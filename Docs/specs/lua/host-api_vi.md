# Lua host API — đợt P1-2

Ngày 12/09/2026. Adapter nằm trong `Src/Client/LuaApiGen/CysHostGlobals.*`; chỉ đăng ký vào ô `nil`, trước `LuaApiGen::RegisterAll`. Các hàm đã có của 0.85 hoặc bản triển khai khác giữ nguyên. Đợt đầu gồm Format, PushEvent và CloseWindow; đợt kế thêm SetTimer, KillTimer và ClearAllTimer qua `CysHostTimers.*`. Các hàm này trước đó chỉ có stub trong `LuaApiGen_Globals.cpp`.

| Hàm | Tham số → kết quả | Hành vi và bằng chứng |
|---|---|---|
| `OpenWindow` | `name:string/number` → 0 giá trị | Gate nLocalID 77 trước đọc đối số, phát OPEN_WINDOW; B `226850`/`218430`; [spec](login-remaining_vi.md). |
| `DataPool:GetProvincesNum` | → một số | Số tỉnh trong catalog thật; B `26e880`, loader `15f030`; [spec](login-remaining_vi.md). |
| `DataPool:EnumProvinces` | `index:number` → ID, tên UTF-8 | Thứ tự xuất hiện đầu, chỉ số không hợp lệ báo lỗi; B `26e970`; [spec](login-remaining_vi.md). |
| `DataPool:GetCityNumFromOneProvinceId` | `index:number` → số thành phố hoặc −1 | Đếm catalog của tỉnh thật; B `26eb50`; [spec](login-remaining_vi.md). |
| `DataPool:NumCityFromOneProvince` | `provinceIndex:number, cityIndex:number` → ID, tên | ID/tên thành phố thật, ngoài cận −1/rỗng; B `26ebd0`; [spec](login-remaining_vi.md). |
| `GetDictionaryString` | `key:string/number` → một chuỗi; kiểu khác → 0 giá trị | Tra dictionary thật rồi NoColor; B `227f60` → UI `4fbf0`, chỉ literal/`%%`, tối đa 2048 byte. Template cần varargs báo lỗi vì wrapper B không cấp đối số; [hợp đồng và kiểm thử](login-remaining_vi.md). |
| `DataPool:CreateActionItemForShow` | `tableId:number, count:number` → ActionButton userdata, isLocked | **Chưa triển khai:** regular Enable, cache count/max/tableId; B wrapper273110/factory164240; [spec/phụ thuộc DBC](display-items_vi.md). |
| `DataPool:CreateBindActionItemForShow` | `tableId:number, count:number` → ActionButton userdata, isLocked | **Chưa triển khai:** cache thêm bind-state1, giữ enable; wrapper273530/factory164500; [spec/phụ thuộc DBC](display-items_vi.md). |
| `PlayerPackage:GetItemTableIndex` | `index:number` → signed table ID, slot trống −1 | Query nguồn thật, truncate int32; B wrapper2a6db0/getter13b0c0/tableID50bf80. CY60/B240 slot; xem giới hạn bên dưới. |
| `DataPool:SetCanUseHotKey` | `value:number` → 0 giá trị; kiểu khác no-op | RVA26d540; gate gameplay thật, zero khóa/nonzero mở, hủy F-key prepare không thực thi. [Spec/24 ca thử](hotkeys_vi.md). |

`CysHostGlobals::Services` nối adapter với dịch vụ sự kiện và cửa sổ của game. Format có tham số thay thế không cần dịch vụ bên ngoài. Mỗi closure Lua giữ bản sao cấu hình callback; context thuộc bên gọi và phải sống tới khi Lua state kết thúc. Test đơn vị kiểm byte đầu ra Format và thay context bằng trạng thái có thể quan sát để kiểm tra thứ tự sự kiện, tác động đóng cửa sổ. Adapter không giả kết quả khi thiếu dịch vụ: lần gọi báo lỗi Lua rõ tên dịch vụ, không ghi nội dung tham số ra log.


