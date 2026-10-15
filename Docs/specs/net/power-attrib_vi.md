# power-attrib — hệ tăng sức mạnh theo CHỈ SỐ NHÂN VẬT (17/09/2026)

Agent `power-attrib`. Nhánh **chỉ số nhân vật**; trang bị/ngọc là của `power-equip`.
Bằng chứng: `Build\Logs\2026-09-17-power-attrib\` (không vào git). Công cụ đo: `scripts\` trong thư mục đó.
Server riêng `R` = `/home/ubuntu/cys-test-20260913`, restart 19:31:52 (đợt `maps-all`). Tài khoản test **test10 / CYTest10 / GUID 200011**.

Quy ước: **[DK]** dữ kiện đo được (có đường dẫn/số). **[SL]** suy luận. Không chắc thì ghi "chưa kết luận được" kèm lý do.

---

## 0. Trả lời ngắn

**Nút thắt của nhánh này KHÔNG phải dữ liệu, cũng không phải handler gói — mà là (a) lớp hàm host của client và (b) script server của các hệ CY mới.**

Năm hệ đã **đo live và CHẠY** với số thật (mục 2): điểm tiềm năng, tu luyện, tâm pháp, danh hiệu, và cơ chế áp dụng kinh mạch.
Điều còn thiếu nằm ở hai chỗ khác nhau tuỳ hệ:

| Chỗ hỏng | Hệ bị ảnh hưởng |
|---|---|
| Hàm host client là **stub** (trả hằng số) → cửa sổ hiện số sai, nút bấm không gửi được | tu luyện (`GetXiuLianBookInfo`, `GetXiuLianMiJiInfo`), tâm pháp (`SendAskStudyXinfa`), kinh mạch, võ hồn, chân nguyên, tông môn |
| **Script server không tồn tại** cho tên hàm mà khung CY gọi qua `Send_XSCRIPT` | chân nguyên (889900/889902/889903), lệnh bài (880001), võ hồn hợp thành mới (790076), bí tịch (890099), 9 tinh thần khí (892471) |
| **Bảng dữ liệu không có trên server** | kinh mạch (`XueWeiBook`), bí tịch chiêu thức (`ComboSkillBook/Rate/RefixComboSkill`), tinh trận (14 bảng `XingZhen*`), tông môn (`TalentInfo`, `ZongmenTalent`), lệnh bài (`RLSkillBook`), long văn (`LongWen*`), chân nguyên (`zhenyuanpingfen`) |

**Ba giả thiết bị bác bằng số:**
1. "Thiếu handler gói" — với nhánh này thì **không**: 19/20 gói `CG` của hệ chỉ số có `function request:` thật trong `services/msgagent.lua` (195 handler thật / 226 gói khai báo). Ngoại lệ duy nhất là **`CGRongYu` — KHÔNG có handler** (mục 4.1).
2. "Thiếu whitelist `AllowableScriptFunc.txt`" — với nhánh này thì **không**: trong 25 lời gọi `Send_XSCRIPT` của các khung chỉ số, **23 thiếu cả hàm thật lẫn dòng whitelist**, và **0 trường hợp "chỉ thiếu một dòng whitelist"**. Kiểm từng ID: 10/11 script ID mà khung gọi **không có trong `scripts.lua`**; cái duy nhất có (`889903`) trỏ tới `charged_38000087` (script vật phẩm), không liên quan 真元. Khác với nhánh `power-equip`.
3. "Khung thiếu file Lua" — **không**: cả 36 khung khảo sát đều có đủ `.layout.xml` + `.lua` (mục 3.1).

---

## 1. Bảng trạng thái từng hệ

Cột "server xử" = nơi thật sự làm việc (file:dòng trên `R`). Cột "bảng" = bảng dữ liệu server cần, kèm số dòng thật.
Số dòng đếm bằng `wc -l` (kể cả 2–3 dòng tiêu đề); "CY" = `C:\TLBB\085\Tools\DATA NEW\DataCY31-08-26\Config`.

| Hệ | Khung (InterfaceFolder) | Gói `CG` | Server xử (file:dòng) | Bảng dữ liệu | Trạng thái |
|---|---|---|---|---|---|
| **Điểm tiềm năng** 潜能 | `SelfEquip` (KHÔNG phải `PointChoise` — cái đó là UI tân thủ) | `CGReqManualAttr` 598 → `GCManualAttrResult` 1031 | `services/msgagent.lua:1529` → `scenecore.lua:6471` → `scene/obj/human.lua:5912 manual_attr` | không cần bảng; `lv1_attrib` trong Mongo | **CHẠY** — đo live 2.1 |
| **Tu luyện** 修炼 | `Xiulian`, `XiulianStudy` | `CGExecuteScript` 860 → script **2099** `AskXiuLianLevelUp` / `AskXiuLianAdvanceJingJie`; trả về `GCDetailXiulianList` 1014 | `msgagent.lua:407` → `scripts/obj/dali/odali_wuyazi.lua:134,184`; `script_base.lua:6474/6484/6489/6503`; `scene/obj/human.lua:8037 xiulian_level_up`, `:8054 send_xiulian_list`; cộng chỉ số ở `lualib/db/human_attrib.lua:2356 xiulian_bonus` | `XiuLianDetail.txt` **1965** (CY 2418), `XiuLianRate.txt` có | **CHẠY (11 cuốn)** — đo live 2.2. Thiếu: `XiuLianBook.txt` (CY 5), `XiuLianMiJi.txt` (CY 17), `XiuLianRule`, `XiuLianNewScore`; gói 1014 **cứng 11 ô** nên không lên 15 cuốn được nếu không đổi bố cục gói |
| **Tâm pháp** 心法 | `ActionSkillsStudy` / `MessageBox_Self` (dòng gọi ở `MessageBox_Self.lua:6488`) | `CGAskStudyXinfa` 555 → `GCStudyXinfa`; `CGAskDetailXinFaList` → `GCDetailXinFaList` | `msgagent.lua:1379` → `scenecore.lua:2568 char_study_xinfa` | `XinFa_V1.txt`, `XinFaStudySpend_V1.txt` **304** (= CY 304, trùng từng ô theo menpai-audit) | **CHẠY** — đo live 2.3. Client: `SendAskStudyXinfa` là **stub** ⇒ người chơi bấm nút không gửi được |
| **Danh hiệu** 称号 | (danh sách nằm trong `SelfEquip`/HUD; không có khung riêng tên `Title`) | `CGCharAllTitles` 1230 → `GCCharAllTitles` 1227; `CGCharUpdateCurTitle` 1192 | `msgagent.lua:2389` → `scenecore.lua:8987` → `scene/obj/human.lua:7891 add_id_title`, `:7944 set_cur_title_by_id_title`, `:7968 update_titles_to_client`; cộng chỉ số ở `human_attrib.lua:1876 title_new_effect_flush` (gọi từ dòng 2135) | `CharTitleNew.txt` **494** (CY 1188) — **195/492 dòng có cặp (IA≥0, IV>0)**; `CharTitle.txt` 247 (CY 432); **thiếu `CharTitleBoard.txt`** (CY 320), `TitleFlash`, `ZM_CharTitle`, `ZongmenTitle` | **CHẠY** — đo live 2.4 |
| **Kinh mạch** 经脉 | `JingMai` (77 KB Lua), `TargetJingMai` | **KHÔNG CÓ gói riêng** | chỉ có chỗ **áp lại** bonus: `human_attrib.lua:2188-2198` đọc `db_attribs["jingmai_attr_bonus"]`; `scenecore.lua:257` có `-- self.jingmaienginer:loadall()` **đang bị chú thích**; script tự viết `scripts/YYC/jingmai.lua` (900099, khoá thẻ tháng) không dùng bảng CY | **thiếu `XueWeiBook.txt`** (CY 23) | **Cơ chế áp dụng CHẠY** (đo live 2.5) nhưng **không có đường nào GHI** `jingmai_attr_bonus`: không gói, không script CY, không bảng |
| **Võ hồn** 武魂 | `Wuhun` + 10 khung con (`WuhunSkillStudy`, `WuhunSkillUp`, `WuhunPropertyCreate`, `WuhunExtraPropertyUp/Del`, `WuhunMagicUp`, `WuhunTypeSwitch`, `WuhunShuXiangChange`, `NewWuhunSkillStudy`, `TargetWuhun`) | `CGKfsOperate` 908 (+ `CGWuhunWG`) | `msgagent.lua:1579` → `scenecore.lua:6693` → script **809270** `scripts/event/equip/wuhun.lua:9 OnAction` (có `KfsAttrExStudy` dòng 162…) | `KFSBase/KFSSlot/KFSAttrEx/KFSAttrExBook/KFSAttrLevelUp/KFSLevelupExp/KFSSkillLevelup/WuhunWg*` đều CÓ; lệch nhẹ: `KFSSkillLevelup` **278** (CY 296), `KFSAttrExBook` **17** (CY 18), `KFSCompoudEx` **11** (CY 12) | **Chưa đo được** — cần một võ hồn trong túi; xem 4.3. Khung `WuhunMagicUp` gọi script **790076 `OnWuHunCompoundNew` KHÔNG tồn tại** |
| **Thú hồn** 珍兽魂 | (khung pet) | `CGPetSoulXiShuXing` | `msgagent.lua` → `scenecore.lua:6707` → script **800127** (`osuzhou_yunshenshen`, whitelist có `OnPetSoulLevelUp`/`OnPetSoulXiShuXing`); `lualib/db/pet_attrib.lua:575+` | `PetSoulBase/Extension/Levelcost/LevelupInfo/Skill/PossVisualLocator` đều CÓ | Chưa đo (thuộc nhánh pet; `pets-wild` đang làm) |
| **Tông môn / thiên phú** 宗门 | `ZongMenSkill` (+`_Upstage`, `_Info`) | `CGSectOper` | `msgagent.lua:1755` → `scenecore.lua:8145 char_sect_oper` → `obj_me:study_sect(so.val)`; `lualib/talentenginer.lua:26` nạp **`sect_desc`** | **thiếu `TalentInfo.txt`** (CY 17), **`ZongmenTalent.txt`** (CY 257), `TalentLayerLevel` | Chưa đo. Khung gọi script **998633 `OpenMainUI` không tồn tại** |
| **Chân nguyên** 真元 | `ZhenYuan` + 6 khung con | — | không có gì trên server | **thiếu `zhenyuanpingfen.txt`** (CY 2054) | **Chưa có server**: 4 tên hàm khung gọi (`OnUpgradeClicked` 889900, `ActivationBtnClk`/`ApplyNiangLian`/`QuickOnceNingYuanClk` 889902, `OnActivePneumaSlot` 889903) **không tồn tại ở đâu cả** |
| **Lệnh bài** 令牌 | `EquipLingPai_*` (4 khung) | — | không có | **thiếu `RLSkillBook.txt`** (CY 25) | **Chưa có server**: 5 tên hàm trên script **880001** không tồn tại |
| **Long văn** 龙纹 | `LongwenExtraPropertyStudy/Up`, `LongwenPropertyReset` | — | không có | **thiếu `LongWenAddAttr` (CY 92), `LongWenBase`, `LongWenRateBase`** | Chưa có server |
| **Bí tịch chiêu thức** 秘籍 | `SelfMiji`, `TargetMiji` | — | không có | **thiếu `ComboSkillBook` (CY 36), `ComboSkillRate` (CY 101), `RefixComboSkill` (CY 68)** | Chưa có server; khung gọi `CheckDeleteBook` trên script 890099 (không tồn tại) |
| **Tinh trận** 星阵 | — | — | không có | **thiếu cả 14 bảng `XingZhen*`** | Chưa có gì |
| **GM bonus** | — | — | `human_attrib.lua:2199-2208` đọc `db_attribs["gm_attr_bonus"]` và áp lại sau mỗi lần dựng lại thuộc tính | — | Cùng cơ chế với kinh mạch; chưa đo riêng (cùng đoạn mã đã chứng minh bằng 2.5) |

### 1.1 Bẫy đặt tên đã sập và đã sửa

- **`PointChoise` KHÔNG phải khung điểm tiềm năng.** `PointChoise.lua:1` ghi rõ `新手指引UI` (UI tân thủ). Khung phân bổ điểm thật là **`SelfEquip`** (`SelfEquip.lua:1511` `Player:GetData("POINT_REMAIN")`, `:2451` `Player:SendAskManualAttr(g_AddStr, g_AddSpr, g_AddCon, g_AddInt, g_AddDex)`).
- **Danh hiệu có HAI nhánh khác nhau trong cùng một gói.** `scenecore:char_update_cur_title` (8987): `uct.id ~= 0` → `set_cur_title_by_id(id)` tra `human.titles` (danh hiệu **chuỗi**); `uct.id == 0` → `set_cur_title_by_id_title(uct.id_title_id)` tra `human.id_titles` (dòng **CharTitleNew**, là nhánh DUY NHẤT mang cặp IA/IV). Gửi nhầm nhánh thì "không có gì xảy ra". Bot có hai cờ riêng: `--set-title` và `--set-id-title`.

---

## 2. ĐO LIVE — năm hệ, số thật

Mỗi phiên: ghi Mongo (khi cần dựng điều kiện) → `CysNetBot --mode world` → `GCDetailAttrib` **trước và sau** trong cùng phiên → đọc lại Mongo.
Bot: `Build\cmake\power-attrib-x64\bin\CysNetBot.exe` (cờ mới `// CYS-ATTRIB`, mục 5). Bằng chứng: `Build\Logs\2026-09-17-power-attrib\live\<nhãn>\result.json`.

