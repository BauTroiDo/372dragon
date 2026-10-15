# Hệ tăng sức mạnh nhân vật — nhánh TRANG BỊ, trên server riêng CY — 17/09/2026

Tiếp nối [item_vi.md](item_vi.md) (túi, mặc/tháo, mua bán, dùng đồ). Phần này lo **nhánh trang bị**
của các hệ tăng sức mạnh: đục lỗ, khảm ngọc, cường hoá, đổi thuộc tính, ám khí, bảo giám.

Ký hiệu: **[DK]** dữ kiện đọc được từ mã/bảng (có đường dẫn + dòng); **[SL]** suy luận chưa kiểm;
**[LIVE]** đã đo trên server riêng `/home/ubuntu/cys-test-20260913` (login 15733 / game 15734).
Tài khoản đo: `test09` / CYTest09 (GUID 200010), cấp 15, phái 9, vũ khí `10106000` 桦木弩.
Bằng chứng: `Build\Logs\2026-09-17-power-equip\` (`survey-*.txt`, `gem-*.json`, `live-1..live-8\`,
`char\`, `tools\`). Đo sau lần restart **19:31:52** (đợt `maps-all`, 195 cảnh).

---

## 1. Bảng tổng kết — hệ nào chạy, hệ nào không

| # | Hệ | Đường vào | Trạng thái | Bằng chứng |
| --- | --- | --- | --- | --- |
| 1 | **Đục lỗ** 打孔 | XSCRIPT `311200 StilettoEx_3` | **CHẠY** | live-2: `slot_count` **0 → 2** sau 6 lần thử |
| 2 | **Khảm ngọc** 镶嵌 | XSCRIPT `701614 EnchaseEx_3` | **CHẠY** | live-3: `list_2[1] = 50101001`, `gem_count 1`, **att_m 278 → 405 (+127)** |
| 3 | **Cường hoá** 强化 | XSCRIPT `809262 FinishEnhance` | **CHẠY** | live-5/7: `enhancement_level` **0 → 2**, **att_p/att_m +11** |
| 4 | Ám khí 暗器 | gói `CGAskDarkAdjust` + XSCRIPT `332207` | đủ ba cổng, **chưa đo** (thiếu món ám khí) | `survey-2`, `survey-5` |
| 5 | Võ hồn 武魂 (`KFS*`) | gói `CGKfsOperate` → script `809270 OnAction` | đủ chuỗi, **chưa đo** | `survey-2` |
| 6 | Điêu văn 雕文 | XSCRIPT `809272` (12 hàm) | có, **chưa đo** | `survey-5` |
| 7 | Tẩy thuộc tính 洗炼 | XSCRIPT `888820 RefreshEquipAttr` | có, **chưa đo** | `survey-5` |
| 8 | Linh ngọc 灵玉 | XSCRIPT `888808 LingYu_*` | có, **chưa đo** | `survey-5` |
| 9 | **Bảo giám** 宝鉴 | — | **KHÔNG TỒN TẠI phía server** | mục 4.3 |
| 10 | **Ngọc giáp** `ArmorGem_*` (`UnderArmour*`) | — | **KHÔNG TỒN TẠI phía server** | mục 4.1 |
| 11 | Ghép ngọc `CGGemCompound` | gói 893 | **có handler, nhưng sinh được ID ngọc HỎNG** | mục 5 |
| 12 | Kỹ năng sinh hoạt 镶嵌 (`in_lay`) | `CGUseAbility` ability 3 | **luôn từ chối `OR_WARNING`** | mục 6 |

Kết luận một dòng: nút thắt của nhánh trang bị **không phải** thiếu handler và **không phải** thiếu
bảng dữ liệu — cả ba hệ chính đều chạy và cho đúng số. Nút thắt là **lệch tên hàm giữa lớp giao diện CY
và lớp script 0.85** (mục 4) cộng một **lỗ dữ liệu chờ nổ ở hệ ghép ngọc** (mục 5).

---

## 2. Cơ chế chung: khung CY gọi server bằng đường nào

**[DK]** Khung giao diện CY không gửi gói riêng cho từng hệ. Nó gọi `Set_XSCRIPT_Function_Name(...)` +
`Set_XSCRIPT_Parameter(i, v)` rồi `Send_XSCRIPT()`:

- `Src\Client\WXClient\Interface\GMGameInterface_Script.cpp:317 Lua_Send_XSCRIPT` đóng gói `X_SCRIPT`
  vào **gói 860 `CGExecuteScript`** `{m_ScriptID u32, m_szFunName str8, m_uParamCount u8, m_aParam array<i32>}`
  (`Registry\protocol\packets.yaml:12803`).
- Server: `GameServer/services/msgagent.lua:407 request:CGExecuteScript` → **cổng 1**:
  `configenginer:get_config("allowable_script_fun")[m_ScriptID]` phải tồn tại, nếu không gói bị bỏ
  **im lặng** (không gói trả lời, không log) → `scenecore.lua:5551 char_excute_Script` →
  `scriptenginer:raw_call` → tham số thật là `(selfId = my_obj_id, p1, p2, …)`.
- `GameServer/lualib/scriptenginer.lua:231 raw_call` có thêm hai cổng:
  - **cổng 2** `s.is_super_function(func)` (`lualib/class.lua:123`) hoặc `not_raw_call_function[func]`
    (`scriptenginer.lua:8-18`: `OnDefaultEvent`, `OnEventRequest`, `OnActivateOnce`,
    `OnActivateEachTick`, `OnDie`, `OnLeaveCombat`, `OnEnterArea`, `OnLeaveArea`, `OnTimer`) → BLOCKED;
  - **cổng 3** `check_function_is_allow(id, func)` (`scriptenginer.lua:248`).
- Bảng: `configs/AllowableScriptFunc.txt` — **730 dòng, GBK, 3 cột** `序号 / 脚本ID / 函数名`
  (`cfghelper.lua:5181`, khoá là cột `脚本ID`). `Game_2/Script/scripts/scripts.lua` ánh xạ id → đường dẫn.

### 2.1 ĐÍNH CHÍNH — cổng 3 hiện ĐANG MỞ, không lọc theo tên hàm

**Bản đầu của tài liệu này nói sai** rằng `Dress_Gem` hỏng vì `OnDressGem_Enchase` chưa có trong
`AllowableScriptFunc.txt`. Sai ở chỗ: `check_function_is_allow` **trả `true` ngay khi
`self.script_access == nil`** (`scriptenginer.lua:249-251`), và `script_access` chỉ được gán khi
`require "scripts.script_access"` thành công (`scriptenginer.lua:83-85`).
**[DK]** `find Game_2 -name "script_access*"` → **rỗng**, module đó không tồn tại ⇒ `script_access = nil`
⇒ cổng 3 luôn pass.

**[LIVE]** live-8 chứng minh trực tiếp bằng ba lần gọi và log server:

| gọi | whitelist? | dòng log | nghĩa |
| --- | --- | --- | --- |
| `701614 IsGem` | **KHÔNG** có tên trong bảng | **không có dòng nào** | đã chạy — cổng 3 không chặn |
| `701614 CysProbeNoSuchFn` | không có, hàm cũng không tồn tại | `[XSCRIPT] scriptenginer:call func NOT FOUND: id= 701614 func= CysProbeNoSuchFn` | qua được cổng 3, chỉ hỏng ở bước tra hàm |
| `999999 IsGem` | script id không có trong bảng | **không có dòng nào** | bị bỏ im lặng ở **cổng 1** trong `msgagent` |

⇒ **Chỉ SCRIPT ID được kiểm.** Cột `函数名` của `AllowableScriptFunc.txt` hiện không có hiệu lực.
⇒ `Dress_Gem` gọi `OnDressGem_Enchase` trên script 830013 (đã whitelist) thì **vẫn tới được hàm**.
Vì sao khung đó chưa chạy thì **chưa kết luận được** — phải đo với một món thời trang và ngọc thời
trang thật, chưa dựng được trong đợt này.

**[DK]** Bot `Build\bot-unknownid\CysNetBot.exe` đã có sẵn cờ `--exec SCRIPT,FUNC[,P1..P8]`
(`Src\Tools\CysNetBot\main.cpp:265` và `:2611`, mốc `// CYS-EXEC`) gửi đúng gói 860 — **không cần thêm
cờ mới**, nên không dựng lại bot và không phải chạy bốn bộ test. Thứ tự trong một phiên:
`--exec` chạy ở bước `Chat`, **trước** pha `Inv` (`main.cpp:2747`), nên gọi XSCRIPT rồi `--equip 0`
trong cùng một phiên là đo được ngay.

