#include "StdAfx.h"
#include "CysTextColour.h"
#include "UIGlobal.h"
#include "UIString.h"
#include "CysUiDictionary.h"
#include "CEGUISystem.h"
#include "CEGUIResourceProvider.h"
#include "CysPackedFormat.h"	// CYS: decode Format metadata before text validation
#include "CysDialogVars.h"	// CYS-QUEST: $N and the other CY dialogue variables
#include "CysInfoLink.h"	// CYS-INFOLINK: CY #{_INFOAIM..} / #{_INFOUSEITEM..} coordinate hyperlinks
#include "TDKernel.h"
#include "TDObjectSystem.h"
#include "TDException.h"
#include "TDDataBase.h"
#include "TDDBC_Struct.h"
#include "Core/utf.h"
#include "TDVariable.h"		// CYS: System_CodePage
#include "CEGUILogger.h"	// CYS: log the active UI code page
#include "CysCrtGuard.h"	// CYS-CRTGUARD: CysFmt_HasFatal - chan `%n` truoc _vsnprintf
#include "TDUtil.h"			// CYS-CRTGUARD: TDU_Log
#include <set>				// CYS-CRTGUARD: ghi log mot lan moi khoa (mau ef3c2b9e)

struct AUTO_LOCALE_CONVERT
{
	AUTO_LOCALE_CONVERT()
	{
		std::locale langLocale("");
		old = std::locale::global(langLocale);
	}
	~AUTO_LOCALE_CONVERT()
	{
		std::locale::global(old);
	}

	std::locale old;
};

CUIStringSystem* CUIStringSystem::s_pMe = NULL;

// CYS: UI text code page, see UIString.h. 936 (0.85 behaviour) until Init() reads System_CodePage.
UINT CUIStringSystem::s_nCodePage = 936;

// CYS: copy the well-formed UTF-8 of strIn to strOut and drop malformed bytes (stray continuation bytes, overlong
// forms, surrogates, a sequence cut short by a byte-limited field). CEGUI::String decodes UTF-8 without checking,
// so nothing malformed may reach it. bText also drops C0 controls except \t \r \n, as the 0.85 GBK check did.
// Returns FALSE when something was dropped. strIn and strOut may be the same object.
static BOOL _cysFilterUtf8(const STRING& strIn, STRING& strOut, BOOL bText)
{
	STRING strRet;
	strRet.reserve(strIn.size() + 1);
	BOOL bClean = TRUE;
	const STRING::size_type nSize = strIn.size();
	for(STRING::size_type i = 0; i < nSize; )
	{
		const BYTE c = (BYTE)strIn[i];
		if(c < 0x80)
		{
			if(!bText || c >= 0x20 || c == '\r' || c == '\n' || c == '\t') strRet += (CHAR)c;
			else bClean = FALSE;
			++i;
			continue;
		}

		STRING::size_type nLen = 0;
		UINT cp = 0, cpMin = 0;
		if(c >= 0xC2 && c <= 0xDF)		{ nLen = 2; cp = c & 0x1F; cpMin = 0x80; }
		else if(c >= 0xE0 && c <= 0xEF)	{ nLen = 3; cp = c & 0x0F; cpMin = 0x800; }
		else if(c >= 0xF0 && c <= 0xF4)	{ nLen = 4; cp = c & 0x07; cpMin = 0x10000; }

		BOOL bOk = (nLen != 0 && nLen <= nSize - i);
		for(STRING::size_type k = 1; bOk && k < nLen; ++k)
		{
			const BYTE cc = (BYTE)strIn[i + k];
			if((cc & 0xC0) != 0x80) bOk = FALSE;
			else cp = (cp << 6) | (cc & 0x3F);
		}
		if(bOk && (cp < cpMin || cp > 0x10FFFF || (cp >= 0xD800 && cp <= 0xDFFF))) bOk = FALSE;

		if(bOk)	{ strRet.append(strIn, i, nLen); i += nLen; }
		else	{ bClean = FALSE; ++i; }	// drop one byte, resynchronise on the next one
	}
	strOut.swap(strRet);
	return bClean;
}

// CYS: see UIString.h.
STRING CUIStringSystem::FromGbkLiteral(const CHAR* szGbk)
{
	if(!szGbk) return STRING();
	if(!IsUTF8()) return STRING(szGbk);

	const INT nWide = ::MultiByteToWideChar(936, 0, szGbk, -1, NULL, 0);
	if(nWide <= 0) return STRING(szGbk);
	std::wstring strWide((size_t)nWide, L'\0');
	::MultiByteToWideChar(936, 0, szGbk, -1, &strWide[0], nWide);

	const INT nUtf8 = ::WideCharToMultiByte(CP_UTF8, 0, strWide.c_str(), -1, NULL, 0, NULL, NULL);
	if(nUtf8 <= 0) return STRING(szGbk);
	STRING strUtf8((size_t)nUtf8, '\0');
	::WideCharToMultiByte(CP_UTF8, 0, strWide.c_str(), -1, &strUtf8[0], nUtf8, NULL, NULL);
	strUtf8.resize((size_t)nUtf8 - 1);	// the -1 length form also wrote the terminating NUL
	return strUtf8;
}
CUIStringSystem::CUIStringSystem()
{
	s_pMe = this;
}

CUIStringSystem::~CUIStringSystem()
{
}

