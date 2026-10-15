local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_ouyeyu = class("osuzhou_ouyeyu", script_base)
osuzhou_ouyeyu.script_id = 001085
function osuzhou_ouyeyu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{SQSJ_0708_08}")
    self:AddNumText("神器炼魂", 6, 1)
    self:AddNumText("Thần Khí Tu Lý", 6, 2)
    self:AddNumText("Thần khí thăng tinh", 6, 3)
    self:AddNumText("Tẩy luyện thần khí", 6, 4)
    self:AddNumText("Về Luyện Hồn Thần Khí", 11, 22)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_ouyeyu:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(0)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 19831114)
    end
    if index == 2 then
        self:BeginUICommand()
        self:UICommand_AddInt(-1)
        self:UICommand_AddInt(-1)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 101526358)
        return
    end
    if index == 3 then
        self:BeginUICommand()
        self:UICommand_AddInt(-1)
        self:UICommand_AddInt(-1)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 89310001)
        return
    end
    if index == 4 then
        self:BeginUICommand()
        self:UICommand_AddInt(-1)
        self:UICommand_AddInt(-1)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 89310002)
        return
    end
    if index == 22 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SQSJ_0708_01}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 33 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SQSX_120806_46}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 44 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SQSX_120806_47}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
end

function osuzhou_ouyeyu:NotifysTip(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function osuzhou_ouyeyu:DoSuperDecorateWeapon(selfId, nPos, Select)
    if Select < 0 then
        return
    end
    if nPos < 0 or nPos == nil then
        return
    end
    local nItemId = self:LuaFnGetItemTableIndexByIndex(selfId, nPos)
    local DecorateID = self:GetDecoWeaponMsg(nItemId, Select)
    if DecorateID == -1 then
        self:NotifysTip(selfId, "Xin chọn ảo sức ngoại hình muốn đổi.")
        return
    end
    local nMoneyJB = self:GetMoney(selfId)
    if nMoneyJB < 50000000 then
        self:NotifysTip(selfId, "Không đủ tiền, không ảo sức được")
        return
    end
    self:AddMoney(selfId, -50000000)
    self:LuaFnSetEquipVisual(selfId, nPos, DecorateID)
    self:NotifysTip(selfId, "Đổi ngoại hình thành công")
end

function GetDecoWeaponMsg(ItemID, Select)
    local DecoWeaponMsg = {
        [10300100] = {946, 1398, 713, 936, 668, 646},
        [10300101] = {956, 1399, 713, 936, 667, 646},
        [10300102] = {966, 1400, 713, 936, 669, 646},
        [10300103] = {946, 1398, 713, 936, 668, 646},
        [10300104] = {956, 1399, 713, 936, 667, 646},
        [10300105] = {966, 1400, 713, 936, 669, 646},
        [10300106] = {946, 1398, 713, 936, 668, 646},
        [10300107] = {956, 1399, 713, 936, 667, 646},
        [10300108] = {966, 1400, 713, 936, 669, 646},
        [10300109] = {946, 1398, 713, 936, 668, 646},
        [10300110] = {956, 1399, 713, 936, 667, 646},
        [10300111] = {966, 1400, 713, 936, 669, 646},
        [10301100] = {942, 1401, 709, 932, 665, 646},
        [10301101] = {952, 1402, 709, 932, 664, 646},
        [10301102] = {962, 1403, 709, 932, 666, 646},
        [10301103] = {942, 1401, 709, 932, 665, 646},
        [10301104] = {952, 1402, 709, 932, 664, 646},
        [10301105] = {962, 1403, 709, 932, 666, 646},
        [10301106] = {942, 1401, 709, 932, 665, 646},
        [10301107] = {952, 1402, 709, 932, 664, 646},
        [10301108] = {962, 1403, 709, 932, 666, 646},
        [10301109] = {942, 1401, 709, 932, 665, 646},
        [10301110] = {952, 1402, 709, 932, 664, 646},
        [10301111] = {962, 1403, 709, 932, 666, 646},
        [10301200] = {944, 1395, 711, 934, 689, 646},
        [10301201] = {954, 1396, 711, 934, 688, 646},
        [10301202] = {964, 1397, 711, 934, 690, 646},
        [10301203] = {944, 1395, 711, 934, 689, 646},
        [10301204] = {954, 1396, 711, 934, 688, 646},
        [10301205] = {964, 1397, 711, 934, 690, 646},
        [10301206] = {944, 1395, 711, 934, 689, 646},
        [10301207] = {954, 1396, 711, 934, 688, 646},
        [10301208] = {964, 1397, 711, 934, 690, 646},
        [10301209] = {944, 1395, 711, 934, 689, 646},
        [10301210] = {954, 1396, 711, 934, 688, 646},
        [10301211] = {964, 1397, 711, 934, 690, 646},
        [10302100] = {947, 1404, 714, 937, 673, 647},
        [10302101] = {957, 1405, 714, 937, 674, 647},
        [10302102] = {967, 1406, 714, 937, 675, 647},
        [10302103] = {947, 1404, 714, 937, 673, 647},
        [10302104] = {957, 1405, 714, 937, 674, 647},
        [10302105] = {967, 1406, 714, 937, 675, 647},
        [10302106] = {947, 1404, 714, 937, 673, 647},
        [10302107] = {957, 1405, 714, 937, 674, 647},
        [10302108] = {967, 1406, 714, 937, 675, 647},
        [10302109] = {947, 1404, 714, 937, 673, 647},
        [10302110] = {957, 1405, 714, 937, 674, 647},
        [10302111] = {967, 1406, 714, 937, 675, 647},
        [10303100] = {929, 1407, 717, 940, 670, 647},
        [10303101] = {930, 1408, 717, 940, 671, 647},
        [10303102] = {931, 1409, 717, 940, 672, 647},
        [10303103] = {929, 1407, 717, 940, 670, 647},
        [10303104] = {930, 1408, 717, 940, 671, 647},
        [10303105] = {931, 1409, 717, 940, 672, 647},
        [10303106] = {929, 1407, 717, 940, 670, 647},
        [10303107] = {930, 1408, 717, 940, 671, 647},
        [10303108] = {931, 1409, 717, 940, 672, 647},
        [10303109] = {929, 1407, 717, 940, 670, 647},
        [10303110] = {930, 1408, 717, 940, 671, 647},
        [10303111] = {931, 1409, 717, 940, 672, 647},
        [10303200] = {943, 1410, 710, 933, 676, 647},
        [10303201] = {953, 1411, 710, 933, 677, 647},
        [10303202] = {963, 1412, 710, 933, 678, 647},
        [10303203] = {943, 1410, 710, 933, 676, 647},
        [10303204] = {953, 1411, 710, 933, 677, 647},
        [10303205] = {963, 1412, 710, 933, 678, 647},
        [10303206] = {943, 1410, 710, 933, 676, 647},
        [10303207] = {953, 1411, 710, 933, 677, 647},
        [10303208] = {963, 1412, 710, 933, 678, 647},
        [10303209] = {943, 1410, 710, 933, 676, 647},
        [10303210] = {953, 1411, 710, 933, 677, 647},
        [10303211] = {963, 1412, 710, 933, 678, 647},
        [10304100] = {945, 1419, 712, 935, 686, 649},
        [10304101] = {955, 1420, 712, 935, 685, 649},
        [10304102] = {965, 1421, 712, 935, 687, 649},
        [10304103] = {945, 1419, 712, 935, 686, 649},
        [10304104] = {955, 1420, 712, 935, 685, 649},
        [10304105] = {965, 1421, 712, 935, 687, 649},
        [10304106] = {945, 1419, 712, 935, 686, 649},
        [10304107] = {955, 1420, 712, 935, 685, 649},
        [10304108] = {965, 1421, 712, 935, 687, 649},
        [10304109] = {945, 1419, 712, 935, 686, 649},
        [10304110] = {955, 1420, 712, 935, 685, 649},
        [10304111] = {965, 1421, 712, 935, 687, 649},
        [10305100] = {949, 1413, 716, 939, 679, 648},
        [10305101] = {959, 1414, 716, 939, 680, 648},
        [10305102] = {969, 1415, 716, 939, 681, 648},
        [10305103] = {949, 1413, 716, 939, 679, 648},
        [10305104] = {959, 1414, 716, 939, 680, 648},
        [10305105] = {969, 1415, 716, 939, 681, 648},
        [10305106] = {949, 1413, 716, 939, 679, 648},
        [10305107] = {959, 1414, 716, 939, 680, 648},
        [10305108] = {969, 1415, 716, 939, 681, 648},
        [10305109] = {949, 1413, 716, 939, 679, 648},
        [10305110] = {959, 1414, 716, 939, 680, 648},
        [10305111] = {969, 1415, 716, 939, 681, 648},
        [10302200] = {951, 1422, 718, 941, 721, 647},
        [10302201] = {961, 1423, 718, 941, 720, 647},
        [10302202] = {971, 1424, 718, 941, 719, 647},
        [10302203] = {951, 1422, 718, 941, 721, 647},
        [10302204] = {961, 1423, 718, 941, 720, 647},
        [10302205] = {971, 1424, 718, 941, 719, 647},
        [10302206] = {951, 1422, 718, 941, 721, 647},
        [10302207] = {961, 1423, 718, 941, 720, 647},
        [10302208] = {971, 1424, 718, 941, 719, 647},
        [10302209] = {951, 1422, 718, 941, 721, 647},
        [10302210] = {961, 1423, 718, 941, 720, 647},
        [10302211] = {971, 1424, 718, 941, 719, 647},
        [10305200] = {948, 1416, 715, 938, 683, 648},
        [10305201] = {958, 1417, 715, 938, 682, 648},
        [10305202] = {968, 1418, 715, 938, 684, 648},
        [10305203] = {948, 1416, 715, 938, 683, 648},
        [10305204] = {958, 1417, 715, 938, 682, 648},
        [10305205] = {968, 1418, 715, 938, 684, 648},
        [10305206] = {948, 1416, 715, 938, 683, 648},
        [10305207] = {958, 1417, 715, 938, 682, 648},
        [10305208] = {968, 1418, 715, 938, 684, 648},
        [10305209] = {948, 1416, 715, 938, 683, 648},
        [10305210] = {958, 1417, 715, 938, 682, 648},
        [10305211] = {968, 1418, 715, 938, 684, 648}
    }

    if DecoWeaponMsg[ItemID] ~= nil then
        return DecoWeaponMsg[ItemID][Select]
    end
    return -1
end

function osuzhou_ouyeyu:DoSuperWeapon9Up(selfId, nPos)
    if nPos == nil or nPos < 0 then
        return
    end
    local tableIndex = self:LuaFnGetItemTableIndexByIndex(selfId, nPos)
    if tableIndex < 10300000 or tableIndex > 10399999 then
        self:NotifysTip(selfId, "Trang bị này không thăng sao được.")
        return
    end
    local nMoneyJB = self:GetMoney(selfId)
    if nMoneyJB < 200000 then
        self:NotifysTip(selfId, "Không đủ tiền, không thăng cấp thần khí được.")
        return
    end
    local Qula = self:GetBagItemQuality(selfId, nPos)
    if Qula >= 9 then
        self:NotifysTip(selfId, "Thần khí này đã sao tối đa, không thăng tiếp được.")
        return
    end
    if Qula < 5 then
        self:NotifysTip(selfId, "Phẩm chất thần khí không đủ, không thăng sao được.")
        return
    end
    local needNum = 0
    if Qula == 5 then
        needNum = 200
    elseif Qula == 6 then
        needNum = 500
    elseif Qula == 7 then
        needNum = 800
    elseif Qula == 8 then
        needNum = 1200
    end
    local Have = self:LuaFnGetAvailableItemCount(selfId, 30505821)
    if Have < needNum then
        self:NotifysTip(selfId, string.format("Thăng sao thần khí này cần %s cái %s.", needNum, self:GetItemName(30505821)))
        return
    end
    self:CostMoney(selfId, 200000)
    if not self:LuaFnDelAvailableItem(selfId, 30505821, needNum) then
        return
    end
    -- 设置品质并刷新客户端装备显示
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_prop_bag_container()
    local item = container:get_item(nPos)
    local equip_data = item:get_equip_data()
    equip_data:set_quality(Qula + 1)
    local packet_def = require "game.packet"  -- [audit 2026-09-11] module "packet_def" khong ton tai
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = nPos
    msg.item = item:copy_raw_data()
    self.scene:send2client(obj, msg)
    -- 全服公告
    local transfer = self:GetBagItemTransfer(selfId, nPos)
    local str =
        string.format("#{_INFOUSR%s}#Pluôn dùng một thần khí, nên tại chỗ#YÂu Trị Vu#Pqua tiến giai thần khí nhận được#{_INFOMSG%s}#P", self:GetName(selfId), transfer)
    self:BroadMsgByChatPipe(selfId, str, 4)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 148, 0)
end

return osuzhou_ouyeyu
