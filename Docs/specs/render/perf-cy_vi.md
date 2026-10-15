# perf-cy — Độ mượt: CY 3.71 so với CY-Source

Ngày 15/09/2026. Người làm: agent perf-cy (Claude). Nhánh `perf-cy`, worktree `Build/wt-perf-cy`.
Bằng chứng: `Build/Logs/2026-09-15-perf-cy/`. RE (Ghidra, chỉ đọc, trên bản sao): `Build/re/perf-cy/out/`.

Chỉ thị người dùng (15/09): "Chú trọng vào render bản đồ, bối cảnh, nhân vật, hiệu ứng,... phải thật mượt, phải thật đẹp. CY
gốc làm rất tốt, nếu ta chưa giống là ta chưa phân tích kỹ cách CY làm."

Tài liệu nối tiếp `09-performance_vi.md` (nhịp khung 60 fps, `CYS_PERF`). Ở đây: **giật** (khung dài bất thường), nguyên
nhân từng khung, cách CY làm, và các bản sửa có số đo trước/sau.

## 1. Tóm tắt

| Mục | Kết quả |
|---|---|
| Nguồn giật số 1 trong world đứng yên / xoay camera / đi bộ / đánh quái | Lua full GC mỗi 3 s chặn luồng chính 32-45 ms. CY làm mỗi 10 s. **Đã sửa `luagc` (7efde694)**: khung >33 ms 21-23 → 9-11 mỗi lượt, stutter 17-20 → 6-8 |
| Khung đứng 0,8-1,0 s khi nhặt đồ; 120-280 ms khi vào world | Sự kiện UI nạp dồn hàng trăm layout cửa sổ đang ẩn: 0.85 bỏ qua cờ `RegisterEvent(ev, false)` của script CY. **Đã sửa `uievent` (09c31bd3)**: `OBJECT_CARED_EVENT` 800-1019 → 61-64 ms, khung dài nhất trong world 205-823 → 164-172 ms, sd khung 4,8-17,2 → 3,4-3,8 ms |
| Dựng cảnh dần | CY: 64 vật khung đầu rồi **30 vật/giây** theo thời gian; 0.85: 1 vật/khung. **Đã sửa `scenebuild` (9a1bf53c)** — số đo ở mục 6.3 |
| Bóng vật tĩnh (d3d9-trace) làm world nặng | Main bật đổ bóng vật tĩnh như CY: lệnh vẽ 1.416 → 2.846, CPU render +2,4 ms, GPU +4,7 ms, p99 +3..+6 ms. CY giữ chi phí thấp nhờ **cắt StaticEntity theo khoảng cách camera** (`SceneConfig EnableCamDisCull`, Đại Lý: 4000 / ×14 bán kính) mà 0.85 bỏ qua. **Đã sửa `camdiscull` (35e94688, số đo da77a265)**: lệnh vẽ 2.846 → 1.668, CPU 15,1 → 12,8 ms, GPU 13,1 → 10,7 ms, p99 25,6-28,5 → 23,2-24,5 ms |
| So với CY world (probe, cùng máy) | CY: p50 16,0, p95 18,0-18,1, p99 19,8-20,2 ms, 8 khung >33 ms / 63 s, CPU luồng vẽ 4,9 ms, 834-853 lệnh vẽ. Dự án (C): p95 18,6-19,1, p99 23,2-24,5 ms, 10 khung >33 ms / ~50 s, CPU render 12,8 ms, 1.668 lệnh vẽ. **Số giật gần ngang CY; chi phí CPU mỗi khung vẫn ~2,5 lần** (mục 8) |
| VSync | CY mặc định `D3DPRESENT_INTERVAL_ONE` + 2 back buffer + cap 45 fps. Chưa đổi mặc định dự án (mục 7) |
| Nhịp khung | CY: `timeSetEvent(int(1000/fps), 1 ms, event, TIME_PERIODIC)` + `MsgWaitForMultipleObjects`. Dự án: waitable timer độ phân giải cao (09-performance). Tương đương khi đứng yên: p50 CY 15,97-15,98 ms (62,5 fps do làm tròn 16 ms) / dự án 16,63-16,67 ms |

## 2. Cách đo

- **Máy dùng chung:** Xeon E5-2696 v3, RTX 2060, màn 2560×1440 @ 59 Hz; 6-10 agent khác biên dịch/chạy viewer cùng lúc. Mỗi lượt
  ghi tải máy (`load.csv`: CPU tổng, GPU 3D, số `cl/link/ninja`, số Game.exe, 3 tiến trình bận nhất) bằng `Tools/perf/sample_load.ps1`.
  Hai lượt có Game.exe thứ hai của agent khác chạy song song (`gcA-2`, `ueA-2`, `games>1` trong `load.csv`); `ueA-2` lệch rõ
  (khung >33 ms = 154) nên không dùng để kết luận.
- **Cùng một đồng hồ cho CY và dự án:** `Tools/perf/present_probe` — `d3d9.dll` proxy (chỉ bản sao/stage của perf-cy):
  thời điểm mọi `IDirect3DDevice9::Present` (QPC), thời gian trong Present, chu kỳ CPU của luồng vẽ và của các luồng khác
  (`QueryThreadCycleTime`/`QueryProcessCycleTime`, quy đổi 2,27·10⁶ chu kỳ/ms đo từ khoảng nạp bận 100 %), số lệnh vẽ và
  `Create*` giữa hai Present, tham số `CreateDevice`/`Reset`. Bảng: `Tools/perf/probe_table.py`.
- **Quy nguyên nhân (chỉ dự án):** `CYS_PERF=1` + `CYS_PERF_CSV`; `Tools/perf/hitch_report.py` chia đoạn theo mốc của driver replay
  và gán mỗi khung >33,4 ms cho pha tự thân lớn nhất. Khung chụp PNG (`shot:*`) và khung kế tiếp bị loại khỏi thống kê.
  Log chẩn đoán kèm theo (chỉ khi `CYS_PERF=1`): `CYS-PERF slow packet|event` (`WXClient.log`), `slow window|load`
  (`UISystem.log`), `slow texture` (`WXRender.log`).
- **Kịch bản dự án** (`Tools/perf/run_world_perf.ps1`, 0 socket, ≤150 s): replay `-Move -Core -Camera` trên stage
  `stage_game.py build --data CanonicalCY` → đăng nhập → chọn nhân vật → vào Đại Lý `dali_new_320` → kịch bản camera →
  **xoay camera 360° liên tục 8 s** (`CYS_PERF_SPIN`) → 3 click đi bộ → đánh quái 3 đòn có impact, nhặt đồ, chat, túi.
  1280×720 cửa sổ, `System_MaxFPS_Front/Back = 60/60`, `View_Aplomb = 0` (cấu hình người dùng).
  Đoạn: `enter` (10 s đầu trong world), `idle`, `spin`, `walk`, `core`, `world-all`.
- **Kịch bản CY** (`Tools/perf/run_cy_probe.ps1` → `Tools/render/run_cy_capture.ps1`): bản sao riêng
  `Build/re/perf-cy/CYGame` (Bin/Bin64 chép, `Data` là junction tới bản sao color-calib), màn đăng nhập 3D, 120 s, 0 kết nối
  game. Cấu hình: `default` = CY gốc (45/25 fps, VSync bật; Back đặt 45 để mất tiêu điểm không đổi nhịp), `nov60`
  (60/60, VSync tắt), `vs60` (60/60, VSync bật). CY chưa vào được world offline (agent cy-oracle) nên chỉ so màn đăng nhập.
- **A/B:** mỗi bản sửa có công tắc môi trường trong cùng binary (`CYS_PERF_LUAGC_MS`, `CYS_PERF_UIEVENT=legacy`,
  `CYS_PERF_SCENEBUILD=legacy`), chạy xen kẽ A/B/A/B/A/B.
