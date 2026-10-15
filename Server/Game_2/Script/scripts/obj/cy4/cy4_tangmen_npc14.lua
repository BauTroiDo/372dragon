local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_tangmen_npc14", base)
npc.script_id = 980030
npc.cfg = {name="Tông Môn",faction=11,faction_name="Đường Môn",role="greeter",text="Hệ thống Tông Môn hiện chưa mở tại máy chủ này."}
return npc
