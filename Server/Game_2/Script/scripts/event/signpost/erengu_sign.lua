local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mantuo_sign = class("mantuo_sign", script_base)
mantuo_sign.script_id = 500073
mantuo_sign.g_Signpost = {
    { ["type"] = 2, ["name"] = "#{ERMP_240620_115}", ["x"] = 84, ["y"] = 26, ["tip"] = "Cốc chủ Sơn Quỷ",
        ["desc"] = "#{ERMP_240620_116}", ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "#{ERMP_240620_117}", ["x"] = 154, ["y"] = 56, ["tip"] = "Người bái sư Ác Nhân Cốc Đoàn Diên Khánh",
        ["desc"] = "#{ERMP_240620_118}", ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "#{ERMP_240620_119}", ["x"] = 180, ["y"] = 120, ["tip"] = "Người truyền võ công Diệp Nhị Nương",
        ["desc"] = "#{ERMP_240620_120}", ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "#{ERMP_240620_121}", ["x"] = 132, ["y"] = 123, ["tip"] = "Kỹ năng đời sống Sơn Lưu Nhi",
        ["desc"] = "#{ERMP_240620_122}", ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "#{ERMP_240620_123}", ["x"] = 117, ["y"] = 123, ["tip"] = "Kỹ năng hỗ trợ đời sống Sơn Diệu",
        ["desc"] = "#{ERMP_240620_124}", ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "#{ERMP_240620_125}", ["x"] = 38, ["y"] = 57, ["tip"] = "Quản lý tọa kỵ Hình Vạn Lý",
        ["desc"] = "#{ERMP_240620_126}", ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "#{ERMP_240620_127}", ["x"] = 182, ["y"] = 181, ["tip"] = "Nhiệm vụ sư môn Nhạc Lão Tam",
        ["desc"] = "#{ERMP_240620_128}", ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "#{ERMP_240620_129}", ["x"] = 123, ["y"] = 150, ["tip"] = "Người truyền tống Ác Nhân Cốc Tôn Tam Bá",
        ["desc"] = "#{ERMP_240620_130}", ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "#{ERMP_240620_131}", ["x"] = 79, ["y"] = 161, ["tip"] = "Người truyền khinh công Vân Trung Hạc",
        ["desc"] = "#{ERMP_240620_132}", ["eventId"] = -1 }
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
