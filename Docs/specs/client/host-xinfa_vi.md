# host-xinfa — nút HỌC TÂM PHÁP của khung CY, từ đầu đến cuối (17/09/2026)

Agent `host-xinfa`. Phạm vi: **đúng một đường** — người chơi bấm nút trong khung CY → gói ra dây → server xử → tâm pháp lên cấp → giao diện cập nhật.
Bằng chứng: `Build\Logs\2026-09-17-host-xinfa\` (không vào git). Server riêng `R` = `/home/ubuntu/cys-test-20260913`.
Tài khoản đo: **test05 / CYTest05 / GUID 200006**.

Quy ước: **[DK]** dữ kiện đo được (có đường dẫn/offset/số). **[SL]** suy luận. Không chắc thì ghi "chưa kết luận được" kèm lý do.

---

## 0. Trả lời ngắn

`SendAskStudyXinfa` **không phải** chỗ hỏng duy nhất trên đường học tâm pháp. Đường đó có **hai** hàm host, và cái hỏng trước nằm ở **nút bấm**, không phải ở hộp xác nhận:

| Bước | Hàm host | Trạng thái TRƯỚC lượt này | Hậu quả |
|---|---|---|---|
| 1. Bấm "Học" trong `ActionSkillsStudy` | `SkillsStudyFrame_study(xinfaId)` — CY gọi **một** tham số | bản 0.85 **thật** nhưng đòi **ba** số nguyên và `TDThrow("LUA: lua_SkillsStudyFrame_study Wrong Param")` | bấm nút là **ném ngoại lệ Lua**, không có gì xảy ra |
| 2. Bấm "Đồng ý" trong `MessageBox_Self` | `SendAskStudyXinfa(nowLevel, xinfaId, menpai)` | **stub** `LAG_CY_3397` (`LuaApiGen_Cy.cpp:3503`) | không gửi gói nào |
| — | sự kiện `STUDY_XINFA` nối bước 1 với bước 2 | **không tồn tại** trong bảng sự kiện 0.85 | `MessageBox_Self.lua:653 RegisterEvent("STUDY_XINFA")` bị từ chối im lặng ⇒ hộp xác nhận không bao giờ hiện |

Nói cách khác: kể cả khi chỉ cài `SendAskStudyXinfa`, **người chơi vẫn không gọi tới nó được**, vì không gì đẩy sự kiện `STUDY_XINFA` để mở hộp xác nhận. Ba mảnh phải vào cùng lượt.

---

## 1. Hành vi đúng của `SendAskStudyXinfa` — dịch ngược, không đoán

### 1.1 Vì sao không dùng `Registry/luaapi/catalog.json` [DK]

`catalog.json` được dựng từ **hai** binary: `client\Bin64\Game.exe` và `client_GL\Bin64\Game.exe` (khối `sources`). `SendAskStudyXinfa` **không có** trong 3.804 entry, và `grep` toàn bộ `client_GL\Data\InterfaceFolder` chỉ thấy `SkillsStudyFrame_study` — nhánh GL không có hàm này. Nó là hàm **chỉ có ở CY**, nên nguồn đúng là binary CY.

### 1.2 Nguồn thật: CY 3.71 `Game.exe` (Bin64) [DK]

```
C:\TLBB\085\Tools\DATA NEW\CY Game\Bin64\Game.exe
sha256 9278c7f37b55539fcfac1d93afa71f278e34d4ce674b0e8b52a0f62ea6e0cc5b
imagebase 0x140000000, .text va 0x1000 (raw 0x400)
```

Chuỗi `"SendAskStudyXinfa"` nằm ở file 0xc440b0 = **VA 0x140c456b0**; chỗ duy nhất `lea` tới nó là **0x140654ee0**, giữa vòng `objGlobal.Register(name, fn)`:

```
140654ebb: leaq -0x4202a2(%rip), %r8   # 0x140234c20   <- SkillsStudyFrame_study
140654ec2: leaq  0x5f073f(%rip), %rdx  # 0x140c45608   "SkillsStudyFrame_study"
140654ed9: leaq -0x420250(%rip), %r8   # 0x140234c90   <- SendAskStudyXinfa
140654ee0: leaq  0x5f07c9(%rip), %rdx  # 0x140c456b0   "SendAskStudyXinfa"
```

⇒ **`SendAskStudyXinfa` = 0x140234c90 (RVA 0x234c90)**, `SkillsStudyFrame_study` = 0x140234c20 (RVA 0x234c20).
Bằng chứng đầy đủ: `Build\Logs\2026-09-17-host-xinfa\re\cy-sendaskstudyxinfa.txt` (công cụ: `re\pescan.py` + `llvm-objdump`).

### 1.3 Thân hàm 0x140234c90 [DK]

```
lua_type(L,1..3) phải == 3 (LUA_TNUMBER), nếu không thì tThrowStringException
esi = (int)lua_tonumber(L,1)      ; arg1
edi = (int)lua_tonumber(L,2)      ; arg2
ebx = (int)lua_tonumber(L,3)      ; arg3
call 0x1406e5f50                   ; dựng gói tại rsp+0x28, vtable 0x140a6e528
movw %bx,  0x40(%rsp)              ; thân gói +0x00 = arg3
movw %di,  0x42(%rsp)              ; thân gói +0x02 = arg2
movw %si,  0x44(%rsp)              ; thân gói +0x04 = arg1
call 0x14050ea70 (rcx = *(0x1410378b0) net manager, rdx = &gói)   ; gửi
```

Ba `uint16` liên tiếp, đúng bố cục `pg::CGAskStudyXinfa` (id **555**, thân 6 byte, `PgPackets_misc.h`):

| Thân gói | Trường server | Tham số Lua |
|---|---|---|
| +0x00 u16 | `menpai` | **arg3** |
| +0x02 u16 | `xinfa` | **arg2** |
| +0x04 u16 | `now_level` | **arg1** |

Khớp đúng chỗ gọi duy nhất trong dữ liệu CY — `MessageBox_Self.lua:6488`:

```lua
SendAskStudyXinfa( argStudyXinFaNowLevel, argStudyXinFaID, argStudyXinFaMenPai );
```

(ba biến đặt ở `:3955-3957` khi khung nhận sự kiện `STUDY_XINFA`, có chú thích 等级 / ID / 门派).

⇒ **`SendAskStudyXinfa(nowLevel, xinfaId, menpai)` → `CGAskStudyXinfa{menpai = arg3, xinfa = arg2, now_level = arg1}`.** [DK]

### 1.4 Bước trước nó: `SkillsStudyFrame_study` của CY nhận MỘT tham số [DK]

`ActionSkillsStudy.lua:312` (`ActionSkillsStudy_UpLevel_Clicked`):

```lua
SkillsStudyFrame_study( g_XinfaDefineID[g_CurSelect] );
```

`g_XinfaDefineID[i] = EnumAction(i-1,"xinfa"):GetDefineID()`, và `CActionItem_XinFa::GetDefineID` trả `pSkillClass->m_pDefine->nID` = **id của `XinFa_V1`** — cùng con số mà `GetXinfaLevel` / `GetUplevelXinfaSpendMoney` / trường `xinfa` của gói dùng.

Bản 0.85 (`GMGameInterface_Script.cpp:689`) đòi `args[1..3].IsInteger()` và `TDThrow` nếu thiếu ⇒ **trên dữ liệu CY nút này ném ngoại lệ**. Bản CY (0x140234c20) chỉ đọc `lua_tonumber(L,1)` rồi gọi `CDataPool::SendStudySkillEvent(id)` ở **0x1400cd690** (chuỗi `D:\TLBB\Temp_Release_v3-71-9001\...\GMDataPool.cpp` trong cùng hàm).

`0x1400cd690` (bằng chứng: `re\cy-senddstudyskillevent-0x1400cd690.txt`) làm:

1. tra bản ghi tâm pháp của nhân vật → `esi` = **cấp hiện tại**; `ebx` = cấp nhân vật;
2. cấp tâm pháp `>= 0x77` (119) ⇒ báo `GMDataPool_Info_Xinfo_Level_Is_Top` rồi dừng;
3. tra `XinFaStudySpend_V1` theo **cấp+1**, lấy `r13` = tiền cần, `r14` = kinh nghiệm cần (cả hai `-1` ⇒ gửi thẳng);
4. thiếu tiền ⇒ báo `GMDataPool_Info_Up_Level_Money_Is_Not_Enough` rồi dừng;
5. **nếu quỹ kinh nghiệm hồi lưu phủ được chi phí** (`HUILIUEXP`, `jle`/`jge` tại 0x1400ce0d3/0x1400ce0dc) ⇒ **gửi thẳng** `CGAskStudyXinfa` tại 0x1400ce2ae (cùng bố cục 3×u16, menpai/xinfa/cấp hiện tại);
6. ngược lại ⇒ ghép ba số thành chuỗi rồi **đẩy sự kiện 0x487** (0x1400ce290 `mov edx, 0x487`).

### 1.5 Sự kiện 0x487 = `STUDY_XINFA` [DK]

Bảng tên sự kiện của CY khởi tạo tại 0x140a29c8a:

```
140a29c8a: movl $0x487, 0x4ca27c(%rip)
140a29c94: leaq 0xd0d45(%rip), %rax    # 0x140afa9e0 = "STUDY_XINFA"
140a29cb8: movl $0x488, ...            # dòng kế: 0x488 = "STUDY_XIULIAN"
```

Và `MessageBox_Self.lua:653` đăng ký đúng tên đó. Khớp: khung CY nhận `arg0/arg1/arg2` = cấp / id / môn phái, rồi nút OK gọi `SendAskStudyXinfa` với đúng thứ tự ấy.
Trong dự án này `CUIWindowItem` đẩy `pEvent->vArg[i]` thành biến toàn cục `argN` (chuỗi) rồi gọi `<Window>_OnEvent("TÊN")` (`UIWindowMng.cpp:533-546`) — nên phía C++ chỉ cần `PushEvent(GE_STUDY_XINFA, {cấp, id, môn phái})`, không phải ghép chuỗi như CY.

---

## 2. Đã cài gì

### 2.1 Lớp Lua glue — `Src\Client\LuaApiGen\CysHost_Skill.cpp`

Hai hàm mới, cả hai đăng ký **force** (đè cả stub lẫn bản 0.85 sai arity; `CysSkillNet::RegisterHost` chạy sau `LuaApiGen::RegisterAll` nên nó thắng):

| Hàm | Hành vi |
|---|---|
| `SkillsStudyFrame_study(a1[,a2,a3])` | một tham số = id tâm pháp (khuôn CY); ba tham số = khuôn 0.85 (`a1/100`). Gọi `Services::studyRequest` |
| `SendAskStudyXinfa(nowLevel, xinfaId, menpai)` | gọi `Services::studySend`; không đẩy giá trị trả về |

`Services` (trong `CysHost_Skill.h`) thêm hai con trỏ hàm `studyRequest` / `studySend`; phần việc thật nằm ở lớp game như mọi hàm khác của file này.

### 2.2 Lớp game — `Src\Client\WXClient\Network\CysSkillNet.cpp`

- `CysSkillNet::RequestStudyXinfa(xinfaId)` — dựng lại 0x1400cd690: tâm pháp phải có trong danh sách đã học, cấp `< 119`, đủ tiền theo `XinFaStudySpend_V1` (DBC 907, cùng phép tra với `Lua_GetUplevelXinfaSpendMoney`), rồi `PushEvent(GE_STUDY_XINFA, {cấp, id, môn phái})`. Không có quỹ hồi lưu trên bản này nên **luôn đi nhánh hỏi xác nhận** — đúng nhánh mà người chơi thấy.
- `CysSkillNet::AskStudyXinfa(xinfaId, nowLevel, menpai)` — dựng `pg::CGAskStudyXinfa` và gửi bằng `CysModernGame::SendModern`. **Môn phái và `now_level` lấy từ trạng thái client** (`Get_MenPai()`, `XinfaLevel(id)`) chứ không lấy thẳng từ Lua, vì `scenecore:char_study_xinfa` tính chi phí theo `req.now_level`; hai giá trị Lua vẫn được ghi log để đối chiếu.
- Hai bộ đếm mới `studyRequests` / `studyAsks` trong `Counters`.

### 2.3 Sự kiện dùng chung (hai dòng, có thẻ `// CYS-XINFA`)

