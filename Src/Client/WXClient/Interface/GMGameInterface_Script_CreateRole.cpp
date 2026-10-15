#include "StdAfx.h"
#include "GMGameInterface_Script.h"
#include "../Procedure/GamePro_CharCreate.h"
#include "../Procedure/GamePro_CharSel.h"
#include "../Procedure/GamePro_Login.h"
#include "../Event/GMEventSystem.h"
#include "../Global.h"
#include "LuaPlus.h"
#include "TDUtil.h"
#include "../Procedure/CysLoginScene.h"
#include "../WXRender/ResourceProvider.h"
#include <sstream>

namespace
{
std::string CyDisplayUtf8(const std::string& gbk)
{
    if (gbk.empty()) return "";
    const int count = MultiByteToWideChar(936, MB_ERR_INVALID_CHARS, gbk.data(), static_cast<int>(gbk.size()), NULL, 0);
    if (!count) TDThrow("Invalid CY display label encoding.");
    std::vector<wchar_t> wide(count);
    MultiByteToWideChar(936, MB_ERR_INVALID_CHARS, gbk.data(), static_cast<int>(gbk.size()), wide.data(), count);
    const int bytes = WideCharToMultiByte(CP_UTF8, 0, wide.data(), count, NULL, 0, NULL, NULL);
    if (!bytes) TDThrow("CY display label conversion failed.");
    std::string result(bytes, '\0');
    WideCharToMultiByte(CP_UTF8, 0, wide.data(), count, &result[0], bytes, NULL, NULL);
    return result;
}
}

namespace SCRIPT_SANDBOX
{
INT CGameProduce_Login::GetCreateOptions(LuaPlus::LuaState* state)
{
    LuaPlus::LuaStack args(state);
    if (!args[2].IsInteger() || !args[3].IsString()) TDThrow("GetCreateOptions requires sex and option kind.");
    const int sex = args[2].GetInteger();
    const std::string kind = args[3].GetString();
    using namespace CysCreateRoleAppearance;
    const TableKind table = kind == "face" ? Face : kind == "hair" ? Hair : kind == "outfit" ? Outfit :
        kind == "portrait" ? Portrait : TableCount;
    if (sex < 0 || sex > 1 || table == TableCount) TDThrow("GetCreateOptions selection is invalid.");
    CGamePro_CharCreate* procedure = CGameProcedure::s_pProcCharCreate;
    procedure->EnsureCyAppearance();
    const auto options = procedure->m_cysAppearance.Options(table, sex);
    LuaPlus::LuaObject result;
    result.AssignNewTable(state);
    for (size_t i = 0; i < options.size(); ++i)
    {
        LuaPlus::LuaObject item = result.CreateTable(static_cast<int>(i) + 1);
        item.SetInteger("id", options[i].id);
        item.SetString("label", CyDisplayUtf8(options[i].name).c_str());
        item.SetString("image", CGamePro_CharCreate::CyPortraitImage(options[i].image).c_str());
    }
    result.PushStack();
    return 1;
}

INT CGameProduce_Login::ApplyCreateAppearance(LuaPlus::LuaState* state)
{
    LuaPlus::LuaStack args(state);
    for (int i = 2; i <= 6; ++i) if (!args[i].IsInteger()) TDThrow("ApplyCreateAppearance requires five integer indices.");
    std::string model, image;
    if (!CGameProcedure::s_pProcCharCreate->ApplyCyAppearance(args[2].GetInteger(), args[3].GetInteger(),
            args[4].GetInteger(), args[5].GetInteger(), args[6].GetInteger(), model, image))
        TDThrow("ApplyCreateAppearance index is outside the CY creation catalog.");
    state->PushString(model.c_str());
    state->PushString(image.c_str());
    return 2;
}

INT CGameProduce_Login::SelectRoleSlot(LuaPlus::LuaState* state)
{
    LuaPlus::LuaStack args(state);
    if (!args[2].IsInteger()) TDThrow("SelectRoleSlot requires one integer index.");
    const bool selected = CGameProcedure::s_pProcCharSel->SelectRoleIndex(args[2].GetInteger());
    state->PushInteger(selected ? 1 : 0);
    return 1;
}

INT CGameProduce_Login::ShowCreatePreview(LuaPlus::LuaState* state)
{
    LuaPlus::LuaStack args(state);
    if (!args[2].IsInteger() || !args[3].IsInteger()) TDThrow("ShowCreatePreview requires sect and sex.");
    const int id = args[2].GetInteger(), sex = args[3].GetInteger();
    if (id < 0 || id >= 15 || sex < 0 || sex > 1) TDThrow("Invalid CY sect preview selection.");
    static std::vector<std::pair<std::string, std::string> > descriptions;
    if (descriptions.empty())
    {
        char* bytes = NULL;
        const DWORD size = CGameProcedure::s_pResourceProvider->loadResource("CysCreatePreview.txt", bytes, "General");
        if (!bytes || !size) TDThrow("CY preview descriptions are missing.");
        const std::string data(bytes, size);
        CGameProcedure::s_pResourceProvider->unloadResource(bytes, size);
        std::istringstream stream(data);
        std::vector<std::pair<std::string, std::string> > next;
        std::string row;
        while (std::getline(stream, row))
        {
            if (!row.empty() && row.back() == '\r') row.pop_back();
            const size_t first = row.find('\t');
            const size_t second = first == std::string::npos ? first : row.find('\t', first + 1);
            if (first == std::string::npos || second == std::string::npos ||
                row.substr(0,first) != std::to_string(next.size()) ||
                row.find('\t',second+1) != std::string::npos || second+1 >= row.size())
                TDThrow("Invalid CY preview description row.");
            const std::string image = row.substr(first+1, second-first-1);
            const std::string text = row.substr(second+1);
            if (image.compare(0,sizeof("set:CysCR_Create")-1,"set:CysCR_Create") != 0 ||
                !MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, text.data(), static_cast<int>(text.size()), NULL, 0))
                TDThrow("Invalid CY preview image or UTF-8 description.");
            next.emplace_back(image, text);
        }
        if (next.size() != 15) TDThrow("CY preview description count differs from 15.");
        descriptions.swap(next);
    }
    std::string model;
    if (!CGameProcedure::s_pProcCharCreate->ShowCySectPreview(id, sex, model))
        TDThrow("CY sect preview model is unavailable.");
    state->PushString(model.c_str());
    state->PushString(descriptions[id].first.c_str());
    state->PushString(descriptions[id].second.c_str());
    return 3;
}

