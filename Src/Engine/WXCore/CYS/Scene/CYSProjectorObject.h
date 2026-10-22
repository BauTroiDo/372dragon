#ifndef __CYS_PROJECTOROBJECT_H__
#define __CYS_PROJECTOROBJECT_H__












#include "Core/WXPlacementObject.h"

#include <OgreColourValue.h>
#include <OgreMaterial.h>

namespace WX
{
    class ObjectFactory;
    class Projector;

    class CYSProjectorObject : public PlacementObject
    {
    public:
        CYSProjectorObject(void);
        virtual ~CYSProjectorObject();

        const String& getType(void) const;
        const String& getCategory(void) const;
        void createRenderInstance(System* system);
        void destroyRenderInstance(void);
        void updateRenderInstance(void);

        /// The OGRE projector (NULL while CY would not create one: BaseWhite / missing texture / no render instance).
        Projector* getProjector(void) const { return mProjector; }
        /// Texture actually used (CY rename rule "x.jpg" -> "jpg_x.dds" applied when the file is missing).
        const String& getResolvedTextureName(void) const { return mResolvedTexture; }

        /// Number of live OGRE projectors created by scene Projector objects (tests / viewer log).
        static size_t getNumLiveProjectors(void);

        static const String msType;
        static const String msCategory;
        static ObjectFactory* getFactory(void);

    protected:
        void createProjector(void);
        void destroyProjector(void);
        bool resolveTexture(String& name) const;
        void buildMaterial(const String& texture);

        Projector* mProjector;
        Ogre::SceneNode* mProjectorNode;
        Ogre::MaterialPtr mMaterial;
        String mResolvedTexture;

    public:     // property commands only (CY offsets in the comment)
        String mTextureName;            // +0xc8 "texture name", default "BaseWhite"
        Real mProjectorSize;            // +0xf8 "projector size", 200
        Real mUScale;                   // +0xfc "U Scale", 1
        Real mVScale;                   // +0x100 "V Scale", 1
        Ogre::ColourValue mColour;      // +0x104 "projector colour", white
        bool mShowFrustum;              // +0x114 "show frustum", true
        Real mNearClip;                 // +0x118 "near clip distance", 100
        Real mFarClip;                  // +0x11c "far clip distance", 1000
        bool mUWave;                    // +0x120 "u wave", false
        bool mVWave;                    // +0x121 "v wave", false
        Real mWaveFrequency;            // +0x124 "wave frequency", 0.1
        Real mWaveAmplitude;            // +0x128 "wave amplitude", 0.05
        int mBlendMode;                 // +0x12c "blend mode" (Ogre::SceneBlendType), 3 = modulate
        int mTerrainGridLimit;          // +0x130 "terrain grid limit", 256
        int mVertexLimit;               // +0x134 "vertex limit", 4096
    };
}

#endif
