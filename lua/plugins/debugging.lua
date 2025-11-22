return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "mfussenegger/nvim-dap-python"
    },
    config = function()
      local ok_dap, dap = pcall(require, "dap")
      if not ok_dap then
        return
      end

      local ok_dapui, dapui = pcall(require, "dapui")
      local ok_dap_python, dap_python = pcall(require, "dap-python")
      local ok_vscode, dap_vscode = pcall(require, "dap.ext.vscode")
      local ok_registry, mason_registry = pcall(require, "mason-registry")

      dap.set_log_level("WARN")

      local codelldb_cmd
      if ok_registry and mason_registry.has_package and mason_registry.has_package("codelldb") then
        local codelldb = mason_registry.get_package("codelldb")
        local extension_path = codelldb:get_install_path() .. "/extension/"
        codelldb_cmd = extension_path .. "adapter/codelldb"
      else
        local mason_path = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/adapter/codelldb"
        if vim.fn.executable(mason_path) == 1 then
          codelldb_cmd = mason_path
        end
      end

      if codelldb_cmd then
        dap.adapters.codelldb = {
          type = "server",
          port = "${port}",
          executable = {
            command = codelldb_cmd,
            args = { "--port", "${port}" },
          },
        }
      end

      dap.configurations.cpp = {
        {
          name = "Launch file",
          type = "codelldb",
          request = "launch",
          program = function()
            local executable = vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
            local expanded_executable = vim.fn.expand(executable)

            if vim.fn.filereadable(expanded_executable) == 0 then
              error("Executable not found: " .. expanded_executable)
            end

            return expanded_executable
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = {},
        },
      }
      dap.configurations.c = dap.configurations.cpp
      dap.configurations.rust = dap.configurations.cpp

      if ok_vscode then
        local default_launch_paths = {
          ".nvim/launch.json",
          ".vscode/launch.json",
        }

        local function load_vscode_launchjs(explicit_path)
          local mappings = {
            codelldb = { "c", "cpp", "rust" },
            cppdbg = { "c", "cpp", "rust" },
            python = { "python" },
          }

          if explicit_path and explicit_path ~= "" then
            dap_vscode.load_launchjs(explicit_path, mappings)
            return
          end

          local cwd = vim.fn.getcwd()
          for _, relative_path in ipairs(default_launch_paths) do
            local candidate = cwd .. "/" .. relative_path
            if vim.fn.filereadable(candidate) == 1 then
              dap_vscode.load_launchjs(candidate, mappings)
              return
            end
          end
        end

        load_vscode_launchjs()

        vim.api.nvim_create_autocmd("DirChanged", {
          group = vim.api.nvim_create_augroup("dap_load_launchjs", { clear = true }),
          callback = function()
            load_vscode_launchjs()
          end,
        })

        vim.api.nvim_create_user_command("DapLoadLaunchJSON", function(opts)
          load_vscode_launchjs(opts.args ~= "" and opts.args or nil)
        end, {
          nargs = "?",
          complete = "file",
        })
      end

      if ok_dapui then
        dapui.setup()
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
      end

      if ok_dap_python then
        local fallback_python

        if ok_registry and mason_registry.has_package and mason_registry.has_package("debugpy") then
          local debugpy = mason_registry.get_package("debugpy")
          local install_path = debugpy:get_install_path()
          if package.config:sub(1, 1) == "\\" then
            fallback_python = install_path .. "\\venv\\Scripts\\python.exe"
          else
            fallback_python = install_path .. "/venv/bin/python"
          end
        end

        if not fallback_python or fallback_python == "" or vim.fn.executable(fallback_python) ~= 1 then
          fallback_python = vim.fn.exepath("python3")
          if fallback_python == "" then
            fallback_python = vim.fn.exepath("python")
          end
          if fallback_python == "" then
            fallback_python = nil
          end
        end

        dap_python.setup(fallback_python, {
          console = "integratedTerminal",
        })

        local default_adapter = dap.adapters.python

        local uv_cmd = vim.fn.exepath("uv")
        if uv_cmd == "" then
          uv_cmd = "uv"
        end

        local function uv_supports_debugpy()
          if uv_cmd == "" or vim.fn.executable(uv_cmd) ~= 1 then
            return false
          end
          vim.fn.system({ uv_cmd, "run", "python", "-m", "debugpy", "--version" })
          return vim.v.shell_error == 0
        end

        local function is_attach(config)
          return config and config.request == "attach"
        end

        dap.adapters.python = function(callback, config)
          default_adapter(function(adapter)
            if adapter and adapter.type == "executable" and not is_attach(config) and uv_supports_debugpy() then
              local updated = vim.deepcopy(adapter)
              updated.command = uv_cmd
              updated.args = { "run", "--module", "debugpy.adapter" }
              callback(updated)
            else
              callback(adapter)
            end
          end, config)
        end

        dap.adapters.debugpy = dap.adapters.python
      end

      vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Debug: Toggle breakpoint" })
      vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Debug: Continue" })
      vim.keymap.set("n", "<leader>n", dap.step_over, { desc = "Debug: Step over" })
      vim.keymap.set("n", "<leader>i", dap.step_into, { desc = "Debug: Step into" })
      vim.keymap.set("n", "<leader>o", dap.step_out, { desc = "Debug: Step out" })
    end
  },
  {
    "rcarriga/nvim-dap-ui", dependencies = {"mfussenegger/nvim-dap", "nvim-neotest/nvim-nio"}
  }
}
