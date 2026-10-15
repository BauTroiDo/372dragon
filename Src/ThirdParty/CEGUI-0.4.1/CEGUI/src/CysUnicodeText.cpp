#include "CysUnicodeText.h"
#include "CEGUIExceptions.h"
#include <windows.h>
#include <limits>
#include <string>

namespace CEGUI
{
String CysComposeDisplayText(const String& text)
{
    bool combining = false;
    for (String::size_type i = 0; i < text.length(); ++i)
        if (text[i] >= 0x0300 && text[i] <= 0x036F) { combining = true; break; }
    if (!combining) return text; // ASCII, Chinese and precomposed Vietnamese keep their bytes/codepoints.

    String result;
    std::wstring segment;
    auto flush = [&]() {
        if (segment.empty()) return;
        if (segment.size() > static_cast<size_t>((std::numeric_limits<int>::max)()))
            throw InvalidRequestException("Display text is too long for Unicode normalization.");
        const int count = static_cast<int>(segment.size());
        const int capacity = NormalizeString(NormalizationC, segment.data(), count, 0, 0);
        if (capacity <= 0) throw InvalidRequestException("Display text Unicode normalization failed.");
        std::wstring normalized(static_cast<size_t>(capacity), L'\0');
        const int written = NormalizeString(NormalizationC, segment.data(), count, &normalized[0], capacity);
        if (written <= 0) throw InvalidRequestException("Display text Unicode normalization failed.");
        for (int i = 0; i < written; ++i)
        {
            utf32 code = normalized[i];
            if (code >= 0xD800 && code <= 0xDBFF && i + 1 < written)
                code = 0x10000 + ((code - 0xD800) << 10) + (normalized[++i] - 0xDC00);
            result += code;
        }
        segment.clear();
    };
    for (String::size_type i = 0; i < text.length(); ++i)
    {
        const utf32 code = text[i];
        if (code > 0x10FFFF || (code >= 0xD800 && code <= 0xDFFF))
        {
            // TLBB puts colour/image/control metadata in non-Unicode 32-bit values.
            flush(); result += code;
        }
        else if (code < 0x10000) segment += static_cast<wchar_t>(code);
        else
        {
            segment += static_cast<wchar_t>(0xD800 + ((code - 0x10000) >> 10));
            segment += static_cast<wchar_t>(0xDC00 + ((code - 0x10000) & 0x3FF));
        }
    }
    flush();
    return result;
}
}
