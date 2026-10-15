local class = require "class"
local define = require "define"
local gbk = require "wire_charset"
-- local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local dw_jinjie_finedraw = class("dw_jinjie_finedraw", script_base)
dw_jinjie_finedraw.script_id = 809272
dw_jinjie_finedraw.g_LCS_Yuanbao = 98			--灵蚕丝元宝售价   客户端有定义显示
	-- 金蚕丝, 强化用的道具, 按照 绑定 -> 元宝交易 -> 随便交易 顺序使用
dw_jinjie_finedraw.g_DWJinJieQianghua_ToolItem = {20310168, 20310166, 20310167}
dw_jinjie_finedraw.g_DWJinJieQianghua_ToolItem2 = 20310174
dw_jinjie_finedraw.g_LCS2JCS = 5

dw_jinjie_finedraw.g_EquipPoint2DWJinJie_Tool_ItemID = {
	[0] = 30900200,--武器
	[1] = 30900206,--帽子
	[2] = 30900205,--衣服
	[3] = 30900209,--手套
	[4] = 30900211,--鞋
	[5] = 30900210,--腰带
	[6] = 30900212,--戒指
	[7] = 30900204,--项链
	[11] = 30900212,--戒指2
	[12] = 30900213,--护符
	[13] = 30900213,--护符2
	[14] = 30900208,--护腕
	[15] = 30900207,--护肩
	[17] = 30900201,--暗器
	[18] = 30900202,--武魂
	[37] = 30900203,--七情刃
}

function dw_jinjie_finedraw:OnDefaultEvent( selfId,targetId )
	local npcname = self:GetName(targetId)
	if npcname == "张伏虎" then
		self:BeginEvent()
			self:AddText("#{DWJJ_240329_04}")
			self:AddNumText( "#{DWJJ_240329_05}", 6, 1 )
			self:AddNumText( "#{DWJJ_240329_06}", 6, 2 )
			self:AddNumText( "#{DWJJ_240329_08}", 6, 3 )
			self:AddNumText( "#{DWJJ_240329_11}", 11, 100 ) 
		self:EndEvent(sceneId)
		self:DispatchEventList(selfId,targetId)
	elseif npcname == "张笑师" then
		self:BeginEvent()
			self:AddText("#{DWJJ_240329_195}")
			self:AddNumText( "#{DWJJ_240329_67}", 6, 4 )
			self:AddNumText( "#{DWJJ_240329_196}", 6, 5 )
			self:AddNumText( "#{DWJJ_240329_193}", 11, 104 )
			self:AddNumText( "#{DWJJ_240329_355}", 11, 105 ) 
		self:EndEvent(sceneId)
		self:DispatchEventList(selfId,targetId)
	end
end
function dw_jinjie_finedraw:OnEventRequest(selfId, targetId, arg, index)
	if index == 0 then
		self:OnDefaultEvent( selfId,targetId )
	elseif index == 1 then
		self:BeginUICommand()
		self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId,89030501)
	elseif index == 2 then
		self:BeginUICommand()
		self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId,89030502)
	elseif index == 3 then
		self:BeginUICommand()
		self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId,89030504)
	elseif index == 4 then
		self:BeginUICommand()
		self:UICommand_AddInt(1)
		self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId,89030506)
	elseif index == 5 then
		self:BeginUICommand()
		self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId,89030505)
	elseif index == 100 then
		self:BeginEvent()
			self:AddNumText( "#{DWJJ_240329_11}", 11, 101 ) 
			self:AddNumText( "#{DWJJ_240329_352}", 11, 102 ) 
			self:AddNumText( "#{DWJJ_240329_354}", 11, 103 ) 
			self:AddNumText( "Trở về trang chủ", 11, 0 ) 
		self:EndEvent(sceneId)
		self:DispatchEventList(selfId,targetId)
	elseif index == 101 then
		self:BeginEvent()
			self:AddText("#{DWJJ_240329_351}")
			self:AddNumText( "Trở về trang chủ", 11, 0 ) 
		self:EndEvent(sceneId)
		self:DispatchEventList(selfId,targetId)
	elseif index == 102 then
		self:BeginEvent()
			self:AddText("#{DWJJ_240329_353}")
			self:AddNumText( "Trở về trang chủ", 11, 0 ) 
		self:EndEvent(sceneId)
		self:DispatchEventList(selfId,targetId)
	elseif index == 103 then
		self:BeginEvent()
			self:AddText("#{DWJJ_240329_12}")
			self:AddNumText( "Trở về trang chủ", 11, 0 ) 
		self:EndEvent(sceneId)
		self:DispatchEventList(selfId,targetId)
	elseif index == 104 then
		self:BeginEvent()
			self:AddText("#{DWJJ_240329_194}")
			self:AddNumText( "Trở về trang chủ", 11, 0 ) 
		self:EndEvent(sceneId)
		self:DispatchEventList(selfId,targetId)
	elseif index == 105 then
		self:BeginEvent()
			self:AddText("#{DWJJ_240329_356}")
			self:AddNumText( "Trở về trang chủ", 11, 0 ) 
		self:EndEvent(sceneId)
		self:DispatchEventList(selfId,targetId)
	end
