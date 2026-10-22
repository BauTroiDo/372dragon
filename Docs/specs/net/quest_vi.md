# Chuỗi nhiệm vụ tân thủ Đại Lý chạy đầu-cuối trên server riêng — 17/09/2026

Tiếp nối [npc-quest_vi.md](npc-quest_vi.md) (wire `GCScriptCommand` / `CGMission*`, hộp thoại NPC, khung theo dõi)
và [core-loop_vi.md](core-loop_vi.md) (đi, đánh, nhặt). Phần này đặc tả **chuỗi nhiệm vụ tân thủ Đại Lý
1400 → 1422** trên server riêng `/home/ubuntu/cys-test-20260913` (login 15733 / game 15734): từng bước là script
nào, điều kiện gì, NPC nào, thưởng gì, **bước nào đã đo được đầu-cuối**, bước nào hỏng và vì sao.

Ký hiệu: **[DK]** dữ kiện đọc từ mã/dữ liệu server; **[SL]** suy luận chưa kiểm; **[LIVE]** đã đo trên server riêng
bằng bot `CysNetBot --mode world` ngày 17/09 (bằng chứng `Build/Logs/2026-09-17-quest-live/`).

## 1. Bảng chuỗi tân thủ Đại Lý (cảnh 2)

Tất cả script nằm ở `Game_2/Script/scripts/event/dali/`, ánh xạ id → file trong `Game_2/Script/scripts/scripts.lua`.
Vị trí NPC lấy từ `Game_2/Scene/dali_new_320_monster.ini` (GBK) — **khác** `g_Position`/`g_SignPost` của script
(đó chỉ là mốc chỉ đường trên bản đồ) **[DK]**.