---

## 3. Ba hệ đã đo live

Bàn đo: vũ khí `10106000` 桦木弩 (`EquipBase.txt` dòng 1199: `Lv(需求等级) = 1`, `Type = 6` 弩类,
`基础外功攻击 = 75`, `基础内功攻击 = 75`, `status = 3` ⇒ **đã giám định**, `0x02 = IEI_IDEN_INFO`).
Mốc chuẩn, lặp lại ở live-1/3/4/5/6/7 **[LIVE]**:

| mốc | att_p | att_m |
| --- | --- | --- |
| không mặc vũ khí | 203 | 203 |
| mặc vũ khí trắng | 278 | 278 |
| mặc vũ khí + 1 viên `50101001` | 278 | **405** |
| mặc vũ khí + ngọc + cường hoá **+2** | **289** | **416** |

### 3.1 Đục lỗ — `311200 StilettoEx_3(selfId, idBagPos, idBagPosStuff)` — CHẠY

live-2: 6 lần `--exec 311200,StilettoEx_3,4,5`.

```
truoc: slot_count = 0 ; vat lieu o tui 5 = 10 mon
sau  : slot_count = 2 ; vat lieu o tui 5 = 4 mon   (6 lan thu, 6 lan tru vat lieu, 2 lan thanh cong)
```

