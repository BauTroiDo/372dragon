# cy_four_combat — ánh xạ ID: ĐỪNG sửa `native_config.lua`

Ngày 17/09/2026. Bằng chứng: `Build/Logs/2026-09-17-cyfour-map/`.

## 1. Kết luận (đọc trước khi động vào)

Nhận định **"`native_config.lua` thiếu ánh xạ 4079/4251/4260/4347/4400/4543/4549 ⇒ `tao.lua:30` assert nổ"** là **SAI**.
Bảy ID đó do hai **overlay** cấp lúc khởi động, không nằm trong `native_config.lua`:

| overlay | nạp bởi | cấp thêm vào `resolve.impacts` |
|---|---|---|
| `cy_four_combat/phase2_config.lua` dòng 3 | `phase2.lua:5-17` | 4079, 4251, 4258, 4259, 4260, 4400, 4517, 4518, 4543, 4549 |
| `cy_four_combat/release_config.lua` dòng 2 | `release.lua:8-11` | 4346, 4347 |

`integration.lua:5-7` gọi `phase2.configure` → `phase3.configure` → `release.configure` **trước** khi dựng bridge;
`tao.lua` nhận `map` = `config.resolve` **sau** khi đã gộp. Đường khởi động thật: `scenecore.lua:253` → `startup.lua:6`
→ `integration.prepare(deployment_config, …)`.

## 2. Đo thật (lua 5.4 trên chính cây server)

`Build/Logs/2026-09-17-cyfour-map/chk2.lua` nạp `deployment_config` rồi chạy đủ ba `configure`:

```
gameplay_enabled= true   talents_enabled= false
phase2   configure ok=true
phase3   configure ok=true
release  configure ok=true
resolve.impacts = 1140 | tao_logic168_base_ready= true
  skill 3801  template->3801  thieu_ref: KHONG
  skill 3804  template->3804  thieu_ref: KHONG
  skill 3809  template->3809  thieu_ref: KHONG
  skill 3820  template->3820  thieu_ref: KHONG
  skill 3822  template->3822  thieu_ref: KHONG
disabled_logic_ids:   (rỗng)
disabled_impacts:     (rỗng)
```

Chỉ đọc `native_config.lua` thì `resolve.impacts` có **1.128** mục; sau khi gộp overlay là **1.140**. Cả 7 ID đều
resolve đồng nhất (`4400 → 4400` …). Bảng `refs` của `tao.lua:15-20` đủ tham chiếu cho **cả 5** chiêu native
(3801/3804/3809/3820/3822), và hai bảng chặn cuối cùng đều **rỗng**.

Bảy dòng StandardImpact tương ứng đều CÓ THẬT trong `configs/StandardImpact.txt` (27.847 dòng):
4079 聚星阵·长生恢复, 4251 聚星阵·阴阳, 4260 聚星阵·贪狼, 4347/4400 桃花岛暗伤标记, 4543/4549 棹歌中流.

## 3. Vì sao thêm tay vào `native_config.lua` sẽ LÀM HỎNG khởi động

Hai overlay dùng `assert` **cứng**, không có lối thoát kiểu "trùng giá trị thì bỏ qua":

- `release.lua:10` — `assert(not c.resolve.impacts[source])` ⇒ thêm `[4347]=4347` vào `native_config` là nổ ngay.
- `phase2.lua:15` — `assert(config[key][id]==nil,'phase2 config collision')` ⇒ thêm mục mô tả
  `[4079]={donor_id=…}` vào bảng `impacts` cấp trên cũng nổ.

(`phase2.lua:12` với nhánh `resolve` thì có tha nếu trùng đúng giá trị, nhưng `release.lua:10` thì không.)
Nổ ở đây nghĩa là `startup.configure()` assert ⇒ **hỏng cả scene**, không phải hỏng một chiêu.

## 4. Giới hạn của `Tools/server/cyfour_map.py`

`cyfour_map.py check` báo `con_thieu_sau_khi_them: 7` với đúng 7 ID trên. Đó là **giới hạn của công cụ**: nó chỉ đọc
`native_config.lua`, không đọc `phase2_config.lua`/`release_config.lua`. Con số 7 đó **không** là lỗi dữ liệu.
Nếu muốn sửa thì sửa phần đọc của công cụ (gộp thêm hai overlay), tuyệt đối không "sửa dữ liệu cho khớp công cụ".

Ghi chú liên quan: `impact_data.py cyfour_mapped()` chỉ đếm dạng `[N]={` (408 mục) nên bỏ sót 1.128 mục dạng `[N]=N`;
`taohua_impacts.py` đọc cả hai dạng (1.298). Khi so số liệu giữa hai công cụ phải nhớ điều này.

## 5. Nếu 3809 / 3820 / 3822 vẫn không ăn

Không phải do ánh xạ. Hướng soi tiếp, theo thứ tự:

1. `phase2.lua:42-44` — `tao.port:ready(source)`; nếu chặn thì `block(source,why)` ghi lý do vào
   `config.disabled_skills[template]`. Lấy đúng chuỗi `why` (`outside_bounded_port`, `missing_faction_binding`,
   `missing_adapter:<tên>`, `missing_reference:<kind>:<id>`, `logic168_unverified`…).
2. `tao_installation.lua:6` — `logic168_verified` = `tao_logic168_verified` **hoặc** `tao_logic168_base_ready`
   (cái sau do `release.lua:20` đặt). Đo ở trên cho thấy nó đã `true`.
3. Adapter thiếu hàm: `capabilities` ở `tao.lua:8-14` liệt kê tên hàm mà `runtime_adapter` phải có.

