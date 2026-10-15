local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oqianzhuang_remai = class("oqianzhuang_remai", script_base)
oqianzhuang_remai.script_id = 181002
oqianzhuang_remai.g_buyrate = 0.5
oqianzhuang_remai.g_shoptableindex = 151
oqianzhuang_remai.g_goodact = 1
oqianzhuang_remai.g_YuanBaoIntro = 18
--可兑换的宝石包括#G猫眼石#W、#G虎眼石#W、#G黄晶石#W、#G蓝晶石#W、#G红晶石#W、#G绿晶石#W、
-- #G紫玉#W、#G 黄玉#W、#G 皓石#W、#G 月光石#W、#G 碧玺#W、#G 红宝石#W。
oqianzhuang_remai.change_gem = {
	--猫眼石
	{gemid = 50301001,give_num = 1,bind = true,needid = 30900077,need_count = 1 },
	{gemid = 50401001,give_num = 1,bind = true,needid = 30900130,need_count = 1 },
	{gemid = 50501001,give_num = 1,bind = true,needid = 30900131,need_count = 1 },
	{gemid = 50601001,give_num = 1,bind = true,needid = 30900132,need_count = 1 },
	{gemid = 50701001,give_num = 1,bind = true,needid = 30900133,need_count = 1 },
	--虎眼石
	{gemid = 50301002,give_num = 1,bind = true,needid = 30900077,need_count = 1 },
	{gemid = 50401002,give_num = 1,bind = true,needid = 30900130,need_count = 1 },
	{gemid = 50501002,give_num = 1,bind = true,needid = 30900131,need_count = 1 },
	{gemid = 50601002,give_num = 1,bind = true,needid = 30900132,need_count = 1 },
	{gemid = 50701002,give_num = 1,bind = true,needid = 30900133,need_count = 1 },
	--黄晶石
	{gemid = 50302001,give_num = 1,bind = true,needid = 30900077,need_count = 1 },
	{gemid = 50402001,give_num = 1,bind = true,needid = 30900130,need_count = 1 },
	{gemid = 50502001,give_num = 1,bind = true,needid = 30900131,need_count = 1 },
	{gemid = 50602001,give_num = 1,bind = true,needid = 30900132,need_count = 1 },
	{gemid = 50702001,give_num = 1,bind = true,needid = 30900133,need_count = 1 },
	--蓝晶石
	{gemid = 50302002,give_num = 1,bind = true,needid = 30900077,need_count = 1 },
	{gemid = 50402002,give_num = 1,bind = true,needid = 30900130,need_count = 1 },
	{gemid = 50502002,give_num = 1,bind = true,needid = 30900131,need_count = 1 },
	{gemid = 50602002,give_num = 1,bind = true,needid = 30900132,need_count = 1 },
	{gemid = 50702002,give_num = 1,bind = true,needid = 30900133,need_count = 1 },
	--红晶石
	{gemid = 50302003,give_num = 1,bind = true,needid = 30900077,need_count = 1 },
	{gemid = 50402003,give_num = 1,bind = true,needid = 30900130,need_count = 1 },
	{gemid = 50502003,give_num = 1,bind = true,needid = 30900131,need_count = 1 },
	{gemid = 50602003,give_num = 1,bind = true,needid = 30900132,need_count = 1 },
	{gemid = 50702003,give_num = 1,bind = true,needid = 30900133,need_count = 1 },
	--绿晶石
	{gemid = 50302004,give_num = 1,bind = true,needid = 30900077,need_count = 1 },
	{gemid = 50402004,give_num = 1,bind = true,needid = 30900130,need_count = 1 },
	{gemid = 50502004,give_num = 1,bind = true,needid = 30900131,need_count = 1 },
	{gemid = 50602004,give_num = 1,bind = true,needid = 30900132,need_count = 1 },
	{gemid = 50702004,give_num = 1,bind = true,needid = 30900133,need_count = 1 },
	--紫玉
	{gemid = 50303001,give_num = 1,bind = true,needid = 30900077,need_count = 1 },
	{gemid = 50403001,give_num = 1,bind = true,needid = 30900130,need_count = 1 },
	{gemid = 50503001,give_num = 1,bind = true,needid = 30900131,need_count = 1 },
	{gemid = 50603001,give_num = 1,bind = true,needid = 30900132,need_count = 1 },
	{gemid = 50703001,give_num = 1,bind = true,needid = 30900133,need_count = 1 },
	--黄玉
	{gemid = 50312001,give_num = 1,bind = true,needid = 30900077,need_count = 1 },
	{gemid = 50412001,give_num = 1,bind = true,needid = 30900130,need_count = 1 },
	{gemid = 50512001,give_num = 1,bind = true,needid = 30900131,need_count = 1 },
	{gemid = 50612001,give_num = 1,bind = true,needid = 30900132,need_count = 1 },
	{gemid = 50712001,give_num = 1,bind = true,needid = 30900133,need_count = 1 },
	--皓石
	{gemid = 50312002,give_num = 1,bind = true,needid = 30900077,need_count = 1 },
	{gemid = 50412002,give_num = 1,bind = true,needid = 30900130,need_count = 1 },
	{gemid = 50512002,give_num = 1,bind = true,needid = 30900131,need_count = 1 },
	{gemid = 50612002,give_num = 1,bind = true,needid = 30900132,need_count = 1 },
	{gemid = 50712002,give_num = 1,bind = true,needid = 30900133,need_count = 1 },
	--月光石
	{gemid = 50312003,give_num = 1,bind = true,needid = 30900077,need_count = 1 },
	{gemid = 50412003,give_num = 1,bind = true,needid = 30900130,need_count = 1 },
	{gemid = 50512003,give_num = 1,bind = true,needid = 30900131,need_count = 1 },
	{gemid = 50612003,give_num = 1,bind = true,needid = 30900132,need_count = 1 },
	{gemid = 50712003,give_num = 1,bind = true,needid = 30900133,need_count = 1 },
	--碧玺
	{gemid = 50312004,give_num = 1,bind = true,needid = 30900077,need_count = 1 },
	{gemid = 50412004,give_num = 1,bind = true,needid = 30900130,need_count = 1 },
	{gemid = 50512004,give_num = 1,bind = true,needid = 30900131,need_count = 1 },
	{gemid = 50612004,give_num = 1,bind = true,needid = 30900132,need_count = 1 },
	{gemid = 50712004,give_num = 1,bind = true,needid = 30900133,need_count = 1 },
	--红宝石
	{gemid = 50313004,give_num = 1,bind = true,needid = 30900077,need_count = 1 },
	{gemid = 50413004,give_num = 1,bind = true,needid = 30900130,need_count = 1 },
	{gemid = 50513004,give_num = 1,bind = true,needid = 30900131,need_count = 1 },
	{gemid = 50613004,give_num = 1,bind = true,needid = 30900132,need_count = 1 },
	{gemid = 50713004,give_num = 1,bind = true,needid = 30900133,need_count = 1 },
}
function oqianzhuang_remai:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local strText = "    Mau đến xem thử đi, hàng hóa bán chạy nhất toàn thành, giá cả rẻ nhất, khách quan ngài mau chọn vài món đi, tuyệt đối đáng giá, đảm bảo ngài mua về sau đêm nay nằm mơ cũng sẽ cười đó nha ~"
    self:AddText(strText)
    self:AddNumText("#GĐổi bảo thạch", 6, 100)
    self:AddNumText("Mua hàng hóa bán chạy", 7, self.g_goodact)
    self:AddNumText("Nguyên bảotửu quán", 11, self.g_YuanBaoIntro)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oqianzhuang_remai:OnEventRequest(selfId, targetId, arg, index)
    if index == self.g_goodact then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(1)
        self:UICommand_AddInt(2)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 888902)
	elseif index == 0 then
		self:OnDefaultEvent(selfId, targetId)
    elseif index == self.g_YuanBaoIntro then
        self:BeginEvent(self.script_id)
        self:AddText("#{INTRO_YUANBAO}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
	elseif index >= 100 and index <= 109 then
		local page = index - 100
		local maxpage = #self.change_gem // 9
		if maxpage > 9 then
			maxpage = 9
		end
		local min_idx = page * 9 + 1
		local max_idx = min_idx + 8
		local index_msg,gem
		local select_idx = 0
        self:BeginEvent(self.script_id)
        self:AddText("    Xin chọn bảo thạch muốn đổi:")
		if page > 0 then
			self:AddNumText("#BTrang trước", 6, index - 1)
		end
		for i = min_idx,max_idx do
			select_idx = select_idx + 1
			gem = self.change_gem[i]
			if gem then
				index_msg = string.format("#WĐổi#G%d#Wcái#G%s",gem.give_num,self:GetItemName(gem.gemid))
				self:AddNumText(index_msg, 6, 100 + select_idx * 10 + page)
			else
				break
			end
		end
		if page < maxpage then
			self:AddNumText("#BTrang sau", 6, index + 1)
		end
		self:AddNumText("Về trang đạo cụ", 11, 0)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
	elseif index >= 110 and index <= 199 then
		index = index - 100
		local page = index % 10
		local select_idx = index // 10
		local check_index = select_idx + page * 9
		local gem = self.change_gem[check_index]
		if gem then
			local idx_msg
			local show_index = false
			if self:LuaFnGetAvailableItemCount(selfId,gem.needid) >= gem.need_count then
				idx_msg = string.format("#W    Đổi#G%d#Wcái#G%s#Wcần#G%d#Wcái#G%s#W, xin xác nhận!",
				gem.give_num,self:GetItemName(gem.gemid),
				gem.need_count,self:GetItemName(gem.needid)
				)
				show_index = true
			else
				idx_msg = string.format("#W    Đổi#G%d#Wcái#G%s#Wcần#cff0000%d#Wcái#cff0000%s#W, nguyên liệu#cff0000không đủ#W, không đổi được.",
				gem.give_num,self:GetItemName(gem.gemid),
				gem.need_count,self:GetItemName(gem.needid)
				)
			
			
			end
			self:BeginEvent(self.script_id)
			self:AddText(idx_msg)
			if show_index then
				self:AddNumText("Đúng, ta muốn đổi", 6, 200 + select_idx * 10 + page)
			end
			self:AddNumText("Về chọn bảo thạch", 11, 100 + page)
			self:AddNumText("Về trang đạo cụ", 11, 0)
			self:EndEvent()
			self:DispatchEventList(selfId, targetId)
		end
	elseif index >= 210 and index <= 299 then
		index = index - 200
		local page = index % 10
		local select_idx = index // 10
		local check_index = select_idx + page * 9
		local gem = self.change_gem[check_index]
		if gem then
			if self:LuaFnGetAvailableItemCount(selfId,gem.needid) >= gem.need_count then
				self:BeginAddItem()
				self:AddItem(gem.gemid,gem.give_num,gem.bind);
				if not self:EndAddItem(selfId,true) then
					return
				end
				self:LuaFnDelAvailableItem(selfId,gem.needid,gem.need_count)
				self:TryRecieveItemWithCount(selfId,gem.gemid,gem.give_num,gem.bind)
				self:GiveItemTip(selfId,gem.gemid,gem.give_num,18)
			else
				self:BeginEvent(self.script_id)
				self:AddText("Đổi thất bại, thiếu nguyên liệu.")
				self:AddNumText("Về chọn bảo thạch", 11, 100 + page)
				self:AddNumText("Về trang đạo cụ", 11, 0)
				self:EndEvent()
				self:DispatchEventList(selfId, targetId)
			end
		end
    end
end

function oqianzhuang_remai:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
end

function oqianzhuang_remai:NewDispatchShopItem(selfId, targetId, shopId)
    -- if targetId >= 0 then
        -- self:DispatchShopItem(selfId, targetId, shopId)
    -- else
        -- self:DispatchNoNpcShopItem(selfId, shopId)
    -- end
end

function oqianzhuang_remai:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            end
            return
        end
    end
end

function oqianzhuang_remai:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oqianzhuang_remai:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

return oqianzhuang_remai
