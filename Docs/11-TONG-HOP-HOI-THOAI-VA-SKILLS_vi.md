# Tổng hợp cuộc trò chuyện và các skill CY-Source

Ngày tổng hợp: **25/09/2026**. Task: **Fix gameplay and UI issues**, ID `01a0cb73-9baa-7e93-bbf5-873f314a71da`. Đây là bản tổng hợp yêu cầu, quyết định, kết quả và kinh nghiệm để tiếp tục dự án; không phải một lượt kiểm thử lại toàn bộ game.

## 1. Cách khôi phục lịch sử, kể cả phần trước khi nén

Đã đối chiếu ba nguồn:

1. Các yêu cầu người dùng còn trong hội thoại và dữ liệu truy hồi của chính task qua `read_thread` (ba trang, 25 turn tại thời điểm đọc). Một số turn API chỉ trả thông tin trạng thái, không có nội dung.
2. Nhật ký gốc cục bộ `C:/Users/PC -Sam/.codex/sessions/2026/09/23/rollout-2026-09-23T06-29-06-01a0cb73-9baa-7e93-bbf5-873f314a71da.jsonl`. Đã đọc các tin nhắn và kết quả qua 34 mốc nén trước yêu cầu này, gồm 23 câu trả lời kết thúc trước yêu cầu tổng hợp này. Nhờ đó đã lấy lại đầy đủ sáu câu hỏi cường hóa, đáp án, NPC mở khung và các giới hạn từng lượt.
3. Các đặc tả trong `Docs/specs`, ghi chú bàn giao, source/generator và đường dẫn bằng chứng `Build/Logs` được ghi trong báo cáo. Những bản tóm tắt công việc còn trong ngữ cảnh được đối chiếu với các nguồn này.

**Giới hạn phục hồi:** snapshot nén trong nhật ký có phần `encrypted_content`, không có bản tóm tắt plaintext để giải mã trực tiếp. Nội dung trước nén được phục hồi từ bản ghi gốc còn lưu và tài liệu, không phải giải mã snapshot. Không tuyên bố khôi phục nguyên văn một phần đã bị xóa hoặc chưa từng được lưu. Không sao chép raw log, credential, dữ liệu tài khoản hay BSON backup vào skill.

Chỉ mục phục hồi và kiểm tra skill nằm tại `Build/Logs/2026-09-25-skills/`. Mốc chốt lịch sử là câu trả lời hoàn tất Võ hồn trước yêu cầu tạo skill; bản ghi của chính công việc tổng hợp không được tính làm kết quả gameplay mới.

## 2. Nguyên tắc và phạm vi phải giữ

- **Học trước, phản biện, rồi áp dụng có điều kiện:** khi phiên bản có sẵn làm được, đọc nó trước. Không tự đặt tên, màu, công thức hoặc ID khi chưa đối chiếu.
- Mục tiêu CY-Source là client x64 build từ source, giữ phong cách/độ đẹp của game và tận dụng tài nguyên có sẵn. Tạo ảnh mới khi thật sự thiếu, như đe/búa của nhịp rèn.
- Phạm vi công việc đã thực hiện: `C:/TLBB/085/CY-Source` và server thử `/home/ubuntu/cys-test-20260913` trong WSL `TLBB`. Login/game 15733/15734, Mongo 27018, MQTT 1884. Các cổng này phân biệt với hệ TLBB chính; kiểm cấu hình hiện tại trước dùng.
- `client`, `client_GL`, `Tools/DATA NEW/CY Game`, `Reference`, CanonicalCY và server chính là nguồn đọc đối chiếu trong chuỗi tác vụ CY này. Không áp dụng quy trình sửa GL trực tiếp sang đây.
- Sửa generator/layout/host/source đúng nơi; không chữa tạm chỉ trong output Play. Không bật lại GLResponsive đã gây mất điều khiển.
- Server quyết định vật phẩm, chi phí, kết quả, quyền GM và progression. Client hiển thị/nhận thao tác; có nút hoặc icon không đồng nghĩa chức năng đã hoạt động.
- Kiểm thử bao gồm thao tác thật, log chức năng, ảnh khi cần và di chuyển sau đóng UI. PASS đăng nhập chung không thay PASS tính năng. Bằng chứng chỉ áp dụng đúng binary/manifest đã chạy.
- Sao lưu fixture toàn BSON trước thử, phục hồi chính xác sau thử. Không để lại đồ/tiền/cấp thử trên nhân vật. Yêu cầu GM chỉ áp danh sách tài khoản test đã xác định, không mở quyền rộng hơn.
- Các nguyên tắc trên là kiến thức dự án, không là giấy phép tự triển khai mọi thay đổi tương lai. Làm trong phạm vi người dùng giao; không yêu cầu xác nhận lại những lựa chọn đã chốt.

