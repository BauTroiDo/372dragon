# 07 — Kiểm toán hiệu ứng và hạt (fx-audit)

- **Trạng thái:** v2, 13/09/2026 18:50. v1 (18:00) đã được thay; mỗi mục ghi **FACT** (có bằng chứng file:dòng, số đo, ảnh) hay **GT** (giả thuyết cần kiểm).
- **Chủ:** fx-audit. **Người dùng:** fx-particles (**P**: `Src\Engine\ParticleFX2`, lõi hạt OGRE, renderer), fx-effects (**E**: `WXCore\EffectSystem`, `CYS\Effects`, all.effect/all.skill), fx-render (**R**: post-FX, đường vật liệu/shader của hạt), perf; **D** = dữ liệu game/Canonical hoặc lõi tài nguyên (ngoài ba nhánh FX, báo orchestrator).
- **Bối cảnh:** người dùng báo 13/09 “hiệu ứng và hạt sai, chưa đẹp; render rất chậm”. Tài liệu lập cơ sở khách quan:
  - census bằng runtime thật trên ba bộ dữ liệu;
  - bộ chụp tất định có số đo chi phí;
  - danh sách lỗi xếp hạng, mỗi lỗi có tiêu chí nghiệm thu đo được.

## 0. Tóm tắt

1. **FACT — dữ liệu stage (game đang chạy) parse gần như sạch.** Runtime chỉ từ chối 6 dòng hạt (`ColourFading opacity3`) và 7 khoá effect (`use_scale`) trên 375.389 dòng hạt, 56.863 dòng effect và 45.030 dòng skill. Không file script nào bị dừng. Lỗi hình của game hiện tại **không** do parser bỏ dữ liệu stage.
2. **FACT — tài nguyên stage không mở được vì tên file CJK.**
   - 15.757/23.664 file của stage có tên Unicode CJK, kế thừa Reference.
   - Engine liệt kê/mở file bằng API ANSI dưới ACP 1252 (`OgreFileSystem.cpp:318`, `:374` `_findfirst`; `:505` `FindFirstFile`), nên không thấy chúng.
   - Vật liệu hạt của stage: 323 tham chiếu texture và 196 tham chiếu mesh (renderer `mesh`) trỏ vào file có trên đĩa nhưng không mở được.
   - Hậu quả nhìn thấy:
     - hạt thành **ô vuông trơn** ngay ở cảnh tạo nhân vật (`taohua_big`, `yezihuyang01`; bản Canonical hiện đúng lá cam);
     - effect có hạt mesh **ném ngoại lệ và mất cả effect** (`梅花.mesh`, `冰晶.mesh`).
3. **FACT — dữ liệu hiện đại (Canonical, đích tương lai của game) bị runtime bỏ rất nhiều.**

   | Nhóm bị bỏ (Canonical) | Số dòng / mục |
   |---|---:|
   | Dòng hạt bị từ chối | 18.831 |
   | ↳ `ColourFading opacity0..5` | 17.572 |
   | ↳ khoá “increment” của ScaleInterpolator | ≈ 1.259 |
   | Khoá effect bị từ chối | 9.281 |
   | ↳ `use_scale` (số effect) | 8.525 |
   | ↳ 12 khoá của Beam (29 effect) | 648 |
   | `AnimEffect DefaultShow` | 4.512 |
   | Khoá **được nhận nhưng không dùng** | 2.082 |
   | ↳ hiệu ứng con của hạt `ParEffectName` (805 element / 457 effect; S2: 7.049) | 805 |

4. **FACT — kiểm hình 100 effect đối chứng trên Canonical.**
   - 46 hiện đúng dáng, 6 bão hoà trắng, **48 không thấy gì**:
     - 20 “hạt sống nhưng không vẽ ra gì”: RotationCurve 6/12, RevoluMove 4, UIParticle 3, SequenceFrame 2…;
     - 15 “bounds nổ”: hạt bay 5–104 km;
     - 13 không có hạt nào: 6 là NewRibbonTrail, bình thường khi vật chủ đứng yên.
   - Trên stage chỉ 7/100 effect đối chứng tồn tại: dữ liệu game đang dùng là thế hệ 0.85.
5. **FACT + GT — bão hoà trắng.**
   - 18/76 mục của màn tạo nhân vật bị cháy trắng (vũ khí môn phái Minh Giáo, Thiên Sơn, Quỷ Cốc…). Canonical giống hệt, nên lỗi nằm ở đường render.
   - Vật liệu dùng `Particle_ColorX4_PS` (`BLEND_OP 2` = MODULATE_X4), kẹp [0,1] rồi cộng `one one` trên đích LDR. B cộng trên HDR rồi tonemap.
6. **FACT — viewer từng giấu 1.303 dòng `orientation_type` của renderer mesh.** Đã bỏ: mặc định chuyển nguyên cho runtime; `--legacy-prefilter` bật lại hành vi cũ.
7. **FACT — chụp chưa lặp lại được từng pixel.**
   - Số hạt khớp 100 % giữa hai lượt, còn pixel thì lệch.
   - Nguyên nhân tìm được:
     - OGRE cập nhật mỗi hệ hạt bằng một controller riêng, lưu trong `std::set<Controller<Real>*>` xếp theo **địa chỉ con trỏ** (`OgreControllerManager.h:51`, `OgreParticleSystem.cpp:851`);
     - mọi hệ lấy số ngẫu nhiên từ một dòng `rand()` chung;
     - ASLR đổi thứ tự đó mỗi lượt, nên effect nhiều hệ hạt lệch, effect một hệ trùng byte.
   - Chi tiết mục 7.
