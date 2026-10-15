#pragma once

class CObject_PlayerOther;

// CYS: original CY login UI presents actors in the scene, without a MeshWindow.
// Positions and camera poses are staged separately from the world data tables.
namespace CysLoginScene
{
// CYS-CHARSEL: Login = the server-selection + account screens (CY CGamePro_Login::Init loads erengu_DL.Scene).
enum Mode { None, Create, Select, Login };
void Enter(Mode mode);
void Leave(Mode mode);
void Show(CObject_PlayerOther* actor, int sex, int slot = 0);
void Forget(CObject_PlayerOther* actor);
void Tick(Mode mode);
void Rotate(float speed);
void Zoom(float speed);
float ZoomFactor();
bool IsShowing(const CObject_PlayerOther* actor);
// CYS-CHARSEL: the world loaded its own scene (CScene::EnterScene); a later login/showroom Enter reloads its scene.
void NoteSceneLoaded(const char* sceneFile);
// CYS-CHARSEL: "erengu_DL.Scene" when the login background scene is installed and loaded, else empty.
const char* LoadedScene();
bool IsActive(Mode mode);
}
