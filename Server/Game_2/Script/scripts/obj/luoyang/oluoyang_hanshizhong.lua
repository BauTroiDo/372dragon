local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_hanshizhong = class("oluoyang_hanshizhong", script_base)
local ScriptGlobal = require ("scripts.ScriptGlobal")
oluoyang_hanshizhong.script_id = 888821
oluoyang_hanshizhong.g_eventList = {600000,1018713,1018714}

function oluoyang_hanshizhong:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{PTDB_231225_74}")
	--开启神龙赐福
    self:AddNumText("#{PTDB_231225_270}", 6, 10)
	--领取龙影古塔奖励
    self:AddNumText("#{PTDB_231225_75}", 6, 11)
	self:AddNumText("#{YJGZ_20231228_9}", 6, 12)
	self:AddNumText("#{YJGZ_20231228_10}", 6, 13)
	self:AddNumText("#{YJGZ_20231228_11}", 6, 14)
	
	self:AddNumText("Tới điểm A Tỏa Long Cổ Tháp", 6, 15)
	self:AddNumText("Tới điểm B Tỏa Long Cổ Tháp", 6, 16)
	--龙影古塔奖励领取帮助
    self:AddNumText("#{PTDB_231225_76}", 11, 14)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_hanshizhong:OnEventRequest(selfId, targetId, arg, index)
    if index == 10 then
    end
    if index == 11 then
    end
    if index == 12 then
     self:CallScriptFunction((400900), "TransferFunc", selfId, 712, 216, 76, 10)
    end
    if index == 13 then
     self:CallScriptFunction((400900), "TransferFunc", selfId, 711, 61, 175, 10)

    end
    if index == 14 then
		self:CallScriptFunction((400900), "TransferFunc", selfId, 710, 194, 212, 10)
    end
    if index == 15 then
		self:CallScriptFunction((400900), "TransferFunc", selfId, 1350, 52, 209, 10)
    end
    if index == 16 then
		self:CallScriptFunction((400900), "TransferFunc", selfId, 1350, 208, 209, 10)
    end
end
function oluoyang_hanshizhong:OnMissionAccept(selfId, targetId, missionScriptId)

end

function oluoyang_hanshizhong:OnMissionRefuse(selfId, targetId, missionScriptId)

end

function oluoyang_hanshizhong:OnMissionContinue(selfId, targetId,
                                                missionScriptId)

end

function oluoyang_hanshizhong:OnMissionSubmit(selfId, targetId, missionScriptId,selectRadioId)

end

function oluoyang_hanshizhong:OnDie(selfId, killerId) end

return oluoyang_hanshizhong
