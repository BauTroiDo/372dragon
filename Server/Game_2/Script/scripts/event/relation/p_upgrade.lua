local class = require "class"
local define = require "define"
local script_base = require "script_base"
local p_upgrade = class("p_upgrade", script_base)
p_upgrade.script_id = 806015
p_upgrade.g_Update = {}

p_upgrade.g_Update["id"] = 1000
p_upgrade.g_Update["wu"] = 1001
p_upgrade.g_Update["uw"] = 1002
p_upgrade.g_msg = {}

p_upgrade.g_msg["up"] = "Ta muốn tăng Cấp độ Sư Đức của ta"
p_upgrade.g_msg["un"] = "  Sư đức Cấp độ của ngươi đã đạt tối cao, không thể thăng tiến thêm nữa."
p_upgrade.g_msg["nv"] = "  Thiện ác giá trị của ngươi không đủ, không thể thăng tiến."
p_upgrade.g_msg["uc"] = "  Thăng tiến đến A cần dùng B điểm thiện ác giá trị."
p_upgrade.g_msg["wu"] = "Ta muốn tăng Cấp độ Sư Đức của ta"
p_upgrade.g_msg["uw"] = "Ta vẫn là không muốn thăng tiến nữa."
p_upgrade.g_msg["ul"] = "  Chỉ có Cấp độ lớn hơn cấp 20 mới có tư cách xin danh hiệu sư phụ."
p_upgrade.g_Title = {}

p_upgrade.g_Title[1] = "Sư phụ Sơ Cấp"
p_upgrade.g_Title[2] = "Sư phụ Trung Cấp"
p_upgrade.g_Title[3] = "Cao cấp sư phụ"
p_upgrade.g_Title[4] = "Nhất Đại Danh Sư"
function p_upgrade:OnDefaultEvent(selfId, targetId, index)
    local key = index
    if key == self.g_Update["id"] then
        self:Upgrade(selfId, targetId)
        return 0
    end
    if key == self.g_Update["wu"] then
        if self:DoUpgrade(selfId, targetId) == 0 then
            return 0
        end
        local msg = "Sư đức Cấp độ của ngài thăng tiến đến" .. tostring(self:LuaFnGetmasterLevel(selfId) .. "cấp.")
        self:MessageBox(selfId, targetId, "  " .. msg)
        self:Msg2Player(selfId, msg, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        return 0
    end
    if key == self.g_Update["uw"] then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
    end
end

function p_upgrade:OnEnumerate(caller)
    caller:AddNumTextWithTarget(self.script_id, self.g_msg["up"], 6, self.g_Update["id"])
end

function p_upgrade:CheckAccept(selfId, targetId)
end

function p_upgrade:OnAccept(selfId, targetId)
    self:OnConfirm(selfId, targetId)
end

function p_upgrade:OnSubmit(selfId, targetId, tId)
end

function p_upgrade:OnCancel(selfId, targetId)
end

function p_upgrade:MessageBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function p_upgrade:Upgrade(selfId, targetId)
    local HumanLevel = self:LuaFnGetLevel(selfId)
    local level = self:LuaFnGetmasterLevel(selfId)
    if HumanLevel < 20 then
        self:MessageBox(selfId, targetId, self.g_msg["ul"])
        return 0
    end
    if level >= 4 then
        self:MessageBox(selfId, targetId, self.g_msg["un"])
        return 0
    end
    local exp = 0
    if level == 0 and HumanLevel < 60 then
        exp = 500
    elseif level == 1 then
        exp = 5000
    elseif level == 2 then
        exp = 25000
    elseif level == 3 then
        exp = 50000
    end
    local text = "  Đưa Sư Đức Cấp độ lên đến" .. tostring(level + 1) .. "cấp, sẽ tiêu hao Thiện Ác Giá trị." .. tostring(exp) .. "Chấm."
    self:BeginEvent(self.script_id)
    self:AddText(text)
    self:AddNumText(self.g_msg["wu"], 6, self.g_Update["wu"])
    self:AddNumText(self.g_msg["uw"], 8, self.g_Update["uw"])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
    return 1
end

function p_upgrade:DoUpgrade(selfId, targetId)
    local HumanLevel = self:LuaFnGetLevel(selfId)
    local level = self:LuaFnGetmasterLevel(selfId)
    if level >= 4 then
        return 0
    end
    local exp = 0
    if level == 0 and HumanLevel < 60 then
        exp = 500
    elseif level == 1 then
        exp = 5000
    elseif level == 2 then
        exp = 25000
    elseif level == 3 then
        exp = 50000
    end
    local gbvalue = self:LuaFnGetHumanGoodBadValue(selfId)
    if gbvalue < exp then
        local msg = "  Thiện Ác Giá trị của ngài không đủ, Thiện Ác Giá trị hiện tại của ngài là" .. tostring(gbvalue) .. "。"
        self:MessageBox(selfId, targetId, msg)
        return 0
    end
    level = level + 1
    self:LuaFnSetmasterLevel(selfId, level)
    gbvalue = gbvalue - exp
    self:LuaFnSetHumanGoodBadValue(selfId, gbvalue)
    self:AwardMasterTitle(selfId, self.g_Title[level])
    self:DispatchAllTitle(selfId)
    self:SetCurTitle(selfId, 27, 0)
    local nam = self:GetName(selfId)
    local str = string.format("#IChúc mừng#W#{_INFOUSR%s}#Ithành công nhận được#G%s#Icủadanh hiệu, giờ có thể thu Khác người chơi làm đồ đệ rồi.", nam, self.g_Title[level])
    self:AddGlobalCountNews(str)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
    return level
end

return p_upgrade
