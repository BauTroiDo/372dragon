// CY-Source (scene agent), Tests/scene: headless load test of every scene file of a data folder (read-only):
//   CanonicalCY (CY 3.71, SceneFolder + Scene2Folder) by default since ci-cy 14/09/2026; client_GL still loads.
//   .Scene / .Terrain (+ .Heightmap / .GridInfo)  -> 0.85 SceneSerializer / TerrainData with the CYS hooks
//   .EnScene, .skysphere, .hfog, .hdr, .newhdrbloom, .godrays, .dynbone -> CY-Source parsers
// Prints per-feature counts, every remaining unknown key (target 0) and data problems, plus unit checks of the
// time-of-day interpolation, the height-fog parameters and the dynamic-bone solver.
//
//   CYSSceneTest.exe [--data <Data folder>] [--report <file>] [--log <ogre log>] [--filter <substring>]
//
// Exit code 0 = every scene loaded, no unknown key, unit checks passed.

#include "Core/WXSceneInfo.h"
#include "Core/WXExpatParser.h"
#include "Core/WXObjectFactoryManager.h"
#include "Core/WXObjectFactory.h"
#include "Core/WXLightObject.h"
#include "Core/WXStaticEntityObject.h"
#include "Core/WXActorObject.h"
#include "Core/WXModelObject.h"
#include "Core/WXParticleSystemObject.h"
#include "Core/WXSkyBoxObject.h"
#include "Core/WXSkyDomeObject.h"
#include "Core/WXSkyPlaneObject.h"
#include "Core/WXEnviromentObject.h"
#include "Core/WXTerrainLiquidObject.h"
#include "Core/WXEffectObject.h"
#include "Core/WXLogicModelObject.h"
#include "Core/TerrainData.h"

#include "CYS/Scene/CYSEnvironment.h"
#include "CYS/Scene/CYSSceneObjects.h"
#include "CYS/Scene/CYSProjectorObject.h"
#include "CYS/Scene/CYSSceneFiles.h"
#include "CYS/Scene/CYSDynamicBones.h"

#include <OgreRoot.h>
#include <OgreLogManager.h>
#include <OgreResourceGroupManager.h>
#include <OgreException.h>

#include <windows.h>

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <map>
#include <set>
#include <sstream>
#include <string>
#include <vector>

using WX::String;

namespace
{
    typedef std::map<String, size_t> Counters;

    Counters gFeatures;
    std::vector<String> gFailures;
    std::vector<String> gCheckLines;
    bool gChecksPassed = true;

    void feature(const String& key, size_t n = 1)
    {
        gFeatures[key] += n;
    }

    void check(bool ok, const String& what)
    {
        gCheckLines.push_back(String(ok ? "PASS " : "FAIL ") + what);
        if (!ok)
            gChecksPassed = false;
    }

    String lowerAscii(const String& s)
    {
        String r(s);
        for (size_t i = 0; i < r.size(); ++i)
            if (r[i] >= 'A' && r[i] <= 'Z')
                r[i] = (char)(r[i] - 'A' + 'a');
        return r;
    }

    bool directoryExists(const String& path)
    {
        const DWORD a = GetFileAttributesA(path.c_str());
        return a != INVALID_FILE_ATTRIBUTES && (a & FILE_ATTRIBUTE_DIRECTORY) != 0;
    }

    /// Resource names of a group matching *.<ext>, case-insensitive on the extension, sorted.
    std::vector<String> findByExtension(const String& group, const String& ext)
    {
        Ogre::ResourceGroupManager& rgm = Ogre::ResourceGroupManager::getSingleton();
        std::set<String> seenLower;
        std::vector<String> names;
        Ogre::StringVectorPtr all = rgm.findResourceNames(group, "*");
        const String lext = lowerAscii(ext);
        for (Ogre::StringVector::const_iterator it = all->begin(); it != all->end(); ++it)
        {
            const String l = lowerAscii(*it);
            if (l.size() > lext.size() && l.compare(l.size() - lext.size(), lext.size(), lext) == 0)
            {
                if (seenLower.insert(l).second)
                    names.push_back(*it);
            }
        }
        std::sort(names.begin(), names.end());
        return names;
    }

