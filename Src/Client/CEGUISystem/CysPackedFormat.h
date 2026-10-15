// CYS: bounded reader for the packed Format envelope emitted by Game.exe+0x619670.
// The byte layout is recovered from B; placeholder/limit policy is documented in
// Docs/specs/lua/host-api_vi.md. No UI/encoding dependency.
#pragma once

#include <cstddef>
#include <string>
#include <vector>

namespace CysPackedFormat
{
    // CYS defensive limits, not recovered B constants. Plain text is not capped.
    static const std::size_t MaxDepth = 16;
    static const std::size_t MaxOutputBytes = 1024 * 1024;
    static const std::size_t MaxExpansions = 4096;

    typedef bool (*Resolver)(void* context, const std::string& key, std::string& text);

    enum Error
    {
        None,
        Truncated,
        InvalidCount,
        InvalidArgumentMarker,
        InvalidBlockLength,
        InvalidPadding,
        InvalidEnd,
        MissingKey, // Resolver service is absent; an unknown key from a present resolver is not an error.
        DepthLimit,
        OutputLimit,
        ExpansionLimit
    };

    inline const char* ErrorName(Error error)
    {
        switch (error)
        {
        case None: return "none";
        case Truncated: return "truncated";
        case InvalidCount: return "invalid-count";
        case InvalidArgumentMarker: return "invalid-argument-marker";
        case InvalidBlockLength: return "invalid-block-length";
        case InvalidPadding: return "invalid-padding";
        case InvalidEnd: return "invalid-end";
        case MissingKey: return "missing-resolver";
        case DepthLimit: return "depth-limit";
        case OutputLimit: return "output-limit";
        case ExpansionLimit: return "expansion-limit";
        }
        return "unknown";
    }

    struct Result
    {
        Error error;
        // Offset in the original input; nested errors identify their outer envelope.
        std::size_t offset;
        std::size_t expanded;
        Result() : error(None), offset(0), expanded(0) {}
        bool ok() const { return error == None; }
    };

    namespace Detail
    {
        struct State
        {
            Resolver resolve;
            void* context;
            Result result;
            std::size_t visited;
            State(Resolver callback, void* data) : resolve(callback), context(data), visited(0) {}
            bool Fail(Error error, std::size_t offset)
            {
                result.error = error;
                result.offset = offset;
                return false;
            }
        };

        inline unsigned Byte(char value) { return static_cast<unsigned char>(value); }

        inline bool Append(std::string& output, const std::string& text, std::size_t start,
            std::size_t length, State& state, std::size_t offset)
        {
            if (length > MaxOutputBytes || output.size() > MaxOutputBytes - length)
                return state.Fail(OutputLimit, offset);
            output.append(text, start, length);
            return true;
        }

        inline bool ReadArguments(const std::string& input, std::size_t marker,
            std::vector<std::string>& arguments, std::size_t& end, State& state, std::size_t offset)
        {
            if (input.size() - marker < 3) return state.Fail(Truncated, offset);
            const unsigned count = Byte(input[marker + 1]);
            if (count == 0 || count > 15) return state.Fail(InvalidCount, offset);
            const unsigned blockLength = Byte(input[marker + 2]);
            std::size_t cursor = marker + 3;
            std::size_t payloadLength = 0;
            for (unsigned index = 0; index < count; ++index)
            {
                if (input.size() - cursor < 2) return state.Fail(Truncated, offset);
                if (input[cursor] != '*') return state.Fail(InvalidArgumentMarker, offset);
                const unsigned length = Byte(input[cursor + 1]);
                cursor += 2;
                if (length > input.size() - cursor) return state.Fail(Truncated, offset);
                arguments.push_back(input.substr(cursor, length));
                cursor += length;
                payloadLength += 2 + length;
            }
            // B inserts precisely one space when sum(2 + argument length) is 56.
            const std::size_t padding = payloadLength == 56 ? 1 : 0;
            if (padding != 0)
            {
                if (cursor == input.size()) return state.Fail(Truncated, offset);
                if (input[cursor] != ' ') return state.Fail(InvalidPadding, offset);
                ++cursor;
            }
            // Only the total wraps. Individual lengths >255 lose information and
            // cannot be reconstructed safely from this envelope.
            if (blockLength != ((payloadLength + 3 + padding) & 255))
                return state.Fail(InvalidBlockLength, offset);
            if (cursor == input.size()) return state.Fail(Truncated, offset);
            if (input[cursor] != '}') return state.Fail(InvalidEnd, offset);
            end = cursor + 1;
            return true;
        }

