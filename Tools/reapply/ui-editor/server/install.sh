#!/bin/bash
# CYS-UIEDIT 20/09/2026 — cai nua server cua "NPC mo cac khung con loi".
#
# Chay trong WSL TLBB:
#   wsl.exe -d TLBB -- bash /mnt/c/TLBB/085/CY-Source/Tools/reapply/ui-editor/server/install.sh
#
# Go ra:
#   wsl.exe -d TLBB -- bash /mnt/c/TLBB/085/CY-Source/Tools/reapply/ui-editor/server/install.sh --go-ra
#
# KHONG can restart server: `Game_2/Script/**` nap luoi qua `try_load`.
# Moi buoc deu soat cu phap bang `luac -p` TRUOC khi ghi de, va sao luu kem sha256.
set -u

SRV=/home/ubuntu/cys-test-20260913
REPO=/mnt/c/TLBB/085/CY-Source
HOST="$SRV/Game_2/Script/scripts/obj/dali/odali_zhongzhipai1.lua"
MODULE_DST="$SRV/Game_2/Script/scripts/obj/uiedit_menu.lua"
MODULE_SRC="$REPO/Tools/reapply/ui-editor/server/uiedit_menu.lua"
BAK="$SRV/backups/uiedit-20260920"
CALL='    require("scripts.obj.uiedit_menu").menu(self, selfId)   -- CYS-UIEDIT'
ANCHOR='self:AddText("Ngươi hãy đi học kỹ năng trồng trọt trước đi")'

die() { echo "HONG: $*" >&2; exit 1; }

[ -f "$HOST" ] || die "khong thay NPC chu: $HOST"
command -v luac >/dev/null || die "khong co luac de soat cu phap"

if [ "${1:-}" = "--go-ra" ]; then
    if [ -f "$BAK/odali_zhongzhipai1.lua.bak" ]; then
        cp -p "$BAK/odali_zhongzhipai1.lua.bak" "$HOST" || die "khong phuc hoi duoc"
        echo "da phuc hoi $HOST tu ban sao luu"
    else
        echo "khong co ban sao luu; go dong CYS-UIEDIT bang tay"
        grep -n "CYS-UIEDIT" "$HOST" || true
    fi
    rm -f "$MODULE_DST" && echo "da xoa $MODULE_DST"
    sha256sum "$HOST"
    exit 0
fi

echo "=== TRUOC ==="
sha256sum "$HOST"
grep -c "CYS-UIEDIT" "$HOST" | sed 's/^/dong CYS-UIEDIT dang co: /'

# 1. module
[ -f "$MODULE_SRC" ] || die "khong thay module nguon: $MODULE_SRC"
luac -p "$MODULE_SRC" || die "module nguon sai cu phap"
mkdir -p "$(dirname "$MODULE_DST")"
cp "$MODULE_SRC" "$MODULE_DST" || die "khong chep duoc module"
luac -p "$MODULE_DST" || die "module sau khi chep sai cu phap"
echo "module: OK -> $MODULE_DST"

# 2. NPC chu — chi them MOT dong, va chi khi chua co
if grep -q "CYS-UIEDIT" "$HOST"; then
    echo "NPC chu DA co dong CYS-UIEDIT, khong them lan nua"
else
    mkdir -p "$BAK"
    cp -p "$HOST" "$BAK/odali_zhongzhipai1.lua.bak" || die "khong sao luu duoc"
    echo "da sao luu -> $BAK/odali_zhongzhipai1.lua.bak"
    grep -qF "$ANCHOR" "$HOST" || die "khong tim thay neo de chen (script da doi?)"
    TMP=$(mktemp)
    awk -v call="$CALL" -v anchor="$ANCHOR" '
        { print }
        index($0, anchor) { print call }
    ' "$HOST" > "$TMP" || die "awk that bai"
    # Soat cu phap TRUOC khi ghi de — day la buoc quan trong nhat cua tep nay.
    luac -p "$TMP" || { rm -f "$TMP"; die "ban va lam sai cu phap, DA KHONG ghi de"; }
    n=$(grep -c "CYS-UIEDIT" "$TMP")
    [ "$n" = "1" ] || { rm -f "$TMP"; die "chen $n dong, mong doi dung 1"; }
    cp "$TMP" "$HOST" || { rm -f "$TMP"; die "khong ghi duoc"; }
    rm -f "$TMP"
    echo "NPC chu: da chen 1 dong"
fi

echo "=== SAU ==="
sha256sum "$HOST" "$MODULE_DST"
luac -p "$HOST" && echo "cu phap NPC chu: DAT"
grep -n "CYS-UIEDIT" "$HOST"
echo
echo "XONG. KHONG can restart server (Game_2/Script/** nap luoi qua try_load)."
echo "Go ra: bash $0 --go-ra"
