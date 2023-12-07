local api = vim.api
local fn = vim.fn
local v = vim.v

local M = {}

-- Configuration options, with defaults
local config = {}

function M.config(user_config)
  config = vim.tbl_deep_extend("force", config, user_config)
  return config
end

local function is_git_managed(file)
  return os.execute('git ls-files --error-unmatch ' .. file .. ' > /dev/null 2>&1') == 0
end

local function paths_same(path1, path2)
  return vim.fn.fnamemodify(path1, ':p') == vim.fn.fnamemodify(path2, ':p') 
end

local function missing_files()
  local missing_files = {}
  for _, file in ipairs(v.oldfiles) do
    if not fn.filereadable(file) then
      table.insert(missing_files, file)
    end
  end
  return missing_files
end

-- Get the current date in the format YYYYMMDD
local function get_date()
  return vim.fn.strftime('%Y%m%d')
end

-- Generate a backup file name
local function get_backup_file_name(dir, date, index)
  return string.format('%s/shada.%s-%d.bak', dir, date, index)
end

-- Get the next available backup file name
local function get_next_backup_file_name(dir, date)
  local index = 1
  while vim.loop.fs_stat(get_backup_file_name(dir, date, index)) do
    index = index + 1
  end
  return get_backup_file_name(dir, date, index)
end

local function save_shada_to_backup_file()
  local backup_dir = vim.api.nvim_eval('&backupdir')
  -- Remove any trailing backslashes
  backup_dir = backup_dir:gsub('/+$', "")
  vim.fn.mkdir(backup_dir, "p")
  local date = get_date()
  local backup_file_name = get_next_backup_file_name(backup_dir, date)
  vim.api.nvim_command('wshada ' .. backup_file_name)

  return backup_file_name
end

function M.audit()
  local missing_files = M.missing_files()
  local temp_file = fn.tempname() .. ".vim"

  local lines_to_write = {
    '" AxAudit Report',
    '',
    '" These paths are remembered but no longer exist.',
    '" To clear them run:',
    '" :source %',
    ''
  }

  local shada_file
  if #missing_files == 0 then
    table.insert(lines_to_write, '" None found')
  else
    for _, file in ipairs(missing_files) do
      table.insert(lines_to_write, 'Ax ' .. file)
    end
    shada_file = save_shada_to_backup_file()
  end

  table.insert(lines_to_write, 'Ax')

  if shada_file then
    table.insert(lines_to_write, '')
    table.insert(lines_to_write, '" State was backed up and can be restored with:')
    table.insert(lines_to_write, '" :rshada ' .. shada_file)
  end

  vim.fn.writefile(lines_to_write, temp_file)

  vim.cmd('edit ' .. temp_file)
end

-- Deletes file.
-- If file is in git, it removes from git as well.
local function remove_file(file)
  if is_git_managed(file) then
    os.execute('git rm -f ' .. file .. ' > /dev/null')
  else
    os.remove(file)
  end
end

-- Moves file.
-- If file is in git, it moves using git.
local function move_file(oldfile, newfile)
  if is_git_managed(oldfile) then
    os.execute('git mv ' .. oldfile .. ' ' .. newfile)
  else
    os.rename(oldfile, newfile)
  end
end

local function move_buffer(oldfile, newfile)
  if paths_same(api.nvim_buf_get_name(0), oldfile) then
    api.nvim_buf_set_name(0, newfile)
  end
end

local function remove_from_oldfiles(file)
  local oldfiles = v.oldfiles
  for i, oldfile in ipairs(oldfiles) do
    if paths_same(oldfile, file) then
      table.remove(oldfiles, i)
      vim.cmd('call remove(v:oldfiles, ' .. (i - 1) .. ')')
      break
    end
  end
end

local function move_from_oldfiles(oldfile, newfile)
  local oldfiles = v.oldfiles
  for i, oldfile_path in ipairs(oldfiles) do
    if paths_same(oldfile_path, oldfile) then
      oldfiles[i] = newfile
      vim.cmd('let v:oldfiles[' .. (i - 1) .. '] = ' .. vim.fn.fnameescape(newfile))
      break
    end
  end
end

local function remove_from_jumplist(file)
  local jumplist = fn.getjumplist()[1]
  for i, jump in ipairs(jumplist) do
    if paths_same(jump.file, file) then
      table.remove(jumplist, i)
      vim.cmd('call remove(getjumplist()[1], ' .. (i - 1) .. ')')
    end
  end
end

local function move_from_jumplist(oldfile, newfile)
  local jumplist = fn.getjumplist()[1]
  for i, jump in ipairs(jumplist) do
    if paths_same(jump.file, oldfile) then
      jumplist[i].file = newfile
      vim.cmd('let getjumplist()[1][' .. (i - 1) .. '].file = ' .. vim.fn.fnameescape(newfile))
    end
  end
end

local function remove_from_changelist(file)
  local changelist = fn.getchangelist()[1]
  for i, change in ipairs(changelist) do
    if paths_same(change.filename, file) then
      vim.cmd('call remove(getchangelist()[1], ' .. (i - 1) .. ')')
    end
  end
