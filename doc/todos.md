# List of Possible Features

## Misc Ideas

* `ax([file])` `ax_move(f1, f2)` - document

## Code snippets


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

## Announce

When we have audit and move.

# Issues

* Unit test: audit, move
* Unit tests given state should be inverse of final then state
* Use `saveas!` to move current buffer
* move local marks
* For move and Ax <file>, determine if buffer is already loaded
* Is it inefficient and unnecessary to normalize to full paths with `paths_same()`?

## Problematic code

Consider testings a project-local file

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
