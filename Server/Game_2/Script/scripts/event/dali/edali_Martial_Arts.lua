local class = require "class"
local define = require "define"
local skynet = require "skynet"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local configenginer = require "configenginer":getinstance()
local edali_Martial_Arts = class("edali_Martial_Arts", script_base)
edali_Martial_Arts.script_id = 502161

----------------------------------------------------------------------
-- NPC对话菜单 (5个选项)
-- StrDictionary引用:
--   DFYD_250716_249  => 武境真诀
--   WJZY_251208_2    => 武境通脉
--   WJZY_251208_3    => 武境心络
--   DFJC_250709_93   => 关于武境
--   WJZY_251208_4    => 关于武境通脉
-- UI界面映射:
--   武境真诀     => Peak_Learn            UI_COMMAND 20250806
--   武境通脉     => Peak_Second_LevelUp   UI_COMMAND 20251211
--   武境心络     => (待实现)
--   关于武境     => NPC文本 #{DFJC_250709_96}
--   关于武境通脉 => NPC文本 #{WJZY_251208_5}
----------------------------------------------------------------------

function edali_Martial_Arts:OnDefaultEvent(selfId, targetId)
    local human = self.scene:get_obj_by_id(selfId)
    local dfeng_open = 0
    if human then
        dfeng_open = human:get_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Open) or 0
    end

    self:BeginEvent(self.script_id)
    self:AddText("#{DFJC_250709_95}")
    if dfeng_open >= 1 then
        self:AddNumText("Võ Cảnh Chân Quyết", 6, 1)         -- Peak_Learn
        self:AddNumText("Võ Cảnh Thông Mạch", 6, 2)         -- Peak_Second_LevelUp
        self:AddNumText("Võ Cảnh Tâm Lạc", 6, 3)         -- Peak_Second_PoMai
        self:AddNumText("Về võ cảnh", 8, 4)          -- 信息文本
        self:AddNumText("Về Võ Cảnh Thông Mạch", 8, 5)      -- 信息文本
        if dfeng_open == 1 then
            self:AddNumText("#YTạm dừng chia kinh nghiệm", 6, 11)   -- 暂停武境经验分流
        else
            self:AddNumText("#GKhôi phục chia kinh nghiệm", 6, 11)   -- 恢复武境经验分流
        end
        --self:AddNumText("[调试]查看MD数据", 6, 7)
        --self:AddNumText("[调试]清除异常MD", 6, 8)
        --self:AddNumText("[调试]设通脉50级", 6, 9)
        --self:AddNumText("[调试]通脉清零", 6, 10)
     else
         self:AddNumText("Mở võ cảnh", 6, 6)
        --self:AddNumText("[调试]查看MD数据", 6, 7)
        --self:AddNumText("[调试]清除异常MD", 6, 8)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function edali_Martial_Arts:OnEnumerate(caller, selfId, targetId, arg, index)
    local human = self.scene:get_obj_by_id(selfId)
    local dfeng_open = 0
    if human then
        dfeng_open = human:get_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Open) or 0
    end

    if dfeng_open >= 1 then
        caller:AddNumTextWithTarget(self.script_id, "Võ Cảnh Chân Quyết", 6, 1)
        caller:AddNumTextWithTarget(self.script_id, "Võ Cảnh Thông Mạch", 6, 2)
        caller:AddNumTextWithTarget(self.script_id, "Võ Cảnh Tâm Lạc", 6, 3)
        caller:AddNumTextWithTarget(self.script_id, "Về võ cảnh", 8, 4)
        caller:AddNumTextWithTarget(self.script_id, "Về Võ Cảnh Thông Mạch", 8, 5)
        if dfeng_open == 1 then
            caller:AddNumTextWithTarget(self.script_id, "#YTạm dừng chia kinh nghiệm", 6, 11)
        else
            caller:AddNumTextWithTarget(self.script_id, "#GKhôi phục chia kinh nghiệm", 6, 11)
        end
        --caller:AddNumTextWithTarget(self.script_id, "[调试]查看MD数据", 6, 7)
        --caller:AddNumTextWithTarget(self.script_id, "[调试]清除异常MD", 6, 8)
        --caller:AddNumTextWithTarget(self.script_id, "[调试]设通脉50级", 6, 9)
        --caller:AddNumTextWithTarget(self.script_id, "[调试]通脉清零", 6, 10)
    else
        caller:AddNumTextWithTarget(self.script_id, "Mở võ cảnh", 6, 6)
        --caller:AddNumTextWithTarget(self.script_id, "[调试]查看MD数据", 6, 7)
        --caller:AddNumTextWithTarget(self.script_id, "[调试]清除异常MD", 6, 8)
    end
