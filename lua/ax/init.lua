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

-- Execute a shell command quietly, and return true if successful.
local function execute_quiet(cmdline)
   local stdout
   if package.config:sub(1,1) == '\\' then
     -- This is Windows
     stdout = 'nul'
   else
     stdout = '/dev/null'
   end
   return os.execute(cmdline .. ' > ' .. stdout .. ' 2>' .. stdout) == 0
end

local function is_git_managed(file)
  return execute_quiet('git ls-files --error-unmatch ' .. file)
end

local function is_git_managed(file)
  local stdout
  if package.config:sub(1,1) == '\\' then
    -- This is Windows
    stdout = 'nul'
  else
    stdout = '/dev/null'
  end
  return os.execute('git ls-files --error-unmatch ' .. file .. ' > ' .. stdout .. ' 2>&1') == 0
end

local function paths_same(path1, path2)
  return vim.fn.fnamemodify(path1, ':p') == vim.fn.fnamemodify(path2, ':p') 
end

local function exists(file)
  return fn.filereadable(file) == 1
end

local function missing_files()
  local missing_files = {}
  for _, file in ipairs(v.oldfiles) do
    local path = vim.fn.fnamemodify(file, ':p')
    if not exists(path) then
      table.insert(missing_files, path)
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
  local missing_files = missing_files()
  local temp_file = fn.tempname() .. ".vim"

  local lines_to_write = {
    '" AxAudit Report',
    '',
    '" These paths are remembered but no longer exist.',
    '" To clear them run:',
    '" :source %',
    ''
  }

  for _, file in ipairs(missing_files) do
    table.insert(lines_to_write, 'Ax ' .. file)
  end
  local shada_file
  if #missing_files > 0 then
    shada_file = save_shada_to_backup_file()
  end

  table.insert(lines_to_write, '" This audit file')
  table.insert(lines_to_write, 'Ax ' .. temp_file)
  table.insert(lines_to_write, '')
  table.insert(lines_to_write, 'wshada!')

  if shada_file then
    table.insert(lines_to_write, '')
    table.insert(lines_to_write, '" State was backed up and can be restored with:')
    table.insert(lines_to_write, '" :rshada ' .. shada_file)
  end

  vim.fn.writefile(lines_to_write, temp_file)

  vim.cmd('edit ' .. temp_file)
end

local function unload_file(file)
  local bufnr = vim.fn.bufnr(file)

  if bufnr >= 0 then
    vim.api.nvim_buf_delete(bufnr, {force = true})
  end
end

-- Deletes file.
-- If file is in git, it removes from git as well.
local function remove_file(file)
  if is_git_managed(file) then
    execute_quiet('git rm -f ' .. file)
  else
    os.remove(file)
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

local function remove_from_jumplist(file)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    vim.api.nvim_set_current_win(win)
    local jumplist = fn.getjumplist()[1]
    for i, jump in ipairs(jumplist) do
      if paths_same(jump.file, file) then
        table.remove(jumplist, i)
        vim.cmd('call remove(getjumplist()[1], ' .. (i - 1) .. ')')
      end
    end
  end
end

local function remove_from_changelist(file)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    vim.api.nvim_set_current_win(win)
    local changelist = fn.getchangelist()[1]
    for i, change in ipairs(changelist) do
      if paths_same(change.filename, file) then
        vim.cmd('call remove(getchangelist()[1], ' .. (i - 1) .. ')')
      end
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

local function load_file_into_hidden_buffer(filepath)
  local buf = vim.fn.bufnr(filepath)
  if buf == -1 then
    buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_name(buf, filepath)
  end
  vim.fn.bufload(buf)

  return buf
end

local function remove_local_marks(file)
  local bufnr = load_file_into_hidden_buffer(file)

  local marks = fn.getmarklist(bufnr)
  for i, mark in ipairs(marks) do
    if mark.mark ~= "'." then
      api.nvim_buf_del_mark(bufnr, string.sub(mark.mark, -1))
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

local function remove_from_loclist(file)
  local tabs = vim.api.nvim_list_tabpages()
  for _, tab in ipairs(tabs) do
    local windows = vim.api.nvim_tabpage_list_wins(tab)
    for _, win in ipairs(windows) do
      local loclist = fn.getloclist(win)
      for i, item in ipairs(loclist) do
        if paths_same(item.filename, file) then
          table.remove(loclist, i)
        end
      end
      fn.setloclist(win, loclist)
    end
  end
end

local function remove_current_buffer()
  buffer_reference = vim.api.nvim_get_current_buf()
  if #vim.api.nvim_tabpage_list_wins(0) > 1 then
    vim.cmd('bn')
  end
  -- This emits output
  api.nvim_buf_delete(buffer_reference, {force = true})
end

function M.ax(file)
  local file = M.ax_forget(file)
  remove_file(file)
  return file
end

-- Forget the file, but don't delete it
function M.ax_forget(file)
  -- If no file, then apply to current buffer
  if not file then
    file = api.nvim_buf_get_name(0)
    remove_current_buffer()
  else
    unload_file(file)
  end
  remove_from_oldfiles(file)
  remove_from_jumplist(file)
  remove_from_changelist(file)
  remove_global_marks(file)
  remove_local_marks(file)
  remove_from_quickfix(file)
  remove_from_loclist(file)
  return file
end

-- File was moved outside of ax or neovim
function M.ax_moved(oldfile, newfile)
  if not exists(oldfile) and exists(newfile) then
    -- This is a kludge, but there's no simple way around it.
    os.rename(newfile, oldfile)
    M.ax_move(oldfile, newfile)
  end
end

function M.ax_move(oldfile, newfile)
  if exists(oldfile) then
    local bufnr = vim.fn.bufnr(oldfile)
    if bufnr >= 0 then
      vim.cmd.b(bufnr)
      vim.cmd.saveas(newfile)
      vim.cmd('b#')
    else
      vim.cmd.edit(oldfile)
      vim.cmd.saveas(newfile)
      vim.cmd.bdelete()
    end
    M.ax(oldfile)
  end
end

function M.setup(setup_config)
  setup_config = setup_config or {}
  M.config(setup_config)
  vim.api.nvim_create_user_command('Ax', function(args)
    if #args.fargs >= 1 then
      M.ax(args.fargs[1])
    else
      M.ax()
    end
  end, { nargs = "*" })
  
  vim.api.nvim_create_user_command('AxForget', function(args)
    if #args.fargs >= 1 then
      M.ax_forget(args.fargs[1])
    else
      M.ax_forget()
    end
  end, { nargs = "*" })

  vim.api.nvim_create_user_command('AxMove', function(args)
    if #args.fargs == 2 then
      M.ax_move(args.fargs[1], args.fargs[2])
    else
      print("AxMove requires exactly 2 arguments")
    end
  end, { nargs = "*" })

  vim.api.nvim_create_user_command('AxMoved', function(args)
    if #args.fargs == 2 then
      M.ax_moved(args.fargs[1], args.fargs[2])
    else
      print("AxMoved requires exactly 2 arguments")
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
  M.unload_file = unload_file
  M.remove_file = remove_file
  M.remove_from_oldfiles = remove_from_oldfiles
  M.remove_from_jumplist = remove_from_jumplist
  M.remove_from_changelist = remove_from_changelist
  M.remove_global_marks = remove_global_marks
  M.remove_local_marks = remove_local_marks
  M.remove_from_quickfix = remove_from_quickfix
  M.remove_from_loclist = remove_from_loclist
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
