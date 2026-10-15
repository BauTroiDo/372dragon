"""Render the complete, evidence-qualified HJ comparison. Writes audit artifacts only."""
from pathlib import Path
import collections, csv, datetime, hashlib, json, subprocess
from audit_hj05_log import ROOT, OUT, SERVER, WS, LINUX, sha

DOC = ROOT/'Docs/specs/hj05-bug-log-audit-20260928_vi.md'
S = 'GameServer/'
GROUPS = {
 'WUHUN': [('Docs/specs/power-systems-20260924_vi.md',''),('Tools/game/power_ui.py','WuhunMagicUp_OnCompoundComfirmedBack'),('Docs/specs/client/wuhun-appearance-fix-20260925_vi.md','')],
 'CHAT': [('Src/Client/CEGUISystem/UIString.cpp','if(strID.substr(0,5) == "_ITEM")'),('Docs/specs/equipment-tooltips-20260924_vi.md','Link vật phẩm trong chat')],
 'EQUIP': [('Docs/specs/equipment-tooltips-20260924_vi.md',''),('Docs/specs/equipcraft-20260924_vi.md',''),(S+'lualib/db/human_attrib.lua','function human_attrib:lingwu_equip_effect_flush()')],
 'PET': [(S+'lualib/pet_attrib.lua','function pet_attrib:item_effect_flush()'),(S+'lualib/db/pet_attrib.lua','function pet_attrib:get_attrib(key)'),('Tools/server/cys_petsoul.lua','function M.can_equip'),('Build/Logs/2026-09-28-hj05-audit/pet_integrity_tests.txt','TOTAL')],
 'PETQUALITY': [(S+'lualib/item.lua','function pet_equip_data:init_from_data'),(S+'lualib/pet_attrib.lua','function pet_attrib:item_effect_flush()'),(S+'lualib/db/pet_attrib.lua','function pet_attrib:item_effect_flush()'),('Build/Logs/2026-09-28-hj05-audit/targeted-probes.txt','OBSERVATION 26/27')],
 'PETLIFE': [(S+'lualib/item.lua','self.pet_equip_unknow_8 = 300'),(S+'lualib/item.lua','function pet_equip_data:init_from_data'),('Tools/server/cys_petsoul.lua','local current=e.pet_equip_unknow_8'),('Build/Logs/2026-09-28-hj05-audit/targeted-probes.txt','73-related')],
 'PETVIEW': [('Src/Client/WXClient/Network/CysPetNet.cpp','if (extra != 0)'),('Src/Client/LuaApiGen/LuaApiGen_Pet.cpp','int LAG_Pet_GetPet_Count_PetBank'),('Build/Logs/2026-09-28-hj05-audit/pet-surface.json','')],
 'SHOP': [(S+'services/scene/scenecore.lua','function scenecore:char_player_shop_buy_item'),(S+'services/scene/scenecore.lua','elseif cis.from_type == packet_def.CGItemSynch.POS.POS_PLAYERSHOPPET'),('Src/Client/WXClient/Network/CysPetNet.cpp','if (extra != 0)')],
 'COMBAT': [('Docs/specs/server/menpai-fix_vi.md',''),(S+'services/scene/skill/combat_core.lua','function combat_core:physical_damage'),('Docs/specs/gameplay/gameplay-completion-20260927_vi.md','Chưa có đo DPS')],
 'MANTUO': [(S+'lualib/define.lua','MATTRIBUTE_MANTUOSHANZHUANG = 16'),(S+'services/scene/skill/condition_delplete_core.lua','local flower = obj_me:get_datura_flower()'),('Docs/specs/server/cs3b-menpai_vi.md','')],
 'TALENT': [('Docs/specs/progression-200-20260924_vi.md','## Thiên phú'),(S+'lualib/talentenginer.lua','self.talent_config = configenginer:get_config("sect_desc")'),(S+'lualib/cy_four_combat/release.lua','assert(c.talents_enabled==false')],
 'QUEST': [('Docs/specs/gameplay/gameplay-completion-20260927_vi.md',''),('Build/Logs/2026-09-28-hj05-audit/test_quest_rewards.txt','Dali reward callbacks'),('Build/Logs/2026-09-28-hj05-audit/test_gameplay_audit.txt','gameplay audit:')],
 'GIFT': [('Docs/specs/client/runtime-polish-20260926_vi.md',''),('Build/Logs/2026-09-28-hj05-audit/test_runtime_gifts.txt','')],
 'SMART': [('Docs/specs/smart-equip-piercing-20260925_vi.md','')],
 'MOVE': [('Docs/specs/gameplay-fixes-20260923_vi.md',''),('Docs/specs/client/runtime-polish-20260926_vi.md',''),('Docs/specs/social-completion-20260928_vi.md','')],
 'CITY': [('Docs/specs/social-completion-20260928_vi.md',''),('Src/Client/LuaApiGen/LuaApiGen_City.cpp','int LAG_City_DoBuilding'),('Src/Client/WXClient/Network/CysGuildWarNet.cpp','void RegisterHost()'),('Game_2/Script/scripts/city0_LevelUp.lua','if type(self.CityIncProgress)'),(S+'lualib/cys_social_city.lua','')],
 'ASSET': [('Docs/specs/client/hj-appearance-import-20260925_vi.md',''),('Registry/hj-appearance-catalog.json','')],
 'TEXT': [('Docs/specs/client/hj-appearance-import-20260925_vi.md','Tên chưa có'),('Docs/specs/gameplay/gameplay-completion-20260927_vi.md','')],
 'CARD': [('Docs/specs/equipment-tooltips-20260924_vi.md','Các tính năng trang bị chuyên biệt')],
 'BUFF': [(S+'lualib/impactenginer.lua','function impactenginer:can_impactA_replace_impactB'),('Build/Logs/2026-09-28-hj05-audit/targeted-probes.txt','OBSERVATION 65')],
 'ELEMENT': [('Docs/specs/gameplay/quest-crafting-xinfa-elements-20260927_vi.md','### Băng, hỏa'),('Build/Logs/2026-09-28-hj05-audit/test_gameplay_audit.txt','gameplay audit:')],
 'EQUIPQUALITY': [(S+'lualib/db/human_attrib.lua','function human_attrib:cal_quality_effect'),(S+'lualib/db/human_attrib.lua','function human_attrib:cal_enhance_effect'),('Build/Logs/2026-09-28-hj05-audit/targeted-probes.txt','OBSERVATION 98')],
 'AOE': [(S+'services/scene/skill/impact_logic/std_impact_101.lua','function std_impact_101:on_damage_target'),(S+'services/scene/obj/monster.lua','sender:on_damage_target(self, damages, skill_id, imp)'),(S+'services/scene/obj/character.lua','function character:impact_on_damage_target'),(S+'lualib/impactenginer.lua','[101] ='),('Build/Logs/2026-09-28-hj05-audit/targeted-probes.txt','OBSERVATION 87')],
 'PVP': [(S+'services/scene/obj/human.lua','function human:is_enemy_human'),(S+'services/scene/ai/human.lua','function human:add_killer_pk_value'),('Build/Logs/2026-09-28-hj05-audit/pvp_integrity_tests.txt','RESULT')],
 'TITLE': [('Docs/specs/settings-friends-titles-20260928_vi.md',''),('Src/Client/WXClient/Network/CysCommunityNet.cpp','int TitleAt(')],
 'RENAME': [('Game_2/Script/scripts/event/huodong/echangeusername.lua','function echangeusername:CallBackChangeUserNameAfter'),(S+'services/scene/scenecore.lua','function scenecore:char_by_name'),(S+'lualib/playermanager_core.lua','function playermanager_core:change_player_name'),('Build/Logs/2026-09-28-hj05-audit/targeted-probes.txt','OBSERVATION 112')],
 'BUYBACK': [(S+'services/scene/obj/human.lua','function human:buy_back'),('Build/Logs/2026-09-28-hj05-audit/targeted-probes.txt','OBSERVATION 121a')],
 'PARTICLE': [('Build/Logs/2026-09-28-social-completion/gui-release-alliance/WXRender.log','Bad particle affector attribute'),('Build/Logs/2026-09-28-social-completion/gui-release-alliance/run.json','"game_sha256"')],
 'BUILD': [('Docs/10-CAU-TRUC-VA-KIEM-TOAN-BUILD_vi.md','### 5.4.')],
 'RUNTIME': [('Build/Logs/2026-09-28-hj05-audit/evidence.json','"game_sha256"'),('Build/Logs/2026-09-28-hj05-audit/server-status.txt','')],
 'SCOPE': [('Build/Logs/2026-09-28-hj05-audit/items.json','')],
}
LABELS={'LOI':'Lỗi đã có bằng chứng','LIEN_QUAN':'Lỗi liên quan, khác mô tả gốc',
 'TIEM_AN':'Lỗi tiềm ẩn trong mã','THIEU':'Chức năng thiếu/chưa hoàn chỉnh',
 'CO_XU_LY':'Có xử lý/kiểm tra đạt trong phạm vi', 'CAN_THU':'Cần kiểm riêng, chưa kết luận','KHAC':'Khác nhánh/thiết kế/bổ sung nội dung'}