    bool readAll(const String& name, const String& group, std::vector<unsigned char>& bytes)
    {
        std::vector<String> groups(1, group);
        return WX::CYSScene::readResource(name, groups, bytes);
    }

    String fmt(const char* f, double a, double b = 0, double c = 0, double d = 0)
    {
        char buf[256];
        sprintf(buf, f, a, b, c, d);
        return buf;
    }

    //-----------------------------------------------------------------------
    void registerFactories(WX::ObjectFactoryManager* ofm)
    {
        // Same list as WX::System::_registerObjectFactories.
        ofm->registerFactory(WX::LightObject::getFactory());
        ofm->registerFactory(WX::StaticEntityObject::getFactory());
        ofm->registerFactory(WX::ActorObject::getFactory());
        ofm->registerFactory(WX::ModelObject::getFactory());
        ofm->registerFactory(WX::ParticleSystemObject::getFactory());
        ofm->registerFactory(WX::SkyBoxObject::getFactory());
        ofm->registerFactory(WX::SkyDomeObject::getFactory());
        ofm->registerFactory(WX::SkyPlaneObject::getFactory());
        ofm->registerFactory(WX::EnviromentObject::getFactory());
        ofm->registerFactory(WX::TerrainLiquidObject::getFactory());
        ofm->registerFactory(WX::EffectObject::getFactory());
        ofm->registerFactory(WX::LogicModelObject::getFactory());
        WX::CYSScene::registerSceneObjectTypes(ofm);
    }

    //-----------------------------------------------------------------------
    void countSky(const WX::CYSEnSky& sky, const String& prefix)
    {
        if (!sky.present)
            return;
        feature(prefix + "EnvKeys", sky.keys.size());
        feature(prefix + "SkyCloudsLayer", sky.clouds.size());
        feature(prefix + "RingCloudsLayer", sky.ringClouds.size());
        if (sky.dome.present)
            feature(prefix + "SkyDome");
        if (sky.sun.enable)
            feature(prefix + "Sun enabled");
        if (sky.moon.enable)
            feature(prefix + "Moon enabled");
        if (sky.star.enable)
            feature(prefix + "Star enabled");
        for (size_t i = 0; i < sky.keys.getKeys().size(); ++i)
        {
            if (sky.keys.getKeys()[i].heightFogEnabled)
                feature(prefix + "EnvKeys with height fog");
        }
    }

