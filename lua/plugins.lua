vim.pack.add({
	"https://github.com/justinmk/vim-sneak",
	"https://github.com/stevearc/oil.nvim",
	"https://github.com/stevearc/conform.nvim",
	"https://github.com/ibhagwan/fzf-lua",
	"https://github.com/lewis6991/gitsigns.nvim",
	"https://github.com/tarides/ocaml.nvim",
	"https://github.com/rachartier/tiny-inline-diagnostic.nvim",
	"https://github.com/rachartier/tiny-code-action.nvim",
	"https://github.com/tarides/ocaml.nvim",
	"https://github.com/dchinmay2/alabaster.nvim",
	"https://github.com/catppuccin/nvim",
	"https://github.com/stevearc/quicker.nvim",
	"https://github.com/refractalize/oil-git-status.nvim",
	"https://github.com/folke/trouble.nvim",
	"https://github.com/j-hui/fidget.nvim",
})
require("fidget").setup()

require("trouble-config")

require("oil-config")
require("fzf-config")
require("gitsigns-config")
require("inline-diagnostic-config")
require("code-action-config")
require("ocaml").setup()
