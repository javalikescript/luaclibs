
local function search(name)
  for i, searcher in ipairs(package.searchers) do
    local loader = searcher(name)
    if type(loader) == 'function' then
      return loader
    else
      print('no loader function at index', i, loader)
    end
  end
end

print('searching in package')
local zlibLoader = search('zlib')
print('loader', zlibLoader)

print('loader', pcall(string.dump, zlibLoader), nil, 'b')

for i = 1, -10, -1 do
  if arg[i] then
    print('arg', i, arg[i])
  else
    break
  end
end

print(package.loadlib('/home/samuel/dev/luaclibs/lua54jls', 'luaopen_zlib'))
