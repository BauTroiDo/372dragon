# host-plumbing — ống nước dùng chung của lớp hàm host (17/09/2026)


Quy ước: **[DK]** dữ kiện đo/đọc được (có đường dẫn, offset hoặc số). **[SL]** suy luận. Không chắc thì ghi "chưa kết luận được".

---

## 0. Trả lời ngắn

**Bốn hàm mà bản giao việc gọi là "nặng nhất" (`ScriptGlobal_Format` 999 khung, `PushEvent` 821, `SetText` 601,
`SetProperty` 547) ĐỀU ĐÃ LÀ HÀM THẬT rồi.** Phép đếm tĩnh của `power-attrib` xếp nhầm chúng vào nhóm stub.

| Hàm | Bản thật nằm ở | |
|---|---|---|
| `ScriptGlobal_Format` | `Src\Client\LuaApiGen\CysHostGlobals.cpp:279` (`LuaFormat`) | [DK] |
| `PushEvent` | `CysHostGlobals.cpp:280` (`LuaPushEvent`) | [DK] |
| `SetText` | `Src\Client\CEGUISystem\UILuaControl.cpp:219` → `Window::setText` | [DK] |
| `SetProperty` | `UILuaControl.cpp:213` → `Window::setProperty` | [DK] |

Phép kiểm rẻ nhất chứng minh điều đó: **bốn phiên chơi thật trong lượt này không ghi một dòng
`missing host function` nào cho bốn hàm đó.** `LuaApiGen` chỉ đăng ký stub khi `IsMissing()`, nên hàm nào có bản
thật thì stub không bao giờ chạy và không bao giờ ghi log. ⇒ **Không có gì để làm ở bốn hàm đó.**



**Đo A/B có đối chứng đã chứng minh cả 6 (mục 5):** cùng một kịch bản, cùng tài khoản, chỉ khác binary —
đúng 5 dòng `missing host function` biến mất, 0 dòng hồi quy, và **2 dòng mới xuất hiện đều là khung
được MỞ KHOÁ nhờ bản sửa**, không phải lỗi.


---

### 1.1 Nguồn số

`Build\world-gui\stage-fps-daiviet\Bin64\WXClient.log`, phiên **17/09 14:05:43 → 14:10:41** (người dùng chơi thật:
đăng nhập, vào thế giới `scene=2`, 69 bước di chuyển, thoát bằng `CGAskQuit`). Dòng cuối của phiên:

```
[17_14:10:35]: LuaApiGen: 3739 calls to 114 missing host functions this session
```

`Stub()` (`LuaApiGen_Common.cpp:110`) ghi **một** dòng `missing host function <Receiver>:<Name>` cho lần gọi đầu và
đếm mọi lần gọi; `CGameProcedure` đổ bảng đếm mỗi 5 giây và lúc thoát, **giới hạn 20 dòng**
(`GameProcedure.cpp:799/907/1040/1059`). Vì vậy tôi lấy **hợp của mọi lần đổ bảng, giữ số lớn nhất cho mỗi hàm**
(`scripts\10-rank.py`): 37/114 hàm từng lọt top-20 nên có số lời gọi thật; 77 hàm còn lại chỉ biết "≥ 1".

`score = số khung gọi × max(số lời gọi, 1)`. "Khung" = một thư mục dưới
`Assets\CanonicalCY\Data\InterfaceFolder` (quét 2.043 file `.lua`, đọc GBK).

### 1.3 Hai mươi dòng đầu

`scripts\12-rank-implva.py` → `measure\rank-implva.tsv` (đủ 114 dòng). `<=10` = có gọi nhưng chưa bao giờ lọt top-20.

|---:|---:|---:|---:|---|---|---|
| 1 | 38251 | 1319 | 29 | `DataPool:LuaFnGetGMVisibleType` | — | [SL] chỉ-CY — **bỏ**, 3.1 |
| 4 | 4114 | 187 | 22 | `_G:IsZbs2018SpeicalServer` | — | [SL] chỉ-CY — bỏ |
| 5 | 3914 | 38 | **103** | `SystemSetup:IsClassic` | — | [SL] chỉ-CY — bỏ, 3.1 |
| 11 | 176 | 16 | 11 | `MetaTable_Control_Window:AddTextCatalogTextAndImage` | — | [SL] chỉ-CY |
| 12 | 156 | 52 | 3 | `DataPool:GetGroupingNameByIndex` | — | [SL] chỉ-CY |
| 13 | 154 | 14 | 11 | `MetaTable_Control_Window:SetCatalogButtonSelect` | — | [SL] chỉ-CY |
| 18 | 78 | ≤10 | 78 | `KaJi:LuaFnIsKaJiServer` | — | [SL] chỉ-CY |
| 19 | 60 | 5 | 12 | `MetaTable_Control_Window:AddTextTextAndImage` | — | [SL] chỉ-CY |
| 20 | 60 | 5 | 12 | `MetaTable_Control_Window:SetTextCatalogSelected` | — | [SL] chỉ-CY |


