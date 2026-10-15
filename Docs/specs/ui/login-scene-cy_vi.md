# Nền 3D động màn chọn server + đăng nhập theo CY 3.71 — 15/09/2026

Agent `charsel-scene` (nhánh `charsel-scene`). Người dùng: "Cảnh chọn nhân vật (nền) sử dụng nền động giống CY" → đính chính
"chọn server, và đăng nhập, không phải chọn nhân vật". Bằng chứng: `Build\Logs\2026-09-15-charsel-scene\`
(RE: `re\`, dump Ghidra: `Build\re\charsel-scene\out\`). Nguồn chuẩn: CY 3.71 `Tools\DATA NEW\CY Game\Bin64`
`Game.exe` SHA256 `9278c7f3…0cc5b` (imagebase 0x140000000), `Render.dll` SHA256 `e6e67de4…0cec7` (0x180000000).
Ghi chú: **FACT** = đọc trực tiếp từ binary/dữ liệu; **SUY LUẬN** = kết luận chưa kiểm bằng CY chạy thật.

## 1. CY chọn cảnh nào, thế nào (FACT)

| Hạng mục | CY 3.71 | Bằng chứng |
|---|---|---|
| Procedure | Màn chọn server và màn tài khoản cùng một procedure `CGamePro_Login` (trạng thái +0x2c0: 2 = chọn server, 3 = nhập tài khoản) | vtable `CGamePro_Login` tại `0x140c27ff8`: Init `FUN_14062f940`, Tick `FUN_14062fc00`, Render `FUN_140630270`, Release `FUN_140630290`; Tick/ProcessInput `FUN_14062f780` đọc `SelectServer_Server_SearchName` khi +0x2c0 == 2 |
| Cảnh | **Cố định `erengu_DL.Scene`** (Ác Nhân Cốc bản đăng nhập), scene id **-1**. Không ngẫu nhiên, không theo giờ, không theo phiên bản | `FUN_14062f940` (Init): nếu `GameServer_ConnectDirect != 1` → `Gfx+0x268(1)`, `Gfx+0x278(-1, "erengu_DL.Scene")`; chuỗi duy nhất trong Game.exe (`0x140c26d70`, `0x140c63f08`); callback nạp lại cảnh `FUN_1406c5650` ánh xạ id -1 → `erengu_DL.Scene`, id -2 → `tl3chuangjian.Scene` |
| Lúc nạp | Mỗi lần `CGamePro_Login::Init` (khởi động, và khi quay lại từ chọn nhân vật về tài khoản) | Init ở trên; Release rỗng (`FUN_140630290` = `ret`) |
| Tuỳ chất lượng | VRAM > 300 MB (`Gfx+0x5d8` = `FUN_180022dd0`, DirectDraw `GetAvailableVidMem` MB) → sương `linear` (`+0x370(1)` = `FUN_18002c800`) + phản xạ nước TerrainLiquid (`+0x3d8(1,1)` = `FUN_18002e710` → `FUN_180046f00`) | `FUN_14062f940` |
| Sau nạp | `Gfx+0x260` = `FUN_18002b5e0`: `setCurRenderConfigLevel(0)`, khoảng nhìn hệ thống +0x2ac/+0x2b0 = 65000, model đổ bóng (`FUN_1800ac630(1)`), **bật shadow map** (`FUN_1800d9470(1)`), `setShadowDis(18000, 1000)` (`+0x418`), rồi đặt camera đăng nhập `FUN_180002a30` | `Build\re\charsel-scene\out\r_login1.txt`; đặc tả `Docs\specs\render\shadow-cy_vi.md` mục 2 |
| Render/Tick | Render = `RenderFrame` (`Gfx+0x88`); Tick không động tới camera (chỉ trạng thái mạng/hotkey) | `FUN_140630270`, `FUN_14062fc00` |

## 2. Camera (FACT)

`FUN_180002a30` trên đối tượng `CCamera_CharSel` (con trỏ `CRenderSystem+0x58`): tách camera khỏi node,
**FOVy = 42°**, `setPosition`, `setOrientation`, `setFarClipDistance(40000)`. Hằng binary32 trong hàm:

| Tham số | Hex | Giá trị |
|---|---|---|
| Vị trí X, Y, Z | `0xc50e735c 0x458b767b 0xc5ffae29` | -2279.21, 4462.81, -8181.77 |
| Quaternion w, x, y, z | `0x3e7a8bd2 0xbc13ebc5 0xbf78091c 0xbd126ba8` | 0.244674, -0.00902838, -0.968889, -0.0357472 |
| Far clip | `0x471c4000` | 40000 |

Hướng nhìn = q·(0,0,-1) = (0.473, -0.074, 0.878): yaw ≈ 151,7°, pitch ≈ -4,2°, nhìn từ góc tây nam địa hình
256×256×100 (±12800) về phía đông bắc. **Camera tĩnh**: không có track/keyframe cho đăng nhập (4 track của
`CCamera_CharSel` — `CameraTrack`, `Role0To1`, `Role1To2`, `Role2To0` — chỉ dùng cho tạo/chọn nhân vật, xem
`Build\Logs\2026-09-13-gpt-create-role\original-reference\original-routing_vi.md`).

## 3. Chuyển động và âm thanh (FACT dữ liệu)

- `erengu_DL.Scene` (CanonicalCY `SceneFolder`, SHA256 `09e6ce0d…73b4c5`; có trong `Scene.axp` CY theo `Docs\evidence\assetinv\axplist_Scene.axp.txt`): 894 StaticEntity, **58 ParticleSystem,
  30 Effect, 12 Model** (quạ bay `从刃/从刃_乌鸦_飞姿.model` có hoạt cảnh), **6 TerrainLiquid**, 51 FakeLight,
  7 Light, 17 HierarchyNode, `EnScene` (vòm trời `DJLTyewan_color1.tga`, 4 lớp mây `enskycloud.mesh`, 9 lớp mây vòng, trăng đỏ
  `erengumoon_red.png`, hiệu ứng treo màn hình `cj_挂屏_风吹落叶` lá bay),
  sương linear 1000–25000 màu (0.09, 0.18, 0.24). Kèm `.EnScene/.hfog/.newhdrbloom/.lightmap.png/Color.tga/.path`.
- Chuyển động nền = hạt/hiệu ứng/quạ bay/nước/mây của cảnh; camera đứng yên (đúng CY).
- Nhạc nền: `SelectServer.lua` (Lua CY, agent cy-gui-2) khi mở màn chọn server gọi `Sound:PlaySound(2110, true, true)`
  nếu `GetClientVersionType() ~= 1`; `SoundInfo.txt` id 2110 = `music\ERenGu_Login.wav` ("天龙八部登陆界面音乐"),
  dừng ở `PLAYER_ENTERING_WORLD`. Không có mã native nào phát nhạc đăng nhập.
- Bóng: bật, back-off 18000 (đã có trong `CYSShadowHost::onSceneLoaded`, khớp `*erengu*`). ColorLUT: không có mục
  cho cảnh đăng nhập trong bảng `DAT_140fb35b0` → không LUT (`CysPostFx::sceneColorLut`). NewHDRBloom giữ tắt với id < 0.

## 4. Chuyển cảnh (FACT)

- Đăng nhập → chọn nhân vật: `CGamePro_CharSel::Init` (`FUN_14063c000`) nạp `tl3chuangjian.Scene` id -2,
  tắt bóng (`Gfx+0x228` = `FUN_18002b710`, khoảng nhìn 5000), camera chế độ 3 + track slot.
- Chọn nhân vật → quay lại tài khoản: `CGamePro_Login::Init` chạy lại → nạp lại `erengu_DL.Scene`.
- Vào game: `CScene::EnterScene` nạp cảnh thế giới (id ≥ 0), camera SCENE.

## 5. Cài trong CY-Source

| Việc | Chỗ | Ghi chú |
|---|---|---|
| Chế độ `CysLoginScene::Login` | `Src/Client/WXClient/Procedure/CysLoginScene.{h,cpp}` (thẻ `CYS-CHARSEL`) | Hằng camera CY ở trên (không đọc dữ liệu ngoài, như Render.dll CY); `Scene_Load(-1, "erengu_DL.Scene")`; `Camera_SetCurrent(CHAR_VIEW)` + cầu `CysLoginSceneCamera` (vị trí/quaternion/FOV) + cầu mới `CysLoginSceneFarClip(40000)` |
| Gọi như CY | `CGamePro_Login::Init` sau kiểm `GameServer_ConnectDirect`; `Release` → `Leave(Login)` | Màn chọn server và tài khoản cùng procedure nên cùng nền |
| Theo dõi cảnh đang nạp | `loadedScene` thay cờ `loaded` | Đổi login ↔ tạo/chọn thì nạp lại cảnh tương ứng; tạo ↔ chọn giữ cảnh (không phá actor); `CScene::EnterScene` gọi `NoteSceneLoaded` nên quay lại đăng nhập/chọn nhân vật sau khi vào game sẽ nạp lại |
| Dữ liệu không phải CY | `LoginSceneInstalled()` dò `erengu_DL.Scene` một lần | Hồ sơ Canonical (GL) không có cảnh → giữ nền trống như trước, không throw |
| Cầu far clip | `Src/Engine/WXRender/RenderSystem.cpp` export `CysLoginSceneFarClip`, kiểu trong `Src/Engine/Interface/CysLoginSceneBridge.h` | `CCamera_CharSel::Update` trả lại 100000 khi màn nhân vật chọn view |
| Smoke | `CysGlLoginSmoke.h`: `CYS_LOGIN_SCENE_SHOTS=N` chụp thêm `server-scene-i`/`account-scene-i` cách nhau 2 s | Chỉ bật khi đặt biến môi trường |

Sai khác có chủ ý / chưa làm:

1. CY bật shadow map ở cảnh đăng nhập bất kể mức; CY-Source bật theo `View_HumanLightmap` ≥ 2 (mặc định CY = 2) vì mức
   0/1 không có biến thể shader nhận bóng.
2. Phản xạ nước/sương theo VRAM (`+0x370`, `+0x3d8`) không gọi riêng: CY-Source dùng thuộc tính cảnh/cấu hình hiện có
   (SUY LUẬN: máy hiện đại luôn > 300 MB nên CY luôn bật cả hai).
3. `setCurRenderConfigLevel(0)` và khoảng nhìn 65000 của `WX::System` chưa có tương đương riêng.

## 6. Kết quả (15/09)

- Game.exe offline CanonicalCY, stage `Build\world-gui\stage-2-charsel` (nhánh sau gộp main 9e306c6):
  `Build\Logs\2026-09-15-charsel-scene\smoke-login-2` — `CYS login scene: loaded erengu_DL.Scene id=-1 in 685 ms`,
  3 ảnh màn chọn server + 3 ảnh màn tài khoản cách 2 s (`server-scene-1..3`, `account-scene-1..3`): quạ bay đổi vị trí,
  GUI CY đè đúng; smoke `PASS offline input`, 0 dump, 0 socket. `CYS-PERF` (WXRender.log): 53–56 fps (pacer 60).
- Camera khớp số đo bộ nhớ tiến trình CY thật của agent color-calib (mắt −2278,95; 4462,77; −8180,85, FOV 42, far 40000).
- Còn lệch so với ảnh CY thật (`Build\Logs\2026-09-14-color-calib\metrics\cy_login.png`, 1280×720):
  1. **Trăng đỏ không hiện** (`<Moon moon_tex_name="erengumoon_red.png" scale="11" moonOrient="344" moonAngle="9"
     moonfix="true">` trong `erengu_DL.EnScene`). FACT Render.dll CY: trăng EnScene = entity mặt phẳng prefab `en_moon`
     (200×200) ở nút con (0,0,−9000) (hằng `0x1802c3a04` = −9000, gán ở `0x1802aea50`), nút cha theo camera, quay
     (orient+180)° quanh −Y rồi −angle° quanh −X, nếu không `moonfix` thêm t·360° quanh −Y (`FUN_180236000`, ctor
     `FUN_180235a10`). Hướng CY = (0,272; 0,156; 0,949) ≈ 16° phải trục nhìn, 9° lên — khớp ảnh CY. `CYSSkyRenderer`
     dùng x = +sin(orient) (ngược dấu) và kích thước 0,01·scale nên trăng rơi ra ngoài khung. Bản vá thử
     `wip_cy_moon.patch` (chưa commit) vẫn chưa hiện trong TlbbViewer → cần xem thứ tự vẽ/lớp mây.
  2. **Mảng trắng trên nền đá** trước hồ (giữa-dưới) — có cả trong TlbbViewer của color-calib (`viewer\login\login_b.png`),
     không có trong CY; nghi TerrainLiquid/nước (log `Cannot find a parameter named wavesSpeed/BigWavesScale…` ×18).
  3. Tỉ lệ khung: CY luôn 1280×720 (16:9); smoke 1024×768 cắt hai bên (tượng lửa trái, mặt quỷ phải).

## 7. login-polish (15/09): trăng, mảng trắng, khung 1280×720

Agent `login-polish` (nhánh `login-polish`, hook `// CYS-LOGIN:`). Bằng chứng: `Build\Logs\2026-09-15-login-polish\`
(dump Ghidra `Build\re\login-polish\out\`). Ảnh ba cột: `metrics\login_cy_before_after.png`, số đo `metrics\login_metrics.txt`.

### 7.1 Trăng đỏ (commit `3d35cf1`)

- FACT (mục 6.1): hướng/kích thước trăng EnScene theo Render.dll CY (`FUN_180236000`, mặt phẳng 200·scale ở 9000).
- FACT nguyên nhân không hiện: `Billboard::setPosition` của OGRE 1.2 không nới hộp bao của `BillboardSet`; hộp giữ
  quanh thiên đỉnh (vị trí tạo `(0, 0.9, 0)`) nên frustum cull trăng khi camera không ngước (camera đăng nhập pitch −4°).
  Sửa: hộp bao phủ cả mặt cầu cho trăng/mặt trời/flare.
- Hàng đợi vẽ bầu trời theo **giá trị layer riêng biệt** (lớp mây alpha 0 ở mọi TimeNode không chiếm ô): trước đây
  8 ô hết sau 7 phần tử, trăng layer 30 chung hàng đợi với 7 lớp mây, thứ tự trong hàng đợi không xác định (mọi phần
  tử bầu trời ở độ sâu 0).
- Đo (1280×720, cùng khung đăng nhập): tâm đĩa trăng CY (850,154) đường kính ngang 170 px; sau sửa (848,160) 168 px.

### 7.2 Mảng trắng trước hồ (commit `7e50dc5`)

- FACT: không phải nước (`CYS_WATER=0` vẫn trắng). Cảnh thử bỏ 31 StaticEntity cỏ/lá thì hết; bỏ riêng lá thì còn →
  `恶人谷_草地片.mesh`. Vật liệu `恶人谷_草地片 : Mtl_Model_Transperant` viết `technique { pass { } pass { emissive 0.2 0.2 0.2 } }`
  trên template 1 pass → bộ đọc (OGRE, và `MaterialScriptCompiler::parsePass` của OgreMain CY như nhau) thêm pass 2
  mặc định: có sáng, đục, ghi độ sâu, không texture, không chương trình. 61 vật liệu CY có mẫu này.
- SUY LUẬN (chưa lần hết đường vẽ SceneRenderProxy của CY): CY không cho thấy gì của pass đó. `CysMaterialSystem` bỏ pass
  không chương trình + không texture đứng sau một pass shader khỏi bản biến thể mesh (thống kê
  `texture-less passes dropped`). Kiểm bằng số đo: hộp (740..850, 585..612) CY rgb (42,56,65), sau sửa (46,58,66),
  trước sửa 36,8 % điểm luma > 110.
- Nước: `applyWaterShaderParams` hỏi `hasNamedConstant` trước khi đặt → hết 18× "Cannot find a parameter named …" (log).

### 7.3 Khung 1280×720 (commit `d994dcf`)

| CY 3.71 (FACT) | Hàm | CY-Source |
|---|---|---|
| Cửa sổ chính tạo với vùng khách **1280×720**, style `0xCA0000`, căn giữa `SM_CXFULLSCREEN`; không đọc `View_Resoution`/`View_FullScreen`/`View_MaxWindow`, không phát sự kiện | `FUN_140623bd0` | `CGameProcedure::CreateMainWnd` |
| `CGamePro_Login::Init`: bỏ `WS_THICKFRAME|WS_MAXIMIZEBOX`, `SW_RESTORE` + `MoveWindow` 1280×720 căn giữa vùng làm việc, `FUN_140620a30(WM_EXITSIZEMOVE)` | `FUN_14062f940` → `FUN_1406302b0` | `CysLoginWindowFixed` (bỏ qua khi đã đúng 1280×720, không cửa sổ phóng to — khác có chủ ý: không phát sự kiện thừa) |
| `CGamePro_CharSel::Init` / `CGamePro_CharCreate::Init`: khung co giãn lại; `View_FullScreen=1` → cỡ màn hình; không thì `View_Resoution` nếu khác cỡ hiện tại (`View_MaxWindow` đọc nhưng bỏ) | `FUN_14063c000`→`FUN_14063c8e0`, `FUN_140640a50`→`FUN_140641c20` | `CysLoginWindowRestore` (CharCreate chỉ khi là thủ tục đang chạy, vì khởi động có prewarm) |
| `View_MaxWindow`: WM_SIZE ghi 1 khi phóng to / 0 khi khôi phục; handler `View_Resoution` ở thủ tục Main không `MoveWindow` khi đang phóng to. CY **không tự phóng to** lúc khởi động (`ShowWindow(…,3)` duy nhất ở `WM_DISPLAYCHANGE`). Cfg CY có `View_MaxWindow=1` vẫn khởi động 1280×720 | `FUN_1406229c0`, `FUN_140468010` | Chưa dùng `View_MaxWindow` (không có code cũ đọc nó) |
| UI: `VIEW_RESOLUTION_CHANGED` (id 0x166 trong bảng `FUN_140a0db90`) **không nạp** cửa sổ chưa nạp (thêm cờ item+0x180 == 1, INF: cửa sổ nạp theo nhu cầu) | UI_CEGUI `FUN_180079300` | `CUIWindowItem::_OnGameEvent`. 1.651/2.042 script CY đăng ký sự kiện này: thiếu luật này, đổi cỡ ở màn chọn nhân vật nạp dồn ~1.150 layout (lượt thử văng vì `ZBS_TeamInfo` trùng tên cửa sổ) |

A/B: `CYS_LOGIN_WINDOW=0` = cửa sổ theo `View_Resoution` như trước. Kết quả: smoke offline PASS 1280×720 (thấy tượng lửa
trái, mặt quỷ phải như CY); phát lại vào world 28/28 PASS, đăng nhập 1280×720 → chọn nhân vật 1024×768, số layout nạp
như trước (231).
