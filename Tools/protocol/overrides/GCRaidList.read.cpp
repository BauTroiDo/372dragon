    // The Lua writer flattens five squads. Each record carries both indices;
    // m_nMemberCount is the total record count, not the number of squads.
    if (!r.u32(m_nEventID) || !r.i16(m_TeamID) || !r.i16(m_RaidID) ||
        !r.u32(m_bLeaveRaid) || !r.u8(m_nMemberCount)) return r.fail("short header", "GCRaidList");
    if (m_nMemberCount > 30) return r.fail("too many members", "GCRaidList");
    std::vector<E_member_list> decoded(5);
    bool occupied[5][6] = {};
    uint32_t guids[30] = {};
    for (unsigned i = 0; i < m_nMemberCount; ++i) {
        E_member_list::E_elem m;
        uint8_t nameLen = 0; int16_t guildLen = 0;
        if (!r.u32(m.guid) || !r.u16(m.sceneid) || !r.u16(m.client_res) || !r.i32(m.m_objID) ||
            !r.u8(nameLen) || nameLen > 30 || !r.str(m.text, nameLen) ||
            !r.u32(m.portrait_id) || !r.u16(m.model) || !r.u8(m.m_Position) ||
            !r.u32(m.anon1) || !r.u32(m.anon2) || !r.i16(m.m_ZoneWorldID) ||
            !r.u32(m.m_iFightScore) || !r.i16(guildLen) || guildLen < 0 || guildLen > 32 ||
            !r.str(m.text_2, guildLen) || !r.i32(m.anon3)) return r.fail("invalid member", "GCRaidList");
        if (m.anon1 >= 5 || m.anon2 >= 6 || m.m_Position > 2 || occupied[m.anon1][m.anon2])
            return r.fail("invalid squad position", "GCRaidList");
        for (unsigned j = 0; j < i; ++j) if (guids[j] == m.guid) return r.fail("duplicate guid", "GCRaidList");
        guids[i] = m.guid; occupied[m.anon1][m.anon2] = true;
        decoded[m.anon1].anon1.push_back(m);
    }
    member_list.swap(decoded);
