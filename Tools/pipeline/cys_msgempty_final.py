# -*- coding: utf-8 -*-
"""CYS-MSGEMPTY: bang cuoi cung - 72 khoa x (nhom, khoa CY, co toi duoc khong).

Gop ba phep do da chay rieng:
  * `cys_msgempty_scan.py`       - cho goi, sink, phep canh          (trong Src/)
  * `cys_msgempty_cy_probe.py`   - CY 3.71 co chuoi khoa khong       (Game.exe CY)
  * `cys_msgempty_orig_probe.py` - client GOC 0.85 co khong          (Game.exe + tu dien goc)

Cot `reach` (co toi duoc khong) KHONG phai phong doan: no doc tu mot su that do duoc -
`GamePro_ChangeScene.cpp:108` `if (CysModernGame::IsActive()) { ...; return; }` nen socket
game 0.85 KHONG BAO GIO mo, va `NetManager.cpp:775 pPacket->Execute(...)` la cho DUY NHAT
goi `GC*Handler::Execute`. => moi tep duoi `Network/PacketHandler/` la ma chet hom nay.
Bang chung chay that: `Build\\world-gui\\stage-play-3\\Bin64\\WXClient.log` 20/09 08:46
"CYS world: game socket 1 connected" + "first unhandled GC id=..." (goi khong ai xu ly chi
duoc GHI LOG roi bo).
"""
import argparse
import json
import os
import sys
import time

# tep chi chay qua bo dieu phoi 0.85 (CNetManager) => chet tren server nay
LEGACY_DIR = "Network/PacketHandler/"
# GMUIDataPool chi chay khi co lenh DPC_UPDATE_TEAM_OR_GROUP, ma lenh do CHI duoc day tu
# GCTeamListHandler.cpp:23 va GCTeamResultHandler.cpp:16 - ca hai deu la handler 0.85.
DEAD_BY_COMMAND = {"Client/WXClient/DataPool/GMUIDataPool.cpp"}
# cong bien moi truong, mac dinh TAT (crash-anim): CYS_CRASHANIM_OLDKEY=1
DEAD_BY_ENVGATE = {("Client/WXClient/Object/TripperObj/GMTripperObj_ItemBox.cpp", 53)}

# khoa CY / ban goc 0.85 tuong duong, doc tay tu ban ke `unit-keys-*.txt` + chuoi hai binary.
# Moi dong deu phai co: khoa dich + van ban + so dac ta khop so doi so cua cho goi.
CY_MAP = {
    "WIN_EXP": ("GCDetailExp_Human_NormalExp", "co trong CA HAI binary; CY chuyen thong bao "
                "kinh nghiem sang goi GCDetailExp (1288) thay vi suy tu delta thuoc tinh"),
    "WIN_ADD_EXP": ("GCDetailExp_Human_AdditionalExp", "nhu tren, phan thuong kinh nghiem"),
    "WIN_ITEM": ("battle_get_myself", "co trong CA HAI binary: 'Nguoi nhan duoc #H%s#W.'"),
    "TEAM_DISMISS": ("GMUIDataPool_Info_Team_Dismiss", "cung don vi, 0 dac ta, khop 0 doi so"),
    "TEAM_FOLLOW_OTHER": ("GCReturnTeamFollowHandler_Info_Join_Follow",
                          "cung don vi, 1 dac ta, khop 1 doi so"),
    "SKILL_LEVLE_UP": ("GCAbilityLevelHandler_1",
                       "cung don vi; 1 dac ta vs 2 doi so cho goi => doi so thua, VO HAI"),
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--scan', required=True)
    ap.add_argument('--map', required=True)
    ap.add_argument('--cy', required=True)
    ap.add_argument('--orig', required=True)
    ap.add_argument('--out', required=True)
    a = ap.parse_args()

    scan = json.load(open(a.scan, encoding='utf-8'))
    mp = json.load(open(a.map, encoding='utf-8'))
    cy = json.load(open(a.cy, encoding='utf-8'))
    orig = json.load(open(a.orig, encoding='utf-8'))

    by_site = {}
    for r in mp['rows']:
        by_site[(r['file'], r['line'], r['key'])] = r

    rows = []
    for r in mp['rows']:
        f, ln, k = r['file'], r['line'], r['key']
        if LEGACY_DIR in f:
            reach, why = "CHET", "handler 0.85, bo dieu phoi khong con chay"
        elif f in DEAD_BY_COMMAND:
            reach, why = "CHET", "chi chay khi co DPC_UPDATE_TEAM_OR_GROUP, ma lenh do chi den tu handler 0.85"
        elif (f, ln) in DEAD_BY_ENVGATE:
            reach, why = "CHET", "sau cong CYS_CRASHANIM_OLDKEY=1, mac dinh TAT"
        else:
            reach, why = "SONG", "duong Lua / duong goi hien dai"
        cyk = CY_MAP.get(k, (r.get('cy_key'), ""))
        rows.append({
            "key": k, "origin": r['origin'], "file": f, "line": ln,
            "macro": r['macro'], "nargs": r['nargs'], "sink": r['sink'],
            "reach": reach, "reach_why": why,
            "cy_key": cyk[0], "cy_note": cyk[1] or ("suy tu hau to _Info_" if r.get('cy_key') else ""),
            "cy_key_in_our_dict": r.get('cy_key_in_our_dict'),
            "group": "a" if cyk[0] else "b",
            "in_cy_bin": any(cy['found'].get(k, {}).values()),
            "in_orig_bin": any(orig['in_orig_bin'].get(k, {}).values()),
            "in_orig_dict": any(orig['in_orig_dict'].get(k, {}).values()),
        })

    res = {"generated": time.strftime("%Y-%m-%d %H:%M:%S"),
           "cy_build": cy.get('cy_build_id'),
           "cy_bins": cy.get('binaries'),
           "orig_bins": orig.get('bins'),
           "orig_dicts": {k: {kk: vv for kk, vv in v.items() if kk != '_d'}
                          for k, v in orig.get('dicts', {}).items()},
           "rows": rows}
    json.dump(res, open(a.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)

    keys_song = sorted({r['key'] for r in rows if r['reach'] == 'SONG'})
    keys_chet = sorted({r['key'] for r in rows if r['reach'] == 'CHET'} - set(keys_song))
    ga = sorted({r['key'] for r in rows if r['group'] == 'a'})
    gb = sorted({r['key'] for r in rows if r['group'] == 'b'})
    print("dong (cho goi + o bang) : %d" % len(rows))
    print("khoa rieng biet          : %d" % len({r['key'] for r in rows}))
    print()
    print("SONG (nguoi choi toi duoc)  : %2d khoa  %s" % (len(keys_song), keys_song))
    print("CHET (khong bao gio toi)    : %2d khoa" % len(keys_chet))
    print()
    print("nhom a (CY co khoa tuong duong) : %d khoa" % len(ga))
    print("nhom b (CY bo han / chua ro)    : %d khoa" % len(gb))
    print()
    print("khoa trong CY 3.71 binary   : %d" % len({r['key'] for r in rows if r['in_cy_bin']}))
    print("khoa trong 0.85 GOC binary  : %d" % len({r['key'] for r in rows if r['in_orig_bin']}))
    print("khoa trong 0.85 GOC tu dien : %d" % len({r['key'] for r in rows if r['in_orig_dict']}))
    print("\n-> %s" % a.out)
    return 0


if __name__ == '__main__':
    sys.exit(main())
