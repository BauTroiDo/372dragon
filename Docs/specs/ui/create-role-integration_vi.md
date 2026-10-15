# Tích hợp màn tạo và chọn nhân vật CY

Ngày13/09/2026, màn tạo/chọn đã dùng đúng cây và cảnh CY. Lượt `wsl-create-a272cbe-2` tạo/lưu CYTest00/GUID200001; full Create gate vẫn FAILED vì harness đọc nhãn bằng API Editbox sau khi server đã lưu. Reader SimpleText riêng `5a2fb6a` đã qua28/28 kiểm native; hai phiên Fresh Select `wsl-select-91148e1` và `wsl-select-91148e1-2` đã PASS, đăng nhập lại và bấm chọn đúng nhân vật; lượt cuối xác nhận hai nhãn ô trống vừa khung gốc. Không tạo lại record để thay thế bằng chứng lỗi. Vào thế giới chưa triển khai.

Mọi đường dẫn tài nguyên và bằng chứng dưới đây tính từ CY-Source. Nguồn S2 chính xác do người dùng chọn là `../Tools/DATA NEW/DataCY31-08-26`, chỉ đọc. Bản sinh, backup và kiểm thử nằm trong CY-Source; server dùng clone test đã được cho phép. Không thuộc phạm vi charlogin, xóa nhân vật hoặc vào thế giới.

## Bố cục và tài nguyên đã tích hợp

Sau khi người dùng bác bố cục tự dựng, profile nhập nguyên **96 control CreateRole và 50 control SelectRole** từ CY, giữ cây, geometry, art và sự kiện. Thay đổi được giới hạn ở namespace, font/nhãn UTF-8 và controller mới. Lua S2 có header mã hóa, chưa được giải mã; controller CY-Source tham khảo workflow Lua GL plaintext. Không bật GLResponsive. NotoSansSC-Regular.ttf dùng CodePage65001; StrFilter trống, icon TSGame và byte sáu tệp đăng nhập GL được giữ theo manifest.

Lưới chân dung giữ 3×3 và hai trang cho 15 lựa chọn mỗi giới tính; đủ nam/nữ, mặt, tóc, đồ khởi tạo, xoay/zoom, tên/ngẫu nhiên, Back/Create. Mười lăm nút xem môn phái dùng primary CharModelEx `4950 + sex × 15 + ordinal`, đủ 30 model. Nhãn ba nút cuối đã đối chiếu ảnh CY: Đào Hoa Đảo, Tuyệt Tình Cốc, Ác Nhân Cốc; không suy tên từ khóa atlas. Preview không đổi môn phái của nhân vật gửi server. Các mô tả tiếng Việt là hướng dẫn mới, không chứa thuộc tính chiến đấu suy đoán.

Native `CysLoginScene` tải `tl3chuangjian.Scene`, scene ID -2. Cảnh, bục, model, mesh, skeleton, vật liệu và hiệu ứng có provenance S2; khóa GBK giữ nguyên, tên đĩa chuyển đúng spelling runtime và giữ thư mục con. Profile ghép các dependency trên bytes đã lên kế hoạch, không ghi đè mất phần appearance. Preflight kiểm containment, hash, backup và kế thừa GL manifest trước khi đặt marker applied.

Camera dùng năm pose đứng yên lấy từ client CY C: nữ/nam tạo và slot0/1/2 chọn, quaternion nguyên bản và FOV dọc65°. Cả 60 float đã đối chiếu từng bit với metadata độc lập. Scale tạo/xem môn phái là1,5; scale chọn là1. Bridge gọi API model thật và đọc lại scale ở scene node, không gán property không tồn tại. Chưa phục hồi các track chuyển camera/intro gốc. Chi tiết nguồn và giá trị ở `Docs/specs/ui/create-role-reference_vi.md`.

