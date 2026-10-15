# Kiểm di chuyển sau khi đóng SelfEquip

Ngưỡng bổ sung khóa ngày 20/09/2026, trước khi dựng/chạy bản chứa probe mới. Chỉ áp dụng lượt opt-in `CYS_UNEQUIP_LIVE=1`; không sửa hành vi gameplay. Mỗi arm dùng output mới, cùng binary/manifest theo phép A/B của arm, account test13; Game chỉ chạy khi điều phối cấp khe.

- Phải có đúng một snapshot `state frame closed` với `frame_shown=0`.
- Nếu RESULT có `taken_off=1`, snapshot `state restored` phải ở sau close và trước BEGIN. Phép tháo/khôi phục GUID vẫn do checker unequip hiện có kiểm riêng.
- Thứ tự bắt buộc: close → restore nếu có → BEGIN → REQUEST4 → OBSERVED4 → REQUEST5 → OBSERVED5 → REQUEST6 → OBSERVED6 → DONE → world script finished. Mỗi marker phải duy nhất.
- Mỗi REQUEST và OBSERVED có frame_shown=0. Mỗi đích chờ ít nhất2500ms, displacement từ tọa độ x/z trước/sau ít nhất0.5m; tổng ba độ dời ít nhất2m. Checker tính lại từ tọa độ, không tin số distance tự báo. Sai số làm tròn tối đa0.005m mỗi đích,0.01m tổng.
- Giữa REQUEST/OBSERVED phải có đúng một ground click cùng index, navmesh1/reachable1/waypoints>0/limit_move0; origin khớp trong0.02m. Phải có click-move sent>0 cùng origin/target (log chỉ một chữ số thập phân nên dung sai0.16m), ở sau ground request. Khi camera pick có error<1m, target thật dùng picked theo đúng ClickGround hiện hữu; checker đọc dấu vết đó thay vì so nhầm với nav candidate ban đầu.
- Ba click1/2/3 của replay ban đầu không tính cho post-close. Không nới ngưỡng theo kết quả runtime. PRECONDITION, thiếu marker, tọa độ không đổi, frame mở lại, không gửi lệnh hoặc sai thứ tự đều FAIL.

Đường đo là `LiveGroundClick → Player_MoveTo → AI → CGCharMove` cùng đọc tọa độ nhân vật thật từ client. Đây không phải phép click chuột OS hay CEGUI hit-test mặt đất, và không tự chứng minh server đã xác nhận vị trí. Giữ rõ giới hạn này trong bàn giao.

Chạy checker riêng cho mọi arm unequip: `python Tools/game/check_selfequip_postclose.py --run <run-dir>`. Stats và geometry tự gọi checker này. Chạy self-test bằng `--self-test` ở cả ba checker; fixture là log tổng hợp chỉ để kiểm negative, không phải bằng chứng runtime.

Bằng chứng r12-v5 giữ nguyên: 17 tab/routing và tháo/restore đã đo; ba ground clicks21:51:03/05/07 xảy ra trước frame close21:51:21/restore21:51:22, nên movement sau close là NOT_RUN. Bản bổ sung này đóng khoảng trống cho lần chạy kế tiếp, không đổi quá khứ.