Khớp đúng thiết kế **[DK]** (`GameServer/lualib/script_base.lua LuaFnStilettoCostExe`):
vật liệu + tiền bị trừ **trước**, rồi `if slot_count < 3 then if math.random(100) % 2 == 0 then return -5 end end`
⇒ **50 % hỏng**, mất vật liệu. Khoá tra bảng `SlotCost.txt` = `item:get_level() * 100 + 1 + slot_count`
(479 dòng, khoá 101…12004); với vũ khí cấp 1 là 101 → 3000 tiền + `20109001` 牛角 ×1.

**[LIVE] Xác nhận lỗ hổng kiểm vật liệu (R3).** Lượt đo dùng `30900010` 宝石镶嵌符 (**lớp 3**) làm vật
liệu đục lỗ, **không phải** `20109001` (lớp 2), và server **vẫn nhận**. Nguyên nhân [DK]: điều kiện từ
chối là

```lua
if stuff_item_id < item_cost.id and stuff_item_id > 20109015 then
    if stuff_item_id ~= 20310111 then return -2 end
end
```

Mọi vật phẩm có `index >= item_cost.id` (tức gần như mọi món lớp 3, `3xxxxxxx > 20109001`) làm vế đầu
sai ⇒ được nhận. **Chưa vá** — đây là thay đổi luật chơi, cần người dùng quyết.

### 3.2 Khảm ngọc — `701614 EnchaseEx_3(selfId, gem, equip, mat, _, location)` — CHẠY

live-3: `--exec 701614,EnchaseEx_3,100,4,5,0,0` rồi `--equip 0`.

```
truoc (khong mac) : att_p=203 att_m=203
sau  (mac lai)    : att_p=278 att_m=405
Mongo equip_list.1: list_2 = [50101001, 0, 0, 0] ; gem_count = 1 ; slot_count = 2
```

