# skill-logic — cài 91 logic kỹ năng (技能逻辑ID) của CY còn thiếu trên server riêng

Ngày: 16/09/2026. Agent `skill-logic`, nhánh `skill-logic`, worktree `Build\wt-skill-logic`.
Tiếp nối `menpai-audit_vi.md` (mục 1.3 A, mục 4 lỗi 5), `menpai-fix_vi.md`, `impact-logic_vi.md` (mục 3), `server-impact_vi.md` (mục 4).
Bằng chứng: `Build\Logs\2026-09-16-skill-logic\` (script + bảng, không vào git). RE: `Build\re\skill-logic\`.
Quy ước: **[DK]** dữ kiện đo được (đường dẫn/địa chỉ). **[SL]** suy luận. `R` = `/home/ubuntu/cys-test-20260913`.

## 0. Kết quả

| Việc | Trạng thái |
|---|---|
| Danh sách chính xác 91 logic chưa cài | **91/91**, mỗi logic có số dòng SkillData, số template, phái, cấp, nhãn tham số và tip — `Build\Logs\2026-09-16-skill-logic\scripts\05-table.md` / `.tsv` |
| Bản đồ logic ↔ mã CY native | **Đã bẻ**: `LogicManager_T<SkillLogic_T,691>::Init` @0xa8c70c của tlbb15 → 42 lớp; `logic_id = chỉ số − 1` (chứng minh ở mục 1.2). Serverhook thêm 792/793/794. Tổng mã CY thật phủ **45** logic, trong đó **7** thuộc 91 logic thiếu |
| Logic đã cài lượt này | **75/91** (50 `label`, 21 `partial`, 4 `native`) — phủ **126/137** template phái cấp kỹ năng 1–4 |
| Logic chưa cài | **16**, có lý do từng cái (mục 3) |
| 20 ô nhãn CY mà logic ĐÃ CÀI không đọc | **Đã cài đủ 20** (`cy_skill_extra.lua` + vá skill_0/80/260/704/840) |
| `std_talent_671.lua:31` `get_menpai() ~= 15` | **Không phải lỗi GL** — 671 是 恶人谷 (SectDesc icon `TalentSkillERenGu_8`), mà 恶人谷 = **15** trong số CY. Giữ nguyên, mục 4 |
| Sát thương "N % đòn đánh thường" (việc chuyển từ `impact-data`) | **Đã cài** `std_impact_115` theo mã CY `StdImpact115_T` @0xa5f2f8 — mục 9 |
| Test offline | `Tools\server\skill_logic_tests.lua` **26/26 đạt**; `luac5.4 -p` sạch 11 file; 265/265 nhãn đặc tả khớp SkillData thật |
| Áp server riêng | `07369ff` (74 logic + 20 ô nhãn), `dffe28c` (+884 → 75), `97813ec` (chú thích talent 671), `1ef0d81` (khối 16 logic chưa cài), `265b531` (logic impact 115). Sao lưu từng file `R/backups/skill-logic-2026091*Z/` |
| Restart / kiểm live | xem mục 6 |

## 1. Bản đồ logic kỹ năng của CY **[DK]**

### 1.1 Nguồn
`tlbb15/Server/Server` (ELF64 đã xoá section header) — symtab khôi phục bằng `recover_main.py` của impact-logic (27.105 symbol, `Build\re\impact-logic\main-symbols.json`).
Decompile Ghidra headless, chỉ đọc, không chạy binary: `Build\re\skill-logic\ghidra\run-registry.cmd` và `run-skills.cmd` (blob `main-load1-va3f0000.bin` VA 0x3f0000, `Serverhook.so` base 0x100000; heap 3 GB).

### 1.2 `logic_id = chỉ số − 1`
`Combat_Module::LogicManager_T<Combat_Module::Skill_Module::SkillLogic_T, 691>::Init()` @0xa8c70c (2.688 byte) ghi 42 con trỏ vtable vào `param_1 + 8*k` (`main-skill-registry.c`).
Serverhook `Combat_Module_Skill_Module_SkillLogic_LogicManager` @0x6c5d4 gọi cùng `Init` rồi `RegisterImpactAx<SkillLogic792_T>(0x318)`, `…793_T(0x319)`, `…794_T(0x31a)`; `RegisterImpactAx` ghi vào `list + 8 + id*8`.
Hai cách ghi trùng nhau ⇒ ô thứ `k` của `Init` là `logic_id = k − 1`; 0x318 = 792 khớp tên lớp. Kiểm chéo với Lua: ô 9 `ArmorMastery_T` ↔ `[8] = armor_mastery`, ô 10 `WeaponMastery_T` ↔ `[9] = weapon_mastery`, ô 643 `DarkSkill001_T` ↔ `[642] = skill_642`, ô 691 `SectSkillToTargetAndSelf_T` ↔ `[690]`.

42 logic của tlbb15: 0–5, 7–17, 50–52, 80–82, 110, 140–141, 200–201, 230–231, 260–261, 290–294, 641, 642, 645, 689, 690 (tên lớp đầy đủ trong `05-table.tsv` cột `native_tlbb15`).

### 1.3 Hệ quả: CY 3.71 mới hơn tlbb15
SkillData của server riêng (ID CY) dùng **130** 技能逻辑ID; `skillenginer.id_logic_module` có 66 → **91 thiếu** (3.610 dòng SkillData) — đúng con số của `server-impact_vi.md` mục 4.
Trong 91 logic đó chỉ **7** có mã CY thật: 7, 12, 641, 645 (main) và 792, 793, 794 (hook). 84 logic còn lại là kỹ năng CY 2019–2026, **không tồn tại** trong tlbb15 ⇒ không có mã native để đọc.

### 1.4 Nguồn nghĩa cho 84 logic không có native **[DK]**
Dùng **dữ liệu của chính CY**, không đoán từ tên logic:
- cột `参数说明` của SkillData (mỗi ô nói rõ vai trò: `自身获得效果`, `目标获得效果`, `中毒几率%`, `对周围生效目标人数`, `变身男buff`, `减少冷却时间id`…);
- `技能描述(FOR TIP)` của đúng dòng đó (mô tả CY: số mục tiêu, bán kính, thời lượng, điều kiện);
- cờ `目标逻辑`/`站位` của SkillTemplate.
Bảng nhãn đầy đủ cho cả 91 logic: `scripts\02-labels.md` / `02-labels.json` (sinh bởi `02-labels.py`).
Mỗi dòng đặc tả ghi `src`: `native` (có địa chỉ mã CY), `label` (nhãn + tip), `partial` (làm phần chính, phần còn lại cần cơ chế native — ghi rõ).

## 2. Cài đặt **[DK]**

### 2.1 Kiến trúc
Không viết 75 module rời. Một bộ chạy + một bảng dữ liệu:

| File | Việc |
|---|---|
| `GameServer/lualib/cy_skill_logic_spec.lua` | bảng nghĩa 75 logic: `impacts` (nhãn → `self`/`target`, `chance`, `duration`), `self_idx`/`tick_self_idx` (đổi đích ô `\|生效一次的附加效果N`), `aoe` (nhãn + `around`, `count`, `radius`, `side`), `trap`, `gender`, `cooldown_reduce`, `cooldown_on_crit`, `teleport` (`doll`/`target`/`dest`), `souls` (hệ số theo số 魂), `by_target_count`, `hp_branch`, `consume` |
| `GameServer/services/scene/skill/human/skill_cy_spec.lua` | lớp con của `skill_cy_generic`: chạy đặc tả rồi mới để generic áp các nhãn còn lại; mọi thao tác phụ bọc `pcall` |
| `GameServer/lualib/cy_skill_extra.lua` | 20 ô nhãn CY mà logic ĐÃ CÀI không đọc (mục 5) |
| `GameServer/lualib/skillenginer.lua` | +75 dòng `[id] = "scene.skill.human.skill_cy_spec"` |
| `skill_0/80/260/704/840.lua` | mỗi file một dòng gọi `cy_skill_extra.apply` (840: đọc `瞬移BUFFid` làm impact thuấn di) |

Vì sao cần bộ chạy riêng thay vì để `skill_cy_generic`: generic áp **mọi** ô nhãn impact lên đích đoán theo chữ trong nhãn, nên không biết
(a) ô nào lên bản thân khi nhãn không chứa `自己/自身` (vd `自身获得效果` đúng, nhưng `拘魂·天效果id` thì không),
(b) xác suất dạng `中毒几率%` / `召唤概率%` (generic chỉ nhận hậu tố `的概率/的发生几率`) → buff khống chế bị áp 100 %,
(c) số người/bán kính AOE riêng (`对周围生效目标人数`, `次目标个数`, `傀儡周围生效人数`),
(d) bẫy, biến thân theo giới tính (generic áp **cả hai** ô nam/nữ), giảm hồi chiêu, thuấn di, hệ số theo số 魂.
Ô tự thân chỉ áp **một lần** mỗi lượt (generic áp lại cho từng mục tiêu của chiêu AOE).

### 2.2 Bốn logic theo mã CY thật
| Logic | Mã CY | Cài |
|---|---|---|
| 12 燃烧陷阱 | `CommonSkill003_T::EffectOnUnitOnce` @0xa6abb6: ô tham số 0 > 0 → `Obj_Character::Skill_CreateObjSpecial(self, vị trí bản thân, giá trị, 0)` rồi `RegisterActiveObj(…, 500)` | `trap = {{label = '陷阱Data', at = 'self', register_ms = 500}}` |
| 792 谋动干戈 | `Skill_ModuleA::SkillLogic792_T::EffectOnUnitOnce` @0x6b97a: `Obj_Human::GetMissionData(self, 0x149 = 329)` (con rối) → đặt làm đích, `Combat_Module::SendSpecificImpactToUnit(self, self, 0x112c)` | `teleport = {idx = 1, to = 'doll'}` (bản CY dùng ô dữ liệu thay hằng số) |
| 793 敛其羽翼 | `SkillLogic793_T::EffectOnUnitOnce` @0x6bbe4, impact 0x1138 | `teleport = {label = '瞬移特效', to = 'doll'}` + `路径效果N` cho `影响人数` địch |
| 794 秦皇东遣 | `SkillLogic794_T::EffectOnUnitOnce` @0x6bd58: `SendSpecificImpactToUnit(self, self, 0x114a)`, không cần con rối | `teleport = {label = '\|生效一次自己附加效果1', to = 'dest'}` |

Bản decompile: `Build\re\skill-logic\{main-skill-registry.c, main-skilllogic.c, hook-skilllogic.named.c}`.

### 2.3 Phạm vi đã phủ
75 logic đã cài phủ **126/137** template kỹ năng phái cấp kỹ năng 1–4 (`05-table.tsv`), theo phái:
星宿 12, 桃花岛 12, 峨嵋 10, 恶人谷 10, 绝情谷 8, 大理 7, 鬼谷 7, 唐门 6, 慕容 5, 天山 3, 武当 3, 逍遥 3, 少林 2, 明教 2, 丐帮 2 (số **logic**, không phải số chiêu) + 22 logic không thuộc phái.

### 2.4 Công cụ và kiểm
`Tools/server/skill_logic.py plan|apply|verify` (chạy WSL, root):
- `plan --out <dir>`: dựng file mới + bản vá từ nội dung **hiện tại** của R (không cố định mốc, để không đè lượt của agent khác), `plan.json`;
- `apply --staging <dir> [--dry-run]`: idempotent, sao lưu từng file vào `R/backups/skill-logic-<UTC>/`;
- `verify [--staging]`: `luac5.4 -p` 9 file, đủ ID đăng ký, không trùng module khác, dấu `-- skill-logic` ở 5 file vá, chạy `skill_logic_tests.lua`.
Test đơn vị 21 ca (lua5.4, giả lập skynet/define/skill_0/impactenginer): đích self/target, xác suất 0 %/100 %, AOE theo ô số người và lọc phe, bẫy, biến thân theo `get_model()`, thuấn di (toạ độ), ô chuyển sang bản thân, hệ số theo số 魂 (tính trên mục tiêu và trên bản thân), giảm hồi chiêu khi hội tâm, "ô tự thân chỉ một lần", logic không có đặc tả giữ hành vi cũ, 5 nhãn của `cy_skill_extra` và chống áp hai lần.
Kiểm dữ liệu: `scripts\04-check-spec.py` đối chiếu **265/265** nhãn trong đặc tả với `参数说明` thật của đúng logic đó — 0 nhãn sai.

## 3. 16 logic CHƯA cài + lý do **[DK]**

| Logic | Dòng SD | tmpl phái | Kỹ năng | Lý do |
|---|---|---|---|---|
| 833 | 920 | 0 | 大江之势… (星阵 4200–4383) | 45 bộ nhãn khác nhau, mỗi dòng một cơ chế (减伤/流血/穿刺/血盾/天人五衰…); là hệ 星阵 bị động, cần bộ 星阵 riêng. 0 template phái |
| 645 | 104 | 0 | 凝冰/焚焰… (珍兽附体) | Có mã CY `PetPossessionSkill_T::Refix_PetPossessionEffect` @0xa75c42; công thức theo 资质/成长率/融合度/觉醒 của trân thú. Thuộc nhóm "ngoài phạm vi phái", để sau cùng |
| 764 / 762 / 761 / 763 / 765 | 32 / 17 / 16 / 16 / 16 | 2/2/1/1/1 | 绝星阵·七杀/破军, 聚星阵·长生/阴阳, 绝星阵·贪狼 (鬼谷) | **Dòng SkillData không có ô tham số nào**; toàn bộ hiệu ứng nằm trong thực thể 星阵 (đối tượng có máu, bán kính, chọn mục tiêu mỗi giây) — cần dựng hệ 星阵 trước |
| 766 | 2 | 2 | 长生聚星阵 | chỉ có `图腾类型ID` — cùng lý do trên |
| 641 | 16 | 0 | 打开/采集… | Mã CY `ActivateSpecificObj_T` @0xa68872/@0xa68e2a gọi `Obj_Monster::Script_OnActivateConditionCheck/EffectOnce` — cần móc script quái, không phải impact |
| 207 | 16 | 1 | 白虹贯日 (大理) | Không có ô tham số; CY chọn NGẪU NHIÊN một chiêu 刃影 **đã học** để kích hoạt/đặt lại thời lượng — cần đọc `skill_list` + hệ 二式 |
| 886 | 16 | 1 | 狂猿凌峰 (峨嵋) | Không có ô tham số; triệu hồi quái 蜀山狂猿 15 s có thuộc tính theo người triệu hồi |
| 7 | 5 | 0 | 形影不离 | Mã CY `SpouseTeleportAndImpacts_T` @0xa71b6c: impact idx 0/1/2 cho mục tiêu, idx 3 = thuấn di tới **vợ/chồng** (`HumanRelation::IsMarried/GetSpouseGUID`, cùng cảnh, không đang bay). Server riêng chưa có API vợ/chồng tương đương; 0 template phái |
| 646 / 647 | 1 / 1 | 0 | 雾影摄魂, 天陨火雨 | Bẫy theo nhịp dẫn ở toạ độ ngẫu nhiên quanh mục tiêu + bẫy tăng cường theo tập buff — cần bộ đặt bẫy theo nhịp |
| 19 | 1 | 0 | 召出子女 | Nhãn duy nhất là `无` (không tham số); triệu hồi con cái theo hệ hôn nhân |
| 735 | 1 | 1 | 万箭齐发·铩羽 (唐门) | Không có ô tham số; kích nổ bẫy 万箭齐发 của chính mình trong 20 m — cần truy vấn danh sách bẫy đang sống |

Ba nhóm gốc: (a) cần **thực thể** native chưa có trên server riêng (星阵, 图腾/triệu hồi, bẫy theo nhịp) — 761–766, 886, 646, 647, 735, 19; (b) cần **trạng thái nhân vật** ngoài phạm vi (vợ/chồng, danh sách chiêu đã học, phẩm chất trân thú) — 7, 207, 645; (c) cần **hệ riêng** (星阵 bị động 833, script quái 641).

Ngoài ra 21 logic đã cài ở mức `partial` — phần chưa làm ghi ngay trong `note` của từng dòng `cy_skill_logic_spec.lua` (vd 144 `\|替换一段技能idN` đổi 4 chiêu sang bản 九阳; 149 `\|回血百分比` hút máu; 179 khoá khí; 204 hệ số giảm dần 15 %/lần; 731/730 枢甲造物/神弩; 767 dời đồng đội; 768/769 chuỗi lan; 799/800 thực thể con rối; 867 斩杀).

## 4. `std_talent_671.lua:31` — **không phải số phái GL** [DK]

`menpai-fix_vi.md` mục 3 đánh dấu `if sender:get_menpai() ~= 15 then return end` là "hằng GL còn sót, cần tra TalentInfo CY". Tra xong:
- `SectDesc.txt` dòng 671: `671  有情皆孽  TalentSkillERenGu_8` → thiên phú của **恶人谷**;
- `menpai_registry.lua:7` (CS3b): "phái có mã Lua riêng theo số CY (0-8, 慕容 10, **恶人谷 15**, 曼陀 16 tắt)";
- SkillTemplate server: mọi chiêu 恶人谷 (4625 拘魂·地, 4629 拘魂·命…) có 门派 = 15;
- `cy_four_combat/native.lua:286` `donor_faction(target) ~= 15` đã được menpai-fix xác nhận là **số CY của 恶人谷**.

⇒ `15` đang **đúng** với số CY. Không sửa; đã thêm chú thích trong file để không ai "sửa" nhầm nữa.
(Chú ý: `SectInfo.txt` cột 3 dùng **hệ số khác** — ERenGu = 11, ManTuo = 10, MuRong = 12 — đó là bảng thiên phú GL/HJS chưa đánh số lại theo CY; đừng lấy cột đó làm số phái.)

## 5. 20 ô nhãn CY mà logic ĐÃ CÀI không đọc **[DK]**

Đo bằng `scripts\03-unread-labels.py` (kỹ năng 15 phái, cấp kỹ năng 1–4; nhãn impact không có trong `cfghelper:read_skill_data` và không được module logic đó đọc qua `get_descriptor`):

| Logic | Module | Nhãn | Số ô | Kỹ năng | Cài |
|---|---|---|---|---|---|
| 0 | skill_0 | `\|生效一次的附加效果（对自己）` | 4 | 454 含笑半步癫 (星宿), impact 21733 | → bản thân |
| 80 | skill_80 | `\|生效一次的附加效果` | 4 | 347 飞龙在天 (丐帮), 21634–21637 | → mục tiêu |
| 260 | skill_260 | `给自己的buff` | 4 | 544 定海神针 (逍遥), 54899 | → bản thân |
| 704 | skill_704 | `新增效果id` + `效果作用对象` | 2+2 | 2005 中冲剑·无助1级 (大理), 2040 灭此朝食·缓行1级 (少林) | đích theo `效果作用对象` (1 = bản thân, khác = mục tiêu) [SL] |
| 840 | skill_840 | `瞬移BUFFid` | 4 | 4516 荡千军 (绝情谷), 49583 | impact thuấn di (module chỉ đọc `瞬移效果/瞬移特效`) |

Cài trong `lualib/cy_skill_extra.lua`; mỗi module vá đúng **một dòng** `pcall(require("cy_skill_extra").apply, …)`.
Chống áp hai lần: `cy_skill_extra` tự bỏ qua khi logic của chiêu có dòng trong `cy_skill_logic_spec` (`瞬移BUFFid` cũng xuất hiện ở logic 841, `给自己的buff` ở logic 206 — hai logic này do `skill_cy_spec` lo).

## 6. Áp server, restart, kiểm live

- Áp: `skill_logic.py apply` → **9 file** đổi; commit `07369ff`; lượt bổ sung (logic 884) `dffe28c`. Git R sạch sau mỗi lần.
- `verify` trên chính R: `luac` sạch, 75/75 logic đăng ký, 0 trùng module, 5 dấu vá đủ, test 21/21.
- **Không tự restart** (lệnh điều phối): xin gộp lượt với `impact-data`.
- Hoàn tác: `git -C /home/ubuntu/cys-test-20260913 revert 265b531 1ef0d81 97813ec dffe28c 07369ff` rồi restart; hoặc chép lại `R/backups/skill-logic-2026091*Z/`.

(Bảng trước/sau của kiểm live: mục 7, điền sau khi restart.)

## 7. Kiểm live **[DK]**

Cách đo giữ nguyên của `menpai-audit` (`scripts\30-live.ps1` = bản chép của `menpai_audit\20-live.ps1`, chỉ đổi thư mục ra + nhãn khoá `skill-logic`): mỗi lượt đặt lại phái/tâm pháp cấp 30/HP/MP của CYTest00 → `CysNetBot --mode world --xinfa 1 --record 1 --cast S,0 --hunt 45,152` (Vô Lượng Sơn) → đọc log Game2 đúng phiên.
6 lượt, 10:01–10:24 (luân phiên khoá `Build\test00.lock` với `menpai-audit`/`menpai-verify`; 1 lần bị `login refused` do phiên agent khác chưa đóng, runner tự chờ 180 s).
Kết quả (`scripts\31-compare.md`, bảng thô `skill-logic-results.tsv`, fixture `skill-logic\m*\`):

| phái | chiêu | logic | TRƯỚC (menpai-audit 15/09) | SAU (16/09) | gửi | gói sát thương | máu gây | buff | traceback |
|---|---|---|---|---|---|---|---|---|---|
| 大理 | 821 少商剑·刃影 | 204 | lỗi server (tb 12) | **chạy** | 32 | 7 | 0 | 2/2 | **0** |
| 大理 | 822 少冲剑·刃影 | 206 | lỗi server (tb 14) | **chạy** (1 lần tung → giết mục tiêu, buff lên mục tiêu) | 1 | 2 | 1 | 4/2 | **0** |
| 大理 | 826 中冲剑·刃影 | 208 | lỗi server (tb 18) | **chạy** | 35 | 10 | 0 | 2/2 | **0** |
| 恶人谷 | 4630 百倍奉还 | 865 | lỗi server (tb 18) | **chạy** (1 lần tung → giết) | 1 | 2 | 1 | 2/2 | **0** |
| 桃花岛 | 3800 雅颂之音 | 801 | lỗi server (tb 3) | **chạy** (giết; **thêm buff tự thân** = ô `生效一次的效果(自己)` 45170 nay đi đúng bản thân) | 1 | 3 | 2 | 3/3 | **0** |
| 桃花岛 | 3808 秦皇东遣 | 794 | lỗi server (tb 9) | **chạy** (buff tự thân 4332/4333 ×4 = `\|生效一次自己附加效果2/3`, trước không có) | 4 | 4 | 0 | **18/18** (trước 2/2) | **0** |

**6/6 chuyển từ "lỗi server" sang "chạy"; 0 traceback ở cả 6 phiên** (trước: 3–18 traceback mỗi phiên). Log Game2 từ restart 09:54:48: **0 traceback**.
Giới hạn của phép đo: 821/826 vẫn `OR −5 ×31–34` (CYTest00 cấp 15 hết khí sau 1–2 lần tung chiêu 大理 105–120 khí) nên chưa so được số sát thương; quái Vô Lượng Sơn chỉ 18 HP nên mọi đòn đều ghi 18 (như menpai-audit đã ghi).
CYTest00 trả nguyên trạng 10:24:40 (`restore rc=0 move rc=0`): phái 9, tâm pháp rỗng, kỹ năng gốc, cảnh 2 (160,150). Khoá đã nhả.

## 9. Sát thương "N % đòn ĐÁNH THƯỜNG" — logic impact 115 **[DK mã CY]**

Việc do người điều phối chuyển sang từ `impact-data` (nhóm A của `Build\Logs6-09-16-impact-data&-need-source.txt`):
nhiều chiêu CY ghi "造成100%普通攻击伤害" / "普通攻击45%/70%/95%的伤害", nhưng `std_impact_003` chỉ nhận
điểm công (`物理攻击+`…) và sát thương thẳng.

**Kết luận:** CY KHÔNG diễn đạt việc này bằng một ô tham số của StandardImpact, và cũng không bằng
`SkillLogic_T::RefixPowerByRate` do kỹ năng gọi. Nó là **một dòng StandardImpact riêng mang 逻辑ID = 115**,
tham số 0 = `伤害量缩放系数`.

| Hàm CY (tlbb15 Server) | VA | Việc |
|---|---|---|
| `StdImpact115_T::InitFromData` | 0xa5f204 | `imp[+0x2c] = round(修正步长0 × cấp) + 参数值0`; `+0x2c` là ô sát thương ĐẦU TIÊN của `_OWN_IMPACT` — đúng ô mà `StdImpact003_T::RefixPowerByRate` @0xa440c8 nhân với `(100+rate)/100` |
| `StdImpact115_T::OnActive` | 0xa5f2f8 | mục tiêu còn sống + có cảnh → tìm người gây theo `imp[+0x0c]`, loại phải ∈ human/pet/monster (`(type−1) u< 3`) → `ImpactCore::InitImpactFromData(core, **DataIndex 0**, &newImp, mục_tiêu, 0)` → nếu `newImp.逻辑ID == 3` thì `CombatCore::Reset` + `GetResultImpact(cc, người_gây, mục_tiêu, &newImp, 0x64)` → `newImp[+8] = imp[+8]` (ID kỹ năng) → `EventCore::RegisterImpactEvent(cảnh, mục_tiêu, người_gây, &newImp, 0, −1)` |
| `StdImpact115_T::IsOverTimed` / `::IsIntervaled` | 0xa5f538 / 0xa5f53e | cả hai `mov eax,0; ret` → hiệu ứng tức thời |

DataIndex 0 của StandardImpact chính là dòng `普通攻击的伤害效果， 这一行永远不能删除或者改变.这是缺省效果`.
Tháo mã (chỉ đọc file, không chạy binary): `Build
e\skill-logic\stdimpact115_init.asm.txt`, `stdimpact115_onactive.asm.txt`,
`stdimpact115_onactive2.asm.txt`, `stdimpact115_flags.asm.txt` (script `scripts!-asm.sh`, offset = VA − 0x3F0000).

**Trước lượt này:** 115 không có trong `impactenginer.id_logic_module` → rơi về `std_impact_003`; dòng 115
không có ô `攻击/伤害` nào nên gây **0 sát thương**.
**Nay:** `services/scene/skill/impact_logic/std_impact_115.lua` + đăng ký `[115]` trong `impactenginer`.

[SL] một bước: bản tlbb15 truyền **hằng 100** cho `GetResultImpact` và không đọc lại `imp[+0x2c]` trong bốn
phương thức của lớp. Bản port áp `伤害量缩放系数` bằng đúng phép nhân của `RefixPowerByRate`
(`add_rate_params(ô, hệ_số − 100)`), vì dữ liệu CY đổi hệ số theo cấp (撼岳群攻效果 43918–43923 =
100/110/125/145/170/200) và tip ghi rõ "N % 普通攻击伤害". Hệ số 100 cho kết quả **trùng khít** tlbb15.

**Cách dùng (phần dữ liệu, thuộc `impact-data`):** ô impact của chiêu trỏ tới một dòng StandardImpact có
`逻辑ID = 115`, `参数0说明 = 伤害量缩放系数`, `参数值 = N`, `是否是持续性效果 = 0`; dòng phải được áp lên
**MỤC TIÊU** (ô `生效一次的效果(目标)` / `附加效果N`), không phải ô `自己`.
Ngoại lệ: 恶人谷 魂离魄散 (logic kỹ năng 867) đã có `一/二/三魂倍率百分比` ngay trong SkillData và
`skill_cy_spec` nhân đúng theo `RefixPowerByRate` — không cần dòng 115.

### Kiểm live (sau khi `impact-data` đổi 65 ô sang dòng 115) **[DK]**

Hai lượt bot 11:48–11:53 (cách đo như mục 7), server `18f4040`:

| chiêu | ô | hệ số | kết quả |
|---|---|---|---|
| 绝情谷 4538 宁鸣不默 (cấp 1) | `生效一次的效果(目标)` 49877 | 70 | 1 lần tung → **sát thương → giết mục tiêu**, `GCCharDirectImpact` **370**, tb 0. `OR −44 ×36` là đúng CY: bot có 0 刀意 nên phần lớn lần tung bị chặn (điều kiện 17) |
| 大理 822 少冲剑·刃影 | `附加效果1` 56867 | 100 | 1 lần tung → **sát thương (hội tâm) → giết**, `GCCharDirectImpact` **7 + 370**, tb 0 |

`370` là `瞬发效果ID` của **dòng 0 — 普通攻击的伤害效果**: đúng dấu vết của `std_impact_115` dựng impact
đánh thường rồi giao cho mục tiêu. Lượt 10:12 (trước khi có dòng 115) chiêu 822 chỉ có
`direct_impacts [1, 7]`, không có 370.
Log Game2 sau restart 11:38 và sau cả hai phiên: **0 traceback, 0 `unmapped positional impact`,
0 `serialize can't pack too depth table`**.
Giới hạn: quái Vô Lượng Sơn chỉ 18 HP nên chưa so được **số** sát thương giữa hệ số 70 và 100.

