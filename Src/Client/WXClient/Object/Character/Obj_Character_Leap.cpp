#include "StdAfx.h"
#include "Obj_Character.h"
// LEGACY A/B ONLY below: the original unverified assumptions are preserved when
// CYS_QINGGONG_LEGACY=1. Production now uses the live GL/CY implementation at the end.
// CYS-MOVE2: the visible part of 轻功 (qinggong): a character glides from A to B on a parabola.
//
// What is CY data and what is inference (spec Docs/specs/client/move-2_vi.md, section "leap arc"):
//   [DK] the trigger and the wire: CGCharFly / GCCharFly, see Network/CysLeapNet.h.
//   [DK] the animations: ActionSetKV.txt 393 "轻功起飞" (takeoff), 394 "轻功空中" (in the air), 395 "轻功落地"
//        (landing); per-menpai variants 814/815/816 "轻功1a/b/c" .. 1128..1130 "轻功9a/b/c". The SendActSet column
//        of SkillTemplate rows 23..31 ("411;412;413") resolves to 慕容博 boss actions in this data set, so it is NOT
//        used - data bug, reported in the handoff.
//   [DK] the duration: SkillTemplate SendTime (column 34) of the skill = 1200 ms for every qinggong row.
//   [SL] the arc height: 0.25 * distance, clamped to [1.5, 4.0] game units - not measured against CY yet; the CY
//        oracle can only answer it with a server-side GCCharFly echo, see the handoff "next".
//   [SL] which "轻功N" variant belongs to which menpai: N = menpai + 1, falling back to the generic 393..395 when the
//        character's action set has no such action.
#include "..\..\Procedure\GameProcedure.h"
#include "..\..\DataPool\GMDP_CharacterData.h"
#include "..\..\Object\ObjectManager.h"
#include "Obj_PlayerMySelf.h"
#include "SkillDataMgr.h"
#include "TDTimeSystem.h"
#include "TDUtil.h"
#include <math.h>
#include <stdlib.h>
#include "CysQinggongCore.h"
#include "..\..\World\WorldManager.h"
#include "..\..\World\Scene.h"

namespace
{
    bool CysQinggongLegacy()
    {
        static const bool enabled = getenv("CYS_QINGGONG_LEGACY") && atoi(getenv("CYS_QINGGONG_LEGACY")) == 1;
        return enabled;
    }
    bool CysQinggongLog()
    {
        static const bool enabled = getenv("CYS_QINGGONG_LOG") && atoi(getenv("CYS_QINGGONG_LOG")) == 1;
        return enabled;
    }

	const UINT  kDefaultLeapMs   = 1200;   // SkillTemplate SendTime of 23..31 / 34 / 110 / 4648
	const FLOAT kHeightPerUnit   = 0.25f;  // [SL]
	const FLOAT kMinHeight       = 1.5f;   // [SL]
	const FLOAT kMaxHeight       = 4.0f;   // [SL]
	const FLOAT kTakeoffFraction = 0.30f;  // switch to the in-air loop no later than 30 % of the flight [SL]

	// ActionSetKV ids (Assets/CanonicalCY/Data/ConfigFolder/ActionSet/ActionSetKV.txt, read 18/09/2026).
	const INT kGenericLeap[3] = { 393, 394, 395 };
	INT MenpaiLeapAction(INT nMenpai, INT nPhase)
	{
		if(nMenpai < 0 || nMenpai > 8 || nPhase < 0 || nPhase > 2) return INVALID_ID;
		if(nMenpai == 0) return 814 + nPhase;				// 轻功1a 814, g01轻功1b 815, 轻功1c 816
		return 1107 + (nMenpai - 1) * 3 + nPhase;			// 轻功2a 1107 .. 轻功9c 1130
	}
}

VOID CObject_Character::CysLeapReset( VOID )
{
	m_bCysLeaping = FALSE;
    m_fvCysLeapAnchor = fVector2(0, 0);
    m_fCysLeapSpeed = m_fCysLeapLength = m_fCysLeapTargetLength = 0;
    m_fCysLeapStartHeight = m_fCysLeapTargetHeight = m_fCysLeapElapsed = 0;
    m_fCysLeapRate = 1;
    m_nCysLeapLoops = m_nCysLeapLoopsDone = m_nCysLeapFlags = 0;
	m_fvCysLeapFrom = fVector2(0.0f, 0.0f);
	m_fvCysLeapTo = fVector2(0.0f, 0.0f);
	m_uCysLeapStart = 0;
	m_uCysLeapDuration = 0;
	m_fCysLeapHeight = 0.0f;
	m_fCysLeapLift = 0.0f;
	m_nCysLeapPhase = -1;
	m_nCysLeapSkill = INVALID_ID;
	m_anCysLeapAction[0] = m_anCysLeapAction[1] = m_anCysLeapAction[2] = INVALID_ID;
}