VOID CUIStringSystem::Init(LPCTSTR szStringDBC)
{
	//----------------------------------------------------
	// CYS: System_CodePage selects the encoding of all UI text (dictionary, Lua, server strings); 65001 = UTF-8
	// (Docs/08 1.1/1.8, replaces the three UI_CEGUI code-page patches). Logged to CEGUI.log for verification.
	{
		BOOL bHave = FALSE;
		const INT nCodePage = g_pVariableSystem ? g_pVariableSystem->GetAs_Int("System_CodePage", &bHave) : 0;
		s_nCodePage = (bHave && nCodePage > 0) ? (UINT)nCodePage : 936;

		CHAR szLog[128] = {0};
		_snprintf(szLog, sizeof(szLog) - 1, "CUIStringSystem: UI text code page %u (%s)", s_nCodePage,
			IsUTF8() ? "UTF-8, passed through" : "legacy MBCS, GBK checks");
		CEGUI::Logger::getSingleton().logEvent((CEGUI::utf8*)szLog);
	}

	//----------------------------------------------------
	//字符串字典
	tDataBaseSystem* pUIDBC = (tDataBaseSystem*)g_pKernel->GetNode("bin\\dbc");
	TDAssert(pUIDBC);
	CEGUI::ResourceProvider* provider = CEGUI::System::getSingleton().getResourceProvider();
	CEGUI::RawDataContainer data;
	provider->loadRawDataContainer("StrDictionary.txt", data, "General");
	try {
		const CysUiDictionary::Table dictionary = CysUiDictionary::Parse(
			std::string((const char*)data.getDataPtr(), data.getSize()), s_nCodePage);
		m_theDirectionary.clear();
		for (const auto& entry : dictionary.entries)
			m_theDirectionary[entry.first] = entry.second;
		CHAR message[192] = {0};
		_snprintf(message, sizeof(message) - 1,
			"CYS StrDictionary: rows=%zu duplicates=%zu source=%u display=%u",
			dictionary.rows, dictionary.duplicates, dictionary.sourceCodePage, s_nCodePage);
		CEGUI::Logger::getSingleton().logEvent(message);
	} catch (...) {
		provider->unloadRawDataContainer(data);
		throw;
	}
	provider->unloadRawDataContainer(data);

	//系统关键字
	//m_theDirectionary[UKS_PLAYERNAME] = 
	
	//---------------------------------
	//字符串字典id转化
	DIRECTIONARY::iterator it;
	for(it=m_theDirectionary.begin(); it!=m_theDirectionary.end(); it++)
	{
		STRING strOut;
		ParserString_Prebuild(it->second, strOut);

		it->second = strOut;
	}
	//------------------------------------------------

	//聊天模板创建
	GenerateTalkTemplateTable();

	// 表情映射
	//加载所有ui
	const tDataBase* pDBC = pUIDBC->GetDataBase(DBC_CODE_CONVERT);
	for(INT i=0; i<(INT)pDBC->GetRecordsNum(); i++)
	{
		const _DBC_CODE_CONVERT* pLine = (const _DBC_CODE_CONVERT*)((tDataBase*)pDBC)->Search_LineNum_EQU(i);
		CEGUI::utf32 dwValue = 0;
		sscanf( pLine->szCode, "%8X", &dwValue );
		m_mapCodeConvertTable[ pLine->nID ] = dwValue ;
	}

	//------------------------------------------------
	// 过滤词数组构造
	const tDataBase* pDBCfl = pUIDBC->GetDataBase(DBC_TALK_FILTER);
	for(INT i=0; i<(INT)pDBCfl->GetRecordsNum(); i++)
	{
		const _DBC_TALK_FILTER* pLine = (const _DBC_TALK_FILTER*)((tDataBase*)pDBCfl)->Search_LineNum_EQU(i);
		m_vecFilterTable.push_back(pLine->szString);
	}

	//------------------------------------------------
	// 完全匹配过滤表构造
	GenerateFullCompareTable();
}

std::pair< BOOL, CUIStringSystem::DIRECTIONARY::iterator > CUIStringSystem::_IsValidDictionKey(const STRING& strKey)
{
	DIRECTIONARY::iterator it = m_theDirectionary.find(strKey);
	if(it == m_theDirectionary.end()) return std::make_pair(false, it);
	else return std::make_pair(true, it);
}

// Prebuild转化：主要是从字典和系统级字符串中查找
VOID CUIStringSystem::ParserString_Prebuild(const STRING& strSource, STRING& strOut)
{
	const CHAR KeyParserBegin	= '{';
	const CHAR KeyParserMiddle	= '=';
	const CHAR KeyParserEnd		= '}';

	STRING::size_type nValidBegin = 0;
	strOut = "";

	do
	{
		if(nValidBegin >= strSource.size()) break;

		STRING::size_type nValidEnd = strSource.find(KeyParserBegin, nValidBegin);

		//最后一段正常值
		if(nValidEnd == STRING::npos) 
		{
			strOut += strSource.substr(nValidBegin);

			break;
		}

		//加入正常值
		if(nValidEnd != nValidBegin) 
		{
			strOut += strSource.substr(nValidBegin, nValidEnd-nValidBegin);
		}

		STRING::size_type nKeyStart = nValidEnd+1;									//"{"
		STRING::size_type nKeyMiddle = strSource.find(KeyParserMiddle, nKeyStart);	//"="
		STRING::size_type nKeyEnd = strSource.find(KeyParserEnd, nKeyStart);		//"}"
		
		//合法的Key描述
		if(nKeyEnd != STRING::npos && nKeyMiddle != STRING::npos && nKeyEnd > nKeyMiddle)
		{
			STRING strKey_Left = strSource.substr(nKeyStart, nKeyMiddle-nKeyStart);
			STRING strKey_Right = strSource.substr(nKeyMiddle+1, nKeyEnd-nKeyMiddle-1);

			if(strKey_Left == "ID")
			{
				std::pair< BOOL, DIRECTIONARY::iterator > isValidKey = _IsValidDictionKey(strKey_Right);
				//找到key
				if(isValidKey.first)
				{
					//加入从key转化过来的值
					strOut += isValidKey.second->second;

					nValidBegin = nKeyEnd+1;
					continue;
				}
			}
		}
		strOut += strSource.substr(nValidEnd, nKeyEnd-nValidEnd);
		nValidBegin = nKeyEnd;
	}while(true);
}

