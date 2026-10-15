// CYS-ACCEL: Lua glue of the CY key-remap window. See CysHost_Accel.h.
//
// What CY does, read out of client_GL\Bin64\Game.exe at the catalog's impl_va (listings in
// Build/Logs/2026-09-17-host-plumbing/measure/disasm/):
//
//   SystemSetup:GetInputSetup(i)      0x140327d20 - lua_type(2) must be a number, else it throws
//       "SystemSetup::Lua_GetInputSetup[2] param parameter error"; then two accessors on the accelerator
//       manager (0x1409c26e0 -> +0x58 -> 0x140434610 and 0x140434630) return the text of binding 1 and
//       binding 2 of row i, and both are pushed as strings.  AcceSetup.lua:327-341 reads them as
//       "key1,key2" and prints CY's own "none" text when either is "".
//   SystemSetup:InputSetup_OnOff(a,b,i)  0x140327b60 - three type checks (boolean, boolean, number), then
//       three setters on the same manager.  AcceSetup.lua calls it (true,true,id) from the plain-key button
//       and (true,false,id) from the Alt-key button, i.e. "start capturing a new key for slot 1 / slot 2".
//   SystemSetup:ComeBackAcce()        0x140327cc0 - one call, "restore the default bindings".
//   SystemSetup:GetIsConfigChanged()  0x14032e440 - pushes the int at +0x18 of the boxed SystemSetup object.
//
// ONLY GetInputSetup is implemented, deliberately:
//   * GetIsConfigChanged would have to answer 0 on this build (nothing tracks a settings change) and the
//     generated stub already pushes 0 - a host function that returns the stub's value is not worth having,
//     it only costs the "missing host function" telemetry.  Same for ComeBackAcce, whose honest behaviour
//     here is a no-op because the bindings are compile-time constants.
//   * InputSetup_OnOff cannot be implemented at all yet: this build dispatches accelerators from a hard-coded
//     switch on scancodes (GamePro_Main.cpp ProcessInput_Keybord), so there is nothing to rebind.  Leaving its
//     stub in place keeps that fact visible in WXClient.log instead of making the button look like it worked.
//
// The table below is CY's own, copied verbatim from its .data (CysHost_Accel_Table.inc, regenerate with
// scripts/23-gen-accel-inc.py).  Its index space is what AcceSetup.lua hard-codes: "AcceArryEx = 10" plus the
// comment that the first 11 rows are not user-editable matches rows 0..10 exactly.  A row this build does not
// dispatch reports "" so the window shows "none" - the truth - rather than a key that would do nothing.
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

        // CYS-HOST2 18/09 (SUA LOI): mod bits are 1 = Ctrl, 2 = Alt, 4 = Shift - this file had Shift and Ctrl
        // swapped, so five rows (eight bindings) told the player a wrong key, e.g. "Shift+N" where CY shows
        // "Ctrl+N". A host function that answers WRONG is worse than a stub, so this is the bug that mattered.
        //
        // Read from B, not assumed (Build/Logs/2026-09-17-host-2/re/KeyText_140435eb0.txt and
        // AccelTableConsumer_140434617.txt):
        //   The single consumer of the 79-row table (client_GL Game.exe 0x140434610, the only `lea` to
        //   .data 0x998990 in .text) does NOT read two u16 fields.  It reads ONE u32 per key slot -
        //       edx = *(u32*)(0x998990 + 48*i)      // slot 1 ("NonChatActive" == 1)
        //       edx = *(u32*)(0x998994 + 48*i)      // slot 2 (chat has the keyboard)
        //   - and hands it to KeyText (0x140435eb0), which peels the modifier bits off the key code:
        //       ebx >= 0x40000 -> "Shift+"   ebx >= 0x20000 -> "Alt+"   ebx >= 0x10000 -> "Ctrl+"
        //   So the "mod" byte this table keeps is simply that u32 >> 16: bit 0 = 0x10000 = Ctrl,
        //   bit 1 = 0x20000 = Alt, bit 2 = 0x40000 = Shift.  The numbers host-plumbing extracted are right;
        //   only the three names were assigned in the wrong order.
        //   Corroboration in the data: rows 2 and 3 are VK 'N' and 'G' with mod 1 - Ctrl+N / Ctrl+G, the usual
        //   shape of a shortcut, not Shift+N / Shift+G.
        //
        // DELIBERATE DEVIATION (bounded, documented): B's KeyText is an if / else-if / else-if with ONE append,
        // so for a row that carries two modifiers (mod 3: rows 4 and 5, prev/next chat channel) it prints only
        // the strongest one and leaves the other bit inside the key code, which then matches no key name. This
        // build concatenates every modifier present, in B's own precedence order, so those two rows read
        // "Alt+Ctrl+," instead of a broken half-name. Never shows a key the build would not dispatch.
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
