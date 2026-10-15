# Vòng lõi G2: chat, chọn mục tiêu, đánh thường/kỹ năng, nhặt đồ, túi, thuộc tính — 14/09/2026

Tiếp nối [world-session_vi.md](world-session_vi.md) (vào cảnh, đi, đổi cảnh, thoát) và [world-replay_vi.md](world-replay_vi.md). Phần này đặc tả và triển khai **vòng lõi** của client mới trên giao thức skynet của server riêng (`/home/ubuntu/cys-test-20260913`, login 15733 / game 15734): sau khi vào cảnh, nhân vật chat, chọn mục tiêu, đánh thường hoặc dùng một kỹ năng, quái mất máu và chết, hộp rơi hiện ra, nhặt đồ, xem túi, nhận cập nhật máu/kinh nghiệm/thuộc tính, chết và hồi sinh tối thiểu. ID gói giữ ID skynet (`Docs/specs/cy-switch_vi.md` mục 4.5, `Registry/protocol/packets.yaml`, codec `Src/Shared/ProtocolGen`). Mọi sửa trong Game.exe gắn `// CYS-CORE:`.

Ký hiệu: **[DK]** dữ kiện đọc từ mã server/0.85/bảng; **[SL]** suy luận chưa kiểm live; **[LIVE]** đã thấy trên server riêng bằng bot.

## 1. Tóm tắt wire

| Hành động | Client → server | Server → client | Handler 0.85 port | Trạng thái |
| --- | --- | --- | --- | --- |
| Chat | 753 `CGChat` | 790 `GCChat` (scene broadcast gồm cả người nói) | `GCChatHandler` → `Talk::HandleRecvTalkPacket` | port xong, loopback ĐẠT |
| Chọn mục tiêu | 372 `CGLockTarget` | không trả lời (server `set_locked_target`) | `CGLockTarget` gửi từ `CObjectManager::SetMainTarget` | dịch xong |
| Đánh thường / kỹ năng | 83 `CGCharUseSkill` (skill 0 = đánh thường) | 331 `GCCharSkill_Send`, 909 `GCTargetListAndHitFlags`, 1692 `GCDetailHealsAndDamages`, 455 `GCCharBaseAttrib` (hp_percent), 802 `GCCharSkill_Missed`, 676 `GCCharDirectImpact`, 7 `GCOperateResult` khi từ chối | `GCCharSkill_SendHandler`, `GCTargetListAndHitFlagsHandler`, `GCDetailHealsAndDamagesHandler`, `GCCharSkill_MissedHandler`, `GCCharDirectImpactHandler`, `GCCharSkill_Gather/LeadHandler` | port xong |
| Quái chết, hộp rơi | — | 455 (hp 0), 1694 `GCNewItemBox`, 582 `GCDelObject` | `GCNewItemBoxHandler` (AddDropBoxEvent / tạo `CTripperObject_ItemBox`) | port xong |
| Mở hộp, nhặt | 1266 `CGOpenItemBox`, 1155 `CGPickBoxItem` | 675 `GCBoxItemList`, 113 `GCPickResult`, 623 `GCItemInfo`, 582 khi hộp rỗng | `GCBoxItemListHandler`, `GCPickResultHandler`, `GCItemInfoHandler` | port xong |
| Túi | 170 `CGAskMyBagList` (ASK_ALL) | 263 `GCMyBagList`; từng ô đổi bằng 623 `GCItemInfo` | `GCMyBagListHandler`, `GCItemInfoHandler` | port xong |
| Kỹ năng đã học | 1252 `CGAskDetailSkillList` | 55 `GCDetailSkillList` (mảng u32 SkillData id) | `GCDetailSkillListHandler` | port xong |
| Thuộc tính / máu / kinh nghiệm | 404 `CGCharAskBaseAttrib`, 678 `CGAskDetailAttrib` | 455 `GCCharBaseAttrib`, 1772 `GCDetailAttrib` (exp, hp, hp_max…), 1288 `GCDetailExp`, 843 `GCLevelUp` | `GCCharBaseAttribHandler`, `GCDetailAttribHandler` (đã có), `GCLevelUpHandler` | 843 port xong; 1288 chỉ đếm |
| Chết / hồi sinh | 1770 `CGPlayerDieResult` {code: 0 thả hồn, 1 nhận hồi sinh} | 508 `GCPlayerDie` {new_player, can_relive, 0, utime}, 431 `GCPlayerRelive` (rỗng) | `GCPlayerDieHandler` (GE_RELIVE_SHOW), `GCPlayerReliveHandler` (GE_RELIVE_HIDE + `EndOutGhostTimer`) | port xong |