### 1.4 Đếm số khung cho ĐÚNG receiver (bẫy `host-power` chuyển sang) [DK]

`host-power` báo bẫy: regex của họ thiếu `\s*` sau dấu hai chấm nên `this : GetChildOffset(` bị đọc thành lời gọi
toàn cục. Bảng xếp hạng của tôi **không dính bẫy đó** (tập hàm lấy từ log chạy thật, có sẵn `Receiver:Name`;
`impl_085` cũng không dùng để quyết định "thật hay giả"), nhưng **cột "số khung" thì có**: nó đếm mọi lần cái tên
xuất hiện, bất kể receiver. Đếm lại có phân biệt receiver, cho phép khoảng trắng hai bên `:` và `.`
(`scripts\13-frames-recv.py`):

| Hàm | khung (đếm thô) | **khung (đúng receiver)** | receiver thật |
|---|---:|---:|---|
| `Player:GetLevel` | 189 | **183** | `Player`=661 lời gọi, `Pet`=10, `Target`=6, `TargetPet`=5 |
| `DataPool:GetServerDayTime` | 178 | **176** | `DataPool`=381, `BudgetPlanGem`=5 |
| `_G:GetCurClientSize` | 15 | **15** | lời gọi toàn cục thuần |
| `ComboBox:AddTextItem` | 75 | **75** | tên biến widget |
| `Player:IsVaild` | 2 | **2** | `Player`=2 |

Bẫy thứ hai của `host-power` (phép đếm stub không nhìn `Src\Client\WXClient\Network\Cys*Net.cpp`) **không ảnh
hưởng lượt này**: tập "thật hay giả" của tôi lấy từ **log chạy thật** — hàm thật không bao giờ ghi
`missing host function`, nên không thể đếm nhầm theo chiều nào.

---

## 2. SÁU HÀM ĐÃ CÀI — hành vi lấy từ mã gốc

Mã: `Src\Client\LuaApiGen\CysHost_Plumbing.{h,cpp}` (**file mới, của nhánh này**), ba móc nhỏ có thẻ `// CYS-PLUMB`
ở `Src\Client\WXClient\Procedure\GameProcedure.cpp`, hai móc nhỏ ở `Src\Client\CEGUISystem\UILuaControl.cpp`.
Đăng ký **trước** `LuaApiGen::RegisterAll`, nên `IsMissing()` giữ stub ở ngoài.

### 2.1 `MetaTable_Control_ComboBox:AddTextItem` — 75 khung [DK]


```
lua_isstring(L, 2)            -> không phải chuỗi/số thì return 0
LuaStackObject::GetString(2)  -> std::string
String32::ctor + hàm đổi mã (cờ byte ở window+0x308)
operator new(0x198)           -> CEGUI::ListboxTextItem   (rtti_classes của catalog xác nhận)
lua_tonumber(L, 3)            -> id của item
ListboxTextItem::ctor(text, id) ; ColourRect lấy từ window+0x404 ; Combobox::addItem
```

⇒ **Cùng một hàm với `ComboBox::ComboBoxAddItem` của 0.85** (`UILuaControl.cpp:1734`), CY chỉ đổi tên. Bản cài =
đăng ký thêm tên `AddTextItem` trỏ vào chính hàm đó (một dòng, cạnh dòng đăng ký cũ).

**Một khác biệt thật, đã sửa:** bản gốc gác bằng `lua_isstring`, **chấp nhận cả số**; 0.85 gác bằng
`args[2].IsString()` (`LUA_TSTRING` thuần) nên **lặng lẽ không thêm gì** khi caption là số —
`BangHuiFuLi.lua:62` `SetHour:AddTextItem( i+7, i )` làm ô chọn giờ rỗng. Bản cài nhận số và đổi bằng `"%.14g"`,
đúng định dạng `tostring()` của Lua. Việc nới này **không thể gây hồi quy**: trước đó nhánh số trả về 0 mà không
làm gì.

