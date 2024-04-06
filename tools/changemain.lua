--[[
This Lua script generates a C file on the standard output.
The syntax is "<Lua directory>/src/lua.c [Lua code to execute]".
The generated file is used in conjonction with the "changemain.c" C file to override
the Lua main function in order to execute Lua code.

If the executable name contains "lua" then the default Lua syntax is preserved.
If a Lua code to execute is provided then the executable will only executes this code.
Otherwise, if the executable name is "example" then the script "example.lua" is executed.
]]

local function charToHex(c)
  return string.format('0x%02x, ', string.byte(c))
end
local function stringToHex(s)
  return (string.gsub(s, '.', charToHex))
end

local function readFile(filename)
  local data
  local f = io.open(filename, 'r')
  if f then
    data = f:read('a')
    f:close()
  end
  return data
end

local function replace(s, p, r, n)
  local rs, rn = string.gsub(s, p, r, n)
  assert(rn == n, 'unable to replace')
  return rs
end


local luac = arg[1] or 'lua/src/lua.c'
local execute = arg[2]

local cc = assert(readFile(luac))
cc = replace(cc, '\n *int +main *%(', '\nstatic int base_main (', 1)
if execute and execute ~= '' then
  io.stdout:write(string.format([[

#define CUSTOM_EXECUTE custom_execute

static char custom_execute[] = {%s0x00};

]], stringToHex(execute)))
  cc = replace(cc, '\n *static +int +handle_script *%(', [[

static int handle_script (lua_State *L, char **argv) {
return LUA_OK;
}

static int base_handle_script(]], 1)
end

io.stdout:write(cc)

io.stdout:write([[

#include "changemain.c"

]])
