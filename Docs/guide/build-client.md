# Build client Windows x64

[← Tài liệu](README.md) · [Dựng server →](server-setup.md)

Hướng dẫn đối chiếu với `Src/CMakeLists.txt`, `Src/cmake/CYSCommon.cmake` và
`Tools/build/build.cmd`. Chưa chạy trọn vẹn trên máy sạch trong đợt chuẩn bị repository.

## Toolchain

| Thành phần | Cấu hình |
|---|---|
| Compiler | MSVC 2022, bộ công cụ C/C++ x64 và Windows SDK |
| Build system | CMake ≥ 3.25, Ninja |
| Script | Python 3; Windows PowerShell cho script yêu cầu .NET Framework |
| Kiến trúc | x64; không trộn import library/DLL x86 |
| Encoding | Source UTF-8; giữ `/execution-charset:.936` cho literal tài nguyên |

Wrapper tìm Build Tools tại `C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools`.
Nếu dùng Community/Professional hoặc cài ở chỗ khác, dùng Developer Command Prompt
x64 và CMake trực tiếp, hoặc sửa đường dẫn wrapper trong bản sao của bạn.

## Phụ thuộc phải chuẩn bị

| Phụ thuộc | Vị trí source đang dùng | Ghi chú |
|---|---|---|
| FMOD Core 2.02.35 | `Src/ThirdParty/_sdk/fmod/api/core/inc` và `lib/x64` | Cần `fmod.h`, `fmod_vc.lib`, `fmod.dll` từ SDK hợp lệ |
| DirectX headers/import libraries | `Src/ThirdParty/DirectX9/Include`, `Lib/x64` | Bản xuất không chứa `.lib`; bổ sung đúng SDK |
| D3DX runtime | `d3dx9_43.dll`, `D3DCompiler_43.dll` | Build x64 có nhánh tạo import library từ D3DX43; kiểm file hệ thống và log CMake |
| NVIDIA Cg | CMake `CYS_CG_DLL` | Mặc định cũ trỏ `../client_GL/Bin64/cg.dll`; cần đường dẫn thật |
| Source thư viện khác | `Src/ThirdParty`, `Src/Engine/OGRE` | Giữ license/notice từng thư viện |

Xem [THIRD_PARTY.md](../../THIRD_PARTY.md). Không thay SDK bằng DLL cùng tên bất kỳ;
phiên bản, kiến trúc và import library phải khớp.

## Cách A — wrapper của dự án

Mở **Command Prompt** ở root source. Cú pháp:

```bat
Tools\build\build.cmd ARCH NAME CONFIG "COMPONENTS" TARGET
```

Sau khi SDK và Cg đã được cấu hình đúng, dựng toàn cây:

```bat
Tools\build\build.cmd x64 public-x64 Release
```

Dựng riêng executable game:

```bat
Tools\build\build.cmd x64 public-x64 Release "" cys_wxclient
```

`Release` đứng thứ ba; target đứng thứ năm. Không truyền `cys_wxclient` vào vị trí
cấu hình. Dựng riêng `Game.exe` không đảm bảo mọi DLL được nạp động đã được dựng lại.

## Cách B — CMake trong Developer Command Prompt x64

Giả định `cmake` và `ninja` có trong PATH, SDK ở đúng chỗ. Thay đường dẫn Cg mẫu
trong lệnh bằng vị trí thực trên máy bạn:

```bat
cmake -S Src -B Build/cmake/public-x64 -G Ninja -DCMAKE_BUILD_TYPE=Release -DCYS_CG_DLL="D:/SDK/Cg/bin.x64/cg.dll"
cmake --build Build/cmake/public-x64
```

Executable/DLL ở `Build/cmake/public-x64/bin`; thư viện tĩnh ở `lib`. Giữ cây build
riêng cho cấu hình này. Khi sửa static library phục vụ UI/render, liên kết lại DLL
sử dụng nó, thay vì chỉ kiểm timestamp `.lib`.

## Từ build sang bản chạy

1. Xác nhận `Game.exe` và các module runtime cùng kiến trúc x64.
2. Đối chiếu cấu hình plugin, tài nguyên, font, launcher và overlay.
3. Chuẩn bị `Play/Bin64`, runtime hợp lệ và `Assets/CanonicalCY/Data`.
4. Khi `Play/Bin64/Game.exe` đã có, tạo junction data:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Publication/Setup-Play.ps1 -Root "C:\Dev\372dragon"
```

Script từ chối thay `Play/Data` khác đích. Nó không tạo launcher, cấu hình tài khoản,
plugin hay bộ runtime. `Tools/build/stage.ps1` là staging lịch sử cho viewer/smoke,
có thể chép cả ứng dụng chẩn đoán; đọc tham số và đầu ra trước khi dùng cho Play.

**Còn thiếu:** quy trình tự động dựng đầy đủ Play trên máy mới chưa được nghiệm thu.
Gói data chỉ có overlay/tài nguyên, không chứa cấu hình Play/Bin64 hoặc DLL đã dựng.
CMake thành công chưa chứng minh đăng nhập và vào thế giới đã hoạt động.

## Kiểm tra sau build

- Ghi snapshot/commit, cấu hình build và SDK đã dùng.
- Đối chiếu file trong bản chạy với output build bằng hash.
- Nạp tài nguyên, đăng nhập và vào scene trên server riêng.
- Kiểm di chuyển, mở/đóng UI và thao tác sau khi đóng cửa sổ.
- Với item/tiền, kiểm lại sau thoát sạch và đăng nhập lại.

Tham khảo [kiểm toán source/build lịch sử](../10-CAU-TRUC-VA-KIEM-TOAN-BUILD_vi.md)
và [xử lý lỗi](troubleshooting.md); bằng chứng cũ không chứng nhận bản build mới.
