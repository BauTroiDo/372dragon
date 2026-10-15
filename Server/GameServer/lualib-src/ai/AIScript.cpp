/*************************************************************************
文件名	: 	AIScript.cpp
版本号 :	0.0.2
功  能	:	针对特有的扩展AI脚本编写的解析及执行类
修改记录:	修改了前版接口函数扩展性不强的缺点
*************************************************************************/

#include "AIScript.h"
#include "AIScriptDef.h"
#include "AIBridge.h"
#include <vector>
#include <string>
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>

AIScript::AIScript()
{
	m_pcdtList = NULL;
	m_pcdtList = NULL;
    m_poptorNodeList = NULL;
	m_pcdtNodeList = NULL;
	m_ptodoNodeList = NULL;
	m_pcdtTree = NULL;
	m_pcdtNode = NULL;
	m_nID = -1;
	m_fX = 0;
	m_fZ = 0;
	m_index = 0;
	memset(m_vStateLists, 0, sizeof(ConditionList*) * (ONDEADSECTION+1));
}

AIScript::~AIScript()
{
	ClearCdtList();
}

bool AIScript::ParseScriptForPet(const char* filename)
{
	m_file.Open(filename);
	int		line = m_file.GetLines();
	char*	szScript;

	//////////////////////////////////////////////////////////////////////////
	//解析follow部分
	szScript = NULL;
	int start = m_file.ReturnLineNum("follow");
	int end = m_file.ReturnLineNum("followend");
	for (int i=start+1 ; i<end; i++)
	{
		szScript = m_file.ReadOneLine(i+1);
		if (szScript == NULL)
		{
			continue;
		}

		ParseOneScript(szScript);
	}
	InitList(SFOLLOW);
	//////////////////////////////////////////////////////////////////////////
	//解析attack部分
	szScript = NULL;
	start = m_file.ReturnLineNum("attack");
	end = m_file.ReturnLineNum("attackend");
	for (int i=start+1 ; i<end; i++)
	{
		szScript = m_file.ReadOneLine(i+1);
		if (szScript == NULL)
		{
			continue;
		}

		ParseOneScript(szScript);
	}
	InitList(SATTACK);
	//////////////////////////////////////////////////////////////////////////
	//解析beskill部分
	szScript = NULL;
	start = m_file.ReturnLineNum("beskill");
	end = m_file.ReturnLineNum("beskillend");
	for(int  i = start+1 ; i < end; i++)
	{
		szScript = m_file.ReadOneLine(i+1);
		if (szScript == NULL)
		{
			continue;
		}

		ParseOneScript(szScript);
	}
	InitList(ONBESKILLSECTION);

	return true;
}

bool AIScript::ParseScript(const char* filename)
{
	m_file.Open(filename);
	int		line = m_file.GetLines();
	char*	szScript;

	m_nID = -1;
	//////////////////////////////////////////////////////////////////////////
	//解析common部分
	szScript = NULL;
	int start = m_file.ReturnLineNum("common");
	int end = m_file.ReturnLineNum("commonend");
	for (int i=start+1 ; i<end; i++)
	{
		szScript = m_file.ReadOneLine(i+1);
		if (szScript == NULL)
		{
			continue;
		}

		ParseOneScript(szScript);
	}
	//处理m_pcdtList，将其分解到各个状态List中，如m_pIdleList,m_pAttackList...
	InitAllStateList();
	//////////////////////////////////////////////////////////////////////////
	//解析skill部分
	szScript = NULL;
	start = m_file.ReturnLineNum("skill");
	end = m_file.ReturnLineNum("skillend");
	for(int i = start+1 ; i < end; i++)
	{
		szScript = m_file.ReadOneLine(i+1);
		if(szScript == NULL)
		{
			continue;
		}

		ParseOneScript(szScript);
	}
	InitList(SKILLSECTION);
	//////////////////////////////////////////////////////////////////////////
	//解析beskill部分
	szScript = NULL;
	start = m_file.ReturnLineNum("beskill");
	end = m_file.ReturnLineNum("beskillend");
	for(int i = start+1 ; i < end; i++)
	{
		szScript = m_file.ReadOneLine(i+1);
		if (szScript == NULL)
		{
			continue;
		}

		ParseOneScript(szScript);
	}
	InitList(ONBESKILLSECTION);
	//////////////////////////////////////////////////////////////////////////
	//解析damage部分
	szScript = NULL;
	start = m_file.ReturnLineNum("damage");
	end = m_file.ReturnLineNum("damageend");
	for (int i = start+1 ; i < end; i++)
	{
		szScript = m_file.ReadOneLine(i+1);
		if(szScript == NULL)
		{
			continue;
		}

		ParseOneScript(szScript);
	}
	InitList(ONDAMAGESECTION);
	//////////////////////////////////////////////////////////////////////////
	//解析dead部分
	szScript = NULL;
	start = m_file.ReturnLineNum("dead");
	end = m_file.ReturnLineNum("deadend");
	for(int i = start+1 ; i < end; i++)
	{
		szScript = m_file.ReadOneLine(i+1);
		if(szScript == NULL)
		{
			continue;
		}

		ParseOneScript(szScript);
	}
	InitList(ONDEADSECTION);

	return true;
}

