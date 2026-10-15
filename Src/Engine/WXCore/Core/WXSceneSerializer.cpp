#include "WXSceneSerializer.h"
#include "WXScene.h"
#include "WXObjectFactoryManager.h"
#include "WXResources.h"
#include "WXXMLAttributes.h"
#include "WXXMLHandler.h"
#include "WXXMLParser.h"
#include "WXXMLNode.h"
#include "WXXMLWriter.h"
#include "CYS/Scene/CYSSceneCommon.h"   // CYS
#include "CYS/Scene/CYSSceneObjects.h"  // CYS

#include <OgreStringConverter.h>

namespace WX
{
static const String CURRENT_FORMAT_VERSION = "0.1.1";

/*!
\brief
	Handler class used to parse the Scene XML files using SAX2
*/
class SceneXMLHandler : public XMLHandler
{
public:
	/*************************************************************************
		Construction & Destruction
	*************************************************************************/

	/** 
		Constructor for SceneXMLHandler objects
	*/
	SceneXMLHandler(Scene* scene, const String& fileName);  // CYS: + file name for the logs

	/** Destructor for SceneXMLHandler objects */
	~SceneXMLHandler(void);

	/*************************************************************************
		SAX2 Handler overrides
	*************************************************************************/ 

    /** Overridden from XMLHandler */
	virtual void characters(const String& chars);

    /** Overridden from XMLHandler */
	virtual void startElement(const String& element, const XMLAttributes& attributes);

    /** Overridden from XMLHandler */
    virtual void endElement(const String& element);

protected:

    typedef std::map<String, String> NameMap;
    typedef std::map<String, NameMap> NameCollectionMap;

    Scene* mScene;
    NameCollectionMap mPropertyNameCollectionMap;
    const NameMap* mPropertyNameMap;
    ObjectPtr mObject;
    String mAttributeName;
    String mAttributeValue;
    String* mString;

    // CYS: B/C scene format (Docs/specs/render/05 §1): file name for the logs, open <Group> elements.
    String mFileName;
    std::vector<String> mGroups;
    String mGroupPath;

