# Bộ lọc hậu kỳ `ColorLUT` theo cảnh của CY 3.71.9609

Ngày 14/09/2026, agent colorlut, nhánh `colorlut`. Chuẩn duy nhất là CY 3.71 (`Tools\DATA NEW\CY Game`, chỉ đọc).
Ký hiệu: **FACT** = có bằng chứng (hàm/offset/chuỗi/file/ảnh), **INF** = suy luận.
Bằng chứng: `Build\Logs\2026-09-14-colorlut\` (`re\` = Ghidra trên bản sao CY Game.exe + Render.dll ở
`Build\re\colorlut\bin` — Game.exe sha256 `9278c7f3…e0cc5b`, Render.dll `e6e67de4…0cec7`; `viewer\` = ảnh TlbbViewer,
`metrics\` = số đo màu; `replay-run-*` = Game.exe replay offline).
Tài liệu liên quan: `cy-look_vi.md` mục 2 (LUT `luttex.png` của **shader nhận bóng** — khác bộ lọc này),
`shadow-cy_vi.md` mục 2 (mức `View_HumanLightmap`), `02-postfx.md` (khung hậu kỳ), `07d-fx-render_vi.md`.

## 0. Tóm tắt

- CY có **hai** LUT khác nhau: (a) `luttex.png` 16×16 trong shader nhận bóng (cy-look, đã làm) và (b) **bộ lọc hậu kỳ
  `ColorLUT`** toàn màn hình với LUT 512×512 (8×8 ô, 64 mức mỗi kênh) **chọn theo cảnh** — file này.
- Cảnh → LUT được **ghi cứng trong Game.exe** (`CScene::EnterScene`, chuỗi `LUT_*.png` tại VA `0x140c62320…`), không có
  cột nào trong `SceneDefineEx.txt` (25 cột, không cột LUT) và không có file cấu hình cảnh (`.hdr/.newhdrbloom/.hfog/
  .godrays`) mang tên LUT. Game.exe gửi tên LUT cho Render.dll qua vtable `CRenderSystem+0x330` =
  `Scene_SetSceneLUTParam(enable, name)`; lệnh console `scenesetlut <n>=<file>` gọi cùng slot.
- Render.dll chỉ **bật** bộ lọc ở mức `View_HumanLightmap = 2` (cùng lúc với bóng đổ), tắt ở mức 0/1;
  `destAmount = "1"` (không blend, không chuyển mượt).
- CY-Source: `CysPostFx` nhận tên cảnh ở `Scene_Load` (hook `// CYS-LUT:`), tra bảng CY, đặt `LUTImage`/`destAmount`
  và bật/tắt theo mức; công tắc `Gfx_ColorLUT = auto|0|1|<file>` và biến môi trường `CYS_COLORLUT` để A/B.

## 1. Shader và dữ liệu LUT (FACT)

- Shader: `MaterialTemplates.zip\ColorLUT.hlsl` (`colorLUT_fp`, giống byte trong bản CY và bản GL): s0 = ảnh cảnh,
  s1 = LUT; mỗi kênh vào ×255, làm tròn lên bội 4 → 8 đỉnh lập phương, mỗi đỉnh tra **2 ô** của lưới 8×8 (ô = B
  nguyên và B+1, 64 mức B) rồi nội suy tuyến tính theo B, cuối cùng nội suy tam tuyến 8 đỉnh; ra
  `lerp(gốc, tra cứu, dest_amount)`. 16 lần `tex2D` LUT cho mỗi điểm ảnh; `clamp(0.001, 0.999)` đầu vào.
- LUT: PNG **512×512** (RGB; vài file RGBA), 8×8 ô 64×64. Trong `Assets\CanonicalCY\Data`: `MaterialFolder\LUT_00…13.png`
  (bộ GL cũ), `Material2Folder\LUT_00gao.png`, `LUT_PBRCommon.png`, `Material3Folder\LUT_14.png`, `LUT_baitian.png`,
  `LUT_bianjing1.png`, `LUT_caoyuanw02s.png`, `LUT_congren.png`, `LUT_congrenfb.png`, `LUT_jinling1.png`,
  `LUT_shuipow02s.png`, `LUT_shupo_02s.png`, `LUT_yintian.png`, `LUT_zhulin.png`, `Material4Folder\LUT_CLF.png`,
  `LUT_JZG01.png`, `LUT_PBRCommonJZG.png`, `LUT_PBRCommonYL.png`, `Material5Folder\LUT_ZongMenDL.png`,
  `Material6Folder\LUT_erg02.png` (34 file; danh sách + hash `re\lut_files.txt`).
