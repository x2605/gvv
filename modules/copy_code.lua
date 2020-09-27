--복사 가능한 코드

local Copy_Code = {}

local codes = {}

local version_code = function() return [[=function()
  return '4'
end,
]] end

local fix_code = require('modules.remote_code.diag_n_fix')
local luac_code = require('modules.remote_code.lua_command')
local get_g_code = require('modules.remote_code.get_g')


codes.in_control_lua = [[
if script.active_mods["gvv"] then require("__gvv__.gvv")() end
]]


codes.in_console_enable = [[
remote.add_interface("__"..script.mod_name.."__gvv",{global=function() return global end,
_G]]..get_g_code()..[[
diag]]..fix_code('')..[[
fix]]..fix_code('b[k]=nil')..[[
c]]..luac_code()..[[
version]]..version_code()..[[
})
]]


codes.in_console_disable = [[
remote.remove_interface("__"..script.mod_name.."__gvv")
]]


for k,code in pairs(codes) do
  codes[k] = code:gsub('^\n',''):gsub('\n$',''):gsub('\n',' '):gsub('%s+',' ')
end

Copy_Code.in_control_lua = function()
  return codes.in_control_lua
end

Copy_Code.in_console_enable = function(mod_name)
  if not mod_name or mod_name == '' or mod_name == 'level' then mod_name = ''
  else mod_name = '__'..mod_name..'__ '
  end
  return '/sc '..mod_name..codes.in_console_enable
end

Copy_Code.in_console_disable = function(mod_name)
  if not mod_name or mod_name == '' or mod_name == 'level' then mod_name = ''
  else mod_name = '__'..mod_name..'__ '
  end
  return '/c '..mod_name..codes.in_console_disable
end

return Copy_Code
