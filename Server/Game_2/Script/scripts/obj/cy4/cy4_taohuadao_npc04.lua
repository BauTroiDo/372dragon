local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_taohuadao_npc04", base)
npc.script_id = 980067
npc.cfg = {name="Tiêu Thanh Yết",faction=13,faction_name="Đào Hoa Đảo",role="quest_giver",text="Ta là Tiêu Thanh Yết, phụ trách nhiệm vụ sư môn của Đào Hoa Đảo. Hiện nhiệm vụ sư môn của bổn phái CHƯA mở tại máy chủ này. Trong lúc chờ, ngươi có thể luyện võ, học khinh công, học nghề và sắm toạ kỵ môn phái.",points={{label="Hỏi về việc học võ",x=207,z=66,tip="Yến Phản",desc="Hãy tìm Yến Phản để học tâm pháp và bí tịch."},{label="Hỏi về khinh công",x=207,z=78,tip="Tạ Xuân Hàn",desc="Hãy tìm Tạ Xuân Hàn để học khinh công."},{label="Hỏi về toạ kỵ",x=103,z=138,tip="Hoàng Trí Tri",desc="Hãy tìm Hoàng Trí Tri để mua toạ kỵ môn phái."}}}
return npc
