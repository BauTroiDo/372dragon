/*
|==========================================
|	DBC数据库文件类
|		(服务器/客户端通用)
|==========================================
|
|		--------------------
|		|  数据库文件格式  |
|		--------------------
|
|		Offset |	Type  |  Description  
|		-------+----------+------------------
|	Head
|		0X000	  UINT		DBC File Identity， always 0XDDBBCC00
|		0X004	  UINT      Number of records in the file 
|		0X008     UINT      Number of 4-byte fields per record
|		0X010     UINT      String block size 
|   FieldType
|		0X014     UINT[FieldNum]   
|							  The type fo fields(0-INT, 1-FLOAT, 2-string)
|   FieldBlock
|				  UINT[FieldNum*RecordNum]
|							  DataBlock
|	StringBlock
|				  CHAR[StringSize]
|							  StringBlock
|
*/
#ifndef _TLBB_DB_H_
#define _TLBB_DB_H_

#include <vector>
#ifdef __WINDOWS__
#include <unordered_map>	// CYS: was <hash_map> (stdext::hash_map is deprecated/blocked by modern MSVC)
#else
#include <ext/hash_map>
#endif
#include "Type.h"

/*
| CYS: x64 record layout.
|   Every table column is 4 bytes in the file (INT, FLOAT, or the offset of a STRING in the string block), and the
|   client overlays whole records with C structs (_DBC_XXX in TDDBC_Struct.h, SSkillData, ...) whose members are
|   INT/FLOAT (4 bytes) and LPCSTR (pointer). 0.85 kept the records as an array of 4-byte FIELD unions, which is
|   exactly that C layout on x86. On x64 the pointer (and the FIELD union) is 8 bytes, so the records are now built
|   with the natural C layout of the column types: INT/FLOAT at 4-byte aligned slots, STRING at 8-byte aligned
|   pointer slots, record size rounded up to the largest slot. On x86 this is byte-for-byte the old layout
|   (offset = 4 * column). Search_Posistion()/Search_Index_EQU() return pointers into that layout, so a struct whose
|   members follow the column types of its table overlays correctly on both architectures.
*/

namespace DBC
{
	class DBCFile	
	{
	public:
		//文件头
		struct FILE_HEAD
		{
			UINT		m_Identify;				//标示	0XDDBBCC00
			INT			m_nFieldsNum;			//列数
			INT			m_nRecordsNum;			//行数
			INT			m_nStringBlockSize;		//字符串区大小
		};

		//字段数据类型
		enum FIELD_TYPE
		{
			T_INT		= 0,	//整数
			T_FLOAT		= 1,	//浮点数
			T_STRING	= 2,	//字符串
		};

		//数据库格式描述
		typedef vector< FIELD_TYPE >	FILEDS_TYPE;

		//数据段
		union FIELD
		{
			FLOAT		fValue;
			INT			iValue;
			const CHAR*	pString;	// Just for runtime!

			//Construct
			FIELD() {}
			FIELD(INT value) { iValue = value; }
			FIELD(FLOAT value) { fValue = value; }
			FIELD(const CHAR* value) { pString = value; }
		};
		//数据区
		typedef vector< FIELD >		DATA_BUF;

	public:
		//打开文本文件，生成一个数据库
		BOOL					OpenFromTXT(const CHAR* szFileName);
		//根据内存中的文件打开
		BOOL					OpenFromMemory(const CHAR* pMemory, const CHAR* pDeadEnd, const CHAR* szFileName=0);
	protected:
		//读取文本格式内容
		BOOL					OpenFromMemoryImpl_Text(const CHAR* pMemory, const CHAR* pDeadEnd, const CHAR* szFileName=0);
		//读取二进制格式内容
		BOOL					OpenFromMemoryImpl_Binary(const CHAR* pMemory, const CHAR* pDeadEnd, const CHAR* szFileName=0);

