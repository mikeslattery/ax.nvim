# List of Possible Features

## Misc Ideas

* Unit test: audit, move
* `AxAudit!` - Run immediately.
* `Ax [<path>]` - Specify path
* `ax([file])` `ax_move([f1,] f2)` - document

## Code snippets


```lua
-- TODO: find all paths in oldfiles that do not exist on disk and return as table.
```

```lua
  vim.api.nvim_create_user_command('AxMove', function(args)
    M.ax_move(args.fargs[1], args.fargs[2])
  -- end, { nargs = 2 })
  end, { nargs = "*" })
```

## Announce

When we have audit and move.

# Issues

* Audit isn't finding files
* Is it inefficient and unnecessary to normalize to full paths with `paths_same()`?

## Problematic code

Consider testings a project-local file

```lua
  before_each(function()
    temp_file_path = 'test/tempfile.txt'
    os.execute('[[ -f ' .. temp_file_path .. ' ]] || touch ' .. temp_file_path)
    os.remove(temp_file_path )
```
