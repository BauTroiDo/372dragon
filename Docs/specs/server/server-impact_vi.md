# server-impact — kỹ năng CY có tác dụng thật trên server riêng

Ngày: 15/09/2026. Agent `server-impact`, nhánh `server-impact`. Bằng chứng: `Build/Logs/2026-09-14-server-impact/`.
Tiếp nối `cs3c-tables_vi.md` (mục 1.2, 6) và `cs3b-menpai_vi.md`. Server riêng: `Docs/specs/net/cys-server_vi.md`.

Quy ước: **[DK]** dữ kiện đo được (đường dẫn/dòng). **[SL]** suy luận. `R` = `/home/ubuntu/cys-test-20260913`, mốc `76e15ba` (sau CS3a2).
Nguồn: **SI** = `R/configs/StandardImpact.txt` (= tlbb15 `Server/Config/StandardImpact.txt`, 23.523 dòng, ID CY); **SD/ST** = `SkillData_V1`/`SkillTemplate_V1` server (ID CY, bố cục GL);
**CY** = client CY 3.71 (`Tools/DATA NEW/DataCY31-08-26/Config`, ImpactSEData); **GL** = bảng server tại `995c2df` (trước CS3b).
Không có nguồn StandardImpact CY nào mới hơn tlbb15 trên máy (`scripts/05-find-si.out.txt`: chỉ 1 file) → mọi dòng thiếu phải **suy ra**.

## 0. Kết quả

| Việc | Trạng thái |
|---|---|
| Impact thiếu | 5.526 ID / 7.135 lượt SkillData → **1.686 ID suy ra** có bằng chứng (R1 145, R2 16, R3 sát thương 758 / thuộc tính 323 / khống chế 444); 3.840 còn lại có lý do; tham chiếu có dòng 17.574 → 19.754 / 24.709 (100 % được phân loại) |
| Logic impact | 88 logic chưa cài (4.193 dòng) → 27 đăng ký tường minh (11 module mới nil-safe, 3 bí danh, 3 buff rỗng) + 58 logic duy trì tự rơi về buff rỗng thay vì `std_impact_003` |
| Skill logic CY chưa cài (91 ID, 3.610 dòng SD) | `skill_cy_generic` = `skill_0` + nhãn impact CY mà cfghelper không đọc |
| Hằng impact GL trong Lua | 176 lượt / 128 ID: 56 giữ (cùng nghĩa), **102 ID** chép dòng GL sang 63000–63101, sửa 89 file (12608/8425/19183–19192 gồm trong đó) |
| Kỹ năng 15 phái cấp 1–4 | "không tác dụng" **896 → 400**, "ok" 675 → 1.071 (tĩnh, mục 1.5) |
| Server riêng | `76e15ba` → `0daf4b0` (bảng) → `2aca108` (engine + module) → **`926e506`** (hằng GL); backup `R/backups/20260915T000804Z-truoc-server-impact` + `R/backups/server-impact-20260915T002904Z/` (bản cũ từng file) |
| Restart / log | restart 07:30:41 và 07:36:22: 15733 LISTEN 30–40 s, **0 traceback, 0 SCENE_LOAD/INIT/CREATE_FAIL, 0 MONSTER_CFG_FAIL** (`wait-logcheck-{3,4}.txt`); sau 3 lượt bot 0 lỗi mới (`post-bot-1.txt`) |
| Bot live (mục 6) | 剜心镰 4622 (恶人谷) trước: **149 lần tung, 0 sát thương**; sau: **1 lần tung → sát thương → giết**. 剑锁江山 775 (慕容) sau: 2 lần tung → 4 GCDetailHealsAndDamages + 2 GCCharDirectImpact + buff, 2 quái chết |



## 1. Impact thiếu **[DK]**

### 1.1 Cách đếm
Tham chiếu impact = ô `参数值` của SD mà `参数说明` là nhãn impact (có `效果`/`buff`, không có `几率/概率/集合/陷阱/次数/数目/上限/半径/时间/距离/类型/百分/%/权重/层数/脚本/冷却/范围/说明/宽度/步长/技能ID/阈值/倍率/系数`), giá trị ≥ 0;
cộng `ST.珍兽技能产生的效果ID` và `EquipBase` cột 19 (`Tools/server/server_impact.py collect_refs`).

