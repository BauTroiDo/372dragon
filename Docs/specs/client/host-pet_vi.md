# Hàm host của khung TRÂN THÚ (珍兽) — host-pet, 17/09/2026

Đặc tả này nói về các hàm host C++ mà **giao diện Lua nguyên bản của CY 3.71** gọi trong 17 thư mục
`Pet*` được giao, và về 7 hàm đã được cài thật trong lượt này.

- Mã mới: `Src/Client/LuaApiGen/CysHost_Pet.{h,cpp}` (glue Lua) và
  `Src/Client/WXClient/Network/CysPetNet.{h,cpp}` (tầng game).
- Bằng chứng: `Build/Logs/2026-09-17-host-pet/` (phép đếm, build, đo live) và
  `Build/re/host-pet/` (dịch ngược CHỈ ĐỌC từ `Game.exe` của B).
- Không sửa `C:\TLBB\085\client`, không sửa `client_GL`, không commit, không restart server riêng.

---

## 1. Phép đếm (đo lại từ đầu, không dùng số của đề bài)

Script: `Build/Logs/2026-09-17-host-pet/scripts/10-scan-pet.py` (kết quả `scan-after.txt`),
`20-rank.py` (bảng xếp hạng `rank-pet-before.tsv`).

Cách đếm — hai bẫy của đề bài đều đã tránh:

1. Regex lời gọi là `([A-Za-z_]\w*)\s*:\s*([A-Za-z_]\w*)\s*\(` — **có `\s*` hai bên dấu hai chấm**, nên
   `Pet : SetPetLocation( Index_Pet, -1 )` (PetNeidan_Lianhua.lua:111) được đếm đúng, và `this : Func(`
   bị loại đúng (là phương thức widget CEGUI, không phải receiver toàn cục).
   Bộ lọc receiver: chỉ nhận tên nằm trong danh sách receiver của `LuaApiGen_*.cpp` + danh sách
   `SCRIPT_SANDBOX::<X>::s_pMetaTable` / `metatable_*` của `GMScriptSystm.cpp`; loại `this`, `self` và
   mọi biến `local` khai báo trong chính file đó.
2. Cột "đã có thật" quét **cả ba** nguồn: `SCRIPT_SANDBOX::*::s_pMetaTable->RegisterObjectFunctor` của
   0.85, bảng `{"Receiver","Name",Fn}` trong `Src/Client/LuaApiGen/CysHost_*.cpp` **và**
   `Src/Client/WXClient/Network/Cys*Net.cpp`. Thiếu nguồn thứ ba là đếm nhầm (ví dụ `Pet:GetIsBaiShou`
   và `DataPool:Lua_IsMissionHaveDone` đã có thật trong `CysHost_Package.cpp`).

### 1.1 Kết quả (17 thư mục: Pet, PetList, PetFrame, PetSkillStudy, PetStudyNewSkill, PetNeidan, PetLevelup, PetIdentify, PetSavvy, PetZhuanXing, PetXingGe, PetShelizi, PetLianHua, PetHuanhua, PetBankMain, PetBankList, PetProcreate)

| | số hàm | số lời gọi |
|---|---|---|
| Tổng (receiver, name) duy nhất | **213** | **927** |
| Đã có thật TRƯỚC lượt này | 68 | 442 |
| **Stub TRƯỚC lượt này** | **145** | **485** |
| — riêng hệ trân thú | 136 | 460 |
| — 9 hàm "đuôi dùng chung" (của `host-plumbing`) | 9 | 25 |
| Đã cài thật trong lượt này | **7** | **99** |
| Stub còn lại SAU lượt này | 138 | 386 |

Số của đề bài (72 gọi / 5 thật / 67 stub, 57 riêng hệ) **không khớp**: phép đếm này lớn hơn nhiều vì nó
tính cả các receiver dùng chung xuất hiện trong khung trân thú (`Player`, `DataPool`, `PlayerPackage`,
`LifeAbility`, `Target`, `Bank`, `SystemSetup`) chứ không chỉ receiver `Pet`. Phân bố stub riêng hệ theo
receiver: `Pet` 97, `DataPool` 22, `PlayerPackage` 7, `Player` 3, `LifeAbility` 3, `SystemSetup` 2,
`Target` 1, `Bank` 1.

Đính chính phạm vi: 4 hàm `Pet:GetPetFightAction / GetPetRelaxAction / GetPetPossessionAction /
GetPetRestoreAction` **bị gọi trong MỌI phiên chơi** (thấy trong `WXClient.log` của mọi lần chạy GUI) nhưng
nằm ở `CommonSkill/CommonSkill.lua`, **ngoài** 17 thư mục được giao — không thuộc nhóm này.

### 1.2 Xếp hạng `[DK]` (dịch ngược được) và `[SL]` (phải suy luận)

`catalog.json` chỉ phủ binary GL/0.85. 80/136 hàm riêng hệ có `impl_va` trong `Game.exe` của B
(**[DK]**, 319 lời gọi); 56 hàm còn lại (**[SL]**, 141 lời gọi) đến từ `LuaApiGen_Cy.cpp`, sinh từ **lời
gọi của script CY** chứ không từ binary, nên **không có địa chỉ để dịch ngược** — không phải "tìm không
ra". 20 dòng đầu của nhóm [DK] (bảng đầy đủ: `rank-pet-before.tsv`):

| # | hàm | gọi | file | impl_va | trạng thái sau lượt này |
|---|---|---|---|---|---|
| 1 | `Pet:SetPetLocation` | 47 | 10 | 0x2b5080 | **ĐÃ CÀI** |
| 2 | `Pet:GetPetLocation` | 23 | 11 | 0x2b5120 | **ĐÃ CÀI** |
| 3 | `PlayerPackage:IsPetLock` | 15 | 10 | 0x2a6a90 | để stub (ô B-only) |
| 4 | `Pet:GetIsPossession` | 14 | 4 | 0x2b2170 | để stub (0.85 không có "phụ thể") |
| 5 | `DataPool:GetLeftProtectTime` | 13 | 9 | 0x26d4d0 | **ĐÃ CÀI** |
| 6 | `Pet:GetData` | 12 | 1 | 0x2bb530 | để stub (ô B-only) |
| 7 | `Pet:GetTakeLevel` | 10 | 5 | 0x2b5850 | để stub (helper chưa lần ra) |
| 8 | `Pet:ClosePetSkillStudyMsgBox` | 9 | 2 | 0x2ba610 | để stub (ID sự kiện CY) |
| 9 | `Pet:GetSavvy` | 9 | 5 | 0x2b5a10 | để stub (ô B-only) |
| 10 | `Pet:GetSkillIDbyIndex` | 9 | 1 | 0x2b2560 | để stub |
| 11 | `Pet:GetPetSkillLevelupInfo` | 8 | 1 | 0x2baee0 | để stub |
| 12 | `Pet:UpdatePetList` | 7 | 3 | 0x2bc8b0 | **ĐÃ CÀI** |
| 13 | `Pet:IsPetHaveEquip` | 6 | 5 | 0x2bb490 | để stub |
| 14 | `Pet:SetSelectPetIdx` | 6 | 1 | 0x2b8fc0 | để stub (4 con trỏ B-only) |
| 15 | `PlayerPackage:FindFirstBindedItemIdxByIDTable` | 6 | 2 | 0x2a7650 | ngoài phạm vi (túi đồ) |
| 16 | `PlayerPackage:GetItemTableIndex` | 6 | 4 | 0x2a6db0 | ngoài phạm vi (túi đồ) |
| 17 | `LifeAbility:CloseReIdentifyMsgBox` | 5 | 1 | 0x29d540 | để stub (ID sự kiện CY) |
| 18 | `Pet:GetPetList_Appoint_PetBank` | 5 | 1 | 0x2bd270 | để stub (kho trân thú B-only) |
| 19 | `Pet:PetBank_PetListSelectChange` | 5 | 2 | 0x2bdac0 | để stub (kho trân thú B-only) |
| 20 | `Pet:GetPetIndexByGUID` | 4 | 3 | 0x2ae270 | **ĐÃ CÀI** |

Nhóm [SL] đầu bảng — `Pet:GetPetCangpinEffectValue` (18), `Pet:GetPetMasterTotalEffectValue` (14),
`Player:IsPetMasterEffectActive` (14), `DataPool:LuaFnGetCangPinSetEffectLevel` (5) — thuộc hệ **藏品**
và **珍兽大师** của CY, server riêng **không có gì để trả lời**. Không cài.

