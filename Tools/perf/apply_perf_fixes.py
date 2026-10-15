#!/usr/bin/env python3
"""Applies the CYS-PERF performance fixes to a CY-Source Src tree that already has the CYS-PERF hooks.

  apply_perf_fixes.py SRC_ROOT FIX [FIX ...] [--check]

Fixes (each one is a commit-sized change, measured on its own, see Docs/specs/render/09-performance_vi.md):
  pacer   Game.exe frame pacing as client_GL: System_MaxFPS_Front / System_MaxFPS_Back instead of the fixed 0.85
          System_MaxFPS tick (30 fps), on a high-resolution waitable timer with absolute QPC deadlines.
          CYS_PERF_PACER=legacy restores the 0.85 tick for A/B runs.
  uiredraw  three FalagardEx widgets (login animation, chat edit box, animate) request a whole-GUI rebuild only
          when their frame/alpha changes and the window is visible.
  counters2 instrumentation: texture loads, shader creations, per-call pixel shader constants, focus marks.
  psconst   D3D9: pixel shader float constants uploaded in runs, as the vertex shader path (was one call per register).
  btnalpha  Falagard/Button: setAlpha / requestRedraw only when the value changes. Every visible button called
          setAlpha(1) every frame, so CEGUI rebuilt the whole GUI every frame on every screen.
  uiredraw2 FalagardEx: an idle StopWatch sets its text only when it differs (select/create screens rebuilt the GUI
          every frame); a caret blink redraws only where the caret is drawn (visible, editable, focused).
  seqframe  SequenceFrame affector: per-particle state in a hash map (lookup every particle, every frame).
  nonvis    WXRender: ParticleSystem::setDefaultNonVisibleUpdateTimeout(5.0f) at start-up, as B's Render.dll.

Same rules as apply_perf_hooks.py: exact anchor counts, file read right before editing, BOM/EOL kept, a file that
already carries the fix marker is skipped.
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from apply_perf_hooks import Edit, apply_edit  # noqa: E402

GAME = "Client/WXClient/Procedure/GameProcedure.cpp"

PACER_HELPERS = (
    "// CYS-PERF-FIX pacer: frame pacing on the QueryPerformanceCounter timeline (InitStaticMemeber, MainLoop).\n"
    "namespace\n"
    "{\n"
    "    bool s_cysPacerActive = false;\n"
    "    int s_cysPacerFront = 60;\n"
    "    int s_cysPacerBack = 25;\n"
    "    LONGLONG s_cysPacerFreq = 0;\n"
    "    LONGLONG s_cysPacerNext = 0;\n"
    "\n"
    "    bool cysPacerLegacy(void)\n"
    "    {\n"
    "        static int s_legacy = -1;\n"
    "        if (s_legacy < 0)\n"
    "        {\n"
    "            char mode[16] = {0};\n"
    "            const DWORD n = ::GetEnvironmentVariableA(\"CYS_PERF_PACER\", mode, sizeof(mode));\n"
    "            s_legacy = (n && n < sizeof(mode) && _stricmp(mode, \"legacy\") == 0) ? 1 : 0;\n"
    "        }\n"
    "        return s_legacy == 1;\n"
    "    }\n"
    "    // client_GL ships 90/25; an absent key (0) falls back to 60/25, other values are clamped to 5..240.\n"
    "    void cysPacerConfigure(int front, int back)\n"
    "    {\n"
    "        s_cysPacerFront = front <= 0 ? 60 : (front < 5 ? 5 : (front > 240 ? 240 : front));\n"
    "        s_cysPacerBack = back <= 0 ? 25 : (back < 5 ? 5 : (back > 240 ? 240 : back));\n"
    "        LARGE_INTEGER frequency;\n"
    "        ::QueryPerformanceFrequency(&frequency);\n"
    "        s_cysPacerFreq = frequency.QuadPart;\n"
    "        s_cysPacerNext = 0;\n"
    "        s_cysPacerActive = true;\n"
    "    }\n"
    "    HANDLE cysPacerCreateTimer(bool& highResolution)\n"
    "    {\n"
    "        typedef HANDLE (WINAPI *CreateTimerExW)(LPSECURITY_ATTRIBUTES, LPCWSTR, DWORD, DWORD);\n"
    "        CreateTimerExW createEx = reinterpret_cast<CreateTimerExW>(\n"
    "            ::GetProcAddress(::GetModuleHandleA(\"kernel32.dll\"), \"CreateWaitableTimerExW\"));\n"
    "        // CREATE_WAITABLE_TIMER_HIGH_RESOLUTION (Windows 10 1803+), TIMER_ALL_ACCESS; auto-reset like the old event\n"
    "        HANDLE timer = createEx ? createEx(NULL, NULL, 0x00000002, 0x001F0003) : NULL;\n"
    "        highResolution = timer != NULL;\n"
    "        if (!timer)\n"
    "        {\n"
    "            timer = ::CreateWaitableTimerW(NULL, FALSE, NULL);\n"
    "            if (timer)\n"
    "                ::timeBeginPeriod(1);   // 1 ms scheduler granularity for the standard timer\n"
    "        }\n"
    "        return timer;\n"
    "    }\n"
    "    // Next deadline one period after the previous one (steady cadence, timer latency does not accumulate).\n"
    "    // After a frame longer than a period the cadence restarts from now: no catch-up burst of short frames.\n"
    "    void cysPacerArm(HANDLE timer, bool foreground)\n"
    "    {\n"
    "        LARGE_INTEGER now;\n"
    "        ::QueryPerformanceCounter(&now);\n"
    "        const LONGLONG period = s_cysPacerFreq / (foreground ? s_cysPacerFront : s_cysPacerBack);\n"
    "        if (!s_cysPacerNext)\n"
    "            s_cysPacerNext = now.QuadPart;\n"
    "        else\n"
    "        {\n"
    "            s_cysPacerNext += period;\n"
    "            if (s_cysPacerNext < now.QuadPart)\n"
    "                s_cysPacerNext = now.QuadPart + period;\n"
    "        }\n"
    "        LARGE_INTEGER due;\n"
    "        due.QuadPart = -(LONGLONG)(double(s_cysPacerNext - now.QuadPart) * 1.0e7 / double(s_cysPacerFreq));\n"
    "        if (due.QuadPart >= 0)\n"
    "            due.QuadPart = -1;\n"
    "        ::SetWaitableTimer(timer, &due, 0, NULL, NULL, FALSE);\n"
    "    }\n"
    "}\n"
)

UIREDRAW_ANIMATE_IMAGE = (
    "{I}// CYS-PERF-FIX uiredraw: setImage/requestRedraw rebuild the whole GUI in CEGUI 0.4 and update() also runs for\n"
    "{I}// hidden windows. Redraw only when the frame or its opacity changes, and only if the window can be seen\n"
    "{I}// (showing a window redraws it anyway).\n"
    "{I}const Image* cysFrame = d_animation && d_play ? d_animation->getFrame(age,-1) : 0;\n"
    "{I}const float cysAlpha = d_animation && d_play ? d_animation->getFrameAlpha(age,-1) : 1;\n"
    "{I}if (cysFrame != getImage() || cysAlpha != d_frameAlpha)\n"
    "{I}{\n"
    "{I}    d_frameAlpha = cysAlpha;\n"
    "{I}    if (isVisible())\n"
    "{I}        setImage(cysFrame);\n"
    "{I}    else\n"
    "{I}        d_image.setImage(cysFrame);\n"
    "{I}}"
)

D3D9RS = "Engine/OGRE/RenderSystems/Direct3D9/src/OgreD3D9RenderSystem.cpp"

PS_FLOAT_LOOP_OLD = [   # stripped lines after "mActiveFragmentGpuProgramParameters = params;" (with counters2 applied)
    "// Bind floats",
    "if (params->hasRealConstantParams())",
    "{",
    "// Iterate over params and set the relevant ones",
    "index = 0;",
    "while (realIt.hasMoreElements())",
    "{",
    "const GpuProgramParameters::RealConstantEntry* e = realIt.peekNextPtr();",
    "if (e->isSet)",
    "{",
    "/*",
    "// TEST",
    "LogManager::getSingleton().logMessage(",
    "\"  Set Constant \" + StringConverter::toString(index) + \" to float4(\" +",
    "StringConverter::toString(e->val[0]) + \", \" +",
    "StringConverter::toString(e->val[1]) + \", \" +",
    "StringConverter::toString(e->val[2]) + \", \" +",
    "StringConverter::toString(e->val[3]) + \")\");",
    "*/",
    "",
    "CysPerf::count(CysPerf::C_PS_CONST); // CYS-PERF-C2",
    "if (FAILED(hr = mpD3DDevice->SetPixelShaderConstantF(",
    "index, e->val, 1)))",
    "{",
    "OGRE_EXCEPT(hr, \"Unable to upload pixel shader float parameters\",",
    "\"D3D9RenderSystem::bindGpuProgramParameters\");",
    "}",
    "}",
    "index++;",
    "realIt.moveNext();",
    "}",
    "}",
]

PS_FLOAT_LOOP_NEW = (
    "{I}mActiveFragmentGpuProgramParameters = params;\n"
    "{I}// Bind floats\n"
    "{I}// CYS-PERF-FIX psconst: runs of set registers go up in one SetPixelShaderConstantF call, like the vertex\n"
    "{I}// path above (OGRE 1.2 made one call per pixel shader register). Same registers, same values.\n"
    "{I}if (params->hasRealConstantParams())\n"
    "{I}{\n"
    "{I}    realConstants.resize(params->getRealConstantCount() * 4);\n"
    "{I}    index = 0;\n"
    "{I}    count = 0;\n"
    "{I}    start = 0;\n"
    "{I}    while (realIt.hasMoreElements())\n"
    "{I}    {\n"
    "{I}        const GpuProgramParameters::RealConstantEntry* e = realIt.peekNextPtr();\n"
    "{I}        if (e->isSet)\n"
    "{I}        {\n"
    "{I}            if (!count)\n"
    "{I}                start = index;\n"
    "{I}            realConstants[(count * 4) + 0] = e->val[0];\n"
    "{I}            realConstants[(count * 4) + 1] = e->val[1];\n"
    "{I}            realConstants[(count * 4) + 2] = e->val[2];\n"
    "{I}            realConstants[(count * 4) + 3] = e->val[3];\n"
    "{I}            ++count;\n"
    "{I}        }\n"
    "{I}        else if (count)\n"
    "{I}        {\n"
    "{I}            CysPerf::count(CysPerf::C_PS_CONST); // CYS-PERF-C2: one upload call\n"
    "{I}            if (FAILED(hr = mpD3DDevice->SetPixelShaderConstantF(start, &realConstants[0], count)))\n"
    "{I}            {\n"
    "{I}                OGRE_EXCEPT(hr, \"Unable to upload pixel shader float parameters\",\n"
    "{I}                    \"D3D9RenderSystem::bindGpuProgramParameters\");\n"
    "{I}            }\n"
    "{I}            count = 0;\n"
    "{I}        }\n"
    "{I}        index++;\n"
    "{I}        realIt.moveNext();\n"
    "{I}    }\n"
    "{I}    if (count)\n"
    "{I}    {\n"
    "{I}        CysPerf::count(CysPerf::C_PS_CONST); // CYS-PERF-C2: one upload call\n"
    "{I}        if (FAILED(hr = mpD3DDevice->SetPixelShaderConstantF(start, &realConstants[0], count)))\n"
    "{I}        {\n"
    "{I}            OGRE_EXCEPT(hr, \"Unable to upload pixel shader float parameters\",\n"
    "{I}                \"D3D9RenderSystem::bindGpuProgramParameters\");\n"
    "{I}        }\n"
    "{I}    }\n"
    "{I}}"
)

def tag_changed_lines(new_text, old_lines, tag):
    """Appends `tag` to every non-blank, non-brace line of a replacement block (a diff may split the block into
    several hunks, including lines equal to original ones), so each hunk carries the CYS-PERF tag."""
    out = []
    for line in new_text.split("\n"):
        body = line.replace("{I}", "").strip()
        if body and body not in ("{", "}") and "CYS-PERF" not in body:
            line += " // " + tag
        out.append(line)
    return "\n".join(out)


PS_FLOAT_LOOP_NEW = tag_changed_lines(PS_FLOAT_LOOP_NEW, PS_FLOAT_LOOP_OLD, "CYS-PERF-FIX psconst")

FIXES = {
    # Instrumentation increment (not a fix): texture loads, shader creations and pixel shader constants per frame.
    "counters2": ("CYS-PERF-C2", {
        "Engine/OGRE/OgreMain/include/OgreCysPerf.h": [
            Edit("replace", "C_UI_BATCHES,       ///< CEGUI draw batches",
                 "{I}C_UI_BATCHES,       ///< CEGUI draw batches\n"
                 "{I}C_TEX_LOAD,         ///< textures loaded (D3D9Texture::loadImpl) - CYS-PERF-C2\n"
                 "{I}C_SHADER_CREATE,    ///< D3D9 vertex/pixel shaders created from microcode - CYS-PERF-C2"),
            Edit("replace", "enum { BLOCK_VERSION = 1 };", "{I}enum { BLOCK_VERSION = 2 }; // CYS-PERF-C2: two counters added"),
        ],
        "Engine/WXCore/CYS/Perf/CysPerf.cpp": [
            Edit("replace", '"scenes", "ents", "animdirty", "swskin", "animext", "built", "uirebuild", "uivbfill", "uiquads", "uibatches"',
                 '{I}"scenes", "ents", "animdirty", "swskin", "animext", "built", "uirebuild", "uivbfill", "uiquads", "uibatches",\n'
                 '{I}"texload", "shadercreate" // CYS-PERF-C2'),
        ],
        D3D9RS: [
            Edit("before", "if (FAILED(hr = mpD3DDevice->SetPixelShaderConstantF(",
                 "{I}CysPerf::count(CysPerf::C_PS_CONST); // CYS-PERF-C2", next_prefix="index, e->val, 1)))"),
        ],
        "Engine/OGRE/RenderSystems/Direct3D9/src/OgreD3D9Texture.cpp": [
            Edit("after", '#include "OgreD3D9Texture.h"', '#include "OgreCysPerf.h" // CYS-PERF-C2'),
            Edit("after_brace", "void D3D9Texture::loadImpl()",
                 "{I1}Ogre::CysPerf::count(Ogre::CysPerf::C_TEX_LOAD); // CYS-PERF-C2"),
        ],
        "Engine/OGRE/RenderSystems/Direct3D9/src/OgreD3D9GpuProgram.cpp": [
            Edit("after", '#include "OgreD3D9GpuProgram.h"', '#include "OgreCysPerf.h" // CYS-PERF-C2'),
            Edit("before", "HRESULT hr = mpDevice->CreateVertexShader(",
                 "{I}Ogre::CysPerf::count(Ogre::CysPerf::C_SHADER_CREATE); // CYS-PERF-C2"),
            Edit("before", "HRESULT hr = mpDevice->CreatePixelShader(",
                 "{I}Ogre::CysPerf::count(Ogre::CysPerf::C_SHADER_CREATE); // CYS-PERF-C2"),
        ],
        # Focus changes switch the pacer between System_MaxFPS_Front and _Back: show them in the perf data.
        GAME: [
            Edit("after", "case WM_ACTIVATEAPP:",
                 "{I1}cysPerfMark(wParam ? \"app-active\" : \"app-inactive\"); // CYS-PERF-C2: pacer front/back switch"),
        ],
    }),
    "psconst": ("CYS-PERF-FIX psconst", {
        "Engine/OGRE/OgreMain/include/OgreCysPerf.h": [
            Edit("replace", "C_PS_CONST,         ///< pixel shader float4 constant registers uploaded",
                 "{I}C_PS_CONST,         ///< SetPixelShaderConstantF calls (one per register before CYS-PERF-FIX psconst)"),
        ],
        D3D9RS: [
            Edit("replace_lines", "mActiveFragmentGpuProgramParameters = params;", PS_FLOAT_LOOP_NEW,
                 block=PS_FLOAT_LOOP_OLD),
        ],
    }),
    "uiredraw": ("CYS-PERF-FIX uiredraw", {
        "Client/CEGUIFalagardEx/FalagardLoginWidgets.cpp": [
            Edit("replace_lines", "setImage(d_animation && d_play ? d_animation->getFrame(age,-1) : 0);",
                 UIREDRAW_ANIMATE_IMAGE,
                 block=["d_frameAlpha = d_animation && d_play ? d_animation->getFrameAlpha(age,-1) : 1;",
                        "requestRedraw();"]),
        ],
        "Client/CEGUIFalagardEx/FalagardChatEditBox.cpp": [
            Edit("replace_lines", "void FalagardChatEditBox::updateSelf( float elapsed )",
                 "{I}void FalagardChatEditBox::updateSelf( float elapsed )\n"
                 "{I}{\n"
                 "{I}\t// CYS-PERF-FIX uiredraw: a hidden chat box (loaded with the login screens) must not rebuild the\n"
                 "{I}\t// whole GUI every frame; a visible one keeps redrawing as before.\n"
                 "{I}\tif (isVisible())\n"
                 "{I}\t\trequestRedraw();\n"
                 "{I}}",
                 block=["{", "requestRedraw();", "}"]),
        ],
        "Client/CEGUIFalagardEx/FalagardAnimate.cpp": [
            Edit("replace_lines", "if( m_pAnimate  )",
                 "{I}if( m_pAnimate  )\n"
                 "{I}{\n"
                 "{I}\t// CYS-PERF-FIX uiredraw: redraw (a whole-GUI rebuild) only when the frame or the alpha changes and\n"
                 "{I}\t// the window can be seen; showing the window redraws it anyway.\n"
                 "{I}\tconst Image* cysFrame = d_normalImage.getImage();\n"
                 "{I}\tconst float cysAlpha = m_fAlpha;",
                 block=["{"]),
            Edit("replace_lines", "else",
                 "{I}else\n"
                 "{I}{\n"
                 "{I}\td_normalImage.setImage( NULL ) ;\n"
                 "{I}}\n"
                 "{I}if ((d_normalImage.getImage() != cysFrame || m_fAlpha != cysAlpha) && isVisible()) // CYS-PERF-FIX uiredraw\n"
                 "{I}\trequestRedraw();",
                 block=["{", "d_normalImage.setImage( NULL ) ;", "}", "", "requestRedraw();"]),
        ],
    }),
    # The per-frame whole-GUI rebuild (uirebuild = 1.00 on every screen): found with a hardware write watch on
    # System::d_gui_redraw (74-99 % of the writes came from FalagardButton::updateSelf -> setAlpha(1)).
    "btnalpha": ("CYS-PERF-FIX btnalpha", {
        "ThirdParty/CEGUI-0.4.1/CEGUI/WidgetSets/Falagard/src/FalButton.cpp": [
            Edit("replace_lines", "d_btnAnimationFrame=d_btnAnimation->getFrame(time,-1);",
                 "{I}// CYS-PERF-FIX btnalpha: requestRedraw() and setAlpha() rebuild the whole GUI in CEGUI 0.4 even when\n"
                 "{I}// nothing changed, and updateSelf ran them every frame for every visible button (setAlpha(1) below).\n"
                 "{I}// Same values, applied only when they change.\n"
                 "{I}const Image* cysFrame=d_btnAnimation->getFrame(time,-1); // CYS-PERF-FIX btnalpha\n"
                 "{I}const float cysAlpha=d_btnAnimation->getFrameAlpha(time,-1); // CYS-PERF-FIX btnalpha\n"
                 "{I}if (cysFrame!=d_btnAnimationFrame || cysAlpha!=d_btnAnimationAlpha) // CYS-PERF-FIX btnalpha\n"
                 "{I}{\n"
                 "{I}    d_btnAnimationFrame=cysFrame; // CYS-PERF-FIX btnalpha\n"
                 "{I}    d_btnAnimationAlpha=cysAlpha; // CYS-PERF-FIX btnalpha\n"
                 "{I}    requestRedraw(); // CYS-PERF-FIX btnalpha\n"
                 "{I}}",
                 block=["d_btnAnimationAlpha=d_btnAnimation->getFrameAlpha(time,-1);", "requestRedraw();"]),
            Edit("replace_lines", "setAlpha(d_flashElapsed / 0.6f);",
                 "{I}if (getAlpha() != d_flashElapsed / 0.6f) // CYS-PERF-FIX btnalpha\n"
                 "{I}    setAlpha(d_flashElapsed / 0.6f); // CYS-PERF-FIX btnalpha"),
            Edit("replace_lines", "else",
                 "{I}else if (getAlpha() != 1.0f) // CYS-PERF-FIX btnalpha\n"
                 "{I}    setAlpha(1); // CYS-PERF-FIX btnalpha",
                 block=["setAlpha(1);"]),
        ],
    }),
    # What was left on the select/create screens after btnalpha (same write watch): an idle Falagard/StopWatch
    # re-set its text every frame, and a caret blink asked for a rebuild even where the caret is not drawn.
    "uiredraw2": ("CYS-PERF-FIX uiredraw2", {
        "Client/CEGUIFalagardEx/FalStopWatch.cpp": [
            Edit("replace_lines", 'setText("");',
                 '{I}if (!getText().empty()) // CYS-PERF-FIX uiredraw2: setText() redraws by itself; an idle stopwatch\n'
                 '{I}\tsetText(""); // CYS-PERF-FIX uiredraw2: re-set the same text and redrew every frame',
                 block=["requestRedraw();"]),
            Edit("replace_lines", 'setText("N/A");',
                 '{I}if (getText() != String("N/A")) // CYS-PERF-FIX uiredraw2\n'
                 '{I}\tsetText("N/A"); // CYS-PERF-FIX uiredraw2',
                 block=["requestRedraw();"]),
        ],
        "Client/CEGUIFalagardEx/FalIMEEditBox.cpp": [
            Edit("replace_lines", "d_lastBlink = time_now;",
                 "{I}d_lastBlink = time_now;\n"
                 "\n"
                 "{I}// CYS-PERF-FIX uiredraw2: the caret is drawn only when the box is visible, editable and focused\n"
                 "{I}// (populateRenderCache); a blink anywhere else rebuilt the whole GUI for nothing.\n"
                 "{I}if (isVisible() && !isReadOnly() && hasInputFocus()) // CYS-PERF-FIX uiredraw2\n"
                 "{I}\trequestRedraw(); // CYS-PERF-FIX uiredraw2",
                 block=["", "requestRedraw();"]),
        ],
    }),
    # Requested by the orchestrator from the fx-particles findings (Build/Logs/2026-09-13-fx-particles/HANDOFF.md).
    "seqframe": ("CYS-PERF-FIX seqframe", {
        "Engine/WXCore/CYS/Effects/WXSequenceFrameAffector.h": [
            Edit("after", "#include <map>", "#include <unordered_map> // CYS-PERF-FIX seqframe"),
            Edit("replace", "typedef std::map<const Ogre::Particle*, ParticleState> ParticleStateMap;",
                 "{I}// CYS-PERF-FIX seqframe: _getTexCoordIndex looks every particle up on every frame (texcoord submit +35 %\n"
                 "{I}// with std::map, fx-particles bench). A hash map makes the lookup O(1); nothing iterates the states in order.\n"
                 "{I}typedef std::unordered_map<const Ogre::Particle*, ParticleState> ParticleStateMap; // CYS-PERF-FIX seqframe"),
        ],
    }),
    "nonvis": ("CYS-PERF-FIX nonvis", {
        "Engine/WXRender/RenderSystem.cpp": [
            Edit("after", "Ogre::ParticleSystem::setDefaultIterationInterval(0.033f);",
                 "{I}// CYS-PERF-FIX nonvis: B (client_GL Bin64/Render.dll) calls setDefaultNonVisibleUpdateTimeout(5.0f) right after\n"
                 "{I}// setDefaultIterationInterval(0.033f): a particle system out of view for 5 s stops updating until it is seen.\n"
                 "{I}Ogre::ParticleSystem::setDefaultNonVisibleUpdateTimeout(5.0f); // CYS-PERF-FIX nonvis"),
        ],
    }),
    "pacer": ("CYS-PERF-FIX pacer", {
        GAME: [
            Edit("before", "#define CYS_PERF_NO_IMPORT // CYS-PERF: layout only, Game.exe does not link OgreMain",
                 PACER_HELPERS),
            Edit("after", 'TDU_Log("CYS-PERF pacer: System_MaxFPS=%d',
                 "{I}// CYS-PERF-FIX pacer: B (client_GL) paces the loop with System_MaxFPS_Front / System_MaxFPS_Back; its\n"
                 "{I}// Game.exe no longer reads System_MaxFPS (the fixed 30 fps tick of 0.85). The tick event becomes a\n"
                 "{I}// high-resolution waitable timer re-armed every frame. CYS_PERF_PACER=legacy keeps the 0.85 tick.\n"
                 "{I}if (!cysPacerLegacy())\n"
                 "{I}{\n"
                 "{I}\tBOOL haveFront = FALSE, haveBack = FALSE;\n"
                 "{I}\tconst INT front = s_pVariableSystem->GetAs_Int(\"System_MaxFPS_Front\", &haveFront);\n"
                 "{I}\tconst INT back = s_pVariableSystem->GetAs_Int(\"System_MaxFPS_Back\", &haveBack);\n"
                 "{I}\tbool highResolution = false;\n"
                 "{I}\tHANDLE timer = cysPacerCreateTimer(highResolution);\n"
                 "{I}\tif (timer)\n"
                 "{I}\t{\n"
                 "{I}\t\tif (m_hEventTimer) ::timeKillEvent(m_hEventTimer);\n"
                 "{I}\t\tm_hEventTimer = NULL;\n"
                 "{I}\t\t::CloseHandle(m_hTickEvent);\n"
                 "{I}\t\tm_hTickEvent = timer;\n"
                 "{I}\t\tcysPacerConfigure(haveFront ? front : 0, haveBack ? back : 0);\n"
                 "{I}\t\tcysPacerArm(m_hTickEvent, true);\n"
                 "{I}\t\tTDU_Log(\"CYS-PERF pacer: front %d fps, back %d fps (System_MaxFPS_Front/Back), %s waitable timer\",\n"
                 "{I}\t\t\ts_cysPacerFront, s_cysPacerBack, highResolution ? \"high-resolution\" : \"standard\");\n"
                 "{I}\t}\n"
                 "{I}}", match="startswith"),
            Edit("after_brace", "if (dwResult == WAIT_OBJECT_0)",
                 "{I1}if (s_cysPacerActive) cysPacerArm(m_hTickEvent, m_bActive != FALSE); // CYS-PERF-FIX pacer: next deadline"),
        ],
    }),
}


def process(src_root, rel, edits, check, marker):
    path = os.path.join(src_root, rel.replace("/", os.sep))
    with open(path, "rb") as handle:           # read right before editing
        data = handle.read()
    bom = data.startswith(b"\xef\xbb\xbf")
    text = data[3:].decode("utf-8", "surrogateescape") if bom else data.decode("utf-8", "surrogateescape")
    if marker in text:
        return "skip (already has %s)" % marker
    eol ="\r\n" if "\r\n" in text else "\n"
    lines = text.split(eol)
    for edit in edits:
        error = apply_edit(lines, edit)
        if error:
            return "FAIL: " + error
    if check:
        return "ok (check only)"
    with open(path, "wb") as handle:
        handle.write((b"\xef\xbb\xbf" if bom else b"") + eol.join(lines).encode("utf-8", "surrogateescape"))
    return "patched"


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("src_root")
    parser.add_argument("fixes", nargs="+", choices=sorted(FIXES))
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args(argv)
    failures = 0
    for name in args.fixes:
        marker, files = FIXES[name]
        for rel, edits in files.items():
            result = process(args.src_root, rel, edits, args.check, marker)
            failures += result.startswith("FAIL")
            print("%-8s %-60s %s" % (name, rel, result))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