### 2.1 Điểm tiềm năng — **CHẠY** [DK]

`char/set-point-10.json` đặt `lv1_attrib.point_remain = 10` → phiên `live\point-3`:

```
--attr-point 2,2,2,2,2   ->  GCManualAttrResult result = 0   (ATTR_RESUlT_SUCCESS)
trước:  point_remain=10  str=22 spr=22 con=20 int=11 dex=20   att_p=278 att_m=278 def_p=193 def_m=148 hit=278 miss=93 hp_max=2250
sau:    point_remain=0   str=24 spr=24 con=22 int=13 dex=22   att_p=288 att_m=288 def_p=203 def_m=158 hit=293 miss=98 hp_max=2360
Mongo sau: lv1_attrib = {str 24, spr 24, con 22, int 13, dex 22, point_remain 0}   (char/power-after-point.json)
log server phiên đó: 0 traceback, 0 error
```

Mỗi chỉ số gốc **+2** đúng như yêu cầu, điểm dư **10 → 0**, và sáu chỉ số dẫn xuất đều đổi. Hệ này **không hỏng gì cả** — cả gói, handler, lưu Mongo lẫn hàm host client (`SendAskManualAttr` là hàm **thật** ở `GMScriptSystm.cpp:456` + `GMGameInterface_Script_PlayerMySelf.cpp:937`).

