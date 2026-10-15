# Tham chiếu cảnh tạo và chọn nhân vật gốc CY

Ngày 13/09/2026. Tài liệu này ghi kết luận hành vi, hằng dữ liệu và nguồn kiểm chứng để triển khai độc lập trong CY-Source. Không chứa mã dịch ngược hoặc giả mã. Mọi đường dẫn tính từ CY-Source; nguồn bên ngoài chỉ được đọc. Không chạy Game.exe hoặc launcher gốc trong đợt điều tra này.

## Nguồn và danh tính

Người dùng chọn đúng bộ S2 tại `../Tools/DATA NEW/DataCY31-08-26`. Camera, vị trí và tỉ lệ CY được xác minh từ client C tại `../Tools/DATA NEW/CY Game/Bin64`. Client GL B chỉ dùng đối chiếu hành vi, không cung cấp tọa độ cho cảnh CY.

| Nguồn | SHA-256 |
|---|---|
| C `Game.exe` | `9278c7f37b55539fcfac1d93afa71f278e34d4ce674b0e8b52a0f62ea6e0cc5b` |
| C `Render.dll` | `e6e67de45489f90207379419c0eb2e9f4fbdbd1d800cc6f46902c1fe5eb0cec7` |
| S2 `Scene/tl3chuangjian.Scene` | `1fb487ee19bed00adc01d811d2554658091b13def544b4d7e9bf0c946f046f17` |
| S2 `Config/CharModelEx.txt` | `64670d0a45a14f6e21efaf6dbd66ac708c621300affcbe6d89ff3a0697f13281` |
| S2 `Model/all.obj` | `4efa8501a9f304c39948424855c9d48bb7a854a1301b8df1d341dfb42d9873d5` |
| B `../client_GL/Bin64/Game.exe` | `ce0c4fec7666595ca7adb250fcd8075c28f04d1852d05111c88b730f57e1c763` |
| B `../client_GL/Bin64/Render.dll` | `49b2ab1f3c72d4b1c957e463bbe474f0ef86f3f085fd8aa8660776f9de1369bb` |

Các địa chỉ dưới đây là RVA hex. C/B Game có image base `0x140000000`; Render có image base `0x180000000`. Không áp offset vtable của C/B lên interface của executable tự build; lớp tích hợp dùng export bổ sung, giữ nguyên ABI virtual hiện có.

## Cảnh, bầu trời và phạm vi giao diện

| Client | Tạo nhân vật | Chọn nhân vật |
|---|---|---|
| CY C + S2 | `tl3chuangjian.Scene`, scene ID -2 | Cùng `tl3chuangjian.Scene`, scene ID -2 |
| GL B | `chuangjian.Scene` | `xuanren.Scene` |

Tuyến tải CY: C Game `0x62b89c` khi tạo và `0x63c05a` khi chọn. GL: B Game `0x3f9e70` khi tạo, `0x3f5dfd` khi chọn. Bản S2 không cần có file `chuangjian.Scene` của GL. Bục tạo trong S2 `Scene/tl3chuangjian.Scene:2726` dùng mesh `天龙3选人场景/天龙3选人场景选人台.mesh`, position `(817.093, 1000, 3030.63)`. Vị trí actor CY được lấy từ hằng native riêng, không suy ra từ vị trí bục.

**Chỉnh lại nhận định sơ bộ về tên camera:** `default` và `chuangjiannan` là tên trạng thái sky sphere. Ở B, Gfx virtual offset `0x320` đi tới Render `0x192f0`; ở C, offset `0x348` đi tới Render `0x31870`, với callsite Game `0x640945`/`0x640978`. Chúng không phải tên camera hoặc đường dẫn file camera. Cảnh S2 không có Camera object/named camera tương ứng; camera thật được dựng bởi `CCamera_CharSel` trong native.

