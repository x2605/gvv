---------------------------------------------------------------------------------------------
-- GUI : HELP PAGES
---------------------------------------------------------------------------------------------
-- FR : Contenu des pages de l'onglet aide, repris de l'ancien legacy/help_menu.lua sans changement
--      de texte (mêmes clés de traduction, mêmes codes à copier, même mise en page).
--      Chaque page est une fonction write(help) qui écrit dans la page avec les méthodes de GvvGuiHelp :
--        help:addTitle(texte)          titre (ancien head)
--        help:addSubtitle(texte)       sous-titre (ancien head2)
--        help:addText(texte, infobulle) paragraphe (ancien text)
--        help:addCopyable(code, lié)   code à copier en lecture seule (ancien copyable)
--        help:addLine()                ligne de séparation (ancien hr)
--        help:openRow() / openColumn() ouvre un conteneur horizontal / vertical (anciens hpo / vpo)
--        help:closeContainer()         revient au conteneur parent (ancien px)
--        help:add(description)         ajoute un élément quelconque (menus, boutons...), décrit dans help.specs
--      Chaque méthode renvoie l'élément créé, pour ajuster son style (ex. .style.top_margin = 5).
-- EN : Help tab pages content, taken from the old legacy/help_menu.lua without text change
--      (same translation keys, same codes to copy, same layout).
--      Each page is a write(help) function that writes into the page with GvvGuiHelp's methods
--      (see the list above). Each method returns the created element, to adjust its style.
---------------------------------------------------------------------------------------------
local Util = require(gvv.defines.lualib.common.util)
local Copy_Code = require(gvv.defines.lualib.common.copy_code)
---------------------------------------------------------------------------------------------

-- FR : Liste des pages, dans l'ordre de la liste à gauche
-- EN : Pages list, in the order of the list on the left
local pages = {
    { name = 'control_lua', caption = {"gvv-mod-help.control_lua"} },
    { name = 'console1', caption = {"gvv-mod-help.console1"} },
    { name = 'console2', caption = {"gvv-mod-help.console2"} },
    { name = 'how_to_use_gui', caption = {"gvv-mod-help.how_to_use_gui"} },
    { name = 'troubleshoot', caption = {"gvv-mod-help.troubleshoot"} },
    { name = 'tips', caption = {"gvv-mod-help.tips"} },
}

---**EN**
---
---Description: Page by its name, or nil.
---
---──────────────────────────────
---
---**FR**
---
---Description: Page par son nom, ou nil.
---@param name string
---@return table?
local function getPage(name)
    for _, page in ipairs(pages) do
        if page.name == name then
            return page
        end
    end
    return nil
end

---**EN**
---
---Description: Bold text, for the words highlighted in the paragraphs
---
---──────────────────────────────
---
---**FR**
---
---Description: Texte en gras, pour les mots mis en valeur dans les paragraphes
---@param text LocalisedString
---@return LocalisedString
local function bold(text)
    return {"", '[font=default-bold]', text, '[/font]'}
end

---**EN**
---
---Description: Tracking tab name in bold, often quoted
---
---──────────────────────────────
---
---**FR**
---
---Description: Nom de l'onglet suivi en gras, souvent cité
---@return LocalisedString
local function trackingTabName()
    return bold({"gvv-mod.tab-filtered-view"})
end

---**EN**
---
---Description: First mod (other than level and gvv) that loads the gvv interface, otherwise default_name
---
---──────────────────────────────
---
---**FR**
---
---Description: Premier mod (autre que level et gvv) qui charge l'interface gvv, sinon default_name
---@param default_name string
---@return string
local function exampleModName(default_name)
    for name in pairs(script.active_mods) do
        -- FR : Lecture protégée : le mod n'a peut-être pas d'interface gvv
        -- EN : Protected read: the mod may have no gvv interface
        local found, interface = pcall(function()
            return remote.interfaces['__' .. name .. '__gvv']['c']
        end)
        if found and interface and name ~= 'level' and name ~= 'gvv' then
            return name
        end
    end
    return default_name
