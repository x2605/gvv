---------------------------------------------------------------------------------------------
-- SETUP CLASSES
---------------------------------------------------------------------------------------------
-- FR : Charge la factory de classes, puis les classes de gvv (qui s'inscrivent en _G).
--      Appelé une seule fois par control.lua, avant l'envoi des modules à l'event handler.
-- EN : Loads the class factory, then gvv's classes (which register themselves in _G).
--      Called once by control.lua, before the modules are sent to the event handler.
---------------------------------------------------------------------------------------------

-- FR : Factory de classes, utilisée par toutes les classes : gvv.classFactory.newclass(...)
-- EN : Class factory, used by every class: gvv.classFactory.newclass(...)
gvv.classFactory = require(gvv.defines.class.core)
log('> imported : ' .. gvv.defines.class.core)

---------------------------------------------------------------------------------------------
-- FR : Classes de gvv (ajoutées au fil de la restructuration 0.6).
--      L'ordre compte : une classe enfant se charge après sa classe parente.
-- EN : gvv classes (added along the 0.6 restructuring).
--      Order matters: a child class is loaded after its parent class.
---------------------------------------------------------------------------------------------
require(gvv.defines.class.player)        -- GvvPlayer : joueur / player
require(gvv.defines.class.gui)           -- GvvGui : base des fenêtres (hérite de GvvPlayer) / windows base (inherits GvvPlayer)
require(gvv.defines.class.gui_element)   -- GvvGuiElement : description d'un élément GUI / GUI element description
require(gvv.defines.class.gui_main)      -- GvvGuiMain : fenêtre principale (hérite de GvvGui) / main window (inherits GvvGui)
require(gvv.defines.class.gui_dialog)    -- GvvGuiDialog : petites fenêtres (hérite de GvvGui) / small windows (inherits GvvGui)
require(gvv.defines.class.gui_help)      -- GvvGuiHelp : onglet aide (hérite de GvvGui) / help tab (inherits GvvGui)
