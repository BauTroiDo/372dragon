#pragma once
#include "CEGUIIme.h"
#include "CEGUIWindow.h"
#include "CEGUIWindowManager.h"
#include "FalSimpleText.h"
#include "CEGUISystem.h"
#include <cstdio>
#include <cstring>
#include <limits>

namespace CysUiInputAccess
{
    inline const char* activeInputName()
    {
        CEGUI::Window* window = Ime::GetActiveIMEEditBox();
        return window ? window->getName().c_str() : "";
    }

    inline int getWindowRectUtf8(const char* name, float out[4])
    {
        if (out) out[0] = out[1] = out[2] = out[3] = 0;
        if (!name || !out) return 0;
        CEGUI::WindowManager* manager = CEGUI::WindowManager::getSingletonPtr();
        if (!manager || !manager->isWindowPresent(name)) return 0;
        CEGUI::Window* window = manager->getWindow(name);
        if (!window->isVisible()) return 0;
        const CEGUI::Rect rect = window->getPixelRect();
        out[0] = rect.d_left; out[1] = rect.d_top;
        out[2] = rect.getWidth(); out[3] = rect.getHeight();
        return 1;
    }

    // CYS-GUIHARNESS 19/09: the pixel space every rect above is expressed in, read live from the renderer, so a
    // caller can bound a target without assuming the Win32 client rect still matches the render target.
    inline int getDisplaySize(float out[2])
    {
        if (out) out[0] = out[1] = 0;
        if (!out) return 0;
        CEGUI::System* system = CEGUI::System::getSingletonPtr();
        CEGUI::Renderer* renderer = system ? system->getRenderer() : 0;
        if (!renderer) return 0;
        const float width = renderer->getWidth(), height = renderer->getHeight();
        if (!(width > 0.0f) || !(height > 0.0f)) return 0;
        out[0] = width; out[1] = height;
        return 1;
    }

    inline int copyWindowTextUtf8(const char* name, char* out, unsigned capacity)
    {
        if (out && capacity) out[0] = 0;
        if (!name || !out || !capacity) return -1;
        CEGUI::WindowManager* manager = CEGUI::WindowManager::getSingletonPtr();
        if (!manager || !manager->isWindowPresent(name)) return -1;
        CEGUI::Window* window = manager->getWindow(name);
        if (!window->testClassName("Editbox") && !window->testClassName("MultiLineEditbox")) return -1;
        const char* text = window->getText().c_str();
        const size_t bytes = std::strlen(text);
        if (bytes >= capacity || bytes > static_cast<size_t>((std::numeric_limits<int>::max)())) return -2;
        std::memcpy(out, text, bytes + 1);
        return static_cast<int>(bytes);
    }

    // Captions belong to any Window, including CheckButton and tooltip children.
    // Keep the edit-only query above unchanged; its callers depend on that contract.
    inline int copyCaptionUtf8(const char* name, char* out, unsigned capacity)
    {
        if (out && capacity) out[0] = 0;
        if (!name || !out || !capacity) return -1;
        CEGUI::WindowManager* manager = CEGUI::WindowManager::getSingletonPtr();
        if (!manager || !manager->isWindowPresent(name)) return -1;
        const char* text = manager->getWindow(name)->getText().c_str();
        const size_t bytes = std::strlen(text);
        if (bytes >= capacity || bytes > static_cast<size_t>((std::numeric_limits<int>::max)())) return -2;
        std::memcpy(out, text, bytes + 1);
        return static_cast<int>(bytes);
    }

    // CYS-CYGUI2: visible windows of the GUI sheet for the replay census (see UI_CEGUI.cpp). Names/types are ASCII
    // in CY layouts; the text is cut to 24 bytes and non-printable bytes become '?'.
    inline void appendWindowLine(CEGUI::Window* w, unsigned depth, char* out, unsigned capacity, unsigned& used)
    {
        const CEGUI::Rect r = w->getPixelRect();
        char text[25] = {};
        const char* t = w->getText().c_str();
        for (unsigned i = 0; i < 24 && t[i]; ++i)
            text[i] = (static_cast<unsigned char>(t[i]) >= 0x20 && static_cast<unsigned char>(t[i]) < 0x7f) ? t[i] : '?';
        char line[320];
        const int n = _snprintf(line, sizeof(line), "%u|%s|%s|%d,%d,%d,%d|%s;", depth, w->getName().c_str(),
            w->getType().c_str(), static_cast<int>(r.d_left), static_cast<int>(r.d_top),
            static_cast<int>(r.getWidth()), static_cast<int>(r.getHeight()), text);
        if (n <= 0 || used + static_cast<unsigned>(n) + 1 >= capacity) return;
        std::memcpy(out + used, line, static_cast<size_t>(n) + 1);
        used += static_cast<unsigned>(n);
    }

    inline void dumpChildren(CEGUI::Window* parent, unsigned depth, float screenW, char* out, unsigned capacity,
                             unsigned& used, int& count);

    inline int dumpVisibleWindowsUtf8(char* out, unsigned capacity)
    {
        if (out && capacity) out[0] = 0;
        if (!out || capacity < 2) return -1;
        CEGUI::System* system = CEGUI::System::getSingletonPtr();
        CEGUI::Window* root = system ? system->getGUISheet() : 0;
        if (!root) return 0;
        const float screenW = root->getPixelRect().getWidth();
        unsigned used = 0;
        int count = 0;
        dumpChildren(root, 0, screenW, out, capacity, used, count);
        return count;
    }

    // Visible children; descend (up to depth 3) into containers at least half the screen wide, so the frames of a
    // full-screen layout root (LogOn_Frame, MainMenuBar...) are listed but a list's 200 items are not.
    inline void dumpChildren(CEGUI::Window* parent, unsigned depth, float screenW, char* out, unsigned capacity,
                             unsigned& used, int& count)
    {
        for (size_t i = 0; i < parent->getChildCount(); ++i)
        {
            CEGUI::Window* w = parent->getChildAtIdx(i);
            if (!w->isVisible()) continue;
            ++count;
            appendWindowLine(w, depth, out, capacity, used);
            if (depth < 3 && w->getPixelRect().getWidth() >= screenW * 0.5f)
                dumpChildren(w, depth + 1, screenW, out, capacity, used, count);
        }
    }

    // Static labels have their own accessor; the input accessor remains edit-only.
    inline int copySimpleTextUtf8(const char* name, char* out, unsigned capacity)
    {
        if (out && capacity) out[0] = 0;
        if (!name || !out || !capacity) return -1;
        CEGUI::WindowManager* manager = CEGUI::WindowManager::getSingletonPtr();
        if (!manager || !manager->isWindowPresent(name)) return -1;
        CEGUI::FalagardSimpleText* window = dynamic_cast<CEGUI::FalagardSimpleText*>(manager->getWindow(name));
        if (!window) return -1;
        const char* text = window->getText().c_str();
        const size_t bytes = std::strlen(text);
        if (bytes >= capacity || bytes > static_cast<size_t>((std::numeric_limits<int>::max)())) return -2;
        std::memcpy(out, text, bytes + 1);
        return static_cast<int>(bytes);
    }
}
