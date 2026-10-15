# Động tác ra chiêu và hiệu ứng impact/buff như CY 3.71 (skill-fx-parity, 15/09/2026)

Agent skill-fx-parity, nhánh `skill-fx-parity`. Hook `// CYS-PARITY:` (đổi hành vi, có công tắc) và `// CYS-SFX:`
(kịch bản, chẩn đoán). **FACT** = đọc từ binary CY (Ghidra, bản sao `Build\re\skill-fx-parity\projCG`, Game.exe sha
`9278c7f3…`), log hoặc ảnh chạy thật; **INF** = suy luận. Bằng chứng: `Build\Logs\2026-09-15-skill-fx-parity\`.

Chuẩn CY: `Build\Logs\2026-09-15-cy-oracle\run-27-hit` (chiêu NPC + impact 28/110/175/124/54) và `run-24-fx`
(GCCharImpactListUpdate: 13 trên MySelf, 11+1 trên 木人).

## 1. Dựng lại kịch bản trong dự án (phát lại offline)

- `Tools\game\cy_scenario_replay.py <scenario.json | oracle.log> <out.txt>`: đọc kịch bản cy-oracle (dòng đầu
  `oracle.log` chính là JSON đã chạy) và viết tệp `CYS_WORLD_SCENARIO`: `scene`, `at=<ms> npc|skill|impact|damage|
  impactlist|tag`. Tệp của hai chuẩn: `scenario\dali_skill_run27.txt`, `scenario\dali_fx_run24.txt`.
- Cùng gói, thứ tự và thời điểm như `cy_oracle_server.py` gửi CY (FACT `oracle\frames.tsv`): GCCharSkill_Send
  (logic 101…105, target 1001), sau 600 ms GCCharDirectImpact + GCDetailHealsAndDamages (sender = MySelf 1001 như
  oracle), NPC 赵天师 57 / 木人 346 / 稻草人 305 / thỏ 391 / khỉ 1520 cùng vị trí và hướng.
- Khác có chủ ý: vị trí vào cảnh = điểm teleport (160.5,152.5) thay cho GCObjTeleport ở giây 3 (dự án chưa có handler
  965); ngoại hình MySelf lấy khung ghi âm của fixture Đại Lý (CY oracle chỉ vẽ đầu + tóc do thiếu GCDetailEquipList).
- `ReplayStream` (NetCore): `LoadScenario`, GCConnect/GCEnterScene mã hoá lại theo cảnh/vị trí/obj; khung ngoại hình
  nhân vật ghi âm (455/1772/288) chuyển sang obj kịch bản; bước giao gói theo `enterTime + at + CYS_WORLD_SCENARIO_DELAY_MS`.
- `CysWorldReplay`: `StepScenario` — camera CY đọc từ bộ nhớ (`cameras.tsv`: pitch 40, fovy 35, yaw −23.98 / −34.67,
  orbit 14,6 m = zoom 0.4 của [6, 27.5]) ở chế độ classic; chụp `CYS_SFX_SHOT_MS` (mặc định 300,800,1300) sau mỗi
  tag, nhãn `<tag>-a|b|c…`; `CYS_SFX_TRIGGER=<tệp>` ghi nhãn ngay trước khi chụp (capture.now của proxy D3D9);
  `CYS_SFX_LOG=1` in thời điểm ms của skill send / animation hit / direct impact / damage board.
- Handler mới `GCCharImpactListUpdate` (324) → `OC_UPDATE_IMPACT_EX` (port 0.85).
- Chạy: `sfx_stage.ps1 -N <n>` (stage CanonicalCY 1280×720) rồi
  `sfx_run.ps1 -Stage <stage> -Scenario <txt> -Out <thư mục> [-Env 'CYS_SFX_SHOT_MS=…;CYS_SFX_CAM=zoom,yaw'] [-Trace]`
  (lấy `Build\game-slot.lock`, 0 socket, tự thoát).
- So: `Tools\render\sfx_compare.py` (CY | trước | |diff| | sau | |diff|, số đo `mad_*` và năng lượng hiệu ứng
  `fx_*` = trung bình max(0, luma − luma khung nền không hiệu ứng) trong vùng cắt); `make_sheets.ps1`.

## 2. Mã CY đã đọc (FACT, Ghidra headless chỉ đọc)

| Hàm CY | Việc | Khác 0.85 |
|---|---|---|
| `FUN_14057d2f0` (GCCharDirectImpact Execute) | dựng _LOGIC_EVENT kiểu damage/EFFECT, lệnh 0x12; gói CY chỉ có target, sender, impact (Read `14084fe60`) | — |
| `FUN_1405ea110` case 0x12 → `FUN_1405f1750` | **luôn** xếp vào `m_listLogicEvent` (begin = now, remove 10000) | 0.85 làm ngay nếu sender sẵn sàng |
| `FUN_1405f1990` (Update_LogicEvent) | làm khi sender −1 / không thấy / `IsLogicReady`; quá hạn thì bỏ | như 0.85 |
| `FUN_1405eb160` (vftable +0x1e8 IsLogicReady) | chưa sẵn sàng chỉ khi `0 < count ≤ n` và (count ≠ n hoặc đang SKILL_SEND chưa hit) | **count ≤ 0 = sẵn sàng** |
| `FUN_1405f52c0` (OnAnimationHit, nhận chỉ số hit) | đặt +0x330 BeAttackEffectShowed theo từng HitTime; chiêu nhiều hit so `count ≤ +0x33c + index` | 0.85 không đăng ký listener |
| `FUN_1405f1cf0` (DoLogicEvent_Damage) | EFFECT: nhóm `rand()%5` của ImpactDirectly (bước 0x20), lọc cấp hiệu ứng `DAT_14103a37c` + cột +0xc0, kiểm `FUN_140695640` | 0.85 nhóm đầu, không lọc |
| `FUN_1405f2530` (DisplayDamageBoard) | cổng: caster/receiver là MySelf, pet, summoner của mình; mất máu **một** bảng kiểu 6/7/1 (+0xd/0xe/0x10 khi cờ +0x40); nộ 2/3, mana 4/5, +0x34 11/12 | 0.85 hai bảng (7 và 1) khi tự đánh mình |

## 3. Bảng khác biệt (số đo)

Vùng cắt 400×320 quanh MySelf/木人. `mad` = |CY − dự án| trung bình RGB (0–255); `fx` = năng lượng hiệu ứng.
Trước = `p27-3` (stage-4, chụp +300/+800/+1300 ms), sau = `p27-5` (stage-7, +500/+1000/+1600 ms);
`sheets\run27-*.png`, `sheets\metrics.jsonl`.

| # | Khác biệt | CY | Dự án trước | Dự án sau | Trạng thái |
|---|---|---|---|---|---|
| D1 | Thời điểm impact 110/175 hiện (sau GCCharSkill_Send) | gói ở +600 ms, hiện ở khung h2a/h3a (INF ≈ +0,7–1,4 s, PrintWindow 0,1–0,9 s) | +1250 / +1234 ms (chờ hết động tác) | +672 / +703 ms (HitTime) | **SỬA** `CYS_PARITY_SKILL_HIT` |
| D2 | Số sát thương khi sender = MySelf | "-505" ở h2a | không bao giờ (IsLogicReady(102) sai với count 0, bỏ sau 10 s) | +656 ms | **SỬA** `CYS_PARITY_LOGIC_READY` |
| D3 | Số bảng sát thương | 1 (cam, kiểu 7) | 2 (cam 7 + tím 1) | 1 (p27-5) | **SỬA** `CYS_PARITY_DAMAGE_BOARD` |
| D4 | Nhóm hiệu ứng ImpactDirectly | rand()%5 | nhóm 0 | rand()%5 (28/110/124/175 5 nhóm giống nhau → ảnh không đổi) | **SỬA** `CYS_PARITY_DIRECT_IMPACT_RAND` |
| D5 | Hiệu ứng impact 175 (cột sáng vàng + vệt đỏ) trong vùng cắt | h3a fx 61,4; h3b 54,9 | h3a 6,6; h3b 4,8 (chưa hiện); mad_crop h3b 70,5 | h3b fx 62,8; mad_crop 70,5 → **46,2** | khớp, lệch pha chụp |
| D6 | Hiệu ứng impact 110 (lửa + quầng đỏ `g01_tianditongshou_02`) | h2a fx 15,3 | 6,3 (không) | h2b 30,8, h2c 11,5 | có hiệu ứng; pha chụp lệch ~0,5 s (D9) |
| D7 | Impact 124 do 赵天师 cưỡi hạc ra chiêu | h4a fx 37,9 | 6,9 | +1438 ms, h4c 18,3 | **CÒN**: không có animation hit cho NPC cưỡi (đòn kết thúc động tác mới hiện) |
| D8 | Buff run-24 (GCCharImpactListUpdate 13/11/1) | vòng tím `buff_fengxue` dưới MySelf (e1-buffs) | không có handler 324; thêm handler thì client chết khi vào world (p24-1, p24-2: Ogre::Exception `ZHUAN DI1.mesh` lúc tạo entity hạt mesh) | vòng tím dưới MySelf như CY, 7 tag / 12 ảnh, quit_complete (p24-3); mad_crop e1-buffs 45,6, e1b 46,0 | **SỬA** (MeshParticleVisualData nhớ mesh vắng, bỏ hạt đó như CY chịu lỗi) |
| D9 | Pha chụp CY | PrintWindow sau `wait` 0–0,1 s, mỗi ảnh 0,1–0,9 s → thời điểm thật không biết chính xác | | | **CÒN**: lượt CY dày `cy27-dense-1` hỏng (oracle không mở cổng 15790, SynSent) |
| D10 | Trace D3D9 so từng lớp (blend/texture/shader/số hạt) | | | | **CÒN**: chưa chạy (proxy + `cy_run.ps1 -Trace`, `sfx_run.ps1 -Trace` đã sẵn) |
| D11 | Font/viền số sát thương | chữ đậm viền tối | chữ mảnh không viền | như trước | **CÒN** (BeHit.txt/font, lớp UI) |
| D12 | Màu tên NPC | đỏ (phe địch) | trắng | trắng | **CÒN** (kịch bản chưa gửi camp; không phải FX) |
| D13 | Xếp hàng mọi OC_LOGIC_EVENT (CY không làm ngay khi push) | ≤ 1 khung | | | **CÒN** (chưa port, ảnh hưởng ≤ 1 khung) |
| D15 | Vị trí 木人 so với MySelf ở run-24 | 木人 chồng lên MySelf | 木人 lùi phía sau ~1 m trên ảnh | | **CÒN** (không phải FX; kiểm hướng/AI 木人 hoặc camera) |
| D14 | Lọc cấp hiệu ứng `DAT_14103a37c`/cột 24 và `FUN_140695640` | | | | **CÒN** |

`mad_full` cả khung giữ ~36–43 ở mọi cặp vì HUD CY ≠ HUD dự án, MySelf CY không có thân, hạc 赵天师 vỗ cánh khác pha.

## 4. Không lùi

- Build rc 0 sau rebase main (`build-11-rebase.log`).
- `cys_world_tests --replay-source` fixture Đại Lý: PASS 20/20 (`world-tests-replay-source.log`).
- Replay cũ `regress-replay-1` (fixture Đại Lý, -Move -Camera, stage-9): PASS (`run.json` passed=true).
- `Tests\scene\run_scene_test.cmd`: PASS (failures 0, unknown keys 0; `scene-test.log`).
- Kịch bản run-24 `p24-3` (stage-10): quit_complete, decode_failures 0.

## 5. Bẫy

1. `SetAnimationHitEvent` của 0.85 bị comment: mọi damage/impact chờ hết động tác (~1,25 s). Listener dùng chung
   `mCallbackFuncInfo` với AnimationFinish — cùng id đối tượng nên an toàn.
2. Kịch bản gửi GCDetailHealsAndDamages với sender = MySelf (như oracle): chỉ hiện nhờ quy tắc count ≤ 0 của CY.
3. Dữ liệu CY thiếu `ZHUAN DI1.mesh` (07e 1.3): buff `g01_buff12` ném Ogre::Exception khi hạt mesh tạo entity lần đầu (`_notifyParticleMoved` → `createVisualData`, không phải `AddEffect`).
4. Dòng tag của oracle ghi cùng lúc GCCharSkill_Send; `wait` của runner khớp sau 0–0,1 s; mỗi PrintWindow 0,1–0,9 s.
5. `run_cy_oracle.ps1` nhận `-View` hashtable: gọi bằng `&` trong job, không qua `powershell -File`.
