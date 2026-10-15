local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_taohuadao_npc20", base)
npc.script_id = 980083
npc.cfg = {name="Niếp tiên sinh",faction=13,faction_name="Đào Hoa Đảo",role="greeter",text="Tiên sinh đang đọc sách, xin hãy nhỏ tiếng."}
return npc
