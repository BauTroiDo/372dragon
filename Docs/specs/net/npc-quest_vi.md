# Thoại NPC, nhiệm vụ và dịch chuyển qua NPC trên giao thức CY — 15/09/2026

Tiếp nối [inventory-equip_vi.md](inventory-equip_vi.md) (thoại NPC → mục cửa hàng) và [core-loop_vi.md](core-loop_vi.md). Phần này đặc tả **hộp thoại NPC CY** (`Quest.lua`), **nhận / hoàn thành nhiệm vụ** (gói `GCScriptCommand` 1/3/4/5, `CGMission*`), **danh sách nhiệm vụ** (`GCMissionList/Add/Modify/Remove/HaveDoneFlag`), **khung theo dõi nhiệm vụ CY** (`MissionTrack.lua`) và **dịch chuyển giữa bản đồ qua NPC trạm dịch** trên server riêng `/home/ubuntu/cys-test-20260913` (login 15733 / game 15734). ID gói giữ ID skynet (`Registry/protocol/packets.yaml`, codec `Src/Shared/ProtocolGen`). Mọi sửa trong mã gắn `// CYS-QUEST`.

Ký hiệu: **[DK]** dữ kiện đọc từ mã server / dữ liệu CY / mã client; **[SL]** suy luận chưa kiểm; **[LIVE]** đã thấy trên server riêng (bot hoặc Game.exe).

## 1. Tóm tắt wire

| Hành động | Client → server | Server → client | Handler server (chỉ đọc) | Trạng thái |
| --- | --- | --- | --- | --- |
| Hỏi danh sách nhiệm vụ | 957 `CGAskMissionList` {m_objID u32 = mình} | 288 `GCMissionList` (2368 B cố định) | `scenecore.lua:3919` → `human:send_mission_list:4642` | [LIVE] |
| Thoại NPC | 1095 `CGCharDefaultEvent` {m_objID = NPC, targetID = mình} | 397 `GCScriptCommand` cmd 0 (danh sách mục) | `scenecore.lua:5496 char_default_event` → script NPC `UpdateEventList` | [LIVE] (inventory-equip) |
| Chọn mục nhiệm vụ | 107 `CGEventRequest` {m_objID = **script nhiệm vụ**, index, arg = NPC, 0} | 397 cmd **1** (thông tin, chưa nhận) / cmd **3** (yêu cầu, đã nhận) / cmd **4** (phần thưởng, NPC trả thẳng) | `char_event_request:5512` → `obj:event_request` → NPC `OnEventRequest` → nhiệm vụ `OnDefaultEvent` | [LIVE] |
| Nhận | 1232 `CGMissionAccept` {m_idNPC i32, unknow i32 (-1), m_idScript i32} | 907 `GCMissionAdd` {id, index = script, yFlag i8, params 8×i32} + 896 `GCMissionModify` (params) + tip | `char_mission_accept:7768` → NPC `OnMissionAccept` → `CheckAccept` / `OnAccept` → `human:add_mission:7621` | [LIVE] |
| Tiếp tục (xem thưởng) | 163 `CGMissionContinue` {m_idNPC, -1, m_idScript} | 397 cmd **4** | `char_mission_continue:8026` → `OnMissionContinue` → `OnContinue` | [LIVE] |
| Nộp | 322 `CGMissionSubmit` {npc_id, script_id, select_radio_id = **id vật phẩm** chọn, 0} | 732 `GCMissionRemove` {id} + 603 `GCMissionHaveDoneFlag` {mission_id, flag} + EXP / vật phẩm (623) | `char_mission_submit:6663` → `OnMissionSubmit` → `OnSubmit` → `DelMission` + `MissionCom` | [LIVE] |
| Bỏ | 261 `CGMissionAbandon` {index = script} | 732 | `char_mission_abandon:7760` → `push_command_mission_abandon` | dịch, chưa live |
| Nộp vật phẩm (kiểm) | 682 `CGMissionCheck` {npc, -1, script, 3×i8 ô túi, pet u8, 0, 0} | tuỳ script | `char_mission_check:7778` → `OnMissionCheck` | dịch, chưa live |
| Gợi ý | — | 397 cmd **5** {u16 len, str} | `script_base:DispatchMissionTips:551` | port |
| Mục trạm dịch | 107 `CGEventRequest` {script 990010, index 1001/1010…, NPC} | 1100-series đổi cảnh: `GCNotifyChangeScene` → `CGAskChangeScene` → `GCRetChangeScene` | `chuan_song_system.lua OnEventRequest` → `400900 TransferFunc` | [LIVE] bot / GUI |

