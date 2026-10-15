local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_guigu_npc26", base)
npc.script_id = 980058
npc.cfg = {name="Quỷ Cốc Huyền Sĩ",faction=12,faction_name="Quỷ Cốc",role="greeter",text="Huyền sĩ Quỷ Cốc đang quan sát thiên tượng, xin đừng quấy rầy."}
return npc
