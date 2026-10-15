//********************************************
//	Ini 相关函数
//********************************************


#include "Ini.h"
#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <cstring>
////////////////////////////////////////////////
// 通用接口
////////////////////////////////////////////////

//初始化
Ini::Ini()
{

	m_lDataLen = 0;
	m_strData = NULL;
	IndexNum = 0;
	IndexList = NULL;

}

//初始化
Ini::Ini( const char *filename )
{

	m_lDataLen=0;
	m_strData=NULL;
	IndexNum=0;
	IndexList=NULL;
	memset( m_strFileName, 0, _MAX_PATH ) ;
	memset( m_szValue, 0, MAX_INI_VALUE ) ;
	memset( m_szRet, 0, MAX_INI_VALUE) ;

	Open(filename);

}

//析构释放
Ini::~Ini()
{

	if( m_lDataLen != 0 )
	{
		delete( m_strData );
		m_lDataLen = 0;
	}

	if( IndexNum != 0 )
	{
		delete( IndexList );
		IndexNum = 0;
	}

}

//读入文件
bool Ini::Open( const char *filename )
{

	strncpy(m_strFileName, filename, _MAX_PATH-1);

	delete( m_strData );

	//获取文件长度
	FILE* fp;
	fp = fopen(filename,"rb");
	if(fp == 0)
	{
		m_lDataLen = -1;
	}
	else
	{
		fseek( fp, 0L, SEEK_END );
		m_lDataLen	= ftell( fp );
		fclose(fp);
	}
	
	
	//文件存在
	if( m_lDataLen > 0 )
	{
		m_strData = (char*)malloc( (size_t)m_lDataLen ) ;
		//m_strData = new char[m_lDataLen];
		memset( m_strData, 0, m_lDataLen ) ;

		FILE *fp;
		fp=fopen(filename, "rb");
		fread(m_strData, m_lDataLen, 1, fp);		//读数据
		fclose(fp);

		//初始化索引
		InitIndex();
		return true;
	}
	else	// 文件不存在
	{
		// 找不到文件
		m_lDataLen=1;
		m_strData = (char*)malloc( (size_t)m_lDataLen ) ;
		//m_strData = new char[m_lDataLen];
		memset(m_strData, 0, 1);
		InitIndex();
	}

	return false;


	return 0 ;
}

//关闭文件
void Ini::Close()
{

	if( m_lDataLen != 0 )
	{
		delete( m_strData );
		m_lDataLen = 0;
	}

	if( IndexNum != 0 )
	{
		delete( IndexList );
		IndexNum = 0;
	}

}

//写入文件
bool Ini::Save(char *filename)
{

	if( filename==NULL )
	{
		filename=m_strFileName;
	}

	FILE *fp;
	fp=fopen(filename, "wb");

	fwrite(m_strData, m_lDataLen, 1, fp);
	fclose(fp);

	return true;


	return false ;
}

//返回文件内容
char *Ini::GetData()
{

	return m_strData;

}

//获得文件的行数
int Ini::GetLines(int cur)
{

	int n=1;
	for(int i=0; i<cur; i++)
	{
		if( m_strData[i]=='\n' )
			n++;
	}
	return n;

}

//获得文件的行数
int Ini::GetLines()
{

	int		n = 0;
	int		i;
	for(i=0; i<m_lDataLen; i++)
	{
		if( m_strData[i]=='\n' )
			n++;
	}
	if(i>=m_lDataLen)
		return n+1;
	return n;

}

////////////////////////////////////////////////
// 内部函数
////////////////////////////////////////////////

//计算出所有的索引位置
void Ini::InitIndex()
{

	IndexNum=0;

	for(int i=0; i<m_lDataLen; i++)
	{
		//找到
		if( m_strData[i]=='[' && ( i==0 || m_strData[i-1]=='\n' ) )
		{
			IndexNum++;
		}
	}

	//申请内存
	delete( IndexList );
	if( IndexNum>0 )
		IndexList=new int[IndexNum];

	int n=0;

	for(int i=0; i<m_lDataLen; i++)
	{
		if( m_strData[i]=='[' && ( i==0 || m_strData[i-1]=='\n' ) )
		{
			IndexList[n]=i+1;
			n++;
		}
	}
}

