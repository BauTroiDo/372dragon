#pragma once
// CYS-INV: bag / equipment / NPC shop on the modern (skynet CY) protocol. Game.exe main thread only.
// Outbound: 0.85 packet classes of the UI (CActionItem_Item::DoAction, NpcShop, DataPool) -> ProtocolGen.
// Inbound: ports of the 0.85 GC handlers (Network/PacketHandler) onto the ProtocolGen structs.
// Wire layouts and server behaviour: Docs/specs/net/inventory-equip_vi.md.

#include <cstdint>
#include <memory>

class Packet;
namespace pg { class Packet; }

namespace CysInventoryNet
{
    // Translate one whitelisted 0.85 packet (nullptr = not an inventory packet).
    std::unique_ptr<pg::Packet> Translate(Packet* legacy);
    // A world packet of this module (stashed until the scene is ready).
    bool IsWorldPacket(uint16_t id);
    // Returns true when the packet was consumed.
    bool Dispatch(const pg::Packet& packet);
    // Counters for logs/tests.
    struct Counters { unsigned useEquip, unEquip, equipLists, charEquipments, shopLists, shopBuys, shopSells, soldLists, discards, swaps, splits, useItems, eventLists, packs; };
    Counters Get();
    // Lua host functions of the CY bag/equip/shop windows (LuaApiGen/CysHost_Package); idempotent, main thread.
    void RegisterHost();
    // GCBagSizeChange (143): prop/material page sizes (defaults until the first answer).
    int BagSize(int bag);
    // The shop option (type 7) of the last NPC event list; false when the menu had none.
    bool LastShopOption(int& scriptId, int& index);
}
