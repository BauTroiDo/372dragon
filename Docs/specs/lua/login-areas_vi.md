# P1-2: mô tả vùng đăng nhập

## Hợp đồng và bằng chứng

`GameProduceLogin:GetServerAreaDis(index:number)` trả đúng một chuỗi mô tả vùng tại chỉ số 0-based. Số được cắt về 0 theo int32; NaN/vô cực/ngoài int32 trở thành INT32_MIN và trả rỗng. Chỉ số âm hoặc vượt số vùng trả rỗng; kiểu khác number báo lỗi. Dùng biên C-string như B, không trả tên vùng thay mô tả. Giữ receiver và mọi method khác, chỉ đăng ký vào ô nil trước generated stubs.


## Phạm vi reader CY

Game ưu tiên `Patch/LoginServer.txt` **UTF-8 plaintext**; chỉ dùng `Patch/WXLoginServer.txt` INI lịch sử khi file hiện đại không tồn tại. Lỗi file hiện đại phải hiện rõ, không rơi về INI để che lỗi. INI không có trường mô tả, nên các vùng legacy giữ mô tả rỗng.

Reader cung cấp danh sách vùng normal với 14 hoặc 15 cột. Giữ nguyên byte tên/mô tả UTF-8, thứ tự vùng và server, mô tả đầu tiên kể cả rỗng. Nạp thành công toàn bộ rồi mới công bố. File tối đa 2 MiB, dòng 16 KiB, kiểm UTF-8/NUL, tên, provider 0–2, status 0–4, nhóm 0–2, endpoint host:port. Dữ liệu sai báo số dòng, không in dữ liệu dòng.

Đây là profile plaintext có kiểm lỗi của CY, không cam kết tương đương B với dữ liệu hỏng: B dùng atoi, có nhánh kẹp giá trị và tạo vùng trước khi loại server sai. Không giải mã wrapper trong Game, không triển khai danh sách đặc biệt/recommendation. Giữ 4 endpoint trong kết quả reader; adapter vào mạng 0.85 chỉ lấy endpoint đầu. Chưa làm failover hay giao thức đăng nhập thật. Cột 3/5/6/13/14 chưa được dùng bởi adapter này.

Kiểm thử chỉ dùng dữ liệu tổng hợp và Game CI `-fl -cys-offline-ui-smoke`, một server giả 127.0.0.1:14400. Noto/UTF-8, giới hạn StrFilter và thuộc tính UI từ `Docs/specs/ui/login-offline_vi.md` giữ nguyên.

## Kiểm thử và tích hợp d1b2c16

- Lua/reader **29/29**: 28 ca tổng hợp và 1 ca đọc plaintext tham chiếu (1 vùng, 1 server, mô tả 47 byte, không mở socket). Cùng Lua gọi hai vùng: stub 2 lượt/1 dòng → host 0 lượt/0 dòng; trả hai mô tả khác nhau, không lấy tên vùng. Kiểm UTF-8 Việt/Trung, mô tả rỗng đầu tiên, thứ tự, nhóm 0/1/2, file lỗi không công bố một phần, chỉ số/kiểu sai, ownership/non-override và lỗi dịch vụ. `tests-2` build/run 0, source giữ nguyên, 0 cảnh báo. `tests-1` lỗi compile fixture LuaStackObject được giữ làm lịch sử, đã sửa trước source commit.
- Query túi hồi quy **25/25**, build/run 0, 0 cảnh báo, dùng LuaPlus thật và bag mô phỏng (`query-regression`). Không tính lại các ca widget/font/hotkey của phiên trước.
- Preflight **6/6**, không chạy Game: chặn primary ngoài dummy, backup sai cổng, nhiều server, sai số cột, nhóm đặc biệt; bản đúng đi tới sentinel Helper.exe rồi dừng trước Start-Process. Kết quả `preflight/results.json`, log `*-2.log`. Lần thử đầu thiếu Get-FileHash do Python truyền PSModulePath của PowerShell 7 sang PowerShell 5; đã sửa môi trường của helper, giữ log lỗi đầu.
- CI **33/33**, stage 0, smoke **6/6**, checks **3/3**: protocol 1.699/1.699, pathlib 488/488, scene 548/548. Census viewer 5/5 giữ nguyên. Evidence: `Build/Logs/2026-09-13-gpt-login-areas/{runtime-comparison.json,missing-host-top20.tsv,census-comparison.json,modern-fixture.json}`; CI `Build/Logs/ci/d1b2c16`. Build 227,5 giây/485 bước/484 cảnh báo thuộc 2 thông báo cờ ngoại lệ cũ, không loại mới; GPU dùng chung. Loop dừng 07:07:46, hai Game riêng đã thoát. Commit chốt chỉ tài liệu/fixture; kiểm HEAD cuối bằng ci.ps1, không lặp runtime khi Src giữ nguyên.
- Hai lượt Game đều không fatal/Lua error, không quan sát socket, nạp cùng 16 layout. Hai cặp ảnh mỗi lượt giống từng pixel (SSIM 1, PSNR 99); log UI giữ 573 lỗi thuộc tính, không thêm lỗi. Đã xem ảnh: nhãn đỏ StrFilter vẫn sai, chưa chứng minh mô tả Việt/Trung hiển thị đúng trong Game. Byte UTF-8 của mô tả được kiểm ở reader/Lua; Noto/65001 giữ nguyên. Không nhập tài khoản, xác thực hay kiểm điều khiển thế giới.
- Game legacy 60,38 giây và modern 61,57 giây đều do harness chủ động dừng sau thời hạn, mỗi lượt 2 PNG back buffer. So với 83b5152: missing 5→3, distinct 4→3; GameProduceLogin:GetServerAreaDis 2→0 ở cả hai profile. Ảnh và heatmap: `images-legacy` (83b5152 → d1b2c16 legacy), `images-modern` (legacy → UTF-8); đủ 4 cặp 1024×768, 0 pixel đổi. Fixture modern có mô tả `Khu thử nghiệm 中文`, cùng tên vùng/server, provider/status và mọi endpoint dummy như legacy.

