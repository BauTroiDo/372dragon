// CY-Source: runtime material system of the B/Fairy renderer. See CysMaterialSystem.h.
// CYS: new file (2026-09-12). Written from Docs\specs\render\01-materials.md; the rules that are
// not FACT in the spec are marked INF in the comments.
#include "CysMaterialSystem.h"
#include <OgreCysPerf.h> // CYS-PERF-C3

#include <OgreEntity.h>
#include <OgreException.h>
#include <OgreRoot.h> // CYS fx-render: frame counter of the once-per-frame source check
#include <OgreGpuProgramManager.h>
#include <OgreHardwareBufferManager.h>
#include <OgreHighLevelGpuProgramManager.h>
#include <OgreImage.h>
#include <OgreLogManager.h>
#include <OgreMaterial.h>
#include <OgreMesh.h>
#include <OgrePass.h>
#include <OgreStringConverter.h>
#include <OgreSubEntity.h>
#include <OgreSubMesh.h>
#include <OgreTechnique.h>
#include <OgreTextureManager.h>
#include <OgreTextureUnitState.h>
#include <OgreVector2.h>
#include <OgreVector3.h>

#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#include <algorithm>
#include <cstdio>
#include <cstring>  // CYS fx-render: memcmp / memcpy of followed constants
#include <intrin.h> // CYS fx-render: __rdtsc for the render-queue hook statistics
#include <set>
#include <sstream>

using namespace Ogre;

namespace CYS
{
    namespace
    {


        const InstanceParamInfo kInstanceParams[] = {
            { "tex0BlendColor", 4, { 0, 0, 0, 0 } },
            { "multiBlendColor", 4, { 1, 1, 1, 1 } },
            { "flowFactor", 4, { 1, 1, 1, 1 } },
            { "D0UV_params", 4, { 1, 1, 0, 0 } },
            { "D1UV_params", 4, { 1, 1, 0, 0 } },
            { "D2UV_params", 4, { 1, 1, 0, 0 } },
            { "DN_params", 4, { 1, 1, 0, 0 } },
            { "outlinePow", 2, { 0, 0, 0, 0 } },
            { "outlineColor", 4, { 1, 1, 0, 1 } },
            { "spec_params", 4, { 1, 1, 1, 1 } },
            { "dissolveClip", 1, { 0, 0, 0, 0 } },
            { "dissolveColorA", 4, { 0, 0, 0, 1 } },
            { "dissolveColorB", 4, { 1, 1, 1, 1 } },
            { "dissolveUVRepeat", 2, { 1, 1, 0, 0 } },
            { "dissolveParams", 4, { 0.05f, 0.005f, 0.02f, 0.01f } },
            { "dissolveSoftEdgeWidth", 1, { 0, 0, 0, 0 } },
            { "dissolveEdgeLighting", 1, { 0, 0, 0, 0 } },
            { "dissolveFlowSpeed", 1, { 0, 0, 0, 0 } },
            { "dissolveEdgeContrast", 1, { 0, 0, 0, 0 } },
            { "dissolveEdgeRange", 1, { 0, 0, 0, 0 } },
            { "dissolveEdgeColor", 4, { 0, 0, 0, 1 } },
            { "dissolveDirection", 3, { 0, 0, 0, 0 } },
            { "dissolveReverse", 1, { 0, 0, 0, 0 } },
            { "dissolveTime", 1, { 0, 0, 0, 0 } },
            { "dissolveMinProj", 1, { 0, 0, 0, 0 } },
            { "dissolveMaxProj", 1, { 0, 0, 0, 0 } },
            // CYS fx-render: CY 3.71 (C / DataCY) only - object-space box of the directional model dissolve
            // (DISSOLVE_EFFECT 5, C ShaderLib/TexKill.inc + ParamNamed.inc default; C Render.dll string 0x2e9370)
            { "dissolveBox", 4, { 0, 1, 0, 1 } },
            { "rimTintColor", 4, { 1, 0.8f, 0.25f, 1 } },
            { "starsTexDistortion_rimPow_rimClampMin_rimClampMax", 4, { 0.05f, 1.17f, 0.1f, 0.93f } },
            { "rimFlowFactor", 4, { 1, 1, 1, 0.1f } },
            { "starsTexScaleFactor", 1, { 0.002f, 0, 0, 0 } },
            { "texRotateScale", 2, { 0, 0, 0, 0 } },
            { "texDepthFactor", 1, { 0, 0, 0, 0 } },
            { "wavesSpeed", 1, { 0, 0, 0, 0 } },
            { "FogColorDensity", 4, { 0, 0, 0, 0 } },
            { "BigWavesScale", 1, { 0, 0, 0, 0 } },
            { "SmallWavesScale", 1, { 0, 0, 0, 0 } },
            { "BumpScale", 2, { 0, 0, 0, 0 } },
            { "ReflectionAmount", 1, { 0, 0, 0, 0 } },
            { "TransparencyRatio", 1, { 0, 0, 0, 0 } },
            { "SunShinePow", 1, { 0, 0, 0, 0 } },
            { "SunMultiplier", 1, { 0, 0, 0, 0 } },
            { "FresnelBias", 1, { 0, 0, 0, 0 } },
            { "UVScale", 2, { 0, 0, 0, 0 } },
            { "heightParams", 2, { 1, 0, 0, 0 } },
            { "L0UV_params", 4, { 1, 1, 0, 0 } },
            { "L1UV_params", 4, { 1, 1, 0, 0 } },
            { "L2UV_params", 4, { 1, 1, 0, 0 } },
            { "LN_params", 4, { 1, 1, 1, 0 } },
            { "lightParams", 4, { 1, 1, 1, 0.5f } },
            { "useRibbon", 1, { 0, 0, 0, 0 } },
            { "widthRatio", 1, { 0, 0, 0, 0 } },
            { "useUDirection", 1, { 0, 0, 0, 0 } },
            { "blocks", 2, { 1, 1, 0, 0 } },
            { "sequenceFrameUVFactor", 4, { 0, 1, 0, 1 } },
        };

        // Skinning limits of ShaderLib/ParamNamedAuto.inc (FACT)
        const size_t kMaxSkinBones = 74;
        const size_t kMaxQuatSkinBones = 105;

        void logMsg(const String& s)
        {
            LogManager::getSingleton().logMessage("CYS material: " + s);
        }

        String trim(const String& s)
        {
            String r = s;
            StringUtil::trim(r);
            return r;
        }

        String lower(const String& s)
        {
            String r = s;
            StringUtil::toLowerCase(r);
            return r;
        }

        /// "A=1;B=2;C" (also ',' separated) -> map; a bare name means "1" (as D3D9HLSLProgram)
        std::map<String, String> parseDefines(const String& s)
        {
            std::map<String, String> m;
            size_t p = 0;
            while (p < s.size())
            {
                size_t q = s.find_first_of(";,", p);
                String item = trim(s.substr(p, q == String::npos ? String::npos : q - p));
                if (!item.empty())
                {
                    size_t eq = item.find('=');
                    if (eq == String::npos)
                        m[item] = "1";
                    else
                        m[trim(item.substr(0, eq))] = trim(item.substr(eq + 1));
                }
                if (q == String::npos)
                    break;
                p = q + 1;
            }
            return m;
        }

        String joinDefines(const std::map<String, String>& m)
        {
            String out;
            for (std::map<String, String>::const_iterator it = m.begin(); it != m.end(); ++it)
            {
                if (!out.empty())
                    out += ";";
                out += it->first + "=" + it->second;
            }
            return out;
        }

        HighLevelGpuProgramPtr getHighLevel(const String& name)
        {
            if (name.empty())
                return HighLevelGpuProgramPtr();
            ResourcePtr r = HighLevelGpuProgramManager::getSingleton().getByName(name);
            if (r.isNull())
                return HighLevelGpuProgramPtr();
            return HighLevelGpuProgramPtr(r);
        }

        /** A fixed-function pass the Model_* ubershaders can render. FACT: Render.dll registers the
            macro slots BLEND_OP_0/1, DIFFUSE_1/2_ENABLE, TEX_EFFECT_0/1, SPHEREMAPPING_ENABLE,
            ALPHATEST_ENABLE (Docs\specs\render\01-materials.md P3); the templates implement them in
            ShaderLib/Diffuse.inc, CalcUV.inc, EnvMap.inc, TexKill.inc. INF: the mapping from the
            OGRE pass state in analyseFixedFunction. */
        struct FixedFunctionInfo
        {
            int diffuse[2];                   ///< texture units of the colour layers (-1 = none)
            int sphere;                       ///< spherical environment map unit (-1 = none)
            String base;                      ///< template pixel shader the variant derives from
            std::map<String, String> defines; ///< macros on top of the base program
        };
        bool analyseFixedFunction(Pass* pass, FixedFunctionInfo& info); // defined below

        String defineOf(const HighLevelGpuProgramPtr& p, const String& name)
        {
            std::map<String, String> m = parseDefines(p->getParameter("preprocessor_defines"));
            std::map<String, String>::const_iterator it = m.find(name);
            return it == m.end() ? StringUtil::BLANK : it->second;
        }

        /// CYS fx-render: CYS_MATSYS_FOLLOW=0 turns the source -> variant following off (A/B comparisons)
        bool followEnabled(void)
        {
            static int enabled = -1;
            if (enabled < 0)
            {
                char value[8] = { 0 };
                const DWORD n = GetEnvironmentVariableA("CYS_MATSYS_FOLLOW", value, sizeof(value));
                enabled = (n > 0 && n < sizeof(value) && value[0] == '0') ? 0 : 1;
                if (!enabled)
                    LogManager::getSingleton().logMessage("CYS material: CYS_MATSYS_FOLLOW=0 - run-time source "
                        "changes are NOT followed onto variants (A/B diagnostic)");
            }
            return enabled == 1;
        }

        /// CYS fx-render: CYS_MATSYS_MESH_VS=particle pairs particle pixel shaders on meshes with Particle_VS again
        /// (the pairing before 13/09 evening) for A/B comparisons; default = Model[_Skin]_VS as in B
        bool meshParticleModelVs(void)
        {
            static int enabled = -1;
            if (enabled < 0)
            {
                char value[16] = { 0 };
                const DWORD n = GetEnvironmentVariableA("CYS_MATSYS_MESH_VS", value, sizeof(value));
                enabled = (n > 0 && n < sizeof(value) && (value[0] == 'p' || value[0] == 'P')) ? 0 : 1;
                if (!enabled)
                    LogManager::getSingleton().logMessage("CYS material: CYS_MATSYS_MESH_VS=particle - particle pixel "
                        "shaders on meshes use Particle_VS (A/B diagnostic)");
            }
            return enabled == 1;
        }

        String exeDirectory()
        {
            char buf[MAX_PATH];
            DWORD n = GetModuleFileNameA(NULL, buf, MAX_PATH);
            String p(buf, n);
            size_t s = p.find_last_of("\\/");
            return s == String::npos ? String(".") : p.substr(0, s);
        }

        /// 64-bit FNV-1a of a file + its size, as hex ("" if unreadable)
        String fileStamp(const String& path)
        {
            HANDLE h = CreateFileA(path.c_str(), GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING,
                FILE_ATTRIBUTE_NORMAL, NULL);
            if (h == INVALID_HANDLE_VALUE)
                return StringUtil::BLANK;
            unsigned long long hash = 0xcbf29ce484222325ULL, total = 0;
            std::vector<unsigned char> buf(1 << 16);
            DWORD got = 0;
            while (ReadFile(h, &buf[0], (DWORD)buf.size(), &got, NULL) && got)
            {
                for (DWORD i = 0; i < got; ++i)
                    hash = (hash ^ buf[i]) * 0x100000001b3ULL;
                total += got;
            }
            CloseHandle(h);
            char s[64];
            std::sprintf(s, "%016llx-%llu", hash, total);
            return s;
        }
    }

