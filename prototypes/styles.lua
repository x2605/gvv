---------------------------------------------------------------------------------------------
-- PROTOTYPES : STYLES
---------------------------------------------------------------------------------------------
-- FR : Styles de l'interface de gvv (suffixe _gvv-mod), ajoutés à data.raw['gui-style'].default.
--      La plupart sont des copies de styles du jeu, retouchées (marges à 0, fonds de la feuille
--      d'images de l'interface : les positions {x, y} pointent une couleur unie de cette feuille).
--      Repris de l'ancien data.lua, sans changement de rendu.
--      Correctif 0.6 : les couleurs « sélectionné » des lignes d'arbre utilisaient une variable
--      button_hovered_font_color qui n'existe plus dans le jeu (valeur nil, donc ignorée) : elles sont
--      retirées, ce qui ne change rien à l'affichage (gvv ne sélectionne jamais ces boutons).
-- EN : gvv interface styles (_gvv-mod suffix), added to data.raw['gui-style'].default.
--      Most are copies of game styles, retouched (zero paddings, backgrounds from the interface
--      image sheet: the {x, y} positions point to a plain colour of that sheet).
--      Taken from the old data.lua, without rendering change.
--      0.6 fix: the "selected" colours of the tree rows used a button_hovered_font_color variable
--      which no longer exists in the game (nil value, so ignored): they are removed, which changes
--      nothing on screen (gvv never selects these buttons).
---------------------------------------------------------------------------------------------

-- FR : Suffixe des noms de styles de gvv
-- EN : gvv style names suffix
local SUFFIX = '_gvv-mod'

-- FR : Styles par défaut du jeu, où les styles de gvv sont ajoutés
-- EN : Game default styles, where gvv styles are added
local default_gui = data.raw['gui-style'].default

-- FR : Positions de couleurs unies dans la feuille d'images de l'interface
-- EN : Plain colour positions inside the interface image sheet
local TRANSPARENT = {25, 8}             -- FR : transparent / EN : transparent
local DARK = {8, 8}                     -- FR : fond sombre / EN : dark background
local LINE = {76, 8}                    -- FR : trait clair (arbres, séparateurs) / EN : light line (trees, dividers)
local PRESSED = {8, 25}                 -- FR : bouton enfoncé / EN : pressed button
local HIGHLIGHT = {287, 79}             -- FR : surlignage de la recherche / EN : search highlight
local TRACKED = {337, 56}               -- FR : ligne suivie / EN : tracked row
local TRACKED_OBJECT = {355, 161}       -- FR : objet Lua ajouté / EN : added Lua object


-- FR : Fond d'une seule couleur (position dans la feuille d'images)
-- EN : Single colour background (position inside the image sheet)
local function plain(position)
    return {base = {center = {position = position, size = {1, 1}}}}
end

-- FR : Nouveau style, copie profonde d'un style existant
-- EN : New style, deep copy of an existing style
local function copyStyle(name, source)
    default_gui[name] = table.deepcopy(source)
    return default_gui[name]
end

-- FR : Nouveau style de zone vide (empty-widget), sans fond
-- EN : New empty area (empty-widget) style, without background
local function emptyStyle(name)
    default_gui[name] = {type = 'empty_widget_style', graphical_set = {}}
    return default_gui[name]
end

-- FR : Variante « suivie » d'une ligne d'arbre : même style, fond de couleur
-- EN : "Tracked" variant of a tree row: same style, coloured background
local function trackedVariant(name, source, position)
    local style = copyStyle(name, source)
    style.default_graphical_set.base.center.position = position
    style.hovered_graphical_set.base.center.position = position
    style.disabled_graphical_set.base.center.position = position
    style.selected_graphical_set.base.center.position = position
    style.selected_hovered_graphical_set.base.center.position = position
    return style
end

-- FR : Lueur au survol / au clic, copiée d'un bouton du jeu (vert, rouge...)
-- EN : Hover / click glow, copied from a game button (green, red...)
local function setGlow(style, button_name)
    local glow = default_gui[button_name].hovered_graphical_set.glow
    style.hovered_graphical_set.glow = table.deepcopy(glow)
    style.clicked_graphical_set.glow = table.deepcopy(glow)
    if style.selected_hovered_graphical_set then
        style.selected_hovered_graphical_set.glow = table.deepcopy(glow)
    end
    if style.selected_clicked_graphical_set then
        style.selected_clicked_graphical_set.glow = table.deepcopy(glow)
    end