def path(rel):return (SERVER if rel.startswith(('GameServer/','Game_2/','configs/')) else ROOT)/rel
def link(p,label=None,line=None):return f'[{label or p.name}](<{p.as_posix()}{":"+str(line) if line else ""}>)'
def reference(rel,needle):
    p=path(rel);assert p.is_file(),p
    lines=p.read_text(encoding='utf-8',errors='replace').splitlines()
    line=next((i for i,s in enumerate(lines,1) if needle in s),None) if needle else None
    assert not needle or line, (rel,needle)
    return link(p,rel,line)
def cell(s):return s.replace('|','\\|').replace('\n',' ')

def main():
    evidence=json.loads((OUT/'evidence.json').read_text(encoding='utf8'))
    # Re-run only changed targeted probes. Other passing suites are not repeated.
    command=['wsl','-d','TLBB','-u','root','--','lua',WS+'/Tools/audit/hj05_probes.lua',LINUX]
    p=subprocess.run(command,capture_output=True,timeout=60)
    output=(p.stdout+p.stderr).decode('utf8','replace');(OUT/'targeted-probes.txt').write_text(output,encoding='utf8')
    assert p.returncode==0,output
    for test in evidence['tests']:
        if test['name']=='targeted-probes':test.update(exit=p.returncode,tail=output.splitlines()[-3:],command=command)
    items=json.loads((OUT/'items.json').read_text(encoding='utf8'))
    rows=list(csv.DictReader((ROOT/'Tools/audit/hj05_assessments.tsv').open(encoding='utf8'),delimiter='\t'))
    assert len(rows)==len(items)==143
    byid={r['id']:r for r in rows};assert len(byid)==143 and set(byid)=={i['key'] for i in items}
    assert all(r['status'] in LABELS and r['evidence'] in GROUPS for r in rows)
    counts=collections.Counter(r['status'] for r in rows)
    gui=ROOT/'Build/Logs/2026-09-28-social-completion/gui-release-alliance'
    run=json.loads((gui/'run.json').read_text(encoding='utf-8-sig'))
    assert run['game_sha256']==evidence['game_sha256']==sha(ROOT/'Build/world-gui/stage-play-21/Bin64/Game.exe')
    particles=[l for l in (gui/'WXRender.log').read_text(encoding='utf8',errors='replace').splitlines() if 'Bad particle affector attribute' in l]
    assert len(particles)==9
    # Preserve only source/report evidence (never configs containing credentials or player documents).
    snapshots=[]
    for rel in sorted({r for group in GROUPS.values() for r,_ in group}):
        p=path(rel)
        if p.suffix not in ('.lua','.cpp','.h','.md'):continue
        dest=OUT/'sources'/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(p.read_bytes())
        snapshots.append(dict(source=str(p),copy=str(dest),sha256=sha(p)))
    impact=(SERVER/'configs/StandardImpact.txt').read_text(encoding='gb18030').splitlines()
    impact_rows=[x.split('\t') for x in impact if len(x.split('\t'))>2 and x.split('\t')[2]=='101']
    collection=next(x for x in (SERVER/'configs/IDCollections.txt').read_text(encoding='gb18030').splitlines() if x.startswith('117\t'))
    evidence.update(assessment_counts=dict(counts),finalized_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
        probe_sha256=sha(ROOT/'Tools/audit/hj05_probes.lua'),assessments_sha256=sha(ROOT/'Tools/audit/hj05_assessments.tsv'),
        source_snapshots=snapshots,particle_evidence=dict(gui_run=str(gui/'run.json'),game_sha256=run['game_sha256'],lines=particles),
        impact101_rows=[dict(id=r[0],name=r[1],params=r[27:36]) for r in impact_rows],collection117=collection)
    (OUT/'evidence.json').write_text(json.dumps(evidence,ensure_ascii=False,indent=2),encoding='utf8')
    lines=['# Đối chiếu HJ 0.5 Hualuo Bug-fix log 3 với CY — 28/09/2026','',
      '**Có lỗi còn tồn tại, đồng thời nhiều mục thuộc tính năng chưa hoàn chỉnh. Không thể coi toàn bộ log HJ là danh sách bản vá có thể chép sang CY.**','',
      f'File gốc có **143 mục**: số 1–140, thêm 27.5 và 94.5, hai mục cùng số 121. Báo cáo giữ thứ tự và gọi hai mục đó là **121a** (ràng buộc vật phẩm), **121b** (tư chất pet trong kho). SHA-256 file: `{evidence["attachment_sha256"]}`.','',
      'Đích đối chiếu là CY-Source/Play21 và server riêng `/home/ubuntu/cys-test-20260913`, không phải server GL chính. Đợt này đọc mã/bảng/log, chạy kiểm tra cô lập và tạo báo cáo; không sửa gameplay, không cấp/xóa vật phẩm, không đổi tài khoản, không restart hay phát hành binary.','',
      f'Game.exe hiện tại: `{evidence["game_sha256"]}`. Sáu dịch vụ riêng hoạt động, không trùng PID; login/game 15733/15734 đang nghe. Trạng thái này không phải chứng minh mọi tính năng hoạt động.','',
      '## Những phát hiện cần xử lý','',
      '| Mục | Phát hiện | Bằng chứng và giới hạn |','|---|---|---|',
      '| **87** | **Nộ Hỏa Liên Trảm đếm theo mục tiêu** | Hàm `on_damage_target` tăng đao mỗi callback; quái gọi callback cho từng mục tiêu trúng. Probe với skill 312 (Huyết Chiến Bát Phương), collection 117/ngưỡng 15: 10 mục tiêu làm đao **5 → 15**, mục tiêu cuối nhận rate 115. Dữ liệu thật có 23 impact dùng logic 101. Đây là tái hiện ở hàm thật với actor/tra cứu collection mô phỏng; chưa chạy AoE trực tiếp trong GUI. |',
      '| **119** | **Particle còn thuộc tính không được nhận** | Log GUI đã có, đúng hash Game hiện tại: **9 dòng** `Bad particle affector attribute` với `MeshAnimationAffector`, `anim_pos1/2/3`. Không phải 3.000 dòng; chưa đo tác động lên hình ảnh/FPS. Đợt audit đọc lại log, không giả là một lượt GUI mới. |',
      '| **112** | **Callback đổi tên có thể trừ thẻ khi báo thất bại** | Chạy hàm thật với kết quả lỗi 1, 2, 3, 4 đều xóa một thẻ trước khi xét kết quả. Đây là **lỗi tiềm ẩn**: caller `char_by_name` hiện chỉ gọi callback After với 0 và từ chối tên trùng trước đó. Chưa chứng minh một lần đổi tên thất bại từ UI đã mất thẻ. |',
      '| Liên quan **25–26** | **Tư chất trang bị pet chưa góp chỉ số** | Cả `pet_attrib.lua` và `db/pet_attrib.lua` chỉ cộng base/raw attrs. Đổi sáu byte tư chất **0 → 255**, phần cộng base vẫn **100 → 100**. Loader giữ tư chất; đây là lỗi tính chỉ số, **khác** lỗi HJ mất dữ liệu/2% sau relog. |',
      '| Phát hiện thêm khi kiểm **73** | **Thọ vật phẩm Thú hồn không được nạp lại** | `copy_raw_data` giữ thọ 420, nhưng `pet_equip_data:init_from_data` bỏ `pet_equip_unknow_8`, constructor đặt lại **300**. Luồng Hồi thọ sử dụng đúng trường này. Khác với tốc độ tụt thọ của pet phụ thể trong mục 73, mục gốc vẫn chưa kết luận. |','',
      f'Nhật ký tái hiện: {link(OUT/"targeted-probes.txt")}. Mã probe: {link(ROOT/"Tools/audit/hj05_probes.lua")}. Các probe cố ý ghi lại hành vi lỗi; việc chúng chạy thành công **không có nghĩa lỗi đã được sửa**.','',
      '## Các hệ còn thiếu cần tách khỏi lỗi HJ','',
      '- **Cửu Châu/trân thú trong shop:** server có `if 0 == 0 then return end` ở nhánh mua pet và rút pet. Client `CysPetNet` bỏ qua extra-view của exchange/stall/shop. Mục 10/123 chưa phải giao dịch hoàn chỉnh; không thể báo “đã đúng tiền/chỗ trống” khi đường giao dịch đang tắt.',
      '- **Kho trân thú:** các host PetBank còn stub; chưa chứng nhận số lượng/tư chất kho (24/121b). Kiểm kê 76 Lua UI cho ra 254 ứng viên stub, chỉ là danh sách điều tra; không gọi chúng là 254 lỗi độc lập vì còn alias/đăng ký đè.',
      '- **Thành bang/thương nhân/nghiên cứu/Trác Lộc:** đã có party/raid/liên minh và ngân phiếu, nhưng các API xây thành, nghiên cứu, shop/tuyến đường, tiến độ quest còn thiếu. Nhiệm vụ thiếu `CityIncProgress` hiện chặn trước tiêu phí. Chưa có nghiệm thu toàn chu kỳ chiến trường/công trạng.',
      '- **Mạn Đà và thiên phú:** Mạn Đà slot 16 đang tắt. CY Tông môn và GL Võ đạo khác schema; còn thiếu UI/mapping cho cây đầy đủ. Không tự áp các ID/hệ số/40+talent mà tác giả HJ nói đã sửa.','',
      '## Các nhánh có xử lý đúng trong phạm vi đã thử','',
      '- Mua lại ở NPC giữ cùng instance/GUID, ràng buộc, cường hóa +9 và tư chất trong probe. Không mở rộng kết quả sang mọi thương hội/đấu giá (121a).',
      '- Pet equipment lưu/nạp được sáu byte tư chất và hai thuộc tính 123/456 trong roundtrip thật; chưa thấy đúng lỗi hook mất dữ liệu của HJ (26/27).',
      '- Trang bị nhân vật thường có tư chất vẫn được cộng khi cường hóa bằng 0: base 100 + tư chất 20 = 120 (98). Thất tinh phải kiểm riêng.',
      '- Buff có mutex priority thấp không đè được priority cao trong hàm thay thế. Từng buff còn phụ thuộc dữ liệu bảng (65).',
      '- Chọn ô nhẫn/hộ phù, tổng xuyên thích, ngoại hình Võ hồn đã có sửa và bằng chứng GUI/relogin từ các đợt trước. Bảng dưới ghi rõ phần nào chỉ là bằng chứng lịch sử.','',
      '## Phạm vi kiểm tra mới','',
      '| Bộ kiểm hiện tại | Kết quả | Phạm vi |','|---|---:|---|',
      '| Pet | 113/113 | Handler/thuộc tính/linh tính với actor mô phỏng, không phải mọi kỹ năng pet live |',
      '| PvP | 83/83 | Luật PvP, công thức và điều kiện arena đã định nghĩa |',
      '| Equipcraft | 54/54 | Luồng Thăng Linh/điêu văn và ranh giới giao dịch |',
      '| Equipment passives | 21/21 | Linh Vũ/Linh bài theo test hiện có |',
      '| Gameplay audit | 978/978 | Handler thật và bảng thật; 494 công thức được khảo sát, 452 tạo được, 42 chặn vì thiếu cấp nghề |',
      '| Quest rewards | 174/174 | Callback Đại Lý và thưởng, không phải toàn bộ 174 chuỗi |',
      '| Lễ hộp | Đạt | Loại mẫu đang test, túi đầy/replay/race/khóa trạng thái |',
      '| Trade/welfare | 37/37 | Ngân phiếu, phúc lợi và chặn nhiệm vụ thành thiếu progress |',
      '| City query | 8/8 | Đọc level/thành đã lưu, không phải tạo thành live |',
      '| Equipment routes | 6/6 | Whitelist + registry + thân hàm |',
      '| Probe HJ chuyên biệt | 9 quan sát | Bao gồm tái hiện lỗi, không tính là 9 chức năng đúng |','',
      'Chín bộ kiểm hồi quy dùng file máy chủ hiện tại, mô phỏng transport/actor/database theo từng bộ. Không sửa fixture Mongo. Chưa chạy soak test THDC4 một giờ; chưa chơi hết Q70, Sát Tinh, Thanh Khâu, Tào Vận; chưa có ma trận chiến đấu mọi phái/talent. Nhiều mục không có item/skill/scene ID nên chưa thể khẳng định trùng lỗi.','',
      '## Phân loại 143 mục','',
      'Đây là số **mục trong file**, không phải số lỗi độc lập. “Có xử lý” chỉ xác nhận phần được mô tả trong cột nhận định; “cần kiểm riêng” không phải PASS. “Thiếu” cũng không phải khẳng định lỗi gốc HJ đã tái hiện.','',
      '| Trạng thái | Số mục |','|---|---:|']
    for status in LABELS:lines.append(f'| {LABELS[status]} | {counts[status]} |')
    lines += ['', '## Bảng đối chiếu đầy đủ','', '| Mục | Nội dung gốc | Trạng thái | Nhận định CY và nguồn |','|---|---|---|---|']
    for item in items:
        r=byid[item['key']]
        lines.append(f'| {item["key"]} | {cell(item["text"])} | {LABELS[r["status"]]} | {cell(r["assessment"])} [{r["evidence"]}](#{r["evidence"].lower()}) |')
    lines += ['', '## Nguồn để đối chiếu tiếp','',
      'Các nhóm nguồn là điểm vào điều tra và bằng chứng theo phạm vi đã ghi, không phải một test đầy đủ cho mọi dòng tham chiếu chúng. Bản chụp source được giữ cùng SHA trong evidence.json để kết luận không trôi theo những lần sửa sau.','']
    for name,refs in GROUPS.items():
        lines += [f'### {name}','']+[f'- {reference(rel,needle)}' for rel,needle in refs]+['']
    lines += ['## Thứ tự xử lý đề nghị','',
      '1. Sửa lưu/nạp thọ Thú hồn và tính tư chất trang bị pet; kiểm bản ghi cũ, cùng pet trước/sau triệu hồi/map/relogin. Không đổi giá trị thọ đã lưu bằng migration khi chưa cần.',
      '2. Sửa Nộ Hỏa Liên Trảm theo một lần thi triển, giữ đúng tương tác nhiều đợt hit; thử một mục tiêu/nhiều mục tiêu/miss và đối chiếu công thức gốc. Không chỉ chặn số đao ở client.',
      '3. Sửa callback đổi tên để chỉ tiêu thẻ sau thành công có xác nhận; kiểm tên trùng/lỗi DB/gửi lặp và giữ đồng bộ tên/cache.',
      '4. Bổ sung hỗ trợ đúng semantics `anim_pos1/2/3` bằng nguồn Fairy/CY, đối chiếu hình ảnh. Không xóa cảnh báo để giả hết lỗi.',
      '5. Hoàn thiện từng tuyến kho/thương hội trân thú, thành bang và thiên phú; chưa bật nhánh return/stub bằng cách bỏ guard mà chưa nối đủ giao dịch.', '',
      f'Hồ sơ máy đọc được: {link(OUT/"evidence.json")}. Danh sách gốc đã chuẩn hóa: {link(OUT/"items.json")}. Bảng nhận định nguồn: {link(ROOT/"Tools/audit/hj05_assessments.tsv")}.', '']
    DOC.write_text('\n'.join(lines),encoding='utf8')
    print('WROTE',DOC,'rows',len(rows),'counts',dict(counts),'source snapshots',len(snapshots))

if __name__=='__main__':main()
