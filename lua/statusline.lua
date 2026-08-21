require("gitsigns").setup({
	status_formatter = function(status)
		local added, changed, removed, head = status.added, status.changed, status.removed, status.head
		local status_txt = {}
		if added and added > 0 then
			table.insert(status_txt, "+" .. added)
		end
		if changed and changed > 0 then
			table.insert(status_txt, "~" .. changed)
		end
		if removed and removed > 0 then
			table.insert(status_txt, "-" .. removed)
		end
		return table.concat(status_txt, " ")
	end,
})

vim.opt.statusline:append("%{get(b:,'gitsigns_status',' ')}")
vim.opt.statusline:append("%{v:lua.vim.lsp.status()}")
