# Sửa tiếp nhiệm vụ, chế tạo và kiểm tra tâm pháp — 27/09/2026

Phạm vi: tiếp nối [đợt kiểm tra trước](quest-crafting-xinfa-elements-20260927_vi.md) theo yêu cầu “sửa tất cả các vấn đề”. Đích chạy là CY-Source và server riêng `/home/ubuntu/cys-test-20260913`; không sửa client_GL, CanonicalCY, snapshot WSL hay server gốc. Các nhánh thiếu thân script hoặc dữ liệu gốc được ghi rõ ở cuối; tài liệu này không xác nhận mọi nhiệm vụ trong game đã chơi hết.

### Nhiệm vụ sư môn và vật phẩm mục tiêu

- Đăng ký lại tám script sư môn 229001–229008; dùng chung lớp sửa cho cả chín phái cổ điển, kể cả Thiếu Lâm 229000 vốn đã được nạp.
- Sửa điều kiện số 0 trong Lua, điều kiện vật phẩm khóa, chọn trang bị/trân thú khi trả nhiệm vụ, tên đích giao thư/khai quang, đếm quái đúng mục tiêu của từng thành viên tổ đội và chặn callback khi không sở hữu nhiệm vụ.
- Giữ các mốc số quái và tỷ lệ rơi theo Lua nguồn; cấp trên mốc cuối dùng mốc cuối đã có, không tự tạo hệ số mới cho cấp 200.
- Bỏ dùng biến thư chung của NPC giữa các người chơi; lấy đủ tên/ID/mô tả vật phẩm từ API.
- Tiêu hao vật phẩm kiểm đủ tổng số lượng trước khi trừ. Hỗ trợ trang bị đơn chiếc, vật phẩm nhiều chồng và nhóm nguyên liệu thay thế; không trừ một phần rồi mới báo thiếu. Hủy nhiệm vụ thu thập chỉ xóa số vật phẩm mục tiêu thực sự đang có.

### Phần thưởng nhiệm vụ

`cys_script_reward.lua` chuẩn bị toàn bộ đối tượng vật phẩm/GUID trước khi `EndAddItem` báo thành công, kiểm chung chỗ trống của cả phần thưởng, rồi ghi các ô vào túi trong một lượt không gọi dịch vụ cấp GUID. Chỉ gộp các chồng có metadata tương thích; giới hạn 250, trạng thái khóa, ràng buộc và thời hạn đều được xét. Danh sách vẫn tách theo coroutine của người gọi như bản sửa trước.

Trước khi ghi, so lại đối tượng và toàn bộ dữ liệu của các chồng đích để không ghi đè một món vừa thay đổi. Gửi lặp sau khi đã nhận không cấp thêm. Nhánh bỏ qua fatigue cũng dùng cùng cơ chế này. Giữ đúng chế độ sinh vật phẩm 0, 1 và 116 tại các nơi gọi đã đối chiếu.

Các callback Đại Lý `edali_newquest_003/004/007/008/009/015/020` và `edali_zhidao_0200` kiểm kết quả cấp vật phẩm trước khi đổi tiền/EXP và xóa nhiệm vụ. Nhiệm vụ 1401 xác nhận nhân vật còn nhiệm vụ và ID phần thưởng thực sự nằm trong lựa chọn, tránh hoàn thành nhiệm vụ mà mất vũ khí khi gửi lựa chọn sai.

Đây là giao dịch cấp **nhóm vật phẩm**; không phải một cơ chế rollback toàn bộ mọi callback Lua. Các script sự kiện khác còn có thể gọi dịch vụ riêng giữa những thay đổi trạng thái. Không suy diễn kiểm thử nhóm thưởng thành bảo đảm tuyệt đối toàn bộ giao dịch của mọi sự kiện.

### Chế tạo theo Lua CY gốc

Đọc thân Lua đầy đủ trong `Tools/DATA NEW/DataCY31-08-26/tlbb15/Public/Data/Script/event/peifang`, không dùng các file Config/event chỉ có metadata làm nội dung thực thi:

| Script | Nội dung khôi phục |
|---|---|
| 700900 | 9 khai báo dược phẩm/thức ăn, nhóm nguyên liệu, nghề hỗ trợ, mức tiêu hao, xác suất và đầu ra phụ theo mã gốc |
| 700901 | 3 công thức sơ chế nguyên liệu thức ăn |
| 700959 | 14 công thức chuyển đổi nhóm nguyên liệu |
| 700960 | 9 công thức may trang phục với chi phí và điều kiện gốc |

Tổng 35 khai báo; bảng runtime có thêm ba ID 213–215 tham chiếu 700900 nhưng không có khai báo tương ứng trong thân Lua tìm được. Không thay bằng một công thức phỏng đoán.

