# costumes-all — đưa TẤT CẢ thời trang (时装) của CY vào thế mua được trên server riêng

Ngày đo: **17–18/09/2026**. Server riêng `R = /home/ubuntu/cys-test-20260913` (WSL `TLBB`, cổng 15733/15734).
Công cụ: `Tools/server/costume_data.py` (`survey | plan | apply | verify`). Bằng chứng:
`Build/Logs/2026-09-17-costumes-all/` (`measure-before/`, `measure-after/`, `plan/`, `bot-*/`, `gui-*/`, `scripts/`).
Công thức khôi phục (git theo dõi): `Tools/reapply/costumes/90-costumes.ps1` + mục trong `Tools/reapply/README_vi.md`.

---

## 0. Trả lời thẳng câu hỏi "thêm tất cả trang phục có thể thêm"

**"Có thể thêm" = 578 Visual.** CY có 4.113 item thời trang → 583 Visual (ngoại hình, kể cả màu nhuộm) →
439 bộ mesh; **578/583 Visual có chuỗi ngoại hình đủ** trên đĩa cho cả nam lẫn nữ; 5 Visual hỏng ngay trong dữ
liệu CY (mục 3). Trước hôm nay chỉ **52** trong số đó mua được trong game; sau khi làm là **578/578**.

| | TRƯỚC | SAU |
|---|---|---|
| item thời trang phía server (`EquipPoint = 16`) | 4 113 / 4 113 | 4 113 / 4 113 (không đổi — bảng đã là bảng CY) |
| Visual đủ chuỗi ngoại hình (mesh + skeleton + material + texture, nam & nữ) | 578 / 583 | 578 / 583 (không đổi — việc client) |
| **Visual mua được trong game** | **52 / 578** | **578 / 578** |
| bộ mesh (IVC) mua được | 52 / 436 | **436 / 436** |
| item thời trang nhìn thấy trong một shop mở được | 102 | **675** |
| ô hàng mỗi shop mà server đưa ra (header `ShopTable`) | 50 | **200** (client hiện tối đa 96) |
| shop 120 久久时装店 — hàng server gửi | 50 | **82** (đo live, gói 2 352 B) |
| shop 247 时尚时装店 — hàng server gửi | 50 | **113** (đo live, gói 3 220 B; client hiện 96) |

Đo bằng `costume_data.py survey` trước/sau (`measure-before/survey.json`, `measure-after/survey.json`) và bằng
bot thật trên server đang chạy (mục 6).

**Điều kiện (c) "mặc lên THẤY đúng"**: chỗ đứt nằm ở **client** chứ không phải dữ liệu — bản dựng CY-Source chỉ áp
5 ô trang bị và chưa từng nạp `EquipDress.txt`. Điều phối viên cấp quyền sửa, nên nhánh này **đã vá client**
(mục 8): nạp `EquipDress.txt` thành DBC 309, thêm ô `HEQUIP_DRESS = 16` vào dữ liệu nhân vật, và vẽ bộ đồ đè lên
thân/tay/chân.

---

## 1. Định nghĩa và bốn con số (đo, không đoán)

**Thời trang** = dòng `EquipBase` có `EquipPoint(装备点) == 16`. `Type(类别)` 24/25/26/27/28 chỉ là **dải ID**
(10124xxx…10128xxx), không phải loại — cả 4.113 dòng đều là 时装, cùng `class 1`, `Quality 1`, `script 0`.
Bộ nhớ dự án nói "Type 25 = thời trang" là đúng với bản 085/GL, còn CY có 226 dòng Type 25 trong 4.113.

Chuỗi ngoại hình (đọc từ bảng, kiểm từng tệp trên đĩa):

```
EquipBase.Visual (cột 6)
  └─ EquipDress[Visual]        DBC 7 cột: index, -1, IVC, -1, -1, ô_màu(1..9), nhóm      (1 050 dòng, tới 1 062)
       └─ ItemVisualChar[IVC]  DBC 23 cột: 1 mesh nữ, 2 material nữ (;), 3..10 màu nhuộm nữ 2..9,
                                            12 mesh nam, 13 material nam, 14..21 màu nhuộm nam      (804 dòng, tới 808)
            └─ .mesh (+ .skeleton nó khai) trong Model*Folder; material trong MaterialFolder/all.material
               (85 686 khối); mọi .dds khối đó gọi trong Material*Folder
```

Bảng thay material **theo vị trí submesh**; submesh dư dùng tên nội trong mesh — kiểm cả hai. Tên tệp trên đĩa là
byte GBK đọc kiểu cp1252 (bẫy đã biết), công cụ tra bằng ba cách giải mã.

