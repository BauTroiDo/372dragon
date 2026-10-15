local ScriptGlobal = require "scripts.ScriptGlobal"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local dungeonsweep = class("dungeonsweep", script_base)
dungeonsweep.dungeons = {
    { name = "Không thể để một ai chạy thoát", cost_sweep_point = 6, cost_money = 50000, script_id = 050100, day_count = 5, seck_num_up_limit = 120, require_level = 30 },
    { name = "Trừ hại", cost_sweep_point = 6, cost_money = 50000, script_id = 050101, day_count = 5, seck_num_up_limit = 120, require_level = 30 },
    { name = "Tiễu phỉ", cost_sweep_point = 6, cost_money = 50000, script_id = 050102, day_count = 5, week_active = 10, seck_num_up_limit = 120, require_level = 30 },
    { name = "Hoàng Kim Chi Liên", cost_sweep_point = 6, cost_money = 50000, script_id = 050220, day_count = 5, seck_num_up_limit = 120, require_level = 75 },
    { name = "Huyền Phật Châu", cost_sweep_point = 6, cost_money = 50000, script_id = 050221, day_count = 5, seck_num_up_limit = 120, require_level = 75},
    { name = "Dung Nham Chi Địa", cost_sweep_point = 6, cost_money = 50000, script_id = 050222, day_count = 5, week_active = 11, seck_num_up_limit = 120, require_level = 75 },
    { name = "讨伐燕子坞", cost_sweep_point = 8, boss_id = { 9320, 9380, 9430},cost_money = 200000, script_id = 401040, day_count = 3, week_active = 12, seck_num_up_limit = 80, require_level = 60 },
    --{ name = "杀星", cost_sweep_point = 8, boss_id = { 13434,13443, 13461, 13479,13524,13488},cost_money = 200000, script_id = 892009, day_count = 2, week_active = 15 },
    { name = "Sát Tinh", cost_sweep_point = 8, boss_id = { 13550,13550, 13550, 13550,13550,13550},cost_money = 200000, script_id = 892009, day_count = 2, week_active = 15, seck_num_up_limit = 80, require_level = 70 },
    { name = "Sơ chiến Phiêu Miểu Phong", cost_sweep_point = 8, boss_id = { 9660, 9661, 9663, 9667, 9666}, script_id = 402276, day_count = 2, week_active = 13, seck_num_up_limit = 80, require_level = 75 },
    { name = "Khiêu chiến Phiêu Miểu Phong", cost_sweep_point = 8, boss_id = { 9540, 9541, 9543, 9547, 9546}, script_id = 402263, day_count = 3, week_active = 14, seck_num_up_limit = 80, require_level = 90 },
    { name = "Thủy Nguyệt Sơn Trang", cost_sweep_point = 8, boss_id = {48504, 48510, 48517, 48521},cost_money = 200000, script_id = 892328, day_count = 2, week_active = 16, seck_num_up_limit = 80, require_level = 80},
    { name = "Thanh Khâu thí luyện - Thường", cost_sweep_point = 8, boss_id = {49713, 49715, 49717, 49719}, script_id = 893020, day_count = 2, week_active = 30, seck_num_up_limit = 80, require_level = 85},
    { name = "Thanh Khâu thí luyện - Khó", cost_sweep_point = 8, boss_id = {49735, 49737, 49739, 49741}, script_id = 893020, day_count = 1, week_active = 31, seck_num_up_limit = 80, require_level = 85},
    { name = "Mộng cảnh xưa - Thường", cost_sweep_point = 8, boss_id_by_level = {
        {51209,51210,51211,51212,51213,51214},
        {51215,51216,51217,51218,51219,51220},
        {51221,51222,51223,51224,51225,51226},
        {51227,51228,51229,51230,51231,51232},
    }, script_id = 801801, day_count = 1, week_active = 39, seck_num_up_limit = 80, require_level = 65},
    { name = "Mộng cảnh xưa - Khó", cost_sweep_point = 8, boss_id_by_level = {
        {51239,51240,51241,51242,51243,51244},
        {51245,51246,51247,51248,51249,51250},
        {51251,51252,51253,51254,51255,51256},
        {51257,51258,51259,51260,51261,51262},
    }, script_id = 801801, day_count = 1, week_active = 40, seck_num_up_limit = 80, require_level = 65},
}
dungeonsweep.double_exp_cost_yuanbao = 5
local g_SweepAll_SeckillTequanDayCount = 943