end


---------------------------------------------------------------------------------------------
-- FR : Page « control.lua » : activer gvv dans un mod
-- EN : "control.lua" page: enabling gvv in a mod
---------------------------------------------------------------------------------------------
pages[1].write = function(help)
    local x = 'gvv-mod-help-control_lua.'
    help:addTitle{x .. '1'}
    help:addText{x .. '2'}
    help:addText{x .. '3'}
    help:addCopyable(Copy_Code.in_control_lua())
    help:addText{x .. '4'}
    help:addText(' ')
    help:addText{x .. '5', bold(getPage('console1').caption)}
    help:addText{x .. '6'}
    help:addText(' ')
end


---------------------------------------------------------------------------------------------
-- FR : Page « console 1 » : commandes, et activation temporaire de gvv dans un mod
-- EN : "console 1" page: commands, and temporary enabling of gvv in a mod
---------------------------------------------------------------------------------------------
pages[2].write = function(help)
    local x = 'gvv-mod-help-console1.'
    help:addTitle{x .. '1'}
    help:addText{x .. '2'}
    help:addText{x .. '3', ' [font=default-bold]/gvv[/font]'}
    help:addText{x .. '4', ' [font=default-bold]/gmods[/font]'}
    help:addText{x .. '5', ' [font=default-bold]/gdump[/font]', '[font=default-bold]/gdump-luaon & /gdump-json[/font]', '[font=default-bold]/gdump-luaon[/font]'}
    help:addText{x .. '5-0'}.style.top_margin = 5
    help:addText{x .. '5-1', ' [font=default-bold]/c /command[/font]', '[font=default-bold]/sc /silent-command[/font]'}.style.bottom_margin = 5
    help:addLine()
    help:addSubtitle{x .. '6-0'}
    help:addText{x .. '6'}

    -- FR : Menu du mod + code d'activation correspondant
    -- EN : Mod menu + matching enabling code
    help:openRow()
    local enable = help:add(help.specs.dropdown.enable)
    enable.items = Util.get_all_mod_list({gvv = true, base = true})
    enable.selected_index = 1
    enable.style.horizontally_squashable = true
    help:addCopyable(Copy_Code.in_console_enable(), true)
    help:closeContainer()

    help:addText{x .. '7'}
    help:addText{x .. '8'}.style.top_margin = 5

    -- FR : Menu du mod + code de désactivation correspondant
    -- EN : Mod menu + matching disabling code
    help:openRow()
    local disable = help:add(help.specs.dropdown.disable)
    disable.items = Util.get_all_mod_list({gvv = true, base = true})
    disable.selected_index = 1
    disable.style.horizontally_squashable = true
    help:addCopyable(Copy_Code.in_console_disable(), true)
    help:closeContainer()

    help:addText{x .. '9'}
    help:addText{x .. '10'}
    help:addText(' ')
end


---------------------------------------------------------------------------------------------
-- FR : Page « console 2 » : écrire le nom d'un mod (4 formes) dans la console
-- EN : "console 2" page: writing a mod name (4 forms) in the console
---------------------------------------------------------------------------------------------
pages[3].write = function(help)
    local x = 'gvv-mod-help-console2.'
    help:addTitle{x .. '1'}
    help:addText{x .. '2'}.style.single_line = true

    help:openRow().style.vertical_align = 'top'

    -- FR : Liste des formes du nom de mod
    -- EN : List of the mod name forms
    local option = help:add(help.specs.listbox.option)
    option.items = {'<mod_name>', '__<mod_name>__', 'remote.call..."storage")', 'remote.call..."c",)'}
    option.selected_index = 3
    option.style.horizontally_stretchable = false
    option.style.vertically_stretchable = true
    option.style.minimal_width = 160
    option.style.minimal_height = 81
    option.style.right_margin = 3

    -- FR : Code à copier, puis liste des mods accessibles
    -- EN : Code to copy, then list of the accessible mods
    help:openColumn(help.specs.flow.mod_list)
    local copy = help:addCopyable('', true)
    local mod = help:add(help.specs.listbox.mod)
    mod.items = Util.get_accessible_mod_list()
    mod.selected_index = 1
    mod.style.vertically_stretchable = true
    help:setCopyableText(copy, 'remote.call("__' .. tostring(mod.items[mod.selected_index]) .. '__gvv","storage")')
    help:closeContainer()

    help:closeContainer()
    help:addText(' ')
