# Tàng Kinh Các và vòng đời giao diện — 29/09/2026

Đợt này xử lý lỗi sự kiện Tàng Kinh Các gọi quái không tồn tại, các lỗi tạo NPC/phụ bản liên quan và lỗi Lua khi thoát game lúc đối thoại còn mở. Không đổi trạng thái toàn bộ 143 mục HJ05 thành hoàn tất.

## Nguồn đối chiếu và dữ liệu

Server và client CY thiếu cả họ monster GL **13565–13600**, gồm bốn loại model, mỗi loại chín mức dữ liệu. ID 549 của CY chỉ là một võ tăng cùng tên, không thay thế được toàn bộ họ này.

Đã đối chiếu tên tài nguyên và tỉ lệ trong `CharModelEx` GL/CY: model 1607, 299, 417 và 2305 có đúng tài nguyên gốc tương ứng. Giữ action/model CY; không chép chỉ số model của GL chỉ vì trùng ID. Bảng server lấy 71 cột theo schema GL đang dùng; DBC client có 73 cột, chuyển bằng mapping đã có trong `cs3c_tables.py` và giữ trường riêng của CY từ mẫu võ tăng CY.

36 monster dùng dải trống **113565–113600**. Bảng client được phát hành qua hai overlay Pre/Post; CanonicalCY và client_GL vẫn là nguồn chỉ đọc. Các dòng client cũ và phần đầu string pool được đối chiếu nguyên vẹn. Không tự đặt thêm drop hoặc phần thưởng không có nguồn.

- [Sổ ID](../../Registry/import/cangjingge-monsters-20260929.json).
- [Công cụ tạo và áp bản sửa](../../Tools/server/cangjingge_repair.py).
- [Khảo sát tài nguyên](../../Build/Logs/2026-09-29-cangjingge/asset-survey.json).
- [Manifest server/client](../../Build/Logs/2026-09-29-cangjingge/manifest.json).

## Các lỗi đã sửa

- Mở lại sự kiện không sinh thêm 17 NPC trùng. Mỗi NPC ghi vị trí sinh vào tham số riêng; khi một số NPC đã được đội sử dụng, chỉ bổ sung đúng những vị trí bị thiếu.
- Chỉ xóa NPC đầu vào sau khi tạo phụ bản thành công. Nếu máy chủ không tạo được phụ bản, NPC còn để người chơi thử lại.
- Cấp trung bình có trọng số của đội được chuyển thành số nguyên trước khi dùng cho thuộc tính monster.
- Hai hướng xuất hiện tiểu boss lấy đúng họ cấp của đội, thay cho dòng quái cấp 80 cố định.
- Không dùng object rỗng khi tạo hộ tăng, quái thường, tiểu boss hoặc boss thất bại. Dừng lượt bị lỗi và đưa người chơi ra; không báo thành công giả.
- Chỉ cái chết của boss được lưu trong phụ bản mới rút ngắn thời gian kết thúc.
- Khi thoát game, ngừng gửi sự kiện UI vào Lua ngay từ `CGameProcedure::ReleaseStaticMember`, trước khi giải phóng bất kỳ hệ thống liên quan nào. CEGUI cũng kiểm tra trạng thái này trước khi đọc userdata/owner. Khởi tạo con trỏ môi trường script rõ ràng.

Lỗi thoát nằm ở thứ tự cũ: ScriptSystem xóa môi trường trước khi World/UI được giải phóng; các bước sau vẫn phát sự kiện. Chỉ chặn tại `CUISystem::Release` là quá muộn. Hai phiên đầu giữ nguyên lỗi để đối chiếu; bản cuối gọi export do chính `UI_CEGUI.dll` cung cấp trước quá trình hủy node. Không thêm thư viện hook/inject.

Nguồn client thay đổi: `GameProcedure.cpp`, `UI_CEGUI.cpp`, `UISystem.cpp`, `UIScript.cpp`, `UIWindowMng.cpp/.h`. Game và UI DLL được build bằng `Tools/build/build.cmd`, target `cys_wxclient` và `cys_uisystem`.

## Kiểm chứng và giới hạn

