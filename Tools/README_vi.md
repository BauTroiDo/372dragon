# Tools — công cụ riêng của CY-Source

Công cụ dùng chung có sẵn ở `C:\TLBB\085\Tools` và `C:\TLBB\085\analysis` được **gọi tại chỗ**, không chép sang đây trừ khi phải sửa. Danh mục đầy đủ ở `Docs\09-DANH-MUC-CONG-CU_vi.md`.

| Thư mục | Công cụ (dự kiến) |
|---|---|
| `pipeline\` | `import_source.py` (nhập mã từ Reference sang UTF-8 kèm manifest), `ingest.py`, `registry.py`, `merge.py`, `tables.py`, `review.py` (bảng chọn bản), `install.py`, `package_axp.py` |
| `protocol\` | `specgen.py` (đặc tả YAML từ codec Lua của server), `codegen_cpp.py`, `codegen_py.py` |
| `re\` | Script Ghidra lấy đặc tả: vtable có tên slot, bảng đăng ký API Lua của Game.exe (B), danh sách lớp gói |

Quy tắc:
- Mọi công cụ ghi dữ liệu có đủ bốn chế độ `check` / `apply` / `verify` / `revert` và sao lưu trước khi ghi.
- File GBK xử lý ở mức byte.
- Python chạy bằng `C:\Program Files\Python313\python.exe` với `PYTHONUTF8=1`.
