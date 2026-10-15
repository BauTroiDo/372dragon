# Luật chọn mục tiêu của kỹ năng — vì sao bot bị từ chối

Ngày 17/09/2026. Bằng chứng: `Build/Logs/2026-09-17-coord/pass13` … `pass16`.

Ba mã từ chối dưới đây chiếm **21/21** chiêu từng bị xếp "không kiểm được". Đọc mã trả về TRƯỚC
khi kết luận một chiêu hỏng — 19 trong 21 chiêu đó **vẫn chạy**, chỉ là phép đo thiếu điều kiện.

## 1. `−25 OR_NOT_ENOUGH_RAGE` — thiếu nộ khí (9 chiêu)

`services/scene/skill/condition_delplete_core.lua`, `CD_RageByRate:ConditionCheck`:

```lua
local rage = obj_me:get_max_rage()
local need = math.floor(rage * rate / 100)
if obj_me:get_rage() < need then  -- rate = 100 với nhóm này
```

Nhân vật test có `rage` 822–832 / `rage_max` 1000 ⇒ chiêu ăn **100 %** nộ luôn bị từ chối.
Cách đo: `char_menpai.py --rage 1000` / `menpai_check.ps1 -RageValue 1000`. Dấu hiệu đã thông:
`or_codes` đổi từ `-25x40` thành `-25x1 -6x1` (lần gửi ĐẦU thành công và tiêu hết nộ).

Chín chiêu: 299, 359, 389, 419, 479, 539, 779, 3449, 4540.

## 2. `−16 OR_WARNING` — sai phe (9 chiêu)

`lualib/skillenginer.lua:251-254` → `taget_loigc_condition_check` (188-202):

```lua
elseif (target_logic_by_stand == 0 and obj_me:is_friend(obj_tar)) then condition_ok = true
```

`target_logic_by_stand == 0` đòi mục tiêu **cùng phe**; bot mặc định bắn vào **quái** nên không bao
giờ hợp lệ. `services/scene/obj/character.lua:1078` có `if self == other then return true`, nên
**bắn vào chính mình là hợp lệ**: `menpai_check.ps1 -TargetSelf` (`--cast <id>,-1`).

Chín chiêu: 288, 302, 318, 332, 452, 482, 512, 3802, 4517.

### 2.1 826 中冲剑·刃影 — cơ chế ĐÚNG, không phát, và KHÔNG đo được bằng bot hiện nay

Đây là chiêu hay bị hiểu nhầm là hỏng. `skill_cy_spec` khối 208 in ra đủ bốn dòng:

```
[skill_cy_spec] 208 he 冰 抗性 60 减抗 0 cap 2 chieu 471 -> bo
   (y hệt cho 火/463, 电/481, 毒/487)
```

`apply_resist_cast` ĐƯỢC GỌI, đọc đúng bốn cặp `get_defence_X` / `get_reduce_def_X`, đúng cấp, chọn
đúng bốn chiêu con — và **không phát vì `60 > 0`**, tức **đúng luật của tip**. Quái có `def_* = 60`
(`MonsterAttrExTable`, 400/400 dòng); người tung có `reduce_def_* = 0`.

**Đã THỬ HAI HƯỚNG, cả hai KHÔNG đi được** (ghi lại để đừng ai thử lại):

1. **Đặt `attrib.reduce_def_* = 100` vào Mongo: VÔ TÁC DỤNG.** Không phải vì server ghi đè, mà vì
   `get_attrib` không bao giờ đọc bốn khoá đó từ bản ghi: `lualib/db/human_attrib.lua`
   `get_base_attrib` chỉ tra `lv1_attribs` → `not_gen_attribs` → `db_attribs` → `menpai_attribs`, và
   `reduce_def_cold` nằm trong **`menpai_attribs`** (tính từ `base_value_table` theo môn phái), KHÔNG
   có trong `db_attribs` lẫn `db_save_attribs`. Muốn nâng `减抗` phải qua **trang bị** mang
   `IATTRIBUTE_REDUCE_TARGET_COLD_RESIST` hoặc một impact, không phải qua bản ghi.
   (Đã gỡ bốn khoá thừa khỏi nhân vật test sau phép thử.)