| # | Mission | Script (file) | NPC nhận | NPC nộp | Điều kiện thật | Thưởng | Trạng thái |
|---|---|---|---|---|---|---|---|
| 1 | 1400 Sơ nhập giang hồ | 210262 `edali_newquest_001` | 赵天师 (160,158) | 赵天师 | xong ngay khi nhận | 200 EXP, 1 giao tử | [LIVE] đã xong từ trước |
| 2 | 1401 Vũ khí đầu tiên | 210200 `edali_zhidao_0200` | 赵天师 | **蒲良 (219,123)** | xong ngay khi nhận | chọn 1/6 vũ khí + 10×30101001 + 1 giao tử + 700 EXP | **[LIVE] ĐẠT** `t1`, `u1` |
| 3 | 1402 Trang bị phòng ngự đầu tiên | 210256 `edali_newquest_003` | 蒲良 | **黄公道 (254,174)** | nói chuyện | 10113000 ×1, 1 giao tử, 200 EXP | **[LIVE] ĐẠT** `t2/t3`, `u2/u3` |
| 4 | 1403 Lần đầu giết quái | 210257 `edali_newquest_004` | 黄公道 | 黄公道 | **giết 4 × 高山白猿** (type 900/901, cảnh 6/73/74 Vô Lượng Sơn) | 10110000 ×1, 30 giao tử, 780 EXP | **[LIVE] ĐẠT cả điều kiện** `t4/t5/t6b`, `u4/u5/u6` |
| 5 | 1404 Hồi thăm Thiên Sư | 210258 `edali_newquest_005` | 黄公道 | 赵天师 | nói chuyện | 30 giao tử, 1200 EXP | **[LIVE] ĐẠT** `t7/t8` |
| 6 | 1405 Kỹ năng Sơ Cấp | 210263 `edali_newquest_006` | 赵天师 | 钱龙 (143,138) | (học kỹ năng) — **không được kiểm** | 30 giao tử, 1600 EXP | **[LIVE] ĐẠT** `t9/t10` |
| 7 | 1406 Linh Đan Diệu Dược | 210259 `edali_newquest_007` | 钱龙 | 卢三七 (105,123) | nói chuyện | 30001001 ×5, 30 giao tử, 1600 EXP | **[LIVE] ĐẠT** `t11/t12` |
| 8 | 1407 Kiếm Các Hầu Hoạn | 210273 `edali_newquest_008` | 卢三七 | 高升祥 (45,125) | giết 4 × 蜀道白猿 (id 718/719) — **quái chỉ có ở `jiange_monster.ini`, cảnh 7 剑阁 `active=0`** | 5 món giáp + 30 giao tử + 4560 EXP | **[LIVE] nộp được** `t13/t14` nhưng **điều kiện không thể đạt** |
| 9 | 1408 Đại Lý Quái Nhân | 210274 `edali_newquest_009` | 高升祥 | 段延庆 (279,263) | nói chuyện | 100 giao tử, 3200 EXP | **[LIVE] HỎNG trước vá (`t16b`,`t17`) → ĐÃ VÁ → ĐẠT sau restart (`v1`)** (mục 4.1) |
| 10 | 1423 Hà Vị Hành Thiện | 210280 `edali_newquest_010` | 段延庆 | 段延庆 | **nhận 3 vật phẩm ở 黄公道 (mục 3) rồi tặng cho 小乞丐 (250,271) (mục 4)** | 300 giao tử, 6000 EXP | **[LIVE] ĐẠT cả điều kiện** `w1/w2b/w3b/w4` |
| 11 | 1412 Tái Phỏng Thiên Sư | 210275 `edali_newquest_013` | 段延庆 (279,263) | 赵天师 | nói chuyện | 3200 EXP | chưa đo — bước kế tiếp |
| 12 | 1413 Gia Tộc Trân thú | 210276 `edali_newquest_014` | 赵天师 | 云飘飘 (271,133) | nói chuyện | 2400 EXP | chưa đo |
| 13 | 1414 Trân thú Đầu Tiên | 210264 `edali_newquest_015` | 云飘飘 | 云飘飘 | **CheckSubmit thật**: có pet `g_PetID` cấp ≥ 2 | 4000 EXP | chưa đo — bot chưa nuôi pet được |
| 14 | 1415 Bắt Trân thú | 210265 `edali_newquest_016` | 云飘飘 | 云飘飘 | **CheckSubmit thật**: có pet 飘飘鸭 (`OnPetChanged`) | 3200 EXP | chưa đo — bot chưa bắt pet được |
| 15 | 1416 Tam Phỏng Thiên Sư | 210277 `edali_newquest_017` | 云飘飘 | 赵天师 | nói chuyện | 2400 EXP | chưa đo |
| 16 | 1417 Pháo hoa mừng lễ | 210266 `edali_newquest_018` | 赵天师 | 赵天师 | **CheckSubmit thật**: param 0 ≥ 1 (đốt pháo hoa `g_ItemId` nhận lúc OnAccept) | 2400 EXP | **đang treo trong nhật ký của CYTest01/02 với p0=0** |
| 17 | 1418 Đại Thiện Nhân | 210278 `edali_newquest_019` | 赵天师 | 钱龙 | nói chuyện | 2400 EXP | chưa đo |
| 18 | 1419 Giang Hồ Vấn Đáp | 210267 `edali_newquest_020` | 钱龙 | 赵天师 | trả lời đúng 5 câu — **không được kiểm** | 2400 EXP | chưa đo |
| 19 | 1420 Thử thách cuối | 210269 `edali_newquest_021` | 赵天师 | 赵天师 | **CheckSubmit thật**: giết 5 × 木头人 (id 703) — **chỉ có ở `newbie_1_monster.ini` (小木人巷, cảnh 50/61/81 đều `active=0`)** | — | **CHẶN CỨNG** [DK] |
| 20 | 1421 Thập Đại Môn phái | 210268 `edali_newquest_022` | 赵天师 | 赵天师 | **CheckSubmit thật**: `GetMenPai(self) ~= 9` | — | chặn với nhân vật phái 9 (CYTest02) |
| 21 | 1422 Giang hồ hùng vĩ | 210279 `edali_newquest_023` | 赵天师 | 崔逢九 (253,121) | nói chuyện | 4000 EXP | chưa đo |

Ghi chú:

- `g_MissionIdPre` là điều kiện mở khoá: `OnEnumerate`/`OnDefaultEvent` im lặng khi nhiệm vụ trước chưa xong, nên
  mục nhiệm vụ **chỉ hiện sau khi nộp bước trước** (đã thấy live: menu 卢三七 không có 210273 trước khi nộp 1406,
  có ngay sau đó) **[LIVE]**.
- Bốn file `edali_newquest_{015,019,022,023}.lua` **không gán `script_id`**, và `019` đặt trường lên biến lớp
  `edali_newquest_018`. Vô hại: `scriptenginer:try_load` ghi đè `script.script_id = id` theo bảng
  `scripts/scripts.lua`, nơi cả 4 id đều có mặt **[DK]**.

## 2. Đếm điều kiện giết quái — đường đi thật

`human:on_kill_object` (`GameServer/services/scene/obj/human.lua:7736`) **[DK]**:

1. bỏ qua nếu đối tượng không phải `monster`, hoặc bản sao người chơi đã rời cảnh (`[KILL_STALE]`);
2. gọi 791010 `OnKillMonster` (Phong Hồn Lục);
3. với **mỗi** nhiệm vụ đang có mà `yFlag & 0x1 == 1`, và cờ `obj.misions_toggle[mission.id]` của **con quái đó**
   chưa bật, gọi `scriptenginer:call(mission.index, "OnKillObject", myObjId, obj:get_model(), obj:get_obj_id())`.

Trong script (`edali_newquest_004:OnKillObject`): so `self:GetName(objId)` với `g_DemandTrueKill[i].name`
(chuỗi chữ Trung), rồi với mọi người chơi gần xác quái (`GetNearHumanCount`/`GetNearHuman`) tăng param 1 và đặt
param 0 = 1 khi đủ số, cuối cùng `DispatchMissionTips` (GCScriptCommand cmd 5).

**Vì sao so tên chữ Trung lại khớp:** `txtreader.lua:25` và `inireader.lua:25` gọi `gbk.toutf8(line)` khi nạp
bảng/ini, nên `monster:get_name()` (= `db:get_attrib("name")`) trả về **UTF-8**, cùng mã với chuỗi literal trong
file `.lua` (UTF-8). `wire_charset.fromutf8` + `wire_names_vi.lua` chỉ đổi tên ở **biên packet**, không đụng logic
server **[DK]**.

**Nguồn tên quái:** `dali/wuliang_monster.ini` để trống `name=` cho quái thường; tên thật lấy từ
`configs/MonsterAttrExTable.txt` (GBK) — id 900 và 901 **đều tên 高山白猿** (89 điểm spawn ở Vô Lượng Sơn),
id 708/709 là hai con 首领/头目 **[DK]**. Điểm săn `45,152` (cùng điểm `menpai_check.ps1` đang dùng) có ≥ 10 con
trong bán kính 20 m.

**Đo live [LIVE]** (`u5-kill-1403`, CYTest02, `--goto 304,149 --hunt 45,152 --attack 6 --record 1`):
cảnh 2 → cổng (304,149) → cảnh 74 → giết 6 quái; fixture PGWORLD1 có đúng 4 gói `GCScriptCommand cmd=5`:

```
TIP 37 bytes 'Đã giết Bạch Viên Cao Sơn 1/4'   ... 2/4 ... 3/4 ... 4/4
```

và Mongo `mission_data.char_missions` của 1403 đi từ `p0=0,p1=0` → **`p0=1,p1=4`**. Lượt `t5-kill-1403`
(CYTest01) cho kết quả y hệt nhưng vào **cảnh 6** — hook chạy đúng ở mọi tuyến Vô Lượng Sơn.

## 3. Đường đi giữa Đại Lý và Vô Lượng Sơn (dùng cho điều kiện giết quái)

- Đại Lý → Vô Lượng Sơn: đi bộ tới **(304,149)** trong cảnh 2 → server đổi cảnh sang 6 / 73 / 74 (cùng bản đồ,
  chọn tuyến theo tải), đáp ở khoảng (43,172) **[LIVE]**.