end
function dw_jinjie_finedraw:CheckNpcDist( selfId,npcid )
	if npcid ~= -1 then
		if not self:IsInDist(selfId, npcid, 5) then
			self:notify_tips(selfId,"#{DWJJ_240329_28}")
			return true
		end
	end
	return false
end

function dw_jinjie_finedraw:DoDiaowenJinJie( selfId,npcid,eqpos,itempos )
	if self:CheckNpcDist( selfId,npcid ) then
		return
	elseif not eqpos or eqpos < 0 then
		return
	elseif not itempos or itempos < 0 then
		return
	end
	local eqid = self:LuaFnGetItemTableIndexByIndex(selfId,eqpos)
	if eqid == define.INVAILD_ID then
		self:notify_tips(selfId,"#{DWJJ_240329_29}")
		return
	end
	local eqpoint = self:GetItemEquipPoint(eqid)
	if not eqpoint then
		self:notify_tips(selfId,"#{DWJJ_240329_29}")
		return
	end
	local needitem = self.g_EquipPoint2DWJinJie_Tool_ItemID[eqpoint]
	if not needitem then
		self:notify_tips(selfId,"#{DWJJ_240329_29}")
		return
	end
	local itemid = self:LuaFnGetItemTableIndexByIndex(selfId,itempos)
	if itemid ~= needitem then
		self:notify_tips(selfId,"#{DWJJ_240329_31}")
		return
	end
	local g_DWJinJieNeedMoney = 500000
	if self:GetMoney(selfId) + self:GetMoneyJZ(selfId) < g_DWJinJieNeedMoney then
		self:notify_tips(selfId,"#{HSWQ_20220607_38}")
		return
	end
	local _,dwlv,dw_advance_level = self:GetDiaoWenFineDraw(selfId, eqpos)
	if dwlv < 4 then
		self:notify_tips(selfId,"Điêu văn cấp 4 trở lên mới tinh hội được.")
		return
	end
	if dw_advance_level > 0 then
		self:notify_tips(selfId,"#{DWJJ_240329_30}")
		return
	end
	self:LuaFnDecItemLayCount(selfId, itempos, 1)
	self:LuaFnCostMoneyWithPriority(selfId, g_DWJinJieNeedMoney)
	local isok = self:SetDiaoWenFineDraw(selfId, eqpos)
	if isok then
		self:notify_tips(selfId,"#{DWJJ_240329_37}")
		if isok ~= "" then
			self:notify_tips(selfId,"Bạn đồng thời kích hoạt khắc văn mới:"..isok)
		end
	end
