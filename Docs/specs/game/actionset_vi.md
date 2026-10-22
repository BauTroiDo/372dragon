# Đặc tả hệ ActionSet của client_GL (B) và cài đặt trong CY-Source

Ngày lập: 14/09/2026 (agent `actionset`, nhánh `actionset`). Bằng chứng nằm ở `Build\Logs\2026-09-14-actionset\`.


## 1. Bức tranh tổng thể

```text
CharModelEx.txt cột 9 ──► ActionSetFile.txt (id → "男主角.txt")            [bộ động tác của model]
CharMount.txt cột 6/7 ──► ActionSetFile.txt (id → "男主角_虎.txt")         [bộ của người cưỡi, theo thú]
        │
        ▼ set id
ActionSet/ActionSet.txt     (record, set, action, line)   ── (set, action) → line
ActionSet/ActionSetLine.txt (line, ô 1..N, phụ A, B, C)   ── line + ô     → id tên
ActionSet/ActionSetKV.txt   (id, tên)                      ── id           → tên hoạt cảnh (GBK)
        │
        ▼ tên
LogicModel::createSkill(tên): có skill cùng tên trong EffectFolder/all.skill → chơi `Animation` của skill
                              (kèm hiệu ứng), không có → chơi thẳng animation cùng tên trong skeleton