end

local function move_from_changelist(oldfile, newfile)
  local changelist = fn.getchangelist()[1]
  for i, change in ipairs(changelist) do
    if paths_same(change.filename, oldfile) then
      changelist[i].filename = newfile
      vim.cmd('let getchangelist()[1][' .. (i - 1) .. '].filename = ' .. vim.fn.fnameescape(newfile))
    end
  end
end

local function remove_global_marks(file)
  local marks = fn.getmarklist()
  for i, mark in ipairs(marks) do
    if paths_same(mark.file, file) then
      api.nvim_del_mark(string.sub(mark.mark, -1))
    end
  end
end

local function move_global_marks(oldfile, newfile)
  local marks = fn.getmarklist()
  for i, mark in ipairs(marks) do
    if paths_same(mark.file, oldfile) then
      api.nvim_set_mark(string.sub(mark.mark, -1), newfile, mark.pos[1], mark.pos[2])
    end
  end
end

local function remove_from_quickfix(file)
  local quickfix = fn.getqflist()
  for i, item in ipairs(quickfix) do
    if paths_same(item.filename, file) then
      table.remove(quickfix, i)
    end
  end
  fn.setqflist(quickfix)
end

local function move_from_quickfix(oldfile, newfile)
  local quickfix = fn.getqflist()
  for i, item in ipairs(quickfix) do
    if paths_same(item.filename, oldfile) then
      quickfix[i].filename = newfile
    end
  end
  fn.setqflist(quickfix)
end

local function remove_from_loclist(file)
  local current_win = vim.api.nvim_get_current_win()
  local loclist = fn.getloclist(current_win)
  for i, item in ipairs(loclist) do
    if paths_same(item.filename, file) then
      table.remove(loclist, i)
    end
  end
  fn.setloclist(current_win, loclist)
end

local function move_from_loclist(oldfile, newfile)
  local current_win = vim.api.nvim_get_current_win()
  local loclist = fn.getloclist(current_win)
  for i, item in ipairs(loclist) do
    if paths_same(item.filename, oldfile) then
      loclist[i].filename = newfile
    end
  end
  fn.setloclist(current_win, loclist)
end

local function remove_current_buffer()
  buffer_reference = vim.api.nvim_get_current_buf()
  if #vim.api.nvim_tabpage_list_wins(0) > 1 then
    vim.cmd('bn')
  end
  api.nvim_buf_delete(buffer_reference, {force = true})
end

function M.ax()
  local file = api.nvim_buf_get_name(0)
  remove_current_buffer()
  remove_file(file)
  remove_from_oldfiles(file)
  remove_from_jumplist(file)
  remove_from_changelist(file)
  remove_global_marks(file)
  remove_from_quickfix(file)
  remove_from_loclist(file)
end

function M.ax_move(oldfile, newfile)
  remove_file(oldfile)
  move_buffer(oldfile, newfile)
  move_from_oldfiles(oldfile, newfile)
  move_from_jumplist(oldfile, newfile)
  move_from_changelist(oldfile, newfile)
  move_global_marks(oldfile, newfile)
  move_from_quickfix(oldfile, newfile)
  move_from_loclist(oldfile, newfile)
end

function M.setup(setup_config)
  setup_config = setup_config or {}
  M.config(setup_config)
  vim.api.nvim_create_user_command('Ax', function(args)
    M.ax()
  end, { nargs = "*" })
  
  vim.api.nvim_create_user_command('AxMove', function(args)
    if #args.fargs == 2 then
      M.ax_move(args.fargs[1], args.fargs[2])
    else
      print("AxMove requires exactly 2 arguments")
    end
  end, { nargs = "*" })

  vim.api.nvim_create_user_command('AxAudit', function(args)
    M.audit()
  end, { nargs = "*" })
  return M
end

-- leak internals for testing purposes
-- Do not include in vim help
function M.leak()
  M.is_git_managed = is_git_managed
  M.paths_same = paths_same
  M.remove_file = remove_file
  M.remove_from_oldfiles = remove_from_oldfiles
  M.remove_from_jumplist = remove_from_jumplist
  M.remove_from_changelist = remove_from_changelist
  M.remove_global_marks = remove_global_marks
  M.remove_from_quickfix = remove_from_quickfix
  M.remove_from_loclist = remove_from_quickfix
  M.move_from_oldfiles = move_from_oldfiles
  M.move_from_jumplist = move_from_jumplist
  M.move_from_changelist = move_from_changelist
  M.move_global_marks = move_global_marks
  M.move_from_quickfix = move_from_quickfix
  M.move_from_loclist = move_from_loclist
  M.move_file = move_file
  M.move_buffer = move_buffer
  return M
end

-- Force reload of plugin.  Useful during development.
-- Do not include in vim help
function M.reload()
  package.loaded['ax'] = nil
  local m = require('ax')
  m.setup(config)
  return m
end

return M
