# Thuộc tính UI đăng nhập native — 13/09/2026

**Mới nhất 30a9611:** CI 36/36; Game 61,41 giây/28 layout/UI Error 0/missing 0; font 59/59 và widget 126/126 trên DLL CI; probe nền D3D9 26/26. Giữ lỗi và bằng chứng các batch dưới làm lịch sử. Bố cục GL và thao tác trong thế giới chưa xác nhận; xem `login-integration-20260913_vi.md`.

Batch tiếp theo P1-1, theo yêu cầu sửa lỗi hiện có và mở UI cần cho đăng nhập. Chỉ ghi trong CY-Source; dùng CEGUI/Falagard thật, NotoSansSC-Regular.ttf và CP65001. Không sửa client_GL, không chạy DLL B, không bật GLResponsive. Phần WSL, StrFilter, dictionary và kiểm thử Game do tác vụ tích hợp quản lý.

## Baseline và phạm vi

`Build/Logs/2026-09-13-gpt-login-areas/smoke-modern/UISystem.log` có 573 dòng Error. Batch này triển khai đường xử lý cho các nhóm tương ứng 555 dòng; đây là phân loại baseline, **chưa phải kết quả đếm log Game sau tích hợp**.

| Nhóm baseline | Số dòng | Hành vi được triển khai |
|---|---:|---|
| ClickSound | 352 | Window phát ID được khai báo qua callback khi click trái hợp lệ; -1 tắt. Callback đi qua tUISystem/UI_CEGUI tới sound host, tháo trước sound shutdown. |
| AnimateId | 100 | Tra ID trong AnimateManager, lấy ảnh đầu và alpha, reset mốc thời gian; -1 xóa; ID thiếu không phá animation trước. |
| UseDefaultTooltip | 35 | Chặn hoặc cho phép tooltip hệ thống, giữ tooltip riêng; bỏ target cũ khi tắt mặc định. |
| FrameEnabled / BackgroundEnabled | 26 | BoundWindow dùng FalagardStaticImage, vẽ và bật/tắt hai lớp look thật. |
| HorzFormatting / VertFormatting | 19 | DragTitle dùng FalagardSimpleText để vẽ chữ đúng căn lề; giữ kéo parent và nhả capture. Khởi tạo drag target rỗng. |
| SelectBrush / SelectColour | 10 | Listbox áp dụng style cho hàng đang có và hàng mới add/insert. Combobox lưu style trước khi auto children sẵn sàng, sau đó chuyển xuống droplist. |
| NormalImage | 4 | SoftKeyWindow vẽ nền các nhóm phím thường, Back, Return, Shift. Hover/Pushed thiếu ảnh tùy chọn không dereference null; kiểm chỉ số trước tra resource. |
| ChannelBkg | 3 | Vẽ ba ảnh left/middle/right theo ba named area, lặp theo từng hàng kênh. Descriptor sai được báo rõ và giữ ảnh cũ. |
| MinHeight | 3 | SelfFitWindow giữ chiều cao tối thiểu cả khi text rỗng; từ chối âm hoặc không hữu hạn. |
| HoverColor | 1 | Màu ARGB thật trên ảnh hover; chấp nhận 8 hex có/không tiền tố 0x và giữ đủ alpha. |
| ChildItem | 1 | ChatHistory dùng factory khai báo `key:ChatBoard name:TYPE`, kiểm native type khi tạo thay vì hardcode scheme WoWLook. |
| Common imageset | 1 | Bỏ hai lần hardcode Common/HoverTextBak trong đường Listbox/Combobox của UILuaControl; giữ đường MultiColumnList cũ; hàng danh sách nhận brush/màu của look đang dùng. |

Không gắn thuộc tính trống để che log. Còn **18 lỗi baseline chưa được xử lý trong batch**: BtnAnimation 16, BoardKillTimer 1, LightEnable 1. Các nhóm này được giữ là việc chưa đạt để kiểm tiếp sau build tích hợp.

## Kiểm thử batch

