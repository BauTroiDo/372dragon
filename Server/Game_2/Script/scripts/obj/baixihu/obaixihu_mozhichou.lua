local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local obaixihu_mozhichou = class("obaixihu_mozhichou", script_base)
obaixihu_mozhichou.g_eventList = { 888808 }

local factions = {
    { id = 1, ability = 54, name = "Bạch Khê Hồ", pres = { 1154, 1155, 1160, 1161, 1166, 1167, 1172, 1173, 1178, 1179, 1184, 1185 } },
    { id = 2, ability = 55, name = "Thục Nam Trúc Hải", pres = { 1156, 1157, 1162, 1163, 1168, 1169, 1174, 1175, 1180, 1181, 1186, 1187 } },
    { id = 3, ability = 56, name = "Tây Lương Phong Lâm", pres = { 1158, 1159, 1164, 1165, 1170, 1171, 1176, 1177, 1182, 1183, 1188, 1189 } },
}

function obaixihu_mozhichou:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{SWXT_221213_1}")
    for _, f in ipairs(factions) do
        self:AddNumText("Gia nhập phe -" .. f.name, 6, 10 + f.id)
    end
    self:AddNumText("#{SWXT_221213_3}", 11, 2)
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function obaixihu_mozhichou:OnEventRequest(selfId, targetId, arg, index)
    for _, f in ipairs(factions) do
        if index == 10 + f.id then
            local cur = self:GetMissionData(selfId, ScriptGlobal.LingWuLiuPai) or 0
            if cur == f.id then
                self:notify_tips(selfId, "Đã tham gia" .. f.name .. ", không thể vào lặp lại")
                return
            end
            self:SetMissionData(selfId, ScriptGlobal.LingWuLiuPai, f.id)
            self:SetHumanAbilityLevel(selfId, f.ability, 1)
            for _, p in ipairs(f.pres) do
                self:SetPrescription(selfId, p, 1)
            end
            self:notify_tips(selfId, "Gia nhập" .. f.name)
            return
        end
    end
    if index == 2 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SWXT_221213_221}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

return obaixihu_mozhichou