"""Execute generated formatting with the game's exact Lua 5.0 DLL, not Lua 5.3."""
import ctypes as C
from stage_progression import ROOT,auto_lua
lua=C.CDLL(str(ROOT/'Build/cmake/coord-x64/bin/LuaPlus.dll'))
lua.lua_open.restype=C.c_void_p
lua.lua_close.argtypes=[C.c_void_p]
lua.lua_settop.argtypes=[C.c_void_p,C.c_int]
lua.lua_tostring.argtypes=[C.c_void_p,C.c_int];lua.lua_tostring.restype=C.c_char_p
lua.luaL_loadbuffer.argtypes=[C.c_void_p,C.c_char_p,C.c_size_t,C.c_char_p];lua.luaL_loadbuffer.restype=C.c_int
lua.lua_pcall.argtypes=[C.c_void_p,C.c_int,C.c_int,C.c_int];lua.lua_pcall.restype=C.c_int
for name in ['luaopen_base','luaopen_string']:
 getattr(lua,name).argtypes=[C.c_void_p];getattr(lua,name).restype=C.c_int
state=lua.lua_open();assert state
try:
 lua.luaopen_base(state);lua.luaopen_string(state);lua.lua_settop(state,0)
 src=(ROOT/'Build/world-gui/stage-play-21/Overlay/Post/InterfaceFolder/AutoAttackSkill/AutoAttackSkill.lua').read_text(encoding='utf8')
 generated=auto_lua(src);assert auto_lua(generated)==generated
 prefix=generated[:generated.index('local g_unifiedposistion')]
 code=prefix+'''
assert(CysAutoFormat("#{ZDZD_200724_13}",50)=="Máu dưới 50%")
assert(CysAutoFormat("#{ZDZD_200724_22}",30)=="Máu thú dưới 30%")
local name=CysAutoFormat("#{ZDZD_200724_14}","Hành Quân Đan",3)
assert(name=="Hành Quân Đan (còn lại 3)")
assert(not string.find(name,"#{",1,true))
assert(string.find(CysAutoFormat("#{ZDZD_20220815_21}",200),"200",1,true))
'''
 raw=code.encode();result=lua.luaL_loadbuffer(state,raw,len(raw),b'auto-text-test')
 if result==0:result=lua.lua_pcall(state,0,0,0)
 assert result==0,(lua.lua_tostring(state,-1) or b'').decode('utf8',errors='replace')
 print('PASS native Lua5.0: Vietnamese labels, literal percent, potion name/count, level200 confirmation')
finally:lua.lua_close(state)
