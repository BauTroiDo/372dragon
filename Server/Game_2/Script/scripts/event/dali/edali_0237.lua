local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_0237 = class("edali_0237", script_base)
local ScriptGlobal = require "scripts.ScriptGlobal"
edali_0237.script_id = 210237
edali_0237.g_mpInfo = {}
edali_0237.g_mpInfo[0] = { "[Thiên Long]", "#{OBJ_dali_0045}", 189, 124, "破贪", 185, 128 }
edali_0237.g_mpInfo[1] = { "[Nga My]", "#{OBJ_dali_0046}", 192, 129, "路三娘", 185, 128 }
edali_0237.g_mpInfo[2] = { "[Cái Bang]", "#{OBJ_dali_0047}", 126, 135, "简宁", 133, 130 }
edali_0237.g_mpInfo[3] = { "[Minh Giáo]", "#{OBJ_dali_0048}", 130, 121, "石宝", 133, 130 }
edali_0237.g_mpInfo[4] = { "[Thiếu Lâm]", "#{OBJ_dali_0049}", 187, 122, "慧易", 185, 128 }
edali_0237.g_mpInfo[5] = { "[Thiên Sơn]", "#{OBJ_dali_0050}", 131, 124, "程青霜", 133, 130 }
edali_0237.g_mpInfo[6] = { "[Võ Đang]", "#{OBJ_dali_0051}", 127, 131, "张获", 133, 130 }
edali_0237.g_mpInfo[7] = { "[Tiêu Dao]", "#{OBJ_dali_0052}", 188, 133, "澹台子羽", 185, 128 }
edali_0237.g_mpInfo[8] = { "[Tinh Túc]", "#{OBJ_dali_0053}", 134, 120, "海风子", 133, 130 }
edali_0237.g_mpInfo[10] = { "【Mạn Đà Sơn Trang】", "#{OBJ_dali_0056}", 156, 143, "海风子", 156, 143 }
function edali_0237:OnDefaultEvent(selfId, targetId,arg,index)
    local key = index
    local mp
    if key == 100 then
        self:BeginEvent(self.script_id)
        self:AddText("  Tìm hiểu đặc sắc của Cửu Đại Môn phái:")
        for i, mp in pairs(self.g_mpInfo) do
            self:AddNumText(mp[1], 11, i + 1)
        end
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif key >= 1 and key <= 9 then
        mp = self.g_mpInfo[key - 1]
        self:BeginEvent(self.script_id)
        self:AddText(mp[2])
        self:AddNumText("Đưa ta đi gặp Người truyền tống", 9, -1 * key)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif key >= -9 and key <= -1 then
        mp = self.g_mpInfo[-1 * key - 1]
        self:CallScriptFunction(define.SCENE_SCRIPT_ID, "AskTheWay", selfId, mp[3], mp[4], mp[5])
        self:SetPos(selfId, mp[6], mp[7])
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
    else
        return
    end
end
function edali_0237:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:GetLevel(selfId) >= 10 and self:GetMenPai(selfId) == ScriptGlobal.MP_WUMENPAI then
        caller:AddNumTextWithTarget(self.script_id,"Tìm hiểu đặc sắc của Cửu Đại Môn phái", 11, 100)
    end
end
function edali_0237:CheckAccept(selfId)
    if self:GetLevel(selfId) >= 10 and self:GetMenPai(selfId) == ScriptGlobal.MP_WUMENPAI then
        return 1
    else
        return 0
    end
end
function edali_0237:OnAccept(selfId)
end
function edali_0237:OnAbandon(selfId)
end
function edali_0237:OnContinue(selfId, targetId)
end
function edali_0237:CheckSubmit(selfId)
    return 1
end
function edali_0237:OnSubmit(selfId, targetId, selectRadioId)
end
function edali_0237:OnKillObject(selfId, objdataId)
end
function edali_0237:OnEnterZone(selfId, zoneId)
end
function edali_0237:OnItemChanged(selfId, itemdataId)
end
return edali_0237