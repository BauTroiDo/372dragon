# Va chạm, tìm đường và độ cao nhân vật — CY 3.71 (nav-collision, 15/09/2026)

Phạm vi: client CY 3.71 dùng những file nào để (a) chặn đi, (b) tìm đường, (c) đặt độ cao nhân vật; CY-Source
làm lại thế nào. Bằng chứng Ghidra ở `Build/re/nav-collision/out/`, log ở `Build/Logs/2026-09-15-nav-collision/`.
**Dữ kiện** = đọc thẳng từ mã dịch ngược hoặc đo trên dữ liệu; **suy luận** ghi rõ.

Binary (bản sao trong `Build/re/nav-collision/bin`):

| File | sha256 | Project Ghidra |
| --- | --- | --- |
| `cy_Game.exe` | `9278c7f37b55539fcfac1d93afa71f278e34d4ce674b0e8b52a0f62ea6e0cc5b` | `projCG/cyg` (chép từ cy-switch) |
| `cy_Render.dll` | `e6e67de45489f90207379419c0eb2e9f4fbdbd1d800cc6f46902c1fe5eb0cec7` | `projR/cyr` (phân tích mới) |
| `cy_PathLib.dll` | `693ec0e420eea9f188a7d0a75ba580a3e625619806132dd427eddd7020537c1e` | `projR/cyr` |

## 1. File nào được nạp khi vào cảnh (dữ kiện)

`CScene::Initial` = `FUN_1406be4d0` gọi `FUN_1406bd110(scene, def+0x20, def+0x28)` — hai chuỗi là cột 5 (`*.path`)
và cột 6 (`*.wCollision`) của `SceneDefineEx`. `FUN_1406bd110`:

1. `ResourceProvider::loadResource(path, "Scene")` (vt+0x78), rồi `scene+0x2080 = gfx->vt+0x6b0()` = `CPathLibRoot`
   của Render.dll (`FUN_180024440` → `FUN_18001d400`, vftable `0x1802c0338`).
2. `scene+0x2088 = root->getPathData()`; `pathData->load(buf,len)`; `scene+0x2090 = root->getPathFinder()`;
   `finder->init(pathData)`.
3. `scene+0xd8 = root->getBuildingCollision()`; nạp `*.wCollision` (cũng nhóm "Scene") vào nó.
4. Sau đó `gfx->vt+0x3f8(scene+0xd8)` (`FUN_1800317d0`: lưu vào `CRenderSystem+0x2a0`).

Không có chuỗi `.Region`, `REGION_EDIT_01`, `.Dijkstra` nào trong Game.exe/Render.dll CY. Chuỗi `REGION_EDIT_01` và
`.region` chỉ có trong PathLib.dll, ở hàm dựng navmesh ngoại tuyến (CGAL `Constrained_Delaunay_triangulation_2`,
đọc `.region` + `.terrain`) — **client CY không đọc `.Region` lúc chạy**. `.Fly` do Render.dll đọc (chuỗi `.fly`) cho
bay; Game.exe `FUN_1406d9520` chỉ hỏi "điểm có bị chặn" khi dùng thú bay.

Render.dll bọc PathLib bằng ba lớp mỏng (vftable `CPathData 0x1802c0298`, `CPathFinder 0x1802c02b8`,
`CBuildingCollision 0x1802c0310`), mỗi slot nhảy thẳng sang slot PathLib:

| Game.exe gọi (`scene+0x2090`) | Render `CPathFinder` | PathLib `PathFinderImpl` (vftable `0x180045908`) | Nghĩa |
| --- | --- | --- | --- |
| +0x08 | `FUN_18001dd90` | +0x08 `FUN_18002b880` | init(PathData) |
| +0x10 (sx,sz,tx,tz,fly) | `FUN_18001db70` | +0x18 `FUN_1800287c0` | findPath |
| +0x18 (sx,sz,tx,tz) | `FUN_18001dc00` | +0x28 `FUN_18002a580` | kiểm đoạn thẳng, gom cạnh ràng buộc bị cắt |
| +0x20 (x,z,&out,bool) | `FUN_18001ddb0` | +0x30 `FUN_18002c160` | điểm có bị chặn |
| +0x28 / +0x30 | `FUN_18001dc40` / `FUN_18001dd40` | +0x38 `FUN_18002b860` / +0x40 | số điểm / điểm i của đường |
| +0x38 (&n,&flag,&pt) | `FUN_18001d6f0` | +0x48 | kết quả kiểm đoạn: số cạnh, cờ, điểm chạm đầu |

| `scene+0xd8` | Render `CBuildingCollision` | PathLib `BuildingCollsionImpl` (vftable `0x180043b78`) | Nghĩa |
| --- | --- | --- | --- |
| +0x08 | `FUN_18001ddd0` | +0x08 `FUN_180004580` | nạp `*.WCollision` |
| +0x10 (x,&y,z) | `FUN_18001dc20` | +0x10 `FUN_180004380` | độ cao mặt công trình |
| +0x18 (orig,dir,&out) | `FUN_18001dac0` | +0x18 `FUN_180003170` | tia chọn mặt công trình (OPCODE) |

## 2. (a) Chặn đi và (b) tìm đường

- `CPath::CreateMovePath` = `FUN_1406d8c00`: kiểm hai đầu trong cảnh (`scene->vt+0x10`), `finder+0x10` findPath,
  chép từng đoạn (điểm i, i+1) vào vector `PathUnit` 16 byte; log `path unit > 16` khi > 16 đoạn.
