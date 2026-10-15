/*************************************************************************
 文件名	: 	AIScript.h
 版本号 :	0.0.2
 功  能	:	针对特有的扩展AI脚本编写的解析及执行类
 修改记录:	修改了前版接口函数扩展性不强的缺点
 *************************************************************************/

#ifndef __SCRIPT_H__
#define __SCRIPT_H__

#include "AIScriptDef.h"
#include "AIScriptFunction.h"
#include "Ini.h"
class MonsterAI;
class AI_Character;
class AIScriptParser;
class AIScriptExecutor;

class AIScript
{
public:

	AIScript();
	~AIScript();

	/** Desc	: 解析Pet脚步文件
	 *  @param	: filename 脚本文件名
	 *  @return	: 解析结果
	 */
	bool			ParseScriptForPet(const char* filename);
	/** Desc	: 解析由文件读取的脚本内容
	 *  @param	: filename 脚本文件名
	 *  @return	: 解析结果
	 */
	bool			ParseScript(const char* filename);
	/** Desc	: 处理脚本，即执行脚本
	 *  @param	: nState 执行哪个Section的脚本,如：ATTACK,APPROACH...
	 *  @return	: 处理结果
	 */
	bool			ProcessScript(int nState, sol::table pAI);
	/** Desc	: 设置自身的AI_Character数据
	 *  @param	: pAI 将要挂接的AI_Character对象指针
	 *  @return	: 空
	 */
	//void			SetAI( sol::table& pAI) { /*m_pAI = pAI;*/ }
	/** Desc	: 重置位m_vStateLists,即所有脚本数据复位
	 *  @param	: 空
	 *  @return	: 空
	 */
	void			ResetStateList(const  sol::table pAI);

	/// 技能错误码相关
	//void			SetSkillErrorCode(ORESULT oResult) { m_SkillErrorCode = oResult; }
	//ORESULT			GetSkillErrorCode(void) const { return m_SkillErrorCode; }

	/////////////////////////////////////////
	//void			SetSkillID(int idSkill) { m_SkillID = idSkill; }
	//int				GetSkillID(void) const { return m_SkillID; }

protected:
	/// 脚本执行函数
	bool			ExcuteCdtScript(ConditionTree* p, sol::table pAI);
	bool			ExcuteToDoScript(TreeNodeList* p, sol::table pAI);
	bool			ExcuteExpress(const TreeNode* p, sol::table pAI);
	bool			ExcuteToDoExpress(const TreeNode* p, sol::table pAI);
	/// 脚本解析函数
	bool			ParseOneScript(const char* szScript);
	int				ParseCHAR(const char* szch);
	int				ParseCommand(const char* szch);
	TreeNode		ParseExpress(Atom atom);
	bool			VerifyExpress(const char* szch);
	/// 由脚本到预处理的脚步数据结构的中间函数
	bool			ProcessOptorQ(void);
	bool			ProcessCdtQ(void);
	bool			ProcessToDoQ(void);
	bool			CreateCdtTree(void);
	bool			CreateCdtNode(void);
	bool			InsertCdtNodeToCdtList(void);
	bool			InsertToNodeList(Atom atom,int flag);
	
	void			ClearQ(void);
	void			ClearList(void);
	void			ClearTree(ConditionTree* p);
	void			ClearNode(ConditionNode* p);
	void			ClearCdtList(void);
	/// 操作条件List的相关函数
	ConditionList*	GetCdtList(void) const { return m_pcdtList; }
	void			InitAllStateList(void);
	void			InitList(ENUM_AISTATE stateIndex) { m_vStateLists[stateIndex] = m_pcdtList; m_pcdtList = NULL; }
	/// 其他的辅助成员函数
	void			VerdictState(ConditionTree* t, ConditionNode* p, int& ret);
	void			SetParam(const char* szCmd, Atom& atom);
	bool			IsParam(const char* szCmd);
	void			ProcessCtdOrToDoQ(const char* szCmd, bool bToDoFlag);
	bool			FindParam(const char* szCmd, int index, char* pString);
	void			ReSetTimes(void);
	void			ReSetFlags(void);


private:

	Ini					m_file;
	ConditionList*		m_pcdtList;		//为中间变量，为各种操作提供方便
	ConditionList*		m_pcdtList2;	//真正的Common部分List的存储指针
	ConditionList*		m_vStateLists[ONDEADSECTION+1];

	OperatorQueue		m_operatorQ;
	CdtExpressionQueue	m_cdtExpQ;
	ToDoExpressionQueue m_todoExpQ;

	TreeNodeList*		m_poptorNodeList;
	TreeNodeList*		m_pcdtNodeList;
	TreeNodeList*		m_ptodoNodeList;

	ConditionTree*		m_pcdtTree;
	ConditionNode*		m_pcdtNode;
	BracketArray		m_array;
	Stack				m_stack;
	int					m_nID;
	int					m_nPrev;
	int					m_fX;
	int					m_fZ;
	int 				m_index;
	//int					m_SkillID;
	//int					m_nSummonCount;
	//int					m_nSpeakID;
	//FLOAT					m_fNeedGoDist;
	// 技能错误码
	//ORESULT				m_SkillErrorCode;

};

#endif