local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_taohuadao_npc06", base)
npc.script_id = 980069
npc.cfg = {name="Chẩm Mộng Quy",faction=13,faction_name="Đào Hoa Đảo",role="title_exchange",text="Ta là Chẩm Mộng Quy. Việc đổi danh hiệu và vật phẩm bằng cống hiến sư môn sẽ mở cùng lúc với nhiệm vụ sư môn của Đào Hoa Đảo. Hiện chưa có gì để đổi.",points={{label="Hỏi về việc học võ",x=207,z=66,tip="Yến Phản",desc="Hãy tìm Yến Phản để học tâm pháp và bí tịch."},{label="Hỏi về khinh công",x=207,z=78,tip="Tạ Xuân Hàn",desc="Hãy tìm Tạ Xuân Hàn để học khinh công."},{label="Hỏi về toạ kỵ",x=103,z=138,tip="Hoàng Trí Tri",desc="Hãy tìm Hoàng Trí Tri để mua toạ kỵ môn phái."}}}
return npc
