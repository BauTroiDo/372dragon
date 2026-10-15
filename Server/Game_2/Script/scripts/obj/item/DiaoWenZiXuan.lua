local class = require "class"
local define = require "define"
local script_base = require "script_base"
local DiaoWenZiXuan = class("DiaoWenZiXuan", script_base)
DiaoWenZiXuan.script_id = 100020
local diaowen_types = {
    [1] = {
        {name = "Bản vẽ Điêu Văn Vũ khí Băng công", index = 101, award = 30120014},
        {name = "Bản vẽ Điêu Văn Vũ khí Hỏa công", index = 102, award = 30120015},
        {name = "Bản vẽ Điêu Văn Huyền công Vũ khí", index = 103, award = 30120016},
        {name = "Bản vẽ Điêu Văn Độc công Vũ khí", index = 104, award = 30120017},
        {name = "Bản vẽ Điêu Văn Hộ Uyển Băng công", index = 105, award = 30120035},
        {name = "Hộ Uyển Hỏa công Điêu Văn Bản vẽ", index = 106, award = 30120036},
        {name = "Hộ Uyển Huyền công Điêu Văn Bản vẽ", index = 107, award = 30120037},
        {name = "Hộ Uyển Độc công Điêu Văn Bản vẽ", index = 108, award = 30120038},
        {name = "Bản vẽ Điêu Văn Băng công Ám khí", index = 113, award = 30120066},
        {name = "Bản vẽ Điêu Văn Hỏa công Ám khí", index = 114, award = 30120067},
        {name = "Bản vẽ Điêu Văn Huyền công Ám khí", index = 115, award = 30120068},
        {name = "Bản vẽ Điêu Văn Độc công Ám khí", index = 116, award = 30120069},
    },
    [2] = {
        {name = "Bản vẽ Điêu Văn Giày Thể lực", index = 201, award = 30120008},
        {name = "Bản vẽ Điêu Văn Yêu Đái Thể lực", index = 202, award = 30120010},
        {name = "Bản vẽ Điêu Văn Y phục Thể lực", index = 203, award = 30120028},
        {name = "Hộ Kiên Thể lực Điêu Văn Bản vẽ", index = 204, award = 30120042},
        {name = "Bản vẽ Điêu Văn Thể lực Võ Hồn", index = 205, award = 30120050},
        {name = "Bản vẽ Điêu Văn Thể lực Mũ", index = 206, award = 30120145},
        {name = "Hộ Thủ Thể lực Điêu Văn Bản vẽ", index = 207, award = 30120041},
    }
}
function DiaoWenZiXuan:OnDefaultEvent(selfId)
    self:BeginEvent(self.script_id)
    self:AddText("#YĐiêu văn tự chọn")
    self:AddText("  Chọn một trong các loại điêu văn dưới đây")
    self:AddNumText("Điêu văn thuộc tính", 0, 1)
    self:AddNumText("Điêu văn thể lực", 0, 2)
    self:EndEvent()
    self:DispatchEventList(selfId, -1)
end

function DiaoWenZiXuan:IsSkillLikeScript(selfId)
    return 0
end

function DiaoWenZiXuan:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        local type_of_diaowens = diaowen_types[1]
        self:BeginEvent(self.script_id)
        self:AddText("#YĐiêu văn thuộc tính tự chọn")
        self:AddText("  Chọn một trong các điêu văn thuộc tính dưới đây")
        for _, d in ipairs(type_of_diaowens) do
            self:AddNumText(d.name, 0, d.index)
        end
        self:EndEvent()
        self:DispatchEventList(selfId, -1)
        return
    end
    if index == 2 then
        local type_of_diaowens = diaowen_types[2]
        self:BeginEvent(self.script_id)
        self:AddText("#YĐiêu văn thể lực tự chọn")
        self:AddText("  Chọn một trong các điêu văn thể lực dưới đây")
        for _, d in ipairs(type_of_diaowens) do
            self:AddNumText(d.name, 0, d.index)
        end
        self:EndEvent()
        self:DispatchEventList(selfId, -1)
        return
    end
    local nBagsPos = self:LuaFnGetPropertyBagSpace(selfId)
    if nBagsPos < 1 then
        self:BeginEvent(self.script_id)
        self:AddText("Cần ít nhất một ô đạo cụ trống")
        self:EndEvent()
        self:DispatchEventList(selfId, -1)
        return
    end
    local item_count = self:LuaFnGetAvailableItemCount(selfId, 38000960)
    if item_count < 1 then
        self:BeginEvent(self.script_id)
        self:AddText("Túi không có hộp điêu văn tự chọn")
        self:EndEvent()
        self:DispatchEventList(selfId, -1)
        return
    end
    local config = self:GetSelectDiaowen(index)
    if config == nil then
        self:BeginEvent(self.script_id)
        self:AddText("Cấu hình bất thường")
        self:EndEvent()
        self:DispatchEventList(selfId, -1)
        return
    end
    if not self:LuaFnDelAvailableItem(selfId, 38000960, 1) then
        self:notify_tips(selfId, "Trừ hộp điêu văn tự chọn thất bại")
        return
    end
    self:TryRecieveItem(selfId, config.award, true)
    self:BeginEvent(self.script_id)
    self:AddText(string.format("Nhận %s thành công", config.name))
    self:EndEvent()
    self:DispatchEventList(selfId, -1)
end

function DiaoWenZiXuan:GetSelectDiaowen(index)
    for _, dt in pairs(diaowen_types) do
        for _, d in ipairs(dt) do
            if d.index == index then
                return d
            end
        end
    end
end


return DiaoWenZiXuan
