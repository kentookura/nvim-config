local oil = require("oil")

oil.setup({
	win_options = { signcolumn = "yes:2" },
	delete_to_trash = true,
	watch_for_changes = true,
	view_options = { show_hidden = true },
	lsp_file_methods = { enabled = true },
})

require("oil-git-status").setup({})

vim.keymap.set("n", "\\", "<CMD>Oil<CR>", { desc = "Open parent directory" })

-- Stage the entries under the cursor / visual selection with git
local function git_add(line1, line2)
	local dir = oil.get_current_dir()
	if not dir then
		vim.notify("oil: not a local directory", vim.log.levels.WARN)
		return
	end

	local args = { "git", "add", "--" }
	local names = {}
	for lnum = line1, line2 do
		local entry = oil.get_entry_on_line(0, lnum)
		if entry then
			table.insert(args, dir .. entry.name)
			table.insert(names, entry.name)
		end
	end
	if #names == 0 then
		return
	end

	vim.system(args, { cwd = dir, text = true }, function(res)
		vim.schedule(function()
			if res.code ~= 0 then
				vim.notify("git add failed: " .. (res.stderr or ""), vim.log.levels.ERROR)
				return
			end
			vim.notify("staged " .. table.concat(names, ", "))
			local ok, gitsigns = pcall(require, "gitsigns")
			if ok then
				gitsigns.refresh()
			end
		end)
	end)
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = "oil",
	callback = function(args)
		vim.keymap.set("n", "ga", function()
			local lnum = vim.fn.line(".")
			git_add(lnum, lnum)
		end, { buffer = args.buf, desc = "git add entry under cursor" })

		vim.keymap.set("x", "ga", function()
			local line1, line2 = vim.fn.line("."), vim.fn.line("v")
			vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
			git_add(math.min(line1, line2), math.max(line1, line2))
		end, { buffer = args.buf, desc = "git add selected entries" })
	end,
})