end

local style


---------------------------------------------------------------------------------------------
-- FR : CONTENEURS
-- EN : CONTAINERS
---------------------------------------------------------------------------------------------

-- FR : Flows sans marge ni espacement
-- EN : Flows without padding or spacing
default_gui['hflow' .. SUFFIX] = {
    type = "horizontal_flow_style",
    padding = 0,
    horizontal_spacing = 0,
}
default_gui['vflow' .. SUFFIX] = {
    type = "vertical_flow_style",
    padding = 0,
    vertical_spacing = 0,
}

-- FR : Cadre transparent sans marge (ligne d'arbre), et sa variante surlignée (recherche)
-- EN : Transparent frame without padding (tree row), and its highlighted variant (search)
default_gui['transparent-frame' .. SUFFIX] = {
    type = "frame_style",
    top_padding = 0,
    right_padding = 0,
    bottom_padding = 0,
    left_padding = 0,
    horizontal_flow_style = {type = 'horizontal_flow_style', parent = 'hflow' .. SUFFIX},
    vertical_flow_style = {type = 'vertical_flow_style', parent = 'vflow' .. SUFFIX},
    graphical_set = plain(TRANSPARENT),
}
style = copyStyle('highlighted-frame' .. SUFFIX, default_gui['transparent-frame' .. SUFFIX])
style.graphical_set.base.center = {position = HIGHLIGHT, size = {1, 1}}

-- FR : Texte sur plusieurs lignes (valeurs du suivi)
-- EN : Multi-line text (tracking values)
style = copyStyle('output' .. SUFFIX, default_gui.label)
style.single_line = false


---------------------------------------------------------------------------------------------
-- FR : FENÊTRE PRINCIPALE
-- EN : MAIN WINDOW
---------------------------------------------------------------------------------------------

-- FR : Cadre principal : bord extérieur du jeu, fond transparent, sans marge
-- EN : Main frame: game outer border, transparent background, without padding
style = copyStyle('frame' .. SUFFIX, default_gui.frame)
style.graphical_set.base.draw_type = 'outer'
style.graphical_set.base.center = {position = TRANSPARENT, size = {1, 1}}
style.top_padding = 0
style.right_padding = 0
style.bottom_padding = 0
style.left_padding = 0
style.horizontal_flow_style = default_gui['hflow' .. SUFFIX]
style.vertical_flow_style = default_gui['vflow' .. SUFFIX]

-- FR : Fond sombre de la barre de titre, et des bordures (empty-widget)
-- EN : Dark background of the title bar, and of the borders (empty-widget)
style = copyStyle('frame-bg' .. SUFFIX, default_gui.frame)
style.graphical_set = plain(DARK)
style.top_padding = 0
style.right_padding = 0
style.bottom_padding = 0
style.left_padding = 0
style.use_header_filler = false

style = emptyStyle('empty-frame-bg' .. SUFFIX)
style.graphical_set = plain(DARK)

-- FR : Cadre intérieur (bord intérieur du jeu), puis cadre profond semi-transparent et flouté
-- EN : Inner frame (game inner border), then deep frame, semi-transparent and blurred
style = copyStyle('inside-wrap' .. SUFFIX, default_gui['frame' .. SUFFIX])
style.graphical_set = {
    base = {
        position = {17, 0}, corner_size = 8, draw_type = 'inner',
        center = {position = TRANSPARENT, size = {1, 1}},
    },
}

style = copyStyle('inside_deep_frame' .. SUFFIX, default_gui.inside_deep_frame)
style.graphical_set.base = {
    center = {position = {336, 0}, size = {1, 1}},
    opacity = 0.75,
    background_blur = true,
}


---------------------------------------------------------------------------------------------
-- FR : ONGLETS
-- EN : TABS
---------------------------------------------------------------------------------------------

-- FR : Cadre du contenu des onglets : sans marge, fond transparent, sans bord bas
-- EN : Tabs content frame: without padding, transparent background, without bottom border
style = copyStyle('tabbed_pane_frame' .. SUFFIX, default_gui.tabbed_pane_frame)
style.top_padding = 0
style.right_padding = 0
style.bottom_padding = 0
style.left_padding = 0
style.graphical_set.base.center = {position = TRANSPARENT, size = {1, 1}}
style.graphical_set.base.bottom = nil

-- FR : Panneau d'onglets qui utilise ce cadre
-- EN : Tabbed pane that uses this frame
style = copyStyle('tabbed_pane' .. SUFFIX, default_gui.tabbed_pane)
style.tab_content_frame.parent = 'tabbed_pane_frame' .. SUFFIX

-- FR : Bande de fond en haut de chaque onglet (avec l'ombre d'un sous-titre du jeu)
-- EN : Background strip at the top of each tab (with the shadow of a game subheader)
style = emptyStyle('empty-tabbed_pane_frame-bg' .. SUFFIX)
style.graphical_set = {
    base = {
        center = {position = LINE, size = {1, 1}},
        bottom = {position = {76, 9}, size = {1, 8}},
    },
    shadow = table.deepcopy(default_gui.subheader_frame.graphical_set.shadow),
}
style.horizontally_stretchable = 'on'

-- FR : Séparateur vertical entre la liste et l'arbre
-- EN : Vertical divider between the list and the tree
style = emptyStyle('vertical-divider' .. SUFFIX)
style.graphical_set = {
    base = {
        left = {position = {68, 8}, size = {8, 1}},
        center = {position = LINE, size = {1, 1}},
        right = {position = {77, 8}, size = {8, 1}},
    },
    shadow = table.deepcopy(default_gui.frame.graphical_set.shadow),
}
style.vertically_stretchable = 'on'

-- FR : Zone défilante (listes et arbres) : s'étire, barres de défilement plus fines
-- EN : Scrolling area (lists and trees): stretches, thinner scroll bars
style = copyStyle('scroll_pane' .. SUFFIX, default_gui.scroll_pane_under_subheader)
style.horizontally_stretchable = 'on'
style.vertically_stretchable = 'on'
style.horizontal_scrollbar_style = table.deepcopy(default_gui.scroll_pane.horizontal_scrollbar_style)
style.horizontal_scrollbar_style.height = 18
style.horizontal_scrollbar_style.thumb_button_style = table.deepcopy(default_gui.horizontal_scrollbar.thumb_button_style)
style.horizontal_scrollbar_style.thumb_button_style.height = 16
style.vertical_scrollbar_style = table.deepcopy(default_gui.scroll_pane.vertical_scrollbar_style)
style.vertical_scrollbar_style.width = 18
style.vertical_scrollbar_style.thumb_button_style = table.deepcopy(default_gui.vertical_scrollbar.thumb_button_style)
style.vertical_scrollbar_style.thumb_button_style.width = 16

-- FR : Bouton de la liste de gauche (mods, objets) : arrondi, texte à gauche, s'étire
-- EN : Left list button (mods, objects): rounded, text on the left, stretches
style = copyStyle('c_sub_mod' .. SUFFIX, default_gui.rounded_button)
style.horizontally_stretchable = 'on'
style.horizontally_squashable = 'off'
style.horizontal_align = "left"


---------------------------------------------------------------------------------------------
-- FR : ARBRES
-- EN : TREES
---------------------------------------------------------------------------------------------

-- FR : Traits de l'arbre : visible, et caché (même place, fond transparent)
-- EN : Tree lines: visible, and hidden (same place, transparent background)
style = emptyStyle('branch' .. SUFFIX)
style.graphical_set = plain(LINE)

style = emptyStyle('branch-hide' .. SUFFIX)
style.graphical_set = plain(TRANSPARENT)

-- FR : Clé d'une ligne d'arbre : bouton à fond transparent, texte blanc à gauche, lueur au survol
-- EN : Tree row key: transparent background button, white text on the left, glow on hover
default_gui['tree-item' .. SUFFIX] = {
    type = "button_style",
    font = "default",
    horizontal_align = "left",
    vertical_align = "center",
    icon_horizontal_align = "left",
    default_font_color = {1, 1, 1},
    top_padding = 0,
    bottom_padding = 0,
    left_padding = 0,
    right_padding = 0,
    minimal_width = 1,
    minimal_height = 1,
    default_graphical_set = plain(TRANSPARENT),
    hovered_font_color = {1, 1, 1},
    hovered_graphical_set = {
        base = {center = {position = TRANSPARENT, size = {1, 1}}},
        glow = table.deepcopy(default_gui.button.hovered_graphical_set.glow),
    },
    clicked_font_color = {1, 1, 1},
    clicked_vertical_offset = 0,
    clicked_graphical_set = {
        base = {center = {position = PRESSED, size = {1, 1}}},
        glow = table.deepcopy(default_gui.button.hovered_graphical_set.glow),
    },
    left_click_sound = table.deepcopy(default_gui.button.left_click_sound),
    disabled_font_color = {179, 179, 179},
    disabled_graphical_set = plain(TRANSPARENT),
    selected_graphical_set = plain(TRANSPARENT),
    selected_hovered_graphical_set = {
        base = {center = {position = TRANSPARENT, size = {1, 1}}},
        glow = table.deepcopy(default_gui.button.hovered_graphical_set.glow),
    },
    selected_clicked_graphical_set = {
        base = {center = {position = PRESSED, size = {1, 1}}},
        glow = table.deepcopy(default_gui.button.hovered_graphical_set.glow),
    },
    strikethrough_color = {0.5, 0.5, 0.5},
    pie_progress_color = {1, 1, 1},
}

-- FR : Clé d'un dossier : lueur verte
-- EN : Folder key: green glow
style = copyStyle('tree-item-folder' .. SUFFIX, default_gui['tree-item' .. SUFFIX])
setGlow(style, 'green_button')

-- FR : « Continuer à charger » : lueur rouge (seulement survol et clic, comme avant)
-- EN : "Continue to load": red glow (only hover and click, as before)
style = copyStyle('load-cont' .. SUFFIX, default_gui['tree-item' .. SUFFIX])
style.hovered_graphical_set.glow = table.deepcopy(default_gui.red_button.hovered_graphical_set.glow)
style.clicked_graphical_set.glow = table.deepcopy(default_gui.red_button.hovered_graphical_set.glow)

-- FR : Lignes suivies (clic droit) : valeur, et dossier
-- EN : Tracked rows (right click): value, and folder
trackedVariant('tracked-tree-item' .. SUFFIX, default_gui['tree-item' .. SUFFIX], TRACKED)
trackedVariant('tracked-tree-item-folder' .. SUFFIX, default_gui['tree-item-folder' .. SUFFIX], TRACKED)

-- FR : Valeur objet Lua (clic droit pour l'ajouter) : lueur rouge ; ajoutée : fond de couleur
-- EN : Lua object value (right click to add it): red glow; added: coloured background
style = copyStyle('tree-item-luaobj' .. SUFFIX, default_gui['tree-item' .. SUFFIX])
setGlow(style, 'red_button')
trackedVariant('tracked-tree-item-luaobj' .. SUFFIX, default_gui['tree-item-luaobj' .. SUFFIX], TRACKED_OBJECT)

-- FR : Méthode et propriété n/a : pas de réaction au survol ni au clic, pas de son
-- EN : Method and n/a property: no reaction on hover or click, no sound
style = copyStyle('tree-item-func' .. SUFFIX, default_gui['tree-item' .. SUFFIX])
style.clicked_graphical_set = plain(TRANSPARENT)
style.selected_clicked_graphical_set = plain(TRANSPARENT)
style.hovered_graphical_set.glow = nil
style.clicked_graphical_set.glow = nil
style.selected_hovered_graphical_set.glow = nil
style.left_click_sound = nil

copyStyle('tree-item-na' .. SUFFIX, default_gui['tree-item-func' .. SUFFIX])


---------------------------------------------------------------------------------------------
-- FR : LISTES
-- EN : LISTS
---------------------------------------------------------------------------------------------

-- FR : Liste transparente (résultats de recherche, pages de l'aide) : zone défilante, puis liste
-- EN : Transparent list (search results, help pages): scrolling area, then list
style = copyStyle('list_box_scroll_pane-transparent' .. SUFFIX, default_gui.list_box_scroll_pane)
style.background_graphical_set = {
    position = {187, 0},
    corner_size = 1,
    overall_tiling_vertical_size = 20,
    overall_tiling_vertical_spacing = 8,
    overall_tiling_vertical_padding = 4,
    overall_tiling_horizontal_padding = 4,
}
style.graphical_set = plain(TRANSPARENT)

style = copyStyle('list_box-transparent' .. SUFFIX, default_gui.list_box)
style.scroll_pane_style.parent = 'list_box_scroll_pane-transparent' .. SUFFIX
