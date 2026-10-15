local class = require "class"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local skynet = require "skynet"

local daluandou_main = class("daluandou_main", script_base)

daluandou_main.script_id = 999861

daluandou_main.config = {
    scene_id = 413,
    timer_script_id = 999860,
    npc_script_id = 999862,
    plane_time = 2029, -- 预告飞机
    start_time = 2030, -- 开战
    end_time = 2100,   -- 结束
    leave_time = 2130, -- 主动离场时间
	
    -- plane_time = 1309, -- 预告飞机
    -- start_time = 1310, -- 开战
    -- end_time = 1330,   -- 结束
    -- leave_time = 1340, -- 主动离场时间
	
	
	
    -- CYS-NAVMIN 19/09: dich (91,180) canh 0 nam trong tam giac BI CHAN cua navmesh (sau 7.10 o). Nhanh nay hien KHONG toi duoc — cua chan: C4 (canh nguon 413 大乱斗 active=0 VA khong co daluandou.scn). MUON MO LAI: SUA TOA DO TRUOC, lay tu nguon co tham quyen (vi tri quai/NPC trong <map>_monster.ini, diem hoi sinh, hay mot dich da kiem), KHONG tu tinh tu .path. Chi tiet: Timeline/handoff/transfer-navmesh.md muc 3.6 + Build/Logs/2026-09-19-transfer-navmesh/97-bai-min.tsv
    leave_pos = {scene = 0, x = 91, z = 180},
    settle_npc = {data_id = 54885, x = 47, z = 48, live_ms = 3600000},
    rank_award = {[1] = 100, [2] = 90, [3] = 80},
}


function daluandou_main:GetRandomRelivePos()
    return {x = math.random(30, 60), z = math.random(30, 60)}
end

function daluandou_main:closebox(selfId, msg)
    if msg and msg ~= "" then
        self:notify_tips(selfId, msg)
    end
    self:BeginUICommand()
    self:EndUICommand()
    self:DispatchUICommand(selfId, 410142021)
end

-- 是否在战斗时间段
function daluandou_main:IsOpenNow()
    local t = os.date("*t")
    local now_hminute = t.hour * 60 + t.min
    local start_h = math.floor((tonumber(self.config.start_time) or 0) / 100)
    local start_m = (tonumber(self.config.start_time) or 0) % 100
    local end_h = math.floor((tonumber(self.config.end_time) or 0) / 100)
    local end_m = (tonumber(self.config.end_time) or 0) % 100
    local start_hminute = start_h * 60 + start_m
    local end_hminute = end_h * 60 + end_m
    return now_hminute >= start_hminute and now_hminute < end_hminute
end

-- 是否允许加入（20:29-21:30）
function daluandou_main:IsJoinWindowNow()
    local t = os.date("*t")
    local now_hminute = t.hour * 60 + t.min
    local plane_h = math.floor((tonumber(self.config.plane_time) or 0) / 100)
    local plane_m = (tonumber(self.config.plane_time) or 0) % 100
    local end_h = math.floor((tonumber(self.config.end_time) or 0) / 100)
    local end_m = (tonumber(self.config.end_time) or 0) % 100
    local plane_hminute = plane_h * 60 + plane_m
    local end_hminute = end_h * 60 + end_m
    return now_hminute >= plane_hminute and now_hminute <= end_hminute
end

function daluandou_main:Gotodaluandou(selfId)
    local t = os.date("*t")
    local now_hhmm = t.hour * 100 + t.min
    if now_hhmm ~= self.config.plane_time then
        self:closebox(selfId, "Truyền tống đã hết hiệu lực.")
        return
    end
    local pos = self:GetRandomRelivePos()
    self:closebox(selfId)
    if self.config.scene_id == self.scene:get_id() then
        self:TelePort(selfId, pos.x, pos.z)
    else
        self:NewWorld(selfId, self.config.scene_id, nil, pos.x, pos.z)
    end
