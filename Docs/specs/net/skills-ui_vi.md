# Kỹ năng trên giao diện CY: danh sách kỹ năng, tâm pháp, thanh nhanh, mục tiêu, hồi chiêu — 15/09/2026

Tiếp nối [core-loop_vi.md](core-loop_vi.md) (CGCharUseSkill, GCCharSkill_*, sát thương, chết) và [inventory-equip_vi.md](inventory-equip_vi.md). Phần này đặc tả và triển khai **kỹ năng trên giao diện như CY**: cửa sổ kỹ năng/tâm pháp CY liệt kê kỹ năng của nhân vật (tên tiếng Việt), kéo kỹ năng vào thanh nhanh F1–F10 (lưu server), Tab chọn địch gần nhất (khung mục tiêu CY), bấm phím dùng kỹ năng lên mục tiêu (hiệu ứng, số sát thương, hồi chiêu), học/nâng tâm pháp. Server riêng `/home/ubuntu/cys-test-20260913` (login 15733 / game 15734) chỉ đọc. Mọi sửa trong mã gắn `// CYS-SKILL`.

Ký hiệu: **[DK]** dữ kiện đọc từ mã server / bảng / mã client; **[SL]** suy luận chưa kiểm; **[LIVE]** đã thấy trên server riêng (bot hoặc Game.exe).

## 1. Tóm tắt wire

| Hành động | Client → server | Server → client | Handler server (chỉ đọc) | Trạng thái |
| --- | --- | --- | --- | --- |
| Danh sách kỹ năng | 1252 `CGAskDetailSkillList` {m_objID} | 55 `GCDetailSkillList` {m_objID, n u16, **ID SkillTemplate** u32[]} | `scenecore.lua ask_detail_skill_list` → `human:get_total_skills_list` (skill_list + thần binh + võ hồn + trang bị) | [LIVE] CYTest00: 0,1,2,3,21,22,34,35,43 |
| Danh sách tâm pháp | 134 `CGAskDetailXinFaList` {m_objID} | 607 `GCDetailXinFaList` {m_objID, n u16 (<16), {id u32, level u32}[], unknow u32 = 26} + xiulian/talent/combo | `scenecore.lua ask_detail_xinfa_list` | [LIVE] CYTest00 rỗng (vô môn phái 9) |
| Mở cửa sổ học tâm pháp | (thoại NPC thầy phái) | 15 `GCXinfaStudyInfo` {menpai u16, teacher u32} | `script_base:DispatchXinfaLevelInfo` (cy4_npc role `xinfa_teacher`, 0.85 `owudang_yuyuanshan`…) | port, không có NPC ở 4 bản đồ |
| Học/nâng tâm pháp | 555 `CGAskStudyXinfa` {menpai u16, xinfa u16, now_level u16} | 137 `GCStudyXinfa` {spare_money u32, spare_exp u32, xinfa u16, now_level u16}; kỹ năng mới → 55 | `msgagent.lua:1379` (xinfa phải có trong danh sách, `now_level` = cấp đang có) → `scenecore:char_study_xinfa` (bảng `xinfa_study_speed_v1`: exp + tiền ưu tiên giao tử) → `human:study_xinfa` → `on_study_xinfa` thêm template `class_by_user 0` cùng xinfa | dịch + port, chưa live (không có tâm pháp) |
| Hỏi thiết lập | 402 `CGAskSetting` (rỗng) | 357 `GCRetSetting` {u8 = 1, 109 × {type u8, data u32}} | `human:send_setting` (khoá "1".."96" → mục 0..95) | [LIVE] |
| Đặt ô thanh nhanh | 409 `CGModifySetting` {type u8 = SETTING_TYPE, setting.type u8, setting.data u32} | không trả lời | `scenecore:char_modify_setting` (bỏ qua 3 s đầu trong cảnh; khoá `tostring(type + 1)`; `cy_four_combat.quickbar_projection` chỉ đổi kỹ năng 绝 của phái 14; `menpai_quick_setting_guard` khi vừa vào phái) | [LIVE] |
| Dùng kỹ năng | 83 `CGCharUseSkill` {…, skillID = **ID template**, targetObjID, posTarget} | 331/909/1692/455/802/676 (core-loop); 85 `GCCooldownUpdate`; 7 `GCOperateResult` khi từ chối | `scenecore:char_use_skill` → `skill/base.lua` | [LIVE] |
| Hồi chiêu | — | 85 `GCCooldownUpdate` {high u32, low u32 (pet guid), n u16, {id i32 = **nhóm hồi chiêu** (SkillTemplate cột 13), cooldown u32 ms, elapsed u32}} | `human:set_cool_down` (chỉ id < 10000), `base.lua:1120` (kỹ năng tự động lặp — đánh thường — dùng `set_auto_repeat_cool_down`, **không gửi gói**) | [LIVE] |
| Thêm kỹ năng lẻ | — | 78 `GCAddSkill` {skill u32, unknow u16} | GM tool `GmTool_Self.lua:942` | port |