    //-----------------------------------------------------------------------
    void loadScenes(const String& filter)
    {
        std::vector<String> scenes = findByExtension("Scene", ".Scene");
        feature("Scene files found", scenes.size());
        WX::ExpatParser parser(NULL);
        WX::CYSEnvironmentManager& env = WX::CYSEnvironmentManager::getSingleton();

        for (size_t i = 0; i < scenes.size(); ++i)
        {
            const String& name = scenes[i];
            if (!filter.empty() && name.find(filter) == String::npos)
                continue;
            WX::SceneInfo* scene = new WX::SceneInfo;
            bool ok = false;
            try
            {
                scene->load(&parser, name, "Scene", false);
                ok = true;
            }
            catch (const Ogre::Exception& e)
            {
                gFailures.push_back(name + ": " + e.getFullDescription());
            }
            catch (const std::exception& e)
            {
                gFailures.push_back(name + ": " + e.what());
            }
            if (ok)
            {
                feature("Scenes loaded");
                const WX::Scene::Objects& objects = scene->getObjects();
                for (WX::Scene::Objects::const_iterator it = objects.begin(); it != objects.end(); ++it)
                {
                    const WX::ObjectPtr& o = *it;
                    const String& type = o->getType();
                    if (type == WX::TerrainLiquidObject::msType)
                    {
                        const WX::CYSWaterSettings& w = static_cast<WX::TerrainLiquidObject*>(o.get())->mCYSWater;
                        if (w.hasShaderParams())
                            feature("TerrainLiquid with ShaderParams");
                        if (!w.meshName.empty())
                            feature("TerrainLiquid mesh water");
                        if (!w.replaceMaterial.empty())
                            feature("TerrainLiquid with replaceMaterial");
                        if (w.showNewWater)
                            feature("TerrainLiquid showNewWaterEnabled");
                        if (w.showMirrorReflectWater)
                            feature("TerrainLiquid showMirrorReflectWaterEnabled");
                    }
                    else if (type == WX::LightObject::msType)
                    {
                        if (static_cast<WX::LightObject*>(o.get())->mIntensity != 1.0f)
                            feature("Light with intensity != 1");
                    }
                    // CYS-FIX fix-projector 15/09/2026: invariant of SceneInfo::initialise (viewer/editor path builds
                    // every object at once): a "create level" command must hand back a Real, otherwise
                    // VariantCast<Real> throws boost::bad_any_cast (ci-cy Projector bag -> TlbbViewer crash on
                    // luoyang_new/suzhou_new). Projector objects must be the real CYSProjectorObject (CY decals).
                    if (o->hasProperty("create level"))
                    {
                        WX::Variant level = o->getProperty("create level");
                        if (!WX::VariantCast<Ogre::Real>(&level))
                            gFailures.push_back(name + ": object '" + o->getName() + "' (" + type +
                                                ") \"create level\" is not a Real (SceneInfo::initialise would throw)");
                    }
                    if (type == WX::CYSProjectorObject::msType)
                    {
                        feature("Projector objects");
                        const WX::CYSProjectorObject* po = dynamic_cast<const WX::CYSProjectorObject*>(o.get());
                        if (!po)
                            gFailures.push_back(name + ": Projector object is not a CYSProjectorObject (no decal)");
                        else if (po->mTextureName != "BaseWhite")
                            feature("Projector objects with a texture (decal)");
                    }
                    if (o->getCYSExtraProperties())
                        feature("Objects with verbatim B properties");
                }
                const WX::CYSTerrainExtras& t = scene->getTerrainData()->mCYSExtras;
                if (t.hasColorMap)
                    feature("Terrain colorMap");
                if (t.useColorMap)
                    feature("Terrain useColorMap=true");
                if (t.useColorMapAlphaBlend)
                    feature("Terrain useColorMapAlphaBlend=true");
                if (t.hasNormalSpec)
                    feature("Terrain normalSpec");
                if (!scene->getTerrainData()->mHeightmap.empty())
                    feature("Terrain heightmaps loaded");

                const WX::CYSSceneHeader& h = scene->mCYSHeader;
                if (h.hasSkySphere)
                    feature("Scene <SkySphere> header");
                if (env.hasSkySphere())
                    feature("Scene SkySphere environment loaded");
                if (env.hasEnScene())
                {
                    feature("Scene EnScene environment loaded");
                    if (env.getEnSceneData().getNumPositionalRegions())
                        feature("Scene EnScene with positional regions");
                }
                const WX::CYSSceneFileParams& files = env.getEnvironment().sceneFiles;
                if (files.hasHdr)
                    feature("Scene .hdr applied");
                if (files.hasNewHdrBloom)
                    feature("Scene .newhdrbloom applied");
                if (files.hasHeightFog)
                {
                    feature("Scene .hfog applied");
                    // B enables the HeightFog filter from the EnvKeys: report the scenes whose keys enable it.
                    const WX::CYSEnSky* sky = env.hasEnScene() ? env.getEnSceneData().getBaseSky() : 0;
                    bool keyEnabled = false;
                    if (sky)
                        for (size_t k = 0; k < sky->keys.getKeys().size(); ++k)
                            keyEnabled = keyEnabled || sky->keys.getKeys()[k].heightFogEnabled;
                    if (keyEnabled)
                        feature("Scene .hfog + EnvKey height_fog_enabled");
                }
                if (files.hasGodRays)
                    feature("Scene .godrays applied");
            }
            env._onSceneReset();
            delete scene;
        }
    }