- Vô Lượng Sơn → Đại Lý: **vùng kích hoạt** `wuliang_area.ini [area2] script_id=400017`, hình chữ nhật
  **x 29..35, z 170..182** → đi tới **(32,176)** **[LIVE]**. `wuliang_platform.ini [platform0]` ở **(38,176)**
  ("通往大理") là **bàn thao tác**, đứng lên đó KHÔNG đổi cảnh (lượt `t6` đứng ở 38,176 và vẫn ở cảnh 6) — đây là
  cái bẫy dễ mất một phiên.

### 4.1 CHẶN CỨNG: nhiệm vụ không có vật phẩm thưởng thì không nộp được

**Triệu chứng [LIVE]** (`t16b`, `t17`, mission 1408/210274): hộp thoại chạy đủ — cmd 0 (menu có
`script=210274 index=1 type=2`), cmd 3 `done=1`, `CGMissionContinue` → cmd 4 — rồi `CGMissionSubmit` được gửi
nhưng server **chỉ** trả một gói:

```
GCScriptCommand cmd=5  TIP 21 bytes '没有给予道具。'
```

Không có `GCDetailExp`, `GCMissionRemove`, `GCMissionHaveDoneFlag` (so với lượt nộp 1403 thành công có đủ cả bốn).
Nhiệm vụ nằm lại trong nhật ký vĩnh viễn → chuỗi dừng.

**Nguyên nhân gốc [DK]:** `GameServer/lualib/script_base.lua:3171 EndAddItem` — khi `#self.add_item_list == 0`
nó rơi xuống nhánh `human:notify_tips("没有给予道具。")` và **`return false`**. `edali_newquest_009:OnSubmit`
(cũng như mọi script cùng khuôn) bọc toàn bộ phần thưởng + `DelMission` + `MissionCom` + gọi nhiệm vụ kế tiếp
trong `if ret then`, mà 1408 có `g_ItemBonus = {}` và `g_RadioItemBonus = {}`.

**Vá (đã áp dụng, đã nạp sau restart 15:32):** `Game_2/Script/scripts/event/dali/edali_newquest_009.lua` — chỉ
gọi `EndAddItem` khi `next(self.g_ItemBonus) ~= nil`, vẫn gọi `BeginAddItem` để xoá danh sách cũ. **Không** sửa
`script_base.lua` (ngoài phạm vi ghi, và 57 script khác gọi chung — xem mục 4.3 vì sao chỗ vá này là đúng).

**Xác nhận sau vá [LIVE]** (`v1-submit-1408`, đúng lệnh đã hỏng ở `t16b`/`t17`): sau `CGMissionSubmit` server trả
`GCDetailExp` + **`GCMissionRemove`** + **`GCMissionHaveDoneFlag`** + `GCScriptCommand cmd=5`
"Hoàn thành nhiệm vụ: Quái nhân Đại Lý" + **`GCScriptCommand cmd=1` của nhiệm vụ kế tiếp** (script 210280,
mission 1423). Mongo: `attrib.jiaozi` **28 883 747 → 28 883 847 = +100** (đúng `g_MoneyJZBonus = 100`),
`mission_data.char_missions` không còn 1408, cờ đã-xong 1408 bật.

**Kiểm offline (không cần server):** `Build/Logs/2026-09-17-quest-live/scripts/test_endadditem_fix.lua` chạy bằng
`lua5.4`, stub `script_base` mô phỏng đúng "danh sách rỗng → `EndAddItem` false". Bản đã vá **8/8 ok**; bản gốc
(thư mục backup) **6/8 FAIL** (không `DelMission`, không `MissionCom`, không gọi 210280).

### 4.3 Phạm vi thật của lỗi 4.1 — vì sao không cần sửa `lualib`

