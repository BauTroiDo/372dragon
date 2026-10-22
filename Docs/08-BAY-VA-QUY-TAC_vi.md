# 08 — Bẫy đã gặp và quy tắc bắt buộc

**22/09 — đồng bộ túi phải kiểm cả identity và thứ tự gói.**
`GCItemInfo` chỉ cập nhật chi tiết object đã có; khi chuyển/đổi loại vật phẩm,
phải tạo/đổi identity bằng `GCNotifyEquip` trước. Bộ kiểm container51/51 vẫn bỏ
lọt lỗi này; `Build/Logs/2026-09-22-inventory/live-B-1-060756` bắt được tại bước
sắp xếp. Hai ca kiểm thứ tự gói cùng lượt live chạy lại mới xác nhận sửa đúng.
Ngoài ra, hộp rơi đã gộp stack khi tạo nên không được cộng1 rồi xóa cả hàng nguồn;
63ca cuối kiểm cả bảo toàn số lượng và GUID nguồn khi nhặt/hái lượm.


Mỗi mục đã từng làm hỏng dữ liệu hoặc làm game crash, hoặc được đo trực tiếp. Không mục nào ở đây là suy đoán. Ai làm việc trong `CY-Source` phải đọc tài liệu này trước khi đụng vào dữ liệu hay mã nguồn.

Cột **Xử lý** cho biết dự án mới đối phó thế nào:

| Mã | Nghĩa |
|---|---|
| **MÃ** | Sửa tận gốc trong mã nguồn engine/client, để bẫy biến mất ở bản dựng mới. |
| **DL** | Luật của dữ liệu. Định dạng hoặc khoá do dữ liệu quyết định, phải giữ nguyên. |
| **KT** | Phải có bộ kiểm tự động trong pipeline (`Tests\validators`). |
| **VH** | Quy tắc vận hành hoặc thử nghiệm. |

---

## QUY TẮC 0 — HỌC TRƯỚC, SỬA SAU (20/09/2026)

> **Trước khi sửa hay thêm bất cứ thứ gì: nếu đã có phiên bản SỐNG làm được việc đó, đi đọc nó
> trước. Rồi phản biện. Chỉ áp dụng khi thật sự hợp.**

Quy tắc này đứng trên mọi mục còn lại trong tài liệu, vì nó quyết định **cách** làm chứ không phải
một cái bẫy riêng lẻ. Người dùng đặt ra sau khi thấy bản đồ lớn bị vá mò trong khi đáp án nằm sẵn
trong Lua của client gốc:

> *"hãy học tập thay vì sửa lung tung, tôi đã cung cấp cho bạn rất nhiều phiên bản sống, cái nào
> không biết bạn chỉ cần học tập, phản biện, phù hợp thì áp dụng"*

### Ba bước, theo đúng thứ tự

| bước | việc | không được bỏ qua |
|---|---|---|
| **1. HỌC** | Tìm chỗ phiên bản sống làm đúng việc đó, đọc **cách nó làm** — cả mã, cả dữ liệu, cả Lua. | Chưa đọc xong thì chưa được viết dòng sửa nào. |
| **2. PHẢN BIỆN** | Hỏi **vì sao** nó làm vậy; nó **ngầm giả định** điều gì; giả định đó ở cây ta **còn đúng không**. | Giống nhau về hình thức không có nghĩa giống nhau về tiền đề. |
| **3. ÁP DỤNG CÓ ĐIỀU KIỆN** | Hợp thì áp. **Không hợp thì ghi rõ vì sao không hợp**, rồi mới chọn đường khác. | "Không hợp" phải viết ra thành câu, không được im lặng bỏ qua. |

### Các phiên bản sống đang có

| cây | là gì | quyền |
|---|---|---|
| `C:\TLBB\085\client` | client 0.85 gốc | **CHỈ ĐỌC** (quy tắc 06/09) |
| `C:\TLBB\085\client_GL` | thế hệ GL | **CHỈ ĐỌC** |
| `C:\TLBB\085\Tools\DATA NEW\CY Game` | CY 3.71 — đích parity | **CHỈ ĐỌC** |
| `\\wsl.localhost\TLBB\home\ubuntu\GameServer` + `\Game_2` | server gốc | không sửa nếu đích là server clone |

### Ca đã chứng minh quy tắc — bản đồ lớn vẽ thành vòng tròn (20/09)

Mỗi ô bản đồ bị cắt thành hình tròn, giữa các vòng là nền đen. Điều phối đi dò biến toàn cục
`g_nLastSceneSharp` trong mã của **chính ta** — sai hướng. Đọc client sống thì mười phút ra đáp án:

```lua
-- client/Data/InterfaceFolder/SceneMap/SceneMap.lua:509-511  (client_GL và CanonicalCY giống hệt)
if (sceneID == GetSceneID()) then   SceneMap_Board:SetSceneFileName( sceneX,sceneY,filename , 1)
else                                SceneMap_Board:SetSceneFileName( sceneX,sceneY,filename , 0)  end
```

Tham số thứ 4 nghĩa là **"đây có phải cảnh tôi đang đứng không"** — Lua của CY chú thích thẳng
`是否显示人物箭头` (*có hiện mũi tên nhân vật hay không*). Mã 0.85 đặt tên nó là `nUserSharp` rồi đổ
vào `setUserSharp()`, mà `enum UserSharps { LookLikeSquare, LookLikeRound }` cho **`LookLikeRound == 1`**.
**Hai ý nghĩa khác hẳn nhau va vào cùng một con số.**

Bước **phản biện** cũng trả công ngay: client gốc ép `m_nXCount = 1; m_nYCount = 1` — một cửa sổ duy
nhất, elip nội tiếp to hơn khung nhìn nên không ai thấy đường cong. Tiền đề đó **đã đổi** ở cây ta
(lát 25 ô 256 px). Chép nguyên hành vi sang thì hỏng; hiểu tiền đề rồi mới biết phải bỏ cờ đi.

Và bước **học** còn xác nhận một điều ta suýt sửa oan: cả ba cây đều dùng cùng bộ ô
`jpg_<cảnh>_<x>_<y>.dds` 5×5. **Cách lát ô của ta đúng, ảnh nguồn đúng** — chỉ một lời gọi vẽ sai.
Nếu không học trước, rất dễ đi viết lại cả đường nạp ảnh.

### Vì sao quy tắc này đáng giá hơn nó trông

- **Rẻ**: đọc cây tham chiếu tốn phút, dựng lại và đo một lượt live tốn giờ.
- **Nó chặn đúng lớp sai lầm đắt nhất**: sửa mò vào mã của chính mình thì mỗi vòng thử đều cần một
  lần dựng + một lượt live, và cổng kiểm vẫn xanh trong khi ta đi sai hướng.
- **Nó ghép với luật đo đếm**: *"phép đo có THẬT SỰ chạy không?"* hỏi về **bằng chứng**; quy tắc 0
  hỏi về **nguồn tri thức**. Một cái chặn kết quả giả, một cái chặn giả thuyết giả.

### Không được dùng quy tắc này để

- Chép mù từ cây tham chiếu mà bỏ bước phản biện — tiền đề có thể đã đổi (ca trên là ví dụ).
- Ghi vào `client` hay `client_GL`. Chúng **CHỈ ĐỌC**. Mọi thay đổi vào `CY-Source`.
- Lấy một địa chỉ binary từ tài liệu mà không kèm **tên bản dựng + sha256** (quy tắc 22.8).

- **12/09, P1-1:** Game.exe trả rc 0 cả khi ném C++ exception; phải đọc dump/log, không dùng rc một mình. Đã unwind 10 frame Render trước → 15 frame CEGUI font sau; bằng chứng `Build/Logs/2026-09-12-gpt-p1-1/baseline-stack-report.md`.
- **12/09, P1-1 font:** SongTiBmp12.font có 2 biến thể CP936/CP1258 dưới `<Fonts>`; bỏ qua wrapper sẽ nạp sai biến thể (backend Bitmap chỉ 12/16 và cố định CP936). Ba font YouYuan tiếp theo dùng cặp file NeedCode; bằng chứng `Build/Logs/2026-09-12-gpt-p1-1/font-proposal/proposal_vi.md`.
- **12/09, Lua counters:** log missing host function chỉ ghi tên một lần, không thể xếp hạng tần suất; generator xóa file cũ trước khi sinh. Dùng thư mục Build mới và so byte; bằng chứng `Build/Logs/2026-09-12-gpt-p1-1/lua-counts-plan.md`.


- **12/09, P1-2 timer/Lua:** DoString gọi `_ALERT` không protected, còn C++ exception qua Lua setjmp có thể bỏ cleanup; timer dùng LoadBuffer/PCall, native lỗi không vào VM lại và chuyển fatal sau TimerProc (`Docs/specs/lua/timers_vi.md`; 40+1 ca trong `Build/Logs/2026-09-12-gpt-p1-2/tests/timers/run-20260912-220005-6174857`).
- **12/09, Lua 5.0.1 GC:** `luaL_checkudata` trả null khi sai metatable, không tự ném như bản Lua mới; phải kiểm null trước đọc userdata. Ca ngoại lai đã tái hiện và kiểm lại trong timer tests 40/40.

