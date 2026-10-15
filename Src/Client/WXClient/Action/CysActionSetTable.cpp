// CysActionSetTable.cpp - CYS (actionset, 2026-09-14). See CysActionSetTable.h and Docs/specs/game/actionset_vi.md.
#include "CysActionSetTable.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>

namespace CysActionSet
{
	namespace
	{
		const int kMaxMessages = 40;

		// One data row split on tabs. Cells keep their bytes (GBK names); a trailing '\r' is removed.
		struct Row
		{
			std::vector<std::string> cells;
		};

		bool IsInteger(const std::string& s)
		{
			if(s.empty()) return false;
			size_t i = (s[0] == '-' || s[0] == '+') ? 1 : 0;
			if(i >= s.size()) return false;
			for(; i < s.size(); ++i)
				if(s[i] < '0' || s[i] > '9') return false;
			return true;
		}

		// Reads an integer cell; non-numeric cells count as bad and read as nDefault.
		int CellInt(const Row& row, size_t nIndex, int nDefault, int& nBadNumbers, int& nShort)
		{
			if(nIndex >= row.cells.size())
			{
				++nShort;
				return nDefault;
			}
			const std::string& s = row.cells[nIndex];
			if(!IsInteger(s))
			{
				++nBadNumbers;
				return nDefault;
			}
			return (int)strtol(s.c_str(), NULL, 10);
		}

		// Splits the buffer into data rows. Header rows (first cell not an integer, e.g. "INT") and blank rows are
		// skipped; nHeaderRows receives how many were skipped before the first data row.
		unsigned int Read32(const char* p)
		{
			const unsigned char* b = (const unsigned char*)p;
			return (unsigned int)b[0] | ((unsigned int)b[1] << 8) | ((unsigned int)b[2] << 16) | ((unsigned int)b[3] << 24);
		}

		// CYS-CY: CY 3.71 (Assets/CanonicalCY) ships the three tables as binary DBC (magic 0xDDBBCC00, TLBB_DBC.h
		// FILE_HEAD: fields, records, string bytes; one 4-byte type per field; 4-byte cells; string pool). CY Game.exe
		// FUN_1405b7610 opens them through its DBCFile. Cells become the text cells the text path would produce.
		// Returns false when the buffer is not binary; a truncated binary buffer yields no rows.
		bool SplitBinaryRows(const char* pData, size_t nSize, std::vector<Row>& rows)
		{
			if(nSize < 16 || Read32(pData) != 0xDDBBCC00u) return false;
			const unsigned int nFields = Read32(pData + 4), nRecords = Read32(pData + 8), nStrings = Read32(pData + 12);
			if(nFields == 0 || nFields > 1024 || nRecords > 4000000u) return true;
			const size_t nTypes = 16 + 4 * (size_t)nFields;
			const size_t nCells = (size_t)nFields * (size_t)nRecords;
			if(nTypes > nSize || nCells > (nSize - nTypes) / 4) return true;
			const size_t nPool = nTypes + 4 * nCells;
			if((size_t)nStrings > nSize - nPool) return true;
			rows.reserve(nRecords);
			char sz[64];
			for(unsigned int r = 0; r < nRecords; ++r)
			{
				Row row;
				row.cells.resize(nFields);
				for(unsigned int c = 0; c < nFields; ++c)
				{
					const unsigned int v = Read32(pData + nTypes + 4 * ((size_t)r * nFields + c));
					const unsigned int t = Read32(pData + 16 + 4 * (size_t)c);
					if(t == 2)	// STRING: offset into the pool
					{
						if(v < nStrings)
						{
							const char* s = pData + nPool + v;
							const char* e = (const char*)memchr(s, 0, nStrings - v);
							row.cells[c].assign(s, e ? (size_t)(e - s) : (size_t)(nStrings - v));
						}
					}
					else if(t == 1)	// FLOAT
					{
						float f;
						memcpy(&f, &v, sizeof(f));
						_snprintf(sz, sizeof(sz) - 1, "%g", f);
						sz[sizeof(sz) - 1] = '\0';
						row.cells[c] = sz;
					}
					else
					{
						_snprintf(sz, sizeof(sz) - 1, "%d", (int)v);
						sz[sizeof(sz) - 1] = '\0';
						row.cells[c] = sz;
					}
				}
				rows.push_back(row);
			}
			return true;
		}

