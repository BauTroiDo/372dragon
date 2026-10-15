# -*- coding: utf-8 -*-
"""bullet-fx (19/09/2026): doc log mot luot do va tra loi "KHONG TAO hay KHONG VE" bang so.

DINH NGHIA DUNG DE DEM — neu ro vi day la cho cac nhanh khac tung do hoan hao tren mot dinh nghia thieu:

  goi toi        = co dong `CYS-BULLETFX: packet 909` cho tag do        (tang MANG)
  duoc yeu cau   = dong do co `bullet=` khac -1                          (tang DU LIEU: skill -> Bullet.txt)
  chay ngay      = dong `logic-event ... -> run-now`                     (tang LOGIC, cong IsLogicReady)
  bi xep hang    = `-> queued`; neu sau do co `DROPPED-UNSHOWN` thi dan bi NUOT IM LANG
  DA TAO         = co dong `CYS-BULLETFX: create`                        (tang DOI TUONG)
  DA GUI DI VE   = co dong `CYS-BULLETFX: attach effect ... -> created`  (tang VE)
  KHONG THAY DUOC= da tao, contrail la loai bay, nhung `hit ... ticks=1`  (song dung mot khung hinh)

  => "KHONG TAO" = goi toi + duoc yeu cau + KHONG co dong `create`.
  => "TAO MA KHONG VE" = co `create` nhung khong co `attach effect ... -> created`,
     hoac co attach nhung `can't find the required effect template` cho dung ten do (rot ve Effect_Error),
     hoac `ticks=1` tren mot dan loai bay.

Ba doi chung am cua kich ban (xem bullet_scenario.py) PHAI ra dung nhu duoi, neu khong thi phep do MU:
  NA-s281   : goi toi, bullet=-1, KHONG create
  NB-s999999: goi toi, bullet=-1, KHONG create
  NC-s2501  : goi toi, bullet=195, CO create, KHONG attach  <-- ca "tao ma khong ve" co that

DUNG:
  python -B Tools/fx/bullet/bullet_report.py --run <thu muc luot do> --meta <run1.meta.json> --out <file>.json
"""
import argparse
import io
import json
import os
import re

RE_TAG = re.compile(r'CYS scenario: tag (\S+) seen')
RE_PKT = re.compile(r'CYS-BULLETFX: packet 909 obj=(\d+) data_type=(\d+) skill_or_special=(\d+) bullet=(-?\d+) '
                    r'hit_char=(\d+) targets=(\d+) is_character=(\d+)')
RE_LOGIC = re.compile(r'CYS-BULLETFX: logic-event bullet=(-?\d+) sender=(-?\d+) sender_logic=(-?\d+) '
                      r'creater=(\S+) ready=(\d+) -> (\S+) target=(-?\d+)')
RE_CREATE = re.compile(r'CYS-BULLETFX: create n=(\d+) bullet=(-?\d+) data=(\S+) contrail=(-?\d+) speed=([\d.]+) '
                       r"fly='([^']*)' hit='([^']*)'")
RE_HIT = re.compile(r'CYS-BULLETFX: hit n=(\d+) bullet=(-?\d+) ticks=(\d+) ms=(\d+) dist_flown=([\d.-]+)')
RE_DROP = re.compile(r'CYS-BULLETFX: DROPPED-UNSHOWN bullet=(-?\d+) sender=(-?\d+) sender_logic=(-?\d+) waited_ms=(\d+)')
RE_NOSEND = re.compile(r'CYS-BULLETFX: NO-SENDER bullet=(-?\d+) sender=(-?\d+)')
RE_ATTACH = re.compile(r"CYS-BULLETFX: attach effect '([^']*)' -> (\S+) node=(\S+)")
RE_MISSFX = re.compile(r"can't find the required effect template '([^']*)")


def read(path):
    if not os.path.isfile(path):
        return []
    with io.open(path, 'rb') as f:
        raw = f.read()
    try:
        text = raw.decode('utf-8')
    except UnicodeDecodeError:
        text = raw.decode('gbk', 'replace')
    return text.split('\n')


