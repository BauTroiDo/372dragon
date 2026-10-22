# Vòng đồ đạc trên server riêng CY — rơi, nhặt, túi, mặc, mua/bán, dùng — 17/09/2026

Tiếp nối [core-loop_vi.md](core-loop_vi.md) (nhặt hộp rơi ở tầng gói) và [inventory-equip_vi.md](inventory-equip_vi.md)
(túi, trang bị, cửa hàng NPC). Phần này **đo live từng khâu** của vòng đồ đạc trên server riêng
`/home/ubuntu/cys-test-20260913` (login 15733 / game 15734) bằng `Build\bot-item\CysNetBot.exe`, và chỉ ra chính xác
khâu nào hỏng cùng nguyên nhân gốc.

Ký hiệu: **[DK]** dữ kiện đọc từ mã/bảng; **[SL]** suy luận chưa kiểm; **[LIVE]** đã đo trên server riêng.
Bằng chứng: `Build\Logs\2026-09-17-item-live\` (live-1..live-6, `impact-audit.txt`, `proposal-numbers.txt`, `char\`).
Tài khoản đo: `test03` / CYTest03 (GUID 200004), cấp 15, phái 9 (chưa nhập phái), giao tử 28,88 triệu, vàng 0.

## 1. Bảng tổng kết — khâu nào chạy, khâu nào không

Đo hai đợt: **trước** khi vá dữ liệu (live-1…live-6) và **sau** khi vá (live-7…live-9, server restart 15:27:39).

| # | Khâu | Trước vá | Sau vá | Bằng chứng sau vá |
| --- | --- | --- | --- | --- |
| 1 | **Quái rơi đồ** | HỎNG — `GCNewItemBox` 0 sau 4 mạng | **CHẠY** | live-9: 8 mạng → `box=365 owner=200004 mine=1` |
| 2 | **Nhặt hộp rơi → vào túi** | chưa đo được | **CHẠY** | live-9: `GCBoxItemList` → `pick 30700232` → `GCPickResult` → Mongo `prop_bag` ô 7 |
| 3 | Túi (hỏi, đổi ô, tách, vứt) | CHẠY | CHẠY | live-3: split 2, discard 0, swap 1 (hai chiều) |
| 4 | **Mặc / tháo + thuộc tính đổi theo** | CHẠY, có số | CHẠY | live-1/5/6: `att_p 278 → 203 → 278` quanh `CGUnEquip`/`CGUseEquip` |
| 5 | **Mua ở cửa hàng NPC** | CHẠY | CHẠY | `GCShopBuy result=0`, giao tử trừ đúng giá |
| 6 | **Bán ở cửa hàng NPC** | CHẠY | CHẠY | live-3: `−300 +202 = −98` khớp từng đồng |
| 7 | **Dùng thuốc máu** | HỎNG — mất đồ, máu không đổi | **CHẠY** | live-7: `GCDetailHealsAndDamages +450`, **hp 400 → 850**, số lượng 5 → 4 |
| 8 | **Dùng thức ăn** | HỎNG — chỉ 1 trong 2 impact vào | **CHẠY** | live-8: 2 cặp `GCDetailBuff`+`GCCharBuff`, `GCDetailImpactListUpdate` 28 → **68 B** |

Hai hỏng đều là **lệch bảng dữ liệu CY vs script 0.85**, không phải lỗi mã — xem mục 5 và 6. Cả hai **đã được vá**
(mục 5.4 và 6.3) và đã đo lại thành công; chi tiết lượt đo sau vá ở **mục 9**.

## 2. Wire của khâu còn thiếu trong hai đặc tả trước

| Hành động | Client → server | Server → client | Handler server | Trạng thái |
| --- | --- | --- | --- | --- |
| Dùng vật phẩm | 473 `CGUseItem` {bagIndex u8, item_index u32, pet_guid ItemGUID, target_obj_id i32, target_pos_x/y f32, target_dir f32, pet_guid_2 PetGUID, target_bag_index u8} | 117 `GCUseItemResult` {result i32} + 623 `GCItemInfo` (ô bị trừ) + 331 `GCCharSkill_Send` + 85 `GCCooldownUpdate`; nếu impact có thật thì thêm 1170 `GCCharSkill_Lead` + 285 `GCDetailBuff` + 153 `GCCharBuff` | `scenecore.lua:2979 char_use_item` | **[LIVE]** |
| (bị cooldown) | 473 | 117 `GCUseItemResult` **result 0** + 7 `GCOperateResult` **−6** | AI chặn trước `OnDeplete` | **[LIVE]** — món **không** bị trừ |

Bot điền gói y như client: `bagIndex` và `item_index` **phải khớp nhau**, nếu không `char_use_item` bỏ gói im lặng
(`item_index == use.item_index` ở dòng 2999) **[DK]**. Với thuốc dùng cho bản thân thì `target_obj_id` = đối tượng
của chính mình, `target_pos` = vị trí của mình, `pet_guid`/`target_bag_index` bỏ trống **[LIVE]**.

### 2.1 Luồng server của một vật phẩm "giống kỹ năng"

`char_use_item` → `config.script_id` (cột 13 `CommonItem.txt`) → `scriptenginer:item_is_skill_like_script`
(`IsSkillLikeScript` = 1 với mọi thuốc) → `obj_me:get_ai():push_command_use_item(...)` →
`services/scene/skill/human/script.lua action_active_once_handler`:

1. `OnConditionCheck` — thuốc máu tự từ chối khi máu đầy (`item_3001` → `OR_HEALTH_IS_FULL`) **[DK]**;
2. `OnDeplete` → `LuaFnDepletingUsedItem` — **trừ món ngay ở bước này**;
3. `register_instant_action_for_script` + `set_cool_down`;
4. `OnActivateOnce` → `LuaFnSendSpecificImpactToUnit(self, self, self, g_Impact1, 0)`.

**Thứ tự này là chỗ đau**: món bị trừ ở bước 2, còn tác dụng mới được gửi ở bước 4, và bước 4 thất bại **im lặng**
(`impactenginer:send_impact_to_unit` → `init_impact_from_data` trả `false` khi không có dòng impact, dòng 62–65
`skynet.loge` đã bị chú thích) **[DK]**. Người chơi mất thuốc mà không nhận được gì, `GCUseItemResult` vẫn là 0.

### 2.2 NPC mở thẳng cửa hàng, không có bảng chọn

`inventory-equip_vi.md` mô tả đường 1095 `CGCharDefaultEvent` → 397 `GCScriptCommand` (bảng chọn) → 107
`CGEventRequest` → 797. Có một lớp NPC **không** đi đường đó: `OnDefaultEvent` gọi thẳng `DispatchShopItem`, nên
server trả **797 + 321 ngay**, không có 397 nào cả **[LIVE]**. Tiệm thuốc Lạc Dương là ví dụ:

```lua
-- Game_2/Script/scripts/obj/luoyang/oluoyang_baimengsheng.lua  (script id 49)
function oluoyang_baimengsheng:OnDefaultEvent(selfId, targetId)
    self:notify_tips(selfId, " Ghe xem, ngo thu nao!~")
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)   -- shop 14
end
```

Bot cũ chờ 397 đủ 5 giây rồi bỏ cả pha mua; `Build\bot-item` nhận 797 đến một mình là mở cửa hàng luôn
(`Inv::NpcMenu`, đánh dấu `// CYS-ITEM`).

