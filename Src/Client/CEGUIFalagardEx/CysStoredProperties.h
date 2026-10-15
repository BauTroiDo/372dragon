#pragma once
// CYS-HUD: GL layout properties whose only effect is on game-side logic (or whose rendering is not implemented yet)
// are accepted and stored per window instead of raising "There is no Property named ..." (rule: a strange property is
// logged/kept, never thrown - Timeline bay 8.2). Each entry names the GL widget type it belongs to, the property, its
// default and the meaning recovered from client_GL (strings of CEGUIFalagard.dll / layouts) - see
// Docs/specs/ui/hud-widgets_vi.md. Values are readable back through Window::getProperty for the game layer.
#include "FalModule.h"
#include "CEGUIProperty.h"

namespace CEGUI
{
    class Window;

    // Registers every stored property on its factory (idempotent). Called by the Falagard module after the
    // factories exist (registerAllFactories / registerFactory).
    FALAGARDBASE_API void cysRegisterStoredProperties();

    // Value of a stored property for a window ("" when never set). Also usable for the semantic getters.
    FALAGARDBASE_API String cysStoredProperty(const Window* window, const String& name);
    FALAGARDBASE_API bool cysHasStoredProperty(const Window* window, const String& name);
}
