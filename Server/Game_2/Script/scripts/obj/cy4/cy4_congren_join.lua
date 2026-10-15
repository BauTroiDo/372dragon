local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_congren_join", base)
npc.script_id = 980012
npc.cfg = {name="Hành Nghiêm",faction_name="Tuyệt Tình Cốc",faction=14,role="join"}
return npc