Số khung: **75 khung gọi `AddTextItem`**, 28 khung gọi `ComboBoxAddItem` (tên cũ vẫn chạy).

### 2.2 `Player:GetLevel` — 183 khung [DK]


```
rax = g_ObjectManager ; assert(rax->[0x98] != 0)      ; [0x98] = MySelf
rbx = rax->[0x98]->[0x1b0] ; assert(rbx != 0)         ; [0x1b0] = CharacterData
push_number( (int) rbx->[0x18]->[0x6c] )              ; = m_pData->m_nLevel
```

⇒ đúng bằng `CObjectManager::GetMe()->GetMySelf()->GetCharacterData()->Get_Level()`
(`GMDP_CharacterData.h:71`). `catalog.impl_085` chỉ đúng chỗ: 0.85 **có** hàm này nhưng **chỉ trên `Character`
(mục tiêu)**, chưa bao giờ trên `Player` — `in_085_same_receiver = false`.

**Khác biệt cố ý:** bản gốc chỉ `assert` khi chưa có MySelf (sẽ nổ ở màn đăng nhập). Bản cài trả **0**, vì khung CY
viết `local n = Player:GetLevel(); if n < 30 then` và `nil` sẽ ném lỗi Lua. Cùng khuôn với `CysMySelfReady()` mà
`GMGameInterface_Script_PlayerMySelf.cpp:45` đã dùng cho mọi `Player:*` khác.

### 2.3 `DataPool:GetServerDayTime` (176 khung) và `GetServerMinuteTime` (28 khung) [DK]


```
ngày : ecx = tm_year * 100 + 190001 + tm_mon ; ecx = ecx * 100 + tm_mday   -> push
giờ  : eax = tm_hour * 100 + tm_min          ; eax = eax * 100 + tm_sec    -> push
```

Thử ngày với 17/09/2026 (`tm_year=126, tm_mon=8, tm_mday=17`): `(126*100 + 190001 + 8)*100 + 17 = 20260917`.
⇒ hằng `190001` chính là `1900*100 + 1`, tức công thức là **`(tm_year+1900)*10000 + (tm_mon+1)*100 + tm_mday`**
= `YYYYMMDD`; và cái kia là **`HHMMSS`** (dù tên là "Minute").

Khớp với cách script dùng: **386 chỗ** so sánh ngày với hằng kiểu `20200106` (`Alcohol_Shop.lua:11`), `20190426`
(`Anniversary.lua:208`), `20230509`; và `JieRiHuoDong.lua:300-302` ghép đúng cặp
`nServerDay == …nDayStart and nServerTime < 110000` (11:00:00).

**Khác biệt cố ý, có lý do ghi rõ:** bản gốc **không** dùng đồng hồ thô. Nó lấy thời gian server trong `DataPool`
rồi **cộng `(8 − múi_giờ_máy) × 3600`** trước khi `_localtime64` (và trừ 1 giờ khi `tm_isdst > 0`), tức luôn trả
**ngày/giờ theo UTC+8** dù người chơi ngồi ở múi nào. Ở bản này **server chạy trên chính máy này (WSL)** nên giờ
của server = giờ cục bộ; giữ phép dịch UTC+8 chỉ làm client **sớm hơn server một ngày** trong vài giờ buổi tối.
Vì vậy bản cài dùng giờ cục bộ. Nếu sau này nối tới server ở múi giờ khác thì thêm đúng phép dịch đó — công thức
đã ghi sẵn trong chú thích của `CysHost_Plumbing.cpp`.

### 2.4 `_G:GetCurClientSize` — 15 khung [DK]


**Sàn 800×600 là chi tiết tôi sẽ đoán sai nếu không đọc mã.** Stub cũ đẩy `(0, 0)`, nên 15 khung viết
`local ScreenWidth, ScreenHeight = GetCurClientSize()` rồi đặt tooltip/cửa sổ trên màn hình 0×0
(`EquipEffectSelfTips.lua:248`, `InfantTips.lua:143`, `FreshManGuideNew.lua:46`…). Bản cài chép nguyên cả hai
nhánh lẫn hai hằng số (đọc từ `.rdata` bằng `scripts\20-peread.py`).

### 2.5 `Player:IsVaild` — 2 khung [DK]


---

### 3.1 57 hàm chỉ có trong client CY 3.71 — không có binary để đọc [SL]


