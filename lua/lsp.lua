vim.lsp.config["luals"] = {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = {
		".luarc.json",
		".luarc.jsonc",
		".luacheckrc",
		".stylua.toml",
		"stylua.toml",
		"selene.toml",
		"selene.yml",
		".git",
	},
	settings = {
		Lua = {
			runtime = {
				-- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
				version = "LuaJIT",
				-- Setup your lua path
				path = runtime_path,
			},
			diagnostics = {
				-- Get the language server to recognize the `vim` global
				globals = { "vim" },
			},
			workspace = {
				-- Make the server aware of Neovim runtime files
				library = vim.api.nvim_get_runtime_file("", true),
			},
			-- Do not send telemetry data containing a randomized but unique identifier
			telemetry = {
				enable = false,
			},
		},
	},
}

vim.lsp.config["vale"] = {
	cmd = { "vale-ls" },
	filetypes = { "mail" },
}

vim.lsp.config["elm"] = {
	cmd = { "elm-language-server" },
	filetypes = { "elm" },
	root_markers = { "elm.json" },
}

vim.lsp.config["tsserver"] = {
	cmd = { "typescript-language-server", "--stdio" },
	filetypes = { "javascript" },
}

vim.lsp.config["lemminx"] = {
	cmd = { "lemminx" },
	filetypes = { "xml", "xslt" },
}

vim.lsp.config["purescript-language-server"] = {
	cmd = { "purescript-language-server", "--stdio" },
	filetypes = { "purescript" },
}

vim.lsp.config["ocamllsp"] = {
	cmd = { "ocamllsp" },
	filetypes = { "ocaml", "ocaml.interface" },
}

vim.lsp.config["yamllsp"] = {
	cmd = { "yaml-language-server", "--stdio" },
	filetypes = { "yaml" },
}

vim.lsp.config["hls"] = {
	cmd = { "haskell-language-server-wrapper", "--lsp" },
	filetypes = { "haskell", "cabal" },
}

vim.filetype.add({ extension = { tree = "forester" } })

vim.lsp.config["forester-lsp"] = {
	-- cmd = { "lsp-devtools", "agent", "--", "dune", "exec", "--", "forester", "lsp" },
	cmd = { "forester", "lsp", "-vvv" },
	filetypes = { "forester" },
}

vim.keymap.set("n", "gK", function()
	local new_config = not vim.diagnostic.config().virtual_lines
	vim.diagnostic.config({ virtual_lines = new_config })
end, { desc = "Toggle diagnostic virtual_lines" })

vim.lsp.enable("purescript-language-server")
vim.lsp.enable("forester-lsp")
vim.lsp.enable("yamllsp")
vim.lsp.enable("hls")
vim.lsp.enable("tsserver")
vim.lsp.enable("lemminx")

vim.lsp.enable("elm")
vim.lsp.enable("luals")
vim.lsp.enable("ocamllsp")
vim.lsp.enable("vale")

-- vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
-- 	underline = false,
-- 	virtual_text = true,
-- 	-- virtual_text = {spacing = 4},
-- 	signs = true,
-- 	update_in_insert = false,
-- })
--
-- vim.lsp.handlers["textDocument/definition"] = function(_, result)
-- 	if not result or vim.tbl_isempty(result) then
-- 		print("[LSP] Could not find definition.")
-- 		return
-- 	end
--
-- 	vim.lsp.util.show_document(result[1], "utf-8", { focus = true })
-- end
--
-- vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "single" })
--
local on_attach = function(ev)
	local bufnr = ev.buf
	local client = vim.lsp.get_client_by_id(ev.data.client_id)
	-- NOTE: Remember that lua is a real programming language, and as such it is possible
	-- to define small helper and utility functions so you don't have to repeat yourself
	-- many times.
	--
	-- In this case, we create a function that lets us more easily define mappings specific
	-- for LSP related items. It sets the mode, buffer and description for us each time.
	local nmap = function(keys, func, desc)
		if desc then
			desc = "LSP: " .. desc
		end

		vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
	end

	nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
	nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

	nmap("gd", require("fzf-lua").lsp_definitions, "[G]oto [D]efinition")
	nmap("gr", require("fzf-lua").lsp_references, "[G]oto [R]eferences")
	nmap("gI", require("fzf-lua").lsp_implementations, "[G]oto [I]mplementation")
	nmap("<leader>D", require("fzf-lua").lsp_typedefs, "Type [D]efinition")
	nmap("<leader>ws", require("fzf-lua").lsp_workspace_symbols, "[W]orkspace [S]ymbols")

	nmap("<leader>ds", require("fzf-lua").lsp_document_symbols, "[D]ocument [S]ymbols")
	nmap("gR", function()
		require("trouble").toggle("lsp_references")
	end, "[R]eferences")
	nmap("<leader>dd", function()
		require("trouble").toggle()
	end, "[D]ocument [D]iagnosics")
	nmap("<leader>wd", function()
		require("trouble").toggle("workspace_diagnostics")
	end, "[W]orkspace [D]iagnosics")
	nmap("<leader>dd", function()
		require("trouble").toggle("document_diagnostics")
	end, "[D]ocument [D]iagnosics")
	nmap("<leader>dq", function()
		require("trouble").toggle("quickfix")
	end, "[Q]uickfix")
	nmap("<leader>dl", function()
		require("trouble").toggle("loclist")
	end, "[L]oclist")

	nmap("K", vim.lsp.buf.hover, "HoverDocumentation")
	nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")

	-- Lesser used LSP functionality
	nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
	nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
	nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
	nmap("<leader>wl", function()
		print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
	end, "[W]orkspace [L]ist Folders")

	if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
		nmap("<leader>th", function()
			vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }))
		end, "[T]oggle Inlay [H]ints")
	end

	-- Create a command `:Format` local to the LSP buffer
	vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
		vim.lsp.buf.format({
			filter = function(client)
				return client.name ~= "ocamlls"
			end,
		})
	end, { desc = "Format current buffer with LSP" })
end

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = on_attach,
})
