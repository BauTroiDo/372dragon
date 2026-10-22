# 07e — Hiệu ứng và hạt theo CY 3.71.9609 trên CanonicalCY (fx-cy, 14/09/2026)


## 1. Census CanonicalCY (runtime thật, TlbbViewer `--fx-census`, bẫy 3.5e)

Dữ liệu: `Assets\CanonicalCY\Data\EffectFolder\{all.effect 25,0 MB; all.particle 48,4 MB; all.skill 3,7 MB}` (bản
`build_canonical_cy.py 1.1`, 14/09 17:05). Bộ đọc: viewer nhánh fx-cy (main e51f130 + sửa đổi mục 3).

| Đại lượng | Trước (main e51f130) | Sau (fx-cy) |
|---|---:|---:|
| Template hạt / effect / skill nạp | 59.813 / 19.039 / 5.829 | như trước |
| Dòng hạt / effect / skill | 1.748.236 / 862.470 / 138.224 | như trước |
| Hạt: dòng bị từ chối | **9** (`anim_pos1..3`, 3 template `buff_冰雪节打卡_心型血槽_*`; B/C cũng không nhận) | 9 |
| Hạt: giá trị không áp (review) | 8.015 = `stacks/slices/repeat_times` cấp system chuyển sang SequenceFrame (đúng B/C) + `quota 0` (B giữ 10) | 8.015 |
| Effect: khoá bị từ chối | **0** | 0 |
| Skill: khoá bị từ chối | **0** | 0 |
| Effect: nhận-nhưng-bỏ-qua | 14.731 (bảng `ignored_keys.tsv` cũ 13/09 còn coi ParEffectName… là bỏ qua) | **337** (`use_energy_wave` true 337 lần; bảng đã cập nhật, mục 1.2) |
| Lỗi script | 0 | 0 |

Nguồn: `census-particle-before\census-canonicalcy-summary.json`, `census-particle-after\…`. Census tĩnh effect/skill (S3 = CanonicalCY,
`Tests\fx\effects\census\fx_census.py --sources S3`): USED 111, PARSED_IGNORED 16, **NOT_PARSED 0** (`census-effect-after\gap.tsv`;
bản "before" báo `BillboardScale0..2` NOT_PARSED là lỗi bảng từ điển sinh bằng tay — khoá ghép theo stage trong
`WXBillboardSetElement`, đã bổ sung vào `gen_wx_tables.py`).

### 1.1 Kiểu / khoá dùng trong CY (FACT `types_S3.tsv`, `keys_S3.tsv`)
Element: Particle 80.053, NewRibbonTrail 291, Beam 76, UIParticle 25, Projector 21, PointLight 10, BillboardSet 1.
Skill: AnimEffect 11.800, Sound 2.154, Ribbon 1.660, SceneLight 19, CameraShake 7, ComplexBlur 2.
Hạt (`all.particle`): ColourFading 59.095, ScaleInterpolator 52.966, Rotator 32.442, MeshRotator 8.981, Movement 9.580,
Revolution 6.287, **RevoluMove 3.376**, LinearForce 2.812, **SequenceFrame 1.507**, MeshAnimationAffector 843, **Dissolve 416**,
**RotationCurve 21**, **PolarMove 12**, DeflectorPlane 57, Scaler 53, DirectionRandomiser 51, ColourInterpolator 1; emitter
Box 31.100, Ring 15.068, Point 6.916, PolarEmitter 5.149, HollowEllipsoid 875, Cylinder 496, Ellipsoid 203; renderer
billboard 40.586, mesh 12.560, texcoord_billboard 6.204, ribbon 462.

Xếp hạng tần suất × ảnh hưởng hình ảnh của 9 kiểu E2 trên CY: RevoluMove (3.376, chuyển động hạt) > SequenceFrame (1.507,
flip-book) > Dissolve (416, tan biến mesh) > NewRibbonTrail (291, vệt cánh/vũ khí) > UIParticle (25 khối / 7 effect UI) >
RotationCurve (21) > PolarMove (12) > CameraShake (7 skill boss/CG) > ComplexBlur (2 skill CG). Tất cả đã có trong mã
(`Src\Engine\WXCore\CYS\Effects\**`, `ParticleFX2`); phiên này kiểm lại theo binary C và bổ sung ComplexBlur.

### 1.3 Lỗi dữ liệu CY thật (FACT: vắng cả trong `DataCY31-08-26` lẫn `CanonicalCY`)
- Mesh renderer trỏ mesh không tồn tại (effect ném khi tạo, engine chịu lỗi): `ZHUAN DI1.mesh` (4 template: `g01_buff12_01`,
  `g01_wd_zdo_rufengsibi_03`, `g01_xiangruyimo_01`, …), `特效琴弦mesh.mesh`, `特效吐息卷mesh.mesh`, `特效吐息卷2mesh.mesh`,
  `特效单根藤蔓mesh.mesh`.
