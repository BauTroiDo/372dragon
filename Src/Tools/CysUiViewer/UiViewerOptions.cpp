// CysUiViewer - command line options, defaults and helpers. CYS: new tool (2026-09-12).
#include "UiViewerOptions.h"

#include <windows.h>
#include <cstdio>
#include <cstdlib>
#include <cwchar>
#include <ctime>

namespace cysui
{
    namespace
    {
        const char* const kDefaultUi   = "C:\\TLBB\\085\\client_GL\\Data\\InterfaceFolder";
        const char* const kDefaultData = "C:\\TLBB\\085\\client_GL\\Data";
        const char* const kDefaultBase = "C:\\TLBB\\085\\client_GL\\Bin64\\CEGUI.log";
        const char* const kScheme      = "Schema\\WoWLookSkin.scheme.xml";

        bool parseSize(const std::wstring& v, int& w, int& h)
        {
            return swscanf(v.c_str(), L"%dx%d", &w, &h) == 2 && w >= 64 && h >= 64 && w <= 8192 && h <= 8192;
        }

        bool parseBg(const std::wstring& v, int* rgb)
        {
            int r, g, b;
            if (swscanf(v.c_str(), L"%d,%d,%d", &r, &g, &b) != 3)
                return false;
            rgb[0] = r < 0 ? 0 : (r > 255 ? 255 : r);
            rgb[1] = g < 0 ? 0 : (g > 255 ? 255 : g);
            rgb[2] = b < 0 ? 0 : (b > 255 ? 255 : b);
            return true;
        }

        std::string trimSlash(std::string s)
        {
            while (s.size() > 3 && (s[s.size() - 1] == '\\' || s[s.size() - 1] == '/'))
                s.erase(s.size() - 1);
            return s;
        }
    }

    void printUsage(void)
    {
        std::printf(
            "CysUiViewer - renders TLBB CEGUI layouts on the CY-Source engine (OGRE D3D9 + CEGUI 0.4.1)\n"
            "\n"
            "  CysUiViewer [--ui DIR]... [--layout FILE|NAME]... | --all | --list FILE  [options]\n"
            "\n"
            "resources\n"
            "  --ui DIR            InterfaceFolder root (repeatable, first wins; default client_GL)\n"
            "  --data DIR          folder with MaterialFolder..Material8Folder (default: sibling of the first\n"
            "                      --ui root if it has MaterialFolder, else client_GL\\Data)\n"
            "  --tex DIR           extra texture folder searched first (repeatable)\n"
            "  --scheme FILE       default Schema\\WoWLookSkin.scheme.xml\n"
            "  --scheme-mode M     robust (default: every scheme element loaded and checked on its own) or\n"
            "                      game (SchemeManager::loadScheme exactly like UI_CEGUI.dll)\n"
            "  --strict-fonts      do not adapt <Fonts>/CodePage font files the 0.85 font handler rejects\n"
            "  --no-wic            no WIC fallback codec for jpg/png (engine codecs only)\n"
            "  --force-wic         use WIC for jpg/png even when an engine codec exists\n"
            "  --dict FILE         StrDictionary.txt for #{KEY} texts (default <data>\\ConfigFolder)\n"
            "  --no-dict           show the raw #{KEY} texts\n"
            "  --interface FILE    InterfaceEx.txt (layout -> window name, for reports and NAME lookup)\n"
            "selection\n"
            "  --layout X          layout file relative to the UI root, absolute path, folder or window name\n"
            "  --all               every *.layout.xml under the UI roots (one PNG each)\n"
            "  --list FILE         one layout per line ('#' comments)\n"
            "  --filter TEXT       keep layouts whose path contains TEXT\n"
            "  --start N --count N slice of the selection\n"
            "  --composite         all selected layouts in one frame (one PNG)\n"
            "look\n"
            "  --size WxH          back buffer size (default 1920x1080; e.g. 1024x768)\n"
            "  --bg R,G,B          background colour (default 40,44,52)\n"
            "  --frames N          frames rendered before the captured one (default 3)\n"
            "  --show-hidden       force every child window visible\n"
            "  --sample-text[=all] replace texts by a Vietnamese sample (=all: also empty text windows)\n"
            "  --sample-string S   custom sample text (UTF-8)\n"
            "  --raw-text          keep texts as written in the layout\n"
            "  --codepage N        UI text code page: 65001 (default; UTF-8 end to end = UI_CEGUI with\n"
            "                      System_CodePage=65001) or e.g. 936 to reproduce the lossy 0.85 round trip\n"
            "output\n"
            "  --shot PNG|DIR      screenshot file (single layout) or folder\n"
            "  --no-shots          census only, no PNG\n"
            "  --out DIR           reports and logs (default CY-Source\\Build\\Logs\\<date>-uiviewer\\<run>)\n"
            "  --baseline FILE     CEGUI.log to compare errors with (default client_GL\\Bin64\\CEGUI.log; 'none')\n"
            "  --log-level L       CEGUI log level: errors|standard|informative|insane (default standard)\n"
            "  --show              visible window;  --interactive: live window (mouse, F5 reload, F12 shot, Esc)\n"
            "batch\n"
            "  --no-supervise      run a batch in this process (default: worker processes, restarted after a\n"
            "                      crash or hang)\n"
            "  --timeout N         seconds without progress before a worker is killed (default 90)\n"
            "  --free-every N      free unused imageset textures every N layouts (default 20)\n"
            "\n"
            "Exit codes: 0 ok, 1 usage, 2 layout failed to load, 3 engine init, 4 capture, 5 crash.\n");
    }

