--幻魂
--脚本号
local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local huanhun = class("huanhun", script_base)

function huanhun:ActiveWg(selfId, ...)
    local huanhun_id = ...
    local huanhun_config = self:GetWuHunWgConfig(huanhun_id)
	
	local costtab = {}
	local itemcount
	local allnum = 0
	for i,j in ipairs(huanhun_config.active_cost_materials) do
		itemcount = self:LuaFnGetAvailableItemCount(selfId, j)
		if itemcount > 0 then
			allnum = allnum + itemcount
			table.insert(costtab,j)
		end
	end
    if allnum < huanhun_config.active_cost_material_count then
        self:notify_tips(selfId, "Không đủ nguyên liệu")
        return
    end
    local nMoneySelf = self:GetMoneyJZ(selfId) + self:GetMoney(selfId)
    if nMoneySelf < huanhun_config.active_cost_money then
        self:notify_tips(selfId, "Xin lỗi, kim tiền trên người ngươi không đủ, không thể tiếp tục")
        return
    end
    local wg = self:GetWuHunWg(selfId)
    local s_huanhun_id = tostring(huanhun_id)
    if wg[s_huanhun_id] then
        self:notify_tips(selfId, "Đã kích hoạt")
        return
    end
    if not self:LuaFnMtl_CostMaterial(selfId, huanhun_config.active_cost_material_count, costtab) then
        self:notify_tips(selfId, "Trừ nguyên liệu thất bại")
        return
    end
    self:LuaFnCostMoneyWithPriority(selfId, huanhun_config.active_cost_money)
    self:UnLockWuHunWg(selfId, huanhun_id)
    self:notify_tips(selfId, "Huyễn hồn kích hoạt thành công!")
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
end

function huanhun:skill_effect_on_uint_once(selfId, ...)
    local type, arg1, arg2 = ...
    if type == 2 then
        self:filling_in(selfId, arg1, arg2)
    end
end

function huanhun:filling_in(selfId, arg1, arg2)
	if not selfId or selfId >= 0 then
		return
	end
	selfId = selfId * -1
    local wg = self:GetWuHunWg(selfId)
    local s_huanhun_id = tostring(arg2)
    if not wg[s_huanhun_id] then
        self:notify_tips(selfId, "Huyễn hồn chưa kích hoạt")
        return
    end
    self:SetWuHunWgQKIndex(selfId, arg1, arg2)
end
function huanhun:SwitchYY(selfId,wg_flag)
	if wg_flag ~= 0 and wg_flag ~= 1 then
		return
	end
	self:SetWuHunWgVisualFlag(selfId,wg_flag)
end
function huanhun:SetShowWuhun(selfId,show)
	if show ~= 0 and show ~= 1 then
		return
	end
	self:SetWuHunShowState(selfId,show)
end
function huanhun:TakeOut(selfId,qk_flag)
	if qk_flag ~= 0 and qk_flag ~= 1 then
		return
	end
	self:SetWuHunWgQKIndex(selfId, qk_flag, 0)
end

function huanhun:LevelUpWg(selfId, ...)
    local huanhun_id = ...
    local index = self:GetWuHunWgIndex(selfId, huanhun_id)
    if index == 0 then
        self:notify_tips(selfId, "Huyễn hồn chưa kích hoạt")
        return
    end
    local wuhun_wg_level = self:GetWuHunWgLevelConfig()
    wuhun_wg_level = wuhun_wg_level[index]
    assert(wuhun_wg_level, index)
    local cost_money = wuhun_wg_level.cost_money
    if cost_money == define.INVAILD_ID then
        self:notify_tips(selfId, "Huyễn hồn đã tối đa")
        return
    end
    local cost_materials = wuhun_wg_level.cost_materials
    local cost_materials_count = wuhun_wg_level.cost_materials_count
	local costtab = {}
	local itemcount
	local allnum = 0
	for i,j in ipairs(cost_materials) do
		itemcount = self:LuaFnGetAvailableItemCount(selfId, j)
		if itemcount > 0 then
			allnum = allnum + itemcount
			table.insert(costtab,j)
		end
	end
	
	
    if allnum < cost_materials_count then
        self:notify_tips(selfId, "Không đủ nguyên liệu")
        return
    end
    local nMoneySelf = self:GetMoneyJZ(selfId) + self:GetMoney(selfId)
    if nMoneySelf < cost_money then
        self:notify_tips(selfId, "Xin lỗi, kim tiền trên người ngươi không đủ, không thể tiếp tục")
        return
    end
    if not self:LuaFnMtl_CostMaterial(selfId, cost_materials_count, costtab) then
        self:notify_tips(selfId, "Trừ nguyên liệu thất bại")
        return
    end
    self:LuaFnCostMoneyWithPriority(selfId, cost_money)
    self:WuHunWgLevelUp(selfId, huanhun_id)
    self:notify_tips(selfId, "Huyễn hồn thăng cấp thành công!")
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
end

