local gbk = require "wire_charset"
local define = require "define"
local class = require "class"
local human_item_logic = require "human_item_logic"
local script_base = require "script_base"
local lingwu = class("lingwu", script_base)
local Prescriptions = {
    { 1154, 1155, 1160, 1161, 1166, 1167, 1172, 1173, 1178, 1179, 1184, 1185},
    { 1156, 1157, 1162, 1163, 1168, 1169, 1174, 1175, 1180, 1181, 1186, 1187},
    { 1158, 1159, 1164, 1165, 1170, 1171, 1176, 1177, 1182, 1183, 1188, 1189}
}
function lingwu:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:GetName(targetId) == "墨知愁" then
        local AbilityLevel = self:QueryHumanAbilityLevel(selfId, 54)
        if AbilityLevel < 1 then
            caller:AddNumTextWithTarget(self.script_id, "#{SZXT_221216_60}", 6, 11)
        end
        caller:AddNumTextWithTarget(self.script_id, "#{SZXT_221216_21}", 6, 8888)
    end
    if self:GetName(targetId) == "江行云" then
        local AbilityLevel = self:QueryHumanAbilityLevel(selfId, 55)
        if AbilityLevel < 1 then
            caller:AddNumTextWithTarget(self.script_id, "#{SZXT_221216_65}", 6, 12)
        end
        caller:AddNumTextWithTarget(self.script_id, "#{SZXT_221216_21}", 6, 8888)
    end
    if self:GetName(targetId) == "阮枫眠" then
        local AbilityLevel = self:QueryHumanAbilityLevel(selfId, 56)
        if AbilityLevel < 1 then
            caller:AddNumTextWithTarget(self.script_id, "#{SZXT_221216_67}", 6, 13)
        end
        caller:AddNumTextWithTarget(self.script_id, "#{SZXT_221216_21}", 6, 8888)
    end
    if self:GetName(targetId) == "莫问之" then
        caller:AddNumTextWithTarget(self.script_id, "#{SZXT_221216_61}", 6, 21)
        caller:AddNumTextWithTarget(self.script_id, "#{SZXT_221216_132}", 6, 22)
        caller:AddNumTextWithTarget(self.script_id, "#{SZXT_221216_180}", 6, 24)
        caller:AddNumTextWithTarget(self.script_id, "#{SZXT_221216_161}", 6, 23)
        caller:AddNumTextWithTarget(self.script_id, "#{SZXT_221216_86}", 6, 25)
        caller:AddNumTextWithTarget(self.script_id, "#{SZXT_230410_11}", 6, 26)
        caller:AddNumTextWithTarget(self.script_id, "#{SZXT_221216_62}", 11, 91)
        caller:AddNumTextWithTarget(self.script_id, "#{SZXT_221216_66}", 11, 92)
    end
end