- **12/09, P1-2 item DBC:** đuôi .txt không chứng minh file text:4 bảng item là binary. Checker đọc readline báo LONG giả. Alignment x64 cũng không phát hiện INT→INT sai nghĩa: CommonItem nRule đọc giá bán ở9.694 dòng. Không nối NewItem trước khi chốt schema/mapping; `Docs/specs/lua/display-items_vi.md` và `Build/Logs/2026-09-12-gpt-p1-2/action-items/data-compatibility_vi.md`.

- **12/09, LuaPlus5 metatable:** `lua_getmetatable` luôn có default; kiểm riêng identity default trước khi thêm method vào userdata. Query test phát hiện24/25→25/25 sau sửa, `Tests/luaapi/query_tests.cpp` và log `tests/queries/run-20260912-222544-2508840`.


## 1. Mã hoá ký tự, tên file, chuỗi

- **13/09, từ điển đăng nhập:** Canonical GL là UTF-8 hai cột STRING/STRING; Reference là GBK ba cột INT/STRING/STRING. Phải chọn schema/encoding theo header, không bỏ cột hoặc đoán lại GBK khi UTF-8 hỏng; 23/23 ca tại `Build/Logs/2026-09-13-gpt-wsl-ui/dictionary-3`.
- **13/09, StrFilter rỗng:** zero byte không phải DBC hợp lệ; giữ hai dòng schema và bỏ riêng các quy tắc theo yêu cầu người dùng, có backup/hash. `Tools/data/empty_strfilter.py` và `Build/Logs/strfilter-empty`.
- **13/09, atlas Noto:** kiểm chiều dọc chỉ khi wrap ngang làm glyph Việt cao hơn ghi vượt đáy256×256; canary10→0 pixel sau sửa, font59/59. `Build/Logs/2026-09-13-gpt-ui-properties/{atlas-before,atlas-after}`.
- **13/09, heap/capture:** WIC WriteSource là nơi phát hiện heap hỏng, chưa chứng minh nơi gây lỗi; PNG có tên hợp lệ nhưng toànzero vẫn phải loại. Dump/25frame unwind tại `Build/Logs/2026-09-13-gpt-wsl-ui/baseline-stack-3570203.txt`, ba probe WIC độc lập giải mã khớp từng byte.
- **13/09, menu CEGUI0.4.1:** Event destructor không invalidate connection còn giữ; ItemListBase thiếu removeChild đối ứng có thể giữ item đã cleanDeadPool. Phải kiểm hủy popup/item theo cả hai thứ tự và destroyAll, không bỏ teardown để unit xanh; `Docs/specs/ui/login-properties_vi.md` batch3.
- **13/09, fixture widget:** Header và Segment không được dùng chung factory DefaultWindow vì cùng đăng ký SortDirection; test sẽ failfast trước ca đầu. Factory riêng và bước chuẩn bị glyph như đo hàng thật đưa bộ MCL tới118/118; `Build/Logs/2026-09-13-gpt-ui-properties/tests-13` giữ lỗi, `tests-16` là kết quả đạt.
- **13/09, stage/CI:** stage.ps1 có thể thoát0 dù manifest ghi CI FAIL; luôn kiểm cờ CI và SHA, không suy đạt từ mã thoát. prepare_game đã từ chối stage f65e0a2 bị lỗi compile; commit2a05b22 mới CI36/36. `Docs/specs/ui/login-integration-20260913_vi.md`.
- **13/09, runner smoke:** gọi trực tiếp bằng PowerShell 7 thiếu System.Drawing.Bitmap và dừng trước GPU. Dùng Windows PowerShell (`powershell -NoProfile -ExecutionPolicy Bypass -File Tools/build/smoke.ps1`); đạt 6/6. Lỗi gốc giữ tại `Build/Logs/2026-09-13-gpt-wsl-ui/smoke-pwsh7-startup.txt`.
- **13/09, quan sát WSL:** connect-close để dò port tạo request rỗng/lỗi HTTP và cluster; status đọc LISTEN trong `/proc/net/tcp*`, không phát kết nối. `Tools/server/provision_test_wsl.py`, `Docs/specs/net/wsl-test_vi.md` ghi trước/sau log và ownership PID thật.

| # | Bẫy / quy tắc | Xử lý | Nguồn |
|---|---|---|---|
| 1.2 | `all.material`, `all.obj`, `all.effect`, `all.particle`, `all.skill` là **GBK**, phải sửa ở mức byte. Một lần đọc `errors='replace'` rồi ghi đè đã phá 60.161 material. | DL + KT (kiểm round-trip từng byte) | bộ nhớ `tlbb-allmaterial-gbk-trap` |
| 1.3 | Khoảng 24.000 tên file trên đĩa là byte GBK hiển thị theo cp1252 (mojibake). Engine mở chúng bằng `CreateFileA` dưới ACP 1252, nên đổi ACP sang UTF-8 là hỏng hết tên file. Muốn đổi tên sang GBK thật: `name.encode('cp1252')` → `.decode('gbk')`, riêng các byte 0x81/0x8D/0x8F/0x90/0x9D giữ nguyên. | **MÃ**: lớp tài nguyên mới đổi tên GBK sang UTF-16 rồi gọi `CreateFileW`, không phụ thuộc ACP | `tlbb-vietnamese-input-ansi-window`, `tlbb-datacy-vs-gl-compare` |
| 1.4 | Ô đường dẫn/khoá trong bảng (kể cả bảng đã UTF-8) phải **giữ GBK**. Pipeline dịch từng dịch nhầm khoá tài nguyên và phá 2.617 ô ở 11 cột (SpecialDressEffect, GemEffect_Cloth, Bullet…). | DL + KT | `tlbb-dbc-binary-tables`, `tlbb-locator-translation-bug` |
| 1.5 | Tên nằm bên trong file model (material, skeletonLink, tên animation) phải là GBK. Không Việt hoá `ActionSet/ActionSetKV.txt`. | DL | `tlbb-model-binary-and-import` |
| 1.6 | Cửa sổ game là ANSI dưới ACP 1252, nên tiếng Việt gõ vào đã thành `?` trước khi tới mã game. Hiện đang chữa bằng vá import A→W cộng `injectChar(codepoint)`. | **MÃ**: cửa sổ Unicode (API W), CEGUI nhận codepoint UTF-32 | `tlbb-vietnamese-input-ansi-window` |
| 1.7 | Game.exe có `g_CodePage` riêng, bị bảng `System_District` ép về 936. Hiện vá 4 byte tại file `0x97CD84`. | **MÃ** | `tlbb-gameexe-district-codepage` |
| 1.8 | CEGUI chỉ nhận các code page {874, 936, 949, 1251, 1252, 1254, 1258}: 65001 bị ép về 936, và chữ bị hạ về 936 trước khi tra glyph (bẫy best-fit Ê→ê). Kiểm bằng 12 dòng "Font created" trong `CEGUI.log`. | **MÃ** | `tlbb-codepage-patch-offsets` |
| 1.9 | Tiêu đề cửa sổ phải là ASCII vì tEngine hạ chuỗi wide về GBK. | **MÃ** | `tlbb-window-title-patch` |
| 1.10 | UTF-8 làm chuỗi dài ra khoảng 1,5 lần. Lỗi `Read Packet Size error[N]`, với N là ID gói, nghĩa là chuỗi vượt ngưỡng của client. Ngưỡng đã đo: tên 30 B, tài khoản 50 B, IP 24 B, mô tả GCNewPlatform 1–31 B, chữ ký GCPrivateInfo ≤ 34 B, danh hiệu < 34 B, shop ≤ 200 món mỗi gói. Phía server hiện chỉ có 2 chỗ gọi `truncate_utf8_bytes`. | **MÃ** (client mới nới/kiểm biên), KT (server cắt UTF-8 an toàn) | `tlbb-platform-packet-crash`, khảo sát server 12/09 |
| 1.11 | `Patch\LoginServer.txt` mã hoá kiểu SEPCIAL_FILE_HD (XOR theo `rand` MSVC với seed 0x19830716/0x19811004/0x19840528). Launcher ghi đè lại bằng GBK mỗi lần mở, nên sau đó phải chạy `Sua-ManChonServer.cmd`. | **MÃ**: client mới đọc cấu hình UTF-8 rõ ràng | `tlbb-serverlist-encrypted` |
| 1.12 | Server: `txtreader.lua` đổi `gbk.toutf8` cho **cả dòng**, vô điều kiện. Vì vậy bảng server **phải GBK**: một ô UTF-8 lẻ byte sẽ nuốt tab và làm lệch cột mà không báo lỗi. Kiểm bằng `fix_server_utf8_rows.py check`. | DL + KT | `tlbb-cy4-rasoat-2026-09-10` |
| 1.13 | `wire_charset.lua` ở chế độ utf8 là hàm đồng nhất. Không thay `preloader.lua` (gây vòng require và crash liên tục). Tên NPC/quái được dịch tại wire qua `wire_names_vi.lua` (5.904 mục, ≤ 29 B mỗi mục). | DL, VH | `tlbb-server-wire-charset`, `tlbb-wire-name-translation` |
| 1.14 | perl/sed đổi CRLF thành LF trên file Lua/XML/cfg, phải chuẩn hoá lại. File `.ps1` cần UTF-8 BOM. Heredoc bash dài hay làm hỏng regex/Unicode, nên viết script ra file rồi mới chạy. | VH | `tlbb-graphics-overhaul`, `tlbb-windows-tooling-gaps` |
| 1.15 | **Mới (12/09):** mã nguồn 0.85 chứa literal tiếng Trung dạng GBK, đóng vai khoá tài nguyên (tên locator, animation, file). Khi chuyển mã nguồn sang UTF-8 phải biên dịch với `/source-charset:utf-8 /execution-charset:.936`, để literal vẫn ra đúng byte GBK. | **MÃ** | tài liệu `04` mục 3 |

