# menpai-audit — kỹ năng môn phái, tâm pháp, bí tịch 15 phái trên server riêng (15/09/2026)

Câu hỏi người dùng (15/09): "Kỹ năng môn phái, tâm pháp, bí tịch các phái ổn chưa". Agent `menpai-audit`, nhánh `menpai-audit`.
Bằng chứng: `Build/Logs/2026-09-15-menpai-audit/` (không vào git). Script đo: `Tools/server/menpai_audit/` (bản chép từ `scripts/` của thư mục bằng chứng).
Tiếp nối `cs3b-menpai_vi.md`, `cs3c-tables_vi.md`, `server-impact_vi.md`, `../net/skills-ui_vi.md`.

Quy ước: **[DK]** dữ kiện đo được (có đường dẫn). **[SL]** suy luận. `R` = `/home/ubuntu/cys-test-20260913` (server riêng; git `926e506` lúc bắt đầu, `01ac39d` sau lần restart 12:27 của agent skills-ui — chỉ thêm quyền GM test00, không đổi kỹ năng).
Server không bị sửa, không restart bởi agent này. Chỉ bản ghi Mongo nhân vật test CYTest00 (GUID 200001) bị đổi tạm, đã sao lưu và trả về nguyên trạng.

## 0. Trả lời ngắn

**Chưa ổn.** 9 phái cũ (0–8) phần lớn kỹ năng chủ động chạy; 6 phái CY (慕容, 唐门, 鬼谷, 桃花岛, 绝情谷, 恶人谷) chỉ khoảng một nửa chạy. Ba lỗi server có traceback làm hỏng hàng loạt, và hai lỗi đầu sửa rất nhỏ:

1. `skill_cy_generic` (lượt server-impact) **sập mọi lần dùng**: `skill_0.lua:72 bad 'for' limit (nil)` vì lớp con không có trường `IMPACT_NUMBER` → mọi kỹ năng có 技能逻辑ID chưa cài (137 template cấp 1–4 thuộc 15 phái) **trừ MP, đặt hồi chiêu nhưng không có tác dụng**. [DK live 26 phiên]
2. `cy_four_combat/storage.lua:27` còn **số phái GL 15/16** → `assert 'resource/faction mismatch'` ở **mỗi nhịp tim** của nhân vật 桃花岛 (13) và 绝情谷 (14); nộ không hồi, tài nguyên 共情/刀意 không lưu. [DK live 28 phiên]
3. `condition_delplete_core.lua:708 assert(logic, type)`: SkillData CY dùng **logic điều kiện 17/18/20/21** chưa đăng ký (刀意需求, 自身不可携带的buff集合, 图腾数量, 需要天机点) → sập trước khi dùng chiêu (23 template). [DK live 9 phiên + tĩnh]

Tâm pháp học/nâng được ở cả 15 phái (live 13 phái), chi phí server = bảng CY (trùng từng ô). Bí tịch: chỉ **tu luyện (phái 0–12), võ hồn, sách trân thú** có handler server; **client mới chưa có cửa sổ nào chạy**, bí tịch chiêu thức/kinh mạch/lệnh bài/tinh trận thiếu cả server.

## 1. Kiểm live theo phái

### 1.1 Cách đo **[DK]**
- Nhân vật: CYTest00 (cấp 15, vốn vô môn phái 9). Trước lượt: `cys_server.ps1 backup truoc-menpai-audit` → `R/backups/20260915T040040Z-truoc-menpai-audit` (`backup-1.txt`); bản ghi gốc `char-original.json`.
- Đổi phái: sửa Mongo bản ghi test (`char_menpai.py set`) đúng như `script_base:LuaFnJoinMenpai` + học 6 tâm pháp thường: `attrib.menpai`, `reputation`, `xinfa_list` = 6 tâm pháp đầu của phái (bỏ 第七/第八心法) ở **cấp 30** (cấp kỹ năng = ⌈30/10⌉+1 = 4), `skill_list` = 9 kỹ năng chung + template `是否直接学会` + template `class_by_user 0` của 6 tâm pháp + 远功 (`MENPAI_JINZHAN_YUANGONG_SKILL`). Server nạp bản ghi từ Mongo mỗi lần đăng nhập (`msgagent.lua:192 load_my_data`), không có cache sau khi thoát sạch (`03-survey-msgagent.out.txt`, `04-survey-gamed.out.txt`).
  Đường GM (`--exec 900066,ConsoleRoleUse,7,…`) có từ 12:27 nhưng không dùng để giữ một cách đo cho mọi phái.
