local class = require "class"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"

local daluandou_npc = class("daluandou_npc", script_base)



-- cd /home/ubuntu/cys-test-20260913/GameServer && expect reload.exp 6002

daluandou_npc.script_id = 999862
daluandou_npc.main_script_id = 999861
daluandou_npc.exchange_event_base = 20000
daluandou_npc.exchange_list = {
	{need_score = 3000, item_id = 10410148, item_num = 1},
	{need_score = 2500, item_id = 10420090, item_num = 1},
}
daluandou_npc.chenghaoBINGlist = {
	{need_score = 1000, item_id = 1456, item_num = 1, name="Đại Loạn Đấu Sắt Đen·Băng"},--大乱斗黑铁·冰
	{need_score = 2000, item_id = 1457, item_num = 1, name="Đại Loạn Đấu Đồng·Băng"},
	{need_score = 3000, item_id = 1458, item_num = 1, name="Đại Loạn Đấu Bạc·Băng"},
	{need_score = 4000, item_id = 1459, item_num = 1, name="Đại Loạn Đấu Vàng·Băng"},
	{need_score = 5000, item_id = 1460, item_num = 1, name="Đại Loạn Đấu Bạch Kim·Băng"},
	{need_score = 6000, item_id = 1461, item_num = 1, name="Đại Loạn Đấu Kim Cương·Băng"},
	{need_score = 8888, item_id = 1462, item_num = 1, name="Đại Loạn Đấu Vương Giả·Băng"},}
daluandou_npc.chenghaoHUOlist = {
	{need_score = 1000, item_id = 1463, item_num = 1, name="Đại Loạn Đấu Sắt Đen·Hỏa"},--大乱斗黑铁·火
	{need_score = 2000, item_id = 1464, item_num = 1, name="Đại Loạn Đấu Đồng·Hỏa"},
	{need_score = 3000, item_id = 1465, item_num = 1, name="Đại Loạn Đấu Bạc·Hỏa"},
	{need_score = 4000, item_id = 1466, item_num = 1, name="Đại Loạn Đấu Vàng·Hỏa"},
	{need_score = 5000, item_id = 1467, item_num = 1, name="Đại Loạn Đấu Bạch Kim·Hỏa"},
	{need_score = 6000, item_id = 1468, item_num = 1, name="Đại Loạn Đấu Kim Cương·Hỏa"},
	{need_score = 8888, item_id = 1469, item_num = 1, name="Đại Loạn Đấu Vương Giả·Hỏa"},
}
daluandou_npc.chenghaoXUANlist = {
	{need_score = 1000, item_id = 1470, item_num = 1, name="Đại Loạn Đấu Sắt Đen·Huyền"},--大乱斗黑铁·玄
	{need_score = 2000, item_id = 1471, item_num = 1, name="Đại Loạn Đấu Đồng·Huyền"},
	{need_score = 3000, item_id = 1472, item_num = 1, name="Đại Loạn Đấu Bạc·Huyền"},
	{need_score = 4000, item_id = 1473, item_num = 1, name="Đại Loạn Đấu Vàng·Huyền"},
	{need_score = 5000, item_id = 1474, item_num = 1, name="Đại Loạn Đấu Bạch Kim·Huyền"},
	{need_score = 6000, item_id = 1475, item_num = 1, name="Đại Loạn Đấu Kim Cương·Huyền"},
	{need_score = 8888, item_id = 1476, item_num = 1, name="Đại Loạn Đấu Vương Giả·Huyền"},
}
daluandou_npc.chenghaoDUlist = {
	{need_score = 1000, item_id = 1477, item_num = 1, name="Đại Loạn Đấu Sắt Đen·Độc"},--大乱斗黑铁·毒
	{need_score = 2000, item_id = 1478, item_num = 1, name="Đại Loạn Đấu Đồng·Độc"},
	{need_score = 3000, item_id = 1479, item_num = 1, name="Đại Loạn Đấu Bạc·Độc"},
	{need_score = 4000, item_id = 1480, item_num = 1, name="Đại Loạn Đấu Vàng·Độc"},
	{need_score = 5000, item_id = 1481, item_num = 1, name="Đại Loạn Đấu Bạch Kim·Độc"},
	{need_score = 6000, item_id = 1482, item_num = 1, name="Đại Loạn Đấu Kim Cương·Độc"},
	{need_score = 8888, item_id = 1483, item_num = 1, name="Đại Loạn Đấu Vương Giả·Độc"},
}