//对MBCS码字符串进行合法检测，剔除非法字符，例如半个汉字
/*
|
|	使用GBK标准
|
|	Windows95及后续版本中文版支持GBK。
|	GB2312的EUC编码范围是第一字节0xA1~0xFE(实际只用到0xF7)，第
|	二字节0xA1~0xFE。GBK对此进行扩展。第一字节为0x81~0xFE，第二
|	字节分两部分，一是0x40~0x7E，二是0x80~0xFE。其中和GB2312相
|	同的区域，字完全相同。扩展部分大概是按部件(部首)和笔顺(笔画)
|	从GB13000中取出再排列入GBK中。因此GBK并不是GB13000，虽然两者
|	字汇相同，但编码体系不同。一个是ISO2022系列不等长编码，一个
|	是等长编码，并且编码区域也不同。注意到GBK实际上不是国家标准。
|	在此之前有一个GB2312基本集，在它之上是一个技术更先进的GB13000。
|	GBK只是一种过渡和扩展规范。所以在Unicode里有GB2312->Unicode,
|	GB12345->Unicode的转换表格，而没有GBK->Unicode转换表格。只有
|	Microsoft制作的Code Page 936(CP936.TXT)可以算作GBK->Unicode
|	转换表格。但要注意这是一个商业公司制作的文件，而不是国家或
|	国际标准组织制作的，有可能与标准有不一致的地方。
|
|
*/
BOOL CUIStringSystem::_CheckStringCode(const STRING& strIn, STRING& strOut)
{
	// CYS: UTF-8 text is checked as UTF-8 - the GBK rules below cut most Vietnamese off with "<ERROR>".
	if(IsUTF8()) return _cysFilterUtf8(strIn, strOut, TRUE);

	const BYTE byANSIBegin		= 0X20;
	const BYTE byANSIEnd		= 0X80;

	const BYTE by1GBKBegin	= 0X81;
	const BYTE by1GBKEnd	= 0XFE;

	const BYTE by2GBKBegin1	= 0X40;
	const BYTE by2GBKEnd1	= 0X7E;
	const BYTE by2GBKBegin2	= 0X80;
	const BYTE by2GBKEnd2	= 0XFE;

	const CHAR * const szERROR = "<ERROR>";

	//预先分配好内存
	INT nSourSize = (INT)strIn.size();
	strOut.reserve(nSourSize+1);
	strOut = "";

	for(INT i=0; i<nSourSize; )
	{
		BYTE byChar = strIn[i];

		//标准ANSI英文字符
		if(byChar >= byANSIBegin && byChar <= byANSIEnd || byChar == '\r' || byChar == '\n' || byChar == '\t')
		{
			strOut += byChar;
			i++; 
			continue;
		}
		//汉字第一个字节
		else if(byChar >= by1GBKBegin && byChar <= by1GBKEnd)
		{
			//半个汉字
			if(i+1 == nSourSize) goto CHECKSTRING_ERROR;

			//取出第二个字节
			BYTE byNext = strIn[++i];
			if(	!( byNext >= by2GBKBegin1 && byNext <= by2GBKEnd1 || byNext >= by2GBKBegin2 && byNext <= by2GBKEnd2) )
			{
				//非法的汉字
				goto CHECKSTRING_ERROR;
			}

			//加入完整的汉字
			CHAR szTemp[8];
			szTemp[0] = byChar;
			szTemp[1] = byNext;
			szTemp[2] = 0;
			strOut += szTemp;

			i++;
			continue;
		}
		else goto CHECKSTRING_ERROR;
	}
	return TRUE;

CHECKSTRING_ERROR:
	strOut += szERROR;
	return FALSE;
}

//对文字串中出现的非法字符进行过滤
BOOL CUIStringSystem::_CheckStringFilter(const STRING& strIn)
{
	size_t allsize = m_vecFilterTable.size();
	for(INT i = 0; i < (INT)allsize; ++i)
	{
		if(STRING::npos != strIn.find(m_vecFilterTable[i]))	return FALSE; //发现非法字符串
	}

	return TRUE;
}

//完全匹配过滤
BOOL CUIStringSystem::_CheckStringFullCompare(const STRING& strIn, const STRING& strFilterType, BOOL bUseAllTable)
{
	BOOL bFind = FALSE;

	FULLCMP_MAP::iterator it = m_fullCompareTable.find("all");
	if(bUseAllTable && it != m_fullCompareTable.end())
	{
		UI_FULLCMP_TEMPLATE& strVec = it->second;
		if(strVec.find(strIn) != strVec.end()) bFind = TRUE;
	}

	it = m_fullCompareTable.find(strFilterType);
	if(!bFind && it != m_fullCompareTable.end())
	{
		UI_FULLCMP_TEMPLATE& strVec = it->second;
		if(strVec.find(strIn) != strVec.end()) bFind = TRUE;
	}

	return !bFind;
}

