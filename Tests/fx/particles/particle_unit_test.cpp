










// OgreParticleFXPrerequisites.h and OgreParticleFX2Prerequisites.h share the include guard
// __SfxPluginPrerequisites_H__, so only the first one included defines its export macro: define both (empty,
// as in both headers).
#define _OgreParticleFXExport
#define _OgreParticleFX2Export

#include "particle_env.h"

#include "OgreColourFadingAffector.h"
#include "OgreScaleInterpolatorAffector.h"
#include "OgreRevolutionAffector.h"
#include "OgreEllipsoidEmitter.h"
#include "OgreExt/OgreMeshAnimationAffector.h"

#include <OgreParticleSystem.h>
#include <OgreParticle.h>
#include <OgreParticleEmitter.h>
#include <OgreParticleAffector.h>
#include <OgreParticleSystemRenderer.h>
#include <OgreDataStream.h>
#include <OgreMatrix3.h>
#include <OgreQuaternion.h>
#include <OgreMath.h>
#include <OgreSceneNode.h>

#include <cmath>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <string>
#include <vector>

using namespace Ogre;

namespace
{
    int gChecks = 0;
    int gFails = 0;
    std::vector<std::string> gOut;
    std::string gSection;

    void out(const std::string& s)
    {
        gOut.push_back(s);
        printf("%s\n", s.c_str());
        fflush(stdout);
    }

    void section(const std::string& s)
    {
        gSection = s;
        out("== " + s);
    }

    bool check(bool ok, const std::string& what)
    {
        ++gChecks;
        if (!ok)
        {
            ++gFails;
            out("  FAIL [" + gSection + "] " + what);
        }
        return ok;
    }

    std::string fmt(double v)
    {
        char b[64];
        sprintf_s(b, "%.7g", v);
        return b;
    }
    std::string fmtV(const Vector3& v) { return "(" + fmt(v.x) + ", " + fmt(v.y) + ", " + fmt(v.z) + ")"; }
    std::string fmtC(const ColourValue& c)
    {
        return "(" + fmt(c.r) + ", " + fmt(c.g) + ", " + fmt(c.b) + ", " + fmt(c.a) + ")";
    }

    bool nearR(double got, double want, double eps, const std::string& what)
    {
        return check(fabs(got - want) <= eps, what + ": got " + fmt(got) + ", want " + fmt(want));
    }
    bool nearV(const Vector3& got, const Vector3& want, double eps, const std::string& what)
    {
        return check((got - want).length() <= eps, what + ": got " + fmtV(got) + ", want " + fmtV(want));
    }
    bool nearC(const ColourValue& got, const ColourValue& want, double eps, const std::string& what)
    {
        const double d = fabs(got.r - want.r) + fabs(got.g - want.g) + fabs(got.b - want.b) + fabs(got.a - want.a);
        return check(d <= eps, what + ": got " + fmtC(got) + ", want " + fmtC(want));
    }
    bool eqS(const String& got, const String& want, const std::string& what)
    {
        return check(got == want, what + ": got '" + got + "', want '" + want + "'");
    }

    /// cumulative volume of the unit ball below height z (times 3/pi) - B Ellipsoid solid height distribution
    double ballCdf(double z) { return ((z * 3.0 - z * z * z) + 2.0) / 3.0; }

    ParticleSystemManager& psm() { return ParticleSystemManager::getSingleton(); }

    ParticleSystem* freshTemplate(const String& name)
    {
        return psm().createTemplate(name, "General");
    }

    //===================================================================================================================
    // runtime copies, through the factories / dictionaries
    //===================================================================================================================
    void testParticleDimensions()
    {
        section("Particle: three dimensions (B Particle +0x14/+0x18/+0x1c)");
        ParticleSystem* sys = freshTemplate("cys_unit_dims");
        sys->setDefaultDepth(7.0f);
        Particle p;
        p._notifyOwner(sys);
        check(!p.hasOwnDimensions(), "a new particle has no own dimensions");
        p.setDimensions(2.0f, 3.0f);
        check(p.hasOwnDimensions(), "setDimensions(w, h) sets own dimensions");
        nearR(p.getOwnWidth(), 2.0, 1e-6, "width");
        nearR(p.getOwnHeight(), 3.0, 1e-6, "height");
        nearR(p.getOwnDepth(), 7.0, 1e-6, "2-argument setDimensions takes the system default depth");
        p.setDimensions(2.0f, 3.0f, 4.0f);
        nearR(p.getOwnDepth(), 4.0, 1e-6, "3-argument setDimensions");
    }

    void testTemplateDefaults()
    {
        section("ParticleSystem template defaults (B ParticleSystemData init FUN_1801202d0)");
        ParticleSystem* t = freshTemplate("cys_unit_tpl");
        nearR(t->getDefaultWidth(), 1.0, 1e-6, "particle_width");
        nearR(t->getDefaultHeight(), 1.0, 1e-6, "particle_height");
        nearR(t->getDefaultDepth(), 0.0, 1e-6, "particle_depth");
        check(t->getKeepParticlesInLocalSpace(), "local_space defaults to true");
        eqS(t->getRendererName(), "billboard", "renderer");
        check(t->getRenderer() != 0, "billboard renderer exists");
        if (t->getRenderer())
            eqS(t->getRenderer()->getParameter("billboard_rotation_type"), "vertex",
                "billboard_rotation_type (B BillboardParticleRenderData ctor 18004ce30)");
    }

    void testEmitterDefaults()
    {
        section("ParticleEmitter defaults (B ctor 18011c4c0: speed 0, time to live 1)");
        ParticleSystem* t = freshTemplate("cys_unit_emit");
        ParticleEmitter* e = t->addEmitter("Point");
        nearR(e->getMinTimeToLive(), 1.0, 1e-6, "time_to_live_min");
        nearR(e->getMaxTimeToLive(), 1.0, 1e-6, "time_to_live_max");
        nearR(e->getMinParticleVelocity(), 0.0, 1e-6, "velocity_min");
        nearR(e->getMaxParticleVelocity(), 0.0, 1e-6, "velocity_max");
    }

    Vector3 boxSpread(ParticleEmitter* box, const char* w, const char* h, const char* d)
    {
        box->setParameter("width", w);
        box->setParameter("height", h);
        box->setParameter("depth", d);
        Vector3 m(0, 0, 0);
        for (int i = 0; i < 4000; ++i)
        {
            Particle q;
            box->_initParticle(&q);
            m.x = std::max(m.x, Math::Abs(q.position.x));
            m.y = std::max(m.y, Math::Abs(q.position.y));
            m.z = std::max(m.z, Math::Abs(q.position.z));
        }
        return m;
    }