daluandou_npc.chenghaoLSlist = {
	{need_score = 50, item_id = 1446, item_num = 1, name="Đại Loạn Đấu·Phong Mang Sơ Lộ"},--大乱斗·锋芒初露
	{need_score = 100, item_id = 1447, item_num = 1, name="Đại Loạn Đấu·Song Ảnh Truy Hồn"},
	{need_score = 150, item_id = 1448, item_num = 1, name="Đại Loạn Đấu·Tam Tài Tuyệt Trận"},
	{need_score = 200, item_id = 1449, item_num = 1, name="Đại Loạn Đấu·Tứ Phương Tịch Diệt"},
	{need_score = 250, item_id = 1450, item_num = 1, name="Đại Loạn Đấu·Ngũ Ngục Tu La"},
	{need_score = 300, item_id = 1451, item_num = 1, name="Đại Loạn Đấu·Lục Đạo Luân Hồi"},
	{need_score = 350, item_id = 1452, item_num = 1, name="Đại Loạn Đấu·Thất Tinh Đoạt Phách"},
	{need_score = 400, item_id = 1453, item_num = 1, name="Đại Loạn Đấu·Bát Hoang Phần Tận"},
	{need_score = 450, item_id = 1454, item_num = 1, name="Đại Loạn Đấu·Cửu U Ma Chủ"},
	{need_score = 500, item_id = 1455, item_num = 1, name="Đại Loạn Đấu·Thập Điện Diêm La"},
}

daluandou_npc.chenghaoZSlist = {
	{need_score = 50, item_id = 1443, item_num = 1, name="Tử Long tại thế"},--大乱斗·子龙在世
	{need_score = 100, item_id = 1444, item_num = 1, name="Vạn nhân mạc khai"},
	{need_score = 200, item_id = 1445, item_num = 1, name="Loạn Đấu Chi Thần"},

}

daluandou_npc.chenghaoPHlist = {
	{need_score = 50, item_id = 1484, item_num = 1, name="Pháo Hôi Đồng"},--大乱斗·锋芒初露
	{need_score = 100, item_id = 1485, item_num = 1, name="Pháo Hôi Bạc"},
	{need_score = 150, item_id = 1486, item_num = 1, name="Pháo Hôi Vàng"},
	{need_score = 200, item_id = 1487, item_num = 1, name="Pháo Hôi Bạch Kim"},
	{need_score = 250, item_id = 1488, item_num = 1, name="Pháo Hôi Kim Cương"},
	{need_score = 300, item_id = 1489, item_num = 1, name="Pháo Hôi Vương Giả"},
}

