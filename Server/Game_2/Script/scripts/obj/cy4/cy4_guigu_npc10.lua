local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_guigu_npc10", base)
npc.script_id = 980043
npc.cfg = {name="Trận Linh Thạch · Nhân",faction=12,faction_name="Quỷ Cốc",role="formation_stone",text="Đây là Trận Linh Thạch · Nhân của Quỷ Cốc. Ba trận linh thạch Thiên · Địa · Nhân nối với nhau, đệ tử cấp 10 trở lên có thể mượn trận mà dịch chuyển.",stones={{label="Trận Linh Thạch · Thiên",x=39,z=43},{label="Trận Linh Thạch · Địa",x=95,z=141}}}
return npc