`GCScriptCommand` (`mission.lua:57 bos`) **[DK]**:

- cmd 0/2: `target_id i32`, `size u8`, `event[size]` {flag i32; flag 0/2 → `str16`; flag 1 → `index i32, type i32, script_id i32, split i32, str16`}.
- cmd 1: `target_id u32, -1 i32, m_objID i32 (= script), m_idMission i32, size u8, str16[size], m_yBonusCount u8 (= #m_aBonus, luôn 0 ở server này), bonus…`.
- cmd 3: `target_id u32, -1, script u32, mission u32, done u32 (0 chưa / 1 xong / 2 cần nộp đồ), size u8, str16[size], m_yDemandCount u8 (luôn 0), {count u8, itemid i32}…`.
- cmd 4: `target_id i32, -1, script i32, mission i32, size i8, str16[size], item_count i8, items[] {flag i32; flag 2/4 → count u8; item_index i32}`. `script_base.lua`: `AddMoneyJZBonus` flag **0** (giao tử), `AddMoneyBonus` **1** (vàng), `AddItemBonus` / `AddRadioItemBonus` đều **4** (có count), `AddRandItemBonus` **5**.
- cmd 5: `u16 len, str`.

Loại mục (`AddNumTextWithTarget` / `AddNumText` type) **[DK]**: 1 nhiệm vụ nhận được (hoặc đã nhận chưa xong), **2 đã nhận / nộp được**, 6 thưởng, 7 cửa hàng, 9 dịch chuyển, 11 khác. Mục nhiệm vụ có `script_id` = script nhiệm vụ (2102xx), mục chức năng có `script_id` = script NPC.

`GCMissionList` **[DK]**: `m_objID u32, m_uMissionListFlags u32 (bit i = ô i có nhiệm vụ), #char_missions u8, 20×{id i32, index i32 (= script), yFlag u8, params 8×i32}, 0 i16, 0 i8, 128×u32 cờ đã xong (bit = mission_id & 31 của phần tử mission_id >> 5), 256×u32 MissionData`. Server xếp nhiệm vụ liền nhau từ ô 0 (`table.remove` khi xoá). `GCMissionModify` flag 0 = một nhiệm vụ (id, index, yFlag, params); flag 1 = MissionData {index u16, value u32} (≈ 250 gói lúc vào cảnh).

## 2. Nhiệm vụ tân thủ và NPC dùng làm bằng chứng

`dali_new_320_monster.ini` (cảnh 2) **[DK]**:

| NPC | Vị trí | Script | Vai trò |
| --- | --- | --- | --- |
| 赵天师 Triệu Thiên Sư | (160,158) | 2030 `odali_xinshoutian` | `g_eventList` 210240, 210200, 210238, 210258, 210262, 210263, 210266… |
| 蒲良 Bồ Lương | (219,123) | 2023 `odali_puliang` | nộp 210200 "Vũ khí đầu tiên" (thưởng chọn 1 trong 6 vũ khí + 10 × 30101001 + 1 giao tử + 700 EXP), 210256 |
| 崔逢九 Thôi Phùng Cửu | (253,121) | 990010 `chuan_song_system` | trạm dịch: 1001 Lạc Dương (0; 235,322), 1002 Tô Châu (1; 204,256), 1000 môn phái… |
| 吴德昌 Ngô Đức Xương | Lạc Dương (235,322) | 990010 | 1010 Đại Lý (2; 253,121) |

