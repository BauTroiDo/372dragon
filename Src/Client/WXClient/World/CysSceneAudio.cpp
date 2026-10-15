// CYS-AUDIO (audio-cy 15/09/2026): background music and environment sounds of a scene as CY 3.71.
// Evidence (CY 3.71 Game.exe, Build/re/audio-cy/out, Docs/specs/game/audio-cy_vi.md 5):
//  - CScene::LoadEnvSound FUN_1406c0e30: <SceneDefineEx column 4 (.Scene)> with the extension renamed to ".esd",
//    opened from resource group "Scene"; fewer than 20 columns -> "CScene::LoadEnvSound ESD Less Than 20 Column:%s".
//    Row: 0 id, 1 sound id, 2..4 random sound ids (> 0 added), 5 region type (0 circle, 1 quad, 10 music region),
//    6/7 X/Z, 8 distance, 9 volume factor, 10..15 the three other quad corners, 16 plays per run, 17 interval ms,
//    18 interval before the next run.
//  - scene tick FUN_1406c00e0: listener = MySelf position; type 10 inside -> background music switches to that id
//    (FUN_1406bd3e0(scene, 1, id)), leaving every music region restores SceneDefineEx column 8; types 0/1 need
//    Enable3DSound: in range -> env-type 3D source (FUN_1406890d0) at X/Z, loop when plays per run = 0, max distance
//    = distance, played; out of range -> the source is destroyed (FUN_140689020).
//  - repeats FUN_14068a740: after a play, wait interval ms and play again until the run count is reached, then wait
//    the next-run interval and draw a random id (FUN_1406bde60, never the same id twice in a row when there are more).
//  - volume FUN_14068a1d0: circle = type volume * (1 - d / distance) * gain; quad = full inside the quad, then
//    1 - (distance to the quad) / distance.
#include "StdAfx.h"
#include "Scene.h"
#include "TDUtil.h"
#include "TDDBC_Struct.h"
#include "TLBB_DBC.h"
#include "TDTimeSystem.h"
#include "..\Procedure\GameProcedure.h"
#include "..\Object\ObjectManager.h"
#include "..\Object\Character\Obj_PlayerMySelf.h"
#include "..\Sound\GMSoundSystem.h"
#include "..\Sound\GMSoundSource.h"
#include "..\Sound\CysAudio.h"
#include "..\Variable\GMVariable.h"
#include "..\WxRender\ResourceProvider.h"
#include <math.h>
#include <shlwapi.h>

namespace
{
    FLOAT Cross(FLOAT ax, FLOAT az, FLOAT bx, FLOAT bz, FLOAT px, FLOAT pz)
    {
        return (bx - ax) * (pz - az) - (bz - az) * (px - ax);
    }

    FLOAT SegDist(FLOAT ax, FLOAT az, FLOAT bx, FLOAT bz, FLOAT px, FLOAT pz)
    {
        FLOAT vx = bx - ax, vz = bz - az;
        FLOAT l2 = vx * vx + vz * vz;
        FLOAT t = l2 > 1e-6f ? ((px - ax) * vx + (pz - az) * vz) / l2 : 0.0f;
        if (t < 0.0f) t = 0.0f; else if (t > 1.0f) t = 1.0f;
        FLOAT dx = ax + t * vx - px, dz = az + t * vz - pz;
        return (FLOAT)sqrt(dx * dx + dz * dz);
    }

    // 0 inside the quad (convex, any winding), else distance to its border
    FLOAT QuadDist(const FLOAT q[4][2], FLOAT px, FLOAT pz)
    {
        int nPos = 0, nNeg = 0;
        for (int i = 0; i < 4; i++)
        {
            const FLOAT* a = q[i];
            const FLOAT* b = q[(i + 1) % 4];
            FLOAT c = Cross(a[0], a[1], b[0], b[1], px, pz);
            if (c > 0.0f) nPos++; else if (c < 0.0f) nNeg++;
        }
        if (nPos == 0 || nNeg == 0) return 0.0f;
        FLOAT d = 1e30f;
        for (int i = 0; i < 4; i++)
        {
            FLOAT s = SegDist(q[i][0], q[i][1], q[(i + 1) % 4][0], q[(i + 1) % 4][1], px, pz);
            if (s < d) d = s;
        }
        return d;
    }

    // 0..1 hearing factor of an entry for a listener, < 0 when out of range
    FLOAT EnvFactor(const CScene* /*pScene*/, FLOAT fDistance, BOOL bQuad, const FLOAT q[4][2], FLOAT fX, FLOAT fZ,
                    FLOAT px, FLOAT pz)
    {
        FLOAT d;
        if (bQuad) d = QuadDist(q, px, pz);
        else { FLOAT dx = px - fX, dz = pz - fZ; d = (FLOAT)sqrt(dx * dx + dz * dz); }
        if (d > fDistance) return -1.0f;
        return fDistance > 0.01f ? 1.0f - d / fDistance : 1.0f;
    }
}

