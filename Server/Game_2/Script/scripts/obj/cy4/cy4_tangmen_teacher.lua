local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_tangmen_teacher", base)
npc.script_id = 980001
npc.cfg = {name="Đường Nhạc Xung",faction_name="Đường Môn",faction=11,role="xinfa_teacher"}
return npc