---

## 2. Bản đồ bố trí bản ghi trân thú của B (nền của mọi kết luận bên dưới)

Cách lấy: dịch ngược 28 hàm host trân thú **đã có thật trong mã 0.85** rồi đối chiếu ô số nguyên mà B đọc
với trường mà mã 0.85 đẩy lên Lua (`Build/re/host-pet/decomp-calib.c`). Ba hàm neo đầu tiên cố định phần
đầu struct: `Pet:GetName` đọc `[5]` + chuỗi ở `+0x20` (dung lượng ở `[0xe]`), `Pet:IsPresent` đọc `[0]`,
`[2]`, `[3]`, `[5]`; `Pet:GetGUID` đẩy `[2]` rồi `[3]` đúng thứ tự 0.85 đẩy `m_uHighSection` rồi
`m_uLowSection`.

| ô int của B | offset | trường 0.85 (`SDATA_PET`) | hàm B dùng để xác định |
|---|---|---|---|
| `[0]` | 0x00 | `m_nIsPresent` | IsPresent |
| `[2]`,`[3]` | 0x08 | `m_GUID` (high, low) | GetGUID |
| `[5]` | 0x14 | `m_nDataID` | GetName |
| `[7]` | 0x1C | `m_nAIType` | GetAIType |
| `[8..0xf]` | 0x20 | `m_szName` (std::string) | GetName |
| `[0x10]` | 0x40 | `m_nLevel` | GetLevel |
| `[0x12]` | 0x48 | `m_nExp` | GetExp |
| `[0x13]`,`[0x14]` | 0x4C | `m_nHP`, `m_nHPMax` | GetHP / GetMaxHP |
| `[0x17]` | 0x5C | `m_nAge` | GetNaturalLife |
| **`[0x18]`** | 0x60 | **`m_nEraCount`** | **GetType** (0.85 `Pet::GetType` đẩy `m_nEraCount`) |
| `[0x19]` | 0x64 | `m_nHappiness` | GetHappy |
| `[0x1e..0x21]` | 0x78 | `m_nAttPhysics/AttMagic/DefPhysics/DefMagic` | GetPhysicsAttack… |
| `[0x22]`,`[0x23]` | 0x88 | `m_nHit`, `m_nMiss` | GetShootProbability / GetMiss |
| `[0x33..0x37]` | 0xCC | 5 tư chất | GetStrAptitude… |
| `[0x3d..0x41]` | 0xF4 | `m_nAttrStr/Spr/Dex/Int/Con` | GetStr… |
| `[0x42]` | 0x108 | `m_nBasic` | GetBasic |
| `[0x44]` | 0x110 | `m_nPot` | GetPotential |

**Kết luận quan trọng:** bản ghi trân thú của B **dài hơn** 0.85 (0.85 kết thúc ở 0xD8) và **chèn thêm ô ở
giữa**, nên **không được** suy offset của 0.85 cho những ô B đọc mà 0.85 không có tên. Các ô B-only đã gặp:
`[0x24]`/`[0x25]` (GetCriticalAttack / GetCriticalDefence), `[0x26]` (GetAttackTrait), `[0x43]` (GetSavvy),
`[0x45]` (GetGrowRate, đọc như float rồi ×1000), `[0x46]`/`[0x48]` (khoá trân thú), **`[0x47]` (vị trí)**,
`[0x50..0x52]` (vector danh hiệu), `[0x5f]` (byte GetPetType), `[0x11]` (GetLastProcreateLevel).

---

## 3. Bảy hàm đã cài — nguồn của từng hàm

### 3.1 `Pet:SetPetLocation(index, location)` và `Pet:GetPetLocation(index)` — 70 lời gọi

`Build/re/luaapi/decomp/Game.exe/1402b5080.c` và `1402b5120.c`. Toàn bộ thân hàm của B:

```
pet = Pet_GetPet((int)lua_tonumber(L,2));
if (pet && pet->[0] != -1) pet->[0x47] = (int)lua_tonumber(L,3);   // Set, không trả gì
...
if (pet && pet->[0] != -1) { lua_pushnumber(L, pet->[0x47]); return 1; }  // Get
```

Không gói tin, không sự kiện, không bảng: đây là **một ô đánh dấu thuần client**, "con trân thú này đang bị
cửa sổ nào dùng". Các mã cửa sổ mà script CY ghi vào: `-1` rảnh, `1` PetLevelup, `2`/`21` PetNeidan_Lianhua,
`3` PetSavvyGGD, `5` PetHuanhua/PetLianHua, `7` MissionReply, `10` PetLingXingUp, `12` PetSavvy,
`16` PetProcreate, `17` PetRHD, `18` PetChangeModel (Pet.lua:1975-1979, PetProcreate.lua:41 …).

`SDATA_PET` của 0.85 không có ô này. Đã giữ ô đánh dấu trong `CysPetNet.cpp` (mảng theo slot), **kèm GUID
của con trân thú lúc ghi**: nếu slot bị dọn hoặc bị con khác chiếm (GCRemovePet / GCNewPet) thì đọc ra `-1`.
Đây là chỗ **khác B một cách có chủ đích** và an toàn hơn — script CY chỉ so kết quả với `-1`.

Khác biệt thứ hai, cũng có chủ đích: khi slot trống, B **ném lỗi Lua**; ở đây trả `-1`. Lý do: giá trị 0 mà
stub trả về làm mọi cửa sổ tưởng con trân thú **đang bận** (`0 ~= -1` là đúng), còn ném lỗi thì cắt đứt chuỗi
gọi Lua. `-1` là câu trả lời đúng nghĩa "không bận".

### 3.2 `Pet:UpdatePetList()` — 7 lời gọi

B: `CEventSystem::PushEvent(0xe8)` (RVA 0x2bc8b0), không làm gì khác.

Bảng sự kiện của B **không trùng** bảng của 0.85 trên toàn dải (`_G:TogglePetPage` lệch +5,
`Pet:ShowTargetPet` lệch −258), nhưng **khối trân thú/túi đồ lệch đúng +27**, neo ba lần bằng những hàm mà
mã 0.85 có sẵn:

| hàm B | sự kiện B | sự kiện 0.85 | lệch |
|---|---|---|---|
| `Pet:ShowPetList(show>0)` | 0xe5 | `GE_OPEN_PET_LIST` 0xca | +27 |
| `Pet:ShowPetList(show<=0)` | 0xe7 | `GE_CLOSE_PET_LIST` 0xcc | +27 |
| `PlayerPackage:OpenLockFrame` | 0xec | `GE_OPEN_ITEM_COFFER` 0xd1 | +27 |

⇒ `0xe8 − 27 = 0xcd = GE_UPDATE_PET_LIST`, mà chú thích trong `TDEventDefine.h` viết đúng là
"更新宠物列表界面", và `PetList.lua:19` đăng ký `this:RegisterEvent("UPDATE_PET_LIST", false)` rồi dựng lại
danh sách ở dòng 76. Ba chứng cứ độc lập (số, tên, người nghe) cùng chỉ một kết quả.

### 3.3 `Pet:GetPetIndexByGUID(high, low)` — 4 lời gọi

B (RVA 0x2ae270): `Pet_GetPetByGuid(PET_GUID_t{ [0] = arg1, [4] = arg2 })`, đẩy kết quả là số.
`FUN_1401437b0` là `CDataPool::Pet_GetPetByGuid`: ba hàm `1401437b0 / 1401437f0 / 140143810` nằm liền nhau
đúng thứ tự khai báo trong `GMDataPool.h:520-522` (`Pet_GetPetByGuid` / `Pet_GetPet(INT)` /
`Pet_GetPet(PET_GUID_t)`), và `1401437f0` chính là hàm mọi getter trân thú của B gọi.
Thứ tự tham số: `PET_GUID_t` có `m_uHighSection` ở offset 0 nên **arg1 = high, arg2 = low** — khớp với
`Pet:GetGUID` (đẩy high rồi low) và với call site `Pet:GetPetIndexByGUID(mainPet.guid.high, mainPet.guid.low)`
(PetSavvy.lua:426, PetRHD.lua:508, PetPropagateSingle.lua:564, PetLianHua.lua:378).
0.85 `Pet_GetPetByGuid` trả `-1` khi không tìm thấy, đúng cái script CY so sánh.