	public:
		//按索引查找(第一列为索引)
		virtual const FIELD*	Search_Index_EQU(INT nValue) const;
		//按照位置查找
		virtual const FIELD*	Search_Posistion(INT nRecordLine, INT nColumNum) const;
		//查找某列等于指定值的第一行
		virtual const FIELD*	Search_First_Column_Equ(INT nColumnNum, const FIELD& value) const;

	public:
		//取得ID
		UINT GetID(VOID) const				{ return m_ID; }
		//取得列数
		INT	GetFieldsNum(VOID) const	    { return m_nFieldsNum; }
		//取得记录的条数
		INT GetRecordsNum(VOID) const		{ return m_nRecordsNum; }
		//生成索引列
		VOID CreateIndex(INT nColum = 0, const CHAR* szFileName=0);

	protected:
#ifdef __SGI_STL_PORT
		typedef std::hash_map< INT, FIELD*>	FIELD_HASHMAP;
#else
	#ifdef __WINDOWS__
		typedef std::unordered_map< INT, FIELD*>	FIELD_HASHMAP;	// CYS: was stdext::hash_map
	#else
		typedef __gnu_cxx::hash_map< INT,FIELD*>    FIELD_HASHMAP;
							  // hash_compare <INT, less<INT> > ,
							   //allocator< pair<const INT, FIELD*> > >
							  
	#endif
		
#endif
		//数据库格式文件名
		UINT			m_ID;
		//数据库格式描述
		FILEDS_TYPE				m_theType;
		//行数
		INT						m_nRecordsNum;
		//列数
		INT						m_nFieldsNum;
		//数据区
		// CYS: was DATA_BUF m_vDataBuf (m_nRecordsNum*m_nFieldsNum FIELDs). Records now use the natural C layout of
		// CYS: the column types (see the note at the top of this file).
		std::vector< unsigned long long >	m_vRecordBuf;	// 8-byte aligned storage of all records
		std::vector< INT >		m_vFieldOffset;	// byte offset of each column inside a record
		INT						m_nRecordSize;	// bytes per record
		//字符串区
		CHAR*					m_pStringBuf;
		//字符串区大小
		INT						m_nStringBufSize;
		//索引表
		FIELD_HASHMAP			m_hashIndex;
		//索引列
		INT						m_nIndexColum;

	public:

		static INT			_ConvertStringToVector(const CHAR* strStrINTgSource, vector< std::string >& vRet, const CHAR* szKey, BOOL bOneOfKey, BOOL bIgnoreEmpty);
		//从内存中字符串读取一行文本(按照换行符)
		static const CHAR*	_GetLineFromMemory(CHAR* pStringBuf, INT nBufSize, const CHAR* pMemory, const CHAR* pDeadEnd);
		//比较两个值是否相等
		template < FIELD_TYPE T>
		static bool			_FieldEqu(const FIELD& a, const FIELD& b);

		// CYS: record layout helpers
		//取得记录的字节数 / 某列在记录中的偏移
		INT					GetRecordSize(VOID) const		{ return m_nRecordSize; }
		INT					GetFieldOffset(INT nColumn) const { return m_vFieldOffset[nColumn]; }
		// CYS: column type, for the runtime schema check of CDataBaseSystem::OpenAllDataBase (GMDataBase.cpp)
		FIELD_TYPE			GetFieldType(INT nColumn) const
		{
			return (nColumn >= 0 && nColumn < (INT)m_theType.size()) ? m_theType[nColumn] : T_INT;
		}
	protected:
		//按列类型计算记录布局(m_vFieldOffset, m_nRecordSize)
		VOID				_BuildLayout(VOID);
		//把逐列的FIELD数组(字符串已是运行时指针)写入记录区
		VOID				_BuildRecords(const DATA_BUF& vFields);
		//第nRecord行第nColumn列的地址
		FIELD*				_FieldAt(INT nRecord, INT nColumn) const
		{
			return (FIELD*)((CHAR*)&(const_cast<DBCFile*>(this)->m_vRecordBuf[0]) +
				(size_t)nRecord * m_nRecordSize + m_vFieldOffset[nColumn]);
		}

	public:
		DBCFile(UINT id);
		virtual ~DBCFile();
	};
}

#endif