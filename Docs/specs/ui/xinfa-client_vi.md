# xinfa-client — tâm pháp phía client: bảng chi phí DBC 907 như CY 3.71 (16/09/2026)

Agent `menpai-verify`, nhánh `menpai-verify`, worktree `Build\wt-menpai-verify`.
Tiếp nối `../server/menpai-audit_vi.md` mục 2 (dòng "Client") và `../net/skills-ui_vi.md` mục 7.
Quy ước: **[DK]** dữ kiện đo được (có đường dẫn). **[SL]** suy luận.
Bằng chứng: `Build\Logs\2026-09-16-menpai-verify\`, RE `Build\re\menpai-verify\` (bản sao chỉ đọc của project Ghidra CY 3.71 Game.exe `Game_C_9278c7f3.exe`, sha256 `9278c7f3…cc5b`).

## 0. Trả lời ngắn

Cửa sổ tâm pháp **không đọc được chi phí** vì client chưa mở bảng DBC 907. Hai lỗi khác nhau, đã sửa cả hai:

1. **[DK]** `CDataBaseSystem::OpenAllDataBase` (`Src/Client/WXClient/DBC/GMDataBase.cpp`) không có dòng nào cho
   `DBC_XINFA_STUDYSPEND` (907), nên `GetDataBase(907)` trả `it->second` của `map::end()` — con trỏ rác.
   `GetDataBase` không kiểm `end()`.
2. **[DK]** Vì vậy agent `skills-ui` đã ghi đè hai hàm Lua bằng hằng số 0
   (`Src/Client/LuaApiGen/CysHost_Skill.cpp`, `SpendMoney`/`Zero`, `force = true`): cửa sổ **mở được** nhưng hiện
   chi phí 0 cho mọi tâm pháp, mọi cấp. Nói cách khác, ở bản `main` cf63a3b4 mở cửa sổ tâm pháp **không sập**
   (hai hàm 0.85 đụng 907 bị che), nhưng số liệu là giả.

Bản sửa: mở bảng CY thật, bỏ hai hàm giả, chặn `GetDataBase` khi thiếu bảng.

## 1. CY nạp bảng nào, ở đâu **[DK]**

- Chuỗi `"XinFaStudySpend_V1.txt"` nằm ở `0x140a58fd8` trong CY Game.exe, **một tham chiếu duy nhất**, trong
  `FUN_140091df0` = `OpenAllDataBase` của CY (`Build\re\menpai-verify\out\xinfa-xref.txt`).
- Ô bảng của nó bắt đầu tại `0x140092933` (`Build\re\menpai-verify\out\xinfa-disasm.txt`):

  ```
  140092939  MOV dword ptr [RBP + 0x22f0], 0x97          ; id bảng
  140092943  LEA RAX, [0x140a58fd8]                      ; "XinFaStudySpend_V1.txt"
  14009294a  MOV qword ptr [RBP + 0x22f8], RAX
  ```

- **Bảng khớp nhau theo TÊN FILE, không theo số hiệu.** CY đánh số 562 bảng thành **một dãy liền** bắt đầu `0x64`
  (`23-cy-dbc-list.tsv`, quét tĩnh bằng `scripts\23-cy-dbc-list.py` theo mẫu ba lệnh `MOV id / LEA tên / MOV con trỏ`),
  còn 0.85 chia theo nhóm (1xx nhân vật, 2xx quái, 3xx vật phẩm, 6xx kỹ năng, 7xx cảnh, 8xx UI, 9xx linh tinh).
  Phép trừ 756 chỉ đúng cho **15/48** bảng nằm trong nhóm 9xx của 0.85 (`24-id-offset-check.txt`: khớp 15, lệch 33) —
  **không phải quy luật**. Vì vậy CY-Source giữ số 907 của 0.85 như với mọi bảng khác.
- Vị trí trong danh sách thì khớp: CY mở nó **ngay giữa `Platform.txt` (0x94) và `CharTitle.txt` (0x98)**, đúng chỗ
  `OpenAllDataBase` của CY-Source đặt nó (sau `CodeConvert.txt`, trước `CharTitle.txt`). `cs2-world` ghi
  `GetDataBase(0xbb)` ↔ `ReputationTable.txt` — cũng thấy trong danh sách này (`0xbb`).
- Tên file **không có tiền tố thư mục** → `ConfigFolder\XinFaStudySpend_V1.txt` (bản CY: 
  `Assets\CanonicalCY\Data\ConfigFolder\XinFaStudySpend_V1.txt`, DBC nhị phân `00CCBBDD`, sha256 `45142aa117fb…`).
  Bản `ConfigFolder\AbilityLevelUp\XinFaStudySpend_V1.txt` là **bảng khác** (130 cột × 152 dòng, 64 cặp) và
  không phải bảng của gói này — CY cũng có chuỗi `AbilityLevelUp/` nhưng ô bảng 0x97 dùng tên trần.
- Bảng CY trùng **từng ô** với bảng của server riêng (`R/configs/XinFaStudySpend_V1.txt`), đã đo ở
  `menpai-audit` mục 2 (`bitich/xinfa_spend_cmp.txt`, 0 ô khác).

## 2. Cấu trúc cột **[DK]**

244 cột INT × 302 dòng (`Build\Logs\2026-09-16-menpai-verify\20-dbc-layout.tsv`):

| Cột | Nghĩa |
|---|---|
| 0 | số dòng, 1..302 |
| 1 | cấp muốn học; dòng 1 mang **888**, dòng 2 mang **999**, dòng 3..302 là cấp **1..300** |
| 2..243 | 121 cặp `(tiền, kinh nghiệm)` |

- Dòng **888** nói ô cặp thứ *k* thuộc tâm pháp nào: `0,0, 1,1, 2,2, … 120,120` → **chỉ số cặp = ID tâm pháp**
  (`XinFa_V1` CY có 120 tâm pháp, ID 1..120), nên `StudySpend[nXinfaId]` là đúng cặp.
- Dòng **999** nói cột chẵn là tiền (0), cột lẻ là kinh nghiệm (1).
- Đối chiếu: cấp 2 của tâm pháp 1 = 10 tiền / 27 kinh nghiệm — đúng con số đo live ở `menpai-audit` mục 2
  (giao tử 28 879 185 → 28 879 175).

Struct tương ứng (`Src/Engine/Interface/TDDBC_Struct.h`):

```c
#define DBC_XINFA_STUDYSPEND_SLOTS  (121)
struct _DBC_XINFA_STUDYSPEND
{
    INT   nLineNum;        // [0] 1..302
    INT   nStudyLevel;     // [1] 888 / 999 / 1..300
    Spend StudySpend[DBC_XINFA_STUDYSPEND_SLOTS];   // [2..243]
};
```

Bản 0.85 là `INT nStudyLevel; Spend StudySpend[54];` — thiếu cột số dòng và chỉ 54 cặp, nên nếu mở bảng CY bằng
struct cũ thì mọi ô lệch một INT và `StudySpend[id]` với id ≥ 54 đọc **ngoài mảng**.

## 3. Bản sửa

| # | File | Nội dung |
|---|---|---|
| 1 | `Src/Engine/Interface/TDDBC_Struct.h` | `_DBC_XINFA_STUDYSPEND` theo bố cục CY (244 INT, 121 cặp) + hằng `DBC_XINFA_STUDYSPEND_SLOTS` |
| 2 | `Src/Client/WXClient/DBC/GMDataBase.cpp` | thêm `{ DBC_XINFA_STUDYSPEND, "XinFaStudySpend_V1.txt", sizeof(...), "I"×244 }` đúng chỗ CY đặt nó (sau `CodeConvert`, trước `CharTitle`) |
| 3 | `Src/Client/WXClient/DBC/GMDataBase.cpp` | `GetDataBase` trả `NULL` + ghi `DBC ERROR` khi id không có trong map (trước đây giải tham chiếu `map::end()`) |
| 4 | `Src/Client/WXClient/Interface/GMGameInterface_Script.cpp` | `CysXinfaStudySpend(id, level, what)` dùng chung: chặn id ngoài `0..120`, chặn bảng NULL, **luôn** đẩy đủ giá trị (bản cũ khi không thấy dòng cấp thì `return 4` mà không đẩy gì → Lua nhận `nil` rồi lỗi nối chuỗi ở `ActionSkill.lua:306`) |
| 5 | `Src/Client/LuaApiGen/CysHost_Skill.cpp` | bỏ hai mục giả `GetUplevelXinfaSpendMoney`/`GetUplevelXinfaSpendExp` để hàm thật chạy |

Lua gọi (`Assets\CanonicalCY\Data\InterfaceFolder\ActionSkill\ActionSkill.lua:306`,
`ActionSkillsStudy\ActionSkillsStudy.lua:279`): `GetUplevelXinfaSpendMoney(nXinfaId, nXinfaLevel + 1)` —
tham số 1 là ID của `XinFa_V1`, tham số 2 là cấp **muốn lên**, khớp cột 1 của bảng.

## 4. Kiểm

| Kiểm | Kết quả |
|---|---|
| Cổng bố cục DBC | **[DK]** `python -X utf8 Tests/abi/check_dbc_layout.py --data Assets/CanonicalCY/Data --gl-data Assets/Canonical/Data --strict` → `PASS`, dòng `DBC_XINFA_STUDYSPEND XinFaStudySpend_V1.txt _DBC_XINFA_STUDYSPEND 244 OK OK OK` (`Build\Logs\2026-09-16-menpai-verify\20-dbc-layout.tsv`); trước bản sửa bảng này không có trong danh sách |
| Bảng client = bảng server | **[DK]** `scripts\22-xinfa-cmp.py` so từng ô bảng CY của client với `R/configs/XinFaStudySpend_V1.txt`: cùng 244 × 302, dòng 888/999 giống hệt, **0 ô khác**. Mẫu: tâm pháp 1 cấp 2 = 10 tiền / 27 kinh nghiệm (`22-xinfa-cmp.out.txt`) |
| Build | **[DK]** rc 0 (`build-1.log` toàn bộ 2 071 đích, `build-3.log` sau khi thêm `LogXinfaCost`) |
| Stage | **[DK]** `stage-1-mpv` (profile **CanonicalCY**) mang đúng bảng 244 cột 295 745 byte (`25-stage.log`, `26-stage-apply.log`) |
| `test_dbc_schema.py` | Chạy trong worktree luôn `FAILED (failures=1, errors=15)` vì worktree không có `Assets\CanonicalCY`; `wt-skills-ui` (không sửa gì) cho kết quả y hệt → nhiễu có sẵn (`27-gate.txt`) |
| GUI live | **[DK] ĐẠT** — mục 5.1: bảng nạp `OK columns=244 records=302 record=976`, cửa sổ tâm pháp mở không sập, chi phí hiện **18 034** đúng ô bảng, học/nâng một cấp `xinfa study -> level 2` |

## 5. GUI live

WSL `TLBB` khởi động lại lúc ~01:32 ngày 16/09 và server riêng không tự chạy lại (status 09:08: 6/6 dịch vụ
`running=False`); lệnh `cys_server.sh start` bị bộ phân loại quyền của phiên chặn (`Interfere With Workloads`),
nên agent này **không tự bật được server** — người điều phối bật lúc ~09:40 (git `2f41d75`, đã có 2 107 dòng
StandardImpact của `impact-data`).

Lượt GUI chạy bằng `Build\Logs\2026-09-16-menpai-verify\scripts\gui_xinfa_turn.ps1` trên stage `stage-1-mpv`:
đặt CYTest00 sang một phái có tâm pháp (`-Menpai`), mở sách kỹ năng → trang tâm pháp, chụp `skill-book-xinfa`,
và `WXClient.log` mang ba dòng `CYS skill-live: xinfa cost: …`.

### 5.1 Kết quả `gui-live-1` (11:16–11:19, CYTest00 phái 0 Thiếu Lâm, tâm pháp cấp 30) **[DK]**

Runner PASS (`51-gui-live-1.txt`), bằng chứng `Build\Logs\2026-09-16-menpai-verify\gui-live-1\` (27 ảnh).

1. **Bảng nạp sạch**: `WXClient.log` có `DBC: XinFaStudySpend_V1.txt OK columns=244 records=302 record=976`
   và dòng tổng kết `59 table(s) checked against the CY 3.71 schema, 0 error(s)`. Không có `DBC ERROR` nào.
2. **Cửa sổ tâm pháp mở được, không sập**: `step 3: TOGLE_SKILL_BOOK` → `step 4: xinfa selected`, ảnh
   `cys-live-35247578-skill-book-xinfa.png`; lượt chạy tiếp hết 22 bước (kéo kỹ năng, Tab, F1, hồi chiêu).
3. **Chi phí hiện đúng số của CY**:

   ```
   CYS skill-live: xinfa cost: ActionSkill_Name       text=[Long Thụ Tâm Kinh Cấp bậc tâm pháp:30]
   CYS skill-live: xinfa cost: ActionSkill_LearnExp   text=[KN cần:18034]
   CYS skill-live: xinfa cost: ActionSkill_LearnDemand_Jiaozi_Text  text=[Chi phí:]
   ```

   Long Thụ Tâm Kinh là tâm pháp **id 5** của `XinFa_V1` CY; bảng `XinFaStudySpend_V1` dòng cấp **31**, cặp số 5
   = **2 527 tiền / 18 034 kinh nghiệm**. Con số trên màn hình **trùng khít cả hai**: ảnh
   `cys-live-35247578-skill-book-xinfa.png` hiện `KN cần:18034` và `Chi phí: 25 <bạc> 27 <đồng>` — đúng 2 527
   (widget `ActionSkill_LearnDemand_Jiaozi` kiểu `TLBB_Money` tách bạc/đồng; số nằm ở property `MoneyNumber` nên
   không đọc được qua text, chỉ thấy nhãn "Chi phí:" trong log). Trước bản sửa, hai hàm giả của `CysHost_Skill`
   luôn trả 0 nên cả hai ô đều là 0.
4. **Học/nâng một cấp chạy được**: phiên bot `--xinfa 2` (`study1\live\m0\`, 11:19:54) trả
   `xinfa study -> level 2`, `study_results=1` — tâm pháp 1 lên cấp 2, đúng ô bảng 10 tiền / 27 kinh nghiệm.
   Log phiên có 2 traceback nhưng là `scene.lua:26 serialize can't pack too depth table` lúc thoát, không liên
   quan tâm pháp.

## 6. Việc còn lại

1. Số tiền chỉ kiểm được bằng mắt trên ảnh (`MoneyNumber` là property, không phải text); muốn kiểm tự động thì
   cần thêm một lối đọc property của CEGUI vào `CysUiInputBridge`.
2. `XinFa_V1` client 37 cột vs server 29 (thiếu 心法等级段 11–14) — xem `menpai-audit` mục 2 dòng "Lệch CY";
   không thuộc gói 907 nhưng cùng cửa sổ.
3. Server chưa chặn `now_level ≥ 300` khi học (`scenecore.lua:2568`): với bảng 300 cấp, `config[301]` là `nil`.
   Client nay trả 0 cho cấp > 300 thay vì đọc rác, nhưng lỗi Lua phía server vẫn còn (agent server lo).