function lingwu:OnDefaultEvent(selfId, targetId, arg, index)
    if index == 11 then
        self:study_zhufa_wuji(selfId)
        return
    end
    if index == 12 then
        self:study_zhufa_shouxin(selfId)
        return
    end
    if index == 13 then
        self:study_zhufa_pozhen(selfId)
        return
    end
    if index == 21 then
        self:BeginUICommand()
        self:UICommand_AddInt(0)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 88880801)
        return
    end
    if index == 22 then
        self:BeginUICommand()
        self:UICommand_AddInt(0)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 88880805)
        return
    end
    if index == 23 then
        self:BeginUICommand()
        self:UICommand_AddInt(0)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 88880804)
        return
    end
    if index == 25 then
        self:BeginUICommand()
        self:UICommand_AddInt(0)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 88880807)
        return
    end
    if index == 26 then
        self:BeginUICommand()
        self:UICommand_AddInt(0)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 88880810)
        return
    end
    if index == 91 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SZXT_221216_68}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 92 then
        self:BeginEvent(self.script_id)
        self:AddNumText("#{SZXT_221216_64}", 11, 9201)
        self:AddNumText("#{SZXT_221216_214}", 11, 9202)
        self:AddNumText("#{SZXT_221216_216}", 11, 9203)
        self:AddNumText("#{SZXT_221216_218}", 11, 9204)
        self:AddNumText("#{SZXT_221216_220}", 11, 9205)
        self:AddNumText("#{SZXT_221216_222}", 11, 9206)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 9201 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SZXT_221216_69}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 9202 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SZXT_221216_215}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 9203 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SZXT_221216_217}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 9204 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SZXT_221216_219}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 9205 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SZXT_221216_221}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 9206 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SZXT_221216_223}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 24 then
        local cost_di_jie = self:GetMissionData(selfId, define.MD_ENUM.MD_COST_DI_JIE_SHU_YU_QUAN)
        local cost_tian_jie = self:GetMissionData(selfId, define.MD_ENUM.MD_COST_TIAN_JIE_SHU_YU_QUAN)
        local getd_di_jie = self:GetMissionData(selfId, define.MD_ENUM.MD_GETD_DI_JIE_SHU_YU_QUAN)
        local getd_tian_jie = self:GetMissionData(selfId, define.MD_ENUM.MD_GETD_TIAN_JIE_SHU_YU_QUAN)
        self:BeginEvent(self.script_id)
        local di = (cost_di_jie - getd_di_jie * 60) // 60
        local tian = (cost_tian_jie - getd_tian_jie * 60) // 60
        di = di < 0 and 0 or di
        tian = tian < 0 and 0 or tian
        self:BeginEvent(self.script_id)
        local str = self:ContactArgs("#{SZXT_221216_181", cost_di_jie, cost_tian_jie, di, tian)
        self:AddText(str .. "}")
        self:AddNumText("#{SZXT_221216_182}", 6, 2401)
        self:AddNumText("#{SZXT_221216_183}", 6, 2402)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 2401 then
        self:AwardShuYuQuan(selfId, define.MD_ENUM.MD_COST_DI_JIE_SHU_YU_QUAN, define.MD_ENUM.MD_GETD_DI_JIE_SHU_YU_QUAN, 60, 20600007)
        self:OnDefaultEvent(selfId, targetId, arg, 24)
        return
    end
    if index == 2402 then
        self:AwardShuYuQuan(selfId, define.MD_ENUM.MD_COST_TIAN_JIE_SHU_YU_QUAN, define.MD_ENUM.MD_GETD_TIAN_JIE_SHU_YU_QUAN, 60, 20600008)
        self:OnDefaultEvent(selfId, targetId, arg, 24)
        return
    end
    if index == 8888 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SZXT_221216_255}")
        self:AddNumText("#{SZXT_221216_61}", 6, 21)
        self:AddNumText("#{SZXT_221216_132}", 6, 22)
        self:AddNumText("#{SZXT_221216_180}", 6, 24)
        self:AddNumText("#{SZXT_221216_161}", 6, 23)
        self:AddNumText("#{SZXT_221216_86}", 6, 25)
        self:AddNumText("#{SZXT_230410_11}", 6, 26)
        self:AddNumText("#{SZXT_221216_62}", 11, 91)
        self:AddNumText("#{SZXT_221216_66}", 11, 92)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
end

function lingwu:AwardShuYuQuan(selfId, xi_key, get_key, sub_value, item_id)
    local cost_chu_hun_sui = self:GetMissionData(selfId, xi_key)
    local get_count = self:GetMissionData(selfId, get_key)
    local count = (cost_chu_hun_sui - get_count * sub_value) // sub_value
    if count > 0 then
        self:BeginAddItem()
        self:AddItem(item_id, count)
        local r = self:EndAddItem(selfId)
        if r then
            self:AddItemListToHuman(selfId)
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 149, 0)
            self:SetMissionData(selfId, get_key, get_count + count)
            self:notify_tips(selfId, "Lĩnh thưởng thành công.")
        else
            self:notify_tips(selfId, "Túi hành trang không đủ chỗ")
        end
    else
        self:notify_tips(selfId, "Không đủ lần nhận")
    end
    return
end

