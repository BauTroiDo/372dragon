# Kiểm tra nhiệm vụ, chế tạo, giám định, tâm pháp và thuộc tính — 27/09/2026

> Đây là mốc kiểm tra/phát hành đầu tiên ngày 27/09. Đợt tiếp theo đã sửa đăng ký sư môn, nhóm thưởng, khôi phục Lua chế tạo và dữ liệu còn thiếu; xem [báo cáo tiếp nối và trạng thái mới](gameplay-completion-20260927_vi.md). Các con số và mục tồn đọng bên dưới giữ nguyên để truy vết mốc đầu, không thay thế trạng thái mới.

## Phạm vi và trạng thái

Mã nguồn client CY-Source và server riêng `/home/ubuntu/cys-test-20260913`, cổng 15733/15734. Không sửa server chính, client GL hoặc snapshot WSL. Nguồn đối chiếu: bảng CY, callback Lua hiện có, server thật và nguồn CY/HJ tại `Tools/DATA NEW`. Chưa thể xác nhận mọi nhiệm vụ/công thức hay cân bằng toàn bộ PvP chỉ từ các kiểm tra dưới đây.

Đã phát hành phần sửa được kiểm chứng vào `Build/world-gui/stage-play-21/Play.cmd`. Server riêng đang chạy 20 file trong `staged-final/manifest.json`. Hai lượt GUI cuối đều đạt; tài khoản thử đã được phục hồi đầy đủ. Các lượt thất bại được giữ nguyên trong thư mục bằng chứng.

## Những lỗi đã sửa trong nguồn

### Nhiệm vụ

- Request nhận/tiếp tục/nộp/kiểm tra nhiệm vụ cần người chơi còn sống và NPC thật trong bán kính tương tác 5. Giữ nguyên danh sách script được NPC cho phép; khóa request của cùng người chơi qua các lần yield.
- Nhiệm vụ Đại Lý 1407 trước đây cấp cả năm phần thưởng lựa chọn. Nay chỉ cấp món được chọn và từ chối lựa chọn không hợp lệ.
- Nhiệm vụ 1414 trước đây tạo trân thú trước khi thêm nhiệm vụ. Nay kiểm tra điều kiện, thêm nhiệm vụ trước; lỗi tạo thú thì xóa nhiệm vụ vừa thêm. Không cấp trùng khi nhận lại hoặc nhật ký đầy.
- `script_base.add_item_list` từng dùng chung giữa mọi người gọi một script. Nay danh sách thưởng tách theo coroutine, tránh ghi đè khi các lượt đọc config/cấp GUID chạy xen kẽ; điều chỉnh cả lệnh xóa danh sách trong webcall.
- Chưa biến mọi callback nhiệm vụ thành giao dịch nguyên tử: nhiều script tự xóa nhiệm vụ/cộng tiền/EXP rồi mới gọi cấp vật phẩm. Việc túi hoặc nhân vật đổi trạng thái trong callback phức tạp còn cần kiểm từng nhóm.

### Chế tạo và giám định

