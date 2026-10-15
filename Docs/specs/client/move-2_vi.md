# move-2 — Khinh công (轻功) + bảng phím thật của CY 3.71

Nhánh `move-2`, 18/09/2026. Bằng chứng: `Build/Logs/2026-09-17-move-2/`.
Binary đối chiếu: `C:\TLBB\085\client_GL\Bin64\Game.exe`, sha256 `ce0c4fec7666595ca7adb250fcd8075c28f04d1852d05111c88b730f57e1c763`.
Ký hiệu: **[DK]** đo được / đọc thẳng từ binary hoặc từ server; **[SL]** suy luận, chưa đo.

---

## 1. Vì sao phím tắt hỏng — nguyên nhân gốc, đo được

Câu chuyện này đã bị sửa **hai lần**; đây là bản cuối, có số đo.

**Sự thật 1 — tên widget.** `CYS_AccelAllowed` (bản 17/09) hỏi
`IsIMEEditboxActive("Chat_Frame_EditBox")`. **Không có widget nào tên như vậy trong layout CY.** Ô nhập
chat thật là **`Chat_EditBox`** (`InterfaceFolder/ChatFrame/ChatFrame.layout.xml:289`,
`<Window Type="TLBB_EditBoxInput" Name="Chat_EditBox">`), `ChatFrame.lua` dùng đúng tên đó ở 12 chỗ. [DK]

**Sự thật 2 — nhưng đó KHÔNG phải cái cổng.** `IsIMEEditboxEmpty()` là
`Ime::GetActiveExitBox()->empty()` — `std::list` các ô **đang focus** (`CEGUIIme.h:37`), tức là
*"không ô nhập nào đang nhận chữ"*. Dòng đó mới là cổng thật, và nó **không** hỏng. Hai chỗ dùng tên sai
kia chỉ làm **hai nhánh chết**, và chính hai nhánh đó là hai lỗi người chơi thấy:
Esc không bao giờ vào nhánh "đang chat" (⇒ không đóng ô chat), Tab luôn vào nhánh "không chat"
(⇒ luôn khoá mục tiêu). [DK, review-red đo 18/09]

**Sự thật 3 — cái cổng đó cũng sai, và đây mới là nguyên nhân gốc.** Đo live 18/09
(`Build/Logs/2026-09-17-move-2/live-1`, 267 bước bơm phím thật): `Ime::GetActiveIMEEditBox()` trả
**`Chat_EditBox` ngay từ lúc vào thế giới và không bao giờ trả null**, vì `ChatFrame.lua:536` đặt
`Chat_EditBox:SetProperty("DefaultEditBox","True")`. Kết quả đo:

```
rows fired state A  0        <-- "chưa bấm Enter, đáng lẽ không có ô nào focus"
rows fired state B  42
keys left to the edit box: 38 distinct (72 events)
Chat_EditBox="1234567890ccaassqqfftteexxoodd--hzvvjmmw,,..rrikbbppl``1234567890"
```

**0/38 phím chữ kích hoạt được phím tắt**; mọi chữ rơi vào ô chat. Suy ra cho bản CŨ:
`IsIMEEditboxEmpty()` **luôn FALSE** ⇒ bản cũ **chặn sạch mọi phím tắt** trừ khi giữ Alt. [DK]

**CY không dùng danh sách focus.** Bộ truy cập `0x140434650` hỏi
`UISystem->GetVariable("NonChatActive") == 1` — một **biến**, và **7 khung CY đọc đúng biến đó**
(`ChatFrame.lua:534`, `LargeMap:317`, `MainMenuBar:1686`, `MiniMap:1190`, `SceneMap:465/1001`,
`TeamFrame:2825`); hàm đặt là `SystemSetup:Lua_SetNonChatActive` (CY `Game.exe +0x32e710`). [DK]

