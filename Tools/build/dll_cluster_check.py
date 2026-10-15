# -*- coding: utf-8 -*-
r"""CYS-MTSWEEP 19/09 - kiem CUM BINARY phai di thanh bo: moi ky hieu mot tep NHAP tu mot tep khac
trong cum phai duoc tep kia XUAT.

Vi sao: `qlog-crash` do duoc rang `UI_CEGUI.dll` moi + `CEGUIFalagard.dll` cu => **chet ngay luc nap**,
truoc khi chay mot dong ma nao, khong co log de doc. 19/09 `CEGUIBase.dll` cung vao cum (nhanh
`info-parity`). Va bai hoc cua chinh dot nay: trong cay dung chung, mot DLL minh khong dung van doi
hash duoi chan minh, nen phai kiem lai sau MOI lan dung, khong phai mot lan dau.

    python Tools/build/dll_cluster_check.py <thu muc chua binary>      # Bin64 cua stage, hoac bin cua cay dung
    python Tools/build/dll_cluster_check.py --self-test                # doi chung: chung minh no BIET TRUOT

Ma thoat:  0 = DAT (da kiem THAT va 0 ky hieu thieu) · 1 = HONG CAP · 2 = KHONG KIEM DUOC

-------------------------------------------------------------------------------------------------
CYS-UIEDIT 20/09 - VA MOT CONG CHAN BAO XANH GIA. Doc ky truoc khi sua tiep.

Ban truoc cua tep nay tra ve 0 ("KHOP CAP") trong SAU tinh huong ma no chua kiem duoc gi ca. Mot
cong chan bao xanh gia con TE HON khong co cong, vi no lam moi nguoi ngung nghi - va day la ca thu
bay cua bai hoc "phep do khong chay ma dau vet trong y nhu da chay" (DIEU-PHOI 19/09 muc 24).

Sau duong xanh gia da bit, va vi sao moi duong deu IM LANG:

  1. Tham so la mot CO (`--stage`, `--help`...). `sys.argv[1]` khong phai thu muc => `present` rong
     => 0 phep so => "KHOP CAP". Dau hieu duy nhat cua ban cu la dong `cum:` RONG - khong ai nhin.
     Day la ca that: nhanh `ui-editor-2` goi `--stage <stage>` va nhan xanh gia.
  2. KHONG co tham so nao. Ban cu roi ve mot duong dan CUNG (`Build\cmake\host-2-x64\bin`) - cay
     dung cua NHANH KHAC. No di kiem binary cua nguoi ta roi bao xanh cho ban. Da BO HAN duong do.
  3. Thu muc co that nhung THIEU mot phan cum (vi du chi co `Game.exe`). Khong co canh nhap nao
     giua cac tep con lai => 0 phep so => xanh. Mot phep kiem MOT PHAN doi lot phep kiem DAY DU.
  4. `llvm-objdump` chay nhung tra ve RONG (tep khong phai PE hop le, hoac objdump loi). `exports()`
     ra tap rong, `imports()` ra dict rong => 0 phep so => xanh.
  5. Dinh dang objdump doi => regex khong khop gi => 0 phep so => xanh. (Chieu nguoc lai thi AN
     TOAN: neu chi `exports()` hong thi moi ky hieu deu bi bao thieu => do am i.)
  6. Cum du tep nhung khong tim thay canh nhap nao giua chung => 0 phep so => xanh.

LUAT CHUNG rut ra, ap cho moi cong chan khac: **khong duoc ket luan tu VIEC KHONG CO LOI; phai ket
luan tu SO PHEP SO DA THUC SU CHAY.** Vi vay tep nay dem `so_tep`, `so_canh`, `so_ky_hieu` va TU
CHOI ket luan DAT khi bat ky so nao trong do bang 0.
-------------------------------------------------------------------------------------------------
"""
import hashlib
import io
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

OBJDUMP = r"C:\Program Files\LLVM\bin\llvm-objdump.exe"
CLUSTER = ["CEGUIBase.dll", "CEGUIFalagard.dll", "UI_CEGUI.dll", "CEGUIOgreRenderer.dll", "Game.exe"]

RC_DAT = 0
RC_HONG_CAP = 1
RC_KHONG_KIEM_DUOC = 2