    //----------------------------------------------------------------------------------------------
    MaterialSystem& MaterialSystem::getSingleton(void)
    {
        static MaterialSystem instance;
        return instance;
    }
    //----------------------------------------------------------------------------------------------
    MaterialSystem::MaterialSystem()
        : mInstalled(false), mVariantsEnabled(true), mAllowQuatSkin(true), mConvertFixedFunction(true),
          mShadowReceiverLighting(true), // CYS-SHADOW
          mBuildingActorVariant(false),  // CYS-PARITY
          mNextPurge(1024), mNextTechniquePurge(4096), mStatResolveCalls(0), mStatResolveTicks(0),
          mStatHitCalls(0), mStatHitTicks(0), mStatFollowed(0), mStatPurged(0), mStatChecks(0),
          mFrameCounter(*this), mFrame(0), mFrameEvents(false), mFrameListenerAdded(false),
          mStatVariantPrograms(0), mStatVariantMaterials(0), mStatEntities(0), mStatTangentSets(0),
          mStatFallbacks(0), mStatEngineUnits(0), mStatFFPasses(0), mStatDroppedPasses(0)
    {
        // CYS-SHADOW: CYS_SHADOW_PROMOTE=0 keeps the receivers as authored (A/B comparisons)
        char value[8] = { 0 };
        const DWORD n = GetEnvironmentVariableA("CYS_SHADOW_PROMOTE", value, sizeof(value));
        if (n > 0 && n < sizeof(value) && value[0] == '0')
            mShadowReceiverLighting = false;
    }
    //----------------------------------------------------------------------------------------------
    void MaterialSystem::install(const String& cacheDir, const String& materialTemplatesZip)
    {
        MaterialManager::getSingleton().setVariantResolver(this);
        mInstalled = true;
        logMsg("runtime shader variants installed (vertex program pairing, skin <= " +
            StringConverter::toString(kMaxSkinBones) + " bones, quaternion skin <= " +
            StringConverter::toString(kMaxQuatSkinBones) + ")");
        if (cacheDir.empty())
            return;
        CreateDirectoryA(cacheDir.c_str(), NULL);
        if (GetFileAttributesA((cacheDir + "\\DISABLED").c_str()) != INVALID_FILE_ATTRIBUTES)
        {
            logMsg("shader cache disabled (" + cacheDir + "\\DISABLED exists)");
            GpuProgramManager::setMicrocodeCacheDirectory(StringUtil::BLANK);
            return;
        }
        // B resets .\ShaderCache when MaterialTemplates.zip changes (NewMaterialTemplateMD5)
        String zip = materialTemplatesZip;
        if (zip.empty())
        {
            const String dir = exeDirectory();
            const char* const rel[] = { "\\..\\Data\\MaterialTemplates.zip", "\\Data\\MaterialTemplates.zip" };
            for (size_t i = 0; i < 2 && zip.empty(); ++i)
                if (GetFileAttributesA((dir + rel[i]).c_str()) != INVALID_FILE_ATTRIBUTES)
                    zip = dir + rel[i];
        }
        const String stamp = "MaterialTemplates " + (zip.empty() ? String("none") : fileStamp(zip));
        const String stampFile = cacheDir + "\\stamp.txt";
        String old;
        {
            FILE* f = std::fopen(stampFile.c_str(), "rb");
            if (f)
            {
                char buf[256] = { 0 };
                size_t n = std::fread(buf, 1, sizeof(buf) - 1, f);
                std::fclose(f);
                old = trim(String(buf, n));
            }
        }
        if (old != stamp)
        {
            size_t removed = 0;
            WIN32_FIND_DATAA fd;
            HANDLE h = FindFirstFileA((cacheDir + "\\*.bin").c_str(), &fd);
            if (h != INVALID_HANDLE_VALUE)
            {
                do
                {
                    if (DeleteFileA((cacheDir + "\\" + fd.cFileName).c_str()))
                        ++removed;
                } while (FindNextFileA(h, &fd));
                FindClose(h);
            }
            FILE* f = std::fopen(stampFile.c_str(), "wb");
            if (f)
            {
                std::fputs(stamp.c_str(), f);
                std::fclose(f);
            }
            logMsg("shader cache reset (" + StringConverter::toString(removed) + " entries), " + stamp);
        }
        GpuProgramManager::setMicrocodeCacheDirectory(cacheDir);
        logMsg("shader cache: " + cacheDir);
    }
    //----------------------------------------------------------------------------------------------
    void MaterialSystem::uninstall(void)
    {
        if (mInstalled && MaterialManager::getSingletonPtr() &&
            MaterialManager::getSingleton().getVariantResolver() == this)
            MaterialManager::getSingleton().setVariantResolver(0);
        if (mFrameListenerAdded && Root::getSingletonPtr())
            Root::getSingleton().removeFrameListener(&mFrameCounter); // CYS fx-render
        mFrameListenerAdded = false;
        mFrameEvents = false;
        mInstalled = false;
        mMaterialCache.clear();
        mTechniqueCache.clear();
        mInstanceMaterials.clear();
    }
    //----------------------------------------------------------------------------------------------
    void MaterialSystem::setGlobalDefine(const String& name, const String& value)
    {
        if (value.empty())
            mGlobalDefines.erase(name);
        else
            mGlobalDefines[name] = value;
        // new state for materials resolved from now on
        mMaterialCache.clear();
        mTechniqueCache.clear();
    }
    //----------------------------------------------------------------------------------------------
    // CYS-SHADOW: shadow receivers (see the header)
    void MaterialSystem::setShadowReceiverLighting(bool on)
    {
        if (mShadowReceiverLighting == on)
            return;
        mShadowReceiverLighting = on;
        mMaterialCache.clear();
        mTechniqueCache.clear();
    }
    //----------------------------------------------------------------------------------------------
    bool MaterialSystem::isTerrainShadowPass(const Pass* pass) const
    {
        if (!mShadowReceiverLighting || !pass->hasFragmentProgram() || !pass->hasVertexProgram())
            return false;
        DefineMap::const_iterator g = mGlobalDefines.find("SHADOWMAP_TYPE");
        if (g == mGlobalDefines.end() || (g->second != "1" && g->second != "2"))
            return false;
        HighLevelGpuProgramPtr fp = getHighLevel(pass->getFragmentProgramName());
        HighLevelGpuProgramPtr vp = getHighLevel(pass->getVertexProgramName());
        if (fp.isNull() || vp.isNull() || lower(fp->getSourceFile()) != "fairyterraincolormap.hlsl" ||
            lower(vp->getSourceFile()) != "fairyterraincolormap.hlsl")
            return false;
        return defineOf(fp, "LIGHT_CALC_TYPE").empty() && defineOf(fp, "SHADOWMAP_TYPE").empty();
    }
    //----------------------------------------------------------------------------------------------
    bool MaterialSystem::promotesToPixelLighting(const HighLevelGpuProgramPtr& fp) const
    {
        if (!mShadowReceiverLighting || fp.isNull() || mBuildingActorVariant) // CYS-PARITY: actors never receive
            return false;
        DefineMap::const_iterator g = mGlobalDefines.find("SHADOWMAP_TYPE");
        if (g == mGlobalDefines.end() || (g->second != "1" && g->second != "2"))
            return false;
        if (classify(fp) != FAMILY_MODEL)
            return false;



        const String lc = defineOf(fp, "LIGHT_CALC_TYPE");
        return lc != "0" && lc != "2";
    }
    //----------------------------------------------------------------------------------------------
    size_t MaterialSystem::getInstanceParamCount(void)
    {
        return sizeof(kInstanceParams) / sizeof(kInstanceParams[0]);
    }
    //----------------------------------------------------------------------------------------------
    const InstanceParamInfo& MaterialSystem::getInstanceParam(size_t i)
    {
        return kInstanceParams[i];
    }
    //----------------------------------------------------------------------------------------------
    const InstanceParamInfo* MaterialSystem::findInstanceParam(const String& name)
    {
        for (size_t i = 0; i < getInstanceParamCount(); ++i)
            if (name == kInstanceParams[i].name)
                return &kInstanceParams[i];
        return 0;
    }
    //----------------------------------------------------------------------------------------------
    MaterialSystem::Family MaterialSystem::classify(const HighLevelGpuProgramPtr& fp) const
    {
        // Families of MaterialTemplates pixel shaders by source file (FACT: Character.program /
        // Particle.program declare one vertex program family per source).
        const String src = lower(fp->getSourceFile());
        if (src == "depth_ps.hlsl")
            return FAMILY_DEPTH;
        if (src.compare(0, 8, "particle") == 0)
            return FAMILY_PARTICLE;
        // CYS-PARITY (d3d9-trace): the FakeLight light box shader is a screen-space pass, not a lit model; CY 3.71
        // draws it without receiver/LUT macros (trace: PS constants far/near clip, globalIntensity,
        // inverse_worldview_matrix_3x4, lightParams, viewport_size only). A variant here also dropped globalIntensity.
        if (src == "model_fakepointlight_ps.hlsl")
            return FAMILY_UNKNOWN;
        if (src.compare(0, 6, "model_") == 0)
            return FAMILY_MODEL;
        return FAMILY_UNKNOWN;
    }
    //----------------------------------------------------------------------------------------------
    bool MaterialSystem::needsVertexProgram(const MaterialPtr& mat) const
    {
        for (unsigned short t = 0; t < mat->getNumTechniques(); ++t)
        {
            Technique* tech = mat->getTechnique(t);
            for (unsigned short p = 0; p < tech->getNumPasses(); ++p)
            {
                Pass* pass = tech->getPass(p);
                if (pass->hasFragmentProgram() && !pass->hasVertexProgram())
                    return true;
            }
        }
        return false;
    }
    //----------------------------------------------------------------------------------------------
    bool MaterialSystem::needsTangents(const MaterialPtr& mat) const
    {
        Technique* tech = mat->getBestTechnique();
        if (!tech)
            return false;
        for (unsigned short p = 0; p < tech->getNumPasses(); ++p)
        {
            Pass* pass = tech->getPass(p);
            if (!pass->hasFragmentProgram() || pass->hasVertexProgram())
                continue;
            HighLevelGpuProgramPtr fp = getHighLevel(pass->getFragmentProgramName());
            if (!fp.isNull() && defineOf(fp, "USE_TANGENT") == "1")
                return true;
        }
        return false;
    }
    //----------------------------------------------------------------------------------------------
    void MaterialSystem::resolveEntity(Entity* ent)
    {
        if (!mVariantsEnabled)
            return;
        const unsigned int count = ent->getNumSubEntities();
        if (!count)
            return;
        // Entity::buildSubEntityList assigns materials one by one; resolve once all are assigned.
        for (unsigned int i = 0; i < count; ++i)
            if (ent->getSubEntity(i)->getSourceMaterial().isNull())
                return;

        MeshPtr mesh = ent->getMesh();
        const bool hasSkeleton = ent->hasSkeleton();
        size_t maxBones = 0;
        bool skinnable = hasSkeleton;
        bool explicitSkinProgram = false;
        for (unsigned int i = 0; i < count; ++i)
        {
            SubEntity* se = ent->getSubEntity(i);
            SubMesh* sm = se->getSubMesh();
            const Mesh::IndexMap& im = sm->useSharedVertices ?
                mesh->sharedBlendIndexToBoneIndexMap : sm->blendIndexToBoneIndexMap;
            maxBones = std::max(maxBones, im.size());
            Technique* tech = se->getSourceMaterial()->getBestTechnique();
            if (!tech)
            {
                skinnable = false;
                continue;
            }
            for (unsigned short p = 0; p < tech->getNumPasses(); ++p)
            {
                Pass* pass = tech->getPass(p);
                if (pass->hasVertexProgram())
                {
                    if (pass->getVertexProgram()->isSkeletalAnimationIncluded())
                        explicitSkinProgram = true;
                    else
                        skinnable = false; // a static vertex program: software skinning (as OGRE)
                }
                else if (pass->hasFragmentProgram())
                {
                    HighLevelGpuProgramPtr fp = getHighLevel(pass->getFragmentProgramName());
                    Family fam = fp.isNull() ? FAMILY_UNKNOWN : classify(fp);
                    // CYS fx-render: particle pixel shaders on meshes take Model[_Skin]_VS (pickVertexProgram)
                    if (fam != FAMILY_MODEL && fam != FAMILY_DEPTH && !(fam == FAMILY_PARTICLE && meshParticleModelVs()))
                        skinnable = false;
                }
                else
                {
                    // fixed-function pass: software skinning, unless the ubershader takes it over
                    FixedFunctionInfo info;
                    if (!(mConvertFixedFunction && analyseFixedFunction(pass, info)))
                        skinnable = false;
                }
            }
        }
        // INF: B's exact choice between the linear and the quaternion variant is not in the spec;
        // the register budget of ParamNamedAuto.inc decides here (74 / 105 bones).
        SkinMode mode = SKIN_NONE;
        if (hasSkeleton && skinnable)
        {
            if (maxBones <= kMaxSkinBones)
                mode = SKIN_LBS;
            else if (mAllowQuatSkin && !explicitSkinProgram && maxBones <= kMaxQuatSkinBones)
                mode = SKIN_QUAT;
        }
        if (hasSkeleton && mode == SKIN_NONE && mLoggedOnce.insert(std::make_pair("sw:" + mesh->getName(), true)).second)
        {
            logMsg("software skinning for mesh " + mesh->getName() + " (bones per sub-mesh " +
                StringConverter::toString(maxBones) + (skinnable ? ", above the shader limit)" :
                ", a pass cannot be paired with a skinning vertex program)"));
        }

        for (unsigned int i = 0; i < count; ++i)
        {
            SubEntity* se = ent->getSubEntity(i);
            const MaterialPtr& src = se->getSourceMaterial();
            if (!needsVariant(src, true) && mGlobalDefines.empty())
            {
                se->_setResolvedMaterial(src);
                continue;
            }
            SubMesh* sm = se->getSubMesh();
            VertexData* vd = sm->useSharedVertices ? mesh->sharedVertexData : sm->vertexData;
            VertexFeatures vf;
            vf.mesh = true;
            // CYS-PARITY (d3d9-trace L6): actor lighting of this sub-entity (explicit flag, else skinned = actor)
            vf.actor = actorVariantsEnabled() && se->getActorLightingFactor() > 0.5f;
            vf.colour = vd && vd->vertexDeclaration->findElementBySemantic(VES_DIFFUSE) != 0;
            vf.tangent = vd && vd->vertexDeclaration->findElementBySemantic(VES_TANGENT) != 0;
            if (!vf.tangent && needsTangents(src))
                vf.tangent = ensureTangents(mesh.getPointer(), sm);
            se->_setResolvedMaterial(getVariantMaterial(src, mode, vf));
        }
        ++mStatEntities;
        maybePurge(); // CYS fx-render: variants of materials the game has removed (mesh-particle clones ...)
    }
    //----------------------------------------------------------------------------------------------
    Technique* MaterialSystem::resolveTechnique(Renderable* rend, Technique* tech)
    {
        (void)rend;
        if (!mVariantsEnabled || !tech)
            return tech;
        // CYS fx-render: called for every queued renderable every frame (OgreRenderQueue.cpp): one hash lookup,
        // then the source's run-time changes are followed onto the variant (see followSource)
        const unsigned long long t0 = __rdtsc();
        ++mStatResolveCalls;
        if (!mFrameListenerAdded && Root::getSingletonPtr())
        {
            Root::getSingleton().addFrameListener(&mFrameCounter);
            mFrameListenerAdded = true;
        }
        Material* mat = tech->getParent();
        TechniqueCache::iterator it = mTechniqueCache.find(tech);
        if (it != mTechniqueCache.end() && mat && it->second.keyHandle == mat->getHandle())
        {
            TechEntry& e = it->second;
            if (e.syncFrom && followEnabled())
            {
                // One check per frame for all renderables that share the entry; an entry without a change in
                // 30 checks is checked every 8th frame (staggered). Hosts without frame events check every call.
                bool check = true;
                if (mFrameEvents)
                {
                    if (e.lastFrame == mFrame)
                        check = false;
                    else if (e.quietChecks >= 30 &&
                             ((mFrame + static_cast<unsigned int>(reinterpret_cast<size_t>(&e) >> 5)) & 7u) != 0)
                        check = false;
                    else
                        e.lastFrame = mFrame;
                }
                if (check)
                {
                    const size_t before = mStatFollowed;
                    followSource(e);
                    e.quietChecks = (mStatFollowed != before) ? 0 : e.quietChecks + 1;
                    ++mStatChecks;
                }
            }
            Technique* cached = e.result;
            const unsigned long long dt = __rdtsc() - t0;
            mStatResolveTicks += dt;
            mStatHitTicks += dt;        // steady state: every queued renderable of every frame
            ++mStatHitCalls;
            return cached;
        }

        TechEntry entry;
        entry.result = tech;
        entry.syncFrom = 0;
        entry.srcMat = 0;
        entry.techIndex = 0;
        entry.keyHandle = mat ? mat->getHandle() : 0; // guards against a new technique at a recycled address
        entry.owner = 0;
        entry.built = false;
        entry.lastFrame = mFrame;
        entry.quietChecks = 0;
        bool needs = false;
        for (unsigned short p = 0; p < tech->getNumPasses() && !needs; ++p)
            needs = (tech->getPass(p)->hasFragmentProgram() && !tech->getPass(p)->hasVertexProgram()) ||
                    isTerrainShadowPass(tech->getPass(p)); // CYS-SHADOW: terrain receivers
        if (needs && mat)
        {
            MaterialPtr src = MaterialManager::getSingleton().getByName(mat->getName());
            if (!src.isNull() && src.getPointer() == mat)
            {
                // Billboards, particles, ribbons, manual objects: static variant, vertex colour
                // available, no tangents (INF: B handles these through its own particle renderers).
                VertexFeatures vf;
                vf.mesh = false;
                vf.actor = false;
                vf.colour = true;
                vf.tangent = false;
                MaterialPtr v = getVariantMaterial(src, SKIN_NONE, vf);
                if (v.getPointer() != mat)
                {
                    for (unsigned short t = 0; t < mat->getNumTechniques(); ++t)
                    {
                        if (mat->getTechnique(t) == tech && t < v->getNumTechniques() &&
                            v->getTechnique(t)->isSupported())
                        {
                            entry.result = v->getTechnique(t);
                            // CYS fx-render: the game writes the material it holds (the billboard set's): the
                            // dissolve / sequence-frame affectors push their constants into it every frame
                            entry.syncFrom = tech;
                            entry.srcMat = mat;
                            entry.techIndex = t;
                            entry.owner = v.getPointer();
                            break;
                        }
                    }
                }
            }
        }
        TechEntry& stored = mTechniqueCache[tech];
        stored = entry;
        if (stored.syncFrom && followEnabled())
            followSource(stored);
        Technique* result = stored.result;
        mStatResolveTicks += __rdtsc() - t0;
        return result;
    }
    //----------------------------------------------------------------------------------------------
    MaterialPtr MaterialSystem::getVariantMaterial(const MaterialPtr& src, SkinMode mode, const VertexFeatures& vf)
    {
        String tag = StringConverter::toString(int(mode)) + (vf.tangent ? "T" : "") + (vf.colour ? "C" : "") +
            (vf.mesh ? "" : "R") + (vf.actor ? "A" : ""); // CYS-PARITY: actor variants
        const String key = src->getName() + "|" + tag;
        VariantCache::iterator it = mMaterialCache.find(key);
        if (it != mMaterialCache.end())
        {
            if (it->second.source.getPointer() == src.getPointer())
                return it->second.variant;
            // CYS fx-render: another material object under the same name (the game removed and re-created it,
            // e.g. a mesh-particle clone named after a recycled scene node): the cached variant is the old one's
            forgetVariant(it, true);
        }

        Ogre::CysPerf::CountScope cysPerfVariant(Ogre::CysPerf::C_VARIANT_BUILD, Ogre::CysPerf::C_VARIANT_US); // CYS-PERF-C3
        // CYS-PERF (perf-cy): which variants are built during a frame and where (CYS_PERF=1, CYS_PERF_VARLOG=1)
        struct CysVarLog
        {
            const String* src; String tag; long long t0;
            ~CysVarLog()
            {
                if (!t0) return;
                const double ms = double(Ogre::CysPerf::ticks() - t0) * 1000.0 / double(Ogre::CysPerf::ticksPerSecond());
                LogManager::getSingleton().logMessage("CYS-PERF variant frame=" +
                    StringConverter::toString(Root::getSingleton().getCurrentFrameNumber()) + " " + *src + "|" + tag +
                    " " + StringConverter::toString(Real(ms)) + " ms");
            }
        } cysVarLog = { &src->getName(), tag, 0 };
        {
            static int s_on = -1;
            if (s_on < 0) { char v[4] = {0}; s_on = ::GetEnvironmentVariableA("CYS_PERF_VARLOG", v, sizeof(v)) ? 1 : 0; }
            if (s_on && Ogre::CysPerf::on()) cysVarLog.t0 = Ogre::CysPerf::ticks();
        }
        if (!needsVariant(src, vf.mesh) && mGlobalDefines.empty())
        {
            VariantEntry same;
            same.source = src;
            same.variant = src;
            mMaterialCache[key] = same;
            return src;
        }

        const String name = src->getName() + "@CYS" + tag;
        MaterialPtr v = MaterialManager::getSingleton().getByName(name);
        if (!v.isNull())
        {
            // CYS fx-render: left over from an earlier material object (or from other global defines): clone
            // afresh; whoever still renders the old variant keeps it alive
            MaterialManager::getSingleton().remove(v->getHandle());
            v.setNull();
        }
        if (v.isNull())
        {
            v = src->clone(name);
            for (unsigned short t = 0; t < v->getNumTechniques(); ++t)
            {
                Technique* tech = v->getTechnique(t);
                for (unsigned short p = 0; p < tech->getNumPasses(); ++p)
                {
                    Pass* pass = tech->getPass(p);
                    // CYS-LOGIN: 61 CY all.material entries derive from Mtl_Model_Transperant as
                    // 'technique { pass { } pass { emissive 0.2 0.2 0.2 } }': the template has one pass, so the
                    // script parser (OGRE and CY OgreMain MaterialScriptCompiler::parsePass alike) appends a second,
                    // default pass: lit, opaque, depth-writing, no texture, no program. Drawn after the alpha-blended
                    // grass it paints a pale grey-white slab (erengu_DL login scene, the grass patch mesh in front of
                    // the pool: (148,164,172) where CY 3.71 shows (38,52,59), the grass-darkened ground).
                    // INF (not traced through CY's renderer): CY shows nothing of that pass, so a program-less,
                    // texture-less pass that follows a shader pass is left out of the mesh variant.
                    if (vf.mesh && p > 0 && !pass->hasVertexProgram() && !pass->hasFragmentProgram() &&
                        pass->getNumTextureUnitStates() == 0 && tech->getPass(0)->hasFragmentProgram())
                    {
                        tech->removePass(p);
                        --p;
                        ++mStatDroppedPasses;
                        continue;
                    }
                    if (vf.mesh && mConvertFixedFunction && !pass->hasFragmentProgram() && !pass->hasVertexProgram())
                        convertFixedFunction(pass); // program-less pass -> ubershader variant
                    mBuildingActorVariant = vf.actor; // CYS-PARITY: read by promotesToPixelLighting
                    if (pass->hasFragmentProgram() && !pass->hasVertexProgram())
                    {
                        String vp = pickVertexProgram(pass, mode, vf);
                        if (!vp.empty())
                            pass->setVertexProgram(vp);
                    }
                    // CYS-PARITY (d3d9-trace L6): FACT CY 3.71 traces (erengu_DL, Dali): every model draw with the D3D9 alpha
                    // test on uses the ALPHATEST_ENABLE=1 pixel shader (clip at imodel_userdata.z: receivers 6972ae69,
                    // actors a2769318) and every draw without it the plain one; CY-Source only made the alpha variant
                    // for converted fixed-function passes. CYS_PARITY_ALPHATEST=0 turns the rule off.
                    if (alphaTestVariantsEnabled() && pass->hasFragmentProgram() &&
                        pass->getAlphaRejectFunction() != CMPF_ALWAYS_PASS)
                    {
                        HighLevelGpuProgramPtr afp = getHighLevel(pass->getFragmentProgramName());
                        if (!afp.isNull() && classify(afp) == FAMILY_MODEL && defineOf(afp, "ALPHATEST_ENABLE") != "1")
                        {
                            DefineMap at;
                            at["ALPHATEST_ENABLE"] = "1";
                            const String av = getProgramVariant(pass->getFragmentProgramName(), at);
                            if (!av.empty() && av != pass->getFragmentProgramName())
                            {
                                GpuProgramParametersSharedPtr old = pass->getFragmentProgramParameters();
                                pass->setFragmentProgram(av);
                                pass->getFragmentProgramParameters()->_copyNamedConstantValuesFrom(*old);
                            }
                        }
                    }
                    if (!mGlobalDefines.empty() && !vf.actor) // CYS-PARITY: actors keep the authored programs
                        applyGlobalDefines(pass);
                    mBuildingActorVariant = false;
                    bindEngineSamplers(pass);
                }
            }
            try
            {
                v->load();
            }
            catch (Exception& e)
            {
                logMsg("variant " + name + " failed to load: " + e.getDescription());
            }
            if (v->getNumSupportedTechniques() == 0)
            {
                ++mStatFallbacks;
                logMsg("variant " + name + " has no supported technique; keeping " + src->getName());
                MaterialManager::getSingleton().remove(v->getHandle());
                v = src;
            }
            else
            {
                ++mStatVariantMaterials;
            }
        }
        VariantEntry entry;
        entry.source = src;
        entry.variant = v;
        mMaterialCache[key] = entry;
        if (v.getPointer() != src.getPointer())
            registerVariantTechniques(src, v); // CYS fx-render: the variant follows the source's run-time state
        return v;
    }
    //----------------------------------------------------------------------------------------------
    String MaterialSystem::pickVertexProgram(Pass* pass, SkinMode mode, const VertexFeatures& vf)
    {
        HighLevelGpuProgramPtr fp = getHighLevel(pass->getFragmentProgramName());
        if (fp.isNull())
            return StringUtil::BLANK;
        const Family fam = classify(fp);
        const std::map<String, String> fd = parseDefines(fp->getParameter("preprocessor_defines"));
        std::map<String, String>::const_iterator fi;
        String base;
        DefineMap extra;
        switch (fam)
        {
        case FAMILY_DEPTH:
        {
            // Depth_PS (ALPHATEST_ENABLE=1;USE_TEXCOORD=1) / Depth_NoTex_PS -> Depth_[Skin|DQSkin]_[NoTex]_VS
            fi = fd.find("USE_TEXCOORD");
            const bool tex = fi != fd.end() && fi->second == "1";
            if (mode == SKIN_LBS)
                base = tex ? "Depth_Skin_VS" : "Depth_Skin_NoTex_VS";
            else if (mode == SKIN_QUAT)
                base = tex ? "Depth_DQSkin_VS" : "Depth_DQSkin_NoTex_VS";
            else
                base = tex ? "Depth_VS" : "Depth_NoTex_VS";
            break;
        }
        case FAMILY_PARTICLE:
            if (!vf.mesh || !meshParticleModelVs())
            {
                base = "Particle_VS"; // billboards / ribbons: colour = vertex colour + emissive (CalcLight.inc:78-85)
                break;
            }








            base = mode == SKIN_NONE ? "Model_VS" : "Model_Skin_VS";
            if (mode == SKIN_QUAT)
                extra["USE_QUAT_SKIN"] = "1";
            extra["TEX_EFFECT_0"] = "1"; // texture_matrix_2x4_0/1: UV animation as in Particle_VS
            extra["TEX_EFFECT_1"] = "1";
            if (vf.colour)
                extra["USE_VERTEXCOLOR"] = "1";
            if (!pass->getLightingEnabled())
                extra["LIGHT_CALC_TYPE"] = "0"; // LIGHT_CALC_NONE: texture x vertex colour, like fixed function
            break;
        case FAMILY_MODEL:
        {
            base = mode == SKIN_NONE ? "Model_VS" : "Model_Skin_VS";
            if (mode == SKIN_QUAT)
                extra["USE_QUAT_SKIN"] = "1";
            // The vertex output layout (Model_VS_OUT.inc) and the lighting split must match the
            // pixel shader: copy the macros both stages read (FACT: Model_vs.hlsl / ModelDef.inc).
            static const char* const shared[] = { "USE_TANGENT", "USE_VERTEXCOLOR", "XINGNING_EFFECT",
                                                  "LIGHT_CALC_TYPE", "SHADOWMAP_TYPE",
                                                  "TEX_EFFECT_0", "TEX_EFFECT_1" }; // CalcUV.inc (VS)
            for (size_t i = 0; i < sizeof(shared) / sizeof(shared[0]); ++i)
            {
                fi = fd.find(shared[i]);
                if (fi != fd.end())
                    extra[shared[i]] = fi->second;
            }
            if (fd.find("LIGHT_CALC_TYPE") == fd.end() && pass->getUseLit() == Pass::LIT_PIXEL)
                extra["LIGHT_CALC_TYPE"] = "2"; // 'lighting on pslit'
            if (promotesToPixelLighting(fp))
                extra["LIGHT_CALC_TYPE"] = "2"; // CYS-SHADOW: receiver (the pixel shader gets the same in applyGlobalDefines)
            // Only feed vertex inputs the mesh has
            if (!vf.tangent)
                extra.erase("USE_TANGENT");
            if (!vf.colour)
                extra.erase("USE_VERTEXCOLOR");
            break;
        }
        default:
            if (mLoggedOnce.insert(std::make_pair("fam:" + fp->getName(), true)).second)
                logMsg("no vertex program family for pixel shader " + fp->getName() + " (" +
                    fp->getSourceFile() + "); pass left without vertex program");
            return StringUtil::BLANK;
        }
        if (!mBuildingActorVariant) // CYS-PARITY: CY actor vertex programs have no SHADOWMAP_TYPE (no shadow_view_matrix)
        {
            for (DefineMap::const_iterator g = mGlobalDefines.begin(); g != mGlobalDefines.end(); ++g)
                extra[g->first] = g->second;
        }
        else
        {
            extra.erase("SHADOWMAP_TYPE");
            extra.erase("LUT_ENABLE");
        }
        return getProgramVariant(base, extra);
    }
    //----------------------------------------------------------------------------------------------
    String MaterialSystem::getProgramVariant(const String& baseName, const DefineMap& extra)
    {
        HighLevelGpuProgramPtr base = getHighLevel(baseName);
        if (base.isNull())
        {
            if (mLoggedOnce.insert(std::make_pair("prog:" + baseName, true)).second)
                logMsg("vertex program " + baseName + " is not declared (MaterialTemplates.zip missing?)");
            return StringUtil::BLANK;
        }
        DefineMap merged = parseDefines(base->getParameter("preprocessor_defines"));
        DefineMap diff;
        for (DefineMap::const_iterator e = extra.begin(); e != extra.end(); ++e)
        {
            DefineMap::iterator m = merged.find(e->first);
            if (m == merged.end() || m->second != e->second)
            {
                merged[e->first] = e->second;
                diff[e->first] = e->second;
            }
        }
        if (diff.empty())
            return baseName;

        const String name = baseName + "@" + joinDefines(diff);
        if (!getHighLevel(name).isNull())
            return name;
        HighLevelGpuProgramPtr v = HighLevelGpuProgramManager::getSingleton().createProgram(
            name, base->getGroup(), base->getLanguage(), base->getType());
        base->copyParametersTo(v.getPointer()); // entry point, target, packing, skeletal flag ...
        v->setSourceFile(base->getSourceFile());
        v->setParameter("preprocessor_defines", joinDefines(merged));
        v->setSkeletalAnimationIncluded(base->isSkeletalAnimationIncluded());
        // explicit 'param_named' defaults of the base program, by name (the register map differs);
        // auto constants are re-bound by name when the variant is compiled
        GpuProgramParametersSharedPtr defaults = v->getDefaultParameters();
        if (base->hasDefaultParameters())
            defaults->_copyNamedConstantValuesFrom(*base->getDefaultParameters());
        ++mStatVariantPrograms;
        logMsg("variant program " + name + (v->hasCompileError() ? " FAILED to compile" : ""));
        return name;
    }
    //----------------------------------------------------------------------------------------------
    namespace
    {
        const char* const kSsaoTexture = "CYS/Global/SSAO";