```

0.85 giữ **một file DBC 13 cột cho mỗi model** (`Config/ActionSet/<model>.txt`: id, 9 tên theo loại vũ khí, ẩn vũ khí,
vũ khí chỉ định, mô tả). B gộp thành ba bảng dùng chung và thêm ô. Hai bộ dữ liệu này cùng mã hành động: action id của
B đúng bằng `ENUM_BASE_ACTION` của 0.85 (`Object/ObjectDef.h`: 0 đứng, 1–2 nhàn, 3 đi, 4 chạy, 5–7 ngồi, 14 cảnh giới,
16 chạy chiến đấu, 23 trúng đòn, 24 chết, 25 xác, 92/93/99 lên cấp; 125+ chiêu, 29–50 cưỡi) **[DK]**: so 728 file
per-model của 0.85 (`Reference\tlbb085\085\Build\Client\Data\Config\ActionSet`) với bảng B cùng tên file: 146.518 dòng
khớp cột "vũ khí chỉ định" 100 %, chỉ 2 action của 0.85 không có trong B.

## 2. Định dạng từng file (Canonical `Assets\Canonical\Data\ConfigFolder`, trùng byte với client_GL) [DK]


| File | Dòng dữ liệu | Cột | Ý nghĩa |
|---|---:|---|---|
| `ActionSetFile.txt` | 1.724 | `id, tên file` | id bộ động tác → tên (chỉ còn là nhãn; 530 = `男主角.txt`, 263 = `女主角.txt`, 501 = `獠牙雪人.txt`, 699 = `虎.txt`). |
| `ActionSet/ActionSet.txt` | 243.148 | `record, set, action, line` | Với mỗi bộ, mỗi action → chỉ số dòng trong ActionSetLine. Các dòng của một bộ **liền nhau** và bộ tăng dần (B dựa vào đó, mục 3.1). Cột record không dùng. |
| `ActionSet/ActionSetLine.txt` | 7.199 | `line, ô 1..15, A, B, C` (19 cột; gốc 15 = 11 ô) | Một dòng = một hành động cụ thể; mỗi ô là **id tên** (không phải tên) cho một loại vũ khí. Cột 0 = chỉ số dòng, trùng thứ tự hàng (0 lệch). |
| `ActionSet/ActionSetKV.txt` | 5.727 | `id, tên` | id 0..5726 liên tục; **id 9 là chuỗi rỗng** (= "không hoạt cảnh"). 1.558 tên có tiền tố `m01_`/`g01_` là **tên skill trong all.skill**, không phải track. |
| `CharActionSet.txt` | 92 (DBC nhị phân, 10 cột) | `id, 9 tên` | Bảng soạn thảo của 0.85; **B không đọc** (đã Việt hoá trong Canonical mà B vẫn chạy; hàm nạp B chỉ mở ba file trên). Game.exe CY-Source vẫn nạp nó vào DBC 90 nhưng không dùng cho hoạt cảnh. |

Ba cột phụ của `ActionSetLine.txt` (phân bố trên 7.199 dòng) [DK]:


## 4. Ngữ nghĩa các ô của ActionSetLine [DK]

| Ô (0-based) | Cột file | Vũ khí / trạng thái | Type % 30 | 0.85 cột tương ứng (số dòng khớp / 61.213) |
|---:|---:|---|---|---|
| 0 | 1 | tay không | — | 1 (58.279) |
| 1 | 2 | thương bổng | 1 | 2 (58.247) |
| 2 | 3 | đao phủ | 0 | 3 (58.247) |
| 3 | 4 | song đoản | 3 | 4 (58.247) |
| 4 | 5 | đơn đoản | 2 | 5 (58.247) |
| 5 | 6 | quạt | 4 | 6 (58.247) |
| 6 | 7 | song hoàn | 5 | 7 (58.247) |
| 7 | 8 | đàn (B thêm) | 6 | — |
| 8 | 9 | liềm Ác Nhân Cốc (B thêm) | 7 | — |
| 9 | 10 | **dùng chung**: quái, NPC, pet, biến hình, cưỡi | — | 8 = cột MONSTER (144.304 / 145.061) |
| 10 | 11 | cột NPC của 0.85; B không chọn | — | 9 = cột NPC (144.340 / 145.060) |
| 11–14 | 12–15 | đao tổ / trượng / nỏ / tiêu kiếm (vá 09/09) | 8 / 9 / 16 / 17 | — |

Số khớp lấy từ so sánh 728 file per-model 0.85 với bảng B (`Build\Logs\2026-09-14-actionset\` không lưu script; lệnh
so sánh mô tả trong handoff). Các tên không khớp là những chỗ B đã đổi hoạt cảnh (ví dụ 0.85 `空手跑步` → B skill
`m01_跑步`).

Với 0.85 `ENUM_WEAPON_TYPE`: NONE→0, SPEAR→1, LONG→2, DSHORT→3, SHORT→4, FAN→5, RING→6, MONSTER→9, NPC→9 (theo B),
INVALID→0. Đàn/liềm/đao tổ/trượng/nỏ/tiêu kiếm chưa có trong enum 0.85 (`CObject_Item_Equip::GetWeaponType` chỉ ánh xạ
6 loại) → tạm về tay không (việc còn lại, mục 9).

## 6. Dự phòng hoạt cảnh (fallback) [DK]

1. `(set, action)` không có dòng, hoặc id tên ngoài `ActionSetKV`, hoặc ô ngoài phạm vi → **NULL → giữ hoạt cảnh đang
   chơi** (3.5). Không có "tay không thay thế" trong B.
2. Tên rỗng (id 9; ví dụ action 3 "đi" ô 0–8, action 34/36/37…) → model **dừng ở khung hiện tại**.
3. Tên là skill của `all.skill` (4.290 skill, 4.290 có dòng `Animation`; 1.098/1.557 tên riêng của bộ nam đi đường
   này) → `createSkill` chơi `Animation` của skill và gắn hiệu ứng (ví dụ `m01_跑步` = `跑步` + bụi chân).
4. Tên không có trong skeleton của model → `_getAnimationState` ném, WXCore log `"_getAnimationState Failed!"`, model
   giữ khung cũ (`WXLogicModel.cpp` 1650–1662).
5. Đối chiếu toàn bộ Canonical (`check-all\`): 4.409 model có bộ, 4.408 object có trong `all.obj`; **1.826 model có đủ
   mọi tên** mà bảng có thể trả cho chúng; 537 tên riêng thiếu, chủ yếu là chiêu người chơi/pet nằm ở ô 9 của các dòng
   quái (`m_magic`, `guid_chongwu_*`, `单短横扫`…: quái không bao giờ được yêu cầu diễn) và `死亡` (703 bộ chỉ có
   `倒地`) / `行走` (425 bộ) / `倒地` (367 bộ). Idle diễn được ở 4.359/4.409 model, chạy ở 4.020/4.409. Bộ nam thiếu
   93 tên, bộ nữ thiếu 261 (danh sách trong `check-all\models.tsv`, `missing_names.tsv`) — đây là tình trạng của chính
   client_GL, không phải lỗi chuyển đổi.

## 7. Cài đặt trong CY-Source (nhánh `actionset`)

| Phần | File | Nội dung |
|---|---|---|
| Parser | `Src\Client\WXClient\Action\CysActionSetTable.{h,cpp}` | Không phụ thuộc engine. `LoadActionSet/Line/KV(pData, nSize)` từ bộ nhớ, hai dòng tiêu đề tự bỏ, số ô = số cột − 4 (tối đa 32), dòng theo chỉ số hàng như B (đếm `nLineIdMismatch`), thiếu ô → 0/−1 và đếm, ô thừa/ô không phải số → đếm và bỏ, `Finish()` đếm id lệch bảng; không bao giờ ném. `FindLine` tuyến tính, dòng đầu thắng; `GetLineName` trả NULL khi id ngoài KV, chuỗi rỗng khi id 9; `Resolve()` gộp. `SlotFromEquipType(Type)` = 3.4. |
| Manager | `Src\Client\WXClient\Object\ActionSetMgr.{h,cpp}` | `Init("ActionSet/")` nạp ba bảng qua `s_pResourceProvider->loadResource` (thử `ActionSet/<file>` rồi tên gốc, cùng nhóm `"General"` như B), log `CYS action-set: B tables loaded: …` với đủ thống kê; `CysGetActionName(set, action, ô, &hide, &appointed)`, `CysHasSet`, `CysSlotFromWeaponType`. Đường per-model 0.85 giữ nguyên làm dự phòng khi không có bảng. |
| Object | `Src\Client\WXClient\Object\Character\Obj_Character.{h,cpp}` (`// CYS`) | `m_nCysCharActionSet`/`m_nCysMountActionSet`; `UpdateCharActionSetFile` = mục 5 (ghế cưỡi qua `CysRiderActionSet`), log một dòng khi bộ không có dòng; `CysActionSlot()` = 3.3 + 3.4; `Get{Char,Mount}ActionNameByActionSetID` đi qua bảng B trước, NULL giữ hoạt cảnh như 3.5. Preview tạo nhân vật (`InitializeCreationPreview`, `Actor_EnterSkill("站立")`) không đi qua đường này nên không đổi. |
| Build | `Src\cmake\components\wxclient.cmake` (+1 dòng), `actionset_check.cmake`, `Src\CMakeLists.txt` (+1 tên thành phần) | |
| Công cụ | `Src\Tools\CysActionSetCheck\ActionSetCheckMain.cpp` → `CysActionSetCheck.exe` | Chạy đúng parser trên thư mục Data; `--report` TSV theo bộ; `--set|--model --action --slot` tra một ô; `--dump-set`. rc 2 khi id lệch bảng. |
| Kiểm dữ liệu | `Tests\actionset\check_actionset.py` | Đối chiếu tên với skeleton (mesh skeletonLink, DefaultSkeleton, `<Skeleton>` của all.obj) và với `all.skill`; `--all` quét toàn bộ CharModelEx. |

