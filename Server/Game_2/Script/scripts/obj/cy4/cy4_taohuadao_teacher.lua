local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_taohuadao_teacher", base)
npc.script_id = 980009
npc.cfg = {name="Yến Phản",faction_name="Đào Hoa Đảo",faction=13,role="xinfa_teacher"}
return npc