### 2.2 Tu luyện — **CHẠY** [DK]

Phiên `live\xiulian-1` (`--exec 2099,AskXiuLianLevelUp,0,0`):

```
GCDetailXiulianList (1014):  cuốn 1 = 1/10, mười cuốn còn lại 0/10     (trước đó 0/10)
exp: 23388 -> 22243  (bị trừ đúng bước học)
```

Phiên `live\xiulian-2` (lần thứ hai): `2/10`. Phiên `live\xiulian-base` (đăng nhập sau khi đã đặt môn phái 0 + 6 tâm pháp cấp 30):

```
xiulian_str = 1   (trước đó 0)      str = 25   (lv1_attrib.str 24 + 1)
```

**Vì sao lần lên cấp 1→2 KHÔNG làm chỉ số đổi thêm** — không phải lỗi, là làm tròn [DK từ bảng + công thức]:
`human_attrib.lua:2356` tính `bonus = ceil( val * 比例/100 * 加成 * 2 )`, với `val = lv1_attrib.str = 24`, `比例 = 0,5` (`XiuLianRate.txt` dòng 30) và `加成` = cấp cuốn sách (`XiuLianDetail` BOOKID 0: cấp 1→1, 2→2, 3→3, 4→4).
⇒ `ceil(0,24 × 加成)` = **1** với 加成 = 1, 2, 3, 4 và chỉ lên **2** khi 加成 = 5. Nhân vật cấp 15 quá nhỏ để thấy bước nhảy.

Hai điều kiện dễ làm hỏng phép đo: bonus chỉ tính khi nhân vật **có môn phái** (`get_xiulian_bonus` đòi `details.BOOKID == menpai`) **và có tâm pháp** (`xiulian_rate[min_xinfa_level]`); với 無門派 (menpai 9) mọi `xiulian_*` đứng yên ở 0 — đó là lý do phiên `xiulian-1` không thấy gì.
**Mỗi chỉ số gắn CHỈ MỘT cuốn**: `xiulian_bonus` map `str`←cuốn 1, `spr`←2, `con`←3, `int`←4, `dex`←5, `att_p`←6, `att_m`←7, `def_p`←8, `def_m`←9, `hit`←10, `miss`←11.

### 2.3 Tâm pháp — **CHẠY** [DK]

Phiên `live\xinfa-2` (đặt trước: môn phái 0, 6 tâm pháp **cấp 1**):

