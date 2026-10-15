// CYS: Tests/abi/dump_sizes.cpp - ABI dump of the shared game structures (Docs/04 section 6).
//
// Prints, as JSON, sizeof/alignof of every struct/class/union declared in the Src/Shared/Common headers that the
// WXNetPackets build uses (DB_Struct.h, GameStruct*.h, Packets/*.h, Net/*.h, ...) and sizeof/offsetof of each of
// their data members. Build it for x86 and x64, run both, then compare with Tests/abi/compare_sizes.py:
//   build.cmd x64 client-x64 Release "...;wxnetpackets;..." cys_abi_dump  -> Build/cmake/client-x64/bin/abi_dump.exe
//   build.cmd x86 client-x86 Release wxnetpackets cys_abi_dump            -> Build/cmake/client-x86/bin/abi_dump.exe
//   abi_dump.exe Registry/abi/struct_sizes_<arch>.json
// The header list (abi_headers.inc) and the type/member list (abi_types.inc) are generated from the headers by
// Tests/abi/gen_abi_types.py; regenerate them when Src/Shared/Common changes.
//
// offsetof needs access to private/protected members, so the shared headers are compiled with private/protected
// defined as public (test-only). Windows and standard headers are included first so the hack does not reach them.

#define _ALLOW_KEYWORD_MACROS
#include <windows.h>
#include <winsock.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include <time.h>
#include <math.h>
#include <assert.h>
#include <exception>
#include <stdexcept>
#include <typeinfo>
#include <new>
#include <utility>
#include <type_traits>
#include <vector>
#include <deque>
#include <list>
#include <map>
#include <set>
#include <hash_map>
#include <unordered_map>
#include <string>
#include <algorithm>
#include <functional>
#include <iostream>
#include <fstream>
#include <sstream>

#define private public
#define protected public
#include "stdafx.h"		// WXNetPackets set: Type.h, DB_Struct.h, GameStruct_Finger.h, Packet.h
#include "abi_headers.inc"
#undef private
#undef protected

// ---- JSON writer ---------------------------------------------------------------------------------------------------
static FILE* g_pOut = NULL;
static bool g_bFirstType = true;
static bool g_bFirstField = true;
static int g_nTypes = 0;
static int g_nFields = 0;

static void cys_type_begin(const char* szName, const char* szFile, int nLine, size_t nSize, size_t nAlign,
	bool bPolymorphic, bool bTrivial)
{
	fprintf(g_pOut, "%s\n  {\"name\": \"%s\", \"file\": \"%s\", \"line\": %d, \"size\": %u, \"align\": %u, "
		"\"polymorphic\": %s, \"trivially_copyable\": %s, \"fields\": [",
		g_bFirstType ? "" : ",", szName, szFile, nLine, (unsigned)nSize, (unsigned)nAlign,
		bPolymorphic ? "true" : "false", bTrivial ? "true" : "false");
	g_bFirstType = false;
	g_bFirstField = true;
	++g_nTypes;
}

static void cys_field(const char* szName, const char* szType, size_t nOffset, size_t nSize)
{
	fprintf(g_pOut, "%s\n    {\"name\": \"%s\", \"type\": \"%s\", \"offset\": %u, \"size\": %u}",
		g_bFirstField ? "" : ",", szName, szType, (unsigned)nOffset, (unsigned)nSize);
	g_bFirstField = false;
	++g_nFields;
}

static void cys_type_end()
{
	fprintf(g_pOut, "]}");
}

// offsetof for any (also non-standard-layout) class; a non-null base keeps the arithmetic well away from 0.
#define CYS_OFFSETOF(T, m) ((size_t)((const char*)&(((T*)0x1000)->m) - (const char*)0x1000))

// ---- pass 1: one dump function per header --------------------------------------------------------------------------
#define CYS_ABI_HEADER_BEGIN(id)	static void cys_dump_##id() {
#define CYS_ABI_HEADER_END()		}
#define CYS_ABI_TYPE_BEGIN(T, NAME, FILE, LINE) { typedef T CysT; cys_type_begin(NAME, FILE, LINE, sizeof(CysT), \
	alignof(CysT), std::is_polymorphic<CysT>::value, std::is_trivially_copyable<CysT>::value);
#define CYS_ABI_FIELD(M, TYPE)		cys_field(#M, TYPE, CYS_OFFSETOF(CysT, M), sizeof(((CysT*)0)->M));
#define CYS_ABI_TYPE_END()			cys_type_end(); }
#include "abi_types.inc"
#undef CYS_ABI_HEADER_BEGIN
#undef CYS_ABI_HEADER_END
#undef CYS_ABI_TYPE_BEGIN
#undef CYS_ABI_FIELD
#undef CYS_ABI_TYPE_END

static void cys_dump_all()
{
	// ---- pass 2: call them in header order -------------------------------------------------------------------------
#define CYS_ABI_HEADER_BEGIN(id)	cys_dump_##id();
#define CYS_ABI_HEADER_END()
#define CYS_ABI_TYPE_BEGIN(T, NAME, FILE, LINE)
#define CYS_ABI_FIELD(M, TYPE)
#define CYS_ABI_TYPE_END()
#include "abi_types.inc"
}

int main(int argc, char** argv)
{
	g_pOut = (argc > 1) ? fopen(argv[1], "wb") : stdout;
	if(!g_pOut)
	{
		fprintf(stderr, "abi_dump: cannot open %s\n", argv[1]);
		return 1;
	}
	fprintf(g_pOut, "{\"arch\": \"%s\", \"pointer_size\": %u, \"long_size\": %u, \"time_t_size\": %u, "
		"\"wchar_t_size\": %u, \"msc_full_ver\": %u, \"types\": [",
		sizeof(void*) == 8 ? "x64" : "x86", (unsigned)sizeof(void*), (unsigned)sizeof(long), (unsigned)sizeof(time_t),
		(unsigned)sizeof(wchar_t), (unsigned)_MSC_FULL_VER);
	cys_dump_all();
	fprintf(g_pOut, "\n]}\n");
	if(g_pOut != stdout) fclose(g_pOut);
	fprintf(stderr, "abi_dump: %d types, %d fields (%s)\n", g_nTypes, g_nFields, sizeof(void*) == 8 ? "x64" : "x86");
	return 0;
}
