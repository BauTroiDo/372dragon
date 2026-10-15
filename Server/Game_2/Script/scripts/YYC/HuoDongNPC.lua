local class = require "class"
local define = require "define"
local script_base = require "script_base"

local HuoDongNPC = class("HuoDongNPC", script_base)
HuoDongNPC.script_id = 998524

local ChuansongList = {}

ChuansongList[1] = {818,173,83,80}
ChuansongList[2] = {714,56,113,80}
ChuansongList[3] = {814,98,158,80}

function HuoDongNPC:OnDefaultEvent(selfId, targetId, arg, index)
    self:BeginEvent(self.script_id)
   -- self:AddNumText("#GDaily Recharge(每日充值)", 6, 3)--水帘妖魔四起，抢夺海量道具！\n
    self:AddText("#cffff00BOSS tối thượng toàn server, trang bị và nguyên liệu hiếm rơi điên cuồng\\n")
    --self:AddNumText("#cff9900■ 大战水帘洞#P（#cffcc0015:00-17:00#P）", 6, 2)
    self:AddNumText("#cff9900■ Thiên Hạ Anh Hùng Hội#P（#cffcc0015:00-17:00#P）", 6, 1)
    self:AddNumText("#cff9900■ Huyết chiến Lăng Vân Quật#P（#cffcc0021:00-23:00#P）", 6, 3)
   -- self:AddNumText("#G经验兑换", 6, 2)
    --self:AddNumText("离开……", 11, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function HuoDongNPC:OnEventRequest(selfId, targetId, arg, index)
    index = tonumber(index)
    if index == 1 then
        self:CallScriptFunction(400900, "TransferFunc", selfId, ChuansongList[index][1], ChuansongList[index][2], ChuansongList[index][3],ChuansongList[index][4])
        return
    end
    if index == 2 then
        self:CallScriptFunction(400900, "TransferFunc", selfId, ChuansongList[index][1], ChuansongList[index][2], ChuansongList[index][3],ChuansongList[index][4])
        return
    end
    if index == 3 then
        self:CallScriptFunction(400900, "TransferFunc", selfId, ChuansongList[index][1], ChuansongList[index][2], ChuansongList[index][3],ChuansongList[index][4])
        return
    end
end

return HuoDongNPC
