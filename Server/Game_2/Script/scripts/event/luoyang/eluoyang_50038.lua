local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local eluoyang_50038 = class("eluoyang_50038", script_base)
eluoyang_50038.script_id = 250038
eluoyang_50038.g_eventId_updateJoinList = -1
eluoyang_50038.g_invitationDataId_level1 = 30303100
eluoyang_50038.g_invitationDataId_level2 = 30303101
eluoyang_50038.g_invitationDataId_level3 = 30303102
function eluoyang_50038:OnDefaultEvent(selfId, targetId, index)
    local selectEventId = index
    if selectEventId then
        if selectEventId == self.g_eventId_updateJoinList then
            self:OnUpdateJoinList(selfId, targetId)
        else
            local creatorGUID = index
            self:OnJoin(selfId, targetId, creatorGUID)
        end
    end
end

function eluoyang_50038:OnEnumerate(caller)
    caller:AddNumTextWithTarget(self.script_id, "Tham gia hôn lễ", 6, self.g_eventId_updateJoinList)
end

function eluoyang_50038:OnUpdateJoinList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local addText = 0
    local selfGUID = self:LuaFnGetGUID(selfId)
    local destSceneId = self:FindCopySceneIDByCopySceneParams(ScriptGlobal.FUBEN_WEDDING, 1, 6, selfGUID)
    if destSceneId and destSceneId >= 0 then
    else
        destSceneId = self:FindCopySceneIDByCopySceneParams(ScriptGlobal.FUBEN_WEDDING, 1, 7, selfGUID)
    end
    local creatorNum = 0
    local creatorList = {}
    if destSceneId and destSceneId ~= -1 then
        if addText == 0 then
            self:AddText("Xin chọn hôn lễ mà ngươi muốn tham gia!")
            addText = 1
        end
        creatorList[creatorNum + 1] = selfGUID
        creatorNum = creatorNum + 1
        self:AddNumText("Hãy để ta trở lại Phó bản hôn lễ của ta.", 9, selfGUID)
    end
    local itemIdList = {
        self.g_invitationDataId_level3, self.g_invitationDataId_level2,
        self.g_invitationDataId_level1
    }
    local itemPos
    for _, itemId in pairs(itemIdList) do
        local maxCount
        maxCount = 100
        itemPos = 0
        for i = 1, maxCount do
            itemPos = self:LuaFnGetItemPosByItemDataID(selfId, itemId, itemPos)
            if itemPos and itemPos > -1 then
                local creatorName = self:LuaFnGetItemCreator(selfId, itemPos)
                if creatorName then
                    local creatorGUID = self:GetBagItemParam(selfId, itemPos, 0, 2)
                    if addText == 0 then
                        self:AddText("Xin chọn hôn lễ mà ngươi muốn tham gia!")
                        addText = 1
                    end
                    local bFind
                    bFind = 0
                    for _, findGUID in pairs(creatorList) do
                        if findGUID == creatorGUID then
                            bFind = 1
                            break
                        end
                    end
                    if bFind == 0 then
                        creatorList[creatorNum + 1] = creatorGUID
                        creatorNum = creatorNum + 1
                        self:AddNumText("tham gia" .. creatorName .. "Hôn lễ của ta", 8, creatorGUID)
                    end
                end
                itemPos = itemPos + 1
            else
                break
            end
        end
    end
    if addText == 0 then
        self:AddText("Ngươi không có thiệp mời kết hôn, không thể tham gia bất kỳ hôn lễ nào.")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function eluoyang_50038:OnJoin(selfId, targetId, creatorGUID)
    self:CallScriptFunction(401030, "PlayerEnter", selfId, targetId, creatorGUID)
end

function eluoyang_50038:MessageBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return eluoyang_50038
