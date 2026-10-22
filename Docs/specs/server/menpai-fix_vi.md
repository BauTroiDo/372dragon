# menpai-fix — sửa lỗi kỹ năng môn phái trên server riêng (15/09/2026)


## 0. Kết quả

| Việc | Trạng thái | Commit server (R) |
|---|---|---|
| Áp impact-logic (6 module 098/101/102/103/155/169) | **Đã áp**, `server_impact.py verify` OK, test 19/19 | `beeab01` |
| Lỗi 1 `skill_cy_generic` thiếu `IMPACT_NUMBER` | **Đã sửa** + test bắt được lỗi (trước sửa: hỏng, sau: đạt) | `203b30e` |
| Lỗi 2 `cy_four_combat/storage.lua:27` số phái GL 15/16 | **Đã sửa** → 13/14 | `d36ea18` |
| Lỗi 3 logic điều kiện CY 16–21 chưa đăng ký | **Đã cài theo mã tlbb15** (không bịa nghĩa), test 7/7 | `6ca25a8` |
| Restart | 18:16:05–18:16:34, gộp `db708f5` (npc-quest). 6/6 dịch vụ, 16/16 cổng, 0 traceback lúc khởi động | HEAD `6ca25a8` |
| Kiểm live lại | xem mục 5 | — |
| Lỗi 5 tu luyện (server) | **Không làm** theo lệnh người dùng 19:10; khảo sát + bố cục gói 1014 CY ghi ở mục 7 | — |
| Thay `IDCollections.txt` bằng bản CY | **Không thay**; bảng ảnh hưởng mục 6 | — |

Nhánh: `5d091910` (lỗi 1), `1abfd808` (lỗi 2+3), commit đặc tả/handoff cuối (xem handoff).

## 1. Áp impact-logic [DK]

`server_impact.py plan --out Build/Logs/2026-09-15-menpai-fix/impact-staging` → `apply --dry-run` đổi đúng 7 file (impactenginer + 6 module) + `skill_cy_generic.lua` (lỗi 1), 107 file không đổi → `cys_server.sh backup truoc-menpai-fix` (Mongo + manifest) → `apply` (sao lưu `R/backups/server-impact-20260915T111439Z/`) → commit → `verify --staging` OK (GBK/tab/ID, tham chiếu 100 % phân loại, logic đăng ký, luac, test Lua).

## 2. Lỗi 1 — `skill_cy_generic` thiếu `IMPACT_NUMBER` [DK]

- Nguyên nhân: `lualib/class.lua` `luaclass` chỉ chép **hàm** lớp cha; `skill_0.IMPACT_NUMBER = 17` và `skill_0.SkillInfoDescriptorIndex` là trường → nil ở lớp con → `skill_0.lua:72 for i = 1, self.IMPACT_NUMBER` sập sau khi đã trừ MP/đặt hồi chiêu.
- Sửa (`Tools/server/server_impact_lua/.../skill_cy_generic.lua`): chép mọi trường không phải hàm của `skill_0` mà lớp con chưa có (`rawget`). 17 = số ô `effect_once` mà `cfghelper.read_skill_data` điền (tối đa ô 17) ≥ 15 cặp `参数说明/参数值` của SkillData CY (đếm trên bảng server bố cục CY) → vòng đọc phủ đủ ô CY.
- Test: `server_impact_tests.lua` thêm ca "kế thừa trường không phải hàm qua class.lua thật" (mock `skill_0` giờ có `IMPACT_NUMBER` như bản thật). Chạy trên R trước sửa: **hỏng** (`IMPACT_NUMBER expected 17 got nil`); sau sửa 19/19.

### 4.2 Cài đặt
- `services/scene/skill/condition_cy.lua` (nguồn `Tools/server/menpai_fix_lua/`): 6 logic trên, `install(core)` đăng ký vào `condition_delplete_core.logics` (16 thay `C_UnitNotHaveImpact_T` — nghĩa GL cũ; 18 mới là "bản thân không có impact thuộc tập"). Tài nguyên dùng chung kho `cy_four_combat` (`human:get/set_cy_four_resource`, con rối `callbacks.get_doll_id`); tiêu hao đẩy vào hàng chờ `bridge.resources.pending` (kiểu 8016/8017) để `on_use_skill_successfully` trừ + hoàn talent như native; không có bridge thì trừ ngay.
- `condition_delplete_core.lua`: `self.logics[type] or self.cy_default_logic` (kiểu lạ → đạt như CDCore) + dòng `install`.
- `lualib/cy_idcollections.lua` (sinh máy): IDCollections **client CY 3.71** (522 dòng) + 10 dòng chỉ có ở tlbb15 (340–349; 340 = 桃花岛共情技能 {3806,3807,3809,3820,3822}). Lý do: bảng server riêng là bản HJS/GL (mục 6), SkillData CY trỏ tập CY (vd 376 {151} 九阴, 499 {2631} 九阳, 414 {9093} 拘魂·地, 426 {178} 移花接木, 511 {8919} 蒙面巾 — khớp nhãn SkillData).
- Hệ quả [SL→DK live]: 八列之舞 3801/六合同风 3818/解我心忧 3819 không thuộc 340 → không kiểm/không trừ 共情 (đúng mã); 谋动干戈 3807 cần con rối → bot không có con rối bị từ chối −44 (live: −44 ×40).
- Công cụ: `Tools/server/menpai_fix.py plan|apply|test` (idempotent, sao lưu `R/backups/menpai-fix-<UTC>/`, luac trước khi ghi), test `Tools/server/menpai_fix_tests.lua` 7/7.