## 2. Model, mesh, skeleton, animation

| # | Bẫy / quy tắc | Xử lý | Nguồn |
|---|---|---|---|
| 2.1 | `.mesh` là `[MeshSerializer_v1.40]` (đọc được v1.10–v1.30). Mesh của Ogre ≥ 1.7 bị từ chối. `.skeleton` là `[Serializer_v1.10]` cộng chunk riêng **0x4120** (u16 count, u16 flags: bit0 quay, bit1 dịch, bit2 co giãn). Chunk này có sẵn trong mã nguồn 0.85 (`OGRE\OgreMain\include\OgreSkeletonFileFormat.h:88`). | DL | `tlbb-model-binary-and-import`, khảo sát mã nguồn |
| 2.2 | Trường `size` của `M_MESH`/`M_SUBMESH`/`M_GEOMETRY` sai sẵn trong file gốc, nên phải đọc tuần tự. `size` của chunk BONE là 36/48 và không tính tên. `size` của 0x4120 = 8 + count × stride (lệch 4). | DL + KT | như trên |
| 2.3 | Keyframe là **độ lệch so với bind pose**: pos = bind + tr, rot = bind × q. Chạy 25 fps, trục Y hướng lên, mặt trước CCW, gốc UV trên-trái (trùng glTF). | DL | như trên |
| 2.4 | Giới hạn: 65.535 đỉnh mỗi submesh; ≤ 4 xương mỗi đỉnh; **≤ 74 xương dùng trong một submesh** (`MAX_SKIN_BONE_NUM` trong `ShaderLib\ParamNamedAuto.inc`). Tổng xương của cả skeleton thì không giới hạn. Con số "12.813 tam giác" chỉ là quan sát; giảm lưới theo nó đã làm hỏng model Goku. | DL + KT. MÃ ở pha vượt ngang: shader có thể nâng giới hạn 74 | như trên |
| 2.5 | Hộp bao trong `.mesh` chỉ tính theo tư thế bind, nên model bay hoặc có animation dời gốc sẽ bị cắt: chạy `expand_mesh_bounds.py`. Tuy vậy locator phải tính từ **đỉnh bind**, không tính từ hộp bao đã nới. | KT. MÃ: engine mới tính bounds theo animation | như trên |
| 2.6 | `Locator qx qy qz qw` là **trục + góc (radian)**, không phải quaternion. | DL | như trên |
| 2.7 | Server không gửi `model_id` cho quái hay trân thú. Quái gửi `怪物编号`; trân thú gửi `data_id`, rồi client tra `PetAttrTable` cột 51 → `MonsterAttrEx.外型ID` (GL cột 44 / CY cột 36) → `CharModelEx` (cột 9 = ActionSet) → `all.obj`. | DL | như trên |
| 2.8 | Chuỗi ActionSet: `ActionSetFile` → `ActionSet.txt` (4 cột) → `ActionSetLine` (line_id + 9 cột theo loại vũ khí + c10/c11 cho pet/quái + …) → `ActionSetKV` (tên track, GBK). Đếm lệch một cột là tra ra animation sai. | DL + KT | `tlbb-model-load-pipeline` |
| 2.9 | `DefaultAnimation`/`InsertAnimation` trong `all.obj` tranh xương với ActionSet làm model giật. Trân thú cần đủ 9 animation chuẩn (站立 休闲 休闲2 跑步 受击 倒地 攻击 攻击2 远程攻击) và `步行速度` 1500. | DL + KT | `tlbb-obj-animation-attrs-vs-actionset` |
| 2.10 | Rig người chơi của 085 và CY giống hệt nhau. Animation tư thế của CY giấu xương vũ khí ở Y −9000 (đao tổ một lưỡi). | DL | `tlbb-cy4-rasoat-2026-09-10` |
| 2.11 | Bảng tư thế cầm vũ khí gốc có 11 ô. Hiện đã vá Game.exe lên 15 ô (19 chỗ vá, bản ghi 0x1c→0x24). | **MÃ**: bảng động trong `ActionSetMgr` | `tlbb-actionsetline-15slot-patch` |
| 2.12 | Model GL: `.ske` là cây JBCF không có bind pose. `.ani` chạy 40 fps, quaternion smallest-three 6 byte dùng nguyên; chỉ liên hợp quaternion của tư thế tham chiếu. Skin (ma trận nghịch bind) nằm ở đuôi `.mesh`. | DL | `GL REAL\03-dinh-dang-da-be\07-…` |
| 2.13 | JX3/KSword3D: pháp tuyến trong file là rác; lật trục Z nhưng giữ thứ tự chỉ số; ma trận thế giới lấy theo xương. | DL | `jx3-ksword3d-format` |
| 2.14 | Blender: trục Y cục bộ luôn dọc theo xương; file `.blend` có thể lưu một pose đè lên rest pose; 1 đơn vị Blender ≠ 1 đơn vị game (đo được 1 : 1,6). | VH | `tlbb-model-binary-and-import` |
| 2.15 | `material=""` trong `all.obj` nghĩa là dùng material ghi bên trong `.mesh` (thường gặp ở vũ khí), nên phải đọc chuỗi trong `.mesh`. | DL | `tlbb-model-load-pipeline` |
| 2.16 | **Mới (12/09):** nhiều file có đệm 1–12 byte ở cuối: DataCY 18.431 file, CYHJ 12.610, `client_GL` 978. Đệm có thể là byte 0 hoặc rác. Khi so hay chép, dùng độ dài suy từ định dạng (cột `fmt_len`, `sha256_content` trong `Assets\Staging\index`), **không** dùng kích thước thô. Cắt về `(list)` − 96 của CY Game thì khớp từng byte. | KT | `Assets\Staging\index\s2_vs_s4_summary.txt` |
| 2.17 | **Mới (12/09):** `all.obj` có tên object lặp (S1: 5, S2/S4: 8); `all.material` của S2/S4 lặp 184 tên material. Khi gộp phải chọn một bản và báo xung đột. Engine gốc lấy bản nào thì chưa kiểm. | KT | như trên |

## 3. Material, shader, texture, renderer

