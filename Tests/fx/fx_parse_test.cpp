// CY-Source (effects/particles agent), Tests/fx: headless parse test of client_GL all.particle / all.effect /
// all.skill (GBK, read-only).  It exercises the CYS particle affectors + mesh renderer (through the real OGRE
// ParticleSystemManager) and the CYS effect elements / skill camera-effect blocks (through their StringInterface
// parameter dictionaries), and reports:
//   - all.particle templates parsed and per-affector/emitter/renderer block counts,
//   - every affector attribute the parsers still reject (target 0 for the implemented affectors),
//   - all.effect element / all.skill sub-block keyword coverage (rejected keys, target 0 for implemented types),
//   - per-type block counts (compare against Docs/evidence/assetinv/fxkeys.json in the report).
//
//   CYSFxParseTest.exe [--data <client_GL\Data\EffectFolder>] [--report <file>] [--log <ogre log>]
//
// Exit code 0 = every implemented affector/element/skill key parsed, no template lost to an unknown key.
// No render system is created (like Tests/scene): the parsers do not need a GPU.

#include "OgreExt/OgreMeshParticleRenderer.h"
#include "OgreExt/OgreTexCoordBillboardParticleRenderer.h"
#include "OgreExt/OgreRibbonRenderer.h"
#include "OgreExt/OgreMeshRotationAffectorFactory.h"
#include "OgreExt/OgreMeshAnimationAffectorFactory.h"

#include "EffectSystem/WXParticleElement.h"
#include "EffectSystem/WXSkill.h"
#include "CYS/Effects/WXSequenceFrameAffector.h"
#include "CYS/Effects/WXDissolveAffector.h"
#include "CYS/Effects/WXRotationCurveAffector.h"
#include "CYS/Effects/WXNewRibbonTrailElement.h"
#include "CYS/Effects/WXUIParticleElement.h"
#include "CYS/Effects/WXSkillCameraEffects.h"

#include <OgreRoot.h>
#include <OgreLogManager.h>
#include <OgreParticleSystemManager.h>
#include <OgreParticleSystem.h>
#include <OgreParticleAffector.h>
#include <OgreStringInterface.h>
#include <OgreException.h>
#include <OgreDataStream.h>

#include <algorithm>
#include <cstdio>
#include <fstream>
#include <map>
#include <set>
#include <sstream>
#include <string>
#include <vector>

using Ogre::String;

namespace
{
    String gData = "C:\\TLBB\\085\\client_GL\\Data\\EffectFolder";
    String gReport;
    String gLog = "C:\\TLBB\\085\\CY-Source\\Build\\Logs\\fx-parse-test.log";

    std::vector<String> gOut;
    void line(const String& s) { gOut.push_back(s); printf("%s\n", s.c_str()); }

    String num(size_t n) { return Ogre::StringConverter::toString((unsigned long)n); }

    // ---- an OGRE log listener that counts the messages the particle parser produces ---------------------
    struct CountingLog : public Ogre::LogListener
    {
        size_t badAffectorAttr;
        size_t missingEmitter;
        size_t missingAffector;
        void write(const String&, const String& message, Ogre::LogMessageLevel, bool)
        {
            if (message.find("Bad particle system affector attribute") != String::npos)
                ++badAffectorAttr;
            else if (message.find("emitter doesn't exists") != String::npos)
                ++missingEmitter;
            else if (message.find("affector doesn't exists") != String::npos)
                ++missingAffector;
        }
        CountingLog() : badAffectorAttr(0), missingEmitter(0), missingAffector(0) {}
    };

    std::vector<unsigned char> readBytes(const String& path)
    {
        std::vector<unsigned char> bytes;
        std::ifstream f(path.c_str(), std::ios::binary);
        if (f)
        {
            f.seekg(0, std::ios::end);
            std::streamoff n = f.tellg();
            f.seekg(0, std::ios::beg);
            if (n > 0)
            {
                bytes.resize((size_t)n);
                f.read(reinterpret_cast<char*>(&bytes[0]), n);
            }
        }
        return bytes;
    }

