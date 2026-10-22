# 09 — Hiệu năng render của CY-Source

Ngày 13/09/2026. Người làm: agent perf (Claude), phiên `7dee11c4-af32-4edd-9ec1-d23eb9125905`.

Phạm vi:
- đo Game.exe x64, TlbbViewer và OgreSmoke;
- dụng cụ đo `CYS_PERF`;
- sửa các nút cổ chai ở phần chưa ai phụ trách: vòng lặp và bộ giới hạn khung của Game, D3D9, lõi render OgreMain, CEGUI.

Hạt, hiệu ứng, hậu kỳ, material, mạng và DBC không sửa. Các vấn đề ở đó chỉ báo lại, kèm bằng chứng (mục 8).

## 1. Tóm tắt

**Nguyên nhân chính của "render rất chậm": Game.exe tự khoá khung ở 30 fps, và nhịp khung còn giật.**
- Vòng lặp 0.85 tạo nhịp bằng `timeSetEvent(1000/System_MaxFPS)`. Cấu hình của người dùng có `System_MaxFPS=30`, nên máy luôn chạy 30 fps dù CPU chỉ bận 3–12 ms mỗi khung.
- Timer này không nâng độ phân giải của bộ lập lịch Windows, nên nhịp rơi vào lưới 15,6 ms. Khung dài lúc 31 ms, lúc 47 ms; p95 là 46–51 ms, và cứ vài giây lại có khung trên 50 ms.
- Bằng chứng từ chính bản người dùng đang chơi: `Build/gpt-p1-1-20260913/stage-91148e1/Bin64/WXRender.log` ghi `Average FPS: 30.3425 Best FPS: 31.1587 Worst FPS: 0.21427`.
- client_GL (B) không đọc `System_MaxFPS`. Game.exe của B chỉ có hai khoá `System_MaxFPS_Front` và `System_MaxFPS_Back`; cấu hình của client_GL đặt 90/25. Cấu hình của người dùng cũng đã có `Front=60`, `Back=30`, nhưng Game của ta bỏ qua hai khoá này.

**Sửa (fix `pacer`, `GameProcedure.cpp`):**
- Nhịp khung theo B: dùng `System_MaxFPS_Front` khi cửa sổ có tiêu điểm, `System_MaxFPS_Back` khi không.
- Timer chờ độ phân giải cao, hẹn giờ theo mốc tuyệt đối trên đồng hồ QPC, và không dồn khung bù sau một khung dài.
- Kết quả: cùng máy, cùng kịch bản offline, các lượt chạy liền nhau, đo khi màn đứng yên sau khi nạp xong. Mỗi ô ghi fps / p95 ms / số khung >50 ms.

| Màn | 1920×1080 trước | 1920×1080 sau (`pacer`) | 1024×768 trước | 1024×768 sau (bản cuối) |
|---|---|---|---|---|
| Đăng nhập | 30,3 / 46,5 / 2 | **60,0 / 17,1 / 0** | 30,3 / 47,5 / 10 | **59,9 / 19,0 / 0** |
| Chọn nhân vật | 30,3 / 46,5 / 0 | **60,0 / 17,1 / 0** | 30,3 / 47,2 / 7 | **60,0 / 17,1 / 0** |
| Chọn nhân vật, lần 2 | 29,4 / 46,7 / 14 | **60,0 / 17,2 / 0** | 30,3 / 46,5 / 5 | **60,0 / 17,2 / 0** |
| Tạo nhân vật | 30,2 / 46,1 / 13 | **59,7 / 23,5 / 2** | 30,3 / 46,8 / 28 | **59,7 / 18,5 / 0** |

- Khung dài nhất khi đứng yên ở 1080p: trước 48–216 ms; sau 27–30 ms ở màn đăng nhập và màn chọn, 61 ms ở màn tạo.
- Mục tiêu "≥60 fps, không khung >50 ms sau khi nạp":
  - đạt ở mọi màn ở 1024×768;
  - đạt ở màn đăng nhập và màn chọn ở 1080p;
  - màn tạo ở 1080p còn 1–2 khung >50 ms trong ~65 s. Các lượt này chạy lúc máy có 5–11 tiến trình biên dịch của agent khác, nên cần đo lại khi máy rảnh (mục 8).
- Bản cuối ở 1080p (thêm `uiredraw` và `psconst`) cũng đạt 59,3–60 fps. p95 của nó là 20,6–26,5 ms vì lượt đó chạy lúc máy có trung bình 10,8 tiến trình biên dịch. Số liệu đầy đủ ở mục 7.6.

**Các sửa phụ, đo riêng từng cái:**
- **GUI dựng lại toàn bộ hình học mỗi khung ở mọi màn** (`uirebuild=1,00`). CEGUI 0.4 không kiểm tra giá trị có đổi hay không, nên mỗi lần đặt lại y hệt cũng dựng lại toàn bộ GUI. Ba bản sửa, mỗi bản một nguồn; sau cả ba, `uirebuild` xuống 0,00–0,03 mỗi khung, `uidraw` từ 0,16–1,3 ms xuống 0,02–0,06 ms, và cấp phát mỗi khung giảm ~10 lần (đăng nhập 2.158 → 78; chọn 136 → 22; tạo 356 → 32):
  - `btnalpha` là nguồn chính, tìm bằng watchpoint phần cứng trên cờ `System::d_gui_redraw` (mục 5.2): mọi nút `Falagard/Button` đang hiện gọi `setAlpha(1)` mỗi khung.
  - `uiredraw2`: đồng hồ `Falagard/StopWatch` đặt lại cùng chữ mỗi khung ở màn chọn và màn tạo; con trỏ ô nhập liệu yêu cầu vẽ lại cả khi con trỏ không được vẽ.
  - `uiredraw`: ba widget FalagardEx khác gọi `requestRedraw()` vô điều kiện mỗi khung.
- Hai bản sửa từ phát hiện của agent hạt (đúng phạm vi tôi phụ trách):
  - `seqframe`: affector SequenceFrame tra `std::map` cho từng hạt mỗi khung; đổi sang bảng băm.
  - `nonvis`: WXRender đặt `setDefaultNonVisibleUpdateTimeout(5.0f)` lúc khởi tạo, đúng như `Render.dll` của B.
- `psconst` (D3D9): hằng số pixel shader trước đây được đẩy mỗi thanh ghi một lần gọi; nay gộp thành từng loạt. Số lần gọi `SetPixelShaderConstantF` giảm ~7 lần: 5.481 → 726 mỗi khung ở màn chọn, 8.068 → 1.046 ở màn tạo. Hình ảnh không đổi.

**TlbbViewer.** Cả 4 cảnh (S01, S07, S09, S10) và 5 hiệu ứng nhiều hạt nhất đều chạy 190–1.200 fps ở cả 1920×1080 lẫn 1024×768. Không khung nào quá 50 ms sau khi ấm máy. Viewer không phải chỗ chậm.

