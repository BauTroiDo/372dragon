# 00 — ĐỌC TRƯỚC: dự án CY-Source (TLBB 64-bit dựng từ mã nguồn)

Ngày lập: 2026-09-12. Trạng thái: **bản quy trình v1**. Các quyết định ghi "Đề xuất" và các câu hỏi Q1–Q5 đang chờ người dùng duyệt.

**Cập nhật đường dẫn đọc ngày 24/09/2026:** trạng thái khởi tạo ở tài liệu này là lịch sử.
Để xem cấu trúc hiện tại, bản Play, nguồn gốc EXE/DLL và cơ chế hook/inject đã kiểm tra, đọc
[10 — Cấu trúc và kiểm toán build](10-CAU-TRUC-VA-KIEM-TOAN-BUILD_vi.md).

**Tổng hợp 25/09/2026:** xem [11 — Hội thoại, quyết định, phần còn mở và skill](11-TONG-HOP-HOI-THOAI-VA-SKILLS_vi.md). Tài liệu này đối chiếu cả nhật ký trước các mốc nén và các báo cáo sửa lỗi; tránh lấy trạng thái khảo sát cũ làm trạng thái hiện tại.

**Đợt sửa 26/09/2026:** [EXP, bay, Phòng thay đồ, GM/Trân thú, lễ hộp và dọn build](specs/client/runtime-polish-20260926_vi.md) ghi nguyên nhân, thay đổi, bằng chứng và giới hạn còn lại; trạng thái phát hành tra release-report được dẫn trong tài liệu.

**Đợt sửa 28/09/2026:** [Cài đặt, Bạn bè và Danh hiệu](specs/settings-friends-titles-20260928_vi.md) ghi các thao tác đã nối vào gameplay/máy chủ, kiểm tra lưu qua đăng nhập lại và những tùy chọn còn chưa được hỗ trợ.

**HJ05, tiếp nối 28/09/2026:** [Tiệm trân thú, khóa/tẩy Thú hồn và 143 mục theo dõi](specs/hj05-remaining-20260928_vi.md) ghi bản Play, kết quả GUI/lưu–nạp, phục hồi dữ liệu thử và phần còn mở. Không dùng trạng thái thiếu tính năng trong audit đầu ngày làm trạng thái hiện tại.

**Tiếp nối 29/09/2026:** [Tàng Kinh Các và vòng đời UI](specs/cangjingge-20260929_vi.md) ghi 36 monster đã đối chiếu GL/CY, sửa NPC/phụ bản, lỗi Lua khi thoát và kiểm lại icon/cuộn/Esc/di chuyển. Có phân biệt kiểm callback, scene thật và phần chưa nghiệm thu bằng đội người chơi.

> ## QUY TẮC 0 — HỌC TRƯỚC, SỬA SAU
>
> **Trước khi sửa hay thêm bất cứ thứ gì: nếu đã có phiên bản SỐNG làm được việc đó, đi đọc nó
> trước. Rồi phản biện. Chỉ áp dụng khi thật sự hợp.**
>
> Ba bước, không được đảo: **HỌC** (đọc cách phiên bản sống làm) → **PHẢN BIỆN** (nó ngầm giả định
> gì, giả định đó ở cây ta còn đúng không) → **ÁP DỤNG CÓ ĐIỀU KIỆN** (không hợp thì **ghi rõ vì
> sao** rồi mới chọn đường khác).
>
> Phiên bản sống: `client` · `client_GL` · `Tools\DATA NEW\CY Game` — cả ba **CHỈ ĐỌC**.
>
> Toàn văn kèm ca đã chứng minh: `08-BAY-VA-QUY-TAC_vi.md` mục **QUY TẮC 0**.

## 1. Dự án là gì

**Mục tiêu:** dựng một bản Thiên Long Bát Bộ **64-bit từ mã nguồn**, tổng hợp tinh hoa của CY, GL, HJ và mọi phiên bản, dùng tối đa những gì đã có (DataCY, CYHJ, CY Game 3.71, client GL, `client_GL`), đặc biệt chú trọng **model, effect, particle và texture**.

**Phạm vi:** toàn bộ dự án nằm trong `C:\TLBB\085\CY-Source`. Server sản phẩm vẫn là server skynet trong WSL `TLBB`. Đây là dự án cá nhân, chạy cục bộ, phi thương mại (`C:\TLBB\085\CLAUDE.md`).

## 2. Kết luận khảo sát ngày 12/09

