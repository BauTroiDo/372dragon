#pragma once
// CYS-MOVE2: engine-free core of the CY 3.71 accelerator table (CAccelerateManager). Everything in this header was
// read out of client_GL\Bin64\Game.exe (sha256 ce0c4fec...) on 18/09/2026 - the addresses are the evidence:
//
//   table          .data 0x140998980, 79 entries x 0x30:
//                    +0x00 u32 id (callback argument; 200.. for the 11 fixed rows, 1..54 and 100..113 for the rest)
//                    +0x08 char* StrDictionary key, +0x10 u32 key1, +0x14 u32 key2, +0x18 fn_down, +0x20 fn_up,
//                    +0x28 u32 flags (bit 8 = usable while dead)
//   packed key     vk | Ctrl<<16 | Alt<<17 | Shift<<18   (processKeyMessage 0x140433ea0: GetKeyState(VK_CONTROL)
//                  -> bts 0x10, VK_MENU -> bts 0x11, VK_SHIFT -> bts 0x12; KeyText 0x140435eb0: 0x40000 "Shift+",
//                  0x20000 "Alt+", 0x10000 "Ctrl+").  So in the u16 mod field 1 = Ctrl, 2 = Alt, 4 = Shift.
//                  (CysHost_Accel_Table.inc's comment "1 Shift, 4 Ctrl" has these two swapped; the numbers are right.)
//   dispatch       processKeyMessage: BOTH bindings of every row are live all the time; while an IME edit box is
//                  active a key without Ctrl/Alt that belongs to the text set (0x1404352a0) is left to the edit box;
//                  key-down and key-up are dispatched (fn_down / fn_up), keyboard auto-repeat is ignored; a dead
//                  character only fires rows with flags bit 8.
//   capture        InputSetup_OnOff(true, slot, id) -> 0x140437050: Esc cancels; a key from the "chat" list
//                  (0x1404357e0 +0x20: Alt+A..Z, Alt/Ctrl+0..9, F1..F12, Alt+Delete, Ctrl+Tab, Alt+punctuation)
//                  goes to binding 2, one from the "plain" list (+0x15c: A..Z, 0..9, Ctrl+0..9, F1..F12, Delete, Tab,
//                  punctuation) to binding 1, anything else is refused with ZDYKJJ_20071227_02; the same key on
//                  another row is cleared there (ZDYKJJ_20071227_03) - 0x140435b80; the window is told with
//                  TOGLE_INPUTSETUP(key1 text, key2 text, id).
//   file           "..\Accounts\%s\Acce_Custom.ini" (0x140408b64), one [ACCE_CUSTOM_%d] section per editable row
//                  with id=, key1=, key2= (0x140434880 writes, 0x140435420 reads).
#include <cstdio>
#include <cstdlib>
#include <cstring>

namespace CysAccelCore
{
    enum { kRows = 79, kFixedRows = 11 };
    enum { kModCtrl = 1, kModAlt = 2, kModShift = 4 };
    enum { kFlagUsableWhileDead = 0x100 };

    inline unsigned Pack(unsigned vk, unsigned mod) { return (vk & 0xFFFFu) | ((mod & 7u) << 16); }
    inline unsigned Vk(unsigned packed) { return packed & 0xFFFFu; }
    inline unsigned Mod(unsigned packed) { return (packed >> 16) & 7u; }

