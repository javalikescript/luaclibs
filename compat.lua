--[[
This Lua script transpiles Lua files from the latest version, 5.4, to an oldest, 5.1
The syntax is "-t=<target directory> [-pretty] <Lua file or directory> ...".
]]

local fs = require('lfs')
local ast = require('jls.util.ast')

local function getFilename(filename)
  return (string.gsub(filename, '^.*[/\\]', '', 1))
end

local function getBaseName(filename)
  local n, e = string.match(filename, '^(.+)%.([^/\\%.]*)$')
  return n or filename, e
end

local function forEach(filename, onFile, onDir, path)
  local mode = fs.attributes(filename, 'mode')
  if path then
    path = path..'/'
  else
    path = ''
  end
  local fname = getFilename(filename)
  if mode == 'file' then
    local _, ext = getBaseName(fname)
    if ext == 'lua' then
      onFile(filename, path..fname)
    end
  elseif mode == 'directory' then
    path = path..fname
    if onDir then
      onDir(path)
    end
    for n in fs.dir(filename) do
      if n ~= '.' and n ~= '..' then
        forEach(filename..'/'..n, onFile, onDir, path)
      end
    end
  end
end

local function readFile(filename)
  local data
  local f = io.open(filename, 'r')
  if f then
    data = f:read('*a')
    f:close()
  end
  return data
end

local function mkDir(path)
  if fs.attributes(path, 'mode') == 'directory' then
    return true
  end
  print(string.format('creating directory "%s"', path))
  return fs.mkdir(path)
end

local luanames = {}
local pretty = false
local target
for _, value in ipairs(arg) do
  if value == '-pretty' then
    pretty = true
  else
    local k, v = string.match(value, '^%-(%w+)[=:](.*)$')
    if k == 't' then
      target = v
    else
      table.insert(luanames, value)
    end
  end
end

assert(mkDir(target))

local count = 0
for _, luaname in ipairs(luanames) do
  forEach(luaname, function(filename, path)
    local targetPath = target..'/'..path
    --print(string.format('processing "%s" to "%s"', filename, targetPath))
    local content = readFile(filename)
    local tree = assert(ast.parse(content))
    local fd = assert(io.open(targetPath, 'wb'))
    if path ~= 'jls/util/compat.lua' then
      local _, updated = ast.traverse(tree, ast.toLua51)
      if updated then
        fd:write('local compat = require("jls.util.compat");')
        if pretty then
          fd:write('\n')
        end
      end
    end
    if pretty then
      tree.pretty = true
    end
    local cc = ast.generate(tree)
    fd:write(cc)
    fd:close()
    count = count + 1
  end, function(path)
    assert(mkDir(target..'/'..path))
  end)
end

print(string.format('%d Lua files processed to "%s"', count, target))