- Phân vị: hạng gần nhất `sorted[round(q·(n−1))]`. Stutter = khung > 2 × trung vị 30 khung trước và dài hơn trung vị ≥ 4 ms.

## 3. CY 3.71 làm gì (FACT từ RE, chỉ đọc)

| Mảng | CY 3.71 | 0.85 / dự án | Nguồn |
|---|---|---|---|
| Nhịp khung | `System_MaxFPS_Front/Back` kẹp [5,150] (ngoài khoảng → 30); `View_GaoZhenLv=1` → 60 fps; hai `timeSetEvent(int(1000/fps), 1, event, 0x11)`; vòng lặp `MsgWaitForMultipleObjects` trên sự kiện Front khi cửa sổ active, Back khi không | 0.85: `timeSetEvent(33,33)` (lưới 15,6 ms). Dự án: waitable timer độ phân giải cao, hạn tuyệt đối (`pacer`) | Game.exe `FUN_14061e270`, `FUN_1406218a0`, `FUN_140620710`; `out/g1_imports.txt`, `g2_strs.txt` |
| Present | `CreateDevice`: back buffer 2, `SwapEffect=DISCARD`, `PresentationInterval=ONE` khi `View_Aplomb=1` (mặc định CY), `IMMEDIATE` khi 0 (1 back buffer); HAL, HW vertex processing (0x40), D24S8 | Dự án: cùng quy tắc (`OgreD3D9RenderWindow`: VSync → 2 BB), nhưng cấu hình người dùng `View_Aplomb=0` | probe `cy/login-*/probe_*.txt`; d3d9-trace `diff-login-1` |
| Lua GC | `lua_setgcthreshold(L, 0)` khi `CalSubTime(last, now) > 9999` → **10 s** | 3 s (`COLLECT_TIME = 3*1000`) | `FUN_140684df0`, `out/g3_gc.txt` |
| Sự kiện UI | `this:RegisterEvent("EV", bLoad)` lưu cờ theo tên (item +0x1c8), không đăng ký trùng; `_OnGameEvent` bỏ sự kiện `bLoad=false` khi cửa sổ ẩn (+0x160) — không nạp layout, không chạy script. Script CY truyền `false` 7.005 lần, `true` 1.699 lần | bỏ qua tham số 3: mọi sự kiện nạp layout | UI_CEGUI `FUN_180079300`, RegisterEvent (`Build/re/login-polish/out/u_onevent.txt`, `u_onload.txt`) |
| Dựng cảnh dần | `IncrementalSceneBuilder` (còn `Fairy_Hack`): khung đầu 64 vật, sau đó ngân sách `+= 30 × timeSinceLastFrame` (30 vật/giây). Có thêm lưới quanh camera (khoảng cách 300) và huỷ `StaticEntity` xa theo `Distance Cull` | 1 vật/khung, tìm vật gần nhất O(N) mỗi vật | Render.dll ctor `FUN_1800876d0`, `frameStarted` `FUN_18008b4f0`; `out/r4_builder.txt` |
| Hạt | `ParticleBackGroundManager`: **4 luồng** cập nhật hạt (`ParticleSystemManager::SystemUpdate(i)`), ghi vào 4 vertex buffer phần mềm; luồng chính `NotifyUpdateParticle(camera)` rồi `WaitForMainThreadRender` và đổi sang 4 buffer phần cứng dùng chung (`MergeParticleSystem`, queue 8); log `OpenBackGroundParticleSystem` | cập nhật hạt trên luồng chính | OgreMain `StartThread` 0x18011c130, `Run`, `WaitForMainThreadRender`; `out/o2_particle.txt`, `o3_pbg.txt` |
| Nạp file | `Fairy::MemLoadManager` + `MemLoadThread`: đọc `filedep.xml` (MainFile → DepFile), đọc trước file phụ thuộc vào bộ nhớ ở luồng nền, `swapData` mỗi khung đưa sang luồng chính; đếm `LoadResNum Total/MainThread/BackThread`. Có cả trong Render.dll của client 0.85 và client_GL | Nguồn dự án (bản WX cũ) không có | Render.dll `FUN_1800b92b0`, `FUN_1800b70f0`, `FUN_1800b95c0`; `out/r1_strs.txt`, `r2_memload.txt` |
| Model logic | thuộc tính scene `LogicModelBackgroundLoad` ("resource is loaded by background thread"); `Gfx_SkeletonPreload` bật khi RAM > 320 MB; `View_InsteadModel` (model thay thế) | không có | Render.dll `FUN_180129690`, `FUN_18002f190`; Game.exe `FUN_1405c7730` |
| Shader cache | `Bin64/ShaderCache`: 396 tệp ghi ở lượt chạy đầu, các lượt sau không ghi thêm | `CYS::MaterialSystem` + `ShaderCache` (09-performance) | `Build/re/perf-cy/CYGame/Bin64/ShaderCache` |

## 4. CY 3.71 màn đăng nhập (probe, 1280×720)

Cửa sổ đo = sau khoảng nạp cuối (> 1 s) + 3 s tới hết lượt (84-96 s).

Cột: `present_ms` = trung vị thời gian trong Present; `main/other_cpu_ms` = trung vị CPU luồng vẽ / các luồng khác; `o33/o50` = số khung > 33/50 ms.

| run | size | vsync | bb | seconds | frames | fps | p50 | p95 | p99 | max | sd | o33 | o50 | stut | present_ms | main_cpu_ms | other_cpu_ms | draws |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| login-default-1 | 1280x720 | on | 2 | 36.4 | 773 | 21.2 | 45.57 | 53.72 | 56.28 | 88.8 | 4.59 | 773 | 191 | 0 | 30.74 | 14.98 | 10.59 | 2062 |
| login-default-3 | 1280x720 | on | 2 | 95.6 | 2296 | 24.0 | 42.01 | 44.23 | 45.87 | 83.4 | 4.43 | 2222 | 9 | 0 | 30.6 | 11.6 | 8.28 | 2062 |
| login-nov60-1 | 1280x720 | off | 1 | 87.0 | 4526 | 52.0 | 19.05 | 24.06 | 27.36 | 82.5 | 4.05 | 17 | 9 | 12 | 0.59 | 18.42 | 11.42 | 2062 |
| login-nov60-2 | 1280x720 | off | 1 | 92.9 | 5786 | 62.3 | 15.98 | 17.65 | 19.75 | 65.8 | 2.01 | 9 | 9 | 9 | 0.45 | 12.04 | 7.59 | 2062 |
| login-nov60-2b | 1280x720 | off | 1 | 92.5 | 5759 | 62.2 | 15.97 | 17.86 | 20.3 | 57.2 | 1.94 | 9 | 8 | 9 | 0.42 | 10.59 | 7.14 | 2062 |
| login-nov60-3 | 1280x720 | off | 1 | 94.1 | 5871 | 62.4 | 15.98 | 17.85 | 19.19 | 60.1 | 1.96 | 9 | 9 | 9 | 0.41 | 10.42 | 7.07 | 2062 |
| login-vs60-1 | 1280x720 | on | 2 | 84.2 | 1883 | 22.4 | 43.9 | 50.68 | 53.99 | 105.4 | 3.65 | 1883 | 112 | 1 | 30.69 | 13.35 | 9.34 | 2062 |
| login-vs60-2 | 1280x720 | on | 2 | 92.9 | 2689 | 28.9 | 43.05 | 45.56 | 47.39 | 88.6 | 13.29 | 1756 | 15 | 2 | 30.31 | 12.81 | 8.69 | 2062 |