| Chỉ số | Số |
|---|---|
| Tham chiếu | 24.709 (SD + EquipBase cột 19 2.907 + ST.珍兽技能产生的效果ID) |
| Có dòng SI | 17.574 |
| **ID thiếu / lượt thiếu** | **5.526 / 7.135** (toàn bộ từ SD; EquipBase 2.907/2.907 có — cs3c đã lọc) |

cs3c ghi 5.273 vì đếm theo chuỗi GBK `效果` trong nhãn; bộ lọc ở đây thêm nhãn `buff/BUFF` và bỏ nhãn số (几率…), nên lệch ~250 [DK: `scripts/04-survey-impacts.py` so `server_impact.py`].

### 1.2 Phân bố
Theo phái (phái lấy từ SkillTemplate chứa SkillData; `scripts/39-spec-stats.json`):

| Phái | ID thiếu | Suy ra được | Còn lại |
|---|---|---|---|
| không phái (kỹ năng chung, trân thú, tọa kỵ, thần binh…) | 1.743 | 226 | 1.517 |
| SD không nằm trong SkillTemplate nào | 516 | 48 | 468 |
| 恶人谷 | 596 | 240 | 356 |
| 慕容 | 473 | 276 | 197 |
| 唐门 | 408 | 210 | 198 |
| 绝情谷 | 404 | 195 | 209 |
| 大理 | 288 | 128 | 160 |
| 鬼谷 | 286 | 108 | 178 |
| 桃花岛 | 246 | 127 | 119 |
| 峨嵋 | 238 | 39 | 199 |
| 星宿 | 142 | 21 | 121 |
| 逍遥 / 天山 / 少林 / 丐帮 / 武当 / 明教 | 53 / 46 / 41 / 20 / 17 / 9 | 0 / 3 / 24 / 18 / 17 / 6 | 53 / 43 / 17 / 2 / 0 / 3 |

Theo dải ID: 0–4.999: 5; 5k: 290; 10k: 152; 15k: 240; 20k: 528; 30k: 110; 35k: 666; 40k: 755; 45k: 517; 50k: 238; **55k–60k: 2.025** (kỹ năng 2024–2026).
Nhãn thiếu nhiều nhất: `|生效一次的附加效果1` 1.993, `|给目标的基础效果1` 700 (kỹ năng 第八心法 logic 643/644, tip không có số), `生效一次的效果(目标)` 410, `|生效一次的附加效果2` 303, `生效一次的效果(自己)` 264, `攻击的效果` 194, `给目标的效果` 185.

### 1.3 Cột StandardImpact server theo logic
Server đọc SI theo **tên cột** (`cfghelper.lua:1356 read_std_impact`): 27 cột cố định (`Data_Index, 效果名称, 逻辑ID, 是否是持续性效果, 瞬发效果ID/驻留效果ID, 分类ID, 互斥ID, 互斥优先级, 影响性质, …, 总持续时间(毫秒), 发作时间间隔(毫秒)…`) + 16 bộ `参数k说明/参数值/修正步长`; `params[nhãn] = 参数值`.
Mỗi logic đọc **nhãn** riêng — cột cần cho từng logic = bộ nhãn trong dòng mẫu cùng logic (bảng đầy đủ: `scripts/10-logics.json`, `39-spec-stats.json.logics`). Các logic dòng suy ra dùng:

| Logic | Nhãn tham số cần | Cột cố định quan trọng |
|---|---|---|
| 3 (sát thương theo thuộc tính) | `物理攻击+, 魔法攻击+, 冰系攻击, 火系攻击, 电系攻击, 毒系攻击, 伤害数值` | 是否持续=0, 瞬发效果ID (SE) |
| 11 (điểm thuộc tính) | `物理攻击+ 物理防御+ 魔法攻击+ 魔法防御+ 冰/火/电/毒系攻击修正 冰/火/电/毒系抗性修正 MAX_HP修正 MAX_MP修正 …` | 持续=1, 总持续时间 |
| 13 (命中/闪避/会心) | `命中+ 闪避+ 会心攻击+ 会心防御+` | 持续=1, 总持续时间 |
| 14 (khống chế/tốc độ) | `可否使用任何技能（CanAction1/2…）, 可否移动（CanMove…）, 无敌否, 移动速度修正%（0为无效）, 隐身/反隐, 变身ID, 骑乘ID…` | 持续=1, 总持续时间, 互斥ID |
| 15 (điểm 5 thuộc tính) | `STR/Con/SPR/INT/DEX修正(0为无效)` | 持续=1, 总持续时间 |

