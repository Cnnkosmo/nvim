# Neovim Configuration Maintenance

This repository contains your Neovim setup powered by lazy.nvim. The notes below explain how to keep Python debugging (debugpy) working smoothly and how to manage related tooling without needing per-project boilerplate.

## File Layout
- `init.lua` bootstraps lazy.nvim and loads everything under `lua/`.
- `lua/plugins/debugging.lua` defines all DAP and debugpy behaviour.
- `lua/plugins/lsp-config.lua` sets up language servers, including the default BasedPyright behaviour.
- `lua/vim-options.lua` keeps core editor settings.

## Python Debugging (debugpy)
1. `mason-nvim-dap` ensures `debugpy` and `codelldb` are installed automatically. Open `:Mason` if you want to monitor or reinstall them.
2. When Neovim loads, `dap-python` tries to use Mason's virtual environment (`.../debugpy/venv/bin/python`). If it is unavailable or not executable, it falls back to `python3` (then `python`).
3. To force a specific interpreter (for example, a project venv), edit `lua/plugins/debugging.lua` and set `dap_python_exec` before the call to `dap_python.setup(...)`.
4. The adapter is launched with a randomly selected free port. If you need a fixed port (for firewall rules), edit the `pick_random_port()` helper near the bottom of `lua/plugins/debugging.lua`.
5. Launch configurations come from:
   - Hard-coded C/C++/Rust entries in `lua/plugins/debugging.lua`.
   - VS Code style `launch.json` files. Place them in `.nvim/launch.json` or `.vscode/launch.json` at the project root, then either restart Neovim or run `:DapLoadLaunchJSON` (optionally with a path) to reload.

### Verifying the Adapter
After installing or changing debugpy, validate with:
```
:lua =vim.fn.executable(require('mason-registry').get_package('debugpy'):get_install_path() .. '/venv/bin/python')
```
This should return `1`. If it does not, reinstall via `:Mason` or point `dap_python_exec` at a working interpreter.

## BasedPyright Defaults
- `lua/plugins/lsp-config.lua` injects mild defaults (basic type checking, open-files diagnostics) whenever a project does **not** ship its own `basedpyrightconfig.json`, `basedpyright.json`, `pyrightconfig.json`, or `pyproject.toml`.
- To adjust the global defaults, edit `default_basedpyright_settings` in that file. Projects can still override everything by adding one of the recognised config files.

## Updating and Reloading
- After editing any Lua file, use `:luafile %` to apply the change to the current buffer, or restart Neovim.
- Run `:Lazy sync` to install or update plugins after modifying plugin specs.
- Use `:Mason` to verify external tooling (debugpy, codelldb, etc.) is installed and up to date.

## Troubleshooting
- `:checkhealth` highlights missing executables (e.g., Python, debugpy). Install whatever it flags and restart.
- If debugpy stops responding, run `:echo vim.fn.has('nvim-0.9')` to ensure your Neovim version is current enough for the configured APIs, then restart and watch `:messages` for adapter-launch errors recorded by `debugpy adapter exited ...` notifications.