Mã kết quả `GCOperateResult` gặp khi dùng kỹ năng (`define.lua OPERATE_RESULT`): −4 mục tiêu đã chết, −6 đang hồi chiêu, −8 mục tiêu không hợp lệ, −16 cảnh báo (NPC phe 8), **−42 cần học kỹ năng trước** (server CÓ kiểm kỹ năng đã học với kỹ năng phái: bot `--cast 775,0` → −42) **[LIVE]**.

### 2.1 ID kỹ năng, cấp

- Server CY dùng **ID SkillTemplate** ở mọi nơi (danh sách, thanh nhanh, CGCharUseSkill, GCCharSkill_Send). 0.85 dùng **SkillData id = template × 100 + cấp** trong `CActionSystem` (`MainMenuBar_Set`, `CAI_MySelf::SendUseSkillMessage`) và khoá bản đồ kỹ năng `CCharacterData::Set_Skill` **[DK]**. Bản port core-loop cũ hiểu 55 là SkillData id (`Set_Skill(id/100, id%100)`) → skill 35 thành template 0 cấp 35: sai với dữ liệu thật (fixture replay chỉ có {0}).
- Cấp theo server (`human.lua get_skill_level`): template có `xinfa` đã học → `ceil(cấp tâm pháp / 10) + 1`; không có → `character.get_skill_level` (1). Client mới dùng đúng công thức (chặn 31 cột `m_anSkillByLevel`) **[DK]**.
- `Set_Skill` 0.85 bỏ kỹ năng có `m_nSkillClass` khác −1 nếu `m_nMenPai` ≠ môn phái của mình → kỹ năng phái chỉ hiện khi môn phái (GCDetailAttrib `flags[7]&64`) đã đúng **[DK]**.

### 2.2 Thanh nhanh

- `GCRetSetting` mục *i* = SETTING_TYPE *i* (server gửi `setting[tostring(i)]` với khoá = type + 1). `define.SETTING_TYPE`: 1 GAME, **2..11 = K0..K9 (F1..F10)**, 12..21 = K10..K19 (trang 2 của thanh CY, `DragAcceptName M1x`), 21..28 thẻ chat, 94 ẩn danh hiệu **[DK]**. Trùng khớp enum `SETTING_TYPE_K0..K19` của 0.85 (`GameDefine2.h`).
- `setting.type` = `ACTION_OPTYPE` 0.85: 0 rỗng, **1 kỹ năng (data = ID template)**, 3 vật phẩm (data = ID bảng), 5 kỹ năng thú (data = (pet << 16) + skill) **[DK]**. CYTest00 lúc đầu: F1 = 1/0 (đánh thường), F8 = 1/35 (打坐), F9 = 1/22 (返回大理城), F10 = 1/21 (召唤坐骑) **[LIVE]**.
- **Lưu ở server** (Mongo `setting` của nhân vật), không lưu client. Server không trả lời 409; muốn thấy giá trị phải gửi lại 402 **[LIVE]** (bot-live-2: đặt F2 = 1/0 → hỏi lại thấy F2 → trả về 0/0 → hỏi lại đúng như trước).
- Layout CY `MainMenuBar.layout.xml`: `Button_Action1..10` (`DragAcceptName M00..M09`), trang 2/3 `M10..`/`M20..` và ô biến thân `w50..` **[DK]**. 0.85 `CActionItem::NotifyDragDropDragged` đọc `M<trang><ô>` = chỉ số trang × 10 + ô; `MainMenuBar_Set` chỉ nhận 0..20 → trang 3 (M2x ≥ 21) chưa dùng được **[DK]**.

### 2.3 Mục tiêu