    void testAreaEmitterAxes()
    {
        section("AreaEmitter defaults and axes (B initDefaults 180001f40: direction +Y, size 1 1 1)");
        ParticleSystem* t = freshTemplate("cys_unit_area");
        ParticleEmitter* box = t->addEmitter("Box");
        eqS(box->getParameter("width"), "1", "width");
        eqS(box->getParameter("height"), "1", "height");
        eqS(box->getParameter("depth"), "1", "depth");
        nearV(box->getDirection(), Vector3::UNIT_Y, 1e-6, "direction");
        // up = UNIT_Y.perpendicular() = -Z, left = up x dir = +X: width -> X, height -> Z, depth -> Y
        Vector3 s = boxSpread(box, "2", "0.0002", "0.0002");
        check(s.x > 0.95 && s.y < 2e-4 && s.z < 2e-4, "width spreads along X " + fmtV(s));
        s = boxSpread(box, "0.0002", "2", "0.0002");
        check(s.z > 0.95 && s.x < 2e-4 && s.y < 2e-4, "height spreads along Z " + fmtV(s));
        s = boxSpread(box, "0.0002", "0.0002", "2");
        check(s.y > 0.95 && s.x < 2e-4 && s.z < 2e-4, "depth spreads along Y (the direction) " + fmtV(s));
    }

    int ringNearCentre(ParticleEmitter* ring)
    {
        int n = 0;
        for (int i = 0; i < 4000; ++i)
        {
            Particle q;
            ring->_initParticle(&q);
            if (q.position.x * q.position.x + q.position.z * q.position.z < 0.25f * 0.25f)
                ++n;
        }
        return n;
    }

    void testRingInner()
    {
        section("Ring inner size stored as given (B: inner_width 0 = full disc)");
        ParticleSystem* t = freshTemplate("cys_unit_ring");
        ParticleEmitter* ring = t->addEmitter("Ring");
        ring->setParameter("width", "2");
        ring->setParameter("height", "2");
        ring->setParameter("depth", "0.0002");
        eqS(ring->getParameter("inner_width"), "0.5", "default inner_width");
        check(ringNearCentre(ring) == 0, "inner 0.5: nothing inside radius 0.25");
        ring->setParameter("inner_width", "0");
        ring->setParameter("inner_height", "0");
        eqS(ring->getParameter("inner_width"), "0", "inner_width 0 kept");
        eqS(ring->getParameter("inner_height"), "0", "inner_height 0 kept");
        const int n = ringNearCentre(ring);
        check(n > 150, "inner 0: a full disc (" + fmt(n) + " of 4000 inside radius 0.25, expected >= 250)");
    }

    /// Ellipsoid emitter of size 2 2 2 and direction +Y: point coefficients k = (x, -z, y)
    void sampleEllipsoid(ParticleEmitter* el, int n, std::vector<Vector3>& ks)
    {
        ks.clear();
        for (int i = 0; i < n; ++i)
        {
            Particle q;
            el->_initParticle(&q);
            ks.push_back(Vector3(q.position.x, -q.position.z, q.position.y));
        }
    }

    void testEllipsoidRuntime()
    {
        section("Ellipsoid (OgreMain copy): B sampling distributions (B _initParticle 1800082c0)");
        ParticleSystem* t = freshTemplate("cys_unit_ell");
        ParticleEmitter* el = t->addEmitter("Ellipsoid");
        el->setParameter("width", "2");
        el->setParameter("height", "2");
        el->setParameter("depth", "2");
        std::vector<Vector3> ks;

        // solid: P(z < -0.5) = ballCdf(-0.5) / (4/3) = 0.15625; radius fraction 1 - w^2: P(< 0.5) = 1 - sqrt(0.5)
        sampleEllipsoid(el, 40000, ks);
        int below = 0, rad = 0, radN = 0;
        float maxLen = 0;
        for (size_t i = 0; i < ks.size(); ++i)
        {
            const Vector3& k = ks[i];
            if (k.z < -0.5f) ++below;
            const float c = 1.0f - k.z * k.z;
            if (c > 1e-3f)
            {
                ++radN;
                if (Math::Sqrt(k.x * k.x + k.y * k.y) / Math::Sqrt(c) < 0.5f) ++rad;
            }
            maxLen = std::max(maxLen, k.length());
        }
        nearR(below / 40000.0, 0.15625, 0.01, "solid: fraction below z = -0.5");
        nearR(rad / double(radN), 1.0 - sqrt(0.5), 0.012, "solid: fraction inside half the slice radius");
        check(maxLen <= 1.0001f, "solid: inside the unit ball (max " + fmt(maxLen) + ")");

        // surface: all inner sizes 1 -> the sphere, z uniform
        el->setParameter("inner_width", "1");
        el->setParameter("inner_height", "1");
        el->setParameter("inner_depth", "1");
        sampleEllipsoid(el, 20000, ks);
        below = 0;
        float worst = 0;
        for (size_t i = 0; i < ks.size(); ++i)
        {
            if (ks[i].z < -0.5f) ++below;
            worst = std::max(worst, Math::Abs(ks[i].length() - 1.0f));
        }
        check(worst < 1e-3f, "surface: on the unit sphere (worst " + fmt(worst) + ")");
        nearR(below / 20000.0, 0.25, 0.01, "surface: z uniform, fraction below -0.5");

        // hollow: between the inner ellipsoid (0.5 0.5 0.5) and the unit ball
        el->setParameter("inner_width", "0.5");
        el->setParameter("inner_height", "0.5");
        el->setParameter("inner_depth", "0.5");
        sampleEllipsoid(el, 20000, ks);
        float minInner = 10, maxOuter = 0;
        for (size_t i = 0; i < ks.size(); ++i)
        {
            minInner = std::min(minInner, ks[i].squaredLength() / 0.25f);
            maxOuter = std::max(maxOuter, ks[i].length());
        }
        check(minInner >= 0.998f, "hollow: outside the inner ellipsoid (min " + fmt(minInner) + ")");
        check(maxOuter <= 1.0001f, "hollow: inside the unit ball (max " + fmt(maxOuter) + ")");

        // angle_range limits the angle around the axis; the sign also proves height = -Z
        el->setParameter("inner_width", "0");
        el->setParameter("inner_height", "0");
        el->setParameter("inner_depth", "0");
        el->setParameter("angle_range", "0 90");
        eqS(el->getParameter("angle_range"), "0 90", "angle_range round trip");
        sampleEllipsoid(el, 10000, ks);
        float minX = 1, minY = 1;
        for (size_t i = 0; i < ks.size(); ++i)
        {
            minX = std::min(minX, ks[i].x);
            minY = std::min(minY, ks[i].y);
        }
        check(minX >= -1e-4f && minY >= -1e-4f, "angle_range 0 90: first quadrant (min " + fmt(minX) + ", " + fmt(minY) + ")");

        // height_range limits the band along the axis
        el->setParameter("angle_range", "0 360");
        el->setParameter("height_range", "0.5 1");
        eqS(el->getParameter("height_range"), "0.5 1", "height_range round trip");
        sampleEllipsoid(el, 10000, ks);
        float minZ = 1;
        for (size_t i = 0; i < ks.size(); ++i)
            minZ = std::min(minZ, ks[i].z);
        check(minZ >= -1e-4f, "height_range 0.5 1: upper half (min z " + fmt(minZ) + ")");
    }

