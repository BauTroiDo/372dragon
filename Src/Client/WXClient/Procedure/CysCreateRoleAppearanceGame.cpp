#include "StdAfx.h"
#include "CysCreateRoleAppearance.h"
#include "CysCreateRoleCamera.h"
#include "../DBC/GMDataBase.h"
#include "../Object/Character/Obj_PlayerOther.h"
#include "GameProcedure.h"
#include "../WXRender/ResourceProvider.h"
#include "TDUtil.h"

namespace CysCreateRoleAppearance
{
namespace
{
bool ApplyCamera(tEntityNode* actor, const std::string& object, std::string& error)
{
    static CameraTable cameras;
    static bool loaded = false;
    static std::map<std::string, std::string> objectCameras;
    if (!loaded)
    {
        if (!CGameProcedure::s_pResourceProvider)
        { error = "CY camera resource provider unavailable"; return false; }
        char* bytes = NULL;
        const DWORD size = CGameProcedure::s_pResourceProvider->loadResource("CysCreateCamera.txt", bytes, "General");
        if (!bytes || !size)
        { error = "CY camera resource missing"; return false; }
        loaded = cameras.Load(bytes, size, error);
        CGameProcedure::s_pResourceProvider->unloadResource(bytes, size);
        if (!loaded) return false;
        TDU_Log("CYS create UI: camera table loaded bytes=%u", static_cast<unsigned>(size));
    }
    auto camera = objectCameras.find(object);
    if (camera == objectCameras.end())
    {
        STRING rowId;
        actor->Actor_GetObjectProperty("Camera_Main", rowId);
        std::string value;
        if (!cameras.Resolve(rowId, value, error)) return false;
        TDU_Log("CYS create UI: camera row=%s height-distance=%s", rowId.c_str(), value.c_str());
        camera = objectCameras.emplace(object, value).first;
    }
    // Preserve the resolved value per base object because the next appearance
    // refresh reuses the actor whose Camera_Main is already in renderer format.
    actor->Actor_SetObjectProperty("Camera_Main", camera->second.c_str());
    STRING actual;
    actor->Actor_GetObjectProperty("Camera_Main", actual);
    if (actual != camera->second)
    {
        TDU_Log("CYS create UI: camera readback expected=%s actual=%s", camera->second.c_str(), actual.c_str());
        error = "CY preview camera value rejected";
        return false;
    }
    return true;
}
}

bool LoadResources(Catalog& catalog, std::string& error)
{
    if (!CGameProcedure::s_pResourceProvider)
    { error = "appearance resource provider unavailable"; return false; }
    Catalog next;
    for (int i = Race; i < TableCount; ++i)
    {
        char* bytes = NULL;
        const TableKind kind = static_cast<TableKind>(i);
        const DWORD size = CGameProcedure::s_pResourceProvider->loadResource(ResourceName(kind), bytes, "General");
        if (!bytes || !size)
        { error = "appearance resource missing: "; error += ResourceName(kind); return false; }
        const bool loaded = next.Load(kind, bytes, size, error);
        CGameProcedure::s_pResourceProvider->unloadResource(bytes, size);
        if (!loaded) { error += ": "; error += ResourceName(kind); return false; }
    }
    catalog = std::move(next);
    return true;
}

bool Apply(CObject_PlayerOther* object, const Recipe& recipe, std::string& error, unsigned int hairColor)
{
    error.clear();
    if (!object || recipe.sex < 0 || recipe.sex > 1 || recipe.object.empty()
        || !object->InitializeCreationPreview(recipe.object.c_str()))
    { error = "creation preview object unavailable"; return false; }
    tEntityNode* actor = object->GetRenderInterface();
    if (!ApplyCamera(actor, recipe.object, error)) return false;
    for (const auto& property : recipe.properties)
    {
        actor->Actor_SetObjectProperty(property.first.c_str(), property.second.c_str());
        STRING actual;
        actor->Actor_GetObjectProperty(property.first.c_str(), actual);
        if (actual != property.second)
        { error = "creation preview property rejected: "; error += property.first; return false; }
    }
    // CY applies the saved RGBA after the hair mesh. This recipe path bypasses
    // CharacterData; its material otherwise retains the untinted white colour.
    // Zero is a valid black colour, also the default sent by character creation.
    static const bool applyHairColor = []() {
        char value[8] = {};
        return !(GetEnvironmentVariableA("CYS_LOGIN_HAIR_COLOR", value, sizeof(value)) == 1 && value[0] == '0');
    }(); // Same-binary negative control; enabled in ordinary play.
    if (applyHairColor) actor->Actor_SetHairColor(hairColor);
    // Exact animation present in both CY base-object Skeletons lists; the closure
    // validates the animation inside each referenced standing skeleton.
    actor->Actor_EnterSkill(TRUE, "\xbf\xd5\xca\xd6\xd5\xbe\xc1\xa2" "01", TRUE, 0.0f);
    return true;
}
}
