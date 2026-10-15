# 07e — Hiệu ứng và hạt theo CY 3.71.9609 trên CanonicalCY (fx-cy, 14/09/2026)

Tác nhân: fx-cy (Claude). Chỉ thị: "Mọi thứ như CY đi" — chuẩn duy nhất là CY 3.71.9609 (`Tools\DATA NEW\CY Game`).
Ký hiệu: FACT = đọc trực tiếp từ binary / dữ liệu / log chạy thật; INF = suy luận. Bằng chứng: `Build\Logs\2026-09-14-fx-cy\`
(gitignore) và `Build\re\fx-cy\` (Ghidra trên bản sao, chỉ đọc). Nối tiếp 07 (audit), 07b (hạt), 07c (effect), 07d (render).

## 0. Kết luận

1. **Mã CY = mã B cho toàn bộ hệ effect / skill / hạt** (FACT, mục 2): 36 hàm Render.dll của 9 kiểu "mới" so sánh B ↔ C
   theo decompile đã chuẩn hoá: kích thước byte bằng nhau từng cặp, 15 hàm trùng tuyệt đối, 21 hàm chỉ khác **offset
   trường struct** (LogicModel của C nhỏ hơn 0x18 byte) hoặc hằng tra tên tham số; Plugin_ParticleFX2 của C chỉ khác
   bảng import. Đặc tả B ở 07b/07c dùng nguyên cho C; không có hành vi CY nào phải cài thêm ngoài **ComplexBlur** (mục 3).
2. **Census runtime CanonicalCY** (FACT, mục 1): effect **0 khoá bị từ chối**, skill **0 khoá bị từ chối**, hạt 9 dòng bị từ
   chối (`anim_pos1..3`, B/C cũng từ chối). NOT_PARSED = 0 ở cả census tĩnh (≥10 template) lẫn runtime. 9 kiểu E2 đều có
   trong mã và được nạp (NewRibbonTrail 291, UIParticle 25, RevoluMove 3.376, SequenceFrame 1.507, Dissolve 416,
   RotationCurve 21, PolarMove 12, CameraShake 7, ComplexBlur 2 khối).
3. **Ảnh** (FACT, mục 4): sheet tất định 141 effect CY (kỹ năng 15 phái, hào quang, buff, vũ khí, tọa kỵ, thời trang, UI):
   140 render, 124 thấy được, **1 crash chập chờn** (không lặp lại khi chạy riêng và khi chạy 5 mục); 58 mục model
   (30 model tạo nhân vật CY có pose + 28 kỹ năng phái, 2 giới) **58/58 thấy được, 0 crash**.
4. **Trong game / hiệu năng / test**: replay offline `dali_new_320` (mục 5); bench hạt update 0,589 ms/khung so với
   main 0,776 (không chậm hơn), submit 0,647 so với 0,768; test hạt 358/358; scene test PASS; build sạch.
5. **Lỗi dữ liệu CY thật** (mục 1.3): 5 mesh, 19 material, 3 texture, 4 effect template vắng trong chính dữ liệu CY.

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

### 1.2 Khoá nhận-nhưng-bỏ-qua còn lại (có lý do)
`use_energy_wave` (Particle, 13.419 template — B/C đăng ký ở mặt nạ méo màn hình `Energy_Wave_Mask` của render pipeline,
C `FUN_1801b6990`, không phải ở element), `ParentSpaceLock` trên Particle (true 8/5.896; B/C dùng `setLogicParentTrans`),
7 khoá sub-effect của UIParticle (B/C không có hệ sub-effect cho hạt UI), 14 khoá wave/curve Beam (không beam nào chọn
CurveType 3–7), `Removedirectly` (3 skill). Bảng `Tools\fx\ignored_keys.tsv` đã viết lại theo mã hiện tại (13/09 nó còn ghi
ParEffectName/ColEffectName/CreateLevel là bỏ qua, nay đã USED — fx-effects).

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

## 2. Đối chiếu Render.dll CY ↔ B (FACT, Ghidra 12.1.3 trên bản sao `Build\re\fx-cy\`)

Binary: C `Render.dll` SHA-256 `e6e67de4…0cec7` (4.057.088 B, `Tools\DATA NEW\CY Game\Bin64`), `Plugin_ParticleFX2.dll`
`288d1192…`; B = `client_GL\Bin64\Render.dll` (dự án gfx sao chép). Cách làm: `CyFxDumpAll.java xref` với cùng bộ chuỗi
neo trên hai binary → `scripts\cmp_bc.py` chuẩn hoá (che FUN_/DAT_/địa chỉ) và so từng dòng (`out\cmp_k1.tsv`, `cmp_k2.tsv`;
diff từng cặp bằng `diff_bc.py`).

| Kiểu | Hàm B | Hàm C | Cỡ B/C | Dòng khác | Nhận xét |
|---|---|---|---|---:|---|
| NewRibbonTrail dict (`TrailLength`…) | `FUN_18021f2a0` | `FUN_18022a3e0` | 3127/3127 | 2 | chỉ địa chỉ |
| NewRibbonTrailElement `CmdElementType::doSet` | `FUN_180220b70` | `FUN_18022bca0` | 594/594 | 1 | |
| FairyRibbonTrail `addNode` | `FUN_18014bfb0` | `FUN_180157f10` | 244/244 | 1 | |
| Dissolve affector (dict + affect) | `FUN_180129440` | `FUN_180136280` | 1720/1720 | 1 | |
| Dissolve (LogicModel dissolve, `@Dissolve` clone) | `FUN_1800ba0d0` | `FUN_1800751f0` | 1056/1056 | 16 | offset trường +0x54c→+0x524, +0x120→+0x110 |
| RotationCurve affector | `FUN_18013c210` | `FUN_180148b10` | 1240/1240 | 1 | |
| SequenceFrame affector 1/2/3 | `FUN_18012af30` | `FUN_180137d70` | 4697/4697 | 8 | vtable + chuỗi tên |
| SequenceFrame element parse / effect | `FUN_18021ff90`, `FUN_18012d7e0` | `FUN_18022b0d0`, `FUN_18013a4d0` | 1203, 421 | 7, 2 | |
| PolarMove affector | `FUN_18012e4f0` | `FUN_18013b1e0` | 3299/3299 | 2 | |
| UIParticle (factory, element, manager) | `FUN_180174240`, `FUN_18004e300`, … | `FUN_18016ec70`, `FUN_180056d00`, … | 6 cặp | 0 | trùng tuyệt đối |
| CameraShake dict / parser | `FUN_1801c7c00` / `FUN_18004fa00` | `FUN_18018bc70` / `FUN_1800587c0` | 1899, 567 | 0, 0 | |
| CameraShake áp lên camera (LogicModel, `LinearDecrease`) | `FUN_1800b7e10` | `FUN_180072f30` | 2937/2937 | 74 | mọi khác biệt là offset −0x18 (LogicModel C) |
| ComplexBlur dict / parser | `FUN_1801c91b0` / `FUN_18004fea0` | `FUN_18018d1b0` / `FUN_180058c60` | 1535, 567 | 0, 2 | |
| ComplexBlur cập nhật từ skill (LogicModel) | `FUN_1800b8990` | `FUN_180073ab0` | 1112/1112 | 16 | offset −0x18; đặt `Unblured/Strength/Distance` mỗi khung |
| ComplexBlurPostFilter build / checkEnable | `FUN_1801a8ec0` / `FUN_1801a9500` | `FUN_1801b4a10` / `FUN_1801b5050` | 1464, 1277 | 1, 2 | quad `scene_buffer→rt_output`, material `PostFilters/ComplexBlur`, hằng `fDistance/fStrength/fUnblured` |
| ParticleElement dict (`use_energy_wave`) | `FUN_1802152b0` | `FUN_180220130` | 1984/1984 | 2 | |
| EffectElement dict (`ParentSpaceLock`) | `FUN_18016b4c0` | `FUN_1801727c0` | 1206/1206 | 0 | |
| BillboardSet dict (`BillboardScale`) | `FUN_180218e20` | `FUN_180223cf0` | 3481/3481 | 5 | |
| `dissolveBox` (material system) | — | `FUN_180162a80`, `FUN_180177530`, `FUN_180175e50` | C-only | — | chỉ C có; thuộc cy-look (CysMaterialSystem), không đụng |
| Render init (`FUN_18000e530` / `FUN_180024ea0`) | 8442 | 8868 | khác | 949 | C khởi tạo thêm; không phải logic effect |

Từ điển tham số effect/skill (`C_adders.txt` vs `B_adders.txt`, fx-effects 13/09): 18 dict, cùng tên/kiểu/thứ tự/mô tả.
Plugin_ParticleFX2 C vs B: decompile toàn bộ chỉ khác địa chỉ import (`Build\re\fx-particles\out\*_Plugin_ParticleFX2.dll.all.txt`).
⇒ Hành vi của 9 kiểu đã hiện thực theo B (07b/07c, `CYS\Effects\**`) đúng là hành vi của C; địa chỉ C ở bảng trên là bằng
chứng tra cứu. SequenceFrame đã dùng `unordered_map` cho trạng thái hạt (`WXSequenceFrameAffector.h:145`, CYS-PERF-FIX) — kiểm OK.

## 3. Cài mới trong phiên: ComplexBlur post-filter (`// CYS-FX`)