    // What a row does. The dispatcher (CysAccelTable.cpp) turns these into engine calls; the CY callback each one
    // mirrors is named in kRowMeta.
    enum Action
    {
        ACT_NONE = 0,
        ACT_ESCAPE,             // 0x140438300: chat close / OnPushEcsape + cancel the mouse skill
        ACT_CHAT_OPEN,          // 0x140439c00: UISystem->[0x1e0](true)
        ACT_CHAT_GM_PREV,       // 0x140438f30 ',': chat GM history up   (0x14034ca40)
        ACT_CHAT_GM_NEXT,       // 0x140438f30 '.': chat GM history down (0x14034cd80)
        ACT_DEBUG,              // debug-only rows (gated on byte 0x1409b64a4 / EnableDebugReport); nothing here
        ACT_SYSTEM_LOCKKEY,     // CapsLock / ScrollLock / NumLock rows: lock-key bookkeeping of CY, nothing here
        ACT_SCREENSHOT,         // PrintScreen: fn_up 0x140438220 (screenshot on release)
        ACT_MENUBAR,            // F1..F10: MainMenuBar_DoAction((id-1) + 10*page, down)
        ACT_MENUBAR_SLOT,       // 1..0 (slot id+19 = 30..39) and custom rows (id-35 = 70..78): MainMenuBar_DoAction
        ACT_EVENT_ACC,          // PushEvent(GE_ACCELERATE_KEYSEND, arg)
        ACT_HELP,               // H: CHelperSystem::GotoAnchorHelp("")
        ACT_JUMP,               // J: PushCommand_Jump unless stalling
        ACT_ZOOM_IN,            // Alt+Up: Camera_SetZoom(TRUE, 2)
        ACT_ZOOM_OUT,           // Alt+Down: Camera_SetZoom(FALSE, 2)
        ACT_UP,                 // Up: chat history up when chatting, else zoom in
        ACT_DOWN,               // Down: chat history down when chatting, else zoom out
        ACT_SCENE_MAP,          // Tab: 0x140438840 pushes TOGLE_SCENE_MAP {szSceneMap, "2"} + the two minimap flags.
                                // CY does NOT lock a target with Tab - the whole callback is only this push
                                // (event id 0x78 = TOGLE_SCENE_MAP, flags at 0x1409c13c0/0x1409c13c1). Measured
                                // 18/09 by disassembling the row-57 callback end to end.
        ACT_EVENT_NAMED,        // PushEventByName(arg) with no argument
        ACT_EVENT_NAMED_INT,    // PushEventByName(arg, -1)
        ACT_STOP_TEAM_FOLLOW,   // K: send CGStopTeamFollow (1263)
        ACT_XIULIAN_PAGE,       // P: level >= 70 -> OPEN_XIULIAN_PAGE(-1)
        ACT_ALT_TOOLTIP,        // Alt: UPDATE_SUPERTOOLTIP "altkeydown"/"altkeyup" + SHOW_SUPERTOOLTIP2
        ACT_CY_NOT_PORTED,      // CY does something this build has no equivalent for: logged, nothing else
    };

    struct RowMeta
    {
        unsigned short id;       // +0x00 of the CY entry (the callback argument and the AcceSetup id)
        unsigned short flags;    // +0x28 of the CY entry
        unsigned char  action;
        unsigned char  hasUp;    // CY entry has fn_up
        const char*    arg;      // event name / note
        const char*    cy;       // CY callback address (evidence)
    };

