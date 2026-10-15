// CysUiViewer - command line options, paths and small text helpers.
// CYS: new tool (2026-09-12). Keep this file ASCII (the tree compiles with /execution-charset:.936).
#pragma once

#include <string>
#include <vector>

namespace cysui
{
    enum ExitCode
    {
        EXIT_OK       = 0,
        EXIT_USAGE    = 1,
        EXIT_LOADFAIL = 2,   // single layout: the layout failed to load
        EXIT_ENGINE   = 3,   // OGRE / CEGUI initialisation failed
        EXIT_CAPTURE  = 4,   // screenshot could not be written
        EXIT_CRASH    = 5,   // unhandled SEH exception
    };

    struct Options
    {
        // ---- resources (paths are ACP bytes; every default path is ASCII)
        std::vector<std::string> uiRoots;   // --ui DIR (repeatable, priority order)
        std::string dataDir;                // --data DIR: holds MaterialFolder..Material8Folder (UI textures)
        std::vector<std::string> texDirs;   // --tex DIR (repeatable): searched before the --data folders
        std::string scheme;                 // --scheme FILE (relative to the UI root)
        bool gameScheme  = false;           // --scheme-mode game: SchemeManager::loadScheme exactly like UI_CEGUI
        bool strictFonts = false;           // --strict-fonts: no adaptation of <Fonts> files the 0.85 handler rejects
        bool wic         = true;            // --no-wic: no WIC fallback codec for jpg/png
        bool forceWic    = false;           // --force-wic: WIC even when an engine codec exists
        std::string dictFile;               // --dict FILE (StrDictionary.txt)
        bool noDict      = false;           // --no-dict
        std::string interfaceTable;         // --interface FILE (InterfaceEx.txt: layout -> window name)

        // ---- what to render
        std::vector<std::string> layouts;   // --layout FILE|NAME (repeatable)
        bool all         = false;           // --all
        std::string listFile;               // --list FILE
        std::string filter;                 // --filter TEXT
        int start        = 0;               // --start N
        int count        = -1;              // --count N
        bool composite   = false;           // --composite: all selected layouts in one frame

        // ---- look
        int width        = 1920;            // --size WxH
        int height       = 1080;
        int bg[3]        = { 40, 44, 52 };  // --bg R,G,B
        int frames       = 3;               // --frames N (frames before the captured one)
        bool showHidden  = false;           // --show-hidden
        bool sampleText  = false;           // --sample-text
        bool sampleAll   = false;           // --sample-text=all
        std::string sampleUtf8;             // --sample-string TEXT (UTF-8)
        bool rawText     = false;           // --raw-text: no #{KEY} / markup resolution
        int codePage     = 65001;           // --codepage N: UI text code page (65001 = UTF-8 end to end, like
                                            // UI_CEGUI with System_CodePage=65001; 936 = 0.85 lossy round trip)

        // ---- output
        std::string shot;                   // --shot PNG|DIR
        bool noShots     = false;           // --no-shots
        std::string outDir;                 // --out DIR (reports, logs)
        std::string baseline;               // --baseline CEGUI.log | none
        std::string logLevel = "standard";  // --log-level errors|standard|informative|insane
        bool show        = false;           // --show
        bool interactive = false;           // --interactive

        // ---- batch supervision
        bool supervise   = true;            // --no-supervise
        int timeoutSec   = 90;              // --timeout N (seconds without progress)
        int freeEvery    = 20;              // --free-every N (ImagesetManager::FreeUnuseImageset)

        // ---- internal (worker processes started by the supervisor)
        bool worker      = false;           // --worker
        std::string workerList;             // --worker-list FILE
        int workerStart  = 0;               // --worker-start N
        int workerRun    = 0;               // --worker-run K
    };

    // Parses argv (wide). Returns EXIT_OK to continue, otherwise the exit code. 'helpOnly' for --help.
    int parseOptions(int argc, wchar_t** argv, Options& opt, bool& helpOnly);
    // Fills the defaults that depend on the file system (roots, data dir, dictionary, out dir ...).
    void resolveDefaults(Options& opt, const std::string& runName);
    void printUsage(void);

    // ---- text / path helpers
    std::string wideToAcp(const std::wstring& w);
    std::string wideToUtf8(const std::wstring& w);
    std::wstring utf8ToWide(const std::string& s);
    std::string acpToUtf8(const std::string& s);
    std::string exeDirectory(void);
    std::string exePath(void);
    bool fileExists(const std::string& path);
    bool dirExists(const std::string& path);
    void makeDirs(const std::string& path);
    std::string joinPath(const std::string& a, const std::string& b);
    std::string parentDir(const std::string& path);
    std::string fileNameOf(const std::string& path);
    std::string fullPath(const std::string& path);
    std::string lowerAscii(std::string s);
    std::string slashes(std::string s, char to);   // '\\' and '/' -> 'to'
    bool startsWithNoCase(const std::string& s, const std::string& prefix);
    bool endsWithNoCase(const std::string& s, const std::string& suffix);
    std::string todayIso(void);
    std::string nowStamp(void);
    double nowSeconds(void);
    void pumpMessages(void);
}