Actor hiện trong main scene; `CreateRole_Model` giữ trong cây nhưng unhook/ẩn, không dùng RTT MeshBack làm nền. SelectRole gốc không có MeshWindow; native dựng ba actor tại ba anchor và chọn camera theo slot. Chuyển mode hoặc hủy object ẩn actor cũ, dừng xoay/zoom và bỏ tham chiếu trước khi giải phóng. Từ 13/09, Enter đi đường modern: CLAskCharLogin 426, rồi socket game. Delete giữ control gốc nhưng disabled vì protocol xóa chưa được nối.

## Luồng dữ liệu tạo và chọn

`CGamePro_Login` sở hữu `LoginClient` Interactive xuyên Login/CharSel/CharCreate; `NetManager::Tick` pump một lần trên main thread. Back về tài khoản hoặc lỗi terminal hủy phiên; việc hủy owner được trì hoãn tới sau pump. Không gọi UI từ worker.

Nút Create ở màn chọn gọi `DataPool:AskCreateCharCode`: gửi776, chỉ777 flag1 mới mở tạo; hộp chờ được đóng khi chuyển màn. Controller lấy option array1-based; `ApplyCreateAppearance` nhận index0-based rồi lưu ID thật của recipe. Tên UTF-8 1..29 byte và sex/face/hair/portrait/outfit hiện tại được gửi522 trên cùng phiên. Không tự gửi lại. Back bị chặn khi pending; lỗi server hiện thông báo. Result440 bằng0 vẫn phải chờ319 mới tăng đúng một GUID và giữ các GUID cũ; không gửi thêm711 legacy.

`CysLoginRoleList` sở hữu record modern, kiểm count, GUID, sex và UTF-8 trước khi đổi dữ liệu. Appearance được resolve trước khi thay danh sách; không ép packet lên `DB_CHAR_BASE_INFO` 0.85. Lua `GetRoleInfo` trả năm giá trị name/menpai/level/deleteTime/portrait; deleteTime bằng0 vì319 không có trường này. Màn chọn dựng ngoại hình từ sex/head/hair/newPlayerSet và chân dung theo portrait_id thật. Hiện chỉ hỗ trợ bộ đồ khởi tạo; chưa nhận là hỗ trợ đầy đủ trang bị của nhân vật cấp cao.

Rà soát luồng0→1 chưa thấy sai hợp đồng ở permission, submit hoặc refresh. Rà soát ba slot phát hiện controller tại `bf4a79b` coi nhân vật mới luôn ở cuối, trong khi transport không bảo đảm thứ tự319. Phần sửa sau mốc đó đã kiểm riêng: native dùng `IsModernCreatePending()` để phân biệt list tạo thành công với login/refresh, xác định GUID mới trước khi đổi record, và giữ GUID đang chọn cho refresh thường. Lua đọc `GetCurSelectRole()` ở mọi refresh, không tự chọn count−1. Nếu GUID đang chọn không còn thì native chọn record đầu còn lại, hoặc -1 khi rỗng. List tạo sai count/thiếu GUID cũ bị từ chối trước khi đổi state. Test hoán vị [A,B]→[B,C,A] và [C,B,A] đều chọn C. GUI/WSL đã chứng minh tạo0→1 và đăng nhập lại chọn GUID200001; ba slot có nhiều nhân vật chỉ mới được kiểm bằng fixture, chưa có ba record thật trên clone.

## Bằng chứng đã chạy

Gốc bằng chứng: `Build/Logs/2026-09-13-gpt-create-role`. Các số dưới đây là những lượt thực sự đã chạy; profile75 đã chạy lại sau sửa chọn theo GUID. Text6 là bằng chứng trước sửa chọn GUID; nhãn tạo không đổi, phần chọn được kiểm thêm8 ca mới.