    // One line per CY entry, same order as the table (and as CysHost_Accel_Table.inc).
    static const RowMeta kRowMeta[kRows] =
    {
        { 200, 0x100, ACT_ESCAPE,           0, "",                          "0x140438300" }, //  0 Esc
        { 201, 0x100, ACT_CHAT_OPEN,        0, "",                          "0x140439c00" }, //  1 Enter
        { 202, 0x000, ACT_DEBUG,            0, "Ctrl+N gfx debug 10",       "0x1404387c0" }, //  2
        { 203, 0x100, ACT_DEBUG,            0, "Ctrl+G gfx debug",          "0x1404384d0" }, //  3
        { 204, 0x000, ACT_CHAT_GM_PREV,     0, "",                          "0x140438f30" }, //  4 Ctrl+Alt+,
        { 205, 0x000, ACT_CHAT_GM_NEXT,     0, "",                          "0x140438f30" }, //  5 Ctrl+Alt+.
        { 206, 0x100, ACT_DEBUG,            0, "Ctrl+` EnableDebugReport",  "0x140439950" }, //  6
        { 207, 0x100, ACT_SYSTEM_LOCKKEY,   0, "CapsLock",                  "0x1404399f0" }, //  7
        { 208, 0x100, ACT_SYSTEM_LOCKKEY,   0, "ScrollLock",                "0x140439b10" }, //  8
        { 209, 0x100, ACT_SYSTEM_LOCKKEY,   0, "NumLock",                   "0x140439b50" }, //  9
        { 210, 0x100, ACT_SCREENSHOT,       1, "PrintScreen",               "0x140438220" }, // 10
        {   1, 0x001, ACT_MENUBAR,          1, "",                          "0x140438370" }, // 11 F1
        {   2, 0x001, ACT_MENUBAR,          1, "",                          "0x140438370" }, // 12 F2
        {   3, 0x001, ACT_MENUBAR,          1, "",                          "0x140438370" }, // 13 F3
        {   4, 0x001, ACT_MENUBAR,          1, "",                          "0x140438370" }, // 14 F4
        {   5, 0x001, ACT_MENUBAR,          1, "",                          "0x140438370" }, // 15 F5
        {   6, 0x001, ACT_MENUBAR,          1, "",                          "0x140438370" }, // 16 F6
        {   7, 0x001, ACT_MENUBAR,          1, "",                          "0x140438370" }, // 17 F7
        {   8, 0x001, ACT_MENUBAR,          1, "",                          "0x140438370" }, // 18 F8
        {   9, 0x001, ACT_MENUBAR,          1, "",                          "0x140438370" }, // 19 F9
        {  10, 0x001, ACT_MENUBAR,          1, "",                          "0x140438370" }, // 20 F10
        {  11, 0x001, ACT_MENUBAR_SLOT,     1, "30",                        "0x1404383f0" }, // 21 1 / Alt+1
        {  12, 0x001, ACT_MENUBAR_SLOT,     1, "31",                        "0x1404383f0" }, // 22 2
        {  13, 0x001, ACT_MENUBAR_SLOT,     1, "32",                        "0x1404383f0" }, // 23 3
        {  14, 0x001, ACT_MENUBAR_SLOT,     1, "33",                        "0x1404383f0" }, // 24 4
        {  15, 0x001, ACT_MENUBAR_SLOT,     1, "34",                        "0x1404383f0" }, // 25 5
        {  16, 0x001, ACT_MENUBAR_SLOT,     1, "35",                        "0x1404383f0" }, // 26 6
        {  17, 0x001, ACT_MENUBAR_SLOT,     1, "36",                        "0x1404383f0" }, // 27 7
        {  18, 0x001, ACT_MENUBAR_SLOT,     1, "37",                        "0x1404383f0" }, // 28 8
        {  19, 0x001, ACT_MENUBAR_SLOT,     1, "38",                        "0x1404383f0" }, // 29 9
        {  20, 0x001, ACT_MENUBAR_SLOT,     1, "39",                        "0x1404383f0" }, // 30 0
        {  21, 0x001, ACT_EVENT_ACC,        0, "acc_MainMenuBarPageOne",    "0x140439d90" }, // 31 Ctrl+1
        {  22, 0x001, ACT_EVENT_ACC,        0, "acc_MainMenuBarPageTwo",    "0x140439d90" }, // 32 Ctrl+2
        {  23, 0x001, ACT_EVENT_ACC,        0, "acc_MainMenuBarPageThree",  "0x140439d90" }, // 33 Ctrl+3
        {  24, 0x001, ACT_CY_NOT_PORTED,    0, "F12: world flag +0x41 / scene +0x370 (0x140438650)", "0x140438650" }, // 34
        {  25, 0x001, ACT_CY_NOT_PORTED,    0, "Ctrl+Tab: throttled world refresh 0x1400efb80 (0x140439990)", "0x140439990" }, // 35
        {  26, 0x001, ACT_EVENT_ACC,        0, "acc_selfequip",             "0x140437f80" }, // 36 C
        {  27, 0x001, ACT_EVENT_ACC,        0, "acc_packet",                "0x140437fe0" }, // 37 A
        {  28, 0x001, ACT_EVENT_ACC,        0, "acc_skill",                 "0x140438020" }, // 38 S
        {  29, 0x001, ACT_EVENT_ACC,        0, "acc_quest",                 "0x140438060" }, // 39 Q
        {  30, 0x001, ACT_EVENT_ACC,        0, "acc_friend",                "0x1404380a0" }, // 40 F
        {  31, 0x001, ACT_EVENT_ACC,        0, "acc_team",                  "0x1404380e0" }, // 41 T
        {  32, 0x001, ACT_EVENT_ACC,        0, "acc_exchange",              "0x140438120" }, // 42 E
        {  33, 0x001, ACT_EVENT_ACC,        0, "acc_pet",                   "0x1404382c0" }, // 43 X
        {  34, 0x001, ACT_EVENT_ACC,        0, "acc_guild",                 "0x140438160" }, // 44 O
        {  35, 0x001, ACT_EVENT_ACC,        0, "acc_face",                  "0x1404381e0" }, // 45 D
        {  36, 0x001, ACT_EVENT_ACC,        0, "acc_chatmod",               "0x1404381a0" }, // 46 -
        {  37, 0x001, ACT_HELP,             0, "",                          "0x140438540" }, // 47 H
        {  38, 0x001, ACT_CY_NOT_PORTED,    0, "Z: InfoBrowser item browser (0x140438fa0)", "0x140438fa0" }, // 48
        {  39, 0x001, ACT_EVENT_ACC,        0, "acc_resetcamera",           "0x140438800" }, // 49 V
        {  40, 0x001, ACT_JUMP,             0, "",                          "0x1404385e0" }, // 50 J
        {  41, 0x001, ACT_EVENT_ACC,        0, "acc_worldmap",              "0x140438780" }, // 51 M
        {  42, 0x001, ACT_CY_NOT_PORTED,    0, "W: singleton 0x1409b7900 lookup (0x1401da0e0)", "0x140437fc0" }, // 52
        {  43, 0x001, ACT_EVENT_ACC,        0, "acc_prevchannel",           "0x140438ee0" }, // 53 ,
        {  44, 0x001, ACT_EVENT_ACC,        0, "acc_nextchannel",           "0x140438ee0" }, // 54 .
        {  45, 0x001, ACT_ZOOM_IN,          0, "",                          "0x140438da0" }, // 55 Alt+Up
        {  46, 0x001, ACT_ZOOM_OUT,         0, "",                          "0x140438da0" }, // 56 Alt+Down
        {  47, 0x101, ACT_SCENE_MAP,        0, "",                          "0x140438840" }, // 57 Tab
        {  48, 0x001, ACT_EVENT_ACC,        0, "acc_clearchat",             "0x140438ea0" }, // 58 Delete
        {  49, 0x001, ACT_EVENT_NAMED,      0, "MINMAP_PLAYERLIST_SHOW",    "0x140439e40" }, // 59 R
        {  50, 0x001, ACT_CY_NOT_PORTED,    0, "I: auto-battle/stall gated toggle (0x140439e70)", "0x140439e70" }, // 60
        {  51, 0x001, ACT_STOP_TEAM_FOLLOW, 0, "",                          "0x14043a030" }, // 61 K
        {  52, 0x001, ACT_EVENT_NAMED_INT,  0, "TOGGLE_WUHUN_PAGE",         "0x14043a0a0" }, // 62 B
        {  53, 0x001, ACT_XIULIAN_PAGE,     0, "OPEN_XIULIAN_PAGE",         "0x14043a0e0" }, // 63 P
        {  54, 0x001, ACT_CY_NOT_PORTED,    0, "L: TRIGGER_ZIDONGZHANDOU start/stop needs the auto-battle state (0x14043a140)", "0x14043a140" }, // 64
        { 100, 0x001, ACT_UP,               0, "",                          "0x140438df0" }, // 65 Up
        { 101, 0x001, ACT_DOWN,             0, "",                          "0x140438df0" }, // 66 Down
        { 102, 0x001, ACT_EVENT_NAMED,      0, "OPEN_AUTOSEARCH",           "0x140439e10" }, // 67 `
        { 103, 0x101, ACT_CY_NOT_PORTED,    0, "F11: UISystem show/hide all (vt+0x260/+0x268) - no engine API here", "0x140439ba0" }, // 68
        { 104, 0x000, ACT_ALT_TOOLTIP,      1, "",                          "0x14043a190" }, // 69 Alt
        { 105, 0x001, ACT_MENUBAR_SLOT,     1, "70",                        "0x140438460" }, // 70 custom
        { 106, 0x001, ACT_MENUBAR_SLOT,     1, "71",                        "0x140438460" }, // 71
        { 107, 0x001, ACT_MENUBAR_SLOT,     1, "72",                        "0x140438460" }, // 72
        { 108, 0x001, ACT_MENUBAR_SLOT,     1, "73",                        "0x140438460" }, // 73
        { 109, 0x001, ACT_MENUBAR_SLOT,     1, "74",                        "0x140438460" }, // 74
        { 110, 0x001, ACT_MENUBAR_SLOT,     1, "75",                        "0x140438460" }, // 75
        { 111, 0x001, ACT_MENUBAR_SLOT,     1, "76",                        "0x140438460" }, // 76
        { 112, 0x001, ACT_MENUBAR_SLOT,     1, "77",                        "0x140438460" }, // 77
        { 113, 0x001, ACT_MENUBAR_SLOT,     1, "78",                        "0x140438460" }, // 78
    };

