--NPC
--
--脚本号
local gbk = require "wire_charset"
local class = require "class"
local script_base = require "script_base"
local oluoyang_lifan = class("oluoyang_lifan", script_base)
local g_Stone = 20310020      --玄昊玉
local g_BindStone = 20310021  --绑定玄昊玉
local g_CountLimit = 50
local g_MeiHuaBiao = 10155003  --梅花镖
local g_MeiHuaBiaoBound = 10155005  --绑定梅花镖[tx45022]
oluoyang_lifan.g_eventList = {1018707,1018708,500604,500607}

--内测道具领取配置
oluoyang_lifan.neice_info =
{
	{listname = "#GNhóm loại khác",
	 item = {
			 {30900057,1},			--一次1个  
			 {30900058,1},			--一次1个  
			 {20600003,20},			--一次20个 
			 {30505817,5},	 
			 {38008177,5},	 
			 
			 {10155002,1},			--一次1个 
			 {38008160,250},			--一次1个 
			 {38002499,250},			--一次20个 
			 {38002397,500},			--一次20个 
			 
			},
	},
	{listname = "#GLoại chế trang bị",
	 item = {
			 {20501004,100},			--一次100个
			 {20502004,100},			--一次100个
			 {38003055,100},			--一次100个
			 
			},
	},
	
	{listname = "#GLoại Điêu văn",
	 item = {
			 {20502009,50},			--一次50个
			 {30700232,50},			--一个50个
			 {30503118,50},			-- 一次50个
	 
			 {30120145,1},			-- 一次1个 
			 {30120066,1},			-- 一次1个 
			 {30120067,1},			--一次1个 
			 {30120068,1},			--一次1个 
			 {30120069,1},			--一次1个 
			 {30120050,1},			--一次1个 
			 {30120042,1},			-- 一次1个 
			 {30120041,1},			--一次1个 
			 {30120035,1},			-- 一次1个 
			 {30120036,1},			--一次1个 
			 {30120037,1},			--一次1个 
			 {30120038,1},			--一次1个 
			 {30120028,1},			--一次1个 
			 {30120014,1},			--一次1个 
			 {30120015,1},			--一次1个 
			 {30120016,1},			--一次1个 
			 {30120017,1},			--一次1个 
			 {30120010,1},			--一次1个 
			 {30120008,1},			--一次1个 
			 
			},
	},
	{listname = "#GLoại khắc điêu văn",
	 item = {
			 {38003158,10},			--一次50个
			 {30900200,1},			-- 一次1个 
			 {30900201,1},			-- 一次1个 
			 {30900202,1},			-- 一次1个 
			 {30900203,1},			-- 一次1个 
			 {30900204,1},			--一次1个 
			 {30900205,1},			--一次1个 
			 {30900206,1},			--一次1个 
			 {30900207,1},			--一次1个 
			 {30900208,1},			-- 一次1个 
			 {30900209,1},			--一次1个 
			 {30900210,1},			-- 一次1个 
			 {30900211,1},			--一次1个 
			 {30900212,1},			--一次1个 
			 {30900213,1},			--一次1个 			 
			},
	},
	{listname = "#GLoại Võ Hồn",
	 item = {
			 {10156001,1},			--     一次1个
			 {10156002,1},			--     一次1个
			 {30700226,1},			--     一次1个
			 {30700227,1},			--     一次1个
			 {30700228,1},			--    一个1个
			 {30700229,1},			--   一次1个
			 {30700222,1},			--   一次1个
			 {30700223,1},			--  一次1个
			 {30700224,1},			-- 一次1个
			 {30700225,1},			-- 一次1个
			 {30700218,1},			-- 一次1个
			 {30700219,1},			-- 一次1个
			 {30700220,1},			-- 一次1个
			 {30700221,1},			-- 一次1个
	 
			 {20800010,250},			--  一次250个
			 {20800008,250},			--  一次250个
			 {20800004,250},			--  一次250个
			 {20800006,250},			-- 一次250个
			 {20800002,250},			--一次250个
			 {20800000,250},			-- 一次250个
	 
			},
	},
	{listname = "#GLoại Thất Tình",
	 item = {
			 {20900001,250},			--  一次250个
			 {38002900,250},			--  一次250个
			 {38002901,250},			--  一次250个 
			 {38002969,250},			--  一次250个 
			 {38002970,250},			--  一次250个 
			 {38002971,250},			--  一次250个 
			 {38002902,1},			-- 一次250个
			 {38002903,1},			--一次250个
			 {38002904,1},			-- 一次250个
			 {38002905,1},			-- 一次250个
			 {38002906,1},			--一次250个
			 {38002907,1},			-- 一次250个
			 {38002908,1},			-- 一次250个
			 {38002909,1},			--一次250个
			 {38002910,1},			-- 一次250个
			 {38002911,1},			-- 一次250个
			 {38002912,1},			--一次250个
			 {38002913,1},			-- 一次250个		
			 {38002914,1},			-- 一次250个
			 {38002915,1},			--一次250个
			 {38002916,1},			-- 一次250个	
			 {38002917,1},			-- 一次250个
			 {38002918,1},			--一次250个
			 {38002919,1},			-- 一次250个				 
			},
	},
	
	
}