        // FixedFunctionInfo / analyseFixedFunction are declared next to defineOf (used earlier)

        /// BLEND_OP value of a layer (0 modulate, 1 x2, 2 x4, 3 add); 'replace' = unlit texture
        int blendOpOf(const TextureUnitState* t, bool& unlit)
        {
            const LayerBlendModeEx& m = t->getColourBlendMode();
            switch (m.operation)
            {
            case LBX_MODULATE_X2: return 1;
            case LBX_MODULATE_X4: return 2;
            case LBX_ADD: return 3;
            case LBX_SOURCE1:
                if (m.source1 == LBS_TEXTURE)
                    unlit = true;
                return 0;
            default:
                return 0; // modulate; the other operations are approximated by it
            }
        }

        /// scrolling / rotating / waving or statically transformed texture coordinates
        bool hasTextureTransform(const TextureUnitState* t)
        {
            const TextureUnitState::EffectMap& fx = t->getEffects();
            for (TextureUnitState::EffectMap::const_iterator e = fx.begin(); e != fx.end(); ++e)
                if (e->second.type != TextureUnitState::ET_ENVIRONMENT_MAP)
                    return true;
            return t->getTextureTransform() != Matrix4::IDENTITY;
        }

        bool analyseFixedFunction(Pass* pass, FixedFunctionInfo& info)
        {
            if (pass->hasVertexProgram() || pass->hasFragmentProgram())
                return false;
            const unsigned short n = pass->getNumTextureUnitStates();
            if (n == 0 || n > 3)
                return false;
            info.diffuse[0] = info.diffuse[1] = -1;
            info.sphere = -1;
            info.defines.clear();
            int layers = 0;
            for (unsigned short i = 0; i < n; ++i)
            {
                const TextureUnitState* t = pass->getTextureUnitState(i);
                if (t->getContentType() != TextureUnitState::CONTENT_NAMED || t->isBlank() ||
                    t->getTextureType() != TEX_TYPE_2D || t->getSamplerRegisterIndex() >= 0 ||
                    t->getTexUnitShaderType() != TextureUnitState::TUST_FRAGMENT)
                    return false;
                bool env = false;
                const TextureUnitState::EffectMap& fx = t->getEffects();
                for (TextureUnitState::EffectMap::const_iterator e = fx.begin(); e != fx.end(); ++e)
                {
                    if (e->second.type == TextureUnitState::ET_ENVIRONMENT_MAP)
                    {
                        if (e->second.subtype != TextureUnitState::ENV_CURVED &&
                            e->second.subtype != TextureUnitState::ENV_PLANAR)
                            return false; // cubic maps stay fixed function
                        env = true;
                    }
                    else if (e->second.type == TextureUnitState::ET_PROJECTIVE_TEXTURE)
                        return false;
                }
                if (env)
                {
                    if (info.sphere >= 0)
                        return false;
                    info.sphere = i;
                    continue;
                }
                // the ubershaders sample every colour layer with UV set 0 (no lightmap UVs)
                if (t->getTextureCoordSet() != 0 || layers == 2)
                    return false;
                info.diffuse[layers++] = i;
            }
            if (layers == 0 || (layers == 2 && info.sphere >= 0))
                return false; // Model_2Tex_ps.hlsl has no environment map
            bool unlit = !pass->getLightingEnabled();
            const TextureUnitState* t0 = pass->getTextureUnitState(static_cast<unsigned short>(info.diffuse[0]));
            const int op0 = blendOpOf(t0, unlit);
            if (layers == 2)
            {
                info.base = "Model_TwoTex_PS"; // Model_2Tex_ps.hlsl with DIFFUSE_2_ENABLE=1
                bool ignored = false;
                const TextureUnitState* t1 = pass->getTextureUnitState(static_cast<unsigned short>(info.diffuse[1]));
                const int op1 = blendOpOf(t1, ignored);
                if (op1)
                    info.defines["BLEND_OP_1"] = StringConverter::toString(op1);
                if (hasTextureTransform(t1))
                    info.defines["TEX_EFFECT_1"] = "1";
            }
            else
            {
                // SpereMaping (sic) carries 'column_major_matrices false' and view_matrix
                info.base = info.sphere >= 0 ? "Character_Skin_SpereMaping_PS" : "Character_Skin_PS";
            }
            if (op0)
                info.defines["BLEND_OP_0"] = StringConverter::toString(op0);
            if (hasTextureTransform(t0))
                info.defines["TEX_EFFECT_0"] = "1";
            if (unlit)
                info.defines["LIGHT_CALC_TYPE"] = "0";
            if (pass->getAlphaRejectFunction() != CMPF_ALWAYS_PASS)
                info.defines["ALPHATEST_ENABLE"] = "1";
            if (pass->getVertexColourTracking() != TVC_NONE)
                info.defines["USE_VERTEXCOLOR"] = "1";
            return true;
        }

