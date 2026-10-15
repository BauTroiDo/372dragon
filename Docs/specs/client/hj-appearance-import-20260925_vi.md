# Nhập ngoại hình HJ vào CY-Source — 25/09/2026

## Trạng thái và sử dụng

**Đã phát hành và kiểm hash sau chép lúc 13:53 ngày 25/09/2026.** Đích là `Build/world-gui/stage-play-21/Play.cmd` và server CY riêng `/home/ubuntu/cys-test-20260913` (15733/15734). Candidate đã kiểm: `Build/world-gui/stage-hj-appearance-25`.

Mở Phòng thay đồ từ bảng nhân vật, chọn nhóm và tìm **HJ**. Chọn mẫu → **Sở hữu** → **Mặc** (thời trang) hoặc **Dùng**. Với thú cưỡi: **Chọn dùng** → **Lên / xuống thú**. Thời trang có bộ chọn màu; huyễn sức có bộ chọn cấp ngoại hình. Cơ chế sở hữu, mặc và lưu dùng luồng wardrobe hiện có.

Huyễn hóa Võ hồn tiếp tục dùng giao diện Võ hồn hiện tại. Tên chưa có bản Việt hóa được xác minh giữ tên HJ gốc và hậu tố `[HJ]`. Không thêm bản sao vào shop nguyên bảo.

## Danh mục

| Nhóm | Số lượng |
|---|---:|
| Thời trang | 230 dòng, 711 biến thể màu |
| Thú cưỡi | 184 mục, 170 model/CharMount riêng |
| Huyễn sức vũ khí | 68 dòng, 195 biến thể cấp, gồm cấp 4 |
| Đầu sức | 12 |
| Bối sức | 21 |
| Mặt | 100 cặp nam/nữ |
| Tóc | 149 cặp nam/nữ |
| Ảnh đại diện | 40 cặp nam/nữ |
| Huyễn hóa Võ hồn | 6 dòng / 36 model đã có; cập nhật 3 texture HJ |

Có **1.412 lựa chọn cho mỗi giới tính**, tổng 2.824 lượt cần phủ. Nhiều mục dùng chung model.

Pack gồm 1.753 mesh, 311 skeleton, 21 dynbone, 5.087 texture, 6.954 material, 2.818 particle, 1.025 effect, 498 object, 230 skill và 11 sound. Hai skill bối sức có thêm alias tương thích tên native, không tính thành hai vật phẩm nữa. Skeleton bổ sung cho người cưỡi có manifest riêng.

## Nguồn và giới hạn

Nguồn: `C:/TLBB/085/Tools/DATA NEW/CYHJ091026`. Đối chiếu GL và `DataCY31-08-26` trước khi ánh xạ. Donor, CanonicalCY và server TLBB chính không bị sửa. Chỉ nhập ngoại hình và chức năng sử dụng tương ứng, không chép chỉ số chiến đấu HJ.

- **玄翎战甲 / Chiến Giáp Huyền Linh**: EquipDress 268 trỏ ItemVisualChar 416 không tồn tại trong cả HJ/GL. Chưa công bố; ID 416 của CY là model khác.
- Hai family placeholder `功夫熊猫替模` (331, 480) không có item gốc. Giữ resource, không tạo đồ giả.
- `Exterior_Poss` HJ khác schema Thú hồn CY. Resource đã thu nhưng chưa mở các lựa chọn Thú hồn mới bằng bảng chưa tương thích.
- CharMount ngoài catalog Exterior_Ride gồm attachment, placeholder, xe chạy thương hoặc model cảnh; không biến thành vật phẩm sở hữu riêng.
- **Bay cao:** CharMount HJ/GL 15 cột không có cờ CY cột 19. Giữ độ lơ lửng HJ cột 14 ở CY cột 22. Thú mới cưỡi/di chuyển theo donor, chưa tự cấp quyền bay cao chỉ vì có cánh. Thú CY đã có quyền giữ nguyên. Muốn mở cho từng mẫu HJ phải đủ metadata và action của cả thú lẫn người cưỡi.

## Cấu trúc và tái tạo

