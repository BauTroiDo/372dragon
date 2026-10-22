# CS3b — Môn phái theo CY + CS3c (phần đầu): XinFa/SkillTemplate/SkillData/EquipBase theo ID CY trên server riêng

Ngày: 14/09/2026. Agent `cs3b-menpai`, nhánh `cs3b-menpai`. Bằng chứng: `Build/Logs/2026-09-14-cs3b-menpai/`.
Kế hoạch mẹ: `Docs/specs/cy-switch_vi.md` mục 4.6, 6 (CS3b/CS3c), 9. Server riêng: `Docs/specs/net/cys-server_vi.md`; bản đồ: `cs3a-maps_vi.md`.

Quy ước: **[DK]** dữ kiện đo được (đường dẫn/dòng). **[SL]** suy luận. `R` = `/home/ubuntu/cys-test-20260913`.
Nguồn chỉ đọc: CY = bảng text S2 `Tools/DATA NEW/DataCY31-08-26/Config` (cùng nội dung `Assets/CanonicalCY/Data` 3.71.9609, có 2 dòng kiểu,
không có tên cột); tlbb15 (HJ) = `Tools/DATA NEW/DataCY31-08-26/tlbb15/Public/Config` (bảng server có tên cột, đọc tĩnh, không chạy, không đọc `config.yaml`);
GL = bảng server riêng tại commit `995c2df` (trước CS3b). Registry cột: `Registry/abi/dbc_columns_cy.tsv`.

## 0. Kết quả

| Việc | Trạng thái |
|---|---|
| Ánh xạ số môn phái GL ↔ CY | Đo bằng tên tâm pháp (mục 1); áp vào 5 bảng + 45 file Lua + `BaseValueTable.ini` + `Exterior_Ride.txt` |
| Bảng server theo ID CY | XinFa_V1 (120), SkillTemplate_V1 (4.586), SkillData_V1 (20.667, nới 48→54 cột), EquipBase (24.531), XinFaStudySpend_V1 (302) |
| Dòng chỉ-GL | 56 + 2.239 + 4.910 + 6.596 dòng lưu ở `R/configs/cys_gl_only/` (không nạp), kèm bảng ID dải riêng đề xuất |
| Server riêng | 3 commit `9bff727` → `af7a3f2` → `8761c93`; restart 17:53:58 → 15733 LISTEN 17:57:22; log 0 traceback, 0 SCENE_*_FAIL |
| Nhân vật test | `CYTest00` (GUID 200001) menpai 9 giữ 9; `skill_list` bỏ 3238 (`填入`, CY không có); xinfa rỗng |
| Bot live | `Tests/net/run_world_live.ps1` 18:13:53 **PASS 8/8** (`bot-live-1/`): login → `AUTO_ROUTE_ENTER` cảnh 2 (160,150) → 2 bước → CGAskQuit; log server 0 lỗi mới; Mongo sau lượt: `skill_list` 9 kỹ năng CY, menpai 9 (`char-inspect-2.json`) |

## 1. Ánh xạ số môn phái **[DK]**

Bằng chứng: `scripts/02-xinfa-compare.out.txt` — 120 tâm pháp CY khớp tên 100 % với 120/128 tâm pháp server (tlbb15 trùng CY 120/120 cả tên lẫn ID).
Tên phái phía server: `GameServer/lualib/define.lua` `MENPAI_ATTRIBUTE` / `ENUM_MENPAI_CHN` (GL); `menpai_extensions.lua` (4 phái nhập 09/09).

| GL / server cũ | Tên | CY 3.71 | Xử lý |
|---:|---|---:|---|
| 0–8 | 少林 明教 丐帮 武当 峨嵋 星宿 大理 天山 逍遥 | 0–8 | giữ (tâm pháp 1–54, 55–63, 72–80 cùng ID) |
| 9 | 无门派 | 9 | giữ |
| 10 | 曼陀山庄 | **không có** | dời sang ô **16**, **tắt** (mục 1.1) |
| 11 | 恶人谷 | 15 | tâm pháp 81–88 → 113–120 |
| 12 | 慕容 | 10 | tâm pháp 89–96 → 64–71 |
| 13 | 唐门 | 11 | tâm pháp 97–104 → 81–88 |
| 14 | 鬼谷 | 12 | 105–112 → 89–96 |
| 15 | 桃花岛 | 13 | 113–120 → 97–104 |
| 16 | 绝情谷 | 14 | 121–128 → 105–112 |

