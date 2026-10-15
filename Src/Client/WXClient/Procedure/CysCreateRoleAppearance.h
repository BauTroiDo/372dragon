#pragma once

#include <cstddef>
#include <string>
#include <utility>
#include <vector>

class CObject_PlayerOther;

// CYS: creation-only view of DATA CY and Canonical tables; resource keys remain original bytes.
namespace CysCreateRoleAppearance
{
enum TableKind { Race, Model, Face, Hair, Portrait, Outfit, Visual, TableCount };
const char* ResourceName(TableKind kind);

struct Option
{
    int id = -1;
    int sex = -1;
    int flags = 0;
    std::string name;
    std::string image;
};

struct Recipe
{
    int sex = -1;
    int faceId = -1;
    int hairId = -1;
    int outfitId = -1;
    std::string object;
    std::vector<std::pair<std::string, std::string> > properties;
};

class Catalog
{
public:
    bool Load(TableKind kind, const char* bytes, std::size_t size, std::string& error);
    bool Ready() const;
    bool ModelObject(int id, std::string& object) const;
    bool PortraitImage(int sex, int id, std::string& image) const;
    std::vector<Option> Options(TableKind kind, int sex) const;
    bool Resolve(int sex, int faceId, int hairId, int outfitId, Recipe& recipe,
                 std::string& error) const;
    bool ResolveIndices(int sex, int faceIndex, int hairIndex, int outfitIndex,
                        Recipe& recipe, std::string& error) const;

private:
    struct Cell { int number = 0; std::string text; };
    typedef std::vector<Cell> Row;
    struct Table { bool loaded = false; std::vector<Row> rows; };
    Table tables_[TableCount];
    const Row* Find(TableKind kind, int id) const;
};

// No wire request or legacy item/DBC overlay is involved in these two operations.
bool LoadResources(Catalog& catalog, std::string& error);
bool Apply(CObject_PlayerOther* object, const Recipe& recipe, std::string& error,
           unsigned int hairColor = 0);
}
