#ifndef __CYS_POSTFX_H__
#define __CYS_POSTFX_H__

// CY-Source (post-processing agent, 2026-09-12): public entry points of the CY-Source post-processing framework.
// Specification: Docs/specs/render/02-postfx.md (framework 1, filters 2, per-scene files 3). Written from the spec
// and B's shader sources (client_GL MaterialTemplates.zip); no decompiled code.
//
// Filters (WX::PostFilter types, created / enabled / parameterised by name through WX::PostFilterManager):
//   GenSSAO, FXAA, FXAAQuality, DLAA, DoF, NewHDRBloom, ColorLUT, HeightFog, GodRays
// All enabled CY-Source filters of a viewport run in ONE OGRE compositor (CysPostFxPipeline): scene colour in a
// 16-bit float target, an optional linear-depth node (R32F), two shared ping-pong targets, B's chain order
// (02 1: ... FXAA, NewHDRBloom, ColorLUT, HeightFog, GodRays). The 0.85 filters (Floodlighting, Fade, Bloom,
// HeatVision, MotionBlur) keep their own compositors and run after it.
//
// Configuration: start-up and run time go through the same call, so a value read from System.cfg at start-up
// takes effect without a VARIABLE_CHANGED event (fixes doc 08 3.6):
//   CysPostFx::applyVariable(manager, viewport, key, value)   or   CysPostFx::applyConfigFile(...)
// Keys (case-insensitive): View_HDRFilter, View_Fanhunjiao, View_FullScreenLight (B System.cfg names),
//   Gfx_PostFX, Gfx_AA (none|fxaa|fxaaquality|dlaa), Gfx_HDRBloom, Gfx_SSAO, Gfx_HeightFog, Gfx_GodRays, Gfx_DoF,
//   Gfx_ColorLUT (auto = CY: scene LUT at View_HumanLightmap 2 | 0 | 1 | <lut.png>), View_HumanLightmap,
//   PostFX.Media (folder), PostFX.<Filter>.<Parameter> = value,
//   PostFX.Preset (b = client_GL exact, default: 8-bit targets + B's NewHDRBloom | cinematic = FP16 + ACES path).

#include "PostFilter/WXPostFilterPrerequisites.h"

namespace Ogre
{
    class Viewport;
}

namespace WX
{
    namespace CysPostFx
    {
        /// Registers the CY-Source filter factories (idempotent). Called by registerAllPostFilterFactories().
        void registerFactories(PostFilterManager* manager);

        /// Folder holding CysPostFX.material and the CY-Source HLSL files. Default search: this folder,
        /// %CYS_POSTFX_MEDIA%, <exe>\CysPostFX, <exe>\..\Media\CysPostFX, then the source tree of the build.
        void setMediaDirectory(const String& directory);
        /// Loads the media into resource group "CysPostFX" (once); false if it cannot be found / parsed.
        /// The host may instead add the folder to any resource group it initialises itself.
        bool initialiseMedia(void);
        const String& getResourceGroup(void);

        /// Returns the filter `type` of the manager, creating it on `viewport` (name == type) if needed;
        /// 0 if no factory has this type.
        PostFilter* ensureFilter(PostFilterManager* manager, Ogre::Viewport* viewport, const String& type);

        /// Applies one configuration variable (see above); true if the key is known.
        bool applyVariable(PostFilterManager* manager, Ogre::Viewport* viewport, const String& key,
                           const String& value);
        /// Applies key=value lines ('#' and ';' start comments); returns the number of keys applied.
        size_t applyConfigFile(PostFilterManager* manager, Ogre::Viewport* viewport, const String& fileName);

        /// Real texture name of a texture produced by the pipeline of `viewport` for other systems:
        /// "depth_buffer" (linear view depth, R32F; B: content_type compositor SceneRender depth_buffer) and
        /// "ssao_buffer" (ambient occlusion, 1 = open; B samples it at s12 in CalcLight.inc). Empty when the
        /// pipeline does not produce it this frame. Names change when the pipeline is rebuilt.
        String getSharedTexture(Ogre::Viewport* viewport, const String& logicalName);

        /// Pipelines update (rebuild, per-frame constants) in Root's frameStarted. Hosts that render without
        /// Root frame events call this once per frame before rendering.
        void update(Real dt);

        // ---- CYS fx-render (2026-09-13): host integration (game Render.dll, TlbbViewer) ----
        /// Looks a configuration variable up in the host (the game's System.cfg); false when the host does not set it.
        typedef bool (*VariableLookup)(void* user, const String& key, String& value);
        /// Applies every key of the post chain once at start-up, exactly as a run-time change would: the host's value
        /// when it sets the key, else the shipped default, which is what client_GL shows in the world:
        ///   Gfx_PostFX 1; View_Fanhunjiao 1 = FXAA; View_HDRFilter 1 = NewHDRBloom with the scene's .newhdrbloom;
        ///   Gfx_HeightFog 1 = B's height fog, built only while the scene environment has it (EnvKey
        ///   height_fog_enabled; "2" forces it); Gfx_SSAO / Gfx_GodRays / Gfx_DoF / Gfx_ColorLUT 0 (B has none of
        ///   them on); View_FullScreenLight, Gfx_AA, Gfx_HDRBloom, PostFX.Media: host value only.
        /// Then the key=value file named by PostFX.Config (PostFX.<Filter>.<Parameter> lines, see applyConfigFile).
        /// lookup may be 0 (defaults only). Returns the number of keys applied.
        size_t applyStartup(PostFilterManager* manager, Ogre::Viewport* viewport, VariableLookup lookup, void* user);
        /// Shipped default of a configuration key ("" = none: left alone when the host does not set it).
        String getDefaultValue(const String& key);
        /// Scene hook (host Scene_Load): B forces View_HDRFilter off on the login / character screens (scene id < 0,
        /// Render.dll FUN_180018540) and restores the configured state for world scenes.
        void onSceneLoaded(PostFilterManager* manager, Ogre::Viewport* viewport, int sceneId);
        // ---- CYS-LUT (2026-09-14, colorlut): per-scene ColorLUT as CY 3.71 ----
        /// Scene hook with the scene file (host Scene_Load, TlbbViewer): CY's Game.exe picks the LUT of a scene by its
        /// .Scene name (CScene::EnterScene -> Scene_SetSceneLUTParam, Render.dll vtable 0x330) and Render.dll enables
        /// the ColorLUT filter with it only for View_HumanLightmap 2 (FUN_18002e100). Docs/specs/render/colorlut-cy_vi.md.
        void onSceneLoaded(PostFilterManager* manager, Ogre::Viewport* viewport, int sceneId, const String& sceneFile);
        /// LUT texture of a scene as CY's Game.exe table ("" = none): by SceneDefine id when sceneId > 0 (the game),
        /// else by the .Scene name (tools; with or without folders / extension).
        String sceneColorLut(int sceneId, const String& sceneFile);
        /// Effective ColorLUT state for logs / tests: "<lut>|on" or "<lut>|off" (mode, level and scene applied).
        String describeColorLut(void);

        /// Profiling hook: called right before every full-screen pass of every pipeline with the stage type
        /// ("Pipeline" for the pipeline's own passes: 1 = depth-node clear, 2 = final copy) and the stage's pass id.
        typedef void (*PassObserver)(void* user, const String& stageType, unsigned int localPassId);
        void setPassObserver(PassObserver observer, void* user);
        /// Internal (CysPostFxPipeline).
        bool _hasPassObserver(void);
        void _notifyPass(const String& stageType, unsigned int localPassId);
    }
}

#endif // __CYS_POSTFX_H__
