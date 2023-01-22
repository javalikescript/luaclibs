local function exists(path, fail)
  local f, err = io.open(path)
  if f then
    io.close(f)
    return true
  end
  return false, err
end

-- Before running any code, lua collects all command-line arguments in a global table called arg.
-- The script name goes to index 0, the first argument after the script name goes to index 1, and so on.
local binName = arg[0]
arg[0] = nil
binName = string.gsub(binName, '%.exe$', '')
for i, v in ipairs(arg) do
  arg[i - 1] = v
end

local scriptName = arg[0]
if scriptName == '-h' or scriptName == '--help' then
  print('try: '..tostring(binName)..' [luascript [arguments ...]]')
  print('with "--" or no Lua script, the Lua script with the executable name, "'..binName..'.lua", will be loaded.')
  os.exit(22)
elseif scriptName == '-v' or scriptName == '--version' then
  print('lua-cjson', require('cjson')._VERSION)
  print('luv', require('luv').version_string())
  print('webview', require('webview')._VERSION)
  print(require('zlib')._VERSION)
  os.exit(0)
elseif not scriptName or scriptName == '--' or scriptName == '' then
  scriptName = binName..'.lua'
  arg[0] = scriptName
end
--print('bin', binName, 'script', scriptName, 'args', table.concat(arg, ' '))

if not exists(scriptName) then
  print('unable to find '..tostring(scriptName))
  os.exit(1)
end

assert(loadfile(scriptName, 't'))()
