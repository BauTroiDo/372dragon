"""Regression: renaming a mesh material must preserve the following geometry."""
import struct,sys,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path[:0]=[str(ROOT/'Tools/pipeline'),str(ROOT/'Tests')]
import canon_lib as C

class MaterialRewrite(unittest.TestCase):
 def test_submesh_size_and_geometry(self):
  def chunk(cid,payload):return struct.pack('<HI',cid,len(payload)+6)+payload
  geometry=chunk(0x5000,struct.pack('<I',3))
  indices=b'\0'+struct.pack('<I',3)+b'\0'+struct.pack('<3H',0,1,2)
  sub=chunk(0x4000,b'old\n'+indices+geometry)
  raw=b'\0\x10[MeshSerializer_v1.40]\n'+chunk(0x3000,b'\0'+sub)
  new=b'cys_wh_longer_material_name'
  result=C.mesh_set_submat(raw,b'old',new)
  self.assertTrue(result.endswith(indices+geometry))
  walk=C.v01_mesh.walk_mesh(result)
  self.assertEqual(walk['err'],'')
  self.assertEqual(walk['subs'][0]['mat'],new)
  self.assertEqual(walk['subs'][0]['verts'],3)
  q=walk['subs'][0]['span'][1]
  self.assertEqual(struct.unpack_from('<HI',result,q-6),(0x4000,len(sub)+len(new)-3))
  self.assertEqual(C.mesh_set_submat(result,new,b'old'),raw)

if __name__=='__main__':unittest.main()
