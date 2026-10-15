# 07 — Kiểm thử, cổng nghiệm thu và phát hành

Ngày lập: 2026-09-12. Áp dụng cho đường ray Q, chạy song song với mọi pha.

## 1. Các tầng kiểm thử

| Tầng | Kiểm gì | Công cụ | Khi nào chạy |
|---|---|---|---|
| T1 Đơn vị | Parser (mesh, skeleton, material, effect, bảng), codec gói tin (khứ hồi), `static_assert` kích thước struct | CTest trong `Src`, pytest trong `Tools` | Mỗi commit |
| T2 Dữ liệu | Bộ kiểm V01–V16 (tài liệu 05, mục 7) | `Tests\validators` | Mỗi đợt nhập, mỗi lần dựng kho chuẩn |
| T3 Đối chứng hình ảnh | Viewer của ta so với `client_GL`: model, effect, cảnh | `Tests\oracle` | Mỗi thay đổi ở Render, material hay effect |
| T4 Tích hợp | Bot headless nói giao thức skynet: đăng nhập, vào cảnh, đi, đánh, chat, đổi cảnh | `tlbb_sim` với codec sinh từ đặc tả | Mỗi thay đổi ở lớp game hoặc giao thức |
| T5 Khói (smoke) | Client chạy tới màn đăng nhập, log sạch; không cần mật khẩu | script chạy client + đọc log | Mỗi bản dựng |
| T6 Người dùng trong game | Danh sách kiểm chức năng (mục 3.5) | người dùng | Tại mỗi cổng pha |
| T7 Hiệu năng và chạy dài | FPS, thời gian nạp cảnh, bộ nhớ, chạy 60 phút | log FPS của engine mới; PresentMon (tuỳ chọn) | Tại cổng E3/G2/G3 |
| T8 Crash | Minidump + symbol, phân loại nguyên nhân | CrashReport x64, `Build\Symbols` | Mỗi lần crash |

## 2. Bộ đối chứng (oracle suite)

**Cập nhật 14/09/2026 (ci-cy, xem `Docs\specs\ci-cy_vi.md`):** từ CS1 binary chỉ chạy trên `Assets\CanonicalCY\Data` (CY 3.71), nên `cases.json` được sinh lại trên CanonicalCY (`make_cases.py --profile cy`: 46 model, 100 effect, 10 cảnh CY). Bộ GL cũ giữ ở `cases_gl.json`. **Ảnh baseline `Tests\oracle\baseline` chụp từ `client_GL` không còn áp dụng cho bộ CY**; CI không so ảnh với GL, chỉ chạy bộ dò khung hình trống.

