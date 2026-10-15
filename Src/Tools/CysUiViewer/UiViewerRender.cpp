// CysUiViewer - layouts: load (SEH guarded), render, back buffer capture, texture placeholders, batch and interactive
// loops. CYS: new tool (2026-09-12). Keep this file ASCII.
#include "UiViewerApp.h"

#include <Ogre.h>
#include <CEGUI.h>
#include <OgreCEGUIRenderer.h>

#include <d3d9.h>
#include <dbghelp.h>

#include <cstdio>
#include <cstdlib>
#include <cstring>

namespace cysui
{
    namespace
    {
        const unsigned long kCxxException = 0xE06D7363;

        char g_sehWhere[2048] = "";   // location + callers of the last hardware exception stopped by sehCall

        void ensureSymbols(void)
        {
            static bool symbols = false;
            if (!symbols)
            {
                SymSetOptions(SYMOPT_LOAD_LINES | SYMOPT_UNDNAME | SYMOPT_DEFERRED_LOADS);
                SymInitialize(GetCurrentProcess(), NULL, TRUE);
                symbols = true;
            }
        }

        // module+offset, function and source line (PDBs sit next to the DLLs in the build tree)
        void describeAddress(void* addr, char* out, size_t size)
        {
            HMODULE module = NULL;
            char moduleName[MAX_PATH] = "?";
            if (GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                                   (LPCSTR)addr, &module))
                GetModuleFileNameA(module, moduleName, MAX_PATH);
            const char* base = std::strrchr(moduleName, '\\');
            base = base ? base + 1 : moduleName;
            ensureSymbols();
            char symbuf[sizeof(SYMBOL_INFO) + 256];
            ZeroMemory(symbuf, sizeof(symbuf));
            SYMBOL_INFO* sym = (SYMBOL_INFO*)symbuf;
            sym->SizeOfStruct = sizeof(SYMBOL_INFO);
            sym->MaxNameLen = 255;
            DWORD64 disp = 0;
            IMAGEHLP_LINE64 line;
            ZeroMemory(&line, sizeof(line));
            line.SizeOfStruct = sizeof(line);
            DWORD ldisp = 0;
            const bool hasSym = SymFromAddr(GetCurrentProcess(), (DWORD64)(UINT_PTR)addr, &disp, sym) != FALSE;
            const bool hasLine = SymGetLineFromAddr64(GetCurrentProcess(), (DWORD64)(UINT_PTR)addr, &ldisp, &line) != FALSE;
            const char* file = hasLine ? std::strrchr(line.FileName, '\\') : NULL;
            _snprintf(out, size - 1, "%s+0x%llx %s%s%s:%lu", base,
                      (unsigned long long)((const char*)addr - (const char*)module), hasSym ? sym->Name : "?",
                      hasLine ? " " : "", hasLine ? (file ? file + 1 : line.FileName) : "",
                      hasLine ? (unsigned long)line.LineNumber : 0UL);
            out[size - 1] = 0;
        }

        // faulting frame + up to 7 callers: "module+off function file:line <- caller <- ..."
        void describeStack(EXCEPTION_POINTERS* ep, char* out, size_t size)
        {
            ensureSymbols();
            out[0] = 0;
            size_t used = 0;
            CONTEXT ctx = *ep->ContextRecord;
            STACKFRAME64 sf;
            ZeroMemory(&sf, sizeof(sf));
            sf.AddrPC.Offset = ctx.Rip;
            sf.AddrPC.Mode = AddrModeFlat;
            sf.AddrFrame.Offset = ctx.Rbp;
            sf.AddrFrame.Mode = AddrModeFlat;
            sf.AddrStack.Offset = ctx.Rsp;
            sf.AddrStack.Mode = AddrModeFlat;
            for (int i = 0; i < 8 && used + 8 < size; ++i)
            {
                if (!StackWalk64(IMAGE_FILE_MACHINE_AMD64, GetCurrentProcess(), GetCurrentThread(), &sf, &ctx, NULL,
                                 SymFunctionTableAccess64, SymGetModuleBase64, NULL) || !sf.AddrPC.Offset)
                    break;
                char frame[320];
                describeAddress((void*)(UINT_PTR)sf.AddrPC.Offset, frame, sizeof(frame));
                int n = _snprintf(out + used, size - used - 1, "%s%s", i ? " <- " : "", frame);
                if (n < 0)
                    break;
                used += (size_t)n;
            }
            out[size - 1] = 0;
            if (!out[0])
                describeAddress(ep->ExceptionRecord->ExceptionAddress, out, size);
        }

