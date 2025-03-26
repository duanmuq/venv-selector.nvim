local utils = require 'venv-selector.utils'
local dbg = require('venv-selector.utils').dbg
local config = require 'venv-selector.config'
local snacks = require 'snacks'

local M = {}

M.results = {}

function M.add_lines(lines, source)
  local icon = source == 'Workspace' and '' or ''

  for row in lines do
    if row ~= '' then
      dbg('Found venv in ' .. source .. ' search: ' .. row)
      table.insert(M.results, { icon = icon, path = utils.remove_last_slash(row) })
    end
  end
end

function M.tablelength(t)
  local count = 0
  for _ in pairs(t) do
    count = count + 1
  end
  return count
end

-- This function removes duplicate results when loading results into snacks
function M.prepare_results()
  local hash = {}
  local res = {}

  for _, v in ipairs(M.results) do
    if not hash[v.path] then
      res[#res + 1] = v
      hash[v.path] = true
    end
  end

  M.results = res

  dbg('There are ' .. M.tablelength(M.results) .. ' results to show.')
end

function M.remove_results()
  M.results = {}
  dbg 'Removed snacks results.'
end

-- Shows the results from the search in a Snacks picker.
function M.show_results()
  M.prepare_results()
  local items = {}
  for _, entry in ipairs(M.results) do
    table.insert(items, {
      label = entry.icon .. ' ' .. entry.path,
      value = entry.path,
    })
  end

  snacks.select {
    prompt = 'Virtual environments',
    items = items,
    on_submit = function(selected)
      local venv = require 'venv-selector.venv'
      venv.activate_venv { value = selected.value }
    end,
  }
end

-- Gets called on results from the async search and adds the findings
-- to snacks.results to show when its done.
function M.on_read(err, data)
  if err then
    dbg('Error:' .. err)
  end

  if data then
    local rows = vim.split(data, '\n')
    for _, row in pairs(rows) do
      if row ~= '' then
        dbg('Found venv in parent search: ' .. row)
        table.insert(M.results, { icon = '󰅬', path = utils.remove_last_slash(row), source = 'Search' })
      end
    end
  end
end

function M.open()
  local dont_refresh_snacks = config.settings.auto_refresh == false
  local has_snacks_results = next(M.results) ~= nil

  if dont_refresh_snacks and has_snacks_results then
    dbg 'Using cached results.'
    M.show_results()
    return
  end

  local venv = require 'venv-selector.venv'
  venv.load()
  -- venv.load must be called before showing the picker
  vim.defer_fn(function()
    M.show_results()
  end, 10)
end

return M