### 1.4 Nguồn suy ra (thứ tự ưu tiên, `server_impact.py`)
1. **R1 chuỗi cấp** (145 dòng): cùng SkillTemplate + cùng vị trí tham số ở cấp khác có dòng → chép dòng gần nhất; ô số (thời lượng + 16 `参数值`) nội suy tuyến tính theo cấp khi có ≥ 2 cấp; `参数值/修正步长` lấy **đúng** `{A:x B:y}` trong tip SD cấp đó nếu A của cấp mẫu trùng một `参数值` dòng mẫu.
   Bằng chứng quy ước tip: SI 1210 仙人指路 `魔法攻击+=3143 / 222.2444`; GL 21140 余音袅袅 `58/3` = tip SD 25000 `{A:58 B:3}` [DK `scripts/07-step.out.txt`, `08-cytext.out.txt`].
2. **R2 dòng GL cùng ID** (16 dòng, 柳拂衣 慕容): chỉ nhận khi tip A trùng `参数值` dòng GL hoặc tên dòng GL chứa tên kỹ năng; SE GL không có ở client CY → −1.
3. **R3 hiệu ứng trong tip** (hiển thị lấy từ client CY, số chiến đấu từ tip SD): tip chia mệnh đề (`，。；` và `#r`), trích theo thứ tự:
   - sát thương: `{A:x B:y}` sau `外功/内功/冰/火/玄/毒攻击` hoặc `伤害`, **không** kèm `持续N秒` trong cùng mệnh đề (kỹ năng thù địch) → dòng logic 3 (khuôn = dòng HJS logic 3 bảy nhãn đầu tiên) — 758 dòng;
   - thuộc tính: từ khoá (`内功攻击/外功防御/生命值/命中/闪避/会心防御/体力/定力/所有属性/移动速度…`) + `增加/提高/降低` + số (`{A}`, `N点`, tốc độ `N%`) + `持续N秒/分钟` trong ≤ 2 mệnh đề sau → logic 11/13/15/14 (khuôn = dòng HJS cùng logic có đủ nhãn, số khác đặt 0/−1) — 323 dòng;
   - khống chế: `定身/昏迷/眩晕/封穴/麻痹/沉默/封印/减速/失明/散功/昏睡` (bỏ mệnh đề `解除/免疫/驱散/净化`) → chép dòng HJS logic 14 chỉ mang đúng loại đó, không `无敌/沉默`, được SD tham chiếu nhiều nhất (玉女穿梭(定身) 1331, 如封似闭(封印) 1200, 天外飞仙麻痹 7567, 云海迎客失明 11742, 拈花指(散功) 250, 兰花点穴手(封穴) 2187, 棒打狗头减速 2904…), thời lượng từ tip (không ghi → giữ dòng mẫu, [SL]) — 444 dòng.
   Ghép hiệu ứng ↔ ô impact: ô đã có dòng "tiêu thụ" hiệu ứng cùng loại (logic 3 = sát thương, 14 = khống chế, 11/13/15… = thuộc tính); ô còn lại nhận hiệu ứng kế tiếp; ô nhãn tự thân (`自己/自身/激活/变身…`) không nhận sát thương/khống chế.
   `瞬发效果ID` (SE) dòng R3: dòng CY `ImpactSEData` đầu tiên có `效果说明` chứa tên kỹ năng, không có → −1 (không vẽ, không lỗi).
4. **Không suy ra** 3.840 ID (ghi lý do trong `staging-6/missing_impacts.tsv`): 3.297 tip không có số liệu rõ (buff đặc thù, "强力控制…根据评分", biến thân, triệu hồi, cơ chế riêng); 543 có hiệu ứng nhưng không ghép được với ô.

Tổng: **1.686 ID suy ra** (R1 145 + R2 16 + R3 1.525) → tham chiếu có dòng 17.574 → **19.754**/24.709; bảng 23.523 → **25.311** dòng (+1.686 + 102 dòng GL remap, mục 3).