## 10. Sửa `unmapped positional impact` của `cy_four_combat` **[DK]**

Việc gấp do người điều phối giao (16/09, sau khi `impact-data` áp bảng impact mới).

**Triệu chứng:** log Game2 có traceback cả lúc **đăng nhập** lẫn lúc dùng chiêu:
`./lualib/cy_four_combat/engine.lua:67: unmapped positional impact` ←
`engine.lua:112 critical_damage_bonus` ← `character.lua:1503 on_impact_activated` ←
`character.lua:1441 register_impact` ← `db/impact_data.lua:23 init_from_db_data` ← `human.lua:115 ctor`
← `scenecore.lua:1039 player_enter_scene`. Hệ quả: bot vào cảnh báo `no GCEnterScene after CGEnterScene`.

**Nguyên nhân:** `engine.lua:67` làm `assert(self.config.impacts[imp:get_data_index()], …)`, nên MỌI dòng
StandardImpact có `逻辑ID ≥ 8000` (nhóm donor cy_four) phải có mục trong
`lualib/cy_four_combat/native_config.lua` bảng `impacts={}`. `impact-data` thêm 158 dòng mới (nhân bản
dòng CY đã có) — số dòng `逻辑ID ≥ 8000` đi từ **245 → 403** (đo lại ở mốc `6ca25a8`) — nhưng bảng
positional vẫn 238 mục.

**Cách sửa:** `impacts[id_mới] = descriptor của dòng mẫu, chép NGUYÊN` (`donor_id`, `donor_logic`,
`step0`, `params`). 238 → **396 mục**.
**Không** dựng `params` từ ô `参数值` thô của bảng: bộ sinh `native_config` đã phân giải các ô kiểu
"ID hiệu ứng" sang ID phía native — `[4465].params[2] = 60958` trong khi bảng ghi `4555`; dựng lại từ
bảng sẽ làm nhóm 战可得威 (4465–4476) trỏ sai hiệu ứng.

**Kiểm bằng dữ liệu trước khi áp** (`Tools/server/cyfour_map.py check`): 158/158 dòng mới đúng là bản
nhân bản của dòng mẫu trong chính bảng — cùng `逻辑ID` (= 8000 + `donor_logic`), cùng 16 ô `参数值`,
cùng `修正步长` → **0 cảnh báo**; kiểm mẫu tay 7 cặp bằng `scripts/43-spotcheck.py`.
`verify`: `cyfour_unmapped = 0`, 158/158 mục mới trùng khít descriptor dòng mẫu, `luac5.4 -p` sạch,
`lua5.4 dofile` nạp được 396 mục. Sao lưu `R/backups/cyfour-map-20260916T041221Z/`. Server `097a7fc`.