    void testFx2Keys(const cysfx::Env& env)
    {
        section("Plugin_ParticleFX2 keys and defaults (B = C: identical code, see spec section B/C)");
        if (!check(env.fx2, "Plugin_ParticleFX2 loaded"))
            return;
        ParticleSystem* t = freshTemplate("cys_unit_fx2");

        ParticleAffector* cf = t->addAffector("ColourFading");
        for (int i = 0; i < 6; ++i)
        {
            const String n = StringConverter::toString(i);
            check(cf->setParameter("opacity" + n, "0.5"), "ColourFading accepts opacity" + n);
            eqS(cf->getParameter("opacity" + n), "0.5", "ColourFading opacity" + n + " round trip");
        }
        eqS(cf->getParameter("time0"), "0", "ColourFading time0 default");
        eqS(cf->getParameter("time1"), "1", "ColourFading time1 default");
        eqS(cf->getParameter("time5"), "1", "ColourFading time5 default");
        eqS(cf->getParameter("colour3"), "0 0 0 1", "ColourFading colour default black");
        eqS(cf->getParameter("opacity"), "1", "ColourFading opacity default");
        eqS(cf->getParameter("fade_in_time"), "0", "ColourFading fade_in_time default");
        eqS(cf->getParameter("fade_out_time"), "1", "ColourFading fade_out_time default");

        ParticleAffector* si = t->addAffector("ScaleInterpolator");
        eqS(si->getParameter("use_interpolated_scale"), "true", "ScaleInterpolator interpolated scale is the default");
        check(si->setParameter("use_interpolated_increment", "true"), "ScaleInterpolator use_interpolated_increment");
        check(si->setParameter("increment_value1", "500 500 50"), "ScaleInterpolator increment_value1");
        check(si->setParameter("increment_time5", "2"), "ScaleInterpolator increment_time5");
        check(si->setParameter("increment_repeat_times", "2"), "ScaleInterpolator increment_repeat_times");
        check(si->setParameter("uniform_size", "false"), "ScaleInterpolator uniform_size");
        check(si->setParameter("depth_range_start", "3"), "ScaleInterpolator depth_range_start");
        check(!si->setParameter("use_uniform_size", "false"),
            "ScaleInterpolator 'use_uniform_size' is not a B/C key (both reject it)");

        ParticleAffector* mv = t->addAffector("Movement");
        eqS(mv->getParameter("use_start_velocity"), "true", "Movement use_start_velocity default");

        ParticleAffector* rv = t->addAffector("Revolution");
        check(rv->setParameter("radius_increment", "2"), "Revolution radius_increment");

        ParticleEmitter* pe = t->addEmitter("PolarEmitter");
        eqS(pe->getParameter("use_polar_step"), "true", "PolarEmitter use_polar_step default (B 180007b80)");
        pe->setParameter("radius_start", "1");
        pe->setParameter("radius_step", "1");
        pe->setParameter("radius_end", "10");
        pe->setParameter("theta_start", "90");
        pe->setParameter("theta_step", "0");
        pe->setParameter("theta_end", "90");
        pe->setParameter("phi_start", "0");
        pe->setParameter("phi_step", "90");
        pe->setParameter("phi_end", "360");
        const Vector3 want[3] = { Vector3(1, 0, 0), Vector3(0, 2, 0), Vector3(-3, 0, 0) };
        for (int i = 0; i < 3; ++i)
        {
            Particle q;
            pe->_initParticle(&q);
            nearV(q.position, want[i], 1e-4, "PolarEmitter step " + StringConverter::toString(i));
        }
        pe->setParameter("emission_rate", "100");
        pe->setParameter("duration", "0.1");
        pe->setEnabled(true);
        const unsigned short n1 = pe->_getEmissionCount(0.05f);
        const unsigned short n2 = pe->_getEmissionCount(0.06f);
        check(n1 == 5, "PolarEmitter emits 5 in 0.05 s at 100/s (got " + fmt(n1) + ")");
        check(n2 == 0, "PolarEmitter emits nothing on the update its duration runs out (got " + fmt(n2) + ")");
        check(!pe->getEnabled(), "PolarEmitter disabled after its duration");
    }

    void testMeshRendererKeys()
    {
        section("Mesh renderer keys (B mesh render data FUN_180138590, orientation doSet 18013a440)");
        ParticleSystem* t = freshTemplate("cys_unit_meshkeys");
        t->setRenderer("mesh");
        ParticleSystemRenderer* r = t->getRenderer();
        if (!check(r != 0 && r->getType() == "mesh", "mesh renderer created"))
            return;
        check(r->setParameter("local_rotation", "0.7071068 0 0.7071068 0"), "local_rotation accepted");
        const Quaternion q = StringConverter::parseQuaternion(r->getParameter("local_rotation"));
        check(Math::Abs(q.w - 0.7071068f) < 1e-5f && Math::Abs(q.y - 0.7071068f) < 1e-5f &&
              Math::Abs(q.x) < 1e-6f && Math::Abs(q.z) < 1e-6f,
              "local_rotation is a quaternion 'w x y z' (got '" + r->getParameter("local_rotation") + "')");
        const char* types[] = { "oriented_origin", "oriented_self", "oriented_camera", "oriented_common",
                                "perpendicular_common", "perpendicular_self" };
        for (size_t i = 0; i < sizeof(types) / sizeof(types[0]); ++i)
        {
            check(r->setParameter("orientation_type", types[i]), String("orientation_type ") + types[i]);
            eqS(r->getParameter("orientation_type"), types[i], String("orientation_type ") + types[i] + " round trip");
        }
    }