**+127 att_m, +0 att_p — đúng bằng ô `内功攻击 = 127` của dòng `50101001` 猫眼石(1级) trong
`GemInfo.txt`** (dòng 3, cột 37). Cộng thẳng, không hệ số ⇒ khớp đường mã
`lualib/item.lua:261-280 equip_data:get_gem_attrs()` → `lualib/db/human_attrib.lua:1753` (lấy) và
`:1778-1780` (cộng) → `get_attrib()` `:2399-2418` → `send_refresh_attrib()` `:2667` → **1772 `GCDetailAttrib`**.
Ngọc **không** đi qua `StandardImpact.txt` hay `ImpactDirectly.txt`.

Điều kiện [DK] (`Game_2/Script/scripts/event/liveabilityevent/gem_embed.lua:12-119`): ngọc lớp 5,
trang bị lớp 1, vật liệu đúng `30900010`; chặn `equip_point` ∈ {RIDER, UNKNOW1/2, FASHION, TOTAL,
LINGWU_*, ALL}; chặn ngọc "điểm" `gemtype 31..33`; ô `location + 1` phải trống ⇒ **phải đục lỗ trước**;
`CheckEnchaseExVaild` cấm hai viên cùng `Type`; `CheckEnchaseGemTypeVaild` — vũ khí chỉ nhận
`Type ∈ {1,2,3,4,21}`, giáp/mũ/giày/đai `{11,12,13,14}`, thần binh/ám khí/võ hồn cả 1…21.

Nguồn ngọc: NPC **范大成 (宝石商人)**, `Game_2/Scene/suzhou_new_monster.ini [monster62]`, **cảnh 1 Tô
Châu (208, 230)**, script `1051` gọi thẳng `DispatchShopItem(..., 31)`. Cửa hàng 31: tiền **vàng**
(cột `货币单位 = 1`), 100/viên, `是否能够购买多个物品 = 0`.

### 3.3 Cường hoá — `809262 FinishEnhance(selfId, equip, essence)` — CHẠY

live-5 (5 lần) + live-7 (15 lần), tinh hoa `30900005` 地煞强化精华 (vũ khí cấp 1 < 40).

```
live-5: 5 lan  -> 5 tinh hoa bi tru, enhancement_level VAN 0, att khong doi
live-7: 15 lan -> 15 tinh hoa bi tru, enhancement_level = 2, att_p 278->289, att_m 405->416
```

**+11 ở cả hai — đúng bằng công thức** [DK]: `lualib/db/human_attrib.lua:881-896 cal_enhance_effect`
→ `addiv = bonus[rate_key] * iv // 100`; `ItemEnhance.txt` slot 0 cấp 2 có `外攻 = 内攻 = 15`,
`iv` = 75 (base của `10106000`) ⇒ `15 * 75 // 100 = 11`. (Ở cấp 1 sẽ là `10 * 75 // 100 = 7`.)
Tiền: jiaozi 28.857.565 → 28.855.700 (−1.865) khớp `收取金钱` 100/115/132 của ba cấp đầu với
2 + 3 + 10 lượt.

**[DK] Vì sao 5 lần đầu đều hỏng — tỉ lệ thành công thật là BÌNH PHƯƠNG số trong bảng.**
`lualib/script_base.lua` (trong `LuaFnEquipEnhance`, ~dòng 3779-3790):

```lua
local losecount = Equip:get_param(9, "ushort") ; losecount = losecount + 1
local currate = downlvinfo.odd * losecount          -- odd = 788 o cap 1
local sjrate = math.random(10000)
if sjrate <= currate then
    sjrate = math.random(10000)
    if sjrate > 10000 - currate then                -- phai DONG THOI dung ca hai
        succ = true
```

Hai lần quay độc lập, mỗi lần xác suất `currate/10000` ⇒ **P(thành công) = (odd × losecount / 10000)²**.
Ở lần thử đầu cấp 1: `(788/10000)² = 0,62 %`, chứ không phải 7,88 % như cột `成功率` gợi ý.
`losecount` là bộ đếm an ủi lưu trên món (`set_param(9, …)`) nên tỉ lệ tăng dần sau mỗi lần hỏng —
đó là lý do 5 lần đầu trượt rồi 15 lần sau ăn hai cấp. **Chưa kết luận được** đây là cố ý hay lỗi
sao chép: cần bản gốc để so. Không sửa.

