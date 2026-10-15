#pragma once
#include "Obj_Item.h"
#include "GameStruct_Item.h"
#include "../../Network/CysPetSoul.h"
#include "../../DBC/GMDataBase.h"
#include "PgStructs.h"
#include <cmath>
// Class7 is a distinct CY object. Never alias its wire block as human equipment.
class CysItemPetSoul:public CObject_Item {
 std::string name,desc,icon,body;int need,price,quality;
public:
 CysItemPetSoul(UINT id,DBC::DBCFile* t,int r):CObject_Item(id){
  name=t->Search_Posistion(r,1)->pString;desc=t->Search_Posistion(r,2)->pString;icon=t->Search_Posistion(r,3)->pString;
  need=t->Search_Posistion(r,4)->iValue;price=t->Search_Posistion(r,7)->iValue;quality=t->Search_Posistion(r,6)->iValue;
  m_nParticularID=t->Search_Posistion(r,0)->iValue;SetNumber(1);
 }
 ITEM_CLASS GetItemClass()const override{return (ITEM_CLASS)7;}
 LPCTSTR GetName()const override{return name.c_str();}
 LPCTSTR GetDesc()const override{return desc.c_str();}
 LPCTSTR GetIconName()const override{return icon.c_str();}
 LPCTSTR GetExtraDesc()override{return desc.c_str();}
 INT GetMaxOverLay()const override{return 1;}
 INT GetNeedLevel()override{return need;}
 INT GetItemPrice()override{return price;}
 INT GetItemTableQuality()override{return quality;}
 INT GetItemTableType()override{return 0;}
 LPCTSTR GetItemTableTypeDesc()override{return u8"Thú hồn";}
 void SetExtraInfo(const _ITEM* p)override{CObject_Item::SetExtraInfo(p);SetNumber(1);}
 // Soul life is carried by the soul view/EquipInfo. The bag durability bytes are
 // unrelated; do not display them as life or as ordinary equipment durability.
 INT GetItemDur()override{return -1;}
 INT GetItemMaxDur()override{return -1;}
 LPCTSTR GetBaseWhiteAttrInfo()override{
  auto p=CysPetSoul::Details(this);body.clear();if(!p)return body.c_str();char buf[200];
  _snprintf(buf,sizeof(buf),u8"Cấp Thú hồn: %u / 100#rHuyết mạch: %u / 6#rKinh nghiệm huyết mạch: %u",p->level,p->pet_soul_level+1,p->pet_soul_exp);body=buf;
  static DBC::DBCFile* ext=nullptr;static bool tried=false;
  if(!tried){tried=true;ext=new DBC::DBCFile(0);if(!CDataBase::Util_OpenDBCFromTxt("PetSoulExtension.txt",ext)||ext->GetFieldsNum()<17){delete ext;ext=nullptr;}}
  if(ext)for(auto& attr:p->pet_soul_attr){
   if(attr.type<0||attr.type>=ext->GetRecordsNum())continue;
   auto cell=ext->Search_Posistion(attr.type,16);if(!cell||!cell->pString)continue;
   char value[40];if(attr.type>=15&&attr.type<=22)_snprintf(value,sizeof(value),"%.1f",std::floor(attr.value/10.0)/10.0);else _snprintf(value,sizeof(value),"%u",attr.value);
   std::string line=cell->pString;size_t pos=line.find("%s");if(pos!=std::string::npos)line.replace(pos,2,value);
   while((pos=line.find("%%"))!=std::string::npos)line.replace(pos,2,"%");
   static const char* colors[]={"#W","#G","#B","#cCC33CC","#cFF9900","#Y"};int band=0;
   for(int i=5;i>=0;--i){auto minimum=ext->Search_Posistion(attr.type,2+i*2);if(minimum&&attr.value>=minimum->iValue){band=i;break;}}
   body+="#r";body+=colors[band];body+=line;
  }
  return body.c_str();
 }
};
