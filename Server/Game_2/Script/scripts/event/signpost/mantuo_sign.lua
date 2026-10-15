local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mantuo_sign = class("mantuo_sign", script_base)
mantuo_sign.script_id = 500072
mantuo_sign.g_Signpost = {
    { ["type"] = 2, ["name"] = "#{MPSD_220622_23}", ["x"] = 140, ["y"] = 75, ["tip"] = "Trang chủ Vương phu nhân",
        ["desc"] = "#{MPSD_220622_24}", ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "#{MPSD_220622_26}", ["x"] = 140, ["y"] = 88, ["tip"] = "Người bái sư Mạn Đà Sơn Trang Vương Tố Thương",
        ["desc"] = "#{MPSD_220622_27}", ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "#{MPSD_220622_29}", ["x"] = 155, ["y"] = 114, ["tip"] = "Người truyền võ công Vương Hòa Linh",
        ["desc"] = "#{MPSD_220622_30}", ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "#{MPSD_220622_32}", ["x"] = 210, ["y"] = 158, ["tip"] = "Kỹ năng đời sống Quan Sơn Nguyệt",
        ["desc"] = "#{MPSD_220622_33}", ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "#{MPSD_220622_35}", ["x"] = 186, ["y"] = 171, ["tip"] = "Kỹ năng hỗ trợ đời sống Vương Thủy Phong",
        ["desc"] = "#{MPSD_220622_36}", ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "#{MPSD_220622_38}", ["x"] = 63, ["y"] = 132, ["tip"] = "Quản lý tọa kỵ Diệp bà bà",
        ["desc"] = "#{MPSD_220622_39}", ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "#{MPSD_220622_41}", ["x"] = 129, ["y"] = 106, ["tip"] = "Nhiệm vụ sư môn Vương An Ca",
        ["desc"] = "#{MPSD_220622_42}", ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "#{MPSD_220622_44}", ["x"] = 143, ["y"] = 159, ["tip"] = "Người truyền tống Mạn Đà Sơn Trang U Thảo",
        ["desc"] = "#{MPSD_220622_45}", ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "#{MPSD_220622_120}", ["x"] = 30, ["y"] = 197, ["tip"] = "Hạo Nguyệt Châu",
        ["desc"] = "#{MPSD_220622_121}", ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "#{MPSD_220622_123}", ["x"] = 151, ["y"] = 36, ["tip"] = "Người truyền khinh công Vương Nhạn Túc",
        ["desc"] = "#{MPSD_220622_47}", ["eventId"] = -1 }
}
function mantuo_sign:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function mantuo_sign:OnDefaultEvent(selfId, targetId, arg, index)
    local signpost = self.g_Signpost[index]
    local sceneId = self:GetSceneID()
    if signpost["type"] == 1 then
        self:BeginEvent(self.script_id)
        self:AddText(signpost["name"] .. "：")
        self:CallScriptFunction(signpost["eventId"], "OnEnumerate", selfId, targetId)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif signpost["type"] == 2 then
        self:CallScriptFunction(888888, "AskTheWay", selfId,sceneId,signpost["x"], signpost["y"], signpost["tip"])
        self:BeginEvent(self.script_id)
        self:AddText(signpost["desc"])
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

return mantuo_sign