- `Src\Engine\Interface\TDEventDefine.h`: thêm `GE_STUDY_XINFA` **ở cuối** enum (mọi ID cũ giữ nguyên).
- `Src\Client\WXClient\Event\GMEventSystem.cpp`: thêm dòng `{ GE_STUDY_XINFA, "STUDY_XINFA", }`. Bảng được đếm bằng `sizeof(g_GlobalEvent)/sizeof(EVENT_DEFINE)` nên thêm dòng là an toàn.

### 2.4 Hai tiện ích để ĐO được (không phải logic trò chơi)

- `Src\Client\WXClient\Network\CysSkillDriver.cpp`: chuỗi bước thứ hai, bật bằng **`CYS_XINFA_LIVE=1`** (tuỳ chọn `CYS_XINFA_ID`): mở `ActionSkillsStudy` → bấm icon tâm pháp → bấm nút "Học" → bấm OK của `MessageBox_Self` → chờ `GCStudyXinfa`. Mọi bước ghi `CYS skill-live:` và chụp ảnh.
- `Src\Client\WXClient\Procedure\CysGlLoginSmoke.h`: **`CYS_BOT_ACCOUNT` / `CYS_BOT_ROLE`** thay cho hai chuỗi `test00` / `CYTest00` ghi cứng (mặc định không đổi). Nhờ đó lượt GUI live chạy được trên tài khoản riêng của từng agent thay vì tranh nhau `test00`.

