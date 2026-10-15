-- City script queries use the persisted city/building records. BuildingType is
-- the script enum; the keys in city.buildings are client placement indices.
local skynet=require 'skynet'
local config=require 'configenginer':getinstance()
local M={}
function M.install(C)
    function C:CityGetBuildingLevel(selfId,buildingType)
        local rows=config:get_config('city_building') or {}
        local buildings=self.scene.conf and self.scene.conf.buildings or {}
        for _,b in pairs(buildings) do
            local row=rows[tonumber(b.id)]
            if row and tonumber(row.BuildingType)==tonumber(buildingType) then
                return math.max(0,math.min(5,tonumber(b.level) or 0))
            end
        end
        return 0
    end
    function C:CityGetMaintainStatus(selfId,cityId)
        local h=self.scene:get_obj_by_id(selfId)
        if not h or not cityId or cityId<0 then return 1 end
        local city=skynet.call('.Dynamicscenemanager','lua','get_city_by_id',cityId)
        if not city then city=skynet.call('.Dynamicscenemanager','lua','get_city_by_scene_id',cityId) end
        if self.scene:get_obj_by_id(selfId)~=h or not city or city.guild_id~=h:get_guild_id() then return 1 end
        -- Older saved cities have no maintenance state. Preserve their normal
        -- state; never infer/charge an upkeep schedule absent from this server.
        local status=tonumber(city.maintain_status) or 0
        return status>=0 and status<=3 and status or 1
    end
    return C
end
return M
