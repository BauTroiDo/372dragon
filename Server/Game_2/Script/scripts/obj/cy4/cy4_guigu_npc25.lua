local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_guigu_npc25", base)
npc.script_id = 980057
npc.cfg = {name="Vương Húc",faction=12,faction_name="Quỷ Cốc",role="greeter",text="Mưu sĩ Quỷ Cốc bàn việc thiên hạ, không rảnh tiếp chuyện người ngoài."}
return npc