### 2.3 Số lượng chồng trong `ItemInfo` — union theo lớp vật phẩm

`ItemInfo` là **union có thẻ**: server chọn nhánh bằng `flag = math.floor(item_index / 10000000)` (chính là
`define.ITEM_CLASS`) rồi ghi khối cố định của lớp đó (`services/game/packet_types/item_types.lua` `bos()` dòng
190–235) **[DK]**. Số lượng chồng nằm **bên trong khối ấy**, đúng ô mà `set_lay_count` của lớp đó ghi
(`lualib/item.lua`, Lua đếm từ 1):

| lớp (`item_index/1e7`) | nhánh `flag` | khối trên wire | ô số lượng | ví dụ |
| --- | --- | --- | --- | --- |
| 1 `ICLASS_EQUIP` | 1 | các trường trang bị | — (`equip_data:copy_raw_data` đặt `lay_count = 1`) | 10106000 |
| 2 `ICLASS_MATERIAL` | 2 | `unknow_19[32]` | `unknow_19[0]` | 20310176 |
| 3 `ICLASS_STOREMAP` (vật phẩm thường / tiêu hao) | 3 | `unknow_20[32]` | `unknow_20[0]` | 30001001, 38008203 |
| 4 `ICLASS_TASK` | 4 | `unknow_21[32]` | `unknow_21[0]` | — |
| 5 `ICLASS_GEM` | 5 | `unknow_22[56]` | `unknow_22[48]` | — |

Bằng chứng khớp trong Mongo **[LIVE]**: món `30602001` (lớp 3) số lượng 3 có `unknow_20 = [3, 0, 0, …]`, món lẻ
có `[1, 0, …]`.

**ĐÃ SỬA 17/09**: trước đó `WorldModel` đặt cứng `BagItem::count = 1` cho mọi 623 `GCItemInfo`, nên số lượng của
một ô **sai** cho tới lần 263 `GCMyBagList` kế tiếp (đo được ở live-1: một chồng 3 viên sau khi dùng 1 hiện "1").
Nay `WorldModel.cpp` có helper `itemStackCount(const pg::ItemInfo_bos&)` đọc đúng ô theo lớp (mốc `// CYS-ITEM`).

