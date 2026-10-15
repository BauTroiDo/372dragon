local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_congren_hub", base)
npc.script_id = 980015
npc.cfg = {name="Cảnh Ngôn",faction_name="Tuyệt Tình Cốc",faction=14,role="Dali_inbound_travel",destination_scene=2223,destination_x=244,destination_z=252,min_level=10}
return npc
