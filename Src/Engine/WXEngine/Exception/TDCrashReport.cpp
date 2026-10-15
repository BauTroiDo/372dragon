#include "StdAfx.h"
#include "TDCrashReport.h"
#include <tlhelp32.h>
#include <time.h>
#include <dbghelp.h>
#include "TDException.h"
#include "TDUtil.h"		// CYS-CRASHRPT: TDU_Log - name the artifacts in the main log
#include <stdio.h>
#include "..\WXClient\Global.h"
#include "..\WXClient\Resource.h"


#define	DUMP_SIZE_MAX	8000	//max size of our dump
#define	CALL_TRACE_MAX	((DUMP_SIZE_MAX - 2000) / (MAX_PATH + 40))	//max number of traced calls
#define	NL				_T("\n")	//new line

// ============================================================================================
// CYS-CRASHRPT 19/09/2026 - the report used to LIE about addresses on x64.
//
// Every address here is a 64-bit ULONG_PTR / PBYTE, but the whole file printed them with
// "%08X", which consumes only the low 32 bits of the vararg slot. The 18/09 QuestLog crash
// therefore reported "Address: 0xFFFFFFFF" while the real faulting address was
// 0xFFFFFFFFFFFFFFFF (the classic non-canonical #GP signature). The truncated value was read
// as a 32-bit npos index and sent a three-day investigation down the wrong path
// (Timeline\handoff\qlog-crash.md, muc 5.1).
//
// NOTE the vararg slots themselves were never misaligned: MSVC x64 varargs give every argument
// an 8-byte slot, so "%08X" truncated the value it printed but did NOT shift the arguments
// after it (that is why "LastError" stayed correct). The bug is pure truncation.
//
// CYS_ADDR_FMT always prints all 64 bits; CYS_ADDR() widens whatever it is handed.
// ============================================================================================
#define	CYS_ADDR_FMT	_T("%016llX")			// full pointer width, zero padded
#define	CYS_RVA_FMT		_T("%08llX")			// module-relative offset, min 8 digits
#define	CYS_ADDR(x)		((unsigned __int64)(ULONG_PTR)(x))

// CYS-CRASHRPT: long (non 8.3) absolute paths of the artifacts written by the last crash.
// CreateXxx() below hand back GetShortPathName() results for CrashReport.exe's command line;
// these keep the readable path so it can be printed into WXClient.log and WXC_SML.TXT.
static TCHAR	g_szCysSmallFileLong[MAX_PATH] = {0};
static TCHAR	g_szCysBigFileLong[MAX_PATH]   = {0};
static TCHAR	g_szCysDumpFileLong[MAX_PATH]  = {0};

//寻找脚本错误模式
extern BOOL g_IsFindLuaError = FALSE;

