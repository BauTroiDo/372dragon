local nav_adapter = require "nav_adapter"
local class = require "class"
local skynet = require "skynet"
local scene = class("scene")

function scene:ctor(scene_def, is_user_city)
    self.scene_def = scene_def
    self.is_user_city = is_user_city
end

function scene:LoadNavMesh(szRegionFile)
    if not szRegionFile or szRegionFile == "" then
        szRegionFile = "luoyang.path"
    end
    if string.sub(szRegionFile, -4) == ".nav" then
        szRegionFile = string.sub(szRegionFile, 1, -5) .. ".path"
    end
    self.map = nav_adapter.new()
    local scene_config_env = skynet.getenv("scene_config_env")
    local fullpath = string.format("%s/%s", scene_config_env, szRegionFile)
    self.map:load(fullpath)
end

function scene:FindPath(from, to)
    if not self.map then return {} end
    return self.map:findpath(from, to)
end

return scene