void CScene::DestroyEnvSound(void)
{
    for (int i = 0; i < (int)m_pEnvSoundList.size(); i++)
    {
        EnvSound_t& snd = m_pEnvSoundList[i];
        if (snd.pSoundSource)
        {
            CSoundSystemFMod::GetMe()->Source_Destroy(snd.pSoundSource);
            snd.pSoundSource = 0;
        }
    }
    m_pEnvSoundList.clear();
    m_nCysMusicRegion = -1;
}

BOOL CScene::LoadEnvSound()
{
    if (m_pEnvSoundList.size() != 0) DestroyEnvSound();

    // CY: strncpy(row +0x20 = column 4 .Scene) + PathRenameExtensionA(".esd"); the file lies in the "Scene" group
    char szFile[MAX_PATH];
    strncpy(szFile, m_pTheDefine->szWXObjectName ? m_pTheDefine->szWXObjectName : "", MAX_PATH - 5);
    szFile[MAX_PATH - 5] = 0;
    PathRenameExtensionA(szFile, ".esd");

    char* lpAddress = NULL;
    DWORD dwSize = CGameProcedure::s_pResourceProvider->loadResource(szFile, lpAddress, "Scene");
    if (dwSize == 0) dwSize = CGameProcedure::s_pResourceProvider->loadResource(szFile, lpAddress, NULL);
    if (dwSize == 0)
    {
        TDU_Log("CYS audio: scene %d env sound file %s absent (no environment sounds)", m_pTheDefine->nServerID, szFile);
        return TRUE;
    }
    DBC::DBCFile dbc(DBC_ENV_SOUND);
    BOOL bOpen = dbc.OpenFromMemory(lpAddress, lpAddress + dwSize + 1, szFile);
    CGameProcedure::s_pResourceProvider->unloadResource(lpAddress, dwSize);
    if (!bOpen)
    {
        TDU_Log("CYS audio: scene %d env sound file %s unreadable", m_pTheDefine->nServerID, szFile);
        return FALSE;
    }
    if (dbc.GetFieldsNum() < 20)
    {
        // CY throws "CScene::LoadEnvSound ESD Less Than 20 Column:%s"; here the scene just has no env sounds
        TDU_Log("CScene::LoadEnvSound ESD Less Than 20 Column:%s (columns=%d, skipped)", szFile, dbc.GetFieldsNum());
        return FALSE;
    }

    int nTypes[11] = { 0 };
    m_pEnvSoundList.resize((INT)dbc.GetRecordsNum());
    for (INT i = 0; i < (INT)dbc.GetRecordsNum(); i++)
    {
        EnvSound_t& e = m_pEnvSoundList[i];
        memset(&e, 0, sizeof(e));
        #define CYS_I(c) (dbc.Search_Posistion(i, (c)) ? dbc.Search_Posistion(i, (c))->iValue : 0)
        e.nID = CYS_I(0);
        e.nSoundIDs[0] = CYS_I(1);
        e.nSoundCount = 1;
        for (int c = 2; c <= 4; c++) { INT v = CYS_I(c); if (v > 0) e.nSoundIDs[e.nSoundCount++] = v; }
        e.nSoundID = e.nSoundIDs[0];
        e.nRegionType = CYS_I(5);
        e.fX = (FLOAT)CYS_I(6);
        e.fZ = (FLOAT)CYS_I(7);
        e.fDistance = (FLOAT)CYS_I(8);
        e.fGain = dbc.Search_Posistion(i, 9) ? dbc.Search_Posistion(i, 9)->fValue : 1.0f;
        if (e.fGain <= 0.0f) e.fGain = 1.0f;
        e.bQuad = (e.nRegionType == 1 || e.nRegionType == 10) && (CYS_I(10) || CYS_I(11) || CYS_I(12) || CYS_I(13));
        if (e.bQuad)
        {
            FLOAT p[4][2] = { { e.fX, e.fZ }, { (FLOAT)CYS_I(10), (FLOAT)CYS_I(11) },
                              { (FLOAT)CYS_I(12), (FLOAT)CYS_I(13) }, { (FLOAT)CYS_I(14), (FLOAT)CYS_I(15) } };
            // convex order around the centroid (CY FUN_1406c2c00 tries the three corner orders)
            FLOAT cx = 0, cz = 0;
            for (int k = 0; k < 4; k++) { cx += p[k][0] * 0.25f; cz += p[k][1] * 0.25f; }
            int idx[4] = { 0, 1, 2, 3 };
            FLOAT ang[4];
            for (int k = 0; k < 4; k++) ang[k] = (FLOAT)atan2(p[k][1] - cz, p[k][0] - cx);
            for (int a = 0; a < 4; a++) for (int b = a + 1; b < 4; b++) if (ang[idx[b]] < ang[idx[a]]) { int t = idx[a]; idx[a] = idx[b]; idx[b] = t; }
            for (int k = 0; k < 4; k++) { e.fQuad[k][0] = p[idx[k]][0]; e.fQuad[k][1] = p[idx[k]][1]; }
        }
        e.nRepeat = CYS_I(16);
        e.nIntervalMs = CYS_I(17);
        e.nNextRunMs = CYS_I(18);
        e.nPosx = (UINT)CYS_I(6);
        e.nPosz = (UINT)CYS_I(7);
        e.pSoundSource = 0;
        #undef CYS_I
        if (e.nRegionType >= 0 && e.nRegionType <= 10) nTypes[e.nRegionType]++;
    }
    TDU_Log("CYS audio: scene %d env sounds %s rows=%d circle=%d quad=%d music_regions=%d", m_pTheDefine->nServerID,
        szFile, (int)m_pEnvSoundList.size(), nTypes[0], nTypes[1], nTypes[10]);
    return TRUE;
}