Tên và tham số chuỗi của `PushEvent`/`CloseWindow` cũng đi qua biên C-string: phần sau NUL đầu tiên không chuyển vào dịch vụ. Bằng chứng `14022cde0.c` đếm byte tới NUL khi chép tên/tham số; `1402268c0.c` truyền `LuaStackObject::GetString` trực tiếp tới dịch vụ.


## Query item trong túi

`CysHostQueries.*` mở rộng metatable thật của global userdata PlayerPackage trước RegisterAll; chỉ điền nil, không tạo receiver giả hoặc thay method đã có. Callback Game dùng `CDataPool::UserBag_GetItem(index)` và `tObject_Item::GetIdTable`, không cấp phát item, không giữ pointer, không gửi packet. Descriptor callback được sao vào Lua closure; context thuộc game và phải sống đến khi LuaState kết thúc.

LuaPlus5.0 trả default metatable cho userdata ngay cả khi chưa gán riêng; Register so identity với default và từ chối trước khi thêm method, tránh sửa metatable chung. Ca lỗi này đã được phát hiện ở lượt đầu24/25 và kiểm lại25/25 sau sửa.

Lua arg2 phải NUMBER thật. Numeric string/sai kiểu báo Lua error cố định; extra args bị bỏ qua. Double truncate về int32, NaN/Inf/ngoài miền trả INT_MIN theo phòng vệ CY tương tự timer, không tái tạo FP flags/trap của B. Index âm/ngoài túi hoặc slot trống trả đúng1 number−1. Callback trả signed tableID, không dùng clientID/GUID/actionID. Lỗi service chuyển thành Lua error sau C++ unwind, không in payload lỗi.

**Giới hạn:** B getter hỗ trợ240 slot, CY `MAX_BAG_SIZE` là60. Adapter thực hiện đúng dữ liệu đang có ở0..59;60..239 trả−1 vì CY không có slot, không được tuyên bố B cũng trống. Không nâng bag/network ABI trong wrapper này. Dữ liệu hiện tại còn lỗi DBC riêng; query không chứng minh NewItem modern đã hoạt động.

Bằng chứng `Build/Logs/2026-09-12-gpt-p1-2/next-hosts/followup-plan_vi.md`; null sentinel double−1 từ RVA6e6240; getter bag13b0c0, tableID50bf80. Query đã25/25 ca PASS,0 cảnh báo,6/6 source hashes giữ nguyên; cùng snippet2→0 missing calls/1→0 dòng thiếu, kết quả10100001/−1. Log `Build/Logs/2026-09-12-gpt-p1-2/tests/queries/run-20260912-222544-2508840/{result.json,tests.log}`; CI tích hợp được ghi tại Timeline khi chốt phiên.

## Cấu trúc byte của Format

Gọi n là số tham số thay thế, L là độ dài C-string của template, S là tổng `2 + độ dài C-string của từng tham số`. Lua number được đổi sang chuỗi bằng Lua. C-string dừng tại NUL đầu tiên, kể cả khi Lua string còn byte phía sau.

| Thành phần | Nội dung |
|---|---|
| Tiền tố | L − 1 byte đầu của template; trường hợp thông thường `#{KEY}` bỏ dấu `}` cuối |
| Header | `*`, byte n, byte `(S + 3 + padding) mod 256` |
| Mỗi tham số | `*`, byte `argument_length mod 256`, toàn bộ byte C-string của tham số |
| Padding | Một dấu cách khi S = 56; các trường hợp khác không có |
| Kết thúc | `}`, NUL |

Ví dụ `ScriptGlobal_Format("#{K}", "Q")` có kết quả Lua dạng hex `23 7B 4B 2A 01 06 2A 01 51 7D`; NUL cuối không thuộc độ dài chuỗi Lua. Đây là vector kiểm thử tự tạo từ spec, không phải khung capture.

