ax.nvim is a plugin that aims to manage buffers and files in Neovim. It eases the file and buffer manipulation process in Neovim by providing a series of commands and functions, abstracting user from writing specific Neovim functions.

---

# INSTALLATION

Using vim-plug:

```vim
Plug 'mikeslattery/ax.nvim'
```

Using lazy.nvim:

```lua
{ "mikeslattery/ax.nvim", cmd = { "Ax", "AxForget", "AxMove", "AxAudit" } }
```

---

# COMMANDS

## Ax

Ax is a primary command of the ax.nvim plugin and is used to remove a file from the disk and also from various vim lists. It modifies global variables: oldfiles, jumplist and changelist.

Usage:

```vim
:Ax
:Ax {path}
```

## AxForget

Identical to Ax, but it won't delete an existing file.

Usage:

```vim
:AxForget {path}
```

## AxMove

AxMove is used to move a file to a new location. It also updates various vim lists to reflect the new location of the file.

Usage:

```vim
:AxMove {source} {destination}
:AxMove % {destination}
```

## AxAudit

AxAudit is used to generate a report that lists paths remembered by vim, but no longer exist. It also provides script to clear them.

Usage:

```vim
:AxAudit
```

---

# MAPPING

Example mappings:

```vim
nmap <Leader>ax :Ax<CR>
nmap <Leader>am :AxMove %<space>
nmap <Leader>aa :AxAudit<CR>
```

---

# COPYRIGHT

© 2023 Mike Slattery. Distributed under the MIT license.