### 3.4 `Player:IsHaveCurrentPet()` — 4 lời gọi

B (RVA 0x2dca90):
```
guid = MySelf->GetCharacterData()->Get_CurrentPetGUID();     // FUN_1401a4b40
pet  = Pet_GetPet(guid);                                     // FUN_140143810
push(pet != 0 && pet->[0] != -1);
```
Cặp accessor này y hệt cặp mà `Pet::GetIsFighting` của 0.85 dùng
(`GMGameInterface_Script_Pet.cpp:1197`). Port nguyên văn.

### 3.5 `Pet:GetGeneration(index)` — 1 lời gọi

B (RVA 0x2bc6f0) đọc `[0x18]` — **đúng ô mà `Pet:GetType` của B (RVA 0x2b03d0) đọc**, và
`Pet::GetType` của 0.85 đẩy `m_nEraCount` (几代宠). Vậy `GetGeneration = m_nEraCount`.

**Lưu ý trung thực:** gói `GCDetailAttrib_Pet` phiên bản CY mà server riêng gửi
(`Src/Shared/ProtocolGen/PgPackets_pet_detail_types.h`) **không có trường generation**, nên
`m_nEraCount` ở client hiện giữ `-1` và hàm luôn trả `-1`. Script chỉ kiểm `nGeneration >= 100`
(Pet.lua:1036) nên hành vi đúng; nhưng đây là "đúng công thức, chưa có dữ liệu", không phải "đã đo được".

### 3.6 `DataPool:GetLeftProtectTime()` — 13 lời gọi

Thân hàm của B (RVA 0x26d4d0) **chỉ có hai dòng**: `lua_pushnumber(L, 0.0); return 1;` — bộ đếm thời gian
bảo vệ chống trộm tài khoản đã bị cắt khỏi client. Pet.lua 1838/2031/2928 chặn "thả / mở khoá trân thú" khi
`> 0`, nên `0` = cho phép. Cài để biến một ô "chưa biết" thành "đã chứng minh" (stub cũng trả 0, nên hành vi
không đổi — giá trị nằm ở chỗ nó hết là ẩn số và hết ghi log).

---

## 4. Vì sao KHÔNG cài những hàm còn lại (nêu rõ từng lý do)

| nhóm | số hàm | số lời gọi | lý do |
|---|---|---|---|
| Ô B-only trong bản ghi trân thú | ~14 | ~60 | `GetSavvy [0x43]`, `GetGrowRate [0x45]`, `GetTitleNum [0x50..0x52]`, `GetPetType [0x5f]`, `GetCriticalAttack/Defence [0x24]/[0x25]`, `GetAttackTrait [0x26]`, `GetLastProcreateLevel [0x11]`, `IsPetLock`/`GetPUnlockElapsedTime_Pet` `[0x46]`/`[0x48]` … — `SDATA_PET` của 0.85 không có ô, và gói CY hiện không được client đọc vào đâu cả |
| Kho trân thú (`*_PetBank`) | 12 | 30 | B có `PetBank_GetPet` / `PetBank_GetCount` (`FUN_140029710/140029800/1400298e0/14002a6e0`) — **cả một hệ thống dữ liệu client mà 0.85 không có** |
| Sự kiện CY chưa giải mã | 9 | ~21 | `ClosePetSkillStudyMsgBox` 0x218, `OpenPetSkillStudyMsgBox` 0x217, `CloseReIdentifyMsgBox` 0x1e8, `NotifySelChange` 0x1d4, `NotifyPetDlgClosed` 0x1d5, `PetOpenTitleList` 0x1cf, `CloseSignalPetProCreate` 0x29f, `ShowBagSelectPet_PetBank` 0x386, `OpenPetEquipReIdentifyMsgBox` 0x26f — **không có điểm neo nào của 0.85 trong dải 0x1cf–0x386**, mà độ lệch của bảng sự kiện B **không phải hằng số** (đã kiểm: +5, +27, −258 ở ba dải khác nhau) |
| "Phụ thể" (`GetIsPossession`, `PossessionPet`, `RestorePet`) | 3 | 16 | B đọc GUID trân thú phụ thể qua `FUN_1401a4e50`; `CCharacterData` của 0.85 **chỉ có** `Get_CurrentPetGUID` |
| Hệ chỉ có ở CY ([SL]) | 56 | 141 | 藏品 / 珍兽大师 / 内丹 / 幻灵 / 进阶 — `LuaApiGen_Cy.cpp`, **không có `impl_va`**, và server riêng cũng không có chuỗi trả lời |
| 9 hàm "đuôi dùng chung" | 9 | 25 | thuộc `host-plumbing` |
| Ngoài phạm vi (túi đồ / mục tiêu / ngân hàng) | 6 | 24 | `PlayerPackage:*`, `Target:GetServerId2ClientId`, `Bank:GetNpcId`, `SystemSetup:OpenPrivatePage` |

Hai trường hợp **cố tình không đoán** dù rất gần:

- `Pet:SetSkillLevelupModel` (0x2b24d0) gọi `FUN_140145f80(DataPool, dataID)` và
  `Pet:SetStudyNewSkillModel` (0x2bb100) gọi `FUN_140145fc0`, trong khi
  `Pet:SetSkillStudyModel` (đã có thật trong 0.85) gọi `FUN_140145f40` =
  `CDataPool::PetStudySkill_SetPetModel`. Ba hàm liền kề = **ba ô fake-object khác nhau**; 0.85 chỉ có
  một. Ánh xạ cả ba về cùng một ô sẽ đặt model vào **sai cửa sổ xem trước 3D**.
- `Pet:GetFoodType` (0x2b4fd0) gọi `FUN_1401c3a80`, hàm này tra DBC id `0x70` rồi lấy ô ở byte `+0x24`
  của bản ghi. 0.85 có sẵn `CDataPool::Pet_GetPetFoodType` đọc `DBC_PET_EX_ATT` cột `m_FoodType`, nhưng
  trong bố trí CY 54 cột hiện tại `+0x24` rơi vào `m_Reserve2` (是否宝宝) chứ **không** phải `m_FoodType`
  (`+0x28`), và id `0x70` ≠ `DBC_PET_EX_ATT` (202). Chưa khớp ⇒ giữ stub. 1 lời gọi.

---

## 5. NÚT THẮT THẬT SỰ CỦA KHUNG TRÂN THÚ (đo được trong phiên live)

`WXClient.log` của cả hai phiên live ghi:

```
[17_22:26:29]: CYS world: first unhandled GC id=512
```

`512 = GCDetailAttrib_Pet` (`Src/Shared/ProtocolGen/PgIds.h:206`,
`PgFactoryTable.cpp:219` "pet_detail_types", DecPartial). Nghĩa là: **server riêng CÓ gửi chi tiết trân thú
khi vào thế giới, bộ giải mã ProtocolGen CÓ đọc được, nhưng client KHÔNG có handler nào cho gói đó** —
không có dòng nào trong `Src/Client/WXClient/Network/` đụng tới `GCDetailAttrib_Pet` / id 512
(`CysModernHandlers.cpp` không liệt kê nó). Handler 0.85 `GCDetailAttrib_PetHandler.cpp` chỉ chạy cho lớp
gói 0.85 cũ, không phải cho gói CY.

Hệ quả: `CDataPool` **không bao giờ được nạp danh sách trân thú trong túi**, nên `Pet:GetPet_Count()`,
`Pet:IsPresent(i)`, `Pet:GetLevel(i)` … của **chính mã 0.85 đã có sẵn** cũng trả 0 / false. Cài thêm hàm
host cho khung trân thú **không giúp gì** cho đến khi gói 512 được nối vào `SDATA_PET`.
(Triệu hồi trân thú ra thế giới vẫn chạy vì nó đi bằng `GCNewPet`, một gói khác, đã có handler.)

⇒ **Việc số 1 của người làm tiếp là viết handler cho GC 512**, không phải cài thêm hàm host.

## 5b. Cơ hội kế tiếp (đã tìm ra, chưa làm)

Server riêng **đã gửi** các ô CY mà khung trân thú cần, và
`Src/Shared/ProtocolGen/PgPackets_pet_detail_types.h` **đã giải mã chúng**, nhưng **không có dòng nào trong
`Src/Client` đọc tới**:

| ô của gói CY | dòng trong spec | hàm host đang là stub vì thiếu nó |
|---|---|---|
| `lingxing` (u8) | L854 | `Pet:GetLixing` (2 lời gọi) |
| `mind_attack` (u32) | L878 | `Pet:GetCriticalAttack` (2) |
| `mind_defend` (u32) | L881 | `Pet:GetCriticalDefence` (2) |
| `gengu` (u32) | L938 | ứng viên cho `Pet:GetSavvy` (9) — **chưa xác minh** |
| `titles` (10×i32) | L1064 | `Pet:GetTitleNum` (3) |

Nguồn phía server: `GameServer/lualib/db/pet_detail.lua:824 calculate_pet_detail_attrib` gọi
`set_lingxing`, `set_mind_attack`, `set_mind_defend`, `set_titles`, `set_gengu`.

Việc cần làm: thêm ô vào `SDATA_PET` (`GMDP_Struct_Pet.h`) + gán trong đường dịch gói CY → gói 0.85 + thêm
hàm host. Tổng cộng khoảng 9 lời gọi cho `lingxing`/`mind_*`/`titles` — **chưa làm trong lượt này vì phải
sửa hai file dùng chung (`GMDP_Struct_Pet.h` và `GCDetailAttrib_PetHandler.cpp`) trong lúc 7 agent khác
đang sửa cùng cây**, và `gengu → savvy` vẫn còn là suy đoán.

---

## 6. Đo LIVE (client thật + server riêng 15733/15734)

Tài khoản **test14 / nhân vật `CYTest14` (GUID 200015)** — đây là nhân vật test **duy nhất có trân thú thật**
(3 con: 兔子宝宝 3009, 飘飘鸭 558 ×2, theo `Build\Logs\2026-09-17-pets-wild\char\pet-mongo-final.json`).
`test00` không có trân thú nên không đo được `GetPetLocation` / `GetGeneration`.

| lần chạy | kết quả |
|---|---|
| `live-1` (22:22) | `PASS World`, `run.json passed=true`; **`CYS-PET: host functions registered=7 (Pet / PetList / PetBank windows)`** ở dòng 287 của `WXClient.log`, ngay sau `CYS inv: 71`, `CYS quest: 23`, `CYS skill: 4`, `CYS power: 3` |
| `live-2` (22:26) | `PASS World`, `passed=true`, `exit_code=0`, `elapsed_s=99`, `login_failed=false`, 16/16 check của bộ smoke; lại `CYS-PET: host functions registered=7` |

Trong cả hai phiên, **không có dòng `missing host function` nào** thuộc 7 hàm này (84 dòng
`missing host function` của phiên, không dòng nào là `Pet:` / `Player:IsHaveCurrentPet` /
`DataPool:GetLeftProtectTime`). Lưu ý trung thực: lượt chạy tự động **không mở cửa sổ trân thú**, nên việc
"không có dòng" chưa đủ mạnh — bằng chứng mạnh là `registered=7` cộng với phép đo giá trị dưới đây.

### 6.1 Dụng cụ đo — hai lần thử

**Thử 1 (THẤT BẠI, ghi lại để khỏi lặp):** chép `PetFrame.lua` vào
`stage-host-pet\Overlay\Pre\InterfaceFolder\PetFrame\` kèm đoạn gọi 7 hàm rồi ghi file bằng `io.open`.
Layout `PetFrame/PetFrame.layout.xml` nạp đúng (UISystem.log dòng 4937) nhưng đoạn thêm **không chạy một
lần nào** trong cả hai phiên. Nguyên nhân: script của cửa sổ **không** nạp theo đường dẫn thư mục mà qua
`CScriptEnvironment::DoFile(pLayoutDef->szScript)` →
`CGameProcedure::s_pResourceProvider->loadResource(szScript, ..., "General")`, với `szScript` lấy từ **cột
`szScript` của bảng DBC Layout** (`TDDBC_Struct.h:1089`) — `Overlay/Pre` không chen được vào đó. Đã gỡ bản
overlay đi để stage sạch.

**Thử 2 (dùng được):** `CYS_PET_PROBE=1` trong `CysPetNet.cpp`, đúng khuôn `CYS_POWER_PROBE` sẵn có của
`CysPowerNet.cpp`. Nó đăng ký `Pet:CysPetProbeLog` (**chỉ khi biến môi trường bật**) rồi `DoString` một
đoạn Lua tự hẹn `SetTimer` 3 s: mỗi nhịp gọi cả 7 hàm **qua đúng ngăn xếp Lua, đúng receiver, đúng thứ
tự tham số** cho 6 slot và ghi giá trị trả về ra `WXClient.log` bằng tiền tố `CYS-PET probe:`.

### 6.2 Kết quả `live-3` (22:38, `passed=true`, `exit_code=0`, `elapsed_s=101.1`, 0 check hỏng)

19 nhịp dò, **giá trị giống nhau ở cả 19 nhịp**:

```
CYS-PET: host functions registered=7 (Pet / PetList / PetBank windows)
CYS-PET probe: armed (CYS_PET_PROBE=1), first tick in 3000 ms
CYS world: first unhandled GC id=512
CYS-PET probe: run=1 Pet:GetPet_Count()=0 DataPool:GetLeftProtectTime()=0
               Player:IsHaveCurrentPet()=false Pet:GetPetIndexByGUID(0,0)=-1
