#ifndef __CYS_XML_H__
#define __CYS_XML_H__

// CY-Source (scene agent): TinyXML helpers for the B/C scene side files (.EnScene, .skysphere, .dynbone).
// Those files are XML without an encoding declaration (147 of 197 .EnScene hold GBK texture names), so they are
// parsed in TinyXML "legacy" (byte) mode: element/attribute names are ASCII and every value keeps its original
// bytes, i.e. GBK resource names stay GBK as the resource system expects (Docs/08 §1.2/1.4).

#include "CYSSceneCommon.h"

class TiXmlDocument;
class TiXmlElement;

namespace WX
{
    namespace CYSScene
    {
        /// Reads an OGRE resource (group `group`) and parses it; false + `error` when missing or malformed.
        bool loadXmlResource(TiXmlDocument& doc, const String& name, const String& group, String* error);
        /// Parses XML text (a leading UTF-8 BOM is skipped).
        bool parseXmlText(TiXmlDocument& doc, const String& text, String* error);

        /// Records every attribute of `e` not listed in `attrs` and every child element not listed in
        /// `children` (NULL-terminated lists, either may be NULL) as an unknown key
        /// "<kind> <path>@<attr>" / "<kind> <path>/<child>" in CYSSceneStats.
        void checkXmlKeys(const TiXmlElement* e, const char* const* attrs, const char* const* children,
                          const String& kind, const String& path, const String& file);

        /// Attribute value or NULL.
        const char* attr(const TiXmlElement* e, const char* name);
        /// Text of the first child element `child` (e.g. <hight>102</hight>) or NULL.
        const char* childText(const TiXmlElement* e, const char* child);

        inline Real attrReal(const TiXmlElement* e, const char* name, Real def) { return parseReal(attr(e, name), def); }
        inline int attrInt(const TiXmlElement* e, const char* name, int def) { return parseInt(attr(e, name), def); }
        inline bool attrBool(const TiXmlElement* e, const char* name, bool def) { return parseBool(attr(e, name), def); }
        String attrString(const TiXmlElement* e, const char* name, const String& def = String());

        inline Real textReal(const TiXmlElement* e, const char* child, Real def) { return parseReal(childText(e, child), def); }
        inline int textInt(const TiXmlElement* e, const char* child, int def) { return parseInt(childText(e, child), def); }
        inline bool textBool(const TiXmlElement* e, const char* child, bool def) { return parseBool(childText(e, child), def); }
        String textString(const TiXmlElement* e, const char* child, const String& def = String());
    }
}

#endif // __CYS_XML_H__
