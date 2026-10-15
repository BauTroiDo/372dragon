local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_taohuadao_hub", base)
npc.script_id = 980011
npc.cfg = {name="Hoàng Thời Vũ",faction_name="Đào Hoa Đảo",faction=13,role="Dali_inbound_travel",destination_scene=2222,destination_x=252,destination_z=167,min_level=10}
return npc
