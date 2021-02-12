-- 트리 검색

--local Tree = require('modules.tree') --treepath 미사용. unused.
local Util = require('modules.util')

local Search_Tree = {}

--upvalues for recursive functions
local search_text = ''
local found_list = {}
local fkey = false
local fvalue = false
local fcase = false
local tree_data = {}

--richtext [color=...][/color] removal
local remove_richkey = function(str)
  --local tstr = str:match('^.- %(%[color=[^%[]+]([^%[]+)%[/color]%)$') --LuaObject type string
  str = str:gsub('^(.-) %(%[color=[^%[]+][^%[]+%[/color]%)$', '%1')
  str = str:gsub('^%[img=[^%[]+](.-)$', '%1')
  str = str:gsub('^%[color=[^%[]+](.-)%[/color]$', '%1')
  str = str:gsub('^%[(.-)]$', '%1')
  str = str:gsub('^%[color=[^%[]+](.-)%[/color]$', '%1')
  str = str:gsub('^"(.-)"$', '%1')
  --if tstr then str = str .. ' (' .. tstr .. ')' end
  return str
end

--richtext [color=...][/color] removal
local remove_richval = function(str)
  str = str:gsub('^"(.-)"$', '%1')
  str = str:gsub('^%[color=[^%[]+](.-)%[/color]$', '%1')
  return str
end

--pcall 에서 pattern의 오류 탐지
local test_pattern = function(str)
  return string.match('', str)
end

--갱신 refresh
Search_Tree.refresh = function(g, treename)
  local wrapper = g.gui['search_'..treename..'_wrap']
  local text = g.search_settings[treename].text
  local inputfield = g.gui['search_'..treename..'_input']
  local result = g.gui['search_'..treename..'_result']
  local filter = {
    key = g.gui['search_'..treename..'_fkey'].state,
    value = g.gui['search_'..treename..'_fvalue'].state,
    regexp = g.gui['search_'..treename..'_fregexp'].state,
    case = g.gui['search_'..treename..'_fcase'].state,
  }
  local data = g.data.search[treename]
  local tree = g.gui['sub_'..treename..'tree']
  local result_list = {}

  result.clear_items()
  g.data.search[treename] = {}

  if not wrapper.visible then
    if tree and tree.children[1] and not tree.children[1].name:match('^[*]') and tree.children[2] and tree.children[3] then
      if treename == 'glob' then
        Search_Tree.reset_scan(tree.children[2].content_container.folder)
      end
      Search_Tree.reset_scan(tree.children[3].content_container.folder)
    end
    return
  end

  if filter.regexp then
    local pc = pcall(test_pattern, text)
    if pc then
      inputfield.style.font_color = {0,0,0}
    else
      inputfield.style.font_color = {1,0,0}
      return
    end
  else
    inputfield.style.font_color = {0,0,0}
    text = text:gsub('[%(%)%.%%%+%-%*%?%[%^%$]', '%%%1')
  end
  if not filter.case then
    text = text:lower()
  end

  if tree and tree.children[1] and not tree.children[1].name:match('^[*]') and tree.children[2] and tree.children[3] then
    search_text = text
    found_list = {}
    fkey = filter.key
    fvalue = filter.value
    fcase = filter.case
    tree_data = {}
    if treename == 'glob' then
      tree_data = g.data._G_tree_item_glob
      if tree.children[2].content_container.visible then
        Search_Tree.scan(tree.children[2].content_container.folder)
      else
        Search_Tree.not_scan(tree.children[2].content_container.folder)
      end
      tree_data = g.data.tree_item_glob
    elseif treename == 'prop' then
      tree_data = g.data.tree_item_prop
    elseif treename == 'gobj' then
      tree_data = g.data.tree_item_gobj
    end
    if tree.children[3].content_container.visible then
      Search_Tree.scan(tree.children[3].content_container.folder)
    else
      Search_Tree.not_scan(tree.children[3].content_container.folder)
    end
    g.data.search[treename] = Util.deepcopytbl(found_list)
    for i, v in ipairs(found_list) do
      result_list[i] = v.name
    end
    result.items = result_list
  end
end

--검색을 끌 때 사용. Used when turning off search mode.
Search_Tree.reset_scan = function(parent_container)
  for index, container in ipairs(parent_container.children) do
    if container.valid then
      if container.label_container then
        container.label_container.style = 'transparent-frame_gvv-mod'
        if container.content_container then
          Search_Tree.reset_scan(container.content_container.folder)
        end
      end
    end
  end
end

--안보이는 항목은 검색안함. Not scan invisible items.
Search_Tree.not_scan = function(parent_container)
  for index, container in ipairs(parent_container.children) do
    if container.valid then
      if container.label_container then
        container.label_container.style = 'transparent-frame_gvv-mod'
      end
    end
  end
end

--검색 scan
Search_Tree.scan = function(parent_container)
  local name = nil
  for index, container in ipairs(parent_container.children) do
    if container.valid then
      if container.label_container then
        if container.visible and type(container.label_container['_gvv-mod_key_label'].caption) == 'string' then
          local key = remove_richkey(container.label_container['_gvv-mod_key_label'].caption)
          if not fcase then key = key:lower() end
          local value = nil
          if container.label_container['_gvv-mod_key_value'] then
            value = remove_richval(container.label_container['_gvv-mod_key_value'].caption)
            if not fcase then value = value:lower() end
          end

          if search_text ~= '' and fkey and key:match(search_text) then
            if value then
              name = container.label_container['_gvv-mod_key_label'].caption .. ' = ' .. container.label_container['_gvv-mod_key_value'].caption
            else
              name = container.label_container['_gvv-mod_key_label'].caption
            end
            found_list[#found_list + 1] = {
              elem = container.label_container['_gvv-mod_key_label'],
              --treepath = Tree.track_path(tree_data, container.label_container['_gvv-mod_key_label'], {}),
              name = name,
            }
            container.label_container.style = 'highlighted-frame_gvv-mod'
          elseif search_text ~= '' and fvalue and value and value:match(search_text) then
            found_list[#found_list + 1] = {
              elem = container.label_container['_gvv-mod_key_label'],
              --treepath = Tree.track_path(tree_data, container.label_container['_gvv-mod_key_label'], {}),
              name = container.label_container['_gvv-mod_key_label'].caption .. ' = ' .. container.label_container['_gvv-mod_key_value'].caption,
            }
            container.label_container.style = 'highlighted-frame_gvv-mod'
          else
            container.label_container.style = 'transparent-frame_gvv-mod'
          end

          if container.content_container and container.content_container.visible then
            Search_Tree.scan(container.content_container.folder)
          elseif container.content_container then
            Search_Tree.not_scan(container.content_container.folder)
          end
        end
      end
    end
  end
end

return Search_Tree