Nhận xét:
- VSync tắt, 60 fps: CY giữ p50 15,97-15,98 ms, p95 17,7-17,9 ms, p99 19,2-20,3 ms; luồng chính ~10,4-12 ms CPU/khung (2.062 lệnh vẽ), các luồng khác 7-7,6 ms (luồng hạt, âm thanh).
- **CY cũng giật định kỳ:** mỗi 10,0 s một khung 57-82 ms, toàn bộ là CPU luồng chính (65-80 ms chu kỳ) — trùng chu kỳ Lua GC 10 s ở trên.
  9 khung >33 ms mỗi 90 s.
- VSync bật (`default`, `vs60`) trên máy dùng chung này: CY chỉ 21-29 fps, `Present` chặn ~30 ms. Đây là môi trường
  (DWM + GPU bị chia); không dùng để đánh giá mặc định VSync (mục 7).
- `nov60-1` (14 trình biên dịch song song) lệch: p50 19,05 ms.

### 4.1 CY 3.71 world Đại Lý (probe qua cy-oracle)

`Build/Logs/2026-09-15-perf-cy/cy_world.ps1` → `Tools/cyoracle/run_cy_oracle.ps1` trên bản sao riêng (LoginServer về 127.0.0.1
bằng `make_loginserver.py`, `Patch/RemoteAddr.txt` Login_IP=127.0.0.1 và `ClientType.cfg NewStopSend_V2=0` như bản sao
cy-oracle — thiếu hai tệp này CY mở kết nối web cổng 80 sau khi vào game và lượt bị dừng). Kịch bản `dali.json`: đứng
quảng trường, skill +10 s, dịch chuyển +20/+32 s. Cửa sổ đo = sau khoảng nạp cuối + 3 s. 1280×720, cap 60/60, VSync tắt.
Oracle chưa dựng model nhân vật (theo cy-oracle), nên số lệnh vẽ của CY thiếu phần nhân vật.

| run | size | vsync | bb | seconds | frames | fps | p50 | p95 | p99 | max | sd | o33 | o50 | stut | present_ms | main_cpu_ms | other_cpu_ms | draws |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| world-nov60-2 | 1280x720 | off | 1 | 64.8 | 4037 | 62.3 | 16.01 | 17.99 | 19.79 | 79.0 | 2.44 | 8 | 7 | 8 | 0.45 | 4.9 | 3.43 | 850 |
| world-nov60-3 | 1280x720 | off | 1 | 60.9 | 3796 | 62.3 | 16.0 | 18.13 | 20.15 | 82.7 | 2.61 | 8 | 7 | 8 | 0.45 | 4.96 | 3.45 | 834 |
| world-nov60-4 | 1280x720 | off | 1 | 65.3 | 4066 | 62.3 | 15.97 | 17.96 | 20.12 | 81.9 | 2.54 | 8 | 7 | 8 | 0.45 | 4.93 | 3.47 | 853 |

- 6/8 khung >33 ms là GC Lua 10 s (54-60 ms, toàn CPU luồng chính); 2 khung là tạo texture/VB khi dịch chuyển (42-79 ms).
- Bóng CY world (d3d9-trace `cy_shadow_casters.tsv`): một map 4096² R32F; caster 306 / 709 / 703 ở w09 / w28 / w42.

### 4.2 Dự án màn đăng nhập cùng cấu hình (lgn-1/2/3, stage-fix5-perfcy, `CYS_PERF_LOGIN_HOLD_MS=30000`)

Đoạn `login` của `hitch_report.py` (khung CYS_PERF), 1280×720, 60/60, VSync tắt, ~30 s mỗi lượt:

| Lượt | fps | p50 | p95 | p99 | max | sd | >33 | stutter | lệnh vẽ trung bình / p95 | CPU render trung bình / p95 |
|---|---|---|---|---|---|---|---|---|---|---|
| lgn-1 | 58,1 | 16,70 | 19,26 | 25,54 | 237,4 | 6,23 | 7 | 6 | 1.502 / 2.455 | 12,4 / 18,9 ms |
| lgn-2 | 58,9 | 16,70 | 19,19 | 24,46 | 47,4 | 1,96 | 4 | 4 | 1.500 / 2.454 | 11,7 / 18,9 ms |
| lgn-3 | 58,8 | 16,68 | 19,14 | 25,28 | 53,6 | 2,09 | 5 | 5 | 1.495 / 2.440 | 11,9 / 18,8 ms |

- So CY cùng cảnh `erengu_DL`: CY p95 17,7-17,9 và p99 19,2-20,3 ms, 9 khung >33 ms / 90 s. Dự án có p95 19,1-19,3, p99 24,5-25,5 ms và 4-7 khung / 30 s.
- Nguồn khung giật: GC 10 s (27-32 ms), cảnh đăng nhập đang dựng dần (892 vật trong 30 s; một khung build 204 ms ở lgn-1), hạt 45-92 ms (một lần ở lgn-1), draw 23 ms.
- Lệnh vẽ dao động 1.500 → 2.455 (p95) nên CPU render p95 18,9 ms, trong khi CY giữ 2.062 lệnh vẽ đều.
- VSync bật (lvs-1): p95 18,58, p99 23,68 ms, `Present` 4,5 ms. Máy dùng chung chưa cho thấy lợi ích.

## 5. Dự án: world Đại Lý trước khi sửa

Lượt `base-warm` (stage `stage-base-perfcy`, HEAD 858b6bef + móc đo) và các lượt A của A/B.

| Nguồn giật | Dấu hiệu | Tần suất | Ghi chú |
|---|---|---|---|
| Lua full GC | pha `script` 32-45 ms | mỗi 3,0 s | 16-18 khung/lượt; chiếm hầu hết khung >33 ms ở idle/spin/walk/core |
| Sự kiện UI nạp dồn layout | pha `events` 800-1019 ms, ~1,07 triệu cấp phát | khi nhặt đồ (`OBJECT_CARED_EVENT`, 352 listener), `UNIT_LEVEL` 119 ms, `PLAYER_ENTERING_WORLD` 235-276 ms, `SCENE_TRANSED` 561-636 ms | kéo theo cả gói `GCCharEquipment` (1194) 330 ms |
| Khung vào world | khung đầu 245 ms: `cull` 65 + `build` 43 (64 vật) + `events` 51 + 52 texture | một lần | CY che bằng màn nạp |
| Texture dùng lần đầu | `draw` 25-43 ms, `texload` 5-6 | vài lần/lượt | |
| Dựng cảnh dần | `build` 20-31 ms | 1-2 lần/lượt; trung bình 0,32-0,42 ms/khung, p99 2,8-3,1 ms | builder chạy suốt lượt (~3.000 vật) |
| Rasterize glyph / UI | `uidraw` 16-31 ms | hiếm | |

Chi phí khung ổn định (world, sau 10 s): CPU `render` 10,5-12,9 ms (`draw` 5,7-6,8, `cull` 3,2-4,1), `tick` 0,7-1,2 ms,
GPU 6,9-8,0 ms; luồng vẽ theo probe 10,6-13,4 ms CPU/khung — ngang CY ở màn đăng nhập (10,4-12 ms).

## 6. Các bản sửa (mỗi bản một commit, số đo A/B xen kẽ 3 lượt)

### 6.1 `luagc` — 7efde694

- `Src/Client/WXClient/Script/GMScriptSystm.cpp` `CScriptSystem::Tick`: chu kỳ 10 s như CY; `CYS_PERF_LUAGC_MS` để A/B.

