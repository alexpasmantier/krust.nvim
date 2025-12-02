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

**Krust** automatically configures rust-analyzer to send colored diagnostics and sets up <kbd>\<leader\>k</kbd> as the default keybinding in Rust buffers.

```lua
-- With lazy.nvim
{
  "alexpasmantier/krust.nvim",
  ft = "rust",
  opts = {
    keymap = "<leader>d",  -- Change the keymap (default: "<leader>k")
    -- keymap = false,     -- Disable default keymap
    float_win = {
      border = "rounded",    -- Border style: "none", "single", "double", "rounded", "solid", "shadow"
      auto_focus = false,    -- Auto-focus float (default: false)
    },
  },
}
```

**Note:** If rust-analyzer starts before krust.nvim loads, you may need `:LspRestart` for colors to appear. To avoid this, load `krust.nvim` before your LSP config.

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

### Behavior

**Krust** tries to behave like LSP hover documentation windows:

- **First press** of `<leader>k`: Opens the floating window (not focused)
- **Second press** of `<leader>k`: Enters the floating window so you can scroll
- **`q` or `<Esc>`**: Closes the window

With `auto_focus = true`, the window opens focused immediately, so you can scroll right away.

The window automatically closes when you move the cursor in the original buffer.

## Why use this?

- **Minimal** - if all you care about is having nicely formatted Rust diagnostics
- **Zero configuration** - works out of the box

## Credits

This was greatly inspired by [rustaceanvim](https://github.com/mrcjkb/rustaceanvim)'s diagnostic rendering.
