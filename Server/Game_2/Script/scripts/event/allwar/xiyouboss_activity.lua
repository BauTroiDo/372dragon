local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local xiyouboss_activity = class("xiyouboss_activity", script_base)
xiyouboss_activity.script_id = 999983
xiyouboss_activity.DataValidator = 0

xiyouboss_activity.GoBackScene = 0
xiyouboss_activity.GoBackPosx = 160
xiyouboss_activity.GoBackPosz = 105

xiyouboss_activity.timetab = {
    [818] = { actname = "Thiên Hạ Anh Hùng Hội", bossId = 55102, posx = 255, posz = 83, finalBossId = 55100,
              openhour = 15, openmin = 0, closehour = 17, closemin = 0,
              wave1min = 5, wave2min = 35, finalmin = 55, bosshp = -1, finalbosshp = -1 },
    [814] = { actname = "Huyết chiến Lăng Vân Quật", bossId = 55101, posx = 95, posz = 81, finalBossId = 55099,
              openhour = 21, openmin = 0, closehour = 23, closemin = 0,
              wave1min = 5, wave2min = 35, finalmin = 5, bosshp = -1, finalbosshp = -1 },
}

xiyouboss_activity.act_isopen = 2
xiyouboss_activity.act_wave = 16

function xiyouboss_activity:OnTimer(actId, uTime, param1)
end

function xiyouboss_activity:OnTimer_Second(actId, minute, hminute, hour)
    if not actId or actId >= 0 then return end
    local newId = -1 * actId
    if define.ACTIVITY_XIYOU_ID ~= newId then return end

    local scene = self:get_scene()
    if not scene then return end
    local sceneId = scene:get_id()
    local params = scene:get_activity_scene_param(newId)
    if not params then return end

    local actinfo = self.timetab[sceneId]
    if not actinfo then return end

    local open_hmin = actinfo.openhour * 60 + actinfo.openmin
    local close_hmin = actinfo.closehour * 60 + actinfo.closemin

    if hminute >= open_hmin and hminute < close_hmin then
        if not params[self.act_isopen] then
            params[self.act_isopen] = 1
            params[self.act_wave] = 0
            local msg = string.format("@*;SrvMsg;SCA:#cffcc00[%s]#P đã mở, chư vị anh hùng mau tới khiêu chiến!", actinfo.actname)
            self:AddGlobalCountNews(msg)
        end

        local wave = params[self.act_wave] or 0
        if wave == 0 and minute >= actinfo.wave1min then
            self:SpawnWave(sceneId, 6, actinfo.bossId, actinfo.bosshp, false, -1)
            params[self.act_wave] = 1
            local msg = string.format("@*;SrvMsg;SCA:#cff9900[Quần anh tập kích]#P #G%s#Pđợt một #cff0000Boss#Pxuất hiện! Mau tới nghênh chiến!", actinfo.actname)
            self:AddGlobalCountNews(msg)
        end
        if wave == 1 and minute >= actinfo.wave2min then
            self:SpawnWave(sceneId, 6, actinfo.bossId, actinfo.bosshp, false, -1)
            params[self.act_wave] = 2
            local msg = string.format("@*;SrvMsg;SCA:#cff9900[Quần anh tập kích]#P #G%s#Pđợt hai #cff0000Boss#Pxuất hiện! Địch mạnh hơn ập tới!", actinfo.actname)
            self:AddGlobalCountNews(msg)
        end
        if wave == 2 and minute >= actinfo.finalmin then
            self:SpawnWave(sceneId, 1, actinfo.finalBossId, actinfo.finalbosshp, true, 999982)
            params[self.act_wave] = 3
            local msg = string.format("@*;SrvMsg;SCA:#cff0000[Boss tối thượng]#P #cffff00★Boss tối thượng★#P của #G%s#P xuất hiện! Người đánh bại nhận thưởng hậu hĩnh!", actinfo.actname)
            self:AddGlobalCountNews(msg)
        end
    else
        if params[self.act_isopen] then
            self:ClearAllMonsters()
            params[self.act_isopen] = 0
            self:StopOneActivity(newId)
            local msg = string.format("@*;SrvMsg;SCA:#cffcc00[%s]#P kết thúc, cảm ơn các dũng sĩ tham gia!", actinfo.actname)
            self:AddGlobalCountNews(msg)
        end
    end