8. **FACT — chi phí.**
   - Trạng thái ổn định rất nhẹ: update ≤ 0,05 ms, render ≤ 3,5 ms mỗi mục ở 512².
   - Ngoại lệ: RevoluMove `E022` update 3,9 ms cho 14 hạt; renderer `mesh` vẽ **một draw call mỗi hạt** (`K31` 133 draw); vật liệu hạt mesh bị clone thêm +2…+8 mỗi 3 s (không phải mỗi khung); lần dùng đầu tốn tới 27,7 ms (biên dịch/nạp).

9. **FACT — S2 (CY) được kiểm ngang Canonical** (census + sheet `--wide-names` trên `run-b8`, mục 4).
   - Ánh sáng bục chọn nhân vật và lá/hoa ở cảnh tạo nhân vật hiện đúng màu khi file đọc được.
   - Bản engine có việc đang dở của các nhánh (`run-b7/b8`) đã bỏ cháy trắng (D4) và mất màu (D20). Nhưng vòng sét Thiếu Lâm và phần lớn lửa Minh Giáo cũng biến mất: độ phủ giảm 50–90 %, cần nhánh sửa xác nhận.
   - Chưa có ảnh B để đo SSIM so với B.
   - Trên 100 effect đối chứng của Canonical, chỉ đổi engine (`run-b3` → `run-b8`):

     | Lớp | `run-b3` | `run-b8` |
     |---|---:|---:|
     | visible | 46 | 78 |
     | hạt sống, không vẽ gì | 20 | 6 |
     | bounds nổ | 15 | 1 |

     Hồi quy mới: E097, E016, E090, E044, E048 (mục 4).

## 1. Runtime và dữ liệu đã đo