// 运行时转化
// 特殊表情符转化，把后面的字符转化成utf32，并且把string也转化成utf32
VOID CUIStringSystem::ParserString_Runtime(const STRING& strSourceNotCheck, CEGUI::String& strOutUtf32)
{

	return ParserString_RuntimeNew(strSourceNotCheck, strOutUtf32);

	const CHAR KeyParserBegin	= '{';
	const CHAR KeyParserMiddle	= '=';
	const CHAR KeyParserEnd		= '}';

	STRING::size_type nValidBegin = 0;
	STRING strOutMBCS = "";

	//检查字符串合法性
	STRING strSource;
	_CheckStringCode(strSourceNotCheck, strSource);
	
	//过滤聊天信息中的非法信息
	if(FALSE == _CheckStringFilter(strSource))
		strSource = FromGbkLiteral("#R请注意你的言辞！！"); // CYS: GBK literal -> UI code page

	do
	{
		if(nValidBegin >= strSource.size()) break;

		STRING::size_type nValidEnd = strSource.find(KeyParserBegin, nValidBegin);

		//最后一段正常值
		if(nValidEnd == STRING::npos) 
		{
			strOutMBCS = strSource.substr(nValidBegin);

			std::string strTemp;
			CUIStringSystem::mbcs_to_utf8(strOutMBCS, strTemp);
			strOutUtf32 += (CEGUI::String)(CEGUI::utf8*)(strTemp.c_str());
			break;
		}

		//加入正常值
		if(nValidEnd != nValidBegin) 
		{
			strOutMBCS = strSource.substr(nValidBegin, nValidEnd-nValidBegin);

			std::string strTemp;
			CUIStringSystem::mbcs_to_utf8(strOutMBCS, strTemp);
			strOutUtf32 += (CEGUI::String)(CEGUI::utf8*)(strTemp.c_str());
		}

		STRING::size_type nKeyStart = nValidEnd+1;									//"{"
		STRING::size_type nKeyMiddle = strSource.find(KeyParserMiddle, nKeyStart);	//"="
		STRING::size_type nKeyEnd = strSource.find(KeyParserEnd, nKeyStart);		//"}"
		
		//合法的Key描述
		if(nKeyEnd != STRING::npos && nKeyMiddle != STRING::npos && nKeyEnd > nKeyMiddle)
		{
			STRING strKey_Left = strSource.substr(nKeyStart, nKeyMiddle-nKeyStart);
			STRING strKey_Right = strSource.substr(nKeyMiddle+1, nKeyEnd-nKeyMiddle-1);

			if(strKey_Left == "ID")
			{
				std::pair< BOOL, DIRECTIONARY::iterator > isValidKey = _IsValidDictionKey(strKey_Right);
				//找到key
				if(isValidKey.first)
				{
					//加入从key转化过来的值
					strOutMBCS += isValidKey.second->second;

					nValidBegin = nKeyEnd+1;

					std::string strTemp;
					CUIStringSystem::mbcs_to_utf8(strOutMBCS, strTemp);
					strOutUtf32 += (CEGUI::String)(CEGUI::utf8*)(strTemp.c_str());

					strOutMBCS = "";
					continue;
				}
			}
			else if(strKey_Left == "PIC") // 表情动画
			{
				// 如果已经定义了
			/*	CODE_CONVERT::iterator  pos = m_mapCodeConvertTable.find( strKey_Right );
//				if( pos != m_mapCodeConvertTable.end() )
				{
					CEGUI::utf32 val = atoi(strKey_Right.c_str());
					val |= 0xFA000000;
					strOutUtf32 += val;
					nValidBegin = nKeyEnd + 1;
					continue;
				}*/
			}
			else if( strKey_Left == "COL" ) // 字体颜色
			{
				CEGUI::utf32 val = 0;
				sscanf( strKey_Right.c_str(), " %8X", &val);
				val = 0xFB000000 | ( val & 0x00FFFFFF );
				strOutUtf32 += val;
				nValidBegin = nKeyEnd + 1;
				continue;
			}
			else if( strKey_Left == "BAK" ) // 字体背景色
			{
				CEGUI::utf32 val = 0;
				sscanf( strKey_Right.c_str(), " %8X", &val);
				val = 0xFC000000 | ( val & 0x00FFFFFF );
				strOutUtf32 += val;
				nValidBegin = nKeyEnd + 1;
				continue;
			}
		}
		strOutMBCS = strSource.substr(nValidEnd, nKeyEnd-nValidEnd);

		std::string strTemp;
		CUIStringSystem::mbcs_to_utf8(strOutMBCS, strTemp);
		strOutUtf32 += (CEGUI::String)(CEGUI::utf8*)(strTemp.c_str());

		nValidBegin = nKeyEnd;
	}while(true);
	
}

// CYS: distinguish a missing dictionary key from a valid empty value.
bool CUIStringSystem::ResolvePackedFormat(void* context, const std::string& key, std::string& text)
{
	CUIStringSystem* self = static_cast<CUIStringSystem*>(context);
	const DIRECTIONARY::const_iterator found = self->m_theDirectionary.find(key);
	if(found == self->m_theDirectionary.end()) return false;
	text = found->second;
	return true;
}

// CYS-QUEST: g_pObjectSystem + UI dictionary as the CY dialogue variable source.
namespace
{
	class CysUiTalkVars : public CysDialogVars::Provider
	{
	public:
		typedef bool (*Resolver)(void*, const std::string&, std::string&);
		CysUiTalkVars(Resolver resolve, void* context) : m_resolve(resolve), m_context(context) {}
		virtual std::string Name(int who) { LPCTSTR s = g_pObjectSystem->GetTalkName(who); return s ? s : ""; }
		virtual int Sex(int who) { return g_pObjectSystem->GetTalkSex(who); }
		virtual std::string UserString() { LPCTSTR s = g_pObjectSystem->GetTalkUserString(); return s ? s : ""; }
		virtual bool Lookup(const std::string& key, std::string& value) { return m_resolve(m_context, key, value); }
	private:
		Resolver m_resolve;
		void* m_context;
	};
}