FLOAT CObject_Character::CysLeapProgress( VOID ) const
{
	if(!m_bCysLeaping || m_uCysLeapDuration == 0) return -1.0f;
	const UINT uNow = CGameProcedure::s_pTimeSystem->GetTimeNow();
	const FLOAT t = CysQinggongLegacy() ? (FLOAT)(uNow - m_uCysLeapStart) / (FLOAT)m_uCysLeapDuration
        : m_fCysLeapElapsed * 1000.0f / (FLOAT)m_uCysLeapDuration;
	return t < 0.0f ? 0.0f : (t > 1.0f ? 1.0f : t);
}

INT CObject_Character::CysResolveLeapAction(INT nPhase)
{
	if(m_pRenderInterface == NULL) return INVALID_ID;
	BOOL bHide = FALSE;
	INT nAppointed = INVALID_ID;
	INT nMenpai = INVALID_ID;
	if(GetCharacterType() == CT_PLAYERMYSELF || GetCharacterType() == CT_PLAYEROTHER)
	{
		if(GetCharacterData()) nMenpai = GetCharacterData()->Get_MenPai();
	}
	const INT nOwn = MenpaiLeapAction(nMenpai, nPhase);
	if(nOwn != INVALID_ID && GetCharActionNameByActionSetID(nOwn, GetWeaponType(), &bHide, &nAppointed) != NULL) return nOwn;
	const INT nGeneric = kGenericLeap[nPhase];
	if(GetCharActionNameByActionSetID(nGeneric, GetWeaponType(), &bHide, &nAppointed) != NULL) return nGeneric;
	return INVALID_ID;
}

BOOL CObject_Character::CysStartLeap(INT idSkill, const fVector2& fvFrom, const fVector2& fvTo, INT nLogicCount, const fVector2& fvAnchor, INT nFlyFlags, FLOAT fWireSpeed)
{
    if(!CysQinggongLegacy()) return CysStartLeapModern(idSkill, fvFrom, fvTo, nLogicCount, fvAnchor, nFlyFlags, fWireSpeed);
	if(IsDie() || CharacterLogic_Get() == CHARACTER_LOGIC_DEAD) return FALSE;
	const FLOAT fDist = TDU_GetDist(fvFrom, fvTo);
	if(fDist < 0.05f)
	{
		TDU_Log("CYS-MOVE2 leap: obj %d skill %d zero distance, ignored", GetServerID(), idSkill);
		return FALSE;
	}

	// Stop whatever the logic was doing (a walk in progress would keep dragging the position).
	CleanupLogicCommandList();
	CharacterLogic_Stop(TRUE);
	if(GetbJumping()) { SetbJumping(FALSE); PhyEnable(FALSE); }

	UINT uDuration = kDefaultLeapMs;
	const SSkillData* pSkill = GetSkillDataMgr() ? GetSkillDataMgr()->GetSkillData((UINT)idSkill) : NULL;
	if(pSkill && pSkill->m_nSendTime > 0) uDuration = (UINT)pSkill->m_nSendTime;

	m_bCysLeaping = TRUE;
	m_fvCysLeapFrom = fvFrom;
	m_fvCysLeapTo = fvTo;
	m_uCysLeapStart = CGameProcedure::s_pTimeSystem->GetTimeNow();
	m_uCysLeapDuration = uDuration;
	m_fCysLeapHeight = fDist * kHeightPerUnit;
	if(m_fCysLeapHeight < kMinHeight) m_fCysLeapHeight = kMinHeight;
	if(m_fCysLeapHeight > kMaxHeight) m_fCysLeapHeight = kMaxHeight;
	m_fCysLeapLift = 0.0f;
	m_nCysLeapSkill = idSkill;
	for(INT i = 0; i < 3; ++i) m_anCysLeapAction[i] = CysResolveLeapAction(i);

	SetFaceDir(TDU_GetYAngle(fvFrom, fvTo));
	m_nCysLeapPhase = 0;
	if(m_anCysLeapAction[0] != INVALID_ID) ChangeAction(m_anCysLeapAction[0], 1.0f, FALSE);
	else if(m_anCysLeapAction[1] != INVALID_ID) { m_nCysLeapPhase = 1; ChangeAction(m_anCysLeapAction[1], 1.0f, TRUE); }

	TDU_Log("CYS-MOVE2 leap: obj %d%s skill %d start (%.1f,%.1f)->(%.1f,%.1f) dist=%.2f height=%.2f ms=%u actions=%d/%d/%d logic=%d",
		GetServerID(), (CObjectManager::GetMe() && CObjectManager::GetMe()->GetMySelf() == (CObject_PlayerMySelf*)this) ? " (self)" : "",
		idSkill, fvFrom.x, fvFrom.y, fvTo.x, fvTo.y, fDist, m_fCysLeapHeight, uDuration,
		m_anCysLeapAction[0], m_anCysLeapAction[1], m_anCysLeapAction[2], nLogicCount);
	return TRUE;
}

