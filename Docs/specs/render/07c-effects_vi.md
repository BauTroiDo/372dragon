# 07c — Hệ hiệu ứng: đặc tả B, kiểm kê "parse vs dùng", và khoảng trống

Ngày: 2026-09-13. Tác nhân: fx-effects (Claude). Trạng thái: đặc tả + kiểm kê + vá `use_scale`.
Ký hiệu: FACT = đọc trực tiếp từ binary/dữ liệu/mã nguồn; INF = suy luận.

Nối tiếp `04-effects-particles.md` (9 kiểu mới, pha E2). Tài liệu này trả lời câu hỏi của điều phối:
"khoá nào được **parse mà không dùng** lúc chạy?" và mô tả bộ máy hiệu ứng của B (client_GL `Render.dll`)
để dựng lại clean-room.


---

### 1.8 Pool & dọn dẹp

---

## 2. So B với C (CY 3.71)
Toàn bộ dict hiệu ứng của C **giống hệt B theo tên khoá, kiểu, thứ tự và mô tả** (`B_adders.txt` vs `C_adders.txt`
khác duy nhất địa chỉ hàm). C có thêm `dissolveBox` ở material-system (đã ghi ở 04/01). Kết luận: đặc tả B ở trên
dùng chung cho C.

---

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