    //-----------------------------------------------------------------------
    void parseSideFiles(void)
    {
        std::vector<String> names = findByExtension("Scene", ".EnScene");
        feature("EnScene files found", names.size());
        for (size_t i = 0; i < names.size(); ++i)
        {
            WX::CYSEnSceneData d;
            String error;
            if (!WX::CYSScene::loadEnScene(names[i], "Scene", d, &error))
            {
                gFailures.push_back(names[i] + ": " + error);
                continue;
            }
            feature("EnScene files parsed");
            countSky(d.sky, "EnScene base ");
            feature("EnScene regions", d.regions.size());
            feature("EnScene positional regions", d.getNumPositionalRegions());
            for (size_t r = 0; r < d.regions.size(); ++r)
                countSky(d.regions[r].sky, "EnScene region ");
            if (d.timesAsDayFraction)
                feature("EnScene files with day-fraction times (rescaled)");
            if (!d.getBaseSky())
                feature("EnScene files without a base sky");
        }

        names = findByExtension("Scene", ".skysphere");
        feature("SkySphere files found", names.size());
        for (size_t i = 0; i < names.size(); ++i)
        {
            WX::CYSSkySphereData d;
            String error;
            if (!WX::CYSScene::loadSkySphere(names[i], "Scene", d, &error))
            {
                gFailures.push_back(names[i] + ": " + error);
                continue;
            }
            feature("SkySphere files parsed");
            feature("SkySphere weathers", d.weathers.size());
            feature("SkySphere layers", d.layers.size());
            feature("SkySphere moon dates", d.moon.dates.size());
            for (size_t w = 0; w < d.weathers.size(); ++w)
            {
                feature("SkySphere EnvKeys", d.weathers[w].keys.size());
                feature("SkySphere texture groups", d.weathers[w].textureGroups.size());
                feature("SkySphere effects", d.weathers[w].effects.size());
            }
        }

        struct BinaryKind
        {
            const char* ext;
            int kind;
        };
        const BinaryKind kinds[] = { { ".hdr", 0 }, { ".newhdrbloom", 1 }, { ".hfog", 2 }, { ".godrays", 3 } };
        for (size_t k = 0; k < sizeof(kinds) / sizeof(kinds[0]); ++k)
        {
            names = findByExtension("Scene", kinds[k].ext);
            feature(String(kinds[k].ext) + " files found", names.size());
            for (size_t i = 0; i < names.size(); ++i)
            {
                std::vector<unsigned char> bytes;
                if (!readAll(names[i], "Scene", bytes))
                {
                    gFailures.push_back(names[i] + ": cannot read");
                    continue;
                }
                String error;
                bool ok = false;
                const void* p = bytes.empty() ? 0 : &bytes[0];
                switch (kinds[k].kind)
                {
                case 0: { WX::CYSHdrFileParams v; ok = WX::CYSScene::decodeHdr(p, bytes.size(), v, &error); break; }
                case 1: { WX::CYSNewHdrBloomParams v; ok = WX::CYSScene::decodeNewHdrBloom(p, bytes.size(), v, &error); break; }
                case 2: { WX::CYSHeightFogParams v; ok = WX::CYSScene::decodeHeightFog(p, bytes.size(), v, &error); break; }
                default: { WX::CYSGodRaysParams v; ok = WX::CYSScene::decodeGodRays(p, bytes.size(), v, &error); break; }
                }
                if (ok)
                    feature(String(kinds[k].ext) + " files decoded");
                else
                    gFailures.push_back(names[i] + ": " + error);
            }
        }

        names = findByExtension("General", ".dynbone");
        feature(".dynbone files found", names.size());
        for (size_t i = 0; i < names.size(); ++i)
        {
            WX::CYSDynamicBonesData d;
            String error;
            if (!WX::CYSScene::loadDynamicBones(names[i], "General", d, &error))
            {
                gFailures.push_back(names[i] + ": " + error);
                continue;
            }
            feature(".dynbone files parsed");
            feature(".dynbone DynamicBone", d.bones.size());
            feature(".dynbone CapsuleCollider", d.colliders.size());
        }
    }

