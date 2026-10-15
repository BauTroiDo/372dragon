#ifndef __CYS_PROJECTOROBJECT_H__
#define __CYS_PROJECTOROBJECT_H__

// CY-Source (fix-projector 15/09/2026): scene object "Projector" as CY 3.71 Render.dll Fairy::ProjectorObject
// (FairyProjectorObject.cpp; Ghidra Build/re/fix-projector/out/proj_xref.txt):
//   ctor FUN_18012a240 (19 properties + defaults), createRenderInstance FUN_18012b810, updateMaterial FUN_18012e980,
//   _getFovFromProjectionSize FUN_18012b580, BlendModeCmd FUN_18012e100/FUN_18012cde0 (labels at 0x1802e07e0).
// A decal: an orthographic WX::Projector pointing down (-Y of the object frame) that draws `texture name` on the
// terrain with its own material "ProjectorObjectMaterial<N>" (no lighting, depth write off, depth bias 1, clamp,
// texture x projector colour, blend mode, fog forced to white for modulate/colour_blend).
// Before this class the type was a verbatim property bag (ci-cy 6b7cdef) whose stored "create level" returned an
// empty Variant; SceneInfo::initialise cast it to Real -> boost::bad_any_cast, TlbbViewer died on luoyang_new and
// suzhou_new (Build/Logs/2026-09-14-fix-projector).

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
