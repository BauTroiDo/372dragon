# 04 — Quy trình mã nguồn, hệ build và port x64

Ngày lập: 2026-09-12. Áp dụng cho các pha E0, E1a, E1b, và cho mọi thay đổi mã về sau. Số liệu lấy từ khảo sát mã nguồn trong tài liệu 01, mục 2.

## 1. Nguyên tắc

1. `CY-Source\Reference` **chỉ đọc**. Mọi thứ chép sang `Src` đều phải có manifest: đường dẫn gốc, SHA-256, mã hoá gốc.
2. `Src` là bản làm việc. Commit đầu tiên chứa mã **nguyên trạng** (chỉ đổi mã hoá), nhờ vậy mọi diff về sau là thay đổi của ta.
3. Không dán mã decompile vào `Src`. Viết lại sạch theo đặc tả (mục 8).
4. Không chạy binary chưa rõ nguồn với quyền quản trị. Server C++ 0.85 chỉ chạy làm hộp cát cục bộ (mục 7).
5. Mỗi thay đổi đi kèm lý do và bằng chứng, như file:dòng hay offset, theo yêu cầu của `CLAUDE.md`.

## 2. Chuẩn bị môi trường (E0)

### 2.1 Cài công cụ (cần người dùng đồng ý, câu hỏi Q5)

```powershell
winget install --id Microsoft.VisualStudio.2022.BuildTools --override "--passive --wait --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.ATLMFC --includeRecommended"
winget install --id Kitware.CMake
winget install --id Ninja-build.Ninja
```

- ATL/MFC chỉ cần cho `Helper.exe`, `Debuger.dll` và `CrashReport.exe`, vốn là các module phụ.
- Windows SDK 10.0.26100 đã có sẵn trên máy.

Kiểm tra sau khi cài:

```powershell
& "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
cmake --version
ninja --version
```

### 2.2 SDK bên ngoài (người dùng tự tải bằng tài khoản của mình)

