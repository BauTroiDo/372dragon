# cy-oracle — đưa CY 3.71 gốc (bản sao) vào thế giới offline để lấy khung chuẩn

Agent `cy-oracle`, nhánh `cy-oracle`, 15/09/2026. Chỉ thị người dùng 15/09: "Chú trọng vào render bản đồ, bối cảnh,
nhân vật, hiệu ứng,... phải thật mượt, phải thật đẹp. CY gốc làm rất tốt, nếu ta chưa giống là ta chưa phân tích kỹ
cách CY làm".

Quy ước: **[DK]** dữ kiện có bằng chứng (hàm/offset Ghidra, log, ảnh), **[SL]** suy luận chưa kiểm trực tiếp.
Chuẩn: CY 3.71.9609 `Bin64\Game.exe` sha256 `9278c7f37b55539fcfac1d93afa71f278e34d4ce674b0e8b52a0f62ea6e0cc5b`
(bản sao `Build\re\cy-oracle\CYGame`, **không vá byte nào**). Bằng chứng: `Build\Logs\2026-09-15-cy-oracle\`
(`run-*` lượt chạy, `offline-test-*`, `protocol\`, `re\`), RE `Build\re\cy-oracle\out\` (Ghidra headless chỉ đọc trên
bản sao project `projCG`).

## 1. Vì sao cần

Trước đó chỉ chụp được CY thật ở màn đăng nhập (`color-calib`). Mọi so sánh Đại Lý / Vô Lượng Sơn / nhân vật / hiệu
ứng kỹ năng dựa trên suy luận. Oracle là máy chủ giả tối thiểu (phương án C giới hạn của `cy-switch_vi.md` §5): chỉ đủ
gói để client CY đăng nhập tài khoản giả, chọn nhân vật, vào cảnh, thấy NPC/quái, đi, dùng kỹ năng dựng sẵn.

## 2. Công cụ (`Tools\cyoracle`)

| File | Việc |
|---|---|
| `cy_oracle_server.py` | Máy chủ giả, chỉ `127.0.0.1` (login 15790, game 15791). Kịch bản JSON: cảnh, vị trí, nhân vật, NPC, `timeline` (dịch chuyển / kỹ năng / giờ). Ghi `frames.tsv` (thân gói CL/CG chứa định danh máy — CLConnect, CLAskLogin, CGConnect, CGHeartBeat, CLAskCharLogin — **không ghi**, chỉ cỡ) |
| `make_loginserver.py` | Viết lại `Patch\LoginServer.txt` của bản sao (mã hoá `SEPCIAL_FILE_HD` mode 1, cùng khoá MSVC rand seed `0x19830716` như 0.85) chỉ còn một server `ORACLE,cyoracle` trỏ `127.0.0.1`; ghi `Login_Area/Login_Server` vào `Bin\System.cfg` để bỏ khung chọn server. Giữ bản gốc `LoginServer.txt.orig` |
| `run_cy_oracle.ps1` | Đợi không còn Game.exe, chạy oracle + `Bin64\Game.exe -fl` của bản sao ≤150 s, chụp theo `-Plan`, **giết ngay** khi Game.exe mở kết nối không phải `127.0.0.1:<15790/15791>`, giết tiến trình con (`webclient.exe`, `na.*.exe`) |
| `test_oracle_offline.py` | Client giả kiểm cỡ/khoá mọi gói trả lời theo `Read()` của CY — không cần Game.exe |
| `pkt_vtables.py` | vtable lớp gói qua RTTI `.?AV<Tên>@Packets@@` |
| `ghidra\` | `CyOracleRE.java` (mode `pkt`, `tree`, `funcs`, `refs`, `callers`, `strdec`, `scalar`), `run_re.cmd`, job `j1..j12` |
| `scenarios\*.json` | Kịch bản tái lập (xem §5) |

## 3. Giao thức CY 3.71 dùng tới **[DK]**

Khung: client gửi `"TLBB01"` + `u16 id` + `u32 (seq<<24 | size)` + thân. Chế độ mạng bị gán cứng: 1 khi nối login
(`FUN_14062fc00` case 5 → `FUN_1405101a0(…,1)`), 2 khi nối game (`FUN_14064f2c0`); `SendPacket` `FUN_14050ea70` thêm
`TLBB01` khi chế độ 1/2 và kiểm cỡ với 12 byte đầu. Server gửi khung 6 byte thường, không tiền tố (`FUN_14050f060`
đọc `size+6`). Lớp gói: vtable slot 1 `Read`, 2 `Write`, 3 `Execute`, 4 `GetPacketID`, 5 `GetPacketSize`.
Luồng stream: `FUN_1406e6520` đọc, `FUN_1406e6470` xem trước, `FUN_1406e66e0` bỏ qua.

| Gói (ID CY) | Read | Bố cục (byte) | Ghi chú |
|---|---|---|---|
| CLConnect 355 → | `140831650` | 1,4,50,4,1,32,4,4,24 = 124 | có MAC/partner SN/Login_IP ⇒ không ghi log |
| LCRetConnect 311 ← | `140834f70` | i32, i32, char24, i32, char24, 9, i32 `+0x60`, u8 = 74 | handler `1405b1d80`: u8=0 ⇒ gửi CLAskLogin (`FUN_14062d910`) |
| CLAskLogin 299 → | `140831870` | 50 acct, 4 len, len, 4, 9, 32, 16, 128, 128, 4×3, 1×3, 512, 4, 1, 20, 4 | uVersion `0x37196`; 0x13 byte cộng khoá ngẫu nhiên |
| LCRetLogin 223 ← | `14082f7a0` | char50, i32 kết quả, 15, i32, u8, i32, [i32 nếu 0x2f/0x4b], u8, i32, [0x42…], [0x53 i32] = 83 | kết quả 0 ⇒ UI 0x123 |
| LCStatus 554 ← | `14084dd60` | u16, i32 trạng thái | 2 ⇒ gửi CLAskCharList (`FUN_14062b660`) |
| CLAskCharList 711 → | `140831ec0` | char50 | |
| LCRetCharList 319 ← | `14082f500` | i32 0, char50, u8 n≤5, n×0x1a4, u32, u8, u32×3, **+8 byte không đọc** = n·420+80 | Read xem trước cả luồng rồi bỏ qua đúng số byte; mục nhân vật §3.1 |
| CLAskCharLogin 426 → | `140832d00` | u32 guid, u32, u16, 3×(u32 len + chuỗi), u32, u8 | |
| LCRetCharLogin 38 ← | `140834c80` | u8 khoá, u32 len=62, thân **mỗi byte trừ khoá** (`FUN_140765510`): i32 kết quả, i32 cổng game, char24 IP, u32 key, u8, i32 (WorldID=i32·1000+u8), u16, u32, u16, u32, i32, i32, u8 | `GetPacketSize` trả 0x69 (không dùng khi nhận) |
| CGConnect 456 → | `1408346a0` | 4,4,4,2,50,4×9,32,4,4 = 140 | có định danh máy ⇒ không ghi |
| GCConnect 796 ← | `14083ab00` | i16 server, i16 cảnh, f32 x, f32 z, i16, i32 = 18 | handler `14053bdc0` → trạng thái 4 |
| CGEnterScene 17 → | `1408331c0` | u16 cảnh, u8 kiểu, f32 x, f32 z = 11 | gửi trong `FUN_1406432d0` |
| GCEnterScene 380 ← | `14083ae10` | u8 0, i16 cảnh, i16 res, f32 x, f32 z, u32 objID, u8, u8, i32, i32 IsKVKServer, i32, u8, i32 IsTServer, i32, u32, i32, i16 ConnectServerID, i16 = 52 | handler `1405464e0` |
| GCNewMonster 797 ← | `140849210` | 0x74 byte: +0x00 obj, +0x14 guid, +0x28/+0x2c x/z, +0x40 hướng, +0x54 tốc độ, +0x68 u16 | `FUN_1406e8880` (cùng vị trí trường với skynet) |
| CGCharAskBaseAttrib 1521 → | `14084a940` | u32 obj | |
| GCCharBaseAttrib 587 ← | `14083cc20` | u8 chế độ (bit7 mã hoá, bit6 dạng danh sách + 6 bit số lượng), u32 obj, u8, 18 byte cờ hoặc danh sách chỉ số bit, rồi trường | handler `14057b150`: bit0 u32 DataID (`FUN_14016abc0`), bit1 tên, bit3 u8 cấp, bit5/6 u8 HP%/MP% (/100), bit10 u32 tốc độ |
| CGCharMove 2345 → / GCCharMove 2742 ← | `14082fdc0` / `1408416c0` | → i32, i32, f32×2, u8 n, u8, n×8; ← u32 obj, i32 thời gian, u8 cờ, u8 n, n×8, [cờ&4: 8, i32, u8] | |
| GCObjTeleport 300 ← | `14083bd90` | u32 obj, f32 x, f32 z, u32, u32, u32 = 24 | lệnh 5 trên đối tượng |
| GCCharSkill_Send 414 ← | `140841c10` | u32 obj, u32 logic, u32 skill, i32 target, [f32×2 nếu target −1], u8 | lệnh 0xcc |
| GCDetailHealsAndDamages 785 ← | `1408463d0` | u8 cờ, u32 nhận, u32 gửi, u32 logic, [i32 HP], …, u8, u8 | |
| GCWorldTime 349 ← | `14086a940` | i32 → biến `WorldTime`, i32, i32 → `NewWorldTime_Interval` | |
| GCDetailAttrib 687 ← | `140842010` | u32 obj, 35 byte cờ, trường theo cờ (bit0 cấp) | |

### 3.1 Mục nhân vật 0x1a4 của LCRetCharList **[DK]** `FUN_1406380b0`

`+0x00` GUID, `+0x08` giới tính (→ `FUN_14016abc0`), `+0x0c` tên 30, `+0x2c` cấp, `+0x30` màu tóc, `+0x38` tóc,
`+0x3c` mặt, `+0x40` cảnh, `+0x44` môn phái (kiểm với ngoại hình vũ khí), `+0x50` (→ `FUN_140172ff0`), `+0x54` 19×u32
trang bị, `+0xa0` 19×u16 ngoại hình, `+0xc8` 19×u32 bảo thạch, `+0x188` i16 huyễn sức vũ khí, `+0x190/+0x194` màu.
Bố cục GL/skynet lệch +4 byte từ `+0x04`.

## 4. Chặn/giới hạn đã gặp

- **Chuột**: CY đọc chuột bằng `GetCursorPos` + `WindowFromPoint` + `GetAsyncKeyState` (`FUN_140212fd0`), không qua
  thông điệp ⇒ `PostMessage` chuột bị bỏ qua; phím (ESC) và `WM_CHAR` thì nhận. `run_cy_oracle.ps1` dùng `SendInput`
  thật (`mclick`) và trả con trỏ về chỗ cũ; cửa sổ để topmost không kích hoạt.
- **Tự thu nhỏ**: trạng thái đăng nhập 3 (`FUN_14062fc00` case 3) thu nhỏ cửa sổ khi không phải foreground ⇒ bước
  `front`.
- **Video mở đầu** chạy qua `webclient.exe` (IPC `FUN_140514cb0`); script giết `webclient.exe`/`na.*.exe` để không có
  kết nối web ⇒ chờ ~46 s rồi ESC.
- Không gặp mã hoá luồng, không gặp chống debug (không gắn debugger, không vá, không tiêm DLL).

## 5. Kết quả vào world và kịch bản so sánh **[DK]**

| Lượt | Kết quả | Ảnh |
|---|---|---|
| run-07 | Lần đầu vào `s_pProcMain`, cảnh `dali_new_320` tải, HUD/minimap; chưa có model | `run-07\s125.png`, màn chọn nhân vật CY `s094.png` |
| run-09 | Thêm model id −1 (bit12 nhánh plain) ⇒ **client crash** (CrashReport) ⇒ bỏ | — |
| run-12/13 | Cảnh đầy đủ (quảng trường, bồn hoa, nước, cổng/công trình), NPC chỉ là chấm minimap | `run-13\world-summary.png` |
| run-14 | Base attrib nhánh mã hoá + bit27: vòng hỏi lại 16→6, vẫn chưa có model | — |
| **run-15/16** | **NPC có model** (赵天师 cưỡi hạc, 木人, 稻草人, thỏ, khỉ, bảng tên, bóng), **MySelf có model** (nhìn từ trên: đầu/tóc/áo) | `run-15\w13-skill.png`, `run-15\contact-world.png`, `run-16\myself-zoom.png` |

Điều kiện để model hiện (FACT, execute `14057b150`, cổng `FUN_1405e35a0`, `FUN_1405d9470`):
1. `GCEnterScene +0x44 = 1` (bằng 0 và cảnh trước không thuộc danh sách `FUN_1405471d0` ⇒ ObjectManager +0x28/+0x29 = 1).
2. `GCNewMonster +0x68` (u16 → obj +0x171/+0x173).
3. `GCCharBaseAttrib` nhánh **mã hoá** (mode 0x80, u8 khoá, u32 dài, mỗi byte + khoá): gói 1 chỉ cờ bit27 (byte cờ 3 bit3,
   không trường) ⇒ obj+0x2e = obj+0x171 = sync; gói 2 cờ byte0 bit0 race u32 (NPC = MonsterAttrEx id, MySelf = giới tính),
   bit1 tên, bit3 u8 cấp, bit4 u8 HP%, (MySelf) byte2 bit0 24 B mặt/tóc/màu tóc. Race chỉ dựng model khi đổi giá trị,
   nên cổng phải mở trước.
4. MySelf: `GCCharEquipment` cờ 0x1f (5 bộ phận, visual 0 = mặc định).

Kịch bản (`scenarios\dali.json`): vào (160,150) cảnh 2, 12:00 đứng yên; +10 s skill 493 lên 木人; +20 s dịch chuyển
(205,168) cổng/nước phía đông; +32 s (160,128) phía nam quảng trường. Shot cố định +5/+9/+11/+13/+23/+28/+35/+42 s tính từ
`IN WORLD`. Ba lượt run-13/15/16 cho khung trùng camera (camera mặc định CY sau đăng nhập, nhìn dốc xuống nhân vật).
`scenarios\wuliang.json`: cảnh 6 cổng (45,165), 老神医 + 4 高山白猿 (toạ độ `wuliang_monster.ini`).

## 6. Dùng cho d3d9-trace / perf-cy

```
powershell -File Tools\cyoracle
un_cy_world.ps1 -OutDir <thư mục mới> [-Scenario dali|wuliang] [-Resolution 1280,720]
                   [-Shots "+5:shot:a;+9:shot:b"] [-Extra "+6:cam:tag;+8:mrdrag:640,360,740,360"]