    void updateGroupPath(void);
    void checkAttributes(const String& element, const XMLAttributes& attributes, const char* const* allowed);
};

//////////////////////////////////////////////////////////////////////////

SceneXMLHandler::SceneXMLHandler(Scene* scene, const String& fileName)
    : mScene(scene)
    , mPropertyNameCollectionMap()
    , mPropertyNameMap()
    , mObject()
    , mAttributeName()
    , mAttributeValue()
    , mString()
    , mFileName(fileName)   // CYS
    , mGroups()
    , mGroupPath()
{
}

SceneXMLHandler::~SceneXMLHandler(void)
{
}

// CYS: "a/b" path of the open <Group> elements (stored on each object as CYSScene::GROUP_PROPERTY).
void SceneXMLHandler::updateGroupPath(void)
{
    mGroupPath.clear();
    for (size_t i = 0; i < mGroups.size(); ++i)
    {
        if (i)
            mGroupPath += "/";
        mGroupPath += mGroups[i];
    }
}

// CYS: attributes that the (0.85 + B/C) reader does not consume are reported once instead of being lost silently.
void SceneXMLHandler::checkAttributes(const String& element, const XMLAttributes& attributes, const char* const* allowed)
{
    for (size_t i = 0; i < attributes.getCount(); ++i)
    {
        const String& name = attributes.getName(i);
        bool ok = false;
        for (const char* const* a = allowed; a && *a; ++a)
        {
            if (name == *a)
            {
                ok = true;
                break;
            }
        }
        if (!ok)
            CYSSceneStats::instance().unknown("Scene attribute " + element + "@" + name, mFileName);
    }
}

//////////////////////////////////////////////////////////////////////////

void SceneXMLHandler::characters(const String& chars)
{
    if (mString)
    {
        mString->append(chars);
    }
}

void
SceneXMLHandler::startElement(const String& element, const XMLAttributes& attributes)
{
    static const char* const kPropertyAttrs[] = { "name", "value", 0 };    // CYS
    static const char* const kObjectAttrs[] = { "type", "name", 0 };
    static const char* const kNameAttr[] = { "name", 0 };
    static const char* const kSceneAttrs[] = { "formatVersion", "name", 0 };
    static const char* const kFilenameAttr[] = { "filename", 0 };
    static const char* const kSkySphereAttrs[] = { "enabled", "filename", "objectname", 0 };
    static const char* const kSchemeAttr[] = { "scheme", 0 };

    if (element == "Property")
    {
        assert(mObject);
        checkAttributes(element, attributes, kPropertyAttrs);     // CYS

        const String* name = &attributes.getValue("name");
        const String& value = attributes.getValue("value");
        if (mPropertyNameMap)
        {
            NameMap::const_iterator it = mPropertyNameMap->find(*name);
            if (it != mPropertyNameMap->end())
                name = &it->second;
        }

        // CYS: a property the class does not define is kept verbatim and reported once (0.85 dropped it
        //      silently); a malformed value no longer aborts the whole scene.
        bool known = true;
        try
        {
            known = mObject->setPropertyAsString(*name, value);
        }
        catch (const Ogre::Exception& e)
        {
            mObject->setCYSExtraProperty(*name, value);
            CYSSceneStats::instance().problem("Scene property value " + mObject->getType() + "." + *name +
                                              " (" + e.getDescription() + ")", mFileName);
        }
        catch (const std::exception& e)
        {
            mObject->setCYSExtraProperty(*name, value);
            CYSSceneStats::instance().problem("Scene property value " + mObject->getType() + "." + *name +
                                              " (" + e.what() + ")", mFileName);
        }
        if (!known)
            CYSScene::onUnknownProperty(*mObject, *name, value, mFileName);
    }
    else if (element == "Object")
    {
        assert(!mObject);
        checkAttributes(element, attributes, kObjectAttrs);       // CYS

        const String& type = attributes.getValue("type");

        // CYS: an object type without factory becomes a property bag (reported once) instead of aborting.
        ObjectFactoryManager& factories = ObjectFactoryManager::getSingleton();
        if (factories.hasFactory(type))
        {
            mObject = factories.createInstance(type);
        }
        else
        {
            mObject = CYSScene::createGenericObject(type);
            CYSSceneStats::instance().unknown("Scene object type " + type, mFileName);
        }
        CYSSceneStats::instance().count("Scene object " + type);

        String objectName = attributes.exists("name") ? attributes.getValue("name")
                                                      : mScene->generateAutoName(mObject);
        // CYS: a duplicate name would make Scene::addObject throw; keep the object under a unique name.
        if (mScene->findObjectByName(objectName))
        {
            CYSSceneStats::instance().problem("Scene duplicate object name", mFileName);
            String unique;
            size_t n = 1;
            do
            {
                unique = objectName + "#" + Ogre::StringConverter::toString(n++);
            }
            while (mScene->findObjectByName(unique));
            objectName = unique;
        }
        mObject->setName(objectName);
        if (!mGroupPath.empty())
            mObject->setCYSExtraProperty(CYSScene::GROUP_PROPERTY, mGroupPath);   // CYS: <Group> container
        mScene->addObject(mObject);

        NameCollectionMap::const_iterator it = mPropertyNameCollectionMap.find(type);
        if (it != mPropertyNameCollectionMap.end())
        {
            mPropertyNameMap = &it->second;
        }
    }
    else if (element == "Attribute")
    {
        assert(!mString);
        checkAttributes(element, attributes, kNameAttr);          // CYS
        mAttributeName = attributes.getValue("name");
        mAttributeValue.clear();
        mString = &mAttributeValue;
    }
    else if (element == "Terrain")
    {
        checkAttributes(element, attributes, kFilenameAttr);      // CYS
        mScene->mTerrainFilename = attributes.getValue("filename");
    }
    else if (element == "Scene")
    {
        checkAttributes(element, attributes, kSceneAttrs);        // CYS
        String formatVersion = attributes.getValue("formatVersion");
        if (formatVersion != CURRENT_FORMAT_VERSION &&
            formatVersion != "0.1.0")
        {
            OGRE_EXCEPT(Ogre::Exception::ERR_INTERNAL_ERROR,
                "Unexpected format version was found while parsing the scene file."
                "\nformat version require: " + CURRENT_FORMAT_VERSION +
                "\nformat version in scene file: " + formatVersion,
                "SceneXMLHandler::startElement");
        }

        mScene->mName = attributes.getValueAs<String>("name", Ogre::StringUtil::BLANK);

        if (formatVersion == "0.1.0")
        {
            mPropertyNameCollectionMap.clear();

            NameMap& enviroment = mPropertyNameCollectionMap["Enviroment"];
            enviroment["fog mode"] = "fog.mode";
            enviroment["fog colour"] = "fog.colour";
            enviroment["fog exp density"] = "fog.exp density";
            enviroment["fog linear start"] = "fog.linear start";
            enviroment["fog linear end"] = "fog.linear end";
        }
    }
    else if (element == "Author")
    {
        assert(!mString);
        mString = &mScene->mAuthor;
    }
    else if (element == "Copyright")
    {
        assert(!mString);
        mString = &mScene->mCopyright;
    }
    else if (element == "Description")
    {
        assert(!mString);
        mString = &mScene->mDescription;
    }
    // CYS: B/C elements (05 §1). <Group name> is an editor container (2,041 in client_GL): its objects are
    //      ordinary scene objects that remember the group path.
    else if (element == "Group")
    {
        checkAttributes(element, attributes, kNameAttr);
        mGroups.push_back(attributes.exists("name") ? attributes.getValue("name") : String());
        updateGroupPath();
        CYSSceneStats::instance().count("Scene element Group");
    }
    else if (element == "SkySphere")
    {
        checkAttributes(element, attributes, kSkySphereAttrs);
        CYSSceneHeader& header = mScene->mCYSHeader;
        header.hasSkySphere = true;
        header.skySphereEnabled = !attributes.exists("enabled") ||
            CYSScene::parseBool(attributes.getValue("enabled").c_str(), true);
        header.skySphereFile = attributes.exists("filename") ? attributes.getValue("filename") : String();
        header.skySphereObjectName = attributes.exists("objectname") ? attributes.getValue("objectname") : String();
        CYSSceneStats::instance().count("Scene element SkySphere");
    }
    else if (element == "ModelMaterialScheme")
    {
        checkAttributes(element, attributes, kSchemeAttr);
        mScene->mCYSHeader.hasMaterialScheme = true;
        mScene->mCYSHeader.materialScheme = attributes.exists("scheme") ? attributes.getValue("scheme") : String();
        CYSSceneStats::instance().count("Scene element ModelMaterialScheme");
    }
    else if (element == "MovieData")
    {
        checkAttributes(element, attributes, kFilenameAttr);
        mScene->mCYSHeader.hasMovieData = true;
        mScene->mCYSHeader.movieData = attributes.exists("filename") ? attributes.getValue("filename") : String();
        CYSSceneStats::instance().count("Scene element MovieData");
    }
    // CYS: anything else is reported once and skipped instead of aborting the scene (was OGRE_EXCEPT).
    else
    {
        CYSSceneStats::instance().unknown("Scene element " + element, mFileName);
    }
}

void
SceneXMLHandler::endElement(const String& element)
{
    if (element == "Object")
    {
        assert(mObject);
        mObject.reset();
        mPropertyNameMap = NULL;
    }
    else if (element == "Attribute")
    {
        assert(mString);
        mString = NULL;
        mScene->setAttribute(mAttributeName, mAttributeValue);
    }
    else if (element == "Author")
    {
        assert(mString);
        mString = NULL;
    }
    else if (element == "Copyright")
    {
        assert(mString);
        mString = NULL;
    }
    else if (element == "Description")
    {
        assert(mString);
        mString = NULL;
    }
    else if (element == "Group")    // CYS
    {
        if (!mGroups.empty())
        {
            mGroups.pop_back();
            updateGroupPath();
        }
    }
}

//////////////////////////////////////////////////////////////////////////

SceneSerializer::SceneSerializer(void)
{
}

SceneSerializer::~SceneSerializer()
{
}

void
SceneSerializer::load(Scene* scene, XMLParser* parser, const String& filename, const String& groupName)
{
    assert(scene);
    assert(parser);

    if (filename.empty())
    {
        OGRE_EXCEPT(Ogre::Exception::ERR_INVALIDPARAMS,
            "Filename supplied for scene loading must be valid",
            "SceneSerializer::load");
    }

    //--------------------------------------------------------------------

    // setup handler object
    SceneXMLHandler handler(scene, filename);   // CYS: + file name

    // parse the scene XML file
    parser->parseXMLFile(handler, filename, groupName,
        SCENE_SCHEMA_NAME, GRAMMAR_RESOURCE_GROUP_NAME);
}

void
SceneSerializer::save(Scene* scene, XMLWriter* writer, const String& filename)
{
    assert(scene);
    assert(writer);

    if (filename.empty())
    {
        OGRE_EXCEPT(Ogre::Exception::ERR_INVALIDPARAMS,
            "Filename supplied for scene saveing must be valid",
            "SceneSerializer::save");
    }

    //--------------------------------------------------------------------

    std::auto_ptr<XMLNode> root(new XMLNode("Scene"));

    root->setAttribute("formatVersion", CURRENT_FORMAT_VERSION);
    root->setAttribute("name", scene->mName, Ogre::StringUtil::BLANK);

    if (!scene->mAuthor.empty())
    {
        XMLNode* e = root->createChild("Author");
        e->setTextContent(scene->mAuthor);
    }

    if (!scene->mCopyright.empty())
    {
        XMLNode* e = root->createChild("Copyright");
        e->setTextContent(scene->mCopyright);
    }

    if (!scene->mDescription.empty())
    {
        XMLNode* e = root->createChild("Description");
        e->setTextContent(scene->mDescription);
    }

    if (!scene->mTerrainFilename.empty())
    {
        XMLNode* e = root->createChild("Terrain");
        e->setAttribute("filename", scene->mTerrainFilename);
    }

    // CYS: B/C header elements, in the order of the B writer (ModelMaterialScheme, SkySphere, MovieData).
    const CYSSceneHeader& header = scene->mCYSHeader;
    if (header.hasMaterialScheme)
    {
        XMLNode* e = root->createChild("ModelMaterialScheme");
        e->setAttribute("scheme", header.materialScheme);
    }
    if (header.hasSkySphere)
    {
        XMLNode* e = root->createChild("SkySphere");
        e->setAttribute("enabled", String(header.skySphereEnabled ? "true" : "false"));
        e->setAttribute("filename", header.skySphereFile);
        e->setAttribute("objectname", header.skySphereObjectName);
    }
    if (header.hasMovieData)
    {
        XMLNode* e = root->createChild("MovieData");
        e->setAttribute("filename", header.movieData);
    }

    const Scene::Attributes& attributes = scene->getAttributes();
    for (Scene::Attributes::const_iterator itAttribute = attributes.begin(); itAttribute != attributes.end(); ++itAttribute)
    {
        const String& name = itAttribute->first;
        const String& value = itAttribute->second;
        XMLNode* e = root->createChild("Attribute");
        e->setAttribute("name", name);
        e->setTextContent(value);
    }

    const Scene::Objects& objects = scene->getObjects();
    XMLNode* groupNode = NULL;      // CYS: consecutive objects of one <Group>
    String currentGroup;
    for (Scene::Objects::const_iterator itObject = objects.begin(); itObject != objects.end(); ++itObject)
    {
        const ObjectPtr& object = *itObject;
        const String* group = object->getCYSExtraProperty(CYSScene::GROUP_PROPERTY);      // CYS
        const String groupName = group ? *group : String();
        if (groupName != currentGroup)
        {
            currentGroup = groupName;
            groupNode = NULL;
            if (!groupName.empty())
            {
                groupNode = root->createChild("Group");
                groupNode->setAttribute("name", groupName);
            }
        }
        XMLNode* n = (groupNode ? groupNode : root.get())->createChild("Object");
        n->setAttribute("type", object->getType());
        if (!scene->isAutoName(object->getName()))
        {
            n->setAttribute("name", object->getName());
        }

        const PropertyList& properties = object->getProperties();
        for (PropertyList::const_iterator itProperty = properties.begin(); itProperty != properties.end(); ++itProperty)
        {
            const String& name = itProperty->name;
            if (!(object->getPropertyFlags(name) & PF_DERIVED))
            {
                String value = object->getPropertyAsString(name);
                if (value != itProperty->defaultValue)
                {
                    XMLNode* e = n->createChild("Property");
                    e->setAttribute("name", name);
                    e->setAttribute("value", value);
                }
            }
        }

        // CYS: verbatim properties that the class dictionary does not define (unknown on load)
        if (const Object::CYSExtraProperties* extras = object->getCYSExtraProperties())
        {
            for (Object::CYSExtraProperties::const_iterator it = extras->begin(); it != extras->end(); ++it)
            {
                if (it->first == CYSScene::GROUP_PROPERTY)
                    continue;
                bool defined = false;
                for (PropertyList::const_iterator itProperty = properties.begin(); itProperty != properties.end(); ++itProperty)
                {
                    if (itProperty->name == it->first)
                    {
                        defined = true;
                        break;
                    }
                }
                if (defined)
                    continue;
                XMLNode* e = n->createChild("Property");
                e->setAttribute("name", it->first);
                e->setAttribute("value", it->second);
            }
        }
    }

    writer->writeXMLFile(root.get(), filename);
}

}
