




























#include "CysHost_Accel.h"
#include "LuaApiGen.h"
#include "TDUtil.h"   // CYS-HOST2: TDU_Log for the probe line
#include <windows.h> // CYS-HOST2: GetEnvironmentVariableA

#include <cstdio>
#include <cstring>

namespace CysHostAccel
{
    namespace
    {
        struct CysAccelRow
        {
            unsigned short key1;
            unsigned char mod1;
            unsigned short key2;
            unsigned char mod2;
            unsigned char ours;
        };

#include "CysHost_Accel_Table.inc"

        const int kRowCount = (int)(sizeof(kCysAccelRows) / sizeof(kCysAccelRows[0]));

        // CY's own key names, .rdata 0x7dc274..0x7dc338 of client_GL Game.exe: "Shift+", "Alt+", "Ctrl+",
        // "F1".."F12", "PageUp", "PageDown", "Home", "End", "Left", "Up", "Right", "Down", "Delete", "Tab".
        const char* NamedKey(int vk)
        {
            switch (vk)
            {
            case 0x08: return "BackSpace";
            case 0x09: return "Tab";
            case 0x0D: return "Enter";
            case 0x10: return "Shift";
            case 0x11: return "Ctrl";
            case 0x12: return "Alt";
            case 0x1B: return "Esc";
            case 0x20: return "Space";
            case 0x23: return "End";
            case 0x24: return "Home";
            case 0x25: return "Left";
            case 0x26: return "Up";
            case 0x27: return "Right";
            case 0x28: return "Down";
            case 0x21: return "PageUp";
            case 0x22: return "PageDown";
            case 0x2C: return "PrintScreen";
            case 0x2D: return "Insert";
            case 0x2E: return "Delete";
            case 0xBA: return ";";
            case 0xBB: return "=";
            case 0xBC: return ",";
            case 0xBD: return "-";
            case 0xBE: return ".";
            case 0xBF: return "/";
            case 0xC0: return "`";
            case 0xDB: return "[";
            case 0xDC: return "\\";
            case 0xDD: return "]";
            case 0xDE: return "'";
            default: return 0;
            }
        }
    }

    bool KeyText(int vk, int mod, char* out, unsigned capacity)
    {
        if (!out || capacity == 0) return false;
        out[0] = '\0';
        if (vk <= 0) return true;

        char body[24];
        const char* named = NamedKey(vk);
        if (named)
        {
            if (std::strlen(named) >= sizeof(body)) return false;
            std::strcpy(body, named);
        }
        else if (vk >= 0x70 && vk <= 0x7B)          // F1 .. F12
        {
            std::sprintf(body, "F%d", vk - 0x70 + 1);
        }
        else if ((vk >= '0' && vk <= '9') || (vk >= 'A' && vk <= 'Z'))
        {
            body[0] = (char)vk;
            body[1] = '\0';
        }
        else
        {
            std::sprintf(body, "0x%02X", vk);       // unknown: show the code, never a wrong name
        }
























        char text[48];
        text[0] = '\0';
        if (mod & 4) std::strcat(text, "Shift+");
        if (mod & 2) std::strcat(text, "Alt+");
        if (mod & 1) std::strcat(text, "Ctrl+");
        std::strcat(text, body);

        if (std::strlen(text) + 1 > capacity) return false;
        std::strcpy(out, text);
        return true;
    }

    bool RowText(int index, char* key1, unsigned cap1, char* key2, unsigned cap2)
    {
        if (key1 && cap1) key1[0] = '\0';
        if (key2 && cap2) key2[0] = '\0';
        if (index < 0 || index >= kRowCount) return false;
        const CysAccelRow& row = kCysAccelRows[index];
        if (!row.ours) return true;                  // not dispatched here: report no binding at all
        if (key1) KeyText(row.key1, row.mod1, key1, cap1);
        if (key2) KeyText(row.key2, row.mod2, key2, cap2);
        return true;
    }

    int SupportedRowCount()
    {
        int n = 0;
        for (int i = 0; i < kRowCount; ++i) n += kCysAccelRows[i].ours ? 1 : 0;
        return n;
    }

    namespace
    {
        LuaPlus::LuaObject Receiver(LuaPlus::LuaObject& globals, const char* name)
        {
            LuaPlus::LuaObject o = globals.GetByName(name);
            if (o.IsTable()) return o;
            if (o.IsUserData())
            {
                LuaPlus::LuaObject meta = o.GetMetaTable();
                if (!meta.IsTable()) return LuaPlus::LuaObject();
                LuaPlus::LuaObject index = meta.GetByName("__index");
                return index.IsTable() ? index : meta;
            }
            return LuaPlus::LuaObject();
        }

        // SystemSetup:GetInputSetup(i) -> key1, key2. Out-of-range rows answer "", "" like CY's empty defaults;
        // the 0.85 script host has no exception path here, so a bad argument must not throw.
        int SystemSetupGetInputSetup(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            char k1[48] = {0}, k2[48] = {0};
            const int index = args[2].IsNumber() ? (int)args[2].GetNumber() : -1;
            if (index >= 0)
                RowText(index, k1, sizeof(k1), k2, sizeof(k2));
            {   // CYS-HOST2 18/09: what the remap window is actually told. Rows 31..33 are the proof of the
                // modifier-bit fix - they must read "Ctrl+1/2/3", not "Shift+1/2/3" (CYS_HOST2_PROBE=1).
                static int probe = -1, logged = 0;
                if (probe < 0) { char t[4] = {0}; probe = (::GetEnvironmentVariableA("CYS_HOST2_PROBE", t, sizeof(t)) == 1 && t[0] == '1') ? 1 : 0; }
                if (probe == 1 && logged < 80 && index >= 0 && (k1[0] || k2[0]))
                {
                    ++logged;
                    TDU_Log("CYS host2: GetInputSetup(%d) -> key1=\"%s\" key2=\"%s\"", index, k1, k2);
                }
            }
            s->PushString(k1);
            s->PushString(k2);
            return 2;
        }
    }

    int Register(LuaPlus::LuaState* state)
    {
        if (!state) return 0;
        LuaPlus::LuaObject globals = state->GetGlobals();
        LuaPlus::LuaObject table = Receiver(globals, "SystemSetup");
        if (!table.IsTable()) return 0;
        table.Register("GetInputSetup", SystemSetupGetInputSetup);   // forced: replaces the generated stub
        return 1;
    }
}