**Sự thật 4 — ô nhập chat cũng HIỆN vĩnh viễn, và tầng UI gõ chữ bất kể tầng game làm gì.**
Lượt `live-2` (binary đã sửa) ra **y hệt** `live-1`: `rows fired state A = 0`, log nói cổng rơi xuống
nhánh "Chat_EditBox visibility" ⇒ cả focus lẫn hiển thị đều luôn đúng, **không tín hiệu UI nào phân
biệt được**. Và `CUISystem::InjectInput` chạy **trước** bộ xử lý phím của game, trong đó nhánh bàn phím
là **khối `if` RỖNG** (`UISystem.cpp`, "对于未加Handle的Keybord Event") ⇒ sự kiện phím **không bao giờ**
được đánh dấu `bProcessed`. Nghĩa là CEGUI gõ chữ vào ô chat **và** sự kiện vẫn tới bảng phím. [DK]

**Sự thật 5 — hai đường phím độc lập, và đó là toàn bộ lời giải.** Chữ **không** đi vào ô chat qua
`CUISystem::InjectInput` (hàm đó không có `case` bàn phím nào, `default: continue`). Nó đi qua
**`CUISystem::MessageProc` → `Ime::ImeMsgProc` → `injectChar`**, tức **đường thông điệp Windows**, hoàn
toàn tách khỏi hàng đợi DirectInput mà tầng game đọc. Vì vậy một lần bấm phím làm **hai** việc, và không
tầng nào "nuốt" được của tầng kia. [DK]

⇒ **Bản sửa trọn vẹn = hai nửa, cùng đọc một biến:**

| nửa | file | làm gì |
|---|---|---|
| tầng game | `Procedure\CysAccelTable.cpp` | ghi `NonChatActive` (Enter đặt, Esc xoá — đúng hai callback CY `0x140439c00`/`0x140438300`) và dùng nó làm cổng nuốt |
| tầng UI | `CEGUISystem\UISystem.cpp` `CUISystem::MessageProc` | khi `NonChatActive == 1` **và** ô đang nhận là `Chat_EditBox`, **không** chuyển `WM_CHAR`/`WM_KEYDOWN`/`WM_IME_*` cho `Ime::ImeMsgProc` |

Tầng UI đọc được biến vì `UI_CEGUI.dll` có sẵn `g_pVariableSystem` (cùng nút `bin\var` mà tầng game ghi,
`UISystem.cpp:346`) — không cần export mới. Guard chỉ nổ cho **`Chat_EditBox`**; 344 ô nhập còn lại của
GUI CY không bị đụng. `CYS_ACCEL_CHATGATE=uifocus` quay lại hành vi thủ cũ mà không phải dựng lại.

**Tổng số ô nhập trong layout CY: 345**; chỉ `Chat_EditBox` là ô mặc định vĩnh viễn, 344 ô còn lại hành xử
bình thường nên vẫn hỏi bằng danh sách focus.

---

## 2. CY 3.71 phân phối phím thế nào (đọc từ binary)

| thứ | địa chỉ | nội dung |
|---|---|---|
| bảng | `.data 0x140998980` | 79 mục × `0x30` byte |
| bố cục mục | | `+0x00 u32 id` · `+0x08 char* khoá StrDictionary` · `+0x10 u32 key1` · `+0x14 u32 key2` · `+0x18 fn_down` · `+0x20 fn_up` · `+0x28 u32 flags` |
| phân phối | `0x140433ea0` `CAccelerateManager::processKeyMessage` | |
| tra text-key | `0x1404352a0` | tập phím "thuộc về ô nhập" |
| tra hợp lệ khi đổi phím | `0x1404357e0` | hai danh sách: dùng khi chat / dùng khi không chat |
| bắt phím mới | `0x140437050` | |
| xoá phím trùng | `0x140435b80` | |
| đổi phím thành chữ | `0x140435eb0` | |
| ghi tệp | `0x140434880` | |
| đọc tệp | `0x140435420` | |
| tên tệp | `0x140408b64` | `"..\Accounts\%s\Acce_Custom.ini"` |

**Khoá phím đóng gói trong một u32**: `vk | Ctrl<<16 | Alt<<17 | Shift<<18`. [DK]
`processKeyMessage` đặt bit bằng `GetKeyState(VK_CONTROL) → bts 0x10`, `VK_MENU → bts 0x11`,
`VK_SHIFT → bts 0x12`; `KeyText` in `0x40000 → "Shift+"`, `0x20000 → "Alt+"`, `0x10000 → "Ctrl+"`.