    void testParseRedirect()
    {
        section("parseScript: stacks / slices / repeat_times go to a SequenceFrame affector (B parseScript 18012cba0)");
        static const char* script =
            "cys_unit_parse_seq\n{\n    renderer texcoord_billboard\n    stacks 4\n    slices 2\n    repeat_times 3\n"
            "    emitter Point\n    {\n    }\n}\n"
            "cys_unit_parse_keys\n{\n    emitter Ring\n    {\n        inner_width 0\n        inner_height 0\n    }\n"
            "    emitter Ellipsoid\n    {\n        inner_width 0.5\n        inner_height 0.5\n        inner_depth 0.5\n"
            "        angle_range 10 80\n        height_range 0.2 0.9\n    }\n}\n";
        DataStreamPtr ds(new MemoryDataStream("cys_unit.particle", (void*)script, strlen(script), false));
        psm().parseScript(ds, "General");
        ParticleSystem* a = psm().getTemplate("cys_unit_parse_seq");
        if (check(a != 0, "template parsed"))
        {
            check(a->getNumAffectors() == 1, "one SequenceFrame affector created (got " + fmt(a->getNumAffectors()) + ")");
            if (a->getNumAffectors() == 1)
            {
                ParticleAffector* s = a->getAffector(0);
                eqS(s->getType(), "SequenceFrame", "affector type");
                eqS(s->getParameter("stacks"), "4", "stacks");
                eqS(s->getParameter("slices"), "2", "slices");
                eqS(s->getParameter("repeat_times"), "3", "repeat_times");
            }
        }
        ParticleSystem* b = psm().getTemplate("cys_unit_parse_keys");
        if (check(b != 0 && b->getNumEmitters() == 2, "Ring + Ellipsoid template parsed"))
        {
            eqS(b->getEmitter(0)->getParameter("inner_width"), "0", "Ring inner_width 0 from the script");
            eqS(b->getEmitter(1)->getParameter("inner_depth"), "0.5", "Ellipsoid inner_depth");
            eqS(b->getEmitter(1)->getParameter("angle_range"), "10 80", "Ellipsoid angle_range");
            eqS(b->getEmitter(1)->getParameter("height_range"), "0.2 0.9", "Ellipsoid height_range");
        }
    }

    //===================================================================================================================
    // exact math on the copies compiled into this test
    //===================================================================================================================
    void testEllipsoidMath()
    {
        section("Ellipsoid math (B 1800082c0: cubic / Cardano / trigonometric inversion)");
        ParticleSystem* t = freshTemplate("cys_unit_ellmath");
        EllipsoidEmitter e(t);
        check(e.sampleMode() == 0, "default solid");
        Vector2 r = e.heightDrawRange();
        nearR(r.x, 0.0, 1e-6, "solid draw range min");
        nearR(r.y, 4.0 / 3.0, 1e-5, "solid draw range max");
        nearV(e.samplePoint(0.0f, 0.0f, 0.0f), Vector3(0, 0, -1), 1e-3, "solid u = 0: bottom pole");
        nearV(e.samplePoint(4.0f / 3.0f, 0.0f, 0.0f), Vector3(0, 0, 1), 1e-3, "solid u = 4/3: top pole");
        nearV(e.samplePoint(2.0f / 3.0f, 0.0f, 0.0f), Vector3(1, 0, 0), 1e-4, "solid u = 2/3, phi 0, w 0: equator");
        nearV(e.samplePoint(2.0f / 3.0f, 90.0f, 0.5f), Vector3(0, 0.75f, 0), 1e-4, "solid radius scaled by 1 - w^2");
        const float us[4] = { 0.1f, 0.5f, 1.0f, 1.25f };
        for (int i = 0; i < 4; ++i)
        {
            const float z = e.samplePoint(us[i], 0.0f, 0.0f).z;
            nearR(ballCdf(z), us[i], 3e-4, "solid height inverts the ball volume, u = " + fmt(us[i]));
        }
        e.setHeightRange(Vector2(0.25f, 0.75f));
        r = e.heightDrawRange();
        nearR(r.x, 0.625 / 3.0, 1e-5, "height_range 0.25 0.75: draw min");
        nearR(r.y, 1.125, 1e-5, "height_range 0.25 0.75: draw max");
        e.setHeightRange(Vector2(0.0f, 1.0f));

        e.setInnerSize(1, 1, 1);
        check(e.sampleMode() == 1, "all inner 1: surface");
        r = e.heightDrawRange();
        nearR(r.x, -1.0, 1e-6, "surface draw min");
        nearR(r.y, 1.0, 1e-6, "surface draw max");
        nearV(e.samplePoint(0.6f, 0.0f, 0.3f), Vector3(0.8f, 0, 0.6f), 1e-5, "surface: u is the height, w unused");
        e.setInnerSize(0.5f, 0.5f, 0.0f);
        check(e.sampleMode() == 0, "any inner 0: solid");

        struct Case { float a, b, c; const char* what; };
        const Case cases[] = {
            { 0.5f, 0.5f, 0.5f, "ab = c^2 (linear band)" },
            { 0.5f, 0.6f, 0.7f, "ab < c^2 (Cardano)" },
            { 0.3f, 0.3f, 0.8f, "ab << c^2 (Cardano)" },
            { 0.9f, 0.8f, 0.4f, "ab > c^2 (trigonometric)" },
        };
        for (size_t ci = 0; ci < sizeof(cases) / sizeof(cases[0]); ++ci)
        {
            const Case& cs = cases[ci];
            const double a = cs.a, b = cs.b, c = cs.c;
            const std::string tag = std::string("hollow ") + cs.what + ": ";
            e.setInnerSize(cs.a, cs.b, cs.c);
            check(e.sampleMode() == 2, tag + "mode");
            const double top = (4.0 - 4.0 * a * b * c) / 3.0;
            r = e.heightDrawRange();
            nearR(r.x, 0.0, 1e-5, tag + "draw min");
            nearR(r.y, top, 1e-5, tag + "draw max = shell volume");
            // at the poles acos() of a rounded argument moves the point sideways by up to ~0.02 (float math, as
            // in client_GL), so only the height is checked there
            nearR(e.samplePoint(0.0f, 0.0f, 0.0f).z, -1.0, 1e-3, tag + "u = 0: bottom pole");
            nearR(e.samplePoint((float)top, 0.0f, 0.0f).z, 1.0, 1e-3, tag + "u = top: top pole");
            const double g0 = (c * c * c - 3.0 * c + 2.0) / 3.0;
            const double g1 = (3.0 * c - c * c * c - 4.0 * a * b * c + 2.0) / 3.0;
            for (int k = 1; k <= 9; ++k)
            {
                const double u = g0 + (g1 - g0) * k / 10.0;
                const Vector3 po = e.samplePoint((float)u, 30.0f, 0.0f);
                const Vector3 pin = e.samplePoint((float)u, 30.0f, 1.0f);
                const double z = po.z;
                const double v = ((a * b - c * c) * z * z * z) / (3.0 * c * c) + (1.0 - a * b) * z +
                                 (2.0 - 2.0 * a * b * c) / 3.0;
                nearR(v, u, 1e-3, tag + "band height inverts the shell volume (u " + fmt(u) + ")");
                check(Math::Abs(po.z) <= cs.c + 1e-4f, tag + "band height inside the inner ellipsoid (z " + fmt(z) + ")");
                nearR(po.length(), 1.0, 1e-3, tag + "w = 0: on the unit sphere");
                nearR(pin.x * pin.x / (a * a) + pin.y * pin.y / (b * b) + pin.z * pin.z / (c * c), 1.0, 3e-3,
                    tag + "w = 1: on the inner ellipsoid");
            }
            // caps: below the band a plain ball slice, above it the ball volume minus the inner one
            const double ul = g0 * 0.5;
            const float zl = e.samplePoint((float)ul, 0.0f, 0.0f).z;
            nearR(ballCdf(zl), ul, 5e-4, tag + "lower cap height");
            const double uh = (g1 + top) * 0.5;
            const float zh = e.samplePoint((float)uh, 0.0f, 0.0f).z;
            nearR(ballCdf(zh) - 4.0 * a * b * c / 3.0, uh, 5e-4, tag + "upper cap height");
        }
    }