| Đoạn (world replay) | A = 3 s (gcA-1/2/3) | B = 10 s (gcB-1/2/3) |
|---|---|---|
| world-all khung >33 ms | 22 / 21 / 23 | 9 / 11 / 10 |
| world-all khung >50 ms | 18 / 18 / 19 | 9 / 9 / 8 |
| world-all stutter | 18 / 17 / 20 | 6 / 8 / 7 |
| world-all p99 (ms) | 24,9 / 29,2 / 27,1 | 21,5 / 23,6 / 22,6 |
| idle khung >33 ms | 3 / 3 / 3 | 1 / 1 / 1 |
| spin khung >33 ms | 2 / 4 / 4 | 1 / 1 / 1 |
| walk khung >33 ms | 2 / 2 / 3 | 1 / 1 / 1 |

### 6.2 `uievent` — 09c31bd3

- `Src/Client/CEGUISystem/UIWindowMng.{h,cpp}`: `LUA_RegisterEvent` đọc tham số 3, lưu `m_cysEventLoad`, không đăng ký trùng;
  `_OnGameEvent` bỏ sự kiện `false` khi cửa sổ ẩn. `CYS_PERF_UIEVENT=legacy` để A/B.

| Chỉ số | A = legacy (ueA-1/3; ueA-2 bị Game.exe thứ hai) | B = như CY (ueB-1/2/3) |
|---|---|---|
| `OBJECT_CARED_EVENT` khi nhặt đồ | 800 / 1019 / 911 ms | 61 / 64 / 62 ms |
| `UNIT_LEVEL` vào world | 119 ms | 17 ms |
| `PLAYER_ENTERING_WORLD` | 235 / 261 / 276 ms | 142 / 155 / 158 ms |
| `SCENE_TRANSED` | 561 / 621 / 636 ms | 461 / 500 / 502 ms |
| world-all khung dài nhất | 823 / 223 / 205 ms | 164 / 164 / 172 ms |
| world-all sd khung | 17,2 / 9,0 / 4,8 ms | 3,4 / 3,8 / 3,7 ms |
| core khung dài nhất | 823 / 103 / 62 ms | 76 / 80 / 77 ms |
| world-all p99 | 21,8 / 55,0 / 26,0 ms | 21,8 / 24,1 / 22,3 ms |

### 6.3 `scenebuild` — 9a1bf53c

- `Src/Engine/WXCore/Core/WXSceneInfo.cpp`: ngân sách thời gian như CY; `CYS_PERF_SCENEBUILD=legacy` để A/B.

| Chỉ số (world, sau vào cảnh 1 s) | A = legacy (sbA-1/2/3) | B = như CY (sbB-1/2/3) |
|---|---|---|
| scene-build trung bình | 0,40 / 0,32 / 0,31 ms | 0,24 / 0,19 / 0,19 ms |
| scene-build lớn nhất | 16,4 / 15,4 / 15,1 ms | 10,1 / 9,7 / 9,9 ms |
| khung có build > 10 ms | 2 / 1 / 2 | 1 / 0 / 0 |
| số vật dựng trong lượt | 3.079 / 3.152 / 3.006 | 1.595 / 1.601 / 1.582 |
| world-all p99 | 22,9 / 23,5 / 21,1 ms | 21,5 / 19,5 / 19,0 ms |
| world-all khung >33 ms | 10 / 11 / 10 | 9 / 9 / 9 |
| world-all stutter | 9 / 10 / 9 | 7 / 8 / 8 |

Cảnh sẽ đầy chậm hơn (30 vật/giây như CY). Với `camdiscull` (6.4), vật xa không còn nằm trong hàng đợi dựng.

### 6.4 `camdiscull` — 35e94688 (số đo da77a265), đường dựng tức thì 34f28ef7

- FACT RE (Render.dll): `SceneConfig` `EnableCamDisCull` / `SetCamDisCullDepth` (giữ khi 100 < depth < 10000) /
  `SetCamDisCullParam` (> 0) → System +0x148 / +0x150, +0x154 = depth² / +0x14c (`FUN_180133a20`, setter `FUN_180134cb0`,
  `FUN_180134cf0`, `FUN_180134d20`); mỗi vật +0x148 = `Entity::getBoundingRadius() × param`, +0x14c = bình phương
  (`FUN_1800bc880`); `IncrementalSceneBuilder::frameStarted` (`FUN_18008b4f0`) chỉ tạo StaticEntity trong depth và huỷ vật đã tạo
  khi dist² > max(depth², (r × param)²) (vật có `Distance Cull` = false thì không cắt). `dali_new_320`: bật, 4000, 14.
- Cài (`WXSceneInfo.cpp`): hoãn tạo StaticEntity ngoài depth; mỗi khung duyệt ≤ 512 vật đã tạo, ẩn/hiện `Entity` theo luật trên.
  **Khác CY (INF, chủ ý):** ẩn thay vì huỷ/tạo lại, để quay lại không phải nạp lại mesh. Đường dựng tức thì (TlbbViewer) cũng
  áp luật ẩn. `CYS_PERF_CAMDISCULL=0` để A/B. Log `CYS-PERF camdiscull:` (cấu hình + created/hidden/pending mỗi 10 s).
- Đo (stage-cdc-perfcy = main 612463fa + camdiscull; sau vào cảnh 10 s, bỏ khung chụp; A = không bóng vật tĩnh,
  B = bóng như main, C = B + camdiscull):

| run | frames | p50 | p95 | p99 | >33 | stut | draws | cpu render | cull | draw | anim | gpu frame | gpu rtt | built | hidden |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| cA-1 | 2488 | 16.64 | 19.76 | 25.72 | 15 | 19 | 1413 | 12.98 | 3.72 | 7.66 | 0.10 | 8.51 | 8.05 | 1276 | - |
| cA-2 | 2387 | 16.66 | 18.22 | 22.34 | 8 | 9 | 1380 | 12.29 | 3.51 | 7.28 | 0.09 | 8.22 | 7.83 | 1207 | - |
| cA-3 | 2607 | 16.68 | 19.54 | 25.29 | 11 | 13 | 1454 | 12.72 | 3.63 | 7.48 | 0.10 | 8.38 | 7.98 | 1330 | - |
| cB-1 | 2390 | 16.81 | 21.71 | 27.65 | 9 | 9 | 2854 | 15.29 | 4.10 | 9.67 | 0.10 | 13.09 | 12.81 | 1263 | - |
| cB-2 | 2420 | 16.91 | 22.81 | 28.50 | 9 | 9 | 2874 | 15.49 | 4.19 | 9.77 | 0.10 | 13.45 | 13.12 | 1300 | - |
| cB-3 | 2457 | 16.69 | 20.27 | 25.60 | 8 | 9 | 2810 | 14.64 | 3.97 | 9.23 | 0.09 | 12.61 | 12.32 | 1267 | - |
| cC-1 | 2342 | 16.68 | 18.87 | 23.73 | 10 | 11 | 1680 | 12.83 | 3.44 | 7.64 | 0.06 | 10.88 | 10.56 | 669 | created=917 hidden=511 pending=4745 |
| cC-2 | 2474 | 16.68 | 18.63 | 23.22 | 10 | 11 | 1658 | 12.70 | 3.41 | 7.59 | 0.06 | 10.55 | 10.18 | 697 | created=944 hidden=580 pending=4718 |
| cC-3 | 2464 | 16.68 | 19.12 | 24.52 | 10 | 11 | 1668 | 12.79 | 3.44 | 7.66 | 0.06 | 10.57 | 10.26 | 683 | created=931 hidden=594 pending=4731 |

Đo lại trên main mới (stage-m2-perfcy = main 643964c0: map bóng đơn 4096, fit tight), B = `CYS_PERF_CAMDISCULL=0`,
C = mặc định, xen kẽ 3 lượt. m2B-3, m2C-2 và m2C-3 chạy lúc máy bận (CPU tổng 12-24 % so với 7-9 %, 3-7 trình biên dịch),
nên dùng cặp sạch m2B-1/2 và m2C-1 để kết luận:

| run | frames | p50 | p95 | p99 | >33 | stut | draws | cpu render | cull | draw | anim | gpu frame | gpu rtt | built | hidden |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| m2B-1 | 2309 | 16.93 | 22.34 | 27.38 | 8 | 9 | 2276 | 14.73 | 3.56 | 9.56 | 0.11 | 11.82 | 11.51 | 1238 | - |
| m2B-2 | 2614 | 16.70 | 19.62 | 24.97 | 9 | 10 | 2424 | 13.36 | 3.11 | 8.83 | 0.10 | 10.73 | 10.51 | 1340 | - |
| m2B-3 | 2073 | 18.19 | 28.85 | 34.71 | 29 | 18 | 2295 | 17.46 | 4.35 | 11.14 | 0.15 | 13.70 | 13.39 | 1230 | - |
| m2C-1 | 2667 | 16.66 | 17.25 | 22.17 | 10 | 11 | 1395 | 10.98 | 2.48 | 6.97 | 0.06 | 8.82 | 8.55 | 750 | created=998 hidden=631 pending=4664 |
| m2C-2 | 2387 | 16.66 | 18.61 | 24.30 | 9 | 10 | 1402 | 12.90 | 3.09 | 7.90 | 0.07 | 9.88 | 9.58 | 704 | created=952 hidden=543 pending=4710 |
| m2C-3 | 2238 | 16.71 | 21.95 | 29.49 | 13 | 12 | 1331 | 13.90 | 3.39 | 8.41 | 0.08 | 10.79 | 10.41 | 648 | created=898 hidden=544 pending=4764 |

- C so với B (lượt sạch): lệnh vẽ 2.276-2.424 → 1.395, CPU render 13,4-14,7 → 11,0 ms, GPU 10,7-11,8 → 8,8 ms, p95 19,6-22,3 → 17,3 ms.
- **Hồi quy mới từ bóng vật tĩnh (có ở cả B và C, và ở cC-1 trên main 612463fa):**
  - khung đầu vào world có `cull` 190-264 ms (fix5, trước bóng vật tĩnh: 60 ms);
  - khi xoay camera có 4 khung `cull` 25-70 ms, lúc vật mới lọt khung nhìn;
  - nghi phạm (INF): lần đầu phân giải biến thể material/caster trong hook render-queue của `CysMaterialSystem`. Log của TlbbViewer ghi `first resolutions 706 calls, 670 ms` (~0,95 ms mỗi lần). Đó là việc 'làm nóng biến thể material trước khi vào cảnh' ở mục 8.

Caster ở đúng camera của trace CY world (d3d9-trace `cy-world-1-trace` w09/w28/w42). Phía dự án là TlbbViewer bản perf-cy
(main 643964c0: map đơn 4096, fit tight) + proxy d3d9-trace, khung 230. Phân loại theo luật của `cy_casters.py`, tính bằng
`Build/Logs/2026-09-15-perf-cy/casters_cat.py`. Bằng chứng ở `viewer-v1/`.

| Camera | CY 3.71 | Dự án camdiscull tắt | Dự án camdiscull bật | CY tĩnh / alpha / skin / địa hình | Dự án bật: tĩnh / alpha / skin / địa hình |
|---|---|---|---|---|---|
| w09 (9 s sau vào cảnh) | 306 | 1.785 | 1.009 | 181 / 76 / 9 / 40 | 728 / 254 / 27 / 0 |
| w28 (8 s sau dịch chuyển 1) | 709 | 1.882 | 1.064 | 484 / 143 / 38 / 44 | 792 / 227 / 45 / 0 |
| w42 (10 s sau dịch chuyển 2) | 703 | 1.559 | 835 | 480 / 160 / 21 / 42 | 594 / 206 / 35 / 0 |

Đọc bảng:
- camdiscull giảm caster 43-46 % ở cả ba camera.
- Phần chênh còn lại so với CY chủ yếu do CY đang dựng dần (suy luận). Mỗi khung CY, `IncrementalSceneBuilder` chỉ có 64 vật + 30 vật/giây, nên ở w09 CY mới dựng khoảng 330 vật quanh camera. TlbbViewer thì dựng toàn cảnh ngay. w42 là khung CY đã dựng lâu nhất; tại đó dự án chỉ còn hơn CY 19 %.
- Địa hình của CY cũng đổ bóng (40-44 lệnh), dự án thì 0. Việc này thuộc d3d9-trace.
- Chưa làm: lưới ô quanh camera của builder CY (+0x50..+0x5c, bước ô +0x38/+0x40 × +0x44, hằng +0x68 = 300). Có thể nó cắt thêm; cần RE tiếp.

### 6.5 `prewarm` — 6f49d0b0 (hồi quy giật do bóng vật tĩnh)

**Nguyên nhân (đo trước khi sửa).** Bộ đếm mới CYS_PERF C3 (`casterbuild/caster_us`, `variantbuild/variant_us`,
`matload/matload_us` trong `frames.csv`) và log `CYS_PERF_VARLOG=1` cho từng biến thể material. Lượt c3diag-1 / varlog-1:

| Khung | cull | Biến thể material dựng trong khung | Material::load | Caster bóng dựng |
|---|---|---|---|---|
| khung đầu world (64 vật khởi động) | 204 ms | 414 (37 ms), 397 là `Terrain/dali_new_320/*` | 852 (125 ms) | 18 (0,6 ms) |
| đổi góc camera (kịch bản camera) | 23-45 ms | 93-190 (9-18 ms), 100 % `Terrain/*` | 189-383 (0,2-0,5 ms) | 0 |

- Caster bóng không phải nguyên nhân. Nguyên nhân là **ô địa hình dựng hình lười**: `TerrainTileOptimized::_updateRenderQueue` chỉ tạo VB và grid material khi ô lọt khung nhìn lần đầu.
- Mỗi grid material mới lại qua `CYS::MaterialSystem::resolveTechnique`, clone biến thể khoảng 0,13 ms/cái ngay trong render queue.
- Cả lượt có 1.642 biến thể `Terrain/dali_new_320`.
- Bóng vật tĩnh chỉ làm lộ vấn đề (thêm pass, đổi khung), không phải gốc.

**CY làm gì.** FACT, probe `cy/world-nov60-2/3`: mọi VS/PS của cảnh được tạo trong hai khung nạp chặn (1,5 s + 1,2 s, 94 + 77 texture). Sau khung nạp cuối **0 shader** được tạo.
- CY vẫn tạo VB/IB khi dựng dần: 890-956 VB trong 64-68 s. Nên việc dựng hình địa hình trong khung nạp là lựa chọn của dự án (INF), không phải bằng chứng CY.

**Sửa.** `Terrain::cysPrewarm()` được gọi sau `buildGeometry` cuối cùng trong `CRenderSystem::Scene_Load` và `Scene_SetLightmapQuality`, tức mọi lần vào/đổi cảnh.
- `createGeometry` cho mọi ô.
- `touch` + `getBestTechnique` + `resolveTechnique` cho mọi grid material.
- `SceneInfo::initialise` còn dựng hình một lần trước đó; gọi prewarm ở đó làm gấp đôi việc, nên đã bỏ.
- `CYS_PERF_PREWARM=0` để A/B. Log: `CYS-PERF prewarm: terrain '<cảnh>' tiles N (geometry ... ms), grid materials M (resolved ... ms)`. Đại Lý: 100 ô, 157-215 ms; 1.757 material, 327-735 ms tuỳ tải máy.

**Số đo** (stage-pw2-perfcy, A = `CYS_PERF_PREWARM=0`, B = mặc định):
- Ba cặp đầu chạy thứ tự A → B, hai cặp sau đảo B → A.
- Cột cuối là tải máy. pwA-5 và pwB-2 chạy lúc máy bận: CPU 26-30 %, 7 trình biên dịch.

