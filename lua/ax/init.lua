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

-- TODO: Write a unit test in ax_spec for this function
local function paths_same(path1, path2)
  -- Using ':p' twice is redundant, as it already expands to the full path
  return vim.fn.fnamemodify(path1, ':p') == vim.fn.fnamemodify(path2, ':p') 
end

local function delete_file(file)
  if is_git_managed(file) then
    os.execute('git rm -f ' .. file .. ' > /dev/null')
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
  local jumplist = fn.getjumplist()[1]
  for i, jump in ipairs(jumplist) do
    if paths_same(jump.file, file) then
      table.remove(jumplist, i)
      vim.cmd('call remove(getjumplist()[1], ' .. (i - 1) .. ')')
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

local function remove_global_marks(file)
  local marks = fn.getmarklist()
  for i, mark in ipairs(marks) do
    if paths_same(mark.file, file) then
      api.nvim_del_mark(string.sub(mark.mark, -1))
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
  local current_win = vim.api.nvim_get_current_win()
  local loclist = fn.getloclist(current_win)
  for i, item in ipairs(loclist) do
    if paths_same(item.filename, file) then
      table.remove(loclist, i)
    end
  end
  fn.setloclist(current_win, loclist)
end

function M.ax()
  local file = api.nvim_buf_get_name(0)
  api.nvim_buf_delete(0, {force = true})
  delete_file(file)
  remove_from_oldfiles(file)
  remove_from_jumplist(file)
  remove_from_changelist(file)
  remove_global_marks(file)
  remove_from_quickfix(file)
  remove_from_loclist(file)
end

function M.setup(setup_config)
  setup_config = setup_config or {}
  M.config(setup_config)
  vim.api.nvim_create_user_command('Ax', function(args)
    M.ax()
  end, { nargs = "*" })
  return M
end

-- leak internals for testing purposes
-- Do not include in documentation.
function M.leak()
  M.is_git_managed = is_git_managed
  M.paths_same = paths_same
  M.delete_file = delete_file
  M.remove_from_oldfiles = remove_from_oldfiles
  M.remove_from_jumplist = remove_from_jumplist
  M.remove_from_changelist = remove_from_changelist
  M.remove_global_marks = remove_global_marks
  M.remove_from_quickfix = remove_from_quickfix
  M.remove_from_loclist = remove_from_quickfix
  return M
end

-- Force reload of plugin.  Useful during development.
-- Do not include in documentation.
function M.reload()
  package.loaded['ax'] = nil
  local m = require('ax')
  m.setup(config)
  return m
end

return M
