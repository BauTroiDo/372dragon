local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_tangmen_npc10", base)
npc.script_id = 980026
npc.cfg = {name="Đường Phi Phi",faction=11,faction_name="Đường Môn",role="guide",sign=500074}
return npc