- Độ lệch so với LUT đồng nhất (trung bình toàn lưới, `re\lut_identity.txt`): `LUT_00gao` tối đi −7 luma đều ba kênh
  (tăng tương phản vùng tối); `LUT_bianjing1` +1,7 luma, hơi xanh (B +3); **`LUT_congren` và `LUT_congrenfb` là LUT
  đồng nhất** (|d| = 0,2, trùng byte nhau và trùng số đo `LUT_00.png`) — cảnh 绝情谷/三庭洞天 của CY thực chất
  **không** đổi màu; các LUT còn lại (`shupo_02s` +25, `erg02` +19, `yintian` −9…) không được Game.exe CY tham chiếu,
  chỉ dùng qua console/sự kiện khác (INF).

## 2. Cách CY chọn LUT theo cảnh (FACT, Game.exe CY x64)

- Chuỗi `LUT_*.png` (17 bản tại `0x140c62320…0x140c62460`) **không** được mã tham chiếu trực tiếp (Ghidra xref = 0,
  quét rel32 = 0); chúng là con trỏ trong **bảng ghi đè theo cảnh `DAT_140fb35b0`** — 43 bản ghi × 0x68 byte, số bản
  ghi ở `DAT_140fb3434` (`re\scene_override_table.tsv`, giải mã từ bản sao Game.exe). Đây chính là bảng mà
  `shadow-cy_vi.md` ghi "nguồn dữ liệu chưa rõ".
- `CScene::EnterScene` (`FUN_1406be820`, `Build\Logs6-09-14-shadow-cy\cy-re\decomp` dòng 464–535) làm theo
  thứ tự: `vtable 0x328("")` (đặt LUT rỗng), rồi duyệt bảng so **ID cảnh** (`SceneDefine` cột 0, `*(int*)param_1[3]`)
  với bản ghi `+0x00`; khi khớp: nếu `+0x08` (shadowDis) > 0 thì gọi 0x418/0x420/0x428/0x448 (tham số bóng), rồi
  **`vtable 0x328(+0x10)`** = tên LUT của bản ghi, rồi 0x5b0/0x5b8/0x5c0, 0x458, 0x380, 0x378 theo các trường còn
  lại; cờ `+0x04` = 1 (cảnh thi đấu) thì thêm 0x300(0)/0x308(0)/0x318(1) và chỉ gửi lại `View_HumanLightmap`. Sau vòng
  lặp, Game.exe gửi lại `View_HDRFilter`, `View_FullScreenLight`, `View_HumanLightmap` (sự kiện 0x13c).
- Bảng cảnh → LUT (17/43 bản ghi có tên; các bản ghi khác và mọi ID ngoài bảng = `""`):

  | ID cảnh (SceneDefineEx CY) | File cảnh | LUT |
  |---|---|---|
  | 749 千仞黄山 | `huangshanzhidian.Scene` | `LUT_00gao.png` |
  | 750 凌云大佛 | `dafo.Scene` | `LUT_00gao.png` |
  | 752 古铜雀台 | `tongquetai.Scene` | `LUT_00gao.png` |
  | 755, 775, 776, 779, 780, 785 汴京 (6 line) | `bianjing.Scene` | `LUT_bianjing1.png` |
  | 824, 827 绝情谷 | `congren.Scene` | `LUT_congren.png` (đồng nhất) |
  | 826, 829 绝情谷 | `congrentx.Scene` | `LUT_congren.png` (đồng nhất) |
  | 828 绝情谷 | `congrensg.Scene` | `LUT_congren.png` (đồng nhất) |
  | 825, 830, 831 三庭洞天 | `congrenfb.Scene` | `LUT_congrenfb.png` (đồng nhất) |
  | 754, 712–716, 834–837, 733, 727, 848, 879, 882, 929, 930, 934, 987–990, 996, 1007, 1008, 1011 | (bảng có bóng/camera) | `""` |

  ⇒ **Đại Lý, Lạc Dương, Tô Châu, Thảo Nguyên, Đào Hoa Đảo… không có LUT trong CY** (không có trong bảng, hoặc `""`).
  Chỉ 4 LUT được Game.exe dùng; trong đó hai LUT `congren*` là đồng nhất, nên CY thực sự đổi tông màu ở đúng
  **4 file cảnh**: 3 cảnh `LUT_00gao` (tối, tăng tương phản) và 汴京 `LUT_bianjing1` (hơi sáng, ngả xanh).
