# Âm thanh như CY 3.71 — 15/09/2026

Agent `audio-cy` (nhánh `audio-cy`). Chỉ thị: "Mọi thứ như CY đi"; "chỉ tập trung vào các chức năng để hoàn thiện".
Bằng chứng chạy: `Build\Logs\2026-09-15-audio-cy\`. RE: bản sao project Ghidra `Build\re\audio-cy\projCG` (chỉ đọc,
heap 3 GB), script `Build\re\audio-cy\scripts\Ac*.java`, dump `Build\re\audio-cy\out\*.txt`.
Nguồn chuẩn: CY 3.71 `Tools\DATA NEW\CY Game\Bin64\Game.exe` (imagebase 0x140000000; mã nguồn gốc
`Prj\GameCode\Client\Game\Sound\GMNewSoundSystem.cpp`, lớp `CNewSoundSystemFMod`), `fmod64.dll` **FMOD 1.10.10**
(SHA256 `e3508221439c073e…`). CY-Source dùng FMOD Core 2.02.35 (`Src\ThirdParty\_sdk\fmod`, không commit).
**FACT** = đọc trực tiếp từ binary/dữ liệu; **SUY LUẬN** = chưa kiểm bằng CY chạy thật.

## 1. Kiến trúc (FACT)

| Hạng mục | CY 3.71 | Bằng chứng |
|---|---|---|
| Khởi tạo | `FMOD_System_Create`; `getVersion >= 0x11010`; `setOutput(0 AUTODETECT)`; `init(32 kênh, FMOD_INIT_NORMAL)`; log loại output (6 DirectSound / 7 WinMM / 8 WASAPI) và tên từng driver; không driver → `setOutput(2 NOSOUND)`; `set3DSettings(1,1,1)`; "Sound System x64 init succeed!" | `FUN_140687500` |
| Bảng | `SoundInfo.txt` (GetDataBase 0x7a; I id, S file, S mô tả; 1.985 dòng) và `SoundUI.txt` (0x7b; I hàng, I id SoundInfo, S mô tả; 38 dòng). Cả hai là DBC nhị phân `00CCBBDD` | `FUN_140091df0` nạp; `FUN_140687500`, `FUN_140687110`, `FUN_140686c40` |
| Biến cấu hình | `DisableAllSound`, `EnableBGSound`, `Enable3DSound`, `EnableSKSound`, `EnableUISound`, `DisableMainSound`, `VOLUME_BG/3D/SK/UI` (Bin/System.cfg CY: bật cả 4, âm lượng 0.5); nghe `VARIABLE_CHANGED` và `VARIABLE_CHANGED_IMM` | `FUN_140687500`, `FUN_140686cd0`; `Bin\System.cfg` |
| Loại nguồn (kênh logic) | 0 nhạc nền (BG), 1 kỹ năng (SK), 2 môi trường (3D), 3 UI — trùng enum `tSoundSource::Type` của 0.85 | `FUN_140688a10` (bật/tắt), `FUN_140688a60` (âm lượng) |
| Bật/tắt | Tắt SK → dừng mọi nguồn loại 1; tắt UI → loại 3; tắt BG → cảnh dừng nhạc; tắt 3D → cảnh xoá nguồn môi trường | `FUN_140686cd0` → `FUN_140688ad0(type)`, `FUN_1406bd3e0`, `FUN_1406bd650` |
| Âm lượng | 2D: `volume = VOLUME_<loại> × gain(+0x6c, 1.0)`; 3D vòng tròn: `× (1 − d/max)` với d = khoảng cách mặt đất tới người nghe, 0 khi d > max (max +0x64, mặc định 10); 3D tứ giác: theo khoảng cách tới cạnh vùng; mọi 3D × hệ số toàn cục 1.0 | `FUN_14068a1d0`, ctor nguồn `FUN_14068a880` |
| Người nghe | Vị trí MySelf (+0x4c) mỗi Tick | Tick `FUN_140687f80` |
| Tắt tiếng khi mất focus | Mặt nạ bit +0x60: `GetTypeVolume` trả 0 và mọi kênh `setMute` | `FUN_140687f80` → `FUN_140688300` |
| Đọc file | `'\'` → `'/'`, `loadResource(name, "General")`, `createSound(mem, 0x808 = OPENMEMORY|2D, defaultfrequency 44100)` — wav/mp3 giải nén cả vào RAM, âm 3D tự tính (không dùng 3D của FMOD) | `FUN_140689a70` |
| Vòng đời đệm | Nguồn huỷ → đếm tham chiếu đệm về 0 thì đặt 60 tick; Tick nhả đệm khi hết | `FUN_14068a970`, `FUN_140687f80` |
| Thiếu id | log "Invalid sound source id: %d", trả NULL (không ném) | `FUN_140689490`, `FUN_1406890d0` |
| Lua `Sound` | `PlaySound(id, loop, [main])` loại 0, 2D, tự huỷ khi không lặp; tham số 4 = true và `DisableMainSound` = 1 → bỏ qua. `PlaySoundEffect(id, loop)` loại 1. `StopSound(handle)`. `PlayUISound(n)` = hàng SoundUI n | `FUN_1406871b0`, `FUN_1406873d0`, `FUN_140687310`, `FUN_140687380` |
| API gốc | `FUN_140688e00(id)` UI loại 3; `FUN_140688ce0(id, pos GFX, loop, …)` kỹ năng 3D max 20; `FUN_1406897c0(file)` → id; `FUN_140688fc0(id)` BG lặp | các hàm cùng tên |

