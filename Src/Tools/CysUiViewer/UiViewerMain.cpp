// CysUiViewer - entry point: options, layout selection, window, crash handling, batch supervisor (worker processes
// restarted after a crash or hang), final reports. CYS: new tool (2026-09-12). Keep this file ASCII.
#include "UiViewerApp.h"

#include <dbghelp.h>
#include <objbase.h>

#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <exception>
#include <map>
#include <set>

using namespace cysui;

namespace
{
    Options g_opt;

    // ---- crash handling: record the layout being processed, write a small minidump, exit with EXIT_CRASH
    void recordCrash(const char* text, EXCEPTION_POINTERS* ep)
    {
        std::fprintf(stderr, "CysUiViewer: CRASH %s\n", text);
        App* app = App::current();
        if (app && app->currentIndex() >= 0)
        {
            std::fprintf(stderr, "CysUiViewer: while processing [%d] %s\n", app->currentIndex(), app->currentLayout().c_str());
            LayoutRecord r;
            r.index = app->currentIndex();
            r.status = "crash";
            r.file = app->currentLayout();
            r.failure = text;
            appendRecord(app->paths().records, r);
            if (ep)
            {
                char dump[MAX_PATH];
                std::sprintf(dump, "%s\\crash_%04d.dmp", app->paths().runDir.c_str(), app->currentIndex());
                HANDLE f = CreateFileA(dump, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
                if (f != INVALID_HANDLE_VALUE)
                {
                    MINIDUMP_EXCEPTION_INFORMATION info;
                    info.ThreadId = GetCurrentThreadId();
                    info.ExceptionPointers = ep;
                    info.ClientPointers = FALSE;
                    MiniDumpWriteDump(GetCurrentProcess(), GetCurrentProcessId(), f, MiniDumpNormal, &info, NULL, NULL);
                    CloseHandle(f);
                }
            }
        }
        std::fflush(stderr);
        std::fflush(stdout);
    }

    LONG WINAPI crashFilter(EXCEPTION_POINTERS* ep)
    {
        static volatile LONG entered = 0;
        if (InterlockedExchange(&entered, 1) != 0)
            TerminateProcess(GetCurrentProcess(), EXIT_CRASH);
        void* address = (ep && ep->ExceptionRecord) ? ep->ExceptionRecord->ExceptionAddress : NULL;
        DWORD code = (ep && ep->ExceptionRecord) ? ep->ExceptionRecord->ExceptionCode : 0;
        HMODULE module = NULL;
        char moduleName[MAX_PATH] = "?";
        if (address && GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                                          (LPCSTR)address, &module))
            GetModuleFileNameA(module, moduleName, MAX_PATH);
        const char* base = std::strrchr(moduleName, '\\');
        char text[512];
        std::sprintf(text, "SEH exception 0x%08lX at %s+0x%llX", code, base ? base + 1 : moduleName,
                     (unsigned long long)((const char*)address - (const char*)module));
        recordCrash(text, ep);
        TerminateProcess(GetCurrentProcess(), EXIT_CRASH);
        return EXCEPTION_EXECUTE_HANDLER;
    }

    void onTerminate(void)
    {
        recordCrash("unhandled C++ exception (std::terminate)", NULL);
        TerminateProcess(GetCurrentProcess(), EXIT_CRASH);
    }