INT CGameProduce_Login::HideCreatePreview(LuaPlus::LuaState* state)
{
    CGameProcedure::s_pProcCharCreate->HideCySectPreview();
    return 0;
}

INT CGameProduce_Login::ModelRotBegin(LuaPlus::LuaState* state)
{
    LuaPlus::LuaStack args(state);
    if (!args[2].IsNumber()) TDThrow("ModelRotBegin requires a speed.");
    CysLoginScene::Rotate(static_cast<float>(args[2].GetNumber()));
    return 0;
}

INT CGameProduce_Login::ModelRotEnd(LuaPlus::LuaState* state)
{
    CysLoginScene::Rotate(0);
    return 0;
}

INT CGameProduce_Login::ModelZoom(LuaPlus::LuaState* state)
{
    LuaPlus::LuaStack args(state);
    if (!args[2].IsNumber()) TDThrow("ModelZoom requires a speed.");
    CysLoginScene::Zoom(static_cast<float>(args[2].GetNumber()));
    return 0;
}

INT DataPool::AskCreateCharCode(LuaPlus::LuaState* state)
{
    CGamePro_Login* login = CGameProcedure::s_pProcLogIn;
    // CYS: offline renderer fixture is explicit and cannot reach the WSL endpoint.
    char mode[16] = {};
    const DWORD length = GetEnvironmentVariableA("CYS_CREATE_ROLE_SMOKE", mode, sizeof(mode));
    const auto* server = login->GetAreaLoginServerInfo(0, 0);
    if (g_cysGlLoginSmoke && length == 7 && strcmp(mode, "Preview") == 0 &&
        !login->IsModernLoginActive() && server && server->szIp == "127.0.0.1" && server->iPort == 14400 &&
        CGameProcedure::GetActiveProcedure() == CGameProcedure::s_pProcCharSel)
    {
        TDU_Log("CYS create UI: offline permission fixture, no network");
        CGameProcedure::s_pProcCharSel->ChangeToCreateRole();
        return 0;
    }
    if (!login->RequestModernCreatePermission())
        CGameProcedure::s_pEventSystem->PushEvent(GE_GAMELOGIN_SHOW_SYSTEM_INFO, u8"Chưa thể tạo nhân vật. Hãy kết nối máy chủ thử nghiệm trước.");
    return 0;
}
}