    void testColourFadingMath()
    {
        section("ColourFading math (B _affectParticles 180002670, _initParticle 180002950)");
        ParticleSystem* t = freshTemplate("cys_unit_cf");
        ColourFadingAffector cf(t);
        nearC(cf.evaluate(0.5f, ColourValue::White), ColourValue(0, 0, 0, 1), 1e-6, "defaults: black, opacity 1");
        Particle p;
        p.colour = ColourValue::White;
        cf._initParticle(&p);
        nearC(p.colour, ColourValue(0, 0, 0, 1), 1e-6, "born particles start black");

        cf.setColourAdjust(0, ColourValue(1, 0, 0, 0.9f)); // the script alpha is not used
        cf.setColourAdjust(1, ColourValue(0, 1, 0, 0.9f));
        cf.setColourAdjust(2, ColourValue(0, 0, 1, 0.9f));
        cf.setTimeAdjust(0, 0.0f);
        cf.setTimeAdjust(1, 0.5f);
        cf.setTimeAdjust(2, 1.0f);
        cf.setOpacityAdjust(0, 0.2f);
        cf.setOpacityAdjust(1, 1.0f);
        cf.setOpacityAdjust(2, 0.5f);
        nearC(cf.evaluate(0.0f, ColourValue::White), ColourValue(1, 0, 0, 0.2f), 1e-5, "age 0: stage 0 (alpha = opacity0)");
        nearC(cf.evaluate(0.25f, ColourValue::White), ColourValue(0.5f, 0.5f, 0, 0.6f), 1e-5, "age 0.25: segment 0");
        nearC(cf.evaluate(0.75f, ColourValue::White), ColourValue(0, 0.5f, 0.5f, 0.75f), 1e-5, "age 0.75: segment 1");
        nearC(cf.evaluate(1.0f, ColourValue::White), ColourValue(0, 0, 1, 0.5f), 1e-5,
            "age 1: first stage placed at life 1");

        cf.setOpacity(0.8f);
        cf.setFadeInTime(0.2f);
        cf.setFadeOutTime(0.6f);
        nearC(cf.evaluate(0.1f, ColourValue::White), ColourValue(0.32f, 0.08f, 0, 0.144f), 1e-5,
            "fade in: rgba x opacity x age / fade_in");
        nearC(cf.evaluate(0.4f, ColourValue::White), ColourValue(0.16f, 0.64f, 0, 0.672f), 1e-5, "plateau: x opacity");
        nearC(cf.evaluate(0.8f, ColourValue::White), ColourValue(0, 0.16f, 0.24f, 0.28f), 1e-5,
            "fade out: x opacity x (1 - (age - fade_out) / (1 - fade_out))");
        cf.setOpacity(1.0f);
        cf.setFadeInTime(0.0f);
        cf.setFadeOutTime(1.0f);

        cf.setRepeatTimes(2.0f);
        nearC(cf.evaluate(0.3f, ColourValue::White), ColourValue(0, 0.8f, 0.2f, 0.9f), 1e-5,
            "repeat_times 2: curve at fmod(2 x 0.3, 1) = 0.6");
    }

    void testScaleInterpolatorMath()
    {
        section("ScaleInterpolator math (B _initParticle 18000dba0, _affectParticles 18000d640)");
        ParticleSystem* t = freshTemplate("cys_unit_si");
        t->setDefaultDimensions(2.0f, 3.0f); // depth 0 (template default)
        ScaleInterpolatorAffector si(t);
        const Vector3 def(2, 3, 0);
        Vector3 r;
        check(si.evaluate(true, Vector3(5, 5, 5), def, 0.5f, 0.1f, r), "defaults: interpolated scale");
        nearV(r, def, 1e-6, "defaults: scale 1 = system default size");
        check(si.evaluate(false, Vector3(5, 5, 5), def, 0.5f, 0.1f, r), "no own size");
        nearV(r, def, 1e-6, "a particle without own size takes the system default");

        si.mUseConstantScale = true;
        si.mConstantScaleValue = Vector3(10, 20, -100);
        check(si.evaluate(true, Vector3(1, 1, 1), def, 0.5f, 0.1f, r), "constant scale");
        nearV(r, Vector3(2, 3, 0), 1e-5, "constant: size + constant_scale x dt, clamped at 0 (and before interpolation)");
        si.mUseConstantScale = false;

        si.mScaleAdj[1] = Vector3(3, 3, 3);
        si.mTimeAdj[1] = 0.5f;
        si.evaluate(true, Vector3(1, 1, 1), def, 0.25f, 0.1f, r);
        nearV(r, Vector3(4, 6, 0), 1e-5, "interpolated: segment 0 at 0.25");
        si.evaluate(true, Vector3(1, 1, 1), def, 0.5f, 0.1f, r);
        nearV(r, Vector3(6, 9, 0), 1e-5, "interpolated: stage 1 at 0.5");
        si.evaluate(true, Vector3(1, 1, 1), def, 0.75f, 0.1f, r);
        nearV(r, Vector3(4, 6, 0), 1e-5, "interpolated: segment 1 at 0.75");
        si.mRepeatTimes = 2.0f;
        si.evaluate(true, Vector3(1, 1, 1), def, 0.125f, 0.1f, r);
        nearV(r, Vector3(4, 6, 0), 1e-5, "repeat_times 2 at 0.125 = curve at 0.25");
        si.mRepeatTimes = 1.0f;

        si.mUseInterpolatedScale = false;
        si.mUseInterpolatedIncrement = true;
        si.mIncrementAdj[0] = Vector3(10, 10, 10);
        si.mIncrementAdj[1] = Vector3(20, 20, 20);
        si.evaluate(true, Vector3(1, 1, 1), def, 0.5f, 0.1f, r);
        nearV(r, Vector3(2, 2, 2), 1e-5,
            "increment: every increment_time defaults to 1, time0 too (B ctor +0x10c), so stage 0 applies");
        si.mIncrementTimeAdj[0] = 0.0f;
        si.evaluate(true, Vector3(1, 1, 1), def, 0.5f, 0.1f, r);
        nearV(r, Vector3(2.5f, 2.5f, 2.5f), 1e-5, "increment: size + curve(increment) x dt");
        si.mUseInterpolatedIncrement = false;
        check(!si.evaluate(true, Vector3(1, 1, 1), def, 0.5f, 0.1f, r), "no mode enabled: size unchanged");

        ScaleInterpolatorAffector born(t);
        Particle p;
        p._notifyOwner(t);
        born._initParticle(&p);
        check(!p.hasOwnDimensions(), "ranges equal to the system size: born particle keeps the default size");
        born.mWidthRangeStart = born.mWidthRangeEnd = 5.0f;
        born._initParticle(&p);
        nearV(Vector3(p.getOwnWidth(), p.getOwnHeight(), p.getOwnDepth()), Vector3(5, 5, 5), 1e-6,
            "uniform_size: width range used for all three");
        born.mUseUniformSize = false;
        born.mHeightRangeStart = born.mHeightRangeEnd = 6.0f;
        born.mDepthRangeStart = born.mDepthRangeEnd = 7.0f;
        born._initParticle(&p);
        nearV(Vector3(p.getOwnWidth(), p.getOwnHeight(), p.getOwnDepth()), Vector3(5, 6, 7), 1e-6,
            "uniform_size false: width / height / depth ranges");
    }

