#pragma once
















#include "Type.h"

namespace CysAccel
{
    // Idempotent. Loads the defaults (CysHost_Accel_Table.inc) and, once an account is known, its custom file.
    void Init();
    void SetAccount(const char* account);

    // One DirectInput key event (KC_* scan code). Returns true when the table consumed it (a row fired, the key was
    // captured for a rebinding, or a dead character was refused); false when the key is nobody's (or belongs to the
    // active edit box).
    bool ProcessKey(int kc, bool down);

    // The chat input is taking keys. MEASURED: the CEGUI focus list and the window's visibility BOTH say "yes"
    // permanently in the CY GUI (DefaultEditBox=True, the input line is always shown), so the real answer is CY's
    // own variable "NonChatActive" - see SetChatting.
    bool ChatEditActive();



    void SetChatting(bool chatting);
    bool AnyEditActive();
    // Name of the active edit box ("" when none) - the UI bridge value, for logs and tests.
    const char* ActiveEditName();
    // UTF-8 text of a named edit box (evidence: "the letter did not land in the chat box"). Returns false when unknown.
    bool CopyEditText(const char* window, char* out, unsigned capacity);

    // ---- AcceSetup window (row index = position in the table, id = the +0x00 field the window passes around) ----
    // SystemSetup:GetInputSetup(i): CY's own spelling of both bindings of row i ("" when unbound / out of range).
    bool RowText(int rowIndex, char* key1, unsigned cap1, char* key2, unsigned cap2);
    // SystemSetup:InputSetup_OnOff(true, chatSlot, id): the next key press rebinds row `id` (Esc cancels).
    void BeginCapture(int id, bool chatSlot);
    void EndCapture();
    bool IsCapturing();
    // SystemSetup:ComeBackAcce - the CY defaults back into the live table (the window redraws itself afterwards).
    void RestoreDefaults();
    // SystemSetup:SaveCurAcceCustom / RevertAcceCustom - the snapshot taken when the window opens, and its restore.
    void Snapshot();
    void Revert();
    // SystemSetup:UseAcceCustomKey - write the live table to the account's Acce_Custom.ini. False = could not write.
    bool Commit();
    // SystemSetup:GetIsConfigChanged / SetIsConfigChanged(n).
    bool IsChanged();
    void SetChanged(bool changed);

    // Page of the F1..F10 bar (Lua MAINMENUBAR_PAGENUM 0..2); slot = 10*page + (F-index).
    void SetMenuBarPage(int page);
    int MenuBarPage();

    struct Counters
    {
        unsigned keysSeen;        // key events handed to ProcessKey
        unsigned swallowedByEdit; // left to the active edit box (text key, no Ctrl/Alt)
        unsigned unbound;         // no row has that packed key
        unsigned dispatched;      // a row fired (down or up)
        unsigned refusedDead;     // dead character, row without the dead flag
        unsigned captured;        // key presses consumed by a rebinding capture
        unsigned notPorted;       // rows whose CY action this build cannot perform (logged, nothing done)
    };
    Counters Get();
}