    //-----------------------------------------------------------------------
    void unitChecks(void)
    {
        // 1) Time-of-day interpolation: mantuoshanzhuang.EnScene (GL, 9 keys 0 3 4 6 15 16 17 18 20) when present,
        //    else the first EnScene of the data whose base sky has at least 3 keys (CanonicalCY has no
        //    mantuoshanzhuang). The checks use the keys' own times: the midpoint between two consecutive keys must
        //    be the average of the two, and the midpoint of the last -> first wrap (past midnight) likewise.
        WX::CYSEnSceneData d;
        String error;
        String chosen;
        std::vector<String> candidates;
        candidates.push_back("mantuoshanzhuang.EnScene");
        const std::vector<String> allEn = findByExtension("Scene", ".EnScene");
        candidates.insert(candidates.end(), allEn.begin(), allEn.end());
        for (size_t c = 0; c < candidates.size() && chosen.empty(); ++c)
        {
            WX::CYSEnSceneData probe;
            String perr;
            if (WX::CYSScene::loadEnScene(candidates[c], "Scene", probe, &perr) && probe.getBaseSky() &&
                probe.getBaseSky()->keys.size() >= 3)
            {
                d = probe;
                chosen = candidates[c];
            }
            else if (c == 0)
                error = perr;
        }
        if (!chosen.empty() && d.getBaseSky())
        {
            const WX::CYSEnvKeyTrack& track = d.getBaseSky()->keys;
            const size_t n = track.size();
            gCheckLines.push_back("     EnvKey track: " + chosen + " (" + fmt("%.0f", (double)n) + " keys)");
            if (chosen == "mantuoshanzhuang.EnScene")
                check(n == 9, "mantuoshanzhuang: 9 EnvKeys");
            else
                check(n >= 3, chosen + ": at least 3 EnvKeys");
            // consecutive pair around the middle of the track
            const size_t i0 = n / 2 - 1, i1 = n / 2;
            const WX::CYSEnvKey ka = track.getKeys()[i0];
            const WX::CYSEnvKey kb = track.getKeys()[i1];
            const float tm = 0.5f * (ka.time + kb.time);
            const WX::CYSEnvKey mid = track.sample(tm);
            const bool lerpOk = std::fabs(mid.fog.r - 0.5f * (ka.fog.r + kb.fog.r)) < 1e-4f &&
                                std::fabs(mid.fogFar - 0.5f * (ka.fogFar + kb.fogFar)) < 1e-2f;
            check(lerpOk, "EnvKey lerp at " + fmt("%.2f", tm) + " h is the midpoint of the " + fmt("%.0f", ka.time) +
                  " h and " + fmt("%.0f", kb.time) + " h keys");
            const WX::CYSEnvKey kLast = track.getKeys()[n - 1];
            const WX::CYSEnvKey kFirst = track.getKeys()[0];
            float tw = 0.5f * (kLast.time + kFirst.time + 24.0f);
            if (tw >= 24.0f)
                tw -= 24.0f;
            const WX::CYSEnvKey wrap = track.sample(tw);
            check(std::fabs(wrap.fog.g - 0.5f * (kLast.fog.g + kFirst.fog.g)) < 1e-4f,
                  "EnvKey wraps midnight (" + fmt("%.2f", tw) + " h = midpoint of " + fmt("%.0f", kLast.time) + " h and " +
                  fmt("%.0f", kFirst.time) + " h)");
            gCheckLines.push_back("     fog colour 5h " + fmt("%.3f %.3f %.3f", track.sample(5).fog.r, track.sample(5).fog.g,
                                  track.sample(5).fog.b) + ", 17.5h " + fmt("%.3f %.3f %.3f", track.sample(17.5f).fog.r,
                                  track.sample(17.5f).fog.g, track.sample(17.5f).fog.b));
        }
        else
        {
            check(false, "an EnScene with at least 3 EnvKeys loads (" + error + ")");
        }

        // 2) Height-fog parameter text and the .hfog order.
        WX::CYSHeightFogParams p;
        const bool parsed = WX::cysParseHeightFogParam("0.5696 0.76718 0.89 1|1 0.966667 0.9 1|1|-2877|0.067|15.6|1|0.56|0|0.9", p);
        check(parsed && p.hHeight == -2877.0f && std::fabs(p.dHeightFalloff - 0.56f) < 1e-6f &&
              std::fabs(p.inscatteringFactor - 0.9f) < 1e-6f && std::fabs(p.dirInscatteringColour.g - 0.966667f) < 1e-5f,
              "height_fog_param parses (FogColor|DirInscatter|HD|HH|HF|HP|DD|DF|DS|IF)");
        WX::CYSHeightFogParams back;
        check(WX::cysParseHeightFogParam(WX::cysFormatHeightFogParam(p), back) && back.hPowFactor == p.hPowFactor,
              "height_fog_param round trip");
        std::vector<unsigned char> bytes;
        WX::CYSHeightFogParams lx;
        if (readAll("FengYun_lingxiaocheng.hfog", "Scene", bytes) &&
            WX::CYSScene::decodeHeightFog(&bytes[0], bytes.size(), lx, 0))
        {
            const WX::Real top = lx.evaluate(0.0f, 1000.0f), valley = lx.evaluate(-1507.0f, 1000.0f);
            check(valley > 0.9f && top < 0.1f, "FengYun_lingxiaocheng.hfog: dense below the city, thin at y=0 (" +
                  fmt("%.3f / %.3f", valley, top) + ")");
        }

        // 3) Dynamic-bone chain: 6 particles, Force (0,-30,0), 5 s at 60 Hz, lengths kept, finite.
        WX::CYSDynBoneDef def;
        def.damping = 0.55f;
        def.elasticity = 0.01f;
        def.stiffness = 0.0f;
        def.inert = 0.2f;
        def.force = Ogre::Vector3(0, -30, 0);
        std::vector<int> parents;
        std::vector<Ogre::Vector3> anim;
        for (int i = 0; i < 6; ++i)
        {
            parents.push_back(i - 1);
            anim.push_back(Ogre::Vector3(10.0f * i, 100, 0));   // horizontal chain
        }
        WX::CYSDynamicBoneChain chain;
        chain.setup(def, parents, anim);
        std::vector<WX::CYSDynCapsule> colliders;
        for (int s = 0; s < 300; ++s)
            chain.update(1.0f / 60.0f, anim, Ogre::Vector3::ZERO, colliders);
        bool finite = true, lengths = true;
        for (size_t i = 1; i < chain.getParticles().size(); ++i)
        {
            const WX::CYSDynamicBoneChain::Particle& q = chain.getParticles()[i];
            finite = finite && q.position.x == q.position.x && q.position.y == q.position.y;
            const WX::Real len = (q.position - chain.getParticles()[q.parent].position).length();
            lengths = lengths && std::fabs(len - 10.0f) < 0.05f;
        }
        const WX::Real tipY = chain.getParticles().back().position.y;
        check(finite && lengths && tipY < 60.0f, "dynamic-bone chain hangs under its force, bone lengths kept (tip y " +
              fmt("%.1f", tipY) + ")");
    }

