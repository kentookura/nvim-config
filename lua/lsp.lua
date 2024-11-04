vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
	underline = false,
	virtual_text = true,
	-- virtual_text = {spacing = 4},
	signs = true,
	update_in_insert = false,
})

local on_attach = function(ev)
	local bufnr = ev.buf
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

local configs = require("lspconfig.configs")

vim.filetype.add({ extension = { tree = "forester" } })
if not configs.forester_lsp then
	configs.forester_lsp = {
		default_config = {
			cmd = { "/home/kento/.forester/bin/forester", "lsp" },
			filetypes = { "forester" },
			root_dir = vim.fs.root(vim.env.PWD, { "forest.toml" }),
			settings = {},
		},
	}
end

require("lspconfig").forester_lsp.setup({})
require("lspconfig").rust_analyzer.setup({})
require("lspconfig").gopls.setup({})
require("lspconfig").nixd.setup({})
require("lspconfig").elmls.setup({})
require("lspconfig").hls.setup({})
require("lspconfig").ts_ls.setup({})
require("lazydev").setup()

require("lspconfig").lua_ls.setup({
	on_init = function(client)
		client.config.settings = vim.tbl_deep_extend("force", client.config.settings, {
			Lua = {
				runtime = {
					version = "LuaJIT",
				},
				workspace = {
					checkThirdParty = false,
					library = {
						vim.env.VIMRUNTIME,
						vim.api.nvim_get_runtime_file("", true),
						"${3rd}/luv/library",
						"${3rd}/busted/library",
					},
				},
			},
		})
		client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
		return true
	end,
})

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
