#include "stdafx.h"
#include <string>
#include <map>
#include <assert.h>
#include "TLBB_DBC.h"
#include <exception>

namespace DBC
{

INT	DBCFile::_ConvertStringToVector(const CHAR* strStrINTgSource, vector< std::string >& vRet, const CHAR* szKey, BOOL bOneOfKey, BOOL bIgnoreEmpty)
{
	vRet.clear();
	
	std::string strSrc = strStrINTgSource;
	if(strSrc.empty())
	{
		return 0;
	}

	std::string::size_type nLeft = 0;
	std::string::size_type nRight;
	if(bOneOfKey)
	{
		nRight = strSrc.find_first_of(szKey);
	}
	else
	{
		nRight = strSrc.find(szKey);
	}

	if(nRight == std::string::npos)
	{
		nRight = strSrc.length();
	}
	while(TRUE)
	{
		std::string strItem = strSrc.substr(nLeft, nRight-nLeft);
		if(strItem.length() > 0 || !bIgnoreEmpty)
		{
			vRet.push_back(strItem);
		}

		if(nRight == strSrc.length())
		{
			break;
		}

		nLeft = nRight + (bOneOfKey ? 1 : strlen(szKey));
		
		if(bOneOfKey)
		{
			std::string strTemp = strSrc.substr(nLeft);
			nRight = strTemp.find_first_of(szKey);
			if(nRight != std::string::npos) nRight += nLeft;
		}
		else
		{
			nRight = strSrc.find(szKey, nLeft);
		}

		if(nRight == std::string::npos)
		{
			nRight = strSrc.length();
		}
	}

	return (INT)vRet.size();
}

template < DBCFile::FIELD_TYPE T>
bool DBCFile::_FieldEqu(const FIELD& a, const FIELD& b)
{
	if(T == T_INT)
	{
		return a.iValue==b.iValue;
	}
	else if(T == T_FLOAT)
	{
		return a.fValue==b.fValue;
	}
	else
	{
		try
		{
			return (strcmp(a.pString, b.pString)==0);
		}
		catch(...)
		{
			return false;
		}
	}
}

// CYS: the file header is 4 x 4 bytes on every platform.
static_assert(sizeof(DBCFile::FILE_HEAD) == 16, "DBC FILE_HEAD must stay 16 bytes");

DBCFile::DBCFile(UINT id)
{
	m_ID = id;
	m_pStringBuf = NULL;
	m_nIndexColum = -1;
	m_nRecordsNum = 0;		// CYS: were left uninitialised
	m_nFieldsNum = 0;		// CYS
	m_nRecordSize = 0;		// CYS
	m_nStringBufSize = 0;	// CYS
}

DBCFile::~DBCFile()
{
	if(m_pStringBuf) delete[] m_pStringBuf;
	m_pStringBuf = NULL;
}

//从内存中字符串读取一行文本(按照换行符)
const CHAR* DBCFile::_GetLineFromMemory(CHAR* pStringBuf, INT nBufSize, const CHAR* pMemory, const CHAR* pDeadEnd)
{
	//寻找下一个换行符
	register const char* pMem = pMemory;
	if(pMem >= pDeadEnd || *pMem==0) return 0;

	while(pMem < pDeadEnd && pMem-pMemory+1<nBufSize && 
			*pMem != 0 && *pMem != '\r' && *pMem != '\n') *(pStringBuf++) = *(pMem++);
	//add 'null' end
	*pStringBuf = 0;

	//skip all next \r and \n
	while(pMem < pDeadEnd && *pMem != 0 && (*pMem=='\r' || *pMem=='\n')) pMem++;

	return pMem;
}

BOOL DBCFile::OpenFromMemory(const CHAR* pMemory, const CHAR* pDeadEnd, const CHAR* szFileName)
{
	assert(pMemory && pDeadEnd);
	//----------------------------------------------------
	//判断是否是二进制格式
	if(pDeadEnd - pMemory >=sizeof(FILE_HEAD) && *((UINT*)pMemory)==0XDDBBCC00)
	{
		return OpenFromMemoryImpl_Binary(pMemory, pDeadEnd, szFileName);
	}
	else
	{
		return OpenFromMemoryImpl_Text(pMemory, pDeadEnd, szFileName);
	}
}

BOOL DBCFile::OpenFromMemoryImpl_Binary(const CHAR* pMemory, const CHAR* pDeadEnd, const CHAR* szFileName)
{
	register const char* pMem = pMemory;

	//----------------------------------------------------
	//Read Head
	FILE_HEAD theHead;
	memcpy(&theHead, pMem, sizeof(FILE_HEAD));
	if(theHead.m_Identify != 0XDDBBCC00 )
	{
		return FALSE;
	}
	//check memory size
	// CYS: every field is 4 bytes in the file; 0.85 used sizeof(FIELD), which is 8 on x64.
	if(	theHead.m_nFieldsNum <= 0 || theHead.m_nRecordsNum < 0 || theHead.m_nStringBlockSize < 0 ||
		sizeof(FILE_HEAD) +
		sizeof(UINT)*(size_t)theHead.m_nFieldsNum +
		sizeof(UINT)*(size_t)theHead.m_nRecordsNum * theHead.m_nFieldsNum +
		(size_t)theHead.m_nStringBlockSize > (size_t)(pDeadEnd-pMemory))
	{
		return FALSE;
	}

	pMem += sizeof(FILE_HEAD);

	//----------------------------------------------------
	//Init 
	m_nRecordsNum = theHead.m_nRecordsNum;
	m_nFieldsNum  = theHead.m_nFieldsNum;
	m_nStringBufSize = theHead.m_nStringBlockSize;

	//---------------------------------------------
	//Create String Blok
	if(m_nStringBufSize < 1) m_nStringBufSize = 1;	// CYS: keep m_pStringBuf[size-1] valid for an empty block
	m_pStringBuf = new CHAR[m_nStringBufSize];
	if(!m_pStringBuf) return FALSE;
	m_pStringBuf[0] = 0;

	//------------------------------------------------------
	// Read Field Types
	vector< UINT > vFieldType;
	vFieldType.resize(theHead.m_nFieldsNum);
	memcpy(&(vFieldType[0]), pMem, sizeof(UINT)*theHead.m_nFieldsNum);
	pMem += sizeof(UINT)*theHead.m_nFieldsNum;

	//Check it!
	m_theType.resize(theHead.m_nFieldsNum);
	for(INT i=0; i<(INT)theHead.m_nFieldsNum; i++)
	{
		switch(vFieldType[i])
		{
		case T_INT:
		case T_FLOAT:
		case T_STRING:
			m_theType[i] = (FIELD_TYPE)vFieldType[i];
			break;

		default:
			delete[] (m_pStringBuf);
			m_pStringBuf = NULL;	// CYS: the destructor deleted it a second time
			return FALSE;
		}
	}

	//------------------------------------------------------
	// Read All Field
	// CYS: read the 4-byte file fields one by one (0.85 memcpy'd sizeof(FIELD) = 8 bytes per field on x64) into a
	// CYS: temporary FIELD array; _BuildRecords() then lays the records out for this architecture.
	const size_t nFieldCount = (size_t)theHead.m_nRecordsNum * theHead.m_nFieldsNum;
	DATA_BUF vFields(nFieldCount);
	for(size_t n=0; n<nFieldCount; n++)
	{
		UINT nRaw;
		memcpy(&nRaw, pMem + n*sizeof(UINT), sizeof(UINT));
		vFields[n].iValue = (INT)nRaw;
	}
	pMem += sizeof(UINT)*nFieldCount;

	//------------------------------------------------------
	// Read String Block
	memcpy(m_pStringBuf, pMem, theHead.m_nStringBlockSize);
	m_pStringBuf[m_nStringBufSize-1]=0;

	//------------------------------------------------------
	// TO runtime address
	for(INT j=0; j<(INT)theHead.m_nFieldsNum; j++)
	{
		if(vFieldType[j] != T_STRING) continue;

		for(INT i=0; i<(INT)theHead.m_nRecordsNum; i++)
		{
			// CYS: was pString += (base) on the raw field; offset -> pointer, offsets outside the block -> ""
			FIELD& theField = vFields[(size_t)i*theHead.m_nFieldsNum+j];
			UINT nOffset = (UINT)theField.iValue;
			theField.pString = m_pStringBuf + (nOffset < (UINT)m_nStringBufSize ? nOffset : 0);
		}
	}
	_BuildRecords(vFields);	// CYS

	//------------------------------------------------------
	//生成索引列
	CreateIndex(0, szFileName);

	return TRUE;
}

BOOL DBCFile::OpenFromMemoryImpl_Text(const CHAR* pMemory, const CHAR* pDeadEnd, const CHAR* szFileName)
{
	//----------------------------------------------------
	//分析列数和类型
	CHAR szLine[1024*10] = {0};
	//读第一行
	register const char* pMem = pMemory;
	pMem = _GetLineFromMemory(szLine, 1024*10, pMem, pDeadEnd);
	if(!pMem) return FALSE;

	//分解
	vector< std::string > vRet;
	_ConvertStringToVector(szLine, vRet, "\t", TRUE, TRUE);
	if(vRet.empty()) return FALSE;
	//生成Field Types
	FILEDS_TYPE vFieldsType;
	vFieldsType.resize(vRet.size());

	for(INT i=0; i<(INT)vRet.size(); i++) 
	{
		if(vRet[i] == "INT") vFieldsType[i] = T_INT;
		else if(vRet[i] == "FLOAT") vFieldsType[i] = T_FLOAT;
		else if(vRet[i] == "STRING") vFieldsType[i] = T_STRING;
		else
		{
			return FALSE;
		}
	}

	//--------------------------------------------------------------
	//初始化
	INT nRecordsNum	= 0;
	INT nFieldsNum	= (INT)vFieldsType.size();

	// CYS: fields are collected here and laid out by _BuildRecords() (was pushed straight into m_vDataBuf)
	DATA_BUF vFields;
	//临时字符串区
	vector< std::pair< std::string, INT > >	vStringBuf;
	//检索表
	std::map< std::string, INT >					mapStringBuf;

	//--------------------------------------------------------------
	//开始读取

	//空读一行
	pMem = _GetLineFromMemory(szLine, 1024*10, pMem, pDeadEnd);
	if(!pMem) return FALSE;

	INT nStringBufSize = 0;
	do
	{
		//读取一行
		pMem = _GetLineFromMemory(szLine, 1024*10, pMem, pDeadEnd);
		if(!pMem) break;;

		//是否是注释行
		if(szLine[0] == '#') continue;

		//分解
		_ConvertStringToVector(szLine, vRet, "\t", TRUE, FALSE);

		//列数不对
		if(vRet.empty()) continue;
        if(vRet.size() != nFieldsNum) 
		{
			//补上空格
			if((INT)vRet.size() < nFieldsNum)
			{
				INT nSubNum = nFieldsNum-(INT)vRet.size();
				for(INT i=0; i<nSubNum; i++)
				{
					vRet.push_back("");
				}
			}
		}

		//第一列不能为空
		if(vRet[0].empty()) continue;

		for(register INT i=0; i<nFieldsNum; i++)
		{
			FIELD newField;
			switch(vFieldsType[i])
			{
			case T_INT:
				newField.iValue = atoi(vRet[i].c_str());
				vFields.push_back(newField);	// CYS: was m_vDataBuf
				break;

			case T_FLOAT:
				newField.fValue = (FLOAT)atof(vRet[i].c_str());
				vFields.push_back(newField);	// CYS: was m_vDataBuf
				break;

			case T_STRING:
				if(vRet[i].empty())
				{
					newField.iValue = 0;
				}
				else
				{
					const CHAR * p = vRet[i].c_str();
					std::map< std::string, INT >::iterator it = mapStringBuf.find(vRet[i]);
					if(it == mapStringBuf.end())
					{
						vStringBuf.push_back(std::make_pair(vRet[i], nStringBufSize));
						mapStringBuf.insert(std::make_pair(vRet[i], (INT)vStringBuf.size()-1));
						newField.iValue = nStringBufSize + 1; // first CHAR is '\0' for blank string
	
						nStringBufSize += (INT)strlen(vRet[i].c_str()) + 1;
					}
					else
					{
						newField.iValue = vStringBuf[it->second].second + 1;
					}
				}

				vFields.push_back(newField);	// CYS: was m_vDataBuf
				break;
			}
		}

		nRecordsNum++;
	}while(TRUE);

	//--------------------------------------------------------
	//生成正式数据库
	m_nRecordsNum = nRecordsNum;
	m_nFieldsNum  = nFieldsNum;
	m_nStringBufSize = nStringBufSize+1;

	//Create String Blok
	m_pStringBuf = new CHAR[m_nStringBufSize];
	if(!m_pStringBuf) return FALSE;

	//------------------------------------------------------
	// Create Field Types
	m_theType = vFieldsType;

	//------------------------------------------------------
	// Create String Block
	UCHAR byBlank = '\0';
	m_pStringBuf[0] = '\0';

	register CHAR* p = m_pStringBuf + 1;
	for(INT i=0; i<(INT)vStringBuf.size(); i++)
	{
		memcpy(p, vStringBuf[i].first.c_str(), vStringBuf[i].first.size());	
		p += vStringBuf[i].first.size();

		*(p++) = '\0';
	}

	//------------------------------------------------------
	// Relocate String Block
	for(register INT i=0; i<nFieldsNum; i++)
	{
		if(vFieldsType[i] != T_STRING) continue;

		for(register INT j=0; j<nRecordsNum; j++)
		{
			FIELD& theField = vFields[(size_t)j*nFieldsNum+i];	// CYS: was m_vDataBuf
			theField.pString = m_pStringBuf + theField.iValue;
		}
	}
	_BuildRecords(vFields);	// CYS

	//------------------------------------------------------
	//生成索引列
	CreateIndex(0, szFileName);

	return TRUE;
}

// CYS: natural C layout of the column types - INT/FLOAT 4 bytes, STRING one pointer, each aligned to its size,
// CYS: record rounded up to the largest slot (see TLBB_DBC.h). x86: offset = 4*column, exactly the 0.85 layout.
VOID DBCFile::_BuildLayout(VOID)
{
	m_vFieldOffset.resize(m_theType.size());
	INT nOffset = 0;
	INT nAlign = (INT)sizeof(INT);
	for(size_t i=0; i<m_theType.size(); i++)
	{
		const INT nSize = (m_theType[i] == T_STRING) ? (INT)sizeof(const CHAR*) : (INT)sizeof(INT);
		nOffset = (nOffset + nSize - 1) & ~(nSize - 1);
		m_vFieldOffset[i] = nOffset;
		nOffset += nSize;
		if(nSize > nAlign) nAlign = nSize;
	}
	m_nRecordSize = (nOffset + nAlign - 1) & ~(nAlign - 1);
}

// CYS: copies a row-major FIELD array (strings already relocated to pointers) into the record storage.
VOID DBCFile::_BuildRecords(const DATA_BUF& vFields)
{
	_BuildLayout();
	const size_t nBytes = (size_t)m_nRecordSize * m_nRecordsNum;
	m_vRecordBuf.assign(nBytes / sizeof(unsigned long long) + 1, 0);
	for(INT i=0; i<m_nRecordsNum; i++)
	{
		for(INT j=0; j<m_nFieldsNum; j++)
		{
			const FIELD& theSrc = vFields[(size_t)i*m_nFieldsNum + j];
			FIELD* pDst = _FieldAt(i, j);
			if(m_theType[j] == T_STRING)
				memcpy(pDst, &theSrc.pString, sizeof(theSrc.pString));
			else
				memcpy(pDst, &theSrc.iValue, sizeof(theSrc.iValue));
		}
	}
}

BOOL DBCFile::OpenFromTXT(const CHAR* szFileName)
{
	assert(szFileName);

	//----------------------------------------------------
	//打开文件
	FILE* fp = fopen(szFileName, "rb");
	if(NULL == fp) return FALSE;

	fseek(fp, 0, SEEK_END);
	int nFileSize = ftell(fp);
	fseek(fp, 0, SEEK_SET);

	//读入内存
	char* pMemory = new char[nFileSize+1];
	fread(pMemory, 1, nFileSize, fp);
	pMemory[nFileSize] = 0;

	BOOL bRet = OpenFromMemory(pMemory, pMemory+nFileSize+1, szFileName);

	delete[] pMemory; pMemory = 0;
	return bRet;
}

VOID DBCFile::CreateIndex(INT nColum, const CHAR* szFileName)
{
	if(nColum <0 || nColum >= m_nFieldsNum || m_nIndexColum==nColum) return;

	m_hashIndex.clear();

	for(INT i=0; i<(INT)m_nRecordsNum; i++)
	{
		FIELD* p = _FieldAt(i, 0);	// CYS: was &m_vDataBuf[i*m_nFieldsNum]

		FIELD_HASHMAP::iterator itFind = m_hashIndex.find(p->iValue);
		if(itFind != m_hashIndex.end())
		{
			CHAR szTemp[260];
			tsnprintf(szTemp, 260, "[%s]Multi index at line %d(SAME:value=%d)", szFileName, i+1, p->iValue);
#ifdef GAME_CLIENT
			throw std::string(szTemp);
#else
			AssertEx(FALSE,szTemp);
#endif
			return;
		}
		m_hashIndex.insert(std::make_pair(p->iValue, p));
	}
}

const DBCFile::FIELD* DBCFile::Search_Index_EQU(INT iIndex) const
{
	FIELD_HASHMAP::const_iterator itFind = m_hashIndex.find(iIndex);
	if(itFind == m_hashIndex.end()) return NULL;

	return itFind->second;
}

const DBCFile::FIELD* DBCFile::Search_Posistion(INT nRecordLine, INT nColumNum) const
{
	// CYS: 0.85 computed nRecordLine*fields+column into a FIELD array and never really bounds-checked it. A row past
	// CYS: the end now returns NULL (callers such as Search_LineNum_EQU loops test for NULL); a bad column still throws.
	if(nRecordLine >= m_nRecordsNum) return NULL;
	if(nRecordLine < 0 || nColumNum < 0 || nColumNum >= m_nFieldsNum)
	{
		char szTemp[260];
		tsnprintf(szTemp, MAX_FILE_PATH, "DBC:Invalid search request[rec=%d, col=%d]", nRecordLine, nColumNum);
#ifdef GAME_CLIENT
		throw std::string(szTemp);
#else
		AssertEx(FALSE, szTemp);
#endif
		return NULL;
	}

	return _FieldAt(nRecordLine, nColumNum);	// CYS: was &m_vDataBuf[nPosition]
}

//查找某列等于指定值的第一行
const DBCFile::FIELD* DBCFile::Search_First_Column_Equ(INT nColumnNum, const FIELD& value) const
{
	if(nColumnNum < 0 || nColumnNum >= m_nFieldsNum) return 0;
	FIELD_TYPE type = m_theType[nColumnNum];

	for(register int i=0; i<m_nRecordsNum; i++)
	{
		const FIELD& theField = *_FieldAt(i, nColumnNum);	// CYS: was m_vDataBuf[m_nFieldsNum*i + nColumnNum]
		
		bool bRet;
		if(T_INT == type) 
			bRet = _FieldEqu<T_INT>(theField, value);
		else if(T_FLOAT == type)
			bRet = _FieldEqu<T_FLOAT>(theField, value);
		else
			bRet = _FieldEqu<T_STRING>(theField, value);

		if(bRet) return _FieldAt(i, 0);	// CYS: was &m_vDataBuf[m_nFieldsNum*i]
	}

	return 0;
}

}