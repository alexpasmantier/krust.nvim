<div align="center" style="color: #abb2bf;font-family: 'Fira Code', monospace;">

# krust.nvim

[![Neovim](https://img.shields.io/badge/Neovim-0.9%2B-7e98e8.svg?style=for-the-badge&logo=neovim)](https://neovim.io/)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-8faf77.svg?style=for-the-badge&logo=lua)

**🦀 Nicer Rust diagnostics for Neovim.**

<img title="krust.nvim" src="assets/krust.png" alt="krust.nvim screenshot"/>

</div>

## Why?

To be able to read complete Rust compiler diagnostics in Neovim with proper colors and formatting, similar to how they appear when running cargo in the terminal.

## Installation

### [`lazy.nvim`](https://github.com/folke/lazy.nvim)

```lua
{
  "alexpasmantier/krust.nvim",
  ft = "rust",
}
```

### [`packer.nvim`](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "alexpasmantier/krust.nvim",
  ft = "rust",
}
```

## Configuration

**Krust** automatically configures rust-analyzer to send colored diagnostics. No keybindings are set by default to avoid conflicts.

```lua
-- With lazy.nvim
{
  "alexpasmantier/krust.nvim",
  ft = "rust",
  opts = {
    keymap = "<leader>k",  -- Set a keymap for Rust buffers (default: false)
    float_win = {
      border = "rounded",    -- Border style: "none", "single", "double", "rounded", "solid", "shadow"
      auto_focus = false,    -- Auto-focus float (default: false)
    },
  },
}
```

**Note:** If rust-analyzer starts before krust.nvim loads, you may need `:LspRestart` for colors to appear. To avoid this, load `krust.nvim` before your LSP config.

## Usage

Use the command:

```vim
:Krust
```

Or call from Lua:

```lua
require('krust').render()
```

### Behavior

**Krust** tries to behave like LSP hover documentation windows:

- **First invocation**: Opens the floating window (not focused)
- **Second invocation**: Enters the floating window so you may scroll
- **`q` or `<Esc>`**: Closes the window

## Credits

This was inspired by [rustaceanvim](https://github.com/mrcjkb/rustaceanvim)'s diagnostic rendering.