end
function dw_jinjie_finedraw:DoDiaowenJinJieQiangHua( selfId,npcid,eqpos,count1,count2 )
	if self:CheckNpcDist( selfId,npcid ) then
		return
	elseif not eqpos or eqpos < 0 then
		return
	elseif not count1 or not count2 then
		self:notify_tips(selfId,"Số lượng bất thường.")
		return
	end
	local eqid = self:LuaFnGetItemTableIndexByIndex(selfId,eqpos)
	if eqid == define.INVAILD_ID then
		self:notify_tips(selfId,"#{DWJJ_240329_29}")
		return
	end
	local eqpoint = self:GetItemEquipPoint(eqid)
	if not eqpoint then
		self:notify_tips(selfId,"#{DWJJ_240329_29}")
		return
	end
	local needitem = self.g_EquipPoint2DWJinJie_Tool_ItemID[eqpoint]
	if not needitem then
		self:notify_tips(selfId,"#{DWJJ_240329_42}")
		return
	end
	local _,dwlv,dw_advance_level,dw_rankexp = self:GetDiaoWenFineDraw(selfId, eqpos)
	if dwlv < 4 then
		self:notify_tips(selfId,"error。")
		return
	end
	local finedrawlv = dw_advance_level // 5
	local dw_advance_level,dw_rankexp = self:GetDiaoWenFineDraw(selfId, eqpos)
	if dw_advance_level == 0 then
		self:notify_tips(selfId,"#{DWJJ_240329_57}")
		return
	elseif finedrawlv >= dwlv then
		self:notify_tips(selfId,"#{DWJJ_240329_60}")
		return
	elseif finedrawlv >= 10 then
		self:notify_tips(selfId,"#{DWJJ_240329_58}")
		return
	end
	local itemcount = {0,0,0}
	local itemallcount = 0
	local itemcount2 = 0
	local addexp = 0
	if count1 > 0 then
		for i,j in ipairs(self.g_DWJinJieQianghua_ToolItem) do
			itemcount[i] = self:LuaFnGetAvailableItemCount(selfId, j)
			itemallcount = itemallcount + itemcount[i]
		end
		if itemallcount < count1 then
			self:notify_tips(selfId,"#{DWJJ_240329_61}")
			return
		end
		addexp = count1
	end
	if count2 > 0 then
		itemcount2 = self:LuaFnGetAvailableItemCount(selfId, self.g_DWJinJieQianghua_ToolItem2)
		if itemcount2 < count2 then
			self:notify_tips(selfId,"#{DWJJ_240329_66}")
			return
		end
		addexp = addexp + count2 * self.g_LCS2JCS
	end
	addexp = addexp + dw_rankexp
	if count1 > 0 then
		local delcount = count1
		for i,j in ipairs(itemcount) do
			if j >= delcount then
				self:LuaFnDelAvailableItem(selfId, self.g_DWJinJieQianghua_ToolItem[i], delcount)
			elseif j > 0 then
				self:LuaFnDelAvailableItem(selfId, self.g_DWJinJieQianghua_ToolItem[i], j)
				delcount = delcount - j
			end
		end
		if delcount > 0 then
			self:notify_tips(selfId,"del count1 error.")
			return
		end
	end
	if count2 > 0 then
		self:LuaFnDelAvailableItem(selfId, self.g_DWJinJieQianghua_ToolItem2, count2)
	end
	self:AddDiaoWenFineDrawExp(selfId, eqpos, dwlv, dw_advance_level, addexp)
	self:notify_tips(selfId,"#{DWJJ_240329_63}")
end
function dw_jinjie_finedraw:DoDiaowenJinJieShengJi( selfId,npcid,eqpos,buyflag,boxflag,tarlevel )
	if self:CheckNpcDist( selfId,npcid ) then
		return
	elseif not eqpos or eqpos < 0 then
		return
	elseif not tarlevel or tarlevel < 1 then
		return
	end
	local eqid = self:LuaFnGetItemTableIndexByIndex(selfId,eqpos)
	if eqid == define.INVAILD_ID then
		self:notify_tips(selfId,"#{DWJJ_240329_29}")
		return
	end
	local eqpoint = self:GetItemEquipPoint(eqid)
	if not eqpoint then
		self:notify_tips(selfId,"#{DWJJ_240329_29}")
		return
	end
	local needitem = self.g_EquipPoint2DWJinJie_Tool_ItemID[eqpoint]
	if not needitem then
		self:notify_tips(selfId,"#{DWJJ_240329_42}")
		return
	end
	local _,dwlv,dw_advance_level,dw_rankexp = self:GetDiaoWenFineDraw(selfId, eqpos)
	if dwlv < 4 then
		self:notify_tips(selfId,"error。")
		return
	end
	local finedrawlv = dw_advance_level // 5
	local dw_advance_level,dw_rankexp = self:GetDiaoWenFineDraw(selfId, eqpos)
	if dw_advance_level == 0 then
		self:notify_tips(selfId,"#{DWJJ_240329_57}")
		return
	elseif finedrawlv >= dwlv then
		self:notify_tips(selfId,"#{DWJJ_240329_91}")
		return
	elseif finedrawlv >= 10 then
		self:notify_tips(selfId,"#{DWJJ_240329_90}")
		return
	end
	if tarlevel > dwlv or tarlevel > 10 then
		self:notify_tips(selfId,"Tầng chọn không vượt cấp điêu văn gốc được, xin chọn lại.")
		return
	elseif tarlevel <= finedrawlv then
		self:notify_tips(selfId,"#{DWJJ_240329_92}")
		return
	end
	local tarlevel_value = tarlevel * 5
	local needexp = self:GetDiaoWenFineDrawNeedExp(selfId, dw_advance_level, tarlevel_value - 1)
	needexp = needexp - dw_rankexp
	if needexp == 0 then
		self:notify_tips(selfId,"error。。")
		return
	end
	local needcount = math.ceil(needexp / self.g_LCS2JCS)
	local havecount = self:LuaFnGetAvailableItemCount(selfId, self.g_DWJinJieQianghua_ToolItem2)
	--未添加元宝购买
	if havecount < needcount then
		self:notify_tips(selfId,"#{DWJJ_240329_66}")
		return
	end
	self:LuaFnDelAvailableItem(selfId, self.g_DWJinJieQianghua_ToolItem2, needcount)
	self:SetDiaoWenFineDrawDetails(selfId, BagPos, tarlevel_value, 0)
	self:notify_tips(selfId,"#{DWJJ_240329_63}")
