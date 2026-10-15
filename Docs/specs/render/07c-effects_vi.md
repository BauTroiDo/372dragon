# 07c — Hệ hiệu ứng: đặc tả B, kiểm kê "parse vs dùng", và khoảng trống

Ngày: 2026-09-13. Tác nhân: fx-effects (Claude). Trạng thái: đặc tả + kiểm kê + vá `use_scale`.
Ký hiệu: FACT = đọc trực tiếp từ binary/dữ liệu/mã nguồn; INF = suy luận.

Nối tiếp `04-effects-particles.md` (9 kiểu mới, pha E2). Tài liệu này trả lời câu hỏi của điều phối:
"khoá nào được **parse mà không dùng** lúc chạy?" và mô tả bộ máy hiệu ứng của B (client_GL `Render.dll`)
để dựng lại clean-room.

Nguồn bằng chứng (chỉ đọc, dưới `Build/re/fx-effects/`):
- Ghidra B `Render.dll` (SHA-256 `fda1205…`, = `client_GL\Bin64\Render.dll`) và C `Render.dll` (CY 3.71).
- `out/B_adders.txt`, `B_dicts.txt` — mọi `ParamDictionary` (tên khoá, kiểu, mô tả, lệnh, vtable).
- `out/B_range_core.txt` (`Effect`/`EffectManager`/`EffectElement`), `B_range_elems.txt` (Particle/Beam/Billboard/
  NewRibbonTrail/PointLight), `B_range_mgr.txt`, `B_range_lm.txt` (`LogicModel`), `B_funcs1.txt`.
- `out/B_ogre_ps.txt` — `Ogre::ParticleSystem::_update/_applyMotion/_applyLogicParentMotion/setLogicParentTrans`.
- `out/B_ogre_vt.txt` / `pe_vtslots.py` — vtable `SceneNode`/`Node`.
- Kiểm kê dữ liệu: `Tests/fx/effects/census/*` → `Build/Logs/2026-09-13-fx-effects/census/{types,keys,refs,gap}_*.tsv`.

---

## 1. Chuỗi hiệu ứng và bộ máy của B (FACT trừ khi ghi INF)

### 1.1 Vòng đời và cập nhật
- `EffectManager` là `ScriptLoader` với pattern `*.effect`, `*.skill` (B `FUN_18004c2c0`), khớp mã nguồn 0.85.
- Mỗi frame `EffectManager::update` (B `FUN_180053690`→`FUN_1800538e0`) chạy qua `mActiveEffectList`
  (danh sách, offset +0x70). Với mỗi effect còn sống gọi `updateEffect` (`FUN_18004b550`):
  - Có bộ đếm 0x19 frame trước khi cập nhật (offset +0xe8): nếu `use_scale`(+0xe7) bật thì cập nhật mỗi frame,
    ngược lại chờ tới 0x19 frame (INF: throttle cho effect không cần theo model). **Mã 0.85/CYS hiện cập nhật mỗi frame.**
  - `LifeTime`(+0x98): khi `mCurrentLifeTime` > `LifeTime` thì `removeAllElements` + đánh dấu chết. Khớp CYS.
- `time` truyền vào bị nhân `*(scene+0x2f0)` (B `FUN_1800538e0`), tức **hệ số tốc độ toàn cục của scene**. CYS
  không nhân — INF: khác biệt nhỏ khi scene chạy chậm/nhanh; ghi nhận, chưa vá.

### 1.2 Effect: các khoá cấp effect (B `FUN_18004aa30`, dict "Effect")
| Khoá | Kiểu | Offset | Ý nghĩa | CYS |
|---|---|---|---|---|
| `LifeTime` | REAL | +0x98 | tuổi thọ effect | ✅ dùng |
| `use_scale` | BOOL | +0xe4 (mặc định 1) | "scale depend on logicmode" — effect thừa hưởng scale của LogicModel | 🆕 **đã vá** (mục 3) |

Ctor B `FUN_180048020` ghi `word[+0xe4]=1` (byte 0xe4=1 use_scale, 0xe5=0) và `byte[+0xe7]=1`. Getter/setter
`use_scale` = `FUN_18004a8f0`/`FUN_18004a960` đọc/ghi byte +0xe4 (FACT `B_range_core`).