`GCItemList` (1267) **không** phải gói túi: server chỉ dùng nó cho danh sách sạp/cửa hàng người chơi (`item.lua:751`, `OPT_ADD_ITEM_LIST` + `GCPlayerShopItemListForSelf_t`). Túi của nhân vật đi bằng 263 + 623 **[DK]**. Lỗi `self.type`/`write` thiếu độ dài của 1267 (TIMELINE việc 5) vẫn ở nhánh `OPT_ADD_ONE_ITEM`/`TYPE_ITEM`, không chạm vòng lõi.

## 2. Bố cục trường (packets.yaml + Lua server)

### 2.1 Chat

- **753 `CGChat`** (`social.lua:59` bis): `ChatType u8`, `Contex str32` (u32 độ dài + UTF-8), `unknow_7 str8` (rỗng), `unknow_8 u32`, `unknow_9 u8`, `unknow_10 u32`, nhánh theo `ChatType` (0 NORMAL: `unknow_2 u16`; 1 TEAM: `teamID u16`; 3 TELL: `TargetName str8` + `u16`; 18 MAIL: `dest_guid i32`; 11 CITY: `city i32`…), rồi `uts[3] u8` (1 = link vật phẩm `guid 6 B`, 2 = link thú `PetGUID`, 6 = ngoại hình 67 B). Bot cũ (`tlbb_sim/packets.py cg_chat`) đã kiểm chứng bố cục này live 08/2026 **[DK]**. Client CY-Source dịch từ 0.85 `CGChat` (`GetChatType/GetContex/GetTargetName/GetTeamID`).
- **790 `GCChat`** (`social.lua:200` bos): `ChatType u8`, `Contex str32`, `SourceName str8` (≤30, GBK từ server theo `gbk.fromutf8` — trên server riêng tên và nội dung đi UTF-8 vì wire_charset đã đổi 24/08), `unknow_1 u32`, `unknow_2 u8`, `unknow_3 u32` (server đặt 1), `unknow_4 i16`, `unknow_5 u32`, `DestName str8`, nếu `ChatType` 0/26: `Sourceid u32` + `unknow_10 i16`; nếu 18/24: `Sourceid`, `mood str8`, `Destid`, … 
- Server `scenecore:char_chat` (`scenecore.lua:5992`): kiểm cấm chat, thay link `#{_INFOSER}`, `msg:set_content`, `set_source_name`, `Sourceid = obj_id`, `unknow_3 = 1`; NORMAL → `broadcast(obj, msg, true)` (**gồm cả người nói** → client thấy dòng của mình bằng echo, không tự thêm như 0.85 chỉ làm với TELL). `msgagent.lua:1484`: SCENE(2) giới hạn 150 s, MENPAI 150 s, CITY 10 s, MAIL cần hai chiều bạn.
- Port: 0.85 `GCChat` cần `m_CampID` để `CalcRelationType(camp gửi, camp của tôi) == RELATION_FRIEND`; gói CY không có camp → client mới đặt camp gửi = camp của MySelf (mọi chat nhìn thấy đều là bạn) **[SL nhỏ]**. Dòng hiện qua `GE_CHAT_MESSAGE` (ChatFrame Lua) và bong bóng đầu nhân vật (`SetPaoPaoTxt`).

