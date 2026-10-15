# 00b — Render + OGRE của mã nguồn gốc 0.85: bản đồ nền để dựng lại và làm đẹp

Ngày 19/09/2026. **Đọc file này TRƯỚC `01`–`05`.** Các spec 01–05 mô tả *khoảng cách* giữa 0.85 và client_GL/CY;
file này mô tả *cái đang có* — kiến trúc render của chính mã nguồn gốc 0.85, từng nút vặn, từng đường dữ liệu,
và những chỗ bản gốc tự làm mình xấu đi. Không có nền này thì mọi việc "thêm HDR / thêm bóng" đều là đoán mò.

Ký hiệu: **FACT** = có file/dòng/chuỗi chứng minh, đã mở ra xem; **INF** = suy luận từ FACT, ghi rõ căn cứ.

Viết tắt đường dẫn (gốc `C:\TLBB\085`):

| Ký hiệu | Đường dẫn | Ghi chú |
|---|---|---|
| **A** | `CY-Source\Reference\tlbb085\085\SourceCode\Client\天龙八部客户端` | mã nguồn gốc 0.85, **chỉ đọc** |
| **D085** | `CY-Source\Reference\tlbb085\085\Build\Client\Data` | dữ liệu client 0.85 gốc (1,4 GB) |
| **P** | `CY-Source\Src\Engine` | bản port x64 đang dựng (nơi được phép sửa) |
| **C** | `client` | client đang chạy của người dùng — **KHÔNG phải 0.85 thuần** (mục 14) |

Mã nguồn 0.85 mã hoá **GBK**. Đọc bằng `iconv -f GBK -t UTF-8 -c <file>`; mở thẳng sẽ ra chữ rác và dễ đọc sai chú thích.

---

## 1. Ai render cái gì — bốn tầng

**FACT** (`A\Client\WXRender\RenderSystem.cpp`, `A\Client\WXCore\Core\WXSystem.cpp`):

```
Game.exe  ──►  WXEngine (tKernel: node "bin\gfx", var, event, time, snd, worldman)
                  │
                  ▼
           WXRender.dll — CRenderSystem (lớp game: camera, trục toạ độ, biến View_*, chụp màn hình)
                  │  m_pRenderSystem = new WX::System      (RenderSystem.cpp:88)
                  ▼
           WXCore — WX::System  ("Fairy"): scene, terrain, object, effect, post-filter, model
                  │
                  ▼
           OgreMain.dll — OGRE 1.2.5 "Dagon" + plugin nhúng tĩnh
                  │
                  ▼
           RenderSystem_Direct3D9.dll
```

Điểm quan trọng: **WXRender rất mỏng (7.630 dòng), WXCore mới là engine render (39.191 dòng .cpp)**. Mọi thứ liên quan
tới "đẹp" — địa hình, vật liệu, ánh sáng, hạt, hậu kỳ, nước, trời — nằm trong `A\Client\WXCore`, không nằm trong WXRender.

`A\Client\Common\TDGfxSystem.h` là interface trừu tượng giữa game và render (`Scene_*`, `Camera_*`, `Actor_*`).
Phần lớn khai báo `Scene_*` trong file đó **đã bị comment** (TDGfxSystem.h:251–279) — game gọi thẳng `CRenderSystem`.

Bố cục thư mục WXCore (**FACT**, `A\Client\WXCore`):

| Thư mục | Nội dung | File lớn nhất |
|---|---|---|
| `Core\` | `WX::System`, Scene/SceneInfo/SceneSerializer, Terrain + TerrainData + TerrainTile*, mọi loại Object (Light, StaticEntity, Actor, Model, ParticleSystem, SkyBox/Dome/Plane, Enviroment, TerrainLiquid, Effect, LogicModel), Projector, MaterialInstance, RayCollide | `TerrainData.cpp` 1.849 |
| `ModelSystem\` | `LogicModel` (nhân vật + trang bị + hiệu ứng gắn), SkeletonMesh, SceneAnimation | `WXLogicModel.cpp` 4.501 |
| `EffectSystem\` | Effect/Skill/Keyframe + 8 loại element (Mesh, Particle, Billboard, Beam, Ribbon, PointLight, Projector, SceneLight) | `WXEffectManager.cpp` 1.218 |
| `PostFilter\` | khung hậu kỳ trên compositor OGRE + 5 filter + `media\` (.cg/.material) | `WXPostFilters.cpp` |
| `OgreExt\` | renderer/affector hạt bổ sung: TexCoordBillboard, MeshParticle, Ribbon, MeshRotation, MeshAnimation, AutoAnimationEntity | — |
| `MaterialTemplates\` | template vật liệu nhân vật (Cg SM1–2) + `nm_*.png` | — |
| `ResourceSystem\` | `PakFileSystemArchive` — đọc gói `.axp` | — |

Bản port **P** giữ nguyên `Core\`, `ModelSystem\`, `EffectSystem\`, `OgreExt\`, `ResourceSystem\` (danh sách file
`P\WXCore\Core` khớp 100 % với `A\Client\WXCore\Core`) và **thêm**: `P\WXCore\CYS\{Scene,Shadow,PostFX,Water,Effects,Perf}`
và `P\WXRender\MaterialSystem\` (mục 16).

---

## 2. OGRE trong TLBB — phiên bản, phần đã sửa, và giới hạn

**FACT** `A\OGRE\OgreMain\include\OgrePrerequisites.h:86–89`:

```c
#define OGRE_VERSION_MAJOR 1
#define OGRE_VERSION_MINOR 2
#define OGRE_VERSION_PATCH 5
#define OGRE_VERSION_NAME "Dagon"
```

**OGRE 1.2.5 "Dagon"** (2006). Đây là mốc quyết định mọi thứ còn lại: compositor thế hệ 1, shadow stencil/texture kiểu cũ,
không có SceneManager phân cảnh cho terrain của game, và trình dịch material chưa biết nhiều từ khoá của client_GL (spec `01`).

### 2.1 Thay đổi của TLBB so với OGRE gốc

**FACT** `A\OGRE\OgreMain\src\OgreRoot.cpp:995–1046`: plugin **không** nạp bằng DLL mà gọi thẳng hàm khởi tạo —
`OgreMain.dll` là một khối:

```c
void Root::loadInnerPlugins() {          // OgreRoot.cpp:995
    registerParticleFactories();          // ParticleFX
    registerParticleFactories2();         // ParticleFX2 (của TLBB)
    StartOctreeSceneManager();            // Octree + Terrain SceneManager
    StartCgProgramManager();              // Cg
    StartScorpio();                       // vải/cloth + hardware skinning
}
void Root::loadRenderPlugins_D3D9() {    // OgreRoot.cpp:1008
    StartDirect3D9();
    setRenderSystem(getRenderSystemByName("Direct3D9 Rendering Subsystem"));
}
```

`StartOctreeSceneManager` được khai báo `_OgreTerrainExport` trong
`A\OGRE\PlugIns\OctreeSceneManager\include\OgreOctreeSceneManagerDll.h:34` → biên dịch thẳng vào OgreMain.

**FACT** `A\Client\WXRender\RenderSystem.cpp:398–413`: nhánh chọn OpenGL đã bị comment, chỉ còn
`loadRenderPlugins_D3D9()` rồi `loadInnerPlugins()`. **Client 0.85 là D3D9 thuần.**

Mô hình link mà bản port đã chốt nằm ở `CY-Source\Src\cmake\components\ogremain.cmake` (đọc phần chú thích đầu file
trước khi sửa build): Win32 platform manager + ParticleFX + Octree/Terrain nhúng tĩnh; D3D9, ParticleFX2, Scorpio,
Cg nạp theo tên DLL; **bỏ** `OgreShadowCameraSetupFocused.cpp` và `OgreShadowCameraSetupLiSPSM.cpp` (cần API OGRE 1.4).

### 2.2 SceneManager thật sự dùng là gì

**FACT** `A\Client\WXCore\Core\WXSystem.cpp:449`:

```c
mSceneManager = mRoot->createSceneManager(Ogre::ST_GENERIC, "FairyMainScene");
```

**`ST_GENERIC` = SceneManager mặc định của OGRE, KHÔNG phải Octree/TerrainSceneManager.** Octree có trong OgreMain
nhưng game không tạo nó. Hệ quả (**INF**, căn cứ: không có cây phân vùng nên OGRE cull từng MovableObject bằng frustum):
0.85 không có occlusion/portal, không có LOD địa hình; chống tải nặng bằng *create level* + *animation level* (mục 9)
chứ không bằng cấu trúc không gian.

`Terrain::buildGeometry` vẫn ghi `setOption("Size", &aabb)` cho SceneManager (Terrain.cpp:819–834, có chú thích
"especially for OctreeSceneManager") — dấu vết của thời từng chạy Octree; với `ST_GENERIC` lời gọi này vô hại.

### 2.3 Hàng đợi vẽ và mặt nạ

**FACT**:

- `A\Client\WXCore\Core\WXPrerequisites.h:40` — `FairySpecialCaseRenderQueue = Ogre::RENDER_QUEUE_9`;
  đăng ký ở `WXSystem.cpp:531`.
- `WXSystem.cpp:532` — `setVisibilityMask(OVF_DEFAULT)`.
- `A\Client\WXCore\Core\WXFlags.h` — cờ truy vấn `OQF_DECAL_TARGET=1`, `OQF_COLLIDEABLE=2`, `OQF_DEFAULT=~0<<2`;
  cờ hiển thị `OVF_POSTFILTER=1`, `OVF_INDICATORS=2`, `OVF_GUI_ELEMENTS=4`, `OVF_DEFAULT=~0<<3`.
- Cây node: `#MainSceneNode` → `#StaticSceneNode` (`WXSystem.cpp:536–537`). Muốn ẩn/vẽ riêng cả thế giới thì tháo
  `#MainSceneNode` ra khỏi root — đây là cơ chế render sub-scene mà chú thích trong `WXSystem.h` nói tới.