## 3. Cửa hàng bán thuốc

`ShopTable` 14 — 35 món trả về trên wire, loại tiền cột 7 = **8 (giao tử)**, `can_multiple_buy` = 1 **[DK][LIVE]**.

| NPC | Cảnh | Toạ độ | script | shop | Mở được? |
| --- | --- | --- | --- | --- | --- |
| 白萌生 (Bạch Manh Sinh) | 0 Lạc Dương | **(230, 308)** | 49 | 14 | **CÓ** — `DispatchShopItem` đang bật **[LIVE]** |
| 卢三七 | 2 Đại Lý | (105, 123) | 2027 | 14 | KHÔNG — `--self:DispatchShopItem`, thay bằng "Tiệm tạm đóng cửa" |
| 杜子腾 | 2 Đại Lý | (108, 155) | 2028 | 5 (thức ăn) | KHÔNG — cả `AddNumText` lẫn `DispatchShopItem` đều bị chú thích |
| 胡凡 | 1 Tô Châu | — | — | 24 | KHÔNG — chỉ `notify_tips("Tiệm tạm đóng cửa")` |

Bốn file trên đều **giống hệt** ở server gốc `/home/ubuntu/Game_2`, nên đây là trạng thái sẵn có của bộ script chứ
không phải do CY-Source làm hỏng **[DK]**. Ở ba thành chính đang bật, **Lạc Dương (230,308) là nơi duy nhất mua được
thuốc**.

Giá và tiền đã kiểm từng đồng **[LIVE]** (live-3): mua 3 × `30001003` giá 100 → −300; bán lại một chồng 2 món giá
bán 101 → +202; giao tử 28.878.565 → 28.878.467.

## 4. Mặc trang bị làm thuộc tính đổi — số đo

Bot hỏi lại 678 `CGAskDetailAttrib` sau mỗi 88 `CGUnEquip` / 238 `CGUseEquip` và chờ 1,2 s. Vũ khí `10106000`
(điểm 0) trên CYTest03 **[LIVE]**, lặp lại giống nhau ở live-1, live-5 và live-6:

| Mốc | level | hp | mp | **att_p** | **att_m** | def_p | def_m | hit | miss |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| đầu lượt (đang mặc) | 15 | 500/2250 | 904/904 | **278** | **278** | 193 | 148 | 540 | 180 |
| sau `CGUnEquip` point 0 | 15 | 500/2250 | 904/904 | **203** | **203** | 193 | 148 | 540 | 180 |
| sau `CGUseEquip` point 0 | 15 | 500/2250 | 904/904 | **278** | **278** | 193 | 148 | 540 | 180 |

Vũ khí đóng góp **+75 công vật lý và +75 công nội** (`damage_point` 98 trong `equip_list` của Mongo). Phòng / chính
xác / né tránh không đổi — đúng với một vũ khí thuần công.

Cờ đọc trường của 1772 `GCDetailAttrib` (dùng để lấy đúng các số trên) **[DK]**, theo `PgPackets_combat.cpp`:
`flags[1]&1` level, `flags[1]&2` hp, `flags[1]&4` mp, `flags[2]&128` hp_max, `flags[3]&1` mp_max,
`flags[2]&8` att_physics, `flags[2]&32` att_magic, `flags[2]&16` def_physics, `flags[2]&64` def_magic,
`flags[3]&8` hit, `flags[3]&16` miss.

### 5.1 Hiện tượng đo được

live-1 / live-5 / live-6, `30001001` 行血散 ("hồi ngay 450 sinh lực"), máu 400–500 / 2250:

```
use_wait  CGUseItem bag=4 item=30001001 hp=500/2250 count=2
use       slot=4 item=30001001 result=0 hp 500->500/2250 count 2->1
```

`GCUseItemResult` = 0 (OR_OK), số lượng giảm 1 (khớp Mongo), **máu không đổi**, `heals_on_me = 0`,
không một gói 909 `GCDetailHealsAndDamages` nào. Lần dùng thứ hai bị `GCOperateResult −6` (cooldown) và **không**
bị trừ món — phần cooldown của server đúng.

### 5.2 Nguyên nhân gốc

`item_3001.g_Impact1 = 3001`, nhưng **`configs/StandardImpact.txt` của server riêng không có dòng 3001**.

| Bảng | Số dòng | Có 3001? | Nội dung 3001 |
| --- | --- | --- | --- |
| `/home/ubuntu/configs/StandardImpact.txt` (0.85 gốc) | 18.167 | **có** | 药品，立即恢复生命，1级 — logic **4**, tham số "HP修改量" = **450** |
| `cys-test-20260913/configs/StandardImpact.txt` (bảng CY) | 27.847 | **không** | — |