```
GCDetailXinFaList: xinfa [1:1 2:1 3:1 4:1 5:1 6:1]
CGAskStudyXinfa -> GCStudyXinfa:  xinfa study -> level 2
```

Phiên `live\xinfa-1` (cùng nhân vật ở **cấp 30**): `xinfa study -> level 30`, tức **không lên** — đúng luật, vì `scenecore.lua:2568` chỉ nâng khi `my_exp >= cost_exp` và nhân vật chỉ còn 22 243 exp. Không phải lỗi.

### 2.4 Danh hiệu — **CHẠY** [DK]

`char/set-title-1043.json` ghi `id_titles = [{id: 1043}]`. Dòng **1043 一世有你** của `CharTitleNew.txt` server có hai cặp: `(IA 0, IV 5000)` = `IATTRIBUTE_POINT_MAXHP` và `(IA 35, IV 1288)` = `IATTRIBUTE_HIT`. Phiên `live\title-1`:

```
GCCharAllTitles: m_nTitleId = 1, danh sách [1043:0]
hp_max 2360 -> 7360   (+5000, đúng IV)
hit      293 -> 1581  (+1288, đúng IV)
att_p/att_m/def_p/def_m/miss: không đổi  (đúng, dòng đó không có cặp nào khác)
--set-id-title 1043 -> Mongo attrib.title = {id: 137, str: "#1043", new_title_id: 1043}
```

`id = 137` = cột `Type` của dòng 1043 — đúng `set_cur_title_by_id_title` (`human.lua:7944`).
Bonus được áp **ngay khi có dòng trong `id_titles`**, không cần "đeo": `title_new_effect_flush` chạy trong lần dựng lại thuộc tính (`human_attrib.lua:2135`).

### 2.5 Kinh mạch — **cơ chế áp dụng CHẠY, không có đường nào ghi** [DK + SL]

`char/set-jingmai.json` ghi `attrib.jingmai_attr_bonus = {"19": 100, "22": 50}` (IA 19 = `IATTRIBUTE_ATTACK_P`, IA 22 = `IATTRIBUTE_DEFENCE_P`). Phiên `live\jingmai-1`:

```
att_p 288 -> 388   (+100, đúng IA 19)
def_p 203 -> 253   (+50,  đúng IA 22)
mọi chỉ số khác: không đổi
```

⇒ **[DK]** đoạn `human_attrib.lua:2188-2198` hoạt động đúng, và cùng khuôn đó cũng là đường của `gm_attr_bonus` (dòng 2199-2208).
⇒ **[SL]** nhưng **không có gói `CG`, không có script, không có bảng `XueWeiBook` nào ghi khoá đó**, và `scenecore.lua:257` để `jingmaienginer:loadall()` ở dạng chú thích. Nên với người chơi, kinh mạch hiện **không tồn tại**; chỉ có "cửa hậu" ghi thẳng Mongo.

### 2.6 Không kết luận được

- **Võ hồn**: chưa đo. `CGKfsOperate` có handler và script 809270 có `OnAction`, nhưng mọi nhánh của `wuhun.lua` đều đòi một **võ hồn trong túi** (`GetKfsData`, `kfs_slot.materials`). Dựng điều kiện đó cần phát vật phẩm võ hồn — chưa làm. Không được kết luận "hỏng".
- **Tông môn, chân nguyên, lệnh bài, long văn, bí tịch, tinh trận**: không đo được vì **server chưa có gì để đo** (mục 1 + 4.2), không phải vì phép đo thiếu.

---

## 3. Lớp client: khung có đủ, hàm host thì không

### 3.1 Khung

36 khung của hệ chỉ số đều có `.layout.xml` + `.lua` (`frame-host-status.tsv`); nhỏ nhất `ZongMenSkill_Info` 3,5 KB, lớn nhất `JingMai` 77 KB. **Không khung nào thiếu file.** Ngoại lệ duy nhất: `LongwenPropertyReset` có `.lua` mà **không có layout** (nó dùng layout của khung khác).

### 3.2 Hàm host: 6 667 tên đăng ký, **748 thật / 5 919 stub**

`Stub(state, "Recv", "Ten", ...)` trong `Src\Client\LuaApiGen` là hàm **giả**: trả hằng số, không đọc dữ liệu. Nhưng `LuaApiGen` chỉ đăng ký bản giả khi `IsMissing(table, "Ten")`, nghĩa là **bản thật của 0.85 (`GMScriptSystm.cpp` `RegisterObjectFunctor`) luôn thắng**. Đếm chỉ trên `LuaApiGen` sẽ nói quá số hàm thiếu (đếm sai lần đầu: "104 thật" → đếm đúng **748**).

Trạng thái các hàm then chốt (`host-spot.txt`):

| Hàm | Trạng thái | Hệ quả |
|---|---|---|
| `Player:SendAskManualAttr` | **thật** | điểm tiềm năng đủ đường từ UI tới server |
| `Player:GetData`, `Player:GetLevel`, `GetXinfaInfo`, `GetXinfaLevel`, `GetUplevelXinfaSpendMoney` | **thật** | |
| `SendAskStudyXinfa` | **stub** (`LuaApiGen_Cy.cpp:3503`) | nút học tâm pháp **không gửi gói** dù server nhận đúng (2.3). Đây là việc sửa rẻ nhất còn lại |
| `Player:GetXiuLianBookInfo`, `Player:GetXiuLianMiJiInfo` | **stub** (`LuaApiGen_Player.cpp:183/185`) | `XiulianStudy.lua:332/333/341` đọc `Level` / `MaxLevel` / `UpLevelNeedExp` từ stub ⇒ cửa sổ tu luyện hiện số sai; `:316` và `:373` kiểm `GetXiuLianBookInfo(2,"HasActived") ~= 1` nên luôn **chặn nhầm** nút thăng cảnh giới |
| `CompareHumanExp` | **stub** | cùng khung `XiulianStudy`, nhánh kinh nghiệm hồi lưu |
| `GetJingMaiFenYeFlag`, `GetMifaInfo`, `GetMifaActiveXueWei` | **stub** | khung kinh mạch chỉ vẽ khung rỗng |
| `GetKfsData`, `GetKfsBase`, `GetKfsSkill`, `GetKfsFixAttrEx` | **stub** | khung võ hồn không đọc được võ hồn thật dù server có dữ liệu |

