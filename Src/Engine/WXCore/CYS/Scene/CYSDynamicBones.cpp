// CY-Source (scene agent): see CYSDynamicBones.h.
#include "CYSDynamicBones.h"
#include "CYSXml.h"

#define TIXML_USE_STL
#include <tinyxml.h>

#include <algorithm>
#include <cstring>

namespace WX
{
    using namespace CYSScene;

    CYSDynBoneDef::CYSDynBoneDef(void)
        : updateRate(60), damping(0.1f), elasticity(0.1f), stiffness(0.1f), inert(0), friction(0), radius(0)
        , force(Ogre::Vector3::ZERO)
    {
    }
    //-----------------------------------------------------------------------
    CYSDynColliderDef::CYSDynColliderDef(void)
        : center(Ogre::Vector3::ZERO), orientation(Ogre::Quaternion::IDENTITY), radius(0.5f), height(0), invert(false)
    {
    }
    //-----------------------------------------------------------------------
    void CYSDynamicBonesData::clear(void)
    {
        fileName.clear();
        bones.clear();
        colliders.clear();
        effects.clear();
    }

    //////////////////////////////////////////////////////////////////////////
    // Solver
    //////////////////////////////////////////////////////////////////////////
    void CYSDynamicBoneChain::setup(const CYSDynBoneDef& def, const std::vector<int>& parents,
                                    const std::vector<Ogre::Vector3>& animPositions)
    {
        mDef = def;
        mTimeAccum = 0;
        mParticles.clear();
        const size_t n = std::min(parents.size(), animPositions.size());
        mParticles.resize(n);
        for (size_t i = 0; i < n; ++i)
        {
            Particle& p = mParticles[i];
            p.parent = parents[i];
            if (p.parent >= (int)i)
                p.parent = -1;      // parents must come first
            p.position = p.prevPosition = animPositions[i];
            p.restLength = p.parent >= 0 ? (animPositions[i] - animPositions[p.parent]).length() : 0.0f;
            p.colliding = false;
        }
    }
    //-----------------------------------------------------------------------
    void CYSDynamicBoneChain::reset(const std::vector<Ogre::Vector3>& animPositions)
    {
        for (size_t i = 0; i < mParticles.size() && i < animPositions.size(); ++i)
        {
            mParticles[i].position = mParticles[i].prevPosition = animPositions[i];
            mParticles[i].colliding = false;
        }
        mTimeAccum = 0;
    }
    //-----------------------------------------------------------------------
    void CYSDynamicBoneChain::update(Real dt, const std::vector<Ogre::Vector3>& animPositions,
                                     const Ogre::Vector3& ownerMove, const std::vector<CYSDynCapsule>& colliders)
    {
        if (mParticles.empty() || animPositions.size() < mParticles.size())
            return;
        const Real rate = mDef.updateRate > 0 ? mDef.updateRate : 60.0f;
        const Real stepDt = 1.0f / rate;
        mTimeAccum += std::max(0.0f, dt);
        int steps = (int)(mTimeAccum / stepDt);
        if (steps <= 0)
        {
            // Too early for a step: keep the root on the animation and the chain attached to it.
            const Ogre::Vector3 delta = animPositions[0] - mParticles[0].position;
            for (size_t i = 0; i < mParticles.size(); ++i)
            {
                mParticles[i].position += delta;
                mParticles[i].prevPosition += delta;
            }
            return;
        }
        if (steps > 3)
            steps = 3;      // after a hitch do not spend frames catching up
        mTimeAccum -= steps * stepDt;
        if (mTimeAccum > stepDt)
            mTimeAccum = 0;
        const Ogre::Vector3 stepMove = ownerMove / (Real)steps;
        for (int s = 0; s < steps; ++s)
            step(stepDt, animPositions, stepMove, colliders);
    }
    //-----------------------------------------------------------------------
    void CYSDynamicBoneChain::step(Real stepDt, const std::vector<Ogre::Vector3>& anim, const Ogre::Vector3& stepMove,
                                   const std::vector<CYSDynCapsule>& colliders)
    {
        // Force is expressed per 60 Hz step (Unity DynamicBone: force * timeVar).
        const Ogre::Vector3 force = mDef.force * (stepDt * 60.0f);

        // 1) Verlet integration with inertia.
        for (size_t i = 0; i < mParticles.size(); ++i)
        {
            Particle& p = mParticles[i];
            if (p.parent < 0)
            {
                p.prevPosition = p.position = anim[i];
                continue;
            }
            const Ogre::Vector3 v = p.position - p.prevPosition;
            const Ogre::Vector3 rmove = stepMove * mDef.inert;
            p.prevPosition = p.position + rmove;
            Real damping = mDef.damping;
            if (p.colliding)
                damping = std::min(1.0f, damping + mDef.friction);
            p.position += v * (1.0f - damping) + force + rmove;
        }

        // 2) Constraints, parents first.
        for (size_t i = 0; i < mParticles.size(); ++i)
        {
            Particle& p = mParticles[i];
            if (p.parent < 0)
                continue;
            const Particle& parent = mParticles[p.parent];
            const Ogre::Vector3 restPos = parent.position + (anim[i] - anim[p.parent]);

            // elasticity: pull toward the animated pose
            p.position += (restPos - p.position) * mDef.elasticity;

            // stiffness: bound the deviation from the animated pose
            if (mDef.stiffness > 0)
            {
                const Ogre::Vector3 d = restPos - p.position;
                const Real len = d.length();
                const Real maxLen = p.restLength * (1.0f - mDef.stiffness) * 2.0f;
                if (len > maxLen && len > 1e-6f)
                    p.position += d * ((len - maxLen) / len);
            }

            // colliders
            p.colliding = false;
            for (size_t c = 0; c < colliders.size(); ++c)
            {
                const CYSDynCapsule& cap = colliders[c];
                const Ogre::Vector3 ab = cap.b - cap.a;
                const Real ab2 = ab.squaredLength();
                Real t = ab2 > 0 ? (p.position - cap.a).dotProduct(ab) / ab2 : 0;
                t = saturate(t);
                const Ogre::Vector3 closest = cap.a + ab * t;
                Ogre::Vector3 d = p.position - closest;
                const Real dist = d.length();
                const Real r = cap.radius + mDef.radius;
                if (dist < 1e-6f)
                    continue;
                if (!cap.invert && dist < r)
                {
                    p.position = closest + d * (r / dist);
                    p.colliding = true;
                }
                else if (cap.invert && dist > r)
                {
                    p.position = closest + d * (r / dist);
                    p.colliding = true;
                }
            }

            // keep the bone length
            const Ogre::Vector3 dd = p.position - parent.position;
            const Real len = dd.length();
            if (len > 1e-6f)
                p.position = parent.position + dd * (p.restLength / len);
        }
    }