| con số | giá trị |
|---|---|
| item thời trang CY | **4 113** |
| Visual khác nhau | **583** (581 có trong EquipDress) |
| IVC khác nhau | **439** |
| Visual đủ chuỗi | **578** — 4 063 item, 436 IVC |
| thời hạn của 4 113 item | vĩnh viễn 720 · 30 ngày 555 · 7 ngày 553 · 3 ngày 474 · 90 ngày 471 · 1 ngày 445 · 15 ngày 411 · 180 ngày 360 · còn lại 124 |

`ItemVisualChar_iv.txt` (652 dòng, mesh `_iv`) **không được client CY-Source đọc** (`grep ItemVisualChar_iv Src/`
= 0) — không tính vào chuỗi.

---

## 2. Vì sao trước đây không mua được — ba nút thắt, đều đọc trong mã

1. **Header `configs/ShopTable.txt` chỉ đặt tên 50 ô.** `cfghelper:read_shop_table` (`lualib/cfghelper.lua:2252`)
   lặp `for i = 1, Num` và tra `conf["PID(商品编号i)"]` / `conf["商品i价格"]`; cột 51..200 tên rỗng ⇒ mọi shop
   dừng ở 50. Shop 120 có 82 ô, 247 có 113 ô ⇒ 32 + 63 ô vô hình. Quét 383 shop: **0 shop có lỗ trống** trước ô
   cuối ⇒ đặt tên 51..200 là an toàn (không tạo `merchadise_list` thủng làm `#` sai).
2. **Client giữ tối đa `MAX_BOOTH_NUMBER = 96` món/shop** (`Src/Shared/Common/GameDefine.h:292`,
   `CysInventoryNet.cpp:226` cắt ở 96) ⇒ chia danh mục sao cho **mỗi shop ≤ 96 ô**. Không nới hằng đó: nó đổi
   kích thước gói và mảng UI, mà 578 bộ chia 7 shop thì đã đủ.
3. **Thương thành chỉ có hai shop thời trang** (`yuanbaoshop.lua shoplist[5] = {120, 247, 181, 145, 182, 134,
   419, 420}` ↔ client `YuanbaoShop.lua SHOP_LIST_A[5]` 8 mục: 久久时装店, 时尚时装店, 如意变身斋, 天扬发艺馆,
   兰雨美容坊, 坐骑商城, 天宫骑术阁, 庄园装饰馆). 419/420/421 **không có trên server** (mục 7/8 tab Hình
   tượng đang rỗng; để dành cho `ride-finish`). 2 × 96 = 192 < 578 ⇒ cần đường khác.

Kết quả đo trước khi làm: 253 item thời trang nằm trong shop server bất kỳ, 189 ở ô ≤ 50, **102 trong shop
Thương thành mở được → 52 Visual**.

---

## 3. Năm Visual "không thể thêm" — hỏng trong chính dữ liệu CY

| Visual | IVC | vì sao | item |
|---|---|---|---|
| 905, 907 | — | `EquipDress` không có dòng | 10127743 / 10127823 "Trang phục Thử Nghiệm" |
| 716 | 638 | nam: material `M_cloth_2022yangzongbao半透` không có trong `all.material` (chỉ có bản `zj01..07半透`) | 10126774–… Phá Thiên Môn |
| 1007 | 777 | nam: `M_cloth_2025帝俊特效片` không có | 10128423–… Tinh Nguyệt Vật Ngữ |
| 1008 | 778 | nam: `M_cloth_2025帝俊01特效片` không có | 10128439–… |

Nữ của 716/1007/1008 đủ. Không đúc material giả — để nguyên, không đưa vào danh mục.

---

## 4. Đã làm gì trên `R` (chỉ THÊM, không sửa dòng CY nào)

