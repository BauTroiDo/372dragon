# Răng cưa và lọc texture theo CY 3.71

Tài liệu do agent aa-cy viết ngày 15/09/2026, trên nhánh `aa-cy`. Commit sửa là `05d946c`.

Quy ước ký hiệu:
- **FACT**: có bằng chứng đi kèm (hàm, offset, bộ nhớ tiến trình, ảnh hoặc số đo).
- **INF**: suy luận, chưa kiểm chứng trực tiếp.

Nơi để bằng chứng:
- Ảnh và số đo: `Build\Logs\2026-09-15-aa-cy\`. Thư mục con: `cy\` là ảnh CY thật kèm log đọc bộ nhớ, `viewer\` là ảnh TlbbViewer, `replay-run-*` là Game.exe, `metrics\` là số đo và ảnh cắt 4×, `perf\` là GPU.
- Kết quả RE: `Build\re\aa-cy\out\`.

Chuẩn so sánh là CY 3.71.9609, chạy trên bản sao `Build\re\color-calib\CYGame` ở chế độ offline, không có kết nối mạng. SHA-256 của các file CY:

| File | SHA-256 |
|---|---|
| `Game.exe` | `9278c7f3…` |
| `Render.dll` | `e6e67de4…` |
| `RenderSystem_Direct3D9.dll` | `80169f31…` |
| `OgreMain.dll` | `a226c865…` |

## 0. Tóm tắt

Người dùng phàn nàn: "Texture trong game vẫn còn răng cưa ? trong khi CY cũng với data đó mà nó không có răng cưa".

**CY lúc chạy (FACT):**
- Không có MSAA.
- Không có FXAA. `View_Fanhunjiao=0`, và đây là giá trị có sẵn trong cfg của CY.
- Lọc texture ở mặc định của OGRE: bilinear, mip point, anisotropy 1. CY chỉ áp `View_TextureFiltering` khi biến này thay đổi, tức là khi người chơi bấm trong hộp thiết lập.
- Khung đăng nhập của CY cho số đo khớp với TlbbViewer chạy bilinear không AA. Tỉ lệ cạnh gắt `hard` là 0,94 % ở CY so với 0,67 % ở viewer. Năng lượng tần số cao `lap` là 12,1 so với 11,8.

**Game.exe của dự án trước khi sửa (FACT):** trạng thái giống hệt CY.
- Bilinear, anisotropy 1 (đọc từ bộ nhớ tiến trình).
- FXAA **chưa từng bật trong game**. Template `WXSystem.cfg` của stage ghi `View_Fanhunjiao=0`; log ngày 14/09, trước color-calib, cũng ghi `View_Fanhunjiao=0` và không có chữ "(default)".
- Vì vậy bản sửa màu **không** tắt FXAA trong game. Nó chỉ tắt NewHDRBloom, và NewHDRBloom vốn làm mềm cạnh (INF).

**Sửa (`// CYS-AA:`, `Src\Engine\WXCore\CYS\PostFX\CysPostFx.cpp`):**
- Áp `View_TextureFiltering` ngay lúc khởi động, theo đúng hàm của CY. Giá trị 2 cho anisotropic ×8.
- Thêm khoá `PostFX.AAMode`, mặc định `fxaa`. Khi cfg để `View_Fanhunjiao` bằng 0, khoá này bật **bộ lọc FXAA của chính CY**: shader `AntiAlias.hlsl FXAA_PS_NOLUMA` lấy từ `MaterialTemplates.zip` của CY, cũng là tuỳ chọn "全屏抗锯齿" (khử răng cưa toàn màn hình) của CY.
- Công tắc A/B:
  - `PostFX.AAMode=cy` hoặc biến môi trường `CYS_AA=cy` cho đúng trạng thái chạy của CY: không AA, không áp lọc lúc khởi động.
  - Các giá trị khác: `none`, `fxaaquality`, `dlaa`.
  - `CYS_TEXFILTER=0|1|2|ogre` chỉ đổi phần lọc texture.
- Mặc định `fxaa` là **quyết định có chủ ý, lệch khỏi cfg mặc định của CY**. Lý do: CY không có cách khử răng cưa nào khác, còn người dùng yêu cầu hết răng cưa.

## 1. CY làm gì (FACT, Ghidra chỉ đọc + đọc bộ nhớ tiến trình CY)

