// CysUiViewer - engine + CEGUI host: OGRE D3D9 window, CEGUI 0.4.1 + OgreCEGUIRenderer, the game's scheme, layout
// rendering, back buffer capture. No game logic: layout <Event> handlers go to a null script module.
// CYS: new tool (2026-09-12). Keep this file ASCII.
#pragma once

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#include <map>
#include <set>
#include <string>
#include <vector>

#include "UiViewerOptions.h"
#include "UiViewerReport.h"
#include "UiViewerText.h"

namespace Ogre
{
    class Root;
    class LogManager;
    class RenderWindow;
    class SceneManager;
    class Camera;
    class Viewport;
}

namespace CEGUI
{
    class OgreCEGUIRenderer;
    class System;
    class Window;
    class ScriptModule;
}

namespace cysui
{
    class GuiRenderListener; // UiViewerApp.cpp
    class WicImageCodec;     // UiViewerApp.cpp

    struct WorkerPaths
    {
        std::string runDir;   // <out>\run_NNN: UISystem.log (CEGUI), Ogre.log, scheme_report.txt, textures.txt ...
        std::string records;  // <out>\records.tsv (appended)
        std::string progress; // <out>\progress.txt (index of the layout being processed)
        std::string shotDir;  // PNG folder for batches
        std::string shotFile; // exact PNG path (single layout / composite); empty = derive from shotDir
    };

    class App
    {
    public:
        explicit App(const Options& opt);
        ~App();

        bool init(HWND hwnd, const WorkerPaths& paths, bool writeSchemeReport, std::string& error);
        // Renders layouts[start..] one by one (or all together with --composite), one record per layout.
        // Returns EXIT_OK, or for a single layout EXIT_LOADFAIL / EXIT_CAPTURE.
        int runBatch(const std::vector<std::string>& layouts, int start);
        // Visible window: mouse input, F5 reloads the layouts, F12 saves a PNG, Esc quits.
        int runInteractive(const std::vector<std::string>& layouts);
        void shutdown(void);

        bool handleMessage(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp, LRESULT& result);

        static App* current(void) { return s_current; }
        int currentIndex(void) const { return m_currentIndex; }
        const std::string& currentLayout(void) const { return m_currentLayout; }
        const WorkerPaths& paths(void) const { return m_paths; }

        // GUI render listener (RENDER_QUEUE_OVERLAY): CEGUI::System::renderGUI with C++ and SEH guards.
        void renderGuiGuarded(void);
        // WindowManager::loadWindowLayout property callback: #{KEY} / markup resolution, sample text.
        bool onLayoutProperty(CEGUI::Window* window, CEGUI::String& name, CEGUI::String& value);

    private:
        // ---- UiViewerApp.cpp: initialisation, scheme
        bool initEngine(HWND hwnd, std::string& error);
        void addResourceLocations(void);
        void registerCodecs(void);
        bool initCegui(std::string& error);
        void loadSchemeGame(void);
        void loadSchemeRobust(void);
        bool adaptFont(const CEGUI::String& name, const CEGUI::String& file, const CEGUI::String& group,
                       std::string& note);
        void finishSchemeReport(void);
        void writeWorkerFiles(void);

        // ---- UiViewerRender.cpp: layouts, rendering, capture
        LayoutRecord processLayouts(int index, const std::vector<std::string>& files, const std::string& label);
        CEGUI::Window* loadLayout(const std::string& file, std::string& failure, bool& crashed);
        bool renderAndCapture(std::vector<unsigned char>& rgb, unsigned& w, unsigned& h, std::string& error,
                              bool& crashed);
        void createPendingPlaceholders(void);
        void destroyLayoutWindow(CEGUI::Window* w);
        std::string shotPathFor(const std::string& label) const;
        double coverageOf(const std::vector<unsigned char>& rgb) const;
        void writeProgress(int index);
        std::string windowNameFor(const std::string& file) const;

        void say(const std::string& utf8);
        void note(const std::string& utf8); // scheme report line (also printed)

        const Options& m_opt;
        WorkerPaths m_paths;
        bool m_writeSchemeReport;
        HWND m_hwnd;

        Ogre::LogManager* m_logManager;
        Ogre::Root* m_root;
        Ogre::RenderWindow* m_window;
        Ogre::SceneManager* m_scene;
        Ogre::Camera* m_camera;
        Ogre::Viewport* m_viewport;
        GuiRenderListener* m_listener;
        std::vector<WicImageCodec*> m_codecs;
        std::vector<std::string> m_locations;

        CEGUI::OgreCEGUIRenderer* m_renderer;
        CEGUI::ScriptModule* m_script;
        CEGUI::System* m_system;
        CEGUI::Window* m_sheet;
        std::string m_logPath;
        unsigned long long m_schemeLogEnd;

        TextResolver m_text;
        bool m_dictLoaded;
        CEGUI::String m_sample;
        std::map<std::string, std::string> m_windowNames;

        std::vector<std::string> m_pendingPlaceholders;
        std::set<std::string> m_placeholders;
        std::string m_renderError;
        unsigned long m_renderSeh;
        int m_currentIndex;
        std::string m_currentLayout;
        std::string m_schemeReport;
        bool m_shotRequested;
        bool m_reloadRequested;

        static App* s_current;
    };
}
