#pragma once
// CYS-REVIVE: scripted GUI turn that answers ONE question — can a real player free themselves from an impact whose
// StandardImpact row says 是否可以被手动取消 = 1, by right-clicking its buff icon, the way PlayerImpactFrame does
// (MouseRClick -> PlayerImpactFrame_ImageN_Click -> Player:DispelBuffByIndex -> CDataPool::BuffImpact_DispelByIndex)?
// The case that matters is 59901 地府束缚 (CanAction1/CanAction2/CanMove = 0, 总持续时间 = -1, 下线就消失否 = 0):
// its own flags block both automatic exits (开始动作 / 开始移动), so manual cancel is the only way out without a GM.
//
// Enabled by CYS_REVIVE_LIVE=1; otherwise Tick() returns true at once.
//   CYS_REVIVE_BUFF=N   StandardImpact Data_Index to cancel (default 59901)
//
// Every step logs "CYS revive-live:" and the turn ends with one VERDICT line. The move probes are the acceptance
// criterion: a full health bar proves nothing, a position delta does.
namespace CysReviveDriver
{
    bool Tick();
}
