# Võ hồn, Thú hồn, Thần đỉnh và Tu luyện — 24/09/2026

## Phạm vi chạy

Client nguồn `CY-Source`; bản phát hành qua `Build/world-gui/stage-play-21/Play.cmd`.
Máy chủ duy nhất được sửa là `/home/ubuntu/cys-test-20260913` (15733/15734).
Không sửa máy chủ gốc, `client_GL`, CanonicalCY hoặc snapshot WSL.

Đây là đợt nối chức năng và sửa tính đúng của bốn hệ thống. Bốn kinh mạch tiến giai
của CY còn thiếu xử lý hiệu quả môn phái trong server GL, nên chưa kích hoạt và
không thu phí. Không coi việc hiển thị 15 biểu tượng là 15 hiệu quả đã hoạt động.

### Võ hồn

- Dữ liệu cấp, trưởng thành, hợp thành, thuộc tính gốc/thực tế và thuộc tính mở
  rộng lấy từ vật phẩm thật. Số ô đã học đếm thuộc tính khác 0, tách với số ô mở.
- Sửa cấp đánh giá trưởng thành về miền 0–4 mà Lua đang dùng.
- CY gọi script hợp thành 790076 không có trên server này. Giao diện nay nối về
  CGKfsOperate/op3 của server GL: hai Võ hồn cùng cấp, tối đa cấp hợp thành 7,
  10000 vàng/giao tử. Giữ xác nhận tiêu Võ hồn nguyên liệu, tắt mua tự động bằng NB.
- Học thuộc tính chỉ trừ một cuốn sách trong chồng; không xóa cả 250 cuốn.
  Kiểm tra ô trống, thuộc tính trùng và khóa nguyên liệu trước khi thu phí.
- Mở rộng khung cục bộ, tách phần mô hình và các hàng số; giữ skin CY, không
  bật GLResponsive hoặc thay bộ co giãn dùng chung.

### Thú hồn

- Hỗ trợ vật phẩm class7/type1, catalog/icon GL riêng, tooltip có cấp, huyết mạch
  và sáu thuộc tính. Không ép cấu trúc này thành trang bị người chơi/class1.
- Nâng cấp 1–100 theo bảng cấp/phẩm thật, tiêu Thăng Hồn Đan và vàng/giao tử.
- Huyết mạch có sáu mức, một Hồn ngọc/lượt; đúng loại 20 EXP, loại khác hợp lệ 10
  EXP; giữ quy tắc vật phẩm đặc biệt của GL và chặn mức tối đa trước khi thu phí.
- Tẩy cơ bản: một nguyên liệu đúng phẩm + 50000 vàng/giao tử. Có hai cột thuộc
  tính hiện tại/kết quả, phải Nhận kết quả mới thay. GUID và revision ngăn nhận
  kết quả cho vật phẩm khác, gửi lặp không tiêu lần hai. Kết quả chưa nhận là
  trạng thái phiên, không tồn tại sau khi thoát game; giao diện ghi rõ.
- Giữ bộ đếm nguyên liệu tẩy MD505/509 để menu thưởng của Vân Thâm Thâm vẫn
  ghi nhận chi phí đã trả. UI gộp chưa có khóa từng dòng hoặc khóa màu.
- Hồi thọ dùng trường thọ riêng `pet_equip_unknow_8`, giới hạn từ PetSoulBase;
  không dùng hai byte độ bền thông thường vốn bằng 0 trên vật phẩm Thú hồn.
- Chọn thú, trang bị/tháo bằng CGPetUseEquip/CGPetUnEquip gốc. Kiểm tra quyền
  sở hữu, khóa, giao dịch, xuất chiến, dung hồn, cấp và ô trang bị trước khi đổi.
  Tháo khi túi đầy giữ nguyên vật phẩm; cập nhật lại túi và thông tin thú từ server.
- Các lệnh mở 80012701/02/08 của Vân Thâm Thâm mở giao diện gộp này.

### Thần đỉnh

- Hai nhánh Càn Nguyên/Côn Võ, mỗi nhánh 45 đan qua chín phẩm; chi phí và điểm
  tăng trích từ script CY, không đặt số tùy ý.
- Nạp Dược Trần tiêu một vật phẩm có thật. Kim đan phải đúng nhánh, đủ phẩm.
- Thể lực và bốn công thuộc tính cộng vào bộ tính chỉ số của nhân vật, lưu độc
  lập với trang bị. Phân phối kiểm tra tổng điểm; thu hồi điểm tốn 2000 Dược Trần.
- Giao dịch có revision để chặn gửi lặp. Server sở hữu toàn bộ chi phí/kết quả.

### Tu luyện

- Hai bộ tu luyện thường gồm 11 bí kíp có chi phí, công lực và hiệu quả thật.
  Nhân vật cần cấp 70; quyển hai yêu cầu cảnh giới quyển đầu theo Lua CY.
- Dùng CY XiuLianDetail 2416 hàng/63 cột, đủ dữ liệu các môn phái CY; packet1014
  đồng bộ 15 cấp/15 giới hạn cho giao diện CY. Bốn dòng tiến giai chỉ hiển thị,
  HasActived=0 và máy chủ từ chối nâng/thu phí.
- Cấp tối đa tu luyện 150. Cảnh giới tăng 10 cấp đến 60, sau đó 15 cấp; phí,
  điều kiện bí kíp đồng bộ theo giao diện. Giữ cấp cũ khi di trú giới hạn.