Build native x64 Release, tối đa 2 jobs, tree riêng `Build/cmake/gpt-login-ui-props`, target `cys_ceguifalagard`, components `freetype;expat;cegui;falagardex`: **rc 0**, `Build/Logs/2026-09-13-gpt-ui-properties/build-6.log`. Các log lỗi trung gian được giữ để truy vết; không dùng chúng làm kết quả đạt.

Chạy:

```powershell
Tests/ui/run_widget_tests.ps1 -OutDir Build/Logs/2026-09-13-gpt-ui-properties/tests-5 -NativeTree Build/cmake/gpt-login-ui-props
```

**69/69 ca native PASS**, compile/run 0; bằng chứng `tests-5/tests.log` và `tests-5/result.json`. Gồm 34 ca cũ và 35 ca mới: callback ID/tháo callback, tooltip, ảnh AnimateId, quads frame/background độc lập, chữ căn lề, kéo 15×8 và nhả capture, min height, bàn phím qua input thật, style hàng add/insert, ChannelBkg 8 quads cho 2 hàng, hover đủ ARGB, empty channel, kiểm factory ChildItem.

SHA256 native DLL được test: CEGUIBase `7120D14496398C3CAF878A3BEC4EDA7502FE635C049FCB7DED36A39104CC1117`; CEGUIFalagard `91E2B77BDA531FCB45F4A419B096AAE59BC086727AD15709727231376615106D`. Runner cho phép chọn tree native nằm trong Build/cmake để không thay DLL stage dùng chung. Diff check phạm vi UI sạch.

Giới hạn: renderer kiểm cache/quads bằng ảnh tổng hợp, không phát âm thanh thiết bị, không dùng GPU/clipboard/mạng. Fixture Combobox kiểm lưu property trước child initialization; fixture ChatHistory kiểm hợp đồng và từ chối native type sai, chưa kiểm bố cục auto children hoặc dòng chat thật. Cần CI đồng bộ, chạy Game, đếm lại log, xem ảnh và kiểm thao tác đăng nhập; khi vào được thế giới phải kiểm di chuyển/thao tác do BoundWindow/DragTitle là thay đổi dùng chung. Không suy từ 69 ca này ra parity B hoặc toàn bộ UI đã đạt.

## Bằng chứng phần còn lại

- BtnAnimation B: setter chọn Animate theo tên, lấy frame đầu nhưng không tự bật; EnableAnimation mới bắt đầu theo System elapsed time, update khi visible, vẽ ảnh phủ trên trạng thái nút. Bằng chứng đã được tác vụ host cung cấp tại `Build/Logs/2026-09-13-gpt-login-remaining/btn-*.txt`; chưa triển khai batch này.
- BoardKillTimer B chỉ kích hoạt khi insert với mode 3/4; chat mode 0 thường không hết hạn. CY hiện có interface insert một tham số nên không được tự làm mọi dòng chat biến mất. `board-insert.txt`, `board-update.txt`, `board-kill-handler.txt`, `board-kill-setter.txt`, `board-own-timer.txt` cùng thư mục trên.
- LightEnable B chọn nhánh render light tại đầu progress, dùng state LightEnable và named area LightArea khi có. Evidence ở `Build/Logs/2026-09-13-gpt-ui-properties/b-progress-draw-head.txt` và `b-progress-light.txt`; phần đầu tệp light bắt giữa instruction nên chỉ đọc từ địa chỉ instruction hợp lệ. Chưa triển khai batch này.

### BtnAnimation / EnableAnimation

`FalButton.h/.cpp` bổ sung tài nguyên overlay và cờ chạy riêng. `BtnAnimation` tra tên trong AnimateManager, giữ tài nguyên cũ nếu manager/tên chưa tồn tại giống B, chọn frame đầu nhưng không bật animation. `EnableAnimation=True` chỉ có tác dụng khi đã có animation; chuyển false→true bắt đầu từ System elapsed time, gán frame/alpha đầu. Gán True lặp lại không restart. False xóa frame. Update khi visible, lấy frame/alpha bằng thời gian CEGUI; overlay phủ đúng kích thước nút sau imagery trạng thái, alpha frame nhân với effective alpha của Window. Hành vi PushButton và autorepeat vẫn chạy.


