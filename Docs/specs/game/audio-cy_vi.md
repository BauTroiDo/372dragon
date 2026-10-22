# Âm thanh như CY 3.71 — 15/09/2026


## 2. Nhạc đăng nhập (FACT)

`SelectServer.lua` (Lua CY) khi `GAMELOGIN_OPEN_SELECT_SERVER`: `Sound:PlaySound(2110, true, true)` nếu
`GetClientVersionType() ~= 1`; `PLAYER_ENTERING_WORLD` → `Sound:StopSound`. `SoundInfo` 2110 = `music\ERenGu_Login.wav`
("唯一永久ID：天龙八部登陆界面音乐"). Không có mã native phát nhạc đăng nhập (xem `login-scene-cy_vi.md` mục 3).

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
