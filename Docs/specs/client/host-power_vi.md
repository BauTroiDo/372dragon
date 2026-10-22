# host-power — 82 hàm host chỉ khung hệ sức mạnh gọi (17/09/2026)


Quy ước: **[DK]** dữ kiện đo/đọc được (có đường dẫn, offset hoặc số). **[SL]** suy luận. Không chắc thì ghi "chưa kết luận được".

---

## 0. Trả lời ngắn

Trong **82** hàm (không phải 81 — xem 1.1) mà **chỉ** các khung hệ sức mạnh gọi:

| | số hàm | số lời gọi |
|---|---|---|
| thuộc hệ **server ĐÃ CHẠY** | **12** | **71** |
| thuộc hệ server thiếu bảng / thiếu script / không có gì | 70 | 273 |
| chỉ tồn tại trong client CY 3.71, không có trong binary GL/085 | 65 | 201 |


Kèm theo là lớp trạng thái client còn thiếu: **gói 1014 `GCDetailXiulianList`** trước lượt này **không có handler nào ở client**, nên cửa sổ tu luyện không có cách nào biết cấp của 11 cuốn bí tịch.


---

## 1. Bảng xếp hạng

Cách đếm: quét mọi `.lua` của **2.065 khung** trong `Assets\CanonicalCY\Data\InterfaceFolder`, chỉ tính **lời gọi dạng toàn cục** (`Ten(` hoặc `Player:Ten(` với receiver là bảng host quen thuộc), giao với tập hàm `stub` của `Src\Client\LuaApiGen`. "Riêng hệ" = **không** khung nào ngoài 49 khung hệ sức mạnh gọi.
Script: `Build\Logs\2026-09-17-host-power\scripts\20-rank2.py` → `rank2.tsv`, `sites2.txt`; bảng dưới: `40-top20.py` → `top20.tsv`.

### 1.1 Bẫy phải sửa trước: regex của phép đếm cũ nuốt dấu cách sau `:` [DK]

`52-stub-reach.py` của power-attrib dùng `(?:(Ten)\s*[:.])?(Ten)\s*\(` — **thiếu `\s*` SAU dấu hai chấm**. Lua của CY viết `this : GetChildOffset( "SelfMiji" )` (có dấu cách), nên lời gọi **phương thức** bị đọc thành lời gọi **toàn cục**.

Sau khi sửa regex (`(?:(Ten)\s*[:.]\s*)?(Ten)\s*\(`):

```
rieng-he : 82   (truoc: 81)      dung-chung: 124 (truoc: 137)
ROI khoi nhom rieng-he: CheckIsSuperWeapon, GetChildOffset, PopComfirm_Alpha1
MOI  vao  nhom rieng-he: CommonClientMessage, GetEquipDur, GetRemainRepairCount, GetSectIsBackLevel
```


### 1.1b Bẫy thứ hai: phép đếm không nhìn vào `Network\Cys*Net.cpp` [DK]

`REAL_SOURCES` của `50-frame-host-status.py` chỉ gồm `Src\Client\WXClient\Script` và `\Interface`. Các module CYS mới đăng ký hàm host **thật** từ `Src\Client\WXClient\Network\Cys*Net.cpp`, và đăng ký **theo bảng**:

```cpp
const struct { const char* name; int (*fn)(LuaPlus::LuaState*); } methods[] = {
    ..., {"GetEquipDur", ActionGetEquipDur}, ... };
for (const auto& m : methods) CActionItem::s_pMetaTable->Register(m.name, m.fn);
```

Regex `Register\("Ten"` không bắt được dạng này. `scripts\50-recount.py` → `recount.txt`:

```
Ham host dang ky tu Network\Cys*Net.cpp ma phep dem cu KHONG thay: 7
Trong 82 ham "rieng he": bi dem NHAM la stub: 1   ->  GetEquipDur (da co that trong CysInventoryNet.cpp:604)
Tren toan bo client: 6 ten (GetEquipDur, GetEquipPoint, GetItemColorInShop, GetItemIconInShop,
                            Lua_GetEquipZhiZunType, SetActionFlash)
```

⇒ Nhóm này thật ra là **81 stub + 1 hàm đã có thật**. Con số "5.913 stub" của toàn client cũng dôi 6.

### 1.2 Hai mươi dòng đầu