    // Default bindings: the CY table itself, generated into CysHost_Accel_Table.inc by host-plumbing
    // (Build/Logs/2026-09-17-host-plumbing/scripts/23-gen-accel-inc.py). Only key/mod are read; 'ours' is ignored.
    struct CysAccelRow
    {
        unsigned short key1;
        unsigned char mod1;
        unsigned short key2;
        unsigned char mod2;
        unsigned char ours;
    };
#include "../../LuaApiGen/CysHost_Accel_Table.inc"

    inline unsigned DefaultKey1(int row) { return Pack(kCysAccelRows[row].key1, kCysAccelRows[row].mod1); }
    inline unsigned DefaultKey2(int row) { return Pack(kCysAccelRows[row].key2, kCysAccelRows[row].mod2); }

    // DirectInput scan code (KC_*, TDInputSystem.h) -> Windows virtual key, US layout. 0 = no VK (not dispatched).
    inline unsigned DikToVk(int dik)
    {
        static unsigned char table[256];
        static bool ready = false;
        if (!ready)
        {
            std::memset(table, 0, sizeof(table));
            table[0x01] = 0x1B; table[0x0E] = 0x08; table[0x0F] = 0x09; table[0x1C] = 0x0D; table[0x39] = 0x20;
            table[0x38] = 0x12; table[0xB8] = 0x12; table[0x2A] = 0x10; table[0x36] = 0x10; table[0x1D] = 0x11; table[0x9D] = 0x11;
            table[0x02] = '1'; table[0x03] = '2'; table[0x04] = '3'; table[0x05] = '4'; table[0x06] = '5';
            table[0x07] = '6'; table[0x08] = '7'; table[0x09] = '8'; table[0x0A] = '9'; table[0x0B] = '0';
            table[0x1E] = 'A'; table[0x30] = 'B'; table[0x2E] = 'C'; table[0x20] = 'D'; table[0x12] = 'E';
            table[0x21] = 'F'; table[0x22] = 'G'; table[0x23] = 'H'; table[0x17] = 'I'; table[0x24] = 'J';
            table[0x25] = 'K'; table[0x26] = 'L'; table[0x32] = 'M'; table[0x31] = 'N'; table[0x18] = 'O';
            table[0x19] = 'P'; table[0x10] = 'Q'; table[0x13] = 'R'; table[0x1F] = 'S'; table[0x14] = 'T';
            table[0x16] = 'U'; table[0x2F] = 'V'; table[0x11] = 'W'; table[0x2D] = 'X'; table[0x15] = 'Y'; table[0x2C] = 'Z';
            table[0x3B] = 0x70; table[0x3C] = 0x71; table[0x3D] = 0x72; table[0x3E] = 0x73; table[0x3F] = 0x74;
            table[0x40] = 0x75; table[0x41] = 0x76; table[0x42] = 0x77; table[0x43] = 0x78; table[0x44] = 0x79;
            table[0x57] = 0x7A; table[0x58] = 0x7B;
            table[0x29] = 0xC0; table[0x0C] = 0xBD; table[0x0D] = 0xBB; table[0x1A] = 0xDB; table[0x1B] = 0xDD;
            table[0x2B] = 0xDC; table[0x27] = 0xBA; table[0x28] = 0xDE; table[0x33] = 0xBC; table[0x34] = 0xBE; table[0x35] = 0xBF;
            table[0xC8] = 0x26; table[0xD0] = 0x28; table[0xCB] = 0x25; table[0xCD] = 0x27;
            table[0xC7] = 0x24; table[0xCF] = 0x23; table[0xC9] = 0x21; table[0xD1] = 0x22; table[0xD2] = 0x2D; table[0xD3] = 0x2E;
            table[0x3A] = 0x14; table[0x45] = 0x90; table[0x46] = 0x91; table[0xB7] = 0x2C; table[0xC5] = 0x13;
            table[0x52] = 0x60; table[0x4F] = 0x61; table[0x50] = 0x62; table[0x51] = 0x63; table[0x4B] = 0x64;
            table[0x4C] = 0x65; table[0x4D] = 0x66; table[0x47] = 0x67; table[0x48] = 0x68; table[0x49] = 0x69;
            table[0x37] = 0x6A; table[0x4E] = 0x6B; table[0x4A] = 0x6D; table[0x53] = 0x6E; table[0xB5] = 0x6F; table[0x9C] = 0x0D;
            table[0xDB] = 0x5B; table[0xDC] = 0x5C; table[0xDD] = 0x5D;
            ready = true;
        }
        return (dik >= 0 && dik < 256) ? table[dik] : 0u;
    }

