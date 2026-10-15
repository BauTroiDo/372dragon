# Src — mã nguồn làm việc

Mã nguồn đã được nhập và đang build bằng CMake/Ninja/MSVC. Cấu trúc thực tế và nguồn gốc từng
EXE/DLL được kiểm tra ngày 24/09/2026 tại
[kiểm toán source/build](../Docs/10-CAU-TRUC-VA-KIEM-TOAN-BUILD_vi.md).

Bố cục tổng quát (một số mô tả kế hoạch ban đầu bên dưới được cập nhật chi tiết trong tài liệu kiểm toán):

| Thư mục | Nội dung |
|---|---|
| `Client\` | `WXClient` (Game.exe), `WXNetPackets` (+ `gen\` chứa codec sinh từ đặc tả), `CEGUISystem` (UI_CEGUI.dll), `CEGUIFalagardEx`, `Support\` (Helper, Debuger, CrashReport) |
| `Engine\` | `Interface` (các header `TD*.h`), `WXEngine` và `WXCore` (static `.lib`), `WXRender` (Render.dll), `OGRE` (1.2.5 Dagon), `ParticleFX2`, `Scorpio`, `PathLib` (viết mới) |
| `Shared\Common` | Struct game, gói tin, DBC dùng chung với server |
| `ThirdParty\` | LuaPlus (Lua 5.0.1 có `continue`), CEGUI-0.4.1, FreeType, expat, tinyxml, Opcode, zziplib, zlib, Devil, Xerces 2.6, boost (phần header cần dùng). `_sdk\` chứa FMOD và Cg, không commit |
| `Tools\SceneEdit` | Chỉ nhập ở pha E4 |

Quy tắc:
- File lưu UTF-8 có BOM.
- Biên dịch với `/source-charset:utf-8 /execution-charset:.936`, vì literal tiếng Trung là khoá tài nguyên dạng GBK.
- Commit đầu tiên chứa mã nguyên trạng, kèm manifest hash của từng file.
- Không dán mã decompile. Viết lại theo đặc tả trong `Docs\specs\`.
