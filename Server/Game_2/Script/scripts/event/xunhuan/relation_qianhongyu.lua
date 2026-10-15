local class = require "class"
local define = require "define"
local script_base = require "script_base"
local relation_qianhongyu = class("relation_qianhongyu", script_base)
relation_qianhongyu.script_id = 050106
relation_qianhongyu.g_TitleList = {
    {
        ["relation"] = 1000,
        ["title"] = "Nghĩa Sĩ Diệt Phỉ",
        ["failMsg"] = "    Muốn nhận được danh hiệu cấp 1, quan hệ giữa ta và ngươi ít nhất phải đạt 1000, hãy hoàn thành thêm vài lần nhiệm vụ tiễu phỉ rồi quay lại tìm ta.",
        ["succMsg"] = "    Võ công của các hạ thật lợi hại, tại hạ vô cùng kính phục, giang hồ đồn rằng các hạ là #R nghĩa sĩ tiễu phỉ#W, ta thấy quả không sai!"
    }, {
        ["relation"] = 2000,
        ["title"] = "Hiệp Sĩ Phá Phỉ",
        ["failMsg"] = "    Muốn nhận được danh hiệu cấp 2, quan hệ giữa ta và ngươi ít nhất phải đạt 2000, hãy hoàn thành thêm vài lần nhiệm vụ tiễu phỉ rồi quay lại tìm ta.",
        ["succMsg"] = "    Võ công của các hạ thật lợi hại, tại hạ vô cùng kính phục, giang hồ đồn rằng các hạ là #R hiệp sĩ phá phỉ#W, ta thấy quả không sai!"
    }, {
        ["relation"] = 4000,
        ["title"] = "Trấn Phỉ Anh Hiệp",
        ["failMsg"] = "    Muốn nhận được danh hiệu cấp 3, quan hệ giữa ta và ngươi ít nhất phải đạt 4000, hãy hoàn thành thêm vài lần nhiệm vụ tiễu phỉ rồi quay lại tìm ta.",
        ["succMsg"] = "    Võ công của các hạ thật lợi hại, tại hạ vô cùng kính phục, giang hồ đồn rằng các hạ là #R anh hiệp trấn phỉ#W, ta thấy quả không sai!"
    }, {
        ["relation"] = 6500,
        ["title"] = "Thiên Hạ Phỉ Kiến Sầu",
        ["failMsg"] = "    Muốn nhận được danh hiệu cấp bốn, giá trị quan hệ giữa ta và ngươi ít nhất phải đạt 6500, hãy hoàn thành thêm vài lần nhiệm vụ tiễu phỉ rồi hãy đến tìm ta.",
        ["succMsg"] = "    Võ công của các hạ thật lợi hại, tại hạ vô cùng kính phục, giang hồ đồn rằng các hạ là #RThiên Hạ Phỉ Kiến Sầu#W, ta thấy quả không sai!"
    }
}

function relation_qianhongyu:OnDefaultEvent(selfId, targetId)
    local opt = index
    if opt == 7 then
        self:GetTitleOptions(selfId, targetId)
    elseif opt == 8 then
        self:GetNewTitle(selfId, targetId)
    end
end

function relation_qianhongyu:OnEnumerate(caller, selfId, targetId, arg, index)
    caller:AddNumTextWithTarget(self.script_id, "Lĩnh danh hiệu", 8, 7)
end

function relation_qianhongyu:GetTitleOptions(selfId, targetId)
    local str = string.format("    A, %s, ta luôn rất khâm phục những anh hùng hoàn thành nhiệm vụ truy nã tiễu phỉ, hiện tại giá trị quan hệ giữa ta và ngươi là %d, khi giá trị quan hệ giữa ta và ngươi đạt 1000, 2000, 4000, 6500 đều Có thể sử dụng tại chỗ ta để đổi danh hiệu.",
                    self:GetName(selfId),
                    self:GetMissionData(selfId, define.MD_ENUM.MD_RELATION_QIANHONGYU))
    self:BeginEvent(self.script_id)
    self:AddText(str)
    self:AddNumText("Lĩnh danh hiệu mới.", 8, 8)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function relation_qianhongyu:GetNewTitle(selfId, targetId)
    self:BeginEvent(self.script_id)
    local str = ""
    local curTitle = self:GetQHYTitle(selfId)
    local relation = self:GetMissionData(selfId, define.MD_ENUM.MD_RELATION_QIANHONGYU)
    local loc = 1
    for i = 1, #(self.g_TitleList) do
        if curTitle == self.g_TitleList[i]["title"] then
            loc = i
            break
        end
    end
    if loc == #(self.g_TitleList) then
        str =
            "    Các hạ giờ đã là Thiên Hạ Phỉ Kiến Sầu danh quán giang hồ rồi, bọn phỉ trên giang hồ nghe danh các hạ ai nấy đều mất vía, người người kinh tâm. Đã không còn danh hiệu nào cao hơn để biểu đạt năng lực của các hạ nữa rồi."
    else
        for i = loc, #(self.g_TitleList) do
            if relation < self.g_TitleList[i]["relation"] then
                str = self.g_TitleList[i]["failMsg"]
                break
            elseif self.g_TitleList[i]["title"] ~= self:GetQHYTitle(selfId) then
                self:SetQHYTitle(selfId, self.g_TitleList[i]["title"])
                self:DispatchAllTitle(selfId)
                str = self.g_TitleList[i]["succMsg"]
                break
            end
        end
    end
    self:AddText(str)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return relation_qianhongyu
