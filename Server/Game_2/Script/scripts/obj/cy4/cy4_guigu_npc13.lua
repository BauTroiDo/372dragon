local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_guigu_npc13", base)
npc.script_id = 980045
npc.cfg = {name="Vương Bàng Nhi",faction=12,faction_name="Quỷ Cốc",role="greeter",text="Ta là đệ tử Quỷ Cốc, đang bận luyện công. Sư huynh sư tỷ cần gì cứ hỏi người chỉ đường của bổn phái."}
return npc