| Mục | Giá trị |
|---|---|
| Runtime | TlbbViewer + OgreMain (ParticleFX dựng trong OgreMain) + `Plugin_ParticleFX2.dll` + WXCore tĩnh (EffectManager, affector/element CYS) + CysMaterialSystem |
| Bản đông cứng | `Build\cmake\fxaudit-x64\run-b3\` (SHA256 trong `SHA256.txt`): HEAD `2e9d456`/`3c50ba7` + thay đổi viewer của fx-audit. **Chưa** gồm việc đang dở của các nhánh. `run-b5` không hợp lệ (xem `INVALID.txt`). `run-b3-noaslr` = bản sao chỉ xoá cờ ASLR của exe. `run-b7` (18:30) = HEAD + việc đang dở của các nhánh (`build7-state.txt`) + `--wide-names`: chỉ dùng cho sheet S2 và xem trước stage sau D1, **không** dùng làm mốc “trước sửa”. |
| Từ điển runtime | `census-raw\baseline-run-b3-dict.tsv`: 7 emitter, 20 affector, 4 renderer, 8 element, Effect, Skill + 6 khối con. Mọi census chấm khoá theo từ điển này. |

| Bộ | Đường dẫn | all.particle | all.effect | all.skill | Tên file không biểu diễn được cp1252 |
|---|---|---|---|---|---|
| stage | `Build\gpt-p1-1-20260913\stage-91148e1\Data` (bố cục 0.85) | 4.683 template | 3.225 | 1.841 | 15.757 / 23.664 |
| Canonical | `Assets\Canonical\Data` (bố cục client_GL) | 43.297 | 13.014 | 4.290 | 4 / 80.690 |
| S2 | `Tools\DATA NEW\DataCY31-08-26` (bố cục CY) | 59.786 | 19.029 | 5.828 | 69.793 / 119.099 |

S2: all.material dừng ở vật liệu trùng tên `W_hair_2026孔慈筷子头` (`ResourceManager::add` ném “already exists”). Phần sau của file bị bỏ, runtime chỉ còn 341 vật liệu. Số liệu vật liệu S2 chỉ dùng để tham khảo.

## 2. Công cụ và lệnh chạy lại

Chạy từ `C:\TLBB\085\CY-Source`. Python `C:\Program Files\Python313\python.exe` (PIL, numpy), đặt `PYTHONUTF8=1`.

1. **Dựng:**
   - `cmd /c Tools\fx\build_fxaudit.cmd TlbbViewer` → `Build\cmake\fxaudit-x64\bin`.
   - Chép sang `run-*` trước khi chạy dài.
   - Nếu nhánh khác đang sửa dở OgreMain/ParticleFX2 thì bản dựng có thể hỏng hoặc lệch; kiểm log trước khi dùng.
2. **Census runtime:**
   `py -3 Tools\fx\fx_census.py --set stage|canonical|s2|all [--run --viewer <exe>] [--dict <dict.tsv>]`
   - Viewer: `TlbbViewer --data <dir> --fx-census <dir> --shader-cache <dir>`.
   - Kết quả: `Registry\fx\census-<set>.tsv` (một dòng/nhóm lỗi) và `census-<set>-summary.json`.
   - Tóm tắt nhanh: `py -3 Tools\fx\fx_report.py`.
   - Khoá “nhận nhưng không dùng” lấy từ `Tools\fx\ignored_keys.tsv` (có bằng chứng mã và giá trị vô hại được bỏ qua).
   - Tồn tại texture/mesh:
     - dùng câu trả lời của runtime khi dump có;
     - nếu không, dùng script vật liệu + tên file mà phép liệt kê ANSI thấy được;
     - tên có trên đĩa dưới dạng CJK được ghi là `unreachable`, không phải `missing`.
3. **Danh sách chụp:** `py -3 Tools\fx\fx_lists.py [--evidence-only]` → `Tests\fx\audit\lists\{oracle,frontend,skills,evidence}.tsv`.
   - frontend: 20 ParticleSystem của `tl3chuangjian/xuanren/chuangjian.Scene` (tên đọc theo khai báo `encoding` của XML), 30 model môn phái 4950–4979 kèm vũ khí, 26 effect gắn trên chúng.
   - skills: 40 effect được AnimEffect gọi nhiều nhất.
   - evidence: effect có hiệu ứng con + chính hiệu ứng con đó, và effect có `use_scale`.
4. **Chụp + sheet:** `py -3 Tools\fx\fx_sheet.py --set <set> --list <list> [--repeat] [--turntable 30] [--cache <dir>] [--viewer <exe>]`
   - Viewer: `TlbbViewer --fx-sheet <list> --out <dir> --size 512x512 --seed 1234 --times 0.15,0.4,0.8,1.5,3 --bgs black,grey --orbit 30,30`.
   - dt cố định 1/60 s. `srand(seed)` trước mỗi mục; `Ogre::Math` dùng `rand()` trên x64.
   - Camera khung theo hợp bounds tại các mốc.
   - Kết quả ở `Build\Logs\2026-09-13-fx-audit\sheets\<set>-<list>[-label][-repN]\`: `sheets\<id>.png`, `overview-black|grey.png`, `sheet-index.tsv`, `metrics.tsv`, `captures.tsv`, `compare.json`.
5. **So hai lượt:** `py -3 Tools\fx\fx_sheet.py --compare <A> <B>` (số cặp, trùng byte, trùng pixel, SSIM nhỏ nhất). Quy trình lặp lại xem mục 7.
6. **Nghiệm thu theo mục:**
   - `py -3 Tools\fx\fx_report.py --classify <run> [...]`: lớp của từng mục theo quy tắc mục 4 (`visible`, `saturated`, `alive-nothing-drawn`, `bounds-blowup`, `no-particles`, `absent`, `error`).
   - `py -3 Tools\fx\fx_report.py --diff <run trước> <run sau>`: mục đổi lớp, độ phủ, độ bão hoà, cạnh box.
   - Nhánh sửa dùng hai lệnh này để chứng minh tiêu chí ở mục 5.

## 3. Census — kết quả (FACT, runtime run-b3)

| Nhóm (số lần xuất hiện) | stage | Canonical | S2 |
|---|---:|---:|---:|
| Dòng hạt bị từ chối (`rejected-key`) | 6 | 18.831 | 19.141 |
| Giá trị hạt không áp (cần xem; chủ yếu Ring `inner_*` 0 → 1) | 96 | 1.449 | 2.063 |
| Khoá effect bị từ chối | 7 | 9.281 | 14.409 |
| Khoá effect nhận nhưng không dùng (giá trị có tác dụng) | 0 | 2.082 | 14.731 |
| Khoá skill bị từ chối (`DefaultShow`…) | 0 | 4.512 | 6.425 |
| Texture không mở được do tên CJK / thật sự thiếu (vật liệu hạt) | 323 / 10 | 0 / 0 | 1.316 / — |
| Mesh của renderer `mesh` không mở được (CJK) / thiếu: effect ném ngoại lệ | 196 / 7 | 0 / 10 | 10.285 / 12 |
| Template hạt thiếu / vật liệu hạt thiếu | 14 / 8 | 0 / 17 | 0 / 19 |
| Vật liệu hạt đục (`one zero`) | 17 | 200 | 1 |
| Quota ≥ 2.000 | 5 | 13 | 19 |
| File script bị dừng | 0 | 0 | 1 (all.material) |

Khoá bị từ chối lớn nhất (Canonical, `Registry\fx\census-canonical.tsv`):

| Khoá | Lần | Template/effect | Ví dụ |
|---|---:|---:|---|
| effect `use_scale` | 8.525 | 8.525 | `2025争霸赛第一名_skill_07` |
| ColourFading `opacity3` / `opacity0` / `opacity2` / `opacity1` / `opacity4` / `opacity5` | 7.585 / 4.484 / 2.301 / 1.532 / 1.364 / 306 | cùng số | `back_2024月光宝盒_A_14` |
| AnimEffect `DefaultShow` | 4.512 | 1.905 skill | `qc_2024争霸赛第一名_地面休闲2` |
| ScaleInterpolator `use_interpolated_increment`, `increment_time0..5`, `increment_value0..5`, `use_uniform_size`, `increment_repeat_times` | ≈ 1.259 | ≈ 600 | `back_2025北极熊玩偶_自身_2` |
| Beam `WaveVelocity`, `WaveShade-y/z`, `WaveFrequency`, `WaveExtent-y/z`, `TexRepeat`, `SubElementFrequency`, `SpLineEditor`, `IsVisable`, `IsSubEleActive`, `IsSinPlay`, `CurveType`, `BindElement` | 54 mỗi khoá | 29 effect | `hj_慕容武道_日月任我攀连线` |

Khoá được nhận nhưng không dùng. Bằng chứng mã: member chỉ xuất hiện ở khai báo, hàm khởi tạo và ParamCommand (`WXParticleElement.cpp:42-44`, `Tools\fx\ignored_keys.tsv`).

| Khoá (element Particle) | Canonical | S2 |
|---|---:|---:|
| `ParEffectName` ≠ NullEffect (hiệu ứng con mỗi hạt) | 805 (457 effect) | 7.049 |
| `use_particle_effect true` | 785 | 6.876 |
| `pass_rotation_to_sub_effect true` | 241 | 167 |
| `legacy_pos_for_sub_effect false` | 163 | 95 |
| `use_energy_wave true` | 38 | 337 |
| `ColEffectName` ≠ NullEffect (hiệu ứng khi va chạm) | 25 | 44 |
| `use_particle_collision true` | 21 | 163 |
| `CreateLevel` (không nơi nào đọc; mức hiệu ứng luôn EL_HIGH, `WXEffectManager.cpp:114`) | 4 | — |

### S2 (ngang hàng Canonical theo quyết định orchestrator 13/09)

- Census S2 (bảng trên): dòng hạt bị từ chối (19.141) và khoá effect bị từ chối (14.409) còn cao hơn Canonical.
- Khoá nhận nhưng không dùng: 14.731 (hiệu ứng con `ParEffectName` 7.049, `use_particle_effect` 6.876, `use_energy_wave` 337, `use_particle_collision` 163…). S2 dựa vào hiệu ứng con nhiều gấp khoảng 9 lần Canonical.
- 10.285 tham chiếu mesh của hạt mesh không mở được do tên CJK.
- Sheet S2 dùng `--wide-names` (archive `FileSystemW` của viewer đọc được tên CJK như máy CP936) trên bản `run-b7` (HEAD + việc đang dở của các nhánh lúc 18:30), nên không phải mốc “trước sửa”. Kết quả ở mục 4.
- **Sự thật hình ảnh của nội dung CY người dùng đang thấy** là sheet stage-frontend: cảnh tạo nhân vật đã được closure CY đổi tên sang dạng cp1252. Các lỗi: D1 (lá/hoa thành ô vuông), D3 (vệt Quỷ Cốc), D4 (vũ khí môn phái cháy trắng), D14 (lửa Minh Giáo), D20 (ánh sáng bục chọn mất màu).

## 4. Kiểm hình (sheet)

Viết tắt thư mục trong `Build\Logs\2026-09-13-fx-audit\sheets\`:

| Tắt | Thư mục |
|---|---|
| SF | `stage-frontend-rep1` (và `-warm-rep1/2`) |
| SK | `stage-skills` |
| SO | `stage-oracle` |
| CF | `canonical-frontend` |
| CO | `canonical-oracle` |
| CK | `canonical-skills` |
| CE | `canonical-evidence` |

| Lượt | Mục | Kết quả |
|---|---:|---|
| SF (warm) | 76 | 76 ok; 18 mục bão hoà (`saturated_black_max` > 2 %: S002/S017 21–22 %, S027 18 %, S008/S023 8 %, S012 6,5 %); 2 “vô hình” thật ra do bounds nổ (E015, E017) |
| SK | 40 | 38 ok, 2 lỗi (K31 `梅花.mesh`, K32 `冰晶.mesh` không mở được: effect ném ngoại lệ) |
| SO | 100 | 92 không có trong dữ liệu stage; 7 ok; 1 lỗi (E088 `冰晶.mesh`) |
| CF | 76 | 63 ok, 13 không có (model môn phái CY không có trong Canonical); lỗi trắng/khối lửa giống stage; lá `yezihuyang01` đúng màu |
| CO | 100 | xem bảng dưới |
| CK | 40 | 39 ok (Canonical có `梅花.mesh` nên K31 chạy: 133 draw call ở 1 s) |

Canonical oracle theo loại mới (`Tests\oracle\cases.json` `new_type`):

| Loại | Hiện | Bão hoà | Hạt sống, không vẽ gì | Bounds > 5.000 u | Không có hạt |
|---|---:|---:|---:|---:|---:|
| RotationCurve (12) | 1 | 1 | 6 | 4 | 0 |
| RevoluMove (12) | 3 | 0 | 4 | 3 | 2 |
| SequenceFrame (12) | 6 | 1 | 2 | 3 | 0 |
| Dissolve (12) | 6 | 0 | 1 | 2 | 3 |
| NewRibbonTrail (12) | 5 | 0 | 1 | 0 | 6 (cần vật chủ di chuyển) |
| PolarMove (11) | 10 | 0 | 1 | 0 | 0 |
| UIParticle (5) | 2 | 0 | 3 | 0 | 0 |
| không loại mới (24) | 13 | 4 | 2 | 3 | 2 |

- “Hạt sống, không vẽ gì”: E003 E013 E016 E017 E022 E024 E027 E028 E039 E041 E045 E056 E057 E060 E061 E063 và 4 mục khác.
- “Bounds nổ”: E020 10.063 u, E023 8.944, E025 7.218, E033 104.040, E034 68.809, E040 39.377, E042 26.005, E046 56.318, E058 8.059, E059 28.830, E062 5.629, E065 92.945, E080 5.520, E085 10.966, E100 41.773.

### S2 và bản `run-b8` (18:35 = engine `run-b7` + `--wide-names` đã sửa đường dẫn có thư mục)

`run-b8` gồm việc đang dở của các nhánh. Mọi so sánh với `run-b3` trộn thay đổi của dữ liệu và của engine; tách bằng `fx_report.py --diff` như bảng dưới.

| Lượt | Mục | Kết quả (`fx_report.py --classify`) |
|---|---:|---|
| `s2-frontend-wide2` | 76 | 69 visible, 4 alive-nothing-drawn (P007 P017 P021 P029: hạt cảnh nhỏ/xa), 2 saturated (P020 P022), 1 visible-bounds-blowup (P008). **Không còn model trắng**. Ánh sáng bục chọn xanh lá/cam/lam đúng màu; lá `yezihuyang01` màu cam |
| `s2-skills-wide2` | 40 | 36 visible, 2 saturated, 2 absent (K17/K40 không có trong S2). K31/K32 (hạt mesh Thiên Sơn) vẽ được vì mesh đọc được: xác nhận nguyên nhân D9 |
| `s2-oracle-wide2` | 100 | 55 có trong S2: 45 visible, 4 alive-nothing-drawn (E017 UIParticle, E045 Dissolve, E056/E061 RotationCurve), 3 no-particles, 2 saturated, 1 bounds lớn (E020 RevoluMove) |
| `stage-frontend-wide2` | 76 | Hạt: lá/hoa có texture (xem trước D1); ánh sáng bục chọn **có màu** (texture của nó vẫn đọc được dưới ANSI, nên D20 được sửa bởi thay đổi engine trong `run-b7/b8`, nhiều khả năng bản đồng bộ variant của R). **30 model + E015/E017 lỗi**, chỉ khi `--wide-names` trên dữ liệu stage (`Unable to load mesh 女少林脸.mesh`, `特效武器鬼谷杖神96升星.mesh`, `jpg_特效武器笛子.dds`) |

Ghi chú:
- **Giới hạn của `stage-frontend-wide2`:** chỉ dùng phần hạt/effect không có mesh. Nguyên nhân model lỗi chưa rõ:
  - không phải trùng tên hai dạng (chỉ `葵花.mesh` có ở cả dạng cp1252 lẫn CJK);
  - ba file lỗi không có ở dạng nào trong `stage\Data`.
  - Người sửa D1 phải kiểm nạp model sau khi đổi lớp tài nguyên sang W, không chỉ kiểm texture.
- **Thiếu mốc B (khoảng trống).** `Tests\oracle\baseline` không tồn tại: chưa ai chụp ảnh client_GL. Chụp B cần chạy client_GL, điều bị cấm trong phạm vi này. Tiêu chí “SSIM ≥ 0,95 so với B” (doc 04) vì vậy chưa đo được; cần orchestrator quyết cách lấy ảnh B.

### Canonical oracle, chỉ đổi engine: `run-b3` → `run-b8` (cùng dữ liệu)

Lệnh: `py -3 Tools\fx\fx_report.py --diff sheets\canonical-oracle sheets\canonical-oracle-b8`. Kết quả đầy đủ trong `Build\Logs\2026-09-13-fx-audit\oracle-b8-diff.txt`: 56 mục đổi.

| Lớp | `run-b3` (mốc) | `run-b8` (việc đang dở 18:30) |
|---|---:|---:|
| visible | 46 | 78 |
| saturated | 6 | 4 |
| alive-nothing-drawn (D2) | 20 | 6 |
| bounds-blowup > 5.000 u (D3) | 15 | 1 (+3 visible nhưng box 5.290–5.995 u) |
| no-particles | 13 | 8 (6 là NewRibbonTrail đứng yên) |

- **Đã khá lên:**
  - E033: box 104.040 → 3.386 u;
  - E065: 92.945 → 1.860 u;
  - E034/E040/E046/E059/E100 hết bounds nổ;
  - RotationCurve E057/E060/E063/E064, SequenceFrame E039/E041, UIParticle E013 nay vẽ được.
- **Còn lỗi:**
  - E017 (UIParticle), E024 (RevoluMove), E045 (Dissolve), E056/E061 (RotationCurve) vẫn không vẽ gì;
  - E023 vẫn bounds nổ.
- **Hồi quy mới, nhánh sửa phải kiểm:**
  - E097: visible → không vẽ gì;
  - E016: không vẽ gì → cháy trắng;
  - E090: visible → cháy trắng;
  - E044: box 3.589 → 5.995 u;
  - E048: độ phủ 0,261 → 0,007;
  - và ở stage: vòng sét Thiếu Lâm S001/E001, lửa Minh Giáo S002/E002 (mục dưới).

### Quan sát sớm trên `run-b7` (HEAD + việc đang dở của các nhánh lúc 18:30; stage, không `--wide-names`)

| Mục | Mốc `run-b3` | `run-b7` (18:30) | Ý nghĩa |
|---|---|---|---|
| Mục Minh Giáo `S002`, effect `E002` | lửa trắng cháy, mép vuông | 3 ngọn lửa cam nhỏ | D4/D14 đổi hẳn, có thể do bản sửa đồng bộ variant/ColorX4 của R hoặc thay đổi hạt của P. **Cần nhánh sửa xác nhận là cố ý** và so với B |
| Mục Thiếu Lâm `S001`, effect `E001` | vòng sét xanh trên đất | vòng sét **mất**, còn đốm nhỏ | **Có thể là hồi quy** do việc đang dở; nhánh sửa phải kiểm |
| `P025 yezihuyang01` | ô vuông trắng | ô vuông trắng | D1 là lỗi dữ liệu, không đổi (đúng kỳ vọng) |
| `P027 选人台_01` | vòng cam | vòng cam | Hạt FF không đổi |

Ảnh: `sheets\stage-control-b7ansi\sheets\S001.png`, `S002.png` so với `sheets\stage-frontend-rep1\sheets\S001.png`, `S002.png`. Danh sách: `Tests\fx\audit\lists\control.tsv`.

## 5. Danh sách lỗi xếp hạng (tác động × tần suất)

| # | Lỗi | Tác động × tần suất | Bằng chứng | Nguyên nhân | Chủ | Nghiệm thu đo được |
|---|---|---|---|---|---|---|
| D1 | Texture/mesh của stage không mở được: hạt thành ô vuông trơn; effect có hạt mesh bị mất hẳn | Rất cao × game hiện tại (323 texture + 196 mesh; 15.757 file) | `SF\sheets\P029.png`, `P025`; so với `CF\sheets\P025.png`; `SK\items.tsv` K31/K32 lỗi; `Registry\fx\census-stage.tsv` nhóm `unreachable-*` | FACT: tên file CJK (Reference) + `OgreFileSystem.cpp:318/374/505` ANSI dưới ACP 1252 | D (đổi tên như Canonical) hoặc lõi tài nguyên (CreateFileW, doc 08 §1.3) | Census stage: `unreachable-texture` = 0, `unreachable-mesh` = 0; P025/P029 có hình; SK K31/K32 và SO E088 status `ok` |
| D2 | Effect hiện đại: hạt sống nhưng **không vẽ ra gì** (hạt mesh RotationCurve, SequenceFrame, Dissolve, UIParticle) | Rất cao × 20/100 đối chứng | `CO\sheets\E056.png` (RotationCurve, 2–4 hạt, đen hoàn toàn, +8 vật liệu clone), `E039` (SequenceFrame, 13 hạt), `E022`, `E045` | GT (có bằng chứng mã fx-render): vật liệu vẽ là **bản clone** (`CysMaterialSystem::getVariantMaterial`, `.cpp:541-545`), còn game ghi màu/alpha của hạt mesh, hằng `sequenceFrameUVFactor`/`dissolve*` vào vật liệu **gốc**; bản sửa “follow source” của R đang làm. Thêm: affector CYS có thể chưa cập nhật UV/clip | R (đồng bộ variant), E (RotationCurve/SequenceFrame/Dissolve) | CO: “hạt sống, không vẽ gì” 20 → ≤ 2; mỗi mục có `coverage_black_max` ≥ 0,001 |
| D3 | **Bounds nổ / hạt bay xa** 5–104 km: vệt mờ rộng cả màn (Quỷ Cốc), effect thành chấm nhỏ | Cao × 15/100 đối chứng + stage E015/E017 | `metrics.tsv` (`box_*`): CO E033 104.040 u, E065 92.945 u; SF E015 z −182…13.859, E017 y −12.127…8.653; `SF\sheets\S012.png` (vệt che 71 % khung ở 3 s) | GT: Revolution/RevoluMove (bán kính/tốc độ sai đơn vị, hoặc `radius_increment` cộng dồn), chuỗi ribbon nối qua hạt tái sinh (`OgreRibbonRenderer.cpp:199-204` chỉ reset khi hết hạn) | P (Revolution/RevoluMove, ribbon), E (SequenceFrame/Dissolve/RotationCurve nếu có dịch chuyển) | Mọi id nêu trên: cạnh lớn nhất của box ≤ 5.000 u; S012/S027 không còn vệt che khung |
| D4 | **Cháy trắng** vũ khí môn phái (Minh Giáo, Thiên Sơn, Cái Bang, Quỷ Cốc) | Cao × 18/76 mục màn tạo nhân vật; giống hệt ở Canonical | `SF\sheets\S002.png`, `S003`, `E002`, `E008`; `CF\overview-black.png`; vật liệu `g01_em_绝剑式_2`; `CysCreateScene.program:58`; `Particle_ps.hlsl fmt_output` kẹp [0,1] | GT (bằng chứng mã): `BLEND_OP_0=2` = MODULATE_X4 (`CysMaterialSystem.cpp:707-708`) trên đích LDR, nhiều lớp `one one`; B cộng trên HDR rồi tonemap | R | `saturated_black_max` của S002/S017/S027/S012/S008/S023/E002/E008 ≤ 0,02, `coverage_black_max` giữ ≥ 70 % hiện tại |
| D5 | `ColourFading opacity0..5` bị từ chối: đường cong độ trong mất | Cao × 17.572 dòng Canonical (6 stage) | `census-canonical.tsv`; `OgreColourFadingAffector.cpp:69-95` | FACT | P | `rejected-key opacity*` = 0 trên Canonical |
| D6 | `use_scale` của effect bị từ chối: effect không co giãn theo model (cảnh tạo dùng scale 1,5) | Cao × 8.525 effect Canonical | `census-canonical.tsv`; `SF\sheets\E011.png` (stage, 7 effect Đường Môn); `CE\sheets\U01..U06.png` | FACT: Effect không có tham số này; GT về nghĩa | E | `rejected-key use_scale` = 0; sheet U01–U06 với `--scale 1.5` của fx-effects: bounds ×1,5 |
| D7 | **Hiệu ứng con của hạt không bao giờ sinh ra** (`ParEffectName`, `ColEffectName`, `use_particle_effect/_collision`, `use_energy_wave`) | Cao × 805 element (457 effect) Canonical; 7.049 S2 | `CE\sheets\V01.png` (effect cha, thưa) cạnh `V02..` (hiệu ứng con vốn phải xuất hiện theo từng hạt); `WXParticleElement.cpp:42-44` | FACT: member chỉ khai báo/khởi tạo | E | `accepted-but-ignored ParEffectName/use_particle_effect` = 0 (đã dùng); sheet cha có các chùm con |
| D8 | `AnimEffect DefaultShow` bị từ chối | Trung bình × 4.512 (1.905 skill) | `census-canonical.tsv` | FACT | E | `rejected-key DefaultShow` = 0 |
| D9 | Renderer `mesh` ném ngoại lệ khi không tìm thấy mesh, **mất cả effect** (có thể làm lỗi chiêu trong thế giới) | Cao khi xảy ra × stage 203, Canonical 10 | `SK\sheet.log` K31 (`OgreResourceGroupManager.cpp:1375`) | FACT | P | Không ngoại lệ: element bị bỏ kèm log một lần; SK K31/K32 status `ok` |
| D10 | ScaleInterpolator của B (`use_interpolated_increment`, `increment_*`, `use_uniform_size`) bị từ chối | Trung bình × ≈ 1.259 dòng | `census-canonical.tsv` | FACT | P | Các khoá này `rejected` = 0 |
| D11 | Beam thiếu 12 khoá sóng/đường cong | Thấp–trung bình × 29 effect | `census-canonical.tsv` | FACT | E | 12 khoá `rejected` = 0 |
| D12 | Ring `inner_* 0` bị ép thành 1: hạt chỉ trên vành | Trung bình × 726 template Canonical, 48 stage | `OgreRingEmitter.cpp:106-131` (mã 0.85 có `//======`) | FACT: mã 0.85; GT: B khác | P | Kết luận có bằng chứng B; nếu B cho 0 = đĩa đặc thì `value-not-applied Ring inner_*` = 0 |
| D13 | Vật liệu hạt đục (`one zero`) | Trung bình × 200 vật liệu Canonical, 17 stage | nhóm `opaque-pass` | GT: một phần sprite cố ý cần `alpha_rejection` | R | Mỗi vật liệu có blend hoặc alpha reject; không quad đen |
| D14 | Lửa Minh Giáo mép vuông răng cưa | Trung bình (2 model) | `SF\sheets\E002.png`, `CF` giống hệt | GT: `jpg_huo_2.dds` không alpha + cộng dồn + xoay/phóng | R (hoặc E nếu B khác dữ liệu) | Không còn cạnh vuông ở t = 0,8 s |
| D15 | Vật liệu hạt mesh bị clone theo từng hạt sinh ra | Chi phí | `metrics.tsv` `materials_end − materials_start`: E006 +8, S013/S028/E017 +4, E015 +2 (3 s) | FACT; R đã có `purgeDeadVariants` đang làm | R | Chênh = 0 hoặc có trần qua 60 s |
| D16 | Chi phí: RevoluMove update 3,9 ms/14 hạt; renderer `mesh` 1 draw/hạt | Chi phí | `CO\sheet-index.tsv` E022; `CK` K31 133 draw, K32 80 draw | FACT (E022 cần đo lại warm) | P/perf | E022 update ≤ 0,3 ms; draw của K31 ≤ số hệ hạt + số mesh khác nhau (instancing) |
| D17 | Thứ tự cập nhật hạt phụ thuộc địa chỉ nên hình không tất định | Kiểm thử | mục 7 | FACT | P (lõi) | `fx_sheet --repeat`: `identical_pixels` = `pairs` |
| D18 | S2 all.material dừng vì vật liệu trùng tên | Dữ liệu | mục 1 | FACT | D; lõi (trùng tên: bỏ qua + log, không ném) | S2 runtime nạp đủ vật liệu |
| D19 | Viewer giấu dòng dữ liệu | Công cụ | mục 0.6 | FACT | fx-audit (đã xong) | — |
| D20 | **Ánh sáng bục chọn nhân vật CY** (`天龙2选人台绿/橙/蓝_01/02`) xám mờ, mất màu xanh/cam/lam; hạt cạnh đó (`选人台_01/02`) giữ màu cam/lam | Cao × cảnh tạo nhân vật (6 hệ hạt, thấy ngay khi chọn nhân vật) | `SF\sheets\P009..P014.png` (warm), so với `P027/P028`; dump stage: `天龙2选人台绿_01` dùng vật liệu `天龙2选人台蓝_01` pass `one one`, **lighting 1**, fp `Particle_PS` (ps_3_0); ColourFading `colour1 0.53 1 0.55`, `colour2 0.66 1 0.08`, `opacity 0.5`. `选人台_01` là pass FF, lighting 0 | GT (bằng chứng dữ liệu + mã): đường shader hạt ps_3_0 (`Particle_ps.hlsl` + VS ghép bởi CysMaterialSystem, lighting on) không đưa màu đỉnh (ColourFading) vào kết quả hoặc nhân với diffuse đen của mẫu; hạt FF thì đúng | R | Sắc độ trung bình (chroma) của P009/P010 là xanh lá, P011/P012 cam, P013/P014 lam, cùng mức với P027/P028; `coverage_black_max` tăng |

