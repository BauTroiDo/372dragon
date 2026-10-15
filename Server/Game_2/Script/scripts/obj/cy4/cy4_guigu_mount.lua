local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_guigu_mount", base)
npc.script_id = 980017
npc.cfg = {name="Tô Cầm",faction_name="Quỷ Cốc",faction=12,role="mount_manager",mount_shop=412}
return npc
