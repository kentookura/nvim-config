require("tiny-inline-diagnostic").setup({ preset = "minimal", options = { multilines = { enabled = true } } })
vim.diagnostic.config({ virtual_text = false })
