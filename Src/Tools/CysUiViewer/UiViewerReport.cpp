// CysUiViewer - records, CEGUI log census, PNG writer and reports. CYS: new tool (2026-09-12). Keep this file ASCII.
#include "UiViewerReport.h"
#include "UiViewerOptions.h"

#include <windows.h>
#include <zlib.h>

#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <map>
#include <set>
#include <sstream>

namespace cysui
{
    namespace
    {
        const char kSep = '\x1F';

        std::string clean(std::string s)
        {
            for (size_t i = 0; i < s.size(); ++i)
                if (s[i] == '\t' || s[i] == '\r' || s[i] == '\n' || s[i] == kSep)
                    s[i] = ' ';
            return s;
        }

        std::vector<std::string> split(const std::string& s, char sep)
        {
            std::vector<std::string> out;
            size_t p = 0;
            while (true)
            {
                size_t q = s.find(sep, p);
                out.push_back(s.substr(p, q == std::string::npos ? std::string::npos : q - p));
                if (q == std::string::npos)
                    break;
                p = q + 1;
            }
            return out;
        }

        bool readFile(const std::string& path, std::string& data)
        {
            HANDLE h = CreateFileA(path.c_str(), GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
                                   NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
            if (h == INVALID_HANDLE_VALUE)
                return false;
            LARGE_INTEGER size;
            GetFileSizeEx(h, &size);
            data.resize((size_t)size.QuadPart);
            DWORD got = 0;
            BOOL ok = data.empty() || ReadFile(h, &data[0], (DWORD)data.size(), &got, NULL);
            CloseHandle(h);
            data.resize(got);
            return ok != FALSE;
        }

        bool writeText(const std::string& path, const std::string& text)
        {
            FILE* f = std::fopen(path.c_str(), "wb");
            if (!f)
                return false;
            std::fputs("\xEF\xBB\xBF", f);
            std::fwrite(text.data(), 1, text.size(), f);
            std::fclose(f);
            return true;
        }

        std::vector<std::string> lines(const std::string& data)
        {
            std::vector<std::string> out;
            size_t p = (data.size() >= 3 && (unsigned char)data[0] == 0xEF) ? 3 : 0;
            while (p < data.size())
            {
                size_t e = data.find('\n', p);
                if (e == std::string::npos)
                    e = data.size();
                size_t end = e;
                if (end > p && data[end - 1] == '\r')
                    --end;
                out.push_back(data.substr(p, end - p));
                p = e + 1;
            }
            return out;
        }

        std::string csv(const std::string& s)
        {
            std::string o = "\"";
            for (size_t i = 0; i < s.size(); ++i)
            {
                if (s[i] == '"')
                    o += "\"\"";
                else if (s[i] == '\r' || s[i] == '\n')
                    o += ' ';
                else
                    o += s[i];
            }
            return o + "\"";
        }

        std::vector<std::string> quoted(const std::string& m)
        {
            std::vector<std::string> q;
            size_t p = 0;
            while ((p = m.find('\'', p)) != std::string::npos)
            {
                size_t e = m.find('\'', p + 1);
                if (e == std::string::npos)
                    break;
                q.push_back(m.substr(p + 1, e - p - 1));
                p = e + 1;
            }
            return q;
        }

        std::string stripException(const std::string& m)
        {
            return m.compare(0, 11, "Exception: ") == 0 ? m.substr(11) : m;
        }

        std::string normalise(const std::string& m)
        {
            std::string s = stripException(m), o;
            bool in = false;
            for (size_t i = 0; i < s.size(); ++i)
            {
                if (s[i] == '\'')
                {
                    if (!in) o += "'X'";
                    in = !in;
                }
                else if (!in)
                    o += s[i];
            }
            return o.size() > 200 ? o.substr(0, 200) : o;
        }

        // Category ("missing property", ...) and the key inside it (e.g. "Falagard/ActionButton.Image").
        std::string classify(const std::string& raw, std::string& key)
        {
            const std::string m = stripException(raw);
            std::vector<std::string> q = quoted(m);
            if (m.find("There is no Property named") != std::string::npos && !q.empty())
            {
                size_t c = m.find("Class:");
                key = (c != std::string::npos ? m.substr(c + 6) : std::string("?")) + "." + q[0];
                return "missing property";
            }
            if (m.find("The Image named") != std::string::npos && q.size() >= 2)
            {
                key = q[1] + "/" + q[0];
                return "missing image";
            }
            if (m.find("No Imageset named") != std::string::npos && !q.empty())
            {
                key = q[0];
                return "missing imageset";
            }
            if (m.find("WidgetLook") != std::string::npos && m.find("does not exist") != std::string::npos && !q.empty())
            {
                key = q[0];
                return "missing look";
            }
            if (m.find("WindowFactory") != std::string::npos && m.find("not registered") != std::string::npos && !q.empty())
            {
                key = q[0];
                return "unknown window type";
            }
            if (m.find("Font") != std::string::npos && m.find("does not exist") != std::string::npos && !q.empty())
            {
                key = q[0];
                return "missing font";
            }
            if (m.find("Texture object from file") != std::string::npos && !q.empty())
            {
                key = q[0];
                return "texture load failed";
            }
            if (m.find("already exists within the system") != std::string::npos && !q.empty())
            {
                key = q[0];
                return "duplicate name";
            }
            if (m.find("XML Parsing error") != std::string::npos || m.find("XML parse") != std::string::npos)
            {
                key = normalise(m);
                return "XML error";
            }
            key = normalise(m);
            return "other";
        }

        struct Tally
        {
            int count = 0;
            std::set<std::string> examples; // layouts
            void add(const std::string& ex)
            {
                ++count;
                if (examples.size() < 3 && !ex.empty())
                    examples.insert(ex);
            }
        };

        std::string joinExamples(const Tally& t)
        {
            std::string o;
            for (std::set<std::string>::const_iterator it = t.examples.begin(); it != t.examples.end(); ++it)
                o += (o.empty() ? "" : ", ") + *it;
            return o;
        }

        // map -> lines sorted by count (descending)
        std::string topList(const std::map<std::string, Tally>& m, size_t limit, const char* indent)
        {
            std::vector<std::pair<int, std::string> > v;
            for (std::map<std::string, Tally>::const_iterator it = m.begin(); it != m.end(); ++it)
                v.push_back(std::make_pair(-it->second.count, it->first));
            std::sort(v.begin(), v.end());
            std::ostringstream o;
            for (size_t i = 0; i < v.size() && i < limit; ++i)
            {
                const Tally& t = m.find(v[i].second)->second;
                o << indent << t.count << "  " << v[i].second;
                if (!t.examples.empty())
                    o << "   [" << joinExamples(t) << "]";
                o << "\n";
            }
            if (v.size() > limit)
                o << indent << "... " << (v.size() - limit) << " more (see causes.txt)\n";
            return o.str();
        }

        int countLogErrors(const std::string& path)
        {
            unsigned long long end = 0;
            return (int)readLogErrors(path, 0, &end).size();
        }
    }