2. **Nhắm một nhân vật chưa mặc đồ kháng** (`抗性 0 ≤ 减抗 0`): không được, vì 826 có
   **`target_logic_by_stand = 1` (đòi ĐỊCH)**, nên bắn vào đồng minh sẽ bị `−16`. Muốn làm phải có
   **PK giữa hai bot**, mà `CysNetBot` hiện chưa có nhánh PK (đó là của bot cũ `BotDemo`).

⇒ Kết luận đúng mực: **826 không phải lỗi**; nó chỉ không quan sát được bằng bàn đo hiện nay.
Đừng xếp nó chung với những chiêu thiếu dữ liệu.

## 3. `−8 OR_INVALID_TARGET` — mục tiêu phải ĐANG CHẾT (2 chiêu)

`services/scene/skill/base.lua` (khối `target_check`):

```lua
local must_in_special_state = skill_info:get_target_must_in_special_state()
if must_in_special_state == 0 then
    if not obj_tar:is_alive() then ... OR_TARGET_DIE ... end
elseif must_in_special_state == 1 then
    if obj_tar:is_alive_in_deed() then
        params:set_errcode(enum_OPERATE_RESULT.OR_INVALID_TARGET)   -- −8
        return false
    end
```

`目标必须处于特殊状态 = 1` nghĩa là mục tiêu **phải đang chết**. Đúng với hai chiêu hồi sinh của
峨嵋: **408 起死回生** và **423 金针渡劫**. Vì vậy cả hai từ chối bản thân (đang sống) **và** từ chối
một đồng minh còn sống — `pass16` đã đo: nhắm `ally` (đồng minh máu 500/2250) vẫn trả `−8`.

Đây là lý do −8 KHÔNG cùng loại với −16: cổng phe đã qua, cổng trạng thái mới chặn.

### 3.1 Công cụ đã có

`CysNetBot --cast SKILL,ally` và `--cast SKILL,corpse` (thẻ `CYS-ALLY`) chọn **người chơi KHÁC**
gần nhất, còn sống hoặc đã chết; `WorldModel::nearestPlayer(dead)`. Đích được giải LẠI mỗi lần thử
vì bot thứ hai có thể chưa vào cảnh. Đã chứng minh chạy đúng: lượt 423 khoá và tung vào đồng minh
thật (server trả −8, không phải "không tìm thấy mục tiêu"), lượt 408 dừng đúng lý do
`no dead player in the scene`.

### 3.2 VIỆC CÒN LẠI: làm cho bot bệnh nhân CHẾT

Đây là thứ duy nhất còn thiếu để đo nốt 408 và 423. Đã thử và **thất bại**: đặt `attrib.hp = 1` rồi
cho bot `--attack 3` ở Vô Lượng Sơn — bot **giết 3 quái, `damage_taken = 0`**, không chết (quái ở đó
18 HP và bị hạ trước khi kịp đánh trả). Hướng còn lại, chưa thử:

- **Hướng gọn nhất, dùng chính một lỗi đã đo được:** agent `item-live` chứng minh **phù hồi thành**
  `30501004/5/6` nay **đánh chính người dùng** (`selfId`) thay vì dịch chuyển — đo live HP 2250 → 2219,
  tức **−31**. Vậy đặt `attrib.hp = 1` cho bot bệnh nhân rồi cho nó `--use 30501004` là **chết chắc**,
  không phụ thuộc quái. Cần: có món đó trong túi (mua 100 vàng ở 郎夫人 Lạc Dương (159,288) shop 32,
  hoặc ghi thẳng vào `prop_bag` — cấu trúc ô túi đã được `item-live` chứng minh qua phép nhặt đồ).
  Phù có thời gian niệm ~10 s nên bot thứ hai phải chờ quá mốc đó rồi mới tung `408,corpse`.
- cho bot bệnh nhân đi map cấp cao rồi `--hunt X,Z` vào quái đủ mạnh;
- hoặc PK giữa hai bot (`pk_mode=PERSONAL` + map dã ngoại, xem bộ nhớ `tlbb-bot-brawl-pk`) —
  `CysNetBot` hiện **chưa** có nhánh PK, đó là của bot cũ `BotDemo`.

Lưu ý khi làm: nếu bot bệnh nhân chết thật thì đối tượng của nó có còn trong AOI dưới dạng "xác"
hay bị xoá khỏi cảnh (trạng thái hồn) là **chưa biết**. `nearestPlayer(dead)` lọc theo
`hpPercent == 0`, nên nếu server xoá đối tượng thì phải đổi cách tìm (đọc `GCPlayerDie` rồi giữ id).

