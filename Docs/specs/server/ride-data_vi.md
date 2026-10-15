# ride-data — dữ liệu thú cưỡi (坐骑) của server riêng

> Cập nhật 24/09/2026: các phép đo “bay” ở tài liệu này là model/hover sát đất. Bay cao bằng Ctrl + chuột trái, điều kiện CharMount cột19 và gói2242 được bổ sung tại [mount-high-flight-20260924_vi.md](mount-high-flight-20260924_vi.md).

Ngày đo: **17/09/2026**. Server riêng `R = /home/ubuntu/cys-test-20260913` (WSL `TLBB`, cổng 15733/15734).
Công cụ: `Tools/server/ride_data.py`. Bằng chứng: `Build/Logs/2026-09-17-ride-data/`
(các script đo nằm ở `do-dac/`, có thể chạy lại).

---

## 0. Trả lời thẳng câu hỏi "Thú cưỡi đã thêm vào hết chưa"

**Chưa, và trước hôm nay thì hỏng nặng hơn là thiếu.** Số đo thật, đo sau khi làm:

| | TRƯỚC | SAU |
|---|---|---|
| dòng `Exterior_Ride` trên server | 198 | **335** |
| số `模型索引` khác nhau | 184 | **321** |
| **thú cưỡi CY có thể hiện ra** (có dòng ride + đủ chuỗi mesh) | **150 / 302** | **287 / 302** |
| trong đó có item Type 41 kích hoạt | 131 | **154** |
| ride có `骑乘ID` khớp `模型索引` (tức là cưỡi ra ĐÚNG con) | **0 / 198** | **335 / 335** |
| ô impact của `Exterior_Ride` trỏ tới dòng không tồn tại | **1 227 / 1 584** | **0 / 2 680** |
| item thú cưỡi dùng được | 1 668 / 1 798 | **1 788 / 1 798** |

Không mất con nào (`before_after.py`: `mat di = 0`).

Còn thiếu: **15 thú cưỡi CY chưa có dòng `Exterior_Ride`** (trong đó 1 con — `151 大风` — có sẵn item
mà dùng không lên), và **148/302 con chỉ GM/script cấp được** vì CY không phát hành item cho chúng.

---

## 1. Chuỗi thật sự quyết định "cưỡi ra con gì"

Đọc trực tiếp trong mã server, không suy đoán:

```
item EquipBase Type 41 (脚本ID 999801)
   └─ 999801.lua:OnDefaultEvent → LuaFnGetEquipVisual → cột `Visual`
        └─ LuaFnGetExteriorRideIDByVisual(visual)          script_base.lua:1734
             quét `exterior_ride`, tìm dòng có 模型索引 == visual → ride id
                └─ LuaFnAddRideRxpirationTime(ride, -1) → human:add_expiration_time  (human.lua:6185)
                     ghi vào `exterior.rides`  ← SỞ HỮU
                └─ ChangePlayerRide(ride) → human:set_ride  (human.lua:2648)
                     ghi attrib `ride`       ← ĐANG CHỌN

bấm cưỡi (packet CGCharAutoRide 636)
   └─ scenecore:char_auto_ride  (scenecore.lua:6171)
        └─ push_command_use_skill(21, …)      skill 21 = 召唤坐骑, SkillData 21 logic = 14
             └─ skill_14:effect_on_unit_once  (skill/human/skill_14.lua:36)
                  max = human:get_riders_max_speed_up()      ← duyệt `exterior.rides` (SỞ HỮU)
                  value = exterior_ride[ride].impacts[max]   ← cột 速度<max> của dòng ride
                  impactenginer:init_impact_from_data(value) ← PHẢI CÓ DÒNG StandardImpact
                     └─ std_impact_014:get_refix_ride_model  đọc tham số `骑乘ID(-1为无效)`
                          → thuộc tính `ride_model` (kiểu refix, human_attrib.lua 170/240/350)
                             → client vẽ CharMount[ride_model]  (Obj_Character.cpp:1182)
```

**Một trục duy nhất ở tầng hiển thị:**
`item.Visual` == `Exterior_Ride.模型索引` == `骑乘ID` == `ride_model` == **chỉ số `CharMount` mà CLIENT tra**.

---

## 2. Bảng `CharMount.txt` của server là bảng CHẾT

