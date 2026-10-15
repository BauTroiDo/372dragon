local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_guigu_travel", base)
npc.script_id = 980006
npc.cfg = {name="Cửu Nhật Thông",faction_name="Quỷ Cốc",faction=12,role="outbound_travel",destination_scene=2,destination_x=253,destination_z=121,min_level=1}
return npc