| # | Hàm host | Lời gọi | Hệ | Server đã chạy chưa | Nguồn hành vi |
|---|---|---|---|---|---|
| 2 | **`GetXiuLianMiJiInfo`** | **35** | **tu luyện** | **CHẠY** (power-attrib 2.2) | **[DK]** `0x2d2950` — **ĐÃ CÀI** |
| 3 | **`GetXiuLianBookInfo`** | **16** | **tu luyện** | **CHẠY** | **[DK]** `0x2d2fe0` — **ĐÃ CÀI** |
| 4 | `GetZongMenTalentCoreData` | 15 | tông môn | thiếu `TalentInfo`/`ZongmenTalent` | [SL] chỉ-CY |
| 5 | `GetZongMenTalentNormalData` | 15 | tông môn | thiếu bảng | [SL] chỉ-CY |
| 6 | `GetZMSectUsePlanIndex` | 13 | tông môn | thiếu bảng | [SL] chỉ-CY |
| 7 | `ConvenientBulkBuyItem` | 12 | võ hồn (khung hoạt động) | script không tồn tại | **[DK]** `0x233740` |
| 8 | `GetShareZongMenTalentData` | 12 | tông môn | thiếu bảng | [SL] chỉ-CY |
| 9 | `GetSectIsModify` | 11 | tông môn | thiếu bảng | [SL] chỉ-CY |
| 10 | `Lua_OpenRlOpPage` | 10 | lệnh bài | KHÔNG có server | [SL] chỉ-CY |
| 11 | `GetMifaInfo` | 9 | kinh mạch | chỉ áp dụng được, không có đường ghi | [SL] chỉ-CY |
| 12 | `Lua_CreateSectInfoAction` | 9 | tông môn | thiếu bảng | **[DK]** `0x25a060` |
| 13 | `Lua_GetSectDesc` | 9 | tông môn | thiếu bảng | **[DK]** `0x25a9b0` |
| 14 | `Lua_SetZhenYuanGiftActionItem` | 9 | chân nguyên | KHÔNG có server | [SL] chỉ-CY |
| 15 | `Lua_GetRlBuffFromTable` | 8 | lệnh bài | KHÔNG có server (880001) | [SL] chỉ-CY |
| 16 | `ChangeSectSelectedIndex` | 5 | tông môn | thiếu bảng | [SL] chỉ-CY |
| 17 | `GetOtherComboBookInfo` | 5 | bí tịch chiêu thức | KHÔNG có server | [SL] chỉ-CY |
| 18 | `GetOtherMifaInfo` | 5 | kinh mạch | không có đường ghi | [SL] chỉ-CY |
| 19 | `GeTargetSex` | 4 | kinh mạch | không có đường ghi | [SL] chỉ-CY |
| 20 | `GetZhenfaAttr` | 4 | võ hồn (khung hoạt động) | script không tồn tại | [SL] chỉ-CY |

Hai mươi dòng đầu = **247/344** lời gọi của cả nhóm.

**Cột "hệ" lấy theo khung, nên có chỗ thô:** sáu hàm `Lua_GetPowerValue` / `Lua_GetPowerTime` / `Lua_IsSetPower` / `Lua_IsSetPowfix` / `Lua_OnPowerTime` / `Lua_OnPowfixTime` nằm trong hai khung tu luyện nhưng thuộc hệ **真元/công lực**, tức hệ **không có server**. Vì vậy con số "12 hàm thuộc hệ đã chạy" thật ra là **2 hàm tu luyện có thật + 6 hàm 真元 đội lốt + 4 hàm của `SelfEquip`**.

---

## 2. Ba hàm đã cài — nguồn hành vi từng ô

Mã: `Src\Client\LuaApiGen\CysHost_Power.cpp` (glue Lua) + `Src\Client\WXClient\Network\CysPowerNet.cpp` (trạng thái + bảng).

### 2.2 Bảng dữ liệu [DK]

`Build\Logs\2026-09-17-host-power\scripts\30-dbc.py` đọc thẳng DBC nhị phân `00CCBBDD` của client:

| Bảng (`Assets\CanonicalCY\Data\ConfigFolder`) | Cột × dòng | Bố cục |
|---|---|---|
| `XiuLianMiJi.txt` | 5 × **15** | `id, bookId, name, icon, explain` — id 0–4 → quyển 0, 5–10 → quyển 1, 11–14 → quyển 2 |
| `XiuLianBook.txt` | 4 × **3** | `id, name, icon, explain` |
| `XiuLianDetail.txt` | 63 × **2416** | `Index, BOOKLEVEL, BOOKID, (经验, 金币, 加成, 未知) × 15` |

- Tên cột lấy từ **dòng tiêu đề thứ hai của bản server** `R/configs/XiuLianDetail.txt` (47 cột = 3 + 4×11, cùng bố cục, ít hơn 4 nhóm bí tịch).
- `2416 = 16 BOOKID × 151 BOOKLEVEL`; server chỉ có `13 × 151` ⇒ đúng như power-attrib nói "thiếu phái 13–15".
- **`Index == số dòng + 1` ở cả 2416 dòng, 0 ngoại lệ** — nên tra bằng số dòng là hợp lệ; mã vẫn kiểm lại cột `Index` trước khi dùng số.

