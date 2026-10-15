# impact-logic — cài logic impact CY còn thiếu (buff rỗng + chưa cài) theo mã CY

Ngày: 15/09/2026. Agent `impact-logic`, nhánh `impact-logic`, worktree `Build\wt-impact-logic`.
Tiếp nối `server-impact_vi.md` (đọc mục 0–2 trước). Bằng chứng RE: `Build\re\impact-logic\`; log: `Build\Logs\2026-09-15-impact-logic\`.

Quy ước: **[DK]** dữ kiện đo (đường dẫn/offset). **[SL]** suy luận. Server riêng `R = /home/ubuntu/cys-test-20260913`.

## 0. Kết quả

| Việc | Trạng thái |
|---|---|
| Nghĩa từng logic theo CY | Đã bẻ **mã logic của CY** (không chỉ mô tả): dựng lại bảng symbol ELF64 còn sót của `tlbb15/Server/Server` (e_shoff=0, 27.105 symbol) + `nm -D Serverhook.so` (1.367), decompile Ghidra headless mọi `StdImpactNNN_T` phương thức ảo (logic 0–189). Bằng chứng: `Build\re\impact-logic\{main-stdimpact-sel.c, hook-stdimpact149-189.named.c, stdimpact-methods.tsv, main-symbols.json, hook-symbols.json}` |
| Logic mới cài (module Lua thật) | **6 module**: `std_impact_098` (慈航普度 khiên nhóm), `101` (怒火连斩 đếm đao + 加速BUFF), `102` (一日丧命散 AOE), `103` (横扫AOE), `155` (魂离魄散 AOE hồn), `169` (拘魂·命/金刚不坏 hồi máu-khí千分比 + 免疫率). `impactenginer.id_logic_module` +6 dòng |
| Kỹ năng 15 phái cấp 1–4 "không tác dụng" | **400 → 380** (tĩnh, cùng định nghĩa server-impact mục 1.5); "ok" 1.071 → **1.099** |
| Ô logic chưa cài của kỹ năng phái cấp thấp | **32 → 5** (còn 99 阳关三叠 ×4 = bẫy, 171 五绝计时 ×1 = đổi kỹ năng) |
| Test Lua offline | `server_impact_tests.lua` 14 → **18 ca**, 18/18 đạt (lua5.4, giả lập scene/skill/impactenginer) |
| Áp server riêng | **CHỜ agent `menpai-audit` xong** (đang đo live). Chưa áp lúc viết bản này |

## 1. Cách bẻ mã logic CY [DK]

`tlbb15/Server/Server` là ELF64 đã xoá section header (`e_shoff=0`) nên `nm/objdump` thường không đọc được. Bảng `.symtab` vẫn còn trong file: khôi phục bằng hai mỏ neo độc lập (theo `Tools/add-phai/import-cy-four/implementation/combat/recover_main.py`):
- offset `0x1CBEDFD8` = một entry symbol có `value=0xA64FAE size=169`;
- chuỗi `_ZNK…StdImpact148_T12InitFromData` trong `.strtab`, kiểm chéo `_Z9Float2IntIfEiT_` tại strtab+0x2FD4.
Quét ±24 byte ra 27.105 symbol → `main-symbols.json`. `Serverhook.so` còn `.dynsym` → `nm -D` ra logic 149–189 (`Impact_ModuleA::StdImpactNNN_T`).

Decompile: Ghidra headless (`Build\re\impact-logic\ghidra\`, script `DecompSel.java`) nạp:
- blob `PT_LOAD#1` VA `0x3f0000` của `Server` (BinaryLoader) → logic 0–148 (main),
- `Serverhook.so` (ELF, base `0x100000`) → logic 149–189 (hook).
Gắn tên hàm từ TSV rồi decompile; hook đổi `func_0x…` → tên PLT (`06-annotate.py`).

**Ánh xạ ABI → nghĩa CY:** mỗi logic đọc tham số qua `Impact_GetImpactDataDescriptorValueByIndex(imp, k)` (k = chỉ số 0..15 = 参数值 thứ k của dòng StandardImpact, đúng thứ tự nhãn `参数k说明`). Đối chiếu chỉ số k với nhãn CY trong `03-logic-survey.json` (khảo sát dòng SI theo logic). Các hook combat: `OnDamage` = phòng thủ (Lua `on_damages`), `OnDamageTarget` = tấn công (Lua `on_damage_target`), `OnActive/OnFadeOut/OnIntervalOver/OnDie/GetIntAttrRefix/OnFiltrateImpact` = trùng tên Lua.

## 2. 6 logic đã cài (module `Tools/server/server_impact_lua/.../impact_logic/`) [DK mã CY]

