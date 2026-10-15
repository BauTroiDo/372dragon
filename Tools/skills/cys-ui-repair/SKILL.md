---
name: cys-ui-repair
description: "Sửa CEGUI/Lua/skin của client CY-Source: nền ô, SelfEquip, tooltip, inspect, cuộn chuột, icon đối thoại, tên NPC và thanh F/Alt. Dùng cho CY build từ source; phân biệt với chỉnh trực tiếp client_GL."
---

# Giao diện CY-Source

Gốc `C:/TLBB/085/CY-Source`; client/client_GL và CanonicalCY chỉ đọc để đối chiếu. Theo AGENTS, đọc kỹ năng GL hiện có khi sửa SelfEquip/skin, nhưng **không chuyển đích sửa sang client_GL**: CY sửa C++/generator và xuất candidate overlay.

## Tìm đúng lớp lỗi

1. Đọc Lua, layout, looknfeel, imageset của phiên bản làm được việc đó; lần theo host C++ và dữ liệu server. Đếm control/names/events trước khi sửa. Khung có mặt không chứng minh host/backend đã hoạt động.
2. Nền ô mất trên nhiều cửa sổ: kiểm renderer chung trước khi vẽ tài nguyên mới. `FalagardSimpleText` từng bỏ state imagery và bỏ nền khi text rỗng; phải vẽ Enabled/Disabled rồi `TextArea`. ResizeText/Star có nền riêng, tránh vẽ hai lần.
3. Cuộn không hoạt động: lần `WM_MOUSEWHEEL` → InputEventQueue → `CUISystem::InjectInput` → CEGUI → scrollbar. Sự kiện UI đã dùng phải không zoom camera; ra thế giới vẫn zoom. Tooltip dài có luồng cuộn riêng cần kiểm cùng menu.
4. Layout sai: sửa generator trong `Tools/game`, giữ tên/cây/callback. Ưu tiên look riêng hoặc layout cục bộ. Không bật lại GLResponsive hay hook chung vào metatable để co toàn UI; cách đó đã làm hỏng điều khiển.
5. Build đủ DLL phụ thuộc, stage, kiểm ảnh ở dữ liệu thật và kiểm đóng Esc → đi bộ/thao tác. Đọc [các hợp đồng UI](references/contracts.md) cho ca cụ thể.

XML của Expat phải ghi `encoding="utf-8"`, không dùng `utf8`. Kiểm Lua bằng runtime LuaPlus 5.0 của client khi liên quan cú pháp/API; `luac5.4` chỉ phù hợp server. `MessageBoxSelf3` từng chỉ là stub; xác nhận bằng lời gọi thật trước khi dựa vào nó.

## Kiểm tra đủ phạm vi

Kiểm chuỗi tiếng Việt có dấu, tên dài, ô trống/đã có item, disabled, hover, cooldown và kéo thả khi liên quan. Transparent DefaultWindow vẫn có thể chặn chuột; thu vùng cha đúng phạm vi hoặc dùng cơ chế xuyên chuột phù hợp. Không coi ảnh không có nền là đạt nếu control không nạp vì lỗi XML.

Nguồn chính: [nền ô và wheel](C:/TLBB/085/CY-Source/Docs/specs/shared-cells-mouse-wheel-20260923_vi.md), [inspect](C:/TLBB/085/CY-Source/Docs/specs/tooltip-inspect-20260923_vi.md), [NPC icon](C:/TLBB/085/CY-Source/Docs/specs/npc-dialogue-icons-20260923_vi.md). Công thức trang bị xem skill `cys-equipment-systems`; thủ tục publish xem `cys-build-release` khi cần.
