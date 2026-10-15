#ifndef __CYS_POSTFX_DEPTH_H__
#define __CYS_POSTFX_DEPTH_H__

// CY-Source (post-processing agent, 2026-09-12): depth techniques for the SceneDepth node (02-postfx.md 1).
//
// B renders the node with material scheme "Depth", whose techniques its material system generates at run time
// (Depth_VS / Depth_Skin_VS / Depth_PS of Character.program; R = -viewZ). Until the CY-Source material system
// provides "Depth" techniques, this class supplies an equivalent per renderable: static or hardware-skinned
// (1..4 weights, up to 80 bones), culled or double-sided, optionally alpha-tested with the material's first
// texture. A renderable whose technique already belongs to scheme "Depth" keeps it; transparent renderables and
// renderables that do not write depth are left out of the depth target.

#include "PostFilter/WXPostFilterPrerequisites.h"

#include <OgreMaterial.h>

#include <map>
#include <utility>

namespace Ogre
{
    class Renderable;
    class Technique;
}

namespace WX
{
    class CysDepthMaterials
    {
    public:
        /// Maximum bones per hardware-skinned renderable (world_matrix_array_3x4 of the depth vertex shader).
        static const size_t MAX_BONES = 80;
        static const String& getSchemeName(void);

        CysDepthMaterials(void);
        ~CysDepthMaterials();

        /// Technique that writes linear depth for `rend`; 0 = keep it out of the depth target.
        Ogre::Technique* choose(Ogre::Renderable* rend);
        /// Forgets the per-source decisions (source techniques may have been recompiled).
        void clearCache(void) { mBySource.clear(); }
        size_t getMaterialCount(void) const { return mMaterials.size(); }

    private:
        Ogre::Technique* get(int weights, bool noCull, const String& alphaTexture, unsigned char alphaRef);

        typedef std::pair<Ogre::Technique*, int> SourceKey;
        std::map<SourceKey, Ogre::Technique*> mBySource;
        std::map<String, Ogre::MaterialPtr> mMaterials;
        bool mWarnedLimit;
    };
}

#endif // __CYS_POSTFX_DEPTH_H__