    void testRevolutionMath()
    {
        section("Revolution math (B RevolutionAffector 18000b660 / calculateDirection 18000baa0)");
        ParticleSystem* t = freshTemplate("cys_unit_rev");
        RevolutionAffector rv(t);
        rv.setParameter("radius_increment", "0");
        const float step = 0.01f;
        const float angle = Math::HALF_PI * step; // 90 degrees per second
        Matrix3 rot;
        Quaternion(Radian(angle), Vector3::UNIT_Y).ToRotationMatrix(rot);
        const Vector3 pos(1, 0, 0);
        Vector3 v = rv._stepVelocity(pos, 1.0f, 1.0f, Vector3::ZERO, rot, step, false);
        nearR((pos + v * step).length(), 1.0, 1e-5, "circle: stays on the radius");
        nearR(v.length(), 2.0 * sin(angle * 0.5) / step, 1e-3, "circle: chord / step");
        check(v.z < 0, "rotation +90 deg/s about +Y moves +X towards -Z");

        rv.setParameter("radius_increment", "2");
        v = rv._stepVelocity(pos, 1.0f, 1.0f, Vector3::ZERO, rot, step, false);
        nearR((pos + v * step).length(), 1.02, 1e-3, "radius_increment 2: radius grows 2 per second");

        rv.setParameter("radius_increment", "-1000");
        v = rv._stepVelocity(pos, 1.0f, 1.0f, Vector3::ZERO, rot, step, false);
        nearV(v, Vector3(-100, 0, 0), 1e-3, "a shrinking orbit lands on the centre instead of crossing it");

        rv.setUseRadiusIncrementScale(true);
        for (int i = 0; i < 6; ++i)
        {
            rv.setTimeAdjust(i, i == 0 ? 0.0f : 1.0f);
            rv.setRadiusIncrementAdjust(i, i == 0 ? 0.0f : 10.0f);
        }
        rv.setRepeatTimes(1.0f);
        v = rv._stepVelocity(pos, 0.5f, 1.0f, Vector3::ZERO, Matrix3::IDENTITY, step, false);
        nearV(v, Vector3(5, 0, 0), 1e-4, "stage curve: increment at life 0.5");
        v = rv._stepVelocity(pos, 0.5f, 1.0f, Vector3::ZERO, Matrix3::IDENTITY, step, true);
        nearV(v, Vector3(4.9f, 0, 0), 1e-4, "stage curve: first half of a split step reads the life one step earlier");
    }

    void testMeshAnimationKeys()
    {
        section("MeshAnimationAffector keys (B Render.dll ctor 18013d7d0)");
        ParticleSystem* t = freshTemplate("cys_unit_manimkeys");
        ParticleAffector* a = t->addAffector("MeshAnimationAffector");
        check(a->setParameter("animation_range_begin", "0.5"), "animation_range_begin");
        check(a->setParameter("animation_range_end", "0.55"), "animation_range_end");
        eqS(a->getParameter("animation_range_end"), "0.55", "animation_range_end round trip");
        check(!a->setParameter("anim_pos1", "0.38 0.1"),
            "anim_posN is not a dictionary key in client_GL (side list without a reader): rejected as there");
    }

    void testMeshAnimationMath()
    {
        section("MeshAnimationAffector position curve (B Render.dll 18013ddc0, FUN_1801e9f80)");
        ParticleSystem* t = freshTemplate("cys_unit_manim");
        MeshAnimationAffector once(t);
        once._cysSetupKeys(2.0f, 4.0f); // animation 2 s, life 4 s, not looping
        nearR(once._animationPosition(0.25f), 0.5, 1e-5, "plays at its own speed (1 s of a 2 s animation)");
        nearR(once._animationPosition(0.75f), 1.0, 1e-5, "then holds its last frame");
        nearR(once.getAnimationSpeedFactor(), 1.0, 1e-6, "speed unchanged");
        MeshAnimationAffector loop(t);
        loop.setAnimationLoop(true);
        loop._cysSetupKeys(2.0f, 4.0f);
        nearR(loop.getAnimationSpeedFactor(), 2.0, 1e-6, "loop: speed x life / length");
        nearR(loop._animationPosition(0.3f), 0.6, 1e-5, "loop: position in the cycle");
        nearR(loop._animationPosition(0.7f), 0.4, 1e-4, "loop: wraps");
        MeshAnimationAffector range(t);
        range.setAnimationRangeBegin(0.5f);
        range.setAnimationRangeEnd(0.55f);
        range._cysSetupKeys(8.0f, 4.0f); // animation longer than the life: the position follows the life
        nearR(range.getAnimationSpeedFactor(), 0.5, 1e-6, "long animation: speed x life / length");
        nearR(range._animationPosition(0.02f), 0.51, 1e-5, "range 0.5..0.55: position mapped into the range");
        nearR(range._animationPosition(0.9f), 0.5 + 0.999 * 0.05, 1e-5, "not looping: stops just before the end");
    }

    Quaternion degQ(float deg, const Vector3& axis) { return Quaternion(Radian(Degree(deg)), axis); }

