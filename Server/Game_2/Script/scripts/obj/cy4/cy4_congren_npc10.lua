local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_congren_npc10", base)
npc.script_id = 980094
npc.cfg = {name="Dĩ Hằng",faction=14,faction_name="Tuyệt Tình Cốc",role="ability_teacher",ability=2,ability_name="Phần Tâm"}
return npc