**Phép kiểm chéo mạnh nhất [DK]:** dòng `BOOKID = 9` (無門派), `BOOKLEVEL = 1` có `经验 = 1145` cho bí tịch 0. Phiên đo live của power-attrib (`live\xiulian-1`) thấy server trừ đúng **1145** kinh nghiệm cho bước học đó (`23388 → 22243`). ⇒ công thức dòng, ý nghĩa `BOOKID` và ý nghĩa cột 经验 **đều được một con số thật xác nhận**.

### 2.3 Trạng thái nhân vật: gói 1014 [DK]

`Registry/protocol/packets.yaml:14104` `GCDetailXiulianList` (48 byte): `u16 level × 11`, rồi `u16 upper_limit × 11`, rồi `u32 unknow_2`.
Server: `human.lua:8073 send_xiulian_list` (gọi từ `scenecore.lua:1703` khi vào thế giới), `unknow_2 = 54`, dữ liệu là `xiulian_list` = danh sách `{level, upper_limit}`.

`packets.yaml` đánh dấu gói này `confidence: medium` với lý do "bis() and bos() differ structurally" — **đã giải quyết [DK]**: `packet_domains/misc.lua:1015 bos` (hàm server dùng để **gửi**) ghi `11 × ushort level`, rồi `11 × ushort upper_limit`, rồi `uint`; còn `bis` ở dòng 1009 (hàm **đọc**, không dùng cho gói GC này) đọc `11 × uint`. Hai cách đều ra **48 byte** nên không phân biệt được bằng kích thước — phải đọc mã. Lớp sinh `PgPackets_misc.h` theo `bos`, tức đúng chiều server→client: `xiulian` = cấp, `xiulian_2` = giới hạn.

Trước lượt này **client không có handler nào cho 1014** (`grep "Xiulian" Src/Client` chỉ ra đúng một dòng chú thích ở `GMGameInterface_Script_PlayerMySelf.cpp:223` ghi "cultivation (GCXiulianList) is not ported -> 0"). Nay `CysPowerNet::Dispatch` nhận gói và giữ 11 cặp số.

### 2.4 `JingJie` — suy ra từ hai dữ kiện đo được, không đoán [DK→SL thấp]

Gói 1014 chỉ mang **hai** số mỗi bí tịch, còn B giữ **ba** (`Level`, `JingJie`, `MaxLevel`). Hai dữ kiện server:

- `human.lua:8021 fix_xiulian_list`: mỗi cuốn khởi tạo `{ level = 0, upper_limit = 10 }`;
- `odali_wuyazi.lua:206 AskXiuLianAdvanceJingJie`: thăng cảnh giới gọi `XiuLianLevelUpperLimitUp(selfId, mjId, 10)` — **cộng đúng 10**.


### 2.5 Hợp đồng đã cài

```
Player:GetXiuLianMiJiInfo(miji /*0..10*/, field)
   "Name" / "Explain"          -> XiuLianMiJi.txt dong miji, cot 2 / cot 4 (GBK nguyen xi)
   "Level"                     -> goi 1014 xiulian[miji]
   "MaxLevel"                  -> goi 1014 xiulian_2[miji]  (upper_limit)
   "JingJie"                   -> upper_limit / 10
   "UpLevelNeedExp"            -> XiuLianDetail dong (menpai*151 + level + 1), cot 3 + miji*4
   "UpLevelNeedMoney"          -> cung dong, cot 3 + miji*4 + 1
   miji ngoai 0..10, hoac field la, hoac tham so sai kieu -> KHONG tra gi (nil), dung nhu B
Player:GetXiuLianBookInfo(book /*0..1*/, field)
   "Name" / "Explain"          -> XiuLianBook.txt dong book, cot 1 / cot 3
   "Level"                     -> max JingJie cua cac cuon thuoc quyen do (0..4 / 5..10)
   book ngoai 0..1 (ke ca "HasActived" cua quyen 2) -> KHONG tra gi (nil), dung nhu B
```

Ba chỗ **cố ý an toàn hơn B**, đều ghi trong mã:

1. Bảng nào mở ra mà **sai hình dạng** (số cột/dòng nhỏ hơn mong đợi) thì bị **bỏ hẳn** — thà không hiện gì còn hơn hiện số của bảng khác.
2. Trước khi đọc chi phí, mã **kiểm lại cột `Index`** của dòng; lệch thì trả 0 và ghi log một lần.
3. Chưa nhận gói 1014 thì `Level`/`MaxLevel` trả 0 — **đúng bằng giá trị stub cũ**, không phải số bịa.

