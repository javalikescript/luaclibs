--[[
This Lua script generates the content of the "addlibs-custom.c" file.
The syntax is "-c <C module name> ... -l|-L <Lua file or directory> ...".
The "addlibs-custom.c" file is used in conjonction with the "addlibs.c" C file to add custom Lua loaders.
The Lua function "luaL_openlibs" is overrided in order to add loaders in the table "package.preload".
The loaders consists in C functions available in the executable and external Lua files.

The Lua application open standard libraries, create table "arg", execute arguments "-e" and "-l", execute main script.
It is possible to run a preloaded Lua script with the following arguments:
  -e "require('<module name>')" NUL
  -l <module name> /dev/null
]]

local lz = require('zlib')
local fs = require('lfs')
local dumbParser = require('dumbParser')

local windowBits = -15
local minDeflatedSize = 512

-- helper functions

local function charToHex(c)
  return string.format('0x%02x, ', string.byte(c))
end

local function stringToHex(s)
  return (string.gsub(s, '.', charToHex))
end

local function deflate(data)
  return lz.deflate(lz.BEST_COMPRESSION, windowBits)(data, 'finish')
end

local function getFilename(filename)
  return (string.gsub(filename, '^.*[/\\]', '', 1))
end

local function getBaseName(filename)
  local n, e = string.match(filename, '^(.+)%.([^/\\%.]*)$')
  return n or filename, e
end

local function forEach(filename, fn, dirPath, recursive, path)
  local mode = fs.attributes(filename, 'mode')
  if path and path ~= '' then
    path = path..'.'
  else
    path = ''
  end
  local fname = getFilename(filename)
  if mode == 'file' then
    local bname, ext = getBaseName(fname)
    if ext == 'lua' then
      fn(filename, path..bname)
    end
  elseif mode == 'directory' and (recursive or path == '') then
    if path ~= '' or dirPath then
      path = path..fname
    end
    for n in fs.dir(filename) do
      if n ~= '.' and n ~= '..' then
        forEach(filename..'/'..n, fn, dirPath, recursive, path)
      end
    end
  end
end

local function stripLua(lua)
  if lua then
    local tree = assert(dumbParser.parse(lua))
    if tree then
      return dumbParser.toLua(tree)
    end
  end
  return ''
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

-- collect arguments

local luanames = {}
local luasubnames = {}
local libnames = {}
local printPreloads = false
local l = libnames
for _, value in ipairs(arg) do
  if value == '-c' then
    l = libnames
  elseif value == '-l' then
    l = luanames
  elseif value == '-L' then
    l = luasubnames
  elseif value == '-p' then
    printPreloads = not printPreloads
  else
    table.insert(l, value)
  end
end

local luafiles = {}
local function addLuaFile(file, name)
  table.insert(luafiles, {file = file, name = name})
end
for _, luaname in ipairs(luanames) do
  forEach(luaname, addLuaFile, true, true)
end
for _, luaname in ipairs(luasubnames) do
  forEach(luaname, addLuaFile)
end
table.sort(luafiles, function(a, b)
  return a.name < b.name
end)

local lines = {}

table.insert(lines, '// Generated custom preloads\n\n')

-- list C libraries

for _, libname in ipairs(libnames) do
  table.insert(lines, string.format('int luaopen_%s(lua_State *L);\n', libname))
end

table.insert(lines, [[

static const luaL_Reg custom_libs[] = {
]])
for _, libname in ipairs(libnames) do
  table.insert(lines, string.format('  {"%s", luaopen_%s},\n', libname, libname))
end
table.insert(lines, [[
	{NULL, NULL}
};

]])

-- list preloads

local preloads = {}
local luaPreloads = {}
local count, index, total = 0, 0, 0
table.insert(lines, 'static const struct custom_preload custom_preloads[] = {\n')
for _, item in ipairs(luafiles) do
  local lua = stripLua(readFile(item.file))
  if #lua > 0 then
    if #lua > minDeflatedSize then
      count = count + 1
      local deflated = assert(deflate(lua))
      table.insert(lines, string.format('  {"%s", %d, %d},\n', item.name, index, #lua))
      table.insert(preloads, deflated)
      index = index + #deflated
      total = total + #lua
    else
      table.insert(luaPreloads, string.format('package.preload["%s"] = function(...)\n', item.name))
      table.insert(luaPreloads, lua)
      table.insert(luaPreloads, '\nend\n')
    end
  end
end
local lua = stripLua(table.concat(luaPreloads))
local deflated = assert(deflate(lua))
table.insert(lines, string.format('  {NULL, %d, %d},\n', index, #lua))
table.insert(preloads, deflated)
index = index + #deflated
total = total + #lua
table.insert(lines, string.format('  {NULL, %d, %d}\n', index, 0))
table.insert(lines, '};\n\n')

table.insert(lines, string.format('#define WINDOW_BITS %d\n', windowBits))
table.insert(lines, string.format('#define PRELOADS_INDEX %d\n', count))

-- print preloads as comment

if printPreloads then
  table.insert(lines, '\n/*\n')
  for _, preload in ipairs(luaPreloads) do
    table.insert(lines, (string.gsub(preload, '%*/', '* /')))
  end
  table.insert(lines, '\n*/\n')
end

-- generate preloads blob

table.insert(lines, '\nstatic const unsigned char custom_chunk_preloads[] = {\n')
for _, preload in ipairs(preloads) do
  table.insert(lines, stringToHex(preload))
end
table.insert(lines, '\n};\n')

-- create file

local fd = assert(io.open('addlibs-custom.c', 'wb'))
for _, line in ipairs(lines) do
  fd:write(line)
end
fd:close()

print(string.format('addlibs generated, deflate ratio is %s for %d modules, using %d kbytes\n', (total * 10 // index) / 10, count, index // 1024))