        int sehFilter(EXCEPTION_POINTERS* ep)
        {
            if (ep->ExceptionRecord->ExceptionCode == kCxxException)
                return EXCEPTION_CONTINUE_SEARCH;
            describeStack(ep, g_sehWhere, sizeof(g_sehWhere));
            return EXCEPTION_EXECUTE_HANDLER;
        }

        // fn must catch its own C++ exceptions; this frame only stops hardware exceptions (no C++ objects here).
        int sehCall(void (*fn)(void*), void* ctx, unsigned long* code)
        {
            __try
            {
                fn(ctx);
                return 0;
            }
            __except (sehFilter(GetExceptionInformation()))
            {
                *code = GetExceptionCode();
                return 1;
            }
        }

        std::string cguiText(const CEGUI::String& s) { return std::string(s.c_str()); }

        std::string sehText(const char* where, unsigned long code)
        {
            char buf[2400];
            std::sprintf(buf, "SEH exception 0x%08lX in %s at %s", code, where, g_sehWhere);
            return buf;
        }

        // ---- renderGUI
        struct GuiCtx
        {
            std::string error;
        };
        void renderGuiCxx(void* p)
        {
            GuiCtx* c = (GuiCtx*)p;
            try { CEGUI::System::getSingleton().renderGUI(); }
            catch (CEGUI::Exception& e) { c->error = cguiText(e.getMessage()); }
            catch (Ogre::Exception& e) { c->error = e.getFullDescription(); }
            catch (std::exception& e) { c->error = e.what(); }
            catch (...) { c->error = "unknown C++ exception in renderGUI"; }
        }

        // ---- loadWindowLayout
        bool layoutPropertyCallback(CEGUI::Window* w, CEGUI::String& name, CEGUI::String& value, void* user)
        {
            return static_cast<App*>(user)->onLayoutProperty(w, name, value);
        }
        struct LoadCtx
        {
            App* app;
            std::string file;
            CEGUI::Window* root;
            std::string error;
        };
        void loadLayoutCxx(void* p)
        {
            LoadCtx* c = (LoadCtx*)p;
            try
            {
                c->root = CEGUI::WindowManager::getSingleton().loadWindowLayout(CEGUI::String(c->file.c_str()), "", "",
                                                                                  &layoutPropertyCallback, c->app);
            }
            catch (CEGUI::Exception& e) { c->error = cguiText(e.getMessage()); }
            catch (Ogre::Exception& e) { c->error = e.getFullDescription(); }
            catch (std::exception& e) { c->error = e.what(); }
            catch (...) { c->error = "unknown C++ exception in loadWindowLayout"; }
        }

