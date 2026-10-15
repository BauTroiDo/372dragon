# Tổ đội, chat và chia kinh nghiệm — đặc tả wire (server riêng CY-Source)

Ngày 17/09/2026 — agent `team-live`. Toàn bộ bố cục lấy từ `GameServer/services/game/packet_domains/team.lua`
+ `social.lua` + `packet_ids.lua` của server riêng `/home/ubuntu/cys-test-20260913`, và được **đo live với hai
nhân vật cùng lúc** (`CYTest05` guid 200006, `CYTest06` guid 200007) bằng `Build\bot-team\CysNetBot.exe`.

Ký hiệu: **[DK]** dữ kiện đọc từ mã nguồn · **[LIVE]** đã bắt được trên dây · **[SL]** suy luận.

---

## 1. Bảng gói CG/GC của tổ đội

| ID | Tên | Hướng | Nơi định nghĩa | Handler server | Đo live |
|---|---|---|---|---|---|
| 447 | `CGTeamInvite` | CG | team.lua:907 | `msgagent:CGTeamInvite` → `.world char_invite_team` | ✅ |
| 966 | `GCTeamAskInvite` | GC | team.lua:998 | `worldcore:char_invite_team` (nhánh không có đội / là đội trưởng) | ✅ |
| 1713 | `GCTeamLeaderAskInvite` | GC | team.lua:2320 | `char_invite_team` khi người mời **không** phải đội trưởng | ❌ (chưa dựng đội 3 người) |
| 791 | `CGTeamLeaderRetInvite` | CG | team.lua:1644 | `char_leader_ret_invite` | ❌ |
| 65 | `CGTeamRetInvite` | CG | team.lua:1152 | `worldcore:char_ret_invite` | ✅ |
| 1280 | `GCTeamList` | GC | team.lua:824 | `char_ret_invite`, `char_ask_team_info`, `char_ret_team_apply` | ✅ |
| 648 | `GCTeamResult` | GC | team.lua:949 | `team:add_member`, `char_team_kick/appoint/leave/dismiss`, `char_start_change_scene`, `char_enter_scene` | ✅ |
| 281 | `GCTeamError` | GC | team.lua:802 | mọi nhánh từ chối trong `worldcore` | ❌ (chưa gặp lỗi trong các lượt đo) |
| 329 | `CGTeamApply` | CG | team.lua:1594 | `char_team_apply` | ❌ |
| 104 | `GCTeamAskApply` | GC | team.lua:1672 | `char_team_apply` → gửi cho đội trưởng | ❌ |
| 258 | `CGTeamRetApply` | CG | team.lua:1619 | `char_ret_team_apply` | ❌ |
| 712 | `CGTeamKick` | CG | team.lua:1575 | `char_team_kick` | ✅ |
| 717 | `CGTeamAppoint` | CG | team.lua:1777 | `char_team_appoint` | ✅ |
| 822 | `CGTeamDismiss` | CG | team.lua:932 | `char_dismiss_team` | ✅ |
| 1353 | `CGTeamLeave` | CG | team.lua:1515 | `char_leave_team` | ✅ |
| 336 | `CGTeamChangeOption` | CG | team.lua:2397 | `char_team_change_option` → `team:set_option` | ✅ |
| 968 | `GCTeamOptionChanged` | GC | team.lua:2416 | `team:set_option` broadcast | ✅ |
| 145 | `CGAskTeamInfo` | CG | misc.lua | `char_ask_team_info` → `GCTeamList` type = REFRESH | ✅ |
| 870 | `CGAutoCreateTeam` | CG | misc.lua | msgagent map thẳng sang `char_ask_team_info` | ❌ |
| 964 | `CGAskTeamMemberInfo` | CG | misc.lua | `scenecore:ask_team_member_info`, rơi về `.world ask_team_member_info` | ✅ |
| 1311 | `GCTeamMemberInfo` | GC | team.lua:1176 | trả lời 964 | ✅ |
| 126 / 887 / 1745 / 457 / 782 / 273 / 1263 | team-follow (`CGAskTeamFollow`, `GCAskTeamFollow`, `CGReturnTeamFollow`, `GCReturnTeamFollow`, `GCTeamFollowList`, `GCTeamFollowErr`, `CGStopTeamFollow`) | | team.lua + scenecore:7853… | `char_ask_team_follow` / `char_return_team_follow` | ❌ |
| 1288 | `GCDetailExp` | GC | misc.lua | `human:add_exp` | ✅ |

