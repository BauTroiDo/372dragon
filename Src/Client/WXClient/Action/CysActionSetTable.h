









#pragma once

#include <map>
#include <string>
#include <vector>

namespace CysActionSet
{




	enum Slot
	{
		SLOT_NONE	= 0,	// bare hands
		SLOT_SPEAR	= 1,	// Type 1
		SLOT_LONG	= 2,	// Type 0 (blade / axe)
		SLOT_DSHORT	= 3,	// Type 3
		SLOT_SHORT	= 4,	// Type 2
		SLOT_FAN	= 5,	// Type 4
		SLOT_RING	= 6,	// Type 5
		SLOT_QIN	= 7,	// Type 6
		SLOT_CY_DAOZU	= 8,	// Type 8
		SLOT_CY_STAFF	= 9,	// Type 9
		SLOT_CY_TYPE10	= 10,	// Type 10 (2 CY weapons)
		SLOT_CY_CROSSBOW	= 11,	// Type 16
		SLOT_CY_SWORD	= 12,	// Type 17
		SLOT_SHARED	= 13,	// monsters, NPCs, pets, transformed players, riders, buses (CY forces 0xd)
		SLOT_CY_14	= 14,	// filled by the data, never selected by the CY functions above (meaning not recovered)
		SLOT_SICKLE	= 15,	// Type 7
		SLOT_MAX	= 32	// hard cap of this parser (CY: 16 compiled in)
	};



	int SlotFromEquipType(int nEquipType);

	struct Stats
	{
		int nSets;			// distinct set ids in ActionSet.txt
		int nActions;		// rows of ActionSet.txt
		int nLines;			// rows of ActionSetLine.txt
		int nSlots;			// slots per line (columns - 4)
		int nNames;			// rows of ActionSetKV.txt (id 0..n-1)
		int nEmptyNames;	// names that are "" (B: id 9 = no animation)
		int nLineIdMismatch;	// ActionSetLine rows whose column 0 != row index (B indexes by row)
		int nShortRows;		// rows with fewer cells than expected (missing cells read as 0 / -1)
		int nExtraCells;	// rows with more cells than expected (ignored)
		int nBadNumbers;	// cells that were not integers (read as 0)
		int nDanglingLines;	// ActionSet rows whose line id is outside ActionSetLine
		int nDanglingNames;	// slot cells whose name id is outside ActionSetKV
		int nDuplicateActions;	// (set, action) listed twice (last wins, like B's linear search finds the first - see spec)
		std::vector<std::string> messages;	// at most a few dozen human-readable notes (ASCII)
		Stats() { Reset(); }
		void Reset();
	};

	class Table
	{
	public:
		Table();

		// CYS-CY (cs2-world): the row reader of the loaders, for the sibling tables of the same folder
		// (ActionSetFile.txt, CharModelEx.txt). CY 3.71 ships them as binary DBC, client_GL as text; the cells come
		// out the same either way (numbers formatted, strings as their GBK bytes).
		static void ReadRows(const char* pData, size_t nSize, std::vector<std::vector<std::string> >& rows);

		// Each loader parses one file from memory (text as B ships it: two header rows, tab-separated, CRLF or LF).
		// They never throw; a false return means the buffer is empty or has no data rows. Unknown extra cells are
		// counted and ignored; short rows are padded (slots 0, extras -1) and counted.
		bool LoadActionSet(const char* pData, size_t nSize);
		bool LoadActionSetLine(const char* pData, size_t nSize);
		bool LoadActionSetKV(const char* pData, size_t nSize);
		// After the three loads: cross-checks (dangling line / name ids) and the final message list.
		void Finish();
		void Clear();

		bool IsReady() const { return m_bReady; }
		const Stats& GetStats() const { return m_stats; }

		int GetSlotCount() const { return m_nSlots; }
		int GetLineCount() const { return (int)m_lines.size(); }
		int GetNameCount() const { return (int)m_names.size(); }
		bool HasSet(int nSetID) const { return m_sets.find(nSetID) != m_sets.end(); }
		int GetSetCount() const { return (int)m_sets.size(); }
		void GetSetIDs(std::vector<int>& out) const;
		// (action id, line id) pairs of one set, in file order; empty when the set does not exist.
		const std::vector<std::pair<int, int> >* GetSetActions(int nSetID) const;


		int FindLine(int nSetID, int nActionID) const;


		const char* GetLineName(int nLineID, int nSlot) const;



		bool GetHideWeapon(int nLineID) const;
		int GetAppointedWeapon(int nLineID) const;
		int GetExtraC(int nLineID) const;
		// Name id of a slot cell (for tools), -1 when out of range.
		int GetLineNameID(int nLineID, int nSlot) const;
		const char* GetName(int nNameID) const;

		// Everything at once, as CObject_Character needs it. Returns NULL when there is no line for (set, action) or
		// the slot / name id is out of range - the caller then keeps its current animation (0.85 and B behaviour).
		const char* Resolve(int nSetID, int nActionID, int nSlot, bool* pbHideWeapon, int* pnAppointedWeapon) const;

	private:
		struct Line
		{
			unsigned short nName[SLOT_MAX];
			short nExtra[3];
		};
		typedef std::vector<std::pair<int, int> > ActionList;	// (action id, line id) in file order
		typedef std::map<int, ActionList> SetMap;

		std::vector<Line>			m_lines;
		int							m_nSlots;
		std::vector<std::string>	m_names;
		SetMap						m_sets;
		Stats						m_stats;
		bool						m_bReady;
		bool						m_bHaveSets, m_bHaveLines, m_bHaveNames;

		void Note(const std::string& s);
	};
}
