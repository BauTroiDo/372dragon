# Kiểm tra kỹ năng, thanh nhanh, trang bị — 23/09/2026

## Phạm vi và nguồn

Client thay đổi: CY-Source, ứng viên `Build/world-gui/stage-actions-23`. Các bản
`client`, `client_GL`, `Tools/DATA NEW/CY Game`, `Assets/CanonicalCY` chỉ đọc.
Máy chủ thay đổi duy nhất: `/home/ubuntu/cys-test-20260913` (15733/15734).
Đã cập nhật Play chính ngày 23/09/2026 lúc 15:51, sau các lượt kiểm chứng bên dưới.


## Sửa đổi

- Tooltip kỹ năng đọc đúng SkillData Tip cột1 (GL cột3), thay cho paraPair11 cũ.
  Skill374 → SkillData1397 có mô tả, pair11 rỗng. Công thức `{A:...}` chưa có
  bộ tính đầy đủ: dùng mô tả Interface thay vì hiển thị token hoặc khung trống.
- Thanh nhanh: mở đủ50 ô; ba trang F; Alt+số30..39; nối callback SetMenuBarPageNumber
  trước đây rỗng. Gửi tag128..177, dịch vềsettings2..51 để tránh chat legacy22..29.
  Khôi phục cả50 khi login. API chat dùng chỉ số native; alliance112 vượt96 bản ghi
  private nên chưa hỗ trợ lưu tab đó, không ghi tràn hoặc đè thanh nhanh.
- Item trên bar lưu loại item, tra lại vị trí túi mỗi lần cập nhật/sử dụng. Giữ loại
  khi cạn item, xóa action/count tạm thời; tìm lại chồng còn lại sau khi di chuyển túi.
- Durability lấy NamedArea ActionArea, lùi2px bên trong ô; fallback rect có inset.
  SelfEquip giữ253control/tên/sự kiện, rộng756 thay820, gom các vùng chỉ số trống;
  chỉ số chiến đấu dùng đủ212px khi không có số cộng,132px khi có số cộng.
- NB shop: lọc1741 lượt hàng trên25 cửa hàng currency5/6 có ngoại hình khớp danh mục
  Wardrobe đã xác thực. Giữ vật phẩm nhuộm/không xác định. Backup:
  `/home/ubuntu/cys-test-20260913/backups/wardrobe-shop-20260923-140116`.
  Frame932×600; vùng danh sách rộng hơn, dòng48px; sidebar120px; dời lịch sử mua lên28px
  để không chồng footerhai dòng. Danh mục hết hàng có thông báo và trang0/0.
- Gem: chặn ID nguồn/đích không có trong GemInfo trước mọi trừ ngọc/phù/tiền.
  417 viên có dữ liệu;30 công thức số học có đích thiếu. Backup
  `/home/ubuntu/cys-test-20260913/backups/gem-recipe-20260923-135200`.
  Chạy hàm production bằng Lua với inventory double: hai ca sai không tiêu hao;
  ca hợp lệ tiêu hao đúng và tạo50501001. Đây không phải chứng nhận toàn bộ UI ngọc.
- Tuyệt Tình4515: GL5723 trỏ action11088 → line7012/7013 →
  `cy4_s_ab77edccf189755e` / `cy4_s_1e011682e1d1a4b1`, cùng ba hiệu ứng chém và HitTime0.2.
  Bốn biến thể CY nam/nữ (riêng vũ khí / phổ thông) có HitTime-1. Overlay khôi phục0.2,
  giữ animation/effect/sound. Thay riêng archive EffectFolder trong WXResources.cfg bằng bản overlay có đủ
  ba file all.effect/all.particle/all.skill; hai file hiệu ứng còn lại giữ nguyên byte.
  Không mount cả Pre/Canonical/Post cho script vì sẽ đăng ký trùng toàn bộ template.
  Server eventenginer nhận delaytime nhưng bỏ qua; nay riêng4515 áp impact sau tối thiểu
  700ms của GL cộng thời gian bay khoảng cách/15m/s từ Bullet305. Giữ caster/logic
  ở thời điểm bắn, kiểm tra target còn sống/còn đúng đối tượng trong scene trước callback.
  Đây là phần tương thích có suy luận về thời gian bay, không tuyên bố mã native giống hệt.
  Client cũng giới hạn mốc phát đạn của từng lệnh4515 ở700ms nếu lệnh đánh tự động
  tiếp theo tới sau mốc HitTime0.2 của cùng animation; đồng thời cho nhận lệnh
  kế tiếp sau700ms để không xếp hàng tới cuối clip2.4s; tránh giữ viên thứ2 đến hết
  chuỗi ba nhịp. Đây là sửa tương thích riêng4515, không đổi các skill khác. Backup `backups/jue-projectile-20260923-145844`.

