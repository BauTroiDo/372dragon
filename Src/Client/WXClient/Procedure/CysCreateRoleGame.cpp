#include "StdAfx.h"
#include "GamePro_CharCreate.h"
#include "CysLoginScene.h"
#include "GamePro_CharSel.h"
#include "GamePro_Login.h"
#include "../Object/Character/Obj_PlayerOther.h"
#include "../Event/GMEventSystem.h"
#include "../WXRender/RenderSystem.h"
#include "TDUtil.h"
#include "../FakeObject/GMFakeObjSystem.h"
#include "../DataPool/GMDP_CharacterData.h"
#include "../DataPool/CysExteriorWeaponData.h"
#if defined(CYS_HAVE_NETCORE)
#include "../../NetCore/LoginClient.h"
#endif

bool CGamePro_CharCreate::HasCyCreationProfile() const
{
    const DWORD attributes = GetFileAttributesA("create_role_profile.json");
    return attributes != INVALID_FILE_ATTRIBUTES && !(attributes & FILE_ATTRIBUTE_DIRECTORY);
}

void CGamePro_CharCreate::EnsureCyAppearance()
{
    if (m_cysAppearance.Ready()) return;
    if (!HasCyCreationProfile()) TDThrow("CY creation profile is not installed.");
    std::string error;
    if (!CysCreateRoleAppearance::LoadResources(m_cysAppearance, error))
        TDThrow("%s", error.c_str());   // CYS-CRTGUARD: chuoi chay-thoi la DU LIEU, khong phai chuoi dinh dang
    TDU_Log("CYS create UI: CY appearance tables loaded");
}

bool CGamePro_CharCreate::ApplyCyAppearance(int sex, int face, int hair, int outfit, int portrait,
                                         std::string& model, std::string& image)
{
    EnsureCyAppearance();
    std::string error;
    CysCreateRoleAppearance::Recipe recipe;
    const auto portraits = m_cysAppearance.Options(CysCreateRoleAppearance::Portrait, sex);
    if (portrait < 0 || static_cast<size_t>(portrait) >= portraits.size() ||
        portraits[portrait].id < 0 || portraits[portrait].id > 255 ||
        !m_cysAppearance.ResolveIndices(sex, face, hair, outfit, recipe, error)) return false;
    if (!CreateModel() || !CysCreateRoleAppearance::Apply(m_pAvatar[sex], recipe, error))
    {
        TDU_Log("CYS create UI: preview apply failed: %s", error.c_str());
        TDThrow("%s", error.empty() ? "CY creation preview is unavailable." : error.c_str());   // CYS-CRTGUARD: nhu tren
    }
    CysLoginScene::Enter(CysLoginScene::Create);
    CysLoginScene::Show(m_pAvatar[sex], sex);
    m_cysPreview = recipe;
    m_cysPreviewValid = true;
    m_iSex = sex;
    m_iFaceModle1 = recipe.faceId;
    m_iHairModle1 = recipe.hairId;
    m_iFaceId = portraits[portrait].id;
    model = sex ? "CreateRole_Man" : "CreateRole_Woman";
    image = CyPortraitImage(portraits[portrait].image);
    TDU_Log("CYS create UI: preview sex=%d face=%d hair=%d outfit=%d portrait=%d",
        sex, recipe.faceId, recipe.hairId, recipe.outfitId, m_iFaceId);
    return true;
}

bool CGamePro_CharCreate::ShowCySectPreview(int id, int sex, std::string& model)
{
    if (id < 0 || id >= 15 || sex < 0 || sex > 1 || !m_cysPreviewValid) return false;
    EnsureCyAppearance();
    // Exact S2 creation preview block (30 primary CharModelEx rows); GL's
    // historical 2644 + sex*12 formula indexes unrelated models in DATA CY.
    const int modelId = 4950 + sex * 15 + id;
    std::string object;
    if (!m_cysAppearance.ModelObject(modelId, object)) return false;
    if (!m_cysSectAvatar)
        m_cysSectAvatar = static_cast<CObject_PlayerOther*>(CFakeObjSystem::GetMe()->NewFakeObject(
            "CObject_PlayerOther", "CreateRole_Sect", "Camera_Main"));
    CysLoginScene::Forget(m_cysSectAvatar);
    if (!m_cysSectAvatar || !m_cysSectAvatar->InitializeCreationPreview(object.c_str())) return false;
    // Every referenced CY sect skeleton contains this original standing animation.
    m_cysSectAvatar->GetRenderInterface()->Actor_EnterSkill(TRUE, "\xd5\xbe\xc1\xa2", TRUE, 0.0f);
    CysLoginScene::Show(m_cysSectAvatar, sex);
    m_cysSectId = id;
    m_cysSectSex = sex;
    model = "CreateRole_Sect";
    TDU_Log("CYS create UI: sect preview=%d sex=%d modelId=%d main-scene=1", id, sex, modelId);
    return true;
}

