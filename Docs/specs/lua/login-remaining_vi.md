# Host đăng nhập còn thiếu: menu, cửa sổ, tỉnh/thành

Ngày 13/09/2026. Phạm vi mã và bằng chứng chỉ trong CY-Source. Người dùng đã yêu cầu sửa lỗi hiện có và kiểm nối WSL; phần này chỉ bổ sung host và thử cục bộ, không tạo tài khoản hoặc gửi thông tin đăng nhập. Tích hợp Game/WSL do phiên chính kiểm sau.

## Hành vi đã phục hồi

- `Talk:HideContexMenu4Speaker(...)` bỏ qua đối số, phát một `HIDE_CONTEXMENU_SPEAKER` không tham số, trả 0 giá trị. Giữ đối tượng Talk/metatable sẵn có; chỉ điền slot nil. Script ContexMenu tự quyết định đóng khi đang hiện, kiểu chat_private và menu speaker, không đóng tất cả cửa sổ.
- `OpenWindow(name)` kiểm cảnh hiện hành trước đọc đối số: có world, active scene và scene define với **nLocalID 77** thì trả 0 và không phát sự kiện. Thiếu world/scene/define thì không bị chặn. Nếu không bị chặn, nhận string/number theo biên Lua C-string và phát `OPEN_WINDOW(name)`, bỏ qua đối số thừa, trả 0. Không dùng nServerID thay nLocalID.
- `DataPool:GetProvincesNum()` trả đúng kích thước catalog tỉnh đang thuộc Game. `EnumProvinces(index)` trả ID liên tiếp từ 0 và tên tỉnh theo lần đầu xuất hiện; cùng tỉnh gom mọi dòng thành phố theo thứ tự nguồn. `GetCityNumFromOneProvinceId(index)` trả số thành phố hoặc -1 khi ngoài catalog. `NumCityFromOneProvince(index, cityIndex)` trả city ID/tên thật, hoặc -1/chuỗi rỗng khi không có dòng. Các hàm có index nhận NUMBER thật, cắt phần lẻ như cvttsd2si; không nhận numeric string.
- Catalog đọc một lần qua ResourceProvider khi đăng ký host, sở hữu các chuỗi UTF-8, tồn tại đến sau hủy Lua. Không đụng packet/DB server. Lỗi schema/đọc nguồn hiện ra, không thay bằng số 0. Bốn query được làm cùng vì GetProvincesNum dương khiến ChannelCustomization/ChannelSetFenping lập tức dùng EnumProvinces rồi truy vấn thành phố.
- Cầu nối ClickSound do UI agent bổ sung được Game gắn vào `CSoundSystemFMod::_PlayUISoundFunc` sau khởi tạo âm thanh và xóa trước teardown node. Không tạo liên kết Game trực tiếp với CEGUI.

## Bằng chứng tĩnh B


| Phần | Bằng chứng |
| --- | --- |
| Hide speaker | `341410..341430` phát event 1cc qua slot c8; registry `6cdc54..6cdc82` đặt tên HIDE_CONTEXMENU_SPEAKER. |
| Open window | `226850..2268ae` gọi gate 218430 trước GetString, chỉ khi false mới phát event 16b; registry `6ccc84..6cccb1` đặt OPEN_WINDOW. |
| Gate scene | `218430..218496`: global 9b70b0, slot 80, scene slot 0, so sánh DWORD đầu với 4d. Constructor `d8780` gọi tWorldSystem rồi gắn vtable 702fd8; slot 80 dẫn `e04b0` trả activeScene tại d358. Interface tScene slot0 là GetSceneDefine; DWORD đầu _DBC_SCENE_DEFINE là nLocalID. |
| Nguồn tỉnh/thành | Registry `126f19..126f31` gắn DBC de với chuỗi CityIdOfChina.txt tại 712310. Loader `15f030..15f47c` duyệt dòng, nhóm chuỗi ở offset10 của record x64 (cột3 province name), giữ lần đầu. Counter BSS 9b78fc khởi đầu 0, chỉ loader tăng. |
| Query | Count `26e880`, enum province `26e970..26eb40`, city count `26eb50..26ebc5`, city enum `26ebd0..26ed11`; city ID đọc offset4 (cột1), city name offset8 (cột2). Invalid city trả double -1 tại6e6240 và chuỗi rỗng76973b. |

