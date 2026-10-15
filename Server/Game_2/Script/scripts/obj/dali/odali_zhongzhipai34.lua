local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_zhongzhipai34 = class("odali_zhongzhipai34", script_base)
odali_zhongzhipai34.script_id = 714090
odali_zhongzhipai34.event_xuanzezhiwu = 713550
odali_zhongzhipai34.g_eventList = {
    20104001,
    20104002,
    20104005,
    20104007,
    20104009,
    20104012,
    20105001,
    20105004,
    20105007,
    20105012
}

function odali_zhongzhipai34:OnDefaultEvent(selfId, targetId)
    local AbilityLevel = self:QueryHumanAbilityLevel(selfId, define.ABILITY_ZHONGZHI)
    if AbilityLevel == 0 then
        self:BeginEvent(self.script_id)
        self:AddText("Ngươi hãy đi học kỹ năng trồng trọt trước đi")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if AbilityLevel ~= 0 then
        self:BeginEvent(self.script_id)
        self:AddText("Mỗi loại cây trồng đều có thể chia thành hai loại: muộn vụ và sớm vụ, thời gian trưởng thành của sớm vụ khoảng 5 phút, muộn vụ khoảng 70 phút, nhưng số lượng thu hoạch mỗi lần nhiều hơn. Ngươi muốn chọn trồng loại cây nào?")
        self:AddNumText("Trồng cây trồng sớm", 6, 254)
        self:AddNumText("Trồng cây trồng muộn", 6, 255)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function odali_zhongzhipai34:OnEventRequest(selfId, targetId, arg, index)
    local name_Index
    local NumText = index
    if NumText == 254 or NumText == 255 then
        self:BeginEvent(self.script_id)
        self:AddText("Xin chọn loại cây trồng mà ngươi muốn trồng")
        for i, eventId in pairs(self.g_eventList) do
            for j, g_ZhiWuId in pairs(define.V_ZHONGZHI_ID) do
                if eventId == g_ZhiWuId then
                    local AbilityLevel = self:QueryHumanAbilityLevel(selfId, define.ABILITY_ZHONGZHI)
                    if AbilityLevel >= define.V_ZHONGZHI_NEEDLEVEL[j] then
                        if NumText == 254 then
                            name_Index = j
                        else
                            name_Index = j + #(define.V_ZHONGZHI_NAME) / 2
                        end
                        self:AddNumText(
                            define.V_ZHONGZHI_NAME[name_Index] .. "(" .. define.V_ZHONGZHI_NEEDLEVEL[j] .. "Cấp)",
                            6,
                            name_Index
                        )
                        break
                    end
                end
            end
        end
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    local zhiwuId = NumText
    for i, findId in pairs(self.g_eventList) do
        if zhiwuId <= #(define.V_ZHONGZHI_NAME) then
            self:CallScriptFunction(713550, "OnDefaultEvent", selfId, targetId, zhiwuId)
            return
        end
    end
end

function odali_zhongzhipai34:OnMissionSubmit(selfId, targetId, scriptId)
    for i, findId in pairs(self.g_eventList) do
        if scriptId == findId then
            local ret = self:CallScriptFunction(scriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(scriptId, "OnAccept", selfId, define.ABILITY_ZHONGZHI)
                self:CallScriptFunction(scriptId, "OnDefaultEvent", selfId, targetId, define.ABILITY_ZHONGZHI)
            end
            return
        end
    end
end

function odali_zhongzhipai34:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId, define.ABILITY_ZHONGZHI)
            end
            return
        end
    end
end

return odali_zhongzhipai34
