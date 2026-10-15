local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_taohuadao_travel", base)
npc.script_id = 980010
npc.cfg = {name="Đào Ân",faction_name="Đào Hoa Đảo",faction=13,role="outbound_travel",destination_scene=2,destination_x=253,destination_z=121,min_level=1}
return npc