Nhiệm vụ (server Việt hoá, `Game_2/Script/scripts/event/dali/*`) **[DK]**:

- 210262 `edali_newquest_001` mission 1400 "Sơ nhập giang hồ": nhận ở 赵天师 → `SetMissionByIndex(0,1)` xong ngay → nộp ở 赵天师 +200 EXP, gọi 210200 `OnDefaultEvent`.
- 210238 `edali_0238` mission 1424 "Mười năm": xong khi cấp ≥ 10, nộp ở 赵天师 (EXP 0).
- 210200 `edali_zhidao_0200` mission 1401 "Vũ khí đầu tiên": nhận ở 赵天师, **nộp ở 蒲良** (`OnDefaultEvent` gọi thẳng `OnContinue` → cmd 4, không có cmd 3), `OnSubmit` so `selectRadioId` với id vật phẩm.
- 210266 mission 1417 "Pháo hoa mừng lễ" (赵天师, +2400 EXP), 210268 mission 1421 "Thập Đại Môn phái".

CYTest00 15/09 trước khi chạy: cấp 15, EXP 1365, đang có 1424/210238 và 1400/210262 (p0 = 1, cả hai nộp được), chưa có cờ xong 1400–1430 **[LIVE]**.

## 3. Lua CY và host

Mã nguồn: `Assets/CanonicalCY/Data/InterfaceFolder/{Quest,MissionTrack,QuestLog}`.

### 3.1 `Quest.lua` (hộp thoại NPC)

| Sự kiện | Nguồn C++ | Lua | Host |
| --- | --- | --- | --- |
| `QUEST_EVENTLIST` | cmd 0 → `CUIDataPool::OnEventListResponse` | `Quest_EventListUpdate`: `DataPool:GetNPCEventList_Item` → `QuestGreeting_Desc:AddOptionElement(text.."&"..script..","..index.."$"..icon)` | 0.85: `GetNPCEventList_*`. **Sửa** `ComplexWindow::AddOptionElement` hiểu định dạng CY `&…,…$` (tìm từ cuối vì chữ có `#G`, `,`), bỏ assert với chữ thường có `#`. |
| `QUEST_INFO` | cmd 1 → `OnMissionInfoResponse` | `Quest_QuestInfoUpdate`: `GetMissionInfo_Num/Text/Bonus`, `LifeAbility:GetQuestUI_Reward`, `GetMissionInfo_ScriptID`, nút Nhận | CY: `GetMissionInfo_ScriptID`, `GetMissionInfo_Bonus` ("money"/"moneyjz"/"item"/"itemrand"/"itemradio"/"exp"), `LifeAbility:GetQuestUI_Reward/Demand` |
| `QUEST_CONTINUE_DONE/NOTDONE` | cmd 3 → `OnMissionDemandInfoResponse` | `Quest_MissionContinueUpdate`: nút Tiếp tục bật khi xong | 0.85 `GetMissionDemand_*` |
| `QUEST_AFTER_CONTINUE` | cmd 4 → `OnMissionContinueInfoResponse` | `Quest_MissionRewardUpdate`: phần thưởng, nút Hoàn thành; `GetMissionContinue_ScriptID/MissionID/IssueScriptID/ItemID` | CY: 4 hàm `GetMissionContinue_*` |
| Nút | — | `QuestOption_Clicked` → `QuestFrameOptionClicked` (107); `QuestAccept_Clicked` → `QuestFrameAcceptClicked` (1232); `MissionContinue_Clicked` → `QuestFrameMissionContinue` (163) / `QuestFrameMissionComplete(id)` (322) | 0.85 `CUIDataPool::Send*Event` + dịch `CysQuestNet::Translate` |