//返回指定标题位置
int Ini::FindIndex(char *string)
{

	for(int i=0; i<IndexNum; i++)
	{
		char *str=ReadText( IndexList[i] );
		if( strcmp(string, str) == 0 )
		{
//			delete( str );
			return IndexList[i];
		}
//		delete( str );
	}
	return -1;


	return 0 ;
}

//返回指定数据的位置
int Ini::FindData(int index, char *string)
{

	int p=index;	//指针

	while(1)
	{
		p=GotoNextLine(p);
		char *name=ReadDataName(p);
		if( strcmp(string, name)==0 )
		{
			delete( name );
			return p;
		}

		if ( name[0] == '[' )
		{
			delete( name );
			return -1;
		}

		delete( name );
		if( p>=m_lDataLen ) return -1;
	}
	return -1;


	return 0 ;
}

//提行
int Ini::GotoNextLine(int p)
{

	int i;
	for(i=p; i<m_lDataLen; i++)
	{
		if( m_strData[i]=='\n' )
			return i+1;
	}
	return i;

}

//在指定位置读一数据名称
char *Ini::ReadDataName(int &p)
{

	char chr;
	char *Ret;
	int m=0;

	Ret=new char[64];
	memset(Ret, 0, 64);

	for(int i=p; i<m_lDataLen; i++)
	{
		chr = m_strData[i];

		//结束
		if( chr == '\r' )
		{
			p=i+1;
			return Ret;
		}
		
		//结束
		if( chr == '=' || chr == ';' )
		{
			p=i+1;
			return Ret;
		}
		
		Ret[m]=chr;
		m++;
	}
	return Ret;


	return 0 ;
}

//在指定位置读一字符串
char *Ini::ReadText(int p)
{

	char chr;
	char *Ret;
	int n=p, m=0;

	int LineNum = GotoNextLine(p) - p + 1;
	Ret=(char*)m_szValue;//new char[LineNum];
	memset(Ret, 0, LineNum);

	for(int i=0; i<m_lDataLen-p; i++)
	{
		chr = m_strData[n];

		//结束
		if( chr == ';' || chr == '\r' || chr == '\t' || chr == ']' )
		{
			//ShowMessage(Ret);
			return Ret;
		}
		
		Ret[m]=chr;
		m++;
		n++;
	}

	return Ret;


	return 0 ;
}

//加入一个索引
bool Ini::AddIndex(char *index)
{

	char str[256];
	memset(str, 0, 256);
	int n=FindIndex(index);

	if( n == -1 )	//新建索引
	{
		sprintf(str,"\r\n[%s]",index);
		m_strData = (char *)realloc(m_strData, m_lDataLen+strlen(str));	//重新分配内存
		sprintf(&m_strData[m_lDataLen], "%s", str);
		m_lDataLen+=(long)(strlen(str));

		InitIndex();
		return true;
	}
	
	return false;	//已经存在


	return 0 ;
}

//在当前位置加入一个数据
bool Ini::AddData(int p, char *name, char *string)
{

	char *str;
	int len=(int)(strlen(string));
	str=new char[len+256];
	memset(str, 0, len+256);
	sprintf(str,"%s=%s",name,string);
	len=(int)(strlen(str));

	p=GotoNextLine(p);	//提行
	m_strData = (char *)realloc(m_strData, m_lDataLen+len);	//重新分配内存

	char *temp=new char[m_lDataLen-p];
	memcpy(temp, &m_strData[p], m_lDataLen-p);
	memcpy(&m_strData[p+len], temp, m_lDataLen-p);	//把后面的搬到末尾
	memcpy(&m_strData[p], str, len);
	m_lDataLen+=len;

	delete( temp );
	delete( str );
	return true;


	return 0 ;
}

//在当前位置修改一个数据的值
bool Ini::ModityData(int p, char *name, char *string)
{

	int n=FindData(p, name);

	char *t=ReadText(n);
	p=n+(int)(strlen(t));
//	if( strlen(t)>0 ) free(t);

	int newlen=(int)(strlen(string));
	int oldlen=p-n;

	m_strData = (char *)realloc(m_strData, m_lDataLen+newlen-oldlen);	//重新分配内存

	char *temp=new char[m_lDataLen-p];
	memcpy(temp, &m_strData[p], m_lDataLen-p);
	memcpy(&m_strData[n+newlen], temp, m_lDataLen-p);			//把后面的搬到末尾
	memcpy(&m_strData[n], string, newlen);
	m_lDataLen+=newlen-oldlen;

	delete( temp );
	return true;


	return 0 ;
}

