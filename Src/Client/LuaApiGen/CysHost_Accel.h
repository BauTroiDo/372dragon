#pragma once
// CYS-ACCEL: the key-remap window (AcceSetup) of CY 3.71.  It asks SystemSetup for the two bindings of every
// action - the plain key used while the chat box is not taking characters, and the Alt+<key> used while it is.
//
// Only SystemSetup:GetInputSetup is implemented here, and it is READ-ONLY.  See
// Docs/specs/client/host-plumbing_vi.md section "AcceSetup" for why the other three stay stubs.
#include "LuaPlus.h"

namespace CysHostAccel
{
    // Registers SystemSetup:GetInputSetup over the generated stub. Returns the number registered (0 or 1).
    int Register(LuaPlus::LuaState* state);

    // Test seam: CY's own spelling of one binding ("F1", "Alt+1", "Shift+Tab", "Delete", "A", ...).
    // Writes "" when the key is 0. Returns false only when the buffer is too small.
    bool KeyText(int vk, int mod, char* out, unsigned capacity);

    // Test seam: the two bindings of row `index` of CY's table, "" when the row is out of range, unbound,
    // or not dispatched by this build. Returns false when index is out of range.
    bool RowText(int index, char* key1, unsigned cap1, char* key2, unsigned cap2);

    // Number of rows this build really dispatches, out of the 79 in the table (telemetry / tests).
    int SupportedRowCount();
}
