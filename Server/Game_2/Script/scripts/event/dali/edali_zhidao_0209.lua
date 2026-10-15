local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_zhidao_0209 = class("edali_zhidao_0209", script_base)
edali_zhidao_0209.script_id = 210209
edali_zhidao_0209.g_XinShouJiNeng = 
{
    {["name"] = "慧易", ["skill"] = "Học tập Ngoại Công Hộ Thể",["menpainame"] = "Thiếu Lâm phái",["strdesc"] = "Thiếu Lâm cổ tự"},
    {["name"] = "石宝", ["skill"] = "Học tập Phấn Lực Đả Kích",["menpainame"] = "明教",["strdesc"] = "Đại Quang Minh Điện"},
    {["name"] = "简宁", ["skill"] = "Học Tập Yếu Hại Tấn công",["menpainame"] = "丐帮",["strdesc"] = "丐帮总舵"},
    {["name"] = "张获", ["skill"] = "学习内劲攻击",["menpainame"] = "Võ Đang phái",["strdesc"] = "Võ Đang tiên phong"},
    {["name"] = "路三娘", ["skill"] = "Học Tập Sơ Cấp Trị Liệu",["menpainame"] = "Phái Nga Mi",["strdesc"] = "Nga My thiên hạ tú"},
    {["name"] = "海风子", ["skill"] = "Học Tập Nội Công Hộ Thể",["menpainame"] = "Tinh Túc phái",["strdesc"] = "Tinh Túc Xuân Thu"},
    {["name"] = "破贪", ["skill"] = "Học Tập Phá Trán Tấn công",["menpainame"] = "Thiên Long phái",["strdesc"] = "Thiên Long phong tình"},
    {["name"] = "程青霜", ["skill"] = "学习初级隐遁",["menpainame"] = "Thiên Sơn phái",["strdesc"] = "Phiêu Miễu Thiên Sơn"},
    {["name"] = "澹台子羽", ["skill"] = "Học Tập Thiêu Đốt Hãm Tĩnh",["menpainame"] = "Tiêu Dao phái",["strdesc"] = "Lăng Ba Tiêu Dao"},
    {["name"] = "王溪云", ["skill"] = "Học Tập Mệnh Hồn Hộ Thể",["menpainame"] = "曼陀山庄",["strdesc"] = "曼陀山庄"},
    {["name"] = "山风", ["skill"] = "Học tập Đoán Cốt Cường Thể",["menpainame"] = "恶人谷",["strdesc"] = "U Xuyên Ác Nhân Cốc"},
}
edali_zhidao_0209.g_XinShouSkillData = {241,242,243,244,245,246,247,248,249,277,140}
function edali_zhidao_0209:OnDefaultEvent(selfId, targetId)
    self:OnContinue(selfId, targetId)
end

function edali_zhidao_0209:OnEnumerate(caller, selfId, targetId, arg, index)
    local nIndex = 0
    for i,Skill in pairs(self.g_XinShouJiNeng) do
        if self:GetName(targetId) == Skill["name"] then
            nIndex = i
        end
    end
    if nIndex > 0 then
        if self:GetLevel(selfId) >= 10 and self:GetMenPai(selfId) == 9 then
            caller:AddNumTextWithTarget(self.script_id,"#GTa muốn gia nhập"..self.g_XinShouJiNeng[nIndex]["menpainame"], 6, 14)
        end
        if not self:HaveSkill(selfId,self.g_XinShouSkillData[nIndex]) then
            caller:AddNumTextWithTarget(self.script_id,self.g_XinShouJiNeng[nIndex]["skill"], 6, -1)
        end
        caller:AddNumTextWithTarget(self.script_id,self.g_XinShouJiNeng[nIndex]["menpainame"].."Nguyên do", 11, 10)
        caller:AddNumTextWithTarget(self.script_id,self.g_XinShouJiNeng[nIndex]["menpainame"].."Đặc sắc chiến đấu", 11, 11)
        caller:AddNumTextWithTarget(self.script_id,self.g_XinShouJiNeng[nIndex]["menpainame"].."Đặc sắc đời sống", 11, 12)
        caller:AddNumTextWithTarget(self.script_id,self.g_XinShouJiNeng[nIndex]["strdesc"], 11, 13)
    end
end

function edali_zhidao_0209:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{XSRW_100111_106}")
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id,-1)
end

function edali_zhidao_0209:OnSubmit(selfId, targetId)
    local nIndex = 0
    for i,Skill in pairs(self.g_XinShouJiNeng) do
        if self:GetName(targetId) == Skill["name"] then
            nIndex = i
        end
    end
    if nIndex > 0 then
        if self:HaveSkill(selfId,self.g_XinShouSkillData[nIndex]) then 
            return 
        end
        if nIndex == 4 then
			if self:IsHaveMission(selfId,1405) then
				local misIndex = self:GetMissionIndexByID(selfId,1405)
				if self:GetMissionParam(selfId,misIndex,1) < 1 then
					self:SetMissionByIndex(selfId,misIndex,1,1)
                    self:notify_tips(selfId,"Học Nội Kình Công Kích chỗ Tiếp Dẫn đạo trưởng Võ Đang: 1/1")
                    if self:GetMissionParam(selfId,misIndex,1) == 1 and self:GetMissionParam(selfId,misIndex,2) == 1 then
                        self:SetMissionByIndex(selfId,misIndex,0,1) --设置完成任务
                        self:notify_tips(selfId,"")
                    end
				end
			end
        elseif nIndex == 8 then
			if self:IsHaveMission(selfId,1405) then
				local misIndex = self:GetMissionIndexByID(selfId,1405)
				if self:GetMissionParam(selfId,misIndex,2) < 1 then
					self:SetMissionByIndex(selfId,misIndex,2,1)
                    self:notify_tips(selfId,"Học Ẩn Độn sơ cấp chỗ Tiếp Dẫn Sứ phái Thiên Sơn: 1/1")
                    if self:GetMissionParam(selfId,misIndex,1) == 1 and self:GetMissionParam(selfId,misIndex,2) == 1 then
                        self:SetMissionByIndex(selfId,misIndex,0,1) --设置完成任务
                    end
				end
			end
        end
        self:AddSkill(selfId,self.g_XinShouSkillData[nIndex])
        self:notify_tips(selfId,"Ngươi học được kỹ năng mới:"..self.g_XinShouJiNeng[nIndex]["menpainame"].."Kỹ năng tân thủ:"..string.sub(self.g_XinShouJiNeng[nIndex]["skill"],7,18))
        self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,18,0)
    end
end

function edali_zhidao_0209:OnKillObject(selfId, objdataId) end

function edali_zhidao_0209:OnEnterZone(selfId, zoneId) end

function edali_zhidao_0209:OnItemChanged(selfId, itemdataId) end

return edali_zhidao_0209
