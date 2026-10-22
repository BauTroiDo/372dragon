# Túi đồ, trang bị, cửa hàng NPC trên giao thức CY — 15/09/2026

Tiếp nối [core-loop_vi.md](core-loop_vi.md) (nhặt đồ, `GCMyBagList`, `GCItemInfo`). Phần này đặc tả và triển khai **túi đồ CY** (cửa sổ `Packet`), **trang bị** (cửa sổ `SelfEquip`, ngoại hình), **vứt / tách / xếp**, **cửa hàng NPC** (thoại NPC → mục cửa hàng → mua / bán / mua lại) trên server riêng `/home/ubuntu/cys-test-20260913` (login 15733 / game 15734). ID gói giữ ID skynet (`Registry/protocol/packets.yaml`, codec `Src/Shared/ProtocolGen`). Mọi sửa trong mã gắn `// CYS-INV`.

Ký hiệu: **[DK]** dữ kiện đọc từ mã server / bảng / mã client; **[SL]** suy luận chưa kiểm; **[LIVE]** đã thấy trên server riêng (bot hoặc Game.exe).

## 1. Tóm tắt wire

| Hành động | Client → server | Server → client | Handler server (chỉ đọc) | Trạng thái |
| --- | --- | --- | --- | --- |
| Hỏi túi | 170 `CGAskMyBagList` {mode u32 = 0, size u8 = 0} | 263 `GCMyBagList` (index, guid, item_index, **count**) | `msgagent.lua CGAskMyBagList` | core-loop, [LIVE] |
| Hỏi kích thước túi | 207 `CGAskMyBagSize` (rỗng) | 143 `GCBagSizeChange` {prop_size u8, material_size u8} | `msgagent.lua:625` → `human:get_bag_size` | [LIVE] prop 20 / material 20 |
| Một ô túi đổi | — | 623 `GCItemInfo` {bagIndex i16, unknow_1 i32, item ItemInfo, askid, bag_type} | nhiều nơi (`package_swap_item`, `shop_sell`, `split_item`, mua) | [LIVE] |
| Danh sách trang bị | 316 `CGAskDetailEquipList` {m_objID u32} | 1272 `GCDetailEquipList` {m_objID, m_mode, m_wPartFlags[12], itemList[84] ItemInfo có mặt theo bit} | `scenecore.lua:1708 ask_detail_equip_list` | [LIVE] |
| Mặc trang bị | 238 `CGUseEquip` {bagIndex u32, equipPoint u8, type u8} | 462 `GCUseEquipResult` (29 B) + 1194 `GCCharEquipment` (phát cho cảnh, gồm mình) | `scenecore.lua:3385 char_use_equip` → `char_use_bag_equip:3163` → `broad_char_equioment:3304` | [LIVE] |
| Tháo trang bị | 88 `CGUnEquip` {equipPoint u8, 3×u8 = 0} | 480 `GCUnEquipResult` (15 B) + 1194 | `scenecore.lua:3500 char_un_equip` | [LIVE] |
| Dùng vật phẩm | 473 `CGUseItem` {bagIndex u8, item_index u32, pet_guid, target_obj_id, target_pos, target_dir, PetGUID, target_bag_index} | 117 `GCUseItemResult` {result i32} | `scenecore.lua:2979 char_use_item` | dịch + port, chưa live |
| Vứt | 520 `CGDiscardItem` {bag_index u8, opt u8 = 0 FromBag} | 844 `GCDiscardItemResult` {result u8 (0 ok), bag_index, opt, item_index i32} | `scenecore.lua:5725 char_discard_item` | [LIVE] |
| Tách chồng | 96 `CGSplitItem` {container u32 = 1 BAG_CON, position u32, num u32} | 1312 `GCSplitItemResult` {con_index i16, is_null u32, container u32, result u8 (2 ok), item ItemInfo} + 623 ô gốc | `human.lua:4399 split_item` | [LIVE] |
| Xếp (đổi ô) | 877 `CGPackage_SwapItem` {index_from u8, index_to u8, count u8} | 34 `GCPackage_SwapItem` {result u8 (1 ok), from, to, count} + 2× 623 | `scenecore.lua:1854 package_swap_item` | [LIVE] |
| Thoại NPC | 1095 `CGCharDefaultEvent` {m_objID u32 = NPC, targetID u32} | 397 `GCScriptCommand` m_nCmdID 0 (event list) | `scenecore.lua:5496` → `obj:default_event` → script `UpdateEventList` | [LIVE] |
| Chọn mục NPC | 107 `CGEventRequest` {m_objID i32 = **script id**, index i32, arg i32 = **NPC obj**, unknow u32} | tuỳ script; mục cửa hàng → 797 + 321 | `scenecore.lua:5512 char_event_request` → `OnEventRequest` → `script_base:DispatchShopItem:278` | [LIVE] |
| Danh sách hàng | — | 797 `GCShopMerchandiseList` + 321 `GCShopSoldList` | `script_base.lua:300`, `human:send_sold_out_list:4687` | [LIVE] |
| Mua | 427 `CGShopBuy` {index u8 (0-based), series_num u8, unique_id u32, item_guid 8 B, buy_num u32, 4×u32} | 37 `GCShopBuy` {result u8, item_index, count, …} + 623 ô nhận | `scenecore.lua:5555 char_shop_buy` → `human:do_shop:1614` (index ≥ 200 → `buy_back`) | [LIVE] |
| Bán | 563 `CGShopSell` {bag_index u8, unknow_2 u32, unknow_3 u8} | 623 (ô trống) + 321 + 305 `GCShopSell` {result i8 (0 ok)} | `human.lua:1551 shop_sell` | [LIVE] |