//****************************************************************************************
// CYS-CRASHRPT: directory that holds the crash artifacts = the folder of the running module,
// exactly where WXC_SML.TXT already goes, so summary + detail + minidump stay together and
// the live runner (Tools\game\run_world_gui_live.ps1:76,134 scans $bin for *.dmp) sees them.
// Falls back to %TEMP% when the module folder is not writable.
//****************************************************************************************
static BOOL CysBuildCrashPath(LPCTSTR szExt, PTCHAR szOut, size_t nOut)
{
	if(!szOut || nOut < MAX_PATH) return FALSE;
	szOut[0] = 0;

	TCHAR szDir[MAX_PATH] = {0};
	if(0 == ::GetModuleFileName(g_hInstance, szDir, MAX_PATH) || !::PathRemoveFileSpec(szDir))
	{
		szDir[0] = 0;
	}

	SYSTEMTIME T; ::GetLocalTime(&T);
	TCHAR szName[MAX_PATH] = {0};
	// ASCII only - this string reaches engine log paths (tEngine narrows wide->GBK).
	_sntprintf(szName, MAX_PATH - 1, _T("WXC_%04d%02d%02d_%02d%02d%02d_pid%lu.%s"),
		T.wYear, T.wMonth, T.wDay, T.wHour, T.wMinute, T.wSecond,
		(unsigned long)::GetCurrentProcessId(), szExt);
	szName[MAX_PATH - 1] = 0;

	if(szDir[0])
	{
		_sntprintf(szOut, nOut - 1, _T("%s\\%s"), szDir, szName);
		szOut[nOut - 1] = 0;
		// Prove it is writable before the caller commits to it.
		HANDLE hTest = ::CreateFile(szOut, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
		if(hTest != INVALID_HANDLE_VALUE) { ::CloseHandle(hTest); return TRUE; }
	}

	TCHAR szTempDir[MAX_PATH] = {0};
	if(0 == ::GetTempPath(MAX_PATH, szTempDir)) { szOut[0] = 0; return FALSE; }
	_sntprintf(szOut, nOut - 1, _T("%s%s"), szTempDir, szName);
	szOut[nOut - 1] = 0;
	return TRUE;
}

//****************************************************************************************
// CYS-CRASHRPT: the 18/09 investigation never found the minidump because nothing ever named
// it. Print the absolute path of every artifact into the main log (WXClient.log, the file the
// runners already harvest) and append the same index to WXC_SML.TXT.
//****************************************************************************************
VOID CysReportCrashArtifacts(VOID)
{
	TDU_Log("CYS-CRASHRPT: crash artifacts of pid %lu", (unsigned long)::GetCurrentProcessId());
	TDU_Log("CYS-CRASHRPT:   summary  (module+RVA) -> %s",
		g_szCysSmallFileLong[0] ? g_szCysSmallFileLong : "<not written>");
	TDU_Log("CYS-CRASHRPT:   detail   (call stack)  -> %s",
		g_szCysBigFileLong[0] ? g_szCysBigFileLong : "<not written>");
	TDU_Log("CYS-CRASHRPT:   minidump (WinDbg/VS)   -> %s",
		g_szCysDumpFileLong[0] ? g_szCysDumpFileLong : "<not written>");

	if(!g_szCysSmallFileLong[0]) return;

	FILE* fp = _tfopen(g_szCysSmallFileLong, _T("at"));
	if(!fp) return;
	_ftprintf(fp,
		_T("------------------------------------------------------------------------------") NL
		_T("Detail:    %s") NL
		_T("Minidump:  %s") NL
		_T("Symbolize: llvm-symbolizer --obj=<module> --relative-address 0x<RVA of Fault>") NL,
		g_szCysBigFileLong[0] ? g_szCysBigFileLong : _T("<not written>"),
		g_szCysDumpFileLong[0] ? g_szCysDumpFileLong : _T("<not written>"));
	fclose(fp);
}

//--------------------------------------------------------------
//自动加载dbghelp.dll
typedef	BOOL (WINAPI * MINIDUMP_WRITE_DUMP)(
	IN HANDLE			hProcess,
	IN UINT			ProcessId,
	IN HANDLE			hFile,
	IN MINIDUMP_TYPE	DumpType,
	IN CONST PMINIDUMP_EXCEPTION_INFORMATION	ExceptionParam, OPTIONAL
	IN PMINIDUMP_USER_STREAM_INFORMATION		UserStreamParam, OPTIONAL
	IN PMINIDUMP_CALLBACK_INFORMATION			CallbackParam OPTIONAL
	);

struct tAUTO_LOAD_DBGHELP
{
	tAUTO_LOAD_DBGHELP();
	~tAUTO_LOAD_DBGHELP();
	
	HMODULE					m_hDbgHelp;
	MINIDUMP_WRITE_DUMP		m_pfnMiniDumpWriteDump;
} theDbgHelper;

tAUTO_LOAD_DBGHELP::tAUTO_LOAD_DBGHELP()
{
	m_hDbgHelp = ::LoadLibrary(_T("DBGHELP.DLL"));
	if(NULL == theDbgHelper.m_hDbgHelp) return; //Load failed!
	m_pfnMiniDumpWriteDump = (MINIDUMP_WRITE_DUMP)GetProcAddress(m_hDbgHelp, (LPCSTR)("MiniDumpWriteDump"));
	if(NULL == m_pfnMiniDumpWriteDump) 
	{
		::FreeLibrary(m_hDbgHelp);
		m_hDbgHelp = NULL;
	}
}

tAUTO_LOAD_DBGHELP::~tAUTO_LOAD_DBGHELP()
{
	if(m_hDbgHelp)
	{
		::FreeLibrary(m_hDbgHelp);
		m_hDbgHelp= NULL;
	}
}

//****************************************************************************************
BOOL WINAPI Get_Module_By_Ret_Addr(PBYTE Ret_Addr, PTCHAR Module_Name, PBYTE & Module_Addr)
//****************************************************************************************
// Find module by Ret_Addr (address in the module).
// Return Module_Name (full path) and Module_Addr (start address).
// Return TRUE if found.
{
	MODULEENTRY32	M = {sizeof(M)};
	HANDLE	hSnapshot;

	Module_Name[0] = 0;
	
	hSnapshot = ::CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, 0);
		
	if ((hSnapshot != INVALID_HANDLE_VALUE) &&
		::Module32First(hSnapshot, &M))
	{
		do
		{
			if (SIZE_T(Ret_Addr - M.modBaseAddr) < M.modBaseSize)	// CYS: UINT truncated the pointer difference (x64)
			{
				lstrcpyn(Module_Name, M.szExePath, MAX_PATH);
				Module_Addr = M.modBaseAddr;
				break;
			}
		} while (::Module32Next(hSnapshot, &M));
	}

	::CloseHandle(hSnapshot);

	return !!Module_Name[0];
} //Get_Module_By_Ret_Addr

