local function format_hunks()
	local ignore_filetypes = { "lua" }
	if vim.tbl_contains(ignore_filetypes, vim.bo.filetype) then
		vim.notify("range formatting for " .. vim.bo.filetype .. " not working properly.")
		return
	end

	local hunks = require("gitsigns").get_hunks()
	if hunks == nil then
		return
	end

	local format = require("conform").format

	local function format_range()
		if next(hunks) == nil then
			vim.notify("done formatting git hunks", "info", { title = "formatting" })
			return
		end
		local hunk = nil
		while next(hunks) ~= nil and (hunk == nil or hunk.type == "delete") do
			hunk = table.remove(hunks)
		end

		if hunk ~= nil and hunk.type ~= "delete" then
			local start = hunk.added.start
			local last = start + hunk.added.count
			-- nvim_buf_get_lines uses zero-based indexing -> subtract from last
			local last_hunk_line = vim.api.nvim_buf_get_lines(0, last - 2, last - 1, true)[1]
			local range = { start = { start, 0 }, ["end"] = { last - 1, last_hunk_line:len() } }
			format({ range = range, async = true, lsp_fallback = true }, function()
				vim.defer_fn(function()
					format_range()
				end, 1)
			end)
		end
	end

	format_range()
end

require("conform").setup({

	format_on_save = function(bufnr)
		-- Disable with a global or buffer-local variable
		if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
			return
		end
		return { timeout_ms = 500, lsp_format = "fallback" }
	end,

	formatters_by_ft = {
		ocaml = { "ocamlformat" },
		dune = { "dune" },
		["ocaml.interface"] = { "ocamlformat" },
		haskell = { "ormolu" },
		lua = { "stylua" },
		purescript = { "purs-tidy" },
		javascript = { "prettierd" },
		json = { "prettierd" },
		jsonc = { "prettierd" },
		css = { "prettierd" },
		nix = { "nixfmt" },
		rust = { "rustfmt" },
		xml = { "xmlformat" },
		html = { "prettier" },
	},
	formatters = {
		["ocaml-topiary"] = {
			async = true,
			command = "topiary",
			stdin = true,
			args = { "format", "--language", "ocaml" },
		},
		["ocaml-interface"] = {
			command = "topiary",
			stdin = true,
			args = { "format", "--language", "ocaml" },
		},

		dune = {
			command = "dune",
			stdin = true,
			args = { "format" },
		},
	},
})

vim.api.nvim_create_user_command("FormatDisable", function(args)
	if args.bang then
		-- FormatDisable! will disable formatting just for this buffer
		vim.b.disable_autoformat = true
	else
		vim.g.disable_autoformat = true
	end
end, {
	desc = "Disable autoformat-on-save",
	bang = true,
})

vim.api.nvim_create_user_command("FormatEnable", function()
	vim.b.disable_autoformat = false
	vim.g.disable_autoformat = false
end, {
	desc = "Re-enable autoformat-on-save",
})

-- vim: ts=2 sts=2 sw=2 et
