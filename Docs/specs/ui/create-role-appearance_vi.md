# Ngoại hình tạo nhân vật từ dữ liệu CY

Ngày 13/09/2026. Nguồn người dùng chỉ định: `../Tools/DATA NEW/DataCY31-08-26`, chỉ đọc. Phạm vi này cung cấp danh mục ngoại hình và mô hình xem trước; kiểm thử GPU, màn tạo nhân vật và việc tạo thật trên máy chủ do đợt tích hợp chốt riêng.

## Hợp đồng

`CysCreateRoleAppearance::Catalog` sở hữu chuỗi tài nguyên nguyên byte. `LoadResources` đọc bảy tên riêng `CysCreateRace/Model/Face/Hair/Portrait/Outfit/Visual.txt` từ resource provider. Các file alias là bản sao nguyên byte của bảng CY tương ứng; không thay schema DBC dùng chung và không sửa bản CY gốc.

`Options(Face/Hair/Portrait/Outfit, sex)` trả `Option { id, sex, flags, name, image }`, thứ tự theo dòng nguồn. `sex=0` là nữ, `sex=1` là nam. Chỉ các dòng có cờ tạo bằng 1 hoặc 3 được đưa vào danh sách. Nhãn CY là GBK, cần chuyển riêng nhãn sang UTF-8 ở lớp Lua; tên mesh, material và object luôn giữ GBK.

`ResolveIndices(sex, faceIndex, hairIndex, outfitIndex, recipe, error)` nhận chỉ số từ 0. `Resolve(sex, faceID, hairID, outfitID, recipe, error)` nhận ID thực được máy chủ trả. Chỉ số ngoài biên, sai giới tính và dòng không tồn tại đều thất bại, không tự thay bằng lựa chọn khác. Recipe chứa ID thực, tên object và chín thuộc tính đồ họa. Portrait được chọn từ danh sách riêng và không đổi cấu trúc mô hình.

`Apply(object, recipe, error)` chỉ hoạt động với native fake object, giữ hệ thống quản lý và giải phóng object hiện có. Phương thức `CObject_PlayerOther::InitializeCreationPreview` không virtual, không thêm trường hay đổi vtable; tạo actor từ tên object của CY. Mỗi thuộc tính được đọc lại sau khi gán. Không tạo item qua schema trang bị 0.85, không gửi gói tin và không ghi trạng thái nhân vật máy chủ.

## Bảng và ánh xạ đã kiểm chứng

Các số cột sau tính từ 0.

| Bảng CY | Schema | Cột được dùng |
|---|---|---|
| CharRace | 10 | ID, cột 3 nối CharModelEx |
| CharModelEx | 21 | cột 1 là object thường; cột 2 là bản IV, không trộn hai bản |
| CharFaceGeo | 12 | ID, giới tính 1, mesh thường 2, nhãn 4, cờ tạo 7 |
| CharHairGeo | 14 | ID, giới tính 1, mesh thường 2, phụ kiện tóc 4, nhãn 6, cờ tạo 9 |
| CharacterFace | 6 | ID, giới tính 1, descriptor ảnh 2, cờ tạo 3 |
| NewRoleEquipset | 5 | ID, nhãn 1, thân 2, chân 3, tay 4 |
| ItemVisualChar | 23 | mesh `1 + 11 * sex`, material cơ bản `2 + 11 * sex` |

Danh mục CY gồm 6 khuôn mặt, 3 kiểu tóc, 15 chân dung và 3 bộ đồ cho mỗi giới tính. Mặt nữ: `1,2,3,4,5,14`; mặt nam: `100,101,102,103,104,113`. Tóc nữ: `1,17,19`; tóc nam: `5,12,14`. Bộ đồ 0 nối visual thân/chân/tay `437/440/443`, bộ 1 `438/441/444`, bộ 2 `439/442/445`.

`CharRace[0] -> CharModelEx[1] -> nữ`, `CharRace[1] -> CharModelEx[0] -> nam`. Trường model gửi máy chủ vẫn là giới tính 0/1, không phải ID của CharModelEx. Máy chủ trả lại ID mặt/tóc và bộ đồ; đối chiếu 12 mặt + 6 tóc CY/server khớp byte ở ID, giới tính và mesh thường tại `Build/Logs/2026-09-13-gpt-create-role/net/appearance-server-rows.json`.