bool AIScript::ParseOneScript(const char* szScript)
{
	//对每行字符串进行子字符串查找
	char		szCmd[64];
	const char*		pDest;		
	int j = 0;
	int index = 0;
	int prev = 0;
	int len = (int)strlen(szScript);
	memset(szCmd,0, sizeof(szCmd));

	bool bToDoFlag = false;

	pDest = strstr(szScript, ":");
	if (pDest && (int)(pDest-szScript+1) > 0)
	{
		j = (int)(pDest-szScript+1);
		char szID[8];
		memset(szID, 0, sizeof(szID));
		memcpy(szID, szScript, j-1);
		//m_nID = atol(szID);
		
		if (m_nID++ >= AISCRIPT_NUM)
		{
			assert(NULL && "id > AISCRIPT_NUM...array overflow...");
			return false;
		}

	}
	else
	{
		//MessageBox(NULL,"Script Error!!!","Error",MB_OK);
		return false;
	}

	for (; j < len; j++)
	{
		switch(ParseCHAR(&szScript[j])) 
		{
		case ANDOROP:
			{//如果是'&','|','(',')'
				Atom atom;
				memcpy(atom.szCHAR, &szScript[j], 1);
				atom.pos = j;
				if (szScript[j] == '|')
				{
					atom.PRI = 0;

					ProcessCtdOrToDoQ(szCmd, bToDoFlag);

					memset(szCmd,0, sizeof(szCmd));
					index = 0;
				}
				else if (szScript[j] == '&')
				{
					atom.PRI = 0;

					ProcessCtdOrToDoQ(szCmd, bToDoFlag);

					memset(szCmd,0,sizeof(szCmd));
					index = 0;
				}
				else if (szScript[j] == '(' && !bToDoFlag)
				{
					m_array.array[m_array.count++] = static_cast<int>(m_operatorQ.size());
				}
				else if(szScript[j] == ')')
				{
					if (!bToDoFlag)
					{
						for(int m = m_array.array[m_array.count-1]+1; m < static_cast<int>(m_operatorQ.size()); m++)
						{//使被()括住的'&','|'的优先级增加
							if(m_operatorQ[m].szCHAR[0]=='&'
								||m_operatorQ[m].szCHAR[0]=='|')
							{
								m_operatorQ[m].PRI += 2;
							}
						}
						m_array.count--;
					}

					char* pParamString = "";
					if (!FindParam(szScript, j, pParamString))
					{
						ProcessCtdOrToDoQ(szCmd, bToDoFlag);
						memset(szCmd,0, sizeof(szCmd));
						index = 0;
					}
					else
					{
						if (!bToDoFlag)
						{
							sprintf(m_cdtExpQ[m_cdtExpQ.size()-1].szCHAR, "%s%c%s%c",
								m_cdtExpQ[m_cdtExpQ.size()-1].szCHAR,
								'(',
								szCmd,
								')');

							char* pString = m_cdtExpQ[m_cdtExpQ.size()-1].szCHAR;
							memset(szCmd,0,sizeof(szCmd));
							index = 0;
						}
						else
						{
							sprintf(m_todoExpQ[m_todoExpQ.size()-1].szCHAR, "%s%c%s%c",
								m_todoExpQ[m_todoExpQ.size()-1].szCHAR,
								'(',
								szCmd,
								')');

							char* pString = m_todoExpQ[m_todoExpQ.size()-1].szCHAR;
							memset(szCmd,0, sizeof(szCmd));
							index = 0;
						}
					}
				}

				//向操作符队列添加
				if (!bToDoFlag)
				{
					m_operatorQ.push_back(atom);
				}
				
				//向条件表达式队列添加
				if (strcmp(szCmd, "") != 0)
				{
					if (strcmp(szCmd,"if") == 0)
						;
					else if (!bToDoFlag) 
					{
						memcpy(atom.szCHAR, szCmd, sizeof(szCmd));
						atom.pos = j-1;
						atom.PRI = -1;
						m_cdtExpQ.push_back(atom);
					}
					else
					{
						memcpy(atom.szCHAR, szCmd, sizeof(szCmd));
						m_todoExpQ.push_back(atom);
					}

					memset(szCmd,0, sizeof(szCmd));
					index = 0;
				}

			}
			break;
		case TODOOP:
			{
				bToDoFlag = true;
				Atom atom;
				//向行为表达式队列添加
				if (strcmp(szCmd, "") != 0)
				{
					//if(VerifyExpress(szCmd)==false)
					//	break;
					memcpy(atom.szCHAR, szCmd, sizeof(szCmd));
					m_todoExpQ.push_back(atom);
					memset(szCmd,0, sizeof(szCmd));
					index = 0;
				}
				if (szScript[j] == '}')
				{//为了能在条件脚本的后面添加注释
					goto Next;
				}
			}
			break;
		case OTHEROP:
		case RELATIONOP:
		case PARAMOP:
			{
				memcpy(&szCmd[index++], &szScript[j], 1);
			}
			break;
		default:
			break;
		}

	}

Next:

	if(m_array.count)
	{
		//MessageBox(NULL,"Script Error!!!","Error",MB_OK);
		return false;
	}

	//PrINTQ();
	ProcessOptorQ();
	ProcessCdtQ();
	ProcessToDoQ();
	ClearQ();

	//PrINTList();e
	//生成条件树
	CreateCdtTree();
	//生成条件节点
	CreateCdtNode();
	//加入到条件节点链表中
	InsertCdtNodeToCdtList();

	ClearList();

	return true;
}