| run | enter: 1st world frame ms / cull | load frame ms | world p50 | p95 | p99 | >33 | stut | spin cull>16 / max | world cull>16 / max | variants in world (ms) | CPU render | GPU | cpu_total% / compilers |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| pwA-1 | 325 / 205 | 1199 | 16.66 | 17.32 | 21.87 | 10 | 9 | 0 / 11.6 | 4 / 205.0 | 1757 (168) | 10.39 | 8.19 | 9 / 1.8 |
| pwA-2 | 324 / 202 | 1242 | 16.67 | 17.40 | 22.82 | 13 | 11 | 0 / 10.3 | 4 / 201.8 | 1770 (168) | 11.18 | 9.02 | 8 / 0.0 |
| pwA-3 | 335 / 212 | 1239 | 16.67 | 18.23 | 26.18 | 17 | 16 | 0 / 11.8 | 4 / 212.4 | 1732 (174) | 12.85 | 10.31 | 11 / 6.4 |
| pwA-4 | 360 / 235 | 1352 | 16.66 | 18.29 | 26.23 | 11 | 10 | 0 / 14.7 | 4 / 235.2 | 1791 (197) | 12.46 | 9.44 | 14 / 0.0 |
| pwA-5 | 631 / 343 | 1933 | 17.05 | 29.00 | 37.34 | 44 | 18 | 3 / 17.6 | 8 / 342.8 | 1736 (266) | 17.48 | 13.31 | 30 / 7.4 |
| pwB-1 | 147 / 23 | 1673 | 16.68 | 18.71 | 23.86 | 11 | 9 | 0 / 5.6 | 1 / 23.1 | 122 (17) | 12.16 | 9.69 | 8 / 0.0 |
| pwB-2 | 211 / 26 | 2024 | 16.75 | 24.38 | 29.04 | 10 | 6 | 0 / 7.4 | 1 / 25.8 | 114 (22) | 15.20 | 11.59 | 26 / 7.0 |
| pwB-3 | 148 / 24 | 1766 | 16.66 | 18.26 | 23.14 | 11 | 9 | 0 / 4.9 | 1 / 23.8 | 116 (17) | 12.01 | 9.46 | 11 / 3.5 |
| pwB-4 | 217 / 29 | 1900 | 16.68 | 17.78 | 22.65 | 8 | 7 | 0 / 4.5 | 1 / 28.9 | 113 (17) | 12.10 | 9.54 | 11 / 0.4 |
| pwB-5 | 154 / 24 | 1759 | 16.67 | 17.36 | 22.55 | 11 | 8 | 0 / 4.5 | 1 / 24.4 | 122 (19) | 11.71 | 9.21 | 18 / 0.0 |

Chi phí world ổn định (sau vào cảnh 10 s, bỏ khung chụp):

| run | frames | p50 | p95 | p99 | >33 | stut | draws | cpu render | cull | draw | anim | gpu frame | gpu rtt | built | hidden |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| pwA-1 | 2366 | 16.66 | 17.33 | 21.37 | 8 | 9 | 1352 | 10.39 | 2.38 | 6.52 | 0.05 | 8.19 | 7.90 | 687 | created=934 hidden=577 pending=4728 |
| pwA-2 | 2465 | 16.67 | 17.43 | 22.75 | 10 | 11 | 1392 | 11.18 | 2.56 | 7.03 | 0.06 | 9.02 | 8.71 | 680 | created=926 hidden=588 pending=4736 |
| pwA-3 | 2672 | 16.67 | 18.30 | 25.77 | 14 | 16 | 1392 | 12.85 | 2.95 | 7.96 | 0.07 | 10.31 | 9.89 | 733 | created=980 hidden=615 pending=4682 |
| pwA-4 | 2348 | 16.66 | 18.44 | 26.23 | 9 | 10 | 1377 | 12.46 | 2.92 | 7.72 | 0.07 | 9.44 | 9.17 | 684 | created=933 hidden=596 pending=4729 |
| pwA-5 | 2021 | 17.63 | 29.82 | 38.32 | 41 | 18 | 1371 | 17.48 | 4.18 | 10.74 | 0.09 | 13.31 | 12.92 | 710 | created=963 hidden=552 pending=4699 |
| pwB-1 | 2393 | 16.69 | 19.04 | 23.86 | 8 | 9 | 1397 | 12.16 | 2.78 | 7.62 | 0.07 | 9.69 | 9.34 | 700 | created=949 hidden=609 pending=4713 |
| pwB-2 | 2197 | 16.82 | 25.10 | 29.32 | 7 | 6 | 1364 | 15.20 | 3.63 | 9.33 | 0.08 | 11.59 | 11.21 | 675 | created=925 hidden=567 pending=4737 |
| pwB-3 | 2438 | 16.67 | 18.40 | 22.66 | 8 | 9 | 1381 | 12.01 | 2.71 | 7.58 | 0.06 | 9.46 | 9.16 | 685 | created=932 hidden=572 pending=4730 |
| pwB-4 | 2328 | 16.68 | 18.04 | 22.90 | 6 | 7 | 1389 | 12.10 | 2.74 | 7.59 | 0.07 | 9.54 | 9.29 | 678 | created=926 hidden=520 pending=4736 |
| pwB-5 | 2384 | 16.67 | 17.37 | 22.66 | 7 | 8 | 1386 | 11.71 | 2.69 | 7.25 | 0.06 | 9.21 | 8.86 | 687 | created=935 hidden=572 pending=4727 |

- **Khung đầu world:** A 324-360 ms (cull 202-235 ms) → B 147-217 ms (cull 23-29 ms). **DoD cull ≤ 60 ms: đạt.** CY khung đầu world 1.222 ms (probe).
- **Xoay 360°:** khung cull > 16 ms = 0 ở cả A và B (lượt yên), cull lớn nhất A 10-15 ms → B 4,5-7,4 ms. **DoD: đạt.**
  - Cả world: khung cull > 16 ms A 4 → B 1; khung còn lại là khung đầu world, 23-29 ms.
- **Biến thể dựng trong world:** 1.732-1.791 (168-197 ms) → 113-122 (17-22 ms).
- **p95 world:** lượt yên A 17,32 / 17,40 / 18,29 ms, B 17,36 / 17,78 / 18,26 ms. Cùng khoảng nhiễu, không có dấu hiệu tệ hơn.
  - pwB-1: 18,71 ms, CPU tổng 8 %. Mọi pha của nó (tick, fstart, uidraw, present) cùng chậm 15-20 %, không riêng pha nào → INF: dao động máy.
  - **DoD p95 ≤ 17,3 ms:** lượt tốt nhất B 17,36 ms, ngang lượt tốt nhất A 17,32 ms.
- **Giá phải trả — khung nạp cảnh dài thêm:** A 1.199-1.352 ms → B 1.673-2.024 ms (lượt yên +470-550 ms). CY nạp Đại Lý bằng hai khung 1,5 + 1,2 s.
  - Màn đăng nhập / chọn nhân vật cũng prewarm: `erengu_DL` 202 material 102-422 ms, `tl3chuangjian` 102 material 46-835 ms (lần đầu nạp template).
- d3d9-trace sắp gộp brush địa hình thành 1 texture ('Terrain/<cảnh>/1.0', '1.1'). Số grid material sẽ giảm mạnh nên giá prewarm cũng giảm. `cysPrewarm` duyệt `Terrain::mMaterials` tổng quát. Nếu brush gộp được tạo sau `Scene_Load` thì phải gọi lại `cysPrewarm()` ở cuối `_postprocessScene`; đã nhắn d3d9-trace.

