--珍兽觉醒NPC(传送到云水间)

local class = require "class"
local script_base = require "script_base"
local pet_elf_kw_npc = class("pet_elf_kw_npc", script_base)

function pet_elf_kw_npc:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Có tới Vân Thủy Gian không?")
    self:AddNumText("Tới Vân Thủy Gian", 9, 1)
    self:AddNumText("#{SHXT_20211230_55}", 11, 99)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function pet_elf_kw_npc:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        if self:LuaFnGetDestSceneHumanCount(1072) < 700 then
            self:CallScriptFunction((400900), "TransferFunc", selfId, 1072, 32, 43)
        else
            self:notify_tips(selfId, "Cảnh đích đã đủ người")
        end
        return
    end
end

return pet_elf_kw_npc
