"""Give translated equipment types room without changing the tooltip style or events."""
import xml.etree.ElementTree as ET
def generate(data):
 root=ET.fromstring(data);found=0
 for node in root.iter('Window'):
  name=node.get('Name','')
  if name.endswith(('ShortDesc','Manufacturer_Frame')):
   height=22 if name.endswith('ShortDesc') else 24
   for p in node.findall('Property'):
    if p.get('Name')=='UnifiedSize':p.set('Value','{{1,-4},{0,%d}}'%height)
  if name.endswith('Manufacturer'):
   for p in node.findall('Property'):
    if p.get('Name')=='Position':p.set('Value','x:0.017964 y:0')
  if node.get('Name','').endswith('StaticPart_Item1'):
   for p in node.findall('Property'):
    if p.get('Name')=='AbsoluteSize':p.set('Value','w:138 h:20')
  if not node.get('Name','').endswith('ShortDesc_Text'):continue
  for p in node.findall('Property'):
   if p.get('Name')=='AbsoluteSize':p.set('Value','w:160 h:20')
   if p.get('Name')=='HorzFormatting':p.set('Value','LeftAligned')
  found+=1
 assert found==1,found
 return ET.tostring(root,encoding='utf-8',xml_declaration=True)
