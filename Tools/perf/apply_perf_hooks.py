#!/usr/bin/env python3
"""Applies the CYS-PERF instrumentation hooks (every inserted line is tagged "CYS-PERF") to a CY-Source Src tree.

  apply_perf_hooks.py SRC_ROOT [--check] [--group NAME ...]

Each edit is anchored on a source line that must occur an exact number of times. A file is read right before it
is edited, keeps its BOM and line endings, and is written only when every anchor of that file matched; a file that
already contains "CYS-PERF" is left alone (running the script twice is a no-op). --check reports without writing.

The hooks only call into Ogre::CysPerf (OgreMain/include/OgreCysPerf.h) and CYS::Perf (WXCore/CYS/Perf), which
must exist in the tree. Groups: ogremain, d3d9, cegui, wxcore, game.
"""
import argparse
import os
import re
import sys

TAG = "CYS-PERF"


def norm(text):
    return re.sub(r"\s+", "", text)


class Edit:
    """op: after | before | replace | after_brace | after_next | replace_lines
    match: strip (whole stripped line), norm (whitespace-free), startswith (stripped prefix), contains, exact
    replace_lines: the anchor line and the following lines listed in `block` (compared stripped) are replaced."""

    def __init__(self, op, anchor, text, count=1, match="strip", then=None, then_match="strip", next_prefix=None,
                 block=None):
        self.op, self.anchor, self.text, self.count, self.match = op, anchor, text, count, match
        self.then, self.then_match, self.next_prefix = then, then_match, next_prefix
        self.block = block or []

    @staticmethod
    def matches(line, anchor, mode):
        s = line.strip()
        if mode == "strip":
            return s == anchor.strip()
        if mode == "norm":
            return norm(line) == norm(anchor)
        if mode == "startswith":
            return s.startswith(anchor.strip())
        if mode == "contains":
            return anchor in line
        if mode == "exact":
            return line.rstrip("\r") == anchor
        raise ValueError(mode)


def indent_of(line):
    return line[: len(line) - len(line.lstrip())]


def unit_of(indent):
    return "\t" if indent.endswith("\t") or (indent == "" ) and False else ("\t" if "\t" in indent else "    ")


def render(text, indent, indent1):
    return [t.replace("{I1}", indent1).replace("{I}", indent) for t in text.split("\n")]


def apply_edit(lines, edit):
    hits = []
    for i, line in enumerate(lines):
        if Edit.matches(line, edit.anchor, edit.match):
            if edit.next_prefix is not None:
                nxt = lines[i + 1].strip() if i + 1 < len(lines) else ""
                if not nxt.startswith(edit.next_prefix):
                    continue
            if edit.op == "replace_lines":
                following = [l.strip() for l in lines[i + 1:i + 1 + len(edit.block)]]
                if following != [b.strip() for b in edit.block]:
                    continue
            hits.append(i)
    if len(hits) != edit.count:
        return "anchor %r matched %d time(s), expected %d" % (edit.anchor, len(hits), edit.count)
    for i in reversed(hits):
        line = lines[i]
        indent = indent_of(line)
        if edit.op in ("after", "before", "replace", "replace_lines"):
            new = render(edit.text, indent, indent + unit_of(indent))
            if edit.op == "after":
                lines[i + 1:i + 1] = new
            elif edit.op == "before":
                lines[i:i] = new
            elif edit.op == "replace_lines":
                lines[i:i + 1 + len(edit.block)] = new
            else:
                lines[i:i + 1] = new
        elif edit.op in ("after_brace", "after_next"):
            target = None
            for j in range(i + 1, min(i + 40, len(lines))):
                if edit.op == "after_brace" and lines[j].strip() == "{":
                    target = j
                    break
                if edit.op == "after_next" and Edit.matches(lines[j], edit.then, edit.then_match):
                    target = j
                    break
            if target is None:
                return "no follow-up line after anchor %r" % edit.anchor
            base = indent_of(lines[target])
            one = base + ("\t" if "\t" in base or (base == "" and "\t" in indent) else "    ")
            new = render(edit.text, base if edit.op == "after_next" else one, one)
            lines[target + 1:target + 1] = new
        else:
            raise ValueError(edit.op)
    return None


INC_OGRE = '#include "OgreCysPerf.h" // CYS-PERF'