**Điểm thiết bị không có vấn đề:** D3D9 dùng HAL với xử lý đỉnh bằng phần cứng. Build là Release `/O2` với CRT không debug. Có shader cache. Log không phình khi đứng yên. Scene manager là `OctreeSceneManager`. Chi tiết ở mục 6.

## 2. Máy đo và cách đo

- **Máy:** Xeon E5-2696 v3 (18 nhân / 36 luồng, 2,3 GHz), RAM 32 GB, RTX 2060 6 GB (driver 591.86), màn 2560×1440 ở 59 Hz, Windows 11 IoT LTSC 2024.
- **Máy dùng chung với 7 agent khác.** Họ biên dịch và chạy viewer cùng lúc, nên thời gian CPU của từng pha dao động mạnh giữa các lượt. Ví dụ: cảnh tạo nhân vật 1080p đo được `render` 14,9 ms ở lượt A và 8,8 ms ở lượt B, cùng bị giới hạn 30 fps.
  - Runner ghi số tiến trình `cl/link/ninja` và số công cụ GPU khác trong mỗi giây vào `logsize.csv`.
  - Các cặp so sánh cuối cùng (mục 7.1) chạy liền nhau trong cùng điều kiện.
- **Game.exe:** chạy offline trên một bản sao riêng `Build/perf/stage`, sao một lần từ stage của người dùng. Stage của người dùng không bị sửa.
  - Kịch bản là smoke GL/CY sẵn có: `-cys-gl-login-smoke` với `CYS_CREATE_ROLE_SMOKE=Preview`. Đây là fixture offline: không xác thực, không socket. Runner dừng ngay nếu thấy kết nối TCP nào.
  - `CYS_PERF_HOLD="Login:15,CharSel:20"` cho smoke dừng 15 s ở màn đăng nhập và 20 s ở màn chọn, để đo trạng thái đứng yên.
  - Mỗi lượt dài 150–210 s và kết thúc bằng lượt đứng yên ở màn tạo nhân vật.
  - Màn chọn offline là màn trống (fixture). Người dùng thật thấy màn này có 1 nhân vật.
- **TlbbViewer:** `--scene/--effect … --frames 900 --dt 0.0166667 --no-vsync --size WxH --shot --show`, cửa sổ hiện nhưng không cướp tiêu điểm.
  - Số liệu đã ổn định = bỏ 60 khung đầu. Khung 0 mang toàn bộ công khởi tạo. Khung chụp PNG cuối cũng bị bỏ.
- **Độ phân giải:** 1920×1080 và 1024×768, cửa sổ, không VSync (đúng với `View_Aplomb=0` của người dùng).
- **Cách tính:**
  - Khung = khoảng giữa hai lần `Root::_fireFrameStarted`.
  - Phân vị lấy theo hạng gần nhất: `sorted[round(q·(n−1))]`, giống nhau trong game và trong script.
  - Khung giật (hitch) = khung dài hơn 50 ms.
  - "Settled" = bỏ 2 s đầu của mỗi đoạn trạng thái.

## 3. Dụng cụ đo `CYS_PERF`

Bật bằng biến môi trường `CYS_PERF=1`. Khi không bật, mọi móc chỉ tốn một phép so sánh. Chi phí của bộ thu khi bật khoảng 0,1 ms mỗi khung (dòng `self=` trong log).

| Biến | Tác dụng |
|---|---|
| `CYS_PERF_INTERVAL=2` | chu kỳ ghi dòng log (giây) |
| `CYS_PERF_CSV=<file>` | mỗi khung một dòng: pha CPU, GPU, bộ đếm, cấp phát, `#mark` |
| `CYS_PERF_LOG=<file>` | chép các dòng `CYS-PERF` ra tệp riêng (TlbbViewer không ghi log OGRE) |
| `CYS_PERF_OVERLAY=1\|2` | vẽ tóm tắt lên màn hình (atlas GDI, texture managed, không đụng Reset thiết bị) |
| `CYS_PERF_GPU=0` | tắt đo GPU |
| `CYS_PERF_ALLOC=0` | tắt đếm cấp phát |
| `CYS_PERF_LISTENERS=0` | tắt đo thời gian từng frame listener |
| `CYS_PERF_HOLD=…` | (chỉ smoke) dừng smoke sau khi đổi màn |
| `CYS_PERF_PACER=legacy` | dùng lại nhịp 0.85 để so A/B |

**Đo gì:**
- **Pha CPU.**
  - Game: `msg`, `wait`, `tick` (gồm `input`, `ui`, `net`, `world`, `object`, `script`), `harness` (thao tác và chụp ảnh của smoke), `events`, `render`.
  - OGRE: `fstart` (các frame listener, trong đó `build` là dựng cảnh dần), `ctrl` (controller, tức cập nhật hạt), `sanim`, `graph`, `cull` (tìm vật thấy được và dựng render queue, gồm `anim` là skeleton/skinning), `draw` (gồm `uidraw` của CEGUI), `present`, `fend`, `targets` (tổng cập nhật mọi render target).
- **GPU:** timestamp D3D9 bao cả khung, cửa sổ chính, render target phụ và UI. Kết quả được đọc lại sau vài khung, không flush.
- **Bộ đếm mỗi khung:**
  - draw call, primitive, texture/VS/PS/render state/sampler state, declaration/stream/index;
  - số thanh ghi hằng số VS và số lần gọi đẩy hằng số PS;
  - số `_renderScene`, entity đưa vào queue, entity có animation bẩn, số skin bằng CPU, số `_updateAnimation` gọi từ ngoài;
  - số vật dựng dần, CEGUI (dựng lại, nạp VB, quad, batch);
  - texture nạp, shader tạo;
  - cấp phát, byte và giải phóng heap của từng module (móc import CRT, thunk không bao giờ gỡ nên an toàn khi DLL unload).
- **Mỗi chu kỳ:**
  - số entity, hệ hạt, số hạt, tổng quota;
  - số material/texture/mesh và dung lượng texture đã nạp;
  - 5 frame listener tốn nhất;
  - cấp phát theo module.
- **Mốc (`#mark`):** đổi màn (`proc:Login`, `proc:CharSel`, `proc:CharCreate`), `scene-built` (dựng dần xong), `hold-end`, `app-active` / `app-inactive`.

**Mã:**
- `Src/Engine/OGRE/OgreMain/include/OgreCysPerf.h` và `src/OgreCysPerf.cpp`: khối đếm xuất từ OgreMain; Game.exe lấy qua `GetProcAddress("CysPerfBlock")`.
- `Src/Engine/WXCore/CYS/Perf/CysPerf.{h,cpp}`: bộ thu, cài từ `WX::System::setup`.
- Các móc nhỏ gắn thẻ `// CYS-PERF` trong `OgreRoot.cpp`, `OgreSceneManager.cpp`, `OgreEntity.cpp`, `OgreD3D9RenderSystem.cpp`, `OgreD3D9RenderWindow.cpp`, `OgreD3D9Texture.cpp`, `OgreD3D9GpuProgram.cpp`, `OgreCEGUIRenderer.cpp`, `WXSystem.cpp`, `WXSceneInfo.cpp` và `GameProcedure.cpp`.