> **SỬA MỘT SAI SÓT CỦA 17/09**: chú thích trong `CysHost_Accel_Table.inc` ghi *"mod bits: 1 Shift, 2 Alt,
> 4 Ctrl"* — **đảo Shift và Ctrl**. Đúng phải là **1 = Ctrl, 2 = Alt, 4 = Shift**. Các con số trong bảng
> thì đúng, chỉ chú thích sai; hậu quả là ba hàng 31/32/33 bị đọc thành `Shift+1/2/3` trong khi CY ghi
> **`Ctrl+1/2/3`**, và hai hàng 4/5 bị đọc thành `Shift+Alt+,` thay vì `Ctrl+Alt+,`. [DK]

**Luật phân phối** (khác hẳn switch cũ): [DK]

1. **Cả hai binding của mọi hàng đều sống cùng lúc.** Không có chuyện "key2 chỉ dùng khi đang chat".
   `J` và `Alt+J` đều nhảy, mọi lúc.
2. Khi **có ô nhập đang nhận chữ**: phím **không kèm Ctrl/Alt** mà nằm trong tập text-key
   (`A..Z`, `0..9`, numpad, `← →`, `Home`, `End`, `Delete`, `Enter`, dấu câu) được **nhường cho ô nhập**.
   Mọi tổ hợp có Ctrl/Alt vẫn chạy.
3. **Phân phối cả key-down lẫn key-up** (`fn_down` / `fn_up`). F1–F10 có `fn_up` — CY *chuẩn bị* khi
   nhấn và *thi hành* khi nhả.
4. Nhân vật **chết** chỉ kích hoạt được hàng có `flags & 0x100`: Esc, Enter, Tab, F11, ba phím khoá,
   PrintScreen, `Ctrl+G`, `Ctrl+\``.
5. Auto-repeat của bàn phím bị bỏ qua.

**Đổi phím** (màn hình `AcceSetup`): Esc huỷ; phím thuộc danh sách "chat" (`Alt+A..Z`, `Alt/Ctrl+0..9`,
`F1..F12`, `Alt+Delete`, `Ctrl+Tab`, `Alt+dấu câu`) vào **binding 2**; phím thuộc danh sách "thường"
(`A..Z`, `0..9`, `Ctrl+0..9`, `F1..F12`, `Delete`, `Tab`, dấu câu) vào **binding 1**; ngoài hai danh sách
⇒ từ chối bằng `ZDYKJJ_20071227_02`. Phím trùng bị **xoá khỏi hàng cũ** kèm `ZDYKJJ_20071227_03`. [DK]

**Một nét lạ của CY được giữ nguyên**: `KeyText` chỉ in **một** tiền tố, ưu tiên Shift → Alt → Ctrl
(sau tiền tố đầu tiên nó nhảy thẳng tới tên phím). Nên `Ctrl+Alt+,` của hàng 4 hiện ra là **`Alt+,`**.
Giữ vì luật 14/09 "mọi thứ như CY"; hàm có cờ `cyQuirk=false` cho log/test in đầy đủ. [DK]

---

## 3. Đã làm gì

### 3.1. Bảng thay cho switch

| tệp | vai trò |
|---|---|
| `Src/Client/WXClient/Procedure/CysAccelCore.h` | **MỚI** — lõi không phụ thuộc engine: 79 hàng, đóng gói/giải mã phím, DIK→VK, hai danh sách hợp lệ, xoá trùng, đọc/ghi `Acce_Custom.ini`, `KeyText` |
| `Src/Client/WXClient/Procedure/CysAccelTable.h/.cpp` | **MỚI** — phân phối thật, bắt phím, cầu nối `UI_CEGUI.dll`, API cho `AcceSetup` |
| `Src/Client/WXClient/Procedure/GamePro_Main.cpp` | switch ~470 dòng → vòng lặp 25 dòng gọi `CysAccel::ProcessKey` |

`ProcessInput_Keybord` mới chỉ còn: bỏ qua sự kiện đã xử lý → `AllowGameHotKey` (cổng UI có sẵn) →
`CysAccel::ProcessKey(kIndex, down)`. Cổng chết, cổng ô nhập, bắt phím và hành động đều nằm trong bảng.