def _thoat_khong_kiem_duoc(ly_do):
    """Mot dong duy nhat, khong the doc nham thanh 'dat'."""
    print("KET QUA: KHONG KIEM DUOC - %s" % ly_do)
    print("         => DUNG TIN ket qua nay. Cum DLL CHUA duoc kiem.")
    return RC_KHONG_KIEM_DUOC


def dump(path):
    try:
        r = subprocess.run([OBJDUMP, "-p", path], capture_output=True, text=True, errors="replace")
    except OSError:
        return ""
    return r.stdout or ""


def _sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for blk in iter(lambda: fh.read(1 << 20), b""):
            h.update(blk)
    return h.hexdigest()


def kiem_ban_ke(base, present):
    """So tung tep cua cum voi `game_data_stage.json` ben canh (neu co).

    VI SAO CAN: phep so TEN KY HIEU o duoi KHONG phat hien duoc mot DLL CU cung API - da do:
    **14 ban dung khac nhau cua `CEGUIBase.dll` xuat y HET 3.928 ten**. Dung cai ma no sinh ra de
    bat (`UI_CEGUI` moi + `CEGUIFalagard` cu) thuong KHONG doi ten ky hieu nao, nen cong se xanh.
    Thu bat duoc la: moi nhi phan phai dung la tep ma `stage_game.py` da chep vao, tu MOT cay dung.

    Tra ve (ok, so_dong_mo_ta). `ok=None` = khong co ban ke (thu muc cay dung), khong phai loi.
    """
    p = os.path.join(base, "game_data_stage.json")
    if not os.path.isfile(p):
        return None, ["ban ke: khong co game_data_stage.json (thu muc cay dung?) - BO QUA phep so nay"]
    try:
        # `utf-8-sig`: mot so stage ghi ban ke KEM BOM (vi du `stage-costumes-all`). Doc bang
        # `utf-8` thuan thi `json.load` nem va cong bao DO OAN - da sap dung phat do khi quet 56 stage.
        with io.open(p, encoding="utf-8-sig") as fh:
            man = json.load(fh)
    except (ValueError, OSError) as e:
        return False, ["ban ke: doc khong duoc game_data_stage.json: %s" % e]

    theo_ten = {}
    for b in man.get("binaries", []) or []:
        if isinstance(b, dict) and b.get("name"):
            theo_ten[b["name"]] = b
    if not theo_ten:
        return False, ["ban ke: game_data_stage.json khong liet ke mot nhi phan nao"]

    dong = ["ban ke: game_data_stage.json, bin_source = %s" % (man.get("bin_source") or "(khong ghi)")]
    loi = []
    for n in present:
        b = theo_ten.get(n)
        if b is None:
            loi.append("ban ke: %s KHONG co trong ban ke (ai do chep tay vao?)" % n)
            continue
        mong = (b.get("sha256") or "").lower()
        that = _sha256(os.path.join(base, n)).lower()
        if mong and that != mong:
            loi.append("ban ke: %s LECH ban ke (tren dia %s..., ban ke %s...)" % (n, that[:16], mong[:16]))
    dong.extend(loi)
    return (not loi), dong


def exports(text):
    out = set()
    for m in re.finditer(r"^\s+\d+\s+0x[0-9a-f]+\s+(\S+)", text, re.M):
        out.add(m.group(1))
    return out


def imports(text):
    """-> {dll_lower: set(symbol)}"""
    res, cur = {}, None
    for line in text.splitlines():
        m = re.match(r"^\s*DLL Name:\s*(\S+)", line)
        if m:
            cur = m.group(1).lower()
            res.setdefault(cur, set())
            continue
        m = re.match(r"^\s+\d+\s+(\S+)$", line)
        if m and cur:
            res[cur].add(m.group(1))
    return res


