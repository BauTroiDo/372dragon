local class = require "class"
local iostream = require "iostream"
local pathparser = class("pathparser")

local VERSION_V1 = 0x1000
local VERSION_V2 = 0x2000
local POINTS_PER_POLYGON = 5
local BYTES_PER_POINT = 8
local BYTES_PER_POLYGON = POINTS_PER_POLYGON * BYTES_PER_POINT

local function append_polygons(is, polygons, polygon_count)
    for i = 1, polygon_count do
        local polygon = {}
        for j = 1, POINTS_PER_POLYGON do
            local point = {}
            point.x = is:readfloat()
            point.y = is:readfloat()
            table.insert(polygon, point)
        end
        table.insert(polygons, polygon)
    end
end

function pathparser:load(f)
    local fh = assert(io.open(f, "rb"), string.format("pathparser: open failed: %s", tostring(f)))
    local buffer = fh:read("*a")
    fh:close()

    local bistream = iostream.bistream
    local is = bistream.new()
    is:attach(buffer)

    local version = is:readushort()
    local polygons = {}
    local size = #buffer

    if version == VERSION_V1 then
        local polygon_count = is:readushort()
        local expected_size = 4 + polygon_count * BYTES_PER_POLYGON
        assert(expected_size <= size,
            string.format("pathparser: invalid v1 path file %s, count=%d, size=%d", tostring(f), polygon_count, size))
        append_polygons(is, polygons, polygon_count)
        return polygons
    end

    if version == VERSION_V2 then
        local offset = is:readuint()
        local polygon_bytes = offset * 8
        local expected_size = 6 + polygon_bytes
        assert(expected_size <= size,
            string.format("pathparser: invalid v2 path file %s, offset=%d, size=%d", tostring(f), offset, size))
        local polygon_count = math.floor(polygon_bytes / BYTES_PER_POLYGON)
        append_polygons(is, polygons, polygon_count)
        return polygons
    end

    error(string.format("pathparser: unknown version %d for %s", version, tostring(f)))
end

return pathparser