Bảng impact bị thay sang bộ CY ở commit `5a4529a` ("CS3c … MonsterDropBoxs/DropBoxContent/DropRateOfItemTable thay
bằng tlbb15 Server"), còn **`Game_2/Script/scripts/obj/commonitem/*.lua` vẫn giữ ID impact của 0.85**.

Quy mô (script `Build\Logs\2026-09-17-item-live\tools\item_impact_audit.py`, kết quả `impact-audit.txt`):

- 545 ID impact khác nhau được các script vật phẩm dùng;
- **161 ID không còn trong bảng CY** → 253 file script vô hiệu. Gồm **toàn bộ** thuốc máu/thuốc khí
  `3001…3012`, thuốc cao `3211…3213`, bánh trung thu `3013`, `3014/3015/3016` (hồi toàn bộ sinh lực/khí), thức ăn
  `3301`…;
- **329 ID vẫn tồn tại nhưng ĐỔI NGHĨA**. Đây là phần nguy hiểm hơn: `3905` từ "药品，增加定力25点" thành
  "天女散花" **logic 3 = sát thương trực tiếp**; `4915/4916` từ "送花" thành "摧魂定魄内功攻击"; `3531…3533`
  từ "圣火术，增加力量" thành "击鼓令" logic 11. Nghĩa là một số vật phẩm bây giờ **gây hiệu ứng khác hẳn**, kể cả
  hiệu ứng sát thương, lên chính người dùng.

### 5.3 Bằng chứng đối chứng (chứng minh đường dẫn mã KHÔNG hỏng)

live-2 dùng `30101031` 白蜂糕 (script 333301). Script này gửi **hai** impact: `g_Impact1 = 3301` (**không có** trong
bảng CY) và `g_Impact2 = 35` (**có**, "打坐回复" logic 10). Kết quả trên wire **[LIVE]**:

```
2712  117 GCUseItemResult   2712  623 GCItemInfo    2712  85 GCCooldownUpdate
2712  1170 GCCharSkill_Lead  2712  285 GCDetailBuff  2712  153 GCCharBuff      <-- impact 35 ĐÃ vào
2791  1116 GCCharStopAction  2870  285 GCDetailBuff (rỗng)                      <-- 35 cần "引导", bot động đậy nên tắt
```

Cùng một đường mã, impact **có trong bảng** thì vào được (buff hiện ra), impact **thiếu trong bảng** thì im lặng.
Vậy `CGUseItem` → `char_use_item` → script vật phẩm → `impactenginer` **chạy đúng**; chỉ thiếu dòng dữ liệu.

### 5.4 ĐÃ SỬA 17/09 — thêm 159 dòng `StandardImpact`

Người điều phối cấp phạm vi ghi, đã áp bằng `Tools/server/item_impacts.py` (luật `copy85`):

| | trước | sau | thêm |
| --- | --- | --- | --- |
| `configs/StandardImpact.txt` | **27.847** | **28.006** | **+159** |

- Hai bảng có **cùng 81 cột, cùng tên cột, cùng dòng kiểu**, nên mỗi dòng thêm là **bản chép byte nguyên vẹn** từ
  `/home/ubuntu/configs/StandardImpact.txt` (kể cả `Data_Index`) — không ánh xạ cột, không chế số.
- Chèn đúng vị trí sắp xếp (`Data_Index` vẫn tăng dần), **0 dòng cũ bị xoá hay đổi** (`diff` byte: 0 dòng `<`,
  159 dòng `>`), GBK giữ nguyên.
- Sao lưu: `backups/item-impacts-20260917T082442Z/`.
- Còn thiếu **2** ID: `4931`, `340001` — không có ở **cả hai** bảng nên không chép nguyên được; bỏ và ghi lý do
  trong `staging/item_impacts.tsv`.
- Mọi `logic` của 159 dòng mới (4, 5, 10, 11, 12, 13, 15, 17) đều đã đăng ký trong `impactenginer` và có file
  `services/scene/skill/impact_logic/std_impact_0xx.lua` **[DK]** — `verify` kiểm lại điều này trên bảng sống.

Phần **329 ID đổi nghĩa** KHÔNG động tới: xem mục 5.5.

### 5.5 329 ID vẫn tồn tại nhưng đổi nghĩa — danh sách xếp mức, KHÔNG sửa

`Build\Logs\2026-09-17-item-live\changed-meaning.tsv` (sinh bằng `tools\changed_meaning_audit.py`).
329 ID, **78 vật phẩm** bị ảnh hưởng. Xếp mức theo `逻辑ID` của dòng CY:

| mức | số ID | nghĩa |
| --- | --- | --- |
| **CAO** | **90** | dòng CY có logic 3 / 6 / 7 / 115 (**sát thương / khống chế**) **và** người nhận là **chính người dùng** |
| **VỪA-T** | **27** | cùng loại logic hại, nhưng người nhận là **mục tiêu** — không tự hại; cần bạn / đúng giới / cùng cảnh mới kích hoạt |
| VỪA | 184 | 0.85 là hồi/buff (logic 4/5/10/11/…) còn CY là triệu hồi / biến hình / cơ chế phái |
| THẤP | 28 | cùng `逻辑ID`, chỉ đổi tên trong bản CY |

#### Phải xét AI LÀ NGƯỜI NHẬN, không chỉ `逻辑ID`

Bản quét đầu tiên xếp nhóm hoa `4915/4916` lên **CAO** với lý do "vật phẩm đánh chính người dùng". **Sai.**
Đọc thẳng script thì đối số thứ ba của `LuaFnSendSpecificImpactToUnit(selfId, sender, RECEIVER, …)` mới nói ai
nhận, và `item_4915:OnActivateOnce` gửi cho **`targetId`**, không bao giờ cho `selfId` **[DK]**:

```lua
-- Game_2/Script/scripts/obj/commonitem/item_4915.lua
function item_4915:OnActivateOnce(selfId)
    local targetId = self:LuaFnGetTargetObjID(selfId)
    if (0 <= targetId) then
        if self:LuaFnIsFriend(targetId, selfId) then
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, targetId, self.g_Impact1, 0)
```

Dùng hoa mà không chọn ai thì món bị trừ nhưng **không impact nào được gửi**. Muốn kích hoạt phải: có mục tiêu +
hai bên là bạn (`LuaFnIsFriend` cả hai chiều) + khác giới (hoa hồng) hoặc cùng giới (君子兰). Vì vậy nhóm hoa được
hạ xuống mức **VỪA-T** — không tự hại, nhưng **người được tặng** ăn sát thương thay vì được cộng độ hảo hữu.
Không đo live được giữa hai tài khoản của agent này: CYTest03 và CYTest04 cùng `model 1` (cùng giới) và
`relation.friends` rỗng **[LIVE]**.

Công cụ nay phân loại theo cả hai yếu tố, con số sau khi sửa: **CAO 90 / VỪA-T 27 / VỪA 184 / THẤP 28**.

#### Mục CAO đã kiểm chứng LIVE — phù hồi thành

Trong 90 mục CAO, phần lớn là vật phẩm `(已废弃)` đã bỏ. Chỉ **ba** món còn dùng thật, và cả ba là **phù hồi
thành** bán bằng vàng ở shop 32 (`郎夫人`, Lạc Dương **(159, 288)**, script 65):

| item | tên | impact | 0.85 | CY | logic |
| --- | --- | --- | --- | --- | --- |
| `30501004` | 大理回城符 | 4831 | 大理回城符 | 宁闻不墨一段 | **9 → 3** |
| `30501005` | 苏州回城符 | 4832 | 苏州回城符 | 宁闻不墨一段 | 9 → 3 |
| `30501006` | 洛阳回城符 | 4833 | 洛阳回城符 | 宁闻不墨一段 | 9 → 3 |

`item_4831.lua` gửi `LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 4831, 0)` — người nhận là **chính
người dùng**. Đo live (live-11, live-13) **[LIVE]**:

```
1805  shop      GCShopMerchandiseList shop=32 npc=49 type=1 (vang) goods=16
1821  buy_wait  CGShopBuy index=12 count=1 price=100
2636  buy       GCShopBuy result=0 item=30501004 count=1       vang 1000 -> 900 -> 800
2699  use_wait  CGUseItem bag=7 item=30501004 hp=2250/2250
2762  (wire)    696 GCCharSkill_Gather        <-- phu la vat pham CO THOI GIAN NIEM (~10 s)
12771 (wire)    1692 GCDetailHealsAndDamages  sender = reciver = chinh minh, hp_modification < 0
```

Kết quả đọc lại từ Mongo sau phiên: **hp 2250 → 2219 (−31)**, phù **đã bị tiêu**, và **`sceneid` vẫn là 0
(Lạc Dương) — KHÔNG dịch chuyển về Đại Lý** như mô tả vật phẩm hứa ("传送玩家去大理").

⇒ Người chơi mua phù bằng vàng, mất phù, **bị đánh**, và không được dịch chuyển. Con số sát thương nhỏ (31) chỉ
vì impact 4831 của CY là `逻辑ID 3` với `物理攻击+ = 442` nên phụ thuộc công/thủ; **hướng** mới là vấn đề.

**Bẫy đo**: phù là vật phẩm niệm (`GCCharSkill_Gather`), gói sát thương tới **~10 giây** sau `CGUseItem` và món
chỉ bị tiêu khi niệm xong. Phải `--hold-ms ≥ 25000`, nếu không phiên kết thúc trước khi thấy gì (live-11 bắt
được gói ở pha `quitting`).

Hướng sạch hơn cho cả nhóm đổi nghĩa là **sửa `g_Impact1/2` trong script vật phẩm** sang ID CY tương đương, chứ
không phải sửa bảng. Quyết định thuộc về người dùng — công cụ chỉ liệt kê và xếp mức.

### 6.1 Hiện tượng đo được

live-4, Vô Lượng Sơn (cảnh 6), giết **4** quái bằng chiêu 0:

```
kill target 193 hp 0 ...    pickup no drop box within 4 s
kill target 192 hp 0 ...    pickup no drop box within 4 s
kill target 191 hp 0 ...    pickup no drop box within 4 s
kill target 190 hp 0 ...    pickup no drop box within 4 s
```

`boxes = 0`, không một gói 1694 `GCNewItemBox` nào; mỗi mạng đều có `GCDetailExp exp=273` nên đường "quái chết →
`on_die_after`" vẫn chạy bình thường.

### 6.2 Nguyên nhân gốc

`monster:on_die_after` → `dispatch_item_box` → `caculate_drop_ruler` → `itemdropmanager:caculate_drop_item_box(model)`,
với `model` = cột `type` trong file `<scene>_monster.ini` (`scenecore.lua:711 db_attribs.model = conf.type`) **[DK]**.
Tra `monster_drop_boxs[model]`, không có thì trả về danh sách rỗng, và **không có hộp nào được tạo**.

Đối chiếu ba bảng (script `tools\item_impact_audit.py` phần cảnh, kết quả trong HANDOFF):

- `scenemanager_core:createScenes()` chỉ dựng cảnh có **`active = 1` VÀ `type = 0`** → server riêng chạy đúng
  **17 cảnh**: 0, 1, 2, 6, 71–74, 77, 1311, 1312, 1315, 1316, 1320, 1321, 1500, 2218 **[DK]**;
- `MonsterDropBoxs.txt` (bản CY, 677 dòng) có ID quái **704…52908**; quái của Vô Lượng Sơn là `900…909`
  (高山白猿, 闪电豹, 山蛛…), của Đại Lý là 稻草人 v.v. — **không ID nào trùng**;
- quét toàn bộ 17 cảnh đang chạy: **0 quái** có dòng `MonsterDropBoxs` với ít nhất một `DropBoxContent` còn vật phẩm;
- 12 cảnh duy nhất có quái rơi đồ (127 贼寇营地 tỉ lệ 23,5 %; 130–138 các sơn môn 5 %; 47, 49) đều là **`type = 1`
  (phó bản)** nên `createScenes()` không bao giờ dựng chúng.

Bảng gốc 0.85 (`/home/ubuntu/configs/MonsterDropBoxs.txt`, 518 dòng) cũng **không** có `900…909`, nên đây không phải
lỗi do đợt thay bảng CY gây ra — cả hai bộ bảng đều thiếu quái dã ngoại cấp thấp.

### 6.3 ĐÃ SỬA 17/09 — thêm 10 dòng `MonsterDropBoxs` cho quái Vô Lượng Sơn

Ba lối ra từng cân nhắc: (1) thêm dòng `MonsterDropBoxs`; (2) đổi `type` 1 → 0 cho một cảnh phó bản; (3) cho
`createScenes()` dựng cả `type = 1`. Chọn **(1)** — nhỏ nhất, chỉ chạm một bảng dữ liệu, đặt hộp rơi đúng chỗ
người chơi mới đi qua.

| | trước | sau | thêm |
| --- | --- | --- | --- |
| `configs/MonsterDropBoxs.txt` | **677** | **687** | **+10** (quái 900…909) |

Bản 0.85 **cũng không** có quái 900…909 nên không có dòng nào để chép nguyên. Luật `clonerow` của
`Tools/server/item_impacts.py` vì thế chép **nguyên một dòng CÓ THẬT trong chính bảng CY** và **chỉ đổi đúng ô
`Data_Index`**; mọi ô khác (`Mvalue`, `怪物掉落类型`, `DID1..DID20`) giữ nguyên byte.

Dòng mẫu: **3640 贼兵喽啰** (cấp 10, quái của 贼寇营地) — `Mvalue = 100`, `DID = 74, 75, 76`:

| hộp | `BoxValue` | p = Mvalue/BoxValue | vật phẩm |
| --- | --- | --- | --- |
| 74 | — | — | rỗng (giữ nguyên vì chép nguyên dòng) |
| 75 | 666 | 0,150 | `30700232` 灵魂碎片·黄 (cấp 1) |
| 76 | 1000 | 0,100 | `20310176` 玉龙髓 / `20310180` 净云水 (cấp 1) |

⇒ **p(rơi ít nhất một món) = 0,235 mỗi mạng**, vật phẩm đều **cấp yêu cầu 1** nên hợp với quái cấp 1–7 của Vô
Lượng Sơn. Công cụ tự kiểm trên bảng sống trước khi ghi: dòng mẫu phải tồn tại, mọi `DID` của nó phải có trong
`DropBoxContent`, ít nhất một hộp phải còn vật phẩm, quái đích phải có trong `MonsterAttrExTable` **và** phải thực
sự xuất hiện trong `<scene>_monster.ini` của một cảnh `active=1 type=0`. Cột `怪物掉落类型` chỉ được `cfghelper`
lưu chứ không nơi nào đọc (`grep drop_type` → 2 chỗ, cả hai là phép gán) **[DK]**, nên chép nguyên là an toàn.

Sao lưu: `backups/item-impacts-20260917T082442Z/`. Áp lúc 15:21, server được người điều phối restart lúc 15:27:39
nên nạp đúng bảng mới.

## 7. Điểm mốc khác đã ghi nhận

1. **Điểm hái lượm là itembox thật.** `gp_caiji:OnCreate` (`GrowPoint` loại 1 đồng khoáng, 101/102 thảo dược, 201 cá)
   gọi `ItemBoxEnterScene`, nên trong cảnh 6 có tới **144** hộp hái lượm (những điểm có `x < 200` **và** `y < 200`;
   `OnCreate` bỏ qua phần còn lại của bản đồ) **[DK]**. Chúng chỉ nhặt được sau khi kỹ năng sinh hoạt chạy xong
   (`ability/generic_gather.lua:78 item_box:set_open_flag(true)`), vì nhánh "không phải hộp rơi" của
   `char_pick_box_item` đòi `get_open_flag()`. Đây là hệ sinh hoạt, không thuộc vòng đồ đạc.
2. **`itembox:can_pick_box` là mã chết và sai.** Nó đọc `self.ownerid` trong khi `set_owner_guid` ghi
   `self.owner_guid`, nên luôn rơi vào nhánh `INVAILD_ID` = ai cũng nhặt được. Hiện **không có nơi nào gọi** nó
   (`char_pick_box_item` không kiểm chủ sở hữu), nên chưa gây hại; ai nối nó vào phải sửa tên trường trước.
3. **`scenecore.lua:2432` gõ nhầm `obj_box:set_open_flag(flase)`** — `flase` là nil. Cùng tác dụng "giả" nên vô hại,
   nhưng là dấu hiệu nhánh đó chưa từng được chạy thật.
4. **Hộp rơi sống 30 giây** (`create_item_box_data`: `recycle_time = create_time + 30`) **[DK]** — bot phải nhặt
   trong khoảng đó; `Step::Pickup` hiện chờ tối đa 8 s, đủ.
5. **Mua gộp vào chồng có sẵn làm hỏng cách bot nhận diện "món vừa mua".** `Inv::BuyBag` coi một ô là "vừa mua" khi ô
   đó mới hoặc `guid.series` đổi; nếu server gộp vào chồng cũ thì `bought` rỗng và `--sell` / `--drop` bị bỏ qua
   (live-6). Muốn bán đúng món vừa mua thì mua món chưa có trong túi.

## 8. Lệnh đo lại

```powershell
Set-Location C:\TLBB\085\CY-Source
$env:CYS_BOT_PWD = (Get-Content .local\test-accounts.txt | Where-Object { $_ -like 'test03=*' }).Substring(7)

# 1. dat nhan vat canh tiem thuoc Lac Duong + mau thap (thuoc bi tu choi khi mau day)
wsl.exe -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-17-item-live/tools/item_char.py `
    place --guid 200004 --scene 0 --x 232 --z 308 --hp 400 `
    --out /mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-17-item-live/char/place-x.json

# 2. mua -> thao/mac -> dung thuoc
Build\bot-item\CysNetBot.exe --mode world --host 127.0.0.1 --port 15733 --game-port 15734 `
    --account test03 --guid 200004 --out Build/Logs/2026-09-17-item-live/live-x --dwell-ms 30000 --walk 0 `
    --goto-scene 0 --npc 230,308 --buy 14,30001001,3 --unequip 0 --equip 0 --use 30001001,1 --bag 1 --record 1

# 3. tra nhan vat ve cho cu
wsl.exe -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-17-item-live/tools/item_char.py `
    restore --guid 200004 `
    --original /mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-17-item-live/char/original-200004.json `
    --out /mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-17-item-live/char/restore-x.json
```

`item_char.py` từ chối mọi GUID ngoài 200004/200005 và từ chối ghi khi còn kết nối trên 15733/15734 — **phải chờ vài
giây sau khi bot thoát**, nếu không lệnh bị bỏ im lặng (đã sập một lần ở live-5).

Kiểm tra dữ liệu (chỉ đọc, không cần server rảnh):

```powershell
wsl.exe -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-17-item-live/tools/item_impact_audit.py
wsl.exe -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-17-item-live/tools/proposal_numbers.py
```

### 9.1 Thuốc máu — live-7

```
1720  inv_state  jiaozi=28878167 bag=[… 4:30001001x3 …]
1720  attrs_start  level=15 hp=400/2250 …
2255  shop       GCShopMerchandiseList shop=14 npc=160 type=8 goods=35
2270  buy_wait   CGShopBuy index=0 count=2 price=100
3081  buy        GCShopBuy result=0 item=30001001 count=2
3143  use_wait   CGUseItem bag=4 item=30001001 hp=400/2250 count=5
3222  heal       GCDetailHealsAndDamages +450 sender=232        <-- TRUOC KHI VA: KHONG CO GOI NAY
4396  use        slot=4 item=30001001 result=0 hp 400->850/2250 count 5->4
5925  inv_state  jiaozi=28877967 bag=[… 4:30001001x4 …]
```

**+450 máu đúng bằng `参数值` của dòng impact 3001 vừa thêm** (`药品，立即恢复生命，1级`, logic 4) và đúng bằng
con số trong mô tả vật phẩm 行血散 **[LIVE]**. `result.json`: `heals_on_me 1`, `healed_hp 450`. Giao tử −200 cho 2
viên. Số lượng chồng 5 → 4 đọc đúng nhờ bản vá `itemStackCount` ở mục 2.3.

### 9.2 Thức ăn — live-8

`30101031` 白蜂糕 gửi **hai** impact: `3301` (vừa thêm) và `35` (vốn đã có). So với live-2 (trước vá):

| | trước vá (live-2) | sau vá (live-8) |
| --- | --- | --- |
| `GCDetailBuff` + `GCCharBuff` | **1 cặp** | **2 cặp** |
| `GCDetailImpactListUpdate` | 28 B | **68 B** |

⇒ impact `3301` nay **vào được**. Dòng của nó: logic 10, tổng 19 000 ms, nhịp 3 000 ms, hiệu ứng con `3061`,
`是否需要引导支持 = 1` và `开始动作时/开始移动时消失 = 1`. Bot không ngồi im nên `GCCharStopAction` đến sau 77 ms và
buff tắt — **đúng luật engine**, không phải lỗi. Muốn thấy máu hồi theo nhịp thì phải để nhân vật đứng yên đủ 3 s.

### 9.3 Rơi đồ và nhặt — live-9

Vô Lượng Sơn (cảnh 6), 8 mạng quái `900…909`, chiêu 0:

```
29530  kill    target 190 hp 0 after 6 skills
29545  box     box=365 owner=200004 monster=190 type=-1 pos=44.5,150.1 mine=1
29592  (wire)  675 GCBoxItemList
30152  pick    item_index=30700232 series=31
30198  (wire)  113 GCPickResult
30859  pickup  done picks_sent=1 picks_ok=1
```

Chuỗi wire đầy đủ **[LIVE]**: 1694 `GCNewItemBox` → 1266 `CGOpenItemBox` → 675 `GCBoxItemList` →
1155 `CGPickBoxItem` → 113 `GCPickResult`. Hộp thuộc về chính mình (`owner_guid` = GUID 200004).
**Xác nhận trong Mongo**: `prop_bag` ô 7 = `30700232` số lượng 1 — món rơi đã nằm trong túi và được lưu DB.

8 mạng ra 1 hộp; kỳ vọng `8 × 0,235 = 1,9`. Một mẫu nhỏ nên không nói được gì về tỉ lệ, chỉ nói được rằng
**đường rơi → nhặt → vào túi đã thông**.

### 9.4 Bảng trước/sau của 161 ID thiếu

| | trước vá | sau vá |
| --- | --- | --- |
| ID impact vật phẩm dùng | 545 | 545 |
| **thiếu trong bảng đang chạy** | **161** | **2** |
| còn thiếu là ID nào | — | `4931`, `340001` |
| vì sao còn thiếu | — | không có ở **cả hai** bảng (0.85 lẫn CY) nên không chép nguyên được; sinh dòng mới = chế số, không làm |

`4931` được `item_4931.lua` dùng, `340001` được `item_340001.lua` dùng; hai vật phẩm đó vẫn sẽ mất đồ mà không có
tác dụng cho tới khi có nguồn dòng thật để chép.