daluandou_npc.chenghaoSYlist = {
	{need_score = 1000, item_id = 1456, item_num = 1, name="Đại Loạn Đấu Sắt Đen·Băng"},--大乱斗黑铁·冰
	{need_score = 2000, item_id = 1457, item_num = 1, name="Đại Loạn Đấu Đồng·Băng"},
	{need_score = 3000, item_id = 1458, item_num = 1, name="Đại Loạn Đấu Bạc·Băng"},
	{need_score = 4000, item_id = 1459, item_num = 1, name="Đại Loạn Đấu Vàng·Băng"},
	{need_score = 5000, item_id = 1460, item_num = 1, name="Đại Loạn Đấu Bạch Kim·Băng"},
	{need_score = 6000, item_id = 1461, item_num = 1, name="Đại Loạn Đấu Kim Cương·Băng"},
	{need_score = 8888, item_id = 1462, item_num = 1, name="Đại Loạn Đấu Vương Giả·Băng"},

	{need_score = 1000, item_id = 1463, item_num = 1, name="Đại Loạn Đấu Sắt Đen·Hỏa"},--大乱斗黑铁·火
	{need_score = 2000, item_id = 1464, item_num = 1, name="Đại Loạn Đấu Đồng·Hỏa"},
	{need_score = 3000, item_id = 1465, item_num = 1, name="Đại Loạn Đấu Bạc·Hỏa"},
	{need_score = 4000, item_id = 1466, item_num = 1, name="Đại Loạn Đấu Vàng·Hỏa"},
	{need_score = 5000, item_id = 1467, item_num = 1, name="Đại Loạn Đấu Bạch Kim·Hỏa"},
	{need_score = 6000, item_id = 1468, item_num = 1, name="Đại Loạn Đấu Kim Cương·Hỏa"},
	{need_score = 8888, item_id = 1469, item_num = 1, name="Đại Loạn Đấu Vương Giả·Hỏa"},

	{need_score = 1000, item_id = 1470, item_num = 1, name="Đại Loạn Đấu Sắt Đen·Huyền"},--大乱斗黑铁·玄
	{need_score = 2000, item_id = 1471, item_num = 1, name="Đại Loạn Đấu Đồng·Huyền"},
	{need_score = 3000, item_id = 1472, item_num = 1, name="Đại Loạn Đấu Bạc·Huyền"},
	{need_score = 4000, item_id = 1473, item_num = 1, name="Đại Loạn Đấu Vàng·Huyền"},
	{need_score = 5000, item_id = 1474, item_num = 1, name="Đại Loạn Đấu Bạch Kim·Huyền"},
	{need_score = 6000, item_id = 1475, item_num = 1, name="Đại Loạn Đấu Kim Cương·Huyền"},
	{need_score = 8888, item_id = 1476, item_num = 1, name="Đại Loạn Đấu Vương Giả·Huyền"},

	{need_score = 1000, item_id = 1477, item_num = 1, name="Đại Loạn Đấu Sắt Đen·Độc"},--大乱斗黑铁·毒
	{need_score = 2000, item_id = 1478, item_num = 1, name="Đại Loạn Đấu Đồng·Độc"},
	{need_score = 3000, item_id = 1479, item_num = 1, name="Đại Loạn Đấu Bạc·Độc"},
	{need_score = 4000, item_id = 1480, item_num = 1, name="Đại Loạn Đấu Vàng·Độc"},
	{need_score = 5000, item_id = 1481, item_num = 1, name="Đại Loạn Đấu Bạch Kim·Độc"},
	{need_score = 6000, item_id = 1482, item_num = 1, name="Đại Loạn Đấu Kim Cương·Độc"},
	{need_score = 8888, item_id = 1483, item_num = 1, name="Đại Loạn Đấu Vương Giả·Độc"},

	{need_score = 50, item_id = 1446, item_num = 1, name="Đại Loạn Đấu·Phong Mang Sơ Lộ"},--大乱斗·锋芒初露
	{need_score = 100, item_id = 1447, item_num = 1, name="Đại Loạn Đấu·Song Ảnh Truy Hồn"},
	{need_score = 150, item_id = 1448, item_num = 1, name="Đại Loạn Đấu·Tam Tài Tuyệt Trận"},
	{need_score = 200, item_id = 1449, item_num = 1, name="Đại Loạn Đấu·Tứ Phương Tịch Diệt"},
	{need_score = 250, item_id = 1450, item_num = 1, name="Đại Loạn Đấu·Ngũ Ngục Tu La"},
	{need_score = 300, item_id = 1451, item_num = 1, name="Đại Loạn Đấu·Lục Đạo Luân Hồi"},
	{need_score = 350, item_id = 1452, item_num = 1, name="Đại Loạn Đấu·Thất Tinh Đoạt Phách"},
	{need_score = 400, item_id = 1453, item_num = 1, name="Đại Loạn Đấu·Bát Hoang Phần Tận"},
	{need_score = 450, item_id = 1454, item_num = 1, name="Đại Loạn Đấu·Cửu U Ma Chủ"},
	{need_score = 500, item_id = 1455, item_num = 1, name="Đại Loạn Đấu·Thập Điện Diêm La"},

	{need_score = 50, item_id = 1443, item_num = 1, name="Tử Long tại thế"},--大乱斗·子龙在世
	{need_score = 100, item_id = 1444, item_num = 1, name="Vạn nhân mạc khai"},
	{need_score = 200, item_id = 1445, item_num = 1, name="Loạn Đấu Chi Thần"},

	{need_score = 50, item_id = 1484, item_num = 1, name="Pháo Hôi Đồng"},--大乱斗·锋芒初露
	{need_score = 100, item_id = 1485, item_num = 1, name="Pháo Hôi Bạc"},
	{need_score = 150, item_id = 1486, item_num = 1, name="Pháo Hôi Vàng"},
	{need_score = 200, item_id = 1487, item_num = 1, name="Pháo Hôi Bạch Kim"},
	{need_score = 250, item_id = 1488, item_num = 1, name="Pháo Hôi Kim Cương"},
	{need_score = 300, item_id = 1489, item_num = 1, name="Pháo Hôi Vương Giả"},

}