MeshWindow của CreateRole và `Common/MeshBack.dds` trong look là đường RTT của widget. SelectRole gốc không có MeshWindow cho nhân vật. Controller CY-Source giữ cây và callback của layout CY, còn bản tích hợp hiện tại hiển thị actor trong cảnh chính, unhook/ẩn CreateRole_Model. Không dùng MeshBack hoặc ảnh loading `Bg_Info` thay cảnh/bục. Quy tắc layout và tài nguyên chi tiết ở `Docs/specs/ui/create-role-profile_vi.md`.

## Năm pose CY khi camera đã đứng yên

Đơn vị vị trí là tọa độ đồ họa của cảnh; yaw tính bằng radian. Trước khi gọi API actor dùng tọa độ game, lớp Game chuyển qua `Axis_Trans(AX_GFX, ..., AX_GAME, ...)`. Camera nhận trực tiếp eye và quaternion `(w,x,y,z)`; giữ góc nghiêng gốc, không dựng hướng thay thế bằng `lookAt`.

| Pose | Actor XYZ | Yaw | Scale XYZ | Camera eye XYZ |
|---|---|---:|---|---|
| Nữ, sex 0 | `(818, 1064, 3033)` | 0 | `(1.5, 1.5, 1.5)` | `(822.0590209960938, 1307.3800048828125, 3708.2900390625)` |
| Nam, sex 1 | `(818, 1064, 3033)` | 0 | `(1.5, 1.5, 1.5)` | `(822.0590209960938, 1347.219970703125, 3678.52001953125)` |
| Chọn slot 0 | `(796.5360107421875, 1146, 1059.6800537109375)` | 0 | `(1, 1, 1)` | `(797.1099853515625, 1313.3699951171875, 1408.780029296875)` |
| Chọn slot 1 | `(-289.39801025390625, 1139, 1060.1400146484375)` | 0 | `(1, 1, 1)` | `(-289.04901123046875, 1313.3699951171875, 1408.3699951171875)` |
| Chọn slot 2 | `(1891.1300048828125, 1139, 1063.9599609375)` | 0 | `(1, 1, 1)` | `(1890.8599853515625, 1313.3699951171875, 1408.3699951171875)` |

- Hai pose tạo có quaternion `(0.9990310072898865, -0.04409569874405861, 0.0037784099113196135, 0.00016679000691510737)`.
- Ba pose chọn có quaternion `(0.9992520213127136, -0.04023699834942818, 0.00030515898833982646, 0.000012777200026903301)`.
- FOV dọc của cả năm pose là **65 độ**. C Render `0x27c9..0x27de` nhân `Math::fDeg2Rad` với hằng 65 tại `0x2bbda0`.
- Avatar tạo thường và model xem trước môn phái cùng scale **1.5**. Nhân vật ở màn chọn scale **1**. Scale tạo GL B **2.5** không áp cho S2.

Vị trí tạo: C Game constructor `0x641240`, các hằng tại `0x6413c0..0x641404`. Scale tạo thường tại `0x6416de..0x6416f3`; scale preview môn phái tại `0x6418ef..0x641904`. Ba vị trí chọn: constructor `0x63cb90`, assignments `0x63cd5a..0x63cdaa`, yaw tại `0x63cea4..0x63ceab`; scale chọn tại `0x63aa90..0x63aaa5`. Các mảng vị trí khác trong constructor chọn phục vụ trạng thái khác, không thay ba anchor trên.

`Tools/data/create_role_showroom.py` sinh `Data/Config/CysLoginShowroom.txt`: dòng scene, rồi đúng năm dòng nhãn `female`, `male`, `select0`, `select1`, `select2`. Mỗi dòng chứa **12 float** theo thứ tự `actorXYZ, yaw, eyeXYZ, quaternionWXYZ, fovY`; scale không nằm trong 12 trường này. Helper kiểm SHA scene S2 trước khi sinh. Native `Src/Client/WXClient/Procedure/CysLoginScene.cpp` đọc đủ năm dòng, kiểm giá trị và không nhận trường dư. Bridge POD tại `Src/Engine/Interface/CysLoginSceneBridge.h` dùng các con trỏ mượn trong cuộc gọi trên main thread.

## Camera gốc và phần chuyển cảnh chưa triển khai