- Nối packet kỹ năng sống, công thức, lò chế tạo, tiến trình, thành công/thất bại giữa protocol CY và client; yêu cầu danh sách kỹ năng sống khi vào thế giới.
- Sửa iterator sau khi thêm kỹ năng sống; bỏ qua định nghĩa DBC không tồn tại, tránh dereference sai.
- Khôi phục thông tin nhóm công thức, cấp nghề, năng lượng, nguyên liệu đặc biệt, số lượt có thể làm. Số lượt tối đa tính theo nguyên liệu cho mỗi lần thực hiện, không chia thêm cho số sản phẩm đầu ra.
- Sửa tìm lò ở các ô lân cận và so sánh bình phương khoảng cách với bình phương bán kính. Đối chiếu lò thật tại Đại Lý CY `(216,110)`.
- Chế tạo thường của đúc/may/chế nghệ/gia công kiểm nghề đã học, công thức, cấp, thành thục, dụng cụ, nguyên liệu đúng vùng túi, vật phẩm khóa, năng lượng và chỗ trống.
- Tạo đầu ra bằng item factory hiện có trước khi trừ nguyên liệu; kiểm lại identity/số lượng/operation sau các lần yield. Giữ metadata khi chồng, giữ trạng thái ràng buộc theo nguyên liệu, giữ người chế tạo và thông tin thủ công. Chặn lặp lần hoàn tất.
- Công thức gọi script không có AbilityCheck/AbilityProduce bị từ chối trước tiêu hao. Không bắt buộc AbilityConsume vì một số script gốc tiêu hao ngay trong AbilityProduce.
- Giám định dùng danh sách 105 cuộn và giới hạn cấp đọc từ mô tả CommonItem; không suy giới hạn bằng phép chia ID. Kiểm đúng vũ khí/áo giáp/trang sức, cấp, khóa, trạng thái sống, số lượng và item sau config yield. Chỉ tiêu hao một cuộn khi thành công.
- Client biểu diễn EquipBase bằng cấu trúc trắng để tương thích layout. Sửa điều kiện giám định/equip để phẩm chất thật từ EquipBase và bit trạng thái máy chủ quyết định; không dùng nhãn WHITE_EQUIP nội bộ để coi đồ xanh là đã giám định.
- Chuột phải vào cuộn giám định phải chuyển sang con trỏ chọn trang bị trong nhánh DoAction_Packet; nhánh cũ chỉ xử lý ở DoSubAction. Máy chủ từ chối mặc món cần giám định nhưng chưa giám định, trước khi gắn trạng thái ràng buộc; kiểm lại đúng item sau đọc config.
- Thuộc tính chưa có của nghề trả nil cho Lua; trước đây trả lại chuỗi tên trường, làm cửa sổ Synthesize so sánh chuỗi với số và lỗi.

### Học tâm pháp

- Giữ phí trong XinFa/StudySpeed hiện tại; khóa yêu cầu trong lúc đọc config, kiểm lại nhân vật, môn phái, tâm pháp và cấp sau yield.
- Client giữ đúng cấp tâm pháp trong lần xác nhận; không tự thay cấp cũ bằng cấp mới trong cache, tránh biến xác nhận cũ thành lần mua tiếp theo.
- Chặn yêu cầu cũ gửi lại; tâm pháp không vượt cấp nhân vật +5. Bảng tâm pháp hiện có tối đa 119, không tự suy lên 200 từ giới hạn cấp nhân vật.
- Chỉ mở kỹ năng khi đạt đúng yêu cầu tâm pháp trong SkillTemplate. Cả lúc thi triển cũng kiểm điều kiện này cho nhân vật cũ đã lưu chiêu được mở sớm; giữ nhánh bỏ qua điều kiện dành cho tác động nội bộ.
- Làm mới cache thuộc tính sau học tâm pháp để hệ số tu luyện phụ thuộc tâm pháp được tính lại.

### Băng, hỏa, huyền, độc

- Sửa kháng cộng thêm bị đưa nhầm sang giảm kháng của người đánh: cộng về phía người chịu đòn.
- Sửa sáu kênh ngoại/nội/băng/hỏa/huyền/độc: phần tăng sát thương trừ phần giảm sát thương được phép âm, chặn thấp nhất -100%; trước đây ép về 0 khiến giảm sát thương mất tác dụng khi cao hơn phần tăng.
- Kiểm tra hệ số tiến giai khác 0 trước phép chia. Giữ cách tính giới hạn kháng âm và hệ số đặc trưng theo bảng gốc.

## Hệ số thuộc tính đang dùng

Giá trị dưới là hệ số nhân AttackTraits, chưa bao gồm kỹ năng, trang bị, giảm kháng, hội tâm, tốc độ đánh hay hiệu ứng. Các phái có chỉ số bằng nhau không có nghĩa DPS thực bằng nhau. Giữ ánh xạ môn phái CY sang dòng AttackTraits của server; không dùng trực tiếp ID giống số nhưng khác nhánh.