### 2.4 OGRE 1.2.5 **không** làm được gì (ảnh hưởng trực tiếp tới "đẹp")

**INF**, căn cứ chéo với spec `01`:

- Không truyền include handler cho `D3DXCompileShader` → mọi `.hlsl` có `#include` của client_GL không dịch được.
- Thiếu ~37 auto-constant (shadow, actor, wind, DQ skinning, mảng đèn, fog_type…).
- Trình dịch material chưa có `render_queue`, `separate_scene_blend`, `content_type`, `sampler_index`, `shader_type`.
- Compositor v1: không alias RT, không tham chiếu texture chéo compositor, không pass theo render-queue.

Đây là bốn "trần nhà" của bản 0.85; muốn vượt phải sửa OgreMain chứ không sửa được bằng dữ liệu.

---

## 3. Trình tự khởi động render (đúng thứ tự gọi)

**FACT**, `A\Client\WXRender\RenderSystem.cpp` + `A\Client\WXCore\Core\WXSystem.cpp`:

| # | Gọi ở | Việc |
|---|---|---|
| 1 | `RenderSystem.cpp:88` | `new WX::System` |
| 2 | `RenderSystem.cpp:373` | `System::init("WXResources.cfg", "", "", "WXRender.log")` → `new Ogre::Root` (không plugins.cfg, không ogre.cfg) |
| 3 | `WXSystem.cpp:198–211` | đăng ký `PakFileSystemArchiveFactory` (`.axp`); `MeshManager::setEnableAutoBuildAllMeshesEdgeLists(true)`; đặt query/visibility mask mặc định |
| 4 | `WXSystem.cpp:262–290` | đọc `WXResources.cfg` → thêm resource location theo nhóm |
| 5 | `WXSystem.cpp:295–308` | đăng ký 12 ObjectFactory (Light, StaticEntity, Actor, Model, ParticleSystem, SkyBox, SkyDome, SkyPlane, Enviroment, TerrainLiquid, Effect, LogicModel) |
| 6 | `RenderSystem.cpp:411,413` | `loadRenderPlugins_D3D9()` rồi `loadInnerPlugins()` |
| 7 | `RenderSystem.cpp:425–447` | đọc `View_Fanhunjiao` → `FSAA` = 0/2/4; `View_Aplomb` → `vsync` |
| 8 | `RenderSystem.cpp:449` | `System::setup(hWnd, &ViewSetting)` |
| 9 | `WXSystem.cpp:315–338` | createRenderWindow → createSceneManager → createCamera → createViewports → `EffectManager` → `LogicModelManager` → `TextureManager::setDefaultNumMipmaps(5)` |
| 10 | `WXSystem.cpp:335–338` | `initialiseResourceGroup(Bootstrap)` rồi `initialiseAllResourceGroups()` — **đây là lúc mọi `.material/.program/.overlay` được phân tích** |
| 11 | `WXSystem.cpp:529–556` | `_initScene`: special-case queue 9, `FrameStatsListener`, `#MainSceneNode`, `PostFilterManager`, `SceneInfo` (tạo `Terrain` + `TerrainData`), đọc `WXTerrainType.cfg` |
| 12 | `RenderSystem.cpp:452–455` | tắt logo + bảng thống kê OGRE |
| 13 | `RenderSystem.cpp:485–492` | tạo `CCamera_CharSel` + `CCamera_Scene` |
| 14 | `RenderSystem.cpp:495–502` | `registerAllPostFilterFactories` → tạo filter **`Floodlighting`** và **`Fade`** (Bloom + HeatVision bị comment ở dòng 499–500) |
| 15 | `RenderSystem.cpp:514` | `Ogre::ParticleSystem::setDefaultIterationInterval(0.033f)` |
| 16 | `RenderSystem.cpp:517–523` | đăng ký handler `VARIABLE_CHANGED`, đẩy lại đúng **một** biến: `View_ColorQuality` |

**Bẫy ở bước 16 (FACT):** chỉ `View_ColorQuality` được áp lại lúc khởi động. `View_TextureFiltering`,
`View_LightmapQuality`, `View_ObjectMove`, `View_FullScreenLight` **chỉ có tác dụng khi người chơi tự bấm đổi trong
game** — mở game lên là chạy giá trị mặc định của code, không phải giá trị trong `System.cfg`. Xem mục 13.

### Nạp một cảnh (`Scene_Load`, RenderSystem.cpp:790)

1. `System::resetScene()` — xoá SceneInfo, `RenderQueue::clear(destroyPassMaps=true)`, giải phóng buffer tạm.
2. `System::loadSceneFromResource(parser, "<tên>.Scene", "General")`
   → `SceneInfo::load` → `_postprocessScene` (`WXSystem.cpp:612–632`):
   `mBaseScale = sqrt(scale.x * scale.z)` → `_adjustCamera()` → `TerrainTypeInfos::update` →
   **`SceneInfo::initialise` (`WXSceneInfo.cpp:236–288`) gọi `Terrain::buildGeometry`** → `MainSceneLight::updateLightInfo`.
3. `unloadUnreferencedResourcesInGroup` cho mọi nhóm trừ Internal/Bootstrap.
4. `RenderSystem.cpp:822–823`: **`setLightmapQuality(LMQ_LOW)` + `buildGeometry(...)` lần hai.**
5. Tìm object kiểu `Enviroment` để giữ con trỏ (dùng cho hạt thời tiết bám theo nhân vật).