## 3. Tổng hợp yêu cầu và trạng thái có bằng chứng

Các chữ “đã sửa/đã kiểm” dưới đây dẫn tới bằng chứng của đợt tương ứng. Chưa chạy lại tất cả các đợt trên binary cuối 25/09 trong tác vụ tạo skill này.

| Nhóm yêu cầu | Kết quả và giới hạn | Nguồn |
|---|---|---|
| Phòng thay đồ kẹt đối chiếu máy chủ | Sửa dispatch để catalog 990021 không bị handler chung lấy mất; kiểm phản hồi 8 nhóm | [Gameplay đầu](specs/gameplay-fixes-20260923_vi.md) |
| Khinh công sai action, cho bấm di chuyển lúc bay | Tiến giai đoạn bằng animation-end, khóa tới hết tiếp đất, bỏ lệnh chen; kiểm skill 34/action 168–170 | [Gameplay đầu](specs/gameplay-fixes-20260923_vi.md) |
| Vũ khí Tân thủ khi nhập phái | Danh mục 15 phái, kiểm sức chứa cả lô, chặn nhận lại; live qua NPC Võ Đang | [Gameplay đầu](specs/gameplay-fixes-20260923_vi.md) |
| Chỉ số đặc trưng môn phái | Đối chiếu bảng điểm và hệ số; vài phái cùng 5 điểm nhưng hệ số chiến đấu khác, không tự sửa cân bằng | [Action/trang bị](specs/actions-equipment-audit-20260923_vi.md) |
| Click bản đồ Alt+M | Nối event CY và AutoRunToTarget thật; kiểm click widget và di chuyển | [Gameplay đầu](specs/gameplay-fixes-20260923_vi.md) |
| Skill mất chiêu, mô tả trống | Dựng danh mục 8 tâm pháp rồi phủ learned; sửa cột mô tả; biểu thức động chưa có evaluator đầy đủ dùng mô tả dự phòng | [Gameplay đầu](specs/gameplay-fixes-20260923_vi.md), [Action](specs/actions-equipment-audit-20260923_vi.md) |
| Phổ thông có ô trống; Trận/Đấu/TH | Dồn action thật; Trận có catalog, Đấu cấp 50; TH có điều kiện nhưng hệ Thiên phú chưa hoàn thiện | [Đợt 2](specs/gameplay-round2-20260923_vi.md), [Cấp 200](specs/progression-200-20260924_vi.md) |
| F/Alt+số, kéo skill/item | Đủ 50 ô, ba trang F, lưu qua login; Alt trên F và sau đó nền trong suốt; thuốc đổi ô/tiêu 3→0/chuyển stack có kiểm | [Action](specs/actions-equipment-audit-20260923_vi.md), [Cấp 200](specs/progression-200-20260924_vi.md) |
| Esc đóng khung | Khôi phục CloseAllWindow và kiểm di chuyển sau đóng; giữ thứ tự nhập liệu | [Gameplay đầu](specs/gameplay-fixes-20260923_vi.md) |
| NPC/quái sai màu | Đối chiếu CY+bốn bộ dữ liệu: NPC trắng/viền xanh, quái chủ động đỏ, thụ động vàng. Trí nhớ “NPC vàng không viền” không khớp nguồn; chưa thử mọi quan hệ PvP | [Gameplay đầu](specs/gameplay-fixes-20260923_vi.md) |
| Tên/danh hiệu NPC bị cắt | Nới giới hạn ngang 600 px, cao tối thiểu32 px, wrap và bố trí theo chiều cao thực; kiểm tiếng Việt dài | [Nameboards](specs/npc-nameboards-20260923_vi.md) |
| Icon trước hội thoại | Giữ 32 mã ảnh đúng, sửa kích thước 25×25 thay 16×16, click/hover cùng hàng | [NPC icons](specs/npc-dialogue-icons-20260923_vi.md) |
| Mất nền ô trên mọi khung | Sửa renderer SimpleText vẽ imagery/TextArea; kiểm kê 3263 ô/634 layout không đồng nghĩa mở từng khung | [Nền và wheel](specs/shared-cells-mouse-wheel-20260923_vi.md) |
| Menu dài không cuộn | Nối input wheel và handler hội thoại/chat; thử 6 nhóm, không zoom khi cuộn UI, world vẫn zoom | [Nền và wheel](specs/shared-cells-mouse-wheel-20260923_vi.md) |
| SelfEquip thừa khoảng trống, thanh độ bền | Thu layout, giữ controls; thanh riêng nằm trong ActionArea. BaoShiCheck đỏ/xanh gốc là đổi ngọc, không phải độ bền | [Ô/độ bền](specs/cell-skin-durability-20260923_vi.md), [Action](specs/actions-equipment-audit-20260923_vi.md) |
| Tooltip/SuperTooltip/Alt/inspect | GUID cache, receiver so sánh, refresh/lifetime, hồ sơ đúng người, chặn reply muộn; live hai nhân vật 23/09. Một số profile/điểm server không gửi vẫn trống | [Inspect](specs/tooltip-inspect-20260923_vi.md) |
| Cường hóa, khắc tên/minh, tư chất, ngọc, tinh khắc | Tính/hiện đúng dữ liệu đã có, mã creator tách riêng; không bịa tên người khắc. Tẩy luyện được nạp lại sau login | [Equipment tooltip](specs/equipment-tooltips-20260924_vi.md) |
| Màu tooltip, Thăng Linh và điêu văn | Màu theo phẩm chất GL, sáu thao tác Chế tác, &W khác &SQ; giao dịch/relogin có kiểm. Lưu Bác và mọi hiệu ứng viền chưa xác minh đủ | [Equipcraft](specs/equipcraft-20260924_vi.md) |
| Cường hóa mới Space/đe/búa | Đã thay thao tác bằng nhịp rèn tới+9, giữ bảng, server challenge; xem quyết định ở mục 4 | [Forge](specs/forge-timing-20260923_vi.md) |
| Hệ ngọc | Đã đọc Lua GL và vá kiểm nguồn/đích trước phí; chưa hoàn thiện tất cả giao diện/packet ghép, khảm và ngọc nâng cao | [Action](specs/actions-equipment-audit-20260923_vi.md) |
| Shop NB trùng đồ wardrobe | Lọc 1741 lượt hàng/25 shop có mapping chắc chắn, giữ nhuộm/không xác định; bố cục/giao dịch đã thử, vài nhãn dài còn cắt | [Action](specs/actions-equipment-audit-20260923_vi.md) |
| Ngoại hình chọn nhân vật khác trong game | Đọc dữ liệu face/hair/sex/equipment/cosmetic đã lưu, bỏ bộ cố định; Wuhun bổ sung 25/09 | [Đợt 2](specs/gameplay-round2-20260923_vi.md), [Wuhun cuối](specs/client/wuhun-appearance-fix-20260925_vi.md) |
| Huyễn sức che mất thân | Kiểm 956 mẫu mapping và vài ảnh đỏ, thêm fallback; chưa tái hiện đúng tổ hợp trong ảnh người dùng | [Đợt 2](specs/gameplay-round2-20260923_vi.md) |
| Nhặt tất cả, túi 100 ô, stack 250 | Nhặt theoGUID, vùng đồ/nguyên liệu riêng, stackable mới 250; bắt và sửa dupe tại điểm Skynet yield; replay/split/merge/relogin có kiểm | [Đợt 2](specs/gameplay-round2-20260923_vi.md) |
| Thiên cơ cẩm nang | Từ stub ở đợt đầu thành kho riêng 120 ô có revision/GUID, cất/rút/relogin giữitem | [Đợt 2](specs/gameplay-round2-20260923_vi.md) |
| Tuyệt Tình chém 3 lần/EXP trước đạn | Sửa HitTime/nhịp tiếp theo/delayed impact; ca đo đạn chạm trước EXP 485 ms; timing có phần suy luận tương thích | [Action](specs/actions-equipment-audit-20260923_vi.md) |
| EXP báo nhưng không cộng; tích lũy 3,5 lần | Đồng bộ bảng EXP, tổng và phần nhận thật; giữ EXP cũ vượtcap; unsigned rộng không âm | [Đợt 2](specs/gameplay-round2-20260923_vi.md), [Cấp 200](specs/progression-200-20260924_vi.md) |
| Cấp 200 | Cận trên server 201, bảng điểm/EXP nối theo dữ liệu, giữ điều kiện thăng cấp; live 199→200/chặn 201/relogin | [Cấp 200](specs/progression-200-20260924_vi.md) |
| Tự chiến đấu | Normal AI/skill/item, cấu hình và dừng đúng, thuốc thật/relogin có kiểm; Võ ý/chuỗi phó bản FB chưa làm | [Cấp 200](specs/progression-200-20260924_vi.md) |
| Thiên phú | Chưa chốt Tông môn CY hay Võ đạo GL; thiếu native CY, không trộn hai hệ | [Cấp 200](specs/progression-200-20260924_vi.md) |
| GMTool và tài khoản testGM | Port UI GL, quyền server;16 account test00–test15 quyền 98, tài khoản ngoài danh sách bị từ chối | [Đợt 2](specs/gameplay-round2-20260923_vi.md), [Cấp 200](specs/progression-200-20260924_vi.md) |
| Cổng chuyển bản đồ |203 đường/108 file được đối chiếu, giữ điều kiện; đi thử Lạc Dương↔Đôn Hoàng, chưa tất cả tuyến | [Đợt 2](specs/gameplay-round2-20260923_vi.md) |
| Animation đánh thường không dừng | Dừng tự lặp khi target chết/biến mất, giữ viên đã phóng | [Đợt 2](specs/gameplay-round2-20260923_vi.md) |
| Võ hồn/Thú hồn/Thần đỉnh/Tu luyện | Nối dữ liệu/thao tác/chỉ số/cost/persistence;4 kinh mạch tiến giai và khóa dòng/màu Thú hồn còn thiếu | [Power](specs/power-systems-20260924_vi.md) |
| Bay cao thú cưỡi | Ctrl + click trái theo CY, eligibilitycol 19, .fly, action 922–927, navmesh server kiểm hạ cánh; người cưỡi đơn, chưa chở đội/tự doY | [Flight](specs/server/mount-high-flight-20260924_vi.md) |
| Võ hồn preview ra người, quá nhỏ | Đổi từ tra NPC sang CharModelEx; phóng lớn và nới vùng vẽ; tháo/lắp/xoay có kiểm | [Preview](specs/client/wuhun-preview-20260925_vi.md) |
| Huyễn hóa và Wuhun world/SelfEquip/màn chọn nhân vật | Đã nối KFSObj, slot/ẩnhiện/cost, import 36 biến thể, relogin/chuyển scene và exactkhôi phục BSON | [Wuhun cuối](specs/client/wuhun-appearance-fix-20260925_vi.md) |
| Cấu trúc source, DLL/hook/inject | Có tài liệu kiểm toán:5 DLL SDK không tự build; có hook chẩn đoán; không thấy inject vào process khác trong Play đã khảo sát | [Kiểm toán](10-CAU-TRUC-VA-KIEM-TOAN-BUILD_vi.md) |
| ShadowFrameSkip/tối ưu cảnh | Đã phân tích rủi ro chất lượng/độ đều thời gian khung hình; chưa bật N 2/3 hoặc chứng minh tối ưu hoàn tất | Lịch sử câu trả lời 23/09; [perfCY](specs/render/perf-cy_vi.md) |