    void testMeshTransform()
    {
        section("Mesh particle transform (B _notifyParticleMoved 180139240, FUN_1801e9980)");
        const Vector3 P(10, 20, 30);
        const Vector3 one(1, 1, 1);
        const Radian z0(0);
        Vector3 op;
        Quaternion oq;
        typedef MeshParticleRenderer M;

        M::computeTransform(MOT_ORIENTED_ORIGIN, P, Vector3::UNIT_Y, one, false, z0, z0, z0, Vector3::UNIT_Y,
            Vector3::UNIT_Z, Vector3::ZERO, Quaternion::IDENTITY, Quaternion::IDENTITY, Quaternion::IDENTITY,
            Vector3::ZERO, op, oq);
        nearV(op, P, 1e-5, "origin: position");
        nearV(oq * Vector3::UNIT_X, Vector3::UNIT_X, 1e-5, "origin: no rotation");

        M::computeTransform(MOT_ORIENTED_SELF, P, Vector3(2, 0, 0), one, false, z0, z0, z0, Vector3::UNIT_Y,
            Vector3::UNIT_Z, Vector3::ZERO, Quaternion::IDENTITY, Quaternion::IDENTITY, Quaternion::IDENTITY,
            Vector3::ZERO, op, oq);
        nearV(oq * Vector3::UNIT_Y, Vector3::UNIT_X, 1e-5, "oriented_self: mesh Y along the direction");
        nearV(oq * Vector3::UNIT_X, -Vector3::UNIT_Y, 1e-5, "oriented_self: mesh X = Y x camera Z");

        M::computeTransform(MOT_ORIENTED_COMMON, P, Vector3::UNIT_X, one, false, z0, z0, z0, Vector3::UNIT_Z,
            Vector3::UNIT_Y, Vector3::ZERO, degQ(90, Vector3::UNIT_Y), Quaternion::IDENTITY, Quaternion::IDENTITY,
            Vector3::ZERO, op, oq);
        nearV(oq * Vector3::UNIT_Y, Vector3::UNIT_Z, 1e-5, "oriented_common: mesh Y along the common direction");

        const Vector3 cam(P.x + 10, P.y, P.z);
        M::computeTransform(MOT_ORIENTED_CAMERA, P, Vector3::UNIT_Y, one, false, z0, z0, z0, Vector3::UNIT_Y,
            Vector3::UNIT_Z, cam, Quaternion::IDENTITY, Quaternion::IDENTITY, Quaternion::IDENTITY, Vector3::ZERO,
            op, oq);
        nearV(oq * Vector3::UNIT_Z, Vector3::UNIT_X, 1e-5, "oriented_camera: mesh Z towards the camera");
        nearV(oq * Vector3::UNIT_Y, Vector3::UNIT_Y, 1e-5, "oriented_camera: mesh Y = camera up");
        M::computeTransform(MOT_ORIENTED_CAMERA, P, Vector3::UNIT_Y, one, true, Radian(Degree(90)), Radian(Degree(45)),
            Radian(Degree(90)), Vector3::UNIT_Y, Vector3::UNIT_Z, cam, Quaternion::IDENTITY, Quaternion::IDENTITY,
            Quaternion::IDENTITY, Vector3::ZERO, op, oq);
        nearV(oq * Vector3::UNIT_Z, Vector3::UNIT_X, 1e-5, "oriented_camera + rotation: still faces the camera");
        nearV(oq * Vector3::UNIT_X, Vector3::UNIT_Y, 1e-5, "oriented_camera + rotation: only the roll turns it");

        M::computeTransform(MOT_PERPENDICULAR_COMMON, P, Vector3::UNIT_X, one, false, z0, z0, z0, Vector3::UNIT_Y,
            Vector3::UNIT_Z, Vector3::ZERO, Quaternion::IDENTITY, Quaternion::IDENTITY, Quaternion::IDENTITY,
            Vector3::ZERO, op, oq);
        nearV(oq * Vector3::UNIT_Z, Vector3::UNIT_Y, 1e-5, "perpendicular_common: mesh Z along the common direction");
        nearV(oq * Vector3::UNIT_X, -Vector3::UNIT_X, 1e-5, "perpendicular_common: mesh X = up x direction");
        M::computeTransform(MOT_PERPENDICULAR_SELF, P, Vector3(0, 3, 0), one, false, z0, z0, z0, Vector3::UNIT_X,
            Vector3::UNIT_Z, Vector3::ZERO, Quaternion::IDENTITY, Quaternion::IDENTITY, Quaternion::IDENTITY,
            Vector3::ZERO, op, oq);
        nearV(oq * Vector3::UNIT_Z, Vector3::UNIT_Y, 1e-5, "perpendicular_self: mesh Z along the particle direction");

        M::computeTransform(MOT_ORIENTED_ORIGIN, P, Vector3::UNIT_Y, one, true, Radian(Degree(90)), z0, z0,
            Vector3::UNIT_Y, Vector3::UNIT_Z, Vector3::ZERO, Quaternion::IDENTITY, Quaternion::IDENTITY,
            Quaternion::IDENTITY, Vector3::ZERO, op, oq);
        nearV(oq * Vector3::UNIT_Z, Vector3::UNIT_X, 1e-5, "MeshRotator yaw 90: Z -> X");

        M::computeTransform(MOT_ORIENTED_ORIGIN, P, Vector3::UNIT_Y, Vector3(2, 3, 4), true, Radian(Degree(90)), z0, z0,
            Vector3::UNIT_Y, Vector3::UNIT_Z, Vector3::ZERO, Quaternion::IDENTITY, Quaternion::IDENTITY,
            Quaternion::IDENTITY, Vector3(1, 0, 0), op, oq);
        nearV(op, P + Vector3(0, 0, -2), 1e-5, "local_position scaled by the size and turned with the particle frame");

        M::computeTransform(MOT_ORIENTED_ORIGIN, P, Vector3::UNIT_Y, one, false, z0, z0, z0, Vector3::UNIT_Y,
            Vector3::UNIT_Z, Vector3::ZERO, Quaternion::IDENTITY, degQ(90, Vector3::UNIT_X), degQ(90, Vector3::UNIT_Z),
            Vector3::ZERO, op, oq);
        nearV(oq * Vector3::UNIT_X, Vector3::UNIT_Z, 1e-5, "parent x local_rotation (local applied first)");
    }