### 2.2 Chọn mục tiêu, đánh thường, kỹ năng

- **372 `CGLockTarget`** (`combat.lua:66`): `target_id i32`. 0.85 gửi trong `CObjectManager::SetMainTarget` (click hoặc Tab `Debug_LockNearestTarget`, chọn địch trong 20 m theo `GetCampType == RELATION_ENEMY`). Server `set_locked_target`, không trả lời.
- **83 `CGCharUseSkill`** (`misc.lua:307` bis, 28 B): `dir f32`, `skillID i32`, `target i32`, `m_objID u32`, `targetObjID i32`, `posTarget.x/y f32`. Server `scenecore:char_use_skill` (`scenecore.lua:2235`) chỉ đọc `skillID`, `targetObjID`, `posTarget`, `dir`; `target` (0.85: GUID mục tiêu) bị bỏ. `skillID` là **SkillData id** = series×100+level; **0 = đánh thường** (`SkillData_V1` id 0, hồi 800 ms — bot cũ `skilldata.py NORMAL_ATTACK = 0`). Kiểm tra `have_skill` trên server đang bị comment; địa phủ/giám ngục/quy tắc PvP 0 chặn vài kỹ năng; kết quả lỗi → 7 `GCOperateResult {result i32}` (`define.lua OPERATE_RESULT`: -3 INVALID_SKILL, -4 TARGET_DIE, -16 WARNING, -42 NEED_LEARN_SKILL_FIRST).
- 0.85 client: `CAI_MySelf::SendUseSkillMessage` gửi `setSkillDataID(idSkill*100+nLevel)`, `IsCanUseSkill` cần `Get_Skill(id*100+level)` trong CharacterData → phải có 55 `GCDetailSkillList` trước; `Set_Skill(0,0)` là ngoại lệ id 0.
- Luật địch (**[DK]** `human.lua:4984 is_enemy`): quái có `reputation == 0` không phải địch; còn lại theo `CampAndStand.txt` (`calc_relation_type`): người camp 0/1 địch với camp 9/10; **camp 8 (NPC, kể cả 稻草人 trong `dali_new_320_monster.ini`) không đánh được**. Cảnh 2 `dali_new_320` không có quái camp 9; 无量山 (scene 6/73/74, `wuliang_monster.ini`) có 317 quái camp 9, gần cổng vào (43,172): type 900 lv1 HP 18 tại (45,150), (46,157), (45,145). Cổng đi bộ #9 tại (304,149) r=4 (`dali_new_320_area.ini`, script 400006 `echuansong_dali_wuliang.lua` → `TransferFunc(obj, {6,73,74} ngẫu nhiên, 43, 172)`).
- Phản hồi khi kỹ năng chạy (server `actionenginer.lua:427`, `skill/base.lua:1043`, `character.lua:1963`):
  - **331 `GCCharSkill_Send`** (26 B): `m_objID`, `logic_count`, `skill_id`, `target_id`, `target_pos`, 2 u8. 0.85: `OC_MAGIC_SEND` (hoạt cảnh phát chiêu). 696 `_Gather`/1170 `_Lead` (40 B: thêm `world_pos`, `dir`, `total_time`) → `OC_MAGIC_CHARGE/CHANNEL`.
  - **909 `GCTargetListAndHitFlags`**: `data_type u8` (0 UNIT_USE_SKILL, 1 SPECIAL_OBJ), `m_objID`, `logic_count`, `skill_or_special_obj_id`, `target_pos`, `unknow_1 u8`, `size u8`, `target_list u32[]`, `shenme i16`. 0.85: tra `SkillData` (bullet id, locator, select type) → `OC_LOGIC_EVENT` đạn tới từng mục tiêu.
  - **1692 `GCDetailHealsAndDamages`** (14–30 B): `dirty_flags u8` (1 hp, 2 mp, 4 rage, 8 strike), `reciver u32`, `sender i32`, `logic_count u32`, các `*_modification i32` theo bit, `is_critical_hit u8`. 0.85: `_DAMAGE_INFO TYPE_HEAL_AND_DAMAGE` → số sát thương bay lên, HP cục bộ.
  - **455 `GCCharBaseAttrib`** với bit `uFlags[0] & 0x10` = `hp_percent` (`monster_attrib.lua send_refresh_attrib` gửi khi HP bẩn): thanh máu mục tiêu. Đã có handler.
  - **802 `GCCharSkill_Missed`** (17 B: `reciver`, `sender`, `skill_id`, `flag i8`, `sender_logic_count`) → chữ "né/miss"; **676 `GCCharDirectImpact`** (18 B) → hiệu ứng.
