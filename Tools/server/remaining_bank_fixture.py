"""Rerun the established bank fixture under this continuation's full backup."""
import runpy,sys
from pathlib import Path
from bson import json_util
import hj05_fixture
from remaining_shop_fixture import LOG
from give_item import connected
from cs3b_menpai import provision
assert sys.argv[1:] in (['seed'],['inspect'])
assert not connected()
rt=provision()
if sys.argv[1]=='seed':
    game=next(s for s in rt.role_specs() if s['name']=='Game');assert not rt.owned_processes(game)
    original=(LOG/'shop-char-200016-original.json').read_text()
    with rt.database() as client:assert client.tlbb.character.find_one({'attrib.guid':200016})==json_util.loads(original)
    backup=LOG/'test15-original.json'
    if backup.exists():assert json_util.loads(backup.read_text())==json_util.loads(original)
    else:backup.write_text(original,encoding='utf8')
hj05_fixture.LOG=LOG
runpy.run_path(str(Path(__file__).with_name('hj05_bank_fixture.py')),run_name='__main__')
