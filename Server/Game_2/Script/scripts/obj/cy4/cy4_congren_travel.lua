local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_congren_travel", base)
npc.script_id = 980014
npc.cfg = {name="Cẩn Hành",faction_name="Tuyệt Tình Cốc",faction=14,role="outbound_travel",destination_scene=2,destination_x=253,destination_z=121,min_level=1}
return npc
