# Chuột phải trang bị và xuyên thích — 25/09/2026

Phạm vi: CY-Source và server riêng `/home/ubuntu/cys-test-20260913`. Nguồn GL/CY và server chính chỉ đọc.

## Đối chiếu và lỗi đã tìm

- `GMActionSystem_Item.cpp::DoSubAction`: nhánh trang bị trong Túi chỉ xử lý giám định rồi thoát, không mặc đồ. Tuy nhiên layout Túi CY hiện bind `RBClicked → Packet_ItemBtnClicked → DoAction`; nhánh này đã mặc được đồ thường nhưng thiếu nhận diện khung chế tác. Cả hai cửa thao tác phải dùng chung quy tắc và luồng mặc hợp lệ `PacketItem_UserEquip`, có kiểm môn phái, cấp và giám định. Lượt `gui-02` xác định khác biệt giữa hai cửa thao tác này.
- Server `scenecore:ring_or_amulet_select_slot` đưa **số ô** vào comparator `table.sort`, trong khi comparator cần boolean. Sau khi đổi ô, `char_use_bag_equip` vẫn dùng món ở ô cũ để tạo GUID/index trả về, xóa hiệu ứng và lấy món đã mặc. Đây là nguy cơ hiển thị bản sao ở Túi khi ô thứ hai vốn trống.
- Hai biểu tượng `SelfEquip_HurtFastness`, `SelfEquip_DefenceFastness` là xuyên thích/kháng xuyên thích. Biểu tượng kế tiếp `SelfEquip_ShenDing_Icon` là Thần đỉnh.
- CY Lua đọc `ENCHANCEATT/ENCHANCEDEF`, nhưng host chưa nối các key này. Server thực tế công bố tổng dùng trong chiến đấu qua mission data 602/603; adapter nhiệm vụ 0.85 chỉ chứa 256 ô.
- Gói danh sách nhiệm vụ ban đầu chỉ gửi 200 ô ánh xạ, không chứa 602/603. Cần gửi riêng cả khi đăng nhập và chuyển cảnh. Lượt GUI đầu tiên bắt được thiếu sót này; giữ tại `gui-01`.
- CY `EnchanceSetAttr.txt` có mốc bộ từ 30/40/50/60. Server hiện dùng cơ chế riêng và lò rèn tối đa +9. Tooltip không được cộng một phần thưởng bộ CY mà server không tính.
- Thần đỉnh áp dụng thuộc tính thật nhưng chưa gửi snapshot lúc đăng nhập: trước khi mở trang Thần đỉnh, SelfEquip chỉ thấy các số 0. `gui-04` bắt được thiếu sót này; bổ sung `cys_shending.sync` bằng chính payload dùng cho trang Thần đỉnh, không tự mở cửa sổ.
- `character:on_damages` gửi sát thương xuyên thích riêng trong `mp_modification = -100000 - damage`. Client đang đưa nguyên số này vào chữ bay mất MP. Data CY `BeHit.txt` có sẵn hàng 13 (gây xuyên thích), 14 (nhận xuyên thích).

## Thay đổi

- Chuột phải trang bị gọi luồng mặc có kiểm tra; món khóa không được thao tác. Khi mở Cường hóa hoặc Thăng Linh/Điêu văn thì chọn vào ô trang bị của khung, không tự tiêu phí.
- Chọn nhẫn/hộ phù: ưu tiên ô trống; nếu cả hai đầy thì thay ô thứ nhất. Server chọn ô trước khi lấy món cũ, đổi nguyên instance rồi trả đúng GUID, index và ô đích. Vẫn hỗ trợ điểm trang bị mở rộng Võ hồn 18 và Chiến hồn 39 qua bảng dữ liệu.
- Giữ ABI nhiệm vụ cũ; chỉ thêm cache riêng hai tổng xuyên thích. Cache phân biệt chưa nhận với giá trị 0, cập nhật khi mặc/tháo và reset khi bắt đầu phiên.
- Bổ sung phát lại 602/603 sau danh sách nhiệm vụ trên hai nguồn `human.lua` của server. Không thay số ô hay độ dài packet.
- Tooltip hiển thị tổng thật và giải thích quy tắc hiện có; nhận sự kiện cập nhật khi SelfEquip đang mở. Thần đỉnh tiếp tục đọc bốn thuộc tính và Thể lực từ snapshot của hệ đó.
- Chữ bay xuyên thích bỏ dấu mã hóa 100000 và dùng kiểu chữ sẵn có 13/14; không hiển thị như mất MP và không sửa HP/MP từ dữ liệu chỉ dành cho hiển thị.

## Quy tắc chiến đấu được giữ

`P = max(xuyên thích người đánh − kháng xuyên thích mục tiêu, 0)`.

| Mục tiêu | Sát thương xuyên thích |
|---|---:|
| Người chơi | `ceil(P × 1)` |
| Quái/trân thú | `ceil(P × 5)` |
| Chí mạng bật theo server | Nhân đôi kết quả trên |

Các đường kỹ năng vẫn theo điều kiện kích hoạt vốn có của server. Danh sách đánh thường `CHUANCI_SKILL` và các đường gây sát thương trực tiếp không được đồng nhất hay mở rộng trong lượt này. Cường hóa chỉ góp xuyên thích từ +9 theo điều kiện hiện có; bảng `equip_enhanceex` và nhóm `CHUANCIGONGFANG` vẫn là nguồn tổng, không tự đổi phân loại hay cân bằng. Các trang bị hết độ bền/tuổi thọ không góp chỉ số theo đường tính hiện hành.

