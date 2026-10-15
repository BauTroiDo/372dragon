--无崖子

local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_wuyazi = class("odali_wuyazi", script_base)
function odali_wuyazi:OnDefaultEvent(selfId, targetId)
	self:BeginEvent(self.script_id)
    self:AddText("#{WH_090729_03}")
    self:AddNumText("Nâng cao Cấp độ hợp thành Võ Hồn",6,1)
    self:AddNumText("Võ Hồn khai mở cột Thuộc tính",6,2)
    self:AddNumText("Võ Hồn mở rộng thuộc tính học tập",6,3)
    self:AddNumText("Võ Hồn mở rộng Thuộc tính Thăng cấp",6,4)
    self:AddNumText("Võ Hồn lĩnh ngộ Kỹ năng",6,5)
    self:AddNumText("Tẩy lại Võ Hồn Kỹ năng",6,6)
    self:AddNumText("Võ Hồn Kỹ năng Thăng cấp",6,7)
    self:AddNumText("Võ Hồn tương quantửu quán",11,8)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_wuyazi:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
		self:BeginUICommand()
			self:UICommand_AddInt(targetId);
			self:UICommand_AddInt(2)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 20090721)
	elseif index == 2 then 
	    self:BeginUICommand()
			self:UICommand_AddInt(targetId);
			self:UICommand_AddInt(4)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 20090721)
	elseif index == 3 then 
		self:BeginUICommand()
			self:UICommand_AddInt(targetId);
			self:UICommand_AddInt(1)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 20090721)
	elseif index == 4 then
		self:BeginUICommand()
			self:UICommand_AddInt(targetId);
			self:UICommand_AddInt(1)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 20090720 )
	elseif index == 5 then
		self:BeginUICommand()
		    self:UICommand_AddInt(targetId)
	        self:UICommand_AddInt(1)
        self:EndUICommand()
        self:DispatchUICommand(selfId,20090722)
	elseif index == 6 then
		self:BeginUICommand()
		    self:UICommand_AddInt(targetId)
	        self:UICommand_AddInt(2)
        self:EndUICommand()
        self:DispatchUICommand(selfId,20090722)
	elseif index == 7 then
		self:BeginUICommand()
		    self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId,20090723)
	elseif index == 8 then
		self:BeginEvent(self.script_id)
			self:AddNumText("Giới thiệu bối cảnh Võ Hồn",11,9)
			self:AddNumText("Làm thế nào để có được Võ Hồn và các đạo cụ liên quan",11,10)
			self:AddNumText("Võ Hồn Thăng cấp giới thiệu",11,11)
			self:AddNumText("Võ Hồn hợp thành Cấp độ giới thiệu",11,12)
			self:AddNumText("Võ Hồn mở rộng Thuộc tính tửu quán",11,13)
			self:AddNumText("Giới thiệu kỹ năng Võ Hồn",11,14)
			self:AddNumText("Giới thiệu thuộc tính Võ Hồn",11,15)
			self:AddNumText("Tuổi thọ của Võ Hồn",11,16)
			self:AddNumText("Quay lại trang trước",8,17)
	    self:EndEvent()
	    self:DispatchEventList(selfId, targetId)
	elseif index == 9 then
		self:BeginEvent(self.script_id)
		self:AddText("#{WH_090820_01}")
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
	elseif index == 10 then
		self:BeginEvent(self.script_id)
		self:AddText( "#{WH_090729_59}" )
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
	elseif index == 11 then
		self:BeginEvent(self.script_id)
		self:AddText( "#{WH_090729_45}" )
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
	elseif index == 12 then
		self:BeginEvent(self.script_id)
		self:AddText( "#{WH_090729_46}" )
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
	elseif index == 13 then
		self:BeginEvent(self.script_id)
		self:AddText( "#{WH_090729_47}" )
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
	elseif index == 14 then
		self:BeginEvent(self.script_id)
		self:AddText( "#{WH_090729_48}" )
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
	elseif index == 15 then
		self:BeginEvent(self.script_id)
		self:AddText( "#{WH_090729_49}" )
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
	elseif index == 16 then
		self:BeginEvent(self.script_id)
		self:AddText( "#{WH_090820_02}" )
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
	elseif index == 17 then
		self:OnDefaultEvent(selfId,targetId )
	end
end

function odali_wuyazi:GetCostGongLi(XiuLianMiJiLevel)
	local nXiulianNeedPower = 0
	if (XiuLianMiJiLevel >= 0 and XiuLianMiJiLevel < 30)  then
		  nXiulianNeedPower = 33
	elseif(XiuLianMiJiLevel >= 30 and XiuLianMiJiLevel < 60 )  then
		  nXiulianNeedPower = 50
	elseif(XiuLianMiJiLevel >= 60 and XiuLianMiJiLevel <= 150)  then
		  nXiulianNeedPower = 100
	end
	return nXiulianNeedPower
end

function odali_wuyazi:AskXiuLianLevelUp(selfId,targetId,index)
    return require("cys_xiulian").operate(self,selfId,index,false)
end

function odali_wuyazi:GetCostMoney(CurMaxLevel)
	local nJingJieNum
	if(CurMaxLevel <= 60)   then
		  nJingJieNum = CurMaxLevel/10;
	else
		  nJingJieNum = ((CurMaxLevel-60)/15) + 6
	end
	nJingJieNum = nJingJieNum + 1
	return math.floor(nJingJieNum * nJingJieNum)
end

function odali_wuyazi:AskXiuLianAdvanceJingJie(selfId,targetId,index)
    return require("cys_xiulian").operate(self,selfId,index,true)
end

return odali_wuyazi