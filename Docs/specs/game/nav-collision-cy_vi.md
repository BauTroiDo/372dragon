# Va chạm, tìm đường và độ cao nhân vật — CY 3.71 (nav-collision, 15/09/2026)


| --- | --- | --- |
| `cy_Game.exe` | `9278c7f37b55539fcfac1d93afa71f278e34d4ce674b0e8b52a0f62ea6e0cc5b` | `projCG/cyg` (chép từ cy-switch) |
| `cy_Render.dll` | `e6e67de45489f90207379419c0eb2e9f4fbdbd1d800cc6f46902c1fe5eb0cec7` | `projR/cyr` (phân tích mới) |
| `cy_PathLib.dll` | `693ec0e420eea9f188a7d0a75ba580a3e625619806132dd427eddd7020537c1e` | `projR/cyr` |

## 1. File nào được nạp khi vào cảnh (dữ kiện)


| --- | --- | --- | --- |

| --- | --- | --- | --- |

## 2. (a) Chặn đi và (b) tìm đường


Đo `dali_new_320` (`Tests/pathlib/tools/nav_overlay.py`, `overlay/dali_new_320_overlay.json`):

| Số đo | Kết quả |
| --- | --- |
| 1.430 đa giác `.Region` (198 có cờ bay) — mẫu 0,5 đơn vị bên trong đa giác nằm ở tam giác chặn của `.path` | 210.377 / 210.419 = **99,98 %** (42 mẫu ngoài lưới) |
| Mẫu 1 đơn vị: tam giác chặn nằm ngoài mọi đa giác / tam giác đi được nằm trong đa giác | **0 / 0** |
| 24 tia dài 60 từ (160,150): khoảng cách tới cạnh `.Region` đầu tiên = tới cạnh ràng buộc `.path` đầu tiên | **24/24 bằng nhau** |

⇒ `.path` CY chính là `.Region` đã tam giác hoá; nạp thêm `.Region` không thêm tường nào. Ảnh
`overlay/dali_new_320_overlay_crop.png`, `overlay/dali_new_320_wcoll_nav_crop.png` (tường khớp công trình `.Scene`).

### Định dạng `*.WCollision` (dữ kiện, đọc hết đúng byte cuối 386/386 file Canonical CY)


Đo `dali_new_320.WCollision` (`Tests/pathlib/tools/wcollision.py`, `wcoll/dali_new_320_wcoll.json`): 29 mẫu,
306 thực thể, 11.752 tam giác; 6.852 ô 1×1 có mặt công trình cao hơn địa hình, cao nhất +23,4. Bục giữa quảng
trường: mặt trên 16,1 (địa hình 12,0) tại các điểm click replay 15/09 06:56 (157.8,166.4)=14,77, (163.5,172.1)=16,28,
(160.4,179.5)=16,12, (154.8,173.8)=16,11 ⇒ nhân vật đứng ở 12,0 chìm 2,8–4,3 đơn vị (280–430 cm) trong bục.

## 4. Nguyên nhân lỗi CY-Source và cách sửa

| Hiện tượng người dùng thấy | Nguyên nhân (dữ kiện) | Sửa |
| --- | --- | --- |
| "Nhân vật đi xuyên tường bục giữa", nhãn tên nổi trên bậc nhưng không thấy model | `CBuildingCollisionMng::LoadCollisionTriInfoFromFile` (mã 0.85) chỉ tìm nhóm "General" (stage đặt SceneFolder ở "Scene") ⇒ không nạp gì, không log; nếu có tìm thấy thì đọc `0xff000002` theo bố cục 0.85 cũng ra rác. `GetHeight` luôn false ⇒ nhân vật và camera đứng trên `.Heightmap` bên trong khối bục | `CysWCollision.{h,cpp}` đọc hai định dạng CY; `CBuildingCollisionMng` thử "General" rồi "Scene", đăng ký tam giác vào mọi ô nguyên hộp bao phủ, `GetHeight` tính cạnh là chạm (như tia OPCODE). `Obj_Phy::SetMapPosition`, `CScene::GetMapHeight`, `CWorldManager::_GetTerrainHeight` (camera) và `SelBuilding` (chuột) dùng lại sẵn |
| "Chưa có địa hình" | Địa hình VẼ đủ (so `scene-dali-new-3.png` của Viewer và `world-1.png`); cái thiếu là **độ cao theo công trình** (bục, bậc, cầu) ở mục trên | như trên |
| Tường nhà/bồn hoa | navmesh đã đúng (mục 2); click sau bồn hoa đi vòng, click vào trong dừng trước tường | không đổi mã; thêm test + replay chứng minh |

Server riêng (`/home/ubuntu/cys-test-20260913`, chỉ đọc): `scenecore:char_move` (dòng 2162) **không kiểm navmesh**
cho người chơi (ghi chú 26/08: kéo ngược gây giật; chặn tường là việc của client như bản đồ gốc); `nav_adapter`
(`.path` qua `lnavmesh`) chỉ dùng cho AI/`is_can_go`. Đo live 15/09 08:07 (`bot-goto-wall/run-20260915-080701`):
CysNetBot `--goto 279,133.3` (tâm tam giác chặn, nhà phía đông) từ (250.5,118.4) đi thẳng 32,1 đơn vị, server trả
GCCharMove và lưu Mongo `x=279.0 y=133.3` ⇒ **server riêng không chặn người chơi đi xuyên tường**; đã đưa nhân vật về
(250.5,118.4) (`bot-goto-restore/run-20260915-080914`). Không sửa server: client GUI chặn như bản đồ gốc (vá kéo ngược
26/08 từng gây giật), độ cao là việc của client (server không có trục Y cho người chơi). Nếu cần chống bot/hack thì
phải làm kiểm đoạn trên server bằng cạnh ràng buộc (không kéo về theo ô) — ngoài phạm vi.

## 5. Kiểm

- `Tests/pathlib/navcol_test.cpp` + `build_navcol_test.cmd <BuildTree> <SceneFolder> <Out>`: 386 `*.WCollision` đọc hết
  byte cuối; `dali_new_320` 29/306/11.752; bục cao hơn địa hình ≥ 2 ở 5 điểm; quảng trường trống không có mặt; < 2 %
  trọng tâm tam giác dưới địa hình; navmesh: đích sau bồn hoa (147.8,166.4) cắt tường khi đi thẳng, FindPath đi vòng
  ≥ 2 waypoint không cắt tường, click (151,166.4) trong bồn hoa bị chặn, MoveAlong dừng phía đi được.
- Replay: `CYS_WORLD_REPLAY_CLICKS="x,z;x,z;x,z"`, `CYS_WORLD_REPLAY_CLICK_MS`, `CYS_NAV_WCOLLISION=0` (tắt để chụp
  ảnh "trước" cùng binary). Log `CYS-NAV: wcollision …`, `CYS-NAV: scripted click …`.