//******************************************************************
VOID Get_Call_Stack(PEXCEPTION_POINTERS pException, FILE* fp)
//******************************************************************
// Fill Str with call stack info.
// pException can be either GetExceptionInformation() or NULL.
// If pException = NULL - get current call stack.
{
	TCHAR	Module_Name[MAX_PATH];
	PBYTE	Module_Addr = 0;
	PBYTE	Module_Addr_1;
	
#pragma warning(disable: 4200)	//nonstandard extension used : zero-sized array in struct/union
	typedef struct STACK
	{
		STACK *	Ebp;
		PBYTE	Ret_Addr;
		// CYS-CRASHRPT: a stack slot is pointer-sized. As UINT, Param[0..4] read the two halves
		// of the first 2.5 arguments on x64 and printed pure noise.
		ULONG_PTR	Param[0];
	} STACK, * PSTACK;
#pragma warning(default: 4200)

	STACK	Stack = {0, 0};
	PSTACK	Ebp;

	if (pException)		//fake frame for exception address
	{
#ifdef _WIN64
		// CYS: x64 CONTEXT has Rbp, not Ebp. Frame-pointer walking is best effort on x64 (frames may omit rbp);
		// the minidump written by CreateDumpHelpFile() is the reliable crash record.
		Stack.Ebp = (PSTACK)(DWORD_PTR)pException->ContextRecord->Rbp;
#else
		Stack.Ebp = (PSTACK)(DWORD_PTR)pException->ContextRecord->Ebp;
#endif
		Stack.Ret_Addr = (PBYTE)pException->ExceptionRecord->ExceptionAddress;
		Ebp = &Stack;
	}
	else
	{
		Ebp = (PSTACK)&pException - 1;	//frame addr of Get_Call_Stack()

		// Skip frame of Get_Call_Stack().
		if (!IsBadReadPtr(Ebp, sizeof(PSTACK)))
			Ebp = Ebp->Ebp;		//caller ebp
	}

	// Trace CALL_TRACE_MAX calls maximum - not to exceed DUMP_SIZE_MAX.
	// Break trace on wrong stack frame.
	for (INT Ret_Addr_I = 0;
		(Ret_Addr_I < CALL_TRACE_MAX) && !IsBadReadPtr(Ebp, sizeof(PSTACK)) && !IsBadCodePtr(FARPROC(Ebp->Ret_Addr));
		Ret_Addr_I++, Ebp = Ebp->Ebp)
	{
		// If module with Ebp->Ret_Addr found.
		if (Get_Module_By_Ret_Addr(Ebp->Ret_Addr, Module_Name, Module_Addr_1))
		{
			if (Module_Addr_1 != Module_Addr)	//new module
			{
				// Save module's address and full path.
				Module_Addr = Module_Addr_1;
				// CYS-CRASHRPT: was "%08X" - a 64-bit image base printed as 8 digits (the real
				// 18/09 report said "5F1E0000" for a module actually loaded at 00007FF85F1E0000).
				_ftprintf(fp, CYS_ADDR_FMT _T("  %s")NL, CYS_ADDR(Module_Addr), Module_Name);
			}

			// Save call offset.
			_ftprintf(fp, _T("  +") CYS_RVA_FMT, (unsigned __int64)(Ebp->Ret_Addr - Module_Addr));

			// Save 5 params of the call. We don't know the real number of params.
			if (pException && !Ret_Addr_I)	//fake frame for exception address
				_ftprintf(fp, _T("  Exception Offset") NL);
			else if (!IsBadReadPtr(Ebp, sizeof(PSTACK) + 5 * sizeof(ULONG_PTR)))
			{
				_ftprintf(fp, _T("  (%llX, %llX, %llX, %llX, %llX)") NL,
					CYS_ADDR(Ebp->Param[0]), CYS_ADDR(Ebp->Param[1]), CYS_ADDR(Ebp->Param[2]),
					CYS_ADDR(Ebp->Param[3]), CYS_ADDR(Ebp->Param[4]));
			}
		}
		else
			_ftprintf(fp, CYS_ADDR_FMT NL, CYS_ADDR(Ebp->Ret_Addr));
	}

} //Get_Call_Stack