| # | đối tượng | trước | sau |
|---|---|---|---|
| 1 | `configs/ShopTable.txt` dòng tiêu đề 2 | 50 ô có tên | **200 ô** có tên (`PID(商品编号N)`, `PNUM(每组多少个)`, `PMAX(有限商品的数量上限)`, `商品N价格`, `商品折扣`, `商品颜色`) |
| 2 | `configs/ShopTable.txt` dòng | 383 shop | **390** — thêm 431..437, chép 27 cột đầu của shop 120 (tiền tệ 5 = nguyên bảo), `Num` = số ô, ô liên tiếp, `PNUM 1 / PMAX -1 / 折扣 100 / 颜色 #c00ff01` y hệt shop 120 |
| 3 | `Game_2/Scene/dali_new_320_monster.ini` | 216 | `[monster216]` guid 900300001 type 29 `万衣` / `时装店` (257,121) dir 27 script 990011; `monstercount` 217 |
| 4 | `Game_2/Scene/luoyang_new_monster.ini` | 258 | `[monster258]` guid 900300002 (339,272) — cạnh NPC CY `伊桂 时装之家` (340.9,268.8); `monstercount` 259 |
| 5 | `Game_2/Scene/suzhou_new_monster.ini` | 179 | `[monster179]` guid 900300003 (322,188) — cạnh NPC CY `施妆 时装店` (319.0,187.6); `monstercount` 180 |
| 6 | `Game_2/Script/scripts/costume_shop.lua` | không có | script 990011: `OnDefaultEvent` = `AddText` + 7 `AddNumText(text, 7, i)`; `OnEventRequest(selfId, targetId, arg, index)` → `DispatchShopItem(selfId, targetId, 430 + index)` |
| 7 | `Game_2/Script/scripts/scripts.lua` | — | thêm `[990011] = "scripts.costume_shop",` trước `}` cuối |
| 8 | `configs/EquipExtraAttr.txt` | 8 545 | **không đổi** (mục 5 — người dùng đã chốt: giữ đời cũ) |
| 9 | `GameServer/lualib/wire_names_vi.lua` | 6 010 mục | **6 011** — thêm `["万衣"] = "Vạn Y"` (thẻ `-- CYS-DRESS`) |

Vị trí NPC: ba ứng viên mỗi thành, `plan` chọn điểm đầu tiên **đi được và cùng vùng navmesh** với mốc neo
(`cs3a_scene.NavMesh.locate`, `.path` của server). Model NPC type 29 = `MonsterAttrExTable` 29 (玛拉) — chính
model mà CY dùng cho thư ký 时装店 施妆 ở Tô Châu. **Tên/chức danh là chữ Hán trong `.ini` (GBK) và được dịch TẠI WIRE** — cơ chế sẵn có của dự án:
`wire_charset.fromutf8` tra `GameServer/lualib/wire_names_vi.lua` (6.010 mục) cho mọi chuỗi server→client. Công cụ
thêm `["万衣"] = "Vạn Y"` (thẻ `-- CYS-DRESS`); `时装店` đã có sẵn = "Cửa hàng Thời Trang". Ghi ASCII không dấu
vào `.ini` là sai cơ chế — đợt đầu tôi làm vậy và đã sửa lại. Chữ trong hộp thoại nằm trong Lua (UTF-8) nên có dấu.

**Danh mục (578 item, `plan/catalog.tsv`)**: mỗi Visual đủ chuỗi lấy đúng **một** item — ưu tiên **vĩnh viễn**
(450 Visual có), không thì thời hạn dài nhất (128 Visual chỉ có bản có hạn: 1 ngày 21, 3 ngày 17, 7 ngày 32,
15 ngày 21, 30 ngày 27, 90 ngày 7, 180 ngày 3). Giá: **giá CY của chính item đó** nếu nó có trong ShopTable CY
(120 item), không thì **5 120 NB** cho vĩnh viễn (109/185 bộ vĩnh viễn của CY bán 5 120) hoặc giá theo thời hạn
đo từ CY (7 ngày 380, 30 ngày 720, 90 ngày 980, 180 ngày 1 934; các mốc CY không bán thì nội suy 100/200/500).
Sắp theo Visual tăng dần (≈ theo năm), chia 7 shop 83/83/83/83/83/83/80 ô; nhãn menu "Tập k/7: <tên bộ đầu>".

Sao lưu: **`R/backups/costumes-20260917T170712Z/`** (ShopTable, EquipExtraAttr, scripts.lua, ba `*_monster.ini`).
Hoàn tác: chép ngược, xoá `Game_2/Script/scripts/costume_shop.lua`, restart.

---

## 5. `EquipExtraAttr` — đo rồi cố ý KHÔNG nhập