bool AIScript::ProcessScript(int nState, sol::table pAI)
{
	if (nState == 13){
		// std::cout << "AIScript::ProcessScript nState = " << nState << endl;
	}
	ReSetNeedGoDist(pAI);
	//将m_pcdtList中的条件节点依次取出
	ConditionList* pCur = NULL;
	pCur = m_vStateLists[nState];

	while(pCur)
	{
		bool ret = false;
		//判断条件是否成功，执行条件语句
		//取出m_pcdtList中的ConditionTree,解析树结构
		ConditionTree* pTree = NULL;
		pTree = pCur->pNode->pRootCondition;
		
		//将AI_xxx中的times的数据复制给相应的Node的times
		int id = pCur->pNode->id;
		if (id >= AISCRIPT_NUM)
		{
			assert(NULL && "id > AISCRIPT_NUM...array overflow...");
			return false;
		}
		//pCur->pNode->times = GetAIScriptTimes(pAI, id);
		// std::cout << "AIScript::ProcessScript id = " << id << " pCur->pNode->times =" << pCur->pNode->times << endl;
		if(pCur->pNode->times > 0 || pCur->pNode->times == -1)
		{
			ret = ExcuteCdtScript(pTree, pAI);
		}
        else
		{
			pCur = pCur->pNext;
			continue;
		}
		// std::cout << "AIScript::ProcessScript id = " << id << " ret =" << ret << endl;
		//如果条件成立，则执行行为语句
		//取出m_pcdtList中的pToDo,解析toDo结构
		if (true == ret)
		{
			ExcuteToDoScript(pCur->pNode->pToDo, pAI);
			pCur->pNode->SetDownFlag(1);//设置该操作执行过

			if (pCur->pNode->times > 0)
			{// 只是不想改变原来的结构和逻辑 故这样做:)...
				pCur->pNode->times--;
				if (pCur->pNode->times < 0)
					pCur->pNode->times = 0;
			}
			if (pCur->pNode->times == 0)
			{
				pCur->pNode->SetDownFlag(0);//设置该操作执行完
			}
			return true;
		}
		else
		{
			if (SKILLSECTION == nState) 
			{
					int idSkill = GetSkillID(pAI);
					float fTmpDist = GetNeedGoDist(pAI, idSkill);
					float fNeedGoDist = GetNeedGoDist(pAI);
					if (fTmpDist > 0 && fNeedGoDist > fTmpDist)
					{
						SetNeedGoDist(pAI, fTmpDist);
						SetSkillID(pAI, idSkill);
					}
			}
		}
		pCur = pCur->pNext;
	}
	if (NULL == pCur) 
	{/** 一个也没有执行成功 */
		return false;
	}

	return true;
}
//pReturn为上一次执行的结果
bool AIScript::ExcuteCdtScript(ConditionTree* p, sol::table pAI)
{
	bool ret = false;
	bool bContinue = false;
	if (NULL == p)
	{
		return false;
	}
	// 确保stack的正确性, 每次使用前先重置一次
	m_stack.Reset();
	do
	{
		while(p != NULL)
		{
			m_stack.push((Elem*)p);
			p = p->pLeft;
		}

		do
		{
			p = (ConditionTree*)m_stack.pop();

			if (!p)
			{
				//assert(NULL && "AIScript::ExcuteCdtScript...p = (ConditionTree*)m_stack.pop() = NULL!!");
				return false;
			}
			if (p->Node.op != OPTAND && p->Node.op != OPTOR && p->Node.op != OPTROOT) 
			{
				//执行条件表达式
				ret = ExcuteExpress(&p->Node, pAI);

				if (ret==true && p->pParent->Node.op==OPTOR
					 || ret==false && p->pParent->Node.op==OPTAND)
				{
					bContinue = true;
				}
				else
				{
					bContinue = false;
				}

			}
			else if (ret == true && p->Node.op == OPTAND)
			{
				bContinue = false;
			}
			else if (ret == true && p->Node.op == OPTOR)
			{
				bContinue = true;
			}
			else if (ret == false && p->Node.op == OPTOR)
			{
				bContinue = false;
			}
			else if (ret == false && p->Node.op == OPTAND)
			{
				bContinue = true;
			}
			else
			{
				bContinue = false;
			}


		}while (bContinue==true);

		p = p->pRight;

	}while (!(m_stack.isEmpty() && p==NULL));

	return ret;

}

bool AIScript::ExcuteToDoScript(TreeNodeList* p, sol::table pAI)
{
	bool bRet = false;
	while(p != NULL)
	{
		bRet = ExcuteToDoExpress(&p->Node, pAI);
		p = p->pNext;
	}

	return bRet;

}

