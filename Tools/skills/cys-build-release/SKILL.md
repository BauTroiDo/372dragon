---
name: cys-build-release
description: "Build, kiểm thử, phát hành và kiểm toán EXE/DLL của CY-Source trong C:/TLBB/085; quản lý candidate Play, server WSL riêng và bằng chứng đúng binary. Dùng khi build/publish, chẩn đoán phiên thử, kiểm tra hook/inject hoặc đo hiệu năng CY."
---

# Build và phát hành CY-Source

Gốc dự án là `C:/TLBB/085/CY-Source`. Đọc `C:/TLBB/085/AGENTS.md`, `Docs/00-DOC-TRUOC_vi.md`, phần liên quan của `Docs/08-BAY-VA-QUY-TAC_vi.md` và [kiểm toán cấu trúc hiện có](C:/TLBB/085/CY-Source/Docs/10-CAU-TRUC-VA-KIEM-TOAN-BUILD_vi.md). Các mốc ngày tháng là bằng chứng lịch sử, không tự chứng minh bản đang chạy hôm nay.

## Xác định đúng bản chạy

- Đến 25/09/2026, launcher người dùng là `Build/world-gui/stage-play-21/Play.cmd`; đầu ra build là `Build/cmake/coord-x64/bin`. Đọc launcher, CMake cache và manifest hiện tại trước khi chọn đường dẫn.
- Server của CY là `/home/ubuntu/cys-test-20260913` trong WSL `TLBB`, login/game 15733/15734, Mongo 27018, MQTT 1884. Không thay server chính `/home/ubuntu/GameServer` bằng các thao tác cho server riêng.
- `client`, `client_GL`, `Tools/DATA NEW/CY Game`, `Reference` và `Assets/CanonicalCY` là nguồn đối chiếu trong quy trình này. Viết code/generator/overlay trong CY-Source. Kiểm tra junction trước khi sao chép.
- Học bản đang hoạt động → kiểm tra các giả định về ID, giao thức, bảng và tài nguyên → áp dụng có căn cứ. Không coi một hàm Lua được khai báo là đã có backend.

## Chuỗi công việc

1. Chụp hash/manifest baseline, xác định PID Game có sẵn và thay đổi chưa commit. Dùng wrapper trong `Tools/build` cùng cấu hình đã có; không suy HEAD đại diện toàn bộ cây đang sửa.
2. Tạo candidate bằng stage/deploy tool của tính năng gần nhất. Sửa nguồn sinh thay vì chỉ sửa file trong Play. Nếu sửa static `cys_falagardex`, phải liên kết lại DLL `CEGUIFalagard`, không chỉ build static library.
3. Chạy kiểm tra phù hợp và probe chức năng thật. Một `run.json` chung đạt không thay thế marker kết thúc probe, ảnh đúng trạng thái và việc di chuyển sau đóng UI.
4. Với thay đổi lưu dữ liệu, kiểm tiền/vật phẩm/GUID sau thoát sạch và đăng nhập lại. Dùng fixture có backup đầy đủ rồi phục hồi chính xác.
5. Publish bằng công cụ có kiểm binary, manifest, overlay và baseline Play chưa đổi; sao lưu trước chép, giữ hồ sơ người chơi và junction Data. Launcher thường phải tắt cờ probe. Không chép binary mới rồi dùng log của binary cũ làm bằng chứng.

Đọc [vận hành và phiên thử](references/runtime-tests.md) khi chạy game/server. Đọc [kiểm toán và hiệu năng](references/audit-performance.md) khi người dùng hỏi nguồn gốc DLL, hook, shadow hoặc tốc độ nạp cảnh. Chọn test theo thay đổi; không chạy lại toàn bộ lịch sử chỉ vì có danh sách.

## Báo kết quả

Nêu bản đã kiểm, phần đã phát hành, nguồn đối chiếu, bằng chứng chức năng, trạng thái phục hồi fixture và giới hạn thực tế. Giữ các lượt FAIL và lỗi baseline. Khi chưa chạy được GUI, nói đúng phạm vi static/unit thay vì ghi tính năng đã hoàn tất.