Trước: `WX::SkillCameraEffects` (13/09) đã parse và tính pha StartTime/MidTime/EndTime, nhưng `PostFilterManager` không có
filter `ComplexBlur` → ghi log một lần, không có hình. Nay: `CysComplexBlur : CysPostFxStage` (`CYS\PostFX\CysPostFxFilters.cpp`,
thứ tự `CYS_ORDER_COMPLEXBLUR = 40`, giữa HDR và GaussianBlur/FXAA như chuỗi B) — một quad với **material của chính CY**
`PostFilters/ComplexBlur` (all.material; shader `MaterialTemplates\ComplexBlur.hlsl`, 8 tap toả tâm, `max(0, len − fUnblured)`),
tham số `Distance/Unblured/Strength` → hằng `fDistance/fUnblured/fStrength` (đúng C `FUN_1801b4a10`), không có material thì
`isActive()=false` + log một lần (như `checkEnable` C). Đăng ký ở `CysPostFx::registerFactories`. Dữ liệu CY dùng ở
`boss过场动画_鸠摩智`, `CG_转场动画_段延庆` (cùng CameraShake). Chỉ chạy cho model người chơi cục bộ (`IsLocalVisible`) hoặc khi
`CYS_FX_CAMERA_EFFECTS_ALL=1` (viewer/sheet).