Kết quả (define.lua / packet_domains): `UseEquipResultCode` 1 thành công, 2 cấp, 3 loại, 4 giám định, 5 môn phái; `GCUnEquipResult.result` 1 thành công, 3 kho thời trang đầy; `DISCARDITEM_RESULT` 0/1; `GCSplitItemResult.RESULT` 0 sai, 1 hết chỗ, 2 thành công; `GCShopBuy.BUY_RESULT` 0 OK, 1 mua lại OK, 2 **không đủ tiền** (mọi loại tiền), 4 túi đầy; `GCShopSell.SELL_RESULT` 0/1 **[DK]**.

### 2.1 Chỉ số túi, điểm trang bị

- `human_bag_container.lua bag_start = {prop = 0, material = 100, task = 200}`; kích thước từ `human:get_bag_size` (prop, material theo DB; task cố định 20). `get_empty_item_index(bag)` quét `bag_start[bag] .. +size-1` **[DK]**. CYTest00: prop 20, material 20 **[LIVE]**.
- Cửa sổ `Packet.lua` CY đánh số theo đúng chỉ số server: trang 0 `EnumItem("base", i)`, `DragAcceptName = "P"..(offset + i)` với offset trang vật liệu = `DataPool:GetBaseBag_MaxNum()` → phải là **100** để khớp `bag_start.material` **[DK]** (`Packet_UpdateDragAcceptName`).
- `define.HUMAN_EQUIP`: 0 vũ khí, 1 mũ, 2 áo, 3 găng (CY) / hộ uyển (0.85 CUFF), 4 giày, 5 thắt lưng, 6 nhẫn 1, 7 dây chuyền, 8 cưỡi, 9 hành nang, 10 cách rương, 11 nhẫn 2, 12/13 hộ phù, 14 hộ uyển, 15 hộ vai, 16 thời trang, 17 ám khí, 18 võ hồn, 37 thần binh, 38 ALL **[DK]**. `char_use_bag_equip` đòi `equipPoint == item:get_item_point()` (trừ nhẫn 6/11, hộ phù 12/13: server tự chọn ô) và `level ≥ EquipBase.level - (10 nếu buff 534)` **[DK]**.
- `GCCharEquipment.flag`: 0x1 vũ khí, 0x2 mũ, 0x4 áo, 0x8 găng, 0x10 giày, 0x10000 thời trang, 0x40000 võ hồn; mỗi phần = item id + gem id + visual i16 **[DK]**; server phát cả cảnh (`broadcast(obj, ret, true)`) **[LIVE]** (flag `0x8005001f` lúc vào cảnh).

### 2.2 ItemInfo và EquipStream