    // ------------------------------------------------------------------ PNG
    static void pngChunk(FILE* f, const char* type, const unsigned char* data, size_t len)
    {
        unsigned char be[4] = { (unsigned char)(len >> 24), (unsigned char)(len >> 16), (unsigned char)(len >> 8),
                                (unsigned char)len };
        std::fwrite(be, 1, 4, f);
        std::fwrite(type, 1, 4, f);
        if (len)
            std::fwrite(data, 1, len, f);
        uLong crc = crc32(0L, Z_NULL, 0);
        crc = crc32(crc, (const Bytef*)type, 4);
        if (len)
            crc = crc32(crc, data, (uInt)len);
        unsigned char c[4] = { (unsigned char)(crc >> 24), (unsigned char)(crc >> 16), (unsigned char)(crc >> 8),
                               (unsigned char)crc };
        std::fwrite(c, 1, 4, f);
    }

    bool writePng(const std::string& path, unsigned w, unsigned h, const std::vector<unsigned char>& rgb)
    {
        if (!w || !h || rgb.size() < (size_t)w * h * 3)
            return false;
        std::vector<unsigned char> raw;
        raw.reserve((size_t)h * (w * 3 + 1));
        for (unsigned y = 0; y < h; ++y)
        {
            raw.push_back(0);
            raw.insert(raw.end(), rgb.begin() + (size_t)y * w * 3, rgb.begin() + (size_t)(y + 1) * w * 3);
        }
        uLongf clen = compressBound((uLong)raw.size());
        std::vector<unsigned char> comp(clen);
        if (compress2(&comp[0], &clen, &raw[0], (uLong)raw.size(), 6) != Z_OK)
            return false;
        makeDirs(parentDir(path));
        FILE* f = std::fopen(path.c_str(), "wb");
        if (!f)
            return false;
        static const unsigned char sig[8] = { 137, 80, 78, 71, 13, 10, 26, 10 };
        std::fwrite(sig, 1, 8, f);
        unsigned char ihdr[13] = { (unsigned char)(w >> 24), (unsigned char)(w >> 16), (unsigned char)(w >> 8),
                                   (unsigned char)w, (unsigned char)(h >> 24), (unsigned char)(h >> 16),
                                   (unsigned char)(h >> 8), (unsigned char)h, 8, 2, 0, 0, 0 };
        pngChunk(f, "IHDR", ihdr, 13);
        pngChunk(f, "IDAT", &comp[0], clen);
        pngChunk(f, "IEND", NULL, 0);
        bool ok = std::ferror(f) == 0;
        std::fclose(f);
        return ok;
    }