    int parseOptions(int argc, wchar_t** argv, Options& o, bool& helpOnly)
    {
        helpOnly = false;
        for (int i = 1; i < argc; ++i)
        {
            std::wstring a = argv[i];
            const bool hasNext = i + 1 < argc;
            std::wstring v = hasNext ? argv[i + 1] : L"";
            if (a == L"--help" || a == L"-h" || a == L"/?")
            {
                printUsage();
                helpOnly = true;
                return EXIT_OK;
            }
            else if (a == L"--ui" && hasNext) { o.uiRoots.push_back(wideToAcp(v)); ++i; }
            else if (a == L"--data" && hasNext) { o.dataDir = wideToAcp(v); ++i; }
            else if (a == L"--tex" && hasNext) { o.texDirs.push_back(wideToAcp(v)); ++i; }
            else if (a == L"--scheme" && hasNext) { o.scheme = wideToAcp(v); ++i; }
            else if (a == L"--scheme-mode" && hasNext)
            {
                if (v == L"game") o.gameScheme = true;
                else if (v == L"robust") o.gameScheme = false;
                else { std::printf("--scheme-mode: game or robust\n"); return EXIT_USAGE; }
                ++i;
            }
            else if (a == L"--strict-fonts") o.strictFonts = true;
            else if (a == L"--no-wic") o.wic = false;
            else if (a == L"--force-wic") o.forceWic = true;
            else if (a == L"--dict" && hasNext) { o.dictFile = wideToAcp(v); ++i; }
            else if (a == L"--no-dict") o.noDict = true;
            else if (a == L"--interface" && hasNext) { o.interfaceTable = wideToAcp(v); ++i; }
            else if (a == L"--layout" && hasNext) { o.layouts.push_back(wideToAcp(v)); ++i; }
            else if (a == L"--all") o.all = true;
            else if (a == L"--list" && hasNext) { o.listFile = wideToAcp(v); ++i; }
            else if (a == L"--filter" && hasNext) { o.filter = wideToAcp(v); ++i; }
            else if (a == L"--start" && hasNext) { o.start = _wtoi(v.c_str()); ++i; }
            else if (a == L"--count" && hasNext) { o.count = _wtoi(v.c_str()); ++i; }
            else if (a == L"--composite") o.composite = true;
            else if (a == L"--size" && hasNext)
            {
                if (!parseSize(v, o.width, o.height)) { std::printf("--size: WxH, e.g. 1920x1080\n"); return EXIT_USAGE; }
                ++i;
            }
            else if (a == L"--bg" && hasNext)
            {
                if (!parseBg(v, o.bg)) { std::printf("--bg: R,G,B\n"); return EXIT_USAGE; }
                ++i;
            }
            else if (a == L"--frames" && hasNext) { o.frames = _wtoi(v.c_str()); if (o.frames < 1) o.frames = 1; ++i; }
            else if (a == L"--show-hidden") o.showHidden = true;
            else if (a == L"--sample-text") o.sampleText = true;
            else if (a == L"--sample-text=all") { o.sampleText = true; o.sampleAll = true; }
            else if (a == L"--sample-string" && hasNext) { o.sampleUtf8 = wideToUtf8(v); o.sampleText = true; ++i; }
            else if (a == L"--raw-text") o.rawText = true;
            else if (a == L"--codepage" && hasNext) { o.codePage = _wtoi(v.c_str()); if (o.codePage <= 0) o.codePage = 65001; ++i; }
            else if (a == L"--shot" && hasNext) { o.shot = wideToAcp(v); ++i; }
            else if (a == L"--no-shots") o.noShots = true;
            else if (a == L"--out" && hasNext) { o.outDir = wideToAcp(v); ++i; }
            else if (a == L"--baseline" && hasNext) { o.baseline = wideToAcp(v); ++i; }
            else if (a == L"--log-level" && hasNext) { o.logLevel = wideToAcp(v); ++i; }
            else if (a == L"--show") o.show = true;
            else if (a == L"--interactive") { o.interactive = true; o.show = true; }
            else if (a == L"--no-supervise") o.supervise = false;
            else if (a == L"--timeout" && hasNext) { o.timeoutSec = _wtoi(v.c_str()); if (o.timeoutSec < 10) o.timeoutSec = 10; ++i; }
            else if (a == L"--free-every" && hasNext) { o.freeEvery = _wtoi(v.c_str()); ++i; }
            else if (a == L"--worker") o.worker = true;
            else if (a == L"--worker-list" && hasNext) { o.workerList = wideToAcp(v); ++i; }
            else if (a == L"--worker-start" && hasNext) { o.workerStart = _wtoi(v.c_str()); ++i; }
            else if (a == L"--worker-run" && hasNext) { o.workerRun = _wtoi(v.c_str()); ++i; }
            else
            {
                std::printf("unknown or incomplete option: %s\n\n", wideToUtf8(a).c_str());
                printUsage();
                return EXIT_USAGE;
            }
        }
        if (!o.worker && !o.all && o.layouts.empty() && o.listFile.empty())
        {
            std::printf("nothing to render: give --layout, --list or --all\n\n");
            printUsage();
            return EXIT_USAGE;
        }
        return EXIT_OK;
    }

