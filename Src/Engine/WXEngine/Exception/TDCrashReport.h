/************************************************************\
*          程序崩溃时保存信息并启动CrachReport               *
*                                                            *
*                                                            *
*   ref from http://www.codeproject.com/tools/minidump.asp   *
*       By Vladimir Sedach                                   *
*                                                            *
\************************************************************/

#pragma optimize("y", off)		//generate stack frame poINTers for all functions - same as /Oy- in the project

BOOL CreateSmallDumpInfo(PEXCEPTION_POINTERS pException, PTCHAR szSmallFile, UINT dwLastError);
BOOL CreateBigInfoFile(PEXCEPTION_POINTERS pException, PTCHAR szBigFile, UINT dwLastError);

BOOL CreateDumpHelpFile(PEXCEPTION_POINTERS pException, PTCHAR szDumpFile);

// CYS-CRASHRPT 19/09/2026: print the ABSOLUTE path of the summary / detail / minidump written by
// the three calls above into the main log (WXClient.log) and append the same index to
// WXC_SML.TXT. Call it once, after all three, so a crash can never again be believed to have
// produced "no dump" (Timeline\handoff\qlog-crash.md muc 5.2).
VOID CysReportCrashArtifacts(VOID);
