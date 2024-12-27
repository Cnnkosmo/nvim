vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.opt.clipboard = "unnamedplus"
vim.g.mapleader = " "
vim.diagnostic.config({
  virtual_text = true,   -- Show inline diagnostics
  signs = true,          -- Show signs in the gutter
  underline = true,      -- Underline the problematic text
  update_in_insert = false, -- Disable updates while typing to reduce noise
})
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*.cpp,*.h,*.c",
  callback = function()
    vim.lsp.buf.format({ async = true })  -- Optional: Format file on save
    vim.lsp.buf.code_action()            -- Trigger code actions
  end,
})