**Còn lại (không thuộc lượt này):** 7 dòng cy_four vẫn không có mục positional — 4079, 4251, 4260, 4347,
4400, 4543, 4549. Đã kiểm ở mốc `6ca25a8`: chúng **đã thiếu từ trước**, cùng `逻辑ID` 8038/8168, thuộc
đường "literal impacts" của `guigu.lua`/`tao.lua` (`make_impact` coi logic 8038 là "verified native
marker", không gọi `bridge:state`) nên không gây assert.

## 11. Hai lỗi làm RỚT NGƯỜI CHƠI trên đường `cy_four_combat` **[DK]** — đừng đặt lại

### 11.1 `unmapped positional impact` → nhân vật không đăng nhập được

**Triệu chứng:** `./lualib/cy_four_combat/engine.lua:67: unmapped positional impact`, ngay trong
`human.ctor → db/impact_data.lua:23 init_from_db_data → character:register_impact →
character:on_impact_activated → engine.lua:114 mark_modified_attr_dirty → engine.lua:112
critical_damage_bonus → engine.lua:67 bridge:state`. Bot báo `no GCEnterScene after CGEnterScene`.
Nhân vật mang buff (kể cả **đã hết hạn**) trỏ tới Data_Index không có mô tả positional thì **kẹt đăng nhập**.

**CY làm gì:** `Combat_Module::Impact_Module::ImpactCore_T::InitImpactFromData` @0xa87fee
(`Build
e\skill-logic\impactcore_initfromdata*.asm.txt`):

```
imp[+4] = dataIndex ; imp[+0x24] = level
pData = GetImpactData(dataIndex)      ; call 0xa87ee6
if (pData == NULL) return 0;          ; @0xa88080 je → @0xa880b6  mov eax,0 ; ret
logic = GetLogic(&imp)                ; call 0xa43425
if (logic == NULL) return 0;          ; @0xa8809b je → @0xa880c2  mov eax,0
return logic->Init(&imp, pData) == 1;
```

Người gọi **kiểm giá trị trả về rồi bỏ qua** (vd `StdImpact115_T::OnActive` @0xa5f415 `test eax,eax; jne`).
⇒ CY **bỏ qua** impact không có mô tả, **không dừng chương trình**. CY cũng không có bước "lọc buff hết hạn"
riêng: chính bước dựng impact đã loại những dòng không tra được.

**Bản sửa (server `18f4040`):**
- `cy_four_combat/engine.lua`: `bridge:descriptor(imp)` tra mô tả, ghi log **một lần cho mỗi data_index**;
  `bridge:state` trả **nil** thay vì `assert`; mọi phương thức do `make_impact` sinh ra được bọc để khi
  thiếu mô tả thì trả **giá trị trung tính**: `critical_damage_bonus` → giữ `point`,
  `on_final_damage(_target)` → giữ `damage`, `continuance_cal` → rơi về `base`, `add_new_trap` → `false`,
  `get_trap_count_of_specific_type` → `0`, `refix_power_by_rate` → `false`, còn lại → `nil`.
- `lualib/db/impact_data.lua`: bỏ buff lưu sẵn mà `data_index` **không còn dòng StandardImpact** — đúng
  nhánh `GetImpactData == NULL → return 0` của CY (bảng impact đổi thì buff cũ thành rác).

### 11.2 `serialize can't pack too depth table` → msgagent bị giết, client rớt giữa phiên

**Triệu chứng:** `./services/scene/scene.lua:26: serialize can't pack too depth table` rồi
`[:xxxx] KILL self` của msgagent. Xuất hiện **lần đầu ở log `Game2_20260916_111346`**, mọi log trước đó 0 lần.

**Nguyên nhân:** `engine.lua` lưu `imp._cy_four_native = state` trong khi `state.engine_impact = imp`
→ **vòng tham chiếu**. `human:get_save_data()` đóng gói `impacts:get_list()` — **chính các đối tượng
impact sống** — và `ma_func:message_update` gọi `skynet.call(scene, "get_my_save_data", …)` mỗi 300 nhịp,
nên skynet pack đi vòng vô hạn. Trước đây không lộ vì các impact dính bridge hiếm khi nằm trên nhân vật;
sau khi ánh xạ thêm 158 dòng (`097a7fc`) thì buff 唐门/桃花岛 thường trực chạm đúng đường này.

**Bản sửa:** trạng thái native để ở `lualib/cy_four_combat/state_cache.lua` — bảng phụ **khoá yếu**
(`__mode = "k"`), ngoài đối tượng impact. `engine.lua` đọc/ghi qua đó, `jue_cast_guard.lua` đọc qua đó,
`services/scene/skill/impact.lua:clean_up` xoá qua đó. Đồ thị của impact lại **phẳng** nên đóng gói được;
`state.engine_impact` vẫn giữ (runtime_adapter cần) mà không tạo vòng.

**Kiểm:** `Tools/server/cyfour_guard_tests.lua` 10/10 — trong đó có ca đo **độ sâu đồ thị** của impact để
bắt lại vòng tham chiếu nếu ai đó khôi phục cách cũ, và ca "thiếu mô tả → native KHÔNG được gọi".
Ca kiểm thử thật: 9 data_index nằm trên CYTest00 (`scripts/48-case9.py`) — chỉ 37561 (震箭式, `逻辑ID` 8148)
đi qua `bridge:state`; 8 mục còn lại có `逻辑ID` 13/26/59/60/65/72 nên không chạm bridge.

## 8. Bẫy

- `LogicManager_T<SkillLogic_T,691>::Init` đánh số **từ 1**; `logic_id = chỉ số − 1`. Lấy nhầm sẽ lệch một ô (vd tưởng `WuDangSkill001_T` là logic 111 trong khi nó là 110).
- CY 3.71 **mới hơn** tlbb15: đừng kỳ vọng có mã native cho logic ≥ 142 (trừ 792–794 trong hook).
- `class.lua` (`luaclass`) chỉ chép **hàm** của lớp cha → mọi lớp con của `skill_0`/`skill_cy_generic` phải tự chép các trường (`IMPACT_NUMBER`…). `skill_cy_spec` chép lại từ cả hai lớp cha.
- `skill:effect_on_unit_once` được gọi **cho từng mục tiêu**; ô "cho bản thân" phải có cờ chỉ-một-lần, nếu không chiêu AOE sẽ áp N lần.
- Lua của server là **UTF-8**; chỉ `configs/*.txt` mới là GBK (đọc nhầm sẽ ra mojibake).
- Nhãn `参数说明` phải khớp **từng ký tự** (kể cả `（）` full-width và dấu `|` đầu nhãn) — sai là ô im lặng không chạy; dùng `scripts\04-check-spec.py` để kiểm.
- `SectInfo.txt` cột 3 là số phái **GL/HJS** (ERenGu 11), khác số phái CY của `SkillTemplate`/`get_menpai()` (恶人谷 15).
- **Đừng đặt lại `assert` trong `cy_four_combat/engine.lua:state`** và **đừng gắn trạng thái native lên đối tượng impact** — xem mục 11, cả hai đều làm rớt người chơi thật.
- Thêm dòng StandardImpact có `逻辑ID ≥ 8000` mà quên mục trong `cy_four_combat/native_config.lua impacts={}` → **sập lúc đăng nhập** (`engine.lua:67 unmapped positional impact`), không chỉ lúc dùng chiêu.
- `params` trong `native_config` KHÔNG phải ô `参数值` thô của bảng (ô kiểu "ID hiệu ứng" đã được phân giải sang ID native) — đừng dựng lại từ bảng.
- Gọi `wsl.exe` từ Git Bash bị chặn/đổi đường dẫn → chạy qua PowerShell, hoặc đặt lệnh vào file `.sh` rồi `wsl.exe -- bash <file>`.

## 12. skill-summon (17/09/2026) — THỰC THỂ TRIỆU HỒI cho hệ kỹ năng CY **[DK]**

Agent `skill-summon`. Bằng chứng: `Build\Logs\2026-09-17-skill-summon\` (`scripts\01-check-summon.py` +
`11-check-summon.txt` = kiểm nhãn/ID quái/ID impact; `10-verify-server.json` = `skill_logic.py verify` trên R;
`12-server-git-status.txt`). Mã: `Tools\server\skill_logic_lua\GameServer\lualib\cy_skill_summon.lua` (mới),
`...\services\scene\skill\human\skill_cy_spec.lua` (+ khối `summon`), `...\lualib\cy_skill_logic_spec.lua`,
`Tools\server\skill_logic_tests.lua` (+16 ca → 40/40).

### 12.1 Vì sao làm được — đường đi đã có sẵn trên server riêng **[DK]**

Mục 3 xếp 星阵 / 图腾 / 召唤 vào nhóm "cần thực thể native chưa có". Đo lại thì **đủ API**:

| API | Nơi | Việc |
|---|---|---|
| `scenecore:create_temp_monster(monster_id, x, y, base_ai, ai_script, script_id, param_dir)` | `services/scene/scenecore.lua:849` | trả `obj_id`; thiếu dòng `MonsterAttrEx` thì `create_monster_data` trả **nil** (không ném) |
| `monster:set_temp_camp_id / set_die_time / mark_unbreakable_flag / set_unconstrained_monster / set_attrib{hp_max} / set_name` | `services/scene/obj/monster.lua` | phe, vòng đời, "không đánh được", chạy được trong MAIN_CITY, máu, tên |
| `monster:update` gọi `scene:delete_temp_monster(self)` khi `die_timer` hết | `obj/monster.lua:70–97` | vòng đời tự dọn, không cần timer toàn cục |
| `cy_four_combat/summon_runtime.lua` | đã chạy thật cho 鬼谷 星阵 / 桃花岛 傀儡 | mẫu "bọc `obj.update` của chính thực thể + tự xoá khi chủ biến mất" |

`cy_skill_summon.lua` làm y hệt `summon_runtime` nhưng **độc lập và bọc `pcall` toàn bộ** — `summon_runtime`
dùng `assert`, mà một `assert` trên đường kỹ năng gây đúng lỗi "trừ MP, đặt hồi chiêu rồi sập" của mục 8.

### 12.2 Mô hình: thực thể là MỐC NEO, người đánh vẫn là CHỦ **[DK + SL]**

**[DK]** Mọi quái triệu hồi của CY trong `MonsterAttrExTable` có `友好值 = 0`
(1499 蜀山狂猿, 16935 诸葛神弩, 16936–16938 枢甲造物, 16944 毒蟾). Với `reputation = 0`:
`monster:is_enemy` (`obj/monster.lua:344`) trả **false** ngay, và `human:is_enemy(monster)`
(`obj/human.lua:4990`) cũng trả **false**. ⇒ engine coi thực thể là trung lập **hai chiều**:
không ai đánh được nó (đúng tip "狂猿无法被攻击"), và nó cũng không tự chọn mục tiêu.

**[SL]** Vì vậy bản port **không** cố nhồi thuộc tính người triệu hồi vào con quái (CY làm thế trong native).
Thay vào đó:

- quan hệ địch/ta tính bằng `owner:is_enemy(nb)` — đúng nghĩa "mục tiêu địch **của người triệu hồi**" của tip;
- sát thương ghi cho **CHỦ** và tính bằng **"N % đòn ĐÁNH THƯỜNG"** — dùng lại đúng cơ chế đã bẻ ở mục 9
  (`StdImpact115_T::OnActive` @0xa5f2f8): dựng impact từ `StandardImpact` **DataIndex 0**
  (`普通攻击的伤害效果`) → `CombatCore:get_result_impact(chủ, mục_tiêu, imp)` →
  `std_impact_003.refix_power_by_rate(imp, N − 100)` → `std_impact_003.on_active`.
  Không có công thức tự chế; N lấy từ tip CY của chính chiêu đó.
- `set_temp_camp_id(owner:get_camp_id())` để thực thể không bao giờ thành địch của chủ
  (`character:calc_relation_type` @`obj/character.lua:3331` cho monster ↔ human cùng phe = FRIEND).

Vòng đời: `set_die_time(life)`; ngoài ra mỗi nhịp kiểm `owner_alive(tag)` (chủ còn đúng `obj_id`, cùng cảnh,
còn sống) — sai thì `set_die_time(1)`. Trần cứng `MAX_LIFE_MS = 60000`. Mỗi chiêu có `key` riêng nên tung lại
thu hồi con cũ trước khi tạo con mới. Bảng `registry` khoá yếu hai tầng (bẫy mục 11.2).

Điểm gọi: `skill_cy_spec:activate_once` (**một lần mỗi lần tung**), **không** phải `effect_on_unit_once` —
`skill:activate_once` (`scene/skill/base.lua:337`) bỏ qua nhánh hiệu ứng khi `target_count == 0`, mà
诸葛神弩 (目标逻辑 7) hoàn toàn có thể đặt ở chỗ không có ai.

### 12.3 Bốn logic đã cài **[DK nhãn/tip, số dòng ở `01-check-summon.json`]**

| Logic | Template | Quái | Cài | Còn thiếu |
|---|---|---|---|---|
| **886** 狂猿凌峰 | 407 (峨嵋, cấp 4) | 1499 蜀山狂猿 | SkillData 17621 **không có ô tham số nào** → mọi số từ tip: 15 s, mỗi **1,2 s** (= `攻击动作时间` của chính dòng 1499) đánh 1 địch của chủ trong **15 m quanh CHỦ**, **20 %** đòn đánh thường ("具有召唤者20%四种属性攻击"), toàn bộ sát thương **hồi máu cho chủ** (đo bằng chênh lệch HP thật của mục tiêu) | 100 % 四种减抗 + 20 % 穿刺 (CY trộn vào chính con quái) |
| **730** 诸葛神弩 | 4468 (唐门, cấp 4) | `图腾id` = 16935 | đặt ở **điểm client gửi**, máu = `图腾血量` (9000), `无敌效果id` (37922) áp lên **CHÍNH tháp**, 15 s, mỗi **0,4 s** bắn 1 địch trong 15 m với **25 %** đòn đánh thường | 20 % xác suất cộng lớp 会心+2 % cho chủ — SkillData không có ID hiệu ứng. **Dòng StandardImpact 37922 chưa có trên server** (xem 12.5) |
| **731** 千机变 | 2922 (唐门, cấp 4) | `图腾id1/2/3` = 16936/16937/16938 | giữ `延迟buff` + `免疫控制buff`; chọn **ngẫu nhiên 1** con (đúng "随机设置1种枢甲造物"), đặt cạnh mục tiêu, máu theo `图腾血量N` (9000/9000/16000), **3 s** sau mới kích hoạt, rồi mỗi 2 s gây **80/100/150 %** đòn đánh thường cho tối đa **3** địch trong **4 m** | thực thể **di chuyển** tới mục tiêu rồi mới nổ; ba hiệu ứng riêng (撕裂/鸩羽/赤练) không có ID trong SkillData; dòng impact 37920 chưa có |
| **174** 毒蟾功 | 435 (星宿, cấp 4) | `召唤物` = 16944 | giữ `失明buff`; 毒蟾 nhảy tới mục tiêu, mỗi giây **50 %** đòn đánh thường cho tối đa **6** địch trong **5 m**, 9 s | đổi mục tiêu 3 lần + tiến hoá 2 lần (cần dời thực thể và đổi model) |

Kèm theo (không phải triệu hồi, cùng lượt): 795 / 799 / 800 / 803 桃花岛 nay neo vào **vị trí con rối 离人偶**
(`around = 'doll'` / `at = 'doll'` → `cy_four_combat.callbacks.get_doll_id`), thay vì quét quanh chính người chơi.
Không có con rối thì rơi về chỗ đứng của chủ như trước. Đây đúng chỗ `cy_four_combat/release.lua:36` đã làm cho
danh sách mục tiêu chính của 3820; trước lượt này chỉ riêng khối AOE còn lệch tâm.

### 12.4 Nhánh DỪNG — 761–766 星阵 (鬼谷): đã có ở tầng khác, thêm nữa là nhân đôi **[DK]**

`02-labels.json` cho thấy logic 761/762/763/764/765 ứng đúng template **3438 / 3439 / 3447 / 3451 / 3453**.
Đó **chính xác** là tập `target_skills` của `lualib/cy_four_combat/guigu_installation.lua:34`
(`GuiGu.profiles[*].skill`), và đường spawn của nó đang **sống**:
`services/scene/obj/character.lua:1054` → `cy_four_combat.hooks.on_use_skill_successfully` →
`phase2.lua:54` (faction 12) → `guigu_installation` → `summon_runtime.spawn`, với
`phase2_config.resolve.monsters` = `{16916, 16917, 16918, 16927, 16928, 17097}` và
`deployment_config.gameplay_enabled = true`.

⇒ Thêm khối `summon` cho 761–765 trong `cy_skill_logic_spec` sẽ ra **HAI 星阵 mỗi lần tung**. Không làm.
766 (3539/3540) và 770 请星入命 phụ thuộc cùng hệ 星阵 nên cũng để nguyên ở tầng `cy_four_combat`.

Tương tự, `tao.native_skills = {3801, 3804, 3809, 3820, 3822}` (桃花岛) do `cy_four_combat.tao` lo phần
tạo/thu con rối; lượt này **chỉ đổi tâm quét**, không tạo thêm thực thể nào cho 桃花岛.

### 12.5 Giới hạn của phép đo và việc còn lại

- **Chưa đo live.** Toàn bộ kết quả là `luac5.4 -p` sạch + 40/40 test đơn vị (`skill_logic_tests.lua`, có giả lập
  `create_temp_monster`). Cần restart server rồi đo 4 chiêu: **407** (峨嵋), **4468** và **2922** (唐门), **435** (星宿).
- `StandardImpact` của server **thiếu dòng 37922** (`无敌效果id` của 730) và **37920** (`免疫控制buff` của 731).
  `init_impact_from_data` trả false ⇒ ô im lặng không chạy, **không** ném lỗi. Việc nhập hai dòng này thuộc
  `impact-data`/`trap-impacts`. Hiện chưa ảnh hưởng: thực thể có `友好值 = 0` nên vốn đã không bị đánh.
- Sát thương mỗi nhịp **không** đánh dấu hội tâm (`critical = false`) — CY có hội tâm cho 神弩; cần nguồn xác suất.
- Chưa dựng chuyển động cho 枢甲造物 (731) và 毒蟾 (174). `character:on_teleport(world_pos)` có sẵn nếu sau này
  muốn cho thực thể "nhảy" tới mục tiêu mới.

### 12.6 Bẫy mới

- Thực thể triệu hồi **không** tự đánh ai: `友好值 = 0` trong `MonsterAttrExTable` chặn `is_enemy` cả hai chiều.
  Đừng "sửa" bằng cách đặt `reputation` khác 0 — mất luôn tính chất "không bị đánh" của CY, và quái sẽ đánh cả
  người chơi khác phe. Hãy để CHỦ là người quét mục tiêu và người gây sát thương.
- Nếu không gọi `set_unconstrained_monster(true)`, `monster:update` **bỏ qua** quái trong `define.MAIN_CITY`
  (`obj/monster.lua:70`) ⇒ thực thể đứng hình trong thành, nhịp không chạy.
- `create_temp_monster` **không ném lỗi** khi thiếu dòng `MonsterAttrEx`; nó trả `nil`. Luôn kiểm giá trị trả về.
- Triệu hồi phải nằm ở `activate_once`, KHÔNG ở `effect_on_unit_once` — chiêu 目标逻辑 7 không trúng ai thì
  `effect_on_unit_once` không bao giờ chạy, còn chiêu AOE thì sẽ tạo N thực thể.
- Trước khi thêm summon cho một logic, kiểm xem template của nó có nằm trong `guigu_installation` target_skills
  hay `tao.native_skills` không — `cy_four_combat` đã dựng thực thể cho những template đó.

## 13. skill-logic-3 (17/09/2026) — CÀI NỐT PHẦN DỞ CỦA CÁC LOGIC `partial` **[DK]**

Agent `skill-logic-3`. Bằng chứng: `Build\Logs\2026-09-17-skill-logic-3\` (`scripts\01-check.py` + `12-check-data.txt`
= dữ kiện bảng thật; `scripts\02-check-spec3.py` + `11-check-spec3.txt` = kiểm **265/265** nhãn đặc tả;
`10-verify-server.json` = `skill_logic.py verify` trên R; `13-server-git-status.txt`; `scripts\90-evidence.sh` chạy lại được).
Mã: `Tools\server\skill_logic_lua\GameServer\lualib\cy_skill_chain.lua` (**mới**),
`...\services\scene\skill\impact_logic\std_impact_171.lua` (**mới**), `...\lualib\cy_skill_logic_spec.lua`,
`...\services\scene\skill\human\skill_cy_spec.lua`, `Tools\server\skill_logic.py`,
`Tools\server\skill_logic_tests.lua` (+15 ca → **55/55**).

### 13.1 Vì sao trạng thái KHÔNG được để trên `self` của lớp logic **[DK]**

`skillenginer:register_all_skill_logics` (`lualib/skillenginer.lua:576`) tạo **một** đối tượng cho mỗi 技能逻辑ID
(`self.skill_logics[skill.logic_id] = mod.new()`) và dùng chung cho **cả cảnh**. `self._first_once` cũ an toàn vì chỉ
sống trong một lời gọi đồng bộ; nhưng chuỗi lan (769) phải nhớ danh sách mắt xích **qua nhiều nhịp** ⇒ trạng thái
nằm trong `lualib/cy_skill_chain.lua`, bảng `chains` **khoá yếu theo chủ** (không gắn vào đối tượng impact — bẫy 11.2).

### 13.2 769 火烧连营 (鬼谷 3441) — chuỗi lan theo NHỊP DẪN của chính engine **[DK]**

| Dữ kiện | Nguồn |
|---|---|
| Bảy ô 主/二/三/四/五/六/七目标伤害 = **59170–59176**, đều `逻辑ID 115` với `伤害量缩放系数` = **80/100/120/140/160/180/200** | `configs/StandardImpact.txt` (trap-impacts đợt 3, `cd22aab`) |
| Nhịp 0,8 s là của **engine**: SkillTemplate 3441 `连续攻击次数或引导的时间间隔(ms)` = **800**, `技能类型` = 1 (chiêu dẫn 8 s) | `configs/SkillTemplate_V1.txt` |
| Cự ly đứt dây `主目标断线距离` 15 m, `其它目标断线距离` 7 m; tối đa nối thêm 6 (tổng 7 = số nấc) | `参数值` + tip của cả 16 dòng |

⇒ **Không dùng `skynet.timeout` cho chuỗi này.** `channel_action.lua:24` → `skill:action_active_each_tick_handler`
→ `skill:activate_each_tick` (`scene/skill/base.lua:380`) đã gọi `effect_on_unit_each_tick` đúng **mỗi 800 ms** và tự
dừng khi ngắt dẫn / chủ chết / mục tiêu biến mất — dùng lại nó thì không có hai nguồn nhịp và không có timer mồ côi.
Nấc = **THỨ TỰ NỐI** (mắt thứ n chịu dòng 59169+n), không phải số nhịp: đó là cách duy nhất khớp cả tip
("伤害依序递增20%") lẫn dãy 80→200 của bảy dòng.
Mỗi nhịp: bỏ mắt chết / xa quá `其它目标断线距离` tính từ **mục tiêu chính** → nối thêm **một** địch quanh mục tiêu chính
→ gây sát thương cho **mọi** mắt theo nấc của nó. Mục tiêu chính rời chủ quá `主目标断线距离` → **đứt cả chuỗi**.
Trần cứng: 12 nhịp (`max_ticks`), 16 mắt, xoá trạng thái khi chủ đổi cảnh/chết.
Hai ô `主目标连线` / `其它目标连线` = 59168/59169 **chưa có dòng StandardImpact** ⇒ `init_impact_from_data` trả false,
ô im lặng bỏ qua (việc của `impact-data`).

### 13.3 204 少商剑·刃影 (大理 821) — sáu phi kiếm + hệ số giảm dần **[DK tip/参数值, SL công thức]**

Cả **16/16** dòng SkillData (17328–17343) có tip "发射6把飞剑，每把飞剑随机对目标周围5米内的一名敌对目标造成伤害…
同一目标重复受到攻击时伤害逐次递减15%" và `衰减系数百分比` = 15. Trước lượt này đặc tả chỉ gửi **một** lần
`附加伤害（逻辑3）` cho mục tiêu — không có chỗ nào để "giảm dần" ⇒ khối `multi_hit` mới bắn đủ 6 đòn, mỗi đòn chọn
**ngẫu nhiên** một địch trong 5 m quanh mục tiêu (mục tiêu chính luôn nằm trong bể chọn).
**[SL]** "衰减系数" hiểu là **nhân dồn**: lần trúng thứ n của cùng một mục tiêu = `100 × 0,85^(n−1)`
(100/85/72/61/52/44), áp bằng `opt.rate` của `skill_cy_spec:send` (chỉ nhân cho impact `逻辑ID 3`). Không có mã CY
cho logic 204 để đối chiếu; cách hiểu "trừ thẳng 15 điểm" cho 100/85/70/55/40/25 — **cần đo live rồi chốt**.
Bộ đếm theo **từng mục tiêu**, sống trong một lần tung (biến cục bộ, không đặt trên `self`).

### 13.4 144 回天术 / 斩情诀 (峨嵋 411/417) — KHÔNG cần đổi danh sách kỹ năng **[DK]**

Bốn ô `|替换一段技能idN` của 411 là **411/424/426/406** (回天术, 清心普善咒, 春花秋月, 佛光普照), của 417 là
**417/404/415/421**. Ba dữ kiện làm sáng chuỗi này:

1. Các bản ·九阳 (**827/828/829/830**) và ·九阴 (**831/832/833/834**) có **cùng `心法ID`** với bản gốc
   (827↔411 xinfa 28; 828/829↔424/426 xinfa 59; 830↔406 xinfa 26…) và `技能类型按使用者划分` = 0, mà
   `human:on_study_xinfa` (`obj/human.lua:2277`) cấp **mọi** template cùng `心法ID` ⇒ người chơi **đã có sẵn** các chiêu đó.
2. SkillData của chúng có điều kiện `条件和消耗逻辑 = 0` (`C_UNIT_MUST_HAVE_IMPACT`, `define.lua:1672`) trỏ tập
   **499 回天术九阳状态** = {互斥ID 2631} / **376 斩情诀BUFF** = {互斥ID 151} (`lualib/cy_idcollections.lua`).
3. Impact mang đúng hai 互斥ID đó là **13058 九阳炽脉** và **13059 九阴煞魄** (đều `逻辑ID 171`, 20 000 ms) — và
   **0/20.667** dòng SkillData trỏ tới chúng ⇒ chính logic 144 phải phát.

⇒ Khối `state` mới phát 13058/13059 lên bản thân theo ô `|替换一段技能id1`. Hết 20 s trạng thái tự rụng ⇒ bốn chiêu
·九阳/·九阴 tự "trả lại". **Không đụng `human.skill_list`** nên không có rủi ro lưu nhầm khi người chơi thoát game
giữa chừng (đó là lý do bỏ phương án `add_skill`/`del_skill`). Đổi biểu tượng trên thanh nhanh là việc của client.

`|变身buff` (57299–57314 回天术疲劳, 互斥 13098; 57315–57330 斩情诀（伤害修正）, 互斥 151) **không** phải trạng thái
九阳 — đừng nhầm. Bản 斩情诀 tình cờ đúng 互斥 151 nên nhánh 九阴 vốn đã đủ điều kiện; nhánh 九阳 thì không.

### 13.5 Logic impact **171** — 13 dòng trạng thái đang bị bỏ rơi **[DK]**

`impactenginer.id_logic_module` không có ô 171 ⇒ `eventenginer:real_register_impact_event` thấy `imp_logic == nil` và
**thoát ngay** (`lualib/eventenginer.lua:116`): impact không bao giờ lên người, **không** báo lỗi. 13 dòng bị ảnh hưởng:
5212 五绝计时; 12931–12936 + 19515 + 57059 + 57107 + 57156 (各式刃影 — trạng thái 二式 của 大理); 13058 九阳炽脉; 13059 九阴煞魄.
Lượt này thêm `impact_logic/std_impact_171.lua`: trạng thái thuần có thời lượng (`is_over_timed = true`,
`is_intervaled = false`, như `null_logic_buff` của logic 97). **Chưa làm:** ô `参数2说明 = 下发的CD` (13058 = 4513) —
chưa có bằng chứng đó là `冷却ID` hay ID kỹ năng nên không suy.

### 13.6 149 金顶绵掌·九阴 (峨嵋 832) — hút máu theo SÁT THƯƠNG THỰC **[DK + SL]**

`|回血百分比` = 50, tip "发功期间为自身回复造成伤害一半的血量". Sát thương đến từ ô `|引导周期的附加效果1` (1402, 逻辑 3)
mỗi nhịp 1 000 ms (`SkillTemplate 832 引导间隔 = 1000`). Engine Lua đăng ký impact qua `skynet.fork`
(`eventenginer.lua:253`) nên **không có số sát thương tại chỗ** ⇒ đo bằng **chênh lệch HP** của mục tiêu: ghi HP lúc
đăng ký, `skynet.timeout(延迟时间 + 400 ms)` đo lại, hồi cho chủ 50 % phần đã mất (đúng cách
`cy_skill_summon.normal_attack` đã đo cho 886). Chỉ đo ở nhịp dẫn (`lifesteal.tick = true`) để không đếm hai lần.
**[SL]** phần máu mất trong cửa sổ 400 ms có thể lẫn sát thương của người khác lên cùng mục tiêu.

### 13.7 736 万箭齐发 (唐门 2901) — ba mức xác suất tóe **[DK]**

Tip: "受到万箭齐发伤害的目标有几率触发雷击效果，对其周围5米范围内3个敌对目标造成100%万箭齐发伤害，**最多对3个目标触发雷击**".
`触发1/2/3次溅射几率（百分比）` = 80/40/12 ⇒ duyệt **từng mục tiêu đã trúng**, lần tóe thứ k dùng mức thứ k, tối đa 3 lần
mỗi lượt (`trap.per_target` + `chance_ladder` + `max`). ID bẫy đọc từ ô `溅射效果陷阱id` **ngay lúc chạy**:
`trap-recollide` đã đổi 1980 → **3064** (16/16 dòng; `SpecialObjData` có dòng 3064) — đặc tả không ghi cứng số nào.

### 13.8 桃花岛 795/799/800 — phần còn lại, và một nhánh DỪNG **[DK]**

- **795 勒马归鞍 — DỪNG phần "thu hồi con rối"**: `cy_four_combat.tao` đã làm và đang sống
  (`tao.native_skills` có 3804; `native_config.skill_templates[3804] = 3804`; `deployment_config.gameplay_enabled = true`).
  Nhánh 3804 (`tao.lua:87`) kéo con rối về chỗ chủ (`c:charge`), tạo vật thể `special_objects[939] → 2101` tại đó rồi gửi
  impact 4372 sau 500 ms. Làm lại ở tầng `skill_cy_spec` sẽ ra **hai** lần — đúng kiểu bẫy 星阵 của mục 12.4.
  **Cần đo live:** bẫy của ô `傀儡回收后，原地留下陷阱ID` (đổi theo cấp: 3018 ở cấp 1, 1450 ở cấp 4) và vật thể 2101 của
  tao có thể là **cùng một hiệu ứng port hai lần**.
- **799 棹歌中流**: ô `生效一次给傀儡加效果` xuất hiện **hai lần** trong cùng một dòng (45493 + 45443) — nay áp **cả hai**
  và gửi cho **chính con rối** (`to = 'doll'`, không có rối thì về bản thân như trước). Ô
  `对效果1伤害的修正，效果1必须用3号伤害类BUFF` nay là hệ số của hiệu ứng 1: `rate = 100 + giá trị`
  (cấp 1 = −5 → 95 %, cấp 4 = 10 → 110 %, khớp tip "每秒造成110%的伤害").
- **800 劝君酒**: hai ô `傀儡罩子` / `傀儡连线` nay gửi cho chính con rối. Phần "kéo mục tiêu về cạnh con rối" **không**
  làm ở đây — `tao.lua:96–105` đã `c:charge` từng địch quanh con rối về tâm.

### 13.9 Giới hạn và việc còn lại

- **Chưa đo live** (không được restart). Toàn bộ kết quả là `luac5.4 -p` sạch + **55/55** test đơn vị + 265/265 nhãn khớp bảng.
  Cần restart rồi đo: **3441** 火烧连营 (鬼谷), **821** 少商剑·刃影 (大理), **411** 回天术 rồi thử dùng **827** 回天术·九阳 (峨嵋),
  **832** 金顶绵掌·九阴 (峨嵋), **2901** 万箭齐发 (唐门), **3820/3822** (桃花岛).
- 59168/59169 (`主目标连线`/`其它目标连线`) chưa có dòng StandardImpact ⇒ chuỗi 769 chạy nhưng **không có dây nối nhìn thấy**.
- Công thức giảm dần của 204 là **[SL]** (nhân dồn 0,85 hay trừ 15 điểm) — chốt bằng số đo live.
- 144: nhân vật tạo **trước** khi bảng có 827–830 có thể chưa có chiêu ·九阳 trong `skill_list` (chỉ được cấp lúc
  `on_study_xinfa`); khi đo live phải học lại tâm pháp 28/59/26 hoặc dùng GM tool cấp kỹ năng.
- Chưa làm: `驱散二式buff集合` (204), ô `下发的CD` của logic 171, và 9 logic còn lại của mục 3 + 12.4.

### 13.10 Bẫy mới

- **Đừng giữ trạng thái nhiều nhịp trên `self` của lớp logic kỹ năng** — `skillenginer` dùng chung MỘT đối tượng cho
  cả cảnh (13.1). `self._first_once` / `self._trap_n` chỉ an toàn vì sống trong một lời gọi đồng bộ và được xoá ngay sau đó.
- Thêm dòng StandardImpact với `逻辑ID` chưa đăng ký trong `impactenginer` ⇒ impact **im lặng không lên**, không lỗi:
  `eventenginer.lua:116` `if not imp_logic then return end`. Khi một buff "không thấy tác dụng", kiểm `id_logic_module` trước.
- Chiêu 引导 (`技能类型 = 1`) đã có nhịp sẵn của engine bằng ô `连续攻击次数或引导的时间间隔(ms)` — dùng nó thay vì
  `skynet.timeout` để không có hai nguồn nhịp và không có timer mồ côi khi người chơi ngắt dẫn.
- `|变身buff` của 144 **không** phải trạng thái 九阳 (57299–57314 là 回天术疲劳, 互斥 13098). Tập điều kiện 499 cần
  互斥 **2631** = impact 13058. Đọc `互斥ID` chứ đừng đoán theo tên ô.
- `human:on_study_xinfa` cấp kỹ năng theo `心法ID` **không kèm giới hạn cấp** — thêm một template mới cùng 心法ID
  nghĩa là mọi người đã học tâm pháp đó sẽ nhận nó ở lần học kế tiếp.

## 14. cy-native-12 (17/09/2026) — 14 chiêu "gửi chiêu không tác dụng": nguồn tác dụng ở đâu **[DK]**

Agent `cy-native-12`. Việc **dịch ngược + lập đặc tả, không sửa server**.
Đầu vào: `Build\Logs\2026-09-17-coord\81-o-rong-khong-phai-loi-nhap.md` + `80-con-lai.tsv`
(đã chứng minh các ô `参数说明`/`参数值` trên server **trùng từng ký tự** với bảng CY).
Bằng chứng thô: `Build\re\cy-native-12\` (20 file). Kết luận từng chiêu:
`Build\Logs\2026-09-17-cy-native-12\ket-luan.tsv` + `README_vi.md`.

### 14.0 Kết quả

14/14 chiêu đã xác định được nguồn tác dụng; **không chiêu nào cần một cơ chế CY hoàn toàn mới chưa biết**.
Chúng gom vào 5 nhóm; nhóm lớn nhất hoá ra **không phải chiêu thật**.

| Nhóm | Chiêu | Loại | Việc |
|---|---|---|---|
| 1. Bản sao "未学习" | 3559, 3557, 3558 | e | không cài gì |
| 2. Ngòi nổ bẫy | 531, 4465, 4466 | d | kịch bản 2 chiêu; 4465/4466 chờ logic 736 |
| 3. Trạng thái 状态 | 2912, 3446, 3812, 3816 | a / b | 2 logic impact mới (8038, 8167), 1 nhãn `命中+`, 1 truy vết |
| 4. Native ghi cứng thực thể | 4516 | b | hằng số bẫy 2102 |
| 5. Đủ dữ liệu, thiếu điều kiện đo | 347, 374, 2905 | e | đo lại |

### 14.1 `3557` / `3558` / `3559` **không phải chiêu** — là mục "chưa học" của bảng kỹ năng **[DK]**

Ba template liền nhau 3557–3559 là **bản sao rỗng** của chiêu thật cùng tên: mọi trường sao y
(`门派`, `目标选择逻辑`, `范围半径`, `范围搜索的目标个数`, `冷却ID`, tiêu hao khí), riêng **cả bốn ô impact
bị đặt −1** nên tung ra không làm gì.

| rỗng | thật | dòng SkillData của bản thật |
|---|---|---|
| 3557 金针渡劫 (SD 31581–31596) | **423** | SD1985 → impact 2761 「金针渡劫(复活)」 logic 4 (HP+6 %, MP+6 %) |
| 3558 柳暗花明 (SD 31597–31612) | **514** | SD3077 → impact 2785 「柳暗花明(隐身)」 logic 14 (隐身 55, −20 % tốc độ, 30 s) |
| 3559 灭此朝食 (SD 31613–31628) | **304** | SD557 → impact 2809 「灭此朝食（嘲讽）」 logic 74 + 17441 (giảm tốc, logic 14) |

Dấu nhận biết chắc chắn nằm trong ô `技能描述(FOR TIP)` của các dòng rỗng — chúng mở đầu bằng
`#cFF0000未学习#r#G学习指引：…` (chữ **未学习** màu đỏ + chỉ dẫn nhận nhiệm vụ để học). Trong cùng khối,
`3566–3575 诛仙万象` cũng là 10 bản sao rỗng cùng kiểu (`Build\re\cy-native-12\14-block3550.txt`).
Kiểm live xác nhận: **304 và 514 CHẠY** (`buffs_other {345:7, 23:7}` và `{214:1}`), còn 3559/3558 trắng.

⇒ **Quy tắc chung:** khi một chiêu có mọi ô impact = −1 **và** tip bắt đầu bằng `未学习`, đó là mục hiển thị
của bảng kỹ năng, **không** phải thiếu dữ liệu. Loại khỏi danh sách kiểm và đừng cấp bằng GM
(bot chỉ tung được vì GM cấp toàn bộ bảng).

### 14.2 Nhóm ngòi nổ bẫy — `531`, `4465`, `4466` **[DK]**

Ba chiêu này tự thân **không sinh hiệu ứng nào**; chúng chỉ kích nổ bẫy do chiêu khác đặt.

- **531 高山流水** — logic 261 (`skill_261.lua`, đã cài). Hai ô: `瞬发效果ID = −1`,
  `引爆的陷阱类型ID = 65`. `IDCollections` dòng **65** = 「引爆陷阱类型」 → `ID1 = 2` = `类别 2` của
  `SpecialObjData` = **八阵图** (401–416, 1146–1161, 3055–3057). `skill_261` lấy buff ghi bẫy
  (`std_impact_052`) rồi `force_activate` các bẫy có `类别` thuộc tập 65. **Mọi mảnh đã có trên server**;
  bot tung 40 lần đơn lẻ mà chưa từng đặt bẫy nên đúng 0 tác dụng (26/40 lần còn `OR −5` hết khí).
  Đo đúng cách: tung **527 八阵图** (logic 260) trước rồi 531.
- **4465 万箭齐发·裂羽** (logic 734) và **4466 …·铩羽** (logic 735) — **0 ô tham số**; tip: "kích nổ cơ quan
  … do **chính mình** đặt trong 20 m". Bẫy gốc do **2901 万箭齐发** sinh ra (logic **736 chưa cài**,
  ô `溅射效果陷阱id` = **3064** = `SpecialObjData` 「万箭齐发」, 类别 4, bán kính 5). ⇒ **Thứ tự việc: cài 736
  trước**, rồi 734/735 dùng lại khuôn `skill_261` (quét bẫy của người tung trong 20 m).