| # | Bẫy / quy tắc | Xử lý | Nguồn |
|---|---|---|---|
| 3.1 | Parser material đọc theo dòng: mỗi dòng một từ khoá, thụt lề bằng TAB. Sai là OgreMain crash, và log Fairy dừng ở `error.dds`. | **MÃ**: parser chịu lỗi và báo số dòng; KT | skill `tlbb-add-model` bẫy 1 |
| 3.2 | Template material nằm trong `Data\MaterialTemplates.zip`. Dòng B/C có 114 file HLSL SM3 (PBR, dissolve, CalcShadow, AntiAlias); bản 0.85 có 17 file Cg SM1–2. Nên dùng `Mtl_Character_PSLit` thay `_Lit`; bậc cao hơn là `Mtl_OutlineCtrl_FlowLight` và `PBRChara`. Đổi file zip làm `NewMaterialTemplateMD5` đổi theo, và ShaderCache bị làm mới. | DL. **MÃ**: engine mới phải hỗ trợ đúng cơ chế template + auto-param của B/C | `tlbb-model-material-shaders`, khảo sát binary |
| 3.3 | Texture rải ở `MaterialFolder`…`Material5Folder`, mesh/skeleton ở `ModelFolder`…`Model3Folder`; dòng B/C còn có thêm khe Model4–8/Material6–8/Scene2. Tiền tố `jpg_`/`tga_`/`png_` cho biết định dạng gốc. | DL. MÃ: resource group | `tlbb-model-load-pipeline`, khảo sát binary |
| 3.5 | Upscale texture: realesrgan-ncnn chạy chế độ thư mục trả ảnh lệch tên (133/651 ảnh hỏng), nên phải gọi từng file với `-j 1:1:1` rồi kiểm MAD vùng đục ≤ 25. Tham số `-s 2` với x4plus làm hỏng ảnh; alpha phải tách riêng. Loại khỏi upscale: texture UI trong `MaterialFolder/Common` và mọi tên có mặt trong InterfaceFolder. Brush địa hình upscale vô ích (atlas ô cố định). | KT, VH | `tlbb-graphics-overhaul` |
| 3.5b | **Mới (12/09):**<br>• Real-ESRGAN (x4plus) biến vân dệt/dither trong vải nén DXT1 thành **lưới ô cứng**; phép kiểm MAD không thấy vì thu nhỏ lại thì lưới biến mất. Cần bộ dò lưới (hỏng khi điểm > 0,40, cần xem khi > 0,30) và làm mờ nhẹ trước khi upscale; khi đó vân biến mất và vải trơn hơn.<br>• Vùng alpha trong suốt hoàn toàn bị trả về alpha 1–11 (lớp mờ trên tóc), nên phải giữ nguyên giá trị của vùng alpha phẳng.<br>• `-t 512` cho ra ảnh rác và trùng lúc driver NVIDIA reset.<br>• Chỉ nên upscale ảnh vẽ tay nén DXT3 và texture nhỏ 64–256 px; bỏ tóc ≤ 64 px và texture hiệu ứng/mask. | KT, VH | `Tools\pipeline\upscale_pack.py`, `Assets\Staging\upscale\2026-09-12\summary.json` |
| 3.5c | **Mới (12/09), client_GL:**<br>• 2.626 ô material không-ASCII trong `ItemVisualChar` là UTF-8, còn tên trong `all.material` là GBK, và game dùng nguyên byte của bảng → material không bao giờ được áp. 373 ô là biến thể màu nên đang hiện sai (vd. IVC 130–142, 685).<br>• **Quy tắc:** mọi cột khoá tài nguyên trong bảng (mesh/material/obj/effect/skeleton) phải giữ GBK.<br>• Trang phục/tóc 2026 dùng skeleton mở rộng (56 xương + 6–24 xương vật lý, file `.dynbone`), LogicModel 0.85 chưa đọc được. | KT, VH | `Build\Logs\2026-09-12-avatar\summary.json`, `Tools\pipeline\avatar.py` |
| 3.5d | **Mới (12/09):** `all.obj` hiện đại ghi `BoundingBox` 6 số "min max", trong khi bản 0.85 chỉ nhận 3 số "rộng cao sâu" và **ném ngoại lệ** → model không được tạo, viewer ra khung trống. Đã sửa ở 587f4ff: nhận cả 3 lẫn 6 số, sai định dạng thì bỏ qua. **Quy tắc:** mọi thuộc tính lạ của bản hiện đại phải được bỏ qua kèm log, không bao giờ ném ngoại lệ làm hỏng cả model. | KT | `Build\Logs\ci\dd597ff\smoke\viewer\M25.png.log` |
| 3.5e | **Mới (13/09), hiệu ứng/hạt:**<br>• Tài nguyên có tên chữ Trung dạng Unicode thật (vd. file lấy từ S2/DataCY) **không mở được**, vì engine dùng API ANSI với ACP 1252, chỉ khớp tên kiểu mojibake "byte GBK đọc như cp1252" giống client_GL. Stage 91148e1 có 15.757/23.664 file như vậy → lá/cánh hoa hiện ô trắng, hiệu ứng thiếu mesh bị mất. **Quy tắc:** mọi stage/dữ liệu phải đặt tên theo quy ước mojibake như Canonical, và phải kiểm rằng mọi tham chiếu đều mở được.<br>• Hạt dùng shader ps_3_0 của B (`Particle_PS`, `_ColorX2_PS`, `_ColorX4_PS`) ra trắng cháy, mất màu hoặc vô hình. Hạt fixed-function thì đúng.<br>• ColourFading của B có khoá độ mờ `opacity0..5` (17.572 dòng); bản 0.85 không có.<br>• Census cũ chạy trong OgreSmoke không nạp ParticleFX2 nên sai số liệu: phải đo bằng runtime thật. | KT, VH | `Docs\specs\render\07-fx-audit_vi.md`, `Registry\fx\census-*.tsv` |
| 3.6 | Render.dll của B có 29 post-filter (compositor) nhưng runtime chỉ bật 4. Hiệu ứng chỉ bật khi biến **đổi giá trị** (có sự kiện), không bật từ cfg lúc khởi động. Ánh xạ khoá: `View_Aplomb` = VSync, `View_Fanhunjiao` = FXAA, `View_HDRFilter` = NewHDRBloom. NewHDRBloom cần file `<scene>.newhdrbloom` 34 B: 4 float **Intensity, Threshold, SoftKnee, Exposure** (thứ tự đúng theo đặc tả 12/09; ghi chú cũ gọi sai tên), sau đó 2 byte cờ UseHDR và UseAutoExposure, rồi màu bloom RGBA. HDR bị stub cứng ở slot +0x2e0; shadow map có sẵn nhưng mọi chỗ gọi đều truyền 0. | **MÃ**: bật theo cấu hình ngay khi khởi động | `tlbb-graphics-overhaul` |
| 3.7 | Tài nguyên nạp đồng bộ (`ResourceBackgroundQueue` tắt) gây giật; nghẽn thật là số model trong AOI (bán kính 20, không giới hạn). Mỗi lần nạp scene tạo RT bóng 4096² cộng 4 cascade 2048². Hook bật lại hiệu ứng ở mỗi scene gây thêm một lần giật thứ hai. | **MÃ**: nạp nền, giới hạn/LOD model, cấu hình cỡ shadow map | `tlbb-graphics-overhaul`, `tlbb-bot-scale-limits` |
| 3.8 | Màn đăng nhập luôn 1024×768 bất kể độ phân giải cấu hình, nên muốn kiểm đồ hoạ phải vào thế giới. | VH. MÃ | `tlbb-graphics-overhaul` |
| 3.9 | Game.exe xoá log Fairy cũ khi khởi động, nên phải chép log cần giữ trước khi chạy lại. | VH. **MÃ**: xoay vòng log | như trên |
| 3.11 | **Mới (12/09):** template trong `MaterialTemplates.zip` của `client_GL` phần lớn **chỉ có pixel shader** (ps_3_0): `Mtl_Particle.material` có 0 tham chiếu vertex program; `Mtl_Character.material` có 12 VS so với 109 FS. Engine của B tự ghép vertex shader tương ứng (Model_Skin_VS, Model_VS, Particle_VS…). Engine 0.85 không ghép nên model hiện thành bóng trắng, hạt không hiện. D3D9 không cho chạy ps_3_0 cùng xử lý đỉnh cố định. | **MÃ** (agent material, pha E2) | báo cáo TlbbViewer 12/09, `Build\Logs\2026-09-12-viewer` |
| 3.10 | **Mới (12/09):** texture nhánh CY (S2 = S4) cùng kích thước, định dạng và số mip với bản HJ/GL, nhưng đã bị **nén lại** (khác byte ở mọi cặp mẫu). Vì vậy "cùng texture" phải so theo nội dung đã giải nén, không so hash file. Trường thứ hai trong `(list)` của AXP không phải CRC, nên không dùng để kiểm nội dung được. | KT | `Assets\Staging\index\index_summary.json` |

- **12/09, P0-5:** viewer chỉ phát thời gian script ≥100 ms; script vắng log không có nghĩa mất 0 ms. Cache Ogre sau scripts khác tổng cuối lượt (80fc02c: 209/0 → 209/1). Giữ rõ mốc và số thiếu là null. Bằng chứng: `Tools/build/test_ci_timings.ps1`, `Build/Logs/2026-09-12-gpt-p0-5/agent-tests/regression-1/results.json` (13/13).
- **12/09, P0-3:** viewer đã cài cache từ a47aff7; cache ấm không đồng nghĩa đạt tốc độ engine ≤30%. Đo 399 hit/0 miss và all.material 13.563 ms; engine 52,37% của lạnh. Bằng chứng: `Build\Logs\2026-09-12-gpt-p0-3\pair-195345\measure.json`.

## 4. Hiệu ứng, hạt, kỹ năng, đạn