    void resolveDefaults(Options& o, const std::string& runName)
    {
        if (o.scheme.empty())
            o.scheme = kScheme;
        if (o.uiRoots.empty())
            o.uiRoots.push_back(kDefaultUi);
        for (size_t i = 0; i < o.uiRoots.size(); ++i)
            o.uiRoots[i] = trimSlash(fullPath(o.uiRoots[i]));
        // A partial overlay root (e.g. a skin folder with only the changed files) falls back to client_GL.
        if (!fileExists(joinPath(o.uiRoots[0], o.scheme)))
        {
            bool haveDefault = false;
            for (size_t i = 0; i < o.uiRoots.size(); ++i)
                haveDefault = haveDefault || lowerAscii(o.uiRoots[i]) == lowerAscii(kDefaultUi);
            if (!haveDefault)
                o.uiRoots.push_back(kDefaultUi);
        }
        if (o.dataDir.empty())
        {
            std::string sib = parentDir(o.uiRoots[0]);
            o.dataDir = dirExists(joinPath(sib, "MaterialFolder")) ? sib : std::string(kDefaultData);
        }
        o.dataDir = trimSlash(fullPath(o.dataDir));
        for (size_t i = 0; i < o.texDirs.size(); ++i)
            o.texDirs[i] = trimSlash(fullPath(o.texDirs[i]));

        const std::string cfg = joinPath(o.dataDir, "ConfigFolder");
        const std::string defCfg = joinPath(kDefaultData, "ConfigFolder");
        if (o.dictFile.empty() && !o.noDict)
        {
            o.dictFile = joinPath(cfg, "StrDictionary.txt");
            if (!fileExists(o.dictFile))
                o.dictFile = joinPath(defCfg, "StrDictionary.txt");
        }
        if (o.noDict)
            o.dictFile.clear();
        if (o.interfaceTable.empty())
        {
            o.interfaceTable = joinPath(cfg, "InterfaceEx.txt");
            if (!fileExists(o.interfaceTable))
                o.interfaceTable = joinPath(defCfg, "InterfaceEx.txt");
        }
        if (o.baseline.empty())
            o.baseline = fileExists(kDefaultBase) ? std::string(kDefaultBase) : std::string();
        else if (lowerAscii(o.baseline) == "none")
            o.baseline.clear();

        if (o.outDir.empty())
        {
            std::string exe = exeDirectory();
            std::string low = lowerAscii(exe);
            size_t p = low.find("\\build\\cmake\\");
            std::string base = p != std::string::npos
                ? exe.substr(0, p) + "\\Build\\Logs\\" + todayIso() + "-uiviewer"
                : joinPath(exe, "uiviewer-out");
            o.outDir = joinPath(base, runName);
        }
        o.outDir = trimSlash(fullPath(o.outDir));
    }

    // ------------------------------------------------------------------ helpers
    std::string wideToAcp(const std::wstring& w)
    {
        if (w.empty())
            return std::string();
        int n = WideCharToMultiByte(CP_ACP, 0, w.data(), (int)w.size(), NULL, 0, NULL, NULL);
        std::string s(n, '\0');
        WideCharToMultiByte(CP_ACP, 0, w.data(), (int)w.size(), &s[0], n, NULL, NULL);
        return s;
    }

    std::string wideToUtf8(const std::wstring& w)
    {
        if (w.empty())
            return std::string();
        int n = WideCharToMultiByte(CP_UTF8, 0, w.data(), (int)w.size(), NULL, 0, NULL, NULL);
        std::string s(n, '\0');
        WideCharToMultiByte(CP_UTF8, 0, w.data(), (int)w.size(), &s[0], n, NULL, NULL);
        return s;
    }

