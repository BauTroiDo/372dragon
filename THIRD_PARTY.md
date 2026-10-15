# Thành phần bên thứ ba

Giữ notice trong source. Bảng này là kiểm kê ban đầu, không phải xác nhận mọi nghĩa vụ
giấy phép đã được đáp ứng cho toàn bộ dự án.

| Thành phần | Bằng chứng/vị trí | Xử lý |
|---|---|---|
| Nền TLBB 0.85 và code kế thừa | Src/Client, Src/Engine | Quyền tác giả gốc; chỉ cấp phép phần đóng góp có quyền |
| OGRE | Src/Engine/OGRE/OgreMain/include/Ogre.h | LGPL version 2 or later theo header |
| CEGUI 0.4.1 | Src/ThirdParty/CEGUI-0.4.1/CEGUI/include/CEGUIBase.h | LGPL-2.1-or-later |
| Skynet | Server/GameServer/framework/LICENSE | MIT; giữ notice codingnow.com |
| jemalloc | Server/GameServer/framework/3rd/jemalloc | Binary ELF `libjemalloc.so.2` nằm ngoài bản xuất; cần xác định phiên bản/source và notice trước khi hoàn tất phụ thuộc build |
| zziplib | Src/ThirdParty/zziplib/zziplib/COPYING.* | Giữ lựa chọn giấy phép đúng bản nguồn |
| zlib, FreeType, Boost, Lua/LuaPlus, DevIL, Xerces, Expat, TinyXML, Opcode | Src/ThirdParty | Giữ notice/điều khoản từng bản; không áp NC cho phần của tác giả gốc |
| FMOD Core 2.02.35 | _sdk/fmod/api/core | Lấy SDK từ [FMOD](https://www.fmod.com/download), theo [điều khoản FMOD](https://www.fmod.com/legal) |
| NVIDIA Cg 3.1 | CYS_CG_DLL | Lấy từ [Cg Toolkit Archive](https://developer.nvidia.com/cg-toolkit-archive), theo giấy phép NVIDIA |
| DirectX SDK, d3dx9_43.dll, D3DCompiler_43.dll | Src/ThirdParty/DirectX9 và runtime | Lấy bản phân phối được Microsoft cho phép; không cấp lại license |
| Font, data đa nguồn | Gói kiểm thử ngoài repo | Quyền của chủ sở hữu gốc; ngoài license dự án |

Không đưa toàn bộ FMOD SDK hay DLL có điều khoản riêng vào Git theo mặc định.
DLL chúng ta build cũng phải xét license của code bên trong. Miễn phí dùng SDK không
tự đồng nghĩa được phân phối lại cả SDK.

Các file binary/dependency đã đóng gói trong phương án GitHub Releases cũ chỉ là file
cục bộ và không thuộc phương án public hiện tại. Phương án hiện tại là source +
hướng dẫn lấy phụ thuộc hợp lệ + data kiểm thử ngoài repo.
