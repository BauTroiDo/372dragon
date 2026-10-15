#pragma once

// Borrowed UTF-8 name, valid until the GUI next changes its active window.
// CopyWindowText never truncates; success returns bytes excluding the NUL.
// Failure returns a negative value and clears out[0] when capacity permits.
namespace CysUiInputBridge
{
    // GUI-thread read-only snapshot: bound ID, empty flag, BackgroundImage
    // state presence, rendered bottom-right stack count (blank = 0).
    typedef int (__cdecl *ReadActionButtonUtf8)(const char* name, int out[4]);
    typedef const char* (__cdecl *GetActiveInputName)();
    // All queries run on the GUI thread. Rect is absolute pixels: left, top, width, height.
    typedef int (__cdecl *GetWindowRectUtf8)(const char* name, float out[4]);
    // Explicit smoke mode only; GUI thread, absolute pixels, action 0=move/1=left down/2=left up,
    // 3=right down/4=right up (CYS-UNEQUIP 20/09).
    typedef int (__cdecl *SmokePointer)(unsigned action, float x, float y);
    // CYS-GUIHARNESS 19/09: the CEGUI display area (width, height) in the SAME pixel space GetWindowRectUtf8
    // returns and SmokePointer injects into. That space is the render target, NOT the Win32 client rect: the two
    // differ whenever the window is resized away from the backbuffer (measured at 1920x1080 on 13/09, runs
    // Build/Logs/2026-09-13-perf/game/F-H-1080 and F-H2-1080). Bound smoke targets with THIS, never GetClientRect.
    typedef int (__cdecl *GetDisplaySize)(float out[2]);
    typedef int (__cdecl *CopyWindowTextUtf8)(const char* name, char* out, unsigned capacity);
    // Actual Window caption, including non-edit widgets. GUI-thread only.
    // No truncation: -1 missing/invalid, -2 insufficient capacity, -3 wrong thread;
    // errors clear out[0] when possible, success returns UTF-8 bytes excluding NUL.
    typedef int (__cdecl *CopyCaptionUtf8)(const char* name, char* out, unsigned capacity);
}