| File/thư mục | Vai trò |
|---|---|
| `Tools/game/hj_appearance_data.py` | Thu dependency, cô lập tên `cys_hj_<hash>`, giữ geometry và hiệu ứng |
| `Assets/Imported/HJ20260910` | Pack, baseline, manifest, mapping, bảng đích |
| `Tools/game/hj_appearance_tables.py` | Chuyển schema, ánh xạ ID, sinh catalog/header |
| `Registry/hj-appearance-catalog.json` | Family, biến thể, native ID, model, icon, thông số preview |
| `Tools/server/hj_appearance_install.py` | Plan/apply/verify, khóa cấu hình, backup, ghi nguyên tử |
| `Tools/game/validate_hj_appearance.py` | Geometry, bảng, Võ hồn, gọi kiểm động tác |
| `Tools/game/validate_hj_mounts.py` | Action → skill → animation của thú, người cưỡi, ornament |
| `Tools/game/hj_asset_extension.py` | Chứng minh sửa hồ lô chỉ thêm resource, giữ phần đã kiểm |
| `Tools/game/deploy_hj_appearance.py` | Stage/check/publish, backup và kiểm hash sau chép |
| `Tools/server/hj_appearance_fixture.py` | Fixture test15 offline, phục hồi BSON đầy đủ |

Visual chủ yếu dùng `20000 + ID HJ`, thú `2000 + ID HJ`, action set `10000 + ID HJ`. Item/wardrobe/native có mapping riêng; không suy ID item từ model. Giữ toàn bộ bản ghi cũ và string pool. Plan server lần nữa phải không đổi.

Game build từ source target `cys_wxclient`, log `build-09.log`, SHA-256:

`8c0efcdc0139e64fa271e4291165494d0f391d531ff4c9e81b6e1e3f978b2573`

Không thêm DLL hook/inject. Thay Game/PDB build lại, giữ DLL hiện có theo manifest.

## Sửa tương thích

- Material tinh vệ điểu, giáp Mộ Dung, bộ quán quân: dùng tên authored trên chính mesh/.obj. Texture cờ Hạng Vũ thiếu lấy đúng tài nguyên cùng tên S2, ghi hash nguồn.
- Thêm profile mặt/tóc/avatar cho màn chọn nhân vật, cờ tạo mới bằng 0. Tóc trọc có HairMesh rỗng nhưng HairMesh2 là da đầu được chấp nhận.
- Serializer login không còn ép tóc ID ≥255 thành 1; giữ ID 32 bit, client vẫn hiểu trường compact cũ.
- Camera thú lấy đúng cột 4–5 ExteriorRideCamera theo Lua GL, không dùng CharModelEx[6..8] vốn là linked model IDs.
- Thu 228 skill model thú với timing effect và 11 sound. Không gọi tên skill như skeleton animation; placeholder terrain vẫn do LogicModel xử lý.
- Sửa alias lỗi HJ/GL theo skeleton chính model: 61 walk dùng run đã có, 9 jump tại chỗ dùng jump di chuyển đã có, một `休闲1` → `休闲`, hai `飞起` → `起飞`. Tổng 73 bản ghi model / 81 trường hợp catalog; không sửa track. Xem `mount-action-repairs.json`.
- Giữ tên ActionSetFile gốc và sửa CysRiderActionSet nhận tiền tố giới tính không cần dấu `_`, gồm `女主角游船站立.txt` trước đây fallback nhầm nam.
- Thêm 18 skeleton, 42 Skeleton tags vào bốn actor CY nam/nữ world/preview. Bỏ các tag thêm phải khôi phục đúng byte actor gốc.
- Hai hồ lô dùng tên skill trong trường idle: thêm hai alias native chưa tồn tại ở CY và dependency cô lập. Bước cuối không sửa Game/catalog.
- Võ hồn: 291 dependency so GL, 288 giống byte, 3 DDS cập nhật pixel HJ; giữ kích thước/format/mip chain, không tạo 36 model trùng.

## Kiểm chứng

Bằng chứng ở `Build/Logs/2026-09-25-hj-import`.

- `static-run-10.log`, `static-validation.json`: 1.753 mesh đảo tên về đúng byte nguồn; 28 bảng giữ bản ghi CY.
- `mount-animation-validation.json`: 184 thú, 1.455 action thú, 340 ghế chính theo giới tính, 9.904 action người cưỡi gồm ghế phụ/preview và 42 action ornament; không thiếu animation.
- `rider-sex-tests/tests.log`: thân hàm C++ thật và bảng thật, 340/340 đạt. Profile chọn nhân vật 578 trường hợp; role-list 27/27; serializer tóc 8 ID biên.
- `wardrobe-contract-final.log`: 111 phản hồi về whitelist, trùng sở hữu, hết hạn, túi đầy, vị trí, đổi màu, tháo và nạp lại.
- `server-geo-validation.json`: 200 face, 298 hair tra được qua beauty metadata gốc.
- `server-release-idempotency/plan.json`: 15 file server không đổi khi plan lại.