def kiem(base, im_chi_tiet=False):
    """Tra ve (ma_thoat, so_canh, so_ky_hieu_thieu). In bao cao."""
    if not os.path.isdir(base):
        return _thoat_khong_kiem_duoc("khong phai thu muc: %r" % base), 0, 0

    if not os.path.isfile(OBJDUMP):
        return _thoat_khong_kiem_duoc("khong thay llvm-objdump: %s" % OBJDUMP), 0, 0

    present = [n for n in CLUSTER if os.path.isfile(os.path.join(base, n))]
    thieu = [n for n in CLUSTER if n not in present]
    print("thu muc: %s" % base)
    print("cum (%d/%d): %s" % (len(present), len(CLUSTER), ", ".join(present) if present else "(RONG)"))

    # Duong xanh gia so 1 va so 3: cum rong, hoac cum thieu tep.
    # Khong the ket luan "cum di thanh bo" khi mot phan cum khong co mat.
    if thieu:
        return _thoat_khong_kiem_duoc("thieu %d tep cua cum: %s" % (len(thieu), ", ".join(thieu))), 0, 0

    # Duong xanh gia so 4 va so 5: objdump khong doc duoc, hoac regex khong khop gi.
    text = {}
    for n in present:
        t = dump(os.path.join(base, n))
        if not t.strip():
            return _thoat_khong_kiem_duoc("llvm-objdump khong doc duoc %s (ra rong)" % n), 0, 0
        text[n] = t

    exp = {}
    for n in present:
        e = exports(text[n])
        exp[n.lower()] = e
    if not any(exp.values()):
        return _thoat_khong_kiem_duoc(
            "khong doc duoc MOT ky hieu xuat nao tu ca cum (dinh dang llvm-objdump da doi?)"), 0, 0

    so_canh = 0
    so_ky_hieu = 0
    thieu_tong = 0
    for name in present:
        imp = imports(text[name])
        for dll, syms in sorted(imp.items()):
            if dll not in exp:
                continue          # nhap tu DLL ngoai cum: khong thuoc pham vi phep kiem nay
            missing = sorted(s for s in syms if s not in exp[dll])
            so_canh += 1
            so_ky_hieu += len(syms)
            thieu_tong += len(missing)
            print("  %-22s nhap %4d tu %-22s thieu %d" % (name, len(syms), dll, len(missing)))
            for s in missing[:8]:
                print("      THIEU: %s" % s)
            if len(missing) > 8:
                print("      ... va %d ky hieu thieu nua" % (len(missing) - 8))

    # Duong xanh gia so 6: du tep nhung khong co canh nao => khong so gi ca.
    if so_canh == 0 or so_ky_hieu == 0:
        return _thoat_khong_kiem_duoc(
            "0 canh nhap giua cac tep trong cum (so_canh=%d so_ky_hieu=%d) - khong co gi de so"
            % (so_canh, so_ky_hieu)), so_canh, thieu_tong

    # Phep so thu hai, bat duoc dung cho ma phep so ten ky hieu MU (xem kiem_ban_ke).
    ban_ke_ok, ban_ke_dong = kiem_ban_ke(base, present)
    for d in ban_ke_dong:
        print("  %s" % d)

    # Chi tu day tro di moi duoc phep ket luan.
    print("da so THAT: %d tep, %d canh nhap, %d ky hieu" % (len(present), so_canh, so_ky_hieu))
    if thieu_tong:
        print("KET QUA: HONG CAP (%d ky hieu thieu tren %d ky hieu da so)" % (thieu_tong, so_ky_hieu))
        return RC_HONG_CAP, so_canh, thieu_tong
    if ban_ke_ok is False:
        print("KET QUA: HONG CAP (ten ky hieu khop, nhung nhi phan LECH BAN KE - xem dong 'ban ke' o tren)")
        return RC_HONG_CAP, so_canh, thieu_tong
    print("KET QUA: KHOP CAP (0 ky hieu thieu tren %d ky hieu da so%s)"
          % (so_ky_hieu, ", ban ke khop" if ban_ke_ok else ", KHONG co ban ke de doi chieu"))
    if ban_ke_ok is None:
        print("         LUU Y: phep so nay chi so TEN ky hieu. Mot DLL CU cung API van lot"
              " (da do: 14 ban dung CEGUIBase.dll xuat y het 3.928 ten).")
        print("         Tren mot stage that thi con doi chieu duoc game_data_stage.json; o thu muc"
              " cay dung thi khong.")
    return RC_DAT, so_canh, thieu_tong