function lingwu:study_zhufa_wuji(selfId)
    self:SetHumanAbilityLevel(selfId, 54, 1)
    self:notify_tips(selfId, "Bạn học được chú pháp - Thủ Tâm!")
    local pres = Prescriptions[1]
    for _, p in ipairs(pres) do
        self:SetPrescription(selfId, p, 1 )
    end
end

function lingwu:study_zhufa_shouxin(selfId)
    self:SetHumanAbilityLevel(selfId, 55, 1)
    self:notify_tips(selfId, "Bạn học được chú pháp - Thủ Tâm!")
    local pres = Prescriptions[2]
    for _, p in ipairs(pres) do
        self:SetPrescription(selfId, p, 1 )
    end
end

function lingwu:study_zhufa_pozhen(selfId)
    self:SetHumanAbilityLevel(selfId, 56, 1)
    self:notify_tips(selfId, "Bạn học được chú pháp - Phá Trận!")
    local pres = Prescriptions[3]
    for _, p in ipairs(pres) do
        self:SetPrescription(selfId, p, 1 )
    end
end

function lingwu:AbilityCheck()
    return define.OPERATE_RESULT.OR_OK
end

function lingwu:CheckForResult()
    return define.OPERATE_RESULT.OR_OK
end
local g_LingWuStuffID = 
{
    [1154] = 20600009,[1155] = 20600010,[1156] = 20600011,[1157] = 20600012,[1158] = 20600013,[1159] = 20600014,[1160] = 20600015,[1161] = 20600016,[1162] = 20600017,
    [1163] = 20600018,[1164] = 20600019,[1165] = 20600020,[1166] = 20600021,[1167] = 20600022,[1168] = 20600023,[1169] = 20600024,[1170] = 20600025,[1171] = 20600026,
    [1172] = 20600027,[1173] = 20600028,[1174] = 20600029,[1175] = 20600030,[1176] = 20600031,[1177] = 20600032,[1178] = 20600033,[1179] = 20600034,[1180] = 20600035,
    [1181] = 20600036,[1182] = 20600037,[1183] = 20600038,[1184] = 20600039,[1185] = 20600040,[1186] = 20600041,[1187] = 20600042,[1188] = 20600043,[1189] = 20600044,
}
function lingwu:Do_Detection(selfId,g_stuffid,g_CurrentRecipe)
    if g_CurrentRecipe < 1154 or g_CurrentRecipe > 1189 then
        self:notify_tips(selfId,"Recipeid error")
        return
    end
    if g_stuffid < 20600009 or g_stuffid > 20600044 then
        self:notify_tips(selfId,"stuffid error")
        return
    end
    local Stuffid = g_LingWuStuffID[g_CurrentRecipe]
    if Stuffid == nil then
        self:notify_tips(selfId,"stuffidinfo error")
        return
    end
    if Stuffid ~= g_stuffid then
        self:notify_tips(selfId,"#{SZXT_221216_92}")
        return
    end
    if self:LuaFnGetAvailableItemCount(selfId,g_stuffid) < 1 then
        self:notify_tips(selfId,string.format("Túi chưa có %s hoặc đã khóa.",self:GetItemName(g_stuffid)))
        return
    end
    self:BeginUICommand()
    self:EndUICommand()
    self:DispatchUICommand(selfId, 2023100901)
end

function lingwu:AbilityConsume(selfId, pres_id, prescription)
    local human = self:get_scene():get_obj_by_id(selfId)
    local logparam = {}
	local del
    for i = 1, 5 do
        local key = string.format("Stuff%dID", i)
        local id = prescription[key]
        key = string.format("Stuff%dnum", i)
        local num = prescription[key]
		if id and num and id > 0 and num > 0 then
        -- if id ~= define.INVAILD_ID then
			del = human_item_logic:del_available_item(logparam, human, id, num)
            -- del = human_item_logic:erase_material_item(logparam, human, id, num)
			assert(del, string.format("Thao tác thất bại, lý do trừ đạo cụ thất bại::ID=%d, NUM=%d",id,num))
        end
    end
    logparam = {}
    local ability_opera = human:get_ability_opera()
    local mat_bag_index = ability_opera.mat_bag_index
    local mat = human:get_prop_bag_container():get_item(mat_bag_index)
    -- P0 fix: mat container item may be nil, return safely instead of crashing
    if not mat then return end
    ability_opera.mat_index = mat:get_index()
    del = human_item_logic:dec_item_lay_count(logparam, human, mat_bag_index, 1)
	assert(del, string.format("Thao tác thất bại, lý do trừ đạo cụ thất bại::%d",mat:get_index()))
    local cool_down_id = prescription["冷却组ID"]
    local cool_down_time = prescription["冷却时间(毫秒)"]
    if cool_down_id >= 0 and cool_down_time > 0 then
        human:set_cool_down(cool_down_id, cool_down_time)
    end
