# Đợt sửa vận hành CY ngày 26/09/2026

Phạm vi: dọn build cũ; nút lên cấp và EXP; camera Phòng Thay đồ; cao độ bay; GMTool/Trân thú; tìm Võ Hồn–Chiến Hồn; lễ hộp trong Túi; các quầy Nguyên Bảo trống. Mọi lượt thử dùng nhân vật test15 trên máy chủ riêng `/home/ubuntu/cys-test-20260913`. Không sửa máy chủ chính `/home/ubuntu/GameServer`.

## Nguồn đối chiếu

- Lua và layout GL: `client_GL/Data/InterfaceFolder/Pet`, `GmTool`; ảnh `PetTujian`.
- CY: `Assets/CanonicalCY/Data/ConfigFolder/OptionalGiftBox.txt`, các khung `OptionalGiftBox_Two/Three/Four/Five`, `Model_Parameter.txt`, thuộc tính `Camera_Main` của actor, lưới `.fly` và action cất/hạ cánh hiện có.
- Hàm đọc bảng lễ hộp GL: `Game.exe` SHA-256 `ce0c4fec7666595ca7adb250fcd8075c28f04d1852d05111c88b730f57e1c763`, các địa chỉ `0x14023e220` và `0x14023e3e0`. Chỉ đọc để xác nhận thứ tự cột; không nạp/hook DLL của GL vào client.
- Cấu hình và các hàm tạo vật phẩm của máy chủ CY riêng là nguồn quyết định ID, số lượng, ràng buộc và giao dịch thật.

## Thay đổi

### EXP và lên cấp

`Player:IsCanLevelup()` trước đây vẫn là hàm rỗng trả 0. Hàm mới đọc EXP và mức cần lên cấp từ dữ liệu nhân vật thật. SelfEquip cho phép bấm khi đủ EXP và dưới cấp 200; điều kiện môn phái/tâm pháp vẫn do máy chủ xét. Bỏ khóa giao diện theo mốc vùng máy chủ CY gốc không áp dụng ở máy chủ riêng.

Rà 16 nhân vật thử: 15 nhân vật cấp 15 có 23.388 EXP, trong khi cần 5.847 và trần tích lũy hiện tại là 20.464. Đó là nguyên nhân phần lớn tài khoản không nhận thêm EXP. Không xóa phần EXP đã có vượt trần. Thông báo khi đầy EXP được đổi sang tiếng Việt; tooltip nút lên cấp cũng giải thích mức 3,5 lần.

### Cao độ bay

Lấy cao độ lớn nhất hữu hạn trong lưới `.fly` làm mặt phẳng bay cố định cho bản đồ. Trong trạng thái bay hoàn toàn, tọa độ Y bằng mặt phẳng này; trong cất/hạ cánh, nội suy giữa nền tại vị trí hiện tại và mặt phẳng. Bỏ phép lấy max với nền vốn làm nhân vật nhấp nhô khi bay ngang.

Giữ điều kiện CharMount, gói CGFlyOperation, khóa thao tác lúc chuyển trạng thái và kiểm tra vùng đi được trước khi hạ cánh. Cách điều khiển vẫn là Ctrl + chuột trái theo luồng CY đang có.

### GMTool và Trân thú

GMTool dùng model ID do máy chủ trả về; bỏ phép tìm trùng tên trong sách trân thú GL vì đây không phải ánh xạ ID. Nối `DataPool:GetMonsterNameAndIcon`, `SetRabbitModel` với bảng thật, bổ sung ảnh PetTujian bị thiếu. Camera dùng `Camera_Main` → `Model_Parameter`.

Phát hiện đường XSCRIPT cũ chỉ chứa sáu số nguyên, trong khi lệnh tạo trân thú cần mười. Đường modern hiện đóng gói đủ số tham số theo giao thức (tối đa 255), giữ nguyên cấu trúc/ABI legacy sáu tham số. Có kiểm tra gói 0/6/8/10/255 tham số và gói bị cắt.

Khung Trân thú giữ widget/callback CY, nới khoảng cách phù hợp font Việt. Đổi model theo thứ tự GL: detach → SetModel → attach. Giữ camera tác giả trong Model_Parameter: thử giảm khoảng cách đồng loạt làm thú có animation bay bị cắt ở mép trên nên đã gỡ. Tiêu đề dùng tên instance đã được giải mã từ gói mạng; tránh đưa chuỗi GBK của tên loài vào widget UTF-8. Các nhãn tư chất rút gọn thành TC để chừa đủ chỗ cho giá trị.

GM search được tạo lại từ bảng hiệu lực của Play và các ID tồn tại trên máy chủ. Tìm được cả mã ID và tên. Võ Hồn/Chiến Hồn dùng luồng tạo vật phẩm riêng của máy chủ; không đưa qua bộ tạo trang bị thường vốn không hỗ trợ loại equip này. Hai file `Patch/Plugin_GameSearch.dll` và `Plugin_GmEquipRules.dll` là bảng văn bản TSV mang đuôi DLL, không phải thư viện PE.

