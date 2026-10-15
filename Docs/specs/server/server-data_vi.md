# server-data — impact vật phẩm, tỉ lệ cường hoá, bảng tông môn (18/09/2026)

Ký hiệu: **[DK]** dữ kiện đọc được từ mã/bảng (có đường dẫn); **[SL]** suy luận chưa kiểm;
**[LIVE]** đã đo trên server riêng `/home/ubuntu/cys-test-20260913` (login 15733 / game 15734).

Bằng chứng: `Build/Logs/2026-09-17-server-data/`.
Công cụ: `Tools/server/impact_map.py` (`survey|plan|apply|verify|copy85|revert`),
`Tools/server/enhance_rate.py` (`audit|apply|verify|revert|analyze`),
`Tools/server/zongmen_tables.py`, `Tools/server/impact_refs.py` (chỉ đọc).
Áp lại: `Tools/reapply/server-data/90-server-data.py plan|apply|verify`.
Tài khoản đo: **test03 / CYTest03 (GUID 200004)**, cấp 15, phái 9.

---

## 0. Ba việc, ba kết luận một dòng

| # | Việc | Kết luận |
|---|---|---|
| 1 | 329 ID impact vật phẩm đổi nghĩa | **SỬA XONG.** Trục CY của khối "đồ dùng" là `ID + 30000`; 341 ô trong 341 file script đã trỏ lại. Nghiệm thu live 11/11 |
| 2 | Tỉ lệ cường hoá là bình phương cột bảng | **SỬA XONG.** Lỗi có từ bản 0.85 gốc. Đo trước: số mũ `a = 1,79`, KTC 95 % `[1,46; 2,21]` |
| 3 | Ba bảng tông môn thiếu phía server | **ĐÃ NHẬP, nhưng VÔ HIỆU về chức năng** — không dòng mã nào trên server đọc chúng. Xem mục 3.3 |
| 4 | "Chỗ thứ tư" của lớp lỗi `ed09b4f` | **CÓ THẬT.** 300 lời gọi `SendSpecificImpactToUnit` mang hằng số: sửa 2 ô theo tên+logic, chép 14 dòng 0.85, 85 ô để nguyên có lý do. Và một **báo động giả 5.569 ô** do chính công cụ tạo ra, đã truy ra và loại. Xem mục 4 |

---

## 1. 329 ID impact vật phẩm — trục ID của CY là `+ 30000`

### 1.1 Hiện tượng đã đo trước đó

Agent `item-live` đo live 17/09: mua 大理回城符 `30501004` bằng vàng, dùng → **`hp 2250 → 2219 (−31)`,
phù bị tiêu, `sceneid` **vẫn 0** (không dịch chuyển)**. Nguyên nhân: `item_4831.lua` gửi
`LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 4831, 0)` — gửi cho **chính người dùng** —
nhưng trong bảng CY, ID 4831 không còn là 回城符.

### 1.2 Bằng chứng gốc [DK]

| bảng | dòng 4831 |
|---|---|
| `/home/ubuntu/configs/StandardImpact.txt` (0.85) | `大理回城符`, `逻辑ID 9`, tham số `场景ID=2, X=160, Z=160` |
| `R/configs/StandardImpact.txt` (CY) | `宁闻不墨一段`, `逻辑ID 3` (**sát thương**) |
| `R/configs/StandardImpact.txt` dòng **34831** | `大理回城符`, `逻辑ID 9`, tham số `场景ID=2, X=160, Z=160` |

Tức **bảng CY vẫn giữ nguyên hiệu ứng của 0.85, chỉ dời sang `ID + 30000`**, còn ID cũ CY gán cho
chiêu thức chiến đấu. Script vật phẩm là mã 0.85 nên vẫn mang ID cũ.

Đây là **cùng một lớp lỗi** với `Exterior_Ride` (commit `ed09b4f`, xem `ride-data_vi.md`) và với
`cyfour_params.py` (xem `cy-four-mapping_vi.md` mục 6): **đổi trục ID của bảng đích mà không đổi các
ô trỏ tới bảng đó**. Cách đo đúng là so theo **TÊN + `逻辑ID`**, không theo ID.

### 1.3 Quy mô đo được [DK]

Quét mọi ô `g_Impact1/2` dưới `Game_2/Script/` (`impact_map.py survey`):

| | số |
|---|---|
| ô `g_Impact1/2` | **716** (trong 545 giá trị khác nhau) |
| ID **đổi nghĩa** (có ở cả hai bảng, khác tên) | **329** → **341 ô**, **341 file** |
| ID cùng tên ở cả hai bảng (không phải lỗi) | 185 |
| ID **không có dòng ở bảng 0.85** (không biết nghĩa gốc) | 31 — xem 1.6 |

341 ô nằm trong 341 file: **340 file `obj/commonitem/item_*.lua`** + `event/newhuodong/QiXiFlower*.lua`
(cùng dùng `g_Impact1 = 4918` 送花).

### 1.4 LUẬT SỬA — bốn điều kiện, sai một là bỏ ô

Chỉ đổi `OLD → NEW` khi **cả bốn** đúng, kiểm trên bảng **SỐNG** (không dùng bản `git show`):

1. `OLD` có dòng ở **cả hai** bảng (0.85 và CY);
2. hai dòng đó **khác tên** ⇒ ID thật sự đã đổi nghĩa;
3. `NEW = OLD + 30000` có dòng trong bảng CY, **cùng `效果名称`** và **cùng `逻辑ID`** với dòng 0.85 của `OLD`;
   *(dự phòng: nếu không có dòng `+30000` thì chấp nhận **đúng MỘT** dòng CY cùng tên + cùng logic)*
4. `NEW` không phải là một giá trị cũng nằm trong bảng ánh xạ (chống chạy hai lần).

