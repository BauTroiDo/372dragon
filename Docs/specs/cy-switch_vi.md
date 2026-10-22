# Chuyển nền CY-Source sang CY 3.71 (cy-switch)

Ngày lập: 14/09/2026. Agent `cy-switch`, nhánh `cy-switch`. Bằng chứng: `Build/Logs/2026-09-14-cy-switch/`.

Chỉ thị người dùng ngày 14/09 (nguyên văn):
1. "Mục tiêu của chúng ta vẫn là client, server giống CY nhất, riêng GUI có thể tậng dụng GL cho đẹp (như hiện tại)"
2. "Không cần server gốc nữa, hãy tận dụng server gốc để dựng server riêng để chỉnh sửa nếu cần thiết"
3. "Chuyển về Dựng giống CY nha"

Quy ước: **[DK]** là dữ kiện đo được, có đường dẫn/offset. **[SL]** là suy luận. Nguồn: S4 = CY 3.71.9609 chính thức (`Tools/DATA NEW/CY Game`), S2 = DataCY (`Tools/DATA NEW/DataCY31-08-26`), S2b = tlbb15, GL = client_GL / `Assets/Canonical`.

---

## 1. Tóm tắt quyết định

| Lớp | "Giống CY" nghĩa là | Trạng thái 14/09 |
|---|---|---|
| Dữ liệu 3D, cảnh, hiệu ứng, âm thanh, bảng game | Byte của S4 (S2 cho wrapper 1–18) | **Xong pha CS0:** `Assets/CanonicalCY/Data`, 112.724 file, 21,88 GB |
| GUI (layout, skin, font, widget, dictionary Việt) | Giữ GL như hiện tại | Lớp GUI GL 6.117 file đã nằm trong CanonicalCY  (14/09 chiều: người dùng đổi sang GUI CY, agent cy-gui) |
| Struct DBC trong Game.exe | Theo cột CY (cả bảng GUI) | **Xong pha CS1** (nhánh cs1-tables, mục 3.4): 62 bảng CY OK; CampAndStand tạm giữ GL; InterfaceEx chờ dữ liệu GUI CY |
| Engine/render | Tính năng CY (ghi nhận D3D11, template CY) | Chỉ ghi nhận; agent camera3d làm camera/trời/cảnh xa |
| Lua host gameplay | Hành vi CY | Lua CY bị đóng gói (magic `D2 D1 E2 E1 B2 B1 C2 C1`), chưa giải |
| Giao thức | Giữ khung + ID skynet cho client tự dựng; gói mới theo **tên lớp CY** | CY Game.exe **không** nói được với skynet (mục 2) |
| Server | **Phương án A:** server riêng skynet, chuyển dần bảng/logic sang CY | Khuyến nghị; B (tlbb15) và C (tầng dịch) bị loại |

---

### 2.1 Số đo **[DK]**