end


---------------------------------------------------------------------------------------------
-- FR : Page « utilisation » : les onglets et les lignes de l'arbre (avec démonstrations)
-- EN : "usage" page: the tabs and the tree rows (with demonstrations)
---------------------------------------------------------------------------------------------
pages[4].write = function(help)
    local x = 'gvv-mod-help-how_to_use_gui.'
    help:addTitle{x .. '1'}
    help:addText{x .. '2'}
    help:addText{x .. '3', {"", ' [font=default-bold]', {"gvv-mod.tab-filtered-view"}, '[/font]'}}
    help:addText{x .. '4', ' [font=default-bold]storage[/font]'}
    help:addText{x .. '5', ' [font=default-bold]property[/font]'}
    help:addText{x .. '6', ' [font=default-bold]LuaObject[/font]'}
    help:addText{x .. '7', {"", ' [font=default-bold]', {"gvv-mod.help-tab"}, '[/font]'}}
    help:addText(' ')
    help:addText{x .. '8'}

    -- FR : Démonstration : dossier (icône + nom), clic droit pour le suivre
    -- EN : Demonstration: folder (icon + name), right click to track it
    help:openRow()
    local sprite = help:add(help.specs.sprite.folder)
    sprite.style.width = 20
    sprite.style.height = 20
    sprite.style.stretch_image_to_widget_size = true
    help:addDemo('[font=default-bold]table_key_name[/font]', 'tree-item-folder_gvv-mod', {'left', 'right'})
    help:addText{x .. '9', {"", ' [font=default-bold]', {"gvv-mod.tab-filtered-view"}, '[/font]'}}
    help:closeContainer()

    -- FR : Démonstration : valeur simple
    -- EN : Demonstration: simple value
    help:openRow()
    help:addDemo(' [font=default-bold]value_key_name[/font]', 'tree-item_gvv-mod', {'right'})
    help:addText{x .. '10', {"", ' [font=default-bold]', {"gvv-mod.tab-filtered-view"}, '[/font]'}}
    help:closeContainer()

    -- FR : Démonstration : objet Lua
    -- EN : Demonstration: Lua object
    help:openRow()
    help:addDemo(' [color=blue][font=default-bold]LuaObj_value[/font][/color]', 'tree-item-luaobj_gvv-mod', {'right'})
    help:addText{x .. '11', ' [font=default-bold]property[/font]'}
    help:closeContainer()

    -- FR : Démonstration : propriété non disponible
    -- EN : Demonstration: unavailable property
    help:openRow()
    help:addDemo(' [color=0.5,0.5,0.5,0.5][font=default-bold]n/a_property_name[/font][/color]', 'tree-item-na_gvv-mod', {'right'})
    help:addText{x .. '12'}
    help:closeContainer()

    -- FR : Démonstration : méthode
    -- EN : Demonstration: method
    help:openRow()
    help:addDemo(' [color=0.5,0.5,0.5,0.5][font=default-bold]method_name(...)[/font][/color]', 'tree-item-func_gvv-mod', {'right'})
    help:addText{x .. '13'}
    help:closeContainer()

    help:addText(' ')
    help:addText{x .. '14', trackingTabName()}
    help:addText{x .. '15', trackingTabName()}
    help:addText(' ')
end


