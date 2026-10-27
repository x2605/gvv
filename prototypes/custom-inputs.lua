---------------------------------------------------------------------------------------------
-- PROTOTYPES : CUSTOM INPUTS
---------------------------------------------------------------------------------------------
-- FR : Raccourcis clavier de gvv. Leurs noms ne doivent jamais changer : les joueurs ont pu
--      les réassigner, et le code les écoute par ce nom (modules/gui.lua).
-- EN : gvv keyboard shortcuts. Their names must never change: players may have
--      reassigned them, and the code listens to them by this name (modules/gui.lua).
---------------------------------------------------------------------------------------------

data:extend({
    -- FR : Ouvrir / fermer la fenêtre principale
    -- EN : Open / close the main window
    {
        type = 'custom-input',
        name = 'toggle-main-frame_gvv-mod',
        key_sequence = 'CONTROL + SHIFT + V',
    },
    -- FR : Rafraîchir l'onglet affiché (valeurs du suivi, ou arbre)
    -- EN : Refresh the displayed tab (tracking values, or tree)
    {
        type = 'custom-input',
        name = 'refresh_gvv-mod',
        key_sequence = 'SHIFT + X',
    },
})
