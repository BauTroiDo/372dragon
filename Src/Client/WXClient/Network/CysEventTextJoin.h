// CYS-QUEST: join event-list texts that the private server split at the CY 255-byte limit.
// CY Game.exe reads one event-list text of 1..255 bytes (GCScriptCommand reader 0x1408471d0, buffer 256); Vietnamese
// UTF-8 is longer than the Chinese GBK originals, so script_base:EndEvent sends a long text as several text items, each
// but the last ending with the continuation byte 0x1F. Header-only (Tests\luaapi\event_text_join_tests.cpp).
#pragma once

#include <string>
#include <utility>
#include <vector>

namespace CysEventTextJoin
{
    const char kContinuation = '\x1F';

    struct Joined
    {
        size_t first;       // index of the first source event
        int flag;           // 0 section, 1 option, 2 text
        std::string text;   // joined text without continuation bytes
    };

    // events: (flag, text). Text items (flag != 1) ending with 0x1F continue into the next item of the same flag.
    inline std::vector<Joined> Join(const std::vector<std::pair<int, std::string> >& events)
    {
        std::vector<Joined> out;
        bool open = false;
        for (size_t i = 0; i < events.size(); ++i)
        {
            const int flag = events[i].first;
            std::string text = events[i].second;
            const bool text_item = flag != 1;
            const bool continues = text_item && !text.empty() && text[text.size() - 1] == kContinuation;
            if (continues) text.erase(text.size() - 1);
            if (open && text_item && out.back().flag == flag) out.back().text += text;
            else { Joined j = { i, flag, text }; out.push_back(j); }
            open = continues;
        }
        return out;
    }
}