### 14.3 Nhóm trạng thái 状态 — `2912`, `3446`, `3812`, `3816` **[DK]**

Cùng khuôn: `技能类型 = 0`, `目标选择逻辑 = 0`, `技能友好度 = 1`, logic kỹ năng **0**, đúng một ô
`|生效一次的附加效果1` trỏ tới buff vĩnh viễn (`总持续时间 = −1`). Dòng `StandardImpact` **đều có thật**;
khác nhau ở `逻辑ID` của impact:

| Chiêu | Impact | `逻辑ID` | Trạng thái trên server | Tác dụng thật |
|---|---|---|---|---|
| 2912 催箭式 | 37508 | 60 | module có; **nhãn ô 5 `命中+` chưa đọc** | 怒气 +30 %, **命中 +1140** |
| 3446 意纵横 | 42325 | 15 | module có và đọc đúng `DEX修正` | 身法 +75 |
| 3812 仁以守本 | 44891 | **8038** (`逻辑ID的说明` = 「程序」) | native CY, **chưa cài** | trần **共情** +500 |
| 3816 战可得威 | 45196 | **8167** (`StdImpact167`) | native CY, **chưa cài** | mỗi 3 s +9 % hội tâm, tối đa 45 % |

**3816 战可得威 cài được ngay bằng chính dữ liệu của dòng impact** — nó mang **10 ô mà không đường nào của
ta đọc**: `回调时间 = 3000`, `给自己的效果1..4` = **4555, 4556, 4557, 4558, 4559** và `替换效果1` ×5 =
**4550, 4551, 4552, 4553, 4554** (thêm `发作时间间隔 = 3000 ms`). Năm cặp `4550+k → 4555+k` chính là **5 bậc
hội tâm** của tip. Khuôn cài: mỗi nhịp 3000 ms nếu chưa bị đánh thì thay buff bậc k bằng bậc k+1; khi bị sát
thương thì giữ bậc hiện tại thêm 10 s — giống `std_impact_101` (đếm nhịp + phát buff) đã có.

**3812 仁以守本:** 8038 = 8000+38 nằm trên đường "literal impacts" của `cy_four_combat`; mục 10 đã ghi rằng
`make_impact` coi 8038/8168 là "verified native marker" và **không gọi `bridge:state`** ⇒ buff vô hiệu.
Cài = nâng **trần 共情** thêm N (N = ô `共情修正`); phải kiểm `cy_four_combat/tao.lua` xem thuộc tính 共情
đã có chưa.

**2912 / 3446 — phần chưa khép kín (không phải cơ chế CY thiếu).** Live: server phát `GCCharSkill_Send` +
`GCTargetListAndHitFlags` nhưng **không hề gửi `GCCharBuff`**, trong khi bốn chiêu cùng khuôn đều gửi
(**2916 震箭式** logic 8148 → SEid 2617; **3442 逍遥游** logic 59 → 3651; **532 大风歌** & **536 洛神图**
logic 60 → 196/192). Đã loại trừ bằng dữ liệu, **đừng kiểm lại**:

| Giả thuyết | Bác bỏ bằng |
|---|---|
| `总持续时间 = −1` bị engine bỏ | 23 chiêu `chay` khác cũng toàn buff vĩnh viễn (`06-duration-crosstab.txt`) |
| `逻辑ID` chưa cài | logic 15 chạy ở 2902/362/392/422; logic 60 chạy ở 532/536/352/382/416 (`13-mutex-correlation.txt`) |
| 互斥 chặn | 震箭式 ưu tiên 90 < 160 vẫn chạy; buff duy nhất lúc đăng nhập là `334 传送保护` (互斥 334) (`11-mutex-groups.txt`) |
| bảng hỏng / lệch cột | `StandardImpact.txt` 27 807 dòng: **0** lệch cột, **0** dòng không đọc được GBK, **0** `Data_Index` trùng (`12-gbk-rowcheck.txt`) |
| template/SkillData khác nhau | diff 3442↔3446 và 2916↔2912 chỉ khác `心法ID`, âm thanh, bộ động tác và chính ID impact (`10-template-diff.txt`) |

⇒ Việc còn lại là **một dấu vết runtime** trong `character:register_impact` cho đúng hai `data_index`
37508 / 42325 (nhánh `get_logic == nil`, `is_stealth_immu`, `replace_mutually_exclusive_impact`).

### 14.4 `4516 荡千军` — CY ghi cứng ID bẫy trong native **[DK]**

`SD35683` logic 840 có `陷阱半径 = 6`, `刀域生效概率 = 40`, `瞬移BUFFid = 49583` — **không ô nào chứa ID bẫy**.
`SpecialObjData` **2102 「荡千军刀域」** có `类别 4`, `触发半径 = 影响半径 = 6`, `持续时间 = 10000 ms`, khớp
chính xác cả ô `陷阱半径 = 6` lẫn câu tip "刀域10秒后自动消失" ⇒ **logic 840 của CY ghi cứng 2102**.
Đối chứng: bản GL/HJ cùng tên (template **5240 / 5523 / 5844**, logic **862**) **có** ô `陷阱id` rõ ràng
(3022 / 3058 / 2166) — cùng một chiêu, hai cách truyền tham số.

Cài đề xuất trong `cy_skill_logic_spec` cho logic 840:
`trap = {{ id = 2102, at = 'dest', radius_label = '陷阱半径' }}` (đặt tại **điểm thuấn di**, không phải chỗ
đứng). Live cho thấy 4516 **đã gây sát thương và giết được** (`damage_dealt+3`, kill sau 5 lần); thứ thiếu là
刀域 và các bộ đếm 刀印/刀意 (+5 % chính xác trong vùng, hoàn 50 % CD cho 扫千机/制六合, lan cứng trực 10–40 %).

### 14.5 `347`, `374`, `2905` — đủ dữ liệu, thiếu điều kiện đo **[DK]**

- **347 飞龙在天**: 4/4 ô đủ, mọi impact tồn tại (15623/15633/15643 sát thương theo đoạn liên kích +
  21648 定身 2 s). 6/6 lần tung trả `OR −26` = **thiếu 连击段**; tip cũng ghi "cần ít nhất một 连击段".
- **374 三环套月**: impact 15874 (僵硬, −50 % tốc độ, 8 s) có thật; chỉ **1 lần tung thật** (CD 60 s).
  `目标选择逻辑 = 7` = điểm đất ⇒ theo mục 12.6, không trúng ai thì `effect_on_unit_once` **không bao giờ
  chạy**. (Ô `生效一次的附加效果2 = 0` trỏ về dòng 0 = đòn đánh thường, vô hại.)
- **2905 暴雨梨花针**: hai impact phong ấn có thật (37395 10 s, 37873 3 s); 1 lần tung thật (CD 120 s); quái
  Vô Lượng Sơn không nhận khống chế. Riêng **飞针入穴** ("tích đủ 5 lần bị hội tâm thì nổ, 5 m / 4 mục tiêu")
  **không có ô nào trong dữ liệu** ⇒ bộ đếm nằm trong native CY; cần cơ chế mới theo khuôn
  `std_impact_101/102/103`.

### 14.6 Bẫy mới

- **Client CY 3.71 KHÔNG chứa mã kỹ năng/impact của server.** `Tools\DATA NEW\CY Game\Bin64\Game.exe`
  (`v3-71-9001`): 4 527 chuỗi RTTI và 269 đường dẫn `.cpp` đều nằm dưới `Prj\GameCode\Client\Game\…`,
  **0 lớp `SkillLogic` / `StdImpact`**. Đừng tốn thời gian mở nó bằng Ghidra để tìm logic kỹ năng — dùng
  dữ liệu CY + tip + đối chứng bản GL/HJ.
