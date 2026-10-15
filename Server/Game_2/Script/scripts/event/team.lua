local skynet = require "skynet"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local team = class("team", script_base)
team.script_id = 400900
team.g_Impact_No_ChangeScene = 38
team.g_Yinpiao = 40002000
-- 2026-09-11: kiểm tra cảnh đích có đang chạy trên máy chủ không. Nếu không kiểm tra, msgagent sẽ
-- không tìm thấy .SCENE_<id> khi vào lại và đưa người chơi về cảnh mặc định (2 = Đại Lý).
function team:IsSceneAvailable(sceneId)
    sceneId = tonumber(sceneId)
    if not sceneId then
        return false
    end
    if sceneId == self:get_scene_id() then
        return true
    end
    local name = string.format(".SCENE_%d", sceneId)
    if skynet.localname(name) then
        return true
    end
    if sceneId >= 10000 then
        return false
    end
    local ok, ready = pcall(skynet.call, ".SceneManager", "lua", "ensure_scene", sceneId)
    if ok and ready and skynet.localname(name) then
        return true
    end
    local ok2, sid = pcall(skynet.call, ".Dynamicscenemanager", "lua", "ensure_city_scene", sceneId)
    if ok2 and tonumber(sid) == sceneId and skynet.localname(name) then
        return true
    end
    return false
end

-- Được gọi nhiều chỗ trong TransferFunc/CheckChangeScene nhưng chưa từng được định nghĩa (lỗi nil method).
function team:NotifyFailTips(selfId, tip)
    if tip and tip ~= "" then
        self:notify_tips(selfId, tip)
    end
end

