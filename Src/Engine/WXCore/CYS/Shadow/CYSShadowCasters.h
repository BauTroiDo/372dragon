#ifndef __CYS_SHADOW_CASTERS_H__
#define __CYS_SHADOW_CASTERS_H__

// CY-Source (shadow agent): the shadow-caster pass (Docs\specs\render\03-shadows.md §4: casters render with the
// "Depth" programs of Character.program). While the atlas renders, this render-queue listener keeps only entities
// that cast and swaps their technique for a depth technique:
//   * casters: sub-entities whose Entity::getCastShadows() is true, in the caster queue groups, whose first pass
//     writes depth and is opaque or alpha-rejected (particles, billboards, ribbons, terrain tiles, sky and
//     transparent effects never cast);
//   * programs: B's Depth_[Skin|DQSkin]_[NoTex]_VS + Depth_[NoTex]_PS from MaterialTemplates.zip when they compile,
//     else our CYSShadowCaster.hlsl (static + skinned; media folder);
//   * hardware-skinned entities get the skinning variant (<= 74 bones per sub-mesh linear, <= 105 dual
//     quaternion), software-skinned and static ones the static variant (their vertices are already blended);
//   * alpha-rejected passes (hair, leaves) sample their diffuse texture and clip at the pass alpha reference;
//   * a material may bring its own technique for the scheme "CYSShadowCaster" (the atlas viewports' scheme);
//     it is then used unchanged.
// Output of every caster: linear light-view depth (-z in light view space) in .r.

#include <OgrePrerequisites.h> // first: OgreCommon.h uses the std containers it brings in
#include <OgreCommon.h>
#include <OgreRenderQueue.h>
#include <OgreResource.h>
#include <OgreString.h>

#include <map>
#include <utility>
#include <vector>

namespace Ogre
{
    class Entity;
    class Pass;
    class SubEntity;
    class Technique;
}

namespace WX
{
    class CYSShadowCasters : public Ogre::RenderQueue::RenderableListener
    {
    public:
        /// Material scheme of the atlas viewports
        static const Ogre::String SCHEME;

        CYSShadowCasters(void);
        ~CYSShadowCasters();

        /// Picks the caster programs (needs MaterialTemplates parsed); materials go to 'resourceGroup'.
        bool initialise(const Ogre::String& resourceGroup);
        bool isInitialised(void) const { return mProgramsOk; }
        /// Drops the caster materials and every cached decision.
        void shutdown(void);
        /// Forgets the per-technique decisions (materials changed); caster materials are kept.
        void clearCache(void);

        void setQueueRange(unsigned char minGroup, unsigned char maxGroup);
        void setAlphaTest(bool on);

        /// Called by the shadow system around the atlas update.
        void beginUpdate(void);
        void setCurrentCascade(size_t index);
        size_t getQueued(size_t cascade) const { return cascade < 4 ? mQueued[cascade] : 0; }

        const Ogre::String& getProgramSource(void) const { return mProgramSource; }
        size_t getCasterMaterialCount(void) const { return mMaterials.size(); }

        // Ogre::RenderQueue::RenderableListener
        bool renderableQueued(Ogre::Renderable* rend, Ogre::uint8 groupID, Ogre::ushort priority,
                              Ogre::Technique** ppTech);

    private:
        enum Skin { SKIN_NONE = 0, SKIN_LBS = 1, SKIN_DQ = 2, SKIN_COUNT = 3 };
        struct Programs
        {
            Ogre::String vs[SKIN_COUNT][2]; ///< [skin][0 = no texture, 1 = alpha-tested texture]
            Ogre::String fs[2];
            bool own;                       ///< CYSShadowCaster.hlsl (alpha reference as constant alphaRef)
        };
        struct Entry
        {
            Ogre::ResourceHandle material;  ///< handle of the source material: detects a recycled Technique*
            Ogre::Technique* caster;        ///< 0 = does not cast
        };
        typedef std::map<std::pair<Ogre::Technique*, int>, Entry> CacheMap;
        typedef std::map<Ogre::String, Ogre::Technique*> SharedMap;

        bool resolvePrograms(void);
        Ogre::Technique* casterFor(Ogre::Technique* src, Ogre::Entity* ent, Ogre::SubEntity* se);
        Ogre::Technique* buildCaster(Ogre::Pass* src, int skin, bool alpha);
        void logOnce(const Ogre::String& key, const Ogre::String& message);

        Ogre::String mGroup;
        Programs mPrograms;
        bool mProgramsOk;
        Ogre::String mProgramSource;
        unsigned char mQueueMin;
        unsigned char mQueueMax;
        bool mAlphaTest;
        size_t mCascade;
        size_t mQueued[4];
        size_t mSerial;
        CacheMap mCache;
        SharedMap mShared;                  ///< caster techniques by value key (shared by many sources)
        std::vector<Ogre::String> mMaterials;
        std::map<Ogre::String, bool> mLogged;
    };
}

#endif // __CYS_SHADOW_CASTERS_H__
