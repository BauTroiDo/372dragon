// CY-Source (post-processing agent, 2026-09-12): registration, media and configuration - see CysPostFx.h.
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>

#include "CysPostFx.h"
#include "CysPostFxPipeline.h"
#include "PostFilter/WXPostFilterManager.h"
#include "PostFilter/WXPostFilter.h"
#include "PostFilter/WXPostFilterFactory.h"

#include <OgreRoot.h>
#include <OgreResourceGroupManager.h>
#include <OgreMaterialManager.h>
#include <OgreTextureManager.h>
#include <OgreImage.h>
#include <OgreDataStream.h>
#include <OgreException.h>
#include <OgreStringConverter.h>
#include <OgreViewport.h>

#include <cmath>
#include <cstdlib>
#include <fstream>
#include <map>
#include <set>
#include <vector>

namespace WX
{
    PostFilterFactory* getCysGenSSAOFactory(void);
    PostFilterFactory* getCysFXAAFactory(void);
    PostFilterFactory* getCysFXAAQualityFactory(void);
    PostFilterFactory* getCysDLAAFactory(void);
    PostFilterFactory* getCysDoFFactory(void);
    PostFilterFactory* getCysComplexBlurFactory(void);   // CYS-FX (fx-cy): skill ComplexBlur
    PostFilterFactory* getCysNewHDRBloomFactory(void);
    PostFilterFactory* getCysColorLUTFactory(void);
    PostFilterFactory* getCysHeightFogFactory(void);
    PostFilterFactory* getCysGodRaysFactory(void);
    PostFilterFactory* getCysWaterFactory(void);   // CYS-WATER: CYS/Water/CysWaterRender.cpp

    namespace
    {
        const String kGroup("CysPostFX");
        String gMediaDir;
        bool gMediaReady = false;
        bool gMediaTried = false;
        bool gMaster = true;                    ///< Gfx_PostFX
        std::map<String, bool> gRequested;      ///< filter type -> requested by the configuration
        std::set<String> gSuspended;            ///< CYS fx-render: held off by the scene (B: login / character)
        // CYS-LUT: per-scene ColorLUT as CY 3.71 (Docs/specs/render/colorlut-cy_vi.md)
        int gHumanLightmap = 2;                 ///< View_HumanLightmap (CY System.cfg default 2); 2 = ColorLUT on
        String gLutMode = "auto";               ///< Gfx_ColorLUT: auto (CY rule) | on | off | file
        String gLutFile;                        ///< Gfx_ColorLUT = <file.png>
        String gSceneLut;                       ///< LUT of the current scene (CY table), "" = none
        String gSceneName;                      ///< base name of the current scene
        bool gLutEnvRead = false;
        String gLutEnv;                         ///< CYS_COLORLUT (A/B): 0 | 1 | auto | <file.png>






        bool gCyHdr = true;                     ///< PostFX.HDRMode = cy | gl (CYS_COLOR = cy | gl wins)
        bool gColorEnvRead = false;
        String gColorEnv;                       ///< CYS_COLOR (A/B)
        bool gHdrBloomExplicit = false;         ///< Gfx_HDRBloom = 1 set by the host / command line: kept on scenes
        bool gLegacyHdrLogged = false;







        bool gAaEnvRead = false;
        String gAaMode = "fxaa";                ///< PostFX.AAMode
        String gAaEnv;                          ///< CYS_AA
        String gTexFilterEnv;                   ///< CYS_TEXFILTER
        String gTexFilterWorld;                 ///< CYS-PARITY (S1): last View_TextureFiltering value (world scenes)
        bool gTexFilterLoginScreen = false;     ///< CYS-PARITY (S1): a login / character screen is loaded
        CysPostFx::PassObserver gObserver = 0;  ///< CYS fx-render: profiling hook
        void* gObserverUser = 0;

        /// CYS fx-render: start-up keys in the order they are applied, with the shipped default ("" = host value
        /// only). CYS-COLOR: defaults = CY 3.71 (installed Bin\System.cfg: View_Fanhunjiao=0, View_HDRFilter=0,
        /// View_HumanLightmap=2; NewHDRBloom off in the world, see gCyHdr). client_GL's set (View_Fanhunjiao=1,
        /// View_HDRFilter=1 -> NewHDRBloom) = PostFX.HDRMode=gl + those two keys. HeightFog follows the scene
        /// environment; SSAO/GodRays/DoF are never on; ColorLUT follows the CY scene table.
        struct KeyDefault
        {
            const char* key;
            const char* value;
        };
        const KeyDefault kStartupKeys[] =
        {
            { "Gfx_PostFX", "1" },
            { "PostFX.Media", "" },
            { "PostFX.Preset", "b" },       // CYS fx-render: b = client_GL exact (8-bit, B's NewHDRBloom) | cinematic
            { "PostFX.HDRMode", "cy" },     // CYS-COLOR: cy = CY 3.71 HDR rule | gl = client_GL (View_HDRFilter -> NewHDRBloom)
            { "PostFX.AAMode", "fxaa" },    // CYS-AA: fxaa = CY's FXAA option on at start-up | cy = View_Fanhunjiao as CY
            { "View_Fanhunjiao", "0" },     // CYS-COLOR: CY System.cfg (client_GL: 1); CYS-AA: PostFX.AAMode decides 0
            { "Gfx_AA", "" },
            { "View_TextureFiltering", "2" },
            { "View_HDRFilter", "0" },      // CYS-COLOR: CY System.cfg (client_GL: 1)
            { "Gfx_HDRBloom", "" },
            { "View_FullScreenLight", "" },
            { "Gfx_HeightFog", "1" },
            { "Gfx_SSAO", "0" },
            { "Gfx_GodRays", "0" },
            { "Gfx_DoF", "0" },
            { "Gfx_ColorLUT", "auto" },     // CYS-LUT: CY rule (scene LUT at View_HumanLightmap 2)
            { "View_HumanLightmap", "2" },  // CYS-LUT: CY System.cfg default; the host value wins
        };

