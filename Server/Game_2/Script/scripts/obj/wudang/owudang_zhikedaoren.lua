--武当NPC
--问路
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local owudang_zhikedaoren = class("owudang_zhikedaoren", script_base)
owudang_zhikedaoren.script_id = 012034
owudang_zhikedaoren.g_eventList = {500064}

function owudang_zhikedaoren:UpdateEventList(selfId, targetId)
  self:BeginEvent(self.script_id)
  self:AddText("Ta sẽ chỉ đường cho ngươi.")
  for i, eventId in pairs(self.g_eventList) do
    self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
  end
  self:EndEvent()
  self:DispatchEventList(selfId, targetId)
end

function owudang_zhikedaoren:OnDefaultEvent(selfId, targetId)
  self:UpdateEventList(selfId, targetId)
end

function owudang_zhikedaoren:OnEventRequest(selfId, targetId, arg, index)
  self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId)
  return
end

function owudang_zhikedaoren:OnMissionAccept(selfId, targetId, missionScriptId)
  for i, findId in pairs(self.g_eventList) do
    if missionScriptId == findId then
      ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
      if ret > 0 then
        self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
      end
      return
    end
  end
end

function owudang_zhikedaoren:OnMissionRefuse(selfId, targetId, missionScriptId)
  for i, findId in pairs(self.g_eventList) do
    if missionScriptId == findId then
      self:UpdateEventList(selfId, targetId)
      return
    end
  end
end

function owudang_zhikedaoren:OnMissionContinue(selfId, targetId, missionScriptId)
  for i, findId in pairs(self.g_eventList) do
    if missionScriptId == findId then
      self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
      return
    end
  end
end

function owudang_zhikedaoren:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
  for i, findId in pairs(self.g_eventList) do
    if missionScriptId == findId then
      self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
      return
    end
  end
end

function owudang_zhikedaoren:OnDie(selfId, killerId)
end

return owudang_zhikedaoren
