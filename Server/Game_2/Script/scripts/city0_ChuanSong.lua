local class = require "class"
local define = require "define"
local script_base = require "script_base"
local city0_ChuanSong = class("city0_ChuanSong", script_base)

function city0_ChuanSong:OnEnterArea(selfId) self:CityMoveToPort(selfId) end

function city0_ChuanSong:OnTimer(selfId) end

function city0_ChuanSong:OnLeaveArea(selfId) end

return city0_ChuanSong