---------------------------------------------------------------------------------------------
-- FR : Page « dépannage » : diagnostic et nettoyage du storage d'un mod
-- EN : "troubleshooting" page: diagnosis and cleaning of a mod storage
---------------------------------------------------------------------------------------------
pages[5].write = function(help)
    local x = 'gvv-mod-help-troubleshoot.'
    help:addTitle{x .. '1'}
    help:addText{x .. '2'}
    help:addText{x .. '3'}
    help:addText(' ')
    help:addText{x .. '4'}

    -- FR : Exemples de messages d'erreur
    -- EN : Error message examples
    help:openColumn()
    for _, message in ipairs({" · Can't copy object of type function", " · Can't copy object of type userdata", " · table index is nil"}) do
        local label = help:addText(message)
        label.style.font = 'var'
        label.style.font_color = {1, 0.85, 0.7, 1}
    end
    help:closeContainer()

    help:addText{x .. '5', bold({"gvv-mod-helpui.diagnose"}), bold({"gvv-mod-helpui.fix"}), 'storage.report'}
    help:addText{x .. '6', bold({"gvv-mod-helpui.fix"})}

    -- FR : Nom du mod, puis boutons diagnostic et nettoyage alignés à droite
    -- EN : Mod name, then diagnose and fix buttons aligned to the right
    help:openColumn().style.padding = 10
    -- FR : clear_and_focus_on_right_click ne se donne qu'à la création : il est dans la description
    -- EN : clear_and_focus_on_right_click can only be given at creation: it is in the description
    local mod_name_spec = help.specs.textfield.mod
    mod_name_spec.clear_and_focus_on_right_click = false
    local mod_name = help:add(mod_name_spec)
    mod_name.style.horizontally_stretchable = true
    mod_name.style.horizontally_squashable = true
    mod_name.style.minimal_width = 10
    mod_name.style.maximal_width = 9999
    mod_name.style.bottom_margin = 10
    local buttons = help:openRow()
    buttons.style.horizontal_align = 'right'
    local diagnose = help:add(help.specs.button.diagnose)
    diagnose.style.right_margin = 10
    diagnose.style.horizontally_stretchable = false
    diagnose.style.horizontal_align = 'center'
    local fix = help:add(help.specs.button.fix)
    fix.style.horizontally_stretchable = false
    fix.style.horizontal_align = 'center'
    help:closeContainer()
    help:closeContainer()

    help:addText{x .. '7', bold({"gvv-mod-helpui.fix"}), '.error'}

    -- FR : Effacer storage.report
    -- EN : Clear storage.report
    help:openRow().style.vertical_align = 'center'
    local label = help:addText{x .. '8', 'storage.report'}
    label.style.right_margin = 5
    label.style.left_margin = 5
    local clear = help:add(help.specs.button.clear_report)
    clear.style.horizontally_stretchable = false
    clear.style.horizontal_align = 'center'
    help:closeContainer()

    help:addText(' ')
end