| # | Bẫy / quy tắc | Xử lý | Nguồn |
|---|---|---|---|
| 4.1 | `all.effect` **không có cú pháp chú thích**. Một dòng lạc ở mức ngoặc 0 làm parser âm thầm bỏ mọi thứ phía sau; triệu chứng là một cục màu đỏ cam. | **MÃ**: parser báo lỗi; KT | `tlbb-effect-file-parser-trap` |
| 4.2 | Object Effect trong `.Scene` không được mang `scale`. | DL | `tlbb-map-lol-buildings` |
| 4.3 | `Position` của element được tinh chỉnh theo model gốc. Hiệu ứng thường trực phải lặp; hiệu ứng `时装_*` chạy một lần. | DL | bộ nhớ trân thú/thời trang |
| 4.4 | Chuỗi hiệu ứng: `<Effects>` trong obj → `all.effect` (element Particle, …, `ParticleSystem`, `ParEffectName`, `ColEffectName`) → `all.particle` → `all.material` → `.dds`. | DL | `tlbb-model-load-pipeline` |
| 4.5 | Chuỗi kỹ năng: SkillData (c1 = template×100 + cấp) → SkillTemplate (c35 = đạn) → `Bullet.txt` (DBC; c3 = bay, c6 = trúng); ImpactSEData c14/c15 = tia. Kỹ năng trân thú được quay số lúc tạo, nên sửa bảng không áp lại cho pet cũ. 133/193 đạn từng hỏng vì tên effect bị dịch. | DL + KT | `tlbb-pet-skill-bullet-system` |
| 4.6 | Nhập kỹ năng CY: `HitTime -1` hoãn đạn tới cuối animation, chiêu có đạn cần `HitTime` trong `all.skill`. Thiếu effect dẫn tới crash `NULL != m_pCharacterData`. `aura_rune_projector%d` đánh số theo môn phái và chỉ có 0–12. | DL + KT. **MÃ**: engine mới không crash khi thiếu effect | `tlbb-cy4-rasoat-2026-09-10` |
| 4.7 | Cột 19 (impact ID) của EquipBase CY va chạm với impact của 085 (百念朝周 biến thành buff cưỡi thỏ). Đã đặt −1 cho 208 món. | DL + KT | như trên |
| 4.8 | `.pu` của GL (JBPU nhị phân, 8.015 file) chưa bẻ được, nên hiệu ứng GL phải dựng lại bằng hệ hạt Fairy. | DL | `GL REAL\01` §2.6 |
| 4.9 | Dòng B/C có thêm 3 element (RibbonTrail, CameraShake, Line), 5 affector (RevoluMove, Dissolve, SequenceFrame, PolarMove, UvAnim) và tham số `dissolveBox` (chỉ có ở C). Mã nguồn 0.85 **không có** các thứ này. | **MÃ** (pha E2) | khảo sát binary 12/09 |

## 5. Bản đồ, scene, địa hình, navmesh

| # | Bẫy / quy tắc | Xử lý | Nguồn |
|---|---|---|---|
| 5.1 | Định dạng, đã kiểm khớp byte trên 499 map:<br>• `.Heightmap` MHEF, rộng = xsize + 1.<br>• `.GridInfo` IGEF, 5 hoặc 7 B mỗi ô; đây là dữ liệu sơn, không phải mặt nạ đi lại.<br>• `.WCollision` v1 (file rỗng = 8 B).<br>• `lightmap.png` = xsize × 8.<br>• `Color.tga` = xsize × 2, 32 bit; sai là crash trong d3dx9_43. | DL + KT | `tlbb-map-scene-format` |
| 5.3 | Nhân vật đứng trên `.Heightmap`, không đứng trên mesh. Ô minimap tên `jpg_<cột 11 của SceneDefineEx>_<X>_<Z>.dds`, 64 ô bản đồ cho mỗi ô texture. Nước là object `TerrainLiquid`; cỏ là StaticEntity `0灌木` (11.685 cây từng gây lag nên đã gỡ). | DL | `tlbb-character-stands-on-heightmap`, `tlbb-map-minimap-and-nav`, `tlbb-map-water-and-grass` |
| 5.4 | ID scene phải tăng dần, nhưng `client_res` lớn gây `bad allocation` (vì vậy scene 1052 được sửa tại chỗ). Tên map phải ASCII. Danh sách scene thật của server là `SceneInfo.ini`; nếu scene đích không có service thì người chơi rơi về Đại Lý. 413/1.289 scene thiếu `.scn`. | DL + KT | `tlbb-map-summoner-rift`, `tlbb-full-audit-2026-09-10` |
| 5.5 | Nhập OBJ thành map có 9 điều bắt buộc. | DL | `tlbb-map-scene-format` |

## 6. Giao diện, CEGUI, Lua client

| # | Bẫy / quy tắc | Xử lý | Nguồn |
|---|---|---|---|
| 6.1 | Chỉ imageset liệt kê trong `WoWLookSkin.scheme.xml` mới được nạp, và CEGUI nạp imageset trước looknfeel bất kể thứ tự ghi. 67–68 lỗi trong `CEGUI.log` là baseline. | DL + KT | `tlbb-client-gl` |
| 6.2 | Đổi diện mạo toàn game bằng ánh xạ WidgetLook: đã có 68 look GL; `TLBB_MainFrame1` phủ 359 cửa sổ, `TLBB_ButtonCommon` phủ 1.747 nút. | DL | `client_GL\README-GL_vi.md` |
| 6.3 | Ảnh `NormalImage` của `TLBB_ButtonNULL` chỉ hiện khi bằng **đúng** cỡ ô. Look ButtonNULL vẫn vẽ Text, nên phải đặt `Text=""` khi đã bake chữ vào ảnh. | DL. MÃ: sửa widget | như trên |
| 6.4 | Nền chèn thêm cần `RiseOnClick=False` và `ZOrderChangeEnabled=False`. `Position`/`Size` kiểu cũ là **tỷ lệ**. `UnifiedPosition` thiếu dấu `}` là định dạng gốc, đừng "sửa". Property mới chèn ở **cuối**. | DL | như trên |
| 6.5 | Có 2.381 container kích thước theo tỷ lệ, nên không được nới khung cha; tràn chữ thì rút gọn bản dịch. GLResponsive đã bị gỡ vì làm hỏng điều khiển nhân vật. | DL, VH | `tlbb-ui-relayout-project`, `AGENTS.md` |
| 6.6 | `TLBB_MainFrame_*` kiểu BoundWindow tắt `FrameEnabled` nên không vẽ ảnh của con. Muốn container trong suốt thì dùng `TLBB_StaticImageNULL` với ảnh `Blank`. | DL | `tlbb-client-gl` |
| 6.7 | Font: giữ Noto Sans SC, vì `zt_1..3.ttf` của GL thiếu dấu tiếng Việt. Cỡ font tính bằng POINT (SongTiBmp12 = 16 px); ô chữ tiếng Việt cần ≥ 24 px. Chữ bake vào nút dùng arialbd (msyhbd thiếu dấu). | DL | như trên |
| 6.8 | Client chỉ tạo cửa sổ theo danh sách native: thêm dòng vào `InterfaceEx.txt` không tạo được cửa sổ. FakeObject/`SetRabbitModel` chỉ chạy khi đã vào thế giới. | **MÃ**: client mới đăng ký cửa sổ theo dữ liệu | `tlbb-model-viewer-project` |
| 6.10 | Lua client là LuaPlus/Lua 5.0.1 **có mở rộng `continue`** (`LuaPlus\Src\LuaPlus\src\llex.c:51`, `lparser.c:1419`), không có toán tử `#`. `luac` chuẩn báo lỗi ở `continue` là bình thường. | DL. MÃ: giữ nguyên LuaPlus này | khảo sát mã nguồn 12/09 |
| 6.11 | Parser layout tự viết từng đọc cả thẻ nằm trong `<!-- -->` (MainMenuBar có một LeftBar bị chú thích trùng tên); đã sửa bằng regex COMMENT. | KT | `tlbb-client-gl` bước 18 |

## 7. Bảng dữ liệu và ID