### Phòng Thay đồ

`Model_Parameter` đang có tác dụng: cột height/distance là tâm nhìn và khoảng cách camera, không phải hệ số scale mesh. Lua có thể thay camera cho một góc xem cụ thể. Thú cưỡi HJ có thông số `ExteriorRideCamera` riêng; thú cưỡi còn lại dùng Camera_Main.

Bỏ tái tạo RTT khi chọn lại cùng model thú cưỡi. Không cập nhật nhân vật thử đồ khi đang chuyển vào tab chỉ xem thú cưỡi. Việc đổi model thú cưỡi thật vẫn detach trước để tránh giữ con trỏ render của entity cũ.

Kiểm ảnh còn phát hiện lỗi độc lập: AttachWindowEx được gọi khi widget đang ẩn; lần hiện sau đó không phát MeshShown nên RTT mới không chạy, có thể hiện nội dung cũ trong vùng nhớ texture. Thêm onShown/onHidden cho FalagardMeshWindow để bắt đầu/dừng cập nhật theo chính widget. Đã đối chiếu cùng model HJ 2094/visual 2087: trước sửa vẫn thấy nhân vật, sau sửa thấy đúng thuyền ngay lần chọn đầu. Đây là lý do kiểm tra con trỏ render khác null chưa đủ.

Hai lần duyệt nhanh 91 model HJ có ghi CSV CysPerf. Tập đo gồm thời gian chọn/nạp model và chụp bằng chứng, không phải benchmark chơi bình thường. Lượt đầu p50/p95/p99/max là 13,054/24,975/59,061/558,600 ms; lượt sau 12,751/22,032/45,289/117,359 ms. Cache hệ điều hành đã ấm hơn ở lượt sau, vì vậy **không quy phần chênh lệch này thành mức tăng FPS của bản sửa**. Các frame nặng còn nằm ở nạp tài nguyên khi đổi model và render; chưa tuyên bố hết khựng ở tất cả thú cưỡi. CYS_PERF_ALLOC=0 trong cả hai lượt, không bật bộ chặn malloc chẩn đoán.

### Lễ hộp

Khôi phục các API đọc OptionalGiftBox theo bố cục GL và `PlayerPackage:GetItemTableIndex` theo ô Túi thật. Khung chọn quà gọi script 990031 trên máy chủ riêng. Máy chủ tự tra phần thưởng, chỉ nhận lựa chọn; kiểm tra cấp, vị trí, object vật phẩm, khóa túi, trạng thái bay. Đóng phiên nhận trước bước sinh GUID có thể yield; kiểm tra lại đúng hộp ngay trước khi trừ một hộp và cấp quà.

Đăng ký script có hai nơi: danh sách module `scripts.lua` và `configs/AllowableScriptFunc.txt` của msgagent. Thiếu nơi thứ hai khiến mở hộp thành công nhưng yêu cầu nhận bị bỏ qua. Bổ sung riêng `990031 / OnClientGetGift`.

Lượt thử bằng chuột còn phát hiện các khung con của SuperTooltip chặn nút dưới chúng. Đặt MouseHollow/MouseMoveHollow cho toàn bộ cây của tooltip chính và hai khung so sánh; chỉ đặt ở gốc không đủ vì CEGUI xét con trước cha. Cuộn mô tả dài vẫn đi qua nhánh `scrollContent` riêng trong UISystem.

Đợt này nối 100 dòng OptionalGiftBox thông thường có đủ vật phẩm thưởng trên máy chủ. Còn 97 dòng đặc biệt/thiếu phần thưởng và bảng CommonGiftBox chưa đủ bằng chứng về quy tắc; không đoán phần thưởng hoặc tiêu hao vật phẩm ở những dòng đó. Vật phẩm có script chưa được triển khai được báo rõ ID và giữ lại trong Túi.

### Quầy Nguyên Bảo

Sinh danh sách quầy có hàng từ script shop và ShopTable máy chủ. Ẩn quầy con rỗng, xếp lại vị trí hiển thị, giữ nguyên tọa độ A/B gửi lên máy chủ. Đường tìm kiếm cũng dùng cùng danh sách. Cần sinh lại overlay nếu thay dữ liệu shop.

## Kiểm tra và phát hành

