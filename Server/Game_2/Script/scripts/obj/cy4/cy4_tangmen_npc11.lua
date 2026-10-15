local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_tangmen_npc11", base)
npc.script_id = 980027
npc.cfg = {name="Đường Thái",faction=11,faction_name="Đường Môn",role="greeter",text="Nơi đây là trọng địa của Đường Môn, xin đừng gây ồn ào. Cần gì hãy hỏi người chỉ đường."}
return npc
