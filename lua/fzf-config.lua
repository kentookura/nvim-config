local fzf = require("fzf-lua")
fzf.setup({ file_ignore_patterns = { "_build/", ".git/", ".claude/", "output" } })

vim.keymap.set("n", "<SPACE>sf", fzf.files)
vim.keymap.set("n", "<SPACE>sg", fzf.live_grep)
vim.keymap.set("n", "<SPACE>ss", fzf.lsp_workspace_symbols)
vim.keymap.set("n", "<SPACE>sd", fzf.lsp_workspace_diagnostics)
-- vim.keymap.set("n', "<SPACE>
