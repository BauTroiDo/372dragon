#include "StdAfx.h"
#include "..\..\WXEngine\resource.h"
#include "TDException.h"
#include "TDKernel.h"
#include "TDCrashReport.h"
#include "TDUtil.h" // CYS: log the thrown message
#include <stdio.h>
#include "XZip.h"
#include <shlobj.h>

/****************************************\
*										*
*				异常相关				*
*										*
\****************************************/

//--------------------------------------------------
//抛出字符串形式异常
VOID tThrowStringException(LPCTSTR szFmt, ...)
{
	va_list argList;
	va_start(argList, szFmt);

	// CYS-CRTGUARD 20/09/2026: `_vsctprintf` tra **-1** khi chuoi dinh dang khong hop le (vi du
	// co `%n`, hoac so dac ta nhieu hon so doi so). Nguyen van gan thang vao `UINT nSize` nen
	// -1 thanh 0xFFFFFFFF, roi `assign(nSize+1, ' ')` = `assign(0, ' ')` = chuoi RONG, va
	// `_vstprintf` ngay sau do ghi vao bo dem do dai 0 => hong dong. Doc INT, va neu am thi
	// nem nguyen van chuoi dinh dang thay vi dinh dang no.
	const INT nSize = _vsctprintf(szFmt, argList);
	if(nSize < 0)
	{
		va_end(argList);
		TDU_Log("CYS-CRTGUARD: TDThrow voi chuoi dinh dang KHONG HOP LE, nem nguyen van: %s", szFmt);
		throw std::exception(szFmt);
	}

	STRING strMessage;
	strMessage.assign(nSize+1, _T(' '));
	_vstprintf((LPTSTR)&(strMessage[0]), szFmt, argList);
	va_end(argList);

	// CYS: the message of a fatal string exception was lost (the crash report keeps only the SEH code);
	// CYS: keep it in the log before the throw. TDU_Log is bounded and never throws.
	TDU_Log("TDThrow: %s", strMessage.c_str());
	throw std::exception(strMessage.c_str());
}

VOID tThrowAssertException(LPCTSTR szFileName, INT nFileLine, LPCTSTR pExpr)
{
	const char *szAssertFmt = 
					_T("Assert  \r\n")
					_T("\r\n")
					_T("File:      %s\r\n")
					_T("Line:      %d\r\n")
					_T("Expr:      %s\r\n");

	UINT nSize = _sctprintf(szAssertFmt,
					szFileName, nFileLine, pExpr);

	STRING strMessage;
	strMessage.assign(nSize+1, _T(' '));
	_stprintf((LPTSTR)&(strMessage[0]), szAssertFmt, 
		szFileName, nFileLine, pExpr);

	throw std::exception(strMessage.c_str());
}

//--------------------------------------------------
//分析SEH数据
VOID tProcessException(PEXCEPTION_POINTERS pException, bool bRunCrashReport) throw()
{
	//保存最后的错误代码
	UINT	dwLastError = ::GetLastError();
	if(!pException) return;

	// CYS-CRASHRPT 19/09/2026: the three artifacts used to be chained with early returns, so a
	// failure writing either TEXT file skipped the MINIDUMP - the single most valuable artifact -
	// without a word. Write all three unconditionally, then index them.
	//生成基本描述文件
	TCHAR szSmallInfoFile[MAX_PATH] = {0};
	BOOL bSmall = CreateSmallDumpInfo(pException, szSmallInfoFile, dwLastError);

	//生成完整表述文件
	TCHAR szBigInfoFile[MAX_PATH] = {0};
	BOOL bBig = CreateBigInfoFile(pException, szBigInfoFile, dwLastError);

	//生成dump报告
	TCHAR szDumpFile[MAX_PATH] = {0};
	CreateDumpHelpFile(pException, szDumpFile);

	// CYS-CRASHRPT: name every artifact in WXClient.log. On 18/09 the minidump and the call stack
	// existed from the very first reproduction and nobody knew, because nothing pointed at them.
	CysReportCrashArtifacts();

	if(!bSmall || !bBig) return;

	if(bRunCrashReport)
	{
		//寻找CrashReport
		TCHAR szCrashReportFile[MAX_PATH] = {0};
		::GetModuleFileName(NULL, szCrashReportFile, MAX_PATH);
		::PathRemoveFileSpec(szCrashReportFile);
		::PathAppend(szCrashReportFile, _T("CrashReport.exe"));

		TCHAR szCmdLine[1024] = {0};
		_sntprintf(szCmdLine, 1024, _T("%s \"%s\" \"%s\" \"%s\""), 
			szCrashReportFile, 
			szSmallInfoFile, szBigInfoFile, szDumpFile);

		//启动CrashReport
		STARTUPINFO si;
		PROCESS_INFORMATION pi;
		ZeroMemory(&si,sizeof(STARTUPINFO));
		ZeroMemory(&pi,sizeof(PROCESS_INFORMATION));
		si.cb = sizeof(STARTUPINFO);
		si.dwFlags = STARTF_USESHOWWINDOW;
		si.wShowWindow = SW_SHOWNORMAL;

		::CreateProcess( NULL, szCmdLine, NULL, NULL, FALSE,CREATE_DEFAULT_ERROR_MODE, NULL, NULL, &si, &pi);
	}
}

