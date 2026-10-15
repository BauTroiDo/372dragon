# Nền ô dùng chung và cuộn chuột — 23/09/2026

Phạm vi: client CY dựng từ source; phát hành vào `Build/world-gui/stage-play-21` sau kiểm chứng. Không sửa kho CanonicalCY, các client đối chiếu hoặc server. Không sử dụng GLResponsive.

## Nền ô: phạm vi thực sự

Lỗi đã sửa trong `FalagardSimpleText::populateRenderCache` là lỗi dùng chung: renderer bỏ qua state imagery của look và chỉ vẽ chữ. Bản sửa ngày 23/09 trước đó đã khôi phục nền/viền và vùng `TextArea` cho toàn bộ lớp này, không có điều kiện theo tên SelfEquip. Những layout không khai báo nền vẫn giữ nguyên ý nghĩa đó.

Kiểm kê `Tools/game/audit_ui_cells_scroll.py` quét 2.032 file layout CanonicalCY, tìm **3.263 ô trong 634 file layout** dùng bảy skin SimpleText có imagery:

| Kiểu | Số ô khai báo |
|---|---:|
| TLBB_SimpleMulitiTextFrame | 3.033 |
| TLBB_SimpleTextFrameLeft | 54 |
| TLBB_SimpleTextFrameRight | 54 |
| TLBB_SimpleTextInfo | 29 |
| TLBB_SimpleTextLace | 77 |
| TLBB_SimpleTextTitleFrame | 7 |
| TLBB_SimpleTextTitleFrame1 | 9 |

Ví dụ ngoài SelfEquip: ActionSkill, Pet, OtherPet, Wuhun, TargetWuhun, SceneMap, các cửa sổ hoạt động và shop. Đây là số khai báo tĩnh; không đồng nghĩa đã mở thử riêng từng cửa sổ. Bằng chứng đầy đủ, gồm đường dẫn và tên control, nằm ở `Build/Logs/2026-09-23-ui-wheel/catalog.json`.

Đã rà các lớp còn lại: ActionButton vẽ `BackgroundImage` cùng `BackImage` của ô trống; StaticImage vẽ Enabled/Disabled và các state frame/background; Listbox và các lớp dẫn xuất sử dụng renderer danh sách; NotSuperList/Item vẽ EnabledBackground/DisabledBackground đúng hợp đồng trong `TLBBLook_NotSuperList.looknfeel.xml` của cả canonical và client gốc. Không gắn thêm nền tùy tiện vào các control cố ý trong suốt.

## Nguyên nhân và sửa cuộn chuột

`WM_MOUSEWHEEL` đã được lớp input chuyển thành `EVENT_MOUSE_WHEEL_UP/DOWN`. Tuy nhiên `CUISystem::InjectInput` thiếu hai case này, đi thẳng vào `default: continue`, nên danh sách không nhận được sự kiện; GamePro_Main vẫn có thể nhận sự kiện để zoom camera.

Đã bổ sung hai case ở luồng input chung, cập nhật tọa độ con trỏ rồi gọi `CEGUI::System::injectMouseWheelChange(+1/-1)`. CEGUI sẵn có cơ chế đi từ control dưới chuột lên cha; nút/chữ/icon trong hàng không chặn việc tìm tới khung cuộn. Sự kiện đã xử lý được đánh dấu trước khi tới camera; phần kiểm tra vùng UI hiện hữu vẫn áp dụng cho vùng khung không cuộn.

Đối chiếu các handler Listbox, MultiColumnList, StaticText, ScrollablePane, Scrollbar của CEGUI và NotSuperList/Achievement của CY: chúng đã cuộn theo step và clamp bằng Scrollbar. Hai lớp riêng `FalagardComplexWindow` (hội thoại/nhiệm vụ) và `FalagardChatHistory` có scrollbar nhưng thiếu `onMouseWheel`; đã bổ sung cùng cơ chế, chỉ cuộn khi thanh hiện và nội dung dài hơn trang, tôn trọng sự kiện đã được subscriber xử lý.

## Kiểm chứng

Bộ kiểm opt-in `CYS_UI_WHEEL_LIVE` dùng các instance thật của giao diện đang nạp, cấp nội dung dài chỉ trong bộ nhớ client (không gửi chat, chọn đáp án hay ghi dữ liệu server). Sự kiện đi vào InputEventQueue và `CUISystem::InjectInput` thật; không gọi thẳng setter của thanh cuộn để giả lập thao tác cuộn. Setter chỉ đưa trạng thái ban đầu về đầu danh sách.

