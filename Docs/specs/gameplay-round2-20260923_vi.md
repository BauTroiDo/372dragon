# Gameplay và giao diện đợt 2 — 23–24/09/2026

Phạm vi: CY-Source và server riêng `/home/ubuntu/cys-test-20260913`.
Client GL/CY gốc chỉ đọc để đối chiếu. Không bật GLResponsive.
Candidate: `Build/world-gui/stage-round2-23`; đích phát hành: `Build/world-gui/stage-play-21/Play.cmd`.
Publisher lưu file trước sửa, mã băm và bằng chứng tại `Build/backups/round2-play/<thời điểm>/deployment.json`.

**Đã phát hành 24/09/2026 00:47:40**, 54 file đổi. Backup:
`Build/backups/round2-play/20260924-004740`. Game SHA256:
`4b1691faf533427a8762ee715b062cc268388ff002f924aec39fc9befc422327`.
`live-gm-8` và `live-tabs-final` kiểm trên đúng binary/manifest cuối, đều PASS;
đã kiểm ảnh GM/tên vật phẩm xuống dòng và tiêu đề Trận. Test00 và test15 đã khôi
phục toàn BSON gốc, kiểm bằng phép so sánh toàn bản ghi.

## Kết quả

| Yêu cầu | Thực hiện và bằng chứng |
|---|---|
| Ngoại hình chọn nhân vật | Đọc mặt, tóc, màu tóc, giới tính, trang bị, thời trang, huyễn sức và hai ô trang sức đã lưu; bỏ bộ khởi tạo cố định. Ảnh nhân vật thử ở lựa chọn và preview cùng áo xanh. |
| Huyễn sức che thân | Kiểm dòng visual và mesh đúng giới tính; thiếu dữ liệu trả về giáp/tay/giày. Quét 956 huyễn sức không đổi mesh/material thân, kiểm ảnh các mẫu hiệu ứng đỏ. Chưa tái hiện đúng tổ hợp trong ảnh người dùng, không kết luận mọi tổ hợp render đã hết lỗi. |
| Alt+số | Nằm trên F, canh cột, hiện mặc định. |
| Nhặt tất cả | Nối Lua tới nhặt thật theo GUID, duyệt cả ô trống xen kẽ. Bọc tự rơi từ quái, gửi lặp lệnh, tổng túi 250 → 251 cho đúng một món, bọc còn 0. |
| Tooltip cường hoá | Tên (+N), cấp và thuộc tính cộng lấy từ bảng server. Live +2: hai thuộc tính cơ bản75 được cộng +11. |
| Cổng bản đồ | Đối chiếu file scene CY/runtime, áp 203 đường trong108 file, kiểm406 điều kiện; giữ script cổng có điều kiện. Đi bộ Lạc Dương → Đôn Hoàng → Lạc Dương, không bật ngược, đi tiếp được. Chưa đi thử toàn bộ203 đường. |
| Kỹ năng phổ thông | Dồn action thật, không dành bốn ô đầu cho action thú không tồn tại, giữ lọc và phân trang. |
| Trận / Đấu / TH | Tab thứ ba là Trận. Có bốn icon/preview đọc SkillTemplate; chỉ kỹ năng đã học mới dùng. Đấu mở từ cấp50, sửa API từ bảy số thành mười bảng theo Lua CY. TH giữ điều kiện120/129, có thông báo khi bấm. |
| Thiên cơ cẩm nang | Kho riêng120 ô, lưu BSON thật, kiểm revision/GUID; cất/rút và đăng nhập lại giữ GUID và +2. |
| Túi100 / chồng250 | Hai vùng đồ/nguyên liệu100 ô, không đè nhiệm vụ. Chỉ đồ vốn cho phép chồng mới nâng250; trang bị/đồ không chồng vẫn1. Live249+1, lặp, ô100, tách100/150, gộp và đăng nhập lại. |
| EXP | Thông báo phần thực nhận, cập nhật tổng. Client dùng bảng server: cấp81 cần3.604.920, trước đây nhầm7.676.775. Cap floor(3,5×mức cần); không trừ EXP cũ của người đã vượt cap. Live1000 →1030 →1060. |
| GM Tool | Lua/layout GL, look CY riêng, giữ quyền server. Esc → GM Tool; tìm item có icon, Vô Lượng Sơn đúng ID6. Tài khoản thường bị từ chối. |
| Dừng đánh thường | Dừng tự lặp khi mục tiêu chết/biến mất; giữ đạn đã phóng. Live logic=0 trước khi probe huỷ thủ công. |