**Công cụ** (thư mục `Tools/perf`):

| Tệp | Việc |
|---|---|
| `build_perf.cmd` | build cây riêng, tối đa 4 luồng |
| `stage_perf.ps1` | cài một biến thể nhị phân vào stage perf |
| `run_game_perf.ps1` | chạy Game offline |
| `run_viewer_perf.ps1` | chạy TlbbViewer |
| `run_ogresmoke_perf.ps1` | chạy OgreSmoke |
| `perf_report.py` | thống kê theo đoạn |
| `viewer_table.py` | bảng tổng hợp viewer |
| `pick_particle_effects.py` | chọn hiệu ứng nhiều hạt từ dữ liệu |
| `apply_perf_hooks.py` / `apply_perf_fixes.py` | áp móc và sửa, kiểm neo, giữ BOM/CRLF |

Kiểm thử ở `Tests/perf`: `test_perf_report.py` (6 ca) và `test_patchers.py` (2 ca, áp lên bản HEAD sạch).

### 4.1 Game.exe

Biến thể A là mã HEAD cộng dụng cụ đo, hành vi y hệt bản người dùng (nhịp 30 fps). B0 là đúng nhị phân của người dùng (`stage-91148e1`, SHA Game.exe `698887bc…`), không có dụng cụ đo.

**A, 1024×768**, bỏ 2 s đầu mỗi đoạn:

| Đoạn | fps | trung bình ms | p95 | p99 | max | khung >50 ms |
|---|---|---|---|---|---|---|
| Đăng nhập, đứng yên | 30,3 | 33,0 | 47,0 | 57,3 | 63,4 | 11 |
| Chọn, đang dựng cảnh | 30,3 | 33,0 | 46,8 | 53,0 | 71,1 | 6 |
| Chọn, cảnh đã dựng xong | 30,3 | 33,0 | 46,6 | 55,3 | 87,9 | 4 |
| Tạo, smoke thao tác (đổi 30 model, chụp ảnh) | 29,6 | 33,8 | 46,8 | 54,3 | 245,5 | 48 |
| Chọn, lần 2, đứng yên | 30,3 | 33,0 | 46,5 | 47,3 | 53,4 | 1 |
| Tạo, lần 2, đứng yên | 30,4 | 32,9 | 46,4 | 46,8 | 47,2 | 0 |

**A, 1920×1080:**

| Đoạn | fps | trung bình ms | p95 | p99 | max | khung >50 ms |
|---|---|---|---|---|---|---|
| Đăng nhập | 30,3 | 33,0 | 47,9 | 61,1 | 70,9 | 16 |
| Chọn | 30,3 | 33,0 | 46,7 | 55,1 | 59,7 | 7 |
| Chọn, đã dựng | 30,3 | 33,1 | 48,3 | 58,9 | 98,7 | 7 |
| Tạo, smoke thao tác | 28,5 | 35,1 | 48,5 | 62,2 | 500,6 | 87 |
| Chọn, lần 2 | 30,1 | 33,2 | 47,0 | 55,3 | 104,0 | 14 |
| Tạo, lần 2 | 30,3 | 33,0 | 48,8 | 57,3 | 61,8 | 5 |

**B0, nhị phân người dùng, 1024×768:**
- Chạy đủ kịch bản, 19 ảnh, 0 socket.
- Trong 51 s cuối đứng yên ở màn tạo nhân vật, tiến trình dùng 23,6 s CPU (~46 % một nhân) mà vẫn chỉ ra 30 khung/s.
- Kích thước ba log không đổi trong lúc đứng yên.

**Tải CPU/GPU của một khung ở trạng thái đứng yên** (A-1024; thời gian đã trừ phần chờ):

| Màn | CPU bận | render | cull | anim | draw | uidraw | present | GPU | draw call | tam giác | entity |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Đăng nhập | ~4,5 ms | 4,1 | 0,03 | – | 1,37 | 1,36 | 0,55 | 0,2 ms | 16 | 2,1 nghìn | 0 |
| Chọn (đã dựng) | ~9 ms | 7,9 | 2,3 | 0,6 | 3,8 | 0,24 | 0,6 | 3,3 ms | 687 | 284 nghìn | 118 |
| Tạo | ~11,5 ms | 10,4 | 3,0 | 0,9 | 5,5 | 0,65 | 0,7 | 5,2 ms | 1.086 | 421 nghìn | 273 |

Ở 1080p, màn tạo tốn 1.149 draw call, 297 entity và GPU 6,4–7,2 ms. CPU mỗi draw call trong pha `draw` là 5,0–5,7 µs. Cảnh tạo đẩy 37–40 nghìn thanh ghi hằng số VS mỗi khung.

### 4.2 TlbbViewer

Biến thể B (dụng cụ đo; viewer không dùng pacer). Mỗi ca 838 khung đã ổn định; bỏ khung 0 và khung chụp.

