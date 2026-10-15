local class = require "class"
local script_base = require "script_base"
local define = require "define"
local gbk = require "wire_charset"
local IA = define.ITEM_ATTRIBUTE

-- 经脉系统（新模型：class + script_base）
-- 任脉：四属性攻击单选修炼（冰/火/玄/毒）
-- 督脉：单入口修炼（统一增加人物HP上限）
-- 手少阳：伤害加成
-- 足太阴：伤害减免
local jingmai = class("jingmai", script_base)

jingmai.script_id = 900099
jingmai.MONTHLY_CARD_IMPACTS = { 9686, 9687, 9688 }
jingmai.MONTHLY_CARD_TIPS = "Bạn chưa kích hoạt thẻ tháng, chưa dùng được chức năng này!"

-- =======================================================
-- BUFF ID（范围：53000-55000）- 保留用于手少阳/足太阴
-- =======================================================
jingmai.SHAOYANG_BUFF_BASE_ID = 53201 -- 53201-53220（每10级1个buff）
jingmai.TAIYIN_BUFF_BASE_ID = 53221 -- 53221-53240（每10级1个buff）

-- =======================================================
-- 任务变量（MD）- 使用900-909范围，避免与FUBEN(960-971)冲突
-- =======================================================
-- 手少阳/足太阴
jingmai.MD_SHAOYANG_LEVEL = 900
jingmai.MD_TAIYIN_LEVEL = 901

-- 任脉四属性攻击（单选修炼）
jingmai.MD_REN_COLD = 902    -- 任脉冰攻等级
jingmai.MD_REN_FIRE = 903    -- 任脉火攻等级
jingmai.MD_REN_LIGHT = 904   -- 任脉玄攻等级
jingmai.MD_REN_POISON = 905  -- 任脉毒攻等级

-- 督脉等级（沿用历史字段，统一按总等级结算）
jingmai.MD_DU_COLD = 906
jingmai.MD_DU_FIRE = 907
jingmai.MD_DU_LIGHT = 908
jingmai.MD_DU_POISON = 909

-- =======================================================
-- 配置（后期可调整）
-- =======================================================
jingmai.MAX_LEVEL = 100           -- 任脉/督脉单属性上限
jingmai.SHAOYANG_MAX_LEVEL = 100  -- 手少阳上限
jingmai.TAIYIN_MAX_LEVEL = 100    -- 足太阴上限
jingmai.EXCHANGE_EXP_COST = 200000000  -- 每档消耗经验（2亿）
jingmai.ATTR_PER_LEVEL = 20       -- 每级属性加成（任脉攻击）
jingmai.DU_HP_PER_LEVEL = 3000    -- 每级属性加成（督脉血上限）

-- 属性映射（IA -> key）
local IA_TO_KEY = {
	[IA.IATTRIBUTE_COLD_ATTACK] = "att_cold",
	[IA.IATTRIBUTE_FIRE_ATTACK] = "att_fire",
	[IA.IATTRIBUTE_LIGHT_ATTACK] = "att_light",
	[IA.IATTRIBUTE_POISON_ATTACK] = "att_poison",
	[IA.IATTRIBUTE_POINT_MAXHP] = "hp_max",
}

-- 任脉属性映射（attr_type -> IA）
local REN_IA = {
	cold = IA.IATTRIBUTE_COLD_ATTACK,
	fire = IA.IATTRIBUTE_FIRE_ATTACK,
	light = IA.IATTRIBUTE_LIGHT_ATTACK,
	poison = IA.IATTRIBUTE_POISON_ATTACK,
}

-- 督脉属性映射（attr_type -> IA，统一转血上限）
local DU_IA = {
	cold = IA.IATTRIBUTE_POINT_MAXHP,
	fire = IA.IATTRIBUTE_POINT_MAXHP,
	light = IA.IATTRIBUTE_POINT_MAXHP,
	poison = IA.IATTRIBUTE_POINT_MAXHP,
}

-- =======================================================
-- 内部工具
-- =======================================================
function jingmai:GetMaiLevel(selfId, md)
	local lv = self:GetMissionData(selfId, md)
	if not lv or lv < 0 then
		return 0
	end
	return lv
end

-- 获取任脉总等级（四属性之和）
function jingmai:GetRenTotalLevel(selfId)
	return self:GetMaiLevel(selfId, self.MD_REN_COLD)
		+ self:GetMaiLevel(selfId, self.MD_REN_FIRE)
		+ self:GetMaiLevel(selfId, self.MD_REN_LIGHT)
		+ self:GetMaiLevel(selfId, self.MD_REN_POISON)
end

-- 获取督脉总等级（四属性之和）
function jingmai:GetDuTotalLevel(selfId)
	return self:GetMaiLevel(selfId, self.MD_DU_COLD)
		+ self:GetMaiLevel(selfId, self.MD_DU_FIRE)
		+ self:GetMaiLevel(selfId, self.MD_DU_LIGHT)
		+ self:GetMaiLevel(selfId, self.MD_DU_POISON)
end

