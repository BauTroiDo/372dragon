local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_zhufugui = class("odali_zhufugui", script_base)
odali_zhufugui.script_id = 002102


function odali_zhufugui:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    --self:AddText("#{GZGZ_120514_03}")
	self:AddNumText("#GNhận đạo cụ hằng ngày (thẻ lương)", 2, 971)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_zhufugui:OnEventRequest(selfId, targetId, arg, index)
    if index == 971 then
       	--ScriptGlobal.MDEX_GONGZIKA = 231 --工资卡今日使用情况
		--ScriptGlobal.MDEX_GONGZIKAFLAG = 232 --工资卡今日领取情况
		if self:GetMissionDataEx(selfId,713) < 1 then
			self:notify_tips(selfId, "Hôm nay bạn chưa dùng thẻ lương, không nhận thưởng ở đây được.")
			return
        end

		
		local GongZiTime = self:GetMissionDataEx(selfId,715)
		local NewTime = self:GetTime2Day()
		local ret = self:LuaFnHaveImpactOfSpecificDataIndex(selfId, 159)
		
		if GongZiTime == tonumber(NewTime) then
			if ret then
				self:notify_tips(selfId, "Online chưa đủ 5 giờ, không nhận thưởng được.")
				return
			end
		else
			self:CallScriptFunction(define.UPDATE_CLIENT_ICON_SRIPTID, "GetNewDayRestData", selfId,on_line)
			self:notify_tips(selfId, "Online chưa đủ 5 giờ, không nhận thưởng được.")
			return
		end
        if self:GetMissionDataEx(selfId,714) > 0 then
			self:notify_tips(selfId, "Bạn đã nhận thưởng này rồi.")
			return
        end
		--检测背包够不够
        self:BeginAddItem()
		self:AddItem(30008130,1,true)	-- 玄灵丹  
		self:AddItem(30505550,1,true)	-- 圣诞果  
		self:AddItem(20501003,20,true)  -- 3级棉布    
		self:AddItem(20502003,20,true)  -- 3级秘银     
		if not self:EndAddItem(selfId) then
            self:notify_tips(selfId, "Túi đồ không đủ chỗ trống.")
            return
        end
        self:AddItemListToHuman(selfId)
		self:AddBindYuanBao(selfId,200000)
		self:SetMissionDataEx(selfId, 714, 1)
		self:notify_tips(selfId, "Nhận đạo cụ hằng ngày thành công, xem túi.")
    end
end

function odali_zhufugui:AddSalary(selfId, nIndex, nType)
end

function odali_zhufugui:PayLastSlay_Auto(selfId)
end

function odali_zhufugui:PayLastSlay_NPC(selfId)
end

function odali_zhufugui:OpenSalaryLayout(selfId)
end

function odali_zhufugui:PayLastSlay(selfId, nSLevel, SalyData, nYuanBao)
end

function odali_zhufugui:GetHongLiData(selfId)
end

function odali_zhufugui:SaveHongLiData(selfId, Time, nSLevel, SalyData, nYuanBao)
end

function odali_zhufugui:CreateDataBase(selfId)
end

function odali_zhufugui:Notify(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchEventList(selfId)
end

function odali_zhufugui:NotifyTip(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return odali_zhufugui