`grep -rni "charmount\|char_mount"` trên toàn bộ `cys-test-20260913/{GameServer,Game_2,configs}` ra
**0 dòng mã**; `configenginer.lua` không có mục `char_mount` (chỉ có `exterior_ride`). File đó chỉ còn
được liệt kê trong `source-manifest.json`.

Nội dung của nó **là bản của `client_GL`**: 201 dòng × 15 cột, khớp từng byte ở các dòng đã đối chiếu
(0, 94, 203, 211, 215). Cột 14 của nó = **độ cao bay**, tương ứng cột 22 của bảng CY (`ride-core` đã
decompile và đổi tên `m_fFlyHeight` trong `Src/Engine/Interface/TDDBC_Struct.h`).

⇒ Chênh "353 vs 201 dòng" và "thiếu 10 cột" **không phải việc của server**. Client đang chạy đọc bản CY
ở `Assets/CanonicalCY/Data/ConfigFolder/CharMount.txt` (24 cột, 353 dòng) và bản đó đã đủ.
Công cụ này **không** nới bảng server lên 24 cột — nong một bảng chết chỉ thêm rủi ro.

Tình trạng file trước khi sửa (đây là lý do vẫn phải chạm vào nó): **trộn 183 dòng LF với 20 dòng CRLF**
và **một dòng UTF-8 lọt vào file GBK** (dòng 185, `CharMount` id 220 `Trâu Đen`, thêm từ 06/09).

---

## 3. HAI KHÔNG GIAN ID — cái bẫy chính

`client_GL`/server và CY là hai nhánh cùng thời, **số hiệu không dùng chung**. So theo **mesh**
(`CharMount[N].ModelID → CharModelEx → all.obj → .mesh`), không theo số:

| | |
|---|---|
| `CharMount` GL (bảng server đang giữ) | 201 dòng, 200 dòng ra được mesh |
| `CharMount` CY (bảng client đang vẽ) | 353 dòng, 351 dòng ra được mesh |
| **cùng ID VÀ cùng mesh** | **76** |
| khác hẳn con | 89 |
| CY không có ID đó | 35 |
| GL có bản tương đương bên CY (theo mesh) | **148 / 201** — trong đó **76 giữ nguyên ID, 72 phải đổi ID** |
| GL không có bản tương đương bên CY | **53** |

Bảng ánh xạ đầy đủ GL→CY theo mesh: `Build/Logs/2026-09-17-ride-data/do-dac/mesh_match.json`.

**Hệ quả quan trọng nhưng dễ đọc nhầm:** người chơi lấy thú cưỡi bằng ITEM, mà bảng `EquipBase` của
server **đã là bảng của CY** (1 828 dòng Type 41, 159 `Visual`, trùng khít tập `Visual` của CY —
`gap.py` in `Visual cua item SV == Visual cua item CY ? True`). Vì item tìm ride bằng
`模型索引 == Visual`, nên **mọi ride mà người chơi thật sự với tới được đều có `模型索引` nằm trên trục CY**
và vẽ ra đúng con vật ghi trên item. Chỗ sai còn lại là **tên/biểu tượng của chính dòng ride** (văn bản
GL) và **trục ID của `Exterior_Ride`** — xem mục 6.

---

## 4. Hỏng đang tồn tại đã tìm ra (và đã vá)

**Commit `ed09b4f` (CS3c) thay toàn bộ `StandardImpact` sang trục ID của CY nhưng KHÔNG đổi
`Exterior_Ride`.** Hậu quả đo được trước khi sửa:

* `Exterior_Ride` trỏ tới 1 433 ID impact; **1 099 ID không còn dòng nào** trên R;
* 1 584 ô impact khác −1, chỉ **357 ô (22,5 %)** còn dòng thật;
* trong 28 006 dòng `StandardImpact` chỉ **6 dòng** khai `骑乘ID`;
* **0/198** ride cho ra đúng model.
* Tệ hơn: 45 dòng ride trỏ vào ID mà CY đã gán cho thứ khác — ví dụ ride 144 `扶摇苍龙` đăng ký
  `魂飞目断（CY推导属性）` lên người chơi, ride 174 `飒露紫` đăng ký `散功`.

Đó chính là dấu vết `[DIAG_RIDE_PK] RIDE_TIMEOUT skill 21 khong tao ra impact cuoi thu` trong log —
lỗi "cưỡi thú thất bại im lặng" đã mở từ trước.