| Ca | Kích thước | fps | trung bình ms | p95 | p99 | max | >50 ms | GPU ms | draw | tam giác | cấp phát/khung |
|---|---|---|---|---|---|---|---|---|---|---|---|
| S01 suzhou | 1920×1080 | 414 | 2,41 | 3,11 | 4,13 | 10,5 | 0 | 0,45 | 407 | 57 nghìn | 20 |
| S01 suzhou | 1024×768 | 468 | 2,13 | 2,65 | 3,75 | 9,1 | 0 | 0,32 | 336 | 48 nghìn | 20 |
| S07 sr_rift | 1920×1080 | 498 | 2,01 | 2,23 | 2,51 | 12,6 | 0 | 1,16 | 340 | 167 nghìn | 17 |
| S07 sr_rift | 1024×768 | 558 | 1,79 | 1,98 | 2,35 | 18,2 | 0 | 0,60 | 290 | 143 nghìn | 17 |
| S09 FengYun_lingxiaocheng | 1920×1080 | 193 | 5,19 | 6,92 | 12,02 | 32,8 | 0 | 2,00 | 368 | 276 nghìn | 76 |
| S09 FengYun_lingxiaocheng | 1024×768 | 204 | 4,89 | 6,91 | 15,96 | 48,1 | 0 | 0,88 | 283 | 209 nghìn | 76 |
| S10 cy4_tangmen | 1920×1080 | 255 | 3,92 | 4,87 | 9,09 | 47,8 | 0 | 1,39 | 557 | 329 nghìn | 23 |
| S10 cy4_tangmen | 1024×768 | 211 | 4,74 | 8,33 | 22,70 | 42,2 | 0 | 2,12 | 438 | 268 nghìn | 23 |
| E087 yanhuo15 | 1920×1080 | 1152 | 0,87 | 1,20 | 5,44 | 15,7 | 0 | 0,11 | 4 | 3,9 nghìn | 25 |
| E087 yanhuo15 | 1024×768 | 1224 | 0,82 | 1,16 | 2,62 | 13,0 | 0 | 0,07 | 4 | 3,9 nghìn | 25 |
| 暴风骤雨 (quota 16.600) | 1920×1080 | 286 | 3,49 | 5,80 | 14,15 | 36,9 | 0 | 0,19 | 4 | 32,6 nghìn | 9 |
| 暴风骤雨 | 1024×768 | 359 | 2,79 | 3,45 | 6,10 | 9,4 | 0 | 0,29 | 4 | 32,6 nghìn | 9 |
| 雷电交加 (quota 8.045) | 1920×1080 | 535 | 1,87 | 2,18 | 10,76 | 30,1 | 0 | 0,13 | 4 | 15,8 nghìn | 9 |
| 雷电交加 | 1024×768 | 529 | 1,89 | 2,50 | 9,22 | 24,2 | 0 | 0,20 | 4 | 15,8 nghìn | 9 |
| 飞雪连天 (quota 8.400) | 1920×1080 | 568 | 1,76 | 2,46 | 14,04 | 30,8 | 0 | 0,10 | 4 | 14,9 nghìn | 9 |
| 飞雪连天 | 1024×768 | 647 | 1,55 | 2,12 | 9,68 | 20,6 | 0 | 0,08 | 4 | 14,9 nghìn | 9 |
| cj_束河下雨 (quota 4.950) | 1920×1080 | 814 | 1,23 | 1,43 | 3,96 | 12,2 | 0 | 0,14 | 3 | 9,6 nghìn | 9 |
| cj_束河下雨 | 1024×768 | 657 | 1,52 | 2,17 | 11,62 | 22,2 | 0 | 0,14 | 3 | 9,6 nghìn | 9 |

- **Cách chọn 5 hiệu ứng.** `pick_particle_effects.py` đọc `all.effect` và `all.particle` (43.297 template, 13.014 hiệu ứng) và ước lượng số hạt sống bằng min(quota, tổng tốc độ phát × tuổi thọ). Trong 100 ca oracle chỉ E087 là nặng (3.006). Bốn hiệu ứng thời tiết nặng nhất của toàn bộ dữ liệu được thêm vào. Kết quả: `Build/Logs/2026-09-13-perf/particle-effects-rank.json`.
- **Viewer không phải chỗ chậm.** Cảnh nặng nhất (S09, S10) vẫn chạy 190–250 fps.
- Chi phí đáng kể duy nhất của hạt là dựng đỉnh billboard trên CPU trong pha `cull`: 1,6–1,8 ms với 暴风骤雨 (16,6 nghìn quota).
- **Sai lầm đã tránh:** lần tổng hợp đầu cho 18.900 cấp phát/khung với hiệu ứng. Con số đó đến từ khung 0, khung chứa toàn bộ cấp phát khởi tạo, khoảng 17 triệu lần. Trung vị thật là 9–25. Bộ thu nay đặt mốc cấp phát ở khung đầu tiên, và báo cáo viewer bỏ 60 khung đầu.

### 4.3 OgreSmoke

`--batch 200 --frames 600` (lưới model, 4.181 tam giác), stage perf, shader cache ấm (209 hit / 0 miss):

| Kích thước | 600 khung | fps trung bình | ms/khung |
|---|---|---|---|
| 1920×1080 | 0,390 s | 1540 | 0,65 |
| 1024×768 | 0,323 s | 1855 | 0,54 |

Tài nguyên: Bootstrap 0,74 s, General 1,48 s, 65.174 material. OgreSmoke không phải bài đo tốc độ cảnh, chỉ là mốc so sánh.

## 5. Phân rã theo pha: vì sao chậm và vì sao giật

1. **Giới hạn 30 fps và nhịp 15,6 ms.** Khung được hẹn bằng `timeSetEvent(33,33)`. Không có `timeBeginPeriod(1)` nên sự kiện rơi vào nhịp 15,6 ms của bộ lập lịch: 2 nhịp = 31,25 ms, 3 nhịp = 46,9 ms, đôi khi 4 nhịp = 62,5 ms. Vì vậy p50 là 31 ms, p95 là 46–47 ms, và có khung trên 50 ms. CPU chỉ bận 4–12 ms; phần còn lại là `wait` 21–29 ms.
2. **GUI dựng lại toàn bộ mỗi khung** ở mọi màn (`uirebuild=1,0`) — **đã sửa** (mục 7.3).
   - CEGUI 0.4 biến mọi `requestRedraw`/`signalRedraw` thành việc dựng lại toàn bộ GUI, và không so giá trị cũ: đặt lại y hệt cũng ép dựng lại. `Window::update` chạy cả cho cửa sổ ẩn.
   - **Cách tìm sai lúc đầu:** đọc mã thấy ba widget FalagardEx gọi `requestRedraw` mỗi khung (ảnh động đăng nhập, ô chat, animate). Sửa chúng (`uiredraw`) **không** làm `uirebuild` giảm, nên phải còn nguồn khác.
   - **Chẩn đoán R (thất bại):** đếm `requestRedraw` theo cửa sổ, nhưng ghi ở mức `Informative`, mà `UISystem.log` chỉ giữ tới `Standard` (thẻ `(InfL1)` là `Standard`) nên không có dòng nào. Kết luận "ít hơn 1.200 yêu cầu" vì thế là sai.
   - **Chẩn đoán đúng — watchpoint phần cứng** (R2): đặt thanh ghi gỡ lỗi DR0 (ghi 1 byte) lên chính cờ `System::d_gui_redraw`; mỗi lần ghi `true` gom theo ngăn xếp 5 tầng, in kèm tên hàm (DbgHelp) mỗi 10 s. Bắt được mọi đường ghi cờ, kể cả hàm inline và DLL khác. Chỉ trong cây perf riêng, bật bằng `CYS_PERF_REDRAW=1`, không bao giờ port. Công cụ: `Tools/perf/diag/guiredraw_watch.py`.
   - **Nguồn thật:** ở màn đăng nhập, 6.567/6.624 lần ghi (99 %) đi qua `FalagardButton::updateSelf` → `Window::setAlpha(1)` → `onAlphaChanged` → `requestRedraw` — mọi nút đang hiện đặt lại alpha 1 mỗi khung (`btnalpha`). Sau đó R3 chỉ ra ở màn chọn/tạo còn `FalagardStopWatch::updateSelf` đặt lại chữ mỗi khung khi đồng hồ đứng, và con trỏ ô nhập liệu nháy cả khi không được vẽ (`uiredraw2`). Các nguồn khác đều theo sự kiện (nạp layout, smoke bấm nút, tooltip, `FreeUnuseImageset` mỗi 6 s).
   - **Sau ba bản sửa** (R4, cặp E → G): `uirebuild` 0,00–0,03, `uidraw` 0,02–0,06 ms, cấp phát mỗi khung giảm ~10 lần.
   - Chi phí trước sửa: `uidraw` 0,85–1,4 ms và ~2.160 cấp phát (161 KB) mỗi khung ở màn đăng nhập; 0,2–0,6 ms ở màn chọn và màn tạo.