Nhận xét **[DK]**: GL đặt 曼陀山庄 lên dải tâm pháp 64–71 và kỹ năng 760–787, tức đúng dải mà CY dành cho 慕容; vì vậy ID GL của 曼陀 va chạm ID CY của 慕容
(ví dụ GL 110 = 曼陀山庄轻功, CY 110 = 慕容轻功). Ba ô quick-skill GL của 曼陀 `{760,771,775}` trùng số với ba kỹ năng cấp 1 của 慕容 CY (柳拂衣/重云掩日/剑锁江山).

### 1.1 曼陀山庄 (server có, CY không có)
- Giữ ở ô **16** (ô duy nhất còn trống ≤ 16 sau khi dời, mọi mảng/`BaseValueTable`/`AttrLevelUpTable` giữ kích thước) với `enabled` mặc nhiên tắt:
  tâm pháp của nó không còn trong `XinFa_V1.txt` nên `menpai_registry.check_ready` trả `eight_xinfa_required` → không gia nhập/đổi phái được;
  `SETTING_MENPAI_SKILLID[16] = {}`; `MENPAI_7_XINFA/8_XINFA = 1070/1071`, `QINGGONG_SKILL = 50110`, `MENPAI_7_SKILLS = {50785,50784,50786}` = ID dải riêng
  (mục 3.4), chưa có dòng nào trong bảng.
- 26 kỹ năng, 8 tâm pháp và script NPC `Game_2/Script/scripts/obj/mantuo/*` giữ nguyên mã, chỉ đổi số so sánh `== 10` → `== 16`.
- Muốn bật lại: nhập 8 tâm pháp + 26 kỹ năng vào dải riêng ở **cả client lẫn server** (bảng CY client không có), rồi đăng ký `LEGACY_IDS`.

### 1.2 Mọi nơi số phái xuất hiện **[DK]** (`scripts/01-survey-server.out.txt`, `05-*`, `08-*`, `10-*`)

Phía server (`R`), tất cả đã đổi bằng `Tools/server/cs3b_menpai.py` (mục 2):

| Nơi | Cách dùng số phái | Đã đổi |
|---|---|---|
| `configs/XinFa_V1.txt` cột 1 `门派ID` | server chỉ đọc `menpai` (`cfghelper.read_xinfa_v1`) | thay cả bảng bằng CY |
| `configs/SkillTemplate_V1.txt` cột 2 `门派` | `template.menpai`; registry đếm kỹ năng theo phái | thay cả bảng bằng CY |
| `configs/EquipBase.txt` cột 12 `门派需求` (STRING) | yêu cầu phái khi mặc | thay cả bảng bằng CY |
| `configs/BaseValueTable.ini` mục `[MENPAIn]` | `base_value_table["MENPAI"..id]` (registry.check_ready) | đổi tên mục 10–16 |
| `configs/AttrLevelUpTable.txt` cột `<tên phái>力量…` | tra theo **tên** `ENUM_MENPAI_CHN[id]` | không cần đổi |
| `configs/Exterior_Ride.txt` cột 6 `门派` | 27 dòng có 10–16 (thú cưỡi 4 phái + 曼陀) | đổi số |
| `lualib/define.lua` | `MENPAI_ATTRIBUTE`, `ENUM_MENPAI_CHN`, `SETTING_MENPAI_SKILLID` (khoá số); các bảng còn lại khoá theo enum | đổi số + ID skill/xinfa (mục 3) |
| `lualib/menpai_registry.lua` | `LEGACY_MAX_ID = 12` (legacy ≤ 12, extension 13–25) | thay bằng tập `LEGACY_IDS = {0..8,10,15,16}` + `is_legacy()` |
| `lualib/menpai_extensions.lua` | khoá 13–16 = 4 phái nhập | khoá 11–14, ID CY |
| `lualib/cy_four_training_config.lua` | `menpaiId`, `factions[13..16]`, sách (`id` = xinfa/skill GL) | số CY + ID CY |
| `lualib/cy_four_combat/{native_config,phase2_config}.lua` | `reverse_faction` GL→donor(CY), `resolve.faction` donor→GL | thành đồng nhất |
| `lualib/cy_four_combat/{release,resource_feedback}.lua` | so `get_menpai()` với 15/16 | 13/14 |
| `services/scene/obj/human.lua:8626` | `> LEGACY_MAX_ID` | `not is_legacy()` |
| `services/scene/skill/human/skill_751.lua` | 化气式: `10 ≤ phái ≤ 11` | `10 ≤ phái ≤ 15` (SkillData CY có tham số `门派%d技能ID` mọi phái) |
| `services/scene/skill/talent_logic/std_talent_671.lua` | `~= 11` (恶人谷) | `~= 15` |
| `Game_2/Script` 30 file (`obj/mantuo/*`, `obj/erengu/*`, `obj/gusu/*`, `event/{mantuo,erengu}/shimen_09*`) | `nMenPai == 10/11/12` | 16/15/10 |
| `Game_2/Script` `odali_azi.lua`, `NewLua/newchangsong.lua` (đổi phái) | `menpai > 13` | `> 15` |
| `Game_2/Script` `item_100019_38000958.lua` | `> 12` | `> 15` |
| `Game_2/Script/scripts/GmTool_Self.lua` `change_menpai` | `p1 > 16` | `p1 > 15` (16 tắt) |
| `lualib/jianzong_ranklist.lua` | dữ liệu xếp hạng mẫu `menpai = 10` (21 chỗ) | 16 |
| Mongo `tlbb.character.attrib.menpai` | 1 nhân vật test, giá trị 9 | giữ 9 (script có sao lưu) |

