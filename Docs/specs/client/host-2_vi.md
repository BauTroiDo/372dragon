# host-2 — hàm host đợt 2, theo thứ tự giá trị (17–18/09/2026)


Quy ước: **[DK]** đọc/đo được (có địa chỉ, offset, số). **[SL]** suy luận. Không chắc thì ghi "chưa kết luận".

---

## 0. Trả lời ngắn



Số đo A/B ở mục 4. Tự phản biện từng hàm ở mục 5.

---

## 1. Đo trước — bảng 114 của host-plumbing là điểm xuất phát


Đối chứng của lượt này (`live-1-control`, cùng binary, `CYS_HOST2_OFF=1`): **90** dòng `missing host function`, trong đó
có `Listbox:GetCurrentFirstItem`, `Listbox:SetCurrentFirstItem`, `DataPool:Lua_GetItemNameByIndex`, `_G:SetDefaultMouse`
ngay lúc vào cảnh (03:29:48) — tức bốn tên này **được gọi trong một phiên bình thường**, không cần mở khung gì.

---

## 2. Hàm đã cài — hành vi lấy từ mã gốc

Mã: `Src\Client\LuaApiGen\CysHost_Host2.{h,cpp}` (**mới**, glue Lua + dịch vụ lớp game + đầu dò, cùng khuôn với
`CysHost_Ride.cpp`), `CysHost_Skill.{h,cpp}` (sửa `explain`), `UIWindowMng.{h,cpp}` + `UIScript.cpp` (`GetChildOffset`),
`UILuaControl.{h,cpp}` (Listbox). Mọi mục đều bị **`CYS_HOST2_OFF=1` tắt** (giữ nguyên stub) để đo A/B trên **cùng một
binary**.

### 2.1 `Player:GetXinfaInfo(id, "explain")` — vì sao `%d` in thô, và CY làm gì [DK]


  ```
  level = ObjectManager[0xb8]->[0x228]->[0x8]->[0x74]          ; cấp nhân vật
  max   = level <= 119 ? 119 : 129                              ; 0x77 / 0x81
  if (pSkillClass->m_nPosIndex == 7) {                          ; ô tâm pháp thứ 8 (SCLIENT_SKILLCLASS +8)
      max = level <= 119 ? 250 : 300
      if (g->[0x6f5874] != 0) max = 119                         ; cờ do gói 0xbfc đặt — server này không gửi ⇒ 0 [SL]
  }
  _snprintf(buf, 0x400, pszDesc, max); PushString(buf)
  ```

- Bản cài (`CysHost_Skill.cpp` `FormatExplain`/`ExplainMaxLevel`): cùng công thức; `m_nPosIndex` lấy từ
  `Get_SkillClass(id)` (0.85 gán `= size()` lúc chèn = thứ tự UI, đúng nghĩa CY); cấp từ `Get_Level()`. Hai dịch vụ
  mới `playerLevel`/`xinfaPosIndex` nối ở `CysSkillNet.cpp:RegisterHost` (2 dòng, thẻ `CYS-HOST2`).
- **Khác biệt cố ý**: thay `%d` (và `%%`) **bằng tay** thay vì `_snprintf(desc)`. Với dòng chuẩn kết quả **y hệt từng
  byte**; với bản dịch tiếng Việt có dấu `%` lạc thì `_snprintf` của CY sẽ phá nhãn, bản cài thì không.
- **Đo tĩnh toàn bảng** (`dbc_inventory.Table`): **120/120** dòng có đúng **một** `%d`, **0** dòng có đặc tả khác
  (`%s`, `%5d`, `%%`) ⇒ hai cách cho kết quả giống nhau trên dữ liệu hiện tại, khác biệt chỉ là lưới an toàn cho
  bản dịch sau này.

### 2.3 `Listbox:GetCurrentFirstItem` / `SetCurrentFirstItem` [DK]


  ```
  getFirstVisibleItem: y = area.top - vscroll.position;  for i: y += item[i].height; if (y > area.top) return item[i]
                       không có thanh cuộn: y bắt đầu = area.bottom ⇒ item 0
  setFirstVisibleItem(i): i >= count -> thôi; before = Σh[<i]; total = Σh; total == areaH -> thôi;
                       if (areaH > total - before) before = total - areaH;  vscroll.setScrollPosition(before)
  ```


### 2.7 `DumpMissingCallCounts(0)` — bảng đếm đầy đủ lúc thoát

