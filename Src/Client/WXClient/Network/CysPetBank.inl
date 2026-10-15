// Included inside CysPetNet's namespace after its packet helpers.
// Contract: CY PetBankMain/PetBankList Lua; server pet.lua packets 228/757/1706.
pg::GCPetBankListUPData g_bank;
bool g_bankOpening=false,g_bankReady=false,g_bankSizes=false,g_bankBusy=false;
int g_bankBagSize=0,g_bankSize=0,g_bankSelected=-1;
DWORD g_bankSent=0;
const pg::GCDetailAttrib_Pet* BankPet(int index){
    return index>=0&&index<10&&g_bank.pet_list[index].present?&g_bank.pet_list[index].anon1:nullptr;
}
int BankArg(LuaPlus::LuaState* s,int n=2){LuaPlus::LuaStack a(s);return a[n].IsNumber()?a[n].GetInteger():-1;}
void BankEvent(const char* name,std::initializer_list<std::string> args={}){
    if(auto e=CEventSystem::GetMe())e->PushEventByName(name,args);
}
void BankOpenReady(){
    if(!g_bankOpening||!g_bankReady||!g_bankSizes)return;
    g_bankOpening=false;
    BankEvent("TOGLE_PETBANK",{"0",std::to_string(g_bankBagSize),std::to_string(g_bankSize),"1"});
}
int BankCount(LuaPlus::LuaState* s){int n=0;for(int i=0;i<10;++i)if(BankPet(i))++n;s->PushInteger(n);return 1;}
int BankPresent(LuaPlus::LuaState* s){s->PushInteger(BankPet(BankArg(s))?1:0);return 1;}
int BankFirst(LuaPlus::LuaState* s){int n=-1;for(int i=0;i<10;++i)if(BankPet(i)){n=i;break;}s->PushInteger(n);return 1;}
int BagFirst(LuaPlus::LuaState* s){int n=-1;for(int i=0;i<HUMAN_PET_MAX_COUNT;++i)if(PetAt(i)){n=i;break;}s->PushInteger(n);return 1;}
int BankNpc(LuaPlus::LuaState* s){auto pool=CDataPool::GetMe();s->PushInteger(pool?pool->UserBank_GetNpcId():-1);return 1;}
int BankList(LuaPlus::LuaState* s){
    auto p=BankPet(BankArg(s));int level=0;
    if(p){auto db=CDataBaseSystem::GetMe()->GetDataBase(DBC_PET_EX_ATT);auto row=db?reinterpret_cast<const _DBC_PET_EX_ATT*>(db->Search_Index_EQU(p->data_index)):nullptr;level=row?row->m_TakeLevel:0;}
    s->PushString(p?p->name.c_str():"");s->PushInteger(level);s->PushInteger(p?p->level:0);s->PushString(p?"on_packa":"");return 4;
}
int BankAI(LuaPlus::LuaState* s){auto p=BankPet(BankArg(s));s->PushInteger(p?p->ai_type:-1);return 1;}
int BankGuid(LuaPlus::LuaState* s){auto p=BankPet(BankArg(s));s->PushNumber(p?p->guid.m_uHighSection:0);s->PushNumber(p?p->guid.m_uLowSection:0);return 2;}
int BankIndex(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);int found=-1;
    if(a[2].IsNumber()&&a[3].IsNumber())for(int i=0;i<10;++i){auto p=BankPet(i);if(p&&p->guid.m_uHighSection==a[2].GetNumber()&&p->guid.m_uLowSection==a[3].GetNumber()){found=i;break;}}
    s->PushInteger(found);return 1;
}
int BankSelected(LuaPlus::LuaState* s){s->PushInteger(g_bankSelected);return 1;}
int BankSelect(LuaPlus::LuaState* s){int index=BankArg(s),kind=BankArg(s,3);
    if(kind==0){g_bankSelected=BankPet(index)?index:-1;BankEvent("TOGLE_PETLIST_SELECT_CHNAGE",{std::to_string(g_bankSelected),"0"});}
    // Selecting a bag row updates the bank selection only. TOGLE_PET_PAGE is
    // also the main pet-window hotkey; broadcasting it opened that window when
    // a hidden CY pet-list receiver refreshed after withdrawing a shop pet.
    else if(kind==1)BankEvent("CYS_PETBANK_BAG_SELECT",{std::to_string(g_bankSelected)});
    return 0;
}
int BankModel(LuaPlus::LuaState* s){auto p=BankPet(BankArg(s));auto fake=CFakeObjSystem::GetMe();if(!fake)return 0;
    auto obj=fake->FindFakeObject("My_PetBank");
    if(!obj&&p)obj=fake->NewFakeObject("CObject_PlayerNPC","My_PetBank","Camera_Main");
    if(obj){auto npc=static_cast<CObject_PlayerNPC*>(obj);npc->GetCharacterData()->Set_RaceID(p?p->data_index:-1);npc->SetFaceDir(0.f);}return 0;
}
int BankInspect(LuaPlus::LuaState* s){auto p=BankPet(BankArg(s));if(!p)return 0;
    auto pool=CDataPool::GetMe();auto target=pool?pool->TargetPet_GetPet():nullptr;if(!target)return 0;
    target->CleanUp();SetGuid(target->m_GUID,p->guid);int64_t f[11]={};bool rage=false,maxRage=false,elf=false;
    pg::deriveDetailAttribPetFlags(p->nf.data(),f,&rage,&maxRage,&elf);
    FillPet(*target,-1,*p,f);CEventSystem::GetMe()->PushEvent(GE_VIEW_EXCHANGE_PET);return 0;
}
int BankInspectBag(LuaPlus::LuaState* s){int index=BankArg(s);if(PetAt(index))CEventSystem::GetMe()->PushEvent(GE_UPDATE_TARGETPET_PAGE,index);return 0;}

