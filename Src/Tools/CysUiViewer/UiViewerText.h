// CysUiViewer - UI texts: StrDictionary.txt, TLBB text markup, Vietnamese sample text, InterfaceEx.txt.
// CYS: new tool (2026-09-12). Keep this file ASCII.
#pragma once

#include <CEGUIBase.h>
#include <CEGUIString.h>

#include <map>
#include <string>
#include <unordered_map>

namespace cysui
{
    // TLBB UI text markup, as CUIStringSystem::ParserString_RuntimeNew (Client/CEGUISystem/UIString.cpp:399) but on
    // UTF-8 input (the game goes UTF-8 -> MBCS -> UTF-32, which is where the code page traps of Docs/08 1.8 live):
    //   #{KEY} dictionary lookup (recursive; KEY*a*b substitutes $1$ $2$ ...), #R #G #B #K #Y #W, #cRRGGBB, #eRRGGBB,
    //   #b blink, #r newline, ## '#', #aB / #aE hyperlink marks, #-NN animation, #N / #NN emote, #u #n ignored.
    // Control characters are the UTF-32 values the game hands to CEGUI (FontBase interprets them):
    //   0xFB000000|rgb colour, 0xFC000000|rgb edge colour, 0xFD000000 / 0xFE000000 link begin / end,
    //   0xE0000000 blink on, 0xE1000000 blink end, 0xE3000000|n animation, 0xFA000000|n emote.
    class TextResolver
    {
    public:
        bool loadDictionary(const std::string& path, std::string& error);
        size_t dictionarySize(void) const { return m_dict.size(); }
        CEGUI::String resolve(const std::string& utf8, int depth = 0);
        const std::map<std::string, int>& missingKeys(void) const { return m_missing; }
        size_t resolvedKeys(void) const { return m_resolved; }
        // 65001: plain text passes through (UI_CEGUI with System_CodePage=65001). Other values approximate the 0.85
        // path: every plain run round-trips UTF-8 -> code page -> UTF-8 (Vietnamese becomes '?' under 936).
        void setCodePage(int cp) { m_codePage = cp; }
        // Markup codes the 0.85 parser does not know ("#gRRGGBB" is drawn as #c by the viewer; other codes lose only
        // the '#', as in 0.85), counted per occurrence.
        const std::map<std::string, int>& unknownMarkup(void) const { return m_markup; }

    private:
        void resolveKey(const std::string& id, CEGUI::String& out, int depth);
        void appendRun(CEGUI::String& out, const std::string& run) const;

        std::unordered_map<std::string, std::string> m_dict;
        std::map<std::string, int> m_missing;
        std::map<std::string, int> m_markup;
        size_t m_resolved = 0;
        int m_codePage = 65001;
    };

    // Default: "Thien Long Bat Bo - Tieng Viet co dau: ..." with the full diacritics set of the task.
    CEGUI::String sampleText(const std::string& customUtf8);

    // InterfaceEx.txt (byte based, LF split only): lower-case layout path with '/' -> window name.
    bool loadInterfaceTable(const std::string& path, std::map<std::string, std::string>& layoutToWindow);
}