### LightEnable

`FalagardSuperProgress.h/.cpp` đọc flag và vẽ state LightEnable tại đầu progress hiện tại. Dùng kích thước LightArea nếu có, fallback hình vuông bằng chiều cao thanh. Dùng ProgressArea của look, fallback rect Window. False tắt riêng ánh sáng.

Look hiện đại dùng Enabled/Disabled/Effect thay vì ProgressImage legacy; native trước đây không vẽ các state này. Batch 2 bổ sung nhánh look: fill và effect theo progress/current smooth value, giữ nhánh RenderableImage khi có ProgressImage riêng. Màu mặc định trắng; dữ liệu EffectColorLevel vẫn được áp dụng. Sửa trả chỉ số màu đã clamp thay vì tính lại chỉ số chưa clamp. Khi bật light, đầu sáng bám progress đích ngay cả khi hiệu ứng chuyển tiếp chưa theo kịp.


### BoardKillTimer

`FalChatHistory.h/.cpp` lưu số giây không âm, mặc định 0 (B constructor a0525 xác nhận). Getter trả giá trị thực để ChatFrame.lua dòng 391 dùng cho Talk disappear time. Bổ sung overload native `insertChatString(id,text,mode)`: mode 0 bình thường, mode 1 thêm mà chưa layout, mode 2 chỉ layout, mode 3 thêm có timer mà chưa layout, mode 4 thêm có timer và layout. Wrapper một tham số đang được Lua dùng tiếp tục gọi mode 0. Timer 0 tắt hết hạn; timer của row đã thêm giữ lifetime lúc thêm.

Timer được giảm trong history `updateSelf`, trước khi CEGUI 0.4.1 duyệt children với child_count đã chụp. Hết hạn loại đúng row, bỏ timer và layout lại; không xóa chat mode 0/1. Khung thời gian lớn vẫn hết hạn; delta không hữu hạn/âm không làm sai timer. Clear và capacity eviction hủy timer trước khi bỏ row.

Khác biệt CY có chủ ý so với B: B dùng row event KillBoard và detach/reuse; CY dùng WindowManager dead pool để giải phóng row ở expiry/clear/eviction. Cách này giữ ownership rõ và tránh sửa mảng children từ giữa update của chính row. CY hết hạn khi thời gian còn lại ≤0, không sao chép các lỗi cạnh 0,5 giây/overshoot của B. Không đổi vtable IFalagardChatHistory một tham số, không thêm Lua host mới trong batch này.

### Kết quả batch 2

Build tree chung `Build/cmake/gpt-login-ui-props`, tối đa 2 jobs, components `freetype;expat;luaplus;wxengine;cegui;falagardex;uisystem`, targets `cys_ceguifalagard cys_uisystem`: **rc0, 98/98 edges**, `Build/Logs/2026-09-13-gpt-ui-properties/build-7.log`. Các cảnh báo /EHc và Boost compiler detection đã có, không phải lỗi compile mới.

Widget **88/88 PASS**, compile/run0, `Build/Logs/2026-09-13-gpt-ui-properties/tests-6/tests.log` và `result.json`: 69 ca batch 1 cùng 19 ca mới. Kiểm resource không tự chạy, enable lặp không restart, missing resource giữ trạng thái, hidden update, stop, alpha; progress fill và quads head 8×6 tại tọa độ đúng, bám progress, toggle; timer mặc định/invalid/mode0..4/large frame/zero/clear. Chat tests dùng hàng native và parent native, scrollbar fixture giữ số liệu thật nhưng không tạo button/thumb của scrollbar; chưa thay kiểm thao tác scrollbar trong Game.