---

## 3. ĐO TRÊN CLIENT THẬT — **CHẠY, đủ cả đường** [DK]

Lượt `Build\Logs\2026-09-17-host-xinfa\gui-live-2`, 17/09 21:42–21:43, `Game.exe` của `Build\world-gui\stage-host-xinfa-3`
(binary dựng từ `Build\cmake\host-xinfa-x64`, dữ liệu `CanonicalCY`, giao diện CY), server riêng, **test05 / CYTest05 / GUID 200006**,
cảnh 2 (Đại Lý). Không dùng bot, không gọi Lua tay: **chuột được bơm vào chính CEGUI** (`CysUiSmokePointer`), nghĩa là
đúng cái nút người chơi bấm.

### 3.1 Chuẩn bị nhân vật (Mongo, lúc offline)

`scripts\10-char-xinfa.py prepare --guid 200006 --menpai 0 --money 100000 --scene 2 --x 160 --z 150`
(sao lưu `char-200006-backup.json`): môn phái 9 → **0 (Thiếu Lâm)**, 8 tâm pháp `1,2,3,4,5,6,55,72` mỗi cái **cấp 1**, tiền 0 → 100 000, exp 23 388.
GM tool không dùng được vì `GmTool_Self.GmCeshi` chỉ có `test00`.

