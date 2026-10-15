local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4926 = class("item_4926", script_base)
item_4926.script_id = 334926
function item_4926:OnDefaultEvent(selfId, bagIndex)
    local sceneId = self:get_scene_id()
    if sceneId and selfId and bagIndex then
        local selfGUID = self:LuaFnGetGUID(selfId)
        local targetGUID = self:GetBagItemParam(selfId, bagIndex, 0, "uint")
        if selfGUID and targetGUID then
            self:BeginEvent(self.script_id)
            if selfGUID == targetGUID then
                self:AddText("Đây là thiệp cưới của chính bạn. Hãy dùng nó để tham gia hôn lễ của mình, mau phát cho bằng hữu của ngươi đi thôi.")
            else
                local targetName = self:LuaFnGetItemCreator(selfId, bagIndex)
                if targetName then
                    self:AddText(
                        "Đây là" .. targetName .. "Thiệp mời gửi đến quý bằng hữu. Có thể sử dụng tại #GLạc Dương (177,94)#RHỷ Lai Lạc#W để tham gia hôn lễ.#rTrước khi hôn lễ kết thúc, Có thể sử dụng tại hội trường hôn lễ tìm Hỷ Lai Lạc dùng thiệp mời đổi lễ vật đó nha."
                    )
                else
                    self:AddText("Đây là thiệp mời từ một nhân vật vô danh gửi đến quý bằng hữu. Có thể sử dụng tại thiệp này để tham gia hôn lễ, nhớ sau khi hôn lễ kết thúc có thể dùng thiệp mời để đổi thưởng.")
                end
            end
            self:EndEvent()
            self:DispatchEventList(selfId, selfId)
        end
    end
    return 0
end

function item_4926:IsSkillLikeScript(selfId)
    return 0
end

function item_4926:CancelImpacts(selfId)
    return 0
end

function item_4926:OnConditionCheck(selfId)
    return 1
end

function item_4926:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4926:OnActivateOnce(selfId)
    return 1
end

function item_4926:OnActivateEachTick(selfId)
    return 1
end

return item_4926
