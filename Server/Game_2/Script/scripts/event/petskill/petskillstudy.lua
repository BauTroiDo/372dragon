--珍兽技能学习UI 3
--普通
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local petskillstudy = class("petskillstudy", script_base)

local g_tbabaymoney  = {
    [5]		= 5000,
    [15]	= 6000,
    [20]	= 7000,
    [25]	= 7000,
    [35]	= 10000,
    [45]	= 15000,
    [55]	= 25000,
    [65]	= 40000,
    [75]	= 55000,
    [85]	= 70000,
    [95]	= 85000,
    [105]	= 100000,
}

local g_YuanBaoCosts = {
	[1] = 6026,
	[5] = 6350,
	[15] = 6440,
	[20] = 6530,
	[30] = 6710,
	[45] = 10949,
	[55] = 11390,
	[65] = 12110,
	[75] = 17150,
	[85] = 17870,
	[95] = 65900,
}

function petskillstudy:OnEnumerate(_, selfId, targetId, sel)
    if sel == 1 then
		self:BeginUICommand()
        self:UICommand_AddInt(targetId)	--调用新版珍兽技能学习界面 UI 223
		self:EndUICommand()
		self:DispatchUICommand(selfId, 223)
	elseif sel == 2 then
		self:BeginUICommand()
        self:UICommand_AddInt(targetId)	
		self:UICommand_AddInt(2)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 20090929)
	else
		self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(sel)		--调用技能学习界面
		self:EndUICommand()
		self:DispatchUICommand(selfId, 3)
	end
end

local g_Propagate = {
    [35] = { ItemTableIndex = 30503017, cost_money = 76500, warn = "Cần dùng Hoàn Đồng Thiên Thư sơ cấp"},
    [65] = { ItemTableIndex = 30503018, cost_money = 76500, warn = "Cần dùng Hoàn Đồng Thiên Thư trung cấp"},
    [85] = { ItemTableIndex = 30503019, cost_money = 76500, warn = "Cần dùng Hoàn Đồng Thiên Thư cao cấp"},
    [95] = { ItemTableIndex = 30503020, cost_money = 76500, warn = "Cần dùng Hoàn Đồng Thiên Thư siêu cấp"},
}

function petskillstudy:OnPropagate(selfId, targetId, petHid, petLid, lock_growth_rate, lock_perception, BagPos)
    local by_type = self:GetPetType(selfId, petHid, petLid)
    local data_id = self:GetPetDataID(selfId, petHid, petLid) 
    if by_type == define.PET_TYPE.PET_TYPE_VARIANCE then
        self:notify_tips(selfId, "Pet đột biến không hoàn đồng được")
        return
    end
    local hhd = self:GetPetHaveHuanHua(selfId, petHid, petLid)
    if data_id ~= 27561 and data_id ~= 24661 and data_id ~= 24741 and data_id ~= 24821 and data_id ~= 27711 then
        if hhd then
            self:notify_tips(selfId, "Pet đã huyễn hóa không hoàn đồng được")
            return
        end
    end
    local _, spouse = self:GetPetSpouseGUID(selfId, petHid, petLid)
    if not spouse:is_null() then
        self:notify_tips(selfId, "Pet đã phối giống không hoàn đồng được")
        return
    end
    local take_level = self:GetPetTakeLevel(data_id)
    local select_take_level
    local take_leves = { 35, 65, 85, 95}
    for _, tl in ipairs(take_leves) do
        if tl >= take_level then
            select_take_level = tl
            break
        end
    end
    assert(select_take_level, take_level)
    local config = g_Propagate[select_take_level]
    assert(config, select_take_level)
    local item_index = self:LuaFnGetItemTableIndexByIndex(selfId, BagPos)
    if item_index ~= config.ItemTableIndex then
        self:notify_tips(selfId, config.warn)
        return 0
    end
    local PlayerMoney = self:GetMoney(selfId ) + self:GetMoneyJZ(selfId)  --交子普及 Vega
    if PlayerMoney < config.cost_money then
        self:notify_tips(selfId, "  Xin lỗi, kim tiền trên người ngài không đủ #{_EXCHG100}!" )
        return 0
    end
    if data_id == 27561 or data_id == 24661 or data_id == 24741 or data_id == 24821 or data_id == 27711 then
        local grow_rate = self:LuaFnGetPeGrowthRate(selfId, petHid, petLid) * 1000
        if grow_rate < 2188 then
            self:LuaFnSetPetData(selfId, petHid, petLid, "growth_rate",2.188)
        else
            self:notify_tips(selfId, "  Pet này không hỗ trợ hoàn đồng" )
            return
        end
    else
        local result = self:PetPropagate(selfId, petHid, petLid, lock_growth_rate, lock_perception)
        if not result then
            self:notify_tips(selfId, "  Pet này không hỗ trợ hoàn đồng" )
            return 0
        end
    end
    self:LuaFnCostMoneyWithPriority(selfId, config.cost_money)
    self:LuaFnDecItemLayCount(selfId, BagPos, 1)
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
    return 1
end

function petskillstudy:OnQuickPropagate(selfId, targetId, petHid, petLid)
    local by_type = self:GetPetType(selfId, petHid, petLid)
    print("by_type =", by_type)
    if by_type == define.PET_TYPE.PET_TYPE_VARIANCE then
        self:notify_tips(selfId, "Pet đột biến không hoàn đồng được")
        return
    end
    local hhd = self:GetPetHaveHuanHua(selfId, petHid, petLid)
    if hhd then
        self:notify_tips(selfId, "Pet đã huyễn hóa không hoàn đồng được")
        return
    end
    local _, spouse = self:GetPetSpouseGUID(selfId, petHid, petLid)
    if not spouse:is_null() then
        self:notify_tips(selfId, "Pet đã phối giống không hoàn đồng được")
        return
    end
    local data_id = self:GetPetDataID(selfId, petHid, petLid)
    local take_level = self:GetPetTakeLevel(data_id)
    local cost_yuanbao = g_YuanBaoCosts[take_level]
    local PlayerYuanbao = self:GetYuanBao(selfId)
    if PlayerYuanbao < cost_yuanbao then
        self:notify_tips(selfId, "Nguyên bảo không đủ")
        return
    end
    local result = self:PetPropagate(selfId, petHid, petLid, 0, 1, true)
    if not result then
        self:notify_tips(selfId, "Pet này không hỗ trợ hoàn đồng")
        return
    end
    self:LuaFnCostYuanBao(selfId, cost_yuanbao)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
    return 1
end

local YuanBaoPay_Items = {
    [30503017] = true,
    [30503018] = true,
    [30503019] = true,
    [30503020] = true
}
function petskillstudy:PetHuantong_Yuanbao_Pay(selfId, ItemIndex, check)
    if YuanBaoPay_Items[ItemIndex] then
        self:CallScriptFunction(888902, "yuanbao_pay", selfId, ItemIndex, check, 2015101414, "#{ZSYB_151109_07")
    end
end

return petskillstudy