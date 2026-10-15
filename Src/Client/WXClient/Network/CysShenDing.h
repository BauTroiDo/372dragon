#pragma once
namespace LuaPlus { class LuaState; }
namespace pg { class Packet; }
namespace CysShenDing {
void RegisterHost();
bool Dispatch(const pg::Packet& packet);
int GetData(LuaPlus::LuaState* state,const char* key);
}
