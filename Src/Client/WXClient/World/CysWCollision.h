// CysWCollision.h — CYS-NAV: đọc *.WCollision của CY 3.71 (mặt đi được của công trình: bục, cầu, bậc thang).
//
// Đo từ cy_PathLib.dll (sha256 693ec0e4…7c1e) lớp PathLib::BuildingCollsionImpl (vftable 0x180043b78):
//   slot 1 FUN_180004580  loadFromMemory: magic 0xff000002 -> slot 4 FUN_180004a00, còn lại (0xff000001) đọc
//                         u32 cellCount, cellCount x { i32 x, i32 z, u32 n, n x f32[9] }
//   slot 4 FUN_180004a00  u16 meshCount + FUN_180003d80 (mỗi mẫu: u16 nv, nv x f32[3], u16 nt, nt x u16[3]),
//                         f32[3] offset, f32[3] scale, u16 instCount, instCount x
//                         { f32[3] scale, f32[3] pos, f32[4] quat(w,x,y,z), u16 mesh }  (42 byte);
//                         đỉnh thế giới = T(pos) * R(quat) (FUN_180001f80/FUN_180011670) * S(scale) (FUN_1800032a0),
//                         toạ độ cảnh = (thế giới - offset) / scale; dựng cây AABB (OPCODE) toàn cục.
//   slot 2 FUN_180004380  getHeight(x, &y, z): tia từ (x, 10000, z) hướng (0,-1,0) qua slot 3, lấy điểm chạm gần nhất
//                         = mặt trên cùng.
// Game.exe CY (sha256 9278c7f3…cc5b): CScene FUN_1406bd110 nạp .path + .wCollision (cột 5/6 SceneDefineEx) từ nhóm
// "Scene"; CScene::GetMapHeight FUN_1406bcfa0 = max(địa hình AX_PLAN->AX_GAME, getHeight) như 0.85.
// Không phụ thuộc WXClient để test offline được (Tests/pathlib/wcollision_test.cpp).
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
