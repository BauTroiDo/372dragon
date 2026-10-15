#ifndef __CYS_WATER_H__
#define __CYS_WATER_H__

// CY-Source (scene agent): B/C water settings of TerrainLiquid objects (2,253 in 416 scenes; 05 §5) that 0.85 lacks,
// from the B ParameterDefs (Render.dll FUN_180110360) and the data (Tools/re/out/scene_objects.tsv):
//   replaceMaterial (514), mesh name (62), showNewWaterEnabled (57), showMirrorReflectWaterEnabled (80),
//   orientation/scale (mesh water), "texture scale for mesh water low level" (61), "texture depth" (34) and the 13
//   "ShaderParams.*" (~520 each) that feed the constants of Model_Water_ps.hlsl.
//
// What CY-Source does today (no render-node framework yet):
//   * material choice as B's low-quality path: a material that cannot render, or a "new water" material
//     (name contains "shader": B enables those only with View_HumanLightmap = 2 and its "Water" filter),
//     falls back to replaceMaterial; without a usable material nothing is created (0.85 threw from
//     TerrainLiquid::setMaterialName and aborted the scene);
//   * mesh water ("mesh name") is rendered as an entity with that mesh instead of the terrain-flood grid;
//   * ShaderParams are pushed as named constants into every pass program that declares them
//     (FogColorDensity, BigWavesScale, SmallWavesScale, BumpScale, ReflectionAmount, TransparencyRatio,
//     SunShinePow, SunMultiplier, FresnelBias, UVScale, wavesSpeed, texRotateScale, texDepthFactor) on a per-object
//     clone of the material;
//   * CYSWaterRenderHooks is the plug-in point for the reflection / refraction / mirror render targets and the
//     SceneDepthForWater depth node (see the report and CYSWaterRenderHooks below).

#include "CYSSceneCommon.h"

#include <OgreMaterial.h>

namespace WX
{
    class TerrainLiquidObject;

    struct CYSWaterSettings
    {
        enum ShaderParam
        {
            SP_WATER_FOG_COLOR,
            SP_WATER_FOG_DENSITY,
            SP_UV_SCALE,
            SP_WAVE_SPEED,
            SP_BUMP_SCALE_X,
            SP_BUMP_SCALE_Z,
            SP_BIG_WAVES_SCALE,
            SP_SMALL_WAVES_SCALE,
            SP_REFLECTION_AMOUNT,
            SP_TRANSPARENCY_RATIO,
            SP_SUNSHINE_POW,
            SP_SUN_MULTIPLIER,
            SP_FRESNEL_BIAS,
            SP_COUNT
        };

        String replaceMaterial;
        String meshName;
        bool showNewWater;
        bool showMirrorReflectWater;
        Ogre::Quaternion orientation;
        Ogre::Vector3 scale;
        Real meshLowLevelTextureScale;      ///< 0 = not set
        Real textureDepth;                  ///< texDepthFactor; 0 = not set

        Ogre::ColourValue fogColour;        ///< FogColorDensity.rgb
        Real fogDensity;                    ///< FogColorDensity.w
        Ogre::Vector2 uvScale;              ///< UVScale
        Ogre::Vector2 waveSpeed;            ///< x -> wavesSpeed ("Wave Speed(Speed/Angle)": the angle is INF)
        Real bumpScaleX, bumpScaleZ;        ///< BumpScale
        Real bigWavesScale, smallWavesScale, reflectionAmount, transparencyRatio, sunShinePow, sunMultiplier,
             fresnelBias;
        String shaderParamText[SP_COUNT];   ///< the file's text, written back by save
        unsigned int shaderParamMask;       ///< bit i = ShaderParam i given in the scene

        CYSWaterSettings(void);

        /// "ShaderParams.Water Fog Color", ... in the B definition order.
        static const char* getShaderParamName(int index);
        /// Sets one ShaderParam from its property text; false for an unknown name.
        bool setShaderParam(int index, const String& text);
        String getShaderParam(int index) const;
        bool hasShaderParams(void) const { return shaderParamMask != 0; }
    };

    /// Plug-in point for the B water render targets (to be implemented with the render-node framework, 02):
    ///   * refraction RT "waterRefractTex" -> texture unit 2 named "<RefractTexInput>" of technique 0 / pass 0,
    ///   * reflection RT "waterReflectTex" -> texture unit 1 named "<ReflectTexInput>" (512 x 512 PF_X8R8G8B8, the
    ///     reflect/refract clip planes of 0.85 ReflectRenderTargetListener/RefractRenderTargetListener),
    ///   * mirror reflection "waterMirrorReflectTex" with a ReflectRTCamera when showMirrorReflectWaterEnabled,
    ///   * depthMap (s0 of Model_Water_ps) from the SceneDepthForWater node, refractMap (s3), reflectMap (s2).
    class CYSWaterRenderHooks
    {
    public:
        virtual ~CYSWaterRenderHooks() {}
        /// True once the new water (shader materials, RTs, depth) can render; until then B's fallback is used.
        virtual bool supportsNewWater(void) const { return false; }
        /// After the liquid (grid or mesh) got `material` (a per-object clone when it carries ShaderParams).
        virtual void liquidCreated(TerrainLiquidObject& liquid, const Ogre::MaterialPtr& material) = 0;
        virtual void liquidDestroyed(TerrainLiquidObject& liquid) = 0;
        /// CYS-WATER: a new-water surface (technique 1, queue 77) was queued for the current camera; `mirror` when
        /// it is mirror water (its reflection texture has to be up to date).
        virtual void surfaceQueued(bool mirror) { (void)mirror; }
    };

    namespace CYSScene
    {
        void setWaterRenderHooks(CYSWaterRenderHooks* hooks);
        CYSWaterRenderHooks* getWaterRenderHooks(void);

        /// The material exists and has a supported technique after loading (shader compile errors included).
        bool isMaterialUsable(const String& name);
        /// B material choice (see the file comment). `replaced` tells whether replaceMaterial was taken.
        String chooseWaterMaterial(const String& material, const CYSWaterSettings& settings, bool* replaced);
        /// Named constants of Model_Water_ps.hlsl on every pass program that declares them; returns the count set.
        size_t applyWaterShaderParams(const Ogre::MaterialPtr& material, const CYSWaterSettings& settings,
                                      Real textureRotate, Real textureScale);
        /// True when some pass of the material has a vertex or fragment program.
        bool materialHasPrograms(const Ogre::MaterialPtr& material);
        /// Mesh water on the fixed-function path: tile every texture unit `tiles` times.
        void applyTextureTiling(const Ogre::MaterialPtr& material, Real tiles);
        /// CYS-WATER: CY TerrainLiquid::_updateRenderQueue (Render.dll FUN_1801ef510): when new water renders and the
        /// material has a supported technique named "WaterFog" followed by another one, returns both (fog -> queue 76,
        /// surface -> queue 77, priority 100).
        bool getNewWaterTechniques(const Ogre::MaterialPtr& material, Ogre::Technique*& fog, Ogre::Technique*& surface);
        /// CYS-WATER: true for the materials CY treats as new water ("shader" or "PBRScene_Water" in the name).
        bool isNewWaterMaterial(const String& name);
    }
}

#endif // __CYS_WATER_H__
