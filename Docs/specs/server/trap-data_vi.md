# Dữ liệu "bẫy" (SpecialObjData) — khoảng trống giữa CY và server riêng

*17/09/2026 — phiên điều phối (hệ kỹ năng). Chỉ đọc, chưa sửa bảng nào.*
Bằng chứng: `Build\Logs\2026-09-17-skill-system\10-trap-gap.tsv` + `.json`, dựng lại bằng
`python -X utf8 -B Build\Logs\2026-09-17-skill-system\scripts\10-trap-gap.py`.

## 0. Vì sao có mục này

Trong các logic kỹ năng CY còn ở mức `partial` (xem `skill-logic_vi.md` mục 3 và `Timeline\handoff\skill-logic.md`),
một nhóm lớn **không thiếu mã** mà **thiếu dòng dữ liệu bẫy**: `三阳开泰` (大理 462, logic 202),
`借东风` (鬼谷 3448, logic 767), `万箭齐发` (唐门 2901, logic 736), `勒马归鞍` (桃花岛 3804, logic 795)…
Cả bốn đều trỏ tới một ID trong bảng `SpecialObjData.txt`; ID đó trên server riêng **không có** hoặc **là đồ vật khác**.

Đây đúng là lớp lỗi mà `impact-data` đã gặp với `StandardImpact`: bảng dữ liệu của server là nhánh **GL/HJ**,
còn `SkillData_V1` đang là **CY 3.71**, nên ID hai bên không dùng chung.

## 1. Số đo **[DK]**

| Mục | Số |
|---|---|
| ID bẫy được `SkillData_V1` tham chiếu (20 nhãn `参数说明` thật sự là ID bẫy) | **342** |
| Có trên server, **trùng tên** với CY → dùng được | 165 |
| Có trên server nhưng **tên khác** CY → kỹ năng CY kích hoạt nhầm đồ vật | **66** |
| **Không có** trên server | **111** |
| Có trong bảng CY (`DataCY31-08-26\Config\SpecialObjData.txt`) | **342/342** |
| Impact mà các dòng bẫy CY trỏ tới nhưng server **chưa có dòng** | **94** |
| Số dòng bảng: server 1.352 — CY 1.843 | |

Trong 111 dòng thiếu, chỉ **2** dòng (`1853 猛虎下山预警`, `2187 鬼谷陨石预警`) không cần impact nào.
**109 dòng còn lại vô dụng nếu chỉ chép dòng bẫy**: bẫy nổ nhưng `init_impact_from_data` trả false vì thiếu dòng impact.

Ví dụ đã tra tay:

| Bẫy | CY | Trên server | Impact của bẫy | Kỹ năng dùng |
|---|---|---|---|---|
| 752 | 三阳开泰 | **không có** | 56821 — **thiếu** | 大理 462 三阳开泰 (logic 202, ô `引导周期释放陷阱`) |
| 2188–2192 | 借东风伤害1…5 | **không có** | 59194–59198 — **thiếu** | 鬼谷 3448 借东风 (logic 767, ô `N队友伤害陷阱`) |
| 1450 | 傀儡残影 | có, nhưng là `步步生花（110-119）` | — | 桃花岛 3804 勒马归鞍 (logic 795) |
| 1980 | 万箭齐发 | có, nhưng là `防守玩法BOSS4-2技能1简单` | — | 唐门 2901 万箭齐发 (logic 736, ô `溅射效果陷阱id`) |

## 2. Bố cục hai bảng (đã đối chiếu từng cột) **[DK]**

- Cột 0–24 **giống hệt** nhau (ID, tên, ToolTips, 类别, 逻辑ID, 隐形级别, 陷阱专用标记, 可激活次数, đặc hiệu/âm hiệu,
  子弹ID, 持续时间, 激活或触发时间间隔, 触发半径, 影响半径, 影响个体数目…).
- Server có **64 cột**: 25–30 là `预留`/`预留新增` (INT, mọi dòng đang là `0`), 31–62 là **16 cặp** `参数说明`/`参数值`,
  63 là `详细说明(内部使用)` (rỗng ở mọi dòng mẫu đã xem).
- CY có **63 cột**: từ 25 là **19 cặp** `参数说明`/`参数值`, không có cột 63.
- ⇒ Ánh xạ khi nhập: `0–24` chép thẳng; `25–30` = `0`; cặp tham số CY (từ cột 25) đổ vào cặp của server (từ cột 31);
  cột 63 để rỗng. Bảng CY **không có dòng tên cột** (hai dòng đầu đều là dòng kiểu) — lấy tên cột từ bảng server.
- Bảng server đọc bằng `txtreader` nên **PHẢI giữ GBK** (bẫy chung của mọi bảng text server).

Khoá mà `services/scene/special_obj/trap.lua` đọc từ `descriptor`: `效果1`, `效果2`, `效果3`, `效果3几率`, `效果4`
(`cfghelper:read_special_obj_data` đổ mọi cặp `参数说明`/`参数值` vào `descriptor`).
`obj_special.get_data_record()` có `assert(data_record, self.data_id)` ⇒ **tạo bẫy với ID không có trong bảng sẽ ném lỗi**,
chứ không im lặng. Vì vậy `skill_cy_spec` hiện chỉ đặt bẫy cho các ô đã biết chắc có dòng.

## 3. ĐÃ LÀM 17/09 — nhập 111 dòng bẫy + ca chứng minh 三阳开泰 **[DK]**

Server riêng `06a86ea` (sau `e8750b3`). Sao lưu: `backups/trap-data-20260917T015331Z`, `backups/trap-impacts-20260917T015818Z`.

| Bước | Công cụ | Kết quả |
|---|---|---|
| Nhập dòng bẫy | `Tools\server\trap_data.py plan\|apply\|verify` | `SpecialObjData.txt` **1.352 → 1.463** dòng (thêm 111, 0 dòng cũ đổi, GBK, 64 cột); `verify`: `still_missing = 0`, `errors = []` |
| Bù impact của bẫy | `Tools\server\trap_impacts.py plan\|apply\|verify` | `StandardImpact.txt` **27.694 → 27.710** (thêm 16), `impact_data.py verify` vẫn `errors = []`, `cyfour_unmapped = 0` |
| Kiểm live | `menpai_check.ps1 -MenpaiList 6 -SkillList 462` | 大理 462 三阳开泰: **6 đòn sát thương (6 nhịp dẫn × tối đa 4 mục tiêu), giết quái, 0 traceback** → "không tác dụng" **→ "chạy"** |

**Bằng chứng nhân quả (không phải suy đoán).** Log phiên 16/09 của chính chiêu 462
(`Build\Logs\2026-09-16-menpai-verify\full\live\m6\s462-141246-a1-serverlog.txt`) có đúng 6 dòng
`[skill_cy_spec] tao bay loi 752 752` — tức logic 202 đã cài và đã gọi đặt bẫy, nhưng `obj_special:init_from_data`
`assert(data, self.data_id)` ném vì **thiếu dòng 752**. Sau khi nhập dòng: log phiên 17/09 09:00 không còn dòng đó,
có 6 lần bẫy trúng mục tiêu (`combat.json`: `dmg_hits = 6`, `dmg_list = [18,18,18,18,18,18]`, 6 obj khác nhau).

**Luật bù impact (nối tiếp luật `hj` của impact-data, chỉ khác đường đi):**
`kỹ năng CY → ô nhãn bẫy → bẫy T (bảng CY) → 效果N = impact I (thiếu)`, rồi tìm
`kỹ năng HJ cùng TÊN + PHÁI + CẤP → ô impact J` đã có dòng trên server → **chép nguyên dòng J sang ID I**.
Chỉ nhận khi HJ cho đúng một giá trị ở cấp đó, và **một dòng mẫu không được dùng cho hai hiệu ứng của cùng một bẫy**
(bẫy CY có `效果1`/`效果2` riêng, HJ chỉ có một ô → bỏ cả cụm; đã loại 53394/53423 của 天山 阳关三叠 vì lý do này).

**Kiểm chéo số của 16 dòng đã bù:** `参数值` và `修正步长` của từng cấp trùng khít từng con số `{A:… B:49.6153846153846}`
trong tip CY của đúng cấp đó (870/1515/2145/2790/…/10455) — nên đây là bản sao **đúng số**, không phải xấp xỉ.

**Còn lại:** 78/94 impact của bẫy chưa có nguồn (HJ không có kỹ năng đó — phần lớn là chiêu CY mới: 唐门 霹雳锁,
鬼谷 借东风 59194–59198, 星宿 罂毒歌…). Đường đi tiếp: dựng theo tip bằng dòng **logic 115** cho các hiệu ứng
"N % đòn đánh thường" (xem mục 4.2). 66 ID va chạm vẫn **không đụng**.
Ghi chú: `trap.lua` từng ghi một dòng log cho **mỗi** mục tiêu trúng bẫy (`[TRAP] register_skill_hit_event`) — đã tắt
ở `06a86ea` vì sau khi bật bẫy thật, log Game2 bị lấp đầy.

## 4. Việc cho lượt sau (theo thứ tự)

1. **Nhập 111 dòng thiếu từ bảng CY** (chỉ thêm, không đổi dòng cũ) — công cụ mới `Tools\server\trap_data.py plan|apply|verify`
   theo đúng khuôn `impact_data.py`: sao lưu, idempotent, verify đếm dòng + so hash dòng cũ + kiểm GBK.
