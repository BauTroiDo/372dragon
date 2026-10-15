// TlbbViewer - command line parsing and console/encoding helpers.
#include "ViewerOptions.h"

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cwchar>
#include <vector>

namespace tlbbv
{
    namespace
    {
        // Converts without best-fit substitution; fails if any character is not representable.
        bool convertStrict(UINT codePage, const std::wstring& text, std::string& result)
        {
            result.clear();
            if (text.empty())
                return true;
            BOOL usedDefault = FALSE;
            int n = WideCharToMultiByte(codePage, WC_NO_BEST_FIT_CHARS, text.c_str(), (int)text.size(),
                                        NULL, 0, NULL, &usedDefault);
            if (n <= 0 || usedDefault)
                return false;
            result.resize(n);
            n = WideCharToMultiByte(codePage, WC_NO_BEST_FIT_CHARS, text.c_str(), (int)text.size(),
                                    &result[0], n, NULL, &usedDefault);
            return n > 0 && !usedDefault;
        }

        std::wstring toWide(UINT codePage, const std::string& bytes)
        {
            if (bytes.empty())
                return std::wstring();
            int n = MultiByteToWideChar(codePage, 0, bytes.c_str(), (int)bytes.size(), NULL, 0);
            if (n <= 0)
                return std::wstring(bytes.begin(), bytes.end());
            std::wstring w(n, L'\0');
            MultiByteToWideChar(codePage, 0, bytes.c_str(), (int)bytes.size(), &w[0], n);
            return w;
        }

        void writeLine(DWORD which, FILE* stream, const std::string& gbkText)
        {
            std::wstring w = toWide(936, gbkText);
            w += L"\n";
            HANDLE h = GetStdHandle(which);
            DWORD mode = 0;
            if (h != NULL && h != INVALID_HANDLE_VALUE && GetConsoleMode(h, &mode))
            {
                DWORD written = 0;
                WriteConsoleW(h, w.c_str(), (DWORD)w.size(), &written, NULL);
                return;
            }
            int n = WideCharToMultiByte(CP_UTF8, 0, w.c_str(), (int)w.size(), NULL, 0, NULL, NULL);
            if (n > 0)
            {
                std::string u(n, '\0');
                WideCharToMultiByte(CP_UTF8, 0, w.c_str(), (int)w.size(), &u[0], n, NULL, NULL);
                fwrite(u.data(), 1, u.size(), stream);
                fflush(stream);
            }
        }

        std::string narrowAscii(const std::wstring& w)
        {
            std::string s;
            for (size_t i = 0; i < w.size(); ++i)
                s += (w[i] < 128) ? char(w[i]) : '?';
            return s;
        }

        bool parseFloatList(const std::wstring& text, float* values, int minCount, int maxCount, int& count)
        {
            count = 0;
            const wchar_t* p = text.c_str();
            while (*p && count < maxCount)
            {
                wchar_t* end = NULL;
                double v = wcstod(p, &end);
                if (end == p)
                    return false;
                values[count++] = (float)v;
                p = end;
                while (*p == L' ')
                    ++p;
                if (*p == L',' || *p == L';')
                    ++p;
                else if (*p)
                    return false;
            }
            return *p == 0 && count >= minCount;
        }

        bool parseInt(const std::wstring& text, int& value)
        {
            wchar_t* end = NULL;
            long v = wcstol(text.c_str(), &end, 10);
            if (end == text.c_str() || *end)
                return false;
            value = (int)v;
            return true;
        }

        bool parseFloat(const std::wstring& text, float& value)
        {
            wchar_t* end = NULL;
            double v = wcstod(text.c_str(), &end);
            if (end == text.c_str() || *end)
                return false;
            value = (float)v;
            return true;
        }
    }