    // CY's "text keys": while an IME edit box is active a key from this set without Ctrl/Alt belongs to the box.
    // 0x1404352a0: A..Z, 0..9, numpad 0..9 and its operators, then Left Right Home End Delete Enter ; = , - . / ` [ \ ] ' 0xDF.
    inline bool IsTextKey(unsigned vk)
    {
        if ((vk >= 'A' && vk <= 'Z') || (vk >= '0' && vk <= '9') || (vk >= 0x60 && vk <= 0x6F)) return true;
        switch (vk)
        {
        case 0x25: case 0x27: case 0x24: case 0x23: case 0x2E: case 0x0D:
        case 0xBA: case 0xBB: case 0xBC: case 0xBD: case 0xBE: case 0xBF: case 0xC0:
        case 0xDB: case 0xDC: case 0xDD: case 0xDE: case 0xDF:
            return true;
        default:
            return false;
        }
    }

    inline bool IsPunctuationVk(unsigned vk)
    {
        return vk == 0xBD || vk == 0xBB || vk == 0xDB || vk == 0xDD || vk == 0xBA || vk == 0xDE || vk == 0xDC ||
               vk == 0xBC || vk == 0xBE || vk == 0xBF;
    }

    // Keys the capture accepts for binding 2 (the one used while chatting) - 0x1404357e0, list at manager +0x20.
    inline bool IsValidChatBinding(unsigned packed)
    {
        const unsigned vk = Vk(packed), mod = Mod(packed);
        if (vk >= 'A' && vk <= 'Z') return mod == kModAlt;
        if (vk >= '0' && vk <= '9') return mod == kModAlt || mod == kModCtrl;
        if (vk >= 0x70 && vk <= 0x7B) return mod == 0;
        if (vk == 0x2E) return mod == kModAlt;          // Alt+Delete
        if (vk == 0x09) return mod == kModCtrl;         // Ctrl+Tab
        if (IsPunctuationVk(vk)) return mod == kModAlt;
        return false;
    }