- `ItemInfo` (bos `item_types.lua:184`, xem core-loop 2.3): đầu 18 B chung, khối theo lớp `floor(item_index/1e7)`. Ô trống = `item_cls.new():copy_raw_data()` với `unknow_1 = 1` (đổi ô, bán) hoặc `-1` (hỏi) **[DK]** → client coi `item_index ≤ 0 || unknow_1 ≠ 0` là ô trống.
- `EquipStream` (321 `GCShopSoldList`, 420 `GCExchangeSynchII`, 1763 `GCStallOpen`) = byte thô `item:get_stream()` (`lualib/item.lua:2464`): ItemGUID 8 + item_index 4 + rule 1 + status 1 + **174 B** cho mọi lớp (equip_type 0–4, vật liệu 74+1+91+8, ngọc 122+1+43+8) → **188 B cố định** (chỉ `item_index = -1` ghi 182, không bao giờ nằm trong danh sách mua lại) **[DK]**. Codec sinh cũ báo “không suy ra được độ dài” → bot live-2 dừng `strict packet decode failed` khi danh sách mua lại có 1 món; đã thêm luật `('struct:EquipStream', 20): len_expr 188` vào `Tools/protocol/codegen_cpp_rules.py` và sinh lại **[LIVE]** (live-4..7 decode 0).

### 2.3 Cửa hàng NPC

- Mở: `CGCharDefaultEvent` → script NPC `UpdateEventList` → 397 m_nCmdID 0: `target_id`, `size`, `event[i]` {flag: 0 section / 1 option / 2 text; option: `index`, `type` (= biểu tượng `AddNumText`, **7 = cửa hàng**), `script_id`, `split`, `str_2`} **[DK]** (`mission.lua:190`). Chọn mục → `CGEventRequest{m_objID = script_id, index, arg = NPC}` → `OnEventRequest(index 0)` → `DispatchShopItem(shop_id)` **[DK]**.
- 797 `GCShopMerchandiseList`: `m_objID` NPC, `shop_type` = cột 7 ShopTable “货币单位” (1 vàng, 2 thiện ác, 3 sư đức, 4 bang cống, 5 nguyên bảo, 6 điểm tặng, 7 sư môn, **8 giao tử**), `sold_type` 1, `unique_id` (=`shop_mgr:get_unique_id()`), `is_yuanbao_shop`, `can_multiple_buy`, danh sách {id, pnum, yuanbao_price, c_pmax, pmax, discount %, price} **[DK]**.
- `do_shop`: phiên bản cấu hình cửa hàng phải khớp, giới hạn mua theo `LIMIT_SHOP*`, `check_cost_money_by_shop_type`: 5 nguyên bảo, 9 nguyên bảo khoá, 21 vinh dự, **8 = `check_money_with_priority` (giao tử trước, rồi vàng)**, còn lại **vàng** → không đủ → `BUY_RMB_FAIL (2)` **[DK]**. Tạo `buy_num × pnum` món (chồng được thì gộp) **[LIVE]**.
- `shop_sell` (không kiểm cửa hàng đang mở): giá = `sell_price × lay_count`; cấu hình phụ `sell_money_type == 0` → **vàng**, còn lại → **giao tử** **[DK]**; món bán vào kho mua lại (`sold_out_container`), gửi 623 + 321 + 305 **[LIVE]**.
- Đại Lý (`dali_new_320_monster.ini`, cảnh 2): 蒲良 `odali_puliang` (219,123) script 2023 shop 1 **vàng** (vũ khí tân thủ 100); 云飘飘 `odali_yunpiaopiao` (271,133) script 2051 shop **27 giao tử** (18 món, 30602001 giá 100); 卢三七 (105,123) shop 14 “tạm đóng cửa”; 杜子腾 (108,155) mục cửa hàng bị chú thích **[DK][LIVE]**. CYTest00 15/09: vàng 0, giao tử 28.880.100 → dùng shop 27.

## 3. Lua CY liên quan và host

Mã nguồn Lua CY: `Assets/CanonicalCY/Data/InterfaceFolder/{Packet,SelfEquip,Shop,SuperTooltip,Quest}` (UTF-8 sau cy-gui).