### 2.6 `XiuLianPage()` — cửa vào của cả hai hàm trên [DK]

Hai hàm ở 2.5 vô dụng nếu **không mở được cửa sổ**. B (`0x21b780`) làm đúng một việc: `PushEvent(0x286, -1)` sau một cờ chắn. Số `0x286` là id sự kiện **của B**, không dùng được trực tiếp ở đây — nhưng **chính khung CY nói tên sự kiện**: `Xiulian.lua:64 this:RegisterEvent("OPEN_XIULIAN_PAGE")`. Hệ sự kiện của 0.85 tra theo **tên**, nên chỉ cần đăng ký tên đó.

**Bẫy [DK]:** `CEventSystem::RegisterEventHandle` (`GMEventSystem.cpp:716`) làm `m_mapEventIndex_AsName[nameEvent]` rồi `if(!pEvent) return;`. Với một tên **không có trong `g_GlobalEvent`** (bảng 314 dòng của 0.85), `operator[]` chèn một mục NULL và **handler của khung bị vứt im lặng**. Vì vậy phải thêm định nghĩa sự kiện, nếu không thì dù có `XiuLianPage()` thật cũng chẳng có ai nghe.

Đã thêm (đều là **nối vào cuối**, không đổi id nào có sẵn):

| File | Thay đổi |
|---|---|
| `Src\Engine\Interface\TDEventDefine.h` | `GE_OPEN_XIULIAN_PAGE,` nối sau `GE_STUDY_XINFA` (của `host-xinfa`) |
| `Src\Client\WXClient\Event\GMEventSystem.cpp` | `{ GE_OPEN_XIULIAN_PAGE, "OPEN_XIULIAN_PAGE", },` nối cuối `g_GlobalEvent` |
| `CysHost_Power.cpp` | global `XiuLianPage()` → đẩy sự kiện, trả `1`/`0` (Infant.lua:1090 đọc `local bRet`) |

**23 khung CY gọi `XiuLianPage()`** (`SelfEquip`, `Pet`, `Ride`, `JingMai`, `SelfMiji`, `Wuhun`, `ZhenYuan`…), nên một hàm này mở đường cho toàn bộ nhóm. Nó nằm ở nhóm **dùng chung** theo phép chia việc — **đã báo `host-plumbing`** để không ai đăng ký trùng.

### 2.7 Chuỗi GBK, không chuyển mã [DK]

`XiuLianMiJi`/`XiuLianBook` của CanonicalCY vẫn là **GBK** (`30-dbc.py` in ra `GBK:#cfff263力拔山兮卷`). Client CY-Source là client **code page 936** (`MultiByteToWideChar(936, …)` ở `CysQuestNet.cpp:111`, `GameProcedure.cpp:1332`…), nên chuỗi được đẩy **nguyên byte** như mọi hàm host đọc DBC khác (`CysHost_Skill` đẩy `def->pszName`). Không tự ý chuyển mã ở đây — đó là quyết định của lớp i18n, không phải của hàm host.

---

## 3. Chỗ đấu nối vào cây mã

| File | Thay đổi |
|---|---|
| `Src\Client\WXClient\Network\CysPowerNet.h/.cpp` | **MỚI** — trạng thái tu luyện + ba bảng + `RegisterHost` |
| `Src\Client\LuaApiGen\CysHost_Power.h/.cpp` | **MỚI** — glue Lua (thư mục này được CMake glob, không cần sửa cmake) |
| `Src\cmake\components\wxclient.cmake` | +1 dòng nguồn `CysPowerNet.cpp` (thẻ `CYS-POWER`) |
| `Src\Client\WXClient\Network\CysModernHandlers.cpp` | +1 include, +1 mệnh đề `|| CysPowerNet::Dispatch(packet)` ở nhánh `default` |
| `Src\Client\WXClient\Network\CysModernGame.cpp` | +1 include, +1 dòng `CysPowerNet::RegisterHost();` cạnh ba dòng cùng loại |

Ba file dùng chung chỉ bị thêm **một dòng mỗi chỗ**, có thẻ `CYS-POWER`, đúng luật hook của TIMELINE mục 0.
**Không** sửa `CysHost_Skill.cpp` (của `host-xinfa`) và **không** sửa file nào của `host-plumbing`.
`Register` dùng cờ `force = true` vì `LuaApiGen_Player.cpp` đã đăng ký stub cùng tên trước đó (`IsMissing` sẽ trả false).

