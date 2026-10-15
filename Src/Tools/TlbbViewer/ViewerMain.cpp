// TlbbViewer - entry point: window, crash handling, message forwarding.
#include "ViewerApp.h"
#include "ViewerOptions.h"

#include <dbghelp.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>

namespace
{
    tlbbv::ViewerApp* g_app = NULL;
    char g_dumpPath[MAX_PATH] = { 0 };

    // Any unhandled SEH exception: report module+offset, write a minidump, exit with EXIT_CRASH (no WER dialog,
    // so automation never hangs).
    LONG WINAPI crashFilter(EXCEPTION_POINTERS* ep)
    {
        static volatile LONG entered = 0;
        if (InterlockedExchange(&entered, 1) != 0)
            TerminateProcess(GetCurrentProcess(), tlbbv::EXIT_CRASH);

        void* address = (ep && ep->ExceptionRecord) ? ep->ExceptionRecord->ExceptionAddress : NULL;
        DWORD code = (ep && ep->ExceptionRecord) ? ep->ExceptionRecord->ExceptionCode : 0;
        HMODULE module = NULL;
        char moduleName[MAX_PATH] = "?";
        if (address && GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                                          GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                                          (LPCSTR)address, &module))
        {
            GetModuleFileNameA(module, moduleName, MAX_PATH);
        }
        fprintf(stderr, "TlbbViewer: CRASH exception 0x%08lX at %s+0x%llX\n", code, moduleName,
                (unsigned long long)((const char*)address - (const char*)module));

        if (g_dumpPath[0])
        {
            HANDLE file = CreateFileA(g_dumpPath, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
            if (file != INVALID_HANDLE_VALUE)
            {
                MINIDUMP_EXCEPTION_INFORMATION info;
                info.ThreadId = GetCurrentThreadId();
                info.ExceptionPointers = ep;
                info.ClientPointers = FALSE;
                MiniDumpWriteDump(GetCurrentProcess(), GetCurrentProcessId(), file,
                                  (MINIDUMP_TYPE)(MiniDumpWithIndirectlyReferencedMemory | MiniDumpScanMemory),
                                  &info, NULL, NULL);
                CloseHandle(file);
                fprintf(stderr, "TlbbViewer: minidump written to %s\n", g_dumpPath);
            }
        }
        fflush(stderr);
        TerminateProcess(GetCurrentProcess(), tlbbv::EXIT_CRASH);
        return EXCEPTION_EXECUTE_HANDLER;
    }

    LRESULT CALLBACK viewerWndProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp)
    {
        if (g_app)
        {
            LRESULT result = 0;
            if (g_app->handleMessage(hwnd, msg, wp, lp, result))
                return result;
        }

        switch (msg)
        {
        case WM_GETMINMAXINFO:
            {
                // Allow client areas larger than the desktop (e.g. 1920x1080 plus borders on a 1080p screen).
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

    HWND createViewerWindow(const tlbbv::Options& opt)
    {
        HINSTANCE instance = GetModuleHandleW(NULL);

        WNDCLASSEXW wc;
        ZeroMemory(&wc, sizeof(wc));
        wc.cbSize = sizeof(wc);
        wc.style = CS_HREDRAW | CS_VREDRAW;
        wc.lpfnWndProc = viewerWndProc;
        wc.hInstance = instance;
        wc.hIcon = LoadIcon(NULL, IDI_APPLICATION);
        wc.hCursor = LoadCursor(NULL, IDC_ARROW);
        wc.hbrBackground = (HBRUSH)GetStockObject(BLACK_BRUSH);
        wc.lpszClassName = L"TlbbViewerWindow";
        RegisterClassExW(&wc);

        std::wstring title = L"TlbbViewer";
        if (!opt.model.empty())
            title += L" - " + tlbbv::engineToWide(opt.model);
        if (!opt.effect.empty())
            title += L" - " + tlbbv::engineToWide(opt.effect);
        if (!opt.scene.empty())
            title += L" - " + tlbbv::engineToWide(opt.scene);

        const DWORD style = WS_OVERLAPPEDWINDOW;
        RECT rc = { 0, 0, opt.width, opt.height };
        AdjustWindowRect(&rc, style, FALSE);
        HWND hwnd = CreateWindowExW(0, wc.lpszClassName, title.c_str(), style, CW_USEDEFAULT, CW_USEDEFAULT,
                                    rc.right - rc.left, rc.bottom - rc.top, NULL, NULL, instance, NULL);
        if (!hwnd)
            return NULL;

        // The D3D9 back buffer takes the client size of this window: make it exact.
        RECT client;
        GetClientRect(hwnd, &client);
        if (client.right != opt.width || client.bottom != opt.height)
        {
            RECT outer;
            GetWindowRect(hwnd, &outer);
            SetWindowPos(hwnd, NULL, 0, 0,
                         (outer.right - outer.left) + (opt.width - client.right),
                         (outer.bottom - outer.top) + (opt.height - client.bottom),
                         SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
        }

        if (opt.show)
        {
            ShowWindow(hwnd, SW_SHOWNORMAL);
            UpdateWindow(hwnd);
        }
        return hwnd;
    }

    // No C++ objects in this frame, so __try is allowed with /EHsc.
    bool guardedShutdown(tlbbv::ViewerApp* app)
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
}

int wmain(int argc, wchar_t** argv)
{
    SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX | SEM_NOOPENFILEERRORBOX);
    _set_abort_behavior(0, _WRITE_ABORT_MSG | _CALL_REPORTFAULT);
    SetProcessDPIAware();

    tlbbv::Options opt;
    bool helpOnly = false;
    int rc = tlbbv::parseOptions(argc, argv, opt, helpOnly);
    if (helpOnly)
        return tlbbv::EXIT_OK;
    if (rc != tlbbv::EXIT_OK)
        return rc;

    std::string dump = opt.logFile;
    size_t dot = dump.find_last_of('.');
    size_t slash = dump.find_last_of("\\/");
    if (dot != std::string::npos && (slash == std::string::npos || dot > slash))
        dump.erase(dot);
    dump += ".dmp";
    strncpy(g_dumpPath, dump.c_str(), MAX_PATH - 1);
    SetUnhandledExceptionFilter(crashFilter);

    HWND hwnd = createViewerWindow(opt);
    if (!hwnd)
    {
        tlbbv::err("TlbbViewer: cannot create the window");
        return tlbbv::EXIT_ENGINE;
    }

    int result = tlbbv::EXIT_OK;
    {
        tlbbv::ViewerApp app(opt);
        g_app = &app;
        result = app.run(hwnd);
        if (!guardedShutdown(&app))
            tlbbv::err("TlbbViewer: warning: fault during engine shutdown (ignored)");
        g_app = NULL;
    }
    DestroyWindow(hwnd);
    return result;
}
