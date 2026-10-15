local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_tangmen_npc15", base)
npc.script_id = 980031
npc.cfg = {name="Đệ Tử Đường Môn",faction=11,faction_name="Đường Môn",role="greeter",text="Ta là đệ tử Đường Môn, đang bận luyện công. Sư huynh sư tỷ cần gì cứ hỏi người chỉ đường của bổn phái."}
return npc
