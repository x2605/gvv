--복사 가능한 코드

local Copy_Code = {}

local codes = {}

---**EN**
---
---Description: Template of the code that makes a mod readable by gvv (pasted into a control.lua or typed in the console).
---
---──────────────────────────────
---
---**FR**
---
---Description: Modèle du code qui rend un mod lisible par gvv (collé dans un control.lua ou tapé dans la console).
---@return string
local version_code = function() return [[=function()
  return '8'
end,
]] end

local fix_code = require(gvv.defines.lualib.remote_code.diag_n_fix)
local luac_code = require(gvv.defines.lualib.remote_code.lua_command)
local get_g_code = require(gvv.defines.lualib.remote_code.get_g)
local get_storage_code = require(gvv.defines.lualib.remote_code.get_global)


codes.in_control_lua = [[
if script.active_mods["gvv"] then require("__gvv__.gvv")() end
]]


codes.in_console_enable = [[
remote.add_interface("__"..script.mod_name.."__gvv",{
storage]]..get_storage_code()..[[
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

---**EN**
---
---Description: Line to put inside the control.lua of a mod to make it readable by gvv.
---
---──────────────────────────────
---
---**FR**
---
---Description: Ligne à mettre dans le control.lua d'un mod pour le rendre lisible par gvv.
---@return string
Copy_Code.in_control_lua = function()
  return codes.in_control_lua
end

---**EN**
---
---Description: Console command that makes a mod (or the map) readable by gvv until the game is reloaded.
---
---──────────────────────────────
---
---**FR**
---
---Description: Commande console qui rend un mod (ou la carte) lisible par gvv jusqu'au rechargement de la partie.
---@param mod_name? string  Mod name; nil, "" or "level" for the map
---@return string  /sc command
Copy_Code.in_console_enable = function(mod_name)
  if not mod_name or mod_name == '' or mod_name == 'level' then mod_name = ''
  else mod_name = '__'..mod_name..'__ '
  end
  return '/sc '..mod_name..codes.in_console_enable
end

---**EN**
---
---Description: Console command that removes the gvv interface from a mod (or the map).
---
---──────────────────────────────
---
---**FR**
---
---Description: Commande console qui retire l'interface gvv d'un mod (ou de la carte).
---@param mod_name? string  Mod name; nil, "" or "level" for the map
---@return string  /c command
Copy_Code.in_console_disable = function(mod_name)
  if not mod_name or mod_name == '' or mod_name == 'level' then mod_name = ''
  else mod_name = '__'..mod_name..'__ '
  end
  return '/c '..mod_name..codes.in_console_disable
end

return Copy_Code
