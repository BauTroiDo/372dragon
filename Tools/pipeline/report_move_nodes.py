"""Check opt-in production movement telemetry; no missing log can pass."""
import argparse, json, math, re
from pathlib import Path

ap=argparse.ArgumentParser()
ap.add_argument('log',type=Path)
ap.add_argument('--arm',choices=['legacy','patched'],required=True)
args=ap.parse_args()
tick=re.compile(r'CYS move-node: tick legacy=(\d+) ms=(\d+) speed=([\d.e+-]+) budget=([\d.e+-]+) node=(\d+)/(\d+) from=([\d.e+-]+),([\d.e+-]+) target=([\d.e+-]+),([\d.e+-]+) distance=([\d.e+-]+)')
advance=re.compile(r'CYS move-node: advance node=(\d+) target=([\d.e+-]+),([\d.e+-]+) remaining=([\d.e+-]+) distance=([\d.e+-]+)')
result=re.compile(r'CYS move-node: result node=(\d+) pos=([\d.e+-]+),([\d.e+-]+) stop=(\d+)')
rows=[]; current=None; skipped=0
log_text=args.log.read_text(errors='replace') if args.log.is_file() else ''
for line_no,line in enumerate(log_text.splitlines(),1):
    m=tick.search(line)
    if m:
        if current: skipped+=1
        g=m.groups()
        current={'line':line_no,'legacy':int(g[0]),'ms':int(g[1]),'speed':float(g[2]),'budget':float(g[3]),'node':int(g[4]),'nodes':int(g[5]),'pos':tuple(map(float,g[6:8])),'target':tuple(map(float,g[8:10])),'arc':0.0,'advances':0}
        continue
    if not current: continue
    m=advance.search(line)
    if m:
        current['arc']+=math.dist(current['pos'],current['target'])
        current['pos']=current['target'];current['target']=(float(m[2]),float(m[3]));current['advances']+=1
        continue
    m=result.search(line)
    if m:
        current['arc']+=math.dist(current['pos'],(float(m[2]),float(m[3])))
        current['stop']=bool(int(m[4]));current['end_node']=int(m[1])
        current['excess']=current['arc']-current['budget']
        rows.append(current);current=None
if current: skipped+=1
violations=[r for r in rows if r['excess']>0.0002]
multi=[r for r in rows if r['nodes']>1]
wrong=[r for r in rows if r['legacy'] != int(args.arm=='legacy')]
verdict='NOT_RUN'
if rows and multi:
    verdict=('PASS_TELEMETRY_ONLY' if not wrong and ((not violations and args.arm=='patched') or (violations and args.arm=='legacy')) else 'FAIL')
print(json.dumps({'verdict':verdict,'arm':args.arm,'ticks':len(rows),'multi_node_ticks':len(multi),'advance_events':sum(r['advances'] for r in rows),'stops':sum(r['stop'] for r in rows),'incomplete_or_early_ticks':skipped,'effective_client_speeds':sorted(set(r['speed'] for r in rows)),'max_excess':max((r['excess'] for r in rows),default=None),'violations':violations[:12],'limitation':'Does not prove server position, NPC spawn, matching binary SHA, or visual arrival; inspect those separately.'},indent=2))
raise SystemExit(0 if verdict=='PASS_TELEMETRY_ONLY' else 2)