Bước 4 là một trong những nguyên nhân "0.85 trông bệt" — xem mục 5.3 và 15.

---

## 4. Hợp đồng dữ liệu của "cái đẹp"

Ba file quyết định 80 % diện mạo một cảnh. Đây là hợp đồng mà cả `SceneEdit` lẫn engine cùng tuân theo.

### 4.1 `<tên>.Scene` (XML, nhóm `General`)

**FACT**, ví dụ thật `C\Data\SceneFolder\Biwuzhaoqin.Scene`:

```xml
<Scene formatVersion="0.1.1" name="Biwuzhaoqin">
  <Terrain filename="Biwuzhaoqin.Terrain"/>

  <Object name="#FairyEnviroment" type="Enviroment">
    <Property name="ambient"          value="0.482353 0.564706 0.701961"/>
    <Property name="fog.mode"         value="linear"/>
    <Property name="fog.colour"       value="0.294118 0.619608 1"/>
    <Property name="fog.linear start" value="7500"/>
    <Property name="fog.linear end"   value="18000"/>
  </Object>

  <Object name="#FairyMainLightOne" type="Light">
    <Property name="type"      value="directional"/>
    <Property name="diffuse"   value="0.901961 0.737255 0.486275"/>
    <Property name="specular"  value="0.34902 0.247059 0.439216"/>
    <Property name="direction" value="0.2 -1 0.5"/>
    <Property name="cast shadows" value="true"/>
  </Object>

  <Object name="#FairyMainLightTwo" type="Light">   <!-- đèn phụ, thường tối và ngược hướng -->
    ...
  </Object>
</Scene>
```

**Ba tên có ý nghĩa cứng trong code:**

| Tên | Dùng ở | Ý nghĩa |
|---|---|---|
| `#FairyEnviroment` | `RenderSystem.cpp:826–836` | ambient + fog + màu nền + hạt thời tiết |
| `#FairyMainLightOne` | `WXMainSceneLight.cpp:143` | đèn chính (key light) |
| `#FairyMainLightTwo` | `WXMainSceneLight.cpp:167` | đèn phụ (fill light) |

**FACT** `A\Client\WXCore\Core\WXEnviromentObject.cpp:304–310` — toàn bộ việc mà Enviroment làm:

```c
mSceneManager->setFog(mFogMode, mFogColour, mFogExpDensity, mFogLinearStart, mFogLinearEnd);
mSceneManager->setAmbientLight(mAmbientLight);
mViewport->setBackgroundColour(mFogMode == Ogre::FOG_NONE ? mBackgroundColour : mFogColour);
```

Mặc định khi thiếu thuộc tính (`WXEnviromentObject.cpp:167–181`): `fog.mode=none`, `exp density=0.001`,
`linear start=0`, `linear end=1`, `ambient=Black`, `background=Black`, `fog.colour=White`.
**Cảnh thiếu `#FairyEnviroment` ⇒ ambient đen tuyền** — vì `SceneInfo::initialise` đặt
`setAmbientLight(Black)` trước khi dựng (`WXSceneInfo.cpp:239`).

**INF** (căn cứ: template nhân vật đặt `max_lights 2`, mục 6): kiểu chiếu sáng của 0.85 là **ba nguồn cố định**
— ambient + 1 directional chính + 1 directional phụ. Muốn đổi "tông" một bản đồ, đây là ba con số phải sửa trước,
không phải shader.

### 4.2 `<tên>.Terrain` (XML)

**FACT**, thẻ hợp lệ theo `A\Client\WXCore\Core\TerrainDataSerializer.cpp:86–292`:

| Thẻ | Thuộc tính | Ghi chú |
|---|---|---|
| `Terrain` | `name`, `xsize`, `zsize`, `tileSize` | kích thước theo **ô lưới** |
| `scale` \| `size` | x,y,z | `scale` = đơn vị thế giới/ô; `size` = tổng, engine tự chia |
| `position` \| `centre`/`center` | x,y,z | gốc ô (0,0) |
| `heightmap` | `filename`, `type` = standard\|image\|raw | |
| `gridInfo` | `filename`, `type` = standard | 2 layer + cờ mỗi ô |
| `lightmap` | `filename`, `type` = standard\|image | |
| `pixmap` | `textureId`, `left/top/right/bottom` | một ô cắt trong texture |
| `texture` | `filename`, `type`=image | |
| `template` | `name` ∈ {OneLayer, TwoLayer, OneLayerLightmap, TwoLayerLightmap}, `material` | **bốn tên này là cứng** (`Terrain.cpp:642–644`) |
| `fog_replacement` | `none`, `exp`, `exp2`, `linear` | bốn tên GPU program cho 4 chế độ sương |
| `ambient`/`diffuse`/`specular`(+`shininess`)/`emissive` trong `<surface>` | r,g,b | tham số bề mặt của **mọi** material địa hình |

Mặc định surface (`TerrainData.cpp:57–64`): ambient/diffuse/specular = trắng, emissive = đen, **shininess = 64**.

Thẻ lạ ⇒ **ném exception** ("Unexpected data was found while parsing the terrain file", `TerrainDataSerializer.cpp:292`).
Đó là lý do file `.Terrain` của client đang chạy (có `useColorMap`, `colorMap`, `useColorMapAlphaBlend`) **không**
nạp được bằng engine 0.85 — mục 14.

### 4.3 Lightmap

**FACT** `A\Client\WXCore\Core\TerrainData.cpp:461–469`: ảnh lightmap phải đúng `xsize*8 × zsize*8`, 1 mặt, depth 1;
sai kích thước thì engine **ghi log "Terrain lightmap out of date" rồi vứt lightmap đi** (không báo lỗi, chỉ tối đi).

### 4.4 Quy ước đặt tên texture địa hình

**FACT** `C\Bin\TerrainTypeInfo.cfg` + tên file trong `D085\Brushes`: texture địa hình đi theo cặp
`…底层.jpg` (lớp dưới, đục, layer 0) và `…上层.tga` (lớp trên, có alpha = mặt nạ trộn, layer 1);
hậu tố `高光` (highlight) đánh dấu texture có kênh alpha dùng làm mặt nạ specular. Xem công thức ở mục 5.4 —
alpha của texture **không** phải độ trong, nó là mặt nạ trộn (layer 1) và mặt nạ specular (layer 0).

`WXTerrainType.cfg`/`TerrainTypeInfo.cfg` gán mỗi texture vào một trong 5 loại mặt đất
`soil / grass / snow / stone / liquid` (`A\Client\WXCore\Core\TerrainTypeInfos.cpp:25–30`) để phát hiệu ứng bước chân.

---

## 5. Địa hình — hệ render riêng, không phải của OGRE

### 5.1 Atlas texture

**FACT** `A\Client\WXCore\Core\Terrain.cpp:50–55`:

```c
mAtlasTextureSize = 512;   // mỗi atlas 512×512
mAtlasPixmapSize  = 64;    // mỗi ô texture 64×64
mAtlasNumMipMaps  = 6;     // 64 >= 1<<6
mAtlasBlockSize   = 512/64 = 8;   // 8×8 = 64 ô mỗi atlas
```