end

function dw_jinjie_finedraw:DoDiaowenJinJieHuiTui( selfId,npcid,eqpos,boxflag )
	if self:CheckNpcDist( selfId,npcid ) then
		return
	elseif not eqpos or eqpos < 0 then
		return
	end
	local eqid = self:LuaFnGetItemTableIndexByIndex(selfId,eqpos)
	if eqid == define.INVAILD_ID then
		self:notify_tips(selfId,"#{DWJJ_240329_29}")
		return
	end
	local eqpoint = self:GetItemEquipPoint(eqid)
	if not eqpoint then
		self:notify_tips(selfId,"#{DWJJ_240329_29}")
		return
	end
	local needitem = self.g_EquipPoint2DWJinJie_Tool_ItemID[eqpoint]
	if not needitem then
		self:notify_tips(selfId,"#{DWJJ_240329_42}")
		return
	end
	local _,dwlv,dw_advance_level,dw_rankexp = self:GetDiaoWenFineDraw(selfId, eqpos)
	if dwlv < 4 then
		self:notify_tips(selfId,"#{DWJJ_240329_42}")
		return
	elseif dw_advance_level == 0 then
		self:notify_tips(selfId,"#{DWJJ_240329_42}")
		return
	end
	local spacecount = self:LuaFnGetPropertyBagSpace(selfId)
	if spacecount < 2 then
		self:notify_tips(selfId,"#{DWJJ_240329_113}")
		return
	end
	dw_rankexp = dw_rankexp + self:GetDiaoWenFineDrawNeedExp(selfId, 1, dw_advance_level - 1)
	local backlcs = math.ceil(dw_rankexp / self.g_LCS2JCS)
	local Value = backlcs * self.g_LCS_Yuanbao
	local needyb = math.ceil(Value * 0.4)
	if needyb > self:GetYuanBao(selfId) then
		self:notify_tips(selfId,"#{DWJJ_240329_112}")
		return
	end
	if boxflag == 0 then
		self:BeginUICommand()
		self:UICommand_AddInt(npcid)
		self:UICommand_AddInt(eqpos)
		self:UICommand_AddInt(needyb)
		self:UICommand_AddInt(backlcs)
		self:UICommand_AddInt(Value)
		self:EndUICommand()
		self:DispatchUICommand(selfId,89030513)
		return
	end
	self:EmptyDiaoWenJinJie(selfId,eqpos,needyb,needitem,38000960,backlcs)
end
function dw_jinjie_finedraw:DoTeXingQiangHua( selfId,npcid,dw_featuresid )
	if self:CheckNpcDist( selfId,npcid ) then
		return
	elseif not dw_featuresid or dw_featuresid < 1 then
		self:notify_tips(selfId,"#{DWJJ_240329_180}")
		return
	end
	local level,nexp = self:LuaFnGetFeaturesDetails(selfId,dw_featuresid)
	if not level then
		level,nexp = 0,0
	end
	local needexp,_,_,needitem = self:GetDiaoWenJinJieFeaturesDetails(dw_featuresid,level)
	if needexp == 0 then
		self:notify_tips(selfId,"#{DWJJ_240329_188}")
		return
	elseif needexp < 0 then
		self:notify_tips(selfId,"#{DWJJ_240329_180}")
		return
	elseif needexp <= nexp then
		self:notify_tips(selfId,"#{DWJJ_240329_182}")
		return
	end
	local havecount = self:LuaFnGetAvailableItemCount(selfId,needitem)
	if havecount < 1 then
		local msg = self:ScriptGlobal_Format("#{DWJJ_240329_183}",self:GetItemName(needitem))
		self:notify_tips(selfId,msg)
		return
	end
	self:LuaFnDelAvailableItem(selfId, needitem, 1)
	nexp = nexp + 1
	self:LuaFnSetFeaturesDetails(selfId,dw_featuresid,level,nexp)
	self:notify_tips(selfId,"#{DWJJ_240329_184}")
	self:BeginUICommand()
	self:UICommand_AddInt(2)
	self:EndUICommand()
	self:DispatchUICommand(selfId,89030506)
