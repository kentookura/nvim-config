require("options")
require("rebinds")
require("plugins")
require("formatting")
require("lsp")
require("util")
require("autocomplete")
require("colorscheme")
require("ocaml-config")
require("statusline")
require("tree-sitter-config")
local spell_types = { "text", "plaintex", "typst", "gitcommit", "markdown", "mail" }

-- Set global spell option to false initially to disable it for all file types
vim.opt.spell = false

-- Create an augroup for spellcheck to group related autocommands
vim.api.nvim_create_augroup("Spellcheck", { clear = true })

-- Create an autocommand to enable spellcheck for specified file types
vim.api.nvim_create_autocmd({ "FileType" }, {
	group = "Spellcheck", -- Grouping the command for easier management
	pattern = spell_types, -- Only apply to these file types
	callback = function()
		vim.opt_local.spell = true -- Enable spellcheck for these file types
	end,
	desc = "Enable spellcheck for defined filetypes", -- Description for clarity
})

vim.api.nvim_set_hl(0, "ocamlTypeCatchAll", { link = "Type" })

require("cram").setup()