`Build/Logs/2026-09-17-quest-live/scripts/scan_endadditem.py` quét **toàn bộ** `Game_2/Script/scripts`
(184 file có gọi `EndAddItem`). Cách đọc: so **đường khối** (`if`/`for`/`while` lồng nhau) của mỗi `AddItem` với
đường khối của `EndAddItem`; một `AddItem` chắc chắn chạy khi tới được `EndAddItem` ⇔ nó nằm dưới đúng những
guard ấy (hoặc chỉ thêm `for ... pairs(g_X)` với `g_X` khai báo **không** rỗng).

| Nhóm | Bản gốc | Sau vá |
| --- | --- | --- |
| **CHẶN CHẮC CHẮN** (danh sách chắc chắn rỗng) | **1 hàm**: `edali_newquest_009:OnSubmit` (mission 1408) | **0 hàm trong toàn cây** |
| CHẶN TÙY LƯỢT (mọi `AddItem` nằm trong nhánh điều kiện) | 17 hàm, 6 thuộc script nhiệm vụ | như cũ |
| An toàn / không gated | 125 + 90 hàm | như cũ |

Năm nhiệm vụ thuộc nhóm "tùy lượt" (bỏ 009 đã vá): **648** `exihu_648`, **442** `edali_zhidao_0202`,
**443** `edali_zhidao_0203`, **41** `jvqing/yipin_02`, **43** `jvqing/yipin_04`. Cả năm đều có dạng
`for item in pairs(g_RadioItemBonus) do if item.id == selectRadioId then AddItem ... end end` — nếu client gửi
`select_radio_id` không khớp món nào thì danh sách rỗng, `EndAddItem` false, người chơi nhận thông báo **sai**
"Túi đã đầy, không thể hoàn thành nhiệm vụ" và nhiệm vụ không nộp được. **[SL]** chưa đo live. Đây là lỗi
*chọn thưởng* của từng script, sửa ở `script_base.lua` cũng không đúng chỗ.

⇒ **Chỉ 1 nhiệm vụ bị chặn chắc chắn trong toàn bộ cây script** ⇒ vá tại script nhiệm vụ là đúng chỗ; không cần
mở phạm vi sang `lualib/script_base.lua`.

**Phạm vi (đối chiếu server gốc):** lỗi **có sẵn ở server gốc** `/home/ubuntu/Game_2` — thư mục `event/dali` của
hai server giống hệt nhau (`diff -rq` rỗng).

### 4.2 Sai biến thưởng tiền ở 1407

`edali_newquest_008.lua:109` viết `self:AddMoneyJZ(selfId, self.g_ExpBonus)` trong khi điều kiện bao quanh là
`if (self.g_MoneyJZBonus > 0)`. Đo live: giao tử **28 879 187 → 28 883 747 = +4560** = đúng `g_ExpBonus`, không
phải `g_MoneyJZBonus = 30` **[LIVE]**. Đã sửa thành `g_MoneyJZBonus`. Lỗi cũng có ở server gốc; đây là chỗ duy
nhất trong toàn bộ `event/` có khuôn sai này.

**Cơ sở của con số 30 — nói thẳng: đây là SUY LUẬN, không phải số tra bảng.**

- **[DK]** chính file khai báo `edali_newquest_008.g_MoneyJZBonus = 30`, và câu lệnh nằm trong
  `if (self.g_MoneyJZBonus > 0) then` — guard đọc đúng biến đó, tức tác giả định dùng nó.
- **[DK]** 18 script khác dưới `event/` dùng khuôn chuẩn `AddMoneyJZ(selfId, self.g_MoneyJZBonus)`.
- **[DK]** hàng xóm cùng chuỗi: 004 = 30, 005 = 30, 006 = 30, 007 = 30, 009 = 100, 010 = 300 → 30 hợp dải.
- **[DK] KHÔNG có nguồn dữ liệu xác nhận:** `configs/Mission_KillMonster.txt` có cột `金钱奖励` nhưng **không có
  dòng** cho mission 1403/1407/1408 (bảng đó dành cho nhiệm vụ vòng lặp sinh tự động, không phải nhiệm vụ kịch
  bản). Trong dự án không có bản dump nhiệm vụ CY để đối chiếu.