Kết quả áp luật: **328/329 giải bằng `+30000`**, **1/329 bằng luật dự phòng**
(`58 黄金马鞍加速 → 86`; bảng CY không có dòng 30058). Phân bố hiệu số: `{30000: 328, 28: 1}`.

**Mức độ trùng khớp ngoài tên + logic**: **327/329 trùng BYTE ở cả 79 cột còn lại**; hai ngoại lệ là
`4835 复活药 → 34835` (CY chỉnh lại `互斥优先级`, hai ô `参数值` 100→50 và 50→40 — dùng bản CY là đúng
theo luật "mọi thứ như CY") và `58 → 86` (`参数值` 30→20).

Kiểm chéo 10 ô ngẫu nhiên (seed cố định 20260918, đã loại nhóm phù hồi thành):
`Build/Logs/2026-09-17-server-data/spotcheck-10.txt` — **10/10 cùng tên + cùng `逻辑ID`**.

### 1.5 VÌ SAO SỬA SCRIPT CHỨ KHÔNG SỬA BẢNG

Vì ID cũ **đang được CY dùng thật**: 4831 là `宁闻不墨一段` của một chiêu CY; 3501 là `横剑疆场`;
3711 là `万箭齐发`. Ghi đè dòng đó để "trả lại" nghĩa 0.85 sẽ **phá chiêu thức CY** — đổi một lỗi
lấy một lỗi to hơn. Bảng là điểm cố định; ô trỏ tới bảng mới là thứ phải sửa.

Đường ngược lại (chép dòng 0.85 sang ID mới) cũng không cần: **bảng CY đã có sẵn đủ dòng**.

### 1.6 CÒN LẠI — 31 ID không tra được nghĩa gốc, CỐ Ý KHÔNG SỬA

`item_4901..4948`, `item_136`, `item_5907`, `item_4931`, `item_340001`: bảng 0.85 **không có** dòng
cho những ID này, nên **không có gì để so tên**. Rất nhiều trong số đó có dòng `+30000` trông rất
đúng (`4930 → 34930 结婚烟花1`, `4920 → 34920 中字礼花`, `4901 → 34901 送花`), nhưng đó là **suy diễn
từ quy tắc**, không phải bằng chứng — và luật của dự án là không cộng hằng số mà không kiểm tên.

**Đã thử một nguồn bằng chứng thứ hai và nó KHÔNG cho kết quả**: đối chiếu tên VẬT PHẨM dùng script
đó với tên dòng CY ở `+30000`. Chuỗi liên kết thật là
`CommonItem.脚本编号 (cột 13) → scripts.lua[id] → đường dẫn file` **[DK]** — ví dụ item `30501004`
có `脚本编号 = 334831`, `scripts.lua[334831] = scripts.obj.commonitem.item_4831` (số `33xxxx` là quy
ước đánh số script của 0.85, **không** liên quan tới phép dời `+30000`; bản 0.85 gốc cũng ghi
`334831`). Chạy chuỗi đó cho 31 ID trên: **0/31 có vật phẩm nào trỏ tới** ⇒ đó là script chết, không
ai với tới được, và cũng không có tên vật phẩm để đối chiếu.

⇒ Để nguyên, ghi ra đây. Muốn sửa thì phải có bảng `StandardImpact` của một bản 0.85/HJ khác có
những ID đó, rồi chạy lại `impact_map.py` — công cụ tự nhận ra và chỉ thêm phần mới.

Hai ID `4931` và `340001` còn **thiếu dòng ở cả hai bảng** (đã có trong phần "chưa làm" của
`item-live`); chúng là 2 ô duy nhất trong 716 ô còn trỏ vào dòng không tồn tại.

### 1.7 Vật phẩm THẬT bị ảnh hưởng: 74/329 ID, 75 vật phẩm

Qua chuỗi `CommonItem.脚本编号 → scripts.lua → file`: **74 trong 329 ID** có vật phẩm thật trỏ tới,
tổng **75 vật phẩm**. Danh sách đầy đủ kèm tên vật phẩm, cấp, hiệu ứng cũ và mới:
`Build/Logs/2026-09-17-server-data/reachable-items.txt`. 255 ID còn lại là script không vật phẩm nào
dùng — sửa vẫn đúng, chỉ là không ai thấy.

### 1.8 Nghiệm thu LIVE — 11/11 [LIVE]

Server đã nạp bản sửa từ lần khởi động **00:09:11** (18/09). Bàn đo: test03, cảnh Lạc Dương.

**Phù hồi thành `30501004`** (`Build/Logs/2026-09-17-server-data/items/snap-01/02-*.json`):

| | trước | sau |
|---|---|---|
| `sceneid` | **0** (Lạc Dương) | **2** (Đại Lý) |
| `world_pos` | (159, 288) | **(160, 160)** |
| `hp` | 2000 / 2250 | **2000** — không đổi |
| số phù trong túi | 3 | 2 |

Cảnh 2 và toạ độ (160, 160) **đúng bằng ba tham số** của dòng CY `34831`. So với đo của `item-live`
trước khi sửa: `−31 HP` và `sceneid` không đổi.

**10 vật phẩm khác**, mỗi món một phiên bot, đọc `impact_list` trong Mongo sau mỗi phiên
(`items/snap-10-*.json`). Cả 10 đều để lại **đúng dòng CY**, và `hp` giữ nguyên 2000 suốt 10 phiên:

| vật phẩm | ID cũ → mới | dòng CY nhận được | số đo |
|---|---|---|---|
| `30004001` 裂石散 | 3501 → **33501** | 药品，增加力量5点 (logic 15) | |
| `30004011` 筋骨散 | 3601 → **33601** | 药品，增加体力5点 (logic 15) | **`hp_max` 2250 → 2525** |
| `30004006` 阴月散 | 3701 → **33701** | 药品，增加灵力5点 (logic 15) | **`mp_max` 904 → 1049** |
| `30004016` 轻身散 | 3801 → **33801** | 药品，增加身法5点 | |
| `30004021` 清心散 | 3901 → **33901** | 药品，增加定力5点 | |
| `30005001` 龟甲散 | 4001 → **34001** | 药品，增加物理防御20点 (logic 11) | |
| `30005006` 清鳞散 | 4011 → **34011** | 药品，增加魔法防御20点 | |
| `30005011` 翠波散 | 4021 → **34021** | 药品，增加冰防20点 | |
| `30005013` 雷泽散 | 4032 → **34032** | 药品，增加玄防20点 | |
| `30008001` 出师糖豆 | 3562 → **33562** | 中级通用谷物增加体力的菜肴 | **`hp_max` 2525 → 3350** |

### 1.9 Ô impact trong BẢNG vật phẩm — đã soát, KHÔNG phải sửa

| bảng | cột | kết quả |
|---|---|---|
| `EquipBase.txt` | 19 `技能ID：装备点为武器时标识效果ID` | **2.907 ô, 0 ô trỏ vào dòng thiếu.** Bảng này đã là bảng CY ⇒ ô của nó đã ở trục CY. 26 ID có tên khác tên 0.85 nhưng **không** cái nào có dòng `+30000` ⇒ đó là ID CY thật, **không phải lỗi** |
| `SkillTemplate_V1.txt` | 30 `珍兽技能产生的效果ID` | 4 ô, 0 thiếu |
| `MonsterAttrExTable.txt` | 42, 43 (免疫ID) | 0 ô có giá trị |
| `CommonItem.txt` | — | **không có cột impact** (chỉ có `脚本编号`, `技能编号`) |
| `PetEquipBase.txt` | 16 | **136/136 ô trỏ vào dòng KHÔNG tồn tại** (dải 8100–8343, thiếu ở cả hai bảng). Lỗ thật, **không thuộc lớp lỗi này** (không có nguồn để chép), thuộc nhánh trân thú |

Đây chính là chỗ dễ kết luận sai: nếu chỉ so `EquipBase` theo tên với bảng 0.85 thì sẽ "phát hiện"
26 ID hỏng và sửa hỏng thật. Luật cứu mạng: **bảng nào đã là bảng CY thì ô của nó đã ở trục CY**.

### 1.10 Phát hiện phụ: 159 dòng `item-live` chép vào là THỪA

`item_impacts.py copy85` (17/09) chép 159 dòng thiếu từ bảng 0.85 vào bảng CY tại **ID gốc**. Đo lại:
cả **159/159** dòng đó **đã có sẵn trong bảng CY ở `ID + 30000`, trùng byte từng cột**. Việc chép
không sai (đã chứng minh chạy được: thuốc máu `hp 400 → 850`), chỉ là **không cần thiết**.

**Cố ý KHÔNG gỡ**: chúng đang chạy đúng, gỡ là đổi một thứ đã chứng minh lấy một thứ chưa chứng minh.
Ai muốn dọn thì chạy `impact_map.py` với luật mở rộng cho nhóm "cùng tên" rồi mới xoá 159 dòng — và
phải đo lại toàn bộ mục 1.8.

---

## 2. Tỉ lệ thành công cường hoá = BÌNH PHƯƠNG cột bảng

### 2.1 Mã lỗi [DK]

`GameServer/lualib/script_base.lua`, trong `LuaFnEquipEnhance` (bản gốc, ~dòng 3775):

```lua
local currate = downlvinfo.odd * losecount
local sjrate = math.random(10000)
if sjrate <= currate then              -- lần 1: P = currate/10000
    sjrate = math.random(10000)
    if sjrate > 10000 - currate then   -- lần 2: P = currate/10000  (viết ngược lại cho khác kiểu)
        succ = true
```

Hai lần quay độc lập, **cùng xác suất** ⇒ `P = (currate/10000)²`.
Cấp 1 (`odd = 788`): **0,62 %** thay vì 7,88 %.

### 2.2 Ba dấu hiệu nói đây là LỖI, không phải luật chơi

1. **Chính server khai báo tỉ lệ TUYẾN TÍNH cho người chơi.** `LuaFnUpdateEquipEnhanceInfo` (cùng
   file) gửi lên khung `117043021`: `qhrate` (= `odd`), `losecount`, và
   `needcount = math.ceil((10000 - odd*losecount) / odd)` — "còn bao nhiêu lần hỏng nữa là chắc chắn
   thành công". Công thức `needcount` **chỉ đúng khi quay MỘT lần** ở tỉ lệ `currate`.
2. `sjrate <= currate` và `sjrate > 10000 - currate` là **cùng một phép thử viết hai kiểu**. Lồng một
   điều kiện vào trong điều kiện tương đương của chính nó là dấu vân của một lần gộp mã, không phải
   một luật "hai cửa" (luật hai cửa thật sẽ dùng **hai tỉ lệ khác nhau**).
3. Bản server GỐC `/home/ubuntu` **giống hệt từng byte** (`diff` cả hàm ⇒ rỗng) ⇒ lỗi có từ 0.85,
   **không phải** do CY-Source gây ra. Sửa ở đây là sửa lỗi cũ, và `revert` trả về nguyên trạng 0.85
   bằng một lệnh.

### 2.3 Cách đo — vì sao không đo bằng "tỉ lệ thô"

