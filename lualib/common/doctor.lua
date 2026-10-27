--의사 선생님

local Doctor = {}

---**EN**
---
---Description: Diagnoses ("diag") or fixes ("fix") the storage of a mod through its gvv interface, writes the report into
---`storage.report` and prints the result to the player.
---
---⚠ Raises an error if the mod doesn't load the gvv interface (message shown to the player). "fix" removes
---entries from the mod storage.
---
---──────────────────────────────
---
---**FR**
---
---Description: Diagnostique (« diag ») ou répare (« fix ») le storage d'un mod par son interface gvv, écrit le rapport dans
---`storage.report` et affiche le résultat au joueur.
---
---⚠ Lève une erreur si le mod ne charge pas l'interface gvv (message affiché au joueur). « fix » supprime
---des entrées du storage du mod.
---@param g table  Player gvv data
---@param mod_name string
---@param action "diag"|"fix"
Doctor.take_a_look = function(g, mod_name, action)
  mod_name = mod_name:gsub('^%s*(.-)%s*$', '%1')..''
  local interface = remote.interfaces['__'..mod_name..'__gvv']
  if not interface then
    error('"__'..mod_name..'__gvv" interface is not found.')
  end
  local func, m
  if action == 'diag' then
    func = interface[action]
    m = {"gvv-mod-helpui.diagnose"}
  elseif action == 'fix' then
    func = interface[action]
    m = {"gvv-mod-helpui.fix"}
  end
  if not func then
    error('function "'..action..'" in remote.interfaces["__'..mod_name..'__gvv"] is not found.')
  end
  local r = remote.call('__'..mod_name..'__gvv',action)
  

  local player = game.get_player(g.index)
  player.print({"",'(gvv) "',mod_name,'" - "',m,'" finished.',
    '\nNormal entries : ',r.n_count,
    '\nError entries : ',r.e_count,
    '\nPotentially problematic entries : ',r.p_count,
    '\nMetatable entries : ',r.m_count,
  },{1,1,0.15,1})
  if not storage.report then storage.report = {} end
  local root, root_name
  if action == 'diag' then
    root_name = '__'..mod_name..'__diagnose'
  elseif action == 'fix' then
    root_name = '__'..mod_name..'__clean_up'
  end
  if not storage.report[root_name] then storage.report[root_name] = {} end
  root = storage.report[root_name]

  local id = #root + 1
  root[id] = {}
  for _, category in ipairs{{r.trouble,'error'}, {r.potential,'problematic'}, {r.meta,'metatables'}} do
    if not root[id][category[2]] then root[id][category[2]] = {} end
    for __,tree_path in pairs(category[1]) do
      local sub_path = root[id][category[2]]
      for ___,name in pairs(tree_path) do
        if not sub_path[name] then sub_path[name] = {} end
        sub_path = sub_path[name]
      end
    end
    if table_size(root[id][category[2]]) == 0 then root[id][category[2]] = nil end
  end
  if table_size(root[id]) ~= 0 then
    player.print({"",'(gvv) report is created at gvv.report.'..root_name..'['..id..']'})
  else
    root[id] = nil
    player.print({"",'(gvv) report is not created because "'..mod_name..'" don\'t have any problems.'})
  end
end

return Doctor