        /// 1x1 white texture (created once; a producer may replace it by removing it and creating
        /// its own texture under the same name)
        void ensureWhiteTexture(const String& name)
        {
            TextureManager& tm = TextureManager::getSingleton();
            if (!tm.getByName(name).isNull())
                return;
            static unsigned char white[4] = { 255, 255, 255, 255 };
            Image img;
            img.loadDynamicImage(white, 1, 1, 1, PF_BYTE_RGBA);
            tm.loadImage(name, ResourceGroupManager::INTERNAL_RESOURCE_GROUP_NAME, img, TEX_TYPE_2D, 0);
            LogManager::getSingleton().logMessage("CYS material system: 1x1 white " + name +
                " until a producer replaces it");
        }

        /// Appends a unit bound to sampler register 'sampler' unless the pass binds it already
        bool addEngineUnit(Pass* pass, TextureUnitState::ContentType type, const String& texName,
                           int sampler, TextureFilterOptions filter)
        {
            for (unsigned short i = 0; i < pass->getNumTextureUnitStates(); ++i)
            {
                const TextureUnitState* t = pass->getTextureUnitState(i);
                if (t->getTexUnitShaderType() != TextureUnitState::TUST_FRAGMENT)
                    continue;
                const int reg = t->getSamplerRegisterIndex() >= 0 ? t->getSamplerRegisterIndex() : int(i);
                if (reg == sampler)
                    return false;
            }
            TextureUnitState* t = pass->createTextureUnitState();
            t->setCompositorReference(StringUtil::BLANK, texName, 0);
            t->setContentType(type);
            t->setSamplerRegisterIndex(sampler);
            t->setTextureAddressingMode(TextureUnitState::TAM_CLAMP);
            t->setTextureFiltering(filter);
            return true;
        }

