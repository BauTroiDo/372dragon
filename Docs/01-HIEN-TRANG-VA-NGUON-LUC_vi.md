# 01 — Hiện trạng và nguồn lực (khảo sát ngày 12/09/2026)

**Phương pháp.** Năm nhánh khảo sát chạy song song:
1. mã nguồn 0.85;
2. ba dòng binary 64-bit;
3. kho tài sản;
4. server;
5. kiến thức và công cụ tích luỹ.

Cộng thêm các phép đo trực tiếp: khoảng cách API Lua, bảng import, kích thước vtable, kiểu tham số của các giao diện `TD*.h`.

Toàn bộ là phân tích tĩnh; không exe/DLL nào được chạy. Ký hiệu: **(DK)** = dữ kiện đo được, **(SL)** = suy luận. Bằng chứng gốc nằm ở `Docs\evidence\`.

## 1. Mười dữ kiện quyết định

1. **(DK)** `Reference\…\SourceCode` là mã 0.85 thuộc dòng engine **WX** (tiền thân của Fairy): OGRE 1.2.5 "Dagon", CEGUI 0.4.1, Lua 5.0.1 (LuaPlus, có từ khoá `continue`). Project chỉ khai báo Win32 (toolset v143) và thiếu 5 trên 16 project.
2. **(DK)** Bản x64 trong `Reference\…\Build\Client\Bin64` **không** dựng từ cây mã này. PDB trỏ về `H:\TLBB\Temp_Release_v0-85-9602\Prj\GameCode\…\VS2017_X64`; thời điểm link là 30/08–03/09/2026, trên một máy khác. Cây mã đó (có D3D11, PathLib, FMOD 2.2) ta không có.
3. **(DK)** `client_GL` (gọi là B) và CY 3.71 (gọi là C) cùng một dòng **Fairy hiện đại**, dựng bằng VS2012. Export của OgreMain trùng nhau hoàn toàn (Jaccard 1,000); Render.dll của hai bản import 1.403 và 1.408 hàm OgreMain.
4. **(DK)** Cả A, B và C lúc chạy đều dùng **D3D9 với SM3.0**. `RenderSystem_Direct3D11.dll` có mặt nhưng không được nạp (log Fairy của từng bản).
5. **(DK)** Server skynet đang chạy nói giao thức của B, **không phải 0.85**: 24/24 ID mẫu lệch số, khoảng 200 gói chỉ có ở skynet, bố cục trường phần lớn khác.
6. **(DK)** Ở cả 3 dòng, Game.exe **không import OgreMain**. Mọi thứ đồ hoạ đi qua Render.dll: vtable của B có 188 slot, của 0.85 khoảng 54.
7. **(DK)** API Lua: 1.201 script UI của `client_GL` gọi **2.698** hàm host. Mã 0.85 chỉ có **513** trong số đó (19 %).
8. **(DK)** Mọi nguồn họ Ogre dùng cùng định dạng tài sản: mesh v1.40 (một phần v1.30), skeleton v1.10 cộng chunk 0x4120 (94–97 %), DDS DXT1/DXT3. Không có BC5 hay BC7.
9. **(DK)** B đọc được mọi tính năng dữ liệu của S1–S4. Mã 0.85 thiếu:
   - 9 kiểu effect/skill, được dùng 5.653 lần trong dữ liệu CY;
   - `.dynbone`, `.hfog`, EnScene, `.godrays`, `.skysphere`, HDR;
   - shadow map, 25 post-filter;
   - template SM3.
10. **(DK)** Có hai bố cục bảng: **HJ** (`client_GL` = CYHJ = server: EquipBase 101 / MonsterAttrEx 71 / PetAttr 51 cột) và **CY/JD** (DataCY = CY Game: 103 / 73 / 54 cột).

## 2. Mã nguồn 0.85 trong `Reference`

### 2.1 Bố cục

| Thư mục | Nội dung | Quy mô |
|---|---|---|
| `Reference\tlbb085\085\SourceCode\Client` | Client + engine + thư viện bên thứ ba | 16.559 file / 336,6 MB |
| `…\SourceCode\Server` | Server C++ 5 tiến trình | 2.078 file / 7,8 MB |
| `…\Build\Client` | Client 0.85 dựng sẵn: `Bin` (x86, build 8130) và `Bin64` (x64, build 9602), `Data` | 23.231 file / 1,52 GB |
| `…\Build\Server` | Server x64 dựng sẵn (`Public`, `Server`, `run.bat`) | 8.018 file / 229 MB |
| `…\Build\GM工具` | TlbbGmTool (.NET, MySqlConnector) | 17 file |
| `…\环境_v0-85-9602_Win` | MariaDB 10.11.18, MariaDB ODBC 3.2.9, `tlbbdb.sql`, `web.sql`, script cài/sao lưu | 18 file / 99 MB |
| `Reference\tlbb085\085.zip` | Bản nén của thư mục `085` | 1,0 GB |

### 2.2 Các thành phần của client

Viết tắt `K` = `SourceCode\Client\天龙八部客户端`.

| Thành phần | Thư mục | Ra file chạy | Ghi chú |
|---|---|---|---|
| WXClient | `K\Client\WXClient` (701 file) | Game.exe | Logic game, gói tin, UI data pool, script. 742 lần đăng ký hàm Lua trong `Script\GMScriptSystm.cpp` (636 tên khác nhau) |
| WXEngine | `K\Client\WXEngine` | tEngine.dll (0.85 dựng thành lib tĩnh) | Microkernel `tKernel`/`tNode`; giao diện nằm ở `K\Client\Common\TD*.h` |
| WXCore | `K\Client\WXCore` (253 file) | (lib) | Lõi WX/Fairy: Scene, Terrain, EffectSystem, ModelSystem, PostFilter, MaterialTemplates |
| WXRender | `K\Client\WXRender` | Render.dll | Lớp render, cấu hình, phần cứng |
| WXNetPackets | `K\Client\WXNetPackets` | (lib) | Handler gói phía client |
| CEGUISystem | `K\Client\CEGUISystem` | UI_CEGUI.dll | 22 lớp control Lua với 94 hàm (`UILuaControl.cpp`) |
| CEGUI 0.4.1, CEGUIFalagardEx | `K\Client\CEGUI`, `CEGUIFalagardEx` | CEGUIBase/Falagard/OgreRenderer | |
| LuaPlus | `K\Client\LuaPlus` | LuaPlus.dll | Lua 5.0.1 có `continue` (`src\llex.c:51`, `lparser.c:1419`) |
| OGRE 1.2.5 "Dagon" | `K\OGRE` | OgreMain + RenderSystem_Direct3D9 / GL | Chỉ có D3D9 và GL, **không có D3D11** |
| ParticleFX2, Scorpio | `K\ParticleFX2`, `K\Scorpio` | plugin | Scorpio là vải; C đã bỏ nó |
| SceneEdit (FairyEditor) | `K\SceneEdit` | trình biên tập cảnh | wxWidgets 2.6.1 chỉ có lib x86 |
| Bên thứ ba khác | boost, Devil 1.6.7, DirectX9 (Include + Lib x86/x64), expat, fmodapi 3.x, FreeType, Opcode, tinyxml, Xerces 2.x, zlib, zziplib | | |
| **Không có mã** | PathLib, RenderSystem_Direct3D11, RSSParser, OgreMeshUpgrade | | PathLib phải viết lại |

### 2.3 Solution và project

- `K\Client\Client.sln` định dạng 12.00 (VS 17). Chỉ khai báo `Debug|Win32`, `Release|Win32`, `Final|Win32`. Toolset v143, MBCS, CRT `/MD`.
- 11/16 project có mặt. **5 project thiếu**, đều nằm dưới `..\_Scripts\VC7.1\`: OgreMain ("Main"), tinyxml_lib, freetype, expat_static, Opcode. Thư mục `_Scripts` bị `.gitignore` loại khi đóng gói. Có vài bản thay thế một phần: `OGRE\OgreMain\scripts\OgreMain.vcproj`, `tinyxml\tinyxml_lib.vcproj` (dùng /MT), và file `.dsp` cho expat và Opcode.
- `UpgradeLog.htm`: 0 lỗi, 173 cảnh báo, 76 thông báo. Đáng chú ý: 70 lỗi MSB8012 (OutputFile lệch TargetPath), thiết lập phạm vi vòng for, `wchar_t` native, và 3 chỗ `/EHsc` đổi thành `/EHa`.
- Tên output lệch với tên file chạy: WXClient.exe → Game.exe; WXRender.dll → Render.dll; UISystem.dll → UI_CEGUI.dll; UIBase.dll → CEGUIBase.dll; UIFrame.dll → CEGUIFalagard.dll.

### 2.4 Dữ kiện engine (có file:dòng)

| Chủ đề | Dữ kiện |
|---|---|
| OGRE | 1.2.5 "Dagon" (`OGRE\OgreMain\include\OgrePrerequisites.h:86-89`); có vài file thời OGRE 1.4 được đưa ngược vào (SSE, SIMDHelper) |
| Mesh | Ghi `[MeshSerializer_v1.40]`; đọc v1.30/v1.20/v1.10 (`OgreMeshSerializerImpl.cpp:59,2387,2613,2770`) |
| Skeleton | `[Serializer_v1.10]`; chunk **0x4120** (`OgreSkeletonFileFormat.h:88`; đọc ở `OgreSkeletonSerializer.cpp:495`, ghi ở 548–580) |
| Effect / skill | `WXCore\EffectSystem\WXEffectManager.cpp:106-107, 578 (effect), 601 (element), 656 (skill)` |
| `.obj` | `WXCore\ModelSystem\WXLogicModelManager.cpp:126`; các mục Attributes 204, EntityList 245, MaterialList 284, Locators 323, Effects 421, Skeleton 507 |
| Terrain / Scene | `WXCore\Core\TerrainData.cpp:907,927`, `TerrainDataSerializer.cpp`, `WXSceneSerializer.cpp:136,267` |
| Post-filter | Chỉ có 5: Bloom, Fade, Floodlighting, HeatVision, MotionBlur (`WXCore\PostFilter\`, shader Cg). **Không có HDR hay FXAA** |
| Bóng | Stencil shadow của OGRE (`WXRender\RenderSystem.cpp:1222-1224`) |
| Template material | `WXCore\MaterialTemplates\`: Cg vs_1_1/ps_2_0 |
| Chọn render system | `RenderSystem.cpp:391-411` gọi cứng `loadRenderPlugins_D3D9()`, nhánh `Gfx_API` bị chú thích bỏ |
| Tìm đường | Client đọc `.region` (`WXClient\World\Scene.cpp:587,652`); không có mã PathLib |

### 2.5 Rủi ro khi port x64

| Mẫu | Mã game | Bên thứ ba | Server |
|---|---|---|---|
| Inline asm | 8 | 80 | 0 |
| MMX intrinsic (không có trên x64) | 0 | 38 | 0 |
| `SetWindowLong` với GWL_WNDPROC/USERDATA | 9 | 2 | 0 |
| Ép con trỏ về 32 bit (dò theo heuristic) | 186 | 5 | 128 |
| `hash_map`/`stdext` | 25 | 19 | 5 |
| `std::auto_ptr` | 8 | 0 | 0 |
| `_USE_32BIT_TIME_T` | 0 | 0 | 5 |
| Gói tin ghi/đọc bằng `sizeof` | 3.009 lần gọi `sizeof(` trong `Common\Packets` | | |
| `.lib` dựng sẵn chỉ có x86 | 69/94 (OGRE Dependencies, DevIL, Xerces, wxWidgets, FMOD 3.x, FoxScript server) | | |

Chi tiết và cách sửa: tài liệu 04, mục 5. Hiện chưa có dấu vết nào của một bản port x64 trong cây này: các chỗ `_WIN64` duy nhất nằm trong header của fmod và glew.

### 2.6 Server C++ 0.85

- `SourceCode\Server\Server.sln` (VS17) gồm 5 project: Billing, Server, Login, ShareMemory, World. Toolset v143, MBCS, `/MT`, x86.
- Truy cập DB qua ODBC (`ODBCInterface.cpp:45-61`).
- 456 lớp gói tin; 483 ID trong `PacketDefine.h`.
- Script chạy trên `FoxScriptEngine.lib`/`LuaLibDll.lib` (x86), **không có mã nguồn**.
- `Build\Server` chứa bản x64 dựng sẵn bằng linker 14.51 (`server-vs2026-x64`), cùng `FoxScriptEngine.dll` và `LuaLib.dll` x64.
- Bố cục: `Server\Config` (113 file), `Public\Config` (92 bảng), `Public\Data\Script`, `Public\Scene` (244 `.scn`, 234 `.path`, 231 `.nav`…).

## 3. Ba dòng binary 64-bit

| | A (Reference Build) | B (client_GL) | C (CY Game 3.71) |
|---|---|---|---|
| Game.exe | 3.423.232 B | 10.940.960 B | 18.591.776 B |
| Nguồn dựng (PDB) | `H:\TLBB\Temp_Release_v0-85-9602\…\VS2017_X64` | `D:\TLBB\Temp_Release_v0-08-0101` + `E:\Fairy_TLBB_Truck` | `D:\TLBB\Temp_Release_v3-71-9001` + `D:\Fairy_New` |
| Trình dịch / CRT | VS2017 (14.16), UCRT | VS2012 (11.0), msvcr110 | VS2012, msvcr110 |
| OgreMain (số export) | 7.319 | 8.053 | 8.053 (trùng B 100 %) |
| RTTI Render.dll | 86 lớp | 174 lớp | 178 lớp (chứa cả 174 của B) |
| RTTI Game.exe | 1.212 | 2.088 | nhiều hơn B 2.844 (1.330 lớp `Packets`) |
| Render system đang chạy | D3D9 SM3 | D3D9 SM3 | D3D9 SM3 (đã có dò tìm D3D11) |
| Post-filter | 5 | 29 compositor (27 có factory + HDR cũ + SceneRender), gồm GenSSAO, DoF | như B |
| Bóng | không có | shadow map + CSM + PCF | như B + `setShadowMapSize` |
| Effect element | 9 | 12 (thêm RibbonTrail, CameraShake, Line) | 12 |
| Affector mới | — | RevoluMove, Dissolve, SequenceFrame, PolarMove, UvAnim | như B (+ tham số `dissolveBox`) |
| Template material | 17 file Cg SM1–2 | 114 file HLSL SM3 (PBR, dissolve, AA, CSM) | 114 file (108 trùng CRC với B) |
| Định dạng texture | DXT1–5, float | + ATI1/ATI2, INTZ | như B |
| UI | CEGUI 0.4.1 + TinyXML | CEGUI 0.4.1 mở rộng + xerces 2.6 | + 658 export Falagard (MultiColumnListNew/Ex, ActionButtonWindow, ScrollText, CircleProgress…) |
| Lua | 5.0.1 | 5.0.1 (LuaPlus bên thứ ba, VS2022, có lớp SuperHook) | 5.0.1 |
| Đóng gói | `Zip=` / `AxpFileSystem=` | `Mem=`/MemLoadManager + AXP; `ccore.dat`, `ndata.dat` | như B + khe Model4–8/Material6–8/Scene2 |
| Âm thanh | FMOD 2.2.35 | FMOD 1.10 (`.fsb`) | tNewSoundSystem, CRFSound |

- **Nguồn gốc của A (DK):** thời điểm link trong PE là 30/08–03/09/2026. Mọi file có mtime 2025-04-07 14:28, là mtime đã bị chuẩn hoá khi đóng gói. `Fairy.log` ghi "AMD Ryzen 7 3700X". `bin64-manifest.txt` không khớp với file đang có.
- **Các bản vá của ta trong B (DK, diff với bản sao lưu):**
  - Render.dll: 75 byte khác.
  - Game.exe: section `.phai25`, bản vá ActionSetLine 133 byte, import A→W, code page District, tiêu đề.
  - UI_CEGUI: 7 byte code page.

  Danh sách đầy đủ ở tài liệu 08, mục 10.

## 4. Ranh giới module và giao diện

Bảng import: tài liệu 02, mục 2. Tóm tắt:
- Game.exe chỉ import tEngine, LuaPlus, fmod và DLL hệ thống.
- Render.dll import OgreMain (B: 1.403 hàm), tEngine (31) và PathLib (6).
- UI_CEGUI import CEGUIBase (241), LuaPlus (35), tEngine (17), OgreMain (20).

**Giao diện `TD*.h` (DK):** `TDGfxSystem.h` có 42 hàm ảo, 17 trong đó có tham số chuỗi hoặc STL; `TDUISystem.h` 49 (23); `TDObjectSystem.h` 63 (14); `TDSound.h` 21 (5); `TDWorldSystem.h` 15, trong đó có `std::list<MAP_POS_DEFINE>*`; `TDNode.h` trả `const STRING&` và `std::list<tNode*>&`. `STRING` là `std::string` (`TDBasicType.h`). Hệ quả: module ở hai bên ranh giới phải cùng CRT/STL.

## 5. Khoảng cách từ mã 0.85 lên B (đo được)

| Hạng mục | 0.85 | B | Bằng chứng |
|---|---|---|---|
| API Lua (hàm host mà script UI gọi) | 746 tên đăng ký; 513 trong đó được UI hiện tại dùng | 2.698 (2.515 nằm trong Game.exe, 183 chỉ ở UI_CEGUI); **thiếu 2.185**, cùng 575 hàm toàn cục | `Docs\evidence\lua_api_gap.json`, `lua_api_gap_methods.tsv` |
| Số hàm thiếu theo đối tượng gọi | — | DataPool 489, Pet 276, Exterior 156, Player 106, LifeAbility 96, PlayerPackage 74, Guild 47, PlayerShop 47, SystemSetup 45, City 45, ItemBar 43, GuildLeague 43, TargetPet 43, GameProduceLogin 38, Talk 35, Raid 33, SuperTooltips2 33, SuperTooltips 32, CachedTarget 30, Auction 29 | như trên |
| CY 3.71 có sẵn các hàm B cần | — | 1.873/2.698 tên xuất hiện trong binary của C | như trên |
| Giao thức | 162 CG / 216 GC; header 8 byte (XOR); phiên bản 5 | 208 + 8 CG / 256 + 8 GC; header 6 byte; 0x785 | tài liệu 06 |
| Giao diện render | khoảng 54 slot | 188 slot | `Docs\evidence\vtable_size.py` |
| Control UI của Lua | 22 lớp / 94 hàm | 36 lớp / 175–183 hàm | |
| Kiểu effect/skill | thiếu 9 kiểu | đủ | `Docs\evidence\assetinv\fxkeys.json` |
| Hậu kỳ / bóng / template | 5 / stencil / Cg SM1–2 | 30 + SSAO + DoF / CSM / HLSL SM3 ×114 | `Docs\evidence\binlineage\` |

## 6. Server (tóm tắt; chi tiết ở tài liệu 06)

- Skynet có 4 tiến trình và chỉ chạy khu 1. MongoDB 4.4.31 chỉ nghe localhost. MQTT dùng làm kênh quản trị.
- Server nạp 790 scene, cần khoảng 75 giây.
- Giao thức: 482 + 16 ID; dây mã hoá UTF-8. Giới hạn chuỗi đã đo (tên 30 B, GCNewPlatform 1–31 B, GCPrivateInfo ≤ 34 B…).
- Bảng server phải GBK; ID lệch sẵn với client (EquipBase 948 dòng chỉ có ở server…). Chỉ một số bảng reload được; phần còn lại phải restart.
- `Game_2` có 3.855 script.
- tlbb15 là server C++ Linux bị hook, tắt ASLR, bảng bố cục HJ. Không dùng.

## 7. Kho tài sản (tóm tắt; chi tiết ở tài liệu 05)

| Nguồn | Quy mô | Ghi chú chính |
|---|---|---|
| S1 `client_GL\Data` | 81.114 file / 15,95 GB | Gốc của kho chuẩn; 378 bảng DBC + 53 bảng text |
| S2 DataCY31-08-26 | 108.847 file / 21,44 GB | ≈ JD 3.71 giải sẵn; đệm 0 ở cuối file; chỉ nó có 7.368 mục model mà AXP bọc kiểu 1–18 |
| S3 CYHJ091026 | 75.536 file / 13,48 GB | Bố cục HJ; biến thể `hj2026` |
| S4 CY Game Data | 23 `.axp` / 108.726 mục / 21,67 GB | Đọc được chỉ mục; `.xzip` là bản vá riêng đã áp sẵn |
| S5 TLGL_extracted | 120.934 file / 10,02 GB | Engine khác; dùng được ảnh UI và model (qua bộ chuyển) |
| S6 DIY / TTrangNew / trâu / bộ cài XTLBB | — | Gói lẻ |
| S7 dữ liệu 0.85 (Reference) | 22.791 file / 1,40 GB | Chỉ dùng cho hộp cát |

Không có khoảng trống nào về template hay từ khoá effect giữa S1 và S2/S3/S4. S2/S4 có dùng thêm khe texture `envTexture`, `MaskTexture`, `DTexture0–2`, `DNTexture0–2`.

## 8. Công cụ (tóm tắt; chi tiết ở tài liệu 09)

Đã có sẵn:
- chuỗi model ⇄ glTF khứ hồi đúng từng byte (`Tools\model-convert`);
- đường ống bản đồ (`Tools\map-convert`);
- bộ giải client GL (`Tools\DATA NEW\DIY`);
- đọc/ghi AXP (`Tools\AXPDecryptor`);
- bộ kiểm toàn vẹn (`analysis\full-audit-2026-09-10`);
- client giao thức headless (`Tools\stress-test\tlbb_sim`);
- 8 project Ghidra đã phân tích;
- CodeGraph.

Còn phải viết mới: pipeline hợp nhất, Registry, bộ sinh đặc tả và codec giao thức, bộ đối chứng hình ảnh.

## 9. Máy và môi trường (đo ngày 12/09)

| Mục | Giá trị |
|---|---|
| Phần cứng | Xeon E5-2696 v3 · 31,9 GB RAM · NVIDIA RTX 2060 |
| Hệ điều hành | Windows 11 IoT Enterprise LTSC 2024 (10.0.26100) |
| Dung lượng trống | C: 418,8 GB · D: 757,9 GB · E: 2.151,6 GB |
| Đã có | Git, Python 3.13 (`C:\Program Files\Python313`), LLVM 22 (có `clang-cl`), Java 21 (Temurin), Ghidra 12.1.3, Blender 5.2, Windows SDK 10.0.26100, CodeGraph 0.20.1 |
| **Chưa có** | MSVC (VS Build Tools), CMake, Ninja, DirectX SDK June 2010 (không bắt buộc: cây mã có sẵn thư viện D3D9/D3DX9 x64), FMOD Core SDK, Cg Toolkit 3.1; `texconv` có trong `Tools\texture-upscale` nhưng không nằm trên PATH |
| MCP | CodeGraph hoạt động; **ReVa không kết nối được** (CONNECT_TIMEOUT) trong phiên 12/09 |

## 10. Bằng chứng

| Tệp | Nội dung |
|---|---|
| `Docs\evidence\lua_api_gap.py`, `.json`, `lua_api_gap_methods.tsv` | Đo khoảng cách API Lua (1.201 script; 2.698 / 513 / 2.185) |
| `Docs\evidence\vtable_size.py` | Đếm slot vtable của Render.dll (B: 188) |
| `Docs\evidence\binlineage\` | Kiểm kê PE, so export, RTTI, chuỗi, zip template của A/B/C (`inventory.tsv`, `expcmp.txt`, `rtti.json`, `strscan.json`, `ziplist.json`, `patchdiff.py`…) |
| `Docs\evidence\assetinv\` | Kiểm kê tài sản: `fullscan.json` (phiên bản mesh/skeleton, DDS), `fxkeys.json` (template, từ khoá effect), `axp_index.py`/`.json` + `axplist_*.txt` (chỉ mục 23 file AXP), `inv_*.json`, `formats_*.json`, `tlb15cmp.py` |
| `Assets\Sources\manifests-2026-09-12\files_*.tsv` | Danh sách file của từng nguồn (S1–S7) |