### 1.3 EffectElement: khoá nền chung (B `FUN_18016b4c0`, "…EffectElement")
`CreateLevel`(INT, "Level to decide whether the effect element need to be created"), `StartTime`(REAL),
`LifeTime`(REAL), `Position`(VECTOR3), `Orientation`(QUATERNION), `ParentSpaceLock`(BOOL, "lock in parent space").
CYS đăng ký đủ 6 khoá này (WXEffectElement::initDefaults).
- `CreateLevel`: B **không tạo** element khi mức chất lượng < CreateLevel. Giá trị dữ liệu là 0/100/120; mức
  effect mặc định là HIGH → hầu như luôn tạo. CYS lưu `mCreateLevel` nhưng **không có cổng** trong `createElement`
  → PARSED_IGNORED, nhưng vô hại ở mức HIGH (mục 4).
- `ParentSpaceLock`: chỉ `NewRibbonTrail` dùng (giữ chuỗi ribbon trong không gian cha). Với Particle, B dùng
  `setLogicParentTrans`/`_applyLogicParentMotion` (mục 1.6).

### 1.4 ParticleElement (B `FUN_1802152b0`, dict theo thứ tự khoá)
`ParticleSystem`, `ParEffectName`, `use_particle_effect`, `legacy_pos_for_sub_effect`,
`pass_rotation_to_sub_effect`, `ColEffectName`, `use_particle_collision`, `use_energy_wave`.
- `ParticleSystem` → tạo `Ogre::ParticleSystem` (CYS dùng).
- **Hệ hiệu ứng con (sub-effect)**: B `FUN_180218070`/`FUN_180218300` mỗi frame, cho mỗi hạt:
  - Nếu `use_particle_effect` và `ParEffectName != NullEffect`: sinh một effect con tại vị trí hạt
    (`FUN_180216800` `_updateColPsys` dùng terrain-type-info, xét `legacy_pos_for_sub_effect` để chọn toạ độ
    local hay world, `pass_rotation_to_sub_effect` để truyền xoay). Đây là "khói bốc từ mỗi tàn lửa", "va chạm đất".
  - Nếu `use_particle_collision`/`use_energy_wave`: `ColEffectName` khi hạt chạm đất/nước (`FUN_180216c10`,
    `FUN_180216e90`), có mặt nạ `Energy_Wave_Mask` (`FUN_1801aae40`).
  - **CYS lưu 7 khoá này nhưng KHÔNG sinh sub-effect** → PARSED_IGNORED (mục 4, khoảng trống lớn nhất còn lại).

### 1.5 Beam (B `FUN_18021aed0`, 27 khoá — nhiều hơn 0.85 rất nhiều)
Ngoài `Colour/ColourRangeStart/ColourRangeEnd/NoiseX..Z/NumElements/Width/Material/Frequency` (0.85 có),
B thêm: `CurveType`(INT, "Type of Beam"), `TexRepeat`(INT), `IsVisable`(BOOL), `IsSinPlay`(BOOL, "Is wave play"),
`WaveExtent-y`, `WaveExtent-z`, `WaveFrequency`("WaveLengh of wave"), `WaveVelocity`, `WaveShade-y`, `WaveShade-z`,
`SpLineEditor`(STRING — điểm điều khiển spline), `BindElement`(STRING, "Bind Element"),
`IsSubEleActive`(BOOL), `SubElementFrequency`(REAL). Offset setter (FACT `B_range_elems`):
`CurveType`+0x110, `NoiseXMin`+0xf8, `NoiseXMax`+0xfc, `NoiseYMin`+0x100, `NoiseYMax`+0x104, `NoiseZMax`+0x10c,
WaveExtent/Frequency/Velocity/Shade quanh +0x130–0x14c, spline tại +0x150 (`Ogre::SimpleSpline`).
- Hàm dựng sóng B `FUN_18021c8a0` (switch 8 `CurveType`): dùng `WaveFrequency/WaveVelocity/WaveExtent` và Sin/Cos
  để uốn từng đốt beam theo thời gian; `SpLineEditor` nạp spline (`FUN_18021c490`), nội suy `interpolate`.