Biên C-string được giữ giống caller B: encoder xây toàn bộ representation rồi gọi `lua_pushstring`. Tham số rỗng tạo length byte 0 và kết quả Lua bị cắt ở đó. Length 256 cũng thành byte 0; block có `(S + 3 + padding) mod 256 = 0` bị cắt ở header. Length vượt 255 vẫn lấy modulo 256 khi toàn bộ buffer an toàn. Không tự sửa thành `lua_pushlstring` hay thêm escaping làm đổi representation.

Helper B nhận capacity nhưng không dùng nó; caller chỉ cấp 1.024 byte. CY kiểm tra trước khi đóng gói: template có C-string rỗng hoặc tổng encoded bytes cộng NUL lớn hơn 1.024 → lỗi Lua rõ ràng. CY không cắt chuỗi để vừa buffer và không mô phỏng ghi tràn bộ nhớ. Template không rỗng nhưng thiếu dấu `}` vẫn bỏ đúng byte cuối như B; không thêm điều kiện cú pháp mà helper không có. Nhánh chỉ truyền template không đi qua encoder nên chuỗi rỗng vẫn gửi sự kiện debug rồi trả 0 giá trị.

Giải từ điển và thay placeholder thuộc bước tiêu thụ UI. Dữ liệu `Assets/Canonical/Data/ConfigFolder/StrDictionary.txt:41577` dùng `%s324` (tham số 3 rồi chữ `24`), dòng 76168 dùng `%s30000` (tham số 3 rồi chữ `0000`); đây là bằng chứng index chiếm một ký tự, không phải số thập phân nhiều chữ số. Reader lịch sử còn nhận ký tự `a`…`f` như mô tả dưới đây. Không diễn giải tham số như chuỗi định dạng C.

## Decoder UI của CY


Reader lịch sử cung cấp thêm bằng chứng cụ thể:


`CysPackedFormat::Expand(input, resolver, context, output)` trả `Result { error, offset, expanded }`. Resolver trả boolean để phân biệt khóa thiếu với giá trị dictionary rỗng hợp lệ. `UIString.cpp:485` nối resolver vào dictionary nội bộ; `ParserString_RuntimeNew` gọi Expand tại dòng 531, trước `_CheckStringCode` tại dòng 540. Byte count/length vì thế được đọc trước khi kiểm UTF-8 hoặc GBK; decoder không chuyển encoding. Sau expansion, kiểm encoding, lọc nội dung, mã màu và parser dictionary/special key hiện có tiếp tục xử lý kết quả.

- Reader nhận `#{KEY*...}` với count 1–15; đọc từng marker `*`, unsigned length và đúng số byte argument có kiểm bounds. Không tìm dấu `}` bên trong argument để suy điểm kết thúc. Tổng S được tính từ các argument đã đọc rồi đối chiếu `blocklen == (S + 3 + padding) mod 256`; block tổng vượt 255 vẫn đọc được khi từng length còn đủ thông tin. S=56 bắt buộc đúng một dấu cách padding trước `}` cuối.
- CY tra KEY rồi thay token `%s0`…`%s9`, `%sa`…`%sf` một lượt trên template. Argument được chèn giữ nguyên byte và không bị thay token lần nữa. `%s10` được đọc là argument 1 rồi chữ `0`; `%%s0` được đọc là chữ `%` rồi argument 0. Index thiếu argument được giữ nguyên token. Ba hành vi token này khớp vòng thay token trong reader lịch sử; chữ hoa `A`…`F` không thuộc token index.
- Packed envelope lồng trong kết quả được expand trước khi kiểm encoding. Argument chứa `}`, plain `#{KEY}`, `%sN`, UTF-8 hoặc GBK không làm cắt nhầm biên ngoài. Plain `#{KEY}`, `#{_MONEY...}` và mã màu còn lại được giữ cho parser UI hiện có. `##` được tôn trọng như escape của UI; chuỗi không packed giữ nguyên từng byte.
- Resolver có mặt nhưng trả false vì không tìm thấy KEY thì consume đúng envelope đó và không emit text; các đoạn literal/envelope khác tiếp tục được xử lý. Resolver nullptr là thiếu dịch vụ: trả error enum `MissingKey`, tên log `missing-resolver`. Unknown key và placeholder thiếu argument không còn là lỗi transactional.
- Header lỗi giữ nguyên toàn bộ input, `expanded=0`, trả loại lỗi và offset trong input gốc; lỗi nested trỏ về đầu envelope ngoài. Lỗi gồm thiếu byte/footer, count/marker/length/padding sai, thiếu resolver hoặc vượt giới hạn. UI chỉ log loại lỗi và offset, không ghi nội dung key/argument, rồi chuyển input qua pipeline kiểm text hiện có. Vì pipeline đó có thể loại metadata hoặc không tạo text, không khẳng định rendering cuối của input lỗi giống reader B.

