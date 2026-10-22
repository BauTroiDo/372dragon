# Đối chiếu HJ 0.5 Hualuo Bug-fix log 3 với CY — 28/09/2026

**Có lỗi còn tồn tại, đồng thời nhiều mục thuộc tính năng chưa hoàn chỉnh. Không thể coi toàn bộ log HJ là danh sách bản vá có thể chép sang CY.**

File gốc có **143 mục**: số 1–140, thêm 27.5 và 94.5, hai mục cùng số 121. Báo cáo giữ thứ tự và gọi hai mục đó là **121a** (ràng buộc vật phẩm), **121b** (tư chất pet trong kho). SHA-256 file: `9674d792882e5e2f7062058ec50c53da21937e89ce29fa80e2d5336770e42a4a`.

Đích đối chiếu là CY-Source/Play21 và server riêng `/home/ubuntu/cys-test-20260913`, không phải server GL chính. Đợt này đọc mã/bảng/log, chạy kiểm tra cô lập và tạo báo cáo; không sửa gameplay, không cấp/xóa vật phẩm, không đổi tài khoản, không restart hay phát hành binary.

Game.exe hiện tại: `fae39743edb1c52e876a7ee2720e64d8325df70e93c7aa90221d178faa0d5745`. Sáu dịch vụ riêng hoạt động, không trùng PID; login/game 15733/15734 đang nghe. Trạng thái này không phải chứng minh mọi tính năng hoạt động.

## Những phát hiện cần xử lý

| Mục | Phát hiện | Bằng chứng và giới hạn |
|---|---|---|
| **87** | **Nộ Hỏa Liên Trảm đếm theo mục tiêu** | Hàm `on_damage_target` tăng đao mỗi callback; quái gọi callback cho từng mục tiêu trúng. Probe với skill 312 (Huyết Chiến Bát Phương), collection 117/ngưỡng 15: 10 mục tiêu làm đao **5 → 15**, mục tiêu cuối nhận rate 115. Dữ liệu thật có 23 impact dùng logic 101. Đây là tái hiện ở hàm thật với actor/tra cứu collection mô phỏng; chưa chạy AoE trực tiếp trong GUI. |
| **119** | **Particle còn thuộc tính không được nhận** | Log GUI đã có, đúng hash Game hiện tại: **9 dòng** `Bad particle affector attribute` với `MeshAnimationAffector`, `anim_pos1/2/3`. Không phải 3.000 dòng; chưa đo tác động lên hình ảnh/FPS. Đợt audit đọc lại log, không giả là một lượt GUI mới. |
| **112** | **Callback đổi tên có thể trừ thẻ khi báo thất bại** | Chạy hàm thật với kết quả lỗi 1, 2, 3, 4 đều xóa một thẻ trước khi xét kết quả. Đây là **lỗi tiềm ẩn**: caller `char_by_name` hiện chỉ gọi callback After với 0 và từ chối tên trùng trước đó. Chưa chứng minh một lần đổi tên thất bại từ UI đã mất thẻ. |
| Liên quan **25–26** | **Tư chất trang bị pet chưa góp chỉ số** | Cả `pet_attrib.lua` và `db/pet_attrib.lua` chỉ cộng base/raw attrs. Đổi sáu byte tư chất **0 → 255**, phần cộng base vẫn **100 → 100**. Loader giữ tư chất; đây là lỗi tính chỉ số, **khác** lỗi HJ mất dữ liệu/2% sau relog. |
| Phát hiện thêm khi kiểm **73** | **Thọ vật phẩm Thú hồn không được nạp lại** | `copy_raw_data` giữ thọ 420, nhưng `pet_equip_data:init_from_data` bỏ `pet_equip_unknow_8`, constructor đặt lại **300**. Luồng Hồi thọ sử dụng đúng trường này. Khác với tốc độ tụt thọ của pet phụ thể trong mục 73, mục gốc vẫn chưa kết luận. |

Nhật ký tái hiện: [targeted-probes.txt](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-audit/targeted-probes.txt>). Mã probe: [hj05_probes.lua](<C:/TLBB/085/CY-Source/Tools/audit/hj05_probes.lua>). Các probe cố ý ghi lại hành vi lỗi; việc chúng chạy thành công **không có nghĩa lỗi đã được sửa**.

## Các hệ còn thiếu cần tách khỏi lỗi HJ

- **Cửu Châu/trân thú trong shop:** server có `if 0 == 0 then return end` ở nhánh mua pet và rút pet. Client `CysPetNet` bỏ qua extra-view của exchange/stall/shop. Mục 10/123 chưa phải giao dịch hoàn chỉnh; không thể báo “đã đúng tiền/chỗ trống” khi đường giao dịch đang tắt.
- **Kho trân thú:** các host PetBank còn stub; chưa chứng nhận số lượng/tư chất kho (24/121b). Kiểm kê 76 Lua UI cho ra 254 ứng viên stub, chỉ là danh sách điều tra; không gọi chúng là 254 lỗi độc lập vì còn alias/đăng ký đè.
- **Thành bang/thương nhân/nghiên cứu/Trác Lộc:** đã có party/raid/liên minh và ngân phiếu, nhưng các API xây thành, nghiên cứu, shop/tuyến đường, tiến độ quest còn thiếu. Nhiệm vụ thiếu `CityIncProgress` hiện chặn trước tiêu phí. Chưa có nghiệm thu toàn chu kỳ chiến trường/công trạng.
- **Mạn Đà và thiên phú:** Mạn Đà slot 16 đang tắt. CY Tông môn và GL Võ đạo khác schema; còn thiếu UI/mapping cho cây đầy đủ. Không tự áp các ID/hệ số/40+talent mà tác giả HJ nói đã sửa.

## Các nhánh có xử lý đúng trong phạm vi đã thử

- Mua lại ở NPC giữ cùng instance/GUID, ràng buộc, cường hóa +9 và tư chất trong probe. Không mở rộng kết quả sang mọi thương hội/đấu giá (121a).
- Pet equipment lưu/nạp được sáu byte tư chất và hai thuộc tính 123/456 trong roundtrip thật; chưa thấy đúng lỗi hook mất dữ liệu của HJ (26/27).
- Trang bị nhân vật thường có tư chất vẫn được cộng khi cường hóa bằng 0: base 100 + tư chất 20 = 120 (98). Thất tinh phải kiểm riêng.
- Buff có mutex priority thấp không đè được priority cao trong hàm thay thế. Từng buff còn phụ thuộc dữ liệu bảng (65).
- Chọn ô nhẫn/hộ phù, tổng xuyên thích, ngoại hình Võ hồn đã có sửa và bằng chứng GUI/relogin từ các đợt trước. Bảng dưới ghi rõ phần nào chỉ là bằng chứng lịch sử.

## Phạm vi kiểm tra mới

| Bộ kiểm hiện tại | Kết quả | Phạm vi |
|---|---:|---|
| Pet | 113/113 | Handler/thuộc tính/linh tính với actor mô phỏng, không phải mọi kỹ năng pet live |
| PvP | 83/83 | Luật PvP, công thức và điều kiện arena đã định nghĩa |
| Equipcraft | 54/54 | Luồng Thăng Linh/điêu văn và ranh giới giao dịch |
| Equipment passives | 21/21 | Linh Vũ/Linh bài theo test hiện có |
| Gameplay audit | 978/978 | Handler thật và bảng thật; 494 công thức được khảo sát, 452 tạo được, 42 chặn vì thiếu cấp nghề |
| Quest rewards | 174/174 | Callback Đại Lý và thưởng, không phải toàn bộ 174 chuỗi |
| Lễ hộp | Đạt | Loại mẫu đang test, túi đầy/replay/race/khóa trạng thái |
| Trade/welfare | 37/37 | Ngân phiếu, phúc lợi và chặn nhiệm vụ thành thiếu progress |
| City query | 8/8 | Đọc level/thành đã lưu, không phải tạo thành live |
| Equipment routes | 6/6 | Whitelist + registry + thân hàm |
| Probe HJ chuyên biệt | 9 quan sát | Bao gồm tái hiện lỗi, không tính là 9 chức năng đúng |

Chín bộ kiểm hồi quy dùng file máy chủ hiện tại, mô phỏng transport/actor/database theo từng bộ. Không sửa fixture Mongo. Chưa chạy soak test THDC4 một giờ; chưa chơi hết Q70, Sát Tinh, Thanh Khâu, Tào Vận; chưa có ma trận chiến đấu mọi phái/talent. Nhiều mục không có item/skill/scene ID nên chưa thể khẳng định trùng lỗi.

## Phân loại 143 mục

Đây là số **mục trong file**, không phải số lỗi độc lập. “Có xử lý” chỉ xác nhận phần được mô tả trong cột nhận định; “cần kiểm riêng” không phải PASS. “Thiếu” cũng không phải khẳng định lỗi gốc HJ đã tái hiện.

| Trạng thái | Số mục |
|---|---:|
| Lỗi đã có bằng chứng | 2 |
| Lỗi liên quan, khác mô tả gốc | 1 |
| Lỗi tiềm ẩn trong mã | 1 |
| Chức năng thiếu/chưa hoàn chỉnh | 28 |
| Có xử lý/kiểm tra đạt trong phạm vi | 21 |
| Cần kiểm riêng, chưa kết luận | 72 |
| Khác nhánh/thiết kế/bổ sung nội dung | 18 |

## Bảng đối chiếu đầy đủ

