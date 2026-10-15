# CI trên CanonicalCY (ci-cy, 14/09/2026)

Nhánh `ci-cy` (worktree `Build\wt-ci-cy`). Bằng chứng: `Build\Logs\2026-09-14-ci-cy\` và `Build\Logs\ci\<sha>\`.
Bối cảnh: từ main 75b3802 (CS1) Game.exe/DLL đọc bảng DBC theo cột CY 3.71 nên **chỉ chạy đúng trên
`Assets\CanonicalCY\Data`**; CI trước đó vẫn stage trên `Assets\Canonical\Data` (GL) và các cổng kiểm đòi số liệu GL
(488 `.path`, 548 `.Scene`, 5 ca viewer GL trong đó 18/43 model, 45/100 effect, 10/10 cảnh không có trong CY).
Chỉ thị người dùng: "Thôi sử dụng khung CY luôn đi, không cần GL nữa. Mọi thứ như CY đi."

## 1. Những gì đổi

| Thành phần | Trước (GL) | Sau (CY) |
|---|---|---|
| `Tools\build\ci_common.ps1` | `CanonicalData = Assets\Canonical\Data` | thêm `CanonicalCYData`, `CyGameBin64`; hàm `Get-CysDataDir` (đòi `OgreCore.zip`, `MaterialTemplates.zip`, `ModelFolder`, `MaterialFolder`, `EffectFolder`, `SceneFolder`, `Scene2Folder`; thiếu → **throw**, không có fallback GL/client_GL) |
| `stage.ps1` | Canonical GL, thiếu thì `client_GL\Data` | `Get-CysDataDir` hoặc `-Data` tường minh; `TerrainTypeInfo.cfg` lấy từ `Tools\DATA NEW\CY Game\Bin64` (trùng byte với client_GL, fallback client_GL); ghi `data_dir`/`data_reason` vào `cys_stage.json`; thêm `-Root` |
| `smoke.ps1` | dùng `data_dir` của stage | như cũ + kiểm `data_dir` tồn tại; thêm `-Root`; tài liệu theo `cases.json` CY |
| `checks.ps1` pathlib | `488 files` ghi cứng, `client_GL\Data\SceneFolder` | đếm `*.path` trong `SceneFolder` + `Scene2Folder` của thư mục dữ liệu lúc chạy (**418** trên CanonicalCY 14/09) và đòi `N files, N parsed ok, 0 parse-fail, 0 CRASH` |
| `checks.ps1` scene | `548` ghi cứng, client_GL | đếm tên `*.Scene` duy nhất (không phân biệt hoa/thường, như `findResourceNames`) trong hai thư mục (**512**) và đòi `Scene files found = N`, `Scenes loaded = N`, `RESULT: PASS (failures 0, unknown keys 0, unit checks ok)`; kiểm stage cùng `data_dir` |
| `checks.ps1` protocol | — | giữ nguyên (không phụ thuộc dữ liệu) |
| `ci.ps1` | — | thêm `-Root` (chạy bản script của worktree nhánh trên `Build\ci`, `Build\cmake\ci-x64`, `Build\Logs\ci` của cây chính; commit vẫn giải trong repo chính vì worktree dùng chung object store) |
| `Tests\oracle\make_cases.py` | GL ghi cứng (`client_GL`, `models_S1.tsv`) | `--profile cy|gl`, `--data`, `--index`, `--out`, `--name`; ca model phải có trong `all.obj` của dữ liệu **và** mọi `.mesh` có trên đĩa; `cy` = CanonicalCY + `models_S2.tsv` (S2 = DataCY, 11.492/11.495 obj trùng `all.obj` CY) |
| `Tests\oracle\cases.json` | 43 model / 100 effect / 10 cảnh GL | **46 model / 100 effect / 10 cảnh CY**; bản GL cũ giữ nguyên byte dưới tên `cases_gl.json` + `cases_gl.tsv` (không dùng trong CI) |
| `Tests\pathlib\pathlib_test.cpp` | `load <dll> <folder>` | `load <dll> <folder> [<folder2> ...]`: tổng một dòng `LOAD TEST`, in số file từng thư mục |
| `Tests\scene\scene_test.cpp` | chỉ `SceneFolder`, `Model[1-3]Folder`; unit check ghi cứng `mantuoshanzhuang.EnScene` | thêm `Scene2Folder`, `Model4–8Folder` (chỉ thêm thư mục tồn tại); unit check EnvKey chọn `mantuoshanzhuang` nếu có, không thì EnScene đầu tiên có ≥ 3 key và kiểm theo **thời điểm thật của key** (trung điểm hai key liền nhau, và trung điểm vòng qua nửa đêm); mặc định `--data` = CanonicalCY |
| Parser cảnh (`Src\Engine\WXCore\CYS\Scene`) | 10 khoá lạ + 10 file `.hdr` lỗi trên CY | xem mục 3 |

## 2. Bộ ca đối chứng CY (`Tests\oracle\cases.json`)

Sinh bằng (từ cây chính, hoặc từ worktree với `--data/--index` trỏ về cây chính vì `Assets` không có trong worktree):

```powershell
$env:PYTHONUTF8=1
& "C:\Program Files\Python313\python.exe" Tests\oracle\make_cases.py --profile cy `
    --data C:\TLBB\085\CY-Source\Assets\CanonicalCY\Data --index C:\TLBB\085\CY-Source\Assets\Staging\index\models_S2.tsv
```