`losecount` là bộ đếm an ủi lưu **trên món** (`set_param(9, …)`, tức hai byte `unknow_4[10..11]`),
tăng sau mỗi lần hỏng và **về 0 sau mỗi lần thành công** ⇒ xác suất **không** cố định giữa các lượt.
Chia "số thành công / số lượt" là vô nghĩa.

Cách đúng: ghi **`currate` của từng lượt** rồi khớp mô hình `p = (currate/10000)^a`.
`a = 1` ⇔ đúng cột bảng; `a = 2` ⇔ bình phương. Ước lượng `a` bằng cực đại khả dĩ, khoảng tin cậy
95 % bằng **profile likelihood** (ngưỡng `χ²₁/2 = 1,9207`). Đây là phép kiểm gộp được mọi lượt dù
`currate` khác nhau — hiệu quả hơn nhiều so với nhìn riêng lượt đầu.

Công cụ: `enhance_rate.py apply --stage probe` thêm đúng một dòng
`skynet.error("[CYS-ENH] rolls= odd= try= currate= r1= r2= succ= qhlv=")`, **giữ nguyên luật chơi**;
`--stage fix` đổi sang một lần quay và **giữ dòng log** ⇒ trước và sau dùng **cùng một dụng cụ đo**.

Bàn đo (`Build/Logs/2026-09-17-server-data/tools/enh_bench.py` + `run_enh.ps1`): test03, vũ khí
`10106000` 桦木弩 cấp 1 (`odd` cấp 1 = **788**, tức cột bảng **7,88 %**), tinh hoa `30900005`, 4 lô ×
50 lượt, **reset `enhancement_level = 0` và `losecount = 0` trước mỗi lô** để mọi lô bắt đầu như nhau.

### 2.4 Kết quả [LIVE]

`truoc-cys-enh.log` (203 dòng, server run 00:09) và `sau-cys-enh.log` (200 dòng, server run 03:51 —
cả 200 dòng đều `rolls=1`, **một phiên server duy nhất**, không trộn trước/sau).

| | **TRƯỚC** (203 lượt) | **SAU** (200 lượt) |
|---|---|---|
| số thành công | **22** | **29** |
| kỳ vọng nếu **đúng cột bảng** | **48,7** | **30,3** |
| kỳ vọng nếu **bình phương** | 16,5 | 6,6 |
| `a` ước lượng | **1,79** | **1,045** |
| **KTC 95 % của `a`** | **[1,46 ; 2,21]** — chứa 2, loại 1 | **[0,87 ; 1,26]** — chứa 1, **loại 2** |
| log tỉ số khả dĩ (tt − bp) | **−14,72** | **+23,93** |
| riêng lượt `try = 1` (`currate = 788`) | **0 / 27** = 0 % | **3 / 33 = 9,09 %** (cột bảng 7,88 %) |

**Hai khoảng tin cậy KHÔNG chồng nhau** — đó là bằng chứng, không phải cảm giác.

**ĐỪNG so "29 thành công" với "48,7".** Con số 48,7 là kỳ vọng tính trên **dãy `currate` của lượt
TRƯỚC**. Sau khi sửa, thành công đến sớm hơn ⇒ `losecount` bị reset thường xuyên hơn ⇒ `currate`
trung bình **thấp hơn** ⇒ kỳ vọng của chính dãy đó là **30,3**. Kỳ vọng phải tính trên dãy `currate`
của chính lượt đo; bê số từ lượt khác sang là so hai thứ khác nhau.

### 2.5 Vòng chơi thật sau khi vá [LIVE]

`loop-console.txt`, 08:32:33 → 08:33:39 (5 phiên bot nối tiếp; bot thoát ngay khi xong pha nên tổng
**66 giây**, không phải 5 phút — `--dwell-ms` chỉ là trần):

- **5 lượt cường hoá**, cả 5 đều ghi `rolls=1` ⇒ bản vá đang chạy thật sau restart;
- **5 vật phẩm** khác nhau, cả 5 phiên `uses=1/1`, bot `code=0`;
- log server khoảng 08:32–08:39: **0 `traceback`, 0 dòng `[E]`**, 0 `attempt to`,
  0 `not configured`, 0 `unmapped positional`, 0 `missing selected impact`.

---

## 3. Ba bảng tông môn — đã nhập, và vì sao nó KHÔNG mở khoá được gì

### 3.1 Nguồn đúng [DK]

