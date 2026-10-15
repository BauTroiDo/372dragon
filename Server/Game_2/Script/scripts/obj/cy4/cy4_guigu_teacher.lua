local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_guigu_teacher", base)
npc.script_id = 980005
npc.cfg = {name="Lý Kế Long",faction_name="Quỷ Cốc",faction=12,role="xinfa_teacher"}
return npc