end

-- XSCRIPT: 设置攻防门派和修为值
-- 客户端Peak_Learn_OK_Clicked发送13个参数:
--   param[0]=targetId, param[1..6]=攻击(门派1,修为1,门派2,修为2,门派3,修为3)
--   param[7..12]=防御(门派1,修为1,门派2,修为2,门派3,修为3)
-- MissionData存储格式: school + xdd * 100
function edali_Martial_Arts:SetDfengAttackDefence(selfId, targetId,
    atkMP1, atkXDD1, atkMP2, atkXDD2, atkMP3, atkXDD3,
    defMP1, defXDD1, defMP2, defXDD2, defMP3, defXDD3)

    local human = self.scene:get_obj_by_id(selfId)
    if not human then return end

    -- 校验武境是否已开启
    if (human:get_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Open) or 0) < 1 then
        human:notify_tips("Võ cảnh chưa mở")
        return
    end

    atkMP1 = tonumber(atkMP1) or 0
    atkXDD1 = tonumber(atkXDD1) or 0
    atkMP2 = tonumber(atkMP2) or 0
    atkXDD2 = tonumber(atkXDD2) or 0
    atkMP3 = tonumber(atkMP3) or 0
    atkXDD3 = tonumber(atkXDD3) or 0
    defMP1 = tonumber(defMP1) or 0
    defXDD1 = tonumber(defXDD1) or 0
    defMP2 = tonumber(defMP2) or 0
    defXDD2 = tonumber(defXDD2) or 0
    defMP3 = tonumber(defMP3) or 0
    defXDD3 = tonumber(defXDD3) or 0

    -- 客户端未使用的槽位发送-1，统一归零
    if atkMP1 < 0 then atkMP1 = 0; atkXDD1 = 0 end
    if atkMP2 < 0 then atkMP2 = 0; atkXDD2 = 0 end
    if atkMP3 < 0 then atkMP3 = 0; atkXDD3 = 0 end
    if defMP1 < 0 then defMP1 = 0; defXDD1 = 0 end
    if defMP2 < 0 then defMP2 = 0; defXDD2 = 0 end
    if defMP3 < 0 then defMP3 = 0; defXDD3 = 0 end

    -- 批量设置时抑制auto-refresh，避免6个set_mission_data各触发一次刷新
    human._dfeng_refreshing = true
    human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Attack1, atkMP1 + atkXDD1 * 100)
    human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Defence1, defMP1 + defXDD1 * 100)
    human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Attack2, atkMP2 + atkXDD2 * 100)
    human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Defence2, defMP2 + defXDD2 * 100)
    human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Attack3, atkMP3 + atkXDD3 * 100)
    human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Defence3, defMP3 + defXDD3 * 100)
    human._dfeng_refreshing = nil

    -- 统一刷新一次756/320 + 补发mission链
    human:refresh_dfeng_attrib()
    human:sync_dfeng_learn_md_to_client()
    human:notify_tips("Tu tập chân quyết võ cảnh đã lưu")
end

-- XSCRIPT: 重置攻防槽位
-- 客户端Peak_Learn_Recharge_Clicked发送1个参数: param[0]=targetId
function edali_Martial_Arts:CleanDfengAttackDefence(selfId, targetId)
    local human = self.scene:get_obj_by_id(selfId)
    if not human then return end

    if (human:get_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Open) or 0) < 1 then
        human:notify_tips("Võ cảnh chưa mở")
        return
    end

    -- 批量设置时抑制auto-refresh
    human._dfeng_refreshing = true
    human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Attack1, 0)
    human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Defence1, 0)
    human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Attack2, 0)
    human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Defence2, 0)
    human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Attack3, 0)
    human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Defence3, 0)
    human._dfeng_refreshing = nil

    human:refresh_dfeng_attrib()
    human:sync_dfeng_learn_md_to_client()
    human:notify_tips("Tu vi công thủ đã đặt lại")
