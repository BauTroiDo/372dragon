# Profile tạo và chọn nhân vật gốc DATA CY

## Nguồn và phạm vi

Theo yêu cầu người dùng ngày 13/09/2026, profile dùng đúng bố cục gốc tại `../Tools/DATA NEW/DataCY31-08-26/Interface`: CreateRole có **96** điều khiển, SelectRole có **50** điều khiển. `Tools/ui/create_role_layout.py` đọc XML này, giữ nguyên tên, thứ tự, cha/con, geometry, art và toàn bộ callback. Chỉ đổi namespace tài nguyên, font Noto, một số nhãn hiển thị và giới hạn ô tên. Không dựng panel thay thế, không thay banner chữ Trung Quốc bằng MeshBack, không bật GLResponsive.

Lua CY có header mã hóa. Hai controller `Tools/ui/templates/CysCreateRole.lua` và `CysSelectRole.lua` là mã CY-Source mới; workflow tham khảo Lua GL plaintext ở `Assets/Canonical/Data/InterfaceFolder` (đã đối chiếu byte với Client GL). Không nhận là đã giải mã hay phục hồi nguyên Lua CY. Manifest lưu hash bốn tệp S2 gốc cùng hash hai tệp GL tham khảo.

Mọi nguồn bên ngoài CY-Source chỉ đọc. `Tools/data/prepare_create_role_profile.py` chỉ ghi dưới `Build`, kế thừa một stage GL riêng. Sáu tệp LogOn, SelectServer, SoftKeyBoard giữ nguyên bytes và hash. StrFilter giữ hai header, không có dòng luật; Noto và TSGame.ico không nằm trong tập ghi.

## Bố cục và đường hiển thị

CreateRole giữ dải 15 nút xem trước môn phái bên trái, bảng giới tính/mặt/tóc/trang phục bên phải, lưới chân dung **3×3 có phân trang**, tên/gợi ý tên và các nút xoay/zoom dưới nhân vật. Màn xem trước dùng nguyên Info2_Frame và nút hủy; chế độ tạo dùng Info_Frame/Info3_Frame. Chân dung có 15 lựa chọn mỗi giới tính, trang cuối chỉ ẩn ba ô không có dữ liệu.

SelectRole giữ ba thẻ nhân vật bên phải và các nút Vào game/Tạo/Xóa/Quay lại đúng vị trí gốc. XML gốc không có MeshWindow cho nhân vật; profile không thêm cửa sổ RTT vào đó. Native chịu trách nhiệm cảnh và nhân vật 3D thật. CreateRole_Model vẫn thuộc cây gốc nhưng controller unhook `SetFakeObject("")` và Hide ở OnLoad/Open, vì native modern cũng hiển thị nhân vật trong cảnh chính. Thuộc tính ShowControl vẫn là tên CreateRole_Frame đúng source, không phải boolean.

Từ 13/09, nút Vào game bật khi có ít nhất một nhân vật. Bấm nút hoặc nhấp đúp thẻ sẽ gọi `GameProduceLogin:SendEnterGameMsg(GetCurSelectRole())`. Native `CGamePro_CharSel::SendEnterGameMsg` gửi CLAskCharLogin 426 trên phiên modern rồi chuyển sang socket game (`Docs/specs/net/world-session_vi.md`). Controller không gửi khi chưa có nhân vật hoặc khi chỉ số native nằm ngoài phạm vi. Nút Xóa vẫn disabled với thông báo chưa sẵn sàng, vì native modern chưa nối packet xóa; không gửi packet legacy để giả chức năng. Chọn thẻ gọi SelectRoleSlot thực; tạo mới phải chờ quyền từ máy chủ.

## Tài nguyên và mã hóa