    //////////////////////////////////////////////////////////////////////////
    // Parser
    //////////////////////////////////////////////////////////////////////////
    namespace
    {
        const char* const kKind = "DynBone";
        const char* const kRootChildren[] = { "DynamicBones", "Colliders", "Effects", NULL };
        const char* const kBonesChildren[] = { "DynamicBone", NULL };
        const char* const kBoneAttrs[] =
        {
            "Bone", "UpdateRate", "Damping", "Elasticity", "Stiffness", "Inert", "Friction", "Radius", "Force", NULL
        };
        const char* const kBoneChildren[] = { "CurveParams", NULL };
        const char* const kCurveAttrs[] =
        {
            "DampingACParam", "ElasticityACParam", "StiffnessACParam", "InertACParam", "FrictionACParam", NULL
        };
        const char* const kCollidersChildren[] = { "CapsuleCollider", NULL };
        const char* const kCapsuleAttrs[] = { "Bone", "Center", "Orientation", "Radius", "Height", "Invert", NULL };
        const char* const kEffectsChildren[] = { "Effect", NULL };
    }
    //-----------------------------------------------------------------------
    bool CYSScene::parseDynamicBones(const TiXmlElement* root, const String& file, CYSDynamicBonesData& out,
                                     String* error)
    {
        out.clear();
        out.fileName = file;
        if (!root || strcmp(root->Value(), "EntityDynamicBones") != 0)
        {
            if (error)
                *error = "root element is not <EntityDynamicBones>";
            return false;
        }
        checkXmlKeys(root, NULL, kRootChildren, kKind, "EntityDynamicBones", file);

        if (const TiXmlElement* list = root->FirstChildElement("DynamicBones"))
        {
            checkXmlKeys(list, NULL, kBonesChildren, kKind, "EntityDynamicBones/DynamicBones", file);
            for (const TiXmlElement* b = list->FirstChildElement("DynamicBone"); b; b = b->NextSiblingElement("DynamicBone"))
            {
                const String p = "EntityDynamicBones/DynamicBones/DynamicBone";
                checkXmlKeys(b, kBoneAttrs, kBoneChildren, kKind, p, file);
                CYSDynBoneDef def;
                def.bone = attrString(b, "Bone");
                def.updateRate = attrReal(b, "UpdateRate", def.updateRate);
                def.damping = attrReal(b, "Damping", def.damping);
                def.elasticity = attrReal(b, "Elasticity", def.elasticity);
                def.stiffness = attrReal(b, "Stiffness", def.stiffness);
                def.inert = attrReal(b, "Inert", def.inert);
                def.friction = attrReal(b, "Friction", def.friction);
                def.radius = attrReal(b, "Radius", def.radius);
                def.force = parseVector3(attr(b, "Force"), def.force);
                if (const TiXmlElement* c = b->FirstChildElement("CurveParams"))
                {
                    checkXmlKeys(c, kCurveAttrs, NULL, kKind, p + "/CurveParams", file);
                    def.dampingCurve = attrString(c, "DampingACParam");
                    def.elasticityCurve = attrString(c, "ElasticityACParam");
                    def.stiffnessCurve = attrString(c, "StiffnessACParam");
                    def.inertCurve = attrString(c, "InertACParam");
                    def.frictionCurve = attrString(c, "FrictionACParam");
                }
                out.bones.push_back(def);
            }
        }
        if (const TiXmlElement* list = root->FirstChildElement("Colliders"))
        {
            checkXmlKeys(list, NULL, kCollidersChildren, kKind, "EntityDynamicBones/Colliders", file);
            for (const TiXmlElement* c = list->FirstChildElement("CapsuleCollider"); c;
                 c = c->NextSiblingElement("CapsuleCollider"))
            {
                checkXmlKeys(c, kCapsuleAttrs, NULL, kKind, "EntityDynamicBones/Colliders/CapsuleCollider", file);
                CYSDynColliderDef def;
                def.bone = attrString(c, "Bone");
                def.center = parseVector3(attr(c, "Center"), def.center);
                def.orientation = parseQuaternion(attr(c, "Orientation"), def.orientation);
                def.radius = attrReal(c, "Radius", def.radius);
                def.height = attrReal(c, "Height", def.height);
                def.invert = attrBool(c, "Invert", false);
                out.colliders.push_back(def);
            }
        }
        if (const TiXmlElement* list = root->FirstChildElement("Effects"))
        {
            checkXmlKeys(list, NULL, kEffectsChildren, kKind, "EntityDynamicBones/Effects", file);
            for (const TiXmlElement* e = list->FirstChildElement("Effect"); e; e = e->NextSiblingElement("Effect"))
            {
                // No <Effect> exists in client_GL; its attributes are unknown, keep them all (reported as deferred).
                CYSDynEffectDef def;
                for (const TiXmlAttribute* a = e->FirstAttribute(); a; a = a->Next())
                {
                    def.attributes[a->Name()] = a->Value();
                    CYSSceneStats::instance().deferred(String("DynBone Effect@") + a->Name());
                }
                out.effects.push_back(def);
            }
        }
        return true;
    }
    //-----------------------------------------------------------------------
    bool CYSScene::loadDynamicBones(const String& name, const String& group, CYSDynamicBonesData& out, String* error)
    {
        TiXmlDocument doc;
        if (!loadXmlResource(doc, name, group, error))
        {
            out.clear();
            return false;
        }
        return parseDynamicBones(doc.RootElement(), name, out, error);
    }
    //-----------------------------------------------------------------------
    String CYSScene::dynamicBonesNameForMesh(const String& meshName)
    {
        const size_t dot = meshName.find_last_of('.');
        const size_t slash = meshName.find_last_of("/\\");
        if (dot == String::npos || (slash != String::npos && dot < slash))
            return meshName + ".dynbone";
        return meshName.substr(0, dot) + ".dynbone";
    }
}
