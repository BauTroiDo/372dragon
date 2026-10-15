#include <windows.h>
#include <stdio.h>
#include <stdarg.h>
static unsigned appended=0, appendFailed=0, fallbackOpened=0, bothFailed=0;

// TDUtil.cpp:12..29, unchanged open/format/close sequence; counters observe opens.
void (TDU_Log)(LPCSTR pszFmt, ...)
{
    FILE* fp = fopen(".\\WXClient.log", "a");
    if (!fp) { ++appendFailed; fp = fopen(".\\WXClient.log", "w"); if (fp) ++fallbackOpened; }
    else ++appended;
    if (!fp) { ++bothFailed; return; }
    CHAR szTemp[1024] = {0};
    va_list ptr; va_start(ptr, pszFmt);
    _vsnprintf((char*)szTemp, 1024, pszFmt, ptr);
    va_end(ptr);
    SYSTEMTIME timeNow; ::GetLocalTime(&timeNow);
    fprintf(fp, "[%02d_%02d:%02d:%02d]: %s\n", timeNow.wDay, timeNow.wHour, timeNow.wMinute, timeNow.wSecond, szTemp);
    fclose(fp);
}

int main()
{
    const DWORD start=GetTickCount(); unsigned attempted=0;
    char padding[513]; for (int i=0;i<512;++i) padding[i]='x'; padding[512]=0;
    while (GetTickCount()-start<8000) { TDU_Log("SEQ=%u %s", ++attempted, padding); }
    FILE* stats=fopen("stats.json","w");
    fprintf(stats,"{\"attempted\":%u,\"appended\":%u,\"append_failed\":%u,\"fallback_opened_truncates\":%u,\"both_failed_drops\":%u}\n", attempted,appended,appendFailed,fallbackOpened,bothFailed);
    fclose(stats);
}
