local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_congren_npc05", base)
npc.script_id = 980090
npc.cfg = {name="Đan Anh",faction=14,faction_name="Tuyệt Tình Cốc",role="greeter",text="Phó bản của Tuyệt Tình Cốc hiện chưa mở tại máy chủ này. Hãy quay lại sau."}
return npc
