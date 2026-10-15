local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_tangmen_npc05", base)
npc.script_id = 980022
npc.cfg = {name="Đường Xuân",faction=11,faction_name="Đường Môn",role="qinggong_teacher"}
return npc