function jingmai:BuildJingMaiBonus(selfId)
	local bonus = {}
	bonus[IA.IATTRIBUTE_COLD_ATTACK] = self:GetMaiLevel(selfId, self.MD_REN_COLD) * self.ATTR_PER_LEVEL
	bonus[IA.IATTRIBUTE_FIRE_ATTACK] = self:GetMaiLevel(selfId, self.MD_REN_FIRE) * self.ATTR_PER_LEVEL
	bonus[IA.IATTRIBUTE_LIGHT_ATTACK] = self:GetMaiLevel(selfId, self.MD_REN_LIGHT) * self.ATTR_PER_LEVEL
	bonus[IA.IATTRIBUTE_POISON_ATTACK] = self:GetMaiLevel(selfId, self.MD_REN_POISON) * self.ATTR_PER_LEVEL
	bonus[IA.IATTRIBUTE_POINT_MAXHP] = self:GetDuTotalLevel(selfId) * self.DU_HP_PER_LEVEL

	-- 手少阳：每10级1%伤害加成（物理+法术通用）
	local shaoyang_level = self:GetMaiLevel(selfId, self.MD_SHAOYANG_LEVEL)
	if shaoyang_level > 0 then
		local shaoyang_bonus = math.floor(shaoyang_level / 10) * 100  -- 每10级+1%（转换为百分比*100）
		if shaoyang_bonus > 0 then
			bonus[IA.IATTRIBUTE_POINT_ADD_ATTACK_PHYSIC_DAMAGE_RATE] = shaoyang_bonus  -- 物理攻击伤害加成(80)
			bonus[IA.IATTRIBUTE_POINT_ADD_ATTACK_MAGIC_DAMAGE_RATE] = shaoyang_bonus   -- 法术攻击伤害加成(79)
		end
	end

	-- 足太阴：每10级1%伤害减免（物理+法术通用）
	local taiyin_level = self:GetMaiLevel(selfId, self.MD_TAIYIN_LEVEL)
	if taiyin_level > 0 then
		local taiyin_bonus = math.floor(taiyin_level / 10) * 100  -- 每10级+1%（转换为百分比*100）
		if taiyin_bonus > 0 then
			bonus[IA.IATTRIBUTE_POINT_ADD_PHYSIC_DEFENCE_RATE] = taiyin_bonus  -- 物理防御率(86)
			bonus[IA.IATTRIBUTE_POINT_ADD_MAGIC_DEFENCE_RATE] = taiyin_bonus   -- 法术防御率(85)
		end
	end

	return bonus
end

-- 刷新经脉属性（强制重新计算并保存，用于修复旧数据）
function jingmai:RefreshJingMaiAttrib(selfId, targetId)
	local scene = self:get_scene()
	if not scene then
		return
	end
	local human = scene:get_obj_by_id(selfId)
	if not human or not human.db then
		return
	end

	-- 强制重新计算所有经脉属性
	self:MarkJingMaiAttribDirty(selfId)

	-- 显示成功消息
	self:BeginEvent(self.script_id)
	self:AddText("#G Làm mới thuộc tính kinh mạch thành công!#W")
	self:AddText("#YĐã tính lại mọi cộng kinh mạch và lưu.#W")
	self:AddText("#HXin mặc lại trang bị để hiệu lực ngay.#W")
	self:AddText(" ")
	self:AddNumText("Về menu chính", 6, 9999)
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end

function jingmai:MarkJingMaiAttribDirty(selfId)
	local scene = self:get_scene()
	if not scene then
		return
	end
	local human = scene:get_obj_by_id(selfId)
	if not human or not human.db then
		return
	end
	local db = human.db
	if type(db.get_attrib) ~= "function" or type(db.cal_item_effect) ~= "function" then
		if human.send_refresh_attrib then
			human:send_refresh_attrib()
		end
		return
	end

	local old_bonus = db:get_attrib("jingmai_attr_bonus")
	if type(old_bonus) ~= "table" then
		old_bonus = {}
	end
	local new_bonus = self:BuildJingMaiBonus(selfId)
	local save_bonus = {}
	local touched = {}

	for ia, value in pairs(new_bonus) do
		local key = tostring(ia)
		local new_val = tonumber(value) or 0
		save_bonus[key] = new_val
		local old_val = tonumber(old_bonus[key]) or tonumber(old_bonus[ia]) or 0
		local delta = new_val - old_val
		if delta ~= 0 then
			pcall(db.cal_item_effect, db, ia, delta)
		end
		touched[key] = true
		local attr_key = IA_TO_KEY[ia]
		if attr_key and type(db.mark_attrib_dirty) == "function" then
			db:mark_attrib_dirty(attr_key)
		end
	end

	for k, v in pairs(old_bonus) do
		local key = tostring(k)
		if not touched[key] then
			local ia = tonumber(k)
			local old_val = tonumber(v) or 0
			if ia and old_val ~= 0 then
				pcall(db.cal_item_effect, db, ia, -old_val)
				local attr_key = IA_TO_KEY[ia]
				if attr_key and type(db.mark_attrib_dirty) == "function" then
					db:mark_attrib_dirty(attr_key)
				end
			end
		end
	end

	if type(db.set_db_attrib) == "function" then
		db:set_db_attrib({ jingmai_attr_bonus = save_bonus })
	end
	if type(db.mark_attrib_dirty) == "function" then
		db:mark_attrib_dirty("jingmai_attr_bonus")
	end
	if human.send_refresh_attrib then
		human:send_refresh_attrib()
	end
end

function jingmai:NotifyFailTips(selfId, Tip)
	self:BeginEvent(self.script_id)
	self:AddText(Tip)
	self:EndEvent()
	self:DispatchMissionTips(selfId)
end

function jingmai:HasMonthlyCardImpact(selfId)
	for _, impactId in ipairs(self.MONTHLY_CARD_IMPACTS) do
		if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, impactId) then
			return true
		end
	end
	return false
end

function jingmai:IsUpgradeIndex(index)
	index = tonumber(index) or -1
	if index == 103 or index == 104 then
		return true
	end
	if index >= 201 and index <= 204 then
		return true
	end
	if index >= 301 and index <= 304 then
		return true
	end
	return false
end