**`KC_PGUP` / `KC_PGDOWN` đã bỏ** (quyết định đã chốt): không xuất hiện trong bất kỳ hàng nào của 79 hàng CY.
Nhảy chỉ còn `J` / `Alt+J`. [DK]

### 3.2. 15 phím CY có mà bản cũ thiếu — nay có

| hàng | phím | CY làm gì | bản này |
|---|---|---|---|
| 0 | `Esc` | đóng chat / `OnPushEcsape` + huỷ lệnh chuột | **có** |
| 1 | `Enter` | mở ô chat | **có** |
| 4/5 | `Ctrl+Alt+,` `.` | cuộn lịch sử lệnh GM | **có** |
| 47 | `H` | `GotoAnchorHelp("")` | **có** |
| 55/56 | `Alt+↑` `Alt+↓` | zoom camera | **có** |
| 57 | `Tab` | **mở/đóng bản đồ lớn** (`TOGLE_SCENE_MAP`) | **có** |
| 59 | `R` | `MINMAP_PLAYERLIST_SHOW` | **có** |
| 61 | `K` | gửi `CGStopTeamFollow` (1263) | **có** |
| 62 | `B` | `TOGGLE_WUHUN_PAGE(-1)` | **có** |
| 63 | `P` | `OPEN_XIULIAN_PAGE(-1)`, chỉ từ **cấp 70** | **có** |
| 65/66 | `↑` `↓` | đang chat: cuộn lịch sử; không chat: zoom | **có** |
| 67 | `` ` `` | `OPEN_AUTOSEARCH` | **có** |
| 69 | `Alt` | `UPDATE_SUPERTOOLTIP` altkeydown/altkeyup + `SHOW_SUPERTOOLTIP2` | **có** |
| 21–30 | `1`–`0` / `Alt+1`–`Alt+0` | ô 30–39 của thanh công cụ | **có** |
| 70–78 | (trống ở CY) | ô 70–78 | **có** (bản này chỉ 20 ô ⇒ ghi log, không làm gì) |

`Shift+1/2/3` **không tồn tại**: CY dùng **`Ctrl+1/2/3`** cho `acc_MainMenuBarPageOne/Two/Three`
(hàng 31/32/33, key `0x31 mod 1`). Bản 17/09 gắn nhầm vào `Shift` vì chú thích bit bị đảo. [DK]

Tên sự kiện CY lấy được bằng cách quét bảng đăng ký sự kiện của CY (`0x1406c9c08` và lân cận,
`mov [rip+X], <id>` đi liền `lea rax, [rip+Y]` trỏ tên): **1.639 cặp id→tên**, trong đó
`0x69 = ACCELERATE_KEYSEND`, `0x85 = NEW_DEBUGMESSAGE`, `0xcd = TOGLE_INPUTSETUP`,
`0x1a5 = OPEN_AUTOSEARCH`, `0x22b = MINMAP_PLAYERLIST_SHOW`, `0x27c = TOGGLE_WUHUN_PAGE`,
`0x286 = OPEN_XIULIAN_PAGE`, `0x312 = TRIGGER_ZIDONGZHANDOU`, `0x135 = UPDATE_SUPERTOOLTIP`,
`0x12f = SHOW_SUPERTOOLTIP2`. Bảng đầy đủ: `scratchpad/m2/cy_events_all.json`. [DK]

**5 hàng CY có mà bản này chưa làm được** — ghi log `not ported`, không đoán bừa:
F12 (cờ thế giới `+0x41`), `Ctrl+Tab` (làm tươi thế giới có tiết lưu), `Z` (`InfoBrowser`),
`W` (một singleton `0x1409b7900`), `I` và `L` (tự động chiến đấu — cần trạng thái mà bản này chưa có),
F11 (ẩn/hiện toàn bộ UI — engine này không có API).

### 3.3. Khinh công

| tệp | vai trò |
|---|---|
| `Src/Client/WXClient/Network/CysLeapNet.h/.cpp` | **MỚI** — `CGCharFly` (1225) / `GCCharFly` (1262), `CCharacterData::GetDefaultFlySkillID` |
| `Src/Client/WXClient/Object/Character/Obj_Character_Leap.cpp` | **MỚI** — cung bay nhìn thấy được |
| `GMAI_MySelf.h/.cpp` | `PushCommand_Fly`, `IsCanFly`, khoá 500 ms ở `PushCommand_Jump` |
| `GMAI_Base.h` | khe ảo `PushCommand_Fly` (CY vtable slot 6, ngay sau `PushCommand_Jump`) |
| `CursorMng.cpp` | thân `MCT_LEAP` (trước đây bị chú thích toàn bộ) |
| `GMDP_CharacterData.h` | khai báo `GetDefaultFlySkillID` |
| `CysModernHandlers.cpp` | 2 dòng `CYS-MOVE2` nối `GCCharFly` vào bộ phân phối |

**`CAI_MySelf::PushCommand_Fly` = `0x140118600`**, dịch từng bước: [DK]

1. `[this+0xa4] != 0` ⇒ trả 0 — **đây chính là khoá 500 ms**;
2. `skillId == -1` ⇒ 0;
3. tra kỹ năng qua `FUN_1401addb0(charData, skillId)`, không có define ⇒ 0;
4. `vtable slot 16` (`0x14011a070`) = `IsCanFly` ⇒ 0;
5. kẹp đích về `tầm × 0.9` (hằng float `0x14070906c` = 0.9; tầm = `m_fMaxAttackRange`);
6. đích phải tới được: `IsPointInUnreachRegion` **và** đường thẳng đúng **một** đoạn
   (`GetPathDirect` → `GetUnitNum() == 1`);
7. dừng AI (slot 9) → gửi `CGCharFly` → `[0xa4] = 500` (`0x1f4`), `[0xa8] = now`, `[0x10] = 0xFFFF`.

**Khoá 500 ms cũng là cổng đầu tiên của `PushCommand_Jump`** (`0x140118550`): khi khoá còn chạy,
CY in `StrDictionary "GMAI_MySelf_1"` (chuỗi tại `0x14070d940`) — bản Việt: *"Ngươi hiện đang rất bận"*.
Bản này dùng lại `m_uForbidTime` sẵn có (`USE_SKILL_FORBID_TIME` = 500 ms), nên không thêm biến mới. [DK]

`IsCanFly` (`0x14011a070`) từ chối khi: chết, đang trong chiêu, bị hạn chế di chuyển, đang bày sạp,
đang theo tổ đội, đang nhảy, đang bay; thông báo chung là `GMAI_MySelf_22`. [DK]

**`GetDefaultFlySkillID`**: CY khoá theo bảng `0x1407132c8` (13 ô, kỹ năng **5271..5285**), nhưng đó là
**không gian ID của CY**, không phải của server này. Server dùng `define.QINGGONG_SKILL`
(`lualib/define.lua:296`): thiếu lâm 23 … tiêu dao 31, Mộ Dung 110, Ác Nhân Cốc 4648, và **34 luôn được
chấp nhận cho mọi phái** (`scenecore:is_qinggong_skill` trả true cho 34). Hàm chọn: kỹ năng của phái nếu
đã học → kỹ năng khinh công bất kỳ đã học → 34 → -1. [DK]

**Cung bay** (`Obj_Character_Leap.cpp`): parabol `lift = 4·h·t·(1−t)`, cộng vào `GetGroundLift()` —
cùng cơ chế `ride-core` dùng cho thú bay, nên `CObject_Phy::SetMapPosition` nâng cả chân lẫn camera.
Thời lượng = `SendTime` của kỹ năng (**1200 ms** cho mọi hàng khinh công). [DK]
Hoạt cảnh lấy từ `ActionSetKV.txt`: **393 `轻功起飞`** (cất cánh), **394 `轻功空中`** (trên không),
**395 `轻功落地`** (tiếp đất); biến thể theo phái `814/815/816` (`轻功1a/b/c`) … `1128/1129/1130`
(`轻功9a/b/c`). [DK]

> **BẪY DỮ LIỆU**: cột `SendActSet` của các hàng khinh công 23–31 ghi `"411;412;413"`, nhưng trong bộ dữ
> liệu này `ActionSetKV` 411/412/413 là **`慕容博秘籍_dl` / `慕容博怒火连斩` / `慕容博横扫乾坤`** — chiêu
> của boss Mộ Dung Bác, không phải khinh công. Dùng cột đó sẽ ra hoạt cảnh sai. Vì thế mã **không** đọc
> `SendActSet` mà tra thẳng `393/394/395` + biến thể phái. [DK]

Độ cao cung (`0.25 × cự ly`, kẹp `[1.5, 4.0]`) và cách chọn biến thể theo phái (`N = menpai + 1`) là **[SL]**.

---

## 4. Số đo thật

### 4.1. Lõi bảng phím — 30 phép kiểm, độc lập engine

`scratchpad/m2/accel_core_test.cpp` + `run_core_test.cmd` → **PASS core (0 failures)**.
Kiểm: chữ của CY cho 6 hàng mẫu (kể cả nét lạ một-tiền-tố), cả hai binding đều tìm thấy hàng,
`Ctrl+Alt` (AltGr) không trúng hàng nào, **PgUp/PgDn không trúng hàng nào**, `Alt+Tab` không trúng
hàng nào, tập text-key, DIK→VK, hai danh sách đổi phím, xoá trùng, vòng đọc–ghi tệp `Acce_Custom.ini`,
`Revert`, ánh xạ id→hàng, cờ "dùng được khi chết".

### 4.2. Khinh công trên server thật — 3 lượt bot thuần (không cần khe `Game.exe`)

Tài khoản test11 / CYTest11 (GUID 200012, phái 9, cấp 15, cảnh 2, `skill_list` có 34).
Bằng chứng: `Build/Logs/2026-09-17-move-2/bot-fly-*/core-loop.tsv`.

| lượt | gửi | server trả |
|---|---|---|
| `bot-fly-1-ok-8u` | `CGCharFly skill=34 from=160,150 to=168,150 dist=8.00` | **`GCCharFly obj=200 (self) logic=4 skill=34 from=160.0,150.0 to=168.0,150.0 to2=168.0,150.0 u4=0 u5=4.00`** sau **30 ms** |
| `bot-fly-2-far-30u` | `... to=190,150 dist=30.00` | không có `GCCharFly`; `GCScriptCommand cmd=5` = `e8b685e587bae8b79de7a6bb` = **`超出距离`** |
| `bot-fly-3-badskill-99` | `... skill=99 dist=5.00` | không có `GCCharFly`; `GCScriptCommand cmd=5` = `e4b88de883bde4bdbfe794a8e8afa5e68a80e883bd` = **`不能使用该技能`** |

Ba kết quả khớp từng dòng `scenecore:char_fly` (`scenecore.lua:6146`). Hai đường từ chối chỉ trả
**tip**, không có mã lỗi — nên client phải tự gác trước khi gửi, đúng như CY làm. [DK]

**Phát hiện sửa một giả định sai của chính tôi**: `from` trên dây là **vị trí TRƯỚC khi bay**
(160,150), không phải đích. Nhưng handler của CY (`0x140395860`) **không đọc `from`** — nó chỉ lấy
`logic_count (+0x1c)`, `skill (+0x20)`, `to (+0x2c/0x30)`, `to2 (+0x34/0x38)` rồi đẩy lệnh 202.
Vị trí bắt đầu nhìn thấy luôn là vị trí client của chính đối tượng. Bản này làm y hệt. [DK]

Mở rộng bot: `--fly X,Z[,SKILL]` (`Src/Tools/CysNetBot/main.cpp`, thẻ `CYS-MOVE2`) — gửi một
`CGCharFly` 1,5 s sau setup rồi ở lại 6,5 s để bắt `GCCharFly`/tip.

### 4.3. Tab — bác một tiền đề nằm sẵn trong mã

Dịch ngược trọn callback hàng 57 (`0x140438840`) từ đầu đến `ret`: toàn bộ thân hàm chỉ dựng
`vector<STRING>{szSceneMap, "2"}` rồi `PushEvent(0x78 = TOGLE_SCENE_MAP)` và bật hai cờ làm tươi minimap
(`0x1409c13c0`, `0x1409c13c1` — đúng `m_bNeedFreshMinimap` / `m_bWaitNeedFreshMinimap` của 0.85).
**Không có lời gọi nào khoá mục tiêu.** Chú thích `CYS-SKILL` cũ trong `GamePro_Main.cpp`
("CY binds Tab to select the nearest enemy") **sai**; hàng 57 nay là `ACT_SCENE_MAP`. [DK]

### 4.4. Phiên live 79 phím

`Build/Logs/2026-09-17-move-2/live-1/`: 267 bước bơm phím/chuột thật, 36 ảnh, 502 dòng `CYS-ACCEL`,
`report_keys.py` tổng hợp thành `keys-79.tsv`. **42 hàng kích hoạt được**, bộ đếm cuối
`seen=368 dispatched=140 edit=139 unbound=51 dead=0 captured=0 notported=5`.
Kết quả chính của lượt này là phát hiện ở mục 1 (sự thật 3) — nó làm chính phép đo "trạng thái A" vô
nghĩa, nên phải chạy lại sau khi sửa cổng. Khinh công trong GUI **chưa đo được** (0 dòng `CYS-MOVE2`:
Ctrl+click chưa kích hoạt `MCT_LEAP`); đường mạng đã chứng minh xong bằng bot ở mục 4.2.

### 4.6. Chiều thứ nhất của phép đối chứng — phím chữ trơn chạy được lần đầu

`live-4` (cả hai nửa bản sửa): **`rows fired state A = 34`** (live-1/live-2: **0**),
**`keys left to the edit box: 0`**, ô chat **trống**, bộ đếm `edit=0`, và log xác nhận
`chat swallow gate = NonChatActive (CY rule; UI half in CUISystem::MessageProc)`.
`C`/`A`/`S` kích hoạt `acc_selfequip`/`acc_packet`/`acc_skill` trên **slot 1** (binding phím trơn). [DK]

### 4.6b. Chiều thứ hai — đã đủ, phép đối chứng khép kín [DK]

`live-5` (`plan_ab.txt`, test11, 20 ảnh). Nhật ký theo đúng thứ tự, **kèm số khe binding**:

```
NonChatActive=1 (keyboard belongs to the game)
down C     row=36 slot=1 acc_selfequip      chưa gõ chat: phím trơn CHẠY
down Enter row=1        -> NonChatActive=0 (typing in the chat box)
C / A / S  left to edit box "Chat_EditBox"  đang gõ: phím trơn KHÔNG chạy...
   Chat_EditBox="cc" -> "cca" -> "ccas"     ...mà vào ô chat
