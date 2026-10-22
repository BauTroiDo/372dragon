# Hiệu chỉnh màu theo CY 3.71 — "màu quá rực / cháy trắng"


## 0. Tóm tắt

- Người dùng: "bạn có thấy màu nó quá là rực không ?", "Màu nó vẫn quá Rực" (Đại Lý mới, Vô Lượng Sơn).
- **Nguyên nhân (FACT):** CY-Source bật **NewHDRBloom** ở cảnh thế giới theo client_GL. CY 3.71 thì không bao giờ bật nó ở
  world. `dali_new_320` và `wuliang` không có `.newhdrbloom` ⇒ bộ đọc lấy mặc định B (Intensity 0, UseHDR 1,
  UseAutoExposure 1) ⇒ tự phơi sáng đưa luma trung bình về 1,0 rồi ACES ⇒ **luma +50–62 %, p95 212, chroma cỏ +72 %**.
- **Sửa:** `PostFX.HDRMode = cy` (mặc định): NewHDRBloom tắt ở world như `CScene::EnterScene` CY; `View_HDRFilter` chỉ
  chọn bộ lọc HDR cũ như Render.dll CY (chưa dựng ⇒ không làm gì); mặc định `View_HDRFilter=0`, `View_Fanhunjiao=0`
  như `Bin\System.cfg` CY. A/B: `CYS_COLOR=gl` hoặc `--postfx PostFX.HDRMode=gl` + `View_HDRFilter=1`.
- Các tầng khác (LUT nhận bóng `luttex.png`, bóng, ColorLUT theo cảnh, sương) **giữ nguyên**: đều đúng CY và tác động
  nhỏ (bảng mục 3).

## 3. A/B từng tầng (TlbbViewer 1280×720, `--lights scene`, cùng camera; `metrics\*_layers.tsv`)

Đại Lý `dali_new_320`, camera game (eye 2246,1990,−1548 → 847,1270,−149, fov 35):

| Cấu hình | luma | chroma | HSV sat | p50 | p95 |
|---|---|---|---|---|---|
| mặc định cũ (`b`: FXAA + NewHDRBloom auto) | **172,1** | **37,5** | 0,229 | 188 | 212 |
| tắt NewHDRBloom | 114,5 | 29,5 | 0,245 | 122 | 152 |
| tắt NewHDRBloom + FXAA (= **mặc định mới**) | 114,4 | 29,8 | 0,248 | 123 | 152 |
| + tắt LUT nhận bóng (`CYS_SHADOW_LUT=0`) | 103,7 | 25,6 | 0,230 | 111 | 140 |
| + tắt bóng (`--shadow off`) | 96,9 | 22,1 | 0,208 | 99 | 140 |
| `Gfx_PostFX=0` | 114,4 | 29,8 | 0,248 | 123 | 152 |
| sương tắt / `UseHDR=0` qua tham số | = mặc định cũ (cảnh không có `.hfog`; tham số bị file cảnh ghi đè) | | | | |

Vô Lượng Sơn `wuliang` (orbit 35,20, fov 55): cũ luma 153,4 / chroma **121,3** / sat 0,701 → tắt NewHDRBloom 94,8 / 70,3 /
0,649 → mới 94,9 / 70,9 / 0,656 → không LUT 88,6 / 60,2 / 0,599.
Tầng làm vọt: **NewHDRBloom (tự phơi sáng + ACES)**. LUT nhận bóng +10 luma / +0,02 sat là đúng CY (`cy-look_vi.md` §2).

## 4. Trước / sau