    //===================================================================================================================
    // device: one real update
    //===================================================================================================================
    void testUpdateOrder(cysfx::Env& env)
    {
        section("ParticleSystem::_update order (B _update 180122bf0: expire, emit, affect, move; fixed interval)");
        static const char* script =
            "cys_unit_order\n{\n    quota 100\n    material BaseWhiteNoLighting\n    iteration_interval 0.5\n"
            "    emitter Point\n    {\n        emission_rate 100\n        time_to_live 10\n    }\n"
            "    affector ColourFading\n    {\n        colour0 1 0 0 1\n        colour1 1 0 0 1\n"
            "        time0 0\n        time1 1\n    }\n}\n";
        DataStreamPtr ds(new MemoryDataStream("cys_unit_order.particle", (void*)script, strlen(script), false));
        psm().parseScript(ds, "General");
        ParticleSystem::setDefaultIterationInterval(0.0f);
        ParticleSystem* ps = env.scene->createParticleSystem("cys_unit_order_1", "cys_unit_order");
        env.scene->getRootSceneNode()->createChildSceneNode()->attachObject(ps);
        ps->_update(0.1f);
        check(ps->getNumParticles() == 10,
            "10 particles after 0.1 s at 100/s; the script iteration_interval is not used (got " +
            fmt(ps->getNumParticles()) + ")");
        size_t red = 0;
        for (size_t i = 0; i < ps->getNumParticles(); ++i)
        {
            const ColourValue& c = ps->getParticle(i)->colour;
            if (Math::Abs(c.r - 1) < 1e-4f && c.g < 1e-4f && c.b < 1e-4f && Math::Abs(c.a - 1) < 1e-4f)
                ++red;
        }
        check(red == ps->getNumParticles(), "particles born in a step are affected in that step (" + fmt(red) + " red)");
        env.scene->destroyParticleSystem(ps);
    }

    std::vector<Vector3> deterministicRun(cysfx::Env& env, bool withOther)
    {
        std::vector<Vector3> v;
        ParticleSystem* other = 0;
        if (withOther)
        {
            other = env.scene->createParticleSystem("cys_unit_det_other", "cys_unit_det");
            env.scene->getRootSceneNode()->createChildSceneNode()->attachObject(other);
            other->_update(0.1f);
        }
        ParticleSystem* ps = env.scene->createParticleSystem("cys_unit_det_1", "cys_unit_det");
        env.scene->getRootSceneNode()->createChildSceneNode()->attachObject(ps);
        rand(); // disturb the global sequence
        ps->_update(0.1f);
        if (other)
            other->_update(0.1f);
        ps->_update(0.1f);
        for (size_t i = 0; i < ps->getNumParticles(); ++i)
        {
            v.push_back(ps->getParticle(i)->position);
            v.push_back(ps->getParticle(i)->direction);
        }
        env.scene->destroyParticleSystem(ps);
        if (other)
            env.scene->destroyParticleSystem(other);
        return v;
    }

    void testDeterminism(cysfx::Env& env)
    {
        section("Deterministic randomness (fx-audit D17): own sequence per system, independent of update order");
        static const char* script =
            "cys_unit_det\n{\n    quota 50\n    material BaseWhiteNoLighting\n    emitter Box\n    {\n"
            "        emission_rate 100\n        time_to_live 10\n        velocity_min 1\n        velocity_max 50\n"
            "        angle 180\n        width 100\n        height 100\n        depth 100\n    }\n}\n";
        DataStreamPtr ds(new MemoryDataStream("cys_unit_det.particle", (void*)script, strlen(script), false));
        psm().parseScript(ds, "General");
        ParticleSystem::setCysDeterministicSeed(777, true);
        const std::vector<Vector3> a = deterministicRun(env, false);
        const std::vector<Vector3> b = deterministicRun(env, true);
        ParticleSystem::setCysDeterministicSeed(0, false);
        check(!a.empty() && a.size() == b.size(), "same particle count (" + fmt(a.size()) + " / " + fmt(b.size()) + ")");
        float worst = 0;
        for (size_t i = 0; i < a.size() && i < b.size(); ++i)
            worst = std::max(worst, (a[i] - b[i]).length());
        check(worst == 0.0f, "identical positions / directions whatever else updates in between (worst " + fmt(worst) + ")");
    }
}

int main(int argc, char** argv)
{
    std::string report = "C:\\TLBB\\085\\CY-Source\\Build\\Logs\\2026-09-13-fx-particles\\unit-test.txt";
    std::string log = "C:\\TLBB\\085\\CY-Source\\Build\\Logs\\2026-09-13-fx-particles\\unit-test-ogre.log";
    bool device = true;
    bool clean = false;
    for (int i = 1; i < argc; ++i)
    {
        const std::string a = argv[i];
        if (a == "--report" && i + 1 < argc) report = argv[++i];
        else if (a == "--log" && i + 1 < argc) log = argv[++i];
        else if (a == "--no-device") device = false;
        else if (a == "--clean-exit") clean = true;
    }
    srand(12345);

    cysfx::Env env;
    bool haveDevice = false;
    try
    {
        haveDevice = cysfx::initEnv(env, log, device) && device;
    }
    catch (Ogre::Exception& e)
    {
        out("engine set-up failed: " + e.getFullDescription());
    }
    if (!env.root)
        return 100;
    out("== CYS particle unit tests (client_GL parity) ==");
    out(std::string("Plugin_ParticleFX2: ") + (env.fx2 ? "loaded" : "NOT loaded"));
    out(std::string("device: ") + (haveDevice ? "D3D9 (hidden window)" : "none"));

    try
    {
        // runtime copies first (their dictionaries are then the registered ones)
        testParticleDimensions();
        testTemplateDefaults();
        testEmitterDefaults();
        testAreaEmitterAxes();
        testRingInner();
        testEllipsoidRuntime();
        testFx2Keys(env);
        if (haveDevice)
            testMeshRendererKeys();
        testParseRedirect();
        testMeshAnimationKeys();
        // exact math
        testMeshAnimationMath();
        testEllipsoidMath();
        testColourFadingMath();
        testScaleInterpolatorMath();
        testRevolutionMath();
        testMeshTransform();
        if (haveDevice)
        {
            testUpdateOrder(env);
            testDeterminism(env);
        }
        else
            out("SKIP update order / mesh renderer keys: no device");
    }
    catch (Ogre::Exception& e)
    {
        check(false, "exception: " + e.getFullDescription());
    }
    catch (std::exception& e)
    {
        check(false, std::string("exception: ") + e.what());
    }

    out("");
    out("checks " + fmt(gChecks) + ", failed " + fmt(gFails));
    std::ofstream f(report.c_str());
    for (size_t i = 0; i < gOut.size(); ++i)
        f << gOut[i] << "\n";
    f.close();
    fflush(stdout);
    // The full engine shutdown of this harness ends in STATUS_HEAP_CORRUPTION (0xC0000374) - with the baseline
    // HEAD engine too - so the exit code would not be the result: stop here (--clean-exit runs the shutdown).
    if (clean)
        cysfx::shutdownEnv(env);
    TerminateProcess(GetCurrentProcess(), (UINT)gFails);
    return gFails;
}