VOID CUIStringSystem::ParserString_RuntimeNew(const STRING& strSourceNotCheck, CEGUI::String& strOutUtf32)
{
	/*
	#R		表示后面的字体为红色(red)
	#G		表示后面的字体为绿色(green)
	#B		表示后面的字体为蓝色(blue)
	#K		表示后面的字体为黑色(black)
	#Y		表示后面的字体为黄色(yellow)
	#W		表示后面的字体为白色(white)
	#b		表示后面的字体为闪烁(blink)
	#c		+ 六个数字或者A-F字母 自定义颜色，例如：c008000=暗绿色
	#e		+ 六个数字或者A-F字母 自定义颜色，例如：e008000=暗绿色,表示字体扩展边底色
	#u		+ 文字 + #u 文字有下划线。   (CYS-INFOPARITY 19/09: utf32 0xE6/0xE7, lop phong ve gach chan)
	#n		所有文字状态恢复正常。       (CYS-INFOPARITY: 0xE1 + 0xE7 nhu CY)
	#r		文字换行。
	##		输出一个#号。
	#aB		表示后面跟着一个超链接，这是超链接部分的开始
	#aE		表示后面跟着一个超链接，这是超链接部分的结束

	#{IDSTR}  查表替换字符串

	#0~99	  表情
	#-01~-99	仅程序使用，不许玩家输入的动画
	*/

	const CHAR			KeyParser			= '#';
	const CHAR			KeyParserIDBegin	= '{';
	const CHAR			KeyParserIDEnd		= '}';
	STRING::size_type	nValidBegin			= 0;
	STRING				strOutMBCS			= "";

	BOOL				bBlink				= FALSE;
	BOOL				bUnderline			= FALSE;	// CYS-INFOPARITY: "#u" toggle, CY keeps it in [rbp-0x68]
	CEGUI::CysTextColourParser colourParser;

	//检查字符串合法性
	STRING strSource;
	// CYS: packed Format carries arbitrary 8-bit count/length metadata, not text.
	STRING strExpanded;
	const CysPackedFormat::Result packed = CysPackedFormat::Expand(
		strSourceNotCheck, &CUIStringSystem::ResolvePackedFormat, this, strExpanded);
	if(!packed.ok())
	{
		CHAR szLog[128] = {0};
		_snprintf(szLog, sizeof(szLog) - 1, "CYS packed Format rejected: %s at byte %Iu",
			CysPackedFormat::ErrorName(packed.error), packed.offset);
		CEGUI::Logger::getSingleton().logEvent((CEGUI::utf8*)szLog);
	}
	_CheckStringCode(strExpanded, strSource);


	{
		CysUiTalkVars provider(&CUIStringSystem::ResolvePackedFormat, this);
		STRING strVars;
		CysDialogVars::Expand(strSource, g_pObjectSystem ? &provider : NULL,
			CysDialogVars::ProtectedRanges(strSource), strVars);
		strSource.swap(strVars);
	}

	//过滤聊天信息中的非法信息
	if(FALSE == _CheckStringFilter(strSource))
		strSource = FromGbkLiteral("#R请注意你的言辞！！"); // CYS: GBK literal -> UI code page

	do
	{
		if(nValidBegin >= strSource.size()) break;

		STRING::size_type nValidEnd = strSource.find(KeyParser, nValidBegin);

		//最后一段正常值
		if(nValidEnd == STRING::npos) 
		{
			strOutMBCS = strSource.substr(nValidBegin);
			std::string strTemp;
			CUIStringSystem::mbcs_to_utf8(strOutMBCS, strTemp);
			strOutUtf32 += (CEGUI::String)(CEGUI::utf8*)(strTemp.c_str());
			break;
		}

		//加入正常值
		if(nValidEnd != nValidBegin) 
		{
			strOutMBCS = strSource.substr(nValidBegin, nValidEnd-nValidBegin);
			std::string strTemp;
			CUIStringSystem::mbcs_to_utf8(strOutMBCS, strTemp);
			strOutUtf32 += (CEGUI::String)(CEGUI::utf8*)(strTemp.c_str());
		}

		STRING::size_type nKeyStart = nValidEnd+1;	//"#"后面那个字符的位置
		STRING::size_type nKeyEnd;					//下一个非指令字符的位置							

		//合法的Key描述
		if(nKeyStart != STRING::npos )
		{
			STRING strKey_Opt	= strSource.substr(nKeyStart, 1);
			CEGUI::utf32 val = 0;
			unsigned colourWord = 0;
			if(colourParser.parse(strSource, nKeyStart, colourWord, nKeyEnd))
			{
				strOutUtf32 += static_cast<CEGUI::utf32>(colourWord);
			}
			else if( strKey_Opt == "b" )
			{//#b闪烁
				val = 0xE0000000;
				strOutUtf32 += val;
				nKeyEnd = nKeyStart+1;

				bBlink = TRUE;
			}
			else if( strKey_Opt == "u" )
			{//#u下划线



				val = bUnderline ? 0xE7000000 : 0xE6000000;
				strOutUtf32 += val;
				bUnderline = !bUnderline;
				nKeyEnd = nKeyStart+1;
			}
			else if( strKey_Opt == "n" )
			{//#n回复状态


				val = 0xE1000000;
				strOutUtf32 += val;
				val = 0xE7000000;
				strOutUtf32 += val;
				nKeyEnd = nKeyStart+1;
			}
			else if( strKey_Opt == "r" )
			{//#r回车换行
				strOutMBCS = "\n";
				std::string strTemp;
				CUIStringSystem::mbcs_to_utf8(strOutMBCS, strTemp);
				strOutUtf32 += (CEGUI::String)(CEGUI::utf8*)(strTemp.c_str());
				nKeyEnd = nKeyStart+1;
			}
			else if( strKey_Opt == "#" )
			{//##
				strOutMBCS = "#";
				std::string strTemp;
				CUIStringSystem::mbcs_to_utf8(strOutMBCS, strTemp);
				strOutUtf32 += (CEGUI::String)(CEGUI::utf8*)(strTemp.c_str());
				nKeyEnd = nKeyStart+1;
			}
			else if( strKey_Opt == "a")
			{//HyperLink #aB{linktxt}showtxt#aE
				STRING strManipulate = strSource.substr(nKeyStart+1, 1);
				if(strManipulate == "B")//#aB
				{
					val = 0xFD000000;
					strOutUtf32 += val;
					nKeyEnd = nKeyStart+2;
				}
				else if(strManipulate == "E")//#aE
				{
					val = 0xFE000000;
					strOutUtf32 += val;
					nKeyEnd = nKeyStart+2;
				}
				else
				{
					//非法HyperLink#a字串
					nKeyEnd = nKeyStart+2;
				}
			}
			else if( strKey_Opt.c_str()[0] == KeyParserIDBegin )
			{//#{IDSTR} == 大哥
				STRING::size_type nIDBegin	= nKeyStart+1;
				STRING::size_type nIDEnd	= strSource.find(KeyParserIDEnd, nIDBegin);

				if(nIDEnd != STRING::npos)
				{
					STRING strID = strSource.substr(nIDBegin, nIDEnd-nIDBegin);






					STRING strInfoLink;
					CysInfoLink::Link infoLinkParsed;
					const BOOL bInfoLink = CysInfoLink::Expand(strID, strInfoLink, &infoLinkParsed) ? TRUE : FALSE;
					if(bInfoLink)
					{



						if(infoLinkParsed.mapTag)
							strOutUtf32 += (CEGUI::utf32)0xE80099E5;
						CEGUI::String strOutTemp;
						ParserString_RuntimeNew(strInfoLink, strOutTemp);
						strOutUtf32 += strOutTemp;
						if(infoLinkParsed.mapTag)
							strOutUtf32 += (CEGUI::utf32)0xE800CCFF;
					}

					if(strID.substr(0,5) == "_ITEM")
					{//#{_ITEM10100005}
						STRING szTBindex = strID.substr(5,8);
						UINT	TBindex = atoi(szTBindex.c_str());
						strOutMBCS	=	g_pObjectSystem->ItemNameByTBIndex(TBindex);
						std::string strTemp;
						CUIStringSystem::mbcs_to_utf8(strOutMBCS, strTemp);
						strOutUtf32 += (CEGUI::String)(CEGUI::utf8*)(strTemp.c_str());
					}
					if(strID.substr(0,5) == "_TIME")
					{//#{_TIME0507211233}
					 //例如：0507211233 表示 "2005年07月21日 12:33"
						STRING szTime	= strID.substr(5,10);
						UINT	uTime	= atoi(szTime.c_str());

						INT min,hour,day,month,year;

						min = uTime % 100;
						uTime /= 100;

						hour = uTime % 100;
						uTime /= 100;

						day = uTime % 100;
						uTime /= 100;

						month = uTime % 100;
						uTime /= 100;

						year = 2000 + uTime % 100;
						//uTime /= 100;

						// CYS: GBK format literal -> UI code page (UTF-8 result is at most 23 bytes)
						STRING strFormat = FromGbkLiteral("%d年%d月%d日 %d:%d");
						CHAR szDate[32] = {0};
						_snprintf(szDate,sizeof(szDate) - 1, strFormat.c_str(), year,month,day,hour,min);
						strOutMBCS = szDate;

						std::string strTemp;
						CUIStringSystem::mbcs_to_utf8(strOutMBCS, strTemp);
						strOutUtf32 += (CEGUI::String)(CEGUI::utf8*)(strTemp.c_str());
					}
					//#{_MONEY8583045}
					if(strID.substr(0,6) == "_MONEY")
					{
						INT nMoney = 0;
						sscanf(strID.c_str(),"_MONEY%d",&nMoney);

						INT nGoldCoin = nMoney / 10000;
						INT nSilverCoin = (nMoney % 10000) / 100;
						INT nCopperCoin = nMoney % 100;
						
						CHAR szData[128] = {0};
                        std::string currencyText;

						if(nGoldCoin != 0)
						{
							_snprintf(szData, sizeof(szData), "%d#-02", nGoldCoin);
                            currencyText += szData;
						}
						if(nSilverCoin != 0)
						{
							_snprintf(szData, sizeof(szData), "%d#-03", nSilverCoin);
                            currencyText += szData;
						}
						if(nCopperCoin != 0 || currencyText.empty())
						{
							_snprintf(szData, sizeof(szData), "%d#-04", nCopperCoin);
                            currencyText += szData;
						}

						strOutMBCS = currencyText;

						CEGUI::String strTemp;
						ParserString_RuntimeNew(strOutMBCS, strTemp);

						strOutUtf32 += strTemp;
					}
					else if(!bInfoLink)	// CYS-INFOLINK: an expanded link must not fall through to the dictionary
					{//不是特殊命令查表
						std::pair< BOOL, DIRECTIONARY::iterator > isValidKey = _IsValidDictionKey(strID);
						//找到key
						if(isValidKey.first)
						{
							//加入从key转化过来的值
							strOutMBCS = isValidKey.second->second;
							CEGUI::String strOutTemp;
							//递归分析
							ParserString_RuntimeNew(strOutMBCS, strOutTemp);
							strOutUtf32 += strOutTemp;
						}
					}

					nKeyEnd = nIDEnd+1;
				}
				else
				{
					//非法#{需要过滤掉
					nKeyEnd = nKeyStart + 2; 
				}
			}
			else if( strKey_Opt == "-")
			{//#-01~-99(必须是两位数值，一位数值算非法值) 仅程序使用的表情符，玩家输入的字符串不能使用。
				STRING strNum = strSource.substr(nKeyStart+1,2);
				if((strNum.size() == 2) &&
				   (strNum.at(0) >= 48 && strNum.at(0) <= 57) &&
				   (strNum.at(1) >= 48 && strNum.at(1) <= 57))
				{
					UINT nNum;
					sscanf(strNum.c_str(), " %u", &nNum);
					
					if(1 != nNum)
					{
						CEGUI::utf32 val = nNum;
						val |= 0xE3000000;
						strOutUtf32 += val;

						nKeyEnd = nKeyStart + 3;
					}
					else
					{
						// -1是非法动画标识，必须从-2开始 [4/24/2006]
						//忽略掉#-
						nKeyEnd = nKeyStart + 1;
					}
				}
				else
				{//非法命令
					//忽略掉#-
					nKeyEnd = nKeyStart + 1;
				}
			}
			else if( strKey_Opt.c_str()[0] >= 48 && strKey_Opt.c_str()[0] <= 57 )
			{//#0~99 表情
				UINT	nDigital	= strKey_Opt.c_str()[0] - 48;
				STRING strDigital	= strSource.substr(nKeyStart+1, 1);
			
				if(strDigital.c_str()[0] >= 48  && strDigital.c_str()[0] <= 57 )
				{//两位整数
					nDigital = nDigital*10 + (strDigital.c_str()[0] - 48);
					nKeyEnd = nKeyStart + 2;
				}
				else
				{//一位整数
					nKeyEnd = nKeyStart + 1;
				}

//				CODE_CONVERT::iterator  pos = m_mapCodeConvertTable.find( nDigital );
//				if( pos != m_mapCodeConvertTable.end() )
				{
					CEGUI::utf32 val = nDigital;
					val |= 0xFA000000;
					strOutUtf32 += val;
				}
			}
			else
			{//非法命令
				//忽略掉#
				nKeyEnd = nKeyStart;
			}
		}
		nValidBegin = nKeyEnd;
	}while(true);

	if(bBlink)
	{
		CEGUI::utf32 val = 0xE1000000;
		strOutUtf32 += val;
	}
	if(bUnderline)
	{

		CEGUI::utf32 val = 0xE7000000;
		strOutUtf32 += val;
	}

}

