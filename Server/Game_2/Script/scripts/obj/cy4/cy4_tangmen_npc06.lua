local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_tangmen_npc06", base)
npc.script_id = 980023
npc.cfg = {name="Đường Uyển Hân",faction=11,faction_name="Đường Môn",role="mount_guide",mount_shop=411}
return npc
