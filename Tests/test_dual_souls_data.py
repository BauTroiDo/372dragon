"""Cross-table/asset compatibility checks for the independent soul prototype."""
from pathlib import Path
import sys,tempfile,unittest,xml.etree.ElementTree as E
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'Tools/game'))
from dual_souls_data import tables,BASELINE,CAT
from hj_appearance_data import RawTable
from dual_souls_ui import actors,layout,wuhun,selfequip,inspect,baseline

class DualSoulDataTest(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.tmp=tempfile.TemporaryDirectory();cls.out={}
  for rel,raw in tables().items():
   p=Path(cls.tmp.name)/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(raw);cls.out[rel]=RawTable(p)
 @classmethod
 def tearDownClass(cls):cls.tmp.cleanup()
 def test_existing_records_and_skill_effects_are_preserved(self):
  for side in ['client','server']:
   for name in ['EquipBase','SkillTemplate_V1','SkillData_V1']:
    before=RawTable(BASELINE/side/(name+'.txt'));after=self.out[side+'/'+name+'.txt']
    for row in before.rows:self.assertEqual(row,after.byid[row[0]])
   t=self.out[side+'/SkillTemplate_V1.txt'];d=self.out[side+'/SkillData_V1.txt']
   for skill in CAT['skills']:
    row=t.byid[skill['id']];data=d.byid[skill['data']]
    self.assertEqual(row[30 if side=='client' else 34],1)
    self.assertEqual(row[48 if side=='client' else 58],skill['data'])
    old=t.byid[skill['source']];olddata=d.byid[old[48 if side=='client' else 58]]
    self.assertEqual(data[5:],olddata[5:]) # logic, MP, effect IDs and timing exactly the source
    self.assertEqual(row[13 if side=='client' else 16],-1 if skill['id']==6100 else skill['id']-5401)
 def test_independent_item_identity_and_slot(self):
  for side in ['client','server']:
   t=self.out[side+'/EquipBase.txt']
   self.assertEqual(t.byid[10156901][5],18);self.assertEqual(t.byid[10156902][5],39)
   self.assertEqual(t.byid[10156001][5],18)
 def test_attachment_preserves_existing_hj_actor_resources(self):
  raw=baseline('Overlay/Post/ModelFolder/cys_hj_riders.obj')
  original=E.fromstring(raw.decode('gbk'));changed=E.fromstring(actors(raw).decode('gbk'))
  self.assertEqual(len(original),4)
  for a,b in zip(original,changed):
   self.assertEqual(a.attrib,b.attrib)
   new=[e for e in b.iter('Locator') if e.get('name')=='CysBattleSoulLocator'];self.assertEqual(len(new),1)
   self.assertEqual(new[0].find('Slot').get('name'),'BattleSoulObj')
   self.assertEqual([e.attrib for e in a.iter('Animation')],[e.attrib for e in b.iter('Animation')])
   self.assertEqual([e.attrib for e in a.iter('Skeleton')],[e.attrib for e in b.iter('Skeleton')])
 def test_layouts_use_expat_supported_encoding_and_unique_names(self):
  layouts=[layout()]+[fn(baseline(f'Overlay/Post/InterfaceFolder/{name}/{name}.layout.xml')) for name,fn in [('Wuhun',wuhun),('SelfEquip',selfequip),('TargetEquip',inspect)]]
  for raw in layouts:
   self.assertIn(b"encoding='utf-8'",raw.splitlines()[0])
   root=E.fromstring(raw);names=[w.get('Name') for w in root.iter('Window')]
   self.assertEqual(len(names),len(set(names)))
if __name__=='__main__':unittest.main()