# ----------------------------------------------------------------------------- doi chung
def _self_test():
    r"""Chung minh cong nay BIET TRUOT. Moi ca in ro: mong doi gi, nhan duoc gi.

    Ba ca dau khong can du lieu ngoai. Ca thu tu can mot thu muc that co du cum (tu dong tim
    trong Build\world-gui\*\Bin64); ca thu nam GHEP MOT CAP LECH THAT tu hai stage khac nhau -
    day moi la ca quan trong nhat, vi no la dung lop loi ma cong nay sinh ra de bat.
    """
    repo = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
    ket = []

    def ca(ten, base, mong_doi):
        print("\n=== CA: %s (mong doi ma thoat %s) ===" % (ten, mong_doi))
        rc, _, _ = kiem(base)
        dat = rc == mong_doi
        print("--> nhan duoc %d : %s" % (rc, "DUNG" if dat else "SAI"))
        ket.append((ten, dat))

    # 1. tham so la mot CO -> khong phai thu muc
    ca("tham so la co '--stage' (ca that cua ui-editor-2)", "--stage", RC_KHONG_KIEM_DUOC)
    # 2. thu muc khong ton tai
    ca("thu muc khong ton tai", os.path.join(repo, "Build", "__khong_ton_tai__"), RC_KHONG_KIEM_DUOC)
    # 3. thu muc rong
    tmp_rong = tempfile.mkdtemp(prefix="cys_cum_rong_")
    try:
        ca("thu muc rong (0 tep cua cum)", tmp_rong, RC_KHONG_KIEM_DUOC)
    finally:
        shutil.rmtree(tmp_rong, ignore_errors=True)

    # 4 + 5. can stage that
    stages = []
    goc = os.path.join(repo, "Build", "world-gui")
    if os.path.isdir(goc):
        for d in sorted(os.listdir(goc)):
            b = os.path.join(goc, d, "Bin64")
            if all(os.path.isfile(os.path.join(b, n)) for n in CLUSTER):
                stages.append(b)

    if not stages:
        print("\n(bo qua ca 4 va 5: khong tim thay stage nao co du cum)")
    else:
        ca("stage that, cum khop cap", stages[0], RC_DAT)

        # 5. CA DO THAT: thay `CEGUIBase.dll` bang mot DLL khac han. `CEGUIFalagard.dll` nhap ~800
        #    ky hieu tu `ceguibase.dll`, nen tat ca phai bao THIEU. Day la phep chung minh nhanh
        #    so-sanh-ky-hieu that su chay va that su do duoc.
        tmp = tempfile.mkdtemp(prefix="cys_cum_do_")
        try:
            for n in CLUSTER:
                shutil.copy2(os.path.join(stages[0], n), os.path.join(tmp, n))
            shutil.copy2(os.path.join(stages[0], "CEGUIOgreRenderer.dll"),
                         os.path.join(tmp, "CEGUIBase.dll"))
            print("\n(ca 5: `CEGUIBase.dll` bi thay bang mot DLL khac han => moi ky hieu Falagard nhap phai THIEU)")
            ca("CUM HONG THAT (mot tep bi thay)", tmp, RC_HONG_CAP)
        finally:
            shutil.rmtree(tmp, ignore_errors=True)

        # 6. DIEM MU DA BIET, ghi thanh mot ca CO KIEM chu khong de ngam.
        #    Hai BAN DUNG khac nhau cua CEGUIBase.dll xuat y HET ten ky hieu, nen phep so ten
        #    KHONG phat hien duoc. Do la ly do phai co phep so ban ke (`kiem_ban_ke`).
        goc_base = _sha256(os.path.join(stages[0], "CEGUIBase.dll"))
        khac = None
        for b in stages[1:]:
            if _sha256(os.path.join(b, "CEGUIBase.dll")) != goc_base:
                khac = b
                break
        if khac is None:
            print("\n(bo qua ca 6: moi stage dung cung mot CEGUIBase.dll)")
        else:
            tmp = tempfile.mkdtemp(prefix="cys_cum_mu_")
            try:
                for n in CLUSTER:
                    nguon = khac if n == "CEGUIBase.dll" else stages[0]
                    shutil.copy2(os.path.join(nguon, n), os.path.join(tmp, n))
                print("\n(ca 6 = DIEM MU: CEGUIBase.dll tu %s, phan con lai tu %s - HAI BAN DUNG KHAC NHAU)"
                      % (os.path.basename(os.path.dirname(khac)),
                         os.path.basename(os.path.dirname(stages[0]))))
                print(" Mong doi XANH: hai ban dung xuat y het ten ky hieu nen phep so ten khong thay gi.")
                print(" Day KHONG phai loi cua cong - la GIOI HAN cua viec so ten. Bat duoc no can ban ke.")
                ca("DIEM MU: hai ban dung khac nhau, cung ten ky hieu", tmp, RC_DAT)
            finally:
                shutil.rmtree(tmp, ignore_errors=True)

            # 7. CUNG MOT CAP LECH DO, nhung tren mot STAGE (co ban ke) => PHAI DO.
            #    Day la ca quan trong nhat cua ca tep: no la DUNG lop loi cong nay sinh ra de bat
            #    (`UI_CEGUI` moi + `CEGUIFalagard` cu), va la ca ma phep so TEN KY HIEU bo lot.
            stage_co_ban_ke = None
            for b in stages:
                if os.path.isfile(os.path.join(b, "game_data_stage.json")):
                    stage_co_ban_ke = b
                    break
            if stage_co_ban_ke is None:
                print("\n(bo qua ca 7: khong stage nao co game_data_stage.json)")
            else:
                thay = None
                goc = _sha256(os.path.join(stage_co_ban_ke, "CEGUIBase.dll"))
                for b in stages:
                    if _sha256(os.path.join(b, "CEGUIBase.dll")) != goc:
                        thay = os.path.join(b, "CEGUIBase.dll")
                        break
                if thay is None:
                    print("\n(bo qua ca 7: khong tim duoc mot CEGUIBase.dll khac)")
                else:
                    tmp = tempfile.mkdtemp(prefix="cys_cum_banke_")
                    try:
                        for n in CLUSTER + ["game_data_stage.json"]:
                            shutil.copy2(os.path.join(stage_co_ban_ke, n), os.path.join(tmp, n))
                        shutil.copy2(thay, os.path.join(tmp, "CEGUIBase.dll"))
                        print("\n(ca 7: stage that + CEGUIBase.dll bi THAY bang mot ban dung khac,"
                              " ten ky hieu y het)")
                        print(" Phep so TEN se noi 'thieu 0' o ca 5 canh. Chi ban ke bat duoc.")
                        ca("DLL CU CUNG API tren stage co ban ke", tmp, RC_HONG_CAP)
                    finally:
                        shutil.rmtree(tmp, ignore_errors=True)

    print("\n================ TONG KET DOI CHUNG ================")
    for ten, dat in ket:
        print("  %-52s %s" % (ten, "DAT" if dat else "TRUOT"))
    hong = [t for t, d in ket if not d]
    print("KET QUA SELF-TEST: %d/%d DAT" % (len(ket) - len(hong), len(ket)))
    return RC_DAT if not hong else RC_HONG_CAP


