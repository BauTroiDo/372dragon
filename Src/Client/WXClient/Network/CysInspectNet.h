#pragma once
#include <cstdint>
class CObject;
namespace pg { class Packet; class GCCharBaseAttrib; }
namespace CysInspectNet {
void RegisterHost();
void Reset();
void Remove(int serverId);
void Base(const pg::GCCharBaseAttrib& packet);
bool Request(CObject* object);
bool AcceptEquipment(int serverId);
void EquipmentReady();
bool IsWorldPacket(uint16_t id);
bool Dispatch(const pg::Packet& packet);
CObject* Target();
}