local function valid_integer(value, min_value, max_value)
    value = tonumber(value)
    if not value or value ~= math.floor(value) then
        return nil
    end
    if min_value and value < min_value then
        return nil
    end
    if max_value and value > max_value then
        return nil
    end
    return value
end

function dungeonsweep:OpenTeQuan(selfId, request_type)
    if request_type == 0 then
        self:BeginUICommand()
        self:UICommand_AddInt(0)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 20221115)
    elseif request_type == 1 then
        local ItemIndex = 38000206
        if self:LuaFnGetAvailableItemCount(selfId, ItemIndex) > 0 then
            self:LuaFnDelAvailableItem(selfId, ItemIndex, 1)
            self:notify_tips(selfId, "#{TQJF_221108_22}")
            self:BeginUICommand()
            self:UICommand_AddInt(0)
            self:EndUICommand()
            self:DispatchUICommand(selfId, 89106202)

            self:SetMissionFlag(selfId, ScriptGlobal.MF_SWEEP_ALL_MONTH_CARD, 1)
            local time = self:TransferNowTime()
            self:SetMissionData(selfId, ScriptGlobal.MD_SweepAll_SeckillTequanData, time)
        else
            self:notify_tips(selfId, "#{TQJF_221108_43}")
            local index, merchadise = self:GetMerchadiseByItemIndex(selfId, ItemIndex)
            if index == nil then
                return
            end
            self:BeginUICommand()
            self:UICommand_AddInt(10)
            self:UICommand_AddInt(5)
            self:UICommand_AddInt(merchadise.price)
            self:UICommand_AddInt(index - 1)
            self:UICommand_AddInt(0)
            self:UICommand_AddInt(self.script_id)
            self:UICommand_AddInt(1)
            self:UICommand_AddInt(1245183)
            local str = self:ContactArgs("#{TQJF_221108_44", ItemIndex, merchadise.price, "#{XFYH_20120221_10}", "#{XFYH_20120221_12", ItemIndex) .. "}"
            self:UICommand_AddStr(str)
            self:EndUICommand()
            self:DispatchUICommand(selfId, 89106201)
        end
    elseif request_type == 2 then
        local ItemIndex = 38000207
        if self:LuaFnGetAvailableItemCount(selfId, ItemIndex) > 0 then
            self:LuaFnDelAvailableItem(selfId, ItemIndex, 1)
            self:notify_tips(selfId, "#{TQJF_221108_23}")
            self:BeginUICommand()
            self:UICommand_AddInt(0)
            self:EndUICommand()
            self:DispatchUICommand(selfId, 89106202)

            self:SetMissionFlag(selfId, ScriptGlobal.MF_SWEEP_ALL_DAY_CARD, 1)
        else
            self:notify_tips(selfId, "#{TQJF_221108_42}")
            local index, merchadise = self:GetMerchadiseByItemIndex(selfId, ItemIndex)
            if index == nil then
                return
            end
            self:BeginUICommand()
            self:UICommand_AddInt(10)
            self:UICommand_AddInt(5)
            self:UICommand_AddInt(merchadise.price)
            self:UICommand_AddInt(index - 1)
            self:UICommand_AddInt(0)
            self:UICommand_AddInt(self.script_id)
            self:UICommand_AddInt(1)
            self:UICommand_AddInt(1245183)
            local str = self:ContactArgs("#{TQJF_221108_44", ItemIndex, merchadise.price, "#{XFYH_20120221_10}", "#{XFYH_20120221_12", ItemIndex) .. "}"
            self:UICommand_AddStr(str)
            self:EndUICommand()
            self:DispatchUICommand(selfId, 89106201)
        end
    end
end

function dungeonsweep:OpenSecKillPage(selfId, index, sweep_type, is_zhaohui)
    index = valid_integer(index, 0, #self.dungeons - 1)
    sweep_type = valid_integer(sweep_type, 0, 3)
    is_zhaohui = valid_integer(is_zhaohui or 0, 0, 1)
    if not index or not sweep_type or not is_zhaohui then
        self:notify_tips(selfId, "Tham số càn quét không đúng")
        return
    end
    index = index + 1
    local sweep_config = self.dungeons[index]
    if sweep_config == nil then
        self:notify_tips(selfId, "Phụ bản này chưa mở càn quét")
        return
    end
    local count = self:GetCampaignCount(selfId, index)
    if count >= sweep_config.day_count and not self:CanContinueSweep(selfId, index) then
        self:notify_tips(selfId, "#{SDYH_170110_06}")
        return
    end
    self:BeginUICommand()
    self:UICommand_AddInt(index)
    self:UICommand_AddInt(sweep_type)
    self:UICommand_AddInt(is_zhaohui)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 20150212)
