local ax = require('ax')


describe('ax.nvim', function()
  -- This test is run by plenary and make

  local temp_file_path
  local buffer_reference

  -- Let's not modify real data
  vim.opt.shadafile = 'test/main.shada'
  vim.v.this_session = 'test/Session.vim'

  before_each(function()
    ax.leak()
    ax.setup({})

    -- open a new buffer with a new temporary file and save it.
    temp_file_path = vim.fn.tempname()
    vim.cmd('edit! ' .. temp_file_path)
    buffer_reference = vim.api.nvim_get_current_buf()
    -- append a single line to the buffer
    vim.api.nvim_buf_set_lines(0, -1, -1, false, {"Test line"})
    vim.cmd('write')
  end)

  after_each(function()
    if temp_file_path and vim.fn.filereadable(temp_file_path) == 1 then
      os.remove(temp_file_path)
    end
  end)

  it('sanity', function()
    assert.are.same( buffer_reference, vim.api.nvim_get_current_buf())
    assert(vim.fn.filereadable(temp_file_path) == 1, "Temporary file must exist")
  end)

  it('paths_same', function()
    local path1 = temp_file_path
    local path2 = vim.fn.fnamemodify(temp_file_path, ':p') -- Get the full path
    assert(ax.paths_same(path1, path2), "Paths should be the same")
    local different_path = vim.fn.tempname()
    assert(not ax.paths_same(path1, different_path), "Paths should not be the same")
  end)

  it('is_git_managed', function()
    assert( ax.is_git_managed ('Makefile') , "Makefiles should be Git managed" )
  end)

  it('regular remove_file', function()
    -- given
    os.execute('touch normal_file.txt')
    -- sanity check
    assert( not ax.is_git_managed ('normal_file.txt'))

    -- when
    ax.remove_file('normal_file.txt')

    -- then
    assert(vim.fn.filereadable('normal_file.txt') == 0, "Temporary file must not exist")
  end)

  it('git remove_file', function()
    -- given
    os.execute('touch git_file.txt')
    os.execute('git add git_file.txt')
    -- sanity check
    assert( ax.is_git_managed ('git_file.txt'))

    -- when
    ax.remove_file('git_file.txt')

    -- then
    assert( not ax.is_git_managed ('git_file.txt'))
    assert(vim.fn.filereadable('git_file.txt') == 0, "Temporary file must not exist")
  end)

  it('Ax command', function()
    -- given
    assert(vim.fn.filereadable(temp_file_path) == 1, "Temporary file must exist")

    -- when
    vim.api.nvim_command('Ax')

    -- then
    assert(vim.fn.filereadable(temp_file_path) == 0, "Temporary file not must exist")
  end)

  it('remove_from_jumplist', function()
    -- given
    vim.cmd('normal m\'') -- Jump back to the mark to ensure the temp file is in the jumplist

    -- when
    ax.remove_from_jumplist(temp_file_path)

    -- then
    local jumplist = vim.fn.getjumplist()[1]
    for _, jump in ipairs(jumplist) do
      assert(jump.file ~= temp_file_path, "File should be removed from jumplist")
    end
  end)

  it('remove_from_changelist', function()
    -- given
    vim.api.nvim_buf_set_lines(0, -1, -1, false, {"Another test line"}) -- Make a change to add to the changelist

    -- when
    ax.remove_from_changelist(temp_file_path)

    -- then
    local changelist = vim.fn.getchangelist()[1]
    for _, change in ipairs(changelist) do
      assert(change.filename ~= temp_file_path, "File should be removed from changelist")
    end
  end)

  it('remove_global_marks', function()
    -- given
    vim.cmd('normal mZ') -- Add global mark Z to line in temp_file_path

    -- when
    ax.remove_global_marks(temp_file_path)

    -- then
    local marks = vim.fn.getmarklist()
    for _, mark in ipairs(marks) do
      assert(mark.file ~= temp_file_path, "File should be removed from global marks")
    end
  end)

  it('remove_from_quickfix', function()
    -- given
    vim.fn.setqflist({{filename = temp_file_path, lnum = 1, col = 1, text = "Test quickfix entry"}}) -- Add quickfix entry that references file temp_file_path

    -- when
    ax.remove_from_quickfix(temp_file_path)

    -- then
    local quickfix = vim.fn.getqflist()
    for _, item in ipairs(quickfix) do
      assert(item.filename ~= temp_file_path, "File should be removed from quickfix")
    end
  end)

  it('remove_from_oldfiles', function()
    -- given
    vim.v.oldfiles = {temp_file_path, "another_file.txt"}

    -- when
    ax.remove_from_oldfiles(temp_file_path)

    -- then
    assert(not vim.tbl_contains(vim.v.oldfiles, temp_file_path), "File should be removed from oldfiles")
  end)

  it('remove_local_marks', function()
    -- given
    vim.api.nvim_buf_set_lines(buffer_reference, -1, -1, false, {"Another test line"})
    vim.api.nvim_buf_set_mark(buffer_reference, 'a', 1, 0, {}) -- Set local mark 'a'

    -- when
    ax.remove_local_marks(temp_file_path)

    -- then
    local marks = vim.fn.getmarklist(buffer_reference)
    for _, mark in ipairs(marks) do
      assert(mark.mark ~= 'a', "Local mark 'a' should be removed")
    end
  end)

  it('remove_from_loclist', function()
    -- given
    local current_win = vim.api.nvim_get_current_win()
    vim.fn.setloclist(current_win, {{filename = temp_file_path, lnum = 1, col = 1, text = "Test loclist entry"}}) -- Add loclist entry that references file temp_file_path

    -- when
    ax.remove_from_loclist(temp_file_path)

    -- then
    local loclist = vim.fn.getloclist(current_win)
    for _, item in ipairs(loclist) do
      assert(item.filename ~= temp_file_path, "File should be removed from loclist")
    end
  end)

  it('move', function()
    -- given
    local new_file_path = vim.fn.tempname()
    vim.cmd.normal('ma')

    -- when
    ax.ax_move(temp_file_path, new_file_path)

    -- then
    assert(vim.fn.filereadable(new_file_path) == 1, "New file exists")
    assert(vim.fn.filereadable(temp_file_path) == 0, "Old file not exists")
  end)
end)