GROUPS = {
    "ogremain": {
        "Engine/OGRE/OgreMain/src/OgreRoot.cpp": [
            Edit("after", '#include "OgreRoot.h"', INC_OGRE),
            Edit("after_brace", "bool Root::_fireFrameStarted(FrameEvent& evt)",
                 "{I1}// CYS-PERF: frame boundary of the perf collector (no-op unless CYS_PERF is set)\n"
                 "{I1}if (CysPerf::gBlock.frameBegin)\n"
                 "{I1}    CysPerf::gBlock.frameBegin();\n"
                 "{I1}CysPerf::Scope cysPerfScope(CysPerf::PH_FRAME_STARTED); // CYS-PERF"),
            Edit("replace", "if (!(*i)->frameStarted(evt))",
                 "{I}const long long cysPerfStart = CysPerf::gBlock.listenerTime ? CysPerf::ticks() : 0; // CYS-PERF\n"
                 "{I}const bool cysPerfContinue = (*i)->frameStarted(evt); // CYS-PERF: time of each listener\n"
                 "{I}if (CysPerf::gBlock.listenerTime) // CYS-PERF\n"
                 "{I}    CysPerf::gBlock.listenerTime(*i, 0, CysPerf::ticks() - cysPerfStart);\n"
                 "{I}if (!cysPerfContinue) // CYS-PERF", match="norm"),
            Edit("after_brace", "bool Root::_fireFrameEnded(FrameEvent& evt)",
                 "{I1}CysPerf::Scope cysPerfScope(CysPerf::PH_FRAME_ENDED); // CYS-PERF"),
            Edit("before", "mActiveRenderer->_updateAllRenderTargets();",
                 "{I}CysPerf::Scope cysPerfScope(CysPerf::PH_TARGETS); // CYS-PERF: all auto-updated render targets"),
        ],
        "Engine/OGRE/OgreMain/src/OgreSceneManager.cpp": [
            Edit("after", '#include "OgreStableHeaders.h"', INC_OGRE),
            Edit("replace", "ControllerManager::getSingleton().updateAllControllers();",
                 "{I}{\n"
                 "{I}    CysPerf::Scope cysPerfScope(CysPerf::PH_CONTROLLERS); // CYS-PERF: particle systems, texture animation\n"
                 "{I}    ControllerManager::getSingleton().updateAllControllers();\n"
                 "{I}}\n"
                 "{I}CysPerf::count(CysPerf::C_RENDER_SCENE); // CYS-PERF"),
            Edit("before", "_applySceneAnimations();", "{I}CysPerf::Scope cysPerfScope(CysPerf::PH_SCENE_ANIM); // CYS-PERF"),
            Edit("replace", "_updateSceneGraph(camera);",
                 "{I}{\n"
                 "{I}    CysPerf::Scope cysPerfScope(CysPerf::PH_SCENE_GRAPH); // CYS-PERF\n"
                 "{I}    _updateSceneGraph(camera);\n"
                 "{I}}"),
            Edit("before", "prepareRenderQueue();",
                 "{I}const long long cysPerfCull = CysPerf::begin(); // CYS-PERF: culling + render queue build"),
            Edit("before", "mDestRenderSystem->_beginGeometryCount();",
                 "{I}CysPerf::end(CysPerf::PH_CULL_QUEUE, cysPerfCull); // CYS-PERF"),
            Edit("replace", "_renderVisibleObjects();",
                 "{I}{\n"
                 "{I}    CysPerf::Scope cysPerfScope(CysPerf::PH_DRAW); // CYS-PERF: pass setup + draw submission\n"
                 "{I}    _renderVisibleObjects();\n"
                 "{I}}"),
        ],
        "Engine/OGRE/OgreMain/src/OgreEntity.cpp": [
            Edit("after", '#include "OgreStableHeaders.h"', INC_OGRE),
            Edit("after_brace", "void Entity::_updateRenderQueue(RenderQueue* queue)",
                 "{I1}CysPerf::count(CysPerf::C_ENTITY_QUEUED); // CYS-PERF"),
            Edit("after_brace", "void Entity::updateAnimation(void)",
                 "{I1}CysPerf::Scope cysPerfScope(CysPerf::PH_ANIMATION); // CYS-PERF: skeleton + software skinning"),
            Edit("after", "bool animationDirty = isUpdatesRequired(mAnimationUpdateState);",
                 "{I}if (animationDirty && CysPerf::on()) // CYS-PERF\n"
                 "{I}{\n"
                 "{I}    CysPerf::count(CysPerf::C_ANIM_DIRTY);\n"
                 "{I}    if (softwareAnimation && hasSkeleton())\n"
                 "{I}        CysPerf::count(CysPerf::C_SW_SKIN);\n"
                 "{I}}"),
            Edit("after_brace", "void Entity::_updateAnimation(void)",
                 "{I1}CysPerf::count(CysPerf::C_ANIM_EXTERNAL); // CYS-PERF"),
        ],
    },
    "d3d9": {
        "Engine/OGRE/RenderSystems/Direct3D9/src/OgreD3D9RenderSystem.cpp": [
            Edit("after", '#include "OgreD3D9RenderSystem.h"', INC_OGRE),
            Edit("before", "hr = mpD3DDevice->SetTexture(stage, pTex);", "{I}CysPerf::count(CysPerf::C_TEXTURE); // CYS-PERF"),
            Edit("before", "hr = mpD3DDevice->SetTexture(stage, 0);", "{I}CysPerf::count(CysPerf::C_TEXTURE); // CYS-PERF"),
            Edit("before", "hr = mpD3DDevice->SetTexture(static_cast<DWORD>(stage), mCysIntzTexture);",
                 "{I}CysPerf::count(CysPerf::C_TEXTURE); // CYS-PERF"),
            Edit("replace", "return mpD3DDevice->SetRenderState(state, value);",
                 "{I}{ CysPerf::count(CysPerf::C_RS); return mpD3DDevice->SetRenderState(state, value); } // CYS-PERF"),
            Edit("replace", "return mpD3DDevice->SetSamplerState(sampler, type, value);",
                 "{I}{ CysPerf::count(CysPerf::C_SS); return mpD3DDevice->SetSamplerState(sampler, type, value); } // CYS-PERF"),
            Edit("replace", "return mpD3DDevice->SetTextureStageState(stage, type, value);",
                 "{I}{ CysPerf::count(CysPerf::C_SS); return mpD3DDevice->SetTextureStageState(stage, type, value); } // CYS-PERF"),
            Edit("before", "hr = mpD3DDevice->SetVertexShader(", "{I}CysPerf::count(CysPerf::C_VS); // CYS-PERF"),
            Edit("before", "hr = mpD3DDevice->SetPixelShader(", "{I}CysPerf::count(CysPerf::C_PS); // CYS-PERF"),
            Edit("before", "if (FAILED(hr = mpD3DDevice->SetVertexShaderConstantF(",
                 "{I}CysPerf::count(CysPerf::C_VS_CONST, count); // CYS-PERF", count=2,
                 next_prefix="start, &realConstants[0], count"),
            Edit("before", "if (FAILED(hr = mpD3DDevice->SetVertexDeclaration(d3ddecl->getD3DVertexDeclaration())))",
                 "{I}CysPerf::count(CysPerf::C_DECL); // CYS-PERF"),
            Edit("before", "hr = mpD3DDevice->SetStreamSource(", "{I}CysPerf::count(CysPerf::C_STREAM); // CYS-PERF"),
            Edit("before", "hr = mpD3DDevice->SetIndices( d3dIdxBuf->getD3DIndexBuffer() );",
                 "{I}CysPerf::count(CysPerf::C_INDEX); // CYS-PERF"),
            Edit("before", "hr = mpD3DDevice->DrawIndexedPrimitive(",
                 "{I}CysPerf::count(CysPerf::C_DRAW); CysPerf::count(CysPerf::C_PRIMS, primCount); // CYS-PERF"),
            Edit("before", "hr = mpD3DDevice->DrawPrimitive(",
                 "{I}CysPerf::count(CysPerf::C_DRAW); CysPerf::count(CysPerf::C_PRIMS, primCount); // CYS-PERF"),
        ],
        "Engine/OGRE/RenderSystems/Direct3D9/src/OgreD3D9RenderWindow.cpp": [
            Edit("after", '#include "OgreD3D9RenderWindow.h"', INC_OGRE),
            Edit("after_next", "void D3D9RenderWindow::swapBuffers( bool waitForVSync )",
                 "{I}CysPerf::gpu(CysPerf::MK_PRESENT); // CYS-PERF: end of the frame's GPU work\n"
                 "{I}const long long cysPerfPresent = CysPerf::begin(); // CYS-PERF",
                 then="HRESULT hr;"),
            Edit("before", "if( D3DERR_DEVICELOST == hr )",
                 "{I}CysPerf::end(CysPerf::PH_PRESENT, cysPerfPresent); // CYS-PERF"),
        ],
    },
    "cegui": {
        "ThirdParty/CEGUI-0.4.1/CEGUIRenderer/src/OgreCEGUIRenderer.cpp": [
            Edit("after", "#include <OgreRenderTarget.h>", "#include <OgreCysPerf.h> // CYS-PERF"),
            Edit("replace", "CEGUI::System::getSingleton().renderGUI();",
                 "{I}Ogre::CysPerf::gpu(Ogre::CysPerf::MK_UI_BEGIN); // CYS-PERF\n"
                 "{I}{\n"
                 "{I}    Ogre::CysPerf::Scope cysPerfScope(Ogre::CysPerf::PH_UI_DRAW); // CYS-PERF\n"
                 "{I}    CEGUI::System::getSingleton().renderGUI();\n"
                 "{I}}\n"
                 "{I}Ogre::CysPerf::gpu(Ogre::CysPerf::MK_UI_END); // CYS-PERF", count=2),
            Edit("after_brace", "void OgreCEGUIRenderer::clearRenderList(void)",
                 "{I1}Ogre::CysPerf::count(Ogre::CysPerf::C_UI_REBUILD); // CYS-PERF: full GUI geometry rebuild"),
            Edit("after_brace", "if(!d_sorted)",
                 "{I1}Ogre::CysPerf::count(Ogre::CysPerf::C_UI_VB_FILL); // CYS-PERF"),
            Edit("after", "d_bufferPos = 0;",
                 "{I}Ogre::CysPerf::count(Ogre::CysPerf::C_UI_QUADS, d_quadlist.size()); // CYS-PERF"),
            Edit("before", "d_render_sys->_render(d_render_op);",
                 "{I}Ogre::CysPerf::count(Ogre::CysPerf::C_UI_BATCHES); // CYS-PERF"),
        ],
    },
    "wxcore": {
        "Engine/WXCore/Core/WXSystem.cpp": [
            Edit("after", '#include "CYS/Scene/CYSSceneObjects.h"', '#include "CYS/Perf/CysPerf.h"     // CYS-PERF',
                 match="startswith"),
            Edit("after", "_createViewports();",
                 "{I}CYS::Perf::install(mRoot, mRenderWindow, mSceneManager); // CYS-PERF: no-op unless CYS_PERF is set"),
            Edit("after_brace", "System::~System()",
                 "{I1}CYS::Perf::shutdown(); // CYS-PERF: summary and GPU queries go before OGRE"),
        ],
        "Engine/WXCore/Core/WXSceneInfo.cpp": [
            Edit("after", '#include "CYS/Scene/CYSEnvironment.h"',
                 '#include "CYS/Perf/CysPerf.h"      // CYS-PERF\n#include <OgreCysPerf.h>           // CYS-PERF',
                 match="startswith"),
            Edit("after_brace", "if (!objects.empty())",
                 "{I1}Ogre::CysPerf::Scope cysPerfScope(Ogre::CysPerf::PH_SCENE_BUILD); // CYS-PERF"),
            Edit("after", "mObjectsPerFrame = RUNNING_BUILD_OBJECTS;",
                 '{I}if (objects.empty()) CYS::Perf::mark("scene-built"); // CYS-PERF'),
            Edit("after", "bestObject->createRenderInstance(mSystem);",
                 "{I}Ogre::CysPerf::count(Ogre::CysPerf::C_SCENE_OBJECTS); // CYS-PERF"),
        ],
    },
    "game": {
        "Client/WXClient/Procedure/GameProcedure.cpp": [
            Edit("after", '#include "..\\WXRender\\ResourceProvider.h"',
                 "#define CYS_PERF_NO_IMPORT // CYS-PERF: layout only, Game.exe does not link OgreMain\n"
                 '#include "..\\..\\..\\Engine\\OGRE\\OgreMain\\include\\OgreCysPerf.h"\n'
                 "#include <stdlib.h>\n"
                 "#include <string.h>\n"
                 "\n"
                 "// CYS-PERF: frame phases and marks for the CYS_PERF collector (Engine/WXCore/CYS/Perf). The block is\n"
                 "// exported by OgreMain.dll, which Game.exe does not link: it is looked up once Render.dll loaded it.\n"
                 "namespace\n"
                 "{\n"
                 "    Ogre::CysPerf::Block* cysPerfBlock(void)\n"
                 "    {\n"
                 "        static Ogre::CysPerf::Block* s_block = NULL;\n"
                 "        static bool s_looked = false;\n"
                 "        if (!s_looked)\n"
                 "        {\n"
                 "            HMODULE ogre = ::GetModuleHandleA(\"OgreMain.dll\");\n"
                 "            if (ogre)\n"
                 "            {\n"
                 "                s_looked = true;\n"
                 "                typedef Ogre::CysPerf::Block* (*GetBlock)(void);\n"
                 "                GetBlock get = reinterpret_cast<GetBlock>(::GetProcAddress(ogre, \"CysPerfBlock\"));\n"
                 "                Ogre::CysPerf::Block* block = get ? get() : NULL;\n"
                 "                if (block && block->version == Ogre::CysPerf::BLOCK_VERSION)\n"
                 "                    s_block = block;\n"
                 "            }\n"
                 "        }\n"
                 "        return (s_block && s_block->enabled) ? s_block : NULL;\n"
                 "    }\n"
                 "    LONGLONG cysPerfNow(void)\n"
                 "    {\n"
                 "        LARGE_INTEGER t;\n"
                 "        ::QueryPerformanceCounter(&t);\n"
                 "        return t.QuadPart;\n"
                 "    }\n"
                 "    LONGLONG cysPerfBegin(void) { return cysPerfBlock() ? cysPerfNow() : 0; }\n"
                 "    void cysPerfEnd(int phase, LONGLONG start)\n"
                 "    {\n"
                 "        Ogre::CysPerf::Block* block = start ? cysPerfBlock() : NULL;\n"
                 "        if (block)\n"
                 "        {\n"
                 "            block->phaseTicks[phase] += cysPerfNow() - start;\n"
                 "            ++block->phaseCalls[phase];\n"
                 "        }\n"
                 "    }\n"
                 "    class CysPerfGameScope\n"
                 "    {\n"
                 "    public:\n"
                 "        explicit CysPerfGameScope(int phase) : m_phase(phase), m_start(cysPerfBegin()) {}\n"
                 "        ~CysPerfGameScope() { cysPerfEnd(m_phase, m_start); }\n"
                 "    private:\n"
                 "        int m_phase;\n"
                 "        LONGLONG m_start;\n"
                 "    };\n"
                 "    void cysPerfMark(const char* label)\n"
                 "    {\n"
                 "        Ogre::CysPerf::Block* block = cysPerfBlock();\n"
                 "        if (block && block->mark)\n"
                 "            block->mark(label);\n"
                 "    }\n"
                 "    const char* cysPerfProcName(CGameProcedure* p)\n"
                 "    {\n"
                 "        if (!p) return \"None\";\n"
                 "        if (p == CGameProcedure::s_pProcLogIn) return \"Login\";\n"
                 "        if (p == CGameProcedure::s_pProcCharSel) return \"CharSel\";\n"
                 "        if (p == CGameProcedure::s_pProcCharCreate) return \"CharCreate\";\n"
                 "        if (p == CGameProcedure::s_pProcEnter) return \"Enter\";\n"
                 "        if (p == CGameProcedure::s_pProcMain) return \"Main\";\n"
                 "        if (p == CGameProcedure::s_pProcChangeScene) return \"ChangeScene\";\n"
                 "        return \"Other\";\n"
                 "    }\n"
                 "    // CYS_PERF_HOLD=\"Login:15,CharSel:20\": seconds the scripted UI smoke pauses after the named procedure\n"
                 "    // becomes active, so perf runs sample idle states. Only read in smoke runs.\n"
                 "    DWORD cysPerfHoldMs(const char* procedure)\n"
                 "    {\n"
                 "        char spec[256] = {0};\n"
                 "        const DWORD n = ::GetEnvironmentVariableA(\"CYS_PERF_HOLD\", spec, sizeof(spec));\n"
                 "        if (!n || n >= sizeof(spec) || !procedure) return 0;\n"
                 "        const size_t length = strlen(procedure);\n"
                 "        for (const char* p = spec; *p; )\n"
                 "        {\n"
                 "            while (*p == ',' || *p == ' ') ++p;\n"
                 "            const char* colon = strchr(p, ':');\n"
                 "            if (!colon) break;\n"
                 "            if (size_t(colon - p) == length && _strnicmp(p, procedure, length) == 0)\n"
                 "                return DWORD(atof(colon + 1) * 1000.0);\n"
                 "            const char* comma = strchr(colon, ',');\n"
                 "            if (!comma) break;\n"
                 "            p = comma + 1;\n"
                 "        }\n"
                 "        return 0;\n"
                 "    }\n"
                 "}"),
            Edit("after", "m_hEventTimer = ::timeSetEvent((INT)(1000.0f/nMaxFPS), (INT)(1000.0f/nMaxFPS), EventTimerProc, 0, TIME_PERIODIC|TIME_CALLBACK_FUNCTION);",
                 '{I}TDU_Log("CYS-PERF pacer: System_MaxFPS=%d -> timeSetEvent period %d ms", nMaxFPS, (INT)(1000.0f/nMaxFPS)); // CYS-PERF',
                 match="norm"),
            Edit("before", "while(PeekMessageW(&msg, NULL, 0, 0, PM_REMOVE))",
                 "{I}const LONGLONG cysPerfMsg = cysPerfBegin(); // CYS-PERF: message pump"),
            Edit("before", '//\t\tAxProfile::AxProfile_PopNode("Msg");',
                 "{I}cysPerfEnd(Ogre::CysPerf::PH_GAME_MSG, cysPerfMsg); // CYS-PERF", match="norm"),
            Edit("before", "UINT dwResult = MsgWaitForMultipleObjects(1, &m_hTickEvent,",
                 "{I}const LONGLONG cysPerfWait = cysPerfBegin(); // CYS-PERF: pacer / message wait", match="startswith"),
            Edit("after", "FALSE, INFINITE, QS_ALLINPUT);",
                 "\t\tcysPerfEnd(Ogre::CysPerf::PH_GAME_WAIT, cysPerfWait); // CYS-PERF"),
            Edit("replace", "TickActive();",
                 "{I}{ CysPerfGameScope cysPerf(Ogre::CysPerf::PH_GAME_TICK); TickActive(); } // CYS-PERF"),
            Edit("replace", "RenderActive();",
                 "{I}{ CysPerfGameScope cysPerf(Ogre::CysPerf::PH_GAME_RENDER); RenderActive(); } // CYS-PERF"),
            Edit("replace", "ProcessGameEvent();",
                 "{I}{ CysPerfGameScope cysPerf(Ogre::CysPerf::PH_GAME_EVENTS); ProcessGameEvent(); } // CYS-PERF"),
            Edit("replace", "if (glSmoke) glSmoke->tick(s_pGfxSystem,s_pProcActive == s_pProcCharSel);",
                 "{I}// CYS-PERF: CYS_PERF_HOLD pauses the scripted smoke for a while after each procedure change\n"
                 "{I}static CGameProcedure* s_cysPerfHoldProc = NULL;\n"
                 "{I}static DWORD s_cysPerfHoldEnd = 0;\n"
                 "{I}if (glSmoke && s_pProcActive != s_cysPerfHoldProc)\n"
                 "{I}{\n"
                 "{I}    s_cysPerfHoldProc = s_pProcActive;\n"
                 "{I}    const DWORD hold = cysPerfHoldMs(cysPerfProcName(s_pProcActive));\n"
                 "{I}    s_cysPerfHoldEnd = hold ? GetTickCount() + hold : 0;\n"
                 "{I}    if (hold) TDU_Log(\"CYS-PERF hold: %s %lu ms\", cysPerfProcName(s_pProcActive), (unsigned long)hold);\n"
                 "{I}}\n"
                 "{I}if (s_cysPerfHoldEnd && LONG(GetTickCount() - s_cysPerfHoldEnd) >= 0)\n"
                 "{I}{\n"
                 "{I}    s_cysPerfHoldEnd = 0;\n"
                 "{I}    cysPerfMark(\"hold-end\");\n"
                 "{I}}\n"
                 "{I}if (glSmoke && !s_cysPerfHoldEnd)\n"
                 "{I}{\n"
                 "{I}    CysPerfGameScope cysPerfHarness(Ogre::CysPerf::PH_GAME_OTHER); // CYS-PERF: smoke clicks and PNG captures\n"
                 "{I}    glSmoke->tick(s_pGfxSystem,s_pProcActive == s_pProcCharSel);\n"
                 "{I}}"),
            Edit("after", "if(s_pProcActive)\ts_pProcActive->Init();",
                 "{I}if(s_pProcActive) { char cysPerfLabel[48]; _snprintf(cysPerfLabel, sizeof(cysPerfLabel), \"proc:%s\","
                 " cysPerfProcName(s_pProcActive)); cysPerfLabel[sizeof(cysPerfLabel)-1] = 0; cysPerfMark(cysPerfLabel); } // CYS-PERF",
                 match="norm"),
            Edit("replace", "s_pInputSystem->Tick();",
                 "{I}{ CysPerfGameScope cysPerf(Ogre::CysPerf::PH_GAME_INPUT); s_pInputSystem->Tick(); } // CYS-PERF", match="norm"),
            Edit("replace", "if(s_pUISystem)s_pUISystem->Tick();",
                 "{I}if(s_pUISystem) { CysPerfGameScope cysPerf(Ogre::CysPerf::PH_GAME_UI); s_pUISystem->Tick(); } // CYS-PERF",
                 match="norm"),
            Edit("replace", "s_pNetManager->Tick();",
                 "{I}{ CysPerfGameScope cysPerf(Ogre::CysPerf::PH_GAME_NET); s_pNetManager->Tick(); } // CYS-PERF", match="norm"),
            Edit("replace", "s_pWorldManager->Tick();",
                 "{I}{ CysPerfGameScope cysPerf(Ogre::CysPerf::PH_GAME_WORLD); s_pWorldManager->Tick(); } // CYS-PERF", match="norm"),
            Edit("replace", "s_pObjectManager->Tick();",
                 "{I}{ CysPerfGameScope cysPerf(Ogre::CysPerf::PH_GAME_OBJECT); s_pObjectManager->Tick(); } // CYS-PERF", match="norm"),
            Edit("replace", "s_pScriptSystem->Tick();",
                 "{I}{ CysPerfGameScope cysPerf(Ogre::CysPerf::PH_GAME_SCRIPT); s_pScriptSystem->Tick(); } // CYS-PERF", match="norm"),
        ],
    },
}


