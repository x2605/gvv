-- 데이터

local suffix = '_gvv-mod'

data:extend{
  {
    type = 'custom-input',
    name = 'toggle-main-frame'..suffix,
    key_sequence = 'CONTROL + SHIFT + V'
  },
  {
    type = 'custom-input',
    name = 'refresh'..suffix,
    key_sequence = 'SHIFT + X'
  },
  {
    type = "sprite",
    name = "gvv-mod_folder-opened",
    filename = "__gvv__/icons/folder-opened.png",
    priority = "extra-high-no-scale",
    width = 32,
    height = 32,
    flags = {"gui-icon"},
    mipmap_count = 1,
    scale = 0.5
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
    scale = 0.5
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
    scale = 0.5
  },
  {
    type = "font",
    name = "var-outline-gvv-mod",
    from = "default-bold",
    size = 14,
    border = true,
    border_color = {}
  },
  {
    type = "sprite",
    name = "gvv-mod_arrow-up",
    filename = "__core__/graphics/arrows/table-header-sort-arrow-up-white.png",
    priority = "extra-high-no-scale",
    width = 16,
    height = 16,
    flags = {"gui-icon"},
    mipmap_count = 1,
    scale = 0.5
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
    scale = 0.5
  },
  {
    type = "sprite",
    name = "gvv-mod_export-import",
    filename = "__gvv__/icons/export-import.png",
    priority = "extra-high-no-scale",
    width = 32,
    height = 32,
    flags = {"gui-icon"},
    mipmap_count = 2,
    scale = 0.5
  },
  {
    type = "sprite",
    name = "gvv-mod_red-check",
    filename = "__core__/graphics/icons/mip/check-mark-white.png",
    priority = "extra-high-no-scale",
    width = 32,
    height = 32,
    flags = {"gui-icon"},
    mipmap_count = 2,
    tint = {r=1, g=0.25, b=0.25, a=1},
    scale = 0.5
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
    tint = {r=0, g=1, b=0, a=1},
    scale = 0.5
  },
  {
    type = "sprite",
    name = "gvv-mod_load-cont",
    filename = "__gvv__/icons/load-cont.png",
    priority = "extra-high-no-scale",
    width = 32,
    height = 32,
    flags = {"gui-icon"},
    mipmap_count = 1,
    scale = 0.5
  },
}

local default_gui = data.raw['gui-style'].default
local copytbl = function(dupl,source)
  default_gui[dupl] = table.deepcopy(source)
  return default_gui[dupl]
end
local emptywidget = function(dupl)
  default_gui[dupl] = {type = 'empty_widget_style', graphical_set = {}}
  return default_gui[dupl]
end
local c

default_gui['hflow'..suffix] = {
  type = "horizontal_flow_style",
  padding = 0,
  horizontal_spacing = 0,
}
default_gui['vflow'..suffix] = {
  type = "vertical_flow_style",
  padding = 0,
  vertical_spacing = 0,
}
default_gui['transparent-frame'..suffix] = {
  type = "frame_style",
  top_padding = 0,
  right_padding = 0,
  bottom_padding = 0,
  left_padding = 0,
  horizontal_flow_style = {type = 'horizontal_flow_style', parent = 'hflow'..suffix},
  vertical_flow_style = {type = 'vertical_flow_style', parent = 'vflow'..suffix},
  graphical_set = {base = {center = {position = {25, 8}, size = {1, 1}}}},
}

c = copytbl('highlighted-frame'..suffix, default_gui['transparent-frame'..suffix])
c.graphical_set.base.center = {position = {287, 79}, size = {1, 1}}

c = copytbl('output'..suffix, default_gui.label)
c.single_line = false

c = copytbl('frame'..suffix, default_gui.frame)
c.graphical_set.base.draw_type = 'outer'
c.graphical_set.base.center = {position = {25, 8}, size = {1, 1}}
c.top_padding = 0
c.right_padding = 0
c.bottom_padding = 0
c.left_padding = 0
c.horizontal_flow_style = default_gui['hflow'..suffix]
c.vertical_flow_style = default_gui['vflow'..suffix]

c = copytbl('frame-bg'..suffix, default_gui.frame)
c.graphical_set = {base = {center = {position = {8, 8}, size = {1, 1}}}}
c.top_padding = 0
c.right_padding = 0
c.bottom_padding = 0
c.left_padding = 0
c.use_header_filler = false

c = emptywidget('empty-frame-bg'..suffix)
c.graphical_set = {base = {center = {position = {8, 8}, size = {1, 1}}}}