- 12 loại control gốc được ánh xạ đúng TargetType; 13 look có namespace `CysCR_`. Các look riêng giữ đầy đủ; TLBB_Look_Common chỉ cần ba phần Frame_Type2, Background_Frame_Type2, Frame_Type_Lace1 có tham chiếu thật.
- 20 atlas S2 giữ tọa độ ảnh, đủ 30 portrait và 15 ảnh thơ/tiêu đề xem trước; không có atlas panel tự thiết kế. Texture giữ nguyên bytes. Descriptor đầu ra native chỉ thêm `CysCR_`; không sửa bảng nguồn.
- Font `CysCR_Control` dùng NotoSansSC-Regular.ttf, Size 11, CodePage 65001. SHA-256 font phải bằng `d45f67f0a7c0ca3f256950777ce6a61cc7ce5f9696d02900cbbaac25f8aa7d16`. Nhãn hiển thị/controller UTF-8; dữ liệu GBK không bị chuyển mã hàng loạt.
- Bảy alias `CysCreate{Race,Model,Face,Hair,Portrait,Outfit,Visual}.txt` giữ nguyên bytes CharRace, CharModelEx, CharFaceGeo, CharHairGeo, CharacterFace, NewRoleEquipset, ItemVisualChar S2. Alias CysCreateCamera giữ nguyên Model_Parameter; không đổi schema catalog.
- `Tests/ui/create_role_appearance_resources.py` đóng model tùy chỉnh từ S2, giữ khóa GBK và ánh xạ tên file CP1252 của engine. Không sửa appearance tables thành schema Canonical.
- `Tools/data/create_role_materials.py` đóng parent Mtl_Character_Lit và AlphaBlend/ColourChangable/AlphaTemplate, tám chương trình model/depth, 20 HLSL/include nguyên S2 vào MaterialTemplates.zip. Các entry Bootstrap không liên quan giữ nguyên bytes; không tạo vật liệu trắng hay texture placeholder.
- `Tools/data/create_role_scene_resources.py` ghép sau appearance/materials bằng đúng bytes đang được plan; đóng cảnh tl3chuangjian.Scene, 30 model môn phái 4950..4979 và toàn bộ mesh/skeleton/effect/particle/material/shader liên quan. Profile từ chối `valid:false`, không bỏ tài nguyên thiếu rồi tạo marker thành công. Các đường có thư mục con phải giữ đầy đủ khóa runtime.
- `Tools/data/create_role_showroom.py` sinh CysLoginShowroom.txt từ năm tư thế native C: nữ, nam và ba slot chọn nhân vật. Có position/yaw, eye/quaternion và FOV; các pose là trạng thái cuối đã đối chiếu nguồn. Chuyển động camera giữa các pose gốc chưa được tái hiện; không nhận phần này là hành vi nguyên bản hoàn toàn.
- Gợi ý tên lấy Female/MaleFirstName/LastName S2, chỉ chuyển giá trị hiển thị GBK sang UTF-8. Bộ sinh kiểm mọi tổ hợp không quá 29 byte.

`Data/Config/CysCreatePreview.txt` gồm đúng 15 dòng UTF-8 không header: `id<TAB>imageDescriptor<TAB>description`. ID 0..14 theo callback CY, không phải ID môn phái của bản ghi nhân vật. Ảnh/ID lấy từ CY; mô tả tiếng Việt là chỉ dẫn xem trang phục do CY-Source viết, không bịa đặc tính chiến đấu. Ảnh thực xác nhận các khóa dễ nhầm: Icon_Kunlun/Cs_Kunlun hiển thị **Đào Hoa Đảo**, Icon_Hongming/Cs_Congren hiển thị **Tuyệt Tình Cốc**, ERenGu hiển thị **Ác Nhân Cốc**. Evidence ảnh đọc từ DDS tại `Build/Logs/2026-09-13-gpt-create-role/profile/original-art`.

## Hợp đồng controller

PreLoad/OnLoad/OnEvent giữ tên LoginCreateRole và LoginSelectRole mà InterfaceEx gọi. Create đăng ký OPEN/CLOSE_CREATE_CHARACTOR, CREATE_CLEAR_NAME; Select đăng ký OPEN/CLOSE_SELECT_CHARACTOR, REFRESH_ROLE_SELECT_CHARACTOR, CREATE_ROLE_OK.

- GetCreateOptions(sex,kind) trả mảng 1-based `{id,label,image}`; controller giữ chỉ số 0-based và gọi ApplyCreateAppearance(sex,face,hair,outfit,portrait). Lựa chọn đọc theo số dòng thật: S2 hiện 6 mặt/3 tóc/3 trang phục/15 chân dung mỗi giới tính. Apply đổi nhân vật trong cảnh native.
- ModelRotBegin(-1/+1), ModelRotEnd(0), ModelZoom(-1/+1/0) giữ chiều và MouseLButtonDown/MouseButtonUp theo GL plaintext. Đóng/quay lại/hủy preview dừng chuyển động.
- ShowCreatePreview(id,sex) trả object/title/description từ native thật; controller chỉ dùng title và description để cập nhật panel gốc, không đưa object vào RTT. HideCreatePreview phục hồi nhân vật đang tạo; hủy giữ nguyên năm lựa chọn trước đó. Preview không gọi CreateRole và không gán môn phái tạo nhân vật.
- CreateRole(name,sex) nhận nguyên văn UTF-8. Controller chặn tên trống/quá 29 byte, native vẫn kiểm điều kiện máy chủ. Back gọi ChangeToSelectRoleDlgFromCreateRole. DefaultEditBox đúng là boolean và được bỏ khi ẩn tên/đóng màn.
- Select đọc GetRoleCount/GetRoleInfo(index) đủ năm giá trị name/menpai/level/deleteTime/portrait, gọi SelectRoleSlot(index) và yêu cầu trả 1. Hiện ba thẻ trống khi không có bản ghi; đủ ba bản ghi thì disable Create. CREATE_ROLE_OK chọn bản ghi mới nhất. Nhãn môn phái đọc theo mapping role GL, tách khỏi chỉ số preview; -1/9 là Vô môn.
- SelectRole_CreateRole gọi DataPool:AskCreateCharCode khi còn chỗ; Back gọi ChangeToAccountInputDlgFromSelectRole. Không thêm host Lua giả hoặc bỏ control/sự kiện để né chức năng thiếu.