| Mục | Nội dung gốc | Trạng thái | Nhận định CY và nguồn |
|---|---|---|---|
| 1 | Fix bug nâng cấp võ hồn không hiển thị nguyên liệu nâng cấp (lua) | Có xử lý/kiểm tra đạt trong phạm vi | Khung Võ hồn dùng host/nguyên liệu thật; đợt power đã thử hợp thành. Chưa thử lại mọi nguyên liệu của mọi nhánh nâng cấp. [WUHUN](#wuhun) |
| 2 | Fix bug item thất tinh đao khi post lên kênh thế giới không hiển thị đầy đủ (lua) | Cần kiểm riêng, chưa kết luận | Tooltip trong túi đã nối metadata; link chat là đường riêng, chưa có ca post đúng Thất tinh đao rồi mở bằng nhân vật thứ hai. [CHAT](#chat) |
| 3 | Fix item thất tinh đao có thể cường hóa hiển thị cường hóa xuyên thích đồng thời chặn việc cường hóa item có eqiup point là 8 9 10 (gs) | Khác nhánh/thiết kế/bổ sung nội dung | CY có lò rèn nhịp Space tối đa +9 và whitelist trang bị riêng; không được chép điều kiện equip point 8/9/10 của HJ vào CY vì ID có thể khác nghĩa. [EQUIP](#equip) |
| 4 | Fix hiệu ứng của item thất tinh đao có vấn đề thiếu material (effect) | Cần kiểm riêng, chưa kết luận | Chưa có mã item/model/effect cụ thể của Thất tinh đao trong log để xác nhận dependency đang dùng. [ASSET](#asset) |
| 5 | Fix bug linh vũ buff id = 0 dẫn đến khi đeo đủ 6 món chuyển map bị trừ máu (lua) | Cần kiểm riêng, chưa kết luận | Có lingwu_equip_effect_flush và bảng bộ; chưa thử mặc đúng sáu món, giữ HP trước/sau chuyển map. Không lấy kiểm tra Linh Vũ mới làm bằng chứng bộ sáu món HJ. [EQUIP](#equip) |
| 6 | Fix bug chuyển thú hồn lên ngựa không hiện ngựa (GS) | Cần kiểm riêng, chưa kết luận | Thú hồn, thú cưỡi và dung hồn dùng các đường riêng; chưa tái hiện đúng tổ hợp chuyển hồn lên ngựa. [PET](#pet) |
| 7 | Fix bug thú hồn không cộng điểm khi pet xuất chiến (hook) | Có xử lý/kiểm tra đạt trong phạm vi | Pet calculator có cộng phần trăm tư chất và thuộc tính mở rộng Thú hồn khi xuất chiến. Bộ pet 113 ca qua, nhưng chưa đo mọi mẫu hồn trong thế giới. [PET](#pet) |
| 8 | Fix bug tàn hình thiên sơn (tạm fix bằng txt thực tế bug này ở bản này có thể fix bằng txt nhưng ở 0.6 thì không thể vì 0.6 bug này nghiêm trọng hơn đã tạm thời tìm được hàm fix là CGCharUseSkillHandler::Execute nhưng chưa có thời gian thực hiện) | Cần kiểm riêng, chưa kết luận | Không dùng CGCharUseSkillHandler của GS HJ; vẫn phải thử ẩn/hiện Thiên Sơn và tương tác party, map, mục tiêu. Không coi khác engine là miễn lỗi. [COMBAT](#combat) |
| 9 | Fix giới hạn giá cửu châu thương hội từ 1000 thành 9999 (GS) | Cần kiểm riêng, chưa kết luận | Đây là thay giới hạn kinh tế 1000 thành 9999; chưa có yêu cầu đổi mức giá của CY và chưa thử biên giá ở UI thương hội. [SHOP](#shop) |
| 10 | Fix bug pet cho vào cửu châu hội lấy ra bị báo đầy (GS) | Chức năng thiếu/chưa hoàn chỉnh | Nhánh rút pet từ player shop bị return vô điều kiện trong scenecore; client cũng bỏ dữ liệu pet shop. Chưa phải luồng hoạt động để nghiệm thu lỗi báo đầy. [SHOP](#shop) |
| 11 | Fix bug item nhẫn và hộ phù không cố định với đeo trùng lâu không có hiệu ứng ( chặn việc trực tiếp ấn đeo nếu ô đầu có trang bị phải kéo vào mới có thể đeo) (GS + Lua) | Có xử lý/kiểm tra đạt trong phạm vi | CY đã sửa chọn ô trống nhẫn/hộ phù và đổi đúng instance/GUID; có GUI/relogin lịch sử. Không áp workaround HJ bắt kéo bằng tay. Hiệu ứng Trùng Lâu cụ thể còn cần ca riêng. [SMART](#smart) |
| 12 | Fix skill ác nhân cốc cho chuẩn (Có 5-6 skill hoạt động không đúng) (GS + hook) | Cần kiểm riêng, chưa kết luận | Log không nêu 5–6 skill Ác Nhân nào. CY đã có đối chiếu kỹ năng cơ bản nhưng không đủ để xác nhận mọi hành vi cùng bản HJ. [COMBAT](#combat) |
| 13 | Fix bug phái mạn đà sử dụng kỹ năng không tiêu hao mạn đà hoa (hook) | Chức năng thiếu/chưa hoàn chỉnh | Mạn Đà được đánh dấu tắt ở slot 16 của CY. Condition cũ có mã tiêu hoa không chứng minh phái đã được mở và nối đúng dữ liệu CY. [MANTUO](#mantuo) |
| 14 | Fix logic lua việc xóa item pet quý trọng có vấn đề dẫn đến không thể xóa (Lua) | Cần kiểm riêng, chưa kết luận | Đã có guard khóa/trao đổi/quyền sở hữu và tách hồn trước xóa pet; chưa tái hiện script xóa vật phẩm pet quý hiếm mà file nhắc. [PET](#pet) |
| 15 | Fix bug thiếu mesh vũ khí ác nhân cốc (client) | Cần kiểm riêng, chưa kết luận | Đã nhập nhiều vũ khí HJ và kiểm dependency, nhưng log không chỉ item/mesh vũ khí Ác Nhân bị thiếu. [ASSET](#asset) |
| 16 | Fix tên item linh võ hiển thị sai (lua + txt) | Cần kiểm riêng, chưa kết luận | Có mapping tên/item riêng CY; cần mã Linh Vũ cụ thể và tên kỳ vọng để khẳng định sai tên. [EQUIP](#equip) |
| 17 | Fix post item linh võ hiển thị sai. (lua) | Cần kiểm riêng, chưa kết luận | Link vật phẩm Linh Vũ chưa có kiểm hai người; kiểm SuperTooltip trong túi không bao phủ link chat. [CHAT](#chat) |
| 18 | Fix bug không hiển thị xuyên thích item liềm của act nan cốc. (lua) | Cần kiểm riêng, chưa kết luận | Tổng xuyên thích đã nối; tooltip instance có metadata. Chưa thử đúng item liềm Ác Nhân của log. [SMART](#smart) |
| 19 | add các loại phụ thể | Khác nhánh/thiết kế/bổ sung nội dung | Là bổ sung các loại phụ thể, không mô tả lỗi hay danh mục cần có. Không coi việc chưa nhập tất cả loại HJ là cùng lỗi. [PET](#pet) |
| 20 | Fix linh vũ item đeo vào chuyển map trở lại op như cũ .(lua) | Cần kiểm riêng, chưa kết luận | Linh Vũ có đường cộng chỉ số riêng; cần snapshot đúng bộ trước/sau map/relogin để loại trừ reset op. [EQUIP](#equip) |
| 21 | Fix item nhận thất tinh kiếm không nhận được Ly ưu thương.(lua) | Cần kiểm riêng, chưa kết luận | Có skill trang bị/Thất tinh trong server nhưng cần đúng item kiếm và ID Ly ưu thương; chưa xác nhận đường nhận item tự cấp chiêu. [EQUIP](#equip) |
| 22 | Fix lại thông tin hiển thị tỷ lệ thăng cấp thành công của võ hồn huyễn hóa (trước đó không hiển thị).(lua) | Khác nhánh/thiết kế/bổ sung nội dung | Huyễn hồn CY hiện hiển thị cấp, tiến độ /10, phí và đột phá bằng luồng riêng; không dùng nguyên UI xác suất nâng cấp HJ được mô tả. [WUHUN](#wuhun) |
| 23 | Fix bug cho pet vào kho thoát ra vào lại mất linh tính + không thể tăng linh tính thành công.(hex) | Cần kiểm riêng, chưa kết luận | Linh tính có trường lưu DB và bộ tính theo bảng CY. Chưa có vòng gửi kho → thoát → lấy ra → nâng linh tính; không suy từ pet trong túi. [PET](#pet) |
| 24 | Fix hiển thị số lượng pet trong kho có thể mang không đúng. (lua) | Chức năng thiếu/chưa hoàn chỉnh | Giao diện/host PetBank còn khoảng trống, chưa có handler riêng đầy đủ cho dữ liệu kho. Không chứng nhận số lượng pet trong kho đúng. [PETVIEW](#petview) |
| 25 | Viết lại hook các hàm cộng điểm pet giải quyết vấn đề thuộc tính pet không cộng thêm của thú hồn và trang bị pet. (hook) | Lỗi liên quan, khác mô tả gốc | Đã cộng base/thuộc tính Thú hồn, nhưng thử thật hàm cộng chỉ số phát hiện qualifications trang bị pet không được dùng ở cả hai calculator. Đây là thiếu hệ số, khác lỗi hook cộng điểm của HJ. [PETQUALITY](#petquality) |
| 26 | Fix bug tư chất trang bị pet thoát ra vào lại bị mất hoặc bị cố định thành 2% (haha cuối cùng cũng Fix được bug này = )) ). | Có xử lý/kiểm tra đạt trong phạm vi | Loader thật giữ đủ sáu byte qualifications; không tái hiện mất/cố định 2% trong roundtrip cô lập. Tuy vậy hệ số tư chất đang bị bỏ qua khi cộng chỉ số (phát hiện riêng). [PETQUALITY](#petquality) |
| 27 | Fix bug trang bị pet pos 20 trở lên thoát ra vào lại mất thuộc tính 2 dòng đầu thành + 0 （ do thằng 花落 hook hơi ngáo). | Có xử lý/kiểm tra đạt trong phạm vi | Loader thật giữ hai dòng attr_values và attr_types đã thử 123/456. Không dùng hook pos20 của HJ; chưa thử mọi loại vật phẩm pet/slot trong GUI. [PETQUALITY](#petquality) |
| 27.5 | đổi sang bản việt hóa & copy file Fix bug đã Fix ở bản cn | Khác nhánh/thiết kế/bổ sung nội dung | Ghi chú chuyển nhánh Việt hóa/copy bản vá, không phải lỗi game. Không làm theo như chỉ thị triển khai. [SCOPE](#scope) |
| 28 | Kéo ui võ hồn bao gồm Fix khung hiển thị nguyên liệu tăng cấp nhuận hồn thạch + nhiều ui khác.(xml) | Có xử lý/kiểm tra đạt trong phạm vi | UI Võ hồn và nguyên liệu đã có sửa nguồn sinh. Không thể nghiệm thu “nhiều UI khác” vì file không liệt kê chúng. [WUHUN](#wuhun) |
| 29 | Việt hóa lại 10 file text client cho chuẩn đồng thời tối ưu lại text. | Cần kiểm riêng, chưa kết luận | Không có danh sách 10 file text, hash hay các dòng dịch sai; chưa thể đối chiếu từng lỗi Việt hóa. [TEXT](#text) |
| 30 | Fix ui không hiển thị nguyên liệu hợp thành ở bành hoài ngọc. (lua) | Có xử lý/kiểm tra đạt trong phạm vi | Khung chế tạo đã nối host nguyên liệu/icon, số lượng và ô thứ năm; thử 54 equipcraft + 978 gameplay ca đạt. Chưa bấm đúng NPC Bành Hoài Ngọc trong lượt này. [QUEST](#quest) |
| 31 | Fix lại text thiên long kỷ niệm thẻ + Fix bug hiển thị không hiển thị thuộc tính cộng thêm gây khó khăn cho việc nâng cấp. (lua) | Cần kiểm riêng, chưa kết luận | Thẻ kỷ niệm là hệ riêng; chưa xác nhận đầy đủ text và cộng thêm thuộc tính trong UI card hiện hành. [CARD](#card) |
| 32 | Fix sang trang thứ 2 không đổi tên tên thẻ vẫn là trang 1. (lua) | Cần kiểm riêng, chưa kết luận | Chưa tái hiện chuyển trang thứ hai bằng đúng thẻ; kiểm tooltip trang bị không bao phủ trạng thái tên card. [CARD](#card) |
| 33 | Fix làm Q tân thủ không thể làm đến lv 10 bắt đầu lỗi từ đoàn diên khánh do việt hóa | Có xử lý/kiểm tra đạt trong phạm vi | Đã sửa callback Đại Lý/nhận trả thưởng và 174 ca callback hiện tại đạt; chưa chơi toàn chuỗi tới cấp 10 với mọi NPC mà HJ nêu. [QUEST](#quest) |
| 34 | vh platform và edit lại text vh cũ của skill ác nhân và mạn đà cho chuẩn. | Cần kiểm riêng, chưa kết luận | Không có bản text chuẩn/danh sách dòng platform và kỹ năng để so. Mạn Đà hiện chưa mở. [TEXT](#text) |
| 35 | Fix bug hiển thị sai icon và text skill khi nâng cấp skill của vũ khí thất tinh cũng như khi chọn skill 1&2 gây ra hiểu nhầm. (lua) | Cần kiểm riêng, chưa kết luận | Có luồng equipment skills, nhưng chưa đối chiếu từng icon/tên của hai chiêu Thất tinh trên UI nâng cấp. [EQUIP](#equip) |
| 36 | bug hơi ảo hiển tại tìm ra cách giải quyết nhưng không biết vì sao phát sinh (nhân vật tự nhiên không thể di chuyển sau khi đánh mục tieu hoặc đeo trang bị). | Có xử lý/kiểm tra đạt trong phạm vi | Đã sửa khóa động tác/đích chết; GUI cùng Game hiện tại có di chuyển sau thao tác. Lỗi ngẫu nhiên dài phiên chưa được tái hiện bằng mô tả này. [MOVE](#move) |
| 37 | Fix bug item không phải thất tinh khi cho vào nâng cấp chức năng liên quan bị khóa đỏ. (lua) | Có xử lý/kiểm tra đạt trong phạm vi | Khung chế tác CY mới từ chối loại/slot không phù hợp; 54 ca equipcraft đạt. Chưa thử mọi cửa sổ Thất tinh cũ còn tồn tại. [EQUIP](#equip) |
| 38 | Fix post item dis client. (không phải bản thân Fix là Cao thủ Fix đại lão ném thẳng file vào mõm luôn kk đa tạ cao thủ) | Cần kiểm riêng, chưa kết luận | Chưa chạy post item nhiều loại và mở link hai người; không thể xác nhận hết lỗi disconnect chỉ bằng kiểm codec túi. [CHAT](#chat) |
| 39 | Fix bug việt hóa tên pet chép lên sv không thể chạy sv (hex) | Có xử lý/kiểm tra đạt trong phạm vi | Server riêng đang chạy/nạp scene với dữ liệu hiện tại; không dùng hex loader HJ. Chưa thử mọi tên Việt hóa mới có thể thêm sau này. [RUNTIME](#runtime) |
| 40 | Fix bug vào map bang bị đen map do việt hóa (txt) | Cần kiểm riêng, chưa kết luận | Map thành bang cần thành thật và thử render/entrance. Dữ liệu map có không đồng nghĩa map thành đã vào được và không đen. [CITY](#city) |
| 41 | Fix tam thời mặc định bang sau bảo trì là cấp độ 5 thay vì là cấp 0 (hex) | Khác nhánh/thiết kế/bổ sung nội dung | Không dùng workaround ép bang cấp 5. CY đọc thành/cấp từ dữ liệu; mục 108 trong chính file cũng hủy workaround này. [CITY](#city) |
| 42 | Thay world không mã hóa | Khác nhánh/thiết kế/bổ sung nội dung | Thay World binary không mã hóa là thao tác riêng nhánh HJ; server CY hiện dùng Skynet/Lua. Không chép binary trong log. [BUILD](#build) |
| 43 | Fix bug không thể từ npc bên ngoài tiến vào trong thành bang (lua) | Chức năng thiếu/chưa hoàn chỉnh | Luồng thành bang chưa hoàn chỉnh, các API tạo/quản lý/cổng còn thiếu; chưa có nghiệm thu NPC ngoài thành → nội thành. [CITY](#city) |
| 44 | Fix bug shop thương nhân không hiển thị (Fix tạm thời bằng lua có thể chạy như bình thường) (lua) | Chức năng thiếu/chưa hoàn chỉnh | AskCityShop/DoCityShop và luồng thương nhân thành chưa nối đủ; kiểm ngân phiếu nhận/trả không chứng minh shop chạy thương mở được. [CITY](#city) |
| 45 | Thêm script tuyến đường thông thương với bang khác tránh việc không thông thương vẫn có thể bán đồ (lua) | Chức năng thiếu/chưa hoàn chỉnh | AskCityRoad/DoCityRoad còn stub, chưa hoàn thành tuyến thông thương và quyền bán theo tuyến. [CITY](#city) |
| 46 | Fix bug có buff thương nhân vẫn có thể lên ngựa (lua) | Cần kiểm riêng, chưa kết luận | Chưa thử buff thương nhân rồi lên/xuống thú. Bộ test ngân phiếu không kiểm khóa mount theo buff. [CITY](#city) |
| 47 | Viết hook Fix bug tiêu dao thiên long thiên sơn đánh quái không tăng nộ khí (hook) | Cần kiểm riêng, chưa kết luận | Cần kiểm tăng nộ theo từng chiêu/đòn trúng của Tiêu Dao, Thiên Long, Thiên Sơn. Không suy từ việc đánh có sát thương. [COMBAT](#combat) |
| 48 | Việt hóa chữ trên buff (bug này không phải bản thân Fix là Cao thủ Fix chỉ việc ăn sẵn kk) | Cần kiểm riêng, chưa kết luận | Thiếu ID buff và chuỗi sai/đúng; bản dịch buff cần so từng dòng. [TEXT](#text) |
| 49 | Fix bug nhuộm màu thời trang bị dừng mặc dù chưa ra thời trang đã chọn do việt hóa (txt) | Cần kiểm riêng, chưa kết luận | CY wardrobe chọn màu theo catalog, đã có kiểm sở hữu/đổi màu. Chưa thử đúng chức năng nhuộm ngẫu nhiên/NPC HJ bị dừng sớm. [ASSET](#asset) |
| 50 | ấn nâng cấp sẽ vào giao diện chọn huyễn sức để xem kết quả đồng thời chuyển sang tab này sẽ làm làm mới thông tin nâng cấp để Fix bug không hiển thị cấp khi nâng cấp gây khó khăn cho việc nâng cấp (lua&txt) | Cần kiểm riêng, chưa kết luận | Mô tả thiếu hệ/item/tab cụ thể; preview ngoại trang có cập nhật cấp nhưng chưa tái hiện thao tác nêu trong log. [ASSET](#asset) |
| 51 | Thêm tính năng chuyển ngọc thời trang tại npc y thiên thải (lua) | Khác nhánh/thiết kế/bổ sung nội dung | Bổ sung chuyển ngọc thời trang ở NPC Y Thiên Thải là tính năng; chưa chứng nhận tính năng này ở CY. [EQUIP](#equip) |
| 52 | Fix bug chức năng thẻ kỷ niệm không có buff tăng nộ khí (lua) | Cần kiểm riêng, chưa kết luận | Chưa kiểm rage buff của thẻ kỷ niệm; không gộp với tăng nộ từ môn phái. [CARD](#card) |
| 53 | Fix bug trang bị pet đeo đủ 5 món 1 set sẽ có buff tăng khả năng phóng thích skill nhưng khi chuyển map bị mất buff (hook) | Cần kiểm riêng, chưa kết luận | Có item_std_impact_effect khi item_flush pet; chưa kiểm chính bộ năm món có buff sau chuyển scene và triệu hồi lại. [PET](#pet) |
| 54 | Mở giới hạn đổi tên pet & tạo nhân vật thành 19 ký tự (lua) | Khác nhánh/thiết kế/bổ sung nội dung | Giới hạn 19 ký tự là thay đổi thiết kế. Cần xét byte UTF-8/độ rộng packet; không áp con số HJ tự động. [TEXT](#text) |
| 55 | Fix bug hiển thị số bạc cần để rs tư chất trang bị pet(lua) | Cần kiểm riêng, chưa kết luận | Chưa thử giá UI tẩy tư chất trang bị pet đối chiếu phí thật. Không nhầm với phí tẩy Thú hồn đã nối. [PET](#pet) |
| 56 | Fix bug skill phóng thích tiến cấp của pet trị số thực tế không đúng (ví dụ siêu cấp thống kích trị số chính xác + không đúng các loại chú cũng bug tương tự) (txt) | Cần kiểm riêng, chưa kết luận | Cần đúng skill ID/cấp và số kỳ vọng của các chiêu pet; bộ kiểm học skill chưa đo toàn bộ sát thương phóng thích. [PET](#pet) |
| 57 | Fix bug nhiệm vụ kịch tình đã có thể làm full đến hết Q70 hư trúc (kiều phong là hộ tống) (lua&txt) | Cần kiểm riêng, chưa kết luận | Các callback Đại Lý được kiểm, nhưng chưa chơi hết kịch tình tới Q70 Hư Trúc/hộ tống Kiều Phong. [QUEST](#quest) |
| 58 | fix bug hiển thị môn phái xem trước nhân vật nam khi tạo nhân vật bị lỗi hiển thị lệch (chỉ xuất hiện ở bản 32bit 11 phái mình đang dev này bản gốc 9 phái không bị) (txt) | Khác nhánh/thiết kế/bổ sung nội dung | File giới hạn lỗi ở client HJ 32-bit 11 phái; CY hiện x64 dùng profile riêng. Không coi lỗi nhánh đó là lỗi đã xác nhận ở CY. [ASSET](#asset) |
| 59 | fix vài bug do việt hóa phát sinh tiêu biểu là bug khi vào phái ác nhân gặp quái đều là npc không thể công kích (txt) | Cần kiểm riêng, chưa kết luận | Ác Nhân CY có mapping phái/camp riêng và từng chạy skill; chưa tái hiện tình huống mọi quái thành NPC sau nhập phái. [COMBAT](#combat) |
| 60 | fix bug 1 vài Q hiện thị có thể nhận nhưng đến npc lại không có ví dụ Q đôn hoàng ( chôn vùi npc tào diên huệ) vẫn còn những Q khác bị nhưng đã tìm được cách fix làm đến chỗ nào fix chỗ đó mình xem qua vài sv online gs này cũng không có Q này (lua) | Cần kiểm riêng, chưa kết luận | Đã sửa điều kiện/registry chung, nhưng chưa thử riêng nhiệm vụ Đôn Hoàng Tào Diên Huệ và các quest không được liệt kê. [QUEST](#quest) |
| 61 | fix bug mở âm kim bảo sương không có item (lua) | Cần kiểm riêng, chưa kết luận | Giao dịch lễ hộp hiện qua kiểm thiếu chỗ/replay/race. Cần ánh xạ đúng item Âm Kim Bảo Sương, không dùng một hộp khác làm bằng chứng. [GIFT](#gift) |
| 62 | bỏ hook hàm LuaFnUpdatePetSoulExValue của hualuo để khi tẩy thuộc tính thú hồn của pet khi khóa nếu ra trùng dòng vẫn sẽ nhận dòng trùng nhau đó giống Tình kiếm thực tế trùng là không chuẩn CY, CY không cho phép trùng nhau vì sau này sẽ có tính năng ngọc pet nếu pet cộng đến 1k2 thuộc tính như vậy sẽ rất mất cân bằng (ví dụ khóa tẩy Cường lực ra dòng cường lực khi ấn đổi vẫn sẽ nhận thêm dòng cường lực má cái thằng này nó làm cái trò gì mà fix hàm này cũng không tử tế thà dùng cái gốc còn hơn ) | Chức năng thiếu/chưa hoàn chỉnh | Tẩy/nhận thuộc tính cơ bản có, khóa dòng/khóa màu chưa hoàn chỉnh. Log còn tự thừa nhận cho dòng trùng khác CY chuẩn; không sao chép luật này. [PET](#pet) |
| 63 | fix bug không nhuộm được màu thời trang ở cột 29 30 thiếu 1 màu (hex) | Cần kiểm riêng, chưa kết luận | Catalog nhập HJ đã giữ 711 biến thể màu, nhưng chưa kiểm đúng dye columns29/30 của tính năng nhuộm cũ. [ASSET](#asset) |
| 64 | add trang bị full môn phái ác nhân cốc đồng thời edit lua npc lương sư thành tô châu cho phép đổi ngự tứ và full môn phái (lua) | Khác nhánh/thiết kế/bổ sung nội dung | Bổ sung full bộ phái và NPC đổi Ngự Tứ là thêm nội dung. Cần danh sách item/script để đối chiếu, không suy từ nhập ngoại hình. [ASSET](#asset) |
| 65 | fix bug buff cấp thấp có thể đè cấp cao điều này là vô lý (hex) | Có xử lý/kiểm tra đạt trong phạm vi | Hàm thật can_impactA_replace_impactB chặn ưu tiên thấp đè cao; probe đã đạt. Cấp buff cụ thể còn phụ thuộc mutex_priority trong bảng. [BUFF](#buff) |
| 66 | fix bug dump sv khi tăng cấp trong cấp từ cấp 10- cấp 15 dump phát sinh do việt hóa (lua) | Có xử lý/kiểm tra đạt trong phạm vi | CY có đường cấp tối đa200 và kiểm biên cấp; chưa tái hiện crash khi 10–15 trong server hiện tại. Không dùng patch hex Việt hóa HJ. [MOVE](#move) |
| 67 | Vh tên game trong task manager (overthinking đã là bản việt hóa thì mình muốn hạn chế việc xuất hiện tiếng trung nhất có thể=)) | Khác nhánh/thiết kế/bổ sung nội dung | Đổi tên hiển thị process là yêu cầu mỹ thuật/nhận diện, không phải lỗi gameplay. [TEXT](#text) |
| 68 | fix lại dung lượng client đồng bộ lại đám mesh với dds bị trùng quá nhiều dẫn đến log client hiện thị đến tận fairy_11 sau tinh giảm chỉ còn fairy_1 (client) | Cần kiểm riêng, chưa kết luận | Importer HJ cô lập dependency và có census, nhưng chưa kiểm toàn bộ pack trùng hoặc file log Fairy1…11. Số file log không tự chứng minh trùng mesh. [ASSET](#asset) |
| 69 | fix bug không thể nhận thưởng sau khi đi phó bản sát tinh 30 điểm hoạt động. (txt) | Cần kiểm riêng, chưa kết luận | Chưa chạy Sát Tinh đủ30 hoạt động rồi lĩnh thưởng; callback nhiệm vụ chung không bao phủ điều kiện sự kiện này. [QUEST](#quest) |
| 70 | fix bug pet bất tử khi đeo thú hồn chu tước trong trạng thái đang công kích sẽ bất tử ( thêm cơ chế escaped = 0 và 1 sau 200s chuyển từ 1 về 0 để hồi lại bất tử) (hook) | Cần kiểm riêng, chưa kết luận | Chưa thử đúng Thú hồn Chu Tước, miễn tử, công kích và hồi200giây; không kết luận từ mã pet tổng quát. [PET](#pet) |
| 71 | fix bug pet nhận buff từ nhân vật không tăng chỉ số tương ứng ví dụ nhận buff thể lực không tăng máu nhận buff cường lực không tăng công(hook) | Có xử lý/kiểm tra đạt trong phạm vi | Công thức pet lấy STR/CON đã refix để tính công/HP, có lan cờ dirty; chưa đo tất cả buff người → pet trong thế giới. [PET](#pet) |
| 72 | fix bug ẩn hình ts chính thức (hook) | Cần kiểm riêng, chưa kết luận | Cùng nhóm mục8; cần ca ẩn/hiện Thiên Sơn thật. Không có patch hook HJ để xác minh một bản vá cụ thể. [COMBAT](#combat) |
| 73 | fix bug thú khi phụ thể tho mệnh tụt quá nhanh | Cần kiểm riêng, chưa kết luận | Chưa đo tốc độ tụt thọ pet phụ thể. Phát hiện riêng: thọ của vật phẩm Thú hồn được lưu420 nhưng loader về300; đây là trường khác, không gán là đã tái hiện đúng mục73. [PETLIFE](#petlife) |
| 74 | fix bug ts tàn hình trong đội khi bỏ ẩn hình mất hình hoặc thập diện mai phục trong tổ đội chuyển map mất hình cả 2 | Cần kiểm riêng, chưa kết luận | Cần hai người, Thập Diện Mai Phục và map transfer. Các test party/chuyển map hiện có chưa bao phủ visibility của combo này. [COMBAT](#combat) |
| 75 | fix bug mất effbuff khi đổi thú hồn (trùng lâu hoặc lưu tinh cản nguyệt khi đổi thú hồn sẽ bị mất hiệu ứng ở nhân vật) | Cần kiểm riêng, chưa kết luận | Chưa kiểm đồng thời Trùng Lâu/Lưu Tinh Cản Nguyệt và đổi Thú hồn; không suy từ việc model Võ hồn hiển thị được. [PET](#pet) |
| 76 | fix bug võ hồn hợp thành 5 ngoại quan không thay đổi | Có xử lý/kiểm tra đạt trong phạm vi | cys_wuhun_appearance chọn visual theo cấp hợp thành, đã sửa KFSObj/world/SelfEquip/chọn nhân vật và có kiểm lịch sử. Không còn dùng một visual cố định cho mọi cấp. [WUHUN](#wuhun) |
| 77 | fix chuẩn võ đạo thiên sơn nặc ảnh tuyệt sát đúng miêu tả thay vì có tác dụng cả với quái vật gây ra lượng dame khủng bố. | Chức năng thiếu/chưa hoàn chỉnh | Chưa hoàn thiện UI/mapping thiên phú theo CY; không chứng nhận Nặc Ảnh Tuyệt Sát chuẩn hay đã chặn quái. Cần kiểm runtime riêng khi cây đúng được mở. [TALENT](#talent) |
| 78 | fix võ đạo minh giáo 4-5 võ đạo hoạt động sai cách | Cần kiểm riêng, chưa kết luận | Log không nêu tên/ID 4–5 thiên phú Minh Giáo; không thể nghiệm thu theo một nhận xét chung. [TALENT](#talent) |
| 79 | fix bug rồng cái bang bị đơ khi ra chiêu | Cần kiểm riêng, chưa kết luận | Chưa thử đúng động tác/effect rồng Cái Bang; census ngoại trang không đo chiêu này. [ASSET](#asset) |
| 80 | fix bug hoành tảo thiên hạ có thể lên ngựa | Cần kiểm riêng, chưa kết luận | Chưa thử Hoành Tảo Thiên Hạ trong lúc chuyển trạng thái cưỡi; chưa xác nhận đủ điều kiện chặn mount. [COMBAT](#combat) |
| 81 | fix bug YQ80 Tinh túc khi quái chết không kích hoạt làm choáng 6 mục tiêu | Cần kiểm riêng, chưa kết luận | Chưa thử YQ80 Tinh Túc, mục tiêu chết và đủ sáu mục tiêu lân cận; chưa có mô tả ID để xác nhận. [TALENT](#talent) |
| 82 | fix bug võ đạo Tinh túc bị động không tang dame khi đứng im 10s | Cần kiểm riêng, chưa kết luận | Chưa đo đứng yên10giây rồi tăng sát thương Tinh Túc; cần thiên phú cụ thể/level/công thức gốc. [TALENT](#talent) |
| 83 | fix bug võ đạo cái bang phi long tại thiên thời gian hồi cho các skill khác bị bug | Cần kiểm riêng, chưa kết luận | Chưa kiểm cooldown các chiêu khác sau Phi Long Tại Thiên theo cây thiên phú đang dùng. [TALENT](#talent) |
| 84 | fix võ đạo thiếu lâm bị đông không nổ 2% máu tối đa | Cần kiểm riêng, chưa kết luận | Chưa đo proc2%HPmax của đúng thiên phú Thiếu Lâm; không thay bằng kiểm sát thương cơ bản. [TALENT](#talent) |
| 85 | fix bug võ đạo thiên long ( yết thiên ứng hành) bị động chỉ xuất hiện băng thuộc tính | Cần kiểm riêng, chưa kết luận | Chưa kiểm Yết Thiên Ứng Hành đủ bốn kênh; hệ số băng/hỏa/huyền/độc chung đạt không chứng minh talent này đúng. [TALENT](#talent) |
| 86 | fix bug impact buff không có giảm kháng hỏa đến âm và độc đến âm | Có xử lý/kiểm tra đạt trong phạm vi | Công thức bốn kênh hiện có giới hạn kháng âm và đã sửa cộng nhầm kháng/giảm sát thương. 978 ca gameplay gồm ma trận công thức đạt; chưa kiểm mọi buff riêng. [ELEMENT](#element) |
| 87 | fix bug nộ hỏa liên trảm dùng skill aoe tiêu hao trảm theo số mục tiêu bên cạnh 1 huyết trận nếu có 10 mục tiêu sẽ có mục tiêu bị tính dame trảm thứ 10 =)) | Lỗi đã có bằng chứng | Tái hiện hàm thật: mười callback trúng mục tiêu cùng skill 312 làm bộ đếm đao 5→15; mục tiêu thứ 10 đã nhận rate 115. Dùng ngưỡng 15/collection 117 của bảng thật; logic 101 có 23 dòng impact. Chưa thử AoE này trong GUI. [AOE](#aoe) |
| 88 | fix bug võ đạo cái bang hoành tảo thiên hạ không tang dame như mô tả | Cần kiểm riêng, chưa kết luận | Chưa đo damage Hoành Tảo theo từng cấp thiên phú/mô tả; không chứng nhận cân bằng toàn bộ Cái Bang. [TALENT](#talent) |
| 89 | fix toàn bộ võ đạo tiêu dao đặt bẫy có vấn đề | Cần kiểm riêng, chưa kết luận | Mô tả “toàn bộ võ đạo đặt bẫy” thiếu danh sách; cần kiểm từng trap/talent, không suy từ việc map bẫy có dữ liệu. [TALENT](#talent) |
| 90 | fix bug mạn đà skill 2 skill hồi máu phải chọn mục tiêu mới có thể dùng và bị trừ mạn đà hoa ( fix cho chuẩn Cy không cần chọn mục tiêu) & bug mục tiêu D:1 skill không bị tiêu hao mạn đà hoa | Chức năng thiếu/chưa hoàn chỉnh | Mạn Đà chưa mở trong CY hiện tại; không có nghiệm thu hai chiêu hồi máu/tự chọn mục tiêu/tiêu hoa. [MANTUO](#mantuo) |
| 91 | fix bug phong nhập tùng không xóa bỏ trạng thái phong huyệt (mạn đà) | Chức năng thiếu/chưa hoàn chỉnh | Mạn Đà chưa mở, Phong Nhập Tùng giải phong huyệt chưa được nghiệm thu. [MANTUO](#mantuo) |
| 92 | fix bug buff hoa anh không giảm 1 hoa khi có tác dung. | Chức năng thiếu/chưa hoàn chỉnh | Mạn Đà chưa mở, tiêu hoa khi Hoa Anh phát hiệu lực chưa được nghiệm thu. [MANTUO](#mantuo) |
| 93 | fix bug võ ðạo mạn đà chiếu minh hoạt động không đúng | Chức năng thiếu/chưa hoàn chỉnh | Mạn Đà/cây Chiếu Minh chưa được nối và nghiệm thu như HJ. [MANTUO](#mantuo) |
| 94 | fix nốt nhánh còn lại mạn đà (vãn lai) bao gồm cả buff cho quảng lăng tán đổi đoạn 1 thành 40 4 thành 75 | Chức năng thiếu/chưa hoàn chỉnh | Không tự áp hệ số40/75 của Vãn Lai/Quảng Lăng Tán khi phái chưa mở đúng CY. [MANTUO](#mantuo) |
| 94.5 | vậy là đã fix toàn bộ võ đạo tầng 1 và 2 của 10 phái trong thời gian 4 ngày tổng số võ đạo đã fix khoảng trên 40 cái = )) | Khác nhánh/thiết kế/bổ sung nội dung | Là lời tổng kết của tác giả đã sửa40+talent trong4ngày, không là chứng cứ chúng ta đã có các bản vá đó. [TALENT](#talent) |
| 95 | fix bug mạn đà võ đạo nhánh 1 chịu dame nhận được võ đạo của thiếu lâm | Chức năng thiếu/chưa hoàn chỉnh | Mạn Đà chưa mở; còn rủi ro trùng ID giữa GL/CY nếu bật cây cũ. Không nhập mù nhánh nhận buff Thiếu Lâm. [MANTUO](#mantuo) |
| 96 | fix bug không thể đi thủy nguyện sơn trang phát sinh do vh | Cần kiểm riêng, chưa kết luận | Chưa thử vào Thủy Nguyện/Nguyệt Sơn Trang; file không có scene ID và điều kiện mở để xác định đúng nhánh. [QUEST](#quest) |
| 97 | fix bug sát tinh công tôn thắng vô hạn phân thân đánh không chết và khi ra ngoài trước khi phó bản kết thúc không thể hoàn thành nhiệm vụ sát tinh | Cần kiểm riêng, chưa kết luận | Chưa chạy Sát Tinh Công Tôn Thắng qua phân thân/rời sớm; không nghiệm thu phụ bản từ test quest chung. [QUEST](#quest) |
| 98 | fix bug tư chất trang bị khi giám định ra nếu không cường hóa sẽ không có tác dung | Có xử lý/kiểm tra đạt trong phạm vi | Probe hàm thật: base100, cường hóa0, tư chất20% vẫn cộng20. Đường flush gọi quality ngoài điều kiện cường hóa; không tái hiện lỗi với trang bị thường. [EQUIPQUALITY](#equipquality) |
| 99 | fix bug không thể giám định tư chất item thất tinh + tư chất item thất tinh không có tác dụng | Cần kiểm riêng, chưa kết luận | Đồ Thất tinh/Thần binh là đường đặc biệt; 98 không chứng minh giám định đúng loại này. Cần fixture item cụ thể. [EQUIP](#equip) |
| 100 | fix bug nhân vật tự die vẫn tăng sát khí | Cần kiểm riêng, chưa kết luận | add_killer_pk_value không có kiểm self/nil riêng; điều kiện attacker/declaration có thể chặn. Chưa tái hiện self-death làm tăng sát khí, ghi rủi ro thay vì kết luận chắc. [PVP](#pvp) |
| 101 | fix bug trong phó bản các nhân vật trong đội có thể đồ sát nhau | Cần kiểm riêng, chưa kết luận | PERSONAL PK trả enemy nếu scene cho phép và không chặn đồng đội trước đó; có rủi ro theo PvPRule. Chưa ghép được đúng instance để xác nhận lỗi như log. [PVP](#pvp) |
| 102 | Mở lại cường hóa trang bị thất tinh đã hex fix bug cường hóa không cộng thêm điểm cho nhân vật | Cần kiểm riêng, chưa kết luận | Thần binh có đường cal_enhance_effect, nhưng UI rèn CY có whitelist riêng. Chưa thử đúng Thất tinh và tổng chỉ số sau nâng. [EQUIP](#equip) |
| 103 | Bổ xung những thứ còn thiếu phái mạn đà như nhiệm vụ, chế dược, các script NPC, tự tìm đường ..... | Chức năng thiếu/chưa hoàn chỉnh | Mạn Đà chưa mở; nhiệm vụ/chế dược/NPC/path không thể được coi là hoàn chỉnh. [MANTUO](#mantuo) |
| 104 | fix bug mạn đà quảng lăng tán những tia đạn phụ đánh lên quái không gây thù hận | Chức năng thiếu/chưa hoàn chỉnh | Chưa có phái Mạn Đà hoạt động để nghiệm thu aggro đạn phụ Quảng Lăng Tán. [MANTUO](#mantuo) |
| 105 | fix bug danh hiệu môn phái đã dùng điểm đổi không hiển thị là đã sở hữu | Có xử lý/kiểm tra đạt trong phạm vi | Danh hiệu đã nối danh sách sở hữu, chọn/ẩn và lưu. Chưa thử từng NPC đổi danh hiệu môn phái/điểm, nên không khẳng định mọi trang đổi hiển thị đúng. [TITLE](#title) |
| 106 | Add tự động tìm đường đến map mạn đà như các phái khác | Chức năng thiếu/chưa hoàn chỉnh | Chưa mở bản đồ/phái Mạn Đà theo luồng CY; không có nghiệm thu tự tìm đường tới phái. [MANTUO](#mantuo) |
| 107 | Fix Quest dẫn đạo của võ đạo môn phái tang 1 lv 60 nhận ở triêu thiên sư tầng 2 nhận ở npc võ đạo môn phái. | Chức năng thiếu/chưa hoàn chỉnh | Thiên phú CY Tông môn và Võ đạo GL chưa thống nhất; hai quest dẫn đạo được log nêu chưa nghiệm thu. [TALENT](#talent) |
| 108 | fix bug thành bang hội không lưu bỏ việc mặc định sau bảo trì bang =5. | Có xử lý/kiểm tra đạt trong phạm vi | Có city database và đọc level thật, không ép level5. Test8 ca city query đạt; chưa có vòng tạo thành→restart→vào thành live đầy đủ. [CITY](#city) |
| 109 | fix bug Q bang hội bao gồm phụ bản text..... liên quan. | Chức năng thiếu/chưa hoàn chỉnh | Một số quest thành còn thiếu CityIncProgress; hiện chặn trước khi mất tiền/nhiệm vụ. “Quest/phụ bản/text bang” rộng hơn phạm vi đã hoạt động. [CITY](#city) |
| 110 | fix bug không thể dùng điểm bang hội đổi ngân bì lệnh tiễn và đổi lệnh bài， thăng cấp kỹ năng cuộc sống bang thất bại. | Chức năng thiếu/chưa hoàn chỉnh | Đã có cống hiến authority và phúc lợi cơ bản; nâng nghề bang/đổi từng token chưa nghiệm thu, UI nghiên cứu thành còn stub. [CITY](#city) |
| 111 | fix bug thăng cấp kiến trúc bang không trừ điểm mở rộng hoặc các loại điểm khác chỉ trừ quỹ bang. | Chức năng thiếu/chưa hoàn chỉnh | Xây/nghiên cứu thành chưa đầy đủ, các nhiệm vụ cần progress đang chặn an toàn. Không được gọi là nâng cấp thành đúng mọi loại điểm. [CITY](#city) |
| 112 | fix bug mất thẻ đổi tên khi đổi tên thất bại. | Lỗi tiềm ẩn trong mã | Gọi callback thật với nRetType1/2/3/4 vẫn xóa1thẻ trước khi xét thất bại. Caller hiện tại chỉ gọi After với0, nên xác nhận lỗi tiềm ẩn của callback, chưa tái hiện mất thẻ từ UI. [RENAME](#rename) |
| 113 | fix bug chạy thương mua full rương dis nhân vật. | Chức năng thiếu/chưa hoàn chỉnh | Đường shop thương nhân chưa nối đủ. Test ngân phiếu/túi đầy đạt không chứng minh mua full rương chạy thương không disconnect. [CITY](#city) |
| 114 | fix bug ngân phiếu hiển thị giá trị không đúng khi đầy. | Cần kiểm riêng, chưa kết luận | Đã sửa thứ tự SetBagItemParam(value,type) của ngân phiếu; chưa thử UI đầy rương/giá trị biên packet ngân phiếu. [CITY](#city) |
| 115 | Thêm rs giá cho shop thương nhân + shop thương nhân hiển thị vật phẩm theo id đúng với mô tả khi tạo đặc sản khi tạo bang | Chức năng thiếu/chưa hoàn chỉnh | Reset giá/shop đặc sản theo thành chưa hoàn thành; AskCityShop/DoCityShop thiếu đường hoạt động. [CITY](#city) |
| 116 | fix bug nhiệm vụ thú hồn không thể nhận, làm cũng như hoàn thành (có thể tham khảo theo hướng dẫn của origin vì giống nhau y hệt) | Cần kiểm riêng, chưa kết luận | UI nâng/tẩy Thú hồn đã có, nhưng quest dẫn hệ Thú hồn khác; thiếu hướng dẫn Origin được file viện dẫn và chưa thử chuỗi. [PET](#pet) |
| 117 | fix bug thanh khâu khi ðánh boss cuối xong vẫn có thể khiêu chiến tiếp。 | Cần kiểm riêng, chưa kết luận | Chưa chạy tới boss cuối Thanh Khâu rồi thử khiêu chiến lại; cần map/quest cụ thể. [QUEST](#quest) |
| 118 | Mở 50 vũ khí huyễn sức mới fix sken động tác | Khác nhánh/thiết kế/bổ sung nội dung | CY đã nhập68dòng huyễn sức HJ/195biến thể, khác danh sách50của log. Chưa chứng minh50món đó là đúng50món này khi thiếu ID. [ASSET](#asset) |
| 119 | fix Bad particle affector attribute line dưới client tầm 3k line | Lỗi đã có bằng chứng | Log GUI đúng Game hiện tại còn9dòng Bad particle affector attribute cho MeshAnimationAffector anim_pos1/2/3. Cùng chữ ký lỗi, không phải3000dòng; chưa đo ảnh hưởng hình ảnh/FPS. [PARTICLE](#particle) |
| 120 | update tổng xuyên thích và kháng xuyên | Có xử lý/kiểm tra đạt trong phạm vi | Tổng xuyên thích/kháng từ mission602/603, snapshot login/map và chữ bay đã nối; có kiểm đơn vị và PvE/relogin lịch sử. [SMART](#smart) |
| 121a | fix bug item cố định mua đi bán lại thành không cố định. | Có xử lý/kiểm tra đạt trong phạm vi | Probe buy_back thật giữ cùng object/GUID/bound/+9/tư chất. Chưa thử mọi luồng thương hội/đấu giá; không mở rộng kết luận sang giao dịch khác. [BUYBACK](#buyback) |
| 121b | fix bug tư chất pet hiển thị trong kho không đúng | Chức năng thiếu/chưa hoàn chỉnh | Khung kho pet/chi tiết extra-view chưa đủ đường native. Không thể khẳng định tư chất pet trong kho hiển thị chuẩn. [PETVIEW](#petview) |
| 122 | fix bug model thú hồn đè lên nhau khi thử thú hồn phải chuyển map mới clean | Cần kiểm riêng, chưa kết luận | Đã sửa model riêng Võ hồn nhưng đó khác Thú hồn. Chưa thử liên tục nhiều model Thú hồn rồi đổi map để xác nhận cache/attachment chồng. [PETVIEW](#petview) |
| 123 | fix bug bày bán shop knb pet giá thực tế là knb nhận về thành vàng | Chức năng thiếu/chưa hoàn chỉnh | Mua pet ở player shop bị return vô điều kiện; không có tuyến KNB pet shop hoàn chỉnh để nghiệm thu tiền người bán. Không báo đã đúng chỉ vì không mua được. [SHOP](#shop) |
| 124 | fix bug trang bị thất tinh khi nâng lv tăng lv đồ lên ví dụ thể lực base là 50 tăng lv đồ đó lên thì nó cộng 150 thoát ra vào lại máu bị giảm đi đúng 100 cái điểm cộng thêm kia còn hp max không đổi mp cũng bị tương tự | Cần kiểm riêng, chưa kết luận | Chưa có fixture đúng Thất tinh tăng base50→150 và HP/MP trước/sau relog; không suy từ metadata equip thường. [EQUIP](#equip) |
| 125 | Thêm 30 bộ thời trang 20 tóc 20 mặt mới thời trang mới đã ghép sken | Khác nhánh/thiết kế/bổ sung nội dung | CY đã nhập230thời trang,149cặp tóc,100cặp mặt HJ; không xác nhận trùng đúng30/20/20mẫu trong log thiếu ID. [ASSET](#asset) |
| 126 | fix bug tỷ lệ sử dung cao phản kích, phản kích, hấp huyết, cao hấp huyết của pet đều là 100% mặc dù không phải là pet nhanh nhẹn có nghĩa là pet dung mãnh ép cao phản kích cung co tac dung nhu pet nhanh nhẹn | Cần kiểm riêng, chưa kết luận | std_impact_022 có xác suất ngẫu nhiên, không mặc định luôn100%; cần kiểm mapping skill/personality/params để xác nhận từng loại phản kích/hấp huyết. [PET](#pet) |
| 127 | Thêm 2 loại ngọc thời trang | Khác nhánh/thiết kế/bổ sung nội dung | Thêm2loại ngọc thời trang là nội dung mới; thiếu ID và công thức để đối chiếu. [EQUIP](#equip) |
| 128 | việt hóa trả lời câu hỏi khảo quan thời gian sự kiện 17h30 | Cần kiểm riêng, chưa kết luận | Chưa kiểm lịch17:30 và bộ câu hỏi khảo quan; không có danh sách đáp án chuẩn trong file. [TEXT](#text) |
| 129 | fix bug không chạy được tào vận | Cần kiểm riêng, chưa kết luận | Tào vận là hệ khác chạy thương bang; chưa thử nhận/chở/trả theo tuyến, không gộp với test ngân phiếu bang. [CITY](#city) |
| 130 | fix bug train thdc 4 tầm 1 giờ sẽ dump client | Cần kiểm riêng, chưa kết luận | Chưa có soak test THDC4 một giờ của binary hiện tại. Phiên GUI vài phút/không crash không loại trừ lỗi dài phiên. [RUNTIME](#runtime) |
| 131 | fix bug thuộc tính thẻ kỷ niệm không đồng bộ + fix bug tang ngoại thủ lại + nội công, đồng thời làm lại ui giống sohu | Cần kiểm riêng, chưa kết luận | Chưa kiểm đúng mapping thẻ kỷ niệm ngoại thủ→nội công và các trang; kiểm tư chất equip thường không bao phủ card. [CARD](#card) |
| 132 | fix bug boss long quy không đánh thường | Cần kiểm riêng, chưa kết luận | Thiếu monster ID/map của boss Long Quy; chưa theo dõi AI/đánh thường đúng boss. [COMBAT](#combat) |
| 133 | fix bug không thể tiến hành bang chiến trong trác lộc chiến trường + đổi điểm công trạng bị lỗi (khả năng vẫn còn sai xót vì bản chất tính năng này trên HJ 0.5,0.6 là chưa hoàn chỉnh mình buộc phải fix hoặc fake lại tương đối nhiều thứ) | Chức năng thiếu/chưa hoàn chỉnh | Danh sách/tuyên chiến cơ bản đã nối, nhưng Trác Lộc chiến trường/điểm công trạng/end-to-end chưa hoàn thiện. Tác giả HJ cũng thừa nhận fake/chưa đầy đủ; không dùng làm chuẩn chắc chắn. [CITY](#city) |
| 134 | mở giới hạn log acc từ 2 thành 5 1 pc | Khác nhánh/thiết kế/bổ sung nội dung | Giới hạn2→5account/PC là cấu hình/chính sách mới, không tự thay khi yêu cầu hiện tại chỉ là kiểm lỗi. [RUNTIME](#runtime) |
| 135 | fix và thêm võ đạo 2 tang 1 và 2 của ác nhân cốc đồng thời sửa lại 1 vài hiệu ung skill cho chuẩn | Chức năng thiếu/chưa hoàn chỉnh | Thiên phú phái mở rộng còn thiếu mapping/UI đúng CY; không công bố40+talent HJ đã được port. [TALENT](#talent) |
| 136 | thêm động tác cầm vũ khí trượng type = 8 (2026/08/26 bỏ cơ chế cũ không thêm cột cơ chế mới sẽ thêm cột day du không làm giảm hiểu năng của client như hook type8 cũ dong thoi fix luôn tình trạng type vk mới bị lệch 1 nhịp so với vũ khí gốc do cơ chế đè type của hook cũ gây ra) | Cần kiểm riêng, chưa kết luận | CY dùng actionset/bảng loại vũ khí từ source, nhưng chưa kiểm đủ nhịp đánh type8với vũ khí gốc. Không áp hook đè type HJ. [ASSET](#asset) |
| 138 | fix ping gs giảm gấp 4 lần local ( tu 132 -> con 24-30) | Cần kiểm riêng, chưa kết luận | 132→24–30ms là số đo nhánh HJ; chưa có benchmark CY cùng tải/phần cứng/tuyến mạng. Không quy thành lỗi hay cam kết tăng4lần. [RUNTIME](#runtime) |
| 139 | Thêm nhiệm vụ sư môn ac nhan coc va doi danh hieu ac nhanh doi vo dao quy Nguyen dan | Chức năng thiếu/chưa hoàn chỉnh | Quest sư môn chín phái cổ đã kiểm, không bao phủ trọn Ác Nhân/đổi Võ đạo Quy Nguyên Đan và danh hiệu. [TALENT](#talent) |
| 140 | thêm boi suc dau suc | Khác nhánh/thiết kế/bổ sung nội dung | CY đã nhập12đầu sức/21bối sức HJ và kiểm preview hai giới; không phải lỗi được mô tả trong mục này. [ASSET](#asset) |

## Nguồn để đối chiếu tiếp

Các nhóm nguồn là điểm vào điều tra và bằng chứng theo phạm vi đã ghi, không phải một test đầy đủ cho mọi dòng tham chiếu chúng. Bản chụp source được giữ cùng SHA trong evidence.json để kết luận không trôi theo những lần sửa sau.

### WUHUN

- [Docs/specs/power-systems-20260924_vi.md](<C:/TLBB/085/CY-Source/Docs/specs/power-systems-20260924_vi.md>)
- [Tools/game/power_ui.py](<C:/TLBB/085/CY-Source/Tools/game/power_ui.py:135>)
- [Docs/specs/client/wuhun-appearance-fix-20260925_vi.md](<C:/TLBB/085/CY-Source/Docs/specs/client/wuhun-appearance-fix-20260925_vi.md>)

### CHAT

- [Src/Client/CEGUISystem/UIString.cpp](<C:/TLBB/085/CY-Source/Src/Client/CEGUISystem/UIString.cpp:731>)
- [Docs/specs/equipment-tooltips-20260924_vi.md](<C:/TLBB/085/CY-Source/Docs/specs/equipment-tooltips-20260924_vi.md:58>)

### EQUIP

- [Docs/specs/equipment-tooltips-20260924_vi.md](<C:/TLBB/085/CY-Source/Docs/specs/equipment-tooltips-20260924_vi.md>)
- [Docs/specs/equipcraft-20260924_vi.md](<C:/TLBB/085/CY-Source/Docs/specs/equipcraft-20260924_vi.md>)
- [GameServer/lualib/db/human_attrib.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/lualib/db/human_attrib.lua:2051>)

### PET

- [GameServer/lualib/pet_attrib.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/lualib/pet_attrib.lua:533>)
- [GameServer/lualib/db/pet_attrib.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/lualib/db/pet_attrib.lua:776>)
- [Tools/server/cys_petsoul.lua](<C:/TLBB/085/CY-Source/Tools/server/cys_petsoul.lua:10>)
- [Build/Logs/2026-09-28-hj05-audit/pet_integrity_tests.txt](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-audit/pet_integrity_tests.txt:114>)

### PETQUALITY

- [GameServer/lualib/item.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/lualib/item.lua:1662>)
- [GameServer/lualib/pet_attrib.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/lualib/pet_attrib.lua:533>)
- [GameServer/lualib/db/pet_attrib.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/lualib/db/pet_attrib.lua:533>)
- [Build/Logs/2026-09-28-hj05-audit/targeted-probes.txt](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-audit/targeted-probes.txt:1>)

### PETLIFE

- [GameServer/lualib/item.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/lualib/item.lua:1333>)
- [GameServer/lualib/item.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/lualib/item.lua:1662>)
- [Tools/server/cys_petsoul.lua](<C:/TLBB/085/CY-Source/Tools/server/cys_petsoul.lua:129>)
- [Build/Logs/2026-09-28-hj05-audit/targeted-probes.txt](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-audit/targeted-probes.txt:2>)

### PETVIEW

- [Src/Client/WXClient/Network/CysPetNet.cpp](<C:/TLBB/085/CY-Source/Src/Client/WXClient/Network/CysPetNet.cpp:841>)
- [Src/Client/LuaApiGen/LuaApiGen_Pet.cpp](<C:/TLBB/085/CY-Source/Src/Client/LuaApiGen/LuaApiGen_Pet.cpp:119>)
- [Build/Logs/2026-09-28-hj05-audit/pet-surface.json](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-audit/pet-surface.json>)

### SHOP

- [GameServer/services/scene/scenecore.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/services/scene/scenecore.lua:4102>)
- [GameServer/services/scene/scenecore.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/services/scene/scenecore.lua:4918>)
- [Src/Client/WXClient/Network/CysPetNet.cpp](<C:/TLBB/085/CY-Source/Src/Client/WXClient/Network/CysPetNet.cpp:841>)

### COMBAT

- [Docs/specs/server/menpai-fix_vi.md](<C:/TLBB/085/CY-Source/Docs/specs/server/menpai-fix_vi.md>)
- [GameServer/services/scene/skill/combat_core.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/services/scene/skill/combat_core.lua:227>)
- [Docs/specs/gameplay/gameplay-completion-20260927_vi.md](<C:/TLBB/085/CY-Source/Docs/specs/gameplay/gameplay-completion-20260927_vi.md:78>)

### MANTUO

- [GameServer/lualib/define.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/lualib/define.lua:263>)
- [GameServer/services/scene/skill/condition_delplete_core.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/services/scene/skill/condition_delplete_core.lua:621>)
- [Docs/specs/server/cs3b-menpai_vi.md](<C:/TLBB/085/CY-Source/Docs/specs/server/cs3b-menpai_vi.md>)

### TALENT

- [Docs/specs/progression-200-20260924_vi.md](<C:/TLBB/085/CY-Source/Docs/specs/progression-200-20260924_vi.md:41>)
- [GameServer/lualib/talentenginer.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/lualib/talentenginer.lua:26>)
- [GameServer/lualib/cy_four_combat/release.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/lualib/cy_four_combat/release.lua:17>)

### QUEST

- [Docs/specs/gameplay/gameplay-completion-20260927_vi.md](<C:/TLBB/085/CY-Source/Docs/specs/gameplay/gameplay-completion-20260927_vi.md>)
- [Build/Logs/2026-09-28-hj05-audit/test_quest_rewards.txt](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-audit/test_quest_rewards.txt:1>)
- [Build/Logs/2026-09-28-hj05-audit/test_gameplay_audit.txt](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-audit/test_gameplay_audit.txt:2>)

### GIFT

- [Docs/specs/client/runtime-polish-20260926_vi.md](<C:/TLBB/085/CY-Source/Docs/specs/client/runtime-polish-20260926_vi.md>)
- [Build/Logs/2026-09-28-hj05-audit/test_runtime_gifts.txt](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-audit/test_runtime_gifts.txt>)

### SMART

- [Docs/specs/smart-equip-piercing-20260925_vi.md](<C:/TLBB/085/CY-Source/Docs/specs/smart-equip-piercing-20260925_vi.md>)

### MOVE

- [Docs/specs/gameplay-fixes-20260923_vi.md](<C:/TLBB/085/CY-Source/Docs/specs/gameplay-fixes-20260923_vi.md>)
- [Docs/specs/client/runtime-polish-20260926_vi.md](<C:/TLBB/085/CY-Source/Docs/specs/client/runtime-polish-20260926_vi.md>)
- [Docs/specs/social-completion-20260928_vi.md](<C:/TLBB/085/CY-Source/Docs/specs/social-completion-20260928_vi.md>)

### CITY

- [Docs/specs/social-completion-20260928_vi.md](<C:/TLBB/085/CY-Source/Docs/specs/social-completion-20260928_vi.md>)
- [Src/Client/LuaApiGen/LuaApiGen_City.cpp](<C:/TLBB/085/CY-Source/Src/Client/LuaApiGen/LuaApiGen_City.cpp:50>)
- [Src/Client/WXClient/Network/CysGuildWarNet.cpp](<C:/TLBB/085/CY-Source/Src/Client/WXClient/Network/CysGuildWarNet.cpp:52>)
- [Game_2/Script/scripts/city0_LevelUp.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/Game_2/Script/scripts/city0_LevelUp.lua:66>)
- [GameServer/lualib/cys_social_city.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/lualib/cys_social_city.lua>)

### ASSET

- [Docs/specs/client/hj-appearance-import-20260925_vi.md](<C:/TLBB/085/CY-Source/Docs/specs/client/hj-appearance-import-20260925_vi.md>)
- [Registry/hj-appearance-catalog.json](<C:/TLBB/085/CY-Source/Registry/hj-appearance-catalog.json>)

### TEXT

- [Docs/specs/client/hj-appearance-import-20260925_vi.md](<C:/TLBB/085/CY-Source/Docs/specs/client/hj-appearance-import-20260925_vi.md:9>)
- [Docs/specs/gameplay/gameplay-completion-20260927_vi.md](<C:/TLBB/085/CY-Source/Docs/specs/gameplay/gameplay-completion-20260927_vi.md>)

### CARD

- [Docs/specs/equipment-tooltips-20260924_vi.md](<C:/TLBB/085/CY-Source/Docs/specs/equipment-tooltips-20260924_vi.md:58>)

### BUFF

- [GameServer/lualib/impactenginer.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/lualib/impactenginer.lua:106>)
- [Build/Logs/2026-09-28-hj05-audit/targeted-probes.txt](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-audit/targeted-probes.txt:5>)

### ELEMENT

- [Docs/specs/gameplay/quest-crafting-xinfa-elements-20260927_vi.md](<C:/TLBB/085/CY-Source/Docs/specs/gameplay/quest-crafting-xinfa-elements-20260927_vi.md:43>)
- [Build/Logs/2026-09-28-hj05-audit/test_gameplay_audit.txt](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-audit/test_gameplay_audit.txt:2>)

### EQUIPQUALITY

- [GameServer/lualib/db/human_attrib.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/lualib/db/human_attrib.lua:869>)
- [GameServer/lualib/db/human_attrib.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/lualib/db/human_attrib.lua:882>)
- [Build/Logs/2026-09-28-hj05-audit/targeted-probes.txt](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-audit/targeted-probes.txt:6>)

### AOE

- [GameServer/services/scene/skill/impact_logic/std_impact_101.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/services/scene/skill/impact_logic/std_impact_101.lua:39>)
- [GameServer/services/scene/obj/monster.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/services/scene/obj/monster.lua:749>)
- [GameServer/services/scene/obj/character.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/services/scene/obj/character.lua:1878>)
- [GameServer/lualib/impactenginer.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/lualib/impactenginer.lua:422>)
- [Build/Logs/2026-09-28-hj05-audit/targeted-probes.txt](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-audit/targeted-probes.txt:8>)

### PVP

- [GameServer/services/scene/obj/human.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/services/scene/obj/human.lua:4886>)
- [GameServer/services/scene/ai/human.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/services/scene/ai/human.lua:1098>)
- [Build/Logs/2026-09-28-hj05-audit/pvp_integrity_tests.txt](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-audit/pvp_integrity_tests.txt:84>)

### TITLE

- [Docs/specs/settings-friends-titles-20260928_vi.md](<C:/TLBB/085/CY-Source/Docs/specs/settings-friends-titles-20260928_vi.md>)
- [Src/Client/WXClient/Network/CysCommunityNet.cpp](<C:/TLBB/085/CY-Source/Src/Client/WXClient/Network/CysCommunityNet.cpp:94>)

### RENAME

- [Game_2/Script/scripts/event/huodong/echangeusername.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/Game_2/Script/scripts/event/huodong/echangeusername.lua:210>)
- [GameServer/services/scene/scenecore.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/services/scene/scenecore.lua:8992>)
- [GameServer/lualib/playermanager_core.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/lualib/playermanager_core.lua:183>)
- [Build/Logs/2026-09-28-hj05-audit/targeted-probes.txt](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-audit/targeted-probes.txt:9>)

### BUYBACK

- [GameServer/services/scene/obj/human.lua](<//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/GameServer/services/scene/obj/human.lua:1487>)
- [Build/Logs/2026-09-28-hj05-audit/targeted-probes.txt](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-audit/targeted-probes.txt:7>)

### PARTICLE

- [Build/Logs/2026-09-28-social-completion/gui-release-alliance/WXRender.log](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-social-completion/gui-release-alliance/WXRender.log:392>)
- [Build/Logs/2026-09-28-social-completion/gui-release-alliance/run.json](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-social-completion/gui-release-alliance/run.json:33>)

### BUILD

- [Docs/10-CAU-TRUC-VA-KIEM-TOAN-BUILD_vi.md](<C:/TLBB/085/CY-Source/Docs/10-CAU-TRUC-VA-KIEM-TOAN-BUILD_vi.md:230>)

### RUNTIME

- [Build/Logs/2026-09-28-hj05-audit/evidence.json](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-audit/evidence.json:9>)
- [Build/Logs/2026-09-28-hj05-audit/server-status.txt](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-audit/server-status.txt>)

### SCOPE

- [Build/Logs/2026-09-28-hj05-audit/items.json](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-audit/items.json>)

## Thứ tự xử lý đề nghị

1. Sửa lưu/nạp thọ Thú hồn và tính tư chất trang bị pet; kiểm bản ghi cũ, cùng pet trước/sau triệu hồi/map/relogin. Không đổi giá trị thọ đã lưu bằng migration khi chưa cần.
2. Sửa Nộ Hỏa Liên Trảm theo một lần thi triển, giữ đúng tương tác nhiều đợt hit; thử một mục tiêu/nhiều mục tiêu/miss và đối chiếu công thức gốc. Không chỉ chặn số đao ở client.
3. Sửa callback đổi tên để chỉ tiêu thẻ sau thành công có xác nhận; kiểm tên trùng/lỗi DB/gửi lặp và giữ đồng bộ tên/cache.
4. Bổ sung hỗ trợ đúng semantics `anim_pos1/2/3` bằng nguồn Fairy/CY, đối chiếu hình ảnh. Không xóa cảnh báo để giả hết lỗi.
5. Hoàn thiện từng tuyến kho/thương hội trân thú, thành bang và thiên phú; chưa bật nhánh return/stub bằng cách bỏ guard mà chưa nối đủ giao dịch.

Hồ sơ máy đọc được: [evidence.json](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-audit/evidence.json>). Danh sách gốc đã chuẩn hóa: [items.json](<C:/TLBB/085/CY-Source/Build/Logs/2026-09-28-hj05-audit/items.json>). Bảng nhận định nguồn: [hj05_assessments.tsv](<C:/TLBB/085/CY-Source/Tools/audit/hj05_assessments.tsv>).