## Kiểm chứng đã có

`Build/Logs/2026-09-23-actions-audit/`:

- `live-quickbar-7`: kéo kỹ năng vào ô trống;50binding; F1/F10 của3trang thực sự gọi
  0,9,10,19,20,29; Alt1/0 gọi30,39; có skill gửi server; di chuyển; thoát sạch.
- `live-quickbar-relogin`: đủ50 ô sau login; Mongo settings3..52 (one-based) đều35.
- `live-item-shop-2`: kéo potion30001001 lênF1; đổi vị trí túi; dùng3→2→1→0,
  đổi chồng tự động; bấm khi hết không có itemảo. Mongo đã trừ đúng3, giữ shortcut.
  NB hủy không mất tiền, mua đúng1 và trừ20; đổi trang/tab/mở lại; danh mục thú cưỡi
  đã lọc rỗng có notice0/0. Thoát sạch, run passed.
- `live-quickbar-6`: CellSkin errors0; SelfEquip đầy/nửa/gần hết độ bền, ô trống,
  Esc và di chuyển thực tế. QuickbarF của lần này FAIL, đã sửa và test7 mới PASS.
- `live-jue-before-shop6`: bằng chứng tái hiện ở scene6: cast259122156,
  EXP cùng giây259122xxx; bullet259124578, hit259124734 — EXP trước đạn khoảng2.4s.
  Không dùng lần này làm gate xuất bản vì probe Tab mở SceneMap che shop/quit.
- Các lần Jue scene0 và loginflag8 là lỗi fixture/cache sau phiên bị ngắt;
  đã giữ báo cáo lỗi, không gọi chúng là PASS. Fixture phải seed lại sau restart.
- Lần `live-jue-after-near` chưa mount EffectFolder nên marker không nạp: FAIL timing.
  Đã sửa generator mount và probe đóng bản đồ Tab trước khi kiểm tra tiếp.

- `live-jue-final2`: bản cuối Game4c80601b, khoảng cách lúc chọn chiêu11.69m,
  đạn chạm261445390 → EXP261445875 (sau485ms). Lệnh tự động403 được giải phóng
  ở tuổi700ms, không chờ hết clip. Di chuyển, không crash, thoát được máy chủ xác nhận.
  Server kiểm tra cú pháp/Lua delayed-impact PASS; invalid/dead/replaced target bị bỏ,
  skill khác giữ xử lý cũ.

## Các câu hỏi đã xác minh và giới hạn

- Môn phái: join→change_menpai_points→wash_points tính lại bảng theo tên phái,
  BaseValueTable theo ID đã ánh xạ. Tuyệt Tình CY14 khớp server gốcGL16.
  Level15 (lực/linh/thể/định/thân): ThiếuLâm30/4/41/8/12;
  VõĐang4/39/22/19/11; TuyệtTình4/31/26/16/18. Một số phái có bộ5điểm giống nhau,
  nhưng hệ số chiến đấu khác (TuyệtTình có AINFOTYPE1=7800, VõĐang4400).
  Không thay số liệu cân bằng khi chưa có bằng chứng sai.
- Bay tự do: chưa có trục tăng/giảm độ cao hoặc giao thức điều khiển tự do.
  Bay bằng thú cưỡi hiện dùng độ cao CharMount col22; chọn ngoại hình thú bay ở
  Phòng thay đồ rồi dùng nút Lên / xuống thú. Chỉnh Y trong preview không phải bay thế giới.
- Thiên cơ cẩm nang: StrDictionary SSCK_180821_11 xác nhận nút Packet_Temporary_Button;
  Lua gọi Bank:AskTemBankList. Host vẫn stub, không thấy backend/túi tương ứng:
  chưa hoạt động; không gán nhầm với mở rộng hành trang hay quà Càn Khôn.
- Viền đặc biệt: Lua SelfEquip_UpdateZhiZunAnimate hỗ trợ loại1/2 →
  ZhiZun_Flash_Big / JunXian_Flash3. Lua_GetEquipZhiZunType hiện ActionZero.
  Native còn kiểm cấp/quality/flag riêng; chưa ánh xạ được flag itemextra+0xd0.
  Chỉ số cao hoặc sao nhiều chưa đủ căn cứ để tự bật viền.