---

### 4.1 Đã chạy trong lượt này

| Bộ | Kết quả |
|---|---|
| build `cys_wxclient` (`Build\cmake\host-power-x64`, Release x64, parallel 4) | **rc = 0**, 1145/1145 mục tiêu, `bin\Game.exe` 4.594.176 byte, **0 lỗi** (`build-1.log:1864`) |
| protocol (`checks.ps1`) | **OK** rc=0, 10,58 s |
| pathlib | **OK** rc=0, 2,37 s — 418/418 `.path` |
| scene | **OK** rc=0, 30,38 s — 512/512 `.Scene` |
| smoke (`Tools\build\smoke.ps1`) | **OK 8/8** (0 bad, 0 skipped): OgreSmoke + M01/M09/M19/M25/M33 + 2 cảnh |
| đếm lại stub (`50-frame-host-status.gen_index`) | `GetXiuLianMiJiInfo` và `GetXiuLianBookInfo` chuyển từ `stub` sang **`real`** |

Chạy **lần hai lúc 22:34** sau khi thêm khung cưỡi thú (`checks-2.log`, `smoke-2.log`): build `cys_wxclient` **rc = 0**;
protocol **OK** 17,31 s; pathlib **OK** (nay **421** `.path`); scene **OK** (nay **515** `.Scene`) — hai con số tăng vì
`scene-import-gl` vừa thêm cảnh, không phải do thay đổi của nhánh này; smoke **OK 8/8** (0 bad, 0 skipped).

**Nói thẳng:** bốn bộ trên **không** kiểm mã của lượt này. `checks.ps1` chạy trên cây CI đã commit, còn `smoke.ps1` ghi rõ "Game.exe is never started here". Chúng chỉ là kiểm hồi quy.

### 4.1b Đầu dò `CYS_POWER_PROBE` — cách chạy phép kiểm GUI không cần chuột

`Tools\game\run_world_gui_live.ps1` tự đăng nhập, chọn nhân vật và vào thế giới, nhưng **không bấm nút nào**. Để lượt chạy đó mở được cửa sổ Tu luyện, `CysPowerNet::Dispatch` có một đầu dò chỉ bật khi biến môi trường `CYS_POWER_PROBE=1`:

- **đúng lúc**: gói 1014 tới **khi vào thế giới**, nên đầu dò nằm ngay trong handler của gói đó, lần đầu tiên nhận được;
- ghi ra `WXClient.log` bảy giá trị mà `Xiulian.lua` sẽ đọc cho cuốn 0 (`Name`, `Level`, `MaxLevel`, `JingJie`, `UpLevelNeedExp`, `UpLevelNeedMoney`, cộng `menpai`);
- rồi đẩy **một lần** `GE_OPEN_XIULIAN_PAGE`, để chính Lua của khung chạy thật.

Nhờ vậy bằng chứng có **hai tầng độc lập**: số do C++ tính (đầu dò) và hành vi do Lua gọi (dòng `missing host function` vắng mặt + cửa sổ vẽ ra). Không bật biến thì đầu dò không tồn tại với người chơi.

Chạy: `Build\Logs\2026-09-17-host-power\scripts\70-live.ps1` (chép binary vào stage → chạy lượt GUI → in thẳng các dòng cần đọc).

### 4.1c Mốc "TRƯỚC" — cửa sổ vốn KHÔNG mở được [DK]

Phiên chơi của người dùng lúc 14:10 trên bản cũ (`Build\world-gui\stage-fps-daiviet\Bin64\WXClient.log`) có **86** dòng `missing host function` và **không có dòng nào** liên quan `XiuLian`.

Đó không phải vì hai hàm chạy tốt, mà vì **không ai mở được cửa sổ**: `XiuLianPage()` là stub, sự kiện `OPEN_XIULIAN_PAGE` không có định nghĩa nên handler của khung bị vứt (2.6). Vì vậy mốc "trước" đúng phải phát biểu là **0 lời gọi, khung không tới được**, chứ không phải "có dòng missing rồi biến mất". Ghi đúng như vậy để người sau không đi tìm một cặp log không tồn tại.

### 4.2 Phép kiểm GUI trực tiếp — ĐÃ CHẠY, khớp từng số [DK]