- **`DataPool:LuaFnGetGMVisibleType` — 1.319 lời gọi, 29 khung, đứng đầu bảng.** Stub trả 0. Không có mã gốc để
  đối chiếu; viết hằng số khác 0 là bịa. **Chưa kết luận được.**
- **`SystemSetup:IsClassic` — 103 khung, nhiều khung nhất cả bảng.** Stub trả **1** (`rets="1"`, quyết định của
  `cy-gui-2`). Đổi giá trị này lật hành vi của 103 khung cùng lúc mà không có bằng chứng ⇒ **không đụng**.

## 4. VIỆC TIẾP THEO, xếp theo "rẻ và có bằng chứng"


---

## 5. ĐO A/B CÓ ĐỐI CHỨNG — bằng chứng cho cả sáu hàm

Công cụ: `Tools\game\run_world_gui_live.ps1` (đăng nhập thật vào server riêng, chọn nhân vật, vào thế giới,
ba lần bấm chuột đi bộ, thoát qua menu). **Cùng một kịch bản, cùng tài khoản `test01`, chỉ khác binary.**

| Phiên | Binary | Thư mục bằng chứng | Kết quả |
|---|---|---|---|
| `live-0-baseline` | **cũ** (`stage-fps-daiviet`) | `Build\Logs\2026-09-17-host-plumbing\live-0-baseline` | 20/20 PASS; **85** hàm giả / 1.083 lời gọi |
| `live-1` | mới (5 hàm) | `…\live-1` | 20/20 PASS; 83 hàm giả / 1.484 lời gọi |
| `live-2`, `live-3` | mới (6 hàm) | `…\live-2`, `…\live-3` | 19/20; **82** hàm giả / 1.632 và 1.884 lời gọi |

### 5.1 Dòng log biến mất — đúng năm dòng, không thừa không thiếu [DK]

`live-0-baseline` **trừ** `live-3` (cùng kịch bản):

```
DataPool:GetServerDayTime
MetaTable_Control_ComboBox:AddTextItem
Player:GetLevel
Player:IsVaild
_G:GetCurClientSize
```

Và `WXClient.log` của cả `live-2` lẫn `live-3` có `CYS-PLUMB: shared host functions registered=5`
(5 hàm phía Game.exe; `AddTextItem` do UI_CEGUI.dll đăng ký nên không đếm ở dòng này).
Không phiên nào còn ghi `missing host function` cho sáu hàm đã cài.

### 5.2 Không có hồi quy [DK]

Chiều ngược lại (có ở bản mới, không có ở bản cũ) chỉ ra **hai** dòng:
`_G:GetJieRiHuoDongInfo` và `_G:Lua_ShowQuickEnter`. **Cả hai đều ở cùng một khung `JieRiHuoDong`** — xem 5.3.
Không có dòng mới nào ở khung khác.

### 5.3 Chuỗi nhân quả: bản sửa MỞ KHOÁ khung, và chính nó lộ ra hàm thứ sáu [DK]

`JieRiHuoDong.lua:300-302` mở khung với điều kiện
`nServerDay == …nDayStart and nServerTime < 110000`, trong đó `nServerDay = DataPool:GetServerDayTime()`.

| Lượt | `GetServerDayTime` | Hệ quả quan sát được |
|---|---|---|
| `live-0-baseline` | stub → **0** | khung thoát sớm; **không bao giờ** gọi `GetServerMinuteTime` hay `GetJieRiHuoDongInfo` |
| `live-1` | **thật** | khung chạy tiếp → `DataPool:GetServerMinuteTime` **lộ ra lần đầu** trong danh sách stub (nó không có trong 114 hàm đo lúc đầu), kèm `GetJieRiHuoDongInfo` |

Đây là bằng chứng mạnh nhất của lượt này: nó cho thấy bản sửa **thật sự thay đổi luồng chạy**, chứ không chỉ làm
im một dòng log.

### 5.4 Một phép kiểm đỏ, KHÔNG do bản sửa [DK]

`live-2` và `live-3` trượt đúng một mục: **`position_changed`**. Ngưỡng ở
`run_world_gui_live.ps1:174` là `|dx| + |dy| >= 2.0`, đo **độ dời ròng** trước/sau ba lần bấm chuột. Ba lần bấm
tạo thành một tam giác **quay lại gần điểm xuất phát**, nên độ dời ròng vốn nhỏ và phụ thuộc vị trí xuất phát:

```
live-1            delta  (đạt)          live-0-baseline (binary CŨ)  delta -3.94,-2.41 = 6.35  PASS
live-2            delta -0.36, 0.89 = 1.25  FAIL
live-3            delta  1.86,-0.02 = 1.88  FAIL
```

Nhân vật **có di chuyển** trong cả hai phiên đỏ (`three_ground_clicks` PASS, `click_move_lines` PASS,
`self_moves=3`, `handler_errors=0`, `no_dump` PASS); chỉ là điểm kết thúc rơi gần điểm đầu. Đây là **tính chất
sẵn có của bộ lái**, không phải hồi quy: bản binary **cũ** cũng chạy đúng kịch bản đó và chỉ qua nhờ may mắn về
đường đi. **Việc nên làm:** đổi phép kiểm sang **quãng đường đi được** (cộng dồn từng đoạn) thay vì độ dời ròng —
báo cho chủ của `Tools\game\run_world_gui_live.ps1`.

---

### 5b.1 Bảng phím tắt CY, giải mã trọn vẹn [DK]


Cấu trúc "hai phím" mà `move-parity` mô tả **đúng từng dòng**: ví dụ mục 21 = `key1 '1' mod 0`,
`key2 '1' mod 2` ⇒ phím trơn `1` khi ô chat không nhận chữ, `Alt+1` khi đang gõ chat.

**Không gian chỉ số khớp chính xác với Lua** [DK]: `AcceSetup.lua:5` `AcceArryEx = 10` kèm chú thích
"11 phần tử đầu không cho người chơi tự định nghĩa" ⇒ bảng **đánh số từ 0**, hàng sửa được bắt đầu từ 11,
và `i = 1 → 1 + 10 = 11`. `ControlMaxNum = 64` phủ các chỉ số 11–30, 72–81 và 31–64.

Tên phím của chính CY (.rdata `0x7dc274`–`0x7dc338`): `"Shift+"`, `"Alt+"`, `"Ctrl+"`, `F1`…`F12`,
`PageUp`, `PageDown`, `Home`, `End`, `Left`, `Up`, `Right`, `Down`, `Delete`, `Tab`
(`measure\accel-modifier-strings.txt`). Cạnh đó là `ACCE_CUSTOM_%d`, `id`, `key1`, `key2`.

### 5b.3 `GetInputSetup` — cài thế nào cho không nói dối [DK]

`Src\Client\LuaApiGen\CysHost_Accel.{h,cpp}` + `CysHost_Accel_Table.inc` (**sinh tự động**, đừng sửa tay;
chạy lại `scripts\23-gen-accel-inc.py`).

Bảng là bản **chép nguyên** của CY, nhưng mỗi hàng mang thêm một bit `ours` = "bản dựng này **có thật sự** phân
phối phím đó không", tính bằng cách đối chiếu bảng CY với chính các nhãn `case KC_*` của
`ProcessInput_Keybord` (`scripts\22-accel-overlap.py`). **BẪY:** `KC_*` của engine là **mã quét
DirectInput** (`KC_A = 0x1E`), còn bảng CY dùng **mã VK** (`'A' = 0x41`) — phải qua một bảng DIK→VK, so thẳng
là sai hết.

```
bản dựng này phân phối 41 mã VK khác nhau
hàng người chơi sửa được (chỉ số >= 11):  68
   trong đó bản dựng này có phân phối:    44
   CY cũng để trống (key1 == 0):           9
   CY có mà bản dựng này CHƯA có:         15   <- danh sách thiếu, dành cho move-parity
tổng trên cả 79 hàng:                     46
```

Hàng nào `ours == 0` thì trả `""` ⇒ cửa sổ hiện chữ "không có" của chính nó. **Đó là sự thật**, thay vì khoe một
phím sẽ không làm gì. Trước lượt này **mọi** hàng đều hiện "không có".

Bằng chứng live: `live-4-accel\WXClient.log`
`CYS-ACCEL: GetInputSetup registered=1 rows_dispatched=46/79`, và so với phiên trước
(`live-3` 82 hàm giả → `live-4` **81**) thì **đúng một dòng biến mất: `SystemSetup:GetInputSetup`**, không có
dòng mới nào.

### 5b.4 `GetChildOffset` — chưa chốt


---

## 6. DỰNG LẠI VÀ BỘ KIỂM

