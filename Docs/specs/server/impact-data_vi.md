# impact-data — bù dòng StandardImpact còn thiếu bằng NGUỒN THẬT

Ngày: 16/09/2026. Agent `impact-data`, nhánh `impact-data`, worktree `Build\wt-impact-data`.
Tiếp nối `server-impact_vi.md` (đọc mục 0–1 trước), `impact-logic_vi.md`, `menpai-audit_vi.md` (mục 1.3 B, mục 4 #4), `menpai-fix_vi.md`.
Bằng chứng: `Build\Logs\2026-09-16-impact-data\`. Công cụ: `Tools\server\impact_data.py`.

Quy ước: **[DK]** dữ kiện đo được (đường dẫn/số dòng). **[SL]** suy luận. `R` = `/home/ubuntu/cys-test-20260913` (server riêng),
mốc vào việc `6ca25a8` (sau menpai-fix). **SI** = `R/configs/StandardImpact.txt`.

## 0. Kết quả

Mọi số so với mốc `6ca25a8` và **giữ nguyên Lua của mốc đó**, để tách riêng ảnh hưởng của lượt này (agent `skill-logic` sửa Lua song song — xem mục 6).

| Việc | Trạng thái |
|---|---|
| Ô impact thiếu dòng của **kỹ năng 15 phái cấp 1–4** | **716 → 183** (bù 533 ô; ID 527 → 134) |
| Ô impact thiếu dòng (toàn bộ SkillData) | 4.955 → **1.742**; ID thiếu 3.840 → **1.457** |
| Kỹ năng 15 phái cấp 1–4 "không tác dụng" (tĩnh) | **380 → 143**; "ok" 1.104 → **1.463**; "một phần" 158 → 36 |
| Tham chiếu impact có dòng | 19.754 → **22.967** / 24.709 (79,9 % → **92,95 %**) |
| Dòng thêm | **2.383** (bảng 25.311 → 27.694), **0 dòng cũ bị đổi** |
| Nguồn | **100 % là bản sao nguyên vẹn của một dòng có thật** trong bảng (chỉ đổi `Data_Index`, và `效果名称` khi GMVisible_Impact cho tên CY). Không có số bịa |
| Mức chắc chắn | **cao 1.628** (tên dòng mẫu dính tên kỹ năng, hoặc số trong tip CY trùng số của dòng mẫu), trung bình 185, thấp 570 |
| Logic của dòng mới | **2.130** dùng logic **đã cài** (tác dụng thật), 174 dùng logic donor `cy_four` (≥ 8000, đã bind), **79** rơi buff rỗng |
| Chỉnh SỐ theo tip CY (mục 6) | **66 ô tham số**; "số khớp tip CY" 73,0 % → **83,3 %** theo dòng, 64 → **73**/85 theo kỹ năng |
| "N % đòn đánh thường" (mục 6.3) | **65 ô** chuyển sang dòng `逻辑ID = 115` (`伤害量缩放系数`) theo tip CY — cơ chế do `skill-logic` bẻ được từ mã CY |
| Server riêng | `6ca25a8` → `2f41d75` → `b8ee0ee` (dựng lại theo luật đã sửa) → `47bd87e` (vòng 2) → `c13c380` + `d9fe9e5` (chỉnh số) → **`a545e0d`** (logic 115). Chỉ `configs/StandardImpact.txt`, **không đụng Lua**. Sao lưu `R/backups/impact-data-2026091602*`/`…03*` |
| Lỗi đã gây ra & cách xử lý | **158 dòng** mang logic `cy_four` ≥ 8000 thiếu **ánh xạ vị trí** trong `native_config.lua` → `unmapped positional impact` (mục 6.4). Giữ dòng, thêm ánh xạ: bảng `cyfour-map.tsv`; `verify` đã bổ sung phép kiểm `cyfour_unmapped` |
| Không lùi | `server_impact.py verify` **ok=true, 0 lỗi**; bảng 27.694×81, 0 tab lỗi, 0 trùng, tăng dần; `se_not_in_cy_client` 0; `logic_not_registered` rỗng; luac 25/25; test Lua **19/19** |

| Phái | ô P1 thiếu trước → sau | | Phái | ô P1 thiếu trước → sau |
|---|---|---|---|---|
| 恶人谷 Ác Nhân | 116 → 20 | | 唐门 Đường Môn | 66 → 18 |
| 星宿 Tinh Túc | 82 → 62 | | 绝情谷 Tuyệt Tình | 57 → 12 |
| 峨嵋 Nga My | 73 → 13 | | 鬼谷 Quỷ Cốc | 56 → 16 |
| 大理 Đại Lý | 72 → 7 | | 逍遥 Tiêu Dao | 26 → 5 |
| 慕容 Mộ Dung | 68 → 8 | | 天山 Thiên Sơn | 19 → 8 |
| 桃花岛 Đào Hoa | 67 → 8 | | 明教 / 少林 / 丐帮 | 7 → 3 / 5 → 1 / 2 → 2 |

### 1.1 Không có bảng StandardImpact của CY 3.71 trên máy — đã kiểm lại
- `find /c/TLBB/085 -iname '*standardimpact*'`: mọi bản đều là (a) tlbb15 `Server/Config/StandardImpact.txt` (8.137.022 B, 23.520 dòng), (b) bảng server GL/085, hoặc (c) bản sao/backup của hai thứ đó. **Chỉ một nguồn họ-CY duy nhất là tlbb15.**
- StandardImpact là bảng **chỉ có ở server**: trong mã 0.85 (`Reference/tlbb085`) chỉ `Server/.../GameTable.cpp`, `Impact_Core.cpp`, `FileDef.h` nhắc tới; client không nạp. Nên client CY 3.71 (DataCY31-08-26) **không thể** có bảng này.
- Phủ ID của các bảng SI khác lên 3.840 ID thiếu (`scripts/02-si-coverage.py`, `02-si-coverage.json`): tlbb15 0, server 0.85 0, **GL gốc 183**, GL+4 phái 215, donor 4 phái 0. GL cùng ID nhưng khác nghĩa — `server-impact` R2 đã lọc, chỉ nhận 16 dòng có bằng chứng.

### 1.2 Ba nguồn thật MỚI tìm được
| # | Nguồn | Vì sao là thật | Dùng cho |
|---|---|---|---|
| A | **Dòng SI cùng tên kỹ năng**: tlbb15 giữ `效果名称` = tên kỹ năng CY, hoặc "tên kỹ năng + hậu tố" (`回天术（护盾）`, `拘魂·地攻击`, `冰消冻释（免疫散功、封穴）`, `少泽剑＋玄攻`, `净心观月(免疫)`) | ID impact bị đánh số lại giữa hai nhánh nhưng **tên hiệu ứng giữ nguyên**; kiểm chứng bằng số trong tip CY (mục 2.2) | `name` 621 + `name2` 987 = **1.608 dòng** |
| B | **Cặp HJ**: client `Tools\DATA NEW\CYHJ091026\Config\SkillData_V1.txt` (15.325 dòng, **bố cục GL 48 cột**, giống server) + `SkillTemplate_V1.txt` (3.482 dòng, 82 cột) — cặp đúng với server tlbb15 | Client HJ và server tlbb15 cùng nhánh 怀旧: trong 12.753 ID impact mà SkillData HJ trỏ tới, chỉ 1.743 thiếu ở tlbb15 (13,7 %), so với 5.526 của CY | `hj` **50 dòng** (căn cấp tuyệt đối; chỉ dùng cho ô không có nhóm tên — xem 2.4) |
| C | **`GMVisible_Impact.txt` (client CY 3.71)** — 1.149 dòng `(chỉ số, Data_Index, ?, tên hiệu ứng)` = **tên impact THẬT của CY** | Liệt kê 264 trong số ID đang thiếu; 32 trong đó có dòng cùng tên ở SI | `gmname` **11 dòng** + đặt lại `效果名称` cho mọi dòng sinh ra có tên CY |

Đã loại: `Impact.txt` (19 dòng demo), `ImpactCollections.txt` (13 dòng), `ImpactPreShow.txt` (255 dòng mô tả kiểu khống chế), `ImpactDirectly.txt` (hiệu ứng sát thương hiển thị), `ZhenfaImpact.txt` (trận pháp) — không mang tham số impact [DK].
`GMVisible_Impact` cột 3 **không phải** `逻辑ID` (chỉ 30/611 trùng) — chỉ dùng cột tên.

## 2. Luật sinh dòng (`Tools/server/impact_data.py`)

`python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/impact_data.py plan --base <rev> --out <dir>` (chạy trong WSL).
Đọc R tại `--base` (mặc định HEAD), GL tại `995c2df`, client CY + client HJ (chỉ đọc). Mỗi dòng ghi: luật, ID dòng mẫu, lý do, mức chắc chắn (`impact_data.tsv`).

### 2.1 Gom ô thiếu theo kỹ năng
Ô impact = `参数值` của SkillData mà `参数说明` là nhãn impact (cùng bộ lọc `server-impact` mục 1.1). Nhóm = (SkillTemplate, vị trí cột) → danh sách `cấp → ID impact`.
Mỗi ID thiếu chỉ do **một** nhóm bù (ưu tiên nhóm thuộc phái 0–15 ≠ 9, cấp thấp nhất) để hai ô không chép cùng một dòng mẫu.

### 2.2 Bốn luật, theo thứ tự chạy
1. **`name` / `name2`**: nhóm dòng SI có `效果名称` = tên kỹ năng S (`name`) hoặc bắt đầu bằng S / bằng phần trước `·`, `（`, `(` của S (`name2`). Ghép **ô còn thiếu theo thứ tự cột** với **nhóm tên theo thứ tự ID nhỏ nhất**, rồi rải theo cấp (dòng thứ `L-1` khi nhóm đủ dài, không thì theo thứ tự xuất hiện). Loại mọi ID mà chính kỹ năng đó đã dùng.
   Ví dụ kiểm được [DK]: 唐门 `催箭式` tip CY "获得怒气的速度增加30%，增加自身命中260点" ↔ dòng tlbb15 3834 `怒气增长修正=30`, `命中+=260`, logic 60 → CY 37493 (cấp 1); 3835/3836/3837 (`命中+` 340/420/500) → 37494/37495/37496.
   `软猬仙身` tip "攻击者受到10%的伤害，持续20秒" ↔ 3946 `反射率=10`, `总持续时间=20000`. `含沙射影` tip "持续10秒" ↔ 3908 `总持续时间=10000`.
   慕容 `净心观月` tip "解除自己的失明状态，并免疫失明10秒" ↔ 3650–3661 (logic 18 驱散, `驱散集合=42`) cho ô 1 và 3662 `净心观月(免疫)` (logic 17, `总持续时间=10000`) cho ô 2.
2. **`hj`**: ô còn lại → template HJ **cùng tên và cùng phái** (qua ánh xạ HJ→CY, mục 2.4) → SkillData cấp L → ô cùng nhãn D → ID impact HJ → dòng đó **đã có trong SI server** (SI server ⊇ tlbb15) → chép.
3. **`series`**: cấp khác của **chính ô đó** đã có dòng (sẵn có hoặc vừa sinh ở bước 1–2) → chép dòng **cấp gần nhất**; lệch > 2 cấp → mức **thấp**.
4. **`gmname`**: `GMVisible_Impact` cho tên CY của ID thiếu → dòng SI cùng tên. Ví dụ [DK]: 绝情谷 `与虎谋皮` ID 49978–49983 → tên CY `与虎谋皮(封穴)` → dòng SI 4796–4801 (logic 14 khống chế) theo cấp.
5. **`gl`** (0 dòng lần này): dòng GL cùng ID và tên chứa tên kỹ năng — nối tiếp R2 của `server-impact`.

**Mức chắc chắn**: `cao` khi tên dòng mẫu dính tên kỹ năng **hoặc** một con số trong tip CY (kể cả `{A:x B:y}`) trùng một `参数值`/`总持续时间` của dòng mẫu; `thấp` khi phải kẹp cấp (hết dòng mẫu) hoặc `series` lệch > 2 cấp; còn lại `trung bình`.

**Không bịa số:** dòng sinh ra là bản sao nguyên vẹn của dòng mẫu; chỉ đổi `Data_Index`, đặt `效果名称` = tên CY khi GMVisible có, và hạ `瞬发效果ID` về −1 nếu SE đó không có ở `ImpactSEData_V1` của client CY (quy ước `server-impact`). Tip CY **chỉ dùng để chọn/kiểm dòng mẫu**, không dùng để sửa số của dòng.

### 2.3 Hai vòng
`plan` đọc R qua `git show` nên vòng 2 phải chạy **sau khi commit vòng 1**. Vòng 1 (nền `6ca25a8`) 2.040 dòng; vòng 2 (nền `b8ee0ee`) thêm **343** dòng — nhóm tên còn rảnh và `series` có thêm mốc. Tổng **2.383**.

### 2.4 Bẫy đã sập và cách sửa **[DK]**
- **Số phái HJ/GL ≠ số phái CY** (sau CS3b): đo theo số tên kỹ năng trùng nhau → HJ 0–8 = CY 0–8, **HJ 12 = CY 10 慕容** (35/36 tên chung), **HJ 11 = CY 15 恶人谷** (25/25), HJ 10 không khớp phái CY nào. Công cụ dựng ánh xạ này khi nạp và **bỏ mọi cặp HJ khác phái** — không thì 332 template trùng tên, 70 trong đó lệch phái.
- **Cặp HJ chạy trước luật tên là sai**: CY có kỹ năng bị làm lại so với HJ. Lượt đầu (`2f41d75`) 慕容 `净心观月` (CY: giải + miễn thất minh) nhận dòng `天魂效果·火/玄/毒` của bản HJ. Đổi thứ tự (tên trước, HJ sau) thì `hj` từ 481 → 50 dòng và mức "cao" 846 → 1.628 — phần lớn ô thật ra có dòng mang đúng tên kỹ năng.

### 2.5 Kết quả theo luật **[DK `final.json`]**
| Luật | Dòng | | Mức chắc chắn | Dòng | | Logic dòng mới | Dòng |
|---|---|---|---|---|---|---|---|
| `name2` | 987 | | cao | 1.628 | | đã cài (tác dụng thật) | 2.130 |
| `series` | 714 | | thấp | 570 | | `cy_four` donor ≥ 8000 | 174 |
| `name` | 621 | | trung bình | 185 | | buff rỗng (logic chưa cài) | 79 |
| `hj` | 50 | | | | | | |
| `gmname` | 11 | | | | | | |

Theo phái (chủ nhân ô): 恶人谷 276, 慕容 178, 峨嵋 165, 唐门 162, 绝情谷 161, 大理 141, 鬼谷 130, 桃花岛 87, 星宿 48, 逍遥 36, 少林 16, 天山 11, 明教 1, không phái 971.

Sáu ví dụ ô thiếu mà `menpai-fix` nêu (handoff mục "CHƯA LÀM" #2) đều đã có dòng thật [DK `final/impact_data_final.tsv`]:
45170 `雅颂之音` ← 4266 (logic 3), 45422 `秦皇东遣` ← 4425 (logic 9), 45423 ← 4422 `秦皇东遣会心一击免疫50%`, 45424 ← 4423 `秦皇东遣会心一击免疫控制`, 44879 `仁以守本` ← 4275, 45184 `战可得威` ← 4468.

### 2.6 Rà tay 16 kỹ năng 6 phái CY **[DK `31-spotcheck.txt`]**
Lấy mẫu ô cấp 1 của 16 kỹ năng (慕容/唐门/鬼谷/桃花岛/绝情谷/恶人谷), đặt tip CY cạnh dòng mẫu:

- **Cơ chế đúng 15/16**: `催箭式` (怒气增长修正=30, 命中+=260 ↔ tip "怒气 +30%, 命中 +260点"), `蓄云欲雨` (怒气+30), `净心观月` (logic 18 驱散集合 42 = thất minh ↔ "解除自己的失明状态"), `冰消冻释（解除封穴）` (驱散集合 40 ↔ "解除封穴"), `春光四沐` (驱散集合 329/52/53 ↔ "控制、虚弱、破绽"), `落日追星(内攻)` (logic 3 ↔ "内功攻击"), `唯心所欲（解除封穴）` (logic 18), `神枢战甲` (logic 14 trạng thái), `软猬仙身` (反射率=10, 20 s ↔ "攻击者受到10%的伤害，持续20秒"), `十方俱灭` (15 s + 子效果), `含沙射影` (子效果 3920 thất minh), `彼行我释` (技能释放=960 ↔ "返还控制"), `震箭式`/`风雷万钧` (tăng sát thương, logic donor `cy_four`).
- **Số có thể lệch vì CY cân bằng lại**: `七霞映日` tip 30 phút ↔ dòng mẫu 180.000 ms (3 phút); `风雷万钧` tip +45 % ↔ mẫu 50; `含沙射影` tip 20 % / 5 s ↔ mẫu 100 % / 10 s; `软猬仙身` tip "trần phản đòn 2000" ↔ mẫu 20000.
- **Không chắc 1/16**: `破天式` (tip chỉ ghi "80剧情挑战本", không mô tả hiệu ứng) → dòng mẫu 13522 `HP修改百分率=-5`.

Kết luận [SL]: **cơ chế (logic + nhãn + đối tượng) gần như luôn đúng; con số đúng khoảng một nửa, phần còn lại là bản HJ chưa cân bằng lại theo CY.** Đây là ranh giới thực tế của việc bù bằng dòng mẫu — muốn đúng số phải có bảng CY thật hoặc sửa theo tip (mục 5).

## 3. Áp lên server riêng, kiểm không lùi **[DK]**

1. `git -C R status` sạch → `impact_data.py apply --staging <dir>` → sao lưu `R/backups/impact-data-<UTC>/configs/StandardImpact.txt` (6 bản: `…T023536Z` = trước mọi thay đổi, `…T025304Z`, `…T025311Z`, `…T031124Z`, `…T032452Z`, `…T035301Z`).
2. `impact_data.py verify --base 6ca25a8`: 27.694 dòng, **2.383 thêm, 0 dòng cũ đổi**, 0 lỗi, 0 cảnh báo, `staging = R`.
   Kiểm gồm: GBK toàn file; số tab mỗi dòng = số cột; ID duy nhất và tăng dần; **logic của dòng mới phải đã có dòng trong bảng gốc** (engine không phải đăng ký logic mới → không chạm `assert(logic_id < 8000 …)` của `impactenginer`); **không lật fallback** `null_logic_buff` → `std_impact_003`; `瞬发效果ID` có ở `ImpactSEData_V1` client CY hoặc −1; cảnh báo khi ô con trỏ tới impact không có dòng.
3. `server_impact.py verify` (không lùi): **ok=true**, bảng 27.694×81 (0 tab lỗi, 0 trùng, tăng dần), tham chiếu phân loại **92,95 %**, `se_not_in_cy_client` 0, `logic_not_registered` **rỗng**, remap GL 102/102, `luac5.4 -p` 25/25, `server_impact_tests.lua` **19/19 đạt** (`si-verify-after2.json` so `si-verify-before.json`).
4. Commit server: `2f41d75` (bản đầu) → `b8ee0ee` (dựng lại theo luật đã sửa) → `47bd87e` (vòng 2) → `c13c380` (chỉnh số đợt 1) → `d9fe9e5` (chỉnh số đợt 2) → **`a545e0d`** (65 ô sang dòng logic 115, mục 6.3); mỗi commit chỉ `configs/StandardImpact.txt`, `git status` sạch.
5. Người điều phối bật/khởi động lại server 4 lượt: 09:38 (bảng `2f41d75`), 09:55 (`47bd87e` + Lua `skill-logic`), 10:17 (`c13c380`), **10:29 (`d9fe9e5`)**. Log Game2 của cả 4 lượt (`Game2_20260916_{093832,095448,101738,102904}.log`): **0 traceback / 0 `attempt to` / 0 `not configured` / 0 `SCENE_*_FAIL`**. 12 `stack traceback` trong `Manager8` mỗi lượt là đua thứ tự cluster lúc khởi động (`Connect to 127.0.0.1:12531 failed`), có từ trước lượt này, không liên quan bảng impact [DK `scripts/21-logcheck.sh`, `scripts/56-wait-restart.sh`].

**Hoàn tác:** `git -C R revert a545e0d d9fe9e5 c13c380 47bd87e b8ee0ee 2f41d75` rồi restart; hoặc chép lại `R/backups/impact-data-20260916T023536Z/configs/StandardImpact.txt` (bản trước mọi thay đổi của lượt này).

## 4. Kiểm live (bot)

Bot `CysNetBot` qua `Tools/server/menpai_audit/20-live.ps1 -Tag impact-data`, CYTest00 cấp 30 (cấp kỹ năng 4), 无量山 cảnh 6, mỗi chiêu một phiên.
Mốc "trước" = `Build\Logs\2026-09-15-menpai-audit\live-results.tsv` (server `926e506`/`6ca25a8`, cùng cách đo). Mốc "sau" = `Build\Logs\2026-09-15-menpai-audit\impact-data-results.tsv` (bảng `2f41d75`).

| Chiêu | Trước (buff tự thân / sát thương) | Sau | Kết luận |
|---|---|---|---|
| 慕容 767 七霞映日 | `{334}` (chỉ buff có sẵn khi vào cảnh), 0 | `{334, **1328**×6}` | có tác dụng |
| 慕容 772 蓄云欲雨 | `{334}`, 0 | `{334, **1326**×2}` | có tác dụng |
| 慕容 779 净心观月 | `{334}`, 0 | `{334, **3899**×2, **3912**×2}` | có tác dụng |

Cả ba trước đây bị `menpai-audit` xếp "gửi chiêu không tác dụng" (mục 1.2 của audit). 0 traceback trong log phiên.
Lượt bot bị dừng giữa chừng theo yêu cầu người điều phối để gộp restart với agent `skill-logic`; các chiêu 唐门/鬼谷/恶人谷 chạy tiếp sau restart.

## 6. Chỉnh SỐ cho khớp CY (`impact_data.py fix`) **[DK]**

Dòng bù là bản sao của bản HJ nên **cơ chế đúng mà số thường lệch** (mục 2.6). Lệnh `fix` sửa phần số đó.

**Nguyên tắc an toàn**: chỉ **chỉnh độ lớn** của tham số **đang dùng** (giá trị ≠ 0/−1) khi tip CY của **đúng SkillData cấp đó** cho **một** con số cho đúng ý nghĩa ấy.
Không bật tham số mới, không đổi `逻辑ID`/nhãn/đích/`互斥ID` → cấu trúc dòng vẫn nguyên như dòng mẫu thật. Tip không đủ số liệu thì giữ nguyên và ghi vào danh sách "cần nguồn khác".

| Luật | Nguồn trong tip | Nhãn được sửa |
|---|---|---|
| sát thương logic 3 | mệnh đề có `…攻击{A:x B:y}` (`外功/内功/冰/火/玄/毒`) | `物理攻击+ / 魔法攻击+ / 冰系攻击 / 火系攻击 / 电系攻击 / 毒系攻击` → `参数值`=A, `修正步长`=B |
| sát thương chung | mệnh đề có `{A:x B:y}` kèm `伤害/攻击` mà không nêu hệ | `伤害数值`, `伤害数值+` |
| thời lượng chung | `持续N秒` / `持续N分钟` / `持续时间：N秒`, **chỉ khi tip có đúng một giá trị** và dòng vốn đã ≥ 1.000 ms | `总持续时间(毫秒)` |
| thời lượng **theo loại hiệu ứng** | `<loại>…N秒` khi **chính dòng đó** mang loại ấy (tên dòng có `定身/麻痹/昏迷/眩晕/封穴/失明/沉默/昏睡/围困/散功/减速`, hoặc có nhãn `隐身级别修正`) | `总持续时间(毫秒)` — vượt được ngưỡng 1.000 ms vì đã có bằng chứng |
| phần trăm / điểm | `怒气…增加N%`, `命中N点`, `伤害提高N%`, `降低…受到伤害的N%`, `吸收N%`, `攻击者受到N%的伤害`, `反弹…最高为N`, `移动速度降低N%` | `怒气增长修正`, `怒气增长率修正`, `命中+`, `基础伤害增强`, `免疫率`, `伤害吸收率`, `反射率`, `反射伤害上限`, `移动速度修正%` (dấu âm) |
| **`<X>修正率` = phần trăm** | `命中/闪避/会心/外功攻击/内功攻击 … 增加N%` | `命中修正率`, `闪避修正率`, `会心修正率`, `会心攻击修正率`, `物理攻击修正率`, `魔法攻击修正率` |
| **tip của chiêu hai** | ô `激活二式buff` / `…刃影` đọc tip của **SkillTemplate `<tên>·刃影`**, không phải tip kỹ năng cha | mọi luật trên, áp trên tip con |

Ngưỡng **≥ 1.000 ms** cho thời lượng chung là bắt buộc: dòng mẫu có `总持续时间` 1–999 ms thường là cờ/nhịp của logic chứ không phải thời lượng buff — đổi sẽ làm sai hành vi [DK lần chạy đầu đã đổi nhầm 1 ms → 10.000 ms cho `引花绕梁`, đã chặn]. Luật "theo loại hiệu ứng" là ngoại lệ có bằng chứng.

**Kết quả** (mẫu = 330 dòng có tham số độ lớn, thuộc **85 kỹ năng** 15 phái cấp 1–4; dòng chỉ mang ID/tập hợp/script bị loại vì tip không bao giờ có số tương ứng; cùng một thước đo cho cả hai mốc):

| Chỉ số | Trước (`47bd87e`) | Sau (`d9fe9e5`) |
|---|---|---|
| Dòng có ít nhất một số khớp tip CY | 241 / 330 = **73,0 %** | 275 / 330 = **83,3 %** |
| Kỹ năng có ít nhất một số khớp tip CY | 64 / 85 = **75,3 %** | 73 / 85 = **85,9 %** |
| Ô tham số đã chỉnh | | **66** (57 đợt 1 + 9 đợt 2) |

Ví dụ [DK `fix-p1/impact_fix.tsv`]: 唐门 `软猬仙身` `反射伤害上限` 20000 → **2000** ("反弹…最高为2000"); 鬼谷 `谪仙梦影` `总持续时间` 25000 → **10/11/12/13 s** theo cấp; 桃花岛 `雅颂之音` `物理攻击+` 490 → **442** (tip `{A:442 B:3}`, `修正步长` → 3); 天山 `四面楚歌` 90 s → **10 s**; 恶人谷 `镰决` `命中修正率` 20 → **2** (cấp 4: 30 → 3); 天山 `踏雪无痕` ẩn thân 400/900 ms → **3.000 ms**; 大理 `商阳剑` ô `激活二式buff` 1.800 s → **10 s** (tip của `商阳剑·刃影`).
Áp lên server: `c13c380` (đợt 1) + `d9fe9e5` (đợt 2), sao lưu `R/backups/impact-data-20260916T031124Z` và `…T032452Z`; `verify --base 6ca25a8` 0 lỗi, **0 dòng cũ bị đổi**; `server_impact.py verify` ok=true, luac 25/25, test Lua 19/19.

### 6.0 Đơn vị tham số — đọc từ chính server, không đoán **[DK]**
- `<X>修正率` (`命中修正率`, `闪避修正率`, `会心攻击修正率`…) → `cy_impact_util.add_rate(args, v)` cộng vào `args.rate` → `lualib/db/human_attrib.lua:2436` (và `:2504`, `pet_attrib.lua:812`) `base = math.ceil(base * (100 + rate) / 100)` ⇒ **đơn vị là phần trăm**. Nên CY nói "命中增加2%" thì ô phải là **2**, không phải 20 (giá trị của bản HJ).
- `命中率调整百分比` / `闪避率调整百分比` → `services/scene/skill/base.lua:944` `accuracy + rate/100` ⇒ cũng là **phần trăm**.
- `总持续时间(毫秒)` → `cfghelper.lua:1382` `t.continuance` → `impactenginer.lua:68` `imp:set_continuance` ⇒ là **tuổi thọ của impact**, dùng thống nhất cho mọi logic (không có ô "thời lượng phụ"). Vì vậy dòng 400 ms **thật sự** chỉ sống 400 ms.
- `std_impact_003` (`services/scene/skill/impact_logic/std_impact_003.lua`) chỉ nhận **điểm công** (`物理攻击+`, `魔法攻击+`, `冰/火/电/毒系攻击`) và **sát thương thẳng** (`物理伤害`…, `直接伤害`), cùng các hệ số `wg_rate…damage_rate`. **Không có tham số "% phổ công"** ⇒ mô tả CY kiểu "造成100%普通攻击伤害" **không thể** biểu diễn bằng cách sửa số của dòng logic 3 (xem nhóm A).

### 6.1 Còn lệch: **80 dòng / 24 kỹ năng** — đã xử lý được gì, còn cần gì **[DK `46-need-source.txt`]**

| # | Vì sao tip không sửa được | Kỹ năng | Trạng thái sau khi đọc mã |
|---|---|---|---|
| A | Tip nêu **% phổ công**, dòng lại là **điểm** (`物理攻击+`/`魔法攻击+`) | 绝情谷 宁鸣不默 ×3 (70/95/120 %), 大理 少冲剑·刃影 (100 %), 恶人谷 魂离魄散 (108/130/167 %), 慕容 破天式 (`{A:14 B:0.07}%`) | **ĐÃ GIẢI** (mục 6.3): CY dùng **dòng `逻辑ID = 115`** (`伤害量缩放系数`), không phải ô của dòng logic 3. `skill-logic` cài module, impact-data đổi 65 ô sang dòng logic 115. Còn lại: 魂离魄散 do `skill-logic` xử lý; 破天式 là "% 内功攻击" (cơ chế khác) |
| B | Tip nói **"theo đánh giá tâm pháp/tu luyện"**, cố ý không có số | 唐门 落日追星, 大理 中冲剑·无助1级 | Giữ nguyên. Công thức nằm trong mã native server CY; tip không bao giờ có số. Cần port công thức, không phải sửa số |
| C | Ô là **hiệu ứng phụ** (`激活二式buff`) nhưng tip đọc là của **kỹ năng cha** | 大理 中冲剑 / 关冲剑 / 商阳剑 / 少商剑 / 少泽剑 | **ĐÃ XỬ LÝ**: `tip_for()` đọc tip của `<tên>·刃影`. 少冲剑 10 s → 6 s, 关冲剑 6 s → 3 s, 商阳剑 1.800 s → 10 s. Còn 中冲剑/少商剑 vì tip con không nêu số cho ô đó |
| D | **Chưa rõ đơn vị** (phần trăm / phần nghìn / điểm) | 恶人谷 镰决, 唐门 震箭式, 峨嵋 延年益寿, 大理 诸我圆满 | **ĐÃ XỬ LÝ một phần**: đơn vị `<X>修正率` = phần trăm (mục 6.0) → 镰决 `命中修正率` 20 → 2. Ba cái còn lại giữ nguyên: 震箭式 `会心伤害提升=25` [SL] vốn đã đúng theo cách hiểu "250 %/200 % = +25 %"; 延年益寿 ô `|疲劳buff` là cờ đánh dấu 20 s, số không lấy từ tip; 诸我圆满 `…系攻击修正=1` là **điểm**, tip lại nói 4 % của ba hệ khác → cần logic 11 tính động |
| E | `总持续时间` ngắn — là thời lượng thật hay cờ/nhịp? | 天山 踏雪无痕 (400/900 ms), 峨嵋 斩情诀·九阴 (500 ms), 慕容 判指阴阳 (1.000 ms), 恶人谷 拘魂·命 (5.000 ms), 慕容 彼行我释 (7.200.000 ms) | **ĐÃ XỬ LÝ một phần**: `总持续时间` là tuổi thọ impact, dùng thống nhất (mục 6.0) ⇒ chỉ sửa khi **chính dòng đó** mang hiệu ứng mà tip nêu thời lượng → 踏雪无痕 (ẩn thân) 400/900 ms → 3.000 ms. Các dòng còn lại không có bằng chứng loại hiệu ứng nên giữ nguyên |
| F | Số nằm ở **hiệu ứng con** | 峨嵋 回天术·九阳, 星宿 化骨绵掌, 恶人谷 拘魂·无厌, 逍遥 凌波微步 | **KHÔNG được sửa**: đã dò `子效果*`/`给自己的效果*` của các dòng này — mọi ID con đều là **dòng tlbb15 có sẵn**, dùng chung cho kỹ năng khác. Sửa chúng sẽ đổi hành vi của những kỹ năng đang chạy. Chỉ sửa được khi dòng con cũng do impact-data thêm (công cụ đã hỗ trợ qua `scope_rows(..., children)`), lần này không có trường hợp nào |

Bằng chứng từng ô (tham số hiện có + tip nguyên văn): `46-need-source.txt`; trước/sau từng ô của 85 kỹ năng: `44-review-p1.txt`; từng ô đã chỉnh: `fix-p1/impact_fix.tsv`.

### 6.2 Nhóm A — "% phổ công" nằm ở **bên gọi**, không ở dòng impact **[DK mã native + Lua]**


| Hàm | VA | Kích thước |
|---|---|---|
| `StdImpact003_T::InitFromData` | `0xa43dd2` | 572 |
| `StdImpact003_T::OnActive` | `0xa43cb0` | 289 |
| **`StdImpact003_T::RefixPowerByRate`** | **`0xa440c8`** | 232 |
| `StdImpact003_T::CriticalRefix` | `0xa4400e` | 186 |

`RefixPowerByRate(imp, rate)` làm đúng một việc: `ebx = rate + 100`, rồi với **cả 7 ô sát thương** của impact (offset `+0x2c, +0x30, +0x34, +0x38, +0x3c, +0x40, +0x44` — sáu hệ + sát thương thẳng) tính `field = Float2Int(ebx * field / 100.0f)` (hằng `100.0f` tại VA `0xb09ce0`, đã đọc byte `00 00 c8 42`) [DK].

⇒ **"造成100%普通攻击伤害" không phải là một ô trong StandardImpact.** Nó là hệ số `rate` do **bên gọi** truyền vào lúc phát impact. Phía server riêng (Lua) cơ chế này đã có sẵn: `logic:refix_power_by_rate(imp, rate)` (`lualib/cy_four_combat/engine.lua:107,147` → `native.refix_167`) và được các logic gọi khi gửi impact con (`std_impact_060.lua:88,96`, `std_impact_081.lua:85`, `std_impact_088.lua:84`, `std_impact_502.lua:30`…).

**Giao lại cho `impact-logic`/`skill-logic`**: muốn 绝情谷 宁鸣不默 (70/95/120 %), 大理 少冲剑·刃影 (100 %), 恶人谷 魂离魄散 (108/130/167 %), 慕容 破天式 (`{A:14 B:0.07}%`) đúng như CY thì phải cài **logic kỹ năng/impact gọi `refix_power_by_rate` với tỉ lệ lấy từ tip**, hoặc dùng dòng logic phần trăm của `cy_four` (dải ≥ 8000). Sửa số trong dòng logic 3 **không** làm được việc này.

### 6.3 Nhóm A đã giải xong: **dòng `逻辑ID = 115`** **[DK]**

`skill-logic` (16/09, server `265b531`) bẻ tiếp mã CY và tìm ra cơ chế: **"造成N%普通攻击伤害" là một dòng StandardImpact riêng mang `逻辑ID = 115`, tham số 0 = `伤害量缩放系数`** — `StdImpact115_T::OnActive` @`0xa5f2f8` nạp **DataIndex 0** (dòng "đòn đánh thường") rồi nhân theo hệ số; `IsOverTimed`/`IsIntervaled` đều trả 0 (tức thời). Họ đã cài `services/scene/skill/impact_logic/std_impact_115.lua` và đăng ký `[115]` trong `impactenginer.lua:444`.
Kết luận mục 6.2 vẫn đúng ở chỗ "không phải tham số của dòng logic 3"; cái thiếu là **CY dùng một dòng khác, không phải một ô khác**.

Lệnh mới `impact_data.py scale --base <rev> --out <dir>` đổi **dữ liệu** (không đụng Lua): ô áp lên **MỤC TIÊU** đang trỏ dòng logic 3 (điểm công bản HJ) → dòng dựng từ **mẫu thật 43918 `撼岳群攻效果`** (logic 115, `是否是持续性效果=0`, `影响性质=-1`, SE 370), `伤害量缩放系数` = % lấy từ tip CY của **đúng SkillData cấp đó**, `效果名称` = tên kỹ năng.

Dãy % trong tip là **ba đoạn** của cùng một chiêu và **dịch theo cấp** (cấp 1 `70%/95%/120%`, cấp 2 `75%/100%/125%`…), nên bảng `SCALE_CELLS` ghép **đoạn ↔ template** bằng tay:

| Kỹ năng (template) | Ô | Hệ số cấp 1–4 |
|---|---|---|
| 绝情谷 宁鸣不默 **4538** (đoạn 1) | `生效一次的效果(目标)` | 70 / 75 / 80 / 85 |
| 绝情谷 宁鸣不默（2段）4533 | `生效一次的效果(目标)` | 95 / 100 / 105 / 110 |
| 绝情谷 宁鸣不默（3段）4534 | `生效一次的效果(目标)` | 120 / 125 / 130 / 135 |
| 绝情谷 宁鸣不默 **4707** | `生效一次的效果(目标)` | 165 |
| 大理 少冲剑·刃影 822 | `附加效果1` | 100 |
| 大理 少商剑 463 | `附加效果2` | 50 |

**Kiểm chéo luật ghép đoạn [DK]**: impact **49918** được **hai** template dùng — 4534 (đoạn 3) ở **cấp 10**, tip cấp đó là `115%/140%/165%` ⇒ đoạn 3 = **165**; và 4707, tip riêng ghi thẳng "额外造成普通攻击**165%**的伤害". Hai đường độc lập cho cùng một số.

Tổng **65 dòng** đổi (mọi cấp), 0 dòng gốc bị đổi. Bằng chứng từng ô: `scale-1/impact_scale.tsv` (logic cũ → 115, hệ số, dãy % trong tip, tip nguyên văn).

#### ĐỪNG đổi các ô sau sang logic 115 — đã xét và cố ý bỏ **[DK]**
Tip của chúng **có** con số "% phổ công" nên bộ lọc tự động rất dễ quét trúng, nhưng đổi là **sai**:

| Ô | Vì sao KHÔNG đổi |
|---|---|
| 星宿 心如毒蝎 (tpl 840/843/846) ô **`封穴buff`** — impact 59741–59748 | Đây là ô **khống chế** (dòng hiện tại logic 14, phong huyệt 1 s). Tip có "80/90/100 % 普通攻击伤害" nhưng con số đó thuộc **phần sát thương mỗi giây** của chiêu, không phải ô này. Đổi sang logic 115 sẽ **mất hẳn phong huyệt** và biến ô khống chế thành ô sát thương |
| 大理 少商剑 (tpl 463) ô **`激活二式buff`** — impact 57155 | Ô **kích hoạt chiêu hai** (`少商剑·刃影`), không phải ô sát thương lên mục tiêu. Số 50 % trong tip là của phần văng quanh mục tiêu (ô `附加效果2`, đã đổi) |
| 慕容 破天式 (tpl ~1180) ô `\|生效一次的附加效果2` — impact 21585 | Tip ghi "造成**内功攻击**{A:14 B:0.07}%的直接伤害" — **% của nội công**, không phải % đòn đánh thường. Logic 115 lấy **DataIndex 0 = đòn đánh thường** nên sẽ tính sai hệ. Cơ chế này chưa tra, để lại |
| 恶人谷 魂离魄散 | Tỉ lệ (108/130/167 %) nằm sẵn trong SkillData và do **logic kỹ năng 867** xử lý (`skill-logic`), không phải việc của dòng impact |
| 绝情谷 宁鸣不默（4段）/（5段）(废弃) | Tên template ghi 4段/5段 nhưng tip chỉ liệt kê **ba** giá trị (28/58/128 và 28/58/78) → không xác định được đoạn nào ứng với template. Lại còn `（废弃）`. Cần tra thêm mới đổi |

Quy tắc chung rút ra: **chỉ đổi ô mà (a) nhãn nói rõ áp lên MỤC TIÊU, (b) dòng hiện tại là dòng sát thương, và (c) con số "% phổ công" trong tip đúng là của ô đó.** Ô khống chế, ô kích hoạt chiêu khác, ô "% của một hệ công khác" đều nằm ngoài.

## 6.4 LỖI ĐÃ GÂY RA: 158 dòng cy_four thiếu **ánh xạ vị trí** **[DK]**

**Triệu chứng**: log Game2 `./lualib/cy_four_combat/engine.lua:67: unmapped positional impact`, cả lúc **đăng nhập** (`lualib/db/impact_data.lua:23 init_from_db_data` → `services/scene/obj/character.lua:1503 on_impact_activated`) lẫn lúc **dùng chiêu** (`eventenginer:register_impact_event`). Lần đầu ở `Game2_20260916_102904.log` (restart 10:29); **không có** ở các lượt 09:38/09:55/10:17 [DK `scripts/75-unmapped.sh`].

**Nguyên nhân**: `cy_four_combat/engine.lua:67` làm `assert(self.config.impacts[imp:get_data_index()], "unmapped positional impact")` — mọi impact mang `逻辑ID ≥ 8000` phải có **Data_Index** trong bảng `impacts={…}` của `lualib/cy_four_combat/native_config.lua` (250 mục). Luật `name`/`name2` của impact-data chép dòng mẫu **theo tên kỹ năng**, và **158 dòng** trong 2.383 dòng thêm có logic ≥ 8000 nhưng mang **Data_Index mới** ⇒ không có trong bảng đó [DK `scripts/78-cyfour-check.py`].
Phân bố: 8038 ×59, 8156 ×27, 8149 ×26, 8148 ×16, 8167 ×16, 8090 ×7, 8171 ×2, 8181 ×2, 8184 ×2, 8182 ×1. 48 dòng thuộc ô kỹ năng 15 phái cấp 1–4.

**Lỗ hổng của `verify`**: đã kiểm "logic của dòng mới phải có dòng trong bảng gốc" nhưng **không kiểm ánh xạ vị trí của cy_four**. Đã bổ sung: dòng thêm có `逻辑ID ≥ 8000` mà Data_Index không có trong `native_config.lua impacts={}` ⇒ **LỖI**, kèm trường `cyfour_unmapped` trong kết quả.

**Cách xử lý (người điều phối chọn)**: giữ 158 dòng (chúng vẫn là bản sao dòng thật, chỉ thiếu mục ánh xạ) và nhờ chủ `cy_four` thêm mục. Bảng đã xuất: **`Build\Logs\2026-09-16-impact-data\cyfour-map.tsv`** — `impact_id_moi | dong_mau_id | dong_mau_goc_da_anh_xa | logic | phai | ky_nang | template | cap | nhan_o`. **158/158 dòng truy được `dong_mau_goc_da_anh_xa`** (một Data_Index đã có sẵn trong bảng), nên việc cần làm chỉ là `impacts[impact_id_moi] = impacts[dong_mau_goc_da_anh_xa]`, chép nguyên descriptor. 45 dòng là chuỗi chép (`series` chép lại dòng vừa sinh) nên công cụ lần ngược chuỗi tối đa 8 bước để ra dòng mẫu gốc.
Đường dự phòng đã có sẵn trong công cụ nhưng **chưa chạy**: `impact_data.py cyfour --repair` (thay bằng dòng cùng tên kỹ năng có logic < 8000, không có thì xoá dòng — mất tối đa 48 ô P1).

## 7. Lưu ý khi đọc chỉ số "không tác dụng"

Chỉ số này (định nghĩa của `server-impact` mục 1.5) tính một ô là hỏng khi: **thiếu dòng impact**, **logic impact chưa cài**, hoặc **nhãn CY không nằm trong bộ nhãn `cfghelper:read_skill_data`** và logic kỹ năng đã cài.
Agent `skill-logic` cài thêm 75 logic **kỹ năng** trong cùng ngày (`dffe28c`), nên vế thứ ba bật lên cho nhiều kỹ năng mới → đo trên Lua mới, con số nhảy lên (1.220 ok / 378 none) dù bảng impact đã đầy hơn.
Vì vậy mục 0 báo cáo theo **Lua giữ nguyên ở `6ca25a8`** (tách riêng ảnh hưởng của impact-data), và kèm chỉ số thuần bảng — **ô impact thiếu dòng 716 → 183** — không phụ thuộc Lua.
Công cụ cần cập nhật bộ nhãn biết được (đọc thêm `cy_skill_extra.lua` / `skill_cy_spec.lua` của `skill-logic`) trước lần đo chung tiếp theo.

## 8. Nội suy theo cấp + bù 17 ô cấp 1–4, 17/09/2026, agent `impact-data-2` **[DK]**

Làm tiếp hai việc của handoff `impact-data` mục "CÒN LẠI" (#2 nội suy `series`, #1 các ô cấp 1–4 chưa có nguồn).
Mốc vào việc: server riêng **`cd22aab`** (sau `trap-impacts` đợt 3), chỉ đụng `configs/StandardImpact.txt`.
Bảng **27.807 → 27.824** (+17 dòng), **58 dòng `series` được chỉnh số**, **0 dòng gốc (mốc `6ca25a8`) bị đổi**.
Công cụ: hai lệnh mới `impact_data.py interp` và `impact_data.py p1fill` (giữ khuôn `plan|apply|verify`, idempotent, sao lưu).
Bằng chứng: `Build\Logs\2026-09-17-impact-data-2\` (`scripts\01..11`, `interp-1\impact_interp.tsv` +
`impact_interp_skip.tsv`, `p1-1\impact_p1fill.tsv` + `impact_p1fill_declined.txt`, `verify-*.json`,
`si-verify-1/2.json`, `30-tong-ket.json`, `20-p1-remain-sau.txt`).
Sao lưu: `R/backups/impact-data-20260917T040424Z` (trước việc 1) và `…T041607Z` (trước việc 2).

### 8.0 `修正步长` KHÔNG phải bước theo cấp — đọc từ dữ liệu và từ mã server **[DK]**

Trước khi nội suy phải biết cấp được biểu diễn ở đâu. Ba dữ kiện:

1. `cfghelper.lua:1394-1412` (`read_std_impact`) chỉ đổ **`参数值`** vào `t.params` (`:1396` lấy nhãn theo
   `参数(%d+)说明`, `:1407` đổ giá trị); `grep 修正步长 lualib/cfghelper.lua` ra **0 dòng**
   ⇒ trên server riêng, cột này hoàn toàn không có tác dụng.
2. Trong chính bảng, `修正步长` **giữ nguyên qua các cấp** còn `参数值` **tăng tuyến tính**:
   `1915–1926 少商剑` `火系攻击` = 279 / 480 / 681 … với `修正步长` = 14,69565217 ở **cả 12 dòng**;
   `2426–2431 阳关三叠（加会心）` `会心一击修正` = 96/108/…/156 với bước 1; `170–177` `伤害数值` = 154/264/…/925.
   ⇒ `修正步长` là bước theo **tu luyện**, không theo cấp (khớp với quy ước tip CY `{A:参数值 B:修正步长}`).
3. Ngoại lệ đã biết: `StdImpact115_T::InitFromData` @`0xa5f204` làm `round(修正步长0 × imp.level) + 参数值0`
   (`std_impact_115.lua` mục đầu). Đó là **riêng logic 115**, và bản tlbb15 đặt `修正步长` = 0 ở mọi dòng 115.

⇒ Kỹ năng chỉ mạnh lên theo cấp khi **mỗi cấp trỏ tới một dòng khác có `参数值` lớn hơn**. Đây đúng là chỗ luật
`series` làm hỏng: nó chép NGUYÊN dòng của cấp gần nhất. Vì vậy lệnh `interp` chỉ đổi **`参数值`** và
**`总持续时间`**, **không đụng `修正步长`** (giống R1 của `server-impact`).

### 8.1 Việc 1 — `impact_data.py interp`: nội suy được **58/714** dòng, và vì sao không hơn **[DK]**

```
python3 -B Tools/server/impact_data.py interp --base 6ca25a8 --out <dir> \
        --tsv Build/Logs/2026-09-16-impact-data/final/impact_data_final.tsv \
        --scale-tsv Build/Logs/2026-09-16-impact-data/scale-1/impact_scale.tsv
```

**Mốc thật** của một ô = các cấp khác của **chính ô đó** mà dòng impact **không phải** dòng `series`
(dòng gốc của bảng, hoặc dòng do luật `name`/`name2`/`hj`/`gmname` sinh), cùng `逻辑ID`, và ID không bị
ô/cấp khác dùng chung. Khớp **bình phương tối thiểu** qua mọi mốc; nếu sai số lớn nhất > `max(1; 2 % biên độ)`
thì coi như dãy không tuyến tính và lùi về **hai mốc gần nhất**.

| Phân bố 597 mức `series` ứng viên (714 − 117 dùng chung / đã sang logic 115) | Số |
|---|---|
| **Đã nội suy** (58 dòng, **88 ô tham số**) | 58 |
| Có ≥ 2 mốc nhưng mọi cấp cùng một con số ⇒ không có gì để suy | 102 |
| **Dưới 2 mốc thật** (417: **358** mức chỉ có **một** mốc, **59** mức **không** mốc nào) | 417 |
| Dòng `逻辑ID ≥ 8000` (cy_four, tham số đọc theo VỊ TRÍ) — cố ý không đụng | 20 |
| `总持续时间 ≥ 10 phút` (cờ gần như vĩnh viễn, vd 商阳剑·刃影 8.100.000 ms) | 17 |
| Phần trăm vượt ngưỡng ⇒ bỏ cả nhãn của ô (xem 8.3) | 1 |

**Không có mức nào nội suy được theo nghĩa "kẹp giữa hai mốc": 538/538 mức có mốc đều nằm TRÊN mốc cao nhất.**
Lý do có thật: tlbb15 chỉ có **12 cấp**, CY có **16** — cấp 13–16 luôn là phần thừa. Nên toàn bộ 88 ô là **ngoại suy**
(cột `kieu` của TSV), mức chắc chắn `trung bình` 83 / `thấp` 5 (`thấp` = khớp bằng hai mốc thay vì cả dãy).
Đã thử thêm hai nguồn mốc khác và **cả hai đều không giúp được**: cặp HJ chỉ cho mốc cho **7/597** mức
(`scripts/03-survey3.py`), tip CY của đúng cấp chỉ có `{A:x B:y}` ở **56/597** mức.

Ví dụ [DK `interp-1/impact_interp.tsv`]: 唐门 `催箭式` `命中+` cấp 13–16 = 1.140 (đứng yên) → **1.220 / 1.300 / 1.380 / 1.460**
(khớp 12 mốc `y = 180 + 80·cấp`); 唐门 `软猬仙身` `反射率` 21 → 22/23/24/25; 恶人谷 `拘魂·天` `伤害数值` 1.410 → 1.524/1.638/1.752/1.866
(`y = 42 + 114·cấp`); 鬼谷 `抱元守一` bốn ô `X系抗性修正` 14 → 15/16/17/18; 唐门 `含沙射影` `总持续时间` 21 s → 22/23/24/25 s.
16 kỹ năng của 6 phái (鬼谷 6, 恶人谷 4, 唐门 3, 慕容/大理/绝情谷 mỗi phái 1): 造化三生, 抱元守一, 判指阴阳, 少冲剑·刃影, 催箭式, 软猬仙身, 含沙射影, 荧惑守心, 逍遥游,
五气朝元, 意纵横, 指踪悬印, 银钩走蝎, 拘魂·天, 剔魂削骨, 魂离魄散.

### 8.2 Việc 2 — `impact_data.py p1fill`: **17 dòng** cho ô cấp 1–4, mỗi dòng một dòng mẫu THẬT **[DK]**

Cùng khuôn `COPY_CELLS` của `trap_impacts.py` (mục 6 `trap-data_vi.md`): mỗi mục khai báo **dòng mẫu + điều kiện**,
công cụ **tự kiểm lại trên bảng sống** (tip cấp 1–4 phải chứa chuỗi khai; dòng mẫu phải đang mang đúng
`总持续时间`/`参数值` đã khai; ô phải thật sự trỏ tới ID đó; ID phải đang **thiếu**). Sai một điều kiện ⇒ **bỏ và ghi lý do**.
Dòng mẫu **bắt buộc có mặt ở mốc `6ca25a8`** (dòng gốc của bảng, không phải dòng do agent trước suy ra).

| ID | Ô (template) | Mẫu | Đổi số | Bằng chứng |
|---|---|---|---|---|
| 59706–59709 | 星宿 神蝎百相 **434** `免控buff` c1–4 | `13519 横扫乾坤（免疫控制）` | **không** | Cùng vai trò/cùng tip với ô `免控buff` của 蝎行无阻 841/844 mà `trap-impacts` đã dựng thành `59721` **từ đúng dòng mẫu này**; 10.000 ms = "持续10秒" của tip |
| 59178–59181 | 鬼谷 借东风 **3448** `霸体效果` c1–4 | `13519` | `总持续时间` 10.000 → **3.000** | Tip "落地时获得**3秒**霸体" cho đúng một con số. Bảng **không có dòng nào tên `霸体`**; họ dòng duy nhất làm "không bị khống chế" là `免疫控制` |
| 59800 | 星宿 饮鸩止渴 **436** `疲劳buff` | `55 珍兽群攻疲劳` (logic 38, 0 tham số) | **không** | Dòng mẫu đã đúng **60.000 ms** = "同一目标**60秒**内只能被千足守护一次" |
| 21667 | 峨嵋 金针渡劫 **423** `\|生效一次的附加效果2` | `64 珍兽神佑疲劳` | **không** | Đã đúng **600.000 ms** = "**10分钟**内同一目标只能受到一次". Ô anh em `…效果1` đang trỏ `金针渡劫(复活)` (`HP修改量`/`MP修改量` = 6 = "6%的血/气") ⇒ ô còn lại là cờ khoá 10 phút (công cụ kiểm điều kiện `sib`) |
| 59722–59725 | 星宿 毒螯势 **839/842/845** `中毒buff` c1–4 | `1031–1034 中毒(HPDOT2)` | `总持续时间` 12.000 → **10.000** | Đúng khuôn DOT độc (logic 10, nhịp 1 s, `子效果` = `中毒减血` **theo cấp**); tip "使目标中毒…**持续10秒**" |
| 32668 | 星宿 无处遁形 **2264** `\|…附加效果2` | `1031` | như trên | Tip "使目标处于**中毒**状态，持续伤血，状态**持续10秒**" |
| 32671 | 大理 六剑齐发 **2266** `\|…附加效果2` | `6313 弱不禁风(NPC)破绽防御` | `物理/魔法防御修正率` −30 → **−50**, thời lượng 120 s → **10 s** | Tip cho **cả hai** số: "内功防御和外功防御降低**50%**…状态**持续10秒**". `<X>修正率` là phần trăm (mục 6.0). Dòng mẫu là dòng thật **duy nhất** đang dùng cả hai nhãn đó |
| 38463 | 唐门 矢魂箭 **2933** `生效一次的效果(自己)` | `3908 含沙射影` (logic 88) | `总持续时间` 10 s → **20 s** | Cơ chế trùng khít: `伤害目标时的激发几率 = 100` ("**每次**攻击") + `给目标或攻击者的子效果1 = 3920 含沙射影失明`; tip "**持续20秒**" |

**Số đo** (ô cấp 1–4 của 15 phái thiếu dòng): theo (SkillData, cột) — thước đo của mục 0 — **171 → 140**;
theo (template, cấp, cột) **228 → 188**; ID thiếu **132 → 115**; nhóm ô **57 → 47**.
Tham chiếu impact có dòng **93,148 % → 93,371 %**.
(Mốc 183 của mục 5 đã tụt về 171 nhờ `trap-impacts` trước lượt này.)

**Hai chỗ phải nhớ khi đo live:** `32671` thừa hưởng `互斥ID = 25` (破绽) của dòng mẫu nên nó và các debuff
cùng họ sẽ thay thế nhau; `38463` dùng chung dòng con `3920` (**0,3 s**) trong khi tip 矢魂箭 ghi **0,5 s** —
`3920` là dòng có sẵn dùng chung của 含沙射影 nên **không được sửa** (mục 6.1 nhóm F).

### 8.3 Ba chặn mới của `interp` — đều vì một ca có thật **[DK]**

- **Danh sách nhãn `INTERP_LABELS`** (chỉ nhãn mang ĐỘ LỚN). Nếu nội suy theo nhãn bất kỳ thì
  `子效果1数据索引` của 峨嵋 `回天术·九阳` (16191/16192/16193/16194 theo cấp) sẽ ra **16195** — một **ID không có dòng**.
  Nhãn kiểu ID/tập hợp/cờ (`驱散集合*`, `子效果*`, `脚本ID`, `技能ID`, `变身ID`, `免疫集合*`, `CanAction*`, `一魂/二魂/三魂`…)
  đều nằm ngoài danh sách.
- **`INTERP_CAP`** cho phần trăm của một *tổng thể*: 峨嵋 `斩情诀·九阴` `聚气时间百分修正` có ba mốc −75/−80/−85,
  khớp tuyến tính ra **−150 %** ở cấp 16 (thời gian tụ khí âm). Vượt ngưỡng ⇒ **bỏ cả nhãn cho mọi cấp của ô**,
  không cắt ngọn — cắt sẽ tạo bậc thang không đơn điệu (cấp 6 = −100, cấp 7 = −85).
- **`INTERP_LONG_DUR` = 600.000 ms**: 大理 `商阳剑·刃影` `给自己的buff` đang 8.100.000 ms (bản HJ, ≈ 2,25 giờ).
  Kéo dài thêm không có nghĩa gì, chỉ làm nhiễu diff.
Ngoài ra vẫn giữ: cùng `逻辑ID` và cùng nhãn tại đúng ô thì mới so; không đổi dấu; `|giá trị mới| ≤ 3 × |mốc lớn nhất|`.

### 8.4 12 nhóm ô cấp 1–4 **cố ý không dựng** — lý do đầy đủ ở `p1-1/impact_p1fill_declined.txt` **[DK]**

Tóm tắt (để lần sau không phải tra lại từ đầu): **第八心法 logic 643/644** (13 kỹ năng × 4 ô = 52 ô) — tip 13 kỹ năng
giống hệt nhau và **cố ý không có số** ("持续时间根据…评分差值决定"), `cy_skill_logic_spec[643]/[644]` cũng ghi
"thiếu công thức điểm CY"; **星宿 变身男/女buff** (59700–59705) và **圣蚕护身 冰蚕buff** (59864–59867) — giữ nguyên
lý do của `trap-data_vi.md` mục 6.8 (đã kiểm lại 17/09: `std_impact_014:get_refix_model_id` vẫn **0 chỗ gọi**);
**唐门 千机变 37920** — giữ nguyên lý do mục 6.7; **恶人谷 生死由我** (12 ID) — tip **có** số (6/8/10 s, 3/4/5 lần)
nhưng **không có dòng mẫu nào** làm "受到致命一击时血量降低到1点" (quét cả bảng: chỉ có `42834 不死不休(状态)`
logic 38 = cờ và `63067 不死不休` logic 320 `命中率+=7`); **峨嵋 蚀心白骨爪·九阴** — `|效果1` cần **logic 11**
(thuộc tính cao nhất, cùng nút thắt với 大理 诸我圆满 ở mục 6.1 nhóm D), `|效果2` là DOT theo % máu **của người gây**;
**鬼谷 缩地成寸 42598** — `cy_skill_logic_spec[760]` xử lý bằng `teleport`, **không gửi impact**;
**绝情谷 吾道即真** — 刀意 là tài nguyên riêng của CY; **天山 冰凝霜华 53395–53398**; **大理 苦禅之心 32672** —
tip đủ số (+50 %, 90 s) nhưng mọi dòng thật dùng `基础伤害增强` đều **kèm mặt trái không có trong tip**
(`741–752 破釜沉舟` có `受到伤害=100`) hoặc là `逻辑ID ≥ 8000`; **慕容 彼道还施 / 剑归我道** — mỗi kỹ năng **hai** ô
thiếu mà tip mô tả mơ hồ nên không gán được ô nào là ô nào; và nhóm cuối là các ô mà tip chỉ ghi
"大量伤害/大量治疗/极大…" (禅棍封魔, 业火焚城, 斗犬十弄, 七星唤魂, 无处遁形 `效果1`, 六剑齐发 `效果1`, 形影无踪,
沙场点兵, 神机幻影, 饮鸩止渴 `效果1`).

### 8.5 Một lỗi của lệnh `fix` phát hiện trong lượt này — **chưa sửa**, để người điều phối quyết **[DK]**

峨嵋 `回天术` tpl 411 ô `|效果1`: cấp 1–4 (`57331–57334`) đang **20.000 ms**, cấp 5–16 (`57335–57346`) **4.000 ms**.
Tip ghi hai thời lượng cho hai thứ khác nhau: "施加**4秒**的护体效果" (khiên — chính là ô này) và
"使自身进入九阳炽脉状态，**持续20秒**" (ô `|变身buff`, đã đúng 20.000 ms ở mọi cấp 1–4). Luật "thời lượng chung"
của `fix` (mục 6) chỉ nhận khi tip có **đúng một** `持续N秒` — ở đây đúng một thật, nhưng nó là của **ô khác**
⇒ `fix` đã đổi nhầm `4.000 → 20.000` cho bốn dòng cấp 1–4. Dòng gốc (4.000 ms) chính là số khớp tip.
Chưa hoàn tác vì nằm ngoài hai việc được giao; cách sửa: đặt lại `总持续时间 = 4000` cho `57331–57334`.
**Bài học cho luật:** "tip có đúng một `持续N秒`" chưa đủ — phải kiểm thêm rằng **ô đang sửa là ô mà mệnh đề đó nói tới**
(mệnh đề "施加4秒的护体效果" không có chữ `持续` nên lọt lưới).

## 9. Cơ chế BIẾN THÂN + mở khoá `变身男/女buff` của 星宿, 17/09/2026, agent `transform-model` **[DK]**

Gỡ đúng hai nút mà mục 8.4 và `trap-data_vi.md` mục 6.8 đã dừng lại: (a) "`std_impact_014:get_refix_model_id`
**0 chỗ gọi**" và (b) "không chứng minh được `变身ID` tra vào bảng nào". **Cả hai đều gỡ được, và cả hai kết luận
cũ sai vì cùng một lý do: thứ cần tìm không xuất hiện dưới dạng chuỗi trong mã/bảng.**
Bằng chứng: `Build\Logs\2026-09-17-transform-model\` (`scripts\01..11`, `01..21-*.out.txt` + `.json`,
`20-transform_model.tsv`, `20-plan.json`, `20-declined.txt`, `22-apply.json`, `verify-*.json`,
`tests\transform_model_tests.lua` + `nil_clobber_proof.lua`, `30/31-*.out.txt`, `40-git-va-sha.txt`).
Công cụ mới **`Tools\server\transform_model.py`** (`plan|apply|verify`, sao lưu, idempotent).

### 9.1 `get_refix_model_id` được gọi **theo tên ghép động** — grep không thể thấy **[DK]**

```
human_attrib:get_attrib("model_id")            lualib/db/human_attrib.lua:2380…2461
  └ get_attrib_refix("model_id")               :2330  (chỉ tính lại khi cờ refix bẩn)
      └ imp_get_attrib_refix("model_id")       :2317  duyệt MỌI impact đang mang
          └ logic:get_refix(imp, key, value, human)
              └ base:get_refix                 services/scene/skill/impact_logic/base.lua:31-36
                    local fn = string.format("get_refix_%s", key)   ← TÊN HÀM GHÉP TỪ CHUỖI
                    → std_impact_014:get_refix_model_id(imp, args)  std_impact_014.lua:84
                          args.replace = imp.params["变身ID(-1为无效)"]
  → value = impact_skill_refix.replace         :2455  (`replace` thắng mọi cộng/nhân)
  → set_attrib{model_id = value}               :2536  → dirty_datas.model_id
send_refresh_attrib                            :2658  → GCCharBaseAttrib:set_model_id (cờ byte2 bit 0x10)
  → scene:broadcast(human, msg, true)          gửi cho cả bản thân lẫn người xung quanh
```

Cờ bẩn được đặt ở `base:mark_modified_attr_dirty` (`base.lua:18-28`): nó **quét metatable của logic**, lấy mọi
tên khớp `get_refix_(.+)` rồi gọi `obj:mark_attrib_refix_dirty(<đuôi>)`. Vì `class.lua` dựng instance bằng
`setmetatable({}, cls)` nên `getmetatable(self)` chính là bảng lớp, tức quét thấy đủ hàm.
Chỗ gọi: `character:on_impact_activated` (`character.lua:1497`, khi impact vào) và `character:remove_impact`
(`:1474`, khi gỡ). ⇒ **Không cần thêm `model` vào danh sách thuộc tính nào cả** — `model_id` đã nằm trong
`base_attribs`/`detail_attribs`/`db_attribs` và `default_char.lua:31` đặt sẵn `model_id = -1`.

Phía client: `GCCharBaseAttrib` đọc `m_nModelID` (`Packets/GCCharBaseAttrib.cpp:60`, chú thích `// 变形`) →
`pCharacterData->Set_ModelID` → `CObject_PlayerOther::CalcCharModelID` (`Obj_PlayerOther.cpp:753-760`):
*"经过变身 … 直接从模型定义表中读取模型名"* → `UpdateCharModel` → `DBC_CHARACTER_MODEL`.
`GMDataBase.cpp:151` cho biết bảng đó là **`CharModelEx.txt`**.

`model` (ô `set_model`, byte1 bit 0x1) là chủng/giới tính gốc, **không** phải biến thân; biến thân chỉ đi
qua `model_id`. `ride_model` đi cùng đường nhưng tra `CharMount` (`Obj_Character.cpp:1180`).

### 9.2 `变身ID` = chỉ số **`CharModelEx`** — kiểm chéo bằng 6 dòng CÓ THẬT **[DK `02-bianshen-source.out.txt`]**

Bảng sống có **112** dòng mang `变身ID ≠ -1`, **tất cả** đều `逻辑ID = 14`. Tra thẳng sang `CharModelEx` của
CY 3.71 thì tên model khớp tên hiệu ứng từng đôi một:

| dòng StandardImpact | `变身ID` | `CharModelEx` |
|---|---|---|
| `9575 变羊BUFF` | 804 | `白色山羊.obj` |
| `5934 变身：兔子` | 806 | `白兔.obj` |
| `5933 变身：乌龟` | 823 | `绿褐龟.obj` |
| `5926 变身：飘飘鸭` | 2003 | `黄鸭.obj` |
| `34847 变身冰块` / `34846 变身雪人` | 444 / 445 | `变身冰人.obj` / `变身雪人.obj` |
| `3958 神枢战甲` (唐门 技改 2025) | 8430 | `npc变身_2025唐门技改神枢战甲.obj` |

`MonsterAttrExTable` **không** phải bảng đích: 巨蝎 ở đó là `11534/11535/11555` (thuộc tính quái, dùng cho
`CalMonsterAwardExp`), còn cái client cần là chỉ số model.

### 9.3 Song ánh 6↔6 cho 巨蝎 **[DK `03-charmodel-scan.out.txt`, `04-cells-434-445.out.txt`, `05-tips.out.txt`]**

`CharModelEx` CY 3.71 có **đúng sáu** model 巨蝎, và `SkillData_V1` của server có **đúng sáu** ID còn thiếu,
cùng bố cục nam→nữ × 3 bậc:

| kỹ năng (mọi cấp 1–16 đều trỏ cùng ID) | `变身男buff` | `变身女buff` | model nam | model nữ |
|---|---|---|---|---|
| **434 神蝎百相** — triệu hồi, bậc 1 | **59700** | **59703** | 8676 `npc变身_2026星宿巨蝎男1级.obj` | 8679 `…女1级.obj` |
| **841 蝎行无阻** — tiến hoá lần 1, bậc 2 | **59701** | **59704** | 8677 `…男2级.obj` | 8680 `…女2级.obj` |
| **844 蝎行无阻** — tiến hoá lần 2, bậc 3 | **59702** | **59705** | 8678 `…男3级.obj` | 8681 `…女3级.obj` |

Tip 434 chốt số bậc: *"驱使巨蝎供自身骑乘，**持续10秒** … 使用蝎行无阻冲撞不少于3个目标可使巨蝎进化，**最多2次**"*
⇒ 1 + 2 = **3 bậc**. Tip 841/844 nói *"进化后**重置存在时间**且伤害提升"* ⇒ bậc sau dùng lại cùng thời lượng.
Ba bậc 毒螯势 `839/842/845` (毒攻 10/20/30 %) và 心如毒蝎 `840/843/846` (80/90/100 %) xác nhận lại cách đánh số
ba bậc của cả bộ chiêu 巨蝎.

Giới tính do **mã đã có** chọn: `skill_cy_spec:apply_gender` (`services/scene/skill/human/skill_cy_spec.lua:386-398`)
đọc `obj_me:get_model()` (0 = nam, 1 = nữ) rồi gửi ô tương ứng lên **bản thân**; `cy_skill_logic_spec[170]` và
`[173]` đã khai `gender = {male = '变身男buff', female = '变身女buff'}` từ trước. Nghĩa là **chỉ thiếu dòng dữ liệu**.

Tài sản client đã sẵn sàng **[DK `09-model-assets.out.txt`, `11-charmodel-rows.out.txt`]**: `all.obj` có đủ 6 khối
`<Object name="npc变身_2026星宿巨蝎…">` (30 locator, có `钳子特效点左/右`); `Model8Folder` có đủ 12 `.mesh`
+ 6 `.skeleton`; `Material7Folder` có texture; `CharModelEx` cột 9 của cả sáu dòng = **2799** →
`ActionSetFile.txt` = `npc_2026星宿变身.txt`, và bảng `ActionSet/ActionSet.txt` có **18** dòng cho bộ 2799.

### 9.4 Hai lỗi mã đã sửa (đều nhỏ, đều chặn đường) **[DK `tests\`]**

**(a) `nil` xoá mất biến thân — `std_impact_014.lua:84-96`.** `imp.params` chỉ chứa nhãn mà **chính dòng đó**
khai (`cfghelper:read_std_impact` đổ theo cặp `参数N说明`/`参数值`). Dòng logic 14 không khai `变身ID(-1为无效)`
cho `value = nil`, mà **`nil ~= -1` là TRUE** ⇒ bản cũ ghi `args.replace = nil` và **xoá** giá trị mà một impact
biến thân đứng trước trong danh sách vừa đặt. Đã đổi thành `if value and value ~= define.INVAILD_ID`
cho cả `get_refix_model_id` lẫn `get_refix_ride_model`.
Trên bảng sống có **2/2698** dòng logic 14 dính: `5700 坐骑：初级年兽` và `5702 坐骑：高级年兽` — **nhãn của chúng bị
hỏng** thành `变身ID(-2为无效)` / `变身ID(-0为无效)` (và `CanAction1标记，-2为无效`…), tức một lượt sửa số trước đây đã
thay `-1` thành `-2`/`-0` ngay trong TÊN nhãn. Hệ quả riêng của hai dòng đó: **hai tọa kỵ 年兽 này không bao giờ
hiện model** (ô `骑乘ID` cũng mất nhãn). **Chưa sửa** — sửa dòng cũ nằm ngoài phần được giao, xem mục 9.6.
`std_impact_326` và `std_impact_352` có **cùng lỗi** ở cùng hai hàm, chưa sửa (ngoài phạm vi ghi).

**(b) Gỡ buff xong client vẫn giữ hình biến thân — `character.lua` + `human.lua`.** Mọi đường gỡ đều là
`on_impact_fade_out(imp)` **rồi mới** `remove_impact(imp)` (`base:continuance_cal` `base.lua:156-158` khi hết giờ,
`dispel_hostility_impact`, `unregister_impact_by_sn`, `impact_on_damages`…). Nhưng `character:on_impact_fade_out`
gọi `send_refresh_attrib()` **khi impact CÒN trong danh sách** ⇒ `model_id` vẫn tính ra model biến thân; còn
`remove_impact` chỉ **đánh dấu bẩn** chứ không gửi gì. Người chơi đứng yên sẽ giữ hình con bọ cạp cho tới lần
`send_refresh_attrib` tình cờ sau đó. Đã thêm `character:refresh_attrib_after_remove_impact()` gọi ở cuối
`character:remove_impact` **và** `human:remove_impact` (human ghi đè hàm này), chỉ gửi khi
`human_attrib:has_attrib_refix_dirty()` (hàm mới, 3 dòng) trả `true` ⇒ impact không sửa thuộc tính thì không
thêm gói nào. Đây là lỗi của **cả lớp** thuộc tính kiểu `replace`: `model_id`, `ride_model`, `can_move`,
`can_action_1/2`, `stealth_level`, `unbreakable`.
Lối `skill_id == 21` (xuống ngựa, `scenecore.lua:2315-2320`) từ trước đã tự viết đúng thứ tự
`fade_out → remove → send_refresh_attrib` — nay là hành vi mặc định.

Đăng xuất/đăng nhập giữa lúc biến thân: **an toàn sẵn**. `model_id` **không** nằm trong `db_save_attribs`
(`human_attrib.lua:475`) nên giá trị biến thân không bao giờ ghi xuống DB — `db_attribs.model_id` luôn là `-1`.
Buff thì có lưu (`human:get_save_data` → `impact_list`) và nạp lại bằng `impact_data:init_from_db_data` →
`register_impact` → `on_impact_activated` → `mark_modified_attr_dirty` + `on_active` ⇒ tính lại đúng. Dòng mẫu
mang `下线仍然计时否 = 0` nên sau khi vào lại buff chạy nốt ≤ 10 s rồi tự hết (lưu ý: `character:impact_on_offline`
**không có chỗ gọi nào** trên server này, nên cờ `下线就消失否 = 1` hiện là cờ chết).

### 9.5 Sáu dòng đã dựng — mẫu `31577 蚩尤青龙驾驶BUFF`, đổi 4 ô **[DK `20-transform_model.tsv`, `21-new-rows-diff.json`]**

Server riêng HEAD `143e909`, **chỉ** `configs/StandardImpact.txt`: **27.824 → 27.830** (+6), `changed = 0`.
sha256 `03edf7a5…` → **`e03ad381…`**. Sao lưu `R/backups/transform-model-20260917T052848Z`.

Dòng mẫu chọn theo ba điều kiện, kiểm trên **cả 30 dòng logic 14 có `变身ID`**: (1) `CanAction1/2 = -1`
(bắt buộc — tip 434 nói "骑乘状态下只能使用巨蝎技能", tức vẫn phải bấm được chiêu; 5942/5943 新圣火变身（男/女）
và họ `变身：*` đều đặt `CanAction = 0`, khoá sạch kỹ năng), (2) `瞬发效果ID = -1` (không mượn hiệu ứng hình ảnh
của chiêu khác — `3958 神枢战甲` mang `9808` của 唐门), (3) có mặt ở mốc `6ca25a8` và y nguyên tới HEAD.
Chỉ còn họ `X驾驶BUFF` (`31577`–`31586`) — và đúng nghĩa: "trạng thái đang cưỡi con X".

| ô | mẫu `31577` | mới | nguồn |
|---|---|---|---|
| `Data_Index` | 31577 | 59700…59705 | ô `变身男/女buff` của SkillData (công cụ kiểm lại từng cấp) |
| `效果名称$1$` | 蚩尤青龙驾驶BUFF | `神蝎百相/蝎行无阻（CY推导变身…）` | khuôn tên của `59706 神蝎百相（CY推导免控）` |
| `变身ID(-1为无效)` (cột 49) | 2261 | 8676…8681 | `CharModelEx` CY, **tên model phải khớp** (verify kiểm lại) |
| `总持续时间(毫秒)` | −1 | **10000** | tip 434 "持续**10秒**" (đúng một `持续N秒`, và nó nói về chính trạng thái cưỡi) |

Mọi ô còn lại chép nguyên. Đáng nhớ: `互斥ID = 1025` dùng chung cả sáu ⇒ **ba bậc thay nhau** và nam/nữ loại
trừ nhau (`can_impactA_replace_impactB` là `>=`, `互斥优先级 = 160` bằng nhau nên bậc sau thắng) — đúng cơ chế
"进化后重置存在时间"; hệ quả kèm theo là nó cũng loại trừ với 蚩尤/炎黄 X驾驶BUFF (chấp nhận được: một lúc chỉ
cưỡi một thứ). `是否可以被技能驱散 = 0`, `是否可以被手动取消 = 0`, `死后是否保留 = 0`, `影响性质 = 0`,
`分类ID = -1` (**cố ý không đặt 99** — class 99 là `define.RIDE_IMPACT_ID`, đặt vào đó thì nút xuống ngựa
(skill 21) sẽ huỷ được biến thân, CY không cho).

**Kiểm sau khi áp [DK `verify-*.json`, `30-tests.out.txt`, `10-luac.out.txt`]:**
`transform_model.py verify --base 6ca25a8` → `ok true`, `errors []`, `added_mine` đủ 6, `changed 0`,
`still_missing []`; `impact_data.py verify` → `errors []`, **`cyfour_unmapped 0`**, `changed 0`;
`trap_impacts.py verify` → `errors []`, **`cyfour_unmapped 0`**, `extra_still_missing` rụng 59700/59703
(còn `37920, 59168, 59169, 59205, 59879`); `server_impact.py verify` → `ok true`, `errors []`, 27.830×81,
`se_not_in_cy_client 0`, `logic_not_registered []`, tham chiếu phân loại **93,759 %**, luac 25/25, test Lua 19/19.
`luac5.4 -p` 4/4 file Lua đã sửa. Test đơn vị riêng `tests/transform_model_tests.lua` **13/13 đạt**
(nạp `base.lua` + `std_impact_014.lua` THẬT, và `human_attrib.lua` thật trong hộp cát `require`).

### 9.6 Vẫn KHÔNG dựng — và lý do mới, chắc hơn **[DK `20-declined.txt`]**

**`59864`–`59879` 圣蚕护身 445 `冰蚕buff`: KHÔNG phải biến thân.** Ba dữ kiện độc lập:
(1) model 冰蚕 trong `CharModelEx` là `8691/8692/8693 npc怪_2026星宿冰蚕1级/2级/3级` — tiền tố **`npc怪_`**
(thực thể quái), khác hẳn `npc变身_` của cả sáu model 巨蝎; (2) `SkillData` của 445 **chỉ có một ô duy nhất**
mỗi cấp (`冰蚕buff`), không có `变身男/女buff` nào; (3) tip mô tả hành vi của **con** 冰蚕 (hút hiệu ứng xấu, tốn
12 % máu, 55 % tiến hoá, không tiến hoá thì tự nổ, bậc 3 xoá sạch rồi biến mất sau 3 s) chứ không nói buff làm gì.
⇒ Đây là việc của **hệ TRIỆU HỒI** (như `skill-summon` đã làm cho 毒蟾功 174 với ô `召唤物`), không phải logic 14.
Lý do cũ ở mục 8.4 ("tip không cho biết bản thân buff làm gì") vẫn đúng, nay có thêm bằng chứng tiền tố model.

**Chưa sửa, để người điều phối quyết:**
1. **`5700`/`5702 坐骑：年兽` hỏng NHÃN tham số** (`-2为无效`/`-0为无效`, xem 9.4a) ⇒ hai tọa kỵ đó không hiện model.
   Sửa = đặt lại nhãn cho đúng hai dòng; nhưng mọi `verify` hiện coi "đổi dòng cũ" là LỖI nên phải làm thành một
   lượt riêng có khai báo. Nên quét thêm: lỗi `-1` → `-2`/`-0` này có thể còn ở nhãn của bảng khác.
2. **`std_impact_326` / `std_impact_352`** có cùng lỗi `nil` ở `get_refix_model_id`/`get_refix_ride_model`.
3. **Ô `分类ID` của sáu dòng mới** để `-1` theo dòng mẫu; nếu CY thật cho phép "xuống bọ cạp" thì đổi thành 99.

## 10. Ô impact cấp 1–4 — đo lại và **đóng** các nhóm chưa có nguồn, 17/09/2026, agent `skill-data-final` **[DK]**

Nối tiếp mục 8 (agent `impact-data-2`). Lượt này **không thêm nhóm P1 nào** vào `impact_data.py`: đã tra lại từng
nhóm còn lại bằng **ba nguồn mới** và cả ba đều cho **kết quả âm tính có bằng chứng**. Bảng chỉ thay đổi vì 17 dòng
桃花岛 của `taohua_impacts.py` (xem `trap-data_vi.md` mục 8), trong đó 4 ô thuộc cấp 1–4.
Bằng chứng: `Build\Logs\2026-09-17-skill-data-final\` (`10-p1-live.txt`, `11-gmname.txt`, `15-neighbours.txt`,
`16-checks.txt`, `17-dibat.txt`, `18-pilisuo.txt`, `20-p1-remain-sau.txt`).

### 10.1 Số đo trên **bảng sống** (không phải trên mốc git) **[DK `20-p1-remain-sau.txt`]**

| Thước đo ô cấp 1–4 của 15 phái thiếu dòng | Sau mục 8 | Sau `transform-model` | **Sau lượt này** |
|---|---|---|---|
| theo (template, cấp, cột) | 188 | 188 | **180** |
| theo (SkillData, cột) — thước đo của mục 0 | 140 | 136 | **132** |
| ID impact thiếu | 115 | 121 (+12 ô 桃花岛 của dải 64000 sau `impact_recollide`, −6 do `transform-model`) | **116** |
| nhóm (kỹ năng × ô) | 47 | 46 | **45** |

Con số **140** trong tài liệu trước là mốc trước khi `transform-model` dựng `59700`–`59705`; đo lại trên bảng sống
ngày 17/09 là **136**, và sau lượt này còn **132**.

### 10.2 Ba nguồn mới đã thử — vì sao không thêm được nhóm nào **[DK]**

1. **Tên CY thật của ID impact** (`GMVisible_Impact.txt` của client CY 3.71, luật `gmname`): 128/456 ID thiếu có
   tên, nhưng **không ID nào** có dòng cùng tên trong bảng server [DK `11-gmname.txt`]. Đáng ghi lại vì nó **đóng**
   nhóm lớn nhất: 13 kỹ năng `第八心法` (logic 643/644, 52 ô) mang tên CY là **`<phái>恶蟒缠身`** (龙盘斗里, 泗水围城,
   紫雾扰心, 碎舟入渊) và **`<phái>第八心法控制`** (六合禁域, 步罡踏斗, 良夜游, 潮生云灭, 容海川, 意长流, 噬魂九淬,
   缚魂狂镰, 万宿辰光). Quét cả bảng: **0 dòng** nào có tên chứa `恶蟒`, `恶蛟` hay `缠身` [DK `16-checks.txt`]
   ⇒ impact này là **hàng CY mới hoàn toàn**, không phải "chưa tìm ra dòng". Bổ sung dữ kiện cho người cài 643/644:
   `SkillData` của chúng mang `|效果下限百分比1 = **−99**` và `|效果上限百分比1 = **300**` ở **mọi cấp, mọi phái**
   [DK `17-dibat.txt`] — tức thời lượng = (thời lượng gốc của dòng impact) × (1 %…400 %) theo chênh lệch điểm; vẫn
   cần **thời lượng gốc**, thứ mà không nguồn nào cho.
2. **Dòng thật lân cận** (±6 ID quanh mỗi ô thiếu, phân biệt `[GOC]` = có ở mốc `6ca25a8` với `[suy]` = do agent
   trước sinh) [DK `15-neighbours.txt`]: mọi láng giềng đều là dòng **khống chế** (定身/封穴/散功/失明) đã dựng từ
   trước; các ô còn thiếu đúng là các ô **sát thương/đặc thù** mà tip chỉ ghi "大量伤害/极大…". Không lộ dòng mẫu nào.
3. **Khối CY có thật trong bảng** (phát hiện của lượt này, xem `trap-data_vi.md` mục 8.1): chỉ tồn tại cho **桃花岛**
   (`4260–4560`) vì `cy_four_combat` cần. Không có khối tương ứng cho 少林/明教/丐帮/峨嵋/慕容/唐门/鬼谷/绝情谷/恶人谷.

### 10.3 Một ô tưởng làm được nhưng **không**: `技能集合ID` **[DK `18-pilisuo.txt`]**

`ImpactPreShow.txt` của client CY có dòng 241 mô tả **霹雳锁**: "受到囚禁，可以攻击，但无法移动，**无法使用位移技能**"
— nghe như dòng mẫu sẵn cho vùng 冰雾 của 阳关三叠. Nhưng trong bảng server, 16 dòng mang tên 霹雳锁 đều là
`霹雳锁（CY推导麻痹）` (dòng **suy** của lượt trước, logic 14, 500 ms) và **không có dòng nào SE = 9802**.
Quét toàn bảng: chỉ **ba** giá trị `技能集合ID` đang được dùng — **64** (hồi thành/ẩn thân/cưỡi), **286** (寻影),
**56** (禅武印). Kết luận mục 6.3 của `trap-data_vi.md` giữ nguyên, nay có thêm số liệu.

### 10.4 Còn lại — xếp theo việc phải làm trước

| Nhóm | Chặn ở đâu |
|---|---|
| `第八心法` 13 kỹ năng (52 ô) | **công thức điểm CY** cho logic 643/644 + thời lượng gốc; tên CY xác nhận là impact mới |
| 桃花岛 3820/3822 (19 ID còn lại của dải 64000) | **ánh xạ vị trí `cy_four`** cho 4400/4543/4549 (`trap-data_vi.md` mục 8.4) |
| `生死由我` (12 ID), `蚀心白骨爪·九阴`, `苦禅之心`, `彼道还施`, `剑归我道`, `圣蚕护身`, `吾道即真`, `千机变`, `冰凝霜华`, `缩地成寸` | giữ nguyên lý do mục 8.4 — đã kiểm lại bằng ba nguồn trên, không đổi |
| Nhóm tip "大量伤害/大量治疗/极大" | cần bảng số của CY, không phải việc suy từ dòng mẫu |
