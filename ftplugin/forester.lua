vim.b.did_ftplugin = 1
vim.treesitter.start()

vim.bo.commentstring = "% %s"

-- NOTE: this Neovim build's native vim.treesitter module does not yet
-- expose an indentexpr (only foldexpr); queries/forester/indents.scm is
-- ready to be picked up once it does, or if the nvim-treesitter plugin's
-- indent module is added to this config.