//***********************************
VOID WINAPI Get_Version_Str(FILE* fp)
//***********************************
// Fill Str with Windows version.
{
	OSVERSIONINFOEX	V = {sizeof(OSVERSIONINFOEX)};	//EX for NT 5.0 and later

	if (!GetVersionEx((POSVERSIONINFO)&V))
	{
		ZeroMemory(&V, sizeof(V));
		V.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
		GetVersionEx((POSVERSIONINFO)&V);
	}

	if (V.dwPlatformId != VER_PLATFORM_WIN32_NT)
		V.dwBuildNumber = LOWORD(V.dwBuildNumber);	//for 9x HIWORD(dwBuildNumber) = 0x04xx

	TCHAR dateBuf[32];
	_tstrdate(dateBuf);
	TCHAR timeBuf[32];
	_tstrtime(timeBuf);


	_ftprintf(fp,
		_T("==============================================================================") NL
		_T("Windows:  %d.%d.%d, SP %d.%d, Product Type %d") NL	//SP - service pack, Product Type - VER_NT_WORKSTATION,...
		NL
		_T("Time:     %s %s")NL,
		V.dwMajorVersion, V.dwMinorVersion, V.dwBuildNumber, V.wServicePackMajor, V.wServicePackMinor, V.wProductType, 
		dateBuf, timeBuf);
} //Get_Version_Str


VOID CreateExceptionDesc(PEXCEPTION_POINTERS pException, FILE* fp, UINT dwLastError)
{
	if (!pException || !fp) return;

	EXCEPTION_RECORD &	E = *pException->ExceptionRecord;
	CONTEXT &			C = *pException->ContextRecord;

	//取得异常发生地
	TCHAR		szModeleInfo[MAX_PATH];
	TCHAR		Module_Name[MAX_PATH];
	// CYS-CRASHRPT: "<module basename>+0x<RVA>" - the single line that turns this report from
	// useless into "paste it into llvm-symbolizer". WXC_SML.TXT carried only the module PATH,
	// so no reader could tell WHERE inside the DLL the fault was.
	TCHAR		szFault[MAX_PATH + 64];
	PBYTE		Module_Addr = 0;		// CYS-CRASHRPT: was read uninitialized on the not-found path
	if (Get_Module_By_Ret_Addr((PBYTE)E.ExceptionAddress, Module_Name, Module_Addr))
	{
		_sntprintf(szModeleInfo, MAX_PATH, _T("%s"), Module_Name);
		_sntprintf(szFault, MAX_PATH + 63, _T("%s+0x") CYS_RVA_FMT,
			::PathFindFileName(Module_Name),
			(unsigned __int64)((PBYTE)E.ExceptionAddress - Module_Addr));
	}
	else
	{
		_sntprintf(szModeleInfo, MAX_PATH, CYS_ADDR_FMT, CYS_ADDR(E.ExceptionAddress));
		_sntprintf(szFault, MAX_PATH + 63, _T("<no module>+0x") CYS_ADDR_FMT, CYS_ADDR(E.ExceptionAddress));
	}
	szModeleInfo[MAX_PATH - 1] = 0;
	szFault[MAX_PATH + 63] = 0;

	switch(E.ExceptionCode)
	{
	//转化后的c++异常
	case 0XE000C0DE:
		{
			const STRING* pCPPException = (const STRING*)E.ExceptionInformation[0];
			if(!pCPPException) return;

			_ftprintf(fp,
				_T("C++ Exception\n")
				_T("\n")
				_T("Expr:      %s\n"),

				pCPPException->c_str());
		}
		break;

		//试图对一个虚地址进行读写
	case EXCEPTION_ACCESS_VIOLATION:
		{
			// Access violation type - Write/Read/Execute(DEP).
			LPCTSTR szOperate = _T("Read");
			if (E.ExceptionInformation[0] == 1) szOperate = _T("Write");
			else if (E.ExceptionInformation[0] == 8) szOperate = _T("Execute(DEP)");

			// CYS-CRASHRPT: "Address" is the DATA address that could not be touched; the CODE
			// address is ExcAddr. The old report printed only the first, as 32 bits, unlabelled -
			// 0xFFFFFFFFFFFFFFFF came out as 0xFFFFFFFF and was misread as a 32-bit npos index.
			_ftprintf(fp,
				_T("\t\tAccess violation\n")
				_T("\n")
				_T("@:         %s\n")
				_T("Fault:     %s\n")
				_T("ExcAddr:   0x") CYS_ADDR_FMT _T("  (code)\n")
				_T("ModBase:   0x") CYS_ADDR_FMT _T("\n")
				_T("Operate:   %s\n")
				_T("Address:   0x") CYS_ADDR_FMT _T("  (data)\n")
				_T("LastError: 0x%08X\n"),
				szModeleInfo,
				szFault,
				CYS_ADDR(E.ExceptionAddress),
				CYS_ADDR(Module_Addr),
				szOperate,
				CYS_ADDR(E.ExceptionInformation[1]), dwLastError);
		}
		break;

	default:
		{
			_ftprintf(fp,
				_T("\t\tOTHER\n")
				_T("\n")
				_T("@:         %s\n")
				_T("Fault:     %s\n")
				_T("ExcAddr:   0x") CYS_ADDR_FMT _T("  (code)\n")
				_T("ModBase:   0x") CYS_ADDR_FMT _T("\n")
				_T("Code:      0x%08X%s\n")
				_T("LastError: 0x%08X\n"),
				szModeleInfo,
				szFault,
				CYS_ADDR(E.ExceptionAddress),
				CYS_ADDR(Module_Addr),
				E.ExceptionCode,
				(E.ExceptionCode == 0xE06D7363) ? _T("  (MSVC C++ throw)") : _T(""),
				dwLastError);

			// CYS-CRASHRPT 19/09/2026: print the exception PARAMETERS. Without them an "OTHER" report
			// says only that something was thrown. The 19/09 scene-1350 crash was code 0xE06D7363,
			// where the parameters ARE the payload:
			//   [0] 0x19930520 EH magic   [1] thrown object   [2] _ThrowInfo   [3] image base (x64)
			// Resolving [2] to module+RVA and running llvm-symbolizer on it prints the C++ type
			// outright ("_TI2?AVException@Ogre@@" => Ogre::Exception) - without opening the minidump.
			const DWORD nParams = (E.NumberParameters > EXCEPTION_MAXIMUM_PARAMETERS)
								? EXCEPTION_MAXIMUM_PARAMETERS : E.NumberParameters;
			for (DWORD i = 0; i < nParams; ++i)
			{
				const ULONG_PTR v = E.ExceptionInformation[i];
				TCHAR szWhere[MAX_PATH + 64]; szWhere[0] = 0;
				TCHAR szMod[MAX_PATH];
				PBYTE pModBase = 0;
				if (v > 0x10000 && Get_Module_By_Ret_Addr((PBYTE)v, szMod, pModBase))
				{
					_sntprintf(szWhere, MAX_PATH + 63, _T("  = %s+0x") CYS_RVA_FMT,
						::PathFindFileName(szMod), (unsigned __int64)((PBYTE)v - pModBase));
					szWhere[MAX_PATH + 63] = 0;
				}
				_ftprintf(fp, _T("Param[%lu]:  0x") CYS_ADDR_FMT _T("%s\n"),
					(unsigned long)i, CYS_ADDR(v), szWhere);
			}
		}
		break;
	}

}