// CYS-AUDIO: one looping background source per id (CY FUN_1406bd3e0 / FUN_140688fc0: type 0, 2D, loop)
VOID CScene::PlayBkgSoundID(INT nSoundID, const char* szWhy)
{
    if (m_pBackSound && m_nCysBackSoundID == nSoundID) return;
    if (m_pBackSound)
    {
        CSoundSystemFMod::GetMe()->Source_Destroy(m_pBackSound);
        m_pBackSound = 0;
        m_nCysBackSoundID = -1;
    }
    if (nSoundID < 0) return;
    tSoundBuffer* pSndBuffer = CSoundSystemFMod::GetMe()->Buffer_Create(nSoundID);
    if (!pSndBuffer) return;
    CSoundSourceFMod* pSrc = (CSoundSourceFMod*)CSoundSystemFMod::GetMe()->Source_Create(CSoundSourceFMod::type_background, FALSE, FALSE);
    if (!pSrc) return;
    pSrc->SetCysWhat(szWhy);
    pSrc->SetBuffer(pSndBuffer);
    pSrc->SetLooping(TRUE);
    pSrc->Play();
    m_pBackSound = pSrc;
    m_nCysBackSoundID = nSoundID;
    TDU_Log("CYS audio: scene %d background music id=%d (%s)", m_pTheDefine->nServerID, nSoundID, szWhy);
}

//控制背景音乐
VOID CScene::ControlBkgSound(BOOL bEnable)
{
    if (bEnable)
    {
        INT nID = m_pTheDefine->nBackSound;	// SceneDefineEx column 8
        const char* szWhy = "scene-bg";
        if (m_nCysMusicRegion >= 0 && m_nCysMusicRegion < (INT)m_pEnvSoundList.size())
        {
            nID = m_pEnvSoundList[m_nCysMusicRegion].nSoundID;
            szWhy = "music-region";
        }
        PlayBkgSoundID(nID, szWhy);
    }
    else if (m_pBackSound)
    {
        CSoundSystemFMod::GetMe()->Source_Destroy(m_pBackSound);
        m_pBackSound = 0;
        m_nCysBackSoundID = -1;
    }
}

//控制背景音乐音量
VOID CScene::ControlBkgSoundVol()
{
    if (m_pBackSound) m_pBackSound->UpdateVolume();
}

//控制环境音音量
VOID CScene::ControlEnvSoundVol()
{
    for (UINT i = 0; i < m_pEnvSoundList.size(); i++)
        if (m_pEnvSoundList[i].pSoundSource) m_pEnvSoundList[i].pSoundSource->UpdateVolume();
}

//控制环境音
VOID CScene::ControlEnvSound(BOOL bEnable)
{
    // CY FUN_1406bd650: enable -> reload the ESD (FUN_1406c0e30); disable -> destroy every env source
    if (bEnable)
    {
        LoadEnvSound();
    }
    else
    {
        for (UINT i = 0; i < m_pEnvSoundList.size(); i++)
        {
            if (m_pEnvSoundList[i].pSoundSource)
            {
                CSoundSystemFMod::GetMe()->Source_Destroy(m_pEnvSoundList[i].pSoundSource);
                m_pEnvSoundList[i].pSoundSource = 0;
            }
        }
    }
}