**Không** lấy từ `Assets/CanonicalCY/Data/ConfigFolder/` — ở đó chúng là **DBC nhị phân `00CCBBDD`**,
không phải bảng text của server. Nguồn đúng là bản đổ text của CY:
`C:\TLBB\085\Tools\DATA NEW\DataCY31-08-26\Config\` — đã là tab + GBK + CRLF + hai dòng tiêu đề.

| bảng | cột × dòng | sha256 nguồn |
|---|---|---|
| `TalentInfo.txt` | 25 × 15 | `63275cf0…` |
| `ZongmenTalent.txt` | 37 × 255 (ID 1..257) | `cb60d95c…` |
| `TalentLayerLevel.txt` | 6 × 10 | `43a2441b…` |

Cả ba: GBK toàn file, mọi dòng đủ cột, cột 0 tăng dần không trùng. `verify` trùng sha sau chuẩn hoá.

### 3.2 BẪY `CharTitleNew` KHÔNG áp dụng ở đây

Bẫy đó (server `8 STRING, 9 INT` ↔ CY `8 INT, 9 STRING`) xảy ra khi **trộn dòng CY vào một bảng
server ĐÃ CÓ**. Ba bảng này server **chưa có**, nên đây là chép **cả file** — không có bảng nào để
đối chiếu kiểu, và cũng không có gì để lệch. Đã kiểm: cả ba đều **không có dòng tên cột** (DBC nhị
phân của CY chỉ lưu KIỂU cột: `0 = INT`, `2 = STRING`), nên dòng 1 lặp lại dòng kiểu. Đó là sự thật
của dữ liệu CY, không phải lỗi của bản đổ.

### 3.3 TỰ PHẢN BIỆN — việc nhập này VÔ HIỆU về chức năng

- `grep -rn 'TalentInfo|ZongmenTalent|TalentLayerLevel'` trên **toàn bộ** cây server → **0 dòng**.
- `cfghelper.lua` có đúng **178** lời gọi `read:load(...)`; không cái nào là ba bảng này.
- ⇒ Server **không mở** ba file đó. "Nạp 0 lỗi" là **hiển nhiên đúng** và **không chứng minh gì**.
- ⇒ Hàm host tông môn của nhánh `host-2` nằm phía **client** và đọc `ConfigFolder` của client, nơi
  **đã có đủ cả ba bảng** ⇒ việc nhập này **không** mở khoá gì cho `host-2`.

Giữ lại vì: vô hại (không ai đọc), có sao lưu, và người viết phần tông môn phía server sau này có
sẵn bảng đúng định dạng, cùng bộ số với client.

### 3.4 CHIỀU NGƯỢC LẠI mới là chiều đang kẹt — ghi nhận

`SectDesc.txt` (985 dòng) và `SectInfo.txt` (985 dòng) **có trên server** (và **được đọc thật**:
`cfghelper.lua:4630` / `:4561`, `talentenginer:loadall` lấy `sect_desc` làm `talent_config`), nhưng
**không có** trong bản đổ CY lẫn trong `Assets/CanonicalCY/Data/ConfigFolder` ⇒ `Lua_GetSectDesc`
phía client chưa cài được. Đưa hai bảng đó sang client là thay đổi trong `Assets/`, **ngoài làn của
nhánh này**.

---

## 4. "Chỗ thứ tư" của lớp lỗi `ed09b4f` — đã quét có hệ thống

Công cụ: **`Tools/server/impact_refs.py scan`** (chỉ đọc). Bằng chứng: `impact-refs-2.tsv`,
`place4.txt`, `col5-xuatxu.txt`, `col5-suaduoc.txt`.

### 4.1 Vì sao phải có công cụ riêng

Commit `ed09b4f` đổi trục ID của `StandardImpact` và bỏ quên **ít nhất bốn** nhóm ô trỏ tới nó:

| # | nơi | ai vá |
|---|---|---|
| 1 | `Exterior_Ride.txt` | `ride-data` |
| 2 | `cy_four_combat/native_config.lua` `params` (282 ô) | `cyfour_params.py` |
| 3 | `g_Impact1/2` của script vật phẩm (341 ô) | mục 1 |
| 4 | **hằng số ở đối số 4 của `SendSpecificImpactToUnit`** | mục 4.3 |

### 4.2 LUẬT PHÂN BIỆT NGHI NGỜ THẬT VỚI BÁO ĐỘNG GIẢ

**Bảng nào đã là bảng CY thì ô impact của nó đã ở trục CY** ⇒ "khác tên so với bảng 0.85" là ĐÚNG.
Công cụ gán **nguồn** cho từng bảng bằng cách so số cột/số dòng với hai bản gốc (bản đổ CY và
`/home/ubuntu/configs/`). Không có luật này thì phép đo sẽ "phát hiện" 68 ô hỏng ở `EquipBase` và
người sửa sẽ phá bảng CY.

### 4.3 Kết quả quét

| nơi | nguồn | số ô | nghi ngờ | kết luận |
|---|---|---|---|---|
| **Lua: hằng số ở đối số 4 `SendSpecificImpactToUnit`** | 0.85 | 300 | 113 → **0 sửa được còn lại** | **chỗ thứ tư thật** — xem dưới |
| `PetEquipBase.txt` cột 16 | 0.85 | 136 | **136** | ID 8100–8343 **thiếu ở CẢ HAI bảng** ⇒ lỗ có trước `ed09b4f`, không có nguồn để vá. Việc của nhánh trân thú |
| `EquipBase.txt` cột 19 | ? | 2.907 | 68 | **BÁO ĐỘNG GIẢ**: 0 ô thiếu, và **0/68** có dòng `+30000` ⇒ ID của CY thật |
| `lua g_Impact` | 0.85 | 716 | 2 | `4931`, `340001` — thiếu ở cả hai bảng |
| hằng số `*IMPACT*` trong `lualib`/`services` | 0.85 | 35 | 2 | `C_UNIT_MUST_NOT_HAVE_IMPACT = 16` (**mã điều kiện, không phải ID impact** — regex bắt nhầm) và `BORROW_IMPACT_ID = 69001` (`std_talent_953.lua`, thiếu ở cả hai bảng) |
| `SkillTemplate_V1.txt` cột 30 | ? | 4 | 0 | sạch |

**Chỗ thứ tư, bóc chi tiết** — 59 giá trị hằng số / 300 lời gọi:

- **2 ô SỬA ĐƯỢC** bằng đúng luật tên + `逻辑ID` (mục 1.4) — **đã sửa**:
  - `event/dali/edali_0211.lua`: `4825 → 34825`. 0.85 = `烟花6` (pháo hoa); CY ở ID cũ là
    `宁闻不墨一段` **`逻辑ID 3` = sát thương**.
  - `obj/luoyang/oluoyang_yanqing.lua`: `50003 → 32407`. 0.85 = `暗器升级BUFF`; CY ở ID cũ là
    **`坐骑：玉麟龙`** — một impact **thú cưỡi**. (Giải bằng luật dự phòng "đúng MỘT dòng CY cùng tên
    + cùng logic"; không có dòng `+30000`.)
- **26 ô / 14 ID** trỏ vào dòng **thiếu bên CY nhưng có nguyên dòng ở 0.85** ⇒ **chép dòng**, xem 4.4.
- **85 ô / 13 ID** đổi nghĩa nhưng **bảng CY không có dòng nào cùng tên + cùng logic** ⇒ **để nguyên**:
  `49` (`升级特效(绿)`, **69 ô** — hiệu ứng lên cấp), `113` (`焰火特效`, 4 ô), `21439`, `50004`,
  `50005`, `50007`, `50008`, `50009`, `50074`, `50101`, `50102`, `50104`, `50105`.
  Không bịa: đoán `+30000` cho chúng là cộng hằng số mà không có gì để kiểm.

### 4.4 Chép 14 dòng từ bảng 0.85 — phương pháp KHÁC, dùng đúng chỗ

`impact_map.py copy85`. Đây **không** phải phép đổi trục: ID vẫn giữ nguyên, chỉ **chép nguyên byte**
dòng 0.85 vào bảng CY tại đúng ID đó (ID đang **trống** bên CY nên không đè lên gì).

Điều kiện: ID được script trỏ tới · **thiếu** ở bảng CY · **có** ở bảng 0.85 · `逻辑ID` của nó **đã
đăng ký** trong `impactenginer`. Ghi trong `flock` `configs/.scene_install.lock` và **trộn lại từ bảng
SỐNG ngay trong lock** (nhánh khác cùng ghi file này). `write_table` tự kiểm GBK toàn file.

**14 ID đã chép** (32.266 → **32.280** dòng, ID tăng dần, 0 ID trùng;
sao lưu `backups/impact-copy85-20260918T013742Z/`):

| ID | tên (0.85) | logic | số ô được cứu | script |
|---|---|---|---|---|
| `159` | 工资卡倒计时 | 0 | 3 | `event/Char_DataBase.lua`, `commonitem/GongZiKa.lua` |
| `3019` | 扛旗 | 14 | 1 | `event/PhoenixPlainWar/event_fenghuangContest.lua` |
| `5978` | 999朵蓝色妖姬特效 | 0 | **10** | `event/newhuodong/QiXiFlower*.lua` |
| `8877` | 卢俊义天罡霸气 | 89 | 1 | `obj/shengsi/lujunyi.lua` |
| `8878` | 卢俊义天人五衰 | 12 | 1 | `obj/shengsi/lujunyi.lua` |
| `8879` | 鲁智深孤芳自赏 | 14 | 1 | `obj/shengsi/luzhishen.lua` |
| `8880` | 鲁智深天煞孤星 | 10 | 1 | `obj/shengsi/luzhishen.lua` |
| `8885` | 李逵杀气瘟疫 | 86 | 1 | `obj/shengsi/likui.lua` |
| `8886` | 李逵杀气爆发 | 12 | 1 | `obj/shengsi/likui.lua` |
| `8887` | 卢俊义天罡聚气(无敌) | 14 | 1 | `obj/shengsi/lujunyi.lua` |
| `8891` | 运营废弃 | 11 | 2 | `obj/shengsi/guansheng.lua`, `songjiang.lua` |
| `31839` | 艾虎 百分比减血 | 5 | 1 | `event/qingqiu/fuben_zhenshoujindi_BOSS_5_BOSS.lua` |
| `42656` | 锁链 | 14 | 1 | `event/shuiyueshanzhuang/ai_shisan.lua` |
| `59901` | 地府束缚 | 14 | 1 | `scene.lua` |

Hai ID **không chép được**: `4931`, `340001` — thiếu ở **cả hai** bảng (đã biết từ `item-live`).

### 4.5 `StandardImpact` cột 5 — 5.569 "nghi ngờ" là BÁO ĐỘNG GIẢ DO CHÍNH CÔNG CỤ NÀY TẠO RA

Bản đầu của `impact_refs.py` báo **28.605 ô / 5.569 nghi ngờ** ở cột 5
`瞬发效果ID/驻留效果ID` của chính bảng `StandardImpact`. Con số đó **sai về bản chất**, không phải sai
về số học: **cột đó không phải chỉ số vào `StandardImpact`**. Đường truy [DK]:

```
cfghelper.lua:1383 read_std_impact   t.impact_id = conf["瞬发效果ID/驻留效果ID"]
impactenginer.lua:66                 imp:set_impact_id(data.impact_id)
scenecore.lua:1761                   impact.buffer_id = imp.impact_id   --> goi GCDetailImpactListUpdate
```

⇒ nó là **ID biểu tượng buff phía CLIENT** (`buffer_id`), đi thẳng ra gói, không bao giờ dùng để tra
dòng impact. So nó với tên dòng `StandardImpact` là **sai phạm trù**. Cột đã được đưa vào
`COL_EXCLUDE` của công cụ kèm nguyên văn lý do, để người sau không đo lại rồi "sửa".

Trước khi loại, tôi đã bóc theo xuất xứ dòng (giữ lại vì nó nói điều khác cũng đáng biết):
`ed09b4f` 2.291 ô · dòng có ở cả hai bản 1.609 · **dòng do chính các nhánh của dự án đúc thêm 1.004**
· chỉ-có-ở-0.85 665. Và **3.161/5.569 (57 %) trỏ vào ID thiếu ở CẢ HAI bảng** — kể cả từ những dòng
tên `测试用SOT…`. Tức ngay cả khi cột này có nghĩa như tưởng, phần lớn vẫn là lỗ dữ liệu có sẵn,
không phải hậu quả của việc đổi trục.

### 4.6 "36 impact ID > 65535 đi trên dây u16" — đo lại: KHÔNG có rủi ro tràn

Câu hỏi của nhánh `review-red`. Năm dữ kiện [DK]:

1. **`StandardImpact.txt` không có dòng nào ID > 65535**: 32.280 dòng, `Data_Index` min 0, **max
   64033**. (12.050 dòng > 32767 — nhưng xem điểm 2.)
2. **Ô 16 bit của hệ impact không mang ID dòng impact.** Nó mang `buffer_id`, lấy từ **cột 5**
   (`cfghelper.lua:1383` → `impactenginer.lua:66` → `scenecore.lua:1761`,
   `services/scene/obj/character.lua:1529/1539/1599`). Ba chỗ ghi 16 bit đều ở
   `services/game/packet_domains/misc.lua`: **756** `GCDetailImpactList`, **3081** `GCCharBuff`,
   **3117** `GCDetailBuff` — cả ba `stream:writeshort(... .buffer_id)`. **`Data_Index` không bao giờ
   được ghi vào một ô 16 bit nào.**
3. **Cột 5 lớn nhất toàn bảng = 19.902**, số ô > 32767 = **0** ⇒ ô 16 bit không bao giờ tới ngưỡng.
4. **Toàn cây R chỉ có đúng 2 tham chiếu ID impact > 65535** và **cả hai đều không có dòng** nên
   không sinh ra impact để gửi: `69001` (`BORROW_IMPACT_ID`, `talent_logic/std_talent_953.lua`) và
   `340001` (`item_340001.lua`).
5. **Tràn cũng không hoá thành ID khác.** `iostream.lua:183 bostream:writeshort` **kẹp**, không quấn
   vòng (`if s > 32767 then s = 32767`). Chạy thử thật: `writeshort(70000)` và `writeshort(340001)`
   đều ra **32767**. Kịch bản "ID lớn lặng lẽ thành một ID nhỏ hợp lệ" **không xảy ra được**.

`impact_refs.py scan` in bất biến này ở cuối mỗi lần chạy, để không ai phải đo lại.

### 4.7 Số cuối cùng, trên toàn bộ tham chiếu ID impact trong `Game_2/Script`

| | số ô |
|---|---|
| tổng ô mang ID impact (716 `g_Impact` + 300 hằng số) | **1.016** |
| trỏ đúng dòng | **929** |
| còn sửa được mà chưa sửa | **0** |
| trỏ vào dòng thiếu | **2** (`4931`, `340001` — không có nguồn) |
| đổi nghĩa nhưng không có dòng CY tương đương | **85** (13 giá trị, mục 4.3) |

---

## 4.8 ĐÍNH CHÍNH của chính tôi — ba chỗ tôi đã nói sai, đã đo lại

Cả ba đều tự tìm ra khi soi lại, không ai chỉ ra.

**(a) Bản quét đầu đếm cả dòng CHÚ THÍCH.** Trong 300 lần hằng số xuất hiện ở ô đối số của
`SendSpecificImpactToUnit`, **35 nằm trong chú thích Lua**, chỉ **265 là mã chạy thật**. Nặng nhất:
`5978 999朵蓝色妖姬特效` — tôi báo "cứu 10 ô", nhưng **cả 10 đều là chú thích**; dòng đã chép vào bảng
là đúng nhưng **không mã sống nào dùng nó**. Số đúng: 14 dòng chép cứu **16 ô sống**, không phải 26.
Công cụ nay dựng `comment_mask()` (cả `--` lẫn `--[[ ]]`) và bỏ qua mọi thứ trong chú thích, khi ĐẾM
lẫn khi GHI.

**(b) Bỏ sót ô mang ID là BIẾN, không phải hằng số.** `QiXiFlower999.lua` có `local Youhadu = 4918`
rồi `Send(..., Youhadu, 0)` — regex cũ chỉ bắt số. Thêm `var_cells()`: chỉ nhận khi tên được gán
**đúng một lần** bằng số nguyên và **mọi** lần xuất hiện khác của tên đều là ô ID của một hàm trong
`CALLS` (nếu không thì biến có thể còn dùng việc khác ⇒ bỏ). Sửa ở **chỗ khai báo**, không sửa lời gọi.

**(c) Bỏ sót HAI họ hàm khác cũng nhận `Data_Index`.** Chữ ký đọc từ `script_base.lua`:
`LuaFnCancelSpecificImpact(selfId, data_index)` **:5271** (117+134 lời gọi) và
`LuaFnHaveImpactOfSpecificDataIndex(selfId, data_index)` **:1201**. Công cụ nay khai bảng `CALLS` gồm
ba hàm kèm **vị trí đối số**. **Cố ý loại** ba hàm tên rất giống nhưng nhận thứ khác:
`LuaFnCancelImpactInSpecificImpact` / `LuaFnHaveImpactInSpecificCollection` (**collection id**) và
`LuaFnHaveImpactOfSpecificMutexId` (**mutex id**) — sửa nhầm chúng là hỏng thật.

Ba đính chính đó làm lộ thêm **19 ô sửa được** (9 ID, 16 file) — đã sửa:

| ID | → | tên 0.85 | CY ở ID CŨ (thứ đang gửi nhầm) | ô |
|---|---|---|---|---|
| `4915/4916/4917/4918` | `+30000` | 送花 | `摧魂定魄内功攻击` / `摧魂定魄(定身)` / `银钩走蝎` — **đòn tấn công** | 10 |
| `4621/4622/4623` | `+30000` | thức ăn trân thú hồi máu | `刃击千里` | 3 |
| `58` | `86` | 黄金马鞍加速 | `AMD双核速龙丹` | 4 |
| `50001` | `8500` | 乾坤杯 | **`坐骑：鬼马龙舟`** — impact **thú cưỡi** | 2 |

và **4 ID nữa cần chép dòng** (`31829/31830/31831/31838`, `阴阳无咎` của phó bản Thanh Khâu) →
bảng **32.280 → 32.284**.

**Số cuối cùng sau tất cả**: **1.081 ô** mang ID impact trong `Game_2/Script` (đã bỏ chú thích) →
**965 trỏ đúng · 0 còn sửa được · 2 vô phương (`4931`, `340001`) · 114 đổi nghĩa không có dòng CY
tương đương (17 ID)**. `luac -p` sạch.

## 4.9 ĐÍNH CHÍNH quan trọng nhất: `Game_2/Script/**` KHÔNG cần restart

Tôi đã viết "script chỉ được nạp lúc khởi động". **Sai.** `scriptenginer:try_load(id)`
(`lualib/scriptenginer.lua:118`) `require` đường dẫn script **lần đầu có ai dùng tới**, rồi mới nhớ
vào `self.scripts[id]`:

```lua
function scriptenginer:try_load(id)
    ...
    local path = dat[id]
    if path then
        local ok, f = xpcall(require, debug.traceback, path)
```

⇒ **Một script chưa từng được dùng trong tiến trình skynet này sẽ đọc file MỚI ngay, không cần
restart.** Script **đã dùng rồi** thì giữ chunk cũ cho tới `reload_scripts` (hàm đó cố ý gọi
`require("skynet.codecache").clear()` — xem chú thích audit 2026-09-11 ở `scriptenginer.lua:69`)
hoặc tới lần restart.

**Bằng chứng live**: server khởi động **09:35:05**; tôi sửa `300265.lua` (`gold_maan` 58 → 86) lúc
**09:45**; rồi cho bot dùng vật phẩm thật `30008114 黄金马鞍` — nhân vật nhận **impact 86
`黄金马鞍加速`**, đúng dòng mới. Nếu script chỉ nạp lúc khởi động thì nó phải nhận `58` =
`AMD双核速龙丹` (buff nước ngọt). (`items/snap-yen-truoc-30008114.json`.)

Hệ quả cho người sau: `configs/*.txt` và `lualib/*.lua` **vẫn phải restart**; `Game_2/Script/**` thì
**tuỳ script đã được chạm hay chưa** — nên vẫn nên restart để chắc chắn đồng nhất, nhưng đừng kết
luận "chưa restart nên chưa có tác dụng".

---

## 5. Bẫy

1. **`\` trong chuỗi Python viết qua heredoc của shell bị nuốt** — `rel.replace('\\', '/')` thành
   `rel.replace('\', '/')` ⇒ `SyntaxError: unterminated string literal`. Dùng công cụ `Edit`, hoặc
   `chr(92)`.
2. **PowerShell nuốt `|`, `&&`, `$(...)` bên trong `wsl.exe -- bash -lc "..."`.** Mọi lệnh shell có
   ống hoặc thay thế lệnh phải **viết ra file `.sh`** rồi `wsl.exe -d TLBB -u root -- bash <file>`.
3. **Gọi `wsl.exe` từ Bash tool của Git Bash làm hỏng đường dẫn `/mnt/c/...`** (chèn
   `C:/Program Files/Git/`). Dùng PowerShell tool.
4. **`impact_list` trong Mongo có thể là LIST, không phải DICT.** `d.get('impact_list').items()` ném
   `AttributeError` trên nhân vật có impact. Phải nhận cả hai dạng.
5. **`give_item.py` chỉ nhân bản được dòng mẫu CÙNG LỚP vật phẩm.** Không nhân vật test nào có trang
   bị (lớp 1) trong **túi** (vũ khí nằm ở `equip_list`, không thuộc `BAGS`) ⇒ không tạo được trang bị
   mới bằng công cụ đó. Cách vòng: chuyển chính vũ khí đang mặc từ `equip_list` sang túi
   (`enh_bench.py stage`), đo xong trả lại (`restore`).
6. **`--exec` của bot chạy ở pha `Chat`, TRƯỚC pha `Inv`.** Muốn "gọi XSCRIPT rồi mặc lại" thì để cả
   hai trong **một** phiên; muốn "tháo ra rồi gọi XSCRIPT" thì phải **hai** phiên.
7. **`losecount` nằm trong `unknow_4[10..11]`** (`item:get_param(9,"ushort")` đọc 12 byte `unknow_4`
   rồi `skip(9)`), không phải một trường riêng. Reset phép đo phải ghi đúng hai byte đó.
8. **`configs/temp.txt` (309 byte, 29/04) không giải mã được GBK** — có từ trước, **không dòng mã nào
   đọc nó**. Đừng tính nó vào phép kiểm "mọi bảng phải GBK"; cũng đừng xoá mà không hỏi.
9. **Đừng đo "tỉ lệ cường hoá" bằng phép chia thô** — `losecount` làm xác suất thay đổi từng lượt.
   Xem 2.3.
10. **Bảng CY không có tên cột.** Mọi reader viết cho `TalentInfo`/`ZongmenTalent`/`TalentLayerLevel`
    phải đọc theo **VỊ TRÍ**; `cfghelper` đọc theo tên nên sẽ không dùng được như các bảng khác.
11. **Tên cột chứa "效果ID" KHÔNG đủ để kết luận đó là chỉ số vào `StandardImpact`.** Xem 4.5: cột 5
    của chính bảng đó là ID biểu tượng buff phía client. Luôn truy đường dùng của cột trước khi đo.
12. **Đừng so "số thành công sau" với "kỳ vọng tính trên dãy trước".** Xem 2.4.
13. **`ItemEnhance` yêu cầu tinh hoa KHÁC khi `qhlv >= 9`** (`38008160`/`38008161` thay cho
    `30900005`). Phép đo dài phải reset cấp về 0 giữa các lô, nếu không lô sau trả mã lỗi 14 và
    phép đo im lặng hỏng.
