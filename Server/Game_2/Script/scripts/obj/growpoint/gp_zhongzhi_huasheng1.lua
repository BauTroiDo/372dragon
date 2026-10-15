local class = require "class"
local define = require "define"
local script_base = require "script_base"
local gp_zhongzhi_huasheng1 = class("gp_zhongzhi_huasheng1", script_base)
gp_zhongzhi_huasheng1.g_GpId = 510
gp_zhongzhi_huasheng1.g_GpIdNext = 511
function gp_zhongzhi_huasheng1:OnRecycle(selfId, targetId)
    local itemBoxX = self:GetItemBoxWorldPosX(targetId)
    local itemBoxZ = self:GetItemBoxWorldPosZ(targetId)
    local ItemBoxId = self:ItemBoxEnterScene(itemBoxX, itemBoxZ, self.g_GpIdNext, define.QUALITY_MUST_BE_CHANGE, 0)
    local ItemBoxOwnerGUID = self:GetItemBoxOwner(targetId)
    self:SetItemBoxOwner(ItemBoxId, ItemBoxOwnerGUID)
    self:SetItemBoxMaxGrowTime(ItemBoxId, 450000)
    return 1
end

return gp_zhongzhi_huasheng1
