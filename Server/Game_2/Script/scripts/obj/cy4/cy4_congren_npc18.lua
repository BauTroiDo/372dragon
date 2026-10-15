local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_congren_npc18", base)
npc.script_id = 980103
npc.cfg = {name="Tông Môn",faction=14,faction_name="Tuyệt Tình Cốc",role="greeter",text="Hệ thống Tông Môn hiện chưa mở tại máy chủ này."}
return npc
