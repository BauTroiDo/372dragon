# Build — đầu ra dựng (không đưa vào git)

| Thư mục | Nội dung |
|---|---|
| `Client\Bin64\`, `Client\Bin\` | Game.exe và các DLL dựng từ `Src`, cộng runtime của hãng (VC++, D3DX9_43, FMOD, cg), theo đúng bố cục thư mục game |
| `Client\Data\` | Dữ liệu dạng thư mục rời khi phát triển (bản sao hoặc liên kết tới `Assets\Canonical`) |
| `Server\Sandbox085\` | Hộp cát: server C++ 0.85 chép từ `Reference\…\Build\Server`, dùng cho pha E1 (`Docs\04`, mục 7). Server sản phẩm vẫn là skynet trong WSL |
| `H0\` | Bản sao `client_GL` dành cho thí nghiệm tuỳ chọn H0 (`Docs\04`, mục 10) |
| `Packs\` | Gói AXP v1.1 để phát hành |
| `Symbols\` | PDB theo cấu hình dựng |
| `Logs\<ngày>-<cổng/đợt>\` | Hồ sơ bằng chứng của từng cổng nghiệm thu hoặc đợt nhập: log, ảnh, báo cáo validator |