| Logic | CY | Nghĩa (theo mã) | Nhãn CY (chỉ số) | Hạn chế [SL] |
|---|---|---|---|---|
| 98 | 慈航普度 (峨嵋) | Bị đánh: chủ buff giảm `减伤率(自己)`; đồng minh trong `有效距离` giảm `减伤率(他人)`, phần `他人受到的伤害转移率` về chủ | 减伤率(自己)3, 减伤率(他人)1, 有效距离0, 转移率2 | Chuyển sát thương chưa áp (on_damages chạy trước số cuối); AOE `子效果` khi tan bỏ (dòng CY = -1) |
| 101 | 怒火连斩 (恶人谷) | Đánh trúng bằng kỹ năng thuộc `生效技能集合` → đếm đao, phát `加速BUFF` một lần; đạt `刀数上限` thì tăng sát thương | 加速BUFF0, 生效技能集合1, 刀数上限2 | % tăng sát thương native dùng tổng lũy tiến hệ số float chưa giải → dùng +刀数% |
| 102 | 一日丧命散 | Kích hoạt gửi `激活产生效果` cho chủ; khi tan quét AOE `扫描半径` gửi `消散效果` (chủ sống) / `死亡效果` (chủ chết) | 激活10, 消散8, 死亡6, 半径0 | Hai đợt native gộp 1 |
| 103 | 横扫AOE | Mỗi nhịp (`发作时间间隔`) quét địch `扫描半径` gửi `子效果1/2/3`; con logic 3 qua CombatCore | 子效果1..3 (6..8), 半径0 | như std_impact_086 |
| 155 | 魂离魄散 | Kích hoạt + khi chết: quét ≤6 địch quanh chủ gửi impact hồn | 死亡触发0, 一魂1… | Chọn ô hồn theo số buff集合 native → dùng ô 0 |
| 169 | 拘魂·命/金刚不坏/绝处逢生 | Mỗi nhịp hồi `回复千分比`×maxhp, `蓝量回复千分比`×maxmp, tự `扣血`; bị đánh miễn `免疫率`% | 回复0, 免疫1, 回调2, 蓝4, 扣血5 | — |

Còn `null_logic_buff` (buff rỗng, chỉ hiện icon) cho các logic native-nặng chưa port:
- **99** 阳关三叠: cần bộ theo dõi bẫy (logic 52 trap tracker, `StdImpact099_T::OnIntervalOver` tạo/đếm bẫy) — cơ chế đối tượng bẫy native.
- **171** 五绝计时: đổi kỹ năng theo thời gian (`LuaPacket::CharEx_Skill` + `OnMissionParamChanged`) — cần bảng đổi kỹ năng CY.
Hai logic này `cy_four_combat` có sẵn `capability[99]/[171]` qua donor 8000+ nếu cấu hình donor; dòng CY (<8000) hiện rơi buff — cần agent cy_four map donor.

## 3. Kỹ năng 15 phái cấp 1–4 (nhân vật cấp 1–30) [DK]

| | ok | một phần | không tác dụng | không ô impact |
|---|---|---|---|---|
| server-impact (trước) | 1.071 | 166 | 400 | 358 |
| impact-logic (sau) | **1.099** | 158 | **380** | 358 |

Còn lại của 380 "không tác dụng": **716 ô impact thiếu dòng** (cần nguồn StandardImpact CY thật — không bịa), **15 ô nhãn CY** logic kỹ năng đã cài không đọc (飞龙在天 logic 80 `|生效一次的附加效果` ×4; 含笑半步癫 logic 0 `…（对自己）` ×4; 中冲剑/灭此朝食 `效果作用对象`/`新增效果id`; 荡千军 logic 840 `瞬移BUFFid` ×4), **5 ô logic** 99/171 (mục 2).

## 4. Áp server riêng (bước 5) — CHỜ menpai-audit

Điều kiện: `git -C <server-impact worktree> log main..menpai-audit` có commit báo cáo cuối + `Timeline\handoff\menpai-audit.md` / `Docs\specs\server\menpai-audit_vi.md` tồn tại trên nhánh đó.
Khi đủ: `Tools\server\cys_server.ps1 backup` → `server_impact.py apply --staging <staging>` (idempotent, backup từng file) → commit git server riêng → `restart` CHỈ khi 0 client / `Get-Process Game` rỗng / 0 TCP 15733-15734 → chờ scene (≤900 s) → log 0 traceback → bot `Tests\net\run_core_live.ps1`/`run_skills_live.ps1` kiểm vài kỹ năng phái trước "không tác dụng".

Công cụ: `Tools/server/server_impact.py plan|apply|verify` (đã +6 logic trong `NEW_LOGICS`). `verify` kiểm GBK/tab/luac/test Lua 18 ca/logic đăng ký/SE.