### 6.6 Phân rã CPU mỗi khung: CY so với dự án (bộ lấy mẫu trong probe, 1280×720, cap 60)

Công cụ: `present_probe` với `CYS_PROBE_SAMPLE=1` (81e20d76):
- mỗi 4 ms dừng luồng vẽ, chép 64 KB ngăn xếp, `RtlVirtualUnwind` trên bản chép;
- `Tools/perf/sample_profile.py DIR [--focus hàm]`: ký hiệu PDB khi PE timestamp khớp, CY theo export gần nhất (`~`).

| Nhóm (ms mỗi khung, luồng vẽ) | CY world `cy/world-smp-3` | Dự án main + L5 `world/smp4-1.perf` |
|---|---|---|
| CPU luồng vẽ (median, chu kỳ) | **6,28** | **8,66** (máy đang biên dịch) |
| Render tổng | ~5,7 | 8,0 |
| Compositor / RT phụ (depth, bóng) | 3,6 | 1,97 (`preRenderTargetUpdate`) |
| Cây octree / tìm vật thấy | 0,9 | 1,75 (`walkOctree`, trong đó `_addToRenderQueue` 1,45) |
| Vẽ từng renderable | 1,56 (`SceneRenderProxy::renderPass`) | 2,1 (`renderSingleObject`) + `_setPass` 0,85 + texture unit 0,53 |
| CEGUI `renderGUI` | 0,33 (module CEGUI tổng 0,35) | 1,0 (module CEGUI tổng 1,35; `uirebuild`=1 mỗi khung, ~718 quad) |
| Controllers / frameStarted | 0,65 / 0,53 | — |
| Tick logic | — | 0,62 |
| Harness chụp PNG (`CysWorldReplay` Shot, windowscodecs) | — | 0,8-0,9 (chỉ trong replay) |

- FACT: chênh thật sau L5 khoảng **1,3-1,4 lần**, không phải 2,5 lần (số 2,5 là trước L5 / camdiscull).
- FACT: CY OgreMain vẽ bằng `SceneRenderProxy::setPass/renderPass` và `RenderPriorityGroup::_fillVertexIndexData` (bộ vẽ gộp khác OGRE 1.2).

### 6.7 `texname` + `queue` — 0029a35d (A/B chưa vượt nhiễu)

- `texname`: `TextureUnitState::getContentTextureName` dựng chuỗi (`StringConverter::toString` = ostringstream) mỗi lần `_setPass`. Nay cache theo content type + MRT; `CYS_PERF_TEXNAME=legacy` tắt.
- `queue`: `QueuedRenderableCollection::clear/acceptVisitorGrouped` duyệt cả map pass group (hàng nghìn pass từng queue). Nay chỉ duyệt nhóm đã dùng từ lần clear trước, sắp theo `PassGroupLess`; `CYS_PERF_QUEUE=legacy` tắt.
- A/B xen kẽ 3 cặp (stage-tq-perfcy, A = cả hai legacy):

| run | p50 | p95 | p99 | draws | CPU render | cull | draw | GPU frame | CPU luồng vẽ (probe) |
|---|---|---|---|---|---|---|---|---|---|
| tqA-1 | 16.66 | 17.14 | 17.52 | 864 | 6.85 | 1.56 | 3.63 | 4.60 | 6.97 |
| tqA-2 (máy bận) | 16.64 | 26.86 | 53.47 | 867 | 11.04 | 2.31 | 5.26 | 7.35 | 9.21 |
| tqA-3 | 16.66 | 17.15 | 17.61 | 875 | 6.75 | 1.54 | 3.59 | 4.73 | 6.75 |
| tqB-1 | 16.68 | 17.16 | 17.50 | 885 | 6.26 | 1.42 | 3.27 | 4.24 | 6.37 |
| tqB-2 | 16.66 | 17.14 | 18.44 | 847 | 7.13 | 1.61 | 3.65 | 4.71 | 7.44 |
| tqB-3 | 16.67 | 17.15 | 17.54 | 883 | 6.56 | 1.50 | 3.40 | 4.45 | 6.79 |

- Kết luận: B nhỉnh hơn A 0,1-0,3 ms CPU render ở các lượt yên, nhưng dao động giữa lượt cùng cấu hình ±0,5 ms (GPU frame lệch theo cùng chiều → tải máy). **DoD "vượt nhiễu": chưa đạt.** p95 bị VSync/cap 60 ghim ở 17,1-17,2 ms nên không phân biệt được.
- Hình: không đổi (chỉ bỏ việc lặp; thứ tự visit giữ đúng thứ tự map). Cặp có lấy mẫu để đo phần trăm hàm (tqsA/tqsB) chưa chạy vì dừng theo lệnh.

### 6.8 `fogvariant` — 04c1ff99 (hồi quy sương địa hình do `prewarm`)

Triệu chứng (d3d9-trace): PS địa hình Game.exe `5201f4e2` không có `fog_colour/fog_params`; CY và viewer `7f401886`.

Nguyên nhân (FACT, trace màn đăng nhập, cùng stage trước sửa):
- `Terrain::cysPrewarm` resolve biến thể của grid material (shadow receiver `FairyTerrainColorMap`) ngay sau `buildGeometry`.
- Lúc đó `Terrain::mCurrentFogMode` còn `FOG_NONE`; `_updateMaterials` chỉ đổi chương trình sang `%fog_linear` khi ô đầu tiên được queue.
- Biến thể là bản sao; `followSource` theo màu/blend/hằng, không theo tên chương trình → biến thể giữ PS không sương.

Sửa:
- `cysPrewarm` gọi `_cysSyncFogMode(fog mode của scene manager)` trước khi resolve. Enviroment object đặt fog khi tạo vật cảnh, trước đoạn này.
- Lưới an toàn: `MaterialVariantResolver::forgetMaterial` (mặc định rỗng). `CYS::MaterialSystem` bỏ biến thể của material khi fog mode đổi về sau, giữ sống 2 khung vì render queue khung hiện tại có thể còn trỏ technique cũ.

| Lượt (Build/Logs/2026-09-15-perf-cy/fog) | Build | PS địa hình màn đăng nhập | Khung đầu world Đại Lý: cull | Cull >16 ms khi xoay |
|---|---|---|---|---|
| lg-tq1 / tq-p1 | trước sửa, prewarm bật | **5201f4e2 ×36, không sương** | 2,2 ms | 0 |
| lg-tq0 / tq-p0 | trước sửa, `CYS_PERF_PREWARM=0` | 7f401886 ×36, có sương | 125 ms | 0 |
| lg-fg / fg-1, fg-2 | sau sửa, prewarm bật | **7f401886 ×36, có sương** | **1,9-2,3 ms** | 0 |

- Đại Lý world không tái hiện (PS địa hình `c8eaf13b`/`2fe658e4` có sương ở cả 3 bản) — INF: cảnh trước đó đã có sương.
- DoD: hash 7f401886 trong Game.exe, khung đầu world cull ≤ 60 ms — **đạt**.

## 7. VSync (đề xuất, chưa đổi mặc định)

- FACT: CY mặc định `View_Aplomb=1` → `PresentationInterval ONE`, 2 back buffer, cap `System_MaxFPS_Front=45`. Cấu hình người dùng
  của dự án: `View_Aplomb=0` (IMMEDIATE, 1 back buffer), Front 60.
- Trên máy dùng chung này VSync bật cho CY 21-29 fps, `Present` chặn ~30 ms (VSync tắt: 62 fps). Không đo được lợi ích của VSync ở đây.
- Đề xuất:
  1. Khi đo được trên máy không chia GPU, dùng VSync bật và cap Front ≥ tần số màn (60). Với 59 Hz, cap 45 của CY cho khung
     xen kẽ 1-2 vblank (16,9/33,9 ms), nên không mượt.
  2. Pacer của dự án không cần tắt khi VSync bật. Hạn kế tiếp tính từ đầu khung, nên Present chặn tới vblank thì lần chờ sau
     trả về ngay.
  3. Nếu còn xé hình khi VSync tắt, cân nhắc Front = 60 + VSync bật như CY (2 BB). Đổi này không nằm trong nhánh.