c = copytbl('tabbed_pane_frame'..suffix, default_gui.tabbed_pane_frame)
c.top_padding = 0
c.right_padding = 0
c.bottom_padding = 0
c.left_padding = 0
c.graphical_set.base.center = {position = {25, 8}, size = {1, 1}}
c.graphical_set.base.bottom = nil

c = emptywidget('empty-tabbed_pane_frame-bg'..suffix)
c.graphical_set = {
  base = {
    center = {position = {76, 8}, size = {1, 1}},
    bottom = {position = {76, 9}, size = {1, 8}}
  },
  shadow = table.deepcopy(default_gui.subheader_frame.graphical_set.shadow)
}
c.horizontally_stretchable = 'on'

c = emptywidget('vertical-divider'..suffix)
c.graphical_set = {
  base = {
    left = {position = {68, 8}, size = {8, 1}},
    center = {position = {76, 8}, size = {1, 1}},
    right = {position = {77, 8}, size = {8, 1}}
  },
  shadow = table.deepcopy(default_gui.frame.graphical_set.shadow)
}
c.vertically_stretchable = 'on'

c = copytbl('tabbed_pane'..suffix, default_gui.tabbed_pane)
c.tab_content_frame.parent = 'tabbed_pane_frame'..suffix

c = copytbl('inside-wrap'..suffix, default_gui['frame'..suffix])
c.graphical_set = {
  base = {
    position = {17, 0}, corner_size = 8, draw_type = 'inner',
    center = {position = {25, 8}, size = {1, 1}},
  }
}

c = copytbl('inside_deep_frame'..suffix, default_gui.inside_deep_frame)
c.graphical_set.base = {
  center = {position = {336, 0}, size = {1, 1}},
  opacity = 0.75,
  background_blur = true
}

c = copytbl('scroll_pane'..suffix, default_gui.scroll_pane_under_subheader)
c.horizontally_stretchable = 'on'
c.vertically_stretchable = 'on'
c.horizontal_scrollbar_style = table.deepcopy(default_gui.scroll_pane.horizontal_scrollbar_style)
c.horizontal_scrollbar_style.height=18
c.horizontal_scrollbar_style.thumb_button_style = table.deepcopy(default_gui.horizontal_scrollbar.thumb_button_style)
c.horizontal_scrollbar_style.thumb_button_style.height=16
c.vertical_scrollbar_style = table.deepcopy(default_gui.scroll_pane.vertical_scrollbar_style)
c.vertical_scrollbar_style.width=18
c.vertical_scrollbar_style.thumb_button_style = table.deepcopy(default_gui.vertical_scrollbar.thumb_button_style)
c.vertical_scrollbar_style.thumb_button_style.width=16

c = copytbl('c_sub_mod'..suffix, default_gui.rounded_button)
c.horizontally_stretchable = 'on'
c.horizontally_squashable = 'off'
c.horizontal_align = "left"

c = emptywidget('branch'..suffix)
c.graphical_set = {base = {center = {position = {76, 8}, size = {1, 1}}}}

c = emptywidget('branch-hide'..suffix)
c.graphical_set = {base = {center = {position = {25, 8}, size = {1, 1}}}}

default_gui['tree-item'..suffix] = {
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
  default_graphical_set = {base = {center = {position = {25, 8}, size = {1, 1}}}},
  hovered_font_color = {1, 1, 1},
  hovered_graphical_set =
  {
    base = {center = {position = {25, 8}, size = {1, 1}}},
    glow = table.deepcopy(default_gui.button.hovered_graphical_set.glow),
  },
  clicked_font_color = {1, 1, 1},
  clicked_vertical_offset = 0,
  clicked_graphical_set =
  {
    base = {center = {position = {8, 25}, size = {1, 1}}},
    glow = table.deepcopy(default_gui.button.hovered_graphical_set.glow),
  },
  left_click_sound = table.deepcopy(default_gui.button.left_click_sound),
  disabled_font_color = {179, 179, 179},
  disabled_graphical_set =
  {
    base = {center = {position = {25, 8}, size = {1, 1}}},
  },
  selected_font_color = button_hovered_font_color,
  selected_graphical_set =
  {
    base = {center = {position = {25, 8}, size = {1, 1}}},
  },
  selected_hovered_font_color = button_hovered_font_color,
  selected_hovered_graphical_set =
  {
    base = {center = {position = {25, 8}, size = {1, 1}}},
    glow = table.deepcopy(default_gui.button.hovered_graphical_set.glow),
  },
  selected_clicked_font_color = button_hovered_font_color,
  selected_clicked_graphical_set =
  {
    base = {center = {position = {8, 25}, size = {1, 1}}},
    glow = table.deepcopy(default_gui.button.hovered_graphical_set.glow),
  },
  strikethrough_color = {0.5, 0.5, 0.5},
  pie_progress_color = {1, 1, 1},
}

