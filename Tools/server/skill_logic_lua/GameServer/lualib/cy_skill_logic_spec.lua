-- skill-logic (CY-Source 16/09/2026): bảng nghĩa cho các 技能逻辑ID của CY chưa cài trong skillenginer.
--
-- NGUỒN của từng dòng (cột `src`):
--   native  = mã CY thật (tlbb15 Server / Serverhook.so), có địa chỉ ghi trong `note`;
--   label   = nhãn 参数说明 của chính SkillData CY (bảng CY, không phải đoán từ tên logic) + tip kỹ năng CY;
--   partial = làm được phần chính theo nhãn/tip, phần còn lại cần cơ chế native (ghi rõ trong `note`).
-- KHÔNG có dòng nào suy ra chỉ từ tên logic. Logic thiếu trong bảng này = chưa cài, lý do ở
-- Docs/specs/server/skill-logic_vi.md mục 3.
--
-- Cú pháp một dòng (mọi trường đều tuỳ chọn):
--   impacts   = { {label=<nhãn 参数说明>, to='self'|'target'|'doll', chance=<nhãn % hoặc số>, all=true}, ... }
--                 -- to='doll': gửi cho CHÍNH con rối 离人偶; không có rối thì về bản thân (skill-logic-3 17/09)
--                 -- all=true : nhãn xuất hiện NHIỀU lần trong một dòng (799) → áp mọi giá trị, không chỉ ô đầu
--   self_idx  = { N, ... }   -- ô |生效一次的附加效果N chuyển sang BẢN THÂN (skill_0 mặc định gửi cho mục tiêu)
--   tick_self_idx = { N }    -- như trên cho |引导周期的附加效果N
--   aoe       = { {label=..., around='self'|'target'|'doll', count=<nhãn|số>, radius=<nhãn|số>, side='enemy'|'ally',
--                  rate_add=<nhãn>}, ... }      -- rate_add: hệ số sát thương = 100 + giá trị ô (799)
--   trap      = { {label=..., at='self'|'target'|'dest'|'doll', per_target=true, max=<số>,
--                  chance_ladder={<nhãn %1>,<nhãn %2>,...}}, ... }
--                 -- per_target: đặt bẫy cho TỪNG mục tiêu trúng (mặc định chỉ mục tiêu đầu)
--                 -- chance_ladder + max: lần đặt thứ k dùng mức xác suất thứ k, tối đa `max` lần mỗi lượt (736)
--   gender    = { male=<nhãn>, female=<nhãn> }
--   cooldown_reduce   = { id=<nhãn>, ms=<nhãn> }            -- giảm hồi chiêu theo 冷却ID
--   cooldown_on_crit  = { min=<nhãn>, max=<nhãn> }          -- hội tâm thì giảm ngẫu nhiên min..max (giây)
--   souls     = { base=<nhãn impact>, sets={<nhãn tập 1>,...}, mult={<nhãn %1>,<nhãn %2>,<nhãn %3>},
--                 per_set={ {set=<nhãn tập>, label=<nhãn impact>} , ...}, min_sets=<số> }
--   teleport  = { label=<nhãn impact thuấn di>, to='doll'|'target'|'dest' }
--   consume   = { <nhãn>, ... }   -- nhãn impact KHÔNG được lớp generic áp thêm (đã xử lý ở trên, hoặc CY không dùng ở đây)
--   summon    = { { id=<nhãn|số monster>, ids={<nhãn>,...} (chọn ngẫu nhiên 1),
--                   hp=<nhãn|số>, hps={<nhãn>,...} (cùng chỉ số với ids),
--                   at='self'|'target'|'dest'|'doll', life=<ms>, delay=<ms tới nhịp đầu>,
--                   unbreakable=true, self_impact=<nhãn impact áp lên chính thực thể>, name='...',
--                   attack={ scale=<%|{%,...} đòn ĐÁNH THƯỜNG của chủ>, radius=, count=,
--                            around='summon'|'owner', interval=<ms>, heal_owner=<%> } }, ... }
--                 -- skill-summon 17/09: chạy MỘT LẦN mỗi lần tung (activate_once), xem lualib/cy_skill_summon.lua
--   multi_hit = { label=<nhãn impact>, count=<số đòn>, radius=<nhãn|số>, around='target'|'self',
--                 side='enemy'|'ally', include_center=true, decay=<nhãn % giảm dần> }
--                 -- nhiều đòn trong MỘT lần tung, mỗi đòn chọn ngẫu nhiên một mục tiêu quanh tâm;
--                 -- `decay`: lần trúng thứ n của CÙNG một mục tiêu chịu hệ số 100 × (1−decay/100)^(n−1) (204)
--   lifesteal = { pct=<nhãn % máu hút>, tick=true }
--                 -- hút máu theo SÁT THƯƠNG THỰC: đo chênh lệch HP của mục tiêu sau 延迟时间 (149)
--   chain     = { ladder={<nhãn nấc 1>,...}, max_links=<số nối thêm>, break_main=<nhãn m>,
--                 break_other=<nhãn m>, link_main=<nhãn impact>, link_other=<nhãn impact>, max_ticks=<số> }
--                 -- chuỗi lan theo NHỊP DẪN của chính engine (769); xem lualib/cy_skill_chain.lua
--   state     = { key=<nhãn ô khoá>, map={[giá trị ô]=<DataIndex trạng thái>} }
--                 -- phát một dòng StandardImpact trạng thái mà dữ liệu SkillData không trỏ tới (144)
--   seed      = { first=<DataIndex mầm ở cấp 1>, tiers=<số mức của dải, mặc định 12> }
--                 -- skill-logic-4 17/09 (761–765 星阵 鬼谷): gửi cho CHÍNH người tung một impact "mầm"
--                 -- (逻辑ID 8090, 脚本ID 808253, 总持续时间 1 ms). Khi mầm tắt, native logic 90 của
--                 -- cy_four_combat dựng đúng MỘT 星阵. Chỉ số ô = cấp tâm pháp, KẸP về `tiers`.
--
return {

-- ============================ 少林/明教/丐帮/武当/峨嵋/星宿/大理/天山/逍遥 ============================

-- 第八心法 (15 phái): |给目标的基础效果1/2 lên mục tiêu; hai ô 下限/上限百分比 là biên của hệ số
-- theo chênh lệch điểm 心法+修炼 (tip CY). Chưa có công thức chênh lệch → gửi impact ở 100 %, KHÔNG nhân biên.
[643] = {src = 'label', note = '第八心法 công (玄印悟佛…15 phái). |给目标的基础效果N → mục tiêu. Biên 下限/上限百分比 chưa áp (thiếu công thức điểm CY).',
         impacts = {{label = '|给目标的基础效果1', to = 'target'}, {label = '|给目标的基础效果2', to = 'target'}}},
[644] = {src = 'label', note = '第八心法 khống chế (慈心悲悯…15 phái). Như 643.',
         impacts = {{label = '|给目标的基础效果1', to = 'target'}, {label = '|给目标的基础效果2', to = 'target'}}},

-- 武当 仙风道骨: 目标逻辑 0 (bản thân); |控制受限idc là TẬP khống chế không gỡ được → không phải impact.
[111] = {src = 'label', note = '仙风道骨 (武当): impact tự thân qua ô |生效一次的附加效果N. |控制受限idc = tập ID, bỏ.',
         consume = {'|控制受限idc'}},

-- 峨嵋 ------------------------------------------------------------------------------------------
[142] = {src = 'label', note = '春花秋月 (峨嵋): mục tiêu chính + 1 mục tiêu phụ gần nhất trong 7 m (tip). Đồng đội → trị liệu, địch → sát thương.',
         impacts = {{label = '|主目标治疗', to = 'target'}, {label = '|主目标伤害', to = 'target'}},
         aoe = {{label = '|次目标治疗', around = 'target', count = 1, radius = 7, side = 'ally'},
                {label = '|次目标伤害', around = 'target', count = 1, radius = 7, side = 'enemy'}},
         consume = {'|治疗连线', '|伤害连线'}},
[143] = {src = 'label', note = '延年益寿 (峨嵋): khiên cho mục tiêu + dấu mệt mỏi (20 s không nhận lại) lên chính mục tiêu.',
         impacts = {{label = '|护盾buff', to = 'target'}, {label = '|疲劳buff', to = 'target'}}},
[144] = {src = 'partial', note = '回天术 (峨嵋 411) / 斩情诀 (峨嵋 417): |效果N lên đồng đội quanh mình (6 người, 7 m) + ' ..
                                 '|变身buff lên bản thân. skill-logic-3 17/09 — bốn ô |替换一段技能idN: ' ..
                                 'KHÔNG cần đổi danh sách kỹ năng. Bằng chứng: (a) 827/828/829/830 (·九阳) và ' ..
                                 '831/832/833/834 (·九阴) có CÙNG 心法ID và 技能类型按使用者划分 = 0 với bản gốc ' ..
                                 '411/424/426/406 và 417/404/415/421, mà human:on_study_xinfa (obj/human.lua:2277) cấp ' ..
                                 'MỌI template có cùng 心法ID ⇒ người chơi ĐÃ có sẵn các chiêu ·九阳/·九阴; ' ..
                                 '(b) SkillData của chúng có điều kiện C_UNIT_MUST_HAVE_IMPACT (kiểu 0) trỏ tập ' ..
                                 '499 回天术九阳状态 = {互斥ID 2631} / 376 斩情诀BUFF = {互斥ID 151} ⇒ chỉ dùng được khi ' ..
                                 'đang mang trạng thái. Thiếu duy nhất TRẠNG THÁI: 13058 九阳炽脉 (20 s, 互斥 2631) và ' ..
                                 '13059 九阴煞魄 (20 s, 互斥 151) KHÔNG được dòng SkillData nào trỏ tới (0/20.667 dòng) ⇒ ' ..
                                 'do chính logic 144 phát. Khối `state` dưới đây phát đúng hai dòng đó, hết 20 s tự rụng ' ..
                                 '(không đụng human.skill_list nên không có rủi ro lưu nhầm khi thoát game giữa chừng). ' ..
                                 'Cần logic impact 171 (impact_logic/std_impact_171.lua, lượt này thêm) mới lên được. ' ..
                                 'Chưa làm: đổi biểu tượng trên thanh nhanh là việc của client (nó tự đọc |替换一段技能idN).',
         impacts = {{label = '|变身buff', to = 'self'}, {label = '|给自己的效果', to = 'self'}},
         -- khoá = ô |替换一段技能id1 (chiêu gốc của chính nhánh: 411 回天术 → 九阳, 417 斩情诀 → 九阴)
         state = {key = '|替换一段技能id1', map = {[411] = 13058, [417] = 13059}},
         aoe = {{label = '|效果1', around = 'self', count = 6, radius = 7, side = 'ally'},
                {label = '|效果2', around = 'self', count = 6, radius = 7, side = 'ally'},
                {label = '|效果3', around = 'self', count = 6, radius = 7, side = 'ally'}},
         consume = {'|替换一段技能id1', '|替换一段技能id2', '|替换一段技能id3', '|替换一段技能id4',
                    '|给自己的效果（命中几次给几次）'}},
[145] = {src = 'label', note = '回天术·九阳 (峨嵋): trị liệu mục tiêu + dấu mệt mỏi.',
         impacts = {{label = '|基础治疗buff', to = 'target'}, {label = '|疲劳buff', to = 'target'}}},
[146] = {src = 'label', note = '春花秋月·九阳 (峨嵋): mục tiêu chính + 2 đồng đội gần nhất 7 m (tip).',
         impacts = {{label = '|主目标治疗', to = 'target'}},
         aoe = {{label = '|次目标治疗', around = 'target', count = 1, radius = 7, side = 'ally'},
                {label = '|三目标治疗', around = 'target', count = 1, radius = 7, side = 'ally'}},
         consume = {'|治疗连线'}},
[147] = {src = 'label', note = '佛光普照 (峨嵋): trị liệu 6 đồng đội trong 7 m quanh bản thân (tip) + buff tự thân khi trị đồng đội.',
         impacts = {{label = '|治疗队友时为自身治疗buf', to = 'self'}},
         aoe = {{label = '|基础治疗buff', around = 'self', count = 6, radius = 7, side = 'ally'}}},
[148] = {src = 'label', note = '斩情诀·九阴 (峨嵋): 目标逻辑 0 → |效果1/2 lên bản thân; |效果2 theo xác suất.',
         impacts = {{label = '|效果1', to = 'self'}, {label = '|效果2', to = 'self', chance = '|效果2的发生几率'}}},
[149] = {src = 'label', note = '金顶绵掌·九阴 (峨嵋 832): ô 1 = sát thương mục tiêu, ô 2 = trạng thái của bản thân. ' ..
                              'skill-logic-3 17/09: |回血百分比 (tip "为自身回复造成伤害一半的血量") NAY đã áp — ' ..
                              'engine Lua đăng ký impact qua skynet.fork nên không có số sát thương tại chỗ, ' ..
                              'nên đo bằng CHÊNH LỆCH HP của mục tiêu sau 延迟时间 + 400 ms (đúng cách ' ..
                              'cy_skill_summon.normal_attack đo cho 886). Chiêu là 引导 1.000 ms ' ..
                              '(SkillTemplate 832 连续攻击次数或引导的时间间隔 = 1000 = "mỗi giây một đòn" của tip) ' ..
                              'nên mỗi nhịp hút một lần. [SL] phần máu mất trong cửa sổ đo có thể lẫn sát thương ' ..
                              'của người khác lên cùng mục tiêu.',
         self_idx = {2}, tick_self_idx = {2},
         lifesteal = {pct = '|回血百分比', tick = true}},
[886] = {src = 'partial', note = '狂猿凌峰 (峨嵋, template 407, cấp kỹ năng 4). Dòng SkillData 17621 KHÔNG có ô tham số nào — ' ..
                                 'mọi số lấy từ tip CY. skill-summon 17/09: triệu hồi 蜀山狂猿 (MonsterAttrEx 1499; 友好值 = 0 nên ' ..
                                 'engine coi nó trung lập hai chiều, không ai đánh được — đúng "狂猿无法被攻击"; thêm cờ ' ..
                                 'unbreakable cho chắc), sống 15 s, mỗi 1,2 s (= 攻击动作时间 của chính dòng 1499) đánh 1 mục tiêu ' ..
                                 'ĐỊCH CỦA CHỦ trong 15 m quanh CHỦ, sát thương = 20 % đòn ĐÁNH THƯỜNG của chủ ' ..
                                 '(tip: "具有召唤者20%四种属性攻击"), và toàn bộ sát thương gây ra hồi máu cho chủ ' ..
                                 '("狂猿造成的伤害会对召唤者产生治疗效果"). ' ..
                                 'Chưa làm: 100 % 四种减抗 + 20 % 穿刺 (CY trộn thuộc tính người triệu hồi vào chính con quái, ' ..
                                 'bản port ghi sát thương thẳng cho chủ nên không có chỗ đặt hai ô này).',
         summon = {{id = 1499, at = 'self', life = 15000, unbreakable = true, name = 'Thục Sơn Cuồng Viên',
                    attack = {scale = 20, radius = 15, count = 1, around = 'owner',
                              interval = 1200, heal_owner = 100}}}},

-- 星宿 ------------------------------------------------------------------------------------------
[170] = {src = 'label', note = '神蝎百相 (星宿): biến thân theo giới tính + buff miễn khống.',
         gender = {male = '变身男buff', female = '变身女buff'},
         impacts = {{label = '免控buff', to = 'self'}}},
[171] = {src = 'label', note = '毒螯势 (星宿): 中毒buff theo 中毒几率% lên mục tiêu (加毒攻% là hệ số sát thương, không phải impact).',
         impacts = {{label = '中毒buff', to = 'target', chance = '中毒几率%'}}, consume = {'加毒攻%'}},
[172] = {src = 'label', note = '心如毒蝎 (星宿): AOE quanh bản thân (目标逻辑 4) — 伤害buff qua skill_0; 封穴buff theo 封穴几率%.',
         impacts = {{label = '封穴buff', to = 'target', chance = '封穴几率%'}}},
[173] = {src = 'label', note = '蝎行无阻 (星宿): bẫy tại chỗ + biến thân theo giới tính + miễn khống.',
         trap = {{label = '陷阱id', at = 'self'}},
         gender = {male = '变身男buff', female = '变身女buff'},
         impacts = {{label = '免控buff', to = 'self'}}},
[174] = {src = 'partial', note = '毒蟾功 (星宿, template 435): 失明buff lên mục tiêu; ô 召唤物 (16944 毒蟾·1级) nay được ' ..
                                 'TRIỆU HỒI thật (skill-summon 17/09) — nhảy tới mục tiêu, mỗi giây gây 50 % đòn đánh thường ' ..
                                 'của chủ cho tối đa 6 địch trong 5 m (số lấy từ tip CY), 9 giây = 3 lượt mục tiêu × 3 s. ' ..
                                 'Chưa làm: đổi mục tiêu + tiến hoá 2 lần (cần dời thực thể và đổi model 16944→16945/16946).',
         impacts = {{label = '失明buff', to = 'target'}},
         summon = {{id = '召唤物', at = 'target', life = 9000, name = 'Độc Thiềm',
                    attack = {scale = 50, radius = 5, count = 6, around = 'summon', interval = 1000}}}},
[175] = {src = 'label', note = '饮鸩止渴 (星宿): 效果1 lên mục tiêu (bản thân/đồng đội) + 疲劳buff chống dùng lại.',
         impacts = {{label = '效果1', to = 'target'}, {label = '疲劳buff', to = 'target'}}},
[176] = {src = 'partial', note = '五毒聚鼎 (星宿): 12 ô 炼化* là bậc luyện hoá của 4 con五毒 — cần bộ đếm tiến hoá. ' ..
                                 'Chỉ áp bậc 1 của từng con lên bản thân theo nhãn.',
         impacts = {{label = '炼化蝎子1', to = 'self'}, {label = '炼化蛤蟆1', to = 'self'},
                    {label = '炼化巨蟒1', to = 'self'}, {label = '炼化冰蚕1', to = 'self'}},
         consume = {'炼化蝎子2', '炼化蝎子3', '炼化蛤蟆2', '炼化蛤蟆3', '炼化巨蟒2', '炼化巨蟒3',
                    '炼化冰蚕2', '炼化冰蚕3', '炼化冰蚕回复1', '炼化冰蚕回复2', '炼化冰蚕回复3'}},
[177] = {src = 'label', note = '青蛇毒掌 (星宿): 攻击效果 lên mục tiêu + 巨蟒buff theo 召唤概率%.',
         impacts = {{label = '攻击效果', to = 'target'}, {label = '巨蟒buff', to = 'target', chance = '召唤概率%'}}},
[178] = {src = 'label', note = '圣蚕护身 (星宿): 冰蚕buff lên bản thân (目标逻辑 0).',
         impacts = {{label = '冰蚕buff', to = 'self'}}},
[179] = {src = 'partial', note = '化骨绵掌 (星宿): 攻击效果 lên mục tiêu. Phần khoá khí + ép hồi chiêu 3 s ' ..
                                 '(锁定下限/上限%, 触发冷却%, 触发冷却气量, 冷却时间) chưa làm — cần khoá MP theo CY.',
         impacts = {{label = '攻击效果', to = 'target'}},
         consume = {'锁定下限%', '锁定上限%', '触发冷却%', '触发冷却气量', '冷却时间'}},

-- 大理 ------------------------------------------------------------------------------------------
[202] = {src = 'label', note = '三阳开泰 (大理): mỗi nhịp dẫn đặt bẫy 引导周期释放陷阱 trên đường.',
         trap = {{label = '引导周期释放陷阱', at = 'self', tick = true}}},
[204] = {src = 'partial', note = '少商剑·刃影 (大理 821). skill-logic-3 17/09: tip của CẢ 16 dòng SkillData ' ..
                                 '(17328–17343) đều ghi "发射6把飞剑，每把飞剑随机对目标周围5米内的一名敌对目标造成伤害， ' ..
                                 '同一目标重复受到攻击时伤害逐次递减15%" ⇒ 6 đòn, mỗi đòn chọn NGẪU NHIÊN một địch trong ' ..
                                 '5 m quanh mục tiêu; ô 衰减系数百分比 (=15 ở cả 16 dòng) là hệ số giảm dần theo SỐ LẦN ' ..
                                 'trúng của TỪNG mục tiêu trong một lượt. [SL] "衰减系数" hiểu là nhân dồn: ' ..
                                 'lần thứ n = 100 × 0,85^(n−1) (không phải trừ thẳng 15 điểm), không có mã CY để đối chiếu. ' ..
                                 'Chưa làm: 驱散二式buff集合 (gỡ tập buff 二式) — cần API gỡ theo tập.',
         multi_hit = {label = '附加伤害（逻辑3）', count = 6, radius = 5, around = 'target', side = 'enemy',
                      include_center = true, decay = '衰减系数百分比'},
         consume = {'驱散二式buff集合'}},
[205] = {src = 'partial', note = '六脉神剑 (大理): 附加效果1 + 附加效果2 theo 附加效果2的概率; 激活二式buff lên bản thân theo ' ..
                                 '二式激活概率百分比, thời lượng 二式激活时长ms. 截拳式集合 là tập kỹ năng — bỏ.',
         impacts = {{label = '附加效果1', to = 'target'},
                    {label = '附加效果2', to = 'target', chance = '附加效果2的概率'},
                    {label = '激活二式buff', to = 'self', chance = '二式激活概率百分比', duration = '二式激活时长ms'}},
         consume = {'截拳式集合'}},
[206] = {src = 'partial', note = '刃影 (大理): 附加效果1 + 附加效果2 theo xác suất + 给自己的buff. 驱散二式buff集合/受控集合 là tập ID.',
         impacts = {{label = '附加效果1', to = 'target'},
                    {label = '附加效果2', to = 'target', chance = '附加效果2的概率'},
                    {label = '给自己的buff', to = 'self'}},
         consume = {'驱散二式buff集合', '受控集合'}},
[208] = {src = 'partial', note = '中冲剑·刃影 (大理 826). Tip: "命中后，目标每有一种抗性不高于自身对应减抗，则对目标' ..
                                 '释放一次对应属性的六脉神剑技能". SkillData chỉ có 驱散二式buff集合 (= 495) ⇒ mọi số ' ..
                                 'phải lấy từ NƠI KHÁC. skill-logic-5 17/09 tra xong CẢ HAI dữ kiện mà skill-logic-4 ' ..
                                 'còn thiếu, không đoán một số nào: ' ..
                                 '(a) ÁNH XẠ HỆ → CHIÊU đọc thẳng từ ô 参数N说明 của dòng StandardImpact mà chính chiêu ' ..
                                 'đó dùng (ô 附加效果1 của SkillData): 56834 少商剑 = 火系攻击 (463), 56899 关冲剑 = ' ..
                                 '冰系攻击 (471), 56963 少泽剑 = 电系攻击 (481), 57075 商阳剑 = 毒系攻击 (487). ' ..
                                 'Hai chiêu còn lại KHÔNG có hệ: 1987 少冲剑 = 逻辑ID 5 「MP修改百分率」 (đốt khí), ' ..
                                 '57139 中冲剑 = 逻辑ID 38 (tám ô 效果N, chính là chiêu mẹ). ' ..
                                 '(b) "抗性" và "自身对应减抗" là THUỘC TÍNH của engine chứ không phải ô bảng: ' ..
                                 'combat_core.lua:338-530 tính sát thương 4 hệ bằng ĐÚNG cặp ' ..
                                 'defencer:get_defence_X() − attacker:get_reduce_def_X(); và server CHỈ có bốn ' ..
                                 'get_reduce_def_* (cold/fire/light/posion) trong khi có sáu get_defence_* — nghĩa là ' ..
                                 '"减抗" chỉ tồn tại cho đúng 4 hệ 冰/火/电(玄)/毒 ⇒ ánh xạ là 4↔4, không phải 6↔6. ' ..
                                 'Cách phát: KHÔNG dùng skill_exec_from_script — với người chơi nó là VÔ HIỆU ' ..
                                 '(ai/states/base.lua:87 trả OR_OK ngay khi obj_type == "human") và còn để lại cờ ' ..
                                 'ignore_condition_check trên params. Cũng không dùng do_use_skill (mỗi lần tốn ' ..
                                 '396–558 khí + hồi chiêu 30–90 s của chính chiêu con, ×4 hệ). [SL] Bản port gửi ' ..
                                 'thẳng ô 附加效果1 của chiêu con ở CÙNG CẤP — đúng thứ mà chiêu con gây ra khi trúng, ' ..
                                 'không đi lại vòng động tác. Chưa làm: 驱散二式buff集合 (cùng nợ với 204/206).',
         resist_cast = {impact_label = '附加效果1',
                        by_elem = {{elem = '冰', defence = 'get_defence_cold',   reduce = 'get_reduce_def_cold',   skill = 471},
                                   {elem = '火', defence = 'get_defence_fire',   reduce = 'get_reduce_def_fire',   skill = 463},
                                   {elem = '电', defence = 'get_defence_light',  reduce = 'get_reduce_def_light',  skill = 481},
                                   {elem = '毒', defence = 'get_defence_posion', reduce = 'get_reduce_def_posion', skill = 487}}},
         consume = {'驱散二式buff集合'}},

-- 逍遥 ------------------------------------------------------------------------------------------
[262] = {src = 'partial', note = '江行初雪 (逍遥): 引爆伤害 lên các mục tiêu AOE (目标逻辑 4). Điều kiện "mang trạng thái 灼烧" ' ..
                                 '(tập 引爆效果集合) chưa lọc.',
         impacts = {{label = '引爆伤害', to = 'target'}}, consume = {'引爆效果集合'}},

-- 慕容 ------------------------------------------------------------------------------------------
[672] = {src = 'partial', note = '凌神式 (慕容): 攻击效果 lên mục tiêu. Bản CY KHÔNG có ô impact thuấn di (chỉ có ' ..
                                 '传送到目标范围 = khoảng cách và 消失前特效图腾id) → phần nhảy tới mục tiêu chưa làm.',
         impacts = {{label = '攻击效果', to = 'target'}},
         consume = {'消失前特效图腾id', '传送到目标范围'}},
[802] = {src = 'label', note = '劝君酒 (慕容 bản kéo): |生效一次的附加效果1 lên mục tiêu (skill_0 lo).'},

-- 唐门 ------------------------------------------------------------------------------------------
[730] = {src = 'partial', note = '诸葛神弩 (唐门, template 4468). skill-summon 17/09: dựng thật 图腾id (16935 诸葛神弩) ' ..
                                 'tại vị trí client chỉ định, máu = 图腾血量 (9000), 无敌效果id (37922) áp lên CHÍNH tháp ' ..
                                 '(tip: "初始3秒无敌" — chủ thể vô địch là cái nỏ, không phải người chơi), sống 15 s, ' ..
                                 'mỗi 0,4 s bắn 1 địch trong 15 m với 25 % đòn ĐÁNH THƯỜNG của chủ (đường std_impact_115). ' ..
                                 'Chưa làm: 20 % xác suất cộng lớp 会心一击+2 % cho chủ — SkillData không có ID hiệu ứng cho lớp này.',
         summon = {{id = '图腾id', hp = '图腾血量', self_impact = '无敌效果id', at = 'dest', life = 15000,
                    name = 'Gia Cát Thần Nỏ',
                    attack = {scale = 25, radius = 15, count = 1, around = 'summon', interval = 400}}}},
[731] = {src = 'partial', note = '千机变 (唐门, template 2922): 延迟buff + 免疫控制buff giữ nguyên. skill-summon 17/09: ' ..
                                 'chọn NGẪU NHIÊN 1 trong 图腾id1/2/3 (16936 枢甲玄豹 / 16937 枢甲幽鸩 / 16938 枢甲游蛇) đặt ' ..
                                 'cạnh mục tiêu, máu theo 图腾血量N (9000/9000/16000), 3 s sau mới kích hoạt (tip), rồi mỗi ' ..
                                 '2 s gây 80/100/150 % đòn đánh thường cho tối đa 3 địch trong 4 m (tip). ' ..
                                 'Chưa làm: thực thể DI CHUYỂN tới mục tiêu rồi mới nổ, và hiệu ứng riêng của từng con ' ..
                                 '(撕裂 / 鸩羽 / 赤练之毒) — SkillData chỉ có 延迟buff, không có ID cho ba hiệu ứng đó.',
         impacts = {{label = '延迟buff', to = 'target'}, {label = '免疫控制buff', to = 'self'}},
         summon = {{ids = {'图腾id1', '图腾id2', '图腾id3'}, hps = {'图腾血量1', '图腾血量2', '图腾血量3'},
                    at = 'target', life = 10000, delay = 3000, name = 'Xu Giáp Tạo Vật',
                    attack = {scale = {80, 100, 150}, radius = 4, count = 3, around = 'summon', interval = 2000}}}},
[732] = {src = 'label', note = '九天揽月 (唐门): 生效一次的效果(目标) + hội tâm thì giảm hồi chiêu ngẫu nhiên 5–15 s (tip).',
         impacts = {{label = '生效一次的效果(目标)', to = 'target'}},
         cooldown_on_crit = {min = '暴击时减少冷却时间的下限', max = '暴击时减少冷却时间的上限'}},
[736] = {src = 'label', note = '万箭齐发 (唐门 2901): 伤害效果 lên từng mục tiêu AOE (目标逻辑 11, 6 người trong 5 m). ' ..
                              'skill-logic-3 17/09: ba mức 触发1/2/3次溅射几率（百分比）(80/40/12) NAY đi đủ — ' ..
                              'tip "受到万箭齐发伤害的目标有几率触发雷击效果…最多对3个目标触发雷击" ⇒ duyệt từng mục tiêu ' ..
                              'ĐÃ TRÚNG, lần tóe thứ k dùng mức xác suất thứ k, tối đa 3 lần cho cả lượt ' ..
                              '(mức sau khó hơn mức trước, đúng thứ tự 80 > 40 > 12). ' ..
                              'ID bẫy đọc từ ô 溅射效果陷阱id NGAY LÚC CHẠY (trap-recollide đã đổi 1980 → 3064, ' ..
                              'SpecialObjData có dòng 3064) — không ghi cứng số nào. ' ..
                              'skill-logic-4 17/09: bẫy 3064 có 陷阱专用标记 = 0 (không nổ được bằng nhân vật) và ' ..
                              '可激活次数 = 1, 持续时间 100 ms ⇒ CHỈ ô 是否即刻生效一次 = 1 mới làm nó chạy — nay đã cài ' ..
                              '(scene.special_obj.trap:activate_at_once). ' ..
                              'skill-logic-5 17/09: ô 效果1 của bẫy KHÔNG phải dữ liệu thiếu — bảng CY 3.71 của chính ' ..
                              'dòng nguồn (1980 万箭齐发) cũng để −1 (trap-data mục 4(c)). Tip nói "对其周围5米范围内3个 ' ..
                              '敌对目标造成100%万箭齐发伤害" = dòng 伤害效果 của ĐÚNG CẤP đang dùng (37316…37331), mà một ' ..
                              'dòng SpecialObjData chỉ có MỘT ô 效果1 ⇒ truyền theo cấp bằng obj._custom_descriptor ' ..
                              '(trap.lua:19-33 ưu tiên bảng này; std_impact_543 đã dùng đúng kiểu này cho 飞剑).',
         impacts = {{label = '伤害效果', to = 'target'}},
         trap = {{label = '溅射效果陷阱id', at = 'target', per_target = true, max = 3,
                  chance_ladder = {'触发1次溅射几率（百分比）', '触发2次溅射几率（百分比）',
                                   '触发3次溅射几率（百分比）'},
                  descriptor = {['效果1'] = '伤害效果'}}}},

-- 鬼谷 ------------------------------------------------------------------------------------------
[760] = {src = 'label', note = '缩地成寸 (鬼谷): 目标逻辑 9 — dời đồng đội được chọn tới điểm chỉ định; ' ..
                              'ô |生效一次的附加效果1 là impact thuấn di → áp cho ĐỒNG ĐỘI được chọn, toạ độ = điểm chỉ định.',
         teleport = {idx = 1, to = 'dest', on = 'target'}},

-- 星阵 (鬼谷) 761–765. skill-logic-4 17/09 — ĐẢO lại kết luận của mục 12.4: cài ở đây KHÔNG ra hai 星阵.
-- Bằng chứng (agent taohua-doll + Build\Logs\2026-09-17-skill-logic-4\15-guigu-seed.txt):
--   * `guigu_installation.timers:on_use_skill_successfully` khi tung 3438… CHỈ ghi mốc vị trí
--     (`callbacks.start_xin_zhen`), KHÔNG dựng thực thể;
--   * thực thể chỉ ra ở `callbacks.script_on_impact_fade` — tức khi một impact MẦM (逻辑ID 8090,
--     脚本ID 808253, 总持续时间 1 ms) TẮT trên người tung; dải mầm quyết định trận nào + bậc mấy;
--   * 60/60 dòng mầm (4067–4078, 4080–4091, 4166–4177, 4226–4237, 4238–4249) CÓ ĐỦ trên server,
--     nhưng **0/20.667 ô SkillData** trỏ tới chúng ⇒ trước lượt này không ai gửi mầm ⇒ 0 星阵.
-- Dòng SkillData của cả 5 chiêu KHÔNG có ô tham số nào (chỉ 消耗MP), nên `first` ghi thẳng ở đây.
-- BẪY: dải mầm chỉ 12 mức còn CY có 16 cấp tâm pháp, mà guigu_installation.lua:22 có
-- `assert(tier >= 1 and tier <= 12)` ⇒ `seed_data_index` KẸP về 12 (không kẹp thì 4067 + 15 = 4082
-- rơi sang dải 破军 4080–4091: sai trận + có thể nổ assert).
[761] = {src = 'label', note = '聚星阵·长生 (鬼谷 3438): gửi impact mầm 4067+(cấp−1) cho CHÍNH người tung; ' ..
                              'cy_four_combat dựng quái 16916 (脚本 808254, 30 s, nhịp 3 s, hồi 3 % HP tối đa của ' ..
                              'người bày trận cho tổ đội trong 10 m). SkillData không có ô tham số nào.',
         seed = {first = 4067, tiers = 12}},
[762] = {src = 'label', note = '绝星阵·破军 (鬼谷 3439): mầm 4080+(cấp−1) → quái 16917 (脚本 808255, 10 s, nhịp 1 s).',
         seed = {first = 4080, tiers = 12}},
[763] = {src = 'label', note = '聚星阵·阴阳 (鬼谷 3447): mầm 4166+(cấp−1) → quái 16918 (脚本 808256, 10 s, nhịp 1 s). ' ..
                              'Điều kiện 需要意纵横 (tập CY 298) do condition_delplete_core lo.',
         seed = {first = 4166, tiers = 12}},
[764] = {src = 'label', note = '绝星阵·七杀 (鬼谷 3451): mầm 4226+(cấp−1) → quái 16927 (脚本 808257, 15 s, nhịp 2 s).',
         seed = {first = 4226, tiers = 12}},
[765] = {src = 'label', note = '绝星阵·贪狼 (鬼谷 3453): mầm 4238+(cấp−1) → quái 16928 (脚本 808258, 15 s, nhịp 1 s).',
         seed = {first = 4238, tiers = 12}},

[767] = {src = 'partial', note = '借东风 (鬼谷): 霸体效果 cho đồng đội quanh mình. Năm bẫy 1..5队友伤害陷阱 chọn theo số đồng đội đã dời — ' ..
                                 'chưa dời được đồng đội nên chỉ đặt bẫy mức 1.',
         aoe = {{label = '霸体效果', around = 'self', count = 6, radius = 15, side = 'ally'}},
         trap = {{label = '1队友伤害陷阱', at = 'self'}},
         consume = {'连线特效', '2队友伤害陷阱', '3队友伤害陷阱', '4队友伤害陷阱', '5队友伤害陷阱'}},
[768] = {src = 'partial', note = '陨星造化 (鬼谷): chọn ô sát thương/choáng theo SỐ mục tiêu trúng (3..6) — ' ..
                                 'engine chia theo số mục tiêu của lượt.',
         by_target_count = {base = 3, damage = {'三目标伤害', '四目标伤害', '五目标伤害', '六目标伤害'},
                            control = {'三目标眩晕', '四目标眩晕', '五目标眩晕', '六目标眩晕'}},
         consume = {'预警陷阱id'}},
[769] = {src = 'label', note = '火烧连营 (鬼谷 3441). skill-logic-3 17/09: CHUỖI LAN theo thời gian đã cài. ' ..
                              'Tip: "立即对目标造成80%普攻伤害，之后每0.8秒额外链接目标附近一名敌对目标，并对所有链接的目标 ' ..
                              '造成伤害，伤害依序递增20%，最多链接6名目标，被链接的目标离开攻击范围后会断开链接". ' ..
                              'Bảy ô 主/二/三/四/五/六/七目标伤害 = 59170–59176 là bảy NẤC: đều 逻辑ID 115 ' ..
                              '(sát thương = N % đòn đánh thường) với 伤害量缩放系数 = 80/100/120/140/160/180/200 ' ..
                              '⇒ đúng "80 % rồi tăng dần 20 %"; nấc = THỨ TỰ NỐI, không phải số nhịp. ' ..
                              'Nhịp lấy từ chính engine: SkillTemplate 3441 连续攻击次数或引导的时间间隔 = 800 ms = 0,8 s ' ..
                              'của tip (技能类型 1 = chiêu dẫn 8 s) ⇒ chuỗi chạy trong activate_each_tick, KHÔNG cần hẹn giờ ' ..
                              'riêng và tự dừng khi ngắt dẫn/chủ chết/mục tiêu chết. Đứt dây: mục tiêu chính rời chủ quá ' ..
                              '主目标断线距离 (15 m) → đứt cả chuỗi; mắt khác rời mục tiêu chính quá 其它目标断线距离 (7 m) ' ..
                              '→ rời chuỗi. Hai ô 主目标连线/其它目标连线 (59168/59169) chưa có dòng StandardImpact trên ' ..
                              'server nên im lặng bỏ qua (việc của impact-data).',
         impacts = {{label = '主目标伤害', to = 'target'}},
         chain = {ladder = {'主目标伤害', '二目标伤害', '三目标伤害', '四目标伤害',
                            '五目标伤害', '六目标伤害', '七目标伤害'},
                  max_links = 6, break_main = '主目标断线距离', break_other = '其它目标断线距离',
                  link_main = '主目标连线', link_other = '其它目标连线', max_ticks = 12}},
[770] = {src = 'partial', note = '请星入命 (鬼谷): hiển hoá 星君 cần hệ 星阵 — chưa có. Chỉ áp 长生护盾 cho bản thân.',
         impacts = {{label = '长生护盾', to = 'self'}}, consume = {'护盾血量百分比', '破军会心'}},

-- 桃花岛 (离人偶 = con rối, mission 329) -------------------------------------------------------
[791] = {src = 'label', note = '八列之舞 (桃花岛): ném con rối tới vị trí; 生效一次的效果(自己) lên bản thân.',
         impacts = {{label = '生效一次的效果(自己)', to = 'self'}}, consume = {'傀儡移动最大距离'}},
[792] = {src = 'native', note = '谋动干戈 (桃花岛). Serverhook Skill_ModuleA::SkillLogic792_T::EffectOnUnitOnce @0x6b97a: ' ..
                               'lấy con rối = Obj_Human::GetMissionData(self, 0x149=329), đặt làm đích thuấn di, rồi ' ..
                               'SendSpecificImpactToUnit(self, self, 0x112c) — thuấn di tới chỗ con rối. ' ..
                               'Bản CY dùng ô dữ liệu |生效一次的附加效果1/2 thay hằng số.',
         teleport = {idx = 1, to = 'doll'}},
[793] = {src = 'native', note = '敛其羽翼 (桃花岛). Serverhook SkillLogic793_T::EffectOnUnitOnce @0x6bbe4 — như 792 nhưng ' ..
                               'impact 0x1138; CY: 瞬移特效 = impact thuấn di, đổi chỗ với con rối; 路径效果N cho tối đa 影响人数 địch trên đường.',
         teleport = {label = '瞬移特效', to = 'doll'},
         impacts = {{label = '给自己效果1', to = 'self'}},
         aoe = {{label = '路径效果1ID', around = 'self', count = '影响人数', radius = 12, side = 'enemy'},
                {label = '路径效果2ID', around = 'self', count = '影响人数', radius = 12, side = 'enemy'}},
         consume = {'矩形宽度（实际效果为该值-0.2）'}},
[794] = {src = 'native', note = '秦皇东遣 (桃花岛/恶人谷). Serverhook SkillLogic794_T::EffectOnUnitOnce @0x6bd58: ' ..
                               'SendSpecificImpactToUnit(self, self, 0x114a) — thuấn di tới điểm chỉ định, không cần con rối. ' ..
                               'CY: ba ô |生效一次自己附加效果1..3 (ô đầu là impact thuấn di).',
         teleport = {label = '|生效一次自己附加效果1', to = 'dest'},
         impacts = {{label = '|生效一次自己附加效果2', to = 'self'}, {label = '|生效一次自己附加效果3', to = 'self'}}},
[795] = {src = 'label', note = '勒马归鞍 (桃花岛, template 3804): để lại bẫy ĐÚNG CHỖ con rối đứng ' ..
                              '(skill-summon 17/09: at = doll → cy_four_combat.callbacks.get_doll_id; không có con rối thì ' ..
                              'rơi về chỗ đứng của chủ như trước). skill-logic-3 17/09 — KHÔNG cài phần "thu hồi con rối" ở ' ..
                              'tầng này: cy_four_combat.tao ĐÃ làm và đang sống (tao.native_skills có 3804, ' ..
                              'phase2_config.resolve.skill_templates[3804] = 3804, deployment_config.gameplay_enabled = true). ' ..
                              'Nhánh 3804 của tao.lua:87 kéo con rối về chỗ chủ (c:charge), tạo vật thể đặc biệt ' ..
                              'ref special_objects[939] = 2101 tại đó rồi gửi impact 4372 cho chủ sau 500 ms. ' ..
                              'Làm lại ở đây sẽ ra HAI con rối/HAI vật thể mỗi lần tung (đúng kiểu bẫy 星阵 mục 12.4). ' ..
                              'CHÚ Ý cần đo live: bẫy của ô 傀儡回收后，原地留下陷阱ID (dòng CY, đổi theo cấp) và vật thể 2101 ' ..
                              'của tao có thể là CÙNG một hiệu ứng port hai lần.',
         trap = {{label = '傀儡回收后，原地留下陷阱ID', at = 'doll'}},
         consume = {'矩形宽度（实际效果为该值-0.2）', '生效敌对目标人数'}},
[797] = {src = 'label', note = '以战止战 (桃花岛): |生效一次的附加效果1 lên bản thân (目标逻辑 0). Ô 0 lớp bị động chỉ là ID tham chiếu.',
         self_idx = {1}, consume = {'桃花岛3817技能对应0层被动效果ID'}},
[799] = {src = 'label', note = '棹歌中流 (桃花岛 3820): 生效一次的效果N(傀儡周围敌人) lên tối đa 傀儡周围生效人数 địch ' ..
                              'QUANH CON RỐI (skill-summon 17/09: around = doll, rơi về chỗ chủ khi chưa có con rối). ' ..
                              'skill-logic-3 17/09: (a) ô 生效一次给傀儡加效果 xuất hiện HAI lần trong cùng một dòng ' ..
                              '(45493 + 45443) — nay áp CẢ HAI và gửi cho CHÍNH CON RỐI (to = doll; không có rối thì về ' ..
                              'bản thân như trước); (b) ô 对效果1伤害的修正，效果1必须用3号伤害类BUFF nay là hệ số cho ' ..
                              'hiệu ứng 1: rate = 100 + giá trị (cấp 1 = −5 → 95 %, cấp 4 = 10 → 110 %, khớp tip ' ..
                              '"每秒造成110%的伤害").',
         impacts = {{label = '生效一次给傀儡加效果', to = 'doll', all = true}},
         aoe = {{label = '生效一次的效果1(傀儡周围敌人)', around = 'doll', count = '傀儡周围生效人数', radius = 5,
                 side = 'enemy', rate_add = '对效果1伤害的修正，效果1必须用3号伤害类BUFF'},
                {label = '生效一次的效果2(傀儡周围敌人)', around = 'doll', count = '傀儡周围生效人数', radius = 5, side = 'enemy'}}},
[800] = {src = 'partial', note = '劝君酒 (桃花岛, template 3822): dấu 暗伤 + giảm tốc cho tối đa 对周围生效目标人数 địch ' ..
                                 'QUANH CON RỐI (skill-summon 17/09: around = doll; chưa có con rối thì quét quanh chủ như trước). ' ..
                                 'skill-logic-3 17/09: hai ô 傀儡罩子 / 傀儡连线 nay gửi cho CHÍNH CON RỐI (to = doll). ' ..
                                 'KHÔNG cài phần "kéo mục tiêu về cạnh con rối": cy_four_combat.tao nhánh 3822 ' ..
                                 '(tao.lua:96–105) đã c:charge từng địch quanh con rối về tâm rồi gửi impact 4400/4518/4517.',
         impacts = {{label = '生效一次的效果(傀儡罩子)桃花岛苦昼短专用', to = 'doll'},
                    {label = '生效一次的效果(傀儡连线)桃花岛苦昼短专用', to = 'doll'}},
         aoe = {{label = '生效一次的效果(目标)桃花岛苦昼短专用', around = 'doll', count = '对周围生效目标人数', radius = 5, side = 'enemy'},
                {label = '生效一次的效果(目标)桃花岛劝君酒专用', around = 'doll', count = '对周围生效目标人数', radius = 5, side = 'enemy'},
                {label = '生效一次的效果(目标)桃花岛怨复怨兮专用', around = 'doll', count = '对周围生效目标人数', radius = 5, side = 'enemy'}}},
[801] = {src = 'label', note = '雅颂之音 / 踏雪无痕 / 解我心忧: 生效一次的效果(自己) lên bản thân, (目标) lên mục tiêu, ' ..
                              '引导周期 tương ứng; 脚下生成陷阱ID đặt bẫy dưới chân.',
         impacts = {{label = '生效一次的效果(自己)', to = 'self'}, {label = '生效一次的效果(目标)', to = 'target'},
                    {label = '生效一次给自己效果2', to = 'self'}},
         trap = {{label = '脚下生成陷阱ID', at = 'self'}},
         tick = {{label = '|引导周期的效果(自己)', to = 'self'}, {label = '|引导周期的附加效果(目标)', to = 'target'}}},
[803] = {src = 'label', note = '高唐云散 (桃花岛, template 3809): dấu 暗伤 cho 对周围生效目标人数 địch quanh CON RỐI ' ..
                              '(skill-summon 17/09: around = doll; không có con rối thì quanh chủ).',
         aoe = {{label = '生效一次的效果(目标)桃花岛怨复怨兮专用', around = 'doll', count = '对周围生效目标人数', radius = 5, side = 'enemy'}}},

-- 绝情谷 (刀意) ---------------------------------------------------------------------------------
[835] = {src = 'label', note = '制六合 (绝情谷): buffid (định thân 2,5 s) lên mục tiêu.',
         impacts = {{label = 'buffid', to = 'target'}}},
[836] = {src = 'label', note = '扫千机 (绝情谷): |生效一次的附加效果1 (tán công) lên mục tiêu — skill_0 lo.'},
[837] = {src = 'label', note = '定苍生 (绝情谷): 控制buffid (cứng đờ 3 s) lên mục tiêu.',
         impacts = {{label = '控制buffid', to = 'target'}}},
[838] = {src = 'label', note = '定苍生（2段） (绝情谷): 控制buffid + 直接伤害 cho tối đa 3 mục tiêu quanh mục tiêu (tip).',
         impacts = {{label = '控制buffid', to = 'target'}, {label = '直接伤害', to = 'target'}}},
-- KHÔNG thêm dòng [840] 荡千军 (绝情谷 4516). skill-logic-4 17/09 — hai lý do, mỗi lý do có bằng chứng:
--   (a) skillenginer đã trỏ [840] → "scene.skill.human.skill_840"; thêm dòng ở đây sẽ khiến skill_logic.py
--       ghi đè thành skill_cy_spec và MẤT cả chuỗi thuấn di → chiêu phụ 5771 của module đó;
--   (b) module skill_840 ĐÃ đặt bẫy 2102 「荡千军刀域」 tại điểm đáp từ mốc gốc 67fc059 — log thật của
--       server riêng 17/09 11:31:48: "[skill_840] dao vuc 2102 obj= 367 tai 46.83 146.23".
--       Thứ thiếu là DỮ LIỆU: SpecialObjData 2102 có 效果1..4 = −1 và 陷阱专用标记 = 0 ⇒ 刀域 chỉ là hiệu ứng
--       nhìn (生存期持续特效 cy4_daoyu_e_…), không gây gì. Việc nhập 效果 thuộc trap-impacts.
[841] = {src = 'label', note = '与虎谋皮 (绝情谷): thuấn di tới mục tiêu (瞬移BUFFid) + 生效一次的效果(目标) phong huyệt. ' ..
                              '刀意buffid là điều kiện (mục tiêu phải có 刀印) — chỉ tiêu thụ nhãn.',
         teleport = {label = '瞬移BUFFid', to = 'target'},
         impacts = {{label = '生效一次的效果(目标)', to = 'target'}},
         consume = {'刀意buffid'}},
[842] = {src = 'label', note = '君入瓮 (绝情谷): 生效一次的效果(目标) cho các mục tiêu AOE (目标逻辑 4).',
         impacts = {{label = '生效一次的效果(目标)', to = 'target'}}},

-- 恶人谷 (拘魂/丧魂) ----------------------------------------------------------------------------
[864] = {src = 'label', note = '拘魂·天/地/命 (恶人谷): 自身获得效果 cho bản thân, 目标获得效果 + 伤害效果 cho mục tiêu, ' ..
                              'rồi giảm 减少时间（ms） hồi chiêu của 减少冷却时间id (tip: 百倍奉还 −2 s).',
         impacts = {{label = '自身获得效果', to = 'self'}, {label = '目标获得效果', to = 'target'},
                    {label = '伤害效果', to = 'target'}},
         cooldown_reduce = {id = '减少冷却时间id', ms = '减少时间（ms）'}},
[865] = {src = 'label', note = '百倍奉还 (恶人谷): 基础伤害效果 nhân theo SỐ loại 丧魂 mục tiêu đang mang ' ..
                              '(tập 天魂/地魂/命魂集合id) — 一/二/三魂倍率百分比.',
         souls = {base = '基础伤害效果', sets = {'天魂集合id', '地魂集合id', '命魂集合id'},
                  mult = {'一魂倍率百分比', '二魂倍率百分比', '三魂倍率百分比'}},
         consume = {'失魂集合id', '重置失魂buff几率', '重置失魂时间'}},
[866] = {src = 'label', note = '无我三界 (恶人谷): ba ô |生效一次的附加效果N lên bản thân (目标逻辑 0) — skill_0 lo.'},
[867] = {src = 'label', note = '魂离魄散 (恶人谷): như 865 nhưng AOE (目标逻辑 11) — nhân theo số 丧魂 của từng mục tiêu. ' ..
                              '斩杀效果 (giết → làm mù quanh) chưa làm.',
         souls = {base = '基础伤害效果', sets = {'失魂集合id'}, mult = {'一魂倍率百分比', '二魂倍率百分比', '三魂倍率百分比'},
                  count_by = 'each'},
         consume = {'斩杀效果'}},
[868] = {src = 'label', note = '判指阴阳 (恶人谷): cần ≥ 2 拘魂; 基础伤害效果 nhân 燃烧两魂/三魂伤害百分比; ' ..
                              'mỗi魂 đang có → impact tương ứng cho mục tiêu; xoá hồi chiêu 清除冷却id.',
         souls = {base = '基础伤害效果', on = 'self', sets = {'天魂集合id', '地魂集合id', '命魂集合id'},
                  mult = {[2] = '燃烧两魂伤害百分比', [3] = '燃烧三魂伤害百分比'}, min_sets = 2,
                  per_set = {{set = '天魂集合id', label = '天魂对应目标获得效果'},
                             {set = '地魂集合id', label = '地魂对应目标获得效果'},
                             {set = '命魂集合id', label = '命魂对应目标获得效果'}}},
         impacts = {{label = '麻痹效果id', to = 'target'}},
         cooldown_reduce = {id = '清除冷却id', ms = 999999}},
[869] = {src = 'label', note = '生死由我 (恶人谷): tiêu mọi 拘魂; chọn ô hiệu ứng theo SỐ 拘魂, phát cho bản thân + 6 đồng đội 5 m. ' ..
                              'Dòng SkillData của chiêu này KHÔNG có ô tập 拘魂 → lấy ID tập từ dòng 判指阴阳 (logic 868): ' ..
                              '天魂集合id 412, 地魂集合id 414, 命魂集合id 416.',
         souls_pick = {set_ids = {412, 414, 416}, on_self = true,
                       labels = {'消耗1个拘魂状态的效果', '消耗2个拘魂状态的效果', '消耗3个拘魂状态的效果'},
                       aoe = {count = 6, radius = 5, side = 'ally'}}},
[870] = {src = 'label', note = '拘魂·无厌 (恶人谷): theo 拘3魂几率 — ba trạng thái 拘魂 cho bản thân, ba 失魂 cho mục tiêu.',
         impacts = {{label = '拘魂·天效果id', to = 'self', chance = '拘3魂几率'},
                    {label = '拘魂·地效果id', to = 'self', chance = '拘3魂几率'},
                    {label = '拘魂·命效果id', to = 'self', chance = '拘3魂几率'},
                    {label = '失魂·天效果id', to = 'target', chance = '拘3魂几率'},
                    {label = '失魂·地效果id', to = 'target', chance = '拘3魂几率'},
                    {label = '失魂·命效果id', to = 'target', chance = '拘3魂几率'}}},

-- ============================ kỹ năng ngoài môn phái (ưu tiên cuối) ============================
[12]  = {src = 'native', note = '燃烧陷阱. tlbb15 CommonSkill003_T::EffectOnUnitOnce @0xa6abb6: ô tham số 0 (陷阱Data) > 0 → ' ..
                                'Obj_Character::Skill_CreateObjSpecial(self, vị trí bản thân, giá trị, 0) rồi RegisterActiveObj(…, 500 ms).',
         trap = {{label = '陷阱Data', at = 'self', register_ms = 500}}},
[882] = {src = 'label', note = 'vũ khí thường (普通攻击/木棍…): 生效一次的效果(自己) → bản thân, (目标) → mục tiêu.',
         impacts = {{label = '生效一次的效果(自己)', to = 'self'}, {label = '生效一次的效果(目标)', to = 'target'}},
         tick = {{label = '|引导周期的效果(自己)', to = 'self'}, {label = '|引导周期的附加效果(目标)', to = 'target'}},
         consume = {'暴击概率'}},
[885] = {src = 'label', note = 'vũ khí có AOE khi hội tâm: như 882 + 次目标个数 địch trong 范围半径 khi 暴击是否触发AOE.',
         impacts = {{label = '生效一次的效果(自己)', to = 'self'}, {label = '生效一次的效果(目标)', to = 'target'}},
         aoe = {{label = '生效一次的效果(目标)', around = 'target', count = '次目标个数', radius = '范围半径',
                 side = 'enemy', only_critical = '暴击是否触发AOE'}},
         consume = {'暴击概率'}},
[883] = {src = 'label', note = '猛虎下山: hai ô (自己) cho bản thân; hai ô (目标…) theo mốc máu 40 % của mục tiêu.',
         impacts = {{label = '生效一次的附加效果1（自己）', to = 'self'}, {label = '生效一次的附加效果2（自己）', to = 'self'}},
         hp_branch = {above = '生效一次的附加效果1（目标，血量高于40%）', below = '生效一次的附加效果2（目标，血量低于40%）', pct = 40},
         consume = {'预警陷阱id'}},
[887] = {src = 'partial', note = '流云矢（神弩）: 伤害效果 lên mục tiêu; 5 mốc 会心增益 theo số lớp — chưa đếm lớp.',
         impacts = {{label = '伤害效果', to = 'target'}},
         consume = {'命中时会心增益概率', '1层会心增益', '2层会心增益', '3层会心增益', '4层会心增益', '5层会心增益'}},
[901] = {src = 'label', note = '冲锋: 伤害效果id + 眩晕效果id lên mục tiêu.',
         impacts = {{label = '伤害效果id', to = 'target'}, {label = '眩晕效果id', to = 'target'}}},
[400] = {src = 'label', note = '战船弩炮手: 给自身的buff cho bản thân, 给目标的buff1 cho mục tiêu.',
         impacts = {{label = '给自身的buff', to = 'self'}, {label = '给目标的buff1', to = 'target'}},
         consume = {'给目标的参数2'}},
[862] = {src = 'label', note = '荡千军 (bản dữ liệu CY, khác logic 840 đã cài): thuấn di theo 瞬移buff, bẫy 陷阱id, ' ..
                              '生效一次的效果(自己) cho bản thân.',
         teleport = {label = '瞬移buff', to = 'dest'},
         trap = {{label = '陷阱id', at = 'dest'}},
         impacts = {{label = '生效一次的效果(自己)', to = 'self'}}},
[6]   = {src = 'label', note = '暗器连击: |生效一次的附加效果1 lên mục tiêu — skill_0 lo.'},
[884] = {src = 'label', note = '制胜一击: |生效一次的附加效果1 lên mục tiêu (目标逻辑 4) — skill_0 lo.'},
[18]  = {src = 'label', note = '万宝随身换: |生效一次的附加效果N — skill_0 lo.'},
[77]  = {src = 'label', note = 'đồ dùng tự tăng ích phạm vi: |生效一次的附加效果N — skill_0 lo (目标逻辑 0).'},
[648] = {src = 'label', note = '诛仙万象: |生效一次的附加效果N + |引导周期的附加效果N — skill_0 lo.'},
[649] = {src = 'label', note = '丢香囊/缉盗棍法…: |生效一次的附加效果N — skill_0 lo, 脚本ID do script xử lý.',
         consume = {'脚本ID'}},

-- ============================================================================================
-- 15/91 logic CHƯA cài (lý do đầy đủ: Docs/specs/server/skill-logic_vi.md mục 3 và mục 12 skill-summon 17/09;
-- 886 狂猿凌峰 đã cài lượt skill-summon nên không còn trong danh sách này):
--   833 大江之势… (920 dòng, 0 template phái) — hệ 星阵 bị động, 45 bộ nhãn khác nhau mỗi dòng.
--   645 珍兽附体 (104 dòng)  — mã CY PetPossessionSkill_T::Refix_PetPossessionEffect @0xa75c42;
--                              công thức theo 资质/成长率/融合度/觉醒 của trân thú (ngoài phạm vi phái).
--   766 长生聚星阵 (鬼谷) — chỉ có ô 图腾类型ID; chưa rõ nó trỏ thực thể nào của hệ 星阵.
--       (761–765 ĐÃ CÀI ở lượt skill-logic-4 17/09 bằng khối `seed` — xem khối 星阵 phía trên.
--        Kết luận cũ "thêm ở đây sẽ ra HAI 星阵" đã bị bác bỏ: guigu_installation chỉ ghi MỐC VỊ TRÍ khi
--        tung chiêu, thực thể chỉ ra khi impact mầm 8090 tắt, mà 0/20.667 ô SkillData trỏ tới dải mầm.)
--   641 打开/采集 — mã CY ActivateSpecificObj_T @0xa68872/@0xa68e2a gọi Obj_Monster::Script_OnActivate*,
--                   cần móc script quái chứ không phải impact.
--   207 白虹贯日 (大理) — không có ô tham số; CY kích hoạt NGẪU NHIÊN một chiêu 刃影 ĐÃ HỌC.
--   7   形影不离 — mã CY SpouseTeleportAndImpacts_T @0xa71b6c: ô 0/1/2 → mục tiêu, ô 3 → thuấn di tới
--                   vợ/chồng (HumanRelation::IsMarried/GetSpouseGUID, cùng cảnh, không bay). Server riêng chưa có API này.
--   646 647 雾影摄魂 / 天陨火雨 — bẫy theo nhịp dẫn ở toạ độ ngẫu nhiên + bẫy tăng cường theo tập buff.
--   19  召出子女 — nhãn duy nhất là 无 (không tham số).
--   735 万箭齐发·铩羽 (唐门) — không có ô tham số; kích nổ bẫy 万箭齐发 của chính mình trong 20 m.
-- ============================================================================================
}
