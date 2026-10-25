---------------------------------------------------------------------------------------------
-- SETUP CLASSES
---------------------------------------------------------------------------------------------
-- FR : Charge la factory de classes, puis les classes de gvv (qui s'inscrivent en _G).
-- EN : Loads the class factory, then gvv's classes (which register themselves in _G).
---------------------------------------------------------------------------------------------
gvv.classFactory = require(gvv.defines.class.core)
log('> imported : ' .. gvv.defines.class.core)
---------------------------------------------------------------------------------------------
-- FR : Classes de gvv (ajoutées au fil de la restructuration 0.6)
-- EN : gvv classes (added along the 0.6 restructuring)
---------------------------------------------------------------------------------------------