Ô mục trong `TLBB_Look_ComplexWindow` CY: `ChildItem key:Option name:TLBB_QuestButton`, biểu tượng theo trạng thái `QuestButtonImage index:N set:S image:I` **[DK]**. 0.85 tạo `WoWLook/QuestButton_1..4` → thêm bí danh sang `TLBB_QuestButton` (và `WoWLook/Button_1` → `TLBB_ButtonNULL`) trong `UISystem.cpp`; `FalagardComplexWindow::AddChildElement_Option` gắn ảnh 16×16 `QuestButtonImage[state]` bên trái. `AddJiaoZiElement` (thưởng giao tử) dùng widget tiền.

### 3.2 `MissionTrack.lua` (khung theo dõi) và `QuestLog.lua`

- Mở bằng `OPEN_MISSION_TRACK 1`, cập nhật `UPDATE_MISSION_TRACK slot`, `NEW_MISSION slot` — sự kiện CY **không có trong bảng 0.85** (RegisterEvent tên lạ bị bỏ qua) → thêm `GE_OPEN_MISSION_TRACK`, `GE_UPDATE_MISSION_TRACK`, `GE_NEW_MISSION`, `GE_DELETE_MISSION`, `GE_UPDATE_WILLGET_MISSION_TRACK` (nối cuối enum `TDEventDefine.h`, bảng `GMEventSystem.cpp`). `CysQuestNet` bắn `OPEN_MISSION_TRACK` ở `GCMissionList` đầu tiên, `UPDATE_MISSION_TRACK` ở mỗi Add/Modify/Remove, `NEW_MISSION` ở Add.
- Dữ liệu nhiệm vụ đi qua đường 0.85: `GetPlayerMission_InUse/Name/Kind/Level/Memo/Variable/Description…` đọc `CDetailAttrib_Player::m_listMission` và mô tả client `ConfigFolder/Script.dat` → `event/dali/*.lua` (khối `--MisDescBegin`, **GBK**, tên Trung).
- Host CY thêm (`LuaApiGen/CysHost_Quest.cpp`): `GetPlayerMissionTrackType` (1 cho mọi nhiệm vụ đang có), `IsMissionTrackOpen` 1, `HaveMisstionTrackThisType` 1, `IsTrackFuncShow` 1, `Set*/UpdateTrackStateButton/UpdateMissionTrack` rỗng, `GetMissionFinishInfo` (NPC nộp / tên cảnh / id / x / z), `GetMissionShortName` (giữ nguyên), `GetMissionInfo_Kind` (tên loại Việt), `GetPlayerMission_Display(slot, 7)` = script, `GetPlayerMissionRandomCustom_Num` 0, `GetInfantExpMission` 0, `GetFreshManGuideOwner` "".
- Tên hiển thị (người dùng 15/09: "ghép âm Hán-Việt, thay vì để nguyên chữ Trung"): `Tools/pipeline/cy_quest_text.py` sinh `CysHost_QuestText_vi.inc` cho 102 script của Đại Lý / Lạc Dương / Vô Lượng Sơn: tên nhiệm vụ = `g_MissionName` của script server (Việt, trùng lời thoại), NPC = `wire_names_vi.lua` của server (trùng bảng tên trên đầu NPC), còn lại (loại, mục tiêu tuỳ biến, địa danh) = `cy_item_text.Lookup` (TM / từ điển) rồi ghép âm Hán-Việt `hanviet_name` (117 dòng mới trong `Registry/i18n/cy_items_vi_hanviet.tsv`, src `hanviet-quest`, được `cy_item_text.py hanviet` giữ lại). `CysQuestNet::LocalizeMission` áp sau khi 0.85 phân tích khối mô tả; chữ dài không có bản dịch giữ UTF-8.

## 4. Triển khai