//*************************************************************
VOID Get_Exception_Info(PEXCEPTION_POINTERS pException, FILE* fp, UINT dwLastError)
//*************************************************************
// Allocate Str[DUMP_SIZE_MAX] and return Str with dump, if !pException - just return call stack in Str.
{
	TCHAR		Module_Name[MAX_PATH];
	PBYTE		Module_Addr;
	HANDLE		hFile;
	FILETIME	Last_Write_Time;
	FILETIME	Local_File_Time;
	SYSTEMTIME	T;
	
	Get_Version_Str(fp);

	_ftprintf(fp, _T("------------------------------------------------------------------------------")NL);
	_ftprintf(fp, _T("Process:  ") );

	GetModuleFileName(NULL, Module_Name, MAX_PATH);
	_ftprintf(fp, _T("%s") NL, Module_Name);

	// If exception occurred.
	if (pException)
	{
		EXCEPTION_RECORD &	E = *pException->ExceptionRecord;
		CONTEXT &			C = *pException->ContextRecord;

		// If module with E.ExceptionAddress found - save its path and date.
		if (Get_Module_By_Ret_Addr((PBYTE)E.ExceptionAddress, Module_Name, Module_Addr))
		{
			_ftprintf(fp, _T("Module:   %s") NL, Module_Name);

			if ((hFile = CreateFile(Module_Name, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING,
				FILE_ATTRIBUTE_NORMAL, NULL)) != INVALID_HANDLE_VALUE)
			{
				if (GetFileTime(hFile, NULL, NULL, &Last_Write_Time))
				{
					FileTimeToLocalFileTime(&Last_Write_Time, &Local_File_Time);
					FileTimeToSystemTime(&Local_File_Time, &T);

					_ftprintf(fp, _T("Date Modified:  %02d/%02d/%d") NL, 
						T.wMonth, T.wDay, T.wYear);
				}
				CloseHandle(hFile);
			}
		}
		else
		{
			_ftprintf(fp, _T("Exception Addr:  ") CYS_ADDR_FMT NL , CYS_ADDR(E.ExceptionAddress));
		}

		_ftprintf(fp, _T("------------------------------------------------------------------------------")NL);

		//加入具体异常解释信息
		CreateExceptionDesc(pException, fp, dwLastError);

		// CYS-CRASHRPT: registers were commented out (the block below was x86-only: C.Eax/C.Ebp
		// do not exist in the x64 CONTEXT). On 18/09 the decisive clue was Rcx = 420C0000420C0000,
		// a Size(35,35) used as a "this" pointer - and it was only reachable by opening the
		// minidump by hand. Write it into the text report.
		_ftprintf(fp, _T("------------------------------------------------------------------------------")NL);
#ifdef _WIN64
		_ftprintf(fp, _T("Registers:") NL);
		_ftprintf(fp, _T("RIP: ") CYS_ADDR_FMT _T("  EFlags: %08X") NL, CYS_ADDR(C.Rip), (UINT)C.EFlags);
		_ftprintf(fp, _T("RAX: ") CYS_ADDR_FMT _T("  RBX: ") CYS_ADDR_FMT _T("  RCX: ") CYS_ADDR_FMT _T("  RDX: ") CYS_ADDR_FMT NL,
			CYS_ADDR(C.Rax), CYS_ADDR(C.Rbx), CYS_ADDR(C.Rcx), CYS_ADDR(C.Rdx));
		_ftprintf(fp, _T("RSI: ") CYS_ADDR_FMT _T("  RDI: ") CYS_ADDR_FMT _T("  RSP: ") CYS_ADDR_FMT _T("  RBP: ") CYS_ADDR_FMT NL,
			CYS_ADDR(C.Rsi), CYS_ADDR(C.Rdi), CYS_ADDR(C.Rsp), CYS_ADDR(C.Rbp));
		_ftprintf(fp, _T("R8 : ") CYS_ADDR_FMT _T("  R9 : ") CYS_ADDR_FMT _T("  R10: ") CYS_ADDR_FMT _T("  R11: ") CYS_ADDR_FMT NL,
			CYS_ADDR(C.R8), CYS_ADDR(C.R9), CYS_ADDR(C.R10), CYS_ADDR(C.R11));
		_ftprintf(fp, _T("R12: ") CYS_ADDR_FMT _T("  R13: ") CYS_ADDR_FMT _T("  R14: ") CYS_ADDR_FMT _T("  R15: ") CYS_ADDR_FMT NL,
			CYS_ADDR(C.R12), CYS_ADDR(C.R13), CYS_ADDR(C.R14), CYS_ADDR(C.R15));
#else
		_ftprintf(fp, _T("Registers:") NL);
		_ftprintf(fp, _T("EAX: %08X  EBX: %08X  ECX: %08X  EDX: %08X") NL, C.Eax, C.Ebx, C.Ecx, C.Edx);
		_ftprintf(fp, _T("ESI: %08X  EDI: %08X  ESP: %08X  EBP: %08X")NL, C.Esi, C.Edi, C.Esp, C.Ebp);
		_ftprintf(fp, _T("EIP: %08X  EFlags: %08X")NL, C.Eip, C.EFlags);
#endif

		// Save the bytes of the faulting instruction (IsBadReadPtr: the code page may be gone).
		if(E.ExceptionAddress && !::IsBadReadPtr(E.ExceptionAddress, 16))
		{
			_ftprintf(fp, _T("Instruction:"));
			for (INT i = 0; i < 16; i++)
				_ftprintf(fp, _T(" %02X"), PBYTE(E.ExceptionAddress)[i]);
			_ftprintf(fp, NL);
		}
	} //if (pException)
	
	_ftprintf(fp, _T("------------------------------------------------------------------------------")NL);

	// Save call stack info.
	_ftprintf(fp, _T("Call Stack:")NL);
	Get_Call_Stack(pException, fp);
} //Get_Exception_Info