def main():
    args = [a for a in sys.argv[1:]]
    if "--self-test" in args:
        return _self_test()

    if not args:
        # Duong xanh gia so 2: ban cu roi ve mot duong dan CUNG cua cay dung nhanh khac.
        print("KET QUA: KHONG KIEM DUOC - thieu tham so")
        print("         Dung: python Tools/build/dll_cluster_check.py <thu muc chua binary>")
        print("         Vi du: ...\\Build\\world-gui\\<stage>\\Bin64  hoac  ...\\Build\\cmake\\<ten>-x64\\bin")
        print("         (KHONG co duong dan mac dinh: ban cu roi ve cay dung cua nhanh khac va bao xanh)")
        return RC_KHONG_KIEM_DUOC

    base = args[0]
    if base.startswith("-"):
        # Duong xanh gia so 1 - ca that da xay ra.
        print("KET QUA: KHONG KIEM DUOC - tham so %r la mot CO, khong phai thu muc." % base)
        print("         Script nay nhan THU MUC lam tham so VI TRI. Khong co `--stage`.")
        print("         Dung: python Tools/build/dll_cluster_check.py <stage>\\Bin64")
        return RC_KHONG_KIEM_DUOC

    rc, _, _ = kiem(base)
    return rc


if __name__ == "__main__":
    sys.exit(main())