- **NetCore** `WorldModel`: `missions()` (List/Add/Modify/Remove), cờ xong 128×32, `lastMissionDialog()` (cmd 1/3/4: npc, script, mission, done, số dòng, thưởng), đếm `missionInfos/Demands/Continues/Tips/Lists/Adds/Modifies/Removes/DoneFlags/uiCommands`; hàm tạo 957/1232/163/322/261.
- **Bot** `CysNetBot --mode world`: `--talk X,Z` (đi tới, `CGCharDefaultEvent`, ghi mục `script/index/type`), `--quest accept|complete|full` (chọn mục type 1 / 2 hoặc `--quest-script`), `--talk-option N` (mục có index N, chờ đổi cảnh), `--talk-scene ID` (chỉ thoại trong cảnh đó). Khối `quest` trong `result.json`; runner `Tests/net/run_quest_live.ps1` (snapshot trước/sau chỉ đọc).
- **Game.exe** `Network/CysQuestNet.{h,cpp}`: dịch 0.85 → CY (`CGMissionAccept/Continue/Submit/Abandon/Check`; Refuse và AskMissionDesc không có ở CY → không gửi), port cmd 1/3/4/5 (lọc vật phẩm `NewItem` không biết — mã 0.85 dereference không kiểm), `GCMissionList/Add/Modify/Remove/HaveDoneFlag` vào `CDetailAttrib_Player` (lớp bạn `CysQuestAccess`), ghi lại mục của cmd 0 trước khi `CysInventoryNet` dựng danh sách 0.85. Móc: `CysModernGame::Translate` / `Start`, `CysModernHandlers::{IsWorldPacket,Dispatch}` (quest trước inventory; cmd 0 rơi xuống inventory), `GMGameInterface_Script_DataPool.cpp` (LocalizeMission).
- **Replay offline** `NetCore/ReplayStream` (`CYS_WORLD_REPLAY_QUEST=1`): bộ trả lời tổng hợp đóng vai Triệu Thiên Sư — `CGAskMissionList` → `GCMissionList` (1400/210262 nộp được, 1401/210200), `CGCharDefaultEvent` → cmd 0 (mục 210262 type 2, 210266 type 1), `CGEventRequest 210262` → cmd 3 done=1, `210266` → cmd 1, `CGMissionAccept` → `GCMissionAdd 1417`, `CGMissionContinue` → cmd 4 (vàng 200 + 10 × 30001011), `CGMissionSubmit` → `GCMissionRemove` + `GCMissionHaveDoneFlag`. NPC hộp thoại là id không tồn tại để `Quest.lua` không đóng vì khoảng cách. `CysWorldReplay` chạy `CysQuestDriver` sau 3 cú click (`CYS_QUEST_NPC=near`). Kịch bản: `scripts\quest_replay.ps1`.
- **GUI live** `Network/CysQuestDriver` (`CYS_QUEST_LIVE=1`, sau inventory/skill driver): `CYS_QUEST_COMPLETE=script` → thoại → mục type 2 → cmd 3 → `SendContinueEvent` → cmd 4 → `SendCompleteEvent(0)`; `CYS_QUEST_ACCEPT=script` → mục type 1 → cmd 1 → `SendAcceptEvent`; `CYS_QUEST_TRAVEL=X,Z,IDX` / `CYS_QUEST_RETURN=X,Z,IDX` → mục trạm → chờ cảnh mới. PNG `cys-live-*-quest-*`. Kịch bản lượt: `Build/Logs/2026-09-15-npc-quest/scripts/quest_gui_turn.ps1` (stage `stage-<sha>-npcq`, đặt nhân vật bằng bot, `CYS_WORLD_REPLAY_CLICKS` giữ nhân vật cạnh NPC để `Quest.lua` không đóng vì xa > 3 m).

## 5. Kiểm chứng

- Bot live (`Build/Logs/2026-09-15-npc-quest/`):
  - `live-1`: Vô Lượng Sơn → cổng → Đại Lý → 赵天师: menu `2030/60000/t6 210240/100/t11 210200/2/t1 210238/1/t2 210262/1/t2 210263/1/t1 210266/1/t1 210276/1/t1 210268/1/t1`; chọn 210200 → cmd 1 (4 dòng) → `CGMissionAccept` → `GCMissionAdd 1401/210200 p0=1 p1=1`; decode 0, quit flag 0. Lượt thoại lại không có mục 210200 (nộp ở 蒲良) — đúng script.
  - `live-2`: `--quest complete --quest-script 210238` → cmd 3 done=1 → `CGMissionContinue` → cmd 4 → `CGMissionSubmit` → `GCMissionRemove` + `GCMissionHaveDoneFlag` (1424 xong); decode 0.
  - `live-5`: `--talk-scene` chưa có → bot đi trong cảnh 73 (xem bẫy 3).