## 8. Nguồn giật còn lại (chưa xử lý)

| Nguồn | Hiện trạng (sau luagc + uievent + scenebuild + camdiscull) | CY 3.71 | Hướng |
|---|---|---|---|
| Lua full GC | 27-45 ms mỗi 10 s (6 khung/phút) | 54-82 ms mỗi 10 s | Đã ngang CY. Làm tốt hơn CY cần GC theo bước (LuaPlus 5.0 không có) hoặc chạy GC vào khung dư — ngoài "như CY" |
| CPU mỗi khung trong world | Main + L5: luồng vẽ 8,66 ms, render 6,3-6,9 ms (probe/CYS_PERF), ~870 lệnh vẽ (mục 6.6) | luồng vẽ 6,28 ms | Còn ~1,3-1,4 lần. Điểm nóng chưa sửa: (1) CEGUI dựng lại cả GUI mỗi khung do bảng tên trên đầu (`CCreatureBoard::SetPosition/Show` gọi setAlpha/setPosition/setSize/requestRedraw mỗi tick; CY CEGUIBase có `populateRenderCache` theo cửa sổ + `requestRedraw(bool)`) ~1 ms; (2) octree `_addToRenderQueue` 1,45 ms so với CY 0,9 |
| Biến thể material địa hình lần đầu | **đã sửa `prewarm` (6f49d0b0)**: khung đầu world cull 202-235 → 23-29 ms, 0 khung cull > 16 ms khi xoay | CY tạo mọi shader trong khung nạp | Giá: khung nạp +470-550 ms; giảm khi d3d9-trace gộp brush |
| Khung đầu vào world | sau `prewarm` 147-217 ms (trước 324-360 ms); cái còn lại: build 64 vật khởi động (~30 ms, như CY) + events + draw/UI; trước prewarm là 160-172 ms: cull 60 (nạp material/texture lần đầu, 52 texture) + build 31 (64 vật khởi động, như CY) + events 29 + draw/UI 21-25 | CY che bằng màn nạp; không đo được khung đầu | Có thể giữ màn nạp tới hết khung dựng đầu |
| `SCENE_TRANSED` | 461-502 ms (MiniMap nạp theo nhu cầu vì đăng ký `true`, 365-391 ms) | cùng luật đăng ký | Nạp layout MiniMap trước (khi vào world lần đầu) nếu CY làm vậy — chưa RE |
| Texture dùng lần đầu | draw 25-43 ms khi nạp 5-6 texture; PNG mây `Xyanmenguan_yun02.png` 68-77 ms | `MemLoadThread` đọc trước file theo `filedep.xml` ở luồng nền | Nạp nền kiểu CY là việc lớn (nguồn WX không có `MemLoadManager`) |
| Nạp lại cảnh đăng nhập | `CysLoginScene::Enter` gọi `Scene_Load` ở `Login::Init` và lại ở `CharSel::Init`; `unloadUnreferencedResourcesInGroup` giải phóng rồi nạp lại texture | — | Việc của charsel-scene |
| VSync | Mặc định người dùng tắt | Bật (ONE, 2 BB, cap 45) | Mục 7 |
| Gói `GCCharEquipment` | trước uievent 330 ms (kéo theo sự kiện UI); sau uievent không còn trong log chậm | — | Theo dõi |

## 9. Lệnh chạy lại

```
# probe
cmd /c Tools\perf\present_probe\build_probe.cmd Build\re\perf-cy\probe
# CY (bản sao riêng; one Game.exe)
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\perf\run_cy_probe.ps1 -OutDir Build\Logs\...\cy\login-X -Seconds 120 -View "System_MaxFPS_Front=60;System_MaxFPS_Back=60;View_Aplomb=0"
python -B Tools\perf\probe_table.py "Build\Logs\...\cy\login-*"
# dự án (stage riêng Build\world-gui\stage-*-perfcy)
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\perf\run_world_perf.ps1 -Stage Build\world-gui\stage-T-perfcy -OutDir Build\Logs\...\world\X -Probe -Env "CYS_PERF_UIEVENT=legacy"
python -B Tools\perf\hitch_report.py Build\Logs\...\world\X.perf\frames.csv
# chuỗi A/B xen kẽ có nghỉ 60 s và khoá lượt chung; bảng chi phí world
powershell -File Build\Logs\2026-09-15-perf-cy\world_series.ps1 -Probe -Gap 60 -Runs "xA-1|TAG|CYS_PERF_CAMDISCULL=0;xB-1|TAG|"
python -B Build\Logs\2026-09-15-perf-cy\world_cost.py xA-1 xB-1        # chạy trong thư mục world
# CY world qua oracle (bản sao riêng, probe); run_cy_oracle.ps1 tự lấy khoá lượt
powershell -File Build\Logs\2026-09-15-perf-cy\cy_world.ps1 -Name world-nov60-N
# caster ở camera của trace CY (TlbbViewer + proxy d3d9-trace), phân loại
powershell -File Build\Logs\2026-09-15-perf-cy\viewer_casters.ps1 -Tag vN
python -B Build\Logs\2026-09-15-perf-cy\casters_cat.py <capture>
```

## 10. Bẫy

- `run_cy_capture.ps1` ghi `-View` vào `System.cfg` của bản sao và giữ lại cho lượt sau: `run_cy_probe.ps1` đặt lại 45/25/VSync
  trước mỗi lượt (lượt `login-default-2` đầu tiên thực chất là `nov60` → đổi tên `login-nov60-2b`).
- Game.exe của agent khác có thể khởi động giữa lượt dù lượt đã chờ lúc bắt đầu: xem cột `games` của `load.csv`.
- `Tee-Object` của PowerShell 5.1 ghi UTF-16; báo cáo ghi bằng `Out-File -Encoding utf8`.
- Heredoc Bash làm hỏng `\\` và `\n` trong script Python; viết script bằng công cụ Write.
- Stage có `--pdb` nặng ~300 MB; ổ C: từng xuống 2,5 GB. Stage perf-cy dựng không PDB.
- Ghidra headless chạy song song trên cùng thư mục settings kẹt ở "Press any key": chạy tuần tự (`queue*.cmd`).
- **Khoá lượt Game.exe** `Build/game-slot.lock` (điều phối 15/09): `run_cy_oracle.ps1` tự lấy khoá, nên đừng lấy khoá bọc ngoài
  (khoá của mình < 5 phút làm nó chờ). Huỷ một lượt đang giữ khoá thì phải xoá khoá. Chạy nối liền không nghỉ làm agent khác
  không có lượt: `world_series.ps1 -Gap 60`.
- `d3d9.dll` proxy đặt trong thư mục `bin` của build bị `stage_game.py` chép vào stage **và manifest** → gỡ khỏi manifest
  hoặc xoá proxy trước khi dựng stage (`viewer_casters.ps1` tự xoá sau khi chạy).
- Bản sao CY dùng cho oracle cần `Patch/RemoteAddr.txt` Login_IP=127.0.0.1 và `Bin/ClientType.cfg NewStopSend_V2=0`; thiếu
  thì CY nối web cổng 80 sau khi vào game và lượt bị dừng.
- PowerShell: `$args` là biến tự động, không dùng làm tên biến mảng tham số.
- So caster với trace CY cần nhớ CY đang dựng cảnh dần: ở w09 CY mới dựng ~330 vật, TlbbViewer dựng hết ngay.