- Click trái vào quái / Tab → `CObjectManager::SetMainTarget` → 372 `CGLockTarget` (core-loop) → khung `TargetFrame` CY (`Target:GetData`, cy-gui-2). CY gán **Tab = chọn địch gần nhất**; 0.85 gán Tab = bản đồ cảnh. Client mới: Tab (khi ô chat trống) → `Debug_LockNearestTarget` (địch trong 20 m theo `GetCampType == RELATION_ENEMY`), bản đồ vẫn ở phím M **[DK]**.
- Phe (`CampAndStand`): người chơi phe 0 đánh được phe 9/10; NPC phe 8 trả −16. Vô Lượng Sơn (cảnh 6/73/74) có quái phe 9 quanh (40,150) **[LIVE]**.

### 2.4 Hồi chiêu

- Nhóm hồi chiêu = `SkillTemplate` cột 13 `m_nCooldownID` (đánh thường 50, 打坐 100, 返回大理城 51, 召唤坐骑 50, 新手轻功 49). `GCCooldownUpdate` → `CDataPool::CoolDownGroup_UpdateList` (0.85, nhóm 0..254) → `CActionSystem::UpdateCoolDown` → lớp phủ hồi chiêu trên nút thanh nhanh **[DK]**.
- Đánh thường: server không gửi 85 (kỹ năng lặp tự động); hồi chiêu chung phía client do `CActionSystem::UpdateCommonCoolDown` khi gửi 83 **[DK]**.

## 3. Lua CY và host

Mã Lua CY: `Assets/CanonicalCY/Data/InterfaceFolder/{ActionSkill,CommonSkill,ActionSkillsStudy,MainMenuBar,TargetFrame}`.

| Cửa sổ | Mở bằng | Dữ liệu dùng | Host |
| --- | --- | --- | --- |
| `ActionSkill` (kỹ năng phái: 8 ô tâm pháp `ActionSkill_Xinfa1..8`, 5 ô chiêu `ActionSkill_Zhaoshi1..5`) | `TOGLE_SKILL_BOOK` (nút kỹ năng thanh menu CY) | `EnumAction(i,"xinfa")`, `EnumAction(i,"skill")` + `GetOwnerXinfa`, `Player:GetXinfaInfo(id,"name/level/explain")`, `Player:GetSkillInfo`, `GetXinfaLevel`, `GetUplevelXinfaSpendMoney/Exp` (bảng `XinFaStudySpend_V1`), `Player:GetDefineHumanMaxLevel`, `IsLMSJSecond/IsJYJYSecond/IsWJQFSecond` | **`CysHost_Skill`**: `Player:GetXinfaInfo` (0.85 để trống nhánh "level" → nối chuỗi nil lỗi), `GetXinfaLevel` (0.85 đã chú thích), `GetDefineHumanMaxLevel` 119, 3 hàm lọc = 0 khi vắng. |
| `CommonSkill` (kỹ năng chung, trang 0: ô 1–4 hành động thú, từ ô 5 kỹ năng có `GetOwnerXinfa() == -9999`) | `TOGLE_COMMONSKILL_PAGE` (thẻ "Kỹ năng thường") | như trên + `Pet:GetPetFightAction…` | có sẵn 0.85 |
| `ActionSkillsStudy` (học tâm pháp ở thầy) | `TOGLE_SKILLSTUDY` (từ 15 `GCXinfaStudyInfo`) | `GetUplevelXinfaSpend*`, `DataPool` gửi `CGAskStudyXinfa` qua `SendStudySkillEvent` | có sẵn 0.85 (dịch 555 điền `menpai` của mình + `now_level` từ danh sách) |
| `MainMenuBar` (thanh nhanh F1–F10) | luôn hiện | `ActionButton` + `MainMenuBar_DoAction` từ F1..F10 (`CGamePro_Main` KC_F1..F10) | có sẵn 0.85 |
| `TargetFrame` | `MAINTARGET_CHANGED` | `Target:GetData` | cy-gui-2 |

Tên kỹ năng/tâm pháp: bảng CY là GBK → Game.exe x64 đưa UTF-8 cho CEGUI → ô vuông. `Tools/pipeline/cy_skill_text.py stage --stage <stage>` ghi `SkillTemplate_V1` (tên cột 2, mô tả 79), `XinFa_V1` (2, 3), `SkillData_V1` (mô tả 1, 2; tên 4) vào `Overlay/Post/ConfigFolder` của stage: GBK → UTF-8 + tiếng Việt (sửa tay → TM → từ điển dự án → Hán-Việt cho tên → giữ chữ Trung UTF-8), mọi ô số và ô chuỗi khoá (icon, hiệu ứng, locator, action set) giữ nguyên byte (kiểm từng ô). Kết quả 15/09: tên SkillTemplate TM 5.597 / Hán-Việt 1.268; còn chữ Trung ở mô tả dài (báo cáo `skill_text_report.tsv`).

