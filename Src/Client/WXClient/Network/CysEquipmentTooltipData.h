#pragma once
// Display-only CY attributes. Never reinterpret this order as 0.85 _ITEM_ATTR.
// Server item.lua:add_attr sorts set bits; packet_types/item_types.lua:bos emits
// their ushort values in that order. In CY, bits 54..57 reduce elemental resistance.
#include <array>
#include <cstdint>
#include <map>
#include <string>
#include <vector>

namespace CysEquipmentTooltip
{
    struct Snapshot
    {
        int itemIndex = 0;
        uint64_t mask = 0;
        std::array<uint16_t, 58> values{};
        uint8_t quality = 0, gemSlots = 0, enhancement = 0;
        std::array<int32_t, 4> gems{};
        std::string creator;
        uint8_t status = 0, reshuffles = 0, advance = 0, feature = 0;
        uint16_t diaowen = 0;
        int16_t advanceExp = 0;
        std::array<uint8_t, 6> qualifications{};
        uint8_t equipType = 0, darkLevel = 0;
    };
    class Cache
    {
        std::map<uint64_t, Snapshot> items;
        static uint64_t Key(uint8_t world, uint8_t server, uint32_t serial)
        { return (static_cast<uint64_t>(world) << 40) | (static_cast<uint64_t>(server) << 32) | serial; }
    public:
        void Metadata(uint8_t world, uint8_t server, uint32_t serial, uint8_t quality,
                      uint8_t slots, uint8_t enhancement, const std::array<int32_t,4>& gems, const std::string& creator)
        {
            auto found=items.find(Key(world,server,serial)); if(found==items.end())return;
            auto& item=found->second;item.quality=quality>9?9:quality;item.gemSlots=slots>4?4:slots;
            item.enhancement=enhancement;item.gems=gems;item.creator=creator;
        }
        void Clear() { items.clear(); }
        void Details(uint8_t world, uint8_t server, uint32_t serial, uint8_t status,
                     const std::array<uint8_t,6>& qualifications, uint16_t diaowen,
                     uint8_t reshuffles, uint8_t advance, int16_t advanceExp, uint8_t feature,
                     uint8_t equipType=0, uint8_t darkLevel=0)
        {
            auto found=items.find(Key(world,server,serial));if(found==items.end())return;
            auto& item=found->second;item.status=status;item.qualifications=qualifications;
            item.diaowen=diaowen;item.reshuffles=reshuffles;item.advance=advance;
            item.advanceExp=advanceExp;item.feature=feature;item.equipType=equipType;item.darkLevel=darkLevel;
        }
        // GameClient starts each session at generation 1; later sockets are scene transfers.
        void ConnectionOpened(uint32_t generation) { if (generation <= 1) Clear(); }
        void Forget(uint8_t world, uint8_t server, uint32_t serial) { items.erase(Key(world, server, serial)); }
        bool Remember(uint8_t world, uint8_t server, uint32_t serial, int itemIndex,
                      uint64_t mask, unsigned count, const std::vector<uint16_t>& values)
        {
            const uint64_t key = Key(world, server, serial);
            // A shop template has no instance GUID; never share its details by item ID.
            if (!key) return false;
            items.erase(key); // a malformed/new-type update must not leave old details visible
            if (itemIndex / 10000000 != 1 || count > 16 || count != values.size() || (mask >> 58)) return false;
            unsigned bits = 0;
            for (uint64_t remaining = mask; remaining; remaining &= remaining - 1) ++bits;
            if (bits != count) return false;
            Snapshot snapshot; snapshot.itemIndex = itemIndex; snapshot.mask = mask;
            unsigned position = 0;
            for (unsigned bit = 0; bit < snapshot.values.size(); ++bit)
                if (mask & (uint64_t(1) << bit)) snapshot.values[bit] = values[position++];
            items[key] = snapshot;
            return true;
        }
        bool Find(uint8_t world, uint8_t server, uint32_t serial, int itemIndex, Snapshot& out) const
        {
            const uint64_t key = Key(world, server, serial);
            const auto found = items.find(key);
            if (!key || found == items.end() || found->second.itemIndex != itemIndex) return false;
            out = found->second;
            return true;
        }
    };
    inline bool IsPercent(unsigned bit)
    {
        return bit == 1 || bit == 4 || bit == 8 || bit == 11 || bit == 14 || bit == 17 || bit == 18 ||
            bit == 20 || bit == 21 || bit == 23 || bit == 24 || bit == 25 || bit == 27 || bit == 28 || bit == 30 ||
            bit == 31 || bit == 32 || bit == 38 || bit == 39 || bit == 40 || bit == 41 || bit == 49 || bit == 50 || bit == 53;
    }
    inline void AppendAttributes(std::string& text, const Snapshot& snapshot)
    {
        // Meanings from the live server define.EQUIP_ATTR, not the legacy label array.
        static const char* labels[58] = {
            u8"Sinh lực tối đa", u8"Sinh lực tối đa", u8"Hồi phục sinh lực",
            u8"Nội lực tối đa", u8"Nội lực tối đa", u8"Hồi phục nội lực",
            u8"Băng công", u8"Kháng Băng", u8"Giảm kháng Băng tối thiểu",
            u8"Hỏa công", u8"Kháng Hỏa", u8"Giảm kháng Hỏa tối thiểu",
            u8"Huyền công", u8"Kháng Huyền", u8"Giảm kháng Huyền tối thiểu",
            u8"Độc công", u8"Kháng Độc", u8"Giảm kháng Độc tối thiểu",
            u8"Giảm sát thương thuộc tính", u8"Công vật lý", u8"Công vật lý",
            u8"Công vật lý cơ bản trang bị", u8"Phòng vật lý", u8"Phòng vật lý",
            u8"Phòng vật lý cơ bản trang bị", u8"Giảm sát thương vật lý",
            u8"Công pháp thuật", u8"Công pháp thuật", u8"Công pháp thuật cơ bản trang bị",
            u8"Phòng pháp thuật", u8"Phòng pháp thuật", u8"Phòng pháp thuật cơ bản trang bị",
            u8"Giảm sát thương pháp thuật", u8"Tốc độ tấn công", u8"Tốc độ hồi chiêu",
            u8"Chính xác", u8"Né tránh", u8"Hội tâm", u8"Bỏ qua phòng ngự",
            u8"Tốc độ di chuyển", u8"Phản sát thương", u8"Nội lực hấp thụ sát thương",
            u8"Sức mạnh", u8"Linh khí", u8"Thể lực", u8"Định lực", u8"Thân pháp",
            u8"Phòng thủ hội tâm", u8"Tất cả thuộc tính cơ bản", u8"Hút sinh lực",
            u8"Hút nội lực", u8"Cấp kỹ năng", u8"Cấp tất cả kỹ năng", u8"Xác suất kỹ năng đặc biệt",
            u8"Giảm kháng Băng", u8"Giảm kháng Hỏa", u8"Giảm kháng Huyền", u8"Giảm kháng Độc"
        };
        for (unsigned bit = 0; bit < snapshot.values.size(); ++bit)
        {
            if (!(snapshot.mask & (uint64_t(1) << bit)) || !snapshot.values[bit]) continue;
            if (!text.empty()) text += '\n';
            text += labels[bit]; text += " +"; text += std::to_string(snapshot.values[bit]);
            if (IsPercent(bit)) text += '%';
        }
    }
}
