// CY-Source (scene agent): see CYSWater.h.
#include "CYSWater.h"
#include "CYS/PostFX/CysPostFxPipeline.h"   // CYS-PARITY (L2): INTZ scene depth

#include <OgreMaterialManager.h>
#include <OgreTechnique.h>
#include <OgrePass.h>
#include <OgreTextureUnitState.h>
#include <OgreGpuProgram.h>
#include <OgreException.h>

#include <cstdio>

namespace WX
{
    using namespace CYSScene;

    namespace
    {
        const char* const kShaderParamNames[CYSWaterSettings::SP_COUNT] =
        {
            "ShaderParams.Water Fog Color",
            "ShaderParams.Water Fog Density",
            "ShaderParams.uvScale",
            "ShaderParams.Wave Speed",
            "ShaderParams.Bump Scale X",
            "ShaderParams.Bump Scale Z",
            "ShaderParams.Big Waves Scale",
            "ShaderParams.Small Waves Scale",
            "ShaderParams.Reflection Amount",
            "ShaderParams.Transparency Ratio",
            "ShaderParams.SunShine Pow",
            "ShaderParams.Sun Multiplier",
            "ShaderParams.Fresnel Bias",
        };

        CYSWaterRenderHooks* sHooks = 0;

        String formatReal(Real v)
        {
            char buf[64];
            sprintf(buf, "%g", v);
            return buf;
        }