Các kế hoạch nhiều đầu ra được chuẩn bị đủ trước khi trừ nguyên liệu/hoạt lực. Kiểm lại nghề, thao tác, vật phẩm, số lượng và nghề hỗ trợ sau các lời gọi có thể nhường luồng. Nguyên liệu hoặc chỗ trống thay đổi thì từ chối; không cấp một phần đầu ra, không trừ phí một phần. Nghề chuyển đổi nguyên liệu 49 được nối vào handler chế tạo thực sự.

Khôi phục 144 định nghĩa còn thiếu từ HJ: 82 trang bị và 62 vật phẩm thường. Server giữ nguyên byte GBK của tiêu đề/cột; client chuyển đúng schema CY 103/28 cột. Đồng bộ 1.639 công thức và 77 nghề giữa hai phía, giữ tên dịch có sẵn khi xác nhận cùng định danh nghề. Các icon mới có namespace `CysCraft`, dùng bitmap/imageset gốc; không ghi đè icon đang dùng.

Đã chạy chính `item_operator:gen_item`, `item` và các bảng thật cho cả 144 định nghĩa, mỗi loại ba lần. GUID service và transport được mô phỏng; kiểm tra này xác nhận sinh dữ liệu/thuộc tính được, chưa chứng minh mọi script sử dụng vật phẩm hay model ngoại hình đi kèm đều hoàn chỉnh.

### Giao diện chế tạo

- Nối host tooltip và icon nguyên liệu qua factory vật phẩm của client để lấy đúng tên, loại và icon cho các phẩm chất.
- `ListBox:GetItemNumber` trả số dòng thực tế.
- Mở rộng khung cục bộ; tách dòng tên và dòng số lượng nguyên liệu để không cắt `50/25` thành `0/25`; hiện số thật thay ký hiệu vô cực khi lớn hơn 99.
- Tạo ô nguyên liệu thứ năm, nối vòng lặp/tooltip đã có API hỗ trợ; hiện bảng runtime không có công thức thường dùng cột nguyên liệu thứ năm, nên không ghi nhận một ca chế tạo năm nguyên liệu trực tiếp.
- Nới nút Làm/Đóng, giữ cây điều khiển và phong cách tài nguyên có sẵn. Không dùng adapter co giãn toàn giao diện.

## Bằng chứng kiểm thử

Thư mục: `Build/Logs/2026-09-27-gameplay-completion`.

| Bộ kiểm tra | Kết quả | Phạm vi |
|---|---:|---|
| `handler-tests-06.txt` | 1.079 đạt | Giao dịch, giám định, chế tạo, công thức sát thương; 494 công thức thường được khảo sát và 85 trường hợp nhóm nguyên liệu Lua khôi phục |
| `shimen-tests-02.txt` | 216 đạt | Callback chín sư môn, trạng thái nhiệm vụ, vật phẩm, nhóm quái và các mốc cấp |
| `quest-rewards-02.txt` | 174 đạt | Callback nhiệm vụ Đại Lý, lựa chọn thưởng, gửi lặp, túi đầy và nhóm thưởng không còn hợp lệ |
| `item-reward-02.txt` | 144 + 20 đạt | Sinh vật phẩm bằng operator thật; phát thưởng nhóm, metadata, GUID, hai actor xen kẽ và từ chối trước ghi |
| `sect-tests-final.txt` | 1.472 đạt | 106 sách, tâm pháp, handler học và điều kiện sử dụng kỹ năng |
| `pvp-traits-final.json` | đạt | 96 hệ số theo kênh, 640 hệ số cơ bản và 16 ánh xạ phái khớp CY nguồn |
| `lua-syntax-final.json` | 30 file, 0 lỗi | Mỗi file Lua server được kiểm riêng bằng luac5.4 |

Tổng 3.105 kiểm tra nêu trên không phải 3.105 nhiệm vụ hoặc ca PvP trong thế giới. Bộ handler dùng config/handler thật cùng actor/dịch vụ mô phỏng; các mốc kiểm tra độc lập có phần phạm vi chồng lấp.

Các lượt thất bại được giữ nguyên: `live01` phát hiện Expat từ chối `encoding="utf8"` (đã đổi `utf-8`); `live02` kết nối trước khi server nạp xong scene; `live05-materials` phát hiện probe dùng cú pháp `#` không có trong LuaPlus 5.0 (đã dùng `string.len`). `live03` và `live04-relogin` đạt trên bản trung gian. `live06-final` và `live07-final-relogin` cũng đạt trên bản trước khi sửa bộ đếm của probe. `live08-final-materials` tạo đúng sản phẩm (packet và BSON đều đúng), nhưng phép kiểm tra chỉ quét ngăn đồ 0–99 nên báo thiếu nguyên liệu ở ngăn 100–199; đã đổi sang bộ đếm toàn túi của client. Không dùng lượt trung gian làm bằng chứng phát hành bản cuối.

## Những phần chưa đủ nguồn hoặc chưa nghiệm thu toàn bộ

