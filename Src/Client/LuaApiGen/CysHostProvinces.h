// CYS: typed province/city catalog from CityIdOfChina; see login-remaining_vi.md.
#pragma once
#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>
namespace LuaPlus { class LuaObject; }
namespace CysHostProvinces
{
    struct City { std::int32_t id; std::string name; };
    struct Province { std::int32_t id; std::string name; std::vector<City> cities; };
    struct Catalog { std::vector<Province> provinces; };
    // Supported sources: five-column binary DBC or four/five-column TSV DBC.
    // Text may be UTF-8 or legacy CP936; malformed tables are rejected.
    // Result owns UTF-8 strings; parse failure publishes no partial catalog.
    Catalog Parse(const char* bytes, std::size_t size);
    // Catalog is borrowed and must outlive the Lua state. Existing slots stay intact.
    unsigned Register(LuaPlus::LuaObject& globals, const Catalog* catalog);
}