Không đổi: `MENPAI_REPUTATIONS` (ID danh vọng), `MENPAI_ABILITYS` (ID nghề), `attack_traits`, `reputation` (khoá theo enum, giá trị không phải số phái).

Phía client: bảng CanonicalCY đã đúng số CY (CS1). `client_GL` (GM tool `gmSectNames` 17 mục, số 13–16 GL) chỉ đọc, không phải đích.

## 2. Công cụ `Tools/server/cs3b_menpai.py`

Chạy trong WSL root: `python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/cs3b_menpai.py <lệnh>`.

| Lệnh | Việc | Chạm `R`? |
|---|---|---|
| `plan --out <dir>` | dựng 5 bảng + Exterior_Ride + BaseValueTable + mọi file Lua vào `<dir>/{configs,lua}`; `plan.json` (ánh xạ cột, tỉ lệ khớp, nguồn từng dòng, log tra ID) | không (đọc `git show 995c2df:` để lấy GL) |
| `apply --staging <dir> [--dry-run]` | chép vào `R`, file cũ sao lưu `R/backups/cs3b-<UTC>/`; file trùng byte → bỏ qua (idempotent) | có |
| `verify [--staging <dir>] [--out json]` | GBK toàn file, số tab từng dòng, ID duy nhất/tăng dần, cấp kỹ năng ↔ SkillData, xinfa ↔ phái, `luac5.4 -p` 41 file, mọi ID trong define/extensions/SETTING tồn tại đúng phái, mục BaseValueTable, staging = R | không |
| `mongo-inspect` / `mongo-apply --staging <dir> --out <json>` | chỉ bản ghi GUID 200001: menpai theo ánh xạ, `xinfa_list`/`skill_list` tra ID CY theo tên, bỏ ID không có; `mongo-apply` từ chối khi còn client, ghi bản sao toàn bộ document trước khi `$set` | Mongo riêng |

Đã kiểm: `plan` chạy hai lần cho kết quả trùng byte (`scripts/23-idempotent-diff.out.txt`); `apply --dry-run` liệt kê 55 file; `verify` sau apply `ok` (`verify-1.json`: 140 kiểm ID OK, luac 41/41).

