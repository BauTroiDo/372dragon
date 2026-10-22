#ifndef __CYS_POSTFX_H__
#define __CYS_POSTFX_H__





















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


        void onSceneLoaded(PostFilterManager* manager, Ogre::Viewport* viewport, int sceneId);




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