B thiếu kiểm cận dưới ở vài lookup vector. CY trả lỗi EnumProvinces hoặc sentinel city cho chỉ số âm/NaN/Inf/int32 overflow, không tái tạo hành vi đọc trước bộ đệm. Gate được giữ; không coi mọi cảnh 77/77 server tương đương khi SceneDefine khác schema. Loader hiện tại đọc catalog một lần; chưa tái tạo việc reload và tăng counter toàn tiến trình của B.

## Profile dữ liệu được hỗ trợ

- Binary DBC magic DDBBCC00, đúng 5 cột `INT, INT, STRING, STRING, INT`; các cột là index dòng, city ID, city name, province name, flag. Kiểm kích thước, type, offset, NUL terminator; không overlay struct C++ lên byte tệp.
- TSV DBC legacy 4 cột `INT, STRING, STRING, INT` hoặc modern 5 cột như trên. Giữ hai dòng header, LF/CRLF, cho BOM UTF-8; dòng trống/comment `#` bỏ qua. Dòng dữ liệu phải đủ cột, số đúng int32. Không hỗ trợ quoted TSV.
- Giới hạn 2 MiB, 100.000 dòng, dòng TSV 32 KiB. Chuỗi nguồn chọn UTF-8 nếu cả khối hợp lệ, nếu không đọc CP936 hợp lệ rồi chuyển UTF-8. Không sửa byte nguồn. Tên rỗng/city ID trùng không bị xóa; thứ tự giữ nguyên. Flag chưa dùng để lọc, phù hợp loader B đã kiểm.
- Canonical binary UTF-8 có 35 tỉnh/340 thành; dữ liệu Reference trong stage cũ là TSV CP936 4 cột, cũng 35/340. Hai profile có kiểm riêng bằng đúng byte từ các tệp, không suy một dạng từ phần mở rộng .txt.

## Kiểm thử

- `Tests/luaapi/run_tests.ps1 -OutDir <Build/evidence> -Jobs 1`: **54/54**, gồm 40 ca trước và 14 ca mới cho OpenWindow/Talk. Kiểm gate trước type, dispatch thật, không giá trị trả về, C-string/UTF-8, descriptor theo LuaState, nil-only, thiếu dịch vụ/exception và receiver/meta identity.
- `Tests/luaapi/run_province_tests.ps1 -OutDir <Build/evidence> -ReferenceList <Build/city-input> -Jobs 1`: **29/29** với Canonical binary; chạy cùng exe với bản sao Reference TSV cũng **29/29**. 28 ca synthetic và 1 ca đọc catalog thật mỗi lượt; không cộng hai lượt thành 58 ca khác nhau. Kiểm parser malformed/giới hạn/type, encoding, nhóm cột đúng, quyền sở hữu chuỗi, số lượng/enum/Lua args/sentinels/lifetime/nil-only. Cùng đoạn Lua trước 1 missing call, sau 0 và lập được danh sách thật.
- Hai bộ build không có warning. 304 event ID có trước giữ nguyên, thêm GE_HIDE_CONTEXMENU_SPEAKER=304, GE_OPEN_WINDOW=305. Không báo runtime missing tổng bằng 0 từ unit.
- Evidence `Build/Logs/2026-09-13-gpt-login-remaining`: `globals-tests-2/result.json`, `province-tests-3/result.json`, `province-tests-3/reference-stage.log`, `event-id-comparison.json`, `reference-identity.json`. Giữ các lượt lỗi trước: globals-tests-1 53/54 (assert stack fixture), province-tests-1 reference-stage chưa hỗ trợ TSV, province-tests-2 timeout do lỗi helper Append lúc mở rộng TSV; đã sửa và kiểm lại ở lượt cuối. Không coi các lượt lỗi là PASS.
- CI và Game/WSL cần phiên chính kiểm sau khi tích hợp source các agent. Unit không chứng minh đăng nhập server, âm thanh nghe được, vào thế giới hay thao tác nhân vật.

