--복사 가능한 코드

local Copy_Code = {}

local codes = {}

local version_code = function() return [[=function()
  return '2'
end,
]] end

local fix_code = require('modules.remote_code.diag_n_fix')
local luac_code = require('modules.remote_code.lua_command')


codes.in_control_lua = [[
if script.active_mods["gvv"] then require("__gvv__.gvv")() end
]]


codes.in_console_enable = [[/sc
remote.add_interface("__"..script.mod_name.."__gvv",{global=function() return global end,
diag]]..fix_code('')..[[
fix]]..fix_code('b[k]=nil')..[[
c]]..luac_code()..[[
version]]..version_code()..[[
})
]]


codes.in_console_disable = [[/c
remote.remove_interface("__"..script.mod_name.."__gvv")
]]


for k,code in pairs(codes) do
  codes[k] = code:gsub('^\n',''):gsub('\n$',''):gsub('\n',' '):gsub('%s+',' ')
end

Copy_Code.in_control_lua = function()
  return codes.in_control_lua
end

Copy_Code.in_console_enable = function()
  return codes.in_console_enable
end

Copy_Code.in_console_disable = function()
  return codes.in_console_disable
end

return Copy_Code