| # | Bẫy / quy tắc | Xử lý | Nguồn |
|---|---|---|---|
| 7.1 | Bảng DBC nhị phân, magic `00 CC BB DD`: header, kiểu cột (0 int, 1 float, 2 offset chuỗi), rồi pool chuỗi. | DL | `tlbb-dbc-binary-tables` |
| 7.2 | Bảng text phía client: header GBK, thân UTF-8, xuống dòng CRLF; **ID tăng dần nghiêm ngặt**, sai là `curIndex < lastIndex`. Server đọc theo tên cột và chịu được bảng không sắp xếp, nhưng bảng server **phải GBK**. `Exterior_TS` phía server có 28 cột, phía client 27. | DL + KT | `HUONG-DAN-THEM-LOAI-VU-KHI…` §0 |
| 7.3 | Ánh xạ cột CY → GL/085:<br>• EquipBase 103 → 101: cột 0–17 giữ; 18–20 ← CY 100–102; 21–24 ← CY 18–21; 25–100 ← CY 24–99.<br>• ItemVisualLocator 63 → 53 (lệch +10 từ cột 19).<br>• PetAttr 54 → 51.<br>• MonsterAttrEx 73 → 71 (cột model CY 36 / GL 44).<br>• CharHairGeo 14 → 13; Exterior_Hair 10 → 9; ActionSet 15/19.<br>CYHJ091026 dùng bố cục cột của GL nhưng có thêm EquipBase Type 27 (thời trang) và Type 43 (tọa kỵ). | DL + KT | `tlbb-cy4-weapons-import`, `tlbb-pet-add-2026`, `tlbb-cyhj-compare` |
| 7.4 | **Không so theo ID giữa các nhánh**, mà so theo tên mesh/obj. ID mới phải còn trống ở cả client lẫn server, trên mọi Type. Item ID có dạng `10 Q TT NNN`; server suy Type bằng `floor(id % 100000 / 1000)`. | DL + KT → `Registry` | `tlbb-datacy-vs-gl-compare`, `tlbb-mount-add-pipeline` |
| 7.5 | Thời trang: `Visual` = index EquipDress → ItemVisualChar. Tọa kỵ: `Visual` = index CharMount, nhưng model khi cưỡi lấy từ `骑乘ID` ở StandardImpact logic 14. CharMount cột 5 là tỉ lệ vẽ thú (0,6). | DL | `tlbb-costume-add-pipeline`, `tlbb-mount-add-pipeline` |
| 7.6 | Shop: server chỉ hiện 50 ô đầu; phải cập nhật cột 11 `Num`; PMAX đặt −1; ≤ 200 món mỗi gói. `ShopTable` phía server có 1.227 cột, phía client 11 cột. | DL + KT | như trên, khảo sát server |
| 7.7 | Hiện đã có khoảng lệch ID giữa server và client: EquipBase 948 dòng chỉ có ở server, SkillData_V1 1.268, MonsterAttrEx 310, PetAttr 202, CharMount 19 (số cột 14/15). | KT | khảo sát server 12/09 |
| 7.8 | `PetAttrTable.id` = `MonsterAttrExTable.id`. Cột 2/3 của PetAttrTable không phải model. | DL | `tlbb-datacy-vs-gl-compare` |

## 8. Server, giao thức, vận hành

| # | Bẫy / quy tắc | Xử lý | Nguồn |
|---|---|---|---|
| 8.1 | Khởi động lại server: chỉ dùng `./start_zone.sh stop && ./start_zone.sh all`, không dùng `run.sh`. Xác nhận bằng `ps -o lstart= -C Game_tlbb_2`. Nạp scene mất khoảng 75 s; đừng kết luận thất bại trước mốc 900 s. Phía Windows dùng `wsl\Start/Stop/Status-TLBB.cmd`. | VH | `tlbb-server-restart`, `AGENTS.md` |
| 8.2 | Reload chỉ có cho scripts, equip_base, monster_attr_ex, shop_table, std_impact, drop_rate, …, và còn bị cache sharetable/codecache làm mất tác dụng, nên phải `clearcache`/inject. `lualib`, PetAttrTable, CommonItem, CharTitleNew và `exterior_*` phải restart. Lỗi hay gặp: dùng `skynet.send` ở chỗ cần giá trị trả về. | VH | `tlbb-server-restart`, `tlbb-full-audit-2026-09-10` |
| 8.3 | Token tự đăng nhập chết sau mỗi lần restart server. Người dùng tự gõ mật khẩu, **không bao giờ gõ hộ**. Không mở client khi người dùng đang chơi (cùng tài khoản sẽ bị đá). File `Accounts\System.cfg` thắng hai file cfg còn lại. Chạy bằng `Bin64\Game.exe -fl` với thư mục làm việc là Bin64. | VH | `tlbb-client-launch-login`, `tlbb-system-cfg-precedence` |
| 8.4 | Đổi scene là một lần đăng nhập lại thu nhỏ: key mới, obj_id mới. AOI bán kính 20 không giới hạn số model, nên vài trăm model gần nhau làm client crash. | **MÃ** | `tlbb-arena-pk`, `tlbb-bot-scale-limits` |
| 8.5 | Giao thức đang chạy **không phải 0.85**: 24/24 ID mẫu lệch số. Header skynet gồm 3 trường u16; login ở cổng 5733 rồi sang game 5734; phiên bản đăng nhập "0x705 → 0x785". `LCRetCreateChar` của client không có case 7 (server đã dời enum sang 8). | DL. **MÃ**: client mới sinh codec từ đặc tả | khảo sát server 12/09, `tlbb-createchar-error-360` |
| 8.6 | MongoDB 4.4.31 chỉ bind 127.0.0.1; chỉ chạy khu 1; không ghi mật khẩu vào bất cứ đâu. | VH | `AGENTS.md` |
| 8.7 | Bản gương `.codegraph-src` cũ hơn server thật (chưa có `wire_charset.lua`), nên với mọi thứ liên quan mã hoá phải grep bản sống trong WSL. **Không bao giờ sửa trong `.codegraph-src`.** | VH | khảo sát server 12/09, `CLAUDE.md` |

## 9. Môi trường và công cụ

| # | Quy tắc | Nguồn |
|---|---|---|
| 9.1 | Python Windows: `C:\Program Files\Python313\python.exe` (hoặc `py -3`), đặt `PYTHONUTF8=1`. Bộ `model-convert`/`map-convert` chạy bằng python3 trong WSL. Git Bash làm hỏng `/mnt/c` và `$`. Trao đổi file WSL↔Windows qua `/dev/shm`. | `tlbb-windows-tooling-gaps`, kiểm tra máy 12/09 |
| 9.2 | PowerShell 5.1 chặn `npm.ps1`/`npx.ps1`, nên gọi `npm.cmd`/`npx.cmd`. | `CLAUDE.md` |
| 9.4 | Sửa script Python bằng Edit/Write, không qua heredoc Bash (`\1` trong chuỗi bị đổi thành byte 0x01). | `tlbb-client-gl` |
| 9.5 | **12/09, ChatGPT:** CI cũ dùng checkout force; stage và metadata CI có xóa file ngoài git. Đã thay bằng kiểm cây sạch và quarantine có move.json; không chạy bản script cũ dưới luật thép. | `05098ff`, `Build\Logs\2026-09-12-gpt-p0-1\safety-test.txt` (9/9), CI 33/33 và smoke 6/6 |

## Bẫy hotkey (12/09/2026)

- `MainMenuBar_DoAction(index,FALSE)` thực thi skill ở nhả F1–F10. Hủy phím phải gọi `MainMenuBar_CancelPrepare` mới, chỉ bỏ prepare; giữ latch đến keyup kể cả khi Lua bật lại. Spec `Docs/specs/lua/hotkeys_vi.md`,24 ca.
- Fixture LuaPlus: hủy LuaObject trước LuaState; BoxPointer đẩy giá trị lên stack nên chỉ chốt mốc stack sau khi publish box. Test cuối24/24; lần thử23:05 lỗi fixture23/24 được giữ nguyên trong Build, không thay kỳ vọng.

## Bẫy font Noto UTF-8 (12/09/2026)

- Phải chọn CodePage **trước** khi tạo backend: SongTi scheme ghi Bitmap nhưng nhánh65001 là FreeType. Chỉ bỏ wrapper `<Fonts>` rồi nạp mọi `<Font>` sẽ trùng tên/sai backend.
- Noto được cung cấp thiếu6 dấu tách rời; dùng NFC cho nhãn/danh sách, giữ ô nhập và mã điều khiển. Không chuẩn hóa tên tài nguyên/all.* hoặc cột khóa GBK. Đọc `Docs/specs/ui/fonts_vi.md`;41 ca và ảnh NFC/NFD bằng nhau.
- CysUiViewer adapter từng che lỗi font; kiểm bằng `--strict-fonts`. Sau sửa native15/15,0adapter,2lỗi init cũ. Game4font qua rồi thiếuBeHit;rc0 vẫn là crash, phải đọc dump/log. CI quarantine stage chỉ giữ metadata, không giả định còn đủDLL; kiểm SHA bản sao trước khi dùng baseline.


## Bẫy BeHit/UI đăng nhập offline (13/09/2026)