function oluoyang_lifan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
        self:AddText("  Giang hồ vốn là nơi thị phi, lắm kẻ cậy hung làm bậy của võ lâm bại hoại, muốn thiên hạ thái bình, phải nhờ vào các vị hiệp sĩ.")
		self:AddNumText("#{AQFC_090115_14}", 6, 2)
		if self:GetHumanGameFlag(selfId,"zhu_bo_flag") == 666 then
			self:AddNumText("#GNhận đạo cụ", 6, 3000)
			self:AddNumText("Tới - Tây Hồ", 6, 3001)
			self:AddNumText("Tới - Thánh Thú Sơn", 6, 3002)
		end
		self:AddNumText("#{AQFC_090115_13}",11, 3)
		for i, eventId in pairs(self.g_eventList) do
			self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
		end
    self:EndEvent()
    self:DispatchEventList(selfId,targetId)
end

function oluoyang_lifan:DoExchange(selfId, targetId)
	local count = self:LuaFnGetAvailableItemCount(selfId, g_Stone)
	local bindCount = self:LuaFnGetAvailableItemCount(selfId, g_BindStone)
	if count + bindCount < g_CountLimit then
		self:notify_tips(selfId, "#{LLFB_80821_5}")
		self:CloseWindow(selfId,targetId)
		return
	end
    -- 检查背包空间
	if self:LuaFnGetPropertyBagSpace(selfId ) < 1 then
        self:notify_tips(selfId,"#{AQFC_090115_07}")
		return
	end
	local nItemBagIndexStone
	local szTransferStone
	--优先扣除绑定的玄昊玉
	local bDelOk
	if bindCount >= g_CountLimit then
		nItemBagIndexStone = self:GetBagPosByItemSn(selfId, g_BindStone)
		szTransferStone = self:GetBagItemTransfer(selfId, nItemBagIndexStone)
		bDelOk = self:LuaFnDelAvailableItem(selfId, g_BindStone, g_CountLimit)
		if not bDelOk then
            self:notify_tips(selfId, "#{JPZB_0610_12}")
		    return
	    end
	else
		nItemBagIndexStone = self:GetBagPosByItemSn(selfId, g_Stone)
		szTransferStone = self:GetBagItemTransfer(selfId, nItemBagIndexStone)
		if bindCount > 0 then
			bDelOk = self:LuaFnDelAvailableItem(selfId, g_BindStone, bindCount)
			if not bDelOk    then
                self:notify_tips(selfId, "#{JPZB_0610_12}")
		        return
	        end
		end
		bDelOk = self:LuaFnDelAvailableItem(selfId, g_Stone, g_CountLimit - bindCount)
		if not bDelOk then
            self:notify_tips(selfId, "#{JPZB_0610_12}")
	        return
        end
	end
	--获取暗器[tx44913]
	local nBagIndex
	if bindCount > 0 then
		nBagIndex = self:TryRecieveItem(selfId, g_MeiHuaBiaoBound, 1)
	else
		nBagIndex = self:TryRecieveItem(selfId, g_MeiHuaBiao, 1 )
	end
	local szTransferEquip = self:GetBagItemTransfer(selfId, nBagIndex)
	--获取暗器[/tx44913]
	self:notify_tips(selfId, "#{AQFC_090115_08}")
	--特效
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
    --公告
    local name = self:LuaFnGetName(selfId)
    name = gbk.fromutf8(name)
    local message = string.format("#{AQ_04}#{_INFOUSR%s}#{AQ_01}#{_INFOMSG%s}#{AQ_02}#{_INFOMSG%s}#{AQ_03}", name, szTransferStone, szTransferEquip)
	self:BroadMsgByChatPipe(selfId, message, 4)
	self:CloseWindow(selfId,targetId)
