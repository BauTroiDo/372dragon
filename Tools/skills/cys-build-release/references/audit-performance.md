# Kiểm toán build và tối ưu không hạ chất lượng

## Nguồn gốc executable

Đọc [kiểm toán 24/09](C:/TLBB/085/CY-Source/Docs/10-CAU-TRUC-VA-KIEM-TOAN-BUILD_vi.md), tìm công cụ hiện có trong `Tools/audit`. Phân biệt bốn bằng chứng: source/CMake target; PE và hash so build; import/launcher; module thực sự nạp khi chạy. PDB nằm trong manifest không phải một DLL thực thi.

Mốc 24/09 có 18 PE: Game +12 DLL có source/target, 5 DLL SDK/runtime (`cg`, `fmod`, `fmodL`, `d3dx9_43`, `D3DCompiler_43`) có sẵn. 8/13 đầu ra trùng hash, 5 khác metadata đã kiểm `.text`. Không viết “100% DLL tự build” hoặc “reproducible sạch bit-for-bit”. Phải kiểm lại inventory cho bản mới.

Có hook nội bộ CysPerf trong Render khi bật `CYS_PERF`, và proxy D3D9 chẩn đoán riêng. Play được khảo sát nạp System32/d3d9.dll, không có proxy trong Bin64 và không thấy đường inject vào process khác. Kết luận này giới hạn ở launcher/module/lượt chạy đã khảo sát; không suy toàn cây không có hook hay máy Windows hoàn toàn sạch.

## Shadow và nạp cảnh

Người dùng ưu tiên độ đẹp, muốn nạp nhanh và frame ổn định. Câu hỏi `kShadowFrameSkip` là đề nghị khảo sát, chưa là quyết định bật N=2/3. Tra `Src/Engine/WXCore/CYS/Shadow/CYSShadowSystem.cpp` và [CY perf](C:/TLBB/085/CY-Source/Docs/specs/render/perf-cy_vi.md).

- Mặt trời tĩnh không làm shadow tĩnh: camera đổi frustum/projection, animation/caster đổi và scene load thêm vật thể. Giữ shadow texture cũ với matrix mới có thể sai vị trí; giữ cả cặp vẫn phải xử lý vùng mới.
- Bỏ cách frame giảm số lần cập nhật trung bình nhưng có thể tạo nhịp frame nặng/nhẹ, bóng giật/chậm. Độ phân giải không giảm không có nghĩa chất lượng chuyển động giữ nguyên.
- Đo cold/warm load, thời gian tới cảnh chơi được, frame time phân vị p50/p95/p99, CPU/GPU và độ ổn định trên cùng đường chạy/camera/cấu hình. Không so chỉ FPS trung bình hoặc suy thời gian CPU shadow là GPU.
- Khảo sát preload/cache/dependency trước (`MemLoadThread`, `filedep.xml` trong bằng chứng CY), công việc UI redraw lặp, upload tài nguyên trên main thread và ngân sách dựng object theo frame. Tách số đo client khỏi cảnh báo queue overload server.
- Tách static/dynamic shadow hoặc dirty update chỉ là hướng thử có điều kiện; kiểm ảnh và animation/camera tương đương trước khi bật mặc định. Không ghi hướng nghiên cứu thành tối ưu đã triển khai.