- Chết: HP 0 → server `character:on_die` → `monster:on_die_after` → `dispatch_item_box` → `create_item_box` → **1694 `GCNewItemBox`** (28 B: `m_objID`, `owner_guid i32`, `monster_id i32`, `world_pos`, `item_box_type i32` (-1 = DROPBOX), `unknow_7`); xác bị **582 `GCDelObject`** sau hoạt cảnh chết. 0.85 `GCNewItemBoxHandler`: quái còn sống trên client → `AddDropBoxEvent` (hộp hiện sau hoạt cảnh chết), ngược lại tạo `CTripperObject_ItemBox` ngay; loại khác = `CTripperObject_Resource`.

### 2.3 Nhặt đồ, túi

- **1266 `CGOpenItemBox`** {`m_objID u32`} → server `char_open_box_item` → **675 `GCBoxItemList`** {`m_objID`, `size u8`, `item_box_type i16`, `item_list ItemInfo[]`} (`scenecore.lua:2370`).
- **1155 `CGPickBoxItem`** {`m_objID u32`, `item_guid ItemGUID`} → `char_pick_box_item` (`scenecore.lua:2392`): tìm theo GUID, xếp vào túi (chồng nếu `can_lay`), → **113 `GCPickResult`** (24 B: `m_objID`, `item_box_guid`, `result u8` (0 thành công, 2 lỗi), `bag_index u8`, `item_box_type i16`, `item_guid`) + **623 `GCItemInfo`** {`bagIndex i16`, `unknow_1 i32`, `item ItemInfo`, `askid u32`, `bag_type i32`} khi ô đổi; hộp rỗng → `recycle` → 582.
- **`ItemGUID`** CY (8 B): `world u8`, `server u8`, `mask u16`, `series u32`; 0.85 `_ITEM_GUID` = `world u8`, `server u8`, pad, `serial i32` → cùng 8 byte nhưng 0.85 không giữ `mask`; client mới lưu `mask` theo (world, server, serial) từ 675/263 để 1155 gửi lại đủ (`CysModernHandlers::ItemGuidMask`).
- **`ItemInfo`** (bos `item_types.lua:184`): đầu chung `guid 8`, `item_index i32`, `rule u8`, `status u8` (bit `IEL_CREATOR 0x10`), `unknow_4[12]` (= 0.85 `m_Param[3]` **[SL]**), rồi khối theo lớp `floor(item_index/1e7)`: 1 trang bị (`max_dur, slot_count, u8, dur, u16, attr_count, attr_values u16[], gem_count, list_2 i32[4], enhancement, diaowen, dmc, qualifications[6], quality, visual, attr_type u64, equip_type, …`), 2/3/4/5/6 = khối mờ 32/32/32/56/20 B, 7 thú cưng trang bị; đuôi `creator[32]` hoặc 22 B, `ling_yu_attrs[3]`, thú hồn, `unknow_44 u32`, `unknow_45 u16`. **Số lượng chồng** không nằm trong phần đã giải mã của 623/675 (server `copy_raw_data` đặt `data.count` nhưng bos không ghi trường tên đó) → client mới đặt 1; **263 `GCMyBagList`** {`m_Mode u32`, `m_AskCount u8`, `list[]{index u8, u8[3], guid, item_index u32, count u8, u8[3]}`} mới mang số lượng đúng **[DK]**.
- Chuyển `ItemInfo` → 0.85 `_ITEM` (`ToLegacyItem`): guid, index, rule, bind, param, creator; trang bị: `dur/max_dur/slot_count/gem_count`; thuốc/nguyên liệu: `m_nCount = 1`. Thuộc tính trang bị (`attr_values` u16 id không kèm giá trị 0.85 `_ITEM_ATTR`) chưa ánh xạ **[SL]**.
- **170 `CGAskMyBagList`** {`unknow_1 u32` = mode, `size u8`, `list u8[]`}; 0.85 `ASK_ALL` = mode 0, size 0. Server `msgagent.lua:634` → 263. **207 `CGAskMyBagSize`** → 143 `GCBagSizeChange` {`prop_size u8`, `material_size u8`}.

