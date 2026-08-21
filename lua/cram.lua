-- cram_diff.lua
--
-- Auto-runs OCaml/dune cram tests (*.t files) on open/change and shows the
-- diff between expected and actual output as color-coded virtual text.
--
-- Requires Neovim 0.10+ (uses vim.system and vim.uv). If you're on an older
-- version, swap vim.system for vim.fn.jobstart (noted inline below).
--
-- Install:
--   1. Save this file as lua/cram_diff.lua somewhere on your runtimepath,
--      e.g. ~/.config/nvim/lua/cram_diff.lua
--   2. In your init.lua:
--        require("cram_diff").setup()
--
-- Usage:
--   Just open a .t file. It'll build automatically and show the diff.
--   :CramDiffRun        - force a re-run right now
--   :CramDiffClear      - clear the diff overlay for the current buffer
--   :CramDiffPromote        - run `dune promote` for the whole file and reload
--   :CramDiffPromoteCursor  - promote only the command block under the cursor
--   :CramDiffPreserveSandbox - rerun and snapshot the test's sandbox dir for
--                              manual inspection (see _build/.cram_diff_snapshots)
--   :CramDiffDebug on   - turn on debug logging (off/omit to toggle)
--   :CramDiffLog        - open the log file in a split
--
-- If nothing seems to be happening, run :CramDiffDebug on, trigger a run
-- (save the file, or :CramDiffRun), then :CramDiffLog to see exactly what
-- fired, what command was run, its exit code/output, and why a diff was or
-- wasn't shown. You can also pass { debug = true } to setup() to start with
-- logging already on.
--
-- Customize highlight groups CramDiffAdd / CramDiffDelete to taste.

local M = {}

local ns = vim.api.nvim_create_namespace("cram_diff")

-- debounce timers, keyed by bufnr
local timers = {}

-- last set of parsed diff hunks per buffer, so CramDiffPromoteCursor doesn't
-- need to re-run dune just to know what's currently on screen
local last_hunks = {}

-- config, filled in by setup()
local config = {
	debounce_ms = 400,
	build_args = { "--force" }, -- extra args passed to `dune build @runtest`
	scope_to_dir = true, -- build only the alias for the file's directory
	events = { "BufReadPost", "BufWritePost", "TextChanged", "InsertLeave" },
	pattern = "*.t",
	debug = false, -- set true to enable logging
	log_file = vim.fn.stdpath("cache") .. "/cram_diff.log", -- :CramDiffLog to open it
}

---Debug logger. No-ops unless config.debug is true. Writes to both
---:messages (via vim.notify) and a log file, since :messages history can be
---truncated and job callbacks can be easy to miss scrolling by.
local function log(fmt, ...)
	if not config.debug then
		return
	end
	local msg = string.format(fmt, ...)
	local line = string.format("[%s] %s", os.date("%H:%M:%S"), msg)
	vim.schedule(function()
		vim.notify("[cram_diff] " .. msg, vim.log.levels.DEBUG)
		local f = io.open(config.log_file, "a")
		if f then
			f:write(line .. "\n")
			f:close()
		end
	end)
end

---Find the nearest dune-project root above `path`.
local function find_root(path)
	local dir = vim.fs.dirname(path)
	local matches = vim.fs.find("dune-project", { path = dir, upward = true })
	if matches[1] then
		return vim.fs.dirname(matches[1])
	end
	return dir
end