- Gem: đường khảm bằng XSCRIPT701614 từng có test tăng thuộc tính ngày17/09;
  đây là bằng chứng lịch sử, không phải chạy lại toàn bộ lần này. Gemcompose Lua
  gọi Do_Combine4đối số, host0.85 vẫn hàm2đối số và CGGemCompound không có modern
  mapping; Lua_GemComposeLayedItem_Update cũng stub. Vì vậy chưa thể gọi toàn hệ
  ngọc là hoạt động tốt. CGUseGem507 không có handler private; UI nâng cao ngọc
  thời trang/ngọc giáp vẫn có luồng chưa được triển khai. Đã đọc LuaGL trước sửa.

## Triển khai

- Play: `Build/world-gui/stage-play-21/Play.cmd`.
- Game SHA256: `4c80601ba4c0f73db0d9b273be13b3fdaf4637084193379afe51add0c949f0d1`.
- `live-ui-final2`: kéo kỹ năng vào ô trống, ba trang F, Alt+số, 50 ô; SelfEquip
  đầy/nửa/gần hết độ bền và ô trống; Esc và di chuyển thực tế; shop hủy/mua/đổi
  trang/đổi tab/mở lại. Danh mục trống đã được xem ảnh, thông báo không bị lưới che.
- `live-relogin-final`: cả 50 ô được khôi phục sau đăng nhập lại.
- `live-items-final`: kéo item vào F1, chuyển ô túi, dùng 3→2→1→0, chuyển sang
  chồng còn lại; bấm khi hết không tạo item ảo. Đối chiếu Mongo: đúng ba vật phẩm
  đã được tiêu hao và phím tắt vẫn lưu loại item. Không suy rộng thành bảo đảm
  mọi loại vật phẩm và mọi tình huống mạng đều không có lỗi.
- Bốn lượt cuối (gồm `live-jue-final2`) cùng Game cuối, đều qua 20 kiểm tra của
  runner, thoát sạch và không có lỗi handler/crash. Lượt Jue diễn ra trước sửa
  hiển thị thông báo shop: manifest trước sửa được lưu, gate chỉ chấp nhận khác
  bốn bản layout/Lua YuanbaoShop; code, hiệu ứng, cấu hình và overlay khác phải
  khớp hoàn toàn. Nhịp đạn đầu chạm trước EXP 485ms; nhịp tự động kế tiếp được
  phát ở tuổi 700ms. Mục tiêu đã chết nên callback impact kế tiếp được bỏ.
- `publish_actions_audit.py` kiểm tra hash/chỉ dấu kết quả rồi sao lưu và thay 18
  file. Backup: `Build/backups/actions-equipment-play/20260923-155137`.
  Manifest và launcher được cập nhật, các cờ probe được tắt trong launcher Play.
- test15/GUID200016 đã khôi phục toàn bộ BSON từ `test15-before.json`, kiểm tra
  bằng nhau chính xác; gồm tiền NB, vật phẩm, trang bị, kỹ năng và phím tắt.
  Chứng cứ: `fixture-restored.txt`.
- Máy chủ riêng sau kiểm tra: cả 6 dịch vụ chạy, 16/16 cổng lắng nghe, không còn
  kết nối client thử. Chứng cứ: `private-health-final.txt`.
  Không thấy traceback/lỗi delayed impact/lỗi OBJ_UPDATE liên quan trong đoạn
  log đã kiểm từ 15:20. Vẫn có cảnh báo `May overload, message queue length`
  trong Game; chưa xác định nguyên nhân, không xem lần kiểm này là chứng nhận
  hiệu năng máy chủ. Chi tiết đếm trong `private-final-logcheck.json`.

Ảnh sau sửa nằm trong `Build/world-gui/stage-actions-23/ScreenShots`:
`cys-gl-261893484-skill-description-restored.png`,
`cys-gl-261893484-cells-selfequip.png`,
`cys-live-261924265-nbshop-1-open.png`,
`cys-live-261924265-nbshop-empty-wardrobe.png`.
Một số tên hàng và nhãn danh mục tiếng Việt dài vẫn bị cắt trong chiều rộng cố
định của shop; các lượt trên kiểm tra giao dịch và bố cục đã sửa, không chứng
nhận mọi chuỗi bản địa hóa đều hiển thị trọn vẹn.
