# Chữ Trung vẽ trong ảnh GUI CY → tiếng Việt (lớp `cy-gui-image-vi`)

Ngày 15/09/2026, agent ui-image-vi. Bằng chứng: `Build/Logs/2026-09-15-ui-image-vi/`.

## Vấn đề

Pipeline canonical đã Việt hoá chữ CEGUI: layout, literal Lua, StrDictionary, bảng item. Trên HUD, màn đăng nhập
và màn chọn nhân vật vẫn còn chữ Trung. Phần chữ này **vẽ sẵn trong texture của imageset**, ví dụ tab `已接/可接`,
tiêu đề `任务追踪`, nút `自动寻路`, `安全`, `充值/兑换`, tab `选择后缀登录`, nút `进入游戏`, `创建角色`,
nút tròn `榜 线 社 战`, ô kênh chat `近 世 密…`. Layout chỉ gọi `set:<Imageset> image:<Image>`, không có thuộc tính Text.

## Quyết định: vẽ lại chữ trong texture, không thay bằng text CEGUI

- **Dữ kiện.** Mỗi nút CY có 3–4 ảnh trạng thái (Normal/Hover/Pushed/Disabled), còn Lua đổi ảnh theo trạng thái
  (ví dụ `MiniMap.lua` đặt `WarningAnimation`). Kiểu `TLBB_ButtonNULL`/`TLBB_StaticImageNULL` không vẽ Text.
- **Suy luận.** Muốn đặt text CEGUI thì phải sửa layout, looknfeel và Lua. Chữ phẳng như vậy cũng mất màu chuyển,
  viền và bóng mà CY vẽ riêng cho từng trạng thái. Vẽ lại trong texture giữ nguyên hành vi và giao diện CY.
- Không đổi tên file, tên imageset, tên ảnh hay toạ độ. Không nới khung.

## Cách làm (`Tools/pipeline/cy_gui_image_vi.py`)


   Không gọi API.
2. **Nguồn ảnh.** Lấy byte CY 3.71 từ `Interface.axp` (S4), chỉ đọc; loại vỏ 1–18 lấy từ S2, giống
   build_canonical_cy. Chế độ độc lập đọc InterfaceFolder trên đĩa.
3. **Tìm chữ (nhãn chữ nhật).** Dùng white top‑hat trên độ sáng, hoặc trên kênh `chan=r` với chữ đỏ, rồi lấy
   ngưỡng Otsu. Bỏ thành phần chạm mép và thành phần là khung (rộng hoặc cao hơn 85% ảnh). Chọn băng dòng quanh
   đỉnh profile, không tính các nét kẻ mảnh. Có thể chỉ định `box=` cho nút có hoa văn.
4. **Xoá chữ.** Nới mask 2 px để lấy cả viền và glow. Nền điền bằng trung bình của hai cách: nội suy theo hàng
   (giữ dải màu dọc của nút) và `cv2.inpaint` Telea. Alpha được xử lý cùng cách.
5. **Nút tròn (`icon=round`).**
   - Dựng lại nền đĩa bằng trung vị của từng ô vòng × cung (12 cung). Mỗi ô lấy phần tối 30%, vì chữ sáng hơn nền.
   - Bán kính lõi là vòng tách viền, tức vòng lệch nhiều nhất so với mặt đĩa ở nửa ngoài.
   - Mask chữ gồm các texel lệch xa nền nằm trong lõi.
   - Chữ mới, kể cả dấu và bóng, phải nằm trọn trong vòng tròn *lõi − 2 px*. Kiểm bằng texel thật đã render.
   - Thứ tự thử: từ đầy đủ ở cỡ ≥9 px, từ đầy đủ ở cỡ ≥8 px, rồi từng nhãn ngắn `alt=` ở cỡ ≥9 px, cuối cùng xuống
     cỡ tối thiểu 7 px. Cỡ không lớn hơn khoảng 1,5 × lõi.
   - Mọi trạng thái trong họ dùng chung lõi, cỡ, nhãn và bóng.
6. **Vẽ chữ.**
   - Font Noto Sans SC Regular, là font người dùng chọn (`fonts_vi.md`); không thêm font khác.
   - Màu lấy từ 35% texel sáng nhất của chữ cũ, chia nửa trên và nửa dưới để giữ dải màu. Viền lấy màu vòng quanh
     chữ cũ.
   - Chữ từ 12 px trở lên có viền 1 px; chữ nhỏ hơn dùng bóng lệch 1 px, vì viền đầy làm bít lỗ chữ.
   - Từ 11 px trở lên dùng đậm giả 1 texel.
   - Cỡ chữ: chiều cao chữ hoa bằng 0,8 × chiều cao chữ Trung cũ. Dấu tiếng Việt được dùng lề trên và dưới trong
     phạm vi ảnh. Có thể nén ngang tới 0,78.
   - Mọi trạng thái của một nút dùng cùng một cỡ.