-- =======================================================
-- 主入口
-- =======================================================
function jingmai:OnDefaultEvent(selfId, targetId)
	if self:GetLevel(selfId) < 90 then
		self:NotifyFailTips(selfId, "#RHệ thống kinh mạch cần trên cấp 90 mới tu luyện được.")
		return
	end
	local ren_total = self:GetRenTotalLevel(selfId)
	local du_total = self:GetDuTotalLevel(selfId)
	local shaoyang_level = self:GetMaiLevel(selfId, self.MD_SHAOYANG_LEVEL)
	local taiyin_level = self:GetMaiLevel(selfId, self.MD_TAIYIN_LEVEL)

	self:BeginEvent(self.script_id)
	self:AddText("#WChào mừng tới hệ thống kinh mạch.#W")
	self:AddText(string.format("#WCấp Nhâm mạch hiện tại: #G%d#W | Cấp Đốc mạch: #G%d#W", ren_total, du_total))
	self:AddText(string.format("#WThủ Thiếu Dương hiện: #G%d#Wcấp | Túc Thái Âm: #G%d#Wcấp", shaoyang_level, taiyin_level))
	self:AddText(string.format("#WTăng kinh mạch tốn đồng nhất: #G%d#W kinh nghiệm/cấp (không tốn vật phẩm)#r#HMặc lại trang bị hiệu lực ngay.#W", self.EXCHANGE_EXP_COST))

	--self:AddText(" ")
	self:AddNumText("#GXem cộng thuộc tính", 6, 1)
	self:AddNumText("#YTăng Nhâm mạch (công 4 thuộc tính)", 6, 2)
	self:AddNumText("#YTăng Đốc mạch (tăng HP đồng loạt)", 6, 3)
	self:AddNumText("#YTăng Thủ Thiếu Dương", 6, 5)
	self:AddNumText("#YTăng Túc Thái Âm", 6, 6)
	self:AddNumText("Làm mới thuộc tính kinh mạch (sửa dữ liệu cũ)", 6, 888)  -- 新增：刷新按钮
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end