## 4. Sáu lựa chọn cường hóa được khôi phục đầy đủ

| Câu | Lựa chọn thật của người dùng | Hệ quả |
|---|---|---|
|1|A|Thay cách thao tác hệ cường hóa hiện có; giữ NPC/điểm mở|
|2|A|Giữ bảng tăng thuộc tính có sẵn|
|3|A, bổ sung “Dùng cả vàng và nguyên liệu”|Trừ phí khi bắt đầu mỗi lượt, thành công hay thất bại đều tiêu|
|4|C với mô tả “Giảm 1 cấp, mất lượt cường hoá”|Trượt giảm 1, sàn 0, kết thúc lượt|
|5|B|Thành công tự chuyển cấp tiếp, đến+9/thất bại/thiếu phí|
|6|A|Chạy qua lại đến khi người chơi bấm Space, không giới hạn thời gian chờ|

NPC được trả lời trong lịch sử: **Âu Dã Tử, Tô Châu(355,234), “Trang bị cường hóa”**. Địa chỉ cần đối chiếu lại nếu scene runtime thay đổi.

Các lựa chọn triển khai thêm đã báo trong kết quả: nonce/timing phía server; bấm giữ Space không lặp; hủy/đóng/rời cảnh/thoát trong lượt tính bỏ lượt; đồ cũ trên+9 giữ nguyên; ví theo thứ tự giao tử rồi vàng; vùng trắng 30→6%, thời gian một chiều 2,6→1,0 giây. Không gán các tham số này thành lời người dùng đã tự chỉ định. Challenge có dung sai mạng, chưa phải chống bot tuyệt đối.

