vim.opt.swapfile = false
vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.wo.number = true
vim.wo.relativenumber = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true

vim.o.mouse = "a"
vim.o.clipboard = "unnamed,unnamedplus"
vim.o.breakindent = true
vim.o.undofile = true

vim.opt.cursorline = true

vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.scrolloff = 8

vim.o.fillchars = "eob: "

vim.wo.signcolumn = "yes"
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.completeopt = "menuone,noselect"
vim.o.termguicolors = true
vim.o.cmdheight = 0

vim.opt.guicursor = {
	"n-v-c:block", -- Normal, visual, command-line: block cursor
	"i-ci-ve:ver25", -- Insert, command-line insert, visual-exclude: vertical bar cursor with 25% width
	"r-cr:hor20", -- Replace, command-line replace: horizontal bar cursor with 20% height
	"o:hor50", -- Operator-pending: horizontal bar cursor with 50% height
	-- "a:blinkwait700-blinkoff400-blinkon250", -- All modes: blinking settings
	"sm:block-blinkwait175-blinkoff150-blinkon175", -- Showmatch: block cursor with specific blinking settings
}
