"""Restore the sixteen test accounts in a private play stage; caller holds game slot."""
import argparse
import datetime
import json
from pathlib import Path
import re
import shutil
from stage_wsl_test import ROOT, PROFILE_FILE, game_running, load_stage, sha


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--stage', required=True)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    stage, manifest_path, manifest = load_stage(args.stage)
    assert stage.parent == (ROOT / 'Build/world-gui').resolve()
    assert stage.name.startswith('stage-play-'), 'Measurement stages keep their own account isolation'
    assert not game_running(stage), 'Close this stage before changing its profile'
    record = manifest['wsl_test']
    assert record['profile'] == 'cys-server'
    profile = stage / PROFILE_FILE
    before = profile.read_bytes()
    rows = [row for row in record['created'] if row['path'] == PROFILE_FILE]
    assert len(rows) == 1 and rows[0]['sha256'] == sha(before), 'Profile differs from its manifest'
    accounts = ['test%02d' % i for i in range(16)]
    pattern = rb'(?m)^accounts=[^\r\n]*(?:\r?\n|$)'
    assert len(re.findall(pattern, before)) <= 1
    line = ('accounts=' + ','.join(accounts) + '\r\n').encode('ascii')
    after = re.sub(pattern, lambda _: line, before) if re.search(pattern, before) else before.rstrip(b'\r\n') + b'\r\n' + line
    result = dict(stage=str(stage),before_accounts=record['accounts'],accounts=accounts,changed=after != before)
    # The login UI appends these five non-secret preferences on its first exit.
    # Accept only an exact recorded config prefix plus that known suffix; never
    # rebaseline an arbitrary config mismatch to make the stage gate pass.
    cfg = stage / 'Bin64/WXSystem.cfg'
    cfg_bytes = cfg.read_bytes()
    cfg_row = next(row for row in record['files'] if row['path'] == 'Bin64/WXSystem.cfg')
    preferences = {}
    if sha(cfg_bytes) != cfg_row['sha256_after']:
        keys = ('Account_MailIndex_AlterFlag','Login_Area','Login_Server','Account_LogonType','Account_MailIndex')
        first = re.search(rb'(?m)^(?:' + '|'.join(keys).encode('ascii') + rb')=', cfg_bytes)
        assert first and sha(cfg_bytes[:first.start()]) == cfg_row['sha256_after'], 'Unrelated WXSystem config drift'
        for saved in cfg_bytes[first.start():].splitlines():
            match = re.fullmatch(rb'([A-Za-z_]+)=([0-9]+)', saved)
            assert match and match[1].decode('ascii') in keys, 'Unknown saved preference'
            key = match[1].decode('ascii')
            assert key not in preferences, 'Duplicate saved preference'
            preferences[key] = int(match[2])
        assert set(preferences) == set(keys)
    result['accepted_login_preferences'] = preferences
    if args.apply and (after != before or record['accounts'] != accounts or preferences):
        stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
        backup = ROOT / 'Build/backups/play-account-filter' / stamp
        backup.mkdir(parents=True, exist_ok=False)
        shutil.copy2(profile, backup / profile.name)
        shutil.copy2(manifest_path, backup / manifest_path.name)
        shutil.copy2(cfg, backup / cfg.name)
        profile.write_bytes(after)
        record['accounts'] = accounts
        rows[0].update(sha256=sha(after), bytes=len(after))
        if preferences:
            cfg_row.update(sha256_after=sha(cfg_bytes), bytes=len(cfg_bytes))
        result.update(backup=str(backup),at=stamp)
        manifest['play_test_accounts_update'] = result
        manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=1)+'\n', encoding='utf8')
        assert profile.read_bytes() == after
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