Chữ động dùng SetProperty("Text",value): native gọi Window::setText/TextChanged, giữ nguyên raw editbox text. SetTextOriginal chỉ ghi cache d_textOriginal và không cập nhật chữ hiển thị. Fixture phân biệt hai hành vi này để lỗi nhãn trống đã gặp ở runtime c77b96a không thể lọt lại.

## Plan, backup và manifest

Từ thư mục CY-Source:

```powershell
& 'C:/Program Files/Python313/python.exe' -B Tools/data/prepare_create_role_profile.py --stage Build/<stage> --out Build/Logs/<new-plan>
& 'C:/Program Files/Python313/python.exe' -B Tools/data/prepare_create_role_profile.py --stage Build/<stage> --out Build/Logs/<new-apply> --apply
```

Plan kiểm toàn bộ manifest GL, bytes sáu tệp Canonical, namespace, closure nguồn, font và filter trước khi ghi. Từ chối đường ngoài Build, traversal, symlink/junction và stage đã áp dụng creation. Marker được kiểm đường dẫn trước exists() và trước ghi cuối; symlink đứt cũng bị từ chối. UI-only plan không thể apply.

Apply sao lưu mọi đích tồn tại trước lần ghi đầu, lưu backup-index, xác minh từng hash sau ghi. create_role_profile.json chỉ có applied:true sau toàn bộ kiểm tra. Manifest chứa provenance/hash nguồn, bộ sinh, controls, atlas, tài nguyên, nguồn/đích từng tệp. Manifest GL chỉ cập nhật hash tệp extension sửa, lưu sha256_before_creation/creation_origin; sáu pairs không đổi.

## Kiểm chứng

`Tests/ui/create_role_profile_tests.py` dùng nguồn CY thật, fixture không Game.exe và LuaPlus.dll CI; không khởi chạy GPU, server hay thực hiện đăng nhập. Kiểm exact control tree/parent/geometry/art/event, closure/bytes, namespace giữ baseline, các guard, apply/backup/hash/inheritance. Controller chạy trong Lua thật với fixture UI/native để kiểm phân trang, chỉ số, chữ/UTF-8, 15 preview × hai giới tính, hủy phục hồi, hướng xoay/zoom và chọn 0/2/3 bản ghi thật trong fixture.

Bằng chứng cuối `Build/Logs/2026-09-13-gpt-create-role/profile/tests-12-original-scene/result.json`: **75/75 PASS**, full private apply **820 tệp**, gồm cảnh/30 model môn phái/năm pose native. Mọi hash/backup/manifest kế thừa và sáu tệp đăng nhập đều đạt. LuaPlus.dll CI SHA-256 `aadbaa43eb1f1748cefa8fccdcf9659ddee1edb4cfccce71cfc2ba7ae745568f`. Lượt 10/11 giữ failure.json: lần đầu fixture dùng lookup Python phân biệt hoa/thường tên Scene; lần sau assert cũ chưa tính hai parent Bootstrap được scene thay đúng nguồn. Test cuối kiểm duy nhất một đích theo quy tắc Windows, các entry không liên quan qua cả hai closure và SHA từng block scene thay.

Kiểm thử vẫn không chứng minh GPU. Cảnh/model/tư thế, font, thao tác và ảnh màn gốc phải kiểm bằng Game sau khi closure/native cùng được ghép. Không coi các ảnh panel tự dựng trước đây là kết quả đạt yêu cầu mới. Ba lỗi native được phát hiện khi review controller (độ dài prefix ảnh, hướng zoom, camera legacy ghi đè ở double Init) đã giao root sửa; bằng chứng read-only tại `Build/Logs/2026-09-13-gpt-create-role/profile/native-controller-review.json`.

## Chữ trong khung gốc sau runtime 8dd7b95

Runtime gốc đã vào được cảnh/preview nhưng câu dài bị ngắt giữa từ. FontBase::drawWrappedText xuống dòng từng codepoint; drawText xử lý LF trước bước đó. Không đổi cơ chế CEGUI chung hay geometry/art: gợi ý trái rút còn “Chọn môn phái”; mô tả mỗi phái là ba câu ngắn “Tên phái. Nam / Nữ. Hủy để quay lại.” Controller tách tại dấu chấm + khoảng trắng thành ba dòng rõ ràng, bảng vẫn 15 dòng vật lý UTF-8 và không đổi API native.

