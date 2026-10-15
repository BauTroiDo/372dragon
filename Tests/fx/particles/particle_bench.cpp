// CY-Source Tests/fx/particles: CPU cost of particle update and render-queue submission on N real systems.
//
//   CYSParticleBench.exe [--data <Data dir>] [--systems 200] [--warmup 90] [--frames 300] [--runs 3] [--dt 0.033]
//                        [--interval 0.033] [--seed 12345] [--mesh 0|1] [--scene 0|1] [--label <text>]
//                        [--out <tsv>] [--log <ogre log>]
//
// * Templates: every template of <data>\EffectFolder\all.particle (read-only), picked with a fixed stride
//   permutation so the set covers the whole file; mesh-renderer systems only with --mesh 1 (their meshes are
//   looked up in the data folders). Every system renders with BaseWhiteNoLighting (no texture loading).
// * Per frame: update = ParticleSystem::_update(dt) of every system (the game's fixed 0.033 s interval by
//   default); submit = _notifyCurrentCamera + _updateRenderQueue of every system into the scene render queue
//   (sorting, billboard buffer fill); scene (--scene 1) = SceneManager::_updateSceneGraph + _findVisibleObjects,
//   which also covers the mesh-particle entities. Emitters of a system that went empty are re-enabled so the
//   load stays steady. GPU work is not measured.
// * Only APIs present in every tree are used, so the same file builds against an older baseline.

#include "particle_env.h"

#include <OgreParticleSystem.h>
#include <OgreParticleEmitter.h>
#include <OgreRenderQueue.h>
#include <OgreResourceGroupManager.h>
#include <OgreDataStream.h>
#include <OgreSceneNode.h>
#include <OgreMaterialManager.h>

#include <algorithm>
#include <cstdio>
#include <fstream>
#include <map>
#include <string>
#include <vector>

using namespace Ogre;

namespace
{
    double gFreq = 0;
    double nowMs()
    {
        LARGE_INTEGER c;
        QueryPerformanceCounter(&c);
        return c.QuadPart * 1000.0 / gFreq;
    }

    std::string fmt(double v, const char* f = "%.4f")
    {
        char b[64];
        sprintf_s(b, f, v);
        return b;
    }

    struct Sys
    {
        ParticleSystem* ps;
        String tpl;
        String renderer;
        double upd;        // ms over the measured frames
        double sub;
        double particles;  // sum over the measured frames
    };

    bool hasMeshFiles(const std::string& dir)
    {
        const char* pats[] = { "\\*.mesh", "\\*.skeleton" };
        for (int i = 0; i < 2; ++i)
        {
            WIN32_FIND_DATAA fd;
            HANDLE h = FindFirstFileA((dir + pats[i]).c_str(), &fd);
            if (h != INVALID_HANDLE_VALUE)
            {
                FindClose(h);
                return true;
            }
        }
        return false;
    }

    /// every folder (recursive) holding meshes / skeletons becomes a location of "General" (0.85 FileSystemArchive
    /// finds files by their relative path only, as TlbbViewer notes)
    void addMeshFolders(const std::string& dir, size_t& count)
    {
        if (hasMeshFiles(dir))
        {
            ResourceGroupManager::getSingleton().addResourceLocation(dir, "FileSystem", "General", false);
            ++count;
        }
        WIN32_FIND_DATAA fd;
        HANDLE h = FindFirstFileA((dir + "\\*").c_str(), &fd);
        if (h == INVALID_HANDLE_VALUE)
            return;
        do
        {
            if ((fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) && fd.cFileName[0] != '.')
                addMeshFolders(dir + "\\" + fd.cFileName, count);
        } while (FindNextFileA(h, &fd));
        FindClose(h);
    }