- Pool: 11.445 obj hợp lệ (complete=ok, verts>0, có trong `all.obj` CY, đủ mesh trên đĩa), 19.038 effect, 512 cảnh.
- Model (46): `player` 8 = `^npc[男女]主角` (nhân vật đủ bộ phận; `男主角.obj` trần là khung ghép 0 entity nên loại), `pet` 10 (toàn 2026), `mount` 6 (`ride_2026*`), `costume` 8 (`top_/back_2026*`), `weapon` 8 (`dweapon_2026*`), `boss_npc` 6 (`npc*_2026*`). Điểm ưu tiên 2026 > 2025 > có animation > texture > đỉnh, rồi băm tên → ổn định.
- Effect (100): 12 mỗi kiểu mới `NewRibbonTrail/RevoluMove/SequenceFrame/Dissolve/RotationCurve`, 7 `UIParticle`, 10 `PolarMove`, còn lại classic.
- Cảnh (10): `dali_new_320`, `luoyang_new`, `suzhou_new`, `tlbb3_login`, `tl3chuangjian` (tạo nhân vật), `login_bianjing`, `fengming_new_320`, `FengYun_lingxiaocheng` (Scene2Folder), `wedding_new_1`, `RogueFB`.
- Smoke chạy 5 ca đầu mỗi nhóm: **M01** `npc女主角变身长武器.obj`, **M09** `pet_2026狐狸小萝莉五级.obj`, **M19** `ride_2026七夕项羽马.obj`, **M25** `back_2026风云联动万剑归宗01.obj`, **M33** `dweapon_2026夏日海洋法杖.obj`.
- **Baseline ảnh `Tests\oracle\baseline` chụp từ client_GL → không còn áp dụng cho `cases.json` CY** (chỉ so được với `cases_gl.json`). CI không so ảnh; bộ dò khung trống (`ci_blank_detector.ps1`) vẫn chạy trên mọi ca viewer.

## 3. Parser cảnh: dữ liệu CY 3.71 khác GL ở đâu (đo bằng CYSSceneTest trên CanonicalCY)

Trước sửa: 467/467 cảnh SceneFolder nạp, **10 failures** (`.hdr` 28 byte), **10 khoá lạ / 1.079 lần**, unit check
`mantuoshanzhuang.EnScene` FAIL (CY không có cảnh này). Sửa theo luật "thuộc tính lạ thì log rồi bỏ qua":

