local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_yunqingqing = class("oluoyang_yunqingqing", script_base)
oluoyang_yunqingqing.g_shoptableindex = 102
function oluoyang_yunqingqing:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

function oluoyang_yunqingqing:OnCharacterTimer(selfId, dataId, uTime)
    local curX, curZ = self:GetWorldPos(selfId)
    if curX <= 173 and curX >= 171 and curZ <= 142 and curZ >= 140 then
        self:SetPos(selfId, 235, 140)
    elseif curX <= 236 and curX >= 234 and curZ <= 141 and curZ >= 139 then
        self:SetPos(selfId, 116, 177)
    elseif curX <= 117 and curX >= 115 and curZ <= 178 and curZ >= 176 then
        self:SetPos(selfId, 172, 141)
    else
        self:SetPos(selfId, 172, 141)
    end
end

return oluoyang_yunqingqing
