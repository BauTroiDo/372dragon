#pragma once
namespace pg { class Packet; }
namespace CysDualSouls {
void RegisterHost();
bool Dispatch(const pg::Packet&);
bool Drop(int bag,const char* target);
}