//把指针移动到本INDEX的最后一行
int Ini::GotoLastLine(char *index)
{

	int n=FindIndex(index);
	n=GotoNextLine(n);
	while(1)
	{
		if( m_strData[n] == '\r' || m_strData[n] == EOF || m_strData[n] == -3 || m_strData[n] == ' ' || m_strData[n] == '/' || m_strData[n] == '\t' || m_strData[n] == '\n' )
		{
			return n;
		}
		else
		{
			n=GotoNextLine(n);
			if( n >= m_lDataLen ) return n;
		}
	}


	return 0 ;
}

/////////////////////////////////////////////////////////////////////
// 对外接口
/////////////////////////////////////////////////////////////////////

//以普通方式读一字符串数据
char *Ini::ReadText(char *index, char *name, char* str, int size)
{

	char szTmp[512] ;
	memset( szTmp, 0, 512 ) ;
	sprintf( szTmp, "[%s][%s][%s]", m_strFileName, index, name ) ;

	int n=FindIndex(index);
	if ( n == -1 )
		return NULL;

	int m=FindData(n, name);
	if ( m == -1 )
		return NULL;

	char* ret = ReadText(m);
	strncpy( str, ret, size ) ;
	return ret ;


	return 0 ;
}

//如果存在则读取
bool Ini::ReadTextIfExist(char *index, char *name, char* str, int size)
{
	int n = FindIndex(index);
	
	if( n == -1 )
		return false;

	int m = FindData(n, name);
	
	if( m == -1 )
		return false;

	char* ret = ReadText(m);
	strncpy( str, ret, size );
	return true;
}
	
//在指定的行读一字符串
char *Ini::ReadText(char *index, int lines, char* str, int size)
{

	char szTmp[512] ;
	memset( szTmp, 0, 512 ) ;
	sprintf( szTmp, "[%s][%s][%d]", m_strFileName, index, lines ) ;

	int n=FindIndex(index);

	//跳到指定行数
	n=GotoNextLine(n);
	for(int i=0; i<lines; i++)
	{
		if( n<m_lDataLen )
			n=GotoNextLine(n);
	}

	//读数据
	while( n<=m_lDataLen )
	{
		if( m_strData[n] == '=' )
		{
			n++;
			char* ret = ReadText(n);
			strncpy( str, ret, size ) ;
			return ret ;
		}
		if( m_strData[n] == '\r' )
		{
			return NULL;
		}
		n++;
	}

	return NULL;


	return 0 ;
}

//以普通方式读一整数
int Ini::ReadInt(char *index, char *name)
{

	char szTmp[512] ;
	memset( szTmp, 0, 512 ) ;
	sprintf( szTmp, "[%s][%s][%s]", m_strFileName, index, name ) ;

	int n=FindIndex(index);
	int m=FindData(n, name);

	char *str=ReadText(m);
	int ret=atoi(str);
	return ret;
}

bool Ini::ReadIntIfExist(char *section, char *key, int& nResult)
{
	int n=FindIndex(section);

	if( n == -1 )
		return false;

	int m=FindData(n, key);

	if( m == -1 )
		return false;

	char *str=ReadText(m);
	nResult=atoi(str);
	return true;
}

//在指定的行读一整数
int Ini::ReadInt(char *index, int lines)
{

	char szTmp[512] ;
	memset( szTmp, 0, 512 ) ;
	sprintf( szTmp, "[%s][%s][%d]", m_strFileName, index, lines ) ;

	int n=FindIndex(index);
	//跳到指定行数
	n=GotoNextLine(n);
	for(int i=0; i<lines; i++)
	{
		if( n<m_lDataLen )
			n=GotoNextLine(n);
	}

	//读数据
	while( n<m_lDataLen )
	{
		if( m_strData[n] == '=' )
		{
			n++;
			char *str=ReadText(n);
			int ret=atoi(str);
//			free(str);
			return ret;
		}
		if( m_strData[n] == '\r' )
		{
			return ERROR_DATA;
		}
		n++;
	}

	return ERROR_DATA;


	return 0 ;
}

