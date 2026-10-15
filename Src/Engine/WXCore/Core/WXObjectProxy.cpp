#include "WXObjectProxy.h"
#include <OgreMovableObject.h>

namespace WX
{

    const String ObjectProxy::msTypeName = "WX::ObjectProxy";
    // CYS: Ogre::UserDefinedObject::getTypeID() returns long (32-bit on Win64); keep the address-derived id but
    // truncate explicitly (only identity comparison is done with it).
    const long ObjectProxy::msTypeID = static_cast<long>(reinterpret_cast<intptr_t>(&msTypeName));
    //-----------------------------------------------------------------------
    ObjectProxy::ObjectProxy(void)
        : mObject()
    {
    }
    //-----------------------------------------------------------------------
    ObjectProxy::ObjectProxy(const ObjectPtr& object)
        : mObject(object)
    {
    }
    //-----------------------------------------------------------------------
    ObjectProxy::~ObjectProxy()
    {
    }
    //-----------------------------------------------------------------------
    long ObjectProxy::getTypeID(void) const
    {
        return msTypeID;
    }
    //-----------------------------------------------------------------------
    const String& ObjectProxy::getTypeName(void) const
    {
        return msTypeName;
    }
    //-----------------------------------------------------------------------
    void ObjectProxy::setObject(const ObjectPtr& object)
    {
        mObject = object;
    }
    //-----------------------------------------------------------------------
    ObjectPtr ObjectProxy::getObject(void) const
    {
        return mObject.lock();
    }

    //-----------------------------------------------------------------------
    ObjectPtr getObjectFromMovable(Ogre::MovableObject* movable)
    {
        assert(movable);
        if (movable)
        {
            const Ogre::Any& any = movable->getUserAny();
            if (any.getType() == typeid(Ogre::UserDefinedObject*))
            {
                Ogre::UserDefinedObject* userObject = Ogre::any_cast<Ogre::UserDefinedObject*>(any);
                if (userObject && userObject->getTypeID() == ObjectProxy::msTypeID)
                {
                    ObjectProxy* proxy = static_cast<ObjectProxy*>(userObject);
                    return proxy->getObject();
                }
            }
        }

        return ObjectPtr();
    }

}