function huanhun:GradeUpWg(selfId, ...)
    local huanhun_id = ...
    local index = self:GetWuHunWgIndex(selfId, huanhun_id)
    if index == 0 then
        self:notify_tips(selfId, "Huyễn hồn chưa kích hoạt")
        return
    end
    local wuhun_wg_level = self:GetWuHunWgLevelConfig()
    wuhun_wg_level = wuhun_wg_level[index]
    assert(wuhun_wg_level, index)
    local cost_money = wuhun_wg_level.cost_money
    if cost_money == define.INVAILD_ID then
        self:notify_tips(selfId, "Huyễn hồn đã tối đa")
        return
    end
    local cost_materials = wuhun_wg_level.cost_materials
    local cost_materials_count = wuhun_wg_level.cost_materials_count
	local costtab = {}
	local itemcount
	local allnum = 0
	for i,j in ipairs(cost_materials) do
		itemcount = self:LuaFnGetAvailableItemCount(selfId, j)
		if itemcount > 0 then
			allnum = allnum + itemcount
			table.insert(costtab,j)
		end
	end
    if allnum < cost_materials_count then
        self:notify_tips(selfId, "Không đủ nguyên liệu")
        return
    end
    local nMoneySelf = self:GetMoneyJZ(selfId) + self:GetMoney(selfId)
    if nMoneySelf < cost_money then
        self:notify_tips(selfId, "Xin lỗi, kim tiền trên người ngươi không đủ, không thể tiếp tục")
        return
    end
    if not self:LuaFnMtl_CostMaterial(selfId, cost_materials_count, costtab) then
        self:notify_tips(selfId, "Trừ nguyên liệu thất bại")
        return
    end
    self:LuaFnCostMoneyWithPriority(selfId, cost_money)
    self:WuHunWgLevelUp(selfId, huanhun_id)
    self:notify_tips(selfId, "Huyễn hồn tiến giai thành công!")
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
end

-- [2026-09-11] client Wuhun_OpenWGChange -> OpenChangeWg (bản gốc tlbb15 chỉ kiểm cấp 80)
function huanhun:OpenChangeWg(selfId)
    if self:GetLevel(selfId) < 80 then
        self:notify_tips(selfId, "#{WH_210223_213}")
        return
    end
end

-- CYS-WUHUN-APPEARANCE
local appearance=require 'cys_wuhun_appearance'
function huanhun:CysFill(id,side,soul)
 local h=self.scene:get_obj_by_id(id)
 if h and h:get_obj_type()=='human' then return appearance.slot(self,h,side,soul) end
end
for _,name in ipairs({'ActiveWg','LevelUpWg','GradeUpWg','SwitchYY','TakeOut','SetShowWuhun','OpenChangeWg','CysState'})do
 local original=huanhun[name]
 huanhun[name]=function(self,id,arg)return appearance.operate(self,id,name,arg,original)end
end

function huanhun:CysDualSoul(id,op,value)
 local h=self.scene:get_obj_by_id(id);if not h or h:get_obj_type()~='human' then return end
 local m=require 'cys_dual_souls'
 if op==1 and (value==0 or value==1) then
  h:set_game_flag_key('cys_assault_hidden',1-value);m.snapshot(self.scene,h,nil,true)
 elseif op==0 then m.snapshot(self.scene,h)
 end
end
return huanhun