- Unit `cys_world_tests` (`questModel`): cmd 0/1/3/4, `GCMissionList/Add/Remove/HaveDoneFlag` qua codec strict vào `WorldModel`; `CGMissionAccept`/`Continue` 12 B, `CGMissionSubmit` 16 B mang id vật phẩm, `CGAskMissionList` 4 B (`world-run-2.txt`: 83 kiểm tra PASS).
- GUI live `gui-live-2`: khung theo dõi nhiệm vụ CY hiện (Đại Lý / Sơ nhập giang hồ Hoàn thành / Đến Đại Lý tìm Triệu Thiên Sư / Vũ khí đầu tiên) — `cys-live-28902921-quest-track-start.png`.
- Test: `run_protocol_tests.py` G1 GATE PASSED (`protocol-run-1.txt`), `run_netcore_tests.py` PASS (`netcore-run-1.txt`), `run_world_session_tests.py` PASS 19 loopback + bot (`world-run-1.txt`). Build toàn bộ rc 0 (`build-6-full.log`).

## 6. Khác biệt CY / 0.85 và bẫy

1. 0.85 `CGEventRequest` = {NPC, script, exIndex}; CY đảo (m_objID = script, arg = NPC) — đã có từ inventory-equip.
2. CY không có `CGMissionRefuse` / `CGAskMissionDesc`: mô tả lấy từ `ConfigFolder`, nút Huỷ chỉ đóng hộp thoại.
3. `CGMissionSubmit.select_radio_id` là **id vật phẩm** chứ không phải chỉ số (`edali_zhidao_0200 OnSubmit`).
4. NPC nộp có thể trả cmd 4 ngay không qua cmd 3 (210200 ở 蒲良).
5. `AddItemBonus` và `AddRadioItemBonus` cùng flag 4 → client coi là "chọn một"; một phần thưởng duy nhất được Lua tự chọn.
6. Sự kiện theo dõi CY chưa có trong bảng 0.85 → `RegisterEvent` im lặng; phải thêm enum.
7. Nút mục của ComplexWindow 0.85 là `WoWLook/QuestButton_N` (không có trong scheme CY) — không bí danh thì `createWindow` ném lỗi.
8. `test00` dùng chung: đăng nhập bị từ chối `login_flag 8` tới ~1–2 phút sau khi phiên khác đóng socket (không còn kết nối 15733/15734) → chờ yên ≥ 90 s trước mỗi lượt.
9. Bot đi thẳng không có navmesh: nếu nhân vật đã bị agent khác dời cảnh, `--talk X,Z` có thể đi trong cảnh sai → dùng `--talk-scene`.

## 7. Biến thoại `$N` và các biến CY khác

**Nơi CY thay biến (dữ kiện, Ghidra chỉ đọc).** Không phải server (script chỉ gửi `$N` nguyên văn), không phải Lua (`Quest.lua` không có `$`), không phải Game.exe (Game.exe CY chỉ dùng `$N`/`$U` cho danh hiệu và mẫu chat). CY thay trong **UI_CEGUI.dll**: bộ phân tích chuỗi runtime `FUN_18004b050` gọi `FUN_180054e20` (kiểm mã chữ) rồi `FUN_18004a5e0` tại `0x18004b146`, trước khi xử lý `#`. Mọi chuỗi qua `ParserString_Runtime` (hộp thoại NPC `AddTextElement`, mục chọn, bảng tên, chat) đều được thay.