Server có dòng cho **2 139/4 113** item thời trang; 1 974 thiếu (thiếu = vĩnh viễn, `human_bag_container.lua:44`).
Định nhập 1 973 dòng còn thiếu theo CY, nhưng phép đo ánh xạ cột (2 138 item có ở cả hai bên) cho thấy **bảng
server là đời khác**: `有效期(小时)` khớp CY chỉ **579/2 138** (10127056 server `-1`, CY `360`; 10126320 server
`-1`, CY `24`), `卖店是否获得交子` 1 909/2 138, `是否装备时计算有效期` 2 000/2 138; chỉ `元宝交易类型` khớp
100 %. Nhập thêm dòng "theo CY" vào một bảng không phải CY là trộn hai nguồn ⇒ `plan` tự từ chối khi ánh xạ
không 100 % (ghi vào `notes`), `verify` chỉ báo số liệu. Hệ quả cho người chơi: mọi item thiếu dòng là vĩnh
viễn — có lợi cho mục tiêu "mặc được", lệch CY về thời hạn. Quyết định nhập lại toàn bộ EEA theo CY (thay cả
2 139 dòng cũ) là việc riêng, cần người dùng chốt (handoff mục 6).

---

## 6. Bằng chứng chạy thật (server đã restart 00:09:11 ngày 18/09 để nạp bảng)

| lượt | tài khoản | việc | kết quả |
|---|---|---|---|
| `bot-1-test01` | test01 / 200002 | đi tới (257,121) Đại Lý, nói với NPC, chọn mục type 7 đầu, mua `10124000` ở shop 431, mặc điểm 16 | `script_menus 1`, `shop 431 goods 83`, `buys_ok 1`, `equip_ok 1`, `end equips=[0:10106000 16:10124000]`; Mongo: `yuanbao 1 000 000 000 → 999 999 900` (giá 100 NB), `equip_list['17'] = 10124000` |
| `bot-4-mall120-test01` | test01 | `CGExecuteScript 888902:OpenYuanbaoShop(-1,5,1)` (Thương thành → Hình tượng → 久久时装店) rồi mua `10127651` | `shop 120 goods 82` (trước 50), `buys_ok 1`; gói `GCShopMerchandiseList` 2 352 B = 56 + 82 × 28 |
| `bot-5-mall247-test02` | test02 / 200003 | mở 时尚时装店 (5,2) | `shop 247 goods 113`; gói 3 220 B = 56 + 113 × 28 |
| `bot-2` | test01 | (lượt lỗi cách dùng: vừa `--exec` vừa `--npc`) | vẫn cho hai gói: 2 352 B (shop 120) và 2 380 B (shop 431, 83 món) |

Bot `Build/bot-item/CysNetBot.exe`; runner `scripts/bot_buy.ps1` (mật khẩu chỉ vào env tiến trình con). Bot
kiểm tiền bằng **vàng** trước khi mua (`main.cpp:1274`), nên hai nhân vật test được cấp `attrib.money = 500000`
(Mongo, lúc offline) — server trừ **nguyên bảo** thật (`do_shop → cost_money_by_shop_type(5)`), vàng không đổi.

**Sau restart lần 2 của điều phối viên (03:51:28, nạp lại mọi bảng):**

| lượt | tài khoản | kết quả |
|---|---|---|
| `bot-7-npc-after-restart2-test01` | test01 (nữ) | NPC `Van Y` tìm thấy tại (257,121) `npc=182 dist=0.0`; menu `990011/1..7 t7`; `shop 431 goods 83` |
| `bot-8-test02-male` | test02 (**nam**, `model 0`) | `shop 431 goods 83`, `buys_ok 1`, `use_equips_ok 1`; Mongo `yuanbao 1e9 → 999 999 900`, `equip_list['17'] = 10124000` |
| probe `scripts/probe_costume.lua` tiêm vào service cảnh 2 `:00000351` (debug_console 16002) | — | bảng **trong bộ nhớ**: `shop 120 n=82 · 247 n=113 · 431..436 n=83 · 437 n=80`, `type=5` |

Mongo cuối: `CYTest01` yuanbao `999 994 780` (= 1e9 − 100 − 5 120), túi có `10127651`, ô 17 = `10124000`;
`CYTest02` (nam) yuanbao `999 999 900`, ô 17 = `10124000`.

**Phiên GUI thật** (`scripts/gui_launch.ps1`, test01, stage `stage-costumes-all`, 03:47:50 → tự thoát 03:49:27,
16 PNG do chính client lưu — `gui-1-test01/`): `cys-live-181131265-cam-sky-low.png` cho thấy `CYTest01` đứng giữa
"Chủ dịch trạm Thôi Phùng Cửu" và **"Tiem Thoi Trang / Van Y"** (model 施妆 + khổng tước) ở Đại Lý — NPC có thật
trong client. Nhưng nhân vật vẫn mặc đồ mặc định: `WXRender-0347.log` không có dòng `Mesh: Loading 女主角少林中级.mesh`
(mesh của Visual 1 → IVC 250), chỉ có `女主角p03001衣服` — nguyên nhân ở mục 8. Phiên đầu (03:38) lỡ đăng nhập test00
vì `Game.exe` của `stage-fps-daiviet` (bản 13:17) chưa đọc `CYS_BOT_ACCOUNT`; đã thay `Bin64` bằng bản `stage-review-red`
(23:43, có đọc biến) — chỉ trong stage của tôi.