CYS-PET probe: run=1 Pet:UpdatePetList() returned without a lua error
CYS-PET probe: slot 0..5 empty loc=-1
```

| hàm | giá trị đo | nhận xét |
|---|---|---|
| `DataPool:GetLeftProtectTime()` | `0` | khớp từng chữ với thân hàm của B |
| `Player:IsHaveCurrentPet()` | `false` | đúng (chưa triệu hồi con nào) |
| `Pet:GetPetIndexByGUID(0,0)` | `-1` | đúng |
| `Pet:UpdatePetList()` | chạy, không lỗi Lua | đẩy `GE_UPDATE_PET_LIST` |
| `Pet:GetPetLocation(i)` ×6 | `-1` | **chỗ sửa nhìn thấy được**: stub trả `0`, script CY đọc `0 ~= -1` thành "trân thú đang bận" |

`Pet:SetPetLocation` (vòng ghi–đọc) và `Pet:GetGeneration` **chưa đo được**: cần một con trân thú có mặt
trong `CDataPool`, mà `Pet:GetPet_Count()` đo được là **0** dù `CYTest14` có 3 con trên server — chính là
nút thắt GC 512 ở mục 5.

**Bẫy của dụng cụ:** `SetTimer` của client **lặp lại theo tên**; chốt `if runs < 6` không dừng được, thực
tế chạy 19 nhịp trong 13 giây. Không phải lỗi của hàm host.

## 7. Thay đổi mã

| file | |
|---|---|
| `Src/Client/LuaApiGen/CysHost_Pet.h` / `.cpp` | **MỚI** — glue Lua 7 hàm (thư mục này được CMake glob sẵn) |
| `Src/Client/WXClient/Network/CysPetNet.h` / `.cpp` | **MỚI** — tầng game: `CDataPool`, `CCharacterData::Get_CurrentPetGUID`, `GE_UPDATE_PET_LIST`, ô đánh dấu vị trí |
| `Src/cmake/components/wxclient.cmake` | **+1 dòng** nguồn, thẻ `CYS-PET` |
| `Src/Client/WXClient/Network/CysModernGame.cpp` | **+1 include, +1 dòng** `CysPetNet::RegisterHost();`, thẻ `CYS-PET` |

Không đụng `GameProcedure.cpp`, `LuaApiGen.h`, `CysHost_Skill/Power/Plumbing.*` hay bất kỳ file nào của 7
agent song song. Không sửa file sinh tự động `LuaApiGen_*.cpp` — 7 mục được đăng ký với `force = true` vì
`LuaApiGen::RegisterAll` chạy **trước** (khi khởi tạo) còn `CysPetNet::RegisterHost()` chạy khi phiên thế
giới bắt đầu (`CysModernGame::Start`).

---

## 8. Bẫy đã gặp (đọc trước khi làm tiếp)

1. **Bảng sự kiện của B không lệch đều so với 0.85.** Đo được +5 (TogglePetPage), +27 (khối trân thú/túi
   đồ), −258 (UPDATE_TARGETPET_PAGE). Chỉ được ánh xạ ID sự kiện khi có **điểm neo trong cùng dải**.
2. **Bản ghi trân thú của B chèn ô ở giữa**, không chỉ nối thêm ở cuối. Suy offset theo `SDATA_PET` của
   0.85 là sai từ khoảng `[0x24]` trở đi. Phải hiệu chuẩn bằng các hàm 0.85 đã có (mục 2).
3. **Ghidra không phục hồi tham số `double` của `lua_pushnumber`** trong nhiều hàm (hiện ra
   `lua_pushnumber(*param_2)` một tham số). Gặp dạng đó thì bản dịch ngược **chưa đủ**, phải đọc
   disassembly hoặc bỏ qua — đừng đoán là "đẩy 0".
4. **`catalog.json` chỉ phủ binary GL/0.85**: 56/136 hàm riêng hệ đến từ `LuaApiGen_Cy.cpp` (sinh từ lời
   gọi script CY) nên **không có `impl_va`**.
5. **`Build/re/luaapi/decomp/Game.exe/1402bacd0.c` không tồn tại và Ghidra báo `NO FUNCTION at 1402bacd0`**
   cho `Pet:ClearSheliziPet` — địa chỉ trong catalog không trỏ vào đầu một hàm đã nhận diện.
6. **Cây nguồn đang có 7 agent sửa song song.** Lần build đầu hỏng vì
   `GamePro_Enter.h(36): error C2065: 'm_nResID'` — một agent khác đang sửa dở header đó, không phải lỗi
   của lượt này. Phải đọc lại file dùng chung ngay trước khi sửa và build lại sau vài phút.
7. **Chuỗi Lua trong heredoc qua Bash → PowerShell bị nuốt một lớp `\`.** Đoạn dò live phải được ghi bằng
   công cụ `Write` rồi ghép bằng PowerShell `[IO.File]::ReadAllText/WriteAllText`, không ghép bằng
   heredoc.


---
---

# PHẦN II — pet-gc512 (18/09/2026): nối gói 512, mở ô CY, sửa trứng

Nối tiếp phần I (host-pet 17/09). Mã: `Src/Client/WXClient/Network/CysPetNet.{h,cpp}` (viết lại toàn bộ),
`Src/Client/LuaApiGen/CysHost_Pet.{h,cpp}` (+14 hàm), 5 dòng móc vào file dùng chung (mục 12).
Bằng chứng: `Build/Logs/2026-09-18-pet-gc512/` (build, đo tĩnh, đo live, đo trứng). Server: `Tools/server/pet_egg_map.py`.

## 9. Bốn gói trân thú đã nối vào client (trước đây: "first unhandled GC id=512")

| gói | id | hướng | nguồn hình dạng gói | port từ 0.85 | làm gì |
|---|---|---|---|---|---|
| `GCDetailAttrib_Pet` | 512 | GC | `pet_detail_types.lua:785 bos()` — 12 byte cờ **đã đổi chỗ** (bit 0-1 giữ, 2-7 → 3-8, hp/hp_max → bit 9/10, rage → 11/12, 精灵 → 90), giải lại bằng `pg::deriveDetailAttribPetFlags` | `GCDetailAttrib_PetHandler.cpp` nhánh thường (ExtraInfo rỗng) + nhánh `TYPE_CONTEX_MENU_OTHER_PET` | tìm slot theo GUID, không có thì slot GUID rỗng; gán từng trường; kỹ năng qua `Pet_SetSkill`; đẩy `GE_UPDATE_PET_PAGE` |
| `GCNewPet` | 1216 | GC | `movement.lua:554 bos()`: `objID, model (pet.lua:311 unknow_1 = get_model), pos, unknow_2, speed, unknow_4` | `GCNewPetHandler.cpp` | `CObject_PlayerNPC` kiểu `NPC_TYPE_PET`, `OC_IDLE`, xếp vào hàng nạp (model đến bằng `GCCharBaseAttrib` như 0.85) |
| `GCRemovePet` | 52 | GC | `PetGUID` (8 byte, confidence high) | `GCRemovePetHandler.cpp` | `CleanUp()` slot, xoá ô CY, `UpdateToolBarForPetSkill`, `GE_UPDATE_PET_PAGE` |
| `GCManipulatePetRet` | 666 | GC | `{PetGUID, is_fighting u32, ret i32}`; `ret` = `define.ENUM_MANIPULATEPET_RET` (0..7 trùng enum 0.85, 8/9 融魂 chỉ CY) | `GCManipulatePetRetHandler.cpp` | ghi log; `CALLUPSUCC(3)` → `Set_CurrentPetGUID(guid)`, `FREESUCC(5)`/`RECALLSUCC(7)` → xoá nếu đang là con đó; `GE_UPDATE_PET_PAGE` |
| `CGManipulatePet` | 435 | CG | `misc.lua` `bis`: `m_objID, PetGUID, type`; `scenecore.lua:6484` chỉ dùng `pet_guid` + `type` (0 gọi, 1 thu, 2 thả) | `Translate` của `Packets::CGManipulatePet` (`Pet:Go_Fight / Go_Relax / Go_Free` của 0.85 gửi) | `m_objID` = ID server của chính mình (như bot) |

Không nối `GCNewPet_Move` (395): server riêng **không bao giờ dựng** gói này (không có tham chiếu ngoài định nghĩa).
`GCDetailAttrib` (của nhân vật) cờ `[8] & 0x10` = `pet_guid` → `CysPetNet::OnCurrentPetGuid` (0.85 làm ở `GCDetailAttribHandler.cpp:313`, bản port CY bỏ sót).

### 9.1 Khối đuôi của 512 = `ExtraInfo` của 0.85

Server viết `writeuchar(unknow_6)` rồi `unknow_6` byte `unknow_7` (`pet_detail_types.lua:1045-1052`); `human:send_pets_detail(who, type)` đặt
`unknow_6 = (type == nil) and 0 or 1`, `unknow_7 = {type}`. `ask_detail_attrib` cho người khác gọi `send_pets_detail(who, 4)`
(`scenecore.lua:1224`) ⇒ `[1 byte = 4]` = đúng `TYPE_CONTEX_MENU_OTHER_PET` của 0.85 → đổ vào `TargetPet_GetPet()` + `GE_VIEW_EXCHANGE_PET`.
Đuôi dài hơn (`GCExchangePetView_t` / `GCStallPetView_t`, byte đầu = `flag`) thuộc giao dịch/sạp — đếm `detailDropped`, không đổ.

### 9.2 Kỹ năng: CY 13 ô, 0.85 có 6

Gói CY mang 2 `activate` + 11 `positive` (mỗi ô `id i32 + level u8`, rỗng = `-1`); B giữ **13 ô** mỗi bản ghi (`FUN_140146250` từ chối `pos > 0xc`,
mảng con trỏ ở `+0x128`, bản ghi dài `0x250`). `SDATA_PET::m_aSkill` chỉ có
`PET_MAX_SKILL_COUNT = PET_SKILL_INDEX_NUMBERS = 6` (`GameDefine2.h:725`). Ánh xạ theo thứ tự dây: activate → ô 0,1; positive 1..4 → ô 2..5;
positive 5..11 **bị đếm vào `skillsBeyondSlots`** (không vứt im). Ba trân thú test **không có kỹ năng nào** (Mongo `skills.activate/positive` rỗng)
nên chưa đo được hiển thị kỹ năng. Mở đủ 12 nút như CY (`PETSKILL_BUTTONS_NUM = 12`, Pet.lua:24) cần **một dòng** thêm enumerator trước
`PET_SKILL_INDEX_NUMBERS` trong `GameDefine2.h` (kéo `PET_MAX_SKILL_COUNT` lên 13; `_PET_DB_LOAD` chỉ dùng phía server 0.85, client không tham chiếu) —
**chưa làm** vì đổi header dùng chung ⇒ dựng lại toàn bộ, và chưa có trân thú nào có >6 kỹ năng để nghiệm thu.

## 10. Ô CY-only của bản ghi B ↔ trường trên dây (mọi ô đã khớp bằng bằng chứng, không đoán)

Giữ trong `CysPetNet.cpp` (`PetCy[6]`, khoá theo GUID của con đang ở slot), không đụng `GMDP_Struct_Pet.h`.

| hàm host (RVA B) | ô B | trường dây 512 | bằng chứng khớp |
|---|---|---|---|
| `Pet:GetLixing` (0x2bc640) | `piVar2[?]` (decomp mất chỉ số) | `lingxing` u8 (`m_Flags[2]&0x08`) | tên hàm = tên trường; widget `Pet_Lingxing` (Pet.lua:1183) |
| `Pet:GetCriticalAttack` (0x2b2390) | `[0x24]` | `mind_attack` | `define.lua:595` `IATTRIBUTE_2ATTACK_RATE` = 会心一击; `human_attrib.lua:111` `mind_attack = {point = IATTRIBUTE_2ATTACK_RATE}`; thứ tự dây hit, miss, mind_attack, mind_defend = `[0x22..0x25]` |
| `Pet:GetCriticalDefence` (0x2b2430) | `[0x25]` | `mind_defend` | như trên |
| `Pet:GetSavvy` (0x2b5a10) | `[0x43]` | `wuxing` u32 | 悟性 = wùxìng; widget `Pet_WuXing` "Ngộ tính" (Pet.lua:1196-1197); server `wuxing_bonus[1..10]`; Lua `nSavvy >= 7`. **Giả thuyết cũ "gengu → savvy" SAI**: `gengu` = 根骨 = `m_nBasic` (`Pet:GetBasic`, 0.85 `PET_DETAIL_ATTR_GENGU`) |
| `Pet:GetTitleNum` (0x2b95c0) | `(end−begin)>>3` của vector `[0x50..0x52]` | `titles[10]` i32 (`-1` = trống) | đếm mục ≠ −1 |
| `Pet:GetGrowRate` (0x2b5ab0) | `(int)((float)[0x45] * 1000.0)` | `growth_rate` f32 (`-1` khi chưa giám định) | công thức nguyên văn decompile |
| `Pet:GetPetType` (0x2bc8e0) | byte `+0x17c` | `unknow_13` u8 = `define.PET_TYPE` (0 宝宝, 1 变异, 2 野生) | server tính từ `pet_attr_table.is_var_type/is_baby_type`; Lua `nPetType == 0` = 宝宝 (Pet.lua:1053) |
| `Pet:GetLastProcreateLevel` (0x2b0330) | `[0x11]` (giữa Level `[0x10]` và Exp `[0x12]`) | `used_procreate_count` i32 (giữa `level` và `exp` trên dây) | vị trí trùng + chú thích Pet.lua:1054 "改成记录已经繁殖次数" |
| `Pet:IsPetHaveEquip` (0x2bb490) | helper `FUN_1401c3b50(pet)` | `equip_list_1..6.item_index >= 0` (rỗng = `Item_cls.new()` = −1) | tên hàm; **chưa có trân thú nào có trang bị để đo live** |
| `Pet:SetSelectPetIdx` (0x2b8fc0) | ghi int vào `+0x70` của 4 đối tượng xem trước | — (chỉ số) | decompile |
| `Pet:GetData("ATTACKCOLD"…)` (0x2bb530) | `[0x27..0x32]`, 12 nhánh `memcmp`, đọc con ĐANG CHỌN | `att_/def_/reduce_def_ × cold/fire/light/poison` | `ATTACKCOLD=[0x27]`, `ATTACKFIRE=[0x2a]`, `ATTACKLIGHT=[0x2d]`, `ATTACKPOISON=[0x30]` ⇒ bước 3 = (att, def, reduce_def) đúng thứ tự dây |
| `Pet:GetSkillIDbyIndex(i, pos)` (0x2b2560) | `FUN_140146250(pool, i, pos)` | `Pet_GetSkill(i,pos)->m_pDefine->m_nID` | PetLevelup.lua:146-151 dùng cùng `pos` với `EnumPetSkill` |
| `Pet:GetTakeLevel(i)` (0x2b5850) | `FUN_1401c3af0`: DBC 0x70 (= PetAttrTable, `dbc_inventory_gl.json b_id 112`) dòng `pet[5]` (data id), int `+0x14` | `_DBC_PET_EX_ATT::m_TakeLevel` (CY cột 4 = GL cột 3 可携带等级; 558 → 1, 3009 → 5) | `decomp-gc512-b.c`; bố trí dòng GL x64 `dbc_columns_gl.tsv` cột 3 @ +20 |
| `Pet:GetPetGrowLevel(i, rate)` (0x2b47d0) | `FUN_1401c39a0`: cùng dòng, so `rate` với int `+0xa4/+0xa8/+0xac/+0xb0` → 0/1/2/3, lớn hơn → 4; `rate < 0` → −1 | `m_GrowRate0..3` (CY cột 30-33 = GL cột 39-42 = 成长率1..4; 3009: 540/594/621/702 ⇒ 0,594 → 1 "Ưu tú") | `decomp-gc512.c`; hàng 3009 đọc từ DBC nhị phân CanonicalCY |

Không cài (lý do cụ thể): `Pet:GetAttackTrait` cần DBC `0xbe` (CY `AttackTraits.txt`, có trong CanonicalCY nhưng **chưa đăng ký** trong `GMDataBase.cpp`);
`Pet:GetPercent_Lx` cần DBC `0xfe` (`PetLingXing.txt`, 2,2 MB, chưa đăng ký) và ô `[0x5e]`; `Pet:IsFreeing` đọc cờ client `pet[1] == 1`
(đặt khi gửi thả, 0.85 không có) — 1 lời gọi, để stub. **Bẫy bố trí bảng**: B đọc PetAttrTable 51 cột (client_GL) bằng offset GL x64 (`+0x14`, `+0x24`, `+0xa4`);
bảng CY 54 cột chèn một cột ở `[2]` (registry `dbc_columns_cy.tsv`: CY 4 ↔ GL 3, CY 8 ↔ GL 7, CY 30-34 ↔ GL 39-43) — dùng TÊN TRƯỜNG của `_DBC_PET_EX_ATT`, không dùng offset của B.

## 11. Trứng trân thú — đo lại THEO TÊN, sửa 180, giữ 56 (server riêng)

Số cũ "169/517 lệch script" đo theo FILE (`egg-script-truth.json`) là **phép đo sai**: nó đếm cả vật phẩm CY **không phải trứng**
(珍兽笼 script 300300 không tồn tại, sách kỹ năng script 840005) và bỏ sót trứng nở **sai con**. Đo theo tên (`scripts/11-egg-truth-by-name.py`):

| CY `CommonItem` có `珍兽蛋` trong tên | 499 |
|---|---|
| dispatch tới `300027.lua` | **490** (9 còn lại trỏ script không có: 892728/999300/999811/893631/−1) |
| nở đúng tên (trước) | 281 |
| có mục nhưng nở **con khác** (trước) | 17 — vd `珍兽蛋：咩小萌` → `星冥人偶宝宝` |
| không có mục → "Đạo cụ chưa mở" (trước) | 192 |

Hiệu chuẩn (`12-egg-calibrate.py`): 270/274 trứng đang đúng có `PetAttrTable` cột 3 (可携带等级) **= cấp trứng** (`CommonItem` cột 8).
Quy tắc: `珍兽蛋：X` cấp L → `X宝宝` có cột 3 = L; `变异珍兽蛋：X` / `珍兽蛋：变异X` → `变异X`. Chỉ ghi khi **đúng một** dòng khớp
(hoặc tên duy nhất). Kết quả `Tools/server/pet_egg_map.py apply` (backup `R/backups/pet-eggmap-20260917T202451Z/300027.lua`, `luac5.4 -p` rc 0):

| | |
|---|---|
| thêm mục | **173** |
| thay mục sai (mục cũ giữ dạng chú thích `--CYS-PET egg-map old:`) | **7** |
| giữ nguyên | 254 → `verify`: **434 keep / 0 add / 0 replace** |
| không đoán | **56**: 32 nhiều dòng cùng cấp (vd `珍兽蛋：鸭嘴兽` có 3449 và 7509 cùng cấp 5), 11 không có trân thú tên đó (神猿 series, 冰雕龙, 火鸡…), 9 tên đặc biệt (神秘珍兽蛋, `（废弃）`, `（雄）/（雌）`), 4 变异 nhiều dòng |

Server chỉ nạp script lúc khởi động hoặc `reload_scripts` — lần restart kế của nhánh `server-data` nạp bản mới. Nghiệm thu bằng bot:

**Bot nở trứng (18/09 03:55–03:57, test14, server sau restart 03:52:49, log server `traceback=0 error=0` cả hai lượt):**
| trứng | mục | kỳ vọng | bot đo được |
|---|---|---|---|
| 30309066 `珍兽蛋：欢乐猪` lv 5 | **thêm** (trước: "Đạo cụ chưa mở") | 8569 `欢乐猪宝宝` | `GCUseItemResult result=0`, `count 1→0`, túi thú **3 → 4**, con mới `200015:269033 data_index 8569` lv1 hp 329/329 (`live/egg-30309066-035554`) |
| 30309079 `珍兽蛋：咩小萌` lv 5 | **thay** (trước: nở `24619 星冥人偶宝宝`) | 27149 `咩小萌宝宝` | `result=0`, `count 1→0`, túi **4 → 5**, con mới `200015:306614 data_index 27149` hp 145/145, tên dây `咩小萌宝宝` (`live/egg-30309079-035632`) |
CYTest14 nay có **5/6** trân thú (cố ý để 1 ô trống). Cả hai lượt bot `code=0`, `quit_complete`, **`decode_failures=0`, `unknown_packets=0`**, `pet_details` = số con trong túi (4 rồi 5) — gói 512 giải mã sạch.

## 12. Thay đổi mã (5 dòng ở file dùng chung, thẻ `CYS-PET`)

| file | |
|---|---|
| `CysModernHandlers.cpp` | +1 `#include "CysPetNet.h"`; +1 `if (CysPetNet::IsWorldPacket(id)) return true;`; +1 `if (CysPetNet::Dispatch(packet)) return true;`; +1 `if (has(8,16)) CysPetNet::OnCurrentPetGuid(...)` trong nhánh `self` của `OnGCDetailAttrib` |
| `CysModernGame.cpp` | +1 `if (auto pet = CysPetNet::Translate(legacy)) return pet;` ở `default:` của `Translate` |
| `CysPetNet.{h,cpp}`, `CysHost_Pet.{h,cpp}` | của nhánh; không sửa `GMDP_Struct_Pet.h`, `GCDetailAttrib_PetHandler.cpp`, `GameDefine2.h`, `LuaApiGen_*.cpp` |

