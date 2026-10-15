#ifndef __FAIRYOBJECT_H__
#define __FAIRYOBJECT_H__

#include "WXPropertyInterface.h"

#include <boost/shared_ptr.hpp>
#include <boost/weak_ptr.hpp>
#include <boost/enable_shared_from_this.hpp>

namespace WX
{
    class System;
    class ResourceCollection;
    struct ObjectSetIndices;

    typedef std::list<Ogre::Entity*> EntityList;

    class Object : public PropertyInterface, public boost::enable_shared_from_this<Object>
    {
        // Allow ObjectSetIndices access mName to simply multi-index container adaptor
        friend struct ObjectSetIndices;

    protected:
        String mName;
		size_t mData;	// CYS: was ulong (32-bit on Win64); holds a pointer (WXRender RFObj.cpp stores `this`)
        // CYS: B/C scene properties this 0.85 class does not model (uuid, lockHeight, ...) kept verbatim, so a
        //      scene loads without losing them and SceneSerializer::save writes them back. Created on first use.
        std::map<String, String>* mCYSExtraProperties;

    public:
        Object(void);
        virtual ~Object();

        // CYS: access to mCYSExtraProperties (see CYS/Scene/CYSSceneObjects.h).
        typedef std::map<String, String> CYSExtraProperties;
        const CYSExtraProperties* getCYSExtraProperties(void) const
        {
            return mCYSExtraProperties;
        }
        const String* getCYSExtraProperty(const String& name) const;
        void setCYSExtraProperty(const String& name, const String& value);

        const String& getName(void) const
        {
            return mName;
        }

        void setName(const String& name);

		size_t getData(void) const	// CYS: was ulong (x64)
        {
            return mData;
        }

        void setData(size_t data);	// CYS: was ulong (x64)

        virtual const String& getType(void) const = 0;
        virtual const String& getCategory(void) const = 0;

        virtual void queryReferenceResources(ResourceCollection* resourceCollection);

        virtual void queryBakableEntities(EntityList& entities);
        virtual void bakeStaticGeometry(Ogre::StaticGeometry* staticGeometry, const EntityList& entities);

        virtual void createRenderInstance(System* system) = 0;
        virtual void destroyRenderInstance(void) = 0;

        virtual void processMessage(const String& msg, const Variant& params);
    };

    typedef boost::shared_ptr<Object> ObjectPtr;
    typedef boost::weak_ptr<Object> ObjectWeakPtr;

}

#endif 