Agent text chạy gradient **55/55 PASS** với cùng DLL; xem `Docs/specs/ui/login-text_vi.md` và `Build/Logs/2026-09-13-gpt-login-remaining/gradient-tests-1`. SHA256 dùng chung: CEGUIBase `089A943FC0F45F08AF05C14698467267396F9AFCC8E781C511E1E229D492562D`, CEGUIFalagard `9730B3E76F86E9E9B1B500F090FBC9C73D73924D62344EE985DAC067F79541E9`. Source widget test `73192392A7DCD79E9FD9AF82CF821ED23FFE90403EA53B3D4CA0167E7F23E427`.

Diff check phạm vi native UI/tests sạch; không có builder thứ ba, không sửa binary stage dùng chung. Đợi CI và Game runtime để kết luận số Error mới; các kiểm tra unit không chứng minh UI đã hoàn toàn đạt hoặc đã kiểm gameplay trong thế giới.

## Batch 3: PopMenu và MapImage qua chuyển trang tài khoản

Runtime b636cd0 qua CI 36/36 rồi dừng khoảng 8 giây tại chuyển trang tài khoản: `Build/Logs/2026-09-13-gpt-wsl-ui/integration-b636cd0/UISystem.log` có hai lỗi PopMenu và fatal factory Falagard/MapImage khi Reputation được nạp. Host xác nhận OpenWindow SoftKeyBoard phát tới listener mặc định giống B; không bỏ sự kiện hoặc lọc route để tránh nạp layout.

### PopMenu

`CEGUIMenuItem.h/.cpp` bổ sung thuộc tính native PopMenu nhận tên PopupMenu đã tồn tại. Hai item ContexMenu dùng chung GroupingMenu; giữ popup dưới parent gốc như B, không reparent popup sang item. Tên không tồn tại hoặc đối tượng sai kiểu báo lỗi trước khi đổi binding; chuỗi rỗng bỏ binding. Overload pointer cũ vẫn giữ hành vi popup con.

Khi mở, dùng native MenuBase để đổi item đang mở; đặt popup bên phải menu hoặc bên dưới menubar, chuyển trái khi vượt biên phải, clamp theo màn hình. Tọa độ tính bằng pixel màn hình rồi trừ gốc parent popup; không dùng screenToWindow ở metrics Relative vì sẽ chia tỷ lệ một lần nữa.

Binding đăng ký DestructionStarted của popup dùng chung. Khi popup bị hủy, đóng khi con trỏ còn hợp lệ, xóa cả binding và tham chiếu Event::Connection. CEGUI 0.4.1 Event destructor không invalidate connection còn sống, nên không giữ connection để disconnect sau khi Event đã chết; cũng không unsubscribe trong lúc Event duyệt subscriber map. Item hủy trước popup thì chủ động đóng và disconnect trước base destruction.

Kiểm thử phát hiện lỗi có sẵn ở ItemListBase: addChild_impl thêm vào d_listItems nhưng không có removeChild_impl đối ứng. destroyWindow/cleanupChildren bỏ child mà list giữ con trỏ đã được cleanDeadPool, dẫn tới AV khi hủy menu sau đó. Sửa ItemListBase.h/.cpp đồng bộ list khi detach; resetList tách toàn bộ danh sách sở hữu trước callback/hủy để không skip phần tử hoặc gọi layout ảo từ base destructor. MenuBase.h/.cpp đóng popup và xóa active item trước khi detach. Không sửa global Event hoặc bỏ cleanDeadPool khỏi test.


### MapImage

`Src/Client/CEGUIFalagardEx/FalagardMapImage.h/.cpp` là lớp native riêng kế thừa FalagardStaticImage để giữ phần render look hiện có. Factory thật được thêm vào FalModule.cpp và component falagardex.cmake; không alias MapImage sang StaticImage. Reputation có 12 widget dùng bản đồ Enemy/Normal/Friend.

ChildImage nhận `name:KEY set:IMAGESET image:IMAGE`, tra resource trước khi ghi map và có thể thay mapping cùng key; không tự đổi ảnh đang hiển thị. SetCurrentImage chọn key và vẽ chính ảnh đã tra; key chưa có xóa ảnh trước giống B. Getter giữ tên vừa yêu cầu; descriptor sai hoặc resource thiếu không phá mapping cũ.


