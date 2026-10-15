local class = require "class"
local define = require "define"
local script_base = require "script_base"
local dali_sign_menpaichuansong = class("dali_sign_menpaichuansong", script_base)
dali_sign_menpaichuansong.script_id = 500041
dali_sign_menpaichuansong.g_Signpost = {
    { ["type"] = 2, ["name"] = "少林", ["x"] = 187, ["y"] = 122, ["tip"] = "慧易",
        ["desc"] = "Thiếu Lâm phái Tiếp Dẫn Tăng Huệ Dịch (187, 122) ở ngay góc Đông Bắc của Ngũ Hoa Đàn trung tâm Đại Lý, nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "天龙", ["x"] = 189, ["y"] = 124, ["tip"] = "破贪",
        ["desc"] = "Thiên Long phái Tiếp Dẫn Tăng Phá Tham (189, 124) ở ngay góc Đông Bắc của Ngũ Hoa Đàn trung tâm Đại Lý, nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "逍遥", ["x"] = 188, ["y"] = 133, ["tip"] = "澹台子羽",
        ["desc"] = "Sứ Giả Tiếp Dẫn Tiêu Dao Phái Đạm Đài Tử Vũ (188, 133) ở ngay góc Đông Bắc của Ngũ Hoa Đàn trung tâm Đại Lý, nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Nga Mi", ["x"] = 192, ["y"] = 129, ["tip"] = "路三娘",
        ["desc"] = "Cô cô tiếp dẫn phái Nga My Lộ Tam Nương (192, 129) ở ngay góc Đông Bắc của Ngũ Hoa Đàn trung tâm Đại Lý, nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "天山", ["x"] = 131, ["y"] = 124, ["tip"] = "程青霜",
        ["desc"] = "Thiên Sơn phái Tiếp Dẫn Sứ xưng Thanh Sương (131, 124) ở ngay góc Tây Bắc của Ngũ Hoa Đàn trung tâm Đại Lý, cách Người giới thiệu bái sư Nhiếp Chính không xa. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "星宿", ["x"] = 134, ["y"] = 120, ["tip"] = "海风子",
        ["desc"] = "Đệ tử tiếp dẫn phái Tinh Túc. Hải Phong Tử (131,124) ở ngay Ngũ Hoa Đàn trung ương #YDạ Lĩnh#W của góc tây bắc, cách Người giới thiệu bái sư Nhiếp Chính không xa. Nhấn phím TAB, trên bản đồ sẽ có nhãn hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "明教", ["x"] = 130, ["y"] = 121, ["tip"] = "石宝",
        ["desc"] = "Tiếp Dẫn Sứ Minh Giáo Thạch Bảo (131,124) ở ngay Ngũ Hoa Đàn trung ương #YDạ Lĩnh#W của góc tây bắc, cách Người giới thiệu bái sư Nhiếp Chính không xa. Nhấn phím TAB, trên bản đồ sẽ có nhãn hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "武当", ["x"] = 127, ["y"] = 131, ["tip"] = "张获",
        ["desc"] = "Võ Đang Trương Hoạch (131,124) ở ngay Ngũ Hoa Đàn trung ương #YDạ Lĩnh#W của góc tây bắc, cách Người giới thiệu bái sư Nhiếp Chính không xa. Nhấn phím TAB, trên bản đồ sẽ có nhãn hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "丐帮", ["x"] = 126, ["y"] = 135, ["tip"] = "简宁",
        ["desc"] = "Trưởng lão tiếp dẫn Cái Bang Giản Ninh (131, 124) ở ngay góc tây bắc Ngũ Hoa Đàn trung tâm Đại Lý, cách Người giới thiệu bái sư Nhiếp Chính không xa. Ấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
}
function dali_sign_menpaichuansong:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function dali_sign_menpaichuansong:OnDefaultEvent(selfId, targetId,arg,index)
    local signpost = self.g_Signpost[index]
    if signpost["type"] == 1 then
        self:BeginEvent(self.script_id)
        self:AddText(signpost["name"] .. "：")
        self:CallScriptFunction(signpost["eventId"], "OnEnumerate", selfId, targetId)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif signpost["type"] == 2 then
        self:CallScriptFunction(888888, "AskTheWay", selfId, signpost["x"], signpost["y"], signpost["tip"])
        self:BeginEvent(self.script_id)
        self:AddText(signpost["desc"])
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

return dali_sign_menpaichuansong
