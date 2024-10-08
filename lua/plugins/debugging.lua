return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "mfussenegger/nvim-dap-python"
    },
    config=function()
      local dap = require("dap")
      local dapui = require("dapui")
      require("dapui").setup()
      require("dap-python").setup("~/.virtualenvs/debugpy/bin/python")
      dap.configurations.python = {
        {
          type = 'python',
          request = 'launch',
          name = "Launch file",
          program = "${file}",
          pythonPath = function()
            return "~/.virtualenvs/debugpy/bin/python"  -- Or another interpreter
          end,
          host = "0.0.0.0",  -- Custom host
          port = 8000,         -- Custom port
        },
      }
      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end
      vim.keymap.set('n', '<Leader>b', dap.toggle_breakpoint, {})
      vim.keymap.set('n', '<Leader>c', dap.continue, {})
    end
  },
  {
    "rcarriga/nvim-dap-ui", dependencies = {"mfussenegger/nvim-dap", "nvim-neotest/nvim-nio"}
  }
}

