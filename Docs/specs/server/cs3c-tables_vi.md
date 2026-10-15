# CS3c (phần còn lại) — Impact/Bullet, Monster/Pet, CommonItem/ShopTable, drop theo ID CY; cầu nối cy_four theo ID CY; quái cảnh 2

Ngày: 14/09/2026. Agent `cs3c-tables`, nhánh `cs3c-tables`. Bằng chứng: `Build/Logs/2026-09-14-cs3c-tables/`.
Tiếp nối `cs3b-menpai_vi.md` (mục 3.5 việc còn lại). Kế hoạch mẹ: `Docs/specs/cy-switch_vi.md` (CS3c). Server riêng: `Docs/specs/net/cys-server_vi.md`.

Quy ước: **[DK]** dữ kiện đo được (đường dẫn/dòng). **[SL]** suy luận. `R` = `/home/ubuntu/cys-test-20260913`.
Nguồn chỉ đọc: **CY** = bảng client CY 3.71 (`Tools/DATA NEW/DataCY31-08-26/Config`, không tên cột); **HJP** = `tlbb15/Public/Config` (bố cục GL + tên cột, ID CY);
**HJS** = `tlbb15/Server/Config` (bảng chỉ-server của HJ: `StandardImpact`, drop, ShopTable — ID CY, có tên cột); **GL** = bảng server riêng tại `995c2df` (trước CS3b).
Registry cột: `Registry/abi/dbc_columns_cy.tsv` (căn theo ID chung; đã kiểm lại trên dòng cùng ID **cùng tên** và bằng ma trận HJP↔CY, `scripts/03,04-survey-*.json`).

## 0. Kết quả

| Việc | Trạng thái |
|---|---|
| Bảng server theo ID CY | StandardImpact 23.523 (HJS 23.520 + 3 GL cùng tên), ImpactSEData 9.419, ImpactDirectly 523, Bullet 337, MonsterAttrEx 28.968, PetAttr 8.587, PetHuanhua 7.039, PetSkillBook 125, CommonItem 20.421, ShopTable 383, MonsterDropBoxs 677, DropBoxContent 183, DropRateOfItemTable 233, PetCollection 648 (GL dời theo tên); EquipBase cột 19 ← CY (2.907 dòng) |
| Dòng chỉ-GL | lưu `R/configs/cys_gl_only/` (không nạp): StandardImpact 6.348, ImpactSEData 144, ImpactDirectly 15, MonsterAttrEx 1.015, PetAttr 602, CommonItem 992, ShopTable 3 (419–421), PetHuanhua 553, PetCollection 582, drop GL cả 3 bảng (518/1.645/227) + `PetAttrTable.cy_placeholder.txt` (2 dòng CY 新珍兽 không có quái) |
| cy_four_* | chuyển sang ID CY: `native_config/phase2_config/release_config/deployment_config` khoá theo ID CY, mọi map `resolve` thành đồng nhất, 245 dòng StandardImpact cầu nối mang `logic = 8000 + donor_logic`; `template_factions` lấy số phái từ SkillTemplate CY (86 giữ, 28 kỹ năng chung 门派 = −1 bỏ khỏi cổng) |
| Lua ghi cứng impact GL | 借力状态 19001 → **69001** (cfghelper + std_talent_953; HJS 19001 = 高级血爆); 1331 玉女穿梭(定身) trùng tên ở HJS giữ; 12608 春光四沐/8425 弑神闪 không có ở HJS → giữ, ghi rủi ro (mục 6) |
| Cảnh 2 `dali_new_320_monster.ini` | `cs3a_scene.py retype`: 4 NPC đổi type theo tên CY (阿紫 49455→6, 萧峰 51296→16669, 黄时雨 56011→17033, 景言 56015→17340), 20 mục chỉ-GL tắt (`pos_x=;`) — 179 mục sống, 179/179 có trong MonsterAttrEx |
| Kiểm chéo (`verify-3.json`) | Pet↔Monster 8.587/8.587; skill trân thú 39.834/39.834; 子弹ID 566/566; EquipBase impact 2.907/2.907; DID drop 3.225/3.225; AI 0 lỗi; PetSkillBook 125/125; cảnh 2 179/179; luac 9/9; config cy_four nạp bằng lua5.4: 238/238 khoá = donor, resolve 1.128/1.128 đồng nhất |
| Server riêng | 9 commit `ed09b4f → 20ac324 → 5a4529a → 1832b0c → 9c0702c → 9bf174a → 4348f46 → a297101 → 2ccf33a`, backup `R/backups/20260914T150322Z-truoc-cs3c-tables` (Mongo 4 DB, 39 file) và `R/backups/cs3c-20260914T150323Z/` (46 file cũ) + `cs3c-20260914T15{0635,1349,1501}Z/` |
| Restart / bot | Restart 1 (22:10:43, 0 client/0 Game.exe) → mọi cảnh `SCENE_CREATE_FAIL` (jue_skill_config, mục 3) → sửa → **restart 2 22:15:36, 15733 LISTEN 22:18:07**: 0 traceback, 0 SCENE_LOAD/INIT_FAIL, 127 `MONSTER_CFG_FAIL` (ID quái chỉ-GL 49781/49970/50147/56003… ở cảnh 1311/1312/1321…, bỏ qua theo guard audit 11/09), cảnh báo cũ AIScript 97/Memory. Bot `run_world_live.ps1` 22:19:45 **PASS 8/8** (`bot-live-1/`): login → `AUTO_ROUTE_ENTER` cảnh **73 无量山2** (59,9;151,6 — vị trí nhân vật do phiên live của agent khác đặt trước đó, không phải cảnh 2) → 12 `GCNewMonster`, 2 bước, CGAskQuit; log server 0 lỗi mới sau 22:19; Mongo GUID 200001 không đổi (`post-bot-1.txt`, `char-inspect-1.json`) |