---

## 7. Bẫy đã trả giá

1. **`ShopTable` tên cột quyết định tất cả** — không phải số cột, không phải `Num`. 383 dòng đều đủ 1 227 cột từ
   đầu; chỉ header thiếu tên.
2. **`t.merchadise_list[i]` đánh chỉ số theo ô** ⇒ ô phải liên tiếp; công cụ kiểm 0 lỗ trước khi đặt tên 200 ô.
3. **Bot `--npc` thắng `--exec`**: nói chuyện NPC sau khi exec mở Thương thành ⇒ shop cuối là 431, `--buy 120` thất
   bại "item not in the open shop". Mở Thương thành bằng bot thì **bỏ `--npc`** (`-Npc none`).
4. **`--out` của CysNetBot phải là đường dẫn tương đối dưới `Build/Logs`**, tính từ thư mục kho.
5. **`cys_server.ps1 restart` gọi từ Git Bash bị MSYS đổi `/home/ubuntu/...` thành đường dẫn Windows** ⇒
   "requires --confirm-root". Gọi `wsl … bash cys_server.sh` với `MSYS_NO_PATHCONV=1` hoặc từ PowerShell thật.
6. **Kiểm chuỗi ngoại hình qua `/mnt/c` mất 4,5 phút** (880 mesh + `all.material` 21 MB); trên Windows chỉ 12 s.
   Công cụ cache `/tmp/costumes-chain.json` theo mtime bốn đầu vào.
7. `attrib.model` của 16 nhân vật test đều là **1 = 女主角 (nữ)** (`CharModelEx` 0 = 男主角, 1 = 女主角); muốn ảnh
   nam phải đổi `model = 0` lúc offline (đã làm cho test02, hoàn tác `= 1`).
