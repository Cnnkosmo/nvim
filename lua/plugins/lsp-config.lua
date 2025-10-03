return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "basedpyright", "clangd", "intelephense", "jdtls" },
        automatic_installation = true,
      })
    end
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")
      local util = require("lspconfig.util")

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      if ok_cmp then
        capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
      end

      local uv = vim.uv or vim.loop

      local function has_basedpyright_config(root_dir)
        if not root_dir then
          return false
        end

        local config_files = {
          "basedpyrightconfig.json",
          "basedpyright.json",
          "pyrightconfig.json",
          "pyproject.toml",
        }

        for _, filename in ipairs(config_files) do
          local path = vim.fs.joinpath(root_dir, filename)
          if uv.fs_stat(path) then
            return true
          end
        end

        return false
      end

      local default_basedpyright_settings = {
        basedpyright = {
          analysis = {
            typeCheckingMode = "basic",
            diagnosticMode = "openFilesOnly",
            autoSearchPaths = true,
            autoImportCompletions = true,
            useLibraryCodeForTypes = true,
          },
        },
      }

      local on_attach = function(_, bufnr)
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc and ("LSP: " .. desc) or nil })
        end

        map("n", "K", vim.lsp.buf.hover, "Hover documentation")
        map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
        map("n", "gd", vim.lsp.buf.definition, "Go to definition")
        map("n", "gr", vim.lsp.buf.references, "Find references")
        map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
      end

      local servers = {
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = {
                globals = { "vim" },
              },
            },
          },
        },
        basedpyright = {
          root_dir = util.root_pattern(
            "basedpyrightconfig.json",
            "basedpyright.json",
            "pyrightconfig.json",
            "pyproject.toml",
            ".git"
          ),
          on_new_config = function(new_config, new_root_dir)
            if has_basedpyright_config(new_root_dir) then
              return
            end

            new_config.settings = vim.tbl_deep_extend(
              "force",
              {},
              new_config.settings or {},
              default_basedpyright_settings
            )
          end,
        },
        intelephense = {
          root_dir = util.root_pattern("composer.json", "composer.lock", ".git"),
          settings = {
            intelephense = {
              environment = {
                includePaths = { "vendor" },
              },
              files = {
                maxSize = 5 * 1024 * 1024,
              },
            },
          },
        },
        jdtls = (function()
          local ok_registry, mason_registry = pcall(require, "mason-registry")
          if not ok_registry or not (mason_registry.has_package and mason_registry.has_package("jdtls")) then
            return nil
          end

          local jdtls = mason_registry.get_package("jdtls")
          local install_path = jdtls:get_install_path()
          local launcher = vim.fn.glob(install_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")
          local config_dir = install_path .. "/config_mac"

          if launcher == "" then
            return nil
          end

          return {
            cmd = {
              vim.env.JAVA_HOME and (vim.env.JAVA_HOME .. "/bin/java") or "java",
              "-Declipse.application=org.eclipse.jdt.ls.core.id1",
              "-Dosgi.bundles.defaultStartLevel=4",
              "-Declipse.product=org.eclipse.jdt.ls.core.product",
              "-Dlog.protocol=true",
              "-Dlog.level=ALL",
              "-Xms1g",
              "--add-modules=ALL-SYSTEM",
              "--add-opens", "java.base/java.util=ALL-UNNAMED",
              "--add-opens", "java.base/java.lang=ALL-UNNAMED",
              "-jar", launcher,
              "-configuration", config_dir,
              "-data", vim.fn.stdpath("cache") .. "/jdtls-workspace",
            },
            root_dir = util.root_pattern(".git", "pom.xml", "build.gradle", "settings.gradle"),
          }
        end)(),
      }

      for server, config in pairs(servers) do
        if config then
          config.capabilities = capabilities
          config.on_attach = on_attach
          lspconfig[server].setup(config)
        end
      end
    end
  },
  {
    "p00f/clangd_extensions.nvim",
    opts = {
      server = {
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy",
          "--completion-style=detailed",
          "--function-arg-placeholders",
          "--fallback-style=llvm",
        },
        capabilities = {
          offsetEncoding = { "utf-16" },
        },
        flags = {
          debounce_text_changes = 150,
        },
        keys = {
          { "<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "LSP: Switch source/header" },
        },
      },
    },
    config = function(_, opts)
      require("clangd_extensions").setup(opts)
    end,
  }
}