2. **Bù 94 dòng impact** mà bẫy CY trỏ tới. Đã kiểm: **0/94** ID có tên trong `GMVisible_Impact.txt` của client CY
   (bảng đó chỉ có 1.149 impact "GM nhìn thấy"), nên luật `gmname` của `impact_data.py` **không dùng được** ở đây.
   Đường khả thi là dựng theo **tip kỹ năng**: phần lớn hiệu ứng bẫy là "gây N % sát thương đòn đánh thường",
   đúng khuôn **dòng `逻辑ID = 115`** mà `skill-logic` đã port (`std_impact_115.lua`, `伤害量缩放系数`).
   Ví dụ 借东风: tip "对落地点附近5米内最多6名敌对目标造成80%普攻伤害，每多移动1名队友伤害增加20%"
   ⇒ 5 dòng 59194–59198 = hệ số 80/100/120/140/160. Ngược lại, 三阳开泰 (56821) là ô "内外功攻击增加{A/B}点"
   (buff theo cấp), không thuộc khuôn 115 — phải tra riêng.
   Không có nguồn CY thật cho `StandardImpact` (đã chứng minh ở `impact-data_vi.md`), nên mọi dòng vẫn là bản dựng.
3. **66 ID va chạm**: kỹ năng CY đang trỏ vào đồ vật khác của GL/HJ. Không đổi dòng cũ; cách an toàn là cấp ID mới
   cho bản CY rồi sửa ô `参数值` của `SkillData_V1` — phải làm cùng lượt với `impact-data`, vì đổi ID kéo theo cả bảng khác.
4. Sau khi có dữ liệu: bật lại các ô `trap` trong `cy_skill_logic_spec.lua` cho logic 202/736/767/795 và đo live.

## 5. KẾ HOẠCH 66 ID VA CHẠM — 17/09/2026, agent `trap-collide` (chỉ đọc, chưa áp)

Kế hoạch đầy đủ: **`Build\Logs\2026-09-17-trap-collide\README_vi.md`**
(kèm `plan.tsv` 1 dòng/1 ID, `skilldata-cells.tsv` 213 ô chính xác, `scripts\10…20…30…py` để dựng lại).
Mục 4.3 ở trên ("66 ID va chạm") **được thay bằng kế hoạch này**. Mốc đo: server riêng **`f71eeb5`**
(ngay sau `06a86ea`), cây sạch; `SpecialObjData.txt` (`031a2e28…`) và `SkillData_V1.txt` (`01fb9585…`)
vẫn y nguyên từ `06a86ea`, chưa đụng.

**Chốt phương án** (ảnh chụp 17/09 ~09:45): **(a) cấp ID mới 65** → dải **3000–3064**, 213 ô `SkillData_V1`
(119 dòng, 8 nhãn); **(b) giữ nguyên 0**; **(c) không đụng 1** (`1750` — impact CY `46907` đã có trên server nhưng là
`玄龟（没加脚本啊）` logic 97, cấp ID mới chỉ đổi cái sai này lấy cái sai khác).

> Luật (b) là: 9/9 cột cơ chế trùng khít **và** cả hai bộ `效果N` đều chưa có dòng. Sáu ứng viên duy nhất
> (`1867, 1868, 1875` ↔ `荡千军`; `1872–1874` ↔ `棹歌中流`) đã chuyển sang (a) ngay trong lượt này, vì agent
> `trap-impacts` vừa dựng đúng impact **phía CY** (`56419 荡千军（直接伤血）`, `56413–56415 棹歌中流` logic 115…)
> trong khi impact phía server (`51313–51315, 51319, 51320, 51476, 51477`) vẫn chưa có.
> ⇒ **Trạng thái impact là biến động**: chạy lại `scripts\20-collide-features.py` + `30-build-plan.py`
> ngay trước khi áp. Ánh xạ ID và danh sách ô `SkillData` thì ổn định.

**Bốn dữ kiện sửa/bổ sung cho mục 1–4 ở trên:**

1. **ID lớn nhất của bảng server là 2.347** (không phải 2.102) sau đợt nhập 111 dòng; CY là 2.350. Dải mới phải trên 2.350.
2. **`StandardImpact.txt` cũng chứa ID bẫy** — qua cặp `参数N说明`/`参数值` (khác `参数说明` nên bộ lọc của
   `10-trap-gap.py` bỏ sót). Dòng **13305–13316 `傀儡香`** trỏ tới bẫy **1110–1121** và chuỗi còn sống:
   `tpl 396 宙耀七星 (武当) c3–15 → SkillData 1639–1651 → SI 5163–5174 魂离魄散2 (ô 三魂) → SI 13305–13316 → bẫy 1110–1121`.
   ⇒ 16 dòng `1110–1125` **không được ghi đè**. 54/66 dòng cũ còn lại hiện không ai dùng, **0/66** có tham chiếu Lua
   (đã quét 5.365 file `.lua` của `GameServer` + `Game_2/Script`).
3. **Hai nhãn bẫy còn thiếu trong `TRAP_LABELS`**: `引导节点的陷阱ID`, `增强的陷阱ID` (trỏ `1079/1080/1081`,
   không va chạm). Các nhãn có chữ `陷阱` nhưng **không** phải ID bẫy: `同类陷阱数目上限`, `纪录陷阱的buffID`,
   `陷阱半径`, `随机生成生成陷阱N的半径`, `个体拥有这些buff…时使用强化陷阱N`, `效果或陷阱的时间(值|%)修正`.
4. **`是否即刻生效一次` chưa được cài** (0 chỗ đọc trong toàn bộ Lua) và `impactenginer:send_impact_to_unit`
   với ID impact thiếu **trả `false`, không ném** — nên "bẫy trỏ impact thiếu" là trơ, khác hẳn "thiếu dòng bẫy"
   (`obj_special:init_from_data` và `skill_260:specific_condition_check` đều `assert`).

**Ràng buộc bắt buộc khi áp (a):** bảng bẫy phía **client** cũng phải nhận 65 dòng mới.
Client CY-Source đọc `Assets\CanonicalCY\Data\ConfigFolder\SpecialObjData.txt` (DBC `00CCBBDD`, 63 cột, 1.843 dòng);
`生存期持续特效`/`激发特效`/`死亡特效`/`子弹ID` là dữ liệu client. Ở **ID cũ** client CY đang hiện **đúng** hiệu ứng CY,
nên đổi sang ID ≥ 3000 mà không thêm dòng client = **mất hiệu ứng nhìn thấy** (không crash:
`Src\Client\WXClient\Object\Surface\Obj_Special.cpp` bọc `GetSpecialObjData() != NULL` ở mọi chỗ dùng).

**Thứ tự áp đề nghị:** ① 20 ID **sai → đúng ngay** (`1110–1125` + `1811, 1812, 1816, 1817`) — đang bắn hiệu ứng
sai thật (`桃花阵减血`, `大风歌（僵硬）`) mà impact CY đã có, đúng tên (`霹雳锁（CY推导麻痹）`, `阳关三叠（加会心）`);
② 24 ID trơ + impact CY đúng (`1797, 1799, 1800, 1804–1810, 1813–1815, 1818, 1819, 1863–1865, 1867, 1868, 1872–1875`);
③ `1450, 1451, 1980` — dòng CY không có ô hiệu ứng, chỉ bỏ vật thể sai, gỡ đúng hai ca `勒马归鞍` + `万箭齐发` của mục 1;
④ `1133, 1149` (sai → trơ, chờ `38550`/`54917`); ⑤ `1820–1835` (chờ `53394`/`53423`); ⑥ `1750` chờ tầng impact.
Hoàn tác: `git checkout -- configs/SpecialObjData.txt configs/SkillData_V1.txt` — chỉ đụng đúng hai file này,
**không** `git checkout .` / `git stash` (các agent khác làm việc trên cùng cây), hoặc bản sao `R/backups/trap-collide-<UTC>/`.

**Công cụ:** viết mới `Tools\server\trap_collide.py` (`plan|apply|verify`) — **không** sửa `trap_data.py`/`trap_impacts.py`.

## 6. ĐÃ LÀM 17/09 — bù **97 dòng** StandardImpact (bẫy + triệu hồi + 5 chiêu), agent `trap-impacts` **[DK]**