void tCenterDlg(HWND hDlg)
{
	int x,y;
	int w,h;
	
	RECT rect;

	GetWindowRect(hDlg,&rect);

	w = rect.right - rect.left;
	h = rect.bottom - rect.top;

	x = ( GetSystemMetrics(SM_CXMAXIMIZED) - w ) /2;
	y = ( GetSystemMetrics(SM_CYMAXIMIZED) - h ) /2;

	MoveWindow(hDlg,x,y,w,h,TRUE);
}

//------------------------------------------------------------------------------------------
//

//global 
STRING g_strExceptionTitle;
STRING g_strExceptionContents;
STRING g_strDumpFile;
CHAR   g_szWinDbg[MAX_PATH];

bool tIsWinDbgEnable(void)
{
	//寻找WinDbg
	DWORD dwType, dwSize = MAX_PATH;
	if(ERROR_SUCCESS != ::SHGetValue( HKEY_CURRENT_USER, 
		"Software\\Microsoft\\DebuggingTools", "WinDbg", &dwType, g_szWinDbg, &dwSize) )
	{
		return false;
	}

	return true;
}

void tSendInnerCrashReport(HWND hInnerWnd)
{
	//-------------------------------------------------------
	CHAR szCurrentDir[MAX_PATH] = {0};
	::GetCurrentDirectory(MAX_PATH, szCurrentDir);

	CHAR szCrashFile[MAX_PATH] = {0};
	SYSTEMTIME timeNow;
	::GetLocalTime(&timeNow);
	// CYS-CRASHRPT 19/09/2026: the format had FOUR %02d for FIVE arguments (MSVC said so all along:
	// "warning C4474: '_snprintf' : too many arguments passed for format string"), so the seconds
	// were dropped and two crash reports sent in the same MINUTE overwrote each other's zip.
	// Same design mistake as the dmp/dtl temp names this branch just fixed - reusing the name of a
	// piece of evidence - now the second time in this one file. Year included for good measure.
	_snprintf(szCrashFile, MAX_PATH, "crash%04d%02d%02d_%02d%02d%02d.zip",
		timeNow.wYear, timeNow.wMonth, timeNow.wDay, timeNow.wHour, timeNow.wMinute, timeNow.wSecond);
	szCrashFile[MAX_PATH - 1] = 0;

	//-------------------------------------------------------
	CHAR szLocalFile[MAX_PATH] = {0};
	strncpy(szLocalFile, szCurrentDir, MAX_PATH);
	PathAppend(szLocalFile, szCrashFile);
	HZIP hz = CreateZip((void *)szLocalFile, 0, ZIP_FILENAME);
	if(!hz) 
	{
		MessageBox(hInnerWnd, "Create Crash.zip error!", "CrashReport", MB_OK|MB_ICONSTOP);
		return;
	}

	ZipAdd(hz, "dump.dmp", (void *)g_strDumpFile.c_str(), 0, ZIP_FILENAME);

	CHAR szLogFile[MAX_PATH];

	strncpy(szLogFile, szCurrentDir, MAX_PATH);
	PathAppend(szLogFile, "WXRender.log");
	ZipAdd(hz, "WXRender.log", (void *)szLogFile, 0, ZIP_FILENAME);

	strncpy(szLogFile, szCurrentDir, MAX_PATH);
	PathAppend(szLogFile, "UISystem.log");
	ZipAdd(hz, "WXUISystem.log", (void *)szLogFile, 0, ZIP_FILENAME);

	CloseZip(hz);

	//-------------------------------------------------------
	BROWSEINFO binfo; ZeroMemory(&binfo, sizeof(BROWSEINFO));
	binfo.hwndOwner = hInnerWnd;
	binfo.pidlRoot = NULL;
	binfo.ulFlags = BIF_NEWDIALOGSTYLE|BIF_RETURNONLYFSDIRS;
	binfo.pszDisplayName = NULL;
	binfo.lpszTitle = "选择一个目录用以保存数据文件";

	LPITEMIDLIST pRetFold = ::SHBrowseForFolder(&binfo);
	if(!pRetFold) return;

	CHAR szReturn[MAX_PATH] = {0};
	::SHGetPathFromIDList(pRetFold, szReturn);

	//-------------------------------------------------------
	CHAR szSaveAs[MAX_PATH] = {0};
	strncpy(szSaveAs, szReturn, MAX_PATH);
	PathAppend(szSaveAs, szCrashFile);
	CopyFile(szLocalFile, szSaveAs, FALSE);
	
}