bool AIScript::ExcuteExpress(const TreeNode* p, sol::table pAI)
{
	if(p==NULL)
	{
		assert(false);
		return false;
	}

	int op = p->op;
	int rRet = p->value;
	const char* name = GetFuncNamebyPtr(p->FuncPtr);
	// std::cout << "AIScript::GetCharacter" << endl;
	sol::table pChar = GetCharacter(pAI);
	// std::cout << "AIScript::ExcuteExpress func = " << name << endl;
	int lRet = p->FuncPtr(pChar, p->param[0], p->param[1], p->param[2]);
	// std::cout << "AIScript::ExcuteExpress lRet = " << lRet << " ,rRet = " << rRet << endl;
	switch(op) 
	{
	case OPTEQUAL:
		return lRet==rRet?true:false;
	case OPTLESSTHAN:
		return lRet<rRet?true:false;
	case OPTLESSEQUAL:
		return lRet<=rRet?true:false;
	case OPTLARGETHAN:
		return lRet>rRet?true:false;
	case OPTLARGEEQUAL:
		return lRet>=rRet?true:false;
	case OPTUNEQUAL:
		return lRet!=rRet?true:false;
	default:
		assert(false);
		break;
	}

	return true;

}

bool AIScript::ExcuteToDoExpress(const TreeNode * p, sol::table pAI)
{
	if(p==NULL)
	{
		assert(false);
		return false;
	}
	sol::table pChar = GetCharacter(pAI);
	int ret = p->FuncPtr(pChar, p->param[0], p->param[1], p->param[2]);
	const char* name = GetFuncNamebyPtr(p->FuncPtr);
	// std::cout << "AIScript::ExcuteToDoExpress func = " << name 
	// << " param[0] =" << p->param[0] << " param[1] =" 
	// << p->param[1] << " param[2] =" << p->param[2] << " ret =" << ret << endl;
	if(0 < ret)
		return true;
	else
		return false;

	return false;
}

void AIScript::ReSetTimes(void)
{
	ConditionList* pCur = NULL;
	pCur = m_pcdtList;
	while(pCur)
	{
		pCur->pNode->times = pCur->pNode->times2;
		pCur = pCur->pNext;
	} 


}

int	AIScript::ParseCHAR(const char* szch)
{
	switch(*szch)
	{
	case '=':
	case '>':
	case '<':
	case '!':
		return RELATIONOP;
	case '&':
	case '|':
	case '(':
	case ')':
		return ANDOROP;
	case ';':
	case '{':
	case '}':
		return TODOOP;
	default:
		return OTHEROP;
	}	

	return true;

}

bool AIScript::ProcessOptorQ(void)
{
	for(int i=0; i < static_cast<int>(m_operatorQ.size()); i++)
	{
		if (m_operatorQ[i].szCHAR[0]=='&'
			 ||m_operatorQ[i].szCHAR[0]=='|')
		{
			InsertToNodeList(m_operatorQ[i], OPERATOR);
		}
	}

	return true;

}

bool AIScript::ProcessCdtQ()
{
	for (int i=0; i < static_cast<int>(m_cdtExpQ.size()); i++)
	{
		InsertToNodeList(m_cdtExpQ[i], CDTEXPRESSION);
	}

	return true;

}

bool AIScript::ProcessToDoQ(void)
{
	for (int i = 0; i < static_cast<int>(m_todoExpQ.size()); i++)
	{
		InsertToNodeList(m_todoExpQ[i], TODOEXPRESSION);
	}

	return true;

}

bool AIScript::CreateCdtTree(void)
{
	m_pcdtTree = NULL;
	if (m_poptorNodeList == NULL && m_pcdtNodeList == NULL)
	{
		return false;
	}

	//生成新的条件树的根节点
	ConditionTree* pRoot = NULL;
	pRoot = new ConditionTree;
	if(pRoot == NULL)
	{
		assert(false);
		return false;
	}

	//第一步，根据操作符list生成树框架
	TreeNodeList* pList = m_poptorNodeList;
	while(pList)
	{
		//new出一个新的树结点
		ConditionTree* pNewTree = NULL;
		pNewTree = new ConditionTree;
		if (pNewTree == NULL)
		{
			assert(false);
			return false;
		}
		//进行插入操作-->是第一次插入
		if(m_pcdtTree == NULL)
		{
			//根节点不进行赋值
			m_pcdtTree = pRoot; 
			//将list表中的Node复制一份到pNewTree;
			pNewTree->Node = pList->Node;
			m_pcdtTree->pLeft = pNewTree;
			pNewTree->pParent = pRoot;

		}
		else
		{
			//从根节点的左子节点寻找位置
			ConditionTree* pCur = pRoot->pLeft;
			ConditionTree* pParent = NULL;
			while(pCur)
			{
				pParent = pCur;
				if (pList->Node.pos > pCur->Node.pos)
				{
					pCur = pCur->pRight;
				}
				else
				{
					pCur = pCur->pLeft;
				}
			}
			pNewTree->Node = pList->Node;
			if (pNewTree->Node.pos>pParent->Node.pos)
			{
				pParent->pRight = pNewTree;
			}
			else
			{
				pParent->pLeft = pNewTree;
			}

			pNewTree->pParent = pParent;

		}


		pList = pList->pNext;
	}

	//第二步，根据条件表达式list生成完整的条件树
	pList = m_pcdtNodeList;
	while (pList)
	{
		//new出一个新的树结点
		ConditionTree* pNewTree = NULL;
		pNewTree = new ConditionTree;
		if(pNewTree == NULL)
		{
			assert(false);
			return false;
		}
		//进行插入操作-->是第一次插入
		//该情况只有当条件表达式为if(HP<10)这样的时候才能进入
		if (m_pcdtTree==NULL)
		{
			//根节点不进行赋值
			m_pcdtTree = pRoot; 
			//将list表中的Node复制一份到pNew;
			pNewTree->Node = pList->Node;
			m_pcdtTree->pLeft = pNewTree;
			pNewTree->pParent = pRoot;

		}
		else
		{
			//从根节点的左子节点寻找位置
			ConditionTree* pCur = pRoot->pLeft;
			ConditionTree* pParent=NULL;
			while (pCur)
			{
				pParent = pCur;
				if (pList->Node.pos>pCur->Node.pos)
				{
					pCur = pCur->pRight;
				}
				else
				{
					pCur = pCur->pLeft;
				}
			}

			pNewTree->Node = pList->Node;
			if (pNewTree->Node.pos>pParent->Node.pos)
			{
				pParent->pRight = pNewTree;
			}
			else
			{
				pParent->pLeft = pNewTree;
			}
			pNewTree->pParent = pParent;

		}


		pList = pList->pNext;
	}
	return true;

}

