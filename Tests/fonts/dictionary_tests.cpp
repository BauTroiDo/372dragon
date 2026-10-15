#include "CysUiDictionary.h"
#include <fstream>
#include <iostream>
#include <iterator>
#include <functional>

static int passed = 0, failed = 0;
static void Check(bool value) { if (!value) throw std::runtime_error("check failed"); }
static void Test(const char* name, const std::function<void()>& body)
{
    try { body(); ++passed; std::cout << "PASS " << name << '\n'; }
    catch (const std::exception& e) { ++failed; std::cout << "FAIL " << name << ": " << e.what() << '\n'; }
}
static std::string Read(const char* path)
{
    std::ifstream file(path, std::ios::binary);
    if (!file) throw std::runtime_error("fixture not found");
    return std::string(std::istreambuf_iterator<char>(file), {});
}
static bool Reject(const std::string& data, UINT codePage = CP_UTF8)
{
    try { CysUiDictionary::Parse(data, codePage); return false; }
    catch (const std::runtime_error&) { return true; }
}
int main(int argc, char** argv)
{
    const std::string modern = "STRING\tSTRING\r\nSTRING\tSTRING\r\n";
    const std::string legacy = "INT\tSTRING\tSTRING\nINT\tSTRING\tSTRING\n";
    Test("UTF8 Vietnamese and Chinese", [&] { auto t = CysUiDictionary::Parse(modern + u8"K\tTiếng Việt 中文\n", CP_UTF8); Check(t.entries.at("K") == u8"Tiếng Việt 中文"); });
    Test("GBK Chinese to UTF8", [&] { auto t = CysUiDictionary::Parse(legacy + "1\tK\t\xd7\xe9\xb6\xd3\n", CP_UTF8); Check(t.entries.at("K") == u8"组队"); });
    Test("legacy bytes unchanged at 936", [&] { auto t = CysUiDictionary::Parse(legacy + "1\tK\t\xd7\xe9\xb6\xd3", 936); Check(t.entries.at("K") == "\xd7\xe9\xb6\xd3"); });
    Test("UTF8 key unchanged", [&] { auto t = CysUiDictionary::Parse(modern + u8"关键字\t中文\n", CP_UTF8); Check(t.entries.at(u8"关键字") == u8"中文"); });
    Test("GBK key unchanged", [&] { auto t = CysUiDictionary::Parse(legacy + "1\t\xd7\xe9\xb6\xd3\tV\n", CP_UTF8); Check(t.entries.at("\xd7\xe9\xb6\xd3") == "V"); });
    Test("BOM CRLF comments trailing empty", [&] { auto t = CysUiDictionary::Parse("\xef\xbb\xbf" + modern + "#comment\r\n\r\nK\t\r\n", CP_UTF8); Check(t.rows == 1 && t.entries.at("K").empty()); });
    Test("duplicate last occurrence and empty key", [&] { auto t = CysUiDictionary::Parse(modern + "K\tA\nK\tB\n\tC\n", CP_UTF8); Check(t.rows == 3 && t.duplicates == 1 && t.entries.at("K") == "B" && t.entries.at("") == "C"); });
    Test("markup and placeholders kept", [&] { auto t = CysUiDictionary::Parse(modern + "K\t#cFF0000%s0 #{REF} $N\n", CP_UTF8); Check(t.entries.at("K") == "#cFF0000%s0 #{REF} $N"); });
    Test("NFC NFD kept without normalization", [&] { auto t = CysUiDictionary::Parse(modern + u8"K\tế e\u0302\u0301\n", CP_UTF8); Check(t.entries.at("K") == u8"ế e\u0302\u0301"); });
    Test("invalid UTF8 rejected no GBK fallback", [&] { Check(Reject(modern + "K\t\xd7\xe9\xb6\xd3\n")); });
    Test("truncated GBK rejected", [&] { Check(Reject(legacy + "1\tK\t\x81\n")); });
    Test("invalid UTF8 key rejected", [&] { Check(Reject(modern + "\xff\tV\n")); });
    Test("schema mismatch rejected", [&] { Check(Reject("INT\tSTRING\nINT\tSTRING\n1\tV\n")); });
    Test("row width rejected", [&] { Check(Reject(modern + "1\tK\tV\n")); });
    Test("header width rejected", [&] { Check(Reject("STRING\tSTRING\nH\nK\tV\n")); });
    Test("invalid ID rejected", [&] { Check(Reject(legacy + "oops\tK\tV\n")); });
    Test("empty dictionary rejected", [&] { Check(Reject("") && Reject(modern)); });
    Test("NUL rejected", [&] { Check(Reject(modern + std::string("K\tV\0X", 5))); });
    Test("line bound rejected", [&] { Check(Reject(modern + "K\t" + std::string(65537, 'x'))); });
    Test("unsupported display encoding rejected", [&] { Check(Reject(modern + "K\tV", 1258)); });
    Test("unrepresentable legacy output rejected", [&] { Check(Reject(modern + u8"K\tTiếng Việt", 936)); });
    Test("canonical corpus", [&] { Check(argc == 3); auto t = CysUiDictionary::Parse(Read(argv[1]), CP_UTF8); std::cout << "canonical rows=" << t.rows << " duplicates=" << t.duplicates << " source=" << t.sourceCodePage << " ZUDUI bytes=" << t.entries.at("ZUDUI").size() << "\n"; Check(t.rows == 77582 && t.duplicates == 2 && t.sourceCodePage == CP_UTF8 && t.entries.at("ZUDUI") == u8"Tổ đội"); });
    Test("legacy corpus", [&] { Check(argc == 3); auto t = CysUiDictionary::Parse(Read(argv[2]), CP_UTF8); Check(t.rows == 10572 && t.duplicates == 26 && t.sourceCodePage == 936 && t.entries.at("ZUDUI") == u8"组队"); });
    std::cout << passed << "/" << (passed + failed) << " passed\n";
    return failed ? 1 : 0;
}