- Không phụ thuộc thời điểm/thời tiết: bảng chỉ có ID cảnh; không có mã đổi LUT theo giờ (không xref nào khác tới
  `LUTImage` ngoài `FUN_18002db70`/setter của bộ lọc). `SceneDefineEx.txt` CY (DBC 25 cột) không có cột LUT.
- Lệnh console `scenesetlut <n>=<file>` (`FUN_140446700`): `atoi(n)` + tên sau `=` → `vtable 0x330(n, file)` = bật/tắt
  thủ công với file bất kỳ.

## 3. Render.dll CY: bật/tắt và tham số (FACT)

- Vtable `+0x328` → `FUN_18002de40(this, const char* name)` (`re
ender_slots.txt`): lưu `name` vào `std::string
  this+0x108`, rồi gọi **`vtable 0x330(this, name[0] != 0, name)`** ⇒ cảnh có LUT: bật ngay; cảnh `""`: tắt ngay.
- Vtable `+0x330` → `FUN_18002db70(this, int enable, const char* lutName)` (`Build\Logs6-09-14-shadow-cy\cy-re  decomp`, `10_CRenderSystem_vtable.txt` dòng 103):
  - bỏ qua nếu `this+0xfc == 0` (bộ lọc ColorLUT không tạo được — `FUN_180024ea0` đặt cờ này lúc khởi tạo chuỗi);
  - lưu `lutName` vào `this+0x108`; nếu khác rỗng: `PostFilterManager::setParameter("ColorLUT", "LUTImage", lutName)`;
  - luôn `setParameter("ColorLUT", "destAmount", "1")` (`DAT_1802c1d28` = chuỗi `"1"`) ⇒ **không blend, không fade**;
  - `setEnabled("ColorLUT", enable == 1)`.
- Setter của bộ lọc (`FUN_1801a9530`, `Fairy::ColorLUTPostFilter::setParameter`): `LUTImage` → lưu tên (+0x58),
  `_forceLoad32BitTexture` (`FUN_1801a8990`: nạp PNG thành texture 32-bit, đặt cờ +0x78 để gắn lại unit 1);
  `destAmount` → `parseReal` vào +0x50 (hằng `dest_amount` của shader).
- Mức chất lượng `View_HumanLightmap` (Render.dll `FUN_18002ec20` → vtable 0x338 `FUN_18002e100(level)`,
  `decomp` dòng 160–200): **mức 2** gọi `FUN_18002db70(this, 1, this+0x108)` **chỉ khi tên đã lưu khác rỗng**;
  mọi mức khác gọi `FUN_18002db70(this, 0, this+0x108)` (tắt). Game.exe gửi lại khoá này **mỗi lần vào cảnh**
  (`FUN_1406be820` dòng 717–732) ngay sau vòng lặp bảng ⇒ luật hiệu dụng của CY:
  **ColorLUT bật ⇔ cảnh có tên LUT trong bảng ∧ `View_HumanLightmap = 2`.**
- Chuỗi debug `[Scene_SetSceneLUTParam("LUT_00gao.png")] param:` (`0x1802c1f98`) do lệnh `debugpostfilter` in ra.
- Thứ tự tạo bộ lọc trong CY (`FUN_180024ea0`, `re
ender_lut_xref.txt` dòng ~1290): … NewHDRBloom → **ColorLUT**
  (cờ sẵn sàng `+0xfc`) → HeightFog → GodRays — **giống B** (`02-postfx.md` mục 1). CY-Source `CYS_ORDER_COLORLUT = 100`
  giữa NewHDRBloom (90) và HeightFog (110): cùng thứ tự.
- Cảnh đăng nhập/chọn nhân vật không qua `CScene::EnterScene` nên giữ tên đang lưu (rỗng lúc khởi động) ⇒ tắt.

## 4. CY-Source làm gì (nhánh `colorlut`, hook `// CYS-LUT:`)

- `CysPostFx::onSceneLoaded(manager, viewport, sceneId, sceneFile)` (mới, `CYS\PostFX\CysPostFx.cpp`): giữ luật cũ
  (NewHDRBloom tắt ở cảnh id < 0), lấy tên gốc cảnh, tra `sceneColorLut()` (bảng CY mục 2), rồi `applyColorLut()`.
  Gọi từ `CRenderSystem::Scene_Load` (`RenderSystem.cpp`, thay lời gọi cũ) và `TlbbViewer::loadScene` (khi có `--postfx`).