end

function oluoyang_lifan:CloseWindow(selfId,targetId)
	self:BeginUICommand()
		self:UICommand_AddInt(targetId )
	self:EndUICommand()
	self:DispatchUICommand(selfId, 1000 )
end

function oluoyang_lifan:OnEventRequest(selfId, targetId, arg, index)
	if index == 0 then
		self:OnDefaultEvent(selfId, targetId)
		return
	end
	if index >= 2000 and index <= 3002 then
		if self:GetHumanGameFlag(selfId,"zhu_bo_flag") ~= 666 then
			return
		end
		if index == 3000 then
			local neice_info = self.neice_info
			if neice_info then
				local maxlist = #neice_info
				if maxlist == 0 then
					self:BeginEvent(self.script_id)
					self:AddText("    Giang hồ Bách Hiểu Sinh: chưa có cấu hình thưởng.")
					self:AddNumText("Làm phiền rồi..",11,0)
					self:EndEvent()
					self:DispatchEventList(selfId, targetId)
					return
				elseif maxlist > 9 then
					maxlist = 9
				end
				self:BeginEvent(self.script_id)
				self:AddText("    Giang hồ Bách Hiểu Sinh: xin chọn thưởng phân loại dưới.")
				for i = 1,maxlist do
					self:AddNumText(neice_info[i].listname,6,2000 + i * 100 + 10)
				end
				self:EndEvent()
				self:DispatchEventList(selfId, targetId)
			end
		elseif index > 3000 then
			--377是西湖 394圣兽山
			local tbl = {
				[1] = {sceneId = 377,posx = 111,posz = 111,level = 1},
				[2] = {sceneId = 394,posx = 111,posz = 111,level = 1},
			
			}
			index = index - 3000
			if tbl[index] then
				self:CallScriptFunction((400900), "TransferFunc", selfId, tbl[index].sceneId, tbl[index].posx, tbl[index].posz, tbl[index].level)
			end
		else
			local neice_info = self.neice_info
			if neice_info then
				local newindex = index % 1000
				local lx_index = newindex // 100
				newindex = newindex % 100
				local page_index = newindex // 10
				local item_index = newindex % 10
			-- self:notify_tips(selfId,"lx_index"..(lx_index))
			-- self:notify_tips(selfId,"page_index"..(page_index))
			-- self:notify_tips(selfId,"item_index"..(item_index))
				local haveaward = neice_info[lx_index]
				if not haveaward then
					self:BeginEvent(self.script_id)
					self:AddText("    Giang hồ Bách Hiểu Sinh: không có phân loại này >> "..tostring(lx_index))
					self:AddNumText("Về phân loại",11,3000)
					self:AddNumText("Về trang đạo cụ",11,0)
					self:EndEvent()
					self:DispatchEventList(selfId, targetId)
					return
				end
				local itemaward = haveaward.item
				if not itemaward or #itemaward < 1 then
					self:BeginEvent(self.script_id)
					self:AddText("    Giang hồ Bách Hiểu Sinh:["..tostring(haveaward.listname).."]chưa cấu hình thưởng.")
					self:AddNumText("Về phân loại",11,3000)
					self:AddNumText("Về trang đạo cụ",11,0)
					self:EndEvent()
					self:DispatchEventList(selfId, targetId)
					return
				end
				if item_index == 0 then
					local itemname
					local headindex = 2000
					local uppage_index = page_index - 1
					local downpage_index = page_index + 1
					local item_over = page_index * 9
					local item_statr = item_over - 8
					local maxpage = math.ceil(#itemaward / 9)
					if maxpage > 9 then
						maxpage = 9
					end
					newindex = headindex + lx_index * 100 + page_index * 10
					local idx = 0
					self:BeginEvent(self.script_id)
					self:AddText("    Giang hồ Bách Hiểu Sinh: xin chọn ["..haveaward.listname.."]#WThưởng:")
					if uppage_index > 0 then
						self:AddNumText("#b#PTrang trước",6,headindex + lx_index * 100 + uppage_index * 10)
					end
					for i = item_statr,item_over do
						idx = idx + 1
						if i <= #itemaward then
							if itemaward[i] then
								itemname = self:GetItemName(itemaward[i][1])
								if itemname ~= -1 then
									self:AddNumText("#B"..itemname.."#W * #B"..tostring(itemaward[i][2]),6,newindex + idx)
								end
							end
						end
					end
					if downpage_index > 1 and downpage_index <= maxpage then
						self:AddNumText("#b#PTrang sau",6,headindex + lx_index * 100 + downpage_index * 10)
					end
					self:AddNumText("Về phân loại",11,3000)
					self:AddNumText("Về trang đạo cụ",11,0)
					self:EndEvent()
					self:DispatchEventList(selfId, targetId)
				else
					item_index = item_index + page_index * 9 - 9
					if not itemaward[item_index] then
						self:BeginEvent(self.script_id)
						self:AddText("    Giang hồ Bách Hiểu Sinh:["..tostring(haveaward.listname).."] >> "..tostring(item_index))
						self:AddNumText("Về phân loại",11,3000)
						self:AddNumText("Về trang đạo cụ",11,0)
						self:EndEvent()
						self:DispatchEventList(selfId, targetId)
						return
					end
					local id,num = itemaward[item_index][1],itemaward[item_index][2]
					if id == 30900058 or id == 30900059 then
						self:BeginAddItem()
						self:AddItem(id,num,true)
						if not self:EndAddItem(selfId,true) then
							return
						end
						for i = 1,num do
							local newpos = self:TryRecieveItem(selfId,id,true)
							if newpos ~= -1 then
								self:SetBagItemParam(selfId, newpos, 4, 30000000, "int", true)
							end
						end
					else
						self:BeginAddItem()
						self:AddItem(id,num,true)
						if not self:EndAddItem(selfId) then
							return
						end
						self:AddItemListToHuman(selfId)
					end
					self:notify_tips(selfId,"Nhận thành công"..self:GetItemName(id)..tostring(num).."cái.")
				end
			end
		end
		return
	end
    if index == 2 then
        self:BeginEvent(self.script_id)
            self:AddText("#{AQFC_090115_06}")
            self:AddNumText("#{INTERFACE_XML_557}", 6, 4)
            self:AddNumText("#{Agreement_Info_No}", 8, 5)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 4 then
        self:DoExchange(selfId, targetId)
        return
    end
    if index == 5 then
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId,arg,index)
            return
        end
    end
end
function oluoyang_lifan:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept",selfId, targetId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId,targetId, missionScriptId)
            end
            return
        end
    end
end

function oluoyang_lifan:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:OnDefaultEvent(selfId, targetId)
            return
        end
    end
end

function oluoyang_lifan:OnMissionContinue(selfId, targetId,
                                                missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,targetId)
            return
        end
    end
end

function oluoyang_lifan:OnMissionSubmit(selfId, targetId, missionScriptId,selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,targetId, selectRadioId)
            return
        end
    end
end

function oluoyang_lifan:OnDie(selfId, killerId) end

return oluoyang_lifan