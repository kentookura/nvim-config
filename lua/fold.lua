vim.opt.foldcolumn = "0"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true
vim.opt.foldmethod = "expr"
vim.opt.foldtext = "v:lua.vim.treesitter.foldtext()"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"

require("ufo").setup({
	provider_selector = function(bufnr, filetype, buftype)
		return { "treesitter", "indent" }
	end,
})

-- vim: ts=2 sts=2 sw=2 et
