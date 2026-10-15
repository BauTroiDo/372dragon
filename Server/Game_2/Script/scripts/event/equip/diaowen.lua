--雕纹
--脚本号
local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local diaowen = class("diaowen", script_base)
diaowen.script_id = 809272
diaowen.g_LCS_Yuanbao = 98			--灵蚕丝元宝售价   客户端有定义显示
	-- 金蚕丝, 强化用的道具, 按照 绑定 -> 元宝交易 -> 随便交易 顺序使用
diaowen.g_DWJinJieQianghua_ToolItem = {20310168, 20310166, 20310167}
diaowen.g_DWJinJieQianghua_ToolItem2 = 20310174
diaowen.g_LCS2JCS = 5

diaowen.g_EquipPoint2DWJinJie_Tool_ItemID = {
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

function diaowen:OnDefaultEvent( selfId,targetId )
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
	elseif npcname == "张笑狮" then
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
function diaowen:OnEventRequest(selfId, targetId, arg, index)
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
function diaowen:CheckNpcDist( selfId,npcid )
	if npcid ~= -1 then
		if not self:IsInDist(selfId, npcid, 5) then
			self:notify_tips(selfId,"#{DWJJ_240329_28}")
			return true
		end
	end
	return false
end

function diaowen:DoDiaowenJinJie( selfId,npcid,eqpos,itempos )
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
	local dwlv,dw_advance_level = self:GetDiaoWenFineDraw(selfId, eqpos)
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
		self:ShowObjBuffEffect(selfId,selfId,-1,18)
		if isok ~= "" then
			-- self:notify_tips(selfId,"您同时激活新的纹刻:"..isok)
		end
	end
end
function diaowen:DoDiaowenJinJieQiangHua( selfId,npcid,eqpos,count1,count2 )
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
	local dwlv,dw_advance_level,dw_rankexp = self:GetDiaoWenFineDraw(selfId, eqpos)
	if dwlv < 4 then
		self:notify_tips(selfId,"error。")
		return
	end
	local finedrawlv = dwlv * 5
	if dw_advance_level == 0 then
		self:notify_tips(selfId,"#{DWJJ_240329_57}")
		return
	elseif dw_advance_level >= finedrawlv then
		self:notify_tips(selfId,"#{DWJJ_240329_60}")
		return
	elseif dw_advance_level >= 50 then
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
	local needexp = self:GetDiaoWenFineDrawNeedExp(selfId, dw_advance_level, finedrawlv - 1)
	if addexp > needexp then
		local msg = "Kinh nghiệm tinh hội vượt giới hạn tầng nâng được, tổng cần"..tostring(needexp).."kinh nghiệm, tránh thiệt hại cho bạn, xin đặt lại số nguyên liệu để thăng cấp."
		self:notify_tips(selfId,msg)
		return
	end
	
	
	if count1 > 0 then
		local delcount = count1
		for i,j in ipairs(itemcount) do
			if j >= delcount then
				self:LuaFnDelAvailableItem(selfId, self.g_DWJinJieQianghua_ToolItem[i], delcount)
				delcount = 0
				break
			elseif j > 0 then
				self:LuaFnDelAvailableItem(selfId, self.g_DWJinJieQianghua_ToolItem[i], j)
				delcount = delcount - j
				if delcount <= 0 then
					break
				end
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
	self:ShowObjBuffEffect(selfId,selfId,-1,18)
end
function diaowen:DoDiaowenJinJieShengJi( selfId,npcid,eqpos,buyflag,boxflag,tarlevel )
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
	local dwlv,dw_advance_level,dw_rankexp = self:GetDiaoWenFineDraw(selfId, eqpos)
	if dwlv < 4 then
		self:notify_tips(selfId,"error。")
		return
	end
	local finedrawlv = dwlv * 5
	if dw_advance_level == 0 then
		self:notify_tips(selfId,"#{DWJJ_240329_57}")
		return
	elseif dw_advance_level >= finedrawlv or tarlevel > finedrawlv then
		self:notify_tips(selfId,"#{DWJJ_240329_91}")
		return
	elseif dw_advance_level >= 50 then
		self:notify_tips(selfId,"#{DWJJ_240329_90}")
		return
	end
	local needexp = self:GetDiaoWenFineDrawNeedExp(selfId, dw_advance_level, tarlevel - 1)
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
	self:SetDiaoWenFineDrawDetails(selfId, eqpos, tarlevel, 0)
	self:notify_tips(selfId,"#{DWJJ_240329_63}")
	self:ShowObjBuffEffect(selfId,selfId,-1,18)
end

function diaowen:DoDiaowenJinJieHuiTui( selfId,npcid,eqpos,boxflag )
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
	local dwlv,dw_advance_level,dw_rankexp = self:GetDiaoWenFineDraw(selfId, eqpos)
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
	self:ShowObjBuffEffect(selfId,selfId,-1,18)
end
function diaowen:DoTeXingQiangHua( selfId,npcid,dw_featuresid )
	-- if 0 == 0 then
		-- self:notify_tips(selfId,"正在维护中。")
		-- return
	-- end


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
	self:ShowObjBuffEffect(selfId,selfId,-1,18)
end
function diaowen:DoTeXingShengJi( selfId,npcid,dw_featuresid )
	-- if 0 == 0 then
		-- self:notify_tips(selfId,"正在维护中。")
		-- return
	-- end
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
	self:ShowObjBuffEffect(selfId,selfId,-1,18)
end
function diaowen:DoDiaowenJinJieTeXingGengHuan( selfId,npcid,eqpoint,dw_featureId,useflag )
	-- if 0 == 0 then
		-- self:notify_tips(selfId,"正在维护中。")
		-- return
	-- end
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
	local dwlv,dw_advance_level = self:GetDiaoWenFineDraw(selfId, eqpoint,eqpoint)
		if dwlv < 4 then
			self:notify_tips(selfId,"Trang bị này chưa tinh hội.")
			return
		elseif dw_advance_level < 1 then
			self:notify_tips(selfId,"Trang bị này chưa tinh hội.")
			return
		end
		if dw_featureId == 15 then
			if dw_advance_level < 5 then
				self:notify_tips(selfId,"Hiệu ứng Vụ Viễn cần tinh hội trang bị đạt cấp 1 bậc 0 trở lên mới đổi được.")
				return
			end
			local feature_lv = self:LuaFnGetFeaturesDetails(selfId,dw_featureId)
			if not feature_lv or feature_lv < 1 then
				self:notify_tips(selfId,"Hiệu ứng Vụ Viễn cần cấp 1 trở lên mới đổi được.")
				return
			end
		end
		local haveid = self:LuaFnGetFeaturesDetails(selfId,dw_featureId)
		if not haveid or haveid < 1 then
			self:notify_tips(selfId,"#{DWJJ_240329_201}")
			return
		end
		self:UseDiaoWenFeatures(selfId,eqpoint,dw_featureId)
	end
	-- self:BeginUICommand()
	-- self:UICommand_AddInt(dw_featureId)
	-- self:EndUICommand()
	-- self:DispatchUICommand(selfId,89030505)
end


function diaowen:DoDiaowenAction(selfId, DataType, ...)
    if self:GetLevel(selfId) < 52 then
		self:notify_tips(selfId, "Lịch duyệt giang hồ của ngươi chưa đủ, sau cấp 52 hãy tìm ta!")
	    return
	end
	
	if DataType == 1 then
		self:DWShike(selfId, ...)
		return
	end
	if DataType == 2 then --雕纹强化
		self:DWQiangHua(selfId,...)
		return
	end
	if DataType == 3 then --雕纹拆除
		self:DWChaiChu(selfId,...)
		return
	end
    if DataType == 4 then
		self:DWHecheng(selfId, ...)
		return
	end
	if DataType == 5 then --雕纹融合
		self:DWRongHe(selfId,...)
		return
	end
	if DataType == 99 then --直接升级雕纹
		self:DWLeveUp(selfId,...)
		return
	end
	if DataType == 100 then --直接升级雕纹
		self:DWDivert(selfId,...)
		return
	end
	if DataType == 101 then --购买熔金粉提示【直接买】
		self:BuyItem_OK(selfId,0)
		return
	end
	if DataType == 102 then --购买熔金粉提示
		self:BuyItem_OK(selfId,1)
	end
	if DataType == 103 then --雕纹拆解用
		self:DWChaiJie(selfId, ...)
		return
	end
end

--**********************************
--雕纹蚀刻
--**********************************
function diaowen:DWShike(selfId,...)
    -- CYS-EQUIPCRAFT open current quote; only Action990029 commits costs.
    local h=self.scene:get_obj_by_id(selfId)
    if h then require('cys_equipcraft').quote(self,h,2,-1,-1,-1,true) end
end
--**********************************
--雕纹合成
--**********************************
local g_needMoeny = 50000
function diaowen:DWHecheng(selfId,...)
    -- CYS-EQUIPCRAFT open current quote; only Action990029 commits costs.
    local h=self.scene:get_obj_by_id(selfId)
    if h then require('cys_equipcraft').quote(self,h,5,-1,-1,-1,true) end
end

--**********************************
--雕纹强化
--**********************************
function diaowen:DWQiangHua(selfId,...)
    -- CYS-EQUIPCRAFT open current quote; only Action990029 commits costs.
    local h=self.scene:get_obj_by_id(selfId)
    if h then require('cys_equipcraft').quote(self,h,3,-1,-1,-1,true) end
end

function diaowen:DoEquipDWLevelUp(selfId, BagPos, targetLevel, check)
    self:notify_tips(selfId, "Cường hóa nhanh đã tắt, xin dùng cường hóa thường.")
    return
    -- local diaowen_id, diaowen_material_count = self:GetEquipDiaoWenData(selfId, BagPos)
    -- local dw_config = self:GetDiaoWenInfoByIndex(diaowen_id)
    -- local all = 0
    -- while dw_config.level < targetLevel do
    --     if dw_config.level == 10 then
    --         break
    --     end
    --     diaowen_id = diaowen_id + 1
    --     all = all + dw_config.enhance_material_count
    --     dw_config = self:GetDiaoWenInfoByIndex(diaowen_id)
    -- end
    -- local need = all - diaowen_material_count
    -- self:DWQiangHua(selfId, BagPos, need)
end

--**********************************
--雕纹拆除
--**********************************
function diaowen:DWChaiChu(selfId,...)
    -- CYS-EQUIPCRAFT open current quote; only Action990029 commits costs.
    local h=self.scene:get_obj_by_id(selfId)
    if h then require('cys_equipcraft').quote(self,h,4,-1,-1,-1,true) end
end

--拆解信息
local g_DWChaiJieInfo={
	[2]={kangxing={28,2},jiankang={84,6},normal={28,2}},
	[3]={kangxing={154,11},jiankang={462,33},normal={154,11}},
	[4]={kangxing={854,61},jiankang={2562,183},normal={854,61}},
	[5]={kangxing={2072,148},jiankang={6216,444},normal={2072,148}},
	[6]={kangxing={4382,313},jiankang={13146,939},normal={4382,313}},
	[7]={kangxing={8358,597},jiankang={25074,1791},normal={8358,597}},
	[8]={kangxing={19712,1408},jiankang={59136,4224},normal={19712,1408}},
	[9]={kangxing={48944,3496},jiankang={146832,10488},normal={48944,3496}},
	[10]={kangxing={87164,6226},jiankang={261492,18678},normal={98924,7066}},
}
function diaowen:DoDiaoWenChaiJie(selfId,bag_pos)
	local diaowen_id = self:LuaFnGetItemTableIndexByIndex(selfId,bag_pos)
	if diaowen_id == -1 then
		self:notify_tips(selfId, "#{DWCJJ_140606_13}" )
		return
	end
    local dw_config = self:GetDiaoWenInfoByProduct(diaowen_id)
	if not dw_config then
		self:notify_tips(selfId, "#{DWCJJ_140606_13}" )
		return
	end
    local ori_level = dw_config.level
	local cj_info = g_DWChaiJieInfo[ori_level]
	if not cj_info then
		self:notify_tips(selfId, "#{DWCJJ_140606_11}" )
		return
	end
	local need_yb,back_jcs
	local ntype = dw_config.dw_type
	if ntype == 1 then
		need_yb = cj_info.normal[1]
		back_jcs = cj_info.normal[2]
	elseif ntype == 2 then
		need_yb = cj_info.jiankang[1]
		back_jcs = cj_info.jiankang[2]
	elseif ntype == 3 then
		need_yb = cj_info.kangxing[1]
		back_jcs = cj_info.kangxing[2]
	else
		self:notify_tips(selfId, "Bảng cấu hình không có dữ liệu điêu văn này" )
		return
	end
	if self:GetYuanBao(selfId) < need_yb then
		self:notify_tips(selfId, "#{DWCJJ_140606_15}" )
		return
	end
	self:EraseItem(selfId,bag_pos)
	self:LuaFnCostYuanBao(selfId, need_yb)
	self:LuaFnAddJCSJ(selfId,38000959,back_jcs)
	local item_name = self:GetItemName(diaowen_id)
	local msg = self:ScriptGlobal_Format("#{DWCJJ_140606_18}",1,item_name)
	self:notify_tips(selfId, msg)
	self:ShowObjBuffEffect(selfId,selfId,-1,18)
end
function diaowen:CheckDiaoWenChaiJie(selfId,bag_pos)
	local diaowen_id = self:LuaFnGetItemTableIndexByIndex(selfId,bag_pos)
	if diaowen_id == -1 then
		self:notify_tips(selfId, "#{DWCJJ_140606_13}" )
		return
	end
    local dw_config = self:GetDiaoWenInfoByProduct(diaowen_id)
	if not dw_config then
		self:notify_tips(selfId, "#{DWCJJ_140606_13}" )
		return
	end
    local ori_level = dw_config.level
	local cj_info = g_DWChaiJieInfo[ori_level]
	if not cj_info then
		self:notify_tips(selfId, "#{DWCJJ_140606_11}" )
		return
	end
	local need_yb,back_jcs
	local ntype = dw_config.dw_type
	if ntype == 1 then
		need_yb = cj_info.normal[1]
		back_jcs = cj_info.normal[2]
	elseif ntype == 2 then
		need_yb = cj_info.jiankang[1]
		back_jcs = cj_info.jiankang[2]
	elseif ntype == 3 then
		need_yb = cj_info.kangxing[1]
		back_jcs = cj_info.kangxing[2]
	else
		self:notify_tips(selfId, "Bảng cấu hình không có dữ liệu điêu văn này" )
		return
	end
	self:BeginUICommand()
	self:UICommand_AddInt(bag_pos)
	self:UICommand_AddInt(need_yb)
	self:UICommand_AddInt(back_jcs)
	self:EndUICommand()
	self:DispatchUICommand(selfId, 8092720)
end

--雕纹转移
function diaowen:DoDiaowenDivert(selfId,...)
    -- CYS-EQUIPCRAFT open current quote; only Action990029 commits costs.
    local h=self.scene:get_obj_by_id(selfId)
    if h then require('cys_equipcraft').quote(self,h,6,-1,-1,-1,true) end
end
return diaowen
