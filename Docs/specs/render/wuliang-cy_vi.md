# Vô Lượng Sơn — so render CY 3.71 và CY-Source (wuliang-parity)

Agent `wuliang-parity`, nhánh `wuliang-parity`, 15/09/2026. Dừng theo lệnh người dùng lúc 18:55 ("xong việc hiện tại thì
dừng hẳn, không bắt đầu khác biệt mới"). Quy ước: **[DK]** dữ kiện (trace, ảnh, mã, disasm), **[SL]** suy luận.
Bằng chứng: `Build\Logs\2026-09-15-wuliang-parity\`.

## 2. Số đo ảnh (viewer-2 so CY, HUD CY che) [DK]

`cmp-1\metrics-viewer2.tsv`, ảnh `cmp-1\contact-viewer2.png` (cột CY / dự án / |diff|×3).

| Khung | abs RGB | abs khối 4×4 | luma CY/dự án | chroma CY/dự án | độ nét CY/dự án |
|---|---|---|---|---|---|
| w0 xa | 1,76 | 1,14 | 96,0 / 96,0 | 66,6 / 66,5 | 38,1 / 37,0 |
| w1 gần | 1,65 | 1,10 | 99,0 / 99,1 | 67,2 / 67,4 | 31,7 / 31,0 |
| w2 yaw −121 | 2,88 | 1,91 | 96,9 / 97,0 | 68,9 / 69,2 | 36,3 / 34,9 |
| w3 xa yaw −121 | 2,51 | 1,54 | 95,9 / 95,8 | 65,6 / 65,6 | 38,9 / 37,2 |

- Màu/tông gần như trùng (luma ±0,1, chroma ±0,3). Chênh còn lại tập trung ở: NPC/tên (dự án viewer không có NPC),
  hạt cổng dịch chuyển (vùng r00 của w2 5,3), lá dương xỉ/cây (gió khác pha), vệt lưới ô địa hình trong ảnh hiệu luma
  có dấu (`cmp-0\signed-luma-x8-w1-close.png`, đường thẳng theo biên ô).
- Dự án mềm hơn CY 2–5 % (độ nét) ở cả 4 khung.
- viewer-1 → viewer-2 (L5 của main): abs w0 1,82 → 1,76, w3 2,57 → 2,51.

## 3. Lệnh vẽ theo lớp [DK]

`layers-w0-w1.tsv` (px của viewer ×4 vì MSAA 4 — không so px viewer với CY; Game.exe live không MSAA).

| Lớp | CY w0 | viewer-1 w0 | viewer-2 w0 | CY w1 | viewer-2 w1 | Game.exe live-1 w1* |
|---|---|---|---|---|---|---|
| Địa hình (`c8eaf13b`/`2fe658e4`) | 14 | 95 | **14** | 12 | **12** | 83 (build trước L5) |
| Entity alpha-test (`6972ae69`) | 47 | 47 | 47 | 23 | 23 | 29 |
| Entity đục (`9f7d6cc2`) | 9 | 9 | 9 | 3 | 3 | 7 |
| Actor NPC/quái (`692dc86a`,`a2769318`,`fbc994fe`) | 7 | 0 | 0 | 5 | 0 | 17 |
| Trời SkySphereLayer (`efff5b67`) | 4 | 4 | 4 | 4 | 4 | 4 |
| Hạt HLSL (`e633dab2`,`091c76b0`) | 4 | 2 | 2 | 0 | 0 | 0 |
| FF (hạt + UI CY) | 85 | 2 | 2 | 83 | 2 | 82 |
| Bóng: địa hình/tĩnh (`c46a8a36`) | 42 | 285 | **36** | 42 | 38 | 222 |
| Bóng: alpha-test (`2d5580e0`) | 254 | 269 | 269 | 333 | 296 | 243 |
| Bóng: đục (`a38170c2`) | 49 | 57 | 57 | 66 | 65 | 71 |
| Hậu kỳ (FXAA `bcf6cee1`, chép+dither `a6ff6bd9`) | 0 | 0 | 0 | 0 | 0 | 2 |

\* live-1 khác vị trí nhân vật và độ phân giải, chỉ so cấu trúc.

## 4. Bảng khác biệt

| # | Lớp | CY 3.71 [DK] | CY-Source [DK] | Nguyên nhân | Chủ / trạng thái |
|---|---|---|---|---|---|
| 1 | Cấu trúc khung Game.exe | Vô Lượng Sơn: **2 pass** — bóng `rt1` 4096² R32F → vẽ thẳng back buffer 1280×720 X8R8G8B8, không RT FP16, không hậu kỳ (Đại Lý có FP16 + HeightFog vì cảnh có sương cao [SL]) | live-1: bóng → `rt2` FP16 → FXAA (`bcf6cee1`) → chép + `ditherAmount` (`a6ff6bd9`) → bb | CysPostFX luôn dựng chuỗi FP16 + FXAA (aa-cy bật FXAA mặc định) | aa-cy / d3d9-trace L2 — **chưa sửa**, ghi lại |
| 2 | Địa hình | 12–14 lệnh vẽ, atlas 4096×1024 + lightmap **L8 256²/ô** | viewer-2 12–14 lệnh vẽ (sau L5), lightmap **cả map 2560² L8**; vệt lưới biên ô trong ảnh hiệu | L5 phần lightmap theo ô | d3d9-trace (không thuộc phạm vi); main 1ff0f593 đã gộp L5b (lightmap 256² L8 + colormap 64² theo ô) — cần đo lại |
| 4 | Hạt cổng `chuansongdian` | 4 lệnh vẽ HLSL: `091c76b0` (_05) + `e633dab2` ×3 (_01, _03, _04), VS `e46476b1`, blend ONE/ONE | _01/_03 (material `chuansongdian_01/02` FF không kế thừa `Mtl_Particle`) vẽ **FF** (COLOROP MODULATE), _04/_05 HLSL | Hệ vật liệu CY đổi pass FF của hạt sang `Particle` HLSL; `CysMaterialSystem` không đổi hai material này | fx — disasm `e633dab2` = saturate(tex × màu đỉnh), alpha × `surface_diffuse_colour.w` ⇒ cùng toán học với FF [DK]; màu cam/xanh khác trong ảnh do pha ngẫu nhiên của ColourFading [SL]. Chưa sửa |
| 5 | Hằng hạt `blocks`/`useUDirection` | (0,874; 0,812) / 0,557 (giá trị rác thanh ghi của shader trước) | (1,1) / 0 | CY không đặt hằng này | không ảnh hưởng (nhánh `useRibbon = 0`) |
| 6 | Pass bóng caster alpha-test | D3D `ALPHATESTENABLE=1 GREATER 128`, sampler ANISOTROPIC ×8 + mip LINEAR | không bật alpha test D3D (PS `2d5580e0` vẫn `texkill` cùng ngưỡng), sampler LINEAR + mip POINT, aniso 16 | cấu hình sampler pass bóng | ảnh hưởng nhỏ (hình bóng lá ở mip xa); shadow/perf-cy |
| 7 | View bóng | cùng hướng đèn (−0,557; −0,743; −0,371) = `#FairyMainLightOne`; view dịch (6014; −6430), trục up khác | view gốc 0 | cách dựng ma trận đèn | không đổi hình; shadow-cy |
| 8 | Thứ tự hàng đợi cảnh | Spearman −0,08 trên 64 cặp (entity đục CY vẽ sau) | — | M1 của d3d9-trace | d3d9-trace |
| 9 | Viewer (chỉ công cụ) | msaa 0, aniso 8, near 10 | msaa 4, aniso 16, near 23,6 | tham số TlbbViewer | không sửa Game.exe; ghi chú khi đọc px/độ nét |
| 10 | Cấu hình stage | `View_Resoution 1280,720`, `View_Aplomb 1` (VSync), `View_Floodlight 1`, `View_VisibleRangeLevelNew 2`, `View_EffectLevel 2` | stage: 1024,768; Aplomb 0; Floodlight 0; ba khoá sau không có | `stage_game.py` | perf-cy (VSync) / người điều phối |
| 11 | Actor | 5–7 lệnh vẽ actor (NPC 老神医 + vượn của oracle) | live-1 17 (server thật có nhiều quái hơn) | nội dung server | không phải khác biệt render |

## 5. Đã sửa

Không có sửa render nào hoàn tất trước lệnh dừng. Đã commit công cụ: driver camera CY cho Game.exe live
(`CYS_WLP_CAMS`, không đổi hành vi khi không đặt biến).

## 6. Game.exe live ở Vô Lượng Sơn [DK]

`live-1\run\run.json`: đăng nhập, chọn CYTest00, `GCEnterScene scene=6`, navmesh, 4 ảnh camera CY, thoát
`quit_complete quit_flag=0 decode_failures=0`, 0 lỗi Lua, 0 dump, chỉ socket 127.0.0.1:15733/15734, 151 s. Các kiểm
`three_ground_clicks/position_changed` sai theo thiết kế (chế độ WLP không click); `world_shots` sai vì tên ảnh — đã đổi
thành `wlp-cam-*`. Không đổi vị trí/cấp/phái nhân vật (bot đặt chỗ lượt live-1 lỗi tham số, không gửi gói).