### 3.2 Chuỗi bấm nút — `WXClient.log`

```
[21:43:25] CYS skill-live: xinfa study: menpai=0 xinfa_known=8 target=1 level=1 button=1 exp=23388 money=100000
[21:43:25] CYS skill-live: step 24: TOGLE_SKILLSTUDY
[21:43:27] CYS skill-live: ActionSkillsStudy shown=1
[21:43:27] CYS skill-live: clicked ActionSkillsStudy_XinfaSkill_1 (xinfa 1)
[21:43:28] CYS skill-live: clicked ActionSkillsStudy_UpLevel_Frame -> SkillsStudyFrame_study(1)
[21:43:28] CYS skill:      study request xinfa=1 level=1 menpai=0 need money=10 exp=27 -> STUDY_XINFA
[21:43:30] CYS skill-live: after the learn button: study_requests+1 MessageBox_Self shown=1
[21:43:30] CYS skill-live: clicked MessageBox_Self_OK_Button -> SendAskStudyXinfa
[21:43:30] CYS skill:      CGAskStudyXinfa sent menpai=0 xinfa=1 now_level=1 (lua asked level=1 menpai=0)
[21:43:30] CYS skill:      GCStudyXinfa xinfa=1 level 1 -> 2 exp=23361 money=100000
[21:43:32] CYS skill-live: PASS xinfa live script: xinfa=1 level 1 -> 2 study_requests+1 study_asks+1 GCStudyXinfa+1
```

