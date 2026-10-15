local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_tangmen_npc21", base)
npc.script_id = 980033
npc.cfg = {name="Tri khách",faction=11,faction_name="Đường Môn",role="guide",sign=500074}
return npc
