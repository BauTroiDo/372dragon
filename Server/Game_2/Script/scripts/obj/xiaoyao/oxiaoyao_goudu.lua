local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxiaoyao_goudu = class("oxiaoyao_goudu", script_base)
oxiaoyao_goudu.g_shoptableindex = 47
function oxiaoyao_goudu:OnDefaultEvent(selfId, targetId)
    self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
end

return oxiaoyao_goudu