- Mỗi phiên: đặt lại phái/tâm pháp + HP/MP gốc + vị trí Vô Lượng Sơn (cảnh 6; 40,150) → `CysNetBot --mode world --xinfa 1 --record 1 --cast S,0 --hunt 45,152` (bot main, sha256 `EB62…3F03`) → đếm gói từ `report.tsv`, giải fixture `world_core_g1.bin` (`decode_fixture.py`: 331 GCCharSkill_Send, 1692 GCDetailHealsAndDamages, 676 GCCharDirectImpact, 153 GCCharBuff, 7 GCOperateResult) → log Game2 của đúng phiên (`logmark.sh`/`logcheck.sh`, theo offset byte) → `live-results.tsv`; gộp bằng `30-aggregate.py` → `aggregate.json`.
- Phân loại một kỹ năng:
  - **chạy**: server nhận chiêu (GCCharSkill_Send của mình cho đúng skill, hoặc GCCooldownUpdate) **và** có sát thương / hồi máu / buff mới (trừ buff 334 có sẵn khi vào cảnh) / GCCharDirectImpact của đúng skill;
  - **không tác dụng**: server nhận chiêu nhưng không có gì ở trên;
  - **lỗi server**: log phiên có traceback do kỹ năng (`skill_0.lua:72`, `condition_delplete_core.lua:708`, `attempt to…`); lỗi nhịp tim `storage.lua:27` tách riêng, không tính là lỗi kỹ năng;
  - **bị từ chối**: GCOperateResult khác −4/−6/−17 và ngoài nhóm dưới (vd −42, −44);
  - **không kiểm được**: chỉ bị −16/−8 (kỹ năng đơn mục tiêu cho đồng minh — bot chỉ nhắm quái), −9 (tầm), −25/−26 (nộ/liên kích), −5 (MP).
- Phạm vi: kỹ năng **chủ động** trong danh sách học được, 技能的心法等级限制 ≤ 30. 11 phái đo đủ (0, 1, 2, 4, 5, 10–15); 大理/逍遥/武当/天山 đo mẫu vì dùng chung tài khoản test00 (khoá `Build/test00.lock`, nghỉ 60–90 s giữa phiên theo điều phối). Mẫu 大理/逍遥/天山 **cố ý chọn kỹ năng tĩnh "không/một phần/không ô impact/logic chưa cài"** nên tỉ lệ "chạy" của ba phái này thấp hơn thực tế; 武当 chọn ngẫu nhiên.
- Tổng: 180 phiên kỹ năng + 13 phiên học tâm pháp, 11:03 → 17:26 (có hai lần tạm dừng nhường tài khoản cho người dùng/npc-quest).

### 1.2 Kết quả

