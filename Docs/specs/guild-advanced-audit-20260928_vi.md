# Kiểm tra bang hội mở rộng — 28/09/2026

**Kết quả: chưa đủ chức năng để xác nhận nâng cấp bang, kết minh, bang chiến, chạy thương và quản trị thành thị hoạt động hoàn chỉnh.** Đợt sửa party/bang hội trước mới xác nhận các luồng tạo bang, xin gia nhập, xét duyệt, bổ nhiệm, đổi tôn chỉ và rời bang. Các kết quả đó không đại diện cho những hệ thống trong báo cáo này.

Phạm vi lần này là đối chiếu mã client CY, Lua giao diện CY có sẵn, mã và bảng dữ liệu của server riêng `/home/ubuntu/cys-test-20260913`, rồi chạy các ca tái hiện lỗi với đối tượng giả lập. Không sửa dữ liệu tài khoản, không khởi động lại server, không thay binary hoặc overlay Play. **Chưa phát hành bản sửa các chức năng mở rộng trong đợt khảo sát này.**

## Trạng thái từng hệ thống

| Hệ thống | Phần đã có trong mã | Phần thiếu hoặc sai đã xác định |
|---|---|---|
| Nâng cấp bang/công trình | Có `CityInfo.txt`, `CityBuilding.txt`, dữ liệu cấp bang, công trình mặc định và menu kiến thiết/nghiên cứu của NPC | Các host `City:DoBuilding`, `DoResearch`, `AskCityManageInfo` còn là hàm khung. `CityGetBuildingLevel()` luôn trả 1; `CitySetLevel` và `CityBuildingChange` được NPC gọi nhưng không có định nghĩa trong `GameServer/lualib/script_base.lua`. Chưa có đủ chuỗi kiểm điều kiện → trừ tài nguyên → nâng cấp → lưu → cập nhật giao diện. |
| Kết minh | Có collection `leagues`, mã lập/xin vào/duyệt/rời/khai trừ và các packet tương ứng | Các host `GuildLeague` của client hiện nằm trong bộ hàm khung; cầu nối bang cơ bản chưa triển khai chúng. Server còn lỗi bang không tồn tại, đếm cả đơn chờ và chọn bang đang chờ làm minh chủ kế nhiệm. Giới hạn chưa thống nhất: manager cho 30 bang nhưng agent chỉ gửi 3 bang và UI CY ghi `/3`. |
| Bang chiến/tuyên chiến ngoài trời | Có danh sách tuyên chiến/chấp nhận, bộ đếm thời gian, thông báo, cảnh chiến trường và quan hệ thù địch trong logic nhân vật | Client `City` còn thiếu host gửi/đọc thật. Server trừ 100 mở rộng trước một số bước kiểm tra; cho thêm trùng mục tiêu; người gửi không tồn tại có thể gây lỗi Lua; đơn chưa được chấp nhận không đi qua bộ đếm hết hạn. Không được suy từ mã quan hệ PvP rằng cả chuỗi chiến trường, điểm số và thưởng đã được kiểm thử. |
| Thương nhân/chạy thương | Có vai trò thương nhân, NPC chủ quản, vật phẩm ngân phiếu `40002000`, mã lĩnh/trả phiếu và menu tuyến thương mại | Thiếu quỹ vẫn tiếp tục cấp phiếu; truyền sai thứ tự tham số ghi tiền lên phiếu; cộng tiền/EXP/tài nguyên bang trước khi biết xóa phiếu thành công. Dải cấp lĩnh phiếu có khoảng hở 69, 84 và từ 100 trở lên, không phù hợp giới hạn nhân vật 200 hiện tại. Client tuyến đường/cửa hàng thành thị vẫn là hàm khung. |
| Thành thị bang | Có cấp phát thành trống, tạo cảnh, sinh công trình, lưu `city`, cập nhật quyền sở hữu, hoàn tác khi tạo cảnh/thu phí thất bại | Giao diện quản trị/xây dựng/nghiên cứu/tuyến thương mại chưa nối đầy đủ. Hai luồng đọc quỹ dùng `founded_money` và `money`, nên có thể hiển thị có tiền nhưng NPC đọc bằng 0. Phí lập thành còn dùng mã tiền/giao tử cũ và cần đối chiếu lại quy ước Võ Thạch; chưa có kiểm thử giao diện thành thị và vào lại sau restart trong đợt này. |

## Những lỗi đã chạy tái hiện