    //-----------------------------------------------------------------------
    std::string toEngineBytes(const std::wstring& text)
    {
        std::string result;
        // ASCII, or GBK bytes displayed as cp1252 (how the data files' names appear under ACP 1252).
        if (convertStrict(1252, text, result))
            return result;
        // Real Chinese text.
        if (convertStrict(936, text, result))
            return result;
        // Last resort: lossy GBK.
        int n = WideCharToMultiByte(936, 0, text.c_str(), (int)text.size(), NULL, 0, NULL, NULL);
        result.assign(n > 0 ? n : 0, '\0');
        if (n > 0)
            WideCharToMultiByte(936, 0, text.c_str(), (int)text.size(), &result[0], n, NULL, NULL);
        return result;
    }
    //-----------------------------------------------------------------------
    std::wstring engineToWide(const std::string& bytes)
    {
        return toWide(936, bytes);
    }
    //-----------------------------------------------------------------------
    void out(const std::string& gbkText)
    {
        writeLine(STD_OUTPUT_HANDLE, stdout, gbkText);
    }
    //-----------------------------------------------------------------------
    void err(const std::string& gbkText)
    {
        writeLine(STD_ERROR_HANDLE, stderr, gbkText);
    }
    //-----------------------------------------------------------------------
    std::string exeDirectory(void)
    {
        char buffer[MAX_PATH] = { 0 };
        DWORD n = GetModuleFileNameA(NULL, buffer, MAX_PATH);
        std::string path(buffer, n);
        size_t slash = path.find_last_of("\\/");
        return slash == std::string::npos ? std::string(".") : path.substr(0, slash);
    }
    //-----------------------------------------------------------------------
    std::string asciiLower(const std::string& s)
    {
        std::string r(s);
        for (size_t i = 0; i < r.size(); ++i)
        {
            if (r[i] >= 'A' && r[i] <= 'Z')
                r[i] = char(r[i] - 'A' + 'a');
        }
        return r;
    }
    //-----------------------------------------------------------------------
    void printUsage(void)
    {
        static const char* text =
            "TlbbViewer - TLBB model / effect / scene viewer (OgreMain + D3D9 + WXCore, x64)\n"
            "\n"
            "Content (names exactly as in all.obj / all.effect / all.skill; Chinese or cp1252 mojibake both work):\n"
            "  --model <name.obj>        LogicModel template from all.obj\n"
            "  --anim <name>             skill (all.skill) or skeleton animation to loop on --model\n"
            "  --effect <name>           effect template from all.effect\n"
            "  --locator <name>          attach --effect to this locator of --model\n"
            "  --model-at x,z[,yaw]      place --model on the terrain at world x,z (yaw degrees) instead of the target\n"
            "  --scale <f>               uniform scale of the model (the creation scene uses 1.5)\n"      // CYS: fx-effects --scale
            "  --effect-follow-scale     the model's effects follow its scale (client_GL LogicModel flag)\n" // CYS: fx-effects --scale
            "  --scene <file.Scene>      scene file (full path, or a name inside SceneFolder)\n"
            "  --data <dir>              client Data folder (default C:\\TLBB\\085\\client_GL\\Data)\n"
            "  --res <dir>               extra resources: <dir> and all sub-folders join group General after the\n"
            "                            --data folders (repeatable; e.g. composite avatar_*.obj files)\n"
            "\n"
            "View:\n"
            "  --size WxH                client / back-buffer size (default 1920x1080)\n"
            "  --camera x,y,z,tx,ty,tz[,fov]   eye, target, vertical FOV in degrees\n"
            "  --orbit yaw,pitch         automatic framing angles in degrees (default 30,12)\n"
            "  --fov deg                 vertical FOV for automatic framing (default 45)\n"
            "  --lights studio|fake|flat|scene   lighting preset (default studio; scene with --scene)\n"
            "  --time-of-day hours       scene clock 0..24 (default 12, or CYS_TIME_OF_DAY)\n"
            "  --time-scale x            game hours per real second (default 0 = frozen, or CYS_TIME_SCALE)\n"
            "  --bg r,g,b                solid background (0..1 or 0..255; default: gradient)\n"
            "  --skybox <material>       Ogre sky box material\n"
            "  --postfilter <type>       WX post filter (Floodlighting, Bloom, HeatVision, MotionBlur, Fade)\n"
            "  --shadow <0|1|2|off|low|high|Gfx_Shadow*=v>  CY-Source shadow maps as the game sets them (repeatable)\n" // CYS-SHADOW
            "  --postfx <b|key=value|file>  CY-Source post chain as the game sets it (repeatable, applied in order):\n"
            "                            b = client_GL's start-up set (FXAA + NewHDRBloom with the scene's .newhdrbloom\n"
            "                            + height fog where the scene has it); a System.cfg / PostFX key such as\n"
            "                            View_HDRFilter=0, Gfx_SSAO=1, PostFX.NewHDRBloom.Intensity=2; or a file of\n"
            "                            key=value lines. Turns back-buffer MSAA off unless --fsaa is given.\n"
            "  --grid                    ground grid\n"
            "  --ff                      diagnostic: drop pixel programs from passes without a vertex program\n"
            "                            (fixed-function texturing; shows mesh/texture/animation data; turns the\n"
            "                            runtime material-system variants off)\n"
            "  (default: the WXRender runtime material system pairs vertex programs with the client_GL\n"
            "   templates, shader cache <exe dir>\\ShaderCache; --strict skips it)\n"
            "  --fsaa N  --aniso N  --no-vsync  --stats\n"
            "\n"
            "Automation:\n"
            "  --shot <file.png>         render --frames frames with fixed --dt, save the back buffer, exit\n"
            "  --frames N                frames before the shot (default 60)\n"
            "  --dt seconds              fixed frame time for --shot (default 0.0333)\n"
            "  --time seconds            simulate at least this long before the shot\n"
            "  --show                    keep the window visible in --shot / --list mode\n"
            "  --dump                    after --shot, print the content scene graph (entities, sub-entity\n"
            "                            materials with supported techniques / program status, particle systems)\n"
            "  --list models|effects|skills|materials|anims [filter]   print names and exit\n"
            "  --log <file>              engine log (default <shot>.log or TlbbViewer.log next to the exe)\n"
            "  --verbose                 full Ogre log detail (default: critical messages only)\n"
            "  --strict                  stock WX resource initialisation, no compatibility shims\n"
            "\n"
            "FX audit (Docs/specs/render/07-fx-audit_vi.md, Tools/fx):\n"
            "  --fx-census <dir>         dump the runtime parameter dictionaries, particle/effect/skill templates and\n"
            "                            material texture references to <dir>\\*.tsv (log at full detail), exit\n"
            "  --fx-sheet <list.tsv>     batch: one item per line 'id<TAB>effect|particle|model<TAB>name[<TAB>anim]'\n"
            "                            (UTF-8), captured at --times on every --bgs into --out <dir>, with per-item\n"
            "                            cost metrics (particles, draw calls, CPU/GPU ms at t=1 s) in metrics.tsv\n"
            "  --out <dir>               output folder of --fx-sheet\n"
            "  --times s,s,...           capture times (default 0.15,0.4,0.8,1.5,3; sheet dt default 1/60 s)\n"
            "  --bgs black,grey,...      backgrounds (black, grey, white or r:g:b; default black,grey)\n"
            "  --seed N                  srand(N) at start-up and before every sheet item (Ogre::Math uses rand())\n"
            "  --turntable deg           camera yaw speed in degrees per simulated second\n"
            "  --fit auto|none           sheet camera fitted to the union of the item bounds (default auto)\n"
            "  --shader-cache <dir>      shader microcode cache (default <exe dir>\\ShaderCache)\n"
            "  --legacy-prefilter        old behaviour: drop all.particle lines / all.effect blocks before parsing\n"
            "  --wide-names              read the resource folders with the wide-character API, so files with CJK\n"
            "                            names (Reference / game stage / DataCY) are reachable as on a CP936 system;\n"
            "                            the game's ANSI resource layer cannot (07-fx-audit D1)\n"
            "  --data also accepts the CY / 0.85 layout (Effect, Model, Material, ... and OgreCore/MaterialTemplates\n"
            "  as .zip or folder), e.g. the game stage Data folder or DataCY\n"
            "\n"
            "Exit codes: 0 ok, 1 usage, 2 content not found, 3 engine init, 4 capture, 5 crash (.dmp written)\n"
            "Keys: LMB orbit, RMB/MMB pan, wheel zoom, WASD/QE move (Shift fast), F frame, R reset,\n"
            "      Space pause, G grid, F12 screenshot, Esc quit\n";
        fputs(text, stdout);
        fflush(stdout);
    }
    //-----------------------------------------------------------------------
    int parseOptions(int argc, wchar_t** argv, Options& opt, bool& helpOnly)
    {
        helpOnly = false;
        opt.dataDir = "C:\\TLBB\\085\\client_GL\\Data";

        for (int i = 1; i < argc; ++i)
        {
            const std::wstring a = argv[i];
            std::wstring v;

            // Fetch the value of the current option.
            #define TLBBV_VALUE()                                                     \
                if (i + 1 >= argc)                                                    \
                {                                                                     \
                    err("TlbbViewer: missing value for " + narrowAscii(a));           \
                    return EXIT_USAGE;                                                \
                }                                                                     \
                v = argv[++i];

            #define TLBBV_BAD()                                                       \
                {                                                                     \
                    err("TlbbViewer: bad value for " + narrowAscii(a) + ": " + toEngineBytes(v)); \
                    return EXIT_USAGE;                                                \
                }

            if (a == L"--help" || a == L"-h" || a == L"/?")
            {
                printUsage();
                helpOnly = true;
                return EXIT_OK;
            }
            else if (a == L"--model")    { TLBBV_VALUE(); opt.model = toEngineBytes(v); }
            else if (a == L"--anim")     { TLBBV_VALUE(); opt.anim = toEngineBytes(v); }
            else if (a == L"--effect")   { TLBBV_VALUE(); opt.effect = toEngineBytes(v); }
            else if (a == L"--locator")  { TLBBV_VALUE(); opt.locator = toEngineBytes(v); }
            else if (a == L"--scale") // CYS: fx-effects --scale
            {
                TLBBV_VALUE();
                if (!parseFloat(v, opt.modelScale) || opt.modelScale < 0.01f || opt.modelScale > 100.0f)
                    TLBBV_BAD();
            }
            else if (a == L"--effect-follow-scale") { opt.effectFollowScale = true; } // CYS: fx-effects --scale
            else if (a == L"--no-sub-effects") { opt.noSubEffects = true; } // CYS: fx-effects
            else if (a == L"--scene")    { TLBBV_VALUE(); opt.scene = toEngineBytes(v); }
            else if (a == L"--data")     { TLBBV_VALUE(); opt.dataDir = toEngineBytes(v); }
            else if (a == L"--res")      { TLBBV_VALUE(); opt.resDirs.push_back(toEngineBytes(v)); } // CYS
            else if (a == L"--time-of-day") // CYS
            {
                TLBBV_VALUE();
                if (!parseFloat(v, opt.timeOfDay) || opt.timeOfDay < 0.0f || opt.timeOfDay > 24.0f)
                    TLBBV_BAD();
            }
            else if (a == L"--time-scale") // CYS
            {
                TLBBV_VALUE();
                if (!parseFloat(v, opt.timeScale) || opt.timeScale < 0.0f)
                    TLBBV_BAD();
            }
            else if (a == L"--skybox")   { TLBBV_VALUE(); opt.skybox = toEngineBytes(v); }
            else if (a == L"--postfilter") { TLBBV_VALUE(); opt.postFilter = toEngineBytes(v); }
            else if (a == L"--postfx")   { TLBBV_VALUE(); opt.postFx.push_back(toEngineBytes(v)); } // CYS fx-render
            else if (a == L"--shadow")   { TLBBV_VALUE(); opt.shadow.push_back(toEngineBytes(v)); } // CYS-SHADOW
            else if (a == L"--log")      { TLBBV_VALUE(); opt.logFile = toEngineBytes(v); }
            else if (a == L"--shot")     { TLBBV_VALUE(); opt.shot = toEngineBytes(v); }
            else if (a == L"--size")
            {
                TLBBV_VALUE();
                int w = 0, h = 0;
                if (swscanf(v.c_str(), L"%dx%d", &w, &h) != 2 || w < 16 || h < 16 || w > 16384 || h > 16384)
                    TLBBV_BAD();
                opt.width = w;
                opt.height = h;
            }
            else if (a == L"--camera")
            {
                TLBBV_VALUE();
                int n = 0;
                if (!parseFloatList(v, opt.camera, 6, 7, n))
                    TLBBV_BAD();
                if (n == 6)
                    opt.camera[6] = opt.fov;
                opt.hasCamera = true;
            }
            else if (a == L"--model-at") // CYS-PARITY (d3d9-trace): place --model on the terrain at x,z, yaw in degrees
            {
                TLBBV_VALUE();
                int n = 0;
                if (!parseFloatList(v, opt.modelAt, 2, 3, n))
                    TLBBV_BAD();
                opt.hasModelAt = true;
            }
            else if (a == L"--orbit")
            {
                TLBBV_VALUE();
                float values[2];
                int n = 0;
                if (!parseFloatList(v, values, 2, 2, n))
                    TLBBV_BAD();
                opt.orbitYaw = values[0];
                opt.orbitPitch = values[1];
            }
            else if (a == L"--fov")
            {
                TLBBV_VALUE();
                if (!parseFloat(v, opt.fov) || opt.fov < 1.0f || opt.fov > 170.0f)
                    TLBBV_BAD();
            }
            else if (a == L"--lights")
            {
                TLBBV_VALUE();
                opt.lights = asciiLower(toEngineBytes(v));
                if (opt.lights != "studio" && opt.lights != "fake" && opt.lights != "flat" && opt.lights != "scene")
                    TLBBV_BAD();
            }
            else if (a == L"--bg")
            {
                TLBBV_VALUE();
                int n = 0;
                if (!parseFloatList(v, opt.bg, 3, 3, n))
                    TLBBV_BAD();
                if (opt.bg[0] > 1.0f || opt.bg[1] > 1.0f || opt.bg[2] > 1.0f)
                {
                    for (int k = 0; k < 3; ++k)
                        opt.bg[k] /= 255.0f;
                }
                opt.hasBg = true;
            }
            else if (a == L"--fsaa")     { TLBBV_VALUE(); if (!parseInt(v, opt.fsaa) || opt.fsaa < 0 || opt.fsaa > 16) TLBBV_BAD(); opt.fsaaExplicit = true; }
            else if (a == L"--aniso")    { TLBBV_VALUE(); if (!parseInt(v, opt.aniso) || opt.aniso < 1 || opt.aniso > 16) TLBBV_BAD(); }
            else if (a == L"--frames")   { TLBBV_VALUE(); if (!parseInt(v, opt.frames) || opt.frames < 1) TLBBV_BAD(); }
            else if (a == L"--dt")       { TLBBV_VALUE(); if (!parseFloat(v, opt.dt) || opt.dt < 0.0f || opt.dt > 1.0f) TLBBV_BAD(); opt.dtExplicit = true; }
            else if (a == L"--time")     { TLBBV_VALUE(); if (!parseFloat(v, opt.simTime) || opt.simTime < 0.0f) TLBBV_BAD(); }
            // CYS fx-audit options
            else if (a == L"--fx-census") { TLBBV_VALUE(); opt.fxCensusDir = toEngineBytes(v); }
            else if (a == L"--fx-sheet")  { TLBBV_VALUE(); opt.fxSheetList = toEngineBytes(v); }
            else if (a == L"--out")       { TLBBV_VALUE(); opt.outDir = toEngineBytes(v); }
            else if (a == L"--shader-cache") { TLBBV_VALUE(); opt.shaderCache = toEngineBytes(v); }
            else if (a == L"--legacy-prefilter") { opt.legacyPrefilter = true; }
            else if (a == L"--wide-names") { opt.wideNames = true; } // CYS fx-audit
            else if (a == L"--seed")
            {
                TLBBV_VALUE();
                int s = 0;
                if (!parseInt(v, s) || s < 0)
                    TLBBV_BAD();
                opt.seed = (unsigned int)s;
                opt.hasSeed = true;
            }
            else if (a == L"--turntable") { TLBBV_VALUE(); if (!parseFloat(v, opt.turntable)) TLBBV_BAD(); }
            else if (a == L"--fit")
            {
                TLBBV_VALUE();
                if (v == L"auto") opt.fit = true;
                else if (v == L"none") opt.fit = false;
                else TLBBV_BAD();
            }
            else if (a == L"--times")
            {
                TLBBV_VALUE();
                float values[32];
                int n = 0;
                if (!parseFloatList(v, values, 1, 32, n))
                    TLBBV_BAD();
                opt.times.assign(values, values + n);
                for (size_t k = 0; k < opt.times.size(); ++k)
                {
                    if (opt.times[k] <= 0.0f || opt.times[k] > 120.0f || (k && opt.times[k] <= opt.times[k - 1]))
                        TLBBV_BAD();
                }
            }
            else if (a == L"--bgs")
            {
                TLBBV_VALUE();
                opt.bgNames.clear();
                opt.bgColours.clear();
                std::wstring rest = v + L",";
                size_t start = 0, comma;
                while ((comma = rest.find(L',', start)) != std::wstring::npos)
                {
                    const std::wstring item = rest.substr(start, comma - start);
                    start = comma + 1;
                    float c[3] = { 0, 0, 0 };
                    if (item == L"black")                     { c[0] = c[1] = c[2] = 0.0f; }
                    else if (item == L"grey" || item == L"gray") { c[0] = c[1] = c[2] = 0.5f; }
                    else if (item == L"white")                { c[0] = c[1] = c[2] = 1.0f; }
                    else if (swscanf(item.c_str(), L"%f:%f:%f", &c[0], &c[1], &c[2]) != 3)
                        TLBBV_BAD();
                    opt.bgNames.push_back(narrowAscii(item == L"gray" ? std::wstring(L"grey") : item));
                    opt.bgColours.push_back(c[0]); opt.bgColours.push_back(c[1]); opt.bgColours.push_back(c[2]);
                }
                if (opt.bgNames.empty())
                    TLBBV_BAD();
            }
            else if (a == L"--no-vsync") { opt.vsync = false; }
            else if (a == L"--show")     { opt.show = true; opt.showExplicit = true; }
            else if (a == L"--stats")    { opt.stats = true; }
            else if (a == L"--grid")     { opt.grid = true; }
            else if (a == L"--strict")   { opt.strict = true; }
            else if (a == L"--verbose")  { opt.verbose = true; }
            else if (a == L"--dump")     { opt.dump = true; }
            else if (a == L"--ff")       { opt.ff = true; }
            else if (a == L"--list")
            {
                TLBBV_VALUE();
                opt.list = asciiLower(toEngineBytes(v));
                if (opt.list != "models" && opt.list != "effects" && opt.list != "skills" &&
                    opt.list != "materials" && opt.list != "anims")
                    TLBBV_BAD();
                if (i + 1 < argc && wcsncmp(argv[i + 1], L"--", 2) != 0)
                    opt.listFilter = toEngineBytes(argv[++i]);
            }
            else
            {
                err("TlbbViewer: unknown option " + toEngineBytes(a) + " (see --help)");
                return EXIT_USAGE;
            }

            #undef TLBBV_VALUE
            #undef TLBBV_BAD
        }

        if (opt.list == "anims" && opt.model.empty())
        {
            err("TlbbViewer: --list anims needs --model");
            return EXIT_USAGE;
        }
        if (!opt.locator.empty() && (opt.model.empty() || opt.effect.empty()))
        {
            err("TlbbViewer: --locator needs --model and --effect");
            return EXIT_USAGE;
        }

        // CYS fx-audit: --fx-census / --fx-sheet are batch modes too
        if (!opt.fxSheetList.empty())
        {
            if (opt.outDir.empty())
            {
                err("TlbbViewer: --fx-sheet needs --out <dir>");
                return EXIT_USAGE;
            }
            if (opt.times.empty())
            {
                static const float defaults[] = { 0.15f, 0.4f, 0.8f, 1.5f, 3.0f };
                opt.times.assign(defaults, defaults + 5);
            }
            if (opt.bgNames.empty())
            {
                opt.bgNames.push_back("black");
                opt.bgNames.push_back("grey");
                static const float colours[] = { 0.0f, 0.0f, 0.0f, 0.5f, 0.5f, 0.5f };
                opt.bgColours.assign(colours, colours + 6);
            }
            if (!opt.dtExplicit)
                opt.dt = 1.0f / 60.0f;
            if (opt.dt <= 0.0f)
            {
                err("TlbbViewer: --fx-sheet needs --dt > 0");
                return EXIT_USAGE;
            }
            opt.vsync = false;
        }
        const bool batch = !opt.shot.empty() || !opt.list.empty() || !opt.fxCensusDir.empty() ||
                           !opt.fxSheetList.empty();
        if (batch && !opt.showExplicit)
            opt.show = false;
        if (opt.simTime >= 0.0f && opt.dt > 0.0f)
        {
            int needed = (int)std::ceil(opt.simTime / opt.dt - 1e-4f);
            if (needed > opt.frames)
                opt.frames = needed;
        }
        if (opt.hasCamera)
            opt.fov = opt.camera[6];
        // CYS fx-render: the post chain renders the scene into its own target; MSAA would only cover the final copy
        if (!opt.postFx.empty() && !opt.fsaaExplicit)
            opt.fsaa = 0;
        if (opt.logFile.empty())
        {
            if (!opt.fxCensusDir.empty())
                opt.logFile = opt.fxCensusDir + "\\census.log";      // CYS fx-audit
            else if (!opt.fxSheetList.empty())
                opt.logFile = opt.outDir + "\\sheet.log";            // CYS fx-audit
            else
                opt.logFile = opt.shot.empty() ? exeDirectory() + "\\TlbbViewer.log" : opt.shot + ".log";
        }
        return EXIT_OK;
    }
}
