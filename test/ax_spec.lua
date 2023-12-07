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
    vim.cmd('enew')
    temp_file_path = vim.fn.tempname()
    vim.cmd('edit ' .. temp_file_path)
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

  it('is_git_managed', function()
    assert( ax.is_git_managed ('Makefile') , "Git managed" )
  end)

  it('regular delete_file', function()
    -- given
    os.execute('touch normal_file.txt')
    -- sanity check
    assert( not ax.is_git_managed ('normal_file.txt'))

    -- when
    ax.delete_file('normal_file.txt')

    -- then
    assert(vim.fn.filereadable('normal_file.txt') == 0, "Temporary file must not exist")
  end)

  it('git delete_file', function()
    -- given
    os.execute('touch git_file.txt')
    os.execute('git add git_file.txt')
    -- sanity check
    assert( ax.is_git_managed ('git_file.txt'))

    -- when
    ax.delete_file('git_file.txt')

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
end)