### 3.1 Cách dựng chung
Mỗi dòng CY (theo ID CY) thành một dòng server theo **bố cục cột GL** (server đọc theo tên cột, `txtreader.lua`):
1. Nền = dòng tlbb15 cùng ID **và cùng tên** (tlbb15 dùng bố cục cột GL với tên cột, ID = CY) → nếu không, dòng GL cùng ID + cùng tên (+ cùng phái sau ánh xạ) → nếu không, mặc định = giá trị phổ biến nhất của cột trong tlbb15.
2. Đè cột CY theo ánh xạ cột (registry + sửa ở mục 3.2), nên cột client nhìn thấy luôn là CY.
3. Ghi GBK từng byte (ô CY/HJ/GL đều GBK), CRLF/LF như file GL; ID tăng dần.

| Bảng | Cột | Dòng CY | Nguồn dòng nền (hj/gl/mặc định) | Lưu trữ chỉ-GL |
|---|---:|---:|---|---:|
| XinFa_V1 | 29 (CY 37: thêm 4 mốc cấp 11–14, server không đọc) | 120 | 113 / 0 / 7 (慕容, tên khác ở tlbb15) — cả 29 cột đều từ CY | 56 |
| SkillTemplate_V1 | 82 | 4.586 | 1.527 / 70 / 2.989 | 2.239 |
| SkillData_V1 | 48 → **54** | 20.667 | 11.231 / 888 / 8.548 | 4.910 |
| EquipBase | 101 | 24.531 | 19.378 / 105 / 5.048 | 6.596 |
| XinFaStudySpend_V1 | 244 (GL 260: 129 cặp; CY 121 cặp = xinfa 1–120) | 302 (GL 152) | toàn bộ CY, tên cột GL | — |

### 3.2 Ánh xạ cột (bằng chứng: `plan.json` → `tables.*.agreement_by_gl_col`, `scripts/10-survey-lua4.out.txt`, `22-diag.out.txt`)
- **Registry `dbc_columns_cy.tsv`** làm gốc; kiểm lại trên dòng cùng ID **và cùng tên** (SkillTemplate 1.208, SkillData 11.583, EquipBase 14.262 dòng).
- **SkillData** **[DK]**: CY 1/2 = mô tả tip/giao diện (GL 3/4), CY 3 = 策划专用ID (GL 1, 11.566/11.583), CY 4 = tên (GL 2). Cặp `参数说明/参数值` theo **vị trí** khớp 97–100 % cho 12 cặp (registry ghi 8→10, 9→11 kém hơn). CY có 15 cặp, 57 dòng dùng cặp 13–15 → server nới 6 cột (tên lặp `参数说明/参数值`, `txtreader` gộp thành mảng, `cfghelper.read_skill_data` duyệt `ipairs`).
- **SkillTemplate** **[DK]**: cột GL chưa có trong registry khớp ≥ 0,94 với cột CY trên dòng có giá trị: 1←89 (策划ID), 13←90 (远程), 14←91, 45←95, 46←96, 48←97 (命中率 999/999), 53←98, 74←79 (mô tả), 77←99 (干扰几率 1.156/1.159), 78←100 (1.150/1.153), 81←101. Registry ghi CY 91→77, 95→78 chỉ khớp 4 % → thay. Cột 79 (`未知`), 80 (`七情技能`, hệ 神兵 GL) giữ giá trị GL khi có dòng GL cùng tên, không lấy từ CY. Cấp kỹ năng 1–16 (GL 58–73 ← CY 48–63); CY có 31 cấp, server chỉ 16.
- **EquipBase** **[DK]**: GL k ← CY k−1 với k = 25..34 (khớp 14.254–14.262/14.262), CY 22 và 23 là cột thêm (registry ghi CY 23→GL 25 bị bác); GL 23/24 ← CY 20/21; GL 18/19/20 (镶嵌上限, impact vũ khí, script) ← CY 100/101/102 (phân bố giá trị trùng: 3/0/4, −1/21/…, −1/999801/…); CY 17 = 修理失败上限 (hằng 3). Cột 7 (适应规则) chỉ khớp 27 %: giá trị CY khác thật, lấy CY.
  - Cột 19 impact (`StandardImpact` **đánh số CY** — bẫy 百念朝周→buff thỏ, memory `tlbb-cy4-rasoat`): giữ giá trị GL nếu có dòng GL cùng tên, nếu không đặt **−1** (3.006 dòng) tới khi agent Impact chuyển `StandardImpact`.
  - Cột 20 script: chỉ giữ nếu script có trong `Game_2/Script/scripts/scripts.lua`; 999802 (1.113 dòng, CY) không có → −1.