Bước tương thích ngược: khi bộ dữ liệu không có `ActionSet/ActionSet.txt` (bố cục 0.85) mọi thứ chạy như trước.

## 8. Kiểm chứng (`Build\Logs\2026-09-14-actionset\`)

- `check-cpp-1.txt`, `check-cpp-report.tsv`: `CysActionSetCheck.exe` trên Canonical — 1.724 bộ, 243.148 action, 7.199
  dòng × 15 ô, 5.727 tên (1 rỗng); 0 lệch chỉ số dòng, 0 dòng thiếu/thừa ô, 0 ô không phải số, 0 id lệch bảng, 0 action
  trùng; `男主角.obj` action 4 ô 0 → dòng 2756 `m01_跑步` (byte `6d 30 31 5f c5 dc b2 bd`). `result: OK`.
- `check-2\`, `check-all\`: `check_actionset.py` (mục 6.5).
- `shots\`: TlbbViewer trên bản dựng của nhánh, `--anim` = tên bảng B trả về, ba thời điểm 0,05/0,45/0,85 s cho
  nam (`avatar_costume_544_m.obj` + `空手站立01`, `m01_跑步`), nữ (`avatar_costume_544_f.obj` + `空手站立01`,
  `g01_跑步`), quái `獠牙雪人.obj` (`站立`, `跑步`); `shots.log`/`shots2.log` ghi rc và cỡ file, `diff.txt` ghi độ lệch
  pixel giữa các khung (đứng 2,9–8,1 %, chạy 5,5–14,1 %). Lần chạy đầu, skill chạy của nam/nữ làm viewer văng ở
  t = 0,48 s: `AnimEffect` với `EffectTemplateName <template>` (bụi chân theo loại đất) gọi
  `TerrainTypeInfos::getTerrainTypeInfo` trên địa hình NULL → đã vá `getEffectInfo` dùng `findTerrainTypeInfo`
  (không địa hình → bỏ hiệu ứng), WXCore `// CYS-ACTIONSET`. Game.exe ở màn không có scene cũng gặp lỗi này nếu model
  diễn skill có `<template>`.
