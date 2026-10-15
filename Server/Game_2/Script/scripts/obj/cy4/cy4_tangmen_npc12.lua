local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_tangmen_npc12", base)
npc.script_id = 980028
npc.cfg = {name="Đường Mộ Tường",faction=11,faction_name="Đường Môn",role="greeter",text="Nơi luyện tập của Đường Môn hiện chưa mở tại máy chủ này. Khi mở ta sẽ dẫn ngươi vào thử sức."}
return npc