function daluandou_npc:OnDefaultEvent(selfId, targetId)
	-- self:AddGlobalCountNews("@*;SrvMsg;SCA:#{_NEWMSG_999861daluandou_box}大乱斗活动1分钟后开启，各位大侠可以入场了。")
	-- self:NewWorld(selfId, 413, nil, 30, 30)
	local sceneid = self:GetSceneID()
	local point = tonumber(self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_DaLuanDouJF)) or 0
	self:BeginEvent(self.script_id)
	self:AddText("    Giờ hoạt động: 20:30-21:00 (20:29 vào được)")
	self:AddText(string.format("    Tích điểm loạn đấu hiện tại:#G%d", point))
	if sceneid == 413 then
		self:AddNumText("Rời bản đồ loạn đấu", 6, 2)
	else

		self:AddNumText("Vào bản đồ loạn đấu", 6, 1)	
	end
	self:AddNumText("Nhận thưởng xếp hạng Sát Thần", 6, 11)
	self:AddNumText("Nhận thưởng xếp hạng Pháo Hôi", 6, 12)
	self:AddNumText("Đổi đạo cụ bằng tích điểm loạn đấu", 6, 20)
	self:AddNumText("Đổi danh hiệu bằng tích điểm loạn đấu", 6, 30)
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end

function daluandou_npc:GetExchangeCfg(index)
	local cfg_index = (tonumber(index) or 0) - (self.exchange_event_base or 20000)
	if cfg_index >= 1 and cfg_index <= #self.exchange_list then
		return self.exchange_list[cfg_index]
	end
end

function daluandou_npc:ShowExchangeList(selfId, targetId)
	local point = tonumber(self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_DaLuanDouJF)) or 0
	self:BeginEvent(self.script_id)
	self:AddText(string.format("    Tích điểm loạn đấu hiện tại:#G%d", point))
	for i, cfg in ipairs(self.exchange_list) do
		local item_name = self:GetItemName(cfg.item_id) or tostring(cfg.item_id)
		local item_num = tonumber(cfg.item_num) or 1
		local need_score = tonumber(cfg.need_score) or 0
		local show_text = string.format("%d tích điểm đổi %sx%d", need_score, item_name, item_num)
		self:AddNumText(show_text, 6, (self.exchange_event_base or 20000) + i)
	end
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end