Phép đếm tĩnh (`scripts/10-scan-pet.py` → `rank-pet-after.tsv`): stub **138 → 124** hàm, lời gọi stub **386 → 314** (−14 hàm / −72 lời gọi;
cộng 7 hàm của host-pet: 145 → 124, 485 → 314).

## 13. Đo live (client thật + server riêng, test14 / CYTest14, 3 trân thú)

**`live-2` (18/09 08:55:50–08:57:37, `Build\Logs\2026-09-18-pet-gc512\live-2`)** — `passed=true`, **20/20 cổng kiểm**, `exit_code=0`,
`elapsed_s=98.6`, `quit_complete quit_flag=0 decode_failures=0`, 0 `handler exception`, 0 dump.
Bản dựng: `Game.exe` sha256 `6a91e087f143…` (Release `/O2 /Ob2`), `CYS-PET: host functions registered=21`.

**Điều then chốt: `Pet:GetPet_Count()` = 0 → 5.** Mọi nhịp dò đều trả 5 (17/09 trả 0 dù server có trân thú).
Dòng `first unhandled GC id=512` **biến mất** khỏi danh sách (còn 335/1750/334/479/530/1205/102/724/251/625/872 — không phải trân thú).

Năm gói 512 vào đúng 5 ô, giá trị đọc được (log `CYS pet:`):

