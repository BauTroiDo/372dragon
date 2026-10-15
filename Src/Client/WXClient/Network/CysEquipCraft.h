#pragma once
namespace pg { class Packet; }
namespace CysEquipCraft { void RegisterHost(); bool Drop(int,const char*); bool Dispatch(const pg::Packet&); }