### 1.5 Kỹ năng 15 phái cấp kỹ năng 1–4 (nhân vật cấp 1–30)
Không tâm pháp: cấp kỹ năng = cấp nhân vật // 10 + 1 (`character.lua get_skill_level`); có tâm pháp: ⌈xinfa/10⌉ + 1 (`human.lua:2203`) → cấp 30 ≈ cấp kỹ năng ≤ 4.
Mỗi SkillData cấp 1–4 của SkillTemplate phái 0–15 (bỏ 9) — `plan.json faction_lowlevel` (ok = mọi ô impact có dòng + logic đã cài + nhãn được logic kỹ năng đọc):

| | ok | một phần | không tác dụng | không có ô impact |
|---|---|---|---|---|
| **Trước** | 675 | 66 | **896** | 358 |
| **Sau** | **1.071** | 166 | **400** | 358 |

| Phái | ok trước → sau | không tác dụng trước → sau |
|---|---|---|
| 少林 | 77 → 103 | 28 → 6 |
| 明教 | 85 → 95 | 23 → 9 |
| 丐帮 | 84 → 99 | 16 → 1 |
| 武当 | 93 → 99 | 14 → 8 |
| 峨嵋 | 52 → 81 | 58 → 29 |
| 星宿 | 54 → 77 | 72 → 41 |
| 大理 | 61 → 68 | 59 → 28 |
| 天山 | 85 → 95 | 16 → 10 |
| 逍遥 | 57 → 61 | 22 → 18 |
| 慕容 | 24 → 98 | 112 → 26 |
| 唐门 | 0 → 45 | 99 → 54 |
| 鬼谷 | 0 → 22 | 74 → 44 |
| 桃花岛 | 3 → 41 | 93 → 37 |
| 绝情谷 | 0 → 55 | 112 → 49 |
| 恶人谷 | 0 → 32 | 98 → 40 |

Còn lại sau: 716 ô impact thiếu dòng, 32 ô logic chưa cài (98/99/101/102/103/155/169/171 → buff rỗng), 15 ô nhãn CY mà logic kỹ năng **đã cài** không đọc.

### 1.6 Quái 4 bản đồ **[DK]**
`_monster.ini` Lạc Dương 131 type / Tô Châu 92 / Đại Lý 106 / Vô Lượng Sơn 36 → `扩展AI` → `AIScript/*.ai` `AIS_ToSkill(n)`: chỉ skill 0 và (Lạc Dương) 551/561 — 8 ô impact **đều có dòng**. Quái 4 bản đồ không thiếu impact; đánh thường (skill 0) không dùng StandardImpact.

## 2. Logic impact chưa cài **[DK]**
88 logic (< 8000) có dòng SI mà `impactenginer.id_logic_module` không có (4.193 dòng); cs3c ghi 97 (đếm cả logic tham chiếu không có dòng). Trước: mọi logic này rơi về `std_impact_003`
(`impactenginer.lua:425–431`) → buff duy trì không có chỉ số nào, và khi kích hoạt `std_impact_003.on_active` gọi `on_damages` với các hệ sát thương 0 (sự kiện "bị đánh" lên cả đồng đội; lượng máu thực trừ chưa đo) [SL].
Xếp theo số SkillData dùng (đầy đủ `scripts/39-spec-stats.json.logics`):

