-- nav_adapter.lua
-- Drop-in replacement for map.so C module
-- All scene nav data is loaded from .path via pathparser + lnavmesh
--   nav_adapter.new() -> obj
--   obj:load(filename) -> bool
--   obj:findpath(start, target) -> {{x=,y=},...}

local lnavmesh = require "lnavmesh"
local pathparser = require "pathparser"
local skynet = require "skynet"

local NAV_DEBUG = skynet.getenv("nav_debug") == "1"

local nav_adapter = {}
local mt = {}
mt.__index = mt

local function file_exists(path)
    local f = io.open(path, "rb")
    if f then
        f:close()
        return true
    end
    return false
end

function nav_adapter.new()
    local obj = setmetatable({}, mt)
    obj.pathfinder = nil
    return obj
end

function mt:load(filename)
    local path_filename = filename

    if string.sub(filename, -4) == ".nav" then
        path_filename = string.sub(filename, 1, -5) .. ".path"
    end

    if not file_exists(path_filename) then
        skynet.error("nav_adapter: missing path file: " .. tostring(path_filename))
        return false
    end

    local t0 = os.clock()
    local ok, polygon_data = pcall(pathparser.load, pathparser, path_filename)
    local t1 = os.clock()
    if not ok or not polygon_data then
        skynet.error("nav_adapter: parse failed: " .. tostring(path_filename) .. " err=" .. tostring(polygon_data))
        return false
    end
    if NAV_DEBUG then
        skynet.error(string.format("nav_adapter: parse OK %s polygons=%d %.3fs", path_filename, #polygon_data, t1 - t0))
    end

    local PathFinder = lnavmesh.PathFinder
    local pf = PathFinder.new()
    local polygons = {}
    for i = 1, #polygon_data do
        local p = polygon_data[i]
        local polygon = lnavmesh.Polygon.new()
        for j = 1, #p do
            local pt = p[j]
            polygon:AddPoint(lnavmesh.Point.new(pt.x, pt.y, 0))
        end
        table.insert(polygons, polygon)
    end
    local t2 = os.clock()
    if NAV_DEBUG then
        skynet.error(string.format("nav_adapter: build polygons %d %.3fs", #polygons, t2 - t1))
    end

    pf:AddPolygons(polygons)
    local t3 = os.clock()
    if NAV_DEBUG then
        skynet.error(string.format("nav_adapter: AddPolygons done %.3fs total=%.3fs %s", t3 - t2, t3 - t0, path_filename))
    end

    self.pathfinder = pf
    return true
end

function mt:findpath(start, target)
    if not self.pathfinder then
        return nil
    end
    local from = lnavmesh.Point.new(start.x, start.y, 0)
    local to = lnavmesh.Point.new(target.x, target.y, 0)
    local raw_path = self.pathfinder:GetPath(from, to)

    local result = {}
    for i = 1, #raw_path do
        local pt = raw_path[i]
        result[i] = { x = pt.x / 100.0, y = pt.y / 100.0 }
    end
    return result
end

return nav_adapter
