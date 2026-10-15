local class = require "class"
local define = require "define"
local gbk = require "wire_charset"
-- local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local newexterior_weapon_levelup = class("newexterior_weapon_levelup", script_base)
newexterior_weapon_levelup.script_id = 893340
function newexterior_weapon_levelup:OnDefaultEvent( selfId,targetId )
		self:BeginEvent()
			self:AddText("#{HSWQ_20220607_20}")
			self:AddNumText( "#{HSWQ_20220607_21}", 6, 1 )
			self:AddNumText( "#{HSWQ_20220607_22}", 11, 100 ) 
		self:EndEvent(sceneId)
		self:DispatchEventList(selfId,targetId)
end
function newexterior_weapon_levelup:OnEventRequest(selfId, targetId, arg, index)
	if index == 0 then
		self:OnDefaultEvent( selfId,targetId )
	elseif index == 1 then
		self:BeginUICommand()
		self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId,89334001)
	elseif index == 100 then
		self:BeginEvent()
			self:AddNumText( "#{HSWQ_20220607_40}", 11, 101 ) 
			self:AddNumText( "#{HSWQ_20220607_41}", 11, 102 ) 
			self:AddNumText( "Trở về trang chủ", 11, 0 ) 
		self:EndEvent(sceneId)
		self:DispatchEventList(selfId,targetId)
	elseif index == 101 then
		self:BeginEvent()
			self:AddText("#{HSWQ_20220607_43}")
			self:AddNumText( "Trở về trang chủ", 11, 0 ) 
		self:EndEvent(sceneId)
		self:DispatchEventList(selfId,targetId)
	elseif index == 102 then
		self:BeginEvent()
			self:AddText("#{HSWQ_20220607_44}")
			self:AddNumText( "Trở về trang chủ", 11, 0 ) 
		self:EndEvent(sceneId)
		self:DispatchEventList(selfId,targetId)
	end
end

function newexterior_weapon_levelup:TryExteriorWeaponLevelUp( selfId,visual,buyflag )
	local level = self:GetWeaponVisualLevel(selfId,visual)
	if level == define.INVAILD_ID then
		self:notify_tips(selfId,"#{HSWQ_20220607_59}")
		return
	elseif level >= self:GetWeaponVisualMaxLevel(selfId,visual) then
		self:notify_tips(selfId,"#{HSWQ_20220607_29}")
		return
	end
	local needmoney,needitem,needcount = self:GetWeaponlevelUpCost(selfId,visual,level + 1)
	if needmoney == 0 or needitem == 0 or needcount == 0 then
		self:notify_tips(selfId,"#{HSWQ_20220607_30}")
		return
	end
	if self:GetMoney(selfId) + self:GetMoneyJZ(selfId) < needmoney then
		self:notify_tips(selfId,"#{HSWQ_20220607_38}")
		return
	end
	if self:LuaFnGetAvailableItemCount(selfId, needitem) < needcount then
		self:notify_tips(selfId,"#{HSWQ_20220607_37}")
		return
	end
	self:LuaFnDelAvailableItem(selfId, needitem, needcount)
	self:LuaFnCostMoneyWithPriority(selfId, needmoney)
	self:SetWeaponVisualLevel(selfId,visual,level + 1)
	self:ShowObjBuffEffect(selfId,selfId,-1,18)
	self:notify_tips(selfId,"#{HSWQ_20220607_39}")
end
return newexterior_weapon_levelup