#define	SELFMSG_MAX_LENGTH 2048
//根据传入的系统字串ID，在字典里查找格式字符串
STRING CUIStringSystem::ParserString_VarParam(const STRING &strID, va_list ptr)
{
	STRING strOut = "";

	std::pair< BOOL, DIRECTIONARY::iterator > isValidKey = _IsValidDictionKey(strID);
	if(isValidKey.first)
	{
		if(ptr)
		{
			STRING strFormat = isValidKey.second->second;

			// ----------------------------------------------------------------------------
			// CYS-CRTGUARD 20/09/2026 - DIEM NGHEN cua ca lop loi.
			//
			// Day la CHO DUY NHAT trong toan bo Src/ dua mot chuoi TU DU LIEU vao mot ham
			// printf voi doi so bien (`printf-fix` da xac nhan; 24 loi goi `_vsnprintf`
			// khac deu nhan chuoi dinh dang la HANG hoac la tham so cua chinh ham bao).
			// Khoa thi SERVER dat duoc (GMInterface_Script_Talk.cpp:2173 `SrvMsg`), nen mot
			// dong script moi la du de tro vao bat ky o nao cua StrDictionary.
			//
			// `%n` la truong hop KHONG THE cuu bang ban va du lieu: UCRT vo hieu hoa no va
			// goi invalid-parameter, mac dinh la __fastfail(5) = `int 29h` - KHONG qua SEH,
			// KHONG minidump, client bien mat. Do duoc ca hai chieu, cung mot binary:
			//   Build\Logs\2026-09-20-crt-guard\probe\crtprobe-results.txt
			//     off-n  -> EXIT=0xC0000409, khong in duoc dong nao sau do
			//     on-n   -> handler no ra, rc=-1, tien trinh SONG
			// `%n` khong bao gio la noi dung giao dien hop le, nen chan cung o day.
			// ----------------------------------------------------------------------------
			if(CysFmt_HasFatal(strFormat.c_str()))
			{
				static std::set<STRING>* s_pFatalSeen = NULL;
				if(!s_pFatalSeen) s_pFatalSeen = new std::set<STRING>();
				if(s_pFatalSeen->insert(strID).second)
				{
					TDU_Log("CYS-CRTGUARD: khoa tu dien [%s] chua `%%n` - dac ta GIET TIEN TRINH. "
					        "Tra ve nguyen van thay vi dinh dang. Sua o du lieu, dung sua o day.",
					        strID.c_str());
				}
				return strFormat;		// nguyen van, khong qua printf
			}

			CHAR  result[SELFMSG_MAX_LENGTH+1];
			memset(result,0,SELFMSG_MAX_LENGTH+1);

			//格式化结果字符串
			_vsnprintf(result, SELFMSG_MAX_LENGTH, strFormat.c_str(), ptr);

			strOut = result;
		}
	}

	return strOut;
}

