local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_tangmen_npc04", base)
npc.script_id = 980021
npc.cfg = {name="Lão Lão Đường Môn",faction=11,faction_name="Đường Môn",role="ability_teacher",ability=1,ability_name="Biên Nạp Thuật"}
return npc