**Mẫu số chung của D2, D4, D20 (FACT từ dump + sheet):**
- Hạt dùng pixel program ps_3_0 của B (`Particle_PS`, `Particle_ColorX2_PS`, `Particle_ColorX4_PS`; VS do CysMaterialSystem ghép) thì sai: trắng cháy, mất màu, hoặc không vẽ gì.
- Hạt vật liệu FF (không program) cùng cảnh thì đúng.
- R nên kiểm trước hết: màu đỉnh/`surface_diffuse_colour`, lighting on với diffuse đen của mẫu, hằng mỗi phiên bản (sequence frame, dissolve) trên bản clone, kẹp và cộng LDR.

**Thứ tự đề nghị:**
1. D1 (game đang chạy).
2. D2 + D3 (đa số hiệu ứng hiện đại) và D4 (màn tạo nhân vật).
3. D5–D7 (khi chuyển game sang Canonical).
4. D9 (tránh lỗi chiêu).
5. D10–D16.

## 6. Chi phí mỗi hiệu ứng (FACT, `metrics.tsv` / `sheet-index.tsv`)

| Cột | Ý nghĩa |
|---|---|
| `particles_max_t1` | Hạt lớn nhất trong cửa sổ 0,9–1,1 s |
| `systems_t1`, `quota_t1` | Số hệ hạt và tổng quota |
| `draws_t1` | Số `Draw*Primitive*` D3D9 trong khung 1 s (vá vtable slot 81–84 trong tiến trình viewer) |
| `faces_t1` | Số mặt |
| `update_ms_t1` | Frame listener + `ControllerManager::updateAllControllers` |
| `render_ms_t1` | Render target + nộp D3D |
| `gpu_ms_t1` | Chờ event query |
| `materials_*`, `textures_*` | Số vật liệu/texture đầu và cuối lượt chụp |