- `CPath::GetPathDirect` = `FUN_1406d8fa0` (giữ chuột / click vào ô chặn): `finder+0x18` kiểm đoạn start→target;
  có cạnh bị cắt thì `finder+0x38` lấy điểm chạm đầu; nếu start **và** target đều trong ô chặn (`finder+0x20`) thì
  cho đi thẳng khi < 2 cạnh ("move from obstacle to nonobstacle"); còn lại dừng ở điểm chạm lùi 0,1 về phía start
  (nếu điểm đó vẫn chặn thì dùng điểm chạm); đoạn < √2 bỏ.
- Dữ liệu chặn = **chỉ `*.path`** (cờ bit0 tam giác + cạnh ràng buộc + danh sách ô lưới, định dạng ở memory
  `tlbb-path-navmesh-format`). CY-Source đã làm bằng PathLib clean-room + `cys::NavMesh` (handoff `navmesh.md`).

Đo `dali_new_320` (`Tests/pathlib/tools/nav_overlay.py`, `overlay/dali_new_320_overlay.json`):

| Số đo | Kết quả |
| --- | --- |
| 1.430 đa giác `.Region` (198 có cờ bay) — mẫu 0,5 đơn vị bên trong đa giác nằm ở tam giác chặn của `.path` | 210.377 / 210.419 = **99,98 %** (42 mẫu ngoài lưới) |
| Mẫu 1 đơn vị: tam giác chặn nằm ngoài mọi đa giác / tam giác đi được nằm trong đa giác | **0 / 0** |
| 24 tia dài 60 từ (160,150): khoảng cách tới cạnh `.Region` đầu tiên = tới cạnh ràng buộc `.path` đầu tiên | **24/24 bằng nhau** |

⇒ `.path` CY chính là `.Region` đã tam giác hoá; nạp thêm `.Region` không thêm tường nào. Ảnh
`overlay/dali_new_320_overlay_crop.png`, `overlay/dali_new_320_wcoll_nav_crop.png` (tường khớp công trình `.Scene`).

## 3. (c) Độ cao nhân vật

- `CScene::GetMapHeight` = `FUN_1406bcfa0`: kiểm biên cảnh, `gfx->Axis_Trans(AX_PLAN→AX_GAME)` (vt+0x150) lấy độ
  cao địa hình, `scene+0xd8 ->getHeight`; có mặt công trình và cao hơn địa hình thì dùng mặt công trình. Giống hệt
  `CScene::GetMapHeight` 0.85 (`Scene.cpp`), khác ở nguồn dữ liệu.
- PathLib `getHeight` `FUN_180004380(this, x, &y, z)`: tia từ `(x, 10000, z)` hướng `(0,-1,0)` qua slot +0x18
  (OPCODE `RayCollider`, giữ điểm chạm gần nhất) ⇒ **mặt trên cùng** tại (x,z).
- Render.dll dùng cùng đối tượng cho va chạm camera: `FUN_1800040e0` lấy max(độ cao 4 góc ô địa hình,
  `getHeight`) làm hộp AABB, `FUN_180004c50` cắt hình cầu camera (suy luận: camera không chui xuống bục/cầu).

### Định dạng `*.WCollision` (dữ kiện, đọc hết đúng byte cuối 386/386 file Canonical CY)

`BuildingCollsionImpl` slot 1 `FUN_180004580`: magic `0xff000002` → slot 4 `FUN_180004a00`; còn lại (`0xff000001`):

```
0xff000001 (125 file):  u32 magic, u32 cellCount,
                        cellCount x { i32 x, i32 z, u32 n, n x f32[9] }   // toạ độ cảnh, tam giác lặp ở nhiều ô
0xff000002 (261 file):  u32 magic, u16 meshCount,
                        meshCount x { u16 nv, nv x f32[3], u16 nt, nt x u16[3] }        // FUN_180003d80
                        f32[3] offset, f32[3] scale                                      // dali_new_320: (-16000,0,-15700) (100,100,100)
                        u16 instCount, instCount x { f32[3] scale, f32[3] pos, f32[4] quat(w,x,y,z), u16 mesh }  // 42 byte
```

Đỉnh thế giới = `T(pos) · R(quat) · S(scale) · v` (`FUN_180001f80` = `Ogre::Quaternion::ToRotationMatrix`
`FUN_180011670` đặt vào ma trận đơn vị; `FUN_1800032a0` = nhân 4×4; ma trận T lấy `pos`, S lấy `scale` của thực thể),
toạ độ cảnh = `(thế giới − offset) / scale` (chia theo w). Loader gốc gộp mọi tam giác vào một cây AABB toàn cục,
không dùng khoá ô của file.

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

## 6. Còn khác CY (suy luận / chưa làm)

- CY dùng cây AABB + tia; CY-Source tra theo ô nguyên (map) — cùng kết quả mặt trên cùng, khác hiệu năng.
- Va chạm camera với mặt công trình trong Render.dll (`FUN_1800040e0`) chỉ có qua `_GetTerrainHeight` nếu camera
  WXRender gọi callback đó; chưa đo riêng.
- `GetPathDirect` đã theo CY (lùi 0,1, bỏ đoạn `DistSq < 2`); nhánh "cả hai đầu trong ô chặn" của CY chưa làm.
  `.Fly`/thú bay chưa làm.
- Vùng động (`CScene::AddDynamicRegion`, `finder+0x40/+0x48`, `GCSetDynamicRegion`) chưa làm.
