local ax = require('ax')

describe('ax.nvim', function()

  before_each(function()
    ax.leak()
    ax.setup({})
  end)

  it('ai', function()
    assert.are.same("7", "7")
  end)










end)
