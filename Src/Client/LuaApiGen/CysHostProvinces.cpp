#include "CysHostProvinces.h"
#include "LuaPlus.h"
#include <cmath>
#include <limits>
#include <stdexcept>

namespace CysHostProvinces
{
    namespace
    {
        std::int32_t Index(lua_State* state, int argument)
        {
            const double value = std::trunc(lua_tonumber(state, argument));
            if (!std::isfinite(value) || value < (std::numeric_limits<std::int32_t>::min)() || value > (std::numeric_limits<std::int32_t>::max)())
                return (std::numeric_limits<std::int32_t>::min)();
            return static_cast<std::int32_t>(value);
        }
        const Catalog* GetCatalog(lua_State* state)
        {
            return *static_cast<const Catalog* const*>(lua_touserdata(state, lua_upvalueindex(1)));
        }
        const Province* At(const Catalog* catalog, std::int32_t index)
        {
            return index >= 0 && static_cast<std::size_t>(index) < catalog->provinces.size() ? &catalog->provinces[index] : nullptr;
        }
        int Count(lua_State* state)
        {
            const auto* catalog = GetCatalog(state);
            if (!catalog) return luaL_error(state, "DataPool:GetProvincesNum catalog is unavailable");
            lua_pushnumber(state, static_cast<double>(catalog->provinces.size()));
            return 1;
        }
        int Enumerate(lua_State* state)
        {
            if (lua_type(state, 2) != LUA_TNUMBER) return luaL_error(state, "DataPool:EnumProvinces requires a numeric index");
            const auto* catalog = GetCatalog(state);
            if (!catalog) return luaL_error(state, "DataPool:EnumProvinces catalog is unavailable");
            const auto* province = At(catalog, Index(state, 2));
            // B lacks the lower-bound check; CY rejects it instead of reading before the vector.
            if (!province) return luaL_error(state, "DataPool:EnumProvinces index outside catalog");
            lua_pushnumber(state, province->id); lua_pushstring(state, province->name.c_str());
            return 2;
        }
        int CityCount(lua_State* state)
        {
            if (lua_type(state, 2) != LUA_TNUMBER) return luaL_error(state, "DataPool:GetCityNumFromOneProvinceId requires a numeric index");
            const auto* catalog = GetCatalog(state);
            if (!catalog) return luaL_error(state, "DataPool:GetCityNumFromOneProvinceId catalog is unavailable");
            const auto* province = At(catalog, Index(state, 2));
            lua_pushnumber(state, province ? static_cast<double>(province->cities.size()) : -1.0);
            return 1;
        }
        int CityEnumerate(lua_State* state)
        {
            if (lua_type(state, 2) != LUA_TNUMBER || lua_type(state, 3) != LUA_TNUMBER)
                return luaL_error(state, "DataPool:NumCityFromOneProvince requires two numeric indices");
            const auto* catalog = GetCatalog(state);
            if (!catalog) return luaL_error(state, "DataPool:NumCityFromOneProvince catalog is unavailable");
            const auto* province = At(catalog, Index(state, 2));
            const std::int32_t index = Index(state, 3);
            const City* city = province && index >= 0 && static_cast<std::size_t>(index) < province->cities.size() ? &province->cities[index] : nullptr;
            lua_pushnumber(state, city ? city->id : -1); lua_pushstring(state, city ? city->name.c_str() : "");
            return 2;
        }
    }
    unsigned Register(LuaPlus::LuaObject& globals, const Catalog* catalog)
    {
        lua_State* state = globals.GetState()->GetCState();
        const int top = lua_gettop(state);
        try
        {
            globals.PushStack(); lua_pushstring(state, "DataPool"); lua_rawget(state, -2);
            if (lua_type(state, -1) != LUA_TUSERDATA || !lua_getmetatable(state, -1))
                throw std::runtime_error("CysHostProvinces requires the DataPool receiver and metatable");
            lua_getdefaultmetatable(state, LUA_TUSERDATA);
            const bool defaultMetatable = lua_rawequal(state, -1, -2) != 0; lua_pop(state, 1);
            if (defaultMetatable) throw std::runtime_error("CysHostProvinces requires the DataPool receiver and metatable");
            const struct { const char* name; lua_CFunction function; } methods[] = {
                {"GetProvincesNum", Count}, {"EnumProvinces", Enumerate},
                {"GetCityNumFromOneProvinceId", CityCount}, {"NumCityFromOneProvince", CityEnumerate}
            };
            unsigned added = 0;
            for (const auto& method : methods)
            {
                lua_pushstring(state, method.name); lua_gettable(state, -2);
                const bool missing = lua_isnil(state, -1) != 0; lua_pop(state, 1);
                if (!missing) continue;
                lua_pushstring(state, method.name);
                *static_cast<const Catalog**>(lua_newuserdata(state, sizeof(const Catalog*))) = catalog;
                lua_pushcclosure(state, method.function, 1); lua_rawset(state, -3); ++added;
            }
            lua_settop(state, top); return added;
        }
        catch (...) { lua_settop(state, top); throw; }
    }
}