Năm lượt dưới đây đều PASS và được dùng cho gate phát hành:

| Lượt | Phạm vi |
|---|---|
| `female-release3-a` | Nữ index 0–710, cưỡi thật 4 mẫu |
| `female-release3-b` | Nữ index 711–1411, sở hữu/mặc 8 nhóm |
| `male-release3-a` | Nam index 0–710, cưỡi thật 4 mẫu |
| `male-release4-b` | Nam index 711–1411, 8 nhóm trên pack cuối |
| `female-release4-back` | Nữ toàn bộ đầu/bối sức, relogin 8 nhóm trên pack cuối |

Gate yêu cầu thoát sạch, không lỗi handler/animation phần nhập và di chuyển sau đóng UI. Census kiểm nạp model/preview, không chứng minh mọi mẫu đã qua toàn bộ động tác chiến đấu/bay cao.

Ba lượt release3 trên cùng Game cuối dùng manifest `782e1c5234bd58b04c4af2572d6587532c47e6b490928d1ef789ab55052910af`. Pack bổ sung hồ lô dùng manifest `31cd765ff9d781deae65afae7f65b69456a4fa613b172a7f883a624d26a74f7a`.

`asset-extension-proof.json` kiểm 18.636 resource cũ cùng mọi definition cũ giữ nguyên byte; binary, cấu hình, UI, bảng, catalog không đổi. Chỉ thêm 72 resource logic, gồm 4 DDS và definition cho hai skill hồ lô. Gate bắt buộc thử lại toàn bộ bối sức cả hai giới tính và relogin 8 nhóm trên pack cuối trước khi chấp nhận coverage cũ.

BSON gốc test15/GUID 200016 lưu tại `test15-original.json`, không công bố nội dung. `restore-result.json` phải đạt equality toàn bản ghi. `release-report.json` chỉ ghi sau backup, phát hành và kiểm hash toàn bộ file.

Kết quả cuối: `restore-result.json` đã đạt equality BSON đầy đủ; `release-gate-final-02.log` PASS; `release-report.json` xác nhận 7.654 file overlay và 37 binary khớp manifest. Game/PDB mới dùng đúng build đã thử. Backup Play: `Build/backups/hj-appearance-play/20260925-135306`, có `rollback-manifest.json` liệt kê cả file cũ và file mới thêm. Manifest Play sau ghi thông tin phát hành: `ad76f27164f54db2f28f97413a672d66256fb698bb05c44fb3fb7632b675fe05`.

`server-status-final.json` ghi tất cả service riêng đang chạy, không trùng process, cổng 15733/15734 đã listen. `server-log-final.json` không thấy marker lỗi/traceback hoặc lỗi appearance trong hai log Game mới nhất. Các lượt probe cuối không có lỗi animation; đã xem ảnh thú cưỡi nam/nữ, bối sức và ngoại hình màn chọn nhân vật.

Hai DDS địa hình Võ Đang `jpg_wudangscene_3_0.dds`, `jpg_wudangscene_0_4.dds` đã thiếu trong baseline functional-01; gate chỉ cho qua hai ngoại lệ này, chặn exception Ogre khác. Không gọi toàn bộ renderer log là sạch.

Một số material dùng nhánh CPU skinning sẵn có của `CysMaterialSystem.cpp::resolveEntity` khi pass không ghép được vertex program skinning. Dòng diagnostic chính xác này được nhận diện riêng trong gate; không coi chữ “cannot” trong thông báo fallback là thiếu tài nguyên. Giữ nguyên material HJ, chưa đo chi phí hiệu năng riêng của các mẫu này.

## Lịch sử lỗi giữ lại

Không xóa FAIL hoặc coi wrapper PASS là đủ:

- census-male-fashion-01 / relogin-02: thiếu profile, tóc bị ép ID.
- census-male-02: camera cắt thú lớn.
- census-male-final: phiên gộp chạm hạn 600 giây; chia A/B.
- male-final / female-final: thiếu skill wrapper của 8 mount.
- female-release2-a: nữ fallback tư thế cưỡi nam.
- male-release3-b: thiếu idle skill hồ lô, fixture đi xa vùng NPC qua nhiều lượt. Đã bổ sung skill, đặt lại vị trí và chạy lại; loại lượt lỗi khỏi gate.
