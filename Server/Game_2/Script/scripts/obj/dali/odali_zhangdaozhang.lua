local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_zhangdaozhang = class("odali_zhangdaozhang", script_base)
odali_zhangdaozhang.script_id = 002075
odali_zhangdaozhang.g_Ability = {}

odali_zhangdaozhang.g_Ability["aid"] = 39
odali_zhangdaozhang.g_Ability["nam"] = "Chỉ Xích Thiên Nhai"
odali_zhangdaozhang.g_Ability["gld"] = 300000
odali_zhangdaozhang.g_LevMax = 3
odali_zhangdaozhang.g_Key = {}

odali_zhangdaozhang.g_Key["nul"] = 0
odali_zhangdaozhang.g_Key["stu"] = 1
odali_zhangdaozhang.g_Key["sty"] = 101
odali_zhangdaozhang.g_Key["stn"] = 100
odali_zhangdaozhang.g_Key["lup"] = 2
odali_zhangdaozhang.g_Key["upy"] = 201
odali_zhangdaozhang.g_Key["upn"] = 200
odali_zhangdaozhang.g_Key["des"] = 3
function odali_zhangdaozhang:OnDefaultEvent(selfId, targetId)
    local lev = self:QueryHumanAbilityLevel(selfId, self.g_Ability["aid"])
    self:BeginEvent(self.script_id)
    self:AddText("  Ta có thể truyền thụ cho ngươi một loại Kỹ năng thần kỳ, lợi dụng Kỹ năng này chế tác ra phù văn có thể ghi lại vị trí thông tin, sau này ngươi muốn trở lại địa phương đã ghi lại này, chỉ cần sử dụng phù văn là được.")
    self:AddText("  Xin chú ý, phù văn càng Cao cấp thì số lần có thể sử dụng cũng càng nhiều.")
    if self:GetLevel(selfId) >= 30 then
        if lev <= 0 then
            self:AddNumText("Học tập" .. self.g_Ability["nam"], 6, self.g_Key["stu"])
        else
            self:AddNumText("Thăng cấp Kỹ năng", 6, self.g_Key["lup"])
        end
        self:AddNumText("Cái gì cũng không làm", -1, self.g_Key["nul"])
    end
    self:AddNumText("Định vị phù tửu quán", 11, self.g_Key["des"])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_zhangdaozhang:OnEventRequest(selfId, targetId, arg, index)
    local key = index
    local lev = self:QueryHumanAbilityLevel(selfId, self.g_Ability["aid"])
    local exp = self:GetAbilityExp(selfId, self.g_Ability["aid"])
    local ret, demandMoney, _, limitAbilityExp, limitAbilityExpShow, _, limitLevel =
        self:LuaFnGetAbilityLevelUpConfig(self.g_Ability["aid"], lev + 1)
    if key == self.g_Key["des"] then
        self:MsgBox(selfId, targetId, "#{function_help_020}")
    elseif key == self.g_Key["stu"] then
        if self:GetLevel(selfId) < 30 then
            return 0
        end
        self:OnAsk(selfId, targetId, self.g_Key["stu"], "  Ngươi học Kỹ năng này Yêu cầu tiêu hao #{_EXCHG" .. demandMoney .. "}, có muốn tiếp tục không?")
    elseif key == self.g_Key["sty"] then
        if self:GetLevel(selfId) < 30 then
            return 0
        end
        if lev > 0 then
            self:MsgBox(selfId, targetId, "  Ngươi đã học Kỹ năng này rồi!")
            return 0
        end
        if self:LuaFnGetMoney(selfId) + self:GetMoneyJZ(selfId) < demandMoney then
            self:MsgBox(selfId, targetId, "  Tiền bạc của ngươi không đủ, không thể học Kỹ năng này!")
            return 0
        end
        self:LuaFnCostMoneyWithPriority(selfId, demandMoney)
        self:SetHumanAbilityLevel(selfId, self.g_Ability["aid"], 1)
        self:SetMyPrescription(selfId, 1)
        self:MsgBox(selfId, targetId, "  Chúc mừng ngài đã học được" .. self.g_Ability["nam"] .. ", nhưng nếu muốn chế tạo Định Vị Phù có số lần sử dụng nhiều hơn, xin hãy Thăng cấp Kỹ năng của ngài.")
    elseif key == self.g_Key["lup"] then
        if self:GetLevel(selfId) < 30 then
            return 0
        end
        if lev >= self.g_LevMax then
            self:MsgBox(selfId, targetId, "  Cấp độ Kỹ năng của ngài đã đủ, không Yêu cầu Thăng cấp thêm nữa.")
            return 0
        end
        self:OnAsk(selfId, targetId, self.g_Key["lup"], "  Ngươi Thăng cấp Kỹ năng này Yêu cầu tiêu hao #{_EXCHG" .. demandMoney .. "}, có muốn tiếp tục không?")
    elseif key == self.g_Key["upy"] then
        if ret ~= 1 then
            return 0
        end
        if self:GetLevel(selfId) < 30 then
            return 0
        end
        if lev < 1 then
            self:MsgBox(selfId, targetId, "  Ngươi vẫn chưa học" .. self.g_Ability["nam"] .. ", đợi học xong Kỹ năng cấp 1 rồi hãy tìm ta Thăng cấp nhé.")
            return 0
        end
        if lev >= self.g_LevMax then
            self:MsgBox(selfId, targetId, "  Cấp độ Kỹ năng của ngài đã đủ, không Yêu cầu Thăng cấp thêm nữa.")
            return 0
        end
        if exp < limitAbilityExp then
            self:MsgBox(selfId, targetId, "  Cần" .. limitAbilityExpShow .. "Cần điểm thuần thục để có thể Thăng cấp lần nữa.")
            return 0
        end
        if self:LuaFnGetMoney(selfId) + self:GetMoneyJZ(selfId) < demandMoney then
            self:MsgBox(selfId, targetId, "  Yêu cầu#{_EXCHG" .. demandMoney .. "} mới có thể Thăng cấp lần nữa.")
            return 0
        end
        self:LuaFnCostMoneyWithPriority(selfId, demandMoney)
        self:SetHumanAbilityLevel(selfId, self.g_Ability["aid"], lev + 1)
        self:SetMyPrescription(selfId, lev + 1)
        self:MsgBox(selfId, targetId, "  Kỹ năng của ngài đã Thăng cấp thành công, chúc mừng ngài có thể chế tạo phù văn Cao cấp hơn rồi.")
    else
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
    end
    return 1
end

function odali_zhangdaozhang:SetMyPrescription(selfId, lev)
    for i = 0, 5 do
        self:SetPrescription(selfId, 510 + (lev - 1) * 6 + i, 1)
    end
end

function odali_zhangdaozhang:OnAsk(selfId, targetId, key, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:AddNumText("là", -1, key * 100 + 1)
    self:AddNumText("không", -1, key * 100)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_zhangdaozhang:MsgBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return odali_zhangdaozhang
