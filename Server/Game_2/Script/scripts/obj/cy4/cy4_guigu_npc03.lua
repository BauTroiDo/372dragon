local class = require "class"
local base = require "scripts.obj.cy4.cy4_npc"
local npc = class("cy4_guigu_npc03", base)
npc.script_id = 980036
npc.cfg = {name="Vũ Hủ Chi",faction=12,faction_name="Quỷ Cốc",role="head",text="Ta là Vũ Hủ Chi, chưởng môn Quỷ Cốc. Bổn phái mới mở cửa thu nhận đệ tử; các sư đệ sư muội cứ chuyên tâm luyện võ, học khinh công và nghề nghiệp của bổn phái. Nhiệm vụ sư môn và cống hiến sẽ được mở sau.",points={{label="Hỏi về việc học võ",x=92,z=55,tip="Lý Kế Long",desc="Hãy tìm Lý Kế Long để học tâm pháp và bí tịch."},{label="Hỏi về khinh công",x=106,z=56,tip="Ngô Bành",desc="Hãy tìm Ngô Bành để học khinh công."},{label="Hỏi về toạ kỵ",x=150,z=150,tip="Tô Cầm",desc="Hãy tìm Tô Cầm để mua toạ kỵ môn phái."}}}
return npc