| Logic | Dòng | SD | Tham chiếu | Mô tả tlbb15 (dòng mẫu) | Sau lượt này |
|---|---|---|---|---|---|
| 97 | 2.945 | 359 | 451 | StdImpact097 坐骑：朔影天狼 (không tham số) | null_logic_buff |
| 16 | 51 | 49 | 49 | 反应迟钝 (STR…DEX修正%) | **std_impact_016** |
| 149 | 59 | 36 | 36 | 破釜沉舟 (基础伤害增强…) | **std_impact_149** |
| 91 | 32 | 32 | 32 | 养精蓄锐 (外/内功攻击修正率) | **std_impact_091** |
| 43 | 128 | 21 | 148 | 中冲破抗冰火玄 (冰/火/电/毒抗性修正, 怒气增长修正) | **std_impact_043** |
| 102 | 22 | 17 | 17 | 一日丧命散 (quét AOE, 死亡/消散效果) | buff rỗng (tự động) |
| 170 | 17 | 17 | 17 | 礼敬如来 (免疫率, 反射率…) | **std_impact_170** |
| 2 | 3 | 17 | 17 | 秒人 (伤害百分率) | **std_impact_002** |
| 76 | 33 | 16 | 16 | 伤害附加 (目标效果集合ID, 附加伤害类型/数值) | **std_impact_076** |
| 99 / 103 / 98 / 101 | 33 / 21 / 16 / 16 | 16 mỗi logic | 16 | 阳关三叠补充 (bẫy) / 横扫AOE / 慈航普度 / 怒火连斩 | buff rỗng (tự động) |
| 114 | 62 | 12 | 12 | 龙战于野 (命中/闪避/会心一击率调整百分比) | **std_impact_114** |
| 156 / 187 | 13 / 12 | 12 / 12 | 12 / 12 | 护心绝 / 金刚不坏体 (免疫率) | **std_impact_170** |
| 155 / 169 | 12 / 31 | 12 / 10 | | 魂离魄散 / 拘魂·命 | buff rỗng (tự động) |
| 145 / 162 / 122 | 15 / 37 / 4 | 8 / 5 / 4 | | 修正率 4 chỉ số / 镰决 / 闪避修正 | **std_impact_114** |
| 115 | 7 | 6 | 9 | 撼岳群攻 (伤害量缩放系数, không 持续) | std_impact_003 (như cũ) |
| 110 / 113 / 116 | 6 mỗi logic | 6 | | 兽魂镇伏 / 夕照护盾 / 煞月 | **170 / 113 / 149** |
| 117 / 112 / 111 / 90 / … | | ≤ 6 | | 星驰 / 溯回 / 慑天 / 命中回调 … | buff rỗng (tự động) |
| 175 / 176 / 185 / 109 / 150 / 130 / 67 / 157 | | ≤ 1 | | 先礼后兵 / 镜花水月 / 荡千军(瞬移) / 兽魂爆发 / 猛袭难当 / 金玉满堂 / 开膛 / 炼狱业火 | **015 / 015 / 009 / 091 / 149 / 130 / 067 / 149** |
| 151 | 207 | 0 | 0 | 寒冰化劲 | buff rỗng (tự động) |

Tổng: **27 logic đăng ký tường minh** (11 module mới + 3 bí danh module GL nhãn trùng 100 % + 3 buff rỗng), **58 logic còn lại** mọi dòng là hiệu ứng duy trì → `null_logic_buff` tự động (704 dòng), 3 logic tức thời giữ `std_impact_003`.
Không dùng bí danh module GL khi nhãn trùng nhưng module **không nil-safe**: 026 (đòi `反射发生几率` → so sánh nil), 059/012 (`math.floor(nil)` trong `get_refix_hp_max`/`def_physics`).

## 3. Lua server ghi cứng impact GL **[DK]**
Quét `GameServer/{services,lualib}` (trừ `cy_four_combat`) các mẫu `send_impact_to_unit(x, N)`, `init_impact_from_data(N)`, `*IMPACT*/DATA_INDEX/BUFF* = N`, `impact_id/data_index = N`, `*_IMPACT_IDS = {…}`: 176 lượt.
- `same` 49 + `cy_only` 4 + `none` 3: ID cùng nghĩa ở SI (tên trùng, hoặc tên GL là tiền tố tên CY **và** cùng logic, vd 44293 降魔镇躯 → 降魔镇躯定身) → giữ.
- `changed` 34 + `gl_only` 86 lượt = **102 ID**: SI mang nghĩa khác (vd 45962 梵音渡世 → CY 灵隐虎 tọa kỵ; 19183 归一剑爆炸 → 高级破绽) hoặc không có (12608 春光四沐, 8425 弑神闪, 5971 天乌骓加伤害…)
  → chép dòng GL sang ID dải riêng **63000–63101** (không trùng SI/không được CY tham chiếu, < 65536), đổi hằng trong **89 file** Lua (chú thích `-- server-impact`), bảng tra `lualib/cys_gl_impact_remap.lua`.
  Gồm 3 hằng cs3c nêu: `murong_skill_common.lua` 12608 → 63017, `skill_73.lua` 8425 → 63001, `std_impact_543.lua` 19183–19192 → 63006–63015.

