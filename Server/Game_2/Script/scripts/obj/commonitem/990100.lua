local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
local chartitleinfo = {
    [38008100] = 1042,
    [38008101] = 1041,
    [38008102] = 1033,
    [38008103] = 1032,
    [38008104] = 1034,
    [38008105] = 1035,
    [38008106] = 1036,
    [38008107] = 1037,
    [38008108] = 1038,
    [38008109] = 1039,
    [38008110] = 1040,
    [38008111] = 1096,
    [38008112] = 1099,
    [38008113] = 1102,
    [38008114] = 1105,
    [38008115] = 1108,
    [38008116] = 1111,
    [38008117] = 1114,
    [38008118] = 1117,
    [38008119] = 1120,
    [38008120] = 1123,
    [38008121] = 1126,
    [38008122] = 1129,
    [38008123] = 1132,
    [38008124] = 1135,
    [38008125] = 1138,
    [38008126] = 1141,
    [38008127] = 1144,
    [38008128] = 1147,
    [38008129] = 1150,
    [38008130] = 1153,
    [38008131] = 1156,
    [38008132] = 1159,
    [38008133] = 1162,
    [38008134] = 1165,
    [38008135] = 1168,
    [38008136] = 1171,
    [38008137] = 1174,
    [38008138] = 1219,
    [38008139] = 1220,
    [38008140] = 1221,
    [38008141] = 1216,
    [38008142] = 1217,
    [38008143] = 1218,
    [38008144] = 1224,
    [38008145] = 1225,
    [38008146] = 1226,
    [38008147] = 1281,
    [38008148] = 1234,
    [38008149] = 1235,
    [38008150] = 1236,
    [38008151] = 1237,
    [38008152] = 1238,
    [38008153] = 1239,
    [38008154] = 1240,
}

function common_item:OnDefaultEvent(selfId, bagIndex)

end

function common_item:IsSkillLikeScript(selfId)
    return 1
end

function common_item:CancelImpacts(selfId)
    return 0
end

function common_item:OnConditionCheck(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then
        return 0
    end
    local bag_index = self:LuaFnGetBagIndexOfUsedItem(selfId)
    local nItemId = self:LuaFnGetItemTableIndexByIndex(selfId,bag_index)
	if chartitleinfo[nItemId] == nil then
		self:notify_tips(selfId,"Đạo cụ chưa mở.")
		return 0
	end
	if self:LuaFnHaveAgname(selfId,chartitleinfo[nItemId]) then
		self:notify_tips(selfId,"Ngươi đã sở hữu danh hiệu này.")
		return 0
	end
    return 1
end

function common_item:OnDeplete(selfId)
    return 1
end

function common_item:OnActivateOnce(selfId)
	local bag_index = self:LuaFnGetBagIndexOfUsedItem(selfId)
	local nItemId = self:LuaFnGetItemTableIndexByIndex(selfId,bag_index)
	self:LuaFnAddNewAgname(selfId,chartitleinfo[nItemId])
	self:notify_tips(selfId,"Dùng thành công, đã nhận danh hiệu này.")
    self:LuaFnDecItemLayCount(selfId, bag_index, 1)
    return 1
end

function common_item:OnActivateEachTick(selfId)
    return 1
end

return common_item