- **XinFa**: 29 cột đồng nhất (registry 1.0/gap). Tên/mô tả/icon lấy CY (server chỉ đọc `门派ID`).
- **XinFaStudySpend**: server đọc `cost_money[xinfa+1]`; 244 cột CY đủ cho xinfa ≤ 120.

### 3.3 ID kỹ năng/tâm pháp trong Lua (tra theo tên + phái đã ánh xạ; `plan.json` → `skill_resolve_log`)
- 0–8: mọi ID trong `MENPAI_7_SKILLS`, `QINGGONG_SKILL`, `MENPAI_7_XINFA/8_XINFA`, `SETTING_MENPAI_SKILLID` trùng CY cả tên (verify 140/140). Hai ô quick-skill 445 (GL 冰蚕毒掌 → CY 圣蚕护身) và 471 (欲擒故纵 → 关冲剑) vẫn là kỹ năng cùng phái ở CY, giữ ID.
- Viễn công `MENPAI_JINZHAN_YUANGONG_SKILL`: 3266/3269/3267/3268/847 → **4742/4743/4744/4745/4746** (CY cột 90 远程 = 1; ID 281/311/341/491 thuộc dòng GL cùng tên nên bị loại).
- 恶人谷 (15): `MENPAI_7_SKILLS` 808/810/811 → 4643/4644/4645 (đúng 3 kỹ năng tâm pháp 119 无尽诀 ở CY); 轻功 111 → 4648; xinfa7/8 87/88 → 119/120; quick 788/799/803 → 4622/4633/4637.
- 慕容 (10): 轻功 → 110; xinfa7/8 → 70/71; `MENPAI_7_SKILLS` GL 830–832 (星火闪…) ở CY thuộc tâm pháp 69, nên đặt theo tâm pháp 70 星璇剑典 của CY: **784 破天式, 785 凌神式, 781 化气式** **[SL: thứ tự vị trí]**; quick `{760,771,775}`.
- 4 phái nhập (`menpai_extensions.lua`): quick 5619→2900…, 5649→3430…, 5687→3800 (2 ứng viên, chọn theo cột), 5723→4515; 轻功 5648→2942, 5677→3518, 5718→3836, 5755→4547; skills7 = kỹ năng tâm pháp thứ 7 của CY: 唐门 **2921/2922/2923** (GL 傀儡香/孔雀翎 không có ở CY → theo vị trí), 鬼谷 3451/3452/3453, 桃花岛 3821/3822/3823, 绝情谷 4542/4543/4544; xinfa7/8 → 87/88, 95/96, 103/104, 111/112.
- `cy_four_training_config.lua`: `menpaiId`, khoá `factions`, `id` sách (xinfa/skill), `needXinfa`, `qinggong` đều tra sang CY.

### 3.4 Dòng chỉ-GL: dải riêng, tắt
- Dòng GL có ID không có ở CY, hoặc cùng ID nhưng khác tên/khác phái: **không nạp**, lưu nguyên byte ở `R/configs/cys_gl_only/<bảng>.txt` (bố cục GL) kèm `<bảng>.reserved_ids.tsv` = ID gốc → ID dải riêng đề xuất (SkillTemplate/SkillData +50000, XinFa +1000, EquipBase +9.000.000 giữ chữ số lớp = 1).
- Lý do không giữ trong bảng sống **[SL]**: không bảng nào có cờ "tắt" theo dòng; client CanonicalCY không có các dòng này nên server gửi ID đó client cũng không vẽ được; mọi ID kỹ năng đều lọt vào `skill_list` u16 của gói.
- Gồm: 曼陀 (26 skill, 8 xinfa), 神兵/PetSoul/Goku/Iron Man/pet 二郎 (kỹ năng 32703…), 922 vũ khí CY4 nhập 09/09 (ID GL 10116xxx… — CY có vũ khí 4 phái ở ID riêng, đã vào theo CY), thời trang/thú cưỡi/huyễn sức nhập 2026 (ID GL), v.v. Muốn dùng lại phải nhập đồng thời vào client (CanonicalCY) và server ở dải riêng — việc của đợt CS3c sau.