def selftest():
    """DOI CHUNG AM cho chinh bo doc log.

    Phai chung minh HAI dieu, khong chi mot:
      (a) phan biet duoc 8 ket cuc khac nhau;
      (b) **khong phu thuoc thu tu** dong `tag ... seen` so voi cac dong `CYS-BULLETFX` — vi trong luot do
          that, pha A ghi goi TRUOC tag con pha B/C ghi tag truoc goi. Ban dau bo doc gom theo "tag gan nhat
          phia tren" va vi vay lech mot nhip; ba doi chung am cua kich ban da bat duoc.
    """
    P = "CYS-BULLETFX: packet 909 obj=2002 data_type=0 skill_or_special=%d bullet=%d hit_char=1 targets=1 is_character=1"
    LG = "CYS-BULLETFX: logic-event bullet=%d sender=2002 sender_logic=%d creater=found ready=%d -> %s target=2001"
    CR = "CYS-BULLETFX: create n=1 bullet=%d data=yes contrail=0 speed=10.00 fly='%s' hit='h' send=2002 target=2001 single=1 pos=1.0,1.0,1.0 tpos=2.0,2.0,2.0 render=yes"
    HT = "CYS-BULLETFX: hit n=1 bullet=%d ticks=%d ms=100 dist_flown=1.00 pos=1,1,1 contrail=0"
    TG = 'CYS scenario: tag %s seen (session 0 ms after enter)'
    # (ket cua mong doi, skill, cac dong client CUA MAN, cac dong render)
    cases = [
        ('CO-DAN', 371, [P % (371, 92), LG % (92, 0, 1, 'run-now'), CR % (92, 'fx_ok'), HT % (92, 40)],
         ["CYS-BULLETFX: attach effect 'fx_ok' -> created node=yes"]),
        ('KHONG-YEU-CAU-DAN', 281, [P % (281, -1)], []),
        ('KHONG-TAO', 372, [P % (372, 93), LG % (93, 5, 0, 'queued'),
                            "CYS-BULLETFX: DROPPED-UNSHOWN bullet=93 sender=2002 sender_logic=5 waited_ms=10000"], []),
        ('TAO-KHONG-CO-HINH-BAY', 2501, [P % (2501, 195), CR % (195, '')], []),
        ('TAO-MA-KHONG-VE', 373, [P % (373, 94), CR % (94, 'fx_x'), HT % (94, 40)], []),
        ('VE-NHAM-Effect_Error', 374, [P % (374, 95), CR % (95, 'fx_gone'), HT % (95, 40)],
         ["CYS-BULLETFX: attach effect 'fx_gone' -> created node=yes",
          "EffectManager::createEffect: can't find the required effect template 'fx_gone"]),
        ('TAO-MA-KHONG-THAY-DUOC', 375, [P % (375, 96), CR % (96, 'fx_1t'), HT % (96, 1)],
         ["CYS-BULLETFX: attach effect 'fx_1t' -> created node=yes"]),
        ('GOI-KHONG-TOI', 376, [], []),
    ]
    ok = 0
    total = 0
    for order in ('tag-truoc', 'goi-truoc'):
        client, render, tags = [], [], []
        for i, (_, skill, cl, rn) in enumerate(cases):
            tag = 'T%d' % (i + 1)
            if order == 'tag-truoc':
                client += [TG % tag] + cl
            else:
                client += cl + [TG % tag]
            render += rn
            tags.append({'tag': tag, 'phase': 'A', 'skill': skill, 'note': ''})
        rows = analyse(client, render, {'tags': tags})['rows']
        for (want, _, _, _), r in zip(cases, rows):
            good = r['verdict'] == want
            ok += 1 if good else 0
            total += 1
            print('%-10s %-6s muon=%-24s duoc=%-24s %s' % (order, r['tag'], want, r['verdict'],
                                                           'PASS' if good else 'FAIL'))
    print('selftest: %d/%d PASS (8 ket cuc x 2 thu tu log)' % (ok, total))
    return 0 if ok == total else 1