bool AIScript::CreateCdtNode(void)
{
	m_pcdtNode = NULL;
	//判断条件树是否存在
	if (m_pcdtTree == NULL)
	{
		return false;
	}

	//生成新的条件节点
	m_pcdtNode = new ConditionNode;
	if (m_pcdtNode == NULL)
	{
		assert(false);
		return false;
	}

	//将解析的id赋值给m_pcdtNode->id
	m_pcdtNode->id = m_nID;
	//使条件节点中的树指针指向生成的条件树结点
	m_pcdtNode->pRootCondition = m_pcdtTree;

	//根据行为表达式list生成条件节点的toDo项
	TreeNodeList* pCur = NULL;
	//-------------------------------------------------------------------------
	pCur = m_ptodoNodeList;
	TreeNodeList* pParent = NULL;
	int i=0, count = 0;
	while (pCur)
	{
		//把TIMES的表达式提取到Node结构体中
		const char* FuncName = GetFuncNamebyPtr(pCur->Node.FuncPtr);
		if(FuncName && strcmp(FuncName, "AIS_SetTimes") == 0)
		{
			TreeNodeList* pTemp = pCur;
			m_pcdtNode->times   = pCur->Node.param[0];
			m_pcdtNode->times2  = pCur->Node.param[0];
			if (pParent == NULL)
			{
				pTemp = pCur;
				pCur = pCur->pNext;
				pTemp->pNext = NULL ;
			}
			else
			{
				pTemp = pCur;
				pParent->pNext = pCur->pNext;
				pCur = pCur->pNext ;
				pTemp->pNext = NULL;
			}
			delete(pTemp) ; // 删除该节点

			continue;
		}
		else if(FuncName && strcmp(FuncName, "AIS_SetPRI") == 0)
		{
			TreeNodeList* pTemp = pCur;
			m_pcdtNode->PRI  = pCur->Node.param[0];
			if (pParent == NULL)
			{
				pTemp = pCur;
				pCur = pCur->pNext;
				pTemp->pNext = NULL ;
			}
			else
			{
				pTemp = pCur;
				pParent->pNext = pCur->pNext;
				pCur = pCur->pNext ;
				pTemp->pNext = NULL;
			}
			delete(pTemp) ; // 删除该节点

			continue;
		}

		count++;
		pParent = pCur;
		pCur = pCur->pNext;
	}

	pCur = NULL;
	pCur = m_ptodoNodeList;
	while (pCur && i<count)
	{
		TreeNodeList* pToDoList = NULL;
		pToDoList = new TreeNodeList;
		if (pToDoList == NULL)
		{
			assert(false);
			return false;
		}

		pToDoList->Node = pCur->Node;
		TreeNodeList* pTmp = NULL;
		pTmp = m_pcdtNode->pToDo;

		if (pTmp == NULL)
		{
			m_pcdtNode->pToDo = pToDoList;
		}
		else
		{
			while (pTmp->pNext)
			{
				pTmp = pTmp->pNext;
			}
			pTmp->pNext = pToDoList;
		}
		pCur = pCur->pNext;
		i++;

	}

	return true;

}

