---@diagnostic disable: deprecated, undefined-global

if not arg and process and type(process.argv) == 'table' then
  local status, shiftArguments = pcall(require, 'jls.lang.shiftArguments')
  if status then
    _G.arg = shiftArguments(process.argv, 1)
  end
end

local M = require('luaunit-')

if jit and process and getfenv then
  local oldRun = M.LuaUnit.run
  function M.LuaUnit.run(...)
    for k, v in pairs(getfenv(2)) do
      if type(k) == 'string' and k:sub(1, 4):lower() == 'test' then
        _G[k] = v
      end
    end
    return oldRun(...)
  end
end

return M