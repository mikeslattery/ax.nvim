# AX PLUGIN

Ax is a Neovim plugin that provides a convenient way to delete files, cleansing them from various Neovim data structures such as oldfiles, jumplists, quickfix lists, and more.

## INSTALLATION

The plugin can be installed using vim-plug or lazy.nvim package managers.

### For vim-plug:

1. Add the following line to your vimrc within the plug block:

```
Plug 'mikeslattery/ax.nvim'
```

2. Then, run `:PlugInstall` in Neovim to install the plugin.

### For lazy.nvim package manager:

1. Add this within your lazy.nvim configuration Lua table:

```lua
{
  dir = "~/path/to/ax.nvim",
  setup = function() require("ax").setup() end,
  config = function() require("ax").config({/* your config */}) end,
}
```

The `dir` field should be the path to the locally cloned repository or can be omitted to fetch automatically from GitHub.

2. Follow the setup instructions of lazy.nvim to complete the installation.

## USAGE

After installing ax, you can use the provided `:Ax` command to delete the current buffer's associated file and cleanse its references from Neovim's data structures.

For more details on configuration and usage, please refer to the repository README at [https://github.com/mikeslattery/ax.nvim](https://github.com/mikeslattery/ax.nvim).

## CONFIGURATION

Ax doesn't require explicit configuration, but it can be customized if needed through the setup function. Example:

```lua
lua require('ax').setup({
  -- your configuration here
})
```

## LICENSE

Ax is distributed under the MIT License. For more details, see the LICENSE file in the repository.

## COPYRIGHT

Copyright (c) 2023 Michael Slattery. All rights reserved.
