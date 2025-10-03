local opt = vim.opt

opt.expandtab = true
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.clipboard = "unnamedplus"
opt.signcolumn = "yes"

vim.keymap.set({ "i", "n", "v" }, "<C-c>", "<Esc>", { desc = "Make Ctrl+C behave like Escape" })


vim.diagnostic.config({
  virtual_lines = true,
  virtual_text = {
    prefix = " ",
    spacing = 2,
  },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.diagnostic.enable(args.buf, nil, { virtual_text = true })
  end,
})

local diagnostic_signs = {
  Error = " ",
  Warn = " ",
  Hint = " ",
  Info = " ",
}

for type, icon in pairs(diagnostic_signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = { "*.c", "*.cpp", "*.h" },
  callback = function(event)
    local bufnr = event.buf
    local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
    for _, client in ipairs(clients) do
      if client.supports_method("textDocument/formatting") then
        vim.lsp.buf.format({ async = true, bufnr = bufnr })
        break
      end
    end
  end,
})