**Nguồn vá là nguồn THẬT:** server GỐC `/home/ubuntu/configs/StandardImpact.txt` (19 370 dòng, **cùng
81 cột, cùng tiêu đề**) còn giữ nguyên khối impact thú cưỡi của nhánh GL và có **1 097/1 099** ID đang
thiếu. Chép đúng các dòng đó về cho **191/198** ride ra đúng model ngay.

---

## 5. Công cụ `Tools/server/ride_data.py`

```
python3 -B Tools/server/ride_data.py survey                       chỉ đọc
python3 -B Tools/server/ride_data.py plan   --out <DIR>           dựng staging, KHÔNG chạm R
python3 -B Tools/server/ride_data.py apply  --staging <DIR>       flock + sao lưu + ghi
python3 -B Tools/server/ride_data.py verify                       đọc lại TỪ ĐĨA rồi khẳng định
```

Bốn việc nó làm:

1. **`repair`** — trộn vào `StandardImpact.txt` những dòng mà `Exterior_Ride` đang trỏ hụt, lấy nguyên
   văn từ server GỐC. **1 097 dòng.**
2. **`repoint`** — ride nào (sau bước 1) vẫn không cho `骑乘ID == 模型索引`, hoặc còn trỏ vào ID không có
   dòng, thì **đúc 8 dòng impact MỚI** (một dòng mỗi bậc tốc độ 10/20/40/70/75/80/85/90) và trỏ lại 8 cột
   tốc độ của ride đó. **Không sửa dòng impact đang có** — dòng đó có thể đang phục vụ một chiêu thật.
   **47 ride, 376 dòng impact.**
3. **`new rides`** — thêm dòng `Exterior_Ride` cho mọi `模型索引` mà CY có còn server chưa có, nội dung
   (`名字/图标/描述/门派/速度索引/模型索引`) lấy nguyên byte GBK từ DBC của CY. **137 ride + 1 096 impact.**
   ID cấp theo luật: **dùng đúng ID ride của CY nếu ID đó còn trống trên server (97 dòng)**, còn lại cấp
   từ 300 (40 dòng).
4. **`encoding fix`** — hai ô UTF-8 lọt vào file GBK (`Exterior_Ride` dòng 182 / ride 180,
   `CharMount` dòng 185 / id 220) đổi sang ASCII, và `CharMount.txt` trả về CRLF thuần.

Luật đã tuân thủ:

* làm ở **mức BYTE**, không decode/encode cả dòng; chuỗi CY lấy thẳng từ string pool của DBC (GBK);
* dòng impact mới là **bản sao của một dòng THẬT cùng bậc tốc độ**, chỉ đổi `Data_Index`, `效果名称`,
  `骑乘ID`, `移动速度修正%`, và SE → −1 khi SE đó không có ở client CY (65/895 SE là SE riêng của GL);
* `StandardImpact` giữ **ID tăng dần** (trộn theo thứ tự, không nối đuôi) và **đúng 81 cột**
  (bảng của server GỐC có dòng 93/144/79/1 cột — cắt về 81; đã kiểm **không dòng nào mất nhãn
  `骑乘ID`/`移动速度修正%` khi cắt**);
* **chỉ THÊM, không xoá dòng nào**;
* `flock` dùng chung `configs/.scene_install.lock` với `scene_install.py`/`map_bianjing.py`;
* `apply` **trộn lại từ bảng SỐNG ngay trong lock** (không chép đè file staging), vì cùng buổi có agent
  khác đang sửa `StandardImpact`; ID đã có trên bảng sống thì bỏ qua ⇒ **idempotent**;
* sao lưu vào `R/backups/ride-data-<UTC>/` trước mỗi lần ghi; từ chối ghi nếu nội dung không decode được GBK.

### Kết quả `verify` (đọc lại từ đĩa, 17/09 22:35)

```
GBK + CRLF thuần                     : OK cho cả 6 bảng thú cưỡi
StandardImpact ID tăng dần / 81 cột  : OK (30 575 dòng)
Exterior_Ride 26 cột, ID tăng dần    : OK (335 dòng)
mọi ô impact đều có dòng thật        : OK (0/2 680 trỏ hụt)
mọi ride có 骑乘ID khớp 模型索引       : OK (335/335)
mọi item thú cưỡi đều có ride        : FAIL — 1 788/1 798; còn Visual 151, 152
```

