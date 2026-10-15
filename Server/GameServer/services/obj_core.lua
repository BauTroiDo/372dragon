local skynet = require "skynet"
local crypt = require "skynet.crypt"
local cluster = require "skynet.cluster"
local class = require "class"
local utils = require "utils"
local obj_human = require "scene.obj.human"
local obj_core = class("obj_core")

function obj_core:ctor(obj_type, ...)
    if obj_type == "human" then
        self.obj = obj_human.new(...)
    elseif obj_type == "pet" then

    elseif obj_type == "monster" then

    end
end

return obj_core