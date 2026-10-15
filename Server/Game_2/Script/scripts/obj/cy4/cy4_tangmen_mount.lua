local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_tangmen_mount", base)
npc.script_id = 980016
npc.cfg = {name="Đường Tự Cơ",faction_name="Đường Môn",faction=11,role="mount_manager",mount_shop=411}
return npc
