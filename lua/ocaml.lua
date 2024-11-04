local nmap = require("util").nmap

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

-- require("nvim-treesitter.configs").setup({
-- 	autopairs = { enable = true },
-- })

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
		vim.keymap.set("n", "<leader>cd", function()
			destruct({ enumerate_cases = true })
		end, { buffer = 0, desc = "[D]estruct the value" })
	end,
})

local ls = require("luasnip")
local s = ls.snippet
local f = ls.function_node
local t = ls.text_node
local sn = ls.snippet_node
local i = ls.insert_node
local c = ls.choice_node

ls.add_snippets("ocaml", {
	s("module", {
		t("module "),
		c(1, {
			sn(nil, {
				i(1, "Module"),
				t({ " = struct", "\t" }),
				i(2, " "),
				t({ "", "end" }),
			}),

			sn(nil, {
				t("type "),
				i(1, "Module"),
				t({ " = sig", "\t" }),
				i(2, " "),
				t({ "", "end" }),
			}),
		}),
	}),

	s({ trig = "let", desc = "Choose from variable, function or module" }, {
		t("let "),

		c(1, {
			sn(nil, {
				i(1, "name"),
				t(" = "),
				i(2, "value"),
				t(" in"),
			}, { key = "var" }),

			sn(nil, {
				i(1, "func"),
				t(" "),
				i(2, "()"),
				t({ " =", "\t" }),
				i(3, "()"),
			}, { key = "function" }),

			sn(nil, {
				t("open "),
				i(1, "Module"),
				t(" in"),
			}),
		}),
	}),
})