STRING CUIStringSystem::ParserString_NoVarParam(const STRING& strID)
{
	STRING strOut = "";

	std::pair< BOOL, DIRECTIONARY::iterator > isValidKey = _IsValidDictionKey(strID);
	if(isValidKey.first)
	{
		strOut = isValidKey.second->second;
	}

	return strOut;
}

#undef SELFMSG_MAX_LENGTH

VOID CUIStringSystem::ParserString_NoColor(const STRING& strSrc, STRING& strOut, BOOL bControl)
{
	const CHAR KeyStart = '#';
	strOut.clear();
	
	STRING::size_type sB = 0;
	STRING::size_type sE = strSrc.find_first_of(KeyStart);
	STRING::size_type sLen = strSrc.size();

	do
	{	
		if(sE == STRING::npos)
		{
			//copy last
			strOut += strSrc.substr(sB);
			break;
		}
		
		//copy normal
		strOut += strSrc.substr(sB, sE-sB);

		//get op
		STRING strOp = strSrc.substr(sE+1, 1);

		// B c/e/g consume six hex characters; #l is a two-byte colour control.
		const size_t colourLength = strOp.empty() ? 0 : CEGUI::CysTextColourParser::tokenLength(strOp[0]);
		if(colourLength)
		{
			sE += colourLength;
		}
		else if(bControl && (strOp == "b" || strOp == "u" || strOp == "r" || strOp == "n"))
		{
			sE += 2;
		}
		else
		{
			//not color means
			strOut += strSrc.at(sE);	//same as --> strOut += KeyStart;
			sE += 1;
		}

		if(sE >= sLen) break;

		//save new begin point
		sB = sE;

		//find next KeyStart
		sE = strSrc.find(KeyStart, sB);

	}while(TRUE);
}