| Phần | Kết quả | Artifact dưới gốc bằng chứng |
|---|---|---|
| Profile/controller với dữ liệu S2 và LuaPlus thật | 75/75; apply fixture820 tệp; sáu tệp GL nguyên byte | `profile/tests-13-guid/result.json` |
| Helper scene/closure | 23/23;685 updates,421 object; missing/unsupported/ambiguous0; kiểm138/138 đường dẫn có prefix | `original-reference/scene-plan/tests-2-prefix.json`, `final-verification-2.json` |
| Nhãn/mô tả Việt trong geometry gốc | 6/6;15 mô tả qua Lua thật; ngắt dòng tường minh, dòng dài nhất110px trong144px | `profile/text-wrap-1/result.json` |
| Catalog appearance S2 | 190/190; thêm30 primary sect model | `appearance/run-4-original-sects/result.json` và `tests.log` |
| Record modern và chọn theo GUID | 21/21 sau sửa; gồm14 ca cũ và7 ca mới | `net/role-list-2-guid/result.json` và `tests.log` |
| Controller chọn theo native GUID/slot | 8/8 sau sửa; reply đảo thứ tự, refresh, Back/mở lại và lỗi index | `profile/selection-guid-1/result.json` |
| Phiên tạo tương tác offline | 28/28 loopback; permission, tạo, lỗi, cancel và319 owned | `net/run-2/summary.json` |
| Probe transport mặc định | 18unit,100000fuzz,1699replay,20loopback | `net/probe-regression/summary.json` |

Phép đo chữ trong test6 dùng FreeType/Pillow để chừa khoảng trống, không thay bằng chứng native render. Catalog Canonical123 ca là hồi quy lịch sử; S2 mới là nguồn chính cho màn này. Chi tiết hợp đồng/test ở `Docs/specs/ui/create-role-profile_vi.md`, `Docs/specs/ui/create-role-appearance_vi.md`, `Docs/specs/net/creation-session_vi.md`.

Lượt **offline-6ea1ed4** chạy khoảng180,7 giây, được runner dừng sau thời lượng định trước; không phải Game tự thoát bình thường. WXClient ghi `PASS Preview; no authentication or character submit`, đủ 30 preview/hủy, portrait hai trang, nam/nữ, chọn ngoại hình, ngẫu nhiên, Unicode, giữ xoay, cả hai nút zoom và Back/mở lại. Có19/19 PNG hợp lệ và readback `main-visible=1 scale=1.5 verified`. Xem `offline-6ea1ed4/run.json`, `WXClient.log` và ảnh tương ứng.

Shader legacy ps_1_1 từng lỗi X3539 ở8dd7b95;6ea1ed4 thêm backwards-compatibility chỉ cho target ps_1_, cache identity có cờ mới. Probe giữ bytes source/defines, tái hiện lỗi rồi compile ra ps_2_0 thành công; hai warning được giữ trong evidence. Runtime6ea không còn X3539/unsupported-program. Census `census-6ea1ed4-1/report_vi.md` ghi CEGUI/Lua/fatal/material errors0, renderer_errors5→1 và không có lỗi renderer mới. Error8 còn lại là fallback `WXTerrainType.cfg` đã có baseline; không xóa hoặc gọi là đã sửa. Các cảnh báo khác vẫn giữ trong log.

**Lịch sử lỗi prewarm được giữ nguyên.** `visual-6ea1ed4/assessment.json` kết luận fresh-login FAIL: scene tạo bị nạp sớm trong startup prewarm và thay nền đăng nhập. 26 vùng control trùng pixel không phủ nhận lỗi toàn khung. Commit `bf4a79b` chỉ cho CharCreate::Init Enter scene khi procedure đang active; harness thêm thời gian chờ tải cảnh trước ảnh. Lượt `offline-bf4a79b` sau sửa đã PASS Preview/19 PNG. `visual-bf4a79b-1/report_vi.md` so toàn khung server/account/unicode trùng RGB/SSIM1; keyboard rawSSIM0,9828 vẫn FAIL phép so0,99. Nguồn C++ cùng SHA dùng rand() xáo68phím, 4977pixel khác chỉ nằm trong nội thất phím; đây là phân loại biến thiên nội dung riêng, không đổi gate hoặc dùng mask để báo full-pixel PASS. Thời gian chờ12 giây không phải điều kiện queue-empty; chưa nhận intro camera gốc.