Focused fixture `Build/Logs/2026-09-13-gpt-create-role/profile/text-wrap-1/result.json` đạt **6/6**: 15 mô tả đi qua controller với LuaPlus thật, hủy vẫn phục hồi editor, cây 96 control giữ nguyên. Đo Noto bằng Pillow FreeType BASIC 15px, cộng advance từng codepoint: hint 105px/khung134px, dòng mô tả dài nhất110px/khung144px. Đây là kiểm kích thước dự phòng cho native11pt/96DPI, chưa thay thế ảnh Game mới; không build hay chạy GPU trong lượt sửa này.

## Kiểm sau sửa chọn theo GUID và runtime a272cbe

`profile/tests-13-guid/result.json` dưới gốc log tạo nhân vật đã chạy lại75/75, apply820file. `profile/selection-guid-1/result.json` thêm8 ca Lua với reply đảo thứ tự; native `net/role-list-2-guid` đạt21/21. CREATE_ROLE_OK chọn GUID mới do native xác định; Lua đọc GetCurSelectRole, không suy ô cuối. Profile gốc vẫn96/50control.

`visual-a272cbe-1/report_vi.md` đối chiếu21PNG và xem trực tiếp bốn trạng thái tạo: nam/nữ mặc định, môn phái cuối nam, tên Unicode. Geometry96control, font và pose có SHA cùngbf4; đủ30model4950..4979 trong log. Ô tên gốc90×18pixel cuộn theo caret (Falagard/IMEEditBox); checkText chứng minh giữ nguyên chuỗi UTF-8, không nhận là ảnh hiển thị toàn chuỗi cùng lúc. Shader/MovementType/mesh cũ warnings0; Error8 WXTerrainType và VSync là baseline.

Hai mesh cảnh v1.30 chỉ chuyển trong bản test bằng serializer OGRE và snapshot byte tuyệt đối, không sửa nguồn S2. `Tools/data/apply_create_role_mesh_upgrade.py` dùng kết quả converter PASS để cập nhật hai mesh và chuỗi hai manifest, backup đủ trước ghi;11/11 test bảo vệ/rollback. Provenance cũ, bộ lọc0rule, Noto và sáu file GL không đổi. Chạy sau prepare_create_role_profile; nguồn scene.sources vẫn mô tả file S2, mesh_upgrade ghi hash bản chuyển riêng.

Lượt a272 đầu đã qua thao tác giao diện nhưng tạo qua mạng FAILED vì Game thiếu proxy tới dịch vụ kiểm tra tên đang chạy trên Tool; giữ bằng chứng mạng riêng, xem integration và handoff mới nhất để biết trạng thái sau sửa WSL.

## Reader nhãn tên và cách thu log — 5a2fb6a/91148e1

Lượt tạo WSL tiếp theo đã lưu GUID200001 nhưng harness dùng copyWindowTextUtf8 (chỉ Editbox/MultiLineEditbox) để đọc nhãn FalagardSimpleText của màn chọn, nên trả-1 và dừng. 5a2fb6a thêm copySimpleTextUtf8/export riêng, kiểm đúng lớp native bằng dynamic_cast, giữ raw UTF-8 và không cắt chuỗi khi thiếu capacity; contract getter ô nhập giữ nguyên. `simpletext-input-tests-1/tests.log` đạt28/28, gồm5 ca mới với factory SimpleText thật. UI/controller/layout không đổi để làm test qua.

91148e1 archive năm log hiện có trước launch vào prior-logs với hash/guard và tách validator chỉ đọc run.json. `runner-validation-1/result.json` đạt23/23; gate6085byte có SHA trước/sau bằng nhau. Raw Create2 vẫn FAILED; dữ liệu đã lưu được kiểm bằng phiên Fresh Select riêng, xem integration để biết kết quả cuối. Không tạo thêm nhân vật chỉ để chạy lại một assertion.

## Chốt nhãn ô trống và bản giao

Commit72384c4 rút “Chưa có nhân vật” thành “Ô trống” trong nguồn `Tools/ui/templates/CysSelectRole.lua`, giữ geometry100×14px của CY. `short-empty-label-1/applied.json` ghi backup/revision cho đúng controller và creation manifest; kiểm đủ820 tệp creation/131 tệp GL trước/sau, mọi file ngoài literal/metadata nguyên byte. Fresh Select2 `wsl-select-91148e1-2` PASS180,226giây, hai ảnh cuối được kiểm trực tiếp tại `visual-final-1`: nhãn trống vừa khung, tên CYTest00 và model thật đúng record đã lưu. Không chạy Create thêm. Bản giao ở `Build/gpt-p1-1-20260913/stage-91148e1`, launcher `Bin64/Run-CY-Test.cmd` dùng input bình thường. Giới hạn charlogin/world và lịch sử full Create FAILED được giữ trong integration.
