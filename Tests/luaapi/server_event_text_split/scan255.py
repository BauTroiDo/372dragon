# CYS-QUEST: server script dialogue strings longer than the CY GCScriptCommand text limit (255 bytes, Game.exe 0x1408471d0)
import collections, os, re, sys
root = sys.argv[1] if len(sys.argv) > 1 else '/home/ubuntu/cys-test-20260913/Game_2/Script/scripts'
pat = re.compile(r'(AddText|AddNumText|AddNumTextWithTarget|TAddNumText)\s*\(\s*(?:[^,"()]*,\s*)?"([^"]*)"')
cnt = collections.Counter(); ex = []; files = set()
for dp, _, fs in os.walk(root):
    for f in fs:
        if not f.endswith('.lua'):
            continue
        p = os.path.join(dp, f)
        try:
            t = open(p, encoding='utf-8').read()
        except Exception:
            continue
        for m in pat.finditer(t):
            s = m.group(2); b = len(s.encode('utf-8'))
            cnt['all'] += 1
            if b > 255:
                cnt[m.group(1)] += 1; files.add(p)
                gbk = len(s.encode('gbk', errors='replace'))
                if len(ex) < 12:
                    ex.append((b, p.replace(root, ''), s[:50]))
print(dict(cnt), 'files', len(files))
for e in ex:
    print(e)