### Kiểm CHẠY THẬT (không phải đọc file)

Server restart 22:07:40, cổng 15734 lên sau ~50 giây, log không có lỗi mới.
Tiêm script chỉ-đọc `probe_ride.lua` vào service cảnh `:000000ac` qua `debug_console` 16002 —
đây là **bảng đang nằm trong bộ nhớ server**, không phải file:

```
[PROBE_RIDE] exterior_ride dang nap = 335 | co impact = 335 | impact dat dung 骑乘ID = 335 | khong = 0
[PROBE_RIDE] ride 1   陆行雕  model=21  imp[10]=43101 logic=14 骑乘ID=21  speed%=10  (dòng CŨ vừa vá)
[PROBE_RIDE] ride 199 坠风莲  model=263 imp[80]=64425 logic=14 骑乘ID=263 speed%=80  (dòng MỚI từ CY)
[PROBE_RIDE] ride 339 海波晏  model=262 imp[80]=64417 logic=14 骑乘ID=262 speed%=80
```

---

## 6. Hai quyết định kiến trúc còn treo

### 6.1 Trục ID của `Exterior_Ride` — **khuyến nghị: server phải đổi, không phải CY**

Client tra `Exterior_Ride` **bằng chính ride id** để lấy tên/biểu tượng/khung xem trước
(`LuaFnGetExteriorRideInfo`, `LuaFnGetExteriorRideCameraParam`, `LuaFnEnumRideSeriesExteriorRideId` —
hiện còn là stub trong `Src/Client/LuaApiGen/`, là phần `ride-core` đang làm). Bảng của client là bảng
**CY**. Server thì đang mang ID của nhánh **GL**.

Đo: **180/335 dòng ride của server hiện trùng nghĩa với dòng CY cùng ID** (trước khi làm: 83/198).
Tức **155 dòng vẫn nói khác ngôn ngữ** với client.

Ai phải đổi? **Server.** Ba lý do, đều đo được:

1. **Client là điểm cố định** — đổi `Assets/CanonicalCY` là rời khỏi chuẩn CY, trái quyết định 14/09
   "MỌI THỨ như CY".
2. **Bảng item của server đã là bảng CY rồi** (mục 3). Giữ ride id GL trong khi item là CY là tự mâu thuẫn.
3. **Đổi bây giờ không tốn gì.** Đo Mongo lúc 22:20: **16 nhân vật, 0 nhân vật sở hữu ride nào**
   (`exterior.rides` rỗng hết). Chờ tới khi người chơi có thú cưỡi thì phải viết migration.

Cách làm đề xuất (chưa chạy, cần người dùng chốt): dựng lại `Exterior_Ride` của server = **297 dòng của
CY ở đúng ID của CY**, cộng các dòng GL còn giá trị (có `模型索引` vẽ được mà CY không phủ) dời lên ID ≥ 400,
rồi đúc lại impact. Rủi ro thấp vì item tìm ride theo `模型索引` chứ không theo ID.

### 6.2 Ba mươi mốt `模型索引` chỉ có ở nhánh GL — **khuyến nghị: để nguyên, đừng phát hành item**

32 dòng ride của server trỏ tới 31 giá trị `模型索引` (101–134, 227 — `琉璃鹄`, `寄居蟹`, `跑商车`,
`七彩祥云`, `筋斗云`, `木鸢`…) mà **CY `CharMount` không có dòng nào**, nên client CY không vẽ được.
Đã kiểm: **không item Type 41 nào trỏ tới chúng**, nên hôm nay không người chơi nào với tới.
Chúng là di sản **085/GL** — có mặt nguyên vẹn cả trong `C:\TLBB\085\client` lẫn `client_GL`.
16/35 con có mặt ở CY nhưng **ở chỉ số khác** (`mesh_match.json` cho ánh xạ), 9 con CY không có cả
`CharModelEx`. Không xoá. Nếu muốn dùng, ánh xạ theo mesh sang chỉ số CY rồi mới phát hành item.

---

## 7. Còn thiếu / còn hỏng (đo sau khi làm)

