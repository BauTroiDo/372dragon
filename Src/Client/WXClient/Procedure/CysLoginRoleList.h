#pragma once

#include "PgPackets_login.h"
#include <string>
#include <vector>

// CYS: owned modern login records. Never overlay these on the 0.85 DB struct.
class CysLoginRoleList
{
    std::vector<pg::LCRetCharList::E_charlist> roles_;

    static bool validName(const std::string& text)
    {
        if (text.empty() || text.size() > 30) return false;
        for (size_t i = 0; i < text.size();)
        {
            const unsigned first = static_cast<unsigned char>(text[i++]);
            unsigned value = first, count = 0, minimum = 0;
            if (first >= 0xc2 && first <= 0xdf) { value &= 0x1f; count = 1; minimum = 0x80; }
            else if (first >= 0xe0 && first <= 0xef) { value &= 0x0f; count = 2; minimum = 0x800; }
            else if (first >= 0xf0 && first <= 0xf4) { value &= 7; count = 3; minimum = 0x10000; }
            else if (first >= 0x80) return false;
            if (i + count > text.size()) return false;
            for (unsigned n = 0; n < count; ++n)
            {
                const unsigned next = static_cast<unsigned char>(text[i++]);
                if ((next & 0xc0) != 0x80) return false;
                value = (value << 6) | (next & 0x3f);
            }
            if (value < minimum || value > 0x10ffff || (value >= 0xd800 && value <= 0xdfff) ||
                value < 0x20 || value == 0x7f) return false;
        }
        return true;
    }

public:
    using Role = pg::LCRetCharList::E_charlist;
    // CY's native charlist carries both legacy compact IDs and full IDs.
    // Older replay fixtures may only populate the compact fields.
    static int Hair(const Role& role) { return role.hair_2 > 0 ? role.hair_2 : role.hair; }
    static int Face(const Role& role) { return role.head_2 > 0 ? role.head_2 : role.head; }
    bool assign(const pg::LCRetCharList& list)
    {
        if (list.unknow != 0 || list.charnum != list.charlist.size() || list.charlist.size() > 3) return false;
        for (size_t i = 0; i < list.charlist.size(); ++i)
        {
            const auto& role = list.charlist[i];
            if (!role.guid || (role.sex != 0 && role.sex != 1) || !validName(role.nickname_text())) return false;
            for (size_t j = 0; j < i; ++j) if (list.charlist[j].guid == role.guid) return false;
        }
        // Validate the complete reply before replacing visible character data.
        auto copy = list.charlist;
        roles_.swap(copy);
        return true;
    }
    const Role* at(int index) const
    { return index >= 0 && static_cast<size_t>(index) < roles_.size() ? &roles_[index] : nullptr; }
    size_t size() const { return roles_.size(); }
    void clear() { roles_.clear(); }
    // Select by identity across reordered server replies. Create success must add
    // exactly one GUID; normal refresh retains the prior GUID when it survives.
    bool replacementSelection(const CysLoginRoleList& previous, int previousIndex,
                              bool created, int& selected) const
    {
        if (created)
        {
            if (size() != previous.size() + 1) return false;
            for (const auto& role : previous.roles_)
                if (findGuid(role.guid) < 0) return false;
            for (size_t i = 0; i < roles_.size(); ++i)
                if (previous.findGuid(roles_[i].guid) < 0)
                { selected = static_cast<int>(i); return true; }
            return false;
        }
        const Role* old = previous.at(previousIndex);
        selected = old ? findGuid(old->guid) : -1;
        if (selected < 0 && !roles_.empty()) selected = 0;
        return true;
    }
    int findGuid(uint32_t guid) const
    {
        for (size_t i = 0; i < roles_.size(); ++i) if (roles_[i].guid == guid) return static_cast<int>(i);
        return -1;
    }
    // CYS-REVIEW 18/09: bo cac o `keep[i] == false` khoi CA danh sach nay LAN vector song song `parallel`.
    //
    // VI SAO NHAN `parallel` BANG THAM CHIEU (co y, dung cham): CGamePro_CharSel::SetModernCharacterList giu
    // `appearances[i]` mo ta `roles_[i]` - hai vector PHAI cung chi so. Neu tach thanh hai lenh loc rieng thi
    // nguoi sua sau chi can quen mot ben la moi nhan vat deo ngoai hinh cua nguoi khac, va khong gi bao loi.
    // Ep truyen ca hai vao MOT lenh lam cho loi do khong viet ra duoc.
    //
    // Tra false va KHONG dong gi neu kich thuoc khong khop (dau hieu goi sai).
    // Thu tu cac o con lai duoc giu nguyen, nen `replacementSelection` van doi chieu theo GUID nhu cu.
    template <class T>
    bool retainWith(const std::vector<bool>& keep, std::vector<T>& parallel)
    {
        if (keep.size() != roles_.size() || parallel.size() != roles_.size()) return false;
        std::vector<Role> roles;
        std::vector<T> kept;
        roles.reserve(roles_.size());
        kept.reserve(parallel.size());
        for (size_t i = 0; i < keep.size(); ++i)
        {
            if (!keep[i]) continue;
            roles.push_back(roles_[i]);
            kept.push_back(parallel[i]);
        }
        roles_.swap(roles);
        parallel.swap(kept);
        return true;
    }
};
