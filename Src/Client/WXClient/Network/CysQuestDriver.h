#pragma once
// CYS-QUEST: scripted GUI turn of the NPC dialogue / mission module inside a live world session (CysGlLoginSmoke mode
// World, after the camera/walk script and the inventory driver). Enabled by CYS_QUEST_LIVE=1; otherwise Tick() returns
// true at once. Steps (each optional through the environment):
//   CYS_QUEST_NPC=X,Z        NPC to talk to (default 160,158 Trieu Thien Su, Dai Ly)
//   CYS_QUEST_COMPLETE=ID    mission script to hand in there (option type 2 -> demand/continue -> reward -> submit)
//   CYS_QUEST_ACCEPT=ID      mission script to accept there (option type 1 -> mission info -> accept -> tracking frame)
//   CYS_QUEST_TRAVEL=X,Z,IDX station NPC and option index of a transfer (253,121,1001 = Dai Ly -> Lac Duong)
//   CYS_QUEST_RETURN=X,Z,IDX station NPC and option of the way back in the new scene (235,322,1010 = Lac Duong -> Dai Ly)
// The CY windows are driven the way their Lua does it (CUIDataPool::SendSelectEvent / SendAcceptEvent /
// SendContinueEvent / SendCompleteEvent = QuestFrameOptionClicked / QuestFrameAcceptClicked / QuestFrameMissionContinue
// / QuestFrameMissionComplete). Every step logs "CYS quest-live:" and takes a cys-live-*-quest-* PNG.
namespace CysQuestDriver
{
    bool Tick();
}
