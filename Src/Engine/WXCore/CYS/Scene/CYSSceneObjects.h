#ifndef __CYS_SCENEOBJECTS_H__
#define __CYS_SCENEOBJECTS_H__










#include "Core/WXObject.h"
#include "Core/WXPlacementObject.h"
#include "Core/WXPropertyInterface.h"

#include <OgreColourValue.h>

namespace Ogre
{
    class Light;
}

namespace WX
{
    class ObjectFactory;
    class ObjectFactoryManager;
    class System;

    /// Property command that keeps the value as text in Object::setCYSExtraProperty (type "String").
    /// doGet returns an empty Variant on purpose: typed readers (e.g. the incremental scene builder's
    /// "position" lookup) must not see a String where they expect a Vector3.
    class CYSStoredPropertyCommand : public PropertyCommand
    {
    public:
        explicit CYSStoredPropertyCommand(const String& name) : mName(name) {}

        Variant doGet(const void* source) const;
        void doSet(void* target, const Variant& value);
        String doGetAsString(const void* source) const;
        void doSetAsString(void* target, const String& value);

    private:
        String mName;
    };

    //////////////////////////////////////////////////////////////////////////
    /// "#FairyEnScene": names the .EnScene file; `enabled` is set by SceneInfo::load after loading it (as B).
    class CYSEnSceneObject : public Object
    {
    public:
        CYSEnSceneObject(void);
        virtual ~CYSEnSceneObject();

        const String& getType(void) const;
        const String& getCategory(void) const;
        void createRenderInstance(System* system) {}
        void destroyRenderInstance(void) {}
        void updateRenderInstance(void) {}

        static const String msType;
        static const String msCategory;
        static ObjectFactory* getFactory(void);

    public:     // property commands only
        String mConfigFile;
        bool mEnabled;
    };

    //////////////////////////////////////////////////////////////////////////
    /// "#FairySkySphere": the sky of the .skysphere named by the <SkySphere> header element.
    class CYSSkySphereObject : public Object
    {
    public:
        CYSSkySphereObject(void);
        virtual ~CYSSkySphereObject();

        const String& getType(void) const;
        const String& getCategory(void) const;
        void createRenderInstance(System* system) {}
        void destroyRenderInstance(void) {}
        void updateRenderInstance(void) {}

        static const String msType;
        static const String msCategory;
        static ObjectFactory* getFactory(void);

    public:     // property commands only
        bool mEnabled;
    };

    //////////////////////////////////////////////////////////////////////////
    /// FakeLight: in B/CY a screen-space light box (Mtl_FakePointLight, needs scene depth) of half extent 50 units x
    /// scale, colour diffuse x intensity x EnvKey fake_point_light_intensity.
    /// CYS-PARITY (d3d9-trace): drawn as that box, like CY 3.71 (trace: 12 triangles per light, blend dest_colour/one,
    /// cull anticlockwise, depth off, lightParams = (diffuse x intensity, size), globalIntensity 1) reading the
    /// CysPostFX linear depth; CYS_FAKELIGHT_MODE=light keeps the older OGRE point-light approximation.
    class CYSFakeLightObject : public PlacementObject
    {
    public:
        CYSFakeLightObject(void);
        virtual ~CYSFakeLightObject();

        const String& getType(void) const;
        const String& getCategory(void) const;
        void createRenderInstance(System* system);
        void destroyRenderInstance(void);
        void updateRenderInstance(void);

        /// World-space radius of the light volume (50 units x largest scale component).
        Real getRadius(void) const;
        /// diffuse x intensity (without the global EnvKey factor).
        Ogre::ColourValue getColour(void) const { return mDiffuse * mIntensity; }
        Ogre::Light* getLight(void) const { return mLight; }

        /// Re-applies colour/range to the OGRE light (creates or destroys it according to the global switch).
        void applyLight(void);

        static const String msType;
        static const String msCategory;
        static ObjectFactory* getFactory(void);

    protected:
        Ogre::Light* mLight;
        Ogre::Entity* mVolume;          ///< CYS-PARITY: light box (Mtl_FakePointLight clone)
        String mVolumeMaterial;

        bool applyVolume(const Ogre::ColourValue& colour);
        void destroyVolume(void);

    public:     // property commands only
        Real mSize;
        Ogre::ColourValue mDiffuse;
        Real mIntensity;
        Real mBeginBrightness;
        Real mEndBrightness;
    };

    //////////////////////////////////////////////////////////////////////////
    /// Object whose properties are all stored verbatim (SceneConfig, HierarchyNode, unknown types).
    class CYSPropertyBagObject : public Object
    {
    public:
        CYSPropertyBagObject(const String& type, const String& category, const char* const* propertyNames);
        virtual ~CYSPropertyBagObject();

        const String& getType(void) const { return mType; }
        const String& getCategory(void) const { return mCategory; }
        void createRenderInstance(System* system) {}
        void destroyRenderInstance(void) {}

        String getString(const String& name, const String& def = String()) const;
        Real getReal(const String& name, Real def) const;
        bool getBool(const String& name, bool def) const;

    private:
        String mType;
        String mCategory;
    };

    namespace CYSScene
    {
        /// Extra-property key holding the <Group name> path of an object (B/C editor grouping in .Scene).
        extern const String GROUP_PROPERTY;

        /// Adds stored (verbatim) definitions for `names` missing from the class dictionary of `instance`.
        size_t addStoredProperties(PropertyInterface* instance, const char* const* names);
        /// Registers EnScene, SkySphere, FakeLight, SceneConfig, HierarchyNode, Projector and the stored B
        /// properties of the 0.85 types. Call after the 0.85 factories are registered (System hook).
        void registerSceneObjectTypes(ObjectFactoryManager* manager);
        /// Object for a type that has no factory: every property ends up stored verbatim.
        ObjectPtr createGenericObject(const String& type);
        /// SceneSerializer hook for a property the object's class does not define: stored + reported.
        void onUnknownProperty(Object& object, const String& name, const String& value, const String& file);

        /// FakeLight approximation switch (default on; environment variable CYS_FAKELIGHT=0 turns it off).
        void setFakeLightsEnabled(bool enabled);
        bool getFakeLightsEnabled(void);
        /// EnvKey fake_point_light_intensity; re-applies every live FakeLight when it changes.
        void setFakeLightGlobalIntensity(Real intensity);
        Real getFakeLightGlobalIntensity(void);
        size_t getNumLiveFakeLights(void);
    }
}

#endif // __CYS_SCENEOBJECTS_H__
