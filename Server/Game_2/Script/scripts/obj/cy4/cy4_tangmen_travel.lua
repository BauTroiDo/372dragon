local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_tangmen_travel", base)
npc.script_id = 980002
npc.cfg = {name="Đường Dư Thành",faction_name="Đường Môn",faction=11,role="outbound_travel",destination_scene=2,destination_x=253,destination_z=121,min_level=1}
return npc