    // Keys the capture accepts for binding 1 (used while not chatting) - list at manager +0x15c. The WASD exclusion
    // of CY applies only while its keyboard-walk flag (0x1409b64ba) is on, which this build does not have.
    inline bool IsValidPlainBinding(unsigned packed)
    {
        const unsigned vk = Vk(packed), mod = Mod(packed);
        if (vk >= 'A' && vk <= 'Z') return mod == 0;
        if (vk >= '0' && vk <= '9') return mod == 0 || mod == kModCtrl;
        if (vk >= 0x70 && vk <= 0x7B) return mod == 0;
        if (vk == 0x2E || vk == 0x09) return mod == 0;   // Delete, Tab
        if (IsPunctuationVk(vk)) return mod == 0;
        return false;
    }

    // CY's own spelling of a key (0x140435eb0). Quirk kept on purpose: only ONE modifier prefix is written, chosen
    // Shift > Alt > Ctrl (the function jumps straight to the key name after the first prefix), so "Ctrl+Alt+," of the
    // fixed rows 4/5 reads "Alt+,". Returns false when the buffer is too small. "" for key 0.
    inline bool KeyText(unsigned packed, char* out, unsigned capacity, bool cyQuirk = true)
    {
        if (!out || capacity == 0) return false;
        out[0] = '\0';
        const unsigned vk = Vk(packed), mod = Mod(packed);
        if (vk == 0) return true;
        char body[24];
        switch (vk)
        {
        case 0x08: std::strcpy(body, "BackSpace"); break;
        case 0x09: std::strcpy(body, "Tab"); break;
        case 0x0D: std::strcpy(body, "Enter"); break;
        case 0x10: std::strcpy(body, "Shift"); break;
        case 0x11: std::strcpy(body, "Ctrl"); break;
        case 0x12: std::strcpy(body, "Alt"); break;
        case 0x13: std::strcpy(body, "Pause"); break;
        case 0x14: std::strcpy(body, "CapsLock"); break;
        case 0x1B: std::strcpy(body, "Esc"); break;
        case 0x20: std::strcpy(body, "Space"); break;
        case 0x21: std::strcpy(body, "PageUp"); break;
        case 0x22: std::strcpy(body, "PageDown"); break;
        case 0x23: std::strcpy(body, "End"); break;
        case 0x24: std::strcpy(body, "Home"); break;
        case 0x25: std::strcpy(body, "Left"); break;
        case 0x26: std::strcpy(body, "Up"); break;
        case 0x27: std::strcpy(body, "Right"); break;
        case 0x28: std::strcpy(body, "Down"); break;
        case 0x2C: std::strcpy(body, "PrintScreen"); break;
        case 0x2D: std::strcpy(body, "Insert"); break;
        case 0x2E: std::strcpy(body, "Delete"); break;
        case 0x90: std::strcpy(body, "NumLock"); break;
        case 0x91: std::strcpy(body, "ScrollLock"); break;
        case 0xBA: std::strcpy(body, ";"); break;
        case 0xBB: std::strcpy(body, "="); break;
        case 0xBC: std::strcpy(body, ","); break;
        case 0xBD: std::strcpy(body, "-"); break;
        case 0xBE: std::strcpy(body, "."); break;
        case 0xBF: std::strcpy(body, "/"); break;
        case 0xC0: std::strcpy(body, "`"); break;
        case 0xDB: std::strcpy(body, "["); break;
        case 0xDC: std::strcpy(body, "\\"); break;
        case 0xDD: std::strcpy(body, "]"); break;
        case 0xDE: std::strcpy(body, "'"); break;
        default:
            if (vk >= 0x70 && vk <= 0x7B) std::sprintf(body, "F%u", vk - 0x70 + 1);
            else if ((vk >= '0' && vk <= '9') || (vk >= 'A' && vk <= 'Z')) { body[0] = (char)vk; body[1] = '\0'; }
            else if (vk >= 0x60 && vk <= 0x69) std::sprintf(body, "Num%u", vk - 0x60);
            else std::sprintf(body, "0x%02X", vk);
            break;
        }
        char text[48];
        text[0] = '\0';
        if (cyQuirk)
        {
            if (mod & kModShift) std::strcat(text, "Shift+");
            else if (mod & kModAlt) std::strcat(text, "Alt+");
            else if (mod & kModCtrl) std::strcat(text, "Ctrl+");
        }
        else
        {
            if (mod & kModCtrl) std::strcat(text, "Ctrl+");
            if (mod & kModAlt) std::strcat(text, "Alt+");
            if (mod & kModShift) std::strcat(text, "Shift+");
        }
        std::strcat(text, body);
        if (std::strlen(text) + 1 > capacity) return false;
        std::strcpy(out, text);
        return true;
    }

