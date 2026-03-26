# Minibuffer.nvim (fork)

![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

> Fork of [simifalaye/minibuffer.nvim](https://github.com/simifalaye/minibuffer.nvim), updated to work with Neovim master (`HEAD`) since the original repository is no longer maintained.

A general purpose interactive interface for Neovim.

https://github.com/user-attachments/assets/d69b3d3a-03d9-4285-aebb-23d1d895b831

## Changes from upstream

- Updated to work with Neovim master (the original targets `0.12` nightly)
- Uses `vim._core.ui2` instead of the deprecated `vim._extui`

## Prerequisites

- Neovim built from `master`
- Enable the new UI early in your `init.lua`:

```lua
require("vim._core.ui2").enable({ enable = true, msg = { target = "cmd" } })
```

## Usage

```lua
vim.ui.select = require("minibuffer.builtin.ui_select")
vim.ui.input = require("minibuffer.builtin.ui_input")

vim.keymap.set("n", "<M-;>", require("minibuffer.builtin.cmdline"))
vim.keymap.set("n", "<M-.>", function()
  require("minibuffer").resume(true)
end)
```

## Integrations

### FFF.nvim

```lua
local picker_ui = require("fff.picker_ui")
picker_ui.open = require("minibuffer.integrations.fff")
```

## Credits

Original plugin by [simifalaye](https://github.com/simifalaye/minibuffer.nvim).