    //-----------------------------------------------------------------------
    void writeReport(const String& path, double seconds, const String& data)
    {
        std::ostringstream out;
        WX::CYSSceneStats& stats = WX::CYSSceneStats::instance();
        out << "CYSSceneTest (CY-Source scene agent) - scene data: " << data << "\n";
        out << "time " << fmt("%.1f", seconds) << " s\n\n";

        out << "== Features\n";
        for (Counters::const_iterator it = gFeatures.begin(); it != gFeatures.end(); ++it)
            out << "  " << it->first << " = " << it->second << "\n";
        out << "\n== Serializer / parser counters\n";
        for (Counters::const_iterator it = stats.getCounts().begin(); it != stats.getCounts().end(); ++it)
            out << "  " << it->first << " = " << it->second << "\n";

        out << "\n== Failures: " << gFailures.size() << "\n";
        for (size_t i = 0; i < gFailures.size(); ++i)
            out << "  " << gFailures[i] << "\n";

        out << "\n== Unknown keys: " << stats.getUnknownTotal() << " occurrences, " << stats.getUnknowns().size()
            << " keys\n";
        for (Counters::const_iterator it = stats.getUnknowns().begin(); it != stats.getUnknowns().end(); ++it)
            out << "  " << it->first << " = " << it->second << "\n";

        out << "\n== Data problems (not unknown keys): " << stats.getProblems().size() << "\n";
        for (Counters::const_iterator it = stats.getProblems().begin(); it != stats.getProblems().end(); ++it)
            out << "  " << it->first << " = " << it->second << "\n";

        out << "\n== Deferred (understood, not applied): " << stats.getDeferred().size() << "\n";
        for (Counters::const_iterator it = stats.getDeferred().begin(); it != stats.getDeferred().end(); ++it)
            out << "  " << it->first << " = " << it->second << "\n";

        out << "\n== Unit checks\n";
        for (size_t i = 0; i < gCheckLines.size(); ++i)
            out << "  " << gCheckLines[i] << "\n";

        const bool pass = gFailures.empty() && stats.getUnknownTotal() == 0 && gChecksPassed;
        out << "\nRESULT: " << (pass ? "PASS" : "FAIL") << " (failures " << gFailures.size() << ", unknown keys "
            << stats.getUnknowns().size() << ", unit checks " << (gChecksPassed ? "ok" : "failed") << ")\n";

        const std::string text = out.str();
        fputs(text.c_str(), stdout);
        if (FILE* f = fopen(path.c_str(), "wb"))
        {
            fwrite(text.data(), 1, text.size(), f);
            fclose(f);
        }
    }
}