| Câu hỏi | Chỗ trong CY | Kết luận |
|---|---|---|
| `View_TextureFiltering` nghĩa là gì | Hàm xử lý `View_*` trong Render.dll là `FUN_18002ec20`. Nó gọi `(*DAT_1803b4e98 + 0x2f0)(value - '0')`. Vtable nằm ở `0x1802c0d08`; slot `+0x2f0` là `FUN_18002e5c0` | 0: `setDefaultTextureFiltering(TFO_BILINEAR)` + `setDefaultAnisotropy(1)`. 1: `TFO_TRILINEAR` + 2. 2: `TFO_ANISOTROPIC` + **8**. Ngoài ra không có mip bias hay sampler state riêng nào |
| `View_Fanhunjiao` nghĩa là gì | Cũng trong `FUN_18002ec20`: `(+0x710)(value == "1")`. Slot `+0x710` là `FUN_18002cc80` | Bật/tắt bộ lọc `"FXAA"` (`DAT_1802c0474`, gọi `FUN_18009ce50`), với điều kiện renderer `+0xf0` khác 0. Không đụng tới MSAA |
| CY có MSAA không | `FUN_180024ea0` (setup) chỉ đưa vào `miscParams` hai khoá `vsync` (lấy từ `View_Aplomb`) và `colourDepth`. Log Fairy của CY: `createRenderWindow … miscParams: colourDepth=32 externalWindowHandle=… vsync=true` | Không truyền `FSAA` |
| | Trong `RenderSystem_Direct3D9.dll`: tuỳ chọn `Anti aliasing` và `RT Anti aliasing` mặc định `None` (`FUN_18001a7a0`). `createRenderWindow` là `FUN_180018680`, đọc `RTFSAA` vào `+0x43a0`. `FUN_180018350` chỉ tạo RT multisample khi `+0x43a0 != 0` | |
| | **Bộ nhớ tiến trình CY:** `OgreMain+0x424638` (Root) → `+0x18` (renderer) → `+0x4398..+0x43a4` cho ra `0 0 0 0` | FSAA, FSAAQuality, RTFSAA và RTFSAAQuality đều bằng 0 (`cy\rs-fsaa\run.log`) |
| Lọc texture khi CY đang chạy | `OgreMain+0x418a08` (MaterialManager) → `+0xB0/+0xB4/+0xB8/+0xBC`. Offset lấy từ `getDefaultTextureFiltering` tại `0x1800c1b80` và `getDefaultAnisotropy` (được gộp chung với `0x1800c1b70`) | Đọc ở giây 20, 75, 85 và 104 (màn đăng nhập) đều ra **`2 2 1 1`** = LINEAR/LINEAR/POINT, aniso 1 (`cy\tf2\run.log`) |
| Có chỗ nào áp `View_TextureFiltering` lúc khởi động không | Game.exe chỉ **đọc** biến này ở 3 nơi: log `ViewSetup Config` (`FUN_1406b64a0`), gói hiệu năng `CGClientPerformanceLogin` (`FUN_140647430`) và bảng so mức chất lượng (`FUN_1406b72c0`). Ở Lua, `ViewSetup.lua` chỉ gọi `SystemSetup:View_SetData` khi người chơi bấm Accept/Default/mức chất lượng | Không. Giá trị 2 trong cfg chỉ có tác dụng sau khi mở hộp thiết lập |
| Mipmap | `TextureManager` (`OgreMain+0x424968`) `+0xB8` = `mDefaultNumMipmaps` = **5**. `D3D9Texture::_loadNormTex` (`FUN_180025980`) gọi `D3DXCreateTextureFromFileInMemoryEx` với số mip = số yêu cầu + 1 | Giống hệt dự án: `WXSystem.cpp` gọi `setDefaultNumMipmaps(5)`, còn `OgreD3D9Texture.cpp` dùng `numMips = mNumRequestedMipmaps + 1`. DDS thiếu mip được D3DX tự sinh mip |
| Alpha-to-coverage cho cỏ/lá | Không có MSAA thì không có coverage. `MaterialTemplates.zip` và `.material` của CY không có `alpha_to_coverage` | Không có |
| Chỉ thị `filtering` trong dữ liệu CY | `.material` trong CanonicalCY có 522 dòng, phần lớn là `linear linear none` cho UI/FX. Template chỉ có 14 dòng trong `Mtl_Character.material` | Model và cảnh dùng mặc định của `MaterialManager` |

Với INF: màn world của CY không đo được vì phải đăng nhập mới vào được. Không có đường mã nào đổi lọc texture hay AA sau màn đăng nhập ngoài hộp thiết lập, nên suy ra world của CY cũng chạy bilinear, không AA.

## 2. So cùng khung với CY thật (màn đăng nhập `erengu_DL`, 1280×720)

Thước đo lấy từ `Tools\render\aa_metrics.py`, tính trên luma:

| Chỉ số | Ý nghĩa |
|---|---|
| `lap` | Trung bình \|Laplacian\|, tức năng lượng tần số cao |
| `hard` | % điểm ảnh có bước sang điểm bên cạnh lớn hơn 48 |
| `p99` | Bước lớn nhất ở phân vị 99 |

Vùng đo là hai dải bên, không có UI: `left` = 0,40–260,620 và `right` = 1060,100–1280,560. Camera của viewer lấy từ bộ nhớ CY (color-calib). Số liệu trong `metrics\login_final.tsv` và `login_all.tsv`.

| Khung | lap trái | hard trái | p99 trái | lap phải | hard phải |
|---|---|---|---|---|---|
| CY thật (2 lượt) | 12,05 / 12,38 | 0,94 / 0,95 % | 47,6 | 15,5 / 13,6 | 2,6 / 1,0 % |
| bilinear, không AA (= Game.exe trước khi sửa) | 11,82 | 0,67 % | 42,6 | 15,4 | 1,83 % |
| aniso ×8, không AA | 15,15 | 0,98 % | 47,7 | 16,7 | 1,13 % |
| **aniso ×8 + FXAA của CY (mặc định mới)** | **11,91** | **0,19 %** | **33,8** | **12,5** | **0,37 %** |
| bilinear + FXAA | 9,64 | 0,14 % | 30,7 | 11,5 | 0,34 % |
| aniso ×8 + FXAAQuality | 12,45 | 0,21 % | 33,8 | 12,5 | 0,26 % |
| aniso ×8 + DLAA | 11,59 | 0,11 % | 30,4 | 12,2 | 0,33 % |

- Khung bilinear không AA khớp CY. Dải phải của CY dao động giữa hai lượt vì có lửa mắt quỷ và hạt động.
- Anisotropic đứng một mình làm texture ở xa gắt hơn: vân ngói nổi thành sọc (`metrics\login_roof_4x`, cột tf2). Vì vậy **không** bật aniso mà thiếu AA.
- Mặc định mới giữ độ nét texture ngang CY (`lap` 11,9 so với 12,1) nhưng số cạnh gắt giảm khoảng 5 lần.
- Ảnh cắt 4× ba cột CY thật / trước / sau: `metrics\login_roof_cy_before_after_4x.png` và `login_chain_cy_before_after_4x.png`.

## 3. Đại Lý (không có CY thật, cần đăng nhập)

**TlbbViewer**, camera của game, 1280×720, `metrics\dali_final.tsv`, toàn khung:

| Khung | lap | hard | p99 |
|---|---|---|---|
| bilinear, không AA (trước) | 18,68 | 3,42 % | 72,5 |
| **mặc định mới** | 19,97 | **1,87 %** | **54,4** |

Ảnh: `metrics\dali_plant_before_after_4x.png` (mép lá chuối mềm hơn, hoa văn đá nét hơn) và `dali_stairs_before_after_4x.png`.

Ca `CYS_AA=cy` trong viewer vẫn giữ aniso 16 riêng của viewer (`--aniso`, dòng 905 của `ViewerApp.cpp`). Game.exe không có lớp này.

**Game.exe replay** `dali_new_320`, khung `world-1`, 1024×768. Khung này tất định: hai lượt trước khi sửa lệch nhau 0,05 luma. Số liệu trong `metrics\game_world1.tsv`:

| Vùng | hard trước → sau | p99 trước → sau |
|---|---|---|
| sân lát (330,100–800,500) | 3,38 → **2,21 %** | 73,7 → 56,6 |
| vườn hoa, lá (700,330–1024,510) | 8,46 → **4,75 %** | 84,4 → 62,7 |
| nền gạch gần camera (330,520–1000,690) | 1,97 → 2,50 % | 56,5 → 55,0 |

- Ở nền gạch, `hard` tăng nhẹ vì aniso làm hiện rõ khe gạch, không phải răng cưa (xem ảnh).
- Ảnh cắt 4×: `metrics\game_world1_garden_4x.png`, `game_world1_rail_4x.png`, `game_world1_lower_4x.png`.
- Đọc bộ nhớ Game.exe sau khi sửa (`metrics\game_mem_fix1.txt`): `2 2 1 1` cho tới khi renderer khởi tạo, sau đó `3 3 2 8` (ANISOTROPIC/ANISOTROPIC/LINEAR, aniso 8).
- Đọc bộ nhớ một Game.exe của nhánh khác chưa sửa (`game_mem_other_agent_itemtext.txt`) ra `2 2 1 1`.

## 4. Mã