---------------------------------------------------------------------------------------------
-- FR : Page « astuces »
-- EN : "tips" page
---------------------------------------------------------------------------------------------
pages[6].write = function(help)
    local x = 'gvv-mod-help-tips.'
    local player_name = help.player.name

    help:addTitle{x .. '1'}
    help:addLine()
    help:addSubtitle{x .. '2'}
    help:addText{x .. '3'}
    help:addText{x .. '3-0', trackingTabName()}
    help:addText{x .. '3-1'}
    help:addCopyable('/c __gvv__ if not storage.memo then storage.memo={} end storage.memo["' .. player_name .. '"]={}').style.bottom_margin = 5
    help:addText{x .. '3-2'}
    local memo_prefix = '/sc __gvv__ local MEMO=storage.memo["' .. player_name .. '"] game.player.print("MEMO#"..#MEMO+1) MEMO[#MEMO+1]= '
    help:addCopyable(memo_prefix .. 'game.player.selected').style.bottom_margin = 5
    help:addText{x .. '3-3'}
    help:addCopyable(memo_prefix).style.bottom_margin = 5
    help:addText({x .. '3-4', '[font=default-semibold][color=128, 206, 240]Enter[/color][/font]'}, {x .. '3-4' .. '-tooltip'})
    help:addCopyable('/sc __gvv__ local t=setmetatable({},{__newindex=function(a,b,c) storage.memo["' .. player_name .. '"][c]=nil game.player.print("MEMO#"..c.."=nil") end}) t[1]= ').style.bottom_margin = 5
    help:addText{x .. '3-5'}
    help:addText(' ')

    help:addLine()
    help:addSubtitle{x .. '4'}
    help:addText{x .. '5', trackingTabName(), {"", '[color=0.75,0.75,0.75,1]', {x .. '5' .. '-word1'}, '[/color]'}}
    help:addText{x .. '6', bold('property')}
    help:addText{x .. '7', '[font=default-semibold][color=128, 206, 240]Ctrl + C[/color][/font]'}
    help:addText(' ')

    help:addLine()
    help:addSubtitle{x .. '8'}
    help:addText{x .. '9', trackingTabName()}
    help:addText(' ')

    help:addLine()
    help:addSubtitle{x .. '10'}
    help:addText{x .. '11',
        {"", '[font=default-bold]', {"gui-menu.game-menu"}, ' - ', {"gui-menu.settings"}, ' - ', {"gui-menu.mod-settings"}, ' - ', {"gui-mod-settings.map"}, '[/font]'},
        trackingTabName(),
    }
    help:addText{x .. '11-1'}
    help:addText{x .. '11-2'}
    help:addCopyable('/sc __gvv__ settings.global["gvv-mod_enable-on-tick"]={value= false }')
    help:addText(' ')

    help:addLine()
    help:addSubtitle{x .. '12'}
    help:addText{x .. '13'}
    help:addText(' ')

    help:addLine()
    help:addSubtitle{x .. '18', {"gvv-mod.tab-filtered-view"}}
    help:addText{x .. '19'}
    help:addCopyable('assert(function() <YOUR_CODE> return <RETURN_VALUE> end)()')
    help:addText(' ')

    help:addLine()
    help:addSubtitle{x .. '14'}
    help:addText{x .. '15'}
    help:addCopyable('/c game.player.print(script.mod_name)')
    help:addText('Prints : [color=0.25,1,0.25]level[/color]')
    help:addCopyable('/c __gvv__ game.player.print(script.mod_name)')
    help:addText('Prints : [color=0.25,1,0.25]gvv[/color]')
    local example_name = exampleModName('my Mod-1')
    help:addCopyable('/c __' .. example_name .. '__ game.player.print(script.mod_name)')
    help:addText({x .. '16', 'Prints : [color=0.25,1,0.25]' .. example_name .. '[/color]'})
    help:addText(' ')

    help:addLine()
    help:addSubtitle('remote.call("__<mod_name>__gvv", "c", <script>, ...)')
    help:addText{x .. '17'}
    local remote_example_name = exampleModName('gvv')
    help:addCopyable('remote.call("__' .. remote_example_name .. '__gvv", "c", [[\n'
        .. 'local pos = {\n'
        .. '  ( arg[1].right_bottom[1] - arg[1].left_top[1] ) /2 + arg[1].left_top[1],\n'
        .. '  ( arg[1].right_bottom[2] - arg[1].left_top[2] ) /2 + arg[1].left_top[2]\n'
        .. '} -- arg is a predefined table of c function.\n'
        .. 'game.player.surface.create_entity{\n'
        .. '  position = pos,\n'
        .. '  name = "flying-text",\n'
        .. '  text = script.mod_name .. arg[2],\n'
        .. '}\n'
        .. ']], area, " TEST") -- area is passed to arg[1].\n'
        .. '-- area is a predefined table of Lua snippet.'
    )
    help:addText(' ')
end


---------------------------------------------------------------------------------------------
-- FR : Fonctions exportées et liste des pages
-- EN : Exported functions and pages list
return {
    pages = pages,
    getPage = getPage,
}
