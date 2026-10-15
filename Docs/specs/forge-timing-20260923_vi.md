# Cường hoá bằng nhịp rèn — đặc tả và bằng chứng

Người dùng đã chọn: thay luồng cường hoá hiện tại; giữ bảng thuộc tính; vàng và
nguyên liệu được trừ khi bắt đầu từng lượt; trượt giảm một cấp và mất lượt;
thành công tự chuyển tiếp; không giới hạn thời gian chờ Space; tối đa +9.
Cấp không xuống dưới 0. Món đã trên +9 được giữ nguyên, không tự hạ dữ liệu cũ.

## Học từ bản hiện có

- CY/GL `EquipStrengthen.lua`: mở bằng UI_COMMAND 1002 tại NPC, vật phẩm lấy
  từ hành trang, gọi script 809262 `FinishEnhance`; bản CY tự tìm nguyên liệu,
  có lựa chọn nâng tự động. `EquipNewStrengthen` là chuyển cường hoá, không
  phải khung cần thay.
- Server sống riêng `/home/ubuntu/cys-test-20260913`: `equip_enhance.lua`,
  `script_base.lua:LuaFnEquipEnhance`, `item.lua:get_next_enhance_config`,
  `human_attrib.lua:cal_enhance_effect`. Cấp thật lưu trên instance trang bị.
- Chỉ số cộng dùng `floor(bonus * thuộc_tính_cơ_bản / 100)` theo ItemEnhance;
  không sửa bảng, không thêm phần trăm tự nghĩ. Chi phí lấy dòng cấp tiếp theo.
- Nguyên liệu dưới cấp trang bị 40: 30900005; từ 40: 30900006 hoặc 30900045
  (Lộ có 11 lượt). Bộ cũ trừ giao tử trước rồi vàng; giữ cơ chế ví này và ghi
  rõ ở giao diện. Trạng thái khóa/giám định/ràng buộc nguyên liệu được giữ.
- Khung/nút/ô dùng TLBB_MainFrame1, TLBB_ButtonCommon, TLBB_ActionButton từ bộ
  đang dùng. Không đổi look chung, không dùng GLResponsive.

## Điểm cần thay có chủ đích

Quay xác suất và bộ đếm an ủi không phù hợp với yêu cầu bấm đúng là lên cấp.
Luồng mới dùng thử thách do máy chủ cấp, nonce dùng một lần, kiểm thời gian
Space và tính lại vị trí; client không gửi cờ tự nhận thành công. Đây là tính
năng mới, không giả làm hành vi native. Dấu nhắc dùng thời gian đã trôi qua,
không đếm frame. Space giữ lâu không tự đánh các lượt kế tiếp.

Trong lượt, trang bị bị khóa trên máy chủ. Hủy/đóng khung/đổi cảnh/rời game
tính là bỏ lượt (giảm cấp và giữ chi phí đã trừ), nhằm tránh chọn lại thử thách
sau khi đã bắt đầu. Lượt đang dở được lưu kèm bản ghi nhân vật và xử lý như
bỏ lượt khi nạp lại sau mất kết nối/khởi động lại. Không có đồng hồ hết hạn
trong khi người chơi vẫn giữ lượt mở.

Ảnh đe/búa được tạo bằng công cụ imagegen tích hợp; prompt và ảnh gốc được
lưu cùng tài nguyên dự án. Đã cập nhật Play sau khi qua kiểm chứng bên dưới.

## Độ khó đã triển khai

| Cấp đích | Vùng trắng trên thanh | Thời gian đi hết một chiều |
|---|---:|---:|
| +1 | 30% | 2,6 giây |
| +2 | 27% | 2,4 giây |
| +3 | 24% | 2,2 giây |
| +4 | 21% | 2,0 giây |
| +5 | 18% | 1,8 giây |
| +6 | 15% | 1,6 giây |
| +7 | 12% | 1,4 giây |
| +8 | 9% | 1,2 giây |
| +9 | 6% | 1,0 giây |

Mỗi lượt có một giây chuẩn bị. Vị trí vùng trắng do server chọn trong khoảng
30–70% chiều dài thanh. Thanh chạy qua lại không giới hạn cho đến khi bấm Space.
Thành công nghỉ 1,1 giây rồi tự bắt đầu lượt kế tiếp và trừ phí mới.

## Nguồn và giới hạn kỹ thuật

- `Tools/server/cys_forge.lua`: luật, trừ phí, khoá trang bị, xác nhận Space.
- `Tools/server/deploy_forge.py`: chỉ cài vào server riêng; chặn cả ba đường
  cường hoá cũ của script 809262; giữ chuyển cường hoá như trước.
- Đường nhân vật thực sự dùng: `GameServer/services/scene/obj/human.lua`.
  `scenecore` gọi lớp này; file trùng tên ở `services/scene/human.lua` không
  được dùng trong đường tạo nhân vật này. Hook lưu/khôi phục đặt ở lớp thật.
- `Tools/game/forge_layout.py` và `Tools/game/forge/EquipStrengthen.lua`: nguồn
  sinh bố cục và trạng thái cửa sổ, dùng đúng frame NPC đã có.
- `Src/Client/WXClient/Network/CysForge.cpp`: kéo thả ô rèn, bắt cạnh xuống
  Space và đồng hồ mili giây; trả điều khiển khi đóng khung.
- `Tools/game/forge/image-prompt.txt` và `forge-anvil-hammer.png`: prompt và
  ảnh gốc tạo bởi imagegen tích hợp. Dùng look hiện hữu cho các điều khiển.

