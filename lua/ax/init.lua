local api = vim.api
local fn = vim.fn

local M = {}

local config = {}

function M.config(user_config)
  config = vim.tbl_deep_extend("force", config, user_config)
  return config
end









function M.setup(setup_config)
  setup_config = setup_config or {}
  M.config(setup_config)
  return M
end

function M.leak()
  return M
end

function M.reload()
  package.loaded['ax'] = nil
  return require('ax').setup(config)
end

return M