- **Đo lượt ấm.** Lượt đầu có biên dịch shader và nạp texture, ví dụ E011 27,7 ms ở lượt lạnh, 0,34 ms ở lượt ấm. Cột chi phí chỉ lấy từ lượt thứ hai.
- Frontend stage ấm: update ≤ 0,05 ms. Render cao nhất E006 3,5 ms, S008 2,0 ms, E017 1,6 ms, P018 1,3 ms.
- Canonical oracle: render ≤ 3,0 ms (E013, E021, E025, E022). **Update E022 3,88 ms** với 14 hạt (RevoluMove), các mục khác ≤ 0,3 ms.
- Renderer `mesh`: `CK` K31 133 draw ở 1 s (107 hạt), K32 80 draw (24 hạt), tức mỗi hạt mesh là một entity riêng.
- Quota: mục 3.

## 7. Lặp lại (tất định)

Mục tiêu nhiệm vụ: hai lượt giống hệt phải cho SSIM = 1.

| So sánh | Cặp ảnh | Trùng byte | SSIM nhỏ nhất | Ghi chú |
|---|---:|---:|---:|---|
| SF rep1 (shader lạnh) vs rep2 (ấm) | 640 | 194 | 0,517 (S012 3 s) | Cache shader khác nhau giữa hai lượt |
| SF warm-rep1 vs warm-rep2 (cùng cache ấm) | 760 | 300 | 0,468 | Số hạt khớp 100 %; 30/30 model, 15 effect, 5 hạt lệch |
| SF noaslr-rep1 vs noaslr-rep2 (exe xoá cờ ASLR, `run-b3-noaslr`) | 760 | 291 | — | **Không giúp**: 30 model, 16 effect, 7 hạt vẫn lệch. DLL và heap vẫn ngẫu nhiên hoá, nên xoá cờ của exe không làm địa chỉ cố định |

