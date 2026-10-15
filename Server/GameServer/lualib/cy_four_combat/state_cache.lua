-- skill-logic guard (16/09/2026): kho trạng thái native của cy_four, ĐỂ NGOÀI đối tượng impact.
--
-- Trước đây `engine.lua` lưu `imp._cy_four_native = state` và `state.engine_impact = imp` → vòng tham
-- chiếu. `human:get_save_data()` đóng gói `impacts:get_list()` (chính các đối tượng impact sống) gửi
-- từ scene về msgagent, nên skynet báo `serialize can't pack too depth table` và msgagent bị giết
-- (client rớt). Để state ở bảng phụ khoá YẾU thì đồ thị của impact lại phẳng, đóng gói được;
-- state vẫn sống đúng bằng tuổi của impact.
local M = setmetatable({}, {__mode = "k"})
return M