`LuaApiGen_Common.cpp`: `limit == 0` ⇒ in mọi hàm; `GameProcedure.cpp:866` gọi với 0 (1 dòng). Bốn lần đổ định kỳ
vẫn 20 dòng.

---

## 4. Đo A/B — cùng kịch bản, cùng tài khoản

Runner `Tools\game\run_world_gui_live.ps1` (đăng nhập thật, chọn nhân vật, vào cảnh, ba lần bấm đất, thoát qua menu)
+ đầu dò `CYS_HOST2_LIVE=1` (mở sổ kỹ năng → cửa sổ học tâm pháp + bấm tâm pháp 1 → `UI_COMMAND 20141203` (MiniMap
forum tip → `GetChildOffset`) → `ToggleWuhunPage()` → đếm stub). Tài khoản **test08**, cùng stage, **cùng binary v3**
(`Game.exe 800ecc19…`, `UI_CEGUI.dll 0b1f2ee9…`) — chỉ khác `CYS_HOST2_OFF`.

| Phiên | Binary | Host-2 | Kịch bản | `missing host function` (lần gọi đầu) | Bảng đếm cuối |
|---|---|---|---|---:|---|
| `live-4-base` | **cũ** (`stage-host-2-base`, cây trước khi sửa, `9b81e964…`) | — | chuẩn, không đầu dò | **81** | 1.565 lời gọi / 81 hàm, 20/20 PASS |
| `live-1-control` | v3 | **OFF** | đầu dò (chết ở bước QuestLog, xem bẫy 2) | **90** | 1.674 / 86 (bảng định kỳ cuối) |
| `live-5-on` | v3 | **ON** | đầu dò (không QuestLog) | **112** | 1.826 / 112 |

**Đọc đúng bảng này** (`scripts\80-ab.py live-1-control live-5-on`):

- `live-1-control` − `live-5-on` = **8 dòng biến mất**: **4 dòng là hàm đợt này** — `DataPool:Lua_GetItemNameByIndex`,
  `MetaTable_Control_Listbox:GetCurrentFirstItem`, `MetaTable_Control_Listbox:SetCurrentFirstItem`, `_G:SetDefaultMouse`
  (bộ đếm stub của cả bốn = **0** ở phiên ON, trong khi phiên OFF ghi chúng ngay lúc vào cảnh 03:29:48); 4 dòng còn lại
  (`GetPlayerMission_*` ×3, `Window:ResetScrollPosition`) thuộc bước QuestLog mà phiên ON không còn — **khác kịch bản, không
  phải thành tích**.
- `live-5-on` − `live-1-control` = **30 dòng mới, tất cả xuất hiện trong cửa sổ 03:56:40–03:56:50** = đúng lúc đầu dò
  phát `UI_COMMAND` (03:56:40, 8 dòng + hộp "lưu thông tin sạp" của khung khác cũng nghe `UI_COMMAND`) và mở **khung võ hồn
  (03:56:41–45, 21 dòng: `KFS_UpdateKFSModel`, `GetKfsSkill`, `SystemSetup:GetShowWuhunObj`, tip của các trang
  BieYe/CangPin/Infant/MaritialSys…)**. Trước lượt này khung ấy **không thể mở** nên các stub đó chưa từng được gọi — cùng
  kiểu "khung được mở khoá lộ ra hàm thiếu" như `JieRiHuoDong` của host-plumbing. **0 dòng mới trước 03:56:40** ⇒ không có
  hồi quy ở phần đăng nhập/vào cảnh/di chuyển.
- `live-4-base` (binary cũ, kịch bản chuẩn) = 81; `live-1-control` (binary mới, OFF) ⊇ base, **0 dòng của base biến mất**
  và 9 dòng thêm đều do đầu dò mở khung ⇒ binary mới ở trạng thái OFF không đổi gì.

**Bằng chứng từng hàm trong phiên ON** (`live-5-on\WXClient.log`, `UISystem.log`, ảnh `cys-live-181561421-h2-*.png`):

