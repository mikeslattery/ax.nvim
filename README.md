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

Include Ax in your configuration like this:

    {
      "mikeslattery/ax.nvim",
    }

Refer to the lazy.nvim documentation for more details on using this package manager.

## USAGE

After installing ax, you can use the provided `:Ax` command to delete the current buffer's associated file and cleanse its references from Neovim's data structures.

For more details on configuration and usage, please refer to the repository README at [https://github.com/mikeslattery/ax.nvim](https://github.com/mikeslattery/ax.nvim).

## LICENSE

Ax is distributed under the MIT License. For more details, see the LICENSE file in the repository.

## COPYRIGHT

Copyright (c) 2023 Michael Slattery. All rights reserved.