end

-- 由human.lua经验分配调用: scene:get_script_engienr():call(502161, "AddWuJingExp", selfId, 0, dfeng_exp)
function edali_Martial_Arts:AddWuJingExp(selfId, arg2, exp)
    local human = self.scene:get_obj_by_id(selfId)
    if not human then return end

    exp = tonumber(exp) or 0
    if exp <= 0 then return end

    -- 倍率已在 human.lua add_exp() 中由 wujing_mult 处理，此处直接累加
    local cur_exp = human:get_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Exp) or 0
    local cur_level = human:get_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Level) or 0
    if cur_level >= 200 then
        if cur_exp > 0 then
            human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Exp, 0)
        end
        return
    end
    human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Exp, cur_exp + exp)
    human:refresh_dfeng_attrib()

    --skynet.logi("[DFeng] AddWuJingExp: selfId=", selfId, " add=", exp, " total=", cur_exp + exp)
end

function edali_Martial_Arts:OnEventRequest(selfId, targetId, arg, index)
    --skynet.logi("[DFeng] OnEventRequest: selfId=", selfId, " targetId=", targetId, " arg=", arg, " index=", index, " script_id=", self.script_id)
    if arg ~= self.script_id then
        --skynet.logi("[DFeng] OnEventRequest: arg mismatch, expected=", self.script_id, " got=", arg)
        return
    end

    if index == 1 then
        -- 武境真诀 → 
        local human = self.scene:get_obj_by_id(selfId)
        if human then
            -- 真诀界面读取旧getter链(GetAttackMenPai1/XDD1...)，打开前补齐高位mission缓存
            human:refresh_dfeng_attrib()
            human:sync_dfeng_learn_md_to_client()
        end
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 20250806)
    elseif index == 2 then
        -- 武境通脉 → Peak_Second_LevelUp UI_COMMAND 20251211
        --skynet.logi("[DFeng] OnEventRequest index=2: 武境通脉, sending UICommand 20251211, targetId=", targetId)
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 20251211)
        --skynet.logi("[DFeng] OnEventRequest index=2: DispatchUICommand done")
    elseif index == 3 then
        -- 武境心络 → 心络强化UI (通过758包触发，不用UI_COMMAND)
        local human = self.scene:get_obj_by_id(selfId)
        if human then
            -- 先补齐已达通脉等级但未初始化的心络，再刷新base_attrib确保CData[10656](通脉等级)同步到客户端
            if human.ensure_dfeng_essence_kongwei_unlocked then
                human:ensure_dfeng_essence_kongwei_unlocked()
            end
            human:refresh_dfeng_attrib()
            human:send_dfeng_essence_kongwei(-1)
        end
    elseif index == 4 then
        -- 关于武境 → 显示信息文本 #{DFJC_250709_96}
        self:BeginEvent(self.script_id)
        self:AddText("#YVề Võ Cảnh#r#r#WKhi Cấp độ của nhân vật đạt đến #G85#W cấp, có thể nhấp vào Nút giao diện chính: #GVõ Cảnh Lệ Đồ#W để tiến hành nhiệm vụ dẫn dắt Võ Cảnh, sau khi Hoàn thành nhiệm vụ thì có thể mở chức năng Võ Cảnh.#r#r#cfabf8fVề Cấp độ Võ Cảnh#r#W    Sau khi chức năng Võ Cảnh được mở, nhân vật có thể nâng #GCấp độ Võ Cảnh#W, Cấp độ Võ Cảnh được nâng thông qua Tiêu hao #GKinh nghiệm Võ Cảnh#W, khi Kinh nghiệm Võ Cảnh đạt đến số lượng Yêu cầu thì Cấp độ Võ Cảnh sẽ tự động tăng. Giới hạn trên của Cấp độ Võ Cảnh là #G200#W cấp.#r#r#cfabf8fVề Thuộc tính do Cấp độ Võ Cảnh cung cấp#r#W    Cấp độ Võ Cảnh mỗi khi tăng thêm#G1#W cấp, nhân vật đều Có thể nhận Thuộc tính, mỗi#G20#W cấp sẽ Nhận được Thuộc tính theo thứ tự cố định.#r#r#cfabf8fVề Chân Quyết Võ Cảnh#r#WVõ Cảnh chân quyết chia làm#Gvõ quyết tấn công#Wvà#Gvõ quyết thủ ngự#W, võ quyết tấn công và võ quyết thủ ngự theo cấp độ Võ Cảnh tăng lên, tối đa có thể chọn#G3#Wmôn phái phát huy hiệu lực, môn phái chưa được chọn thì không bị ảnh hưởng. Môn phái đã chọn và điểm võ quyết có thể thông qua tiêu hao#G1#Wviên#YVõ Quyết Dịch Cân Đan#Wđể đặt lại.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 5 then
        -- 关于武境通脉 → 显示信息文本 #{WJZY_251208_5}
        self:BeginEvent(self.script_id)
        self:AddText("#{WJZY_251208_5}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 7 then
        -- [调试] 查看角色身上所有非零MD数据
        local human = self.scene:get_obj_by_id(selfId)
        if human then
            local md_list = {}
            local md_datas = human.mission_data and human.mission_data.mission_datas or {}
            for i, val in pairs(md_datas) do
                if val and val ~= 0 then
                    local md_id = i - 1
                    table.insert(md_list, string.format("MD[%d]=%d", md_id, val))
                end
            end
            table.sort(md_list)
            local text = "Dữ liệu MD nhân vật (khác 0):\\n" .. table.concat(md_list, "\n")
            self:BeginEvent(self.script_id)
            self:AddText(text)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            --skynet.logi("[DFeng] ShowMD: ", text)
        end
    elseif index == 8 then
        -- [调试] 清除异常负值MD
        local human = self.scene:get_obj_by_id(selfId)
        if human then
            local fix_ids = {964, 966, 967, 968, 969}
            for _, md_id in ipairs(fix_ids) do
                local val = human:get_mission_data_by_script_id(md_id)
                if val and val < 0 then
                    human:set_mission_data_by_script_id(md_id, 0)
                end
            end
            human:notify_tips("Đã xóa giá trị âm bất thường của MD[964,966-969]")
            --skynet.logi("[DFeng] FixNegativeMD done for selfId=", selfId)
            human:refresh_dfeng_attrib()
        end
    elseif index == 11 then
        -- 暂停/恢复经验分流（不清除任何武境数据）
        local human = self.scene:get_obj_by_id(selfId)
        if human then
            local cur_open = human:get_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Open) or 0
            if cur_open == 1 then
                -- 当前分流中 → 暂停（设为2）
                human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Open, 2)
                human:notify_tips("Chia kinh nghiệm võ cảnh đã dừng, kinh nghiệm giết quái dồn hết cho nhân vật")
            elseif cur_open == 2 then
                -- 当前已暂停 → 恢复（设为1）
                human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Open, 1)
                human:notify_tips("Chia kinh nghiệm võ cảnh đã khôi phục, kinh nghiệm giết quái chia 50-50")
            else
                human:notify_tips("Võ cảnh chưa mở")
            end
        end
    elseif index == 6 then
        -- 开启武境
        local human = self.scene:get_obj_by_id(selfId)
        if human then
            if (human:get_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Open) or 0) >= 1 then
                human:notify_tips("Võ cảnh đã mở rồi")
                return
            end
            human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Open, 1)
            human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Exp, 0)
            human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Level, 0)
            human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_LevelUp_Times, 0)
            human:refresh_dfeng_attrib()
            human:notify_tips("Võ cảnh đã mở! Từ nay giết quái nhận kinh nghiệm võ cảnh")
            --skynet.logi("[DFeng] OpenWuJing: selfId=", selfId)
        end
    elseif index == 9 then
        -- [调试] 设置通脉等级=50(心络系统需通脉等级>=10才解锁)
        local human = self.scene:get_obj_by_id(selfId)
        if human then
            local cur_dfeng_level = human:get_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Level) or 0
            if cur_dfeng_level < 50 then
                human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Level, 50)
            end
            human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_LevelUp_Times, 50)
            human:refresh_dfeng_attrib()
            human:notify_tips("Cấp thông mạch đã đặt 50 (võ cảnh >= 50)")
            --skynet.logi("[DFeng] DebugSetEssenceLevel50: selfId=", selfId)
        end
    elseif index == 10 then
        -- [调试] 通脉等级清零
        local human = self.scene:get_obj_by_id(selfId)
        if human then
            human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_LevelUp_Times, 0)
            -- 同时清零周计数中的通脉部分
            human:refresh_dfeng_attrib()
            human:notify_tips("Cấp thông mạch đã về 0, đếm tuần đã đặt lại")
            --skynet.logi("[DFeng] DebugResetEssenceLevel: selfId=", selfId)
        end
    end
