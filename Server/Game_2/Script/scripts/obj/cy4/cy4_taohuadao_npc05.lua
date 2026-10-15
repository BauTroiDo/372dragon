local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_taohuadao_npc05", base)
npc.script_id = 980068
npc.cfg = {name="Đào Đào",faction=13,faction_name="Đào Hoa Đảo",role="greeter",text="Phó bản của Đào Hoa Đảo hiện chưa mở tại máy chủ này. Hãy quay lại sau."}
return npc