**Kết luận hiện tại:** chưa đạt SSIM = 1 cho toàn danh sách.
- Trùng từng byte: hiệu ứng một hệ hạt FF (đa số P*).
- Lệch: mọi mục có từ hai hệ hạt trở lên, hoặc gắn trên model.
- Mẫu hình này khớp cơ chế dưới đây. Việc sửa thuộc lõi (P); harness không tự sửa được mà không đổi OgreMain.

- **Nguyên nhân (FACT mã):**
  - `ControllerManager` giữ controller trong `std::set<Controller<Real>*>` (`OgreControllerManager.h:51`), mỗi hệ hạt có một controller thời gian khung riêng (`OgreParticleSystem.cpp:851`). Thứ tự cập nhật các hệ là thứ tự **địa chỉ**.
  - Mọi hệ lấy số ngẫu nhiên từ một dòng `rand()` chung (`asm_math.h`: `float(rand())` trên x64). `srand(seed)` trước mỗi mục vẫn không đủ khi có từ hai hệ hạt trở lên.
  - Hệ quả phụ: EffectManager cũng cập nhật qua một controller trong cùng tập, nên effect bắt đầu sớm hay muộn một khung tuỳ địa chỉ.
  - Mô hình tĩnh (tư thế bind) lệch ngay từ 0,15 s vì hiệu ứng vũ khí gắn trên nó.
  - Hiệu ứng một hệ hạt, FF không shader, trùng byte (P003 và phần lớn P*).