## 4. Triển khai

- **NetCore** `WorldModel`: `settings()` (109 mục), `xinfas()`, `cooldowns()` theo nhóm, `lastStudy()`, `myMenpai()`, `studyTeacher()`; hàm tạo 402/409/134/555; bộ đếm `settingLists, xinfaLists, cooldownEntries, studyResults, studyInfos, addSkills`.
- **Bot** `CysNetBot --mode world`: `--hotbar 1` (402 → liệt kê F1..F10/R1..R10), `--hotbar 2` (thêm: đặt ô trống đầu tiên của F1..F10 = kỹ năng `--cast` hoặc 0 bằng 409, chờ 1,2 s, hỏi lại, PASS nếu lưu; trả về giá trị cũ, hỏi lại, "restored"), `--xinfa 1|2` (134; 2 = gửi 555 cho tâm pháp đầu tiên nếu có), `--cast SKILL,TARGET` (TARGET 0 = quái phe 9/10 gần nhất rồi quái bất kỳ, bỏ mục tiêu bị −16/−8; bấm một lần, ghi 331/1692/85/7; bấm lại ngay trong hồi chiêu; bấm tiếp mỗi max(1,3 s, hồi chiêu + 0,2 s) tới khi mục tiêu chết). Khối `skills` trong `result.json`. Runner `Tests/net/run_skills_live.ps1` (snapshot trước/sau chỉ đọc).
- **Game.exe**:
  - `Network/CysSkillNet.{h,cpp}`: dịch 409 (SkillData id → template; ô rỗng data 0), 134, 555; `TemplateOfSkillData` cho 83 (`CysModernGame.cpp`); port 357 (dựng `GCRetSetting` 0.85 với data kỹ năng = template × 100 + cấp rồi gọi `GCRetSettingHandler` — SystemSetup, `MainMenuBar_SetID`, thẻ chat; ô rỗng xoá hẳn), 607 (`Set_SkillClass` + `SkillClass_Update`), 85 (`CoolDownGroup_UpdateList`, bỏ gói thú), 137, 15 (`GE_TOGLE_SKILLSTUDY` với NPC), 78; `OnSkillList` thay thân `OnGCDetailSkillList` (CysModernHandlers): xoá, `Set_Skill(template, cấp)`, áp lại thanh nhanh (thanh đến trước kỹ năng), `GE_SKILL_UPDATE`. Tự gửi 1252 khi nhận 357 lần đầu và 134 sau danh sách kỹ năng đầu (client 0.85 không bao giờ hỏi).
  - `Procedure/GamePro_Main.cpp`: Tab = chọn địch gần nhất.
  - `LuaApiGen/CysHost_Skill.{h,cpp}` đăng ký lúc `CysModernGame::Start`.
  - `Network/CysSkillDriver.{h,cpp}` (`CYS_SKILL_LIVE=1`, sau driver túi đồ trong `CysGlLoginSmoke` mode World): chờ 55 + 357 → PNG HUD → `TOGLE_SKILL_BOOK` → PNG → `TOGLE_COMMONSKILL_PAGE` → PNG → kéo F1 ra khỏi thanh bằng chuột CEGUI tiêm (`CysUiSmokePointer`) → PNG → kéo kỹ năng (`CYS_SKILL_ID`, mặc định 0) từ `CommonSkill_Skill<n>` (tính như `CommonSkill_Update`) thả lên `Button_Action1` → PNG → đóng sách → Tab → PNG khung mục tiêu → F1 (WM_KEYDOWN) → PNG hiệu ứng + số sát thương → F1 tới khi mục tiêu chết → PNG → phím hồi chiêu `CYS_SKILL_COOL_KEY` (mặc định F8 = 打坐) → PNG lớp phủ hồi chiêu. Camera đặt về góc cổ điển trước mỗi ảnh. Nếu kéo chuột không đổi ô, dùng `NotifyDragDropDragged` (log "fallback").

