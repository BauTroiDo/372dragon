# Bộ lọc hậu kỳ `ColorLUT` theo cảnh của CY 3.71.9609


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
