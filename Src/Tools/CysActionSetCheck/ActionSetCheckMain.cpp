// CysActionSetCheck - offline checker of the client_GL action-set tables with Game.exe's parser
// (Src/Client/WXClient/Action/CysActionSetTable.cpp). CYS actionset agent, 2026-09-14. Keep this file ASCII.
//
//   CysActionSetCheck.exe --data <Data dir> [--report <file.tsv>] [--dump-set <id>]
//                         [--set <id> | --model <name.obj>] [--action <id>] [--slot <n>]
//
// --data      client Data folder (ConfigFolder/ActionSet/*.txt, ActionSetFile.txt, CharModelEx.txt); CY 3.71 binary
//             DBC tables (Assets/CanonicalCY) and client_GL text tables both load
// --report    TSV: one row per set (id, file name, models using it, actions, base actions 0/1/3/4/5/14/16/23/24/25
//             resolved in the first weapon slot and in the shared slot - 13 for the 16-slot CY lines, 9 for GL);
//             names are GBK bytes as in the data
// --dump-set  every action of one set with its line id, extras and the names of every slot
// --set/--model + --action [+ --slot]  resolve one lookup the way CObject_Character does
// Exit codes: 0 ok, 1 usage / file missing, 2 tables loaded with errors (dangling ids, bad numbers, not ready).
#include "CysActionSetTable.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <map>
#include <string>
#include <vector>

namespace
{
    bool readFile(const std::string& path, std::string& out)
    {
        FILE* f = std::fopen(path.c_str(), "rb");
        if (!f) return false;
        std::fseek(f, 0, SEEK_END);
        long n = std::ftell(f);
        std::fseek(f, 0, SEEK_SET);
        out.resize(n > 0 ? (size_t)n : 0);
        if (n > 0 && std::fread(&out[0], 1, (size_t)n, f) != (size_t)n) { std::fclose(f); return false; }
        std::fclose(f);
        return true;
    }

    // CYS-CY (cs2-world): the tables are read with CysActionSet::Table::ReadRows, which takes the CY 3.71 binary DBC
    // form as well as the client_GL text form (the local text splitter of this tool is gone).

    const int kBaseActions[] = { 0, 1, 3, 4, 5, 6, 7, 14, 16, 23, 24, 25 };
    const char* kBaseNames[] = { "idle", "idle_ex0", "walk", "run", "sit_down", "sit_idle", "sit_stand", "f_idle", "f_run", "be_hit", "die", "cadaver" };
}