## 5. Học / nâng tâm pháp ở 4 bản đồ

- NPC gia nhập/thầy tâm pháp chỉ có trong cảnh môn phái: 0.85 (`oshaolin_xuanji`, `owudang_zhangxuansu`…, cảnh 9–17) và CY4 (`cy4_*_join`/`cy4_*_teacher` 980000+, cảnh 2220–2223, cùng `Xbw_*_XiuXi`). Cả hai nhóm cảnh đang **tắt** (`configs/cys_scene_off.json`, chỉ giữ 0/1/2/6/71–74/77/1311–1321/1500/2218). Đại Lý chỉ có tiếp dẫn `cy4_*_hub` (role `Dali_inbound_travel` → cảnh tắt) **[DK]**.
- GM: `GmTool_Self:ConsoleRoleUse` có `change_menpai` (gọi `LuaFnJoinMenpai`: đặt phái, danh sách tâm pháp cấp 1, kỹ năng `direct_study_up`, tự điền thanh K1..K9) và `set_xinfa`, nhưng kiểm `IsGM` theo tên tài khoản (`GmRootLarge = {"chen00"}`); **test00 không có quyền** **[DK]**. Cổng admin HTTP `hs_admin` gọi script theo `cluster` — không dùng (không chắc cổng thuộc server riêng, và vẫn vướng `IsGM`).
- Vì vậy CYTest00 (vô môn phái 9, cấp 15) **không thể** có kỹ năng phái hay tâm pháp trên server riêng mà không sửa server. Đề xuất (không áp): `Build/Logs/2026-09-15-skills-ui/server-proposal/menpai-test_vi.md`.

## 6. Kiểm chứng

Bằng chứng `Build/Logs/2026-09-15-skills-ui/` (tóm tắt; chi tiết `Timeline/handoff/skills-ui.md`):

- Bot **[LIVE]**: `bot-live-2` thanh nhanh F1=1/0 F8=1/35 F9=1/22 F10=1/21 → đặt F2 → hỏi lại thấy F2 → trả về → như cũ; `--cast 0,0` giết quái phe 9; `bot-live-3` `--cast 775,0` → −42. decode 0.
- GUI **[LIVE]** (`run_world_gui_live.ps1` PASS): `gui-live-6` Tab → khung mục tiêu, F1 → 331 + sát thương + quái chết, F8 → `GCCooldownUpdate` nhóm 100 1.200 ms; `gui-live-9` trang Phổ thông chọn "Tấn công thường" + mô tả tiếng Việt; `gui-live-10` sách Môn phái có 6 tâm pháp (Kim Cang Kinh cấp 30) sau khi phía người điều phối đổi CYTest00 sang Thiếu Lâm, nhãn rút gọn không chồng, nhân vật đứng chỗ trống trước ảnh chiến đấu.
- Test: `world-run-2` (unit 73 check, 19 loopback, bot), `netcore-run-1`, `netbot-tests-1.txt` 27/27.
- Chưa: kéo bằng chuột CEGUI tiêm (driver dùng `NotifyDragDropDragged`), học tâm pháp ở NPC (15/555/137 chưa live), lượt GUI dùng kỹ năng phái trên F1 (driver sẵn `CYS_SKILL_ID`, chờ khe test00).

## 7. Khác biệt CY / 0.85 và bẫy

1. CY: ID template ở mọi gói; 0.85: SkillData id (×100 + cấp) trong UI và gói.
2. `GCDetailSkillList` CY không mang cấp; cấp suy ra từ tâm pháp.
3. Client 0.85 không gửi 1252 / 134 lúc vào cảnh; server CY đẩy 55 một lần lúc đăng nhập nhưng không đẩy 607.
4. `CGModifySetting` trong 3 s đầu sau khi vào cảnh bị server bỏ qua im lặng.
5. Server không trả lời 409; `GCRetSetting` chỉ đến khi hỏi 402 (hoặc khi đổi ẩn danh hiệu).
6. Đánh thường không có `GCCooldownUpdate`; muốn thấy hồi chiêu server phải dùng kỹ năng có hồi chiêu (打坐 35, nhóm 100).
7. Kỹ năng phái chưa học → −42 dù `character:have_skill` luôn true (kiểm ở tầng human/skill).
8. `MainMenuBar_SetID` 0.85 bỏ qua `AOT_EMPTY` → phải xoá ô bằng `INVALID_ID`.