        bool setNamed(Ogre::GpuProgramParametersSharedPtr& params, const char* name, const Ogre::Vector4& value)
        {
            // CYS-LOGIN: the setter tries every ShaderParams constant on every water program; asking first keeps
            // OGRE from logging an exception per undeclared constant ("Cannot find a parameter named wavesSpeed" x18
            // on erengu_DL). Same result: an undeclared constant is skipped.
            if (!params->hasNamedConstant(name))
                return false;
            try
            {
                params->setNamedConstant(name, value);
                return true;
            }
            catch (const Ogre::Exception&)
            {
                return false;   // the program does not declare this constant
            }
        }
    }
    //-----------------------------------------------------------------------
    // CYS-WATER: defaults of CY 3.71 TerrainLiquidObject (Render.dll FUN_18011ccc0, floats at +0x208..+0x228: 0.6 0.6
    // 0.59 0.44 0.22 0.11 113.1 0.41 0.1 = the default_params of the water programs). Fog colour / density, uvScale and
    // wave speed follow the program defaults (FogColorDensity 1 1 1 0, UVScale 1 1, wavesSpeed 1; INF: the matching
    // constructor slots are 1.0).
    CYSWaterSettings::CYSWaterSettings(void)
        : showNewWater(false)
        , showMirrorReflectWater(false)
        , orientation(Ogre::Quaternion::IDENTITY)
        , scale(Ogre::Vector3::UNIT_SCALE)
        , meshLowLevelTextureScale(0)
        , textureDepth(0)
        , fogColour(1.0f, 1.0f, 1.0f, 1.0f)
        , fogDensity(0.0f)
        , uvScale(1.0f, 1.0f)
        , waveSpeed(1.0f, 0.0f)
        , bumpScaleX(0.6f)
        , bumpScaleZ(0.6f)
        , bigWavesScale(0.59f)
        , smallWavesScale(0.44f)
        , reflectionAmount(0.22f)
        , transparencyRatio(0.11f)
        , sunShinePow(113.1f)
        , sunMultiplier(0.41f)
        , fresnelBias(0.1f)
        , shaderParamMask(0)
    {
    }
    //-----------------------------------------------------------------------
    const char* CYSWaterSettings::getShaderParamName(int index)
    {
        return (index >= 0 && index < SP_COUNT) ? kShaderParamNames[index] : "";
    }
    //-----------------------------------------------------------------------
    bool CYSWaterSettings::setShaderParam(int index, const String& text)
    {
        const char* t = text.c_str();
        switch (index)
        {
        case SP_WATER_FOG_COLOR: fogColour = parseColour(t, fogColour); break;
        case SP_WATER_FOG_DENSITY: fogDensity = parseReal(t, fogDensity); break;
        case SP_UV_SCALE: uvScale = parseVector2(t, uvScale); break;
        case SP_WAVE_SPEED: waveSpeed = parseVector2(t, Ogre::Vector2(waveSpeed.x, 0)); break;
        case SP_BUMP_SCALE_X: bumpScaleX = parseReal(t, bumpScaleX); break;
        case SP_BUMP_SCALE_Z: bumpScaleZ = parseReal(t, bumpScaleZ); break;
        case SP_BIG_WAVES_SCALE: bigWavesScale = parseReal(t, bigWavesScale); break;
        case SP_SMALL_WAVES_SCALE: smallWavesScale = parseReal(t, smallWavesScale); break;
        case SP_REFLECTION_AMOUNT: reflectionAmount = parseReal(t, reflectionAmount); break;
        case SP_TRANSPARENCY_RATIO: transparencyRatio = parseReal(t, transparencyRatio); break;
        case SP_SUNSHINE_POW: sunShinePow = parseReal(t, sunShinePow); break;
        case SP_SUN_MULTIPLIER: sunMultiplier = parseReal(t, sunMultiplier); break;
        case SP_FRESNEL_BIAS: fresnelBias = parseReal(t, fresnelBias); break;
        default: return false;
        }
        shaderParamText[index] = text;
        shaderParamMask |= 1u << index;
        return true;
    }
    //-----------------------------------------------------------------------
    String CYSWaterSettings::getShaderParam(int index) const
    {
        if (index < 0 || index >= SP_COUNT)
            return String();
        if (shaderParamMask & (1u << index))
            return shaderParamText[index];
        return String();    // unset: the property default is "" so SceneSerializer::save omits it
    }
    //-----------------------------------------------------------------------
    void CYSScene::setWaterRenderHooks(CYSWaterRenderHooks* hooks)
    {
        sHooks = hooks;
    }
    //-----------------------------------------------------------------------
    CYSWaterRenderHooks* CYSScene::getWaterRenderHooks(void)
    {
        return sHooks;
    }
    //-----------------------------------------------------------------------
    bool CYSScene::isMaterialUsable(const String& name)
    {
        if (name.empty())
            return false;
        try
        {
            Ogre::MaterialPtr material = Ogre::MaterialManager::getSingleton().getByName(name);
            if (material.isNull())
                return false;
            material->load();
            return material->getBestTechnique() != 0;
        }
        catch (const Ogre::Exception&)
        {
            return false;
        }
    }
    //-----------------------------------------------------------------------
    String CYSScene::chooseWaterMaterial(const String& material, const CYSWaterSettings& settings, bool* replaced)
    {
        if (replaced)
            *replaced = false;
        const bool newWater = material.find("shader") != String::npos;
        // CYS-WATER: CY mesh water (FUN_1801219e0) renders only PBRScene_Water as new water; a "shader" material on a
        // mesh takes replaceMaterial.
        const bool newWaterAvailable = sHooks && sHooks->supportsNewWater() && settings.meshName.empty();
        const bool usable = isMaterialUsable(material);
        if (usable && (!newWater || newWaterAvailable || settings.replaceMaterial.empty()))
        {
            // CYS-PARITY (L2): Render.dll FUN_1801275e0 - with the INTZ scene depth a "shader*" / "PBRScene_Water*"
            // material becomes "<material>_DSIntZ" (water fog on 'content_type dsintz', PS 78f6952f)
            if (CysPostFxPipeline::intzSceneDepth() &&
                (material.find("shader") != String::npos || material.find("PBRScene_Water") != String::npos) &&
                isMaterialUsable(material + "_DSIntZ"))
                return material + "_DSIntZ";
            return material;
        }
        if (isMaterialUsable(settings.replaceMaterial))
        {
            if (replaced)
                *replaced = true;
            return settings.replaceMaterial;
        }
        return usable ? material : String();
    }
    //-----------------------------------------------------------------------
    bool CYSScene::materialHasPrograms(const Ogre::MaterialPtr& material)
    {
        if (material.isNull())
            return false;
        Ogre::Material::TechniqueIterator ti = const_cast<Ogre::Material*>(material.get())->getTechniqueIterator();
        while (ti.hasMoreElements())
        {
            Ogre::Technique::PassIterator pi = ti.getNext()->getPassIterator();
            while (pi.hasMoreElements())
            {
                Ogre::Pass* pass = pi.getNext();
                if (pass->hasVertexProgram() || pass->hasFragmentProgram())
                    return true;
            }
        }
        return false;
    }
    //-----------------------------------------------------------------------
    size_t CYSScene::applyWaterShaderParams(const Ogre::MaterialPtr& material, const CYSWaterSettings& s,
                                            Real textureRotate, Real textureScale)
    {
        if (material.isNull())
            return 0;
        size_t count = 0;
        const Ogre::Vector4 fogColorDensity(s.fogColour.r, s.fogColour.g, s.fogColour.b, s.fogDensity);
        Ogre::Material::TechniqueIterator ti = const_cast<Ogre::Material*>(material.get())->getTechniqueIterator();
        while (ti.hasMoreElements())
        {
            Ogre::Technique::PassIterator pi = ti.getNext()->getPassIterator();
            while (pi.hasMoreElements())
            {
                Ogre::Pass* pass = pi.getNext();
                for (int stage = 0; stage < 2; ++stage)
                {
                    const bool fragment = stage == 1;
                    if (fragment ? !pass->hasFragmentProgram() : !pass->hasVertexProgram())
                        continue;
                    Ogre::GpuProgramParametersSharedPtr params = fragment ? pass->getFragmentProgramParameters()
                                                                          : pass->getVertexProgramParameters();
                    if (params.isNull())
                        continue;
                    count += setNamed(params, "FogColorDensity", fogColorDensity);
                    count += setNamed(params, "BigWavesScale", Ogre::Vector4(s.bigWavesScale, 0, 0, 0));
                    count += setNamed(params, "SmallWavesScale", Ogre::Vector4(s.smallWavesScale, 0, 0, 0));
                    count += setNamed(params, "BumpScale", Ogre::Vector4(s.bumpScaleX, s.bumpScaleZ, 0, 0));
                    count += setNamed(params, "ReflectionAmount", Ogre::Vector4(s.reflectionAmount, 0, 0, 0));
                    count += setNamed(params, "TransparencyRatio", Ogre::Vector4(s.transparencyRatio, 0, 0, 0));
                    count += setNamed(params, "SunShinePow", Ogre::Vector4(s.sunShinePow, 0, 0, 0));
                    count += setNamed(params, "SunMultiplier", Ogre::Vector4(s.sunMultiplier, 0, 0, 0));
                    count += setNamed(params, "FresnelBias", Ogre::Vector4(s.fresnelBias, 0, 0, 0));
                    count += setNamed(params, "UVScale", Ogre::Vector4(s.uvScale.x, s.uvScale.y, 0, 0));
                    count += setNamed(params, "wavesSpeed", Ogre::Vector4(s.waveSpeed.x, 0, 0, 0));
                    count += setNamed(params, "texRotateScale", Ogre::Vector4(textureRotate, textureScale, 0, 0));
                    if (s.textureDepth > 0)
                        count += setNamed(params, "texDepthFactor", Ogre::Vector4(s.textureDepth, 0, 0, 0));
                }
            }
        }
        return count;
    }
    //-----------------------------------------------------------------------
    bool CYSScene::isNewWaterMaterial(const String& name)
    {
        return name.find("shader") != String::npos || name.find("PBRScene_Water") != String::npos;
    }
    //-----------------------------------------------------------------------
    // CYS-WATER: see CYSWater.h (CY FUN_1801ef510 looks the technique up by the name "WaterFog").
    bool CYSScene::getNewWaterTechniques(const Ogre::MaterialPtr& material, Ogre::Technique*& fog, Ogre::Technique*& surface)
    {
        fog = surface = 0;
        if (material.isNull() || !sHooks || !sHooks->supportsNewWater())
            return false;
        Ogre::Material* m = const_cast<Ogre::Material*>(material.get());
        const unsigned short count = m->getNumTechniques();
        for (unsigned short i = 0; i + 1 < count; ++i)
        {
            Ogre::Technique* t = m->getTechnique(i);
            if (t && t->getName() == "WaterFog")
            {
                Ogre::Technique* s = m->getTechnique(i + 1);
                if (t->isSupported() && s && s->isSupported() && t->getNumPasses() > 0 && s->getNumPasses() > 0)
                {
                    fog = t;
                    surface = s;
                    return true;
                }
                CYSScene::logOnce("water technique " + m->getName(),
                                  "New Water Material Error! Technique is NULL or unsupported! name: " + m->getName());
                return false;
            }
        }
        return false;
    }
    //-----------------------------------------------------------------------
    void CYSScene::applyTextureTiling(const Ogre::MaterialPtr& material, Real tiles)
    {
        if (material.isNull() || tiles <= 0)
            return;
        Ogre::Material::TechniqueIterator ti = material->getTechniqueIterator();
        while (ti.hasMoreElements())
        {
            Ogre::Technique::PassIterator pi = ti.getNext()->getPassIterator();
            while (pi.hasMoreElements())
            {
                Ogre::Pass::TextureUnitStateIterator ui = pi.getNext()->getTextureUnitStateIterator();
                while (ui.hasMoreElements())
                    ui.getNext()->setTextureScale(1.0f / tiles, 1.0f / tiles);
            }
        }
    }
}
