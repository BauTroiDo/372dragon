local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_taohuadao_mount", base)
npc.script_id = 980018
npc.cfg = {name="Hoàng Trí Tri",faction_name="Đào Hoa Đảo",faction=13,role="mount_manager",mount_shop=413}
return npc
