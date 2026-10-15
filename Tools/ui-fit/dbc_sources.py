# -*- coding: utf-8 -*-
"""ui-fit-3: chu HIEN THI den tu bang DBC (`ConfigFolder`) chay vao widget nao.

Gioi han #3/#8 cua bo do cu (`Timeline/handoff/ui-fit-2.md` muc 5): `measure_ui_text.py` chi thay chu
trong `.layout.xml`, hang chuoi trong `.lua` va `StrDictionary`. Ten vat pham/quai, danh hieu, cam xuc...
den LUC CHAY tu bang DBC nen KHONG nam trong con so 4.269. `i18n-2` (18/09) vua dich 8 bang sang tieng
Viet - tieng Viet dai hon chu Han - nen phan lon cho tran moi sinh ra deu vo hinh voi bo do cu.

LUAT XAC DINH COT HIEN THI (i18n-2 muc 5, da tra gia nhieu lan): **grep cho truy cap field THAT trong
`Src`, KHONG suy tu ten cot**. Moi dong PROV duoi day co `evidence` = `file:dong` cua cho C++ that su
doc field do va day sang Lua/CEGUI. Khong them dong nao neu chua co con tro nhu vay.

Chuoi bang chung day du cua mot muc:
    bang DBC  --(C++ doc field)-->  ham Lua (PushString)  --(Lua .lua)-->  Widget:SetText(...)
             evidence_dbc                  evidence_api                    do tu chinh file .lua
"""

import os
import re
import struct

MAGIC = b'\x00\xcc\xbb\xdd'


# --------------------------------------------------------------------------- DBC

def read_column(path, col, encoding='utf-8'):
    """Doc mot cot STRING cua bang DBC nhi phan -> list chuoi theo thu tu dong.

    Dinh dang: Tools/pipeline/cy_item_text.py::parse (magic 00CCBBDD, nf/nr/ns, kinds, cells, pool).
    """
    raw = open(path, 'rb').read()
    if raw[:4] != MAGIC:
        raise ValueError('%s khong phai DBC nhi phan' % path)
    _, nf, nr, ns = struct.unpack_from('<Iiii', raw, 0)
    kinds = struct.unpack_from('<%dI' % nf, raw, 16)
    if col >= nf:
        raise ValueError('%s chi co %d cot, khong co cot %d' % (path, nf, col))
    if kinds[col] != 2:
        raise ValueError('%s cot %d khong phai STRING' % (path, col))
    base = 16 + 4 * nf
    cells = struct.unpack_from('<%dI' % (nf * nr), raw, base)
    pool = raw[base + 4 * nf * nr: base + 4 * nf * nr + ns]
    out = []
    for r in range(nr):
        o = cells[r * nf + col]
        if o >= len(pool):
            out.append('')
            continue
        e = pool.find(b'\0', o)
        b = pool[o:e if e >= 0 else len(pool)]
        if encoding == 'utf-8':
            out.append(b.decode('utf-8', 'replace'))
        else:
            try:
                out.append(b.decode(encoding))
            except UnicodeDecodeError:
                out.append(b.decode('gb18030', 'replace'))
    return out


# --------------------------------------------------------------------------- provenance
#
# `sel` = chi so doi so (0 = doi so dau tien SAU self) quyet dinh cot nao duoc tra ve; `when` = gia tri
# cua doi so do. `when=None` nghia la khong phu thuoc doi so. `default=True` = nhanh else cua chuoi if.
# `batch`: 2 = 8 bang `i18n-2` dich 18/09 (viec cua nhanh nay), 1 = cac bang dich tu cac dot truoc.