def analyse(client, render, meta):
    """Gom cac dong CYS-BULLETFX thanh "man" (episode) roi gan vao tag theo DANH TINH SKILL, khong theo vi tri log.

    VI SAO KHONG THEO VI TRI (do that, luot r2): o pha A, `targetlist` den DUNG giay cua `tag`, va bo xu ly goi
    chay TRUOC khi bo dieu khien kich ban nhan ra tag ⇒ dong `packet 909` nam TRUOC dong `tag ... seen`.
    O pha B/C thi nguoc lai (goi den sau tag 400 ms). Gom theo "tag gan nhat phia tren" vi vay lech MOT NHIP
    va moi phan quyet bi gan sai tag. **Ba doi chung am da bat duoc chinh loi nay** (2/3 FAIL) — do dung la
    viec cua chung.

    Cach dung: moi dong `packet 909` mo mot man; cac dong sau no thuoc man do cho toi dong `packet 909` ke tiep.
    Man thu k co `skill = S` gan vao tag thu k co `skill = S` trong ke hoach (kich ban phat dung thu tu).
    """
    attaches = [RE_ATTACH.search(l).groups() for l in render if RE_ATTACH.search(l)]
    missing_fx = [RE_MISSFX.search(l).group(1) for l in render if RE_MISSFX.search(l)]

    seen_tags, episodes, cur = [], [], None
    for line in client:
        m = RE_TAG.search(line)
        if m:
            seen_tags.append(m.group(1))
            continue
        m = RE_PKT.search(line)
        if m:
            cur = {'packet': {'obj': int(m.group(1)), 'data_type': int(m.group(2)), 'skill': int(m.group(3)),
                              'bullet': int(m.group(4)), 'hit_char': int(m.group(5)),
                              'targets': int(m.group(6)), 'is_character': int(m.group(7))},
                   'logic': None, 'create': None, 'hit': None, 'dropped': None, 'no_sender': None}
            episodes.append(cur)
            continue
        if cur is None:
            continue
        m = RE_LOGIC.search(line)
        if m:
            cur['logic'] = {'bullet': int(m.group(1)), 'sender': int(m.group(2)), 'sender_logic': int(m.group(3)),
                            'creater': m.group(4), 'ready': int(m.group(5)), 'path': m.group(6),
                            'target': int(m.group(7))}
            continue
        m = RE_CREATE.search(line)
        if m:
            cur['create'] = {'n': int(m.group(1)), 'bullet': int(m.group(2)), 'data': m.group(3),
                             'contrail': int(m.group(4)), 'speed': float(m.group(5)),
                             'fly': m.group(6), 'hit_effect': m.group(7)}
            continue
        m = RE_HIT.search(line)
        if m:
            cur['hit'] = {'n': int(m.group(1)), 'bullet': int(m.group(2)), 'ticks': int(m.group(3)),
                          'ms': int(m.group(4)), 'dist_flown': float(m.group(5))}
            continue
        m = RE_DROP.search(line)
        if m:
            cur['dropped'] = {'bullet': int(m.group(1)), 'waited_ms': int(m.group(4))}
            continue
        m = RE_NOSEND.search(line)
        if m:
            cur['no_sender'] = {'bullet': int(m.group(1)), 'sender': int(m.group(2))}

    # gan man vao tag theo (skill, lan thu may)
    by_skill = {}
    for e in episodes:
        by_skill.setdefault(e['packet']['skill'], []).append(e)
    used = {}
    buckets = {}
    for t in meta['tags']:
        k = used.get(t['skill'], 0)
        lst = by_skill.get(t['skill'], [])
        buckets[t['tag']] = lst[k] if k < len(lst) else None
        used[t['skill']] = k + 1

    # gan `attach effect` theo TEN hieu ung bay (moi lan ghep tieu thu mot dong)
    pool = list(attaches)
    for t in meta['tags']:
        b = buckets[t['tag']]
        if not b or not b['create'] or not b['create']['fly']:
            continue
        for i, (name, res, node) in enumerate(pool):
            if name == b['create']['fly']:
                b['attach'] = {'name': name, 'result': res, 'node': node}
                pool.pop(i)
                break

    rows, verdicts = [], {}
    for t in meta['tags']:
        b = buckets[t['tag']] or {'packet': None, 'logic': None, 'create': None, 'hit': None,
                                  'dropped': None, 'no_sender': None}
        pkt, cr, at = b['packet'], b['create'], b.get('attach')
        flying = bool(cr) and cr['contrail'] in (0, 1)
        if pkt is None:
            v = 'GOI-KHONG-TOI'
        elif pkt['bullet'] == -1:
            v = 'KHONG-YEU-CAU-DAN'
        elif cr is None:
            v = 'KHONG-TAO'
        elif flying and not cr['fly']:
            v = 'TAO-KHONG-CO-HINH-BAY'
        elif at is None or at['result'] != 'created':
            v = 'TAO-MA-KHONG-VE'
        elif cr['fly'] in missing_fx:
            v = 'VE-NHAM-Effect_Error'
        elif b['hit'] and flying and b['hit']['ticks'] <= 1:
            v = 'TAO-MA-KHONG-THAY-DUOC'
        else:
            v = 'CO-DAN'
        verdicts[v] = verdicts.get(v, 0) + 1
        row = dict(b)
        row.update({'tag': t['tag'], 'phase': t.get('phase'), 'skill': t.get('skill'),
                    'note': t.get('note'), 'tag_seen': t['tag'] in seen_tags, 'verdict': v, 'attach': at})
        rows.append(row)
    return {'rows': rows, 'verdicts': verdicts, 'order': seen_tags,
            'episodes': len(episodes),
            'missing_effect_templates': sorted(set(missing_fx)), 'attach_lines': len(attaches)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--selftest', action='store_true')
    ap.add_argument('--run', help='thu muc luot do (chua WXClient.log, WXRender.log)')
    ap.add_argument('--meta')
    ap.add_argument('--out')
    a = ap.parse_args()
    if a.selftest:
        raise SystemExit(selftest())
    if not a.run or not a.meta or not a.out:
        raise SystemExit('--run, --meta, --out bat buoc (tru khi --selftest)')

    meta = json.load(open(a.meta, encoding='utf-8'))
    res = analyse(read(os.path.join(a.run, 'WXClient.log')),
                  read(os.path.join(a.run, 'WXRender.log')), meta)
    rows, verdicts, order = res['rows'], res['verdicts'], res['order']

    # kiem chinh phep do: ba doi chung am cua kich ban phai dung
    expect = {'NA-s281': 'KHONG-YEU-CAU-DAN', 'NB-s999999': 'KHONG-YEU-CAU-DAN',
              'NC-s2501': 'TAO-KHONG-CO-HINH-BAY'}
    control = []
    for suffix, want in expect.items():
        for r in rows:
            if r['tag'].endswith(suffix):
                control.append({'tag': r['tag'], 'want': want, 'got': r['verdict'], 'pass': r['verdict'] == want})
    out = {
        'schema': 1, 'run': os.path.abspath(a.run), 'meta': os.path.abspath(a.meta),
        'tags_seen': len(order), 'tags_planned': len(meta['tags']),
        'verdicts': verdicts,
        'doi_chung_am': control,
        'doi_chung_am_pass': sum(1 for c in control if c['pass']),
        'doi_chung_am_total': len(control),
        'missing_effect_templates': res['missing_effect_templates'],
        'attach_lines': res['attach_lines'],
        'rows': rows,
    }
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    json.dump(out, open(a.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(json.dumps({k: out[k] for k in ('tags_seen', 'tags_planned', 'verdicts', 'doi_chung_am_pass',
                                          'doi_chung_am_total', 'attach_lines')}, ensure_ascii=False, indent=1))
    for c in control:
        print('  doi chung %-14s muon=%-22s duoc=%-22s %s' % (c['tag'], c['want'], c['got'], 'PASS' if c['pass'] else 'FAIL'))
    print('-> %s' % a.out)


if __name__ == '__main__':
    main()
