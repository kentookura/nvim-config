-- Register various ocaml related syntax extensions
vim.filetype.add({
	extension = {
		mli = "ocaml.interface",
		mly = "ocaml.menhir",
		mll = "ocaml.ocamllex",
		mlx = "ocaml",
		t = "ocaml.cram",
	},
})

-- If you have `ocaml_interface` parser installed, it will use it for `ocaml.interface` files
vim.treesitter.language.register("ocaml_interface", "ocaml.interface")
vim.treesitter.language.register("menhir", "ocaml.menhir")
vim.treesitter.language.register("ocaml_interface", "ocaml.interface")
vim.treesitter.language.register("cram", "ocaml.cram")
vim.treesitter.language.register("ocamllex", "ocaml.ocamllex")

local destruct = function(opts)
	opts = opts or {}
	opts.enumerate_cases = vim.F.if_nil(opts.enumerate_cases, false)

	-- Keep the old destruct kind, in case of older LSP.
	--    Newer version has multiple destruct kinds we can use.
	local only = { "destruct" }
	if opts.enumerate_cases then
		table.insert(only, "destruct (enumerate cases)")
	else
		table.insert(only, "destruct-line (enumerate cases, use existing match)")
	end

	vim.lsp.buf.code_action({
		apply = true,
		---@diagnostic disable-next-line: missing-fields
		context = { only = only },
	})
end

require("lspconfig").ocamlls.setup({
	cmd = { "ocamllsp" },
	filetypes = { "ocaml", "menhir", "ocaml.interface", "ocamllex", "reason", "dune" },
	on_init = function(client)
		client.server_capabilities.semanticTokensProvider = nil
	end,
	on_attach = function()
		vim.keymap.set("n", "<leader>cd", destruct, { buffer = 0 })
	end,
})
