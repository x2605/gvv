-- 컨트롤

local util = require('__core__.lualib.util')

_initiated_session_ = false
require('modules.register_event')

--[[
download :
https://mods.factorio.com/mod/gvv

github :
https://github.com/x2605/gvv

--]]

-- Copy & paste following code at the end of empty line of "control.lua" file of other mod or savefile or scenario.
-- 다음 코드를 다른 모드나 세이브파일, 또는 시나리오에 있는 "control.lua" 파일의 마지막 빈 줄에 복사&붙여넣기 하세요.

-- This is a part of "gvv", "Lua API global Variable Viewer" mod.
-- It makes possible gvv mod to read sandboxed variables in the map or other mod if following code is inserted at the end of empty line of "control.lua" of each.

if script.active_mods["gvv"] then require("__gvv__.gvv")() end

-- 이 코드는 "gvv", "Lua API global Variable Viewer" 모드의 일부입니다.
-- 다른 모드나 지도의 "control.lua" 빈 줄 끝에 삽입하면 gvv 모드가 맵이나 다른 모드에서 샌드박스처리된 global 변수를 읽을 수 있습니다.