| Biến | CY đọc | Giá trị |
|---|---|---|
| `$N` | `g_pObjectSystem` vt+0xb8(0) | tên nhân vật mình |
| `$n` | vt+0xb8(1) | tên mục tiêu chính nếu là `CObject_Character`, không thì rỗng |
| `$U` | vt+0xc8 | chuỗi `CharacterData+0x4940` của mình, rỗng khi liên server [SL: chỉ thấy chỗ khởi tạo `0x1401bc250`; không dữ liệu/script nào dùng `$U` → 0.85 trả rỗng] |
| `$G` | giới tính mình (vt+0xc0(0)) | từ điển `GMGameInterface_Script_Talk_Info_G_Woman` / `_G_Man` (Tiểu yêu nữ / Tiểu ác nhân) |
| `$g` | giới tính mục tiêu (vt+0xc0(1)) | `_g_Woman` / `_g_Man` |
| `$R` | giới tính mình | `_R_Woman` / `_R_Man` (Cô nương / Thiếu hiệp) |
| `$r` | giới tính mình | `_r_Woman` / `_r_Man` |

Quy tắc (theo `FUN_18004a5e0`): so ký tự sau `$` theo thứ tự `N n U G g R r` (bảng `0x18008f180`); giới tính 0 = nữ, 1 = nam (người chơi: id bảng chủng tộc % 2 khi `RaceID != -1`, `0x14060b8a0`; NPC: cột giới tính của bảng quái, `0x1406026a0`), giá trị khác → biến bị xoá; thiếu khoá từ điển → rỗng; ký tự khác (vd `$C`, `$1`, `$` cuối chuỗi) → chỉ bỏ `$`; chưa có `g_pObjectSystem` → giữ nguyên chuỗi. `$` nằm trong khoảng bảo vệ (`this+0x138`, do `FUN_180054e20` ghi cho khối `#{_INFOMSG<3 số>…}` và `#{…*?<độ dài>…}`, từ vị trí `#`−1 tới `}`) được chép nguyên cùng ký tự sau. Không có `$C`. Dùng trong CanonicalCY: StrDictionary `$N` 508 lần (440 mục), `$G` 2; script server `$N` 25, `$g` 6.

**Triển khai.** `Src/Client/CEGUISystem/CysDialogVars.h` (header, `Expand` + `ProtectedRanges`), gọi trong `CUIStringSystem::ParserString_RuntimeNew` ngay sau `_CheckStringCode`; nguồn `tObjectSystem::GetTalkName/GetTalkSex/GetTalkUserString` (thêm cuối interface, cài ở `CObjectManager`), từ điển qua `ResolvePackedFormat`. [SL] CY còn đòi trường NPC `+0x4f0 == 0` khi lấy giới tính NPC — chưa ánh xạ.

**Kiểm chứng.** `Tests/luaapi/run_dialog_vars_tests.ps1`: 24 ca PASS (`Build/Logs/2026-09-15-npc-quest/dialog-vars-1`), gồm từ điển CanonicalCY thật (440 mục có `$N` → 0 còn sót, `$R` = Thiếu hiệp / Cô nương).
- **GUI live `gui-live-15`** (stage `stage-607eca6-npcq`, server riêng): thoại Phượng Triều Dương (Quán chủ võ quán, Đại Lý 46,240, script 2037) → mục "Về lôi đài" → trang `#{OBJ_dali_0055}` (chứa `$N`) → driver cuộn chữ tới cuối → hộp thoại hiện "Lôi đài tỷ Ô, sinh tử do mệnh, **CYTest00**, ngươi nghĩ kỹ chưa?" (`cys-live-52709828-quest-npc-dialog-end.png`); runner 11/11 PASS, driver PASS 1/0. Lượt `gui-live-12`/`13` không có `$N` trên màn hình: lời chào Triệu Thiên Sư do script ghép tên sẵn (`PlayerName .. PlayerSex .. #{OBJ_dali_0011}`), lời chào Bạch Sùng Nghĩa có `$N` nhưng dài 404 B > `ScriptString` 255 B nên bị cắt, và `XSRW_100111_2` ("Chào mừng $N Thiếu hiệp") chỉ hiện khi nộp 1400 (đã nộp).
- Driver: `CYS_QUEST_ACCEPT=<script>` trên mục không mở cmd 1 mà mở trang NPC mới/cmd 3 → chụp `quest-npc-dialog-next`/`quest-demand`, bấm nút tăng thanh cuộn `QuestGreeting_Desc` (`CysUiSmokePointer`) tối đa 40 lần rồi chụp `quest-npc-dialog-end`.

