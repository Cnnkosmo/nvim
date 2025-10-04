return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
    "MunifTanjim/nui.nvim",
  },
  config = function()
    local ok, neotree = pcall(require, "neo-tree")
    if ok then
      neotree.setup({
        filesystem = {
          filtered_items = {
            hide_dotfiles = false,
            hide_gitignored = false,
            hide_hidden = false,
          },
        },
      })
    end

    vim.keymap.set("n", "<leader>e", ":Neotree filesystem reveal left<CR>", { desc = "Neo-tree: reveal" })
  end,
}
