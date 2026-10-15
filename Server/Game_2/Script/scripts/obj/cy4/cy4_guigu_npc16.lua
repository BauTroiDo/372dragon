local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_guigu_npc16", base)
npc.script_id = 980048
npc.cfg = {name="Tiểu Tiên Nhi",faction=12,faction_name="Quỷ Cốc",role="ability_teacher",ability=2,ability_name="Linh Ngọc Thuật"}
return npc