## 1. Từng bảng: cột server ↔ cột CY, số dòng, ID trùng số khác nghĩa **[DK]**

Bằng chứng: `scripts/01-survey-tables.out.txt` (tab/cột/GBK), `03-survey-tables.json` (registry trên dòng cùng tên, tham chiếu chéo),
`04-survey-cols.json` (ma trận HJP↔CY), `staging-3/plan.json` (`agreement_on_same_name_rows`, `row_source`, `notes`).

Cách dựng chung (khuôn cs3b): mỗi dòng CY thành một dòng server theo **bố cục cột GL** (server đọc theo tên cột). Cột có ánh xạ ← CY; cột chỉ-server ← dòng GL cùng ID **cùng tên**,
không thì giá trị phổ biến nhất của cột GL. GBK từng byte, CRLF/LF như file GL, ID tăng dần. Dòng GL có ID không có ở CY → `cys_gl_only` (+ `reserved_ids.tsv` = ID dải riêng đề xuất).

| Bảng | Cột GL/CY | Dòng CY / GL / server mới | Cùng ID khác tên (GL↔CY) | Ánh xạ cột (GL ← CY) | Cột chỉ-server |
|---|---|---|---|---|---|
| StandardImpact | 81 / — (HJS 155) | — / 18.167 / **23.523** | GL↔HJS cùng ID 11.816, cùng tên 5.994: dải 0–2k, 6k–10k, 18k, 30k trùng; 3k–5k, 11k–12k, 22k–28k, 42k+ GL đánh số riêng | HJS 0–75 → R 0–75 **cùng tên và vị trí** (27 cột cố định + 16 bộ `参数k说明/参数值/修正步长` + `效果描述`); R 76–80 rỗng | không (HJS là bảng server) |
| ImpactSEData_V1 | 23 / 28 | 9.419 / 5.200 / 9.419 | 5.056 chung, 3.859 khác `效果说明` (GL sửa chữ) | R k ← CY k, k = 0–21 (cùng kiểu, cùng vị trí; registry ghi R8←CY7 chỉ 0,62 → bác); CY 22–27 bỏ | R 22 rỗng. Server chỉ đọc `ID`, `图标文件名` (`cfghelper:2145`) |
| ImpactDirectly | 20 (bố cục HJP) / 25 | 523 / 348 / 523 | — | HJP k ← CY: 1–3←1–3, 4–6←5–7, 7–9←9–11, 10–12←13–15, 13–15←17–19, 16/17←21/22, 18←23, 19←24 (CY thêm cột INT sau mỗi nhóm) | server **không nạp**; bản GL mang nhầm tên cột ImpactSEData → viết theo HJP |
| Bullet | 16 / 16 | 337 / 178 / 337 | 178 chung, 62 khác tên | R 0–8 ← CY 0–8 (registry 0,99–1,0); R14 描述 ← CY13; R15 标记 ← CY14 | 预留1–5 rỗng. Server không nạp (client dùng) |
| MonsterAttrExTable | 71 / 73 | 28.968 / 18.822 / 28.968 | 17.807 chung, **6.668 khác tên** (vd 49455 阿紫 GL = 星宿第一人 CY) | R 0–3 ← CY 0–3; R12–43 ← CY 4–35; R44 外型ID ← CY36; R45–69 ← CY37–61; **8 cột chỉ-server có ngay trong bảng CY**: R4 基础经验 ← CY66, R6 休闲间隔 ← CY64, R7 基础AI ← CY68, R8 扩展AI ← CY69, R9 阵营 ← CY70, R10 掉落半径 ← CY71, R11 掉落最大有效组 ← CY72 (HJP↔CY 100 % trên 27.136 dòng cùng tên) | R5 友好值 (GL toàn 0), R70 指定技能 (GL, chỉ std_impact_331/525 đọc `params`) ← GL cùng tên / mặc định |
| PetAttrTable | 51 / 54 | 8.589 / 5.006 / **8.587** | 4.404 chung, 1.283 khác tên | R0,1 ← CY0,1; R2–22 ← CY3–23; R33–50 ← CY24–41 (= memory `tlbb-pet-add-2026`: bỏ CY 2/42/43/44–53) | R23–32 被动技能6–10 (CY không có) ← GL cùng tên / −1,0 |
| PetHuanhuaTable | 5 / 6 | 7.039 / 4.011 / 7.039 | — | R0,1,2 ← CY0,1,2; R3 金币 ← CY4; R4 ← CY5 (CY3 = 幻化外观3, server chỉ đọc 1/2) | — |
| PetSkillBook | 2 / 2 | 125 / 125 / 125 | 26 dòng khác kỹ năng | R ← CY | — |
| CommonItem | 27 / 28 | 20.421 / 10.093 / 20.421 | 9.101 chung, 2.346 khác tên (vd 20307193 枕月发型图 GL = 花间发型图 CY) | R0–14 ← CY0–14; **R15 是否消耗 ← CY27** (HJP 6.837/6.843); R16–24 ← CY15–23; R25 是否广播 ← CY24 (registry 0,986); R26 "INT" ← CY25 | — |
| ShopTable | 1.227 / 1.229 | 383 / 386 / 383 | ID chung 383 | R0–17 ← CY0–17; R18–25 杀气折扣 ← CY21–28; R27+6j+m ← CY29+6j+m (PID/PNUM/PMAX/价格/折扣/颜色, 200 món); CY18–20 bỏ | R26 `is_yuanbao_shop` ← GL cùng Index (0/2) |
| MonsterDropBoxs / DropBoxContent / DropRateOfItemTable | 23 / 517 / 9 | HJS 677 / 183 / 233 (GL 518 / 1.645 / 227) | GL khoá theo ID quái/gói GL | thay nguyên bảng HJS, **tên cột GL** (HJS DropBoxContent lặp tên `Item16ID` → txtreader gộp mảng) | — |
| PetCollection (GL, CY không có) | 4 | 1.230 → 648 | — | `data_id` giữ khi CY cùng ID cùng tên; 582 dòng tên không duy nhất ở CY → lưu trữ | — |
| EquipBase (cột 19) | — | 24.531 | — | cột 19 impact ← CY cột 101 khi ID có trong StandardImpact mới (2.907), không thì −1 (516 ID CY tham chiếu không có ở HJS) | — |