    // ------------------------------------------------------------------ records
    bool appendRecord(const std::string& path, const LayoutRecord& r)
    {
        char num[160];
        std::sprintf(num, "%d\t%d\t%.5f\t%.1f\t%d", r.windows, r.errors, r.coverage, r.ms, r.placeholders);
        std::string errs;
        for (size_t i = 0; i < r.errorLines.size(); ++i)
            errs += (i ? std::string(1, kSep) : std::string()) + clean(r.errorLines[i]);
        std::string line = std::to_string(r.index) + "\t" + clean(r.status) + "\t" + clean(r.file) + "\t" +
                           clean(r.window) + "\t" + num + "\t" + clean(r.png) + "\t" + clean(r.failure) + "\t" + errs +
                           "\n";
        FILE* f = std::fopen(path.c_str(), "ab");
        if (!f)
            return false;
        std::fwrite(line.data(), 1, line.size(), f);
        std::fclose(f);
        return true;
    }

    bool readRecords(const std::string& path, std::vector<LayoutRecord>& out)
    {
        std::string data;
        if (!readFile(path, data))
            return false;
        std::map<int, LayoutRecord> byIndex;
        std::vector<std::string> ls = lines(data);
        for (size_t i = 0; i < ls.size(); ++i)
        {
            std::vector<std::string> c = split(ls[i], '\t');
            if (c.size() < 12)
                continue;
            LayoutRecord r;
            r.index = std::atoi(c[0].c_str());
            r.status = c[1];
            r.file = c[2];
            r.window = c[3];
            r.windows = std::atoi(c[4].c_str());
            r.errors = std::atoi(c[5].c_str());
            r.coverage = std::atof(c[6].c_str());
            r.ms = std::atof(c[7].c_str());
            r.placeholders = std::atoi(c[8].c_str());
            r.png = c[9];
            r.failure = c[10];
            if (!c[11].empty())
                r.errorLines = split(c[11], kSep);
            byIndex[r.index] = r;
        }
        for (std::map<int, LayoutRecord>::iterator it = byIndex.begin(); it != byIndex.end(); ++it)
            out.push_back(it->second);
        return true;
    }