VOID CObject_Character::CysTickLeap( VOID )
{
    if(!CysQinggongLegacy()) { CysTickLeapModern(); return; }
	if(!m_bCysLeaping) return;
	const UINT uNow = CGameProcedure::s_pTimeSystem->GetTimeNow();
	FLOAT t = (m_uCysLeapDuration > 0) ? (FLOAT)(uNow - m_uCysLeapStart) / (FLOAT)m_uCysLeapDuration : 1.0f;
	if(t < 0.0f) t = 0.0f;

	if(t >= 1.0f)
	{
		// Landing: on the ground at the target, landing action once, then the normal idle animation.
		m_bCysLeaping = FALSE;
		m_fCysLeapLift = 0.0f;
		SetMapPosition(m_fvCysLeapTo);
		if(m_anCysLeapAction[2] != INVALID_ID) ChangeAction(m_anCysLeapAction[2], 1.0f, FALSE);
		else FreshAnimation();
		m_nCysLeapPhase = 2;
		TDU_Log("CYS-MOVE2 leap: obj %d landed at (%.1f,%.1f) after %u ms (pos now %.1f,%.1f,%.1f)", GetServerID(),
			m_fvCysLeapTo.x, m_fvCysLeapTo.y, uNow - m_uCysLeapStart, GetPosition().x, GetPosition().y, GetPosition().z);
		return;
	}

	const fVector2 fvPos(m_fvCysLeapFrom.x + (m_fvCysLeapTo.x - m_fvCysLeapFrom.x) * t,
						 m_fvCysLeapFrom.y + (m_fvCysLeapTo.y - m_fvCysLeapFrom.y) * t);
	m_fCysLeapLift = 4.0f * m_fCysLeapHeight * t * (1.0f - t);
	SetMapPosition(fvPos);

	if(m_nCysLeapPhase == 0 && (IsAnimationEnd() || t >= kTakeoffFraction))
	{
		m_nCysLeapPhase = 1;
		if(m_anCysLeapAction[1] != INVALID_ID) ChangeAction(m_anCysLeapAction[1], 1.0f, TRUE);
	}
}


// Q4-Q10: live GL/CY formulas and action lookup; no inferred KV or faction mapping.
FLOAT CObject_Character::CysLeapActionLength(INT action)
{
    if(!m_pRenderInterface || action == INVALID_ID) return 0;
    BOOL hide = FALSE;
    INT appointed = INVALID_ID;
    LPCSTR name = GetCharActionNameByActionSetID(action, GetWeaponType(), &hide, &appointed);
    if(!name) return 0;
    STRING value;
    STRING query = "CysAnimationLength:";
    query += name;
    m_pRenderInterface->Actor_GetObjectProperty(query.c_str(), value);
    const FLOAT length = (FLOAT)atof(value.c_str());
    return length > 0 ? length : 0;
}