## 5. Những kết luận cũ đã được thay thế

| Kết luận trước | Bổ sung sau phải dùng |
|---|---|
| Thiên cơ cẩm nang chưa có backend ở lượt Action | Đợt 2 triển khai kho 120 ô, có persistence |
| Cap 119, tự chiến đấu chưa có ở báo cáo đợt 2 | Đợt progression 24/09 đã cap 200 và auto thực; Thiên phú vẫn còn mở |
| Thăng Linh chưa có script/metadata ở lượt tooltip 16:42 | Equipcraft 18:38 bổ sung &W và sáu luồng; không nhầm với &SQ |
| Bay là hover cột 22 trong khảo sát cũ | Bay cao thực dùng cột 19/.fly/native 2242, sau đó bổ sung action và navmesh server |
| Preview VH đúng nghĩa là Wuhun đã có trên người | Audit chỉ ra chưa có; fix 25/09 sau đó mới nối world/SelfEquip/màn chọn nhân vật và huyễn hóa |
| Generic GUI run passed nghĩa là flight đạt | Probe hạ cánh live 01 vẫn FAIL; chỉ các lượt sau sửa mới đạt |

## 6. Các phần còn mở, không được báo đã xong

1. **Thiên phú:** cần chọn Tông môn CY hoặc Võ đạo GL và triển khai hệ còn thiếu; không có câu trả lời lựa chọn được tìm thấy trong lịch sử đến mốc chốt.
2. **Ngọc:** thiếu một số host/chữ ký/giao thức ghép và hệ ngọc nâng cao. Vá chống trừ phí sai không thay hoàn thiện end-to-end.
3. **Huyễn sức che thân:** cần đúng tổ hợp gây lỗi để xác minh đầy đủ; kiểm tra danh mục không phủ mọi tổ hợp render.
4. **Power:** 4 kinh mạch tiến giai chưa có hiệu quả server; Thú hồn chưa khóa từng dòng/màu.
5. **Flight:** chở đội chưa port; quỹ đạo/timing 2 giây chưa chứng minh bằng tuyệt đối native; chưa live hai client để chứng minh hình ảnh AOI.
6. **Auto:** Võ ý thiếu counter và chuỗi phó bản FB chưa hỗ trợ; chưa thử mọi phái/thú/kỹ năng.
7. **UI/equipment:** tên người khắc không có dữ liệu; profile/điểm và tên bang còn giới hạn; hai khung so sánh nhẫn/hộ phù, liên kết vật phẩm trong chat và mọi viền bậc cao chưa kiểm đầy đủ. Ngoại lệ Lưu Bác chưa xác định.
8. **Dữ liệu và hiệu năng:** nhãn shop/Pet còn ca cắt/chồng, minimap Võ Đang thiếu tài nguyên và scene queue overload là baseline còn tồn tại; không được gộp vào thành công của Wuhun/tooltip. Chưa chứng minh tối ưu nạp cảnh/độ đều thời gian khung hình hoàn tất.
9. **Phạm vi test:** thử trực tiếp cổng chỉ một số tuyến; danh mục kỹ năng không đồng nghĩa mọi skill đã chơi; unit test mọi cấp không là bấm trực tiếp mọi cấp. Những lỗi vận hành hệ chính quan sát trong báo cáo cũ phải kiểm lại nếu có nhiệm vụ riêng, không tự restart từ task CY.

