local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_taohuadao_join", base)
npc.script_id = 980008
npc.cfg = {name="Quân Hoàn Châu",faction_name="Đào Hoa Đảo",faction=13,role="join"}
return npc