end

lingwu.Mat2Quality = {
    [20600000] = {
        { level = 0, attr_count = { 1, 3}},
        { level = 1, attr_count = { 1, 3}},
    },
    [20600001] = {
        { level = 1, attr_count = { 1, 3}},
        { level = 2, attr_count = { 1, 3}},
    },
    [20600002] = {
        { level = 2, attr_count = { 1, 3}},
        { level = 3, attr_count = { 1, 3}},
    },
    [20600003] = {
        { level = 3, attr_count = { 1, 3}},
    },
    [20600004] = {
        { level = 3, attr_count = {3, 3}},
    },
}
function lingwu:AbilityProduce(selfId, recipeId, prescription)
	if not prescription then
		return define.OPERATE_RESULT.OR_ERROR
	end
    local human = self:get_scene():get_obj_by_id(selfId)
    local result_id = prescription["ResultID"]
    local result_num = prescription["ResultNum"]
    local ability_id = prescription["对应技能ID"]
    local ability_opera = human:get_ability_opera()
    if result_num and result_num > 0 then
        local mat_index = ability_opera.mat_index
        local quality = self.Mat2Quality[mat_index]
		if not quality then
			return define.OPERATE_RESULT.OR_ERROR
		end
		-- local msg = "lingwu:AbilityProduce  quality 为nil值 mat_index = "..tostring(mat_index)
		-- assert(quality,msg)
        quality = quality[math.random(1, #quality)]
        result_id = result_id + quality.level * 36
        local attr_num = math.random(quality.attr_count[1], quality.attr_count[2])
        self:TryRecieveItem(selfId, result_id, true, quality, { attr_num = attr_num})
        -- self:TryRecieveItem(selfId, result_id, true, quality)
-- self:SceneBroadcastMsgEx("result_id:"..tostring(result_id))		
    end
    self:LuaFnSendAbilitySuccessMsg(selfId, ability_id, recipeId, result_id)
    return define.OPERATE_RESULT.OR_OK
end

local LingWuWashMaterials = {
    [0] = { [20600005] = 0, cost_money = 1000 },
    [1] = { [20600005] = 0, cost_money = 2000 },
    [2] = { [20600045] = 0, [20600007] = 2, cost_money = 30000 },
    [3] = { [20600046] = 0, [20600008] = 2, cost_money = 50000 }
}

function lingwu:LingYu_Wash(selfId, targetId, BagPosLingWu, BagPosM)
    print("lingwu:LingYu_Wash", selfId, BagPosLingWu, BagPosM)
    local lingwu_index = self:GetBagItemIndex(selfId, BagPosLingWu)
    local lingwu_class = self:GetLingWuClass(lingwu_index)
    if lingwu_class == define.INVAILD_ID then
        self:notify_tips(selfId, "Chỉ Linh Võ mới chú luyện được!")
        return
    end
    local is_bind = self:GetBagItemIsBind(selfId, BagPosLingWu)
    if not is_bind then
        self:notify_tips(selfId, "Chỉ Linh Võ khóa mới chú luyện được")
        return
    end
    local materials = LingWuWashMaterials[lingwu_class]
    local mat_index = self:GetBagItemIndex(selfId, BagPosM)
    if materials[mat_index] == nil then
        self:notify_tips(selfId, "Nguyên liệu không khớp!")
        return
    end
    local cost_money = materials.cost_money
    local lock_count = materials[mat_index]
    local PlayerMoney = self:GetMoney(selfId ) +  self:GetMoneyJZ(selfId)
    if PlayerMoney < cost_money then
        self:notify_tips(selfId, "Kim tệ không đủ")
        return
    end
    local del = self:LuaFnDecItemLayCount(selfId, BagPosM, 1)
	if del then
		del = self:LuaFnCostMoneyWithPriority(selfId, cost_money) --扣钱
		if del then
			self:LingWuWash(selfId, BagPosLingWu, lock_count)
			self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 148, 0)
		end
	end
end

function lingwu:LingYu_Switch(selfId, targetId, BagPosLingWu)
    self:LingWuSwitch(selfId, BagPosLingWu)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 148, 0)