end
function daluandou_main:daluandou_box(selfId, goings)
	-- skynet.logw("是不是都没有调用哇。。。。")
    if not selfId or selfId <= 0 then
        return
    end
    --清理连杀数据
    self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_DaLuanDouLS, 0) 

    self:BeginUICommand()
    self:UICommand_AddInt(self.script_id)
    self:UICommand_AddStr("Gotodaluandou")
    self:UICommand_AddStr("#YĐại Loạn Đấu sắp bắt đầu, tới ngay không?")
    self:EndUICommand()
    self:DispatchUICommand(selfId, 24)
end

function daluandou_main:JoinBattle(selfId)
    if not self:IsJoinWindowNow() then
        self:notify_tips(selfId, "Giờ truyền tống: 20:29-21:00")
        return false
    end
    local pos = self:GetRandomRelivePos()
    self:NewWorld(selfId, self.config.scene_id, nil, pos.x, pos.z)
    return true
end

function daluandou_main:LeaveBattle(selfId)
    local t = os.date("*t")
    local now_hhmm = t.hour * 100 + t.min
    if now_hhmm < (tonumber(self.config.end_time) or 2130) then
        self:notify_tips(selfId, "Hoạt động kết thúc mới tự truyền tống rời được.")
        return false
    end
    local p = self.config.leave_pos
    self:NewWorld(selfId, p.scene, nil, p.x, p.z)
    return true
end

function daluandou_main:OnBattlePlayerEnter(selfId)
    if self:GetSceneID() ~= self.config.scene_id then
        return
    end
    local pos = self:GetRandomRelivePos()
    self:SetPlayerDefaultReliveInfo(selfId, 1, 1, 1, self.config.scene_id, pos.x, pos.z)

    local t = os.date("*t")
    local now_hminute = t.hour * 60 + t.min
    local start_h = math.floor((tonumber(self.config.start_time) or 0) / 100)
    local start_m = (tonumber(self.config.start_time) or 0) % 100
    local end_h = math.floor((tonumber(self.config.end_time) or 0) / 100)
    local end_m = (tonumber(self.config.end_time) or 0) % 100
    local start_hminute = start_h * 60 + start_m
    local end_hminute = end_h * 60 + end_m

    -- 进入时只有在开战区间才给个人阵营；预告阶段(20:29)不提前给
    if now_hminute >= start_hminute and now_hminute < end_hminute then
        self:SetPlayerPvpRule(selfId, 9)
        self:SetUnitCampID(selfId, selfId + 100)
    elseif now_hminute >= end_hminute then
        self:SetPlayerPvpRule(selfId, 0)
        self:SetUnitCampID(selfId, 0)
    end
end

-- 每分钟刷新场内玩家复活点
function daluandou_main:RefreshScenePlayersRelivePoint()
    local scene = self:get_scene()
    if not scene or scene:get_id() ~= self.config.scene_id then
        return
    end
    local human_count = scene:get_human_count()
    if not human_count or human_count <= 0 then
        return
    end

    for i = 1, human_count do
        local obj_id = scene:get_human_obj_id(i)
        if obj_id and obj_id ~= -1 then
            local pos = self:GetRandomRelivePos()
			skynet.logw("pos.x:"..pos.x)
			skynet.logw("pos.z:"..pos.z)
            self:SetPlayerDefaultReliveInfo(obj_id, 1, 1, 1, self.config.scene_id, pos.x, pos.z)
        end
    end
end

