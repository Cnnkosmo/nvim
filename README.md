# Neovim Configuration Maintenance

This repository contains your Neovim setup powered by lazy.nvim. The notes below explain how to keep Python debugging (debugpy) working smoothly and how to manage related tooling without needing per-project boilerplate.

## File Layout
- `init.lua` bootstraps lazy.nvim and loads everything under `lua/`.
- `lua/plugins/debugging.lua` defines all DAP and debugpy behaviour.
- `lua/plugins/lsp-config.lua` sets up language servers, including the default BasedPyright behaviour.
- `lua/vim-options.lua` keeps core editor settings.

## Python Debugging (debugpy)
1. `mason-nvim-dap` ensures `debugpy` and `codelldb` are installed automatically. Open `:Mason` if you want to monitor or reinstall them.
2. When Neovim loads, `dap-python` first tries to use `uv` if it is available in `$PATH`. When `uv` is used we wrap the adapter so that it runs `uv run python -m debugpy.adapter`, matching the upstream docs. Otherwise it falls back to Mason's virtual environment (`.../debugpy/venv/bin/python`), then `python3`, and finally `python`.
3. To force a specific interpreter (for example, a project venv), adjust the `python_exec` selection right before the `dap_python.setup(...)` call in `lua/plugins/debugging.lua`, or set `require('dap-python').setup(<path>)` in a personal override.
4. Ensure the selected interpreter has `debugpy` installed (`uv pip install debugpy` if you rely on uv).
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
- **macOS socket permission errors / `.nvimlog` spam**: macOS may mark `$TMPDIR` as system-managed (`com.apple.rootless`), so Neovim cannot create its RPC socket there and logs `server_start: Failed to start server: operation not permitted`. Use a private runtime directory instead:
  1. `mkdir -p ~/.cache/nvim/run && chmod 700 ~/.cache/nvim/run`
  2. Export `XDG_RUNTIME_DIR="$HOME/.cache/nvim/run"` before launching Neovim (add it to `~/.zshenv` or your shell profile).
  3. Remove the old `/var/folders/.../nvim.<user>` directory and `.nvimlog` once you confirm the warning is gone.
  This repository already ensures the directory exists at startup, but macOS still needs the environment variable exported so Neovim picks it up before runtime.