// Target views use the same CY wire fields as bag pets. Keep them keyed by GUID,
// including CopyMyPet, so changing the inspected pet cannot reuse another's data.
const PetCy* TargetCy(){
    auto pool=CDataPool::GetMe();auto pet=pool?pool->TargetPet_GetPet():nullptr;
    return pet&&pet->m_nIsPresent!=-1&&pet->m_GUID.m_uHighSection==g_targetCy.high&&pet->m_GUID.m_uLowSection==g_targetCy.low?&g_targetCy:nullptr;
}
template<int PetCy::*field> int TargetCell(LuaPlus::LuaState* s){auto c=TargetCy();s->PushInteger(c?c->*field:-1);return 1;}
// CY B 0x1402ea02d: generations 100..110 display spiritual level 0..10.
int TargetLingxing(LuaPlus::LuaState* s){auto c=TargetCy();int raw=c?c->lingxing:-1;s->PushInteger(raw>=100&&raw<=110?raw-100:0);return 1;}
const _DBC_PET_EX_ATT* TargetRow(){
    auto pool=CDataPool::GetMe();auto p=pool?pool->TargetPet_GetPet():nullptr;
    auto db=CDataBaseSystem::GetMe()->GetDataBase(DBC_PET_EX_ATT);
    return p&&p->m_nIsPresent!=-1&&db?reinterpret_cast<const _DBC_PET_EX_ATT*>(db->Search_Index_EQU(p->m_nDataID)):nullptr;
}
int TargetTakeLevel(LuaPlus::LuaState* s){auto p=TargetRow();s->PushInteger(p?p->m_TakeLevel:0);return 1;}
int TargetFood(LuaPlus::LuaState* s){auto p=TargetRow();s->PushInteger(p?p->m_FoodType:0);return 1;}
int TargetGrowLevel(LuaPlus::LuaState* s){auto p=TargetRow();auto cy=TargetCy();int g=cy?cy->growPerMille:-1;
    s->PushInteger(!p||g<0?-1:g<=p->m_GrowRate0?0:g<=p->m_GrowRate1?1:g<=p->m_GrowRate2?2:g>p->m_GrowRate3?4:3);return 1;
}
int TargetCopy(LuaPlus::LuaState* s){
    const int index=BankArg(s);auto pet=PetAt(index);if(!pet)return 0;
    auto cy=CyAt(index);ResetCyData(g_targetCy);if(cy)g_targetCy=*cy;
    CDataPool::GetMe()->Pet_CopyToTarget(pet);return 0;
}
void RegisterTargetHosts(LuaPlus::LuaState* s){
    ResetCyData(g_targetCy);
    auto t=s->GetGlobals().GetByName("TargetPet");if(t.IsUserData())t=t.GetMetaTable().GetByName("__index");if(!t.IsTable())return;
    t.Register("CopyMyPet",TargetCopy);
    t.Register("GetLixing",TargetLingxing);
    t.Register("GetGeneration",TargetCell<&PetCy::lingxing>);
    t.Register("GetSavvy",TargetCell<&PetCy::wuxing>);
    t.Register("GetCriticalAttack",TargetCell<&PetCy::mindAttack>);
    t.Register("GetCriticalDefence",TargetCell<&PetCy::mindDefend>);
    t.Register("GetGrowRate",TargetCell<&PetCy::growPerMille>);
    t.Register("GetPetType",TargetCell<&PetCy::petType>);
    t.Register("GetLastProcreateLevel",TargetCell<&PetCy::usedProcreate>);
    t.Register("GetTakeLevel",TargetTakeLevel);t.Register("GetFoodType",TargetFood);t.Register("GetPetGrowLevel",TargetGrowLevel);
}
int BankSave(LuaPlus::LuaState* s){
    const int index=BankArg(s),kind=BankArg(s,3),dest=BankArg(s,4);
    if(kind<0||kind>2||!CysModernGame::IsInWorld()||(g_bankBusy&&GetTickCount()-g_bankSent<5000))return 0;
    std::unique_ptr<pg::CGPetBankAddPet> out(new pg::CGPetBankAddPet);out->type=static_cast<uint8_t>(kind);
    if(kind==0){auto p=BankPet(index);if(!p)return 0;out->pet_guid_from=p->guid;}
    else {auto p=PetAt(index);if(!p)return 0;out->pet_guid_from.m_uHighSection=p->m_GUID.m_uHighSection;out->pet_guid_from.m_uLowSection=p->m_GUID.m_uLowSection;
        if(kind==2){auto q=BankPet(dest);if(!q)return 0;out->pet_guid_to=q->guid;}}
    g_bankBusy=CysModernGame::SendModern(std::move(out));g_bankSent=GetTickCount();return 0;
}
void RegisterBankHosts(LuaPlus::LuaState* s){
    RegisterTargetHosts(s);
    g_bank=pg::GCPetBankListUPData();g_bankOpening=g_bankReady=g_bankSizes=g_bankBusy=false;g_bankSelected=-1;
    auto bank=s->GetGlobals().GetByName("Bank");if(bank.IsUserData())bank=bank.GetMetaTable().GetByName("__index");
    if(bank.IsTable())bank.Register("GetNpcId",BankNpc);
    auto p=s->GetGlobals().GetByName("Pet");if(p.IsUserData())p=p.GetMetaTable().GetByName("__index");if(!p.IsTable())return;
    p.Register("GetPet_Count_PetBank",BankCount);p.Register("IsPresent_PetBank",BankPresent);
    p.Register("GetFirstPetPosInBank_PetBank",BankFirst);p.Register("GetPetList_Appoint_PetBank",BankList);
    p.Register("GetFirstPetPosInPag",BagFirst);
    p.Register("GetAIType_PetBank",BankAI);p.Register("GetPetGUIDByIndex_PetBank",BankGuid);p.Register("GetPetIndexByGUID_PetBank",BankIndex);
    p.Register("GetCurrentSelectPet_PetBank",BankSelected);p.Register("PetBank_PetListSelectChange",BankSelect);
    p.Register("SetModel_PetBank",BankModel);p.Register("ShowTargetPet_PetBank",BankInspect);
    p.Register("ShowBagSelectPet_PetBank",BankInspectBag);p.Register("SavePetIntoBank_PetBank",BankSave);
}
bool BankDispatch(const pg::Packet& packet){
    if(packet.packetId()==pg::GCBankBegin::PACKET_ID){auto& p=static_cast<const pg::GCBankBegin&>(packet);if(p.unknow!=1)return false;
        auto npc=CObjectManager::GetMe()->FindServerObject(p.npc);CDataPool::GetMe()->UserBank_SetNpcId(npc?npc->GetID():-1);
        g_bank=pg::GCPetBankListUPData();g_bankOpening=true;g_bankReady=g_bankSizes=false;g_bankSelected=-1;
        std::unique_ptr<pg::CGPetBankAddPet> req(new pg::CGPetBankAddPet);req->type=3;CysModernGame::SendModern(std::move(req));return true;
    }
    if(packet.packetId()==pg::GCPacketStream::PACKET_ID){auto& p=static_cast<const pg::GCPacketStream&>(packet);if(p.id!=5)return false;
        if(p.args.size()!=9||p.args[0]>10||p.args[4]>10||p.args[0]<1||p.args[4]<1)return true;
        g_bankBagSize=p.args[0];g_bankSize=p.args[4];g_bankSizes=p.args[8]!=0;BankOpenReady();return true;
    }
    if(packet.packetId()==pg::GCPetBankListUPData::PACKET_ID){
        g_bank=static_cast<const pg::GCPetBankListUPData&>(packet);g_bankReady=true;g_bankBusy=false;
        if(!BankPet(g_bankSelected)){g_bankSelected=-1;for(int i=0;i<10;++i)if(BankPet(i)){g_bankSelected=i;break;}}
        BankOpenReady();BankEvent("TOGLE_PETLIST_PETNUM_CHNAGE");
        PetLog("bank snapshot flags=%u selected=%d",g_bank.flag,g_bankSelected);return true;
    }
    if(packet.packetId()==pg::GCPetBankAddPet::PACKET_ID){
        auto& p=static_cast<const pg::GCPetBankAddPet&>(packet);g_bankBusy=false;
        if(p.type==1||p.type==2){pg::GCRemovePet remove;remove.guid=p.pet_guid_from;OnRemovePet(remove);}
        PetLog("bank committed type=%u from=%u:%u",p.type,p.pet_guid_from.m_uHighSection,p.pet_guid_from.m_uLowSection);return true;
    }
    return false;
}