**Toàn bộ texture mặt đất bị ép xuống 64×64 và nhét vào atlas 512×512.** Đây là trần độ nét của mặt đất 0.85
và là chênh lệch dễ thấy nhất so với CY. Đổi hai hằng số này là cách nâng chất lượng rẻ nhất trong cả tài liệu
(kèm chi phí VRAM bậc hai — xem mục 15 #4).

### 5.2 Vật liệu mỗi ô = clone từ template + đổi tên texture

**FACT** `Terrain.cpp:601–706`:

1. Khoá vật liệu `MaterialId{textureId0, textureId1, lightmapId, depthBias}`; `lightmapId = (tileZ<<16)|tileX`.
2. Chọn template theo `textureIds[1] ? "TwoLayer" : "OneLayer"`, `+ "Lightmap"` nếu có lightmap.
3. `templateMaterial->clone(name, true, "General")` rồi `applyTextureAliases({<layer0>, <layer1>, <lightmap>})`.
4. Áp `surface` params, áp fog, cộng `depthBias`.

Tên vật liệu sinh ra: `Terrain/<tên cảnh>/<id0>.<id1>[_<bias>][_<Lightmap>(x,y)]`.

**Hệ quả (INF):** muốn đổi cách mặt đất được tô — thêm normal map, thêm colour map, đổi công thức — thì sửa
**4 material template** trong `D085\Scene\FairyTerrain.material` là đủ, không phải sửa C++. Đó cũng là cách
client đời sau làm (`Terrain/OneLayerColorMap`, `Terrain/TwoLayerColorMapAlphaBlend` — mục 14).

### 5.3 Lightmap: chất lượng bị ép xuống LOW ở mọi lần nạp cảnh

**FACT** `Terrain.cpp:776–800` và `Terrain.cpp:203–215`:

| Mức | Kích thước texture lightmap mỗi tile | Ghi chú |
|---|---|---|
| `LMQ_NONE` | — | xoá luôn ảnh lightmap khỏi bộ nhớ |
| `LMQ_LOW` | `tileSize * 2` | với `tileSize=32` ⇒ **64×64** |
| `LMQ_HIGH` | `tileSize * 8` | ⇒ **256×256**, đúng 1:1 với dữ liệu gốc |

Định dạng: `PF_L8`, `TU_AUTOMIPMAP|TU_STATIC_WRITE_ONLY`, mip = −1 (`Terrain.cpp:796–799`).

**FACT** `Terrain.cpp:38–39`: giá trị khởi tạo là `LMQ_HIGH`.
**FACT** `RenderSystem.cpp:822`: `Scene_Load` **ép cứng `LMQ_LOW`** rồi dựng lại hình học.

Nên: cảnh đầu tiên dựng ở HIGH (do `SceneInfo::initialise`) rồi **dựng lại** ở LOW; mọi cảnh sau dựng hai lần ở LOW.
Kết quả là **ánh sáng nướng của mọi bản đồ chỉ còn 1/16 số texel**, cộng thêm một lần dựng địa hình thừa mỗi lần đổi cảnh.
`View_LightmapQuality` trong `System.cfg` không cứu được vì nó chỉ chạy khi người chơi bấm đổi (mục 3, bước 16).

**Sửa tối thiểu:** bỏ hai dòng `RenderSystem.cpp:822–823` và thay bằng việc đọc `View_LightmapQuality` một lần
lúc khởi động (đẩy `GE_VARIABLE_CHANGED` như đang làm với `View_ColorQuality` ở dòng 520). Đây là thay đổi
một dòng có tác động hình ảnh lớn nhất trong mã nguồn 0.85.

Thành viên `mLightmapTextureSize = 1024` (`Terrain.cpp:38`) **không được dùng ở đâu cả** — mã chết, đừng tin nó.

### 5.4 Hình học và công thức tô

**FACT** `A\Client\WXCore\Core\TerrainTileOptimized.cpp:86–140`. Mỗi ô lưới là **một quad riêng, 4 đỉnh không dùng chung**,
gom theo material bucket trong từng tile. Khai báo đỉnh:

```
POSITION float3 | NORMAL float3 | TEXCOORD0 float2 (layer0)
                                [ TEXCOORD1 float2 (layer1)  — chỉ bucket 2 lớp ]
                                [ TEXCOORDn float2 (lightmap) — nếu có lightmap ]
```

Không có màu đỉnh, không có LOD, không có morphing. Việc 4 đỉnh riêng cho mỗi ô là cố ý: nó cho phép mỗi ô
xoay/lật texture độc lập (`TerrainData::LayerInfo::orientation`, `GridInfo::FlipDiagonal`).

**FACT** `D085\Scene\FairyTerrain.cg` — công thức tô hai lớp có lightmap:

```c
float4 c0 = tex2D(layer0, uv0);
float4 c1 = tex2D(layer1, uv1);
float3 texturedColour = lerp(c0.rgb, c1.rgb, c1.a);          // alpha layer1 = mặt nạ trộn
float4 lightmapColour = tex2D(lightmap, uvLightmap);
float4 baseColour     = diffuse * lightmapColour;             // diffuse = COLOR0 = đèn tính ở ĐỈNH
float3 finalColour    = baseColour.rgb * texturedColour
                      + specular.rgb * (1-c0.a) * (1-c1.a) * lightmapColour.a;   // alpha = mặt nạ specular
oColour = float4(Fogging(finalColour), baseColour.a);
```

**Ba điều rút ra (FACT từ chính shader):**

1. Ánh sáng mặt đất là **fixed-function per-vertex** (`COLOR0`/`COLOR1` do OGRE tính ở đỉnh), nhân với lightmap.
   Không có per-pixel lighting trên mặt đất trong 0.85.
2. `alpha` của texture lớp trên = mặt nạ trộn; `alpha` của cả hai lớp = **nghịch đảo** mặt nạ specular.
   Texture đặt alpha sai sẽ làm mặt đất bóng nhẫy hoặc bệt lì — không phải lỗi shader.
3. Sương mù nằm **trong** shader, chọn bằng macro `ARB_fog_*`.

**FACT** `D085\Scene\FairyTerrain.program`: bản gốc `profiles ps_1_1 arbfp1`; bốn biến thể `%fog_linear/%fog_exp/%fog_exp2`
chỉ khai báo `profiles arbfp1` (**chỉ OpenGL**).
**FACT** `TerrainData.cpp:801–838` (`_fixupSupportedMaterials`): một `fog_replacement` chỉ được nhận nếu **cả bốn**
program tồn tại, `isSupported()` và `load()` được.
**INF:** chạy D3D9 ⇒ bốn biến thể `arbfp1` không được hỗ trợ ⇒ `mSupportedFogReplacements` rỗng ⇒
`Terrain::_applyFogMode` (Terrain.cpp:533–540) thoát ngay ⇒ **cơ chế fog_replacement là mã chết trên client thật**;
sương trên mặt đất do khối fog cố định của D3D9 lo. Đừng mất thời gian sửa `%fog_*` trước khi có đường HLSL.

---

## 6. Vật liệu nhân vật, NPC, vũ khí

**FACT** `CY-Source\Assets\Staging\materialtemplates\A085\` (giải nén từ `D085\MaterialTemplates.zip`, 17 file):
`CharacterTemplate.material`, `NPCnMonsterTemplate.material`, `WeaponTemplate.material`,
`ColourChangableTemplate.material`, `TransparentTemplate.material`, `Character.cg`, `Character.program`,
`ScorpioHardwareSkinning.cg`, `ScorpioHardwareAnimation.{material,program}`, `nm_{bk,dn,fr,lf,rt,up}.png`, `reflect.tga`.

Bản trong mã nguồn (`A\Client\WXCore\MaterialTemplates\`) là biến thể per-pixel:
`PerPixelLighting.{cg,program}`, `PerPixelLightingTemplate.material`, `TransparentTemplate.material`.

**FACT** cấu trúc một template (`PerPixelLightingTemplate.material`), technique `HighTech` gồm 4 pass:

| Pass | Nội dung | Điểm cần nhớ |
|---|---|---|
| `Ambient` | ambient + emissive, xuất alpha để `alpha_rejection greater 128` | `emissiveColor` mặc định `0.275` |
| `DirectionalLighting` | `iteration once_per_light directional`, **`max_lights 2`**, `scene_blend add`, normal cube map `nm.png` | khớp đúng 2 đèn `#FairyMainLightOne/Two` |
| `PointLighting` | như trên cho đèn điểm | đèn điểm đến từ `LightObject` và `PointLightElement` của hiệu ứng |
| `Decal` | nhân texture nền | |

**BẪY (FACT):** template viết sai từ khoá — `specualr 1 1 1` thay vì `specular` (xuất hiện ở cả 3 pass).
OGRE ghi `"Unrecognised command: specualr"` vào log rồi **bỏ qua**
(`A\OGRE\OgreMain\src\OgreMaterialSerializer.cpp:2908`), không báo lỗi. Trước khi kết luận "shader sai",
hãy `grep -c "Unrecognised command" WXRender.log`.

Cơ chế material instance (`A\Client\WXCore\Core\WXMaterialInstance.h`) rất mỏng: mỗi entity giữ một cặp
`origin` + `derived` (bản clone) để chỉnh trong suốt/đổi màu. **0.85 không có tham số per-instance đẩy xuống shader** —
đây chính là khoảng trống mà `P\WXRender\MaterialSystem\CysMaterialSystem.cpp` (1.929 dòng) lấp (mục 16).

---

## 7. Ánh sáng và bóng đổ — nơi 0.85 nghèo nhất

### 7.1 Cấu hình bóng của SceneManager

**FACT** `A\Client\WXCore\Core\WXSystem.cpp:460–477`:

```c
rq->setEnableShadowsForUnregisteredGroup(false);      // mọi nhóm mới: không bóng
// … tắt bóng cho TẤT CẢ nhóm đang có …
rq->getQueueGroup(mSceneManager->getWorldGeometryRenderQueue())->setShadowsEnabled(true);
```

Chỉ hàng đợi *world geometry* (địa hình) tham gia lượt bóng.

### 7.2 Kỹ thuật bóng **chưa bao giờ được bật**

**FACT**: `Scene_SetShadowTechnique` chỉ có một chỗ định nghĩa (`RenderSystem.cpp:1218`) và **không nơi nào gọi**
(`grep -rn "Scene_SetShadowTechnique"` cho ra: khai báo `RenderSystem.h:176`, định nghĩa, và một dòng đã comment ở
`TDGfxSystem.h:273`). Biến `szShadowTechniqueVar = "View_HumanLightmap"` (`RenderSystem.cpp:65`) **không xuất hiện**
trong `_OnVariableChangedEvent` (`RenderSystem.cpp:1097–1168`).

Thêm nữa, hai nhánh của nó bị **đảo ngược** (`RenderSystem.cpp:1218–1225`):

```c
if(bSetting == TRUE)  setShadowTechnique(SHADOWTYPE_NONE);               // bật => TẮT bóng
else                  setShadowTechnique(SHADOWTYPE_STENCIL_MODULATIVE); // tắt => bóng stencil
```

**Kết luận (FACT + INF):** client 0.85 chạy với `SHADOWTYPE_NONE` (mặc định OGRE) suốt vòng đời.
`MeshManager::setEnableAutoBuildAllMeshesEdgeLists(true)` (`WXSystem.cpp:206`) vẫn dựng edge list cho **mọi** mesh
— tốn RAM và thời gian nạp cho một tính năng không bật. Đây là một nguồn lãng phí đo được.

### 7.3 Bóng nhân vật thật ra là decal

**FACT** `A\Client\WXCore\ModelSystem\WXLogicModel.h:70–74`:

```c
enum ModelProjectorType { MPT_SELECTED, MPT_SHADOW /* 地下的简单阴影 = bóng đơn giản dưới chân */ };
```

`WX::Projector` (`A\Client\WXCore\Core\WXProjector.h`) là một `Ogre::Frustum` chiếu texture lên địa hình/vật thể,
có `setTerrainGridLimit`, `setVertexLimit`, `setEnableClipPlanes`, `setQueryMask`. Bóng nhân vật = một vệt đen chiếu
xuống, không liên quan tới hướng đèn. Muốn bóng thật phải làm shadow map — `P\WXCore\CYS\Shadow\` đã làm (mục 16),
đặc tả ở `03-shadows.md` và `shadow-cy_vi.md`.

### 7.4 Chuyển màu đèn theo thời gian

`MainSceneLight` (`A\Client\WXCore\EffectSystem\WXMainSceneLight.cpp`) cho phép hiệu ứng đổi màu **cả hai đèn + ambient**
theo pha `FADEIN → LAST → FADEOUT` rồi trả về màu gốc. Đây là toàn bộ "day/night" của 0.85: không có chu kỳ thời gian,
chỉ có hiệu ứng kịch bản. Hệ thời gian trong ngày thật nằm ở `.EnScene`/EnvKey của client đời sau (`05-scene-features.md`).

---

## 8. Hậu kỳ (PostFilter)

**FACT** `A\Client\WXCore\PostFilter\`: khung bọc `Ogre::Compositor`. Mỗi filter = một `CompositionTechnique`
**dựng bằng C++** (không phải script), cộng các material trong `PostFilter\media\*.material`.

Năm factory đăng ký (`WXPostFilters.cpp`): `HeatVision`, `Bloom`, `Floodlighting`, `Fade`, `MotionBlur`.
**Chỉ `Floodlighting` và `Fade` được tạo thật** (`RenderSystem.cpp:498,501`); `Bloom` và `HeatVision` bị comment.

Ví dụ `Floodlighting` (`WXFloodlightingPostFilter.cpp:49–90` + `media\Floodlighting.material`):

| RT | Kích thước | Format |
|---|---|---|
| `scene` | 1.0 viewport | `PF_X8R8G8B8` |
| `blur0`, `blur1` | 0.5 viewport | `PF_X8R8G8B8` |

Chuỗi pass: `scene` (IM_PREVIOUS) → down-sample ¼ → blur ngang → blur dọc → blend.
Tham số: `blur_amount` (mặc định 0.2), `shine_amount` (0.3).

`Fade` dùng cho hiệu ứng chết: `CRenderSystem::Tick` (`RenderSystem.cpp:640`) chạy `ColourAmount`/`GrayAmount`
từ 0→1 theo bước 5 % mỗi tick.

**Giới hạn (INF, căn cứ mục 2.4):** RT 8-bit, không linear space, không FP16 ⇒ mọi thứ gọi là "HDR/Bloom" trong
0.85 chỉ là blur cộng thêm. Muốn giống CY phải có pipeline compositor mới — đã làm ở
`P\WXCore\CYS\PostFX\` (mục 16), đặc tả `02-postfx.md`.

---

## 9. Hạt và hiệu ứng

- **ParticleFX** (chuẩn OGRE) + **ParticleFX2** của TLBB: `A\ParticleFX2\src\` — thêm
  `PolarEmitter`, `MovementAffector`, `RevolutionAffector`, `ScaleInterpolatorAffector`, `ColourFadingAffector`.
- **Renderer bổ sung** (`A\Client\WXCore\OgreExt\`, đăng ký ở `WXSystem.cpp:236–250`):
  `TexCoordBillboardParticleRenderer` (sprite sheet), `MeshParticleRenderer` (hạt là mesh),
  `RibbonRenderer`/`RibbonSet` (vệt), `MeshRotationAffector`, `MeshAnimationAffector`.
- **EffectSystem**: `Effect` = danh sách `EffectElement` có keyframe. Tám loại element:
  Mesh, Particle, BillboardSet, Beam, AnimationRibbon, PointLight, Projector, AnimationSceneLight (+ Sound).
- `Ogre::ParticleSystem::setDefaultIterationInterval(0.033f)` (`RenderSystem.cpp:514`) — bước mô phỏng hạt cố định 33 ms.

Chín loại element/affector mà client_GL có thêm nằm ở `04-effects-particles.md`; phần đã port ở `P\WXCore\CYS\Effects\`.

---

## 10. Nước, trời, thời tiết

| Thành phần | File | Ghi chú |
|---|---|---|
| Nước | `A\Client\WXCore\Core\WXTerrainLiquid{,Object}.cpp` | `MovableObject` lưới sóng có mô phỏng gợn (`PARAM_C` tốc độ sóng, `PARAM_D` khoảng cách, `PARAM_U` độ nhớt); thuộc tính: `material`, `subdivision`, `texture scale/rotate`, `depth texture layer.{enable,height scale,height adjust}`, `projector name/size` |
| Trời | `WXSkyBoxObject` / `WXSkyDomeObject` / `WXSkyPlaneObject` | bọc trực tiếp `SceneManager::setSkyBox/Dome/Plane` của OGRE |
| Thời tiết | thuộc tính `weather.particle system name` + `weather.render weather` của `Enviroment` | hệ hạt bám theo nhân vật, `Scene_SetEnviromentInfo` đặt vị trí ở `y+300` (`RenderSystem.cpp:840–851`) |

Không có phản chiếu, không có khúc xạ, không có độ sâu nước theo depth buffer trong 0.85 — `depth texture layer`
chỉ là một lớp texture thứ hai lấy toạ độ theo chiều cao. Nước kiểu CY: `water-cy_vi.md` + `P\WXCore\CYS\Water\`.

---

## 11. Camera và nhịp khung hình

**FACT**:

| Giá trị | Nơi | Số |
|---|---|---|
| FOV dọc | `WXSystem.cpp:490,680` | 45° |
| Near / Far clip | `WXSystem.cpp:677–678` | `0.25 × baseScale` / `150 × baseScale` |
| `baseScale` | `WXSystem.cpp:614` | `sqrt(scale.x × scale.z)` — với `scale=100` ⇒ 100 ⇒ near 25, far **15.000** |
| Aspect | `WXSystem.cpp:492` | auto |
| Góc ngẩng cố định | `Camera_Scene.cpp:15` | **−38,5°** |
| Khoảng cách camera | `Camera_Scene.cpp:16–17` | 6 → 14 (mét game) |
| Chiều cao nhìn | `Camera_Scene.h:66` | +0,7 |

Ba hằng số cuối đọc đè được bằng biến `Camera_MinDistance`, `Camera_MaxDistance`, `Camera_Pitch`
(`RenderSystem.cpp:476–485`).

Vòng render: `CRenderSystem::RenderFrame` (`RenderSystem.cpp:640–656`) gọi `Ogre::Root::renderOneFrame()`;
nếu hai khung cách nhau **> 2.000 ms** thì bỏ khung đó và gọi `clearEventTimes()` (chống nhảy vọt sau khi nạp cảnh).
Nhịp khung do `System_MaxFPS` ở tầng game quyết định — đã phân tích và sửa trong `09-performance_vi.md` mục 1.

---

## 12. Tài nguyên

**FACT** `C\Bin\FairyResources.cfg` (mã nguồn gọi là `WXResources.cfg`, `RenderSystem.cpp:373`):

```ini
[Bootstrap]  ../Data/OgreCore.zip*Zip , ../Data/MaterialTemplates.zip*Zip
[General]    ../Data/{Effect,Model,Model2,Model3,Interface,Material..Material5,Sound,Config}Folder*FileSystem
[Brushes]    ../Data/BrushesFolder*FileSystem
[Scene]      ../Data/SceneFolder*FileSystem
```

Tên nhóm trong code (`A\Client\WXCore\Core\WXResources.cpp:13–22`):
`GRAMMAR="Grammar"`, `EDITOR="Fairy Editor"`, `BRUSH="General"`, `SCENE_SCHEMA="WXScene.xsd"`, `TERRAIN_SCHEMA="WXTerrain.xsd"`.

**Chú ý:** `BRUSH_RESOURCE_GROUP_NAME` = **"General"**, không phải "Brushes". Atlas địa hình, texture lightmap và
mọi material địa hình clone ra đều nằm trong nhóm `General`.

`readme.txt` của thư mục template (`A\Client\WXCore\MaterialTemplates\readme.txt`) nêu một ràng buộc thứ tự:
*đường dẫn chứa template phải đứng TRƯỚC đường dẫn chứa material dùng template đó trong FairyResources.cfg.*
Đặt sai thứ tự ⇒ `clone` không tìm thấy material nền ⇒ vật thể trắng.

`.axp` được đọc qua `PakFileSystemArchive` (`A\Client\WXCore\ResourceSystem\WXPakFileSystem.cpp`, 469 dòng),
đăng ký ở `WXSystem.cpp:197–198`.

---

## 13. Bảng điều khiển chất lượng — tám biến `View_*` và sự thật về chúng

**FACT** `A\Client\WXRender\RenderSystem.cpp:59–66` và `1097–1226`:

| Biến | Hằng trong code | Được xử lý? | Việc thật sự làm |
|---|---|---|---|
| `View_ColorQuality` | `sz32BitTexturesVar` | có, và là biến **duy nhất** được áp lúc khởi động (dòng 520) | **`Scene_Enable32BitTextures` có thân rỗng** — dòng gọi `enable32BitTextures` đã bị comment (dòng 1178). Không làm gì cả. |
| `View_TextureFiltering` | `szDefaultTextureFilteringVar` | có (chỉ khi đổi trong game) | 0→BILINEAR/aniso 1; 1→TRILINEAR/aniso 2; 2→ANISOTROPIC/**aniso 8** (dòng 1182–1201) |
| `View_LightmapQuality` | `szLightmapQualityVar` | có (chỉ khi đổi trong game) | `LMQ_NONE/LOW/HIGH` + dựng lại địa hình (dòng 867–891). Bị `Scene_Load` ghi đè về LOW ở mỗi lần đổi cảnh — mục 5.3 |
| `View_ObjectMove` | `szAnimationQualityVar` | có (chỉ khi đổi trong game) | `setAnimationQuality(n*50-50)` ⇒ −50 / 0 / +50 |
| `View_FullScreenLight` | `szPostFilterEnabledVar` | có (chỉ khi đổi trong game) | bật/tắt filter `Floodlighting` |
| `View_Fanhunjiao` | `szFSAAVar` | chỉ lúc khởi động | 0→FSAA 0, 1→**2**, 2→**4**, khác→0 (dòng 428–441) |
| `View_Aplomb` | `szvsyncVar` | chỉ lúc khởi động | `vsync` true/false |
| `View_HumanLightmap` | `szShadowTechniqueVar` | **KHÔNG** | khai báo rồi bỏ đó — mục 7.2 |

`animationQuality` cộng vào `animation level` của từng object (`WXSystem.cpp:798–807`):
`≥100 → AT_FULL`, `≥50 → AT_FROZE`, `<50 → AT_DISABLE`. `AT_FROZE` đóng băng animation ở **một thời điểm ngẫu nhiên**
(`WXStaticEntityObject.cpp:551–562`) — cây cối đứng im ở dáng khác nhau thay vì cùng dáng. `AT_DISABLE` tắt hẳn.

`createLevel` (`WXSystem.cpp:810–830`, mặc định 50): object chỉ được **tạo** khi `createLevel(object) + systemCreateLevel ≥ 50`
(`WXSceneInfo.cpp:256–260`). Đây là cơ chế giảm mật độ vật trang trí theo cấu hình máy — dữ liệu cảnh phải đặt
`create level` thấp cho vật phụ thì nó mới có tác dụng.

Ba file `System.cfg` (`Bin64`, `Bin`, `Accounts`) hợp nhất theo khoá, `Accounts` thắng — xem ghi nhớ
`tlbb-system-cfg-precedence`. `View_LightmapQuality=2` và `View_ColorQuality=2` hiện chỉ có trong `Bin\System.cfg`.

---

## 14. Client đang chạy ≠ engine 0.85 — đừng lẫn hai thứ

**FACT**, bằng chứng trong chính dữ liệu của `C`:

- `C\Data\SceneFolder\Biwuzhaoqin.Terrain` có `<useColorMap>`, `<colorMap>`, `<useColorMapAlphaBlend>` —
  ba thẻ mà `TerrainDataSerializer.cpp` của 0.85 sẽ ném exception khi gặp.
- Cùng file khai báo template `Terrain/OneLayerColorMap`, `Terrain/TwoLayerColorMapAlphaBlend`,
  `Terrain/OneLayerLightmapColorMap`, `Terrain/TwoLayerLightmapColorMapAlphaBlend` — không có trong `FairyTerrain.material` gốc.
- `C\Data\SceneFolder\` có `.EnScene`, `.skysphere`, `.hdr`, `.newhdrbloom` — không loại nào được engine 0.85 đọc.
- `C\Data\SceneFolder\Biwuzhaoqin.Scene` có `<Object type="SceneConfig">`; 0.85 chỉ đăng ký 12 factory và
  **không có** `SceneConfig` (`WXSystem.cpp:295–308`) ⇒ nạp bằng 0.85 sẽ hỏng.
- `C\Data\MaterialTemplates.zip` chứa 114 mục với `Model_Pbr_*.hlsl`, `SSAO.hlsl`, `hdr.hlsl`, `GodRays.hlsl`,
  `AntiAlias.hlsl`, `ShaderLib\CalcShadow.inc` — SM3 + PBR, đời sau 0.85 rất xa.

**Vì vậy:** khi so "sao mình xấu hơn", **mốc so sánh là CY/client_GL**, còn `A`/`D085` chỉ là điểm xuất phát.
Đừng dùng dữ liệu của `C` để kiểm thử engine 0.85 thuần rồi kết luận engine hỏng.

---

## 15. Vì sao bản 0.85 trông "bệt" — danh sách nguyên nhân gốc, xếp theo tác động

Mỗi mục đều là **FACT** có dòng dẫn ở trên; cột "sửa ở đâu" là điểm can thiệp nhỏ nhất.

| # | Nguyên nhân | Bằng chứng | Sửa ở đâu | Công |
|---|---|---|---|---|
| 1 | **Lightmap luôn bị ép LOW** (1/16 texel) và địa hình bị dựng hai lần mỗi lần đổi cảnh | `RenderSystem.cpp:822–823` vs `Terrain.cpp:38–39,776–784` | bỏ ép LOW, đọc `View_LightmapQuality` lúc khởi động | giờ |
| 2 | **Không có bóng đổ nào** — kỹ thuật bóng chưa từng được gọi, lại còn đảo nhánh; bóng nhân vật chỉ là decal | `RenderSystem.cpp:1218–1225`, `grep` không có call site; `WXLogicModel.h:72` | shadow map (`P\WXCore\CYS\Shadow\` đã có) | tuần |
| 3 | **Mặt đất không có per-pixel lighting**, chỉ đèn ở đỉnh × lightmap | `FairyTerrain.cg` | thay 4 material template địa hình | tuần |
| 4 | **Texture mặt đất bị ép 64×64 trong atlas 512×512** | `Terrain.cpp:50–52` | nâng `mAtlasPixmapSize`/`mAtlasTextureSize` (VRAM tăng bậc hai) | ngày |
| 5 | **Hậu kỳ chỉ còn Floodlighting + Fade**, RT 8-bit, không linear/HDR | `RenderSystem.cpp:498–501`, `WXFloodlightingPostFilter.cpp:57–70` | pipeline compositor mới (`CYS\PostFX\`) | tuần |
| 6 | **Mipmap mặc định 5** — texture lớn bị cụt mip, nhấp nháy ở xa | `WXSystem.cpp:329` | đặt theo kích thước texture | giờ |
| 7 | **Lọc texture mặc định không phải aniso** cho tới khi người chơi tự bấm đổi | mục 3 bước 16 + `RenderSystem.cpp:1182` | đẩy thêm biến lúc khởi động | giờ |
| 8 | **`fog_replacement` là mã chết trên D3D9** | `FairyTerrain.program` (`arbfp1`), `TerrainData.cpp:801–838` | chỉ sửa cùng lúc với đường HLSL | — |
| 9 | **`max_lights 2`** — cả cảnh chỉ 2 đèn hướng + ambient | `PerPixelLightingTemplate.material` | EnvKey/nhiều đèn (`05-scene-features.md`) | tuần |
| 10 | **Không SceneManager phân vùng** ⇒ không occlusion; tải nặng phải hạ bằng create level | `WXSystem.cpp:449` | cân nhắc rất kỹ, ảnh hưởng toàn cục | — |
| 11 | Edge list dựng cho **mọi** mesh dù bóng tắt | `WXSystem.cpp:206` | tắt nếu không dùng stencil shadow | giờ |
| 12 | Template vật liệu có từ khoá sai `specualr`, OGRE bỏ qua im lặng | `PerPixelLightingTemplate.material` | sửa chính tả + soát log | phút |

Mục 1, 6, 7, 11, 12 là **năm việc rẻ nhất** và làm được ngay trong một buổi; mục 2, 3, 5 là ba việc nặng
đã có spec riêng.

---

## 16. Phần CY-Source đã làm rồi — đừng làm lại

**FACT**, `P\WXCore\CYS\` (17.150 dòng .cpp) và `P\WXRender\MaterialSystem\`:

| Thư mục | Nội dung | Spec |
|---|---|---|
| `CYS\PostFX\` | `CysPostFxPipeline` (1.081), `CysPostFxFilters` (1.201), `CysPostFx` (991), `CysPostFxStage`, `CysPostFxDepth` | `02-postfx.md` |
| `CYS\Shadow\` | `CYSShadowSystem` (756), Casters/Fitting/Host/Params/Programs/Config | `03-shadows.md`, `shadow-cy_vi.md`, `shadow-finish_vi.md` |
| `CYS\Scene\` | `CYSSkyRenderer` (1.060), `CYSSkyCyRenderer` (924), `CYSEnvironment` (999), `CYSEnvKey`, `CYSEnSceneData`, `CYSSkySphereData`, `CYSWater`, `CYSDynamicBones`, `CYSProjectorObject` | `05-scene-features.md`, `sky-enscene-cy_vi.md` |
| `CYS\Water\` | `CysWaterRender` (680) | `water-cy_vi.md` |
| `CYS\Effects\` | NewRibbonTrail, SequenceFrame, Dissolve, RotationCurve, UIParticle, SkillCameraEffects | `04-effects-particles.md`, `07b/07c/07e` |
| `CYS\Perf\` | `CysPerf` (1.519) — dụng cụ đo | `09-performance_vi.md` |
| `WXRender\MaterialSystem\` | `CysMaterialSystem` (1.929) — ghép vertex program cho template `ps_3_0` của client_GL, biến thể runtime, cache microcode | `01-materials.md` |

Trước khi viết dòng code render nào: `rg` tên tính năng trong `P\WXCore\CYS` và đọc spec tương ứng.
Dùng CodeGraph để tra người gọi/bị gọi (xem `CLAUDE.md` mục công cụ), rồi mới `rg` để chốt dòng.

---

## 17. Quy trình cho agent: dựng → chạy → chụp → đo

**Dựng** (`CY-Source\Tools\build\build.cmd`, cú pháp `ARCH NAME [CONFIG] [COMPS] [TARGET]`):

```bat
Tools\build\build.cmd x64 render-x64 Release "zlib;zziplib;freetype;devil;ogremain;ogre_d3d9;ogre_plugins;scorpio;particlefx2;wxengine;wxcore;wxrender"
```

**BẪY đã sập thật:** đặt tên target vào ô CONFIG (`build.cmd x64 tên cys_wxclient`) khiến `CMAKE_BUILD_TYPE`
thành một kiểu lạ và **mất sạch `/O2` trong im lặng**. Dạng đúng: `build.cmd x64 NAME Release "" cys_wxclient`.
`build.cmd` đã có guard chặn từ 18/09 (đọc chú thích đầu file).

**Chạy và chụp** — bốn công cụ có sẵn trong `CY-Source\Src\Tools\`:

| Công cụ | Dùng để |
|---|---|
| `TlbbViewer` | nạp `.Scene`/model/effect không cần game, camera quỹ đạo, **chụp back-buffer theo bước thời gian cố định** — đây là công cụ so sánh hình ảnh chính (`viewer.cmake`) |
| `OgreSmoke` | kiểm tra OgreMain + D3D9 dựng được cửa sổ và vẽ được |
| `CysPostFxTest`, `CysShadowTest` | kiểm thử riêng từng hệ |
| `CysD3D9Trace` | ghi lại lời gọi D3D9 để đối chiếu với CY thật |

**Đo và ghi bằng chứng:** theo đúng lệ của thư mục này — mỗi phát hiện phải kèm đường dẫn file + dòng, hoặc
ảnh/`.log` trong `Build\Logs\<ngày>-<nhánh>\`. Không có con trỏ tới phép đo thì ghi **INF**, đừng ghi **FACT**
(xem ghi nhớ `cy-source-unmeasured-claims`).

**Luật so sánh** (ghi nhớ `feedback-render-parity-cy`): chuẩn là **CY thật**, không phải "trông đã đẹp hơn".
Mỗi thay đổi phải có cặp ảnh trước/sau cùng cảnh, cùng camera, cùng giờ, cùng độ phân giải.

---

## 18. BẪY — danh sách rút gọn

1. **Mã nguồn là GBK.** Đọc bằng `iconv -f GBK -t UTF-8 -c`, đừng sửa trực tiếp bằng công cụ giả định UTF-8.
2. **`Scene_Load` ghi đè chất lượng lightmap.** Sửa biến trong `System.cfg` không có tác dụng.
3. **Chỉ `View_ColorQuality` được áp lúc khởi động** — và hàm của nó rỗng.
4. **`Scene_SetShadowTechnique` là mã chết và đảo nhánh.** Đừng "sửa lỗi bóng" trước khi kiểm chỗ gọi.
5. **`BRUSH_RESOURCE_GROUP_NAME = "General"`**, không phải "Brushes".
6. **Thứ tự resource path quyết định template có tìm thấy hay không** (`MaterialTemplates\readme.txt`).
7. **Thẻ lạ trong `.Terrain` ⇒ exception**; thẻ lạ trong `.material` ⇒ chỉ ghi log rồi bỏ qua
   (`OgreMaterialSerializer.cpp:2908`). Hai mức nghiêm khắc khác nhau — dấu hiệu nhận ra trong log cũng khác nhau.
8. **Material trùng tên trong `all.material`**: nếu OgreMain chưa có commit `c8ff9a3` thì parser **bỏ toàn bộ phần
   còn lại của file** ⇒ công trình trắng toát. Dấu hiệu một dòng: `scripts … 1 aborted by an exception` và số
   material < 80.000 (xem `cy-look_vi.md` mục 1).
9. **Lightmap sai kích thước bị vứt im lặng** (`TerrainData.cpp:461–469`) — cảnh chỉ tối đi, không có lỗi.
10. **`mLightmapTextureSize` là mã chết.** Đổi nó không ảnh hưởng gì.
11. **Dữ liệu client đang chạy mới hơn engine 0.85** (mục 14). Test engine 0.85 phải dùng `D085`.
12. **`build.cmd`**: `ARCH NAME [CONFIG] [COMPS] [TARGET]` — đặt target vào ô CONFIG là mất `/O2`.

---

## 19. Tra nhanh: câu hỏi → file:dòng

| Muốn biết | Mở |
|---|---|
| Phiên bản OGRE | `A\OGRE\OgreMain\include\OgrePrerequisites.h:86` |
| Plugin nào nhúng tĩnh | `A\OGRE\OgreMain\src\OgreRoot.cpp:995` |
| Toàn bộ trình tự khởi động render | `A\Client\WXRender\RenderSystem.cpp:360–525` |
| SceneManager / camera / viewport | `A\Client\WXCore\Core\WXSystem.cpp:445–508` |
| Cấu hình bóng của hàng đợi vẽ | `A\Client\WXCore\Core\WXSystem.cpp:460–477` |
| Nạp cảnh | `A\Client\WXRender\RenderSystem.cpp:790–838` + `A\Client\WXCore\Core\WXSceneInfo.cpp:236–288` |
| Ambient / fog / màu nền | `A\Client\WXCore\Core\WXEnviromentObject.cpp:167–181, 304–310` |
| Hai đèn chính của cảnh | `A\Client\WXCore\EffectSystem\WXMainSceneLight.cpp:137–192` |
| Atlas + vật liệu địa hình | `A\Client\WXCore\Core\Terrain.cpp:50–55, 601–706` |
| Lightmap địa hình | `A\Client\WXCore\Core\Terrain.cpp:170–235, 753–812` |
| Khai báo đỉnh địa hình | `A\Client\WXCore\Core\TerrainTileOptimized.cpp:86–140` |
| Công thức tô mặt đất | `D085\Scene\FairyTerrain.cg` |
| Thẻ hợp lệ của `.Terrain` | `A\Client\WXCore\Core\TerrainDataSerializer.cpp:86–292` |
| Template vật liệu nhân vật | `A\Client\WXCore\MaterialTemplates\PerPixelLightingTemplate.material` |
| Khung hậu kỳ | `A\Client\WXCore\PostFilter\WXPostFilter.h` + `WXFloodlightingPostFilter.cpp:49–90` |
| Hạt: renderer/affector thêm | `A\Client\WXCore\OgreExt\` + `A\ParticleFX2\src\` |
| Nước | `A\Client\WXCore\Core\WXTerrainLiquid.h:86–118` |
| Hằng số camera | `A\Client\WXRender\Camera\Camera_Scene.cpp:15–19` |
| Biến chất lượng `View_*` | `A\Client\WXRender\RenderSystem.cpp:59–66, 1097–1235` |
| Mô hình link OgreMain của bản port | `CY-Source\Src\cmake\components\ogremain.cmake` (chú thích đầu file) |

---

## 20. Đọc tiếp

`00-INDEX.md` (thứ tự ưu tiên theo tác động hình ảnh) → `01-materials.md` → `02-postfx.md` → `03-shadows.md` →
`05-scene-features.md` → `04-effects-particles.md`.
Bản tiếng Việt đi sâu từng mảng: `cy-look_vi.md`, `shadow-cy_vi.md`, `water-cy_vi.md`, `sky-enscene-cy_vi.md`,
`aa-cy_vi.md`, `colorlut-cy_vi.md`, `d3d9-parity_vi.md`, `09-performance_vi.md`.
Nguồn hành vi chuẩn của CY: `cy-oracle_vi.md` và ghi nhớ `cy-source-cy-oracle`.