        const char* const kCysTypes[] =
        {
            "GenSSAO", "FXAA", "FXAAQuality", "DLAA", "DoF", "NewHDRBloom", "ColorLUT", "HeightFog", "GodRays"
        };
        const char* const kAATypes[] = { "FXAA", "FXAAQuality", "DLAA" };

        bool isCysType(const String& type)
        {
            for (size_t i = 0; i < sizeof(kCysTypes) / sizeof(kCysTypes[0]); ++i)
            {
                if (type == kCysTypes[i])
                    return true;
            }
            return false;
        }

        String trim(const String& s)
        {
            const char* ws = " \t\r\n";
            const size_t b = s.find_first_not_of(ws);
            if (b == String::npos)
                return String();
            return s.substr(b, s.find_last_not_of(ws) - b + 1);
        }

        String exeDirectory(void)
        {
            char buffer[MAX_PATH * 2] = { 0 };
            const DWORD n = GetModuleFileNameA(NULL, buffer, sizeof(buffer));
            String p(buffer, n);
            const size_t s = p.find_last_of("\\/");
            return s == String::npos ? String(".") : p.substr(0, s);
        }

        String sourceMediaDirectory(void)
        {
            const String f = __FILE__;                  // absolute at build time (development trees)
            const size_t s = f.find_last_of("\\/");
            return s == String::npos ? String() : f.substr(0, s) + "\\media";
        }

        String environmentVariable(const char* name)
        {
            char buffer[1024] = { 0 };
            const DWORD n = GetEnvironmentVariableA(name, buffer, sizeof(buffer));
            return (n > 0 && n < sizeof(buffer)) ? String(buffer, n) : String();
        }

        bool fileExists(const String& path)
        {
            const DWORD a = GetFileAttributesA(path.c_str());
            return a != INVALID_FILE_ATTRIBUTES && !(a & FILE_ATTRIBUTE_DIRECTORY);
        }

        /// 4x4 random rotations for the SSAO kernel (xy in R, G).
        void createNoiseTexture(void)
        {
            const String name("CysPostFX/SSAONoise");
            Ogre::TextureManager* tm = Ogre::TextureManager::getSingletonPtr();
            if (!tm || !tm->getByName(name).isNull())
                return;
            static Ogre::uchar pixels[4 * 4 * 4];
            unsigned int seed = 0x2545F491u;
            for (int i = 0; i < 16; ++i)
            {
                seed = seed * 1664525u + 1013904223u;
                const float a = (float)(seed >> 8) * (1.0f / 16777216.0f) * 6.28318531f;
                pixels[i * 4 + 0] = 0;                                                      // B
                pixels[i * 4 + 1] = (Ogre::uchar)((std::sin(a) * 0.5f + 0.5f) * 255.0f + 0.5f); // G
                pixels[i * 4 + 2] = (Ogre::uchar)((std::cos(a) * 0.5f + 0.5f) * 255.0f + 0.5f); // R
                pixels[i * 4 + 3] = 255;                                                    // A
            }
            try
            {
                Ogre::Image img;
                img.loadDynamicImage(pixels, 4, 4, 1, Ogre::PF_A8R8G8B8);
                tm->loadImage(name, Ogre::ResourceGroupManager::INTERNAL_RESOURCE_GROUP_NAME, img, Ogre::TEX_TYPE_2D, 0);
            }
            catch (Ogre::Exception& e)
            {
                CysPostFxUtil::log("CysPostFX: SSAO noise texture failed: " + e.getDescription());
            }
        }

        PostFilter* findFilter(PostFilterManager* m, const String& type)
        {
            return (m && m->hasPostFilter(type)) ? m->getPostFilter(type) : 0;
        }

        /// Requested by the configuration and not held off by Gfx_PostFX (CY-Source filters) or by the scene.
        bool effectiveState(const String& type)
        {
            std::map<String, bool>::const_iterator it = gRequested.find(type);
            const bool requested = it != gRequested.end() && it->second;
            return requested && (gMaster || !isCysType(type)) && gSuspended.find(type) == gSuspended.end();
        }

        void applyState(PostFilter* f, const String& type)
        {
            try
            {
                f->setEnabled(effectiveState(type));
            }
            catch (Ogre::Exception& e)
            {
                CysPostFxUtil::log("CysPostFX: " + type + ": " + e.getDescription());
            }
        }