- **CYS chỉ có beam tĩnh (13 khoá cũ). 14 khoá sóng/spline/sub-element là NOT_PARSED** (54 block dùng) → beam
  của 96/CY trông "đứng yên, sai" (mục 4). Đây là khoảng trống nhìn thấy được trong viewer.

### 1.6 Particle theo model (ParentSpaceLock / logic parent) — B OgreMain
- `Ogre::ParticleSystem::setLogicParentTrans(pos, quat)` ghi pos/quat cha vào +0x1dc..+0x1f4 (FACT export
  `?setLogicParentTrans@…`). `_applyLogicParentMotion` (B `FUN_180121ca0`) dịch **mọi hạt còn sống** theo
  delta chuyển động của cha (giữ hạt ở world-space nhưng "trôi mềm" theo model) — khác
  `setKeepParticlesInLocalSpace` (gắn cứng). OgreMain của CY-Source có `setKeepParticlesInLocalSpace` (FACT
  `OgreParticleSystem.h:597`) nhưng **không có** `setLogicParentTrans`/`_applyLogicParentMotion`.
- Dữ liệu: `ParentSpaceLock true` chỉ 8/6635 lần dùng trên Particle (FACT census). Giá trị thấp + ngữ nghĩa lệch
  → để lại PARSED_IGNORED, ghi rõ (mục 4). Cần thêm export OGRE nếu muốn dựng đúng.

### 1.7 Gắn effect vào skill / model (LogicModel, B `B_range_lm`)
- `AnimationEffectInfo` (B `FUN_180222960`): `AttachTime`+? , `AttachPoint`(bone/locator), `EffectTemplateName`,
  `OffsetPos`+, `OffsetRotation`+, `Attach`(byte +0x7c — effect đi theo attach point), `DefaultShow`(byte +0x7d).
  CYS có 6 khoá đầu; **thiếu `DefaultShow`** (NOT_PARSED, 4512 lần).
  - `DefaultShow`: B `FUN_1800b0ea0` tạo effect khi `(scene[+0x2c0]==0) || info[+0x7d]!=0`. Tức DefaultShow chỉ
    có tác dụng khi cờ **"scene tạm ẩn hiệu ứng"** (+0x2c0) bật (cutscene/giảm chi tiết). Ở màn chơi thường
    (+0x2c0=0) DefaultShow là no-op. LogicModel CYS chưa có cờ này → tương đương no-op. Ghi nhận, chưa vá.
- `Attach`(+0x7c): B `FUN_1800b97e0` mỗi frame cập nhật lại toạ độ effect đang gắn theo attach point. CYS dùng
  (`_updateAttachedAnimationEffect`).
- Locator world-transform (B `FUN_1800c6c80`/`FUN_1800c6590`): với type "tất cả", position = attach point
  world pos + rot*offsetPos, orientation = attachRot*offsetRot. Vị trí có nhân `_getDerivedScale()` cho offset —
  khớp CYS `getLocatorWorldTransform`.

### 1.8 Pool & dọn dẹp
- B có pool effect y hệt CYS (map theo template → list rảnh, `reborn`), `mMaxNumFreeEffectPerList` (CYS 10).
- `Effect_Error` fallback khi thiếu template (B `FUN_18004e300` gọi `Fairy_Effect_Error`; CYS tạo `Effect_Error`).
- B OgreMain có `ParticleSystemData` (template chia sẻ), `MergeParticleSystem`/`BackParticleSystem`,
  `setTotalLargeParticleSystemNum(1000)`, `setDefaultNonVisibleUpdateTimeout(5.0)`,
  `setDefaultIterationInterval(0.033)` (FACT `04-effects-particles.md` §1). CYS đặt `IterationInterval 0.033`
  (RenderSystem.cpp:559) nhưng **chưa có** batching/BackParticleSystem/ParticleSystemData → chi phí/độ mượt khác
  (thuộc agent OGRE/material, ghi tham chiếu).

