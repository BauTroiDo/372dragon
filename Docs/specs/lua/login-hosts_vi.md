# P1-2: host đăng nhập — 13/09/2026

Đợt này thực hiện `SetSoftKeyAim`, đồng hạng cao nhất trong bảng P1-1 (2 lượt). Phạm vi: source/test/spec trong CY-Source, chỉ Game của CI với `-fl -cys-offline-ui-smoke`, danh sách giả 127.0.0.1:14400. Noto/UTF-8 giữ nguyên. Chưa sửa lỗi nhãn đỏ hoặc mở kết nối xác thực.

## Hợp đồng SetSoftKeyAim

`SetSoftKeyAim(editboxName:string/number)` không trả giá trị. Chuyển tham số đầu qua biên Lua/C-string, phát đúng một sự kiện `SET_SOFTKEY_AIM` với tên ô nhập ở arg0. Bỏ qua tham số thừa. Không gõ ký tự hoặc lấy nội dung ô nhập trong hàm host.


Source: `Src/Client/LuaApiGen/CysHostGlobals.cpp`, `Src/Engine/Interface/TDEventDefine.h`, `Src/Client/WXClient/Event/GMEventSystem.cpp`. Không sửa generated stub. Evidence tĩnh: `Build/Logs/2026-09-13-gpt-login-hosts/{set-softkey.txt,event-softkey-name.txt,reference-strings.json}`.

## Kiểm thử trước CI

- Lua 40/40 (31 cũ + 9 mới). Cùng snippet `SetSoftKeyAim('LogOn_ID'); SetSoftKeyAim('LogOn_PassWord')`: stub 2 lượt/1 dòng → 0 lượt/0 dòng và 2 sự kiện có đúng tên đích. Kiểm không ghi đè hàm/false, UTF-8, NUL, kiểu sai, tham số thừa, lỗi dịch vụ và tách context. Log `Build/Logs/2026-09-13-gpt-login-hosts/lua-tests`.
- Widget 34/34 (30 cũ + 4 mới), dùng DLL đã CI của bb67e6a; source widget không thay đổi. Mouse/input thật trên dữ liệu tổng hợp kiểm gõ vào ô thường, chuyển sang SafeIME che chữ, backspace `中ế` thành `中`, báo đích không tồn tại. Không dùng tài khoản/mật khẩu hay clipboard. Log `Build/Logs/2026-09-13-gpt-login-hosts/keyboard-tests`.
- CI và Game runtime đã chạy sau commit; kết quả tại mục tích hợp dưới đây, không suy từ unit test.

Lệnh từ gốc CY-Source (OutDir phải mới):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tests/luaapi/run_tests.ps1 -Jobs 5
powershell -NoProfile -ExecutionPolicy Bypass -File Tests/ui/run_widget_tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File Tools/build/ci_loop.ps1 -IntervalMinutes 1 -IdleMinutes 0 -MaxHours 1
powershell -NoProfile -ExecutionPolicy Bypass -File Tests/ui/run_game_offline_smoke.ps1 -Stage Build/gpt-p1-1-20260913/stage-HASH -OutDir Build/Logs/game-offline-ui/recheck-NEW -Seconds 60
```

## Kết quả tích hợp 83b5152

- CI 33/33, build rc0/228,9 giây/490 bước; 486 cảnh báo thuộc 2 loại cờ ngoại lệ đã có, không có loại mới. Stage0, smoke6/6, checks3/3; census5 viewer giữ nguyên. GPU dùng chung, không suy hiệu năng. Loop dừng06:33:30.
- Game 62,184554 giây, harness chủ động dừng; không fatal, không quan sát socket. Missing7→5 lượt, distinct5→4, riêng SetSoftKeyAim2→0. Đã nạp16 layout, thêm SoftKeyBoard. WXClient/UISystem không có dòng Lua-error trước hoặc sau.
- Hai cặp server/account 1024×768 trước/sau giống từng pixel: SSIM1/PSNR99 theo `Tests/oracle/compare.py`. Ảnh đã xem thủ công; nhãn đỏ vẫn sai như trước. `Build/Logs/2026-09-13-gpt-login-hosts/images-83b5152/` giữ *_before.png, *_after.png và *_diff.png.
- **UI vẫn có lỗi:** thuộc tính563→573, thêm10 thông báo ở SoftKeyBoard: FrameEnabled1, BackgroundEnabled1, HorzFormatting3, ClickSound1, NormalImage4. `Build/Logs/2026-09-13-gpt-login-hosts/keyboard-baseline-identity.json` xác nhận cùng byte layout/script/CEGUIBase/CEGUIFalagard trước–sau; thay đổi host làm nạp cửa sổ vốn chưa chạy trong baseline. Không gọi là UI sạch lỗi, không tắt log hoặc bỏ thuộc tính để giảm census. Chưa hoàn thiện hình thức bàn phím hay toàn bộ P2-6.
- `Build/Logs/2026-09-13-gpt-login-hosts/event-id-comparison.json`: giữ303 ID cũ, thêm GE_SET_SOFTKEY_AIM ở303. Kết quả và lệnh thu thập nằm trong `Build/Logs/2026-09-13-gpt-login-hosts`, báo cáo chính `runtime-comparison.json`, bảng thật4 hàm ở `Build/Logs/2026-09-13-gpt-login-hosts/missing-host-top20.tsv`. Không thêm hàng giả cho đủ20.

## Các host còn lại (cập nhật 13/09/2026 07:14)


Toàn P1-2 chưa đạt. Những giới hạn UI/data từ `Docs/specs/ui/login-offline_vi.md` vẫn áp dụng; không coi phép thử host là đăng nhập server hoặc kiểm điều khiển trong thế giới.
