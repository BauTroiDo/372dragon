# Kiểm sáu chỉ số SelfEquip

Ngưỡng khóa trước runtime ngày 20/09/2026. Không dùng số dự đoán cho critical.

- Tài khoản test13 / GUID200014; không ghi DB. Census được phép: vigor60/max60, stamina50/max50.
- Hai arm cùng Game.exe SHA và manifest; geometry giữ nguyên. Chỉ đổi `CYS_SELFEQUIP_STATS_OLD=1` (old) / bỏ biến (new), cờ được cache trong process.
- `CYS_UNEQUIP_LIVE=1`, `CYS_UNEQUIP_GESTURE=left`, `CYS_SELFEQUIP_STATS_LIVE=1`. Lua đo thật `Player:GetData`, text đọc qua SimpleText accessor. Sáu thành phần số ở bốn widget: critical hai ô, vigor/max và energy/max hai cặp.
- Old: cả sáu key và thành phần text là -1. New: critical bằng snapshot nhận trực tiếp từ mind_attack/mind_defend wire1772; vigor60/60, energy50/50; presence đủ63. Giá trị 0 chỉ được chấp nhận khi có bit hiện diện.
- Cả hai arm phải click trái qua C++ DoAction no-op, không gửi nhận tháo đồ; đóng SelfEquip; ba groundclicks điều hướng thành công; world/quit exit0. Checker không thay kiểm ảnh geometry.
- Chạy `python Tools/game/check_selfequip_stats.py --old <old-run> --new <new-run>`. Thiếu key, text, presence, đường đi hoặc khác SHA/manifest đều FAIL.

Không tự chạy Game.exe: cần khe do điều phối cấp. Runner hiện dùng `run-five.ps1 -Only unequip-left -Stats old|new`; clears environment và lưu flags trong selection.json. Luôn thư mục output mới.

## Bổ sung thứ tự sau đóng khung (khóa trước bản dựng kế tiếp)

Các lượt r10/r12 trước đây có ba lần di chuyển ở đầu replay, trước khi mở SelfEquip. Giữ nguyên verdict về sáu chỉ số, routing và tháo/khôi phục trang bị; các lượt đó chưa chứng minh di chuyển **sau khi đóng**. Checker mới không được dùng để đổi ngược verdict cũ thành một phép đo chưa chạy.

Từ bản probe có `CYS-SELFEQUIP-POSTMOVE`, hai arm bắt buộc đạt thêm [hợp đồng sau đóng khung](selfequip_postclose.md): khung ẩn, restore nếu có, ba đích riêng index4/5/6 với packet gửi và tọa độ thật thay đổi. Ba click1/2/3 vẫn là bằng chứng replay đầu phiên, không góp vào phép đo này. Checker stats và geometry đều gọi cùng bộ kiểm thứ tự.

## Native kiểm presence và wire

`selfequip_presence.cpp` tạo bytes theo writer combat.lua rồi gọi decoder ProtocolGen thật, không dùng packet.write. Gồm sáu delta riêng, zero/absent, owner khác, repeat, chuyển scene/login/close, full uint32, không alias CritRate/BATTLESCORE và truncated packet. Critical19/7 trong fixture là số tùy chọn của test, không phải số tài khoản test13.

Biên dịch tuần tự bằng g++ C++17: include `Src/Client/WXClient/Network` và `Src/Shared/ProtocolGen`; sources gồm file test, `PgPackets_combat.cpp`, `PgStructs.cpp`, `PgRuntime.cpp`; options `-O1 -ffunction-sections -fdata-sections -Wl,--gc-sections`. Output để dưới Build. Chạy executable và `python Tools/game/check_selfequip_stats.py --self-test`. Không cần Game/server/DB.