| Phái | chủ động (≤30 / tổng) | kiểm live | chạy | gửi chiêu không tác dụng | bị từ chối | không kiểm được (mục tiêu) | lỗi server | tĩnh lv4 ok/một phần/không/không ô impact |
|---|---|---|---|---|---|---|---|---|
| 0 少林 (Thiếu Lâm) | 16 / 22 | 16 | 14 | 1 | 0 | 1 | 0 | 14/1/0/1 |
| 1 明教 (Minh Giáo) | 14 / 20 | 14 | 11 | 0 | 0 | 3 | 0 | 14/0/0/0 |
| 2 丐帮 (Cái Bang) | 14 / 20 | 14 | 11 | 1 | 0 | 2 | 0 | 13/1/0/0 |
| 3 武当 (Võ Đang) | 13 / 19 | 3 | 3 | 0 | 0 | 0 | 0 | 13/0/0/0 |
| 4 峨嵋 (Nga My) | 18 / 26 | 18 | 9 | 0 | 2 | 5 | 2 | 11/2/2/3 |
| 5 星宿 (Tinh Túc) | 13 / 20 | 13 | 8 | 1 | 0 | 1 | 3 | 11/0/2/0 |
| 6 大理 (Đại Lý (Thiên Long)) | 19 / 25 | 9 | 1 | 0 | 0 | 0 | 8 | 12/2/2/3 |
| 7 天山 (Thiên Sơn) | 16 / 27 | 3 | 1 | 1 | 0 | 0 | 1 | 15/0/0/1 |
| 8 逍遥 (Tiêu Dao) | 13 / 19 | 6 | 4 | 2 | 0 | 0 | 0 | 8/2/1/2 |
| 10 慕容 (Mộ Dung) | 14 / 20 | 14 | 10 | 4 | 0 | 0 | 0 | 11/0/3/0 |
| 11 唐门 (Đường Môn) | 15 / 23 | 15 | 7 | 5 | 0 | 2 | 1 | 11/0/4/0 |
| 12 鬼谷 (Quỷ Cốc) | 14 / 21 | 14 | 6 | 4 | 0 | 0 | 4 | 5/1/5/3 |
| 13 桃花岛 (Đào Hoa Đảo) | 13 / 19 | 13 | 3 | 0 | 3 | 1 | 6 | 5/2/5/1 |
| 14 绝情谷 (Tuyệt Tình Cốc) | 15 / 23 | 15 | 5 | 1 | 0 | 2 | 7 | 9/1/5/0 |
| 15 恶人谷 (Ác Nhân Cốc) | 13 / 19 | 13 | 6 | 3 | 0 | 1 | 3 | 6/2/5/0 |
| **Tổng** | 220 / 323 | 180 | 99 | 23 | 5 | 18 | 35 | |

Cột "tĩnh lv4": phân loại cấp kỹ năng 4 của `server-impact` (`plan.json faction_lowlevel`); `ok*` = template không có trong danh sách (ok từ trước).

### 1.3 Nguyên nhân (xếp theo số kỹ năng bị ảnh hưởng)

| # | Nguyên nhân | Bằng chứng | Phạm vi |
|---|---|---|---|
| A | **`skill_cy_generic` thiếu `IMPACT_NUMBER`** → `for i = 1, self.IMPACT_NUMBER` nil. `lualib/class.lua` (`luaclass`, dòng 54–59) chỉ chép **hàm** của lớp cha, `skill_0.IMPACT_NUMBER = 17` là trường số nên lớp con `skill_cy_generic` nhận nil. Test `server_impact_tests.lua` giả lập `skill_0` nên không bắt được. Chiêu đã qua kiểm điều kiện: **MP bị trừ, hồi chiêu được đặt, rồi sập** (vd 大理 824: 9 lần nhận chiêu, 18 traceback, hết MP −5×31). | `live/m*/s*-serverlog.txt` (`skill_0.lua:72` ← `skill_cy_generic.lua:79` ← `base.lua:368`), `scripts/18-survey-generic.out.txt` | 137 template cấp 1–4 của 15 phái có logic chưa cài: 少林 2, 明教 2, 丐帮 2, 武当 2, 峨嵋 17, 星宿 19, 大理 16, 天山 7, 逍遥 3, 慕容 6, 唐门 7, 鬼谷 15, 桃花岛 18, 绝情谷 9, 恶人谷 12 (tĩnh, `plan.json skill_logic_installed=false`); 91 logic ID |
| B | **Impact thiếu dòng** (buff tự thân của phái CY): chiêu được nhận, có hồi chiêu, không buff nào | vd 慕容 767/772/779, 唐门 2907/2912/2916, 鬼谷 3442/3446/3449, 恶人谷 4634/4638 — tĩnh `missing:<id>` | 716 ô impact cấp 1–4 (server-impact 1.5) |
| C | **Logic điều kiện/tiêu hao chưa đăng ký** (`define.ConditionAndDepleteID` chỉ có −1, 0–14, 16): 17 刀意需求, 18 自身不可携带的buff集合, 20 图腾数量, 21 需要天机点 → `assert(logic, type)` | `scripts/21-condition-logics.out.txt`; live 鬼谷 3441/3448/3457, 绝情谷 4533/4534/4538, 恶人谷 4629, 峨嵋 411, 天山 498 | 峨嵋 4, 天山 1, 唐门 5, 鬼谷 4, 绝情谷 6, 恶人谷 3 template |
| D | **`cy_four_combat` còn số phái GL**: `storage.lua:27` chỉ nhận 328 khi phái 15 và 331/332 khi phái 16 (GL 桃花岛/绝情谷); sau CS3b số CY là 13/14. `menpai.lua:74 on_heart_beat` gọi `hooks.on_rage_regeneration` **trước** `rage_increment(2)` nên assert chặn luôn hồi nộ | `live/m13`, `live/m14` mọi phiên; `scripts/17-survey-errors.out.txt` | mọi nhân vật 桃花岛/绝情谷, mỗi nhịp tim |
| E | [SL] Logic điều kiện **16** của 桃花岛 = 消耗能量 (CY) nhưng server hiểu là `C_UNIT_MUST_NOT_HAVE_IMPACT`; `cy_four_combat.resources.dispatch` chỉ bắt kiểu 8016–8018 | `21-condition-logics.out.txt`, `17-survey-errors.out.txt` | 10 template 桃花岛 |
| F | Buff rỗng (58 logic impact → `null_logic_buff`): hiện icon, không chỉ số — bot thấy "chạy" (có GCCharBuff) nhưng không có tác dụng thật [SL] | server-impact mục 2 | 704 dòng SI |
| G | −44 `OR_U_CANNT_DO_THIS_RIGHT_NOW` ×40: 峨嵋 832/833 (九阴), 桃花岛 3818 — cần trạng thái riêng, logic chưa cài [SL] | `live-results.tsv` | 3 |