- **Một chiêu có mọi ô impact = −1 chưa chắc là thiếu dữ liệu.** Kiểm tip trước: mở đầu bằng
  `#cFF0000未学习#r` nghĩa là mục "chưa học" (bản sao trưng bày), CY cố ý để rỗng.
- **Trùng tên ≠ trùng chiêu.** Trước khi kết luận "chiêu X hỏng", liệt kê **mọi** `SkillTemplate` cùng tên
  (`Build\re\cy-native-12\03-variants.txt` sinh lại được) — 灭此朝食 có 4 template, 万箭齐发 có 9, 荡千军 có 4.
- `SkillAddImpact.txt` của CY chỉ có **2 dòng dữ liệu** ⇒ không phải nguồn hiệu ứng, đừng tra lại.
- `IDCollections` có dòng mang tên chiêu (468 飞龙在天, 517 催箭式, 520 意纵横, 521 仁以守本, 522 战可得威)
  nhưng nội dung là danh sách cho **武道/thi đấu**, không phải hiệu ứng.
- `DataCY31-08-26\tlbb15\Server\Config\StandardImpact.txt` là bảng **tlbb15** (155 cột), không phải CY;
  bảng CY 3.71 phía server ta **không có bản gốc**. Dùng nó để biết dòng nào là di sản tlbb15 và dòng nào
  thuộc khối CY (37xxx/42xxx/44xxx/45xxx…), đừng coi nó là "bảng CY".

## 15. taohua-doll (17/09/2026) — con rối 离人偶 (桃花岛) và 星阵 (鬼谷): nguồn `-44` và nguồn "phát mà không nổ" **[DK]**

Agent `taohua-doll`. Việc **đo + lập tài liệu, KHÔNG sửa một dòng nào trên server** (xem 15.6 vì sao).
Bằng chứng: `Build\Logs\2026-09-17-taohua-doll\` — `10-verify\` + `11-plan\` (`Tools\server\taohua_doll.py`,
chạy lại được), `20…29-*` (dữ kiện 桃花岛), `40…47-*` (dữ kiện 鬼谷 + IDCollections), `60-live-3801-doll-spawn.txt`
(gói mạng thật), `scripts\90-evidence.sh` sinh lại toàn bộ.

### 15.1 `-44` của 3807/3820/3822 KHÔNG phải lỗi ánh xạ tập ID — đây là cổng ĐÚNG của CY **[DK]**

Chuỗi: `SkillData_V1` của cả 5 chiêu có `条件和消耗逻辑 = 16` (`消耗能量（条件+消耗）`) →
`condition_delplete_core:condition_check` (`resources.dispatch` chỉ nhận 8016/8017/8018 nên **không** chặn ở đây)
→ `condition_cy.logics[16]` (`services/scene/skill/condition_cy.lua:117–137`). Hai nhánh, **cả hai** đặt
`OR_U_CANNT_DO_THIS_RIGHT_NOW = −44`:

| nhánh | mã | điều kiện |
|---|---|---|
| thiếu 共情 | `condition_cy.lua:125–127` | `mission328 % 10000 < 条件或消耗参数值` |
| chưa có con rối | `condition_cy.lua:129` | `cy_four_combat.callbacks.get_doll_id(obj) <= 0` |

`27-cond16-sim.txt` chạy **chính** `condition_cy.logics[16]` với đối tượng giả lập và in ra bảng thật:
3807 ở (共情 100, không rối) = `−44`; (100, có rối) = `0`; 3820 ở (299, có rối) = `−44`, (300, có rối) = `0`;
3822 ở (119, có rối) = `−44`, (120, có rối) = `0`.

**Tập ID 340 đúng khít.** `cy_idcollections[340] = {3806, 3807, 3809, 3820, 3822}` (dòng chỉ có ở tlbb15;
`IDCollections` của client CY 3.71 **không có** dòng 340 — `47-idcollections-cy-vs-tlbb15.txt`). Chứng minh
không cần bảng CY: **đúng 5 chiêu đó, và chỉ 5 chiêu đó**, có tip CY kết bằng `需要离人偶出战`
(`23-tips.txt`, `10-verify\verify.txt` phép kiểm `set340` = TRÙNG KHÍT). Khác hẳn ca 唐门 (`logic 20`
trỏ tập 1 = ba impact của 天龙寺): ở đây **không có gì để remap**.

Giá trị 共情 lấy thẳng từ bảng: 3806 = 155, 3807 = 100, 3809 = 10, 3820 = 300, 3822 = 120
(khớp từng con số trong tip: `消耗共情：N点`).

### 15.2 Con rối do chiêu nào "xuất chiến", và `cy_four_combat.tao` đã cài tới đâu **[DK]**

**3801 八列之舞** (技能逻辑 791, `SkillData 33016`, 共情 50) — tip: *"离人偶操控 将离人偶投掷到自身10米范围内指定位置"*.
Đó là chiêu **duy nhất** trong 桃花岛 có chuỗi `将离人偶投掷到` (`10-verify` phép kiểm `summon_skill`).

Đường chạy **đang sống**, đã đo bằng gói mạng thật (`60-live-3801-doll-spawn.txt`, phiên `s3801-073900-a1`):

```
4471 ms GCCharSkill_Send      ← lần tung đầu
4519 ms GCNewMonster          ← CON RỐI (MonsterAttrEx 17097 傀儡模型, 友好值 0, HP上限 9320)
4519 ms GCNewSpecial          ← vật thể đặc biệt 936→2100 (1006文王于昭)
13392/18607/23836/29027 ms    ← bốn lần tung sau: KHÔNG có GCNewMonster ⇒ dùng lại con rối cũ
```

Chuỗi mã: `character:on_use_skill_success_fully` (`obj/character.lua:1054`) → `cy_four_combat.hooks` →
`phase2:on_use_skill_successfully` → faction 13 → `tao_installation` → `tao:on_skill_success` →
`call_doll` → `summon_runtime.spawn(17097)` → `callbacks.set_doll`. `ready()` của cả 5 chiêu
`{3801, 3804, 3809, 3820, 3822}` trả **true** (`21-tao-ready.txt`): `tao_landing_replacement` và
`tao_logic168_base_ready` được `release.configure` bật **trước** `phase2.prepare` nên không chiêu nào bị `block`.

Phần `cy_four_combat.tao` phụ trách (và **không được cài lại** ở tầng `skill_cy_spec`): tạo/di chuyển rối (3801),
thu hồi (3804), kéo địch quanh rối (3822), lớp tăng thương 4267–4271, vòng đời `tick_doll`
(rời chủ quá `√180 ≈ 13,4 m`, chủ đổi cảnh/chết, `state.doll_id < 0` ⇒ `set_die_time(200)`).
Phần `skill_cy_spec` phụ trách: mọi ô nhãn impact/AOE/bẫy neo theo `around/at/to = 'doll'`.

**Trả lời câu hỏi bỏ ngỏ ở mục 13.8** ("bẫy 3018 và vật thể 2101 có phải cùng một hiệu ứng port hai lần?"):
**KHÔNG**. `SpecialObjData` 3018 = **傀儡残影** (đặt ở chỗ **con rối** đứng, do ô CY `傀儡回收后，原地留下陷阱ID`),
2101 = **1009桃花岛本体残影** (đặt ở chỗ **chủ** đứng, do `tao.lua:91`). Hai vật thể khác nhau, hai vị trí khác nhau.
Ngoài ra ô `傀儡回收后，原地留下陷阱ID` là **3018 ở cả 16/16 cấp** (`26-per-level.txt`) — ghi chú cũ
"3018 ở cấp 1, 1450 ở cấp 4" **sai**; 1450 là `步步生花（110-119）`, không liên quan.

### 15.3 Nút thắt THẬT của 3820/3822: ID impact của CY rơi trúng khối 坐骑 **[DK]**

Kể cả khi đã có con rối và đủ 共情, hai chiêu này vẫn "không tác dụng", vì ô impact của chúng trỏ vào
**dòng thú cưỡi** của bảng GL/HJS (`逻辑ID 97` + `分类ID 99` = buff rỗng): impact **vẫn lên người, không báo lỗi**.

| Chiêu | Ô | ID | Dòng thật trên server |
|---|---|---|---|
| 3820 棹歌中流 | `生效一次的效果1(傀儡周围敌人)` | 45444 | **红白凤** |
| 3820 | `生效一次给傀儡加效果` (ô 1) | 45493 / 45496 (c1/c4) | **七彩鹿 / 闪电貂** |
| 3820 | `生效一次给傀儡加效果` (ô 2) | 45443 | **金翼鹤** |
| 3822 劝君酒 | `生效一次的效果(目标)桃花岛苦昼短专用` | **45445…45460 theo 16 cấp** | **白牦牛, 白鹿, 白雕, 白狼, 狮子, 白狮, 大象, 犀牛, 玄龟, 陆吾, 木牛流马, 熊, 符文骑士, 鸵鸟, 河马, 马车** |
| 3822 | `生效一次的效果(傀儡罩子)…` | 45510 | **火云邪兽** |
| 3822 | `生效一次的效果(傀儡连线)…` | 45511 | **玄天雷兽** |

Dãy 45445→45460 chạy **liên tiếp theo cấp** và **mọi mức** đều là dòng 坐骑 ⇒ đây là **va chạm DẢI ID**,
không phải một ô nhập sai (`25-collide-mount.txt`, `26-per-level.txt`, phép kiểm `series`).
Các ô còn lại của nhóm con rối **đúng**: 45171 八列之舞, 45373 敛其羽翼（CY推导麻痹）, 44812/44815/44828/44831
谋动干戈（麻痹）, 45165 高唐云散, 45166 劝君酒（CY推导减速）.
⇒ Việc của `impact-data`: dời ID (trong `SkillData_V1`) hoặc nhập dòng CY ở dải trống. **Ngoài phạm vi ghi
của `taohua-doll`** (`configs/*.txt`); `taohua_doll.py plan` in ra đúng danh sách này.

### 15.4 共情: 3801/3803/3808/3818/3819 vừa không bị chặn vừa không bị trừ **[DK + SL]**

`condition_cy.logics[16].applies` đòi kỹ năng ∈ tập 340 ⇒ **10** template 桃花岛 khai ô `类型16` nhưng chỉ **5**
được kiểm/trừ (`10-verify`, phép kiểm `cond16`): 3801 (50), 3803 (80), 3808 (50), 3818 (10), 3819 (150)
đi qua **miễn phí**. Bản port cũ hơn của **cùng** đoạn native — `cy_four_combat/resources.lua:6,49` — lại giữ
共情 cho **tám** chiêu `{3801,3818,3819,3806,3807,3809,3820,3822}` và chỉ đòi con rối cho những chiêu **ngoài**
`{3801,3818,3819}`, tức: **共情 kiểm cho mọi chiêu 类型16; con rối chỉ kiểm cho tập 340**. Tip CY ủng hộ bản này
(3801 ghi rõ `消耗共情：50点`). **[SL]** Hai bản port mâu thuẫn; chưa có mã CY thứ ba để chốt.

Hệ quả thực tế: có thể triệu hồi rối ở 共情 = 0, và `resources.on_rage_regeneration` (`resources.lua:113–125`)
sẽ **xoá ngay** con rối ở nhịp tim môn phái kế tiếp (`current == 0 and get_doll_id > 0 → clear_doll`).
Kinh tế 共情 hiện tại: `+80` mỗi nhịp khi **không** có rối, `−15` mỗi nhịp khi **có** rối, trần 1 000
(`仁以守本` nâng trần). `define.MENPAI_HEART_BEAT_TICK = 2500 ms` ⇒ nạp ≈ 32/s, hao ≈ **6/s**, trong khi
tip 3801 ghi **"每秒消耗5点共情值"** ⇒ lệch 20 % (hằng số donor 15 hợp với nhịp 3 000 ms). **[SL]**, chưa sửa.

### 15.5 鬼谷 3438 聚星阵·长生 — ống dẫn còn sống nhưng KHÔNG ai bấm cò **[DK]**

Đo live `pass10` (server `143e909`): 3438 **phát được** (`sends = 1`, chỉ `-6` hồi chiêu, điều kiện duy nhất là
`消耗MP logic 4 = 48`) nhưng 0 sát thương, 0 buff. Nguyên nhân:

1. `guigu_installation.lua:35–42` — `timers:on_use_skill_successfully` khi tung 3438 **chỉ ghi mốc**
   (`callbacks.start_xin_zhen(owner, x, y)`). Nó **không** spawn.
2. Nơi spawn thật là **callback lúc impact TẮT**: `callbacks.script_on_impact_fade(owner, 808253, …)`
   (`callbacks.lua:102–113`) → `config.spawn_formation` → `summon_runtime.spawn(16916)`.
   Nó chỉ chạy cho impact có `donor_id ∈ [4067…4078]` (长生), `[4080…4091]`, `[4166…4177]`,
   `[4226…4237]`, `[4238…4249]` hoặc 13317.
3. Những dòng đó **có đủ** trên server (`4067–4078` = `聚星阵·长生`, `逻辑ID 8090`, `参数0 = 808253`;
   `40-guigu-config.txt`, `43-seed-rows.txt`) và `guigu.readiness` trả **true**, `resolve.monsters` đủ 5 con.
4. **Nhưng quét TOÀN BỘ `SkillData_V1`: 0 ô nào trỏ tới 4067–4091 / 4166–4177 / 4226–4249**
   (`42-who-sends-seed.txt`). Dòng `SkillData` của 3438/3439/3447/3451/3453 **không có một ô tham số nào**
   (đúng như mục 3) ⇒ **không ai gửi impact mầm** ⇒ `script_on_impact_fade` không bao giờ chạy ⇒ **0 星阵**.

⇒ **Lật lại kết luận mục 12.4.** "Đường spawn đang sống" chỉ đúng ở phần **ống dẫn**; **cò súng** (impact mầm)
nằm trong `SkillLogic761_T`/`762`/`763`/`764`/`765` của Serverhook CY — **chưa port**. Cài 761–765 ở tầng
`skill_cy_spec` **không** làm ra hai 星阵, **miễn là** làm đúng cách:

> Logic 761–765 chỉ cần **gửi cho chính người tung** impact mầm `first + (cấp心法 − 1)` của trận tương ứng
> (761 长生 → 4067, 762 破军 → 4080, 763 阴阳 → 4166, 764 七杀 → 4226, 765 贪狼 → 4238).
> `cy_four_combat` lo phần còn lại: mốc vị trí đã ghi sẵn, `spawn_formation` tạo đúng **một** thực thể,
> `guigu:tick` chạy nhịp, `set_cool_down(83, desc.cooldown)`.

**BẪY bắt buộc:** dải mầm của tlbb15 chỉ có **12** mức, CY có **16** cấp 心法; `spawn` có
`assert(tier >= 1 and tier <= 12)` (`guigu_installation.lua:22`) ⇒ **phải kẹp cấp về 12**. Gửi `4067 + 15`
sẽ ra **4082 = 绝星阵·破军** (sai trận) và/hoặc ném lỗi.

### 15.6 Vì sao LƯỢT ĐẦU không sửa gì **[DK]**

> Lượt sau (`pass11`, mục **15.8**) đã sửa **một** lỗi thật trong phạm vi: gói `GCCharDoAction` chứa
> một hàm làm `skynet.pack` nổ và huỷ cả lần tung. Mục này nói về lượt ĐẦU (đo, chưa vá).

Phạm vi ghi của agent là `lualib/cy_four_combat/**` và `lualib/cy_idcollections.lua`. Sau khi đo:
tập 340 **đúng**, chuỗi xuất chiến 3801 **đang chạy**, `tao`/`guigu` đủ `ready`, `luac5.4 -p` sạch 38 file.
Mọi việc còn lại nằm ở bảng của agent khác (`configs/StandardImpact.txt` — `impact-data`) hoặc ở tầng
`skill_cy_spec` (`Tools\server\skill_logic_lua\**` — ngoài phạm vi, và bị cấm ở lượt này).
`Tools\server\taohua_doll.py apply` **từ chối** đúng vì lý do đó; dùng `verify` để đo lại sau khi agent khác sửa.

### 15.7 Bẫy mới

- **`-44` của 桃花岛 có HAI nguồn**, đừng kết luận sớm: thiếu 共情 **và** chưa có rối đều trả `-44`.
  Muốn tách, xem `Cong tinh: N/1000` do `resource_feedback.notify` gửi qua `notify_tips`.
- **`cy_four_combat/resources.lua` KHÔNG chạy cho ô `类型16` của CY.** Nó chỉ nhận `data.type` 8016/8017/8018
  (`resources.lua:148`); bảng CY ghi **16**. Đường sống là `condition_cy`; `resources` chỉ nhận **hàng chờ**
  tiêu hao qua `condition_cy.queue_cost` và làm phần nhịp tim.
- **Impact "lên được" không có nghĩa là "đúng dòng".** Khối 坐骑 (`逻辑ID 97` + `分类ID 99`) nuốt trọn dải
  45440–45511; một ô 桃花岛 trỏ vào đó sẽ **im lặng** thành buff thú cưỡi. Kiểm bằng tên dòng, đừng kiểm
  "có dòng hay không".
- **Thực thể do `cy_four_combat` tạo ra đều chờ một impact TẮT.** 星阵 chờ 4067…4249 (script 808253),
  八列之舞 chờ 45171 → 808280 (`release.landing`), 勒马归鞍 chờ 4372 → 808281 (`callbacks` xoá rối).
  Nếu `SkillData` không trỏ tới đúng ID đó thì toàn bộ nhánh im lặng không chạy — **và không có log lỗi nào**.
- `bridge:descriptor` chỉ ghi log một lần cho mỗi `data_index` thiếu mô tả positional
  (`[cy_four] bo qua impact khong co mo ta positional`); đừng chờ nó lặp lại trong log.

## 16. skill-logic-4 (17/09/2026) — cài phần cài được của 7 chiêu "gửi mà không tác dụng" + 星阵 鬼谷 **[DK]**

Agent `skill-logic-4`. Đầu vào: mục 14 (`cy-native-12`), mục 15 (`taohua-doll`) và hai tin nhắn của người điều phối.
Bằng chứng: `Build\Logs\2026-09-17-skill-logic-4\` — 15 file `*.txt` sinh lại được bằng `scripts\90-evidence.sh`,
`20-verify-server.json` (`skill_logic.py verify` trên R, `ok: true`), `21-server-git-status.txt`,
`24-log-skill840-dao-vuc.txt`. Mã: `lualib\cy_collection_bridge.lua` (**mới**), `lualib\cy_skill_logic_spec.lua`,
`services\scene\skill\human\skill_cy_spec.lua`, và **ba file ngoài bộ cũ** —
`services\scene\skill\impact_logic\std_impact_060.lua`, `services\scene\special_obj\trap.lua`,
`services\scene\skill\condition_delplete_core.lua`. Test `skill_logic_tests.lua` **72/72**; 265/265 nhãn khớp bảng.

### 16.0 Kết quả

| Việc | Kết luận |
|---|---|
| 1. 4516 荡千军 (logic 840) — `trap = {id = 2102}` | **DỪNG: đã có sẵn từ mốc gốc**, thiếu là DỮ LIỆU (16.4) |
| 2. 2912 催箭式 — nhãn `命中+` cho `std_impact_060` | **CÀI**, và tìm ra lý do thật vì sao buff không lên (16.1) |
| 3. 3816 战可得威 — module impact 8167 | **DỪNG: `cy_four_combat` đã cài native 167** (16.5) |
| 4. 3812 仁以守本 — module impact 8038 | **DỪNG: `cy_four_combat/resources.lua` đã cài** (16.5) |
| 5. 3446 意纵横 — vì sao không tác dụng | **CÀI**: cùng một gốc với 2912 (16.1) |
| 6. 826 中冲剑·刃影 (logic 208) | **DỪNG: thiếu ánh xạ 6 hệ, KHÔNG đoán** (16.6) |
| 7. 2901 万箭齐发 — ô `是否即刻生效一次` | **CÀI** (16.2); bẫy 3064 vẫn thiếu `效果1` (việc của `trap-impacts`) |
| 8 (bổ sung). 827–830 ·九阳 / 832–834 ·九阴 không dùng được | **CÙNG GỐC với việc 5, đã sửa** (16.3) |
| 9 (bổ sung). 761–765 星阵 (鬼谷) | **CÀI** bằng khối `seed` — mục 12.4 bị đảo (16.7) |

### 16.1 Gốc chung: điều kiện kỹ năng tra `IDCollections` của **GL**, không phải của **CY** **[DK]**

`impactenginer:is_impact_in_collection` (`lualib/impactenginer.lua:194`) tra
`configenginer:get_config("id_collections")` = **`configs/IDCollections.txt`, bản HJS/GL, 375 dòng**.
SkillData của CY 3.71 trỏ tới **IDCollections của CY (532 dòng)** — đã có sẵn ở `lualib/cy_idcollections.lua`
(sinh bởi `menpai_fix.py`, nhưng chỉ `scene.skill.condition_cy` kiểu 16–21 dùng).
Hai bảng dùng CHUNG dãy số, khác nghĩa (`13-condition-collections.txt`, `07-dispel-collections.txt`):

| tập | GL (`configs/IDCollections.txt`) | CY (`cy_idcollections.lua`) | dùng ở đâu |
|---|---|---|---|
| **499** | **KHÔNG CÓ DÒNG** | 回天术九阳状态 `{2631}` | 64 ô — `需要九阳状态` (kiểu 0) của 827–830, `九阳状态无法使用` (18) của 417 |
| **376** | 拘魂天 `{6510}` | 斩情诀BUFF `{151}` | `需要九阴状态` (kiểu 0) của 832–834 |
| **388** | 失魂天+AB `{467,477}` | 所有门派姿态buff (21 ID) | 448 ô `驱散` (kiểu 9) của **28 chiêu 姿态** |
| **389** | 失魂命+AB `{476,477}` | 所有门派姿态下技能buff (15 ID) | 448 ô `驱散` |
| 128 | 心剑交融BUFF借力 `{19001}` | 心剑交融BUFF借力 `{1529}` | 16 ô `驱散` của 777 |
| 230/231/297/298/300/150/155 | **KHÔNG CÓ DÒNG** | 催箭式 / 震箭式 / 逍遥游 / 意纵横 / 鬼谷QTE… | điều kiện kiểu 0 |

**Vì sao 2912 / 3446 "gửi chiêu mà không có `GCCharBuff`" [DK]:** cả hai là chiêu **đổi 姿态** và SkillData của
chúng có HAI ô `驱散` (kiểu 9) trỏ tập **388** + **389** — CY gỡ 姿态 cũ TRƯỚC khi áp 姿态 mới
(`deplete_process` ở `scene/skill/base.lua:92`, trước `activate_once` ở dòng 103). Vì 388/389 tra nhầm bảng GL
nên 姿态 cũ **không bị gỡ**; sau đó `character:replace_mutually_exclusive_impact` (`obj/character.lua:1385`)
thấy trùng `互斥ID` mà `can_impactA_replace_impactB` (= `ưu tiên mới >= ưu tiên cũ`) sai ⇒ **bỏ im lặng impact
mới** — nhánh `else` chỉ DỰNG gói `GCCharSkill_Missed` rồi `return true`, **không hề gửi**. Số liệu
(`04-stance-mutex.txt`, 16/16 cấp đều cùng ưu tiên):

| chiêu | impact cấp 16 | 互斥ID | 互斥优先级 | chiêu chặn nó |
|---|---|---|---|---|
| 2912 催箭式 | 37508 | 105 | **10** | 2916 震箭式 37573 — cùng 105, **90** |
| 3446 意纵横 | 42325 | 150 | **120** | 3442 逍遥游 42276 — cùng 150, **131** |

⇒ Không phải "cơ chế CY thiếu", cũng không phải bảng hỏng: **thiếu phép `驱散` theo bảng CY**.
(Mục 14.3 loại 互斥 bằng phép so "震箭式 ưu tiên 90 < 160 vẫn chạy"; cặp thật là 10 < 90 và 120 < 131.)

**Bản sửa:** `lualib/cy_collection_bridge.lua` + **một dòng**
`pcall(function() require("cy_collection_bridge").install(condition_delplete_core) end)` ở cuối
`services/scene/skill/condition_delplete_core.lua`. Nó bọc đúng **ba** logic điều kiện/tiêu hao đọc tập ID từ
SkillData và chưa CY-hoá — **0** `C_UNIT_MUST_HAVE_IMPACT`, **2** `C_TARGET_MUST_HAVE_IMPACT`,
**9** `D_CANCEL_SPECIFIC_IMPACT` (16/18/19/20 đã do `condition_cy` lo). Luật **HỢP**: giữ nguyên kết quả bảng GL,
chỉ CỘNG THÊM kết quả bảng CY ⇒ không bao giờ biến một kết quả đúng của GL thành sai.
**KHÔNG** đụng `impactenginer:is_impact_in_collection` (nó còn phục vụ std_impact_*/talent của GL).
Công tắc tắt nhanh: `M.ENABLED = false` một dòng trong `cy_collection_bridge.lua`.