## 2. Nhạc đăng nhập (FACT)

`SelectServer.lua` (Lua CY) khi `GAMELOGIN_OPEN_SELECT_SERVER`: `Sound:PlaySound(2110, true, true)` nếu
`GetClientVersionType() ~= 1`; `PLAYER_ENTERING_WORLD` → `Sound:StopSound`. `SoundInfo` 2110 = `music\ERenGu_Login.wav`
("唯一永久ID：天龙八部登陆界面音乐"). Không có mã native phát nhạc đăng nhập (xem `login-scene-cy_vi.md` mục 3).

## 3. Âm UI

- `Sound:PlayUISound(n)` dùng **hàng SoundUI** (FACT); callback `ClickSound` của CEGUI cũng vậy (SUY LUẬN: giá trị
  looknfeel 17/19/20/22 khớp nghĩa SoundUI, và hệ âm thanh CY có slot vtable `FUN_140686c40` = hàng SoundUI → phát,
  chưa lần caller trong UI_CEGUI.dll): 17 = click chung (435
  `interface\click_common_1.wav`), 18 nút đóng (434), 19/20 mở/đóng cửa sổ (441/440), 22/23 cuộn (446/445), 24 xu
  (438), 27 tin nhắn (442)… Looknfeel CY: 100× `ClickSound=17`, 7× 19, 7× 20, 1× 22; 27× giá trị `435` (không phải
  hàng SoundUI → CY im lặng; CY-Source giữ nguyên, log "missing ui-index").
- Mã native 0.85 gọi `_PlayUISoundFunc(<id SoundInfo>)` (62 vào đội, 66 lên cấp, 67 trang bị, 96 túi đầy…): cùng id
  với cột 1 của SoundUI nên giữ nguyên.

## 4. Nhạc nền cảnh, kỹ năng, đạn, bẫy

1. **Nhạc cảnh (FACT)** — SceneDefineEx cột 8: Lạc Dương 0 → 2121 `luoyang_new.mp3`, Tô Châu 1 → 2122
   `suzhou_new.mp3`, Đại Lý 2 → 2106 `newdali.mp3`, Vô Lượng Sơn 6 → 122 `diewu.mp3`. `FUN_1406bd3e0(scene, bật, id)`:
   nguồn BG lặp (`FUN_140688fc0`); đổi cảnh cùng lưới → dừng nhạc cũ nếu id khác (`FUN_1406bd710`). Nhánh gia viên
   (vfunc +0x40) phát 2154/2155 — không làm (chưa có gia viên).
2. **Âm hoạt cảnh kỹ năng (FACT dữ liệu)** — `all.skill` có 4.308 phần tử `Sound`/`SoundName` (Skills\…, male_01.wav…);
   engine gọi con trỏ phát (`LogicModel::SetPlaySoundFuncton`, `RenderSystem.cpp`) → `_PlaySoundFunc(file, pos GFX,
   loop)`; CY `FUN_1400a02c0` = file → id → `FUN_140688ce0` (loại 1, 3D, max 20).
