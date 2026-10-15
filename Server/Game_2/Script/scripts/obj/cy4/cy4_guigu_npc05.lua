local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_guigu_npc05", base)
npc.script_id = 980038
npc.cfg = {name="Tô Mộc Nhiên",faction=12,faction_name="Quỷ Cốc",role="greeter",text="Nơi luyện tập của Quỷ Cốc hiện chưa mở tại máy chủ này. Khi mở ta sẽ dẫn ngươi vào thử sức."}
return npc