STRING CUIStringSystem::getTalkTemplate(const STRING& strKey, UINT index)
{
	STRING strOut = "";

	if(!(strKey.empty()))
	{
		TALK_TEMPLATE_MAP::iterator itFind = m_talkTemplateTable.find(strKey);
		if(itFind != m_talkTemplateTable.end() && index < (itFind->second).size())
		{
			strOut = (itFind->second)[index];
		}
	}

	return strOut;
}

STRING CUIStringSystem::getTalkRandHelpMsg()
{
	TALK_TEMPLATE_MAP::iterator itFind = m_talkTemplateTable.find(TALK_HELPSTRING_KEY);
	if(itFind != m_talkTemplateTable.end())
	{
		UINT idx = abs(rand()%(INT)((itFind->second).size()));
		return (itFind->second)[idx];
	}
	return "";
}

void CUIStringSystem::mbcs_to_utf8(const std::string& strIn, std::string& strOut)
{
	// CYS: UTF-8 game text needs no conversion through the process locale (CP936 only on a Chinese Windows, ACP 1252
	// here) - only the malformed-byte filter that keeps CEGUI::String's decoder inside the buffer.
	if(IsUTF8()) { _cysFilterUtf8(strIn, strOut, FALSE); return; }

	//设置语言环境
	AUTO_LOCALE_CONVERT theAutoConvert;
	strOut = utf::mbcs_to_utf8(strIn);
}

void CUIStringSystem::utf8_to_mbcs(const std::string& strIn, std::string& strOut)
{
	// CYS: UTF-8 UI text goes back to the game unchanged.
	if(IsUTF8()) { strOut = strIn; return; }

	//设置语言环境
	AUTO_LOCALE_CONVERT theAutoConvert;
	strOut = utf::utf8_to_mbcs(strIn);
}

VOID CUIStringSystem::GenerateFullCompareTable()
{
	tDataBaseSystem* pUIDBC = (tDataBaseSystem*)g_pKernel->GetNode("bin\\dbc");
	TDAssert(pUIDBC);
	const tDataBase* pDBCFullCmp = pUIDBC->GetDataBase(DBC_FULLCMP_FILTER);
	TDAssert(pDBCFullCmp);
	for(INT i=0; i<(INT)pDBCFullCmp->GetRecordsNum(); i++)
	{
		const _DBC_FULLCMP_FILTER* pLine = (const _DBC_FULLCMP_FILTER*)((tDataBase*)pDBCFullCmp)->Search_LineNum_EQU(i);
		FULLCMP_MAP::iterator itFind = m_fullCompareTable.find(pLine->szFilterType);

		//创建新的类型
		if(itFind == m_fullCompareTable.end())
		{
			UI_FULLCMP_TEMPLATE	talkTemplate;

			m_fullCompareTable.insert(std::make_pair(pLine->szFilterType, talkTemplate));
			itFind = m_fullCompareTable.find(pLine->szFilterType);
		}

		//添加字串
		UI_FULLCMP_TEMPLATE& strVec = itFind->second;
		strVec.insert(pLine->szFullTxt);
	}
}

VOID CUIStringSystem::GenerateTalkTemplateTable()
{
	DIRECTIONARY::iterator it = m_theDirectionary.begin();

	UI_TALK_TEMPLATE	talkTemplate;
	STRING				talkKey;

	do
	{
		//聊天快捷模板发现
		if("TALK_" == (it->first).substr(0,5))
		{
			talkKey = (it->first).substr(5, (it->first).find("_", 6)-(it->first).find("_") -1);

			TALK_TEMPLATE_MAP::iterator itTemplate = m_talkTemplateTable.find(talkKey);
			if(itTemplate == m_talkTemplateTable.end())
			{
				INT idmax = (TALK_HELPSTRING_KEY == talkKey)?TALK_HELPSTRING_MAX:TALK_TEMPLATE_MAX;
				for(INT id = 0; id < idmax; ++id)
				{
					CHAR num[4] = {0};
					_snprintf(num,4,"%03d",id+1);

					STRING strFind = "TALK_" + talkKey + "_" + num;

					DIRECTIONARY::iterator itFind = m_theDirectionary.find(strFind);
		
					if(itFind != m_theDirectionary.end())
					{
						talkTemplate.push_back(itFind->second);
                		m_theDirectionary.erase(itFind);
					}
					else
					{
						if(idmax == TALK_TEMPLATE_MAX)
							talkTemplate.push_back("");	//not found insert an empty string.
					}
				}

				m_talkTemplateTable.insert(std::make_pair(talkKey, talkTemplate));

				talkKey.clear();
				talkTemplate.clear();
				it = m_theDirectionary.begin();
			}
			else
				m_theDirectionary.erase(it++); //说明聊天模板的书写方式错误，删除错误记录
		}
		else
			it++;
	}
	while(it != m_theDirectionary.end());
}

STRING CUIStringSystem::ModifyChatTemplate(const STRING& strSrc, const STRING& strTalker, const STRING& strTarget)
{
	const CHAR KeyStart = '$';

	STRING::size_type sB = 0;
	STRING::size_type sE = strSrc.find_first_of(KeyStart);
	STRING::size_type sLen = strSrc.size();

	STRING strOut;
	strOut.clear();

	do
	{	
		if(sE == STRING::npos)
		{
			//copy last
			strOut += strSrc.substr(sB);
			break;
		}
			
		//copy normal
		strOut += strSrc.substr(sB, sE-sB);

		//get op
		STRING strOp = strSrc.substr(sE+1, 1);

		//replace talker
		if(strOp == "N")
		{
			strOut += strTalker;
			sE += 2;
		}
		else if(strOp == "n") //replace target
		{
			strOut += strTarget;
			sE += 2;
		}
		else
		{
			//ignore wrong '$'
			//strOut += strSrc.at(sE);
			sE += 1;
		}

		if(sE >= sLen) break;

		//save new begin point
		sB = sE;

		//find next KeyStart
		sE = strSrc.find(KeyStart, sB);

	}while(TRUE);

	return strOut;
}