3. **Màn tạo tốn CPU ở `draw` và `cull`.**
   - 1.090–1.150 draw call, ~5–5,7 µs mỗi cái trên CPU: pass, auto-param, hằng số, trạng thái.
   - 37–40 nghìn thanh ghi hằng số VS mỗi khung.
   - `cull` 2,4–3,6 ms, trong đó `anim` 0,7–1,0 ms cho ~85 entity có animation; 2–5 entity mỗi khung bị skin bằng CPU.
   - Ở 60 fps (16,7 ms), màn tạo 1080p còn dư ít nếu máy đang bận.
4. **Phần `render` không nằm trong pha cảnh nào** (tìm ánh sáng, begin/end, clear, vv.): ~1,2 ms bên trong `targets`, và ~1,7 ms ở phía Game ngoài `renderOneFrame`.
5. **Khung giật sau khi nạp xong** (B-1024, các khung >40 ms trong đoạn đứng yên):
   - **Do smoke:** thao tác và chụp PNG, gồm cả `HeapValidate` trong `CysOfflineUiCapture.h`, tốn 196–461 ms. Chỉ có trong lượt test.
   - **Khoảng trống không pha nào đo được:** tới ~195 ms. Nhiều khả năng do máy đang tải nặng hoặc bộ lập lịch; runner nay ghi mức tranh chấp.
   - **GPU khung 50–100 ms khi texture hoặc resource dùng lần đầu:** `targets` 100–120 ms, trong khi các pha cảnh chỉ 10–20 ms.
   - **Một lần `ctrl` 77 ms:** cập nhật hạt/controller.
   - **Một lần `uidraw` 35 ms:** rasterize glyph FreeType.
   - **Chuỗi vài khung `draw` 37–52 ms:** nghi dùng lần đầu shader/texture. Bộ đếm `texload` và `shadercreate` (counters2) được thêm để quy trách nhiệm cho các khung này.

## 6. Kiểm tra các nghi phạm thường gặp

| Nghi phạm | Kết quả | Bằng chứng |
|---|---|---|
| Cấu hình build (CRT debug, tối ưu, assert, iterator debugging) | Không phải. Game.exe của người dùng là build CI `ci-x64` `Release` (`/O2 /Ob2 /DNDEBUG`, `/MD`). Import `MSVCP140.dll` / `VCRUNTIME140.dll`, không có bản `…D`. Src giữa 91148e1 và HEAD giống nhau. | `Build/cmake/ci-x64/CMakeCache.txt`, `llvm-objdump -p` |
| Tạo thiết bị D3D9 | Không phải. HAL, xử lý đỉnh phần cứng, không PURE, không FPU_PRESERVE, không MULTITHREADED. Back buffer X8R8G8B8, 1 bộ đệm, DISCARD, `PresentationInterval=IMMEDIATE` (VSync tắt theo `View_Aplomb=0`), không MSAA, depth D24S8, cửa sổ. | dòng `CYS-PERF device:` trong `WXRender.log` |
| Bộ giới hạn khung / Sleep | **Có, đây là nguyên nhân chính.** Xem mục 1 và 5.1. | `GameProcedure.cpp` `InitStaticMemeber`; `Average FPS: 30.34` |
| Biên dịch shader lúc chạy | Không phải khi chạy ổn định. Game cài `CYS::MaterialSystem` với `.\ShaderCache` trước khi parse script. OgreSmoke 209/0 hit/miss. Lần đầu dùng một biến thể mới vẫn có thể biên dịch; bộ đếm `shadercreate` được thêm. | dòng `CYS material: shader cache` |
| Log phình mỗi khung | Không. `WXRender.log` / `UISystem.log` / `WXClient.log` giữ nguyên 51 s liền khi đứng yên. Dòng `CYS-PERF` chỉ có khi bật đo. | `game/B0-user-1024/logsize.csv` |
| Chẩn đoán của ChatGPT còn bật | Không, với lượt chạy thường. Smoke, chụp ảnh và `HeapValidate` chỉ bật khi có `-cys-gl-login-smoke` hoặc `CYS_*_SMOKE`. `Run-CY-Test.cmd` xoá các biến này. | grep `HeapValidate` / `MiniDumpWriteDump` / `StackWalk64` |
| CEGUI vẽ lại mọi cửa sổ, rasterize lại glyph | **Có**: vẽ lại toàn bộ mỗi khung (mục 5.2). Nguồn chính là `Falagard/Button` gọi `setAlpha(1)` mỗi khung (sửa `btnalpha`); ở màn chọn và màn tạo có thêm `Falagard/StopWatch` (sửa `uiredraw2`). Có một lần rasterize glyph 35 ms, không lặp lại. | bộ đếm `uirebuild`, `uidraw`; watchpoint `CYS-GUIREDRAW` |
| Skinning bằng CPU, animation của entity không hiện | Một phần. 2–5 entity mỗi khung ở màn tạo và 13 ở S01 bị skin bằng CPU. OGRE 1.2 chỉ cập nhật animation của entity được vẽ; `_updateAnimation` từ ngoài bằng 0 trong các cảnh đã đo. | bộ đếm `swskin`, `animext` |
| Tạo hoặc clone texture/material mỗi khung | Không. Số material/texture/mesh không tăng khi đứng yên (`+0` mỗi chu kỳ). Cấp phát khi đứng yên: 9–76 mỗi khung ở viewer, 136–500 ở Game (chủ yếu do GUI). | dòng `CYS-PERF scene:` |
| Quota hạt khổng lồ | Có dữ liệu với quota lớn (暴风骤雨 16.600), nhưng vẫn >280 fps. Chi phí nằm ở dựng billboard trên CPU. Thuộc fx-particles. | viewer fx06 |
| Scene manager | Là `OctreeSceneManager` (biên dịch vào OgreMain và đăng ký qua `StartOctreeSceneManager`), giống B dùng `Plugin_OctreeSceneManager.dll`. | dòng `CYS-PERF install: scene_manager=OctreeSceneManager(FairyMainScene)` |

## 7. Các bản sửa và số trước/sau

Mỗi bản sửa là một thay đổi có thể commit riêng, có marker riêng trong mã (`CYS-PERF-FIX <tên>`), và được đo riêng.

### 7.1 `pacer`: nhịp khung theo B

