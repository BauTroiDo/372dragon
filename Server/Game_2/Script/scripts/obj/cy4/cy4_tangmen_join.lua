local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_tangmen_join", base)
npc.script_id = 980000
npc.cfg = {name="Đường Diệc Phong",faction_name="Đường Môn",faction=11,role="join"}
return npc
