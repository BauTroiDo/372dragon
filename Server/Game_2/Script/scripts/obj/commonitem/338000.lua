local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
local g_SkillBooks = require "cy_sect_books"
local configenginer = require "configenginer":getinstance()

local g_TypeNames = {}
g_TypeNames[1] = "Bí kíp"
g_TypeNames[2] = "Yếu quyết"
g_TypeNames[3] = "Kỹ năng tiến giai"

local MenPaiName = { [10] = "Mộ Dung", [11] = "Đường Môn", [12] = "Quỷ Cốc",
    [13] = "Đào Hoa Đảo", [14] = "Tuyệt Tình Cốc", [15] = "Ác Nhân Cốc" }

-- Validate the runtime data before consuming a book, including all legacy sects.
local function valid_book(book)
    if not book or book.id < 0 then return false end
    local xinfas = configenginer:get_config("xinfa_v1")
    if book.type == 1 then
        return xinfas[book.id] and xinfas[book.id].menpai == book.menpaiId
    end
    local template = configenginer:get_config("skill_template")[book.id]
    if not template or template.menpai ~= book.menpaiId or template.xinfa ~= book.needXinfa then return false end
    return book.needXinfa == -1 or (xinfas[book.needXinfa] and xinfas[book.needXinfa].menpai == book.menpaiId)
end

function common_item:IsSkillLikeScript()
    return 1
end

function common_item:CancelImpacts()
    return 0
end

function common_item:OnConditionCheck(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then
		return 0
	end
    local itemTblIndex = self:LuaFnGetItemIndexOfUsedItem(selfId)
    local skillBook = g_SkillBooks[itemTblIndex]
    if not valid_book(skillBook) then
        self:notify_tips(selfId, "Sách này chưa có dữ liệu học hợp lệ. Vật phẩm được giữ nguyên.")
        return 0
    end
    if skillBook.type == 2 then
        local human = self:get_scene():get_obj_by_id(selfId)
        if not human:have_skill(skillBook.id) and #human:get_total_skills_list() >= 127 then
            self:notify_tips(selfId, "Danh sách kỹ năng đã đầy.")
            return 0
        end
    end
	local menpai = self:GetMenPai(selfId )
	if -1~=skillBook.menpaiId then
		if menpai ~= skillBook.menpaiId then
			if skillBook.menpaiId < 9 then
				self:notify_tips(selfId, "Ngươi không phải #{_MENPAI" .. skillBook.menpaiId .. "} đệ tử, không thể học" .. g_TypeNames[skillBook.type] .. "。" )
			else
				self:notify_tips( selfId, "Ngươi không phải"..(MenPaiName[skillBook.menpaiId] or tostring(skillBook.menpaiId)).."đệ tử, không học được" .. g_TypeNames[skillBook.type] .. "。" )
			end
			return 0
		end
	end
    if self:GetLevel(selfId) < skillBook.needLevel then
		self:notify_tips(selfId, "Ngươi còn chưa thể học" .. g_TypeNames[skillBook.type] .. "。" )
		return 0
	end

	if skillBook.needXinfa ~= -1 then
		local xinfaLevel = self:HaveXinFa(selfId, skillBook.needXinfa )
		if xinfaLevel < 1 then
			self:notify_tips(selfId, "Cần học tâm pháp trước:#{_XINFA" .. skillBook.needXinfa .. "}。" )
			return 0
		end

		if xinfaLevel < skillBook.needXinfaLevel then
			-- 需要测试这个地方，跨行而且没有分号
			self:notify_tips(selfId, "Cần tâm pháp:#{_XINFA" .. skillBook.needXinfa .. "} ".. skillBook.needXinfaLevel .. " Cấp, hiện tại " .. xinfaLevel .. " cấp." )
			return 0
		end
	end

	if skillBook.type == 1 then					-- 心法
		if self:HaveXinFa(selfId, skillBook.id ) > 0 then
			self:notify_tips(selfId, "Ngươi đã học được Tâm Pháp này." )
			return 0
		end
	elseif skillBook.type == 2 then				-- 要诀
		if self:HaveSkill(selfId, skillBook.id ) then
			self:notify_tips(selfId, "Ngươi đã học được Kỹ năng này." )
			return 0
		end
	end
    return 1
end

function common_item:OnDeplete(selfId)
    if self:OnConditionCheck(selfId) ~= 1 then return 0 end
    return self:LuaFnDepletingUsedItem(selfId)
end

function common_item:OnActivateOnce(selfId)
	local itemTblIndex = self:LuaFnGetItemIndexOfUsedItem(selfId)
	local skillBook = g_SkillBooks[itemTblIndex]
	if not valid_book(skillBook) then
		return 0
	end
	-- 学习
	if skillBook.type == 1 then					-- 心法
		if self:HaveXinFa(selfId, skillBook.id ) > 0 then
			self:notify_tips(selfId, "Ngươi đã học được Tâm Pháp này." )
			return 0
		else
			self:AddXinFa(selfId, skillBook.id )
			self:notify_tips(selfId, "Chúc mừng bạn học tâm pháp thành công:#{_ITEM"..itemTblIndex.."}" )
		end
	elseif skillBook.type == 2 then				-- 要诀
		if self:HaveSkill(selfId, skillBook.id ) then
			self:notify_tips(selfId, "Ngươi đã học được Kỹ năng này." )
			return 0
		else
			self:AddSkill(selfId, skillBook.id )
			self:notify_tips(selfId, "Chúc mừng bạn học yếu quyết thành công:#{_ITEM"..itemTblIndex.."}" )
		end
	end
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, skillBook.specialEffectID, 0 )
    return 1
end

return common_item