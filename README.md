# For Neovim

## Introduction

Ax is a Neovim plugin that provides commands to remove files and their traces from Neovim's state. It can also move files and update Neovim's state to reflect the new file location.

## Installation

To install the ax plugin, you can use a package manager like vim-plug or lazy.nvim.

Using vim-plug:

```vim
Plug 'mikeslattery/ax.nvim'
```

Using lazy.nvim:

```lua
{ "mikeslattery/ax.nvim", cmd = { "Ax", "AxForget", "AxMove", "AxMoved", "AxAudit" } }
```

## Commands

Ax provides the following commands:

- `:Ax [file]`: Deletes the file and removes all traces of it from Neovim's state. If no file is provided, it applies to the current buffer.

- `:AxForget [file]`: Removes all traces of the file from Neovim's state but does not delete the file. If no file is provided, it applies to the current buffer.

- `:AxMove [oldfile] [newfile]`: Moves the file from oldfile to newfile and updates Neovim's state to reflect the new file location.

- `:AxMoved [oldfile] [newfile]`: Updates Neovim's state to reflect that the file has been moved from oldfile to newfile.  This might be used when a move happens externally.

- `:AxAudit`: Generates a report of files that are remembered by Neovim but no longer exist.

## Configuration

Ax does not currently have any configuration options.
