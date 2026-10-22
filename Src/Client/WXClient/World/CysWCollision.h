














#pragma once

#include <cstddef>
#include <string>
#include <vector>

namespace cys {

struct WCollTri {
    float v[9];  // (x,y,z) x 3, toạ độ cảnh (x,z = đơn vị lưới server, y = độ cao game như AX_GAME)
};

struct WCollStats {
    unsigned magic = 0;
    unsigned meshes = 0, instances = 0, cells = 0;
    unsigned trisRead = 0;   // gồm bản trùng (0xff000001 lặp tam giác ở nhiều ô)
    unsigned trisUnique = 0; // sau khi bỏ trùng
    std::size_t parsed = 0, size = 0;
    bool truncated = false;
    float minY = 0, maxY = 0;
};

// true nếu magic là 0xff000001/0xff000002 và đọc không vượt buffer (out = tam giác duy nhất).
bool ParseCyWCollision(const unsigned char* data, std::size_t size, std::vector<WCollTri>& out, WCollStats& stats);
bool IsCyWCollisionMagic(const unsigned char* data, std::size_t size);
std::string DescribeWCollision(const WCollStats& stats);

// Mặt trên cùng tại (x,z) theo danh sách tam giác (phép chiếu đứng, cạnh tính là chạm); false = không có mặt.
bool WCollTopHeight(const std::vector<WCollTri>& tris, float x, float z, float& y);

}  // namespace cys