//在指定的行读一数据名称
char *Ini::ReadCaption(char *index, int lines, char* str, int size)
{

	char szTmp[512] ;
	memset( szTmp, 0, 512 ) ;
	sprintf( szTmp, "[%s][%s][%d]", m_strFileName, index, lines ) ;

	int n=FindIndex(index);

	//跳到指定行数
	n=GotoNextLine(n);
	for(int i=0; i<lines; i++)
	{
		if( n<m_lDataLen )
			n=GotoNextLine(n);
	}

	char* ret = ReadDataName(n);
	strncpy( str, ret, size ) ;
	return ret ;


	return 0 ;
}

//以普通方式写一字符串数据
bool Ini::Write(char *index, char *name, char *string)
{

	int n=FindIndex(index);
	if( n == -1 )	//新建索引
	{
		AddIndex(index);
		n=FindIndex(index);
		n=GotoLastLine(index);
		AddData(n, name, string);	//在当前位置n加一个数据
		return true;
	}

	//存在索引
	int m=FindData(n, name);
	if( m==-1 )		//新建数据
	{
		n=GotoLastLine(index);
		AddData(n, name, string);	//在当前位置n加一个数据
		return true;
	}

	//存在数据
	ModityData(n, name, string);	//修改一个数据

	return true;


	return 0 ;
}

//以普通方式写一整数
bool Ini::Write(char *index, char *name, int num)
{

	char string[32];
	sprintf(string, "%d", num);

	int n=FindIndex(index);
	if( n == -1 )	//新建索引
	{
		AddIndex(index);
		n=FindIndex(index);
		n=GotoLastLine(index);
		AddData(n, name, string);	//在当前位置n加一个数据
		return true;
	}

	//存在索引
	int m=FindData(n, name);
	if( m==-1 )		//新建数据
	{
		n=GotoLastLine(index);
		AddData(n, name, string);	//在当前位置n加一个数据
		return true;
	}

	//存在数据
	ModityData(n, name, string);	//修改一个数据

	return true;


	return 0 ;
}

//返回连续的行数
int Ini::GetContinueDataNum(char *index)
{

	int num=0;
	int n=FindIndex(index);
	n=GotoNextLine(n);
	while(1)
	{
		if( m_strData[n] == '\r' || m_strData[n] == EOF || m_strData[n] == -3 || m_strData[n] == ' ' || m_strData[n] == '/' || m_strData[n] == '\t' || m_strData[n] == '\n' )
		{
			return num;
		}
		else
		{
			num++;
			n=GotoNextLine(n);
			if( n >= m_lDataLen ) return num;
		}
	}


	return 0 ;
}
//在指定行读一字符串
char* Ini::ReadOneLine(int p)
{
	int start = FindOneLine(p);
	memset(m_szRet,0,sizeof(m_szRet));
	

	for(int i=start; i<m_lDataLen; i++)
	{
		if( m_strData[i]=='\n' || m_strData[i]=='\0')
		{
			memset(m_szRet,0,sizeof(m_szRet));
			strncpy(m_szRet,&m_strData[start],i-start);
			m_szRet[i-start] = '\0';
			return m_szRet;
		}

	}
}
int Ini::FindOneLine(int p)
{
	char*	Ret = NULL;
	int		n = 0;
	int     m = 0;
	if(p==0)	return -1;
	if(p==1)	return 0;
	for(int i=0; i<m_lDataLen; i++)
	{
		if ( m_strData[i]=='\n' )
			n++;
		if ( n==p-1 )				//找到要了要找的的行
			return i+1;
	}

	return -1; //没有找到
}
int Ini::ReturnLineNum(char* string)
{
	int p = FindIndex(string);
	char*	Ret = NULL;
	int		n = 0;
	int     m = 0;
	if(p==0)	return -1;
	if(p==1)	return 0;
	for(int i=0; i<p; i++)
	{
		if ( m_strData[i]=='\n' )
			n++;
	}
	return n;

	return -1; //没有找到
}