## 5. Kiểm live lại (CysNetBot, cùng phân loại `30-aggregate.py` của menpai-audit)

Cách đo giống menpai-audit (`20-live.ps1` chép thành `Build/Logs/2026-09-15-menpai-fix/scripts/20-live-fix.ps1`, chỉ đổi thư mục log + tên khoá): mỗi lượt đặt lại phái/tâm pháp cấp 30/HP/MP → `CysNetBot --mode world --xinfa 1 --record 1 --cast S,0 --hunt 45,152` → log Game2 đúng phiên. Bảng: `scripts/30-aggregate-fix.py` (dùng `classify()` của menpai-audit; "sau" = kết quả audit, thay các kỹ năng chạy lại) → `aggregate-fix.json`, `30-aggregate-fix.out.txt`.
32 lượt, 18:19–20:11 (tạm dừng 19:02–19:16 nhường khoá; rút gọn theo lệnh người điều phối 19:18): mọi kỹ năng 桃花岛/绝情谷 từng lỗi (trừ 4534/4538), 17 kỹ năng có chữ ký lỗi 1–3 ở phái khác (một phần), 1 lượt ở mỗi phái chưa kiểm (0/1/2/3/8/10). **Log server Game2 từ restart tới 20:11: 474 dòng, 0 traceback** (`18-logscan.out.txt`); trước sửa mỗi phiên 桃花岛/绝情谷 có `storage.lua:27` mỗi nhịp tim, phiên generic có `skill_0.lua:72`.

| Phái | lượt audit | chạy trước→sau | không tác dụng | bị từ chối | không kiểm được | lỗi server | chạy lại |
|---|---|---|---|---|---|---|---|
| 0 少林 | 16 | 14→14 | 1→1 | 0→0 | 1→1 | 0→0 | 1 |
| 1 明教 | 14 | 11→11 | 0→0 | 0→0 | 3→3 | 0→0 | 1 |
| 2 丐帮 | 14 | 11→12 | 1→0 | 0→0 | 2→2 | 0→0 | 1 |
| 3 武当 | 3 | 3→3 | 0→0 | 0→0 | 0→0 | 0→0 | 1 |
| 4 峨嵋 | 18 | 9→9 | 0→2 | 2→2 | 5→5 | 2→0 | 2 |
| 5 星宿 | 13 | 8→8 | 1→2 | 0→0 | 1→1 | 3→2 | 1 |
| 6 大理 | 9 | 1→1 | 0→2 | 0→0 | 0→0 | 8→6 | 2 |
| 7 天山 | 3 | 1→2 | 1→1 | 0→0 | 0→0 | 1→0 | 1 |
| 8 逍遥 | 6 | 4→4 | 2→2 | 0→0 | 0→0 | 0→0 | 1 |
| 10 慕容 | 14 | 10→10 | 4→3 | 0→0 | 0→1 | 0→0 | 1 |
| 11 唐门 | 15 | 7→7 | 5→6 | 0→0 | 2→2 | 1→0 | 1 |
| 12 鬼谷 | 14 | 6→6 | 4→6 | 0→0 | 0→0 | 4→2 | 2 |
| 13 桃花岛 | 13 | 3→5 | 0→6 | 3→1 | 1→1 | 6→0 | 9 |
| 14 绝情谷 | 15 | 5→9 | 1→2 | 0→0 | 2→2 | 7→2 | 6 |
| 15 恶人谷 | 13 | 6→8 | 3→3 | 0→0 | 1→1 | 3→1 | 2 |
| **Tổng** | 180 | **99→109** | 23→36 | 5→3 | 18→19 | **35→13** | 32 |