## 7. Bản cuối trước yêu cầu tổng hợp

Theo [hồ sơ Wuhun 25/09](specs/client/wuhun-appearance-fix-20260925_vi.md), phát hành **08:50:19 ngày 25/09/2026** tại `Build/world-gui/stage-play-21/Play.cmd`, Game SHA256:

`65a7f3abb3bbaa8171c0d1ca72e448d9bae4581f8939e3fc2d98ee7a43c28e72`.

Hai lượt cuối `live-09` và `relogin-02`, gồm giao dịch thật, 36 model, world/SelfEquip/màn chọn nhân vật, chuyển Võ Đang→Đại Lý. Tiền 10 triệu→8.960.000, ba stack 100→50/50/98 trong fixture; khôi phục BSON chính xác cho test15. Backup `Build/backups/wuhun-appearance-play/20260925-085019`. Đây là provenance của bản đã xuất, không phải kiểm tra lại toàn bộ chức năng các ngày trước.

## 8. Các skill mới

Bản nguồn nằm trong `Tools/skills/`; bản cài để Codex phát hiện nằm trong `C:/Users/PC -Sam/.codex/skills/`. Các file `references/` chỉ nạp khi đúng nhánh công việc, tránh nhồi toàn hội thoại vào mọi lần sửa.

| Skill | Khi dùng | Bài học chính |
|---|---|---|
| [cys-build-release](../Tools/skills/cys-build-release/SKILL.md) | Build, candidate, publish, private server, audit/perf | Đúng binary/manifest, probe riêng, fixture, SDK/hook phân biệt, không bật frame skip mù |
| [cys-ui-repair](../Tools/skills/cys-ui-repair/SKILL.md) | CEGUI, layout, SelfEquip, nền ô/wheel/NPC/Alt | Renderer trước asset, generator, hit-testing, UTF-8 XML, di chuyển sau đóng |
| [cys-equipment-systems](../Tools/skills/cys-equipment-systems/SKILL.md) | Tooltip, nhịp rèn, Thăng Linh/điêu văn và power | Công thức server, metadata/GUID, thiết kế đã chốt, giới hạn các hệ |
| [cys-inventory-transactions](../Tools/skills/cys-inventory-transactions/SKILL.md) | Túi, kho phụ, loot, stack, phí/item | Revalidate sau yield, commit không yield, bảo toàn GUID/metadata |
| [cys-gameplay-state](../Tools/skills/cys-gameplay-state/SKILL.md) | Skill, combat, EXP/cấp, auto, phái, portal | Catalog khác learned, callback mục tiêu, state server, cap và Thiên phú không trộn |
| [cys-appearance-assets](../Tools/skills/cys-appearance-assets/SKILL.md) | Wuhun/huyễn hóa/wardrobe/model/import | Đúng namespace ID, KFSObj, closure, bảng nhị phân/mesh nguyên vẹn |
| [cys-mount-flight](../Tools/skills/cys-mount-flight/SKILL.md) | Bay cao mount và kiểm hạ cánh | Hover khác flight, native codec, .fly, action, đối chiếu navmesh server |

