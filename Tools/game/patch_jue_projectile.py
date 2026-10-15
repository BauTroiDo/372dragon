"""Recover the four CY Jue basic-attack hit markers from the living GL equivalents."""
import re
from pathlib import Path

def generate(raw):
 donor=Path('C:/TLBB/085/client_GL/Data/EffectFolder/all.skill').read_bytes()
 for name in [b'cy4_s_1e011682e1d1a4b1',b'cy4_s_ab77edccf189755e']:
  m=re.search(rb'(?:^|\n)skill '+name+rb'\s*\{(.*?)(?=\n(?:skill |\Z))',donor,re.S)
  assert m and re.search(rb'HitTime\s+0\.2\s',m[1])
 result=raw
 for sex in ['m01','g01']:
  for suffix in ['', '通用普攻']:
   name=(sex+'_cr_刃击千里'+suffix).encode('gb18030')
   pat=rb'((?:^|\n)skill '+re.escape(name)+rb'\s*\{.*?\bHitTime[ \t]+)-1([ \t]*[\r\n])'
   result,n=re.subn(pat,lambda m:m[1]+b'0.2'+m[2],result,count=1,flags=re.S)
   assert n==1,name
 assert len(re.findall(rb'\bHitTime\b',result))==len(re.findall(rb'\bHitTime\b',raw))
 return result
