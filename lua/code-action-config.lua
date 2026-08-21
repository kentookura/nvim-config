require("tiny-code-action").setup({
	backend = "vim",
	picker = {
		"buffer",
		opts = {
			hotkeys = true,
			auto_accept = true,
			keymaps = {
				close = { "q", "<Esc>" },
			},
		},
	},
})

vim.keymap.set({ "n", "x" }, "<leader>ca", function()
	require("tiny-code-action").code_action()
end, { noremap = true, silent = true })