Trong C, camera mode tạo là sex+1: mode 1 nữ, mode 2 nam; chọn là mode 3. Game gọi Gfx offset `0x228` tới Render `0x2b710`, rồi `CCamera_CharSel` tại `0x27a0`. Track được dựng trong Render `0x1dc0..0x254b`:

| Track | Tên gốc | Độ dài | Pose dùng khi đứng yên |
|---|---|---:|---|
| 0 | CameraTrack | 0.5 s | Nam t=0; nữ t=0.5 |
| 1 | Role0To1 | 2 s | Slot 0 tại t=0 |
| 2 | Role1To2 | 2.5 s | Slot 1 tại t=0 |
| 3 | Role2To0 | 2 s | Slot 2 tại t=0 |

Khi vào chọn, C Game `0x63c0b8..0x63c0f0` chọn track bằng slot+1, không freeze, chạy ngược, cách cuối track 1.1 giây. Render `0x25e0..0x279f` đặt thời gian ban đầu; listener `0x3410..0x34a5` gọi import `AnimationState::addTime` với delta âm. Animation không lặp nên thời gian giảm về 0. Vì vậy intro vào màn chọn dài khoảng **0.9/1.4/0.9 giây**, còn góc đứng yên là keyframe đầu của từng track.

Bản CY-Source này dùng ngay năm pose đứng yên. **Chưa tái hiện các chuyển động camera intro/chuyển slot gốc**; đây là điều chỉnh có chủ ý của adapter, không được báo là đã khôi phục đầy đủ camera animation. Xoay actor và zoom tương tác được triển khai riêng. Không lấy thời gian giữa track 0.9/1.4 làm pose đứng yên.

## Ba mươi model xem trước môn phái

C Game `ShowModel` tại `0x63fac0` nhận ordinal 0..14; factory `0x641740` xác minh giới hạn 30 model. Hợp đồng model đã chứng minh là **model ID 4950 + sex × 15 + ordinal**, với sex 0 nữ, 1 nam. Đây là chỉ số nút xem trước, không phải ID môn phái của bản ghi nhân vật hoặc yêu cầu tạo gửi server.

| Ordinal UI | Nhãn | Model nữ | Model nam |
|---:|---|---:|---:|
| 0 | Thiếu Lâm | 4950 | 4965 |
| 1 | Minh Giáo | 4951 | 4966 |
| 2 | Cái Bang | 4952 | 4967 |
| 3 | Võ Đang | 4953 | 4968 |
| 4 | Nga Mi | 4954 | 4969 |
| 5 | Tinh Túc | 4955 | 4970 |
| 6 | Thiên Long | 4956 | 4971 |
| 7 | Thiên Sơn | 4957 | 4972 |
| 8 | Tiêu Dao | 4958 | 4973 |
| 9 | Mộ Dung | 4959 | 4974 |
| 10 | Đường Môn | 4960 | 4975 |
| 11 | Quỷ Cốc | 4961 | 4976 |
| 12 | Đào Hoa Đảo | 4962 | 4977 |
| 13 | Tuyệt Tình Cốc | 4963 | 4978 |
| 14 | Ác Nhân Cốc | 4964 | 4979 |

Nhãn 12/13/14 đã đối chiếu ảnh CY thật: khóa `Icon_Kunlun/Cs_Kunlun` là Đào Hoa Đảo; `Icon_Hongming/Cs_Congren` là Tuyệt Tình Cốc; `ERenGu` là Ác Nhân Cốc. Không đặt nhãn theo tên khóa dễ gây nhầm. Bằng chứng ảnh ở `Build/Logs/2026-09-13-gpt-create-role/profile/original-art`, được ghi trong spec profile.

S2 `Config/CharModelEx.txt:4153` bắt đầu 30 dòng này. Actor lấy từ cột model thường, tức cột 1 tính từ 0; cột 2 là model IV. Row 4979 có actor thường `M_cloth_ERG_2024高模.obj`, còn cột phụ là CR_2021; không chọn cột phụ để xem trước. Tên actor `.obj` là khóa Object trong `Model/all.obj`, không phải yêu cầu một file `.obj` rời cùng tên.

