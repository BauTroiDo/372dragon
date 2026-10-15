#pragma once
#include "Packet.h"
#include <memory>
namespace pg {class Packet;}
namespace CysGuildNet {
void Reset();
void RegisterHost();
bool IsWorldPacket(unsigned short id);
bool Dispatch(const pg::Packet& packet);
std::unique_ptr<pg::Packet> Translate(Packet* legacy);
}