## 6. NHƯNG `params` thì SAI THẬT — 282 ô đã sửa (17/09)

Mục 1–5 nói về **khoá** của bảng `impacts` (đủ, đừng thêm). Phần **`params` bên trong** lại là
chuyện khác và có lỗi thật, do agent skill-logic-5 phát hiện bằng đo sống:

```
runtime_adapter.lua:77  assert -> "missing selected impact 60958"
   <- native.interval_167 <- std_impact_081.heart_beat   ... lặp MỖI 3 GIÂY, MÃI MÃI
```

Nặng hơn bình thường vì buff 战可得威 có `总持续时间 = -1` (vĩnh viễn): nó **lưu xuống Mongo** và
sống lại mỗi lần đăng nhập, nên nhân vật lỡ dùng 3816 là tự đầu độc cho tới khi xoá tay `impact_list`.

### 6.1 Bằng chứng

| | giá trị |
|---|---|
| impact SỐNG trên nhân vật | `data_index 45184`, `logic_id 8167`, params 4554/4556/4557/4559 |
| `configs/StandardImpact.txt` dòng 45184 | 战可得威, 逻辑ID 8167, params **3000, 4555…4559, 4550…4554** |
| `native_config.impacts[45184].params` | 3000, **60958…60962, 60953…60957** |
| dòng 60950–60965 trong bảng | **KHÔNG CÓ DÒNG NÀO** |
| dòng 4550–4559 trong bảng | **CÓ ĐỦ 10 DÒNG** (`战可得威(会心提升)`, 逻辑ID 8162) |

Tức bộ sinh `native_config` đã phân giải các ô "ID hiệu ứng" sang ID của client donor (lệch +56403),
trong khi server này dùng `resolve = đồng nhất`. **Lời cảnh báo "params đã phân giải sang ID native,
đừng dựng lại từ bảng" (ghi trong `cyfour_map.py` và `impact-data_vi.md`) là SAI với server ta ở
đúng lớp ô này.**

### 6.2 Đã sửa: `Tools/server/cyfour_params.py plan | apply | verify`

Luật sửa — chỉ đổi một ô khi **cả ba** đúng, kiểm trên bảng SỐNG:

1. ô đó là ô **ID hiệu ứng** (nhãn có `效果`);
2. giá trị native **không** có dòng trong `StandardImpact`;
3. giá trị của bảng **có** dòng trong `StandardImpact`.
Thêm: bỏ mọi ô ≤ 1000 (tham số số học như `回调时间`, `修正率`).

Kết quả `apply` (sao lưu `backups/cyfour-params-20260917T083711Z/`):

```
so_o_sua 282 | so_muc_sua 29 | kiem_lai true        verify: so_o_sua 0, ok true
29 mục = 4465…4476 + 45181…45196 (logic 167) + 13320 (logic 180)
loadfile OK, impacts vẫn 396 mục, 45184.params[2]: 60958 -> 4555
```

### 6.3 CỐ Ý KHÔNG SỬA — 23 ô (đọc trước khi ai đó "sửa nốt")

- **11 ô logic 171** (13262/13263/49941/49943, nhãn `初始技能`/`替换技能`): đó là **ID KỸ NĂNG**,
  không phải impact. 3840/3846/3847/3851 có mặt trong `StandardImpact` chỉ là TRÙNG DẢI ngẫu nhiên —
  sửa theo bảng sẽ trỏ sai hẳn. (13262/13263 hiện còn nằm trong `disabled_impacts`.)
- **12 ô logic 99** (13305–13316, nhãn `纪录陷阱的buffID`, 61032 → 9): native không tồn tại thật,
  nhưng giá trị bảng ≤ 1000 nên ngoài luật. **Việc còn mở cho người phụ trách trap.** Các ô lệch
  khác của cùng khối (2088↔1110, 505↔35) là ánh xạ **CỐ Ý** của đợt trap-recollide — native đúng,
  bảng là bản GL cũ; đừng "sửa" chúng.

### 6.4 Giữ nguyên `assert` ở `runtime_adapter.lua:77`

Đã cân nhắc bỏ `assert` cho êm. **Quyết định: giữ.** Chính cái assert ồn ào đó đã phơi ra lỗi dữ
liệu này; bỏ nó đi thì lần sau lỗi cùng lớp sẽ im lặng trỏ sai hiệu ứng. Cái cần sửa là DỮ LIỆU,
và đã sửa. (Đã kiểm: không nhân vật test nào còn `impact_list` dính 4465–4476/45181–45196.)

### 6.5 Có hiệu lực khi nào

`native_config.lua` là Lua nạp lúc khởi động ⇒ **phải restart server**. Sau restart, phép đo dứt
điểm là 3816 战可得威 (phái 13) và 4465/4466 万箭齐发·裂羽/铩羽 (phái 11) — ba chiêu này nằm trong
nhóm `khong_tac_dung` còn lại.

## 7. BẪY BẢNG: nhãn cột lệch một ô

Khi đọc `参数N说明` của `StandardImpact.txt`, đừng tin cột `说明` của chính ô đó. Nhiều dòng bị
**lệch một cột**: nhãn của ô k nằm ở cột `修正步长` của ô k−1, còn cột `说明` của ô k thì RỖNG.

Dòng 45184 chẳng hạn: ô1 `说明`=`回调时间`, ô1 `修正步长`=`给自己的效果1`, ô2 `说明`=rỗng, ô2 值=4555.

Bản đầu của `cyfour_params.py` dùng đúng cột `说明` nên **bỏ sót chính ô 60958** — ô gây ra assert.
Cách đúng: nhãn = cột ngay trước GHÉP với cột `说明` của ô đó (xem hàm `cell()`).