### Kết quả batch 3 và giới hạn

Build chung x64 Release tối đa 2 jobs, tree/components/targets như batch 2: **rc0, 17/17 edges**, `Build/Logs/2026-09-13-gpt-ui-properties/build-13.log`. Không sửa DLL stage dùng chung. Các cảnh báo /EHc và Boost compiler detection cũ còn được ghi trong log.

```powershell
Tests/ui/run_widget_tests.ps1 -OutDir Build/Logs/2026-09-13-gpt-ui-properties/tests-11 -NativeTree Build/cmake/gpt-login-ui-props
```

**105/105 PASS**, compile/run0, `tests-11/tests.log`, `tests-11/result.json`: 88 ca trước + 11 ca PopMenu/vòng đời và 6 ca MapImage. Popup fixture chỉ thay phần vẽ và sizeToContent; native MenuBase/add/remove/open/close/destroy vẫn chạy. Các ca mới kiểm vị trí pixel, chia sẻ không đổi parent, chuyển item, clamp, lỗi atomic; hủy target trước/hủy item trước; removeItem đang mở, detach/reparent, reset nhiều item, hủy parent; đăng ký qua export module thật, chọn ảnh/quads, unknown key xóa và resource lỗi giữ map. Cuối bộ chạy destroyAllWindows rồi cleanDeadPool và thoát 0.

Giữ `tests-9` (AV khi rebind connection sau hủy target) và `tests-10` (101 ca riêng qua nhưng AV ở destroyAll) làm bằng chứng lỗi trung gian; chúng không phải kết quả đạt. Hash bản cuối: CEGUIBase `9073165AB1C5E451D465929EF277858850F8C955F2BA3074B754A7DF3FA41EFC`; CEGUIFalagard `163922E7EF79D3406249E54C4421071962EE3228C1AA5703400E2C010A60CFAF`; source widget test `C3C213ACCC3411A1DB39D2CD03DBD0FF6E966BDB8B54697EEE0855E362832910`.

Gradient 55/55 là kết quả batch 2 với hash DLL đã ghi ở trên; không tuyên bố đã chạy lại font suite trên DLL menu mới. Cần CI đồng bộ và Game để đếm Error mới, chụp trang đăng nhập, thử tài khoản WSL, kiểm menu thực và thao tác/di chuyển khi vào thế giới. Native 105 ca không thay cho kiểm GPU, âm thanh thiết bị, mạng hoặc parity toàn bộ UI B.

Root đã commit source batch 2/3 tại 3570203 sau kiểm thử; CI toàn bộ đang chạy tại thời điểm bàn giao. Kết quả CI/Game sẽ được tác vụ tích hợp cập nhật sau.

## Sửa tràn atlas FreeType khi gặp glyph cao hơn

Runtime `Build/Logs/2026-09-13-gpt-wsl-ui/integration-3570203` qua CI 36/36, nạp 11 layout, UI Error=0 rồi kết thúc 0xC0000374 ở lần capture đầu trước SelectLoginServer. PNG 3.145.728 byte toàn zero; dump stack `baseline-stack-3570203.txt` cùng thư mục cha xác định WICImageCodec::encodeTo/WriteSource. Đây là nơi heap corruption được phát hiện; chưa đủ bằng chứng để kết luận nơi tạo lỗi. Root quản lý instrumentation capture/WIC riêng.

Đọc đường glyph tìm được lỗi raw write trong `Src/ThirdParty/CEGUI-0.4.1/CEGUI/src/CEGUIFont_FreeType.cpp`: sau cập nhật d_maxGlyphHeight, bản cũ chỉ kiểm chiều dọc trong nhánh xuống dòng ngang. Một glyph cao hơn tại dòng cuối còn chỗ ngang vượt atlas 256×256. Đây là lỗi native có trước gradient; mã D0 bị prepareString bỏ qua nên không tạo glyph.