| Cảnh | Nguồn | luma trước → sau | chroma trước → sau | Ảnh |
|---|---|---|---|---|
| Đại Lý (camera game) | viewer | 172,1 → 114,4 | 37,5 → 29,8 | `metrics\dali_before_after.png` |
| Đại Lý (camera vào world) | viewer | 181,9 → 125,3 (p95 219 → 168) | 29,0 → 23,6 | `metrics\dali2_before_after.png` |
| Vô Lượng Sơn | viewer | 153,4 → 94,9 | 121,3 → 70,9 | `metrics\wuliang_before_after.png` |
| Đại Lý world-1 | Game.exe replay (vùng 3D) | 173,7 → 119,7 | 34,5 → 27,8 | `replay-run-2`, trước = `2026-09-14-cy-gui-2\replay-5` |
| Đại Lý zoom-far / yaw90 | Game.exe replay | 166,9 → 116,3 / 160,4 → 121,6 | 38,4 → 28,4 / 28,9 → 32,3 | `metrics\game_skylow_before_after.png` |
| Đăng nhập `erengu_DL` | CY thật / viewer | CY 46,5; trước 49,7 (+6,8 %); sau 51,1 (**+9,7 %**) | CY 33,9; trước 35,6 (+5,1 %); sau 34,1 (**+0,6 %**) | `metrics\login_cy_before_after.png` |

- Replay: khung move-running/move-after sau khi gộp main có camera khác (va chạm camera đổi) ⇒ không so từng điểm.
  Chroma yaw90/sky-low tăng nhẹ vì trời hết bị bạc (trước: đỉnh bị ép về trắng).
- Đăng nhập: bão hoà/chroma khớp CY trong 5 %; **luma dư +9,7 %** là **cục bộ**, không phải lệch toàn cục: dải trái
  (tượng đá có lửa + nến, FakeLight) +18 %, dải phải (mặt quỷ) −3 % luma / −10 % chroma; `CYS_FAKELIGHT=0` ⇒ +4,8 %
  (`metrics\login_residual*.tsv`). Bầu trời viewer thiếu trăng đỏ (`CYS_SKY=0`/`CYS_ENV=0` không đổi số) ⇒ không áp
  gain/gamma toàn cục (sẽ làm lệch phía còn lại). Trong game, cảnh đăng nhập id < 0 vốn đã giữ NewHDRBloom tắt; dự án
  hiện chưa vẽ cảnh 3D ở màn đăng nhập (nền xanh trơn).

## 5. Mã (`// CYS-COLOR:`, `Src\Engine\WXCore\CYS\PostFX\CysPostFx.cpp`)

- Khoá khởi động `PostFX.HDRMode` (`cy` mặc định | `gl`), đọc trước `View_Fanhunjiao/View_HDRFilter`; `CYS_COLOR`
  (`cy|gl`) thắng khi có. Mặc định `View_Fanhunjiao=0`, `View_HDRFilter=0`.
- `cy`: `View_HDRFilter` ghi log "legacy HDR filter … not built", không đổi NewHDRBloom; `onSceneLoaded(id)` gọi
  `request("NewHDRBloom", false)` như EnterScene CY. `Gfx_HDRBloom=1` đặt tường minh vẫn giữ (dùng để xem thử).
- `gl`: như trước (client_GL). Chuỗi, preset `b`, ColorLUT, HeightFog, LUT nhận bóng không đổi.
- Log: `CysPostFX: HDR rule cy (…)`, dòng khởi động có `PostFX.HDRMode=cy(default) View_HDRFilter=0(default)`.
- GPU: chỉ bớt pass (NewHDRBloom 0,21 ms + FXAA 0,11 ms ở 1080p theo `07d` §10) ⇒ không tăng.
- `Tools\game\stage_game.py` còn chú thích cũ "Defaults stay client_GL's (FXAA + NewHDRBloom)" (chỉ chú thích).

## 7. Chưa làm / chưa xác minh

- Bộ lọc HDR cũ của CY (`View_HDRFilter=1`, `.hdr` KeyValue…) chưa dựng (mặc định CY tắt).
- Dư +9,7 % luma ở đăng nhập: FakeLight/đuốc tượng trái và bầu trời (trăng đỏ) — INF: cường độ FakeLight hoặc lớp sky
  `EnScene`; chưa có ảnh CY world để kiểm.
- Không có ảnh CY của tạo nhân vật / Đại Lý / Vô Lượng Sơn (cần đăng nhập). Bảng vùng cỏ/đá/da: đo được trên dự án
  (`metrics`), chưa có đối chiếu CY.