```
- ≤150 s, tự lấy/xoá `Build\game-slot.lock`, chờ Game.exe khác; giết khi Game.exe mở kết nối ngoài 127.0.0.1:15790/15791.
- Mốc `+s` tính từ dòng `IN WORLD` của `oracle\oracle.log` (≈83 s sau khi chạy). Góc camera khác: `mrdrag` (kéo chuột phải
  thật), `wheel`; mọi thao tác chuột thật chỉ khi cửa sổ CY ở trước và vài trăm ms.
- Bằng chứng mỗi lượt: `run.log`, `run.json` (sockets), `oracle\frames.tsv`, log `Game_*/Fairy_*` của CY.
- Còn chưa làm: đọc camera từ bộ nhớ ở world (bước `cam` quét 16:9 chủ yếu trúng mã, xem `color-calib`), skill do MySelf
  cast chưa thấy hiệu ứng rõ ở khung +11/+13 (cần kiểm `GCCharSkill_Send` cờ/logic count hoặc đứng gần mục tiêu).

## 7. Góc camera chơi thường + đọc camera (15/09 chiều) **[DK]**

- `Tools\cyoracle\cy_camera_read.py` (bước `camread:<tag>` của `run_cy_oracle.ps1`): chỉ `OpenProcess(QUERY|VM_READ)` +
  `ReadProcessMemory`; tìm float aspect 16:9 trong vùng private RW, kiểm fov/near/far trước nó, ma trận view row-major
  (trực chuẩn) ở +336 B và ma trận chiếu (fovy = 2·atan(1/m11)). Kiểm với tiến trình giả: đúng mắt/pitch/yaw.
- CY 3.71 thật (run-17..21): **1 ứng viên duy nhất** mỗi lần đọc; `fovy 35,0°` (= `Camera_FOV`), near 1, far 15000;
  **pitch xuống cố định 40,0°** (kéo chuột phải dọc không đổi pitch); yaw mặc định 180° sau khi vào cảnh; khoảng cách
  quỹ đạo 2750 (= `Camera_MaxDistance` 27,5 m), mỗi nấc lăn chuột lại gần ~215 (7 nấc → 1245); kéo phải ngang đổi yaw
  (tốc độ phụ thuộc tốc độ kéo, nên luôn đọc lại). Tâm quỹ đạo = điểm trên đầu nhân vật: (0, 1350, −700) render
  = (160, 150) game, cao 13,5 m.
- `cam_table.py RUNDIR` ghép ảnh với camera ⇒ `cameras.tsv` (cột `tlbbviewer` = `--camera ex,ey,ez,tx,ty,tz,fov`, cùng
  quy ước `d3d9_trace_diff.py camera`). Khung chuẩn: `run-18-cam` (y0 yaw 180 / y1 154 / y2 121 / y3 64, cự ly 1245,
  pitch 40), `run-21-cam` (y0 180 / y1 167 / y2 129).
- Nhân vật **MySelf chỉ vẽ đầu + tóc** (run-16..21), NPC thì đủ: đã thử mặt/tóc (cờ byte2 bit0), 5 bộ phận trang bị
  item −1, ModelID −1 (cờ byte1 bit4), ô thời trang 16 = −1 (GCCharEquipment bit 0x10000) — không đổi. Dự đoán [SL]:
  MySelf lấy trang bị từ `GCDetailEquipList` (client gửi `CGAskDetailEquipList`, bản ghi vật phẩm 0xF4 B) chứ không phải
  `GCCharEquipment`. So chiếu sáng actor tạm dùng NPC (赵天师, 木人, 稻草人) cùng khung.

## 8. Hiệu ứng kỹ năng / impact (15/09 chiều) **[DK]**

- `GCCharSkill_Send` (skill template 493/402/283/313, người cast MySelf hoặc NPC 赵天师, run-22/23): chỉ hiện số sát thương
  (`GCDetailHealsAndDamages`), **không có hoạt cảnh/hiệu ứng** — MySelf không có vũ khí/môn phái, NPC không có kỹ năng đó
  trong bộ động tác [SL]; chưa lần tiếp id kỹ năng thật của lệnh 0xcc.
- **Impact thì hiện rõ (run-24-fx):** `GCCharImpactListUpdate` (Read `1408410a0`: u32 obj, u32, u16 n, n×(u16 impact, u32,
  u32), u16, u32) trả lời `CGCharAskImpactList` bằng id `ImpactSEData_V1` (cột 7 hiệu ứng, cột 9 điểm gắn):
  MySelf 13 (`buff_fengxue_01`), 木人 11 (`g01_buff12` vòng dưới chân) + 1 ⇒ vòng phép tím cộng sáng, động.
  `GCCharDirectImpact` (u32 target, u32 sender, u16 impact) theo timeline. Khung: `run-24-fx\contact-fx.png`,
  `run-24-fx\fx-zoom.png`, camera `run-24-fx\cameras.tsv` (pitch 40, yaw −34,7, fovy 35).
- Kịch bản `scenarios\dali_skill.json` (`impacts` theo obj + timeline `impact_list`/`direct_impact`/`skill`), chụp đồng bộ
  bằng `wait:timeline <tag>` rồi `+0.2/+0.8/+1.6`.

## 9. Vô Lượng Sơn (15/09 chiều) **[DK]**

- `scenarios/wuliang.json`: cảnh 6 (`wuliang.scene`, CY cùng offset −16000/−15700 như Đại Lý), vào (43,172) = cổng từ Đại Lý,
  老神医 + 4 高山白猿 (toạ độ `wuliang_monster.ini`), impact 11 cho 1 con vượn.
- run-25-wuliang: cỏ, đá, dương xỉ, đường đá, cột sáng cổng dịch chuyển, 老神医; 4 khung + `cameras.tsv`: w0 xa (cự ly 2750),
  w1 gần (6 nấc), w2 yaw −121, w3 xa yaw −121; pitch 40, fovy 35. Ảnh `run-25-wuliang/contact-wuliang.png`.

## 10. Chiêu có động tác + hiệu ứng + trúng đích (15/09 tối) **[DK]**

- MySelf ra chiêu (`GCCharSkill_Send`, id SkillData 0/281/641, run-26): không có động tác (MySelf không thân/vũ khí/môn phái).
- **NPC ra chiêu có động tác:** 木人 (obj 2002) nhận `GCCharSkill_Send` skill 0 → quay về mục tiêu + động tác đánh (run-26/27).
- **Trúng đích có hiệu ứng:** timeline `{"skill":0,"caster":2002,"target":1001,"impact":N,"damage":D}` gửi sau 0,6 s
  `GCCharDirectImpact(target, caster, N)` + `GCDetailHealsAndDamages`: impact 110 (`g01_sl_zdo_mingjingtai_01`) = bùng lửa
  đỏ cam trên mục tiêu; 175 (`g01_buff42_01`, 铁锁横江) = cột sáng vàng + vệt tốc độ; 124 (`g01_gb_buff113_01`) = quầng cam
  dưới chân 木人 (赵天师 ra chiêu); 28/54 mờ. Số sát thương nổi đúng mục tiêu.
- Khung `run-27-hit/hit-summary.png` (28 / 110 / 175 / 124), đủ `contact-hit.png`, camera `run-27-hit/cameras.tsv`
  (pitch 40, yaw −24, fovy 35). Kịch bản `scenarios/dali_skill.json`.

## 11. MySelf đủ thân (15/09 tối) **[DK]**

- Nguyên nhân chỉ vẽ đầu+tóc: cổng áp bộ phận `FUN_14060e350` (PlayerOther) cần obj+0x591 == obj+0x590 và ≠ 0xFF (cặp đồng bộ
  trang bị, như obj+0x170/0x171 của thuộc tính). `GCCharEquipment` Execute chỉ gán cả hai = byte +0x1c **vô điều kiện khi cờ
  bit31** (`(int)flags < 0`), và gán SAU khi đã áp bộ phận ⇒ gửi gói đồng bộ (cờ 0x80000000, không bộ phận) trước, rồi gói
  bộ phận (cờ 0x1F | 0x10000 ô thời trang −1 | bit31). Bật bằng `character.equip_sync` (kịch bản `dali_self.json`);
  `dali_skill.json` (run-27-hit) không đổi byte.
- run-28-self: MySelf nữ đủ áo xanh, cổ tay, giày; ảnh `run-28-self/self-zoom.png`, `contact-self.png`, `cameras.tsv`.
- run-29-self (`e8c6fcb1`): vũ khí hiện (visual 410 = EquipBase cột 6) + môn phái (`GCDetailAttrib` cờ byte 6 bit7 → u32
  +0x130). MySelf ra chiêu (SkillData 0/281/641) vẫn không quay mặt, không động tác; impact trúng đích trên 木人 vẫn hiện.

### 11.1 Vì sao MySelf không ra chiêu **[DK]**

- `GCCharSkill_Send` Read `140841c10`: u32 obj, u32 logic, u32 skill, i32 target, [f32 x, f32 z nếu target −1], u8 → +0x32.
  Execute `140593a60` dựng lệnh 0xcc; bit1 của +0x32 → lệnh +0x134 (cờ "không cần động tác").
- `Start_MagicSend` CY = `FUN_1405ed4e0` (bản 0.85: `Obj_Character_Logic.cpp`). Bỏ lệnh (trả 0) khi: logic lệnh ≤ obj+0x30;
  lệnh +0x134 ≠ 0; không có SkillData; SkillData +0x1c == 2; **vtable 0x2c8 trả 0**; hoặc danh sách động tác
  (SkillData +0x60, tách chuỗi, `FUN_140766040`) rỗng/−1. Quay mặt về đích khi SkillData +0x74 ∈ {1,2,6} (3: không tính hướng); `FUN_1405e1180` = ChangeAction;
  cuối cùng `FUN_1405eb790(obj,7)` = SKILL_SEND.
- vtable 0x2c8: NPC `1405d9620`, PlayerOther/MySelf `140608a60`. Bản người chơi đòi thêm +0x591 == +0x590; cả hai đòi
  +0x171 == +0x170 và **+0x173 == +0x172**, đều ≠ 0xFF.
- +0x172/+0x173 chỉ được gán bởi `GCCharImpactListUpdate` Execute `14057e2f0` (byte +0x1c) — `GCCharBuff` `14057cf80` chỉ cập nhật
  khi đã bằng nhau. NPC có sẵn vì `GCCharBaseAttrib` (loại obj 3) gán +0x172 = 0x101. run-29: client gửi `CGCharAskImpactList`
  cho 1001 nhưng oracle không trả (kịch bản không có `impacts`) ⇒ cổng đóng ⇒ MySelf không ra chiêu.
- Sửa (`64b52a83`): `dali_self.json` thêm `"impacts": {"1001": []}` (danh sách rỗng, byte đồng bộ 0). Kiểm chứng: run-30-self
  (xem handoff).