Điều kiện [DK] (`Game_2/Script/scripts/event/equip/equip_enhance.lua:12`): món phải **đã giám định**
(`LuaFnIsIdentd` → `item.status & 0x02`); tinh hoa theo cấp món và cấp cường hoá —
`30900005` (< cấp 40) / `30900006` hoặc `30900045` 强化露 (≥ 40) / `38008160-61` (từ +9).

---

## 4. Lớp lỗi chính: LỆCH TÊN HÀM giữa giao diện CY và script 0.85

### 4.1 Bảng đối chiếu "tên CY gọi → hàm server có sẵn tương đương"

**[DK]** — `Build\Logs\2026-09-17-power-equip\survey-1-xscript.txt` và `survey-5-whitelist.txt`.
**Không viết hàm mới**; cột cuối chỉ nêu hàm **đã có thật** trên server.

| Khung `InterfaceFolder` | Hàm CY gọi | Có trong `Game_2/Script/scripts`? | Hàm server tương đương (script id) |
| --- | --- | --- | --- |
| `ArmorGem_Handle` | `UnderArmourJewelCompound`, `UnderArmourJewelRecycle`, `ShowUnderArmourIntro` | ✘ | **không có** — hệ ngọc giáp chỉ tồn tại ở bản CY |
| `ArmorGem_Change` | `UnderArmourEmbed`, `UnderArmourSplit` | ✘ | **không có** |
| `ArmorGem_Upstage` / `_Downstage` | `UnderArmourJewelUp`, `UnderArmourJewelRankReset` | ✘ | **không có** |
| `Dress_Gem` | `OnDressGem_Enchase` | **✔** `dress_gem_embed.lua:184` | chính nó, **và** `OnDress_Enchase` (`:14`) — cả hai trên **830013** |
| `Dress_SplitGem` | `BuySplitFu` | ✘ | `BuyDressFu` (`dress_gem_embed.lua:149`, **830013**) |
| `BudgetPlanGem` | `DownPayment`, `PayMoney` | ✘ | **không có** |
| `CardStrengthen` | `StudyBooks` | ✘ | **không có** |
| `EquipAttributeChange` | `DoRefreshEquipAttr`, `OnGenNewEquipAttr` | ✘ | **`RefreshEquipAttr` / `SwitchEquipAttr` / `DiscardNewEquipAttr`** — NPC 陈德 Tô Châu, script **888820** (đúng ba thao tác khung cần) |
| `EquipAttributeTransfer` | `EquipAttaFuke` | ✘ | **không có** (gần nhất: `FinishMoveEnhance` **809262** — chuyển CẤP CƯỜNG HOÁ, không phải thuộc tính) |
| `AnqiShuxingNEW` | `DarkSkillAdjustForBagItem`, `DoRefreshDarkSkill` | **✔** `obj/commonitem/332207.lua` | chính nó (**332207**) |
| `AnqiCuidu` | `LingyuCuiduConfim` | ✘ | nhóm `LingYu_Wash` / `LingYu_Switch` / `LingYuUnbind` / `LingYuWashItemCompound` / `LingYuRecycle` / `LingYuTransition` (**888808**) |
| `DWQianghua` | *(không dùng XSCRIPT)* | — | `DoDiaowenJinJie`, `DoDiaowenJinJieQiangHua`, `DoDiaowenJinJieShengJi`, `DoDiaowenJinJieHuiTui`, `DoTeXingQiangHua`, `DoTeXingShengJi` (**809272**) |
| `EquipBaoJian_*`, `SelfBaoJian`, `TargetBaoJian` | — | — | **không có** (mục 4.3) |

⇒ Việc "nhét chức năng vào khung" chỉ có nghĩa với **`EquipAttributeChange`**, **`AnqiCuidu`**,
**`Dress_SplitGem`** và **`DWQianghua`**: server có sẵn hàm tương đương, chỉ cần đổi tên hàm phía
client (và khớp thứ tự tham số). Bốn khung còn lại (`ArmorGem_*`, `BudgetPlanGem`, `CardStrengthen`,
`EquipAttributeTransfer`, `EquipBaoJian_*`) **không có gì để nhét vào** — muốn có phải viết logic mới.