### 3.5 Phụ thuộc còn lại (không thuộc đợt này)
| Bảng/hệ | Tình trạng sau CS3b | Việc |
|---|---|---|
| `StandardImpact`, `ImpactSEData`, `ImpactDirectly`, `Bullet` | vẫn GL; SkillData CY tham chiếu impact ID CY (`|生效一次的附加效果`, 59912…) → kỹ năng CY chưa có hiệu ứng đúng, EquipBase cột 19 đã đặt −1 | agent Impact (CS3c) |
| `MonsterAttrExTable`, `PetAttrTable`, `CommonItem`, `ShopTable`, drop/quest | vẫn GL; `ShopTable`/quest tham chiếu 6.596 item GL đã tắt (shop 402–418 vũ khí CY4…) → mở shop có thể thiếu hàng | agent Monster/Pet/Item |
| `cy_four_combat/*` (37 file), `cy_four_training_config.lua` | số phái đã đổi; `deployment_config.template_factions`, `native_config.donor_skill_templates`, `phase2_config.impacts` vẫn khoá theo **ID skill GL** (5619…, đã tắt) → hook không bắt được kỹ năng CY 2900…; 4 phái chạy bằng dữ liệu CY thuần | chuyển hoặc bỏ lớp bridge GL |
| Script sư môn/hào quang/`aura_rune_projector%d` client | `%d` = số phái CY (0–15) khớp CY sẵn | không |
| `SectInfo/SectDesc` | là 宗门 talent, không phải môn phái | không |
| 曼陀山庄 | tắt (1.1) | quyết định nhập lại hay bỏ |

## 4. Áp, kiểm, hoàn tác

- `cys_server.ps1 backup truoc-cs3b-menpai` → `R/backups/20260914T105202Z-truoc-cs3b-menpai` (4 DB Mongo, 39 file) trước khi ghi.
- `apply` → `R/backups/cs3b-20260914T105216Z/` (bản cũ 47 file), commit `9bff727` (bảng), `af7a3f2` (Lua), `8761c93` (BaseValueTable + Exterior_Ride). Cây sạch.
- Restart chỉ khi `status` 0 client, `Get-Process Game` rỗng, 0 kết nối 15733/15734 (agent cs2-world chạy GUI xen kẽ): `scripts/40-restart-mongo.sh` = stop → mongod riêng → `mongo-apply` (bản sao `char-move-1.json`) → start; 17:53:58 stop, 15733 LISTEN 17:57:22 (`wait-logcheck-1.txt`): 0 traceback, 0 SCENE_LOAD_FAIL/INIT_FAIL, chỉ cảnh báo có sẵn (AIScript id 97, clock, Memory warning).
- Hoàn tác: `git -C R revert 8761c93 af7a3f2 9bff727` rồi restart; hoặc chép lại `R/backups/cs3b-20260914T105216Z/`; nhân vật: `char-move-1.json` (`backup_full_doc`) hoặc `cys_server.sh restore backups/20260914T105202Z-truoc-cs3b-menpai`.

## 5. Bẫy gặp trong pha này
- `Exterior_Ride.txt` server **không phải GBK hợp lệ** (byte 0x81 tại 22853, có sẵn); tool chỉ đổi số ở cột 6, không ép decode.
- `set -o pipefail` + `| head` làm script `.sh` chết vì SIGPIPE **trước** khi stop server (lần 1 của `40-restart-mongo.sh`).
- tlbb15 `SkillTemplate_V1` 96 cột nhưng 81–95 rỗng; `SkillData` 54 cột nhưng 48–53 rỗng → chỉ là bố cục GL kéo dài.
- Tên kỹ năng trùng giữa phái: 慕容 có bản sao 化气式 (788–800) mang tên kỹ năng phái khác; tra tên phải kèm phái.
- Registry `dbc_columns_cy.tsv` căn theo ID chung (không kiểm tên) nên sai ở EquipBase 23–33 và SkillTemplate 77/78; luôn kiểm lại trên dòng cùng tên.
- Bảng CY `XinFa_V1` 37 cột (thêm mốc cấp 11–14): client CS1 đọc, server không.
