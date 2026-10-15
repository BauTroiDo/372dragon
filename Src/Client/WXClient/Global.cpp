#include "StdAfx.h"
#include "Global.h"

//数据核心
tKernel			g_theKernel;

//主窗口
HWND			g_hMainWnd			= NULL;
//当前主程序模块句柄
HINSTANCE		g_hInstance			= NULL;

//当前版本号
const CHAR		VERSION_INFO[]		= "0.0.0005";

//标题
// CYS 17/09/2026: tên trò chơi theo yêu cầu người dùng. Giữ THUẦN ASCII: chuỗi này là literal GBK
// (/execution-charset:.936) và được đổi sang UTF-16 bằng code page 936 trước khi đặt tiêu đề cửa sổ.
const CHAR		GAME_TITLE[]		="Dai Viet";
