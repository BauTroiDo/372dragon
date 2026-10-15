local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local edali_0241 = class("edali_0241", script_base)
edali_0241.script_id = 210241
edali_0241.g_MPInfo = {
{ ["nam"] = "Thiếu Lâm phái", ["des"] = "#{event_dali_mp_sl}", ["key"] = 1020, ["x"] = 187, ["z"] = 122, ["npc"] = "慧易" },
{ ["nam"] = "明教", ["des"] = "#{event_dali_mp_mj}", ["key"] = 1021, ["x"] = 130, ["z"] = 121, ["npc"] = "石宝" },
{ ["nam"] = "丐帮", ["des"] = "#{event_dali_mp_gb}", ["key"] = 1022, ["x"] = 126, ["z"] = 135, ["npc"] = "简宁" },
{ ["nam"] = "Võ Đang phái", ["des"] = "#{event_dali_mp_wd}", ["key"] = 1023, ["x"] = 134, ["z"] = 120, ["npc"] = "海风子" },
{ ["nam"] = "Nga My phái", ["des"] = "#{event_dali_mp_em}", ["key"] = 1024, ["x"] = 192, ["z"] = 129, ["npc"] = "路三娘" },
{ ["nam"] = "Tinh Túc phái", ["des"] = "#{event_dali_mp_xx}", ["key"] = 1025, ["x"] = 134, ["z"] = 120, ["npc"] = "海风子" },
{ ["nam"] = "Thiên Long phái", ["des"] = "#{event_dali_mp_tl}", ["key"] = 1026, ["x"] = 189, ["z"] = 124, ["npc"] = "破贪" },
{ ["nam"] = "Thiên Sơn phái", ["des"] = "#{event_dali_mp_ts}", ["key"] = 1027, ["x"] = 131, ["z"] = 124, ["npc"] = "程青霜" },
{ ["nam"] = "Tiêu Dao phái", ["des"] = "#{event_dali_mp_xy}", ["key"] = 1028, ["x"] = 188, ["z"] = 133, ["npc"] = "澹台子羽" }
}
function edali_0241:OnDefaultEvent(selfId, targetId,arg,index)
    local key = index
    if key == 1010 then
        self:BeginEvent(self.script_id)
        self:AddText("#{event_dali_mp_dlg}")
        for _, MP in pairs(self.g_MPInfo) do
            self:AddNumText(MP["nam"], 11, MP["key"])
        end
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    else
        for _, MP in pairs(self.g_MPInfo) do
            if key == MP["key"] then
                self:MsgBox(selfId, targetId, MP["des"])
                self:CallScriptFunction(define.SCENE_SCRIPT_ID, "AskTheWay", selfId, MP["x"], MP["z"], MP["npc"])
                break
            end
        end
    end
end
function edali_0241:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:GetLevel(selfId) >= 10 and self:GetMenPai(selfId) == ScriptGlobal.MP_WUMENPAI then
        caller:AddNumTextWithTarget(self.script_id, "Ta phải làm sao để đến được Cửu Đại Môn phái?", 11, 1010)
    end
end
function edali_0241:CheckAccept(selfId)
end
function edali_0241:OnAccept(selfId)
end
function edali_0241:OnAbandon(selfId)
end
function edali_0241:OnContinue(selfId, targetId)
end
function edali_0241:CheckSubmit(selfId)
end
function edali_0241:OnSubmit(selfId, targetId, selectRadioId)
end
function edali_0241:OnKillObject(selfId, objdataId, objId)
end
function edali_0241:OnEnterArea(selfId, zoneId)
end
function edali_0241:OnItemChanged(selfId, itemdataId)
end
function edali_0241:MsgBox(selfId, targetId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end
return edali_0241