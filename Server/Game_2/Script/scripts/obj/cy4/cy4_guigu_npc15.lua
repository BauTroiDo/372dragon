local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_guigu_npc15", base)
npc.script_id = 980047
npc.cfg = {name="Trương Di",faction=12,faction_name="Quỷ Cốc",role="ability_teacher",ability=1,ability_name="Quỷ Cốc Phù Lục"}
return npc