Móc `// CYS-AA:` nằm trong `CysPostFx.cpp`.
- `applyTextureFiltering` là bản sao đúng `FUN_18002e5c0`: đổi mặc định của `MaterialManager`. OGRE 1.2.5 lấy lại mặc định ở mỗi `_setPass`, nên material đã nạp cũng theo.
- Khoá khởi động, theo đúng thứ tự trong bảng: `PostFX.AAMode=fxaa`, `View_Fanhunjiao` (host), `Gfx_AA`, `View_TextureFiltering=2`.
- `startupAaOverride` chỉ tác động lúc khởi động:
  - Chế độ `fxaa|fxaaquality|dlaa`: cfg để 0 thì đổi thành bộ lọc tương ứng.
  - `none`: luôn là 0.
  - `cy`: giữ cfg và bỏ qua `View_TextureFiltering` lúc khởi động.
- Khi đang chạy, hộp thiết lập vẫn đi qua `applyVariable` (sự kiện `VARIABLE_CHANGED` trong `RenderSystem.cpp`), nên người chơi vẫn tắt/bật FXAA và đổi mức lọc được.
- Dòng log:
  - `CysPostFX: anti-aliasing FXAA (View_Fanhunjiao=fxaa)`
  - `CysPostFX: View_TextureFiltering=2 (…): min/mag/mip 3/3/2 anisotropy 8`
  - Dòng `start-up configuration` có thêm `[CYS-AA fxaa: View_Fanhunjiao 0->fxaa]`.
- Công cụ đi kèm:
  - `run_cy_capture.ps1` có thêm hành động `t:mem:<module>,<rva>,[ptrOff…],<off>,<count>` để đọc bộ nhớ chỉ đọc theo chuỗi con trỏ.
  - `aa_metrics.py` (`stats`, `sheet`).
- `Tools\game\stage_game.py`: chỉ sửa chú thích cũ.

## 5. Chi phí GPU và kiểm tra công tắc

Cách đo:
- TlbbViewer, cảnh Đại Lý, 1920×1080, bóng high, `CYS_PERF=1`, 900 khung, bỏ 1/3 đầu. RTX 2060.
- Số liệu và bảng: `perf\gpu_summary.tsv`.
- Lượt A và lượt B cách nhau vài phút, và tải máy lúc đó khác nhau khoảng 5 ms. Vì vậy chỉ so các ca **trong cùng một lượt**.

| Cấu hình | GPU trung vị lượt A | GPU trung vị lượt B |
|---|---|---|
| bilinear, không AA (trước khi sửa) | 24,91 ms | 20,04 ms |
| aniso ×8, không AA | 25,52 ms (+0,61) | — |
| **aniso ×8 + FXAA (mặc định mới)** | 26,83 ms (+1,92) | **21,01 ms (+0,96)** |

- Lượt B ít nhiễu hơn: tăng khoảng **+1 ms mỗi khung ở 1080p**.
- Theo `07d` §10, riêng FXAA tốn 0,11–0,14 ms. Phần còn lại là anisotropic ×8 trên cảnh có nhiều bề mặt nghiêng (INF: chưa tách riêng được, vì nhiễu giữa hai lượt vượt quá độ chênh cần đo).
- Khi cần tiết kiệm: `CYS_TEXFILTER=0` (hoặc chỉnh `View_TextureFiltering` trong hộp thiết lập) bỏ phần anisotropic nhưng giữ FXAA.

Kiểm tra công tắc:
- Game.exe chạy `CYS_AA=cy` (`replay-run-4`, PASS). Khung `world-1` lệch khung trước khi sửa **0,18 luma**, lệch khung sau khi sửa 2,62. Nghĩa là `cy` tái tạo đúng trạng thái cũ, cũng là trạng thái của CY.
- Log của lượt đó: `[CYS-AA cy: View_TextureFiltering 2 not applied at start-up]` và `anti-aliasing none`.

## 6. Còn lại / chưa xác minh

- Mép lá, cỏ alpha-test vẫn còn bậc ở mức nhỏ (FXAA chỉ làm mềm). CY cũng không có cách nào khác tốt hơn.
- Bóng CYS có bậc ở chân cột lan can (`probe\world1_rail.png`). Việc này thuộc agent shadow, không nằm trong phạm vi AA.
- INF về nguyên nhân người dùng "thấy CY mịn": cfg của CY có `View_MaxWindow=1` (cửa sổ phóng to trên màn 2560×1440, render ở độ phân giải cao hơn), trong khi stage của dự án chạy cửa sổ 1024×768. Ngoài ra NewHDRBloom trước đây làm nhoè cạnh. Chưa đo được CY ở chế độ phóng to vì bản sao buộc `View_MaxWindow=0`.
- World của CY chưa chụp được. Kết luận "CY world = bilinear, không AA" là INF dựa trên mã.