PROV = [
    # ---- CharTitle.txt (batch 2) -------------------------------------------------------------
    dict(recv='Player', meth='EnumAgname', sel=1, when='name', default=False,
         table='CharTitle.txt', col=2, member='szTitle', batch=2,
         evidence_api='Src/Client/WXClient/Interface/GMGameInterface_Script_PlayerMySelf.cpp:836',
         evidence_reg='Src/Client/WXClient/Script/GMScriptSystm.cpp (RegisterObjectFunctor "EnumAgname")',
         note='chi khi bFlag == ID_TITLE; danh hieu do server dat (szTitleData) khong qua bang'),
    dict(recv='Player', meth='EnumAgname', sel=1, when=None, default=True,
         table='CharTitle.txt', col=3, member='szTitleDesc', batch=2,
         evidence_api='Src/Client/WXClient/Interface/GMGameInterface_Script_PlayerMySelf.cpp:838',
         evidence_reg='Src/Client/WXClient/Script/GMScriptSystm.cpp (RegisterObjectFunctor "EnumAgname")',
         note='nhanh else cua strncmp(szFilter,"name",4)'),
    # ---- Ability.txt (batch 2) ---------------------------------------------------------------
    dict(recv='Player', meth='GetAbilityInfo', sel=1, when='name', default=False,
         table='Ability.txt', col=1, member='szName', batch=2,
         evidence_api='Src/Client/WXClient/Interface/GMGameInterface_Script_PlayerMySelf.cpp:664',
         evidence_reg='Src/Client/WXClient/Script/GMScriptSystm.cpp (RegisterObjectFunctor "GetAbilityInfo")'),
    dict(recv='Player', meth='GetAbilityInfo', sel=1, when='explain', default=False,
         table='Ability.txt', col=13, member='szExplain', batch=2,
         evidence_api='Src/Client/WXClient/Interface/GMGameInterface_Script_PlayerMySelf.cpp:684',
         evidence_reg='Src/Client/WXClient/Script/GMScriptSystm.cpp (RegisterObjectFunctor "GetAbilityInfo")'),
    # ---- ImpactSEData_V1.txt (batch 2) -------------------------------------------------------
    dict(recv='Player', meth='GetBuffToolTipsByIndex', sel=None, when=None, default=False,
         table='ImpactSEData_V1.txt', col=16, member='m_pszInfo', batch=2,
         evidence_api='Src/Client/WXClient/Interface/GMGameInterface_Script_PlayerMySelf.cpp:142',
         evidence_reg='Src/Client/WXClient/Script/GMScriptSystm.cpp:428'),
    # ---- CharFaceGeo.txt / CharHairGeo.txt (batch 2) -----------------------------------------
    dict(recv='GameProduceLogin', meth='GetFaceModelName', sel=None, when=None, default=False,
         table='CharFaceGeo.txt', col=4, member='pShowName', batch=2,
         evidence_api='Src/Client/WXClient/Interface/GMGameinterface_Script_GameProduceLogin.cpp:841'
                      ' -> Src/Client/WXClient/Procedure/FaceModelMng.cpp:234/246',
         evidence_reg='CGameProduce_Login::GetFaceModelName (GMGameinterface_Script_GameProduceLogin.cpp:819)'),
    dict(recv='GameProduceLogin', meth='GetHairModelName', sel=None, when=None, default=False,
         table='CharHairGeo.txt', col=6, member='pShowName', batch=2,
         evidence_api='Src/Client/WXClient/Interface/GMGameinterface_Script_GameProduceLogin.cpp:937'
                      ' -> Src/Client/WXClient/Procedure/HairModelMng.cpp:244/256',
         evidence_reg='CGameProduce_Login::GetHairModelName (GMGameinterface_Script_GameProduceLogin.cpp:915)'),
    # ---- ItemCompound.txt (batch 1, dot 15/09) -----------------------------------------------
    dict(recv='LifeAbility', meth='GetPrescr_Explain', sel=None, when=None, default=False,
         table='ItemCompound.txt', col=24, member='szExplain', batch=1,
         evidence_api='Src/Client/WXClient/Interface/GMGameInterface_Script_LifeAbility.cpp:350'
                      ' (SCLIENT_PRESCR::m_pDefine = _DBC_LIFEABILITY_ITEMCOMPOSE ='
                      ' ItemCompound.txt, GMDataBase.cpp:192)',
         evidence_reg='Src/Client/WXClient/Script/GMScriptSystm.cpp:1077'),
    # ---- SkillTemplate_V1.txt / XinFa_V1.txt (batch 1, dot skills-ui 15/09) ------------------
    dict(recv='Player', meth='GetSkillInfo', sel=1, when='name', default=False,
         table='SkillTemplate_V1.txt', col=2, member='m_lpszName', batch=1,
         evidence_api='Src/Client/WXClient/Interface/GMGameInterface_Script_PlayerMySelf.cpp:560',
         evidence_reg='Src/Client/WXClient/Script/GMScriptSystm.cpp (RegisterObjectFunctor "GetSkillInfo")'),
    dict(recv='Player', meth='GetSkillInfo', sel=1, when='explain', default=False,
         table='SkillTemplate_V1.txt', col=79, member='m_pszDesc', batch=1,
         evidence_api='Src/Client/WXClient/Interface/GMGameInterface_Script_PlayerMySelf.cpp:586',
         evidence_reg='Src/Client/WXClient/Script/GMScriptSystm.cpp (RegisterObjectFunctor "GetSkillInfo")'),
    dict(recv='Player', meth='GetSkillClassInfo', sel=1, when='name', default=False,
         table='XinFa_V1.txt', col=2, member='pszName', batch=1,
         evidence_api='Src/Client/WXClient/Interface/GMGameInterface_Script_PlayerMySelf.cpp:627',
         evidence_reg='Src/Client/WXClient/Script/GMScriptSystm.cpp (RegisterObjectFunctor "GetSkillClassInfo")'),
    dict(recv='Player', meth='GetSkillClassInfo', sel=1, when='explain', default=False,
         table='XinFa_V1.txt', col=3, member='pszDesc', batch=1,
         evidence_api='Src/Client/WXClient/Interface/GMGameInterface_Script_PlayerMySelf.cpp:639',
         evidence_reg='Src/Client/WXClient/Script/GMScriptSystm.cpp (RegisterObjectFunctor "GetSkillClassInfo")'),
    # ---- SceneDefineEx.txt (batch 1, dot npc-quest 15/09) ------------------------------------
    dict(recv='_G', meth='GetCurrentSceneName', sel=None, when=None, default=False,
         table='SceneDefineEx.txt', col=1, member='szName', batch=1,
         evidence_api='Src/Client/WXClient/Interface/GMGameInterface_Script.cpp:1167',
         evidence_reg='Lua_GetCurrentSceneName (ham toan cuc)'),
    dict(recv='_G', meth='GetCurrentSceneNameById', sel=None, when=None, default=False,
         table='SceneDefineEx.txt', col=1, member='szName', batch=1,
         evidence_api='Src/Client/WXClient/Interface/GMGameInterface_Script.cpp:1178',
         evidence_reg='Lua_GetCurrentSceneNameById (ham toan cuc)'),
]

