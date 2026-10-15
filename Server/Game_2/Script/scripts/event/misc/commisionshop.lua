local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local commisionshop = class("commisionshop", script_base)
commisionshop.script_id = 800116
commisionshop.g_CShopInfo = {
    [0] = {
        ["name"] = "#GLạc Dương (160, 181)#RĐinh Đinh",
        ["type"] = {
            [0] = {
                ["name"] = "Nguyên bảo",
                ["sellFmtValueStr"] = "#G%d điểm Nguyên bảo#l",
                ["sellFmtPriceStr"] = "#G#{_MONEY%d}#l",
                ["sellInfo"] = "#GTa muốn mua Nguyên bảo#l",
                ["buyFmtValueStr"] = "%d điểm Nguyên bảo",
                ["buyFmtPriceStr"] = "#{_MONEY%d}"
            },
            [1] = {
                ["name"] = "金币",
                ["sellFmtValueStr"] = "#G#{_MONEY%d}#l",
                ["sellFmtPriceStr"] = "#G%d điểm Nguyên bảo#l",
                ["sellInfo"] = "#GTa muốn mua tiền vàng#l",
                ["buyFmtValueStr"] = "#{_MONEY%d}",
                ["buyFmtPriceStr"] = "%d điểm Nguyên bảo"
            }
        }
    },
    [1] = {
        ["name"] = "#GLạc Dương(158,181)#RĐông Đông",
        ["type"] = {
            [0] = {
                ["name"] = "Nguyên bảo",
                ["sellFmtValueStr"] = "#G%d điểm Nguyên bảo#l",
                ["sellFmtPriceStr"] = "#G#{_MONEY%d}#l",
                ["sellInfo"] = "#GTa muốn mua Nguyên bảo#l",
                ["buyFmtValueStr"] = "%d điểm Nguyên bảo",
                ["buyFmtPriceStr"] = "#{_MONEY%d}"
            },
            [1] = {
                ["name"] = "金币",
                ["sellFmtValueStr"] = "#G#{_MONEY%d}#l",
                ["sellFmtPriceStr"] = "#G%d điểm Nguyên bảo#l",
                ["sellInfo"] = "#GTa muốn mua tiền vàng#l",
                ["buyFmtValueStr"] = "#{_MONEY%d}",
                ["buyFmtPriceStr"] = "%d điểm Nguyên bảo"
            }
        }
    }
}

function commisionshop:OnEnumerate(caller, selfId, targetId, arg, index)
    caller:AddNumTextWithTarget(self.script_id, "Ta muốn mua Nguyên bảo.", 5, 2)
    if not self:IsShutout(selfId, ScriptGlobal.ONOFF_T_CSHOP) then
        if not self:GetConfigInfo("IsCloseYuanBaoSell") then
            caller:AddNumTextWithTarget(self.script_id, "Ta muốn ký bán Nguyên bảo.", 5, 3)
        end
    end
    caller:AddNumTextWithTarget(self.script_id, "Thu Nguyên bảo hoặc Kim tệ.", 5, 6)
    caller:AddNumTextWithTarget(self.script_id, "Thu phí giới thiệu", 11, 7)
    caller:AddNumTextWithTarget(self.script_id, "Giới thiệu Ký Bán", 11, 5)
end