- Scheme hiện đại dùng TLBB_BeHitBoard với BeHit.txt 20 cột. Không tạo layout giả để lấp BeHit.layout.xml. ID+100 là biến thể; giữ nhánh cũ cho scheme legacy. Spec: `Docs/specs/ui/login-offline_vi.md`.
- Star/AnimateImage/SafeIME thiếu factory lần lượt chặn ChatFrame/MainMenuBar/LogOn. StaticImage và Button có offset IFalagardAnimate khác nhau: Lua Play phải cross-cast có kiểm tra. Clipboard cần kiểm ở IME trước cả copy/cut/paste.
- Giảm MaxTextLength phải lặp khi độ dài lớn hơn giới hạn. `mbcs_length` là quy ước lịch sử TLBB, không phải số byte UTF-8 hay số code point.
- OGRE 1.2 writeContentsToFile dùng GetFrontBufferData, có thể chụp app khác khi Game ẩn. **Không dùng JPG81557ef làm ảnh Game.** Capture cuối đọc DDBACKBUFFER trước Present, thực hiện ở Render.dll. C export trả BOOL/log lỗi; không ném C++ qua /EHc. Game không link trực tiếp OGRE: `0b6e3eb` lỗi include, `bb67e6a` sửa ranh giới plugin.
- RC0 vẫn có thể là Game bị terminate sau exception. Sau rethrow, dump chỉ còn 9 frame unwind; phải đọc kèm UISystem/WXRender.log. Có PNG chưa đủ: phải xem nội dung ảnh và xác nhận đúng màn tài khoản.
- UI đỏ cùng một câu cảnh báo không phải thiếu glyph Noto. StrFilter baseline 6 cột/Canonical 3 cột, nhưng `_DBC_TALK_FILTER` chỉ đọc 2 cột. Áp mọi quy tắc trước markup sẽ trúng chữ A/số trong khóa từ điển. Cần phục hồi nghĩa flags/ngữ cảnh, không tắt lọc hoặc xóa quy tắc để che lỗi. Evidence: `Build/Logs/2026-09-13-gpt-p1-1/filter-schema-evidence.json`.

## Bẫy host bàn phím ảo (13/09/2026)

- SetSoftKeyAim phải phát SET_SOFTKEY_AIM qua hàng đợi và đăng ký tên sự kiện trước PreLoad; ID B 1ba không phải ID CY. Giữ 303 ID cũ, thêm sự kiện ở ID 303; spec `Docs/specs/lua/login-hosts_vi.md`.
- Cửa sổ được nạp khi nhận sự kiện đầu tiên. Lượt này mở thêm SoftKeyBoard nên lộ10 lỗi thuộc tính vốn có (563→573); cùng SHA layout và DLL không làm các lỗi đó biến mất. So cả census, phạm vi layout đã chạy và lỗi Lua; không bỏ log/thuộc tính để báo UI đạt.
- GetServerAreaDis đọc mô tả riêng của vùng, không phải tên vùng. Reader UTF-8 plaintext đã có ở d1b2c16; xem bẫy vùng dưới đây.

## Bẫy vùng đăng nhập (13/09/2026)

- B lấy mô tả cột 7 từ lần gặp tên vùng đầu tiên, kể cả rỗng; cột 12 nhóm 0/1 thuộc view normal, nhóm 2 không thuộc view này. INI lịch sử không có mô tả. Không dùng tên vùng thay mô tả hoặc cập nhật mô tả theo server sau.
- Game ưu tiên Patch/LoginServer.txt UTF-8 plaintext. File hiện đại lỗi phải báo lỗi, chỉ fallback WXLoginServer.txt khi không tồn tại. Không đưa file bọc SEPCIAL_FILE_HD hay danh sách endpoint thật vào Game offline; reader CY chưa giải mã wrapper/failover. Spec `Docs/specs/lua/login-areas_vi.md`.
- Khi kiểm offline, phải kiểm cả 4 endpoint của danh sách modern trước launch; chỉ kiểm INI là chưa đủ khi modern được ưu tiên. Preflight 6/6 tại `Build/Logs/2026-09-13-gpt-login-areas/preflight/results.json`, không tiến trình Game được tạo.
- Lua đúng byte mô tả chưa chứng minh nhãn Game hiển thị đúng: 2 lượt legacy/modern đều 573 lỗi UI và ảnh giống pixel; nhãn StrFilter vẫn sai. Không dùng missing 2→0 để nhận toàn UI hoặc đăng nhập thật đã đạt.


## Bẫy tích hợp GL và WSL test (13/09/2026)

- CampAndStand có16 camp trong DATA; template cũ nhận ID bằng capacity12, ghi52byte đè con trỏ database và44byte ngoài manager. Stack CEGUI/WIC là nơi phát hiện muộn. Chặn ID bằng/vượt capacity và đọc đủ16 quan hệ; test canary11/11, mutant10/11. Xem Docs/specs/ui/gl-login-heap-camp_vi.md.
- Ba cặp layout/Lua GL đúng byte chưa đủ closure: cần looks, atlas thuộc Material2–5Folder và SoundInfo2108/music/cangshan.mp3. Giữ byte GBK của bảng và backup profile. Thiếu sound từng ném native exception trước capture; xem baseline-stack-native-1.txt trong Build/Logs/2026-09-13-gpt-gl-login.
- Missing host0 không đồng nghĩa Lua chạy xong: native CheckButton thiếu FlashMe làm close SelectServer dừng trước Hide, trong khi text phía sau vẫn nhận input. Kiểm cửa sổ che đã ẩn, Lua status và ảnh; không nhận raw UTF-8 PASS thay cho hình hiển thị. Flash16/16 và Toggle73/73 tại thư mục log GL.
- LuaPlus fork ánh xạ nil metatable về defaultmeta và getmetatable luôn trả1; phục hồi identity thực/stack qua C API. Native unwind có thể làm VM không dùng lại được; marker riêng phải đi qua host CloseWindow mà không chuyển thành lua_error. Checked16/16+2child, Docs/specs/lua/checked-execution_vi.md.
- LuaObject phải bị hủy trước LuaState sở hữu; fixture ToggleWindow từng giữ globals của state tạo sau trong biến có lifetime dài hơn. Không có dump lần crash nên chỉ khẳng định lỗi lifetime trong source, không suy stack. Tests bật RUN/unbuffered để giữ ca cuối khi fail.
- WM_KEYDOWN do SendMessage không tự sinh WM_CHAR, và MouseTick dùng GetAsyncKeyState; harness nhập qua HWND riêng, chuột qua đúng CEGUI injection có gate. Không SendInput hoặc di chuyển chuột desktop. Xem Docs/specs/ui/gl-login-input_vi.md.
- TTY Python kế thừa PSMODULEPATH từ PowerShell7 có thể làm Windows PowerShell5.1 không tìm được Get-FileHash. Lọc tên biến không phân biệt hoa/thường chỉ trong environment child, chọn powershell.exe hệ thống; hai lỗi preflight xảy ra trước hỏi mật khẩu hoặc tạo Game. getpass phải coi GetPassWarning là lỗi để không fallback echo; không đưa credential vào argv/file.
- StrFilter rỗng là ngoại lệ người dùng đã duyệt ngày13/09, chỉ profile CY test; giữ header/schema và0rule. Không suy thành quyền xóa bộ lọc client_GL hoặc thay server gốc. WSL chỉ clone riêng, credential chỉ bộ nhớ; số socket lấy mẫu2giây có thể bỏ lỡ phiên auth ngắn, cần counter/event thực.
- GamePro_Login gọi baseTick trước PumpModernLogin; LOGIN_CONNECTING dùng chung sẽ đẩy NetManager legacy vào WaitConnecting dù không tạo socket/handle cũ. Gate theo chủ sở hữu modern thực tại TickGameLoginProcedure, giữ UI/baseTick. Server flag0 có thể đã thành công trước client crash; phân biệt auth server, callback main và màn hình thật, xem gl-login-integration-20260913_vi.md.
- Bẫy ở baseline bc363c3: GetCurSelectRole đọc state riêng; B empty khởi tạo0, khác deletion index. Khi đó camera/MoveToCharacter/record modern chưa nối và NetCore đóng socket sau charlist. Bản tạo CY đã thêm session Interactive, scene và chọn record theo GUID; vẫn phải phân biệt chọn để hiển thị với charlogin/vào thế giới chưa triển khai.
- Game.rc dùng TSGame.ico cho cả IDI_GAME/IDI_SMALL và CMake phải có dependency icon. CreateMainWnd từng lấy IDD_GAME_DIALOG làm hIcon; kiểm cả resource payload và handle của đúng cửa sổ. Đọc sau process timeout cho danh sách rỗng, không suy icon bị lỗi.

## Bẫy khôi phục màn tạo/chọn nhân vật CY gốc (13/09/2026)