| Hàm | Dòng/ảnh |
|---|---|
| `explain` | `text ActionSkillsStudy_SkillInfo rc=252 […最高等级119…]` (OFF: `…最高等级%d…`); ảnh `h2-study` (trước/sau: `live-1-control` vs `live-5-on`) và `h2-skillbook` |
| Listbox | `UISystem.log`: `GetCurrentFirstItem MissionTrack_ListBoxTransparent -> -1 (items=0)` rồi `-> 0 (items=5)`; `SetCurrentFirstItem <- 0 … now first=0`; `XuanPresent_ChooseFriend_FriendList -> -1 (items=0)` ×7 — đúng B (rỗng ⇒ −1) |
| `Lua_GetItemNameByIndex`, `SetDefaultMouse` | stub 0 lần (OFF: gọi ngay lúc vào cảnh) |
| `ToggleWuhunPage` + sự kiện + KFS nil | `Wuhun shown=1 (pushed by host function=1)`, ảnh `h2-wuhun` — khung "Võ Hồn" mở, ô võ hồn trống, **không lỗi Lua** (OFF: sự kiện bị từ chối, khung không mở) |
| `GetChildOffset` | **v3 SAI**: `GetChildOffset MiniMap:MiniMap_Forum -> (0,0) found=0` dù widget có (`MiniMap.layout.xml:485`) — `isChild/getChild` 0.4.1 chỉ xét con trực tiếp; **sửa ở v5** (`cysFindDescendant`, đúng `FindChild` của B), chờ khe đo lại — xem 4.1 |

### 4.1 `GetChildOffset`: lỗi v3, nguyên nhân, bản sửa v5

**Triệu chứng đo được** (`live-5-on`, `UISystem.log`): `GetChildOffset MiniMap:MiniMap_Forum -> (0.0, 0.0);
screen delta (0.0, 0.0) found=0` — chính dòng tự kiểm ở 2.2b bắt được, vì `found=0` trong khi widget có thật.


**Bản sửa (v5)**: `cysFindDescendant` trong `UIWindowMng.cpp` duyệt cây đúng như `FindChild`. Dự đoán kiểm được ở
phiên sau: `MiniMap:MiniMap_Forum` phải ra `found=1` và `(x, y)` **bằng** `screen delta` (= vị trí
`MiniMap_Background_Frame` + vị trí `MiniMap_Forum` trong khung).

**ĐÃ CHỨNG MINH** — phiên `live-6-on` (08:35–08:37, binary v7 `05f84e8c…`, **runner 20/20 PASS**), `UISystem.log`:

```
CYS-HOST2: GetChildOffset MiniMap:MiniMap_Forum -> (199.0, 41.0); screen delta (199.0, 41.0) found=1
```

`found=1` và **hai cặp số bằng nhau** — đúng dự đoán tĩnh (199 = X của `MiniMap_Background_Frame` + X của
`MiniMap_Forum`). Bộ đếm stub `this:GetChildOffset` = 0 ở cả hai phiên là chuyện đương nhiên (stub nằm sai receiver,
không bao giờ chạy) ⇒ **dòng probe này là bằng chứng duy nhất có thể có** cho hàm ấy.

Cùng phiên đó: `closed MessageBox_Self (after the forum tip)` ⇒ hai phép kiểm thoát của runner (4.2) **xanh trở lại**.

### 4.2 Hai phép kiểm đỏ của runner ở phiên ON — không do hàm host

`quit_complete_flag0_decode0` / `finished_in_time`: sau khi đầu dò xong, runner bấm thoát (`clicked the quit item … CGAskQuit`
03:56:50) nhưng client không đóng ⇒ bị kill ở 240 s. Ảnh `h2-forumtip`/`h2-wuhun` cho thấy một **hộp "Chức năng lưu thông
tin sạp hàng…"** (`INTERFACE_XML_681`) mở ngay sau `UI_COMMAND 20141203` — khung khác cũng nghe `UI_COMMAND` và hiện hộp
xác nhận; hộp này (modal) nhiều khả năng là thứ chặn thoát. Đầu dò phiên sau đóng nó trước khi thoát (4.1).

---

## 5. Tự phản biện — "nếu tôi sai thì triệu chứng là gì" và đã kiểm thế nào

