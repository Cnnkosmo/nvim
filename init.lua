-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Ensure Neovim has a writable runtime dir for RPC sockets
do
  local default_runtime_dir = vim.fn.expand("~/.cache/nvim/run")
  local runtime_dir = vim.env.XDG_RUNTIME_DIR or default_runtime_dir

  if vim.fn.isdirectory(runtime_dir) == 0 then
    vim.fn.mkdir(runtime_dir, "p", 448) -- 0700 permissions
  else
    pcall(vim.fn.setfperm, runtime_dir, "rwx------")
  end

  vim.env.XDG_RUNTIME_DIR = runtime_dir
end


--vim options
require("vim-options")
-- Setup lazy.nvim
require("lazy").setup("plugins")