`af28108` sửa converter CPU cho hai mesh CY v1.30→v1.40: tắt padding riêng trong tiến trình chuyển đổi để AABB không bị cộng hai lần, không đổi policy của Game. `mesh-upgrade-1` giữ lỗi vòng đầu; `mesh-upgrade-2` PASS2/2 với so snapshot byte tuyệt đối và skeleton có thật. Bird48đỉnh/48tamgiác/7bone; crane484đỉnh/560tamgiác/18bone; source mesh/skeleton không đổi. Adapter `4db9234` kiểm lại evidence/nguồn/hash, backup đủ hai mesh và hai manifest trước ghi; 11/11 test guard/rollback, apply thật4/4 file tại `mesh-adapter-apply-bf4a79b6`. Profile gốc vẫn giữ nguồn S2; derived hash có provenance riêng.

Lượt `wsl-create-bf4a79b` xác thực đúng một lần, nhận list0 và permission1 nhưng dừng tại kiểm ngoại hình trước submit. Trong12giây harness chờ, log có hai lần đổi portrait ngoài lịch input; chưa có log nguồn để quy cho người dùng. `input-isolation-1/route_vi.md` xác nhận MouseTick vẫn đọc async desktop và gửi cùng endpointCEGUI; `a272cbe` bỏ polling đó riêng khi smoke, giữ input của phiên Game thường. `net/role-post-create-attempt1.json` xác nhận0role; đây không phải create-refusal và không có căn cứ nói đã tạo.