int main(int argc, char** argv)
{
    String data = "C:\\TLBB\\085\\CY-Source\\Assets\\CanonicalCY\\Data";
    String report = "C:\\TLBB\\085\\CY-Source\\Build\\Logs\\2026-09-12-scene\\scene_test_report.txt";
    String logFile = "C:\\TLBB\\085\\CY-Source\\Build\\Logs\\2026-09-12-scene\\scene_test_ogre.log";
    String filter;
    for (int i = 1; i + 1 < argc; i += 2)
    {
        const String opt = argv[i];
        if (opt == "--data")
            data = argv[i + 1];
        else if (opt == "--report")
            report = argv[i + 1];
        else if (opt == "--log")
            logFile = argv[i + 1];
        else if (opt == "--filter")
            filter = argv[i + 1];
    }

    const DWORD start = GetTickCount();
    Ogre::Root* root = new Ogre::Root("", "", logFile);
    Ogre::ResourceGroupManager& rgm = Ogre::ResourceGroupManager::getSingleton();
    // CY 3.71 keeps 45 scenes in Scene2Folder and models up to Model8Folder; GL has SceneFolder + Model[1-3]Folder.
    // Only folders that exist are added (an absent one would abort the test).
    const char* sceneFolders[] = { "SceneFolder", "Scene2Folder" };
    for (size_t i = 0; i < sizeof(sceneFolders) / sizeof(sceneFolders[0]); ++i)
    {
        const String dir = data + "\\" + sceneFolders[i];
        if (directoryExists(dir))
            rgm.addResourceLocation(dir, "FileSystem", "Scene", false);
        else if (i == 0)
            fprintf(stderr, "CYSSceneTest: no SceneFolder in %s\n", data.c_str());
    }
    const char* modelFolders[] =
    {
        "ModelFolder", "Model2Folder", "Model3Folder", "Model4Folder", "Model5Folder", "Model6Folder", "Model7Folder",
        "Model8Folder"
    };
    for (size_t i = 0; i < sizeof(modelFolders) / sizeof(modelFolders[0]); ++i)
    {
        const String dir = data + "\\" + modelFolders[i];
        if (directoryExists(dir))
            rgm.addResourceLocation(dir, "FileSystem", "General", false);
    }

    WX::ObjectFactoryManager* factories = new WX::ObjectFactoryManager;
    registerFactories(factories);
    WX::CYSSceneStats::instance().setCountingEnabled(true);

    int code = 0;
    try
    {
        loadScenes(filter);
        if (filter.empty())
        {
            parseSideFiles();
            unitChecks();
        }
    }
    catch (const Ogre::Exception& e)
    {
        gFailures.push_back("test aborted: " + e.getFullDescription());
    }

    writeReport(report, (GetTickCount() - start) / 1000.0, data);
    const WX::CYSSceneStats& stats = WX::CYSSceneStats::instance();
    code = (gFailures.empty() && stats.getUnknownTotal() == 0 && gChecksPassed) ? 0 : 1;

    delete factories;
    delete root;
    return code;
}
