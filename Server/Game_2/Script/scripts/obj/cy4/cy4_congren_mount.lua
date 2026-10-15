local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_congren_mount", base)
npc.script_id = 980019
npc.cfg = {name="Lộ Mạn",faction_name="Tuyệt Tình Cốc",faction=14,role="mount_manager",mount_shop=414}
return npc
