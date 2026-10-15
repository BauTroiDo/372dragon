# Triển khai prototype Võ hồn – Chiến hồn

Người dùng đã yêu cầu thực hiện ngày 25/09/2026. Bản đầu dùng pháp bảo do người chơi điều khiển, giữ nguyên toàn bộ Võ hồn/Huyễn hồn cũ và thêm hai vật phẩm thử riêng. Không tự chuyển đổi tài sản cũ.

## Hợp đồng dữ liệu

- Registry nguồn: `Registry/dual-souls.json`.
- Võ hồn Huyền Giáp `10156901`, equip point 18; Chiến hồn Xích Diệm `10156902`, equip point 39.
- Không lấy điểm 19 (Linh vũ), 37 (Thần binh), hoặc 38 (sentinel còn có nhánh logic cũ). Container dùng capacity 40; giữ nguyên giá trị HEQUIP_ALL để tránh đổi nghĩa các nhánh cũ.
- Cùng cơ chế GUID, giao dịch đổi trang bị, raw item và lưu BSON hiện có. Hai instance có GUID riêng. ItemInfo loại 2 giữ layout cũ. GCDetailEquipList đã có 84 vị trí nên không tăng kích thước packet.
- Hai vật phẩm mới có cấp 1 cố định ở prototype; chưa bán nâng cấp. Không dùng công thức KFS cũ để cộng thêm chỉ số lần nữa. Võ hồn nhận bị động qua mastery skill.
- Kỹ năng 6100–6103, SkillData 58000–58003. Dùng thông số/effect của CY 1379, 1397, 1541, 1583; ID và tên riêng, chưa cân bằng lại.
- Nhóm hồi chiêu 700–702 độc lập, không trùng nhóm của bảng SkillTemplate hai phía. Client tăng sức chứa nhóm hồi chiêu nhân vật lên 1024; trân thú giữ ABI hiện có.
- Quyền dùng chiêu lấy từ đúng item/đúng ô và thọ còn lại. Không tin mảng kỹ năng được sửa trong instance. Bị động 6100 không nhận lệnh cast.
- Khóa đổi/tháo hồn khi đang có động tác hoặc trong 10 giây từ lúc thi triển/bị đánh. Hồi chiêu theo chủ nhân được lưu qua `cool_down_times` hiện có.
- Hai chiêu tấn công dùng lịch va chạm riêng: 1.800/1.500 ms ra đòn cộng quãng đường / 15 m/s, theo Bullet126/132 của CY. Timer giữ impact đã chuẩn bị, bỏ khi người đánh/mục tiêu chết, rời scene hoặc object ID được tái sử dụng. Đòn diện rộng chỉ nổ sau khi đạn đến. Không sửa thời gian các chiêu cũ.

## Ngoại hình và protocol

- `KFSObj` giữ Võ hồn. `BattleSoulObj` là attachment riêng trên bốn actor nam/nữ/world/preview. Nguồn actor lấy từ override HJ mới nhất để giữ các liên kết cưỡi mới.
- Quy ước nhìn theo nhân vật: Võ hồn phải, Chiến hồn trái. Khi nhìn chính diện trong SelfEquip, Võ hồn nằm phía trái màn hình. Xương Bip01 quay hệ trục: Y cục bộ mới là trục ngang; không phản chiếu X. Vị trí hỗ trợ chỉ đổi với item mới; Render.dll áp offset vào child model, không sửa vị trí các model KFS cũ.
- State dùng GCUICommand index 990031, đúng 6 int: `[version=1, object_id, assault_item, assault_visual, assault_shown, support_item]`. Gửi sau ask_char_equipment (AOI) và khi đổi trang bị/ẩn hiện. State cũ được bỏ nếu khác version/độ dài.
- LCRetCharList không tăng 332 byte/nhân vật: sử dụng 10 byte trước đây ghi 0 (`anon9[5]`) với magic `0x5344`, version `1`, visual, low16(item), high16(item). Decoder chỉ đọc khi đúng magic/version; dữ liệu 0 của server cũ vẫn không có Chiến hồn. Không ghi đè các trường thú hồn, huyễn sức, bối sức, đầu sức.
- Layout, bảng kỹ năng/vật phẩm và actor được sinh vào candidate. CanonicalCY, client_GL và data HJ tham khảo giữ nguyên.

## Kiểm thử và phát hành