## 8. Lời thoại > 255 B, nút đáy hộp thoại, tên cảnh (15/09 tối)

**Giới hạn chữ (dữ kiện Ghidra).** Game.exe CY đọc mỗi chữ của danh sách sự kiện `GCScriptCommand` cmd 0/2 với `len-1 < 0xff` vào bộ đệm 256 B (`FUN_1408471d0`, gọi từ `Packets::GCScriptCommand` vftable `0x140c9e0a8` slot Read `0x140848280`); cmd 5 cũng bộ đệm `0x100`. Server skynet `packet_domains/mission.lua` `bos` ghi `len` nhưng không ghi byte nào khi `len >= 256`, nên client nhận chuỗi rỗng. Server gửi UTF-8 (`wire_charset` chế độ utf8, `fromutf8` chỉ tra tên), không chuyển mã. Bản gốc GBK vừa 255 B; bản dịch tiếng Việt UTF-8 vượt: 174 chuỗi `AddText` literal trong 161 file (`Tests/luaapi/server_event_text_split/scan255.py`), ví dụ Bạch Sùng Nghĩa 404 B.

**Sửa.**
- Server riêng: commit `db708f5`, restart bởi menpai-fix lúc 18:16 (SHA `6ca25a8`). `script_base:EndEvent` tách chữ > 255 B thành các mục ≤ 254 B + `\31`, cắt ở ranh giới UTF-8, ưu tiên sau dấu cách, tổng không quá 16 mục. Không có `\31` nào trong StrDictionary, script hay lualib. Bản vá và test: `Tests/luaapi/server_event_text_split/` (10/10 PASS).
- Client: `CysEventTextJoin.h` chỉ ghép khi thấy dấu `\31` ở cuối mục chữ; mục thường giữ nguyên. Chữ > 255 B lấy qua `CysQuestNet::EventListText` → `DataPool::GetNPCEventList_Item`. Test `run_event_text_join_tests.ps1` 11/11 PASS.

**Nút đáy.** CY `Quest.layout.xml`: `Quest_Button_Accept` (10, −29) và `Quest_Button_Continue` (50, −29), mỗi nút 40×20, sát nhau; `Quest_Button_Refuse` bên phải. `Quest.lua` luôn hiện cả hai, ở danh sách sự kiện thì Disable (chữ xám `FFBBBBBB`). Nhãn đã ngắn nhất: Nhận / Tiếp / Thôi. Chữ nhãn Noto 12 lấp đầy 40 px nên hai nút đọc liền nhau. CY bản Việt dùng phông 1258 hẹp hơn (`VTNAM14.bin`, tahoma). Giữ vị trí và nhãn CY; `CUIWindowItem::LoadWindow("Quest")` gán phông dẫn xuất 10 px `CysQuestButton` cho ba nút (`FontManager::createCysDerivedFont`).

**Tên cảnh.** `SceneDefineEx.txt` cột `szName` (1) và `szDisplayName` (22) được đưa vào `cy_item_text.py` (TM → Hán-Việt). `szName` còn 2/679 chữ Trung; mô tả dài của `szDisplayName` vẫn giữ chữ Trung UTF-8. Cột khoá giữ nguyên byte. Cần `build_canonical_cy.py --apply` ở main. Hiển thị ở: tiêu đề minimap (`GetCurrentSceneName`), bản đồ lớn/thế giới (UILuaControl), tooltip. Nhãn "藏经阁校场" trên minimap không thuộc bảng này: đó là chữ vẽ trong ô `SceneFolder/jpg_dali_new_320_<x>_<z>.dds` (thứ tự nạp `createTiledBackground`: "" → `_SJ` → `_QX`), đã giao ui-image-vi.
