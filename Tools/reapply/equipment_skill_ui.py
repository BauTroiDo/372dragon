"""Reapply equipment skill UI updates to the owned canonical tree."""
from pathlib import Path
import argparse
import datetime
import hashlib
import shutil
import re

ROOT = Path(__file__).resolve().parents[2]
TARGET = ROOT / 'Assets/CanonicalCY/Data/InterfaceFolder/EquipLingPai_SkillQH/EquipLingPai_SkillQH.lua'
OLD = '''\tlocal nEquipBagIndex = m_EquipBagIndex
\tEquipLingPai_SkillQH_NoEqup()
'''
NEW = '''\tlocal nEquipBagIndex = m_EquipBagIndex
\tlocal nSelIdx = m_Text_SkillList:GetFirstSelectItem()
\t-- The learned-skill reply can arrive after the window was opened. Rebuild
\t-- the labels from the authoritative mask, preserving the chosen item/row.
\tEquipLingPai_SkillQH_Init()
\tif nSelIdx >= 0 and nSelIdx < Lua_GetALLRlBuffNum() then
\t\tm_Text_SkillList:SetItemSelect(nSelIdx)
\tend
'''
KFS_OLD = '''\telseif (event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
\t\tif m_Equip_Idx ~= -1 and arg0 ~= nil and tonumber(arg0) == m_Equip_Idx then
\t\t\tNewWuhunSkillStudy_Update(m_Equip_Idx)
'''
KFS_NEW = '''\telseif (event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
\t\tif m_Equip_Idx ~= -1 and arg0 ~= nil and tonumber(arg0) == m_Equip_Idx then
\t\t\t-- A detail-only reply must preserve the paid result still bound to this item.
\t\t\tif g_WUhun_IsReset == 1 and DataPool:GetKFSNewSkillDesc(m_Equip_Idx,0) ~= "" then return end
\t\t\tg_WUhun_IsReset = 0
\t\t\tNewWuhunSkillStudy_Update(m_Equip_Idx)
'''

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    wuhun=TARGET.parents[1]/'NewWuhunSkillStudy/NewWuhunSkillStudy.lua'
    dark=TARGET.parents[1]/'AnqiShuxingNEW/AnqiShuxingNEW.lua'
    changes=[]
    for path,old,new in [(TARGET,OLD,NEW),(wuhun,'local g_YBCheck = 1--默认选中',
            'local g_YBCheck = 0-- Use owned materials by default; YB auto-buy is not implemented.'),
            (wuhun,KFS_OLD,KFS_NEW),
            (wuhun,'m_Equip_Idx ~= -1 and i_index ~= m_Equip_Idx and  g_WUhun_IsReset == 1',
             'm_Equip_Idx ~= -1 and itemIdx ~= m_Equip_Idx and  g_WUhun_IsReset == 1'),
            (wuhun,'tostring(LifeAbility : Get_Item_Icon_Name(itemIdx))','GetIconFullName(theAction:GetItemIconInShop())'),
            (dark,'tostring(LifeAbility : Get_Item_Icon_Name(i_index))','GetIconFullName(theAction:GetItemIconInShop())'),
            (dark,'LifeAbility : Get_Equip_Point(Dark_Bag_Index)','EnumAction(Dark_Bag_Index, "packageitem"):GetEquipPoint()'),
            (dark,'local nHave = AnqiShuxingNEW_WantNum:GetProperty("MoneyMaxNumber");',
             'local nHave = Player:GetData("MONEY") + Player:GetData("MONEY_JZ"); -- authoritative balance; old money widget has no MoneyMaxNumber getter')]:
        raw=next((data for p,data in reversed(changes) if p==path),path.read_bytes())
        text=raw.decode('utf-8').replace('\r\n','\n')
        if new in text:
            print('PASS: already installed',path.name);continue
        assert text.count(old)==1, f'Unexpected Lua source: {path.name}'
        fixed=text.replace(old,new)
        changes.append((path,fixed.replace('\n','\r\n' if b'\r\n' in raw else '\n').encode('utf-8')))
        print('source',path.name,'sha256',hashlib.sha256(raw).hexdigest())
    raw=next((data for p,data in reversed(changes) if p==dark),dark.read_bytes())
    text=raw.decode('utf-8').replace('\r\n','\n')
    # Keep the full description accessible even on unusually long variants;
    # clearing an item must clear its tooltip too.
    pattern=r'(?m)^(\s*)(AnqiShuxingNEW_(?:Before|After)Attr(?:First|Second|Third)):SetText\(([^\n]*)\)\s*$'
    def tooltip(match):
        indent,widget,value=match.groups()
        original=match.group(0).rstrip()
        if text[match.end():].lstrip().startswith(widget+':SetToolTip('):return match.group(0)
        return original+'\n'+indent+widget+':SetToolTip('+value+')'
    fixed=re.sub(pattern,tooltip,text)
    if fixed!=text:
        changes.append((dark,fixed.replace('\n','\r\n' if b'\r\n' in raw else '\n').encode('utf-8')))
    raw=next((data for p,data in reversed(changes) if p==TARGET),TARGET.read_bytes())
    text=raw.decode('utf-8')
    for value in ('nBuffName', 'nBuffName.."#{BHZB_140521_226}"'):
        old='m_Text_SkillList:AddItem('+value+', i - 1)'
        new=old+'\n\t\t\tm_Text_SkillList:SetItemTooltip(i - 1, '+value+')'
        if 'm_Text_SkillList:SetItemTooltip(i - 1, '+value+')' not in text:
            assert text.count(old)==1
            text=text.replace(old,new)
    if text.encode('utf-8')!=raw:changes.append((TARGET,text.encode('utf-8')))
    if not changes or not args.apply:return
    backup = ROOT / 'Build/backups/equipment-skill-ui' / datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    backup.mkdir(parents=True, exist_ok=False)
    for path,raw in dict(changes).items():
        shutil.copy2(path,backup/path.name);path.write_bytes(raw)
    print('Applied; backup', backup)

if __name__ == '__main__':
    main()