- Tham chiếu có tiền tố thư mục sai: `EffectSystem/特效_地面闪电_mesh.mesh` (file nằm ở Model6 gốc); `草药矿石/孔明灯1..3.mesh`
  và `草药矿石/jpg_孔明灯1.dds` (file có ở cả `Model\` gốc lẫn `Model\草药矿石\`; census runtime báo thiếu — cần kiểm lớp tài
  nguyên với tên có thư mục, thuộc agent data/viewer; INF: C đọc từ AXP theo khoá đường dẫn nên cũng chỉ thấy khi khoá khớp).
- 19 material hạt không có trong `all.material` (vd. `cw_2023smmcixiu_攻击2_变色_15`, `npc_怪神魂_04`, `水母`,
  `FairyEmptyParticle` — không có cả trong chuỗi Render.dll/OgreMain.dll của C).
- Texture: `png_2023xb石头02.dds`, `jpg_珍兽111128新年vip龙4.dds` vắng; material `m01_六合剑_气宗_受击_0012` có `texture` rỗng.
- Skill trỏ effect vắng: `女主角_饮酒男女_01/_02`, `HJ_boss_少林高手_技能3如来神掌发招C`; all.obj trỏ `Buff_场景机制特效_地面火焰`.
- 19 system `quota ≥ 2000` (tới 8.000: `暴风骤雨`, `npc_zhulushapan_baoyulaixi_01`) — chi phí, không phải lỗi.
- Khoá `BendAngle` của Cylinder (B) / `bend_angle` (C) không xuất hiện trong CanonicalCY (0 dòng).

## 3. Cài mới trong phiên: ComplexBlur post-filter (`// CYS-FX`)


Không cài: `UIParticle` vẽ trong không gian UI (25 khối; CY UI tham chiếu qua thuộc tính CEGUI `<Property Name="Effect"
Value="UI_PVE_2024"/>` ở `ZhouchangPVE_Warning.layout.xml`) — cần hook render CEGUI, thuộc cy-gui (handoff); hiện element
vẽ ở RENDER_QUEUE_OVERLAY, sheet U01 "alive-nothing-drawn" (bounds 0), U02–U07 thấy được trong 3D.

## 5. Trong game, hiệu năng, test

- Stage `Build\world-gui\stage-e51f130-fxcy` (`stage_game.py build --data CanonicalCY --bin bin-new`): 18 binary, 68 overlay.
  **Replay `dali_new_320` CHƯA CÓ ẢNH TRONG WORLD** — bị chặn bởi lớp GUI CY của CanonicalCY (cy-gui đổi lúc 17:05), không phải
  bởi hiệu ứng (FACT, 5 lượt, mỗi lượt exit 0, 0 dump, 0 socket):
  - run-1/2 (binary fx-cy): `CYS MainLoop: fatal exception` ngay khi tạo UI — `ChatFrame.layout.xml` CY dùng `TLBB_ButtonCorner` →
    `Falagard/DragCornerButton` không có trong main.
  - run-3 (+ overlay stage-cục-bộ ChatFrame `TLBB_ButtonCorner→TLBB_ButtonNULL`): **`replay_enabled`, `gcconnect_scene2`,
    `gcenterscene_scene2` PASS** (vào cảnh 2 `dali_new_320`), rồi fatal khi nạp layout world: `CheckBox` thiếu `MinHeight`,
    `ChatChannel` thiếu `AutoResizeEnabled/DelButtonSize`, "ChildImage resource could not be resolved" (thuộc tính widget CY).
  - run-4 (+ lớp GL `Assets\Canonical\…\InterfaceFolder` chèn trước): fatal ở `SoftKeyBoard` (`TLBB_DragTitle_GLFit13` không có trong
    scheme CY tra theo tên gốc) — trộn hai lớp GUI không được; đã gỡ.
  - run-5 (binary **cy-gui 7a6f8ed** trên stage riêng `stage-7a6f8ed-fxcy-cygui`): fatal ngay ở ChatFrame ("Property
    `MouseMoveHollow` already exists", "Window `Chat_SystemChk` already exists") — cy-gui đang dở.
  ⇒ Bằng chứng trong game của fx-cy dừng ở: engine nạp CanonicalCY, DBC 58 bảng CY OK, vào cảnh 2 (run-3), PostFX chạy
  (`CysPostFX: NewHDRBloom enabled`); ảnh hiệu ứng chân/hào quang/quái trong world phải chạy lại sau khi cy-gui ổn định
  (lệnh ở handoff; stage của fx-cy đã sẵn, có README các overlay thử nghiệm).
- Bench hạt `CYSParticleBench` (200 system Canonical, 300 khung × 3 lượt, `bench.tsv` nhãn `fxcy`): update **0,589 ms/khung**
  (2,95 µs/system), submit 0,647, scene 1,401; fx-particles ghi cho main (`after`): 0,776 / 0,768 / 1,865 → không chậm hơn.
  (Mã hạt hai bên giống hệt — nhánh này chỉ đổi PostFX; chênh là nhiễu máy.)
- `CYSParticleUnitTest` **358/358** (`particle-unit-test.txt`); `Tests\scene\run_scene_test.cmd` **PASS** (failures 0,
  unknown keys 0, `scene-test-report.txt`); build toàn bộ `build-0-baseline` rc 0 (2050 bước), `build-1-fxcy` rc 0.

## 6. Bẫy mới
- `cmd.exe` trên máy này không tìm exe theo thư mục hiện hành (`CYSParticleUnitTest.exe is not recognized` dù `pushd bin`;
  INF: `NoDefaultCurrentDirectoryInExePath`) → gọi bằng đường dẫn đầy đủ (`run_particle_tests.cmd` bị ảnh hưởng ở bước chạy).
- `CyFxDumpAll.java xref` ghi `<program>.xref.txt` cố định — hai lượt cùng program ghi đè nhau; truyền nhãn làm tham số thứ 4.
- Từ điển census tĩnh (`gen_wx_tables.py`) không thấy khoá ghép theo vòng lặp (`BillboardScale0..2`) → NOT_PARSED giả.
- Sheet nhiều tiến trình (`render_fx_sheet.py`) mất ~2–4 phút nạp CanonicalCY mỗi mục; dùng `fx_sheet.py` kiểu `model` (một tiến
  trình, `cy-models.tsv`) nhanh 30×.
- Game.exe của tác nhân khác đang chạy làm replay phải chờ (luật một bản; script không giết tiến trình lạ).