BOOL CALLBACK _InnerExceptionDlgProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
	case WM_CTLCOLORSTATIC:
		{
			HWND hStatic = (HWND)lParam;
			static HBRUSH s_YellowBrush = 0;

			if(hStatic == GetDlgItem(hDlg, IDC_STATIC_TYPE))
			{
				SetBkMode((HDC)wParam, TRANSPARENT);
				SetBkColor((HDC)wParam, RGB(255, 255, 0));

				if(0==s_YellowBrush)
				{
					s_YellowBrush = ::CreateSolidBrush(RGB(255, 255, 0));
				}
				return (BOOL)(INT)(INT_PTR)s_YellowBrush;
			}
			else return FALSE;
		}
		break;

	case WM_INITDIALOG :
		{	
			tCenterDlg(hDlg);
			::SetWindowText(::GetDlgItem(hDlg, IDC_STATIC_TYPE), g_strExceptionTitle.c_str());

			FILE* fp = fopen(g_strExceptionContents.c_str(), "rb");
			if(fp)
			{
				CHAR szTemp[1024] = {0};
				fread(szTemp, sizeof(CHAR), 1024,fp);
				fclose(fp); fp = NULL;
				::SetWindowText(::GetDlgItem(hDlg, IDC_EDIT_CONTENTS), szTemp);
			}

			//::EnableWindow(::GetDlgItem(hDlg, IDC_BUTTON_DEBUG), tIsWinDbgEnable());
		}
		break;

	case WM_COMMAND:
		{
			switch(LOWORD(wParam))
			{
			case IDC_BUTTON_DEBUG:
				EndDialog(hDlg, 3);
				break;
			case IDC_BUTTON_SEND:
				tSendInnerCrashReport(hDlg);
				EndDialog(hDlg, 2);
				break;
			case IDC_BUTTON_THROW:
				EndDialog(hDlg, 1);
				break;
			case IDC_BUTTON_IGNORE:
				EndDialog(hDlg, 0);
				break;
			}
		}
		break;

	case WM_CLOSE:
		{	
			EndDialog(hDlg, 0);
			DestroyWindow( hDlg );
		}
		break;
	default:
		return FALSE;
	}

	return TRUE;
}

INT tProcessInnerException(PEXCEPTION_POINTERS pException, HWND hParentWnd, LPCTSTR szTitle)
{
	DWORD dwLastError = ::GetLastError();

	//生成基本描述文件
	TCHAR szSmallInfoFile[MAX_PATH] = {0};
	if(!CreateSmallDumpInfo(pException, szSmallInfoFile, dwLastError))
	{
		return 0;
	}

	//生成dump报告
	TCHAR szDumpFile[MAX_PATH] = {0};
	CreateDumpHelpFile(pException, szDumpFile);

	CysReportCrashArtifacts();		// CYS-CRASHRPT: same index for the in-process handler

	g_strExceptionTitle = szTitle;
	g_strExceptionContents = szSmallInfoFile;
	g_strDumpFile = szDumpFile;

	return (INT)::DialogBox(g_hInstance, MAKEINTRESOURCE(IDD_DIALOG_INNER_EXCEPTION), 
				hParentWnd, (DLGPROC)_InnerExceptionDlgProc );
}