function daluandou_npc:ExchangeByIndex(selfId, targetId, arg, index)
	local cfg = self:GetExchangeCfg(index)
	if not cfg then
		self:notify_tips(selfId, "Cấu hình đổi không tồn tại.")
		return
	end

	local point = tonumber(self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_DaLuanDouJF)) or 0
	if point < (cfg.need_score or 0) then
		self:notify_tips(selfId, string.format("Không đủ tích điểm loạn đấu, cần %d.", cfg.need_score or 0))
		return
	end
	self:BeginAddItem()
	self:AddItem(cfg.item_id, cfg.item_num,true)
	if not self:EndAddItem(selfId) then
		self:notify_tips(selfId, "Túi đồ không đủ chỗ trống.")
		return
	end
	self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_DaLuanDouJF, point - (cfg.need_score or 0))
	self:AddItemListToHuman(selfId)
	self:notify_tips(selfId, string.format("Đổi thành công, tốn %d tích điểm.", cfg.need_score or 0))
	self:ShowExchangeList(selfId, targetId)
end

function daluandou_npc:OnEventRequest(selfId, targetId, arg, index)
	if index == 1 then
		local point = tonumber(self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_DaLuanDouJF)) or 0
				--清理连杀数据
				self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_DaLuanDouLS, 0) 
				if point<100 then
					self:notify_tips(selfId, "Tích điểm loạn đấu dưới 100 không vào giữa chừng được")
					return
				end
				self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_DaLuanDouJF, (point-100)) 
		self:CallScriptFunction(self.main_script_id, "JoinBattle", selfId)
	elseif index == 2 then
		self:CallScriptFunction(self.main_script_id, "LeaveBattle", selfId)
	elseif index == 11 then
		self:CallScriptFunction(self.main_script_id, "ClaimRankAward", selfId, 1)
	elseif index == 12 then
		self:CallScriptFunction(self.main_script_id, "ClaimRankAward", selfId, 2)
	elseif index == 20 then
		self:ShowExchangeList(selfId, targetId)
	elseif index == 30 then--属性称号分页
		self:ShowCHList(selfId, targetId)
	elseif index == 31 then--冰属性称号
		self:ShowCHBINGList(selfId, targetId)
	elseif index == 32 then--火属性称号
		self:ShowCHHUOList(selfId, targetId)
	elseif index == 33 then--玄属性称号
		self:ShowCHXUANList(selfId, targetId)
	elseif index == 34 then--毒属性称号
		self:ShowCHDUList(selfId, targetId)
	elseif index == 40 then--毒属性称号
		self:ShowCHLSList(selfId, targetId)
	elseif index == 50 then--炮灰称号
		self:ShowCHPHList(selfId, targetId)
	elseif index == 60 then--战损比称号
		self:ShowCHZSList(selfId, targetId)
	elseif index >30000 and index <38000 then--给称号
		self:SETChengHao(selfId, index)
	elseif index >= (self.exchange_event_base + 1) and index <= (self.exchange_event_base + #self.exchange_list) then
		self:ExchangeByIndex(selfId, targetId, arg, index)
	end
end
--称号兑换分页
function daluandou_npc:ShowCHList(selfId, targetId)
	local point = tonumber(self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_DaLuanDouJF)) or 0
	self:BeginEvent(self.script_id)
	self:AddText(string.format("    Tích điểm loạn đấu hiện tại:#G%d", point))
	
	self:AddNumText("Danh hiệu thuộc tính Băng Đại Loạn Đấu", 6, 31)
	self:AddNumText("Danh hiệu thuộc tính Hỏa Đại Loạn Đấu", 6, 32)
	self:AddNumText("Danh hiệu thuộc tính Huyền Đại Loạn Đấu", 6, 33)
	self:AddNumText("Danh hiệu thuộc tính Độc Đại Loạn Đấu", 6, 34)
	self:AddNumText("Danh hiệu chuỗi giết Đại Loạn Đấu", 6, 40)
	self:AddNumText("Danh hiệu Pháo Hôi Đại Loạn Đấu", 6, 50)
	self:AddNumText("Danh hiệu tỷ lệ chiến tổn Đại Loạn Đấu", 6, 60)
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end
--冰属性称号
function daluandou_npc:ShowCHBINGList(selfId, targetId)
	local point = tonumber(self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_DaLuanDouJF)) or 0
	self:BeginEvent(self.script_id)
	self:AddText(string.format("    Tích điểm loạn đấu hiện tại:#G%d", point))
	for i, cfg in ipairs(self.chenghaoBINGlist) do
		local item_name = cfg.name
		local item_num = tonumber(cfg.item_num) or 1
		local need_score = tonumber(cfg.need_score) or 0
		local show_text = string.format("%d tích điểm đổi %sx%d", need_score, item_name, item_num)
		self:AddNumText(show_text, 6, (30000 + cfg.item_id))
	end
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end
--火属性称号
function daluandou_npc:ShowCHHUOList(selfId, targetId)
	local point = tonumber(self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_DaLuanDouJF)) or 0
	self:BeginEvent(self.script_id)
	self:AddText(string.format("    Tích điểm loạn đấu hiện tại:#G%d", point))
	for i, cfg in ipairs(self.chenghaoHUOlist) do
		local item_name = cfg.name
		local item_num = tonumber(cfg.item_num) or 1
		local need_score = tonumber(cfg.need_score) or 0
		local show_text = string.format("%d tích điểm đổi %sx%d", need_score, item_name, item_num)
		self:AddNumText(show_text, 6, (30000 + cfg.item_id))
	end
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end
--玄属性称号
function daluandou_npc:ShowCHXUANList(selfId, targetId)
	local point = tonumber(self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_DaLuanDouJF)) or 0
	self:BeginEvent(self.script_id)
	self:AddText(string.format("    Tích điểm loạn đấu hiện tại:#G%d", point))
	for i, cfg in ipairs(self.chenghaoXUANlist) do
		local item_name = cfg.name
		local item_num = tonumber(cfg.item_num) or 1
		local need_score = tonumber(cfg.need_score) or 0
		local show_text = string.format("%d tích điểm đổi %sx%d", need_score, item_name, item_num)
		self:AddNumText(show_text, 6, (30000 + cfg.item_id))
	end
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end
--毒属性称号
function daluandou_npc:ShowCHDUList(selfId, targetId)
	local point = tonumber(self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_DaLuanDouJF)) or 0
	self:BeginEvent(self.script_id)
	self:AddText(string.format("    Tích điểm loạn đấu hiện tại:#G%d", point))
	for i, cfg in ipairs(self.chenghaoDUlist) do
		local item_name = cfg.name
		local item_num = tonumber(cfg.item_num) or 1
		local need_score = tonumber(cfg.need_score) or 0
		local show_text = string.format("%d tích điểm đổi %sx%d", need_score, item_name, item_num)
		self:AddNumText(show_text, 6, (30000 + cfg.item_id))
	end
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end
--连杀称号
function daluandou_npc:ShowCHLSList(selfId, targetId)
	local point = tonumber(self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_DaLuanDouMAXLS)) or 0
	self:BeginEvent(self.script_id)
	self:AddText(string.format("    Chuỗi giết lớn nhất loạn đấu hiện tại:#G%d", point))
	for i, cfg in ipairs(self.chenghaoLSlist) do
		local item_name = cfg.name
		local item_num = tonumber(cfg.item_num) or 1
		local need_score = tonumber(cfg.need_score) or 0
		local show_text = string.format("%d chuỗi giết %sx%d", need_score, item_name, item_num)
		self:AddNumText(show_text, 6, (32000 + cfg.item_id))
	end
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end
--战损称号
function daluandou_npc:ShowCHZSList(selfId, targetId)
	
	local player_guid = self:LuaFnGetGUID(selfId)
	local world_id = self:LuaFnGetServerID(selfId)
	local _, player_kill = self:ranking_call("get_brawl_rank", world_id, 1, player_guid)
	local _, player_dead = self:ranking_call("get_brawl_rank", world_id, 2, player_guid)
	
	self:BeginEvent(self.script_id)
	--self:AddText(string.format("    当前乱斗战损比：#G%d", (player_kill/(player_dead+1))))
	self:AddText(string.format("    Tỷ lệ chiến tổn loạn đấu hiện tại:#G%d", math.floor(player_kill / (player_dead + 1) + 0.5)))
	for i, cfg in ipairs(self.chenghaoZSlist) do
		local item_name = cfg.name
		local item_num = tonumber(cfg.item_num) or 1
		local need_score = tonumber(cfg.need_score) or 0
		local show_text = string.format("%d tỷ lệ chiến tổn %sx%d", need_score, item_name, item_num)
		self:AddNumText(show_text, 6, (34000 + cfg.item_id))
	end
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end
--炮灰称号
function daluandou_npc:ShowCHPHList(selfId, targetId)
	
	local player_guid = self:LuaFnGetGUID(selfId)
	local world_id = self:LuaFnGetServerID(selfId)
	local _, player_kill = self:ranking_call("get_brawl_rank", world_id, 1, player_guid)
	local _, player_dead = self:ranking_call("get_brawl_rank", world_id, 2, player_guid)
	
	self:BeginEvent(self.script_id)
	self:AddText(string.format("    Số chết loạn đấu hiện tại:#G%d", player_dead))
	for i, cfg in ipairs(self.chenghaoPHlist) do
		local item_name = cfg.name
		local item_num = tonumber(cfg.item_num) or 1
		local need_score = tonumber(cfg.need_score) or 0
		local show_text = string.format("%d số chết loạn đấu %sx%d", need_score, item_name, item_num)
		self:AddNumText(show_text, 6, (36000 + cfg.item_id))
	end
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end