| việc | số | ghi chú |
|---|---|---|
| thú cưỡi CY chưa có dòng `Exterior_Ride` | **15** | `20`(không tên), `22 走白雕`, `23 象`, `25 双人雕`, `151 大风`, `170 替模骑乘`, `240 芙玉飞花`, `241 霜瑟飞花`, `256 桃舟`, `258 花灯`, … — **CY cũng không có dòng ride cho chúng**, nên không chép được; phải đúc tay |
| item dùng không lên | **10** | `10141357`–`10141366` `飞龙：大风`, Visual **151/152**. CY `CharMount` 151/152 có thật (`大风` / `大风附件`, cao bay 2.0, đủ mesh) nhưng **CY không phát hành `Exterior_Ride` cho chúng** ⇒ đường lấy thú cưỡi BAY không đi qua `Exterior_Ride`; đây là câu hỏi của `ride-core` |
| thú cưỡi bay chưa có ride | **2/28** | `151 大风`, `403 归墟神龙`. 26 con còn lại đã có |
| `CharMount` CY đứt chuỗi mesh | **2/353** | id `20` (không tên) và `241 霜瑟飞花` — thiếu dòng `CharModelEx` |
| impact không nơi nào có | **2** | `5766`, `5767` — server GỐC cũng không có; các ride liên quan đã được `repoint` sang dòng mới |
| ride chỉ GM/script cấp được | **133** | CY không phát hành item cho chúng |

### Việc KHÔNG phải của dữ liệu

Cưỡi vẫn **chưa lên** trong lần thử live gần nhất (22:31:12, guid 200010): `RIDE_TIMEOUT`.
Dữ liệu đã đúng (mục 5), skill 21 có thật (`SkillTemplate_V1` 21 = `召唤坐骑`, `SkillData_V1` 21 logic 14,
nhân vật test có học). Nghi can còn lại nằm ở **logic**, không ở bảng:

```lua
-- human.lua:4163
function human:get_riders_max_speed_up()
    local rides = self.exterior.rides        -- danh sách SỞ HỮU
    local speed_up = 0                       -- <— rỗng thì trả 0
    for _, ride in ipairs(rides) do ... end
    return speed_up
end
-- skill_14.lua:41
local max_speed_up = obj_tar:get_riders_max_speed_up() or define.INVAILD_ID
if max_speed_up ~= define.INVAILD_ID then                       -- 0 ~= -1 ⇒ TRUE
    local value = exterior_ride_conf[ride].impacts[max_speed_up] -- impacts[0] = nil ⇒ -1
    if value ~= define.INVAILD_ID then ... end                    -- bỏ qua, không có impact
```

Chọn ride (`attrib.ride`) **không đủ**; phải **sở hữu** (`exterior.rides`) thì `max_speed_up` mới khác 0.
Đây là việc của `ride-core`.

---

## 8. Sao lưu và cách hoàn tác

```
/home/ubuntu/cys-test-20260913/backups/ride-data-20260917T150310Z/   (repair + 137 ride mới + sửa mã hoá)
/home/ubuntu/cys-test-20260913/backups/ride-data-20260917T150545Z/   (repoint 45 ride)
/home/ubuntu/cys-test-20260913/backups/ride-data-20260917T150609Z/   (repoint 2 ride còn trỏ hụt)
```

Mỗi thư mục chứa bản gốc của `StandardImpact.txt`, `Exterior_Ride.txt`, `CharMount.txt`.
Hoàn tác = chép ngược thư mục **cũ nhất** rồi restart server:

```bash
wsl -d TLBB -u root -- bash -lc 'cp /home/ubuntu/cys-test-20260913/backups/ride-data-20260917T150310Z/*.txt \
    /home/ubuntu/cys-test-20260913/configs/'
wsl -d TLBB -u root -- bash /mnt/c/TLBB/085/CY-Source/Tools/server/cys_server.sh restart \
    --confirm-root /home/ubuntu/cys-test-20260913
```

Áp lại (nếu vùng bị dựng lại):

```bash
wsl -d TLBB -u root -- bash -lc '
  cd /mnt/c/TLBB/085/CY-Source &&
  python3 -B Tools/server/ride_data.py plan   --out /tmp/ride-data-plan &&
  python3 -B Tools/server/ride_data.py apply  --staging /tmp/ride-data-plan &&
  python3 -B Tools/server/ride_data.py plan   --out /tmp/ride-data-plan2 &&
  python3 -B Tools/server/ride_data.py apply  --staging /tmp/ride-data-plan2 &&
  python3 -B Tools/server/ride_data.py verify'
```