### 2.4 Thuộc tính, máu, kinh nghiệm, cấp

- 455 `GCCharBaseAttrib` (đã port): tên, cấp, hp/mp %, tốc độ…; 1772 `GCDetailAttrib` (đã port 14/09 sáng): `flags[22]`, `level`, `hp`, `mp`, `hp_max`, `exp` (bit `flags[1] & 8`), tiền, chỉ số; **1288 `GCDetailExp`** (44 B: `exp`, `award_exp`, `bb_exp`, `anqi_exp`…, `human.lua:3528`) chỉ đếm — 0.85 không có handler; **843 `GCLevelUp`** {`m_objID`, `level`} → `OC_LEVEL_UP` + âm 66.
- **85 `GCCooldownUpdate`** {`m_uHighSection`, `m_uLowSection` (pet guid), `m_nNumCooldown u16`, `{id i32, cooldown u32, elapsed u32}[]`} — chưa port (0.85 `CoolDownGroup_UpdateList` cần `Cooldown_T`); ghi nhận để làm sau.

### 2.5 Chết, hồi sinh

- **508 `GCPlayerDie`** (16 B: `new_player u32`, `can_relive u32`, `0 i32`, `utime u32`) chỉ gửi cho người chết → `GE_RELIVE_SHOW(can_relive, giây)`; Lua trả lời **1770 `CGPlayerDieResult`** {`code u32`}: 0 = thả hồn về điểm hồi sinh (`SendReliveMessage_OutGhost`), 1 = nhận hồi sinh tại chỗ; server `char_die_result` (`scenecore.lua:5908`) → **431 `GCPlayerRelive`** (rỗng) → `GE_RELIVE_HIDE`, `EndOutGhostTimer`. Bot tự trả lời 0 khi thấy 508.

## 3. Triển khai

- **NetCore** (`Src/Client/NetCore`):
  - `WorldModel`: theo dõi `hpPercent/level/name/model/camp` từng đối tượng, hộp rơi, hộp đang mở + món, túi, danh sách kỹ năng, chat cuối, kết quả nhặt, máu/exp/cấp của mình, bộ đếm mới (`chats, skillSends, damages, damageDealt, hpUpdates, targetDeaths, itemBoxes, boxLists, picksOk, itemInfos, bagLists, skillLists, playerDies…`); makers `makeLockTarget/makeUseSkill/makeChat/makeOpenItemBox/makePickBoxItem/makeAskMyBagList/makeAskDetailSkillList/makePlayerDieResult/makeMovePath`; `nearestMonster`, `nearestItemBox`.
  - `RecordStream`: bọc `StreamFactory` ghi mọi khung của socket game → fixture PGWORLD1 (`Recorder::writeFixture`, key CGConnect và key 280 bị xoá về 0). Socket login không bao giờ được bọc.
  - `ReplayStream`: `Options.coreLoop` bật **bộ trả lời tổng hợp** theo bố cục server: 372 ghi nhớ; 83 → 331 + 909 + 1692(-7) + 455(hp %) (3 đòn giết → 455 hp 0 + 1694 hộp tại vị trí quái ghi âm + 582 xác sau 1,5 s); 1266 → 675 (1 món 30001011 鸳鸯补血丹); 1155 → 113 + 623 (+582 hộp rỗng); 753 → 790 echo; 170 → 263; 1252 → 55 {0}; 1770 → 431. Vị trí quái lấy từ `GCNewMonster` của fixture.
