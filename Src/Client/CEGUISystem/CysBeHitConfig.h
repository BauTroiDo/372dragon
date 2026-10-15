#pragma once

// BeHit.txt contract recovered from B UI_CEGUI +bd60/+c550/+d310/+d6b0.
// Keep the GBK description opaque; it is not a resource key or display string.
#include <climits>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <map>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

namespace cys {
struct BeHitConfig {
    int id, x, y, ax, ay, vx, vy, holdMs, fadeMs;
    uint32_t colour, border, criticalColour, criticalBorder;
    float normalScale, criticalStart, criticalPeak, criticalEnd;
    int peakMs, endMs;
};

inline std::vector<std::string> beHitColumns(const std::string& line) {
    std::vector<std::string> fields;
    size_t start = 0, end;
    do {
        end = line.find('\t', start);
        fields.push_back(line.substr(start, end == std::string::npos ? end : end - start));
        start = end + 1;
    } while (end != std::string::npos);
    return fields;
}

inline int beHitInt(const std::string& value) {
    size_t used = 0;
    long long result = std::stoll(value, &used, 10);
    if (used != value.size() || result < INT_MIN || result > INT_MAX)
        throw std::runtime_error("invalid integer");
    return static_cast<int>(result);
}
inline float beHitFloat(const std::string& value) {
    size_t used = 0;
    float result = std::stof(value, &used);
    if (used != value.size() || !std::isfinite(result) || result <= 0)
        throw std::runtime_error("invalid scale");
    return result;
}
inline uint32_t beHitHex(const std::string& value, size_t digits) {
    if (value.empty() || value.size() > digits || value.find_first_not_of("0123456789abcdefABCDEF") != std::string::npos)
        throw std::runtime_error("invalid colour");
    return static_cast<uint32_t>(std::stoul(value, nullptr, 16));
}

// CYS-CY: CY 3.71 (Assets/CanonicalCY) ships BeHit.txt as binary DBC (magic 0xDDBBCC00, same 20 column types as the
// client_GL text table). The binary table is rewritten to the text form (two type rows + tab rows) so the checks below
// stay the single source of truth. Throws on a truncated or foreign binary table.
inline uint32_t beHitU32(const std::string& b, size_t at) {
    return static_cast<uint32_t>(static_cast<unsigned char>(b[at])) |
           (static_cast<uint32_t>(static_cast<unsigned char>(b[at + 1])) << 8) |
           (static_cast<uint32_t>(static_cast<unsigned char>(b[at + 2])) << 16) |
           (static_cast<uint32_t>(static_cast<unsigned char>(b[at + 3])) << 24);
}
inline std::string beHitBinaryToText(const std::string& b, const char* header) {
    if (b.size() < 16) throw std::runtime_error("BeHit.txt: truncated binary header");
    const uint32_t fields = beHitU32(b, 4), records = beHitU32(b, 8), strings = beHitU32(b, 12);
    if (fields != 20) throw std::runtime_error("BeHit.txt: binary table is not 20 columns");
    const size_t types = 16 + 4 * static_cast<size_t>(fields);
    if (records > 100000 || types + 4 * static_cast<size_t>(fields) * records + strings != b.size())
        throw std::runtime_error("BeHit.txt: binary extents do not match the file size");
    const size_t pool = types + 4 * static_cast<size_t>(fields) * records;
    std::string text = std::string(header) + "\n" + header + "\n";
    char number[64];
    for (uint32_t r = 0; r < records; ++r) {
        for (uint32_t c = 0; c < fields; ++c) {
            const uint32_t kind = beHitU32(b, 16 + 4 * c);
            const uint32_t v = beHitU32(b, types + 4 * (static_cast<size_t>(r) * fields + c));
            if (c) text += '\t';
            if (kind == 2) {
                if (v >= strings) throw std::runtime_error("BeHit.txt: string offset out of range");
                const size_t end = b.find('\0', pool + v);
                if (end == std::string::npos || end >= pool + strings) throw std::runtime_error("BeHit.txt: unterminated string");
                text.append(b, pool + v, end - (pool + v));
            } else if (kind == 1) {
                float f = 0;
                std::memcpy(&f, &v, sizeof(f));
                std::snprintf(number, sizeof(number), "%.9g", f);
                text += number;
            } else {
                std::snprintf(number, sizeof(number), "%d", static_cast<int>(v));
                text += number;
            }
        }
        text += '\n';
    }
    return text;
}

class BeHitTable {
public:
    void load(const std::string& input) {
        static const char* header = "INT\tSTRING\tINT\tINT\tINT\tINT\tINT\tINT\tINT\tINT\tSTRING\tSTRING\tSTRING\tSTRING\tFLOAT\tFLOAT\tFLOAT\tFLOAT\tINT\tINT";
        const bool binary = input.size() >= 4 && beHitU32(input, 0) == 0xDDBBCC00u;
        const std::string bytes = binary ? beHitBinaryToText(input, header) : input;	// CYS-CY
        std::map<int, BeHitConfig> rows;
        std::istringstream stream(bytes);
        std::string line;
        unsigned lineNumber = 0;
        try {
            while (std::getline(stream, line)) {
                ++lineNumber;
                while (!line.empty() && line.back() == '\r') line.pop_back();
                if (lineNumber <= 2) {
                    if (line != header) throw std::runtime_error("expected the 20-column schema");
                    continue;
                }
                if (line.empty()) continue;
                const auto c = beHitColumns(line);
                if (c.size() != 20) throw std::runtime_error("expected 20 columns");
                BeHitConfig r;
                r.id = beHitInt(c[0]);
                r.x = beHitInt(c[2]); r.y = beHitInt(c[3]);
                r.ax = beHitInt(c[4]); r.ay = beHitInt(c[5]);
                r.vx = beHitInt(c[6]); r.vy = beHitInt(c[7]);
                r.holdMs = beHitInt(c[8]); r.fadeMs = beHitInt(c[9]);
                r.colour = beHitHex(c[10], 8); r.border = beHitHex(c[11], 6);
                r.criticalColour = beHitHex(c[12], 8); r.criticalBorder = beHitHex(c[13], 6);
                r.normalScale = beHitFloat(c[14]); r.criticalStart = beHitFloat(c[15]);
                r.criticalPeak = beHitFloat(c[16]); r.criticalEnd = beHitFloat(c[17]);
                r.peakMs = beHitInt(c[18]); r.endMs = beHitInt(c[19]);
                if (r.id < 0 || r.holdMs < 0 || r.fadeMs < 0 || r.holdMs > INT_MAX - r.fadeMs || r.peakMs < 0 || r.endMs < r.peakMs)
                    throw std::runtime_error("invalid id or duration");
                if (!rows.emplace(r.id, r).second) throw std::runtime_error("duplicate id");
            }
            if (lineNumber < 3 || rows.empty()) throw std::runtime_error("empty table");
            // Every gameplay caller in CY uses one of 0..8. Zero durations disable a row.
            for (int id = 0; id <= 8; ++id)
                if (!rows.count(id)) throw std::runtime_error("missing gameplay id 0..8");
        } catch (const std::exception& error) {
            throw std::runtime_error("BeHit.txt line " + std::to_string(lineNumber) + ": " + error.what());
        }
        rows_.swap(rows);
    }
    const BeHitConfig* find(int id, bool alternate) const {
        if (id < 0) return nullptr;
        auto it = rows_.end();
        if (alternate && id <= INT_MAX - 100) it = rows_.find(id + 100);
        if (it == rows_.end()) it = rows_.find(id);
        return it == rows_.end() ? nullptr : &it->second;
    }
    size_t size() const { return rows_.size(); }
private:
    std::map<int, BeHitConfig> rows_;
};

struct BeHitMotion {
    float x = 0, y = 0, vx = 0, vy = 0, alpha = 1, scale = 1;
    int life = 0, total = 0;
    bool critical = false;
    void reset(const BeHitConfig& r, bool doubleHit, float startX, float startY) {
        x = startX + r.x; y = startY + r.y;
        vx = static_cast<float>(r.vx); vy = static_cast<float>(r.vy);
        life = total = r.holdMs + r.fadeMs;
        critical = doubleHit; alpha = 1;
        scale = critical ? (r.peakMs ? r.criticalStart : r.criticalPeak) : r.normalScale;
    }
    bool tick(const BeHitConfig& r, float deltaMs) {
        if (!std::isfinite(deltaMs) || deltaMs < 0) throw std::runtime_error("invalid BeHit frame duration");
        if (life <= 0) { alpha = 0; return false; }
        if (deltaMs >= life) { life = 0; alpha = 0; return false; }
        // B uses semi-implicit Euler, milliseconds, and integer lifetime ticks.
        vx += r.ax / 1000.0f * deltaMs; vy += r.ay / 1000.0f * deltaMs;
        x += vx / 1000.0f * deltaMs; y += vy / 1000.0f * deltaMs;
        life -= static_cast<int>(deltaMs);
        alpha = r.fadeMs > 0 && life < r.fadeMs ? float(life) / r.fadeMs : 1.0f;
        const int elapsed = total - life;
        if (!critical) scale = r.normalScale;
        else if (elapsed > r.endMs) scale = r.criticalEnd;
        else if (elapsed > r.peakMs) {
            scale = r.endMs == r.peakMs ? r.criticalEnd : r.criticalPeak -
                float(elapsed - r.peakMs) / (r.endMs - r.peakMs) * (r.criticalPeak - r.criticalEnd);
        } else {
            // Unlike B's zero-peak branch, never divide by zero.
            scale = r.peakMs == 0 ? r.criticalPeak : r.criticalStart +
                float(elapsed) / r.peakMs * (r.criticalPeak - r.criticalStart);
        }
        return true;
    }
};
}