`define.TEAM_RESULT` (`lualib/define.lua:1300`): 0 MEMBERENTERTEAM · 1 MEMBERLEAVETEAM · 2 LEADERLEAVETEAM ·
3 TEAMDISMISS · 4 TEAMKICK · 5 TEAMAPPOINT · 6 TEAMREFRESH · 7 STARTCHANGESCENE · 8 ENTERSCENE ·
9 REFRESHSERVERINFO · 10 MEMBEROFFLINE. `define.MAX_TEAM_MEMBER = 6`, `define.LEADER_ID = 1`.

## 2. Bố cục trường (chỉ những gói đã dùng)

### 447 `CGTeamInvite` (CG) — team.lua:917 **[DK]**
```
i32 data_length      -- server đọc rồi bỏ; bot ghi 11 + #dest_name
i32 m_objID          -- obj id của người mời
i32 unknow           -- client CY ghi -1
u8  dest_name_size ; bytes dest_name   (1..29, GBK trên dây)
u16 unknow_1
```
`worldcore:char_invite_team` **chỉ đọc `dest_name`**; tra bằng `name_2_guid` (khoá là `uinfo.name`, UTF-8). **[DK]**

### 966 `GCTeamAskInvite` (GC) — team.lua:1079 **[DK]**
```
i32 guid             -- GUID người mời (dùng lại ở CGTeamRetInvite.guid)
bytes[30] nickname   -- tên người mời, đệm 0
i16 unknow_1 (-1) ; u8 member_size
member_size x { u8 detail_flag ; u8 n ; bytes[n] nickname ; i32 menpai ; i16 sceneid ;
                i32 level ; i16 model ; i32 unknow_6 ; i16 model_2 }
u32 71147369         -- hằng số
```

### 65 `CGTeamRetInvite` (CG) — team.lua:1163 **[DK]**
```
u8  return_type   -- 1 = đồng ý, 0 = từ chối
u32 guid          -- GUID NGƯỜI MỜI (không phải của mình)
u32 unknow_3
u32 list[8]
```

### 1280 `GCTeamList` (GC) — team.lua:841 **[DK][LIVE]**
Khung ngoài `i32 data_length` + blob. Trong blob:
```
u8  0
u32 type      -- define.TEAM_LIST_TYPE: 0 CREATE, 1 JOIN, 2 REFRESH
u16 team_id
u32 exp_mode
u8  member_size (tối đa 6)
i32 0
member_size x 108 byte:
   i32 guid ; i16 sceneid ; i16 client_res ; i32 m_objID ; u8 name_size ;
   bytes name + đệm 0 cho đủ 31 byte ;
   u32 portrait_id ; u16 race_id ; u16 0 ; u32 level ; u8 menpai ; u8 0 ; i16 race_id ;
   TeamMemberInfo (48 byte, packet_types/team_types.lua)
```
**Không có trường đội trưởng trên dây.** `worldcore` luôn ghi `team:get_members()` mà `team:leader()`
= `members[1]` (`lualib/team.lua:104`), nên **phần tử đầu tiên chính là đội trưởng**. **[DK]** —
kiểm live: lượt 03/08 luôn cho `member_list[0].guid == 200006` = người mời = đội trưởng. **[LIVE]**

### 648 `GCTeamResult` (GC) — team.lua:962 **[DK][LIVE]**
```
u8  return_type ; i32 guid ; u16 team_id ; i32 guid_ex ; i16 sceneid ; i16 client_res ;
u8  name_size ; bytes name ; u32 portrait_id ; u16 sex ; i16 sex
(nếu return_type == 0 hoặc 8) TeamMemberInfo 48 byte
```
`worldcore` có gán `msg.leader_guid` nhưng **`bos` không ghi trường đó ra dây** → client không đọc được
đội trưởng mới từ gói này; phải suy từ `guid_ex` của type 5 (APPOINT) hoặc từ `GCTeamList`. **[DK]**