Đọc từng dòng:

1. **Nút "Học" chạy** — `SkillsStudyFrame_study(1)` nhận **một** tham số và không ném ngoại lệ nữa.
2. **Chi phí khớp bảng** — `need money=10 exp=27` đúng ô `XinFaStudySpend_V1` cấp 2 của tâm pháp 1 (cặp thứ 1: `10 27`), tức client tra đúng bảng CY.
3. **Hộp xác nhận hiện** — `MessageBox_Self shown=1`, nghĩa là `GE_STUDY_XINFA` mới đã tới đúng khung CY với ba tham số.
4. **`SendAskStudyXinfa` được gọi thật và gửi gói** — `study_asks+1` và `CGAskStudyXinfa sent menpai=0 xinfa=1 now_level=1`.
5. **Server trả lời và tâm pháp lên cấp** — `GCStudyXinfa xinfa=1 level 1 -> 2`, `spare_exp` 23 388 → **23 361** (đúng **−27**).
6. `OnStudyXinfa` đẩy `GE_SKILLSTUDY_SUCCEED` ⇒ `ActionSkillsStudy_OnEvent("SKILLSTUDY_SUCCEED")` → `ActionSkillsStudy_UpdateFrame()` (khung vẽ lại cấp và chi phí mới).

### 3.3 Dòng stub đã biến mất [DK]

```
grep -c "missing host function _G:SendAskStudyXinfa" WXClient.log   ->  0
grep -c "missing host function"                      WXClient.log   ->  89
LuaApiGen: 1991 calls to 88 missing host functions this session
CYS skill: host functions registered=4
```

Số 0 này **có nghĩa** (khác với "không ai gọi nên không in"): cùng phiên đó `study_asks+1` chứng minh hàm **đã được gọi** —
nó chạy bản thật chứ không phải stub. `registered=4` = bốn mục `force` của `CysHost_Skill` (`GetXinfaInfo`, `GetXinfaLevel`,
`SkillsStudyFrame_study`, `SendAskStudyXinfa`); bốn mục còn lại là "chỉ khi thiếu" và đã có sẵn.

### 3.3b Ảnh — thấy tận mắt [DK]

`gui-live-2\cys-live-159173500-xinfa-*.png` (5 ảnh: `hud`, `window`, `selected`, `confirm`, `after`).

- `xinfa-confirm`: khung **Thuộc tính** (ActionSkillsStudy) mở với 8 ô tâm pháp, hộp xác nhận tiếng Việt
  *"Lần lên cấp này cần dùng kinh nghiệm bản thân của nhân vật, có xác nhận hoàn tất thao tác này không?"* + nút **OK / Hủy**,
  dòng **"Cần tiêu hao 10"**.
- `xinfa-after`: cùng khung sau khi server trả lời — **"Kim Cang Kinh — Cấp bậc hiện tại: 2"**, **"Cần tiêu hao 15"**
  (chi phí cấp kế đã nhảy 10 → 15) và ba chiêu của tâm pháp đó hiện ra. ⇒ **giao diện tự cập nhật** qua
  `GE_SKILLSTUDY_SUCCEED`, không phải chỉ có gói chạy.

**Việc của người khác, không phải của tôi (ghi lại để khỏi mất):** trong hai ảnh đó thấy ba lỗi nhãn của khung này —
mô tả tâm pháp còn **nguyên văn tiếng Trung** (`XinFa_V1` cột mô tả chưa dịch), dòng `最高等级%d` in **thô cả `%d`**,
và hai nhãn `ActionSkillsStudy_CurrentlyExp_Character_Text` / `DemandExp_Character_Text` **đè lên nhau**
("Kinh nghiệm hiệnKinh nghiệm yêu…"). Thuộc nhánh dịch/`ui-layouts`.

### 3.4 Server và Mongo [DK]

```
server log Game2_20260917_201253.log:
  [21:42:56] [AUTO_ROUTE_ENTER] guid= 200006 obj= 210 scene= 2 x= 160.0 y= 150.0
  0 traceback / 0 error mới trong khoảng 21:42–21:44 (ba cảnh báo MonsterAI lúc 21:30 có từ trước phiên này)
Mongo sau phiên (char-200006-after.json):
  xinfa_list[0] = {id: 1, level: 2}     (trước: level 1)   <- LƯU THẬT
  exp = 23361                            (trước: 23388)
```