# Chu DBC den widget qua SU KIEN (arg cua OnEvent), khong qua loi goi API -> khong suy dien duoc bang
# quet tinh chung; khai bao thang, kem bang chung.
EVENT_PROV = [
    dict(layout='ProgressBar/ProgressBar.layout.xml', widget='ProgressBar_Progress',
         event='PROGRESSBAR_SHOW', lua='ProgressBar/ProgressBar.lua:18',
         sources=[
             dict(table='Ability.txt', col=15, member='szProgressbarName', batch=2,
                  evidence_api='Src/Client/WXClient/Object/Character/Obj_Character_Logic.cpp:1757'),
             dict(table='SkillTemplate_V1.txt', col=2, member='m_lpszName', batch=1,
                  evidence_api='Src/Client/WXClient/Object/Character/Obj_Character_Logic.cpp:1288,1382'),
         ]),
]

# Bang/cot DA DICH ma duong ra man hinh KHONG phai widget co be rong co dinh -> khong the bi CAT.
# Ghi lai de nguoi sau khong di tim "cho tran" o day nua.
NON_CLIPPING = [
    dict(table='MonsterPaoPao.txt', col=1, member='szPaoPaoTxt', batch=2,
         path='Talk::SetMonsterPaoPaoText -> CObject_Character::Say -> CCreatureBoard::SetElement_PaoPaoText',
         evidence='Src/Client/WXClient/Interface/GMInterface_Script_Talk.cpp:2714;'
                  ' Src/Client/WXClient/Object/Character/Obj_Character.cpp:1793;'
                  ' Src/Client/CEGUISystem/UICreatureBoard.cpp:285',
         why='widget __auto_paopao__ la Falagard/PaoPao ho FalagardSelfFitWindow:'
             ' updateSelfSize() goi getFormattedSize(..., WordWrapLeftAligned) roi setSize(Absolute, sz)'
             ' -> TU GIAN + TU XUONG DONG trong MaxWidth, khong bao gio cat chu'
             ' (Src/Client/CEGUIFalagardEx/FalagardSelfFitWindow.cpp:82-103)'),
    dict(table='CharTitle.txt', col=2, member='szTitle', batch=2,
         path='TransTitleStr -> CCharacterData::Set_CurTitle -> CCreatureBoard::SetElement_Title',
         evidence='Src/Client/WXClient/DBC/GMDataBase.cpp:319;'
                  ' Src/Client/WXClient/DataPool/GMDP_CharacterData.cpp:247;'
                  ' Src/Client/CEGUISystem/UICreatureBoard.cpp:299',
         why='m_pTitleWindow cung la FalagardSelfFitWindow (UICreatureBoard.cpp:184 ep kieu'
             ' IFalagardSelfFitWindow) -> tu gian, khong cat. Chi lam bang ten RONG ra tren dau nhan vat.'),
    dict(table='ChatMood.txt', col=2, member='szNobody', batch=2,
         path='Talk::GenTalkActMap -> m_TalkActMap -> Talk::GetTalkActMsg -> khung chat',
         evidence='Src/Client/WXClient/Interface/GMInterface_Script_Talk.cpp:3187, 2645',
         why='chu chay vao lich su chat (Falagard/ChatHistory) - khung cuon + tu xuong dong'),
    dict(table='ChatMood.txt', col=3, member='szMyself', batch=2,
         path='nhu tren', evidence='Src/.../GMInterface_Script_Talk.cpp:3188', why='nhu tren'),
    dict(table='ChatMood.txt', col=4, member='szOther', batch=2,
         path='nhu tren', evidence='Src/.../GMInterface_Script_Talk.cpp:3189', why='nhu tren'),
    dict(table='ChatMood.txt', col=11, member='szToolTip', batch=2,
         path='act.m_tip -> CActionItem_ChatMood::GetName -> tooltip/ten o hanh dong',
         evidence='Src/Client/WXClient/Interface/GMInterface_Script_Talk.cpp:3198;'
                  ' Src/Client/WXClient/Action/GMActionSystem_ChatMood.cpp:43,115',
         why='tooltip CEGUI tu do be rong theo chu (Falagard/SuperTooltip + SelfFitWindow)'),
    dict(table='ImpactSEData_V1.txt', col=16, member='m_pszInfo', batch=2,
         path='Player:GetBuffToolTipsByIndex -> IMPACT_BUTTONS[i]:SetToolTip',
         evidence='Assets/CanonicalCY/Data/InterfaceFolder/PlayerImpactFrame/PlayerImpactFrame.lua:304,307',
         why='SetToolTip chu khong phai SetText -> tooltip tu do be rong; van do rieng o bang tooltip'),
    dict(table='ScenePosDefine.txt', col=5, member='szAimName', batch=2,
         path='CWorldManager::EnterScene/UpdateUserCity -> m_ScenePoslistObj'
              ' -> GetObjectListByClass(6) -> UILuaControl (WorldMap/MiniMap)',
         evidence='Src/Client/WXClient/World/WorldManager.cpp:180,223,646;'
                  ' Src/Client/CEGUISystem/UILuaControl.cpp:1613,2321',
         why='ve truc tiep len ban do (MAP_POS_DEFINE.name) chu khong qua Window co rect co dinh'),
]


