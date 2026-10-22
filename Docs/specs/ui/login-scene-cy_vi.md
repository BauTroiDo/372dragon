# Nền 3D động màn chọn server + đăng nhập theo CY 3.71 — 15/09/2026


## 2. Camera (FACT)


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


A/B: `CYS_LOGIN_WINDOW=0` = cửa sổ theo `View_Resoution` như trước. Kết quả: smoke offline PASS 1280×720 (thấy tượng lửa
trái, mặt quỷ phải như CY); phát lại vào world 28/28 PASS, đăng nhập 1280×720 → chọn nhân vật 1024×768, số layout nạp
như trước (231).
