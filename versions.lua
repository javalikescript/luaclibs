
local function printVersion(name, fn)
  local status, m = pcall(require, name)
  if status then
    local version = '?'
    if fn then
      version = fn(m, name)
    elseif m._VERSION then
      version = m._VERSION
    end
    print(name, version)
  end
end

local bits = math.floor(#(string.match(tostring({}), '%w+: (%w+)')) / 2) * 8
print(_VERSION, tostring(bits)..' bits')

printVersion('lfs')
printVersion('socket')
printVersion('cjson')
printVersion('zlib')
printVersion('luv', function(m) return m.version_string(); end)
printVersion('openssl', function(m) return m.version(); end)
printVersion('lpeg', function(m) return m.version(); end)
printVersion('lpeglabel', function(m) return m.version; end)
printVersion('luaunit')
printVersion('exif')
printVersion('jpeg')
