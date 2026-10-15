local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_taohuadao_npc17", base)
npc.script_id = 980080
npc.cfg = {name="Đào Khê",faction=13,faction_name="Đào Hoa Đảo",role="greeter",text="Đào Hoa Đảo cách biệt trần thế, ngươi tới đây hẳn là có duyên."}
return npc
