# Factory item xem trước — contract và phụ thuộc còn chặn

Ngày 12/09/2026, P1-2. Hai factory vẫn là stub; tài liệu này không xác nhận đã tạo được item/action hoặc giảm missing calls. Phân tích tĩnh dùng bản sao `Build/re/luaapi/gpt-p1-2-helpers/inputs/Game.exe`, SHA-256 `0bf344935d6266ab80b6807d048fcd59184a925f18fd292072ccc596d045c918`; không chạy binary tham chiếu.

| Hàm | Tham số → kết quả | RVA Game.exe |
|---|---|---|
| DataPool:CreateActionItemForShow | tableId:number, count:number → ActionButton userdata, isLocked:boolean | wrapper273110, factory164240 |
| DataPool:CreateBindActionItemForShow | tableId:number, count:number → ActionButton userdata, isLocked:boolean | wrapper273530, factory164500 |
| DataPool:ClearActionItemForShow | không tham số → không giá trị | wrapper273bb0, backend164810 |

Lua arg2/arg3 phải là NUMBER thật, không nhận numeric string; B báo lỗi native khi sai kiểu. Giá trị double bị truncate về int32; wrapper truyền thêm max=1. Factory trả null thì wrapper trả userdata trỏ invalid action tĩnh cùng false, không trả nil. Có action thì boolean lấy từ item thật qua IsLocked, không phải success hoặc bind. Wrapper thường gọi Enable; wrapper Bind giữ trạng thái enable hiện tại.

Chứng cứ: `Build/re/luaapi/decomp/Game.exe/{140273110,140273530,140273bb0}.c`; RTTI, caller và disassembly bổ sung trong `Build/Logs/2026-09-12-gpt-p1-2/action-items/factory-followup_vi.md`.

## Cache và sở hữu

- CDataPool giữ một vector item chung. Cache thường khớp count/max/tableId; cache Bind cần thêm bind-state bằng1. Nhánh thường không loại item đã bind.
- Item mới do CItemSystem quản lý. Chỉ gán count nếu khác0, gán max, owner preview; nhánh Bind còn cập nhật metadata bind và helper riêng cho equipment. Điền lỗ null đầu tiên hoặc nối cuối vector.
- CActionSystem tạo/cập nhật action và giữ map action. GetImpl tìm item theo client ID; Lua userdata mượn action, không sở hữu item/action.
- Clear hủy item, đặt slot cache null rồi dọn action không còn impl. Dung lượng vector giữ nguyên. Userdata cũ có thể còn giữ pointer action đã hủy; chưa chốt được kỷ luật caller hoặc cơ chế vô hiệu hóa phía B. Không thêm Lua GC xóa borrowed action.

Các target đã xác minh: CItemSystem New/Destroy/Find=431120/4314b0/431550; CActionSystem Update/Get/Clean=1e9270/1eac30/1ebc50. Hai batch Ghidra tuần tự đều4/4 PASS, read-only/noanalysis, heap3GB: `Build/re/luaapi/gpt-p1-2-factories/decomp` và `gpt-p1-2-item-lifetime/decomp`.

Enable được đối chiếu bằng named IsEnable wrapper1dfb90 (+80 đọc, +88 ghi1, +90 ghi0), cùng CreateActionItemForShowDisable273320. IsLocked được đối chiếu bằng LifeAbility.Lock_Packet_ItemByID299fc0: setter+100 ghi byte+21, getter+108 đọc đúng byte này. Không suy tên chỉ từ offset. Bind getter+120 có trạng thái0/1/2/3; helper equipment424fb0 chưa phục hồi đủ để triển khai.

## Phụ thuộc DBC đã đo

Khảo sát đọc byte có kiểm biên, không overlay C++ lên dữ liệu: `Build/Logs/2026-09-12-gpt-p1-2/action-items/{data-compatibility_vi.md,data-compatibility.json}`. Sáu bảng item và một bảng rule hiện tại cho **5 BAD, 2 PREFIX**. Bốn file `.txt` thực chất binary; checker cũ đọc dòng văn bản đầu và báo LONG giả với1 cột.