### 1.1 AI quái **[DK + SL]**
- CY dùng `基础AI` 47–98 cho 1.704 quái (HJ có bảng AI lớn hơn); `MonsterAITable.ini` của skynet chỉ có AI0–AI34 (HJP ini 32). Xử lý: GL cùng tên hợp lệ (6) → giữ; `是否可以交互 = 1` (695) → **AI3** (không đánh, không đi); còn lại (1.009) → **AI1** (không chủ động, đánh trả) **[SL]**.
- `扩展AI` không có trong `AIScript.dat` (270 script): 63 dòng → −1.
- Bảng đã áp: 0 quái AI ngoài bảng (`verify-3.json` `monster_ai`).

### 1.2 StandardImpact — độ phủ **[DK]**
- SkillData CY (server) tham chiếu 22.406 lần / 16.113 impact khác nhau: **10.843 ID có ở HJS** (15.728 lần). 5.273 ID (dải 5k, 21k, 37k, 42k, 49k, 54k–58k…) không có: tlbb15 (HJS max 55.484) **cũ hơn** client 3.71.9609 → kỹ năng đó không có hiệu ứng phía server (`init_impact_from_data` trả false im lặng). 515 ID trong số đó có ở GL nhưng khác đánh số; chỉ 3 dòng GL trùng tên kỹ năng tham chiếu (仙风道骨 14–16) được lấy (`gl_name_rows`).
- HJS trỏ `瞬发效果ID` 21.012 lần, 18.123 có trong ImpactSEData CY; 2.880 trỏ SE 19615–19902 (HJ riêng, client CY không có → không vẽ, không crash [SL]).
- Logic ID HJS không có `std_impact_<n>.lua`: 97 logic / 4.193 dòng (97, 151, 43, 83, 149, 114, 162, 130…) → `register_all_impact_logics` rơi về `std_impact_003` (hành vi sẵn có với logic 2/6/16/71… của GL). HJS logic 8507/8513 (2 dòng 定身, 逻辑说明 = STD_IMPACT_014) → **14** [SL] để qua assert `logic_id < 8000 or bridge`.
- 245 dòng CY là impact cầu nối cy_four (`config.impacts`): logic đổi thành `8000 + donor_logic` như GL đã làm với bản sao 59909–61196 (GL 59909 流云矢 = HJS 3699 流云矢, khác SE 1010/275).