### 4.2 Gói `CG` chuyên dụng của nhánh trang bị

**[DK]** — `survey-2-handlers.txt`.

| Gói | id | Handler | Chuyển tới | Bảng cần |
| --- | --- | --- | --- | --- |
| `CGUseGem` | 507 | **KHÔNG CÓ** | — | — |
| `CGRemoveGem` | 656 | `msgagent.lua:1396` | `scenecore.lua:2652` | `GemInfo.txt` |
| `CGRemoveDressGem` | 721 | `msgagent.lua:1400` | `scenecore.lua:2752` | `GemInfo.txt` |
| `CGGemCompound` | 893 | `msgagent.lua:1404` | `scenecore.lua:2805` | `DoubleGemCompound.txt`, `GemInfo.txt` |
| `CGDisplaceGem` | 517 | `msgagent.lua:1408` | `scenecore.lua:5564` | — |
| `CGAskDarkAdjust` | — | `msgagent.lua:1555` | `scenecore.lua:6584` → script **332207** (`define.DARK_ITEM_SCRIPT`, `define.lua:2206`) | `DarkSkillList.txt` (205), `DarkExpLevel.txt` (151) |
| `CGKfsOperate` | 908 | `msgagent.lua:1579` | `scenecore.lua:6693` → script **809270** `OnAction` (= `scripts.event.equip.wuhun`) | 8 bảng `KFS*` |
| `CGUseAbility` | 1372 | `msgagent.lua:1426` | `scenecore.lua:5665` → `ability/in_lay.lua` | `Ability.txt` |

**[DK] Thống kê**: `packet_domains/*.lua` khai báo **226** gói `CG`; `grep "function request:CG*"` trên
toàn `GameServer/services/` chỉ có **194** ⇒ **32 gói `CG` không có handler**. Trong 32 gói đó **chỉ
`CGUseGem` thuộc nhánh trang bị**; phần còn lại là cửa hàng người chơi, đấu giá, bang chiến, đăng nhập.
Khẳng định "226/226 gói `CG` đều được server xử" chỉ đúng theo nghĩa "tên gói có xuất hiện đâu đó".

### 4.3 Bảo giám (`EquipBaoJian_*`) — KHÔNG có trên server

**[DK]** `grep -rl "宝鉴" GameServer --include=*.lua` → **chỉ** `lualib/wire_names_vi.lua` (từ điển dịch);
`grep -rl "宝鉴" Game_2/Script` → rỗng; `grep -rli "baojian"` cả hai cây → rỗng; `configs/` không có
bảng `*BaoJian*`. Nhóm bảng `KFS*` là **武魂 (võ hồn)**, không phải bảo giám —
`char_kfs_operate` gọi `scripts.event.equip.wuhun`.

---

## 5. R1 — lỗ dữ liệu chờ nổ ở hệ NGỌC, ĐÃ VÁ phần phòng thủ

### 5.1 Vì sao nguy hiểm

`GameServer/lualib/item.lua:261-280 equip_data:get_gem_attrs()` duyệt `list_2[1..4]`, lấy
`config = gem_config[id]` rồi dùng **thẳng** `config[chn]` **không kiểm `config == nil`**. Hàm này chạy
mỗi lần tính lại thuộc tính trang bị (`human_attrib.lua:1753`, trong `common_equip_effect_flush`).
Một ID ngọc có trong `list_2` mà thiếu dòng trong `GemInfo.txt` ⇒ `attempt to index a nil value` ngay
giữa `item_effect_flush` ⇒ **nhân vật mất toàn bộ thuộc tính do trang bị cộng**.

### 5.2 Đo: ID ngọc lạ sinh ra từ đâu — 30 công thức có thật