## Các giới hạn còn lại

Server giới hạn cấp119, thiếu script998633 của Thiên phú CY. Không tăng cap để giả mở TH.
Bộ thực thi tự chiến đấu đầy đủ CY chưa có: server chỉ có bảy cờ mission/đánh thường,
UI có thêm hồi phục, thú, vật phẩm và phó bản. Nút Bắt đầu báo rõ chưa được hỗ trợ,
không báo chạy giả. Mở tab Đấu không đồng nghĩa triển khai xong bộ tự chiến đấu.
Chưa tái hiện đúng món huyễn sức/tổ hợp trang phục trong ảnh tóc đỏ của người dùng.

## Lỗi nhân đôi đã bắt được

Đọc config qua Skynet có thể nhường quyền xử lý. Hai lệnh gộp giữ cùng tham chiếu
nguồn/đích; lệnh đầu xoá nguồn, lệnh sau dùng dữ liệu cũ dựng lại đồ đã tiêu thụ.
Hai lần live đầu bắt được251 thay vì250.
`round2_swap.py` sửa cả gộp/đổi và `item_operator:move_item`: chụp danh tính/số lượng
trước chỗ có thể nhường quyền, kiểm lại sau đó. Gửi identity trước dữ liệu chi tiết,
không bảo client đổi hai ô một cách mù quáng. Giữ vùng túi, khoá, bound, +N, ngọc và GUID.

- `inventory-deployed-final.log`: 91 ca PASS trên phương thức đã triển khai, có các ca nguồn/đích đổi trong lúc config nhường quyền, replay, túi đầy và kho phụ.
- `basic-deployed-final.log`: 13 ca PASS về cap, EXP, bag và loại chồng.
- `live-stack-3`: 249+1, lặp, ô99, từ chối qua vùng100, tách100/150 và gộp; bảo toàn lượng/GUID.
- `live-stack-relog-cosmetic-1`: BSON và client sau đăng nhập giữ250 ở ô99; 956 mẫu không đổi mesh/material thân.
- `live-tembank-3`, `live-tembank-relog-2`: cất/rút và đăng nhập giữ GUID/+2.
- `live-combat-2`: quái chết, EXP tăng, dừng đánh; bọc thật và nhặt lặp bảo toàn.
- `live-basic-3`: ô100, Alt/F, phổ thông, tooltip, EXP, di chuyển.
- `live-gm-6`, `live-gm-7`: quyền GM, item/cảnh, Esc; `live-gm-denied-1`: tài khoản thường bị từ chối.
- `live-tabs-1`, `live-tabs-redcosmetic-2`: Trận/Đấu/TH, không lỗi Lua; bốn ảnh hiệu ứng10100037/10192035/10192220/10192307 còn đủ thân, đóng UI đi bộ được.
- `live-portals-1`: generic `stats_in_world_with_objects` thất bại vì cổng không có NPC/player khác trong AOI; các check khác qua. Probe riêng xác nhận hai lần đổi cảnh thật và đi tiếp. Giữ nguyên kết quả generic, không đổi thành PASS.

Mỗi run.json lưu SHA binary/manifest. Publisher giữ mã băm cũ đúng lượt kiểm và yêu cầu
một lượt live trên candidate cuối. Không đổi bằng chứng build cũ thành build mới.

## Dữ liệu thử và vận hành

Toàn BSON gốc test15 GUID200016: `test15-original.json`; test00 GUID200001:
`test00-original.json`, cùng thư mục log. Phải khôi phục cả hai sau kiểm.
Test00 có GM98 từ trước; không cấp quyền cho tài khoản thường.
Server có backup/manifest riêng: `server-applied`, `tembank-applied2`, `portal-applied`, `swap-applied3`.
Private server đủ16/16 cổng và Mongo/MQTT/Manager/DataCenter/Tool/Game đang chạy.
Kiểm đọc server gốc thấy `tlbb-game` failed; không can thiệp vì phiên CY dùng server riêng.
Log private có cảnh báo tải hàng đợi, chưa thấy traceback mới trong các luồng vừa sửa.
