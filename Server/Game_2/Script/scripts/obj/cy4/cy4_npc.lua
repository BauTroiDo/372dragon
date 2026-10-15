-- Core faction NPC behavior. Data and initial skills are owned by the live registry.
-- CYS-MENPAIJOIN (20/09): `cfg.faction` cua moi tep cy4_<phai>_*.lua la SO PHAI CY cua server rieng
-- (tangmen 11, guigu 12, taohuadao 13, congren 14) - KHONG phai so GL 13..16 cua server goc. Con so nay di
-- thang vao LuaFnJoinMenpai / GetMenPai / DispatchXinfaLevelInfo / cy_four_training_config.factions[...].
-- Dung "sua cho giong server goc": kiem bang Tools/server/menpai_join_fix.py verify.
local class = require "class"
local script_base = require "script_base"
local cy4_npc = class("cy4_npc", script_base)

function cy4_npc:Say(selfId, targetId, text)
    self:BeginEvent(self.script_id)
    self:AddText(text)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function cy4_npc:CanJoin(selfId)
    if self:GetMenPai(selfId) ~= 9 then return false, "Bạn đã gia nhập một môn phái." end
    if self:GetLevel(selfId) < 10 then return false, "Bạn cần đạt cấp 10 để bái sư." end
    return true
end