BOOL SaveCurrentlyLog(VOID* TheLog, size_t LogSize)
{
	TCHAR szTempFile[MAX_PATH] = {0};
	if (NULL == ::GetModuleFileName(g_hInstance,szTempFile,MAX_PATH))
	{
		memset(szTempFile,0,MAX_PATH);
		memcpy(szTempFile, "C:\\WXC_SML.TXT", strlen("C:\\WXC_SML.TXT"));
	}
	else
	{
		if(TRUE == ::PathRemoveFileSpec(szTempFile))
		{
			strcat(szTempFile, "\\WXC_SML.TXT");
		}
		else
		{
			memset(szTempFile,0,MAX_PATH);
			memcpy(szTempFile, "C:\\WXC_SML.TXT", strlen("C:\\WXC_SML.TXT"));
		}
	}

	FILE* fp = _tfopen(szTempFile, _T("at"));
	if(!fp) return FALSE;

	fwrite("\n操作描述为:", strlen("\n操作描述为:"), 1, fp);
	fwrite(TheLog, LogSize, 1, fp);
	SYSTEMTIME TNow;
	memset(&TNow,0,sizeof(TNow));
	::GetLocalTime(&TNow);
	CHAR strtime[100]={0};
	memset(strtime, 0, 100);
	sprintf(strtime,"\nTime:%d年%d月%d日%d时%d分%d秒\n",TNow.wYear,TNow.wMonth,TNow.wDay,TNow.wHour,TNow.wMinute,TNow.wSecond);
	fwrite(strtime, strlen(strtime), 1, fp);
	fwrite("\n\n\n------------------------------------------------------\n", strlen("\n\n\n------------------------------------------------------\n"), 1, fp);

	fclose(fp); fp = NULL;
	return TRUE;
}

