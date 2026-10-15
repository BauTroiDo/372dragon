# Game.exe chạy trên dữ liệu Canonical (client_GL)

Tài liệu của agent game-data, ngày 13/09/2026. Mục tiêu: Game.exe x64 của CY-Source đọc bộ dữ liệu đích
`Assets/Canonical/Data` (dựng từ client_GL = "B") thay cho bản 0.85 Reference mà các stage cũ vẫn dùng. Quyết định D
(12/09) áp dụng: cấu trúc bản ghi DBC và bộ đọc theo cột của client_GL.

## 1. Bảng DBC: danh mục, cấu trúc, cổng kiểm

**Danh mục.** `Registry/abi/dbc_inventory_gl.{json,tsv}` do `Tools/game/dbc_inventory.py build` sinh ra. Mỗi bảng Game.exe
đọc (khởi động, đăng nhập, chọn/tạo nhân vật, vào thế giới) có kiểu cột Canonical, tên cột (13 bảng có hàng tên),
ID bảng của B và kích thước bản ghi B truyền cho `GetDataBase(id, size)`. Bằng chứng B nằm ở
`Build/Logs/2026-09-13-game-data/ghidra/b-sizes*.tsv` (Ghidra trên bản sao, `Build/re/game-data`).
- 345 bảng; 63 bảng do `CDataBaseSystem::OpenAllDataBase` mở; 20 bảng do bộ đọc khác mở.
- Kích thước bản ghi trùng B ở 94 lời gọi. Ba chỗ lệch là SkillTemplate_V1, XianluShop và Zhounianshop. SkillTemplate_V1:
  B đọc 80/81 cột đầu (368 byte), Canonical có 82 cột (376 byte).

**Cấu trúc.** `Src/Engine/Interface/TDDBC_Struct.h` và `Src/Shared/Common/GameStruct_Skill.h` theo đúng cột client_GL,
giữ tên 0.85 khi nghĩa không đổi (ghi chú `// CYS:` và số cột `[n]` trên từng trường). Bảng đổi bố cục: CharHairGeo,
CharFaceGeo (qua DBC_CHARACTER_HEAD_GEO), CharModelEx, CharacterFace, CharMount, MonsterAttrExTable, PetAttrTable,
ItemVisualChar, ItemVisualLocator, White/Green/BlueEquipBase, CommonItem, GemInfo, StoreMapItem, EquipSetAttr,
SoundInfo, EffectDefine, XinFa_V1, SkillDeplete, MissionData, SpecialObjData, SceneDefineEx, BuildingDefine,
CityBuilding, InterfaceEx, GrowPoint, Ability, ItemCompound, CharTitle, SkillData_V1, StrDictionary, ItemRule,
StrFilter, ChatMood, ImpactDirectly, ImpactSEData_V1, Bullet, SkillTemplate_V1. Bảng mới: CharActionSet (bảng 10 cột),
ActionSetFile (DBC 112), EquipBase (DBC 316), CampAndStand.

**Bộ nạp.** `OpenAllDataBase` (`Src/Client/WXClient/DBC/GMDataBase.cpp`) dùng tên file của B (CharModelEx, CharFaceGeo,
SceneDefineEx, InterfaceEx, EquipBase, ActionSetFile). Mỗi hàng mang `sizeof(struct)` và chuỗi kiểu cột (I/F/S) sinh từ
Canonical. Sau khi nạp, bộ nạp so hai giá trị với bảng thật và ghi vào `WXClient.log`:
`DBC: <file> OK columns=.. records=.. record=..` hoặc `DBC ERROR: ...`. MissionList/Reward/Punish/Dialog không có trong
client_GL (B không nạp), nên được mở rỗng với dòng log `absent`.

**Cổng kiểm offline.** `Tests/abi/check_dbc_layout.py --strict` so từng hàng của danh sách với dữ liệu và bố cục struct
trên x86/x64. Kết quả `Registry/abi/dbc_layout_x64.tsv`: 59 OK + 4 ABSENT, 0 lệch. Sổ đăng ký cột
`Registry/abi/dbc_columns_gl.tsv` (1.402 cột: kiểu, offset x64, trường struct, tên cột của dữ liệu).
`Tests/abi/test_dbc_schema.py`: 33 bài, gồm cổng strict và bài padding struct lồng (SkillData_V1).
182 `static_assert` (`Src/Shared/Common/abi_asserts.h`) biên dịch được trên x86 và x64: các struct đã sửa đều có
con trỏ nên không thuộc diện assert.

