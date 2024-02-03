local lz = require('zlib')
local fs = require('lfs')
local dumbParser = require('dumbParser')

local windowBits = -15
local minDeflatedSize = 512

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

local function getPathname(pathname)
  return (string.gsub(pathname, '\\', '/'))
end

local function getBaseName(filename)
  local n, e = string.match(filename, '^(.+)%.([^/\\%.]*)$')
  return n or filename, e
end

local function forEach(filename, fn, path)
  local mode = fs.attributes(filename, 'mode')
  if path then
    path = path..'.'
  else
    path = ''
  end
  if mode == 'file' then
    fn(filename, path..getBaseName(getFilename(filename)))
  elseif mode == 'directory' then
    path = path..getFilename(filename)
    for name in fs.dir(filename) do
      if name ~= '.' and name ~= '..' then
        forEach(filename..'/'..name, fn, path)
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


local luanames = {}
local libnames = {}
local l = libnames
for _, value in ipairs(arg) do
  if value == '-c' then
    l = libnames
  elseif value == '-l' then
    l = luanames
  else
    table.insert(l, value)
  end
end


local lines = {}

table.insert(lines, '// Generated custom preloads\n\n')

for _, libname in ipairs(libnames) do
  table.insert(lines, string.format('int luaopen_%s(lua_State *L);\n', libname))
end

table.insert(lines, [[

static void load_custom_libs(lua_State *L) {
  luaL_getsubtable(L, LUA_REGISTRYINDEX, LUA_PRELOAD_TABLE);]])
for _, libname in ipairs(libnames) do
  table.insert(lines, string.format([[
  lua_pushcfunction(L, luaopen_%s);
  lua_setfield(L, -2, "%s");
]], libname, libname))
end
table.insert(lines, [[  lua_pop(L, 1);
}

]])

local deflatedNames = {}

local preloads = {}
local luaPreloads = {}
local count, index, total = 0, 0, 0
table.insert(lines, 'static const struct custom_preload custom_preloads[] = {\n')
for _, luaname in ipairs(luanames) do
  forEach(luaname, function(filename, path)
    local lua = stripLua(readFile(filename))
    if #lua > 0 then
      if #lua > minDeflatedSize then
        count = count + 1
        local deflated = assert(deflate(lua))
        table.insert(lines, string.format('  {"%s", %d, %d},\n', path, index, #lua))
        table.insert(deflatedNames, path)
        table.insert(preloads, deflated)
        index = index + #deflated
        total = total + #lua
      else
        table.insert(luaPreloads, string.format('package.preload["%s"] = function(...)\n', path))
        table.insert(luaPreloads, lua)
        table.insert(luaPreloads, '\nend\n')
      end
    end
  end)
end

local lua = stripLua(table.concat(luaPreloads))
local deflated = assert(deflate(lua))
table.insert(lines, string.format('  {"%s", %d, %d},\n', "preloads", index, #lua))
table.insert(preloads, deflated)
index = index + #deflated
total = total + #lua
table.insert(lines, string.format('  {NULL, %d, %d}\n', index, 0))
table.insert(lines, '};\n\n')

table.insert(lines, string.format('#define WINDOW_BITS %d\n', windowBits))
table.insert(lines, string.format('#define PRELOADS_INDEX %d\n', count))

table.insert(lines, [[

static void load_custom_mods(lua_State *L) {
  luaL_getsubtable(L, LUA_REGISTRYINDEX, LUA_PRELOAD_TABLE);]])
for _, modname in ipairs(deflatedNames) do
  table.insert(lines, string.format([[
  lua_pushcfunction(L, preload_custom_get);
  lua_setfield(L, -2, "%s");
]], modname))
end
table.insert(lines, [[  lua_pop(L, 1);
}

]])

if false then
  table.insert(lines, '/*\n')
  table.insert(lines, table.concat(luaPreloads))
  table.insert(lines, '\n*/\n')
end

table.insert(lines, '\nstatic const unsigned char custom_chunk_preloads[] = {\n')
for _, preload in ipairs(preloads) do
  table.insert(lines, stringToHex(preload))
end
table.insert(lines, '\n};\n')

for _, line in ipairs(lines) do
  io.stdout:write(line)
end

io.stderr:write(string.format('addlibs generated, deflate ratio is %s for %d modules\n', (total * 10 // index) / 10, count))