| ô | guid | data | tên (UTF-8 trên dây) | hp | type | take | grow |
|---|---|---|---|---|---|---|---|
| 0 | 200015:1291469 | 3009 | Thú cưng Thỏ | 184/200 | 0 (宝宝) | 5 | −1000 |
| 1 | 200015:777395 | 558 | Phiêu Phiêu Áp | 156/156 | **1 (变异)** | **1** | −1000 |
| 2 | 200015:940210 | 558 | Phiêu Phiêu Áp | 166/166 | 1 | 1 | −1000 |
| 3 | 200015:269033 | 8569 | Heo Vui Vẻ Thú cưng | 329/329 | 0 | 5 | −1000 |
| 4 | 200015:306614 | 27149 | 咩小萌宝宝 | 145/145 | 0 | 5 | −1000 |

**Ba ô tự kiểm chéo với bảng dữ liệu, không phải "trả về số nào cũng được":** `type` = 1 đúng cho 558 (`PetAttrTable` cột 6
是否变异 = 1) và 0 cho 3009/8569/27149 (cột 7 是否宝宝 = 1); `take` = 1 cho 558 và 5 cho ba con kia — đúng cột 4 可携带等级;
`grow` = −1000 vì server gửi `growth_rate = -1` khi `growth_rate_queryd = false` (chưa giám định) ⇒ `growlvl = -1` "Vô danh", đúng luật CY.
`savvy/lixing/titles/procreate/equip = 0` khớp Mongo (`wuxing/gengu/lingxing = 0`, `titles = {}`, `equips = {}`); `crit = 8/8` (`mind_attack/mind_defend`).

**Hai hàm 17/09 KHÔNG đo được, nay đo được** (vì cần trân thú thật trong `CDataPool`):
`Pet:SetPetLocation` vòng ghi–đọc `loc = -1 / 12 / -1` ở cả 5 ô; `Pet:GetPetIndexByGUID(hi,lo)` = đúng chỉ số ô (0,1,2,3,4).

**Khung trân thú mở thật trong game**: `TogglePetPage()` (đúng hàm nút chính của `MainMenuBar.lua:1077`) → ảnh
`cys-pet-frame.png` (08:57:04, 1,21 MB). `missing host function Pet:*` trong phiên **có mở khung** còn **3** dòng /
3 hàm: `Pet:GetPet_Count_PetBank`, `Pet:GetIsBaiShou`, `Pet:GetIsPossession` (trên tổng 87 dòng / 85 hàm của cả phiên).
So sánh trung thực: phiên 17/09 có **0** dòng `Pet:*` nhưng chỉ vì khung **chưa bao giờ mở** — 0 đó không phải điểm tốt hơn.

**Triệu hồi và thu hồi bằng chính hàm của khung** (`Pet:Go_Fight(0)` / `Pet:Go_Relax(0)` → `CGManipulatePet` đã dịch):

```
CYS pet: CGManipulatePet type=0 guid=200015:1291469 sent
CYS pet: GCManipulatePetRet ret=3 CALLUPSUCC guid=200015:1291469
CYS pet: GCNewPet obj=213 model=3009 at (156.9,155.1) speed=3.50      <- trân thú hiện trong cảnh
CYS pet: GCDetailAttrib_Pet #6 slot=0 ... obj=213 ...                 <- gói làm mới, obj -1 -> 213
CYS pet: CGManipulatePet type=1 guid=200015:1291469 sent
CYS pet: GCManipulatePetRet ret=7 RECALLSUCC guid=200015:1291469
```
`Player:IsHaveCurrentPet()` false → **true** sau triệu hồi; `Pet:GetIsFighting(0)` = true; ảnh `cys-pet-summoned.png`.

**Không làm vỡ gói khác (đòi hỏi của đề bài), đo bằng dòng tổng kết phiên:**

| | 17/09 `live-3` (trước) | 18/09 `live-2` (sau) |
|---|---|---|
| gói GC **chưa có handler** | `unhandled=13/37` | **`unhandled=11/28`** |
| `decode_failures` | 0 | **0** |
| `handler_errors` / `invalid_pos` | 0 / 0 | **0 / 0** |
| gói CG không dịch được | `dropped=12/18` | `dropped=12/19` (cùng 12 ID, thêm 1 lần xuất hiện) |

Số gói chưa xử lý **giảm** dù phiên sau làm nhiều hơn (mở khung, triệu hồi, thu hồi) — đúng như kỳ vọng khi 4 ID trân thú
(512, 1216, 52, 666) rời khỏi danh sách. **11 ID còn lại không có ID nào của trân thú**: 335 `GCChatDecryption`,
334 `GCMSShopBuyInfo`, 479 `GCDiGongShopInfo`, 530 `GCExteriorInfo`, 1205 `GCUICommand`, 1750 `GCRMBChatActionInfo`,
102 `GCSectDetail`, 724 `GCComboSkillOperation`, 251 `GCDetailImpactListUpdate` (cả chín đến trong cụm vào thế giới lúc 08:56:57),
cộng 625 `GCNewBus_Move` + 872 `GCBusMove` — **xe/thuyền trong cảnh** (`services/scene/obj/bus.lua`, `scenecore:create_buss`),
không phải trân thú; chúng tình cờ xuất hiện sau lúc triệu hồi nên dễ bị quy oan.