---

## 2. So B với C (CY 3.71)
Toàn bộ dict hiệu ứng của C **giống hệt B theo tên khoá, kiểu, thứ tự và mô tả** (`B_adders.txt` vs `C_adders.txt`
khác duy nhất địa chỉ hàm). C có thêm `dissolveBox` ở material-system (đã ghi ở 04/01). Kết luận: đặc tả B ở trên
dùng chung cho C.

---

## 3. Đã hiện thực phiên này (clean-room theo B)

### 3.1 Hệ sub-effect / collision của Particle (khoảng trống lớn nhất: 38.813 lần dùng)
`WXParticleElement`: `_updateParticleEffects` (B `FUN_180216c10`+`FUN_180216e90`) và `_updateCollisionEffects`
(B `FUN_180216800` `_updateColPsys`), gọi trong `updateRenderInstance` (B `FUN_180218070`).
- **ParEffectName + use_particle_effect**: mỗi hạt sống sinh **một** effect con `ParEffectName` đi theo hạt. Đồng
  bộ theo địa chỉ hạt (như B): danh sách theo thứ tự hạt + `unordered_map` tra O(1) (B quét list tuyến tính); hạt
  chết → effect trả pool ngay (`removeEffect(...,false,true)` — giữ node để tái dùng). Vị trí: hạt world-space →
  `particle->position`; local-space → mesh-node derived pos, hoặc `mBasicNode->_getFullTransform()*pos`; `legacy_
  pos_for_sub_effect` → `pos + node.derivedPos`. `pass_rotation_to_sub_effect` (mesh) → derived orient của node hạt.
- **ColEffectName + use_particle_collision**: hạt cách mặt đất < 10 (địa hình hoặc mặt nước theo `TerrainTypeInfo`
  loại LIQUID) → effect va chạm hiện tại chỗ chạm rồi hạt `timeToLive=0` (B). Tra địa hình có **bao biên**
  (`TerrainTypeInfos::findTerrainTypeInfo` mới — bản cũ `getTerrainTypeInfo` index thẳng, crash ngoài mảng).
- **Cầu nối OGRE**: thêm `MeshParticleVisualData::getEntity()` (tag `// CYS-FXBRIDGE`, fx-particles sở hữu file).
- **Công tắc**: `ParticleElement::msSubEffectsEnabled` (mặc định BẬT); viewer `--no-sub-effects` /
  env `CYS_FX_SUB_EFFECTS=0` để A/B không cần build lại. `use_energy_wave` là mặt nạ méo màn hình ở render
  pipeline (B `FUN_1801aae40`) — **không** thuộc element, để PARSED_IGNORED.

### 3.2 use_scale (8525 effect) — qua TransformInfo.mScale
B `TransformInfo` là {pos, rot, **scale**}; `Effect::setTransformInfo` (B `FUN_18004b2f0`) đặt scale lên node gốc,
element là con local. CYS đặt element ở world-space nên viết trực tiếp: `pos = info.mPosition + rot*(info.mScale*
mRelPos)`, và `node->setScale(info.mScale)` (mesh/emitter/hạt local-space theo đó). `LogicModel::setEffectFollowScale`
(B `LogicModel+0x328`, mặc định TẮT): khi bật, `getLocatorWorldTransform`/`getBoneWorldTransform` (GTIT_ALL) trả
`_getDerivedScale()` vào `mScale`. B bật cờ này qua `CRFObj_FairyActor` vtable slot 37 trên các model của actor
(chính, KFSObj, vũ khí, BackWeaponObj); B **không** đọc `use_scale` của effect. Viewer thêm `--scale <f>` +
`--effect-follow-scale` (tag `// CYS: fx-effects --scale`) để kiểm ở scale 1.5 = cảnh tạo nhân vật. Mặc định
(scale 1.0, follow tắt) → **bất biến**, không hồi quy.

### 3.3 CreateLevel (mọi element) — cổng theo mức
`EffectElement::update` (B `FUN_18016bd00`): ẩn element khi `CreateLevel < EffectManager::getCreateLevel()`
(mặc định 100 = ctor B, không đổi). Mặc định element = 100 ⇒ 100≥100 hiện; giá trị dữ liệu 0 (35 hạt) ẩn như B.
Giữ nguyên luồng gốc create → life-check → update (không hồi quy).