Người đọc cột theo cách khác cần biết:
- SceneDefineEx cột 0 là ID cảnh server (không còn nLocalID/nCityLevel).
- Cột 5 là `.path` (navmesh PathLib). `LoadRegionBinary` bỏ qua file không phải `.region` và ghi log.
- CharMount không có cột pass-level.
- MonsterAttrExTable không có cột cannot-be-attacked.
- SkillData_V1 không có cột need-level/need-money.
- EquipSetAttr gồm 16 cặp (loại, giá trị).
- GemInfo có 4 cột kháng chen trước thuộc tính gốc (`CysGemAttr`).
- ItemVisualChar tách race 0/1 (`CysItemVisualEntity`).
- Action set: CharModelEx cột 9 trỏ vào ActionSetFile.txt.

## 2. Stage: `Tools/game/stage_game.py`

```
python -B Tools/game/stage_game.py build --name <tên> [--bin <thư mục build>] [--pdb] [--no-creation]
python -B Tools/game/stage_game.py check --stage Build/game-data/<tên> --out <thư mục> --gate
powershell -NoProfile -ExecutionPolicy Bypass -File Tools/game/run_game_smoke.ps1 -Stage Build\game-data\<tên>
```

Bố cục `Build/game-data/<tên>/`:

| Thư mục | Nội dung |
|---|---|
| `Bin64/` | Game.exe + DLL của một bản build: mặc định worktree `Build/wt-game-data`, vì bản CI 2e9d456 còn struct 0.85, không đọc đúng Canonical. Thêm các DLL runtime không build được (cg, CgProgramManager, d3dx9_43, D3DCompiler_43, fmodL), chép từ stage CI và kiểm sha256 theo `cys_stage.json`. `TerrainTypeInfo.cfg`/`WXTerrainType.cfg` chép (chỉ đọc) từ client_GL. `WXSystem.cfg` offline 127.0.0.1:14400, `System_CodePage=65001`. `WXResources.cfg`. Manifest `game_data_stage.json` có hash từng file. |
| `Data` | **Junction** tới `Assets/Canonical/Data`. Không chép 15 GB, không ghi gì qua junction: script từ chối mọi đích nằm dưới Canonical. |
| `Overlay/Pre/<Folder>` | Liệt kê **trước** Canonical: thắng khi tra theo tên gốc và theo đường dẫn có `\`. |
| `Overlay/Post/<Folder>` | Liệt kê **sau** Canonical: thắng khi tra theo đường dẫn tương đối đầy đủ; nơi chứa file mới. |
| `Patch/` | `LoginServer.txt` (fixture offline) và `WXLoginServer.txt` (một máy chủ giả, không bao giờ kết nối). |

**Cảnh báo xoá stage.** `Data` là junction. Muốn xoá stage phải gỡ junction trước (`rmdir <stage>\Data`, lệnh này chỉ xoá
liên kết), rồi mới xoá phần còn lại. Không bao giờ dùng `rmdir /s`, `shutil.rmtree` hay Explorer trên cả thư mục khi
junction còn đó: các lệnh ấy đi xuyên junction và **xoá Canonical**.

**Thứ tự tra tài nguyên** (mô phỏng đúng `OgreResourceGroupManager::addResourceLocation` bản CYS):
- Tên đầy đủ: vị trí thêm sau cùng thắng.
- Tên gốc trong vị trí đệ quy: vị trí đầu tiên thắng.
- File ở gốc của một vị trí về sau sẽ ghi đè tên gốc.
- Không có trong chỉ mục thì duyệt các vị trí theo thứ tự.

`WXResources.cfg` giữ bố cục `Bin/FairyResources.cfg` của client_GL (Bootstrap: OgreCore.zip, MaterialTemplates.zip;
General: Effect, Model 1–3, Interface, Material 1–5, Sound, Config; Brushes; Scene; mọi thư mục đệ quy). Pre đứng
trước, Post đứng sau. File phải thắng Canonical (bộ điều khiển CreateRole/SelectRole của CY, scheme đã gộp, StrFilter
rỗng, bản sửa ChatFrame, InterfaceEx đã lọc) được đặt ở cả Pre lẫn Post.

**Tên file (D1, `Docs/specs/render/07-fx-audit_vi.md`).** Lớp file ANSI của engine (ACP 1252) mở tên bằng byte GBK đọc
như cp1252 ("dạng engine"). Canonical đã theo quy ước này. Mọi tên trong overlay được kiểm là dạng engine. Tên
Unicode của S2 được đổi theo quy tắc: GBK → byte → cp1252; 5 byte trống của cp1252 ánh xạ đồng nhất như Windows.

**Hồ sơ đăng nhập GL.** Canonical chính là giao diện GL: 6 file LogOn/SelectServer/SoftKeyBoard đã có sẵn, không cần
gộp look/imageset. Overlay chỉ thêm: StrFilter rỗng (ngoại lệ đã được user duyệt), sửa ba descriptor ChatFrame nếu còn
lỗi, shim `CYS_WXDebug.overlay` cho Render.dll (lấy từ TLBB.overlay).

**Hồ sơ tạo nhân vật CY: rebase lên Canonical.** Nguồn là manifest và file đã áp dụng của stage
`Build/gpt-p1-1-20260913/stage-91148e1` (chỉ đọc, kiểm sha256), kèm bản backup "before" mà hồ sơ ghi lại.
- File mới (tên chưa có trong Canonical) → Post.
- File trùng byte với Canonical → bỏ qua.
- File khác byte, trùng tên với Canonical → **Canonical thắng** (ưu tiên ngang hàng client_GL); danh sách ghi trong
  manifest (`canonical_wins`).
- Bộ điều khiển CreateRole/SelectRole → thay GL (đặt ở Pre + Post).
- Scheme = scheme Canonical + các đăng ký CY mà hồ sơ thêm (tính theo backup).
- `all.material/.particle/.effect/.obj` và MaterialTemplates.zip: chỉ lấy khối CY mới/đổi so với backup mà Canonical
  chưa định nghĩa, đưa vào file script riêng (`CysCreate_*`). Không thay `all.*` của Canonical, để không đưa hiệu ứng
  0.85 cũ quay lại.
- Tên do nội dung overlay nhắc tới mà không tìm thấy ở đâu sẽ được lấy từ S2, đổi sang dạng engine.

**Tương thích UI.** `InterfaceEx.txt` của Canonical được lọc: bỏ các cửa sổ mà layout cần kiểu cửa sổ Falagard mà bản
build chưa đăng ký. Danh sách kiểu đã đăng ký đọc từ CEGUIFalagard.dll/UI_CEGUI.dll của stage. Nếu không lọc, CEGUI
ném ngoại lệ và Game.exe thoát, ví dụ Cloud_SelectServer → TLBB_NotSuperList → Falagard/NotSuperList. Mỗi cửa sổ bị bỏ
được ghi vào `ui_compat` của manifest như một việc chặn của lớp UI.

## 3. Kiểm tra

- `stage_game.py check`: mô phỏng chỉ mục tài nguyên và phân loại mọi tên được nhắc trong script (all.* và mọi
  .material/.program/.particle/.effect/.skill/.obj/.overlay), cảnh (.Scene/.Terrain), UI (layout, imageset, font,
  scheme, look) và bảng tạo nhân vật CY:
  - resolved: mở được;
  - unreachable: chỉ có file tên CJK, engine không mở được;
  - missing: không có ở đâu cả.
- `run_game_smoke.ps1`:
  - chạy `Game.exe -fl -cys-gl-login-smoke` offline, không đăng nhập và không kết nối (có kiểm socket);
  - lưu log cũ trước khi chạy, dừng đúng tiến trình mình mở;
  - chạy `Tests/ui/validate_gl_login_result.ps1`, rồi chặn nếu có `DBC ERROR` hoặc dump.

## 4. Kết quả trên stage `Build/game-data/dbc-3` (13/09 19:32)

| Hạng mục | Kết quả |
|---|---|
| Cổng DBC offline (`check_dbc_layout.py --strict`) | 59 OK + 4 ABSENT, 0 lệch; 182 static_assert x86 + x64 đạt |
| DBC trong game (`WXClient.log`) | `59 table(s) checked against the client_GL schema, 0 error(s), 4 absent` |
| Tên không mở được (D1) | stage cũ 91148e1: 11.688 tên (243.600 lượt nhắc), 15.750 file tên CJK → stage mới: **0** và 0 file CJK |
| Tên mở được / thiếu hẳn | 55.834 / 2.382 (file mà dữ liệu client_GL nhắc nhưng không kèm, ví dụ `11111111.dds`, `17_01.mesh`) |
| Smoke đăng nhập offline | sống đủ 75 s, không dump, 0 `(Error)` UISystem; đủ 4 mốc GL kể cả `PASS offline input; no authentication`; ảnh server/account/unicode/soft-keyboard hiện giao diện GL trên Canonical |
| TlbbViewer | cảnh GL Biwuzhaoqin và cảnh tạo nhân vật CY tl3chuangjian đều lên texture, exit 0 |

Bộ kiểm `validate_gl_login_result.ps1` chỉ dừng ở luật "không được thiếu hàm host". Hai hàm Lua host của GL,
`ZBS:IsViewerWatching` và `GMVisible:LuaFnGetViewType`, được LuaApiGen trả giá trị trung tính; đây là việc của lớp
Lua host. Danh sách việc chặn đầy đủ (UI widget GL, action set, navmesh `.path`, EquipBase, lỗi dữ liệu Canonical)
và toàn bộ bằng chứng nằm ở `Build/Logs/2026-09-13-game-data/HANDOFF.md`.
