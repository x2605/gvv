# gvv
 Factorio global Variable Viewer mod.  
 
### Download  
https://mods.factorio.com/mod/gvv
 
### Github
https://github.com/x2605/gvv
 
### How to use  
- Type **/gvv** or press **CTRL+SHIFT+V** (you can change key bindings) to open GUI. Only admins can use the mod if it is multiplay game.  
To allow **gvv** to access **global** table of mod, savefile or scenario(start from beginning), you need to modify "**control.lua**" file of demand mod or map.  
Input following code at first line or last line of "**control.lua**" file of the mod or map.
``` lua

if script.active_mods["gvv"] then require("__gvv__.gvv")() end


```
- In case of savefile, extract "**control.lua**" from it first. Then, edit code and overwrite it at same location of "**control.lua**" inside of the zipped file.  
- There is also a way to make the mod or map accessible temporarily without editing "**control.lua**", introduced in in-game GUI.
- Most of other helpful words are inside of **Helper** tab in **gvv** in-game GUI.  

### 사용 방법
- 모드, 세이브파일, 또는 시나리오(처음부터 시작)의 **global** 테이블에 **gvv**가 액세스할 수 있게 하려면 해당 지도 또는 모드의 "**control.lua**" 파일을 변경해야 합니다.
- 지도 또는 모드의 "**control.lua**" 파일의 첫 줄 또는 마지막 줄에 다음의 코드를 삽입하세요.
``` lua

if script.active_mods["gvv"] then require("__gvv__.gvv")() end


```
- 세이브파일의 경우에는 압축파일에서 "**control.lua**"만 꺼낸 뒤, 편집하고 압축파일 내부의 같은 위치에 "**control.lua**"를 덮어쓰세요.
- "**control.lua**"를 편집하지 않고 임시로 모드나 지도를 액세스 가능하게 만드는 방법이 있습니다. 게임 내 GUI에 소개되어 있습니다.
- 다른 도움말은 게임 내 **gvv** GUI의 **도움 기능** 탭에서 확인할 수 있습니다.

### Commands added by this mod  
- **/gvv** : Opens/closes gvv main GUI window. Only admins or player in singleplay can use this command.  
- **/gmods** : Prints loaded mod list and global accessible mod list.  
- **/gdump** : Same as /gdump-luaon  
- **/gdump-luaon** <mod_name>(optional) : Prints global data of accessible mod in lua object notation format.  
  If no <mod_name> is given, level(current map) will be used.  
- **/gdump-json** <mod_name>(optional) : Prints global data of accessible mod in js object notation format.  
  If no <mod_name> is given, level(current map) will be used.  

### LuaRemote interfaces added by this mod  
- **remote.call("__<mod_name>__gvv","global")** : Returns global table of the mod.  
- **remote.call("__<mod_name>__gvv","diag")** : Need to be used only internally. Performs diagnosis of global table of the mod and returns problematic paths as table.  
- **remote.call("__<mod_name>__gvv","fix")** : Need to be used only internally. Performs diagnosis and kills entries that LuaRemote cannot handle in global table of the mod.  
- **remote.call("__<mod_name>__gvv","c",<lua_code>, ...)** : Runs a lua code(string type) in sandbox of the mod, "..." becomes local table named "arg" in the lua code.  