1. **Mã nguồn "cổ" 0.85 là tổ tiên của client hiện đại, và đã đọc đúng mọi định dạng file** của dữ liệu CY/HJ 2026 (mesh v1.40, skeleton 0x4120, DXT). Nó thiếu tính năng, không thiếu định dạng.
2. **`client_GL` (bản đang chơi) và CY 3.71 là cùng một dòng engine Fairy hiện đại**, và **server skynet nói giao thức của `client_GL`, không phải của 0.85**. Dựng mã 0.85 lên sẽ không kết nối được server hiện tại.
3. **Khoảng trống phải lấp**, tất cả đều đã đo được:

   | Mảng | Thiếu so với client hiện đại |
   |---|---|
   | Render | 29 post-filter, bóng CSM, 114 template SM3/PBR, 9 kiểu effect, dynbone, height fog, HDR… |
   | Giao thức | Khoảng 200 gói mới; đánh số và bố cục trường khác |
   | API Lua | 2.185 trên 2.698 hàm mà UI hiện tại gọi |
   | Hệ thống game | Ngoại trang, tọa kỵ, võ hồn, điêu văn, raid, đấu giá… |

4. **Không có đường tắt kiểu "dựng 0.85 là chơi được", nhưng cũng không cần viết engine mới.** Đường đúng gồm bốn điểm:
   - tiến hoá mã 0.85 lên ngang `client_GL`;
   - lấy `client_GL` và CY 3.71 làm **đặc tả** và **đối chứng**;
   - nói giao thức skynet;
   - đọc **một kho dữ liệu chuẩn** hợp nhất.
5. **Kho dữ liệu chuẩn làm được ngay**, và phục vụ `client_GL` từ tuần đầu, không phải chờ engine.