Không phải lỗi server (giới hạn đo): kỹ năng hỗ trợ đơn mục tiêu cho đồng minh (−16, khoảng 1/phái), cần nộ/liên kích/tầm gần. Quái Vô Lượng Sơn chỉ còn **18 HP** → mọi đòn đơn đều ghi 18 (千里横行 90 = 5 mục tiêu): con số sát thương **không so được với CY**, chỉ chứng minh có sát thương.

## 2. Tâm pháp

| Việc | Kết quả |
|---|---|
| Học/nâng live | **[DK]** 13 phái (0, 1, 2, 4, 5, 6, 10–15): `CGAskStudyXinfa` tâm pháp đầu cấp 1 → `GCStudyXinfa` cấp 2, giao tử −10 mỗi lần (vd 28 879 185 → 28 879 175), đúng ô `学习等级 2` cặp theo ID tâm pháp (10 tiền / 27 kinh nghiệm). `live/m*/study-*` |
| Kỹ năng theo tâm pháp | **[DK]** `GCDetailXinFaList` đúng 6 tâm pháp/phái, `GCDetailSkillList` có đủ template; cấp kỹ năng theo ⌈cấp tâm pháp/10⌉+1 (`human.lua:2203`) |
| Bảng chi phí | **[DK]** `XinFaStudySpend_V1` server = CY từng ô (244 cột × 302 dòng, 0 khác, `bitich/xinfa_spend_cmp.txt`); dòng 888 = chỉ mục cặp, 999 = cờ cột; server tra `[now_level+1].cost_*[xinfa+1]` đúng cặp cho ID 1–120 |
| Kiểm sẵn sàng phái | **[DK một phần]** mô phỏng `menpai_registry.check_ready` (8 tâm pháp, thứ tự 7/8, cột chi phí, SkillData 12 cấp, 七绝/轻功/thanh nhanh 4 phái CY): 15/15 đạt (`scripts/14-ready-check.out.txt`). Chưa kiểm live `LuaFnJoinMenpai` ở NPC (cảnh phái đang tắt). |
| Lệch CY | [DK] server không kiểm "không cao hơn cấp nhân vật + 5" khi học (`scenecore.lua:2568 char_study_xinfa`; mô tả XinFa_V1 có quy tắc này); `now_level = 300` → `config[301]` nil → lỗi Lua. `XinFa_V1` server 29 cột, CY 37 (thiếu 心法等级段 11–14) |
| Client | [DK] `GetUplevelXinfaSpendMoney/Exp` tra `DBC_XINFA_STUDYSPEND (907)` nhưng 907 **không được nạp** (`GMDataBase.cpp:137-210`), `GetDataBase` không kiểm `end()` → [SL] truy cập rác khi mở trang tâm pháp; struct 0.85 `StudySpend[54]` và lệch cột (ID ≥ 54 ra ngoài mảng) |

## 3. Bí tịch / tu luyện