| Khoá | Số lần | Xử lý |
|---|---|---|
| `.hdr` 28 byte (dali_new_320, luoyang_new, suzhou_new, guishi, taohuadaofb, *_MD) | 10 file | `decodeHdr` nhận 20 hoặc 28 byte; 5 float đầu như cũ, 2 float cuối (đều 0.5) giữ ở `CYSHdrFileParams::cyExtra[]`, đếm là *deferred* (chưa lần nghĩa) |
| `EnScene …/EnSky/Effects` (`<Effect effect_name=…/>`) | 18 | thêm `Effects` vào `kSkyChildren`, đọc vào `CYSEnSky::effects` (tên all.effect chơi cùng bầu trời vùng, vd tuyết); *deferred*, chưa phát |
| `StaticEntity.index` | 851 | thuộc tính editor (số thứ tự), giữ verbatim (`kStoredStaticEntity`) |
| `StaticEntity.Distance Cull`, `StaticEntity.HeightMapEnable` | 2 + 2 | giữ verbatim |
| `Model.UseHighLight` | 2 | giữ verbatim (`kStoredModel`) |
| `ParticleSystem.active`, `beginSceneBrightness`, `endSceneBrightness` | 18 + 29 + 155 | bảng mới `kStoredParticle` (ParticleSystem tách khỏi `kStoredPlaced`), giữ verbatim |
| `Projector.near clip distance`, `far clip distance` | 1 + 1 | thêm vào `kProjectorProps` |

Còn lại là *data problems* (không phải khoá lạ, không chặn cổng): `EnScene file not loaded: file not found = 6`
(cảnh tham chiếu EnScene không có trong dữ liệu CY).

## 4. Cách chạy CI cho một nhánh (như đã chạy cho ci-cy)

```powershell
$R = 'C:\TLBB\085\CY-Source'; $S = "$R\Build\wt-ci-cy\Tools\build"
powershell -NoProfile -ExecutionPolicy Bypass -File $S\ci.ps1    -Sha <sha> -Root $R
powershell -NoProfile -ExecutionPolicy Bypass -File $S\stage.ps1 -Root $R
powershell -NoProfile -ExecutionPolicy Bypass -File $S\smoke.ps1 -Root $R          # Windows PowerShell 5.1
powershell -NoProfile -ExecutionPolicy Bypass -File $R\Build\ci\wt\Tools\build\checks.ps1 -Root $R
```

Sau khi merge vào main, `Tools\build\ci_loop.ps1` của cây chính chạy đúng chuỗi này không cần `-Root`.
Khoá `Build\ci\{tree,bin64,checks}.lock`; `CMAKE_BUILD_PARALLEL_LEVEL=5`; không chạy viewer khi cây CI đang link.

## 5. Kết quả CI thật (14/09/2026)

| Commit | ci.ps1 | stage | smoke (CanonicalCY) | checks |
|---|---|---|---|---|
| `6b7cdef` (CI-CY + main 86c83a1) | 40/40 OK, build 905,6 s / 1.198 edge, 0 lỗi | rc 0, `data_dir` CanonicalCY, 25 PDB | 6/6 OK: OgreSmoke 200/200 + 200/200; M01/M09/M19/M25/M33 rc 0, PNG 49–76 KB, blank=false | 3/3: protocol 1.699/1.699; pathlib **418/418** 0 crash; scene **512/512** 0 khoá lạ, unit checks ok |
| `e803ef5` (merge main 4e03122: + shadow-cy, water-cy) | 40/40 OK, build 164,3 s / 87 edge, 0 lỗi (tổ hợp shadow+water biên dịch sạch) | rc 0 | 6/6 OK | 3/3 OK (scene 140,6 s) |

Bằng chứng: `Build\Logs\ci\{6b7cdef,e803ef5}\{summary.txt,smoke.json,checks.json,checks\scene\report.txt}`,
`Build\Logs\ci\latest.json`, `history.tsv`; driver và log từng bước: `Build\Logs\2026-09-14-ci-cy\{run-ci-chain.ps1,chain-*.log}`.
Scene report CY còn 2 *data problems* (không chặn cổng): `SnowWorld_GeCao_Xiuxi.Terrain` vắng trong Scene2.axp/DataCY
(CYHJ và client_GL có file này) → `WXSceneInfo::load` nạp cảnh không địa hình và ghi problem thay vì ném ngoại lệ như
engine gốc; 1 `.skysphere` được tham chiếu nhưng không có. *Deferred* 2: `EnSky/Effects` 27, `.hdr` 28 byte 20.

Số liệu cũ (GL) để đối chiếu: pathlib 488, scene 548, smoke 5 ca GL (M01/M09/M19/M25/M30 của `cases_gl.json`).