Tiếp mục 3 và mục 4 #2. Sau lượt `hj` của người điều phối còn **78** ID impact mà bẫy CY trỏ tới nhưng
`StandardImpact` chưa có dòng. Lượt này bù **71** (còn 7), cộng **1** ô ngoài bẫy do `skill-summon` báo (mục 6.7).
Đợt 3 (mục 6.8) thêm **25** dòng cho 5 chiêu đang "gửi chiêu không tác dụng".
Bảng `configs/StandardImpact.txt` **27.710 → 27.781 → 27.782 → 27.807** (thêm **97** tổng cộng, **0 dòng cũ bị đổi**).
Server riêng: 71 dòng đầu đã vào commit **`f71eeb5`**; dòng `37922` của mục 6.7 **chưa commit**.
Sao lưu: `R/backups/trap-impacts-20260917T023828Z/` (trước 71 dòng) và `…T025655Z/` (trước dòng 37922).
Bằng chứng: `Build\Logs\2026-09-17-trap-impacts\` (`scripts\01..07`, `10-trap-impacts-final.tsv`, `10-plan-final.json`,
`11-summon-extra.tsv`, `11-summon-extra-plan.json`, `verify-trapimpacts-3.json`, `verify-impactdata-3.json`,
`si-verify-after3.json`, `05-coverage.tsv`, `06-summon.txt`, `07-summon-donor.txt`).

### 6.1 Hai luật mới (`Tools\server\trap_impacts.py`, giữ `plan|apply|verify`)

| Luật | Dòng | Cách dựng | Dòng mẫu |
|---|---|---|---|
| `pct115` | **14** | tip CY ghi "造成N%普通攻击/普攻伤害" ⇒ dòng `逻辑ID = 115`, `伤害量缩放系数 = N` — đúng khuôn `impact_data.py scale` (`impact-data_vi.md` mục 6.3) | `43918 撼岳群攻效果` |
| `copy` | **57** | chép NGUYÊN một dòng thật cùng kỹ năng / cùng vai trò, chỉ đổi `Data_Index` (+ tên, + `总持续时间`/`参数值` khi tip cho đúng một con số cho đúng nhãn ấy) | 11 dòng mẫu, **tất cả đều có ở mốc `6ca25a8`** (trước khi impact-data thêm gì) |
| `extra` | **1** | như `copy`, cho ô **không đi qua bẫy** do agent khác báo (mục 6.7) | `43847` |

Bẫy gọi `impactenginer:send_impact_to_unit(muc_tieu, 效果N, owner, …)` (`services/scene/special_obj/trap.lua`)
nên `caster` của impact là **chủ bẫy** ⇒ `std_impact_115` tra được người gây và dựng được đòn đánh thường. [DK]

**Mỗi mục trong các bảng `SCALE_CELLS`/`COPY_CELLS`/`EXTRA_CELLS` khai báo bằng chứng và công cụ tự kiểm lại
trên bảng sống**: chuỗi phải có trong tip của kỹ năng dẫn tới ID đó; `参数值`/`总持续时间` của dòng mẫu phải đúng
như khai; ô `强化陷阱1/2` của SkillData phải khớp; `效果N` của bẫy CY đối chứng phải đúng bằng dòng mẫu.
Sai một điều kiện ⇒ mục đó bị **bỏ** và ghi lý do vào TSV, **không âm thầm sinh dòng**.

### 6.2 Chi tiết 71 dòng của bẫy **[DK `10-trap-impacts-final.tsv`]**

| Kỹ năng (template) | ID | Luật | Nguồn / bằng chứng |
|---|---|---|---|
| 鬼谷 借东风 3448 | 59194–59198 | `pct115` | tip "对落地点附近5米内最多6名敌对目标造成**80%**普攻伤害，每多移动1名队友伤害增加**20%**" ⇒ 80/100/120/140/160 theo ô `1…5队友伤害陷阱` |
| 星宿 蝎行无阻 841/844/847 | 59757/59758/59759 | `pct115` | ba giai đoạn 巨蝎: tip từng template ghi **80 % / 90 % / 100 %** phổ công |
| 星宿 蝎行无阻 (效果2, 16 cấp) | 59760–59775 | `copy` | mẫu `5362 目眩神迷眩晕`, `总持续时间` 1.000 → **2.000 ms** (tip "并使其眩晕2秒") |
| 棹歌中流 5238 / 5520 | 52904 / 56413–56415 | `pct115` | "每秒造成N%普通攻击伤害": 100 / 50 (cấp 1–7), 100 (cấp 8), 150 (cấp 9–16) |
| 定海神针 5225 | 52882 | `pct115` | "每2秒对目标造成**50%**普通攻击伤害" |
| 荡千军 5240 | 52907 | `pct115` | "造成**200%**普通攻击伤害" |
| 荡千军 5523 / 5844 | 56419, 58609 | `copy` | mẫu **`4626 荡千军（直接伤血）`** `伤害数值+ = 100` — trùng khít tip "造成**100点**直接伤害" |
| 荡千军 5523 (麻痹) | 56420, 56676, 56677 | `copy` | mẫu **`4808 荡千军(麻痹)`**, `总持续时间` 2.000 → **1.000 ms** (tip "1秒麻痹") |
| 荡千军 5844 (麻痹) | 58611 | `copy` | mẫu `4808` — đã đúng **2.000 ms** (tip "2秒麻痹"), **không đổi số nào** |
| 八阵图 5594 (sát thương) | 56713/56714/56715 | `copy` | mẫu **`2512`/`2515`/`2518 八阵图减血`** `伤害数值+` = **136/421/706**, trùng khít ba con số trong tip ba cấp |
| 八阵图 5594 (散功) | 56716/56717/56718 | `copy` | mẫu **`2683 八阵图(散功)`** (CanAction2 = 0, CanMove = 1 ↔ tip "散功状态下可以移动，但无法使用技能"), `总持续时间` 6.000 → **2.000/3.000/4.000** |
| 唐门 霹雳锁 2921 + tpl 797 (16 cấp) | 37800–37815 | `copy` | mẫu `63003 扣冰麻痹` — đã đúng **500 ms** (tip "每2秒受到**0.5秒**的麻痹效果"), không đổi số nào |
| 星宿 罂毒歌 2263 (封穴) | 32666 | `copy` | mẫu `13514 含笑半步癫(封穴)` **1.000 ms** ↔ tip "使目标封穴1秒"; bẫy 1068 lấy `激发特效 = m01_xx_含笑半步癫进阶_01` (cùng họ, cùng phái 星宿) |
| 阳关三叠 5854 (会心) | 58688–58693 | `copy` | sáu bẫy 会心 2178–2183 nối tiếp ↔ **cấp 7–12 của 天山 阳关三叠 510**: dãy % trong tip khớp từng cấp (6/6/7/7/8/8) và bẫy 会心 1810–1815 của tpl 510 trỏ đúng `2426`–`2431 阳关三叠（加会心）` |
| 定海神针 951 (phó bản 80) | 19575–19579 | `copy` | SkillData của tpl 951 mang **đúng cặp `强化陷阱1/强化陷阱2`** của cấp 8–12 tpl 544 (374/390 … 378/394) và bẫy 1057–1061 cùng hồ sơ với 358–362 ⇒ chép `29959`–`29963 定海神针减血` |
| 逍遥 定海神针 544 (命中陷阱) | 21687 | `copy` | mẫu `53273 四海归心` (logic 162, `命中修正率`, 5 s), đặt `命中修正率` = **10** theo tip "提升**10%**命中率" (`<X>修正率` là phần trăm — `impact-data_vi.md` mục 6.0) |

Ba chỗ số **trùng khít** giữa tip CY và dòng thật (không phải xấp xỉ): 八阵图 **136/421/706** = `参数值` của
`2512/2515/2518`; 荡千军 **100 điểm** = `参数值` của `4626`; 荡千军 **麻痹 2 s** = `总持续时间` của `4808`.
Đó là bằng chứng mạnh nhất cho thấy CY giữ nguyên số của nhánh cũ ở các chiêu này.

### 6.3 Còn lại **7 ID của bẫy** — lý do, không bịa **[DK `10-plan-final.json` trường `skipped_why`]**

| ID | Kỹ năng | Vì sao chưa dựng |
|---|---|---|
| 53394, 53423 (tpl 510 天山) và 58694, 58695 (tpl 5854) | 阳关三叠 — vùng 冰雾 | Bẫy 1820–1835 / 2172–2177 có **hai** ô hiệu ứng nhưng tip chỉ mô tả **một** kết quả ("处于冰雾内最多6名敌方目标**无法使用位移类技能**") ⇒ không biết ô nào là ô nào. Cơ chế khả dĩ: logic 14 với `参数10 允许还是禁止 = 0` + `参数11 技能集合ID` = tập kỹ năng vị di — **chưa tìm được tập đó**: mọi dòng logic 14 đang dùng `技能集合ID` chỉ có 64 (hồi thành/ẩn thân/cưỡi) và 286 (寻影). Bản HJ của 阳关三叠 chỉ có **một** ô impact (`2420 加会心`), tức vùng 冰雾 là **cơ chế CY mới** |
| 32665 (tpl 2263 星宿) | 罂毒歌 — `效果1` | Tip ghi "每隔2秒产生**大量伤害**" — **không có con số**. `效果2` (封穴 1 s) đã bù |
| 38550 (tpl 3000), 54917 (tpl 5714) | 玄雷天降 | Kỹ năng BOSS (`boss_赤帝_…`, `boss_玄击神将_…`); tip chỉ ghi "玄击神将技能" / "玄雷天降" — không mô tả hiệu ứng nào |

### 6.4 Kiểm sau khi áp **[DK]**

| Phép kiểm | Kết quả |
|---|---|
| `trap_impacts.py verify` | `rows = 27.782`, `changed = **0**`, `errors = []`, `cyfour_unmapped = **0**`, `trap_impact_still_missing = 7`, `extra_still_missing = [37920]` |
| `impact_data.py verify` | `changed = 0`, `errors = []`, `cyfour_unmapped = **0**`, `warnings = []`; `refs_missing_ids` 1.457 → **1.456** |
| `server_impact.py verify` (không lùi) | `ok = true`, 0 lỗi, bảng **27.782×81**, 0 tab lỗi, 0 trùng, tăng dần; `se_not_in_cy_client = 0`; `logic_not_registered = []`; tham chiếu phân loại 92,95 % → **93,015 %**; `luac5.4 -p` 25/25; `server_impact_tests.lua` **19/19 đạt** |
| Chạy lại `plan` sau khi áp | `added = 0`, file sinh ra **trùng sha** với bảng trên server ⇒ idempotent |
| Logic của 72 dòng mới | 1, 14, 115, 123, 162 — **tất cả đã cài module** trong `impactenginer.lua`; **không dòng nào ≥ 8000** nên không đụng `cy_four_combat/native_config.lua` |

### 6.5 Kỹ năng nay có bẫy chạy ĐỦ (đáng đo live) **[DK `05-coverage.tsv`]**

16 template chuyển từ "thiếu impact" sang **đủ** (mọi `效果N` của mọi bẫy nó đặt đều có dòng).
Trong đó thuộc 15 phái: **544 定海神针 (逍遥)**, **797 霹雳锁 (phái 10)**, **2921 霹雳锁 (唐门)**,
**841 / 844 / 847 蝎行无阻 (星宿)**, **3448 借东风 (鬼谷)**.
Phái −1 (phó bản / BOSS / bản nâng): 951 + 5225 定海神针, 5238 + 5520 棹歌中流, 5240 + 5523 + 5844 荡千军,
5594 八阵图, 2934 蛛丝缠足.
Còn "thiếu": 510 + 5854 阳关三叠 (冰雾), 2263 罂毒歌 (`效果1`), 3000 + 5714 玄雷天降.

### 6.6 BẪY của lượt này **[DK]**

- **Không có "anh em cùng ô"**: `02-series.tsv` cho thấy **0/392** ô bẫy có cấp khác đã có dòng ⇒ luật `series`
  của impact-data **không dùng được** ở đây. Mọi cụm bẫy CY đều thiếu trọn bộ.
- **Dòng logic 14 điều khiển bằng `参数值`, không bằng tên**: `std_impact_014` đọc `可否使用任何技能(CanAction1/2)`
  và `可否移动(CanMove)`; `-1` = **vô hiệu**, `0` = cấm, `1` = cho phép. Đã kiểm từng dòng mẫu:
  眩晕/麻痹/封穴 = `0/0/0` (khoá hẳn), 散功 = `1/0/1` (đi được, không dùng chiêu được), 定身 = `1/1/0`.
  Chọn dòng mẫu **chỉ theo tên là chưa đủ** — một dòng tên "眩晕" mà ba ô đều `-1` thì không khống chế gì cả.
- **ID bẫy va chạm giữa hai nhánh**: bẫy `2088` của server (GL) là `霹雳锁` nhưng bẫy `2088` của bảng CY là `回血符`.
  Đừng tra dòng mẫu bằng ID bẫy của nhánh kia. Ngoài ra `霹雳锁` của GL trỏ impact `60931` — **cũng không có dòng**,
  nên đường "chép theo bẫy GL cùng tên" chết ở đây; phải quay về tip.
- **Bảng CY tự nó là nguồn tốt nhất tìm được**: nhiều bẫy CY cũ (401 `八阵图`, 358 `定海神针`, 1810 `阳关三叠会心`)
  trỏ đúng các ID **đang có** trên server ⇒ dùng chính bảng CY để bắc cầu "bẫy mới ↔ bẫy cũ cùng tên/cùng hồ sơ"
  là bằng chứng mạnh nhất của lượt này (11 dòng dựng theo cách đó).
- **`蛛丝缠足` (tpl 2934) dùng chung bẫy `1125` với `霹雳锁` cấp 16** nhưng tip của nó ghi "使目标定身2秒",
  còn tip 霹雳锁 ghi "0.5秒的麻痹". Dòng bẫy 1125 mang **tên `霹雳锁`**, và 37800–37814 (cấp 1–15) đều là 麻痹,
  nên `37815` được dựng theo 霹雳锁. Nếu sau này thấy 蛛丝缠足 "không định thân", đây là chỗ xem lại.
- **`21687` dùng chung `互斥ID = 53267` với 四海归心** (thừa hưởng từ dòng mẫu) ⇒ hai buff sẽ thay thế nhau.
  Đúng như thiết kế TLBB nhưng cần nhớ khi đo live.

### 6.7 Hai ô **ngoài bẫy** do `skill-summon` báo **[DK `07-summon-donor.txt`, `11-summon-extra.tsv`]**

Hai ô này nằm thẳng trong `SkillData_V1`, không đi qua `SpecialObjData`, nên luật bẫy ở trên không quét tới.
Công cụ có thêm bảng `EXTRA_CELLS` (dựng, cùng luật `copy`) và `EXTRA_DECLINED` (đã xét, cố ý không dựng).

| ID | Ô | Kết quả |
|---|---|---|
| **37922** | 唐门 诸葛神弩 4468, `无敌效果id` (16 cấp cùng một ID) | **ĐÃ BÙ** — mẫu `43847 溯回BUFF(宠物效果)`: `逻辑ID = 14`, `无敌否 = 1`, và CanAction1/CanAction2/CanMove đều `-1` (**vô hiệu ⇒ không khoá hành động**) nên cái nỏ vẫn bắn được trong lúc bất khả xâm phạm. Chỉ đổi `总持续时间` **2.000 → 3.000 ms** theo tip "神弩…**初始3秒无敌**". Vai trò khớp: đây là buff bất khả xâm phạm cho **thực thể triệu hồi**, mà `cy_skill_logic_spec[730].summon.self_impact` áp đúng lên cái nỏ chứ không lên người chơi |
| **37920** | 唐门 千机变 2922, `免疫控制buff` (16 cấp cùng một ID) | **KHÔNG DỰNG** — tip của cả 16 cấp **không có chữ `免疫` nào**, nên không biết miễn loại khống chế nào và bao lâu. Nặng hơn: `cy_skill_logic_spec[731]` áp ô này lên **người chơi** (`to = 'self'`), mà mọi dòng 免疫 có thật đều là "miễn tất cả" — `52 实物（免疫点穴僵硬等一切不良buff）` **vĩnh viễn** (`总持续时间 = -1`), `346–357 百无禁忌（全免疫）` **30 s** — hoặc miễn đúng hai loại khống chế không xác định được (`1091 神龙摆尾`, `1593 行屍走肉`, `1880 金石俱焚`, `2168 非枯非荣`). Chép bất kỳ dòng nào trong số đó ⇒ người chơi miễn khống chế vĩnh viễn hoặc 30 s — **sai và thành lỗ hổng**. Cần nguồn khác (bảng CY thật, hoặc tip của chiêu con) |

Ứng viên đã xét cho `37922` và vì sao bỏ: `50`/`112 攻击免疫+攻击不能` (CanAction2 = 0 ⇒ **cấm dùng kỹ năng**,
nỏ sẽ không bắn), `12234 横行无忌（无敌）` 1 s và `6795 神佑（无敌）` 10 s (đúng cơ chế nhưng là buff của **người chơi**,
phải sửa thời lượng nhiều hơn), `19659 无敌` / `10489 年兽无敌` (`总持续时间 = -1`, vĩnh viễn).
Mọi dòng mẫu nêu ở mục 6 đều **có mặt ở mốc `6ca25a8`**, tức là dòng gốc của bảng chứ không phải dòng do
`impact-data` sinh ra — đã kiểm bằng `git show 6ca25a8:configs/StandardImpact.txt`.

### 6.8 Đợt 3 — **25 dòng** cho 5 chiêu đang "gửi chiêu không tác dụng" **[DK `12-five-skills.tsv`]**

Người điều phối rà lại 24 chiêu còn "không tác dụng" trên **bảng sống** (`Build\Logs\2026-09-17-coord\80-con-lai.tsv`)
và giao 16 ID của 5 chiêu. Bù **10/16** ID đó, **cộng 15 ID anh em cùng ô mà bảng của điều phối không liệt kê**
(ô `附加伤害（逻辑3）` của 少商剑·刃影 có **một ID cho mỗi cấp**, không bù đủ 16 thì chỉ cấp 16 chạy)
⇒ tổng **25 dòng**. Bảng **27.782 → 27.807**, `changed = 0`. Sao lưu `R/backups/trap-impacts-20260917T033756Z/`.

Trước khi chọn, đọc `lualib/cy_skill_logic_spec.lua` để biết ô nào Lua **thật sự áp** (`impacts`/`gender`) và ô nào
đang `consume` (cố ý bỏ qua) — đây là thứ quyết định ô nào đáng bù trước [DK].

| Chiêu (template) | ID | Luật | Nguồn / bằng chứng |
|---|---|---|---|
| 鬼谷 **火烧连营 3441** (logic 769) | 59170–59176 (7) | `pct115` | tip "立即对目标造成**80%**普攻伤害…并对所有链接的目标造成伤害，**伤害依序递增20%**，最多链接**6名**目标" ⇒ chủ + 6 liên kết = 7 ô `主/二/三/四/五/六/七目标伤害` = **80/100/120/140/160/180/200**. Đúng khuôn đã dùng cho 借东风 |
| 大理 **少商剑·刃影 821** (logic 204) | 56851–56866 (16) | `copy` | mẫu là chính bộ **`1915`–`1926 少商剑`** của kỹ năng CHA (logic 3, **đang dùng** `火系攻击`, SE 6); chỉ chỉnh độ lớn theo `{A:… B:…}` trong tip của **đúng cấp đó**: `火系攻击` = 348/600/851/…/4121, `修正步长` = 18,36956522. Cấp 13–16 dùng mẫu cấp 12 (tlbb15 chỉ có 12 cấp) |
| 鬼谷 **请星入命 3457** (logic 770) | 59200 (1) | `copy` | ô `长生护盾`; ô anh em `护盾血量百分比 = **50**` trùng khít `施加者护体百分比 = **50**` của dòng thật `1467 延年益寿（护盾）` (logic 29, `伤害吸收率 = 100`, 10 s) ⇒ **chép nguyên, không đổi số nào** |
| 星宿 **神蝎百相 434** (logic 170) + 蝎行无阻 841/844 | 59721 (1) | `copy` | ô `免控buff`; tip "驱使巨蝎供自身骑乘，**持续10秒**…**不会受到部分控制效果**". Dòng thật mang đúng tên `免疫控制` **và** đúng **10.000 ms** là `13519 横扫乾坤（免疫控制）` (logic 17, `免疫级别 160`, tập `60 控制`/`52 破绽`/`53 虚弱`/`45 僵硬`/`5,6 HPDOT`) ⇒ chép nguyên |

**Lưu ý về `59721`:** dòng mẫu miễn **rộng hơn** chữ "部分控制" của tip (kèm 破绽/虚弱/僵硬/HPDOT). Đây là dòng
`免疫控制` duy nhất có thời lượng **đúng bằng** thời lượng cưỡi, nên chọn nó; bảng `IDCollections` **không có**
tập nào hẹp hơn chỉ gồm khống chế (`60 控制` luôn đi kèm 5 tập kia trong mọi dòng có thật) [DK]. Cần thu hẹp khi có nguồn.

**Bỏ 6/16 ID — lý do [DK `12-five-skills-plan.json` trường `skipped_why`]:**

| ID | Ô | Vì sao |
|---|---|---|
| 59168, 59169 | 火烧连营 `主目标连线` / `其它目标连线` | Hiệu ứng **dây nối** (visual), tip không mô tả. `cy_skill_logic_spec[769]` đang **`consume`** hai ô này (không áp) nên bù cũng không đổi hành vi. Mọi dòng "连线" có thật (`19652` logic 14, `42988`/`42989 阴阳无咎-玩家连线` logic 38) đều `总持续时间 = -1` (**vĩnh viễn**), chỉ dùng được khi logic tự gỡ dây — logic 769 chưa làm chuỗi lan nên chưa gỡ được |
| 59205 | 请星入命 `破军会心` | Tip không cho con số nào cho 破军星君; ô đang `consume` |
| 59700, 59703 | 神蝎百相 `变身男buff` / `变身女buff` | Cần **`变身ID` của 巨蝎** (nam và nữ) — không có nguồn. Mọi dòng `变身` có thật mang ID của model khác (`8430 神枢战甲`, `2060/2061/2003` lễ hội, `6934/6935` NPC); `MonsterAttrExTable` có 巨蝎 `11534/11535/11555` nhưng **chưa chứng minh được `变身ID` tra vào bảng đó**. Hơn nữa `std_impact_014:get_refix_model_id` hiện **không có chỗ nào gọi** trong `lualib/`+`services/` ⇒ có dòng cũng chưa biến thân được |
| 59879 | 圣蚕护身 `冰蚕buff` | Tip mô tả **cơ chế của con 冰蚕** (hút hiệu ứng xấu, tốn 12 % máu, tiến hoá) chứ không cho biết **bản thân buff** làm gì. Bảng chỉ có `冰蚕掌` (sát thương + giảm nội phòng), không phải trạng thái gắn 冰蚕 |

**Kiểm sau đợt 3 [DK `verify-trapimpacts-5.json`, `verify-impactdata-5.json`, `si-verify-after5.json`]:**
`trap_impacts.py verify` → `rows 27.807`, `added 25`, **`changed 0`**, **`errors []`**, **`cyfour_unmapped 0`**;
`impact_data.py verify` → `added 25`, `changed 0`, **`errors []`**, `cyfour_unmapped 0`;
`server_impact.py verify` → `ok true`, 0 lỗi, **27.807×81**, `se_not_in_cy_client 0`, `logic_not_registered []`,
tham chiếu phân loại **93,148 %**, luac 25/25, test Lua **19/19**.
Logic của 25 dòng mới: 3 (×16), 17 (×1), 29 (×1), 115 (×7) — đều đã cài, không dòng nào ≥ 8000.

**Đáng đo live sau đợt 3** (kèm danh sách mục 6.5): 鬼谷 **3441 火烧连营** (đòn đầu 80 % phổ công lên mục tiêu —
`cy_skill_logic_spec[769]` mới chỉ áp `主目标伤害`, chuỗi lan 2–7 vẫn chưa làm), 大理 **821 少商剑·刃影**
(6 phi kiếm gây sát thương hoả), 鬼谷 **3457 请星入命** (khiên 50 % máu lên bản thân),
星宿 **434 神蝎百相** (chỉ buff miễn khống — **chưa biến thân**, xem bảng bỏ ở trên).


### 6.9 Đợt 4 — va chạm ID **impact** (96 ô) + 刀域 `2102`, công cụ mới `impact_recollide.py` **[DK]**

Hai việc dữ liệu, **không đụng `StandardImpact`**: sửa `configs/SkillData_V1.txt` và `configs/SpecialObjData.txt`.
Bằng chứng: `13-recollide.tsv`, `13-recollide-plan.json`, `verify-recollide-1.json`, `11-two-jobs.txt`.
Sao lưu: `R/backups/impact-recollide-20260917T060335Z/` (cả hai bảng).

#### (a) Lớp va chạm ID **impact** — 96 ô của 桃花岛 rơi vào khối 坐骑

Cùng loại lỗi `trap_recollide` đã gỡ ở tầng bẫy, lần này ở tầng `StandardImpact`: `SkillData_V1` đã là CY 3.71
nhưng `StandardImpact` là nhánh GL/HJ (agent `taohua-doll` truy ra). Đo lại trên bảng sống:
**96 ô / 36 ID phân biệt** của **3820 棹歌中流** và **3822 劝君酒**, và **96/96 ô** trỏ vào dòng mang
**`逻辑ID = 97` (坐骑)** — công cụ kiểm điều kiện này cho từng ô, ô nào không phải logic 97 thì **không đổi** [DK].

| Template | Nhãn ô | ID cũ (khối 坐骑) | Số ô |
|---|---|---|---|
| 3820 棹歌中流 | `生效一次的效果1(傀儡周围敌人)` | 45444 `红白凤` (chung 16 cấp) | 16 |
| 3820 | `生效一次给傀儡加效果` | 45443 `金翼鹤` + 45493–45508 (`七彩鹿`, `青牦牛`, `幻羽`…) theo cấp | 32 |
| 3822 劝君酒 | `生效一次的效果(目标)桃花岛苦昼短专用` | 45445–45460 (`白牦牛`, `白鹿`, `白雕`, `白狼`, `狮子`…) theo cấp | 16 |
| 3822 | `生效一次的效果(傀儡罩子)桃花岛苦昼短专用` | 45510 `火云邪兽` | 16 |
| 3822 | `生效一次的效果(傀儡连线)桃花岛苦昼短专用` | 45511 `玄天雷兽` | 16 |

Đã dời sang dải **64000–64035** (`Data_Index` lớn nhất của bảng là **63101** ⇒ dải trống; các con số 64xxx
tìm thấy ở `MonsterAttrExTable`/`Mission_KillMonster` thuộc **không gian ID khác**, không liên quan) [DK].
Ánh xạ từng ô: `13-recollide.tsv`. **Không đụng dòng 45443–45511** — khối 坐骑 đang được nội dung khác dùng.

**Khác `trap_recollide` ở một điểm quan trọng:** không có bảng `StandardImpact` của CY 3.71 (chứng minh ở
`impact-data_vi.md` mục 1.1) nên **ID mới chưa có dòng**. `impactenginer:init_impact_from_data` trả `false`
và logic kỹ năng bỏ qua ⇒ ô **hết tác dụng SAI** (trước đây gắn buff 坐骑 lên người chơi mà **không báo lỗi** —
số đo của người điều phối: `3822` trả `buffs_other = {19695: 1, …}`), và chờ ai đó dựng nội dung đúng ở ID mới.
Đây là **đánh đổi có chủ ý**: `refs_missing_ids` của `impact_data.py verify` **tăng 36** — đó là 36 chỗ trống
đã đăng ký, không phải hồi quy. Ô `生效一次的效果(目标)桃花岛劝君酒专用 = 45166 劝君酒（CY推导减速）` **không đụng**
vì không va chạm. Bảng client **không cần** đồng bộ (chỉ ID bẫy mới cần).

Nội dung đúng cho 36 ID **chưa dựng được** vì tip không cho số dùng được: ô `效果1` của 3820 phải là
**dòng logic 3** (ô anh em ghi rõ `对效果1伤害的修正，效果1必须用3号伤害类BUFF` = −5/0/+5/…/+50, cộng đúng với dãy
`95 %…150 %` trong tip) nhưng tip không cho `{A:… B:…}`; `暗伤标记` của 3822 là công thức động
("bỏ qua 会心防御 bằng 40 % 会心攻击 của mình, tối đa 80 % của mục tiêu"); `傀儡罩子`/`傀儡连线` không có số nào.

#### (b) `SpecialObjData 2102 荡千军刀域` — bù `效果1`/`效果2` **[DK]**

`skill_840` đặt bẫy này từ mốc gốc (log server riêng 17/09 11:31:48 `[skill_840] dao vuc 2102 obj= 367`)
nhưng dòng có `效果1..4 = -1` và `陷阱专用标记 = 0` ⇒ 刀域 chỉ là hiệu ứng nhìn.
Bù bằng **hai dòng có thật của chính kỹ năng**, trùng khít tip 绝情谷 4516 "造成**100点**直接伤害和**2秒**麻痹":

| Ô | Giá trị | Dòng mẫu |
|---|---|---|
| `效果1` | **4626** | `荡千军（直接伤血）` logic 1, `伤害数值+ = 100` |
| `效果2` | **4808** | `荡千军(麻痹)` logic 14, `总持续时间 = 2000` |
| `陷阱专用标记` | 0 → **2** | bằng đúng bẫy anh em `1800`/`2166` của cùng kỹ năng ở template khác (cùng hồ sơ: 10 s, nhịp 11 s, bán kính 6, 3 mục tiêu) |
| `是否即刻生效一次` | thêm mới = **1** | như `1800`/`2166`; ô này do `skill-logic-4` cài trong `trap.lua` |

Không trùng với `瞬移BUFFid = 49583`: ô đó là **impact thuấn di** (logic 9) mà `skill_840` dùng để dịch chuyển,
không phải 麻痹 [DK `skill_840.lua:9-12,126-141`]. Công cụ kiểm lại `伤害数值+ = 100` và `总持续时间 = 2000`
của hai dòng mẫu trước khi ghi; sai một điều kiện thì bỏ cả mục.

#### (c) `SpecialObjData 3064 万箭齐发` — **KHÔNG** dựng `效果1`, việc thuộc Lua **[DK]**

`cy_skill_logic_spec[736]` ghi "việc nhập `效果1` thuộc trap-impacts". Đã tra tận gốc: **bảng CY 3.71 của chính
dòng này (`1980 万箭齐发`, nguồn mà `trap_recollide` chép sang `3064`) cũng có `效果1 = -1`** [DK `11-two-jobs.txt`].
Nên dữ liệu **không phải** chỗ thiếu. Tip nói "对其周围5米范围内3个敌对目标造成**100%万箭齐发伤害**" — tức đúng
**dòng `伤害效果` của cấp đang dùng** (`37316`–`37331`, mỗi cấp một ID), mà một dòng bẫy chỉ có **một** ô `效果1`.
Cách đúng là **Lua**: khi logic 736 đặt bẫy, gán
`trap_obj._custom_descriptor = {['效果1'] = <伤害效果 của cấp đó>}` — cơ chế này đã có sẵn
(`trap.lua:21-30` ưu tiên `_custom_descriptor`, `std_impact_543.lua:121-172` đang dùng đúng kiểu này để truyền
impact theo cấp). Ghi cứng một ID vào bảng sẽ đúng **một** cấp và sai 15 cấp còn lại ⇒ để nguyên, giao lại `skill-logic`.

#### Kiểm sau đợt 4 **[DK]**

| Phép kiểm | Kết quả |
|---|---|
| `impact_recollide.py verify` | `cells_moved = 96`, **`cells_still_mount = 0`**, `trap_fix 2102 = {效果1: 4626, 效果2: 4808, 是否即刻生效一次: 1}`, **`errors []`** |
| `impact_recollide.py apply` | từ chối nếu **bất kỳ** ô/dòng nào ngoài danh sách bị đổi; số dòng hai bảng **y nguyên** (SkillData 20.667, SpecialObjData 1.528) |
| `trap_data.py verify` | `errors []`, `still_missing = 0` |
| `trap_impacts.py verify` / `impact_data.py verify` | `changed = 0`, **`errors []`**, `cyfour_unmapped = 0` (lượt này không đụng `StandardImpact`) |
| `server_impact.py verify` (không lùi) | `ok = true`, 0 lỗi, 27.830×81, luac 25/25, test Lua **19/19**, tham chiếu phân loại **93,759 %** |

**Đáng đo lại:** 桃花岛 **3820 棹歌中流** và **3822 劝君酒** — chờ thấy `buffs_other` **không còn ID khối 坐骑**
(trước: `3822` trả `{19695: 1, …}`); 绝情谷 **4516 荡千军** — chờ 刀域 gây **100 điểm sát thương thẳng + tê liệt 2 s**
cho tối đa 3 mục tiêu ở điểm đáp. 唐门 **2901 万箭齐发** vẫn chưa tóe được — chờ Lua (mục c).

## 7. ĐÃ LÀM 17/09 — **áp** kế hoạch mục 5: đổi ID cho **65/66** bẫy va chạm, agent `trap-recollide` **[DK]**

Thực thi kế hoạch mục 5 (agent `trap-collide`). Bằng chứng: `Build\Logs\2026-09-17-trap-recollide\`
(`README_vi.md`, `50-plan.json`, `50-trap-recollide.tsv`, `verify-trap-recollide.json`, `verify-trapdata.json`,
`verify-impactdata.json`, `40-coverage.tsv`, `52-idempotent-and-git.txt`, `scripts\20/30/40*.py`).
Công cụ mới **`Tools\server\trap_recollide.py`** (`plan|apply|verify`) — không sửa `trap_data.py`/`trap_impacts.py`.
**Không** restart server, **không** commit, **không** đụng `StandardImpact.txt` hay file Lua nào.

### 7.1 Đối chiếu lại kế hoạch trên bảng SỐNG trước khi áp **[DK]**

Handoff `trap-collide` yêu cầu chạy lại `20-collide-features.py` + `30-build-plan.py` vì trạng thái impact biến động.
Đã chạy lúc 10:27 ở server riêng **`f733316`** (cây sạch): `SpecialObjData.txt` và `SkillData_V1.txt` **vẫn y nguyên**
(`031a2e28…`, `01fb9585…`), `StandardImpact.txt` đã là `d06b646e…` (27.782 dòng, thêm `37922` của `trap-impacts`).
Kết quả **giống hệt** bản 09:42: **a = 65, b = 0, c = `[1750]`**, dải **3000–3064**, **213 ô** `SkillData`;
`plan.tsv` và `skilldata-cells.tsv` sinh lại **trùng từng byte**. ⇒ **0 ID lệch kế hoạch cũ.**
Dải `3000–3064` kiểm trống ở cả ba bảng ngay trước khi áp (server max **2347**, CY **2350**, client **2350**).

### 7.2 Ba bảng đã đổi cùng lượt **[DK]**

Sao lưu cả ba: `R/backups/trap-recollide-20260917T033633Z/` (kèm `manifest.json` có sha256 từng file).

| Bảng | Trước | Sau | Thay đổi | sha256 sau |
|---|---|---|---|---|
| `R/configs/SpecialObjData.txt` (GBK, 64 cột) | 1.463 dòng | **1.528** | **+65 dòng** `3000–3064`, **0 dòng cũ đổi**, 0 xoá | `58457e66…` |
| `R/configs/SkillData_V1.txt` (GBK, 54 cột) | 20.667 | 20.667 | **213 ô** `参数值` / **119 dòng**, 0 thêm, 0 xoá | `d910e233…` |
| `Assets\CanonicalCY\…\SpecialObjData.txt` (DBC `00CCBBDD`) | 1.843 bản ghi | **1.908** | **+65 bản ghi**, **0 bản ghi cũ đổi** | `9d7deb7c…` |

`1750` **không đụng** (phương án c). 16 dòng `1110–1125` **không bị ghi đè**; chuỗi
`SI 13305–13316 傀儡香 → bẫy 1110–1121` còn nguyên (verify kiểm tự động).

### 7.3 Bảng client là **DBC nhị phân**, không phải text — bẫy mới của lượt này **[DK]**

`Assets\CanonicalCY\Data\ConfigFolder\SpecialObjData.txt` có cấu trúc
`[magic 00CCBBDD][nFields u32][nRecords u32][poolSize u32][types u32×nFields][cells u32×nRecords×nFields][pool]`
(`type 0 = INT, 1 = FLOAT, 2 = STRING`, cell của STRING là **offset** vào pool). Đo được: **63 cột, 1.843 bản ghi,
pool 33.508 byte GBK**; dãy type **trùng khít dòng kiểu của bảng CY text** ⇒ dựng bản ghi mới thẳng từ dòng CY.
Hai ràng buộc bắt buộc: (1) **giữ nguyên pool cũ**, chỉ nối chuỗi mới và **dùng lại offset** cho chuỗi đã có —
lượt này pool **không đổi 1 byte** vì mọi chuỗi của 65 dòng đã có sẵn; (2) bảng phải **tăng dần theo ID**
vì `Obj_Special.cpp` tra bằng `Search_Index_EQU` (tìm nhị phân) — ID ≥ 3000 nối cuối nên vẫn đúng.

### 7.4 Kiểm sau khi áp **[DK]**

| Phép kiểm | Kết quả |
|---|---|
| `trap_recollide.py verify` | `ok = true`, `errors = []`, `warnings = []`; GBK cả ba file, đủ cột (64/54/63), không ID trùng, client còn sắp xếp tăng dần |
| 65 ID mới | có mặt ở **cả** server lẫn client, nội dung **khớp từng cột** với dòng CY |
| 213 ô SkillData | `o_SkillData_da_doi = 213`, `o_SkillData_con_ID_cu = **0**` |
| So **hash từng dòng** với sao lưu | `SpecialObjData` thêm đúng `[3000…3064]`, **đổi 0**, xoá 0; `SkillData` thêm 0, xoá 0, **đổi đúng 119 dòng** (= tập dòng của 213 ô); client **0 bản ghi cũ đổi**, +65 |
| ID bẫy CY **còn va chạm** | **1** — `[1750]` |
| `trap_data.py verify` | `rows = 1528`, `still_missing = **0**`, `errors = []` |
| `impact_data.py verify` | `changed = 0`, `errors = []`, `warnings = []`, `cyfour_unmapped = **0**` |
| Chạy lại `plan` | 0 thêm / 0 ô sửa, ba file **trùng sha** bảng sống ⇒ idempotent |

### 7.5 Impact của **bẫy mới** còn thiếu — cho `trap-impacts` **[DK]**

| Impact | Bẫy mới | Kỹ năng | Vì sao chưa dựng (mục 6.3) |
|---|---|---|---|
| `38550` | `3016` (cũ 1133) | `玄雷天降` tpl **3000** | tip BOSS không mô tả hiệu ứng |
| `54917` | `3017` (cũ 1149) | `玄雷天降` tpl **5714** | như trên |
| `53394`, `53423` | `3039–3054` (cũ 1820–1835) | `阳关三叠` tpl **510** (天山) | vùng 冰雾: hai ô hiệu ứng, tip chỉ mô tả một kết quả |

Ngoài lượt này, tầng bẫy còn **3** ID thiếu **không đổi ID**: `32665` (bẫy `1068 罂毒歌`),
`58694`/`58695` (bẫy `2172–2177 阳关三叠` tpl 5854). **Tổng tầng bẫy: 7 ID.**

### 7.6 Kỹ năng đáng đo live **[DK `40-coverage.tsv`]**

21 template đặt ít nhất một bẫy vừa đổi ID; **18** nay có bẫy **đủ**:

- **Sai → đúng ngay**: `797 霹雳锁` (慕容), `2921 霹雳锁` (唐门), `2934 蛛丝缠足` (dùng chung bẫy `3015`).
- **Bỏ vật thể sai** (dòng CY không có ô hiệu ứng): `2901 万箭齐发` (唐门) → `3064`;
  `3804 勒马归鞍` (桃花岛) → `3018`; `3819` + `5518 解我心忧`, `5189–5193 踏雪无痕` (天山) → `3019`.
- **Trơ → chạy**: `5225 定海神针` `3020`; `5238` + `5520 棹歌中流` `3021`/`3060–3062`;
  `5240` + `5523 荡千军` `3022`/`3058,3059,3063`; `5594 八阵图` `3055–3057`.
- **Một phần**: `510 阳关三叠` (天山) — 16 bẫy 会心 `3023–3038` **đủ**, 16 bẫy 冰雾 `3039–3054` chờ impact.
- **Chờ impact**: `3000` / `5714 玄雷天降`.

Đối chứng bắt buộc: `396 宙耀七星` (武当) phải **không đổi hành vi**.
`2901 万箭齐发` vẫn **trơ** vì `是否即刻生效一次` chưa được cài (0 chỗ đọc trong Lua) — đổi ID chỉ để bỏ
vật thể sai `防守玩法BOSS4-2技能1简单`.

### 7.7 `IDCollections.txt` — đã đo, **không phải làm gì** **[DK]**

Việc #5 của handoff `trap-collide`: `IDCollections.txt` (375 dòng) **không có dòng nào** chứa bất kỳ ID nào trong
66 ID cũ, cũng **không có dòng nào** chứa ID `3000–3064` (`skill_261` tra theo `类别`, không theo ID bẫy).
`类别` của 65 dòng mới là `4` ×42, `1` ×16, `2` ×3, `3` ×2, `0` ×2 — **mọi giá trị đều đã có sẵn** trong bảng
⇒ không sinh lớp mới. Hạn mức bẫy **cùng lớp** (`OR_TOO_MANY_TRAPS` của `skill_260`/`std_impact_309`) vẫn có thể
đổi trong trận; chỗ đó chỉ đo được khi chơi thật.

### 7.8 BẪY của lượt này **[DK]**

- **Bảng client là nhị phân.** Mở bằng trình đọc bảng text sẽ ra rác. Phải đọc/ghi theo `00CCBBDD`,
  **giữ pool cũ nguyên vẹn** và giữ **thứ tự ID tăng dần** (tìm nhị phân).
- **`build_srv_row` nén bỏ cặp tham số rỗng** nên nhãn có thể đổi vị trí so với dòng CY (`是否即刻生效一次` của
  `1980`/`3064` nhảy từ cặp 6 lên cặp 5). Không sao: `cfghelper:read_special_obj_data` đổ
  `descriptor[nhãn] = giá trị` — **vị trí không quan trọng, tên nhãn mới quan trọng**. Đừng "sửa" cho thẳng hàng.
- **Ô `SkillData` phải lấy từ bảng SỐNG rồi mới đối chiếu TSV**, không được ghi mù theo TSV: nếu bảng bị agent khác
  sửa, ghi mù sẽ đè lên ô lạ. `trap_recollide.py plan` quét sống → so với 213 ô → lệch thì báo `errors`.
- **Hoàn tác phải chọn đúng file.** `configs/StandardImpact.txt` của server riêng đang có thay đổi **chưa commit**
  của agent khác trong cùng buổi ⇒ `git checkout .` / `git reset --hard` / `git stash` sẽ **nuốt việc của họ**.
- Gọi WSL từ Git Bash: **không dùng biến shell trong chuỗi truyền vào `wsl … bash -lc`** — lớp bọc trên Windows
  bung `$VAR` thành rỗng trước khi tới WSL. Dùng đường dẫn tuyệt đối đầy đủ.

## 8. ĐÃ LÀM 17/09 — nội dung cho dải **64000–64035** của 桃花岛, agent `skill-data-final` **[DK]**

Tiếp mục 6.9: `impact_recollide` đã dời 96 ô của **3820 棹歌中流** / **3822 劝君酒** khỏi khối `坐骑` sang dải
**64000–64035**, và để lại 36 ID **chưa có dòng**. Lượt này dựng **17/36** dòng bằng nguồn thật, bỏ 19 ID có lý do.
Server riêng HEAD `e501c00`, **chỉ sửa** `configs/StandardImpact.txt` (27.830 → **27.847**, `changed = 0`).
Công cụ mới **`Tools\server\taohua_impacts.py`** (`plan|apply|verify`, idempotent, sao lưu, tự kiểm trên bảng sống).
Bằng chứng: `Build\Logs\2026-09-17-skill-data-final\` (`README_vi.md`, `01`–`18` khảo sát, `plan-1/`, `plan-2/`,
`verify-*.json`, `scripts\90-verify.sh`, `scripts\91-final.sh`).
Sao lưu: `R/backups/taohua-impacts-20260917T075053Z/`.

### 8.1 NGUỒN mới: bảng server **có sẵn khối CY 桃花岛 4260–4560** **[DK `05-block.txt`]**

Mục 6.9 kết luận "không có bảng `StandardImpact` của CY 3.71". Đúng với **toàn bộ** bảng, nhưng **sai với khối
桃花岛**: bảng đang chạy có sẵn một khối CY thật ở `4260–4560` — cùng nguồn với các ID mà bản port mã native CY
`lualib/cy_four_combat/tao.lua` gọi thẳng theo số:

| Dòng thật | Nội dung | Khớp tip CY |
|---|---|---|
| `4504`–`4515` `棹歌中流` | `逻辑ID 3`, `威力修正` = **95 / 100 / 105 … 150** (12 dòng) | dãy "每秒造成 **95 %** … **150 %** 的伤害" |
| `4543`–`4549` `棹歌中流` | dur **10.000 ms**, `转换比例` = 95 … 125 | "持续 **10** 秒" |
| `4400` `桃花岛暗伤标记` | `逻辑ID 8038`, dur **10.000 ms**, SE 4411 | "施加持续 **10** 秒的暗伤标记" |
| `4517` / `4518` | `劝君酒散攻效果` **4 s** / `劝君酒减速效果` **5 s, −45 %** | "持续 **5** 秒的 **45 %** 减速…造成 **4** 秒散功" |

Mã native còn ghim đúng dải: `tao.lua M.scale_tao_damage` chỉ chạy **cho source `4504..4515`**; nhánh 3822 của
`on_skill_success` gửi `4400` cho từng địch quanh con rối rồi `4518`/`4517` tuỳ `in_impact_collection(…, 281)`.

### 8.2 Hai nhóm đã dựng — đều là **bản sao nguyên vẹn** dòng có thật ở mốc `6ca25a8` **[DK `plan-1/taohua_impacts.tsv`]**

| ID | Ô | Mẫu | Bằng chứng công cụ tự kiểm lại trên bảng sống |
|---|---|---|---|
| `64001` (1 dòng, dùng chung 16 cấp) | 3820 `生效一次的效果1(傀儡周围敌人)` | **4505** `棹歌中流` (`逻辑ID 3`, `威力修正` = **100**) | Ô anh em `对效果1伤害的修正，效果1必须用3号伤害类BUFF` chạy −5 … +50 theo cấp; `skill_cy_spec:send` đổi nó thành `rate = 100 + ô` và **chỉ áp cho `逻辑ID = 3`** (đúng điều kiện ghi trong tên ô). Công cụ kiểm `100 + ô == %` trong tip ở **cả 16/16 cấp**; 4505 là thành viên "100 %" nên tích ra đúng 95 %…150 % |
| `64018`–`64033` (16 dòng theo cấp) | 3820 `生效一次给傀儡加效果` (bản THEO CẤP) | **4544** `棹歌中流` (`逻辑ID 38`, dur **10.000**, SE 4375) | Tên = tên kỹ năng; `总持续时间` = "持续10秒" của tip; `逻辑ID 38` là **cờ trạng thái**, và `转换比例` **không có chỗ đọc nào** trong `lualib/`+`services/` nên bản sao không thể gây tác dụng phụ. `cy_skill_logic_spec[799]` gửi ô này cho **chính con rối** |

### 8.3 19 ID **cố ý không dựng** — lý do **[DK `plan-1/taohua_declined.txt`]**

- **`64000`** (3820 `生效一次给傀儡加效果` bản **hằng số**, CY 45443): native gửi `4549` cho con rối, `4543` cho chủ,
  và `tick_doll` giữ điệu múa bằng `c:has_impact(doll, ref('impacts', 4549))` — tức **chỉ đúng ID 4549 mới có tác
  dụng**, bản sao ở ID mới không bao giờ thoả. `4549` lại mang `逻辑ID 8038` và `4543` mang `8168` (cy_four), chép
  sang ID mới sẽ sinh dòng `cyfour_unmapped` (mục 6.4 của `impact-data_vi.md`).
- **`64002`–`64017`** (3822 `…(目标)桃花岛苦昼短专用`): nội dung đúng là **`4400 桃花岛暗伤标记`** (trùng khít tip),
  nhưng `4400` mang `逻辑ID 8038` nên không chép được; và `tao.lua` đã gửi **đúng 4400** cho từng địch quanh rối.
- **`64034` / `64035`** (`傀儡罩子` / `傀儡连线`): tip 16 cấp không có câu nào về hai vai trò này; quét cả bảng có
  **0** dòng tên `罩子`, 5 dòng tên `连线` đều của kỹ năng khác; `tao.lua` cũng không gửi gì cho hai vai trò đó.

### 8.4 PHÁT HIỆN cần giao lại `cy_four` — `tao.lua` đang **ném lỗi** ở hai nhánh **[DK `06-cyfour-map.txt`]**

`tao.lua:30` là `function self:ref(kind,id) return assert((map[kind] or {})[id],'unmapped '..kind..':'..id) end`.
Đối chiếu `cy_four_combat/native_config.lua` (**1.298** ID đã ánh xạ, gồm hai dạng mục `[N]={…}` **và** `[N]=N`):

| ID | Vai trò | Có ánh xạ? |
|---|---|---|
| `4400` `桃花岛暗伤标记` | 3822/3809 gửi cho từng địch | **KHÔNG** |
| `4549` / `4543` `棹歌中流` | 3820 gửi cho con rối / cho chủ | **KHÔNG** |
| `4347`, `4260` | 暗伤 5 s, 聚星阵·贪狼 | **KHÔNG** |
| `4504`–`4515`, `4267`, `4345`, `4372` | sát thương, lớp tăng thương, 勒马归鞍 | CÓ |

Mỗi lần dùng **3820** hoặc **3822/3809**, `self:send(...)` chạy `ref('impacts', 4549/4400)` và **assert nổ**;
phần native của hai chiêu không chạy tới nơi. Sửa = thêm mục ánh xạ trong `native_config.lua` (file **Lua**,
thuộc chủ `cy_four`), **không phải việc dữ liệu**. Sau khi có ánh xạ thì mới đáng bàn tiếp `64000`/`64002–64017`.

**Lưu ý cho người viết công cụ:** `impact_data.py cyfour_mapped()` chỉ đọc dạng `[N]={` (408 mục) nên **bỏ sót**
1.128 mục dạng `[N]=N`. `taohua_impacts.py cyfour_mapped()` lấy **hợp** của cả hai (1.298). Hai hàm cho cùng kết
luận `cyfour_unmapped = 0` hôm nay, nhưng bản hợp mới là bản đúng với `engine.lua:67`.

### 8.5 **7 ID bẫy** của mục 6.3: vẫn **không dựng**, nhưng lý do nay chắc hơn **[DK `13/14/18-*.txt`]**

| ID | Tra thêm được gì trong lượt này |
|---|---|
| `58694`/`58695` (bẫy 2172–2177) và `53394`/`53423` (bẫy 3039–3054) — vùng 冰雾 của 阳关三叠 | (a) `GMVisible_Impact` của CY **không có tên** cho cả 4 ID; (b) bẫy `会心` anh em (`3023`/`3024`/`3038`, `2178`) chỉ mang `效果1` = dòng `阳关三叠（加会心）` nên **không lộ** hai ô của vùng sương; (c) cả 4 ID **hằng số qua 16 cấp**, tức là **hai hiệu ứng khác nhau** trong khi tip chỉ tả một; (d) **tìm được tập kỹ năng vị di**: `IDCollections` của **client CY** có dòng **`404 位移技能（瞬移+冲锋）`** (23 ID: 364 379 503 524 785 2543 2904 3806 3807 3808 4516 4523 4524 4544 4626 5826 5829 5836 5838 5839 5842 5844 5847) — nhưng `IDCollections` của **server** chỉ có 375 dòng và **dòng 404 của server là `变身3级`**, ghi `技能集合ID = 404` bây giờ sẽ **cấm nhầm**. Trên bảng sống chỉ có ba giá trị `技能集合ID` đang dùng: **64 / 286 / 56**, không cái nào là "vị di". Việc cần trước: `cy_collection_bridge` (của `skill-logic-4`) phủ thêm **tập kỹ năng**, không chỉ tập impact/驱散 |
| `32665` (bẫy 1068 罂毒歌 `效果1`) | Tip cho **nhịp** ("每隔2秒") và **thời lượng bẫy** (10 s) nhưng độ lớn vẫn là "**大量伤害**" — không con số. Không dòng thật nào tên 罂毒歌 (32666 là dòng suy của lượt trước) |
| `38550` (bẫy 3016), `54917` (bẫy 3017) — 玄雷天降 | Bẫy mang đặc hiệu `boss_赤帝_玄雷天降02` / `boss_玄击神将_玄雷天降陷阱爆炸`; tip chỉ là tên. Bảng có 61 dòng tên chứa 玄雷 nhưng đều của kỹ năng khác (玄雷咒(NPC), 玄雷击杀) và **không tip nào neo được độ lớn** nên chép là bịa |

### 8.6 Kiểm sau khi áp **[DK]**

| Phép kiểm | Kết quả |
|---|---|
| `taohua_impacts.py verify` | `ok = true`, `errors = []`, `changed = 0`, `cyfour_unmapped = **0**`, 17 ID đã dựng, dải còn thiếu 19 |
| `impact_data.py verify --base 6ca25a8` | `changed = 0`, `errors = []`, `cyfour_unmapped = **0**` |
| `trap_impacts.py verify --base 6ca25a8` | `ok = true`, `errors = []`, `changed = 0`, `cyfour_unmapped = **0**` |
| `trap_data.py verify` / `impact_recollide.py verify` | `errors = []`; `still_missing = 0`; `cells_still_mount = **0**` |
| `server_impact.py verify` | `ok = true`, bảng **27.847×81**, 0 tab lỗi, 0 trùng, tăng dần; `se_not_in_cy_client = 0`; `logic_not_registered = []`; tham chiếu phân loại **93,759 %** |
| Chạy lại `plan` sau `apply` | sha **trùng khít** bảng đang chạy (`2ec9d45c…`) — idempotent |
| `apply` | từ chối nếu **bất kỳ** dòng cũ bị đổi, hoặc thêm ID **ngoài dải 64000–64035** |

**Đáng đo lại sau restart:** 桃花岛 **3820 棹歌中流** — chờ thấy sát thương thật quanh con rối (trước đó ô trỏ ID
không có dòng nên `init_impact_from_data` trả `false` và logic bỏ qua) và con rối mang buff 10 s. **3822 劝君酒**
vẫn chưa đủ (暗伤/罩子/连线 chưa dựng, và nhánh native của nó đang assert ở `ref('impacts',4400)`).