        void request(PostFilterManager* m, Ogre::Viewport* vp, const String& type, bool on)
        {
            gRequested[type] = on;
            PostFilter* f = on ? CysPostFx::ensureFilter(m, vp, type) : findFilter(m, type);
            if (f)
                applyState(f, type);
        }

        // ---- CYS-LUT: per-scene ColorLUT as CY 3.71 ----------------------------------------------------------
        String sceneBaseName(const String& sceneFile)
        {
            String n = sceneFile;
            const size_t slash = n.find_last_of("\\/");
            if (slash != String::npos)
                n = n.substr(slash + 1);
            const size_t dot = n.find_last_of('.');
            if (dot != String::npos && CysPostFxUtil::toLowerAscii(n.substr(dot)) == ".scene")
                n = n.substr(0, dot);
            return CysPostFxUtil::toLowerAscii(trim(n));
        }

        bool lutResourceExists(const String& name)
        {
            Ogre::ResourceGroupManager* rgm = Ogre::ResourceGroupManager::getSingletonPtr();
            if (!rgm || name.empty())
                return false;
            if (!Ogre::TextureManager::getSingleton().getByName(name).isNull())
                return true;
            const Ogre::StringVector& groups = rgm->getResourceGroups();
            for (size_t i = 0; i < groups.size(); ++i)
            {
                try
                {
                    if (rgm->resourceExists(groups[i], name))
                        return true;
                }
                catch (Ogre::Exception&)
                {
                }
            }
            return false;
        }





        void applyColorLut(PostFilterManager* manager, Ogre::Viewport* viewport, const char* why)
        {
            if (!gLutEnvRead)
            {
                gLutEnvRead = true;
                gLutEnv = trim(environmentVariable("CYS_COLORLUT"));
                if (!gLutEnv.empty())
                    CysPostFxUtil::log("CysPostFX: ColorLUT: CYS_COLORLUT=" + gLutEnv + " overrides Gfx_ColorLUT");
            }
            String mode = gLutMode, file = gLutFile;
            if (!gLutEnv.empty())
            {
                const String e = CysPostFxUtil::toLowerAscii(gLutEnv);
                if (e == "0" || e == "off")
                    mode = "off";
                else if (e == "1" || e == "on")
                    mode = "on";
                else if (e == "auto" || e == "cy")
                    mode = "auto";
                else
                {
                    mode = "file";
                    file = gLutEnv;
                }
            }
            const String lut = mode == "file" ? file : gSceneLut;
            bool on = false;
            if (mode == "off")
                on = false;
            else if (mode == "on")
                on = true;                                       // the scene LUT, else the filter's own LUT_00.png
            else if (mode == "file")
                on = !lut.empty();
            else                                                 // auto = CY: level 2 and the scene has a LUT
                on = gHumanLightmap >= 2 && !lut.empty();
            if (on && !lut.empty() && !lutResourceExists(lut))
            {
                CysPostFxUtil::log("CysPostFX: ColorLUT: LUT " + lut + " not found in the resources - filter skipped");
                on = false;
            }
            if (on)
            {
                PostFilter* f = CysPostFx::ensureFilter(manager, viewport, "ColorLUT");
                if (f && !lut.empty())
                {
                    try
                    {
                        f->setParameter("LUTImage", lut);
                        f->setParameter("destAmount", "1");      // CY: DAT_1802c1d28 "1", no blend
                    }
                    catch (Ogre::Exception& e)
                    {
                        CysPostFxUtil::log("CysPostFX: ColorLUT: " + e.getDescription());
                    }
                }
            }
            request(manager, viewport, "ColorLUT", on);
            CysPostFxUtil::log("CysPostFX: ColorLUT " + String(on ? "on" : "off") + " (" + why + "): mode " + mode +
                               ", View_HumanLightmap " + Ogre::StringConverter::toString(gHumanLightmap) +
                               ", scene " + (gSceneName.empty() ? String("-") : gSceneName) + ", lut " +
                               (lut.empty() ? String("-") : lut));
        }

        // ---- CYS-AA: texture filtering + anti-aliasing as CY 3.71 -------------------------------------------
        void readAaEnvironment(void)
        {
            if (gAaEnvRead)
                return;
            gAaEnvRead = true;
            gAaEnv = CysPostFxUtil::toLowerAscii(trim(environmentVariable("CYS_AA")));
            gTexFilterEnv = CysPostFxUtil::toLowerAscii(trim(environmentVariable("CYS_TEXFILTER")));
            if (!gAaEnv.empty() || !gTexFilterEnv.empty())
                CysPostFxUtil::log("CysPostFX: AA override CYS_AA=" + (gAaEnv.empty() ? String("-") : gAaEnv) +
                                   " CYS_TEXFILTER=" + (gTexFilterEnv.empty() ? String("-") : gTexFilterEnv));
        }