[Kiểm callback thật](../../Build/Logs/2026-09-29-cangjingge/tests.json): **320 assertion đạt**, kiểm trên ba file đã triển khai và hash manifest. Bao gồm mở sự kiện lặp, bổ sung vị trí bị khuyết, tạo thất bại, các mốc cấp 40–200 không vượt họ dữ liệu, đủ 13 đợt/184 monster, boss chết, trả đội về và giữ NPC khi tạo phụ bản không thành công. Đây là kiểm callback với scene/party giả lập, không phải một đội ba người chơi đã đánh xong cả phụ bản bằng GUI.

[Kiểm scene thật](../../Build/Logs/2026-09-29-cangjingge/live-result.json): gọi đường RPC sự kiện hiện có trên cụm CY riêng. Scene 18: 143→161→161, scene 24: 146→164→164, scene 30: 144→162→162. Lần mở thứ hai không tăng số NPC. Tạo được cả ba họ quái tấn công. [Biên log server](../../Build/Logs/2026-09-29-cangjingge/live-server-check-v2.json) không có lỗi mới.

Hai phiên nghiệm thu cùng manifest/binary cuối:

- [gui-3](../../Build/Logs/2026-09-29-cangjingge/gui-3/run.json): thấy bốn họ model, nhấp NPC qua đường lệnh chuột thật và nhận đối thoại server, di chuyển, thoát game khi đối thoại còn mở. Không còn `CYS Lua failure`, lỗi handler hay lỗi server trong biên thử.
- [gui-4](../../Build/Logs/2026-09-29-cangjingge/gui-4/run.json): đối chiếu 32 icon từ dữ liệu CY ở sáu trang kiểm thử, bấm icon/chữ, cuộn menu dài, Esc đóng đối thoại và di chuyển sau đóng. Catalog icon là fixture UI không gửi giao dịch; đối thoại ban đầu nhận từ NPC thật.

Đã xem trực tiếp ảnh bốn model, ảnh đối thoại còn mở khi thoát và trang icon. Cây trong bản đồ che một phần thân model. **Tên võ tăng dài vẫn bị giới hạn trên đường truyền, và nhãn “藏经阁” vẫn chưa Việt hóa**; không ghi hai điểm này là đã sửa trong đợt này.

`gui-1` và `gui-2` vượt world smoke nhưng còn lỗi Lua lúc thoát; không dùng làm bằng chứng phát hành. Các log này được giữ nguyên. Chưa nghiệm thu một đội người chơi hoàn thành toàn bộ trận 30 phút, toàn bộ thưởng/drop hay độ cân bằng phụ bản ở cấp 200.

## Phát hành và phục hồi

Công cụ [deploy_cangjingge.py](../../Tools/game/deploy_cangjingge.py) chỉ cho publish khi: bản Play gốc chưa thay đổi; Game/UI/PDB đúng build; các overlay cũ giữ nguyên; hai phiên GUI đúng manifest; callback/live scene/log đạt; đã kiểm ảnh; toàn bộ BSON test15 bằng bản sao đầu đợt. Công cụ sao lưu trước khi thay Game/UI/PDB và thêm hai overlay monster.

- Launcher: [Play.cmd](../../Build/world-gui/stage-play-21/Play.cmd).
- Kết quả và hash phát hành: [release-report.json](../../Build/Logs/2026-09-29-cangjingge/release-report.json).
- Server được sửa: `/home/ubuntu/cys-test-20260913`; không phải server GL chính.
- Phục hồi nhân vật: [verify.json](../../Build/Logs/2026-09-29-cangjingge/verify.json), đối chiếu toàn BSON sau khởi động lại cụm.
- Trạng thái cuối: [health.json](../../Build/Logs/2026-09-29-cangjingge/health.json), [log khởi động](../../Build/Logs/2026-09-29-cangjingge/boot-log-summary.json).

Năm monster thiếu 49285–49289 vẫn là phần còn mở. Model ID của chúng trùng số nhưng khác tài nguyên giữa GL/CY, nên không được nhập cùng cách với bốn họ đã xác minh ở trên. Stall hai người, thành bang/thương nhân/nghiên cứu, Mạn Đà/thiên phú và các ca còn mở khác tiếp tục được ghi trong [bảng 143 mục](hj05-remaining-20260928_vi.md).