3. **Impact (FACT cột)** — ImpactDirectly cột 2 / ImpactSEData cột 5: đã có trong 0.85 qua `_PlaySoundFunc`.
4. **Đạn (FACT)** — Bullet cột 4 (row +0x18) âm bay: phát lặp 3D, giữ handle (+0x278) `FUN_14061a720`; khi trúng
   `FUN_14061a850` dừng âm bay, phát cột 7 (row +0x30) một lần.
5. **Âm bắt đầu kỹ năng** — `FUN_1405eac80(nhân vật, skill)`: SkillTemplate cột 16 (row +0x50) → id → 3D một lần
   (FACT). Điểm móc trong CY-Source (lệnh MagicSend) là **SUY LUẬN** (chưa lần caller CY).
6. **Bẫy/vật đặc biệt (FACT)** — SpecialObjData cột 9 (+0x38) lặp khi tạo, handle +0x148 (`FUN_14061ae30`); cột 13
   (+0x58) khi chết, dừng âm lặp (`FUN_14061b630`); cột 11 (+0x48) khi kích hoạt (SUY LUẬN theo bố cục cột).
7. **Bước chân** — không tìm thấy trong CY 3.71: SoundInfo 182–335 `run\*.wav` ("男主角在砖地…跑步音效") không được
   bảng/dữ liệu nào tham chiếu (chuỗi chỉ nằm trong SoundInfo), không hàm nào dùng đồng thời hằng 182…187 ngoài bảng
   sự kiện UI (`AcImmScan`: `FUN_140a0db90`, `FUN_14002c080`), và 20 caller của mọi hàm phát không có nhánh địa hình.
   `TerrainTypeInfo.cfg` chỉ gắn hiệu ứng dấu chân (walk_tudi…), không âm. → **CY-Source không thêm bước chân**
   (thêm là trái "như CY"). `FUN_1405e9fc0/FUN_1405f58b0` là âm biểu cảm theo giới tính (bảng ActionExt 0x1b7).

## 5. Âm môi trường ESD (FACT)

- File: SceneDefineEx cột 4 (`.Scene`) đổi đuôi `.esd` (`PathRenameExtensionA`), nhóm tài nguyên `Scene`
  (`FUN_1406c0e30`); < 20 cột → CY ném "CScene::LoadEnvSound ESD Less Than 20 Column:%s". 0.85 lấy tên từ `.region`
  (CY không còn `.region` → 0.85 không bao giờ nạp).
- Cột: 0 id, 1 id âm, 2–4 id ngẫu nhiên (> 0), 5 loại vùng (0 tròn, 1 tứ giác, 10 vùng nhạc), 6/7 X/Z, 8 khoảng
  nghe, 9 hệ số âm lượng (FLOAT), 10–15 ba góc còn lại của tứ giác, 16 số lần phát mỗi lượt (0 = lặp), 17 nghỉ giữa
  các lần (ms), 18 nghỉ trước lượt sau (ms), 19 mô tả. Dữ liệu CY: 4.002 dòng tròn, 151 tứ giác, 5 vùng nhạc.
- Tick cảnh `FUN_1406c00e0`: loại 10 và người chơi trong vùng → nhạc nền đổi sang id vùng (`FUN_1406bd3e0(1, id)`),
  ra khỏi mọi vùng → trả nhạc cảnh; loại 0/1 cần `Enable3DSound`: trong tầm → nguồn loại 2 (`FUN_1406890d0`), đặt
  vị trí, lặp khi cột 16 = 0, max = khoảng nghe, phát; ngoài tầm → huỷ (`FUN_140689020`).
- Lặp theo lượt `FUN_14068a740`: sau mỗi lần phát đợi cột 17 rồi phát lại tới đủ cột 16; đủ thì đợi cột 18, bốc id
  ngẫu nhiên khác id vừa phát (`FUN_1406bde60`), đổi id → huỷ nguồn để Tick tạo lại.
- Các cảnh chính: `luoyang_new.esd` 32 dòng / 14 id, `suzhou_new.esd` 74 / 13, `dali_new_320.esd` 23 / 8,
  `wuliang.esd` 22 / 12 — đều loại 0, đủ file (`Tests\audio\check_audio_cy.py`).