Cây build: `Build\cmake\host-plumbing-x64` (Release, 27 thành phần). Log: `Build\Logs\2026-09-17-host-plumbing\build\`.

| Việc | Kết quả |
|---|---|
| `cys_wxclient` (Game.exe) + `cys_uisystem` (UI_CEGUI.dll) | **rc 0**, 0 lỗi (`build-4.log`) |
| `cys_protocol_tests` | **PASSED**, 497 gói, spec `2eb05f0c473d44b6` |
| `cys_netcore_tests` | **PASS**, 18 phép kiểm, fuzz 100.000 đầu vào |
| `cys_world_tests` | **PASS**, 83 phép kiểm, fuzz 20.000 gói thế giới |
| `cys_netbot_tests` | **PASS**, 28 phép thử, 0 thất bại, fuzz 100.000 |
| Bốn phiên GUI live | 20/20, 20/20, 19/20, 19/20 (mục 5.4) |

`Tools\build\ci_all.ps1` **chưa chạy** trong lượt này: nó chiếm khe `Game.exe` dùng chung và cả bốn phiên live ở
trên đã dùng khe đó. Bốn bộ kiểm bắt buộc đều xanh.

---

## 7. BẪY ĐÃ SẬP TRONG LƯỢT NÀY

1. **Đếm tĩnh nói quá rất nặng.** "5.919 stub" là số stub *đăng ký*; số stub *được gọi* trong một phiên chơi đầy
   đủ là **114**. Bốn hàm "nặng nhất" của bản giao việc thì đã là hàm thật từ trước.
2. **`LuaApiGen` là DLL khác với CEGUI.** `Src\Client\LuaApiGen\*` biên dịch vào **`cys_wxclient` → Game.exe**;
   các lớp widget (`ComboBox`, `ListBox`, `MeshWindow`, `CUIWindowItem`) nằm ở `Src\Client\CEGUISystem` →
   **`cys_uisystem` → UI_CEGUI.dll**. Không thể cài `MetaTable_Control_*:…` từ `CysHost_*.cpp`; **bắt buộc** phải
   sửa `UILuaControl.cpp`. Đúng như bố cục bản gốc: catalog ghi `module = UI_CEGUI.dll` cho đúng nhóm hàm ấy.
3. **`build.cmd` nuốt tham số.** Danh sách thành phần chứa `;` nên `cmd` cắt nó nếu không được **trích dẫn
   nguyên khối**; PowerShell lại **bỏ hẳn** tham số `""` rỗng, làm `%4`/`%5` lệch một bậc (danh sách thành phần
   chui vào `CYS_COMPONENTS`, ninja báo `no work to do`). Cách chắc chắn: viết một `.cmd` bọc ngoài, hằng số hoá
   cả dòng lệnh, rồi gọi file đó.
4. **Cấu hình CMake bị cũ khi agent khác thêm file nguồn.** `wxclient.cmake` liệt kê nguồn **tường minh** (không
   glob), nên khi `host-power` thêm `CysPowerNet.cpp` **sau** lần cấu hình của tôi, bản dựng của tôi đứt ở
   `LNK2019 CysPowerNet::RegisterHost`. Chạy lại `build.cmd` (nó cấu hình lại) là xong — **đừng** đi sửa file của
   agent khác.
5. **`localtime` vs múi giờ server.** Xem 2.3: bản gốc trả ngày/giờ **UTC+8**, không phải giờ cục bộ. Ai đọc
   `GetServerDayTime` mà tưởng nó là `time()` cục bộ sẽ chép sai khi server dời sang máy khác.
6. **`GetClientRect` trả 0 khi cửa sổ thu nhỏ** — đó là lý do bản gốc có nhánh `IsIconic`, không phải mã thừa.
   Và nó có **sàn 800×600** trong `.rdata`, thứ không thể đoán ra.
7. **Cột "số khung" phải phân biệt receiver.** `GetLevel` có mặt trên `Player`, `Pet`, `Target`, `TargetPet`;
   đếm thô cho 189 khung, đếm đúng cho **183**. Regex phải cho phép khoảng trắng **hai bên** `:` và `.`
   (bẫy do `host-power` phát hiện).
8. **Một phép kiểm đỏ chưa chắc là hồi quy.** `position_changed` đo *độ dời ròng*, mà kịch bản đi vòng về gần chỗ
   cũ. Cách chứng minh rẻ nhất: chạy lại **đúng kịch bản đó trên binary cũ** — đối chứng đó vừa loại trừ hồi quy
   vừa cho bảng so sánh sạch (mục 5).