| Môn phái | Băng | Hỏa | Huyền | Độc |
|---|---:|---:|---:|---:|
| Thiếu Lâm | 1 | 1 | 1.5 | 1 |
| Minh Giáo | 1 | 1.5 | 1 | 1 |
| Cái Bang | 1 | 1.25 | 1 | 1.3 |
| Võ Đang | 1.25 | 1.2 | 1.1 | 1 |
| Nga Mi | 1.2 | 1 | 1.25 | 1 |
| Tinh Túc | 1 | 1 | 1 | 1.5 |
| Đại Lý / Thiên Long | 1.15 | 1.15 | 1.15 | 1.15 |
| Thiên Sơn | 1.5 | 1 | 1 | 1 |
| Tiêu Dao | 1 | 1.3 | 1 | 1.25 |
| Không môn phái | 0.2 | 0.2 | 0.2 | 0.2 |
| Mộ Dung | 1 | 1 | 1.5 | 1 |
| Đường Môn | 1 | 1 | 1.3 | 1.3 |
| Quỷ Cốc | 1 | 1.2 | 1.3 | 1 |
| Đào Hoa Đảo | 1.3 | 1 | 1 | 1.2 |
| Tuyệt Tình Cốc | 1 | 1.3 | 1.2 | 1 |
| Ác Nhân Cốc | 1.25 | 1 | 1 | 1.3 |

Với mỗi kênh: sát thương cơ sở = (công thuộc tính + công thêm của kỹ năng) × hệ số phái × (100 − kháng hiệu lực)/100; bằng 0 nếu kháng hiệu lực ≥100. Kháng hiệu lực là kháng cộng thêm trừ giảm kháng, có chặn dưới theo giới hạn âm/tiến giai đang có. Sau đó áp dụng tăng/giảm sát thương. Các bước dao động, impact và hệ phái khác vẫn theo luồng chiến đấu hiện có.

Không tuyên bố toàn bộ phái đã cân bằng PvP: cần bộ đo theo cùng ngân sách trang bị, cấp tâm pháp, mục tiêu, nhiều lượt ngẫu nhiên; ghi DPS, thời gian hạ mục tiêu, hồi phục, miễn sát thương và thời lượng khống chế. Bản sửa này khôi phục tác dụng phòng thủ đúng công thức, không tự sửa hàng loạt hệ số để các phái giống nhau.

## Dữ liệu chưa đủ hoặc chưa được chứng minh hoạt động

Quét 3.866 script Lua: không có lỗi cú pháp. Phát hiện 358 script có callback nhiệm vụ, trong đó 324 có OnSubmit và 165 có CheckSubmit. Đây là kiểm kê tĩnh, không phải 358 chuỗi đã chơi hết.

Có 11 script nhiệm vụ chưa đăng ký. Tám script sư môn được NPC tham chiếu nhưng không được nạp: 229001–229008. Ba mục còn lại gồm bản Bak/bản trùng và script phụ bản cũ; không đăng ký tự động chỉ vì có file. Trong một số script sư môn cũ còn dùng `if GetMissionParam(...,0)` với số 0 trong Lua và `if not ...` để đếm quái: phải sửa/kiểm đầy đủ trước khi bật lại để không phát thưởng sai hoặc không đếm tiến độ.

Có 1.639 công thức; 475 dòng có phụ thuộc cần đối chiếu. Các nhóm chồng lấp, không được cộng số lượng dưới thành tổng lỗi:

- 190 dòng tham chiếu script chưa đăng ký: 791130 (102), 505020 (48), 700959 (14), 700900 (12), 700960 (9), 700901 (3), 505023 (2).
- 145 dòng ghi đầu ra không tìm được trong bảng item hiện tại, gồm 109 công thức thường và các dòng đặc thù khác.
- 212 dòng dùng đầu ra phụ thuộc script: đây không tự động là lỗi.
- 37 dòng không có nghề tương ứng, gồm 19 dòng placeholder -1 và 18 dòng hệ nghề khác.
- 7 dòng có nguyên liệu placeholder 21000000.
- Kiểm thêm 494 công thức thường đủ item/nguyên liệu của 5 nghề: 452 công thức tạo đúng đầu ra và trừ đúng nguyên liệu; 42 công thức yêu cầu cấp nghề chưa có trong bảng AbilityLevelUp, bị từ chối và không mất nguyên liệu. Danh sách: `recipe-level-gaps.json`. Đây cũng là các nhóm có thể chồng lấp, không cộng vào 475 để suy tổng lỗi.
- Một công thức đòi cống hiến chưa có xử lý trừ điểm đầy đủ bị chặn, không miễn phí ngầm.

Đã tìm được Lua CY cũ của 700900/700901/700959/700960 trong `Tools/DATA NEW/DataCY31-08-26/tlbb15/Public/Data/Script/event/peifang`. Đây là API global cũ, cần port sang script class/transaction hiện tại; không thể chép thẳng rồi coi như đã chạy. Các ID 505020/791130 xuất hiện trong registry HJ nhưng chưa tìm thấy thân Lua tương ứng trong pack đã khảo sát. Chưa tự đặt xác suất hoặc đầu ra thay thế.

Giao diện chế tạo hiện còn một số nhãn/tên dài bị cắt, danh mục tiếng Trung và tooltip nguyên liệu có hàm host chưa nối. Không coi việc tạo được một món là toàn bộ UI/nhánh chế tạo đã hoàn tất.

615 mẫu kỹ năng môn phái đã đối chiếu: không có liên kết tâm pháp hay SkillData tương ứng bị thiếu trong nhóm này. Không đồng nghĩa toàn bộ combo/thiên phú/hiệu ứng đã được đo cân bằng.

## Bằng chứng và kiểm tra

Thư mục bằng chứng: `Build/Logs/2026-09-26-quest-craft-combat`.

- `handler-tests.txt`: 978 ca đạt, dùng config thật và handler thật; actor, transport, một số dịch vụ và cấp item được mô phỏng. Gồm các biên giám định/chế tạo, request nhiệm vụ, 494 công thức thường, 320 tổ hợp phái × thuộc tính × mức kháng (cả công thêm của kỹ năng, kháng thêm và giới hạn giảm kháng) và 32 ca giảm sát thương ngoại/nội.
- `quest-tests.txt`: 149 ca đạt cho 20 callback trả nhiệm vụ Đại Lý và nhận nhiệm vụ trân thú; điều kiện mục tiêu thế giới được tách bằng mock. Không thay cho chơi toàn tuyến.
- `reward-batch-tests.txt`: 9 kiểm tra đạt, chạy hai actor xen kẽ tại chờ kiểm túi/cấp item bằng chính các phương thức script_base.
- `sect-tests.txt`: 1.472 ca đạt, gồm 106 sách, 120 tâm pháp trong bảng, mở chiêu và 436 trường hợp điều kiện thi triển theo handler thật.
- `data-audit.json`: kiểm kê script, nhiệm vụ, recipe, hệ số và liên kết kỹ năng; giữ nguyên baseline để so sánh.
- `staged-final/manifest.json`: 20 file server, hash trước/sau; backup gốc đầu tiên `Build/backups/gameplay-audit-server/20260927-001551`, bản áp dụng cuối `20260927-011826`.
- Fixture test15/GUID 200016 có backup toàn BSON của đợt này, phục hồi và kiểm equality khi kết thúc. Không dùng fixture để sửa tài khoản người chơi khác.

Các lượt GUI 01–10 có thất bại và được giữ lại: lần lượt phát hiện field nghề trả sai kiểu, lò chưa qua protocol, tọa độ lò của bản đồ cũ, vị trí không đi được, lớp trang bị trắng nội bộ che trạng thái giám định, dữ liệu chi tiết chưa về khi mới vào túi, sai nhánh chuột phải, và client tự đổi cấp trong xác nhận học tâm pháp cũ. Bit 16 là thông tin người chế tạo, không phải bit giám định (bit 2). Nhận định tạm thời rằng output tự giám định đã bị bác bỏ bằng mã ItemRule/define và packet thật.

