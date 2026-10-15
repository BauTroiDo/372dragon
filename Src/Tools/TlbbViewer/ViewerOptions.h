// TlbbViewer - command line options and text helpers.
//
// Names given on the command line (model, animation, effect, locator, material) are converted to the byte
// strings the engine uses: GBK, exactly as stored in all.obj / all.effect / all.skill / all.material. Paths are
// converted the same way, which matches the on-disk names (GBK bytes shown as cp1252 mojibake under ACP 1252).
#pragma once

#include <string>
#include <vector>

namespace tlbbv
{
    enum ExitCode
    {
        EXIT_OK        = 0,
        EXIT_USAGE     = 1,
        EXIT_NOT_FOUND = 2,   // model / animation / effect / scene not found or failed to load
        EXIT_ENGINE    = 3,   // engine or device initialisation failed
        EXIT_CAPTURE   = 4,   // screenshot could not be written
        EXIT_CRASH     = 5,   // unhandled SEH exception (see the .dmp next to the log)
    };

    struct Options
    {
        // window / device
        int   width   = 1920;
        int   height  = 1080;
        int   fsaa    = 4;       // multisample count, 0 = off
        bool  fsaaExplicit = false; // CYS fx-render: --fsaa given (--postfx turns back-buffer MSAA off otherwise)
        int   aniso   = 8;      // CYS-PARITY (S1): CY world anisotropy x8 / Game.exe View_TextureFiltering=2
        bool  vsync   = true;
        bool  show    = true;    // window visible; --shot hides it unless --show
        bool  showExplicit = false;
        bool  stats   = false;   // Ogre frame-stats overlay

        // data / engine
        std::string dataDir;     // default C:\TLBB\085\client_GL\Data
        std::vector<std::string> resDirs; // CYS: --res <dir> (repeatable) - extra "General" folder trees
        float timeOfDay = -1.0f;  // CYS: --time-of-day hours [0, 24); < 0 = CYS_TIME_OF_DAY / scene default
        float timeScale = -1.0f;  // CYS: --time-scale game hours per real second; < 0 = CYS_TIME_SCALE / frozen
        std::string logFile;     // default: <shot>.log, or TlbbViewer.log next to the exe
        bool  verbose = false;   // full Ogre log detail (default: critical messages only)
        bool  strict  = false;   // stock WX resource initialisation, no compatibility shims

        // content
        std::string model;       // LogicModel template from all.obj, e.g. "xxx.obj"
        std::string anim;        // skill (all.skill) or skeleton animation name
        std::string effect;      // effect template from all.effect
        std::string locator;     // attach --effect to this locator of --model
        std::string scene;       // .Scene path (or a file name inside SceneFolder)
        std::string skybox;      // material for Ogre's sky box
        std::string postFilter;  // WX post filter type (Floodlighting, Bloom, ...)
        std::vector<std::string> postFx; // CYS fx-render: --postfx b | key=value | key=value file (repeatable)
        std::vector<std::string> shadow; // CYS-SHADOW: --shadow <0|1|2|off|low|high|Gfx_Shadow*=value> (repeatable)
        float modelScale = 1.0f;         // CYS: fx-effects --scale <f>: uniform scale of the model (LogicModel::setScaleFactor)
        bool  effectFollowScale = false; // CYS: fx-effects --effect-follow-scale: the model's effects follow its scale (B LogicModel+0x328)
        bool  noSubEffects = false;      // CYS: fx-effects --no-sub-effects: disable the particle sub-effect system

        // camera
        bool  hasCamera = false;
        bool  hasModelAt = false;               // CYS-PARITY d3d9-trace: --model-at x,z[,yaw]
        float modelAt[3] = { 0, 0, 0 };
        float camera[7] = { 0, 0, 0, 0, 0, 0, 45 };   // eye xyz, target xyz, vertical fov (deg)
        float orbitYaw   = 30.0f;                      // auto framing, degrees
        float orbitPitch = 12.0f;
        float fov        = 45.0f;

        // look
        std::string lights;      // studio | fake | flat | scene ; empty = studio, or scene when --scene
        bool  hasBg = false;
        float bg[3] = { 0, 0, 0 };
        bool  grid  = false;
        bool  ff    = false;     // diagnostic: drop pixel programs from passes without a vertex program

        // automation
        std::string shot;        // PNG path
        int   frames  = 60;
        float dt      = 1.0f / 30.0f;
        float simTime = -1.0f;   // simulate at least this many seconds before the shot
        bool  dump    = false;   // print the content scene graph (materials, techniques, particles) before exiting

        // listing
        std::string list;        // models | effects | skills | materials | anims
        std::string listFilter;

        // CYS fx-audit: runtime census, deterministic effect sheets (Docs/specs/render/07-fx-audit_vi.md)
        std::string fxCensusDir;          // --fx-census <dir>: dump runtime dictionaries/templates/materials, exit
        std::string fxSheetList;          // --fx-sheet <list.tsv>: batch render "id \t kind \t name [\t anim]"
        std::string outDir;               // --out <dir>: output folder of --fx-sheet
        std::vector<float> times;         // --times s,s,...: capture times of --fx-sheet (default 0.15,0.4,0.8,1.5,3)
        std::vector<std::string> bgNames; // --bgs black,grey,...: backgrounds of --fx-sheet (default black,grey)
        std::vector<float> bgColours;     // 3 floats per entry of bgNames
        bool  hasSeed = false;            // --seed <n>: srand(n) at start-up and before every sheet item
        unsigned int seed = 0;
        bool  dtExplicit = false;         // --dt given (sheet default dt is 1/60 s)
        float turntable = 0.0f;           // --turntable deg/s: camera yaw speed (sheet and --shot)
        bool  fit = true;                 // --fit auto|none: sheet camera fitted to the union of the bounds
        std::string shaderCache;          // --shader-cache <dir> (default <exe dir>\ShaderCache)
        bool  legacyPrefilter = false;    // --legacy-prefilter: old line/block dropping of all.particle/all.effect
        bool  wideNames = false;          // --wide-names: resource folders via FindFirstFileW/CreateFileW (CJK names)
    };

    // Parses argv. Returns EXIT_OK to continue; otherwise the process exit code (usage / errors printed).
    // 'helpOnly' is set when --help was requested (exit code EXIT_OK, nothing else to do).
    int parseOptions(int argc, wchar_t** argv, Options& opt, bool& helpOnly);

    void printUsage(void);

    // UTF-16 text -> engine bytes (GBK). cp1252 mojibake of GBK is taken byte for byte, real Chinese via CP 936.
    std::string toEngineBytes(const std::wstring& text);

    // Engine bytes (GBK/ASCII) -> UTF-16.
    std::wstring engineToWide(const std::string& bytes);

    // Console output of engine strings: WriteConsoleW on a console, UTF-8 when redirected. Appends a newline.
    void out(const std::string& gbkText);
    void err(const std::string& gbkText);

    // Directory of the running executable (ACP bytes, no trailing separator).
    std::string exeDirectory(void);

    // Lower-case ASCII letters only (GBK trail bytes are left untouched).
    std::string asciiLower(const std::string& s);
}
