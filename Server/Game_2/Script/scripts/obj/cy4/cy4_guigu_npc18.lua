local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_guigu_npc18", base)
npc.script_id = 980050
npc.cfg = {name="Giang hồ đạo tặc",faction=12,faction_name="Quỷ Cốc",role="greeter",text="Hừ! Bọn ta chỉ tạm dừng chân ở đây, đừng dây vào bọn ta!"}
return npc
