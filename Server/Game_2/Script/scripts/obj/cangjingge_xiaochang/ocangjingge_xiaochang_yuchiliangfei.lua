local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ocangjingge_xiaochang_yuchiliangfei = class("ocangjingge_xiaochang_yuchiliangfei", script_base)
ocangjingge_xiaochang_yuchiliangfei.script_id = 900008
ocangjingge_xiaochang_yuchiliangfei.g_ChangShenCaoItem = {38000639, 40004689}

function ocangjingge_xiaochang_yuchiliangfei:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{TFXC_20220921_28}")
    self:AddNumText("#{SJBW_130823_49}", 6, 10)
    self:AddNumText("Mãn Nộ Trị Liệu", 6, 0)
    self:AddNumText("#{TFXC_20220921_29}", 9, 5001)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ocangjingge_xiaochang_yuchiliangfei:OnEventRequest(selfId, targetId, arg, index)
    if index == 5001 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 0, 186, 327)
        return
    end
end

function ocangjingge_xiaochang_yuchiliangfei:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

return ocangjingge_xiaochang_yuchiliangfei