- `applyColorLut()`: quyết định bật/tắt từ **chế độ** (`Gfx_ColorLUT`: `auto` = luật CY — mức ≥ 2 **và** cảnh có LUT;
  `1` = bật với LUT cảnh hoặc `LUT_00.png`; `0` = tắt; `<file.png>` = ép file), **mức** (`View_HumanLightmap`, mặc định
  2 như `System.cfg` CY; khoá này nay đi qua `CysPostFx::applyVariable` cả lúc khởi động lẫn `VARIABLE_CHANGED`) và
  **LUT cảnh**. Đặt `LUTImage` + `destAmount = 1` như CY, rồi `request("ColorLUT", on)`. LUT không có trong tài nguyên
  → log `LUT … not found … filter skipped`, bộ lọc tắt. Mỗi lần áp ghi một dòng
  `CysPostFX: ColorLUT on|off (why): mode …, View_HumanLightmap …, scene …, lut …` vào log Ogre/WXRender.
- A/B: biến môi trường **`CYS_COLORLUT`** = `0` (tắt) | `1` | `auto` | `<file.png>` đè `Gfx_ColorLUT` (đọc một lần).
- Bảng `sceneColorLut(sceneId, sceneFile)`: khoá **ID cảnh** như CY khi `sceneId > 0` (Game.exe: `Scene_Load(nID, file)`
  nhận `SceneDefine` cột 0), khoá **tên file** cho công cụ không có ID (TlbbViewer); hai khoá cho cùng kết quả vì mọi ID
  chung một file cảnh trong bảng CY đều chung LUT. Chế độ `auto` = đúng luật hiệu dụng CY (mục 3): bật ⇔ có LUT ∧ mức 2;
  cảnh ngoài bảng tắt (CY gọi 0x328("") trước vòng lặp). Thứ tự chuỗi, shader, LUT, `destAmount` như CY.
- TlbbViewer: `--postfx b --shadow high` ⇒ mức 2 cũng được chuyển cho ColorLUT (`applyVariable(View_HumanLightmap)`),
  dòng `TlbbViewer: ColorLUT <lut>|on/off` trong stdout.

## 5. Số đo và ảnh (Build\Logs6-09-14-colorlutiewer, metrics)

TlbbViewer trên `Assets\CanonicalCY\Data`, 1920×1080, `--lights scene --shadow high --postfx b` (chuỗi client_GL: FXAA +
NewHDRBloom + HeightFog), cùng góc; ba biến thể: `nolut` (`CYS_COLORLUT=0`), `lut` (auto = bảng CY), `gao` (ép
`CYS_COLORLUT=LUT_00gao.png`, **không phải CY**, chỉ để thấy LUT tác động lên cảnh không có LUT). Số đo toàn khung
(`metricsll_scenes.tsv`, `metrics\lut_deltas.tsv`; luma 0–255, saturation = (max−min)/max trung bình):

| Cảnh | CY có LUT? | tắt → bật (auto) | tắt → ép LUT_00gao |
|---|---|---|---|
| dali_new_320 (trưa / 18,5 h) | không | **giống hệt** (ΔL 0, ΔS 0) | ΔL −3,8, ΔS +0,024 |
| caoyuan (trưa / 18,5 h) | không | giống hệt | ΔL −3,5, ΔS +0,062 |
| bianjing (`LUT_bianjing1`) | có | ΔL **+2,5**, ΔS +0,0006, spread 0,604→0,622 | – |
| huangshanzhidian (`LUT_00gao`) | có | ΔL **−9,6**, ΔS +0,033, spread 0,028→0,045 | – |
| dafo (`LUT_00gao`) | có | ΔL −5,2, ΔS +0,043 | – |
| tongquetai (`LUT_00gao`) | có | ΔL −8,8, ΔS +0,059 | – |
| congren (`LUT_congren`, đồng nhất) | có (đồng nhất) | bật nhưng không đổi màu (INF từ số đo LUT) | – |

- Kết luận: `LUT_00gao` = tối đi 5–10 luma, bão hoà +0,03–0,06, tương phản tăng (spread ↑) — đúng "tone điện ảnh" của
  3 cảnh CY; `LUT_bianjing1` sáng nhẹ +2,5. Bốn cảnh DoD (Đại Lý, Lạc Dương, Tô Châu, Thảo Nguyên) **không đổi** ở
  chế độ CY vì CY không gán LUT cho chúng — đây là kết quả đúng theo chuẩn CY, không phải lỗi.