(chạy `plan`+`apply` hai lượt là đúng: lượt đầu vá và thêm dòng, lượt sau `repoint` các ride mà lượt đầu
mới làm lộ ra. Lượt thứ ba sẽ ra kế hoạch rỗng.)

---

## 9. Bẫy đã trả giá để biết

1. **`Tools/game/dbc_inventory.Table` decode sai chuỗi GBK.** `decode()` thử UTF-8 TRƯỚC rồi mới GBK, nên
   chuỗi GBK thật lọt qua cửa UTF-8 và ra chữ Kirin: `CharMount` 233 tên thật là GBK `D1A9 D1B1 C2B9`
   = `雪驯鹿` nhưng nó trả `ѩѱ¹`. Bảng thú cưỡi toàn tiếng Trung ⇒ phải đọc **ở mức BYTE**
   (`do-dac/dbcbytes.py`).
2. **Tên file `.mesh` trên đĩa là byte GBK bị đọc bằng cp1252 lúc giải nén** (`虎.mesh` nằm trên đĩa dưới
   tên `»¢.mesh`). Muốn đối chiếu `all.obj` ↔ đĩa phải `filename.encode('cp1252')` rồi so byte, nếu không
   sẽ kết luận nhầm là "thiếu 300/353 mesh".
3. **EOL trộn.** `CharMount.txt` của server có 183 dòng LF lẫn 20 dòng CRLF. Tách file bằng `\r\n` cho ra
   18 "dòng" 2 573 cột — sai hoàn toàn mà không báo lỗi. Luôn tách bằng `\n` rồi `rstrip(b'\r')`.
4. **`是否需要装备支持` = 1 trên mọi dòng impact thú cưỡi nhưng server KHÔNG ép**: `impact:is_need_equip_support()`
   được định nghĩa mà **không nơi nào gọi**. Chép nguyên là an toàn.
5. **`txtreader` gom các cột trùng TÊN thành một danh sách.** `RideSeries`/`RideCollection` có dòng tiêu đề
   thứ hai toàn chữ `INT`, nên `ride_huayu_bonus.lua` đọc chúng bằng **thứ tự trong `conf["INT"]`**, không
   bằng tên. Thêm/bớt cột ở giữa các bảng đó là hỏng im lặng.
6. **Thêm cột vào CUỐI thì an toàn**, vì `txtreader` gán khoá số cho cột vượt tiêu đề và `cfghelper`
   chỉ đọc theo tên. Bớt hoặc chèn giữa mới hỏng.
7. **`速度索引` của CY có bậc 125** (2 dòng) mà bảng server không có cột tương ứng. Nguy hiểm hơn là ai đó
   sở hữu một con bậc 125: `get_riders_max_speed_up` trả 125 rồi `impacts[125]` = nil ⇒ **mọi** thú cưỡi
   của người đó đều không lên. Công cụ **ép về 90** và ghi vào `ride-moi.tsv`.

---

## 10. Bảng liên quan — trạng thái

| bảng | server | CY | kết luận |
|---|---|---|---|
| `Exterior_Ride.txt` | 335 × 26 | 297 × 28 | **đã nhập**, xem mục 5 |
| `StandardImpact.txt` | 30 575 × 81 | (không có bên client) | **đã vá + đúc**, xem mục 4 |
| `CharMount.txt` | 201 × 15 | 353 × 24 | **bảng chết trên server**; chỉ sửa mã hoá/EOL |
| `ExteriorRideCamera.txt` | không có file | 287 × 6 | **thuần client**, đã đủ ở bản CY |
| `RideCollectionEffect.txt` | 1 dòng | 1 dòng | **giống hệt nhau**, không phải làm gì |
| `RideSeries.txt` | 6 × 15 | 8 × 36 | **KHÔNG nhập** — `ride_huayu_bonus.load_series` đọc ride id, mà ride id hai bên khác trục (mục 6.1). Nhập bây giờ là ghi số rác. Làm sau khi chốt trục |
| `RideCollection.txt` | 14 × 5 | 8 × 5 | như trên; server đang là tập lớn hơn, để nguyên |
| `EquipBase.txt` Type 41 | 1 828 dòng | 1 828 dòng | **đã trùng khít với CY** từ trước (CS3c). 30 dòng `Visual = -1` là túi đồ, không phải thú cưỡi |
