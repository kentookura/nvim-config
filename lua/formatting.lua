require("conform").setup({
	formatters_by_ft = {
		-- ocaml = { "ocamlformat" },
		ocaml = { "ocaml" },
		dune = { "dune" },
		["ocaml.interface"] = { "ocaml-interface" },
		haskell = { "ormolu" },
		lua = { "stylua" },
		purescript = { "purs-tidy" },
		javascript = { "prettier" },
		json = { "prettier" },
		css = { "prettier" },
		nix = { "nixfmt" },
		rust = { "rustfmt" },
		xml = { "xmlformat" },
		html = { "prettier" },
	},
	formatters = {
		ocaml = {
			command = "topiary",
			stdin = true,
			args = { "format", "--language", "ocaml" },
		},
		["ocaml-interface"] = {
			command = "topiary",
			stdin = true,
			args = { "format", "--language", "ocaml-interface" },
		},

		dune = {
			command = "dune",
			stdin = true,
			args = { "format" },
		},
	},
	format_on_save = function(bufnr)
		-- Disable with a global or buffer-local variable
		if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
			return
		end
		return { timeout_ms = 2000 }
	end,
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
