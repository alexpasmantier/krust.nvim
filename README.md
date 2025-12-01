# krust.nvim

![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

Improved Rust diagnostics rendering for Neovim's rust-analyzer LSP client.

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "alexpasmantier/krust.nvim",
  ft = "rust",
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "alexpasmantier/krust.nvim",
  ft = "rust",
}
```

## Configuration

The plugin **automatically configures** rust-analyzer to send colored diagnostics and sets up `<leader>k` as the default keybinding in Rust buffers.

If this conflicts with your setup, you can customize or disable the keybinding:

```lua
-- With lazy.nvim
{
  "alexpasmantier/krust.nvim",
  ft = "rust",
  opts = {
    keymap = "<leader>d",  -- Change the keymap
    -- keymap = false,     -- Disable default keymap
  },
}
```

**Note:** If rust-analyzer starts before krust.nvim loads, you may need `:LspRestart` for colors to appear. To avoid this, load krust.nvim before your LSP config.

## Usage

**Default keybinding:** `<leader>k` in Rust buffers

Or use the command:

```vim
:Krust
```

Or call from Lua:

```lua
require('krust').render()
```

A floating window will appear showing the full formatted diagnostic. Press `q` or `<Esc>` to close it.

## Why use this?

- **Minimal** - if all you care about is having nicely formatted Rust diagnostics
- **Zero configuration** - works out of the box with rust-analyzer

## Credits

Inspired by [rustaceanvim](https://github.com/mrcjkb/rustaceanvim)'s diagnostic rendering, but simplified and
standalone.