int main(int argc, char** argv)
{
    std::string data, report;
    int dumpSet = -1, setId = -1, action = -1, slot = 0;
    std::string model;
    for (int i = 1; i < argc; ++i)
    {
        std::string a = argv[i];
        const char* v = (i + 1 < argc) ? argv[i + 1] : NULL;
        if (a == "--data" && v) { data = v; ++i; }
        else if (a == "--report" && v) { report = v; ++i; }
        else if (a == "--dump-set" && v) { dumpSet = std::atoi(v); ++i; }
        else if (a == "--set" && v) { setId = std::atoi(v); ++i; }
        else if (a == "--model" && v) { model = v; ++i; }
        else if (a == "--action" && v) { action = std::atoi(v); ++i; }
        else if (a == "--slot" && v) { slot = std::atoi(v); ++i; }
        else { std::fprintf(stderr, "CysActionSetCheck: unknown option %s\n", a.c_str()); return 1; }
    }
    if (data.empty()) { std::fprintf(stderr, "CysActionSetCheck: --data <Data dir> is required\n"); return 1; }

    const std::string cfg = data + "\\ConfigFolder\\";
    std::string fSet, fLine, fKv, fFile, fModel;
    const char* names[3] = { "ActionSet.txt", "ActionSetLine.txt", "ActionSetKV.txt" };
    std::string* bufs[3] = { &fSet, &fLine, &fKv };
    for (int i = 0; i < 3; ++i)
    {
        std::string path = cfg + "ActionSet\\" + names[i];
        if (!readFile(path, *bufs[i])) { std::fprintf(stderr, "CysActionSetCheck: cannot read %s\n", path.c_str()); return 1; }
    }
    if (!readFile(cfg + "ActionSetFile.txt", fFile)) { std::fprintf(stderr, "CysActionSetCheck: cannot read ActionSetFile.txt\n"); return 1; }
    const bool haveModels = readFile(cfg + "CharModelEx.txt", fModel);

    CysActionSet::Table table;
    bool ok = true;
    ok &= table.LoadActionSet(fSet.data(), fSet.size());
    ok &= table.LoadActionSetLine(fLine.data(), fLine.size());
    ok &= table.LoadActionSetKV(fKv.data(), fKv.size());
    table.Finish();
    const CysActionSet::Stats& st = table.GetStats();

    // ActionSetFile.txt: set id -> file name; CharModelEx.txt: model id -> (name, set id)
    std::map<int, std::string> setFiles;
    std::vector<std::vector<std::string> > rows;
    CysActionSet::Table::ReadRows(fFile.data(), fFile.size(), rows);
    for (size_t i = 0; i < rows.size(); ++i)
        if (rows[i].size() >= 2) setFiles[std::atoi(rows[i][0].c_str())] = rows[i][1];
    struct ModelRow { int id; std::string name; int set; };
    std::vector<ModelRow> models;
    if (haveModels)
    {
        CysActionSet::Table::ReadRows(fModel.data(), fModel.size(), rows);
        // CYS-CY: the action-set file id is column 20 of CY 3.71's CharModelEx (21 columns,
        // Registry/abi/dbc_struct_columns_cy.tsv m_nActionSetFileID) and column 9 in client_GL.
        size_t setColumn = 9;
        for (size_t i = 0; i < rows.size() && i < 16; ++i)
            if (rows[i].size() >= 21) { setColumn = 20; break; }
        std::printf("CharModelEx.txt: action-set column %d\n", (int)setColumn);
        for (size_t i = 0; i < rows.size(); ++i)
        {
            if (rows[i].size() <= setColumn) continue;
            ModelRow m;
            m.id = std::atoi(rows[i][0].c_str());
            m.name = rows[i][1];
            m.set = std::atoi(rows[i][setColumn].c_str());
            models.push_back(m);
        }
    }
    std::map<int, int> modelsPerSet;
    int modelsNoSet = 0, modelsBadSet = 0, modelsSetNoFile = 0;
    for (size_t i = 0; i < models.size(); ++i)
    {
        if (models[i].set < 0) { ++modelsNoSet; continue; }
        if (!table.HasSet(models[i].set)) ++modelsBadSet;
        if (setFiles.find(models[i].set) == setFiles.end()) ++modelsSetNoFile;
        ++modelsPerSet[models[i].set];
    }
    int filesWithoutRows = 0;
    for (std::map<int, std::string>::const_iterator it = setFiles.begin(); it != setFiles.end(); ++it)
        if (!table.HasSet(it->first)) ++filesWithoutRows;

    std::printf("CysActionSetCheck: data %s\n", data.c_str());
    std::printf("tables %s: %d sets, %d actions, %d lines x %d slots, %d names (%d empty)\n",
        table.IsReady() ? "loaded" : "NOT loaded", st.nSets, st.nActions, st.nLines, st.nSlots, st.nNames, st.nEmptyNames);
    std::printf("row-id mismatch %d, short rows %d, extra cells %d, bad numbers %d, dangling lines %d, dangling names %d, duplicate actions %d\n",
        st.nLineIdMismatch, st.nShortRows, st.nExtraCells, st.nBadNumbers, st.nDanglingLines, st.nDanglingNames, st.nDuplicateActions);
    std::printf("ActionSetFile.txt: %d files, %d without rows in ActionSet.txt\n", (int)setFiles.size(), filesWithoutRows);
    if (haveModels)
        std::printf("CharModelEx.txt: %d models, %d with set -1, %d whose set has no rows, %d whose set is not in ActionSetFile.txt\n",
            (int)models.size(), modelsNoSet, modelsBadSet, modelsSetNoFile);
    for (size_t i = 0; i < st.messages.size(); ++i)
        std::printf("note: %s\n", st.messages[i].c_str());

    if (!model.empty())
    {
        for (size_t i = 0; i < models.size(); ++i)
            if (models[i].name == model) { setId = models[i].set; std::printf("model %s -> CharModelEx %d -> set %d\n", model.c_str(), models[i].id, setId); break; }
        if (setId < 0) { std::fprintf(stderr, "CysActionSetCheck: model %s not found in CharModelEx.txt\n", model.c_str()); return 1; }
    }
    // CYS-CY: the shared slot of monsters/NPCs/pets/riders: 13 in CY (16-slot lines), 9 in the GL tables.
    const int sharedSlot = table.GetSlotCount() >= 16 ? (int)CysActionSet::SLOT_SHARED : 9;
    if (setId >= 0 && action >= 0)
    {
        bool hide = false; int appointed = -1;
        const char* name = table.Resolve(setId, action, slot, &hide, &appointed);
        int line = table.FindLine(setId, action);
        std::printf("resolve set %d (%s) action %d slot %d -> line %d, name %s%s%s, hide %d, appointed %d, extraC %d\n",
            setId, setFiles.count(setId) ? setFiles[setId].c_str() : "?", action, slot, line,
            name ? "\"" : "", name ? name : "NULL", name ? "\"" : "", (int)hide, appointed, table.GetExtraC(line));
        if (name)
        {
            std::printf("name bytes:");
            for (const char* p = name; *p; ++p) std::printf(" %02x", (unsigned char)*p);
            std::printf("\n");
        }
    }
    if (dumpSet >= 0)
    {
        const std::vector<std::pair<int, int> >* acts = table.GetSetActions(dumpSet);
        std::printf("set %d (%s): %d actions\n", dumpSet, setFiles.count(dumpSet) ? setFiles[dumpSet].c_str() : "?", acts ? (int)acts->size() : 0);
        if (acts)
        {
            for (size_t k = 0; k < acts->size(); ++k)
            {
                int line = (*acts)[k].second;
                std::printf("%d\t%d\t%d\t%d\t%d", (*acts)[k].first, line, (int)table.GetHideWeapon(line), table.GetAppointedWeapon(line), table.GetExtraC(line));
                for (int s = 0; s < table.GetSlotCount(); ++s)
                {
                    const char* n = table.GetLineName(line, s);
                    std::printf("\t%s", n ? n : "<dangling>");
                }
                std::printf("\n");
            }
        }
    }
    if (!report.empty())
    {
        FILE* f = std::fopen(report.c_str(), "wb");
        if (!f) { std::fprintf(stderr, "CysActionSetCheck: cannot write %s\n", report.c_str()); return 1; }
        std::fprintf(f, "# CysActionSetCheck report (names are GBK bytes). tables=%s sets=%d actions=%d lines=%d slots=%d names=%d\n",
            table.IsReady() ? "ok" : "error", st.nSets, st.nActions, st.nLines, st.nSlots, st.nNames);
        std::fprintf(f, "set\tfile\tmodels\tactions\tdistinct_lines");
        for (size_t b = 0; b < sizeof(kBaseActions) / sizeof(kBaseActions[0]); ++b)
            std::fprintf(f, "\t%s(%d)/s0\t%s(%d)/s9", kBaseNames[b], kBaseActions[b], kBaseNames[b], kBaseActions[b]);
        std::fprintf(f, "\n");
        std::vector<int> ids;
        table.GetSetIDs(ids);
        for (size_t i = 0; i < ids.size(); ++i)
        {
            const std::vector<std::pair<int, int> >* acts = table.GetSetActions(ids[i]);
            std::map<int, int> lines;
            for (size_t k = 0; acts && k < acts->size(); ++k) ++lines[(*acts)[k].second];
            std::fprintf(f, "%d\t%s\t%d\t%d\t%d", ids[i], setFiles.count(ids[i]) ? setFiles[ids[i]].c_str() : "",
                modelsPerSet.count(ids[i]) ? modelsPerSet[ids[i]] : 0, acts ? (int)acts->size() : 0, (int)lines.size());
            for (size_t b = 0; b < sizeof(kBaseActions) / sizeof(kBaseActions[0]); ++b)
            {
                const char* n0 = table.Resolve(ids[i], kBaseActions[b], 0, NULL, NULL);
                const char* n9 = table.Resolve(ids[i], kBaseActions[b], sharedSlot, NULL, NULL);
                std::fprintf(f, "\t%s\t%s", n0 ? n0 : "-", n9 ? n9 : "-");
            }
            std::fprintf(f, "\n");
        }
        std::fclose(f);
        std::printf("report written: %s\n", report.c_str());
    }
    const bool hardError = !table.IsReady() || st.nDanglingLines || st.nDanglingNames || st.nBadNumbers;
    std::printf("result: %s\n", hardError ? "ERROR" : "OK");
    return hardError ? 2 : 0;
}
