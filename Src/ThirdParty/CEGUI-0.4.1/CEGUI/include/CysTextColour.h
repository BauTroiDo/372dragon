#ifndef CYS_TEXT_COLOUR_H
#define CYS_TEXT_COLOUR_H

#include <cstdlib>
#include <string>

namespace CEGUI
{
// B UI_CEGUI RuntimeNew: current/previous begin white; #l restores without swapping.
class CysTextColourParser
{
public:
    CysTextColourParser() : current_(0xFBFFFFFFu), previous_(0xFBFFFFFFu) {}

    static size_t tokenLength(char key)
    {
        switch (key)
        {
        case 'R': case 'G': case 'B': case 'K': case 'Y': case 'W': case 'l': return 2;
        case 'c': case 'g': case 'e': return 8;
        default: return 0;
        }
    }

    // keyPosition is the character after '#'. The legacy %6X accepts a hex prefix.
    bool parse(const std::string& source, size_t keyPosition, unsigned& word, size_t& end)
    {
        if (keyPosition >= source.size()) return false;
        const char key = source[keyPosition];
        const size_t length = tokenLength(key);
        if (!length) return false;
        switch (key)
        {
        case 'R': word = 0xFBFF0000u; break;
        case 'G': word = 0xFB00FF00u; break;
        case 'B': word = 0xFB0000FFu; break;
        case 'K': word = 0xFB000000u; break;
        case 'Y': word = 0xFBFFFF00u; break;
        case 'W': word = 0xFBFFFFFFu; break;
        case 'l': word = current_ = previous_; end = keyPosition + 1; return true;
        default:
            word = static_cast<unsigned>(std::strtoul(source.substr(keyPosition + 1, 6).c_str(), 0, 16));
            word = (word & 0xFFFFFFu) | (key == 'g' ? 0xD0000000u : key == 'e' ? 0xFC000000u : 0xFB000000u);
            break;
        }
        end = keyPosition + length - 1;
        if (key != 'e') { previous_ = current_; current_ = word; }
        return true;
    }

private:
    unsigned current_, previous_;
};

// B CEGUIBase D0: two RGB444 colours, high three digits top, low three bottom.
inline unsigned CysExpandRgb444(unsigned rgb)
{
    return ((rgb & 0xF00u) * 0x1100u) | ((rgb & 0xF0u) * 0x110u) | ((rgb & 0xFu) * 0x11u);
}
}
#endif