def process(src_root, rel, edits, check):
    path = os.path.join(src_root, rel.replace("/", os.sep))
    with open(path, "rb") as handle:           # read right before editing
        data = handle.read()
    bom = data.startswith(b"\xef\xbb\xbf")
    text = data[3:].decode("utf-8", "surrogateescape") if bom else data.decode("utf-8", "surrogateescape")
    if TAG in text:
        return "skip (already has %s)" % TAG
    eol = "\r\n" if "\r\n" in text else "\n"
    lines = text.split(eol)
    for edit in edits:
        error = apply_edit(lines, edit)
        if error:
            return "FAIL: " + error
    if check:
        return "ok (check only)"
    out = eol.join(lines).encode("utf-8", "surrogateescape")
    with open(path, "wb") as handle:
        handle.write((b"\xef\xbb\xbf" if bom else b"") + out)
    return "patched"


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("src_root", help="the Src directory of a CY-Source tree")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--group", action="append", choices=sorted(GROUPS))
    args = parser.parse_args(argv)
    required = ["Engine/OGRE/OgreMain/include/OgreCysPerf.h", "Engine/OGRE/OgreMain/src/OgreCysPerf.cpp",
                "Engine/WXCore/CYS/Perf/CysPerf.h", "Engine/WXCore/CYS/Perf/CysPerf.cpp"]
    missing = [r for r in required if not os.path.isfile(os.path.join(args.src_root, r))]
    if missing:
        print("missing CYS-PERF files: %s" % ", ".join(missing))
        return 2
    failures = 0
    for group in (args.group or sorted(GROUPS)):
        for rel, edits in GROUPS[group].items():
            result = process(args.src_root, rel, edits, args.check)
            failures += result.startswith("FAIL")
            print("%-8s %-72s %s" % (group, rel, result))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
