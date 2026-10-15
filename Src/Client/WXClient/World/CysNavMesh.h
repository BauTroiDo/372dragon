// CysNavMesh.h — CYS: navmesh của một cảnh (file *.path của client_GL) nạp qua PathLib clean-room.
//
// client_GL (B) nạp SceneDefineEx cột 5 (*.path) bằng PathLib.dll: PathData::parseBuffer rồi PathFinder::findPath.
// 0.85 dùng *.region (đa giác chặn) + Dijkstra; hai định dạng không tương thích nên CScene nạp lớp này khi cột 5
// là *.path (xem Scene.cpp, CYS: navmesh) và CPath rẽ nhánh sang đây (Path.cpp).
//
// HỆ TỌA ĐỘ (đo trên dali.path và SceneDefineEx cảnh 2): toạ độ trong *.path là ĐƠN VỊ THẾ GIỚI của 0.85
// (fVector2.x = x, fVector2.y = z), cùng đơn vị với toạ độ server (posWorld x,y) và cột nXSize/nZSize của
// SceneDefineEx (dali: 320 × 320). Hệ số = 1:1, không có phép đổi đơn vị. Lưới ô của navmesh là 8 đơn vị/ô
// (cellSize), Zone của 0.85 là 10 đơn vị/ô; hai lưới độc lập.
//
// Lớp này không phụ thuộc WXClient (không CWorldManager/DBC) để test offline được (Tests/pathlib/navmesh_test.cpp).

#pragma once

#include <cstddef>
#include <string>
#include <vector>

namespace PathLib {
class PathData;
class PathFinder;
}

namespace cys {

struct NavPoint {
    float x;
    float z;
};

struct NavStats {
    std::size_t points = 0;
    std::size_t tris = 0;
    std::size_t blockedTris = 0;
    std::size_t edges = 0;          // cạnh ràng buộc (tường)
    std::size_t regions = 0;        // số vùng liên thông (giá trị `extra` khác nhau trên tam giác đi được)
    unsigned cellSize = 0;
    unsigned nx = 0, nz = 0;
    float minX = 0, minZ = 0, maxX = 0, maxZ = 0;
    // Bất biến chống crash của PathLib gốc (memory tlbb-path-navmesh-format): tam giác BỊ CHẶN phải có
    // extra == 0; tam giác đi được phải có extra != 0. Đếm số vi phạm khi nạp.
    std::size_t invariantBlockedExtra = 0;   // blocked && extra != 0
    std::size_t invariantWalkableZero = 0;   // walkable && extra == 0
    unsigned version = 0;
};

class NavMesh {
public:
    NavMesh();
    ~NavMesh();
    NavMesh(const NavMesh&) = delete;
    NavMesh& operator=(const NavMesh&) = delete;

    // Nạp từ ảnh file trong bộ nhớ (resource provider) hoặc từ đường dẫn. Trả false nếu hỏng/thiếu; khi đó
    // IsLoaded() = false và mọi truy vấn trả "không có dữ liệu" (không ném ngoại lệ).
    bool LoadFromMemory(const void* bytes, std::size_t len, const char* nameForLog);
    bool LoadFromFile(const char* path);
    void Unload();
    bool IsLoaded() const { return m_loaded; }
    const NavStats& Stats() const { return m_stats; }
    const std::string& Name() const { return m_name; }
    // Một dòng tóm tắt để ghi log: "points=… tris=… regions=…".
    std::string Summary() const;

    // Điểm (x,z) nằm trong tam giác BỊ CHẶN hoặc ngoài lưới => true. Chưa nạp => false (không chặn oan).
    bool IsBlocked(float x, float z) const;
    // Tam giác chứa điểm; đi được => true. Chưa nạp hoặc ngoài lưới => false.
    bool IsWalkable(float x, float z) const;
    // Vùng liên thông của điểm (0 = bị chặn/không có).
    unsigned RegionAt(float x, float z) const;

    // Tìm đường từ `from` tới `to`. Kết quả `out` là các waypoint KHÔNG gồm điểm xuất phát, điểm cuối = `to`.
    // Trả false khi: chưa nạp, điểm đầu/cuối bị chặn, hai điểm khác vùng liên thông, hoặc A* thất bại.
    bool FindPath(const NavPoint& from, const NavPoint& to, std::vector<NavPoint>& out) const;

    // Đoạn thẳng from→to không cắt cạnh ràng buộc nào.
    bool LineOfSight(const NavPoint& from, const NavPoint& to) const;

    // Đi thẳng từ `from` về phía `to` cho tới khi chạm tường; `stop` = điểm dừng (= `to` nếu không chạm).
    // Trả true nếu có chạm tường.
    bool MoveAlong(const NavPoint& from, const NavPoint& to, NavPoint& stop) const;

    // Kiểm đoạn from→to có cắt cạnh ràng buộc nào (dùng cho test độc lập với PathFinder).
    bool SegmentHitsWall(const NavPoint& from, const NavPoint& to) const;

private:
    bool Finish(const char* nameForLog);
    void ComputeStats();

    PathLib::PathData* m_data;
    PathLib::PathFinder* m_finder;
    bool m_loaded;
    NavStats m_stats;
    std::string m_name;
};

}  // namespace cys