Khảo sát chỉ đọc (`bitich/`: `tbl_cmp.txt`, `srv1–9.txt`, `cy_lua_api.txt`). Bảng CY là DBC nhị phân, đọc bằng `Tools/game/dbc_inventory.py`.

| Loại CY | Dữ liệu CY | Server riêng | Client mới | Phân loại |
|---|---|---|---|---|
| 修炼 Tu luyện (五行宝典 / 无涯遗书 / 昊天真经; `Xiulian.lua`, `XiulianStudy.lua`) | `XiuLianBook` 3, `XiuLianMiJi` 15 cuốn, `XiuLianDetail` 2 416 dòng × 63 cột (phái 0–15) | script 2099 `odali_wuyazi` `AskXiuLianLevelUp/AskXiuLianAdvanceJingJie` + gói 1014 (11 cuốn); `XiuLianDetail` 1 963 × 47 (**chỉ phái 0–12**, 11 cuốn) → phái 13–15 "Tra bảng bất thường" | `GetXiuLianBookInfo/GetXiuLianMiJiInfo` là hàm giả, gói 1014 không handler | **chạy (server, phái 0–12)** / thiếu client / thiếu dữ liệu (13–15, cuốn 11–14) |
| 秘籍 Bí tịch chiêu thức (`SelfMiji.lua`, `ComboSkillBook` 34 sách, 3 chiêu mỗi sách) | `ComboSkillRate` 99, `RefixComboSkill` 66 | template 2500–2547 có; script dùng sách 890100/890099/888435 **không tồn tại**; không gói `GCDetailComboSkillList`/`CGAskComboSkillOperation` (724 là chuỗi chiêu 671, không phải bí tịch) | hàm giả | thiếu server / thiếu client / thiếu dữ liệu (impact 34000+) |
| 经脉·秘法 Kinh mạch (`JingMai.lua`, `XueWeiBook` 21) | cuốn 11–14 của XiuLianMiJi | không gói; có script tự viết `YYC/jingmai.lua` (900099, khoá thẻ tháng) không dùng bảng CY | hàm giả | thiếu server (kiểu CY) / thiếu client |
| 令牌要诀 Yếu quyết lệnh bài (`RLSkillBook` 23) | item 38000965–988 | script 880003 không tồn tại | — | thiếu server / thiếu client |
| 武魂扩展属性书 (`KFSAttrExBook` 16) | trùng server | `wuhun.lua:162 KfsAttrExStudy`, 908 `CGKfsOperate`; `KFSSkillLevelup` CY 294 / server 276, `KFSCompoudEx` 10/9 | hàm giả | **chạy (server)** / thiếu client / lệch dữ liệu nhẹ |
| 星阵 Tinh trận (`XingZhen_SkillBook` 276) | 46 chiêu × cấp 0–5 | chỉ có template 4200–4383; không bảng/script/gói | — | thiếu server / thiếu client / thiếu dữ liệu |
| 宠物技能书 Sách trân thú (`PetSkillBook` 125) | trùng server | script 336096 có | luồng 0.85 | **chạy** |
| 秘传/宗门 (`TalentInfo`, `ZongmenTalent`) | gói `GCTalent*` | server dùng hệ `SectInfo` khác | — | chưa đối chiếu (audit riêng) |

Chưa thử bí tịch bằng bot: bot main có `--exec` từ 12:11 nhưng lượt đo kỹ năng dùng hết khe tài khoản test00. Đường thử đã xác định: `--exec 2099,AskXiuLianLevelUp,<npc>,<mjIdx>` với nhân vật phái 0–12 (kỳ vọng gói 1014 cấp +1; phái 13–15 báo lỗi bảng).

## 4. Việc sửa, xếp theo ảnh hưởng

