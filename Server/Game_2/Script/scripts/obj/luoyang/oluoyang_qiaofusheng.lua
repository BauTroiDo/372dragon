local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_qiaofusheng = class("oluoyang_qiaofusheng", script_base)
oluoyang_qiaofusheng.script_id = 000109
function oluoyang_qiaofusheng:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{SHCK_090522_1}11#{SHCK_090522_2}")
    self:AddNumText("#{RCYH_180606_102}", 6, 2)
    if not self:IsShutout(selfId,3) then
        self:AddNumText("#{RCYH_180606_103}", 6, 0)
    else
        self:AddNumText("#{RCYH_180606_104}", 6, 7)
    end
    self:AddNumText("#{RCYH_180606_105}", 6, 1)
    self:AddNumText("#{RCYH_180606_106}", 6, 3)
    self:AddNumText("#{RCYH_180522_22}", 11, 6)
    self:AddNumText("#{RCYH_180522_25}", 11, 10)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_qiaofusheng:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        if self:get_scene_id() == 0 then
            self:BeginEvent(self.script_id)
            self:AddText("#{PS_OPEN_SHOP_NOTICE}")
            self:EndEvent()
            self:DispatchMissionDemandInfo(selfId, targetId, self.script_id, 0, 1)
        else
            self:BeginEvent(self.script_id)
            self:AddText("Xin tới chủ thành Lạc Dương dùng chức năng mở tiệm Cửu Châu Thương Hội")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    elseif index == 1 then
        local strShop0Name = self:LuaFnGetShopName(selfId, 1)
        local strShop1Name = self:LuaFnGetShopName(selfId, 2)
        if ((strShop0Name == "") and (strShop1Name == "")) then
            self:BeginEvent(self.script_id)
            local strText = "Xin lỗi, hình như ngươi không có tiệm."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        else
            if ((strShop0Name ~= "") and (strShop1Name ~= "")) then
                self:BeginEvent(self.script_id)
                self:AddText(
                    "Ồ ồ, thì ra là chưởng quỹ đã đến, xin hỏi ngài muốn đến tiệm nào xem qua?")
                if self:GetPlayerShopFrezeType(selfId, 0) == 1 then
                    self:AddNumText("#cCCCCCCĐiếm Phô 1  " .. strShop0Name, -1, 4)
                else
                    self:AddNumText("Tiệm buôn 1  " .. strShop0Name, -1, 4)
                end
                if self:GetPlayerShopFrezeType(selfId, 1) == 1 then
                    self:AddNumText("#cCCCCCC Tiệm buôn 2  " .. strShop1Name, -1, 5)
                else
                    self:AddNumText("Tiệm buôn 2  " .. strShop1Name, -1, 5)
                end
                self:EndEvent()
                self:DispatchEventList(selfId, targetId)
            elseif (strShop0Name ~= "") then
                self:LuaFnOpenPlayerShop(selfId, targetId, 1)
            elseif (strShop1Name ~= "") then
                self:LuaFnOpenPlayerShop(selfId, targetId, 2)
            end
        end
    elseif index == 2 then
        self:DispatchPlayerShopList(selfId, targetId)
    elseif index == 3 then
        self:DispatchPlayerShopSaleOutList(selfId, targetId)
    elseif index == 4 then
        self:LuaFnOpenPlayerShop(selfId, targetId, 1)
    elseif index == 5 then
        self:LuaFnOpenPlayerShop(selfId, targetId, 2)
    elseif index == 6 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_048}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 7 then
        local strShop0Name = self:LuaFnGetShopName(selfId, 1)
        local strShop1Name = self:LuaFnGetShopName(selfId, 2)
        if ((strShop0Name == "") and (strShop1Name == "")) then
            self:BeginEvent(self.script_id)
            local strText = "Người chơi cần có ít nhất một tiệm buôn."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        else
            self:BeginEvent(self.script_id)
            self:AddText("#{UnregisterShopHelp}")
            self:AddNumText("Xác nhận", 6, 8)
            self:AddNumText("Rời đi", 6, 9)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    elseif index == 8 then
        local canErase = self:CanErasePlayerShop(selfId)
        if (canErase) then
            self:BeginUICommand()
            self:EndUICommand()
            self:DispatchUICommand(selfId, 1000)
            self:ErasePlayerShop(selfId)
            local msg = string.format(
                            "Chúc mừng bằng hữu đã huỷ thành công, vốn liếng trong tiệm buôn đã được hoàn trả, xin hãy kiểm tra.")
            self:BeginEvent(self.script_id)
            self:AddText(msg)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            msg = string.format("Ngài đã hủy Cá nhân thương điếm thành công")
            self:BeginEvent(self.script_id)
            self:AddText(msg)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            self:BeginUICommand()
            self:EndUICommand()
            self:DispatchUICommand(selfId, 19810222)
        elseif canErase == -1 then
            local msg = string.format("Cửa hàng của bằng hữu đã bị đóng băng.")
            self:BeginEvent(self.script_id)
            self:AddText(msg)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        else
            local msg = string.format(
                            "Tiệm bạn còn tin bán hoặc thu mua đang đăng, xin dọn sạch rồi tới.")
            self:BeginEvent(self.script_id)
            self:AddText(msg)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        end
    elseif index == 9 then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
    elseif index == 10 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_101}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function oluoyang_qiaofusheng:OnMissionContinue(selfId, targetId,missionScriptId)
    self:BeginUICommand()
    self:EndUICommand()
    self:DispatchUICommand(selfId, 1000)
    self:ApplyPlayerShop(selfId, targetId)
end

return oluoyang_qiaofusheng
