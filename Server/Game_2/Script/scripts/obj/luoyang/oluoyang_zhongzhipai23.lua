local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_zhongzhipai36 = class("oluoyang_zhongzhipai36", script_base)
oluoyang_zhongzhipai36.script_id = 714043
oluoyang_zhongzhipai36.g_eventList = {
    20104001, 20104003, 20104004, 20104006, 20104010, 20104011, 20105001,
    20105002, 20105005, 20105008, 20105011
}
local V_ZHONGZHI_NEEDLEVEL = 
{
1,2,3,4,5,6,7,8,9,10,
11,12,1,2,3,4,5,6,7,8,
9,10,11,12
}
local V_ZHONGZHI_NAME = {
"Tiểu Mạch non","Đại Mễ non","Ngọc Mễ non","Lạc non","Khoai lang non","Cao lương non","Vừng non","Đậu xanh non","Đậu tương non","Đậu tằm non",
"Khoai tây non","Khoai môn non","Cây gai non","Cây bông vải non","Á Ma non tháng","Mộc Miên non tháng","Hoàng Ma non tháng","Vân Miên non","Cẩn Ma non","Nhung Miên non",
"Thanh Ma non","Thải Miên non","La Bố Ma non","Lục Địa Miên non",
"Tiểu Mạch Vụ Mùa","Gạo muộn","Ngô muộn","Lạc muộn","Khoai lang muộn","Cao Lương Muộn","Vừng Muộn","Đậu Xanh Muộn","Đậu Nành Muộn","Đậu Tằm Muộn",
"Khoai Tây Muộn","Khoai Môn muộn","Cây gai muộn","Cây bông muộn","Cây lanh muộn","Mộc Miên muộn","Hoàng Ma muộn","Vân Miên muộn","Cẩn Ma muộn vụ","Nhung Miên muộn vụ",
"Thanh Ma muộn vụ","Thải Miên muộn","La Bố Ma muộn","Lục Địa Miên muộn"
}
function oluoyang_zhongzhipai36:OnDefaultEvent(selfId, targetId)
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
        self:AddText("Xin chọn loại cây trồng mà ngươi muốn trồng")
        for i, scriptId in pairs(self.g_eventList) do
            for j, g_ZhiWuId in pairs(define.V_ZHONGZHI_ID) do
                if scriptId == g_ZhiWuId then
                    if AbilityLevel >= V_ZHONGZHI_NEEDLEVEL[j] then
                        self:AddNumText(V_ZHONGZHI_NAME[j], 6, -1)
                        break
                    end
                end
            end
        end
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function oluoyang_zhongzhipai36:OnEventRequest(selfId, targetId, arg, index)
    local zhiwuId = self.script_id
    for i, findId in pairs(self.g_eventList) do
        if zhiwuId == findId then
            self:CallScriptFunction(713550, "OnDefaultEvent", selfId, targetId,
                                    zhiwuId)
            return
        end
    end
end

function oluoyang_zhongzhipai36:OnMissionSubmit(selfId, targetId, scriptId)
    for i, findId in pairs(self.g_eventList) do
        if scriptId == findId then
            local ret = self:CallScriptFunction(scriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(scriptId, "OnAccept", selfId,
                                        define.ABILITY_ZHONGZHI)
                self:CallScriptFunction(scriptId, "OnDefaultEvent", selfId,
                                        targetId, define.ABILITY_ZHONGZHI)
            end
            return
        end
    end
end

function oluoyang_zhongzhipai36:OnMissionAccept(selfId, targetId,
                                                missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret =
                self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId,
                                        define.ABILITY_ZHONGZHI)
            end
            return
        end
    end
end

return oluoyang_zhongzhipai36