Sáu ca: QuestGreeting_Desc (menu NPC), QuestLog_Listbox, SelectFacestyle_StyleList (danh sách có icon con), AutoSearch_List, ActionSkill_Explain và Chat_Frame_History. Mỗi ca đo vị trí sau cuộn xuống/lên, biên đầu/cuối và kiểm tra camera không đổi. Cuối lượt mở Pet/ActionSkill để chụp các ô nền dùng chung, đóng bằng Esc, kiểm tra lăn chuột trên thế giới vẫn zoom camera, rồi nhân vật di chuyển. ActivitySchedule có layout trong kho nhưng không có trong danh mục cửa sổ đang dùng, nên ca NotSuperList chọn SelectFacestyle đã đăng ký thực tế.

Ứng viên: `Build/world-gui/stage-ui-wheel-23`. Công cụ `deploy_ui_wheel.py` có stage/check/publish, khóa bằng hash Game/manifest/binary, yêu cầu marker đủ sáu ca, không lỗi Lua, không thay Overlay/Patch, không có Game đang chạy khi cập nhật; sao lưu trước khi ghi bản Play.

Các lượt chuẩn bị được giữ riêng, không dùng để phát hành: `live-01` phát hiện bộ kiểm gọi Lua `this:Show()` trước khi layout được nạp (đã chuyển sang `ShowWindowByName`, có nạp layout); `live-02` bị từ chối đăng nhập flag 8 sau phiên ngắt; `live-03` xác nhận NPC và quest nhưng dừng ở cửa sổ không đăng ký; `live-04` xác nhận cuộn hai chiều danh sách icon nhưng giới hạn 100 nấc của bộ kiểm chưa tới đáy. Bộ kiểm cuối đi tới khi vị trí dừng thay đổi, có giới hạn chống lặp, rồi đối chiếu với document size trừ page size.

## Kết quả bản phát hành

`live-05` đạt **20/20 kiểm tra phiên chơi**, exit 0, không dump/lỗi Lua/handler/decode; marker `CYS-UI-WHEEL: RESULT menus=6 errors=0` lúc 10:27:09. Sáu khung đều cuộn xuống, lên, về đúng đầu và đáy; vị trí đáy đo được lần lượt 1.400, 504, 3.816, 740, 800 và 744 pixel. Mức zoom không đổi trong từng ca; sau khi đóng UI, cuộn trên thế giới đổi zoom, và bấm đất làm nhân vật di chuyển.

Đã xem ảnh thực trong `Build/Logs/2026-09-23-ui-wheel/live-05`: menu NPC, danh sách lựa chọn, mô tả kỹ năng dài, lịch sử chat, Pet và ActionSkill. Ảnh hai khung cuối xác nhận nền/viền ô chỉ số và ô trống được vẽ ngoài SelfEquip. Các hàng dài trong bộ kiểm là nội dung cục bộ để kiểm đường cuộn, không phải dữ liệu gameplay đầy đủ của từng cửa sổ. Khung Pet còn có chữ chồng/cắt ở bố cục hiện hữu; đợt này không tuyên bố đã sửa toàn bộ bố cục hoặc Việt hóa của Pet.

Đã phát hành lúc **10:28:37**, backup `Build/backups/ui-wheel-play/20260923-102837`. Game SHA-256: `e7705122c77398779fa7042163d1d5c2c4010a181fa41628627873a8648ec508`. Sáu file binary/PDB đi kèm được kiểm hash theo manifest; Overlay và Patch giống hệt bản Play trước đợt này. Launcher xóa cờ `CYS_UI_WHEEL_LIVE` trong phiên thường.

Lượt Play thường cuối `play-final-02` bằng test13 đạt **20/20**, kết thúc lúc **10:33:35**, exit 0, không bật probe, không lỗi Lua/handler/decode hoặc dump. Cảnh 420 có bốn đối tượng, ba lần bấm đất làm nhân vật di chuyển và phiên kết thúc bằng `quit_complete`. Game hash khớp chính xác bản đã kiểm tra chức năng; toàn bộ 37 mục binary trong manifest Play đều khớp. Lượt `play-final` trước đó bằng test15 đạt 19/20 vì vị trí sau nhiều lượt đi bộ nằm ngoài vùng có đối tượng (`objects=0 created=0` ở cảnh 2); tiêu chí được giữ nguyên và chạy lại ở khu vực có NPC, không bỏ hoặc làm yếu kiểm tra.