- 32 lượt chạy lại: **0 lượt lỗi server** (trước: 23 lượt lỗi, chữ ký `cy_generic_IMPACT_NUMBER` 17, `cy_four_storage_faction` 15, `condition_logic_missing` 5). 13 "lỗi server" còn trong cột sau là kết quả audit của kỹ năng **chưa chạy lại** (大理 471/822–826, 鬼谷 3448/3457, 星宿 441/445, 绝情谷 4534/4538, 恶人谷 4630) — cùng chữ ký lỗi 1/3 đã sửa [SL: sẽ hết lỗi như các kỹ năng cùng chữ ký đã chạy lại].
- Chuyển lớp: lỗi→chạy 8, lỗi→không tác dụng 13, lỗi→bị từ chối 1, bị từ chối→chạy 1, không tác dụng→chạy 1, không gửi→không tác dụng 2.
- "Không tác dụng" tăng vì chiêu trước sập nay chạy hết đường nhưng thiếu impact/logic kỹ năng: vd 桃花岛 3800 `missing:45170` logic 801 chưa cài, 3808 `missing:45422–45424`, 3812/3816 `missing:44879/45184` (tĩnh `static-menpai.json`) → lỗi 4 (716 ô impact) và lỗi 5 audit (91 logic kỹ năng).
- Bị từ chối đúng CY: 谋动干戈 3807 −44 ×40 (cần con rối, tập 340), 宁鸣不默（2段）4533 −44 ×36 (刀意 = 0 < 1; tính "không tác dụng" vì có GCCharSkill_Send của chiêu khác trong phiên).
- 大理 821 −5 ×34 (hết MP giữa phiên, như audit 824) — hết sập, chưa chứng minh tác dụng.

## 6. `IDCollections.txt` server riêng ≠ CY 3.71 — bảng ảnh hưởng (chưa thay) [DK]

Nguồn: `scripts/16-idcoll-impact.py` → `16-idcoll-impact.json`. So theo (kiểu, tập ID), bỏ tên.

| | số ID |
|---|---|
| Server 375 dòng / CY 3.71 522 / tlbb15 235 | |
| giống / khác / chỉ CY / chỉ server | 117 / 248 / 157 / 10 |
| server = tlbb15 (trên 375) | giống 161, khác 73, tlbb15 không có 141 |
| ID được tham chiếu | 162 (chưa tham chiếu: khác 192, chỉ CY 145) |

Ai dùng 248 dòng khác / 157 dòng chỉ CY (theo ID × nguồn):

| Nguồn | giống | khác | chỉ CY | chỉ server | không có cả hai |
|---|---|---|---|---|---|
| Lua server (hằng trong lời gọi `*collection*(N)` / `*COLLECTION* = N`) | 8 | 6 | 0 | 1 (340 — `condition_cy`, tập riêng) | 2 |
| Bảng (cột/nhãn có 集合: SkillData, StandardImpact, CommonItem…) | 75 | 46 | 9 | 2 | 2 |
| SkillData điều kiện 0 (`C_UNIT_MUST_HAVE_IMPACT`, dùng bảng server) | 19 | **8** | **5** | 0 | 0 |
| SkillData điều kiện 18 (nay qua `cy_idcollections`) | 0 | 6 | 1 | 0 | 0 |
| SkillData điều kiện 2 / 20 | 1 / 2 | 0 | 0 | 0 | 0 |

6 ID Lua khác nghĩa: 56 少林攻击技能 (`std_talent_428`, tập khác nội dung), 121 十大门派第一本心法第一个技能 (`base.lua:754`, `skill_0.lua:49`, `skill_1.lua:45`), 281 所有门派减速合集 → CY 变身：夫妻任务娘子 (`std_talent_510`), 313 曼陀山庄琴音 → CY 明夷于飞 (`define.MANTUO_XUANYINQV_COLLECTION_ID`; SkillData CY 33208… dùng điều kiện 0 với nghĩa CY), 354 神兵能用的技能 → CY 绝情谷进阶QTE (`scenecore.lua:2273`), 476 逍遥陷阱 → CY 冰雪PVP附加技能 (`std_talent_856/857/862`).
StandardImpact (tlbb15/HJS + dòng suy ra CY): trong các ID khác, tlbb15 = server 12, tlbb15 = CY 2, khác cả hai/không có 20 (mẫu ≤4 tham chiếu/ID) → dòng StandardImpact gốc tlbb15 cần nghĩa server, dòng CY cần nghĩa CY.

**Kết luận:** thay thẳng không an toàn (Lua GL 6 ID + StandardImpact tlbb15 ~12+ ID đổi nghĩa). **Đề xuất "mọi thứ như CY":** lấy bảng CY 3.71 làm gốc; dời các dòng server/tlbb15 mà Lua/StandardImpact tlbb15 còn dùng sang dải riêng (≥ 900, như `cys_gl_impact_remap` của server-impact) và đổi hằng/ô tham chiếu; khi đó bỏ `cy_idcollections.lua`. Lỗi đang có ngay: 13 điều kiện 0 của SkillData CY đang tra nhầm tập server (vd 313).