        bool loginTextureFilteringParity(void)
        {
            static const bool on = []() {
                const char* e = getenv("CYS_PARITY_LOGIN_TEXFILTER");
                return !(e && e[0] == '0');
            }();
            return on;
        }
        bool applyTextureFiltering(const String& value, const char* why);
        void applySceneTextureFiltering(bool loginScreen)
        {
            gTexFilterLoginScreen = loginScreen;
            readAaEnvironment();
            if (!loginTextureFilteringParity() || !gTexFilterEnv.empty())
                return;
            if (loginScreen)
                applyTextureFiltering("0", "login / character screen as CY");
            else
                applyTextureFiltering(gTexFilterWorld.empty() ? String("2") : gTexFilterWorld, "world scene");
        }
        bool applyTextureFiltering(const String& value, const char* why)
        {
            Ogre::MaterialManager* mm = Ogre::MaterialManager::getSingletonPtr();
            if (!mm)
                return false;
            const String v = CysPostFxUtil::toLowerAscii(trim(value));
            if (v.empty() || v == "ogre" || v == "default")
            {
                CysPostFxUtil::log(String("CysPostFX: View_TextureFiltering left at OGRE's default (") + why + ")");
                return true;
            }
            switch (std::atoi(v.c_str()))
            {
            case 0:
                mm->setDefaultTextureFiltering(Ogre::TFO_BILINEAR);
                mm->setDefaultAnisotropy(1);
                break;
            case 1:
                mm->setDefaultTextureFiltering(Ogre::TFO_TRILINEAR);
                mm->setDefaultAnisotropy(2);
                break;
            case 2:
                mm->setDefaultTextureFiltering(Ogre::TFO_ANISOTROPIC);
                mm->setDefaultAnisotropy(8);
                break;
            default:
                CysPostFxUtil::log("CysPostFX: View_TextureFiltering=" + value + " ignored (CY: 0/1/2 only)");
                return true;
            }
            CysPostFxUtil::log("CysPostFX: View_TextureFiltering=" + v + " (" + why + "): min/mag/mip " +
                Ogre::StringConverter::toString(int(mm->getDefaultTextureFiltering(Ogre::FT_MIN))) + "/" +
                Ogre::StringConverter::toString(int(mm->getDefaultTextureFiltering(Ogre::FT_MAG))) + "/" +
                Ogre::StringConverter::toString(int(mm->getDefaultTextureFiltering(Ogre::FT_MIP))) + " anisotropy " +
                Ogre::StringConverter::toString(mm->getDefaultAnisotropy()));
            return true;
        }

        /// CYS-AA start-up rule. The effective mode is CYS_AA when set, else PostFX.AAMode:
        ///   cy          View_Fanhunjiao as CY 3.71 (0 = no AA) and no start-up View_TextureFiltering (CY's Render.dll
        ///               only reacts to VARIABLE_CHANGED: the running CY client keeps OGRE's bilinear filtering,
        ///               MaterialManager +0xB0 = 2 2 1 1 read at the login screen)
        ///   fxaa        CY's FXAA option (View_Fanhunjiao 1, the CY shader AntiAlias.hlsl FXAA_PS_NOLUMA) when the
        ///   fxaaquality configuration leaves it at 0; View_TextureFiltering from the configuration (CY ships 2)
        ///   dlaa        idem with CY's other anti-aliasing filters
        ///   none        no AA whatever View_Fanhunjiao says
        /// Run-time changes (the setup UI) still go straight through applyVariable. Returns true when it changed value.
        bool startupAaOverride(const String& key, String& value, String& note)
        {
            readAaEnvironment();
            const String mode = gAaEnv.empty() ? gAaMode : gAaEnv;
            const String k = CysPostFxUtil::toLowerAscii(key);
            if (k == "view_fanhunjiao")
            {
                String want;
                if (mode == "none" || mode == "off" || mode == "0")
                    want = "0";
                else if ((mode == "fxaa" || mode == "fxaaquality" || mode == "dlaa") && std::atoi(value.c_str()) <= 0)
                    want = mode;
                if (want.empty() || want == value)
                    return false;
                note = " [CYS-AA " + mode + ": View_Fanhunjiao " + (value.empty() ? String("-") : value) + "->" + want + "]";
                value = want;
                return true;
            }
            if (k == "view_texturefiltering" && mode == "cy" && gTexFilterEnv.empty())
            {
                note = " [CYS-AA cy: View_TextureFiltering " + value + " not applied at start-up]";
                value.clear();
                return true;
            }
            return false;
        }
    }