| Hàm | Nếu sai | Triệu chứng | Kiểm |
|---|---|---|---|
| `explain` | công thức `max` sai | nhãn "最高等级" ra 129/250 thay vì 119 cho nhân vật cấp 15 | đọc text `ActionSkillsStudy_SkillInfo` qua bridge + ảnh `h2-study` |
| `explain` | thay nhầm ký tự | mất chữ quanh `%d`, hoặc `%%` không thành `%` | so byte đầu/cuối chuỗi trước–sau trong log |
| `GetChildOffset` | cộng dồn sai (tuyệt đối/tương đối, dừng sai cửa sổ) | `(x,y)` ≠ `screen delta` trong dòng `CYS-HOST2: GetChildOffset` | đối chiếu hai cặp số trong `UISystem.log` |
| `GetCurrentFirstItem` | lệch 1 (so `>` vs `>=`) hoặc sai thanh cuộn | trả −1 khi có item, hoặc chỉ số ≠ dòng đầu nhìn thấy sau khi `Set` | dòng `SetCurrentFirstItem … now first=N` phải bằng `N` vừa đặt |
| `SetCurrentFirstItem` | không tìm thấy `__auto_vscrollbar__` | danh sách không cuộn về chỗ cũ khi MissionTrack/QuestLog vẽ lại | `scroll=-1.0` trong log = không có thanh cuộn |
| `Lua_GetItemNameByIndex` | sai bảng/cột | tên vật phẩm sai loại (tên đá quý cho thuốc) | đối chiếu chỉ số mẫu 3 dải với `dbc_inventory` |
| `ToggleWuhunPage` | sự kiện chưa nối / cổng thủ tục sai | `Wuhun shown=0` sau khi gọi | dòng `Wuhun shown=…` + ảnh `h2-wuhun` |
| KFS getter | trả nil sai lúc có võ hồn | nhãn võ hồn trống khi đã mặc | dòng `wuhun equipped but … (nil)` — chưa có nhân vật mặc võ hồn để kiểm (mục 7) |
| `SetDefaultMouse` | kiểu mặc định ≠ NORMAL | con trỏ nháy sai một tick khi đóng shop | **Đo được 1 mẫu** (`live-6-on`): `SetDefaultMouse cursor 1 -> 1 (CURSOR_NORMAL=1)` — lần gọi duy nhất trong kịch bản xảy ra lúc vào thế giới, con trỏ **đã** là NORMAL ⇒ lần đó hàm **không sửa gì**, hệt như stub. Chưa phủ được ca nó sinh ra để phục vụ (đóng shop khi con trỏ đang là "mua"): 51 khung gọi đều là shop, kịch bản chưa mở shop nào ⇒ **ích lợi CHƯA chứng minh** — xem 5.1 |
| `DumpMissingCallCounts(0)` | `limit 0` bị hiểu là "không in" | bảng cuối trống | `shown=N` bằng `distinct=N` ở dòng `begin` |

### 5.1 `SetDefaultMouse` — mục duy nhất chưa chứng minh được ích lợi

Luật dự án: *"hàm host trả đúng bằng giá trị stub thì không đáng cài"*. Tôi **chưa** hạ nó về stub vì hành vi của nó
**phụ thuộc trạng thái**, khác hẳn nhóm hằng số (`IsWeGameClient`, `ZBS:IsViewerWatching`) mà host-plumbing bỏ: B đặt
lại con trỏ về kiểu mặc định, và ca nó phục vụ là **đóng shop khi con trỏ đang là "mua"** — kịch bản đo chưa mở shop
nào nên chưa quan sát được. Mẫu duy nhất quan sát được (`cursor 1 -> 1`) chỉ nói "lần đó không sửa gì".

**Phép thử dứt điểm cho người sau** (một phiên có shop, `CYS_HOST2_PROBE=1`): mở NPC shop → đóng → tìm dòng
`CYS host2: SetDefaultMouse cursor N -> 1` với **N ≠ 1**. Có N ≠ 1 ⇒ giữ; chỉ toàn `1 -> 1` sau vài phiên có shop
⇒ **hạ về stub** (xoá đúng một dòng `{nullptr, "SetDefaultMouse", …}` trong `kEntries`). Rủi ro khi giữ bị chặn ở
một khung hình: `GamePro_Main.cpp:925-947` tính lại con trỏ theo hover mỗi tick.

### 5.2 Lỗi `CysHost_Accel` — hoán vị Shift ↔ Ctrl (do `review-red` tìm ra, tôi kiểm độc lập rồi sửa)


**Ảnh hưởng thật**: 15 binding đổi tên, trong đó **8 binding của 5 hàng** là hàng bản dựng thật sự phân phối
(`ours = 1`) ⇒ **người chơi đang thấy sai**: `Shift+1/2/3` → **`Ctrl+1/2/3`** (hàng 31/32/33),
`Shift+Alt+,` / `Shift+Alt+.` → `Alt+Ctrl+,` / `Alt+Ctrl+.` (hàng 4/5 — đổi kênh chat). Mười hàng còn lại có
`ours = 0` nên vốn đã hiển thị "không có".

