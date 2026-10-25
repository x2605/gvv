---------------------------------------------------------------------------------------------
-- CLASS FACTORY
---------------------------------------------------------------------------------------------
-- FR : Factory de classes orientée objet (Lua 5.1), même principe que celle de RitnLib.
--      Copiée ici pour que gvv reste autonome, sans dépendance.
-- EN : Object-oriented class factory (Lua 5.1), same principle as RitnLib's.
--      Copied here so gvv stays standalone, without dependency.
---------------------------------------------------------------------------------------------

---@class GvvClassFactory
---@field newclass fun(super: table|fun(self: any, ...: any): any, init?: fun(self: any, ...: any): any): table

---FR : Crée une nouvelle classe, avec ou sans classe parente.
---     La classe renvoyée s'appelle comme une fonction : `MaClasse(args)` crée une instance et lance `init`.
---     ⚠ Les champs du parent sont copiés superficiellement : une table du parent reste partagée.
---EN : Creates a new class, with or without a parent class.
---     The returned class is callable: `MyClass(args)` creates an instance and runs `init`.
---     ⚠ The parent's fields are shallow-copied: a parent's table stays shared.
---
---```lua
---local A = newclass(function(self, value) self.value = value end)
---local B = newclass(A, function(self, value) A.init(self, value); self.extra = 42 end)
---local instance = B(10)
---instance:is_a(A) -- true
---```
---@param super table|fun(self: any, ...: any): any  Classe parente, ou fonction init sans parent / Parent class, or init function without parent
---@param init? fun(self: any, ...: any): any        Fonction init (si un parent est donné) / Init function (when a parent is given)
---@return table
local function newclass(super, init)
    local class = {}
    if not init and type(super) == 'function' then
        init = super
        super = nil
    elseif type(super) == 'table' then
        -- FR : La nouvelle classe est une copie superficielle de la classe parente
        -- EN : The new class is a shallow copy of the parent class
        for key, value in pairs(super) do
            class[key] = value
        end
        class._super = super
    end
    -- FR : La classe sert de métatable à ses instances, qui y cherchent leurs méthodes
    -- EN : The class is the metatable of its instances, which look up their methods in it
    class.__index = class

    -- FR : Constructeur : MaClasse(args)
    -- EN : Constructor: MyClass(args)
    local metatable = {}
    metatable.__call = function(class_table, ...)
        local instance = {}
        setmetatable(instance, class)
        if init then
            init(instance, ...)
        elseif super and super.init then
            -- FR : Sans init propre, on initialise au moins la partie parente
            -- EN : Without its own init, initialise at least the parent part
            super.init(instance, ...)
        end
        return instance
    end
    class.init = init
    class.is_a = function(self, klass)
        local current = getmetatable(self)
        while current do
            if current == klass then return true end
            current = current._super
        end
        return false
    end
    setmetatable(class, metatable)
    return class
end

---------------------------------------------------------------------------------------------
---@type GvvClassFactory
local factory = {
    newclass = newclass,
}
return factory