        // ---- frames + capture
        bool captureBackBuffer(Ogre::RenderWindow* win, std::vector<unsigned char>& rgb, unsigned& w, unsigned& h,
                               std::string& err)
        {
            IDirect3DDevice9* dev = NULL;
            IDirect3DSurface9* bb = NULL;
            win->getCustomAttribute("D3DDEVICE", &dev);
            win->getCustomAttribute("DDBACKBUFFER", &bb); // not AddRef'ed by the render system
            if (!dev || !bb)
            {
                err = "no D3DDEVICE/DDBACKBUFFER";
                return false;
            }
            D3DSURFACE_DESC d;
            bb->GetDesc(&d);
            IDirect3DSurface9* src = bb;
            IDirect3DSurface9* resolved = NULL;
            if (d.MultiSampleType != D3DMULTISAMPLE_NONE)
            {
                if (FAILED(dev->CreateRenderTarget(d.Width, d.Height, d.Format, D3DMULTISAMPLE_NONE, 0, FALSE, &resolved, NULL)) ||
                    FAILED(dev->StretchRect(bb, NULL, resolved, NULL, D3DTEXF_NONE)))
                {
                    err = "MSAA resolve failed";
                    if (resolved)
                        resolved->Release();
                    return false;
                }
                src = resolved;
            }
            IDirect3DSurface9* sys = NULL;
            bool ok = false;
            if (SUCCEEDED(dev->CreateOffscreenPlainSurface(d.Width, d.Height, d.Format, D3DPOOL_SYSTEMMEM, &sys, NULL)) &&
                SUCCEEDED(dev->GetRenderTargetData(src, sys)))
            {
                D3DLOCKED_RECT lr;
                if (SUCCEEDED(sys->LockRect(&lr, NULL, D3DLOCK_READONLY)))
                {
                    w = d.Width;
                    h = d.Height;
                    rgb.resize((size_t)w * h * 3);
                    ok = d.Format == D3DFMT_X8R8G8B8 || d.Format == D3DFMT_A8R8G8B8;
                    if (!ok)
                        err = "unsupported back buffer format " + std::to_string((int)d.Format);
                    for (unsigned y = 0; y < h && ok; ++y)
                    {
                        const unsigned char* row = (const unsigned char*)lr.pBits + (size_t)y * lr.Pitch;
                        unsigned char* dst = &rgb[(size_t)y * w * 3];
                        for (unsigned x = 0; x < w; ++x, dst += 3)
                        {
                            dst[0] = row[x * 4 + 2];
                            dst[1] = row[x * 4 + 1];
                            dst[2] = row[x * 4 + 0];
                        }
                    }
                    sys->UnlockRect();
                }
                else
                    err = "LockRect failed";
            }
            else
                err = "GetRenderTargetData failed";
            if (sys)
                sys->Release();
            if (resolved)
                resolved->Release();
            return ok;
        }

        struct FrameCtx
        {
            Ogre::Root* root;
            Ogre::RenderWindow* win;
            int frames;
            bool capture;
            std::vector<unsigned char>* rgb;
            unsigned w, h;
            bool ok;
            std::string error;
        };
        void framesCxx(void* p)
        {
            FrameCtx* c = (FrameCtx*)p;
            c->ok = false;
            try
            {
                for (int i = 0; i < c->frames; ++i)
                {
                    pumpMessages();
                    CEGUI::System::getSingleton().injectTimePulse(0.05f);
                    c->root->renderOneFrame();
                }
                if (c->capture)
                {
                    pumpMessages();
                    CEGUI::System::getSingleton().injectTimePulse(0.05f);
                    c->win->update(false); // render without Present, read the back buffer, then present
                    c->ok = captureBackBuffer(c->win, *c->rgb, c->w, c->h, c->error);
                    c->win->swapBuffers(false);
                }
                else
                    c->ok = true;
            }
            catch (Ogre::Exception& e) { c->error = e.getFullDescription(); }
            catch (CEGUI::Exception& e) { c->error = cguiText(e.getMessage()); }
            catch (std::exception& e) { c->error = e.what(); }
            catch (...) { c->error = "unknown C++ exception while rendering"; }
        }

        void destroyCxx(void* p)
        {
            try
            {
                CEGUI::WindowManager::getSingleton().destroyWindow(static_cast<CEGUI::Window*>(p));
                CEGUI::WindowManager::getSingleton().cleanDeadPool();
            }
            catch (...)
            {
            }
        }

        // after a crash: keep the windows out of later frames without destroying them
        void detachCxx(void* p)
        {
            try
            {
                CEGUI::Window* w = static_cast<CEGUI::Window*>(p);
                w->setVisible(false);
                if (w->getParent())
                    w->getParent()->removeChildWindow(w);
            }
            catch (...)
            {
            }
        }

        int countWindows(CEGUI::Window* w)
        {
            int n = 1;
            for (CEGUI::uint i = 0; i < w->getChildCount(); ++i)
                n += countWindows(w->getChildAtIdx(i));
            return n;
        }

        void showAll(CEGUI::Window* w)
        {
            w->setVisible(true);
            for (CEGUI::uint i = 0; i < w->getChildCount(); ++i)
                showAll(w->getChildAtIdx(i));
        }

