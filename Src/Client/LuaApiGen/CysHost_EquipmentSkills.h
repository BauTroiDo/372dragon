#pragma once
#include <cstdint>
#include <string>
namespace pg { class Packet; struct ItemInfo_bos; }
namespace CysEquipmentSkills {
    void RegisterHost();
    void Reset();
    void Remember(const pg::ItemInfo_bos& item);
    void RequestBagDetails(int slot);
    bool IsWorldPacket(uint16_t id);
    bool Dispatch(const pg::Packet& packet);
    bool IsWuhunSkill(int id);
    bool Preview(int position, int& skill, std::string& name, std::string& icon);
    bool ProbeTick(); // opt-in test15 fixture only; silent and inactive in play builds
    const char* ProbeShotName();
}
