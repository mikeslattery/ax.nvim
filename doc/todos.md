# Future Work and Notes

## Misc Ideas

* Events.  `Ax[Pre] AxMove[Pre]`
  - See layz.nvim for example code.  Find `nvim_exec_autocmds`
  - lazy config: `event = { "Ax", "AxPre", "AxMove", "AxMovePre" }`
  - Not called when functions are used.  `ax() ax_move()`
* Document functions - `ax([file])` `ax_move(f1, f2)`

## Announce

* v0.0.2
* When we have events, functions, and critical issues fixed.
* [Discourse](https://neovim.discourse.group/)
* [Community](https://neovim.io/community/)

## Crazy ideas

These are sorted least to most insane.

* Tree support: netrw, nvim-tree
* In `AxAudit` check if other *recent* branches have file that doesn't exist.
  - Use `git reflog`or `@{-1}` to discover recent branches
  - Emit: `" Exists in branches: develop, main`
  - `git ls-tree --name-only branch-name -- path/to/file`
  - Also current branch, in case the file has been Axed but not committed.
* `AxUndelete [<file>]`
  - Keep deleted files in OS concept of Trash or temp folder
  - In data directory maintain a `.vim` log file of deletes.
  - `AxLog` to load log.  Lines of `AxUndelete` and `AxMove`
  - Ask user if they want to restore shada backup
  - As part of ax, generate `<filename>-unrm.vim` file, which restores all
* Vim-lua shim

# Issues

* Unit test: move functions
* Unit tests "given" state should be inverse of final "then" state
* Use `saveas!` to move current buffer
* move local marks
* For move and Ax <file>, determine if buffer is already loaded
* Is it inefficient and unnecessary to normalize to full paths with `paths_same()`?
* Refactor.  `init.lua` is too big.

## Problematic code

This is code that exists that has issues
or code that may help with an issue.
It's here for reference.

Consider testing a project-local file

```lua
local function move_local_marks(oldfile, newfile)
end
```

```lua
  before_each(function()
    temp_file_path = 'test/tempfile.txt'
    os.execute('[[ -f ' .. temp_file_path .. ' ]] || touch ' .. temp_file_path)
    os.remove(temp_file_path )
```

```lua
function is_buffer_hidden(bufnr)
  -- Check if the buffer is loaded
  if not vim.api.nvim_buf_is_loaded(bufnr) then
    return false
  end

  -- Iterate over all windows to see if the buffer is visible
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == bufnr then
      -- The buffer is visible in a window, so it's not hidden
      return false
    end
  end

  -- If we reached this point, the buffer is loaded but not visible in any window
  return true
end
```