    namespace CysPostFx
    {
        void registerFactories(PostFilterManager* manager)
        {
            if (!manager)
                return;
            PostFilterFactory* factories[] =
            {
                getCysGenSSAOFactory(), getCysFXAAFactory(), getCysFXAAQualityFactory(), getCysDLAAFactory(),
                getCysDoFFactory(), getCysNewHDRBloomFactory(), getCysColorLUTFactory(), getCysHeightFogFactory(),
                getCysGodRaysFactory(), getCysWaterFactory(),   // CYS-WATER
                getCysComplexBlurFactory()   // CYS-FX (fx-cy)
            };
            for (size_t i = 0; i < sizeof(factories) / sizeof(factories[0]); ++i)
            {
                const PostFilterManager::PostFilterFactoryList& known = manager->getFactoryList();
                if (known.find(factories[i]->getType()) == known.end())
                    manager->registerFactory(factories[i]);
            }
        }
        //-------------------------------------------------------------------
        void setMediaDirectory(const String& directory)
        {
            gMediaDir = directory;
            gMediaTried = false;
        }
        //-------------------------------------------------------------------
        const String& getResourceGroup(void)
        {
            return kGroup;
        }
        //-------------------------------------------------------------------
        bool initialiseMedia(void)
        {
            if (gMediaReady)
                return true;
            Ogre::MaterialManager* mm = Ogre::MaterialManager::getSingletonPtr();
            Ogre::ResourceGroupManager* rgm = Ogre::ResourceGroupManager::getSingletonPtr();
            if (!mm || !rgm)
                return false;
            try
            {
                rgm->createResourceGroup(kGroup);
            }
            catch (Ogre::Exception&)
            {
                // exists already
            }
            createNoiseTexture();
            if (!mm->getByName("CysPostFX/Final").isNull())
            {
                gMediaReady = true;                     // the host loaded the media itself
                return true;
            }
            if (gMediaTried)
                return false;
            gMediaTried = true;

            std::vector<String> dirs;
            if (!gMediaDir.empty())
                dirs.push_back(gMediaDir);
            const String env = environmentVariable("CYS_POSTFX_MEDIA");
            if (!env.empty())
                dirs.push_back(env);
            const String exe = exeDirectory();
            dirs.push_back(exe + "\\CysPostFX");
            dirs.push_back(exe + "\\Media\\CysPostFX");         // CYS fx-render: next to Media\Scorpio (stage.ps1)
            dirs.push_back(exe + "\\..\\Media\\CysPostFX");
            dirs.push_back(sourceMediaDirectory());
            String found;
            for (size_t i = 0; i < dirs.size() && found.empty(); ++i)
            {
                if (!dirs[i].empty() && fileExists(dirs[i] + "\\CysPostFX.material"))
                    found = dirs[i];
            }
            if (found.empty())
            {
                CysPostFxUtil::log("CysPostFX: CysPostFX.material not found (PostFX.Media, %CYS_POSTFX_MEDIA%, "
                                   "<exe>\\CysPostFX, <exe>\\..\\Media\\CysPostFX)");
                return false;
            }
            try
            {
                // The script is parsed directly (the group may never be initialised by the host); programs open
                // their .hlsl through the group, B's files come from MaterialTemplates.zip (other groups).
                rgm->addResourceLocation(found, "FileSystem", kGroup, false);
                Ogre::DataStreamPtr stream = rgm->openResource("CysPostFX.material", kGroup);
                mm->parseScript(stream, kGroup);
            }
            catch (Ogre::Exception& e)
            {
                CysPostFxUtil::log("CysPostFX: loading " + found + " failed: " + e.getFullDescription());
            }
            gMediaReady = !mm->getByName("CysPostFX/Final").isNull();
            CysPostFxUtil::log("CysPostFX: media " + found + (gMediaReady ? " loaded" : " could not be loaded"));
            return gMediaReady;
        }
        //-------------------------------------------------------------------
        PostFilter* ensureFilter(PostFilterManager* manager, Ogre::Viewport* viewport, const String& type)
        {
            if (!manager)
                return 0;
            if (manager->hasPostFilter(type))
                return manager->getPostFilter(type);
            const PostFilterManager::PostFilterFactoryList& factories = manager->getFactoryList();
            if (!viewport || factories.find(type) == factories.end())
                return 0;
            try
            {
                return manager->createPostFilter(type, viewport);
            }
            catch (Ogre::Exception& e)
            {
                CysPostFxUtil::log("CysPostFX: cannot create post filter " + type + ": " + e.getDescription());
                return 0;
            }
        }
        //-------------------------------------------------------------------
        bool applyVariable(PostFilterManager* manager, Ogre::Viewport* viewport, const String& key, const String& value)
        {
            const String k = CysPostFxUtil::toLowerAscii(trim(key));
            const String v = trim(value);
            const String lv = CysPostFxUtil::toLowerAscii(v);
            const bool on = CysPostFxUtil::parseBool(v, std::atoi(v.c_str()) != 0);

            if (k == "postfx.media")
            {
                setMediaDirectory(v);
                return true;
            }
            if (k == "postfx.preset")                           // CYS fx-render: b (default) | cinematic
            {
                const bool cinematic = lv == "cinematic" || lv == "cys" || lv == "hdr";
                CysPostFxPipeline::setCinematic(cinematic);
                PostFilter* f = findFilter(manager, "NewHDRBloom");
                if (f)
                {
                    try
                    {
                        f->setParameter("Mode", cinematic ? "Cinematic" : "B");
                    }
                    catch (Ogre::Exception&)
                    {
                    }
                }
                CysPostFxUtil::log(cinematic ? "CysPostFX: preset cinematic (FP16 targets, CY-Source NewHDRBloom)"
                                             : "CysPostFX: preset b (client_GL: 8-bit targets, B's NewHDRBloom)");
                return true;
            }
            if (k == "postfx.hdrmode")                          // CYS-COLOR: cy (default) | gl
            {
                if (!gColorEnvRead)
                {
                    gColorEnvRead = true;
                    const char* env = std::getenv("CYS_COLOR");
                    gColorEnv = env ? CysPostFxUtil::toLowerAscii(trim(env)) : String();
                }
                const String mode = gColorEnv.empty() ? lv : gColorEnv;
                gCyHdr = mode != "gl" && mode != "b" && mode != "client_gl";
                CysPostFxUtil::log(String("CysPostFX: HDR rule ") + (gCyHdr
                    ? "cy (View_HDRFilter = legacy HDR filter; NewHDRBloom off in the world as CY 3.71)"
                    : "gl (client_GL: View_HDRFilter -> NewHDRBloom)") + (gColorEnv.empty() ? "" : " [CYS_COLOR]"));
                if (gCyHdr && !gHdrBloomExplicit)
                    request(manager, viewport, "NewHDRBloom", false);
                return true;
            }
            if (k == "view_hdrfilter" && gCyHdr)                // CYS-COLOR: CY Render.dll 0x308 -> legacy "HDR"
            {
                if (!gLegacyHdrLogged || on)
                {
                    CysPostFxUtil::log("CysPostFX: View_HDRFilter=" + v + " selects CY's legacy HDR filter (Render.dll "
                                       "FUN_18002ced0); not built in CY-Source, NewHDRBloom unchanged");
                    gLegacyHdrLogged = true;
                }
                return true;
            }
            if (k == "view_hdrfilter" || k == "gfx_hdrbloom")   // B: View_HDRFilter -> NewHDRBloom
            {
                if (k == "gfx_hdrbloom")
                    gHdrBloomExplicit = on;                      // CYS-COLOR: explicit request survives scene changes
                request(manager, viewport, "NewHDRBloom", on);
                return true;
            }
            if (k == "view_fullscreenlight")                     // 0.85 / B: full-screen glow (Floodlighting)
            {
                request(manager, viewport, "Floodlighting", on);
                return true;
            }
            if (k == "view_texturefiltering")
            {
                readAaEnvironment();
                if (!gTexFilterEnv.empty())
                    return applyTextureFiltering(gTexFilterEnv, "CYS_TEXFILTER");
                gTexFilterWorld = v;
                if (gTexFilterLoginScreen && loginTextureFilteringParity())
                    return true;                                 // CYS-PARITY (S1): applied when a world scene loads
                return applyTextureFiltering(v, "View_TextureFiltering");
            }
            if (k == "postfx.aamode")                           // CYS-AA: fxaa (default) | cy | none | fxaaquality | dlaa
            {
                gAaMode = lv.empty() ? String("fxaa") : lv;
                return true;
            }
            if (k == "view_fanhunjiao" || k == "gfx_aa")         // B: View_Fanhunjiao -> FXAA
            {
                String type;
                if (lv == "fxaa" || lv == "1")
                    type = "FXAA";
                else if (lv == "fxaaquality" || lv == "2")
                    type = "FXAAQuality";
                else if (lv == "dlaa" || lv == "3")
                    type = "DLAA";
                if (k == "view_fanhunjiao" && std::atoi(v.c_str()) > 0)
                    type = "FXAA";                               // 0.85 stored the MSAA level (1/2/4) here
                CysPostFxUtil::log("CysPostFX: anti-aliasing " + (type.empty() ? String("none") : type) + " (" + key +
                                   "=" + v + ")");
                for (size_t i = 0; i < sizeof(kAATypes) / sizeof(kAATypes[0]); ++i)
                {
                    if (type != kAATypes[i])
                        request(manager, viewport, kAATypes[i], false);
                }
                if (!type.empty())
                    request(manager, viewport, type, true);
                return true;
            }
            if (k == "gfx_ssao")
            {
                request(manager, viewport, "GenSSAO", on);
                return true;
            }
            if (k == "gfx_heightfog")
            {
                // CYS fx-render: 1 / auto = B (built only while the scene environment has height fog), 2 / force = always
                const bool force = lv == "2" || lv == "force" || lv == "always";
                const bool enable = force || lv == "auto" || on;
                if (enable)
                {
                    PostFilter* f = ensureFilter(manager, viewport, "HeightFog");
                    if (f)
                    {
                        try
                        {
                            f->setParameter("Auto", force ? "0" : "1");
                        }
                        catch (Ogre::Exception&)
                        {
                        }
                    }
                }
                request(manager, viewport, "HeightFog", enable);
                return true;
            }
            if (k == "gfx_godrays")
            {
                request(manager, viewport, "GodRays", on);
                return true;
            }
            if (k == "gfx_dof")
            {
                request(manager, viewport, "DoF", on);
                return true;
            }
            if (k == "gfx_colorlut")                            // CYS-LUT: auto (CY) | 0 | 1 | <lut.png>
            {
                const bool flag = lv.empty() || lv == "0" || lv == "1" || lv == "on" || lv == "off" ||
                                  lv == "true" || lv == "false" || lv == "yes" || lv == "no";
                gLutFile.clear();
                if (lv == "auto" || lv == "cy" || lv == "scene")
                    gLutMode = "auto";
                else if (!flag)
                {
                    gLutMode = "file";
                    gLutFile = v;
                }
                else
                    gLutMode = on ? "on" : "off";
                applyColorLut(manager, viewport, "Gfx_ColorLUT");
                return true;
            }
            if (k == "view_humanlightmap")                      // CYS-LUT: CY level 2 = shadows + ColorLUT
            {
                gHumanLightmap = std::atoi(v.c_str());
                applyColorLut(manager, viewport, "View_HumanLightmap");
                return true;
            }
            if (k == "gfx_postfx")
            {
                gMaster = on;
                for (std::map<String, bool>::const_iterator it = gRequested.begin(); it != gRequested.end(); ++it)
                {
                    PostFilter* f = isCysType(it->first) ? findFilter(manager, it->first) : 0;
                    if (f)
                        applyState(f, it->first);
                }
                return true;
            }
            if (k == "postfx.config")                           // CYS fx-render: key=value file (applyConfigFile)
            {
                if (!v.empty())
                    applyConfigFile(manager, viewport, v);
                return true;
            }
            if (k.compare(0, 7, "postfx.") == 0)
            {
                const String rest = trim(key).substr(7);
                const size_t dot = rest.find('.');
                if (dot == String::npos || dot == 0 || dot + 1 >= rest.size())
                    return false;
                const String type = rest.substr(0, dot);
                const String param = rest.substr(dot + 1);
                PostFilter* f = ensureFilter(manager, viewport, type);
                if (!f)
                {
                    CysPostFxUtil::log("CysPostFX: " + key + ": no post filter type '" + type + "'");
                    return false;
                }
                try
                {
                    f->setParameter(param, v);
                }
                catch (Ogre::Exception& e)
                {
                    CysPostFxUtil::log("CysPostFX: " + key + ": " + e.getDescription());
                    return false;
                }
                return true;
            }
            return false;
        }
        //-------------------------------------------------------------------
        size_t applyConfigFile(PostFilterManager* manager, Ogre::Viewport* viewport, const String& fileName)
        {
            std::ifstream in(fileName.c_str());
            if (!in)
            {
                CysPostFxUtil::log("CysPostFX: configuration " + fileName + " not found");
                return 0;
            }
            size_t applied = 0;
            String line;
            bool first = true;
            while (std::getline(in, line))
            {
                if (first && line.size() >= 3 && (unsigned char)line[0] == 0xEF && (unsigned char)line[1] == 0xBB &&
                    (unsigned char)line[2] == 0xBF)
                {
                    line.erase(0, 3);                   // UTF-8 BOM
                }
                first = false;
                line = trim(line);
                if (line.empty() || line[0] == '#' || line[0] == ';' || (line.size() > 1 && line[0] == '/' && line[1] == '/'))
                    continue;
                const size_t eq = line.find('=');
                if (eq == String::npos)
                    continue;
                const String key = trim(line.substr(0, eq));
                if (applyVariable(manager, viewport, key, trim(line.substr(eq + 1))))
                    ++applied;
                else
                    CysPostFxUtil::log("CysPostFX: " + fileName + ": unknown key '" + key + "'");
            }
            CysPostFxUtil::log("CysPostFX: " + fileName + ": " + Ogre::StringConverter::toString(applied) + " key(s) applied");
            return applied;
        }
        //-------------------------------------------------------------------
        String getSharedTexture(Ogre::Viewport* viewport, const String& logicalName)
        {
            CysPostFxPipeline* p = CysPostFxPipeline::get(viewport, false);
            if (!p)
                return String();
            String name = logicalName;
            if (logicalName == "depth_buffer")
                name = CysPostFxPipeline::DEPTH_TEXTURE;
            else if (logicalName == "ssao_buffer")
                name = CysPostFxPipeline::SSAO_TEXTURE;
            return p->producesTexture(name) ? name : p->getTextureName(name);
        }
        //-------------------------------------------------------------------
        size_t applyStartup(PostFilterManager* manager, Ogre::Viewport* viewport, VariableLookup lookup, void* user)
        {
            // CYS fx-render: doc 08 3.6 - B only reacts to VARIABLE_CHANGED, so values read at start-up never took
            // effect (client_GL needs a Lua hook); here every key goes through applyVariable once at start-up.
            size_t applied = 0;
            String summary;
            for (size_t i = 0; i < sizeof(kStartupKeys) / sizeof(kStartupKeys[0]); ++i)
            {
                const String key(kStartupKeys[i].key);
                String value;
                const bool fromHost = lookup && lookup(user, key, value) && !trim(value).empty();
                if (!fromHost)
                    value = kStartupKeys[i].value;
                String note;
                if (i > 0 && startupAaOverride(key, value, note))  // CYS-AA: PostFX.AAMode / CYS_AA at start-up
                    summary += note;
                if (value.empty())
                    continue;
                if (applyVariable(manager, viewport, key, value))
                {
                    ++applied;
                    summary += " " + key + "=" + trim(value) + (fromHost ? "" : "(default)");
                }
            }
            String config;
            if (lookup && lookup(user, "PostFX.Config", config) && !trim(config).empty())
                applied += applyConfigFile(manager, viewport, trim(config));
            CysPostFxUtil::log("CysPostFX: start-up configuration:" + summary);
            return applied;
        }
        //-------------------------------------------------------------------
        String getDefaultValue(const String& key)
        {
            const String k = CysPostFxUtil::toLowerAscii(trim(key));
            for (size_t i = 0; i < sizeof(kStartupKeys) / sizeof(kStartupKeys[0]); ++i)
            {
                if (CysPostFxUtil::toLowerAscii(kStartupKeys[i].key) == k)
                    return kStartupKeys[i].value;
            }
            return String();
        }
        //-------------------------------------------------------------------
        void onSceneLoaded(PostFilterManager* manager, Ogre::Viewport* viewport, int sceneId, const String& sceneFile)
        {
            onSceneLoaded(manager, viewport, sceneId);
            // CYS-LUT: CY Game.exe passes the LUT of the scene on every EnterScene; Render.dll keeps it and applies it
            // with the quality level. Scene files without an entry get no LUT (the filter is then off in auto mode).
            gSceneName = sceneBaseName(sceneFile);
            gSceneLut = sceneColorLut(sceneId, sceneFile);
            applyColorLut(manager, viewport, "scene");
        }
        //-------------------------------------------------------------------
        String sceneColorLut(int sceneId, const String& sceneFile)
        {





            struct Entry { int id; const char* scene; const char* lut; };
            static const Entry kTable[] =
            {
                { 749, "huangshanzhidian", "LUT_00gao.png" },      // 千仞黄山
                { 750, "dafo",             "LUT_00gao.png" },      // 凌云大佛
                { 752, "tongquetai",       "LUT_00gao.png" },      // 古铜雀台
                { 755, "bianjing",         "LUT_bianjing1.png" },  // 汴京 (+ 775 776 779 780 785 lines 2..6)
                { 775, "bianjing",         "LUT_bianjing1.png" },
                { 776, "bianjing",         "LUT_bianjing1.png" },
                { 779, "bianjing",         "LUT_bianjing1.png" },
                { 780, "bianjing",         "LUT_bianjing1.png" },
                { 785, "bianjing",         "LUT_bianjing1.png" },
                { 824, "congren",          "LUT_congren.png" },    // 绝情谷 (identity LUT: no colour change)
                { 826, "congrentx",        "LUT_congren.png" },
                { 827, "congren",          "LUT_congren.png" },
                { 828, "congrensg",        "LUT_congren.png" },
                { 829, "congrentx",        "LUT_congren.png" },
                { 825, "congrenfb",        "LUT_congrenfb.png" },  // 三庭洞天 (identity LUT)
                { 830, "congrenfb",        "LUT_congrenfb.png" },
                { 831, "congrenfb",        "LUT_congrenfb.png" },
            };
            const size_t n = sizeof(kTable) / sizeof(kTable[0]);
            if (sceneId > 0)                                     // the game: exact, by id as CY
            {
                for (size_t i = 0; i < n; ++i)
                {
                    if (kTable[i].id == sceneId)
                        return String(kTable[i].lut);
                }
                return String();
            }
            const String name = sceneBaseName(sceneFile);        // tools without a scene id: by .Scene name
            if (name.empty())
                return String();
            for (size_t i = 0; i < n; ++i)
            {
                if (name == kTable[i].scene)
                    return String(kTable[i].lut);
            }
            return String();
        }
        //-------------------------------------------------------------------
        String describeColorLut(void)
        {
            const bool on = effectiveState("ColorLUT");
            String lut = gLutMode == "file" ? gLutFile : gSceneLut;
            const String e = CysPostFxUtil::toLowerAscii(gLutEnv);
            if (!gLutEnv.empty() && e != "0" && e != "off" && e != "1" && e != "on" && e != "auto" && e != "cy")
                lut = gLutEnv;                                   // CYS_COLORLUT=<file>
            return (lut.empty() ? String("-") : lut) + (on ? "|on" : "|off");
        }
        //-------------------------------------------------------------------
        void onSceneLoaded(PostFilterManager* manager, Ogre::Viewport* viewport, int sceneId)
        {
            (void)viewport;


            const bool loginScreen = sceneId < 0;
            applySceneTextureFiltering(loginScreen);             // CYS-PARITY (S1)
            const bool wasHeld = gSuspended.find("NewHDRBloom") != gSuspended.end();
            if (loginScreen)
                gSuspended.insert("NewHDRBloom");
            else
                gSuspended.erase("NewHDRBloom");
            if (wasHeld != loginScreen)
            {
                CysPostFxUtil::log(String("CysPostFX: NewHDRBloom ") +
                                   (loginScreen ? "held off on the login / character screens (as B)" : "restored"));
            }
            // CYS-COLOR: CY Game.exe CScene::EnterScene -> Scene_SetSceneNewHDRBloomEnabled(0, 0, 0) on every scene.
            if (gCyHdr && !gHdrBloomExplicit)
                request(manager, viewport, "NewHDRBloom", false);
            PostFilter* f = findFilter(manager, "NewHDRBloom");
            if (f)
                applyState(f, "NewHDRBloom");
        }
        //-------------------------------------------------------------------
        void setPassObserver(PassObserver observer, void* user)
        {
            gObserver = observer;
            gObserverUser = user;
        }
        //-------------------------------------------------------------------
        bool _hasPassObserver(void)
        {
            return gObserver != 0;
        }
        //-------------------------------------------------------------------
        void _notifyPass(const String& stageType, unsigned int localPassId)
        {
            if (gObserver)
                gObserver(gObserverUser, stageType, localPassId);
        }
        //-------------------------------------------------------------------
        void update(Real dt)
        {
            CysPostFxPipeline::updateAll(dt);
        }
    }
}
