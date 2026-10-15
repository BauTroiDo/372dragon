# CYS component: CysActionSetCheck.exe (Src/Tools/CysActionSetCheck) - offline checker of the client_GL action-set
# tables (ConfigFolder/ActionSet/ActionSet.txt, ActionSetLine.txt, ActionSetKV.txt + ActionSetFile.txt) with the
# same parser Game.exe uses (Src/Client/WXClient/Action/CysActionSetTable.cpp). No engine dependency.
#   bin\CysActionSetCheck.exe --data <Data dir> [--report <file.tsv>] [--set <id> | --model <name.obj>]
#                             [--action <id>] [--slot <n>] [--dump-set <id>]
# Spec: Docs/specs/game/actionset_vi.md. Owner: actionset agent (2026-09-14).
set(_cys_asc "${CYS_SRC}/Tools/CysActionSetCheck")
add_executable(CysActionSetCheck
    "${_cys_asc}/ActionSetCheckMain.cpp"
    "${CYS_SRC}/Client/WXClient/Action/CysActionSetTable.cpp"
    "${CYS_SRC}/Client/WXClient/Action/CysActionSetTable.h")
target_include_directories(CysActionSetCheck PRIVATE "${CYS_SRC}/Client/WXClient/Action")
target_compile_definitions(CysActionSetCheck PRIVATE _CONSOLE NOMINMAX WIN32_LEAN_AND_MEAN _CRT_SECURE_NO_WARNINGS)