		void SplitRows(const char* pData, size_t nSize, std::vector<Row>& rows, int& nHeaderRows)
		{
			rows.clear();
			nHeaderRows = 0;
			if(SplitBinaryRows(pData, nSize, rows)) return;	// CYS-CY: binary DBC (CY 3.71)
			bool bData = false;
			const char* p = pData;
			const char* pEnd = pData + nSize;
			while(p < pEnd)
			{
				const char* pNl = (const char*)memchr(p, '\n', (size_t)(pEnd - p));
				const char* pLineEnd = pNl ? pNl : pEnd;
				const char* q = pLineEnd;
				if(q > p && q[-1] == '\r') --q;
				if(q > p)
				{
					Row row;
					const char* c = p;
					while(true)
					{
						const char* pTab = (const char*)memchr(c, '\t', (size_t)(q - c));
						const char* cEnd = pTab ? pTab : q;
						row.cells.push_back(std::string(c, (size_t)(cEnd - c)));
						if(!pTab) break;
						c = pTab + 1;
					}
					if(!bData && !IsInteger(row.cells[0]))
					{
						++nHeaderRows;
					}
					else
					{
						bData = true;
						rows.push_back(row);
					}
				}
				p = pNl ? pNl + 1 : pEnd;
			}
		}

		std::string Fmt(const char* pszFmt, int a, int b = 0, int c = 0)
		{
			char sz[256];
			_snprintf(sz, sizeof(sz) - 1, pszFmt, a, b, c);
			sz[sizeof(sz) - 1] = '\0';
			return sz;
		}
	}

	int SlotFromEquipType(int nEquipType)
	{
		if(nEquipType < 0) return SLOT_NONE;
		switch(nEquipType % 30)	// CYS-CY: CY 3.71 FUN_1405c6df0: signed remainder, jump table of 18 (0..17)
		{
		case 0:		return SLOT_LONG;
		case 1:		return SLOT_SPEAR;
		case 2:		return SLOT_SHORT;
		case 3:		return SLOT_DSHORT;
		case 4:		return SLOT_FAN;
		case 5:		return SLOT_RING;
		case 6:		return SLOT_QIN;
		case 7:		return SLOT_SICKLE;
		case 8:		return SLOT_CY_DAOZU;
		case 9:		return SLOT_CY_STAFF;
		case 10:	return SLOT_CY_TYPE10;
		case 16:	return SLOT_CY_CROSSBOW;
		case 17:	return SLOT_CY_SWORD;
		default:	return SLOT_NONE;	// 11..15 fall to the default case of the CY jump table
		}
	}

	void Table::ReadRows(const char* pData, size_t nSize, std::vector<std::vector<std::string> >& rows)
	{
		std::vector<Row> parsed;
		int nHeader = 0;
		rows.clear();
		if(pData == NULL || nSize == 0) return;
		SplitRows(pData, nSize, parsed, nHeader);
		rows.reserve(parsed.size());
		for(size_t i = 0; i < parsed.size(); ++i)
			rows.push_back(parsed[i].cells);
	}

	void Stats::Reset()
	{
		nSets = nActions = nLines = nSlots = nNames = nEmptyNames = 0;
		nLineIdMismatch = nShortRows = nExtraCells = nBadNumbers = 0;
		nDanglingLines = nDanglingNames = nDuplicateActions = 0;
		messages.clear();
	}

	Table::Table() : m_nSlots(0), m_bReady(false), m_bHaveSets(false), m_bHaveLines(false), m_bHaveNames(false)
	{
	}