function commisionshop:OnDefaultEvent(selfId, targetId, arg, eventId)
    local opt = eventId
    if opt == 1 then
        self:OpenShop(selfId, targetId, 3)
        return
    elseif opt == 2 then
        self:OpenShop(selfId, targetId, 0)
        return
    elseif opt == 3 or opt == 4 then
        local _yes = self:LuaFnOpenPWBox(selfId)
        if (_yes == 1) then
            return
        end
    elseif opt == 5 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_095}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    elseif opt == 6 then
        self:LuaFnAskNpcScriptMail(selfId, ScriptGlobal.MAIL_COMMISIONSHOP)
        return
    elseif opt == 7 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_099}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    local UserName = self:GetName(selfId)
    local i = string.find(UserName, "*")
    if i == nil then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(opt)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 19850424)
    else
        self:BeginEvent(self.script_id)
        self:AddText("Tên ngài có chứa \"*\", Yêu cầu đổi tên trước mới có thể sử dụng chức năng ký gửi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
    return
end

function commisionshop:OpenShop(selfId, targetId, Grade)
    self:GetCommisionShop(selfId, targetId, Grade)
end

function commisionshop:Buy(selfId, targetId, Grade, SerialNumber)
    local ret, shopId, type, value, price, seller = self:CommisionShopBuy(selfId, targetId, Grade, SerialNumber)
    if ret then
        if self.g_CShopInfo[shopId] and self.g_CShopInfo[shopId]["type"][type] and self.g_CShopInfo[shopId]["name"] then
            local typeInfo = self.g_CShopInfo[shopId]["type"][type]
            local nameInfo = self.g_CShopInfo[shopId]["name"]
            local strGUID = self:LuaFnGetGUID(selfId)
            local len = string.len(strGUID)
            strGUID = string.sub(strGUID, len - 3)
            local str = string.format("#INgười nào đó[ID:****%s] tại #R%s#I đã dùng #Y%s#I để mua #Y%s#I.", strGUID,
                nameInfo, typeInfo["buyFmtPriceStr"], typeInfo["buyFmtValueStr"])
            str = string.format(str, price, value)
            str = gbk.fromutf8(str)
            self:BroadMsgByChatPipe(selfId, str, 4)
            local sellstr = string.format(
                "%s ký gửi của ngài đã #Ybán thành công#W, xin hãy tìm NPC ký gửi để chọn \"nhận Nguyên bảo hoặc vàng\" để nhận Nguyên bảo hoặc vàng của ngài.#r#GChú ý: Để bảo đảm an toàn tài sản của ngài, xin hãy cố gắng nhận Nguyên bảo và vàng của ngài trong vòng một tuần. Nếu sau một tuần ngài vẫn chưa nhận, Nguyên bảo hoặc vàng có thể bị mất.",
                typeInfo["buyFmtValueStr"])
            sellstr = string.format(sellstr, value)
            self:LuaFnSendSystemMail(seller, sellstr)
            self:GetCommisionShop(selfId, targetId, Grade)
        end
    end
end

function commisionshop:Sell(selfId, targetId, Grade, Price)
    if true then
        self:notify_tips(selfId, "Chức năng ký gửi tạm đóng")
        return
    end
    local ret, shopId, type, value, price = self:CommisionShopSell(selfId, targetId, Grade, Price)
    if ret then
        if self.g_CShopInfo[shopId] and self.g_CShopInfo[shopId]["type"][type] and self.g_CShopInfo[shopId]["name"] then
            local typeInfo = self.g_CShopInfo[shopId]["type"][type]
            local nameInfo = self.g_CShopInfo[shopId]["name"]
            local strGUID = self:LuaFnGetGUID(selfId)
            local len = string.len(strGUID)
            strGUID = string.sub(strGUID, len - 3)
            local str = string.format(
                "#INgười nào đó[ID:****%s] tại #R%s#I rao bán #Y%s, #I giá bán #Y%s, #I người chơi có ý định mua xin nhanh chóng trở về #GLạc Dương#I đi.",
                strGUID, nameInfo, typeInfo["buyFmtValueStr"], typeInfo["buyFmtPriceStr"], typeInfo["sellInfo"],
                typeInfo["name"])
            str = string.format(str, value, price)
            str = gbk.fromutf8(str)
            self:BroadMsgByChatPipe(selfId, str, 4)
        end
    end
end

function commisionshop:TimeOutCommission(shopId, itemserial)
    local ret, type, value, price, seller = self:GetCommisionShopItem(shopId, itemserial)
    if ret then
        if self.g_CShopInfo[shopId] and self.g_CShopInfo[shopId]["type"][type] then
            local typeInfo = self.g_CShopInfo[shopId]["type"][type]
            local sellstr = string.format(
                "Vật phẩm ký gửi của %s#Y chưa bán được#W, xin hãy tìm đến NPC ký gửi chọn \"Thu hồi Nguyên bảo hoặc vàng\" để nhận được Nguyên bảo hoặc vàng của ngài.#r#GChú ý: Để bảo đảm an toàn tài sản của ngài, xin hãy cố gắng nhận Nguyên bảo và vàng của ngài trong vòng một tuần, nếu sau một tuần ngài vẫn chưa nhận thì Nguyên bảo hoặc vàng có thể bị mất.",
                typeInfo["buyFmtValueStr"])
            sellstr = string.format(sellstr, value)
            self:LuaFnSendSystemMail(seller, sellstr)
        end
    end
end

return commisionshop
