local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_taohuadao_npc09", base)
npc.script_id = 980072
npc.cfg = {name="Lâm Hạ Phong",faction=13,faction_name="Đào Hoa Đảo",role="ability_teacher",ability=2,ability_name="Thông Cảm"}
return npc