| SDK | Dùng cho | Đặt ở | Ghi chú |
|---|---|---|---|
| FMOD Core 2.x (Windows) | `tSoundSystem` x64, đọc `.fsb` của B/C | `Src\ThirdParty\_sdk\fmod\` (không commit) | Giấy phép miễn phí cho dự án phi thương mại. Bản A đã dùng FMOD 2.2.35 |
| NVIDIA Cg Toolkit 3.1 (có `lib.x64`) | `CgProgramManager` cho template Cg của dữ liệu 0.85 | `Src\ThirdParty\_sdk\cg\` | Chỉ cần cho hộp cát 0.85. Dữ liệu B/C dùng HLSL. `cg.dll` x64 3.1.0013 có sẵn trong mọi bộ Bin64 |
| D3D9 / D3DX9 | Render system D3D9 | có sẵn trong `…\天龙八部客户端\DirectX9\Include` và `Lib\x64` (có `d3d9.lib`, `d3dx9.lib`, `dxguid.lib`, `DxErr.lib`) | Đặt include của Windows SDK trước, dùng DXSDK chỉ để lấy D3DX9. Runtime `D3DX9_43.dll` có trong Bin64 của B |

### 2.3 git (câu hỏi Q4)

```powershell
git -C C:\TLBB\085\CY-Source init
git -C C:\TLBB\085\CY-Source add .gitignore Docs Src Tools Registry Tests README_vi.md
git -C C:\TLBB\085\CY-Source commit -m "Khởi tạo CY-Source: tài liệu quy trình và khung thư mục"
```

`.gitignore` (đã đặt sẵn) loại trừ `Reference\`, `Assets\` (trừ manifest), `Build\` và `Src\ThirdParty\_sdk\`. Không commit binary hay dữ liệu game.

### 2.4 CodeGraph cho `Src`

Thêm một mục vào `$map` trong `C:\TLBB\085\Tools\Sync-CodeGraphSources.ps1`: nguồn `C:\TLBB\085\CY-Source\Src`, đích `.codegraph-src\cysrc`. Bỏ qua `Src\ThirdParty\boost`, `wxWidgets` và `Xerces\samples`.

Nếu tổng số file vượt 12.000 thì nâng `--max-files` trong `C:\TLBB\085\.mcp.json`. Việc này đổi cấu hình dự án, nên phải hỏi người dùng trước. Không sửa file trong `.codegraph-src`.

## 3. Nhập mã nguồn vào `Src` (E0)

### 3.1 Ánh xạ thư mục

Viết tắt: `R` = `Reference\tlbb085\085\SourceCode`, `K` = `R\Client\天龙八部客户端`.

| Nguồn | Đích | Ghi chú |
|---|---|---|
| `K\Client\WXClient` | `Src\Client\WXClient` | Game.exe |
| `K\Client\WXNetPackets` | `Src\Client\WXNetPackets` | Sau này thêm thư mục `gen\` chứa codec sinh tự động |
| `K\Client\CEGUISystem` | `Src\Client\CEGUISystem` | UI_CEGUI.dll |
| `K\Client\CEGUIFalagardEx` | `Src\Client\CEGUIFalagardEx` | |
| `K\Client\Helper`, `Debuger`, `CrashReport` | `Src\Client\Support\…` | Phụ; làm sau. Không dùng tên `Aux`: Windows cấm (tên thiết bị) |
| `R\Client\Common` | `Src\Shared\Common` | Struct game, gói tin, DBC. Giống 1.052/1.053 file với `R\Server\Common` |
| `K\Client\Common` (35 file `TD*.h`) | `Src\Engine\Interface` | Giao diện tEngine giữa Game.exe và các hệ con |
| `K\Client\WXEngine`, `WXCore`, `WXRender` | `Src\Engine\{WXEngine,WXCore,WXRender}` | tEngine.dll, lõi Fairy, Render.dll |
| `K\OGRE\OgreMain`, `RenderSystems\Direct3D9`, `PlugIns\{OctreeSceneManager,CgProgramManager}`, `PlatformManagers\Win32` | `Src\Engine\OGRE\…` | Bỏ qua `Samples`, `Mac`, `Docs`, `Tests`, `ReferenceApplication`. `RenderSystems\GL` tuỳ chọn |
| `K\ParticleFX2`, `K\Scorpio` | `Src\Engine\{ParticleFX2,Scorpio}` | Scorpio (vải) tuỳ chọn; C đã bỏ nó |
| `K\Client\LuaPlus` | `Src\ThirdParty\LuaPlus` | Lua 5.0.1 có `continue` |
| `K\Client\CEGUI` | `Src\ThirdParty\CEGUI-0.4.1` | |
| `K\{FreeType,expat,tinyxml,Opcode,zziplib,zlib,Devil,Xerces\src}`; phần header cần dùng của `K\boost` | `Src\ThirdParty\…` | Dựng lại từ mã cho x64 |
| `K\SceneEdit`, `K\SndShell` | `Src\Tools\SceneEdit` | Chỉ nhập ở pha E4 |
| `R\Server` | *không nhập*; đọc tại chỗ | Khi cần mới nhập vào `Src\Server085` |

**Loại trừ khi nhập:**
- Thư viện chỉ có file lib: `wxWidgets`, `wxDockIt`, `wxPropGrid`.
- `fmodapi` 3.x, `WXClient\Sound\fmod375`, `SndShell\fmod374`.
- `KeyDog.lib` (không dùng).
- File phụ của IDE: `*.ncb`, `*.suo`, `*.opt`, `*.plg`, `*.aps`.
- Mọi `.lib` x86 dựng sẵn: `OGRE\Dependencies\lib`, `Devil\projects\msvc\extlibs`, `Xerces\Build`.

### 3.2 Chuyển mã hoá

Viết `Tools\pipeline\import_source.py`, dùng cùng thuật toán với `Sync-CodeGraphSources.ps1`:
- Nhận dạng mã hoá từng file theo thứ tự: UTF-8 chặt → GB18030 chặt → GBK → cp1252 dự phòng.
- Ghi lại dạng UTF-8 **có BOM**, giữ nguyên CRLF.
- Ghi manifest vào `Registry\import\source-import-<ngày>.csv` gồm: đường dẫn gốc, SHA-256 gốc, mã hoá gốc, đích.

**Cờ biên dịch bắt buộc:** `/source-charset:utf-8 /execution-charset:.936`.

Lý do: literal tiếng Trung trong mã là **khoá tài nguyên** (tên locator, animation, file, nhóm). Chúng phải giữ nguyên byte GBK như bản gốc (tài liệu 08, mục 1.15). Chữ hiển thị cho người chơi đi qua bảng chuỗi UTF-8, không đi qua literal.

**Kiểm:**
- Sau khi dựng E1a, tìm một literal biết trước (ví dụ `身体受击点`) dưới dạng byte GBK trong `.rdata` của binary vừa dựng.
- So danh sách chuỗi CJK của `Render.dll` tự dựng với `Reference\…\Build\Client\Bin\Render.dll`.

## 4. Hệ build

### 4.1 E1a — Dựng nhanh bằng `.vcxproj` có sẵn (x86)

Tình trạng hiện tại:
- `Client.sln` (VS17) chỉ có Win32 (Debug/Release/Final) và toolset v143.
- 11/16 project có mặt. Thiếu 5: `..\_Scripts\VC7.1\{OgreMain,tinyxml_lib,freetype,expat_static,Opcode}.vcxproj`. Chúng bị `.gitignore` loại khi đóng gói (`*_Scripts`).

Việc cần làm:
1. Tạo lại 5 project đó. Nền để tạo:
   - `K\OGRE\OgreMain\scripts\OgreMain.vcproj` (TargetName "Main" theo `UpgradeLog.htm`).
   - `K\tinyxml\tinyxml_lib.vcproj` (bản này dùng /MT, phải đổi sang /MD).
   - `.dsp` cho expat và Opcode.
   - FreeType chưa có project nào.
2. Dựng theo thứ tự:
   1. zlib, zziplib, FreeType, expat, tinyxml, Opcode
   2. OgreMain (gồm CgProgramManager; OgreMain của A import `cg.dll`)
   3. RenderSystem_Direct3D9, Plugin_ParticleFX2, Plugin_OctreeSceneManager
   4. CEGUIBase, CEGUIFalagard, CEGUIOgreRenderer
   5. LuaPlus
   6. WXEngine (tEngine.dll), WXCore, WXRender (Render.dll)
   7. CEGUISystem (UI_CEGUI.dll), CEGUIFalagardEx
   8. WXNetPackets, WXClient (Game.exe)
3. Tên output của project không trùng tên file chạy. Đặt `TargetName` như sau, rồi kiểm các chuỗi `LoadLibrary`/plugin trong mã cho khớp:

   | Output hiện tại | Tên file chạy |
   |---|---|
   | `WXClient.exe` | `Game.exe` |
   | `WXRender.dll` | `Render.dll` |
   | `UISystem.dll` | `UI_CEGUI.dll` |
   | `UIBase.dll` | `CEGUIBase.dll` |
   | `UIFrame.dll` | `CEGUIFalagard.dll` |
   | "Main" | `OgreMain.dll` |
   | `WXEngine` (lib) | `tEngine.dll` (A/B dựng nó thành DLL) |

4. Dùng các cờ tương thích mà `UpgradeLog.htm` đã ghi: phạm vi biến vòng lặp for, `wchar_t` native, con trỏ hàm thành viên. Giữ `/EHa` cho các file có `__try` (ví dụ `HardwareInfoSystem.cpp`), còn lại dùng `/EHsc`.

### 4.2 E1b — CMake là hệ build duy nhất

- `Src\CMakeLists.txt` gốc, mỗi module một `CMakeLists.txt`; `CMakePresets.json` gồm `x86-release`, `x64-debug`, `x64-release`, `x64-final`; generator Ninja Multi-Config (hoặc "Visual Studio 17 2022" khi cần debug trong IDE).
- Bố cục đầu ra giống game:
  - `Build\Client\Bin64\` và `Build\Client\Bin\` chứa `Game.exe`, `tEngine.dll`, `Render.dll`, `OgreMain.dll`, `RenderSystem_Direct3D9.dll`, `Plugin_ParticleFX2.dll`, `Plugin_OctreeSceneManager.dll`, `CEGUIBase.dll`, `CEGUIFalagard.dll`, `CEGUIOgreRenderer.dll` (dựng dạng DLL như B, không phải lib tĩnh như 0.85), `UI_CEGUI.dll`, `LuaPlus.dll`, `PathLib.dll`, `FMOD`, `cg.dll`.
  - PDB đặt ở `Build\Symbols\<cấu hình>\`.
- Cờ chung:
  - `/MP /Zi /W3 /permissive /Zc:wchar_t /std:c++17`, cộng `/source-charset:utf-8 /execution-charset:.936`.
  - Định nghĩa `_CRT_SECURE_NO_WARNINGS`.
  - Bật cảnh báo cắt con trỏ (C4311/C4312/C4302) thành lỗi trong mã game khi port xong.
- Phiên bản: mọi DLL/EXE có version resource ghi phiên bản CY-Source, hash commit và ngày dựng.

## 5. Danh mục port x64

Số liệu từ lần quét mã ngày 12/09. "Game" gồm các project WX*, CEGUISystem, CEGUIFalagardEx, Debuger, Helper, CrashReport và hai thư mục Common.

| # | Mẫu mã | Game | Bên thứ ba | Server | Ví dụ | Cách sửa |
|---|---|---|---|---|---|---|
| 1 | Inline asm `__asm` / `_asm` | 8 | 80 | 0 | `WXRender\HardwareInfoSystem.cpp:420,443,494,528` (CPUID); `OGRE\OgreMain\include\asm_math.h:28…`; `Opcode\Ice\IceFPU.h` (85) | CPUID → intrinsic `__cpuid`/`__cpuidex`. `asm_math.h` → nhánh C++ (thêm `!defined(_WIN64)` vào điều kiện). IceFPU → C++/SSE2 |
| 2 | `__declspec(naked)` | 0 | 1 (`InvSqrt`, asm_math.h:217) | 0 | | Viết lại bằng C++ |
| 3 | Intrinsic MMX (`__m64`, `_mm_empty`) | 0 | 38 (trong 400 hit SIMD) | 0 | `OgreOptimisedUtilSSE.cpp`, `OgreSIMDHelper.h`, `OgreColourValue.cpp` | Trình biên dịch x64 không hỗ trợ MMX. Thay bằng SSE2, hoặc tạm dùng nhánh thường |
| 4 | `SetWindowLong`/`GetWindowLong` với `GWL_WNDPROC`/`GWL_USERDATA` | 9 | 2 | 0 | `Debuger\RollupCtrl.cpp:202-212`, `CaptionButton.cpp:443`, `OgreD3D9RenderWindow.cpp:50,56` | `SetWindowLongPtr`/`GetWindowLongPtr` với `GWLP_*`; `SetClassLongPtr` |
| 5 | Set/Get(Window/Class)Long khác không có Ptr | 28 | 4 | 0 | | Rà từng chỗ |
| 6 | Ép con trỏ về kiểu 32 bit (dò theo heuristic, có nhiễu) | 186 | 5 | 128 | `OgreSerializer.cpp:378-389` `(long)pData`; `WXCore\Core\WXObjectProxy.cpp:8` | `INT_PTR`/`UINT_PTR`/`uintptr_t`; để cảnh báo C4311/C4312 tìm hết |
| 7 | `(UINT)(` | 28 | 0 | 79 | | Rà từng chỗ |
| 8 | `hash_map` / `stdext::` | 25 | 19 | 5 | `WXClient\stdafx.h:37`, `Object\ActionSetMgr.h:36-38`, `OgrePrerequisites.h:117-126` | MSVC hiện đại chặn `<hash_map>` (lỗi C1189 nếu không định nghĩa `_SILENCE_STDEXT_HASH_DEPRECATION_WARNINGS`), nên thay bằng `std::unordered_map` |
| 9 | `std::auto_ptr` | 8 | 0 | 0 (SceneEdit 8) | `WXCore\Core\TerrainDataSerializer.cpp:341`, `WXSceneSerializer.cpp:267`, `WXXercesParser.cpp:73` | `std::unique_ptr` (C++17 đã bỏ `auto_ptr`) |
| 10 | `_USE_32BIT_TIME_T` | 0 | 0 | 5 | `Server\*\stdafx.h:11`, `ShareMemory\stdafx.h:8` | Không dùng được trên x64. Mọi `time_t` nằm trong struct gói tin hay file đổi sang kiểu cố định 4 byte |
| 11 | `time_t` trong struct chung, ghi bằng `sizeof` | có | — | có | `Common\GameStruct.h:629,688,741,826`, `GameStruct.cpp:1885,1915,2042,2076` | Kiểu cố định. **Lưu ý:** server ép `time_t` 32 bit còn client thì không, nên ngay ở x86 hai bên có thể đã lệch kích thước |
| 12 | `#pragma pack` | 3 | 0 | 3 | `Common\DB_Struct.h:13-1590` (`push,1`) | Giữ nguyên, thêm `static_assert` kích thước |
| 13 | `size_t`/`LONG` nằm trong struct | có | — | — | `Common\GameUtil.h:438`, `BaseType.h:59-60` | Kiểu cố định. `LONG` vẫn 32 bit trên Win64; chỉ lo khi nó được dùng để chứa con trỏ |
| 14 | Gói tin ghi/đọc bằng `sizeof` | 3.009 lần gọi `sizeof(` trong `Common\Packets\*.cpp` | | | | `static_assert` từ số đo x86 (mục 6) |

**Thư viện dựng sẵn chặn x64** (94 file `.lib`: 69 x86, 21 x64, 4 không phải archive COFF):

| Nhóm | Cách xử lý |
|---|---|
| `OGRE\Dependencies\lib` (CEGUI gốc, DevIL/ILU/ILUT, cg, freetype, ode, zdll, zziplib), x86 VC7.1 | Dựng lại từ mã có trong cây. Riêng Cg lấy từ SDK 3.1 x64. CEGUI dựng từ `Client\CEGUI` |
| DevIL extlibs (libjpeg/png/tiff), x86 VC6 | Dựng lại, hoặc thay codec ảnh bằng DirectXTex/stb |
| `Xerces\Build\Win32\VC7.1\xerces-c_2.lib`, x86 | Dựng Xerces-C 2.6 từ `Xerces\src` cho x64. B cũng dùng `xerces-c_2_6.dll` |
| FMOD 3.74/3.75, x86 | FMOD Core 2.x (quyết định D6) |
| wxWidgets/wxDockIt/wxPropGrid, x86 lib, không có mã | Chỉ SceneEdit dùng; để pha E4 |
| `FoxScriptEngine.lib`, `LuaLibDll.lib` (server), không có mã | Hộp cát dùng bản x64 dựng sẵn trong `Reference\…\Build\Server` |
| `DirectX9\Lib\x64` | Có sẵn. Không có `d3d11.lib` (lấy từ Windows SDK khi làm V1) |

## 6. Kiểm ABI: kích thước struct

1. **E1a (x86):** viết `Tests\abi\dump_sizes.cpp`. Tool này include `Src\Shared\Common` và in `sizeof`/`offsetof` của mọi struct nằm trong `Packets\*`, `DB_Struct.h`, `GameStruct*.h` và của các struct định dạng file mà mã engine đọc bằng `sizeof`. Kết quả ghi vào `Registry\abi\struct_sizes_x86.json`.
2. **E1b (x64):** sinh `Src\Shared\Common\abi_asserts.h` gồm các `static_assert(sizeof(T) == N)` từ file JSON. Lệch ở đâu thì sửa kiểu ở đó.
3. **G1:** kích thước gói của giao thức skynet lấy từ đặc tả (tài liệu 06), không lấy từ struct 0.85.

## 7. Hộp cát 0.85 (client tự dựng + server C++ + MariaDB)

- **Nguồn:**
  - Chép `Reference\tlbb085\085\Build\Server` sang `CY-Source\Build\Server\Sandbox085`; không chạy ngay trong `Reference`.
  - Dữ liệu client lấy từ `Reference\…\Build\Client\Data`.
  - Script môi trường: `Reference\…\环境_v0-85-9602_Win\Install-TLBB-Environment-x64.ps1`. Script này cài MariaDB 10.11.18, ODBC 3.2.9 và DSN hệ thống, rồi nạp `tlbbdb.sql` và `web.sql`. Cần quyền quản trị, và người dùng phải duyệt.
- **Xung đột cổng:**
  - MariaDB mặc định nghe 3306.
  - Tool của server WSL vẫn thử MySQL tại 127.0.0.1:3306 (lỗi baseline ghi trong `AGENTS.md`). Nếu WSL chạy chế độ mạng mirrored thì Tool có thể nối nhầm vào MariaDB của hộp cát.
  - Cách tránh: đặt MariaDB của hộp cát ở cổng khác (ví dụ 3307) và sửa DSN theo, hoặc chỉ bật hộp cát khi cần.
  - Login server 0.85 nghe 127.0.0.1:14400 (theo `Patch\LoginServer.txt` mà `单机点我启动客户端.bat` ghi ra), không trùng các cổng 5733/5734/6002 của skynet.
- **Chạy:** dùng `Build\Client\Bin64\Game.exe -fl`, thư mục làm việc là Bin64, cùng `LoginServer.txt` trỏ tới 127.0.0.1:14400.
- **An toàn:**
  - Chỉ nghe trên localhost.
  - Không mở cổng ra LAN.
  - Phần mềm diệt virus có thể xoá exe server cũ. Chỉ thêm ngoại lệ cho thư mục của hộp cát và chỉ khi file có nguồn tin cậy.

## 8. Quy trình "dịch ngược làm đặc tả"

Dùng cho mọi tính năng mà B/C có nhưng mã 0.85 thiếu. Mỗi tính năng là một gói việc:

1. **Chọn tính năng và đo mức dùng.** Ví dụ affector `Dissolve`. Số lần dữ liệu dùng nó lấy từ `Docs\evidence\assetinv\fxkeys.json`.
2. **Tìm trong B/C.**
   - Chuỗi và RTTI: `Docs\evidence\binlineage\rtti.json`, `strscan.json`.
   - Project Ghidra: `analysis\graphics-overhaul\ghidra\proj\gfx.gpr` (Render.dll + Game.exe của B), `analysis\ghidra\headless-projects\cegui.gpr`, `pathlib.gpr`.
   - Ghi lại module, hash, RVA, xref.
3. **Viết đặc tả** vào `Docs\specs\<module>\<tính-năng>.md`: cú pháp dữ liệu, tham số, thuật toán (pseudo-code), hằng số, tương tác với phần khác, các ca thử lấy từ dữ liệu thật (tên effect/model dùng tính năng đó), và mức chắc chắn.
4. **Hiện thực** trong `Src`: viết sạch theo phong cách của mã xung quanh. Không chép mã decompile.
5. **Đối chứng:** Viewer của ta so với `client_GL` trên cùng model/effect/cảnh và cùng camera. So ảnh và log (tài liệu 07).
6. **Đóng gói việc:** cập nhật đặc tả (đạt, hay còn khác ở đâu), commit, thêm ca thử vào bộ đối chứng.

**Quy tắc:**
- Phân tích tĩnh trước.
- Không gắn debugger vào client khi người dùng đang chơi.
- Mọi kết luận phải có offset/RVA hoặc xref; tên hàm hay pseudo-code do mô hình đoán thì chưa phải sự thật.
- Trước khi dùng ReVa MCP phải kiểm kết nối (phiên 12/09 bị CONNECT_TIMEOUT).

## 9. Chuyển các bản vá binary thành tính năng mã nguồn

Danh sách đầy đủ ở tài liệu 08, mục 10. Nơi làm trong `Src`:

| Nhóm | Nơi làm (theo mã 0.85) | Ghi chú |
|---|---|---|
| Cửa sổ Unicode, nhập codepoint, tiêu đề | Chỗ tạo cửa sổ và vòng thông điệp của `WXClient` (tìm `CreateWindow`/`PeekMessage` trong `Src\Client\WXClient`); `CEGUIBase` (`injectChar`) | Bỏ được 4 bản vá import + hook `SetWindowLongPtrW` |
| Code page UTF-8, resolver `#{KEY*args}` | `Src\Client\CEGUISystem` (lớp chuỗi và font) | Bỏ được 3 bản vá của UI_CEGUI |
| District code page | Phần đọc bảng `System_District` trong `WXClient` | Bỏ bản vá 0x97CD84 |
| ActionSetLine nhiều ô | `Src\Client\WXClient\Object\ActionSetMgr.*` | Số ô đọc theo số cột của bảng, không cố định 11 hay 15 |
| Bóng, HDR, anisotropy | `Src\Engine\WXRender` (cấu hình render, post-filter) | Bật theo cfg khi khởi động |
| Giới hạn chuỗi trong gói | Codec sinh từ đặc tả (G1) | Kiểm biên thay vì để crash |

## 10. Thí nghiệm tuỳ chọn H0: module tự dựng dưới Game.exe của B

- **Mục đích:** xem có đi tắt tới M3 được không, bằng cách chạy Render.dll tự dựng dưới Game.exe của B.
- **Bước 1 (chỉ ghi vết):** dựng một DLL proxy tên `Render.dll`. Proxy nạp `Render_orig.dll`, bọc đối tượng giao diện, rồi ghi slot nào trong 188 slot được gọi và bao nhiêu lần trong một phiên chơi. Proxy chỉ chuyển tiếp, không tạo hay huỷ đối tượng STL, nên dựng bằng VS2022 vẫn được.
- **Điều kiện đi tiếp sang thay thế thật:** hoặc các slot đang dùng không truyền `STRING`/`std::list` qua ranh giới, hoặc có toolset VS2012 (v110) để dựng phần ghép.
- **Nơi làm:** chỉ trên bản sao `CY-Source\Build\H0\` của `client_GL`, không bao giờ trên `client_GL` thật, và không chạy khi người dùng đang chơi.

## 11. Chuẩn mã và kiểm soát thay đổi

- **Phong cách:** theo mã xung quanh (tiền tố kiểu Hungary, macro kiểu `VOID`/`INT` của TLBB). Chú thích mới viết tiếng Việt có dấu hoặc tiếng Anh, thống nhất trong từng module. Giữ nguyên chú thích gốc tiếng Trung (đã chuyển UTF-8).
- **Commit:** `[module] mô tả ngắn`, thân ghi lý do, bằng chứng và cách đã kiểm.
- **Nhánh:** `main` luôn dựng được; việc mới làm trên `feature/<pha>-<việc>`.
- **Kiểm tra:**
  - `/code-review` trên diff.
  - `/analyze` cho module vừa đổi.
  - Định kỳ chạy ASan với bản x64 debug.
  - Minidump khi crash (CrashReport x64), symbol ở `Build\Symbols`.
- **Log:** Fairy/Game/CEGUI log xoay vòng theo phiên, không xoá log cũ (bỏ hành vi xoá log của bản gốc).