7. **Kiểm tự động (QA), ghi vào cột `qa` của manifest.**
   - `bounds_px = 0`: không texel chữ mới nào nằm ngoài vùng xoá ∪ vùng chữ khai báo (với nút tròn là vòng lõi trừ lề).
   - `residual ≤ 0,08`: tỉ lệ nét chữ Trung còn nổi trên nền đã xoá. Nhãn chữ nhật đo bằng top‑hat; nút tròn đo độ
     lệch khỏi nền dựng lại, ngoài mask, bên trong lõi.
   - `contrast ≥ 2,0`: tỉ lệ WCAG giữa màu chữ và nền dưới chữ; trạng thái disabled chỉ cần ≥ 1,3, như CY.
   - Nút tròn phải `fits`.
   - Ảnh không đạt được ghi vào `gui_image_vi_problems.tsv`, và build báo trong `gui_unresolved`.
8. **Ghi ra.** Texture giữ tên và loại: DDS thành A8R8G8B8 không nén (không có mip, như texture GUI CY), TGA 32 bit,
   PNG, hoặc JPG q95. Nếu texel ngoài các hình chữ nhật đã vẽ bị đổi, công cụ ném lỗi. Hình chữ nhật chồng nhau,
   như `TServerUI2` Bang_Xuanzhan_*, chỉ ghi texel thật sự thay đổi.

## Tích hợp pipeline

- `build_canonical_cy.py` gọi `GIV.generate` trong `cy_gui_generate`. File sinh ra nằm ở
  `_generated/gui-cy/InterfaceFolder/<texture>`, thuộc layer `cy-gui-image-vi` và thay entry S4 cùng đường dẫn.
  Manifest ghi ở `_manifest/gui_image_vi.tsv` với các cột nguồn, sha256 nguồn/đích, thông số vẽ và QA.
- `--out DIR` ghi Data, `_manifest` và `_generated` vào DIR, để worktree chạy `--plan` mà không chạm
  `Assets/CanonicalCY`. Người điều phối chạy `--apply` trên cây chính sau khi gộp.
- Stage thử (khi chưa apply): `Build/Logs/2026-09-15-ui-image-vi/scripts/overlay_stage.py PLAN_OUT STAGE` chép các
  texture vào `Overlay/Pre` và `Overlay/Post/InterfaceFolder` (dạng "winner" của stage_game), kèm `Bin64/uivi_overlay.json`.

## Kết quả đợt 1

- 160 dòng registry, 392 ảnh trong 33 texture; QA 392/392 đạt.
- Chi tiết theo màn: `inventory.tsv`. Sheet duyệt: `review-2x-85072d5/` (trước | sau, zoom 2×).
- Nhãn ngắn trên nút tròn nhỏ (có ghi chú trong registry):
  - `线` → `T` (Tuyến); `榜` → `BXH`; `战` → `Đ` (tự đánh)
  - `新` → `T` (Tân thủ); `捷` → `T` (Tiệp); `限` → `H` (Hạn); `分` → `P` (Phân)
  - Bản 22 px: `询` → `H`, `调` → `Đ`
  - Đĩa mục tiêu: `T`, `Y`, `S`, `K`, `N`

## Chưa làm, kèm lý do

Chi tiết trong `inventory.tsv`.

- Logo `新天龍八部`: thương hiệu thư pháp.
- `首充奖励`, `新手欢乐月`, `新手嘉年华`: chữ thư pháp lẫn trong tranh; các nút sự kiện này không hiện trong phiên thật.
- Huy hiệu đánh giá ngoại hình `Pretty01`: chữ là một phần tranh vẽ.
- Thơ giới thiệu phái ở màn tạo nhân vật: cần dịch thơ hai dòng.
- Chữ trên ảnh bản đồ nhỏ của cảnh (`驿`…): texture bản đồ từng cảnh, không thuộc imageset GUI.
- Ô bậc danh hiệu `SectTitle` (零…二十 → 0…20): số đọc rõ, nhưng phần giữa hình thoi bị làm phẳng khi xoá chữ cao.
  Nên dựng lại nền hình thoi theo đối xứng.

## Chạy lại

```powershell
$py = 'C:\Program Files\Python313\python.exe'; $env:PYTHONUTF8 = 1
& $py -B Tools\pipeline\cy_gui_image_vi.py --ui <CanonicalCY>\Data\InterfaceFolder --out <dir> --preview   # nhanh, có sheet
& $py -B Tools\pipeline\build_canonical_cy.py --plan --out <dir>                                       # đường pipeline
& $py -B Tools\pipeline\test_cy_gui_image_vi.py
& $py -B Tools\pipeline\cy_gui_image_scan.py --ui <InterfaceFolder> --out <dir> LAYOUT...               # kiểm kê ảnh
```