| Chỉ số | client_GL | CY 3.71 | skynet | tlbb15 |
|---|---:|---:|---:|---:|
| Số lớp gói (factory) | 848 | 1.357 | 497 | 702 |
| ID trùng skynet (trên tên chung) | 488/488 | **24/447** | — | 25/422 |
| Gói login skynet (16): có tên / cùng ID | 15/15 | 15/13 | — | — |
| Gói game skynet (481): có tên / cùng ID | 473/473 | 432/**11** | — | — |


### 2.2 Kết luận

- **CY 3.71 Game.exe không chơi được trên server skynet (riêng hay gốc).** Mức chắc chắn: cao. Lý do quyết định: gói đầu tiên trên socket game là `CGConnect` mang ID 456; skynet giải thành `GCConnect` và `gamed.lua:178-179` assert "gói đầu phải là 49". Trước đó login cũng chỉ parse được một phần (bố cục `CLConnect`/`CLAskLogin` lệch). Không chạy thử live vì kết luận không phụ thuộc vào đó.
- **tlbb15 không hợp với client nào đang có:** ID trùng 6,0% với GL, 5,5% với CY, 5,9% với skynet, tức chỉ bằng mức trùng ngẫu nhiên của các ID login/thấp. Nó là server của một nhánh thứ ba (bố cục bảng HJ). Mức chắc chắn: cao về ID; không xét bố cục trường.
- Client của dự án là Game.exe dựng từ mã (ProtocolGen theo skynet), nên việc ID của CY khác **không chặn** việc dựng "giống CY". Nó chỉ loại việc dùng nguyên CY Game.exe làm client.


---

### 3.1 Bảng DBC **[DK]**

Công cụ `Tools/game/dbc_compare_cy.py` đọc S4 `Config.axp` trong bộ nhớ, S2 text và Canonical. Registry cột: `Registry/abi/dbc_columns_cy.tsv`.

- **Toàn bộ bảng:** CY 742, GL 431. Có ở cả hai 293 (200 cùng số cột), chỉ CY 449, chỉ GL 138.
- **81 bảng Game.exe nạp** (`Registry/abi/dbc_inventory_gl.json`): CY có 62. 35 bảng cùng kiểu cột, **27 bảng khác cột**:

| Bảng | GL → CY cột | GL → CY dòng |
|---|---|---|
| EquipBase | 101 → 103 | 20.840 → 24.531 |
| MonsterAttrExTable | 71 → 73 | 18.822 → 28.968 |
| PetAttrTable | 51 → 54 | 4.908 → 8.589 |
| SkillTemplate_V1 | 82 → 102 | 3.447 → 4.586 |
| SkillData_V1 | 48 → 54 | 16.493 → 20.667 |
| ImpactSEData_V1 | 22 → 28 | 5.376 → 9.419 |
| ImpactDirectly | 20 → 25 | 399 → 523 |
| ItemVisualLocator | 53 → 63 | 1.453 → 2.917 |
| CharModelEx | 10 → 21 | 4.906 → 7.616 |
| CharMount | 15 → 24 | 201 → 353 |
| CharTitle | 45 → 50 | 245 → 430 |
| CharFaceGeo / CharHairGeo | 11 → 12 / 13 → 14 | 234 → 444 / 340 → 608 |
| CommonItem | 27 → 28 | 10.093 → 20.440 |
| GemInfo | 81 → 84 | 753 → 1.195 |
| ItemCompound / ItemRule | 32 → 38 / 14 → 15 | 1.639 → 1.482 / 93 → 94 |
| XinFa_V1 | 29 → 37 | 128 → 120 |
| GrowPoint | 9 → 19 | 415 → 424 |
| LvMaxMoney | 3 → 12 | 150 → 150 |
| SceneDefineEx | 24 → 25 | 547 → 679 |
| SpecialObjData / SkillDeplete | 64 → 63 / 7 → 6 | 1.352 → 1.843 / 5.161 → 5.399 |
| ActionSet/ActionSetLine | 19 → 20 | 7.199 → 18.286 |
| Bullet / PlayerExpLevel | cùng số cột, khác kiểu | 227 → 337 / 150 → 150 |
| InterfaceEx | 9 → 10 | **giữ GL** (lớp GUI) |

- Nhiều bảng cùng cột nhưng CY lớn hơn hẳn: `ActionSet/ActionSet` 243.148 → 465.613 dòng, `StrDictionary` 77.579 → 154.822 (dictionary giữ bản Việt GL), `StrFilter` GL rỗng (theo yêu cầu 13/09) / CY 147.205.
- **Tên cột:** bảng client CY không mang tên cột (dòng 2 của bản text S2 lặp lại kiểu). Ánh xạ cột CY → GL trong `dbc_columns_cy.tsv` dựa trên giá trị trùng ở các ID chung (`dbc_inventory.align`), cộng các khoảng trống cùng độ dài/cùng kiểu giữa hai mốc (điểm `gap`): 1.283/1.551 cột CY đã có cột GL tương ứng; 35 bảng cùng kiểu ánh xạ đồng nhất; chỉ 4 bảng trùng nội dung hoàn toàn (CharEffect, CharRace, CreatureSound, MissionData).
- ID trùng nhưng khác nội dung là phổ biến (khảo sát `cy-gap` của cys-server: 6.668/17.807 quái, 1.650/2.858 SkillTemplate, 1.283 pet, 2.346 CommonItem khác tên trên cùng ID). Không chép dòng CY sang GL hay server theo ID.

Bằng chứng: `data/dbc_compare_cy.tsv`, `data/dbc_census_cy.{tsv,json}`.

### 3.2 Tài nguyên theo tên **[DK]**

Công cụ `Tools/pipeline/res_compare_cy.py` (CanonicalCY, bỏ lớp GUI, so với Canonical):

| Loại | CY | GL | Chung: giống / khác | Chỉ CY | Chỉ GL |
|---|---:|---:|---|---:|---:|
| Object `all.obj` | 11.495 | 6.771 | 3.356 / 840 | 7.299 | 2.575 |
| Material `all.material` | 85.730 | 65.059 | 32.751 / 2.307 | 50.672 | 30.001 |
| Effect | 19.038 | 13.014 | 7.126 / 101 | 11.811 | 5.787 |
| Particle | 59.813 | 43.297 | 19.957 / 1.004 | 38.852 | 22.336 |
| Skill | 5.829 | 4.290 | 2.119 / 525 | 3.185 | 1.646 |
| File `.mesh` (tên gốc) | — | — | 13.008 / 1.229 | 20.335 | 8.837 |
| File `.skeleton` | — | — | 2.268 / 1.281 | 4.910 | 2.322 |
| Texture | — | — | 7.909 / 15.471 | 27.096 | 15.310 |
| File cảnh (.Scene/.Terrain/.path/…) | — | — | 1.106 / 622 | 1.675 | 1.482 |
| Âm thanh | — | — | 762 / 0 | 1.268 | 233 |

- Texture "khác" chủ yếu do nhánh CY mã hoá lại DXT (cùng kích thước/định dạng, khác byte; D0 12/09). Mẫu 3.000 cặp: chỉ 89 khác do đệm đuôi. Skeleton khác phần lớn là đệm đuôi của bản giải S1 (mẫu 62/69).
- **`all.material` của CY định nghĩa trùng 184 material** (S4 và S2 như nhau; GL: 0). OGRE 1.2.5 ném `ERR_DUPLICATE_ITEM` và viewer bỏ phần còn lại của file (23 nghìn material). Đã sửa ở `OgreMaterialSerializer.cpp` (thẻ `CYS-CYSWITCH`: bản đầu thắng, ghi log).

### 3.3 Cảnh 2 (Đại Lý) **[DK]**

- SceneDefineEx cảnh 2: **CY dùng bản đồ mới** `dali_new_320.Scene/.path/.wCollision/.jpg`, minimap `dali_new_320`, cột 8 = 2106; GL dùng `dali.Scene/.path/.wCollision`, cột 8 = 101. Cả hai 320×320. CY thêm cột 25.
- File theo tên `dali*`: CY 96, GL 40; chung 2 (giống nhau). `dali_new_320.path` 1.188.746 B so với `dali.path` 411.119 B. Hai thành chính khác cũng đổi bản đồ ở CY: `luoyang_new` (512×512), `suzhou_new` (khảo sát cys-server).
- Viewer vẽ `dali_new_320.Scene` trên CanonicalCY: 5.982 object, 0 lỗi dựng, terrain 320×320.

Bằng chứng: `data/res_compare_cy.json`, `viewer/`.

### 3.4 CS1: struct DBC của Game.exe theo CY (14/09, agent cs1-tables)

**Quyết định cơ chế:** chuyển hẳn lúc build (không có hồ sơ dữ liệu lúc chạy). Game.exe từ nhánh `cs1-tables` chỉ đọc đúng `Assets/CanonicalCY`; `Assets/Canonical` (GL) chỉ còn làm đối chứng lịch sử. Stage GL cũ (world3b, replay) phải dùng binary trước CS1. Chỉ thị người dùng 14/09 chiều "Mọi thứ như CY": bảng GUI cũng theo CY (bỏ ngoại lệ GUI giữ GL).


**Kết quả:**
- 25 struct đổi theo CY (bảng ở `Registry/abi/dbc_struct_columns_cy.tsv`, thành viên theo cột) + `_DBC_UI_LAYOUTDEFINE` (InterfaceEx 10 cột). Thành viên giữ tên GL khi cột căn được; cột mới/chưa rõ = `unk_N`, không đọc.
- Đổi đáng chú ý: MonsterAttrEx xếp lại khối (exp/AI/phe/rơi đồ dời về cột 64–72); SkillTemplate 31 cấp skill (cột 48–78); SkillData_V1 đảo cột 1–4 và 15 cặp tham số; ItemVisualLocator vũ khí phải/trái cột 2/5, hiệu ứng ngọc cột 29–58; PlayerExpLevel cột 1 là STRING; Bullet cột 2 INT; ImpactDirectly nhóm 4 ô.
- Bảng không có ở CY: HairStyle (bảng rỗng), Mission* (rỗng như trước). **CampAndStand** CY không có; bảng rỗng làm mọi quan hệ phe thành FRIEND nên **tạm giữ bảng GL** (stage chép vào `Overlay/Post/ConfigFolder`) tới khi lần ra logic quan hệ của CY — ngoại lệ GL duy nhất còn lại.
- Gate `check_dbc_layout.py --strict` (mặc định CanonicalCY): 62 bảng CY OK (57 OpenAllDataBase + 5 loader khác) + CampAndStand giữ GL + 5 vắng. Sau khi InterfaceEx đổi sang CY, bảng này là **PENDING** (struct khớp bảng CY tham chiếu S2; dữ liệu CanonicalCY vẫn là lớp GUI GL cho tới khi agent cy-gui thay) → cần `--allow-pending` đến lúc đó.


## 4. Định nghĩa "giống CY" theo từng lớp

1. **Dữ liệu.** Mọi tài nguyên không phải GUI lấy từ S4 3.71.9609; wrapper 1–18 lấy S2 cắt đúng độ dài payload S4. Không trộn bản GL cùng tên. Nội dung GL không có trong CY (hàng nhập 2026 riêng của client_GL, hệ PetSoul/ShenBing…) chỉ vào bằng đợt nhập có ID riêng, sau cờ.
2. **Bảng/struct Game.exe.** Struct DBC theo cột CY (`dbc_columns_cy.tsv`). Riêng bảng GUI (`InterfaceEx`, `StrDictionary`, `StrFilter`) giữ bản GL.
3. **Engine/render.** Hành vi hình ảnh theo CY: template `MaterialTemplates.zip` của CY, camera/trời/cảnh xa theo CY (agent camera3d). **Chỉ ghi nhận, chưa làm:** CY có `RenderSystem_Direct3D11.dll` bên cạnh D3D9, `Render.dll` 4.057.088 B (GL 3.991.552 B), `nvtt.dll`, `ccore.dat`, `rail_api.dll` (WeGame).
4. **Gameplay / Lua host.** Hàm host và luật client theo CY. Lua CY trong `Interface.axp`/`Config.axp` bị đóng gói (magic `D2 D1 E2 E1 B2 B1 C2 C1`; `Config.axp` có 1.130 file Lua sự kiện/obj). Lua GUI dùng bản plaintext GL. Muốn đọc Lua CY phải lần hàm nạp trong CY Game.exe (việc riêng).
5. **Giao thức.** Khung 6 byte và seq 0x7B như nhau ở GL/CY/skynet: giữ nguyên. ID: client tự dựng giữ ID skynet cho 447 gói chung. Gói hệ thống CY mới mang **tên lớp CY** và dùng **ID của CY** nếu ID đó còn trống ở skynet (705/910), để về sau so với CY Game.exe dễ hơn. Bố cục trường của gói CY lấy từ `Write/Read` trong CY Game.exe.
6. **Server.** Hành vi CY trên server riêng: bảng theo ID CY (cột server bù từ HJ), bản đồ CY, đánh số môn phái CY, hệ thống CY.

---

## 5. Phương án server

| | A. Giữ skynet riêng, chuyển dần sang CY | B. Server khác (tlbb15) | C. Tầng dịch cho CY Game.exe |
|---|---|---|---|
| Hợp client dự án | Có (ProtocolGen = skynet, 488/488) | Không: ID khớp ~6% với mọi client | Chỉ để chạy CY Game.exe gốc |
| Chi phí | Lớn nhưng chia được: bảng/scene/môn phái/hệ thống theo đợt | Rất lớn: binary C++ bị hook, không có mã, không sửa được; phải viết lại client theo ID của nó | Rất lớn: dịch ID 447 gói + bố cục trường từng gói (4/4 gói đã xem đều lệch), 910 gói CY không có đích |
| Rủi ro | Khối lượng dữ liệu; lệch ID trên DB nhân vật | Chạy binary lạ (ASLR off, `LD_PRELOAD`), mật khẩu trong config | Không có server CY để dịch tới, nên hành vi vẫn là skynet |
| Kết luận | **Khuyến nghị** | Loại; chỉ dùng tlbb15 làm nguồn tham chiếu cột/ script HJ (đọc tĩnh) | Loại. Nếu cần "oracle" CY thì giới hạn login → vào cảnh → đi (~15 gói), không làm trước CS3 |

---

### CS0 — Đo và gốc dữ liệu (XONG 14/09)
- DoD đạt: mục 2, 3; `Assets/CanonicalCY/Data` idempotent (chạy lại ghi 0 file), verify sâu sha256; viewer vẽ cảnh 2 và 2 nhân vật CY.

### CS1 — Game.exe đọc bảng CY (client, offline)
- Đổi 27 struct theo `dbc_columns_cy.tsv`; consumer đổi cột (ItemVisualChar/Locator, CharModelEx 21 cột, EquipBase 103, SceneDefineEx 25…). Bảng GUI giữ GL.
- `Tools/game/stage_game.py` thêm hồ sơ `--data CanonicalCY` (junction như Canonical).
- **DoD:** `Tests/abi/check_dbc_layout.py --strict` trên CanonicalCY 62/62 OK, 0 lệch; log `DBC: … 0 error(s)`; smoke đăng nhập offline (GUI GL) chạy đủ 75 giây, 0 fatal; unreachable 0 (quy tắc tên stage_game).
- Tác động: stage world3b/replay và CI hiện chạy trên Canonical GL; giữ song song tới khi CS2 đạt, rồi đổi mặc định.

### CS2 — World CY offline
- `dali_new_320.path` qua PathLib; ActionSet CY (465.613 dòng, ActionSetLine 20 cột; bổ sung loại vũ khí 4 phái CY vào ENUM_WEAPON_TYPE); ngoại hình qua CharModelEx/ItemVisualLocator CY; camera/trời CY (camera3d).
- Replay hiện có ghi toạ độ trên `dali` cũ: cần bản bắt mới trên server riêng sau CS3a hoặc replay tổng hợp.
- **DoD:** replay vào cảnh 2 CY, in_world, 0 decode failure; đi bộ click-to-move trên navmesh CY; ảnh nhân vật ở quảng trường Đại Lý mới có HUD GL.

### CS3 — Server riêng theo CY (phương án A)
- **CS3a bản đồ:** chuẩn scene ID theo SceneDefineEx CY; dựng `.scn`/`.path`/`_monster.ini`/`_area.ini` cho `dali_new_320`, `luoyang_new`, `suzhou_new` từ file client S4; dời toạ độ hồi sinh/truyền tống.
- **CS3b môn phái:** một bảng ánh xạ số phái GL → CY áp cho XinFa, SkillTemplate, EquipBase, script, DB (cys-server đo: CY 15 phái, không có 曼陀山庄).
- **CS3c bảng:** Monster/Pet/Skill/Impact/Item theo ID CY; cột chỉ-server lấy từ bảng HJ (skynet/tlbb15) theo tên/model; ID riêng GL dời sang dải riêng. Bảng server vẫn GBK.
- Sửa 6 lỗi server đã có patch (`Build/Logs/2026-09-14-live-endpoint/server-patches`).
- **DoD:** `cys_server.ps1 backup` trước; restart khi 0 client; bot `CysNetBot` login → vào `dali_new_320` → đi → CGAskQuit, 0 lỗi server mới; stage CS2 vào world live.

### CS4 — Hệ thống CY
- Theo đợt (đề xuất của cys-server): 重楼/升阶 → 神器9 → 内丹/幻灵 → 星阵 → 内甲; mỗi hệ gồm bảng S4, codec gói (tên + bố cục từ CY Game.exe), handler Lua server, UI (GL nếu có, không thì dựng từ layout CY).
- **DoD mỗi hệ:** `packets.yaml` sinh lại, cổng protocol đạt, bot + GUI dùng được hệ đó.

### CS5 — Tuỳ chọn
- Giải Lua CY đóng gói (tham chiếu hành vi client). Tầng dịch tối thiểu cho CY Game.exe (chỉ khi cần đối chứng hình ảnh/camera).

---

## 7. Giữ gì từ GL

- `InterfaceFolder` GL (4.340 file: layout, Lua plaintext, scheme/looknfeel, font, `NotoSansSC-Regular.ttf`).
- 1.774 texture mà imageset/font GL trỏ tới (nằm trong `Material*Folder` GL).
- `ConfigFolder/InterfaceEx.txt`, `StrDictionary.txt` (Việt, UTF-8 hai cột), `StrFilter.txt` (rỗng).
- Con trỏ GL nhúng trong Game.exe, widget Falagard GL, nhịp khung/UI của các agent trước.
- 53 tham chiếu GUI GL không giải được (`Schema\tahoma.ttf` của GLResponsive…) cũng thiếu ở client_GL: `_manifest/gui_unresolved.tsv`.

## 8. CanonicalCY (pha CS0)

- Công cụ: `Tools/pipeline/build_canonical_cy.py --plan | --apply | --verify [--deep]` (6 tiến trình). Nguồn chỉ đọc; không đụng `Assets/Canonical`.
- Tên thư mục theo Canonical (`<Archive>.axp` → `<Archive>Folder`); tên file dạng engine (GBK đọc qua cp1252, như `stage_game.engine_name`).
- Kết quả: 112.724 file / 21.881.526.056 B; `cy-s4-plain` 56.762, `cy-s4-w19-25` 42.476, `cy-s2-w1-18` 7.368, `cy-s4-root` 3, lớp GUI GL 6.117. Loại ra 2.122: 1.143 cùng đường dẫn GUI GL, 974 cùng tên gốc GUI GL (trong Interface), 3 bảng GUI, **2 va chạm hoa/thường** (`文`→`ÎÄ` và `武`→`Îä` chỉ khác hoa/thường trên NTFS; giữ tên gốc nhỏ hơn).
- Manifest: `Assets/CanonicalCY/_manifest/{files,plan,excluded,missing,gui_layer,gui_unresolved}.tsv`, `canonical_cy.json`, `verify-deep.json`.
- Kiểm:
  - `--apply` lần đầu 148 giây; chạy lại ghi **0** file; `--verify --deep` 112.724/112.724 sha256 khớp, 0 file thừa (mở mọi file bằng tên dạng engine → 0 tên không mở được).
  - Mô phỏng chỉ mục OGRE (`Tools/pipeline/reach_canonical_cy.py`, dùng `stage_game.check_references`): 75.790 tên giải được (827.319 tham chiếu), **unreachable 0**, file tên CJK 0, thiếu 104 tên (208 tham chiếu, chính dữ liệu CY không có).
  - TlbbViewer (bản build nhánh này, có sửa material trùng) trên `--data Assets\CanonicalCY\Data`: 85.874 material, 59.813 particle, 19.039 effect, 5.829 skill, 11.494 object, 0 script bị bỏ; `dali_new_320.Scene` 5.982 object, 0 lỗi; hai nhân vật CY `NPC男主角门派时装从刃.obj`/`NPC女主角门派时装从刃.obj` vẽ đủ. `男主角.obj`/`女主角.obj` là khung ghép (0 entity), cần ghép bộ phận như `avatar.py` (việc CS1/CS2 vì `avatar.py` đang đọc cột GL).
  - Trước khi sửa material trùng: viewer dừng ở material trùng đầu tiên, 62.384 material, tường/cây trắng (`viewer/scene-dali-new-1.png`).

## 9. Quyết định cần người dùng

Chỉ các việc không tự quyết được theo luật hiện hành:

1. **CS3b đánh số môn phái theo CY** đổi số phái của nhân vật đã lưu trên server riêng (4 phái CY đã nhập đang ở 13–16 theo GL). Nhân vật test `CYTest00` (GUID 200001) sẽ được chuyển bằng script có sao lưu. Nếu người dùng muốn **xoá** nhân vật/tài khoản test thay vì chuyển, cần xác nhận.
2. **Bản đồ mới Đại Lý/Lạc Dương/Tô Châu** làm toạ độ nhân vật đã lưu trên bản đồ cũ không còn hợp lệ. Mặc định: dời về điểm hồi sinh của bản đồ CY, không cần hỏi. Chỉ hỏi nếu người dùng muốn giữ bản đồ cũ song song.
3. **client_GL đang chơi và server gốc** không còn là đích. Không đổi gì trên đó; mọi thay đổi ở CanonicalCY và server riêng.