Giới hạn phòng vệ CY là `MaxDepth=16`, `MaxOutputBytes=1.048.576`, `MaxExpansions=4.096`. Giới hạn số expansion chặn cây đệ quy có output rỗng mà depth/output riêng chưa chặn được. Chuỗi plain không bị áp giới hạn output của decoder. Chu kỳ dictionary plain của parser UI cũ nằm ngoài giới hạn đệ quy packed trong một lần Expand.

Argument dài hơn 255 byte mất thông tin trong length một byte; reader không đoán số vòng wrap để lấy thêm payload. Byte NUL do argument rỗng, length modulo bằng 0 hoặc blocklen bằng 0 đã cắt chuỗi ở `lua_pushstring` của producer cũng không thể khôi phục. Reader báo lỗi khi thiếu byte, không tự bịa argument/footer. Header có thể đọc một chuỗi nhị phân đầy đủ với length=0, nhưng chuỗi đó không phải đầu ra nguyên vẹn đi qua biên C-string này. Không thể bảo đảm phát hiện mọi payload cố tình tạo ra một envelope ngắn hợp lệ, vì representation không có thông tin phân biệt.

Kiểm thử decoder/tích hợp LuaPlus thật → host → decoder: **34/34 PASS**, gồm golden bytes, total wrap 2×130, padding, UTF-8/GBK nguyên byte, brace/nested, token một lượt, `%sa`…`%sf`, `%%s0`, token thiếu/chữ hoa giữ nguyên, mixed/nested unknown key, resolver nullptr, lỗi transactional và các biên phòng vệ. Canonical qua LuaPlus/host/decoder trả đúng 44 byte văn bản. Fuzz cố định seed `1129927473`: **10.000 mẫu**, 4.677 nhận, 5.323 từ chối, 0 exception; đây là test dữ liệu, không phải runtime Game. Bằng chứng: `Tests/luaapi/packed_format_tests.cpp`, `Tests/luaapi/run_packed_format_tests.ps1`, log `Build/Logs/2026-09-12-gpt-p1-2/tests/packed/run-20260912-214216-9587793/tests.log`; báo cáo decoder `Build/Logs/2026-09-12-gpt-p1-2/packed-format/report_vi.md`.

## Phạm vi bằng chứng


Encoder và consumer CY đã có mã cùng unit test; hook consumer đã nối vào UIString. Bộ 34 test đã xác nhận 3 sửa semantics sau khi tìm thấy body reader lịch sử: `%sa`…`%sf`, giữ token thiếu argument, và chỉ bỏ envelope có unknown key. Kết quả này chưa chứng minh Game UI đã render đúng. Commit `ce93717` đã CI 33/33, smoke 6/6, checks 3/3, census 5 viewer không tăng (log `Build/Logs/ci/ce93717`); smoke Game hiện bị chặn bởi vấn đề font baseline đang chờ xử lý. Các khác biệt phòng ghi tràn/đầu vào rỗng, lỗi decoder và giới hạn phòng vệ nêu trên là lựa chọn rõ ràng của CY, không phải hành vi trả lỗi đã đo trên B.
