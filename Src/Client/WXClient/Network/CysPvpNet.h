#pragma once
#include <cstdint>
namespace pg { class Packet; class GCCharBaseAttrib; class GCDetailAttrib; }
class CObject;
namespace CysPvpNet {
void RegisterHost();
void Reset();
void Remove(int id);
void Base(const pg::GCCharBaseAttrib& p);
void Detail(const pg::GCDetailAttrib& p);
bool Dispatch(const pg::Packet& p);
void Observe(const pg::Packet& p);
bool IsWorldPacket(uint16_t id);
bool Relation(CObject* a,CObject* b,bool& enemy);
bool HasAttackers(int objectId);
bool Probe();
}