Số stub theo khung (`frame-host-status.tsv`, cột `stub`): `ZhenYuan` 52, `JingMai` 42, `SelfMiji` 42, `Wuhun` 40, `ZongMenSkill` 39, `Xiulian` 39, `SelfData` 34, `XiulianStudy` 18, `EquipLingPai_Star` 13.

**Cảnh báo về cột `missing`** của bảng đó: nó còn lẫn **phương thức của widget CEGUI** (`this:Hide()`, `Frame:GetProperty()`, `RegisterEvent`, `Enable`…) mà bộ quét không thấy vì chúng là method của đối tượng, không phải global. Chỉ cột `stub` là kết luận chắc.

### 3.3 Bao nhiêu trong 5 919 stub nằm TRÊN ĐƯỜNG của các khung hệ sức mạnh?

`scripts\52-stub-reach.py` → `stub-reach.tsv` / `stub-reach.txt`. Chỉ đếm **lời gọi dạng global** (`Ten(` hoặc `Player:Ten(`), bỏ phương thức widget CEGUI (`Frame:SetProperty(`) vì lớp widget lo, không phải hàm host.

```
49 khung hệ sức mạnh gọi 306 hàm host toàn cục khác nhau
   trong đó là STUB:                                   218   (71 %)
      - CHỈ các khung sức mạnh gọi (riêng hệ):          81
      - khung khác cũng gọi (dùng chung):              137
```

**Con số đáng xếp ưu tiên là 81** — đó là các hàm chỉ phục vụ hệ sức mạnh, sửa cái nào là một tính năng sống lại: `GetXiuLianBookInfo`, `GetXiuLianMiJiInfo` (2 khung mỗi cái), `GetKfsSkill`, `GetKfsData`, `GetSectEquipSkill`, `GetZongMenTalentCoreData`/`NormalData`, `Lua_GetPowerValue`/`IsSetPower` (chân nguyên), `AskLevelupComboBook`/`AskDelComboBook` (bí tịch), `Lua_OpenRlOpPage` (lệnh bài, 4 khung).

**137 cái dùng chung** thì mỗi cái sửa một lần lợi cho cả client: `ScriptGlobal_Format` (999 khung), `PushEvent` (821), `SetText` (601), `SetProperty` (547), `SetActionItem` (417), `CreateActionItemForShow` (343), `CloseWindow` (322), `SetTimer`/`KillTimer` (268/264). Đây không phải việc của nhánh chỉ số — nhưng nó giải thích vì sao **mọi** khung CY đều "có mà không chạy", không riêng hệ sức mạnh.

⇒ Trả lời gọn cho câu hỏi của người dùng ("khung có mà chưa có chức năng"): **218/306 hàm host mà các khung sức mạnh gọi là hàm giả; 81 trong số đó là của riêng hệ sức mạnh.**

---

## 4. Ba phép đếm theo đúng cách

### 4.1 Handler gói: 195 `function request:` thật

`services/msgagent.lua` có **195** `function request:` (không phải 226 như phép đếm theo tên gói). Trong 20 gói của nhánh chỉ số, **19 có handler**; ngoại lệ:

> **`CGRongYu` (khai báo ở `services/game/packet_domains/core.lua:77`) KHÔNG có `function request:CGRongYu`.** Gói này tới server rồi rơi vào khoảng không. [DK] `handler-xscript.txt` mục A.

### 4.2 `Send_XSCRIPT`: 25 lời gọi, 2 đủ đường

Khung CY gọi `Clear_XSCRIPT(); Set_XSCRIPT_Function_Name("Ten"); Set_XSCRIPT_ScriptID(N); … Send_XSCRIPT()`.
(Bẫy: `Send_XSCRIPT()` **không mang tham số** — phải ghép `Set_XSCRIPT_Function_Name` với `Set_XSCRIPT_ScriptID` ngay sau nó.)

| Kết quả | Số |
|---|---|
| đủ cả whitelist + hàm thật | **2** (`XiulianStudy` → 2099 `AskXiuLianLevelUp`, `AskXiuLianAdvanceJingJie`) |
| thiếu hàm thật trong `Game_2/Script/scripts` | **23** |
| thiếu dòng whitelist | 22 |
| **chỉ thiếu dòng whitelist (hàm có sẵn)** | **0** |

11 script ID mà khung gọi: `800801, 892471, 998827, 998879, 890099, 790076, 889900, 889902, 889903, 998633, 880001` — **10 cái không có trong `scripts.lua`**; `889903` có nhưng trỏ tới `scripts.obj.item.charged_38000087` (script vật phẩm, không phải 真元), và `OnActivePneumaSlot` không tồn tại ở bất cứ đâu.
`892471 SuperWeaponDIYSkill_OpenUI` được **26 khung** gọi (7 trong nhánh này: SelfEquip, SelfData, Xiulian, JingMai, SelfMiji, Wuhun, ZhenYuan; còn lại là Pet, Ride, Packet, 4 khung Ngự Thú…) — một script thiếu làm hỏng nút "9 tinh thần khí" ở tất cả.

`AllowableScriptFunc.txt`: **GBK**, 2 dòng tiêu đề (`INT/INT/STRING`, `序号/脚本ID/函数名`), 753 dòng dữ liệu, 504 tên hàm khác nhau.

### 4.3 Bảng dữ liệu: server vs CY