end

-- XSCRIPT: 通脉升级
-- 客户端Peak_Second_LevelUp_GradeUp_Clicked发送4个参数:
--   param[0]=nSelectActive (0=普通升级, 1-4=阶段边界元素选择)
--   param[1]=nSelID_single1 (元素类型1: 1=冰,2=火,3=玄,4=毒)
--   param[2]=nSelID_single2 (元素类型2)
--   param[3]=nSelID_single3 (元素类型3)
function edali_Martial_Arts:ComfirmSecond_LevelUp_Essence(selfId,
    nSelectActive, nSelID1, nSelID2, nSelID3)

    local human = self.scene:get_obj_by_id(selfId)
    if not human then
        --skynet.logi("[DFeng-DBG] ComfirmSecond_LevelUp_Essence: human not found, selfId=", selfId)
        return
    end

    -- 调试: 游戏内可见提示, 确认函数被调用及参数
    --human:notify_tips("[DBG]通脉 sel=" .. tostring(nSelectActive)
    --    .. " id=" .. tostring(nSelID1) .. "/" .. tostring(nSelID2) .. "/" .. tostring(nSelID3))

    --skynet.logi("[DFeng] ComfirmSecond_LevelUp_Essence ENTER: selfId=", selfId,
    --    " select=", nSelectActive, " sel=", nSelID1, "/", nSelID2, "/", nSelID3)

    if (human:get_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Open) or 0) < 1 then
        human:notify_tips("Võ cảnh chưa mở")
        return
    end

    nSelectActive = tonumber(nSelectActive) or 0
    nSelID1 = tonumber(nSelID1) or -1
    nSelID2 = tonumber(nSelID2) or -1
    nSelID3 = tonumber(nSelID3) or -1

    local cur_essence_level = human:get_mission_data_by_script_id(ScriptGlobal.MD_DFeng_LevelUp_Times) or 0
    local cur_dfeng_level = human:get_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Level) or 0

    --skynet.logi("[DFeng] EssenceLevelUp CHECK: essence=", cur_essence_level, " dfeng=", cur_dfeng_level)

    if cur_essence_level >= 200 then
        human:notify_tips("Cấp thông mạch đã đầy")
        return
    end

    -- 通脉等级不能超过武境等级
    if cur_essence_level >= cur_dfeng_level then
        human:notify_tips("Cấp thông mạch không vượt cấp võ cảnh được (thông mạch hiện:" .. cur_essence_level .. " Võ cảnh:" .. cur_dfeng_level .. ")")
        return
    end

    -- 每破脉10级，对应心络必须强化满级(8级)才能继续下一个10级
    if cur_essence_level > 0 and cur_essence_level % 10 == 0 then
        local required_slot = cur_essence_level / 10
        local slot_level = human:get_dfeng_kw_slot_level(required_slot)
        if slot_level < 8 then
            human:notify_tips("Xin trước tiên đem thứ" .. required_slot .. "Cường hóa tâm lạc tới tối đa (hiện" .. slot_level .. "Cấp)")
            return
        end
    end

    -- 每周升级次数限制: 基础10 + floor(DFLevel/10)
    -- MD 970 打包格式: week_id * 10000 + 武境周升级次数 * 100 + 通脉周升级次数
    --local max_week_times = 10 + math.floor(cur_dfeng_level / 10)
    --if essence_weekly >= max_week_times then
        --human:notify_tips("本周通脉升级次数已达上限")
        --return
    --end

    -- 读取配置
    local essence_cfg = configenginer:get_config("dfeng_essence_info")
    if not essence_cfg then
        skynet.loge("[DFeng] ComfirmSecond_LevelUp_Essence: config not found")
        human:notify_tips("Cấu hình sai")
        return
    end
    local next_level = cur_essence_level + 1
    local cfg = essence_cfg[next_level]
    if not cfg then
        skynet.loge("[DFeng] ComfirmSecond_LevelUp_Essence: no config for level ", next_level)
        human:notify_tips("Cấu hình sai")
        return
    end

    -- 检查金币(金币+交子总和)
    local money = self:GetMoney(selfId) + self:GetMoneyJZ(selfId)
    if money < cfg.money_cost then
        human:notify_tips("Kim tệ không đủ")
        return
    end

    -- 检查道具
    if cfg.item_id > 0 and cfg.item_count > 0 then
        local have_count = self:LuaFnGetAvailableItemCount(selfId, cfg.item_id) or 0
        if have_count < cfg.item_count then
            human:notify_tips("Không đủ nguyên liệu")
            return
        end
    end

    -- 整十级破脉: 扣费前校验破脉参数有效性
    local is_breakthrough = (next_level % 10 == 0)
    if is_breakthrough then
        if nSelectActive < 1 or nSelectActive > 4 then
            human:notify_tips("Xin chọn thuộc tính tự chọn rồi hãy phá mạch")
            return
        end
        if nSelectActive == 1 and nSelID1 < 1 then
            human:notify_tips("Xin chọn thuộc tính tự chọn rồi hãy phá mạch")
            return
        end
        if nSelectActive == 2 and (nSelID1 < 1 or nSelID2 < 1) then
            human:notify_tips("Xin chọn thuộc tính tự chọn rồi hãy phá mạch")
            return
        end
        if nSelectActive == 3 and (nSelID1 < 1 or nSelID2 < 1 or nSelID3 < 1) then
            human:notify_tips("Xin chọn thuộc tính tự chọn rồi hãy phá mạch")
            return
        end
    end

    -- 扣除金币和道具
    self:LuaFnCostMoneyWithPriority(selfId, cfg.money_cost)
    if cfg.item_id > 0 and cfg.item_count > 0 then
        self:LuaFnDelAvailableItem(selfId, cfg.item_id, cfg.item_count)
    end

    -- 判定成功率
    local roll = math.random(1, 100)
    if roll <= cfg.success_rate then
        -- 升级成功
        human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_LevelUp_Times, next_level)
        --skynet.logi("[DFeng] EssenceLevelUp SUCCESS: selfId=", selfId,
        --    " level=", cur_essence_level, "->", next_level, " select=", nSelectActive,
        --    " sel1=", nSelID1, " sel2=", nSelID2, " sel3=", nSelID3)
        human:notify_tips("Thông mạch thăng cấp thành công! Cấp: " .. next_level)

        -- 整十级破脉: 初始化对应心络孔位的属性类型和元素选择
        if next_level % 10 == 0 then
            local slot_index = next_level / 10  -- 10->1, 20->2, ..., 50->5
            if nSelectActive >= 1 and nSelectActive <= 4 then
                -- 设置孔位等级为1(0=未开启, 客户端level=0时读到item_id=-1/money=-1导致空白)
                human:set_dfeng_kw_slot_level(slot_index, 1)
                human:set_dfeng_kw_slot_active(slot_index, nSelectActive)
                -- sel值必须>=1, -1/0会导致客户端strTable[0]崩溃
                local sel1, sel2, sel3 = 1, 1, 1
                if nSelectActive == 1 then
                    sel1 = math.max(1, nSelID1)
                elseif nSelectActive == 2 then
                    sel1 = math.max(1, nSelID1)
                    sel2 = math.max(1, nSelID2)
                elseif nSelectActive == 3 then
                    sel1 = math.max(1, nSelID1)
                    sel2 = math.max(1, nSelID2)
                    sel3 = math.max(1, nSelID3)
                elseif nSelectActive == 4 then
                    sel1 = 1; sel2 = 2; sel3 = 3
                end
                human:set_dfeng_kw_slot_attrs(slot_index, sel1, sel2, sel3)
                --skynet.logi("[DFeng] PoMai INIT: slot=", slot_index,
                --    " active=", nSelectActive, " sel=", sel1, "/", sel2, "/", sel3)
            else
                --skynet.loge("[DFeng] PoMai INIT SKIP: invalid nSelectActive=", nSelectActive)
            end
        end

        if next_level % 10 == 0 then
            if human.ensure_dfeng_essence_kongwei_unlocked then
                human:ensure_dfeng_essence_kongwei_unlocked()
            end
            human:send_dfeng_essence_kongwei(-1)
        end
    else
        --skynet.logi("[DFeng] EssenceLevelUp FAIL: selfId=", selfId,
        --    " level=", cur_essence_level, " roll=", roll, " rate=", cfg.success_rate)
        human:notify_tips("Thông mạch thăng cấp thất bại")
    end

    -- 更新周计数(不管成功失败都消耗次数)
    -- 刷新属性和UI
    human:refresh_dfeng_attrib()