function jingmai:OnEventRequest(selfId, targetId, arg, index)
	-- if self:IsUpgradeIndex(index) and not self:HasMonthlyCardImpact(selfId) then
		-- self:NotifyFailTips(selfId, self.MONTHLY_CARD_TIPS)
		-- return
	-- end

	if index == 1 then
		return self:ShowAttributes(selfId, targetId)
	elseif index == 2 then
		return self:ShowRenMaiMenu(selfId, targetId)
	elseif index == 3 then
		return self:ShowDuMaiMenu(selfId, targetId)
	elseif index == 5 then
		return self:ShowShaoYangMenu(selfId, targetId)
	elseif index == 6 then
		return self:ShowTaiYinMenu(selfId, targetId)
	elseif index == 888 then
		return self:RefreshJingMaiAttrib(selfId, targetId)  -- 刷新经脉属性
	elseif index == 9999 then
		return self:OnDefaultEvent(selfId, targetId)
	-- 任脉四属性升级（201-204）
	elseif index == 201 then
		local cur = self:GetMaiLevel(selfId, self.MD_REN_COLD)
		local cur_exp = self:GetExp(selfId)
		local ren_cold = cur
		local ren_fire = self:GetMaiLevel(selfId, self.MD_REN_FIRE)
		local ren_light = self:GetMaiLevel(selfId, self.MD_REN_LIGHT)
		local ren_poison = self:GetMaiLevel(selfId, self.MD_REN_POISON)
		
		self:BeginEvent(self.script_id)
		if cur_exp >= self.EXCHANGE_EXP_COST and cur < self.MAX_LEVEL then
			ren_cold = cur + 1
			self:AddText(string.format("#GTăng băng công thành công! Cấp: %d", ren_cold))
			self:AddText("#HMặc lại trang bị là có hiệu lực ngay.#W")
		elseif cur_exp < self.EXCHANGE_EXP_COST then
			self:AddText("#RKhông đủ kinh nghiệm")
		else
			self:AddText("#RĐã tới tầng cao nhất")
		end
		self:AddText(" ")
		self:AddText(string.format("#BBăng công: #G%d#Wcấp | #RHỏa công: #G%d#Wcấp", ren_cold, ren_fire))
		self:AddText(string.format("#PHuyền công: #G%d#Wcấp | #GĐộc công: #G%d#Wcấp", ren_light, ren_poison))
		self:AddText(" ")
		if ren_cold < self.MAX_LEVEL then
			self:AddNumText("#BTăng băng công", 6, 201)
		end
		if ren_fire < self.MAX_LEVEL then
			self:AddNumText("#RTăng hỏa công", 6, 202)
		end
		if ren_light < self.MAX_LEVEL then
			self:AddNumText("#YTăng huyền công", 6, 203)
		end
		if ren_poison < self.MAX_LEVEL then
			self:AddNumText("#GTăng độc công", 6, 204)
		end
		self:AddNumText("Về menu chính", 6, 9999)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
		
		if cur_exp >= self.EXCHANGE_EXP_COST and cur < self.MAX_LEVEL then
			self:LuaFnCostExp(selfId, self.EXCHANGE_EXP_COST)
			self:SetMissionData(selfId, self.MD_REN_COLD, cur + 1)
			self:MarkJingMaiAttribDirty(selfId)
		end
	elseif index == 202 then
		local cur = self:GetMaiLevel(selfId, self.MD_REN_FIRE)
		local cur_exp = self:GetExp(selfId)
		local ren_cold = self:GetMaiLevel(selfId, self.MD_REN_COLD)
		local ren_fire = cur
		local ren_light = self:GetMaiLevel(selfId, self.MD_REN_LIGHT)
		local ren_poison = self:GetMaiLevel(selfId, self.MD_REN_POISON)
		
		self:BeginEvent(self.script_id)
		if cur_exp >= self.EXCHANGE_EXP_COST and cur < self.MAX_LEVEL then
			ren_fire = cur + 1
			self:AddText(string.format("#GTăng hỏa công thành công! Cấp: %d", ren_fire))
			self:AddText("#HMặc lại trang bị là có hiệu lực ngay.#W")
		elseif cur_exp < self.EXCHANGE_EXP_COST then
			self:AddText("#RKhông đủ kinh nghiệm")
		else
			self:AddText("#RĐã tới tầng cao nhất")
		end
		self:AddText(" ")
		self:AddText(string.format("#BBăng công: #G%d#Wcấp | #RHỏa công: #G%d#Wcấp", ren_cold, ren_fire))
		self:AddText(string.format("#PHuyền công: #G%d#Wcấp | #GĐộc công: #G%d#Wcấp", ren_light, ren_poison))
		self:AddText(" ")
		if ren_cold < self.MAX_LEVEL then
			self:AddNumText("#BTăng băng công", 6, 201)
		end
		if ren_fire < self.MAX_LEVEL then
			self:AddNumText("#RTăng hỏa công", 6, 202)
		end
		if ren_light < self.MAX_LEVEL then
			self:AddNumText("#YTăng huyền công", 6, 203)
		end
		if ren_poison < self.MAX_LEVEL then
			self:AddNumText("#GTăng độc công", 6, 204)
		end
		self:AddNumText("Về menu chính", 6, 9999)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
		
		if cur_exp >= self.EXCHANGE_EXP_COST and cur < self.MAX_LEVEL then
			self:LuaFnCostExp(selfId, self.EXCHANGE_EXP_COST)
			self:SetMissionData(selfId, self.MD_REN_FIRE, cur + 1)
			self:MarkJingMaiAttribDirty(selfId)
		end
	elseif index == 203 then
		local cur = self:GetMaiLevel(selfId, self.MD_REN_LIGHT)
		local cur_exp = self:GetExp(selfId)
		local ren_cold = self:GetMaiLevel(selfId, self.MD_REN_COLD)
		local ren_fire = self:GetMaiLevel(selfId, self.MD_REN_FIRE)
		local ren_light = cur
		local ren_poison = self:GetMaiLevel(selfId, self.MD_REN_POISON)
		
		self:BeginEvent(self.script_id)
		if cur_exp >= self.EXCHANGE_EXP_COST and cur < self.MAX_LEVEL then
			ren_light = cur + 1
			self:AddText(string.format("#GTăng huyền công thành công! Cấp: %d", ren_light))
			self:AddText("#HMặc lại trang bị là có hiệu lực ngay.#W")
		elseif cur_exp < self.EXCHANGE_EXP_COST then
			self:AddText("#RKhông đủ kinh nghiệm")
		else
			self:AddText("#RĐã tới tầng cao nhất")
		end
		self:AddText(" ")
		self:AddText(string.format("#BBăng công: #G%d#Wcấp | #RHỏa công: #G%d#Wcấp", ren_cold, ren_fire))
		self:AddText(string.format("#PHuyền công: #G%d#Wcấp | #GĐộc công: #G%d#Wcấp", ren_light, ren_poison))
		self:AddText(" ")
		if ren_cold < self.MAX_LEVEL then
			self:AddNumText("#BTăng băng công", 6, 201)
		end
		if ren_fire < self.MAX_LEVEL then
			self:AddNumText("#RTăng hỏa công", 6, 202)
		end
		if ren_light < self.MAX_LEVEL then
			self:AddNumText("#YTăng huyền công", 6, 203)
		end
		if ren_poison < self.MAX_LEVEL then
			self:AddNumText("#GTăng độc công", 6, 204)
		end
		self:AddNumText("Về menu chính", 6, 9999)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
		
		if cur_exp >= self.EXCHANGE_EXP_COST and cur < self.MAX_LEVEL then
			self:LuaFnCostExp(selfId, self.EXCHANGE_EXP_COST)
			self:SetMissionData(selfId, self.MD_REN_LIGHT, cur + 1)
			self:MarkJingMaiAttribDirty(selfId)
		end
	elseif index == 204 then
		local cur = self:GetMaiLevel(selfId, self.MD_REN_POISON)
		local cur_exp = self:GetExp(selfId)
		local ren_cold = self:GetMaiLevel(selfId, self.MD_REN_COLD)
		local ren_fire = self:GetMaiLevel(selfId, self.MD_REN_FIRE)
		local ren_light = self:GetMaiLevel(selfId, self.MD_REN_LIGHT)
		local ren_poison = cur
		
		self:BeginEvent(self.script_id)
		if cur_exp >= self.EXCHANGE_EXP_COST and cur < self.MAX_LEVEL then
			ren_poison = cur + 1
			self:AddText(string.format("#GTăng độc công thành công! Cấp: %d", ren_poison))
			self:AddText("#HMặc lại trang bị là có hiệu lực ngay.#W")
		elseif cur_exp < self.EXCHANGE_EXP_COST then
			self:AddText("#RKhông đủ kinh nghiệm")
		else
			self:AddText("#RĐã tới tầng cao nhất")
		end
		self:AddText(" ")
		self:AddText(string.format("#BBăng công: #G%d#Wcấp | #RHỏa công: #G%d#Wcấp", ren_cold, ren_fire))
		self:AddText(string.format("#PHuyền công: #G%d#Wcấp | #GĐộc công: #G%d#Wcấp", ren_light, ren_poison))
		self:AddText(" ")
		if ren_cold < self.MAX_LEVEL then
			self:AddNumText("#BTăng băng công", 6, 201)
		end
		if ren_fire < self.MAX_LEVEL then
			self:AddNumText("#RTăng hỏa công", 6, 202)
		end
		if ren_light < self.MAX_LEVEL then
			self:AddNumText("#YTăng huyền công", 6, 203)
		end
		if ren_poison < self.MAX_LEVEL then
			self:AddNumText("#GTăng độc công", 6, 204)
		end
		self:AddNumText("Về menu chính", 6, 9999)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
		
		if cur_exp >= self.EXCHANGE_EXP_COST and cur < self.MAX_LEVEL then
			self:LuaFnCostExp(selfId, self.EXCHANGE_EXP_COST)
			self:SetMissionData(selfId, self.MD_REN_POISON, cur + 1)
			self:MarkJingMaiAttribDirty(selfId)
		end
	-- 督脉单入口升级（301-304统一处理，兼容旧按钮索引）
	elseif index == 301 or index == 302 or index == 303 or index == 304 then
		local cur_exp = self:GetExp(selfId)
		local du_total = self:GetDuTotalLevel(selfId)
		local next_level = du_total

		self:BeginEvent(self.script_id)
		if cur_exp >= self.EXCHANGE_EXP_COST and du_total < self.MAX_LEVEL then
			next_level = du_total + 1
			self:AddText(string.format("#GTăng Đốc mạch thành công! Cấp: %d", next_level))
			self:AddText("#HMặc lại trang bị là có hiệu lực ngay.#W")
		elseif cur_exp < self.EXCHANGE_EXP_COST then
			self:AddText("#RKhông đủ kinh nghiệm")
		else
			self:AddText("#RĐã tới tầng cao nhất")
		end
		self:AddText(" ")
		self:AddText(string.format("#WMỗi cấp tăng #G%d#W điểm giới hạn HP", self.DU_HP_PER_LEVEL))
		self:AddText(string.format("#YCấp hiện tại: #G%d#W / %d", next_level, self.MAX_LEVEL))
		self:AddText(string.format("#YTổng cộng giới hạn HP nhân vật: #G+%d#W", next_level * self.DU_HP_PER_LEVEL))
		self:AddText(" ")
		if next_level < self.MAX_LEVEL then
			self:AddNumText("#GTăng cấp Đốc mạch", 6, 301)
		end
		self:AddNumText("Về menu chính", 6, 9999)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)

		if cur_exp >= self.EXCHANGE_EXP_COST and du_total < self.MAX_LEVEL then
			self:LuaFnCostExp(selfId, self.EXCHANGE_EXP_COST)
			self:SetMissionData(selfId, self.MD_DU_COLD, self:GetMaiLevel(selfId, self.MD_DU_COLD) + 1)
			self:MarkJingMaiAttribDirty(selfId)
		end
	-- 手少阳/足太阴升级
	elseif index == 103 then
		local cur = self:GetMaiLevel(selfId, self.MD_SHAOYANG_LEVEL)
		local cur_exp = self:GetExp(selfId)
		local level = cur
		
		self:BeginEvent(self.script_id)
		if cur_exp >= self.EXCHANGE_EXP_COST and cur < self.SHAOYANG_MAX_LEVEL then
			level = cur + 1
			self:AddText(string.format("#GTăng Thủ Thiếu Dương thành công! Cấp: %d", level))
			self:AddText("#HMặc lại trang bị là có hiệu lực ngay.#W")
		elseif cur_exp < self.EXCHANGE_EXP_COST then
			self:AddText("#RKhông đủ kinh nghiệm")
		else
			self:AddText("#RĐã tới tầng cao nhất")
		end
		self:AddText(" ")
		self:AddText("#WThủ Thiếu Dương mỗi 10 cấp tăng 1% sát thương (hiệu lực ngay, vĩnh viễn)#W")
		self:AddText(string.format("#YCấp hiện tại: #G%d#W / %d", level, self.SHAOYANG_MAX_LEVEL))
		self:AddText(" ")
		if level < self.SHAOYANG_MAX_LEVEL then
			self:AddNumText("#GTăng cấp Thủ Thiếu Dương", 6, 103)
		end
		self:AddNumText("Về menu chính", 6, 9999)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
		
		if cur_exp >= self.EXCHANGE_EXP_COST and cur < self.SHAOYANG_MAX_LEVEL then
			self:LuaFnCostExp(selfId, self.EXCHANGE_EXP_COST)
			self:SetMissionData(selfId, self.MD_SHAOYANG_LEVEL, level)
			self:MarkJingMaiAttribDirty(selfId)
			-- 属性已直接加成到jingmai_attr_bonus，无需额外BUFF
			-- if level % 10 == 0 then
			-- 	local buff_id = self.SHAOYANG_BUFF_BASE_ID + (level / 10) - 1
			-- 	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, buff_id, 0)
			-- end
		end
	elseif index == 104 then
		local cur = self:GetMaiLevel(selfId, self.MD_TAIYIN_LEVEL)
		local cur_exp = self:GetExp(selfId)
		local level = cur
		
		self:BeginEvent(self.script_id)
		if cur_exp >= self.EXCHANGE_EXP_COST and cur < self.TAIYIN_MAX_LEVEL then
			level = cur + 1
			self:AddText(string.format("#GTăng Túc Thái Âm thành công! Cấp: %d", level))
			self:AddText("#HMặc lại trang bị là có hiệu lực ngay.#W")
		elseif cur_exp < self.EXCHANGE_EXP_COST then
			self:AddText("#RKhông đủ kinh nghiệm")
		else
			self:AddText("#RĐã tới tầng cao nhất")
		end
		self:AddText(" ")
		self:AddText("#WTúc Thái Âm mỗi 10 cấp giảm 1% sát thương nhận (hiệu lực ngay, vĩnh viễn)#W")
		self:AddText(string.format("#YCấp hiện tại: #G%d#W / %d", level, self.TAIYIN_MAX_LEVEL))
		self:AddText(" ")
		if level < self.TAIYIN_MAX_LEVEL then
			self:AddNumText("#GTăng cấp Túc Thái Âm", 6, 104)
		end
		self:AddNumText("Về menu chính", 6, 9999)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
		
		if cur_exp >= self.EXCHANGE_EXP_COST and cur < self.TAIYIN_MAX_LEVEL then
			self:LuaFnCostExp(selfId, self.EXCHANGE_EXP_COST)
			self:SetMissionData(selfId, self.MD_TAIYIN_LEVEL, level)
			self:MarkJingMaiAttribDirty(selfId)
			-- 属性已直接加成到jingmai_attr_bonus，无需额外BUFF
			-- if level % 10 == 0 then
			-- 	local buff_id = self.TAIYIN_BUFF_BASE_ID + (level / 10) - 1
			-- 	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, buff_id, 0)
			-- end
		end
	end