**Đã sửa ba chỗ** như yêu cầu: `CysHost_Accel.cpp` (thứ tự tên **và** thứ tự ghép theo đúng precedence của B),
chú thích trong `CysHost_Accel_Table.inc`, và **bộ sinh** `23-gen-accel-inc.py`.

### 5.3 Cột `ours` — dựng lại trên nguồn mới, và vì sao 58 chứ không phải 63

Phép quét cũ (`case KC_*` của `GamePro_Main.cpp`) chết khi `move-2` chuyển sang bảng `CysAccelCore/CysAccelTable`
(xoá 474 dòng) ⇒ sinh lại cho `ours = 0/79`, **âm thầm tắt cả 46 binding**. `move-2` viết bộ quét mới
`Tools/game/accel_ours_scan.py` (đọc `kRowMeta`) và báo **63/79**.

**Tôi kiểm lại và hạ xuống 58.** Quy tắc của bộ quét là "dispatched trừ khi action là `ACT_NONE`/`ACT_CY_NOT_PORTED`",
tức tin `kRowMeta` — nhưng `kRowMeta` nói hàng *định* làm gì, còn `CysAccelTable.cpp` mới nói nó *có* làm gì. Đọc thân
`case` (dòng 365–373):

| action | thân `case` | kết luận |
|---|---|---|
| `ACT_SYSTEM_LOCKKEY` (hàng 7, 8, 9 — CapsLock/ScrollLock/NumLock) | `break;`, không có đường nào khác | **0** |
| `ACT_DEBUG` (hàng 2, 6) | chỉ làm việc khi `row == 3` | **0** |
| `ACT_DEBUG` hàng 3 (Ctrl+G) | bật bảng gỡ đồ hoạ, trong `#ifndef _FINAL`; **`_FINAL` không được định nghĩa** (0 lần trong `build.ninja`) | **1** |
| `ACT_SCREENSHOT` (hàng 10) | `break;` **nhưng** `CInputSystem::MessageProc` bắt `VK_SNAPSHOT` → `PrintScreen` (`GMInputSystem.cpp:152-157`) | **1** |

Nếu giữ 63 thì năm hàng CapsLock/NumLock/ScrollLock/Ctrl+N/Ctrl+` sẽ được **quảng cáo là có phím** trong khi bấm vào
không có gì — đúng lỗi "tệ hơn stub" vừa sửa ở 5.2. Tôi vá quy tắc vào **chính bộ quét dùng chung** (thẻ `CYS-HOST2`,
kèm bằng chứng) để bộ sinh và `--check` cùng một sự thật.

**Kết quả**: `ours` **46 → 58**, đúng **16 hàng** đổi bit — 14 hàng `0→1` (Esc, Enter, Ctrl+G, PrintScreen, H trợ giúp,
J nhảy, Alt+Lên/Xuống thu phóng, Tab bản đồ, R/`` ` `` sự kiện, Lên/Xuống, Alt tooltip) và 2 hàng `1→0`
(`ACT_CY_NOT_PORTED`: chỉ ghi log). Bộ sinh nay lấy `ours` **từ bộ quét**, và có `--check` (rc=1 khi `.inc` lệch):

```
python Build\Logs\2026-09-17-host-plumbing\scripts\23-gen-accel-inc.py --check   # rc=0: check: .inc ours=58, bo quet=58, lech 0 hang []
```

### 5.4 Đo live của hai mục trên — `live-9-on` và `live-10-on` (18/09, test08, runner 20/20 PASS cả hai)

```
CYS-ACCEL: GetInputSetup registered=1 rows_dispatched=58/79          <- khop so tinh duoc o 5.3
CYS host2: GetInputSetup(31) -> key1="Ctrl+1" key2="Ctrl+1"          <- 5.2: truoc khi sua la "Shift+1"
CYS host2: GetInputSetup(32) -> key1="Ctrl+2" key2="Ctrl+2"
CYS host2: GetInputSetup(33) -> key1="Ctrl+3" key2="Ctrl+3"
CYS host2: GetInputSetup(30) -> key1="0"      key2="Alt+0"           <- mod 2 = Alt khong doi, dung nhu truoc
CYS host2-live: AcceSetup shown=1                                     <- anh cys-live-202103453-h2-accel.png
```