    // The live bindings plus the two copies CY keeps (defaults at manager +0x11c8, the snapshot of
    // SaveCurAcceCustom for RevertAcceCustom).
    struct Table
    {
        unsigned key1[kRows];
        unsigned key2[kRows];
        unsigned snap1[kRows];
        unsigned snap2[kRows];
        bool changed;

        void Reset()
        {
            for (int i = 0; i < kRows; ++i) { key1[i] = DefaultKey1(i); key2[i] = DefaultKey2(i); }
            Snapshot();
            changed = false;
        }
        void Snapshot() { for (int i = 0; i < kRows; ++i) { snap1[i] = key1[i]; snap2[i] = key2[i]; } }
        void Revert() { for (int i = 0; i < kRows; ++i) { key1[i] = snap1[i]; key2[i] = snap2[i]; } }

        int RowOfId(int id) const
        {
            for (int i = 0; i < kRows; ++i) if (kRowMeta[i].id == id) return i;
            return -1;
        }

        // First row whose binding equals packed. slotOut: 1 or 2. -1 when none. A packed key of 0 never matches.
        int Find(unsigned packed, int* slotOut = 0) const
        {
            if (Vk(packed) == 0) return -1;
            for (int i = 0; i < kRows; ++i)
            {
                if (key1[i] == packed) { if (slotOut) *slotOut = 1; return i; }
                if (key2[i] == packed) { if (slotOut) *slotOut = 2; return i; }
            }
            return -1;
        }

