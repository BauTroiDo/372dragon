// CYS: independent fixtures for the UI decoder of B's packed format strings.
#include "CysPackedFormat.h"
#include "CysHostGlobals.h"
#include "LuaPlus.h"

#include <cstdio>
#include <fstream>
#include <map>
#include <memory>
#include <random>
#include <stdexcept>
#include <string>
#include <vector>

namespace
{
    unsigned passed = 0;
    unsigned failed = 0;
    typedef std::map<std::string, std::string> Dictionary;

    void Require(bool value, const char* message)
    { if (!value) throw std::runtime_error(message); }
    template<class F> void Test(const char* name, F run)
    {
        try { run(); ++passed; std::printf("PASS %s\n", name); }
        catch (const LuaPlus::LuaException& e) { ++failed; std::printf("FAIL %s: %s\n", name, e.GetMessage()); }
        catch (const std::exception& e) { ++failed; std::printf("FAIL %s: %s\n", name, e.what()); }
    }
    bool Resolve(void* context, const std::string& key, std::string& text)
    {
        const Dictionary& dictionary = *static_cast<const Dictionary*>(context);
        auto found = dictionary.find(key);
        if (found == dictionary.end()) return false;
        text = found->second;
        return true;
    }
    // Fixture builder follows the recovered input representation, not decoder code.
    // The first test additionally uses the fixed ten-byte vector directly.
    std::string Frame(const std::string& key, const std::vector<std::string>& args)
    {
        std::string payload;
        for (const auto& arg : args)
        {
            payload += '*'; payload += static_cast<char>(arg.size() & 255); payload += arg;
        }
        if (payload.size() == 56) payload += ' ';
        std::string result = "#{" + key + '*';
        result += static_cast<char>(args.size());
        result += static_cast<char>((payload.size()+3) & 255);
        return result + payload + '}';
    }
    CysPackedFormat::Result Expand(const std::string& input, Dictionary& dictionary, std::string& output)
    { return CysPackedFormat::Expand(input, Resolve, &dictionary, output); }
    void Expect(const std::string& input, Dictionary& dictionary, const std::string& expected, std::size_t expanded)
    {
        std::string output = "previous contents";
        auto result = Expand(input, dictionary, output);
        if (!result.ok()) throw std::runtime_error(CysPackedFormat::ErrorName(result.error));
        Require(output == expected, "decoded bytes differ");
        Require(result.expanded == expanded, "expanded count differs");
    }
    void Reject(const std::string& input, Dictionary& dictionary, CysPackedFormat::Error expected = CysPackedFormat::None)
    {
        std::string output = "previous contents";
        auto result = Expand(input, dictionary, output);
        Require(!result.ok(), "invalid packed input accepted");
        Require(output == input, "failure did not preserve complete input");
        Require(result.expanded == 0, "failure reported successful expansions");
        Require(result.offset <= input.size(), "error offset outside input");
        Require(CysPackedFormat::ErrorName(result.error) != nullptr, "missing error description");
        if (expected != CysPackedFormat::None) Require(result.error == expected, "wrong error category");
    }
    std::string ReadDictionaryCell(const char* path, const std::string& key)
    {
        std::ifstream input(path, std::ios::binary);
        Require(input.good(), "canonical dictionary is unavailable");
        std::string line;
        while (std::getline(input, line))
        {
            if (line.compare(0, key.size()+1, key+'\t') != 0) continue;
            std::string value = line.substr(key.size()+1);
            const auto tab = value.find('\t');
            if (tab != std::string::npos) value.resize(tab);
            if (!value.empty() && value.back() == '\r') value.pop_back();
            return value;
        }
        throw std::runtime_error("canonical dictionary key is unavailable");
    }
}