BOOL CObject_Character::CysStartLeapModern(INT skill, const fVector2& from, const fVector2& to,
    INT logicCount, const fVector2& anchor, INT flags, FLOAT wireSpeed)
{
    if(IsDie() || CharacterLogic_Get() == CHARACTER_LOGIC_DEAD) return FALSE;
    CScene* scene = (CScene*)CWorldManager::GetMe()->GetActiveScene();
    if(!scene || !scene->IsValidPosition(from) || !scene->IsValidPosition(to)) return FALSE;
    CleanupLogicCommandList();
    CharacterLogic_Stop(TRUE);
    if(GetbJumping()) { SetbJumping(FALSE); PhyEnable(FALSE); }
    m_fvCysLeapFrom = from;
    m_fvCysLeapTo = to;
    m_fvCysLeapAnchor = anchor;
    m_fCysLeapLength = TDU_GetDist(from, anchor);
    m_fCysLeapTargetLength = TDU_GetDist(from, to);
    m_fCysLeapSpeed = CysQinggongCore::Speed(wireSpeed);
    const FLOAT duration = CysQinggongCore::Duration(m_fCysLeapLength, m_fCysLeapSpeed);
    m_uCysLeapDuration = (UINT)(duration * 1000.0f + 0.5f);
    m_uCysLeapStart = CGameProcedure::s_pTimeSystem->GetTimeNow();
    m_fCysLeapElapsed = 0;
    m_fCysLeapHeight = 0;
    m_fCysLeapLift = 0;
    m_nCysLeapSkill = skill;
    m_nCysLeapFlags = flags;
    m_nCysLeapLoopsDone = 0;
    m_nCysLeapPhase = 0;
    m_fCysLeapStartHeight = m_fCysLeapTargetHeight = GetPosition().y;
    scene->GetMapHeight(from, m_fCysLeapStartHeight);
    scene->GetMapHeight(to, m_fCysLeapTargetHeight);
    FLOAT lengths[3] = {0, 0, 0};
    for(INT phase = 0; phase < 3; ++phase)
    {
        m_anCysLeapAction[phase] = flags != 0 ? 26 + phase
            : (GetSkillDataMgr() ? GetSkillDataMgr()->GetRandAnim(skill, phase, TRUE) : INVALID_ID);
        lengths[phase] = CysLeapActionLength(m_anCysLeapAction[phase]);
    }
    m_nCysLeapLoops = CysQinggongCore::AirLoops(duration, lengths[0], lengths[1], lengths[2]);
    m_fCysLeapRate = (lengths[0] + m_nCysLeapLoops * lengths[1] + lengths[2]) / duration;
    if(m_fCysLeapRate <= 0) m_fCysLeapRate = 1;
    m_bCysLeaping = TRUE;
    SetFaceDir(flags == 0 ? TDU_GetYAngle(from, to) : TDU_GetYAngle(to, from));
    if(m_anCysLeapAction[0] != INVALID_ID)
        ChangeAction(m_anCysLeapAction[0], m_fCysLeapRate * GetLogicSpeed(), FALSE);
    TDU_Log("CYS-QINGGONG: START obj=%d legacy=0 skill=%d logic=%d from=(%.3f,%.3f) to=(%.3f,%.3f) anchor=(%.3f,%.3f) flags=%d wireSpeed=%.3f speed=%.3f duration=%.6f lengths=(%.3f,%.3f,%.3f) loops=%d rate=%.6f actions=%d/%d/%d",
        GetServerID(), skill, logicCount, from.x, from.y, to.x, to.y, anchor.x, anchor.y, flags, wireSpeed, m_fCysLeapSpeed, duration,
        lengths[0], lengths[1], lengths[2], m_nCysLeapLoops, m_fCysLeapRate, m_anCysLeapAction[0], m_anCysLeapAction[1], m_anCysLeapAction[2]);
    return TRUE;
}

BOOL CObject_Character::CysLeapAnimationEnd()
{
    if(CysQinggongLegacy() || !m_bCysLeaping) return FALSE;
    if(IsDie() || CharacterLogic_Get() == CHARACTER_LOGIC_DEAD)
    {
        m_bCysLeaping = FALSE;
        m_fCysLeapLift = 0;
        return FALSE;
    }
    if(m_nCysLeapPhase >= 2) {
        m_nCysLeapPhase = 3;
        if(CysQinggongLog()) TDU_Log("CYS-QINGGONG: landing-complete obj=%d time=%.6f", GetServerID(), m_fCysLeapElapsed);
        return TRUE;
    }
    if(m_nCysLeapLoopsDone < m_nCysLeapLoops)
    {
        ++m_nCysLeapLoopsDone;
        m_nCysLeapPhase = 1;
    }
    else m_nCysLeapPhase = 2;
    const INT action = m_anCysLeapAction[m_nCysLeapPhase];
    if(action != INVALID_ID) ChangeAction(action, m_fCysLeapRate * GetLogicSpeed(), FALSE);
    if(CysQinggongLog()) TDU_Log("CYS-QINGGONG: phase obj=%d phase=%d loop=%d/%d action=%d", GetServerID(), m_nCysLeapPhase, m_nCysLeapLoopsDone, m_nCysLeapLoops, action);
    return TRUE;
}

