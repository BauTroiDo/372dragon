---
name: cys-mount-flight
description: "Sửa bay cao trên thú cưỡi CY-Source theo CY gốc: Ctrl+chuột trái, CharMount eligibility, CGFlyOperation, lưới .fly, action922–927 và kiểm navmesh khi hạ cánh. Dùng khi bay cao/hover/khinh công bị nhầm hoặc lệch client–server."
---

# Bay cao CY

Đọc [bằng chứng CY và bản port](C:/TLBB/085/CY-Source/Docs/specs/server/mount-high-flight-20260924_vi.md) và [giao thức/địa hình](references/protocol-nav.md). Gốc `C:/TLBB/085/CY-Source`, server riêng `/home/ubuntu/cys-test-20260913`; donor giữ chỉ đọc.

## Hành vi đã đối chiếu

- Đang cưỡi loại hỗ trợ: **Ctrl + chuột trái xuống nền** cất/hạ cánh. Khi đi bộ giữ luồng khinh công. UI có quyền nhận click trước thế giới.
- CharMount cột 19, offset `0x6c`, giá trị >=1 quyết định quyền bay cao. Cột 22/ground-hover chỉ làm thú lơ lửng; không cấp quyền bay từ vẻ ngoài hoặc tọa độ Y trong preview.
- Request native CGFlyOperation 2242 có body 5 byte (`objectID32 + op8`): 0 cất cánh, 1 hạ cánh. Op 2 không phải quyền đặc biệt. Server vẫn xác thực request dù client đã kiểm.
- Action 922 cất cánh, 923 hạ cánh, 924 đứng, 925/926 nghỉ, 927 di chuyển. CharModelEx CY tra actionset ở cột 20, không dùng ghi chú cột 9 của GL. Tra animation có sẵn, không lấy action chạy mặt đất cộng offset chung.
- Khóa chuyển động/động tác trong lúc cất/hạ cánh, `FreshAnimation` không ghi đè. Trên không có thể đi qua chướng ngại mặt đất, nhưng phải trong biên scene và đúng lưới bay. Hạ cánh chỉ tại nơi mặt đất đi được; hạ xong mới xuống/đổi thú.

## Phần port cần giữ rõ

Server 085 thiếu flight extension của GCCharBaseAttrib CY, nên phản hồi/AOI dùng 990030 theo implementation. Nội suy 2 giây/bốn trạng thái là quy ước của phần port; chưa chứng minh quỹ đạo/timing bằng native. Hỗ trợ người cưỡi đơn, chưa chở đội. Không mô tả mặt bay từ dữ liệu thành khả năng tự do tăng/giảm độ cao Y.

Code liên quan: `Network/CysRideNet.cpp`, `CysMountFlightPacket.h`, `World/CysFlightGrid.h`, Scene/Path/Cursor/Obj_Character/AI; server `Tools/server/cys_mount_flight.lua`, `cys_mount_flight_packet.lua`, `cys_flight_nav.lua`, `deploy_mount_flight.py`.

## Kiểm chứng thay đổi

Thử thú bay có hover, thú bay hover 0 và thú mặt đất; cất cánh → di chuyển trên không → hạ cánh nơi bị chặn → hạ cánh đúng → xuống thú → đi bộ. Gửi request trực tiếp để chứng minh server cũng từ chối chỗ bị chặn/thú không bay. Kiểm tọa độ NaN/inf/ngoài biên, scene thiếu grid, spam/callback cũ, chết/mất mount/chuyển scene và AOI theo mức thay đổi. Khi kết luận về hình ảnh người khác, cần lượt hai client, không suy từ unit test AOI.

Publisher `Tools/game/deploy_mount_flight.py` đã yêu cầu các probe độc lập cùng binary/manifest và baseline Play. `run.json passed` từng che probe hạ cánh FAIL; đọc cả marker tính năng. Phục hồi toàn BSON của fixture sau kiểm tra.
