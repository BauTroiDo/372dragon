#pragma once
namespace pg {class GCItemInfo;}
class tObject_Item;
namespace CysTemBank {
void RegisterHost();
void Snapshot(int kind,int revision);
bool ItemInfo(const pg::GCItemInfo& packet);
bool Owns(tObject_Item* item);
bool Withdraw(tObject_Item* item);
bool Drop(int bagSlot,const char* target);
}