VOID CObject_Character::CysTickLeapModern()
{
    if(!m_bCysLeaping) return;
    if(IsDie() || CharacterLogic_Get() == CHARACTER_LOGIC_DEAD)
    {
        m_bCysLeaping = FALSE;
        m_fCysLeapLift = 0;
        return;
    }
    CScene* scene = (CScene*)CWorldManager::GetMe()->GetActiveScene();
    if(!scene) { CysLeapReset(); return; }
    const FLOAT dt = CGameProcedure::s_pTimeSystem->GetDeltaTime() * 0.001f * GetLogicSpeed();
    m_fCysLeapElapsed += dt;
    fVector2 pos(GetPosition().x, GetPosition().z);
    const FLOAT remaining = TDU_GetDist(pos, m_fvCysLeapTo);
    const FLOAT step = m_fCysLeapSpeed * dt;
    const bool arrived = remaining <= step || remaining <= 0.0001f;
    if(arrived) pos = m_fvCysLeapTo;
    else
    {
        pos.x += (m_fvCysLeapTo.x - pos.x) * step / remaining;
        pos.y += (m_fvCysLeapTo.y - pos.y) * step / remaining;
    }
    const fVector2 middle((m_fvCysLeapFrom.x + m_fvCysLeapAnchor.x) * 0.5f,
                         (m_fvCysLeapFrom.y + m_fvCysLeapAnchor.y) * 0.5f);
    // Keep the arc independent of the added terrain baseline compensation.
    if(arrived) m_fCysLeapHeight -= 15.0f * dt;
    else m_fCysLeapHeight = CysQinggongCore::Lift(m_fCysLeapLength, TDU_GetDist(pos, middle));
    if(m_fCysLeapHeight < 0) m_fCysLeapHeight = 0;
    FLOAT ground = m_fCysLeapStartHeight;
    scene->GetMapHeight(pos, ground);
    const FLOAT fraction = m_fCysLeapTargetLength > 0.0001f ? TDU_GetDist(m_fvCysLeapFrom, pos) / m_fCysLeapTargetLength : 1.0f;
    const FLOAT baseline = m_fCysLeapStartHeight + fraction * (m_fCysLeapTargetHeight - m_fCysLeapStartHeight);
    m_fCysLeapLift = m_fCysLeapHeight + (baseline > ground ? baseline - ground : 0);
    SetMapPosition(pos);
    if(CysQinggongLog()) TDU_Log("CYS-QINGGONG: sample obj=%d time=%.6f pos=(%.6f,%.6f) arc=%.6f lift=%.6f y=%.6f phase=%d", GetServerID(), m_fCysLeapElapsed, pos.x, pos.y, m_fCysLeapHeight, m_fCysLeapLift, GetPosition().y, m_nCysLeapPhase);
    // Keep input locked through the landing clip. Off-screen actors may have
    // no animation callbacks, so bound the wait using the authored duration.
    const bool animationDone = m_nCysLeapPhase == 3 || m_anCysLeapAction[2] == INVALID_ID ||
        m_fCysLeapElapsed >= m_uCysLeapDuration * 0.001f + 0.5f;
    if(arrived && m_fCysLeapHeight < 0.1f && animationDone)
    {
        m_bCysLeaping = FALSE;
        m_fCysLeapLift = 0;
        SetMapPosition(m_fvCysLeapTo);
        CharacterLogic_Stop(TRUE);
        CharacterLogic_Set(CHARACTER_LOGIC_IDLE);
        FreshAnimation();
        TDU_Log("CYS-QINGGONG: END obj=%d elapsed=%.6f to=(%.3f,%.3f)", GetServerID(), m_fCysLeapElapsed, pos.x, pos.y);
    }
}