Không cài: `UIParticle` vẽ trong không gian UI (25 khối; CY UI tham chiếu qua thuộc tính CEGUI `<Property Name="Effect"
Value="UI_PVE_2024"/>` ở `ZhouchangPVE_Warning.layout.xml`) — cần hook render CEGUI, thuộc cy-gui (handoff); hiện element
vẽ ở RENDER_QUEUE_OVERLAY, sheet U01 "alive-nothing-drawn" (bounds 0), U02–U07 thấy được trong 3D.

## 4. Ảnh (sheet tất định, `CYS_FX_SEED=1234`, viewer `Build\re\fx-cy\bin-new`, 512², 5 mốc × 2 nền)

- **`sheets\canonicalcy-cy-fxcy`** — danh sách `Tests\fx\audit\lists\cy.tsv` (141 effect, sinh bởi `Tools\fx\fx_lists_cy.py`:
  5 effect AnimEffect mỗi phái × 15 phái, 15 hào quang `光环/aura`, 15 `buff_`, 10 `wq_`, 5 `dweapon`, 5 `hj_`, 6 tọa kỵ, 6 thời
  trang, 7 `UI_`): 140 render / 544 s; `fx_report --classify`: visible 124, saturated 5 (STM02/STM04/Swd04/Sxx04/W07),
  no-particles 6 (A01–A04 `aura_rune_projector0/13/4/9` = Projector, không có hạt là đúng; B10; T01), alive-nothing-drawn 4
  (B04, B05, B11, U01 UIParticle), bounds-blowup 1 (A05). **Crash 1**: `Sxx02 g01_xx_jq_玄冥神掌_2` exit −1 ở lượt 1 (sau ~25
  mục), harness tự chạy tiếp; chạy riêng (`crash-Sxx02`) và chạy 5 mục liền trước (`crash-Sxx02b`) đều rc=0 → chập chờn, chưa
  tái hiện; lượt 2 toàn danh sách `canonicalcy-cy-fxcy2` (xem handoff).
- **`sheets\canonicalcy-cy-models-fxcy`** — `cy-models.tsv` (58 mục kiểu model: 30 model tạo nhân vật CY có pose `站立`
  = `sect_cases.tsv` của fx-effects, nay đủ 30/30 vì CanonicalCY có 8 model CY-only; + 28 kỹ năng phái `m01_/g01_<phái>_…`
  trên đúng model): **58/58 visible, 0 crash, 98 s** (`overview-black.png` — ảnh đẹp nhất phiên: hiệu ứng vũ khí nằm đúng
  trên vũ khí, hào quang chân, cầu lửa Minh Giáo, băng Thiên Sơn, kiếm khí Đào Hoa Đảo).
- **`sect-cy2`** — `render_fx_sheet.py --data CanonicalCY --cases sect_cases.tsv` (mỗi mục một tiến trình, kiểm độ phủ):
  **30/30 rc 0, 30 PNG, 0 ảnh trống** (`manifest.json`; `sect-cy` là lượt 1 bị lỗi decode stdout của script, đã sửa).
- **Lặp lại** (run 1 `fxcy` vs run 2 `fxcy2`, cùng binary, cùng seed): 1.540 cặp PNG, 465 trùng byte, 1.075 khác ở 133 mục
  (`fx_sheet.py --compare` chạy quá lâu, so bằng md5 — `sheet-compare-md5`); đây là hạn chế đã biết của fx-audit D17
  (controller trong `std::set` thứ tự con trỏ + `rand()` chung), số hạt/trạng thái giống nhau; ngoài phạm vi fx-cy.
- **Cặp trước/sau ComplexBlur** (`postfx-test\shot_none.png` / `shot_complexblur.png`, `CysPostFxTest --cases none,complexblur`
  trên CanonicalCY, giá trị của skill CG 24 / 0,1 / 0,08): tâm nét, mờ toả tia ra rìa đúng shader CY. Kích hoạt qua skill
  trong viewer không được vì hai skill CY dùng animation `出场动画` của model CG riêng (`complexblur\on\`: skill không chạy).
  Viewer `--postfx b` + model AV ở `OgreMain.dll` lúc thoát sau khi đã ghi đủ ảnh — xảy ra **cả với viewer main** (`bin-base`,
  `complexblur\on-base.dmp`, offset khác) → lỗi có sẵn của đường thoát viewer với post chain, không do stage mới.

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
