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
      local dap_python = require("dap-python")
      dap.set_log_level('TRACE')

      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
        command = "/Users/rtk/.local/share/nvim/mason/packages/codelldb/extension/adapter/codelldb",
          args = { "--port", "${port}" },
        },
      }
      dap.configurations.cpp = {
        {
          name = "Launch file",
          type = "codelldb",
          request = "launch", program = function()
            -- Prompt the user for the path to the executable
            local executable = vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')

            -- Ensure that the path is properly expanded and valid
            local expanded_executable = vim.fn.expand(executable)
            if vim.fn.filereadable(expanded_executable) == 0 then
              error("Executable not found: " .. expanded_executable)
            end

            return expanded_executable
          end,
          cwd = '${workspaceFolder}',   -- Set the working directory to the workspace folder
          stopOnEntry = false,          -- Whether to stop at the entry point of the program
          args = {},                    -- Pass any program arguments if needed
        },
      }
      dap.configurations.c = dap.configurations.cpp
      dap.configurations.rust = dap.configurations.cpp

      require("dapui").setup()
      dap_python.setup("/Users/rtk/Documents/test_py/.venv/bin/python")
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

