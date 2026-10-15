local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_congren_npc09", base)
npc.script_id = 980093
npc.cfg = {name="Vu Chỉ",faction=14,faction_name="Tuyệt Tình Cốc",role="ability_teacher",ability=1,ability_name="Thông Nhận Thuật"}
return npc
