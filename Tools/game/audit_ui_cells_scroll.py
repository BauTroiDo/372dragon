"""Inventory shared cell skins and scrollable widgets in the canonical CY layouts."""
from pathlib import Path
import collections, json, re

ROOT = Path(__file__).resolve().parents[2]
UI = ROOT / 'Assets/CanonicalCY/Data/InterfaceFolder'
OUT = ROOT / 'Build/Logs/2026-09-23-ui-wheel'

def attrs(text):
    return dict(re.findall(r'(\w+)\s*=\s*"([^"]*)"', text))

def main():
    maps = {}
    for p in (UI / 'Schema').glob('*.scheme.xml'):
        for tag in re.findall(r'<FalagardMapping\s+([^>]+)', p.read_text(encoding='utf8', errors='replace')):
            a = attrs(tag)
            maps[a['WindowType']] = a
    looks = {}
    for p in (UI / 'Schema').glob('*.looknfeel.xml'):
        raw = re.sub(r'<!--.*?-->', '', p.read_text(encoding='utf8', errors='replace'), flags=re.S)
        for tag, body in re.findall(r'<WidgetLook\s+([^>]+)>(.*?)</WidgetLook>', raw, re.S):
            looks[attrs(tag)['name']] = dict(file=p.name, states=re.findall(r'<StateImagery\s+name="([^"]+)"', body), imagery=len(re.findall(r'<Section\s', body)))
    usage = collections.defaultdict(list)
    files = list(UI.rglob('*.layout.xml'))
    for p in files:
        raw = re.sub(r'<!--.*?-->', '', p.read_text(encoding='utf8', errors='replace'), flags=re.S)
        for tag in re.findall(r'<Window\s+([^>]+)', raw):
            a = attrs(tag)
            usage[a.get('Type', '')].append(dict(layout=str(p.relative_to(UI)), name=a.get('Name', '')))
    cells = []
    scrolls = []
    for name, m in maps.items():
        target = m['TargetType'].split('/')[-1]
        look = looks.get(m['LookNFeel'], {})
        row = dict(type=name, target=m['TargetType'], look=m['LookNFeel'], **look, count=len(usage[name]), layouts=sorted({u['layout'] for u in usage[name]}), examples=usage[name][:8])
        if target == 'SimpleText' and look.get('imagery', 0): cells.append(row)
        if target in ('Listbox','ListBoxEx','NotSuperList','Achievement','AchievementWindow','ComplexWindow','ChatHistory','ScrollablePane','MultiColumnList','StaticText','ImageListBox','ImageListBoxEx') and usage[name]: scrolls.append(row)
    data = dict(layout_files=len(files), cell_instances=sum(r['count'] for r in cells), cell_layouts=len({f for r in cells for f in r['layouts']}), cells=cells, scrolls=scrolls)
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT/'catalog.json').write_text(json.dumps(data, ensure_ascii=False, indent=2)+'\n', encoding='utf8')
    print(json.dumps({k:data[k] for k in ('layout_files','cell_instances','cell_layouts')}))
    print('Cell skins:', [(r['type'],r['count']) for r in cells if r['count']])
    print('Scroll families:', sorted({r['target'] for r in scrolls}))
    for family in ('ComplexWindow','NotSuperList','Listbox','MultiColumnList','StaticText','ChatHistory'):
        rows=[r for r in scrolls if r['target'].endswith('/'+family)]
        print(family, [(r['type'],r['count'],r['examples'][:2]) for r in rows[:4]])

if __name__ == '__main__': main()
