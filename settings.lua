--설정

local prefix = 'gvv-mod_'

data:extend {
  {
    type = 'string-setting',
    name = 'gvv-mod_preinput_code',
    setting_type = 'runtime-global',
    default_value = '',
    allow_blank = true,
    order = 'a'
  },
  {
    type = 'bool-setting',
    name = 'gvv-mod_on_start',
    setting_type = 'runtime-global',
    default_value = false,
    order = 'b'
  },
  {
    type = 'bool-setting',
    name = prefix..'enable-on-tick',
    setting_type = 'runtime-global',
    default_value = true,
    order = 'c'
  },
}