## 4. Kỹ năng có logic chưa cài, nhãn CY mới
SD dùng **91** `技能逻辑ID` không có trong `skillenginer.id_logic_module` (3.610 dòng SD; 833: 920, 643/644: 465 mỗi logic — 第八心法, 205: 105…) → trước: `skill_0`, chỉ áp nhãn `cfghelper.read_skill_data` biết.
Sau: `scene.skill.human.skill_cy_generic` = `skill_0` + áp thêm cặp (nhãn, DataIndex) thô mà nhãn là nhãn impact, **không** thuộc 179 nhãn cfghelper (`skill_cy_generic_known.lua` sinh máy), DataIndex có trong SI;
đích = bản thân nếu nhãn tự thân hoặc impact tích cực (`影响性质` > 0) nhắm địch; bỏ impact tiêu cực lên đồng minh; `<X>的概率/的发生几率` = xác suất. `cfghelper` lưu `t.cy_raw_params`, `skillinfo` giữ tham chiếu.
Không thay hành vi kỹ năng có logic đã cài (15 ô nhãn CY lạ trong kỹ năng phái cấp thấp vẫn bị bỏ — mục 7).

## 5. Công cụ `Tools/server/server_impact.py`
Chạy trong WSL root: `python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/server_impact.py <lệnh>` (import `cs3b_menpai.py`).

| Lệnh | Việc | Chạm R? |
|---|---|---|
| `plan --out <dir>` | nguồn từ `git show 76e15ba` (+ GL `995c2df`) → `<dir>/configs/StandardImpact.txt` (GBK byte, ID tăng), `<dir>/lua/GameServer/…` (108 file: 12 module impact + `skill_cy_generic` + 2 file sinh máy, 4 file vá engine, 89 file đổi hằng), `plan.json`, `missing_impacts.tsv` | không |
| `apply --staging <dir> [--dry-run]` | chép, sao lưu `R/backups/server-impact-<UTC>/`, trùng byte bỏ qua | có |
| `verify [--staging] [--out]` | GBK toàn file, số tab/ID duy nhất/tăng; 100 % tham chiếu impact được phân loại (có dòng hoặc `unresolved` có lý do); dòng mới: logic đăng ký tường minh, SE có ở client CY hoặc −1; 27 logic trỏ đúng module; remap GL có dòng; `luac5.4 -p`; `server_impact_tests.lua`; staging = R | không |
| `char-skill --out/--add` / `--restore` | CYTest00 `skill_list` thêm template test / khôi phục; từ chối khi còn client hoặc skynet chạy | Mongo riêng |

Test Lua đơn vị `Tools/server/server_impact_tests.lua` (lua5.4, giả lập skynet/define/impactenginer/skill_0): 14 ca — mọi module mới (số liệu, nil-safe với tham số rỗng), phân loại nhãn/đích của `skill_cy_generic`.
Idempotent: plan hai lần trùng byte (`scripts/38-idempotent.out.txt`).

## 6. Áp, restart, kiểm bot, hoàn tác **[DK]**
Bằng chứng `Build/Logs/2026-09-14-server-impact/` (script trong `scripts/`).
1. `status-0.txt` (server riêng đang tắt) → start mốc 0 (`wait-logcheck-0.txt`, 0 traceback) → `cys_server.ps1 backup truoc-server-impact` (`backup-1.txt`, 4 DB, 39 file, git 76e15ba).
2. `plan` 6 lần (`staging-1..6`; 5 ≡ 4 trùng byte `scripts/38-idempotent.out.txt`), test Lua trên staging 14/14 mỗi lần.
3. **Mốc trước** (cấu hình cũ): chờ rảnh → stop → mongod riêng → `char-skill --add 4622,760,775,771` (bản sao `char-skill-add-1.json`) → start (`restart-1.txt`, `wait-logcheck-1.txt` 0 traceback).
   Bot `run_core_live.ps1` lần 1–2 (`bot-before-4622`, `bot-before-4622-wuliang`): mục tiêu gần nhất là NPC thân thiện → `GCOperateResult −16` (OR_WARNING, kiểm mục tiêu đơn) 229 lần — lỗi chọn mục tiêu của bot, không phải impact.
   Sửa bot (`Src/Tools/CysNetBot/main.cpp`: loại mục tiêu bị −16/−8 ba lần, hết ứng viên thì đi tới `--hunt`), build `Build/wt-server-impact/Build/bot-server-impact-072407/CysNetBot.exe` (`scripts/43-build-bot.ps1`).
   Lần 3 (`bot-before-4622-wuliang3`, 无量山 cảnh 6, săn 45,152; lần chạy kế trước đó bị từ chối đăng nhập vì Game.exe của phiên khác đang chạy → chờ rảnh `idle-wait-2.txt`): mục tiêu 189 hợp lệ, **153 CGCharUseSkill → 149 GCCharSkill_Send + 149 GCTargetListAndHitFlags, 0 GCDetailHealsAndDamages, 0 kill** (impact 55131 không có dòng).