## Theo dõi account transition và GetDictionaryString

Probe `Build/Logs/2026-09-13-gpt-wsl-ui/integration-b636cd0` dừng khi tải Reputation vì thiếu factory Falagard/MapImage. Đường kích hoạt là `Build/gpt-p1-1-20260913/stage-b636cd0/Data/Interface/LogOn/LogOn.lua:192`: GAMELOGIN_OPEN_COUNT_INPUT gọi `OpenWindow("SoftKeyBoard")`. Stage này đang dùng script legacy; bản Canonical LogOn đã comment lời gọi đó, nên không dùng Canonical để suy caller runtime. Reputation_PreLoad đăng ký OPEN_WINDOW; điều kiện `arg0=="Reputation"` nằm trong OnEvent, sau tải layout.

Đã kiểm cả dispatcher Game và callback UI B. `OPEN_WINDOW` là broadcast cho subscriber; không có lọc tên cửa sổ trước LoadWindow. Giữ nguyên routing CY, không thêm bypass Reputation hoặc giả lập factory:

| Đường B | Bằng chứng và ý nghĩa |
| --- | --- |
| Game OpenWindow `226850` | Phát event 16b qua virtual b8 của CEventSystem, vtable 7c7238 → `3d4650`; chuỗi arg0 giữ nguyên, gọi queue `3d9920` tại `3d492d`. Nhánh riêng 85 trong push-string chỉ xử lý màu, không áp dụng cho 16b. |
| Game `_ProcessEvent` `3d9a60` | Chỉ 136 (UI_COMMAND) có nhánh riêng; mọi event khác đi `3d9b9e..3d9bca`, duyệt tất cả cặp callback/owner. Không đọc arg0 để chọn layout. |
| UI RegisterEvent `58750` | Arg3 là boolean thì lấy giá trị; thiếu hoặc kiểu khác mặc định TRUE tại `587b7`. Lưu cờ theo event và đăng ký callback `59ef0`; đăng ký trùng không thay cờ. |
| UI `_OnGameEvent` `59ef0` | Cờ FALSE cùng cửa sổ chưa hiện thì bỏ qua. Cờ mặc định TRUE đi tiếp; nếu chưa nạp layout thì gọi `58bb0` tại `5a09e`, rồi mới đặt arg0… và gọi `%s_OnEvent` tại `5a190`. |

UI B SHA256 `344628121ed7068a45a70dd4bf6732f4c68d01916cbb3a226ae0d7be10e93f73`. Bằng chứng LLVM trong `Build/Logs/2026-09-13-gpt-login-remaining/{event-push-string,event-dispatch,window-register-event,window-event}.txt`. Kết luận chỉ xác nhận nguyên nhân tải Reputation; chưa chứng minh toàn bộ màn Reputation hoặc mọi cờ RegisterEvent đã được phục hồi trong CY.

`GetDictionaryString` thiếu sáu lần ở ContexMenu_OnLoad của probe trên. Hợp đồng B:

- Game wrapper `227f60` dùng lua_isstring(arg1): string và number được chuyển qua C-string, dừng ở NUL; nil/boolean/table/function/không đối số trả 0 giá trị. Bỏ qua mọi Lua arg2 trở đi. Kết quả lua_pushstring trả đúng một chuỗi, dừng ở NUL.
- UI virtual 148 → `4fbf0` là ParserString_NoColor_VarParam, không phải NoColor_NoVarParam. Helper `36b00` tra key đúng byte, missing trả rỗng; gọi `_vsnprintf` giới hạn 800 hex byte trên buffer đã zero 801 hex byte, sau đó NoColor `2ea90` với bControl=FALSE. Escape `%%` trở thành `%`; control như `#n` vẫn được giữ cho bước render.
- Wrapper Game không cấp C varargs. CY dùng `ParserString_NoVarParam` lấy template thật, định dạng zero-argument có giới hạn 2048 byte, rồi `ParserString_NoColor(..., FALSE)`. Các template có conversion cần đối số (`%s`, `%d`, `%n`, width `*`…) hoặc format sai báo Luaerror rõ. Đây là chặn hành vi đọc varargs không được cấp của B, không tự lấy Lua arg2 làm tham số và không trả rỗng che lỗi. Quét toàn template đến NUL để kiểm format, kể cả phần vượt giới hạn đầu ra.
- Native NoColor được gọi qua service UI thật; host không chứa bảng từ điển hay bộ bỏ mã màu riêng. Phạm vi màu phụ thuộc parser UI hiện có; không tuyên bố các expansion phức tạp `#{_INFOUSR...}`/`#{_INFOID...}` của B đã hoàn tất.
- Năm key hiện cần: Tip_PVP_Peace (hai lần), Tip_PVP_Moral, Tip_PVP_FreeForAll, Tip_PVP_FreeForTeam, TM_20080311_16. Corpus Canonical UTF-8 hiện có đủ, giá trị đều literal và không chứa `%`/`#`. Host không thay mã hóa key hoặc chuẩn hóa Unicode; display value do loader dictionary chọn profile UTF-8/936.