Một lượt GUI sống trên server riêng, tài khoản **test09 / CYTest09 / GUID 200010** (menpai 9, cấp 15, exp 23388).
Bằng chứng: `Build\Logs6-09-17-host-power\live-1\` (log + 12 ảnh + `run.json`), ảnh chính chép ra `xiulian-window.png`.

**Log `WXClient.log` của lượt đó:**

```
[21:55:57] CYS power: host functions registered=3
[21:56:00] CYS power: GCDetailXiulianList 0/10,0/10,0/10,0/10,0/10,0/10,0/10,0/10,0/10,0/10,0/10
[21:56:00] CYS power: XiuLianMiJi.txt opened 5x15
[21:56:00] CYS power: XiuLianBook.txt opened 4x3
[21:56:00] CYS power: XiuLianDetail.txt opened 63x2416
[21:56:00] CYS power: probe miji0: Name=<力拔山兮卷> Level=0 MaxLevel=10 JingJie=1 UpLevelNeedExp=1145 UpLevelNeedMoney=34 menpai=9
[21:56:00] CYS power: probe book0: Name=<五行宝典>
[21:56:00] CYS power: probe pushed OPEN_XIULIAN_PAGE
[21:56:03] CYS ui: world-1 0|Xiulian_Frame|TLBB_MainFrameNULL|0,92,620,397|      <- khung HIEN tren man hinh
```

| Điều phải chứng minh | Kết quả |
|---|---|
| `missing host function Player:GetXiuLianMiJiInfo` / `...BookInfo` trong log | **0 dòng** (toàn log có 87 dòng `missing host function`, không dòng nào là của hai hàm này) |
| cửa sổ mở ra thật | **CÓ** — `Xiulian_Frame` nằm trong danh sách widget hiển thị, và ảnh `xiulian-window.png` cho thấy khung tiêu đề **"Tu luyện"** |
| số trên màn hình | **`0/10` × 5 cuốn** của quyển 1 — đúng `level 0 / upper_limit 10` của `xiulian_list` trong Mongo |
| cảnh giới | `JingJie = 1` (= `upper_limit / 10`) |
| chi phí cấp sau | `UpLevelNeedExp = 1145`, `UpLevelNeedMoney = 34` |
| `menpai` client dùng để tra bảng | `9` — khớp `BOOKID` của `XiuLianDetail` |

**Đối chứng phía server — bot bấm học thật** (`bot-study-2`, `--exec 2099,AskXiuLianLevelUp,0,0`):

```
truong              truoc            sau      chenh
exp                 23388          22243      -1145
jiaozi           28879065       28879031        -34
xiulian[0]           0/10           1/10
```

⇒ **Con số client hiện trước khi bấm bằng đúng con số server trừ khi bấm.** Vòng khép kín: bảng client → hàm host → cửa sổ → gói → script server → Mongo.

#### 4.2.1 Ba điều lệch, ghi nguyên văn chứ không làm tròn cho đẹp

1. **Một lỗi Lua trong khung — KHÔNG phải của hai hàm này [DK].**
   `CYS Lua failure env=Xiulian_Env ... Xiulian.lua:797: attempt to compare nil with number`.
   Dòng 797 nằm trong `Xiulian_SetHappyMonth()`: `local StartTimeLua, EndTimeLua = DataPool:Lua_GetPowfixTime()` rồi `if(StartTime < 0 ...)`. `Lua_GetPowfixTime` vẫn là **stub trả một giá trị**, nên `EndTimeLua` là `nil` → `tonumber(nil)` → `nil < 0` nổ. Hàm này chạy **sau** `Xiulian_Update()`, nên phần dữ liệu tu luyện đã vẽ xong; chỉ băng "tháng vui vẻ" hỏng. Đây là stub kế tiếp cần sửa cho khung này.
2. **Chữ Trung còn nguyên GBK [DK].** Ảnh cho thấy tên/mô tả quyển sách hiện ra **ô vuông**, còn các chuỗi có khoá StrDictionary ("Tu luyện", "Cần Cấp độ 70", "Công lực:") hiện tiếng Việt. Nguyên nhân: `XiuLianMiJi.txt` / `XiuLianBook.txt` của `CanonicalCY` **chưa được dịch** (vẫn GBK), trong khi các bảng khác đã dịch. Hàm host đẩy đúng byte của bảng — đây là việc **i18n/dữ liệu**, không phải lỗi hàm host. Sửa bằng cách dịch hai bảng đó, không phải bằng cách chuyển mã trong hàm host.
3. **Đầu dò làm hỏng vài phép kiểm của chính runner [DK].** `run.json`: `three_ground_clicks`, `position_changed`, `quit_requested`, `finished_in_time` = `false`. Cửa sổ Tu luyện rộng 620×397 mở ngay giữa màn hình che mất chỗ mà kịch bản thế giới định bấm xuống đất, và cũng chặn luôn đường thoát qua menu (tiến trình bị `Kill` khi hết giờ). Các phép kiểm login/vào cảnh/navmesh vẫn `true`. Ngoài ra `character_selected=false` là **lỗi sẵn có của runner**: nó so với `$env:CYS_BOT_ROLE` của tiến trình **cha** (không được đặt) nên luôn so với `CYTest00`.
   ⇒ Chỉ bật `CYS_POWER_PROBE` cho lượt lấy bằng chứng; đừng bật trong lượt CI đo di chuyển.

**Trạng thái test09 sau phép kiểm:** `xiulian_list[0].level = 1` (trước là 0), exp 22243, jiaozi 28.879.031. Không hoàn tác — đó là một thao tác chơi hợp lệ trên tài khoản test và chính nó là bằng chứng.

## 6. Bẫy đã sập


---

## 7. Việc tiếp theo, xếp theo "rẻ và chắc"


---

## 8. Khung cưỡi thú — nối `Ride.lua` vào `CysRideNet` (đợt 2, 17/09 22:30)

`ride-core` viết tầng mạng `Src\Client\WXClient\Network\CysRideNet.{h,cpp}` nhưng không được đụng
`Src\Client\LuaApiGen\`, nên phần hàm host chuyển sang nhánh này.

### 8.1 Đã cài — bốn tên, năm chỗ đăng ký

`Src\Client\LuaApiGen\CysHost_Ride.{h,cpp}` (MỚI). `CysRideNet` không cần `RegisterHost` của riêng nó:
file glue gọi thẳng vào `CysRideNet` và `CysModernGame`.

| Lua | Làm gì | Nguồn hành vi |
|---|---|---|
| `OpenRidePage()` | đẩy `GE_OPEN_RIDE_PAGE` | **[DK]** B `0x21b860` đẩy một sự kiện; **tên** lấy từ chính khung: `Ride.lua:20 RegisterEvent("OPEN_RIDE_PAGE")`. 8 khung CY gọi; `Infant.lua:1131` đọc `local bRet` nên trả 1/0 |
| `GetMountID()` và `Player:GetMountID()` | `CysRideNet::MountID()` | **[DK]** B để ở `_G` (`0x222af0`, trả number) còn `Ride.lua:433/467` gọi qua `Player:` — đăng ký **cả hai** cách viết |
| `Player:UseSkillInLua_Const()` | `CysRideNet::RequestAutoRide(1)`, trả 1/0 | **[DK]** cho nhánh LÊN thú: `Ride.lua:425 CallInOutRide(1)` gọi không tham số và kiểm `if nSucc == 1`. **[SL]** nhánh XUỐNG thú chưa chứng minh — xem 8.4 |
| `Lua_CysSelectRide(index)` | `CGExteriorRequest` type 7, category 3 | **[DK]** `scenecore.lua:3761` biến nó thành `human:set_ride(index)`. **Không phải tên của CY** (tiền tố `Lua_Cys` để không ai nhầm): trong giao diện CY, thú được chọn bằng cách **trang bị** (`Ride.lua:379 DoAction()`, `HEQUIP_RIDER = 8`) |

Sự kiện mới `GE_OPEN_RIDE_PAGE` nối cuối `TDEventDefine.h` + một dòng `g_GlobalEvent` — **cùng cái bẫy** như
`GE_OPEN_XIULIAN_PAGE` ở mục 2.6: không có dòng bảng thì `RegisterEventHandle` chèn NULL và vứt handler im lặng.

### 8.2 Hai chỗ đứt phía server — đã sửa cả hai [DK]

**(a) Không ai kiểm quyền sở hữu.** `human.lua:4188 get_riders_max_speed_up()` duyệt `exterior.rides` = bộ thú
**đã sở hữu** và lấy `speed_up` lớn nhất; còn `CGExteriorRequest` type 7/cat 3 đặt `ride` mà **không** kiểm sở hữu.
Đo trên `test09`: `exterior.rides = {}` và `attrib.ride = -1` ⇒ `speed_up = 0` ⇒ `impacts[0]` nil ⇒ không impact
⇒ `ride_model` vẫn −1 ⇒ server im lặng.
Cấp quyền phải qua `human:add_expiration_time(id, -1)` (`human.lua:6235`), ghi đúng một phần tử
`{ id = index, term = -1, terminable = 0 }`; hàm đó bị chặn khỏi `CGExecuteScript`.
**Công cụ mới `Tools\server\ride_grant.py`** (`show` / `grant --apply` / `clear --apply`, chỉ chạm GUID
200001–200016, chỉ khoá `exterior.rides`) ghi thẳng đúng hình dạng đó. Đã cấp **thú id 1 = 陆行雕** cho `test09`
(dòng `Exterior_Ride.txt` index 1, cột `门派 = -1` nên mọi môn phái dùng được, `模型索引 = 21`).

**(b) Cuộc đua 1600 ms / 3000 ms.** `scenecore.lua:6210 wait_ride_ready` bỏ cuộc sau `retry > 15` với
`skynet.timeout(10, …)` = 100 ms mỗi lần ⇒ cửa sổ chờ **1600 ms**. Nhưng `configs/SkillData_V1.txt` dòng ID 21
ghi `聚气时间(ms) = 3000` ⇒ server **luôn** bỏ cuộc trước khi mô hình kịp xuất hiện.
**Công cụ mới `Tools\server\ride_wait_patch.py`** (`audit` / `apply` / `revert --backup`) nâng 15 → **45**
(4600 ms). Đã áp: sao lưu `R/backups/ride-wait-20260917T152444Z/`, `luac5.4 -p` rc 0.
⚠ `services/*.lua` chỉ nạp lúc khởi động skynet ⇒ **chỉ có hiệu lực sau lần restart kế tiếp**; công cụ không restart.

Quan trọng: (b) chỉ làm mất **lời xác nhận**, không làm mất con thú. `GCCharAutoRide` chỉ là ack; mô hình luôn tới
riêng qua `ride_model` trên `GCCharBaseAttrib`/`GCDetailAttrib`. Vì vậy sau khi sửa (a) thì cưỡi thú **chạy được ngay,
chưa cần restart** — và đó đúng là điều đo được dưới đây.

### 8.3 Đo live — `live-2`, test09, `CYS_RIDE_PROBE=1` [DK]

```
[22:31:09] CYS ride: host functions registered=5
[22:31:12] CYS ride: CGCharAutoRide flag=1 sent (mount=-1)
[22:31:12] CYS power: ride probe: index=1 select_sent=1 auto_ride_sent=1 mount_id=-1
[22:31:16] CYS ride: mount -1 -> 21, fly height 0.0
[22:31:18] CYS ride: CGCharAutoRide flag=1 got no reply in 6000 ms - server path was silent
```

| | |
|---|---|
| hai gói đi ra | `select_sent=1` (CGExteriorRequest 7/3 index 1) và `auto_ride_sent=1` (CGCharAutoRide flag 1) |
| **nhân vật LÊN THÚ THẬT** | `mount -1 -> 21` sau **4 giây** — đúng 3000 ms niệm của kỹ năng 21 cộng độ trễ |
| mô hình đúng con đã cấp | **21** = cột `模型索引` của `Exterior_Ride.txt` dòng index **1**, đúng con vừa `ride_grant.py grant --ride 1` |
| ack vắng mặt | đúng như (b) dự đoán: 1600 ms < 3000 ms. Bản vá đã áp, **chờ restart** |

⇒ Mắt xích đứt mà `ride-core` chẩn đoán là **dữ liệu, không phải mã** đã được xác nhận bằng cách **sửa nó**:
cấp quyền sở hữu xong thì đường cưỡi thú chạy từ Lua → gói → skill 21 → impact → `ride_model` → `Set_MountID`.

### 8.4 Còn đứt, ghi rõ chứ không giấu

1. **Xuống thú chưa chứng minh [SL].** `char_auto_ride` gặp nhân vật **đang cưỡi** thì trả lời ngay mà **không**
   gỡ thú (`scenecore.lua:6172` nhánh 2). `CallInOutRide(0)` của CY gọi đúng cùng một hàm host, nên nút "xuống thú"
   nhiều khả năng **không làm gì thấy được**. Không bịa thêm gói thứ hai; cần đo riêng.
2. **Danh sách thú trong khung vẫn rỗng.** `Player:GetTotalHorseNum` (`0x2d7060`), `Player:GetMyHorse` (`0x2d7110`),
   `Player:SetHorseModel` (`0x2d7220`) đọc `s_pCharMountDBC`; `DataPool:GetCurActiveRidePoint`,
   `LifeAbility:Get_RideEquip_VisualID_ByActivePoint`, `Player:IsPlayerInFittingState` là **chỉ-CY**. Chưa cài —
   chúng là lớp *hiển thị/xem trước*, không phải lớp mạng, và phụ thuộc trạng thái túi/trang bị.
3. **Ack sau restart.** Sau lần restart kế tiếp, chạy lại `live-2` và dòng `got no reply` phải **biến mất**,
   thay bằng ack của `GCCharAutoRide`.
4. **`ride_grant.py` ghi thẳng Mongo** nên nhân vật phải **không** đang đăng nhập lúc ghi; và nó chỉ mô phỏng
   `add_expiration_time` — nếu sau này server mở được đường script hợp lệ thì nên dùng đường đó.