- ⇒ "**4560 là sai**" là kết luận chắc (4560 chính là `g_ExpBonus`, đặt trong nhánh guard của biến khác).
  "**30 là đúng**" chỉ là giá trị tác giả khai báo — **[SL]**. Hoàn tác một dòng:
  `cp backups/quest-live-20260917/edali_newquest_008.lua Game_2/Script/scripts/event/dali/`.

## 5. Những chỗ *không* sửa (có bằng chứng, cần người điều phối quyết)

1. **`scene:CheckSubmit` quá dễ dãi.** `Game_2/Script/scripts/scene.lua:534` chỉ kiểm "đang có nhiệm vụ và chưa
   hoàn thành" rồi trả 1 — **không** đọc param 0. 57 script gọi nó, nên mọi nhiệm vụ dùng nó đều nộp được ngay sau
   khi nhận (đo live: 1403 hiện `done=1` ngay lúc `p0=0`; 1405, 1407 nộp được dù chưa làm gì). File này **giống
   hệt** bản server gốc → là hành vi thượng nguồn, không phải hồi quy của dự án. Sửa nó ảnh hưởng 57 script nên
   để lại cho người điều phối quyết.
2. **EXP không bao giờ tăng cho nhân vật test.** `human:add_my_exp` (human.lua:3571) kẹp
   `exp = 4 * player_exp_level[level]`; `PlayerExpLevel.txt` cho `level 15 = 5847` → trần **23 388**, đúng bằng
   exp hiện tại của CYTest01/CYTest02. Mỗi lần cộng EXP server gửi tip `#{DNS_211124_54}` (thấy trong fixture
   `u5`). Ngoài ra `if exp >= level_exp and level < 10` nghĩa là **không nhân vật nào lên cấp bằng EXP từ cấp 10
   trở lên**. Nằm ngoài phần nhiệm vụ của human.lua → chỉ báo cáo. ⇒ **Đừng dùng EXP làm bằng chứng thưởng**;
   dùng `attrib.jiaozi` và `prop_bag_list` (đã làm).
3. **Quái của hai nhiệm vụ không tồn tại trong cảnh đang bật:** 蜀道白猿 (1407) chỉ có ở `jiange_monster.ini`
   (cảnh 7, `active=0`); 木头人 (1420) chỉ có ở `newbie_1_monster.ini` (cảnh 50/61/81, đều `active=0`).
   1407 vẫn nộp được nhờ mục 5.1; **1420 thì không**, vì `CheckSubmit` của nó tự kiểm param 1 == 5. Muốn chuỗi
   chạy tới 1422 thì phải bật cảnh (`configs/SceneInfo.ini`) hoặc đổi điều kiện — cả hai đều ngoài phạm vi ghi
   của lượt này.
4. **Tip lỗi còn chữ Trung:** `没有给予道具。`, `背包空间缺少:`, `第N个道具…` trong `script_base.lua` chưa dịch —
   người chơi Việt gặp nguyên văn chữ Trung khi túi đầy hoặc gặp lỗi 5.1.

## 6. Cách đo lại

`Build/Logs/2026-09-17-quest-live/scripts/quest_turn.ps1` — một lượt = một phiên bot, khoá theo tài khoản
(`Build/<account>.lock`, cùng quy ước `menpai_check.ps1`), đọc Mongo trước/sau (chỉ đọc), cắt đoạn log server của
lượt, tự thử lại tối đa 4 lần khi bị `connection refused` (server còn giữ phiên vài chục giây sau khi bot thoát).

```powershell
cd C:\TLBB\085\CY-Source
$t = '.\Build\Logs\2026-09-17-quest-live\scripts\quest_turn.ps1'
# nhận nhiệm vụ
& $t -Name x-accept -Account test01 -Guid 200002 -BotArgs @('--talk','254,174','--talk-scene','2','--quest','accept','--quest-script','210257')
# làm điều kiện (đi Vô Lượng Sơn giết quái) + ghi fixture
& $t -Name x-kill   -Account test01 -Guid 200002 -DwellMs 45000 -BotArgs @('--goto','304,149','--hunt','45,152','--attack','6','--record','1')
# quay về + nộp
& $t -Name x-submit -Account test01 -Guid 200002 -DwellMs 45000 -BotArgs @('--goto','32,176','--talk','254,174','--talk-scene','2','--quest','complete','--quest-script','210257')
```

