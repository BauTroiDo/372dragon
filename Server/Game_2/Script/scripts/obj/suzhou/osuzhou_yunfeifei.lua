--苏州NPC
--云霏霏
--一般
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_yunfeifei = class("osuzhou_yunfeifei", script_base)
osuzhou_yunfeifei.g_shoptableindex = 27
local g_eventList	= { 800103, 800104 , 800106, 800101, 800102, 800108}
local g_key				= {}
g_key["buy"]= 0		--购买珍兽用品
g_key["ask"]= 1		--查询珍兽成长率
g_key["rep"]= 2		--确认查询
g_key["i_pc"]= 5		--发布征友信息 必需=5
g_key["ask_pc"]= 6		--征友 必需=6
g_key["ask_prcr"]= 7		--查询繁殖的珍兽
g_key["pet_help"]= 10		--珍兽相关介绍
g_key["pet_help_savvy"]= 11		--提升珍兽悟性介绍
g_key["pet_help_prcr"]= 12		--珍兽繁殖介绍

function osuzhou_yunfeifei:OnDefaultEvent(selfId, targetId)
	self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_suzhou_0019}" )
    self:AddNumText("Tra cứu Tỉ lệ trưởng thành Trân thú", 6, g_key["ask"] )
    self:AddNumText("Trân thú sinh sản",6,6080)
    self:AddNumText("Lấy ra hoàn thành việc gây giống của Trân thú",6,6081)
    self:AddNumText("Tra cứu sinh sản của Trân thú",6,6082)

    self:CallScriptFunction(800106, "OnEnumerate", self, selfId, targetId)
    self:AddNumText("Mua vật phẩm Trân thú", 7, g_key["buy"] )
    self:AddNumText("Trân thú liên quan tửu quán", 11, g_key["pet_help"] )
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_yunfeifei:OnEventRequest(selfId, targetId, event_id, index)
    print("osuzhou_yunfeifei:OnEventRequest", selfId, targetId, event_id, index)
    if event_id == self.script_id then
        local key	= index
        if key == g_key["pet_help"] then
            self:BeginEvent(targetId)
            self:AddNumText("Nâng cao ngộ tính Trân thú ở tửu quán", 11, g_key["pet_help_savvy"] )
            self:AddNumText("Trân thú sinh sản tửu quán",11,g_key["pet_help_prcr"]);
            self:EndEvent()
            self:DispatchEventList(selfId,targetId)
            return
        elseif key == g_key["pet_help_savvy"] then
            self:BeginEvent(targetId)
            self:AddText("#{function_help_059}" )
            self:EndEvent()
            self:DispatchEventList(selfId,targetId)
            return
        elseif key == 6080 or key == 6081 or key == 6082 then
            self:BeginUICommand()
            self:UICommand_AddInt(targetId)
            self:EndUICommand()
            self:DispatchUICommand(selfId, 20091025)
        elseif key == g_key["pet_help_prcr"] then
            self:BeginEvent(targetId)
            self:AddText("#{function_help_057}#r")
            self:EndEvent()
            self:DispatchEventList(selfId,targetId)
            return
        --购买珍兽用品
        elseif key == g_key["buy"] then
            self:DispatchShopItem(selfId,targetId, self.g_shoptableindex)
        --查询珍兽成长率
        elseif key == g_key["ask"] then
            self:OnConfirm(selfId, targetId )
        elseif key == g_key["ask_prcr"] then
            self:LuaFnGetPetProcreateInfo(selfId)
        end
    else
        for _, findId in ipairs(g_eventList)  do
			if event_id == findId then
				self:CallScriptFunction(event_id, "OnDefaultEvent", selfId, targetId )
				return
			end
		end
    end
end

function osuzhou_yunfeifei:OnConfirm(selfId, targetId)
	self:BeginUICommand()
    self:UICommand_AddInt(targetId)
    self:UICommand_AddInt(6)				--珍兽查询分支
	self:EndUICommand()
	self:DispatchUICommand(selfId, 3)	--调用珍兽界面
end

function osuzhou_yunfeifei:OnInquiryForGrowRate(selfId, petHid, petLid )
    if self:LuaFnIsPetGrowRateByGUID(selfId, petHid, petLid) then
        self:notify_tips(selfId, "Trân Thú này đã tra cứu tỷ lệ trưởng thành rồi." )
        return
    end
    local PlayerMoney = self:GetMoney(selfId ) + self:GetMoneyJZ(selfId)  --交子普及 Vega
    if PlayerMoney < 100 then
        self:notify_tips(selfId, "  Xin lỗi, kim tiền trên người ngài không đủ #{_EXCHG100}!" )
        return 0
    end
    local lev = self:LuaFnGetPetLevelByGUID(selfId, petHid, petLid )
    if lev < 1 then -- zchw 
        self:notify_tips(selfId, "  Xin lỗi, chỉ có thể tra cứu tỷ lệ trưởng thành của Trân thú cấp 10 trở lên!" )
        return 0
    end
    --扣除金钱
    local _, costJ , costM = self:LuaFnCostMoneyWithPriority(selfId, 100)		--交子普及 Vega
    if costM ~= nil and costJ ~= nil then
        if costJ > 0 then
            local str = string.format("Ngươi đã tiêu tốn #{_EXCHG%d}",costJ ) 
            self:Msg2Player(selfId, str, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA )
        end
        if costM > 0 then
            local str = string.format("Ngươi đã tiêu tốn #{_MONEY%d}",costM ) 
            self:Msg2Player(selfId, str, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA )
        end
        self:Msg2Player(selfId, "Dùng để tra cứu tỷ lệ trưởng thành của Trân thú.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA )
    else
        return
    end
    local	nGrowLevel	= self:LuaFnGetPetGrowRateLevelByGUID(selfId, petHid, petLid )
    local	strTbl			= { "Thường", "Ưu tú", "Kiệt xuất", "Xuất sắc", "Hoàn mỹ" }
    if( nGrowLevel < 1 or nGrowLevel > #strTbl) then
        nGrowLevel				= 1
    end
    local	strLevel		= strTbl[nGrowLevel]    
    --将获取数据传给Client
    self:BeginUICommand()
    self:UICommand_AddStr("key="..1 )						--关键字，1表示成功执行
    self:UICommand_AddStr("rat="..nGrowLevel )	--成长率
    self:UICommand_AddStr("gld="..100 )					--花费金钱
    self:EndUICommand()
    self:DispatchUICommand(selfId, 4 )    
    --当查询的珍兽为宝宝、变异，并且成长率查询结果是3、4或5时，发布世界公告
    local	rnd			= math.random( 4 )
    local	msg			= {}
    --local	typ			= self:LuaFnGetPetTypeByGUID(selfId, petHid, petLid )
    return 1
end

return osuzhou_yunfeifei