# Đặc tả hệ ActionSet của client_GL (B) và cài đặt trong CY-Source

Ngày lập: 14/09/2026 (agent `actionset`, nhánh `actionset`). Bằng chứng nằm ở `Build\Logs\2026-09-14-actionset\`.

Quy ước trong tài liệu: **[DK]** = dữ kiện đo được trên dữ liệu hoặc đọc được từ mã máy của B; **[SL]** = suy luận
của người viết, có nêu căn cứ. Địa chỉ hàm là VMA trong `C:\TLBB\085\client_GL\Bin64\Game.exe` (image base
`0x140000000`, SHA-256 `ce0c4fec7666595ca7adb250fcd8075c28f04d1852d05111c88b730f57e1c763`, 10.940.960 byte, bản đã vá
15 ô ngày 09/09/2026; dịch ngược lấy từ project Ghidra `C:\TLBB\085\analysis\ghidra\game-exe-proj` là bản TRƯỚC vá,
khác đúng 133 byte, không đụng các hàm được trích ở đây trừ các hằng số ô đã ghi trong mục 3.3).

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

Cả bốn file là text tab, **hai dòng đầu là kiểu cột** (`INT`/`STRING`), CRLF, tên là byte GBK. B đọc chúng bằng đúng
bộ nạp DBC text của 0.85 (`FUN_140124c30` = `CDataBase::Util_OpenDBCFromTxt`, nhóm tài nguyên `"General"`).

| File | Dòng dữ liệu | Cột | Ý nghĩa |
|---|---:|---|---|
| `ActionSetFile.txt` | 1.724 | `id, tên file` | id bộ động tác → tên (chỉ còn là nhãn; 530 = `男主角.txt`, 263 = `女主角.txt`, 501 = `獠牙雪人.txt`, 699 = `虎.txt`). |
| `ActionSet/ActionSet.txt` | 243.148 | `record, set, action, line` | Với mỗi bộ, mỗi action → chỉ số dòng trong ActionSetLine. Các dòng của một bộ **liền nhau** và bộ tăng dần (B dựa vào đó, mục 3.1). Cột record không dùng. |
| `ActionSet/ActionSetLine.txt` | 7.199 | `line, ô 1..15, A, B, C` (19 cột; gốc 15 = 11 ô) | Một dòng = một hành động cụ thể; mỗi ô là **id tên** (không phải tên) cho một loại vũ khí. Cột 0 = chỉ số dòng, trùng thứ tự hàng (0 lệch). |
| `ActionSet/ActionSetKV.txt` | 5.727 | `id, tên` | id 0..5726 liên tục; **id 9 là chuỗi rỗng** (= "không hoạt cảnh"). 1.558 tên có tiền tố `m01_`/`g01_` là **tên skill trong all.skill**, không phải track. |
| `CharActionSet.txt` | 92 (DBC nhị phân, 10 cột) | `id, 9 tên` | Bảng soạn thảo của 0.85; **B không đọc** (đã Việt hoá trong Canonical mà B vẫn chạy; hàm nạp B chỉ mở ba file trên). Game.exe CY-Source vẫn nạp nó vào DBC 90 nhưng không dùng cho hoạt cảnh. |

Ba cột phụ của `ActionSetLine.txt` (phân bố trên 7.199 dòng) [DK]:

| Cột | Giá trị | Ý nghĩa | Căn cứ |
|---|---|---|---|
| A (cột 16) | 0: 5.658 dòng; 1: 1.541 dòng (ngồi, biểu cảm, chào, ngủ, mở rương, ném tuyết…) | **ẩn vũ khí** (`bHideWeapon` của 0.85) | 0.85 cột 10 = A trên 145.748 + 755 dòng so sánh, chỉ 15 dòng lệch. Hàm đọc B tại `0x1400e3ffd/0x1400e4001` (offset +0x16). |
| B (cột 17) | −1: hầu hết; 361 (采药), 362 (钓鱼), 363 (采矿), 364 (扫地/招式), 642, 1251–1257 (khi cầm đàn) | **vũ khí chỉ định**: id visual của đồ vật cầm thay vũ khí khi diễn hành động (`nAppointedWeaponID`; 0.85 `OnHideWeapon` → `EquipItem_BodyLocator(HEQUIP_WEAPON, id)`) | 0.85 cột 11 = B trên 146.518/146.518 dòng. Hàm đọc B `0x1400e3f5a/0x1400e3f5e` (offset +0x18); `FUN_140116180` dùng nó khi nhóm vũ khí = 7 (đàn) rồi tra bảng locator DBC 0x146. |
| C (cột 18) | −1: 6.968; 0: 231 (đứng 1096, chạy 1099, tiềm hành, lên cấp…); 1: 2 | Chưa rõ; B đọc ở `0x1400e409e/0x1400e40a2` (offset +0x1a). **[SL]** cờ "cho phép hoà trộn/không cắt" của các hành động lặp; không có trong 0.85 nên CY-Source chỉ đọc và giữ (`GetExtraC`). | phân bố + vị trí hàm đọc |

## 3. B nạp và tra bảng như thế nào (Game.exe) [DK]

### 3.1 Nạp — `FUN_1400e35b0` (gọi từ `FUN_1403df910`, tương ứng `CActionSetMgr::Init`)

- Đường dẫn = `this+0x98` (chuỗi thư mục, `"ActionSet/"`) + tên file; chuỗi `"ActionSetLine.txt"` ở `0x1407036a8`, tham
  chiếu tại `0x1400e387b`. Nạp bằng `FUN_140124c30(path, dbc, 0, "General")` (bộ nạp DBC text 0.85). Có log
  `"CActionSetMgr::Init ActionSet.txt FileNum Too Big : %d"`.
- Trước đó B đọc bảng DBC id `0x6c` (108 = ActionSetFile) thành mảng `(id, tên)` 16 byte/mục tại `this+0x48`, số mục
  `this+0x50`.
- `ActionSet.txt`: cờ `this+0xb8 = 1` khi mở được (0 = dùng đường per-model 0.85). Mảng `(action, line)` 2 × int16 tại
  `this+0x68`; mảng mô tả bộ 0x18 byte/bộ tại `this+0x58` gồm `+0 set id (int16)`, `+8 con trỏ vào mảng (action, line)`,
  `+0x10 số action (int16)`; bộ mới bắt đầu khi set id đổi (vì thế các dòng một bộ phải liền nhau).
- `ActionSetLine.txt`: bản ghi cố định **0x1c byte = 11 ô × int16 + 3 phụ × int16** tại `this+0x70`, số dòng
  `this+0x78` (int16); vòng đọc cột 1..11 rồi cột 12/13/14 ghi vào +0x16/+0x18/+0x1a. Sau bản vá 09/09: 0x24 byte, 15 ô,
  phụ ở +0x1e/+0x20/+0x22 (19 chỗ vá, xem `Tools\add-phai\HUONG-DAN-THEM-LOAI-VU-KHI-VA-TU-THE_vi.md` mục 10).
- `ActionSetKV.txt`: bảng offset int32 tại `this+0x80`, khối chuỗi `this+0x88`, số tên `this+0x90` (uint16).
- **Số ô là hằng biên dịch trong B**; đọc cột không có trong file thì bộ nạp DBC **ném ngoại lệ** (bẫy đã sập 09/09).
  CY-Source lấy số ô từ số cột của file (mục 5).

### 3.2 Tra — `FUN_1400e3db0(mgr, set*, action, ô)`

```c
if (mgr->b8 == 0)  return legacyDbc->Search_Index_EQU(action)->pWeapon_Set[ô];   // đường 0.85: struct 13 cột, tên ở +8+ô*8
for (i = 0; i < set->count; ++i) if (set->pairs[i].action == action) {
    line = set->pairs[i].line;  if (line < 0 || line >= mgr->lineCount) return NULL;
    id = mgr->lines[line*14 + ô];            // imul rcx,rcx,0xe: bước theo PHẦN TỬ 2 byte (18 sau vá)
    if (id >= mgr->nameCount) return NULL;
    return mgr->nameBase + mgr->nameOffset[id];  // có thể là chuỗi rỗng (id 9)
}
return NULL;
```

Tìm tuyến tính, **dòng đầu tiên trùng action thắng**. Không kiểm `ô` ở đây; hai hàm bao kiểm.

### 3.3 Hai hàm bao chọn ô (vtable +0x530 / +0x538 của lớp nhân vật; con trỏ `0x1409df978`, `0x1409df984`)

`FUN_1400f9110(this, action, ô, set*)` — hoạt cảnh của **nhân vật** (0 → dùng `this[0x5e]` = bộ của nhân vật):

1. `type = vcall +0x2a0` (loại nhân vật). Nếu `type` ∈ {0, 1} (người chơi mình/khác): có dữ liệu nhân vật và
   `vcall +0x540` (id model biến hình) ∉ {0, 1} → **ô = 9**.
2. `type` ∈ {2, 3} (quái/NPC, pet) → **ô = 9**.
3. Ngoài ra: dữ liệu nhân vật có `mountID (+0xa0) != -1` (đang cưỡi) → **ô = 9**.
4. `ô > 10` (`cmp ebx,0xa` tại `0x1400f91c2`; 0xe sau vá) hoặc bộ rỗng hoặc `action == -1` → NULL; còn lại gọi 3.2.

`FUN_1400f9200(this, action, ô)` — hoạt cảnh của **thú cưỡi** (`this[0x5f]`): `type == 2` → ô = 9; `ô < 11`.

Kết luận: **ô 10 (cột NPC của 0.85) không bao giờ được B chọn**; quái, NPC, pet, người biến hình và người đang cưỡi đều
dùng ô 9. Các caller truyền ô từ `this+0x17c`, là kết quả của 3.4.

### 3.4 Loại vũ khí → ô — `FUN_140421ff0(item)` (gọi từ `FUN_1400f7860`, `FUN_140113b40`, `FUN_140115180`, `FUN_140116180`, `FUN_1402ad670`)

`switch (Type % 30)` với Type = cột 3 `EquipBase` của vũ khí đang mặc (vtable +0xb8): `0→2, 1→1, 2→4, 3→3, 4→5, 5→6, 6→7,
7→8`, còn lại → 0 (tay không); sau vá 09/09 thêm `8→11, 9→12, 16→13, 17→14`, 10..15 vẫn → 0. `FUN_140113b40` ghi kết
quả vào `this+0x17c` khi mặc/tháo vũ khí; không có vũ khí → 0. (Chi tiết mã máy: mục 10.3 của hướng dẫn add-phai.)

### 3.5 Đổi hoạt cảnh — `FUN_1400f7860` (= `CObject_Character::ChangeAction`)

`name = vcall +0x530(action, this+0x17c, 0)`; **`name == NULL` → return** (giữ hoạt cảnh đang chơi); chuỗi rỗng đi tiếp
→ `LogicModel::_changeAnimation("")` đặt `mCurrentAnimationState = NULL` (model đứng khựng ở khung cuối). Cùng logic có
trong 0.85 (`Obj_Character.cpp`, `ChangeAction`) và `WXLogicModel.cpp` dòng 1625.

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

## 5. Chọn bộ theo model, thú cưỡi

- **Model** [DK]: `CharModelEx.txt` cột 9 = id `ActionSetFile.txt`. Canonical: 4.906 model, 4.409 có bộ (497 ghi −1),
  **0** bộ không có dòng trong `ActionSet.txt`; 1.724/1.724 file đều có dòng.
- **Người cưỡi** [DK về dữ liệu, SL về mã B]: `CharMount.txt` cột 6 = bộ ghế chính cho nữ, cột 7 cho nam (282 =
  `女主角_虎.txt`, 549 = `男主角_虎.txt`, 291/558 ngựa…, 201/201 dòng đều có cả hai), cột 9/10 = ghế phụ. 0.85 giữ
  các bộ này ở `CharModelEx` cột 10.. (Reference: `男主角.obj … 男主角.txt 男主角_虎.txt 男主角_马.txt`) và chọn bằng
  `CharMount` cột 6 (chỉ số 0/1). Hàm B chọn ghế chưa dịch ngược; CY-Source chọn ghế theo **tên bộ của nhân vật** (bộ
  `男主角.txt` → ghế có tên bắt đầu `男主角_`), không có thì lấy ghế nam.
- **Cột 5 `CharMount`** (447 = `段正淳.txt` cho 虎, 448 = `段誉.txt` cho ngựa…) **không phải** bộ động tác: giá trị y hệt
  trong 0.85 (`Reference CharMount.txt` cột 5) khi `ActionSetFile.txt` chưa tồn tại [DK] → **[SL]** id model/âm thanh
  cũ. Tên `m_nMountActionSetID` trong `TDDBC_Struct.h` (agent game-data) vì thế là sai nghĩa; đề nghị đổi.
- **Thú cưỡi** [SL]: bộ của model thú lấy từ `CharModelEx` cột 9 của chính nó (1010 `虎.obj` → 699 `虎.txt`, 1011
  `黄骠马.obj` → 896 `黄骠马.txt`); mọi ô của các dòng thú giống nhau nên ô truyền vào không quan trọng.
- Action id khi cưỡi: bộ ghế có cùng action id (0 đứng, 4 chạy…) nhưng tên hoạt cảnh riêng (`单短骑乘跑步_虎`), nên
  logic 0.85 không phải đổi. Các action 29–50 trong `男主角.txt` (`骑乘站立_马`…) là di sản, không cần dùng.

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