- Ảnh ghép tắt/bật: `metrics\huangshan_noon_nolut_vs_lut.png` (đẹp nhất, `metricsest_huangshan_noon.png`),
  `dafo_…`, `tongquetai_…`, `bianjing_…`, `dali_noon_nolut_vs_gao.png`, `caoyuan_noon_nolut_vs_gao.png`.
- Ảnh CY thật cùng góc: **không có** (CY Game.exe không chạy được trên máy này với dữ liệu CanonicalCY) ⇒ chưa đo
  lệch tuyệt đối; chỉ có A/B nội bộ + số đo LUT so với đồng nhất (mục 1).
- Lạc Dương / Tô Châu: TlbbViewer của **main 544a2df** (và mọi binary từ 465a373 trở đi, kể cả nhánh này) **crash**
  (`0xE06D7363`, ngoại lệ C++ không phải OGRE, ngay sau `luoyang_new.Terrain: nothing skipped`); binary cy-look
  ed9f7f1, fx-cy 0fa8017, cy-gui acb600b, water-cy 6fe0b8b, shadow-cy 28e2a55 (đều **chưa** có cy-look+water+ci-cy)
  chạy được cùng dữ liệu (`diag\luoyang_*.txt`). Hai cảnh này có `Projector` (3/10), các cảnh chạy được không có
  ⇒ INF: hồi quy parser/đối tượng cảnh của main, **không thuộc ColorLUT**; vì CY không gán LUT cho chúng nên kết quả
  ColorLUT của chúng = tắt.
- `--time-of-day 18.5` cho ảnh **giống hệt** 12 h trong viewer (ΔL 0) — thời điểm không đổi chiếu sáng `--lights
  scene` của viewer (INF: ngoài phạm vi; CY chọn LUT không theo giờ nên không ảnh hưởng kết luận).
- Chi phí GPU (`metricsench_colorlut_1080p.txt`, CysPostFxTest `--bench 120`, RTX 2060 1920×1080, D3D9 timestamps,
  máy đang có Game.exe của agent khác): pass ColorLUT **0,33 ms** (FXAA 0,14 ms cùng điều kiện; fx-render đo trước
  0,27 ms). Sát ngưỡng 0,3 ms — 16 `tex2D` của shader B/CY; muốn giảm thì đổi sang tra 3D một lần (không phải CY).

## 6. Chưa làm / chưa xác minh

- **Replay trong game (DoD 4) không có ảnh world**: 5 lượt (`replay-run-1..5`). Lượt 1 (binary trước cy-gui, GUI CY)
  fatal ở `ChatFrame` (`TLBB_ButtonCorner` — lỗi cy-gui đã biết). Lượt 3/4 (sau gộp cy-gui) và **lượt 5 với binary CI
  của main 544a2df** (`stage-ext-colorlut-main544a2df`) đều dừng cùng chỗ: `character selection opened` → nạp cảnh
  đăng nhập `tl3chuangjian` → `WXRender.log` kết thúc ở `Building liquid at (745, −813, −2759)`, tiến trình thoát mã 0
  sau ~45–60 s không log fatal (`quit_flag` không có). Cùng cảnh nạp tốt trong TlbbViewer của nhánh này
  (`diag\chuangjian_mine.txt` rc 0). ⇒ hồi quy của **main** (không do ColorLUT; binary main không có mã này cũng
  dừng). Log ColorLUT trong game đã có ở khởi động (`ColorLUT off (View_HumanLightmap): mode auto …`), nhánh hook
  `Scene_Load` chưa được chạy tới vì cảnh chưa nạp xong.
- Ảnh CY thật để đo lệch tuyệt đối; lệnh console `scenesetlut` (tương đương `applyVariable("Gfx_ColorLUT", file)`).
- Các trường còn lại của bảng `DAT_140fb35b0` (bóng theo cảnh: 0x418/0x420/0x428/0x448/0x458/0x5b0/0x5c0, camera
  0x380/0x378, cờ thi đấu 0x300/0x308/0x318) — đã giải mã giá trị (`re\scene_override_table.tsv`,
  `reender_slots.txt`), chưa áp dụng (việc của shadow-cy/camera).
