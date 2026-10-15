local ScriptGlobal = require "scripts.ScriptGlobal"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local obaixihu_qingyuan = class("obaixihu_qingyuan", script_base)
function obaixihu_qingyuan:OnDefaultEvent(selfId, targetId)
	self:BeginEvent(self.script_id)
    self:AddText("#{BLDPVP_221214_18}")
    --self:AddNumText("#{BLDPVP_221214_175}", 10, 3)
    self:AddNumText("#{BLDPVP_221214_20}", 11, 2)
    self:AddNumText("#{CJWK_221220_31}", 9, 100)
    self:AddNumText("#{BLDPVP_221214_129}", 7, 201)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function obaixihu_qingyuan:OnEventRequest(selfId, targetId, arg, index)
	if index == 100 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 1295, 51, 219)
        return
    end
    if index == 3 then
        if self:GetLevel(selfId) < 85 then
            self:BeginEvent(self.script_id)
            self:AddText("Cấp bạn quá thấp, sau cấp 85 mới tới Bất Lão Điện được")
            self:EndEvent()
            self:DispatchEventList(selfId,targetId)
            return
        end
        if ScriptGlobal.is_internal_test then
            self:BeginEvent(self.script_id)
            self:AddText("Đang test, không tham gia Thiên Ngoại được~")
            self:EndEvent()
            self:DispatchEventList(selfId,targetId)
        else
            self:CallScriptFunction((400900), "TransferFunc", selfId, 1297, 40, 174)
        end
        return
    end
    if index == 201 then
        self:DispatchTJCPVPCnmData(selfId)
        return
    end
end

return obaixihu_qingyuan