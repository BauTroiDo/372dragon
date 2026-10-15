local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_0284 = class("edali_0284", script_base)
edali_0284.script_id = 210284
edali_0284.g_busGuilList = {1000003, 1000004}
function edali_0284:OnDefaultEvent(selfId, targetId)
    local bSucceeded = 0
    local strText = "Không có Tọa kỵ khả dụng, xin hãy đợi"
    for _, busGuid in pairs(self.g_busGuilList) do
        local busId = self:LuaFnBusGetObjIDByGUID(busGuid)
        if busId then
            if busId ~= define.INVAILD_ID then
                local ret = self:LuaFnBusAddPassenger_Shuttle(busId, selfId, targetId, 0)
                if ret == define.OPERATE_RESULT.OR_OK then
                    strText = "Xin hãy đợi, lập tức cất cánh"
                    bSucceeded = 1
                    break
                elseif ret == define.OPERATE_RESULT.OR_BUS_PASSENGERFULL then
                    strText = "Tọa kỵ đã đầy, xin hãy đi chuyến sau."
                    break
                elseif ret == define.OPERATE_RESULT.OR_BUS_HASMOUNT then
                    strText = "Ngươi không thể thi triển Thao tác này khi đang cưỡi Tọa kỵ."
                    break
                elseif ret == define.OPERATE_RESULT.OR_BUS_HASPET then
                    strText = "Ngươi không thể thi triển Thao tác này khi đang mang theo Trân thú."
                    break
                elseif ret == define.OPERATE_RESULT.OR_BUS_CANNOT_TEAM_FOLLOW then
                    strText = "Ngươi không thể thi triển Thao tác này khi đang tổ đội và đi theo."
                    break
                elseif ret == define.OPERATE_RESULT.OR_BUS_CANNOT_DRIDE then
                    strText = "Ngươi không thể thi triển Thao tác này khi đang song nhân cưỡi chung."
                    break
                elseif ret == define.OPERATE_RESULT.OR_BUS_CANNOT_CHANGE_MODEL then
                    strText = "Ngươi không thể thi triển Thao tác này khi đang biến thân."
                    break
                end
            end
        end
    end
    self:BeginEvent(self.script_id)
    self:AddText(strText)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
    if bSucceeded == 1 then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
    end
end

function edali_0284:OnEnumerate(caller)
    caller:AddNumTextWithTarget(self.script_id, "Bay đến Đông Môn", 9, -1)
end

return edali_0284