### 3.4 DefaultShow (skill AnimEffect, 4512 dòng) — cổng ẩn-hiệu-ứng
`AnimationEffectInfo` khoá `DefaultShow` (B +0x7d); `System::setHideAnimationEffects` (B `System+0x2c0`, mặc định
TẮT). Khi bật ẩn hiệu ứng skill, chỉ effect có `DefaultShow` được tạo (B `FUN_1800b0ea0`/`FUN_1800b97e0`). Mặc
định TẮT ⇒ no-op như màn chơi thường.

### 3.5 Beam wave/curve/spline (14 khoá) — parse + lưu
`WXBeamElement` đăng ký đủ 14 khoá đúng tên/kiểu/thứ tự dict B (offset xác nhận từ setter thunk: CurveType +0x128,
IsSinPlay +0x130, WaveExtent-y/z +0x134/+0x138, WaveFrequency +0x13c, WaveVelocity +0x140, WaveShade-y/z
+0x148/+0x14c…). **Phát hiện then chốt**: mọi beam đã ship là **CurveType 0/1** (census: 0=49, 1=5) = đường
noise-tuyến-tính mà CYS **đã vẽ**; các curve sin (3/5/6/7) và spline (2/4) tiêu thụ các khoá wave/spline **không
beam nào chọn**, và WaveShade luôn 0. Nên **parse + lưu là toàn bộ khoảng trống hành vi** cho dữ liệu; hiện thực
máy sóng/spline "chết" là gold-plating → không làm.

### 3.6 Sửa crash (ưu tiên khẩn của điều phối)
- `Effect::removeParentSceneNode` (WXEffect.cpp) deref `getParent()` NULL trên effect tái dùng từ pool (node đã
  gỡ) → crash khi tạo/thu effect tần suất cao (sub-effect). Vá: bảo vệ NULL.
- `EffectElement::update` (bản ghi trước) tạo/cập nhật render instance **sau** `destroyMe()` cùng frame → sai vòng
  đời. Vá: khôi phục nhánh else gốc (không cập nhật khi vừa destroy).
- Đã dựng lại, render E070 (`wq_2025冰元素镰刀_展示`, 4 Particle có sub-effect) **rc=0 không crash**.

---

## 4. Kiểm kê "parse vs dùng" — cổng ≥10 template (FACT census `gap.tsv`)

| Nguồn | Trước | Sau |
|---|---|---|
| S1 (client_GL) | USED 110 / **NOT_PARSED 16** / PARSED_IGNORED 11 | USED **121** / **NOT_PARSED 0** / PARSED_IGNORED 16 |
| S2 (DataCY) | USED 100 / NOT_PARSED 16 / PARSED_IGNORED 11 | USED **111** / **NOT_PARSED 0** / PARSED_IGNORED 16 |

**NOT_PARSED = 0** cho mọi khoá dùng bởi ≥10 template (yêu cầu chính đạt). PARSED_IGNORED còn lại đều **ngoài phạm
vi fx-effects** hoặc **chết trong dữ liệu**:
- Particle `use_energy_wave` (8414): mặt nạ méo màn hình — render pipeline, không phải element.
- Particle `ParentSpaceLock` (1213): cần export OGRE `setLogicParentTrans` (fx-particles/OGRE); true 8/6635 lần.
- 14 khoá Beam (29 mỗi khoá): curve type tương ứng không beam nào chọn (mục 3.5).

**Việc còn lại (đề xuất):** billboard scale ở renderer để `use_scale` phóng cả sprite hạt thuần billboard;
export OGRE cho `ParentSpaceLock`; máy beam sóng/spline chỉ khi dữ liệu dùng CurveType ≥2.

## 4b. Gắn effect vào locator/bone — maths đúng B, "hiệu ứng trôi" là do bind-pose