    bool readFile(const std::string& path, std::string& text)
    {
        std::ifstream f(path.c_str(), std::ios::binary);
        if (!f)
            return false;
        text.assign((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
        return true;
    }

    size_t gcd(size_t a, size_t b) { while (b) { size_t t = a % b; a = b; b = t; } return a; }

    size_t materialCount(void)
    {
        size_t n = 0;
        ResourceManager::ResourceMapIterator it = MaterialManager::getSingleton().getResourceIterator();
        while (it.hasMoreElements())
        {
            it.getNext();
            ++n;
        }
        return n;
    }

    double median(std::vector<double> v)
    {
        if (v.empty()) return 0;
        std::sort(v.begin(), v.end());
        return v[v.size() / 2];
    }
}

int main(int argc, char** argv)
{
    std::string data = "C:\\TLBB\\085\\CY-Source\\Assets\\Canonical\\Data";
    std::string outPath = "C:\\TLBB\\085\\CY-Source\\Build\\Logs\\2026-09-13-fx-particles\\bench.tsv";
    std::string log = "C:\\TLBB\\085\\CY-Source\\Build\\Logs\\2026-09-13-fx-particles\\bench-ogre.log";
    std::string label = "bench";
    int systems = 200, warmup = 90, frames = 300, runs = 3, mesh = 1, scene = 1, churn = 5;
    float dt = 0.033f, interval = 0.033f;
    unsigned seed = 12345;
    for (int i = 1; i + 1 < argc; i += 2)
    {
        const std::string a = argv[i], v = argv[i + 1];
        if (a == "--data") data = v;
        else if (a == "--systems") systems = atoi(v.c_str());
        else if (a == "--warmup") warmup = atoi(v.c_str());
        else if (a == "--frames") frames = atoi(v.c_str());
        else if (a == "--runs") runs = atoi(v.c_str());
        else if (a == "--dt") dt = (float)atof(v.c_str());
        else if (a == "--interval") interval = (float)atof(v.c_str());
        else if (a == "--seed") seed = (unsigned)atoi(v.c_str());
        else if (a == "--mesh") mesh = atoi(v.c_str());
        else if (a == "--scene") scene = atoi(v.c_str());
        else if (a == "--churn") churn = atoi(v.c_str());
        else if (a == "--label") label = v;
        else if (a == "--out") outPath = v;
        else if (a == "--log") log = v;
    }
    LARGE_INTEGER f;
    QueryPerformanceFrequency(&f);
    gFreq = (double)f.QuadPart;

    cysfx::Env env;
    try
    {
        if (!cysfx::initEnv(env, log, true, 640, 480))
        {
            printf("no render system\n");
            return 2;
        }
    }
    catch (Ogre::Exception& e)
    {
        printf("engine set-up failed: %s\n", e.getFullDescription().c_str());
        return 2;
    }
    printf("CYSParticleBench [%s]: Plugin_ParticleFX2 %s\n", label.c_str(), env.fx2 ? "loaded" : "NOT loaded");
    ParticleSystemManager& psm = ParticleSystemManager::getSingleton();
    ParticleSystem::setDefaultIterationInterval(interval);

    if (mesh)
    {
        size_t n = 0;
        const char* folders[] = { "EffectFolder", "ModelFolder", "Model2Folder", "Model3Folder", "Model4Folder",
                                  "Model5Folder", "Model6Folder", "Model7Folder", "Model8Folder" };
        for (size_t i = 0; i < sizeof(folders) / sizeof(folders[0]); ++i)
            addMeshFolders(data + "\\" + folders[i], n);
        printf("mesh folders: %u\n", (unsigned)n);
    }

    std::string text;
    const std::string script = data + "\\EffectFolder\\all.particle";
    if (!readFile(script, text))
    {
        printf("cannot read %s\n", script.c_str());
        return 3;
    }
    {
        const double t0 = nowMs();
        DataStreamPtr ds(new MemoryDataStream("all.particle", &text[0], text.size(), false));
        try { psm.parseScript(ds, "General"); }
        catch (Ogre::Exception& e) { printf("parse: %s\n", e.getFullDescription().c_str()); }
        printf("all.particle parsed in %.0f ms\n", nowMs() - t0);
    }
    std::vector<String> names;
    ParticleSystemManager::ParticleSystemTemplateIterator it = psm.getTemplateIterator();
    while (it.hasMoreElements())
    {
        names.push_back(it.peekNextKey());
        it.moveNext();
    }
    printf("templates: %u\n", (unsigned)names.size());
    if (names.empty())
        return 4;

    // camera over a 20 x 10 grid of systems
    Camera* cam = env.camera;
    cam->setPosition(Vector3(0, 3000, 6000));
    cam->lookAt(Vector3(0, 0, 0));
    RenderQueue* queue = env.scene->getRenderQueue();

    // selection: index k * P mod N with P coprime to N walks the whole file in a fixed order
    size_t P = 7919;
    while (gcd(P, names.size()) != 1)
        P += 2;
    std::vector<Sys> set;
    std::map<String, int> byRenderer;
    srand(seed);
    for (size_t k = 0; k < names.size() && (int)set.size() < systems; ++k)
    {
        const String& name = names[(k * P) % names.size()];
        ParticleSystem* tpl = psm.getTemplate(name);
        if (!tpl)
            continue;
        const String renderer = tpl->getRendererName();
        if (!mesh && renderer == "mesh")
            continue;
        ParticleSystem* ps = 0;
        SceneNode* node = 0;
        try
        {
            ps = env.scene->createParticleSystem("cys_bench_" + StringConverter::toString((unsigned long)set.size()),
                name);
            ps->setMaterialName("BaseWhiteNoLighting");
            const int c = (int)set.size() % 20, r = (int)set.size() / 20;
            node = env.scene->getRootSceneNode()->createChildSceneNode(
                Vector3((c - 9.5f) * 400.0f, 0.0f, (r - 4.5f) * 400.0f));
            node->attachObject(ps);
            for (int i = 0; i < 3; ++i)
            {
                ps->_update(dt);
                queue->clear();
                ps->_notifyCurrentCamera(cam);
                ps->_updateRenderQueue(queue);
            }
        }
        catch (Ogre::Exception& e)
        {
            printf("skip %s: %s\n", name.c_str(), e.getDescription().c_str());
            if (ps)
            {
                if (node)
                    node->detachObject(ps);
                env.scene->destroyParticleSystem(ps);
            }
            continue;
        }
        Sys s = { ps, name, renderer, 0, 0, 0 };
        set.push_back(s);
        byRenderer[renderer] += 1;
    }
    printf("systems: %u (", (unsigned)set.size());
    for (std::map<String, int>::iterator r = byRenderer.begin(); r != byRenderer.end(); ++r)
        printf(" %s %d", r->first.c_str(), r->second);
    printf(" )\n");

    std::vector<double> updRuns, subRuns, sceneRuns, partRuns;
    for (int run = 0; run < runs; ++run)
    {
        srand(seed + run);
        for (size_t i = 0; i < set.size(); ++i)
            set[i].upd = set[i].sub = set[i].particles = 0;
        double upd = 0, sub = 0, sceneMs = 0, parts = 0;
        for (int frame = 0; frame < warmup + frames; ++frame)
        {
            const bool measure = frame >= warmup;
            const double t0 = nowMs();
            for (size_t i = 0; i < set.size(); ++i)
            {
                const double a = nowMs();
                set[i].ps->_update(dt);
                if (measure)
                    set[i].upd += nowMs() - a;
            }
            const double t1 = nowMs();
            queue->clear();
            for (size_t i = 0; i < set.size(); ++i)
            {
                const double a = nowMs();
                set[i].ps->_notifyCurrentCamera(cam);
                set[i].ps->_updateRenderQueue(queue);
                if (measure)
                    set[i].sub += nowMs() - a;
            }
            const double t2 = nowMs();
            double t3 = t2;
            if (scene)
            {
                env.scene->_updateSceneGraph(cam);
                queue->clear();
                env.scene->_findVisibleObjects(cam, false);
                t3 = nowMs();
            }
            size_t alive = 0;
            for (size_t i = 0; i < set.size(); ++i)
            {
                const size_t n = set[i].ps->getNumParticles();
                alive += n;
                if (measure)
                    set[i].particles += (double)n;
                if (n == 0)
                {
                    // keep the load steady: a finished one-shot system starts again
                    for (unsigned short e = 0; e < set[i].ps->getNumEmitters(); ++e)
                        set[i].ps->getEmitter(e)->setEnabled(true);
                }
            }
            if (measure)
            {
                upd += t1 - t0;
                sub += t2 - t1;
                sceneMs += t3 - t2;
                parts += (double)alive;
            }
        }
        updRuns.push_back(upd / frames);
        subRuns.push_back(sub / frames);
        sceneRuns.push_back(sceneMs / frames);
        partRuns.push_back(parts / frames);
        printf("run %d: update %.3f ms/frame, submit %.3f ms/frame, scene %.3f ms/frame, particles %.0f\n", run,
            upd / frames, sub / frames, sceneMs / frames, parts / frames);
    }

    const double U = median(updRuns), S = median(subRuns), SC = median(sceneRuns), PA = median(partRuns);
    const double n = (double)std::max<size_t>(1, set.size());
    printf("[%s] median of %d runs: update %.3f ms/frame (%.2f us/system, %.1f ns/particle), submit %.3f ms/frame "
        "(%.2f us/system, %.1f ns/particle), scene %.3f ms/frame, particles %.0f\n", label.c_str(), runs, U,
        U * 1000.0 / n, PA > 0 ? U * 1e6 / PA : 0.0, S, S * 1000.0 / n, PA > 0 ? S * 1e6 / PA : 0.0, SC, PA);

    // per renderer (last run)
    std::map<String, double> ru, rs, rp;
    for (size_t i = 0; i < set.size(); ++i)
    {
        ru[set[i].renderer] += set[i].upd / frames;
        rs[set[i].renderer] += set[i].sub / frames;
        rp[set[i].renderer] += set[i].particles / frames;
    }

    std::ofstream out(outPath.c_str(), std::ios::app);
    out << "label\tmetric\tvalue\n";
    out << label << "\tsystems\t" << set.size() << "\n";
    out << label << "\tframes\t" << frames << "\n";
    out << label << "\truns\t" << runs << "\n";
    out << label << "\tdt\t" << dt << "\n";
    out << label << "\tinterval\t" << interval << "\n";
    out << label << "\tupdate_ms_per_frame\t" << fmt(U) << "\n";
    out << label << "\tsubmit_ms_per_frame\t" << fmt(S) << "\n";
    out << label << "\tscene_ms_per_frame\t" << fmt(SC) << "\n";
    out << label << "\tparticles_alive\t" << fmt(PA, "%.1f") << "\n";
    out << label << "\tupdate_us_per_system\t" << fmt(U * 1000.0 / n) << "\n";
    out << label << "\tsubmit_us_per_system\t" << fmt(S * 1000.0 / n) << "\n";
    out << label << "\tupdate_ns_per_particle\t" << fmt(PA > 0 ? U * 1e6 / PA : 0.0, "%.2f") << "\n";
    out << label << "\tsubmit_ns_per_particle\t" << fmt(PA > 0 ? S * 1e6 / PA : 0.0, "%.2f") << "\n";
    for (std::map<String, double>::iterator r = ru.begin(); r != ru.end(); ++r)
    {
        out << label << "\trenderer." << r->first << ".systems\t" << byRenderer[r->first] << "\n";
        out << label << "\trenderer." << r->first << ".update_ms\t" << fmt(r->second) << "\n";
        out << label << "\trenderer." << r->first << ".submit_ms\t" << fmt(rs[r->first]) << "\n";
        out << label << "\trenderer." << r->first << ".particles\t" << fmt(rp[r->first], "%.1f") << "\n";
    }
    out.close();

    // the heaviest systems of the last run (update + submit), for the waste review
    std::vector<std::pair<double, size_t> > heavy;
    for (size_t i = 0; i < set.size(); ++i)
        heavy.push_back(std::make_pair(set[i].upd + set[i].sub, i));
    std::sort(heavy.rbegin(), heavy.rend());
    std::ofstream top((outPath + "." + label + ".systems.tsv").c_str());
    top << "rank\ttemplate\trenderer\tupdate_us_per_frame\tsubmit_us_per_frame\tparticles\n";
    for (size_t k = 0; k < heavy.size(); ++k)
    {
        const Sys& s = set[heavy[k].second];
        top << k + 1 << "\t" << s.tpl << "\t" << s.renderer << "\t" << fmt(s.upd * 1000.0 / frames, "%.2f") << "\t"
            << fmt(s.sub * 1000.0 / frames, "%.2f") << "\t" << fmt(s.particles / frames, "%.1f") << "\n";
    }
    top.close();

    // material clones of mesh particles when mesh systems are destroyed and created again (fx-audit: "+2..+8
    // clones every 3 s"): every mesh system is re-created 'churn' times and run 10 frames each time
    if (churn > 0)
    {
        const size_t m0 = materialCount();
        int meshSystems = 0;
        for (int c = 0; c < churn; ++c)
        {
            for (size_t i = 0; i < set.size(); ++i)
            {
                if (set[i].renderer != "mesh")
                    continue;
                if (c == 0)
                    ++meshSystems;
                SceneNode* node = set[i].ps->getParentSceneNode();
                const String name = set[i].ps->getName();
                if (node)
                    node->detachObject(set[i].ps);
                env.scene->destroyParticleSystem(set[i].ps);
                set[i].ps = env.scene->createParticleSystem(name, set[i].tpl);
                set[i].ps->setMaterialName("BaseWhiteNoLighting");
                if (node)
                    node->attachObject(set[i].ps);
                for (int k = 0; k < 10; ++k)
                {
                    set[i].ps->_update(dt);
                    queue->clear();
                    set[i].ps->_notifyCurrentCamera(cam);
                    set[i].ps->_updateRenderQueue(queue);
                }
            }
        }
        const size_t m1 = materialCount();
        printf("[%s] churn: %d mesh systems re-created %d times: materials %u -> %u\n", label.c_str(), meshSystems,
            churn, (unsigned)m0, (unsigned)m1);
        std::ofstream more(outPath.c_str(), std::ios::app);
        more << label << "\tchurn_mesh_systems\t" << meshSystems << "\n";
        more << label << "\tchurn_times\t" << churn << "\n";
        more << label << "\tchurn_materials_before\t" << m0 << "\n";
        more << label << "\tchurn_materials_after\t" << m1 << "\n";
    }

    fflush(stdout);
    // see particle_unit_test.cpp: the harness shutdown ends in a heap-corruption status (baseline HEAD too)
    TerminateProcess(GetCurrentProcess(), 0);
    return 0;
}
