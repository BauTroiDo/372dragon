#pragma once
namespace pg { class Packet; class GCDetailAttrib_Pet; struct ItemInfo_bos; }
class tObject_Item;
namespace CysPetSoul {
void RegisterHost();
bool Dispatch(const pg::Packet& packet);
bool Drop(int bag,const char* target);
void Remember(const pg::ItemInfo_bos& item);
void RememberPet(const pg::GCDetailAttrib_Pet& pet);
const pg::ItemInfo_bos* Details(const tObject_Item* item);
}