Khi có xác thật, `--cast 408,corpse` và `--cast 423,corpse` là đủ để chốt hai chiêu cuối cùng.

### 3.3 ĐÃ ĐO ĐƯỢC (17/09 17:30) — cần đúng BỐN điều kiện

Sau bốn lượt hỏng, đây là công thức chạy được. Thiếu bất kỳ điều nào là "no dead player in the scene":

1. **Có xác thật.** `attrib.hp = 1` + phù hồi thành `30501004` trong túi (`Tools/server/give_item.py`)
   + bot `--use 30501004`. Phù nay đánh chính người dùng nên chết chắc, không phụ thuộc quái.
2. **Xác phải NẰM LẠI.** `services/scene/ai/human.lua` `push_command_die_result` gọi `relive()` ở
   **mọi** nhánh resultcode, và hồi sinh xong thì nhân vật rời cảnh về điểm hồi sinh (đo được:
   `died 11766 ms -> CGAskChangeScene 6->1500`). Không có mã nào nghĩa là "cứ nằm đó", nên cách duy
   nhất là **không trả lời gì cả**: `CysNetBot --stay-dead 1`.
3. **Thầy thuốc phải vào cảnh TRƯỚC khi bạn chết.** Người đã chết KHÔNG xuất hiện trong AOI của
   người mới vào: vào sau 32 s thì thấy **0** người chơi. Vào trước thì thấy bạn lúc còn sống
   (`hpPercent 1`) rồi thấy tụt về 0.
4. **Chờ đủ lâu.** Bạn cần ~12 s để đăng nhập + vào cảnh, phù niệm thêm ~10 s. Đích `ally`/`corpse`
   nay chờ tới **60 s**.

Kết quả **408 起死回生**: `cast_target = 413` (đúng id của xác), **0 mã từ chối** (`last_operate = 0`,
hết hẳn `−8`). Gói đo được ở phía thầy thuốc: `GCCharSkill_Gather` → `GCCharSkill_Send` +
`GCCharDirectImpact` + **`GCDetailHealsAndDamages`**; phía xác nhận được `GCCharSkill_Send`,
`GCCharDirectImpact`, `GCTargetListAndHitFlags` và **`GCPlayerDie` LẦN HAI** lúc 22352 ms.

⇒ **Chiêu chạy.** `player_relives = 0` vì bước cuối là **người chết tự chọn hồi sinh**
(`GCPlayerDie` lần hai chính là lời mời đó; `push_command_call_of_result` / `CGPlayerDieResult`),
mà bot đang ở `--stay-dead` nên cố ý không trả lời. Đó là hành vi người chơi, không phải lỗi chiêu.
Muốn đóng trọn vòng thì thêm một chế độ "nằm chết nhưng CHẤP NHẬN lời mời hồi sinh đến sau".

### 3.4 Kết quả **423 金针渡劫** — rõ hơn cả 408

Cùng công thức, lượt `pass24`:

```
cast 423 (target=corpse): self_skill_sends+1  cooldown_entries+1
                          cooldowns=[72:600000ms]  last_operate=0
recast:                   last_operate=-6 (hồi chiêu)   cast_target=415  (đúng id của xác)
gói: GCCharSkill_Gather, GCCharSkill_Send x2, GCCharDirectImpact x2,
     GCDetailHealsAndDamages, GCTargetListAndHitFlags
```

Ở đây **chính bot cũng ghi nhận `self_skill_sends + 1`** và chiêu vào hồi 10 phút — đủ điều kiện
`chay` theo đúng luật phân loại của `aggregate_check.py` (`sends && eff`).

### 3.5 Cách đếm cho trung thực

Hai chiêu này **không** đo bằng `menpai_check.ps1` (bàn đo một bot), nên chúng **không** xuất hiện
trong `96-best-of.tsv`. Vì vậy con số nên nói thành hai phần:

> **209/220 do bàn đo một bot** + **2 chiêu (408, 423) chứng minh riêng bằng lượt hai bot** = **211/220**.

Đừng sửa tay `96-best-of.tsv` cho đẹp số: bảng đó là kết quả của công cụ, sửa tay là mất giá trị đối chứng.
Muốn gộp thì phải cho `menpai_check.ps1` biết chạy hai bot, và đó là việc riêng.