    // ------------------------------------------------------------------ CEGUI log
    unsigned long long fileSize(const std::string& path)
    {
        WIN32_FILE_ATTRIBUTE_DATA d;
        if (!GetFileAttributesExA(path.c_str(), GetFileExInfoStandard, &d))
            return 0;
        return ((unsigned long long)d.nFileSizeHigh << 32) | d.nFileSizeLow;
    }

    std::vector<std::string> readLogErrors(const std::string& logPath, unsigned long long from, unsigned long long* end)
    {
        std::vector<std::string> out;
        std::string data;
        if (!readFile(logPath, data))
        {
            if (end)
                *end = from;
            return out;
        }
        if (end)
            *end = data.size();
        if (from >= data.size())
            return out;
        std::vector<std::string> ls = lines(data.substr((size_t)from));
        for (size_t i = 0; i < ls.size(); ++i)
        {
            size_t p = ls[i].find("(Error)");
            if (p == std::string::npos)
                continue;
            std::string m = ls[i].substr(p + 7);
            size_t b = m.find_first_not_of(" \t");
            out.push_back(b == std::string::npos ? std::string() : m.substr(b));
        }
        return out;
    }

    // ------------------------------------------------------------------ reports
    std::string writeReports(const ReportInput& in, std::vector<LayoutRecord>& recs)
    {
        std::map<std::string, int> byStatus;
        int blank = 0, totalWindows = 0, totalErrors = 0, placeholders = 0, captured = 0;
        double totalMs = 0;
        std::map<std::string, Tally> causes, failures;
        std::map<std::string, std::map<std::string, Tally> > categories;
        std::set<std::string> viewerMessages;
        for (size_t i = 0; i < recs.size(); ++i)
        {
            const LayoutRecord& r = recs[i];
            byStatus[r.status]++;
            totalWindows += r.windows;
            totalErrors += r.errors;
            totalMs += r.ms;
            placeholders += r.placeholders;
            if (r.coverage >= 0)
                ++captured;
            if (r.coverage >= 0 && r.coverage < 0.0005 && (r.status == "ok" || r.status == "errors"))
                ++blank;
            if (!r.failure.empty())
                failures[normalise(r.failure)].add(r.file);
            std::set<std::string> seen; // count each normalised cause once per layout for the example list
            for (size_t e = 0; e < r.errorLines.size(); ++e)
            {
                const std::string& m = r.errorLines[e];
                viewerMessages.insert(m);
                std::string key, cat = classify(m, key);
                causes[cat + ": " + normalise(m)].add(r.file);
                categories[cat][key].add(r.file);
                seen.insert(cat);
            }
        }

        // scheme phase (first worker)
        std::string schemeReport, schemeErrorsText;
        std::vector<std::string> schemeErrors;
        std::map<std::string, Tally> textures, dictMissing, markup;
        int logErrorsTotal = 0;
        for (size_t i = 0; i < in.runDirs.size(); ++i)
        {
            std::string data;
            if (i == 0 && readFile(joinPath(in.runDirs[i], "scheme_report.txt"), data))
                schemeReport = data.size() >= 3 && (unsigned char)data[0] == 0xEF ? data.substr(3) : data;
            if (i == 0 && readFile(joinPath(in.runDirs[i], "scheme_errors.txt"), data))
            {
                schemeErrors = lines(data);
                for (size_t e = 0; e < schemeErrors.size(); ++e)
                {
                    viewerMessages.insert(schemeErrors[e]);
                    std::string key, cat = classify(schemeErrors[e], key);
                    categories[cat][key].add("(scheme)");
                }
            }
            if (readFile(joinPath(in.runDirs[i], "textures.txt"), data))
            {
                std::vector<std::string> ls = lines(data);
                for (size_t k = 0; k < ls.size(); ++k)
                {
                    std::vector<std::string> c = split(ls[k], '\t');
                    if (c.size() >= 2)
                        textures[c[0] + " " + (c.size() >= 3 ? c[1] : std::string())].add(c.back());
                }
            }
            if (readFile(joinPath(in.runDirs[i], "dict_missing.txt"), data))
            {
                std::vector<std::string> ls = lines(data);
                for (size_t k = 0; k < ls.size(); ++k)
                {
                    std::vector<std::string> c = split(ls[k], '\t');
                    if (c.size() >= 2)
                        dictMissing[c[0]].count += std::atoi(c[1].c_str());
                }
            }
            if (readFile(joinPath(in.runDirs[i], "markup.txt"), data))
            {
                std::vector<std::string> ls = lines(data);
                for (size_t k = 0; k < ls.size(); ++k)
                {
                    std::vector<std::string> c = split(ls[k], '\t');
                    if (c.size() >= 2)
                        markup[c[0]].count += std::atoi(c[1].c_str());
                }
            }
            logErrorsTotal += countLogErrors(joinPath(in.runDirs[i], "UISystem.log"));
        }
        if (!in.runDirs.empty())
            CopyFileA(joinPath(in.runDirs[0], "UISystem.log").c_str(), joinPath(in.outDir, "CEGUI.log").c_str(), FALSE);

        // baseline comparison (exact messages)
        std::vector<std::string> base;
        if (!in.baselineLog.empty())
        {
            unsigned long long end = 0;
            base = readLogErrors(in.baselineLog, 0, &end);
        }
        std::set<std::string> baseSet(base.begin(), base.end());
        int reproduced = 0;
        std::vector<std::string> notReproduced, newMessages;
        for (std::set<std::string>::const_iterator it = baseSet.begin(); it != baseSet.end(); ++it)
        {
            if (viewerMessages.count(*it))
                ++reproduced;
            else
                notReproduced.push_back(*it);
        }
        for (std::set<std::string>::const_iterator it = viewerMessages.begin(); it != viewerMessages.end(); ++it)
            if (!baseSet.count(*it))
                newMessages.push_back(*it);

        // ---- layouts.csv / errors.txt / failures.txt
        std::ostringstream csvOut, errOut, failOut;
        csvOut << "index,layout,window,status,windows,errors,coverage,ms,placeholders,png,failure,first_error\n";
        for (size_t i = 0; i < recs.size(); ++i)
        {
            const LayoutRecord& r = recs[i];
            char num[128];
            std::sprintf(num, "%d,%d,%.5f,%.0f,%d", r.windows, r.errors, r.coverage, r.ms, r.placeholders);
            csvOut << r.index << "," << csv(r.file) << "," << csv(r.window) << "," << r.status << "," << num << ","
                   << csv(r.png) << "," << csv(r.failure) << ","
                   << csv(r.errorLines.empty() ? std::string() : r.errorLines[0]) << "\n";
            if (!r.errorLines.empty() || !r.failure.empty())
            {
                errOut << "== [" << r.index << "] " << r.file << " (" << r.window << ") " << r.status
                       << " errors=" << r.errors << "\n";
                if (!r.failure.empty())
                    errOut << "   FAILURE: " << r.failure << "\n";
                for (size_t e = 0; e < r.errorLines.size(); ++e)
                    errOut << "   " << r.errorLines[e] << "\n";
            }
            if (r.status != "ok" && r.status != "errors")
                failOut << r.status << "\t" << r.file << "\t" << r.window << "\t" << r.failure << "\n";
        }
        writeText(joinPath(in.outDir, "layouts.csv"), csvOut.str());
        writeText(joinPath(in.outDir, "errors.txt"), errOut.str());
        writeText(joinPath(in.outDir, "failures.txt"), failOut.str());

        // ---- causes.txt (complete lists)
        std::ostringstream c;
        c << "All CEGUI error causes (normalised; count  cause  [example layouts])\n";
        c << topList(causes, 100000, "  ");
        for (std::map<std::string, std::map<std::string, Tally> >::const_iterator it = categories.begin();
             it != categories.end(); ++it)
        {
            c << "\n== " << it->first << " (" << it->second.size() << " distinct)\n";
            c << topList(it->second, 100000, "  ");
        }
        c << "\n== load failures\n" << topList(failures, 100000, "  ");
        c << "\n== baseline messages not reproduced (" << notReproduced.size() << ")\n";
        for (size_t i = 0; i < notReproduced.size(); ++i)
            c << "  " << notReproduced[i] << "\n";
        c << "\n== messages not in the baseline (" << newMessages.size() << ")\n";
        for (size_t i = 0; i < newMessages.size(); ++i)
            c << "  " << newMessages[i] << "\n";
        writeText(joinPath(in.outDir, "causes.txt"), c.str());

        // ---- summary.txt
        std::ostringstream s;
        const int total = (int)recs.size();
        const int ok = byStatus["ok"], withErrors = byStatus["errors"];
        s << "CysUiViewer summary - " << nowStamp() << "\n";
        s << "command: " << in.commandLine << "\n";
        s << "size " << in.width << "x" << in.height << ", " << total << " layouts, " << (int)in.seconds << " s\n\n";
        if (!schemeReport.empty())
            s << schemeReport << "\n";
        s << "== layouts\n";
        s << "  rendered (loaded + captured): " << (ok + withErrors) << " / " << total << "\n";
        s << "    clean (no CEGUI error):     " << ok << "\n";
        s << "    with CEGUI errors:          " << withErrors << "\n";
        for (std::map<std::string, int>::const_iterator it = byStatus.begin(); it != byStatus.end(); ++it)
            if (it->first != "ok" && it->first != "errors")
                s << "  " << it->first << ": " << it->second << "\n";
        s << "  blank captures (<0.05% pixels differ from the background): " << blank << "\n";
        s << "  windows created: " << totalWindows << "; layout CEGUI errors: " << totalErrors
          << "; texture placeholders: " << placeholders << "; avg " << (total ? (int)(totalMs / total) : 0)
          << " ms/layout\n\n";
        s << "== CEGUI log\n";
        s << "  (Error) lines in the worker logs: " << logErrorsTotal << " (scheme phase: " << schemeErrors.size()
          << ", layouts: " << totalErrors << ")\n";
        if (!in.baselineLog.empty())
        {
            s << "  baseline " << in.baselineLog << ": " << base.size() << " (Error) lines, " << baseSet.size()
              << " distinct (the modern client, startup + opened windows; Docs/08 6.1 quotes 67-68)\n";
            s << "  baseline messages reproduced here: " << reproduced << " / " << baseSet.size()
              << "; distinct messages not in the baseline: " << newMessages.size() << "\n";
        }
        s << "\n== load failures (normalised)\n" << topList(failures, 25, "  ");
        s << "\n== top CEGUI error causes (normalised)\n" << topList(causes, 25, "  ");
        static const char* const cats[] = { "unknown window type", "missing look", "missing property", "missing image",
                                            "missing imageset", "missing font", "texture load failed", "duplicate name",
                                            "XML error", "other" };
        for (size_t k = 0; k < sizeof(cats) / sizeof(cats[0]); ++k)
        {
            std::map<std::string, std::map<std::string, Tally> >::const_iterator it = categories.find(cats[k]);
            if (it == categories.end())
                continue;
            s << "\n== " << cats[k] << " (" << it->second.size() << " distinct)\n" << topList(it->second, 15, "  ");
        }
        if (!textures.empty())
            s << "\n== textures decoded outside the engine codecs / replaced by placeholders\n"
              << topList(textures, 20, "  ");
        if (!dictMissing.empty())
            s << "\n== dictionary keys not found (#{KEY}; the game drops them)\n" << topList(dictMissing, 15, "  ");
        if (!markup.empty())
            s << "\n== text markup the 0.85 UIString parser does not know (occurrences in resolved texts; viewer draws "
                 "#gRRGGBB as #c, other codes lose only the '#', as in 0.85)\n"
              << topList(markup, 20, "  ");
        s << "\nfiles: layouts.csv, errors.txt, failures.txt, causes.txt, CEGUI.log (first worker), run_*/, shots/\n";
        writeText(joinPath(in.outDir, "summary.txt"), s.str());
        return s.str();
    }
}