    bool guardedShutdown(App* app)
    {
        __try
        {
            app->shutdown();
            return true;
        }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            return false;
        }
    }

    // ---- window
    LRESULT CALLBACK wndProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp)
    {
        App* app = App::current();
        if (app)
        {
            LRESULT r = 0;
            if (app->handleMessage(hwnd, msg, wp, lp, r))
                return r;
        }
        switch (msg)
        {
        case WM_GETMINMAXINFO:
            {
                // client areas larger than the desktop (1920x1080 + borders on a 1080p screen)
                MINMAXINFO* info = reinterpret_cast<MINMAXINFO*>(lp);
                info->ptMaxTrackSize.x = 16384;
                info->ptMaxTrackSize.y = 16384;
                return 0;
            }
        case WM_ERASEBKGND:
            return 1;
        case WM_CLOSE:
            PostQuitMessage(0);
            return 0;
        default:
            break;
        }
        return DefWindowProcW(hwnd, msg, wp, lp);
    }

    HWND createViewerWindow(const Options& opt)
    {
        WNDCLASSEXW wc;
        ZeroMemory(&wc, sizeof(wc));
        wc.cbSize = sizeof(wc);
        wc.style = CS_HREDRAW | CS_VREDRAW;
        wc.lpfnWndProc = wndProc;
        wc.hInstance = GetModuleHandleW(NULL);
        wc.hCursor = LoadCursor(NULL, IDC_ARROW);
        wc.hbrBackground = (HBRUSH)GetStockObject(BLACK_BRUSH);
        wc.lpszClassName = L"CysUiViewerWindow";
        RegisterClassExW(&wc);
        const DWORD style = opt.show ? WS_OVERLAPPEDWINDOW : WS_POPUP;
        RECT rc = { 0, 0, opt.width, opt.height };
        AdjustWindowRect(&rc, style, FALSE);
        HWND hwnd = CreateWindowExW(0, wc.lpszClassName, L"CysUiViewer", style, opt.show ? CW_USEDEFAULT : 0,
                                    opt.show ? CW_USEDEFAULT : 0, rc.right - rc.left, rc.bottom - rc.top, NULL, NULL,
                                    wc.hInstance, NULL);
        if (!hwnd)
            return NULL;
        // the D3D9 back buffer takes the client size of this window: make it exact
        RECT client;
        GetClientRect(hwnd, &client);
        if (client.right != opt.width || client.bottom != opt.height)
        {
            RECT outer;
            GetWindowRect(hwnd, &outer);
            SetWindowPos(hwnd, NULL, 0, 0, (outer.right - outer.left) + (opt.width - client.right),
                         (outer.bottom - outer.top) + (opt.height - client.bottom), SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
        }
        if (opt.show)
        {
            ShowWindow(hwnd, SW_SHOWNORMAL);
            UpdateWindow(hwnd);
        }
        return hwnd;
    }

    // ---- files
    std::string readText(const std::string& path)
    {
        std::string s;
        FILE* f = std::fopen(path.c_str(), "rb");
        if (!f)
            return s;
        char buf[4096];
        size_t n;
        while ((n = std::fread(buf, 1, sizeof(buf), f)) > 0)
            s.append(buf, n);
        std::fclose(f);
        return s;
    }

    std::vector<std::string> readLines(const std::string& path)
    {
        std::vector<std::string> out;
        std::string data = readText(path);
        size_t p = (data.size() >= 3 && (unsigned char)data[0] == 0xEF) ? 3 : 0;
        while (p < data.size())
        {
            size_t e = data.find('\n', p);
            if (e == std::string::npos)
                e = data.size();
            std::string l = data.substr(p, e - p);
            p = e + 1;
            size_t b = l.find_first_not_of(" \t\r");
            size_t z = l.find_last_not_of(" \t\r");
            if (b == std::string::npos || l[b] == '#')
                continue;
            out.push_back(l.substr(b, z - b + 1));
        }
        return out;
    }

    void removeTree(const std::string& dir)
    {
        WIN32_FIND_DATAA fd;
        HANDLE h = FindFirstFileA(joinPath(dir, "*").c_str(), &fd);
        if (h != INVALID_HANDLE_VALUE)
        {
            do
            {
                std::string n = fd.cFileName;
                if (n == "." || n == "..")
                    continue;
                std::string p = joinPath(dir, n);
                if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
                    removeTree(p);
                else
                {
                    SetFileAttributesA(p.c_str(), FILE_ATTRIBUTE_NORMAL);
                    DeleteFileA(p.c_str());
                }
            } while (FindNextFileA(h, &fd));
            FindClose(h);
        }
        RemoveDirectoryA(dir.c_str());
    }

    // Only the viewer's own outputs of an earlier run with the same --out (records, progress, run_* folders).
    void cleanOutDir(const std::string& out)
    {
        DeleteFileA(joinPath(out, "records.tsv").c_str());
        DeleteFileA(joinPath(out, "progress.txt").c_str());
        WIN32_FIND_DATAA fd;
        HANDLE h = FindFirstFileA(joinPath(out, "run_*").c_str(), &fd);
        if (h == INVALID_HANDLE_VALUE)
            return;
        do
        {
            if ((fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) && std::strncmp(fd.cFileName, "run_", 4) == 0)
                removeTree(joinPath(out, fd.cFileName));
        } while (FindNextFileA(h, &fd));
        FindClose(h);
    }

    // ---- selection
    void enumerateLayouts(const std::string& root, const std::string& rel, std::vector<std::string>& out)
    {
        WIN32_FIND_DATAA fd;
        HANDLE h = FindFirstFileA(joinPath(joinPath(root, slashes(rel, '\\')), "*").c_str(), &fd);
        if (h == INVALID_HANDLE_VALUE)
            return;
        do
        {
            std::string name = fd.cFileName;
            if (name == "." || name == "..")
                continue;
            std::string r = rel.empty() ? name : rel + "/" + name;
            if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
                enumerateLayouts(root, r, out);
            else if (endsWithNoCase(name, ".layout.xml"))
                out.push_back(r);
        } while (FindNextFileA(h, &fd));
        FindClose(h);
    }

    bool lessNoCase(const std::string& a, const std::string& b) { return lowerAscii(a) < lowerAscii(b); }

    bool selectLayouts(const Options& opt, std::vector<std::string>& out, std::string& error)
    {
        std::map<std::string, std::string> table, byWindow;
        loadInterfaceTable(opt.interfaceTable, table);
        for (std::map<std::string, std::string>::const_iterator it = table.begin(); it != table.end(); ++it)
            byWindow[lowerAscii(it->second)] = it->first;
        for (size_t i = 0; i < opt.layouts.size(); ++i)
        {
            const std::string& x = opt.layouts[i];
            std::string sel;
            const bool absolute = x.size() > 1 && (x[1] == ':' || (x[0] == '\\' && x[1] == '\\'));
            if (absolute)
            {
                const std::string full = fullPath(x);
                for (size_t r = 0; r < opt.uiRoots.size() && sel.empty(); ++r)
                    if (startsWithNoCase(full, opt.uiRoots[r] + "\\"))
                        sel = slashes(full.substr(opt.uiRoots[r].size() + 1), '/');
                if (sel.empty())
                {
                    error = "--layout " + x + " is not inside a --ui root";
                    return false;
                }
            }
            else if (endsWithNoCase(x, ".xml"))
                sel = slashes(x, '/');
            else
            {
                const std::string cand = x + "/" + x + ".layout.xml"; // folder name
                for (size_t r = 0; r < opt.uiRoots.size() && sel.empty(); ++r)
                    if (fileExists(joinPath(opt.uiRoots[r], slashes(cand, '\\'))))
                        sel = cand;
                if (sel.empty())
                {
                    std::map<std::string, std::string>::const_iterator it = byWindow.find(lowerAscii(x)); // window name
                    if (it != byWindow.end())
                        sel = it->second;
                }
                if (sel.empty())
                {
                    error = "--layout " + x + ": no such layout file, folder or InterfaceEx window name";
                    return false;
                }
            }
            out.push_back(sel);
        }
        if (!opt.listFile.empty())
        {
            if (!fileExists(opt.listFile))
            {
                error = "cannot read --list " + opt.listFile;
                return false;
            }
            std::vector<std::string> ls = readLines(opt.listFile);
            for (size_t i = 0; i < ls.size(); ++i)
                out.push_back(slashes(ls[i], '/'));
        }
        if (opt.all)
        {
            std::vector<std::string> all;
            std::set<std::string> seen;
            for (size_t r = 0; r < opt.uiRoots.size(); ++r)
            {
                std::vector<std::string> v;
                enumerateLayouts(opt.uiRoots[r], "", v);
                for (size_t i = 0; i < v.size(); ++i)
                    if (seen.insert(lowerAscii(v[i])).second)
                        all.push_back(v[i]);
            }
            std::sort(all.begin(), all.end(), lessNoCase);
            out.insert(out.end(), all.begin(), all.end());
        }
        if (!opt.filter.empty())
        {
            std::vector<std::string> kept;
            for (size_t i = 0; i < out.size(); ++i)
                if (lowerAscii(out[i]).find(lowerAscii(opt.filter)) != std::string::npos)
                    kept.push_back(out[i]);
            out.swap(kept);
        }
        if (opt.start > 0 || opt.count >= 0)
        {
            size_t b = std::min(out.size(), (size_t)std::max(0, opt.start));
            size_t e = opt.count >= 0 ? std::min(out.size(), b + (size_t)opt.count) : out.size();
            out = std::vector<std::string>(out.begin() + b, out.begin() + e);
        }
        if (out.empty())
            error = "the selection is empty";
        return !out.empty();
    }

    std::string safeName(const std::string& s)
    {
        std::string o;
        for (size_t i = 0; i < s.size(); ++i)
        {
            char c = s[i];
            o += ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '-' || c == '_') ? c : '_';
        }
        return o;
    }

    std::string runNameFor(const Options& opt)
    {
        std::string name;
        if (opt.all)
            name = "all";
        else if (!opt.listFile.empty())
        {
            std::string stem = fileNameOf(opt.listFile);
            name = "list-" + stem.substr(0, stem.find('.'));
        }
        else if (opt.composite)
            name = "composite-" + std::to_string(opt.layouts.size());
        else if (opt.layouts.size() == 1)
        {
            std::string l = fileNameOf(slashes(opt.layouts[0], '\\'));
            if (endsWithNoCase(l, ".layout.xml"))
                l.erase(l.size() - 11);
            name = "layout-" + l;
        }
        else
            name = "layouts-" + std::to_string(opt.layouts.size());
        name += "-" + std::to_string(opt.width) + "x" + std::to_string(opt.height);
        if (!opt.filter.empty())
            name += "-f_" + opt.filter;
        if (opt.gameScheme)
            name += "-game";
        if (opt.strictFonts)
            name += "-strictfonts";
        if (!opt.wic)
            name += "-nowic";
        if (opt.sampleText)
            name += "-sample";
        if (opt.codePage != 65001)
            name += "-cp" + std::to_string(opt.codePage);
        return safeName(name);
    }

    WorkerPaths pathsFor(const Options& opt, int run, bool singleShot)
    {
        WorkerPaths p;
        char buf[32];
        std::sprintf(buf, "run_%03d", run);
        p.runDir = joinPath(opt.outDir, buf);
        p.records = joinPath(opt.outDir, "records.tsv");
        p.progress = joinPath(opt.outDir, "progress.txt");
        if (endsWithNoCase(opt.shot, ".png"))
        {
            if (singleShot)
                p.shotFile = fullPath(opt.shot);
            p.shotDir = parentDir(fullPath(opt.shot));
        }
        else
            p.shotDir = opt.shot.empty() ? joinPath(opt.outDir, "shots") : fullPath(opt.shot);
        return p;
    }

    int runWorker(const Options& opt, const std::vector<std::string>& layouts, int run, int start, bool singleShot)
    {
        HWND hwnd = createViewerWindow(opt);
        if (!hwnd)
        {
            std::printf("CysUiViewer: cannot create the window\n");
            return EXIT_ENGINE;
        }
        int rc = EXIT_OK;
        {
            App app(opt);
            std::string err;
            if (!app.init(hwnd, pathsFor(opt, run, singleShot), run == 0, err))
            {
                std::printf("CysUiViewer: initialisation failed: %s\n", err.c_str());
                rc = EXIT_ENGINE;
            }
            else
                rc = opt.interactive ? app.runInteractive(layouts) : app.runBatch(layouts, start);
            if (!guardedShutdown(&app))
                std::printf("CysUiViewer: warning: fault during engine shutdown (ignored)\n");
        }
        DestroyWindow(hwnd);
        return rc;
    }

    std::wstring quoteArg(const std::wstring& a)
    {
        std::wstring o = L"\"";
        size_t bs = 0;
        for (size_t i = 0; i < a.size(); ++i)
        {
            wchar_t c = a[i];
            if (c == L'\\')
            {
                ++bs;
                continue;
            }
            if (c == L'"')
            {
                o.append(bs * 2 + 1, L'\\');
                o += L'"';
            }
            else
            {
                o.append(bs, L'\\');
                o += c;
            }
            bs = 0;
        }
        o.append(bs * 2, L'\\');
        return o + L"\"";
    }

    std::wstring acpWide(const std::string& s) { return utf8ToWide(acpToUtf8(s)); }

    // Runs the layouts in worker processes; a worker that crashes or stops making progress is replaced and the
    // batch continues after the layout it was processing (which gets a crash/hang record).
    int supervise(const Options& opt, int argc, wchar_t** argv, const std::vector<std::string>& layouts,
                  const std::string& listPath, std::vector<std::string>& runDirs)
    {
        const std::string progress = joinPath(opt.outDir, "progress.txt");
        const std::string records = joinPath(opt.outDir, "records.tsv");
        wchar_t exe[MAX_PATH * 2];
        GetModuleFileNameW(NULL, exe, MAX_PATH * 2);
        std::wstring base = quoteArg(exe);
        for (int i = 1; i < argc; ++i)
            base += L" " + quoteArg(argv[i]);
        const int n = (int)layouts.size();
        int next = 0, run = 0, fruitless = 0;
        while (next < n)
        {
            DeleteFileA(progress.c_str());
            char runName[32];
            std::sprintf(runName, "run_%03d", run);
            runDirs.push_back(joinPath(opt.outDir, runName));
            std::wstring cmd = base + L" --worker --worker-list " + quoteArg(acpWide(listPath)) + L" --worker-start " +
                               std::to_wstring(next) + L" --worker-run " + std::to_wstring(run) + L" --out " +
                               quoteArg(acpWide(opt.outDir));
            STARTUPINFOW si;
            ZeroMemory(&si, sizeof(si));
            si.cb = sizeof(si);
            PROCESS_INFORMATION pi;
            ZeroMemory(&pi, sizeof(pi));
            if (!CreateProcessW(NULL, &cmd[0], NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi))
            {
                std::printf("supervisor: cannot start a worker (error %lu)\n", GetLastError());
                return EXIT_ENGINE;
            }
            std::string seen = "\x01";
            double changed = nowSeconds();
            bool hung = false;
            while (WaitForSingleObject(pi.hProcess, 1000) == WAIT_TIMEOUT)
            {
                std::string p = readText(progress);
                if (p != seen)
                {
                    seen = p;
                    changed = nowSeconds();
                }
                else if (nowSeconds() - changed > opt.timeoutSec)
                {
                    hung = true;
                    TerminateProcess(pi.hProcess, 6);
                    WaitForSingleObject(pi.hProcess, 10000);
                    break;
                }
            }
            DWORD exitCode = 0;
            GetExitCodeProcess(pi.hProcess, &exitCode);
            CloseHandle(pi.hThread);
            CloseHandle(pi.hProcess);
            const std::string p = readText(progress);
            if (p.compare(0, 4, "done") == 0)
                break; // finished (a fault during shutdown does not matter)
            const int idx = p.empty() ? -1 : std::atoi(p.c_str());
            if (idx < next || idx >= n)
            {
                if (++fruitless >= 2)
                {
                    std::printf("supervisor: workers failed twice before the first layout (exit code %lu) - giving up\n",
                                exitCode);
                    return EXIT_ENGINE;
                }
                ++run;
                continue;
            }
            fruitless = 0;
            std::vector<LayoutRecord> recs;
            readRecords(records, recs);
            bool have = false;
            for (size_t i = 0; i < recs.size() && !have; ++i)
                have = recs[i].index == idx;
            if (!have)
            {
                LayoutRecord r;
                r.index = idx;
                r.status = hung ? "hang" : "crash";
                r.file = layouts[idx];
                char buf[128];
                if (hung)
                    std::sprintf(buf, "no progress for %d s - worker killed", opt.timeoutSec);
                else
                    std::sprintf(buf, "worker exit code 0x%08lX", exitCode);
                r.failure = buf;
                appendRecord(records, r);
            }
            std::printf("supervisor: worker %d stopped at [%d] %s (%s) - continuing at %d\n", run, idx,
                        layouts[idx].c_str(), hung ? "hang" : "crash", idx + 1);
            std::fflush(stdout);
            next = idx + 1;
            ++run;
        }
        return EXIT_OK;
    }

    void printSection(const std::string& summary, const char* from, const char* to)
    {
        size_t b = summary.find(from);
        if (b == std::string::npos)
            return;
        size_t e = summary.find(to, b + 1);
        std::printf("%s", summary.substr(b, e == std::string::npos ? std::string::npos : e - b).c_str());
    }
}