bool AIScript::InsertCdtNodeToCdtList(void)
{
	//判断条件节点是否存在
	if (m_pcdtNode == NULL)
	{
		return false;
	}

	//生成新的条件list节点
	ConditionList* pNewListNode = NULL;
	pNewListNode = new ConditionList;
	if (pNewListNode == NULL)
	{
		assert(false);
		return false;
	}

	pNewListNode->pNode = m_pcdtNode;
	//将条件list节点中的条件节点指针指向生成的条件节点
	if (m_pcdtList == NULL)
	{
		m_pcdtList = pNewListNode;
	}
	else
	{//按照条件节点的优先级插入条件list，最终生成的条件list是按
		//条件节点优先级降序的List.
		ConditionList* pCur = NULL;
		ConditionList* pParent = NULL;
		pCur = m_pcdtList;
		if (pNewListNode->pNode->PRI > pCur->pNode->PRI)
		{
			pNewListNode->pNext = pCur;
			m_pcdtList = pNewListNode;
		}
		else
		{
			while (pCur != NULL && pNewListNode->pNode->PRI <= pCur->pNode->PRI)
			{
				pParent = pCur;
				pCur = pCur->pNext;
			}
			if(pCur == NULL)
			{
				pParent->pNext = pNewListNode;
			}
			else
			{
				pParent->pNext = pNewListNode;
				pNewListNode->pNext = pCur;
			}

		}
	}
	return true;

}

bool AIScript::InsertToNodeList(Atom atom, int flag)
{
	TreeNode	  treeNode;
	TreeNodeList* ptreeNodeList = NULL;

	ptreeNodeList = new TreeNodeList;
	if (ptreeNodeList == NULL)
	{
		assert(false);
		return false;
	}
	switch(flag) 
	{
	case OPERATOR:
		{
			if ('&' == atom.szCHAR[0]) 
			{
				treeNode.op = OPTAND;
			}
			else if ('|' == atom.szCHAR[0])  	
			{
				treeNode.op = OPTOR;
			}

			treeNode.PRI = atom.PRI;
			treeNode.pos = atom.pos;
			ptreeNodeList->Node = treeNode;

			if (m_poptorNodeList == NULL)
			{
				m_poptorNodeList = ptreeNodeList;
			}
			else
			{//对'&','|'按各自的优先级排序（升序）
				TreeNodeList* pParent;
				TreeNodeList* pCur;
				pCur = m_poptorNodeList;

				if (ptreeNodeList->Node.PRI < pCur->Node.PRI)
				{//新插入的节点的优先级比第一个节点的小时，应替换首节点
					ptreeNodeList->pNext = pCur;
					m_poptorNodeList = ptreeNodeList;
					pCur = ptreeNodeList;
				}
				else
				{//找到适合的位置,然后进行插入
					while (pCur != NULL && ptreeNodeList->Node.PRI >= pCur->Node.PRI)
					{
						pParent = pCur;
						pCur = pCur->pNext;
					}
					if(pCur == NULL)
					{
						pParent->pNext = ptreeNodeList;
					}
					else
					{
						pParent->pNext = ptreeNodeList;
						ptreeNodeList->pNext = pCur;
					}

				}
			}
		}
		break;
	case CDTEXPRESSION:
		{
			treeNode = ParseExpress(atom);
			ptreeNodeList->Node = treeNode;
			if (m_pcdtNodeList == NULL)
			{
				m_pcdtNodeList = ptreeNodeList;
			}
			else
			{
				TreeNodeList* pParent;
				TreeNodeList* pCur;
				pCur = m_pcdtNodeList;
				while (pCur != NULL)
				{
					pParent = pCur;
					pCur = pCur->pNext;
				}
				pParent->pNext = ptreeNodeList;

			}
		}
		break;
	case TODOEXPRESSION:
		{
			treeNode = ParseExpress(atom);
			ptreeNodeList->Node = treeNode;
			if (m_ptodoNodeList == NULL)
			{
				m_ptodoNodeList = ptreeNodeList;
			}
			else
			{
				TreeNodeList* pParent;
				TreeNodeList* pCur;
				pCur = m_ptodoNodeList;
				while (pCur != NULL)
				{
					pParent = pCur;
					pCur = pCur->pNext;
				}
				pParent->pNext = ptreeNodeList;


			}
		}
		break;
	default:
		break;
	}
	return true;
}