end

function dungeonsweep:OnFuBenSecKill(selfId, index, boss_id, double_exp,
    wujing_double, wujing_double_65, double_cost_mode, sweep_type, is_zhaohui)
    index = valid_integer(index, 1, #self.dungeons)
    boss_id = valid_integer(boss_id, 1)
    double_exp = valid_integer(double_exp, 0, 1)
    wujing_double = valid_integer(wujing_double or 0, 0, 1)
    wujing_double_65 = valid_integer(wujing_double_65 or 0, 0, 1)
    double_cost_mode = valid_integer(double_cost_mode or 0, 0, 1)
    sweep_type = valid_integer(sweep_type, 0, 3)
    is_zhaohui = valid_integer(is_zhaohui or 0, 0, 1)
    if not index or not boss_id or not double_exp or not wujing_double
        or not wujing_double_65 or not double_cost_mode or not sweep_type or not is_zhaohui then
        self:notify_tips(selfId, "Tham số càn quét không đúng")
        return
    end

    local sweep_config = self.dungeons[index]
    if sweep_config == nil then
        self:notify_tips(selfId, "Phụ bản này chưa mở càn quét")
        return
    end
    if not self:CheckCanSweep(selfId, index, boss_id, sweep_config) then
        return
    end

    local old_data = self:GetSecKillData(selfId)
    if old_data and old_data.item_list and #old_data.item_list > 0 then
        self:notify_tips(selfId, "Xin nhận hoặc bỏ thưởng càn quét hiện tại trước")
        return
    end
    if boss_id > 1 then
        if not old_data then
            self:notify_tips(selfId, "Tiến độ càn quét không tồn tại, xin mở lại giao diện")
            return
        end
        -- 后续首领始终使用第一个首领保存的设置。客户端刷新界面时会重置部分
        -- 勾选状态，不能再用后续请求中的显示状态覆盖本次扫荡规则。
        sweep_type = old_data.sweep_type == nil and sweep_type or old_data.sweep_type
        double_exp = old_data.double_exp == nil and double_exp or old_data.double_exp
        wujing_double = old_data.wujing_double == nil and wujing_double or old_data.wujing_double
        wujing_double_65 = old_data.wujing_double_65 == nil and wujing_double_65 or old_data.wujing_double_65
        double_cost_mode = old_data.double_cost_mode == nil and double_cost_mode or old_data.double_cost_mode
        is_zhaohui = old_data.is_zhaohui == nil and is_zhaohui or old_data.is_zhaohui
    end

    local privilege_count
    if boss_id == 1 then
        if sweep_type == 0 then
            local sweep_point = self:GetSweepCount(selfId, index)
            if sweep_point < sweep_config.cost_sweep_point then
                self:notify_tips(selfId, "Không đủ điểm càn quét")
                return
            end
        elseif sweep_type == 1 then
            if sweep_config.cost_money == nil then
                self:notify_tips(selfId, "Phụ bản này không càn quét bằng kim tệ được")
                return
            end
            local my_money = self:GetMoney(selfId)
            if my_money < sweep_config.cost_money then
                self:notify_tips(selfId, "Kim tệ không đủ")
                return
            end
        elseif sweep_type == 2 then
            local time = self:GetMissionData(selfId, ScriptGlobal.MD_SweepAll_SeckillTequanData)
            time = self:DeTransferNowTime(time) + 30 * 24 * 60 * 60
            local now = os.time()
            if time < now then
                self:notify_tips(selfId, "Chinh Long Lệnh đã hết hạn")
                return
            end
            privilege_count = self:GetMissionData(selfId, g_SweepAll_SeckillTequanDayCount)
            if privilege_count >= 2 then
                self:notify_tips(selfId, "Càn quét bất thường 2")
                return
            end
        elseif sweep_type == 3 then
            self:notify_tips(selfId, "Càn quét bạc chưa mở, xin dùng điểm càn quét hoặc kim tệ")
            return
        else
            self:notify_tips(selfId, "Cách càn quét chưa rõ")
            return
        end
        if double_exp == 1 then
            if self:GetYuanBao(selfId) < self.double_exp_cost_yuanbao then
                self:notify_tips(selfId, "Nguyên bảo không đủ")
                return
            end
        end
    end

    local sweep_state = {
        sweep_type = sweep_type,
        double_exp = double_exp,
        wujing_double = wujing_double,
        wujing_double_65 = wujing_double_65,
        double_cost_mode = double_cost_mode,
        is_zhaohui = is_zhaohui,
    }
    local sec_kill_data, award_exp = self:GenSecKillData(selfId, index, boss_id, sweep_state)
    if not sec_kill_data or type(sec_kill_data.item_list) ~= "table"
        or type(award_exp) ~= "number" or award_exp < 0 then
        self:notify_tips(selfId, "Tạo thưởng càn quét thất bại, lần này chưa trừ phí")
        return
    end

    -- 所有可能失败的校验与奖励生成均已完成，最后统一提交费用。
    if boss_id == 1 then
        if sweep_type == 0 then
            if not self:CostSweepPoint(selfId, index, sweep_config.cost_sweep_point) then
                self:notify_tips(selfId, "Trừ điểm càn quét thất bại")
                return
            end
        elseif sweep_type == 1 then
            self:CostMoney(selfId, sweep_config.cost_money)
        elseif sweep_type == 2 and self:GetCampaignCount(selfId, index) == 0 then
            self:SetMissionData(selfId, g_SweepAll_SeckillTequanDayCount, privilege_count + 1)
        end
        if double_exp == 1 then
            self:LuaFnCostYuanBao(selfId, self.double_exp_cost_yuanbao)
        end
    end

    if double_exp == 1 then
        award_exp = award_exp * 2
    end
    self:AddExp(selfId, math.floor(award_exp))
    self:SetSecKillData(selfId, sec_kill_data)
    if boss_id == 1 then
        if type(sweep_config.boss_id) == "table"
            or type(sweep_config.boss_id_by_level) == "table" then
            self:CallScriptFunction(sweep_config.script_id, "CalSweepData", selfId, index, boss_id)
        end
        self:DungeonDone(selfId, index)
    end
    if sec_kill_data.have_next == 0 and sweep_config.week_active then
        self:LuaFnAddMissionHuoYueZhiSilent(selfId, sweep_config.week_active)
    end
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
end

function dungeonsweep:GetSecKillData(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
    return human and human.dungeonsweep and human.dungeonsweep.sec_kill_data
end

function dungeonsweep:CheckCanSweep(selfId, fuben_index, boss_id, sweep_config)
    local sec_kill_data = self:GetSecKillData(selfId) or {}
    local campaign_count = self:GetCampaignCount(selfId, fuben_index)
    if boss_id == 1 and campaign_count >= sweep_config.day_count then
        self:notify_tips(selfId, "Lượt càn quét đã tối đa")
        return false
    end
    if boss_id == 1 and sec_kill_data.fuben_index == fuben_index - 1
        and sec_kill_data.have_next == 1 then
        self:notify_tips(selfId, "Xin càn quét xong các thủ lĩnh còn lại của phụ bản trước")
        return false
    end
    if sec_kill_data.fuben_index == nil then
        if boss_id ~= 1 then
            self:notify_tips(selfId, "Yêu cầu bất thường 0")
            return false
        end
    end
    if (sec_kill_data.fuben_index and sec_kill_data.fuben_index + 1 == fuben_index) then
        if boss_id ~= 1 and boss_id ~= (sec_kill_data.boss_id or 0) + 1 then
            self:notify_tips(selfId, "Xin càn quét thủ lĩnh phụ bản theo thứ tự")
            return false
        end
    else
        if boss_id ~= 1 then
            self:notify_tips(selfId, "Yêu cầu bất thường 4")
            return false
        end
    end
    if sweep_config.boss_id == nil and sweep_config.boss_id_by_level == nil then
        if boss_id ~= 1 then
            self:notify_tips(selfId, "Yêu cầu bất thường 1")
            return false
        end
    elseif type(sweep_config.boss_id_by_level) == "table" then
        if type(sweep_config.boss_id_by_level[boss_id]) ~= "table" then
            self:notify_tips(selfId, "Yêu cầu bất thường 2")
            return false
        end
    else
        if sweep_config.boss_id[boss_id] == nil then
            self:notify_tips(selfId, "Yêu cầu bất thường 2")
            return false
        end
    end
    local level = self:GetCharacterLevel(selfId)
    if level < sweep_config.require_level then
        self:notify_tips(selfId, "Yêu cầu bất thường 3")
        return false
    end
    return true
end

function dungeonsweep:OnContinueFuBenSecKill(selfId, index, sweep_type, is_zhaohui)
    index = valid_integer(index, 1, #self.dungeons)
    sweep_type = valid_integer(sweep_type, 0, 3)
    is_zhaohui = valid_integer(is_zhaohui or 0, 0, 1)
    if not index or not sweep_type or not is_zhaohui then
        self:notify_tips(selfId, "Tham số càn quét không đúng")
        return
    end
    local sweep_config = self.dungeons[index]
    if sweep_config == nil then
        self:notify_tips(selfId, "Phụ bản này chưa mở càn quét")
        return
    end
    local count = self:GetCampaignCount(selfId, index)
    if count >= sweep_config.day_count and not self:CanContinueSweep(selfId, index) then
        self:notify_tips(selfId, "#{SDYH_170110_06}")
        return
    end
    self:BeginUICommand()
    self:UICommand_AddInt(index)
    self:UICommand_AddInt(sweep_type)
    self:UICommand_AddInt(is_zhaohui)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 20150212)
end

function dungeonsweep:GenSecKillData(selfId, index, boss_id, sweep_state)
    local data = {
        boss_id = 0,
        fuben_index = 0,
        item_list = {},
        sweep_type = sweep_state.sweep_type,
        double_exp = sweep_state.double_exp,
        wujing_double = sweep_state.wujing_double,
        wujing_double_65 = sweep_state.wujing_double_65,
        double_cost_mode = sweep_state.double_cost_mode,
        is_zhaohui = sweep_state.is_zhaohui,
    }
    local dungeon = self.dungeons[index]
    local boss_data_index
    local drop_items
    local award_exp
    local player_level = self:GetLevel(selfId)
    local selfLevel = math.min(11, math.max(1, math.floor(player_level / 10)))
    local monsterinfo = {0,1,2,3,4,5,6,7,8,9,30000}
    if type(dungeon.boss_id_by_level) == "table" then
        local level_index = 1
        if player_level >= 110 then
            level_index = 6
        elseif player_level >= 100 then
            level_index = 5
        elseif player_level >= 90 then
            level_index = 4
        elseif player_level >= 80 then
            level_index = 3
        elseif player_level >= 70 then
            level_index = 2
        end
        boss_data_index = dungeon.boss_id_by_level[boss_id][level_index]
        data.boss_id = boss_id
        data.fuben_index = index - 1
        data.have_next = boss_id < #dungeon.boss_id_by_level and 1 or 0
        drop_items = self:CalMonsterDropItems(boss_data_index)
        award_exp = self:CalMonsterAwardExp(boss_data_index)
    elseif type(dungeon.boss_id) == "table" then
        if dungeon.name == "讨伐燕子坞" then
            boss_data_index = dungeon.boss_id[boss_id] + monsterinfo[selfLevel]
        else
            boss_data_index = dungeon.boss_id[boss_id]
        end
        data.boss_id = boss_id
        data.fuben_index = index - 1
        data.have_next = boss_id < #dungeon.boss_id and 1 or 0
        drop_items = self:CalMonsterDropItems(boss_data_index)
        award_exp = self:CalMonsterAwardExp(boss_data_index)
    else
        data.boss_id = 1
        data.fuben_index = index - 1
        data.have_next = 0
        drop_items, award_exp = self:CallScriptFunction(dungeon.script_id, "CalSweepData", selfId)
    end
    if type(drop_items) ~= "table" or type(award_exp) ~= "number" then
        return nil
    end
    if #drop_items > 12 then
        return nil
    end
    data.item_list = drop_items
    for i, item in ipairs(data.item_list) do
        item.id = valid_integer(item.id or item.item_index, 1)
        item.count = valid_integer(item.count, 1, 255)
        if not item.id or not item.count then
            return nil
        end
        item.index = i - 1
    end
    return data, award_exp
end

function dungeonsweep:CanContinueSweep(selfId, index)
    local human = self:get_scene():get_obj_by_id(selfId)
    local data = human and human.dungeonsweep and human.dungeonsweep.sec_kill_data
    if data == nil then
        return false
    end
    return (data.fuben_index == index - 1) and data.have_next == 1
end

function dungeonsweep:OnScenePlayerEnter(selfId)
    for i, config in ipairs(self.dungeons) do
        local sweep_point = self:GetSweepCount(selfId, i)
        sweep_point = math.max(0, math.min(config.seck_num_up_limit,
            math.floor(tonumber(sweep_point) or 0)))
        self:SetSweepCount(selfId, i, sweep_point)
    end
end

return dungeonsweep