## 2. Phụ thuộc chéo **[DK]**
- SkillData(CY) → StandardImpact(HJS) → ImpactSEData(CY): mục 1.2. EquipBase 19 → StandardImpact 2.907/2.907.
- SkillTemplate 子弹ID → Bullet 566/566. PetAttr → SkillTemplate 39.834/39.834. PetAttr.id = MonsterAttrEx.id 8.587/8.587 (2 placeholder CY `新珍兽` 34670/34671 bỏ).
- ShopTable PID → CommonItem/EquipBase/GemInfo/PetEquipBase: 6.875/7.360 (485 lần trỏ 30800000–30800019… CY tự thiếu; GL cũ cũng thiếu 550/7.225, server chịu được).
- MonsterDropBoxs (HJS) → MonsterAttrEx CY 652/677; DID → DropBoxContent 3.225/3.225; vật phẩm trong gói 322/500 (HJS thiếu, như GL cũ thiếu 465/6.269 — `itemdropmanager` chỉ log).
- PetHuanhua 旧外观ID → PetAttr 7.039/7.039. PetSkillBook item/skill 125/125.
- Mọi cảnh: 2.202 type quái trong `*_monster.ini`, 2.046 có ở CY; 40 ID chỉ-GL (49285–49289, 56000–56114…) và ~6.668 ID **đổi nghĩa** ở các cảnh chưa qua CS3a (mục 6).