## Kiểm tra trực tiếp trong game

Lượt `live13` đạt toàn bộ 24 điều kiện, thoát game bằng CGAskQuit, không crash hay lỗi handler/Lua. Đi đến NPC Bồ Lương `(219,123)` bằng đường đi thật, mở đối thoại, chọn trả nhiệm vụ 1401, nhận nhiệm vụ 1402; log có `passed=2 failed=0`. Sau đó đi tới lò, bấm Make trong Synthesize, chuột phải quyển giám định và chọn trang bị, gửi yêu cầu học tâm pháp và gửi lặp xác nhận cũ, đóng túi rồi tiếp tục di chuyển. Probe chỉ bật bằng biến môi trường trên tài khoản test15.

Đối chiếu Mongo sau khi thoát game (`fixture-verified.json`):

- 10200011 ×1, status 16: trang bị vừa chế tạo, chưa giám định.
- 10200001 ×1, status 18: món kiểm tra đã giám định, có bit 2.
- Cuộn 30506001 còn 1; nguyên liệu còn 25/10/12/1 theo đúng một lượt.
- Phần thưởng nhiệm vụ: 10101000 ×1 và 30101001 ×10; chín GUID trong túi không trùng.
- Tâm pháp 1 lên cấp 2; EXP 1.000.673 = 1.000.000 +700 −27. Tổng tiền 999.991 = 1.000.000 +1 −10; hoạt lực 480.

Lượt `live11` đã đạt trước khi bổ sung đi bộ tới NPC trong probe. Lượt `live12` nhận/trả nhiệm vụ đạt nhưng bước thử chế tạo chờ đi bộ chỉ 6 giây nên thất bại; probe được đổi sang chờ nhân vật thực sự đến lò, tối đa 45 giây. Đây là chỉnh thời gian kiểm thử, không dịch chuyển nhân vật bằng GM hoặc bỏ kiểm khoảng cách trên máy chủ.

## Phát hành và phục hồi dữ liệu

- Build Release x64 từ mã nguồn; Game.exe SHA-256: `0021980a2bfbf875640b0a960dadc253a0b81a2c00ce00adca9be5e4ec44e349`.
- `live13`: 24/24 điều kiện đạt, gồm nhận/trả thưởng nhiệm vụ và chế tạo–giám định–tâm pháp–di chuyển.
- `live14-relogin`: 22/22 điều kiện đạt; nhận lại trạng thái item đã giám định, trang bị chế tạo, số cuộn, nguyên liệu và tâm pháp sau đăng nhập lại. Đối chiếu Mongo lần nữa giữ đúng mọi số lượng, GUID và chi phí.
- `fixture-restore.json`: phục hồi nguyên BSON test15, so sánh toàn bộ document bằng bản sao gốc, đạt.
- Phát hành lúc `20260927-013451`; sao lưu bản Play trước thay đổi tại `C:/TLBB/085/CY-Source/Build/backups/gameplay-audit-play/20260927-013451`. Chỉ cập nhật Game.exe/PDB, manifest và dòng xóa biến probe trong launcher; kiểm lại 37 bản ghi binary/PDB, Overlay/Patch không đổi.
- Tổng 2.608 kiểm tra Lua đạt (978 giao dịch/chế tạo/giám định/sát thương, 149 nhiệm vụ, 9 cô lập danh sách thưởng, 1.472 tâm pháp/kỹ năng). Không coi tổng này là số nhiệm vụ đã chơi trong thế giới.
- Giữ báo cáo những phụ thuộc chưa hoàn thiện ở trên; chưa nghiệm thu tất cả nhiệm vụ/công thức hoặc cân bằng toàn bộ PvP.
