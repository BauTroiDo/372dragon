// CysUiViewer - per-layout records, CEGUI log census, PNG writer and the final reports.
// CYS: new tool (2026-09-12). Keep this file ASCII.
#pragma once

#include <string>
#include <vector>

namespace cysui
{
    // 8-bit RGB PNG (zlib; DevIL has no PNG in the x64 build).
    bool writePng(const std::string& path, unsigned w, unsigned h, const std::vector<unsigned char>& rgb);

    struct LayoutRecord
    {
        int index = -1;
        std::string status;                  // ok | errors | load-failed | crash | hang | render-failed
        std::string file;                    // layout path relative to the UI root, '/' separators
        std::string window;                  // window name from InterfaceEx.txt
        int windows = 0;                     // windows created by the layout
        int errors = 0;                      // CEGUI (Error) lines while loading + rendering it
        double coverage = -1.0;              // share of pixels different from the background (-1: no capture)
        double ms = 0.0;
        int placeholders = 0;                // textures replaced by the magenta placeholder
        std::string png;
        std::string failure;                 // load/render failure text (UTF-8)
        std::vector<std::string> errorLines; // the CEGUI (Error) messages (UTF-8)
    };

    // records.tsv: one line per layout (tab separated, error lines joined with 0x1F).
    bool appendRecord(const std::string& path, const LayoutRecord& r);
    bool readRecords(const std::string& path, std::vector<LayoutRecord>& out); // last record per index, sorted

    unsigned long long fileSize(const std::string& path);
    // "(Error)" messages written to a CEGUI log after byte offset 'from' (timestamp and tag removed).
    std::vector<std::string> readLogErrors(const std::string& logPath, unsigned long long from,
                                           unsigned long long* end);

    struct ReportInput
    {
        std::string outDir;
        std::string commandLine;             // UTF-8
        std::string baselineLog;             // CEGUI.log of the modern client (optional)
        std::vector<std::string> runDirs;    // run_000 ... written by the workers
        int width = 0;
        int height = 0;
        double seconds = 0.0;
    };

    // Writes layouts.csv, errors.txt, failures.txt, causes.txt and summary.txt into in.outDir, copies the first
    // worker's UISystem.log to CEGUI.log and returns the summary text.
    std::string writeReports(const ReportInput& in, std::vector<LayoutRecord>& records);
}
