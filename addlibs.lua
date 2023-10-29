local lz = require('zlib')

local filename = arg[1] or 'content.lua'
local libnames = {}
for i = 2, #arg do
  table.insert(libnames, arg[i])
end

local lines = {}

local chunk_name = (string.gsub(filename, '^.*[/\\]', '', 1))
local chunk_window_bits = -15
local chunk_inflated_size, chunk_deflated_size, chunk_bytes = 0, 0, ''

local f = io.open(filename, 'r')
if f then
  local data = f:read('a')
  f:close()
  if data then
    local deflated = lz.deflate(lz.BEST_COMPRESSION, chunk_window_bits)(data, 'finish')
    if deflated then
      chunk_bytes = string.gsub(deflated, '.', function(c)
        return string.format('0x%02x, ', string.byte(c))
      end)
      chunk_inflated_size, chunk_deflated_size = #data, #deflated
    end
  end
end

table.insert(lines, string.format([[

static const char* chunk_name = "%s";

static const int chunk_window_bits = %d;

static const int chunk_inflated_size = %d;
static const int chunk_deflated_size = %d;

static const unsigned char chunk_deflated[] = {
  ]], chunk_name, chunk_window_bits, chunk_inflated_size, chunk_deflated_size))
table.insert(lines, chunk_bytes)
table.insert(lines, '\n};\n\n')

for _, libname in ipairs(libnames) do
  table.insert(lines, string.format('int luaopen_%s(lua_State *L);\n', libname))
end

table.insert(lines, [[

static const luaL_Reg reg_add_libs[] = {
]])

for _, libname in ipairs(libnames) do
  table.insert(lines, string.format('  {"%s", luaopen_%s},\n', libname, libname))
end

table.insert(lines, [[
  {NULL, NULL}
};

]])

io.stdout:write(table.concat(lines))
