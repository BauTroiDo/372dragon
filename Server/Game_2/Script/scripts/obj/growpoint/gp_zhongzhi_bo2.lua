local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_zhongzhi_bo2 = class("gp_zhongzhi_bo2", script_base)
gp_zhongzhi_bo2.g_GpId = 547
gp_zhongzhi_bo2.g_GpIdNext = 548
function gp_zhongzhi_bo2:OnRecycle(selfId, targetId)
    local itemBoxX = self:GetItemBoxWorldPosX(targetId)
    local itemBoxZ = self:GetItemBoxWorldPosZ(targetId)
    local ItemBoxId = self:ItemBoxEnterScene(itemBoxX, itemBoxZ, self.g_GpIdNext, define.QUALITY_MUST_BE_CHANGE, 1, 20105004)
    local ItemBoxOwnerGUID = self:GetItemBoxOwner(targetId)
    self:SetItemBoxOwner(ItemBoxId, ItemBoxOwnerGUID)
    self:SetItemBoxPickOwnerTime(ItemBoxId, 600000)
    self:EnableItemBoxPickOwnerTime(ItemBoxId)
    self:SetItemBoxMaxGrowTime(ItemBoxId, 600000)
    local GP_X = self:GetItemBoxWorldPosX(targetId)
    local GP_Z = self:GetItemBoxWorldPosZ(targetId)
    GP_X = math.floor(GP_X)
    GP_Z = math.floor(GP_Z)
    local sceneId = self:get_scene():get_id()
    local num = 0
    for i, findid in pairs(ScriptGlobal.PLANTNPC_ADDRESS) do
        if
            (GP_X >= findid["X_MIN"]) and (GP_Z >= findid["Z_MIN"]) and (GP_X <= findid["X_MAX"]) and
                (GP_Z <= findid["Z_MAX"]) and
                (sceneId == findid["Scene"])
         then
            num = i
            break
        end
    end
    if num == 0 then
        return
    end
    if ScriptGlobal.PLANTFLAG[num] == 8 then
        self:LuaFnSendMailToGUID(ItemBoxOwnerGUID, "Cây trồng của ngươi đã trưởng thành, xin thu hoạch trong vòng 10 phút.")
    end
    ScriptGlobal.PLANTFLAG[num] = ScriptGlobal.PLANTFLAG[num] - 1
    return 1
end

return gp_zhongzhi_bo2