| Cửa sổ | Mở bằng | Sự kiện chính | Host đã cài / thay (CysHost_Package) |
| --- | --- | --- | --- |
| `Packet` (túi) | `ToggleContainer()` → `TOGLE_CONTAINER`; tự mở khi `OPEN_BOOTH`, `OPEN_EXCHANGE_FRAME`… | `PACKAGE_ITEM_CHANGED_EX`, `MONEY_CHANGE_EX`, `RESET_EXT_BAG` | `DataPool:Get{Base,Mat,Task}Bag_{Num,BaseNum,RealMaxNum,MaxNum}` (catalog stub trả 0 → mọi ô bị khoá), `DataPool:AskMyBagList` (170 + 207, chặn 3 s), `Player:GetLevelMoneyLimit` (false), `TLCJ:IsInTLCJScene` (0), `GameProduceLogin:IsWeGameClient` (0), `PlayerPackage:GetBagPosByItemIndex` (-1). Có sẵn 0.85: `PlayerPackage:EnumItem` (theo `PosIndex` = chỉ số server), `PackUpPacket`, `SplitItem`. |
| `SelfEquip` | `OpenEquip(1)` → `OPEN_EQUIP` | `REFRESH_EQUIP`, `UNIT_*` | `DataPool:Lua_IsMissionHaveDone`, `Lua_CheckOpenTalent`, `Exterior:LuaFnIsHave*ShowTip`, `OrnamentsScript:IsHaveOrnamentsShowTip` (0). Còn ~40 stub CY (Pneuma, KaJi, Infant, WGAch…) giữ nguyên. |
| `Shop` | `OPEN_BOOTH` (từ 797) | `UPDATE_BOOTH`, `CLOSE_BOOTH` | `NpcShop:GetBuyDirectly/GetIsShopReorder` (0), `CloseConfirm/SetBuyDirectly` (không làm gì). Có sẵn 0.85: `NpcShop:EnumItemPrice/EnumItemName/…`, mua qua `CActionItem_Item::DoAction` (IO_BOOTH → `Booth_BuyItem` → 427). |
| `SuperTooltip` | `SHOW_SUPERTOOLTIP` (`CActionItem::NotifyTooltipsShow`) | `UPDATE_SUPERTOOLTIP` | 47 hàm `SuperTooltips:*` CY (xem 3.1). Có sẵn 0.85: `GetTitle`, `IsPresent`, `GetTypeDesc`, `SendAskItemInfoMsg`. |
| `Quest` (thoại NPC) | `QUEST_EVENTLIST` (từ 397 cmd 0) | — | chọn mục → `CUIDataPool::SendSelectEvent(-, script, index)` → 107. Phần thoại/nhiệm vụ còn lại thuộc agent npc-quest. |

### 3.1 Tooltip CY (tiếng Việt)

`SuperTooltip_Update` gọi ~45 hàm và so sánh số (`nYuanbaotrade == 0`, `nGemHoleCounts > 0`, `t300AuctionSubType > 0`…) → stub trả nil làm Lua lỗi (`gui-live-2`: `CYS Lua failure env=SuperTooltip_Env`). Cài đặt:

- `GetIconName` = icon của action item (`StaticImage:SetImage` tra IconManager); `GetDesc1` “Cấp yêu cầu: N”; `GetDesc2` “Độ bền: a/b” (trang bị) hoặc “Số lượng: n”; `GetDesc3` “Giá bán: X”; `GetDesc4` = loại (`GetTypeDesc`); `GetPropertys` = chỉ số cơ bản EquipBase cột 24–29 (“Công vật lý +N”, “Phòng vật lý +N”, “Chính xác”, “Né tránh”), nil nếu không có; `GetExplain` = mô tả bảng; `GetAuthorInfo` nil.
- Trung tính theo nghĩa CY: `GetDesc5` "0" (không khoá), `GetYuanbaoTradeFlag` 1 (không thêm dòng giao dịch NB), `GetMoney1/2` nil ngoài cửa hàng, cờ quỷ thị / chí tôn / biệt thự / điêu văn / ngọc = 0 hoặc "".
- Nhãn “Cấp yêu cầu / Độ bền / Giá bán / Công vật lý…” viết tiếng Việt trong mã; chưa dò khoá StrDictionary CY tương ứng (tooltip CY gốc dựng chữ trong Game.exe CY) **[SL]**. Tên và mô tả vật phẩm lấy từ bảng CY (`CommonItem.txt`, `EquipBase.txt`) — phần nào chưa dịch vẫn là chữ Trung (thống kê của cy-gui).

