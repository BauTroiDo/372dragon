#include "WXObject.h"

namespace WX
{
    Object::Object(void)
        : mName()
		, mData(0)
        , mCYSExtraProperties(NULL)     // CYS
    {
    }
    //-----------------------------------------------------------------------
    Object::~Object()
    {
        delete mCYSExtraProperties;     // CYS
    }
    //-----------------------------------------------------------------------
    // CYS: verbatim B/C properties (see WXObject.h).
    const String* Object::getCYSExtraProperty(const String& name) const
    {
        if (!mCYSExtraProperties)
            return NULL;
        CYSExtraProperties::const_iterator it = mCYSExtraProperties->find(name);
        return it == mCYSExtraProperties->end() ? NULL : &it->second;
    }
    //-----------------------------------------------------------------------
    void Object::setCYSExtraProperty(const String& name, const String& value)
    {
        if (!mCYSExtraProperties)
            mCYSExtraProperties = new CYSExtraProperties;
        (*mCYSExtraProperties)[name] = value;
    }
    //-----------------------------------------------------------------------
    void Object::setName(const String& name)
    {
        mName = name;
    }
    //-----------------------------------------------------------------------
    void Object::setData(size_t data)	// CYS: was ulong (pointer truncation on x64)
    {
        mData = data;
    }
    //-----------------------------------------------------------------------
    void Object::queryReferenceResources(ResourceCollection* resourceCollection)
    {
    }
    //-----------------------------------------------------------------------
    void Object::queryBakableEntities(EntityList& entities)
    {
    }
    //-----------------------------------------------------------------------
    void Object::bakeStaticGeometry(Ogre::StaticGeometry* staticGeometry, const EntityList& entity)
    {
    }
    //-----------------------------------------------------------------------
    void Object::processMessage(const String& msg, const Variant& params)
    {
    }
}