## 3. cy_four_combat / cy_four_training_config **[DK]**
- `native_config.lua` đã chứa sẵn map CY→GL: `resolve.impacts` (1.128), `skill_templates` (138), `skill_data` (1.313), `xinfa` (32), `phase2.monsters` (6). Tool đảo map để đổi khoá: `config.impacts` 238 + phase2 6 + release 1 (khoá = `donor_id`), `skill_instances` 12 (+ `combat/specific`), `donor_skill_templates` 114, `disabled_impacts` 3, `tao_damage_scaling` 12, `resource_costs` 36; mọi `resolve.*` thành đồng nhất (`[k]=k`); `template_factions` 114 → 86 (số phái = SkillTemplate CY cột 2; map GL lệch ở 桃花岛/绝情谷: 3828–3861 ghi 14 nhưng bảng là 13/−1).
- `jue_skill_config.lua` (55 dòng, `phase2.lua:19` nạp làm `config.jue_skill_instances`): khoá GL SkillData 35763… → `donor_data_id` (CY 14552…), `target_template_id` → `donor_template_id` (CY 3840…), `p4/p5` 60980/60882 → 13262/4890. **Lần restart 1 (22:10) mọi cảnh `SCENE_CREATE_FAIL`** vì `jue_hooks.readiness` đòi đúng namespace CY cho file này (`wait-logcheck-1.txt`); sửa ở commit `a297101`/`2ccf33a`, `verify` nay mô phỏng `jue_hooks.readiness` bằng lua5.4 (`jue_ready = true`).
- `deployment_config.collections[510].ids`: 4 ID GL (5619/5649/5687/5723) → CY (2900/3430/3800/4515); các ID khác trong `ids` (281, 311…, 788) không nằm trong map → giữ [SL: là ID chung của CY].
- Map CY→GL luôn đọc từ bản GL trong git (`git show 995c2df:`), vì sau khi áp, file trong `R` chỉ còn map đồng nhất (bẫy lần plan-7).
- Không đổi: `collections` (đánh số nội bộ, trừ `ids` trên), `special_objects` (SpecialObjData server vẫn GL), `cy_four_training_config.lua` (cs3b đã ID CY), 37 file logic.
- Cổng `availability.allowed` nay áp lên kỹ năng CY 4 phái (`donor_skill_templates` khoá CY): cần `menpai_registry.check_ready` phái 11–14 (cs3b: sẵn).
- Kiểm: `lua5.4` nạp `deployment_config` + `phase2_config` (không cần skynet): 238/238 khoá = donor, 1.128/1.128 resolve đồng nhất, 86/86 template_factions khớp SkillTemplate.

## 4. Công cụ `Tools/server/cs3c_tables.py` (+ `cs3a_scene.py retype`)
Chạy trong WSL root: `python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/cs3c_tables.py <lệnh>` (import `cs3b_menpai.py` cùng thư mục).

| Lệnh | Việc | Chạm `R`? |
|---|---|---|
| `plan --out <dir>` | dựng 15 bảng + `cys_gl_only` + 6 file Lua + `dali_new_320_monster.ini` (qua `cs3a_scene.py retype --map`) vào `<dir>/{configs,lua,scene}`; `plan.json` (ánh xạ, nguồn dòng, khớp cột trên dòng cùng tên, log cy_four, retype) | không (GL từ `git show 995c2df:`) |
| `apply --staging <dir> [--dry-run]` | chép vào `R`, sao lưu `R/backups/cs3c-<UTC>/`, trùng byte bỏ qua | có |
| `verify [--staging] [--out]` | GBK toàn file, tab, ID, tham chiếu chéo mục 2, logic ≥ 8000 phải là cầu nối, AI trong bảng, luac 9 file, nạp thử config cy_four bằng lua5.4, staging = R | không |

Đã kiểm: plan 2 lần trùng byte (`21-idempotent-dryrun.out.txt`); plan trên `R` đã áp → apply 0 file đổi (`33-cleanup-comment.out.txt`).

## 5. Áp, restart, kiểm, hoàn tác
- `cys_server.ps1 backup truoc-cs3c-tables` → apply → verify → 4 commit theo nhóm bảng (`30-apply-commit.out.txt`), rồi 2 commit sửa (template_factions/PetAttr placeholder; chú thích).
- Restart chỉ khi 0 client, `Get-Process Game` rỗng, 0 TCP 15733/15734 (`45-idle-restart.ps1`, kiểm mỗi 60 s ≤ 20 phút); `40-restart.sh` → `41-wait-and-logcheck.sh` (≤ 900 s, so lỗi log với lần khởi động cs3b). Kết quả: `restart-1.txt`, `wait-logcheck-1.txt`; bot: `bot-live-1/`; sau bot: `post-bot-1.txt`.
- Hoàn tác: `git -C R revert <6 commit>` rồi restart; hoặc chép lại `R/backups/cs3c-20260914T150323Z/` (+ `cs3c-20260914T150635Z/`); DB không đổi (`cys_server.sh restore backups/20260914T150322Z-truoc-cs3c-tables` nếu cần).