Reader cũng nhận schema Canonical cũ: Model 10, Face 11, Hair 13. Hai schema được kiểm tra tường minh; không ép record này sang struct của schema kia. Các chuỗi dài, offset vượt giới hạn, header/kiểu cột sai và ID trùng bị từ chối. Một lần nạp bảng bị lỗi không phá bảng hợp lệ đã nạp trước đó.

## Tài nguyên xem trước

`Tests/ui/create_role_appearance_resources.py::build_plan(stage, source_root)` trả `(updates, records, report)`, chưa ghi stage. Chủ profile kiểm tra rồi áp kế hoạch. File CY trên đĩa dùng tên Unicode Trung Quốc; tên đích stage dùng cách biểu diễn CP1252 của khóa GBK để phù hợp engine hiện tại. Nội dung mesh, skeleton và texture giữ nguyên byte.

Kế hoạch đã kiểm trên stage đăng nhập `stage-bc363c3`: 85 file cập nhật, 8.165.952 byte, gồm 7 bảng alias, 2 script ghép, 36 mesh, 4 skeleton và 36 texture. Hai block object gốc CY và 36 block material cần cho ngoại hình được ghép nguyên byte vào script stage; các block khác được giữ. Kiểm đầy đủ mesh, skeleton, material và texture trực tiếp của danh mục không thiếu tài nguyên. Bằng chứng: `Build/Logs/2026-09-13-gpt-create-role/appearance/resources-2.json`.

Động tác đứng `空手站立01` có trong hai object CY và trong skeleton thực: nữ dùng `女空手站立.skeleton`, nam dùng `4_男空手非战斗.skeleton`. Gọi actor với cờ animation trực tiếp, lặp lại. Các liên kết animation khác trong block object chỉ nạp khi dùng; không đưa toàn bộ động tác chiến đấu, thú cưỡi vào profile tạo nhân vật.

Kế hoạch lần đầu dừng khi thấy material trùng ở phần không dùng của all.material CY. Lần sau giới hạn kiểm trùng ở đúng 36 material được chọn; không sửa hoặc tuyên bố đã sửa các material không liên quan.

## Kiểm chứng offline