        // CY 0x140435b80: bind `packed` to slot `slot` of row `row`; the same key on any other EDITABLE row is cleared
        // there. Returns the number of rows that lost the key (the window shows ZDYKJJ_20071227_03 when > 0).
        int Apply(int row, int slot, unsigned packed)
        {
            int replaced = 0;
            for (int i = kFixedRows; i < kRows; ++i)
            {
                if (i == row) continue;
                if (key1[i] == packed) { key1[i] = 0; ++replaced; }
                if (key2[i] == packed) { key2[i] = 0; ++replaced; }
            }
            if (slot == 2) key2[row] = packed; else key1[row] = packed;
            changed = true;
            return replaced;
        }

        // "..\Accounts\<account>\Acce_Custom.ini" body, CY's layout (0x140434880): one section per editable row.
        int Serialize(char* out, unsigned capacity) const
        {
            unsigned used = 0;
            if (!out || capacity == 0) return -1;
            out[0] = '\0';
            for (int i = kFixedRows; i < kRows; ++i)
            {
                char line[96];
                const int n = std::sprintf(line, "[ACCE_CUSTOM_%d]\r\nid=%d\r\nkey1=%u\r\nkey2=%u\r\n",
                                           kRowMeta[i].id, kRowMeta[i].id, key1[i], key2[i]);
                if (n <= 0 || used + (unsigned)n + 1 > capacity) return -1;
                std::memcpy(out + used, line, (size_t)n + 1);
                used += (unsigned)n;
            }
            return (int)used;
        }

        // Reads the format Serialize writes (and CY writes). Unknown ids are skipped; returns rows applied.
        int Parse(const char* text)
        {
            if (!text) return 0;
            int applied = 0, id = -1;
            unsigned k1 = 0, k2 = 0;
            bool have1 = false, have2 = false;
            const char* p = text;
            while (*p)
            {
                const char* eol = p;
                while (*eol && *eol != '\n' && *eol != '\r') ++eol;
                char line[128];
                unsigned len = (unsigned)(eol - p);
                if (len >= sizeof(line)) len = sizeof(line) - 1;
                std::memcpy(line, p, len); line[len] = '\0';
                if (line[0] == '[')
                {
                    if (id >= 0 && have1 && have2)
                    {
                        const int row = RowOfId(id);
                        if (row >= kFixedRows) { key1[row] = k1; key2[row] = k2; ++applied; }
                    }
                    id = -1; have1 = have2 = false;
                    std::sscanf(line, "[ACCE_CUSTOM_%d]", &id);
                }
                else if (std::strncmp(line, "key1=", 5) == 0) { k1 = (unsigned)std::strtoul(line + 5, 0, 10); have1 = true; }
                else if (std::strncmp(line, "key2=", 5) == 0) { k2 = (unsigned)std::strtoul(line + 5, 0, 10); have2 = true; }
                p = eol;
                while (*p == '\n' || *p == '\r') ++p;
            }
            if (id >= 0 && have1 && have2)
            {
                const int row = RowOfId(id);
                if (row >= kFixedRows) { key1[row] = k1; key2[row] = k2; ++applied; }
            }
            return applied;
        }
    };
}