- **Việc cần làm cho tất định thật (P, lõi):** thứ tự controller theo lúc tạo (vector/danh sách) hoặc bộ sinh số riêng cho từng hệ hạt, seed từ tên template + số thứ tự. Đồng thời sinh ngẫu nhiên theo từng hệ còn cho hình đẹp ổn định giữa các máy.
- **Quy trình kiểm lặp lại hiện tại:** một lượt làm ấm cache, rồi hai lượt đo cùng cache (`--repeat --cache <bản sao>`). Chỉ chấp nhận SSIM = 1 trên nhóm hạt một hệ cho tới khi D17 được sửa.

## 8. Bẫy mới (bổ sung doc 08)

- **Tên file CJK:**
  - Dữ liệu Reference/stage/S2 dùng tên Unicode CJK. Engine chỉ mở được tên GBK hiển thị qua cp1252 (Canonical, client_GL).
  - Kiểm bằng `name.encode('cp1252')`.
  - Census phân biệt `unreachable` (có trên đĩa) với `missing`.
- **Scene CY khai báo `encoding="UTF-8"`:** tên particle trong `tl3chuangjian.Scene` là UTF-8. `WXExpatParser.cpp:83` đổi sang CP936 nên game khớp; công cụ phải giải mã theo khai báo XML.
- **Log EffectManager chỉ báo mỗi khoá lạ một lần** (`_logErrorInfoOnce`, `WXEffectManager.cpp:1260`). Đếm lỗi all.effect bằng từ điển runtime, không bằng log.
- **Mức log:** thông báo “Bad particle … line” ở mức LML_NORMAL; viewer mặc định LL_LOW sẽ bỏ. Census tự nâng mức log.
- **Tra tên vắng rất chậm:** `ResourceGroupManager::resourceExists` với tên vắng `stat` từng location (500–1.500), hàng giờ trên Canonical. Dùng chỉ mục tên đã liệt kê.
- **Vật liệu trùng tên dừng cả file** (S2 all.material), khác hạt: template hạt trùng chỉ bỏ block.
- **So chi phí phải dùng lượt ấm.** Lượt lạnh gồm biên dịch shader/nạp texture.
- **Chụp không tất định khi có nhiều hệ hạt** (mục 7). So ảnh trước/sau sửa phải dùng cùng một lượt ấm, hoặc so theo nhóm một hệ hạt, cho tới khi D17 được sửa.
- **NewRibbonTrail cần vật chủ chuyển động.** Chụp effect đứng yên cho ảnh trống; không kết luận lỗi.

## 9. Việc tiếp theo của fx-audit

1. Tất định: `noaslr` không giúp (mục 7). Chờ P sửa D17, rồi chạy lại `--repeat` trên bản dựng mới. Mục tiêu `identical_pixels` = `pairs`.
2. Thêm chế độ vật chủ chuyển động (quỹ đạo tròn) cho NewRibbonTrail và hiệu ứng vũ khí.
3. Chạy lại census + sheet trên bản dựng sau khi P/E/R sửa. So `census-*.tsv` và `sheet-index.tsv` trước/sau theo tiêu chí mục 5.
4. Bổ sung sheet S2 khi có bản S2 đổi tên file sang dạng cp1252 (hiện 69.793 tên CJK).