Kết quả `Tests/luaapi/run_tests.ps1 -OutDir Build/Logs/2026-09-13-gpt-login-remaining/dictionary-host-tests-2 -Jobs 1`: **67/67 PASS**, build/run exit 0, không warning; cùng sáu lời gọi từ corpus giảm missing 6→0, kiểm đủ sáu kết quả. Lượt `dictionary-host-tests-1` build fail do windows.h đặt macro GetMessage xung đột với LuaException::GetMessage trong test runner; đã undef tại include boundary và giữ log lỗi. Chưa chạy Game sau tích hợp host này; không suy kết nối WSL hoặc hết lỗi runtime từ unit. Hash source, corpus và DLL LuaPlus trong `dictionary-host-source-identity.json` cùng thư mục bằng chứng.

## ComboBox SetCurrentSelect: kiểm cận trước chọn item

Probe `Build/Logs/2026-09-13-gpt-wsl-ui/integration-2a05b22` đã đi qua account transition. Một lỗi Listbox xuất hiện sau dòng tải xong ZhengyouSearch.layout.xml và trước PlayerZhengyou.layout.xml. Nguyên nhân nằm trong `Build/gpt-p1-1-20260913/stage-2a05b22/Data/Interface/ZhengyouSearch/ZhengyouSearch.lua:71`: OnLoad → OnInitDialog thêm item MenPai rồi gọi SetCurrentSelect(10) **bên trong vòng lặp**. Ngay lượt đầu count=1, index=10. PlayerZhengyou_OnLoad chỉ đặt tiêu đề; không truy cập Listbox. CY gọi getListboxItemFromIndex thẳng nên ném lỗi, làm dở phần tạo các combo tiếp theo.

B UI_CEGUI `21b40..21be1` đã kiểm đủ: lua_type(arg2)==NUMBER tại `21b58`, cvttsd2si tại `21b6f`, âm trả 0, so index với getItemCount tại `21b7e..21b87`, chỉ khi hợp lệ và item khác null mới setItemSelectState rồi setText(item text). Mọi nhánh trả 0 giá trị Lua. Với script stage, mười lượt đầu chưa đủ item được bỏ qua; lượt thứ 11 chọn index10 có thật. Không tìm bằng item ID, không clamp index và không xóa selection/text cũ ở nhánh ngoài cận.

Sửa duy nhất host `Src/Client/CEGUISystem/UILuaControl.cpp`: khôi phục kiểm kiểu và cận đó; số hữu hạn truncate về int32 không âm (−0,5 → 0), NaN/Inf/overflow trả 0 trước cast. Giữ nguyên core Listbox và Lua stage; không bắt rồi nuốt exception. Canonical ZhengyouSearch khác stage (MenPai là cặp text/ID và SetCurrentSelect(0) sau vòng lặp); không thay script để che thiếu hợp đồng host.


Chưa build hoặc chạy riêng sau hunk này. Phiên chính sẽ kiểm CI, widget suite và đúng script stage trong Game: lỗi Listbox 1→0, list MenPai đủ11 item rồi chọn index10, các combo còn lại được khởi tạo. Không tạo helper hay test phản chiếu phép kiểm cận đơn giản; không báo PASS trước khi có bằng chứng runtime.
