local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_taohuadao_npc16", base)
npc.script_id = 980079
npc.cfg = {name="Lan Đình Sinh",faction=13,faction_name="Đào Hoa Đảo",role="greeter",text="Ta ghi chép chuyện của đảo. Ngươi có chuyện gì đáng ghi vào sử sách không?"}
return npc
