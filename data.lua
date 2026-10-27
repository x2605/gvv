---------------------------------------------------------------------------------------------
-- DATA
---------------------------------------------------------------------------------------------
-- FR : Data stage de gvv : chargement des prototypes (raccourcis, sprites, police, styles),
--      rangés dans prototypes/ (étape 4 de la restructuration 0.6, ancien data.lua découpé).
-- EN : gvv data stage: loading of the prototypes (shortcuts, sprites, font, styles),
--      sorted inside prototypes/ (step 4 of the 0.6 restructuring, old data.lua split).
---------------------------------------------------------------------------------------------

-- FR : Registre des chemins
-- EN : Path registry
require("core.defines")

-- FR : Prototypes
-- EN : Prototypes
require(gvv.defines.prototypes.custom_inputs)   -- FR : raccourcis clavier / EN : keyboard shortcuts
require(gvv.defines.prototypes.sprites)         -- FR : icônes / EN : icons
require(gvv.defines.prototypes.fonts)           -- FR : police / EN : font
require(gvv.defines.prototypes.styles)          -- FR : styles de l'interface / EN : interface styles