int main(int argc, char** argv)
{
    Test("golden_b_ten_byte_vector", [] {
        const unsigned char raw[] = {0x23,0x7b,0x4b,0x2a,0x01,0x06,0x2a,0x01,0x51,0x7d};
        Dictionary dictionary = {{"K", "%s0"}};
        Expect(std::string(reinterpret_cast<const char*>(raw), sizeof(raw)), dictionary, "Q", 1);
    });
    Test("non_packed_and_escaped_text_are_byte_identical", [] {
        Dictionary dictionary;
        std::string plain = "plain #{UNKNOWN} %s0 ## ##{literal} ";
        plain += std::string("\xe1\xbb\x87", 3);
        Expect(plain, dictionary, plain, 0);
        const std::string escaped = '#' + Frame("K", {"Q"});
        Expect(escaped, dictionary, escaped, 0);
    });
    Test("two_arguments_keep_order_and_numeric_text", [] {
        Dictionary dictionary = {{"K", "%s1,%s0"}};
        Expect(Frame("K", {"hero", "7"}), dictionary, "7,hero", 1);
    });
    Test("single_digit_placeholders_and_one_pass_substitution", [] {
        Dictionary dictionary = {{"K", "%s10-%s324"}, {"OPAQUE", "%s0/%s1"}};
        Expect(Frame("K", {"A", "B", "C", "D"}), dictionary, "B0-D24", 1);
        Expect(Frame("OPAQUE", {"%s1", "done"}), dictionary, "%s1/done", 1);
    });
    Test("lowercase_hex_placeholders_and_uppercase_literals", [] {
        Dictionary dictionary = {{"K", "%sa|%sb|%sc|%sd|%se|%sf|%sA|%sF|%sg"}};
        std::vector<std::string> arguments;
        for (unsigned i=0; i<15; ++i) arguments.push_back(std::to_string(i));
        // Format supports at most 15 arguments, so index 15 (%sf) stays literal.
        Expect(Frame("K",arguments),dictionary,"10|11|12|13|14|%sf|%sA|%sF|%sg",1);
    });
    Test("percent_before_placeholder_is_preserved", [] {
        Dictionary dictionary = {{"K", "%%s0|%%%s0|%%sa"}};
        Expect(Frame("K",{"Q"}),dictionary,"%Q|%%Q|%%sa",1);
    });
    Test("argument_metadata_above_127_does_not_damage_utf8", [] {
        Dictionary dictionary = {{"K", "%s0"}};
        std::string argument(190, 'A'); argument += std::string("\xe1\xbb\x87", 3);
        Expect(Frame("K", {argument}), dictionary, argument, 1);
    });
    Test("raw_gbk_dictionary_and_argument_bytes_are_preserved", [] {
        const std::string gbk("\xd6\xd0\xce\xc4",4);
        Dictionary dictionary = {{"K", "#G%s0"}, {"TEXT", gbk+" %s0"}};
        Expect(Frame("K", {gbk}),dictionary,"#G"+gbk,1);
        Expect(Frame("TEXT", {"7"}),dictionary,gbk+" 7",1);
    });
    Test("argument_braces_plain_expression_and_token_are_not_reparsed", [] {
        Dictionary dictionary = {{"K", "<%s0>"}};
        Expect(Frame("K", {"x}#{PLAIN}%s1"}),dictionary,"<x}#{PLAIN}%s1>",1);
    });
    Test("block_length_wraps_but_argument_lengths_define_boundaries", [] {
        Dictionary dictionary = {{"K", "%s0/%s1"}};
        const std::string first(130, 'A'), second(130, 'B');
        const std::string input = Frame("K", {first, second});
        Require(static_cast<unsigned char>(input[5]) == 11, "fixture block byte");
        Expect(input, dictionary, first+'/'+second, 1);
    });
    Test("padding_56_and_neighbors", [] {
        Dictionary dictionary = {{"K", "%s0"}};
        Expect(Frame("K", {std::string(53, 'Q')}), dictionary, std::string(53, 'Q'), 1);
        Expect(Frame("K", {std::string(54, 'Q')}), dictionary, std::string(54, 'Q'), 1);
        Expect(Frame("K", {std::string(55, 'Q')}), dictionary, std::string(55, 'Q'), 1);
    });
    Test("fifteen_arguments", [] {
        Dictionary dictionary = {{"K", "%s0/%s9"}};
        Expect(Frame("K", std::vector<std::string>(15, "Q")), dictionary, "Q/Q", 1);
    });
    Test("nested_packed_argument_expands_before_utf8_filter", [] {
        Dictionary dictionary = {{"OUTER", "before %s0 after"}, {"INNER", "value=%s0"}};
        Expect(Frame("OUTER", {Frame("INNER", {"7"})}), dictionary, "before value=7 after", 2);
    });
    Test("multiple_expressions_keep_surrounding_bytes", [] {
        Dictionary dictionary = {{"K", "%s0"}};
        Expect("["+Frame("K", {"A"})+"]-"+Frame("K", {"B"}), dictionary, "[A]-B", 2);
    });
    Test("unknown_dictionary_key_consumes_its_own_expression", [] {
        Dictionary dictionary;
        Expect(Frame("MISSING", {"Q"}),dictionary,"",1);
        Expect("before "+Frame("MISSING", {"Q"})+" after",dictionary,"before  after",1);
    });
    Test("missing_placeholder_arguments_stay_literal", [] {
        Dictionary dictionary = {{"K", "%s1|%s0|%sf|%s9"}};
        Expect(Frame("K",{"Q"}),dictionary,"%s1|Q|%sf|%s9",1);
    });
    Test("mixed_known_unknown_expressions_keep_remaining_message", [] {
        Dictionary dictionary = {{"K", "%s0"}};
        Expect("["+Frame("K",{"A"})+"] / "+Frame("UNKNOWN",{"ignored"})+" / "+Frame("K",{"B"}),
               dictionary,"[A] /  / B",3);
    });
    Test("unknown_nested_expression_preserves_outer_text", [] {
        Dictionary dictionary = {{"OUTER", "before "+Frame("UNKNOWN",{"Q"})+" after"}};
        Expect("prefix "+Frame("OUTER",{"Q"}),dictionary,"prefix before  after",2);
    });
    Test("missing_resolver_service_is_explicit_and_transactional", [] {
        const std::string input = "prefix "+Frame("K",{"Q"});
        std::string output;
        auto result = CysPackedFormat::Expand(input,nullptr,nullptr,output);
        Require(result.error == CysPackedFormat::MissingKey && result.offset == 7, "missing resolver category/offset");
        Require(std::string(CysPackedFormat::ErrorName(result.error)) == "missing-resolver", "missing resolver description");
        Require(output == input && result.expanded == 0, "missing resolver is not transactional");
    });
    Test("truncated_header_argument_and_terminator_are_rejected", [] {
        Dictionary dictionary = {{"K", "%s0"}};
        const std::string valid = Frame("K", {"Q"});
        Reject(valid.substr(0,4), dictionary);
        Reject(valid.substr(0,5), dictionary);
        Reject(valid.substr(0,8), dictionary);
        Reject(valid.substr(0,valid.size()-1), dictionary);
    });
    Test("mismatched_block_length_is_rejected", [] {
        Dictionary dictionary = {{"K", "%s0"}};
        std::string input = Frame("K", {"Q"}); input[5] = 7;
        Reject(input, dictionary);
    });
    Test("missing_padding_byte_is_rejected", [] {
        Dictionary dictionary = {{"K", "%s0"}};
        std::string input = Frame("K", {std::string(54,'Q')});
        input.erase(input.size()-2,1);
        Reject(input, dictionary);
    });
    Test("invalid_argument_marker_is_rejected", [] {
        Dictionary dictionary = {{"K", "%s0"}};
        std::string input = Frame("K", {"Q"}); input[6] = '!';
        Reject(input, dictionary);
    });
    Test("invalid_argument_counts_are_rejected", [] {
        Dictionary dictionary = {{"K", "%s0"}};
        for (unsigned count : {0u,16u,31u})
        {
            std::string input = Frame("K", {"Q"}); input[4] = static_cast<char>(count);
            Reject(input, dictionary, CysPackedFormat::InvalidCount);
        }
    });
    Test("c_string_truncation_from_empty_host_argument_is_rejected", [] {
        Dictionary dictionary = {{"K", "%s0"}};
        const unsigned char raw[] = {0x23,0x7b,0x4b,0x2a,0x01,0x05,0x2a};
        Reject(std::string(reinterpret_cast<const char*>(raw), sizeof(raw)), dictionary);
    });
    Test("later_failure_preserves_prior_valid_expression", [] {
        Dictionary dictionary = {{"K", "%s0"}};
        std::string malformed = Frame("K",{"invalid"}); malformed.pop_back();
        Reject(Frame("K", {"valid"})+" / "+malformed,dictionary,CysPackedFormat::Truncated);
    });
    Test("nesting_depth_16_is_accepted_and_17_rejected", [] {
        Dictionary dictionary;
        for (unsigned i=0; i<16; ++i)
            dictionary["K"+std::to_string(i)] = i == 15 ? "%s0" : Frame("K"+std::to_string(i+1), {"Q"});
        Expect(Frame("K0", {"Q"}), dictionary, "Q", 16);
        dictionary["K15"] = Frame("K16", {"Q"}); dictionary["K16"] = "%s0";
        Reject(Frame("K0", {"Q"}), dictionary);
    });
    Test("recursive_cycle_stops_with_error", [] {
        Dictionary dictionary = {{"K", Frame("K", {"Q"})}};
        Reject(Frame("K", {"Q"}), dictionary);
    });
    Test("nested_failure_offset_points_to_outer_expression", [] {
        std::string malformed = Frame("K",{"Q"}); malformed.pop_back();
        Dictionary dictionary = {{"OUTER",malformed},{"K","%s0"}};
        const std::string input = "prefix "+Frame("OUTER", {"Q"});
        std::string output;
        auto result = Expand(input,dictionary,output);
        Require(result.error == CysPackedFormat::Truncated && result.offset == 7, "nested error location/category");
        Require(result.expanded == 0 && output == input, "nested error is not transactional");
    });
    Test("expansion_count_4096_boundary", [] {
        Dictionary dictionary = {{"K", ""}};
        const std::string single = Frame("K", {"Q"});
        std::string input;
        for (unsigned i=0; i<4096; ++i) input += single;
        Expect(input,dictionary,"",4096);
        Reject(input+single,dictionary,CysPackedFormat::ExpansionLimit);
    });
    Test("one_mib_output_boundary", [] {
        Dictionary dictionary = {{"K", std::string(1024*1024, 'A')}};
        Expect(Frame("K", {"Q"}), dictionary, dictionary["K"], 1);
        dictionary["K"] += 'A';
        Reject(Frame("K", {"Q"}), dictionary);
    });
    Test("canonical_dictionary_real_key_keeps_utf8_colors", [&] {
        Require(argc == 2, "pass canonical StrDictionary.txt path");
        const std::string key = "ZNDB_230215_157";
        const std::string value = ReadDictionaryCell(argv[1], key);
        const auto placeholder = value.find("%s0");
        Require(placeholder != std::string::npos && value.find("%s0", placeholder+3) == std::string::npos, "real fixture must contain one placeholder");
        const std::string expected = value.substr(0,placeholder)+"42"+value.substr(placeholder+3);
        Dictionary dictionary = {{key, value}};
        Expect(Frame(key, {"42"}), dictionary, expected, 1);
        std::printf("CANONICAL key=%s template_bytes=%u output_bytes=%u\n", key.c_str(), static_cast<unsigned>(value.size()), static_cast<unsigned>(expected.size()));
    });
    Test("real_lua_host_encoder_to_decoder_with_canonical_dictionary", [&] {
        Require(argc == 2, "pass canonical StrDictionary.txt path");
        const std::string key = "ZNDB_230215_157";
        const std::string value = ReadDictionaryCell(argv[1],key);
        const auto placeholder = value.find("%s0");
        Require(placeholder != std::string::npos && value.find("%s0",placeholder+3) == std::string::npos, "integration fixture placeholder");
        Require(value.size() == 45, "integration fixture template must be 45 bytes");
        const std::string expected = value.substr(0,placeholder)+"42"+value.substr(placeholder+3);
        Require(expected.size() == 44, "integration expected text must be 44 bytes");
        typedef std::unique_ptr<LuaPlus::LuaState, void(*)(LuaPlus::LuaState*)> LuaOwner;
        LuaOwner state(LuaPlus::LuaState::Create(true),LuaPlus::LuaState::Destroy);
        Require(state.get() != nullptr, "integration LuaState allocation");
        LuaPlus::LuaObject globals = state->GetGlobals();
        // CYS-TESTRED 19/09: this used to read "== 3", the number of globals CysHostGlobals published when the case
        // was written. Register() now publishes seven (CysHostGlobals.cpp: ScriptGlobal_Format, PushEvent,
        // CloseWindow, SetSoftKeyAim, OpenWindow, ToggleWindow, GetDictionaryString), so the literal rotted and was
        // the only red case in this suite - no product defect. A count of globals is not what this case is about
        // anyway; what it needs is "the REAL host published the encoder". Assert that, plus the two invariants the
        // magic number was standing in for: registration fills the fresh state (so a second call adds nothing and
        // replaces nothing) and the encoder under test is a live host function, not a LuaApiGen stub.
        const unsigned registered = CysHostGlobals::Register(globals,CysHostGlobals::Services());
        Require(registered >= 1, "integration real host registration");
        Require(CysHostGlobals::Register(globals,CysHostGlobals::Services()) == 0, "integration re-registration replaced a host global");
        Require(globals.GetByName("ScriptGlobal_Format").IsFunction(), "integration encoder is not a host function");
        Require(state->DoString("packed=ScriptGlobal_Format('#{ZNDB_230215_157}',42)") == 0, "integration Lua call failed");
        LuaPlus::LuaObject packed = globals.GetByName("packed");
        Require(packed.IsString(), "integration host did not return a string");
        const std::string encoded = packed.GetString();
        Dictionary dictionary = {{key,value}};
        Expect(encoded,dictionary,expected,1);
        std::printf("INTEGRATION real_lua=true real_host=true real_decoder=true key=%s packed_bytes=%u template_bytes=45 output_bytes=44\n",key.c_str(),static_cast<unsigned>(encoded.size()));
    });
    Test("deterministic_malformed_byte_fuzz_10000_cases", [] {
        const unsigned seed = 0x43595331;
        std::mt19937 random(seed);
        Dictionary dictionary = {{"K", "%s0/%s1"}};
        const std::string valid = Frame("K", {"A", "B"});
        unsigned accepted = 0, rejected = 0;
        for (unsigned iteration=0; iteration<10000; ++iteration)
        {
            std::string input = iteration%3 == 0 ? "prefix "+valid+" suffix" : valid;
            const unsigned edits = random()%9;
            for (unsigned edit=0; edit<edits; ++edit)
            {
                const unsigned operation = random()%4;
                const std::size_t position = random()%(input.size()+1);
                const char value = static_cast<char>(random()&255);
                if (operation == 0 && position<input.size()) input[position] = value;
                else if (operation == 1) input.insert(position,1,value);
                else if (operation == 2 && position<input.size()) input.erase(position,1);
                else if (operation == 3) input.insert(position,valid);
            }
            std::string output;
            auto result = Expand(input,dictionary,output);
            if (result.ok())
            {
                ++accepted;
                Require(result.expanded <= CysPackedFormat::MaxExpansions, "fuzz expansion bound");
                if (result.expanded == 0) Require(output == input, "fuzz changed non-packed bytes");
                else Require(output.size() <= CysPackedFormat::MaxOutputBytes, "fuzz output bound");
            }
            else
            {
                ++rejected;
                Require(output == input && result.expanded == 0, "fuzz error is not transactional");
                Require(result.offset <= input.size(), "fuzz error offset outside input");
            }
        }
        Require(accepted != 0 && rejected != 0, "fuzz did not exercise success and failure");
        std::printf("FUZZ seed=%u cases=10000 accepted=%u rejected=%u exceptions=0\n",seed,accepted,rejected);
    });
    std::printf("RESULT passed=%u failed=%u total=%u\n", passed, failed, passed+failed);
    return failed == 0 ? 0 : 1;
}
