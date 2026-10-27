-- 그래픽 유저 인터페이스


local Gui = {}


-- 메인 윈도우
-- FR : Fenêtre principale : maintenant construite par classes/GvvGuiMain.lua (étape 3.1).
--      Gui.open_main et Gui.close_main restent comme points d'entrée pour l'ancien code (/gvv, migrations).
-- EN : Main window: now built by classes/GvvGuiMain.lua (step 3.1).
--      Gui.open_main and Gui.close_main stay as entry points for the old code (/gvv, migrations).
Gui.open_main = function(player_index)
  GvvGuiMain({player_index = player_index}):toggle()
end

-- 메인 윈도우 닫기
Gui.close_main = function(g, ignore_save)
  GvvGuiMain({player_index = g.index}):close(ignore_save)
end

-- FR : Outils et onglets des arbres (storage, property, LuaObject) : construits par classes/GvvGuiTree.lua (étape 3.6)
-- EN : Trees tools and tabs (storage, property, LuaObject): built by classes/GvvGuiTree.lua (step 3.6)

-- 내용을 복사할 수 있는 미니 윈도우1
-- FR : Petites fenêtres : maintenant construites par classes/GvvGuiDialog.lua (étape 3.2).
--      Ces fonctions restent comme points d'entrée pour l'ancien code (/gdump, onglet suivi).
-- EN : Small windows: now built by classes/GvvGuiDialog.lua (step 3.2).
--      These functions stay as entry points for the old code (/gdump, tracking tab).
Gui.copyable_dump = function(player_index, str, title)
  GvvGuiDialog({player_index = player_index}):openDump(str, title)
end

-- 코드를 입력하는 미니 윈도우
Gui.put_anycode_in_tracking = function(g)
  return GvvGuiDialog({player_index = g.index}):openAnycode()
end

-- 내용을 복사할 수 있는 미니 윈도우2
Gui.copyable_tracking_code = function(g, str, entry_name)
  GvvGuiDialog({player_index = g.index}):openCopy(str, entry_name)
end

-- 코드를 편집하는 미니 윈도우
Gui.edit_code_in_tracking = function(g, str, entry_name)
  return GvvGuiDialog({player_index = g.index}):openEdit(str, entry_name)
end

--내보내기 윈도우
Gui.export_window = function(g)
  GvvGuiDialog({player_index = g.index}):openExport()
end

--가져오기 윈도우
Gui.import_window = function(g)
  GvvGuiDialog({player_index = g.index}):openImport()
end

return Gui
