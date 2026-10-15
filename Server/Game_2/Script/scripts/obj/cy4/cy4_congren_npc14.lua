local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_congren_npc14", base)
npc.script_id = 980098
npc.cfg = {name="Ký Cầm Tư",faction=14,faction_name="Tuyệt Tình Cốc",role="greeter",text="Tuyệt Tình Cốc vốn là nơi cắt đứt tình duyên, ngươi tới đây nên giữ tâm tịnh."}
return npc