**Luật khớp + bán kính ảnh hưởng [DK]:** theo đúng `define.CollectionIdType` (0 = `瞬发效果ID` khi impact là hiệu
ứng duy trì, 1/5 = `互斥ID`, 2 = `逻辑ID`, 3 = `技能ID`), **cộng thêm** một luật cầu nối: với tập kiểu `互斥` cũng
khớp `瞬发效果ID` (chỉ khi `is_over_timed`). Lý do: dòng StandardImpact do CY thêm trên server riêng giữ
**`互斥ID` cũ của GL** nhưng mang **ID của CY ở cột `瞬发效果ID`** — 逍遥游 42276: 互斥 150 / SEid **3651**;
意纵横 42325: 互斥 150 / SEid **3653**; 战可得威 45196: SEid **4159**; cả ba SEid ∈ tập CY 388, còn 150 thì không
(`08-stance-cover.txt`: **26/28** chiêu 姿态 được phủ). Bán kính riêng của luật cầu nối: **4 nhóm / 112 dòng
持续性** (逍遥游, 意纵横, 战可得威, 经脉逆行) — `12-dispel-blast2.txt`.

### 16.2 Ô `是否即刻生效一次` của `SpecialObjData` (việc 7) **[DK]**

`services/scene/special_obj/trap.lua` chỉ có hai đường nổ, cả hai đọc `陷阱专用标记`: `trigger_check` đòi bit 1
(`MASK_TRIGGER_BY_CHARACTER`), `on_time_over` đòi bit 0. Trong 1 528 dòng `SpecialObjData`, **110** dòng có ô
`是否即刻生效一次`, **64** dòng đặt **1**; và **đúng một dòng** vừa đặt 1 vừa có `陷阱专用标记 = 0`:
**3064 「万箭齐发」** (bẫy của 2901, logic 736) — `可激活次数 = 1`, `持续时间 = 100 ms`, `触发/影响半径 = 5`.
Nó **không có đường nổ nào khác** (`10-trap-actnow.txt`).

Cài: `trap:activate_at_once_flag` / `trap:has_target_in_range` / `trap:activate_at_once` (thêm thuần, không đổi
dòng nào đang có), gọi từ khối `trap` của `skill_cy_spec:apply_trap` — **chỉ nơi chính ta tạo bẫy**, nên bẫy do
`skill_260/261`, `std_impact_*`, `cy_four_combat` đặt **giữ nguyên hành vi cũ**. Hai điểm cẩn thận:
(a) cờ một-lần trên chính vật thể (`_cy_trap_acted_now`); (b) **chỉ nổ khi đã có mục tiêu trong `影响半径`** —
`trap:activate` trừ `可激活次数` vô điều kiện, nổ vào chỗ trống sẽ phí lượt duy nhất của những bẫy sống lâu
(2166/3022/3058 荡千军, `可激活次数 = 1`, 10 s).

**CÒN THIẾU DỮ LIỆU:** 3064 có `效果1/效果2/效果3几率/效果3 = −1` ⇒ nổ vẫn không gây gì. Nhập `效果1` cho 3064 là
việc của `trap-impacts` (`configs/SpecialObjData.txt`).

### 16.3 827–830 ·九阳 / 832–834 ·九阴 — mắt xích còn thiếu của mục 13.4 **[DK]**

Người điều phối đo `pass10`: tung 411 rồi 827 vẫn `OR −44`; tung 417 rồi 832/833 vẫn `OR −44`. Nguyên nhân nằm
đúng ở 16.1:

- `827` cần `需要九阳状态` (kiểu **0**, tập **499**). `configs/IDCollections.txt` **không có dòng 499** ⇒
  `is_impact_in_collection` trả `false` ⇒ điều kiện **không bao giờ đạt**, bất kể có mang trạng thái hay không.
- `832/833` cần `需要九阴状态` (kiểu 0, tập **376**). Bảng GL có dòng 376 nhưng là 「拘魂天」 `{6510}`; CY 376 =
  「斩情诀BUFF」 `{151}`.
- Trạng thái mà mục 13.4 phát **đúng ID**: `13058 九阳炽脉` có `互斥ID = 瞬发效果ID = 2631` (khớp CY 499 kiểu 0),
  `13059 九阴煞魄` có `151` (khớp CY 376) — `14-jiuyang-chain.txt`.
- **Buff `2634` thấy trong `buffs_self` KHÔNG phải trạng thái 九阳**: đó là `|变身buff` = **57314 「回天术疲劳」**
  (`逻辑ID 38`, `互斥 13098`, `瞬发效果ID 2634`, 120 s) — đúng cái bẫy đã ghi ở 13.10. Trạng thái 九阳 hiện ra
  dưới số **2631**; khi đo lại phải tìm số đó.
- `417 斩情诀` còn có điều kiện `需要灭剑式` (kiểu 0, tập **19** = `{148}`, GL và CY **trùng nhau**) ⇒ muốn đo
  832/833 phải mồi **hai tầng**: **416 灭剑式** (峨嵋 — template duy nhất mang 互斥 147 / SEid 148) → **417** → **832**.

### 16.4 `4516 荡千军` — KHÔNG cài thêm gì (việc 1) **[DK]**

Mục 14.4 đề nghị `trap = {{id = 2102, at = 'dest'}}` cho logic 840. **Không làm**, hai lý do:

1. `skillenginer` đang trỏ `[840] → scene.skill.human.skill_840`; thêm dòng `[840]` vào `cy_skill_logic_spec`
   sẽ khiến `skill_logic.py` ghi đè thành `skill_cy_spec` và **mất** cả chuỗi thuấn di → chiêu phụ 5771.
2. **`skill_840` ĐÃ đặt bẫy 2102 từ mốc gốc `67fc059`** (`DAO_VUC = 2102`, hàm `dat_dao_vuc`). Log thật của
   server riêng 17/09 11:31:48 (`24-log-skill840-dao-vuc.txt`):
   `[skill_840] dao vuc 2102 obj= 367 tai 46.839838299621 146.23893548276`.

Thứ thiếu là **DỮ LIỆU**: `SpecialObjData 2102 「荡千军刀域」` có `效果1/效果2/效果3几率/效果3/效果4 = −1` và
`陷阱专用标记 = 0` ⇒ 刀域 chỉ còn là hiệu ứng nhìn (`生存期持续特效 = cy4_daoyu_e_…`), không gây gì
(`01-trap2102.txt`). Đối chiếu: bản GL/HJ cùng tên **3022 / 3058 / 2166** có `效果1` (52907 / 56419 / 58609),
`陷阱专用标记 = 2`, `可激活次数 = 1`, `是否即刻生效一次 = 1` ⇒ việc còn lại thuộc `trap-impacts`.

Ghi thêm (chưa sửa): log cùng phiên có `[skill_840] KHONG dang ky duoc thuan di: init= true logic= true` —
ô `瞬移BUFFid` của 4516 là **49583**, `逻辑ID 14` (tê liệt) chứ không phải logic 9 (瞬移), nên
`logic.set_impact_x` là `nil` và module bỏ qua. Cần xác định lại nghĩa của ô đó trước khi sửa.

### 16.5 `3812 仁以守本` (8038) và `3816 战可得威` (8167) — `cy_four_combat` ĐÃ cài **[DK]**

Mục 14.3 ghi hai logic impact này là "native CY chưa cài". Đo lại thì **đã có**; cài thêm sẽ đúng kiểu bẫy nhân
đôi của mục 12.4:

- `installation.prepare` dựng `bridge:make_impact(id)` cho **mọi** `donor_logic` xuất hiện trong
  `native_config.impacts`; bảng đó có **115** dòng `donor_logic = 38` và **28** dòng `donor_logic = 167`
  ⇒ `impactenginer.logics[8038]` và `[8167]` được `bind_impacts` ghi **trước** vòng `register_all_impact_logics`.
  Thêm `[8167]` vào `id_logic_module` sẽ **không có tác dụng** (`if self.logics[logic_id] == nil` đã sai), và
  `assert(logic_id < 8000 or self.logics[logic_id])` ở `impactenginer.lua:462` chứng minh hai ô đó đang có
  (server khởi động được).
- **8167**: `native_config.impacts[45196] = {donor_id = 4476, donor_logic = 167, params = {3000, 60958…60962,
  60953…60957}}` và `cy_four_combat/native.lua` có đủ `interval_167` (mỗi nhịp, nếu không mang tập 360 và chưa
  có `p(5)` thì `stack = min(stack+1, 5)` rồi `send_specific(p(stack))`) + `damages_167` (bị đánh:
  `dispel_impact(p(stack))` + `send_specific(p(stack+5))`) — **đúng 5 bậc hội tâm + giữ thêm 10 s** của tip.
  `params` ở đây là ID **đã phân giải sang phía native** (60958…), KHÔNG phải 4550–4554 của bảng (cảnh báo mục 10).
- **8038**: `capability[38] = {}` (marker). Tham số `共情修正 = 500` được đọc ở
  `cy_four_combat/resources.lua:on_rage_regeneration`:
  `if r.donor_id >= 4272 and r.donor_id <= 4283 then cap = cap + integer(r.params[1]) end`
  ⇒ trần 共情 đi từ **1000 → 1500** khi mang buff; `native_config.impacts[44891] = {donor_id = 4283,
  donor_logic = 38, params = {500, …}}` đúng dòng cấp 16 của 3812.

⇒ Cả hai chỉ cần **đo đúng điều kiện** (nhân vật 桃花岛; 3816 cần 3 s không bị đánh). Hai chiêu cùng `互斥 150`,
ưu tiên 10→120 theo cấp nên ở cấp lệch nhau chúng chặn nhau — nay đã có `驱散` theo bảng CY (16.1).

### 16.6 `826 中冲剑·刃影` (logic 208) — DỪNG, thiếu hai dữ kiện **[DK]**

Tip: "命中后，目标每有一种抗性不高于自身对应减抗，则对目标释放一次对应属性的六脉神剑技能".
`SkillData 17423` có **đúng một** ô: `驱散二式buff集合 = 495` (CY 495 = 「中冲剑二式飞剑」 `{940}`). Thiếu:

1. **Ánh xạ hệ → chiêu 六脉神剑.** Tip từng chiêu chỉ cho **4/6**: 463 少商剑 = 火, 471 关冲剑 = 冰,
   487 商阳剑 = 毒, 481 少泽剑 = 玄. 469 少冲剑 là "hút khí", 488 中冲剑 là "giảm 3 kháng ngẫu nhiên" —
   **không hệ nào**; hệ **电** thì **không có chiêu nào**. Không tập `IDCollections` nào ghi ánh xạ: chỉ có
   507 「六脉神剑刃影技能」 `{821..826}` và 490–495 「X剑二式飞剑」 (ID đạn từng chiêu) — `09-dali-liumai.txt`.
2. **"自身对应减抗"** (ngưỡng so sánh) không có ô nào trong SkillData/StandardImpact của 826.

Thêm: `character:skill_exec_from_script` đi qua đủ điều kiện + hồi chiêu (30–90 s) + tiêu hao khí (396–558) của
chính chiêu con, nên "phát thêm một lần" **không miễn phí** như tip mô tả. Lý do đã ghi trong `note` của dòng
`[208]`; **đừng đoán ánh xạ**.

### 16.7 761–765 星阵 (鬼谷) — khối `seed`, ĐẢO kết luận của mục 12.4 **[DK]**

Mục 12.4 kết luận "thêm 761–765 sẽ ra HAI 星阵". Sai. Đo lại (khớp với mục 15 của `taohua-doll`):

- `guigu_installation.timers:on_use_skill_successfully` khi tung 3438… **chỉ ghi mốc vị trí**
  (`callbacks.start_xin_zhen`), **không** dựng thực thể;
- thực thể chỉ ra ở `callbacks.script_on_impact_fade` — tức khi một **impact mầm** TẮT trên người tung:
  `native.fade_90` đọc `脚本ID = 808253` rồi tra dải mầm để biết **trận nào** (`formations[i].first..last`) và
  **bậc mấy** (`tier = source − first + 1`), sau đó gọi `spawn` → **đúng một** thực thể;
- 60/60 dòng mầm có đủ trên server (`逻辑ID 8090`, `脚本ID 808253`, `总持续时间 = 1 ms`, `互斥ID 11928`), nhưng
  **0/20.667 ô SkillData** trỏ tới chúng ⇒ trước lượt này không ai gửi mầm ⇒ **0 星阵** (`15-guigu-seed.txt`).

| logic | chiêu | dải mầm | quái / 脚本 | vòng đời |
|---|---|---|---|---|
| 761 | 3438 聚星阵·长生 | **4067–4078** | 16916 / 808254 | 30 s, nhịp 3 s |
| 762 | 3439 绝星阵·破军 | 4080–4091 | 16917 / 808255 | 10 s, nhịp 1 s |
| 763 | 3447 聚星阵·阴阳 | 4166–4177 | 16918 / 808256 | 10 s, nhịp 1 s |
| 764 | 3451 绝星阵·七杀 | 4226–4237 | 16927 / 808257 | 15 s, nhịp 2 s |
| 765 | 3453 绝星阵·贪狼 | 4238–4249 | 16928 / 808258 | 15 s, nhịp 1 s |

Cài: khối `seed = {first = <đầu dải>, tiers = 12}` trong `cy_skill_logic_spec` + `skill_cy_spec:apply_seed`.
Gửi **chỉ cho chính người tung**, và gọi từ `activate_once` (không phải `effect_on_unit_once`) vì cả 5 chiêu có
`目标选择逻辑 = 7` (điểm đất) — không trúng ai thì `effect_on_unit_once` không bao giờ chạy (bẫy 12.6).
Dòng SkillData của cả 5 chiêu **không có ô tham số nào** (chỉ `消耗MP`) nên `first` ghi thẳng trong đặc tả.
Mốc vị trí đã do `on_use_skill_successfully` đặt **trước** `activate_once` (`scene/skill/base.lua:98` rồi `103`).

**BẪY:** dải mầm chỉ **12** mức trong khi CY có **16** cấp tâm pháp, mà `guigu_installation.lua:22` có
`assert(tier >= 1 and tier <= 12)` ⇒ `skill_cy_spec:seed_data_index` **KẸP** cấp về 12. Không kẹp thì
`4067 + 15 = 4082` rơi sang dải **破军** (4080–4091): vừa sai trận vừa có thể nổ assert. Cấp lấy từ
`params:get_skill_level()` (`targeting_and_depleting_params.lua:189`), rơi về 1 khi không đọc được.
`766` và `770 请星入命` vẫn để nguyên (766 chỉ có ô `图腾类型ID`, chưa rõ trỏ thực thể nào).