        // CYS-LOOK: LUT of the shadow-receiver pixel shaders (LUT_ENABLE=1). FACT: CY 3.71 / B MaterialTemplates.zip
        // 'luttex.png' (16x16 grey S-curve, byte-identical in both zips), sampled per channel by LUTColor()
        // (ShaderLib/Diffuse.inc, FairyTerrainColorMap.hlsl) at register s4; CY's terrain Lut materials bind it as
        // 'texture luttex.png / tex_address_mode clamp / filtering none / sampler_index 4'
        // (SceneFolder/FairyTerrainColorMapNormalSpec.material); CY OgreMain.dll holds the same file name for the
        // receiver programs. Spec: Docs\specs\render\cy-look_vi.md.
        const char* const kLutTexture = "luttex.png";

        /// true when no fragment texture unit of the pass is bound to sampler register 'sampler'
        bool samplerFree(const Pass* pass, int sampler)
        {
            for (unsigned short i = 0; i < pass->getNumTextureUnitStates(); ++i)
            {
                const TextureUnitState* t = pass->getTextureUnitState(i);
                if (t->getTexUnitShaderType() != TextureUnitState::TUST_FRAGMENT)
                    continue;
                const int reg = t->getSamplerRegisterIndex() >= 0 ? t->getSamplerRegisterIndex() : int(i);
                if (reg == sampler)
                    return false;
            }
            return true;
        }

        /// the LUT texture exists in some resource group (MaterialTemplates.zip)
        bool lutTextureAvailable(void)
        {
            static int available = -1;
            if (available < 0)
            {
                try
                {
                    available = ResourceGroupManager::getSingleton().findGroupContainingResource(kLutTexture).empty()
                        ? 0 : 1;
                }
                catch (const Exception&)
                {
                    available = 0;
                }
                LogManager::getSingleton().logMessage(String("CYS material system: receiver LUT ") + kLutTexture +
                    (available ? " found" : " missing, LUT_ENABLE not used"));
            }
            return available == 1;
        }