**Cấu trúc thư mục `Tests\oracle\`:**
- `cases.yaml`: mỗi ca gồm `id`, loại (model/effect/scene/ui), tên obj/effect/scene, animation và thời điểm lấy khung, camera (vị trí, điểm nhìn, FOV), độ phân giải.
- `baseline\B\<ca>.png`: chụp từ `client_GL` (chỉ cho `cases_gl.json`).
- `ours\<ca>.png`: chụp từ engine mới.
- `report.html`: ảnh cạnh nhau, SSIM, ảnh hiệu.

**Cách chụp phía `client_GL`:**
- Model và effect: xem trong thế giới qua FakeObject (`DataPool:SetRabbitModel(id)`, `FakeObj_SetCamera`; project `tlbb-model-viewer`). Cần người dùng đã đăng nhập; không bao giờ gõ mật khẩu hộ.
- Cảnh: đứng ở điểm cố định, camera cố định (lệnh debug `cameraprint`/`camerafov`), chụp bằng `Tools\gl-skin\Chup-ManHinh-Game.ps1` (PrintWindow).
- Mọi baseline ghi kèm hash của `Render.dll` và `MaterialTemplates.zip` lúc chụp.

**Phía ta:** TLBB Viewer dùng đúng tham số camera của ca, không cần server.

**Ngưỡng đạt:**
- Model và effect: SSIM ≥ 0,95 trên vùng có model.
- Cảnh: SSIM ≥ 0,90, cộng một lượt người duyệt.
- Log: không có dòng "unknown", "not found" hay "error" mới.

`Tools\gl-skin\scene3d\preview_scene.py` chỉ dùng để kiểm bố cục cảnh, không coi là chân lý từng pixel.

**Bộ khởi đầu** (chốt ở E0):
- 50 model: người chơi nam và nữ với 4 loại vũ khí, 10 pet 2026 CY/HJ, 6 tọa kỵ 2026, 10 thời trang, 10 huyễn sức, quái và boss 2026.
- 100 effect: nhóm effect dùng các kiểu NewRibbonTrail, UIParticle, RevoluMove, SequenceFrame, Dissolve, RotationCurve, PolarMove, CameraShake, ComplexBlur (danh sách lấy từ `fxkeys.json`).
- 10 cảnh.

## 3. Cổng nghiệm thu

Mỗi cổng phải có hồ sơ bằng chứng trong `Build\Logs\<ngày>-<cổng>\`: log, ảnh, báo cáo validator, kết quả test.

### 3.1 Đường ray E

| Cổng | Điều kiện đo được |
|---|---|
| E0 | `vswhere` thấy MSVC v143 x86/x64; commit "nguyên trạng" có manifest hash; CodeGraph trả callers/callees của `CGameProcedure` |
| E1a | Client x86 tự dựng vào thế giới 0.85; 30 phút đi lại và đánh quái không crash; log không có lỗi mới so với `Reference\…\Build\Client\Bin` |
| E1b (M1) | Như E1a nhưng với bản x64 dựng bằng CMake; 0 cảnh báo C4311/C4312/C4302 trong mã game; mọi `static_assert` kích thước qua |
| E2 (M2) | Bộ đối chứng model và effect đạt ngưỡng; 0 dòng "unknown element/affector/template" |
| E3 (M3) | Bộ đối chứng cảnh đạt ngưỡng; FXAA, HDR và bóng bật từ cfg; 60 fps ở 1440p tại Tô Châu (RTX 2060) |

### 3.2 Đường ray G

| Cổng | Điều kiện |
|---|---|
| G1 | 100 % gói trong đặc tả có codec C++ và Python; khứ hồi đúng từng byte trên bộ gói bắt được |
| G2 (M4) | Trên server skynet: đăng nhập, vào thế giới, đi 10 phút, đánh quái, nhặt đồ, chat; không crash; bộ đếm hàm Lua thiếu (mục 3.4) = 0 với các cửa sổ lõi |
| G3 (M5) | Danh sách kiểm chức năng (mục 3.5) đạt 100 % mục bắt buộc; người dùng chơi 7 ngày không gặp lỗi chặn |

### 3.3 Đường ray D

| Cổng | Điều kiện |
|---|---|
| D0 | Có manifest cho 7 nguồn; báo cáo khớp DataCY ↔ CY Game |
| D1 | Chạy lại một đợt nhập cũ bằng pipeline, kết quả trùng `client_GL` (chỉ khác ID); validators 0 lỗi chặn |
| D2 (mỗi đợt) | Validators 0 lỗi chặn; cài xong; người dùng xác nhận trong game |

### 3.4 Bộ đếm "hàm Lua không tồn tại"

Engine mới phải ghi **mỗi lần** script gọi một hàm host chưa hiện thực: tên hàm, file script, dòng, cửa sổ. Trùng lặp chỉ ghi một lần mỗi phiên. Con số này là thước đo tiến độ chính của G2/G3:
- Tổng hàm cần: 2.698.
- Đã có ở mã 0.85: 513.
- Danh sách đầy đủ các hàm còn thiếu, xếp theo số lượt gọi trong script: `Docs\evidence\lua_api_gap_methods.tsv`. Số tổng hợp nằm ở `lua_api_gap.json`.

### 3.5 Danh sách kiểm chức năng cho M5

Mục có dấu ★ là bắt buộc.

1. ★ Chọn server, đăng nhập, tạo nhân vật (tên tiếng Việt có dấu), xoá nhân vật
2. ★ Vào thế giới, di chuyển bằng chuột và phím, đổi cảnh, dịch chuyển qua NPC/GM
3. ★ Hội thoại NPC, nhận và trả nhiệm vụ, script sự kiện
4. ★ Chiến đấu: kỹ năng các phái gốc và 4 phái CY, đạn và effect, buff, chết và hồi sinh
5. ★ Trân thú: xuất chiến, kỹ năng, hợp thể; tọa kỵ: cưỡi và xuống. Lỗi "cưỡi thú + PK thất bại im lặng" hiện đang mở ở client cũ
6. ★ Túi, kho, trang bị, ngoại trang, thời trang, huyễn sức, trang sức, danh hiệu
7. ★ Shop NPC, shop nguyên bảo (các tab 2026), giao dịch
8. ★ Chat tiếng Việt: các kênh, dán chữ (Ctrl+V hiện mất dấu ở client cũ)
9. Tổ đội, bang hội, bạn bè, thư
10. GM Tool (GmTool.lua / 900066)
11. ★ Cài đặt đồ hoạ: FXAA, HDR, bóng, độ phân giải, giữ nguyên qua các lần đổi cảnh
12. ★ Hiệu năng: không giật khi đổi cảnh lần hai; FPS ≥ client_GL tại cùng điểm

## 4. Quy tắc chạy client khi thử nghiệm

- **Không** mở client (bất kỳ bản nào) khi người dùng đang chơi, vì cùng tài khoản sẽ bị đá.
- **Không** gõ mật khẩu. Token tự đăng nhập chết sau mỗi lần restart server; muốn vào lại thì người dùng tự đăng nhập.
- Game.exe của `client_GL` xoá log Fairy cũ khi khởi động, nên phải chép log cần giữ trước. Engine mới thì xoay vòng log.
- Engine mới cần có chế độ "không tự đăng nhập", để thử tới màn đăng nhập mà không đụng tới token.
- Chạy thử xong thì tắt tiến trình ngay (`Stop-Process -Name Game`), rồi báo lại người dùng.

## 5. Ngân sách hiệu năng (mục tiêu, đo lại ở E3)

| Chỉ số | Mục tiêu | Hiện trạng `client_GL` |
|---|---|---|
| FPS ở 2560×1440, Tô Châu, RTX 2060 | ≥ 60 | cần đo baseline ở E0 |
| Thời gian nạp cảnh | ≤ 10 giây, không giật lần hai | 6–12 giây, cộng một lần giật do hook (đã sửa ngày 11/09) |
| Bộ nhớ tiến trình | ≤ 4 GB ở cảnh đông người | cần đo |
| Số model trong AOI | có giới hạn và LOD | AOI bán kính 20 không giới hạn; vài trăm model gần nhau là crash |

## 6. Phát hành

- **Số hiệu:** `CY-Source <lớn>.<nhỏ>.<bản dựng>` + hash commit, ghi trong version resource của mọi DLL/EXE.
- **Gói phát hành:**
  - `Bin64` gồm các binary dựng từ `Src` và runtime của hãng (VC++, D3DX9_43, FMOD, cg).
  - `Data` là kho chuẩn đã đóng AXP, hoặc thư mục rời.
  - `Patch\LoginServer.txt` dạng UTF-8 do engine mới đọc.
  - Ghi chú phát hành: thay đổi, kết quả validator, lỗi đã biết.
- **Hoàn tác:** giữ nguyên thư mục của bản trước; manifest dữ liệu; script hoàn tác phía server của từng đợt.
- **Phạm vi:** chỉ dùng trên máy này, là dự án cá nhân. Không tải binary, mã hay dữ liệu lên dịch vụ ngoài khi người dùng chưa yêu cầu rõ (`CLAUDE.md`).

## 7. Lưu hồ sơ

| Loại | Nơi lưu |
|---|---|
| Log, ảnh, báo cáo theo cổng hoặc đợt | `Build\Logs\<ngày>-<cổng/đợt>\` |
| Đặc tả dịch ngược | `Docs\specs\<module>\<tính-năng>.md` |
| Đợt nhập dữ liệu | `Registry\batches\<đợt>.yaml` |
| Lựa chọn bản | `Registry\selections\<đợt>.yaml` |
| Đặc tả giao thức | `Registry\protocol\packets.yaml` |
| Kích thước struct | `Registry\abi\struct_sizes_x86.json` |
| Bằng chứng khảo sát 12/09 | `Docs\evidence\` |
