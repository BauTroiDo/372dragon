#ifndef __PATHFINDER_H__
#define __PATHFINDER_H__
#include <stdint.h>
#include "Map.h"

#define EIGHT_DIRECTIONS 8
#define MAX_FILE_PATH 260
extern "C"
{
	class Map;
	class PathFinder
	{
	private:
		struct _D2XZLOOKUP
		{
			uint16_t costmultiplier;
			short zx;
			uint8_t route;
		} DZX[EIGHT_DIRECTIONS];

		struct AIROUTE
		{
			uint16_t count;

			uint16_t walkpoint;
			uint32_t startzx;
			uint32_t endzx;

			uint8_t route[MAX_ROUTES];
		};

		struct _WORLD
		{
			uint8_t state : 4;
			uint8_t route : 4;
		};

		struct _NODES
		{
			uint16_t f;
			uint16_t g;

			uint32_t zx;
		};

		struct _NAVMAP_HEAD
		{
			uint16_t width;
			uint16_t height;
		};

		enum
		{
			EMPTY_NODE = 0,
			MIN_NODE = 1,
			NO_ROUTE = EIGHT_DIRECTIONS,
			MAX_HEAP_LEAFS = MAX_ROUTES,
		};

		enum
		{
			UNKNOWN = 0,
			IMPASSABLE = 1,
			OPEN = 20,
			CLOSED = 30,
		};

		enum
		{
			FINDING = 0,
			NO_PATH = 1,
			PATH_FOUND = 2,
		};
		enum
		{
			ROOT_HEAP = 1
		};

	private:
		char mFileName[MAX_FILE_PATH];
		Map *mOwner;
		int mWidth;
		int mHeight;
		float mGridSize;
		float mInvGridSize;
		float mLeftTopx;
		float mLeftTopz;

		_WORLD *mWorld;
		_WORLD *mWorkWorld;
		_NODES *mNodes;

		uint16_t mLastHeapLeaf;
		uint16_t mHeap[MAX_HEAP_LEAFS];

		uint16_t mBestFNode;
		uint16_t mFreeNode;
		int mMaxNode;

		uint32_t mStartzx, mEndzx;
		uint16_t mStartx, mStartz, mEndx, mEndz;
		float mfStartX, mfStartZ, mfEndX, mfEndZ;

		int mCallTimes;
		int mGridNum;
		int mGrids[MAX_ROUTES];

		WORLD_POS mFirstCanGoPos;
		int mDistance;
		int curStep;

	public:
		PathFinder(Map *owner);
		virtual ~PathFinder();

		void Reset(int startz, int endz);
		bool FindPath(WORLD_POS *startPt, WORLD_POS *endPos, WORLD_POS *posNode, int &numNode, int nLevel, bool bLine = false, int maxRoute = MAX_ROUTES);
		bool IsCanGo(const WORLD_POS &pos, const int nLevel);

		bool ReadNavMap(const char *filename, uint32_t &mx, uint32_t &mz);
		void InitEightDirections();
	private:
		inline uint16_t Distance(const uint32_t zx);
		inline uint16_t RealDistance(const uint32_t zxFirst, const uint32_t zxSecond);
		inline int LEFT(int k);
		inline int RIGHT(int k);
		inline int PARENT(int k);
		inline bool NOTEMPTY_UP(int k);
		inline bool NOTEMPTY_DOWN(int k);
		inline void SwapHeap(const int k1, const int k2);

		void InsertNodeToHeap(uint16_t node);
		void RemoveRootFromHeap();

		bool IsStraightLine(float mAStarBeginPtx, float mAStarBeginPty, float mAStarEndPtx, float mAStarEndPty, bool edit, int nLevel);
		// void EditAStarPath(float startPtx,float startPty,WORLD_POS* posNode,int& numNode);
		void EditAStarPathOpt(float startPtx, float startPty, WORLD_POS *posNode, int &numNode, int nLevel);
		void PackRoute(WORLD_POS *posNode, int &numNode, int nLevel);
		int GetDistance();

		bool IsCanGo(const int state, const int nDriverLevel);
	};
}

#endif
