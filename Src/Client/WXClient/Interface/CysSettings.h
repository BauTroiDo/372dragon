#pragma once
namespace LuaPlus {class LuaState;}
namespace CysSettings {
void Register(LuaPlus::LuaState* state);
void ApplyRuntime(unsigned flags);
double Value(int index);
int Get(LuaPlus::LuaState* state,unsigned flags);
unsigned Save(LuaPlus::LuaState* state,unsigned flags);
}
