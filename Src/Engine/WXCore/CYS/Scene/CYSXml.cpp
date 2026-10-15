// CY-Source (scene agent): see CYSXml.h.
#include "CYSXml.h"

#define TIXML_USE_STL
#include <tinyxml.h>

#include <OgreResourceGroupManager.h>
#include <OgreException.h>

#include <cstdio>
#include <cstring>

namespace WX
{
    namespace CYSScene
    {
        namespace
        {
            bool inList(const char* const* list, const char* name)
            {
                if (!list || !name)
                    return false;
                for (; *list; ++list)
                {
                    if (strcmp(*list, name) == 0)
                        return true;
                }
                return false;
            }
        }

        bool parseXmlText(TiXmlDocument& doc, const String& text, String* error)
        {
            const char* p = text.c_str();
            if ((unsigned char)p[0] == 0xEF && (unsigned char)p[1] == 0xBB && (unsigned char)p[2] == 0xBF)
                p += 3;

            doc.Clear();
            // Legacy mode = bytes are kept as they are (GBK values stay GBK); the markup itself is ASCII.
            doc.Parse(p, 0, TIXML_ENCODING_LEGACY);
            if (doc.Error())
            {
                if (error)
                {
                    char buf[64];
                    sprintf(buf, " (row %d, col %d)", doc.ErrorRow(), doc.ErrorCol());
                    *error = String(doc.ErrorDesc()) + buf;
                }
                return false;
            }
            if (!doc.RootElement())
            {
                if (error)
                    *error = "no root element";
                return false;
            }
            return true;
        }

        bool loadXmlResource(TiXmlDocument& doc, const String& name, const String& group, String* error)
        {
            String text;
            try
            {
                Ogre::DataStreamPtr stream = Ogre::ResourceGroupManager::getSingleton().openResource(name, group);
                if (stream.isNull())
                {
                    if (error)
                        *error = "cannot open resource";
                    return false;
                }
                text = stream->getAsString();
            }
            catch (const Ogre::Exception& e)
            {
                if (error)
                    *error = e.getDescription();
                return false;
            }
            return parseXmlText(doc, text, error);
        }

        void checkXmlKeys(const TiXmlElement* e, const char* const* attrs, const char* const* children,
                          const String& kind, const String& path, const String& file)
        {
            if (!e)
                return;
            for (const TiXmlAttribute* a = e->FirstAttribute(); a; a = a->Next())
            {
                if (!inList(attrs, a->Name()))
                    CYSSceneStats::instance().unknown(kind + " " + path + "@" + a->Name(), file);
            }
            for (const TiXmlElement* c = e->FirstChildElement(); c; c = c->NextSiblingElement())
            {
                if (!inList(children, c->Value()))
                    CYSSceneStats::instance().unknown(kind + " " + path + "/" + c->Value(), file);
            }
        }

        const char* attr(const TiXmlElement* e, const char* name)
        {
            return e ? e->Attribute(name) : NULL;
        }

        const char* childText(const TiXmlElement* e, const char* child)
        {
            if (!e)
                return NULL;
            const TiXmlElement* c = e->FirstChildElement(child);
            if (!c)
                return NULL;
            const char* t = c->GetText();
            return t ? t : "";
        }

        String attrString(const TiXmlElement* e, const char* name, const String& def)
        {
            const char* v = attr(e, name);
            return v ? String(v) : def;
        }

        String textString(const TiXmlElement* e, const char* child, const String& def)
        {
            const char* v = childText(e, child);
            return v ? String(v) : def;
        }
    }
}