	void Table::Clear()
	{
		m_lines.clear();
		m_names.clear();
		m_sets.clear();
		m_nSlots = 0;
		m_stats.Reset();
		m_bReady = m_bHaveSets = m_bHaveLines = m_bHaveNames = false;
	}

	void Table::Note(const std::string& s)
	{
		if((int)m_stats.messages.size() < kMaxMessages)
			m_stats.messages.push_back(s);
		else if((int)m_stats.messages.size() == kMaxMessages)
			m_stats.messages.push_back("... (more notes suppressed)");
	}

	// ActionSet.txt: record, set id, action id, line id (B FUN_1400e35b0 reads columns 1..3 and groups rows by set
	// id as they change; the record column is not used).
	bool Table::LoadActionSet(const char* pData, size_t nSize)
	{
		m_sets.clear();
		m_bHaveSets = false;
		if(pData == NULL || nSize == 0) return false;
		std::vector<Row> rows;
		int nHeader = 0;
		SplitRows(pData, nSize, rows, nHeader);
		if(rows.empty())
		{
			Note("ActionSet.txt: no data rows");
			return false;
		}
		int nShort = 0;
		for(size_t i = 0; i < rows.size(); ++i)
		{
			const Row& row = rows[i];
			if(row.cells.size() > 4) ++m_stats.nExtraCells;
			int nRowShort = 0;
			int nSet = CellInt(row, 1, -1, m_stats.nBadNumbers, nRowShort);
			int nAction = CellInt(row, 2, -1, m_stats.nBadNumbers, nRowShort);
			int nLine = CellInt(row, 3, -1, m_stats.nBadNumbers, nRowShort);
			if(nRowShort) ++nShort;
			if(nSet < 0 || nAction < 0)
			{
				Note(Fmt("ActionSet.txt row %d: set %d / action %d ignored", (int)i, nSet, nAction));
				continue;
			}
			ActionList& list = m_sets[nSet];
			for(size_t k = 0; k < list.size(); ++k)
			{
				if(list[k].first == nAction)
				{
					++m_stats.nDuplicateActions;
					break;
				}
			}
			list.push_back(std::make_pair(nAction, nLine));
			++m_stats.nActions;
		}
		m_stats.nShortRows += nShort;
		m_stats.nSets = (int)m_sets.size();
		m_bHaveSets = !m_sets.empty();
		return m_bHaveSets;
	}

