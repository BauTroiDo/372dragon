local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_guigu_npc07", base)
npc.script_id = 980040
npc.cfg = {name="Công Tôn Na",faction=12,faction_name="Quỷ Cốc",role="greeter",text="Nơi đây là trọng địa của Quỷ Cốc, xin đừng gây ồn ào. Cần gì hãy hỏi người chỉ đường."}
return npc
