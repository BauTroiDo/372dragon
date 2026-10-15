# Assets — dữ liệu game (không đưa vào git)

| Thư mục | Nội dung |
|---|---|
| `Sources\` | `sources.yaml` mô tả 7 nguồn S1–S7 (viết ở pha D0). `manifests-2026-09-12\files_*.tsv` là danh sách file của từng nguồn, do `inv_walk.py` sinh ngày 12/09. **Không chép dữ liệu nguồn vào đây**; nguồn nằm nguyên tại `C:\TLBB\085\client_GL\Data` và `C:\TLBB\085\Tools\DATA NEW\…` |
| `Staging\` | Dữ liệu đã đọc và chuẩn hoá theo từng nguồn (tên thống nhất, đã cắt đệm), kèm manifest. Sinh lại được |
| `Canonical\` | Kho chuẩn hợp nhất, bố cục `Data\*Folder` như client. Các file `all.*` được dựng lại theo cách xác định |

Dung lượng dự kiến: Staging 30–50 GB, Canonical 20–30 GB. Ngày 12/09 ổ C còn khoảng 419 GB trống.

Quy trình: `Docs\05-QUY-TRINH-TAI-SAN_vi.md`.
