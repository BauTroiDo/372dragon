#ifndef __CYS_DYNAMICBONES_H__
#define __CYS_DYNAMICBONES_H__









#include "CYSSceneCommon.h"

class TiXmlElement;

namespace WX
{
    struct CYSDynBoneDef
    {
        String bone;                ///< root bone of the chain (the chain = the bone and its descendants)
        Real updateRate;            ///< simulation steps per second
        Real damping, elasticity, stiffness, inert, friction, radius;
        Ogre::Vector3 force;        ///< per-step force at 60 Hz (Unity semantics, INF)
        String dampingCurve, elasticityCurve, stiffnessCurve, inertCurve, frictionCurve;   ///< all empty in data
        CYSDynBoneDef(void);
    };

    struct CYSDynColliderDef
    {
        String bone;
        Ogre::Vector3 center;           ///< bone-local
        Ogre::Quaternion orientation;   ///< bone-local (w x y z); the capsule axis is its local X (Biped bones)
        Real radius, height;
        bool invert;                    ///< keep particles inside instead of outside
        CYSDynColliderDef(void);
    };

    struct CYSDynEffectDef
    {
        std::map<String, String> attributes;    ///< no <Effect> exists in client_GL; kept verbatim
    };

    struct CYSDynamicBonesData
    {
        String fileName;
        std::vector<CYSDynBoneDef> bones;
        std::vector<CYSDynColliderDef> colliders;
        std::vector<CYSDynEffectDef> effects;
        void clear(void);
    };

    /// World-space capsule used by the solver.
    struct CYSDynCapsule
    {
        Ogre::Vector3 a, b;     ///< end points of the axis segment
        Real radius;
        bool invert;
    };

    /// Verlet chain of one DynamicBone definition: particle 0 is the root (follows the animation), every other
    /// particle keeps its rest length to its parent, is pulled to the animated pose by `elasticity`, limited by
    /// `stiffness`, carried by the owner motion by `inert`, damped by `damping` (+ `friction` while touching a
    /// collider) and pushed out of capsules.
    class CYSDynamicBoneChain
    {
    public:
        struct Particle
        {
            int parent;                 ///< index of the parent particle, -1 for the root
            Real restLength;
            Ogre::Vector3 position;
            Ogre::Vector3 prevPosition;
            bool colliding;
        };

        CYSDynamicBoneChain(void) : mTimeAccum(0) {}

        /// `parents` (parents before children) and `animPositions` describe the chain in its animated pose.
        void setup(const CYSDynBoneDef& def, const std::vector<int>& parents,
                   const std::vector<Ogre::Vector3>& animPositions);
        /// Advances by `dt` seconds with fixed steps of 1/updateRate. `ownerMove` is the world displacement of
        /// the owning object since the previous call.
        void update(Real dt, const std::vector<Ogre::Vector3>& animPositions, const Ogre::Vector3& ownerMove,
                    const std::vector<CYSDynCapsule>& colliders);
        void reset(const std::vector<Ogre::Vector3>& animPositions);

        const std::vector<Particle>& getParticles(void) const { return mParticles; }
        const CYSDynBoneDef& getDef(void) const { return mDef; }

    private:
        void step(Real stepDt, const std::vector<Ogre::Vector3>& animPositions, const Ogre::Vector3& stepMove,
                  const std::vector<CYSDynCapsule>& colliders);

        CYSDynBoneDef mDef;
        std::vector<Particle> mParticles;
        Real mTimeAccum;
    };

    namespace CYSScene
    {
        bool parseDynamicBones(const TiXmlElement* root, const String& file, CYSDynamicBonesData& out, String* error);
        bool loadDynamicBones(const String& name, const String& group, CYSDynamicBonesData& out, String* error);
        /// "<dir>/<mesh base>.mesh" -> "<dir>/<mesh base>.dynbone" (the B lookup name).
        String dynamicBonesNameForMesh(const String& meshName);
    }
}

#endif // __CYS_DYNAMICBONES_H__
