# 372 dragon — Thiên Long Bát Bộ 64-bit dựng từ mã nguồn

Dự án dựng một client TLBB x64 từ mã nguồn 0.85 (trong `Reference`), nâng lên ngang dòng engine Fairy hiện đại của `client_GL` và CY 3.71, rồi dùng một kho dữ liệu hợp nhất từ CY, HJ, GL và 085. Client nói giao thức của server skynet đang chạy trong WSL `TLBB`.

**Bắt đầu từ `Docs\00-DOC-TRUOC_vi.md`.**

**Cấu trúc và kiểm toán bản đang chạy (24/09/2026):**
[Cấu trúc dự án, nguồn gốc EXE/DLL và hook/inject](Docs/10-CAU-TRUC-VA-KIEM-TOAN-BUILD_vi.md).
Client chính có source/build; FMOD, Cg và runtime DirectX là các phụ thuộc nhị phân có sẵn.

| Thư mục | Vai trò | Git |
|---|---|---|
| `Docs\` | Tài liệu quy trình 00–09 và bằng chứng khảo sát (`evidence\`) | có |
| `Reference\` | Mã nguồn 0.85 và bản dựng sẵn. **Chỉ đọc** | không |
| `Src\` | Mã nguồn làm việc (nhập ở pha E0) | có |
| `Tools\` | Công cụ riêng của dự án: build, pipeline dữ liệu và giao thức | có |
| `Assets\` | Nguồn (mô tả + manifest), Staging, kho chuẩn | không (trừ `sources.yaml`) |
| `Registry\` | Sổ ID, lựa chọn bản, đợt nhập, đặc tả giao thức, ABI | có |
| `Tests\` | Validators, bộ đối chứng hình ảnh, bot, kiểm ABI | có |
| `Build\` | Đầu ra dựng, gói AXP, log theo cổng | không |

Các tài liệu quy trình ngày 12/09/2026 ghi lại trạng thái khởi tạo. Mã nguồn và toolchain hiện đã có;
bản Play được kiểm toán ngày 24/09 nằm tại `Build/world-gui/stage-play-21`. Xem tài liệu kiểm toán
ở trên để phân biệt source, đầu ra build, dữ liệu game và DLL SDK.
