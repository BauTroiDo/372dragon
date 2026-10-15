// CY-Source (shadow agent): shadow-caster pass. See CYSShadowCasters.h.
#include "CYSShadowCasters.h"
#include "CYSShadowPrograms.h"
#include "../../Core/TerrainTileRenderable.h" // CYS-PARITY: terrain casters
#include <cstdlib>
#include <OgreCysPerf.h> // CYS-PERF-C3

#include <OgreEntity.h>
#include <OgreException.h>
#include <OgreHighLevelGpuProgram.h>
#include <OgreMaterial.h>
#include <OgreMaterialManager.h>
#include <OgreMesh.h>
#include <OgrePass.h>
#include <OgreStringConverter.h>
#include <OgreSubEntity.h>
#include <OgreTechnique.h>
#include <OgreTextureUnitState.h>

namespace WX
{
    const Ogre::String CYSShadowCasters::SCHEME = "CYSShadowCaster";

    namespace
    {
        // Skinning limits of ShaderLib/ParamNamedAuto.inc (FACT, 01-materials.md §3 P7)
        const size_t kMaxSkinBones = 74;
        const size_t kMaxQuatSkinBones = 105;

        /// Diffuse texture of a pass: the first named 2D unit, preferring sampler s0 (DiffuseSampler of Depth_PS).
        Ogre::TextureUnitState* diffuseUnit(Ogre::Pass* pass)
        {
            Ogre::TextureUnitState* first = 0;
            for (unsigned short i = 0; i < pass->getNumTextureUnitStates(); ++i)
            {
                Ogre::TextureUnitState* t = pass->getTextureUnitState(i);
                if (t->getContentType() != Ogre::TextureUnitState::CONTENT_NAMED || t->isBlank() ||
                    t->getTexUnitShaderType() == Ogre::TextureUnitState::TUST_VERTEX)
                    continue;
                if (t->getSamplerRegisterIndex() <= 0)
                    return t;
                if (!first)
                    first = t;
            }
            return first;
        }
    }

