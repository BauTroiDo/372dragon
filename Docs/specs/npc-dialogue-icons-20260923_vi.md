# Icon trước lựa chọn NPC — 23/09/2026

Phạm vi: client CY dựng từ nguồn, phát hành vào `Build/world-gui/stage-play-21`. Không sửa các client tham khảo hoặc máy chủ gốc.

## Đối chiếu trước khi sửa

- `Assets/CanonicalCY/Data/InterfaceFolder/Schema/TLBBLook_ComplexWindow.looknfeel.xml` khai báo 32 mục `QuestButtonImage`, index 0–31. Các ảnh trong UIIcons, Menpaishuxing và NpcVisible đều có ô nguồn **25×25**. `Tools/game/audit_npc_icons.py` đọc độc lập XML look và imageset, kiểm tra ảnh tồn tại, xuất `Build/Logs/2026-09-23-npc-icons/catalog.json`. `source-atlas.png` là bảng ảnh cắt từ texture tham khảo để kiểm tra, không phải tài nguyên thay thế trong game.
- `C:/TLBB/085/client/Data/Interface/Schema/TLBBLook_ComplexWindow.looknfeel.xml` dùng cùng ánh xạ 0–17, nhưng bản CY có thêm bộ NpcVisible và khác mục 18–19. Giữ ánh xạ theo bộ giao diện CY đang dùng.
- `Quest.lua:Quest_EventListUpdate` chuyển loại 32→1, 33→2, 34→19; loại ngoài khoảng 1–34 về 8. `Icon_Preference` là thứ tự sắp xếp, không phải bảng chọn ảnh. Chuỗi Lua gửi vào `AddOptionElement` là `text&script,index$icon`. Parser đang lấy các dấu phân cách từ cuối, không nhầm mã màu hoặc dấu phẩy trong nội dung. Không thay đổi các quy tắc này.
- Bốn alias `WoWLook/QuestButton_1..4` đều trỏ tới `TLBB_QuestButton` trong bộ CY; biểu tượng được lấy từ `QuestButtonImage`, không phải từ số alias. Look nút chỉ có nền/trạng thái và chữ, không vẽ thêm một icon thứ hai.

## Lỗi được sửa

`FalagardComplexWindow::AddChildElement_Option` đã tìm đúng mục ảnh nhưng ép StaticImage thành **16×16**. Các nét nhỏ bị thu lại. Lớp ảnh cũng chưa đặt `MouseHollow`/`MouseMoveHollow`, nên nó trở thành control nhận chuột tại phần icon thay vì để nút phía dưới nhận hover/click.

Sửa tại nguồn C++ dùng chung: lấy kích thước ô nguồn từ `Image::getSourceTextureArea()`, căn giữa theo chiều cao thực, cho ảnh trang trí xuyên chuột xuống nút. Đây là bố cục tọa độ pixel cố định; không áp hệ số AutoScaled của atlas lên kích thước control. Lỗi tra ảnh được ghi vào log thay vì bị bỏ qua im lặng. Không đổi texture, mã icon, hành động NPC, Lua hay nguồn sinh layout.

## Kiểm tra và phát hành

`CysNpcIconProbe`/`CysNpcIconFixture` chỉ hoạt động trong tiến trình smoke có `CYS_NPC_ICON_LIVE=1`. Trước hết kiểm tra menu từ NPC thật qua `CysNpcInteractProbe`, sau đó dựng ComplexWindow riêng trong khung Quest, không gắn callback Lua/network, để kiểm đủ 32 ảnh. Bộ đo bấm icon và chữ qua đầu vào CEGUI thật, đối chiếu cùng tên nút nhận sự kiện; cuộn chuột qua hàng có icon bằng hàng đợi input game, đóng Esc rồi kiểm vị trí nhân vật thay đổi. Cửa sổ thật được trả lại trước khi đóng.

`Tools/game/deploy_npc_icons.py` kế thừa các cổng kiểm binary/hash, phiên chơi và backup của công cụ phát hành trước, bổ sung marker bộ đo và đối chiếu 32 mục runtime với XML bằng `audit_npc_icons.py`. Chỉ phát hành khi các cổng này đạt. Kết quả phiên và đường dẫn backup được ghi bổ sung sau kiểm tra.

## Kết quả

- Build UI/Falagard và Game thành công; `git diff --check` sạch.
- `live-01`: mọi ca icon/input đều đạt, nhưng không được dùng để phát hành vì một script ID giả trong bộ đo trùng chuỗi mà cổng kiểm mật khẩu tìm trong log. Đã thay ID giả, giữ nguyên cổng kiểm, dựng lại UI và chạy mới.
- `Build/Logs/2026-09-23-npc-icons/live-02`: **20/20 PASS**, exit 0, không dump/lỗi Lua/handler/decode; 32 mã icon qua sáu trang, marker `CYS-NPC-ICON: RESULT states=32 pages=6 errors=0`. Các ảnh là ô 25×25 đúng atlas; icon và chữ đều nhận đúng cùng mục; cuộn qua icon hoạt động và không zoom camera; Esc đóng Quest; nhân vật di chuyển sau đóng.
- Menu NPC từ máy chủ được kiểm trước dữ liệu mẫu. Các trang 32 mã là dữ liệu cục bộ riêng để kiểm renderer, không đại diện cho việc đã thử mọi NPC/chức năng máy chủ. Các ca bấm dữ liệu mẫu không gửi gói mạng.
- Đã xem ảnh menu thật, nhiệm vụ, cửa hàng/dịch chuyển và nhóm NpcVisible trong game; đối chiếu với contact sheet texture gốc. Tên mẫu dài ở vài trang bị cắt theo chiều rộng khung sẵn có; không tuyên bố sửa bố cục văn bản dài trong đợt icon này.
- Đã phát hành lúc **10:52:52**; backup `Build/backups/npc-icons-play/20260923-105252`. Game SHA-256 `43f06692349dcba8b09bca76b66831708771dcde1e792d3ad6e98a8c90bf4e4e`. Sáu binary/PDB khớp bản đã thử và 37 mục binary của Play khớp manifest. Overlay/Patch giữ đúng hash trước phát hành. Launcher xóa cờ `CYS_NPC_ICON_LIVE` khi mở Play.

- Phiên Play sau phát hành `Build/Logs/2026-09-23-npc-icons/play-final`: **20/20 PASS**, exit 0, 103,9 giây, không chạy bộ đo icon, không lỗi Lua/handler/decode hoặc dump; nhân vật di chuyển và thoát bằng `quit_complete`. Game/manifest của phiên khớp bản Play trên đĩa, kiểm lại đủ 37 binary thành công.
