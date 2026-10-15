local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_taohuadao_npc08", base)
npc.script_id = 980071
npc.cfg = {name="Túc Hồi Chi",faction=13,faction_name="Đào Hoa Đảo",role="ability_teacher",ability=1,ability_name="Cách Vật Chi Thuật"}
return npc
