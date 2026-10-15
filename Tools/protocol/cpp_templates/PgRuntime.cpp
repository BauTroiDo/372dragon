// ProtocolGen runtime (template: CY-Source/Tools/protocol/cpp_templates/PgRuntime.cpp).
#include "PgRuntime.h"

#include <cstdarg>
#include <cstdio>

namespace pg {

namespace {
LogFn g_log = nullptr;
}

void setLogHandler(LogFn fn) { g_log = fn; }

void logf(const char* fmt, ...) {
    if (!g_log) return;
    char buf[512];
    va_list ap;
    va_start(ap, fmt);
    std::vsnprintf(buf, sizeof(buf), fmt, ap);
    va_end(ap);
    buf[sizeof(buf) - 1] = 0;
    g_log(buf);
}

const char* dirName(Dir d) {
    switch (d) {
        case Dir::CG: return "CG";
        case Dir::GC: return "GC";
        case Dir::CGW: return "CGW";
        case Dir::WGC: return "WGC";
        case Dir::CL: return "CL";
        case Dir::LC: return "LC";
    }
    return "?";
}

const char* protoName(Proto p) { return p == Proto::Login ? "login" : "game"; }

// speccodec.py _char_base_attrib_flags
void deriveCharBaseAttribFlags(const uint8_t nf[14], int64_t uFlags[11], int64_t* dfengFlags, int64_t* dfengFlags2) {
    uFlags[0] = (nf[0] & 0x7F) | ((nf[1] & 1) << 7);
    for (int i = 1; i < 11; ++i) uFlags[i] = (nf[i] >> 1) | ((nf[i + 1] & 1) << 7);
    *dfengFlags = nf[12];
    *dfengFlags2 = nf[13];
}

// speccodec.py _detail_attrib_pet_flags (pet_detail_types.lua bos lines 791-810)
void deriveDetailAttribPetFlags(const uint8_t nf[12], int64_t flags[11], bool* hasRage, bool* hasRageMax,
                                bool* elfFlag) {
    for (int k = 0; k < 11; ++k) flags[k] = 0;
    for (int nb = 0; nb < 96; ++nb) {
        if (!((nf[nb >> 3] >> (nb & 7)) & 1)) continue;
        int ob;
        if (nb <= 1)
            ob = nb;
        else if (nb >= 3 && nb <= 10)
            ob = nb - 1;  // 3..8 = old 2..7, 9/10 = hp / hp_max mirrors of old 8/9
        else if (nb >= 13)
            ob = nb - 3;
        else
            continue;  // 2, 11, 12
        if (ob < 88) flags[ob >> 3] |= static_cast<int64_t>(1) << (ob & 7);
    }
    *hasRage = ((nf[11 >> 3] >> (11 & 7)) & 1) != 0;
    *hasRageMax = ((nf[12 >> 3] >> (12 & 7)) & 1) != 0;
    *elfFlag = ((nf[90 >> 3] >> (90 & 7)) & 1) != 0;
}

}  // namespace pg