end

function xiyouboss_activity:SpawnWave(sceneId, count, bossId, hp, isFinal, scriptId)
    local scene = self:get_scene()
    local actinfo = self.timetab[sceneId]
    if not actinfo then return end
    local spread = 15
    local base_x = actinfo.posx
    local base_z = actinfo.posz
    for i = 1, count do
        local posx = base_x + math.random(-spread, spread)
        local posz = base_z + math.random(-spread, spread)
        local objId = self:LuaFnCreateMonster(bossId, posx, posz, 4, 0, scriptId or -1)
        if objId then
            local obj = scene:get_obj_by_id(objId)
            if obj then
                if hp > 0 then
                    self:LuaFnSetLifeTimeAttrRefix_MaxHP(objId, hp)
                    self:RestoreHp(objId)
                end
                obj:set_scene_params(define.MONSTER_DATAID, bossId)
                obj:set_reputation(29)
            end
        end
    end
end

function xiyouboss_activity:ClearAllMonsters()
    local scene = self:get_scene()
    local monsters = {}
    local humans = {}
    for _, obj in pairs(scene.objs) do
        if obj and obj:get_obj_type() == "monster" and obj:is_alive() then
            monsters[#monsters + 1] = obj
        elseif obj and obj:get_obj_type() == "human" then
            humans[#humans + 1] = obj:get_obj_id()
        end
    end
    for _, obj in ipairs(monsters) do
        scene:delete_temp_monster(obj)
    end
    for _, objId in ipairs(humans) do
        self:NewWorld(objId, self.GoBackScene, nil, self.GoBackPosx, self.GoBackPosz)
    end
end

function xiyouboss_activity:StartActivity(actId)
    if not actId or actId >= 0 then return end
    local newId = -1 * actId
    if define.ACTIVITY_XIYOU_ID ~= newId then return end
    if self:HaveActivity(newId) then return end
    self:StartOneActivity(newId, 2100000000, 0, -1)
end

function xiyouboss_activity:CheckActiviyIsOpen()
    local scene = self:get_scene()
    if not scene then return false end
    local sceneId = scene:get_id()
    local info = self.timetab[sceneId]
    if not info then return false end
    local params = scene:get_activity_scene_param(define.ACTIVITY_XIYOU_ID)
    if not params then return false end
    return params[self.act_isopen] and params[self.act_isopen] > 0
end

function xiyouboss_activity:CheckActiviyParticipation(selfId)
    local scene = self:get_scene()
    if not scene then return "Cảnh hoạt động bất thường." end
    local sceneId = scene:get_id()
    local info = self.timetab[sceneId]
    if not info then return "Cảnh hiện tại không có hoạt động." end
    local params = scene:get_activity_scene_param(define.ACTIVITY_XIYOU_ID)
    if not params or not params[self.act_isopen] or params[self.act_isopen] <= 0 then
        return "Hoạt động chưa mở."
    end
    local obj = scene:get_obj_by_id(selfId)
    if not obj or not obj:is_alive() then
        return "Ngươi đã chết."
    end
    return 0
end

function xiyouboss_activity:EnsureActivityOpen()
    local scene = self:get_scene()
    if not scene then return end
    local sceneId = scene:get_id()
    local info = self.timetab[sceneId]
    if not info then return end
    if not self:HaveActivity(define.ACTIVITY_XIYOU_ID) then
        self:StartActivity(-398)
    end
    local t = os.date("*t")
    local hminute = t.hour * 60 + t.min
    if hminute >= info.openhour * 60 + info.openmin and hminute < info.closehour * 60 + info.closemin then
        local params = scene:get_activity_scene_param(define.ACTIVITY_XIYOU_ID)
        if params and not params[self.act_isopen] then
            params[self.act_isopen] = 1
        end
    end
end

function xiyouboss_activity:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
    if param6 ~= self.DataValidator then return end
    if not self:HaveActivity(define.ACTIVITY_XIYOU_ID) then
        self:StartActivity(-398)
    end
end

function xiyouboss_activity:GetDataValidator(param1, param2)
    self.DataValidator = math.random(1, 2100000000)
    return self.DataValidator
end

return xiyouboss_activity
