vim.filetype.add({
	extension = { t = "cram", tree = "forester" },
})

vim.treesitter.language.register("cram", "cram")
vim.treesitter.language.add("cram", { path = "/home/kento/tree-sitter-cram/cram.so" })

vim.treesitter.language.register("forester", "forester")
vim.treesitter.language.add("forester", { path = "/home/kento/tree-sitter-forester/forester.so" })

local group = vim.api.nvim_create_augroup("custom-treesitter", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
	group = group,
	callback = function(args)
		local bufnr = args.buf
		local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
		if not ok or not parser then
			return
		end
		pcall(vim.treesitter.start)

		vim.bo[bufnr].syntax = "on"
	end,
})