local skynet = require "skynet"
function daluandou_npc:ranking_call(method, ...)
    local ok, ret1, ret2, ret3 = pcall(skynet.call, ".ranking", "lua", method, ...)
    if not ok then
        return nil, ret1
    end
    return ret1, ret2, ret3
end
--给称号
function daluandou_npc:SETChengHao(selfId, targetId)
	if targetId<32000   then
		local title_id = targetId-30000
		local score = 0
		local point = tonumber(self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_DaLuanDouJF)) or 0
		for i, cfg in ipairs(self.chenghaoSYlist) do
			local item_name = cfg.name
			local item_num = tonumber(cfg.item_num) or 1
			local need_score = tonumber(cfg.need_score) or 0
			local show_text = string.format("%d tích điểm đổi %sx%d", need_score, item_name, item_num)
			if cfg.item_id == title_id then
				score = cfg.need_score
			end
		end
		if score == 0 then
			self:notify_tips(selfId, string.format("Dữ liệu dị thường"..title_id))
			return
		end
		if  point<score  then
			self:notify_tips(selfId, string.format("Không đủ tích điểm loạn đấu, cần %d.", score))
			return
		end
		
		-- 处理称号奖励
		if not self:LuaFnHaveAgname(selfId, title_id) then
		self:LuaFnAddNewAgname(selfId, title_id)
		self:notify_tips(selfId, string.format("Chúc mừng nhận danh hiệu"))
		self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_DaLuanDouJF, (point - score))
		else
			self:notify_tips(selfId, string.format("Ngươi đã từng nhận danh hiệu này"))
			return
		end
	elseif targetId>32000 and targetId<34000 then
	
		local title_id = targetId-32000
		local score = 0
		local point = tonumber(self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_DaLuanDouMAXLS)) or 0
		for i, cfg in ipairs(self.chenghaoSYlist) do
			local item_name = cfg.name
			local item_num = tonumber(cfg.item_num) or 1
			local need_score = tonumber(cfg.need_score) or 0
			local show_text = string.format("%d tích điểm đổi %sx%d", need_score, item_name, item_num)
			if cfg.item_id == title_id then
				score = cfg.need_score
			end
		end
		if score == 0 then
			self:notify_tips(selfId, string.format("Dữ liệu dị thường"..title_id))
			return
		end
		if  point<score  then
			self:notify_tips(selfId, string.format("Chuỗi giết lớn nhất loạn đấu không đủ, cần %d.", score))
			return
		end
		
		-- 处理称号奖励
		if not self:LuaFnHaveAgname(selfId, title_id) then
		self:LuaFnAddNewAgname(selfId, title_id)
		self:notify_tips(selfId, string.format("Chúc mừng nhận danh hiệu"))
		else
			self:notify_tips(selfId, string.format("Ngươi đã từng nhận danh hiệu này"))
			return
		end
	elseif targetId>34000 and targetId<36000 then
		
		local title_id = targetId-34000
		local player_guid = self:LuaFnGetGUID(selfId)
		local world_id = self:LuaFnGetServerID(selfId)
		local _, player_kill = self:ranking_call("get_brawl_rank", world_id, 1, player_guid)
		local _, player_dead = self:ranking_call("get_brawl_rank", world_id, 2, player_guid)
		local a= math.floor(player_kill / (player_dead + 1) + 0.5)
		self:BeginEvent(self.script_id)
		self:AddText(string.format("    Tỷ lệ chiến tổn loạn đấu hiện tại:#G%d", a))
		local score = 0
		
		for i, cfg in ipairs(self.chenghaoSYlist) do
			local item_name = cfg.name
			local item_num = tonumber(cfg.item_num) or 1
			local need_score = tonumber(cfg.need_score) or 0
			local show_text = string.format("%d tích điểm đổi %sx%d", need_score, item_name, item_num)
			if cfg.item_id == title_id then
				score = cfg.need_score
			end
		end
		if score == 0 then
			self:notify_tips(selfId, string.format("Dữ liệu dị thường"..title_id))
			return
		end
		
		
		if (tonumber(a) or 0)< (tonumber(score) or 0) then
			self:notify_tips(selfId, string.format("Tỷ lệ chiến tổn không đủ, cần %d.", score))
			return
		end
		
		-- 处理称号奖励
		if not self:LuaFnHaveAgname(selfId, title_id) then
		self:LuaFnAddNewAgname(selfId, title_id)
		self:notify_tips(selfId, string.format("Chúc mừng nhận danh hiệu"))
		else
			self:notify_tips(selfId, string.format("Ngươi đã từng nhận danh hiệu này"))
			return
		end
	elseif targetId>36000 then
		
		local title_id = targetId-36000
		local player_guid = self:LuaFnGetGUID(selfId)
		local world_id = self:LuaFnGetServerID(selfId)
		
		local _, player_dead = self:ranking_call("get_brawl_rank", world_id, 2, player_guid)
		
		self:BeginEvent(self.script_id)
		self:AddText(string.format("    Chết loạn đấu hiện tại:#G%d", player_dead))
		local score = 0
		
		for i, cfg in ipairs(self.chenghaoSYlist) do
			local item_name = cfg.name
			local item_num = tonumber(cfg.item_num) or 1
			local need_score = tonumber(cfg.need_score) or 0
			local show_text = string.format("%d tích điểm đổi %sx%d", need_score, item_name, item_num)
			if cfg.item_id == title_id then
				score = cfg.need_score
			end
		end
		if score == 0 then
			self:notify_tips(selfId, string.format("Dữ liệu dị thường"..title_id))
			return
		end
		if  player_dead<score  then
			self:notify_tips(selfId, string.format("Số chết loạn đấu không đủ, cần %d.", score))
			return
		end
		
		-- 处理称号奖励
		if not self:LuaFnHaveAgname(selfId, title_id) then
		self:LuaFnAddNewAgname(selfId, title_id)
		self:notify_tips(selfId, string.format("Chúc mừng nhận danh hiệu"))
		else
			self:notify_tips(selfId, string.format("Ngươi đã từng nhận danh hiệu này"))
			return
		end
	end
end

return daluandou_npc