-- timer 每分钟调用：时间判断全部在 main
function daluandou_main:OnMinuteTick()
    local now = os.date("*t")
    local hminute = now.hour * 60 + now.min

    local plane_h = math.floor((tonumber(self.config.plane_time) or 0) / 100)
    local plane_m = (tonumber(self.config.plane_time) or 0) % 100
    local start_h = math.floor((tonumber(self.config.start_time) or 0) / 100)
    local start_m = (tonumber(self.config.start_time) or 0) % 100
    local end_h = math.floor((tonumber(self.config.end_time) or 0) / 100)
    local end_m = (tonumber(self.config.end_time) or 0) % 100

    local plane_hminute = plane_h * 60 + plane_m
    local start_hminute = start_h * 60 + start_m
    local end_hminute = end_h * 60 + end_m
    local leave_h = math.floor((tonumber(self.config.leave_time) or 2200) / 100)
    local leave_m = (tonumber(self.config.leave_time) or 2200) % 100
    local leave_hminute = leave_h * 60 + leave_m
    local scene = self:get_scene()
    if hminute == plane_hminute then
        self:AddGlobalCountNews("@*;SrvMsg;SCA:#{_NEWMSG_999861daluandou_box}Đại Loạn Đấu mở sau 1 phút, chư vị đại hiệp vào trận được rồi.")
        -- 清理数据
        local world_id = scene and scene:get_world_id() or self:LuaFnGetServerID()
        
        if world_id and world_id > 0 and (not self:ranking_call("clear_chaos_brawl_data", world_id)) then
            self:AddGlobalCountNews("Dọn dữ liệu Đại Loạn Đấu thất bại, xin báo quản trị.")
        end
    end
    if hminute == start_hminute then
        self:AddGlobalCountNews("Hoạt động Đại Loạn Đấu đã mở.")
    end
    if hminute == end_hminute then
        self:CreateSettleNpc()
        self:AddGlobalCountNews("Hoạt động Đại Loạn Đấu đã kết thúc.")
    end

    -- 不用等于，按区间持续刷新阵营
    if scene and scene:get_id() == self.config.scene_id then
        local human_count = scene:get_human_count()
        for i = 1, human_count do
            local obj_id = scene:get_human_obj_id(i)
            if obj_id and obj_id ~= -1 then
                if hminute >= start_hminute and hminute < end_hminute then
                    self:SetPlayerPvpRule(obj_id, 9)
                    self:SetUnitCampID(obj_id, obj_id + 100)
                elseif hminute >= end_hminute then
                    self:SetPlayerPvpRule(obj_id, 0)
                    self:SetUnitCampID(obj_id, 0)
                end
            end
        end
    end

    -- 非活动可停留时段强制离场：20:29 前 或 22:00 后
    if (hminute < plane_hminute or hminute >= leave_hminute) and scene and scene:get_id() == self.config.scene_id then
        local p = self.config.leave_pos
        local human_count = scene:get_human_count()
        for i = 1, human_count do
            local obj_id = scene:get_human_obj_id(i)
            if obj_id and obj_id ~= -1 then
                self:NewWorld(obj_id, p.scene, nil, p.x, p.z)
            end
        end
    end
end

function daluandou_main:ranking_call(method, ...)
    local ok, ret1, ret2, ret3 = pcall(skynet.call, ".ranking", "lua", method, ...)
    if not ok then
        return nil, ret1
    end
    return ret1, ret2, ret3
end

function daluandou_main:UpdateRankOnDie(selfId, killerId, world_id, dead_guid, dead_name, killer_guid, killer_name)
    if not self:IsOpenNow() then
        return 0, 0, 0, 0
    end
    
    if not world_id or world_id <= 0 or not dead_guid or dead_guid <= 0 then
        return 0, 0, 0, 0
    end

    local self_kill = 0
    local self_dead = 0
    local dead_menpai = self:LuaFnGetMenPai(selfId) or 9
    local _, dead_kill_count, dead_count = self:ranking_call("update_chaos_brawl_score", world_id, dead_guid, dead_name, 0, 1, dead_menpai)
    self_kill = tonumber(dead_kill_count) or 0
    self_dead = tonumber(dead_count) or 0

    local killer_kill = 0
    local killer_dead = 0
    if killerId and killerId > 0 and killerId ~= selfId then
        killer_guid = killer_guid or self:LuaFnGetGUID(killerId)
        killer_name = killer_name or self:LuaFnGetName(killerId)
        if killer_guid and killer_guid > 0 then
            local killer_menpai = self:LuaFnGetMenPai(killerId) or 9
            local _, killer_kill_count, killer_dead_count = self:ranking_call("update_chaos_brawl_score", world_id, killer_guid, killer_name, 1, 0, killer_menpai)
            killer_kill = tonumber(killer_kill_count) or 0
            killer_dead = tonumber(killer_dead_count) or 0
        end
    end

    return self_kill, self_dead, killer_kill, killer_dead