### 1353 `CGTeamLeave` / 822 `CGTeamDismiss` (CG)
Cùng bố cục `i32 guid`. `worldcore` bỏ qua trường này và dùng GUID của phiên. **[DK]**

### 336 `CGTeamChangeOption` / 968 `GCTeamOptionChanged`
`i32 unknow_1 ; u64 exp_mode`. Chỉ đội trưởng được đổi (`char_team_change_option` kiểm `team:leader().guid`). **[DK][LIVE]**

### 753 `CGChat` — nhánh theo kênh (social.lua:59) **[DK][LIVE]**
```
u8 ChatType ; u32 ContexSize ; bytes Contex ; u8 n ; bytes unknow_7 ; u32 unknow_8 ;
u8 unknow_9 ; u32 unknow_10
  ChatType 0 (thường)   -> u16 unknow_2
  ChatType 1 (tổ đội)   -> u16 teamID
  ChatType 3 (riêng)    -> u8 n ; bytes TargetName ; u16 unknow_2
  ChatType 2/5/6/7/11/14/15/18 -> xem social.lua:77-99
u8 uts[3] ; (4 x tuỳ uts: item guid / pet guid / 67 byte exterior)
```
Định tuyến trong `scenecore.lua:6067`: 0 → `broadcast` trong cảnh; 1 → `.world team_chat` →
`team:broad_team_msg`; 3 → `.world tell_chat` (gửi người nhận) **và** một bản `CHAT_TYPE_TELL_RET = 25`
gửi lại cho người gửi.

## 3. Luồng đã chứng minh live

### 3.1 Mời → chấp nhận (lượt `03-invite`, `08-exp`) **[LIVE]**
```
T+0      CYTest05  CG 447 CGTeamInvite dest_name="CYTest06"
T+39ms   CYTest06  GC 966 GCTeamAskInvite guid=200006 nickname=CYTest05
T+39ms   CYTest06  CG  65 CGTeamRetInvite return_type=1 guid=200006
T+76ms   CYTest05  GC 648 GCTeamResult type=0 guid=200007 team_id=1 name=CYTest06
T+76ms   cả hai    GC 1280 GCTeamList team_id=1 member_size=2
                        [200006 CYTest05 obj 349 scene 74 lv 15 | 200007 CYTest06 obj 348 scene 74 lv 15]
```
Chú ý **[DK]**: `human:update_team_info` (`services/scene/obj/human.lua:5288`) **không** đặt
`bNotifyTeamInfoFlag` khi `msg.guid == self:get_guid()`, nên `msgagent` chặn gói `GCTeamResult`
"chính mình vào đội". Client chỉ biết mình đã vào đội qua `GCTeamList`. Đo live khớp: người mời chỉ nhận
1 GCTeamResult (về người kia), người nhận không nhận GCTeamResult nào trong lúc lập đội. **[LIVE]**

### 3.2 Thanh tổ đội (`CGAskTeamInfo` + `CGAskTeamMemberInfo`) **[LIVE]**
`CGAskTeamInfo` (145) → `GCTeamList` type = REFRESH. Khi **chưa có đội**, `char_ask_team_info` không trả
gói nào (lượt `01-names`: `team_lists = 0`). `CGAskTeamMemberInfo` (964) → `GCTeamMemberInfo` (1311)
với hp/mp/level/vị trí/trang bị của từng thành viên.

### 3.3 Chia kinh nghiệm **[LIVE]** — bằng chứng số học
`monster:on_die_after` → `refix_occupant_guid` → `caculate_owner_list` → `dispatch_exp`
(`services/scene/obj/monster.lua:466`).

| Lượt | Ai hạ quái | exp_mode | CYTest05 | CYTest06 | Nhận xét |
|---|---|---|---|---|---|
| `04-exp` | CYTest05 (một mình, hai cảnh khác nhau) | 0 | **273** | 0 | mốc đơn lẻ |
| `08-exp` | CYTest05 (đội trưởng) | 0 | **178** | **178** | `ceil(273 × 0,65) = 178` đúng `team_exp_rate[2]` |
| `09` | CYTest05 (đội trưởng) | **1** | **178** | **178** | exp_mode **bị bỏ qua** → lỗi, xem mục 4.1 |
| `10` | CYTest06 (đội viên), đội trưởng cách quái 17,6 m | 1 | 0 | **273** | không chia → lỗi, xem mục 4.2 |
| `11` | CYTest06 (đội viên), đội trưởng cách quái 11,6 m | 1 | **119** | **238** | đúng công thức exp_mode 1 |

