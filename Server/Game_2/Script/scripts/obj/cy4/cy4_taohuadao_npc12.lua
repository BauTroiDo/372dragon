local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_taohuadao_npc12", base)
npc.script_id = 980075
npc.cfg = {name="U Lan",faction=13,faction_name="Đào Hoa Đảo",role="greeter",text="Du thuyền quanh đảo hiện chưa mở. Ngươi có thể dạo bộ ngắm hoa đào trên đảo."}
return npc
