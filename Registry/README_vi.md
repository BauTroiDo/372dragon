# Registry — sổ sách máy đọc được (có trong git)

| Đường dẫn (dự kiến) | Nội dung | Tài liệu |
|---|---|---|
| `ids\<bảng>.tsv` | Mỗi ID đã cấp: khoá (tên obj/mesh/item), nguồn, đợt, trạng thái | 05, mục 4 |
| `id-ranges.yaml` | Dải ID dành cho từng nhóm (CY, HJ, GL, tự làm), chốt ở D1 sau khi quét ID trống cả client lẫn server | 05, mục 4 |
| `selections\<đợt>.yaml` | Bản người dùng chọn cho mỗi món có nhiều phiên bản | 05, mục 3.3 |
| `batches\<đợt>.yaml` | Mỗi đợt nhập: tài sản, nguồn, ID, file đã ghi, hash trước/sau (dùng để hoàn tác) | 05, mục 9 |
| `protocol\packets.yaml` | Đặc tả giao thức sinh từ codec Lua của server | 06, mục 3 |
| `parity-known.yaml` | Các chỗ lệch client–server đã biết, được chấp nhận | 06, mục 5 |
| `abi\struct_sizes_x86.json` | Kích thước và offset các struct gói tin / file đo ở bản x86 | 04, mục 6 |
| `import\source-import-<ngày>.csv` | Manifest nhập mã từ Reference sang Src | 04, mục 3.2 |