Lệnh từ CY-Source, chạy mỗi lần với thư mục output mới:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tests/ui/run_create_role_appearance_tests.ps1 -OutDir Build/Logs/2026-09-13-gpt-create-role/appearance/tests-cy-next -CY
powershell -NoProfile -ExecutionPolicy Bypass -File Tests/ui/run_create_role_appearance_tests.ps1 -OutDir Build/Logs/2026-09-13-gpt-create-role/appearance/tests-canonical-next
```

CY đạt 141/141 (`tests-cy-3`); Canonical đạt 123/123 (`tests-canonical-4`), build/run rc 0 và không cảnh báo compiler. Các ca dùng helper C++ thật với bảng nguồn thật, kiểm mọi tổ hợp mặt/tóc/bộ đồ, so recipe theo chỉ số và ID máy chủ, kiểm khóa GBK, giới tính và lỗi dữ liệu. Không gọi renderer hay kết nối máy chủ trong bộ này.

Lần `tests-cy-2` đạt 139/141 vì hai ca âm giả định bảng binary trong khi CY là bảng text. Giữ nguyên kết quả cũ, sửa ca âm để cắt dòng text và làm hỏng ID đúng định dạng CY; không nới kiểm tra sản phẩm. Bản Canonical binary vẫn giữ các ca offset/pool tương ứng.

Trước thay đổi, CharModel.txt được mở bảng rỗng và fake object tạo nhân vật không có actor; CharHairGeo cũ đọc phụ kiện/IV mesh thành nhãn. Đây là nguyên nhân cần lớp đọc đúng schema. Các kết quả offline trên chưa chứng minh hình ảnh hoặc animation trong Game; đợt tích hợp phải kiểm bằng ảnh và log thật.

## Lịch sử chẩn đoán GPU đầu tiên và camera CY

Các đoạn dưới ghi lại trạng thái của những bản thử bị loại, không phải trạng thái hiện tại. Sau phản hồi của người dùng, màn tạo/chọn đã chuyển sang scene chính và geometry CY gốc; host xoay/zoom/MoveToCharacter đã có triển khai cho scene này. GPU `a272cbe` xác nhận model, scale và toàn bộ điều khiển tạo. Xem `Docs/specs/ui/create-role-integration_vi.md` để biết kết quả WSL và các giới hạn còn lại; không dùng mô tả stub hoặc RTT dưới đây làm hướng triển khai mới.

Phiên `offline-c77b96a` đã chạy điều khiển nhưng ảnh `create-male-default` chỉ có chân mô hình trắng phóng lớn; ảnh `create-male-choices` không còn mô hình. Hai ảnh ở `Build/gpt-p1-1-20260913/stage-c77b96a/ScreenShots` là bằng chứng lỗi, chưa phải màn tạo nhân vật đạt.

`CFakeObjectManager::CreateObject` đưa riêng render node về gốc RTT. Fake object logic vẫn ở `(100,100,100)` từ lúc tạo; mỗi lần đổi ngoại hình, `CObject_Character::CreateRenderInterface` lại đẩy vị trí logic sang renderer. `InitializeCreationPreview` nay đồng bộ vị trí logic và renderer về gốc `(0,0,0)` trước khi làm mới, chỉ áp dụng cho fake object của màn tạo/chọn nhân vật.

`Camera_Main` trong object CY là ID: nữ dùng 1, nam dùng 3. Giá trị thuộc `Config/Model_Parameter.txt`, schema ISFF, lần lượt cao/khoảng cách `0.95/5.4` và `1/6`. `CysCreateRoleCamera.h` đọc bảng riêng `CysCreateCamera.txt`, kiểm ID, số hữu hạn, khoảng giá trị và dòng trùng; `Apply` đổi giá trị này sang `height;distance` trước khi khung RTT tạo camera. Giá trị được lưu theo tên object nguyên byte để lần đổi diện mạo sau vẫn dùng đúng camera. Không đổi ABI hoặc enum của catalog bảy bảng.

Kế hoạch tài nguyên camera tại `appearance/resources-camera-1.json` thêm alias thứ tám nguyên byte: 86 cập nhật, 8.178.986 byte, ghi lại camera ID/cao/khoảng cách của cả hai object. Log GPU cũng xác nhận thiếu parent `Mtl_Character_Lit`: parent nằm trong `MaterialTemplates/Mtl_Character.material`, không nằm trong `Material/all.material`. Phần bổ sung material/shader được xử lý riêng bởi chủ profile; chỉ có tài nguyên mesh/texture chưa đủ chứng minh vật liệu hiển thị đúng. Cần phiên Game mới sau khi tích hợp các sửa này.

Reader camera và danh mục CY đạt 159/159 tại `appearance/tests-camera-cy-1`; hồi quy Canonical đạt 123/123 tại `appearance/tests-camera-canonical-1`. Cả hai build/run rc 0, không cảnh báo compiler. Chưa chạy lại GPU trong phần việc này.

Phiên `offline-a6ed37d` dừng ngay sau khi tạo actor nữ, trước nạp mesh. Alias camera trong stage có SHA-256 trùng nguồn CY; dump ghi ngoại lệ C++ `0xE06D7363`. Đối chiếu mã xác định `LogicModel::changeAttribute` không lưu giá trị của thuộc tính có hint trống: gán `Camera_Main=0.95;5.4` vẫn đọc lại `1`, nên adapter chủ động báo `CY preview camera value rejected`. Sửa hẹp trong `Src/Engine/WXCore/ModelSystem/WXLogicModel.cpp`: chỉ cập nhật thuộc tính `Camera_Main` đã tồn tại với hint trống; giữ xử lý mesh/material và thuộc tính khác. Log native mới ghi ID camera, cặp thông số và sai khác khi đọc lại, cùng lỗi trước khi ném ngoại lệ. Chưa có kiểm chứng GPU cho sửa này.

Đối chiếu GL gốc: CreateRole gọi `SetFakeObject("")` rồi `CreateRole_Woman/Man` khi đổi giới tính, nhưng lệnh xoay/zoom gọi `GameProduceLogin:ModelRotBegin/ModelRotEnd/ModelZoom`. Các host này hiện là stub; `MoveToCharacter(index)` của SelectRole cũng là stub. Có sẵn đường native `MeshWindow:RotateBegin/RotateEnd` tới `CFakeObjSystem`, còn camera RTT chỉ đọc khi hook; `Debug_SetFakeCamera` bị cố định cho `Player_Head`, không phải API zoom cho màn tạo nhân vật. `GamePro_CharSel::Init` còn đoạn nạp `CharacterSelTest.Scene` bị comment. Vì vậy cần đối chiếu đúng luồng scene và bố cục GL/CY trước khi khẳng định đã phục dựng màn gốc; các panel tự dựng trước đó chưa đáp ứng yêu cầu mới của người dùng.