end

function daluandou_main:OnSceneHumanDie(selfId, killerId)
    if self:GetSceneID() ~= self.config.scene_id then
        return
    end

    if not self:IsOpenNow() then
        self:notify_tips(selfId, "Ngoài giờ Đại Loạn Đấu, chết không tính điểm.")
        return
    end

    local world_id = self:LuaFnGetServerID(selfId)
    local self_guid = self:LuaFnGetGUID(selfId)
    local self_name = self:LuaFnGetName(selfId)
    if not world_id or world_id <= 0 or not self_guid or self_guid <= 0 then
        return
    end

    local killer_guid = 0
    local killer_name = ""
    local has_killer = killerId and killerId > 0 and killerId ~= selfId
    if has_killer then
        killer_guid = self:LuaFnGetGUID(killerId) or 0
        killer_name = self:LuaFnGetName(killerId) or ""
    end

    local self_point = tonumber(self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_DaLuanDouJF)) or 0
    local self_after = self_point + 1
    self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_DaLuanDouJF, self_after)
    local self_point_LS = tonumber(self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_DaLuanDouLS)) or 0

    --终结连杀积分奖励
    if self_point_LS>100 then
        if has_killer then
        local nKillName = self:GetName(killerId)
        self:notify_tips(selfId, string.format("Chuỗi giết của ngươi bị"..nKillName.."Kết thúc, chuỗi giết về không!!!"))
        local selfIdName = self:GetName(selfId)
        self:notify_tips(killerId, string.format("Kết thúc"..selfIdName.."Chuỗi giết thành công thưởng thêm 300 tích điểm!!!"))
        -- 大乱斗积分
        local killer_point = tonumber(self:GetMissionDataEx(killerId, ScriptGlobal.MDEX_DaLuanDouJF)) or 0
        killer_after = killer_point + 300
        self:SetMissionDataEx(killerId, ScriptGlobal.MDEX_DaLuanDouJF, killer_after)
        end
    end

    --死亡连杀归零
    self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_DaLuanDouLS, 0)
    local jf =2  --增加积分
    local killer_after = 0
    local killer_point_LS = 0
    local killer_point_MAX_LS = tonumber(self:GetMissionDataEx(killerId, ScriptGlobal.MDEX_DaLuanDouMAXLS)) or 0 --最大连杀数
    if has_killer then
        
        -- 大乱斗连杀
        killer_point_LS = tonumber(self:GetMissionDataEx(killerId, ScriptGlobal.MDEX_DaLuanDouLS)) or 0
        killer_point_LS = killer_point_LS + 1
        self:SetMissionDataEx(killerId, ScriptGlobal.MDEX_DaLuanDouLS, killer_point_LS)

        --给最大连杀数赋值
        if killer_point_LS>killer_point_MAX_LS then
            self:SetMissionDataEx(killerId, ScriptGlobal.MDEX_DaLuanDouMAXLS, killer_point_LS) 
        end

        if killer_point_LS>100 then
            jf=4
        end
        if killer_point_LS>200 then
            jf=6
         end
        if killer_point_LS>300 then
            jf=8
        end
        if killer_point_LS>400 then
            jf=10
        end
        if killer_point_LS>500 then
            jf=12
        end
        if killer_point_LS==100 then
            self: LSGB(killerId ,killer_point_LS)
        elseif killer_point_LS==200 then
            self: LSGB(killerId ,killer_point_LS)
        elseif killer_point_LS==300 then
            self: LSGB(killerId ,killer_point_LS)
        elseif killer_point_LS==400 then
            self: LSGB(killerId ,killer_point_LS)
        elseif killer_point_LS>500 then
            self: LSGB(killerId ,killer_point_LS)
        end

        -- 大乱斗积分
        local killer_point = tonumber(self:GetMissionDataEx(killerId, ScriptGlobal.MDEX_DaLuanDouJF)) or 0
        killer_after = killer_point + jf
        self:SetMissionDataEx(killerId, ScriptGlobal.MDEX_DaLuanDouJF, killer_after)
   
        
        
    end

    -- 先更新排行，直接拿更新后的击杀/死亡数据，避免重复查询
    local self_kill, self_dead, killer_kill, killer_dead = self:UpdateRankOnDie(selfId, killerId, world_id, self_guid, self_name, killer_guid, killer_name)
    self:notify_tips(selfId, string.format("Ngươi đã tử trận: tổng điểm %d, trận này giết %d, chết %d, chuỗi giết về 0", self_after, tonumber(self_kill) or 0, tonumber(self_dead) or 0))

    if has_killer and killer_guid > 0 then
        self:notify_tips(killerId, "Giết thành công: tổng tích điểm"..killer_after..", trận này giết"..killer_kill..", trận này chết"..killer_dead..", chuỗi giết trận này"..killer_point_LS)
    end