Toàn bộ số liệu và bằng chứng: `01-HIEN-TRANG-VA-NGUON-LUC_vi.md` và thư mục `evidence\`.

## 3. Chiến lược: năm đường ray song song

| Ký hiệu | Đường ray | Kết quả đầu tiên người dùng thấy |
|---|---|---|
| **D** | Dữ liệu và tài sản (CY/HJ/GL → kho chuẩn, sổ ID, bộ kiểm) | Đợt nhập đầu tiên đi qua pipeline, cài vào `client_GL` (4–8 tuần) |
| **E** | Engine từ mã nguồn (x64, rồi đủ tính năng Fairy) | M1: Game.exe x64 dựng từ mã đi lại trong thế giới 0.85 (2–3 tháng)<br>M2: model/effect/particle/texture 2026 hiển thị như `client_GL` (4–6 tháng) |
| **G** | Lớp game và giao thức skynet | M4: vào được server skynet với UI của `client_GL` (8–12 tháng) |
| **S** | Server hỗ trợ (đặc tả giao thức, kiểm cặp bảng) | Đặc tả máy đọc được (2–4 tuần) |
| **Q** | Kiểm thử và phát hành | Bộ đối chứng hình ảnh, validator, cổng nghiệm thu |

Mốc cuối **M5**: client mới thay `client_GL`, ước lượng 15–24 tháng cho một người chính có AI hỗ trợ. Sau M5 là pha "vượt ngang": D3D11, PBR đầy đủ, hạt GPU… Chi tiết ở `03-LO-TRINH-TONG_vi.md`.

## 4. Bản đồ tài liệu

| Tài liệu | Đọc khi |
|---|---|
| `00-DOC-TRUOC_vi.md` | Luôn đọc đầu tiên |
| `01-HIEN-TRANG-VA-NGUON-LUC_vi.md` | Cần số liệu: mã nguồn, ba dòng binary, server, tài sản, máy |
| `02-KIEN-TRUC-VA-QUYET-DINH_vi.md` | Cần hiểu kiến trúc đích, các quyết định D1–D15, câu hỏi mở Q1–Q5 |
| `03-LO-TRINH-TONG_vi.md` | Lập kế hoạch: pha, cổng, ước lượng, rủi ro |
| `04-QUY-TRINH-MA-NGUON-X64_vi.md` | Cài toolchain, nhập mã, hệ build và port x64 |
| `05-QUY-TRINH-TAI-SAN_vi.md` | Nhập hay gộp model, effect, particle, texture, map, UI, bảng, âm thanh |
| `06-GIAO-THUC-VA-SERVER_vi.md` | Gói tin, codec, đồng bộ bảng client–server, reload/restart |
| `07-KIEM-THU-VA-PHAT-HANH_vi.md` | Kiểm thử, bộ đối chứng, cổng nghiệm thu, phát hành |
| `08-BAY-VA-QUY-TAC_vi.md` | **Bắt buộc đọc trước khi động vào dữ liệu hay mã**: mọi bẫy đã gặp |
| `09-DANH-MUC-CONG-CU_vi.md` | Công cụ có sẵn, công cụ phải viết mới |
| `evidence\` | Bằng chứng khảo sát ngày 12/09 (script và kết quả đo) |

## 5. Mười hai quy tắc vàng

1. `Reference`, `C:\TLBB\085\client` và `Tools\DATA NEW` **chỉ đọc**. Chỉ ghi trong `CY-Source`, và trong `client_GL` khi cài nội dung cho bản chơi hiện tại.
2. UTF-8 là vĩnh viễn. Các file `all.*` và tên nội bộ trong model là GBK, phải sửa ở mức byte.
3. **Không so theo ID giữa các nhánh.** Mọi ID mới đều qua Registry và phải còn trống ở cả client lẫn server.
4. Bảng server phải GBK. Bảng client giữ đúng dạng như `client_GL` và sắp ID tăng dần.
5. Server skynet là chủ giao thức. Đặc tả giao thức được sinh tự động từ server.
6. Mã nguồn lưu UTF-8 và biên dịch với `/execution-charset:.936`.
7. Mọi bước ghi dữ liệu có đủ check/apply/verify/revert và bản sao lưu. Không xoá, chỉ cách ly.
8. Mỗi pha chỉ qua khi đạt **cổng đo được**, kèm hồ sơ bằng chứng trong `Build\Logs`.
9. Không mở client khi người dùng đang chơi. Không gõ mật khẩu. Không ghi mật khẩu vào tài liệu hay log.
10. Không restart server khi chưa báo trước. Restart đúng bằng `start_zone.sh`, và chờ tới 900 giây trước khi kết luận.
11. Không tải mã, binary hay dữ liệu dự án lên dịch vụ bên ngoài nếu người dùng chưa yêu cầu rõ.
12. Đọc `08-BAY-VA-QUY-TAC_vi.md` trước khi làm.

## 6. Việc cần người dùng quyết

| # | Câu hỏi | Mặc định nếu không trả lời |
|---|---|---|
| Q1 | Bạn có cây mã `Temp_Release_v0-85-9602\Prj\GameCode` (bản đã port x64, có D3D11, PathLib, FMOD 2.2) không? | Làm E1 đầy đủ từ mã 0.85 |
| Q2 | Xác nhận mục tiêu cuối là chơi trên server skynet hiện tại | Theo D1 (skynet là chủ giao thức) |
| Q3 | Dùng FMOD Core (giấy phép phi thương mại) hay thư viện mở (miniaudio / OpenAL Soft, bỏ `.fsb`)? | FMOD Core |
| Q4 | Cho khởi tạo git cục bộ trong `CY-Source`? (`.gitignore` đã có sẵn) | Chờ đồng ý |
| Q5 | Cho cài VS2022 Build Tools, CMake và Ninja bằng winget? | Chờ đồng ý |

**Đã trả lời ngày 12/09:** Q1 là không; Q2–Q5 cho phép tất cả; ưu tiên số một là **ĐẸP**. Chi tiết và hệ quả ở tài liệu 02, mục 6.

## 7. Việc làm ngay khi được duyệt (2 tuần đầu)

- **E0:**
  - Cài toolchain (Q5).
  - `git init` (Q4).
  - Viết `Tools\pipeline\import_source.py`, nhập mã nguyên trạng vào `Src` kèm manifest.
  - Thêm `Src` vào CodeGraph.
- **D0:**
  - Viết `Assets\Sources\sources.yaml`.
  - Bổ sung SHA-256 cho manifest ngày 12/09.
  - Lập chỉ mục model theo tên obj/mesh cho S1–S4.
  - Đối chiếu độ dài file giữa DataCY và CY Game.
- **S1:** ghi lại cú pháp DSL của các file codec Lua trên server; viết `Tools\protocol\specgen.py` bản đầu.
- **Q:**
  - Chốt danh sách bộ đối chứng (50 model, 100 effect, 10 cảnh).
  - Chụp baseline của `client_GL`. Việc này cần người dùng đăng nhập và báo lúc không chơi.

## 8. Cấu trúc thư mục

```text
CY-Source\
├─ README_vi.md            điểm vào
├─ .gitignore              loại Reference, Assets, Build, SDK
├─ Docs\                   tài liệu quy trình (00–09) + evidence\
├─ Reference\              mã nguồn 0.85 + bản dựng sẵn (CHỈ ĐỌC)
├─ Src\                    mã làm việc: Client\ Engine\ Shared\ ThirdParty\ (git)
├─ Tools\                  pipeline\ protocol\ re\ (git)
├─ Assets\                 Sources\ (mô tả + manifest), Staging\, Canonical\ (không git)
├─ Registry\               sổ ID, lựa chọn, đợt nhập, đặc tả giao thức, ABI (git)
├─ Tests\                  validators\ oracle\ bot\ abi\ (git)
└─ Build\                  Client\ Server\ Packs\ Logs\ (không git)
```