void CGamePro_CharCreate::HideCySectPreview()
{
    CysLoginScene::Rotate(0);
    CysLoginScene::Zoom(0);
    CysLoginScene::Forget(m_cysSectAvatar);
    m_cysSectId = m_cysSectSex = -1;
    if (m_cysPreviewValid && GetActiveProcedure() == this)
        CysLoginScene::Show(m_pAvatar[m_cysPreview.sex], m_cysPreview.sex);
}

std::string CGamePro_CharCreate::CyPortraitImage(const std::string& original)
{
    // The profile imports S2 atlas payloads unchanged under a creation-only prefix.
    std::string image = original;
    if (image.compare(0, 4, "set:") == 0) image.insert(4, "CysCR_");
    return image;
}

std::string CGamePro_CharCreate::CyPortraitById(int sex, int id)
{
    EnsureCyAppearance();
    for (const auto& option : m_cysAppearance.Options(CysCreateRoleAppearance::Portrait, sex))
        if (option.id == id) return CyPortraitImage(option.image);
    std::string image;
    if (m_cysAppearance.PortraitImage(sex, id, image)) return image;
    TDThrow("CY portrait ID is absent from the creation catalog.");
    return "";
}

bool CGamePro_CharCreate::SubmitCyCharacter()
{
    if (!m_cysPreviewValid || !s_pProcLogIn || !s_pProcLogIn->IsModernLoginActive())
    {
        s_pEventSystem->PushEvent(GE_GAMELOGIN_SHOW_SYSTEM_INFO, "Connect to the test server before creating a character.");
        return false;
    }
#if defined(CYS_HAVE_NETCORE)
    cys::net::CreateCharacterRequest request;
    request.nickname = m_szCreateRoleName;
    request.model = m_cysPreview.sex;
    request.faceStyle = m_cysPreview.faceId;
    request.hairStyle = m_cysPreview.hairId;
    request.newPlayerSet = m_cysPreview.outfitId;
    request.portraitId = static_cast<uint8_t>(m_iFaceId);
    if (m_iSex != m_cysPreview.sex || !s_pProcLogIn->SubmitModernCharacter(request))
    {
        if (!s_pProcLogIn->IsModernCreatePending())
            s_pEventSystem->PushEvent(GE_GAMELOGIN_SHOW_SYSTEM_INFO, "The name or appearance is invalid, or character creation is not ready.");
        return false;
    }
    return true;
#else
    return false;
#endif
}

void CGamePro_CharSel::PrepareCySelectionScene()
{
#if defined(CYS_HAVE_NETCORE)
    if (!UsesModernCharacters() || GetActiveProcedure() != this) return;
    CysLoginScene::Enter(CysLoginScene::Select);
    for (int i = 0; i < m_iCharacterCount; ++i)
    {
        const auto* role = GetModernRoleInfo(i);
        if (role && m_Character[i].m_pAvatar) CysLoginScene::Show(m_Character[i].m_pAvatar, role->sex, i);
    }
    SelectRoleIndex(GetCurSelectRole());
#endif
}