### 3.5 Lượt thứ hai, tâm pháp khác — cũng CHẠY, và **20/20 cổng kiểm PASS** [DK]

Lượt `gui-live-5` (stage `stage-host-xinfa-4`), tâm pháp **4**:

```
[22:07:11] xinfa study: menpai=0 xinfa_known=8 target=4 level=1 button=4 exp=23361 money=100000
[22:07:14] study request xinfa=4 level=1 menpai=0 need money=15 exp=41 -> STUDY_XINFA
[22:07:16] CGAskStudyXinfa sent menpai=0 xinfa=4 now_level=1
[22:07:16] GCStudyXinfa xinfa=4 level 1 -> 2 exp=23320          (23361 - 41, đúng chi phí)
[22:07:18] PASS xinfa live script: xinfa=4 level 1 -> 2
missing host function _G:SendAskStudyXinfa -> 0
```

Runner: **20/20 PASS** (`character_selected` nay theo `-Role`, xem dưới). Mongo cuối (`char-200006-after2.json`):
`xinfa 1 = cấp 2`, `xinfa 4 = cấp 2`, `exp 23320`. ⇒ **lặp lại được**, không phải may một lần.

### 3.5b Lượt PARTIAL và vì sao — luật của trò chơi, không phải lỗi [DK]

Lượt `gui-live-4` chọn **tâm pháp 2** và báo `study_requests+0 MessageBox_Self shown=0`: nút bấm rồi mà **không có gì xảy ra**.
Nguyên nhân nằm trong chính script CY — `ActionSkillsStudy.lua:362-367`:

```lua
ActionSkillsStudy_UpLevel_Frame:Enable()
if nIndex == 2 or nIndex == 3 or nIndex == 6 then
    if Player:GetData("LEVEL") < 20 then ActionSkillsStudy_UpLevel_Frame:Disable() end
end
```

CYTest05 **cấp 15** ⇒ ba ô 2/3/6 khoá nút "Học". Đúng luật CY, không phải lỗi hàm host — và là bằng chứng phụ rằng
nút thật sự đi qua lớp CEGUI (một nút bị `Disable()` thì cú click không tới Lua). Bộ đo đã học luật này
(`CheapestXinfa` bỏ qua ô 2/3/6 khi cấp < 20).

### 3.5c Cổng kiểm `character_selected`

Lượt đầu (`gui-live-2`) báo 19/20: ô đó `match` chuỗi `name=CYTest00` ghi cứng, mà dòng log nay in tên thật (`CYTest05`).
Đã sửa `Tools\game\run_world_gui_live.ps1` để ô đó theo `-Role` / `CYS_BOT_ROLE` (mặc định `CYTest00` — không đổi hành vi cũ).
Từ `gui-live-4` trở đi: **20/20 PASS**.

### 3.6 Bốn bộ kiểm + build [DK]

| Bộ | Kết quả |
|---|---|
| build `host-xinfa-x64` (toàn bộ) | **rc 0**, 920/920 target (`build-6-all.log`); lượt chỉ `cys_wxclient` 1143/1143 rc 0 (`build-5-account.log`) |
| `cys_netbot_tests` | **tests=28 failed=0**, fuzz 100 000 đầu vào |
| `cys_netcore_tests` | **checks=18 PASS**, fuzz 100 000 |
| `cys_world_tests` | **checks=83 PASS**, fuzz 20 000 gói world |
| `cys_protocol_tests` | **PASSED**, 497 gói, spec sha256 `2eb05f0c473d44b6` |

(Bốn bộ này không chạm lớp GUI/host; chúng là kiểm hồi quy cho phần mạng mà sửa đổi của tôi đi qua — `CGAskStudyXinfa` 555.)

---

## 4. Bẫy đã sập trong lượt này