# --------------------------------------------------------------------------- lua scan

def strip_comments(src):
    """Bo chu thich nhung GIU nguyen so ky tu/so dong (de offset -> dong van dung)."""
    out = list(src)
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if c in '"\'':
            q = c
            i += 1
            while i < n and src[i] != q:
                i += 2 if src[i] == '\\' else 1
            i += 1
            continue
        if c == '-' and i + 1 < n and src[i + 1] == '-':
            if src[i + 2:i + 4] == '[[':
                j = src.find(']]', i + 4)
                j = (j + 2) if j >= 0 else n
            else:
                j = src.find('\n', i)
                j = j if j >= 0 else n
            for k in range(i, j):
                if out[k] != '\n':
                    out[k] = ' '
            i = j
            continue
        i += 1
    return ''.join(out)


def _balanced(src, start):
    """Doi so cua loi goi bat dau tai '(' o vi tri start-1."""
    depth, i, n = 1, start, len(src)
    while i < n and depth and i - start < 4000:
        c = src[i]
        if c in '"\'':
            q = c
            i += 1
            while i < n and src[i] != q:
                i += 2 if src[i] == '\\' else 1
        elif c == '(':
            depth += 1
        elif c == ')':
            depth -= 1
            if depth == 0:
                return src[start:i], i
        i += 1
    return None, start