### 16.8 Giới hạn và việc còn lại

- **Chưa đo live** (không được restart). Kết quả là `luac5.4 -p` sạch + **72/72** test đơn vị + **265/265** nhãn
  đặc tả khớp bảng. Sau restart cần đo, theo thứ tự:
  1. **2912 催箭式** sau khi đã mang **2916 震箭式** — phải thấy `GCCharBuff`, 命中 +1460;
  2. **3446 意纵横** sau khi đã mang **3442 逍遥游** — phải thấy `GCCharBuff`, 身法 +95;
  3. **411 → 827** và **416 → 417 → 832** — chiêu ·九阳/·九阴 dùng được trong 20 s
     (kiểm `buffs_self` có **2631**, ngoài **2634** = 回天术疲劳);
  4. **3438 / 3439 / 3447 / 3451 / 3453** — phải thấy quái 16916/16917/16918/16927/16928 xuất hiện **một** con,
     và **chỉ một**; thử ở cấp tâm pháp > 12 để chắc phép kẹp;
  5. **2901 万箭齐发** — bẫy 3064 nổ ngay (`GCSpecialObj_ActNow`) nhưng CHƯA có sát thương cho tới khi
     `trap-impacts` nhập `效果1` cho 3064;
  6. các chiêu còn tồn của mục 12.5 và 13.9.
- Nếu `驱散` theo bảng CY gây tác dụng phụ ngoài dự tính: đặt `M.ENABLED = false` trong
  `lualib/cy_collection_bridge.lua` rồi restart — trả về đúng hành vi sáng 17/09.
- Hoàn tác cả lượt: xem `Timeline\handoff\skill-logic-4.md`. Lượt này áp **hai lần** nên nếu dùng bản sao lưu
  phải chép **`…054600Z` trước rồi `…053624Z` sau**; cách gọn hơn là `git checkout --` sáu file (chưa commit).
- Chưa làm: `瞬移BUFFid` của 4516 (16.4), ánh xạ 六脉神剑 (16.6), `效果1` cho bẫy 2102 và 3064 (dữ liệu),
  766 / 770, và danh sách còn lại ở mục 3 / 13.9.

### 16.9 Bẫy mới

- **Tập ID trong SkillData của CY KHÔNG tra được bằng `configs/IDCollections.txt`** (bản HJS/GL 375 dòng);
  bản CY 532 dòng nằm ở `lualib/cy_idcollections.lua`. Trước khi kết luận "điều kiện sai", kiểm xem tập đó có
  tồn tại và cùng nội dung ở **cả hai** bảng không (`13-condition-collections.txt`).
- **`character:replace_mutually_exclusive_impact` bỏ impact mới trong IM LẶNG** khi trùng `互斥ID` mà ưu tiên
  thấp hơn: nhánh `else` dựng gói `GCCharSkill_Missed` rồi `return true` **mà không gửi**. Khi một buff
  "không lên mà không có lỗi", kiểm `互斥ID` + `互斥优先级` của buff đang mang trước khi nghi ngờ dữ liệu.
- **Chiêu 姿态 của CY dựa vào ô `驱散` để đổi trạng thái**, không dựa vào luật thay thế theo ưu tiên;
  `驱散` (`条件和消耗逻辑 = 9`) chạy trong `deplete_process`, **trước** `activate_once`.
- **`trap:activate` trừ `可激活次数` vô điều kiện**, kể cả khi quét không ra ai. Đừng kích hoạt bẫy "cho chắc";
  luôn kiểm có mục tiêu trước.
- **Một số logic impact ≥ 8000 ĐÃ được `cy_four_combat` cài** và `bind_impacts` chạy **trước** `id_logic_module`.
  Trước khi viết `std_impact_8xxx`, đếm `donor_logic=<xxx−8000>` trong `native_config.lua` và đọc
  `capability[<xxx−8000>]` ở `engine.lua`.
- **`|变身buff` của 144 hiện ra dưới số 2634 (`回天术疲劳`)** — đừng nhầm với trạng thái 九阳 (**2631**).
- **Dải mầm 星阵 chỉ 12 mức còn kỹ năng có 16 cấp**; `guigu_installation.lua:22` assert `tier <= 12`. Mọi công
  thức "ID gốc + (cấp − 1)" trên dữ liệu CY phải kiểm độ dài dải trước khi cộng.

### 15.8 Lượt vá 17/09 — `skynet.pack` nổ trên đường con rối: gói GCCharDoAction chứa một HÀM **[DK]**

Đo live `pass11` (server `143e909`, tung 3801 trước rồi mới tung chiêu cần đo) làm lộ lỗi mà mọi phép đo
trước đó không thấy — vì trước đó **chưa bao giờ có con rối** nên `tao:on_skill_success` luôn trả sớm `no_doll`.

**Triệu chứng:** `Unsupport type function to serialize` — 26 traceback ở phiên 3820, 2 ở phiên 3804/3807/3822.
Ngăn xếp: `tao.lua:94` (hoặc `:109`) → `scenecore.broadcast` → `scenecore.send2client` → `skynet.send`
→ **`skynet.pack`**. Hậu quả nặng hơn "một hoạt ảnh hỏng": lỗi nằm trên đường
`hooks.on_use_skill_successfully`, mà `character:on_use_skill_success_fully` (`obj/character.lua:1054`)
**không bọc `pcall`** ⇒ huỷ luôn phần còn lại của lần tung. Đó là lý do **3820 ra `sends = 0`**
(client không hề nhận `GCCharSkill_Send`) dù chiêu đã qua hết điều kiện.

**Nguyên nhân gốc [DK]:** `action_packet.M.new` đặt closure `msg:bos` **ngay trong bảng gói**:

```lua
local msg={xy_id=786,obj_id=obj,action_id=action,target_id=target}
function msg:bos()return string.pack('<i4i4i4',self.obj_id,self.action_id,self.target_id)end
```

`scenecore:send2client` (`scenecore.lua:9464`) gửi gói **sang dịch vụ khác** bằng
`skynet.send(agent,"lua","send2client",packet.xy_id,packet)`; skynet serialize cả bảng và **không** nhận
kiểu `function`. Gói của engine không bao giờ mang hàm trong bảng: `net:send2client`
(`lualib/net.lua:183–190`) **tự gắn lại** `bos` bằng metatable của lớp đã đăng ký —
`setmetatable(data,{__index=packet.new()})` rồi `data:bos()`. Đối chứng đo được:
`packet.GCMissionModify.new()` có `rawget(inst,'bos') == nil` và `pairs(inst)` chỉ ra **2** trường dữ liệu.