- Chưa có thân Lua của 505020 (48 tham chiếu), 791130 (102) và 505023 (2) trong các bộ nguồn đã khảo sát. Tên trong registry không đủ để khôi phục thuật toán tạo trang bị hoặc xác suất.
- Chưa có định nghĩa vật phẩm 39920139; nhóm nguyên liệu cấp 11 của công thức 406 tham chiếu 20107020 cũng không có trong các bảng tham khảo đã tìm. Giữ từ chối trước khi trừ đồ, không đổi sang ID gần giống.
- Ba công thức 213–215 và các công thức nghề cấp 11–12 chưa có khai báo/bảng phí gốc tương ứng. Trong 494 công thức thường đã thử, 452 tạo được và 42 bị chặn do thiếu cấp nghề. Không tự đặt phí hoặc cho qua miễn phí.
- Các placeholder nghề `-1`, nguyên liệu `21000000` và công thức 563 cần trừ cống hiến nhưng chưa có quy tắc trừ đầy đủ vẫn cần nội dung nguồn. Không coi placeholder là nội dung hoạt động.
- Những vật phẩm vừa bổ sung còn có liên kết script/skill/model riêng; đã lưu danh sách tại `data-recovery.json`, chưa đồng nghĩa mọi thao tác sử dụng chúng đã thử.
- Chưa chơi hết tất cả chuỗi nhiệm vụ/phụ bản trong thế giới. Đã sửa và kiểm các luồng dùng chung cùng các nhóm nêu rõ ở trên.
- Băng/hỏa/huyền/độc đã qua các ca công thức và đối chiếu hệ số gốc. Chưa có đo DPS, thời gian hạ mục tiêu, hồi phục và khống chế cho toàn bộ cặp phái với cùng ngân sách trang bị; chưa thể nghiệm thu cân bằng PvP toàn bộ.

## Triển khai

Manifest hiện tại có 32 file server (30 Lua, 2 bảng) và 45 tài nguyên client được xuất vào cả Pre/Post. Backup server trước lần áp dụng cuối: `Build/backups/gameplay-completion-server/20260927-223715`. Bản candidate build Release x64 có Game.exe SHA-256 `9ff397422642bc4c2c046f8c275fc2a6069d4a0c870f6d495eb87793145e0229`.

Đã phát hành lúc **22:59:05 ngày 27/09/2026** vào `Build/world-gui/stage-play-21/Play.cmd`. Backup Play: `Build/backups/gameplay-completion-play/20260927-225905`. Tool phát hành đối chiếu toàn bộ 37 mục binary/PDB cùng các overlay trong manifest; chỉ chấp nhận bằng chứng đúng hash Game và đúng hash manifest candidate.

Bốn lượt cuối cùng cùng hash `9ff397422642bc4c2c046f8c275fc2a6069d4a0c870f6d495eb87793145e0229` và cùng manifest candidate:

| Lượt GUI | Điều kiện đạt | Nội dung |
|---|---:|---|
| `live10-materials` | 22/22 | Mở khung nghề 49, chọn công thức 399, bấm Làm, nhận sản phẩm, đóng khung và đi bộ |
| `live11-materials-relogin` | 22/22 | Đăng nhập lại, lượng nguyên liệu/sản phẩm và GUID giữ đúng |
| `live12-quests-craft` | 24/24 | Đi tới Bồ Lương, trả 1401/nhận 1402, đi tới lò, chế tạo, giám định, học tâm pháp và gửi lặp xác nhận cũ |
| `live13-quests-craft-relogin` | 22/22 | Đăng nhập lại kiểm trang bị, giám định, cuộn, nguyên liệu, tâm pháp và di chuyển |

Tổng 90 điều kiện GUI đạt; cả bốn thoát bằng giao thức, không crash, không lỗi handler hoặc Lua liên quan đến luồng thử. Ảnh cuối `live12-quests-craft/cys-gl-12291562-craft-recipe-materials.png` đã kiểm trực quan: số 50/25, 20/10, 24/12, 2/1 hiện đầy đủ; ô nguyên liệu không dùng được ẩn.

BSON sau chuỗi nhiệm vụ/chế tạo có chín GUID khác nhau; trang bị mới 10200011 chưa giám định, 10200001 đã giám định, cuộn 30506001 còn một. Nguyên liệu còn 25/10/12/1, tâm pháp 1 ở cấp 2, EXP 1.000.673, tổng tiền 999.991, hoạt lực 480. Chuyển đổi 399 để lại 20103037 ×1 và 20103061 ×1 với hai GUID khác nhau; kiểm lại sau đăng nhập vẫn đúng.

`fixture-restore.json` xác nhận phục hồi toàn bộ document test15/GUID 200016 và so sánh bằng bản BSON gốc của đợt này. `server-status-release.json` xác nhận sáu tiến trình riêng chạy, không trùng, cổng 15733/15734 đang nghe. Log không có traceback hay lỗi chuẩn bị nhóm thưởng; vẫn còn cảnh báo baseline về script 402043/808041/888088 chưa nạp và hàng đợi/bộ nhớ, không được coi là đã sửa trong đợt này. `completion-summary.json` và `release-report.json` lưu kết quả tổng hợp.