Đã xác nhận 30 Object tồn tại và toàn bộ 226 tham chiếu mesh của chúng có file trong Model/Model2..8. Công thức GL B `2644 + sex × 12 + ordinal` không tương thích S2: các ID 2664..2667 của S2 là sói. Không bù model thiếu bằng actor khác. Kiểm này chỉ chứng minh actor/mesh tồn tại; closure vật liệu, skeleton và animation phải được kiểm riêng theo profile và runtime.

## Quy tắc binding và giới hạn kiểm chứng

- Layout/controller giữ sự kiện gốc. `ShowCreatePreview(id, sex)` chỉ đổi model trình diễn và nội dung panel; `HideCreatePreview` trả về ngoại hình đang tạo. Không gọi tạo nhân vật hoặc gán môn phái server khi bấm preview.
- `GetCreateOptions` trả bảng Lua 1-based; các lựa chọn native `ApplyCreateAppearance` dùng chỉ số 0-based. `SelectRoleSlot` nhận slot 0..2, thành công trả 1. Thẻ chọn liên kết record thật; không dùng chỉ số xóa nhân vật thay selection state.
- Cảnh/actor do native Game quản lý. Các lần đổi mode, ẩn, giải phóng actor phải xử lý visibility và dừng xoay/zoom, không giữ con trỏ UI hoặc actor đã hết lifetime trong renderer. ActorVisible/CameraPose đi qua export bổ sung, không thêm virtual slot dựa trên vtable C/B.
- Dữ liệu tài nguyên giữ nguyên khóa GBK; chỉ nhãn hiển thị chuyển UTF-8. Font NotoSansSC-Regular.ttf và bảng StrFilter để trống theo profile chung. Không đổi bộ sáu tệp đăng nhập hoặc nguồn S2 trong việc ghép cảnh.
- Original Lua S2 có header mã hóa, chưa được giải mã trong công việc này. Controller CY-Source là mã mới có workflow tham chiếu GL plaintext; không nhận là mã Lua CY gốc được phục hồi.

Bằng chứng static không chứng minh Game.exe tự build đã hiển thị đúng hoặc tạo nhân vật thành công. CI, ảnh GPU, census lỗi, thao tác và đối chiếu server thuộc báo cáo tích hợp riêng. Phần charlogin/vào thế giới không nằm trong đặc tả tham chiếu này.

## Artifact để tái kiểm

Thư mục bằng chứng: `Build/Logs/2026-09-13-gpt-create-role/original-reference`.

- `original-routing_vi.md`: báo cáo điều tra ban đầu, trước xác nhận ảnh nhãn 12/13/14.
- `c-showroom-poses.json`: identity C, năm pose binary32, mỗi pose có mảng đúng 12 float.
- `c-camera-keyframes.json`: bốn track, 11 keyframe; quaternion track 3 đã được kiểm lại bằng đối số constructor thực. `c-camera-validated-imports.json` xác nhận các import liên quan.
- `c-loadscene-62b7e0.txt`, `c-create-loadscene.txt`: route tải cảnh; file thứ hai có tên cũ nhưng nội dung là CharSel Init tại `0x63c000`.
- `c-create-ctor-anchors.txt`, `c-normal-factory.txt`, `c-sect-factory.txt`, `c-select-ctor.txt`, `c-select-actors.txt`: vị trí, yaw và scale.
- `c-render-camera-tracks.txt`, `c-render-camera-mode-endpoints.txt`, `c-render-select-track.txt`, `c-render-camera-frame-listener.txt`, `c-render-camera-track-names.txt`: camera, timing và tên track.
- `c-show-model-complete.txt`, `s2-sect-preview-rows.json`: công thức model, 30 bản ghi nguồn và tham chiếu mesh.
- Các file `b-create-*`, `b-select-*`, `b-render-sky-*`, `b-render-charcam-*`: đối chiếu GL B và chỉnh lại nghĩa hai tên sky.

Tài liệu này chỉ lưu kết luận và metadata cần triển khai; disassembly cục bộ không được chép vào đặc tả tracked.
