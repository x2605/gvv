--설정

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
}