INT_PTR CALLBACK SML_DialogProc(
								HWND hwndDlg,
								UINT uMsg,
								WPARAM wParam,
								LPARAM lParam
								)
{
	switch(uMsg)
	{
	case WM_COMMAND:
		{
			switch(LOWORD(wParam))
			{
			case IDOK:
				{
					CHAR t_strErrorInfo[MAX_ERROR_INFO];
					memset(t_strErrorInfo, 0, MAX_ERROR_INFO);
					GetDlgItemText(hwndDlg, IDC_EDIT_WXC_SML, t_strErrorInfo, MAX_ERROR_INFO);
					SaveCurrentlyLog(t_strErrorInfo, strlen(t_strErrorInfo));
					::DestroyWindow(hwndDlg);
				}
				break;
			case IDCANCEL:
				{
					::DestroyWindow(hwndDlg);
				}
			}
		}
		break;
	}
	return 0;
}
BOOL CreateSmallDumpInfo(PEXCEPTION_POINTERS pException, PTCHAR szSmallFile, UINT dwLastError)
{
	g_szCysSmallFileLong[0] = 0;	// CYS-CRASHRPT: never report a stale path from an earlier crash
	if (!pException) return FALSE;

	//创建基本描述文件
	TCHAR szTempFile[MAX_PATH] = {0};
	if (NULL == ::GetModuleFileName(g_hInstance, szTempFile,MAX_PATH))
	{
		memset(szTempFile,0,MAX_PATH);
		memcpy(szTempFile, "C:\\WXC_SML.TXT", strlen("C:\\WXC_SML.TXT"));
	}
	else
	{
		if(TRUE == ::PathRemoveFileSpec(szTempFile))
		{
			strcat(szTempFile, "\\WXC_SML.TXT");
		}
		else
		{
			memset(szTempFile,0,MAX_PATH);
			memcpy(szTempFile, "C:\\WXC_SML.TXT", strlen("C:\\WXC_SML.TXT"));
		}
	}

	//::GetTempPath(MAX_PATH, szTempDir);

	//TCHAR szTempFile[MAX_PATH] = {0};
	//::GetTempFileName(szTempDir, _T("sml"), MAX_PATH, szTempFile);

	FILE* fp = _tfopen(szTempFile, _T("a+"));
	if(!fp) return FALSE;

	CreateExceptionDesc( pException, fp, dwLastError);

	fclose(fp); fp = NULL;

	// CYS-CRASHRPT: keep the readable absolute path (GetShortPathName below mangles it).
	lstrcpyn(g_szCysSmallFileLong, szTempFile, MAX_PATH);

	if(g_IsFindLuaError)//如果是找异常模式
	{
		HWND HDialog = ::CreateDialog(g_hInstance, MAKEINTRESOURCE(IDD_DIALOG_WXC_SML), g_hMainWnd, SML_DialogProc);
		::ShowWindow(HDialog, SW_SHOW);
	}
	::GetShortPathName(szTempFile, szSmallFile, MAX_PATH);
	// CYS-CRASHRPT: no 8.3 name -> empty buffer, and the old code then reported failure for a
	// file it had just written; tProcessException() returned before writing the minidump at all.
	if(szSmallFile[0] == 0) lstrcpyn(szSmallFile, szTempFile, MAX_PATH);

	return TRUE;
}

