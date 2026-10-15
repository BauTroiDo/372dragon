local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_tangmen_hub", base)
npc.script_id = 980003
npc.cfg = {name="Đường Dục",faction_name="Đường Môn",faction=11,role="Dali_inbound_travel",destination_scene=2220,destination_x=129,destination_z=71,min_level=10}
return npc