int wmain(int argc, wchar_t** argv)
{
    SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX | SEM_NOOPENFILEERRORBOX);
    _set_abort_behavior(0, _WRITE_ABORT_MSG | _CALL_REPORTFAULT);
    SetProcessDPIAware();
    SetConsoleOutputCP(CP_UTF8);

    Options& opt = g_opt;
    bool helpOnly = false;
    int rc = parseOptions(argc, argv, opt, helpOnly);
    if (helpOnly)
        return EXIT_OK;
    if (rc != EXIT_OK)
        return rc;
    resolveDefaults(opt, runNameFor(opt));
    SetUnhandledExceptionFilter(crashFilter);
    std::set_terminate(onTerminate);
    CoInitializeEx(NULL, COINIT_APARTMENTTHREADED);
    const double t0 = nowSeconds();

    if (opt.worker)
    {
        std::vector<std::string> layouts = readLines(opt.workerList);
        rc = runWorker(opt, layouts, opt.workerRun, opt.workerStart, opt.composite || layouts.size() == 1);
        CoUninitialize();
        return rc;
    }

    std::vector<std::string> layouts;
    std::string error;
    if (!selectLayouts(opt, layouts, error))
    {
        std::printf("CysUiViewer: %s\n", error.c_str());
        return EXIT_USAGE;
    }
    makeDirs(opt.outDir);
    std::printf("CysUiViewer: %d layout(s), %dx%d, UI root %s, out %s\n", (int)layouts.size(), opt.width, opt.height,
                acpToUtf8(opt.uiRoots[0]).c_str(), acpToUtf8(opt.outDir).c_str());
    std::fflush(stdout);
    if (opt.interactive)
    {
        rc = runWorker(opt, layouts, 0, 0, true);
        CoUninitialize();
        return rc;
    }

    cleanOutDir(opt.outDir);
    const std::string listPath = joinPath(opt.outDir, "layouts.lst");
    {
        FILE* f = std::fopen(listPath.c_str(), "wb");
        if (f)
        {
            for (size_t i = 0; i < layouts.size(); ++i)
                std::fprintf(f, "%s\n", layouts[i].c_str());
            std::fclose(f);
        }
    }
    std::vector<std::string> runDirs;
    const bool batch = layouts.size() > 1 && !opt.composite;
    if (batch && opt.supervise)
        rc = supervise(opt, argc, argv, layouts, listPath, runDirs);
    else
    {
        rc = runWorker(opt, layouts, 0, 0, !batch);
        runDirs.push_back(joinPath(opt.outDir, "run_000"));
    }

    ReportInput ri;
    ri.outDir = opt.outDir;
    ri.commandLine = wideToUtf8(GetCommandLineW());
    ri.baselineLog = opt.baseline;
    ri.runDirs = runDirs;
    ri.width = opt.width;
    ri.height = opt.height;
    ri.seconds = nowSeconds() - t0;
    std::vector<LayoutRecord> recs;
    readRecords(joinPath(opt.outDir, "records.tsv"), recs);
    const std::string summary = writeReports(ri, recs);
    if (batch)
    {
        printSection(summary, "== layouts", "== load failures");
        printSection(summary, "== load failures", "== top CEGUI");
    }
    std::printf("summary: %s\n", acpToUtf8(joinPath(opt.outDir, "summary.txt")).c_str());
    CoUninitialize();
    if (batch)
        return rc == EXIT_ENGINE ? EXIT_ENGINE : EXIT_OK;
    return rc;
}