- **Game.exe**: `CysModernGame::Translate` thêm 372/83/753/1266/1155/170/1252/1770; `CysModernHandlers` port 790/331/696/1170/802/676/909/1692/508/431/1694/675/113/623/263/55/843 (+7 ghi log), tất cả là gói thế giới (stash tới khi `WorldReady`). Log `CYS core:` cho từng gói (≤64 dòng).
- **Replay driver** (`CysWorldReplay`, `CYS_WORLD_REPLAY_CORE=1`): sau 3 cú click đi bộ: 1252 → `Debug_LockNearestTarget` (372) → 3× 83 (skill 0, gửi thẳng `Packets::CGCharUseSkill` qua `CNetManager::SendPacket`) → hộp → `Tripper_Active` (1266) → `ItemBox_PickItem` (1155) → `SendChatCommand` (753) → 170; PNG `core-target/core-hit/core-dead/core-loot/core-chat/core-bag`. `run_world_replay.ps1 -Core` thêm 13 phép kiểm.
- **Bot** `CysNetBot --mode world`: `--goto X,Z` (đi thẳng ≤16 điểm/gói; server riêng không kiểm tường từ 26/08 — `scenecore.lua char_move`), cổng → 809/414/280 tự động; `--chat`, `--attack N` (quái gần nhất còn máu, 372 + 83 mỗi 1,3 s tới khi 582/hp 0), `--pickup` (1266/1155 mọi món), `--bag` (170), `--record 1` (fixture `world_core_gN.bin` của socket có 1694/331), `--skill ID` (mặc định 0). Output thêm `core-loop.tsv` và khối `core` trong `result.json`. Thứ tự: vào cảnh → setup (404, 1252, 404 quái) → goto → chat → attack/pickup → bag → 1727.

## 4. Kiểm chứng

- `Tests/net/run_world_session_tests.py`: kịch bản loopback **`core-combat`** (fake server kiểm bố cục 372/83/1266/1155/753/170 byte-by-byte, trả khung do `cys_world_tests --fixture core-*` mã hoá bằng ProtocolGen), **`--replay-core`** (bộ trả lời trên fixture 27/08), bot **`bot-core`** (đầy đủ chat/attack/pickup/bag/record, kiểm `result.json` và hình dạng fixture ghi được). Kết quả ở `Build/Logs/2026-09-14-core-loop/`.
- Live: `Tests/net/run_world_live.ps1` (mật khẩu từ `.local/test-accounts.txt`) với bot core; xem handoff `Timeline/handoff/core-loop.md` về kết quả live.

## 5. Khác biệt CY / 0.85 đã ghi nhận

- 0.85 gửi GUID mục tiêu trong 83; CY dùng `targetObjID` và server bỏ `target`.
- 0.85 tự hiện dòng chat của mình chỉ với TELL; server skynet echo NORMAL cho cả người nói → không tự thêm nữa (tránh trùng).
- CY `ItemInfo` giàu hơn 0.85 `_ITEM` (linh ngọc, thú hồn, sáng tạo 32 B); 0.85 UI chỉ cần index/guid/bind/độ bền → chuyển tối thiểu.
- `GCDetailSkillList` CY là u32 SkillData id (0.85: `_OWN_SKILL` 8 B + level riêng).
- 稻草人 (bù nhìn) Đại Lý ở server riêng là camp 8 → không đánh được (bản CY gốc: bù nhìn tập luyện) **[DK bảng, SL hành vi CY gốc]**.