function team:TransferFunc(selfId, newSceneId, posX, posY, minLevel, maxLevel)
    local initiatingHuman = self.scene:get_obj_by_id(selfId)
    if not initiatingHuman then return end
    -- CYS-ROUND2: retain the gate script's conditions; correct only a matching
    -- walking gate's CY arrival. NPC transfers away from a gate are unchanged.
    local gateX,gateZ=self:GetWorldPos(selfId)
    posX,posY=require("scripts.event.chuansong.cys_walk_portals").resolve(
        self:get_scene_id(),gateX,gateZ,newSceneId,posX,posY)

    --minLevel = nil
    --maxLevel = nil
    skynet.logi("[AUTO_ROUTE_TRANSFER] scene=", tostring(self:get_scene_id()),
        " self=", tostring(selfId), " to=", tostring(newSceneId),
        " x=", tostring(posX), " y=", tostring(posY),
        " min_level=", tostring(minLevel), " max_level=", tostring(maxLevel))
    if not self:IsSceneAvailable(newSceneId) then
        skynet.loge("[AUTO_ROUTE_TRANSFER_UNAVAILABLE] scene=", tostring(self:get_scene_id()),
            " self=", tostring(selfId), " to=", tostring(newSceneId))
        self:notify_tips(selfId, string.format("Bản đồ đích (cảnh %s) chưa mở trên máy chủ, không thể truyền tống.", tostring(newSceneId)))
        return
    end
    if self:LuaFnGetDestSceneHumanCount(newSceneId) > 500 then
        self:notify_tips(selfId, "Cảnh đích đã đủ người")
        return
    end
    if self.scene:get_obj_by_id(selfId) ~= initiatingHuman then return end
    if newSceneId == 2 then
        minLevel = 1
    end
    if minLevel == nil then
        minLevel = 10
    end
    local humanList = {}
    local humanCount = 0
    local selfHasDRideFlag = self:LuaFnGetDRideFlag(selfId)
    if selfHasDRideFlag then
        local selfIsDRideMountOwner = self:LuaFnIsDRideMountOwner(selfId)
        if not selfIsDRideMountOwner then
            return
        end
    end
    local selfHasTeamFlag = self:LuaFnHasTeam(selfId)
    if selfHasTeamFlag then
        local teamFollowFlag = self:IsTeamFollow(selfId)
        local teamLeaderFlag = self:LuaFnIsTeamLeader(selfId)
        if not teamLeaderFlag and teamFollowFlag then
            return
        end
        if teamLeaderFlag then
            if teamFollowFlag then
                local followMemberCount = self:LuaFnGetFollowedMembersCount(selfId)
                local followMembers = {}
                for i = 1, followMemberCount do
                    followMembers[i] = self:GetFollowedMember(selfId, i)
                    if followMembers[i] and followMembers[i] ~= -1 then
                        if followMembers[i] ~= selfId and self:IsHaveMission(followMembers[i], 4021) then
                            self:NotifyFailTips(selfId, "Các hạ còn có đồng đội đang trong Trạng thái Vận Tiêu, không thể truyền tống.")
                            return
                        end
                        if followMembers[i] ~= selfId and self:GetItemCount(followMembers[i], self.g_Yinpiao) >= 1 then
                            self:NotifyFailTips(selfId, "Các hạ còn có đồng đội đang trong Trạng thái Chạy Thương, không thể truyền tống.")
                            return
                        end
                        local memberHasDRideFlag = self:LuaFnGetDRideFlag(followMembers[i])
                        if memberHasDRideFlag then
                            local memberIsDRideMountOwner = self:LuaFnIsDRideMountOwner(followMembers[i])
                            if memberIsDRideMountOwner then
                            else
                                self:NotifyFailTips(selfId, "Song nhân cưỡi ngựa không thể cùng tổ đội đi theo cùng tồn tại.")
                                return
                            end
                        end
                        humanCount = humanCount + 1
                        humanList[humanCount] = followMembers[i]
                    else
                        self:NotifyFailTips(selfId, "Các hạ còn có đồng đội chưa đến bản cảnh, tạm thời không thể rời đi.")
                        return
                    end
                end
            else
                humanCount = humanCount + 1
                humanList[humanCount] = selfId
            end
        else
            if teamFollowFlag then
                -- Reject a stale follow request without crashing the scene.
                return
            end
            humanCount = humanCount + 1
            humanList[humanCount] = selfId
        end
    else
        humanCount = humanCount + 1
        humanList[humanCount] = selfId
    end
    local saveHumanCount = humanCount
    for i = 1, saveHumanCount do
        local tempHumanId = humanList[i]
        local drideFlag = self:LuaFnGetDRideFlag(tempHumanId)
        if drideFlag then
            local isDRideMountOwner = self:LuaFnIsDRideMountOwner(tempHumanId)
            if isDRideMountOwner then
                local drideTargetID = self:LuaFnGetDRideTargetID(tempHumanId)
                if drideTargetID and drideTargetID ~= -1 then
                    if drideTargetID ~= selfId and self:IsHaveMission(drideTargetID, 4021) then
                        self:NotifyFailTips(selfId, "Các hạ hoặc đội đi theo của các hạ có người song nhân cưỡi ngựa của đối phương đang trong Trạng thái Vận Tiêu, không thể truyền tống.")
                        return
                    end
                    if drideTargetID ~= selfId and self:GetItemCount(drideTargetID, self.g_Yinpiao) >= 1 then
                        self:NotifyFailTips(selfId, "Ngài hoặc đội ngũ đi theo ngài có người đang trong Trạng thái chạy thương bằng song nhân tọa kỵ, không thể truyền tống.")
                        return
                    end
                    humanCount = humanCount + 1
                    humanList[humanCount] = drideTargetID
                end
            else
                return
            end
        end
    end
    -- Pin object identity and party membership before validation can yield.
    local transferMembers = {}
    for _,id in ipairs(humanList) do
        local h = self.scene:get_obj_by_id(id)
        if not h then return end
        if transferMembers[id] then return end
        transferMembers[id] = {human=h,team=h:get_team_id(),follow=h:get_team_follow_flag()}
    end
    for _, checkHumanId in pairs(humanList) do
        local checkRet, errorTips, errorSelfTips =
            self:CheckChangeScene(checkHumanId, newSceneId, posX, posY, minLevel, maxLevel)
        if checkRet and checkRet == 1 then
        else
            if errorTips then
                self:NotifyFailTips(checkHumanId, errorTips)
            end
            if checkHumanId ~= selfId and errorSelfTips then
                self:NotifyFailTips(selfId, errorSelfTips)
            end
            -- Reject a stale follow request without crashing the scene.
            return
        end
    end
    for id,v in pairs(transferMembers) do
        if self.scene:get_obj_by_id(id) ~= v.human or v.human:get_team_id() ~= v.team or v.human:get_team_follow_flag() ~= v.follow or v.human:is_die() then
            self:NotifyFailTips(selfId, "Đội đã thay đổi trong lúc chuyển cảnh; hãy thử lại.")
            return
        end
    end
    local sceneId = self:get_scene_id()
    if sceneId ~= newSceneId then
        for _, checkHumanId in pairs(humanList) do
            self:NewWorld(checkHumanId, newSceneId, nil, posX, posY)
        end
    else
        for _, checkHumanId in pairs(humanList) do
            self:SetPos(checkHumanId, posX, posY)
        end
    end