---Build the dune alias to run: either the full @runtest or one scoped to
---the file's directory (faster in large projects).
local function dune_target(root, filepath)
	if not config.scope_to_dir then
		return "@runtest"
	end
	local dir = vim.fs.dirname(filepath)
	if dir == root then
		return "@runtest"
	end
	local rel = dir:sub(#root + 2) -- strip "root/" prefix
	if rel == "" then
		return "@runtest"
	end
	return "@" .. rel .. "/runtest"
end

local function clear(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

---Parse dune's cram-test failure output (a unified/git-style diff) into a
---list of hunks for the file whose source path is `rel` (relative to the
---dune root). We deliberately parse the diff text itself rather than read
---any file off disk: the sandbox dune builds the corrected output in is
---ephemeral and may be gone by the time we look for it, but the diff dune
---already printed is right there in the process output.
---
---Expected shape of the relevant section of output:
---  diff --git a/test/foo.t b/test/foo.t.corrected
---  index abc123..def456 100644
---  --- a/test/foo.t
---  +++ b/test/foo.t.corrected
---  @@ -4,7 +4,7 @@
---     context line
---  -  removed line
---  +  added line
---     context line
---
---Returns a list of hunks: { old_start, old_count, new_start, new_count,
---lines = { {tag=" "|"-"|"+", text=...}, ... } }, or nil if no matching
---section was found.
local function parse_diff_hunks(output, rel)
	if not output or rel == nil then
		return nil
	end

	local lines = {}
	for line in output:gmatch("[^\r\n]+") do
		table.insert(lines, line)
	end

	-- Find the "diff --git a/<rel> b/<rel>.corrected" header for our file.
	-- Match on suffix too, since dune may print a path like
	-- "_build/.sandbox/HASH/default/<rel>".
	local start_idx
	for i, line in ipairs(lines) do
		local a_path = line:match("^diff %-%-git a/(%S+) b/%S+%.corrected$")
		if a_path and (a_path == rel or a_path:sub(-(#rel + 1)) == "/" .. rel or a_path == "/" .. rel) then
			start_idx = i
			break
		end
	end
	if not start_idx then
		return nil
	end

	-- Skip header lines ("index ...", "--- a/...", "+++ b/...") up to the
	-- first hunk marker.
	local i = start_idx + 1
	while i <= #lines and not lines[i]:match("^@@") do
		if lines[i]:match("^diff %-%-git") then
			return nil -- no hunks before the next file's diff started; malformed
		end
		i = i + 1
	end

	local hunks = {}
	local current
	while i <= #lines do
		local line = lines[i]
		local old_start, old_count, new_start, new_count = line:match("^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@")
		if old_start then
			current = {
				old_start = tonumber(old_start),
				old_count = old_count ~= "" and tonumber(old_count) or 1,
				new_start = tonumber(new_start),
				new_count = new_count ~= "" and tonumber(new_count) or 1,
				lines = {},
			}
			table.insert(hunks, current)
		elseif line:match("^diff %-%-git") then
			break -- next file's diff; we're done with this one
		elseif current then
			local tag = line:sub(1, 1)
			if tag == "+" or tag == "-" or tag == " " then
				table.insert(current.lines, { tag = tag, text = line:sub(2) })
			end
			-- ignore markers like "\ No newline at end of file"
		end
		i = i + 1
	end

	return hunks
end

---Render parsed hunks as extmarks: the "expected" side (dune's diff "-"
---lines) is what's currently written in the buffer, so it's highlighted in
---place with a full-line gitsigns-style highlight rather than shown as
---virtual text. The "actual" side ("+" lines) has no home in the buffer --
---it's output dune produced that isn't written anywhere yet -- so it's still
---shown as green virtual lines below the highlighted block.
local function render_hunks(bufnr, hunks)
	clear(bufnr)
	if not hunks or #hunks == 0 then
		log("render_hunks: nothing to render")
		return
	end

	local groups = 0
	for _, hunk in ipairs(hunks) do
		local old_line = hunk.old_start -- 1-indexed cursor into the source file
		local group_del_lines = {} -- pending 0-indexed buffer lines to highlight
		local group_adds = {} -- pending "actual output" text lines

		local function flush()
			if #group_del_lines == 0 and #group_adds == 0 then
				return
			end
			groups = groups + 1
			for _, lnum0 in ipairs(group_del_lines) do
				vim.api.nvim_buf_set_extmark(bufnr, ns, lnum0, 0, { line_hl_group = "CramDiffDelete" })
			end
			if #group_adds > 0 then
				local virt_lines = {}
				for _, text in ipairs(group_adds) do
					table.insert(virt_lines, { { "+ " .. text, "CramDiffAdd" } })
				end
				-- Anchor after the last highlighted line in this group, or just
				-- before old_line for a pure insertion.
				local anchor = #group_del_lines > 0 and group_del_lines[#group_del_lines]
					or math.max(old_line - 2, 0)
				vim.api.nvim_buf_set_extmark(bufnr, ns, anchor, 0, { virt_lines = virt_lines })
			end
			group_del_lines, group_adds = {}, {}
		end

		for _, l in ipairs(hunk.lines) do
			if l.tag == " " then
				flush()
				old_line = old_line + 1
			elseif l.tag == "-" then
				table.insert(group_del_lines, old_line - 1)
				old_line = old_line + 1
			elseif l.tag == "+" then
				table.insert(group_adds, l.text)
			end
		end
		flush()
	end
	log("render_hunks: rendered %d change group(s) across %d hunk(s)", groups, #hunks)
end

---Run the cram test for bufnr and update the diff overlay.
function M.run(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local filepath = vim.api.nvim_buf_get_name(bufnr)
	if filepath == "" or not filepath:match("%.t$") then
		log("run: skipping buf %d, name %q doesn't look like a .t file", bufnr, filepath)
		return
	end

	local root = find_root(filepath)
	local target = dune_target(root, filepath)
	local rel = filepath:sub(1, #root) == root and filepath:sub(#root + 2) or filepath

	local cmd = vim.list_extend({ "dune", "build", target }, config.build_args)
	log("run: buf %d file=%s root=%s rel=%s cmd=%s", bufnr, filepath, root, rel, table.concat(cmd, " "))

	local ok, handle_or_err = pcall(vim.system, cmd, { cwd = root, text = true }, function(obj)
		log("run: dune exited code=%s stdout=%q stderr=%q", tostring(obj.code), obj.stdout or "", obj.stderr or "")
		vim.schedule(function()
			if not vim.api.nvim_buf_is_valid(bufnr) then
				log("run: buf %d no longer valid, dropping result", bufnr)
				return
			end
			if obj.code == 0 then
				log("run: dune exited 0, test passed as written")
				last_hunks[bufnr] = nil
				clear(bufnr)
				return
			end
			local hunks = parse_diff_hunks(obj.stderr, rel) or parse_diff_hunks(obj.stdout, rel)
			if not hunks then
				log(
					"run: dune failed but no matching diff section found for %s (build error unrelated to cram output?)",
					rel
				)
				last_hunks[bufnr] = nil
				clear(bufnr)
				return
			end
			last_hunks[bufnr] = hunks
			render_hunks(bufnr, hunks)
		end)
	end)

	if not ok then
		log("run: vim.system call failed: %s", tostring(handle_or_err))
	end

	--[[ Neovim < 0.10 fallback (no vim.system):
  vim.fn.jobstart(cmd, {
    cwd = root,
    stdout_buffered = true,
    stderr_buffered = true,
    on_exit = function() ... same body as above ... end,
  })
  ]]
end

local function debounced_run(bufnr)
	log("debounced_run: scheduling buf %d in %dms", bufnr, config.debounce_ms)
	if timers[bufnr] then
		timers[bufnr]:stop()
		timers[bufnr]:close()
	end
	local timer = vim.uv.new_timer()
	timers[bufnr] = timer
	timer:start(
		config.debounce_ms,
		0,
		vim.schedule_wrap(function()
			log("debounced_run: timer fired for buf %d", bufnr)
			M.run(bufnr)
		end)
	)
end

function M.clear(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	last_hunks[bufnr] = nil
	clear(bufnr)
end

---Accept dune's actual output as correct (`dune promote`) and reload.
function M.promote(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local filepath = vim.api.nvim_buf_get_name(bufnr)
	local root = find_root(filepath)
	vim.system({ "dune", "promote" }, { cwd = root, text = true }, function(obj)
		vim.schedule(function()
			if obj.code == 0 then
				last_hunks[bufnr] = nil
				clear(bufnr)
				vim.cmd("checktime")
			else
				vim.notify("dune promote failed:\n" .. (obj.stderr or ""), vim.log.levels.ERROR)
			end
		end)
	end)
end

---Dune has no flag to keep a rule's sandbox directory around after the
---build (checked: `dune build --help` only exposes --sandbox=none|symlink
---|copy|hardlink, which controls how the sandbox is populated, not whether
---it's kept). It deletes the sandbox as soon as the rule finishes.
---
---This works around that by watching _build/.sandbox for the moment a new
---directory is created and copying it out immediately -- well before dune's
---cleanup, which only happens after the whole rule (including your test's
---shell commands) has finished running. It's best-effort rather than
---guaranteed, but in practice the copy starts with the test's entire
---execution time as its margin, so it reliably wins the race for any test
---that isn't instantaneous.
function M.preserve_sandbox_and_run(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local filepath = vim.api.nvim_buf_get_name(bufnr)
	if filepath == "" or not filepath:match("%.t$") then
		vim.notify("[cram_diff] current buffer isn't a .t file", vim.log.levels.WARN)
		return
	end

	local root = find_root(filepath)
	local sandbox_dir = root .. "/_build/.sandbox"
	local snapshot_dir = root .. "/_build/.cram_diff_snapshots"
	vim.fn.mkdir(snapshot_dir, "p")
	vim.fn.mkdir(sandbox_dir, "p") -- fs_event needs the dir to exist to watch it

	local seen = {}
	local watcher = vim.uv.new_fs_event()
	watcher:start(sandbox_dir, {}, function(watch_err, filename)
		if watch_err or not filename or seen[filename] then
			return
		end
		seen[filename] = true
		local src = sandbox_dir .. "/" .. filename
		local dst = snapshot_dir .. "/" .. filename
		log("preserve_sandbox: capturing %s -> %s", src, dst)
		vim.system({ "cp", "-r", src, dst })
	end)

	local target = dune_target(root, filepath)
	local cmd = vim.list_extend({ "dune", "build", target }, config.build_args)
	log("preserve_sandbox: running %s with sandbox watcher active", table.concat(cmd, " "))

	vim.system(cmd, { cwd = root, text = true }, function(obj)
		vim.schedule(function()
			-- Give any in-flight `cp -r` a brief moment to land before we stop
			-- watching and report; the copy was already started well before this.
			vim.defer_fn(function()
				watcher:stop()
				local paths = {}
				for name in pairs(seen) do
					table.insert(paths, snapshot_dir .. "/" .. name)
				end
				if #paths == 0 then
					vim.notify("[cram_diff] no sandbox directory was created for this build", vim.log.levels.INFO)
				else
					vim.notify(
						"[cram_diff] preserved sandbox snapshot(s):\n" .. table.concat(paths, "\n"),
						vim.log.levels.INFO
					)
				end
				log("preserve_sandbox: dune exited code=%s, captured %d snapshot(s)", tostring(obj.code), #paths)
			end, 200)
		end)
	end)
end

---Find the [start, finish] (1-indexed, inclusive) line range of the cram
---command block containing `lnum`, or nil if `lnum` isn't inside one. A
---block begins at a "  $ command" line, continues through "  > ..."
---continuation lines and unmarked output lines, and ends at the next blank
---line, a non-indented line, or the start of another "  $ " command.
local function find_command_block(lines, lnum)
	local start = lnum
	while start > 1 and lines[start] and lines[start]:match("^  ") and not lines[start]:match("^  %$ ") do
		start = start - 1
	end
	if not (lines[start] and lines[start]:match("^  %$ ")) then
		return nil
	end
	local finish = start
	local i = start + 1
	while i <= #lines do
		local l = lines[i]
		if not l or not l:match("^  ") or l:match("^  %$ ") then
			break
		end
		finish = i
		i = i + 1
	end
	return start, finish
end

---Reconstruct the "new" (actual) side of a hunk: context lines are kept,
---"-" lines are dropped, "+" lines are inserted, in their original order.
local function hunk_new_lines(hunk)
	local out = {}
	for _, l in ipairs(hunk.lines) do
		if l.tag == " " or l.tag == "+" then
			table.insert(out, l.text)
		end
	end
	return out
end

---Promote only the diff hunk(s) overlapping the cram command block under
---the cursor, leaving the rest of the file's pending diff untouched. Edits
---the buffer directly (rather than shelling out to `dune promote`, which
---only operates on whole files) and re-runs the test to refresh what's left.
function M.promote_at_cursor(bufnr, winid)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	winid = winid or 0

	local hunks = last_hunks[bufnr]
	if not hunks or #hunks == 0 then
		vim.notify("[cram_diff] no pending diff for this buffer", vim.log.levels.INFO)
		return
	end

	local lnum = vim.api.nvim_win_get_cursor(winid)[1]
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local start, finish = find_command_block(lines, lnum)
	if not start then
		vim.notify("[cram_diff] cursor is not inside a cram command block", vim.log.levels.WARN)
		return
	end
	log("promote_at_cursor: block for line %d is [%d,%d]", lnum, start, finish)

	local matched = {}
	for _, hunk in ipairs(hunks) do
		local hunk_end = hunk.old_start + hunk.old_count - 1
		if hunk.old_start <= finish and hunk_end >= start then
			table.insert(matched, hunk)
		end
	end
	if #matched == 0 then
		vim.notify("[cram_diff] no diff for the command under the cursor", vim.log.levels.INFO)
		return
	end

	-- Apply bottom-most hunk first so earlier hunks' line numbers stay valid
	-- even if a replacement changes the line count.
	table.sort(matched, function(a, b)
		return a.old_start > b.old_start
	end)
	for _, hunk in ipairs(matched) do
		local new_lines = hunk_new_lines(hunk)
		vim.api.nvim_buf_set_lines(bufnr, hunk.old_start - 1, hunk.old_start - 1 + hunk.old_count, false, new_lines)
	end
	log("promote_at_cursor: applied %d hunk(s)", #matched)

	vim.api.nvim_buf_call(bufnr, function()
		vim.cmd("silent write")
	end)
	M.run(bufnr)
end

---Link CramDiffAdd/CramDiffDelete to existing highlight groups instead of
---hardcoding colors, so they track the active colorscheme (and gitsigns,
---if present) automatically. Neovim highlight links are live, so these
---don't need to be recomputed on ColorScheme -- they just follow whatever
---the target group currently resolves to.
local function setup_highlights()
	local has_gitsigns = pcall(require, "gitsigns")
	local add_link = has_gitsigns and "GitSignsAddLn" or "DiffAdd"
	-- CramDiffDelete is applied as a full-line highlight on real buffer lines
	-- (see render_hunks), so it wants a gitsigns *Ln group. Gitsigns has no
	-- GitSignsDeleteLn: it never highlights a real line as deleted, since a
	-- genuinely deleted line has nothing left in the buffer to highlight (see
	-- gitsigns/highlight.lua: gen_hl special-cases kind == "Ln" and ty ==
	-- "delete" to return nothing). Our "deleted" lines are different -- they're
	-- the file's current content that's about to be replaced -- so
	-- GitSignsChangeLn, gitsigns' highlight for a modified-in-place line, is
	-- the closer match.
	local del_link = has_gitsigns and "GitSignsChangeLn" or "DiffChange"

	vim.api.nvim_set_hl(0, "CramDiffAdd", { link = add_link, default = true })
	vim.api.nvim_set_hl(0, "CramDiffDelete", { link = del_link, default = true })
end

function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})

	setup_highlights()

	local group = vim.api.nvim_create_augroup("CramDiff", { clear = true })

	vim.api.nvim_create_autocmd(config.events, {
		group = group,
		pattern = config.pattern,
		callback = function(args)
			log("autocmd: %s fired for buf %d (%s)", args.event, args.buf, args.file)
			debounced_run(args.buf)
		end,
	})

	vim.api.nvim_create_autocmd("BufDelete", {
		group = group,
		pattern = config.pattern,
		callback = function(args)
			if timers[args.buf] then
				timers[args.buf]:stop()
				timers[args.buf]:close()
				timers[args.buf] = nil
			end
			last_hunks[args.buf] = nil
		end,
	})

	vim.api.nvim_create_user_command("CramDiffRun", function()
		M.run(vim.api.nvim_get_current_buf())
	end, {})

	vim.api.nvim_create_user_command("CramDiffClear", function()
		M.clear(vim.api.nvim_get_current_buf())
	end, {})

	vim.api.nvim_create_user_command("CramDiffPromote", function()
		M.promote(vim.api.nvim_get_current_buf())
	end, {})

	vim.api.nvim_create_user_command("CramDiffPromoteCursor", function()
		M.promote_at_cursor(vim.api.nvim_get_current_buf(), 0)
	end, {})

	vim.api.nvim_create_user_command("CramDiffPreserveSandbox", function()
		M.preserve_sandbox_and_run(vim.api.nvim_get_current_buf())
	end, {})

	vim.api.nvim_create_user_command("CramDiffDebug", function(cmd_args)
		if cmd_args.args == "on" then
			config.debug = true
		elseif cmd_args.args == "off" then
			config.debug = false
		else
			config.debug = not config.debug
		end
		vim.notify(
			"[cram_diff] debug logging " .. (config.debug and "ON" or "OFF") .. " (log: " .. config.log_file .. ")"
		)
	end, {
		nargs = "?",
		complete = function()
			return { "on", "off" }
		end,
	})

	vim.api.nvim_create_user_command("CramDiffLog", function()
		vim.cmd("split " .. vim.fn.fnameescape(config.log_file))
		vim.cmd("normal! G")
	end, {})
end

return M