## 6. Dữ liệu trong CanonicalCY (FACT)

`Assets\CanonicalCY\Data\SoundFolder`: 2.031 file (music 185, ambience 362, interface 70, Skills 483, run 154,
Dial_BJ 675…); SoundInfo 1.985 dòng, 1.935 có file, 50 thiếu (client log + bỏ qua). Tên file GBK nằm trên đĩa dưới
dạng byte GBK đọc theo cp1252 — Ogre mở bằng API ANSI nên khớp.

## 7. Cài đặt trong CY-Source (thẻ `// CYS-AUDIO:`)

| Tệp | Nội dung |
|---|---|
| `Sound\CysAudio.{h,cpp}` | Nhật ký `CYS audio:` (play/stop/missing/mute/mixed/meter/release, `t_ms`), đo mức DSP đầu master (`setMeteringEnabled`), `CYS_AUDIO_OUTPUT=wav:<file>` (FMOD WAV writer) hoặc `nosound`, CPU Tick |
| `Sound\GMSoundSystem.cpp/.h` | Init như §1, đọc SoundUI, mặc định VOLUME_* 0.5, Lua PlaySound/PlaySoundEffect/StopSound/PlayUISound như CY, thiếu id → log, `PlayUISoundByIndex`, `FindSoundID`, `PlaySkillSound3D` (max 20), `PlaySoundFileAtGame`, đệm giữ 60 tick, không tắt tiếng khi chạy thử có `CYS_AUDIO_OUTPUT`, `CYS_AUDIO_PROBE=1` |
| `Sound\GMSoundSource.cpp/.h` | Suy giảm tuyến tính CY, `SetMaxDistance/SetGain`, log `mixed` (vị trí phát + audibility FMOD) mỗi lần phát |
| `Sound\GMSoundBuffer.cpp/.h` | `'\'`→`'/'`, `defaultfrequency 44100`, thiếu/không giải mã được → FALSE (không ném) |
| `World\CysSceneAudio.cpp`, `Scene.{h,cpp}` | §4.1 + §5 |
| `Object\Surface\Obj_Bullet.*`, `Obj_Special.*`, `Object\Character\Obj_Character_Logic.cpp` | §4.4–4.6 |
| `Procedure\GameProcedure.cpp` | `ClickSound` → `_PlayUISoundIndexFunc` (hàng SoundUI) |

Khác CY có chủ ý: FMOD 2.02 thay 1.10 (WASAPI mặc định); mất focus khi đang chạy thử có `CYS_AUDIO_OUTPUT` không tắt
tiếng; `DisableAllSound` CY chỉ đọc vào biến toàn cục (`DAT_141039e49`) không dùng trong hệ âm thanh → CY-Source cũng
không dùng (stage đặt `DisableAllSound=1` không làm im).

## 8. Kiểm chứng (không cần nghe)

- `smoke-login-4` (stage-4-audio, CanonicalCY, 90 s): play 2110 bg → `mixed position_ms=555 audibility=0.500`; click
  → SoundUI 17 → 435; WAV 37,7 s RMS −21,5 dBFS, 37/38 giây có tín hiệu; 0 dump; DBC 58 OK.
- `replay-core-4` (`run_world_replay.ps1 -Move -Core`, 33/33 PASS, exit 0, `quit_complete quit_flag=0`, 0 socket):
  2110 → cảnh 2 nhạc 2106 `newdali.mp3` → login dừng bởi Lua → gió 401 (env 3D, audibility 0.456); probe: UI 441,
  kỹ năng 3D 904 ở 5 m (âm lượng 0,375 = 0,5 × (1 − 5/20)), PlaySoundEffect 66, file 3D, ClickSound 17 → 435, mọi
  nguồn có `mixed position_ms > 0`; WAV 66,8 s RMS −22,9 dBFS; `release … missing=0 tick_avg_ms=0.0909
  tick_max_ms=1.547 ticks_over_1ms=1` (một đỉnh duy nhất; SUY LUẬN: nhả đệm WAV đăng nhập đã giải nén sau 60 tick), FMOD DSP ~0,2 % CPU.
- `Tests\audio\check_audio_cy.py` PASS; `Tools\game\test_stage_game.py` 26/26.
