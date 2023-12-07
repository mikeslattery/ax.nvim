# List of Possible Features

## Misc Ideas

* `AxAudit[!]` - Generate vimscript of `:Ax` commands for missing oldfiles
* `Ax [<path>]` - Specify path
* `AxMove [<oldpath>] <newpath>` - Move file location

## Issues

* Normalize full paths if necessary: `vim.fn.namemodify(path, ':p:p')`

### Problematic code

Consider testings a project-local file

```lua
  before_each(function()
    temp_file_path = 'test/tempfile.txt'
    os.execute('[[ -f ' .. temp_file_path .. ' ]] || touch ' .. temp_file_path)
    os.remove(temp_file_path )
```