Lệnh từ gốc CY-Source, dùng OutDir mới để giữ bằng chứng:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tests/luaapi/run_login_area_tests.ps1 -Jobs 2 -ReferenceList C:\TLBB\085\CY-Source\Build\Logs\2026-09-13-gpt-login-areas\reference-list.bin
powershell -NoProfile -ExecutionPolicy Bypass -File Tests/luaapi/run_query_tests.ps1 -Jobs 2
powershell -NoProfile -ExecutionPolicy Bypass -File Tools/build/ci_loop.ps1 -IntervalMinutes 1 -IdleMinutes 0 -MaxHours 1
# Sau khi CI stage/smoke đã xong; helper yêu cầu stage mới, kiểm SHA 19 binary và Noto.
$env:PYTHONUTF8='1'
& 'C:\Program Files\Python313\python.exe' -B Build/Logs/2026-09-13-gpt-p1-1/prepare_game.py HASH
powershell -NoProfile -ExecutionPolicy Bypass -File Tests/ui/run_game_offline_smoke.ps1 -Stage Build/gpt-p1-1-20260913/stage-HASH -OutDir Build/Logs/game-offline-ui/legacy-NEW -Seconds 60
# Chỉ tạo file modern mới trong stage vừa chuẩn bị; giữ nguyên WXLoginServer.txt.
Copy-Item -LiteralPath Tests/ui/fixtures/login-server-utf8.txt -Destination Build/gpt-p1-1-20260913/stage-HASH/Patch/LoginServer.txt
powershell -NoProfile -ExecutionPolicy Bypass -File Tests/ui/run_game_offline_smoke.ps1 -Stage Build/gpt-p1-1-20260913/stage-HASH -OutDir Build/Logs/game-offline-ui/modern-NEW -Seconds 60
```

Bỏ `-ReferenceList` thì chạy 28 ca tổng hợp. File tham chiếu trong Build chỉ để test reader, không chép vào stage hoặc commit; fixture đã commit chỉ chứa 127.0.0.1:14400. Helper thu thập lượt này: `Build/Logs/2026-09-13-gpt-login-areas/collect_runtime.py`, giữ JSON/TSV/ảnh và dùng `Tests/oracle/compare.py`. Không chạy lại helper lên thư mục ảnh đã có.

## Điểm làm tiếp

Tiếp P1-2: còn Talk:HideContexMenu4Speaker, _G:OpenWindow và DataPool:GetProvincesNum, mỗi hàm 1 lượt. Ưu tiên phục hồi sự kiện HideContexMenu4Speaker; OpenWindow chưa rõ gate, ProvincesNum chưa rõ schema nên không bỏ điều kiện hay trả số giả. UI còn StrFilter và thuộc tính bàn phím. Ngoại lệ UI đăng nhập đã được duyệt; P0-3/material và 7 việc cũ vẫn chờ.