down Alt+C row=36 slot=2 acc_selfequip      đang gõ: Alt+<phím> VẪN chạy (khe 2)
down Esc   row=0        -> NonChatActive=1 (keyboard belongs to the game)
down C     row=36 slot=1 acc_selfequip      thoát chat: phím trơn chạy lại
```

`slot=1` / `slot=2` chứng minh dùng đúng binding nào. Đây là hành vi CY, **cả hai chiều**.

**Một ký tự lọt ở phím ĐẦU TIÊN của phiên** — ô chat đọc `"cc"` sau **một** lần gõ `c`. Biến
`NonChatActive` trước đây công bố **lười**, ngay trong lần gọi `ChatEditActive()` của chính phím đầu
(nhật ký: công bố dòng 435, phím `C` đầu dòng 438), nhưng `WM_CHAR` của phím đó đi qua window proc **sớm
hơn trong cùng khung hình** so với `CInputSystem::Tick` ⇒ guard đọc "chưa có biến" và cho lọt. Đúng một
ký tự, một lần mỗi phiên. **Đã sửa**: công bố ngay trong `CGamePro_Main::Init()`; chờ một lượt xác nhận.

### 4.7. Bật được phím chữ làm lộ một lỗi có sẵn

`live-4` kết thúc ở giây 97 **ngay tại** `Q → acc_quest`: khung Mission của CY gọi bốn hàm host còn thiếu
(`DataPool:GetPlayerMission_DelActivePos/ForePart/ActivePos`,
`MetaTable_Control_Window:ResetScrollPosition`) rồi tiến trình kết thúc — không exception, không assert,
không dump, và `Esc` chưa hề được bấm (`row=0` không xuất hiện lần nào). **Lỗ hổng có sẵn của khung
Mission**, không phải của bảng phím: trước đây phím chữ trơn chưa bao giờ chạy nên chưa ai mở được khung
đó bằng phím. [DK]

### 4.5. Biên dịch

`Tools\build\build.cmd x64 move-2-x64` — `cys_wxclient` **rc = 0**, `cys_netbot` **rc = 0**,
**0 cảnh báo mới** trong các tệp của nhánh. Nhật ký: `Build/Logs/2026-09-17-move-2/build/`.

---

## 5. Bẫy

1. **`Chat_Frame_EditBox` không tồn tại** — xem mục 1. Bất kỳ ai gác phím theo tên ô nhập đều phải dùng
   `Chat_EditBox`, hoặc tốt hơn là hỏi "có ô nào đang nhận chữ không".
2. **Chú thích bit modifier của `CysHost_Accel_Table.inc` đảo Shift↔Ctrl.** Con số đúng, chữ sai.
   Ai đọc chú thích mà không đọc binary sẽ gắn `Shift+1` thay cho `Ctrl+1`.
3. **`MOD_ALT` / `MOD_SHIFT` là macro của `winuser.h`** (`RegisterHotKey`). Đặt trùng tên trong enum
   làm trình dịch nổ ở chỗ chẳng liên quan (`missing '}' before constant`). Tên trong lõi là
   `kModCtrl/kModAlt/kModShift`.
4. **`ROWS` cũng đụng** với một macro khác trong cây → `kRows`.
5. **`GMInterface_Script_Talk.h` không có include guard.** Include nó sau `GMGameInterface_Script.h`
   ⇒ 15 lỗi "redefinition". Chỉ include cái thứ hai.
6. **`CActionSystem::s_MainMenuBarNum` là `protected`** — không đọc được từ ngoài; hằng 20 phải chép tay.
7. **Cột `SendActSet` của kỹ năng khinh công trỏ nhầm sang chiêu boss** — xem mục 3.3.
8. **Bot `--out` phải là đường dẫn TƯƠNG ĐỐI dưới `Build/Logs`**; đường tuyệt đối bị từ chối
   ("output must be relative below Build/Logs") và lượt chạy hỏng im lặng nếu không đọc `result.json`.
9. **`connection refused` của bot = server đang restart**, không phải lỗi mã. `result.json` ghi
   `exit_code 4`, `charlogin: not_requested`, tệp sự kiện rỗng.
10. **`u5 = 4.00` trong `GCCharFly`** là giá trị mặc định của ctor Lua (`packet.lua`), không phải dữ liệu
    thật — đừng suy ra tốc độ/độ cao từ nó.

---

## 6. Chưa xong / cần phối hợp

- **Tầng Lua của màn hình đổi phím** (`Src/Client/LuaApiGen/CysHost_Accel.cpp`) do **host-2** giữ.
  Tệp **có** được biên dịch (`wxclient.cmake:543` glob `Client/LuaApiGen/*.cpp`) — giả thuyết
  "chưa vào cmake" là **sai**. Hiện nó đọc bảng **tĩnh** `CysHost_Accel_Table.inc`, nên đổi phím vẫn
  chưa hiện ra. Bản vá đúng (6 dòng, không đổi hành vi nào khác):

  | hàm Lua | gọi vào |
  |---|---|
  | `SystemSetup:GetInputSetup(i)` | `CysAccel::RowText(i, k1, 48, k2, 48)` |
  | `SystemSetup:InputSetup_OnOff(a, b, id)` | `CysAccel::BeginCapture(id, b != 0)` |
  | `SystemSetup:ComeBackAcce()` | `CysAccel::RestoreDefaults()` |
  | `SystemSetup:SaveCurAcceCustom()` | `CysAccel::Snapshot()` |
  | `SystemSetup:RevertAcceCustom()` | `CysAccel::Revert()` |
  | `SystemSetup:UseAcceCustomKey()` | `CysAccel::Commit()` |
  | `SystemSetup:GetIsConfigChanged()` / `SetIsConfigChanged(n)` | `CysAccel::IsChanged()` / `SetChanged(n != 0)` |

  `AcceSetup.lua` còn gọi `SystemSetup:InputSetupSwitch` (dòng 369) — chưa dịch ngược, chưa cần.
- **Độ cao cung bay** vẫn là [SL]. Chốt được bằng một lượt CY oracle có server trả `GCCharFly` cho
  chính nhân vật (`cy_oracle_server.py` hiện chưa phát gói này).
