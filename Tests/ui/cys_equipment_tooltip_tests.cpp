// Standalone offline checks for the CY instance-data contract and cache lifetime.
#include "../../Src/Client/WXClient/Network/CysEquipmentTooltipData.h"
#include <iostream>
#include <stdexcept>

static void Require(bool ok, const char* reason) { if (!ok) throw std::runtime_error(reason); }
int main()
{
    try
    {
        CysEquipmentTooltip::Cache cache;
        CysEquipmentTooltip::Snapshot snapshot;
        // Independently specified example: server add_attr sorts bits 0,19,54,
        // so packet values 120,35,27 mean HP120, physical attack35, reduce cold27.
        const uint64_t mask = (uint64_t(1) << 54) | (uint64_t(1) << 19) | 1;
        Require(cache.Remember(1, 2, 99, 10106000, mask, 3, {120, 35, 27}), "valid three-attribute packet rejected");
        Require(cache.Find(1, 2, 99, 10106000, snapshot), "snapshot missing");
        Require(snapshot.values[0] == 120 && snapshot.values[19] == 35 && snapshot.values[54] == 27, "mask rank differs from server order");
        std::string text;
        CysEquipmentTooltip::AppendAttributes(text, snapshot);
        Require(text.find(u8"Giảm kháng Băng +27") != std::string::npos, "CY bit54 became a legacy base attack");
        Require(text.find(u8"Công vật lý +35") != std::string::npos, "physical attack value missing");
        Require(!cache.Find(1, 3, 99, 10106000, snapshot) && !cache.Find(2, 2, 99, 10106000, snapshot), "GUID world/server collision");
        Require(!cache.Find(1, 2, 100, 10106000, snapshot), "GUID serial collision");
        Require(!cache.Find(1, 2, 99, 10106001, snapshot), "old item ID accepted");
        Require(!cache.Remember(0, 0, 0, 10106000, 1, 1, {8}) && !cache.Find(0, 0, 0, 10106000, snapshot), "shop GUID0 cached");
        Require(!cache.Remember(1, 2, 99, 10106000, mask, 2, {120, 35}), "mask/count mismatch accepted");
        Require(!cache.Find(1, 2, 99, 10106000, snapshot), "malformed refresh left stale attributes");
        Require(!cache.Remember(1, 2, 99, 10106000, uint64_t(1) << 58, 1, {9}), "unknown attribute semantics accepted");
        Require(!cache.Remember(1, 2, 99, 10106000, 1, 1, {}), "short value list accepted");
        Require(cache.Remember(1, 2, 99, 10106000, 1, 1, {65535}), "ushort upper bound rejected");
        Require(cache.Find(1, 2, 99, 10106000, snapshot) && snapshot.values[0] == 65535, "ushort value truncated");
        cache.Forget(1, 2, 99);
        Require(!cache.Find(1, 2, 99, 10106000, snapshot), "removed item persisted");
        Require(cache.Remember(1, 2, 99, 10106000, 0, 0, {}), "ordinary white item rejected");
        cache.ConnectionOpened(2);
        Require(cache.Find(1, 2, 99, 10106000, snapshot), "scene transfer dropped details behind GET_MORE_INFO");
        cache.ConnectionOpened(1);
        Require(!cache.Find(1, 2, 99, 10106000, snapshot), "new login session retained prior account details");
        Require(cache.Remember(1, 2, 99, 10106000, 0, 0, {}), "refresh after new login rejected");
        // Independent read-only test13 census: Anqi common block, not aq_* specific fields.
        Require(cache.Remember(10, 1, 50, 10155004, 136339441844224ULL, 5, {1, 1, 1, 1, 1}), "test13 Anqi common attributes rejected");
        Require(cache.Find(10, 1, 50, 10155004, snapshot), "test13 Anqi snapshot missing");
        text.clear(); CysEquipmentTooltip::AppendAttributes(text, snapshot);
        Require(text == u8"Sức mạnh +1\nLinh khí +1\nThể lực +1\nĐịnh lực +1\nThân pháp +1", "test13 five common attributes differ from live census");
        cache.Clear();
        Require(!cache.Find(1, 2, 99, 10106000, snapshot), "session reset left stale item");
        std::cout << "PASS CY mask order, bit54 meaning, GUID identity, zero GUID, malformed refresh, value bounds, remove, scene transfer, new session, Anqi census and terminal reset\n";
        return 0;
    }
    catch (const std::exception& e) { std::cerr << "FAIL " << e.what() << '\n'; return 1; }
}
