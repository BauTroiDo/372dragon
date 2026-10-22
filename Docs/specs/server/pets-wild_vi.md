# Hệ trân thú (珍兽) trên server riêng — đo, vá và cách đo lại

Agent `pets-wild`, 17/09/2026. Bằng chứng: `Build\Logs\2026-09-17-pets-wild\`.
Server riêng: `\\wsl.localhost\TLBB\home\ubuntu\cys-test-20260913` (dưới đây gọi là `R`).

Ký hiệu: **[DK]** = dữ kiện đo được (có file/đường dẫn/dòng mã). **[SL]** = suy luận.
Chỗ nào chưa chứng minh được thì ghi thẳng "chưa kết luận được" kèm lý do.

> **ĐÍNH CHÍNH (đọc trước).** Bản đầu của tài liệu này nói "38 trứng có thật đi qua script không có
> chốt ⇒ `assert` làm hỏng scene". **SAI.** Thứ quyết định server chạy file Lua nào là cột
> `脚本编号` của `CommonItem.txt`, không phải bảng `g_petList` trong file Lua. Đo lại
> (`egg-script-truth.tsv`): chỉ **ba** file thật sự được gọi — `300027.lua` (356 trứng, **CÓ** chốt
> `GetIsPetID`), `332003.lua` (1), `charged_38000082.lua` (1). Sáu file "không chốt"
> (`891217/893088/893308/998545/998515/890041`) **không có vật phẩm nào trỏ tới** ⇒ không bao giờ
> chạy. Lỗ hổng `assert` thật nằm ở **nhánh BẮT THÚ HOANG**, không phải nhánh trứng — mục 2.3.

---

### 1.1 Trân thú hoang sinh ra ở đâu

[DK] Chỉ có **hai** lời gọi tạo trân thú hoang trong toàn bộ `Game_2/Script` (33 chỗ dùng `CreatePetOnScene`):

| Nguồn | File | Trạng thái |
|---|---|---|
| Quái mang script `petdropper` chết | `Game_2/Script/scripts/obj/monster/petdropper.lua` (script id **501000**) | **CHẠY — đã đo live** |
| Growpoint "rương báu" mọc ra trân thú | `gp_treasuredropper_*.lua` + `gp_yanwanggumu.lua` (31 file) | **CHẾT — xem 1.2** |

```
monster:OnDie  ->  petdropper.lua:OnDie
     g_PetDropList[GetMonsterDataID(objId)]        -- 62 ID quai
     math.random(10000) > dropOdds  -> bo qua      -- 111..10000 / 10000
     chon petDataID trong petList (AlienPetPower)  -- 342 ID tran thu
     CreatePetOnScene(petDataID, x, z)
        -> script_base:CreatePetOnScene            (lualib/script_base.lua:5874)
        -> scenecore:create_wild_pet               (services/scene/scenecore.lua:9915)
              petmanager:make_capture_pet_attrib(...)
              scenecore:create_pet(conf, INVAILD_ID, pos)
     SetPetCaptureProtect(petObjID, occupantGuid)  -- 300 s, uu tien nguoi ha quai
     SetCharacterDieTime(petObjID, 180000)         -- tran thu hoang song 180 s