end

-- =======================================================
-- 菜单页
-- =======================================================
function jingmai:ShowAttributes(selfId, targetId)
	local ren_cold = self:GetMaiLevel(selfId, self.MD_REN_COLD)
	local ren_fire = self:GetMaiLevel(selfId, self.MD_REN_FIRE)
	local ren_light = self:GetMaiLevel(selfId, self.MD_REN_LIGHT)
	local ren_poison = self:GetMaiLevel(selfId, self.MD_REN_POISON)

	local du_cold = self:GetMaiLevel(selfId, self.MD_DU_COLD)
	local du_fire = self:GetMaiLevel(selfId, self.MD_DU_FIRE)
	local du_light = self:GetMaiLevel(selfId, self.MD_DU_LIGHT)
	local du_poison = self:GetMaiLevel(selfId, self.MD_DU_POISON)
	local du_total_bonus = (du_cold + du_fire + du_light + du_poison) * self.DU_HP_PER_LEVEL

	local shou_level = self:GetMaiLevel(selfId, self.MD_SHAOYANG_LEVEL)
	local zu_level = self:GetMaiLevel(selfId, self.MD_TAIYIN_LEVEL)

	local shou_bonus = math.floor(shou_level / 10)
	local zu_bonus = math.floor(zu_level / 10)

	self:BeginEvent(self.script_id)
	self:AddText("#W====== Thuộc tính Nhâm mạch (công 4 thuộc tính) ======#W")
	self:AddText(string.format("     #BBăng công: #G+%d#W | #RHỏa công: #G+%d", ren_cold * self.ATTR_PER_LEVEL, ren_fire * self.ATTR_PER_LEVEL))
	self:AddText(string.format("     #PHuyền công: #G+%d#W | #GĐộc công: #G+%d", ren_light * self.ATTR_PER_LEVEL, ren_poison * self.ATTR_PER_LEVEL))
	self:AddText(" ")
	self:AddText("#W====== Thuộc tính Đốc mạch (HP nhân vật) ======#W")
	self:AddText(string.format("     #YCấp Đốc mạch: #G%d#W / %d", self:GetDuTotalLevel(selfId), self.MAX_LEVEL))
	self:AddText(string.format("     #YTổng cộng giới hạn HP nhân vật: #G+%d", du_total_bonus))
	self:AddText(" ")
	self:AddText("#W========== Thủ Thiếu Dương/Túc Thái Âm ==========#W")
	self:AddText(string.format("    #YCấp Thủ Thiếu Dương: #G%d#W (cộng sát thương #G+%d%%#W)", shou_level, shou_bonus))
	self:AddText(string.format("    #YCấp Túc Thái Âm: #G%d#W (giảm sát thương #G+%d%%#W)", zu_level, zu_bonus))
	self:AddText(" ")
	self:AddNumText("Về menu chính", 6, 9999)
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end