Chạy trực tiếp hàm của manager và hàm sự kiện NPC đang có trên server, thay RPC, database và nhân vật bằng đối tượng trong bộ nhớ. Không gửi packet tới máy chủ đang chạy. Nhãn `CONFIRMED` trong log có nghĩa **đã tái hiện lỗi**, không phải tính năng đạt kiểm thử.

| Mã | Ca tái hiện | Kết quả quan sát |
|---|---|---|
| WAR-01 | Bang chúng thường yêu cầu tuyên chiến | Không có cuộc chiến mới nhưng điểm mở rộng giảm 500 → 400. |
| WAR-02 | Bang chủ chọn bang đích không tồn tại | Điểm mở rộng vẫn giảm 500 → 400. |
| WAR-03 | Bang chủ gửi hai yêu cầu tới cùng bang | Hai mục chiến tranh trùng nhau, điểm mở rộng giảm 500 → 300. |
| WAR-04 | GUID gửi yêu cầu không thuộc bang | Phát sinh lỗi Lua khi truy cập `operator.position`. |
| WAR-05 | Đơn thách chiến chưa được chấp nhận đã quá thời hạn | Đơn không bị xóa vì bộ đếm chỉ chạy sau điều kiện chấp nhận/cảnh. |
| LEAGUE-01 | Đọc thông tin liên minh không tồn tại | Phát sinh lỗi Lua do đọc bảng `nil`. |
| LEAGUE-02 | Một bang đã được nhận, một bang còn chờ | Danh sách công khai báo có 2 bang. |
| LEAGUE-03 | Minh chủ rời liên minh chỉ còn một đơn chờ | Chức minh chủ chuyển sang bang chưa được nhận; bang đó vẫn có `confederate_id = -1`. |
| CITY-01 | Bản ghi có `founded_money = 10000000`, chưa có `money` | Hàm `city_get_attr(1, 7)` trả 0. |
| TRADE-01 | Nhân vật cấp 60 lĩnh phiếu khi quỹ bằng 0 | NPC báo thiếu quỹ rồi vẫn đi tới thao tác thêm phiếu. |
| TRADE-02 | Ghi vốn và mục tiêu vào ngân phiếu | Tham số `value` nhận chuỗi kiểu dữ liệu; tham số `vtype` nhận số tiền. |
| TRADE-03 | Trả phiếu đủ giá trị nhưng xóa item thất bại | Phiếu còn nguyên, vẫn cộng 15.000 tiền, 20.000 EXP và gọi cộng tài nguyên bang. |

Lần chạy đầu bị lỗi ở thiết lập class giả lập của bộ kiểm tra sau 9 ca. Đã sửa thiết lập đó; lần chạy thứ hai tái hiện đủ 12 ca. Cả hai log được giữ lại. Không diễn giải lần chạy đầu thành lỗi gameplay mới.

## Bằng chứng mã nguồn

- Client: `Src/Client/LuaApiGen/LuaApiGen_City.cpp` có 51 host sinh dạng `Stub`; `LuaApiGen_GuildLeague.cpp` có 48 host dạng `Stub`. Đây là số hàm khung trong hai receiver, không phải số lỗi gameplay độc lập.
- `Src/Client/WXClient/Network/CysGuildNet.cpp` mới xử lý packet bang cơ bản và dữ liệu thành viên/thông tin bang; không có triển khai host `City` hoặc `GuildLeague` tương ứng với các menu nâng cao.
- Lua CY gốc: `Assets/CanonicalCY/Data/InterfaceFolder/GuildLeague/`, `NewBangHui_Tmxx/` và các khung thành thị gọi những host trên. Có Lua/layout không đồng nghĩa host đã làm được việc.
- Server `GameServer/services/guild/guildmanager_core.lua`: `guild_wild_war` trừ phí trước kiểm tra mục tiêu/quyền; nhánh phát hiện mục tiêu trùng không có hành động từ chối; `guild_league_quit` chọn phần tử đầu mà không lọc `join_date`; `get_guild_league_list` đếm cả đơn chờ.
- Server `GameServer/msgagent_module/ma_guild.lua`: thông tin liên minh chỉ lấy phần tử 1–3; thông tin bang đọc `founded_money`.
- Server `GameServer/services/msgagent.lua`: chức năng thành thị/bang chiến dùng `CGCGWPacket`, **khác với** `CGGuild` của bang cơ bản. Không quy lỗi tất cả chức năng nâng cao cho whitelist `CGGuild`.
- Server `GameServer/lualib/script_base.lua`: `CityGetBuildingLevel` trả hằng 1; chữ ký ghi tham số vật phẩm là `SetBagItemParam(selfId, bag_index, start, value, vtype, update)`.
- NPC `Game_2/Script/scripts/obj/city/pc_guilddirector.lua`: nhánh 16 thiếu `return` sau báo thiếu quỹ và đảo `value/vtype`; nhánh 17 trả thưởng trước `DelItem`.
- `GameServer/lualib/dynamicscenemanager_core.lua` đã có khóa khi cấp phát thành, tạo công trình mặc định, tạo cảnh và `release_city`. Do đó không đánh đồng thành thị với hoàn toàn chưa có backend.
- `GameServer/services/scene/obj/human.lua` đã xét quan hệ bang chiến trong PvP, sau điều kiện bản đồ/cấp. Cần giữ các điều kiện bảo vệ này khi nối bang chiến.

