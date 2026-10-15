#pragma once
#include <cstdint>
#include <memory>
class Packet;
namespace pg { class Packet; class GCItemInfo; }
namespace CysPlayerShopNet {
void RegisterHost();
bool IsWorldPacket(uint16_t id);
bool Dispatch(const pg::Packet& p);
bool ItemInfo(const pg::GCItemInfo& p);
std::unique_ptr<pg::Packet> Translate(Packet* p);
}