end

function lingwu:LingYuTransition(selfId, targetId, BagPosFrom, BagPosTo)
    local from_index = self:GetBagItemIndex(selfId, BagPosFrom)
    local from_class = self:GetLingWuClass(from_index)
    local to_index = self:GetBagItemIndex(selfId, BagPosTo)
    local to_class = self:GetLingWuClass(to_index)
    if from_class ~= to_class then
        self:notify_tips(selfId, "Cùng phẩm chất mới chuyển được")
        return
    end
    local from_attr_count = self:GetLingWuAttrCount(selfId, BagPosFrom)
    local to_attr_count = self:GetLingWuAttrCount(selfId, BagPosFrom)
    if from_attr_count ~= to_attr_count then
        self:notify_tips(selfId, "Cùng số dòng mới chuyển được")
        return
    end
    self:LuaFnLingWuTransition(selfId, BagPosFrom, BagPosTo)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 148, 0)
end

local RecycleAwards = {
    [0] = 20600005,
    [1] = 20600006,
    [2] = 20600045,
    [3] = 20600046,
}

function lingwu:LingYuRecycle(selfId, targetId, BagPos)
    local lingwu_index = self:GetBagItemIndex(selfId, BagPos)
    local lingwu_class = self:GetLingWuClass(lingwu_index)
    local award = RecycleAwards[lingwu_class]
    if award == nil then
        self:notify_tips(selfId, "Không hỗ trợ thu hồi")
        return
    end
    self:EraseItem(selfId, BagPos)
    self:TryRecieveItem(selfId, award, true, 1)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 148, 0)
end

local WashItemCompound = {
    [20600005] = 20600006,
    [20600006] = 20600045,
    [20600045] = 20600046,
}

function lingwu:LingYuWashItemCompound(selfId, targetId, item_index)
    local product = WashItemCompound[item_index]
    if product == nil then
        self:notify_tips(selfId, "Không hỗ trợ hợp thành")
        return
    end
    local count = self:LuaFnGetAvailableItemCount(selfId, item_index)
    if count < 4 then
        self:notify_tips(selfId, "Không đủ số nguyên liệu hợp thành")
        return
    end
    self:LuaFnDelAvailableItem(selfId, item_index, 4)
    self:TryRecieveItem(selfId, product, true, 1)
end

local UnbindMats = {
    [2] = 38002817,
    [3] = 38002818,
}
function lingwu:LingYuUnbind(selfId, targetId, BagPos)
    local lingwu_index = self:GetBagItemIndex(selfId, BagPos)
    local lingwu_class = self:GetLingWuClass(lingwu_index)
    local mat = UnbindMats[lingwu_class]
    if mat == nil then
        self:notify_tips(selfId, "Không hỗ trợ gỡ khóa")
        return
    end
    local count = self:LuaFnGetAvailableItemCount(selfId, mat)
    if count <= 0 then
        self:notify_tips(selfId, "Không có lệnh gỡ khóa tương ứng")
        return
    end
    local gem_count = self:GetGemEmbededCount(selfId, BagPos)
    if gem_count > 0 then
        self:notify_tips(selfId, "Gỡ khóa lỗi")
        return
    end
    local del = self:LuaFnDelAvailableItem(selfId, mat, 1)
	if del then
		self:LuaFnItemUnbind(selfId, BagPos)
	end
end

return lingwu