-- 任脉子菜单（四属性攻击选择）
function jingmai:ShowRenMaiMenu(selfId, targetId, msg)
	local ren_cold = self:GetMaiLevel(selfId, self.MD_REN_COLD)
	local ren_fire = self:GetMaiLevel(selfId, self.MD_REN_FIRE)
	local ren_light = self:GetMaiLevel(selfId, self.MD_REN_LIGHT)
	local ren_poison = self:GetMaiLevel(selfId, self.MD_REN_POISON)

	self:BeginEvent(self.script_id)
	if msg then
		self:AddText(msg)
		self:AddText(" ")
	end
	self:AddText("#WTu Nhâm mạch - chọn công thuộc tính muốn tăng#W")
	self:AddText(string.format("#WMỗi cấp tăng #G%d#W điểm công thuộc tính", self.ATTR_PER_LEVEL))
	self:AddText(string.format("#WTốn: #G%d#W kinh nghiệm/cấp", self.EXCHANGE_EXP_COST))
	self:AddText(" ")
	self:AddText("#WCấp hiện tại:")
	self:AddText(string.format("#BBăng công: #G%d#Wcấp | #RHỏa công: #G%d#Wcấp", ren_cold, ren_fire))
	self:AddText(string.format("#PHuyền công: #G%d#Wcấp | #GĐộc công: #G%d#Wcấp", ren_light, ren_poison))
	self:AddText(" ")
	self:AddNumText("#BTăng băng công", 6, 201)
	self:AddNumText("#RTăng hỏa công", 6, 202)
	self:AddNumText("#PTăng huyền công", 6, 203)
	self:AddNumText("#GTăng độc công", 6, 204)
	self:AddText(" ")
	self:AddNumText("Về menu chính", 6, 9999)
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end