TreeNode AIScript::ParseExpress(Atom atom)
{
	TreeNode treeNode;
	char		szCmd[32];
	int			prev = 0;
	int len = (int)strlen(atom.szCHAR);
	memset(szCmd,0, sizeof(szCmd));

	for (int i = 0; i < len; i++)
	{
		switch(ParseCHAR(&atom.szCHAR[i])) 
		{
		case ANDOROP:
			{
				if (atom.szCHAR[i] == '(')
				{
					if (strcmp(szCmd, "") != 0)
					{//是命令,如MP<5 or 5>MP
						PLAISFunc FuncPtr = GetFuncPtrbyName(szCmd);
						if (FuncPtr)
						{
							treeNode.FuncPtr = FuncPtr;
						}
						else
						{
							printf("szCmd = %s un support\n", szCmd);
							//assert(false);
						}

						memset(szCmd,0, sizeof(szCmd));
						m_index = 0;
					}
				}
				else if (atom.szCHAR[i] == ')') 
				{
					SetParam(szCmd, atom);
					memset(szCmd,0, sizeof(szCmd));
					memcpy(treeNode.param, atom.param, sizeof(atom.param));
					m_index = 0;
				}
			}
			break;
		case RELATIONOP:
			{
				if (RELATIONOP == ParseCHAR(&atom.szCHAR[i+1])) 
				{
					if ('<' == atom.szCHAR[i] && '=' == atom.szCHAR[i+1]) 
					{ 
						treeNode.op = OPTLESSEQUAL;
					}
					else if ('>' == atom.szCHAR[i] && '=' == atom.szCHAR[i+1])  	
					{
						treeNode.op = OPTLARGEEQUAL;
					}
					else if ('!' == atom.szCHAR[i] && '=' == atom.szCHAR[i+1])
					{
						treeNode.op = OPTUNEQUAL;
					}
					++i;
				}
				else
				{
					if ('=' == atom.szCHAR[i]) 
					{
						treeNode.op = OPTEQUAL;
					}
					else if ('>' == atom.szCHAR[i])
					{
						treeNode.op = OPTLARGETHAN;
					}
					else if ('<' == atom.szCHAR[i])
					{
						treeNode.op = OPTLESSTHAN;
					}

				}
				treeNode.pos = atom.pos;
			}
			break;
		case OTHEROP:
			{
				memcpy(&szCmd[m_index++], &atom.szCHAR[i], 1);
				if (i == len-1)//这时的szCmd必然是右边的value值,如MP<HP
				{
					if (strcmp(szCmd,"") != 0)
					{
						int ret = GetMacrobyName(szCmd);
						if (-1 != ret) 
						{
							treeNode.value = ret;
						}
						else
						{
							int len = (int)strlen(szCmd);
							for (int j = 0; j < len; ++j)
							{
								 if (!isdigit(szCmd[j]))
								 {
									 assert(false);
								 }
							}
							treeNode.value = atoi(szCmd);
						}

						memset(szCmd,0, sizeof(szCmd));
						m_index = 0;
					}
				}

			}
			break;
		default:
			assert(false);
			break;
		}
	}
	return treeNode;
}

void AIScript::ClearQ(void)
{
	m_operatorQ.clear();
	m_cdtExpQ.clear();
	m_todoExpQ.clear();
}

void AIScript::ClearList(void)
{
	TreeNodeList* pTmp = NULL;
	while(m_poptorNodeList)
	{
		pTmp = m_poptorNodeList->pNext;
		delete(m_poptorNodeList);
		m_poptorNodeList = pTmp;
	}

	pTmp = NULL;
	while(m_pcdtNodeList)
	{
		pTmp = m_pcdtNodeList->pNext;
		delete(m_pcdtNodeList);
		m_pcdtNodeList = pTmp;
	}

	pTmp = NULL;
	while(m_ptodoNodeList)
	{
		pTmp = m_ptodoNodeList->pNext;
		delete(m_ptodoNodeList);
		m_ptodoNodeList = pTmp;
	}
	m_pcdtList;
}

void AIScript::ClearTree(ConditionTree* p)
{
	if(p==NULL)
	{
		return ;
	}

	ClearTree(p->pLeft);
	ClearTree(p->pRight);
	delete(p);
}

void AIScript::ClearNode(ConditionNode* p)
{
	if (p)
	{
		ClearTree(p->pRootCondition);
		TreeNodeList* pToDo = NULL;
		TreeNodeList* pTmp  = NULL;
		pToDo = p->pToDo;
		while (pToDo)
		{
			pTmp = pToDo->pNext;
			delete(pToDo);
			pToDo = pTmp;
		}
		delete(p);
	}
}

void AIScript::ClearCdtList(void)
{
	ConditionList* pTmp = NULL; 
	/*	
	while(m_pcdtList2)
	{
	pTmp = m_pcdtList2->pNext;
	//此处已经将实际的Node(包括TreeNode,ToDoNode...)节点delete,故下面的各个状态链表只要负责
	//delete本身的链表节点就可以了.
	ClearNode(m_pcdtList2->pNode);
	delete(m_pcdtList2);
	m_pcdtList2 = pTmp;
	}
	*/
	//////////////////////////////////////////////////////////////////////////
	for (int i = 0; ONDEADSECTION+1 > i; ++i)
	{
		while(m_vStateLists[i])
		{
			pTmp = m_vStateLists[i]->pNext;
			ClearNode(m_vStateLists[i]->pNode);
			delete(m_vStateLists[i]);
			m_vStateLists[i] = pTmp;
		}
	}

}

bool AIScript::VerifyExpress(const char* szch)
{

	return true;
}

void AIScript::ReSetFlags(void)
{
	ConditionList* pCur = NULL;
	pCur = m_pcdtList;
	while (pCur)
	{
		pCur->pNode->ReSetDownFlag(pCur->pNode->id);
		pCur = pCur->pNext;
	}

}

void AIScript::ResetStateList(sol::table pAI)
{
#define MAX_RETRY_COUNT (64)
	
	int id = 0;
	int retryCount = 0;
	for (int i = 0; ONDEADSECTION+1 > i; ++i)
	{
		if(NULL == m_vStateLists[i])
		{
			continue;
		}
		ConditionList* pCur = m_vStateLists[i];
		while(pCur)
		{
			if (retryCount++ > MAX_RETRY_COUNT)
				break;
			pCur->pNode->ResetTimes();
			/////////////////////////////////////////////////////
			// 重置AI_Monster中的Script的次数Times
			id = pCur->pNode->id;
			SetAIScriptTimes(pAI, id, pCur->pNode->times2);
			////////////////////////////////////////////////////
			pCur->pNode->ReSetAllDownFlags();
			pCur = pCur->pNext;

		};
	}
}