## 6. Rủi ro còn lại / việc sau
- **5.273 impact CY không có bảng server** (tlbb15 cũ hơn client): kỹ năng mới 2024–2026 không có hiệu ứng; cần nguồn StandardImpact CY mới hơn hoặc dựng tay theo SkillData.
- 97 logic ID HJS chưa cài (4.193 dòng) rơi về logic 3 (sát thương theo `伤害数值`): có thể sai hiệu ứng/tham số nil khi chiến đấu; cần cài dần theo `逻辑ID的说明` (`StdImpact097` = toạ kỵ, 151 寒冰化劲, 43 中冲破抗…).
- Lua GL giữ hằng impact GL: `murong_skill_common.lua` 12608 (春光四沐 — HJS không có), `skill_73.lua` 8425 (弑神闪), `std_impact_543.lua` 19183–19192 (归一剑; logic 543 không còn dòng nào) → chỉ chạy khi SkillTemplate CY dùng logic 73/543 → trỏ dòng CY khác nghĩa; nên đổi thành tra theo tên hoặc tắt.
- Các cảnh ngoài cảnh 2 vẫn dùng `_monster.ini` GL: ~6.668 ID quái đổi tên/model ở CY (vd 阿紫 → 星宿第一人), 40 ID chỉ-GL thành `MONSTER_CFG_FAIL` (đã có guard audit 11/09). Việc của CS3a tiếp (Lạc Dương, Tô Châu…): dùng `cs3a_scene.py retype` với map theo tên.
- Script nhiệm vụ/NPC (`Game_2/Script`, hàng nghìn ID quái/vật phẩm GL) chưa đổi nghĩa; CommonItem/EquipBase script cột 脚本编号 CY tham chiếu script CY không có ở skynet (GL cũng thiếu 158).
- 曼陀山庄, 神兵/PetSoul/Goku/Iron Man/二郎, thời trang/tọa kỵ 2026, shop 419–421 vẫn ở `cys_gl_only` (cs3b 3.4).
- Mongo nhân vật test: túi/kỹ năng không đổi (không có item GL đổi nghĩa cần dời trong lượt này — `char-inspect` cs3b); nếu có nhân vật khác mang item/pet GL thì ID đã đổi nghĩa.

## 7. Bẫy gặp trong pha này
- `tlbb15/Server/Config/StandardImpact.txt` là nguồn CY duy nhất của bảng chỉ-server; `Public/Config/Impact.txt` (19 dòng) là bảng khác.
- Bảng CY MonsterAttrEx 73 cột **chứa luôn 8 cột chỉ-server** (64–72) → không cần tlbb15 để bù.
- HJS DropBoxContent lặp tên cột `Item16ID` (thay cho Item14ID) → phải dùng tên cột GL, nếu không `txtreader` gộp thành mảng.
- `register_all_impact_logics` assert mọi logic ≥ 8000 phải do cầu nối đăng ký → HJS 8507/8513 phải đổi.
- `_monster.ini` GL dùng dòng MonsterAttrEx **không tên** (50059…) làm tượng người chơi với `name=` tuỳ biến (紫禁|醉温柔…) → ở CY là 天山内息… → tắt.
- Bảng HJP `PetAttrTable` cột 主动技能 toàn 0 (HJ đổi cơ chế) → không dùng HJP làm nền cho PetAttr; CY có đủ.
- Bash tool phá `\\` trong heredoc Python (2 lần: script cs3a `retype`, patch rekey) → sửa bằng Edit tool.
- `plan` chạy trên `R` đã áp phải tự nhận biết chú thích đã có (lần 4 lặp chú thích → sửa idempotent) và phải lấy map CY→GL từ git, không từ file đã đổi (lần 7: `p4` 60980 không đổi được).
- `cy_four_combat` có **6** file cấu hình sinh máy (native/phase2/release/deployment/jue_skill_config + resources trong deployment), không phải 4; thiếu một file là mọi cảnh chết lúc `scenecore.lua:253 startup.configure()` (assert), không phải lỗi nhẹ.