Công thức trong `dispatch_exp`: `team_exp_rate = {1.0, 0.65, 0.54, 0.50, 0.49, 0.48}` theo số người hưởng;
`exp = base_exp * rate` rồi mới qua `caculate_base_exp` (suy giảm theo chênh cấp × `config_info.Exp.ExpParam`).
Với `exp_mode == 1`: chủ sở hữu nhận `add + add*(n-1)/3`, người còn lại nhận `add*2/3`
→ `ceil(178 + 178/3) = 238`, `ceil(178*2/3) = 119`. Khớp tuyệt đối. **[LIVE]**

### 3.4 Trao quyền / đuổi / rời / giải tán **[LIVE]** (lượt `14-appoint-kick`, `12-chat`)
```
CG 717 CGTeamAppoint dest=200007  -> GC 648 type=5 guid_ex=200007, cả hai nhận, đội trưởng đổi
CG 712 CGTeamKick   dest=200006  -> GC 648 type=4 guid=200006, cả hai nhận, người bị đuổi sạch danh sách
CG 1353 CGTeamLeave              -> GC 648 type=2 (LEADERLEAVETEAM) khi người rời là đội trưởng
CG 822 CGTeamDismiss             -> GC 648 type=3 (TEAMDISMISS) guid=-1, cả hai sạch danh sách
```
Thoát khỏi thế giới (CGAskQuit) cũng gọi `worldcore:leave_world` → `char_leave_team`; người cuối cùng
nhận `type=3`. **[LIVE]**

### 3.5 Chat **[LIVE]** (lượt `12-chat`)
| Kênh | ChatType | Kết quả |
|---|---|---|
| Thường | 0 | ✅ cả hai nhận `GCChat` (echo của chính mình + của người kia) |
| Tổ đội | 1 | ✅ `GCChat type=1` tới mọi thành viên qua `worldcore:team_chat` |
| Riêng | 3 | ❌ **bị chặn**: `scenecore:check_limit_chat` yêu cầu level > 49; nhân vật test đang level 15 |

Khi bị chặn, server trả `GCScriptCommand m_nCmdID=5` (đường `human:notify_tips`) với nội dung
`e7ad89e7baa7e4b88de8b6b33530e38082` = UTF-8 `"等级不足50。"`. **[LIVE]** Kênh `CHAT_TYPE_SCENE (2)`
và `CHAT_TYPE_CITY (11)` dùng chung cổng chặn này.

## 4. Lỗi tìm được

### 4.1 `caculate_owner_list` không ghi `team_leader` khi chính đội trưởng hạ quái — **ĐÃ VÁ, CHỜ RESTART**
`services/scene/obj/monster.lua:434`. Nhánh `if n:get_guid() == occupant_guid` không kiểm
`n:get_team_info():is_leader()`, chỉ nhánh `elseif team_occipant_guid ~= INVAILD_ID` mới kiểm.
Hệ quả khi đội trưởng là người hạ quái:
- `dispatch_exp` nhận `team_leader == nil` → `exp_mode` luôn đọc là 0 (chế độ chia của tổ đội mất tác dụng);
- `dispatch_good_bad` không chạy → đội trưởng không được cộng thiện ác khi dắt người cấp thấp.

Bằng chứng: lượt `09` (đội trưởng hạ, exp_mode = 1) → 178/178; lượt `11` (đội viên hạ, exp_mode = 1) → 238/119.

Đã vá tại chỗ (ghi `team_leader` trong nhánh chủ sở hữu, có kiểm `get_team_id() == team_occipant_guid`).
**Chưa kiểm tra live vì phiên này bị cấm restart server.** Bản gốc: `Build\Logs\2026-09-17-team-live\monster.lua.bak-2026-09-17-team-live`.

