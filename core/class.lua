---------------------------------------------------------------------------------------------
-- CLASS FACTORY
---------------------------------------------------------------------------------------------
-- FR : Source : RitnLib (Ritn), core/class.lua (ritnlib.classFactory), version 0.10.7.
--      Factory de classes orientée objet (Lua 5.1), copiée pour que gvv reste autonome.
--      Différences : seule newclass est reprise (la variante new, inutilisée, est laissée de côté),
--      noms de variables explicites.
-- EN : Source: RitnLib (Ritn), core/class.lua (ritnlib.classFactory), version 0.10.7.
--      Object-oriented class factory (Lua 5.1), copied so gvv stays standalone.
--      Differences: only newclass is kept (the unused new variant is left out),
--      explicit variable names.
---------------------------------------------------------------------------------------------

---@class GvvClassFactory
---@field newclass fun(super: table|fun(self: any, ...: any): any, init?: fun(self: any, ...: any): any): table

---**EN**
---
---Description: Creates a new class, with or without a parent class.
---The returned class is callable: `MyClass(args)` creates an instance and runs `init`.
---⚠ The parent's fields are shallow-copied: a parent's table stays shared.
---
---```lua
---local A = newclass(function(self, value) self.value = value end)
---local B = newclass(A, function(self, value) A.init(self, value); self.extra = 42 end)
---local instance = B(10)
---instance:is_a(A) -- true
---```
---
---──────────────────────────────
---
---**FR**
---
---Description: Crée une nouvelle classe, avec ou sans classe parente.
---La classe renvoyée s'appelle comme une fonction : `MaClasse(args)` crée une instance et lance `init`.
---⚠ Les champs du parent sont copiés superficiellement : une table du parent reste partagée.
---@param super table|fun(self: any, ...: any): any  Parent class, or init function without parent
---@param init? fun(self: any, ...: any): any        Init function (when a parent is given)
---@return table
local function newclass(super, init)
    -- FR : La nouvelle classe : une table qui contiendra ses méthodes
    -- EN : The new class: a table that will hold its methods
    local class = {}

    if not init and type(super) == 'function' then
        -- FR : Appel newclass(init) sans parent : le premier paramètre est la fonction init
        -- EN : Call newclass(init) without parent: the first parameter is the init function
        init = super
        super = nil
    elseif type(super) == 'table' then
        -- FR : Appel newclass(parent, init) : la nouvelle classe est une copie superficielle de la classe parente
        --      (elle reçoit toutes ses méthodes, qu'elle pourra remplacer)
        -- EN : Call newclass(parent, init): the new class is a shallow copy of the parent class
        --      (it receives all its methods, which it can replace)
        for key, value in pairs(super) do
            class[key] = value
        end
        -- FR : On garde le parent, pour is_a
        -- EN : Keep the parent, for is_a
        class._super = super
    end

    -- FR : La classe sert de métatable à ses instances, qui y cherchent leurs méthodes
    --      (instance:print() cherche print dans la classe)
    -- EN : The class is the metatable of its instances, which look up their methods in it
    --      (instance:print() looks up print in the class)
    class.__index = class

    -- FR : Constructeur : appeler MaClasse(args) exécute cette fonction
    -- EN : Constructor: calling MyClass(args) runs this function
    local metatable = {}
    metatable.__call = function(class_table, ...)
        -- FR : Nouvelle instance, reliée à la classe
        -- EN : New instance, linked to the class
        local instance = {}
        setmetatable(instance, class)

        if init then
            -- FR : Initialisation propre à la classe
            -- EN : Class's own initialisation
            init(instance, ...)
        elseif super and super.init then
            -- FR : Sans init propre, on initialise au moins la partie parente
            -- EN : Without its own init, initialise at least the parent part
            super.init(instance, ...)
        end

        return instance
    end

    -- FR : init reste accessible, pour qu'une classe enfant appelle Parent.init(self, ...)
    -- EN : init stays reachable, so a child class can call Parent.init(self, ...)
    class.init = init

    -- FR : instance:is_a(Classe) : vrai si l'instance vient de cette classe ou d'une classe enfant
    -- EN : instance:is_a(Class): true if the instance comes from this class or from a child class
    class.is_a = function(self, klass)
        -- FR : On remonte la chaîne des classes : classe de l'instance, puis son parent, etc.
        -- EN : Walk up the class chain: the instance's class, then its parent, etc.
        local current = getmetatable(self)
        while current do
            if current == klass then
                return true
            end
            current = current._super
        end
        return false
    end

    -- FR : Rend la classe appelable comme une fonction : MaClasse(args)
    -- EN : Makes the class callable like a function: MyClass(args)
    setmetatable(class, metatable)
    return class
end

---------------------------------------------------------------------------------------------
-- FR : Fonctions exportées
-- EN : Exported functions
---@type GvvClassFactory
local factory = {
    newclass = newclass,
}
return factory
