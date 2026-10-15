#pragma once
#include <cstdint>
#include <map>
#include <set>
#include <sstream>
#include <stdexcept>
#include <string>

// UICommandIndex.txt: row ID, UI command, InterfaceEx window ID. Multiple rows
// for a command are intentional (e.g. command 23 opens two cooperating frames).
namespace CysUiCommandRoutes {
class Table {
    std::map<uint32_t, std::set<uint32_t>> routes_;
    static uint32_t U32(const std::string& s, size_t pos) {
        if (pos > s.size() || s.size() - pos < 4) throw std::runtime_error("UICommandIndex truncated");
        const auto p = reinterpret_cast<const unsigned char*>(s.data() + pos);
        return uint32_t(p[0]) | uint32_t(p[1]) << 8 | uint32_t(p[2]) << 16 | uint32_t(p[3]) << 24;
    }
public:
    void Load(const std::string& bytes) {
        std::map<uint32_t, std::set<uint32_t>> next;
        if (bytes.size() >= 4 && U32(bytes, 0) == 0xDDBBCC00u) {
            if (U32(bytes, 4) != 3 || U32(bytes, 16) || U32(bytes, 20) || U32(bytes, 24))
                throw std::runtime_error("UICommandIndex schema mismatch");
            const size_t rows = U32(bytes, 8), pool = U32(bytes, 12);
            if (rows > 100000 || 28 + rows * 12 + pool != bytes.size())
                throw std::runtime_error("UICommandIndex size mismatch");
            for (size_t i = 0; i < rows; ++i) next[U32(bytes, 32 + i * 12)].insert(U32(bytes, 36 + i * 12));
        } else {
            std::istringstream lines(bytes); std::string line;
            while (std::getline(lines, line)) {
                std::istringstream row(line); uint32_t id, command, window;
                if (row >> id >> command >> window) next[command].insert(window);
            }
        }
        if (next.empty()) throw std::runtime_error("UICommandIndex has no routes");
        routes_.swap(next);
    }
    bool Allows(uint32_t command, uint32_t window) const {
        const auto it = routes_.find(command);
        return it != routes_.end() && it->second.count(window) != 0;
    }
    size_t Size() const { return routes_.size(); }
};
}
