# CampAndStand ghi vượt heap trước GL LogOn — 13/09/2026

Nhánh tiếp từ `902ecf8`; lỗi được tìm khi điều tra GL baseline dùng stage `15523fa`. Chỉ sửa ba file combat và thêm harness riêng. Không sửa String, WIC hoặc renderer theo vị trí phát hiện muộn.

## Nguyên nhân đã xác nhận

`TemplateManager_T::InitFromDBMemory` dùng `MAXSIZE < nID`, nên cho phép ID bằng capacity truy cập ngoài mảng. `CampStandRecord_T` cũ chỉ có 12 camp (MAX_ID=11), nhưng DATA đang nạp gồm ID 0–15. Record12 ghi 52 byte từ offset632 của manager640byte: đè `m_pDB` và 44 byte ngoài object.

Debug heap phát hiện tại `Game.exe+0xcd0a3`, allocation `new CActionSetMgr` ngay sau `s_pCampDataMgr->InitFromDBMemory`. Executable stage155 xác nhận compare `0xc` rồi `ja`, nhân ID với `0x34`, cộng8 và gọi record initializer. Chứng cứ tại `Build/Logs/2026-09-13-gpt-gl-login/baseline-stack-debugheap-v2.txt`, `camp-init-call.txt`, `heap-camp-finding_vi.md`.

Các dump khác phát hiện muộn trong CEGUI String::grow hoặc WIC WriteSource. Chúng không chứng minh hai hàm ấy là writer. Dump không capture vùng heap-failure-info hay global camp pointer, nên điều tra không gán địa chỉ block khi thiếu dữ liệu. Bằng chứng writer ở đây là source + machine code của executable đang chạy + ID12 trong bảng thật.

## DATA B và contract được giữ

`Assets/Canonical/Data/ConfigFolder/CampAndStand.txt` byte exact bảng B: SHA-256 `90a735a4cc41b1cbd042c0edb130669bda9680015743264843c2099b0760271b`. DBC nhị phân có **17 INT ×16 record**, gồm ID và 16 quan hệ. Bản text trong stage155 khác dạng lưu nhưng toàn bộ ID và 256 quan hệ khớp. Chi tiết: `camp-schema-compare.txt`; B đăng ký tên bảng tại Game RVA `12603d`, `b-camp-table-registration.txt`. Chưa phục hồi ABI manager của B; capacity16 trong CY căn cứ schema B thật, không khẳng định class layout nhị phân tương đương.

- `TemplateManager.h`: sửa strict bound `MAXSIZE <= nID`, khớp đường InitFromDB và GetInstanceByID hiện có. ID âm/bằng/vượt capacity không được ghi vào array.
- `CampAndStand.h`: MAX_ID thành15, đủ ID0–15. Không bỏ các camp12–15 để né lỗi.
- `CampAndStand.cpp`: đọc đúng số cột quan hệ có sẵn; legacy12camp vẫn giữ 144 quan hệ cũ và zero bốn cột mới. Record từ bảng rộng hơn16 quan hệ bị từ chối trước khi ghi, không cắt âm thầm; xác minh database/row trước khi đọc.

Record nội bộ đổi 52→68byte, manager x64 đổi640→1104byte. Đây bộ nhớ quản lý quan hệ của Game, không phải packet hay DBC overlay DTO; cần rebuild đồng bộ các translation unit dùng header chung. Không thay đổi dữ liệu hoặc runtime server WSL trong nhánh này.

## Kiểm thử source thật

`Tests/combat/run_camp_tests.ps1` biên dịch trực tiếp `CampAndStand.cpp`, `TLBB_DBC.cpp` và harness, không mock DBC hoặc copy implementation. `Tests/combat/stdafx.h` chỉ cung cấp shared types/formatting macros cho executable độc lập, không khởi tạo Game/PCH hay GPU.

Lệnh từ CY-Source:

```powershell
Tests/combat/run_camp_tests.ps1 -OutDir Build/Logs/2026-09-13-gpt-gl-login/camp-tests-1
```

Kết quả **11/11 PASS**, compile/run0, không warning. Kiểm binary/text matrix bằng reader thật, canary manager với 16 record, đủ256 quan hệ native StandByCampID/CalcRelationType, invalidID -1/16/17/INT_MAX, legacy12camp, schema quá rộng, null/row bounds, và file loader.

Regression âm: bản copy ba source trong `Build/Logs/2026-09-13-gpt-gl-login/camp-mutant-source` chỉ trả điều kiện strict bound về lỗi cũ, giữ capacity16. Cùng harness cho **10 PASS/1 FAIL**, đúng ca ID16 ghi vượt canary; log `camp-tests-mutant/tests.log`. Không thay nguồn chính để chạy regression âm. Guard bị hỏng không gọi destructor lên pointer đã bị ghi đè, để báo writer gốc thay vì lỗi delete thứ cấp.

`result.json` giữ hash ba source và hai bảng. Lượt Game/debug heap với DLL tích hợp sau sửa chưa được xác nhận trong tài liệu này; do root tiếp tục thực hiện. Unit xanh không thay thế ảnh hợp lệ, fade/ô nhập GL và kết nối WSL thực tế.
