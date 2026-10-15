local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_congren_npc06", base)
npc.script_id = 980091
npc.cfg = {name="Mục Vũ",faction=14,faction_name="Tuyệt Tình Cốc",role="title_exchange",text="Ta là Mục Vũ. Việc đổi danh hiệu và vật phẩm bằng cống hiến sư môn sẽ mở cùng lúc với nhiệm vụ sư môn của Tuyệt Tình Cốc. Hiện chưa có gì để đổi.",points={{label="Hỏi về việc học võ",x=231,z=170,tip="Vân Kiêu",desc="Hãy tìm Vân Kiêu để học tâm pháp và bí tịch."},{label="Hỏi về khinh công",x=281,z=170,tip="Lăng Xước",desc="Hãy tìm Lăng Xước để học khinh công."},{label="Hỏi về toạ kỵ",x=115,z=249,tip="Lộ Mạn",desc="Hãy tìm Lộ Mạn để mua toạ kỵ môn phái."}}}
return npc