Ca tái hiện dùng FontManager/FreeType thật, NotoSansSC-Regular.ttf 12pt/96dpi. Hai glyph mặc định cho chiều cao cũ 15; U+1EA0 (Ạ) cao 16, rộng 10. Fixture đặt cursor (32,241), hàng cũ vẫn vừa 256, và mở rộng allocation bằng vùng canary 64 dòng để không phá heap của tiến trình kiểm thử. Bản cũ ghi hỏng **10 pixel canary** và thất bại đúng ca: `Build/Logs/2026-09-13-gpt-ui-properties/atlas-before`, 55/56, compile0/run1. Không xóa bằng chứng thất bại này.

Sửa mỗi glyph trước raw write: dùng chiều rộng/rows bitmap thật, xuống dòng nếu hết chỗ ngang, tạo atlas mới khi hết chỗ dọc kể cả chưa xuống dòng ngang. Rect của glyph dùng đúng rows, không mượn chiều cao lớn nhất toàn font. Glyph bình thường luôn được giữ, upload và vẽ trên atlas mới. Nếu bitmap lớn hơn cả atlas cố định 256, báo InvalidRequest trước thay đổi atlas thay vì ghi tràn hoặc silently drop; chưa mở rộng renderer/atlas động cho cỡ chữ quá lớn.

`Tests/fonts/font_tests.cpp` thêm 4 ca: tái hiện glyph Việt cao hơn ở dòng cuối (canary sau sửa **0 pixel thay đổi**, so từng byte alpha với bitmap FreeType gốc và kiểm quad), wrap ngang, 1.114 glyph Trung/Việt qua nhiều atlas không mất mapping/vượt rect, font quá lớn thất bại rõ và không publish font lỗi. Fixture truy cập protected state bằng member pointer của base, không downcast đối tượng native sang kiểu test hoặc sửa production ABI.

Build shared tree x64 Release tối đa 2 jobs: `Build/Logs/2026-09-13-gpt-ui-properties/build-14.log`, rc0. Font **59/59 PASS** tại `atlas-after/tests.log`, `atlas-after/result.json`; widget **105/105 PASS** tại `tests-12/tests.log`, `tests-12/result.json`, gồm teardown sạch. CEGUIBase SHA256 `4FABF3155D9E9A520D27A15FCBC64CD77CB182ED76D449F7E28D4C42E35CC882`; CEGUIFalagard giữ `163922E7EF79D3406249E54C4421071962EE3228C1AA5703400E2C010A60CFAF`. Source font test `EA56F2EFC42769EE8ED8FBFD83B10583FC4AA1F1A06FDD3137F9A3DA2352FE99`.

Diff check hai file source/test sạch, UTF-8 không BOM/LF giữ nguyên. Không sửa capture/WIC, không PageHeap registry, không đổi binary stage. Cần CI và runtime có instrumentation để xác định lỗi heap WIC còn hay hết; kết quả unit chứng minh sửa atlas, chưa chứng minh đăng nhập Game đạt.

## Batch 4: bốn thuộc tính MultiColumnList

Runtime sau atlas/ComboBox tại 5d5ece4 đã giữ Game chạy 60 giây theo kiểm thử root; log còn yêu cầu SelectColour, SelectBrush, DrawOffset và ColumnsAdjust của MultiColumnList. Phạm vi batch này là bốn file MultiColumnList/Properties, ba file ListboxItem/ListboxTextItem do tác vụ WSL phối hợp, và widget tests. Không đổi thuộc tính Sizable hay kích thước layout.

SelectColour và SelectBrush giữ trạng thái native như Listbox. Setter áp cho mọi ô đang có, bỏ qua ô null; addRow, insertRow và setItem áp trạng thái cho ô thêm/thay sau. Khi chưa đặt hai thuộc tính, màu/brush riêng của item được giữ. Brush rỗng xóa rõ cả ô cũ và ô mới; descriptor hoặc resource lỗi bị từ chối trước đổi trạng thái. Renderer ListboxTextItem dùng màu bốn góc và ảnh selection thật.