    // Splits a script into blocks. A block header is a line whose first token is 'headerKeyword' (e.g.
    // "affector"/"emitter"/"element") with a second token = the type; the body is the lines up to the matching
    // '}'.  Records, per type, the block count and (type,key)->one sample value for every body attribute line.
    struct BlockScan
    {
        std::map<String, size_t> typeCount;                 // type -> number of blocks
        std::map<String, std::map<String, String> > keys;   // type -> key -> sample value
    };

    // top-level block scanner for all.effect: "element <Type> { ... }" (skips the enclosing "effect <name>")
    BlockScan scanElements(const std::vector<unsigned char>& data)
    {
        BlockScan scan;
        std::string text(data.begin(), data.end());
        std::istringstream in(text);
        std::string raw;
        String curType;
        int depth = 0;
        bool inBlock = false;
        while (std::getline(in, raw))
        {
            String s = raw;
            // trim
            size_t a = s.find_first_not_of(" \t\r\n");
            if (a == String::npos) continue;
            size_t b = s.find_last_not_of(" \t\r\n");
            s = s.substr(a, b - a + 1);
            if (s.empty() || (s.size() >= 2 && s[0] == '/' && s[1] == '/')) continue;

            if (s == "{") { ++depth; continue; }
            if (s == "}") { if (inBlock && depth == 2) { inBlock = false; curType.clear(); } --depth; continue; }

            std::vector<String> tok = Ogre::StringUtil::split(s, " \t", 1);
            if (depth == 1 && tok.size() >= 2 && tok[0] == "element")
            {
                curType = Ogre::StringUtil::split(tok[1], " \t")[0];
                scan.typeCount[curType] += 1;
                inBlock = true;
            }
            else if (inBlock && depth == 2)
            {
                const String key = tok[0];
                const String val = (tok.size() > 1) ? tok[1] : "";
                if (scan.keys[curType].find(key) == scan.keys[curType].end())
                    scan.keys[curType][key] = val;
            }
        }
        return scan;
    }

    // skill scanner: top-level "skill <name> { ... }"; inside, a bare token is a sub-block header, "key value"
    // is a skill attribute (recorded under type "<skill>").
    BlockScan scanSkills(const std::vector<unsigned char>& data)
    {
        BlockScan scan;
        std::string text(data.begin(), data.end());
        std::istringstream in(text);
        std::string raw;
        String curBlock;   // "" = skill level, otherwise the sub-block type
        int depth = 0;
        while (std::getline(in, raw))
        {
            String s = raw;
            size_t a = s.find_first_not_of(" \t\r\n");
            if (a == String::npos) continue;
            size_t b = s.find_last_not_of(" \t\r\n");
            s = s.substr(a, b - a + 1);
            if (s.empty() || (s.size() >= 2 && s[0] == '/' && s[1] == '/')) continue;

            if (s == "{") { ++depth; continue; }
            if (s == "}") { if (depth == 2) curBlock.clear(); --depth; continue; }

            std::vector<String> tok = Ogre::StringUtil::split(s, " \t", 1);
            if (depth == 1)
            {
                if (tok.size() == 1)
                {
                    // sub-block header (AnimEffect / Ribbon / Sound / SceneLight / CameraShake / ComplexBlur / ...)
                    if (tok[0] != "skill")
                    {
                        curBlock = tok[0];
                        scan.typeCount[curBlock] += 1;
                    }
                }
                else if (tok[0] != "skill")
                {
                    // skill-level attribute
                    scan.typeCount["<skill>"] += 1;
                    if (scan.keys["<skill>"].find(tok[0]) == scan.keys["<skill>"].end())
                        scan.keys["<skill>"][tok[0]] = tok.size() > 1 ? tok[1] : "";
                }
            }
            else if (depth == 2 && !curBlock.empty())
            {
                const String key = tok[0];
                if (scan.keys[curBlock].find(key) == scan.keys[curBlock].end())
                    scan.keys[curBlock][key] = tok.size() > 1 ? tok[1] : "";
            }
        }
        return scan;
    }

    // Tests every (type,key) sample against 'obj', returns the keys the dictionary rejected or threw on.
    struct KeyResult { std::vector<String> rejected; std::vector<String> threw; size_t ok; KeyResult() : ok(0) {} };

