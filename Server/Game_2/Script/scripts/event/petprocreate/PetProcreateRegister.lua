--珍兽繁殖
local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local configenginer = require "configenginer":getinstance()
local PetProcreateRegister = class("PetProcreateRegister", script_base)

-- 加权浮动资质计算（替换C++底层的随机浮动）
local function calc_float_perception(base)
	local rate = math.random(100)
	local float
	if rate <= 50 then
		float = math.random(1000, 1030) / 1000    -- 50% 平庸
	elseif rate <= 75 then
		float = math.random(1030, 1060) / 1000    -- 25% 一般
	elseif rate <= 88 then
		float = math.random(1060, 1100) / 1000    -- 13% 良好
	elseif rate <= 95 then
		float = math.random(1100, 1150) / 1000    -- 7% 优秀
	elseif rate <= 99 then
		float = math.random(1150, 1200) / 1000    -- 4% 卓越
	else
		float = math.random(1200, 1300) / 1000    -- 1% 极品
	end
	return math.ceil(base * float)
end

function PetProcreateRegister:OnDefaultEvent(selfId, targetId)
	local checkRet = self:LuaFnCheckCallPetProcreateRegisterUI(selfId, targetId)
	if checkRet then
		local ret = self:LuaFnCallPetProcreateRegisterUI(selfId, targetId, 26)
		if ret then
			self:Msg2Player(selfId, "Thực hiện thành công", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
		else
			self:Msg2Player(selfId, "Thực hiện thất bại",  define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
		end
	end
end

function PetProcreateRegister:OnEnumerate(caller)
    caller:AddNumTextWithTarget(self.script_id, "Trân thú sinh sản", 6, self.script_id)
end

local PetLoveNestItemIndex = 30309794
local g_rate = {}
g_rate[1] = {1000}
g_rate[2] = {300,1000}
g_rate[3] = {200,600,1000}
g_rate[4] = {100,300,600,1000}
g_rate[5] = {50,100,300,600,1000}
g_rate[6] = {100,200,300,400,500,1000}
g_rate[7] = {100,200,300,400,500,600,1000}
g_rate[8] = {100,200,300,400,500,600,700,1000}

--指定珍兽繁殖概率  
--[珍兽宝宝的ID] = {
-- rate = {多少变异的概率,随机总概率为1000},

-- str_perception -- 力量资质
-- spr_perception -- 灵气资质
-- con_perception -- 体力资质
-- int_perception -- 定力资质
-- dex_perception -- 身法资质

-- str_perception = {n_min = 2200,n_max = 2800}}

-- 虬龙出顶变概率变大  顶变灵气资质在2000-2300  其他资质照常
-- 老鼠出顶变概率变大  顶变力量资质在2200-2800  其他资质照常

-- 鸟人出顶变概率变大  顶变灵气资质在2200-2800  其他资质照常

-- 麒麟出顶变概率变大  顶变灵气资质在2200-2800  其他资质照常

-- 当扈出顶变概率变大  顶变灵气资质在2200-2800  其他资质照常

-- 穷奇出顶变概率变大  顶变力量资质在2200-2800  其他资质照常
local pet_special_procreate = {
	[22209]		= {rate = {100,200,300,400,500,1000},spr_perception = {n_min = 2200,n_max = 2300}},-- 虬龙
	[6619]		= {rate = {100,200,300,400,500,1000},str_perception = {n_min = 2200,n_max = 2800}},
	[6639]		= {rate = {100,200,300,400,500,1000},spr_perception = {n_min = 2200,n_max = 2800}},
	[22489]		= {rate = {50,100,150,200,300,400,500,1000},spr_perception = {n_min = 2200,n_max = 2800}},-- 麒麟
	[8339]		= {rate = {50,100,150,200,300,400,500,1000},spr_perception = {n_min = 2200,n_max = 2800}},-- 当扈
	[22059]		= {rate = {50,100,200,300,400,500,1000},str_perception = {n_min = 2200,n_max = 2800}},-- 穷奇
	[22069]		= {rate = {50,100,150,200,300,400,500,1000},str_perception = {n_min = 2200,n_max = 2800}},-- 穷奇

}


function PetProcreateRegister:OnSignalPetProcreateRegister(selfId,  targetId, mainPetGuidH, mainPetGuidL, assisPetGuidH, assisPetGuidL, LoveNestPos)
	print("PetProcreateRegister:OnSignalPetProcreateRegister", selfId, targetId, mainPetGuidH, mainPetGuidL, assisPetGuidH, assisPetGuidL, LoveNestPos)
	local LoveNestIndex = self:GetBagItemIndex(selfId, LoveNestPos)
	if LoveNestIndex ~= PetLoveNestItemIndex then
		self:notify_tips(selfId, "Xin hãy đặt Ái Tâm Tiểu Ốc vào")
		return
	end
	local ret1, SpouseGUID_1 = self:GetPetSpouseGUID(selfId, mainPetGuidH, mainPetGuidL)
	local ret2, SpouseGUID_2 = self:GetPetSpouseGUID(selfId, assisPetGuidH, assisPetGuidL)
	if not ret1 or not ret2 then
		self:notify_tips(selfId, "Lấy trân thú thất bại")
		return
	end
	local space_count = self:LuaFnGetPetContainerSpaceCount(selfId)
	if space_count < 2 then
		self:notify_tips(selfId, "Ô trân thú không đủ chỗ, không phối giống được" )
		return
	end
	if not ((SpouseGUID_1:is_null() and SpouseGUID_2:is_null() )
		or ( SpouseGUID_1 == { m_uHighSection = assisPetGuidH , m_uLowSection = assisPetGuidL} and SpouseGUID_2 == { m_uHighSection = mainPetGuidH, m_uLowSection = mainPetGuidL} )) then
		self:notify_tips(selfId, "Trân thú mang đến không phải là phối ngẫu của nhau")
		return
	end
	local PlayerMoney = self:GetMoney(selfId ) +  self:GetMoneyJZ(selfId)
	if PlayerMoney < 20000 then
		self:notify_tips(selfId, "Giao Tử hoặc kim tệ mang theo không đủ")
		return
	end
	local num_1 = self:GetPetNumOfReproductions(selfId, mainPetGuidH, mainPetGuidL)
	if num_1 <= 0 then
		self:notify_tips(selfId, "Không đủ lần phối giống")
		return
	end
	local num_2 = self:GetPetNumOfReproductions(selfId, assisPetGuidH, assisPetGuidL)
	if num_2 <= 0 then
		self:notify_tips(selfId, "Không đủ lần phối giống")
		return
	end
	local huanhua_1 = self:GetPetHaveHuanHua(selfId, mainPetGuidH, mainPetGuidL)
	if huanhua_1 then
		self:notify_tips(selfId, "Trân thú huyễn hóa, không phối giống được")
		return
	end
	local huanhua_2 = self:GetPetHaveHuanHua(selfId, assisPetGuidH, assisPetGuidL)
	if huanhua_2 then
		self:notify_tips(selfId, "Trân thú huyễn hóa, không phối giống được")
		return
	end
	local by_type_1 = self:GetPetByType(selfId, mainPetGuidH, mainPetGuidL)
	local data_id_1 = self:GetPetDataID(selfId, mainPetGuidH, mainPetGuidL)
	if by_type_1 ~= define.PET_TYPE.PET_TYPE_BABY or data_id_1 % 10 ~= 9 then
		self:notify_tips(selfId, "Trân thú không phải bé con, chỉ trân thú bé con mới phối giống được")
		return
	end
	local by_type_2 = self:GetPetByType(selfId, assisPetGuidH, assisPetGuidL)
	local data_id_2 = self:GetPetDataID(selfId, assisPetGuidH, assisPetGuidL)
	if by_type_2 ~= define.PET_TYPE.PET_TYPE_BABY or data_id_2 % 10 ~= 9 then
		self:notify_tips(selfId, "Trân thú không phải bé con, chỉ trân thú bé con mới phối giống được")
		return
	end
	local pet_attr_table = configenginer:get_config("pet_attr_table")
	local pet_attr_1 = pet_attr_table[data_id_1]
	local pet_attr_2 = pet_attr_table[data_id_2]
	if not pet_attr_1 or not pet_attr_2 then
		self:notify_tips(selfId, "Cấu hình trân thú bất thường, không phối giống được")
		return
	end
	local similar_pet_type_1 = tonumber(pet_attr_1.similar_pet_type)
	local similar_pet_type_2 = tonumber(pet_attr_2.similar_pet_type)
	-- A few extended pets omit the reference column; their data IDs still use the standard group layout.
	if not similar_pet_type_1 or similar_pet_type_1 <= 0 then
		similar_pet_type_1 = data_id_1 - data_id_1 % 10
	end
	if not similar_pet_type_2 or similar_pet_type_2 <= 0 then
		similar_pet_type_2 = data_id_2 - data_id_2 % 10
	end
	if similar_pet_type_1 ~= similar_pet_type_2 then
		self:notify_tips(selfId, "Hai trân thú phối giống phải cùng loài")
		return
	end
	local sex_1 = self:GetPetSex(selfId, mainPetGuidH, mainPetGuidL)
	local sex_2 = self:GetPetSex(selfId, assisPetGuidH, assisPetGuidL)
	if sex_1 == sex_2 then
		self:notify_tips(selfId, "Hai Trân thú gây giống phải khác giới tính")
		return
	end
	if not self:LuaFnDelAvailableItem(selfId, PetLoveNestItemIndex, 1) then
		self:notify_tips(selfId, "Ngươi không có tổ ấm yêu thương" )
		return
	end
	local variances,data_index = self:GetPetVariances(selfId, mainPetGuidH, mainPetGuidL)
	if #variances == 0 or not data_index then
		self:notify_tips(selfId, "Trân thú này không phối giống được" )
		return
	end
	local growth_rate_1 = self:LuaFnGetPeGrowthRate(selfId, mainPetGuidH, mainPetGuidL)
	local growth_rate_2 = self:LuaFnGetPeGrowthRate(selfId, assisPetGuidH, assisPetGuidL)
	local average_growth_rate = (growth_rate_1 + growth_rate_2) / 2

	self:SetPetsSpouseGUID(selfId, mainPetGuidH, mainPetGuidL, assisPetGuidH, assisPetGuidL)
	self:SetPetNumOfReproductions(selfId, mainPetGuidH, mainPetGuidL, num_1 - 1)
	self:SetPetNumOfReproductions(selfId, assisPetGuidH, assisPetGuidL, num_2 -1)
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0 )
	self:notify_tips(selfId, "Phối giống trân thú thành công, xem ô trân thú")
	self:LuaFnCostMoneyWithPriority(selfId, 20000)
	local PlayerName = self:GetName(selfId)
	PlayerName = gbk.fromutf8(PlayerName)
	local num = #variances
	local rates = g_rate[num]
	local is_special = pet_special_procreate[data_index]
	if is_special then
		rates = is_special.rate
	end
	local is_max = false
	local petGUID_H, petGUID_L
	for i = 1, 2 do
		local rate = math.random(1000)
		for j = 1, num do
			if rate <= rates[j] then
				if j == #variances then
					is_max = true
				end
				if petGUID_L then
					_, petGUID_H, petGUID_L = self:LuaFnCreatePetToHuman(selfId, variances[j], true, average_growth_rate, petGUID_L + 1)
					
					-- 加权浮动资质覆写（对所有宠物生效）
					if petGUID_H and petGUID_L then
						local pet_attr = configenginer:get_config("pet_attr_table")
						local base = pet_attr[variances[j]]
						if base then
							self:LuaFnSetPetData(selfId, petGUID_H, petGUID_L, "str_perception", calc_float_perception(base.str_perception or 0))
							self:LuaFnSetPetData(selfId, petGUID_H, petGUID_L, "spr_perception", calc_float_perception(base.spr_perception or 0))
							self:LuaFnSetPetData(selfId, petGUID_H, petGUID_L, "con_perception", calc_float_perception(base.con_perception or 0))
							self:LuaFnSetPetData(selfId, petGUID_H, petGUID_L, "int_perception", calc_float_perception(base.int_perception or 0))
							self:LuaFnSetPetData(selfId, petGUID_H, petGUID_L, "dex_perception", calc_float_perception(base.dex_perception or 0))
						end
					end
					
					local transfer = self:GetPetTransString(selfId, petGUID_H, petGUID_L)
					local strMsg = string.format("#{PBB_2_A}#{_INFOUSR%s}#{PBB_2_B}#{_INFOMSG%s}#{PBB_2_C}", PlayerName, transfer)
					self:BroadMsgByChatPipe(selfId, strMsg, 4)
					break
				else
					_, petGUID_H, petGUID_L = self:LuaFnCreatePetToHuman(selfId, variances[j], true, average_growth_rate)
					
					-- 加权浮动资质覆写（对所有宠物生效）
					if petGUID_H and petGUID_L then
						local pet_attr = configenginer:get_config("pet_attr_table")
						local base = pet_attr[variances[j]]
						if base then
							self:LuaFnSetPetData(selfId, petGUID_H, petGUID_L, "str_perception", calc_float_perception(base.str_perception or 0))
							self:LuaFnSetPetData(selfId, petGUID_H, petGUID_L, "spr_perception", calc_float_perception(base.spr_perception or 0))
							self:LuaFnSetPetData(selfId, petGUID_H, petGUID_L, "con_perception", calc_float_perception(base.con_perception or 0))
							self:LuaFnSetPetData(selfId, petGUID_H, petGUID_L, "int_perception", calc_float_perception(base.int_perception or 0))
							self:LuaFnSetPetData(selfId, petGUID_H, petGUID_L, "dex_perception", calc_float_perception(base.dex_perception or 0))
						end
					end
					
					local transfer = self:GetPetTransString(selfId, petGUID_H, petGUID_L)
					local strMsg = string.format("#{PBB_2_A}#{_INFOUSR%s}#{PBB_2_B}#{_INFOMSG%s}#{PBB_2_C}", PlayerName, transfer)
					self:BroadMsgByChatPipe(selfId, strMsg, 4)
					break
				end
			end
		end
	end
end

return PetProcreateRegister