- `scripts/quest_inspect.py --guid G [--out F]`: đọc Mongo **chỉ đọc** — cấp, exp, giao tử, cảnh, vị trí,
  `mission_data.char_missions` (id/script/yFlag/params) và cờ `mission_have_done_flags` 1400..1470, kèm túi đồ.
- `scripts/decode_scriptcmd.py <fixture.bin>`: in mọi `GCScriptCommand` (397) trong fixture PGWORLD1 —
  cmd 0 (menu + mục), cmd 5 (tip). Dùng để lấy nguyên văn chuỗi server gửi.
- **Bot phải là `Build\bot-17-09\CysNetBot.exe`** (bản duy nhất nhận `--account test01..test15`). Không cần thêm
  lệnh mới cho nhiệm vụ: chia "nhận → làm điều kiện → nộp" thành ba phiên là đủ, vì `mission_data` nằm trong Mongo
  và sống qua đăng xuất.

## 7. Bẫy

1. `--goto` của bot chỉ áp dụng ở **cảnh đầu tiên của phiên** (`generation == 1`). Sau khi qua cổng, muốn đi tiếp
   phải dùng `--hunt` hoặc bước quest `--talk` (bước quest kiểm `--talk-scene` trước khi đi).
2. Vùng về Đại Lý là **(29..35, 170..182)**, không phải cái bàn ở (38,176) — xem mục 3.
3. `--quest complete` dừng nếu cmd 3 trả `done != 1`; với chuỗi này `done` hầu như luôn = 1 vì mục 5.1.
3b. **Bước "nhận / giao vật phẩm" của nhiệm vụ là MỘT MỤC TRONG MENU, không chạy khi chỉ thoại.** Với 1423:
   thoại 黄公道 chỉ ra menu `210280/3/t2`; phải `--talk-option 3` mới nhận được 3 vật phẩm
   (40004514/15/16, `p1 0→1`). Thoại 小乞丐 (250,271) ra `210280/4/t2`; `--talk-option 4` mới trừ đủ ba món và
   đặt `p0 = 1` (ba tip "Tặng màn thầu/Y phục/cuốc…"). `--talk-option` của bot sau đó chờ đổi cảnh 25 s rồi báo
   "no transfer" — **vô hại**, `CGEventRequest` đã gửi và server đã xử lý; đọc `state-after.json` để xác nhận.
4. Bot chọn `radio` = id vật phẩm đầu tiên có `flag == 4` trong cmd 4; với 1401 (6 vũ khí) nó lấy món đầu
   (10101000). Muốn món khác thì phải thêm tuỳ chọn cho bot.
5. Đăng nhập lại cùng tài khoản quá sớm → `connection refused`; `quest_turn.ps1` chờ 90 s rồi thử lại.
6. NPC 黄公道 ở **(254,174)**, không phải (238,171) như `g_Position`/`g_SignPost` của script.
7. Sửa script Lua của server **không có tác dụng cho tới khi restart**: `scriptenginer` cache instance trong
   `self.scripts[id]`, và `reload_scripts` tuy tồn tại (`lualib/scriptenginer.lua:54`) nhưng **không có chỗ nào
   trong `services/` gọi tới** — không có lệnh reload cho người vận hành. (Đã xác nhận: cùng một lệnh bot hỏng
   trước restart 15:32 và chạy đúng ngay sau đó, không đổi gì khác.)
8. Bốn file `edali_newquest_{015,019,022,023}.lua` **không gán `script_id`** và `019` gán trường lên biến lớp
   `edali_newquest_018`. Vô hại — `try_load` ghi đè `script.script_id = id` theo `scripts/scripts.lua`. Đừng
   "sửa" chúng khi chưa đọc `scriptenginer.lua`.