end
--连杀广播
function daluandou_main:LSGB(killerId ,killer_point_LS)
    local nKillName = self:GetName(killerId)
    local sMessage = string.format("#R#{_INFOUSR%s}#Itựa thiên thần nhập thể, không ai cản nổi, trong Đại Loạn Đấu chuỗi giết#cFF0000%d#Ingười mà không xây xát! Mau tới kết thúc chuỗi giết, thưởng kết thúc 300 tích điểm!!!",
                              nKillName,  killer_point_LS)
    -- 广播击杀消息
    if sMessage ~= "" then
        self:AddGlobalCountNews(sMessage)
    end
end
function daluandou_main:CreateSettleNpc()
    local npc_cfg = self.config.settle_npc
    local objid = self:LuaFnCreateMonster(npc_cfg.data_id, npc_cfg.x, npc_cfg.z, 3, 0, self.config.npc_script_id)
    if objid and objid > 0 then
        local live_ms = tonumber(npc_cfg.live_ms) or 7200000
        self:SetCharacterDieTime(objid, live_ms)
    end
end


function daluandou_main:ClaimRankAward(selfId, key)
    key = tonumber(key) or 0
    if key ~= 1 and key ~= 2 then
        self:notify_tips(selfId, "Loại bảng xếp hạng sai.")
        return false
    end
    if self:IsOpenNow() then
        self:notify_tips(selfId, "Đang hoạt động, không nhận thưởng được.")
        return false
    end

    local world_id = self:LuaFnGetServerID(selfId)
    local guid = self:LuaFnGetGUID(selfId)
    local status, msg, rank = self:ranking_call("check_brawl_reward_status", world_id, key, guid, 3)
    rank = tonumber(rank) or 0
    if status == "claimed" then
        self:notify_tips(selfId, "Phần thưởng này đã được nhận.")
        return false
    end
    if status ~= "can_claim" then
        self:notify_tips(selfId, "Chưa vào hạng có thưởng.")
        return false
    end

    local award = self.config.rank_award[rank]
    if not award or award <= 0 then
        self:notify_tips(selfId, "Chưa vào hạng có thưởng.")
        return false
    end

    local ok = self:ranking_call("mark_brawl_reward", world_id, key, guid)
    if not ok then
        self:notify_tips(selfId, "Ghi trạng thái nhận thưởng thất bại, xin thử lại sau.")
        return false
    end

    local cur_point = tonumber(self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_DaLuanDouJF)) or 0
    self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_DaLuanDouJF, cur_point + award)
    self:notify_tips(selfId, string.format("Nhận thành công, được %d tích điểm loạn đấu.", award))
    return true