- Công lực lấy từ GCDetailAttrib thật, phát UINT_POWER, không còn giá trị -1.
- Luồng XiulianStudy của NPC nâng cấp/nâng cảnh giới sử dụng chính thao tác UI.

## Cách mở để kiểm tra

- Võ hồn: tab **VH** trong bảng nhân vật; thao tác tại **Vô Nhai Tử**, Đại Lý
  khoảng **140,195** (script002099).
- Tu luyện: tab **TL** để xem; **Tảo Địa Thần Tăng**, Đại Lý **242,31**, chọn
  tu luyện hoặc nâng cảnh giới (script900008).
- Thần đỉnh: tab **TĐ** trong bảng nhân vật. Nạp Dược Trần, chọn nhánh và Ngưng;
  nhánh Côn Võ dùng nút cộng và xác nhận để phân phối điểm.
- Thú hồn: **Vân Thâm Thâm**, Tô Châu khoảng **177,240** (script800127), chọn một
  mục nâng Thú hồn/huyết mạch/tẩy; kéo vật phẩm từ túi vào ô. Thu hồi trân thú
  trước khi Trang bị/Tháo. Tọa độ lấy từ `dali_new_320_monster.ini` và
  `suzhou_new_monster.ini` đang chạy trên server riêng; chưa kiểm tra đường đi
  tới từng NPC trong đợt này.

## Kiểm thử và phát hành

- `Tools/server/test_power.lua`: 47 kiểm tra dùng bảng server thật và lớp vật
  phẩm thật, vận chuyển/lưu trữ được mô phỏng. Bao gồm chi phí, giới hạn,
  gửi lặp, đổi GUID, phần trăm, đếm thưởng, quyền sở hữu/khóa và sách 250 cuốn.
- `Tools/server/test_equipment_skills.lua`: 38 kiểm tra hồi quy đã đạt.
- `CYS_POWER_SYSTEMS_LIVE=1`: test15 có bản sao BSON toàn bộ; kiểm tra hai nhánh
  Thần đỉnh, chỉ số nhân vật thật, hợp thành Võ hồn, UI Tu luyện, kéo Thú hồn
  bằng pointer, nâng/tẩy/nhận/trang bị/tháo và di chuyển sau khi đóng khung.
- `CYS_POWER_SYSTEMS_LIVE=2`: đăng nhập phiên mới, kiểm tra các giá trị đã lưu.
- Bằng chứng từng lượt nằm trong `Build/Logs/2026-09-24-power`; không dùng PASS
  của runner đăng nhập làm bằng chứng thay cho RESULT của kiểm tra chức năng.
- `Tools/game/publish_power.py` yêu cầu cả hai chế độ đạt trên đúng hash exe và
  manifest; sao lưu trước khi chép vào Play. Không chép/xóa junction Data.
- `Tools/server/power_live_fixture.py restore` khôi phục nguyên BSON của test15.
  Bản sao nằm ngoài source trong `Build/Logs/2026-09-24-power/test15-original.json`.

Đã phát hành vào `Build/world-gui/stage-play-21` lúc 10:12 ngày 24/09/2026:

- Lượt cuối `live-09`: `RESULT mode=1 errors=0`; `live-10` đăng nhập lại:
  `RESULT mode=2 errors=0`. Cả hai dùng cùng exe và manifest, di chuyển thật
  sau khi đóng giao diện, thoát bình thường, không lỗi xử lý packet.
- Game SHA256: `b07894047bdc183d74b9e63f9b7066ea108541c432d40d5d03af40c0ad7fcf6f`.
- Đã xem ảnh trong game của Võ hồn, Tu luyện, Thú hồn và Thần đỉnh. Sửa vùng
  cắt của khung cha chứa số phân phối Côn Võ; ảnh cuối hiển thị Băng 6/Hỏa 4,
  đúng với chỉ số thật đã được kiểm tra.
- Năm Lua giao diện biên dịch cú pháp bằng chính LuaPlus 5.0 của client đạt.
- `fixture-after-live.txt` ghi nhận dữ liệu lưu sau đăng nhập lại;
  `fixture-restore.txt` xác nhận `PASS exact BSON restore test15`.
- Client thay 38 tệp; sao lưu tại
  `Build/backups/power-play/20260924-101222`. Bộ triển khai giữ hồ sơ Play hiện
  có và đối chiếu SHA256 của toàn bộ các tệp overlay sau chép.
- Server có 18 tệp khớp manifest triển khai; lần cập nhật cuối sao lưu tại
  `/home/ubuntu/cys-test-20260913/backups/power-20260924-095755`.
  Bản sao đầu đợt tại `power-20260924-085821`; không dùng riêng bản sao cuối
  để hoàn tác toàn bộ đợt vì nó chỉ giữ các tệp đổi trong lần áp đó.
- `status-final.txt`: cả sáu dịch vụ server riêng chạy, 16/16 cổng, không còn
  client thử kết nối. `server-final-verification.json` ghi hash và log kiểm tra.
  Server riêng dùng loopback 127.0.0.1:15733/15734 theo hồ sơ `cys-server`.

Chưa xác nhận mọi phẩm Thú hồn, mọi tổ hợp kỹ năng/môn phái, mọi mức cấp và
độ phân giải trong game. Ranh giới chi phí và cấp có kiểm tra tự động. Không
tuyên bố bốn kinh mạch tiến giai hoặc khóa dòng/khóa màu đã hoàn thiện.
