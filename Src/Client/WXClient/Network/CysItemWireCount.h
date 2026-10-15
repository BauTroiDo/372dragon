#pragma once
#include "PgStructs.h"

namespace CysItemWireCount
{
    // Server item.lua get_lay_count + packet_types/item_types.lua ItemInfo.bos.
    // The fixed EquipInfo in GCNotifyEquip does not carry these stack fields;
    // the following GCItemInfo is authoritative, including for existing stacks.
    inline unsigned Get(const pg::ItemInfo_bos& item)
    {
        switch (item.item_index / 10000000)
        {
        case 2: return item.unknow_19[0];
        case 3: return item.unknow_20[0];
        case 4: return item.unknow_21[0];
        case 5: return item.unknow_22[48];
        default: return item.item_index > 0 ? 1u : 0u;
        }
    }
}
