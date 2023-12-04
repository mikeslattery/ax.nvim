local ax = require('ax')

describe('ax.nvim', function()
  -- This test is run by plenary and make

  local temp_file_path
  local buffer_reference

  before_each(function()
    ax.leak()
    ax.setup({})

    -- open a new buffer with a new temporary file and save it.
    vim.cmd('enew')
    temp_file_path = vim.fn.tempname()
    vim.cmd('edit ' .. temp_file_path)
    vim.cmd('write')
    buffer_reference = vim.api.nvim_get_current_buf() -- Save a reference to the buffer
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
    os.execute('touch normal_file.txt')
    -- sanity check
    assert( not ax.is_git_managed ('normal_file.txt'))

    ax.delete_file('normal_file.txt')

    assert(vim.fn.filereadable('normal_file.txt') == 0, "Temporary file must not exist")
  end)

  it('git delete_file', function()
    os.execute('touch git_file.txt')
    os.execute('git add git_file.txt')
    -- sanity check
    assert( ax.is_git_managed ('git_file.txt'))

    ax.delete_file('git_file.txt')

    assert( not ax.is_git_managed ('git_file.txt'))
    assert(vim.fn.filereadable('git_file.txt') == 0, "Temporary file must not exist")
  end)

  it('Ax command', function()
    assert(vim.fn.filereadable(temp_file_path) == 1, "Temporary file must exist")

    vim.api.nvim_command('Ax')

    assert(vim.fn.filereadable(temp_file_path) == 0, "Temporary file not must exist")
  end)
  -- TODO: push
  -- TODO: automate test generation
end)