	// ActionSetLine.txt: line id, one name id per slot, then three extra cells. The slot count is the column count
	// minus 4 (B compiles it in: 11, or 15 after the 09/09 patch; this parser takes it from the header row so both
	// files load). Lines are indexed by ROW like B; column 0 is checked and a mismatch counted.
	bool Table::LoadActionSetLine(const char* pData, size_t nSize)
	{
		m_lines.clear();
		m_nSlots = 0;
		m_bHaveLines = false;
		if(pData == NULL || nSize == 0) return false;
		std::vector<Row> rows;
		int nHeader = 0;
		SplitRows(pData, nSize, rows, nHeader);
		if(rows.empty())
		{
			Note("ActionSetLine.txt: no data rows");
			return false;
		}
		// Column count: the widest of the first rows (a short first row must not shrink the table).
		size_t nCols = 0;
		for(size_t i = 0; i < rows.size() && i < 16; ++i)
			if(rows[i].cells.size() > nCols) nCols = rows[i].cells.size();
		if(nCols < 5)
		{
			Note(Fmt("ActionSetLine.txt: only %d columns (need line id + 1 slot + 3 extras)", (int)nCols));
			return false;
		}
		int nSlots = (int)nCols - 4;
		if(nSlots > SLOT_MAX)
		{
			Note(Fmt("ActionSetLine.txt: %d slots, capped to %d", nSlots, (int)SLOT_MAX));
			nSlots = SLOT_MAX;
		}
		m_nSlots = nSlots;
		m_lines.resize(rows.size());
		for(size_t i = 0; i < rows.size(); ++i)
		{
			const Row& row = rows[i];
			Line& line = m_lines[i];
			memset(&line, 0, sizeof(line));
			int nRowShort = 0;
			int nID = CellInt(row, 0, (int)i, m_stats.nBadNumbers, nRowShort);
			if(nID != (int)i) ++m_stats.nLineIdMismatch;
			for(int s = 0; s < nSlots; ++s)
			{
				int v = CellInt(row, (size_t)(1 + s), 0, m_stats.nBadNumbers, nRowShort);
				if(v < 0 || v > 0xFFFF) { v = 0xFFFF; }	// out of range -> dangling (reported by Finish)
				line.nName[s] = (unsigned short)v;
			}
			line.nExtra[0] = (short)CellInt(row, (size_t)(1 + nSlots), 0, m_stats.nBadNumbers, nRowShort);
			line.nExtra[1] = (short)CellInt(row, (size_t)(2 + nSlots), -1, m_stats.nBadNumbers, nRowShort);
			line.nExtra[2] = (short)CellInt(row, (size_t)(3 + nSlots), -1, m_stats.nBadNumbers, nRowShort);
			if(nRowShort) ++m_stats.nShortRows;
			if(row.cells.size() > nCols) ++m_stats.nExtraCells;
		}
		m_stats.nLines = (int)m_lines.size();
		m_stats.nSlots = nSlots;
		m_bHaveLines = true;
		return true;
	}

	// ActionSetKV.txt: id, name (GBK). B stores an offset table and returns base + offset[id]; ids are contiguous from
	// 0 in the shipped data. Gaps are filled with "" so lookups stay by id.
	bool Table::LoadActionSetKV(const char* pData, size_t nSize)
	{
		m_names.clear();
		m_bHaveNames = false;
		if(pData == NULL || nSize == 0) return false;
		std::vector<Row> rows;
		int nHeader = 0;
		SplitRows(pData, nSize, rows, nHeader);
		if(rows.empty())
		{
			Note("ActionSetKV.txt: no data rows");
			return false;
		}
		int nGaps = 0;
		for(size_t i = 0; i < rows.size(); ++i)
		{
			const Row& row = rows[i];
			int nRowShort = 0;
			int nID = CellInt(row, 0, -1, m_stats.nBadNumbers, nRowShort);
			if(nID < 0 || nID > 0xFFFE)
			{
				Note(Fmt("ActionSetKV.txt row %d: id %d ignored", (int)i, nID));
				continue;
			}
			if((int)m_names.size() <= nID)
			{
				if((int)m_names.size() < nID) nGaps += nID - (int)m_names.size();
				m_names.resize((size_t)nID + 1);
			}
			// A name row of one cell means an empty name (B: id 9). Count it; it is valid data.
			const std::string& name = (row.cells.size() >= 2) ? row.cells[1] : std::string();
			if(row.cells.size() > 2) ++m_stats.nExtraCells;
			m_names[(size_t)nID] = name;
		}
		for(size_t i = 0; i < m_names.size(); ++i)
			if(m_names[i].empty()) ++m_stats.nEmptyNames;
		if(nGaps) Note(Fmt("ActionSetKV.txt: %d id gap(s) filled with empty names", nGaps));
		m_stats.nNames = (int)m_names.size();
		m_bHaveNames = !m_names.empty();
		return m_bHaveNames;
	}

