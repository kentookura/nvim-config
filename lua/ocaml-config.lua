-- Register various ocaml related syntax extensions
vim.filetype.add({
	extension = {
		mli = "ocaml.interface",
		mly = "ocaml.menhir",
		mll = "ocaml.ocamllex",
		mlx = "ocaml",
		t = "cram",
	},
})

-- If you have `ocaml_interface` parser installed, it will use it for `ocaml.interface` files
vim.treesitter.language.register("ocaml_interface", "ocaml.interface")
vim.treesitter.language.register("menhir", "ocaml.menhir")
vim.treesitter.language.register("ocaml_interface", "ocaml.interface")
vim.treesitter.language.register("cram", "ocaml.cram")
vim.treesitter.language.register("ocamllex", "ocaml.ocamllex")

local ocaml = require("ocaml")

ocaml.setup({
	-- If you replace this section with {} it will not setup any
	-- keymaps.
	keymaps = {
		jump_next_hole = "<leader>n",
		jump_prev_hole = "<leader>p",
		construct = "<leader>c",
		jump = "<leader>j",
		phrase_prev = "<leader>pp",
		phrase_next = "<leader>pn",
		infer = "<leader>i",
		switch_ml_mli = "<leader>s",
		type_enclosing = "<leader>t",
		type_enclosing_grow = "<Up>",
		type_enclosing_shrink = "<Down>",
		type_enclosing_increase = "<Right>",
		type_enclosing_decrease = "<Left>",
	},
})

local vim = vim

local api = vim.api

local ui = require("ocaml.ui")

local function get_server()
	local clients = vim.lsp.get_clients({ name = "ocamllsp" })
	for _, client in ipairs(clients) do
		if client.name == "ocamllsp" then
			return client
		end
	end
end

local function with_server(callback)
	local server = get_server()
	if server then
		return callback(server)
	end
	vim.notify("No OCaml LSP server available", vim.log.levels.ERROR)
end

local destruct = function()
	with_server(function(client)
		local row, col = table.unpack(api.nvim_win_get_cursor(0))
		local params = {
			uri = vim.uri_from_bufnr(0),
			position = { line = row - 1, character = col },
			withValues = "local",
		}
		local result = client.request_sync("ocamllsp/destruct", params, 1000)
		if not (result and result.result) then
			vim.notify("Unable to destruct.", vim.log.levels.WARN)
			return
		end

		local choices = result.result.result
		local buf = api.nvim_get_current_buf()
		local function apply_choice(choice)
			api.nvim_buf_set_text(buf, row - 1, col, row - 1, col + 1, { choice })
			local range = {
				start = { line = row - 1, character = col },
				["end"] = { line = row - 1, character = col + #choice },
			}
			ocaml.jump_to_hole("next", range, buf)
			vim.cmd.redraw()
		end

		ui.selecting_floating_window(choices, function(id)
			apply_choice(choices[id])
		end)
	end)
end

vim.keymap.set("n", "<leader>d", destruct)
