// Tests/fx/effects: pure unit tests for the effect timing / transform / gating maths (no engine, no GPU).
//
// Mirrors the rules the fx-effects spec (Docs/specs/render/07c-effects_vi.md) takes from client_GL Render.dll:
//   1. skill time window of AnimEffect / HitTime / BreakTime / ShakeTime over a normalised animation clock that
//      wraps when a looping animation restarts (WXLogicModel.cpp);
//   2. element placement with the B TransformInfo scale (WXEffectElement.cpp setTransformInfo): the same derived
//      transform as B's scaled effect base node with the element as a local child;
//   3. the CreateLevel gate (WXEffectElement.cpp update, B FUN_18016bd00): hidden when CreateLevel < manager level;
//      element default 100, manager level 100;
//   4. the ParticleElement sub-effect bookkeeping (WXParticleElement.cpp _updateParticleEffects, B FUN_180216c10 /
//      FUN_180216e90): one entry per live particle in particle order, removed the update its particle is gone,
//      particles identified by address (a reused pool slot keeps its effect).
// Build/run with Tests/fx/effects/run_effects_math.cmd. Exit 0 = all cases pass.

#include <cmath>
#include <cstdio>
#include <list>
#include <unordered_map>
#include <vector>

static int g_fail = 0;
#define CHECK(cond) do { if (!(cond)) { ++g_fail; \
    std::printf("FAIL %s:%d  %s\n", __FILE__, __LINE__, #cond); } } while (0)

// ---- 1. Skill time window ------------------------------------------------------------------------------------
// The exact predicate of LogicModel::_createAnimationEffect / _handleSkillHitTime: a key time t fires when the
// normalised clock moves from oldTime to currTime and t lies in [oldTime, currTime); a looping clip makes
// currTime < oldTime (wrap) and then t >= oldTime or t < currTime fires.
static bool inWindow(float t, float oldTime, float currTime)
{
    return (currTime >= oldTime && t >= oldTime && t < currTime) ||
           (currTime < oldTime && (t >= oldTime || t < currTime));
}

static void test_window()
{
    CHECK(inWindow(0.5f, 0.2f, 0.6f));
    CHECK(inWindow(0.2f, 0.2f, 0.6f));    // lower bound closed
    CHECK(!inWindow(0.6f, 0.2f, 0.6f));   // upper bound open
    CHECK(!inWindow(0.1f, 0.2f, 0.6f));
    CHECK(!inWindow(0.7f, 0.2f, 0.6f));
    CHECK(inWindow(0.6f, 0.6f, 0.9f));    // ... so a key on a frame boundary fires exactly once
    CHECK(inWindow(0.95f, 0.9f, 0.1f));   // wrap: t >= oldTime side
    CHECK(inWindow(0.05f, 0.9f, 0.1f));   // wrap: t < currTime side
    CHECK(!inWindow(0.5f, 0.9f, 0.1f));
    CHECK(inWindow(0.0f, 0.9f, 0.1f));
    CHECK(!inWindow(0.5f, 0.5f, 0.5f));   // stationary clock fires nothing
    const float keys[] = {0.0f, 0.25f, 0.5f, 0.75f, 1.0f};
    for (int k = 0; k < 5; ++k)
    {
        int fires = 0;
        float prev = 0.0f;
        for (int s = 1; s <= 20; ++s)
        {
            float cur = (float)s / 19.0f;   // reaches just over 1 so the 1.0 key can fire
            if (inWindow(keys[k], prev, cur)) ++fires;
            prev = cur;
        }
        CHECK(fires == 1);
    }
}

// ---- 2. Element placement with the TransformInfo scale ----------------------------------------------------------
struct V3 { double x, y, z; };
static V3 add(V3 a, V3 b) { return V3{a.x + b.x, a.y + b.y, a.z + b.z}; }
static V3 mulc(V3 a, V3 b) { return V3{a.x * b.x, a.y * b.y, a.z * b.z}; }   // Ogre Vector3 * Vector3
static V3 yaw(V3 v, double deg)                                               // rotation about +Y (Ogre, right-handed)
{
    const double r = deg * 3.14159265358979323846 / 180.0, c = std::cos(r), s = std::sin(r);
    return V3{c * v.x + s * v.z, v.y, -s * v.x + c * v.z};
}
static bool near3(V3 a, V3 b) { return std::fabs(a.x - b.x) < 1e-9 && std::fabs(a.y - b.y) < 1e-9 && std::fabs(a.z - b.z) < 1e-9; }

// WX (world-space element nodes): position = P + R * (S * relPos), node scale = S
static V3 elementWorld(V3 P, double yawDeg, V3 S, V3 rel) { return add(P, yaw(mulc(S, rel), yawDeg)); }
// B scene graph: base node (P, R, S), element node local child at rel: Ogre _updateFromParent
static V3 sceneGraphWorld(V3 P, double yawDeg, V3 S, V3 rel) { return add(yaw(mulc(S, rel), yawDeg), P); }

static void test_scale_transform()
{
    const V3 P{10, 2, -3}, rel{1, 0.5, 0};
    // unit scale reproduces the 0.85 placement P + R * relPos
    CHECK(near3(elementWorld(P, 90, V3{1, 1, 1}, rel), add(P, yaw(rel, 90))));
    // scale 1.5 (creation scene) with the effects following the model: the offset is scaled
    const V3 w = elementWorld(P, 90, V3{1.5, 1.5, 1.5}, rel);
    CHECK(near3(w, sceneGraphWorld(P, 90, V3{1.5, 1.5, 1.5}, rel)));
    CHECK(near3(w, V3{10, 2.75, -4.5}));            // yaw 90: +x -> -z, y scaled 0.5 -> 0.75
    // the base position itself is never scaled (the reason the effect base node must not carry the scale in WX)
    CHECK(near3(elementWorld(P, 0, V3{2, 2, 2}, V3{0, 0, 0}), P));
    // non-uniform scale is carried per axis
    CHECK(near3(elementWorld(V3{0, 0, 0}, 0, V3{2, 0.5, 1}, V3{1, 1, 1}), V3{2, 0.5, 1}));
}

// ---- 3. CreateLevel gate -----------------------------------------------------------------------------------------
static bool hiddenByLevel(int createLevel, unsigned int managerLevel)
{
    return static_cast<unsigned int>(createLevel) < managerLevel;
}
static void test_create_level()
{
    const unsigned int managerLevel = 100;   // B EffectManager ctor, never changed
    const int elementDefault = 100;          // B EffectElement ctor (elements without the key)
    CHECK(!hiddenByLevel(elementDefault, managerLevel));
    CHECK(!hiddenByLevel(100, managerLevel)); // 38.757 client_GL particle elements
    CHECK(!hiddenByLevel(120, managerLevel)); // 4
    CHECK(hiddenByLevel(0, managerLevel));    // 35 particle + 1 ribbon: hidden in B
    CHECK(!hiddenByLevel(0, 0));              // a manager level of 0 shows everything (0.85 behaviour)
}

// ---- 4. Sub-effect bookkeeping -----------------------------------------------------------------------------------
// Same algorithm as ParticleElement::_updateParticleEffects, with the effect creation / removal counted.
struct SubEffects
{
    struct Info { const void* particle; int effect; unsigned stamp; };
    std::list<Info> list;
    std::unordered_map<const void*, std::list<Info>::iterator> index;
    unsigned stamp = 0;
    int nextEffect = 1, created = 0, removed = 0;

    void update(const std::vector<const void*>& live)
    {
        ++stamp;
        for (const void* p : live)
        {
            auto f = index.find(p);
            if (f == index.end())
            {
                list.push_back(Info{p, 0, stamp});
                index[p] = --list.end();
            }
            else
                f->second->stamp = stamp;
        }
        for (auto& e : list)
            if (e.particle && e.stamp != stamp) { index.erase(e.particle); e.particle = nullptr; }
        for (auto i = list.begin(); i != list.end();)
        {
            if (!i->particle) { if (i->effect) ++removed; i = list.erase(i); continue; }
            if (!i->effect) { i->effect = nextEffect++; ++created; }
            ++i;
        }
    }
};

static void test_subeffect_sync()
{
    int a, b, c, d;
    SubEffects s;
    s.update({&a, &b});                 // two particles born
    CHECK(s.created == 2 && s.removed == 0 && s.list.size() == 2);
    CHECK(s.list.front().particle == &a && s.list.back().particle == &b);   // particle order
    s.update({&a, &b, &c});             // one more
    CHECK(s.created == 3 && s.list.size() == 3);
    s.update({&b, &c});                 // a dies: its effect goes back at once
    CHECK(s.removed == 1 && s.list.size() == 2 && s.list.front().particle == &b);
    s.update({&b, &c, &a});             // slot a reused later: a new effect
    CHECK(s.created == 4 && s.removed == 1);
    // same address alive across two updates (slot reused in between): keeps its effect, as B does
    const int effectOfB = s.list.front().effect;
    s.update({&b, &c, &a});
    CHECK(s.list.front().effect == effectOfB && s.created == 4);
    s.update({});                       // system cleared
    CHECK(s.list.empty() && s.index.empty() && s.removed == 4);
    s.update({&d});
    CHECK(s.created == 5 && s.list.size() == 1);
}

int main()
{
    test_window();
    test_scale_transform();
    test_create_level();
    test_subeffect_sync();
    if (g_fail == 0)
        std::printf("effects_math_test: PASS (all cases)\n");
    else
        std::printf("effects_math_test: FAIL (%d cases)\n", g_fail);
    return g_fail == 0 ? 0 : 1;
}