Server tính lại vị trí, kiểm nonce một lần và giới hạn sai lệch timestamp
350 ms. Đây là dung sai đường truyền; không phải hệ thống chống bot hoặc
chứng minh người thật bấm phím. Bản client bị sửa vẫn có thể tự căn nhịp.
Không tuyên bố chống gian lận tuyệt đối.

`test_forge.lua` bao gồm 66 kiểm tra luật, gồm chín cấp, trượt, phát lại,
thiếu phí, sai vật phẩm, khoá/giám định, hủy, khôi phục lượt dở và bình Lộ.
Có kiểm tra tiêu thụ nguyên liệu cuối cùng và dừng trước khi trừ lượt tiếp.

Bảng nhị phân `UICommandIndex.txt` được sinh overlay giữ toàn bộ hàng gốc,
thêm lệnh 990023 tới đúng window ID của lệnh native 1002. Đây là tuyến nhận
 phản hồi rèn; không bỏ bộ lọc định tuyến UI và không phát lệnh tới mọi khung.

## Kiểm chứng trong game

Thư mục bằng chứng: `Build/Logs/2026-09-23-forge`.

- `rules-test.txt`: 66 kiểm tra chạy trực tiếp module server sản xuất với
  đồng hồ/kho vật phẩm kiểm soát được. `build-client-9.log`: build x64 thành công.
- `live-9-cancel`: kéo trang bị và nguyên liệu bằng đường chuột thật; server
  từ chối đổi ô trang bị đang rèn. Bấm Dừng: +2 → +1. Bắt đầu lượt thứ hai
  rồi thoát game: +1 → 0, giữ hai lượt chi phí.
- `live-10-relogin`: đăng nhập lại, báo giá trả cấp 0, nguyên liệu còn 28/30;
  đổi ô trang bị thành công rồi đổi về chỗ cũ. Đóng Esc và đo vị trí nhân vật
  thay đổi từ (71,833; 101,958) sang (77,494; 96,297).
- `db-verify-cancel.json`: cấp 0, tiền 999.753/1.000.000, nguyên liệu 28,
  không còn `cys_forge`, bit khoá trang bị đã gỡ. Phí hai lượt = 132 + 115 = 247.
- `live-7` là kiểm tra đầy đủ ban đầu: một lần trượt +2 → +1 rồi tám lần
  Space đúng đến +9. Số dư xác minh sau thoát là 998.309, nguyên liệu còn 21.
  Các lượt đầu dùng để tìm lỗi Lua/API, định tuyến và bố cục được giữ lại;
  chúng không phải bằng chứng đạt của bản cuối.

Giới hạn đo: dùng client x64 ở 1280×720, tài khoản test15 trên server riêng.
Các thao tác phím/chuột chạy qua cầu kiểm thử của đúng tiến trình game, không
giả gói kết quả thành công. Kiểm tra khoá dùng yêu cầu đổi ô tới server;
`Obj_Item::IsLocked()` là khoá thao tác cục bộ, không đại diện cho bit PLOCK
của server. Không dựa vào cờ cục bộ đó để kết luận trang bị đã an toàn.

Sao lưu server theo thứ tự cài:
`forge-20260923-165308`, `forge-20260923-165935`, `forge-20260923-171323`,
trong `/home/ubuntu/cys-test-20260913/backups`. Khi cần hoàn tác toàn bộ,
phục hồi theo thứ tự ngược để cả script, `scene/obj/human.lua` và hook rời
scene cùng trở lại bản trước. File `scene/human.lua` không dùng đã trả nguyên
trạng từ bản sao lưu ngay trong lúc sửa; bản cuối không phụ thuộc file đó.

## Bản đã phát hành trong workspace

- 23/09/2026 17:45:42: đã cập nhật 14 file vào
  `Build/world-gui/stage-play-21`, giữ các overlay khác và profile máy chủ riêng.
- Game SHA256: `a3e5fe38f09af4885f5b177083bab0b0c57ae5cc6c43b3cd185f291b0132fbaf`.
- Ba lượt đạt trên đúng binary và manifest cuối: `live-9-cancel`,
  `live-10-relogin`, `live-11-final`. Không có lỗi Lua của luồng rèn, crash,
  lỗi giải mã gói hoặc lỗi handler trong các lượt này.
- `live-11-final`: trượt một lần +2 → +1, tám Space đúng → +9, dừng tự động;
  Esc đóng khung, vị trí thay đổi (72,662; 100,434) → (78,317; 94,785).
  `db-verify.json` xác nhận +9, 21 nguyên liệu, 998.309 đồng, không khoá/lượt dở.
- Test15 đã được khôi phục toàn bộ BSON từ `test15-before.json` và so sánh
  bằng nhau hoàn toàn. Không để lại trang bị thử hoặc thay đổi tiền của nhân vật.
- Backup Play: `Build/backups/forge-play/20260923-174542/deployment.json`.
  File này ghi từng file cũ, dấu băm và đường dẫn bằng chứng.
- `health-final.txt`: 6 dịch vụ riêng hoạt động, 16/16 cổng lắng nghe.
  Log server mới không có lỗi `cys_forge.lua`, `equip_enhance.lua` hoặc
  `scriptenginer:call error`. Cảnh báo queue overload của baseline vẫn tồn tại;
  thay đổi này không xử lý hiệu năng scene.

Chơi bằng `Build/world-gui/stage-play-21/Play.cmd`. Tới NPC cường hoá như cũ,
tháo món đang mặc về hành trang nếu cần, kéo trang bị và nguyên liệu vào hai ô,
bấm Bắt đầu rồi căn Space trong vùng trắng. Phí trừ ở mỗi lần bắt đầu, kể cả
lượt tự tiếp tục. Không có thao tác chuyển tiền/vật phẩm khỏi nhân vật khi
chỉ đặt vào hai ô xem báo giá.