    KeyResult testKeys(Ogre::StringInterface* obj, const std::map<String, String>& keys)
    {
        KeyResult r;
        for (std::map<String, String>::const_iterator it = keys.begin(); it != keys.end(); ++it)
        {
            try
            {
                if (obj->setParameter(it->first, it->second.empty() ? String("0") : it->second))
                    ++r.ok;
                else
                    r.rejected.push_back(it->first);
            }
            catch (Ogre::Exception&)
            {
                r.threw.push_back(it->first);
            }
        }
        return r;
    }

    String join(const std::vector<String>& v)
    {
        String s;
        for (size_t i = 0; i < v.size(); ++i) s += (i ? ", " : "") + v[i];
        return s;
    }

    size_t countTemplates(Ogre::ParticleSystemManager& psm)
    {
        size_t n = 0;
        Ogre::ParticleSystemManager::ParticleSystemTemplateIterator it = psm.getTemplateIterator();
        while (it.hasMoreElements()) { it.getNext(); ++n; }
        return n;
    }
}

int main(int argc, char** argv)
{
    for (int i = 1; i < argc; ++i)
    {
        String a = argv[i];
        if (a == "--data" && i + 1 < argc) gData = argv[++i];
        else if (a == "--report" && i + 1 < argc) gReport = argv[++i];
        else if (a == "--log" && i + 1 < argc) gLog = argv[++i];
    }

    Ogre::Root* root = new Ogre::Root("", "", gLog);
    CountingLog counter;
    Ogre::LogManager::getSingleton().addListener(&counter);

    // Register the WXCore particle renderers / affectors (same set as WX::System::_registerExtraPlugins) and the
    // three new CYS affectors, then load Plugin_ParticleFX2 (PolarEmitter, RevoluMove, PolarMove, ...).
    Ogre::ParticleSystemManager& psm = Ogre::ParticleSystemManager::getSingleton();
    psm.addRendererFactory(new Ogre::TexCoordBillboardParticleRendererFactory());
    psm.addRendererFactory(new Ogre::MeshParticleRendererFactory());
    psm.addRendererFactory(new Ogre::RibbonRendererFactory());
    psm.addAffectorFactory(new Ogre::MeshRotationAffectorFactory());
    psm.addAffectorFactory(new Ogre::MeshAnimationAffectorFactory());
    psm.addAffectorFactory(new WX::SequenceFrameAffectorFactory());
    psm.addAffectorFactory(new WX::DissolveAffectorFactory());
    psm.addAffectorFactory(new WX::RotationCurveAffectorFactory());

    bool fx2 = false;
    try { root->loadPlugin("Plugin_ParticleFX2"); fx2 = true; }
    catch (Ogre::Exception&) { try { root->loadPlugin("Plugin_ParticleFX2.dll"); fx2 = true; } catch (Ogre::Exception&) {} }

    line("== CYS FX parse test ==");
    line("data     : " + gData);
    line("Plugin_ParticleFX2 loaded : " + String(fx2 ? "yes" : "no (RevoluMove/PolarMove/PolarEmitter unavailable)"));
    line("");

    int exit = 0;

    //-------------------------------------------------------------------- all.particle
    {
        std::vector<unsigned char> bytes = readBytes(gData + "\\all.particle");
        if (bytes.empty())
        {
            line("FAIL: cannot read all.particle");
            exit = 2;
        }
        else
        {
            const size_t before = countTemplates(psm);
            Ogre::DataStreamPtr stream(new Ogre::MemoryDataStream("all.particle",
                &bytes[0], bytes.size(), false));
            try
            {
                psm.parseScript(stream, Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            }
            catch (Ogre::Exception& e)
            {
                line("FAIL: all.particle aborted with an exception: " + e.getDescription());
                exit = 3;
            }
            const size_t parsed = countTemplates(psm) - before;
            line("all.particle templates parsed        : " + num(parsed));
            line("  affector attributes rejected       : " + num(counter.badAffectorAttr) + "  (target 0 for implemented affectors)");
            line("  emitter blocks skipped (unknown)   : " + num(counter.missingEmitter) + "  (OGRE ParticleFX plugin not in this tree)");
            line("  affector blocks skipped (unknown)  : " + num(counter.missingAffector) + "  (OGRE ParticleFX plugin not in this tree)");
            if (counter.badAffectorAttr != 0)
                exit = (exit ? exit : 4);
            line("");
        }
    }

    //-------------------------------------------------------------------- all.effect (elements)
    {
        std::vector<unsigned char> bytes = readBytes(gData + "\\all.effect");
        if (bytes.empty())
        {
            line("FAIL: cannot read all.effect");
            exit = 2;
        }
        else
        {
            BlockScan scan = scanElements(bytes);
            line("all.effect element blocks (per type, keyword coverage):");
            for (std::map<String, size_t>::const_iterator it = scan.typeCount.begin(); it != scan.typeCount.end(); ++it)
            {
                const String& type = it->first;
                Ogre::StringInterface* obj = NULL;
                if (type == "Particle")            obj = new WX::ParticleElement("Particle", NULL);
                else if (type == "UIParticle")     obj = new WX::UIParticleElement(NULL);
                else if (type == "NewRibbonTrail") obj = new WX::NewRibbonTrailElement("NewRibbonTrail", NULL);

                if (!obj)
                {
                    // Mesh / BillboardSet / Projector / Beam / PointLight: known element types owned elsewhere
                    line("   " + type + " : " + num(it->second) + " blocks (not tested here - element owned outside this agent)");
                    continue;
                }

                KeyResult r = testKeys(obj, scan.keys[type]);
                String status = (r.rejected.empty() && r.threw.empty()) ? "OK" : "UNKNOWN KEYS";
                line("   " + type + " : " + num(it->second) + " blocks, " + num(r.ok) + " keys parsed [" + status + "]");
                if (!r.rejected.empty()) { line("       rejected: " + join(r.rejected)); exit = (exit ? exit : 5); }
                if (!r.threw.empty())    { line("       threw   : " + join(r.threw));    exit = (exit ? exit : 5); }
                delete obj;
            }
            line("");
        }
    }

    //-------------------------------------------------------------------- all.skill (sub-blocks)
    {
        std::vector<unsigned char> bytes = readBytes(gData + "\\all.skill");
        if (bytes.empty())
        {
            line("FAIL: cannot read all.skill");
            exit = 2;
        }
        else
        {
            BlockScan scan = scanSkills(bytes);
            line("all.skill blocks (per type, keyword coverage):");
            for (std::map<String, size_t>::const_iterator it = scan.typeCount.begin(); it != scan.typeCount.end(); ++it)
            {
                const String& type = it->first;
                Ogre::StringInterface* obj = NULL;
                if (type == "<skill>")            obj = new WX::Skill("test", NULL);
                else if (type == "CameraShake")   obj = new WX::AnimationCameraShake();
                else if (type == "ComplexBlur")   obj = new WX::AnimationComplexBlur();

                if (!obj)
                {
                    line("   " + type + " : " + num(it->second) + " blocks (not tested here - block owned outside this agent)");
                    continue;
                }

                KeyResult r = testKeys(obj, scan.keys[type]);
                String status = (r.rejected.empty() && r.threw.empty()) ? "OK" : "UNKNOWN KEYS";
                const String label = (type == "<skill>") ? "skill-level" : type;
                line("   " + label + " : " + num(it->second) + " blocks, " + num(r.ok) + " keys parsed [" + status + "]");
                if (!r.rejected.empty()) { line("       rejected: " + join(r.rejected)); exit = (exit ? exit : 5); }
                if (!r.threw.empty())    { line("       threw   : " + join(r.threw));    exit = (exit ? exit : 5); }
                delete obj;
            }
            line("");
        }
    }

    line(exit == 0 ? "RESULT: PASS" : "RESULT: FAIL (see lines above)");

    if (!gReport.empty())
    {
        std::ofstream of(gReport.c_str(), std::ios::binary);
        for (size_t i = 0; i < gOut.size(); ++i) of << gOut[i] << "\n";
    }

    Ogre::LogManager::getSingleton().removeListener(&counter);
    delete root;
    return exit;
}
