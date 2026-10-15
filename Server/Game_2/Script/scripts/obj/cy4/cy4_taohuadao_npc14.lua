local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_taohuadao_npc14", base)
npc.script_id = 980077
npc.cfg = {name="A Đường",faction=13,faction_name="Đào Hoa Đảo",role="greeter",text="Suối nóng của đảo hiện chưa mở đón khách."}
return npc
