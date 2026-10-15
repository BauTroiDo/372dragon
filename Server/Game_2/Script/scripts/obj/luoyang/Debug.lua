local class = require "class"
local define = require "define"
local script_base = require "script_base"
local Debug = class("Debug", script_base)
Debug.script_id = 230919
Debug.g_AskPrizeInfo = {
    [1] = {{ 38002397, 250 }},
    [2] = {{ 20501004, 50},{20502004,50}},
    [3] = {{ 10156001, 1 },{ 10156002, 1 }},
    [4] = {{ 10155001, 1 },{ 10155002, 1 },{10155003,1}},
    [5] = {{ 38002499, 250 }},
    [6] = {{ 20600003, 250 }},
    [7] = {{ 30505706, 1 },{ 30505806, 20 },{ 30505908,50}},
    [8] = {{ 30505908, 100 }},
    [9] = {{ 20310111, 100 }},
    [10] = {{ 20502005, 250 }, { 20501005, 250 }, { 20500005, 250 }},
    [11] = {{ 10422016, 1 }, { 10422016, 1 }, { 10423024, 1 }, { 10423024, 1 }},
    [12] = {
        { 38002608, 1 }, { 38002609, 1 }, { 38002610, 1 }, { 38002611, 1 },
        { 38002612, 1 }, { 38002613, 1 }, { 38002614, 1 }, { 38002615, 1 },
        { 38002616, 1 }, { 38002617, 1 }, { 38002618, 1 }, { 38002619, 1 },
        { 38002620, 1 }, { 38002621, 1 },
    },
    [13] = {{ 20502009, 250 }},
    [14] = {
        { 50702005, 250}, { 50702006, 250}, { 50702007, 250}, { 50702008, 250},
        { 50712005, 250}, { 50712006, 250}, { 50712007, 250}, { 50712008, 250},
        { 50713002, 250}, { 50713003, 250}, { 50713004, 250}, { 50713005, 250},
        { 50721001, 250}, { 50721002, 250}, { 50721003, 250}, { 50721004, 250},
        { 50703001, 250}, { 50714001, 250},
    },
    [15] = {
        { 30700214, 1}, { 30700215, 1}, { 30700216, 1}, { 30700217, 1},
        { 30700218, 1}, { 30700219, 1}, { 30700220, 1}, { 30700221, 1},
        { 30700222, 1}, { 30700223, 1}, { 30700224, 1}, { 30700225, 1},
        { 30700226, 1}, { 30700227, 1}, { 30700228, 1}, { 30700229, 1},
    }
}
function Debug:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("   Ngươi từ cấp 10 lên thẳng 104, và nhận các vật phẩm liên quan sau!")
    self:AddNumText("Thăng thẳng cấp 104",11,1)
    self:AddNumText("Tâm pháp tăng tới cấp 90",11,2)
    self:AddNumText("Nhận về thần khí", 11,107)
    self:AddNumText("Nhận về ám khí", 11,104)
    self:AddNumText("Nhận về trang bị thủ công",11,102)
    self:AddNumText("Dọn sạch ô đạo cụ và nguyên liệu! Thận trọng!",11,1000)
    self:AddNumText("#HNhận về võ đạo", 11,101)
    self:AddNumText("#HNhận về Linh Võ",11,106)
    --[[self:AddNumText("领取4级棉布秘银250个", 6, 102)
    self:AddNumText("领取武魂装备", 6, 103)
    self:AddNumText("领取冰魄神针", 6, 104)
    self:AddNumText("领取神魂檀箱250个", 6, 105)
    self:AddNumText("领取超级长春玉250个", 6, 106)
    self:AddNumText("领取神节7级和新莽神符", 6, 107)
    self:AddNumText("领取神兵符3级100个", 6, 108)
    self:AddNumText("领取寒玉精粹100个", 6, 109)
    self:AddNumText("领取5级手工材料分别250个", 6, 110)
    self:AddNumText("领取4个重楼", 6, 111)
    self:AddNumText("领取所有幻饰", 6, 112)
    self:AddNumText("获取黄纸250个", 6, 113)
    self:AddNumText("获取7级石头", 6, 114)
    self:AddNumText("获取武魂技能书", 6, 115)
    self:AddNumText("获取武道领悟点10000点", 6, 131)]]
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function Debug:OnEventRequest(selfId, targetId, arg, index)
    local nIndex = index
    if nIndex == 1 then
        local nLevel = self:GetLevel(selfId)
        if self:GetMenPai(selfId) == 9 then
            self:notify_tips(selfId,"Xin hãy gia nhập Môn phái trước.")
            return 
        end
        if nLevel < 104 then
            self:SetLevel(selfId, 104)
            self:MsgBox(selfId, targetId, "Nhận cấp 104 thành công.")
        else
            self:MsgBox(selfId, targetId, "Đã đạt cấp 104, khỏi nhận lại.")
            return
        end
    elseif nIndex == 2 then
        if self:GetMenPai(selfId) == 9 then
            self:notify_tips(selfId,"Xin hãy gia nhập Môn phái trước.")
            return 
        end
        self:UpXinfaLevel(selfId, 90)
        return
    end
    if nIndex >= 100 and nIndex <= 120 then
        local nGiftItem = self.g_AskPrizeInfo[(nIndex % 100)]
        self:BeginAddItem()
        for i = 1, #(nGiftItem) do
            self:AddItem(nGiftItem[i][1], nGiftItem[i][2])
        end
        if not self:EndAddItem(selfId) then
            self:notify_tips(selfId, "Không đủ chỗ, xin kiểm tra")
            return
        end
        self:AddItemListToHuman(selfId)
        self:MsgBox(selfId, targetId, "Nhận thành công.")
        return
    end
    if nIndex == 131 then
        self:LuaFnAddTalentUnderstandPoint(selfId, 10000)
        self:notify_tips(selfId, "Nhận 10000 điểm lĩnh ngộ võ đạo thành công")
        return
    end
    if nIndex == 1000 then
        for i = 0,159 do
            self:LuaFnEraseItem(selfId,i)
        end
    end
end

function Debug:MsgBox(selfId, targetId, str)
    self:BeginEvent(self.script_id)
    self:AddText(str)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return Debug