`Build\Logs\2026-09-17-power-attrib\scripts\60-tables.sh` (số dòng kể cả tiêu đề):

| Bảng | Server | CY | |
|---|---|---|---|
| `XiuLianDetail` | 1965 | 2418 | thiếu phái 13–15 và cuốn 12–15 [SL theo menpai-audit mục 3] |
| `CharTitleNew` | 494 | 1188 | **195/492 dòng server có cặp IA/IV thật** |
| `CharTitle` | 247 | 432 | |
| `KFSSkillLevelup` | 278 | 296 | |
| `KFSAttrExBook` | 17 | 18 | |
| `KFSCompoudEx` | 11 | 12 | |
| `XinFaStudySpend_V1` | 304 | 304 | bằng nhau |
| `XiuLianBook`, `XiuLianMiJi`, `XueWeiBook`, `ComboSkillBook`, `ComboSkillRate`, `RefixComboSkill`, `TalentInfo`, `ZongmenTalent`, `RLSkillBook`, `LongWenAddAttr`, `zhenyuanpingfen`, 14 bảng `XingZhen*` | **không có** | có | |
| `CharTitleBoard` | không có | 318 | **KHÔNG phải bảng của server** — xem 4.4.2 |

### 4.4 Nhập danh hiệu CY (đã áp 17/09 20:07)

Công cụ: **`Tools\server\title_data.py plan | apply | verify`** (idempotent, sao lưu trước khi ghi, mức BYTE, chỉ THÊM).

#### 4.4.1 Bốn sự thật phải biết trước khi chạm vào bảng [DK]

1. **Bảng danh hiệu của CLIENT chính là bản CY.** `Assets\CanonicalCY\Data\ConfigFolder\CharTitleNew.txt` là DBC nhị phân `00CCBBDD`, **53 cột / 1186 bản ghi** — đúng bằng bản CY; server riêng chỉ có **492** dòng. `CharTitleBoard` client 318 = CY 318; `CharTitle` client 430 = CY 430. ⇒ **client và server đang lệch nghĩa ở phần lớn ID** từ trước lượt này.
2. **ID KHÔNG dùng chung.** 491 ID có ở cả hai bản, **0 dòng trùng**. Ví dụ ID 1043: server `一世有你`, CY `$N的宿敌`; ID 1079: server `独步天下·龙威`, CY `苦禅弟子`. Chỉ 84 danh hiệu trùng TÊN, và **80 trong số đó lệch ID**.
3. **Bố cục cột lệch đúng một chỗ: cột 8 và 9 đổi nhau.** Dòng kiểu: server `…7 STRING, 8 STRING, 9 INT…`, CY `…7 STRING, 8 INT, 9 STRING…`. Vân tay giá trị xác nhận (`scripts\77-find-ia-cols.py`): ở **cả hai** bản khối `(IA, IV)` nằm ở cột **13..22** (cột 23–52 luôn −1), và cột 10/11/12 cùng miền giá trị. ⇒ ánh xạ CY → server = **đổi chỗ cột 8 và 9**, mọi cột khác giữ nguyên. Không chế thêm số nào.
4. **`CharTitleBoard.txt` không phải bảng của server.** `grep` toàn bộ `GameServer` không có dòng nào đọc nó; `configenginer` chỉ nạp `char_title`, `char_title_new`, `pet_title`. Nó là bảng **client** (bảng ảnh danh hiệu, đúng như bộ nhớ `tlbb-title-add-pipeline`) và client **đã có đủ bản CY 318 bản ghi**. ⇒ **không nhập gì cho `CharTitleBoard`** — bỏ file đó vào `configs/` chỉ là rác.

#### 4.4.2 Kết quả [DK]

```
plan :  server 492 dòng  +  695 dòng CY chưa có  =  1187        (491 ID trùng: BỎ QUA, không đè)
        695 dòng thêm, trong đó 140 dòng có cặp (IA≥0, IV>0);  0 dòng sai số cột
apply:  backup configs/CharTitleNew.txt.bak-title-data-20260917T130709Z
        129 689 byte -> 310 238 byte
verify: 1187 dòng / 1187 ID duy nhất / 0 ID trùng / mọi dòng 53 cột / file vẫn giải mã GBK
        dòng tiêu đề không đổi (53, 53) | 335 dòng có IA/IV (trước 195) | 1186/1186 ID của CY đã có mặt | ok = true
apply lần hai: rows_to_add = 0  (idempotent)
```

Giá trị IA trong 695 dòng mới: `{0:128, 6:3, 8:1, 9:3, 11:1, 12:3, 14:1, 15:3, 17:1, 20:3, 27:3, 46:3, 48:126}`, IV lớn nhất 6000 — **đều nằm trong `define.ITEM_ATTRIBUTE` của server** (enum tới 165) và cùng họ với các dòng server đã có (`{0:99, 1:6, 6:78, 9:78, 12:78, 15:78, 35:13, 36:5, 37:6, 44:5, 46:4, 48:14}`). `IA 48 = IATTRIBUTE_ATTRIBUTE_ALL` được `cal_item_effect` xử lý riêng (cộng cả năm chỉ số gốc).

**Lợi ích thật:** 695 ID này trước đây có trên client mà server không biết; nay **client và server khớp thêm 695 ID**. 491 ID đang lệch thì không đụng tới (luật chỉ-thêm).

#### 4.4.3 Đo lại sau khi áp — **CHỜ RESTART**

`cfghelper:read_char_title_new` nạp bảng **một lần rồi cache**, nên bảng mới chỉ có hiệu lực sau lần restart kế tiếp (người điều phối giữ độc quyền restart; lúc áp là 20:07, server đang chạy từ 19:31:52).
Lệnh đo đã chuẩn bị sẵn, chạy ngay sau restart:

```powershell
wsl.exe -d TLBB -u root -- python3 -B Build/Logs/2026-09-17-power-attrib/scripts/31-set-title.py --guid 200011 --ids 1492 --apply
powershell -File Build\Logs\2026-09-17-power-attrib\scripts\40-run.ps1 -Label title-new-1 -BotArgs "--titles 1 --set-id-title 1492"
wsl.exe -d TLBB -u root -- python3 -B Build/Logs/2026-09-17-power-attrib/scripts/31-set-title.py --guid 200011 --ids "" --apply   # SAU phiên
```

Danh hiệu **1492 `悍武卓然·百战先锋（17）`** (Type 317) có `(IA 48, IV 60)` + `(IA 0, IV 6000)`.
**Kỳ vọng** trên CYTest10 nguyên trạng (`hp_max 2250`, `str 22 spr 22 con 20 int 11 dex 20`):
`hp_max 2250 → 8250` (+6000) và **năm chỉ số gốc mỗi cái +60** (`str 22 → 82`…), kéo theo att/def/hit/miss.
Nếu số không khớp thì hoặc bảng chưa nạp lại, hoặc ánh xạ cột sai — cả hai đều lộ ngay ở cặp số.

#### 4.4.4 BẪY phải sửa trước khi ai đó phát danh hiệu bằng GM tool

`human_attrib.lua:1880`:

```lua
local config = char_title_new[id]
for i = 1, 6 do
    local ia = config.IA[i]      -- KHONG co kiem tra nil cho `config`
```

Một dòng `id_titles` mang ID **không có trong bảng** làm `config` = nil ⇒ `attempt to index a nil value` ngay trong lần dựng lại thuộc tính ⇒ **nhân vật đó không đăng nhập được**. Trước lượt này client có 1186 ID còn server chỉ 492, nên rủi ro rất thật (GM tool phát theo ID của client). Đợt nhập vừa rồi đã lấp 695 ID, nhưng **vẫn nên thêm ba dòng chắn**:

```lua
local config = char_title_new[id]
if not config or not config.IA or not config.IV then goto continue end   -- hoac bao boc bang if config then ... end
```

Chưa vá vì `human_attrib.lua` là file dùng chung và cần một cửa sổ restart; ghi vào NEXT.

---

## 5. Công cụ mới

### 5.1 `CysNetBot` — nhóm cờ `attrib` (thẻ `// CYS-ATTRIB`)

`Src\Tools\CysNetBot\main.cpp`. Pha mới `Step::Attrib` chạy **Ask → Act → Verify**: hỏi `CGAskDetailAttrib`, chụp `GCDetailAttrib`, gửi gói của hệ, hỏi lại, chụp lần hai. Nhờ vậy mọi kết luận là **một cặp số**, không phải một mã trả về.

```
--attr-point S,SP,C,I,D   CGReqManualAttr 598   -> GCManualAttrResult 1031
--titles 0|1              CGCharAllTitles 1230  -> GCCharAllTitles 1227
--set-title ID            CGCharUpdateCurTitle 1192 (nhánh danh hiệu CHUỖI)
--set-id-title ID         CGCharUpdateCurTitle 1192 (nhánh CharTitleNew — nhánh có IA/IV)
--kfs OP[,A1,A2,A3]       CGKfsOperate 908      -> script 809270 OnAction
```

`result.json` thêm khối `attrib` với `before` / `after` là **hai ảnh chụp đầy đủ**: `point_remain`, `str/spr/con/int/dex`, 11 ô `xiulian_*`, `mind_attack/defend`, cộng `hp/hp_max/mp/mp_max/att_p/att_m/def_p/def_m/hit/miss`, và `xiulian_lists` / `xiulian_level_limit` giải mã `GCDetailXiulianList` 1014.
Bit cờ của `GCDetailAttrib` lấy từ `PgPackets_combat.cpp` (`point_remain` = byte 2 bit 4; `str/spr/con` = byte 1 bit 32/64/128; `int/dex` = byte 2 bit 1/2; `xiulian_*` = byte 3 bit 128 → byte 5 bit 2).

**Xây lại + bốn bộ kiểm** (17/09, sau khi thêm cờ):

| Bộ | Kết quả |
|---|---|
| build `power-attrib-x64` (`protocolgen;netcore;netbot`) | rc 0, 31/31 target, 0 lỗi (`build-1.log`, `build-2.log`) |
| protocol (`checks.ps1`) | **OK 1699/1699** frame trùng byte, 10,62 s |
| pathlib | **OK 418/418** `.path`, 0 crash, 2,25 s |
| scene | **OK 512/512** `.Scene`, 0 khoá lạ, 29,98 s |
| smoke | **OK 8/8** (OgreSmoke + M01/M09/M19/M25/M33 + 2 cảnh), 0 bad, 0 skipped |

(Ba bộ `checks` chạy trên **cây CI đã commit** `ace2d6c0` — `checks.ps1` tự chuyển sang bản committed, nên chúng là kiểm hồi quy của nhánh chính chứ không kiểm trực tiếp sửa đổi chưa commit của tôi. Sửa đổi của tôi chỉ nằm trong `cys_netbot`, không nằm trong bất kỳ target nào của bốn bộ đó.)

### 5.2 Script đo (trong `Build\Logs\2026-09-17-power-attrib\scripts\`)

| File | Việc |
|---|---|
| `30-char-power.py` | đọc/ghi ô sức mạnh trên Mongo (`dump`, `set-point`, `set-xiulian`, `set-jingmai`, `unset`); mặc định CHỈ ĐỌC, mọi lệnh ghi đòi `--apply`, chỉ chạm GUID 200001–200016 |
| `31-set-title.py` | đặt/xoá `id_titles` |
| `32-set-money.py` | đặt `attrib.money` |
| `39-restore.py` | trả nhân vật về nguyên trạng |
| `40-run.ps1` | một phiên bot: khoá `Build\test10.lock` → mốc log server → bot → in cặp số |
| `50-frame-host-status.py` | khung ↔ hàm host thật/stub/thiếu |
| `60/61/62/63/64` `.sh` | khảo sát bảng + mã server |
| `67-title-rows.py` | tìm dòng `CharTitleNew` thật sự cộng chỉ số |
| `70-handler-and-xscript.py` | đếm `function request:` và kiểm `Send_XSCRIPT` |