Điều phối báo "hiệu ứng lửa trôi sang phải" trên `女主角高模明教.obj` (S002). **Nguyên nhân (FACT, đã kiểm):**
- all.obj gắn effect `wq_九大门派神器明教刀01` tại locator `武器特效点` (bone `Bone29`, **x=166.97**, translateFirst).
- Viewer render model **trần không animation** → skeleton ở bind-pose → Bone29 chưa được pose → offset 166 đơn vị
  (đỉnh vũ khí) chỉ sang world +X thay vì dọc lưỡi → lửa trôi sang phải, ngang hông.
- Render **có animation `站立`** → lửa nằm **đúng trên vũ khí** (đã chụp `crashcheck/S002_anim.png`). `weapon00`
  (Thiếu Lâm) gắn đúng ngay cả bind-pose.
- `getLocatorWorldTransform` khớp B `FUN_1800c6c80` (worldOrient*offsetRot; worldOrient*(_getDerivedScale()*
  offsetPos)+worldPos). **Không có lỗi maths**, không phải hồi quy của fx-effects (giống hệt khi sub-effect bật/tắt).
- Kết luận: cảnh tạo nhân vật trong game **luôn** chạy idle animation → đúng. Verify sect-preview phải render **có
  pose** (`Tests/fx/effects/sect_cases.tsv`, kind skill + `站立`). Vấn đề "sở hữu effect nên ở model vũ khí" (B:
  `CRFObj_Actor::SetRightWeaponEffect` → LogicModel vũ khí `addEffect`) thuộc agent weapon/model.

---

## 5. Kiểm thử
- **Unit** `Tests/fx/effects/effects_math_test.cpp` (`run_effects_math.cmd`): cổng thời gian skill (bao vòng loop),
  đặt element theo TransformInfo.mScale (so scene-graph), cổng CreateLevel, đồng bộ sub-effect theo địa chỉ hạt.
  **PASS toàn bộ.**
- **Parse** `Tests/fx/fx_parse_test.cpp` — 0 khoá lạ.
- **Census** `Tests/fx/effects/census/fx_census.py --wx-dicts wx_dicts.tsv --wx-usage wx_key_usage.tsv` → `gap.tsv`
  (cổng ở mục 4). `gen_wx_tables.py` sinh bảng từ đọc mã nguồn.
- **Oracle** (`Tools/fx/fx_sheet.py`, canonical, 100 effect): **100/100 ok, 0 crash** sau vá (E070 ok 469 ms).
- **Chi phí/frame mỗi item** (oracle, t1): update mean 0.04 ms (p95 0.06, max 0.47), render 0.19 ms, GPU 0.24 ms.
- **Sub-effect A/B cùng binary** (evidence 24, `--no-sub-effects`): +116 draw call, update +0.04 ms tổng, render
  +1.12 ms, GPU +0.57 ms (≈0,05 ms/item); ảnh 240 cặp / 124 trùng / SSIM min 0.834.
- **Sect-preview có pose** (`sect_cases.tsv`): 22/30 (mọi model có trong client_GL) — hiệu ứng vũ khí đúng trên vũ
  khí ở scale 1.0 và 1.5+follow. 8 model CY-only không có trong all.obj của client_GL; ở S2/stage mesh tên CJK
  không nạp được (thuộc agent data/viewer).
- **36 case** trước/sau: 36/36 rc=0; khác biệt gộp thay đổi của agent khác (hai bin build từ cây chung ở hai thời
  điểm) → A/B đúng nghĩa là cùng-binary on/off ở trên.
- **Crash** E070 rc=0 (`crashcheck/E070.png`).
- **use_scale, camera cố định** (`scaleproof/`): scale 1.0 | 1.5 không follow (mặc định B) | 1.5 + follow. Không
  follow: hiệu ứng vẫn đúng vị trí trên vũ khí (locator đã scale) nhưng giữ cỡ 1.0; có follow: hiệu ứng phóng theo
  model. Cờ follow ở game do B bật qua `CRFObj_FairyActor` slot 37 / gắn model kế thừa scale — engine CYS đã có
  `LogicModel::setEffectFollowScale`, việc nối vào cảnh tạo nhân vật thuộc agent game-layer.