        bool isTextWindow(CEGUI::Window* w)
        {
            static const char* const classes[] = { "StaticText", "PushButton", "Editbox", "MultiLineEditbox", "Checkbox",
                                                   "RadioButton", "Titlebar", "FalagardSimpleText", "FalagardDragTitle",
                                                   "FalagardIMEEditBox", "FalagardMultiIMEEditBox", "FalagardCheckButton" };
            for (size_t i = 0; i < sizeof(classes) / sizeof(classes[0]); ++i)
                if (w->testClassName(classes[i]))
                    return true;
            return false;
        }

        void fillSample(CEGUI::Window* w, const CEGUI::String& s)
        {
            if (w->getText().empty() && isTextWindow(w))
                w->setText(s);
            for (CEGUI::uint i = 0; i < w->getChildCount(); ++i)
                fillSample(w->getChildAtIdx(i), s);
        }
    }

    // ------------------------------------------------------------------ hooks
    void App::renderGuiGuarded(void)
    {
        GuiCtx ctx;
        unsigned long code = 0;
        if (sehCall(&renderGuiCxx, &ctx, &code))
        {
            m_renderSeh = code;
            return;
        }
        if (ctx.error.empty())
            return;
        m_renderError = ctx.error;
        // OgreCEGUITexture::loadFromFile: "Failed to create Texture object from file 'X'" -> placeholder after the frame
        static const char kTag[] = "Texture object from file '";
        size_t p = ctx.error.find(kTag);
        if (p != std::string::npos)
        {
            p += sizeof(kTag) - 1;
            size_t e = ctx.error.find('\'', p);
            if (e != std::string::npos)
                m_pendingPlaceholders.push_back(ctx.error.substr(p, e - p));
        }
    }

    bool App::onLayoutProperty(CEGUI::Window*, CEGUI::String& name, CEGUI::String& value)
    {
        if (name != "Text" || value.empty())
            return true;
        if (m_opt.sampleText)
        {
            value = m_opt.codePage == 65001 ? m_sample : m_text.resolve(std::string(m_sample.c_str()));
            return true;
        }
        if (m_opt.rawText || !m_dictLoaded)
            return true;
        value = m_text.resolve(std::string(value.c_str())); // as CUIWindowItem::callbackProperty (UIWindowMng.cpp:72)
        return true;
    }

    // ------------------------------------------------------------------ helpers
    std::string App::windowNameFor(const std::string& file) const
    {
        std::map<std::string, std::string>::const_iterator it = m_windowNames.find(lowerAscii(slashes(file, '/')));
        return it == m_windowNames.end() ? std::string() : it->second;
    }

    std::string App::shotPathFor(const std::string& label) const
    {
        if (!m_paths.shotFile.empty())
            return m_paths.shotFile;
        std::string rel = slashes(label, '/');
        if (endsWithNoCase(rel, ".layout.xml"))
            rel.erase(rel.size() - 11);
        std::string dir, file = rel;
        size_t s = rel.find_last_of('/');
        if (s != std::string::npos)
        {
            dir = rel.substr(0, s);
            file = rel.substr(s + 1);
        }
        std::string name = dir.empty() || lowerAscii(dir) == lowerAscii(file) ? file : dir + "__" + file;
        for (size_t i = 0; i < name.size(); ++i)
            if (name[i] == '/' || name[i] == ':' || name[i] == '*' || name[i] == '?' || name[i] == ' ')
                name[i] = '_';
        return joinPath(m_paths.shotDir, name + ".png");
    }

    double App::coverageOf(const std::vector<unsigned char>& rgb) const
    {
        if (rgb.size() < 3)
            return -1.0;
        const size_t n = rgb.size() / 3;
        size_t diff = 0;
        for (size_t i = 0; i < n; ++i)
        {
            int d = std::abs((int)rgb[i * 3] - m_opt.bg[0]) + std::abs((int)rgb[i * 3 + 1] - m_opt.bg[1]) +
                    std::abs((int)rgb[i * 3 + 2] - m_opt.bg[2]);
            if (d > 24)
                ++diff;
        }
        return (double)diff / (double)n;
    }

    void App::writeProgress(int index)
    {
        FILE* f = std::fopen(m_paths.progress.c_str(), "wb");
        if (!f)
            return;
        if (index >= 0)
            std::fprintf(f, "%d\n", index);
        else
            std::fputs("done\n", f);
        std::fclose(f);
    }

    void App::createPendingPlaceholders(void)
    {
        Ogre::TextureManager& tm = Ogre::TextureManager::getSingleton();
        for (size_t i = 0; i < m_pendingPlaceholders.size(); ++i)
        {
            const std::string& name = m_pendingPlaceholders[i];
            if (!m_placeholders.insert(name).second)
                continue;
            try
            {
                Ogre::ResourcePtr old = tm.getByName(name); // the failed load stays registered, unloaded
                if (!old.isNull())
                    tm.remove(old->getHandle());
                const size_t n = 16 * 16 * 4;
                unsigned char* px = new unsigned char[n];
                for (size_t k = 0; k < n; k += 4)
                {
                    px[k] = 255;     // B
                    px[k + 1] = 0;   // G
                    px[k + 2] = 255; // R  -> magenta
                    px[k + 3] = 255; // A
                }
                Ogre::DataStreamPtr ds(new Ogre::MemoryDataStream(px, n, true));
                tm.loadRawData(name, "General", ds, 16, 16, Ogre::PF_A8R8G8B8);
                say("  placeholder texture (magenta): " + name);
            }
            catch (Ogre::Exception& e)
            {
                say("  placeholder FAILED for " + name + ": " + e.getDescription());
            }
        }
        m_pendingPlaceholders.clear();
        CEGUI::System::getSingleton().signalRedraw();
    }

    void App::destroyLayoutWindow(CEGUI::Window* w)
    {
        unsigned long code = 0;
        if (w && sehCall(&destroyCxx, w, &code))
            say("  " + sehText("destroyWindow", code));
    }

    // ------------------------------------------------------------------ layouts
    CEGUI::Window* App::loadLayout(const std::string& file, std::string& failure, bool& crashed)
    {
        LoadCtx c;
        c.app = this;
        c.file = slashes(file, '/');
        c.root = NULL;
        unsigned long code = 0;
        crashed = sehCall(&loadLayoutCxx, &c, &code) != 0;
        if (crashed)
        {
            failure = sehText("loadWindowLayout", code);
            return NULL;
        }
        if (!c.root)
            failure = c.error.empty() ? std::string("loadWindowLayout returned no window") : c.error;
        return c.root;
    }

    bool App::renderAndCapture(std::vector<unsigned char>& rgb, unsigned& w, unsigned& h, std::string& error,
                               bool& crashed)
    {
        crashed = false;
        FrameCtx c;
        c.root = m_root;
        c.win = m_window;
        c.frames = m_opt.frames;
        c.capture = false;
        c.rgb = &rgb;
        c.w = c.h = 0;
        c.ok = false;
        unsigned long code = 0;
        for (int attempt = 0; attempt < 8; ++attempt)
        {
            if (sehCall(&framesCxx, &c, &code) || m_renderSeh)
            {
                crashed = true;
                error = sehText(m_renderSeh ? "renderGUI" : "renderOneFrame", m_renderSeh ? m_renderSeh : code);
                return false;
            }
            // A texture that failed to load aborts renderGUI once per frame: placeholders, then render again.
            for (int pass = 0; pass < 64 && !m_pendingPlaceholders.empty(); ++pass)
            {
                createPendingPlaceholders();
                c.frames = 1;
                c.capture = false;
                if (sehCall(&framesCxx, &c, &code) || m_renderSeh)
                {
                    crashed = true;
                    error = sehText("rendering", m_renderSeh ? m_renderSeh : code);
                    return false;
                }
            }
            if (c.capture && m_pendingPlaceholders.empty())
                break;
            c.frames = 0;
            c.capture = true;
        }
        w = c.w;
        h = c.h;
        error = c.error;
        return c.ok && c.capture;
    }

    LayoutRecord App::processLayouts(int index, const std::vector<std::string>& files, const std::string& label)
    {
        LayoutRecord r;
        r.index = index;
        r.file = slashes(label, '/');
        r.window = files.size() == 1 ? windowNameFor(files[0]) : std::string();
        m_currentIndex = index;
        m_currentLayout = r.file;
        const double t0 = nowSeconds();
        const unsigned long long logStart = fileSize(m_logPath);
        const size_t placeholdersBefore = m_placeholders.size();
        m_renderError.clear();
        m_renderSeh = 0;

        std::vector<CEGUI::Window*> roots;
        bool crashed = false;
        for (size_t i = 0; i < files.size() && !crashed; ++i)
        {
            std::string failure;
            CEGUI::Window* root = loadLayout(files[i], failure, crashed);
            if (root)
                roots.push_back(root);
            else
                r.failure += (r.failure.empty() ? "" : " | ") + (files.size() > 1 ? files[i] + ": " : std::string()) + failure;
        }
        if (crashed)
            r.status = "crash";
        else if (roots.empty())
            r.status = "load-failed";
        else
        {
            for (size_t i = 0; i < roots.size(); ++i)
            {
                m_sheet->addChildWindow(roots[i]);
                roots[i]->show(); // the game hides a loaded layout and shows it on demand
                if (m_opt.showHidden)
                    showAll(roots[i]);
                if (m_opt.sampleAll)
                    fillSample(roots[i], m_sample);
                r.windows += countWindows(roots[i]);
            }
            std::vector<unsigned char> rgb;
            unsigned w = 0, h = 0;
            std::string err;
            bool rc = false;
            if (!renderAndCapture(rgb, w, h, err, rc))
            {
                r.status = rc ? "crash" : "render-failed";
                r.failure += (r.failure.empty() ? "" : " | ") + err;
            }
            else
            {
                r.coverage = coverageOf(rgb);
                if (!m_opt.noShots)
                {
                    const std::string png = shotPathFor(label);
                    if (writePng(png, w, h, rgb))
                        r.png = png;
                    else
                    {
                        r.status = "render-failed";
                        r.failure += (r.failure.empty() ? "" : " | ") + std::string("cannot write ") + png;
                    }
                }
            }
            if (r.status != "crash")
                for (size_t i = 0; i < roots.size(); ++i)
                    destroyLayoutWindow(roots[i]);
            else
            {
                unsigned long dcode = 0;
                for (size_t i = 0; i < roots.size(); ++i)
                    sehCall(&detachCxx, roots[i], &dcode);
            }
        }
        unsigned long long end = 0;
        r.errorLines = readLogErrors(m_logPath, logStart, &end);
        r.errors = (int)r.errorLines.size();
        if (r.status.empty())
            r.status = !r.failure.empty() && files.size() > 1 ? "errors" : (r.errors ? "errors" : "ok");
        r.placeholders = (int)(m_placeholders.size() - placeholdersBefore);
        r.ms = (nowSeconds() - t0) * 1000.0;
        return r;
    }

    int App::runBatch(const std::vector<std::string>& layouts, int start)
    {
        int rc = EXIT_OK;
        const int n = (int)layouts.size();
        const bool single = m_opt.composite || n == 1;
        const int first = m_opt.composite ? 0 : start;
        const int last = m_opt.composite ? 1 : n;
        for (int i = first; i < last; ++i)
        {
            writeProgress(i);
            std::vector<std::string> files = m_opt.composite ? layouts : std::vector<std::string>(1, layouts[i]);
            std::string label = m_opt.composite ? "composite-" + std::to_string(n) : layouts[i];
            LayoutRecord r = processLayouts(i, files, label);
            appendRecord(m_paths.records, r);
            std::printf("[%d/%d] %-13s %s  windows=%d errors=%d placeholders=%d cover=%.3f %.0f ms\n", i + 1,
                        m_opt.composite ? 1 : n, r.status.c_str(), r.file.c_str(), r.windows, r.errors, r.placeholders,
                        r.coverage, r.ms);
            if (single)
            {
                if (!r.failure.empty())
                    std::printf("  failure: %s\n", r.failure.c_str());
                for (size_t e = 0; e < r.errorLines.size() && e < 40; ++e)
                    std::printf("  CEGUI: %s\n", r.errorLines[e].c_str());
                if (!r.png.empty())
                    std::printf("  shot: %s\n", acpToUtf8(r.png).c_str());
                rc = (r.status == "load-failed" || r.status == "crash") ? EXIT_LOADFAIL
                                                                        : (r.status == "render-failed" ? EXIT_CAPTURE : EXIT_OK);
            }
            std::fflush(stdout);
            if (r.status == "crash" && m_opt.worker)
            {
                // After a hardware exception the CEGUI/OGRE state cannot be trusted (a crashed layout otherwise
                // crashes every later frame): this worker ends, the supervisor starts a new one at the next layout.
                writeWorkerFiles();
                std::printf("  worker ends after the crash; the supervisor continues with the next layout\n");
                std::fflush(stdout);
                TerminateProcess(GetCurrentProcess(), EXIT_CRASH);
            }
            if (m_opt.freeEvery > 0 && (i - first + 1) % m_opt.freeEvery == 0)
                CEGUI::ImagesetManager::getSingleton().FreeUnuseImageset();
        }
        writeProgress(-1);
        writeWorkerFiles();
        return rc;
    }

    int App::runInteractive(const std::vector<std::string>& layouts)
    {
        ShowWindow(m_hwnd, SW_SHOWNORMAL);
        UpdateWindow(m_hwnd);
        SetForegroundWindow(m_hwnd);
        std::vector<CEGUI::Window*> roots;
        int shots = 0;
        bool reload = true, quit = false;
        double last = nowSeconds();
        say("interactive: F5 reload the layouts, F12 screenshot, Esc quit");
        while (!quit)
        {
            if (reload)
            {
                reload = false;
                for (size_t i = 0; i < roots.size(); ++i)
                    destroyLayoutWindow(roots[i]);
                roots.clear();
                const unsigned long long logStart = fileSize(m_logPath);
                for (size_t i = 0; i < layouts.size(); ++i)
                {
                    std::string failure;
                    bool crashed = false;
                    CEGUI::Window* w = loadLayout(layouts[i], failure, crashed);
                    if (!w)
                    {
                        say("load failed: " + layouts[i] + ": " + failure);
                        continue;
                    }
                    m_sheet->addChildWindow(w);
                    w->show();
                    if (m_opt.showHidden)
                        showAll(w);
                    if (m_opt.sampleAll)
                        fillSample(w, m_sample);
                    roots.push_back(w);
                }
                unsigned long long end = 0;
                std::vector<std::string> errs = readLogErrors(m_logPath, logStart, &end);
                for (size_t e = 0; e < errs.size() && e < 40; ++e)
                    say("  CEGUI: " + errs[e]);
            }
            MSG msg;
            while (PeekMessageW(&msg, NULL, 0U, 0U, PM_REMOVE))
            {
                if (msg.message == WM_QUIT)
                    quit = true;
                TranslateMessage(&msg);
                DispatchMessageW(&msg);
            }
            if (quit || !IsWindow(m_hwnd))
                break;
            if (m_reloadRequested)
            {
                m_reloadRequested = false;
                reload = true;
                continue;
            }
            const double now = nowSeconds();
            try
            {
                m_system->injectTimePulse((float)(now - last));
            }
            catch (CEGUI::Exception&)
            {
            }
            last = now;
            if (!m_pendingPlaceholders.empty())
                createPendingPlaceholders();
            if (m_shotRequested)
            {
                m_shotRequested = false;
                std::vector<unsigned char> rgb;
                unsigned w = 0, h = 0;
                std::string err;
                bool crashed = false;
                char name[64];
                std::sprintf(name, "interactive_%02d.png", ++shots);
                if (renderAndCapture(rgb, w, h, err, crashed) && writePng(joinPath(m_paths.shotDir, name), w, h, rgb))
                    say("shot: " + acpToUtf8(joinPath(m_paths.shotDir, name)));
                else
                    say("shot failed: " + err);
                continue;
            }
            try
            {
                m_root->renderOneFrame();
            }
            catch (Ogre::Exception& e)
            {
                say("render: " + e.getDescription());
            }
            Sleep(5);
        }
        for (size_t i = 0; i < roots.size(); ++i)
            destroyLayoutWindow(roots[i]);
        writeWorkerFiles();
        return EXIT_OK;
    }
}