-- 督脉子菜单（单入口修炼，统一增加HP）
function jingmai:ShowDuMaiMenu(selfId, targetId, msg)
	local level = self:GetDuTotalLevel(selfId)
	local du_total_bonus = level * self.DU_HP_PER_LEVEL

	self:BeginEvent(self.script_id)
	if msg then
		self:AddText(msg)
		self:AddText(" ")
	end
	self:AddText("#WTăng Đốc mạch#W")
	self:AddText(string.format("#WMỗi cấp tăng #G%d#W điểm giới hạn máu", self.DU_HP_PER_LEVEL))
	self:AddText("#WChỉ tăng giới hạn HP, không phân nhánh thuộc tính.#W")
	self:AddText(string.format("#WTốn: #G%d#W kinh nghiệm/cấp", self.EXCHANGE_EXP_COST))
	self:AddText(" ")
	self:AddText(string.format("#YCấp hiện tại: #G%d#W / %d", level, self.MAX_LEVEL))
	self:AddText(string.format("#YTổng cộng giới hạn HP nhân vật: #G+%d#W", du_total_bonus))
	self:AddText(" ")
	if level < self.MAX_LEVEL then
		self:AddNumText("#GTăng cấp Đốc mạch", 6, 301)
	else
		self:AddText("#RĐốc mạch đã tầng cao nhất.")
	end
	self:AddNumText("Về menu chính", 6, 9999)
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end

function jingmai:ShowShaoYangMenu(selfId, targetId, msg)
	local level = self:GetMaiLevel(selfId, self.MD_SHAOYANG_LEVEL)

	self:BeginEvent(self.script_id)
	if msg then
		self:AddText(msg)
		self:AddText(" ")
	end
	self:AddText("#WTăng Thủ Thiếu Dương#W")
	self:AddText("#WThủ Thiếu Dương mỗi 10 cấp tăng 1% sát thương, hiệu lực ngay và lưu vĩnh viễn.#W")
	self:AddText(string.format("#YCấp hiện tại: #G%d#W / %d", level, self.SHAOYANG_MAX_LEVEL))
	self:AddText(string.format("#WTăng cần tốn: #G%d#W kinh nghiệm", self.EXCHANGE_EXP_COST))
	self:AddText(" ")
	if level < self.SHAOYANG_MAX_LEVEL then
		self:AddNumText("#GTăng cấp Thủ Thiếu Dương", 6, 103)
	else
		self:AddText("#RThủ Thiếu Dương đã tầng cao nhất.")
	end
	self:AddNumText("Về menu chính", 6, 9999)
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end

function jingmai:ShowTaiYinMenu(selfId, targetId, msg)
	local level = self:GetMaiLevel(selfId, self.MD_TAIYIN_LEVEL)

	self:BeginEvent(self.script_id)
	if msg then
		self:AddText(msg)
		self:AddText(" ")
	end
	self:AddText("#WTăng Túc Thái Âm#W")
	self:AddText("#WTúc Thái Âm mỗi 10 cấp giảm 1% sát thương nhận, hiệu lực ngay và lưu vĩnh viễn.#W")
	self:AddText(string.format("#YCấp hiện tại: #G%d#W / %d", level, self.TAIYIN_MAX_LEVEL))
	self:AddText(string.format("#WTăng cần tốn: #G%d#W kinh nghiệm", self.EXCHANGE_EXP_COST))
	self:AddText(" ")
	if level < self.TAIYIN_MAX_LEVEL then
		self:AddNumText("#GTăng cấp Túc Thái Âm", 6, 104)
	else
		self:AddText("#RTúc Thái Âm đã tầng cao nhất.")
	end
	self:AddNumText("Về menu chính", 6, 9999)
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end

-- =======================================================
-- 核心逻辑
-- =======================================================
-- 任脉升级（四属性攻击单选）
function jingmai:UpgradeRenMai(selfId, targetId, attr_type)
	local md, name
	if attr_type == "cold" then
		md = self.MD_REN_COLD
		name = "Nhâm mạch băng công"
	elseif attr_type == "fire" then
		md = self.MD_REN_FIRE
		name = "Nhâm mạch hỏa công"
	elseif attr_type == "light" then
		md = self.MD_REN_LIGHT
		name = "Nhâm mạch huyền công"
	elseif attr_type == "poison" then
		md = self.MD_REN_POISON
		name = "Nhâm mạch độc công"
	end

	local cur = self:GetMaiLevel(selfId, md)
	local cur_exp = self:GetExp(selfId)
	
	if cur >= self.MAX_LEVEL then
		return "Đã tới tầng cao nhất"
	end

	if cur_exp < self.EXCHANGE_EXP_COST then
		return "Không đủ kinh nghiệm"
	end

	local new_level = cur + 1
	
	self:LuaFnCostExp(selfId, self.EXCHANGE_EXP_COST)
	self:SetMissionData(selfId, md, new_level)
	self:MarkJingMaiAttribDirty(selfId)
	
	return string.format("#GTăng %s thành công! Cấp hiện tại: %d", name, new_level)
end

