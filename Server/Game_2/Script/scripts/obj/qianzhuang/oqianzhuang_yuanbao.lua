local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oqianzhuang_yuanbao = class("oqianzhuang_yuanbao", script_base)
local ScriptGlobal = require "scripts.ScriptGlobal"
oqianzhuang_yuanbao.script_id = 181000
oqianzhuang_yuanbao.g_buyrate = 5
oqianzhuang_yuanbao.g_shoptableindex = 120
oqianzhuang_yuanbao.g_zengdianshop = 121
oqianzhuang_yuanbao.g_goodact = 1
oqianzhuang_yuanbao.g_buyact = 2
oqianzhuang_yuanbao.g_ticketact = 3
oqianzhuang_yuanbao.g_zdianact = 4
oqianzhuang_yuanbao.g_gotodali = 5
oqianzhuang_yuanbao.g_normalzdianshop = 6
oqianzhuang_yuanbao.g_lv1zdianshop = 7
oqianzhuang_yuanbao.g_lv2zdianshop = 8
oqianzhuang_yuanbao.g_lv3zdianshop = 9
oqianzhuang_yuanbao.g_lv4zdianshop = 10
oqianzhuang_yuanbao.g_lv5zdianshop = 11
oqianzhuang_yuanbao.g_lv6zdianshop = 12
oqianzhuang_yuanbao.g_lv7zdianshop = 13
oqianzhuang_yuanbao.g_lv8zdianshop = 14
oqianzhuang_yuanbao.g_lv9zdianshop = 15
oqianzhuang_yuanbao.g_lv10zdianshop = 16
oqianzhuang_yuanbao.g_leave = 20
oqianzhuang_yuanbao.g_return = 21
oqianzhuang_yuanbao.g_rate = 5
oqianzhuang_yuanbao.g_shoptableindexs = {121, 122, 123, 124, 125, 126, 127}
function oqianzhuang_yuanbao:OnDefaultEvent(selfId, targetId)
    local nCurPrize = self:GetMissionData(selfId,ScriptGlobal.MD_HUIKUI_1)
	local nYuanBao =self:GetMissionData(selfId,ScriptGlobal.MD_CHANGE_POINTCOUNT)
    local tPirzeFlag = self:MathCilCompute_1_InEx(nCurPrize)
    self:BeginEvent(self.script_id)
    local strText = "    Có tiền mua tiên cũng được, tuy rằng giang hồ lấy võ lực làm trọng, nhưng có Nguyên bảo có thể khiến rất nhiều chuyện vốn khó khăn trở nên đơn giản hơn, ngài muốn làm gì nào?"
    self:AddText(strText)
	--self:AddNumText("#G零元千金豪情礼", 2, 102)
    --self:AddNumText("#{CZHL_200916_04}", 2, 101)
    --self:AddNumText("#GCDK激活", 2, 301)
    --self:AddNumText("#G畅玩武圣卡购买", 2, 302)
    --self:AddNumText("#G领取补偿礼包", 2, 303)
    --self:AddNumText("我想购买商品", 2, self.g_goodact)
    --self:AddNumText("将点数兑换成元宝", 2, self.g_buyact)
	-- if nYuanBao >= 1500000 then 
	--self:AddNumText("将元宝兑换成元宝票", 2, self.g_ticketact)
	-- end
	-- 关于一掷千金豪情礼
    -- self:AddNumText("#{CZHL_200916_02}", 11, 201)
    -- self:AddNumText("#{SMSD_100127_02}", 11, 202)
    -- self:AddNumText("元宝介绍", 11, 203)
    -- self:AddNumText("首充享豪礼", 11, 204)
    -- self:AddNumText("关于绑定元宝", 11, 205)
    -- self:AddNumText("关于点数兑换元宝", 11, 206)
    --打开乾鼎商店条件
    local Isopen = 0
    for i = 1,8 do
        if tPirzeFlag[i] == 2 then
        else
            Isopen = i
            break
        end
    end

    if Isopen == 0 then
        self:AddNumText("#{CZHL_200916_63}",7,1000)
        self:AddNumText("#{CZHL_200916_64}",11,2000)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oqianzhuang_yuanbao:OnEventRequest(selfId, targetId, arg, index)
	local nYuanBao =self:GetMissionData(selfId,ScriptGlobal.MD_CHANGE_YUANBAO)
    if index == self.g_buyact then
        if self:GetMenPai(selfId) == 9 then
            self:notify_tips(selfId,"Chỉ sau khi vào môn phái mới đổi nguyên bảo được.")
            return
        end
        local rate = self:CallScriptFunction(define.PRIZE_SCRIPT_ID, "GetYuanBaoRate", selfId)
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(rate)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 2001)
        self:CallScriptFunction(define.PRIZE_SCRIPT_ID, "AskPoint", selfId)
    elseif index == self.g_return then
        self:OnDefaultEvent(selfId, targetId)
    elseif index == self.g_goodact then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(1)
        self:UICommand_AddInt(1)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 888902)
    elseif index == self.g_ticketact then
		if nYuanBao < 1500000 then 
			return
		end
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 2002)
    elseif index == self.g_leave then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
    elseif index == 101 then
        self:CallScriptFunction(180001,"OpenTopChongZhi",selfId,targetId,101)
    elseif index == 102 then
        self:CallScriptFunction(180001,"OpenTopChongZhi",selfId,targetId,102)
    elseif index == 301 then
		self:BeginUICommand()
		self:UICommand_AddInt(targetId)
		self:UICommand_AddInt(1)
		self:EndUICommand()
		self:DispatchUICommand(selfId,20170431)
		return
    elseif index == 303 then
        local claimed = self:GetMissionData(selfId, ScriptGlobal.MD_BUCHANG_LIBAO)
        if claimed == 1 then
            self:notify_tips(selfId, "Bạn đã nhận quà bồi thường, không nhận lại được.")
            return
        end
        self:BeginAddItem()
        self:AddItem(30008117, 5, true)
        local ret = self:EndAddItem(selfId, nil, 1)
        if not ret then
            self:notify_tips(selfId, "Túi không đủ chỗ, xin dọn rồi nhận.")
            return
        end
        if not self:AddItemListToHuman(selfId, 1) then return end
        self:SetMissionData(selfId, ScriptGlobal.MD_BUCHANG_LIBAO, 1)
        self:notify_tips(selfId, "Nhận quà bồi thường thành công! Được Huyền Linh Đan x5.")
        return
    elseif index == 302 then
		-- local cururl = "https://vip.ku918.com/details/F687BAA3"
        -- self:BeginUICommand()
        -- self:UICommand_AddStr(cururl)
        -- self:EndUICommand()
        -- self:DispatchUICommand(selfId, 2023120201)
        return
    elseif index == 1000 then
            local i = os.date("%j") % (#self.g_shoptableindexs) + 1
            self:DispatchShopItem(selfId, targetId, self.g_shoptableindexs[i])
            return
    elseif index == 2000 then
        self:BeginEvent(self.script_id)
        self:AddText("#{CZHL_200916_65}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 201 then
        self:BeginEvent(self.script_id)
        self:AddText("#{CZHL_200916_03}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 202 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SMSD_100127_01}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 203 then
        self:BeginEvent(self.script_id)
        self:AddText("#{INTRO_YUANBAO}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 204 then
        self:BeginEvent(self.script_id)
        self:AddText("#{CZSBS_81218_1}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 205 then
        self:BeginEvent(self.script_id)
        self:AddText("#{BDYB_090824_01}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 206 then
        self:BeginEvent(self.script_id)
        self:AddText("#{DHYB_20090728_01}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end
function oqianzhuang_yuanbao:AskOpenDuihuanWindow22(selfId,index)
	  self:notify_tips(selfId,"2222222222222222222。")
	if index == 1 then
	--self:notify_tips(selfId,"充值临时维护预计13:00恢复")
		local ServerID = self:LuaFnGetServerID(selfId)
		
		local chongzhi_url = {
		[10] = {"https://vip.sanqnet.com/pay3/g.html?gid=17635541841247923"},
		[11] = {"https://vip.sanqnet.com/pay3/g.html?gid=17635541841247923"},
		[12] = {"https://vip.sanqnet.com/pay3/g.html?gid=17635541841247923"},
		[13] = {"https://vip.sanqnet.com/pay3/g.html?gid=17635541841247923"},
		[14] = {"https://vip.sanqnet.com/pay3/g.html?gid=17635541841247923"},
		[15] = {"https://vip.sanqnet.com/pay3/g.html?gid=17635541841247923"},
		[16] = {"https://vip.sanqnet.com/pay3/g.html?gid=17635541841247923"},
		[17] = {"https://vip.sanqnet.com/pay3/g.html?gid=17635541841247923"},
		}
		if #chongzhi_url[ServerID] < 1 then
            self:notify_tips(selfId,"Chưa mở nạp.")
            return
        end
		local selectidx = math.random(1,#chongzhi_url[ServerID])
		local cururl = chongzhi_url[ServerID][selectidx]
        self:BeginUICommand()
        self:UICommand_AddStr(cururl)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 2023120201)
        return
    end
	
end
function oqianzhuang_yuanbao:AskOpenDuihuanWindow(selfId,index)
    if index == 1 then
	--self:notify_tips(selfId,"充值临时维护预计13:00恢复")
		local ServerID = self:LuaFnGetServerID(selfId)
		
		local chongzhi_url = {
		[10] = {"https://vip.sanqnet.com/pay3/g.html?gid=17635541841247923"},
		[11] = {"https://vip.sanqnet.com/pay3/g.html?gid=17635541841247923"},
		[12] = {"https://vip.sanqnet.com/pay3/g.html?gid=17635541841247923"},
		[13] = {"https://vip.sanqnet.com/pay3/g.html?gid=17635541841247923"},
		[14] = {"https://vip.sanqnet.com/pay3/g.html?gid=17635541841247923"},
		[15] = {"https://vip.sanqnet.com/pay3/g.html?gid=17635541841247923"},
		[16] = {"https://vip.sanqnet.com/pay3/g.html?gid=17635541841247923"},
		[17] = {"https://vip.sanqnet.com/pay3/g.html?gid=17635541841247923"},
		}
		if #chongzhi_url[ServerID] < 1 then
            self:notify_tips(selfId,"Chưa mở nạp.")
            return
        end
		local selectidx = math.random(1,#chongzhi_url[ServerID])
		local cururl = chongzhi_url[ServerID][selectidx]
        self:BeginUICommand()
        self:UICommand_AddStr(cururl)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 2023120201)
        return
    end
    if index == 3 then
	--攻略

		--[[local ServerID = self:LuaFnGetServerID(selfId)
		local chongzhi_url = {
		
		}
		if #chongzhi_url[ServerID] < 1 then--]]
		local cururl = "http://124.223.68.130:91/"
        self:BeginUICommand()
        self:UICommand_AddStr(cururl)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 2023120201)
        return
    end
    if index == 2 then
        if self:GetMenPai(selfId) == 9 then
            self:notify_tips(selfId,"Chỉ sau khi vào môn phái mới đổi nguyên bảo được.")
            return
        end
        local sceneId = self:GetSceneID()
        if sceneId ~= 151 and sceneId ~= 0 and sceneId ~= 1 and sceneId ~= 71 and sceneId ~= 2 and sceneId ~= 1300 and sceneId ~= 1301 and sceneId ~= 1302 and sceneId ~= 1311 and sceneId ~= 1312 and sceneId ~= 1316 then
            self:notify_tips(selfId,"Chỉ khi ở Lạc Dương, Tô Châu, Đại Lý mới có thể đổi Nguyên bảo.")
            return
        end
        local rate = self:CallScriptFunction(define.PRIZE_SCRIPT_ID, "GetYuanBaoRate", selfId)
        self:BeginUICommand()
        self:UICommand_AddInt(define.INVAILD_ID)
        self:UICommand_AddInt(rate)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 2001)
        self:CallScriptFunction(define.PRIZE_SCRIPT_ID, "AskPoint", selfId)
    end

end

function oqianzhuang_yuanbao:BuyYuanbao(selfId, nYuanBao )
	--购买元宝
	if nYuanBao then
		if nYuanBao > 0 and nYuanBao <= 4000000 then
			self:CallScriptFunction(define.PRIZE_SCRIPT_ID, "BuyYuanBao", selfId, nYuanBao, self.g_buyrate)
		end
	end
    self:AskOpenDuihuanWindow(selfId)
end

function oqianzhuang_yuanbao:YBCost_GetPrize(...)
    return self:CallScriptFunction(180001, "YBCost_GetPrize", ...)
end

return oqianzhuang_yuanbao
