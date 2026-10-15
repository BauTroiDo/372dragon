local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_taohuadao_npc25", base)
npc.script_id = 980087
npc.cfg = {name="Tông Môn",faction=13,faction_name="Đào Hoa Đảo",role="greeter",text="Hệ thống Tông Môn hiện chưa mở tại máy chủ này."}
return npc