def split_args(arg):
    """Tach doi so theo dau phay o MUC NGOAI CUNG."""
    parts, depth, cur = [], 0, []
    i, n = 0, len(arg)
    while i < n:
        c = arg[i]
        if c in '"\'':
            q = c
            cur.append(c)
            i += 1
            while i < n and arg[i] != q:
                cur.append(arg[i])
                i += 2 if arg[i] == '\\' else 1
                if arg[i - 1] == '\\' and i - 1 < n:
                    cur.append(arg[i - 1])
            cur.append(q)
            i += 1
            continue
        if c in '([{':
            depth += 1
        elif c in ')]}':
            depth -= 1
        if c == ',' and depth == 0:
            parts.append(''.join(cur))
            cur = []
            i += 1
            continue
        cur.append(c)
        i += 1
    parts.append(''.join(cur))
    return [p.strip() for p in parts]


_STR_RE = re.compile(r'^\s*(?:"((?:[^"\\]|\\.)*)"|\'((?:[^\'\\]|\\.)*)\')\s*$')


def _literal(tok):
    m = _STR_RE.match(tok)
    if not m:
        return None
    return (m.group(1) if m.group(1) is not None else m.group(2))


_CALL_RE = re.compile(r'\b([A-Za-z_]\w*)\s*[:.]\s*([A-Za-z_]\w*)\s*\(')
_GLOBAL_CALL_RE = re.compile(r'(?<![\w.:])([A-Za-z_]\w*)\s*\(')
_ASSIGN_RE = re.compile(r'(?m)^[ \t]*(local[ \t]+)?([A-Za-z_]\w*(?:[ \t]*,[ \t]*[A-Za-z_]\w*)*)[ \t]*=[ \t]*(?!=)')
_FUNC_RE = re.compile(r'(?m)^[ \t]*(?:local[ \t]+)?function\b')
# Ben nhan co the la bien tro (`Frame_Text`), phan tu bang (`IMPACT_BUTTONS[i+1]`) hoac o trong bang
# (`g_MembersCtl.desc.ctl`) - bat het roi moi phan loai; chi ten tron moi doi chieu duoc voi layout.
_RECV = r'[A-Za-z_]\w*(?:\.[A-Za-z_]\w*|\[[^\]\n]*\])*'
_SETTER_RE = re.compile(r'(?<![\w.])(' + _RECV +
                        r')\s*:\s*(SetText|SetToolTip|AddTextTextAndImage|SetImageTips)\s*\(')
_IDENT_RE = re.compile(r'[A-Za-z_]\w*')


def _mask_strings(expr):
    """Thay noi dung chuoi bang khoang trang (giu do dai) de khong bat nham bien trong chuoi."""
    out = list(expr)
    i, n = 0, len(expr)
    while i < n:
        c = expr[i]
        if c in '"\'':
            q = c
            i += 1
            while i < n and expr[i] != q:
                out[i] = ' '
                i += 2 if expr[i] == '\\' else 1
            i += 1
            continue
        i += 1
    return ''.join(out)