- **Tệp:** `Src/Client/WXClient/Procedure/GameProcedure.cpp`.
- **Khởi tạo** (`InitStaticMemeber`):
  - đọc `System_MaxFPS_Front` / `System_MaxFPS_Back`; nếu thiếu khoá thì mặc định 60/25, còn giá trị ngoài 5–240 thì kẹp lại trong khoảng đó;
  - thay event 0.85 bằng một waitable timer độ phân giải cao (`CREATE_WAITABLE_TIMER_HIGH_RESOLUTION`, Windows 10 1803 trở lên; nếu không có thì dùng timer thường cộng `timeBeginPeriod(1)`).
- **Mỗi khung** (`MainLoop`): hẹn mốc tiếp theo bằng mốc trước cộng một chu kỳ, theo `m_bActive` (Front hoặc Back). Nếu đã trễ quá một chu kỳ thì bắt đầu lại từ bây giờ, không dồn khung bù.
- **Log:** `CYS-PERF pacer: front 60 fps, back 30 fps (System_MaxFPS_Front/Back), high-resolution waitable timer`.
- **Hoàn tác:** `CYS_PERF_PACER=legacy`.
- **Lưu ý cho người dùng:** client_GL đặt `System_MaxFPS_Front=90`. Người dùng có thể đặt 90 để mượt hơn nếu CPU đủ.

Kết quả lượt B (pacer), 1024×768, cùng kịch bản với A:

| Đoạn | A: fps / p95 / max / >50 ms | B: fps / p95 / max / >50 ms |
|---|---|---|
| Đăng nhập, đứng yên | 30,3 / 47,0 / 63,4 / 11 | **59,9 / 19,6 / 41,3 / 0** |
| Chọn, đang dựng | 30,3 / 46,8 / 71,1 / 6 | **60,0 / 17,4 / 33,2 / 0** |
| Chọn, đã dựng | 30,3 / 46,6 / 87,9 / 4 | **59,7 / 18,5 / 58,9 / 1** |
| Tạo, lần 2, đứng yên (65 s) | 30,4 / 46,4 / 47,2 / 0 (4 s) | **58,3 / 23,2 / 109,3 / 6** |

Ở 1920×1080 (B): đăng nhập 59,8 fps (p95 22,5, max 48,2, 0 khung >50 ms); chọn đã dựng 59,4 fps (p95 22,0, max 45,4, 0 khung >50 ms).

Trong lượt B-1080, hai đoạn cuối về 30 fps vì cửa sổ mất tiêu điểm: một cửa sổ khác trên máy dùng chung chiếm tiêu điểm, và pacer chuyển sang `Back=30` đúng như thiết kế. Từ đó runner ghi mốc `app-active`/`app-inactive`, và các lượt so sánh đặt `System_MaxFPS_Back=60`.

**Cặp so sánh cuối cùng** (A → B → C → D chạy liền nhau, cùng máy, cùng kịch bản): xem mục 7.6.

### 7.2 `uiredraw`: GUI chỉ dựng lại khi có thay đổi

- **Tệp:** `Src/Client/CEGUIFalagardEx/FalagardLoginWidgets.cpp`, `FalagardChatEditBox.cpp`, `FalagardAnimate.cpp`.
- **Thay đổi:**
  - `setImage` / `requestRedraw` chỉ được gọi khi khung ảnh hoặc độ trong suốt đổi, và chỉ khi cửa sổ đang hiện. Khi cửa sổ hiện ra, CEGUI tự vẽ lại.
  - Ô chat bị ẩn không còn ép dựng lại GUI; ô chat đang hiện vẫn vẽ như cũ.
- Hình ảnh không đổi: vẫn khung ảnh đó, vẫn độ trong suốt đó.
- **Kết quả (F-C so với F-B): một mình chưa đủ.** `uirebuild` vẫn 1,00 mỗi khung ở cả bốn trạng thái; cấp phát ở màn đăng nhập vẫn 2.158 mỗi khung. Ba widget này là nguồn thật, nhưng nguồn chính là `Falagard/Button` (mục 7.3).
- `uiredraw` vẫn cần: không có nó, ảnh động màn đăng nhập vẫn ép dựng lại mỗi khung sau khi `btnalpha` đã sửa.

### 7.3 `btnalpha` và `uiredraw2`: nguồn thật của việc dựng lại GUI mỗi khung

- **Tìm ra bằng** watchpoint phần cứng trên `System::d_gui_redraw` (mục 5.2).
- **`btnalpha`**, tệp `Src/ThirdParty/CEGUI-0.4.1/CEGUI/WidgetSets/Falagard/src/FalButton.cpp`, hàm `FalagardButton::updateSelf`:
  - nút bình thường chỉ gọi `setAlpha(1)` khi alpha đang khác 1;
  - nút nhấp nháy (`Flash`) chỉ gọi `setAlpha` khi giá trị mới khác giá trị cũ;
  - nút có hoạt ảnh (`BtnAnimation`) chỉ `requestRedraw()` khi khung ảnh hoặc alpha của hoạt ảnh đổi.
- **`uiredraw2`**, tệp `Src/Client/CEGUIFalagardEx/FalStopWatch.cpp` và `FalIMEEditBox.cpp`:
  - đồng hồ đứng (`Timer` bằng 0 hoặc −1) chỉ `setText` khi chữ khác; `setText` tự yêu cầu vẽ lại;
  - con trỏ nháy chỉ yêu cầu vẽ lại khi ô đang hiện và có tiêu điểm, vì chỉ lúc đó con trỏ được vẽ.
- Cùng giá trị, cùng hình: các bản sửa chỉ bỏ những lần đặt lại y hệt.
- **Kết quả R3** (1024×768, `btnalpha`, watchpoint bật), màn đăng nhập đứng yên: `uirebuild` 1,00 → 0,03 mỗi khung; `uidraw` 1,0–1,3 → 0,18 ms; cấp phát 2.158 → 78 mỗi khung. Màn chọn và màn tạo vẫn 1,00 vì `StopWatch`, nên mới có `uiredraw2`.
- **Kết quả R4** (thêm `uiredraw2`, watchpoint bật): `uirebuild` xuống 0,00–0,05 ở cả bốn trạng thái; watchpoint chỉ còn ghi các nguồn theo sự kiện (nạp layout, smoke bấm nút, tooltip), không còn nguồn mỗi khung.
- **Cặp E → G ở 1920×1080** (E = D + phần phụ của collector, không có hai bản sửa này; G = E + `btnalpha` + `uiredraw2`; chạy liền nhau; bản gốc `Build/Logs/2026-09-13-perf/final-btnalpha-1080-table.md`):