        /// s4 unit reading luttex.png as CY does
        bool addLutUnit(Pass* pass)
        {
            if (!samplerFree(pass, 4))
                return false;
            TextureUnitState* t = pass->createTextureUnitState();
            t->setTextureName(kLutTexture);
            t->setSamplerRegisterIndex(4);
            t->setTextureAddressingMode(TextureUnitState::TAM_CLAMP);
            t->setTextureFiltering(TFO_NONE);
            return true;
        }
    }
    //----------------------------------------------------------------------------------------------
    void MaterialSystem::setFixedFunctionConversion(bool on)
    {
        if (mConvertFixedFunction == on)
            return;
        mConvertFixedFunction = on;
        mMaterialCache.clear();
        mTechniqueCache.clear();
    }
    //----------------------------------------------------------------------------------------------
    bool MaterialSystem::alphaTestVariantsEnabled(void)
    {
        static const bool on = []() {
            const char* v = getenv("CYS_PARITY_ALPHATEST");
            return !(v && v[0] == '0');
        }();
        return on;
    }
    //----------------------------------------------------------------------------------------------
    bool MaterialSystem::actorVariantsEnabled(void)
    {
        // CYS-PARITY (d3d9-trace L6): CYS_PARITY_ACTOR=0 lights actors like scene objects again (receivers + LUT)
        static const bool on = []() {
            const char* v = getenv("CYS_PARITY_ACTOR");
            return !(v && v[0] == '0');
        }();
        return on;
    }
    //----------------------------------------------------------------------------------------------
    bool MaterialSystem::needsVariant(const MaterialPtr& mat, bool mesh) const
    {
        if (needsVertexProgram(mat))
            return true;
        if (!mesh || !mConvertFixedFunction)
            return false;
        FixedFunctionInfo info;
        for (unsigned short t = 0; t < mat->getNumTechniques(); ++t)
        {
            Technique* tech = mat->getTechnique(t);
            for (unsigned short p = 0; p < tech->getNumPasses(); ++p)
                if (analyseFixedFunction(tech->getPass(p), info))
                    return true;
        }
        return false;
    }
    //----------------------------------------------------------------------------------------------
    bool MaterialSystem::convertFixedFunction(Pass* pass)
    {
        FixedFunctionInfo info;
        if (!analyseFixedFunction(pass, info) || getHighLevel(info.base).isNull())
            return false;
        const String fp = getProgramVariant(info.base, info.defines);
        if (fp.empty())
            return false;
        pass->setFragmentProgram(fp);
        // sampler registers of Model_ps.hlsl / Model_2Tex_ps.hlsl / ParamNamed.inc
        pass->getTextureUnitState(static_cast<unsigned short>(info.diffuse[0]))->setSamplerRegisterIndex(0);
        if (info.diffuse[1] >= 0)
            pass->getTextureUnitState(static_cast<unsigned short>(info.diffuse[1]))->setSamplerRegisterIndex(1);
        if (info.sphere >= 0)
            pass->getTextureUnitState(static_cast<unsigned short>(info.sphere))->setSamplerRegisterIndex(3);
        ++mStatFFPasses;
        return true;
    }
    //----------------------------------------------------------------------------------------------
    bool MaterialSystem::isReceiverDefineSet(void) const
    {
        DefineMap::const_iterator g = mGlobalDefines.find("SHADOWMAP_TYPE");
        return g != mGlobalDefines.end() && (g->second == "1" || g->second == "2");
    }
    //----------------------------------------------------------------------------------------------
    bool MaterialSystem::receiverLutEnabled(void) const
    {
        // CYS-LOOK: A/B switch CYS_SHADOW_LUT=0; CYS_SHADOW_PROMOTE=0 (receivers as authored) also leaves the LUT out
        static const bool env = !(std::getenv("CYS_SHADOW_LUT") && std::string(std::getenv("CYS_SHADOW_LUT")) == "0");
        return env && mShadowReceiverLighting && isReceiverDefineSet() && lutTextureAvailable();
    }
    //----------------------------------------------------------------------------------------------
    void MaterialSystem::bindEngineSamplers(Pass* pass)
    {
        // Engine-owned samplers of the Model_* pixel shaders (FACT: ShaderLib/ParamNamed.inc):
        //   s4  LUTSampler        LUT_ENABLE = 1                         -> "CYS/Global/LUT"
        //   s5  ShadowMapSampler  SHADOWMAP_TYPE = 1 (CSM) or 2 (simple) -> "CYS/Shadow/0"
        //   s12 ssao_buffer       read by the LIGHT_CALC_TYPE = 2 lighting (CalcLight.inc: indirect
        //                         light * ssao.r)                        -> "CYS/Global/SSAO"
        // SceneManager::_setPass unbinds every register a pass does not name, so they are texture
        // units with a fixed sampler index. The SSAO slot reads a 1x1 white texture until the
        // post-processing system provides one (an unbound sampler reads 0: no indirect light).
        if (!pass->hasFragmentProgram())
            return;
        HighLevelGpuProgramPtr fp = getHighLevel(pass->getFragmentProgramName());
        if (!fp.isNull() && lower(fp->getSourceFile()) == "fairyterraincolormap.hlsl" &&
            defineOf(fp, "LIGHT_CALC_TYPE") == "2")
        {
            // CYS-SHADOW: terrain receiver variant: s5 shadow atlas + s12 SSAO (terrain_ps signature)
            const String shadow = defineOf(fp, "SHADOWMAP_TYPE");
            if ((shadow == "1" || shadow == "2") &&
                addEngineUnit(pass, TextureUnitState::CONTENT_SHADOW, StringUtil::BLANK, 5, TFO_NONE))
                ++mStatEngineUnits;
            ensureWhiteTexture(kSsaoTexture);
            if (addEngineUnit(pass, TextureUnitState::CONTENT_GLOBAL, "SSAO", 12, TFO_BILINEAR))
                ++mStatEngineUnits;
            if (defineOf(fp, "LUT_ENABLE") == "1" && addLutUnit(pass)) // CYS-LOOK: $lutTex s4
                ++mStatEngineUnits;
            return;
        }
        if (fp.isNull() || classify(fp) != FAMILY_MODEL)
            return;
        if (defineOf(fp, "LIGHT_CALC_TYPE") == "2")
        {
            ensureWhiteTexture(kSsaoTexture);
            if (addEngineUnit(pass, TextureUnitState::CONTENT_GLOBAL, "SSAO", 12, TFO_BILINEAR))
                ++mStatEngineUnits;
        }
        const String shadow = defineOf(fp, "SHADOWMAP_TYPE");
        if ((shadow == "1" || shadow == "2") &&
            addEngineUnit(pass, TextureUnitState::CONTENT_SHADOW, StringUtil::BLANK, 5, TFO_NONE))
            ++mStatEngineUnits;
        if (defineOf(fp, "LUT_ENABLE") == "1" && addLutUnit(pass)) // CYS-LOOK: LUTSampler s4 = luttex.png
            ++mStatEngineUnits;
    }
    //----------------------------------------------------------------------------------------------
    void MaterialSystem::applyGlobalDefines(Pass* pass)
    {
        // SHADOWMAP_TYPE / LUT_ENABLE ... also change the pixel shader
        if (!pass->hasFragmentProgram())
            return;
        const String fpName = pass->getFragmentProgramName();
        HighLevelGpuProgramPtr fp = getHighLevel(fpName);
        if (isTerrainShadowPass(pass))
        {
            // CYS-SHADOW: FairyTerrainColorMap.hlsl receives only as LIGHT_CALC_TYPE 2 + SHADOWMAP_TYPE (its pixel
            // shader declares the light arrays for that combination only); both programs get the same macros.
            DefineMap defines;
            defines["SHADOWMAP_TYPE"] = mGlobalDefines["SHADOWMAP_TYPE"];
            defines["LIGHT_CALC_TYPE"] = "2";
            const String vpName = pass->getVertexProgramName();
            const String vv = getProgramVariant(vpName, defines);


            if (receiverLutEnabled() && samplerFree(pass, 4))
                defines["LUT_ENABLE"] = "1";
            const String fv = getProgramVariant(fpName, defines);
            if (vv.empty() || fv.empty())
                return;
            GpuProgramParametersSharedPtr oldVp = pass->getVertexProgramParameters();
            GpuProgramParametersSharedPtr oldFp = pass->getFragmentProgramParameters();
            pass->setVertexProgram(vv);
            pass->getVertexProgramParameters()->_copyNamedConstantValuesFrom(*oldVp);
            pass->setFragmentProgram(fv);
            pass->getFragmentProgramParameters()->_copyNamedConstantValuesFrom(*oldFp);
            return;
        }
        if (fp.isNull() || classify(fp) == FAMILY_UNKNOWN)
            return;
        DefineMap defines = mGlobalDefines;
        if (promotesToPixelLighting(fp) && pass->hasVertexProgram())
        {
            // CYS-SHADOW: receiver, only when the vertex program pickVertexProgram paired is the promoted one
            HighLevelGpuProgramPtr vp = getHighLevel(pass->getVertexProgramName());
            if (!vp.isNull() && defineOf(vp, "LIGHT_CALC_TYPE") == "2")
                defines["LIGHT_CALC_TYPE"] = "2";
        }




        if (classify(fp) == FAMILY_MODEL && isReceiverDefineSet() && pass->getLightingEnabled() &&
            defineOf(fp, "DISSOLVE_EFFECT") != "5" && receiverLutEnabled() && samplerFree(pass, 4))
            defines["LUT_ENABLE"] = "1";
        const String v = getProgramVariant(fpName, defines);
        if (v.empty() || v == fpName)
            return;
        GpuProgramParametersSharedPtr old = pass->getFragmentProgramParameters();
        pass->setFragmentProgram(v);
        pass->getFragmentProgramParameters()->_copyNamedConstantValuesFrom(*old);
    }
    //----------------------------------------------------------------------------------------------
    bool MaterialSystem::ensureTangents(Mesh* mesh, SubMesh* sub)
    {
        // Tangents for normal-mapped templates (USE_TANGENT=1). B computes them with MikkTSpace
        // (TangentSpaceCalc in its OgreMain, FACT); here: per-triangle UV derivatives accumulated per
        // vertex, Gram-Schmidt against the normal, handedness in w (T = dP/du, B = w * cross(N, T)).
        VertexData* vd = sub->useSharedVertices ? mesh->sharedVertexData : sub->vertexData;
        if (!vd)
            return false;
        VertexDeclaration* decl = vd->vertexDeclaration;
        if (decl->findElementBySemantic(VES_TANGENT))
            return true;
        const VertexElement* posE = decl->findElementBySemantic(VES_POSITION);
        const VertexElement* nrmE = decl->findElementBySemantic(VES_NORMAL);
        const VertexElement* uvE = decl->findElementBySemantic(VES_TEXTURE_COORDINATES, 0);
        if (!posE || !nrmE || !uvE || posE->getType() != VET_FLOAT3 || nrmE->getType() != VET_FLOAT3 ||
            (uvE->getType() != VET_FLOAT2 && uvE->getType() != VET_FLOAT3))
        {
            if (mLoggedOnce.insert(std::make_pair("tan:" + mesh->getName(), true)).second)
                logMsg("mesh " + mesh->getName() + " has no position/normal/uv0 for tangents");
            return false;
        }
        const size_t n = vd->vertexCount;
        std::vector<Vector3> pos(n), nrm(n), t1(n, Vector3::ZERO), t2(n, Vector3::ZERO);
        std::vector<Vector2> uv(n);
        // read the three elements (they may live in different buffers)
        const VertexElement* elems[3] = { posE, nrmE, uvE };
        for (int e = 0; e < 3; ++e)
        {
            HardwareVertexBufferSharedPtr buf = vd->vertexBufferBinding->getBuffer(elems[e]->getSource());
            unsigned char* base = static_cast<unsigned char*>(buf->lock(HardwareBuffer::HBL_READ_ONLY));
            const size_t stride = buf->getVertexSize();
            base += vd->vertexStart * stride;
            for (size_t i = 0; i < n; ++i)
            {
                float* f;
                elems[e]->baseVertexPointerToElement(base + i * stride, &f);
                if (e == 0)
                    pos[i] = Vector3(f[0], f[1], f[2]);
                else if (e == 1)
                    nrm[i] = Vector3(f[0], f[1], f[2]);
                else
                    uv[i] = Vector2(f[0], f[1]);
            }
            buf->unlock();
        }
        // triangles of every sub-mesh using this vertex data
        size_t triangles = 0;
        for (unsigned short s = 0; s < mesh->getNumSubMeshes(); ++s)
        {
            SubMesh* sm = mesh->getSubMesh(s);
            VertexData* svd = sm->useSharedVertices ? mesh->sharedVertexData : sm->vertexData;
            if (svd != vd || sm->operationType != RenderOperation::OT_TRIANGLE_LIST || !sm->indexData ||
                sm->indexData->indexBuffer.isNull())
                continue;
            IndexData* id = sm->indexData;
            const bool i32 = id->indexBuffer->getType() == HardwareIndexBuffer::IT_32BIT;
            const void* ib = id->indexBuffer->lock(HardwareBuffer::HBL_READ_ONLY);
            for (size_t k = 0; k + 2 < id->indexCount; k += 3)
            {
                size_t idx[3];
                for (int c = 0; c < 3; ++c)
                {
                    size_t at = id->indexStart + k + c;
                    idx[c] = i32 ? static_cast<const uint32*>(ib)[at] : static_cast<const uint16*>(ib)[at];
                }
                if (idx[0] >= n || idx[1] >= n || idx[2] >= n)
                    continue;
                const Vector3 e1 = pos[idx[1]] - pos[idx[0]], e2 = pos[idx[2]] - pos[idx[0]];
                const float du1 = uv[idx[1]].x - uv[idx[0]].x, dv1 = uv[idx[1]].y - uv[idx[0]].y;
                const float du2 = uv[idx[2]].x - uv[idx[0]].x, dv2 = uv[idx[2]].y - uv[idx[0]].y;
                const float det = du1 * dv2 - du2 * dv1;
                if (std::fabs(det) < 1e-12f)
                    continue;
                const float r = 1.0f / det;
                const Vector3 sdir = (e1 * dv2 - e2 * dv1) * r;
                const Vector3 tdir = (e2 * du1 - e1 * du2) * r;
                // MikkTSpace-style accumulation: per corner, the face tangent / bitangent are
                // projected onto the plane of the vertex normal, normalised and weighted by the
                // corner angle (MikkTSpace additionally splits vertices; this keeps the mesh as is)
                for (int c = 0; c < 3; ++c)
                {
                    const size_t i0 = idx[c], i1 = idx[(c + 1) % 3], i2 = idx[(c + 2) % 3];
                    Vector3 n = nrm[i0];
                    n.normalise();
                    Vector3 a = pos[i1] - pos[i0], b = pos[i2] - pos[i0];
                    a -= n * n.dotProduct(a);
                    b -= n * n.dotProduct(b);
                    const float la = a.length(), lb = b.length();
                    float cosAngle = (la > 1e-12f && lb > 1e-12f) ? a.dotProduct(b) / (la * lb) : 1.0f;
                    cosAngle = std::max(-1.0f, std::min(1.0f, cosAngle));
                    const float angle = std::acos(cosAngle);
                    Vector3 ts = sdir - n * n.dotProduct(sdir);
                    Vector3 tt = tdir - n * n.dotProduct(tdir);
                    if (ts.squaredLength() > 1e-20f)
                        t1[i0] += ts.normalisedCopy() * angle;
                    if (tt.squaredLength() > 1e-20f)
                        t2[i0] += tt.normalisedCopy() * angle;
                }
                ++triangles;
            }
            id->indexBuffer->unlock();
        }
        // new buffer with float4 tangents
        const unsigned short source = vd->vertexBufferBinding->getNextIndex();
        HardwareVertexBufferSharedPtr tb = HardwareBufferManager::getSingleton().createVertexBuffer(
            sizeof(float) * 4, n, HardwareBuffer::HBU_STATIC_WRITE_ONLY, true);
        float* out = static_cast<float*>(tb->lock(HardwareBuffer::HBL_DISCARD));
        for (size_t i = 0; i < n; ++i)
        {
            Vector3 nn = nrm[i];
            nn.normalise();
            Vector3 t = t1[i] - nn * nn.dotProduct(t1[i]);
            if (t.squaredLength() < 1e-12f)
                t = nn.perpendicular();
            t.normalise();
            const float w = nn.crossProduct(t).dotProduct(t2[i]) < 0.0f ? -1.0f : 1.0f;
            out[i * 4 + 0] = t.x;
            out[i * 4 + 1] = t.y;
            out[i * 4 + 2] = t.z;
            out[i * 4 + 3] = w;
        }
        tb->unlock();
        vd->vertexBufferBinding->setBinding(source, tb);
        decl->addElement(source, 0, VET_FLOAT4, VES_TANGENT);
        ++mStatTangentSets;
        logMsg("generated tangents for " + mesh->getName() + " (" + StringConverter::toString(n) + " vertices, " +
            StringConverter::toString(triangles) + " triangles)");
        return true;
    }
    //----------------------------------------------------------------------------------------------
    bool MaterialSystem::setEntityParam(Entity* ent, const String& name, const Vector4& value)
    {
        bool found = false;
        std::vector<MaterialPtr>& owned = mInstanceMaterials[ent];
        for (unsigned int i = 0; i < ent->getNumSubEntities(); ++i)
        {
            SubEntity* se = ent->getSubEntity(i);
            MaterialPtr cur = se->getMaterial();
            const String instName = se->getSourceMaterial().isNull() ? cur->getName() + "@inst" + ent->getName() +
                "#" + StringConverter::toString(i) : se->getSourceMaterial()->getName() + "@inst" + ent->getName() +
                "#" + StringConverter::toString(i);
            if (cur->getName() != instName)
            {
                MaterialPtr inst = MaterialManager::getSingleton().getByName(instName);
                if (inst.isNull())
                {
                    inst = cur->clone(instName);
                    inst->load();
                    owned.push_back(inst);
                }
                se->_setResolvedMaterial(inst);
                cur = inst;
            }
            for (unsigned short t = 0; t < cur->getNumTechniques(); ++t)
            {
                Technique* tech = cur->getTechnique(t);
                for (unsigned short p = 0; p < tech->getNumPasses(); ++p)
                {
                    Pass* pass = tech->getPass(p);
                    if (pass->hasFragmentProgram() && pass->getFragmentProgramParameters()->hasNamedConstant(name))
                    {
                        pass->getFragmentProgramParameters()->setNamedConstant(name, value);
                        found = true;
                    }
                    if (pass->hasVertexProgram() && pass->getVertexProgramParameters()->hasNamedConstant(name))
                    {
                        pass->getVertexProgramParameters()->setNamedConstant(name, value);
                        found = true;
                    }
                }
            }
        }
        return found;
    }
    //----------------------------------------------------------------------------------------------
    void MaterialSystem::resetEntityParams(Entity* ent)
    {
        std::map<Entity*, std::vector<MaterialPtr> >::iterator it = mInstanceMaterials.find(ent);
        // back to the shared variants first, then drop the clones
        resolveEntity(ent);
        if (it == mInstanceMaterials.end())
            return;
        for (size_t i = 0; i < it->second.size(); ++i)
            MaterialManager::getSingleton().remove(it->second[i]->getHandle());
        mInstanceMaterials.erase(it);
    }
    //----------------------------------------------------------------------------------------------
    // CYS fx-render (2026-09-13): run-time state of the source followed onto its variant.
    // The rule is "follow changes": the variant starts from its own state, and a property is written to it only
    // when the source changes that property, so code that writes the rendered material directly is not undone.
    //----------------------------------------------------------------------------------------------
    void MaterialSystem::PassState::read(const Pass* p)
    {
        ambient = p->getAmbient();
        diffuse = p->getDiffuse();
        specular = p->getSpecular();
        emissive = p->getSelfIllumination();
        shininess = p->getShininess();
        tracking = int(p->getVertexColourTracking());
        srcBlend = int(p->getSourceBlendFactor());
        dstBlend = int(p->getDestBlendFactor());
        separateBlend = p->hasSeparateSceneBlending();
        srcBlendAlpha = int(p->getSourceBlendFactorAlpha());
        dstBlendAlpha = int(p->getDestBlendFactorAlpha());
        depthCheck = p->getDepthCheckEnabled();
        depthWrite = p->getDepthWriteEnabled();
        colourWrite = p->getColourWriteEnabled();
        depthFunc = int(p->getDepthFunction());
        alphaFunc = int(p->getAlphaRejectFunction());
        alphaValue = int(p->getAlphaRejectValue());
        cull = int(p->getCullingMode());
        manualCull = int(p->getManualCullingMode());
    }
    //----------------------------------------------------------------------------------------------
    bool MaterialSystem::PassState::operator==(const PassState& o) const
    {
        return ambient == o.ambient && diffuse == o.diffuse && specular == o.specular && emissive == o.emissive &&
            shininess == o.shininess && tracking == o.tracking && srcBlend == o.srcBlend && dstBlend == o.dstBlend &&
            separateBlend == o.separateBlend && srcBlendAlpha == o.srcBlendAlpha &&
            dstBlendAlpha == o.dstBlendAlpha && depthCheck == o.depthCheck && depthWrite == o.depthWrite &&
            colourWrite == o.colourWrite && depthFunc == o.depthFunc && alphaFunc == o.alphaFunc &&
            alphaValue == o.alphaValue && cull == o.cull && manualCull == o.manualCull;
    }
    //----------------------------------------------------------------------------------------------
    void MaterialSystem::registerVariantTechniques(const MaterialPtr& src, const MaterialPtr& variant)
    {
        // Sub-entities render the variant's techniques (SubEntity::getTechnique): each follows the source
        // technique it was cloned from.
        const unsigned short n = std::min(src->getNumTechniques(), variant->getNumTechniques());
        for (unsigned short t = 0; t < n; ++t)
        {
            TechEntry& e = mTechniqueCache[variant->getTechnique(t)];
            e.result = variant->getTechnique(t);
            e.syncFrom = src->getTechnique(t);
            e.srcMat = src.getPointer();
            e.techIndex = t;
            e.keyHandle = variant->getHandle();
            e.owner = variant.getPointer();
            e.built = false;
            e.lastFrame = mFrame - 1;   // checked on its first frame
            e.quietChecks = 0;
            e.passes.clear();
        }
    }
    //----------------------------------------------------------------------------------------------
    bool MaterialSystem::FrameCounter::frameStarted(const FrameEvent& evt)
    {
        (void)evt;
        ++mOwner.mFrame;
        mOwner.mFrameEvents = true;
        // CYS-PERF-FIX fogvariant: release the variants forgotten at least two frames ago
        std::vector<std::pair<unsigned int, MaterialPtr> >& retired = mOwner.mRetiredVariants;
        for (size_t i = retired.size(); i-- > 0;)
            if (mOwner.mFrame - retired[i].first >= 2)
                retired.erase(retired.begin() + i);
        return true;
    }
    //----------------------------------------------------------------------------------------------
    void MaterialSystem::forgetMaterial(Material* mat)
    {
        // CYS-PERF-FIX fogvariant (perf-cy 15/09): Terrain::_applyFogMode renames the programs of a grid material
        // (fog_linear variant). A variant built before (Terrain::cysPrewarm resolves every grid material at scene
        // load; the fog mode reached the materials only at the first queued tile) kept the programs without fog:
        // d3d9-trace, terrain pixel shader 5201f4e2 without fog_colour / fog_params instead of CY's 7f401886.
        // followSource follows colours / blending / constants, not program names, so the variant is built again.
        if (!mat)
            return;
        for (VariantCache::iterator it = mMaterialCache.begin(); it != mMaterialCache.end();)
        {
            if (it->second.source.getPointer() == mat)
            {
                VariantCache::iterator dead = it++;
                if (!dead->second.variant.isNull() && dead->second.variant.getPointer() != mat)
                    mRetiredVariants.push_back(std::make_pair(mFrame, dead->second.variant));
                forgetVariant(dead, true);
            }
            else
                ++it;
        }
        // entries are keyed by the queued technique (srcMat = its parent): no scan of the whole cache
        for (unsigned short t = 0; t < mat->getNumTechniques(); ++t)
            mTechniqueCache.erase(mat->getTechnique(t));
    }
    //----------------------------------------------------------------------------------------------
    void MaterialSystem::buildSync(TechEntry& e)
    {
        e.built = true;
        e.passes.clear();
        Technique* s = e.syncFrom;
        Technique* d = e.result;
        if (s->getNumPasses() != d->getNumPasses() &&
            mLoggedOnce.insert(std::make_pair("sync:" + d->getParent()->getName(), true)).second)
        {
            logMsg("variant " + d->getParent()->getName() + " has " + StringConverter::toString(d->getNumPasses()) +
                " pass(es), its source " + StringConverter::toString(s->getNumPasses()) +
                ": only the common ones follow the source");
        }
        // B's per-instance constants declared by both programs (same register layout is not assumed)
        auto match = [](const GpuProgramParametersSharedPtr& sp, const GpuProgramParametersSharedPtr& dp,
                        std::vector<ConstSync>& out)
        {
            for (size_t i = 0; i < getInstanceParamCount(); ++i)
            {
                const String name(kInstanceParams[i].name);
                if (!sp->hasNamedConstant(name) || !dp->hasNamedConstant(name))
                    continue;
                ConstSync c;
                c.src = sp->getParamIndex(name);
                c.dst = dp->getParamIndex(name);
                GpuProgramParameters::RealConstantEntry* de = dp->getRealConstantEntry(c.dst);
                if (!de || !sp->getRealConstantEntry(c.src))
                    continue;
                std::memcpy(c.last, de->val, sizeof(c.last)); // the variant's value: any difference is a change
                out.push_back(c);
            }
        };
        const unsigned short n = std::min(s->getNumPasses(), d->getNumPasses());
        for (unsigned short p = 0; p < n; ++p)
        {
            PassSync ps;
            ps.src = s->getPass(p);
            ps.dst = d->getPass(p);
            ps.last.read(ps.dst);
            for (unsigned short u = 0; u < ps.src->getNumTextureUnitStates(); ++u)
            {
                const TextureUnitState* dt = u < ps.dst->getNumTextureUnitStates() ? ps.dst->getTextureUnitState(u) : 0;
                ps.textures.push_back(dt ? dt->getTextureName() : StringUtil::BLANK);
            }
            if (ps.src->hasFragmentProgram() && ps.dst->hasFragmentProgram())
                match(ps.src->getFragmentProgramParameters(), ps.dst->getFragmentProgramParameters(), ps.fp);
            if (ps.src->hasVertexProgram() && ps.dst->hasVertexProgram())
                match(ps.src->getVertexProgramParameters(), ps.dst->getVertexProgramParameters(), ps.vp);
            e.passes.push_back(ps);
        }
    }
    //----------------------------------------------------------------------------------------------
    void MaterialSystem::followSource(TechEntry& e)
    {
        // The source technique must still be the object the entry was made from (Material::copyDetailsTo and
        // operator= replace techniques); otherwise stop following, the variant keeps its last state.
        if (!e.srcMat || e.techIndex >= e.srcMat->getNumTechniques() ||
            e.srcMat->getTechnique(e.techIndex) != e.syncFrom)
        {
            e.syncFrom = 0;
            return;
        }
        if (!e.built)
            buildSync(e);
        auto follow = [this](const GpuProgramParametersSharedPtr& sp, const GpuProgramParametersSharedPtr& dp,
                             std::vector<ConstSync>& regs)
        {
            for (size_t k = 0; k < regs.size(); ++k)
            {
                ConstSync& c = regs[k];
                GpuProgramParameters::RealConstantEntry* s = sp->getRealConstantEntry(c.src);
                if (!s || std::memcmp(s->val, c.last, sizeof(c.last)) == 0)
                    continue;
                std::memcpy(c.last, s->val, sizeof(c.last));
                GpuProgramParameters::RealConstantEntry* d = dp->getRealConstantEntry(c.dst);
                if (d)
                {
                    std::memcpy(d->val, s->val, sizeof(d->val));
                    d->isSet = true;
                }
                ++mStatFollowed;
            }
        };
        for (size_t i = 0; i < e.passes.size(); ++i)
        {
            PassSync& ps = e.passes[i];
            Pass* d = ps.dst;
            PassState now;
            now.read(ps.src);
            if (!(now == ps.last))
            {
                const PassState& was = ps.last;
                if (now.ambient != was.ambient)
                    d->setAmbient(now.ambient);
                if (now.diffuse != was.diffuse)
                    d->setDiffuse(now.diffuse);
                if (now.specular != was.specular)
                    d->setSpecular(now.specular);
                if (now.emissive != was.emissive)
                    d->setSelfIllumination(now.emissive); // mesh particles: the particle colour
                if (now.shininess != was.shininess)
                    d->setShininess(now.shininess);
                if (now.tracking != was.tracking)
                    d->setVertexColourTracking(TrackVertexColourType(now.tracking));
                if (now.srcBlend != was.srcBlend || now.dstBlend != was.dstBlend ||
                    now.separateBlend != was.separateBlend || now.srcBlendAlpha != was.srcBlendAlpha ||
                    now.dstBlendAlpha != was.dstBlendAlpha)
                {
                    if (now.separateBlend)
                    {
                        d->setSeparateSceneBlending(SceneBlendFactor(now.srcBlend), SceneBlendFactor(now.dstBlend),
                            SceneBlendFactor(now.srcBlendAlpha), SceneBlendFactor(now.dstBlendAlpha));
                    }
                    else
                    {
                        d->setSceneBlending(SceneBlendFactor(now.srcBlend), SceneBlendFactor(now.dstBlend));
                        if (d->hasSeparateSceneBlending()) // same factors for alpha = plain blending
                            d->setSeparateSceneBlending(SceneBlendFactor(now.srcBlend), SceneBlendFactor(now.dstBlend),
                                SceneBlendFactor(now.srcBlend), SceneBlendFactor(now.dstBlend));
                    }
                }
                if (now.depthCheck != was.depthCheck)
                    d->setDepthCheckEnabled(now.depthCheck);
                if (now.depthWrite != was.depthWrite)
                    d->setDepthWriteEnabled(now.depthWrite);
                if (now.colourWrite != was.colourWrite)
                    d->setColourWriteEnabled(now.colourWrite);
                if (now.depthFunc != was.depthFunc)
                    d->setDepthFunction(CompareFunction(now.depthFunc));
                if (now.alphaFunc != was.alphaFunc || now.alphaValue != was.alphaValue)
                    d->setAlphaRejectSettings(CompareFunction(now.alphaFunc), (unsigned char)now.alphaValue);
                if (now.cull != was.cull)
                    d->setCullingMode(CullingMode(now.cull));
                if (now.manualCull != was.manualCull)
                    d->setManualCullingMode(ManualCullingMode(now.manualCull));
                ps.last = now;
                ++mStatFollowed;
            }
            // texture names of single-frame named units (animated units run their own controllers in the variant)
            const unsigned short units = std::min<unsigned short>(ps.src->getNumTextureUnitStates(),
                static_cast<unsigned short>(ps.textures.size()));
            for (unsigned short u = 0; u < units; ++u)
            {
                const TextureUnitState* st = ps.src->getTextureUnitState(u);
                if (st->getContentType() != TextureUnitState::CONTENT_NAMED || st->getNumFrames() != 1)
                    continue;
                const String& name = st->getTextureName();
                if (name != ps.textures[u])
                {
                    ps.textures[u] = name;
                    if (u < d->getNumTextureUnitStates())
                        d->getTextureUnitState(u)->setTextureName(name);
                    ++mStatFollowed;
                }
            }
            // B's per-instance constants (dissolve, sequence frame, ribbon, flow, rim ...)
            if (!ps.fp.empty() && ps.src->hasFragmentProgram() && d->hasFragmentProgram())
                follow(ps.src->getFragmentProgramParameters(), d->getFragmentProgramParameters(), ps.fp);
            if (!ps.vp.empty() && ps.src->hasVertexProgram() && d->hasVertexProgram())
                follow(ps.src->getVertexProgramParameters(), d->getVertexProgramParameters(), ps.vp);
        }
    }
    //----------------------------------------------------------------------------------------------
    void MaterialSystem::forgetVariant(VariantCache::iterator it, bool removeFromManager)
    {
        Material* v = it->second.variant.getPointer();
        Material* s = it->second.source.getPointer();
        for (TechniqueCache::iterator t = mTechniqueCache.begin(); t != mTechniqueCache.end();)
        {
            if ((v && t->second.owner == v) || (s && t->second.srcMat == s))
                t = mTechniqueCache.erase(t);
            else
                ++t;
        }
        if (removeFromManager && v && v != s)
        {
            MaterialPtr cur = MaterialManager::getSingleton().getByName(it->second.variant->getName());
            if (!cur.isNull() && cur.getPointer() == v)
                MaterialManager::getSingleton().remove(cur->getHandle());
        }
        mMaterialCache.erase(it);
    }
    //----------------------------------------------------------------------------------------------
    size_t MaterialSystem::purgeDeadVariants(void)
    {
        // A source only this cache still holds has no user left: the game removed it (MaterialManager::remove) and
        // destroyed what rendered it (sub-entities hold their source, billboard sets their material). Its variant
        // can go as well; before, every mesh-particle clone (unique name) left a variant behind for good.
        std::set<Material*> dead;
        MaterialManager& mm = MaterialManager::getSingleton();
        size_t purged = 0;
        for (VariantCache::iterator it = mMaterialCache.begin(); it != mMaterialCache.end();)
        {
            VariantEntry& e = it->second;
            if (!e.source.isNull() && e.source.useCount() <= 1)
            {
                dead.insert(e.source.getPointer());
                if (!e.variant.isNull() && e.variant.getPointer() != e.source.getPointer())
                {
                    dead.insert(e.variant.getPointer());
                    MaterialPtr cur = mm.getByName(e.variant->getName());
                    if (!cur.isNull() && cur.getPointer() == e.variant.getPointer())
                        mm.remove(cur->getHandle());
                }
                it = mMaterialCache.erase(it);
                ++purged;
            }
            else
            {
                ++it;
            }
        }
        for (TechniqueCache::iterator t = mTechniqueCache.begin(); t != mTechniqueCache.end();)
        {
            const TechEntry& te = t->second;
            bool drop = (te.owner && dead.count(te.owner)) || (te.srcMat && dead.count(te.srcMat));
            if (!drop && !te.owner)
                drop = mm.getByHandle(te.keyHandle).isNull(); // no variant: dropped once the material left
            if (drop)
                t = mTechniqueCache.erase(t);
            else
                ++t;
        }
        mStatPurged += purged;
        mNextPurge = std::max<size_t>(1024, mMaterialCache.size() * 2);
        mNextTechniquePurge = std::max<size_t>(4096, mTechniqueCache.size() * 2);
        return purged;
    }
    //----------------------------------------------------------------------------------------------
    void MaterialSystem::maybePurge(void)
    {
        // amortised: a sweep whenever a cache has doubled since the last one (bounded to twice the live size), and
        // every 256 entity resolutions so short-lived mesh-particle clones do not pile up (fx-audit D15)
        static size_t resolvesSincePurge = 0;
        if (++resolvesSincePurge >= 256 || mMaterialCache.size() >= mNextPurge ||
            mTechniqueCache.size() >= mNextTechniquePurge)
        {
            resolvesSincePurge = 0;
            purgeDeadVariants();
        }
    }
    //----------------------------------------------------------------------------------------------
    String MaterialSystem::getFrameStats(void) const
    {
        static double nsPerTick = 0.0;
        if (nsPerTick == 0.0)
        {
            // TSC rate against the performance counter over 20 ms (once)
            LARGE_INTEGER f, a, b;
            QueryPerformanceFrequency(&f);
            QueryPerformanceCounter(&a);
            const unsigned long long t0 = __rdtsc();
            do
            {
                QueryPerformanceCounter(&b);
            } while ((b.QuadPart - a.QuadPart) * 50 < f.QuadPart);
            const unsigned long long t1 = __rdtsc();
            const double ns = double(b.QuadPart - a.QuadPart) * 1e9 / double(f.QuadPart);
            nsPerTick = t1 > t0 ? ns / double(t1 - t0) : 0.3;
        }
        std::ostringstream o;
        o.setf(std::ios::fixed);
        o.precision(1);
        o << "render-queue hook " << mStatResolveCalls << " calls, "
          << (mStatResolveCalls ? double(mStatResolveTicks) * nsPerTick / double(mStatResolveCalls) : 0.0)
          << " ns/call, " << double(mStatResolveTicks) * nsPerTick * 1e-6 << " ms total (cached "
          << mStatHitCalls << " calls, "
          << (mStatHitCalls ? double(mStatHitTicks) * nsPerTick / double(mStatHitCalls) : 0.0)
          << " ns/call; first resolutions " << (mStatResolveCalls - mStatHitCalls) << " calls, "
          << double(mStatResolveTicks - mStatHitTicks) * nsPerTick * 1e-6 << " ms); frames " << mFrame
          << ", source checks " << mStatChecks << "; source changes followed "
          << mStatFollowed << "; variants purged " << mStatPurged << "; caches: variants " << mMaterialCache.size()
          << ", techniques " << mTechniqueCache.size();
        return o.str();
    }
    //----------------------------------------------------------------------------------------------
    String MaterialSystem::getStats(void) const
    {
        std::ostringstream o;
        o << "variant programs " << mStatVariantPrograms << ", variant materials " << mStatVariantMaterials
          << ", entities " << mStatEntities << ", tangent sets " << mStatTangentSets
          << ", fallbacks " << mStatFallbacks << ", engine sampler units " << mStatEngineUnits
          << ", fixed-function passes converted " << mStatFFPasses
          << ", texture-less passes dropped " << mStatDroppedPasses // CYS-LOGIN
          << ", shader cache hits " << GpuProgramManager::getMicrocodeCacheHits()
          << " / misses " << GpuProgramManager::getMicrocodeCacheMisses()
          << ", source changes followed " << mStatFollowed << ", variants purged " << mStatPurged; // CYS fx-render
        return o.str();
    }
}