```

Gói ra client: **`GCNewPet` (1216)** / `GCNewPet_Move`; `WorldModel` đã có sẵn `Kind::Pet`
(`Src/Client/NetCore/WorldModel.cpp:119-126`).

### 1.2 [DK] Nhánh growpoint "rương báu" là NHÁNH CHẾT — không phải chưa bật

Mỗi `gp_treasuredropper_*.lua` có mục `["itemType"] = 9` (trân thú) với `["odd"] = -1.0`, và tổng
odd của **các mục đứng trước nó đúng bằng 1.0**. `GetTableIndexByOdd` chọn theo tích luỹ:

```lua
local oddNow = math.random()          -- [0, 1)
if (tb[i]["odd"] + base >= oddNow) then return i end
```

Muốn trúng mục trân thú phải có `1.0 + (-1.0) = 0 >= oddNow` ⇒ xác suất coi như 0.
Đo trên cả 31 file (`growpoint-pet-scripts.tsv`): **30/31** đúng khuôn đó, 2 file không có mục
itemType 9. [SL] `-1.0` là sentinel "tắt" của bản gốc. **Đừng đổi thành số dương** nếu chưa có
quyết định thiết kế — làm vậy là chế số và sẽ rải trân thú ra toàn bộ bản đồ dã ngoại.

### 1.3 Thu phục / triệu hồi / cất về túi

| Việc | Kỹ năng / gói | Mã server |
|---|---|---|
| Thu phục | SkillTemplate **1** 捕兽 → SkillData 1, `技能逻辑ID = 10`, 聚气 **15 000 ms**, tầm 0–8 m | `scene/skill/human/skill_10.lua` → `human:capture_pet` |
| Triệu hồi | `CGManipulatePet` (**435**) `type = 0` | `scenecore:char_manipulate_pet` → `skill_11` → `human:call_up_pet` |
| Cất về túi | `CGManipulatePet` `type = 1` | `human:recall_pet` |
| Trả lời | `GCManipulatePetRet` (**666**) `{PetGUID, is_fighting u32, ret i32}` | `ENUM_MANIPULATEPET_RET`: **0** bắt hụt, **1** bắt được, **2** gọi hụt, **3** gọi được, 4/5 phóng sinh, 6/**7** thu về, 8/9 dung hồn |
| Liệt kê túi thú | `CGAskDetailAttrib` → một **`GCDetailAttrib_Pet` (512)** cho mỗi con | `scenecore.lua:1187` → `human:send_pets_detail` |

[DK] Nhân vật test có sẵn cả hai kỹ năng: `char_menpai.py BASE_SKILLS = [0, 1, 2, 3, 21, 22, 34, 35, 43]`.
[DK] Túi thú **6 ô** (`define.DEFAULT_PET_NUM = 6` + `attrib.pet_num_extra`).

### 1.4 Trứng trân thú — script THẬT là cột `脚本编号` của `CommonItem`

[DK] `scripts/obj/commonitem` có 10 file chứa bảng `g_petList` (596 mục vật phẩm), nhưng server
dispatch theo `CommonItem.txt` cột 13 → `scripts.lua[id]`. Đo được (`egg-script-truth.json`):

| File thật sự được gọi | Số trứng | Chốt `GetIsPetID` | Chốt `TryCreatePet` |
|---|---|---|---|
| `300027.lua` | 356 | 3 | 2 |
| `332003.lua` | 1 | 0 | 1 |
| `charged_38000082.lua` | 1 | – | – |

Sáu file còn lại (`890041`, `891217`, `893088`, `893308`, `998515`, `998545`) **không có vật phẩm
nào trỏ tới** ⇒ mã chết.

[DK] **24 shop** trong `ShopTable.txt` bán trứng trân thú ⇒ người chơi lấy được trân thú cả khi
không đi bắt hoang.

---

### 2.1 Bảng dữ liệu

| Bảng | Trước 17/09 | Sau đợt này |
|---|---|---|
| `R/configs/PetAttrTable.txt` | 8 587 ID × 51 cột | **8 651 ID** |
| `R/configs/MonsterAttrExTable.txt` | 29 058 ID × 71 cột | **29 122 ID** |
| ID trân thú có dòng quái tương ứng | 8 587 / 8 587 | **8 651 / 8 651** |
| `PetSkillDistribute` | 1 448 ID, đều có trong PetAttr | không đổi |
| `PetCollection` | 648 dòng | không đổi |

[DK] `PetCollection` **không có nơi nào dùng phía server** (`cfghelper:read_pet_collection` nạp,
`configenginer` liệt kê, `grep` toàn bộ `services`/`lualib` không có lời gọi `get_config` nào khác).
[SL] Đó là bảng đồ giám cho client ⇒ "648 / 8 651" **không phải lỗ hổng**.

### 2.2 [DK] Đã nhập 64 dòng trân thú thiếu — đúng luật, nhưng giá trị THỰC nhỏ hơn tưởng

64 ID trân thú mà bảng `g_petList` trỏ tới không có dòng trong hai bảng của server riêng ⇒ nếu có
đường nào tới được `petmanager:make_capture_pet_attrib` thì gặp `assert(false, "不存在珍兽ID")`.
Bảng CY `DataCY31-08-26` **không có** 64 ID này (0/64); server 0.85 gốc `/home/ubuntu/configs`
**có đủ 64/64 ở cả hai bảng, header giống hệt từng byte** ⇒ chép dòng nguyên văn.

**Đã áp 17/09 12:14Z** bằng `Tools\server\pet_data.py` (append-merge, không chép đè):

```
PetAttrTable        8 587 -> 8 651  (+64)   sha aa1c977b78de777097576a6dea1ed11acc195dede6445a697134dc7497a9337f
MonsterAttrExTable 29 058 -> 29 122  (+64)  sha c0d0e1f01e54f5d4cbbf07f18bf47468aa08c23168da6232ba84e368bdebb522
backup R/backups/pet-data-20260917T121403Z/ ; verify PASS (missing [] / [])
```

**Nhưng [DK]: bản nhập này mở khoá 0 vật phẩm đang dùng được.** Chỉ **9** trứng có thật trỏ tới một
trong 64 ID, và **cả 9 đều nằm trong nhóm lệch ánh xạ ở mục 2.3** — `CommonItem` gửi chúng sang
`300027.lua`, file đó không có mục `g_petList` cho chúng, nên chúng bị từ chối từ trước đó với
"Đạo cụ chưa mở, không thể sử dụng". Giá trị thật của bản nhập là **đóng lỗ hổng dữ liệu và triệt
đường `assert`**, không phải "sửa 38 trứng".

> Đã đo live 19:37: trứng `30309096` (lv 95) dùng ở nhân vật lv 15 → server trả tip
> `等级不足`, `count 1→1`. Không kết luận được gì về 64 dòng từ lượt đó.

### 2.3 [DK] LỖI THẬT đã SỬA: bắt trân thú khi túi thú đầy làm hỏng cả scene

```
skill_10.lua:effect_on_unit_once  ->  human:capture_pet          (obj/human.lua:7826)
                                          petmanager:create_guid_of_pet
                                          human:add_pet          (obj/human.lua:6867)
                                              assert(empty_index ~= define.INVAILD_ID)   <-- NỔ