- CY C dùng cảnh chính `tl3chuangjian.Scene` cho cả tạo và chọn; MeshWindow/`Common/MeshBack.dds` là nền RTT của widget GL, `Bg_Info` là nền loading, không thay thế cảnh/bục gốc. Đối chiếu `Build/Logs/2026-09-13-gpt-create-role/original-reference/original-routing_vi.md:33` và `:72`; chưa coi closure tài nguyên là đã đạt hình ảnh trong Game.
- Công thức preview GL `2644 + sex*12 + ordinal` không dùng cho DATA CY S2 vì ID2664..2667 là sói; native CY dùng `4950 + sex*15 + ordinal` (nữ0, nam1; ordinal0..14), lấy model cột chính, không nhầm ordinal nút với ID môn phái server. Bằng chứng `Build/Logs/2026-09-13-gpt-create-role/original-reference/original-routing_vi.md:58` và `:64`, bảng đầy đủ `s2-sect-preview-rows.json` cùng thư mục.
- `default` và `chuangjiannan` là trạng thái sky sphere, không phải tên camera/file camera: B Gfx+320→Render192f0, C Gfx+348→Render31870; camera đi tuyến mode/track riêng. Bằng chứng `Build/Logs/2026-09-13-gpt-create-role/original-reference/original-routing_vi.md:70`.
- Không bỏ thư mục con khi đóng tài nguyên GBK→CP1252: `OgreFileSystem.cpp:409` giữ nguyên request có prefix, fallback basename chỉ áp dụng tên không chứa dấu phân cách tại dòng414; model còn thử đường dẫn tương đối ở `Src/Engine/WXCore/Core/WXResources.cpp:127`. Nguồn đầy đủ `Src/Engine/OGRE/OgreMain/src/OgreFileSystem.cpp`; kiểm Win32 trước0/138→sau138/138 tại `Build/Logs/2026-09-13-gpt-create-role/original-reference/scene-plan/prefix-win32-verification.json`, không phải xác nhận Game/GPU.
- Scene dựng tăng dần: 64 object ở frame đầu rồi một object mỗi frame sau (`Src/Engine/WXCore/Core/WXSceneInfo.cpp:14`, `:59`); 389 object cảnh này vào hàng đợi, được ưu tiên theo khoảng cách, nên không kết luận thiếu cảnh từ ảnh ngay sau Scene_Load. Đối chiếu `Build/Logs/2026-09-13-gpt-create-role/original-reference/scene-plan/native-runtime-review_vi.md:9`.

- Camera_Main là thuộc tính có sẵn nhưng không có hint trong model CY; WXLogicModel từng bỏ setter khi hint rỗng, nên readback giữ chuỗi ID 1 thay vì 0.95;5.4. Sửa đúng nhánh thuộc tính, không bỏ readback: `Docs/specs/ui/create-role-appearance_vi.md`, GPU lỗi `Build/Logs/2026-09-13-gpt-create-role/offline-a6ed37d`.
- CharCreate Init được gọi lại; camera legacy phải nằm sau nhánh CY return, nếu không nó ghi đè pose ở lần Init thứ hai. Prefix descriptor nên dùng sizeof(literal)-1; zoom gốc trừ speed khỏi zoomFactor. Bằng chứng `Build/Logs/2026-09-13-gpt-create-role/profile/native-controller-review.json`.
- Generic SetWXObjectProperty("scale") không áp dụng với LogicModelObject vì lớp chỉ có logic-model-name, setter trả false bị caller bỏ qua; phải dùng LogicModel::setScaleFactor và đọc lại scene node. GPU8dd7b95 đã qua thao tác nhưng model còn scale1; c106472 thêm bridge/readback, `Src/Engine/WXRender/RenderSystem.cpp`.
- Actor_SetUIVisibleFlag gọi MovementType vô điều kiện và Apply gọi lặp làm 92 dòng thuộc tính thiếu ở GPU8dd7b95. Model CY mặc định Normal nhưng không khai báo thuộc tính legacy; giữ một lần khởi tạo và chỉ đổi thuộc tính khi hasAttribute, không tắt log unknown-property chung. Xem `Src/Engine/WXRender/Object/RFObj_Actor.cpp`, `Build/Logs/2026-09-13-gpt-create-role/census-8dd7b95-1`.
- Shader legacy Character_HardwareSkinning_PS_1_1_hlsl cần D3DXSHADER_ENABLE_BACKWARDS_COMPATIBILITY trên D3DX43; nguồn không đổi, flags đã nằm trong cache key. Probe trước HRESULT0x80004001/X3539, sau S_OK/228byte/ps_2_0; giữ đầy đủ hai compiler warning trong `Build/Logs/2026-09-13-gpt-create-role/original-reference/scene-plan/shader-compat-1`. Không nhầm Error8 WXTerrainType fallback đã có từ baseline với lỗi shader mới.
- FontBase bẻ dòng theo codepoint nên câu Việt có thể bị chẻ giữa từ; dùng câu ngắn và LF ở ranh giới câu trong controller, giữ geometry/art. Đo Noto chỉ là kiểm dự phòng, phải xem ảnh Game: `Docs/specs/ui/create-role-profile_vi.md`.
- GameProcedure gọi CharCreate::Init để nạp trước catalogue ngay lúc khởi động; nạp scene ở đây làm cảnh tạo tràn ra nền đăng nhập. Chỉ Enter(Create) khi GetActiveProcedure()==this, vẫn giữ nạp catalogue/model; GPU bf4a79b xác nhận scene chỉ mở khi chuyển màn, ba ảnh login cố định trùng RGB baseline. Bàn phím ảo xáo chữ có sai khác riêng, không dùng ảnh đó để nhận full-pixel PASS.
- MeshSerializer readBoundsInfo gọi _setBounds(box,true), mỗi lần import cộng padding1%; converter import→export→import sẽ lệch bounds dù vertex/index nguyên. Chỉ tiến trình CPU chuyển hai mesh chim đã pin SHA dùng MeshManager padding0; Game vẫn giữ padding chuẩn. So snapshot byte bằng tuyệt đối (declaration/buffer/index/bone/material/alias/bounds/skeleton), không nới ngưỡng. mesh-upgrade-1 giữ FAIL, mesh-upgrade-2 PASS2/2 tại Build/Logs/2026-09-13-gpt-create-role; nguồn S2 không đổi.
- Trong smoke, CysUiSmokePointer đi thẳng vào CEGUI nhưng MouseTick vẫn đọc GetCursorPos/GetAsyncKeyState của desktop rồi inject cùng endpoint. Lượt WSL bf4a79b ghi thay chân dung trong12 giây harness không bấm, sau đó assertion thất bại trước submit; không có log nguồn input để quy cho người dùng. a272cbe chỉ bỏ polling chuột thật khi g_cysGlLoginSmoke, giữ cầu nhập/WM_CHAR và đường mở Game bình thường; snapshot role-post-create-attempt1 xác nhận0 nhân vật, phải kiểm dữ liệu trước chạy lại.
- Sau CREATE_ROLE_OK không chọn count−1: packet319 có thể đổi thứ tự. Native so GUID với danh sách cũ, chọn đúng một GUID mới; refresh thường giữ GUID còn tồn tại, Lua đọc GetCurSelectRole. a114125 có21 ca record và8 ca controller, gồm [A,B]→[B,C,A]/[C,B,A]; không nhầm fixture này với bằng chứng GPU đủ ba slot.
- Game đăng ký cluster trước khi nạp scene nhưng chỉ online sau đó. Tool online trong khoảng này sẽ bị bỏ lỡ nếu manager chỉ broadcast tới các node đã online; Game có thể đăng nhập được nhưng create chết ở `.textfilter` trước ghi DB. Bản vá clone replay peer cùng group khi node mới online; kiểm nguyên Lua tái hiện race và cache proxy. Không sửa packet522 hoặc tăng timeout để che lỗi; xem `Tools/server/repair_test_cluster_routes.py` và `Build/Logs/2026-09-13-gpt-create-role/net/textfilter-route-repair_vi.md`.
- Debug console COMMANDX.run thực thi hàm trong pcall rồi mới gọi table.tostr; console không nạp formatter này nên có thể báo lỗi sau khi lệnh đã chạy. Không suy CMD Error thành không có tác động. Wrapper một lần trả mã chẩn đoán cho phép và phục hồi identity formatter; kiểm actual debug_console bằng `Tests/net/cluster_route_console_tests.lua`. Không ghi raw reply, cấu hình hoặc credential vào bằng chứng.
- Skynet fork cache loadfile theo đường dẫn, không xét mtime khi cache hit. Helper thay nội dung cùng tên có thể vẫn chạy bytecode cũ. Công cụ phục hồi chỉ đọc file đã kiểm bằng io.open/read có giới hạn rồi load(text), không clear cache toàn dịch vụ. Console đã start cũng không require module cluster có init gọi RPC qua C require; query clusterd hiện có và giữ contract sender/req. Evidence activate4→5, console36/race40 tại gốc log tạo nhân vật.
- CysUiCopyWindowTextUtf8 chỉ đọc Editbox/MultiLineEditbox. Nhãn tên CY là FalagardSimpleText; dùng getter ô nhập làm smoke fatal dù DB đã lưu đúng nhân vật. 5a2fb6a thêm reader SimpleText riêng, giữ input getter; native28/28, gồm UTF-8 và buffer bounds. Không sửa nhãn UI hoặc tạo lại record để bù lỗi kiểm thử.
- WXClient.log mở append, khác WXRender/UISystem mở trunc. Tái dùng stage phải archive log cũ trước launch và giữ hash; nếu không exact-one auth/create gate bị lẫn các lượt. Runner91148e1 có prior-logs và validator tách riêng với nguyên gate byte-identical. Với lượt cũ đã chạy, chỉ tách suffix khi chứng minh prefix bằng byte và mọi timestamp thuộc cửa sổ run; giữ rawrun và fatal thật.
