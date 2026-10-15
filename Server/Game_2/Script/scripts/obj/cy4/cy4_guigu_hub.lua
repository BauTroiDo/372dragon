local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_guigu_hub", base)
npc.script_id = 980007
npc.cfg = {name="Dương Tiệm",faction_name="Quỷ Cốc",faction=12,role="Dali_inbound_travel",destination_scene=2221,destination_x=86,destination_z=147,min_level=10}
return npc
