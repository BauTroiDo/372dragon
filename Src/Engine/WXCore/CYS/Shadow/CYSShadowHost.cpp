// CY-Source (shadow-cy): host glue of the cascaded shadow maps. See CYSShadowHost.h.
#include <cstring> // CYS-PARITY: strcmp
#include <OgrePrerequisites.h>
#include <OgreCommon.h>
#include "CYSShadowHost.h"

#include "CYSShadowPrograms.h"
#include "CYSShadowSystem.h"
#include "../../ModelSystem/WXLogicModelManager.h"

#include <OgreCamera.h>
#include <OgreFrameListener.h>
#include <OgreResourceGroupManager.h>
#include <OgreRoot.h>
#include <OgreSceneManager.h>
#include <OgreStringConverter.h>

#include <windows.h>

#include <algorithm>
#include <cstdlib>
#include <map>

namespace WX
{
    namespace
    {
        const char* const kGroup = "CYSShadow";
        bool gStarted = false;
        bool gMediaAdded = false;

        /// Gfx_Shadow* fine keys (CYSShadowConfig::apply)
        const char* const kFineKeys[] = { "Gfx_Shadow", "Gfx_ShadowSize", "Gfx_ShadowCascades", "Gfx_ShadowDistance",
            "Gfx_ShadowSplitLambda", "Gfx_ShadowSplits", "Gfx_ShadowNear", "Gfx_ShadowBias", "Gfx_ShadowSoftness",
            "Gfx_ShadowStrength", "Gfx_ShadowPbrStrength", "Gfx_ShadowBackoff", "Gfx_ShadowBlend", "Gfx_ShadowFit",
            "Gfx_ShadowDebug" };

        Ogre::String exeDirectory(void)
        {
            char path[MAX_PATH] = { 0 };
            const DWORD n = GetModuleFileNameA(NULL, path, MAX_PATH);
            Ogre::String s(path, n);
            const size_t slash = s.find_last_of("\\/");
            return slash == Ogre::String::npos ? Ogre::String(".") : s.substr(0, slash);
        }

        bool directoryExists(const Ogre::String& dir)
        {
            const DWORD a = GetFileAttributesA(dir.c_str());
            return a != INVALID_FILE_ATTRIBUTES && (a & FILE_ATTRIBUTE_DIRECTORY);
        }

        int parseLevel(const Ogre::String& value, int fallback)
        {
            Ogre::String v = value;
            Ogre::StringUtil::trim(v);
            Ogre::StringUtil::toLowerCase(v);
            if (v == "off" || v == "false" || v == "no")
                return 0;
            if (v == "low")
                return 1;
            if (v == "high" || v == "on" || v == "true")
                return 2;
            if (v.empty() || v.find_first_not_of("0123456789") != Ogre::String::npos)
                return fallback;
            const int n = Ogre::StringConverter::parseInt(v);
            return n < 0 ? 0 : (n > 2 ? 2 : n);
        }

        int gLevel = -1;

        /// "CYS shadow: stats ..." every 5 s of frames: CPU of the atlas update (fit + cull + submit) and casters per
        /// cascade. GPU / frame times: CYS_PERF=1 (CysPerf, "rtt" = render textures, i.e. mainly the atlas).
        class StatsLogger : public Ogre::FrameListener
        {
        public:
            StatsLogger(void) : mFrames(0), mCpu(0), mMax(0), mElapsed(0), mUpdates(0) {}
            bool frameEnded(const Ogre::FrameEvent& evt)
            {
                CYSShadowSystem& s = CYSShadowSystem::getSingleton();
                ++mFrames;
                mElapsed += evt.timeSinceLastFrame;
                if (s.isActive() && s.getStats().updates != mUpdates)
                {
                    mUpdates = s.getStats().updates;
                    mCpu += s.getStats().cpuMs;
                    mMax = std::max(mMax, s.getStats().cpuMs);
                    ++mSamples;
                }
                if (mElapsed >= 5.0f)
                {
                    const CYSShadowSystem::Stats& st = s.getStats();
                    char line[256];
                    _snprintf_s(line, sizeof(line), _TRUNCATE,
                        "stats: level %d, active %d, %u frames in %.1f s, atlas CPU ms avg %.3f max %.3f (%u updates), "
                        "casters %u/%u/%u/%u", gLevel, s.isActive() ? 1 : 0, mFrames, mElapsed,
                        mSamples ? mCpu / mSamples : 0.0, mMax, mSamples, (unsigned)st.casters[0], (unsigned)st.casters[1],
                        (unsigned)st.casters[2], (unsigned)st.casters[3]);
                    CYSShadowPrograms::log(line);
                    mFrames = 0;
                    mElapsed = 0;
                    mCpu = 0;
                    mMax = 0;
                    mSamples = 0;
                }
                return true;
            }
            unsigned mFrames;
            double mCpu;
            double mMax;
            float mElapsed;
            unsigned long mUpdates;
            unsigned mSamples = 0;
        };
        StatsLogger gStats;
        bool gStatsAdded = false;
    }

