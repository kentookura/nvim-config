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

vim.lsp.config["nix"] = {
	cmd = { "nixd" },
	filetypes = { "nix" },
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
	cmd = { "/home/kento/.forester/bin/forester", "lsp", "-vvv", "--port", "8080", "forest.toml" },
	filetypes = { "forester" },
	root_markers = { "forest.toml" },
}

vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, {
	callback = function()
		local root = vim.fs.root(0, "forest.toml")
		if not root then
			return
		end
		for _, c in ipairs(vim.lsp.get_clients({ name = "forester-lsp" })) do
			if c.root_dir == root then
				return
			end
		end
		vim.lsp.start(
			vim.tbl_extend("force", vim.lsp.config["forester-lsp"], {
				root_dir = root,
				cmd_cwd = root,
			}),
			{ bufnr = 0 }
		)
	end,
})

vim.lsp.config["rust_analyzer"] = {
	filetypes = { "rust" },
	cmd = { "rust-analyzer" },
	root_markers = { "Cargo.toml", ".git" },
	single_file_support = true,
	before_init = function(init_params, config)
		-- See https://github.com/rust-lang/rust-analyzer/blob/eb5da56d839ae0a9e9f50774fa3eb78eb0964550/docs/dev/lsp-extensions.md?plain=1#L26
		if config.settings and config.settings["rust-analyzer"] then
			init_params.initializationOptions = config.settings["rust-analyzer"]
		end
	end,
}

vim.diagnostic.config().virtual_lines = true

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
vim.lsp.enable("nix")
vim.lsp.enable("rust_analyzer")

local on_attach = function(ev)
	local bufnr = ev.buf
	local client = vim.lsp.get_client_by_id(ev.data.client_id)
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

	nmap("K", vim.lsp.buf.hover, "HoverDocumentation")
	nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")

	-- Lesser used LSP functionality
	nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
	nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
	nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
	nmap("<leader>wl", function()
		print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
	end, "[W]orkspace [L]ist Folders")

	if client then
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