Nguồn test: `Tests/test_dual_souls_data.py`, `Tools/server/test_dual_souls.lua`, `CysDualSoulsProbe.h`.

Candidate: `Build/world-gui/stage-dual-souls-25`. Bằng chứng: `Build/Logs/2026-09-25-dual-souls`.

## Cách dùng prototype

1. Trong GM Tool, tạo mỗi loại một món: 10156901 (Võ hồn Huyền Giáp), 10156902 (Chiến hồn Xích Diệm).
2. Mở bảng Võ hồn, chọn **Song hồn**, hoặc bấm ô hồn mới trong SelfEquip.
3. Kéo vật phẩm từ túi vào ô cùng loại. Hai ô sử dụng giao dịch trang bị thật và GUID riêng.
4. Kéo các chiêu chủ động từ khung xuống thanh F/Alt+số. Huyền Giáp Hộ Thể tự có hiệu lực khi đeo, không kéo để thi triển.
5. Hai nút ẩn/hiện chỉ thay ngoại hình. Tháo hồn gỡ đúng kỹ năng; không xóa hồi chiêu.

Bản này có một loại Võ hồn và một loại Chiến hồn, cấp 1. Chưa mở nâng cấp trả phí, gắn chiêu tự do, thêm họ hồn, cộng hưởng hoặc chuyển tài sản cũ sang bộ luật mới. Cân bằng PvP, đổi mục tiêu khi đạn đang bay và chuỗi chết/hồi sinh cần lượt thử chuyên biệt; không gán các mục chưa thử thành PASS.

**Đã phát hành vào Play21 ngày 25/09/2026**, launcher `Build/world-gui/stage-play-21/Play.cmd`, server CY riêng `/home/ubuntu/cys-test-20260913`.

- GUI cuối `gui-08`: hai món được tạo bằng GM Tool thật, kéo vào hai ô, kéo chiêu xuống F1, F1/Alt+1/F2 thi triển được; sát thương đơn và diện rộng được nhận sau độ trễ. Cùng một đòn diện rộng đánh trúng hai quái khác nhau trong lượt cuối.
- Máy chủ từ chối tháo khi giao tranh. Tháo sau 10 giây gỡ đúng hai chiêu tấn công, Võ hồn vẫn giữ kỹ năng; đeo lại giữ cooldown. Giao dịch không sinh trùng GUID trong các trường hợp đã thử.
- `relogin-01`: cả hai món và bốn chiêu phục hồi, hai hồn hiện ở màn chọn nhân vật, thế giới và SelfEquip; chuyển Võ Đang (12) → Đại Lý (2) giữ đúng item, chiêu và ngoại hình. Luồng inspect đã nối dữ liệu nhưng chưa có lượt GUI hai người chuyên biệt.
- Cả hai lượt cùng SHA Game/manifest cuối, không crash, không lỗi handler/codec; nhân vật vẫn di chuyển sau đóng khung. Đã xem ảnh kết quả thật.
- 4 test dữ liệu/XML/actor đạt. Lua tests đạt quyền kỹ năng, cách ly slot, thọ, ẩn hiện, khóa đổi, gỡ buff đúng nguồn, lịch đạn và hủy timer khi chết/chuyển scene.
- BSON sau thoát có hai GUID riêng và cooldown 700/701/702. Sau thử, toàn bộ bản ghi Test15 đã được phục hồi và so sánh bằng nhau với bản sao gốc.
- 20 file server khớp hash triển khai; các tiến trình riêng và cổng 15733/15734 hoạt động. Lỗi thiếu cấu hình quái lúc nạp các scene khác là baseline, không tính thành kết quả kiểm thử hệ hồn.

Release report: `Build/Logs/2026-09-25-dual-souls/release-report.json`. Backup Play: `Build/backups/dual-souls-play/20260925-174515`.

Game SHA256: `0bc498613e0a19757cbacf4dce454e740b3a80fce19e805d90864f8fcdb990f6`.
Render SHA256: `33eecb7eae740cfded6d659e5cb0b657e5c68d362dab14b8290cdaa117ed5f0d`.
Manifest SHA256: `fa0bbba3ba0f9b163cdf26685faa4009cccbc23f6125011365071debcddf5fc8`.

Các lượt thử thất bại trước đó được giữ nguyên trong thư mục bằng chứng. Nguồn sinh UI đọc baseline trước phát hành để chạy lại không lồng thêm slot hoặc dòng InterfaceEx.
