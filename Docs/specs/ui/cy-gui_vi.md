# Giao diện theo CY 3.71.9609 (agent `cy-gui`)

Ngày lập: 14/09/2026. Nhánh `cy-gui`, worktree `Build\wt-cy-gui`. Bằng chứng: `Build\Logs\2026-09-14-cy-gui\`.
Quy ước: **[DK]** dữ kiện đo được (có đường dẫn/offset/số đếm), **[SL]** suy luận.

Nguồn: **S4** = CY 3.71.9609 chính thức `C:\TLBB\085\Tools\DATA NEW\CY Game` (chỉ đọc; Game.exe sha256
`9278c7f37b55539fcfac1d93afa71f278e34d4ce674b0e8b52a0f62ea6e0cc5b`, CEGUIFalagard.dll `4adc5a34…cd1`,
CEGUIBase.dll `96b11d89…f88`, UI_CEGUI.dll `e90c68e0…0a5`), **GL** = `Assets\Canonical` (nền client_GL).

---

## 1. Chỉ thị người dùng và phạm vi

| Ngày | Nguyên văn | Hệ quả |
|---|---|---|
| 14/09 | “Thôi sử dụng khung CY luôn đi, không cần GL nữa. Mọi thứ như CY đi” | Toàn bộ lớp GUI (layout, scheme, looknfeel, imageset, font, Lua giao diện, luồng màn hình) lấy từ CY 3.71. GL chỉ còn là tham chiếu khi CY thiếu. |
| 14/09 | “Giữ tiếng Việt, tiếp tục đi” | **Quyết định của người dùng** (không còn là giả định): khung/bố cục/Lua theo CY, chữ hiển thị là tiếng Việt qua từ điển ghép theo **khoá CY**; chỗ chưa có bản dịch giữ chữ Trung gốc của CY và được **thống kê** để làm đợt dịch sau. |
| 12/09 | “Dùng font này để hiển thị vừa tiếng trung vừa tiếng việt NotoSansSC-Regular.ttf utf8” | Mỗi file `.font` của CY được thêm biến thể `CodePage="65001"` trỏ Noto; biến thể 936/1258 của CY giữ nguyên. |
| 13/09 | yêu cầu để trống StrFilter | `ConfigFolder\StrFilter.txt` rỗng (chỉ 2 dòng tiêu đề). |

Không đụng `Assets\Canonical`, client_GL, `C:\TLBB\085\client`, `Tools\DATA NEW`, server WSL.

---

### 2.2 Bộ giải và kết quả **[DK]**

`Tools\pipeline\cy_lua_unpack.py` (Rijndael thuần Python, không phụ thuộc thư viện ngoài) + test
`Tools\pipeline\test_cy_lua_unpack.py` (10 ca): vector FIPS-197 C.1/C.2, khứ hồi khối 24, khứ hồi container,
CRC sai bị từ chối, dữ liệu không đóng gói trả `None`, và **ca trên kho thật**.

- `Interface.axp` có **2.043** file `.lua`; **226** file đóng gói. Bộ giải ra **226/226 mã nguồn Lua GBK**
  (không phải bytecode `\x1bLua`), và **đóng gói lại khớp từng byte 226/226** (test `test_all_packed_decode_to_source`).
- `Config.axp` có 1.130 file `.lua`, **không file nào** đóng gói (plaintext GBK). Chú thích “Config.axp có 1.130 file Lua
  đóng gói” ở `cy-switch_vi.md` mục 4 cần sửa: chúng là plaintext.
- Lệnh: `python -B Tools\pipeline\cy_lua_unpack.py FILE -o OUT` | `--axp <Interface.axp> --out DIR` | `--selftest`.

---

### 3.2 `all.imageset.xml` **[DK] + [SL]**

CEGUIBase.dll của CY có chuỗi hằng `Schema/all.imageset.xml` (và `ImagesetFromImage`, `Imageset_bin`); scheme CY trỏ
tới các file rời không tồn tại (`Common/CornerMark.imageset.xml`…). **[SL]** CY nạp một file gộp rồi tra theo
**`Name`**. CEGUI 0.4.1 của dự án nạp một imageset mỗi file, nên builder **tách** `all.imageset.xml` thành đúng
3.784 file theo tên file mà scheme gọi (4 mục trùng tên file, 4 mục đã có file thật, 0 mục không giải được).

### 3.3 Font CY **[DK]**

Mỗi `.font` là `<Fonts>` nhiều biến thể theo code page: `CodePage="936"` dùng `Schema/0_FIREFOX_2.bin|Schema/1_FIREFOX_2.bin`
(hoặc `GBK12.bin` cho bitmap SongTiBmp12) và `CodePage="1258"` dùng `Schema/tahoma.ttf` / `VTNAM14.bin` — tức bản CY
này **đã có nhánh tiếng Việt CP1258**, nhưng `tahoma.ttf` không có trong Interface.axp. Dự án chạy `System_CodePage=65001`
nên builder thêm biến thể `CodePage="65001" Type="FreeType" Filename="Schema/NotoSansSC-Regular.ttf"` (kích thước giữ
theo biến thể đầu, `TextureSize=512`). Viewer xác nhận **8/8 font do engine nạp, 0 phải thích ứng**.

### 3.4 Kiểu Falagard CY có mà GL không có (DoD 2) **[DK]**


| TargetType CY | Dùng trong layout | Lớp CY (export) | Cài trong `FalagardCyWidgets.*` |
|---|---:|---|---|
| `Falagard/MeshWindow/ParentWindow` | 8 (PlayerFrame, TargetFrame, PetFrame, PartyFrame) | `FalagardMeshWindow::ParentWindow` | Window + `RoundEnabled`, `MaskImage`, vẽ look Enabled/Disabled |
| `Falagard/MultiColumnListNew` | 6 | `MultiColumnListNew::{addButtonItem,addImageItem,addListBoxItem,clearAllSelections,…}` + thuộc tính `ColumnHeader/CreateButtonType/SetImageSize/SetButtonSize/SelectBrush/SelectColour/LineDrawOffset` | dẫn xuất `FalagardMultiColumnList` + thuộc tính CY (`ShowImageType`, `ChildItem`… giữ giá trị) |
| `Falagard/EventsWindow` | 3 | `AddChildElement/ClearAllElement/UpdateAllElement/PageEnd/SetElementsInView/…`, `Column/HorizontalPadding/VerticalPadding` | dẫn xuất `FalagardAchievementWindow` + bố trí lưới |
| `Falagard/ActionButtonWindow` | 2 | như trên | như trên |
| `Falagard/DragCornerButton` | 1 (ChatFrame) | `setDragTarget/setDragMode/setLimited/setMin|MaxWidth/setMini|MaxHeight` | dẫn xuất `FalagardButton` + kéo đổi cỡ cửa sổ đích |
| `Falagard/ScrollText` | 4 (ServerNew) | `Speed/TextMode/TextBoardNumber/TextBoardHeight/BoardKillTimer`, sự kiện `InfoElement*` | Window cuộn chữ + 5 thuộc tính + 4 sự kiện |
| `Falagard/SFZSoftKeyWindow`, `Falagard/PhoneSoftKeyWindow` | 1 + 1 | `FalagardSFZSoftKeyBoard`, `FalagardPhoneSoftKeyBoard` (cùng API với SoftKeyBoard, khác tên thuộc tính) | dẫn xuất `FalagardSoftKeyBoard` + `SFZ*`/`Phone*` |
| `Falagard/ActionButtonItem` | 0 (Lua tạo lúc chạy) | `SetImage/SetText1..3/SetButton1*/ChildImage*` | `FalagardCyItemButton` |
| `Falagard/GuildButton` | 0 | `SetBanghuiJiangli*` (12 setter) | `FalagardCyItemButton` |
| `Falagard/AchievementBarWindowButton` (+ `…CompareWindowButton`, `…CompareWindowIntegrationButton`) | 0 | `SetAchievementBar{Name,Content,Date,Icon…,Progress}` | `FalagardCyItemButton` |
| `Falagard/AchievementWindowCatalogButton`, `…TextButton` | 0 | `SetAchievementCatalog*/SetAchievementText*`, `getHoverSection` | `FalagardCyItemButton` (có `HoverSection`) |
| `Falagard/MultiColumnListEx` | 0 | `addRow/SetItemText/IsRowUsed/ChangeButtonType/GetClickedButton*` | dẫn xuất `FalagardMultiColumnList` |
| `Falagard/StaticUVImage` | 0 | `setMirrorFormatting` | dẫn xuất `FalagardStaticImage` + `MirrorFormat` (vẽ chưa lật UV — ghi rõ) |
| `Falagard/CircleProgress` | 0 | `ApplyMesh/setAutoMove/setClockWise/setDownDir/setFillDirection/setLightEnable/setLightRadius/setMoveSpeed` | Window + 9 thuộc tính, vẽ xấp xỉ tuyến tính (CY vẽ vành) |

Thuộc tính layout CY mà 0.85/GL chưa biết (nay được nhận và giữ, không ném): `StopWatch.TimerShowType/HourText`,
`ActionButton.EnableCtrlRightClick`, `CheckBox.ShowPush`, `WorldMap.CommanderFlagImage/HostileImage`,
`ChatHistory.ForceVertScrollbar`, `Button.HorzFormatting`, `DefaultWindow.Image/TweenPosition`,
`ChatChannel.AutoResizeEnabled/ChildItem/DelButtonSize`.

### 3.5 Look thiếu trong chính dữ liệu CY **[DK]**

4 look mà scheme CY gọi nhưng không file `.looknfeel.xml` nào của CY định nghĩa: `TLBB_Look_NewExteriorCheckBK1`,
`TLBB_Look_NewExteriorCheckBK2`, `TLBB_Look_ScrollbarThumb_Track`, `TLBB_Look_SelectServerWindow`. Không layout nào
dùng 4 kiểu cửa sổ tương ứng, nên đây là lỗ hổng có sẵn của CY, không phải do chuyển nền.

---

## 4. Luồng màn hình CY (DoD 2)

`ConfigFolder\InterfaceEx.txt` của CY là bảng nhị phân 00CCBBDD **10 cột** (GL 9), 1.975 dòng
(ID, tên cửa sổ, layout, lua, nhóm, mã, 2 số, cột 9 mới = -1, mô tả). Các mục của luồng đăng nhập **[DK]**:

| ID | Tên | Layout / Lua |
|---:|---|---|
| 16 | `LoginLogOn` | `LogOn/LogOn.layout.xml` + `.lua` |
| 29 | `LoginSelectServer` | `SelectServer/SelectServer.*` |
| 30 | `LoginSelectServerQuest` | `SelectServerQuest/SelectServerQuest.*` |
| 28 | `LoginSelectRole` | `SelectRole/SelectRole.*` |
| 7 | `LoginCreateRole` | `CreateRole/CreateRole.*` |
| 311 | `LoginTimer` | `LoginTimer/LoginTimer.*` |
| 522 | `LoginOverTime` | `LoginOverTime/LoginOverTime.*` |
| 17/65/174/358 | `MainMenuBar`, `_2`, `_3`, `_4` | thanh nút HUD |
| 36 / 42 / 43 / 4 | `MiniMap`, `PlayerFrame`, `TargetFrame`, `ChatFrame` | HUD |


Khác biệt đáng chú ý: CY có `LogOn_Wegame_*`, `LogOn_MailID`, `LogOn_PassWord_Protect_*`, `LogOn_OwnDefineLogon`;
GL có `LogOn_Erweima_*` (mã QR), `LogOn_FangChenMi_*`. CY SelectServer dùng `SelectServer_Commendable2_Subarea*`
thay cho `SelectServer2_Subarea*` của GL và có thêm khu “CG”. CreateRole CY có 15 mục xem trước môn phái
(`CreateRole_MenpaiModel00..14`) so với 12 của GL.


---

## 5. Chữ tiếng Việt trên khung CY (quyết định người dùng)

`Tools\pipeline\cy_gui_dict.py` dựng `ConfigFolder\StrDictionary.txt` (văn bản UTF-8, CRLF, 2 dòng tiêu đề) theo
**khoá CY**, mỗi giá trị chọn theo thứ tự:

| Nguồn | Số khoá | Giải thích |
|---|---:|---|
| `gl-same-zh` | 24.159 | GL đã dịch và nguyên bản Trung của GL **giống hệt** chuỗi Trung của CY |
| `no-han` | 2.381 | không có chữ Hán (số, ký hiệu) → giữ nguyên |
| `untranslated` | **8.454** | giữ chữ Trung của CY; liệt kê ở `_manifest\gui_dict_untranslated.tsv` cho đợt dịch sau |

Tổng 154.776 khoá (46 khoá trùng bị bỏ, giữ dòng đầu như TLBB_DBC). Tỷ lệ có tiếng Việt hoặc trung tính: **94,5%**.

Chữ trong **layout**: 15.093 giá trị `Text/Tooltip/ColumnHeader`, trong đó 349 có chữ Hán; 145 được dịch bằng khớp
đúng (110 file), 204 còn lại giữ chữ Trung. Chữ trong **Lua**: 6.614 literal còn chữ Hán — **chưa dịch**, vì Lua so
sánh chuỗi nên cần bộ lexer và các luật loại trừ của `apply_clientlua.py` (việc đợt sau).

Mã hoá: Lua CY được chuyển GBK→UTF-8 khi đưa vào CanonicalCY (1.671 file GBK, 220 file đóng gói + GBK, 145 file đã
là UTF-8 giữ nguyên, 6 file đóng gói + UTF-8, 1 file trộn mã hoá xử lý theo dòng). Layout giữ nguyên mã hoá gốc
(ASCII/UTF-8/UTF-8 BOM/UTF-16). Khoá tài nguyên và tên file vẫn theo quy tắc GBK/cp1252 của dự án.

---

## 6. Lớp GUI CY trong `Assets\CanonicalCY` (DoD 3)

`Tools\pipeline\build_canonical_cy.py` **1.1** thêm `--gui cy|gl` (mặc định **cy**):

- Giữ nguyên byte CY cho mọi file `InterfaceFolder` trừ bốn phép biến đổi có ghi trong `files.tsv` (cột `source`):
  `[unpacked]`, `[gbk->utf8]` (Lua), `[font+noto65001]` (8 file `.font`), `[layout-vi(n)]` (chữ hiển thị).
- Sinh thêm: 3.784 file imageset tách từ `all.imageset.xml`, `StrDictionary.txt` tiếng Việt, `StrFilter.txt` rỗng,
  `Schema\NotoSansSC-Regular.ttf` (chép từ Canonical, đúng sha của file người dùng đưa).
- `ConfigFolder\InterfaceEx.txt` giữ **byte CY** (10 cột) → hợp với struct `_DBC_UI_LAYOUTDEFINE` của nhánh cs1-tables.
- File của lớp GUI cũ không nằm trong kế hoạch được **dời** sang `Assets\CanonicalCY\_backup_gui_gl_<stamp>\`
  (`_manifest\gui_moved.tsv`), **không xoá**. Lần chuyển 14/09 dời 3.911 file GUI GL.

Kết quả chạy thật **[DK]**: 112.512 file / 21.470.742.307 B; `--verify --deep` **112.512/112.512 OK, 0 file thừa**;
chạy lại `--apply` ghi 0 file (idempotent). Lỗi duy nhất trong `errors.tsv`: `DressPaint_sp.lua` có 4 dòng trộn mã
hoá được giữ nguyên byte.

---

## 7. Kết quả CysUiViewer trên CanonicalCY (DoD 4)

| Lượt | Vẽ được | Sạch lỗi | Nạp hỏng | Kiểu chưa đăng ký | Lỗi layout |
|---|---:|---:|---:|---:|---:|
| `census-all-1` (trước khi cài widget CY) | 2.016/2.032 | 1.989 | 16 | 18 | 114 |
| `census-all-2` (sau widget CY) | 2.031/2.032 | 2.019 | 1 | **0** | 101 |
| `census-all-3` (sau khi bổ sung thuộc tính + dịch layout) | **2.032/2.032** | **2.024** | **0** | **0** | **15** |

Mọi lượt: 3.784 imageset tạo được / 0 hỏng, **0 texture thiếu**, 8/8 font engine nạp, 20/20 looknfeel, 0 crash.
15 lỗi còn lại đều là **lỗi dữ liệu của chính CY**: 7 ảnh imageset không tồn tại (`QiXi_StoryLetter_2/*`,
`Anniversary2/Anniversary_Left_Pic`, `XSYNew02/HXL_*`), 5 animate không có trong `wowanimate.xml`
(`XinShouNew`), 1 `ChannelBkg` sai cú pháp (ChatFrame), 2 biểu thức chính quy hỏng trong Editbox
(`BW_CreateTeam`, `Anniversary`).

---

## 7b. Game.exe trên lớp GUI CY (DoD 5) **[DK]**

- Gate `check_dbc_layout.py --strict --data CanonicalCY --gl-data Canonical`: **PASS 63 OK** (InterfaceEx CY 10 cột,
  CampAndStand giữ GL), không cần `--allow-pending`.
- Smoke đăng nhập offline 75 s (`smoke-2`): 0 fatal, 4/4 mốc PASS, 4 PNG; 9 `CYS Lua failure` hồi phục được và 13 lỗi
  UI đều là dữ liệu CY (`QiXi_StoryLetter_2`, `ChannelBkg`).
- Replay thế giới (`replay-8`): vào cảnh 2 `dali_new_320`, HUD CY hiện (thanh menu, ô kỹ năng, khung chat).
- Hai lỗi chặn đã sửa trên đường vào world: (1) look `TLBBLook_CreatureBoard` đặt `MinHeight` lên CheckBox và
  `MapImage::setChildImage` ném khi ảnh thiếu → ngoại lệ trong MainLoop; (2) **rò ngăn xếp Lua có sẵn ở main**
  (`LuaState::BoxPointer` không pop, `lua_dostring` để LUA_MULTRET) → mọi script kiểm tra thất bại `StackCapacity`
  sau ~8.000 ô, HUD không dựng; cs1-tables (GUI GL) cũng có 2.859 lỗi này. Sửa bằng `lua_gettop/settop`.

## 8. Bẫy


---
