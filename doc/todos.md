# Future Work and Notes

## Feature To-Dos and Ideas

No new functionality in the near future, until requested.

## Next Announcement

* v0.0.2
* When we have missing functionality issues fixed
* [Discourse](https://neovim.discourse.group/)
* [Community](https://neovim.io/community/)

## Crazy ideas

These are sorted least to most insane.
None of these are high priority.
If anyone requests these, I'll move it up to the top of the file.

* LSP integration
  - LSP remove/move events notify this plugin.
  - Or, this plugin notifies LSP.
* Built-in Tree support: neo-tree, nvim-tree
  - See also nvim-lsp-file-operations
* Events
  - `Ax[Pre] AxMove[Pre]`
  - See lazy.nvim for example code.  Find `nvim_exec_autocmds`
  - lazy config: `event = { "Ax", "AxPre", "AxForget", "AxForgetPre", "AxMove", "AxMovePre" }`
  - Not called when functions are used.  `ax() ax_move()`
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

## Missing Functionality

* Implement `move_local_marks()`
* Command file autocompletion
* Document functions - `ax([file])` `ax_move(f1, f2)`

## General Tech debt and Performance

* Use reflection to simplify `M.leak()`.  https://www.lua.org/pil/23.1.1.html
* Refactor.  `init.lua` is too big.
* Reduce duplicate code
* Use `saveas!` to move current buffer
* Is it inefficient and unnecessary to normalize to full paths with `paths_same()`?
* For move and Ax <file>, determine if buffer is already loaded

## Testing improvments and validate

* Investigate shada contents to ensure complete removal
* Unit test: move functions.  unstash
* Unit tests "given" state should be inverse of final "then" state
* In `remove_current_buffer()`, `nvim_buf_delete()` is noisy.

## Problematic code

This is code that exists that has issues
or code that may help with an issue.
It's just here for my reference.

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

```lua
--[[
NEOVIM HELP:

vim.api.nvim_exec_autocmds({event}, {*opts})                    *nvim_exec_autocmds()*
    Execute all autocommands for {event} that match the corresponding {opts}
    |autocmd-execute|.

    Parameters:  
      • {event}  (String|Array) The event or events to execute
      • {opts}   Dictionary of autocmand options:
                 • group (string|integer) optional: the autocmand group name
                   or id to match against. |autocmd-groups|.
                 • pattern (string|array) optional: defaults to "*"
                   |autocmd-pattern|. Cannot be used with {buffer}.
                 • buffer (integer) optional: buffer number
                   |autocmd-buflocal|. Cannot be used with {pattern}.
                 • modeline (bool) optional: defaults to true. Process the
                   modeline after the autocmands |<nomodeline>|.
                 • data (any): arbitrary data to send to the autocmand
                   callback. See |nvim_create_autocmd()| for details.

    Example usage:

          vim.api.nvim_exec_autocmds("User", {
            pattern = "TelescopePreviewerLoaded",
            data = {
              title = entry.preview_title,
              bufname = self.state.bufname,
              filetype = putils.filetype_detect(self.state.bufname or ""),
            },
          })

    See also:  
      • |:doautocmd|

nvim_create_autocmd({event}, {*opts})                  *nvim_create_autocmd()*
    Creates an |autocommand| event handler, defined by `callback` (Lua function or Vimscript function name string) or `command` (Ex command string).

    Example using Lua callback: >lua
        vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
          pattern = {"*.c", "*.h"},
          callback = function(ev)
            print(string.format('event fired: %s', vim.inspect(ev)))
          end
        })
<

    Example using an Ex command as the handler: >lua
        vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
          pattern = {"*.c", "*.h"},
          command = "echo 'Entering a C or C++ file'",
        })
<

    Note: `pattern` is NOT automatically expanded (unlike with |:autocmd|),
    thus names like "$HOME" and "~" must be expanded explicitly: >lua
        pattern = vim.fn.expand("~") .. "/some/path/*.py"
<

    Parameters:  
      • {event}  (string|array) Event(s) that will trigger the handler
                 (`callback` or `command`).
      • {opts}   Options dict:
                 • group (string|integer) optional: autocommand group name or
                   id to match against.
                 • pattern (string|array) optional: pattern(s) to match
                   literally |autocmd-pattern|.
                 • buffer (integer) optional: buffer number for buffer-local
                   autocommands |autocmd-buflocal|. Cannot be used with
                   {pattern}.
                 • desc (string) optional: description (for documentation and
                   troubleshooting).
                 • callback (function|string) optional: Lua function (or
                   Vimscript function name, if string) called when the
                   event(s) is triggered. Lua callback can return true to
                   delete the autocommand, and receives a table argument with
                   these keys:
                   • id: (number) autocommand id
                   • event: (string) name of the triggered event
                     |autocmd-events|
                   • group: (number|nil) autocommand group id, if any
                   • match: (string) expanded value of |<amatch>|
                   • buf: (number) expanded value of |<abuf>|
                   • file: (string) expanded value of |<afile>|
                   • data: (any) arbitrary data passed from
                     |nvim_exec_autocmds()|

                 • command (string) optional: Vim command to execute on event.
                   Cannot be used with {callback}
                 • once (boolean) optional: defaults to false. Run the
                   autocommand only once |autocmd-once|.
                 • nested (boolean) optional: defaults to false. Run nested
                   autocommands |autocmd-nested|.

    Return:  
        Autocommand id (number)

    See also:  
      • |autocommand|
      • |nvim_del_autocmd()|
--]]

-- TODO: For Ax and AxForget ensure that <afile> resolves to file.
-- TODO: For AxMove ensure that <afile> resolves to the first argument.
-- TODO: Use vim.api.nvim_exec_autocmds() to emit AxPre and Ax user events for the Ax command below. Ensure that <afile> resolves to fargs[1].

  -- Emit AxPre user event
  vim.api.nvim_exec_autocmds("User", {
    pattern = "AxPre",
    data = {
      afile = file,
      abuf = bufnr,
    },
  })
```
