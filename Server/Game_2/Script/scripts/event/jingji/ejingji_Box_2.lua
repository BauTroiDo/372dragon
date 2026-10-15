local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ejingji_Box_2 = class("ejingji_Box_2", script_base)
ejingji_Box_2.script_id = 125023
ejingji_Box_2.g_SmallBoxBuff = {
    {["id"] = 1, ["name"] = "紫色秘笈", ["buff"] = 8053},
    {["id"] = 2, ["name"] = "黄色秘笈", ["buff"] = 8052},
    {["id"] = 3, ["name"] = "绿色秘笈", ["buff"] = 8051},
    {["id"] = 4, ["name"] = "白色秘笈", ["buff"] = 8050},
    {["id"] = 5, ["name"] = "黑色秘笈", ["buff"] = 8049},
    {["id"] = 6, ["name"] = "蓝色秘笈", ["buff"] = 8048},
    {["id"] = 7, ["name"] = "红色秘笈", ["buff"] = 8047}

}
function ejingji_Box_2:OnActivateConditionCheck(selfId, activatorId) return 1 end
function ejingji_Box_2:OnActivateDeplete(selfId, activatorId) return 1 end
function ejingji_Box_2:OnActivateEffectOnce(selfId, activatorId)
    local szName = self:GetName(selfId)
    for i = 1, #(self.g_SmallBoxBuff) do
        if szName == self.g_SmallBoxBuff[i]["name"] then
            self:LuaFnDeleteMonster(selfId)
            self:LuaFnSendSpecificImpactToUnit(activatorId, activatorId, activatorId,    self.g_SmallBoxBuff[i]["buff"], 100)
        end
    end
    return 1
end

function ejingji_Box_2:OnActivateEffectEachTick(selfId, activatorId) return 1 end

function ejingji_Box_2:OnActivateActionStart(selfId, activatorId) return 1 end

function ejingji_Box_2:OnActivateCancel(selfId, activatorId) return 0 end

function ejingji_Box_2:OnActivateInterrupt(selfId, activatorId) return 0 end

function ejingji_Box_2:OnActivateInterrupt(selfId, activatorId) end

return ejingji_Box_2