void AIScript::InitAllStateList(void)
{
	ConditionList* pCur = m_pcdtList;
	//m_pcdtList2 = m_pcdtList;
	while(pCur)
	{
		int ret = 0;
		VerdictState(pCur->pNode->pRootCondition, pCur->pNode, ret);
		if(!ret)
		{// 没有加入任何状态List中，向所有的List添加该条件语句
			for (int i = 0; SRETURN > i; ++i)
			{
				ConditionList* p = new ConditionList;
				if (NULL == p) break;

				p->pNode = pCur->pNode;
				if (NULL == m_vStateLists[i])
				{
					m_vStateLists[i] = p;
				}
				else
				{
					ConditionList* ptmp = m_vStateLists[i];
					while (ptmp->pNext)
					{
						ptmp = ptmp->pNext;
					}
					ptmp->pNext = p;
				}
			}
		}
		pCur = pCur->pNext;
	}

	ConditionList* pTmp = NULL; 
	while(m_pcdtList)
	{
		pTmp = m_pcdtList->pNext;
		delete(m_pcdtList);
		m_pcdtList = pTmp;
	}
	m_pcdtList = NULL;
}

void AIScript::VerdictState(ConditionTree* t, ConditionNode* p, int& ret)
{
	assert(p!=NULL);

	if (t == NULL)
	{
		return ;
	}

	VerdictState(t->pLeft, p, ret);
	//Verdict and process...
	const char* FuncName = GetFuncNamebyPtr(t->Node.FuncPtr);
	
	if(FuncName && strcmp(FuncName, "AIS_GetAIState") == 0)
	{
		int nState;
		ConditionList* pRet = NULL;
		ConditionList* pp = NULL;

		pp = new ConditionList;
		if(NULL == pp) 
		{
			return ;
		}

		pp->pNode = p;
		nState = t->Node.value;
		if (m_vStateLists[nState] == NULL)
		{
			m_vStateLists[nState] = pp;
		}
		else
		{
			ConditionList* pCur = m_vStateLists[nState];
			while (pCur->pNext)
			{
				pCur = pCur->pNext;
			}
			pCur->pNext = pp;
		}
		ret = 1;//标记已经加入过了
	}

	VerdictState(t->pRight, p, ret);


}

void AIScript::SetParam(const char* szCmd, Atom& atom)
{
	int i = 0;
	int pos1 = 0, pos2 = 0; 
	std::string sParam(szCmd);
	pos2 = (int)sParam.find(',', pos1);

	if (pos2 < 0)
	{
		if (strcmp(szCmd, "") == 0)
		{
			atom.param[0] = -1;
			return ;
		}
	}

	while (i < sizeof(atom.param)/sizeof(int))
	{
		atom.param[i] = atoi(sParam.substr(pos1, pos2).c_str());
		pos1 = pos2 + 1;
		pos2 = (int)sParam.find(',', pos1);
		++i;
		if (pos2 < 0)
		{// 最后一个参数
			atom.param[i] = atoi(sParam.substr(pos1).c_str());
			return ;
		}
	}

	{
		atom.param[0] = atoi(szCmd);
	}


}

bool AIScript::IsParam(const char* szCmd)
{
	int len = (int)strlen(szCmd);
	
	for (int i = 0; i < len; ++i)
	{
		if (!isdigit(szCmd[i]))
		{
			if (szCmd[i] == '-')
			{
				return true;
			}
			else if (szCmd[i] == ',')  
			{
				return true;
			}
			else
			{
				return false;
			}

		}
	}

	return true;

}

void AIScript::ProcessCtdOrToDoQ(const char* szCmd, bool bToDoFlag)
{
	if (!bToDoFlag)
	{
		if (m_cdtExpQ.size() > 0 && m_cdtExpQ[m_cdtExpQ.size()-1].szCHAR)
		{
			strcat(m_cdtExpQ[m_cdtExpQ.size()-1].szCHAR, szCmd);
		}
	}
	else
	{
		if (m_cdtExpQ.size() > 0 && m_cdtExpQ[m_cdtExpQ.size()-1].szCHAR)
		{
			strcat(m_todoExpQ[m_todoExpQ.size()-1].szCHAR, szCmd);
		}
	}
}

bool AIScript::FindParam(const char* szCmd, int index, char* pString)
{
	for (int i = index-1; i >= 0; --i)
	{
		if (szCmd[i] == '(')
		{
			char szParam[32];
			memset(szParam, 0, sizeof(szParam));
			assert(index-i-1<=32);
			memcpy(szParam, &szCmd[i+1], index-i-1);
			if (IsParam(szParam))
			{
				pString = szParam;
				return true;
			}
			else
			{
				return false;
			}
		}
	}

	return false;

}