BOOL CreateBigInfoFile(PEXCEPTION_POINTERS pException, PTCHAR szBigFile, UINT dwLastError)
{
	g_szCysBigFileLong[0] = 0;		// CYS-CRASHRPT: never report a stale path from an earlier crash
	if (!pException) return FALSE;

	// CYS-CRASHRPT: this used to be GetTempFileName(%TEMP%, "dtl") -> "dtl104.tmp". The 18/09
	// runs DID produce it (with module + Exception Offset inside) but the name said nothing and
	// the folder was the child process's %TEMP%, so everyone concluded "this crash has no dump".
	// It now lands beside WXC_SML.TXT under a name that says what it is.
	TCHAR szTempFile[MAX_PATH] = {0};
	if(!CysBuildCrashPath(_T("detail.txt"), szTempFile, MAX_PATH))
	{
		TCHAR szTempDir[MAX_PATH] = {0};
		::GetTempPath(MAX_PATH, szTempDir);
		::GetTempFileName(szTempDir, _T("dtl"), MAX_PATH, szTempFile);
	}

	FILE* fp = _tfopen(szTempFile, _T("w"));
	if(!fp) return FALSE;

	Get_Exception_Info(pException, fp, dwLastError);

	fclose(fp); fp = NULL;

	lstrcpyn(g_szCysBigFileLong, szTempFile, MAX_PATH);

	::GetShortPathName(szTempFile, szBigFile, MAX_PATH);
	// CYS-CRASHRPT: 8.3 name generation is off on most modern volumes; GetShortPathName then
	// leaves the buffer empty and the old code reported failure for a file it had just written.
	if(szBigFile[0] == 0) lstrcpyn(szBigFile, szTempFile, MAX_PATH);

	return TRUE;
}
//创建DBGHLEP所需要的dmp信息
BOOL CreateDumpHelpFile(PEXCEPTION_POINTERS pException, PTCHAR szDumpFile)
{
	szDumpFile[0] = ' ';
	szDumpFile[1] = 0;
	g_szCysDumpFileLong[0] = 0;

	// If MiniDumpWriteDump() of DbgHelp.dll available.
	// CYS-CRASHRPT: say so in the log instead of returning silently - "there is no dump" must be
	// a statement the report makes, never something a reader infers from an empty folder.
	if (!theDbgHelper.m_pfnMiniDumpWriteDump)
	{
		TDU_Log("CYS-CRASHRPT: no minidump - DBGHELP.DLL/MiniDumpWriteDump unavailable.");
		return FALSE;
	}

	// CYS-CRASHRPT: was GetTempFileName(%TEMP%, "dmp") -> "dmp104.tmp" inside the child's %TEMP%.
	TCHAR szTempFile[MAX_PATH] = {0};
	if(!CysBuildCrashPath(_T("dmp"), szTempFile, MAX_PATH))
	{
		TCHAR szTempDir[MAX_PATH] = {0};
		::GetTempPath(MAX_PATH, szTempDir);
		::GetTempFileName(szTempDir, _T("dmp"), MAX_PATH, szTempFile);
	}

	MINIDUMP_EXCEPTION_INFORMATION	M;

	M.ThreadId = GetCurrentThreadId();
	M.ExceptionPointers = pException;
	M.ClientPointers = 0;

	HANDLE hDump_File = CreateFile(szTempFile,
		GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
	if (hDump_File == INVALID_HANDLE_VALUE)
	{
		TDU_Log("CYS-CRASHRPT: no minidump - cannot create %s (GetLastError=%lu).",
			szTempFile, (unsigned long)::GetLastError());
		return FALSE;
	}

	BOOL bWritten = theDbgHelper.m_pfnMiniDumpWriteDump(GetCurrentProcess(), GetCurrentProcessId(), hDump_File,
		MiniDumpNormal, (pException) ? &M : NULL, NULL, NULL);

	DWORD dwLow = ::GetFileSize(hDump_File, NULL);
	CloseHandle(hDump_File);

	if(!bWritten)
	{
		TDU_Log("CYS-CRASHRPT: MiniDumpWriteDump FAILED for %s (GetLastError=%lu).",
			szTempFile, (unsigned long)::GetLastError());
		return FALSE;
	}

	lstrcpyn(g_szCysDumpFileLong, szTempFile, MAX_PATH);
	TDU_Log("CYS-CRASHRPT: minidump written, %lu bytes.", (unsigned long)dwLow);

	::GetShortPathName(szTempFile, szDumpFile, MAX_PATH);
	if(szDumpFile[0] == 0) lstrcpyn(szDumpFile, szTempFile, MAX_PATH);

	return TRUE;
}

