
local function printVersion(name, key)
  local status, m = pcall(require, name)
  if status then
    if key == nil then
      key = '_VERSION'
    end
    local version = '?'
    if type(key) == 'function' then
      version = key(m, name)
    elseif type(key) == 'string' then
      local value = m[key]
      if type(value) == 'function' then
        version = value()
      elseif type(value) == 'string' then
        version = value
      end
    end
    print(name, version)
  end
end

local bits
if string.pack then
  bits = #string.pack('T', 0) * 8
else
  bits = 0xfffffffff == 0xfffffffff and 64 or 32
end
print(_VERSION, tostring(bits)..' bits')

printVersion('lfs')
printVersion('socket')
printVersion('cjson')
printVersion('zlib')
printVersion('luv', 'version_string')
printVersion('openssl', 'version')
printVersion('lpeg', 'version')
printVersion('lpeglabel', 'version')
printVersion('luaunit')
printVersion('dumbParser', 'VERSION')
printVersion('lxp') -- LuaExpat
printVersion('lxp', '_EXPAT_VERSION')
printVersion('xml2lua') -- XmlParser
printVersion('webview')
printVersion('llthreads')
--printVersion('luachild') -- not available
printVersion('sha1')
printVersion('luacov.runner', 'version')
--printVersion('struct') -- not available 1.8
printVersion('dkjson', 'version')
--printVersion('winapi') -- not available
printVersion('periphery', 'version')

printVersion('exif')
printVersion('jpeg')
printVersion('serial')
printVersion('win32')
printVersion('linux')
printVersion('buffer')