`lualib/human_item_logic.lua gem_compound_item_index()` tính ID ngọc cấp kế tiếp **thuần số học**
(`item_index + 100000`, hoặc `+100001` khi `gem_index >= 100 + quality - 1`) và **chỉ** chặn khi
`quality > MAX_GEM_QUALITY[env]` (= **8** với `env = publish_yu`, `define.lua:2174`). Nó **không** kiểm
`gem_info[new]` có tồn tại không. Đường vào là gói **893 `CGGemCompound`** →
`scenecore:char_gem_compound` — **gọi thẳng từ client, không cần NPC**.

**[DK]** `Build\Logs\2026-09-17-power-equip\gem-compound-audit.json` (417 dòng `GemInfo.txt`):

| | số |
| --- | --- |
| chặn vì quá cấp | 66 |
| ghép ra ID **có thật** | 321 |
| **ghép ra ID KHÔNG tồn tại** | **30** |

Cả 30 nằm ở dải 肩 cấp 4 → cấp 5, ví dụ `50431001 冰蓝流云·肩(4级)` → `50531001` (không có dòng).

Ngoài ra `gem-shop-audit.json`: **7 cửa hàng** (182, 293, 314, 315, 316, 346, 410) bày bán **141 ID ngọc
không có dòng** trong `GemInfo.txt`. Hiện **không NPC nào** mở bảy cửa hàng đó
(`grep g_shoptableindex` và `DispatchShopItem(...,N)` đều rỗng) nên chưa mua được — nhưng dữ liệu vẫn sai.

### 5.3 Bản vá đã áp — `Tools/server/gem_guard.py`

| | |
| --- | --- |
| file | `GameServer/lualib/item.lua` (71.908 → 72.709 byte) |
| thay đổi | thêm đúng một nhánh `if config == nil then <log 1 lần> else <vòng cũ> end`, mốc `-- CYS-EQUIP` |
| sao lưu | `/home/ubuntu/cys-test-20260913/backups/gem-guard-20260917T125044Z/item.lua` |
| kiểm | `luac -p` mã thoát **0** (cú pháp hợp lệ) |
| hoàn tác | `gem_guard.py revert --backup <dir>` |

Không đổi số, không đổi công thức, không đổi hành vi của ngọc hợp lệ — chỉ bỏ qua viên ngọc lạ.
⚠ **`lualib/*.lua` chỉ nạp lúc khởi động dịch vụ skynet ⇒ bản vá chỉ có hiệu lực sau lần restart kế
tiếp.** Công cụ không restart. Sau restart, kiểm bằng `gem_guard.py verify`.

Bản vá **không** sửa dữ liệu: 30 công thức vẫn cho ra ID không có dòng, người chơi vẫn mất 5 viên ngọc
để lấy một viên vô dụng. Muốn sửa dứt điểm thì phải hoặc bổ sung 30 dòng `GemInfo.txt` từ nguồn thật,
hoặc cho `gem_compound_item_index` chặn khi `gem_info[new] == nil`. **Cả hai đều chờ người dùng quyết.**

---

## 6. `in_lay.lua` — CỐ Ý KHÔNG VÁ, có lý do

**[DK]** `GameServer/services/scene/ability/in_lay.lua:9-35 can_use_ability` mất `return` ở hai nhánh
(dòng 29 và 31) so với bản anh em `ability/compound.lua`, nên **luôn** rơi xuống dòng 34
`return define.OPERATE_RESULT.OR_WARNING` ⇒ kỹ năng sinh hoạt 镶嵌 (`ABILITY_CLASS_INLAY = 3`,
`define.lua:1137`) không bao giờ khởi động được.

**Không vá, vì sửa dòng 29/31 sẽ làm lộ một lỗi thứ hai và biến một lời từ chối im lặng thành lỗi
server**: `in_lay.lua:83` gọi `self:is_fit_prescr(human)` **thiếu tham số `prescription`**, trong khi
`is_fit_prescr` mở đầu bằng `assert(human) ; assert(prescription)` (`in_lay.lua:37-39`) ⇒ ném lỗi
trong cảnh. Khảm ngọc thật đi đường XSCRIPT `701614` và **đã chạy** (mục 3.2), nên nhánh ability này
không chặn việc gì. Ai muốn bật nó phải sửa **cả hai** chỗ rồi đo lại.