        inline bool Substitute(const std::string& text, const std::vector<std::string>& arguments,
            std::string& output, State& state, std::size_t offset)
        {
            std::size_t begin = 0;
            for (std::size_t cursor = 0; cursor < text.size(); ++cursor)
            {
                if (text.size() - cursor < 3 || text[cursor] != '%' || text[cursor + 1] != 's') continue;
                const char digit = text[cursor + 2];
                unsigned index;
                if (digit >= '0' && digit <= '9') index = digit - '0';
                else if (digit >= 'a' && digit <= 'f') index = digit - 'a' + 10;
                else continue;
                // CYS: the historical reader preserves an unavailable argument token.
                if (index >= arguments.size()) { cursor += 2; continue; }
                if (!Append(output, text, begin, cursor - begin, state, offset) ||
                    !Append(output, arguments[index], 0, arguments[index].size(), state, offset)) return false;
                cursor += 2;
                begin = cursor + 1;
            }
            // Inserted arguments are never scanned for %sN by this substitution.
            return Append(output, text, begin, text.size() - begin, state, offset);
        }

        inline bool ExpandText(const std::string& input, std::string& output, std::size_t depth,
            std::size_t outerOffset, State& state)
        {
            std::size_t begin = 0;
            bool changed = false;
            for (std::size_t cursor = 0; cursor < input.size(); )
            {
                if (input[cursor] != '#' || input.size() - cursor < 2) { ++cursor; continue; }
                if (input[cursor + 1] == '#') { cursor += 2; continue; }
                if (input[cursor + 1] != '{') { ++cursor; continue; }
                std::size_t marker = cursor + 2;
                while (marker < input.size() && input[marker] != '*' && input[marker] != '}' &&
                    input[marker] != '#' && input[marker] != '{') ++marker;
                if (marker == input.size() || input[marker] != '*') { cursor += 2; continue; }
                // A printable character after '*' remains an ordinary dictionary key.
                // B emits count 1..15; C0 values and an unfinished header are candidates.
                if (input.size() - marker >= 2 && Byte(input[marker + 1]) >= 32)
                { cursor += 2; continue; }

                const std::size_t offset = outerOffset == std::string::npos ? cursor : outerOffset;
                if (depth >= MaxDepth) return state.Fail(DepthLimit, offset);
                if (++state.visited > MaxExpansions) return state.Fail(ExpansionLimit, offset);
                std::vector<std::string> arguments;
                std::size_t end = 0;
                if (!ReadArguments(input, marker, arguments, end, state, offset)) return false;
                std::string text;
                if (!state.resolve) return state.Fail(MissingKey, offset);
                // CYS: an unknown dictionary key consumes only its own envelope.
                if (!state.resolve(state.context, input.substr(cursor + 2, marker - cursor - 2), text))
                    text.clear();
                std::string substituted;
                if (!Substitute(text, arguments, substituted, state, offset)) return false;
                // Resolve nested packed envelopes before the UI strips C0/invalid UTF-8
                // metadata. Ordinary #{KEY}, colors and literal %sN remain for the UI.
                std::string nested;
                if (!ExpandText(substituted, nested, depth + 1, offset, state)) return false;
                if (!Append(output, input, begin, cursor - begin, state, offset) ||
                    !Append(output, nested, 0, nested.size(), state, offset)) return false;
                cursor = end;
                begin = end;
                changed = true;
            }
            if (!changed) { output = input; return true; } // Byte identity, including large plain strings.
            return Append(output, input, begin, input.size() - begin, state,
                outerOffset == std::string::npos ? begin : outerOffset);
        }
    }

    // Failure is transactional: preserve the complete original input and report no
    // successful expansion. Do not log text/arguments; callers can log ErrorName/offset.
    inline Result Expand(const std::string& input, Resolver resolve, void* context, std::string& output)
    {
        Detail::State state(resolve, context);
        std::string expanded;
        if (Detail::ExpandText(input, expanded, 0, std::string::npos, state))
        {
            output.swap(expanded);
            state.result.expanded = state.visited;
        }
        else output = input;
        return state.result;
    }
}