**Ảnh**: cửa sổ "Tùy chỉnh phím tắt" mở, mười hàng đầu hiện **F1…F10 ở cả hai cột** — đúng bằng hàng 11–20 của bảng
(key1 = key2 = 0x70…0x79, `ours = 1`). Ba hàng `Ctrl+1/2/3` nằm dưới tầm nhìn của trang đầu, nên **bằng chứng cho
chúng là dòng log ở trên** — cùng một chuỗi mà `AcceSetup.lua:336` đặt vào `SetProperty("Text", key1)`, tức đúng thứ
người chơi đọc. Muốn thấy tận mắt thì phải cuộn danh sách: thêm một bước đầu dò nữa, chưa làm.

**Bẫy bắt được khi lấy ảnh**: đẩy `GE_TOGLE_INPUTSETUP` **không tham số** thì khung **im lặng không mở**
(`AcceSetup shown=0` ở `live-9-on`) — `AcceSetup.lua:253-254` chỉ mở khi `arg0 == "show"`. Cùng họ với bẫy
`RegisterEventHandle` của host-power: sự kiện tới đúng khung vẫn có thể không làm gì, và không có dòng lỗi nào.

---

## 6. Bẫy đã sập / phát hiện trong lượt này

1. **`Wuhun_Update` chết vì stub trả `""`** — một stub "vô hại" cũng làm khung không mở: `data < 5` với chuỗi. Với hàm
   "đọc thứ chưa có", câu trả lời đúng của B thường là **nil**, không phải `""`/0.
2. **Mở QuestLog bằng `TOGLE_MISSION` từ phiên mới ⇒ Access Violation trong `CEGUIBase.dll`** (đọc `0xFFFFFFFF`,
   `live-1-control`, host-2 **OFF**) — lỗi có sẵn, không thuộc lượt này; đầu dò đã bỏ bước đó. Giao `quest`.
3. **Thunk vtable của CY 3.71**: `objGlobal.Register("GetXinfaInfo", fn)` trỏ vào `jmp [rax+0xC0]`, không phải thân
   hàm; phải lần theo chuỗi mà hàm dùng (`explain`, `needlevel`).
4. **`Rect` của CEGUI GL xếp `{top,bottom,left,right}`** — đọc `isPointInRect` trước khi tin bất kỳ `[rax+4]` nào.
5. **`Src/Client/LuaApiGen` include được lớp game** (`CysHost_Ride.cpp` đã làm) — không cần thêm `Network/*.cpp` + sửa
   `wxclient.cmake`; nhưng `GMDataPool.h` cần `<set>` trước nó, và `ITEM_CLASS` thật tên `ICLASS_EQUIP`
   (`Shared/Common/GameDefine_Item.h`) — enum `IC_*` trong `TDObjectSystem.h:154` **nằm trong chú thích**.
6. **`give_item.py` từ chối khi có bất kỳ kết nối client nào** (không chỉ nhân vật đích) — với 10 nhánh song song thì
   gần như không có khe; phải chọn lúc server rảnh.
7. **Không có `Game.exe` nào của mình nhưng khe vẫn bận**: `tasklist` thấy tiến trình của nhánh khác; runner tự chờ
   (`-WaitMinutes 30`), đừng kill.
8. **Bản dựng cây mới trùng lúc sửa file**: `EPERM` khi Edit `GameProcedure.cpp` vì `cl.exe` đang giữ; và bản dựng
   nền có thể "dính" file sửa dở — kiểm chuỗi (`grep -c CYS_HOST2_OFF Game.exe`) trước khi gọi nó là "binary cũ".

---

## 7. Việc tiếp theo (lệnh chạy được)

1. **Võ hồn thật**: phát `10156001` (琉璃焰, EquipPoint 18) cho test10 khi server không có kết nối, rồi đo bằng bot:
   ```
   wsl.exe -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/give_item.py give --guid 200011 --item 10156001 --out /mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-17-host-2/kfs/give-200011-before.json
   Build\cmake\host-2-x64\bin\CysNetBot.exe --mode world --host 127.0.0.1 --port 15733 --game-port 15734 --account test10 --guid 200011 --bag 1 --equip <ô> --kfs 4,<pos>,0,0 --out Build/Logs/2026-09-17-host-2/kfs/bot-1
   ```