#if defined(CYS_HAVE_NETCORE)
bool CGamePro_CharSel::SetModernCharacterList(const pg::LCRetCharList& list)
{
    CysLoginRoleList incoming;
    if (!incoming.assign(list)) return false;
    std::vector<CysCreateRoleAppearance::Recipe> appearances;
    if (incoming.size())
    {
        s_pProcCharCreate->EnsureCyAppearance();
        std::string error;
        // CYS-REVIEW 18/09: MOT nhan vat hong du lieu ngoai hinh KHONG duoc lam hong ca danh sach.
        // Truoc day mot o khong giai duoc lam ham tra false -> GamePro_Login.cpp:443 "invalid list" ->
        // tai khoan do KHONG dang nhap duoc bang bat ky nhan vat nao, chi thay "Danh sach nhan vat khong
        // hop le". Nay o hong bi BO QUA, cac o con lai van vao duoc. `keep[i]` di kem `appearances[i]`
        // va ca hai bi loc trong MOT lenh `retainWith` (xem chu thich o CysLoginRoleList.h).
        std::vector<bool> keep;
        keep.reserve(incoming.size());
        for (size_t i = 0; i < incoming.size(); ++i)
        {
            const auto& role = *incoming.at(static_cast<int>(i));
            CysCreateRoleAppearance::Recipe recipe;
            // CYS-REVIEW 18/09: chan duong hong THU HAI cua cung mot lop loi. Anh chan dung cung phan chia
            // theo gioi tinh nhu mat/toc (CysCreatePortrait: sex 0 = 1,2,3...; sex 1 = 13,14,15...), va
            // GMGameinterface_Script_GameProduceLogin.cpp:368 goi CyPortraitById() cho TUNG o khi Lua ve
            // danh sach - ham do TDThrow neu id khong thuoc gioi tinh. Nghia la mot anh chan dung lech
            // gioi tinh van giet ca man chon nhan vat DU danh sach da qua duoc Resolve() o tren.
            // Kiem o day (khong nem) de o hong bi loc cung mot duong, va TDThrow kia tro lai dung vai
            // "khong bao gio xay ra".
            std::string portraitImage;
            const bool portraitOk = s_pProcCharCreate->m_cysAppearance.PortraitImage(
                role.sex, role.portrait_id, portraitImage);
            if (!portraitOk)
            {
                TDU_Log("CYS character list: portrait unavailable slot=%u guid=%u sex=%d portrait_id=%d"
                        " - bo qua o nay, cac nhan vat con lai van vao duoc",
                        static_cast<unsigned>(i), role.guid, role.sex, role.portrait_id);
                keep.push_back(false);
                continue;
            }
            if (!s_pProcCharCreate->m_cysAppearance.Resolve(role.sex, CysLoginRoleList::Face(role), CysLoginRoleList::Hair(role),
                    role.new_player_set, recipe, error))
            {
                // CYS-REVIEW 18/09: ghi RO vi sao va voi so lieu nao. Truoc day chi in "slot=N", con chuoi
                // `error` cua Resolve() bi vut di, nen mot ban ghi tu mau thuan chi hien "Danh sach nhan vat
                // khong hop le" va khong ai lan ra nguyen nhan (mat 3 luot GUI moi tim ra).
                // Nguyen nhan hay gap nhat: attrib.model (sex) khong khop bo mat/toc - logind.lua:492-500 gui
                // sex <- attrib.model, head <- attrib.face_style, hair <- attrib.hair_style, con Resolve()
                // doi (*face)[1] == sex va (*hair)[1] == sex (CysCreateRoleAppearance.cpp:186).
                TDU_Log("CYS character list: appearance unavailable slot=%u guid=%u sex=%d head=%d hair=%d outfit=%d: %s"
                        " - bo qua o nay, cac nhan vat con lai van vao duoc",
                        static_cast<unsigned>(i), role.guid, role.sex, CysLoginRoleList::Face(role), CysLoginRoleList::Hair(role), role.new_player_set,
                        error.empty() ? "(khong co mo ta)" : error.c_str());
                keep.push_back(false);
                continue;
            }
            keep.push_back(true);
            appearances.push_back(recipe);
        }
        // `appearances` chi chua cac o giai duoc, nen phai bo cac o hong khoi `incoming` truoc khi
        // hai vector duoc dung song song ben duoi. Chen tam cho vao cho khop kich thuoc de retainWith
        // (von tu choi kich thuoc lech) van la mot lenh duy nhat loc CA hai.
        if (appearances.size() != incoming.size())
        {
            std::vector<CysCreateRoleAppearance::Recipe> aligned;
            aligned.reserve(incoming.size());
            size_t next = 0;
            for (size_t i = 0; i < keep.size(); ++i)
                aligned.push_back(keep[i] ? appearances[next++] : CysCreateRoleAppearance::Recipe());
            if (!incoming.retainWith(keep, aligned)) return false;
            appearances.swap(aligned);
            TDU_Log("CYS character list: %u nhan vat hong ngoai hinh da bi bo qua, con %u",
                    static_cast<unsigned>(keep.size() - appearances.size()),
                    static_cast<unsigned>(appearances.size()));
        }
    }
    int selected = -1;
    // NetCore only publishes the post-create list after success440 and validates
    // its GUID set. Initial login/ordinary refresh has no pending create.
    if (!incoming.replacementSelection(m_modernRoles, GetCurSelectRole(),
            s_pProcLogIn && s_pProcLogIn->IsModernCreatePending(), selected)) return false;
    ClearUIModel();
    m_modernRoles = std::move(incoming);
    m_useModernCharacters = true;
    m_iCharacterCount = static_cast<int>(m_modernRoles.size());
    for (int i = 0; i < m_iCharacterCount; ++i)
    {
        m_Character[i].CreateNewUIModel();
        std::string error;
        const auto& role=*m_modernRoles.at(i);
        auto avatar=m_Character[i].m_pAvatar;
        auto data=avatar->GetCharacterData();
        data->Set_RaceID(role.sex);
        data->Set_ModelID(INVALID_ID);
        if (!CysCreateRoleAppearance::Apply(m_Character[i].m_pAvatar, appearances[i], error,
                static_cast<unsigned int>(m_modernRoles.at(i)->hair_color)))
            TDThrow("%s", error.c_str());   // CYS-CRTGUARD: chuoi chay-thoi la DU LIEU, khong phai chuoi dinh dang
        data->Set_FaceMesh(CysLoginRoleList::Face(role)); data->Set_HairMesh(CysLoginRoleList::Hair(role));
        data->Set_HairColor(static_cast<unsigned int>(role.hair_color));
        for(int point=0;point<HEQUIP_NUMBER;++point) {
            data->Set_Equip((HUMAN_EQUIP)point,role.equips[point]>0?role.equips[point]:INVALID_ID);
            data->Set_EquipGem((HUMAN_EQUIP)point,role.gems[point]);
        }
        // The fake-avatar weapon slot follows the same override as SelfEquip.
        const int cosmetic=CysExteriorWeaponData::Item(role.exterior_weapon_id);
        if(cosmetic>=0) data->Set_Equip(HEQUIP_WEAPON,cosmetic);
        data->Set_ExteriorWeapon(role.exterior_weapon_id);
        data->Set_DressVisual(role.equips[16]>0?role.visuals[16]:INVALID_ID);
        data->Set_Ornament(0,role.exterior_head_id,role.exterior_head_color);
        data->Set_Ornament(1,role.exterior_back_id,role.exterior_back_color);
        data->Set_WuhunAppearance(role.equips[18],role.visuals[18]);
        // v1 extension occupies the ten formerly zero bytes, tagged for old replies.
        const auto& soul=role.anon9;
        const int assaultItem=(uint16_t)soul[3]|((uint32_t)(uint16_t)soul[4]<<16);
        data->Set_AssaultAppearance(soul[0]==0x5344&&soul[1]==1?assaultItem:-1,
                                   soul[0]==0x5344&&soul[1]==1?soul[2]:0);
        if(getenv("CYS_DUAL_SOULS_LIVE"))TDU_Log("CYS-DUAL-SOULS: selection item=%d visual=%d",data->Get_AssaultItem(),data->Get_AssaultVisual());
        avatar->RefreshSelectionAppearance();
        if(getenv("CYS_WUHUN_APPEARANCE_LIVE")) {
            STRING obj;if(avatar->GetRenderInterface())avatar->GetRenderInterface()->Actor_GetObjectProperty("KFSObj",obj);
            TDU_Log("CYS-WUHUN: selection item=%d visual=%d object=%s",role.equips[18],role.visuals[18],obj.c_str());
        }
        TDU_Log("CYS-ROUND2: selection current equipment guid=%u dress=%d weapon=%d",role.guid,data->Get_DressVisual(),data->Get_WeaponAppearance());
    }
    RestoreRoleSelection(selected);
    m_bClearUIModel = FALSE;
    PrepareCySelectionScene();
    return true;
}
#endif