8. **Số cột `Exterior_TS` server là 27**, không phải 28 như bộ nhớ dự án — đo lại trước khi dùng.
9. Heredoc trong Bash của phiên này **nuốt `\\` thành `\`** ⇒ mã Python có `b'\\'` hỏng im lặng; dùng `bytes([92])`
   hoặc ghi tệp bằng công cụ Write.

---

### 8.1. Chỗ đứt, đo trước khi sửa

1. **Server gửi đủ.** `GCCharEquipment` (id 1194, `Src/Shared/ProtocolGen/PgPackets_misc.h:2775-2776`) có
   `fashion_item_id` và `visual`; `scenecore.lua:3364 set_fasion` đặt **bit `0x10000`**. Cả hai đường đều gửi:
   lúc vào thế giới (`scenecore.lua:2122-2131`) và mỗi lần mặc/cởi (`scenecore.lua:3458 broad_char_equioment`).
   Log client trước khi vá đã có `flag=0x8005001f` — tức bit thời trang **đang bật** mà client bỏ qua.
2. **Client bỏ qua.** `CysInventoryNet.cpp:208-212` chỉ áp `flag & 0x1..0x10`; `grep HEQUIP_DRESS Src/Client` = 0;
   `GMDataBase.cpp` không mở `EquipDress.txt`.
3. **Không có chỗ chứa.** `SDATA_PLAYER_OTHER::m_nEquipmentID[HEQUIP_NUMBER]` chỉ **9** ô, mà thời trang là điểm
   **16** ⇒ `Set_Equip(HEQUIP_DRESS)` sẽ ghi tràn mảng. Vì vậy ô thời trang phải có trường riêng, đúng như
   `m_nMountID` của thú cưỡi.

### 8.2. Hai phép đo quyết định thiết kế

| câu hỏi | đo trên dữ liệu CY | kết luận |
|---|---|---|
| Lưu **id vật phẩm** hay **visual**? | server gửi `visual = equip_data:get_visual()` = chỉ số EquipDress | lưu **visual** — không phải dựng `CObject_Item` tạm, không phụ thuộc `EquipBase` phía client |
| Bộ đồ có che tay/chân không? | hộp bao `女主角少林中级.mesh` = x[−78,4; 78,4] y[−1,4; 158,9]; đúng bằng **hợp** của 衣服 (x±45,9 y 20..158,6) + 护腕 (x±78,4 y 122..141) + 靴子 (y −0,3..44,2). Nam và bộ `W_cloth_2026战甲01` cho cùng kết quả | mesh **trọn thân** ⇒ phải **ẩn** ô tay và ô chân, nếu không tay/giày thường đâm xuyên |
| Ô màu nhuộm tra cột nào? | nhóm 9 dòng `EquipDress 33/63..70 → IVC 284`: slot 1 → `女主角时装清凉` (cột 2), slot 2 → `…清凉1` (cột 3) … slot 9 → `…清凉8` (cột 10) | slot 1 = vật liệu gốc; slot k≥2 = `pDyeMat_RaceN[k−2]`; ô rỗng → về gốc (441/578 bộ chỉ có một slot) |

### 8.3. Đã sửa gì (9 file, tất cả mang thẻ `CYS-DRESS`)

| file | thay đổi |
|---|---|
| `Src/Shared/Common/GameDefine_Item.h` | **+1 dòng**: `HEQUIP_DRESS = 16` (trùng giá trị `HEQUIP_UNKNOW8`, khớp `define.lua HEQUIP_FASHION = 16`) |
| `Src/Engine/Interface/TDDBC_Struct.h` | `DBC_ITEM_EQUIP_DRESS (309)` + `struct _DBC_ITEM_EQUIP_DRESS` (7 INT = 28 byte) |
| `Src/Engine/Interface/CysDBCAccess.h` | `CysDressMaterial(pVisual, nRace, nDyeSlot)` — ánh xạ ô nhuộm đã đo ở 8.2 |
| `Src/Client/WXClient/DBC/GMDataBase.cpp` | **+1 dòng** bảng: `EquipDress.txt` schema `IIIIIII` (bộ nạp tự kiểm schema + record size) |
| `.../DataPool/GMDP_Struct_CharacterData.h` | **+1 trường** `m_nDressVisual` |
| `.../DataPool/GMDP_CharacterData.h/.cpp` | `Get_DressVisual` / `Set_DressVisual` + khởi tạo `INVALID_ID` (theo khuôn `Set_MountID`) |
| `.../Object/Character/Obj_PlayerOther.h/.cpp` | `OnDataChanged_Dress`, `UpdateDress`, `IsDressWorn`; `UpdateEquip` **bỏ qua** ARMOR/CUFF/BOOT khi đang mặc thời trang; `CreateRenderInterface` gọi `UpdateDress()` sau khi dựng lại 6 ô |
| `.../Object/Character/Obj_PlayerMySelf.h/.cpp` | `OnDataChanged_Dress` chuyển tiếp sang `m_pAvatar` + `m_pHeadAvatar` (hình nhân xem trước) |
| `.../Network/CysInventoryNet.cpp` | `if (p.flag & 0x10000) data->Set_DressVisual(p.fashion_item_id > 0 ? p.visual : INVALID_ID);` + log `dress=…(visual …)` |

Chuỗi khi chạy: `GCCharEquipment.visual` → `EquipDress[visual].nVisualID` → `ItemVisualChar` → mesh (theo
`Get_RaceID()`: 0 = nữ cột 1/2, 1 = nam cột 12/13) + vật liệu theo ô nhuộm → `Actor_SetObjectProperty` cho
`MainBodyMesh/Mat`, và `ArmMesh/Mat` + `FootMesh/Mat` đặt rỗng. Cởi ra (`fashion_item_id <= 0`) → gọi lại
`UpdateEquip(ARMOR/CUFF/BOOT)` nên giáp thường trở về.

### 8.4. Bẫy của bản vá này

**Schema `EquipDress.txt` KHÁC nhau giữa hai bộ dữ liệu.** `Assets/CanonicalCY` (bộ CY 3.71, bộ mà client
CY-Source chạy — `stage/Data` là junction tới đúng nó) có **7 cột / 1 050 dòng / record 28 byte**; bộ GL cũ
`Assets/Canonical` có **8 cột / 997 dòng / 32 byte**. Bảng đăng ký khai `"IIIIIII"` + `sizeof(...) = 28` nên nếu
ai đó chạy binary này trên bộ GL, bộ nạp DBC sẽ ghi `DBC ERROR: EquipDress.txt schema … (expected …)` rồi **mở
bảng rỗng** — thời trang lặng lẽ không hiện, **không crash**. Theo luật 14/09 ("MỌI THỨ như CY") và vì CI từ
14/09 chỉ chạy trên CanonicalCY, đây là lựa chọn đúng; chỉ cần nhớ dấu hiệu nhận biết ở dòng log đó.

**Dòng log để nghiệm thu nhanh** (`<stage>/Bin64`):
`WXClient.log` → `DBC: EquipDress.txt OK columns=7 records=1050 record=28` và
`CYS inv: GCCharEquipment … dress=<item>(visual <n>)`; `WXRender.log` → `Mesh: Loading 女主角少林中级.mesh`
(bộ Visual 1). Thiếu dòng mesh = bộ đồ chưa được áp.

**Ba chỗ cố ý KHÔNG đụng**: `Obj_Character` phần thú cưỡi (`m_fMountFlyHeight`, `GetGroundLift` — của `ride-finish`),
`GCCharEquipmentHandler.cpp` đời 0.85 (không nằm trên đường CY), và `OnUseEquipResult` (đã tự chặn `p.equipPoint <
HEQUIP_NUMBER` nên điểm 16 không lọt vào mảng 9 ô).

### 8.5. Nghiệm thu bản vá client (đo thật, 18/09)

| bằng chứng | kết quả |
|---|---|
| build | `Tools/build/build.cmd x64 costumes-x64 Release` → **rc=0** (`CMAKE_BUILD_TYPE=Release`, `/O2 /Ob2`) |
| test | `cys_netcore_tests` 18 checks · `cys_protocol_tests` 497 gói · `cys_world_tests` 83 checks · `cys_netbot_tests` 28 tests/100 000 fuzz → **4/4 PASS** |
| bảng mới nạp | `WXClient.log`: `DBC: EquipDress.txt OK columns=7 records=1050 record=28` |
| gói thời trang được giải mã | `CYS inv: GCCharEquipment obj=215 flag=0x8005001f … dress=10124000(visual 1)` |
| **mesh bộ đồ được nạp thật** | `WXRender.log`: `Mesh: Loading 男主角少林中级.mesh` + `D3D9 : Loading 2D Texture … tga_男主角少林中级.dds` |
| **ảnh trước/sau** | `gui-1-test01/cys-live-181131265-cam-sky-low.png` (đồ mặc định) ↔ `gui-2-pair/cys-live-200843750-cam-sky-low.png` (áo vàng Thiếu Lâm = `Phật Y Như Lai`, item 10124000) |
| **lặp lại trên tài khoản thứ hai** | `gui-6-test02-model1/cys-live-204387640-cam-sky-low.png`: `CYTest02` mặc đúng bộ đó; cùng ảnh cho thấy NPC hiện **"Cửa hàng Thời Trang / Vạn Y"** ⇒ tên chữ Hán + từ điển dịch tại wire đang chạy |
| người khác nhận được | bot quan sát (`bot-16-observer-test02`) nhận **1 × `GCCharEquipment` (id 1194, 30 B)** đúng lúc bot kia mặc (`bot-17`, `buys_ok 1 / use_equips_ok 1`) |
| chuỗi tra bảng, mô phỏng đúng đường mã C++ | `scripts/dress_resolve.py` → **578 mục × 2 giới = 1 156 phép kiểm, 0 hỏng** (`dress-resolve.txt`) |

**Giới tính lấy từ `Get_RaceID()` = `attrib.model` của server** (`CysModernHandlers.cpp:328 Set_RaceID((INT)packet.model)`),
và `CharRace` quyết định thân: **race 0 → `nModelID 1` → `女主角.obj`**, **race 1 → `nModelID 0` → `男主角.obj`**.
16 nhân vật test đều `model = 1` ⇒ **là NAM trong thế giới** (dù `CharModelEx` gọi chỉ số 1 là 女主角 — hai trục khác
nhau, đừng lẫn). Vì vậy `CYTest01` nạp `男主角少林中级.mesh` là **đúng**: bộ đồ khớp đúng thân mà client đang vẽ.
Muốn ảnh nhân vật nữ thì đặt `attrib.model = 0` (đã làm với `test02`).

### 8.6. Ảnh nhân vật NỮ chưa lấy được — vì `attrib.model = 0` KHÔNG vào nổi thế giới qua GUI (lỗi có sẵn, không thuộc bản vá này)

Ba lượt GUI trên **cùng một tài khoản `test02`**, chỉ khác giá trị `attrib.model`:

| lượt | `attrib.model` | kết quả |
|---|---|---|
| `gui-3-test02-male/` 09:21 | **0** | dừng ngay sau `submitted once through GL TextAccepted`, 168 s im lặng → `integration deadline exceeded`; **0 ảnh thế giới** |
| `gui-4-female-and-other/` 10:03 | **0** | y hệt; log `Game2` **không có dòng nào của `200003`** ⇒ chưa tới máy chủ trò chơi |
| `gui-6-test02-model1/` 10:15 | **1** | **vào được ngay**, 7 ảnh thế giới, mặc thời trang đúng |

Cùng lúc đó **bot đăng nhập `test02` luôn thành công ở cả hai giá trị** (`bot-13`, `bot-19`: `charlogin=granted`)
— bot không đi qua màn chọn nhân vật. ⇒ **`model = 0` chặn ở đường GUI (danh sách/chọn nhân vật), không phải ở
xác thực tài khoản, và không liên quan tới thời trang.** Vì `CharRace 0 → 女主角.obj`, hệ quả thực tế là **hôm nay
không nhân vật NỮ nào vào được thế giới bằng client** — đáng báo cho nhánh sở hữu màn tạo/chọn nhân vật.

**Hệ quả cho nhánh này:** ảnh in-game của bộ đồ **nữ** chưa chụp được, và sẽ chụp được ngay khi lỗi trên được sửa
(không cần đụng gì thêm ở phía thời trang). Nhánh nữ hiện đã được chứng minh ở mức dữ liệu: `dress_resolve.py`
**578 × 2 giới = 1 156 phép kiểm, 0 hỏng** — mọi mesh/material/texture **nữ** đều có thật trên đĩa — và đường vẽ là
**cùng một hàm** `UpdateDress()`, chỉ khác cột chọn theo `Get_RaceID()`.

`test02` đã được **trả về `model = 1`** (giá trị gốc) sau phép đo.

## 8b. "Server chỉ nạp lúc khởi động" — đúng một nửa, và chỗ nào thì khác

Điều phối viên đính chính 18/09 (có chứng minh live của nhánh khác): `lualib/scriptenginer.lua:118 try_load(id)`
**`require` từng script `Game_2/Script/**` LẦN ĐẦU có ai dùng tới**. Hệ quả cho ba loại tệp của nhánh này:

| tệp | nạp lúc nào | cần restart? |
|---|---|---|
| `configs/ShopTable.txt` (7 shop + header 200 ô) | `cfghelper:read_shop_table` lúc khởi động | **có** — đã nạp ở restart 2 (03:51) |
| `Game_2/Script/scripts/costume_shop.lua` + `scripts.lua` | `try_load(990011)` lần đầu có người bấm vào NPC | **không**, nếu từ lúc khởi động chưa ai chạm |
| `Game_2/Scene/*_monster.ini` (tên/vị trí NPC) | lúc **dựng cảnh** khi server khởi động | **có** |
| `GameServer/lualib/wire_names_vi.lua` (mục dịch tên) | `require` lúc khởi động (nằm ở `lualib/`, không phải `Game_2/Script`) | **có** |

**Đo, không suy — đợt đổi tên của nhánh này ĐÃ nạp rồi:** hai tệp ghi lúc **08:36:52**, server đang chạy khởi động
**09:35:05**, và log của server đó in `[AUTO_ROUTE_DISPATCH] … target_name= 万衣 target_script= 990011` khi bot
nói chuyện với NPC lúc 09:39 ⇒ tên chữ Hán đang sống, **không cần thêm restart nào cho `costumes-all`**.

---

## 9. Còn lại / cần quyết

- **Client chưa vẽ thời trang** (mục 8) — việc của nhánh sở hữu `Src/Client`; dữ liệu server và hai nhân vật test
  đang mặc sẵn để kiểm.

- `EquipExtraAttr` theo CY hay giữ đời cũ (mục 5).
- Tab Hình tượng mục 7/8 (419/420) vẫn rỗng — của `ride-finish`/`ui-fit-2`; nếu muốn đưa thời trang vào Thương
  thành thay vì NPC thì cần thêm mục con ở `YuanbaoShop.lua` (InterfaceFolder, không thuộc nhánh này).
- Tên NPC `Van Y` ASCII; muốn hiện "Vân Y / Tiệm Thời Trang" cần `i18n-2` thêm vào bảng dịch tên NPC (nếu có).
- Shop 247 có 113 ô nhưng client hiện 96 (17 ô cuối là bản có hạn của cùng bộ) — muốn hiện đủ phải nới
  `MAX_BOOTH_NUMBER` trong `Src/` (không thuộc nhánh này).
