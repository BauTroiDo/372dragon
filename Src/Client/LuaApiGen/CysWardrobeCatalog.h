#pragma once
#include "LuaPlus.h"
namespace pg { class Packet; }
class CObject_Character;
namespace CysWardrobeCatalog {
void Register(LuaPlus::LuaState* state);
void Reset();
bool Dispatch(const pg::Packet& packet);
void Preview(CObject_Character* dst);
bool Ready(int cat);
bool Busy();
bool Owned(int cat, int id);
int Current(int cat);
int Result(int cat);
int PreviewVisual();
int SavedPosition(int cat, int id);
}
