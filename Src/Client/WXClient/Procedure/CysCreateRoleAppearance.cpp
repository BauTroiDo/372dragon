#include "CysCreateRoleAppearance.h"

#include <cerrno>
#include <climits>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <set>
#include <sstream>

namespace CysCreateRoleAppearance
{
namespace
{
const char* const names[] = {"CysCreateRace.txt", "CysCreateModel.txt",
    "CysCreateFace.txt", "CysCreateHair.txt", "CysCreatePortrait.txt",
    "CysCreateOutfit.txt", "CysCreateVisual.txt"};
const char* const schemas[] = {"IIIIIIIIII", "ISFFFFIIII", "IISSSIIISII",
    "IISSSSSIIISII", "IISIIS", "ISIII", "ISSSSSSSSSSSSSSSSSSSSSS"};
const char* const cySchemas[] = {"IIIIIIIIII", "ISSFFFFIIIIIIIIIIIIII", "IISSSIIISIII",
    "IISSSSSIIISIII", "IISIIS", "ISIII", "ISSSSSSSSSSSSSSSSSSSSSS"};
std::uint32_t Read32(const char* p)
{
    const unsigned char* b = reinterpret_cast<const unsigned char*>(p);
    return static_cast<std::uint32_t>(b[0]) | (static_cast<std::uint32_t>(b[1]) << 8)
        | (static_cast<std::uint32_t>(b[2]) << 16) | (static_cast<std::uint32_t>(b[3]) << 24);
}
bool ParseInt(const std::string& text, int& value)
{
    if (text.empty()) return false;
    char* end = NULL;
    errno = 0;
    long result = std::strtol(text.c_str(), &end, 10);
    if (errno || !end || *end || result < INT_MIN || result > INT_MAX) return false;
    value = static_cast<int>(result);
    return true;
}
std::vector<std::string> Split(const std::string& line)
{
    std::vector<std::string> result;
    std::size_t start = 0, end;
    do
    {
        end = line.find('\t', start);
        result.push_back(line.substr(start, end == std::string::npos ? end : end - start));
        start = end == std::string::npos ? end : end + 1;
    } while (end != std::string::npos);
    return result;
}
}

const char* ResourceName(TableKind kind)
{
    return kind >= Race && kind < TableCount ? names[kind] : NULL;
}

bool Catalog::Load(TableKind kind, const char* bytes, std::size_t size, std::string& error)
{
    error.clear();
    if (kind < Race || kind >= TableCount || !bytes || size < 4)
    { error = "invalid appearance table input"; return false; }
    std::string schema = schemas[kind];
    Table table;
    if (Read32(bytes) == 0xddbbcc00)
    {
        if (size < 16) { error = "truncated appearance table header"; return false; }
        const std::size_t columns = Read32(bytes + 4), rows = Read32(bytes + 8);
        const std::size_t strings = Read32(bytes + 12);
        if (columns == std::strlen(cySchemas[kind])) schema = cySchemas[kind];
        if (columns != schema.size() || rows > 100000 || columns * rows > 2000000)
        { error = "appearance table schema/count mismatch"; return false; }
        const std::size_t records = 16 + 4 * columns, pool = records + 4 * columns * rows;
        if (pool > size || strings > size - pool || pool + strings != size)
        { error = "appearance table extent mismatch"; return false; }
        for (std::size_t c = 0; c < columns; ++c)
        {
            const unsigned expected = schema[c] == 'I' ? 0 : schema[c] == 'F' ? 1 : 2;
            if (Read32(bytes + 16 + 4 * c) != expected)
            { error = "appearance table column type mismatch"; return false; }
        }
        for (std::size_t r = 0; r < rows; ++r)
        {
            Row row(columns);
            for (std::size_t c = 0; c < columns; ++c)
            {
                std::uint32_t value = Read32(bytes + records + 4 * (r * columns + c));
                if (schema[c] == 'S')
                {
                    if (value >= strings)
                    { error = "appearance table string offset out of range"; return false; }
                    const char* begin = bytes + pool + value;
                    const char* end = static_cast<const char*>(std::memchr(begin, 0, strings - value));
                    if (!end) { error = "appearance table string not terminated"; return false; }
                    row[c].text.assign(begin, end);
                }
                else std::memcpy(&row[c].number, &value, sizeof(value));
            }
            table.rows.push_back(row);
        }
    }
    else
    {
        std::istringstream stream(std::string(bytes, size));
        std::string line;
        if (!std::getline(stream, line)) { error = "missing appearance text header"; return false; }
        if (!line.empty() && line.back() == '\r') line.pop_back();
        const std::vector<std::string> header = Split(line);
        if (header.size() == std::strlen(cySchemas[kind])) schema = cySchemas[kind];
        if (header.size() != schema.size()) { error = "appearance text schema mismatch"; return false; }
        for (std::size_t c = 0; c < schema.size(); ++c)
        {
            const char* expected = schema[c] == 'I' ? "INT" : schema[c] == 'F' ? "FLOAT" : "STRING";
            if (header[c] != expected) { error = "appearance text type mismatch"; return false; }
        }
        // Canonical typed text tables have a second description/header line.
        if (!std::getline(stream, line)) { error = "missing appearance text description"; return false; }
        while (std::getline(stream, line))
        {
            if (!line.empty() && line.back() == '\r') line.pop_back();
            if (line.empty()) continue;
            const std::vector<std::string> fields = Split(line);
            if (fields.size() != schema.size()) { error = "appearance text row width mismatch"; return false; }
            Row row(schema.size());
            for (std::size_t c = 0; c < schema.size(); ++c)
            {
                if (schema[c] == 'I' && !ParseInt(fields[c], row[c].number))
                { error = "invalid appearance integer"; return false; }
                if (schema[c] == 'S') row[c].text = fields[c];
            }
            table.rows.push_back(row);
            if (table.rows.size() > 100000) { error = "too many appearance rows"; return false; }
        }
    }
    std::set<int> ids;
    for (const Row& row : table.rows)
        if (!ids.insert(row[0].number).second)
        { error = "duplicate appearance row ID"; return false; }
    table.loaded = true;
    tables_[kind] = std::move(table);
    return true;
}

bool Catalog::Ready() const
{
    for (const Table& table : tables_) if (!table.loaded) return false;
    return true;
}

const Catalog::Row* Catalog::Find(TableKind kind, int id) const
{
    for (const Row& row : tables_[kind].rows) if (row[0].number == id) return &row;
    return NULL;
}

std::vector<Option> Catalog::Options(TableKind kind, int sex) const
{
    std::vector<Option> result;
    if (sex < 0 || sex > 1 || (kind != Face && kind != Hair && kind != Portrait && kind != Outfit))
        return result;
    for (const Row& row : tables_[kind].rows)
    {
        const int flags = kind == Outfit ? 3 : row[kind == Face ? 7 : kind == Hair ? 9 : 3].number;
        if (kind != Outfit && (row[1].number != sex || (flags != 1 && flags != 3))) continue;
        Option option;
        option.id = row[0].number;
        option.sex = sex;
        option.flags = flags;
        if (kind == Portrait) option.image = row[2].text;
        else option.name = row[kind == Face ? (row.size() == 12 ? 4 : 3)
            : kind == Hair ? (row.size() == 14 ? 6 : 4) : 1].text;
        result.push_back(option);
    }
    return result;
}

bool Catalog::PortraitImage(int sex, int id, std::string& image) const
{
    // Existing characters can own wardrobe portraits unavailable at creation.
    const Row* row = Find(Portrait, id);
    if (sex < 0 || sex > 1 || !row || (*row)[1].number != sex || (*row)[2].text.empty()) return false;
    image = (*row)[2].text;
    return true;
}

bool Catalog::Resolve(int sex, int faceId, int hairId, int outfitId, Recipe& recipe,
                      std::string& error) const
{
    error.clear();
    if (!Ready() || sex < 0 || sex > 1) { error = "appearance catalog/sex unavailable"; return false; }
    const Row* race = Find(Race, sex);
    const Row* model = race ? Find(Model, (*race)[3].number) : NULL;
    const Row* face = Find(Face, faceId);
    const Row* hair = Find(Hair, hairId);
    const Row* outfit = Find(Outfit, outfitId);
    if (!model || !face || !hair || !outfit || (*face)[1].number != sex || (*hair)[1].number != sex)
    { error = "appearance row missing or sex mismatch"; return false; }
    Recipe next;
    next.sex = sex; next.faceId = faceId; next.hairId = hairId; next.outfitId = outfitId;
    next.object = (*model)[1].text;
    next.properties.push_back(std::make_pair("FaceMesh", (*face)[2].text));
    next.properties.push_back(std::make_pair("HairMesh", (*hair)[2].text));
    next.properties.push_back(std::make_pair("HairMesh2", (*hair)[hair->size() == 14 ? 4 : 3].text));
    const char* const mesh[] = {"MainBodyMesh", "FootMesh", "ArmMesh"};
    const char* const material[] = {"MainBodyMat", "FootMat", "ArmMat"};
    for (int part = 0; part != 3; ++part)
    {
        const Row* visual = Find(Visual, (*outfit)[2 + part].number);
        if (!visual) { error = "starter outfit visual missing"; return false; }
        next.properties.push_back(std::make_pair(mesh[part], (*visual)[1 + 11 * sex].text));
        next.properties.push_back(std::make_pair(material[part], (*visual)[2 + 11 * sex].text));
    }
    // Bald hairstyles intentionally leave the outer hair mesh empty and use
    // only the scalp in HairMesh2. They remain valid persisted appearances.
    if (next.object.empty() || next.properties[0].second.empty() ||
        (next.properties[1].second.empty() && next.properties[2].second.empty()))
    { error = "empty required appearance resource"; return false; }
    recipe = std::move(next);
    return true;
}

bool Catalog::ModelObject(int id, std::string& object) const
{
    const Row* row = Find(Model, id);
    if (!row || row->size() < 2 || (*row)[1].text.empty()) return false;
    object = (*row)[1].text;
    return true;
}

bool Catalog::ResolveIndices(int sex, int faceIndex, int hairIndex, int outfitIndex,
                             Recipe& recipe, std::string& error) const
{
    const std::vector<Option> faces = Options(Face, sex), hairs = Options(Hair, sex), outfits = Options(Outfit, sex);
    if (faceIndex < 0 || hairIndex < 0 || outfitIndex < 0 || faceIndex >= static_cast<int>(faces.size())
        || hairIndex >= static_cast<int>(hairs.size()) || outfitIndex >= static_cast<int>(outfits.size()))
    { error = "appearance selection index out of range"; return false; }
    return Resolve(sex, faces[faceIndex].id, hairs[hairIndex].id, outfits[outfitIndex].id, recipe, error);
}
}
