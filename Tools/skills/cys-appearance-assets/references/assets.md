# Dependency closure, bảng và mesh

## Ánh xạ có nguồn

Chọn donor theo hành vi đã chứng minh. Names/ID không cùng nghĩa giữa phiên bản. Wuhun GL 729–764 xung đột visual CY (733 là model khác), nên dùng mapping riêng và tên ASCII `cys_wh_<sha16>`, thêm CharModelEx 9995–10030 ở đợt 25/09. Kiểm Registry/ID trống hiện tại trước nhập mới; không tái dùng dải đó như dải luôn còn trống.

`Tools/game/audit_wuhun_appearance.py` tạo bằng chứng nguồn; `wuhun_appearance_data.py` dùng Planner, không tự copy file đơn lẻ. Closure gồm obj→mesh/skeleton/material→texture/effect/particle. Wuhun đã import 36 obj/291 phụ thuộc/21 mesh; số này chỉ cho pack đã khảo sát.

## Bảng mã và binary

Bảng client có ô nhị phân/string pool GBK; decoder phục vụ hiển thị không phải serializer roundtrip. Giữ byte gốc, append đúng schema/count/offset; không decode–encode toàn bộ chỉ để thêm vài dòng. Source all.* có tên GBK phải xử lý byte/codec có bằng chứng. Giữ đường dẫn con, không luôn rút basename. Bảng ID tăng nghiêm ngặt; không Unicode splitlines trên Latin-1 vì `0x85` có thể tách dòng giả.

## Material trong mesh

Override material trong .obj không đủ: lúc tạo entity, embedded material trong mesh vẫn được resolve. Import/rewrite cả tên trong mesh và closure tương ứng.

Lỗi `canon_lib.mesh_set_submat` đã sửa: `walk_mesh()['subs'][...]['span'][0]` là cursor **sau index buffer**, không phải chunk header. Header submesh đúng tại `q-6` với q là đầu tên material. Sửa nhầm chunk size ở cursor kia phá geometry dù file vẫn tồn tại.

`Tests/test_wuhun_material_rewrite.py` kiểm vertex/index/geometry nguyên, chunk size đúng và đổi tên ngược. `mesh-integrity.json` có đổi ngược toàn bộ byte 21 mesh GL. Khi sửa helper dùng chung, kiểm nhiều asset gốc thay vì chỉ xem một model render.

Một bẫy khác trong docs 08: OGRE import bounds với padding 1%; tool import→export→import có thể lệch bounds dù geometry nguyên. Đối chiếu source/serializer trước nới sai số; không đổi padding của game để chữa converter.

## Phân biệt tài nguyên với runtime

Thiếu all.skill cấu hình nạp overlay có thể làm marker HitTime không nạp; mount chồng EffectFolder script có thể duplicate definitions. Mesh/texture đủ không chứng minh actor đang hiển thị/camera fit. Exception sau thời gian cố định có thể là thời hạn probe: dùng log/PDB, không mặc nhiên quy lỗi asset cuối cùng.

Huyễn sức: audit 956 mẫu không đổi mesh/material thân và vài ảnh có đủ thân chưa tái hiện đúng tổ hợp tóc đỏ của người dùng. Giữ ca này là chưa xác nhận toàn diện; cần đúng item/sex/outfit/slot nếu tiếp tục.