| Trạng thái | `uirebuild` E → G | `uidraw` ms E → G | cấp phát/khung E → G |
|---|---|---|---|
| Chọn, đã dựng | 1,00 → **0,00** | 0,16 → **0,02** | 136 → **22** |
| Chọn lần 2 | 1,00 → **0,00** | 0,18 → **0,02** | 136 → **23** |
| Tạo, đứng yên | 1,00 → **0,03** | 0,46 → **0,06** | 356 → **32** |

  Cả hai lượt đạt 59,6–60,3 fps ở mọi trạng thái ổn định (pacer đã đưa lên trần 60 từ trước; hai bản sửa này cắt việc dựng lại vô ích, không cắt thời gian khung). Ích lợi thật là: đúng như B, ~10 lần ít cấp phát hơn mỗi khung, và `uidraw` gần như bằng 0. Vài khung >50 ms còn lại ở cả E và G là do nạp texture lần đầu (mục 5.5), không phải GUI.

### 7.4 `psconst`: gộp hằng số pixel shader

- **Tệp:** `Src/Engine/OGRE/RenderSystems/Direct3D9/src/OgreD3D9RenderSystem.cpp`, trong `bindGpuProgramParameters`.
- OGRE 1.2 gọi `SetPixelShaderConstantF(index, v, 1)` cho từng thanh ghi. Nay các thanh ghi liền nhau được đẩy trong một lần gọi, giống nhánh VS sẵn có. Cùng thanh ghi, cùng giá trị.
- Bộ đếm `psc` đếm số lần gọi, cả trước lẫn sau sửa.
- **Kết quả (F-D so với F-C, 1080p):** số lần gọi đẩy hằng số PS mỗi khung giảm từ 5.481 xuống 726 ở màn chọn và từ 8.068 xuống 1.046 ở màn tạo, tức −87 %.
- Hình ảnh cùng bước smoke (`create-male-default`) của hai lượt giống nhau về ánh sáng, màu và model; chỉ lá rơi và đom đóm lệch vị trí do thời điểm.
- Chạy đủ kịch bản: PASS Preview, 0 lỗi UI, 0 socket.
- Thời gian CPU không tách được vì nhiễu: lúc chạy có 10,8–13,2 tiến trình biên dịch của agent khác.

### 7.6 Bảng so sánh cuối

Các lượt F chạy liền nhau, cùng máy, cùng kịch bản offline, 210 s mỗi lượt:

| Lượt | Nhị phân |
|---|---|
| A | trước sửa |
| B | + `pacer` |
| C | + `uiredraw` + counters2 |
| D | + `psconst` |

B, C, D chạy với `System_MaxFPS_Back=60`. Cột "biên dịch nền" là số tiến trình `cl/link/ninja` của agent khác trung bình trong lượt. Nhiễu này chủ yếu đẩy p95/p99 lên ở C và D. Bảng sinh bằng `Tools/perf/compare_runs.py`; bản gốc ở `Build/Logs/2026-09-13-perf/final-1080-table.md`.

**1920×1080** (fps / p95 / p99 / max ms / số khung >50 ms / CPU bận ms):

| Trạng thái | A (trước) | B (pacer) | C (+uiredraw) | D (+psconst) |
|---|---|---|---|---|
| Đăng nhập, đứng yên | 30,3 / 46,5 / 48,7 / 58,2 / 2 / 2,1 | **60,0 / 17,1 / 19,1 / 30,1 / 0** / 1,5 | 60,0 / 19,0 / 29,6 / 39,6 / 0 / 2,4 | 59,9 / 26,5 / 39,1 / 47,8 / 0 / 4,1 |
| Chọn, đã dựng | 30,3 / 46,5 / 47,1 / 48,2 / 0 / 5,1 | **60,0 / 17,1 / 19,1 / 27,4 / 0** / 5,7 | 59,9 / 18,0 / 24,9 / 47,6 / 0 / 6,5 | 59,4 / 25,2 / 38,7 / 44,7 / 0 / 9,1 |
| Chọn lần 2, đứng yên | 29,4 / 46,7 / 124,4 / 216,4 / 14 / 8,6 | **60,0 / 17,2 / 21,6 / 26,8 / 0** / 6,2 | 59,4 / 27,0 / 37,0 / 51,6 / 1 / 9,1 | 59,3 / 25,9 / 37,7 / 47,2 / 0 / 9,8 |
| Tạo, đứng yên | 30,2 / 46,1 / 47,3 / 203,6 / 13 / 8,4 | **59,7 / 23,5 / 29,8 / 60,7 / 2** / 9,1 | 59,2 / 27,5 / 37,2 / 57,1 / 1 / 11,6 | 59,7 / 20,6 / 33,8 / 89,9 / 1 / 8,8 |
| Biên dịch nền (trung bình) | 0,0 | 5,0 | 13,2 | 10,8 |

Bộ đếm, cùng cho bốn lượt trừ khi ghi khác:

| Trạng thái | draw call | hằng số VS | `psc` (C → D) | uirebuild | cấp phát/khung | GPU |
|---|---|---|---|---|---|---|
| Tạo nhân vật | 1.149 | 39,6 nghìn thanh ghi | 8.068 → 1.046 | 1,00 | 356 | 4,1–5,2 ms |
| Chọn nhân vật | 687 | – | 5.481 → 726 | – | – | – |

`uirebuild` là 1,00 ở A–D vì các bản sửa GUI (`btnalpha`, `uiredraw2`) chỉ có từ biến thể G trở đi; cặp E → G ở mục 7.3 cho thấy nó xuống 0,00–0,03.

**Đọc bảng:**
- `pacer` là bước quyết định: mọi trạng thái từ 30 fps lên 59,3–60 fps, và số khung >50 ms từ 2–14 xuống 0–2.
- C và D không đổi fps. p95/p99 của chúng cao hơn B vì lúc chạy máy có 11–13 tiến trình biên dịch (so với 5 ở B), không phải do bản sửa: CPU bận thay đổi theo đúng mức nhiễu.
- Khung >50 ms còn lại ở màn tạo khi đứng yên (1–2 khung trong ~65 s) cần đo lại khi máy rảnh.

**1024×768** (A và D chạy liền nhau; bản gốc ở `Build/Logs/2026-09-13-perf/final-1024-table.md`):

| Trạng thái | A (trước) | D (pacer + uiredraw + psconst) | GPU A → D ms | `psc` D |
|---|---|---|---|---|
| Đăng nhập, đứng yên | 30,3 / 47,5 / 55,0 / 62,0 / 10 / 4,4 | **59,9 / 19,0 / 33,6 / 39,6 / 0** / 2,4 | 0,64 → 0,53 | 0 |
| Chọn, đã dựng | 30,3 / 47,2 / 52,8 / 67,9 / 7 / 8,9 | **60,0 / 17,1 / 19,5 / 22,6 / 0** / 5,9 | 3,73 → 2,40 | 632 |
| Chọn lần 2, đứng yên | 30,3 / 46,5 / 48,4 / 63,5 / 5 / 7,2 | **60,0 / 17,2 / 20,6 / 43,3 / 0** / 5,8 | 3,33 → 2,21 | 632 |
| Tạo, đứng yên | 30,3 / 46,8 / 52,2 / 65,3 / 28 / 9,8 | **59,7 / 18,5 / 26,4 / 47,0 / 0** / 8,5 | 4,96 → 4,02 | 985 |
| Biên dịch nền (trung bình) | 7,7 | 4,3 | | |