VOID CScene::Tick(VOID)
{
    TickEnvSound();
}

VOID CScene::TickEnvSound(VOID)
{
    CObject_PlayerMySelf* pMySelf = CObjectManager::GetMe()->GetMySelf();
    if (!pMySelf || !CSoundSystemFMod::GetMe()) return;
    FLOAT px = pMySelf->GetPosition().x, pz = pMySelf->GetPosition().z;
    BOOL bEnv = (CVariableSystem::GetMe()->GetAs_Int(CSoundSystemFMod::sz3DSoundVar) == 1);
    BOOL bBg = (CVariableSystem::GetMe()->GetAs_Int(CSoundSystemFMod::szBKSoundVar) == 1);
    INT nDeltaMs = CGameProcedure::s_pTimeSystem ? (INT)CGameProcedure::s_pTimeSystem->GetDeltaTime() : 0;

    INT nMusicRegion = -1;
    for (UINT i = 0; i < m_pEnvSoundList.size(); i++)
    {
        EnvSound_t& e = m_pEnvSoundList[i];
        FLOAT fFactor = EnvFactor(this, e.fDistance, e.bQuad, e.fQuad, e.fX, e.fZ, px, pz);

        if (e.nRegionType == 10)
        {
            // music region: the first one the player stands in wins (CY bVar2 guard)
            if (fFactor >= 0.0f && nMusicRegion < 0 && (!e.bQuad || QuadDist(e.fQuad, px, pz) == 0.0f)) nMusicRegion = (INT)i;
            continue;
        }

        if (!bEnv || fFactor < 0.0f)
        {
            if (e.pSoundSource)
            {
                CSoundSystemFMod::GetMe()->Source_Destroy(e.pSoundSource);
                e.pSoundSource = 0;
            }
            e.nPlayed = 0;
            e.nTimerMs = 0;
            continue;
        }

        CSoundSourceFMod* pSrc = (CSoundSourceFMod*)e.pSoundSource;
        if (!pSrc)
        {
            tSoundBuffer* pSndBuffer = CSoundSystemFMod::GetMe()->Buffer_Create(e.nSoundID);
            if (!pSndBuffer) { e.nRegionType = -1; continue; }	// missing id/file: logged once, entry disabled
            pSrc = (CSoundSourceFMod*)CSoundSystemFMod::GetMe()->Source_Create(CSoundSourceFMod::type_circumstance, e.bQuad ? FALSE : TRUE, FALSE);
            if (!pSrc) continue;
            pSrc->SetCysWhat(e.bQuad ? "env-quad" : "env-circle");
            pSrc->SetBuffer(pSndBuffer);
            pSrc->SetPos(fVector3(e.fX, 0.0f, e.fZ));
            pSrc->SetMaxDistance(e.fDistance);
            pSrc->SetGain(e.bQuad ? e.fGain * fFactor : e.fGain);
            pSrc->SetLooping(e.nRepeat == 0);
            pSrc->Play();
            e.pSoundSource = pSrc;
            e.nPlayed = 1;
            e.nTimerMs = 0;
            continue;
        }

        if (e.bQuad)
        {
            pSrc->SetGain(e.fGain * fFactor);
        }
        pSrc->UpdateVolume();

        // repeats (CY FUN_14068a740)
        if (e.nRepeat > 0)
        {
            e.nTimerMs += nDeltaMs;
            if (e.nPlayed >= e.nRepeat)
            {
                if (e.nTimerMs >= e.nNextRunMs)
                {
                    e.nPlayed = 0;
                    e.nTimerMs = 0;
                    INT nOld = e.nSoundID;
                    if (e.nSoundCount > 1)
                    {
                        INT k;
                        do { k = rand() % e.nSoundCount; } while (e.nSoundIDs[k] == nOld);
                        e.nSoundID = e.nSoundIDs[k];
                    }
                    if (e.nSoundID != nOld)
                    {
                        CSoundSystemFMod::GetMe()->Source_Destroy(e.pSoundSource);	// recreated next tick with the new id
                        e.pSoundSource = 0;
                    }
                    else
                    {
                        pSrc->Play();
                        e.nPlayed = 1;
                    }
                }
            }
            else if (e.nTimerMs >= e.nIntervalMs)
            {
                e.nTimerMs = 0;
                pSrc->Play();
                e.nPlayed++;
            }
        }
    }

    // background music: music region or SceneDefineEx column 8
    if (nMusicRegion != m_nCysMusicRegion)
    {
        m_nCysMusicRegion = nMusicRegion;
        if (bBg) ControlBkgSound(TRUE);
    }
}