1. **Hàm không có trong `catalog.json` không có nghĩa là không có bằng chứng.** Catalog dựng từ `client` + `client_GL`; hàm chỉ-CY phải tra thẳng trong `CY Game\Bin64\Game.exe`. Quét chuỗi + `lea` RIP-relative tới chuỗi đó là đủ tìm chỗ đăng ký (`re\pescan.py`), không cần mở Ghidra.
2. **Sửa `SendAskStudyXinfa` một mình là vô dụng.** Không có `GE_STUDY_XINFA` thì `RegisterEvent("STUDY_XINFA")` bị `PushEventByName` từ chối (dòng "CYS: reject unknown names"), hộp xác nhận không hiện, và hàm không bao giờ được gọi.
3. **Cùng một tên hàm, hai arity khác nhau.** `SkillsStudyFrame_study` tồn tại ở cả 0.85 và CY nhưng CY chỉ truyền **một** tham số; bản 0.85 `TDThrow` — đây là kiểu hỏng mà bộ đếm stub **không** thấy, vì hàm "có thật".
4. **`Build\cmake\<tên>-x64` mới phải build TOÀN BỘ target ít nhất một lần.** Chỉ build `cys_wxclient` thì thiếu `WXRender.dll`/`UI_CEGUI.dll`… và `stage_game.py` vẫn "STAGED" 12 binary; client chết ngay với `TDThrow: Load plugin dll(WXRender.dll) failed!` (lượt `gui-live-1`).
5. **`stage_game.py build` từ chối ghi đè stage cũ** ("stage exists") và `stage_wsl_test.py apply` từ chối stage đã ở trạng thái server-profile ⇒ mỗi lần dựng lại binary phải dùng `--name` mới.
6. **Tài khoản của lượt GUI live bị ghi cứng `test00`** trong `CysGlLoginSmoke.h` (ba chỗ kiểm tên tài khoản + hai chỗ kiểm tên nhân vật). `-Account` của runner chỉ chọn **mật khẩu**. Đã thay bằng `CYS_BOT_ACCOUNT` / `CYS_BOT_ROLE`.
7. **GM tool chỉ mở cho `test00`** (`GmTool_Self.GmCeshi = { {user = "test00"} }`), nên `--exec 900066,ConsoleRoleUse,...` không dùng được cho test05; phải dựng điều kiện bằng Mongo lúc nhân vật offline (`scripts\10-char-xinfa.py`).
8. **Bấm `Select-Object -First N` sau `wsl.exe`** làm tiến trình chết vì broken pipe và trả exit 255 dù lệnh đã chạy xong — đừng đọc đó là lỗi.
9. **Ba ô tâm pháp 2/3/6 khoá nút "Học" khi nhân vật cấp < 20** (`ActionSkillsStudy.lua:362-367`). Bấm vào đó là "không có gì xảy ra" — rất dễ đọc nhầm thành hàm host còn hỏng (lượt `gui-live-4`). Đo bằng nhân vật cấp ≥ 20 hoặc chọn ô khác.
10. **`attrib.world_pos.y` của server = `z` của bản đồ** (theo `cs3a_move_test_char.py`); ghi nhầm vào `.z` là nhân vật rơi sai chỗ.

---

## 5. Công cụ mới trong `Build\Logs\2026-09-17-host-xinfa\`

| File | Việc |
|---|---|
| `build_xinfa.cmd` | build Release x64 cây chính vào `Build\cmake\host-xinfa-x64` (Ninja, parallel 4) |
| `scripts\10-char-xinfa.py` | đọc/chuẩn bị/khôi phục nhân vật test trên Mongo (`dump` / `prepare --menpai --money` / `restore`); mặc định CHỈ ĐỌC, mọi lệnh ghi đòi `--apply`, chỉ chạm GUID 200001–200016, từ chối khi còn client nối 15733/15734, sao lưu toàn bộ document trước khi ghi |
| `scripts\20-xinfa-gui-turn.ps1` | một lượt GUI live của đường học tâm pháp (chờ máy rảnh → `run_world_gui_live.ps1` với `CYS_XINFA_LIVE=1`) |
| `re\pescan.py` | quét PE: chuỗi → VA, rồi tìm mọi `lea` RIP-relative trỏ tới VA đó trong `.text` |
| `re\cy-*.txt` | disassembly kèm hash của CY `Game.exe` |
