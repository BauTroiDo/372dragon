local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_saodiseng = class("odali_saodiseng", script_base)
odali_saodiseng.script_id = 900008
odali_saodiseng.g_ChangShenCaoItem = {38000639, 40004689}
local title_ids = {
    [3] = 265, [4] = 266, [5] = 267, [6] = 268,
    [7] = 269, [8] = 270, [9] = 271, [10] = 272,
    [11] = 273, [12] = 276
}
function odali_saodiseng:UpdateEventList(selfId, targetId)
    if self:GetMenPai(selfId) == 9 then
        self:BeginEvent(self.script_id)
        self:AddText("Xin vào môn phái rồi hãy tới.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    self:BeginEvent(self.script_id)
    self:AddText("#{XL_090707_01}")
    self:AddNumText("#{XL_XML_35}", 6, 0)
    self:AddNumText("#{XL_XML_36}", 6, 1)
    self:AddNumText("Lĩnh thưởng danh hiệu Tu luyện", 6, 2)
    self:AddNumText("Về Tu luyện", 11, 3)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_saodiseng:OnEventRequest(selfId, targetId, arg, index)
    local Operation = index
    if Operation == 222 then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1020200711)
    end
    if Operation == 0 then
        if self:GetLevel(selfId) < 70 then
            self:NotifyTip(selfId, "#{XL_090707_61}")
            return
        end
        if self:GetMissionData(selfId, define.XIULIAN_JINGJIE_1) == 0 then
            self:SetMissionData(selfId, define.XIULIAN_JINGJIE_1, 11111111)
        end
        if self:GetMissionData(selfId, define.XIULIAN_JINGJIE_2) == 0 then
            self:SetMissionData(selfId, define.XIULIAN_JINGJIE_2, 1111111)
        end
        self:BeginUICommand()
        local nGongLi = self:GetMissionData(selfId, define.XIULIAN_GONGLI)
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(1)
        self:UICommand_AddInt(0)
        self:UICommand_AddInt(nGongLi)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 171717)
        return
    end
    if Operation == 1 then
        if self:GetLevel(selfId) < 70 then
            self:NotifyTip(selfId, "#{XL_090707_61}")
            return
        end
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(2)
        self:UICommand_AddInt(0)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 171717)
        return
    end
    if Operation == 2 then
        self:AwardXiuLianTitle(selfId, targetId)
        return
    end
    if Operation == 3 then
        self:BeginEvent(self.script_id)
        self:AddText("#{XL_090707_46}")
        self:AddNumText("#{XL_XML_60}", 11, 100)
        self:AddNumText("#{XL_XML_69}", 11, 102)
        self:AddNumText("#{XL_XML_61}", 11, 103)
        self:AddNumText("#{XL_XML_63}", 11, 104)
        self:AddNumText("#{XL_XML_64}", 11, 105)
        self:AddNumText("Quay lại trang trước", 0, 107)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if Operation == 5 then
        self:BeginEvent(self.script_id)
        self:AddText("#{LZZHD_130520_03}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if Operation == 100 then
        self:BeginEvent(self.script_id)
        self:AddText("#{XL_090707_48}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if Operation == 101 then
        self:BeginEvent(self.script_id)
        self:AddText("#{XLZY_120330_20}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if Operation == 102 then
        self:BeginEvent(self.script_id)
        self:AddText("#{XL_090707_52}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if Operation == 103 then
        self:BeginEvent(self.script_id)
        self:AddText("#{XL_090707_53}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if Operation == 104 then
        self:BeginEvent(self.script_id)
        self:AddText("#{XL_090707_55}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if Operation == 105 then
        self:BeginEvent(self.script_id)
        self:AddText("#{XL_090707_56}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if Operation == 106 then
        self:BeginEvent(self.script_id)
        self:AddText("#{XLPF_110520_02}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if Operation == 107 then
        self:UpdateEventList(selfId, targetId)
        return
    end
end

function odali_saodiseng:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function odali_saodiseng:NotifyTip(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function odali_saodiseng:AwardXiuLianTitle(selfId, targetId)
    local level = self:GetHumanMaxXiulianLevel(selfId)
    if level >= 3 then
        self:LuaFnAwardTitle(selfId, 45, title_ids[level])
    else
        self:BeginEvent(self.script_id)
        self:AddText("#{XL_090707_45}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

return odali_saodiseng