-- 督脉升级（单入口，统一增加HP）
function jingmai:UpgradeDuMai(selfId, targetId, attr_type)
	local cur_exp = self:GetExp(selfId)
	local du_total = self:GetDuTotalLevel(selfId)

	if du_total >= self.MAX_LEVEL then
		self:notify_tips(selfId, "Đốc mạch đã tới tầng cao nhất.")
		return
	end

	if cur_exp < self.EXCHANGE_EXP_COST then
		self:notify_tips(selfId, "Kinh nghiệm không đủ 200 triệu, không tăng Đốc mạch được.")
		return
	end

	local new_level = du_total + 1

	self:LuaFnCostExp(selfId, self.EXCHANGE_EXP_COST)
	self:SetMissionData(selfId, self.MD_DU_COLD, self:GetMaiLevel(selfId, self.MD_DU_COLD) + 1)
	self:MarkJingMaiAttribDirty(selfId)

	local player_name = self:GetName(selfId)
	local broadcast_msg = string.format("#W#{_INFOUSR%s}#Wtu luyện kinh mạch, Đốc mạch lên tầng %d!", player_name, new_level)
	broadcast_msg = gbk.fromutf8(broadcast_msg)
	self:BroadMsgByChatPipe(selfId, broadcast_msg, 4)

	self:BeginEvent(self.script_id)
	self:AddText(string.format("#GTăng Đốc mạch thành công! Cấp hiện tại: %d", new_level))
	self:AddText(" ")
	self:AddText("#WTăng Đốc mạch#W")
	self:AddText(string.format("#WMỗi cấp tăng #G%d#W điểm giới hạn máu", self.DU_HP_PER_LEVEL))
	self:AddText(string.format("#YCấp hiện tại: #G%d#W / %d", new_level, self.MAX_LEVEL))
	self:AddText(string.format("#YTổng cộng giới hạn HP nhân vật: #G+%d#W", new_level * self.DU_HP_PER_LEVEL))
	self:AddText(" ")
	if new_level < self.MAX_LEVEL then
		self:AddNumText("#GTăng cấp Đốc mạch", 6, 301)
	else
		self:AddText("#RĐốc mạch đã tầng cao nhất.")
	end
	self:AddNumText("Về menu chính", 6, 9999)
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end

function jingmai:UpgradeMaiByExp(selfId, targetId, mai_type)
	local md, max_level, buff_base, name
	if mai_type == "shaoyang" then
		md = self.MD_SHAOYANG_LEVEL
		max_level = self.SHAOYANG_MAX_LEVEL
		buff_base = self.SHAOYANG_BUFF_BASE_ID
		name = "Thủ Thiếu Dương"
	else
		md = self.MD_TAIYIN_LEVEL
		max_level = self.TAIYIN_MAX_LEVEL
		buff_base = self.TAIYIN_BUFF_BASE_ID
		name = "Túc Thái Âm"
	end

	local cur = self:GetMaiLevel(selfId, md)
	local cur_exp = self:GetExp(selfId)
	
	if cur >= max_level then
		self:notify_tips(selfId, name .. "Đã tới tầng cao nhất.")
		return
	end

	if cur_exp < self.EXCHANGE_EXP_COST then
		self:notify_tips(selfId, "Kinh nghiệm không đủ 200 triệu, không tăng được" .. name .. "。")
		return
	end

	local new_level = cur + 1
	
	-- 先执行升级
	self:LuaFnCostExp(selfId, self.EXCHANGE_EXP_COST)
	self:SetMissionData(selfId, md, new_level)
	self:MarkJingMaiAttribDirty(selfId)

	-- 属性已直接加成到jingmai_attr_bonus，无需额外BUFF
	-- 每10级送一个buff
	-- if new_level % 10 == 0 then
	-- 	local buff_id = buff_base + (new_level / 10) - 1
	-- 	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, buff_id, 0)
	-- end

	-- 头顶提示广播
	local player_name = self:GetName(selfId)
	local broadcast_msg = string.format("#W#{_INFOUSR%s}#Wtu luyện kinh mạch, %s lên tầng %d!", player_name, name, new_level)
	broadcast_msg = gbk.fromutf8(broadcast_msg)
	self:BroadMsgByChatPipe(selfId, broadcast_msg, 4)

	-- 显示提示并刷新菜单
	local level = self:GetMaiLevel(selfId, md)
	self:BeginEvent(self.script_id)
	self:AddText(string.format("#GTăng %s thành công! Cấp hiện tại: %d", name, new_level))
	self:AddText(" ")
	if mai_type == "shaoyang" then
		self:AddText("#WTăng Thủ Thiếu Dương#W")
		self:AddText("#WThủ Thiếu Dương mỗi 10 cấp tăng 1% sát thương, mỗi 10 cấp thêm một Buff.#W")
		self:AddText(string.format("#YCấp hiện tại: #G%d#W / %d", level, self.SHAOYANG_MAX_LEVEL))
		self:AddText(string.format("#WTăng cần tốn: #G%d#W kinh nghiệm", self.EXCHANGE_EXP_COST))
		self:AddText(" ")
		if level < self.SHAOYANG_MAX_LEVEL then
			self:AddNumText("#GTăng cấp Thủ Thiếu Dương", 6, 103)
		else
			self:AddText("#RThủ Thiếu Dương đã tầng cao nhất.")
		end
	else
		self:AddText("#WTăng Túc Thái Âm#W")
		self:AddText("#WTúc Thái Âm mỗi 10 cấp giảm 1% sát thương nhận, mỗi 10 cấp thêm một Buff.#W")
		self:AddText(string.format("#YCấp hiện tại: #G%d#W / %d", level, self.TAIYIN_MAX_LEVEL))
		self:AddText(string.format("#WTăng cần tốn: #G%d#W kinh nghiệm", self.EXCHANGE_EXP_COST))
		self:AddText(" ")
		if level < self.TAIYIN_MAX_LEVEL then
			self:AddNumText("#GTăng cấp Túc Thái Âm", 6, 104)
		else
			self:AddText("#RTúc Thái Âm đã tầng cao nhất.")
		end
	end
	self:AddNumText("Về menu chính", 6, 9999)
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end

return jingmai