    //---------------------------------------------------------------------------------------------------------------
    CYSShadowCasters::CYSShadowCasters(void)
        : mProgramsOk(false)
        , mProgramSource("none")
        , mQueueMin(0)
        , mQueueMax(255)
        , mAlphaTest(true)
        , mCascade(0)
        , mSerial(0)
    {
        mPrograms.own = false;
        for (size_t i = 0; i < 4; ++i)
            mQueued[i] = 0;
    }
    //---------------------------------------------------------------------------------------------------------------
    CYSShadowCasters::~CYSShadowCasters()
    {
        // Ogre may be gone at static destruction time: shutdown() releases the materials while it is alive.
    }
    //---------------------------------------------------------------------------------------------------------------
    bool CYSShadowCasters::initialise(const Ogre::String& resourceGroup)
    {
        mGroup = resourceGroup;
        if (!mProgramsOk)
        {
            mProgramsOk = resolvePrograms();
            CYSShadowPrograms::log(mProgramsOk ? "caster programs: " + mProgramSource :
                "no caster programs (neither MaterialTemplates Depth_* nor CYSShadowCaster.hlsl): nothing casts");
        }
        return mProgramsOk;
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowCasters::shutdown(void)
    {
        mCache.clear();
        mShared.clear();
        if (Ogre::MaterialManager::getSingletonPtr())
        {
            for (size_t i = 0; i < mMaterials.size(); ++i)
                Ogre::MaterialManager::getSingleton().remove(mMaterials[i]);
        }
        mMaterials.clear();
        mProgramsOk = false;
        mProgramSource = "none";
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowCasters::clearCache(void)
    {
        mCache.clear();
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowCasters::setQueueRange(unsigned char minGroup, unsigned char maxGroup)
    {
        mQueueMin = minGroup;
        mQueueMax = maxGroup;
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowCasters::setAlphaTest(bool on)
    {
        if (mAlphaTest != on)
        {
            mAlphaTest = on;
            mCache.clear();
        }
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowCasters::beginUpdate(void)
    {
        mCascade = 0;
        for (size_t i = 0; i < 4; ++i)
            mQueued[i] = 0;
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowCasters::setCurrentCascade(size_t index)
    {
        mCascade = index < 4 ? index : 3;
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowCasters::logOnce(const Ogre::String& key, const Ogre::String& message)
    {
        if (mLogged.insert(std::make_pair(key, true)).second)
            CYSShadowPrograms::log(message);
    }
    //---------------------------------------------------------------------------------------------------------------
    bool CYSShadowCasters::resolvePrograms(void)
    {
        using namespace CYSShadowPrograms;

        // 1) client_GL MaterialTemplates.zip, Character.program (the "Depth" scheme programs of B)
        static const char* const bVs[SKIN_COUNT][2] = {
            { "Depth_NoTex_VS", "Depth_VS" },
            { "Depth_Skin_NoTex_VS", "Depth_Skin_VS" },
            { "Depth_DQSkin_NoTex_VS", "Depth_DQSkin_VS" },
        };
        static const char* const bFs[2] = { "Depth_NoTex_PS", "Depth_PS" };
        bool b = isUsable(bFs[0]) && isUsable(bFs[1]);
        for (int s = 0; s < SKIN_DQ && b; ++s)
            for (int t = 0; t < 2 && b; ++t)
                b = isUsable(bVs[s][t]);
        if (b)
        {
            for (int s = 0; s < SKIN_COUNT; ++s)
                for (int t = 0; t < 2; ++t)
                    mPrograms.vs[s][t] = (s < SKIN_DQ || isUsable(bVs[s][t])) ? bVs[s][t] : "";
            mPrograms.fs[0] = bFs[0];
            mPrograms.fs[1] = bFs[1];
            mPrograms.own = false;
            mProgramSource = "MaterialTemplates Depth_* (Character.program)";
            if (mPrograms.vs[SKIN_DQ][0].empty())
                mProgramSource += ", no dual-quaternion variant";
            return true;
        }

        // 2) CYSShadowCaster.hlsl from the media folder (static + linear skinning; no dual quaternion)
        const Ogre::String file = "CYSShadowCaster.hlsl";
        struct Decl { const char* name; const char* entry; const char* target; const char* defines; bool vertex; };
        static const Decl decls[] = {
            { "CYS/Shadow/Caster_NoTex_VS", "casterVS", "vs_3_0", "USE_TEXCOORD=0", true },
            { "CYS/Shadow/Caster_VS", "casterVS", "vs_3_0", "USE_TEXCOORD=1", true },
            { "CYS/Shadow/Caster_Skin_NoTex_VS", "casterVS", "vs_3_0", "USE_SKIN=1;USE_TEXCOORD=0", true },
            { "CYS/Shadow/Caster_Skin_VS", "casterVS", "vs_3_0", "USE_SKIN=1;USE_TEXCOORD=1", true },
            { "CYS/Shadow/Caster_NoTex_PS", "casterPS", "ps_3_0", "ALPHA_TEST=0", false },
            { "CYS/Shadow/Caster_PS", "casterPS", "ps_3_0", "ALPHA_TEST=1", false },
        };
        for (size_t i = 0; i < sizeof(decls) / sizeof(decls[0]); ++i)
        {
            Ogre::HighLevelGpuProgramPtr p = createHlsl(decls[i].name, mGroup, file, decls[i].entry, decls[i].target,
                decls[i].defines, decls[i].vertex ? Ogre::GPT_VERTEX_PROGRAM : Ogre::GPT_FRAGMENT_PROGRAM);
            if (p.isNull())
                return false;
            Ogre::GpuProgramParametersSharedPtr d = p->getDefaultParameters();
            if (decls[i].vertex)
            {
                setAuto(d, "world_matrix", Ogre::GpuProgramParameters::ACT_WORLD_MATRIX);
                setAuto(d, "view_matrix", Ogre::GpuProgramParameters::ACT_VIEW_MATRIX);
                setAuto(d, "projection_matrix", Ogre::GpuProgramParameters::ACT_PROJECTION_MATRIX);
                if (!setAuto(d, "world_matrix_array_3x4[0]", Ogre::GpuProgramParameters::ACT_WORLD_MATRIX_ARRAY_3x4))
                    setAuto(d, "world_matrix_array_3x4", Ogre::GpuProgramParameters::ACT_WORLD_MATRIX_ARRAY_3x4);
                setAuto(d, "imodel_userdata", Ogre::GpuProgramParameters::ACT_IMODEL_USERDATA);
                if (std::string(decls[i].defines).find("USE_SKIN=1") != std::string::npos)
                    p->setSkeletalAnimationIncluded(true);
            }
        }
        mPrograms.vs[SKIN_NONE][0] = decls[0].name;
        mPrograms.vs[SKIN_NONE][1] = decls[1].name;
        mPrograms.vs[SKIN_LBS][0] = decls[2].name;
        mPrograms.vs[SKIN_LBS][1] = decls[3].name;
        mPrograms.vs[SKIN_DQ][0] = mPrograms.vs[SKIN_DQ][1] = "";
        mPrograms.fs[0] = decls[4].name;
        mPrograms.fs[1] = decls[5].name;
        mPrograms.own = true;
        mProgramSource = "CYSShadowCaster.hlsl (MaterialTemplates Depth_* unavailable)";
        return true;
    }
    //---------------------------------------------------------------------------------------------------------------
    bool CYSShadowCasters::renderableQueued(Ogre::Renderable* rend, Ogre::uint8 groupID, Ogre::ushort priority,
                                            Ogre::Technique** ppTech)
    {
        (void)priority;
        if (groupID < mQueueMin || groupID > mQueueMax || !ppTech || !*ppTech)
            return false;
        // CYS-PARITY (d3d9-trace): terrain tiles cast like CY 3.71. FACT (d3d9 trace, Dali w09/w28/w42 and erengu_DL):
        // after the entity casters CY draws 40-44 (login 26) terrain tiles into the 4096 R32F map with the terrain
        // material's "Depth" scheme technique (VS 9beba414 $WorldViewXf/$WvpXf, PS c46a8a36 = CartoonEffect/PS/
        // DrawDepth_NoTex writing view depth, $specialFlag 1.5), cull CW, no depth bias. CYS_PARITY_TERRAIN_CAST=0: off.
        if (dynamic_cast<TerrainTileRenderable*>(rend))
        {
            static const bool terrainCast = []() {
                const char* v = getenv("CYS_PARITY_TERRAIN_CAST");
                return !(v && v[0] == '0');
            }();
            Ogre::Material* mat = terrainCast ? (*ppTech)->getParent() : 0;
            if (!mat)
                return false;
            Ogre::Technique* depth = 0;
            for (unsigned short t = 0; t < mat->getNumTechniques() && !depth; ++t)
            {
                Ogre::Technique* tech = mat->getTechnique(t);
                if (tech->getSchemeName() == "Depth" && tech->isSupported() && tech->getNumPasses() > 0)
                    depth = tech;
            }
            if (!depth)
            {
                logOnce("terrain-depth:" + mat->getName(), "terrain material " + mat->getName() +
                        " has no supported Depth technique: its tiles do not cast");
                return false;
            }
            *ppTech = depth;
            ++mQueued[mCascade];
            return true;
        }
        // Only entities cast otherwise: particles, billboards, ribbons, sky and overlays are other renderables.
        Ogre::SubEntity* se = dynamic_cast<Ogre::SubEntity*>(rend);
        if (!se)
            return false;
        Ogre::Entity* ent = se->getParent();
        if (!ent || !ent->getCastShadows())
            return false;
        Ogre::Technique* src = *ppTech;
        if (src->getSchemeName() == SCHEME)
        {
            ++mQueued[mCascade]; // the material's own caster technique
            return true;
        }
        Ogre::Technique* caster = 0;
        try
        {
            caster = casterFor(src, ent, se);
        }
        catch (Ogre::Exception& e)
        {
            logOnce("exc:" + src->getParent()->getName(), "caster for material " + src->getParent()->getName() +
                    " failed: " + e.getDescription());
            caster = 0;
        }
        if (!caster)
            return false;
        *ppTech = caster;
        ++mQueued[mCascade];
        return true;
    }
    //---------------------------------------------------------------------------------------------------------------
    Ogre::Technique* CYSShadowCasters::casterFor(Ogre::Technique* src, Ogre::Entity* ent, Ogre::SubEntity* se)
    {
        Ogre::Pass* pass = src->getNumPasses() ? src->getPass(0) : 0;
        if (!pass || !mProgramsOk)
            return 0;

        // Vertex data the caster receives: blended by the GPU (skinning variant) or already blended / static.
        int skin = SKIN_NONE;
        bool tooManyBones = false;
        if (ent->hasSkeleton() && ent->isHardwareAnimationEnabled())
        {
            const size_t bones = se->getNumWorldTransforms();
            skin = (pass->hasVertexProgram() &&
                    CYSShadowPrograms::hasDefine(pass->getVertexProgramName(), "USE_QUAT_SKIN")) ? SKIN_DQ : SKIN_LBS;
            if (skin == SKIN_LBS && bones > kMaxSkinBones)
                skin = SKIN_DQ;
            tooManyBones = skin == SKIN_DQ && bones > kMaxQuatSkinBones;
        }

        const std::pair<Ogre::Technique*, int> key(src, skin);
        const Ogre::Material* mat = src->getParent();
        const Ogre::ResourceHandle handle = mat ? mat->getHandle() : 0;
        CacheMap::iterator it = mCache.find(key);
        if (it != mCache.end() && it->second.material == handle)
            return it->second.caster;

        Ogre::CysPerf::CountScope cysPerfCaster(Ogre::CysPerf::C_CASTER_BUILD, Ogre::CysPerf::C_CASTER_US); // CYS-PERF-C3
        Ogre::Technique* caster = 0;
        if (tooManyBones)
        {
            logOnce("bones:" + ent->getMesh()->getName(), "mesh " + ent->getMesh()->getName() +
                    " has more bones per sub-mesh than the skinning shaders allow; it does not cast");
        }
        else
        {
            // Opaque or alpha-rejected passes that write depth cast; blended effects and glass do not.
            const bool rejects = pass->getAlphaRejectFunction() != Ogre::CMPF_ALWAYS_PASS;
            const bool casts = pass->getDepthCheckEnabled() && (pass->getDepthWriteEnabled() || rejects) &&
                               (!pass->isTransparent() || rejects);
            if (casts)
                caster = buildCaster(pass, skin, rejects && mAlphaTest && diffuseUnit(pass) != 0);
        }
        Entry e;
        e.material = handle;
        e.caster = caster;
        mCache[key] = e;
        return caster;
    }
    //---------------------------------------------------------------------------------------------------------------
    Ogre::Technique* CYSShadowCasters::buildCaster(Ogre::Pass* src, int skin, bool alpha)
    {
        const Ogre::String& vs = mPrograms.vs[skin][alpha ? 1 : 0];
        const Ogre::String& fs = mPrograms.fs[alpha ? 1 : 0];
        if (vs.empty() || fs.empty())
        {
            logOnce("skin:" + Ogre::StringConverter::toString(skin), "no caster vertex program for skin mode " +
                    Ogre::StringConverter::toString(skin) + "; such entities do not cast");
            return 0;
        }
        Ogre::TextureUnitState* unit = alpha ? diffuseUnit(src) : 0;
        const unsigned char ref = unit ? src->getAlphaRejectValue() : 0;
        const Ogre::CullingMode cull = src->getCullingMode();

        // One caster technique per state; many source passes share it.
        Ogre::String key = vs + "|" + fs + "|" + Ogre::StringConverter::toString(int(cull));
        if (unit)
        {
            const Ogre::TextureUnitState::UVWAddressingMode& am = unit->getTextureAddressingMode();
            key += "|" + unit->getTextureName() + "|" + Ogre::StringConverter::toString(int(ref)) + "|" +
                   Ogre::StringConverter::toString(int(am.u)) + Ogre::StringConverter::toString(int(am.v));
        }
        SharedMap::iterator it = mShared.find(key);
        if (it != mShared.end())
            return it->second;

        Ogre::MaterialManager& mm = Ogre::MaterialManager::getSingleton();
        Ogre::String name;
        do
        {
            name = "CYS/ShadowCaster/" + Ogre::StringConverter::toString(mSerial++);
        } while (!mm.getByName(name).isNull());
        Ogre::MaterialPtr mat = mm.create(name, mGroup);
        Ogre::Technique* tech = mat->getNumTechniques() ? mat->getTechnique(0) : mat->createTechnique();
        Ogre::Pass* p = tech->getNumPasses() ? tech->getPass(0) : tech->createPass();
        p->setLightingEnabled(false);
        p->setFog(true, Ogre::FOG_NONE);
        p->setDepthCheckEnabled(true);
        p->setDepthWriteEnabled(true);
        p->setDepthFunction(Ogre::CMPF_LESS_EQUAL);
        p->setCullingMode(cull);
        p->setManualCullingMode(Ogre::MANUAL_CULL_NONE);
        p->setSceneBlending(Ogre::SBF_ONE, Ogre::SBF_ZERO);
        p->setVertexProgram(vs);
        p->setFragmentProgram(fs);
        if (unit)
        {
            Ogre::TextureUnitState* t = p->createTextureUnitState(unit->getTextureName());
            t->setTextureAddressingMode(unit->getTextureAddressingMode());
            t->setTextureFiltering(Ogre::TFO_BILINEAR);
            // B's Depth_PS clips at imodel_userdata.z = alpha reject value / 256 of the pass being drawn;
            // ALWAYS_PASS keeps the fixed-function alpha test off on the float target.
            p->setAlphaRejectSettings(Ogre::CMPF_ALWAYS_PASS, ref);
            if (mPrograms.own)
                CYSShadowPrograms::setConstant(p->getFragmentProgramParameters(), "alphaRef", Ogre::Real(ref) / 255.0f);
        }
        try
        {
            mat->load();
        }
        catch (Ogre::Exception& e)
        {
            CYSShadowPrograms::log("caster material " + name + " failed to load: " + e.getDescription());
        }
        if (!mat->getNumSupportedTechniques())
        {
            logOnce("unsupported:" + key, "caster material " + name + " (" + key + ") is not supported");
            mm.remove(mat->getHandle());
            mShared[key] = 0;
            return 0;
        }
        mMaterials.push_back(name);
        mShared[key] = tech;
        return tech;
    }
}
