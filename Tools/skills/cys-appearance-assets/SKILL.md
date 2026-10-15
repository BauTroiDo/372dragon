---
name: cys-appearance-assets
description: "Sửa ngoại hình và nhập tài nguyên GL/CY vào CY-Source: Võ hồn/huyễn hóa, KFSObj, SelfEquip, màn chọn nhân vật, wardrobe, model/material/mesh và ánh xạ ID. Dùng khi model mất/sai/nhỏ hoặc mặc đồ làm ẩn thân."
---

# Ngoại hình và tài nguyên CY

Gốc `C:/TLBB/085/CY-Source`; đọc nguồn GL/CY trước, không sửa donor/CanonicalCY tại chỗ. Phân biệt itemID, visualID, CharModelExID, MonsterAttrExID, actionID và skillID trước thử sửa.

## Từ dữ liệu đến hình ảnh

Theo dữ liệu lưu → charlist/GCCharEquipment → CharacterData → actor attachment/preview → dependency closure và renderer. Kiểm riêng world, SelfEquip, select-role và widget chỉ dựng model; một nơi đúng không chứng minh nơi khác đúng.

- Wuhun `GCCharEquipment` mask `0x40000` đưa item+visual tới CharacterData, `Obj_PlayerOther::UpdateWuhun` đặt `KFSObj`; SelfEquip fakeavatar copy state, charlist lấy slot 18 C++/19 Lua. Tháo/ẩn phải clear, không giữ orb cũ.
- Tab VH dùng model trực tiếp qua CharModelEx/MeshWinSetModelID, không RaceID/MonsterAttrEx: ID 2341 tra bảng NPC từng dựng người. Camera scale/dist/pitch chỉ sửa sau khi chắc chọn đúng model.
- Char selection tính visual từ equipped item+huyễn hóa đã lưu, không tin cache visual cũ. World fallback không dùng default face/hair/costume nếu record có dữ liệu thật.
- Bản preview đã đúng model không chứng minh giao dịch huyễn hóa/cost/slots/persistence đúng. Đọc [huyễn hóa](references/wuhun.md).

## Nhập asset

Dùng `Tools/pipeline/canon_lib.py` Planner và SourceView để thu closure, đổi tên cô lập, giữ mapping Registry. Không chép numericID giữa GL/CY: visual 729–764 từng trùng model khác. Đọc [tính toàn vẹn asset](references/assets.md) trước sửa mesh/material/bảng nhị phân.

Model không thấy cần kiểm slot/visibility/sex/attachment, dependency/material và geometry trước khi tăng scale. Ornament che thân phải tái hiện đúng tổ hợp, không dùng vài ảnh khác để tuyên bố mọi trường hợp đã sửa.

Kiểm chuyển thường ↔ huyễn hóa, hide/show, equip/unequip, reopen, xoay, chuyển scene/relogin và ảnh thật. Duyệt danh mục 36 model là bằng chứng render catalog; bấm UI với ACK và kiểm tiền/nguyên liệu là bằng chứng giao dịch riêng.
