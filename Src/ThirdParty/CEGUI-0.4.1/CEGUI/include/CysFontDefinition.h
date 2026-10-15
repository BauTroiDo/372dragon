// CYS: Select one language definition before constructing the font backend.
#ifndef CYS_FONT_DEFINITION_H
#define CYS_FONT_DEFINITION_H
#include "CEGUIXMLHandler.h"
#include "CEGUIXMLAttributes.h"
#include "CEGUIExceptions.h"
#include "CEGUIFontBase.h"
#include <vector>

namespace CEGUI
{
class CysFontDefinition : public XMLHandler
{
public:
    void elementStart(const String& element, const XMLAttributes& attributes) override
    {
        if (finished_ || (depth_ == 0 && element != "Font" && element != "Fonts") ||
            (depth_ != 0 && (!collection_ || depth_ != 1 || element != "Font")))
            throw FileIOException("Font definition: unexpected element '" + element + "'.");
        if (depth_ == 0) collection_ = element == "Fonts";
        if (element == "Font") entries_.push_back(attributes);
        ++depth_;
    }

    void elementEnd(const String& element) override
    {
        if (depth_ == 0 || element != (collection_ && depth_ == 1 ? "Fonts" : "Font"))
            throw FileIOException("Font definition: unexpected closing element.");
        if (--depth_ == 0) finished_ = true;
    }

    const XMLAttributes& select(uint codePage) const
    {
        if (!finished_ || depth_ != 0 || entries_.empty())
            throw FileIOException("Font definition: incomplete or empty document.");
        const XMLAttributes* selected = 0;
        const String name = entries_[0].getValueAsString("Name");
        for (const auto& entry : entries_)
        {
            if (entry.getValueAsString("Name").empty() || entry.getValueAsString("Filename").empty())
                throw FileIOException("Font definition: Name and Filename are required.");
            if (collection_ && entry.getValueAsString("Name") != name)
                throw FileIOException("Font definition: language variants must share one Name.");
            if (!collection_ || parseCodePage(entry.getValueAsString("CodePage")) == codePage)
            {
                if (selected) throw FileIOException("Font definition: duplicate matching CodePage.");
                selected = &entry;
            }
        }
        if (!selected) throw FileIOException("Font definition: no variant for the selected CodePage.");
        return *selected;
    }

    static FontType backend(const XMLAttributes& entry, FontType legacyType)
    {
        const String type = entry.getValueAsString("Type");
        if (type == "FreeType") return FreeType;
        if (type == "Bitmap") return Bitmap;
        // Legacy single-Font definitions used dynamic/static, with the backend in the scheme.
        if (type.empty() || type == "dynamic" || type == "static") return legacyType;
        throw FileIOException("Font definition: unsupported Type '" + type + "'.");
    }

private:
    static uint parseCodePage(const String& value)
    {
        uint result = 0;
        if (value.empty()) throw FileIOException("Font definition: CodePage required in Fonts collection.");
        for (String::size_type i = 0; i < value.length(); ++i)
        {
            if (value[i] < '0' || value[i] > '9' || result > 6553 ||
                (result == 6553 && value[i] > '5'))
                throw FileIOException("Font definition: invalid CodePage.");
            result = result * 10 + (value[i] - '0');
        }
        if (!result) throw FileIOException("Font definition: CodePage must be positive.");
        return result;
    }
    std::vector<XMLAttributes> entries_;
    unsigned depth_ = 0;
    bool collection_ = false;
    bool finished_ = false;
};
}
#endif