- Ở 1024×768 cả bốn trạng thái đạt mục tiêu: 59,7–60 fps và **0 khung >50 ms** sau khi nạp xong.
- Trước sửa, 5–28 khung >50 ms mỗi trạng thái.
- A không có bộ đếm `psc` (bộ đếm này thêm ở counters2).
- CPU bận và GPU thấp hơn ở D, nhưng lượt D cũng chạy lúc máy ít tiến trình nền hơn (4,3 so với 7,7), nên không quy hết cho `psconst`.

## 8. Việc còn lại và người phụ trách

| Việc | Bằng chứng | Người phụ trách | Đề xuất |
|---|---|---|---|
| Nạp model xem trước môn phái khi bấm nút ở màn tạo nhân vật: khung tới 245–500 ms | đoạn "Tạo, smoke thao tác", `max` 245–500 ms | game-layer (UI tạo nhân vật) | nạp trước 30 model 4950–4979 khi vào cảnh, hoặc nạp nền |
| Texture/resource dùng lần đầu gây GPU 50–100 ms | `targets` 100–120 ms, `gpu_frame` 100 ms | fx-render (MaterialSystem) cùng perf | `PreLoad`/prefetch texture của cảnh; làm ấm shader biến thể |
| Một lần `ctrl` 77 ms; dựng billboard trên CPU 1,6–1,8 ms với 16,6 nghìn quota | B-1024 khung 6977; viewer fx06 | fx-particles | xem lại cập nhật hệ hạt khi bắt đầu hoặc bước thời gian lớn; giới hạn quota thời tiết. (Hai điểm agent hạt tìm ra — tra map SequenceFrame và timeout không nhìn thấy — đã sửa: mục 7.5) |
| 2–13 entity mỗi khung skin bằng CPU | bộ đếm `swskin` (tạo 2–5, S01 13) | fx-render (ghép VS có `includes_skeletal_animation`) | ghi danh mesh/material bị skin CPU (có thể thêm log một lần mỗi entity) |
| Rasterize glyph FreeType 35 ms lần đầu | `uidraw` 35 ms một lần | UI / perf | làm ấm atlas glyph khi nạp. Việc dựng lại GUI mỗi khung đã sửa (`btnalpha`, `uiredraw2`, mục 7.3). Trong thế giới, ô chat đang hiện vẫn vẽ lại theo nhịp con trỏ — chấp nhận được |
| CPU mỗi draw call ~5 µs, 37–40 nghìn thanh ghi VS mỗi khung | pha `draw`, bộ đếm `vsc` | perf (việc tiếp theo) | chỉ đẩy phần hằng số đổi, lọc declaration/stream thừa |
| Khoảng trống không pha nào đo được (tới 195 ms) khi máy đang tải | B-1024 khung 6765 | vận hành | đo lại khi máy rảnh; runner đã ghi số tiến trình biên dịch |
| `CYSCommon.cmake` | build đã là Release `/O2` | — | không đề xuất đổi. `/GL` (LTCG) hoặc `/arch:AVX2` chỉ nên thử khi có số đo |

## 9. Lệnh chạy lại và bẫy

```powershell
# build cây perf (bản export HEAD + móc/sửa), tối đa 4 luồng
cmd /c C:\TLBB\085\CY-Source\Tools\perf\build_perf.cmd export
# cài biến thể vào stage perf (không bao giờ đụng stage của người dùng)
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\perf\stage_perf.ps1 -Variant D -From Build\perf\variants\D
# Game offline (smoke Preview, không socket), 1080p, Back=60 để mất tiêu điểm không làm sai số
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\perf\run_game_perf.ps1 -Tag D-1080 -Seconds 210 -Width 1920 -Height 1080 -Set System_MaxFPS_Back=60
# viewer và OgreSmoke
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\perf\run_viewer_perf.ps1 -Tag D -Cases 'S01,S07,S09,S10,E087'
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\perf\run_ogresmoke_perf.ps1 -Tag D
# bảng
python -B Tools\perf\perf_report.py Build\Logs\2026-09-13-perf\game\D-1080\frames.csv --settle 2
python -B Tools\perf\viewer_table.py Build\Logs\2026-09-13-perf\viewer\D

# áp các bản sửa vào một cây Src (đọc lại từng tệp ngay trước khi sửa, giữ BOM/CRLF, đếm mỏ neo)
python -B Tools\perf\apply_perf_fixes.py Src pacer uiredraw counters2 psconst btnalpha uiredraw2 seqframe nonvis
python -B Tests\perf\test_patchers.py            # 2/2 pass trên bản HEAD

# chẩn đoán nguồn dựng lại GUI (chỉ cây perf riêng, không bao giờ port); rồi chạy Game với CYS_PERF_REDRAW=1
python -B Tools\perf\diag\guiredraw_watch.py Build\perf\src\Src
cmd /c Tools\perf\build_perf.cmd export cys_ceguibase

# bench chi phí CPU hệ hạt (200 hệ) trong một cây perf
cmd /c Tools\perf\build_particle_bench.cmd main
Build\cmake\perf-main-x64\bin\CYSParticleBench.exe --label test --out Build\Logs\2026-09-13-perf\particle-bench.tsv
```

**Bẫy:**
- **`powershell -File` không nhận chuỗi rỗng.** Để tắt tham số, dùng `-Hold none`.
- **Process bị kill không ghi dòng `Average FPS` của OGRE.** Hãy dùng CSV. Collector flush CSV sau mỗi chu kỳ.
- **Lượt viewer rất ngắn** (900 khung, khoảng 1 s). Settle theo giây sẽ rỗng, nên phải bỏ theo số khung (`--skip-frames 60`). Khung 0 chứa toàn bộ phần khởi tạo.
- **Mất tiêu điểm thì pacer chuyển sang `System_MaxFPS_Back`.** Máy dùng chung hay có cửa sổ khác chiếm tiêu điểm. Khi so sánh, đặt `Back` bằng `Front`.
- **Smoke chụp ảnh** (kể cả `HeapValidate`) tạo khung 200–460 ms. Đó là việc của test, không phải của game (pha `harness`).
- **Thời gian CPU phụ thuộc tải máy.** So sánh chỉ khi hai lượt chạy liền nhau và cột `compilers` trong `logsize.csv` gần 0.
- **Heredoc Bash làm hỏng chuỗi Python có `\r\n`.** Viết script ra tệp rồi mới chạy (đúng như `08-BAY-VA-QUY-TAC_vi.md` 9.4).