c = copytbl('tree-item-folder'..suffix, default_gui['tree-item'..suffix])
c.hovered_graphical_set.glow = table.deepcopy(default_gui.green_button.hovered_graphical_set.glow)
c.clicked_graphical_set.glow = table.deepcopy(default_gui.green_button.hovered_graphical_set.glow)
c.selected_hovered_graphical_set.glow = table.deepcopy(default_gui.green_button.hovered_graphical_set.glow)
c.selected_clicked_graphical_set.glow = table.deepcopy(default_gui.green_button.hovered_graphical_set.glow)

c = copytbl('load-cont'..suffix, default_gui['tree-item'..suffix])
c.hovered_graphical_set.glow = table.deepcopy(default_gui.red_button.hovered_graphical_set.glow)
c.clicked_graphical_set.glow = table.deepcopy(default_gui.red_button.hovered_graphical_set.glow)

c = copytbl('tracked-tree-item'..suffix, default_gui['tree-item'..suffix])
local a, b = 337, 56
c.default_graphical_set.base.center.position = {a, b}
c.hovered_graphical_set.base.center.position = {a, b}
c.disabled_graphical_set.base.center.position = {a, b}
c.selected_graphical_set.base.center.position = {a, b}
c.selected_hovered_graphical_set.base.center.position = {a, b}

c = copytbl('tracked-tree-item-folder'..suffix, default_gui['tree-item-folder'..suffix])
local a, b = 337, 56
c.default_graphical_set.base.center.position = {a, b}
c.hovered_graphical_set.base.center.position = {a, b}
c.disabled_graphical_set.base.center.position = {a, b}
c.selected_graphical_set.base.center.position = {a, b}
c.selected_hovered_graphical_set.base.center.position = {a, b}

c = copytbl('tree-item-luaobj'..suffix, default_gui['tree-item'..suffix])
c.hovered_graphical_set.glow = table.deepcopy(default_gui.red_button.hovered_graphical_set.glow)
c.clicked_graphical_set.glow = table.deepcopy(default_gui.red_button.hovered_graphical_set.glow)
c.selected_hovered_graphical_set.glow = table.deepcopy(default_gui.red_button.hovered_graphical_set.glow)
c.selected_clicked_graphical_set.glow = table.deepcopy(default_gui.red_button.hovered_graphical_set.glow)

c = copytbl('tracked-tree-item-luaobj'..suffix, default_gui['tree-item-luaobj'..suffix])
local a, b = 355, 161
c.default_graphical_set.base.center.position = {a, b}
c.hovered_graphical_set.base.center.position = {a, b}
c.disabled_graphical_set.base.center.position = {a, b}
c.selected_graphical_set.base.center.position = {a, b}
c.selected_hovered_graphical_set.base.center.position = {a, b}

c = copytbl('tree-item-func'..suffix, default_gui['tree-item'..suffix])
c.clicked_graphical_set = {base = {center = {position = {25, 8}, size = {1, 1}}}}
c.selected_clicked_graphical_set = {base = {center = {position = {25, 8}, size = {1, 1}}}}
c.hovered_graphical_set.glow = nil
c.clicked_graphical_set.glow = nil
c.selected_hovered_graphical_set.glow = nil
c.left_click_sound = nil

c = copytbl('tree-item-na'..suffix, default_gui['tree-item-func'..suffix])

c = copytbl('list_box_scroll_pane-transparent'..suffix, default_gui.list_box_scroll_pane)
c.background_graphical_set = {
  position = {187, 0},
  corner_size = 1,
  overall_tiling_vertical_size = 20,
  overall_tiling_vertical_spacing = 8,
  overall_tiling_vertical_padding = 4,
  overall_tiling_horizontal_padding = 4,
}
c.graphical_set = {base = {center = {position = {25, 8}, size = {1, 1}}}}

c = copytbl('list_box-transparent'..suffix, default_gui.list_box)
c.scroll_pane_style.parent = 'list_box_scroll_pane-transparent'..suffix