Lệnh kiểm phần chọn GUID, từ CY-Source, luôn chọn thư mục output mới:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tests/net/run_login_role_list_tests.ps1 -OutDir Build/Logs/role-list-NEW
python -B Tests/ui/create_role_selection_tests.py --out Build/Logs/selection-guid-NEW
```

Bộ native dùng header production và protocol library CI, một compiler; build/run exit0, không warning. Bộ Lua dùng LuaPlus.dll CI với SHA `aadbaa43eb1f1748cefa8fccdcf9659ddee1edb4cfccce71cfc2ba7ae745568f`; phản hồi native trong bộ này là fixture, còn thuật toán GUID được kiểm trong bộ C++ riêng. Hai bộ không chạy mạng hoặc Game.

## WSL thật, kiểm thử cuối và giới hạn

Hai mesh đã qua runtime a272, không còn cảnh báo phiên bản cũ; giữ Error8 WXTerrainType và VSync baseline. Lượt `wsl-create-a272cbe` đã gửi522 đúng một lần nhưng timeout vì Game không có proxy `.textfilter`; snapshot vẫn0role. Race xảy ra giữa register và online khi Game nạp scene. Công cụ `Tools/server/repair_test_cluster_routes.py` đã backup/patch duy nhất manager trong clone; `net/cluster-route-activate-5/report.json` xác nhận had_tool=false→true,11 dịch vụ công khai và filter_equal=true, PID Tool/Game không đổi. Manager đang chạy vẫn nạp code cũ; patch startup đã kiểm trên Lua thật, chưa chạy lại toàn bộ server để kiểm cold start.

Lượt `wsl-create-a272cbe-2` nhận440 result0 rồi319 list1 lúc16:10:31 trên cùng phiên (tx6/rx8,closed0). `net/role-pre-7.json`→`net/role-post-create-observation2.json` xác nhận0→1, GUID200001, model1/hair5/face100/portrait13/newPlayerSet0; một lần auth thành công,6 PID/16 cổng giữ nguyên, delta error/traceback của bốn log hiện tại bằng0, abnormal packet không tăng. `net/create2-server-success-client-failure_vi.md` phân biệt server creation PASS với full GUI Create FAILED: actor chọn đã dựng và có readback scale1, nhưng kiểm nhãn tên dừng lúc16:10:33. Không đổi kết quả thất bại đó thành PASS từ DB.

WXClient.log append khi dùng lại stage. `net/create2-log-extraction-1/provenance.json` chứng minh prefix18075byte bằng nguyên log lượt trước, suffix19122byte/215 record thuộc đúng cửa sổ hiện tại; không lọc dòng lỗi. Rawrun/log được giữ nguyên. Lượt tiếp theo phải archive log cũ trước launch và kiểm riêng record đã lưu, không gửi Create thêm để bù lỗi kiểm thử.

`wsl-select-91148e1` chạy16:24:04–16:27:07,182,369giây; auth/list1 lúc16:24:25, chỉ3TX/4RX và không gửi Create. Có marker PASS Select lúc16:24:42, reader kiểm tên từ SimpleText thật, record CYTest00/actor native và bấm slot0. `net/fresh-select-review-1.json` xác nhận13/13 điều kiện snapshot: cùng GUID/ngoại hình, một auth trong cửa sổ,6PID/16cổng giữ, không thêm abnormal/error/traceback. Ảnh lượt này có hai nhãn ô trống dài hơn100px; `visual-label-before-1/report.json` giữ lỗi cắt chữ riêng với PASS chức năng. Commit `72384c4` đổi đúng một literal thành “Ô trống”, giữ geometry100×14px. `short-empty-label-1/applied.json` kiểm SHA/size toàn bộ820 tệp creation và131 tệp GL trước/sau, backup controller/manifest, ghi revision nguồn vào manifest; native binary và GL manifest nguyên byte.

CI `91148e1` đạt38/38, smoke6/6 và checks3/3. `5a2fb6a` là lượt thật biên dịch reader:8,9giây/5edge, hai warning D9025 đã có từ cờ EH;91148e1 không đổi Src, build1,4giây và0warning mới. `runner-validation-1` đạt23/23, toàn bộ gate6085byte trước/sau bằng SHA; không nới gate để nhận dữ liệu đã lưu là full Create PASS.

Runner kiểm CI binary, manifest, endpoint, Noto và sáu tệp GL trước launch. Preview dùng fixture loopback14400, không auth/submit; WSL test dùng127.0.0.1:15733 của clone. Input đi qua đúng HWND/CEGUI và ảnh từ backbuffer Game. Credential chỉ ở bộ nhớ/environment child, không vào argv, script hoặc log. Mọi lượt có thư mục evidence mới. Bằng chứng hiện tại xác nhận tạo/lưu thật và đăng nhập lại/chọn để hiển thị; chưa xác nhận charlogin hoặc vào world.

Lượt cuối `wsl-select-91148e1-2` chạy16:33:09–16:36:09,180,226giây; PASS Select lúc16:33:43, một auth, list1,3TX/4RX, không permission/create. `net/fresh-select-review-2.json` đạt13/13 điều kiện, GUID/ngoại hình không đổi, không thêm error/traceback/abnormal packet và giữ6PID/16cổng. Hai PNG màn chọn ở `visual-final-1` được kiểm trực tiếp: model không cắt đầu/chân, tên CYTest00 và hai nhãn “Ô trống” vừa khung. Census vẫn giữ Error8 WXTerrainType/VSync baseline, không có lỗi CEGUI/Lua/fatal/material hoặc warning mesh cũ/MovementType/X3539 mới.

Bản chạy thủ công: `Build/gpt-p1-1-20260913/stage-91148e1/Bin64/Run-CY-Test.cmd`; dùng input bình thường, không chứa credential. Nguồn native của stage là91148e1, nhãn nguồn72384c4; commit tài liệu cuối được CI kiểm qua `Build/Logs/ci/latest.json`. Đối chiếu cây Src, binary và manifest của bản giao nằm tại `Build/Logs/2026-09-13-gpt-create-role/final-verification/report.json`. Việc tiếp theo là charlogin/socket game/world, không tạo lại CYTest00.
