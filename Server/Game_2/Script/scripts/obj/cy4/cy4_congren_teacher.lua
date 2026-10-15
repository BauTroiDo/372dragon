local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_congren_teacher", base)
npc.script_id = 980013
npc.cfg = {name="Vân Kiêu",faction_name="Tuyệt Tình Cốc",faction=14,role="xinfa_teacher"}
return npc
