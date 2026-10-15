---
name: cys-inventory-transactions
description: "Sửa giao dịch túi/vật phẩm CY-Source và Skynet: chống nhân đôi khi gộp/tách/chuyển, nhặt tất cả, Thiên cơ cẩm nang, tiêu hao qua phím tắt hoặc chế tác. Dùng khi thay số lượng, GUID, vùng túi, phí hoặc lưu–nạp item."
---

# Giao dịch vật phẩm CY/Skynet

Gốc `C:/TLBB/085/CY-Source`; phạm vi runtime lịch sử là server riêng `/home/ubuntu/cys-test-20260913`. Xác minh phạm vi tác vụ hiện tại trước seed, migrate hoặc deploy. Học normal item handler của server và luồng Lua GL đang hoạt động trước khi thêm tuyến mới.

## Bất biến cần giữ

- Tổng lượng chỉ thay theo giao dịch hợp lệ; một instance GUID không xuất hiện hai nơi. Chuyển item giữ đủ bound/lock/+N/ngọc/tư chất và metadata đặc biệt.
- Túi đồ 100 ô, nguyên liệu 100 ô riêng; chỉ loại vốn cho phép stack mới nâng tối đa 250. Trang bị/đồ không chồng vẫn 1. Không mở 100 ô bằng cách đè vùng nhiệm vụ.
- Server quyết định phí/kết quả. UI cập nhật từ identity/packet thật; không swap hai ô mù quáng hoặc tự xóa item để tạo cảm giác thành công.
- Danh tính item gồm đủ GUID và loại; slot không phải danh tính, itemID không phân biệt hai món cùng loại.

## Chống nhân đôi ở điểm nhường luồng

Skynet đọc config hoặc cấp GUID có thể yield. Lỗi đã gặp: hai yêu cầu gộp giữ cùng tham chiếu; yêu cầu 1 xóa nguồn, yêu cầu 2 dùng tham chiếu cũ tái tạo đồ. Không chỉ thêm kiểm tra ở đầu handler.

Chụp GUID/số lượng/trạng thái/revision trước đoạn có thể yield, rồi đọc lại và so khớp sau đó. Với chế tác cần item thưởng, tạo trước để giải quyết cấp GUID, giữ chỗ thưởng và kiểm lại toàn input/tiền/quote. Invalidate quote trước thu phí; phần commit không được yield. Không hứa atomic nếu còn lời gọi RPC/config bên trong commit.

Đọc [đường túi và kiểm chứng](references/bags-and-tests.md) cho chỉ số vùng và các probe có sẵn. Nếu chỉ sửa tooltip, không chạy thao tác dữ liệu chỉ vì skill được chọn.

## Từ chối và khôi phục

Gói lặp/stale, source/destination thay khi yield, thiếu phí, túi đầy, khóa, cảnh đổi hoặc lỗi cấp thưởng phải giữ đúng đồ/tiền. Sau lỗi bất định, đọc trạng thái thực trước retry; đừng coi exception là giao dịch chưa xảy ra.

Kiểm tra có ý nghĩa gồm xen kẽ hai request tại yield, replay, biên 250/100 ô, metadata/GUID, disconnect/relogin và exact BSON restore của fixture. Các số 91 ca inventory trong lịch sử là bằng chứng của bản đó; dùng test hiện tại và hash thực khi sửa tiếp.