### 4.2 Bán kính chia kinh nghiệm thực tế bị tầm nhìn AOI của **con quái** giới hạn — **CHƯA VÁ**
`caculate_owner_list` gọi `self:get_scene():scan{radious = config_info.Human.CanGetExpRange}` (= **60**,
`configs/ConfigInfo.ini:96`). Nhưng `scenecore:scan` (`scenecore.lua:9611`) chỉ duyệt
`scaner:get_view()` — tức là **chỉ những đối tượng nằm trong tầm nhìn AOI của con quái**.
`define.AOI_RADIS = 20.0` (C module mới là nguồn sự thật, xem chú thích trong `define.lua:2346`).

Đo live: chia được ở 11,6 m (lượt 11), 12,2 m (lượt 09) và 13,5 m (lượt 08); **không** chia ở 17,6 m
(lượt 10, đội trưởng nhận 0, đội viên nhận nguyên 273 như đánh một mình). Nghĩa là cấu hình 60 đơn vị
không bao giờ đạt được.

Đề xuất vá (chưa áp): thay vì chỉ dựa vào `scan`, bổ sung duyệt thẳng danh sách đội của chủ sở hữu
(`occupant:get_team_info():get_scene_member_obj_id(i)`) và lọc theo `CanGetExpRange`. Cần restart để kiểm.

### 4.3 Cổng Đại Lý → Vô Lượng Sơn chọn tuyến NGẪU NHIÊN → tách đôi tổ đội — **KHÔNG SỬA (ngoài phạm vi)**
`Game_2/Script/scripts/event/chuansong/echuansong_dali_wuliang.lua`:
```lua
local dunhuang = {6, 73, 74}
local to_scene_id = dunhuang[math.random(1, #dunhuang)]
```
Hai người cùng đi qua một cổng có 2/3 khả năng rơi vào hai tuyến khác nhau (đo live lượt `04-exp`:
200006 → cảnh 73, 200007 → cảnh 6, cùng lúc, cùng toạ độ, cùng `client_res = 6`). Sau đó không nhìn
thấy nhau, không chia kinh nghiệm, dù vẫn cùng một `team_id`.
`Game_2/Script/**` do agent khác giữ → chỉ báo cáo. Cách đúng của bản gốc là bám theo tuyến của đội trưởng
(hoặc `ai_logic_team_follow` trong `services/scene/ai/human.lua:198`, nhưng chỉ chạy khi đã bật đi theo).

### 4.4 Chuỗi tiếng Trung cứng trong `check_limit_chat` — **KHÔNG SỬA (ngoài phạm vi chat/tổ đội?)**
`scenecore.lua:6080/6099/6105` gọi `obj:notify_tips("等级不足50。")` — chuỗi cứng, không qua
StrDictionary, nên client hiện nguyên tiếng Trung. Ba chỗ.

### 4.5 `GCTeamResult` không mang `leader_guid` ra dây — **GHI NHẬN**
`worldcore` gán `msg.leader_guid` ở `char_leave_team` và `char_start_change_scene`, nhưng `bos` của
gói 648 không ghi trường này. Phía scene (`human:update_team_info`) vẫn dùng được vì nhận bảng Lua,
client thì không. Với `TEAM_RESULT_LEADERLEAVETEAM` client phải tự đôn `members[1]`.

## 5. Cách chạy lại

```powershell
# Hai tiến trình song song, test05 mời - test06 nhận, đo chia kinh nghiệm
Build\Logs\2026-09-17-team-live\run-team.ps1 -Tag "lai" `
  -ArgsA @('--team-invite','CYTest06','--team-at-ms','12000','--team-info','1','--attack','1','--skill','0','--hold-ms','70000','--team-leave','1') `
  -ArgsB @('--team-accept','1','--team-at-ms','30000','--team-wait-ms','40000','--hold-ms','70000') `
  -DwellMs 90000
```
Điều kiện: **hai nhân vật phải ở CÙNG một cảnh và cách chỗ quái chết ≤ ~13 m** (mục 4.2). Cả hai đang
lưu ở cảnh 74 (Vô Lượng Sơn tuyến 3). Nếu bị tách tuyến, đi tới `(32,176)` để về Đại Lý `(280,154)`
rồi đi lại cổng `(304,149)` cho tới khi trùng tuyến (mục 4.3).