| Bảng | Cột thật | Record / struct x64 (byte) | Phát hiện |
|---|---:|---:|---|
| WhiteEquipBase | 93 | 400 /368 | pointer name/desc/icon trúng cột INT |
| GreenEquipBase | 93 | 400 /368 | pointer name/desc/icon trúng cột INT |
| BlueEquipBase | 91 | 392 /368 | pointer name/desc/icon trúng cột INT |
| CommonItem | 27 | 128 /104 | nRule đọc giá bán; nPileCount đọc rule |
| GemInfo | 81 | 352 /328 | attr lệch; pointer màu/type-desc trúng INT |
| StoreMapItem | 15 | 80 /56 | prefix đúng loại/offset, chỉ1 record |
| ItemRule | 14 | 56 /40 | prefix10 cột khớp, còn4 cột chưa dùng |

CommonItem: 9.694/10.093 dòng đọc rule khác cột đúng,29 dòng đọc ra rule không tồn tại; rule đúng không thiếu. 9.692 dòng đọc pile khác cột đúng. NewItem có nhánh trả null sau allocation khi thiếu rule; đây là rủi ro từ source, chưa đo leak runtime.

Tập literal của hai factory: 73 callsite/50 ID; chỉ35 ID có trong đúng bảng mà NewItem0.85 tra. Hai ID10142701/10142702 ở EquipBase.txt, nhưng mapping cũ chỉ mở White/Green/BlueEquipBase. Còn13 ID3992… chưa tìm thấy trong phạm vi bảng đã kiểm. Không coi toàn bộ525 lượt gọi tĩnh là literal hoặc runtime, không tạo row giả cho ID thiếu.

## Hai phương án tiếp theo

1. **Khuyến nghị: sửa phụ thuộc DBC trước.** Checker phải đọc binary/text đúng; chốt loại, offset và ý nghĩa từng field từ bảng/B; xác định mapping EquipBase modern; sau đó sửa adapter/record nguồn, build mọi consumer và kiểm item/action thật. Không chỉ sửa padding hoặc nRule rồi coi cả object an toàn.
2. Reader riêng cho item xem trước: đọc cột có kiểu, đưa vào record production có sở hữu rõ rồi action thật. Cần kiểm riêng name/icon/rule/bind/tooltip và userdata sau clear; không dùng Lua table giả hoặc trả thành công hằng. Hướng này không chứng minh NewItem0.85 đã tương thích.

Hiện chặn việc nối trực tiếp factory vào NewItem. Checker đã31/31 ca PASS; CLI61 bảng Canonical rc0/INVALID0,4 binary có93/93/91/15 cột thật. Bảy bảng item/rule vẫn5 BAD/2 PREFIX; không sửa dữ liệu để đổi kết quả. Evidence `Build/Logs/2026-09-12-gpt-p1-2/action-items/schema-tests-20260912-222614-257644/result.json` và `schema-final/canonical-layout.tsv`. Đã chuyển query túi độc lập theo mục4.7 rồi tạm dừng theo yêu cầu người dùng. Chưa sửa bảng Canonical, cấu trúc item, mapping database hoặc lifetime action. Phạm vi sửa DBC tiếp theo cần được chốt bằng schema có chứng cứ; không tự mở rộng sang server hoặc dữ liệu client của người dùng.

## Kiểm thử còn cần trước khi nhận DoD factory

Ca Lua phải dùng ActionButton metatable và item/action production; có name/icon/count/rule từ dữ liệu thật, invalid ID, cache reuse thường/Bind, count0, lock true/false, Enable khác nhau, cleanup và handle cũ. Mock backend chỉ chứng minh thuật toán, chưa đủ chứng minh factory UI. Mỗi ca giữ counter trước/sau, lỗi Lua, log; CI mọi consumer và smoke không thêm lỗi. Chưa có kết quả PASS của các ca này.
