#pragma once
namespace pg { class Packet; }
namespace CysRaidNet {
void Reset();
void RegisterHost();
bool IsWorldPacket(unsigned short id);
bool Dispatch(const pg::Packet& packet);
}
