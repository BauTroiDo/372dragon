#include "CysCreateRoleAppearance.h"
#include "CysCreateRoleCamera.h"
#include <fstream>
#include <iostream>
#include <iterator>
#include <map>

using namespace CysCreateRoleAppearance;
static int passed = 0, failed = 0;
static void Check(bool ok, const char* name)
{
    (ok ? ++passed : ++failed);
    std::cout << (ok ? "PASS " : "FAIL ") << name << "\n";
}
static std::string Read(const std::string& path)
{
    std::ifstream stream(path.c_str(), std::ios::binary);
    return std::string(std::istreambuf_iterator<char>(stream), std::istreambuf_iterator<char>());
}
int main(int argc, char** argv)
{
    if (argc < 2 || argc > 3) return 2;
    const bool cy = argc == 3 && std::string(argv[2]) == "cy";
    const int faceCount = cy ? 6 : 5;
    const char* files[] = {"CharRace.txt", "CharModelEx.txt", "CharFaceGeo.txt", "CharHairGeo.txt",
        "CharacterFace.txt", "NewRoleEquipset.txt", "ItemVisualChar.txt"};
    Catalog catalog;
    std::string error;
    if (cy)
    {
        CameraTable cameras;
        std::string value;
        const std::string cameraSource = Read(std::string(argv[1]) + "/Model_Parameter.txt");
        Check(cameras.Load(cameraSource.data(), cameraSource.size(), error), "load exact CY ISFF camera table");
        Check(cameras.Resolve("1", value, error) && value == "0.95;5.4", "female Camera_Main uses CY row 1");
        Check(cameras.Resolve("3", value, error) && value == "1;6", "male Camera_Main uses CY row 3");
        Check(!cameras.Resolve("2147483648", value, error), "reject camera ID overflow");
        Check(!cameras.Resolve("999999", value, error), "reject absent CY camera row");
        Check(!cameras.Resolve("1;6", value, error), "camera source ID must not be a renderer pair");
        const std::string cameraHeader = "INT\tSTRING\tFLOAT\tFLOAT\r\r\nINT\tSTRING\tFLOAT\tFLOAT\r\r\n";
        const char* invalidRows[] = {"1\tfemale\t0.95\t0\n", "1\tfemale\t0.95\t-1\n",
            "1\tfemale\tNaN\t5.4\n", "1\tfemale\t0.95\tinf\n", "1\tfemale\t0.95oops\t5.4\n",
            "1\tfemale\t-1\t5.4\n", "1\tfemale\t0.95\t1001\n", "1\tfemale\t0.95\n",
            "1\tfemale\t0.95\t5.4\n1\tduplicate\t1\t6\n", "-1\tfemale\t0.95\t5.4\n"};
        for (const char* row : invalidRows)
        {
            const std::string badCamera = cameraHeader + row;
            Check(!cameras.Load(badCamera.data(), badCamera.size(), error), "reject malformed or unsafe camera table");
        }
        Check(cameras.Resolve("1", value, error) && value == "0.95;5.4", "failed camera reload preserves valid values");
        const std::string wrongSchema = "INT\tSTRING\tINT\tINT\nINT\tSTRING\tINT\tINT\n1\tfemale\t1\t6\n";
        Check(!cameras.Load(wrongSchema.data(), wrongSchema.size(), error), "camera numeric columns require FLOAT");
    }
    Check(!catalog.Ready(), "empty catalog not ready");
    for (int i = 0; i < TableCount; ++i)
    {
        const std::string data = Read(std::string(argv[1]) + "/" + files[i]);
        Check(catalog.Load(static_cast<TableKind>(i), data.data(), data.size(), error), files[i]);
        if (!error.empty()) std::cout << error << "\n";
    }
    if (!catalog.Ready()) return 1;
    Check(catalog.Ready(), "seven exact Canonical schemas loaded");
    for (int sex = 0; sex != 2; ++sex)
    {
        Check(catalog.Options(Face, sex).size() == static_cast<std::size_t>(faceCount), "creation face count per selected source");
        Check(catalog.Options(Hair, sex).size() == 3, "three creation hairs per sex");
        Check(catalog.Options(Portrait, sex).size() == 15, "fifteen creation portraits per sex");
        Check(catalog.Options(Outfit, sex).size() == 3, "three starter outfits");
        for (int face = 0; face != faceCount; ++face)
            for (int hair = 0; hair != 3; ++hair)
                for (int outfit = 0; outfit != 3; ++outfit)
                {
                    Recipe recipe;
                    bool ok = catalog.ResolveIndices(sex, face, hair, outfit, recipe, error);
                    ok = ok && recipe.sex == sex && recipe.properties.size() == 9 && !recipe.object.empty();
                    Recipe server;
                    ok = ok && catalog.Resolve(sex, recipe.faceId, recipe.hairId, recipe.outfitId, server, error);
                    ok = ok && server.properties == recipe.properties && server.object == recipe.object;
                    Check(ok, "indexed preview equals server-ID recipe");
                }
    }
    if (cy)
    {
        std::string portrait;
        Check(catalog.PortraitImage(0,149,portrait) && portrait=="set:GirlProtagonist3 image:GirlProtagonist3_1",
            "existing character accepts wardrobe-only portrait");
        Check(!catalog.PortraitImage(1,149,portrait), "existing portrait still rejects opposite sex");
        Check(!catalog.PortraitImage(0,999999,portrait), "existing portrait rejects absent ID");
        for (int id = 4950; id < 4980; ++id)
        {
            std::string object;
            Check(catalog.ModelObject(id, object) && object.size() > 4 &&
                object.substr(object.size()-4) == ".obj", "CY sect preview uses a valid primary model key");
        }
        std::string absent;
        Check(!catalog.ModelObject(-1, absent) && !catalog.ModelObject(2147483647, absent),
            "reject absent sect preview model IDs");
    }
    Recipe female, male;
    Check(catalog.ResolveIndices(0, 0, 0, 0, female, error) && female.faceId == 1 && female.hairId == 1
        && female.outfitId == 0 && female.object == std::string("\xc5\xae\xd6\xf7\xbd\xc7.obj"),
        "female IDs and GBK base template bytes");
    Check(catalog.ResolveIndices(1, 0, 0, 0, male, error) && male.faceId == 100 && male.hairId == 5
        && male.object == std::string("\xc4\xd0\xd6\xf7\xbd\xc7.obj"), "male IDs and GBK base template bytes");
    std::map<std::string, std::string> fp(female.properties.begin(), female.properties.end());
    Check(fp["FootMesh"].find((cy ? "20110906.mesh" : "20100318.mesh")) != std::string::npos
        && fp["ArmMesh"] != fp["FootMesh"] && fp["MainBodyMesh"] != fp["FootMesh"],
        "outfit body/foot/arm columns remain distinct");
    Check(!catalog.Resolve(0, 100, 1, 0, female, error), "reject opposite-sex face");
    Check(!catalog.Resolve(1, 100, 1, 0, female, error), "reject opposite-sex hair");
    Check(!catalog.Resolve(0, 1, 1, 99, female, error), "reject unknown outfit");
    Check(!catalog.ResolveIndices(0, -1, 0, 0, female, error), "reject negative index");
    Check(!catalog.ResolveIndices(0, faceCount, 0, 0, female, error), "reject past face end");
    Check(!catalog.ResolveIndices(2, 0, 0, 0, female, error), "reject unsupported sex");
    Check(catalog.Options(Face, -1).empty() && catalog.Options(Model, 0).empty(), "invalid options empty");
    const std::string original = Read(std::string(argv[1]) + "/CharFaceGeo.txt");
    std::string bad = original;
    bad[4] = 4;
    Check(!catalog.Load(Face, bad.data(), bad.size(), error), "reject legacy face schema");
    Check(!catalog.Load(Face, original.data(), 12, error), "reject truncated header");
    if (cy)
    {
        const std::size_t rowStart = original.find('\n', original.find('\n') + 1) + 1;
        bad = original.substr(0, rowStart) + "1\t0\tpartial.mesh\n";
        Check(!catalog.Load(Face, bad.data(), bad.size(), error), "reject truncated CY text row");
    }
    else Check(!catalog.Load(Face, original.data(), original.size() - 1, error), "reject truncated string pool");
    bad = original; bad[16 + 8] = 0;
    Check(!catalog.Load(Face, bad.data(), bad.size(), error), "reject mesh column numeric type");
    bad = original;
    if (cy)
    {
        const std::size_t rowStart = original.find('\n', original.find('\n') + 1) + 1;
        bad.insert(rowStart, "invalid");
        Check(!catalog.Load(Face, bad.data(), bad.size(), error), "reject invalid CY text row ID");
    }
    else
    {
        for (int i = 0; i != 4; ++i) bad[16 + 44 + 8 + i] = static_cast<char>(0xff);
        Check(!catalog.Load(Face, bad.data(), bad.size(), error), "reject out of range resource pointer");
    }
    Check(catalog.ResolveIndices(0, 0, 0, 0, female, error) && female.faceId == 1,
        "rejected reload preserves prior valid catalog");
    std::cout << "RESULT " << passed << "/" << passed + failed << "\n";
    return failed ? 1 : 0;
}