Ví dụ kiểm: vũ khí +9 góp 42; thêm nhẫn +9 là 84; thêm hộ phù +9 là 126. Mũ +9 góp 42 kháng. Quái có kháng 0 nhận thêm 630 từ xuyên thích 126 ở đòn đủ điều kiện, hoặc 1260 khi chí mạng, trừ các cơ chế miễn/giới hạn sát thương khác.

## Công cụ và bằng chứng

- `Tools/server/deploy_smart_equip.py`: tạo file từ baseline, kiểm cú pháp, hash và kết nối, sao lưu trước khi ghi bốn nguồn server riêng.
- `Tools/game/deploy_smart_equip.py`: stage riêng, giữ các DLL/data hiện tại, chỉ phát hành Game.exe/PDB và hai overlay SelfEquip khi đúng bằng chứng cùng hash.
- `Tools/server/test_smart_equip.lua`: chạy chính các method server đã vá, kiểm nhẫn/hộ phù cùng template khác GUID, hai ô trống/đầy, instance trả về, công thức xuyên thích và gói lúc đăng nhập.
- `Tests/net/piercing_snapshot_tests.cpp`: ranh giới cache, giá trị 0, cập nhật một phần, reset phiên, giải mã chữ bay và số âm biên.
- `CysSmartEquipProbe.h`: chuột phải qua cầu nhập CEGUI, thay vũ khí, nhẫn/hộ phù đôi, đồ hỏng, hai hồn, chọn đồ trong hai khung, hover ba icon, Esc và di chuyển, đánh quái bằng phím F1, đăng nhập lại.
- Fixture test15 có bản sao **toàn BSON của lượt này**, kiểm GUID/metadata và phục hồi chính xác. Kết quả cuối, ảnh và hash nằm tại `Build/Logs/2026-09-25-smart-equip`; chưa có `release-report.json` thì chưa xác nhận phát hành.

## Kết quả cuối và bản Play

Đã phát hành lúc 19:39 ngày 25/09/2026 vào `Build/world-gui/stage-play-21/Play.cmd` cùng server riêng CY. `release-report.json` xác nhận:

- Game.exe: `889d4d2fa9ec2d2cc3be66d89a3cc9542adb8fb9454b4006dee2dc258e675bc8`.
- Manifest: `47dbc0772b3a0e8a28191cdf7cd7295df2452320671d7b68d5ace31ae0fbcebb`.
- Sao lưu Play: `Build/backups/smart-equip-play/20260925-193948`.
- `gui-06`: PASS, 168,1 giây, `RESULT errors=0`; chuột phải thực tế qua CEGUI, chọn ô nhẫn/hộ phù, thay đồ cùng template khác GUID, Võ hồn/Chiến hồn, chọn vào Cường hóa và Thăng Linh/Điêu văn, hover ba tooltip, Esc và di chuyển.
- `relogin-01`: PASS, 110,1 giây, cùng Game.exe/manifest, `RELOGIN errors=0`. Tám ô đang mặc vẫn đúng; tổng xuyên thích/kháng là 126/42. Thần đỉnh hiện Thể lực 15, Băng 6 và Hỏa 4 ngay khi đăng nhập, trước khi mở trang hệ thống.
- `persistent-result.json`: 12 vật phẩm, 12 GUID riêng; giữ template, cường hóa, người chế tạo, tư chất và ngọc của các instance thử. Độ bền được phép giảm trong đánh thật.
- `restore-result.json`: toàn BSON test15 đã phục hồi bằng bản gốc của chính lượt này.
- `final-server-status.json`: sáu tiến trình riêng chạy, không trùng PID, các cổng riêng đang nghe. Log Game mới không có traceback/lỗi dispatch hay lỗi Lua của các nguồn thay đổi.

Đánh thường Võ Đang 371 qua F1 trên quái thật đã phát chữ bay kiểu 13, giải mã `-100629` thành 629. Ảnh `gui-06/cys-gl-111669250-smart-equip-combat.png` cho thấy chữ xuyên thích riêng dùng màu/style từ CY. Đây là **số cuối server gửi**: server chia các thành phần theo lượng HP thực mất, nên quy tắc làm tròn có thể cho 629 thay vì mức lý thuyết 630; đòn kết liễu chỉ còn 74. Client không tự tính lại hay cộng số 100000 vào sát thương.

Các unit test đã qua: method chọn ô/trả item trên server thật, công thức chênh lệch xuyên–kháng và hệ số/chí mạng, cache/biên giải mã, phát chỉ số lúc đăng nhập, payload Thần đỉnh 15 trường đồng nhất với trang nâng cấp và không tiêu tiền. Lượt này đã thử PvE trong game; hệ số PvP và chí mạng được kiểm bằng method server, chưa chạy hai người chơi đối kháng trực tiếp.

Giữ lại các lượt thử chưa qua để tra cứu. `gui-03` dừng do probe gọi `Show()` trước khi cửa sổ Cường hóa được nạp; probe cuối mở bằng UI command gốc. `gui-05` dừng ở setup chiến đấu do thiếu id/số lượng quái trong lệnh GM của probe; `gui-06` đã sửa setup. Bộ `test_power.lua` cũ qua 44 ca trước khi gặp fixture Võ hồn thiếu scene với guard chiến đấu hiện có; không dùng kết quả đó làm bằng chứng toàn bộ bộ kiểm thử đã qua.