## Công việc cần hoàn thiện và điều kiện nghiệm thu

1. **Quỹ bang và giao dịch thương nhân:** thống nhất nguồn quỹ và đơn vị Võ Thạch; xác thực chức vụ/vị trí NPC; kiểm tra và giữ chỗ tài nguyên trước khi nhường xử lý; lĩnh phiếu chỉ một lần; trả phiếu chỉ thưởng một lần; lưu trạng thái phục hồi nếu một bước liên dịch vụ lỗi. Không chỉ đổi thứ tự hai lệnh rồi gọi đó là giao dịch an toàn. Thử thiếu quỹ, đầy túi, click đôi, chuyển/xóa phiếu, mất kết nối và đăng nhập lại.
2. **Kết minh:** nối host/packet/dữ liệu vào các khung CY có sẵn; thống nhất giới hạn có căn cứ từ phiên bản được chọn; chỉ minh chủ có quyền duyệt/khai trừ; chỉ bang đã được duyệt được kế nhiệm; đồng bộ tên/ID cho thành viên online và offline. Thử ít nhất hai bang và một đơn chờ, có lưu–nạp lại.
3. **Bang chiến:** kiểm quyền, mục tiêu, quan hệ đồng minh, số trận và phí tại manager trước khi thay trạng thái; chống yêu cầu trùng; quy định hết hạn cho lời mời; đồng bộ hai phía; xác nhận PvP chỉ trong điều kiện cho phép. Thử tuyên chiến/chấp nhận/hết hạn/chuyển cảnh/đăng nhập lại/điểm số/kết thúc/thưởng với hai phía.
4. **Thành thị và nâng cấp:** phục hồi luồng quản trị/xây dựng/nghiên cứu theo dữ liệu CY, nối packet còn thiếu, đọc đúng cấp thực tế, kiểm yêu cầu và chi phí trên server, lưu cấp/công trình và cập nhật hình ảnh. Thử bang không sở hữu thành, thiếu quỹ, đang xây, yêu cầu trùng, lỗi tạo cảnh và khởi động lại.
5. **Nghiệm thu bản Play:** dùng candidate, kiểm thao tác UI thật và di chuyển sau đóng khung; đối chiếu đúng binary/manifest; sao lưu và phục hồi toàn bộ nhân vật, bang, liên minh và thành bị tác động. Chỉ ghi hoàn tất khi có bằng chứng cho từng luồng.

## Tái chạy và hồ sơ

Các công cụ chỉ đọc source và chạy đối tượng giả lập:

```powershell
& 'C:/Program Files/Python313/python.exe' -X utf8 Tools/server/audit_guild_advanced.py
wsl -d TLBB -u root -- lua /mnt/c/TLBB/085/CY-Source/Tools/server/audit_guild_advanced.lua /home/ubuntu/cys-test-20260913
```

- Kiểm kê/hash: `Build/Logs/2026-09-28-guild-advanced/source-audit.json`.
- Log đầy đủ 12 ca: `Build/Logs/2026-09-28-guild-advanced/reproductions-2.txt`.
- Log lần thiết lập đầu: `Build/Logs/2026-09-28-guild-advanced/reproductions.txt`.
- Công cụ: `Tools/server/audit_guild_advanced.py` và `Tools/server/audit_guild_advanced.lua`.

Đây là báo cáo trạng thái và bộ tái hiện lỗi. Không phải biên bản nghiệm thu gameplay hay xác nhận đã sửa/phát hành.