end
function dw_jinjie_finedraw:DoTeXingShengJi( selfId,npcid,dw_featuresid )
	if self:CheckNpcDist( selfId,npcid ) then
		return
	elseif not dw_featuresid or dw_featuresid < 1 then
		self:notify_tips(selfId,"#{DWJJ_240329_180}")
		return
	end
	local level,nexp = self:LuaFnGetFeaturesDetails(selfId,dw_featuresid)
	if not level then
		self:notify_tips(selfId,"#{DWJJ_240329_189}")
		return
	end
	local needexp,needmoney,needcount = self:GetDiaoWenJinJieFeaturesDetails(dw_featuresid,level)
	if needexp == 0 then
		self:notify_tips(selfId,"#{DWJJ_240329_188}")
		return
	elseif needexp < 0 then
		self:notify_tips(selfId,"#{DWJJ_240329_180}")
		return
	elseif needexp > nexp then
		self:notify_tips(selfId,"#{DWJJ_240329_189}")
		return
	end
	if self:GetMoney(selfId) + self:GetMoneyJZ(selfId) < needmoney then
		self:notify_tips(selfId,"#{HSWQ_20220607_38}")
		return
	end
	if needcount > 0 then
		local havecount = self:LuaFnGetAvailableItemCount(selfId,20310175)
		if havecount < needcount then
			self:notify_tips(selfId,"#{DWJJ_240329_190}")
			return
		end
		self:LuaFnDelAvailableItem(selfId, 20310175, needcount)
	end
	self:LuaFnCostMoneyWithPriority(selfId, needmoney)
	level = level + 1
	nexp = 0
	self:LuaFnSetFeaturesDetails(selfId,dw_featuresid,level,nexp)
	self:notify_tips(selfId,"#{DWJJ_240329_191}")
	self:BeginUICommand()
	self:UICommand_AddInt(2)
	self:EndUICommand()
	self:DispatchUICommand(selfId,89030506)
end
function dw_jinjie_finedraw:DoDiaowenJinJieTeXingGengHuan( selfId,npcid,eqpoint,dw_featureId,useflag )
	if self:CheckNpcDist( selfId,npcid ) then
		return
	elseif not eqpoint or not self.g_EquipPoint2DWJinJie_Tool_ItemID[eqpoint] then
		return
	elseif not dw_featureId or dw_featureId < 1 then
		return
	end
	--更换或卸下时还有些相关BUFF在角色身上时不给卸下且给提示  备忘
	if useflag == 0 then
		if self:UnDiaoWenFeatures(selfId,eqpoint) then
			self:notify_tips(selfId,"#{DWJJ_240329_200}")
		end
	else
	local _,dwlv,dw_advance_level = self:GetDiaoWenFineDraw(selfId, eqpoint,eqpoint)
		if dwlv < 4 then
			self:notify_tips(selfId,"Trang bị này chưa tinh hội.")
			return
		elseif dw_advance_level < 1 then
			self:notify_tips(selfId,"Trang bị này chưa tinh hội.")
			return
		end
		local haveid = self:LuaFnGetFeaturesDetails(selfId,dw_featureId)
		if not haveid or haveid < 1 then
			self:notify_tips(selfId,"#{DWJJ_240329_201}")
			return
		end
		self:UseDiaoWenFeatures(selfId,eqpoint,dw_featureId)
	end
    local human = self:get_scene():get_obj_by_id(selfId)
	local packet_def = require "game.packet"
    -- local ret = packet_def.GCUnEquipResult.new()
	-- ret.result = 1
	-- ret.equipPoint = 0
	-- ret.item_guid = {0,0,0,0}
	-- ret.item_index = 38000960
	-- ret.bagIndex = 0
	-- self:get_scene():send2client(human, ret)
	    -- local ret = packet_def.GCUseEquipResult.new()
    -- ret.bagIndex = -1
    -- ret.equipPoint = eqpoint
	 -- self:send2client(obj_me, ret)
	
	
	self:BeginUICommand()
	self:UICommand_AddInt(dw_featureId)
	self:EndUICommand()
	self:DispatchUICommand(selfId,89030505)
end
return dw_jinjie_finedraw