def _vars_in(expr):
    """Ten bien trong bieu thuc: bo chuoi, bo `a.b`/`a:b` (truy cap truong), bo loi goi `f(`.

    `..` la phep NOI CHUOI cua Lua chu khong phai truy cap truong: `"  "..szExplain` -> co `szExplain`.
    Do la cho bo quet ban dau bo sot 1 widget that (LifeSkillsStudy_Explain_Desc).
    """
    masked = _mask_strings(expr)
    out = []
    for m in _IDENT_RE.finditer(masked):
        name = m.group(0)
        if name in _LUA_KW:
            continue
        before = masked[:m.start()].rstrip()
        if before.endswith('..'):
            pass
        elif before.endswith('.') or before.endswith(':'):
            continue
        if masked[m.end():].lstrip().startswith('('):
            continue
        out.append(name)
    return out

_LUA_KW = {'and', 'or', 'not', 'nil', 'true', 'false', 'if', 'then', 'else', 'elseif', 'end',
           'function', 'local', 'return', 'for', 'while', 'do', 'in', 'tostring', 'tonumber',
           'string', 'table', 'math', 'format', 'this', 'self'}


def _calls_in(expr):
    """Moi loi goi API khop PROV trong mot bieu thuc -> list ban ghi PROV (da chon nhanh selector)."""
    hits = []
    for m in _CALL_RE.finditer(expr):
        recv, meth = m.group(1), m.group(2)
        arg, _ = _balanced(expr, m.end())
        args = split_args(arg) if arg else []
        hits.extend(_match_prov(recv, meth, args))
    for m in _GLOBAL_CALL_RE.finditer(expr):
        meth = m.group(1)
        if meth in _LUA_KW:
            continue
        arg, _ = _balanced(expr, m.end())
        args = split_args(arg) if arg else []
        hits.extend(_match_prov('_G', meth, args))
    return hits


def _match_prov(recv, meth, args):
    cands = [p for p in PROV if p['recv'] == recv and p['meth'] == meth]
    if not cands:
        return []
    out, fallback = [], None
    for p in cands:
        if p['sel'] is None:
            out.append(p)
            continue
        if p.get('default'):
            fallback = p
            continue
        tok = args[p['sel']] if p['sel'] < len(args) else None
        lit = _literal(tok) if tok is not None else None
        if lit is not None and lit == p['when']:
            out.append(p)
    if not out and fallback is not None:
        # Doi so selector la chuoi KHAC "name"/"explain" -> nhanh else; neu la BIEN thi khong doan.
        chosen = [p for p in cands if p['sel'] is not None and not p.get('default')]
        sel = chosen[0]['sel'] if chosen else fallback['sel']
        tok = args[sel] if sel is not None and sel < len(args) else None
        if tok is not None and _literal(tok) is not None:
            out.append(fallback)
    return out