Không sửa hoặc thay thế skill GL/add-model/add-costume đang có. Không có skill nào tự cấp quyền GM, tự seed tài khoản, tự restart hoặc tự phát hành chỉ vì được nạp. Có thể gọi trực tiếp, ví dụ: `$cys-ui-repair sửa khung SelfEquip của CY-Source`, `$cys-inventory-transactions kiểm tra chống nhân đôi khi gộp đồ`.

## 9. Kết quả tạo và cài skill

- Đã tạo **7 skill, 11 tài liệu tham chiếu, tổng 25 file** gồm SKILL.md, references và agents/openai.yaml; mỗi skill có mô tả chọn tự động và câu gọi mẫu.
- Bộ `quick_validate.py` của skill-creator xác nhận cả bảy bản cài hợp lệ. Đã kiểm tra 94 liên kết Markdown trong gói skill và bản tổng hợp trước khi bổ sung mục kết quả này; không có liên kết thiếu.
- Toàn bộ 25 file cài tại thư mục skill Codex khớp SHA256 với bản nguồn trong dự án. Giữ chế độ tự chọn mặc định, không thay skill cũ.
- [Chỉ mục khôi phục lịch sử](../Build/Logs/2026-09-25-skills/history-index.json) ghi 34 mốc nén, 23 câu trả lời kết thúc và hash phần nhật ký đã đọc; không chứa snapshot mã hóa hoặc raw log công cụ.
- [Hồ sơ cài và kiểm tra](../Build/Logs/2026-09-25-skills/installed-skills.json) ghi tên skill, đường dẫn nguồn/bản cài, SHA256 và phạm vi rà soát. Đây là kiểm tra tài liệu/cấu trúc, không phải một lượt agent độc lập thực thi gameplay từ skill.
- Đọc lại hash Game.exe của Play xác nhận vẫn là bản `65a7f3ab…` ở mục 7. Tác vụ này chỉ tạo tài liệu/skill, không thay source game, dữ liệu tài khoản hoặc server.

Khi sửa skill về sau, sửa bản nguồn tương ứng trong `Tools/skills`, kiểm tra lại rồi đồng bộ đúng thư mục đã cài. Không sửa một bản và để bản còn lại khác nội dung mà không ghi nhận.