---

## 6. Bẫy đã sập trong lượt này

1. **Điểm tiềm năng và năm chỉ số gốc KHÔNG nằm trong `attrib`.** Chúng ở document cấp cao **`lv1_attrib`** (`human_attrib:get_lv1_attrib` → `self.lv1_attribs`). Ghi `attrib.point_remain` là vô tác dụng. (Khác với `xiulian_*`, vốn nằm trong `attrib` vì thuộc `db_attribs` + `db_save_attribs`.)
2. **Tra bảng trước khi đặt thẳng một chỉ số** (bẫy người điều phối đã gửi). Đã kiểm trước khi ghi: `point_remain/str/spr/con/int/dex` ∈ `lv1_attribs`; `xiulian_*` ∈ `db_attribs`; `money` ∈ `db_attribs` (dòng 392); `jingmai_attr_bonus`/`gm_attr_bonus` đọc thẳng từ `db_attribs` trong `on_attrib_rebuild`. Không đụng `menpai_attribs`.
3. **Phiên bot GHI ĐÈ bản ghi Mongo khi thoát.** Xoá `id_titles` *trước* một phiên nữa thì phiên đó ghi 1043 trở lại. Mọi lệnh dọn dẹp phải chạy **sau** phiên cuối. (Cùng loại bẫy với menpai-audit mục 5.)
4. **`Send_XSCRIPT()` không mang tham số.** Regex bắt `Send_XSCRIPT(script, "func")` cho kết quả rác (6 "tên hàm" bịa như `equip`, `packageitem`). Phải ghép `Set_XSCRIPT_Function_Name` + `Set_XSCRIPT_ScriptID`.
5. **Đếm stub chỉ trên `LuaApiGen` là nói quá.** `IsMissing()` cho bản thật của 0.85 thắng ⇒ phải gộp `Src\Client\WXClient\Script` + `Interface`. Sai số của phép đếm đầu: 104 → **748** hàm thật.
6. **Cửa sổ tu luyện không đổi chỉ số ≠ hỏng.** `ceil(val × 0,5/100 × 加成 × 2)` làm tròn về 1 cho cả bốn cấp đầu ở nhân vật cấp 15.
7. **Từ Git Bash, `wsl.exe` bị MSYS đổi đường dẫn** (`/home/...` → `C:/Program Files/Git/home/...`) kể cả khi có `MSYS_NO_PATHCONV=1` và kể cả trong nháy đơn. Mọi lệnh `wsl.exe` trong lượt này chạy qua **PowerShell**.
8. **`.local\test-accounts.txt`**: bot đọc mật khẩu từ biến môi trường `CYS_BOT_PWD`; script phải nạp đúng dòng tài khoản và `Remove-Item Env:CYS_BOT_PWD` khi xong (đã làm trong `40-run.ps1`).

---

## 7. VIỆC TIẾP THEO, xếp theo "rẻ và thấy ngay"

0. **NGAY SAU RESTART: đo danh hiệu mới 1492** — ba lệnh ở 4.4.3. Đây là bước còn thiếu để đợt nhập danh hiệu không dừng ở "đã nhập 695 dòng".
1. **`SendAskStudyXinfa` (stub → thật).** Server đã chứng minh chạy (2.3) và chi phí client đã đúng từ 16/09; chỉ còn hàm host — hiện nút học tâm pháp **không gửi gói nào**. **Một hàm host, nửa ngày.**
2. **`Player:GetXiuLianBookInfo` / `GetXiuLianMiJiInfo` (stub → thật).** Mở `XiuLianDetail` (đã có trên client? cần kiểm DBC) để cửa sổ tu luyện hiện đúng chi phí và bỏ chặn nhầm nút thăng cảnh giới. **1 ngày.**
3. **Chắn nil cho `title_new_effect_flush`** (`human_attrib.lua:1880`, 4.4.4): một ID danh hiệu lạ hiện làm **nhân vật không đăng nhập được**. **Ba dòng, cần cửa sổ restart.**
4. **`CGRongYu` không có handler** — quyết định: viết handler hay bỏ gói. **1 giờ để kết luận.**
5. **Kinh mạch**: nhập `XueWeiBook` (CY 23) + viết script CY ghi `jingmai_attr_bonus` + bỏ chú thích `jingmaienginer:loadall()`. Cơ chế áp dụng đã chạy sẵn (2.5) nên phần còn lại chỉ là "ai ghi". **2–3 ngày.**
6. **Võ hồn**: phát một võ hồn vào túi test10 rồi đo `--kfs`. Dữ liệu đã đủ; chỉ chưa ai bấm. **Nửa ngày.**
6b. **`CharTitle.txt`** (245 dòng server / 430 CY, và **43 cột server vs 50 cột CY**): chưa nhập vì số cột khác nhau nên chưa có ánh xạ chứng minh được — khác `CharTitleNew` vốn chỉ lệch một cặp cột. Cần dựng vân tay cột như 4.4.1 mục 3 trước khi đụng vào.
7. **Chân nguyên / lệnh bài / long văn / bí tịch / tinh trận**: mỗi hệ cần cả bảng lẫn script server. Đây là việc "làm mới", không phải "sửa", nên để sau khi người dùng chọn hệ nào đáng làm trước.
8. **Tu luyện 15 cuốn**: chặn cứng ở **bố cục gói 1014 (11 ô)**. Muốn lên 15 phải đổi cả `GCDetailXiulianList` phía server và phía client cùng lượt — đúng như quyết định 16/09 "để sau".