| # | Việc | Ảnh hưởng | Công |
|---|---|---|---|
| 1 | `skill_cy_generic.lua`: thêm `skill_cy_generic.IMPACT_NUMBER = skill_0.IMPACT_NUMBER` (và mọi trường không phải hàm `skill_0` dùng qua `self`, vd `SkillInfoDescriptorIndex`); sửa test để dùng `class.lua` thật | 137 template 15 phái hết sập (tác dụng vẫn phụ thuộc #4) | 1 giờ + restart + chạy lại `20-live.ps1` cho các template này |
| 2 | `cy_four_combat/storage.lua:27`: 328 ↔ phái 13, 331/332 ↔ phái 14 (hoặc qua `donor_faction`/`reverse_faction`); rà các hằng 15/16 còn lại trong `cy_four_combat` | hết traceback mỗi nhịp tim, hồi nộ + 共情/刀意 của 桃花岛/绝情谷 | 1–2 giờ |
| 3 | Đăng ký logic điều kiện CY 17/18/20/21 trong `condition_delplete_core` (hoặc định tuyến sang `cy_four_combat.resources` với kiểu 8016+), xác định nghĩa 16 của 桃花岛; không để `assert` làm sập chiêu | 23 template (+10 桃花岛) | 1 ngày |
| 4 | Impact thiếu cho buff tự thân phái CY (716 ô) và 58 logic buff rỗng: cần StandardImpact CY thật hoặc dựng tay theo tip | phần lớn "không tác dụng" còn lại của 6 phái CY | 3–5 ngày |
| 5 | Cài nghĩa cho 91 logic kỹ năng CY đang rơi về generic (ưu tiên 第八心法 643/644, 833, 761–770 鬼谷, 791–803 桃花岛, 835–842 绝情谷, 864–870 恶人谷) | đúng hành vi CY (không chỉ có impact) | 1–3 tuần |
| 6 | Client: nạp DBC 907 theo bố cục CY, sửa `Lua_GetUplevelXinfaSpend*`, chặn `GetDataBase` khi thiếu bảng | tránh sập cửa sổ tâm pháp | 3–4 giờ |
| 7 | Server tâm pháp: chặn `now_level ≥ 300`, kiểm cấp nhân vật + 5 như CY, bổ sung cột 心法等级段 11–14 | đúng luật CY | 2–3 giờ |
| 8 | Tu luyện: `XiuLianDetail` theo CY (15 cuốn, phái 13–15), gói 1014 11 → 15 cuốn (xác nhận bố cục trong Game.exe CY), client handler + host | tu luyện 15 phái | 2–3 ngày |
| 9 | Bí tịch chiêu thức (script sách, gói danh sách/thao tác, impact 34000+, host client) | tính năng CY chưa có | 4–7 ngày |
| 10 | Kinh mạch, lệnh bài, tinh trận, võ hồn client | tính năng CY chưa có | 1–3 tuần |
| 11 | Bot/kiểm: `--cast` lên chính mình/đồng minh, bãi quái máu cao để so số sát thương, hồi nộ/liên kích trước khi thử | kiểm được ~20 kỹ năng còn "không kiểm được" | 0,5 ngày (agent skills-ui) |

## 5. Bẫy gặp khi đo

- **Phiên bot bị giết giữa chừng** (TaskStop) → msgagent còn lại lưu dữ liệu cũ **sau** khi đã sửa Mongo → sửa bị ghi đè (3559 lần 2 thấy phái 1). Chỉ sửa Mongo sau khi thoát sạch; runner đặt lại trạng thái trước mỗi phiên.
- MP không hồi giữa các phiên (lưu qua đăng xuất): một chiêu dẫn/lặp (少林 304: 107 GCCharSkill_Send) rút MP → các phiên sau −5 ×40. Runner đặt lại HP/MP.
- Đăng nhập lại ngay sau phiên trước → `game socket closed` / `login refused`: chờ 10 s, khoá `Build/test00.lock`, nghỉ 60 s.
- `report.tsv` đếm GCCharSkill_Send của **mọi** đối tượng; phải lọc theo `m_objID` của mình (fixture).
- Kỹ năng không gửi GCCharSkill_Send (vd 峨嵋 404) vẫn được nhận: xem GCCooldownUpdate.

## 6. Trạng thái cuối

CYTest00 trả về phái 9, `xinfa_list` rỗng, `skill_list` 9 kỹ năng gốc, HP/MP gốc, Đại Lý (2; 160,150) (`char/restore-*.json`, `char/move-*.json`). Kinh nghiệm tăng do giết quái (1 638 → 23 388) và giao tử −10 mỗi lần học không hoàn lại. Hoàn tác toàn bộ Mongo nếu cần: `cys_server.ps1 restore R/backups/20260915T040040Z-truoc-menpai-audit` (cần dừng skynet).