---

## 7. Lệnh đo lại

```powershell
Set-Location C:\TLBB\085\CY-Source
$D = 'Build\Logs\2026-09-17-power-equip'
$T = '/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-17-power-equip/tools'

# 0. doi server ranh (moi lenh ghi Mongo deu bi tu choi khi con ket noi 15733/15734)
wsl.exe -d TLBB -u root -- bash $T/wait_idle.sh 240

# 1. dat nhan vat canh tiem ngoc To Chau + cap tien vang
wsl.exe -d TLBB -u root -- python3 -B $T/equip_char.py place --guid 200010 --scene 1 --x 208 --z 233 --money 20000

# 2. mua ngoc + thao vu khi
& "$D\tools\run_bot.ps1" -Out live-N -BotArgs @('--npc','208,230','--buy','31,50101001,1','--unequip','0','--bag','1')

# 3. doc o tui THAT (chi so wire = khoa Mongo tru 1; ngoc vao khoang 100+)
wsl.exe -d TLBB -u root -- python3 -B $T/equip_char.py show --guid 200010

# 4. vat lieu (lop 3 nen give_item chep shape duoc)
wsl.exe -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/give_item.py give --guid 200010 --item 30900010 --count 10
wsl.exe -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/give_item.py give --guid 200010 --item 30900005 --count 30

# 5. duc lo (lap lai vi 50% hong) -> kham -> cuong hoa -> mac lai
& "$D\tools\run_bot.ps1" -Out live-N -BotArgs @('--exec','311200,StilettoEx_3,4,5','--exec','311200,StilettoEx_3,4,5')
& "$D\tools\run_bot.ps1" -Out live-N -BotArgs @('--exec','701614,EnchaseEx_3,100,4,5,0,0','--equip','0')
& "$D\tools\run_bot.ps1" -Out live-N -BotArgs @('--exec','809262,FinishEnhance,7,6','--equip','0')

# 6. tra nhan vat ve cho cu
wsl.exe -d TLBB -u root -- python3 -B $T/equip_char.py restore --guid 200010 --original $T/../char/original-200010.json
```

Công cụ chỉ đọc (chạy được cả khi server bận):

```powershell
wsl.exe -d TLBB -u root -- bash $T/survey.sh          # khung CY goi gi vs server co gi
wsl.exe -d TLBB -u root -- bash $T/survey5.sh         # ham nao cua script nao da duoc whitelist
wsl.exe -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/gem_guard.py audit
wsl.exe -d TLBB -u root -- python3 -B $T/table_probe.py find --table GemInfo.txt --col 0 --value 50101001
wsl.exe -d TLBB -u root -- python3 -B $T/shop_row.py --shop 31
wsl.exe -d TLBB -u root -- python3 -B $T/npc_find.py --script 1051
```

**Bẫy đã sập**:
- `equip_char.py` / `give_item.py` **từ chối ghi khi còn bất kỳ kết nối nào** trên 15733/15734 — trong
  phiên nhiều agent phải chờ; dùng `tools/wait_idle.sh N` rồi thử lại vài lần.
- Gọi `wsl.exe` từ Bash tool của Git Bash làm **hỏng đường dẫn `/mnt/c/...`** (chèn
  `C:/Program Files/Git/`). Dùng PowerShell tool, hoặc `bash //mnt/c/...` (hai gạch chéo).
- `--exec` chạy **trước** pha `Inv`, nên muốn "gọi XSCRIPT rồi mặc lại" thì để `--exec` và `--equip`
  trong **cùng một phiên**; còn muốn "tháo ra rồi gọi XSCRIPT" thì phải **hai phiên**.
- Chỉ số ô túi trên wire = khoá Mongo **trừ 1**; ngọc (lớp 5) rơi vào ngăn nguyên liệu, **ô 100 trở lên**.
- Cột `成功率` của `ItemEnhance.txt` **không** là tỉ lệ thật: mã quay hai lần nên tỉ lệ là bình phương
  (mục 3.3). Đừng kết luận "cường hoá hỏng" sau vài lượt trượt.