Bằng chứng nằm tại `Build/Logs/2026-09-26-runtime-polish`. Các lượt thất bại được giữ lại, không tính là đã đạt. `run.json` ghi SHA Game.exe và manifest của từng lượt. Bộ phát hành yêu cầu đúng binary/manifest đã đạt các luồng UI, lễ hộp và đăng nhập lại, bay và thú cưỡi đất, đánh quái nhận EXP và census 91 model HJ; đồng thời yêu cầu phục hồi toàn bộ BSON test15. Các ảnh HJ trong probe runtime được lấy cùng nhịp đổi lựa chọn nên không dùng để xác nhận hình model; dùng các ảnh hj-census đã giữ lựa chọn qua nhiều frame.

`Tools/game/runtime_polish_ui.py` là nguồn sinh overlay; `deploy_runtime_polish.py` dựng candidate và phát hành có kiểm tra hash, sao lưu Play. `Tools/server/runtime_polish_server.py` lưu kế hoạch/hash và sao lưu sáu file máy chủ trước khi áp dụng, cộng bản sao riêng cho AllowableScriptFunc. Không sửa snapshot server.

Dọn build bằng `Tools/maintenance/clean_cy_builds.ps1`: 182 thư mục, 204.867 file, tổng dung lượng danh nghĩa 185,48 GiB. Giữ Play đang dùng, candidate Võ Thạch, candidate đợt này, `cmake/coord-x64`, worktree, log, backup và tài nguyên nguồn. Script kiểm tra đường dẫn tuyệt đối, reparse point và tiến trình đang dùng trước khi xóa.

Trạng thái phát hành cuối cùng được ghi trong `release-report.json`; không coi việc build hoặc vào được thế giới là đủ bằng chứng chức năng.

## Kết quả cuối ngày 26/09

Đã phát hành 41 file vào `Build/world-gui/stage-play-21` lúc 21:55. Backup tại `Build/backups/runtime-polish-play/20260926-215513`. Không thay launcher/profile; Play.cmd tiếp tục xóa cờ probe trước khi chạy. Hash đã đối chiếu cho 37 mục binary/PDB và 8.042 mục overlay sau khi chép.

- Game.exe: `07b525ba0812d7a02c2d25954caa4272411aa256e706e2470bb10fbbfc42768f`.
- CEGUIFalagard.dll: `4a59394e5b2005ee36912338a331a81f51d9a1c1781d2d18c82bf22c3a987d07`.
- Manifest: `b41babb6e6c0c131e12407ce0814df85549f075a8ab0eb662cd7ddb20eb57684`.
- Chín lượt GUI `release3-*` đạt trên đúng binary/manifest này: mở hộp, đăng nhập lại, UI/GM/lên cấp/shop, tự đánh nhận EXP, hai loại thú bay, thú mặt đất, 91 model HJ và bốn huyễn sức.
- Lên cấp thực tế: 15 → 16, EXP 11.694 → 5.847. Đánh quái bắt đầu 1.000 EXP, dữ liệu lưu sau thoát là 1.120.
- Hộp 38007057: từ 2 hộp/0 phần thưởng → 1 hộp/1 phần thưởng 38007035. Gửi lặp và đăng nhập lại đều giữ đúng số lượng, GUID không trùng.
- Rồng và diều: cao độ đầu/cuối đều 47,7613 trong bản đồ thử; từ chối hạ cánh vào vùng cấm và từ chối bay cho thú mặt đất.
- Huyễn sức 10100037/10192035/10192220/10192307: kiểm mesh/material thân không đổi và xem bốn ảnh, nhân vật còn nguyên. Không suy kết quả này thành mọi tổ hợp ngoại hình đều đã được thử.
- 91 ca giao dịch túi đạt; các ca riêng về hộp, packet XSCRIPT, lưới bay đều đạt. Bảy file triển khai trên server khớp hash kế hoạch.
- `fixture-restore.json`: `full_bson_equal=true`; nhân vật test15 được phục hồi toàn bộ dữ liệu gốc sau lượt cuối.

Các giới hạn còn mở: nạp lần đầu của model nặng vẫn có frame trễ; một số model nhỏ dùng camera tác giả nên còn nhỏ trong khung Trân thú; bản địa hóa/bố cục dài của toàn bộ tab Trân thú chưa hoàn tất. 97 dòng OptionalGiftBox chưa nối được phân loại trong `server/gift-excluded-details.json`: 56 có metadata thưởng riêng, 40 có cờ kích hoạt riêng, 6 thiếu vật phẩm thưởng trên server (các nhóm có giao nhau). CommonGiftBox chưa có quy tắc server được xác nhận.

Rà log máy chủ cuối đợt thấy ba traceback của sự kiện định giờ `bg_CangJingGe.lua:203` lúc 21:30, sau khi tạo NPC type 13565 thất bại vì thiếu cấu hình. Cùng lỗi đã có trong `Game2_20260925_191258.log` ngày 25/09 lúc 21:30; không phải lỗi của đợt sửa này và không được che đi. Không thấy traceback thuộc các tính năng vừa thay đổi. Chi tiết phân loại ở `server-log-check.json`.