end


-- ==================== 自动 UI 推送 ====================
function daluandou_main:tick_update_ui()
    local scene = self:get_scene()
    if not scene then return end

    if scene:get_id() ~= self.config.scene_id then return end

    local human_count = scene:get_human_count()
    if human_count <= 0 then return end

    local world_id = scene:get_world_id()
    if not world_id or world_id <= 0 then return end

    local kill_ranklist = self:ranking_call("get_brawl_ranklist", world_id, 1, 10) or {}
    local dead_ranklist = self:ranking_call("get_brawl_ranklist", world_id, 2, 10) or {}

    local kill_str = ""
    for j = 1, 10 do
        local p = kill_ranklist[j]
        kill_str = kill_str
            .. (p and ((p.name or "") .. "," .. tostring(p.kill_count or 0) .. "," .. tostring(p.menpai or 9)) or ",,")
            .. "\n"
    end

    local dead_str = ""
    for j = 1, 10 do
        local p = dead_ranklist[j]
        dead_str = dead_str
            .. (p and ((p.name or "") .. "," .. tostring(p.dead_count or 0) .. "," .. tostring(p.menpai or 9)) or ",,")
            .. "\n"
    end

    for i = 1, human_count do
        local hid = scene:get_human_obj_id(i)
        if hid and self:LuaFnIsCharacterLiving(hid) then
            local guid = self:LuaFnGetGUID(hid)
            local _, player_kill = self:ranking_call("get_brawl_rank", world_id, 1, guid)
            local _, player_dead = self:ranking_call("get_brawl_rank", world_id, 2, guid)

            self:BeginUICommand()
            self:UICommand_AddStr(kill_str)
            self:UICommand_AddStr(dead_str)
            self:UICommand_AddInt(tonumber(player_kill) or 0) -- 个人击杀
            self:UICommand_AddInt(tonumber(player_dead) or 0) -- 个人死亡
            self:EndUICommand()
            self:DispatchUICommand(hid, 20210616)
        end
    end
end

-- ==================== 单人打开排行 UI ====================
function daluandou_main:OnOpenUI(selfId)
	self:BeginUICommand()
	
	local player_guid = self:LuaFnGetGUID(selfId)
	local world_id = self:LuaFnGetServerID(selfId)
	
	local kill_ranklist = self:ranking_call("get_brawl_ranklist", world_id, 1, 10) or {}
	local dead_ranklist = self:ranking_call("get_brawl_ranklist", world_id, 2, 10) or {}
	
	local _, player_kill = self:ranking_call("get_brawl_rank", world_id, 1, player_guid)
	local _, player_dead = self:ranking_call("get_brawl_rank", world_id, 2, player_guid)
	
	local kill_str = ""
	for j = 1, 10 do
		local player = kill_ranklist[j]
		if player then
			kill_str = kill_str .. (player.name or "") .. "," .. tostring(player.kill_count or 0) .. "," .. tostring(player.menpai or 9) .. "\n"
		else
			kill_str = kill_str .. "," .. "," .. "\n"
		end
	end
	
	local dead_str = ""
	for j = 1, 10 do
		local player = dead_ranklist[j]
		if player then
			dead_str = dead_str .. (player.name or "") .. "," .. tostring(player.dead_count or 0) .. "," .. tostring(player.menpai or 9) .. "\n"
		else
			dead_str = dead_str .. "," .. "," .. "\n"
		end
	end
	
	self:UICommand_AddStr(kill_str)
	self:UICommand_AddStr(dead_str)
	self:UICommand_AddInt(tonumber(player_kill) or 0) -- 个人击杀
	self:UICommand_AddInt(tonumber(player_dead) or 0) -- 个人死亡
	self:EndUICommand()
	self:DispatchUICommand(selfId, 20210616)
end



return daluandou_main
