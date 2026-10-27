-- 스프라이트

local Sprite = {}

local prototype_sprite_prefix = {
  LuaItemPrototype = 'item/',
  LuaEntityPrototype = 'entity/',
  LuaTechnologyPrototype = 'technology/',
  LuaRecipePrototype = 'recipe/',
  LuaFluidPrototype = 'fluid/',
  LuaTilePrototype = 'tile/',
  LuaVirtualSignalPrototype = 'virtual-signal/',
  LuaAchievementPrototype = 'achievement/',
  LuaEquipmentPrototype = 'equipment/',
}
local prototype_group_type_sprite_prefix = {
  ['item-group'] = 'item-group/',
}
---**EN**
---
---Description: Reads `obj[prop]` (called inside a pcall by safe_check).
---
---──────────────────────────────
---
---**FR**
---
---Description: Lit `obj[prop]` (appelée dans un pcall par safe_check).
---@param obj any
---@param prop string
---@return any
local safe_check_func = function(obj, prop)
  return obj[prop]
end
---**EN**
---
---Description: Protected read of `obj[prop]`: nil if it raises an error.
---
---──────────────────────────────
---
---**FR**
---
---Description: Lecture protégée de `obj[prop]` : nil si elle lève une erreur.
---@param obj any
---@param prop string
---@return any  nil if reading fails
local safe_check = function(obj, prop)
  local pc, ret = pcall(safe_check_func, obj, prop)
  if pc then return ret end
end

---**EN**
---
---Description: Rich text icon of a Lua object (prototype, entity, item...), or "" if it has no valid sprite.
---
---──────────────────────────────
---
---**FR**
---
---Description: Icône en texte enrichi d'un objet Lua (prototype, entité, objet...), ou "" s'il n'a pas de sprite valide.
---@param obj any
---@return string  "[img=...]" or ""
Sprite.img = function(obj)
  if prototype_sprite_prefix[obj.object_name] then
    if safe_check(obj, 'name') and helpers.is_valid_sprite_path(prototype_sprite_prefix[obj.object_name]..obj.name) then
      return '[img='..prototype_sprite_prefix[obj.object_name]..obj.name..']'
    end
  elseif obj.object_name == 'LuaGroup' and safe_check(obj, 'type') and prototype_group_type_sprite_prefix[obj.type] then
    if safe_check(obj, 'name') and helpers.is_valid_sprite_path(prototype_group_type_sprite_prefix[obj.type]..obj.name) then
      return '[img='..prototype_group_type_sprite_prefix[obj.type]..obj.name..']'
    end
  end
  return ''
end

return Sprite
