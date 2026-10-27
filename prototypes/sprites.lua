---------------------------------------------------------------------------------------------
-- PROTOTYPES : SPRITES
---------------------------------------------------------------------------------------------
-- FR : Icônes de l'interface de gvv (préfixe gvv-mod_), affichées en 16 px (images 32 px, scale 0.5).
--      Avant 0.6, gvv-mod_folder-closed était déclaré deux fois à l'identique : une seule fois ici.
-- EN : gvv interface icons (gvv-mod_ prefix), shown at 16 px (32 px images, scale 0.5).
--      Before 0.6, gvv-mod_folder-closed was declared twice, identically: only once here.
---------------------------------------------------------------------------------------------

data:extend({
    -- FR : Dossier ouvert / fermé (arbres)
    -- EN : Opened / closed folder (trees)
    {
        type = "sprite",
        name = "gvv-mod_folder-opened",
        filename = "__gvv__/icons/folder-opened.png",
        priority = "extra-high-no-scale",
        width = 32,
        height = 32,
        flags = {"gui-icon"},
        mipmap_count = 1,
        scale = 0.5,
    },
    {
        type = "sprite",
        name = "gvv-mod_folder-closed",
        filename = "__gvv__/icons/folder-closed.png",
        priority = "extra-high-no-scale",
        width = 32,
        height = 32,
        flags = {"gui-icon"},
        mipmap_count = 1,
        scale = 0.5,
    },
    -- FR : Flèches haut / bas (suivi : déplacer les entrées), images du jeu
    -- EN : Up / down arrows (tracking: move entries), game images
    {
        type = "sprite",
        name = "gvv-mod_arrow-up",
        filename = "__core__/graphics/arrows/table-header-sort-arrow-up-white.png",
        priority = "extra-high-no-scale",
        width = 16,
        height = 16,
        flags = {"gui-icon"},
        mipmap_count = 1,
        scale = 0.5,
    },
    {
        type = "sprite",
        name = "gvv-mod_arrow-down",
        filename = "__core__/graphics/arrows/table-header-sort-arrow-down-white.png",
        priority = "extra-high-no-scale",
        width = 16,
        height = 16,
        flags = {"gui-icon"},
        mipmap_count = 1,
        scale = 0.5,
    },
    -- FR : Exporter / importer la liste du suivi
    -- EN : Export / import the tracking list
    {
        type = "sprite",
        name = "gvv-mod_export-import",
        filename = "__gvv__/icons/export-import.png",
        priority = "extra-high-no-scale",
        width = 32,
        height = 32,
        flags = {"gui-icon"},
        mipmap_count = 2,
        scale = 0.5,
    },
    -- FR : Coche rouge et croix verte, images du jeu teintées
    -- EN : Red check mark and green cross, tinted game images
    {
        type = "sprite",
        name = "gvv-mod_red-check",
        filename = "__core__/graphics/icons/mip/check-mark-white.png",
        priority = "extra-high-no-scale",
        width = 32,
        height = 32,
        flags = {"gui-icon"},
        mipmap_count = 2,
        tint = {r = 1, g = 0.25, b = 0.25, a = 1},
        scale = 0.5,
    },
    {
        type = "sprite",
        name = "gvv-mod_green-close",
        filename = "__core__/graphics/icons/close.png",
        priority = "extra-high-no-scale",
        width = 32,
        height = 32,
        flags = {"gui-icon"},
        mipmap_count = 1,
        tint = {r = 0, g = 1, b = 0, a = 1},
        scale = 0.5,
    },
    -- FR : « Continuer à charger » (arbres, au-delà de la limite de lignes)
    -- EN : "Continue to load" (trees, past the rows limit)
    {
        type = "sprite",
        name = "gvv-mod_load-cont",
        filename = "__gvv__/icons/load-cont.png",
        priority = "extra-high-no-scale",
        width = 32,
        height = 32,
        flags = {"gui-icon"},
        mipmap_count = 1,
        scale = 0.5,
    },
})
