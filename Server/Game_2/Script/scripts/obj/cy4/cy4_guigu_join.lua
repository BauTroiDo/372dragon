local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_guigu_join", base)
npc.script_id = 980004
npc.cfg = {name="Vương Thiền Nhất",faction_name="Quỷ Cốc",faction=12,role="join"}
return npc