end

-- XSCRIPT: 心络强化升级
-- 客户端Peak_Second_PoMai_ButtonOK_OnClick发送2个参数:
--   param[0]=nIndex(0-19), param[1]=targetId
function edali_Martial_Arts:PoMaiLevelUp(selfId, nIndex, nTargetId)
    local human = self.scene:get_obj_by_id(selfId)
    if not human then return end

    if (human:get_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Open) or 0) < 1 then
        human:notify_tips("Võ cảnh chưa mở")
        return
    end

    nIndex = tonumber(nIndex) or -1
    if nIndex < 0 or nIndex > 19 then
        human:notify_tips("Ô tâm lạc không hợp lệ")
        return
    end

    local slot_index = nIndex + 1  -- 转1-based
    local section = slot_index     -- section = 孔位编号

    -- 检查通脉等级是否足够解锁此孔位
    local cur_essence_level = human:get_mission_data_by_script_id(ScriptGlobal.MD_DFeng_LevelUp_Times) or 0
    local req_level = section * 10
    if cur_essence_level < req_level then
        human:notify_tips("Cấp thông mạch không đủ, cần" .. req_level .. "cấp")
        return
    end

    -- 获取当前孔位等级
    local cur_level = human:get_dfeng_kw_slot_level(slot_index)
    if cur_level >= 8 then
        human:notify_tips("Tâm lạc này đã cấp tối đa")
        return
    end

    -- 检查孔位是否已初始化（通脉破脉时初始化level=1）
    local cur_active = human:get_dfeng_kw_slot_active(slot_index)
    if cur_level == 0 and cur_active == 0 then
        human:notify_tips("Xin hoàn thành thông mạch trước" .. req_level .. "cấp phá mạch để mở tâm lạc này")
        return
    end

    -- 读取配置
    local kw_cfg = configenginer:get_config("dfeng_essence_kw_info")
    if not kw_cfg or not kw_cfg[section] or not kw_cfg[section][cur_level] then
        skynet.loge("[DFeng] PoMaiLevelUp: config not found for section=", section, " level=", cur_level)
        human:notify_tips("Cấu hình sai")
        return
    end
    local cfg = kw_cfg[section][cur_level]

    -- 检查是否可以升级 (rate=-1表示不可升级)
    if cfg.success_rate < 0 then
        human:notify_tips("Tâm lạc này đã cấp tối đa")
        return
    end

    -- 检查消耗 (item_id=-1表示免费)
    if cfg.item_id > 0 and cfg.item_cost > 0 then
        local have_count = self:LuaFnGetAvailableItemCount(selfId, cfg.item_id) or 0
        if have_count < cfg.item_cost then
            human:notify_tips("Không đủ Tâm Lạc Đan")
            return
        end
    end

    if cfg.money_cost > 0 then
        local money = self:GetMoney(selfId) + self:GetMoneyJZ(selfId)
        if money < cfg.money_cost then
            human:notify_tips("Kim tệ không đủ")
            return
        end
    end

    -- 扣除消耗
    if cfg.item_id > 0 and cfg.item_cost > 0 then
        self:LuaFnDelAvailableItem(selfId, cfg.item_id, cfg.item_cost)
    end
    if cfg.money_cost > 0 then
        self:LuaFnCostMoneyWithPriority(selfId, cfg.money_cost)
    end

    -- 判定成功
    local roll = math.random(1, 100)
    if roll <= cfg.success_rate then
        local new_level = cur_level + 1
        human:set_dfeng_kw_slot_level(slot_index, new_level)
        if new_level >= 8 and human.ensure_dfeng_essence_kongwei_unlocked then
            human:ensure_dfeng_essence_kongwei_unlocked()
        end
        --skynet.logi("[DFeng] PoMaiLevelUp SUCCESS: slot=", slot_index, " level=", cur_level, "->", new_level)
        human:notify_tips("Cường hóa tâm lạc thành công! Cấp: " .. new_level)
    else
        --skynet.logi("[DFeng] PoMaiLevelUp FAIL: slot=", slot_index, " level=", cur_level, " roll=", roll)
        human:notify_tips("Cường hóa tâm lạc thất bại")
    end

    -- 刷新UI
    human:refresh_dfeng_attrib()
    human:send_dfeng_essence_kongwei(-1)