Đây đúng lớp lỗi mà `cyfour_guard` đã gặp một lần rồi (ca "state KHÔNG nằm trên đối tượng impact —
không còn vòng → skynet đóng gói được"), chỉ khác chỗ áp dụng.

**Đã sửa (trong phạm vi):** `lualib/cy_four_combat/action_packet.lua` — `M.new` trả **bảng dữ liệu thuần**;
chuỗi byte tách ra `M.bytes(msg)` (vẫn đúng `<i4i4i4`, 12 byte). Thêm `lualib/cy_four_combat/hooks.lua`:
gọi `bridge.phase2:on_use_skill_successfully` qua `pcall` + **`skynet.loge`** (ghi log, không nuốt im) —
đúng cách `character.lua:1057` đã làm cho `talent_on_use_skill_success_fully`. Việc này còn sửa một lỗi phụ:
trước đây khi nhánh phải ném lỗi thì `resources:on_use_skill_successfully` bên dưới **bị bỏ qua** ⇒ 共情
không bị trừ.

**Còn lại, NGOÀI phạm vi `cy_four_combat` [DK]:** `game.packet` của server **không có lớp nào mang
`xy_id = 786`**. Đo đúng cách `net:register_packets` làm (duyệt `pairs(game.packet)` đọc **giá trị** `xy_id`,
**không grep theo tên** — tên lớp có thể ghép bằng `string.format`): **514 lớp**, 785 = `GCStallItemPrice`,
787 = `CGPetExteriorCollectionRequest`, **786 trống** (`71-packet786.txt`). Vậy dù bảng đã thuần,
`net:send2client` vẫn sẽ nổ tiếp ở `self.packets[786]` = nil **trong dịch vụ agent**
(`lualib/net.lua:183`). Muốn có hoạt ảnh 傀儡 thì phải đăng ký lớp `GCCharDoAction` trong
`services/game/packet_domains/**` với **đúng ba tên trường** `obj_id` / `action_id` / `target_id`
(ba `<i4`), vì `net:send2client` đọc chúng qua `__index`.

Trong khi chờ, `action_packet.send` **từ chối gửi** (`false, 'packet_class_missing'` + `skynet.logw` một lần)
thay vì ném. Hoạt ảnh là phần trang trí; **sát thương / impact / kéo mục tiêu của 3809 / 3820 / 3822 vẫn chạy**.
Khi lớp được đăng ký, `M.writer_registered()` tự thấy và gửi lại — không phải sửa thêm dòng nào.
**Cố ý giữ `do_action` tồn tại**: `tao.capabilities` đòi phương thức này, gỡ nó đi thì `phase2.prepare`
sẽ `block` hẳn ba chiêu 3809/3820/3822 (tệ hơn mất hoạt ảnh).

**Kiểm:** `Build\Logs\2026-09-17-taohua-doll\70-test-fix.txt` — 14/14 ca (gói mới pack được; bản cũ bị từ chối
đúng lý do `function`; 12 byte không đổi; `send` trả false không ném; `hooks` nuốt-mà-ghi-log và **vẫn** trừ
tài nguyên). `luac5.4 -p` sạch 38 file; `cyfour_guard.py verify` `ok: true`, 10/10.

**Bẫy:** đừng bao giờ đặt hàm (hay userdata / bảng có vòng) vào bảng gói gửi bằng
`scenecore:send2client` / `broadcast` — nó đi **liên dịch vụ**. Và một lỗi ném trên đường
`hooks.on_use_skill_successfully` **giết cả lần tung**, không chỉ nhánh phụ.

## 17. skill-logic-5 (17/09/2026) — lớp gói 786, bẫy 万箭齐发 theo cấp, 中冲剑·刃影 **[DK]**

Agent `skill-logic-5`. Đầu vào: mục 14 (`cy-native-12`), 15 (`taohua-doll`), 16 (`skill-logic-4`) và
`Build\Logs\2026-09-17-coord\96-best-of.tsv` (14 chiêu còn `!= chay`, bỏ 3557/3558/3559 theo mục 14.1).
Bằng chứng: `Build\Logs\2026-09-17-skill-logic-5\` — `README_vi.md` là bản đồ tệp; 8 script Python chỉ ĐỌC
`configs/*.txt`, sinh lại bằng `scripts\90-evidence.sh`; `10-verify-server.txt` = `skill_logic.py verify` trên R;
`live\a…e\` = phiên bot thật.
Mã: `Tools\server\skill_logic_lua\GameServer\services\game\packet_domains\cy_combat.lua` (**mới**),
`…\lualib\cy_skill_logic_spec.lua`, `…\services\scene\skill\human\skill_cy_spec.lua`,
`Tools\server\skill_logic.py` (thêm 1 file mới + 1 file vá), `Tools\server\skill_logic_tests.lua` (+20 ca → **91/91**).

### 17.0 Kết quả

| Việc | Kết luận |
|---|---|
| 1. Lớp gói `xy_id = 786` `GCCharDoAction` | **CÀI + ĐO XONG** — 17.1; live: `unknown_packets = 6`, `unknown_first_id = 786` |
| 2. 2901 万箭齐发 — ô `效果1` của bẫy 3064 | **CÀI** bằng `_custom_descriptor` theo cấp — 17.2. Live **CHƯA KẾT LUẬN**: 8/8 lần tung đều trượt (17.8b) |
| 3. 4465/4466 万箭齐发·裂羽/铩羽 | **DỪNG: thiếu DỮ LIỆU** — 17.3; live 47/47 lần TRÚNG mà 0 tác dụng, đúng dự đoán (17.8b) |
| 4. 826 中冲剑·刃影 (logic 208) | **CÀI + ĐO XONG** — 17.4; live chứng minh cơ chế chạy đúng và không phát vì `抗性 60 > 减抗 0` (17.8b) |
| 5. 3812 仁以守本 / 3816 战可得威 | **CHẠY** (do cầu IDCollections của 16.1); lộ **một lỗi vô tận** của `cy_four_combat` — 17.5, nay đã hết sau bản vá 282 ô params (17.8b) |
| 6. 434 神蝎百相 / 445 圣蚕护身 | 434 **CHẠY**; 445 **DỪNG: thiếu 16 dòng impact** — 17.6 |

### 17.1 Lớp gói `GCCharDoAction` (`xy_id = 786`) **[DK]**

Mục 15.8 giao lại: `game.packet` không có lớp nào mang 786 nên `net:send2client` (`lualib/net.lua:183`) sẽ nổ ở
`self.packets[786] = nil` **trong dịch vụ agent**, và `action_packet.send` phải tự từ chối gửi.

Cài: **file riêng** `services/game/packet_domains/cy_combat.lua` + **một dòng** `require` ở cuối phần nạp domain của
`services/game/packet.lua`. Không sửa `packet_ids.lua` cũng không sửa `packet_domains/combat.lua` — cả hai mang dòng
`由 split_packet.py 自动生成，勿手动修改`; hằng `XYID_GC_CHAR_DO_ACTION = 786` đặt ngay trong `M.bind` (với
`net:register_packets`, một số trong bảng `packet` là hằng id, một bảng là lớp gói — hai cách khai là một).

Khuôn byte **[DK]**: `/home/ubuntu/GameServer/lualib/cy_four_combat/action_packet.lua:1` (bản port gốc) ghi
*"GCCharDoAction: current GL reader 0x1406830e0, ID 786, three signed int32s"*; `M.bytes` của bản trên server riêng
giữ đúng `string.pack('<i4i4i4', obj_id, action_id, target_id)`. `bostream:writeint` (`lualib/iostream.lua:184`) dùng
`string.pack("i4", n)` = `<i4` trên x86-64 ⇒ ba lần `writeint` cho **đúng 12 byte** của `M.bytes` (test đối chiếu
từng byte trên 4 bộ giá trị). **Ba tên trường phải giữ nguyên** `obj_id`/`action_id`/`target_id`: `net:send2client`
không chép dữ liệu, nó `setmetatable(data, {__index = msg})` rồi gọi `bos` của lớp này trên **chính** bảng mà
`cy_four_combat` dựng.

### 17.2 2901 万箭齐发 — ô `效果1` của bẫy đi theo CẤP, không theo bảng **[DK]**

`trap-data` mục 4(c) đã chứng minh đây **không** phải lỗi nhập: bảng CY 3.71 của chính dòng nguồn
(`1980 万箭齐发`, mà `trap-recollide` chép sang `3064`) cũng để `效果1 = -1`. Tip nói
"对其周围5米范围内3个敌对目标造成**100%万箭齐发伤害**" = dòng `伤害效果` của **đúng cấp đang dùng**
(`37316`…`37331`, mỗi cấp một ID — `01-tangmen-wanjian.txt`), mà một dòng `SpecialObjData` chỉ có **một** ô `效果1`.

Cài: khối `trap` nhận thêm ô `descriptor = {['效果1'] = '伤害效果'}`; `skill_cy_spec:apply_trap` gán
`obj._custom_descriptor` cho **vật thể vừa tạo**, **trước** lời gọi `activate_at_once` (bẫy 3064 nổ ngay trong
lời gọi đó). Cơ chế có sẵn: `trap.lua:19-33` (`get_impact` / `impact_activate_odds`) ưu tiên `_custom_descriptor`
hơn `data.descriptor`; `std_impact_543.lua:121-172` đã dùng đúng kiểu này để truyền impact theo cấp cho 飞剑.
Ô `伤害效果 = -1` thì **không** đặt gì (để bảng quyết định như cũ).

### 17.3 4465 / 4466 万箭齐发·裂羽 / ·铩羽 — DỪNG, thiếu DỮ LIỆU **[DK]**

Mục 14.2 đoán hai chiêu này nổ bẫy **3064** do 2901 đặt. Đo lại thì **không thể**: 3064 có `持续时间 = 100 ms`,
`可激活次数 = 1`, `是否即刻生效一次 = 1` ⇒ nổ ngay rồi biến mất trong 0,1 s, không còn gì để "引爆".
Bẫy mà tip nói tới là **một dòng khác**:

| | dòng CY | trên server riêng |
|---|---|---|
| `1109 万箭齐发` | `类别 2`, `可激活次数 2`, `持续时间 10000`, `影响半径 5`, `影响个体数目 3`, nhịp 500 ms, hiệu ứng **`m01_唐门技改_万箭齐发裂羽_陷阱预警`** / **`…_陷阱爆炸`** | ID 1109 đang là **「火焰围剿」** của GL/HJ (va chạm ID, đúng lớp việc của `trap-recollide`) |

Dữ kiện: `03-trap-liewu.txt` (server chỉ có **một** dòng tên 万箭齐发 = 3064), `05-who-places-1109.txt`
(quét **mọi** ô nhãn chứa `陷阱` của cả `SkillData_V1` lẫn `StandardImpact`: **0 ô** trỏ tới 1109/1963/1982–1986),
`04-tangmen-list.txt` (không template nào khác của 唐门 đặt bẫy đó). Bảng CY **không có** dòng nào mang chữ 铩羽
trong `SpecialObjData` — chỉ 裂羽, và chỉ ở dòng 1109.

⇒ Việc còn lại **không thuộc skill-logic**: (a) nhập dòng CY `1109` vào một ID trống (≥ 3065) như
`trap-recollide` đã làm cho 65 ID khác; (b) sau đó mới quyết được ai đặt bẫy đó (CY ghi cứng trong native của
logic 736 hay của chính 神枢战甲 — **chưa có bằng chứng**, đừng đoán). Trước khi có (a), mọi cách cài 734/735 đều
là nổ vào chỗ trống.

### 17.4 826 中冲剑·刃影 (logic 208) — CÀI, hai dữ kiện còn thiếu đã tra ra **[DK]**

Mục 16.6 dừng vì thiếu (a) ánh xạ hệ → chiêu 六脉神剑 và (b) ngưỡng `自身对应减抗`. Cả hai **có trong hệ thống**,
chỉ là không nằm trong `SkillData`:

**(a) Ánh xạ đọc thẳng từ ô `参数N说明` của dòng impact mà chính chiêu đó dùng** (`06-dali-liumai.txt`):

| chiêu 六脉神剑 | ô `附加效果1` (cấp 1) | dòng StandardImpact | hệ |
|---|---|---|---|
| 471 关冲剑 | 56899 | `关冲剑（CY推导伤害）` 逻辑ID 3, `参数3说明 = 冰系攻击` | **冰** |
| 463 少商剑 | 56834 | `少商剑（CY推导伤害）` 逻辑ID 3, `参数4说明 = 火系攻击` | **火** |
| 481 少泽剑 | 56963 | `少泽剑（CY推导伤害）` 逻辑ID 3, `参数5说明 = 电系攻击` | **电** (= 玄) |
| 487 商阳剑 | 57075 | `商阳剑（CY推导伤害）` 逻辑ID 3, `参数6说明 = 毒系攻击` | **毒** |
| 469 少冲剑 | 1987 | `少冲剑（法力燃烧）` **逻辑ID 5**, `MP修改百分率 = -30` | không có hệ |
| 488 中冲剑 | 57139 | `中冲剑` **逻辑ID 38**, tám ô `效果N(人宠/怪)` | không có hệ |

(Mục 16.6 ghi "hệ 电 KHÔNG có chiêu nào" — **sai**: 电 chính là 少泽剑, và chính nó là hệ mà tip gọi là 玄.)

**(b) `抗性` / `自身对应减抗` là THUỘC TÍNH của engine, không phải ô bảng.**
`combat_core.lua:338-530` tính sát thương bốn hệ bằng đúng cặp
`resit = defencer:get_defence_X() − attacker:get_reduce_def_X()`. Quét cả cây Lua: có **sáu** `get_defence_*`
(`physics/magic/cold/fire/light/posion`) nhưng chỉ **bốn** `get_reduce_def_*` (`cold/fire/light/posion`)
⇒ khái niệm "减抗" chỉ tồn tại cho đúng bốn hệ **冰/火/电/毒**. Ánh xạ là **4↔4**, không phải 6↔6 — đó là lý do
tip chỉ cho 4 hệ và không hề nhắc 物理/魔法.

**Cách phát — hai đường bị loại, có bằng chứng:**
- `character:skill_exec_from_script` **VÔ HIỆU với người chơi**: `services/scene/ai/states/base.lua:87`
  `if character:get_obj_type() == "human" then return OR_OK end` — không chạy chiêu nào, mà còn để lại cờ
  `ignore_condition_check_flag` trên `targeting_and_depleting_params` của người chơi (lần tung kế tiếp sẽ bỏ
  kiểm điều kiện/tiêu hao). **Đừng dùng cho human.**
- `character:do_use_skill` (đường mà `skill_840` dùng cho chiêu phụ 5771) chạy **đủ** `deplete_process` +
  `cooldown_process` ⇒ mỗi hệ tốn 396–558 khí và 30–90 s hồi chiêu của chính chiêu con, ×4 hệ.

⇒ **[SL]** bản port gửi thẳng ô `附加效果1` của chiêu con ở **cùng cấp** (`skill_cy_spec:child_skill_impact` đọc
lúc chạy qua `skillenginer:get_skill_template → get_skill_info_id_by_level → get_skill_info().cy_raw_params`,
**không ghi cứng ID nào** — mỗi chiêu con có 16 cấp). Đây là thứ chiêu con gây ra khi trúng, không đi lại vòng
động tác. Chưa làm: `驱散二式buff集合` (cùng nợ với 204/206).

Kiểm dữ liệu trước khi áp (`07-liumai-levels.txt`): với **mọi** cấp 1–12 của cả bốn chiêu con, ô `附加效果1`
có giá trị, dòng `StandardImpact` tương ứng **tồn tại**, `逻辑ID = 3`, và ô hệ của nó **đúng bằng** hệ đã ánh xạ
— **48/48 ô đạt, 0 sai**.

Cấp lấy từ `params:get_skill_level()`, mà `skillenginer:instance_skill` đã kẹp theo
`define.MAX_CHAR_SKILL_LEVEL = **12**` (cùng con số với dải mầm 星阵 ở mục 16.7) — nên `level_skills[cấp]` của
chiêu con (16 dòng) luôn tra được; không đọc được thì rơi về cấp 1.

**Lưu ý cho bộ kiểm nhãn** (`02-check-spec3.py`): `resist_cast.impact_label = '附加效果1'` là nhãn của **chiêu con**
(logic 205), **không** phải của logic 208 — đừng thêm khoá `impact_label` vào `KEY_RE` của bộ kiểm, thêm là báo sai.

### 17.5 3812 仁以守本 / 3816 战可得威 — đã chạy, và lỗi VÔ TẬN của `cy_four_combat` **[DK]**

Đo live 15:07–15:09 (`live\b`), tài khoản test07, `--cast <id>,-1`:

| chiêu | trước (96-best-of) | sau | `buffs_self` | traceback |
|---|---|---|---|---|
| 434 神蝎百相 (星宿) | `khong_tac_dung` | **chạy** | `{334:1, -1:2}` (biến thân + miễn khống) | 0 |
| 3812 仁以守本 (桃花岛) | `khong_tac_dung` | **chạy** | `{334:1, 4406:1}` | 0 |
| 3816 战可得威 (桃花岛) | `khong_tac_dung` | **chạy** | `{334:1, 4159:1}` (đúng SEid mục 16.1) | 1 |

Không cần cài gì thêm: nguyên nhân cũ là phép `驱散` tra bảng GL (mục 16.1), `skill-logic-4` đã nối.

**Lỗi mới, nghiêm trọng** (`live\b\live\m13\s3816-*-serverlog.txt`):
```
[E] [OBJ_UPDATE] scene = 6 obj_id = 385 type = human error =
  ./lualib/cy_four_combat/runtime_adapter.lua:77: missing selected impact 60958
  ← native.lua:335 cy_four_combat.native.interval_167
  ← impact_logic/base.lua:138 std_impact_081.interval_calc ← :232 heart_beat
  ← obj/character.lua:1183 update_impact
```
Lặp **mỗi 3 s không bao giờ dứt** (đếm tới `count = 1000` trong một phiên 80 s), và vì buff 战可得威 có
`总持续时间 = -1` nên nó **lưu xuống Mongo** và sống lại mỗi lần đăng nhập — phải xoá tay `impact_list` mới sạch
(`scripts\93-clear-impacts.py`).

Dữ kiện chốt (đọc bản ghi impact SỐNG trên nhân vật): `data_index = 45184`, `logic_id = 8167`, `skill_id = 3816`,
`continuance = -1`, `params = {回调时间 3000, 给自己的效果2 4556, 给自己的效果3 4557, 给自己的效果4 4559, 替换效果1 4554}`
— tức **đúng ID của bảng**. Trong khi `native_config.impacts[45181..45196].params = {3000, 60958…60962, 60953…60957}`
và `StandardImpact` **không có dòng nào** trong dải 60950–60965, còn **4550–4559 thì có đủ**
(`战可得威(会心提升)`, 逻辑ID 8162) — `09-missing-60958.txt`.

⇒ Với server riêng, cảnh báo của mục 10 ("`params` trong `native_config` là ID đã phân giải sang phía native, đừng
dựng lại từ bảng") **không đúng cho nhóm 167**: dải 609xx là ID của máy chủ donor, không tồn tại ở đây.
Hai việc cho người phụ trách `cy_four_combat` (ngoài phạm vi ghi của `skill-logic`):
(a) `params` của 4465–4476 và 45181–45196 phải là 4550–4559; (b) bỏ `assert` ở `runtime_adapter.lua:77`
(trả `nil` + ghi log một lần) — đúng lớp lỗi đã sập ở mục 11.1.

### 17.6 434 神蝎百相 / 445 圣蚕护身 (星宿) **[DK]**

- **434**: dữ liệu của `transform-model` đã đủ (`变身男buff 59700` / `变身女buff 59703`, 逻辑ID 14; `免控buff`
  59706…59721, 逻辑ID 17 — `07-taohua-xingxiu.txt`) và live đã **chạy** (bảng trên). Chưa đo được `model_id`
  8676/8679 trong `GCCharBaseAttrib` vì bot không giải mã trường đó; `buffs_self` hiện ra dưới số **-1** vì cả sáu
  dòng biến thân đều có `瞬发效果ID = -1` (chép từ dòng mẫu 31577) — muốn nhìn thấy số riêng thì phải đặt
  `瞬发效果ID` khác nhau, đó là việc của `transform-model`/`impact-data`.
- **445 圣蚕护身 — DỪNG.** Ô duy nhất là `冰蚕buff` = **59864…59879 theo 16 cấp**, và **không dòng nào trong
  `StandardImpact` tồn tại** ⇒ `init_impact_from_data` trả false, ô im lặng bỏ qua (bẫy 13.10). Cài thêm ở tầng
  logic là vô nghĩa khi chưa có 16 dòng đó. Ngoài ra tip mô tả một **cơ chế theo nhịp** chưa có khuôn: mỗi 10 s hút
  một hiệu ứng xấu, tốn 12 % HP tối đa, 55 % tiến hoá nếu không thì tự nổ, ba bậc (霸体 1/2/3 s, hồi 8 %/15 % HP),
  dừng khi HP < 20 %. ⇒ cần **(a)** 16 dòng impact (việc của `impact-data`) rồi **(b)** một logic impact mới theo
  khuôn `std_impact_101/102/103`. `transform-model` đã chốt: model 冰蚕 là `npc怪_*` nên **không** phải 变身.

### 17.7 Bẫy mới

- **Đừng sửa `services/game/packet_ids.lua` hay `packet_domains/{core,combat,…}.lua`** — cả bộ mang dòng
  `由 split_packet.py 自动生成`. Lớp gói do CY thêm để ở file riêng và nạp bằng một dòng trong `packet.lua`.
- **`character:skill_exec_from_script` KHÔNG chạy chiêu cho người chơi** (`ai/states/base.lua:87` trả `OR_OK` ngay
  khi `obj_type == "human"`), mà vẫn bật `ignore_condition_check_flag` — dùng nó cho human là vừa vô hiệu vừa để
  lại cờ bẩn. Muốn tung chiêu phụ thì theo khuôn `skill_840` (`do_use_skill` + thử lại khi `OR_BUSY`), và nhớ là
  đường đó **tốn khí + đặt hồi chiêu** của chiêu con.
- **Buff vĩnh viễn (`总持续时间 = -1`) đi vào `character.impact_list` của Mongo** và sống lại mỗi lần đăng nhập.
  Một `assert` trên đường `heart_beat` của nó = lỗi vô tận, không tự hết; phải xoá bản ghi mới sạch.
- **Bẫy sống 100 ms + `是否即刻生效一次 = 1` thì không chiêu nào "引爆" kịp** — 3064 là ca đó. Khi tip nói "引爆 cơ quan
  do chính mình đặt", hãy tìm dòng bẫy có `可激活次数 ≥ 2` và `持续时间` dài, đừng mặc định là bẫy cùng tên gần nhất.
- **Bot `CysNetBot` chết với `strict packet decode failed` khi gặp id lạ.** Thêm một lớp gói mới ở server đồng
  nghĩa với việc phải dạy bot id đó (hoặc cho nó bỏ qua id chưa biết), nếu không mọi phép đo đi qua đường đó đều
  hỏng phiên. (Đã vá 17/09: `Buildot-unknownid\CysNetBot.exe` bỏ qua id không có trong Registry và đếm vào
  `unknown_packets` / `unknown_first_id`; gói CÓ trong Registry mà thân sai thì vẫn `rc=5` như cũ.)
- **`SkillTemplate 4465/4466` và `StandardImpact 4465–4476` là HAI dải ID khác nhau, trùng số.**
  Template 4465/4466 = 万箭齐发·裂羽/铩羽 (唐门, logic 734/735); dòng impact 4465–4476 = 12 cấp **战可得威**
  (`逻辑ID 8167`, donor của `native_config`). Sửa dải impact **không** đụng gì tới hai chiêu kia — đã suýt lẫn một lần.

### 17.8 Đo live sau restart 15:58 — 826 **ĐÃ CHỨNG MINH**, 2901 **CHƯA KẾT LUẬN** **[DK]**

Không xếp hai chiêu này vào `chay` hay `khong_tac_dung`: **chưa có phép đo nào chạm tới đường mã mới**.

| Phiên | Thiết lập | Kết quả |
|---|---|---|
| `live` 15:01 | cấp 15, `--cast <id>,0`, 无量山 (45,152) | 2901: 1 lần tung, `dmg_hits 0`, **0 `GCNewSpecial`**; 826: 35 gửi / 9 lần qua, `dmg_hits 0` |
| `live\e` 15:33 | như trên, sau restart | y hệt (2901 1 lần tung; 826 35/9) |
| `live` 15:38 | `-Level 60 -MpValue 60000` | tệ hơn: mỗi chiêu chỉ 2 lần tung (`OR −4`), `dmg_hits 0` |

Ba dòng log chẩn đoán (`log_once` trong `apply_trap` và `apply_resist_cast`) **chưa nạp**: tiến trình
`Game_tlbb_2` khởi động **15:27:39**, file ghi **15:28:17** — trễ 38 giây (`ps -o lstart` + `stat -c %y`).
Phần **mã** thì đã sống từ lượt áp 14:56.

Vì sao gói mạng không đủ để kết luận: `skill:activate_once` (`scene/skill/base.lua:359`) chỉ gọi
`effect_on_unit_once` cho mục tiêu có `hit_flag_list[i] == true`; mà cả bốn phiên đều `damage_dealt = 0`,
`dmg_hits = 0` nên không chứng minh được có lần nào trúng. `GCDetailHealsAndDamages` xuất hiện một gói mỗi
lần tung ở cả hai chiêu, nhưng nó có mặt **cả trước** lượt này (số đo 16/09 của mục 7: 826 = 35 gửi / 10 gói)
nên không phân biệt được trước–sau.

**2901 — một lần tung mỗi phiên, và lần đó TRƯỢT [DK].** Giải mã fixture `live\e`: gói `GCCharSkill_Send`
(obj 360, skill **2901**, mục tiêu 192) đi kèm `GCTargetListAndHitFlags` dài 25 byte kết thúc bằng
`… 01 00` (count = 1, **hit = 0**), trong khi gói cùng loại của 826 dài 29 byte và kết thúc `01 01 <id mục tiêu>`.
Phù hợp với `GCNewSpecial = 0` (không có bẫy nào được tạo) và với `GCDetailHealsAndDamages` duy nhất là
`02|obj|obj|0|-150` = **MP −150**, tức tiền khí chứ không phải sát thương. Hồi chiêu của 2901 là **70 s** mà phiên
bot chỉ dài 60–80 s ⇒ mỗi phiên **đúng một** lần tung; lần đó trượt là hết cơ hội. Muốn đo phải chạy lại lượt
唐门 vài lần cho tới khi có `hit = 1`.

**Dự đoán có cơ sở cho 826 — nhiều khả năng điều kiện ĐÚNG LÀ không đạt [DK]:** giải mã fixture gói mạng của
phiên `live\e` cho thấy **9/9 lần tung 826 đều `hit_flag = 1`** (`GCTargetListAndHitFlags`: obj 361, skill 826,
count 1, hit 1) ⇒ `effect_on_unit_once` **có chạy**. Nhưng `MonsterAttrExTable` đặt
`冰/火/电/毒防御 = 60` cho **400/400** dòng đã kiểm, còn `降低目标X抵抗` của người chơi mặc định = **0**
⇒ `get_defence_X() = 60 > get_reduce_def_X() = 0` ở cả bốn hệ ⇒ đúng luật của tip thì **không** phát chiêu nào.
Vậy đo 826 bằng quái là **không bao giờ** thấy nó nổ. Muốn thấy: nhắm một **nhân vật** chưa mặc trang bị kháng
(kháng 0 ⇒ `0 ≤ 0` đạt), hoặc người tung có 减抗 ≥ 60.
(Chín gói `GCDetailHealsAndDamages` của phiên đó là **tiền khí**: thân gói `02 | obj | obj | 0 | -82`, tức
`MP −82` mỗi lần tung — không phải sát thương. Đừng đọc số gói đó là "có gây sát thương".)

**Cách đo dứt điểm (một phiên 唐门 + một phiên 大理 sau lần restart kế):** đọc log Game2 bằng
`Build\Logs6-09-17-skill-logic-5\scripts\94-grep-diag.sh` —
`[skill_cy_spec] bay 3064 mang _custom_descriptor 效果1 = 37316` chứng minh việc 2, và
`[skill_cy_spec] 208 he 冰 抗性 <n> 减抗 <n> cap <n> chieu 471 -> <ID>` chứng minh việc 4 (kể cả khi kết quả là
`bo`, vì nó in ra hai con số để biết ngưỡng có đạt không).

### 17.8b Số đo chốt (server khởi động 15:58:39, đã có ba dòng log chẩn đoán) **[DK]**

| chiêu | phiên | số đo | kết luận |
|---|---|---|---|
| **826 中冲剑·刃影** | `live\g` 16:08 | log: `208 he 冰 抗性 60 减抗 0 cap 2 chieu 471 -> bo` và ba dòng y hệt cho 火/电/毒 | **CƠ CHẾ CHẠY ĐÚNG.** `apply_resist_cast` được gọi, đọc đúng bốn cặp thuộc tính, đọc đúng cấp (2), chọn đúng bốn chiêu con (471/463/481/487); **không phát** vì `60 > 0` — đúng luật của tip. Muốn thấy nó nổ: mục tiêu có kháng ≤ 减抗 của người tung |
| **2901 万箭齐发** | `live,e,f,g,t1…t6` — **8 phiên** | **8/8 lần tung `hit = 0`** (`GCTargetListAndHitFlags` 25 byte kết `01 00`), `GCNewSpecial = 0`, **0 dòng log** | **CHƯA KẾT LUẬN.** Hồi chiêu 70 s ⇒ 1 lần tung mỗi phiên; chưa lần nào trúng nên `effect_on_unit_once` chưa bao giờ chạy |
| **4465 / 4466** | `live\g` 16:07–16:08 | 40 + 7 lần tung, **47/47 `hit = 1`** (`命中率 = 100` trong SkillTemplate), nhưng `dmg_pkt 0`, `dealt 0`, `buffs 0`, `GCNewSpecial 0` | **0 tác dụng, đúng dự đoán 17.3** — thiếu dòng `SpecialObjData` 1109, **không phải hồi quy** |
| **3816 战可得威** | `live\h` 16:11 | `buffs_self = {334, 4159, **4192**, **4224**}`, tb 0, và **0 dòng `missing selected impact`** trong cả log phiên | **CHẠY ĐỦ**: sau khi người điều phối sửa 282 ô `params` của `native_config`, `native.interval_167` phát được bậc hội tâm (4192, 4224) và hết hẳn lỗi vô tận của 17.5 |
| **3809 高唐云散** (nhóm con rối) | `live\i` 16:10 | bot bản mới đếm **`unknown_packets = 6`, `unknown_first_id = unknown_last_id = 786`**; `buffs_self = {334, -1 ×2, 4321, 4322}`; tb 0 | **GÓI 786 ĐI TRỌN ĐƯỜNG**: server dựng bảng thuần → `scenecore:broadcast` → `skynet.send` (đóng gói được) → `net:send2client` tra được `self.packets[786]` → `bos()` 12 byte ra dây. Việc 1 **XONG** |

Vì sao 2901 trượt còn 826 trúng, dù cả hai đều `命中率 = -1`: phép quay nằm ở `skill:is_hit`
(`scene/skill/base.lua:935`) — `combat:calculate_hit_rate(obj_me:get_hit(), obj_tar:get_miss())` cộng
`skill_info:get_accuracy_rate_up()`. Khác biệt là **thuộc tính/chỉ số**, không phải mã của lượt này
(4465/4466 trúng 47/47 vì `命中率 = 100`). Muốn chốt 2901 thì cần một phiên nó trúng — khi đó dòng
`[skill_cy_spec] bay 3064 mang _custom_descriptor 效果1 = <37316…37331>` sẽ hiện ra.

### 17.9 Việc còn lại

1. Đo live 2901 / 826 theo 17.8 (chỉ cần một lần restart nữa).
2. **Ngoài `skill-logic`:** (a) `native_config.impacts[4465–4476, 45181–45196].params` trỏ dải 60953–60962 không
   tồn tại — người phụ trách `cy_four_combat` nhận (17.5); (b) `CysNetBot` phải bỏ qua id gói lạ thay vì
   `strict packet decode failed`; (c) nhập dòng CY `1109` cho 4465/4466 (17.3); (d) 16 dòng `冰蚕buff`
   59864–59879 cho 445 (17.6).
3. **2905 暴雨梨花针** không nằm trong danh sách lượt này — `96-best-of.tsv` đã xếp nó là `chay` (nó chạy khi tung
   sau 2901). Phần còn thiếu của nó vẫn đúng như mục 14.5: bộ đếm **飞针入穴** (đủ 5 lần bị hội tâm thì nổ AOE
   5 m / 4 mục tiêu) **không có ô nào trong dữ liệu** ⇒ cần một logic impact mới theo khuôn `std_impact_101/102/103`.
4. Chưa làm trong lượt này: `驱散二式buff集合` (204 / 206 / 208), 734 / 735, 766 / 770, và danh sách còn tồn của
   mục 3 / 13.9 / 16.8.
