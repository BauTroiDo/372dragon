#include "StdAfx.h"
#include "CysLoginScene.h"
#include "GameProcedure.h"
#include "GamePro_CharCreate.h"
#include "GamePro_CharSel.h"
#include "../Object/Character/Obj_PlayerOther.h"
#include "../FakeObject/GMFakeObjSystem.h"
#include "../WXRender/RenderSystem.h"
#include "../WXRender/ResourceProvider.h"
#include "CysLoginSceneBridge.h"
#include "TDTimeSystem.h"
#include "TDUtil.h"
#include <cmath>
#include <algorithm>
#include <locale>
#include <sstream>

namespace CysLoginScene
{
namespace
{
struct Pose { fVector3 position, eye; float yaw = 0; float orientation[4] = {}; float fov = 0; };
Pose poses[5];
std::string scene;
Mode current = None;
CObject_PlayerOther* showing = NULL;
std::vector<CObject_PlayerOther*> displayed;
int poseIndex = -1;
float rotateSpeed = 0, zoomSpeed = 0, zoomFactor = 1;
std::string loadedScene; // CYS-CHARSEL: scene file currently in the renderer when a login/showroom scene loaded it

// CYS-CHARSEL: CY 3.71 login background (Docs\specs\ui\login-scene-cy_vi.md, Build\Logs\2026-09-15-charsel-scene).
// Game.exe CGamePro_Login::Init FUN_14062f940: Scene_Load(-1, "erengu_DL.Scene") - one fixed scene, no random/time
// choice (the scene-reload callback FUN_1406c5650 maps id -1 to the same name). Render.dll FUN_18002b5e0 then calls
// CCamera_CharSel FUN_180002a30: FOVy 42 deg, the position/orientation below (binary32 constants in that function),
// setFarClipDistance(40000). The camera is static; the motion comes from the scene (particles, effects, water, clouds).
const char* const kLoginScene = "erengu_DL.Scene";
const float kLoginEye[3] = {-2279.2099609375f, 4462.81005859375f, -8181.77001953125f};
const float kLoginOrientation[4] = {0.24467399716377258f, -0.009028379805386066f, -0.9688889980316162f, -0.03574720025062561f};
const float kLoginFov = 42.0f;
const float kLoginFarClip = 40000.0f;
int loginAvailable = -1; // -1 unknown, 0 scene not installed (non-CY data profile), 1 installed

float Distance(const fVector3& a, const fVector3& b)
{
    const float x = a.x-b.x, y = a.y-b.y, z = a.z-b.z;
    return std::sqrt(x*x+y*y+z*z);
}

void Visibility(CObject_PlayerOther* object, bool visible)
{
    if (!object || !object->GetRenderInterface()) return;
    HMODULE module = GetModuleHandleA("Render.dll");
    if (!module) module = GetModuleHandleA("WXRender.dll");
    const auto call = module ? reinterpret_cast<CysLoginSceneBridge::ActorVisible>(
        GetProcAddress(module, "CysLoginActorSceneVisible")) : NULL;
    if (!call || !call(CGameProcedure::s_pGfxSystem, object->GetRenderInterface(), visible ? 1 : 0))
        TDThrow("CY login actor scene visibility bridge failed.");
}

void Scale(CObject_PlayerOther* actor, float scale)
{
    HMODULE module = GetModuleHandleA("Render.dll");
    if (!module) module = GetModuleHandleA("WXRender.dll");
    const auto call = module ? reinterpret_cast<CysLoginSceneBridge::ActorScale>(
        GetProcAddress(module, "CysLoginActorSceneScale")) : NULL;
    if (!call || !call(CGameProcedure::s_pGfxSystem, actor->GetRenderInterface(), scale))
        TDThrow("CY login actor scale bridge failed readback.");
}

void LoadPoses()
{
    if (!scene.empty()) return;
    char* bytes = NULL;
    const DWORD size = CGameProcedure::s_pResourceProvider->loadResource("CysLoginShowroom.txt", bytes, "General");
    if (!bytes || !size) TDThrow("CY login showroom presentation is missing.");
    const std::string data(bytes, size);
    CGameProcedure::s_pResourceProvider->unloadResource(bytes, size);
    std::istringstream stream(data);
    stream.imbue(std::locale::classic());
    std::string tag, file;
    if (!(stream >> tag >> file) || tag != "scene" || file.find('/') != std::string::npos ||
        file.find('\\') != std::string::npos || file.find("..") != std::string::npos)
        TDThrow("CY login showroom scene field is invalid.");
    const char* labels[] = {"female", "male", "select0", "select1", "select2"};
    Pose next[5];
    for (int i = 0; i < 5; ++i)
    {
        Pose& p = next[i];
        if (!(stream >> tag >> p.position.x >> p.position.y >> p.position.z >> p.yaw >>
              p.eye.x >> p.eye.y >> p.eye.z >> p.orientation[0] >> p.orientation[1] >>
              p.orientation[2] >> p.orientation[3] >> p.fov) || tag != labels[i])
            TDThrow("CY login showroom camera row is invalid.");
        const float values[] = {p.position.x,p.position.y,p.position.z,p.yaw,
            p.eye.x,p.eye.y,p.eye.z,p.orientation[0],p.orientation[1],p.orientation[2],p.orientation[3],p.fov};
        for (float value : values)
            if (!std::isfinite(value) || fabs(value) > 1000000.0f)
                TDThrow("CY login showroom camera value is invalid.");
        const float distance = Distance(p.eye, p.position);
        if (distance < 10.0f || distance > 10000.0f)
            TDThrow("CY login showroom camera distance is invalid.");
    }
    if (stream >> tag) TDThrow("CY login showroom has trailing fields.");
    for (int i = 0; i < 5; ++i) poses[i] = next[i];
    scene.swap(file);
}

HMODULE RenderModule()
{
    HMODULE module = GetModuleHandleA("Render.dll");
    return module ? module : GetModuleHandleA("WXRender.dll");
}

bool LoginSceneInstalled()
{
    if (loginAvailable < 0)
    {
        char* bytes = NULL;
        const DWORD size = CGameProcedure::s_pResourceProvider->loadResource(kLoginScene, bytes, NULL);
        if (bytes) CGameProcedure::s_pResourceProvider->unloadResource(bytes, size);
        loginAvailable = size ? 1 : 0;
        TDU_Log("CYS login scene: %s %s", kLoginScene, loginAvailable ? "installed" : "absent (login background stays empty)");
    }
    return loginAvailable == 1;
}

void LoginCamera()
{
    HMODULE module = RenderModule();
    const auto pose = module ? reinterpret_cast<CysLoginSceneBridge::CameraPose>(
        GetProcAddress(module, "CysLoginSceneCamera")) : NULL;
    const auto clip = module ? reinterpret_cast<CysLoginSceneBridge::CameraFarClip>(
        GetProcAddress(module, "CysLoginSceneFarClip")) : NULL;
    if (!pose || !pose(CGameProcedure::s_pGfxSystem, kLoginEye, kLoginOrientation, kLoginFov))
        TDThrow("CY login background camera bridge failed.");
    if (!clip || !clip(CGameProcedure::s_pGfxSystem, kLoginFarClip))
        TDThrow("CY login background far clip bridge failed.");
}

void Camera()
{
    if (poseIndex < 0 || current == None) return;
    const Pose& p = poses[poseIndex];
    // q * (0,0,-1): dolly along the original camera axis, retaining its roll.
    const float w = p.orientation[0], x = p.orientation[1], y = p.orientation[2], z = p.orientation[3];
    const fVector3 forward(-2*(x*z+w*y), -2*(y*z-w*x), -(1-2*(x*x+y*y)));
    const fVector3 eye = p.eye + forward * ((1-zoomFactor) * Distance(p.eye, p.position));
    const float xyz[] = {eye.x,eye.y,eye.z};
    HMODULE module = GetModuleHandleA("Render.dll");
    if (!module) module = GetModuleHandleA("WXRender.dll");
    const auto call = module ? reinterpret_cast<CysLoginSceneBridge::CameraPose>(
        GetProcAddress(module,"CysLoginSceneCamera")) : NULL;
    if (!call || !call(CGameProcedure::s_pGfxSystem,xyz,p.orientation,p.fov))
        TDThrow("CY login scene camera bridge failed.");
}
}

void Enter(Mode mode)
{
    if (mode != Create && mode != Select && mode != Login) TDThrow("Invalid CY login scene mode.");
    if (current == mode) return;
    if (mode == Login)
    {
        if (!LoginSceneInstalled()) return;
    }
    else LoadPoses();
    CFakeObjSystem::GetMe()->OnUIUnHook("CreateRole_Model");
    for (auto* actor : displayed) Visibility(actor, false);
    displayed.clear();
    showing = NULL;
    rotateSpeed = zoomSpeed = 0;
    zoomFactor = 1;
    current = mode;
    // Both screens use the installed CY showroom; no world/legacy test scene.
    // CYS-CHARSEL: CY reloads on every Init (login -1 erengu_DL, create/select -2 tl3chuangjian); here only when another
    // scene replaced it (login <-> showroom, or the world), so create <-> select keeps its actors and camera.
    const std::string wanted = mode == Login ? std::string(kLoginScene) : scene;
    const bool load = loadedScene != wanted;
    if (load)
    {
        const DWORD started = ::timeGetTime();
        CGameProcedure::s_pGfxSystem->Scene_Load(mode == Login ? -1 : -2, wanted);
        loadedScene = wanted;
        TDU_Log("CYS login scene: loaded %s id=%d in %lu ms", wanted.c_str(), mode == Login ? -1 : -2,
            (unsigned long)(::timeGetTime() - started));
        // CYS-SKY: like CY 3.71 the Render.dll day clock runs in the procedure scenes (the game sets no time there).
        HMODULE module = GetModuleHandleA("Render.dll");
        if (!module) module = GetModuleHandleA("WXRender.dll");
        const auto clock = module ? reinterpret_cast<CysLoginSceneBridge::SkyClock>(
            GetProcAddress(module, "CysSceneSkyClock")) : NULL;
        if (!clock || !clock(CGameProcedure::s_pGfxSystem, 1))
            TDU_Log("CYS login scene: sky clock bridge unavailable");
    }
    CGameProcedure::s_pGfxSystem->Camera_SetCurrent(CRenderSystem::CHAR_VIEW);
    if (mode == Login)
    {
        poseIndex = -1;
        LoginCamera();
    }
    else
    {
        poseIndex = mode == Create ? 0 : 2;
        Camera();
    }
    TDU_Log("CYS login scene: enter mode=%s scene=%s reload=%d",
        mode == Create ? "create" : mode == Select ? "select" : "login", wanted.c_str(), load ? 1 : 0);
}

void Leave(Mode mode)
{
    if (current != mode) return;
    for (auto* actor : displayed) Visibility(actor, false);
    displayed.clear();
    showing = NULL;
    current = None;
    rotateSpeed = zoomSpeed = 0;
}

void Show(CObject_PlayerOther* actor, int sex, int slot)
{
    if (current == None || current == Login || !actor || sex < 0 || sex > 1 || slot < 0 || slot >= 3 || !actor->GetRenderInterface())
        TDThrow("CY login scene actor is not ready.");
    CFakeObjSystem::GetMe()->OnUIUnHook("CreateRole_Model");
    if (current == Create && showing && showing != actor)
    {
        Visibility(showing, false);
        displayed.clear();
    }
    const int next = current == Create ? sex : 2 + slot;
    const bool changed = showing != actor || poseIndex != next;
    poseIndex = next;
    fVector3 position;
    if (!CGameProcedure::s_pGfxSystem->Axis_Trans(CRenderSystem::AX_GFX, poses[next].position,
            CRenderSystem::AX_GAME, position)) TDThrow("CY login scene position conversion failed.");
    Scale(actor, current == Create ? 1.5f : 1.0f);
    actor->SetPosition(position);
    if (changed) actor->SetFaceDir(poses[next].yaw);
    Visibility(actor, true);
    showing = actor;
    if (std::find(displayed.begin(), displayed.end(), actor) == displayed.end()) displayed.push_back(actor);
    Camera();
    TDU_Log("CYS login scene: actor sex=%d pose=%d position=%.3f,%.3f,%.3f main-visible=1 scale=%.1f verified",
        sex, next, position.x, position.y, position.z, current == Create ? 1.5f : 1.0f);
}

void Forget(CObject_PlayerOther* actor)
{
    const auto found = std::find(displayed.begin(), displayed.end(), actor);
    if (found != displayed.end())
    {
        Visibility(actor, false);
        displayed.erase(found);
    }
    if (showing != actor) return;
    showing = NULL;
    rotateSpeed = zoomSpeed = 0;
}

void Rotate(float speed)
{
    if (!std::isfinite(speed) || fabs(speed) > 1.0f) TDThrow("Invalid login actor rotation speed.");
    rotateSpeed = showing ? speed : 0;
}

void Zoom(float speed)
{
    if (!std::isfinite(speed) || fabs(speed) > 1.0f) TDThrow("Invalid login camera zoom speed.");
    zoomSpeed = current != None && current != Login ? speed : 0;
}

void Tick(Mode mode)
{
    if (current != mode) return;
    float seconds = CGameProcedure::s_pTimeSystem->GetDeltaTime() * 0.001f;
    if (seconds < 0) seconds = 0;
    if (seconds > 0.1f) seconds = 0.1f;
    if (showing && rotateSpeed != 0)
        showing->SetFaceDir(showing->GetFaceDir() + rotateSpeed * seconds);
    if (zoomSpeed != 0)
    {
        zoomFactor -= zoomSpeed * seconds * 0.5f;
        if (zoomFactor < 0.65f) zoomFactor = 0.65f;
        if (zoomFactor > 1.35f) zoomFactor = 1.35f;
        Camera();
    }
}

float ZoomFactor() { return zoomFactor; }
void NoteSceneLoaded(const char* sceneFile) { loadedScene = sceneFile ? sceneFile : ""; }
const char* LoadedScene() { return loadedScene == kLoginScene ? kLoginScene : ""; }
bool IsActive(Mode mode) { return mode != None && current == mode; }
bool IsShowing(const CObject_PlayerOther* actor) { return actor && actor == showing && current != None; }
}
