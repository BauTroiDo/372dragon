local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogaibang_zhangquanxiang = class("ogaibang_zhangquanxiang", script_base)
ogaibang_zhangquanxiang.script_id = 010008
ogaibang_zhangquanxiang.g_xuanWuDaoId = 400918
ogaibang_zhangquanxiang.g_mpInfo = {}

ogaibang_zhangquanxiang.g_mpInfo[0] = {"星宿", 16, 96, 152, define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU}

ogaibang_zhangquanxiang.g_mpInfo[1] = {"逍遥", 14, 67, 145, define.MENPAI_ATTRIBUTE.MATTRIBUTE_XIAOYAO}

ogaibang_zhangquanxiang.g_mpInfo[2] = {"少林", 9, 95, 137, define.MENPAI_ATTRIBUTE.MATTRIBUTE_SHAOLIN}

ogaibang_zhangquanxiang.g_mpInfo[3] = {"天山", 17, 95, 120, define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN}

ogaibang_zhangquanxiang.g_mpInfo[4] = {"天龙", 13, 96, 120, define.MENPAI_ATTRIBUTE.MATTRIBUTE_DALI}

ogaibang_zhangquanxiang.g_mpInfo[5] = {"Nga Mi", 15, 89, 144, define.MENPAI_ATTRIBUTE.MATTRIBUTE_EMEI}

ogaibang_zhangquanxiang.g_mpInfo[6] = {"武当", 12, 103, 140, define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUDANG}

ogaibang_zhangquanxiang.g_mpInfo[7] = {"明教", 11, 98, 167, define.MENPAI_ATTRIBUTE.MATTRIBUTE_MINGJIAO}

ogaibang_zhangquanxiang.g_mpInfo[8] = {"丐帮", 10, 91, 116, define.MENPAI_ATTRIBUTE.MATTRIBUTE_GAIBANG}

function ogaibang_zhangquanxiang:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{MPXL_090113_06}")
    if self:GetLevel(selfId) >= 10 then
        self:AddNumText("Lạc Dương", 9, 0)
        self:AddNumText("Tô Châu", 9, 1)
        self:AddNumText("Lạc Dương - Cửu Châu Thương hội", 9, 3)
        self:AddNumText("Tô Châu - Tiệm Thợ rèn", 9, 4)
    end
    if self:GetLevel(selfId) >= 20 then
        self:AddNumText("束河古镇", 9, 6)
    end
    if self:GetLevel(selfId) >= 75 then
        self:AddNumText("#{MPCSLL_80925_01}", 9, 5)
    end
    self:AddNumText("Đại Lý", 9, 2)
    self:CallScriptFunction(self.g_xuanWuDaoId, "OnEnumerate", self, selfId, targetId)
    self:AddNumText("Đưa ta đến Khác Môn phái đi", 9, 11)
    self:AddNumText("Ta phải làm sao mới có thể đến Đôn Hoàng và Tung Sơn?", 11, 2000)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ogaibang_zhangquanxiang:OnEventRequest(selfId, targetId, arg, index)
    if index == self.g_xuanWuDaoId then
        self:CallScriptFunction(self.g_xuanWuDaoId, "OnDefaultEvent", selfId, targetId)
        return
    end
    if index == 2000 then
        self:BeginEvent(self.script_id)
        self:AddText("#{GOTO_DUNHUANF_SONGSHAN}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 11 then
        self:BeginEvent(self.script_id)
        for i = 0, 8 do
            self:AddNumText("Môn phái - " .. self.g_mpInfo[i][1], 9, i + 12)
        end
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    local num = index
    if num > 11 then
        if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, 113) == 1 then
            self:BeginEvent(self.script_id)
            self:AddText("  Đang trong Trạng thái Vận Tiêu, Chạy Thương hội thì không thể truyền tống từ chỗ ta được")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        local i = num - 12
        self:CallScriptFunction(
            (400900),
            "TransferFuncFromNpc",
            selfId,
            self.g_mpInfo[i][2],
            self.g_mpInfo[i][3],
            self.g_mpInfo[i][4]
        )
        return
    end
    if index == 0 then
        self:CallScriptFunction((400900), "TransferFuncFromNpc", selfId, 0, 235, 322, 10)
    elseif index == 1 then
        self:CallScriptFunction((400900), "TransferFuncFromNpc", selfId, 1, 204, 256, 10)
    elseif index == 3 then
        self:CallScriptFunction((400900), "TransferFuncFromNpc", selfId, 0, 326, 269, 10)
    elseif index == 4 then
        self:CallScriptFunction((400900), "TransferFuncFromNpc", selfId, 1, 335, 225, 10)
    elseif index == 2 then
        self:CallScriptFunction((400900), "TransferFuncFromNpc", selfId, 2, 253, 121)
    elseif index == 5 then
        self:CallScriptFunction((400900), "TransferFuncFromNpc", selfId, 186, 288, 136, 75)
    end
    if index == 6 then
        self:BeginUICommand()
        self:UICommand_AddInt(self.g_scriptId)
        self:UICommand_AddInt(targetId)
        self:UICommand_AddStr("GotoShuHeGuZhen")
        self:UICommand_AddStr("Thúc Hà Cổ Trấn là cảnh không tăng sát khí, xin hãy chú ý an toàn. Ngươi đã xác nhận muốn tiến vào chưa?")
        self:EndUICommand()
        self:DispatchUICommand(selfId, 24)
        return
    end
end

function ogaibang_zhangquanxiang:GotoShuHeGuZhen(selfId, targetId)
    self:CallScriptFunction((400900), "TransferFuncFromNpc", selfId, 420, 200, 211, 20)
    return
end

return ogaibang_zhangquanxiang