- `check_dbc_layout-strict.txt` (59 OK + 4 ABSENT), `test_dbc_schema.txt` (33 OK), `build-2.log` (rc 0).
- Game.exe không được chạy trong đợt này (hai agent khác đang dùng). Dòng log cũ `CYS action-set: … not found
  (client_GL uses ActionSet/ActionSet*.txt…)` chỉ còn phát khi không có bảng B; với Canonical, `Init` sẽ ghi
  `CYS action-set: B tables loaded` và `UpdateCharActionSetFile` không mở file per-model nữa.

## 9. Việc còn lại và ghi nhận dữ liệu

1. `ENUM_WEAPON_TYPE`/`CObject_Item_Equip::GetWeaponType` chưa biết đàn (6), liềm (7), đao tổ (8), trượng (9), nỏ (16),
   tiêu kiếm (17) → các vũ khí đó hiện diễn tay không. Cách làm gọn: lưu thêm `Type` của vũ khí trong
   `CObject_Character` và gọi `CysActionSet::SlotFromEquipType(Type)` thay cho enum.
2. Ẩn vũ khí/vũ khí chỉ định đã nối qua `OnHideWeapon(nAppointedWeaponID)` như 0.85; chưa kiểm trong game.
3. Cưỡi: chọn ghế theo tên bộ (mục 5) chưa có bằng chứng mã B; khi có dữ liệu giới tính trong CharacterData nên đổi.
4. Ghi nhận cho `canonical`/`game-data`: (a) `CharActionSet.txt` Việt hoá không ảnh hưởng hoạt cảnh (B không đọc);
   (b) 497 model `CharModelEx` cột 9 = −1 (không hoạt cảnh, đúng như client_GL); (c) `_DBC_CHARACTER_MOUNT::m_nMountActionSetID`
   nên đổi tên vì cột 5 không phải bộ động tác.
5. Cột C của ActionSetLine chưa rõ nghĩa; đã đọc và giữ.