def scan_lua(path):
    """-> {ten widget: [ban ghi nguon]} ; moi ban ghi co them 'setter', 'literal', 'confidence'."""
    try:
        raw = open(path, 'r', encoding='utf-8', errors='replace').read()
    except Exception:
        return {}
    src = strip_comments(raw)
    starts = [0]
    for i, ch in enumerate(src):
        if ch == '\n':
            starts.append(i + 1)

    def line_of(off):
        lo, hi = 0, len(starts) - 1
        while lo < hi:
            mid = (lo + hi + 1) // 2
            if starts[mid] <= off:
                lo = mid
            else:
                hi = mid - 1
        return lo + 1

    scopes = [m.start() for m in _FUNC_RE.finditer(src)]

    def scope_of(off):
        lo, hi, res = 0, len(scopes) - 1, -1
        while lo <= hi:
            mid = (lo + hi) // 2
            if scopes[mid] <= off:
                res, lo = mid, mid + 1
            else:
                hi = mid - 1
        return res

    # 1) MOI phep gan cho bien (ke ca phep gan KHONG co nguon DBC - no GIET gia tri cu).
    #    Bo qua diem nay la bug that: `strName` trong LifeSkill.lua nhan Ability c13 o dong 288 roi bi gan
    #    lai bang `skillexp` (so nguyen) o dong 299; neu chi luu ban gan "co nguon" thi dong 300 bi quy oan
    #    cho Ability c13.
    # off, scope, var, [prov], is_local, alias_var, is_guard (ve phai la HANG - `x = ""` sau `if x == nil`)
    assigns = []
    for m in _ASSIGN_RE.finditer(src):
        names = [x.strip() for x in m.group(2).split(',')]
        rhs, _ = _read_stmt(src, m.end())
        hits = _calls_in(rhs)
        off, sc, isloc = m.start(), scope_of(m.start()), bool(m.group(1))
        av, guard = None, False
        if not hits:
            mv = re.match(r'^\s*([A-Za-z_]\w*)\s*;?\s*$', rhs)
            av = mv.group(1) if mv else None
            # `strHairModelName = ""` trong nhanh `if ... == nil then` la GIA TRI MAC DINH, khong phai
            # mot nguon khac -> khong duoc xoa nguon DBC gan truoc do.
            guard = bool(re.match(r'^\s*(?:""|\'\'|nil|-?\d+(?:\.\d+)?)\s*;?\s*$', rhs))
        assigns.append((off, sc, names[0], hits, isloc, av, guard))
        for extra in names[1:]:
            assigns.append((off, sc, extra, [], isloc, None, False))

    def resolve(var, off, sc, depth=0):
        """Lui dan tu ban gan gan nhat: co nguon -> tra ve; hang mac dinh -> bo qua; con lai -> chet."""
        if depth > 3:
            return None, None
        for scope_name, pool in (('cung-ham', [a for a in assigns if a[1] == sc]),
                                 ('toan-file', [a for a in assigns if not a[4]])):
            cands = sorted([a for a in pool if a[2] == var and a[0] < off], key=lambda a: -a[0])
            for a in cands:
                if a[3]:
                    return a[3], scope_name
                if a[6]:
                    continue                      # gia tri mac dinh, di tiep ve truoc
                if a[5]:
                    sub, _c = resolve(a[5], a[0], a[1], depth + 1)
                    if sub:
                        return sub, scope_name + '+alias'
                break                             # bi gan lai bang thu khac -> het nguon
        return None, None

    out = {}
    for m in _SETTER_RE.finditer(src):
        widget, setter = m.group(1), m.group(2)
        arg, _ = _balanced(src, m.end())
        if arg is None:
            continue
        off, sc = m.start(), scope_of(m.start())
        found = []
        for p in _calls_in(arg):
            found.append((p, 'truc-tiep'))
        if not found:
            for v in _vars_in(arg):
                hits, conf = resolve(v, off, sc)
                if hits:
                    for p in hits:
                        found.append((p, conf))
                    break
        if not found:
            continue
        # chuoi hang trong doi so (tien to/hau to noi them) - cong vao be rong
        lit = ''.join(x for x in re.findall(r'"((?:[^"\\]|\\.)*)"', arg)) \
            + ''.join(x for x in re.findall(r"'((?:[^'\\]|\\.)*)'", arg))
        for p, conf in found:
            rec = dict(p)
            rec['setter'] = setter
            rec['literal'] = lit.replace('\\"', '"').replace('\\n', '\n')
            rec['confidence'] = conf
            rec['lua_line'] = line_of(off)
            out.setdefault(widget, []).append(rec)
    return out


def _read_stmt(src, start):
    """Doc ve phai tu `start` het mot cau lenh: het dong, tru khi ngoac chua can bang."""
    depth, i, n = 0, start, len(src)
    while i < n:
        c = src[i]
        if c in '"\'':
            q = c
            i += 1
            while i < n and src[i] != q:
                i += 2 if src[i] == '\\' else 1
        elif c in '([{':
            depth += 1
        elif c in ')]}':
            depth -= 1
        elif c == '\n' and depth <= 0:
            return src[start:i], i
        i += 1
    return src[start:], n