    // FACT (CY 3.71): Render.dll FUN_18002ec20 dispatches "View_HumanLightmap" (atoi) from VARIABLE_CHANGED; CY's
    // default System.cfg sets View_HumanLightmap=2 (Build\Logs\2026-09-14-shadow-cy\cy-re\strings).
    const char* const CYSShadowHost::kLevelKey = "View_HumanLightmap";

    //---------------------------------------------------------------------------------------------------------------
    int CYSShadowHost::defaultLevel(void)
    {
        return 2;
    }
    //---------------------------------------------------------------------------------------------------------------
    CYSShadowConfig CYSShadowHost::configForLevel(int level)
    {
        // FACT (CY 3.71, Docs\specs\render\shadow-cy_vi.md): Render.dll FUN_18002e100 calls setShadowMapEnabled(1) only
        // for View_HumanLightmap 2; 0 and 1 switch the shadow map off (1 only changes the terrain mode). The level
        // never changes the map parameters: constructor FUN_1800d7a20 = CSM, 4 cascades, 1024 texels per cascade
        // (+0x1c8), splits 668 / 1945 / 4508 / 9625 (+0x50 +0x9c +0xe8 +0x134), back-off 8000 (+0x38), blend 0.005;
        // AutoParamDataSource bias defaults const 5 / normal 20 world units (CY/B OgreMain), EnvKey strengths.
        CYSShadowConfig cfg;
        if (level < 2)
        {
            cfg.mode = CYSShadowConfig::MODE_OFF;
        }
        else
        {
            cfg.mode = CYSShadowConfig::MODE_CSM;
            // CYS-PARITY (d3d9-trace, Docs/specs/render/d3d9-parity_vi.md L1): FACT d3d9 trace of CY 3.71 at run time,
            // login erengu_DL and Dali (cy-oracle world, 3 frames): ONE 4096x4096 R32F map, receivers
            // shadow_param (1,1,4096,0), shadow_csm_param (1, 1, 0.005, 8000), isystem_userdata (8,0,0,20), 300..730
            // caster draws. The constructor values below (4 x 1024, splits 668..9625, bias 5) are replaced at run time.
            // CYS_PARITY_SHADOW=ctor restores them.
            const char* cysAb = std::getenv("CYS_PARITY_SHADOW");
            if (!(cysAb && std::strcmp(cysAb, "ctor") == 0))
            {
                cfg.mapSize = 4096;
                cfg.cascadeCount = 1;
                cfg.splits.clear();
                cfg.splits.push_back(8000.0f);
                cfg.maxDistance = 8000.0f;
                cfg.constBias = 8.0f;
                cfg.normalBias = 20.0f;
                cfg.backoff = 8000.0f;
                cfg.blendBand = 0.005f;
                // CYS-PARITY: FACT CY ortho 9,422 x 7,555 at w09 = the per-frame AABB fit (tight 9,701 x 7,684 with the
                // same depth scale; stable 11,314^2). Coordinator 15/09: default like CY; CYS_SHADOW_FIT=stable or
                // Gfx_ShadowFit=stable keeps the shimmer-free fit for A/B (applied after this by readConfig).
                cfg.fit = CYSShadowConfig::FIT_TIGHT;
                cfg.validate();
                return cfg;
            }
            cfg.mapSize = 1024;
            cfg.cascadeCount = 4;
            cfg.splits.clear();
            cfg.splits.push_back(668.0f);
            cfg.splits.push_back(1945.0f);
            cfg.splits.push_back(4508.0f);
            cfg.splits.push_back(9625.0f);
            cfg.constBias = 5.0f;
            cfg.normalBias = 20.0f;
            cfg.backoff = 8000.0f;
            cfg.blendBand = 0.005f;
        }
        cfg.validate();
        return cfg;
    }
    //---------------------------------------------------------------------------------------------------------------
    CYSShadowConfig CYSShadowHost::readConfig(Lookup lookup, void* user)
    {
        int level = defaultLevel();
        Ogre::String value;
        if (lookup && lookup(user, kLevelKey, value))
            level = parseLevel(value, level);
        const char* env = std::getenv("CYS_SHADOW_LEVEL");
        if (env && *env)
            level = parseLevel(env, level);
        CYSShadowConfig cfg = configForLevel(level);
        std::map<Ogre::String, Ogre::String> kv;
        for (size_t i = 0; lookup && i < sizeof(kFineKeys) / sizeof(kFineKeys[0]); ++i)
            if (lookup(user, kFineKeys[i], value))
                kv[kFineKeys[i]] = value;
        if (!kv.empty())
            cfg.apply(kv);
        cfg.applyEnvironment();
        gLevel = level;
        return cfg;
    }
    //---------------------------------------------------------------------------------------------------------------
    Ogre::String CYSShadowHost::shaderDefine(const CYSShadowConfig& config)
    {
        const int t = config.shaderType();
        return t ? Ogre::StringConverter::toString(t) : Ogre::StringUtil::BLANK;
    }
    //---------------------------------------------------------------------------------------------------------------
    bool CYSShadowHost::start(const CYSShadowConfig& config, Ogre::SceneManager* sceneManager, Ogre::Camera* camera)
    {
        if (config.mode == CYSShadowConfig::MODE_OFF)
        {
            CYSShadowPrograms::log("host: shadows off (" + Ogre::String(kLevelKey) + " = 0)");
            return false;
        }
        if (!sceneManager || !camera)
            return false;
        Ogre::ResourceGroupManager& rgm = Ogre::ResourceGroupManager::getSingleton();
        if (!gMediaAdded)
        {
            const Ogre::StringVector groups = rgm.getResourceGroups();
            if (std::find(groups.begin(), groups.end(), Ogre::String(kGroup)) == groups.end())
                rgm.createResourceGroup(kGroup);
            const Ogre::String exe = exeDirectory();
            const Ogre::String dirs[] = { exe + "\\Media\\CysShadow", exe + "\\CysShadow", exe + "\\..\\Media\\CysShadow" };
            for (size_t i = 0; i < sizeof(dirs) / sizeof(dirs[0]); ++i)
            {
                if (directoryExists(dirs[i]))
                {
                    try
                    {
                        rgm.addResourceLocation(dirs[i], "FileSystem", kGroup, false);
                        CYSShadowPrograms::log("host: media " + dirs[i]);
                    }
                    catch (const Ogre::Exception& e)
                    {
                        CYSShadowPrograms::log("host: media " + dirs[i] + " failed: " + e.getDescription());
                    }
                    break;
                }
            }
            gMediaAdded = true;
        }
        CYSShadowSystem& shadows = CYSShadowSystem::getSingleton();
        if (!shadows.initialise(config, kGroup))
            return false;
        shadows.attach(sceneManager, camera);
        if (LogicModelManager::getSingletonPtr())
            LogicModelManager::getSingleton().setShadowCastable(true); // actors, monsters, NPCs, mounts cast
        gStarted = true;
        if (!gStatsAdded && Ogre::Root::getSingletonPtr())
        {
            Ogre::Root::getSingleton().addFrameListener(&gStats);
            gStatsAdded = true;
        }
        CYSShadowPrograms::log("host: started, level " + Ogre::StringConverter::toString(gLevel) + ", " +
                               config.describe());
        return true;
    }
    //---------------------------------------------------------------------------------------------------------------
    bool CYSShadowHost::applyVariable(const Ogre::String& key, const Ogre::String& value)
    {
        const bool level = Ogre::StringUtil::match(key, kLevelKey, false);
        bool fine = false;
        for (size_t i = 0; i < sizeof(kFineKeys) / sizeof(kFineKeys[0]) && !fine; ++i)
            fine = Ogre::StringUtil::match(key, kFineKeys[i], false);
        if (!level && !fine)
            return false;
        if (!gStarted)
        {
            CYSShadowPrograms::log("host: " + key + " = " + value + " ignored: shadows were off at start-up (restart)");
            return true;
        }
        CYSShadowSystem& shadows = CYSShadowSystem::getSingleton();
        CYSShadowConfig cfg = shadows.getConfig();
        if (level)
        {
            const int n = parseLevel(value, gLevel < 0 ? defaultLevel() : gLevel);
            if (n == 0)
            {
                shadows.setEnabled(false);
                gLevel = 0;
                CYSShadowPrograms::log("host: shadows disabled at run time");
                return true;
            }
            CYSShadowConfig next = configForLevel(n);
            cfg.mode = next.mode;
            cfg.mapSize = next.mapSize;
            cfg.cascadeCount = next.cascadeCount;
            cfg.maxDistance = next.maxDistance;
            cfg.splits = next.splits;
            gLevel = n;
        }
        else
        {
            std::map<Ogre::String, Ogre::String> kv;
            kv[key] = value;
            cfg.apply(kv);
        }
        shadows.initialise(cfg, kGroup);
        shadows.setEnabled(cfg.mode != CYSShadowConfig::MODE_OFF);
        CYSShadowPrograms::log("host: " + key + " = " + value + " -> " + cfg.describe());
        return true;
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowHost::onSceneLoaded(const Ogre::String& sceneFile)
    {
        // FACT (CY 3.71 Render.dll, Build\Logs\2026-09-14-shadow-cy\cy-re\decomp\03): after the login scene
        // erengu_DL.Scene the client calls setShadowMapEnabled(1) + setShadowDis(18000, 1000) (FUN_18002b5e0);
        // the character screen tl3chuangjian.Scene calls setShadowMapEnabled(0) (FUN_18002b710).
        if (!gStarted)
            return;
        Ogre::String name = sceneFile;
        Ogre::StringUtil::toLowerCase(name);
        const bool charScreen = name.find("chuangjian") != Ogre::String::npos;
        const bool loginScreen = name.find("erengu") != Ogre::String::npos;
        CYSShadowSystem& shadows = CYSShadowSystem::getSingleton();
        if (charScreen)
        {
            if (shadows.isEnabled())
            {
                shadows.setEnabled(false);
                CYSShadowPrograms::log("host: scene " + name + ": shadows off (character screen, as CY)");
            }
            return;
        }
        const Ogre::Real backoff = loginScreen ? Ogre::Real(18000) : Ogre::Real(8000);
        if (shadows.getConfig().backoff != backoff)
        {
            shadows.setBackoff(backoff);
            CYSShadowPrograms::log("host: scene " + name + ": caster back-off " +
                                   Ogre::StringConverter::toString(backoff));
        }
        const bool on = gLevel >= 2;
        if (on != shadows.isEnabled())
        {
            shadows.setEnabled(on);
            CYSShadowPrograms::log("host: scene " + name + ": shadows " + (on ? "on" : "off") + " (level " +
                                   Ogre::StringConverter::toString(gLevel) + ")");
        }
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowHost::stop(void)
    {
        if (gStatsAdded && Ogre::Root::getSingletonPtr())
            Ogre::Root::getSingleton().removeFrameListener(&gStats);
        gStatsAdded = false;
        if (!gStarted)
            return;
        CYSShadowSystem::getSingleton().shutdown();
        gStarted = false;
    }
    //---------------------------------------------------------------------------------------------------------------
    bool CYSShadowHost::isStarted(void)
    {
        return gStarted;
    }
}
