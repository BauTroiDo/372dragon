#include "path_finder.h"

#include <queue>
#include <algorithm>
#include <cstdio>
#include <unordered_map>

namespace NavMesh {

// 用于 unordered_map 的边哈希（有序点对）
struct EdgeHash {
	size_t operator()(const std::pair<Point,Point>& e) const {
		size_t h1 = std::hash<int>()(e.first.x);
		size_t h2 = std::hash<int>()(e.first.y);
		size_t h3 = std::hash<int>()(e.second.x);
		size_t h4 = std::hash<int>()(e.second.y);
		return h1 ^ (h2 * 2654435761U) ^ (h3 * 40503U) ^ (h4 * 12345701U);
	}
};

struct EdgeEqual {
	bool operator()(const std::pair<Point,Point>& a, const std::pair<Point,Point>& b) const {
		return a.first == b.first && a.second == b.second;
	}
};

void PathFinder::AddPolygons(const std::vector<Polygon>& polygons_to_add, int inflate_by = 0)
{
	polygons_.clear();
	v_.clear();
	edges_.clear();
	vertex_ids_.clear();
	polygon_point_is_inside_.clear();
	free_vertices_.clear();
	ext_points_.clear();

	polygons_.reserve(polygons_to_add.size());
	for (auto const& p : polygons_to_add) {
		polygons_.emplace_back(p.Inflate(inflate_by));
		if (polygons_.back().Size() < 1) polygons_.pop_back();
	}

	int n = (int)polygons_.size();
	if (n == 0) return;

	// 每个多边形一个质心顶点
	for (int i = 0; i < n; ++i) {
		int m = polygons_[i].Size();
		int cx = 0, cy = 0;
		for (int k = 0; k < m; ++k) {
			cx += polygons_[i].points_[k].x;
			cy += polygons_[i].points_[k].y;
		}
		v_.push_back(Point(cx / m, cy / m));
		edges_.push_back({});
	}

	// 建立邻接关系：共享同一条边的多边形互为邻居
	std::unordered_map<std::pair<Point,Point>, int, EdgeHash, EdgeEqual> edge2poly;
	edge2poly.reserve(n * 5);
	for (int i = 0; i < n; ++i) {
		int m = polygons_[i].Size();
		for (int k = 0; k < m; ++k) {
			Point a = polygons_[i].points_[k];
			Point b = polygons_[i].points_[(k + 1) % m];
			auto edge = (a < b) ? std::make_pair(a, b) : std::make_pair(b, a);
			auto it = edge2poly.find(edge);
			if (it != edge2poly.end()) {
				int j = it->second;
				double dst = (v_[i] - v_[j]).Len();
				edges_[i].push_back({j, dst});
				edges_[j].push_back({i, dst});
			} else {
				edge2poly[edge] = i;
			}
		}
	}
}

void PathFinder::AddExternalPoints(const std::vector<Point>& points)
{
	ext_points_ = points;
}

std::vector<Point> PathFinder::GetPath(const Point& start_coord, const Point& dest_coord)
{
	int n = (int)polygons_.size();
	if (n == 0) return {};

	// 找起点/终点所在的多边形
	int sp = -1, dp = -1;
	for (int i = 0; i < n; ++i) {
		if (sp < 0 && polygons_[i].IsInside(start_coord)) sp = i;
		if (dp < 0 && polygons_[i].IsInside(dest_coord)) dp = i;
		if (sp >= 0 && dp >= 0) break;
	}

	// 回退：检查是否在多边形顶点上
	if (sp < 0) {
		for (int i = 0; i < n && sp < 0; ++i)
			for (int k = 0; k < polygons_[i].Size(); ++k)
				if (polygons_[i].points_[k] == start_coord) { sp = i; break; }
	}
	if (dp < 0) {
		for (int i = 0; i < n && dp < 0; ++i)
			for (int k = 0; k < polygons_[i].Size(); ++k)
				if (polygons_[i].points_[k] == dest_coord) { dp = i; break; }
	}

	// 最终回退：最近质心
	if (sp < 0) {
		double best = -1;
		for (int i = 0; i < n; ++i) {
			double d = (v_[i] - start_coord).Len();
			if (best < 0 || d < best) { best = d; sp = i; }
		}
	}
	if (dp < 0) {
		double best = -1;
		for (int i = 0; i < n; ++i) {
			double d = (v_[i] - dest_coord).Len();
			if (best < 0 || d < best) { best = d; dp = i; }
		}
	}

	if (sp == dp) return { start_coord, dest_coord };

	// A* 寻路：在多边形邻接图上搜索
	std::vector<int> prev(n, -1);
	std::vector<double> dist(n, -1.0);
	std::vector<bool> done(n, false);
	std::priority_queue<std::pair<double, int>> pq;

	dist[sp] = 0;
	pq.push({-(v_[dp] - v_[sp]).Len(), sp});

	while (!pq.empty()) {
		int cur = pq.top().second;
		pq.pop();
		if (done[cur]) continue;
		done[cur] = true;
		if (cur == dp) break;

		for (auto& e : edges_[cur]) {
			double nd = dist[cur] + e.second;
			if (dist[e.first] < 0 || nd < dist[e.first]) {
				dist[e.first] = nd;
				prev[e.first] = cur;
				pq.push({-(nd + (v_[dp] - v_[e.first]).Len()), e.first});
			}
		}
	}

	if (prev[dp] == -1) return {};

	// 构建路径：起点 -> 沿途质心 -> 终点
	std::vector<Point> res;
	int u = dp;
	while (u != sp) {
		res.push_back(v_[u]);
		u = prev[u];
	}
	res.push_back(start_coord);
	std::reverse(res.begin(), res.end());
	res.push_back(dest_coord);
	return res;
}

std::vector<Segment> PathFinder::GetEdgesForDebug() const
{
	std::vector<Segment> res;
	for (int i = 0; i < (int)edges_.size(); ++i) {
		for (const auto& e : edges_[i]) {
			if (e.first > i) {
				res.push_back(Segment(v_[i], v_[e.first]));
			}
		}
	}
	return res;
}

int PathFinder::GetVertex(const Point& c)
{
	auto it = vertex_ids_.find(c);
	if (it != vertex_ids_.end()) return it->second;
	vertex_ids_[c] = (int)v_.size();
	v_.push_back(c);
	edges_.push_back({});
	return (int)v_.size() - 1;
}

void PathFinder::AddEdge(int be, int en)
{
	double dst = (v_[be] - v_[en]).Len();
	edges_[be].push_back({en, dst});
	edges_[en].push_back({be, dst});
}

bool PathFinder::CanAddSegment(const Segment& s, const std::vector<std::pair<int, int>>& tangents)
{
	return true;
}

}