```

Nhánh TRỨNG có chốt `TryCreatePet` sẵn; nhánh BẮT HOANG **không có chốt nào**. Hai nhánh đấu giá
nguyên bảo (`scenecore:auction_buy_after_do`, `auction_take_back_after_do`) cũng gọi `add_pet` trần.

**Chứng minh mà KHÔNG làm hỏng scene nào**: `Tools\server\pet_bagfull_tests.lua` rút đúng ba hàm ra
khỏi file thật, nạp bằng `load` với container giả rồi gọi với túi đầy.

```
lua5.4 Tools/server/pet_bagfull_tests.lua <human.lua>
  bản gốc (backups/pet-bagfull-20260917T124857Z/human.lua)  RESULT checks=13 failed=8  FAIL
  bản đã vá (R/GameServer/.../obj/human.lua)                RESULT checks=13 failed=0  PASS
```

**Bản vá** (`Tools\server\pet_bagfull.py apply`, backup `R/backups/pet-bagfull-20260917T124857Z/`,
`luac5.4 -p` rc 0, chạy lại không đổi):

1. `human:capture_pet` — chốt trước khi sinh guid: `cal_item_space() < 1` ⇒ `notify_tips` +
   `OR_BAG_OUT_OF_SPACE (-15)` + `return false`. `skill_10` nhận `false` và gửi
   `GCManipulatePetRet ret = 0 CAPTUREFALID` ⇒ **từ chối êm**, đúng như nhánh trứng.
2. `human:add_pet` — bỏ `assert`, ghi `[PET_BAG_FULL]` rồi `return false`. Lưới an toàn cuối cho
   MỌI người gọi, kể cả hai nhánh đấu giá.
3. `human:add_pet_by_data_id` — trả kết quả THẬT của `add_pet` thay vì luôn `true` (trước đây trứng
   thất bại vẫn báo thành công cho script sau khi đã tiêu hao vật phẩm).

> **CẦN RESTART** mới nạp (module service, không nằm trong `scriptenginer:reload_scripts`).
> Cách đo live nằm ở mục 5 bước 2. **Không** cố tình làm hỏng scene để thử trước khi restart.

[DK] `services/scene/human.lua` là **bản sao chết** của cùng nội dung (không có `require "scene.human"`
ở đâu; bản sống là `scene.obj.human`). Bản vá chỉ chạm bản sống.

### 2.4 [DK] 169/517 trứng trân thú lệch ánh xạ script — vẫn CHƯA sửa được

`egg-script-truth.json`: trong 517 vật phẩm trứng có mặt ở `CommonItem.txt`, chỉ **348** có
`脚本编号` trỏ tới đúng file Lua chứa mục `g_petList` của chúng. **169** trỏ sang file khác ⇒ script
đó tra `g_petList[itemTblIndex]` ra `nil` ⇒ từ chối "Đạo cụ chưa mở, không thể sử dụng."

Nguyên nhân đo được:

| Vật phẩm | server riêng / DataCY | server 0.85 / client_GL |
|---|---|---|
| 30309096 | lv 95, script **300027** | lv 95, script **893088** |
| 30309097 | lv 45, script **300027** | lv 95, script **893088** |
| 30309900 | lv 75, script **300027** | lv 1, script **891217** |
| 30309903 | lv 55, script **300300** | lv 1, script **891217** |

`CommonItem.txt` của server riêng **giống DataCY từng dòng** (20 421 dòng — `cs3c-tables` nhập theo
ID CY), còn `Game_2/Script` vẫn là cây script **0.85**. Nghĩa là bên CY những vật phẩm đó do
`300027`/`300300` lo, và `300027.lua` đời CY hẳn có mục cho chúng — nhưng **ta không có script
server đời CY**. ⇒ **Không có nguồn thật để sửa.** Hai lối đều là chế dữ liệu:
(a) trả `CommonItem` về giá trị 0.85 thì phá quyết định "CommonItem theo ID CY" của `cs3c-tables`;
(b) tự viết mục `g_petList` mới trong `300027.lua` thì là chế số.
**Ghi lại, chờ quyết định.**

### 2.5 [DK] Trân thú hoang trong thế giới — con số cuối

`scripts/30-survey-petdropper.py` (đối chiếu `type` từng mục `R/Game_2/Scene/*_monster.ini` với
`g_PetDropList` + cờ `active` của `configs/SceneInfo.ini`):

| Mốc | Cảnh bật | Quái rơi trân thú trong cảnh ĐANG BẬT | ID trân thú tới được |
|---|---|---|---|
| 17/09 ~18:30 | 366 | **0** | **0** |
| 17/09 ~19:10 (sau khi `maps-all` bật cảnh) | 501 | **41 loại / 46 chỗ đặt** | **251** |
| 17/09 ~19:35 (sau restart 19:31:52, 195 cảnh `type=0` sống) | 501 | **41 loại / 46 chỗ đặt** | **251** |

**Không đổi sau restart**: 135 bản đồ mới mang 17 725 quái nhưng **không có quái rơi trân thú nào**,
và không sinh thêm file `_monster.ini` (vẫn 388 file). Trân thú hoang chỉ nằm trong 7 file bản đồ:

| Cảnh | Tên | File | Quái rơi thú | Ghi chú |
|---|---|---|---|---|
| **39** | 玄武岛 | `petisland` | 26 loại, 244 chỗ, tỉ lệ 1 263–1 521 / 10 000 | đảo trân thú chính |
| **158 / 394** | 圣兽山 | `petisland_1` | 6 loại, 152 chỗ | |
| **62 / 82 / 182** | 后花园 | `newbie_2` | quái **558** 飘飘鸭 × 20, tỉ lệ **10 000 / 10 000 = 100 %** | **nhanh nhất để đo** |
| **188** | 银皑雪原 | `bingkang` | 4 loại, 40 chỗ | |
| **163 / 166** | 燕王古墓 5/8 | `bashu_5/8` | 8550–8553, tỉ lệ 111–556 | rất hiếm |
| 433 | 昆仑山 | `kunlunshan` | 3420/6570 × 20, **`script_id = -1`** | **không rơi thú — xem 2.6** |

[DK] 8 651 ID trân thú, **862** tới được bằng một cơ chế có thật (565 qua trứng + 342 qua
petdropper, có giao nhau). [SL] Phần còn lại là biến thể sinh ra từ sinh sản – hoàn đồng – huyễn hoá.

### 2.6 [DK] Cảnh 433 昆仑山 `script_id = -1` — ĐO RỒI, KHÔNG SỬA

Quy tắc trên server riêng: **484 / 504 = 96,0 %** chỗ đặt quái rơi thú dùng `script_id = 501000`;
**20 / 504 = 4,0 %** dùng `-1`, và **cả 20 đều ở duy nhất `kunlunshan`**.

Nhưng đối chiếu ba nguồn độc lập (`kunlunshan-script-id.json`):

| Nguồn | `kunlunshan` 3420/6570 | `bingkang` 3420/6570 |
|---|---|---|
| server riêng | `script_id = -1`, `base_ai = 17`, respawn 15 000/30 000 | `501000` |
| server 0.85 gốc `/home/ubuntu` | `script_id = -1`, `base_ai = 17`, respawn 15 000/30 000 | `501000` |
| snapshot `wsl/source-snapshot` | `script_id = -1`, `base_ai = 17`, respawn 15 000/30 000 | `501000` |

**Ba nguồn đều nói `-1`** và quái ở đó còn khác cả `base_ai` lẫn nhịp hồi sinh so với `bingkang`
⇒ đây là **dữ liệu gốc có chủ ý**, không phải sót khi nhập bản đồ. Sửa = chế dữ liệu ⇒ **BỎ**.

### 2.7 [DK] DBC client `PetAttrTable.txt` — KHÔNG nối, vì không có nguồn thật

| Nguồn | Định dạng | Số dòng | Có bao nhiêu trong 64 ID |
|---|---|---|---|
| `Assets/CanonicalCY/.../PetAttrTable.txt` | nhị phân `00CCBBDD`, **54 cột** | 8 589 | — (đích) |
| `Tools/DATA NEW/DataCY31-08-26/.../PetAttrTable.txt` | văn bản, **54 cột** | 8 589 | **0 / 64** |
| `C:\TLBB\085\client\...` (0.85 gốc) | văn bản, **51 cột** | 4 804 | 57 / 64 |
| `C:\TLBB\085\client_GL\...` | văn bản, **51 cột** | 4 908 | 64 / 64 |
| `Tools/DATA NEW/CYHJ091026/...` | văn bản, **51 cột** | 4 900 | 58 / 64 |

Không có nguồn **54 cột** nào chứa dù chỉ một trong 64 ID. Và hai lược đồ **không phải quan hệ
"51 cột + 3 cột thêm"**: chúng lệch ngay từ **cột 43** (GL `INT` ↔ CY `STRING`). Chuyển 51 → 54 là
tự đặt nghĩa cột ⇒ chế số. **BỎ.**

Hệ quả của việc bỏ, đã đo: client chỉ dùng bảng này cho `Pet_GetPetFoodType`
(`Src/Client/WXClient/DataPool/GMDataPool.cpp:3073`) và **có null-check** ⇒ thiếu dòng chỉ làm
"loại thức ăn = invalid", **không crash**; tên và model của thú đi theo dây (`GCDetailAttrib_Pet`).

---

### 3.1 Trứng → túi thú → triệu hồi → cất về túi

`live/egg-summon-190848/` (test14 / GUID 200015), `exit_code 0`, `decode_failures 0`,
`unknown_packets 0`, log server `traceback=0 error=0`.

| Bước | Gói / lệnh | Kết quả |
|---|---|---|
| Đặt trứng | `give_item.py give --item 30309002` | ô 5, 珍兽蛋：兔子 |
| Dùng trứng | `CGUseItem` (473) → `GCUseItemResult` | `result = 0`, số lượng **1 → 0** |
| Liệt kê | `CGAskDetailAttrib` → `GCDetailAttrib_Pet` (512) × 2 | guid `200015:1291469`, `data_index` **3009** 兔子宝宝, lv 1, hp 200/200 |
| Triệu hồi | `CGManipulatePet` `type = 0` | **`ret = 3` CALLUPSUCC**, `GCNewPet` × 1 |
| Cất về túi | `CGManipulatePet` `type = 1` | **`ret = 7` RECALLSUCC**, thú trong cảnh 1 → 0 |

Mongo: `pet_bag_list` 1 con (`data_id 3009`, `growth_rate 0.594`, `happiness 100`,
`life_span 66236`); `attrib.pet_guid` về `{0,0}` — đúng, `recall_pet` đặt lại guid rỗng.

### 3.2 Trọn vòng THÚ HOANG trong MỘT phiên — `live/capture-s62d-194602/`

Cảnh **62 后花园**, bot đứng ngay ô sinh của quái **558** `(41, 32)`, lệnh
`--attack 8 --hunt 41,32 --pet-capture 1 --pet 2 --pet-fight-ms 10000`.
`exit_code 0`, `decode_failures 0`, log server `traceback=0 error=0`.

| Bước | Đo được |
|---|---|
| Vào đúng cảnh | `AUTO_ROUTE_ENTER … scene= 62`, `final_scene 62` |
| Hạ quái | `kills = 8`, `damage_dealt = 17` |
| **Thú hoang mọc** | `GCNewPet obj=63 / 64 / 65` ngay sau các lượt hạ quái (`live/capture-s62c` core-loop 2204 ms, 12997 ms, 15801 ms) |
| **Thu phục** | `CGCharUseSkill` skill 1 → **`GCManipulatePetRet ret = 1` CAPTURESUCC** |
| Túi thú | **2 → 3**, con mới `200015:940210`, **`data_index 558`**, hp 166/166, tên GBK `506869c3aa7520506869c3aa7520c38170` = "Phiêu Phiêu Áp" |
| Triệu hồi con vừa bắt | **`ret = 3` CALLUPSUCC**, `GCNewPet` × 1, `pet_objects_in_scene = 2` |
| **Trân thú đánh nhau** | `damage_dealt = 17`, `kills = 8` trong lúc thú ở ngoài |
| Cất về túi | **`ret = 7` RECALLSUCC** |

Hai số đo phụ, đều lấy từ `live/capture-s62c-194314/`:
- **Thời gian trả lời của 捕兽 là ~22 s tính từ lúc tung**, không phải 15 s (聚气 15 s cộng phần
  tiếp cận/khởi thức của server). Bot ban đầu chỉ chờ 22 s nên bỏ lỡ; nay chờ 45 s.
- Triệu hồi ngay sau khi bắt trả **`ret = 2` CALLUPFALID với `operate_result -17 OR_BUSY`** —
  người tung vẫn đang trong chiêu. Bot nay chờ 4 s rồi thử lại một lần.

---

### 4.1 `Tools\server\pet_data.py` — `plan | apply | verify`

Chỉ THÊM dòng, giữ GBK + EOL gốc, sao lưu trước khi ghi, chạy lại không đổi. **`apply` nối dòng vào
bản ĐANG CÓ trên server, không chép đè file staging** — vì `MonsterAttrExTable.txt` dùng chung với
agent bản đồ. `verify` khẳng định GBK, đủ cột, không ID trùng, mọi ID mà script trứng/petdropper trỏ
tới đều có dòng ở cả hai bảng.

### 4.2 `Tools\server\pet_bagfull.py` + `pet_bagfull_tests.lua`

`plan | apply | verify` vá theo NEO nguyên văn (idempotent, có `luac -p`), và bộ kiểm **ngoại tuyến**
bằng `lua5.4` rút đúng ba hàm ra khỏi file thật. Trước vá 8/13 fail, sau vá 0/13 fail.

### 4.3 `CysNetBot` — ba cờ mới (`Src\Tools\CysNetBot\main.cpp`, thẻ `CYS-PET`)

```
--pet 1|2               1 = liệt kê túi thú; 2 = thêm triệu hồi + cất về túi
--pet-capture 0|1       tung SkillTemplate 1 捕兽 vào trân thú hoang gần nhất
--pet-fight-ms 0..60000 giữ thú ngoài bao lâu trước khi cất (mặc định 12 000)
```

Máy trạng thái `Pt`: `ask → ask_wait → [capture_pick → capture_arrive → capture → capture_wait →
ask2 → ask2_wait] → summon → summon_wait → fight → recall → recall_wait → done`.
Khi có `--pet-capture`, pha `Attack` chạy TRƯỚC pha `Pet` (phải có quái rơi thú chết thì mới có thú
hoang). `CGManipulatePet` dựng ngay trong `main.cpp` (như `CGUseItem` của `CYS-ITEM`) vì `WorldModel`
ngoài phạm vi ghi. `result.json` có khối `"pet"`: `pet_bag[]` (guid, data_index, level, hp, tên GBK
hex), `last_ret`, `captures_sent`, `summons_sent`, `recalls_sent`, `new_pet_objects`, `summary`.

Bản dựng `Build\bot-pets\CysNetBot.exe` sha256
`9F029EF48EBB51443710259FBD1AFC5B1D8CB412F21DF19486DB2F26FC5F1CC6`. Bốn bộ test:
`cys_netbot_tests` 28/0 · `cys_netcore_tests` 18 PASS · `cys_world_tests` 83 PASS ·
`cys_protocol_tests` 497 gói PASSED.

### 4.4 Script khảo sát (chỉ đọc, chạy lại được) — `Build\Logs\2026-09-17-pets-wild\scripts\`

`10-survey-wild-pets.py`, `20-survey-growpoint-pets.py`,
**`30-survey-petdropper.py`** (bảng quan trọng nhất), `40-pet-data-integrity.py`,
`50-run-pet-bot.ps1`, `60-show-pet-mongo.py`,
`70-kunlunshan-script-id.py`, **`80-egg-script-truth.py`** (script THẬT của từng trứng).

---

## 5. Việc còn lại

1. **Sau lần restart kế tiếp — đo live bản vá túi thú đầy.** Túi thú 6 ô; test14 đang có 3 con.
   Đặt thêm 3 trứng `30309002` (lv 5) rồi dùng hết để lấp đầy, sau đó chạy lượt bắt:
   ```
   give_item.py give --guid 200015 --item 30309002 --count 1      # lặp 3 lần
   50-run-pet-bot.ps1 -Label bagfull -DwellMs 200000 `
       -BotArgs @('--use','30309002','--attack','8','--hunt','41,32','--pet-capture','1','--pet','1')
   ```
   Kỳ vọng: `GCManipulatePetRet ret = 0` (CAPTUREFALID) + một `GCScriptCommand cmd 5` mang câu
   "Túi Trân thú đã đầy…", **log server `traceback = 0`**. Trước bản vá chỗ này ném `assert`.
2. **Chờ quyết định — 169 trứng lệch ánh xạ script** (mục 2.4). Cần người chốt: giữ `CommonItem`
   theo CY và chấp nhận 169 trứng không dùng được, hay trả riêng nhóm đó về script 0.85.
3. **Đã đóng, đừng làm lại:** DBC client `PetAttrTable` (mục 2.7 — không có nguồn 54 cột);
   cảnh 433 `script_id = -1` (mục 2.6 — ba nguồn đều vậy); nhánh growpoint `odd = -1.0`
   (mục 1.2 — sentinel tắt của bản gốc); `PetCollection` 648 dòng (mục 2.1 — bảng client).

---

## 6. Bẫy đã sập, ghi lại để khỏi sập lần nữa

1. **Script của một vật phẩm là cột `脚本编号` của `CommonItem.txt`, KHÔNG phải file Lua có chứa
   `g_petList[<item>]`.** Tôi đã kết luận sai một lần vì đọc ngược chiều. Kiểm bằng
   `80-egg-script-truth.py`.
2. **Đừng đo "trân thú đặt trong `*_monster.ini`" rồi kết luận.** Mục `[monsterN]` có `type` trùng ID
   trân thú vẫn là **quái**; thứ quyết định là `script_id = 501000`. `R/Game_2/Scene/*_pet.ini`
   (72 file) **server này không đọc** — không có chỗ nào trong `GameServer` nhắc tới `pet.ini`.
3. **`odd = -1.0` trong bảng rơi đồ = TẮT**, không phải "thiếu số".
4. **Bảng server 0.85 gốc là nguồn hợp lệ** khi CY không có dòng — nhưng phải kiểm dòng kiểu + dòng
   tên khớp từng byte trước khi chép. 147 dòng trong `PetAttrTable.txt` gốc có TAB thừa cuối dòng
   (cột thừa đều rỗng): phải cắt cho đúng bề rộng header, nếu không `write_table` ném
   "row has 52 cols, want 51".
5. **Sửa file dùng chung thì phải NỐI, không chép đè.** `MonsterAttrExTable.txt` đang được agent bản
   đồ sửa song song.
6. **`char_menpai.py set --scene` không đưa được vào cảnh chưa nạp.** Server lặng lẽ đưa về cảnh mặc
   định và ghi `AUTO_ROUTE_ENTER … scene= 2`. Luôn đối chiếu `final_scene` trước khi kết luận
   "không có trân thú".
7. **`static-menpai.json` không có khoá `9`.** CYTest14 vốn ở môn phái 9; muốn dùng `set` phải chọn
   môn phái khác rồi `restore` sau.
8. **Trứng có yêu cầu CẤP ĐỘ** (`CommonItem` cột 8). Không đủ cấp thì `GCUseItemResult.result` vẫn
   là **0** nhưng vật phẩm KHÔNG bị tiêu hao và server gửi tip `等级不足`. Đọc `count` trước/sau và
   đọc tip, đừng tin mỗi `result`.
9. **Đứng đúng ô sinh của quái mới đo được.** Ở `newbie_2` quái 702 (không rơi thú) đông gần gấp đôi
   quái 558 (rơi thú 100 %); đứng ở `(45, 32)` hạ 3 con thì 0 thú hoang, đứng ở `(41, 32)` hạ 8 con
   thì 3 thú hoang.