    std::wstring utf8ToWide(const std::string& s)
    {
        if (s.empty())
            return std::wstring();
        int n = MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(), NULL, 0);
        std::wstring w(n, L'\0');
        MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(), &w[0], n);
        return w;
    }

    std::string acpToUtf8(const std::string& s)
    {
        if (s.empty())
            return s;
        int n = MultiByteToWideChar(CP_ACP, 0, s.data(), (int)s.size(), NULL, 0);
        std::wstring w(n, L'\0');
        MultiByteToWideChar(CP_ACP, 0, s.data(), (int)s.size(), &w[0], n);
        return wideToUtf8(w);
    }

    std::string exePath(void)
    {
        char buf[MAX_PATH * 2];
        DWORD n = GetModuleFileNameA(NULL, buf, (DWORD)sizeof(buf));
        return std::string(buf, n);
    }

    std::string exeDirectory(void)
    {
        return parentDir(exePath());
    }

    bool fileExists(const std::string& path)
    {
        DWORD a = GetFileAttributesA(path.c_str());
        return a != INVALID_FILE_ATTRIBUTES && !(a & FILE_ATTRIBUTE_DIRECTORY);
    }

    bool dirExists(const std::string& path)
    {
        DWORD a = GetFileAttributesA(path.c_str());
        return a != INVALID_FILE_ATTRIBUTES && (a & FILE_ATTRIBUTE_DIRECTORY);
    }

    void makeDirs(const std::string& path)
    {
        if (path.empty() || dirExists(path))
            return;
        std::string parent = parentDir(path);
        if (!parent.empty() && parent != path)
            makeDirs(parent);
        CreateDirectoryA(path.c_str(), NULL);
    }

    std::string joinPath(const std::string& a, const std::string& b)
    {
        if (a.empty())
            return b;
        if (b.empty())
            return a;
        char last = a[a.size() - 1];
        if (last == '\\' || last == '/')
            return a + b;
        return a + "\\" + b;
    }

    std::string parentDir(const std::string& path)
    {
        size_t p = path.find_last_of("\\/");
        if (p == std::string::npos)
            return std::string();
        if (p == 2 && path.size() > 1 && path[1] == ':')
            return path.substr(0, 3);
        return path.substr(0, p);
    }

    std::string fileNameOf(const std::string& path)
    {
        size_t p = path.find_last_of("\\/");
        return p == std::string::npos ? path : path.substr(p + 1);
    }

    std::string fullPath(const std::string& path)
    {
        char buf[MAX_PATH * 4];
        DWORD n = GetFullPathNameA(path.c_str(), (DWORD)sizeof(buf), buf, NULL);
        if (n == 0 || n >= sizeof(buf))
            return path;
        return std::string(buf, n);
    }

    std::string lowerAscii(std::string s)
    {
        for (size_t i = 0; i < s.size(); ++i)
            if (s[i] >= 'A' && s[i] <= 'Z')
                s[i] = (char)(s[i] - 'A' + 'a');
        return s;
    }

    std::string slashes(std::string s, char to)
    {
        for (size_t i = 0; i < s.size(); ++i)
            if (s[i] == '\\' || s[i] == '/')
                s[i] = to;
        return s;
    }

    bool startsWithNoCase(const std::string& s, const std::string& prefix)
    {
        return s.size() >= prefix.size() && lowerAscii(s.substr(0, prefix.size())) == lowerAscii(prefix);
    }

    bool endsWithNoCase(const std::string& s, const std::string& suffix)
    {
        return s.size() >= suffix.size() && lowerAscii(s.substr(s.size() - suffix.size())) == lowerAscii(suffix);
    }

    std::string todayIso(void)
    {
        SYSTEMTIME st;
        GetLocalTime(&st);
        char buf[32];
        std::sprintf(buf, "%04d-%02d-%02d", st.wYear, st.wMonth, st.wDay);
        return buf;
    }

    std::string nowStamp(void)
    {
        SYSTEMTIME st;
        GetLocalTime(&st);
        char buf[48];
        std::sprintf(buf, "%04d-%02d-%02d %02d:%02d:%02d", st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond);
        return buf;
    }

    double nowSeconds(void)
    {
        static LARGE_INTEGER f = {};
        if (!f.QuadPart)
            QueryPerformanceFrequency(&f);
        LARGE_INTEGER c;
        QueryPerformanceCounter(&c);
        return double(c.QuadPart) / double(f.QuadPart);
    }

    void pumpMessages(void)
    {
        MSG msg;
        while (PeekMessageW(&msg, NULL, 0U, 0U, PM_REMOVE))
        {
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
    }
}
