require("options")

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.api.nvim_create_autocmd("BufReadPost", {
	--group = vim.g.user.event,
	callback = function(args)
		local valid_line = vim.fn.line([['"]]) >= 1 and vim.fn.line([['"]]) < vim.fn.line("$")
		local not_commit = vim.b[args.buf].filetype ~= "commit"

		if valid_line and not_commit then
			vim.cmd([[normal! g`"]])
		end
	end,
})

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

	{ "echasnovski/mini.nvim" },

	{
		"catppuccin/nvim",
	},
	-- 	config = function()
	-- 		require("catppuccin").setup({ flavour = "latte" })
	-- 		vim.cmd.colorscheme("catppuccin")
	-- 	end,
	-- },

	{
		"aktersnurra/no-clown-fiesta.nvim",
		config = function()
			vim.cmd([[colorscheme no-clown-fiesta]])
			local scheme = require("no-clown-fiesta.palette")
			vim.api.nvim_set_hl(0, "LspInlayHint", { fg = scheme.hint })
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		build = ":TSUpdate",
	},

	-- FILETYPES
	{ "NoahTheDuke/vim-just", ft = { "just" } },
	{ "ashinkarov/nvim-agda" },
	{ "ElmCast/elm-vim" },

	{
		"lalitmee/browse.nvim",
		config = function()
			local browse_utils = require("browse.utils")
			-- Open the page of opam package on ocaml.org
			-- TODO: use argument in user command
			vim.api.nvim_create_user_command("Opam", function()
				browse_utils.format_search("https://ocaml.org/p/%s", { prompt = "Opam package:" })()
			end, {})
		end,
	},

	-- UI

	{ "nvim-tree/nvim-web-devicons" },
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
			"MunifTanjim/nui.nvim",
		},
	},
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = {},
     -- stylua: ignore
     keys = {
       { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
       { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
       { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
       { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
       { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
     },
	},
	{
		"folke/trouble.nvim",
		event = "VeryLazy",
		cmd = "Trouble",
		opts = {},
		config = function()
			require("trouble").setup()
			vim.api.nvim_create_autocmd("QuickFixCmdPost", {
				callback = function()
					vim.cmd([[Trouble qflist open]])
				end,
			})
		end,
		keys = {
			{
				"<leader>xx",
				"<cmd>Trouble diagnostics toggle<cr>",
				desc = "Diagnostics (Trouble)",
			},
		},
	},
	{
		"norcalli/nvim-colorizer.lua",
		event = "VeryLazy",
		config = function()
			-- require("colorizer").setup()
		end,
	},

	{ "NvChad/showkeys", cmd = "ShowkeysToggle" },

	{
		"chentoast/marks.nvim",
		event = "VeryLazy",
		opts = {},
	},
	{
		"nvim-lualine/lualine.nvim",
		opts = {
			options = {
				icons_enabled = true,
				component_separators = "|",
				section_separators = "",
				globalstatus = true,
			},
		},
	},

	{
		"kylechui/nvim-surround",
		config = function(opts)
			require("nvim-surround").setup({
				keymaps = { visual = "z" },
				surrounds = { ["#"] = {
					add = function()
						return { { "#{" }, { "}" } }
					end,
				} },
			})
		end,
	},
	{ "sindrets/diffview.nvim" },

	-- -- Forester
	-- {
	-- 	dir = "/home/kento/forester.nvim",
	-- 	-- "kentookura/forester.nvim",
	-- 	config = function()
	-- 		require("forester").setup()
	-- 		-- require("telescope").load_extension("forester")
	-- 		vim.g.mapleader = " "
	-- 		vim.keymap.set("n", "<leader>n.", "<cmd>Forester browse<CR>", { silent = true })
	-- 		vim.keymap.set("n", "<leader>nn", "<cmd>Forester new<CR>", { silent = true })
	-- 		vim.keymap.set("n", "<leader>nc", "<cmd>Forester config<CR>", { silent = true })
	-- 	end,
	-- 	dependencies = {
	-- 		{ "nvim-treesitter/nvim-treesitter" },
	-- 		{ "nvim-telescope/telescope.nvim" },
	-- 		{ "nvim-lua/plenary.nvim" },
	-- 	},
	-- },

	-- Git
	"tpope/vim-fugitive",
	"tpope/vim-rhubarb",
	{
		-- Adds git related signs to the gutter, as well as utilities for managing changes
		"lewis6991/gitsigns.nvim",
		opts = {
			-- See `:help gitsigns.txt`
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
			preview_config = {
				border = "none",
			},
			on_attach = function(bufnr)
				local gs = package.loaded.gitsigns

				local function map(mode, l, r, opts)
					opts = opts or {}
					opts.buffer = bufnr
					vim.keymap.set(mode, l, r, opts)
				end

				-- Navigation
				map({ "n", "v" }, "]c", function()
					if vim.wo.diff then
						return "]c"
					end
					vim.schedule(function()
						gs.next_hunk()
					end)
					return "<Ignore>"
				end, { expr = true, desc = "Jump to next hunk" })

				map({ "n", "v" }, "[c", function()
					if vim.wo.diff then
						return "[c"
					end
					vim.schedule(function()
						gs.prev_hunk()
					end)
					return "<Ignore>"
				end, { expr = true, desc = "Jump to previous hunk" })

				-- Actions
				-- visual mode
				map("v", "<leader>hs", function()
					gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, { desc = "stage git hunk" })
				map("v", "<leader>hr", function()
					gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, { desc = "reset git hunk" })
				-- normal mode
				map("n", "<leader>gs", gs.stage_hunk, { desc = "git stage hunk" })
				map("n", "<leader>gr", gs.reset_hunk, { desc = "git reset hunk" })
				map("n", "<leader>gS", gs.stage_buffer, { desc = "git Stage buffer" })
				map("n", "<leader>gu", gs.undo_stage_hunk, { desc = "undo stage hunk" })
				map("n", "<leader>gR", gs.reset_buffer, { desc = "git Reset buffer" })
				map("n", "<leader>gp", gs.preview_hunk, { desc = "preview git hunk" })
				map("n", "<leader>gb", function()
					gs.blame_line({ full = false })
				end, { desc = "git blame line" })
				map("n", "<leader>hd", gs.diffthis, { desc = "git diff against index" })
				map("n", "<leader>hD", function()
					gs.diffthis("~")
				end, { desc = "git diff against last commit" })

				-- Toggles
				map("n", "<leader>tb", gs.toggle_current_line_blame, { desc = "toggle git blame line" })
				map("n", "<leader>td", gs.toggle_deleted, { desc = "toggle git show deleted" })

				-- Text object
				map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "select git hunk" })
			end,
		},
	},

	-- Detect tabstop and shiftwidth automatically
	"tpope/vim-sleuth",

	{
		-- LSP Configuration & Plugins
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "j-hui/fidget.nvim", opts = {} },
			"folke/lazydev.nvim",
		},
	},

	{
		-- Autocompletion
		"hrsh7th/nvim-cmp",
		dependencies = {
			-- Snippet Engine & its associated nvim-cmp source
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",

			-- Adds LSP completion capabilities
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-buffer",

			-- Adds a number of user-friendly snippets
			-- "rafamadriz/friendly-snippets",
		},
	},

	-- Useful plugin to show you pending keybinds.
	{ "folke/which-key.nvim" },
	{ "folke/todo-comments.nvim", opts = {} },
	{
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	},

	{
		"ibhagwan/fzf-lua",
		config = function()
			require("fzf-lua").setup({
				fzf_colors = false,
				winopts = {
					hls = {},
				},
			})

			vim.keymap.set("n", "<leader><leader>", require("fzf-lua").blines, { desc = "current [B]uffer" })
			vim.keymap.set("n", "<leader>sb", require("fzf-lua").buffers, { desc = "[B]uffers" })
			vim.keymap.set("n", "<leader>sf", require("fzf-lua").files, { desc = "[F]iles" })
			vim.keymap.set("n", "<leader>sg", require("fzf-lua").live_grep, { desc = "[G]rep" })
			vim.keymap.set("n", "<leader>sh", require("fzf-lua").help_tags, { desc = "[H]elp tags" })
			vim.keymap.set(
				"n",
				"<leader>ss",
				require("fzf-lua").lsp_document_symbols,
				{ desc = "[ ] Find symbols in buffer" }
			)
			vim.keymap.set(
				"n",
				"<leader>sS",
				require("fzf-lua").lsp_workspace_symbols,
				{ desc = "[ ] Find symbols in workspace" }
			)
			vim.keymap.set("n", "gd", require("fzf-lua").lsp_definitions, { desc = "[G]oto [D]efinition" })
			vim.keymap.set("n", "gr", require("fzf-lua").lsp_references, { desc = "[G]oto [R]eferences" })
			vim.keymap.set("n", "gI", require("fzf-lua").lsp_implementations, { desc = "[G]oto [I]mplementation" })
			vim.keymap.set("n", "<leader>D", require("fzf-lua").lsp_typedefs, { desc = "Type [D]efinition" })
			vim.keymap.set(
				"n",
				"<leader>ws",
				require("fzf-lua").lsp_workspace_symbols,
				{ desc = "[W]orkspace [S]ymbols" }
			)
			--
			-- vim.keymap.set("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
			-- vim.keymap.set("n", "<leader>?", require("telescope.builtin").oldfiles, { desc = "[?] Find recently opened files" })
			-- vim.keymap.set("n", "<leader>/", function()
			-- 	-- You can pass additional configuration to telescope to change theme, layout, etc.
			-- 	require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
			-- 		winblend = 10,
			-- 		previewer = false,
			-- 	}))
			-- end, { desc = "[/] Fuzzily search in current buffer" })
		end,
	},
	-- Fuzzy Finder (files, lsp, etc)
	{
		"nvim-telescope/telescope.nvim",
	},
	{
		"chrisgrieser/nvim-origami",
		config = function()
			require("origami").setup()
		end,
	},
	-- 	branch = "0.1.x",
	-- 	dependencies = {
	-- 		"nvim-lua/plenary.nvim",
	-- 		-- Fuzzy Finder Algorithm which requires local dependencies to be built.
	-- 		-- Only load if `make` is available. Make sure you have the system
	-- 		-- requirements installed.
	-- 		{
	-- 			"nvim-telescope/telescope-fzf-native.nvim",
	-- 			-- NOTE: If you are having trouble with this installation,
	-- 			--       refer to the README for telescope-fzf-native for more instructions.
	-- 			build = "make",
	-- 			cond = function()
	-- 				return vim.fn.executable("make") == 1
	-- 			end,
	-- 		},
	-- 	},
	-- },
	{
		"andreypopp/ocaml.nvim",
		config = function()
			require("ocaml")
		end,
	},

	{
		"stevearc/conform.nvim",
	},
}, {})

-- local foresterCompletionSource = require("forester.completion")
-- require("cmp").register_source("forester", foresterCompletionSource)
-- require("cmp").setup.filetype("forester", { sources = { { name = "forester", dup = 0 } } })

vim.diagnostic.config({
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = " ",
			[vim.diagnostic.severity.WARN] = " ",
			[vim.diagnostic.severity.HINT] = "󰌶",
		},
	},
})

-- [[ Basic Keymaps ]]
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

vim.cmd([[nnoremap \ :Neotree toggle<cr>]])

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank()
	end,
	group = highlight_group,
	pattern = "*",
})

local wk = require("which-key")

wk.add({
	-- document existing key chains
	{ "<leader>f", desc = "[F]ind" },
	{ "<leader>c", desc = "[C]ode" },
	{ "<leader>d", desc = "[D]ocument" },
	{ "<leader>g", desc = "[G]it" },
	{ "<leader>h", desc = "Git [H]unk" },
	{ "<leader>r", desc = "[R]ename" },
	{ "<leader>s", desc = "[S]earch" },
	{ "<leader>t", desc = "[T]oggle" },
	{ "<leader>w", desc = "[W]orkspace" },
	{ "<leader>n", desc = "[N]otes" },
	{ "<leader>x", desc = "Trouble" },
})

require("ocaml")
require("tree-sitter-config")
require("completion")
require("formatting")
require("filetree")
require("lsp")
require("nvim-web-devicons").setup({ override_by_extension = { ["tree"] = { icon = "🌲" } } })

-- vim: ts=2 sts=2 sw=2 et
