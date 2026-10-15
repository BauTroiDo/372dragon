"""annotations.py - hand-checked facts that cannot be derived from the Lua codecs.

Every entry cites its evidence.  specgen.py merges them into packets.yaml:
  dir     overrides the direction (only for packets without a CG/GC/... prefix)
  derive  name of a decoder plugin in speccodec.DERIVE that rebuilds server-side
          state tested by the conditions (the wire carries a transformed copy)
  note    free text copied to `annotation`
"""

PACKETS = {
    'KeyExchange': {
        'dir': 'GC',
        'note': 'Sent by the server right after CGConnect (services/msgagent.lua:313, '
                'packet_def.KeyExchange.new()); observed S2C with a 10-byte body in '
                'Tools/stress-test/_capture/capture.jsonl. Clients ignore it.',
    },
    'unknow_440': {
        'dir': 'GC',
        'note': 'Unused: no sender and no REQUEST handler anywhere in services/ (grep 2026-09-12). '
                'The direction is a guess.',
    },
    'GCCharBaseAttrib': {
        'derive': 'char_base_attrib_flags',
        'note': 'Conditions test the server-side m_uFlags[1..11]. On the wire they are new_flags[1..14] '
                '(combat.lua bos): new_flags[1] = m_uFlags[1] & 0x7F; for i = 2..11 new_flags[i] = '
                '(m_uFlags[i] << 1 | carry) & 0xFF with carry = previous byte >> 7 (first carry = '
                'm_uFlags[1] >> 7); new_flags[12] = last carry; new_flags[13..14] = DFeng flags. '
                'Receiver: m_uFlags[1] = (nf[1] & 0x7F) | (nf[2] & 1) << 7; m_uFlags[i] = nf[i] >> 1 | '
                '(nf[i+1] & 1) << 7.',
    },
    'GCDetailAttrib_Pet': {
        'derive': 'detail_attrib_pet_flags',
        'note': 'Conditions test the server-side m_Flags[1..11]; the wire carries 12 remapped bytes _nf '
                '(pet_detail_types.lua bos, lines 791-810): new bits 0-1 = old 0-1, 3-8 = old 2-7, '
                '9/10 = hp/hp_max mirrors (old 8/9), 11/12 = _has_rage/_has_rage_max, 90 = elf data, '
                '13.. = old 10... The optional tail (GCStallPetView_t / GCExchangePetView_t, line 1035) '
                'is written only when the server attached extra_data; nothing on the wire announces it, '
                'the receiver can only tell from the remaining body length.',
    },
    'GCPetBankListUPData': {
        'note': 'Each present pet_list[i] is a pre-serialized GCDetailAttrib_Pet body written without a '
                'length prefix (bos: stream:write(pet_data, #pet_data); bis: pet_list[i]:bis(...)). '
                'Decode each element as struct GCDetailAttrib_Pet; bit i-1 of flag says which exist.',
    },
    'CGShowFashionDepotData': {
        'note': 'Direction conflict on id 1032: the server decodes it as CGShowFashionDepotData (handler '
                'request:CGShowFashionDepotData in services/msgagent.lua:1329), while packet_ids.lua notes that '
                'the client uses 1032 for GCYuanBao (server -> client). No server code sends 1032, and the '
                'handler replies with packet_def.GCShowFashionDepotData, whose definition is commented out '
                '(mission.lua:307), so it would raise at run time.',
    },
    'CLAskLogin': {
        'note': 'is_new_format = (body_size - size) >= 412: the new client (uVersion 0x785) inserts '
                'unk_int1/unk_int2 and appends new_byte/new_int; body is 949 bytes when size = 0.',
    },
}