function cy4_npc:OnDefaultEvent(selfId, targetId)
    local c = self.cfg
    self:BeginEvent(self.script_id)
    if c.role == "join" then
        self:AddText("Ta là " .. c.name .. ", phụ trách tiếp nhận đệ tử " .. c.faction_name .. ".")
        if self:GetMenPai(selfId) == 9 then self:AddNumText("Gia nhập " .. c.faction_name, 6, 0) end
    elseif c.role == "xinfa_teacher" then
        self:AddText("Ta truyền dạy võ học " .. c.faction_name .. ".")
        if self:GetMenPai(selfId) == c.faction then self:AddNumText("Học tâm pháp", 12, 0) end
    elseif c.role == "outbound_travel" then
        self:AddText("Ta có thể đưa bạn trở về Đại Lý.")
        self:AddNumText("Đến Đại Lý", 9, 0)
    elseif c.role == "Dali_inbound_travel" then
        self:AddText("Ta là tiếp dẫn của " .. c.faction_name .. ".")
        self:AddNumText("Đến " .. c.faction_name, 9, 0)
    elseif c.role == "mount_manager" then
        self:AddText("Ta quản lý toạ kỵ của " .. c.faction_name .. ".")
        if self:GetMenPai(selfId) == c.faction then
            self:AddNumText("Xem toạ kỵ môn phái", 12, 40)
        end
    elseif c.role == "guide" then
        self:AddText("Ta là " .. c.name .. ", người chỉ đường của " .. c.faction_name .. ". Ngươi muốn tìm ai?")
        self:CallScriptFunction(c.sign, "OnEnumerate", self, selfId, targetId)
    elseif c.role == "qinggong_teacher" then
        self:AddText("Ta là " .. c.name .. ", truyền thụ khinh công độc môn của " .. c.faction_name .. ".")
        require("scripts.obj.cy4.cy4_training_npc").qinggong_menu(self, selfId)
    elseif c.role == "ability_teacher" then
        self:AddText("Ta là " .. c.name .. ", truyền dạy " .. c.ability_name .. " cho đệ tử " .. c.faction_name .. ".")
        require("scripts.obj.cy4.cy4_training_npc").ability_menu(self, selfId, c.ability)
    elseif c.role == "mount_guide" then
        self:AddText("Toạ kỵ của " .. c.faction_name .. " chỉ cần dùng vật phẩm là cưỡi được ngay, không phải học kỵ thuật. "
            .. "Có ba loại theo cấp 40, 60 và 80; cấp càng cao chạy càng nhanh.")
        if self:GetMenPai(selfId) == c.faction then
            self:AddNumText("Mua toạ kỵ môn phái", 12, 40)
        end
    elseif c.role == "head" or c.role == "quest_giver" or c.role == "title_exchange" then
        self:AddText(c.text)
        if c.points then
            for i, p in ipairs(c.points) do
                self:AddNumText(p.label, 11, 49 + i)
            end
        end
    elseif c.role == "formation_stone" then
        self:AddText(c.text)
        if self:GetLevel(selfId) >= 10 and c.stones then
            for i, p in ipairs(c.stones) do
                self:AddNumText("Dịch chuyển tới " .. p.label, 9, 59 + i)
            end
        end
    elseif c.role == "greeter" then
        self:AddText(c.text)
    end
    require("scripts.obj.cy4.cy4_training_npc").menu(self,selfId)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function cy4_npc:OnEventRequest(selfId, targetId, arg, index)
    local c = self.cfg
    if c.sign and arg == c.sign then
        self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
        return
    end
    if require("scripts.obj.cy4.cy4_training_npc").event(self,selfId,targetId,index) then return end
    if c.role == "join" then
        if index ~= 0 and index ~= 3 then return end
        local allowed, message = self:CanJoin(selfId)
        if not allowed then self:Say(selfId, targetId, message); return end
        if index == 0 then
            self:BeginEvent(self.script_id)
            self:AddText("Bạn có muốn bái nhập " .. c.faction_name .. "?")
            self:AddNumText("Xác nhận gia nhập", 6, 3)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        local joined = self:LuaFnJoinMenpai(selfId, c.faction)
        if not joined then
            self:Say(selfId, targetId, "Môn phái chưa sẵn sàng tiếp nhận đệ tử. Xin thử lại sau.")
            return
        end
        self:Say(selfId, targetId, "Bạn đã gia nhập " .. c.faction_name .. ". Hãy gặp thầy truyền dạy võ học để học tâm pháp.")
    elseif c.role == "xinfa_teacher" then
        if index ~= 0 then return end
        if self:GetMenPai(selfId) ~= c.faction then
            self:Say(selfId, targetId, "Ta chỉ truyền dạy võ học cho đệ tử " .. c.faction_name .. ".")
            return
        end
        self:DispatchXinfaLevelInfo(selfId, targetId, c.faction)
    elseif c.role == "mount_manager" then
        if index ~= 40 then return end
        if self:GetMenPai(selfId) ~= c.faction then
            self:Say(selfId, targetId, "Toạ kỵ này chỉ dành cho đệ tử " .. c.faction_name .. ".")
            return
        end
        self:DispatchShopItem(selfId, targetId, c.mount_shop)
    elseif c.role == "mount_guide" then
        if index ~= 40 then return end
        if self:GetMenPai(selfId) ~= c.faction then
            self:Say(selfId, targetId, "Toạ kỵ này chỉ dành cho đệ tử " .. c.faction_name .. ".")
            return
        end
        self:DispatchShopItem(selfId, targetId, c.mount_shop)
    elseif c.role == "head" or c.role == "quest_giver" or c.role == "title_exchange" then
        local p = c.points and c.points[index - 49]
        if not p then return end
        self:CallScriptFunction(888888, "AskTheWay", selfId, self:get_scene_id(), p.x, p.z, p.tip)
        self:Say(selfId, targetId, p.desc)
    elseif c.role == "formation_stone" then
        local p = c.stones and c.stones[index - 59]
        if not p then return end
        if self:GetLevel(selfId) < 10 then
            self:Say(selfId, targetId, "Cần đạt cấp 10 mới dùng được trận linh thạch.")
            return
        end
        self:CallScriptFunction(400900, "TransferFunc", selfId, self:get_scene_id(), p.x, p.z, 10)
    elseif c.role == "outbound_travel" or c.role == "Dali_inbound_travel" then
        if index ~= 0 then return end
        if self:GetLevel(selfId) < c.min_level then
            self:Say(selfId, targetId, "Bạn cần đạt cấp " .. c.min_level .. " để đến nơi này.")
            return
        end
        self:CallScriptFunction(400900, "TransferFunc", selfId, c.destination_scene, c.destination_x, c.destination_z, c.min_level)
    end
end

return cy4_npc
