# Động tác ra chiêu và hiệu ứng impact/buff như CY 3.71 (skill-fx-parity, 15/09/2026)


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

`mad_full` cả khung giữ ~36–43 ở mọi cặp vì HUD CY ≠ HUD dự án, MySelf CY không có thân, hạc 赵天师 vỗ cánh khác pha.

## 4. Không lùi

- Build rc 0 sau rebase main (`build-11-rebase.log`).
- `cys_world_tests --replay-source` fixture Đại Lý: PASS 20/20 (`world-tests-replay-source.log`).
- Replay cũ `regress-replay-1` (fixture Đại Lý, -Move -Camera, stage-9): PASS (`run.json` passed=true).
- `Tests\scene\run_scene_test.cmd`: PASS (failures 0, unknown keys 0; `scene-test.log`).
- Kịch bản run-24 `p24-3` (stage-10): quit_complete, decode_failures 0.