**Chỗ ảnh SAI NHÃN, ghi lại thay vì giấu:** `cys-pet-recalled.png` của `live-2` **byte y hệt** `cys-pet-summoned.png`
(cùng sha256 `18c93603866f3647…`). Nguyên nhân: chốt chờ tính theo **số nhịp** `SetTimer`, mà nhịp bắn hàng loạt trong
cùng một giây (nhịp 16→24 đều ở 08:57:10) nên ảnh chụp **trước khi** `ret=7` về; dòng `after Go_Relax: IsHaveCurrentPet()=true`
cũng đo sớm vì vậy. Việc THU HỒI vẫn được chứng minh bằng gói (`ret=7 RECALLSUCC`), nhưng **ảnh thì không** — đừng dùng
ảnh đó làm bằng chứng. Đã sửa trong mã: các pha nay chờ **trạng thái đổi** (`Player:IsHaveCurrentPet()` lật true rồi lật false),
và tên ảnh có mã phiên (`cys-pet-<tick>-<nhãn>.png`) vì `run_world_gui_live.ps1` chỉ chép PNG **mới** — tên cố định trùng với
ảnh của lượt bị huỷ lúc 03:47 nên ảnh khung trân thú bị bỏ lại trong stage, phải chép tay vào `live-2`.

**`live-3` (18/09 09:59:49–10:01:26) — lượt XÁC NHẬN sau khi sửa ba lỗi của chính lượt trước.** `passed=true`, 20/20 cổng kiểm,
`exit_code=0`, `elapsed_s=97`, `decode_failures=0`, `handler_errors=0`. `Game.exe` sha256 `ed3b9cf63c29…`.

| đo | `live-2` (chốt theo số nhịp) | `live-3` (chốt theo trạng thái) |
|---|---|---|
| sau `Go_Relax` | `IsHaveCurrentPet()=true`, `GetIsFighting(0)=true` — **đo sớm, sai** | **`false` / `false`** — đúng |
| ảnh `summoned` vs `recalled` | **trùng byte** (`18c93603…`) | **khác nhau** (`7298a0c4…` vs `306d2022…`) |
| ảnh vào thư mục bằng chứng | thiếu ảnh khung (kẹt trong stage) | **đủ 3** (`cys-pet-203456921-frame/summoned/recalled.png`) |

**Bộ đếm của module, in ra cuối lượt** (`Pet:CysPetProbeCounters`):

```
CYS-PET probe: counters detail=6 applied=6 target=0 dropped=0 new_pets=1 removed=0
                        manipulate_ret=2 manipulate_sent=2 skills_beyond_slots=0
```
`dropped=0` = **không gói 512 nào bị bỏ im** (đủ ô, không có view giao dịch/sạp); `skills_beyond_slots=0` = **không kỹ năng THẬT nào
rơi ra ngoài 6 ô của 0.85** (13 cờ đều là `-1` vì các con này chưa có kỹ năng); `applied=6` = 5 con trong túi + 1 gói làm mới khi triệu hồi.

**Ảnh khung trân thú** (`cys-pet-203456921-frame.png`): cửa sổ **Trân thú** mở, danh sách hiện **đúng tên thật** —
"Thú cưng T…", "Phiêu Phiêu…", "Phiêu Phiêu…", "Heo Vui Vẻ" (con thứ 5 nằm dưới, phải cuộn). Khi triệu hồi, dòng đang chọn
sáng lên và một thanh trạng thái hiện ở giữa dưới màn hình (`cys-pet-203456921-summoned.png`).

**Khuyết điểm nhìn thấy trên ảnh, KHÔNG phải lỗi dữ liệu — thuộc `ui-fit`:** bố cục khung `Pet` đè chữ nặng
("ảnh hiệ"/"Sửa"/"sách Trân t" chồng lên danh sách; loạt nhãn `Ng.công / Nội công / Ngoại thủ / Nội thủ / Né / C.xác /
Hội công / Hội thủ` không thấy ô giá trị đi kèm; khung xem trước mô hình trống). Dữ liệu đã tới client đầy đủ (chứng minh bằng
phép dò từng ô ở trên), nên đây là việc kẻ lại khung — đúng nhóm "487 cặp chữ đè nhau / 190 khung" mà `ui-fit` đã xếp hạng.

ID gói chưa xử lý của `live-3` (12): như `live-2` cộng **422 `GCBusRemoveAllPassenger`** — cũng là xe/thuyền trong cảnh, không phải trân thú.

## 14. Bẫy mới

1. **Python heredoc qua Bash không ghi được file có chuỗi `\n` trong mã C++** — "patched" in ra nhưng file không đổi (mtime cũ, build "no work to do"). Dùng `Edit`.
2. **`GCNewPet_Move` không bao giờ được server dựng** — đừng port handler cho gói không ai gửi.
3. **`gengu` ≠ savvy.** `gengu` = 根骨 = `m_nBasic`; savvy = `wuxing` (悟性). Widget `Pet_WuXing` là bằng chứng rẻ nhất.
4. **Trứng: so theo TÊN + cột 3, không theo ID** — cùng ID giữa CY và 0.85 là vật phẩm khác (珍兽笼, sách kỹ năng).
5. Phép đo "missing host function Pet:*" của lượt tự động = **0 cả trước lẫn sau** vì khung không mở; phải mở khung (probe `TogglePetPage()`) mới đo được.
6. **`SetTimer` bắn hàng loạt trong CÙNG một giây** (live-2: nhịp 16→24 đều ở 08:57:10). Mọi chốt chờ theo **số nhịp** đều đo sớm —
   ảnh "đã thu hồi" hoá ra là ảnh "đang triệu hồi" (trùng sha256). Chốt phải theo **trạng thái quan sát được**
   (`Player:IsHaveCurrentPet()` lật true rồi lật false). `GetCurrentTime()` của client **không dùng thay được**: nó trả
   giờ/phút/**mili-giây**, thiếu hẳn trường giây (`GMGameInterface_Script.cpp:1758`).
7. **`run_world_gui_live.ps1` chỉ chép PNG MỚI** (so với ảnh chụp thư mục trước khi chạy). Tên ảnh cố định ⇒ ảnh của lượt trước
   (kể cả lượt bị huỷ) làm ảnh mới bị coi là cũ và **ở lại trong stage**. Đặt mã phiên vào tên ảnh.
8. **Server đặt CẢ 13 cờ kỹ năng ở mọi gói 512**, kể cả khi trân thú không có kỹ năng nào
   (`set_activate_skill_1(nil)` → `skill = skill or define.INVAILD_ID` vẫn bật cờ). Gọi `Pet_SetSkill` theo từng cờ là 6 lần
   `CleanInvalidAction` + 6 lần `GE_UPDATE_PET_PAGE` mỗi con mỗi gói (30 lần cho 5 con) — phải so giá trị cũ trước khi ghi.
6. **`SetTimer` bắn hàng loạt trong CÙNG một giây** (live-2: nhịp 16→24 đều ở 08:57:10). Mọi chốt chờ theo **số nhịp** đều đo sớm —
   ảnh "đã thu hồi" hoá ra là ảnh "đang triệu hồi" (trùng sha256). Chốt phải theo **trạng thái quan sát được**
   (`Player:IsHaveCurrentPet()` lật true rồi lật false), không theo đếm nhịp. `GetCurrentTime()` của client **không dùng thay được**:
   nó trả giờ/phút/**mili-giây**, thiếu hẳn trường giây (`GMGameInterface_Script.cpp:1758`).
7. **`run_world_gui_live.ps1` chỉ chép PNG MỚI** (so với ảnh chụp thư mục trước khi chạy). Tên ảnh cố định ⇒ ảnh của lượt trước
   (kể cả lượt bị huỷ) làm ảnh mới bị coi là cũ và **ở lại trong stage**. Đặt mã phiên vào tên ảnh.
8. **Server đặt CẢ 13 cờ kỹ năng ở mọi gói 512**, kể cả khi trân thú không có kỹ năng nào
   (`set_activate_skill_1(nil)` → `skill = skill or define.INVAILD_ID` vẫn bật cờ). Gọi `Pet_SetSkill` theo từng cờ là 6 lần
   `CleanInvalidAction` + 6 lần `GE_UPDATE_PET_PAGE` mỗi con mỗi gói (30 lần cho 5 con) — phải so giá trị cũ trước khi ghi.
