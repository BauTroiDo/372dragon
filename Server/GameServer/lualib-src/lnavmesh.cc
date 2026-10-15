#include "../navmesh/point.h"
#include "../navmesh/pointf.h"
#include "../navmesh/segment.h"
#include "../navmesh/polygon.h"
#include "../navmesh/path_finder.h"
#include "../navmesh/cone_of_vision.h"

#include <vector>
#include <cmath>
#include "sol.hpp"

extern "C"
{
	int luaopen_lnavmesh(lua_State *L)
	{
        sol::state_view state_view(L);
		auto navmesh_lib = state_view.create_table();

        navmesh_lib.new_usertype<NavMesh::Point>(
			"Point", "new",
			sol::initializers([](NavMesh::Point &uninitialized_memory, float x, float y, float z)
							{ 
								int ix = floor(x * 100);
								int iy = floor(y * 100);
								return new (&uninitialized_memory) NavMesh::Point(ix, iy); 
							}),
		"x", &NavMesh::Point::x,
		"y", &NavMesh::Point::y);

        navmesh_lib.new_usertype<NavMesh::Polygon>(
			"Polygon", "new",
			sol::initializers([](NavMesh::Polygon &uninitialized_memory)
							  { return new (&uninitialized_memory) NavMesh::Polygon(); }),
		"AddPoint", sol::overload(
			[](NavMesh::Polygon* Polygon, const NavMesh::Point* point) { 
				return Polygon->AddPoint(*point);
			})
        );

        navmesh_lib.new_usertype<NavMesh::PathFinder>(
			"PathFinder", "new",
			sol::initializers([](NavMesh::PathFinder &uninitialized_memory)
							  { return new (&uninitialized_memory) NavMesh::PathFinder(); }),
            "AddPolygons", sol::overload(
			[](NavMesh::PathFinder* PathFinder, sol::table t) { 
                std::vector<NavMesh::Polygon> Polygons;
                for (auto& kv : t) {
                    NavMesh::Polygon value = kv.second.as<NavMesh::Polygon>();
                    Polygons.push_back(value);
                }
				return PathFinder->AddPolygons(Polygons, 0);
			}),
            "GetPath", sol::overload(
			[](NavMesh::PathFinder* PathFinder, NavMesh::Point* from, NavMesh::Point* to) { 
				std::vector<NavMesh::Point> path = PathFinder->GetPath(*from, *to);
				return path;
			})
		);
		return navmesh_lib.push();
    }
}