## 4. Triển khai

- **NetCore** `WorldModel` (bot + test): trang bị theo điểm, `Shop` (hàng/giá/loại tiền/unique), `ScriptEvent` của menu NPC, `Result` của mặc/tháo/mua/bán/vứt/tách/xếp, tiền vàng (`GCDetailAttrib flags[1]&0x10`) và **giao tử** (`flags[14]&0x04`); hàm tạo 316/678/238/88/520/877/96/1095/107/427/563.
- **Bot** `CysNetBot --mode world`: `--npc X,Z` (đi tới, thoại, chọn mục type 7), `--buy SHOP,ITEM[,N]` (tiền không đủ + `--sell` → bán một chồng không phải trang bị trước), `--unequip SLOT`, `--equip SLOT` (món vừa mua nếu là trang bị, không thì trang bị đầu tiên trong túi), `--sell 1`, `--drop 1` (một chồng mà vừa bán vừa vứt → `CGSplitItem` 1 đơn vị trước), `--swap 1` (đổi ô rồi đổi lại), `--goto-scene ID`. Kết quả: `core-loop.tsv`, khối `inventory` trong `result.json`. Runner `Tests/net/run_inventory_live.ps1` (snapshot trước/sau chỉ đọc).
- **Game.exe**:
  - `Network/CysInventoryNet.{h,cpp}`: dịch 0.85 → CY (`CGUseEquip` tự điền `equipPoint` từ `CObject_Item_Equip::GetItemType`, `CGUnEquip`, `CGDiscardItem`, `CGSplitItem`, `CGPackage_SwapItem`, `CGShopBuy`, `CGShopSell`, `CGCharDefaultEvent`, `CGEventRequest`, `CGUseItem` (điền `item_index`), `CGAskDetailEquipList`); port 462/480/1272/1194/797/321/37/305/844/34/1312/117/397(cmd 0)/143. Hook một dòng ở `CysModernGame::Translate` (default) và `CysModernHandlers::{IsWorldPacket,Dispatch}` (default).
  - `DataPool`: túi client **220 ô theo chỉ số server** (`CYS_CLIENT_BAG_SLOTS`, thay `MAX_BAG_SIZE` 60 chỉ trong DataPool/ActionSystem; struct wire/DB giữ nguyên); trang bị **39 điểm** (`CYS_CLIENT_EQUIP_SLOTS`), sửa `UserEquip_GetItem` (`&&` → `||`), cho nhẫn 6/11 và hộ phù 12/13 dùng chung điểm EquipBase.
  - `Object/Item/Obj_Item.cpp NewItem`: B/CY chỉ nạp `EquipBase.txt` (`GMDataBase.cpp`: White/Green/Blue EquipBase là bảng cũ B không nạp) → mọi trang bị CY `NewItem` trả NULL (`gui-live-2`: “item 10106000 unknown to the item tables”, túi/SelfEquip trống). Nay dựng định nghĩa trắng từ dòng EquipBase (tên, icon, điểm, visual, cấp, giá, độ bền; khối thuộc tính = -1).
  - `LuaApiGen/CysHost_Package.{h,cpp}` (keo Lua) + dịch vụ trong `CysInventoryNet.cpp`; đăng ký lúc `CysModernGame::Start`.
  - `Network/CysInventoryDriver.{h,cpp}`: kịch bản GUI live `CYS_INV_LIVE=1` sau kịch bản camera/đi bộ của `CysGlLoginSmoke` mode World: mở túi → tooltip → mở SelfEquip → mặc / tháo / mặc lại (DoAction trên action item) → thoại NPC (`Player_Speak`) → chọn mục cửa hàng → mua một món (DoAction trên hàng) → PNG `cys-live-inv-*`. `CYS_INV_NPC=X,Z`, `CYS_INV_BUY_ITEM`.

## 5. Kiểm chứng

