--珍兽繁殖
local class = require "class"
local script_base = require "script_base"
local PetProcreateTakeOut = class("PetProcreateTakeOut", script_base)

function PetProcreateTakeOut:OnDefaultEvent(selfId)
	local checkRet	= self:LuaFnCheckPetProcreateTakeOut(selfId)
	if checkRet then
		self:LuaFnPetProcreateTakeOut(selfId)
	end
end

function PetProcreateTakeOut:OnEnumerate(caller)
    caller:AddNumTextWithTarget(self.script_id, "Lấy ra hoàn thành việc gây giống của Trân thú", 6, self.script_id)
end

return PetProcreateTakeOut