	void Table::Finish()
	{
		m_stats.nDanglingLines = 0;
		m_stats.nDanglingNames = 0;
		for(SetMap::const_iterator it = m_sets.begin(); it != m_sets.end(); ++it)
		{
			const ActionList& list = it->second;
			for(size_t k = 0; k < list.size(); ++k)
			{
				int nLine = list[k].second;
				if(nLine < 0 || nLine >= (int)m_lines.size())
				{
					if(m_stats.nDanglingLines < 8)
						Note(Fmt("ActionSet.txt: set %d action %d -> line %d outside ActionSetLine", it->first, list[k].first, nLine));
					++m_stats.nDanglingLines;
				}
			}
		}
		for(size_t i = 0; i < m_lines.size(); ++i)
		{
			for(int s = 0; s < m_nSlots; ++s)
			{
				if((int)m_lines[i].nName[s] >= (int)m_names.size())
				{
					if(m_stats.nDanglingNames < 8)
						Note(Fmt("ActionSetLine.txt: line %d slot %d -> name id %d outside ActionSetKV", (int)i, s, (int)m_lines[i].nName[s]));
					++m_stats.nDanglingNames;
				}
			}
		}
		m_bReady = m_bHaveSets && m_bHaveLines && m_bHaveNames;
	}

	void Table::GetSetIDs(std::vector<int>& out) const
	{
		out.clear();
		out.reserve(m_sets.size());
		for(SetMap::const_iterator it = m_sets.begin(); it != m_sets.end(); ++it)
			out.push_back(it->first);
	}

	const std::vector<std::pair<int, int> >* Table::GetSetActions(int nSetID) const
	{
		SetMap::const_iterator it = m_sets.find(nSetID);
		return (it == m_sets.end()) ? NULL : &it->second;
	}

	int Table::FindLine(int nSetID, int nActionID) const
	{
		SetMap::const_iterator it = m_sets.find(nSetID);
		if(it == m_sets.end()) return -1;
		const ActionList& list = it->second;
		// B FUN_1400e3db0: linear scan of the set's rows, first match wins.
		for(size_t k = 0; k < list.size(); ++k)
			if(list[k].first == nActionID) return list[k].second;
		return -1;
	}

	const char* Table::GetName(int nNameID) const
	{
		if(nNameID < 0 || nNameID >= (int)m_names.size()) return NULL;
		return m_names[(size_t)nNameID].c_str();
	}

	int Table::GetLineNameID(int nLineID, int nSlot) const
	{
		if(nLineID < 0 || nLineID >= (int)m_lines.size()) return -1;
		if(nSlot < 0 || nSlot >= m_nSlots) return -1;
		return (int)m_lines[(size_t)nLineID].nName[nSlot];
	}

	const char* Table::GetLineName(int nLineID, int nSlot) const
	{
		int nNameID = GetLineNameID(nLineID, nSlot);
		if(nNameID < 0) return NULL;
		return GetName(nNameID);	// NULL when the id is outside ActionSetKV (B: uVar2 >= count -> 0)
	}

	bool Table::GetHideWeapon(int nLineID) const
	{
		if(nLineID < 0 || nLineID >= (int)m_lines.size()) return false;
		return m_lines[(size_t)nLineID].nExtra[0] != 0;
	}

	int Table::GetAppointedWeapon(int nLineID) const
	{
		if(nLineID < 0 || nLineID >= (int)m_lines.size()) return -1;
		return m_lines[(size_t)nLineID].nExtra[1];
	}

	int Table::GetExtraC(int nLineID) const
	{
		if(nLineID < 0 || nLineID >= (int)m_lines.size()) return -1;
		return m_lines[(size_t)nLineID].nExtra[2];
	}

	const char* Table::Resolve(int nSetID, int nActionID, int nSlot, bool* pbHideWeapon, int* pnAppointedWeapon) const
	{
		if(!m_bReady) return NULL;
		int nLine = FindLine(nSetID, nActionID);
		if(nLine < 0) return NULL;
		const char* pszName = GetLineName(nLine, nSlot);
		if(pszName == NULL) return NULL;
		if(pbHideWeapon) *pbHideWeapon = GetHideWeapon(nLine);
		if(pnAppointedWeapon) *pnAppointedWeapon = GetAppointedWeapon(nLine);
		return pszName;
	}
}