end

-- XSCRIPT: 心络重置属性(选择元素类型)
-- 客户端Peak_Second_PoMai_ResetButton_Clicked发送6个参数:
--   param[0]=nIndex(0-19), param[1]=nSelectedActive(1-4)
--   param[2]=元素1, param[3]=元素2, param[4]=元素3, param[5]=targetId
function edali_Martial_Arts:PoMaiResetActive(selfId,
    nIndex, nSelectedActive, param1, param2, param3, nTargetId)

    local human = self.scene:get_obj_by_id(selfId)
    if not human then return end

    if (human:get_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Open) or 0) < 1 then
        human:notify_tips("Võ cảnh chưa mở")
        return
    end

    nIndex = tonumber(nIndex) or -1
    nSelectedActive = tonumber(nSelectedActive) or 0
    param1 = tonumber(param1) or 0
    param2 = tonumber(param2) or 0
    param3 = tonumber(param3) or 0

    if nIndex < 0 or nIndex > 19 then
        human:notify_tips("Ô tâm lạc không hợp lệ")
        return
    end

    if nSelectedActive < 1 or nSelectedActive > 4 then
        human:notify_tips("Loại thuộc tính không hợp lệ")
        return
    end

    local slot_index = nIndex + 1

    -- 检查孔位等级 >= 1 才能设置属性
    local cur_level = human:get_dfeng_kw_slot_level(slot_index)
    if cur_level < 1 then
        human:notify_tips("Xin cường hóa tâm lạc lên cấp 1 trước")
        return
    end

    -- 检查重置消耗(归脉丹 38003579 × 1，首次设置免费)
    local cur_active = human:get_dfeng_kw_slot_active(slot_index)
    if cur_active > 0 then
        local reset_item_id = 38003579
        local reset_item_count = 1
        local have = self:LuaFnGetAvailableItemCount(selfId, reset_item_id) or 0
        if have < reset_item_count then
            human:notify_tips("Không đủ Quy Mạch Đan")
            return
        end
        self:LuaFnDelAvailableItem(selfId, reset_item_id, reset_item_count)
    end

    -- 设置属性类型和元素选择
    human:set_dfeng_kw_slot_active(slot_index, nSelectedActive)

    local sel1, sel2, sel3 = 1, 1, 1
    if nSelectedActive == 1 then
        sel1 = math.max(1, param1)
    elseif nSelectedActive == 2 then
        sel1 = math.max(1, param1)
        sel2 = math.max(1, param2)
    elseif nSelectedActive == 3 then
        sel1 = math.max(1, param1)
        sel2 = math.max(1, param2)
        sel3 = math.max(1, param3)
    elseif nSelectedActive == 4 then
        sel1 = 1; sel2 = 2; sel3 = 3
    end
    human:set_dfeng_kw_slot_attrs(slot_index, sel1, sel2, sel3)

    --skynet.logi("[DFeng] PoMaiResetActive: slot=", slot_index, " active=", nSelectedActive,
    --    " sel1=", sel1, " sel2=", sel2, " sel3=", sel3)
    human:notify_tips("Thuộc tính tâm lạc đã đặt")

    human:refresh_dfeng_attrib()
    human:send_dfeng_essence_kongwei(-1)
end

function edali_Martial_Arts:CheckAccept(selfId) end
function edali_Martial_Arts:OnAccept(selfId) end
function edali_Martial_Arts:OnAbandon(selfId) end
function edali_Martial_Arts:OnContinue(selfId, targetId) end
function edali_Martial_Arts:CheckSubmit(selfId) end
function edali_Martial_Arts:OnSubmit(selfId, targetId, selectRadioId) end
function edali_Martial_Arts:OnKillObject(selfId, objdataId, objId) end
function edali_Martial_Arts:OnEnterArea(selfId, zoneId) end
function edali_Martial_Arts:OnItemChanged(selfId, itemdataId) end
return edali_Martial_Arts