end

function team:TransferFuncFromNpc(selfId, newSceneId, posX, posY, minLevel, maxLevel)
    if self:IsHaveMission(selfId, 4021) then
        self:BeginEvent(self.script_id)
        local strText = "Ngài đang trong Trạng thái Tào Vận, không thể sử dụng chức năng truyền tống."
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    elseif self:LuaFnHaveImpactOfSpecificDataIndex(selfId, 113) then
        self:BeginEvent(self.script_id)
        local strText = "Ngài đang trong Trạng thái chạy thương, không thể sử dụng chức năng truyền tống."
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    else
        self:TransferFunc(selfId, newSceneId, posX, posY, minLevel, maxLevel)
    end
end

function team:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function team:CheckChangeScene(selfId, newSceneId, posX, posY, minLevel, maxLevel)
    if newSceneId ~= 2 then
        if minLevel == nil then
            minLevel = 10
        end
    end
    if not selfId or not newSceneId or not posX or not posY then
        return 0, "Yêu cầu truyền tống không hợp lệ, không thể truyền tống.", "Yêu cầu truyền tống không hợp lệ, không thể truyền tống."
    end
    local selfLevel = self:LuaFnGetLevel(selfId)
    if not selfLevel then
        return 0, "Yêu cầu truyền tống không hợp lệ, không thể truyền tống.", "Yêu cầu truyền tống không hợp lệ, không thể truyền tống."
    end
    local livingFlag = self:LuaFnIsCharacterLiving(selfId)
    if not livingFlag then
        return 0, "Ngươi đã Tử vong, không thể truyền tống.", self:GetName(selfId).."Đã Tử vong, không thể truyền tống."
    end
    if minLevel and selfLevel < minLevel then
        return 0,  "Cấp bậc của ngươi chưa đủ."..tostring(minLevel)..", không thể truyền tống.", self:GetName(selfId).."Cấp bậc của ngươi chưa đủ."..tostring(minLevel)..", không thể truyền tống."
    end
    if maxLevel and selfLevel >= maxLevel then
        return 0, "Cấp bậc của ngươi phải nhỏ hơn."..tostring(maxLevel)..", mới có thể truyền tống.", self:GetName(selfId).."Cấp bậc của ngươi phải nhỏ hơn."..tostring(maxLevel)..", mới có thể truyền tống."
    end
    local changeSceneImpactCheck = self:LuaFnHaveImpactOfSpecificDataIndex(selfId, self.g_Impact_No_ChangeScene)
    if changeSceneImpactCheck then
        return 0, "Hiện tại ngươi vẫn chưa thể rời đi.", self:GetName(selfId).."Hiện tại vẫn chưa thể rời đi."
    end
    return 1
end

return team