- Live bot (bằng chứng `Build/Logs/2026-09-14-inventory-equip/live-*`):
  - live-1: vào cảnh 2 (nhân vật đã ở Đại Lý), thoại 蒲良 → menu `[2023/0/t7]` → shop 1 (23 món) → mua 3 vũ khí: `BUY_RMB_FAIL` (vàng 0); mặc 10106000 từ túi → `USEEQUIP_SUCCESS`, ngoại hình phát 1194.
  - live-2: `strict packet decode failed` ở 321 có 1 món mua lại → sửa codec EquipStream 188 B.
  - live-5: 杜子腾 không có mục cửa hàng; tháo + mặc vũ khí OK; giao tử 28.880.100.
  - **live-7 (đủ DoD 2)**: shop 27 → mua 3 × 30602001 (`BUY_OK`, gộp 1 ô) → tháo vũ khí (ô túi 3) → mặc lại → tách 1 (ô mới 3) → bán ô 1 (`SELL_OK`) → vứt ô 3 (`DISCARDITEM_SUCCESS`) → đổi ô 0↔1 và đổi lại; `decode_failures 0`, `quit_complete flag 0`; giao tử 28.879.809 → 28.879.515; fixture `world_core_g1.bin`. Review snapshot: dịch vụ / cổng / tài khoản / log lỗi không đổi; `position_unchanged` và `bot_result` (kỳ vọng `--walk 1` cũ) FAIL là cố ý.
- **GUI live `gui-live-8`** (stage `Build/world-gui/stage-<sha>-inv`, `CYS_INV_LIVE=1`, runner 20/20 PASS, 144 s): cửa sổ túi CY “Hành trang” mở (`Packet shown=1`, icon vật phẩm), tooltip CY hiện (“Cấp yêu cầu / Số lượng / Giá bán”), SelfEquip mở, tháo vũ khí (`GCUnEquipResult 1`, `GCCharEquipment weapon=-1`) rồi mặc lại (`GCUseEquipResult 1`, weapon 10106000 visual 836), thoại 云飘飘 → menu Quest → mục cửa hàng → cửa sổ Shop CY 18 món → mua 30602001 (`GCShopBuy 0`). PNG `cys-live-*-inv-{bag-open,tooltip,equip-open,unequipped,equipped,npc-menu,shop-open,shop-bought}.png`.
- Còn thiếu ở GUI: tên vật phẩm trong tooltip/cửa hàng là ô vuông (tên bảng CY GBK chưa dịch/chuyển — lớp dữ liệu cy-gui); ô tiền túi hiện −1 (`Player:GetData("MONEY")`); SelfEquip che nhân vật, khung xem mô hình trong SelfEquip trống → đổi ngoại hình chỉ có bằng chứng log (1194 → `Set_Equip`), chưa có PNG so sánh; nhặt hộp rơi bằng click chỉ có ở replay `-Core` (core-loop), live chưa có quái rơi đồ.
- Test: `run_protocol_tests.py` G1 GATE PASSED (`protocol-run-1.txt`), `run_netcore_tests.py` PASS (`netcore-run-1`), `run_world_session_tests.py` PASS 19 loopback + bot (`world-run-1`).

## 6. Khác biệt CY / 0.85 và bẫy

1. 0.85 `CGUseEquip` chỉ có ô túi; CY cần `equipPoint` và `type` (2 = từ kho thời trang).
2. 0.85 `CGEventRequest` = {NPC, script, exIndex}; CY đảo: `m_objID` = script, `arg` = NPC.
3. Ô túi CY chia trang theo chỉ số 0/100/200; 0.85 gộp 60 ô liên tục.
4. Bán đồ không đưa vàng khi `sell_money_type ≠ 0` (đa số vật liệu → giao tử); shop vàng không mua được bằng giao tử, shop loại 8 dùng giao tử trước.
5. `GCItemInfo` ô trống có `item_index` -1 chứ không phải 0.
6. `GCShopSoldList` bắt buộc phải giải được — server gửi sau **mỗi** lần bán và khi mở cửa hàng.
7. Tài khoản test00 dùng chung giữa các agent: đăng nhập nhân vật bị từ chối (`login_flag 8` / `charlogin refused`) khi agent khác đang giữ phiên; nhân vật có thể bị dời cảnh (73 ↔ 2) giữa hai lượt.