4. `apply --staging staging-6` (`apply-6.txt`, 109 file) → commit server 0daf4b0/2aca108/926e506 → `verify` (`verify-6b.json`: ok; lần `verify-6.json` báo lỗi do chính công cụ kiểm — `ipairs` dừng ở nil và chưa chấp nhận logic rơi buff rỗng — đã sửa công cụ, dữ liệu không đổi).
   Lưu ý: script `50-apply-verify-commit.sh` commit không chặn theo kết quả verify, và thông điệp commit `0daf4b0` ghi nhầm "+1.305 dòng" (đúng: +1.686 suy ra + 102 GL = 1.788).
5. Chờ rảnh → restart (`restart-3.txt`, `wait-logcheck-3.txt`): 0 traceback/0 SCENE_*_FAIL.
6. **Mốc sau**: `bot-after-4622` — 1 CGCharUseSkill → GCCharSkill_Send → **GCDetailHealsAndDamages → mục tiêu 189 hp 0 (kill 1)**; `bot-after-775` — 41 lệnh (hồi chiêu 12 s → OR_COOL_DOWNING) → 2 GCCharSkill_Send, **4 GCDetailHealsAndDamages, 2 GCCharDirectImpact, 2 GCCharBuff/GCDetailBuff, 2 kill**. `post-bot-1.txt`: 0 traceback/lỗi.
7. Dọn: chờ rảnh → stop → `char-skill --restore` (skill_list gốc 9 mục) + `cs3a_move_test_char.py apply --scene 2 --x 160 --z 150` (`char-move-1.json`, trước: cảnh 6 46,152) → start (`restart-4.txt`, `wait-logcheck-4.txt`: 0 traceback, git 926e506 sạch).

Hoàn tác: `git -C R revert 926e506 2aca108 0daf4b0` rồi restart; hoặc chép lại `R/backups/server-impact-20260915T002904Z/`; Mongo: `cys_server.sh restore backups/20260915T000804Z-truoc-server-impact`.



## 7. Còn lại / rủi ro
- 3.840 ID impact không suy ra (1.517 kỹ năng không phái: trân thú/tọa kỵ/thần binh/武魂; 700 `|给目标的基础效果1` 第八心法 "强力控制" không số liệu). Cần nguồn StandardImpact CY thật hoặc dựng tay theo mô tả.
- Dòng R3 là **suy luận có bằng chứng tip**, không phải bảng CY thật: SE (hiệu ứng nhìn) thường −1 hoặc SE cùng tên; mutex/分类 theo dòng khuôn; thời lượng khống chế không ghi trong tip giữ theo khuôn [SL].
- `std_impact_149`: chỉ `基础伤害增强`; `暴击伤害增强/门派检测/受到伤害/受到会心伤害` chưa rõ đơn vị. `std_impact_170`: `反射伤害上限` không áp được (engine không có trần tuyệt đối). `std_impact_187`: `回复率千分比/附加伤害千分比` chưa.
- 58 logic chuyển buff rỗng (hiện icon, không chỉ số): AOE quét (98/102/103), bẫy (99), 魂 (152–155/169), 五绝计时 171… cần cài theo nghĩa.
- 15 ô nhãn CY lạ ở kỹ năng có logic đã cài (vd 飞龙在天 logic 80 `|生效一次的附加效果`).
- EquipBase cột 19 = 21 (钓鱼buff) ở 2.624 trang bị không phải vũ khí (cs3c lấy CY cột 101) [DK] — cột này chỉ dùng cho vũ khí (`技能ID：装备点为武器时标识效果ID`), cần agent inventory-equip xem lại.