DrawOffset lưu float, mặc định 0. Item renderer dịch cạnh trái của selection sang trái và vị trí bắt đầu chữ sang phải theo offset, giữ clipper và các cạnh còn lại. Cả nhánh render trực tiếp và RenderCache dùng cùng ý nghĩa. B chỉ lưu MCL offset, rồi UI_CEGUI chép sang item lúc thêm/thay; CY mở rộng có chủ ý theo yêu cầu điều phối: thay property còn cập nhật ngay các ô đang có. Tọa độ không hữu hạn bị từ chối trước đổi ô. Không thay số đo nội dung hoặc nới clipper để làm selection tràn ô.

ColumnsAdjust là hành động một lần: False không làm gì; True cộng chiều rộng tương đối của các segment, chỉ tăng cột cuối bằng phần thiếu khi tổng nhỏ hơn 1. Không co cột khi tổng đã đủ/vượt 1, không tự điều chỉnh theo nội dung hay bật chế độ resize lâu dài. Getter trả chuỗi rỗng như B; metadata mặc định False. CY thực hiện vòng tính bằng API ListHeader/segment đang có, không thêm alias sang ColumnsSizable.

Bằng chứng B tại `Build/Logs/2026-09-13-gpt-netbot/b-mcl-semantics_vi.md` và các tệp `b-*.txt` cùng thư mục: CEGUIBase SHA256 `C79A301F373FA108BA0E709B8644EF85219473C953FF479A2F689C84EA25282B`; ColumnsAdjust getter RVA100940, setter101420, action FF680, header EA6D0; DrawOffset getter1009E0/setter1014B0, giá trị MCL+4A0; UI_CEGUI chép sang item+E0 tại12258/12607; ListboxTextItem draw E7930 có selection-left trừ offset và text-left cộng offset. Đã xác minh thứ tự trường Rect của B trước khi chuyển sang Rect CY.

Build shared tree x64 Release, tối đa 2 jobs: `Build/Logs/2026-09-13-gpt-ui-properties/build-15.log`, **rc0, 15/15 edges**. Widget `tests-16/tests.log` và `tests-16/result.json` cùng thư mục: **118/118 PASS**, compile/run0, gồm 105 ca trước và 13 ca mới kiểm ô cũ/mới/null, lỗi brush atomic, màu bốn góc và quad selection, clear, offset dương/âm trên quad chữ và ảnh thật, False/True một lần/no shrink. Fixture giữ row mutation, header segment, item render và teardown native; chỉ cố định vùng list và không tạo scrollbar. Glyph được chuẩn bị bằng getTextExtent giống bước đo hàng, không sửa production để đáp ứng fixture.

CEGUIBase SHA256 `8CF9B51A0FD1D0132135A76C507121F9B6ECAEEEAA6F7A861A91C66BF5D67109`; CEGUIFalagard `DBDB32B5BE00022E662EAA3F7081181FB77EA1F1798F6D752B66F2AFD86D8A5C`; source widget test `A152D74ED6084C7B6E82C6DDDE8A4791FD1BAD637ACF14E1ED8253FEEDAEB686`. Giữ tests-13 (fixture Header/Segment trùng factory làm trùng SortDirection), tests-14 (helper ghi sai encoding và fixture chưa chuẩn bị glyph), tests-15 (compile const sai) làm lịch sử; không dùng các lần đó làm kết quả đạt. tests-16 giữ nguyên các literal Unicode gốc và thoát sạch sau destroyAll/cleanDeadPool.

Thay đổi kích thước ListboxItem/MultiColumnList yêu cầu CI build đồng bộ các module dùng header; không trộn DLL cũ/mới. Chưa thay binary stage hoặc tự chạy Game batch này. Root tiếp tục CI và runtime để kiểm bốn lỗi MCL đã hết; unit chưa xác nhận thao tác trong thế giới.
