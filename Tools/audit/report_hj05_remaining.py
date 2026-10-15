"""Extend, rather than erase, the complete HJ05 resolution ledger after publication."""
from pathlib import Path
import collections,json
ROOT=Path(__file__).resolve().parents[2]
LOG=ROOT/'Build/Logs/2026-09-28-hj05-remaining'
OLD=ROOT/'Build/Logs/2026-09-28-hj05-fixes'
release=json.loads((LOG/'release-report.json').read_text(encoding='utf8'))
verify=json.loads(Path(release['verification']).read_text(encoding='utf8'))
assert verify['passed'] and len(release['proof'])==7
stall=ROOT/'Build/Logs/2026-09-28-hj05-stall'
current_verify=max(p for p in LOG.glob('verify-*/report.json') if json.loads(p.read_text()).get('stall_manifest_sha256'))
assert json.loads(current_verify.read_text())['passed'] and (stall/'applied.json').exists()
assert json.loads((LOG/'shop-verify.json').read_text())['full_bson_equal']
assert json.loads((LOG/'soul-verify.json').read_text())['full_bson_equal']
stopwatch_path=LOG/'stopwatch/release-report.json'
stopwatch=json.loads(stopwatch_path.read_text()) if stopwatch_path.exists() else None
cangjingge=ROOT/'Build/Logs/2026-09-28-hj05-cangjingge'
rows=json.loads((OLD/'resolution-ledger.json').read_text(encoding='utf8'));assert len(rows)==143
updates={
 '10':('SUA_GUI','Đã nối tiệm trân thú thật: gửi/rút bằng container pet, tìm ô trống thực, giữ GUID và tư chất. GUI chủ tiệm gửi→rút→gửi→đăng bán, người khác xem/mua và đăng nhập lại đạt. Kho đầy/quyền/serial/yêu cầu lặp được kiểm hàm; chưa kiểm mọi loại trân thú bằng GUI.'),
 '62':('SUA_GUI','Tẩy Thú hồn theo CY: loại thuộc tính duy nhất, khóa loại giữ dòng hợp lệ kể cả dòng cuối của phẩm có 4/5 thuộc tính; chỉ số vẫn được tẩy lại. Vật phẩm khóa màu bảo đảm đúng số dòng bậc cao theo nguồn. GUI khóa dòng 5, dùng khóa màu, xem trước→nhận→đăng nhập lại; phí/nguyên liệu/GUID đúng. Không áp yêu cầu dòng trùng của HJ.'),
 '123':('KIEM_MOT_PHAN','Đính chính audit: bày bán Stall khác tiệm PlayerShop. Hàm char_stall_buy hiện đã cộng Nguyên Bảo cho người bán pet nếu quầy là KNB; 26 kiểm hàm thật xác nhận tiền, GUID và yêu cầu lặp. Đã sửa riêng lỗi định dạng nhật ký nhánh Võ Thạch sau thanh toán. Client Stall chưa nối đầy đủ, chưa có GUI hai người; không dùng kiểm tiệm Võ Thạch để đóng mục KNB.'),
}
for r in rows:
 if r['id'] in updates:
  r['previous_release_status']=r['status'];r['status'],r['assessment']=updates[r['id']]
(LOG/'resolution-ledger.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
counts=collections.Counter(r['status'] for r in rows)
text='''# HJ05 — tiệm trân thú và tẩy Thú hồn, tiếp nối 28/09/2026

Đã phát hành phần sửa dưới đây vào Play. **Toàn bộ 143 mục vẫn được theo dõi; còn các tính năng thiếu và các ca chưa nghiệm thu, không ghi tất cả đã hoàn tất.** Báo cáo phát hành trước và các lượt thử thất bại được giữ nguyên.

## Bản chạy

'''
text+=f"- Launcher: [Play.cmd](<{(ROOT/'Build/world-gui/stage-play-21/Play.cmd').as_posix()}>).\n- Game.exe SHA-256: `{release['game_sha256']}`.\n- Sao lưu client: `{release['backup']}`.\n- Máy chủ CY riêng: `/home/ubuntu/cys-test-20260913`; {verify['runtime_hashes_match']} file tích lũy khớp manifest.\n- [Hồ sơ phát hành](<{(LOG/'release-report.json').as_posix()}>), [hồi quy máy chủ hiện hành](<{current_verify.as_posix()}>).\n\n"
if stopwatch:
 text+=f"Bổ sung DLL CEGUIFalagard build từ source để sửa đồng hồ: `{stopwatch['dll_sha256']}`. Game.exe, các DLL khác và overlay giữ nguyên. [Hồ sơ đồng hồ](<{stopwatch_path.as_posix()}>).\n\n"
text+='''## Tiệm trân thú

- Dùng container pet đúng loại, giữ object/GUID, kỹ năng, trang bị và tư chất khi gửi, lấy về hoặc mua. Kiểm quyền chủ/đối tác, trạng thái quầy, số phiên, giá, túi đầy và yêu cầu lặp trước thay đổi.
- Sửa đọc/lưu quầy có khóa số hoặc chuỗi, trạng thái bán dạng boolean/số, số phiên và cờ dữ liệu thay đổi. Lưu shop dùng API thật; thay đổi đến trong lúc chờ lưu không bị mất cờ cần lưu.
- Nối gói danh sách/chi tiết/gửi/rút/đăng bán/mua của CY, phân biệt gói chủ tiệm và người mua. Khung xem trân thú đọc dữ liệu của đúng GUID, không trộn vào trân thú người chơi.
- Nối quyền chủ tiệm và mã loại tiệm theo Lua CY, nới bố cục quản lý, tên/ID chủ, doanh thu, giá bán, hàng quầy và các nút. Giữ skin có sẵn.
- Sửa sự kiện chọn trong kho dùng nhầm sự kiện mở khung Trân thú. Danh sách ẩn cập nhật sau khi rút trân thú ở tiệm không còn tự bật khung Pet.

Giao dịch GUI đã kiểm: người mua có 10000→9500 Võ Thạch hạ phẩm, tiệm có doanh thu 490 sau phí 2%, người bán giữ 10000; một GUID pet chuyển sang người mua đúng một lần, tư chất 1234 không đổi. Bấm mua lặp không nhân pet. Đăng nhập lại và dữ liệu Mongo xác nhận cùng kết quả.

Phần bày bán **Stall** là luồng khác. Kiểm hàm thật xác nhận nhánh trân thú KNB đã trả đúng KNB, nên hiệu chỉnh nhận định audit trước đó. Ca Võ Thạch tái hiện lỗi Lua 5.3 `%d` nhận số lẻ khi ghi nhật ký, sau khi pet và tiền đã chuyển. Bản sửa riêng `hj05_stall_format.py` lấy phần nguyên đúng ba mệnh giá 10000/100/1 và dùng nhãn Võ Thạch. 26 kiểm tiền, GUID và replay qua sau sửa. Đây là kiểm hàm máy chủ, chưa là nghiệm thu GUI Stall hai người.

## Thú hồn

- Đối chiếu script Vân Thâm Thâm, bảng PetSoulExtension và màu TIPS native GL/CY trước sửa. Không sao chép luật cho phép dòng trùng của HJ.
- Khóa loại dùng sáu chữ số theo dòng; phẩm 0/1/2–3 có 4/5/6 dòng. Tạo đúng số dòng rồi mới sắp xếp, tránh mất loại đã khóa ở cuối khi cắt danh sách.
- Không tạo hai thuộc tính cùng loại. Kiểm mask, dòng trống/ẩn, cấu hình và vật phẩm khóa màu trước thu phí. Vật phẩm khóa màu dùng điều kiện phẩm và số dòng bảo đảm từ nguồn; không mua nguyên liệu tự động.
- Phí tẩy 50000 Võ Thạch hạ phẩm; nguyên liệu theo số dòng khóa: 0→1, 1–2→2, 3–4→3, 5→4, 6→5. Một lượt có khóa màu tiêu thêm một vật phẩm phù hợp. Giữ bộ đếm nguyên liệu và luật khóa vật phẩm sau tiêu nguyên liệu khóa.
- Khóa loại giữ **loại**, trị số được tẩy lại. Kết quả tẩy nằm ở cột xem trước cho đến khi Nhận kết quả. Loại/giá trị trong tooltip và khung dùng bậc màu của từng thuộc tính, không dùng chung màu phẩm vật phẩm.
- Từng thuộc tính và nút khóa có hàng riêng; nội dung dài xuống dòng không làm lệch nút khóa. Dòng không tồn tại không có nút khóa.

GUI đã kiểm phẩm 1, khóa dòng thứ năm có loại 22, dùng khóa màu, tẩy, xem trước chưa đổi thuộc tính cũ, nhận kết quả và đăng nhập lại. GUID giữ nguyên, năm loại duy nhất, dòng thứ sáu rỗng, hai nguyên liệu tẩy và một khóa màu bị tiêu, tiền 100000→50000. Phẩm khác và các biên được kiểm bằng hàm thật; không nói đã bấm mọi phẩm trong GUI.

## Kiểm chứng

8 bộ hồi quy máy chủ qua sau bản sửa Stall: 112 assertion shop, 1891 Thú hồn, 62 power, 9461 hồi quy HJ05, 68 kho, 113 pet, 37 thương nhân/phúc lợi và 26 tiền tệ Stall. Đây là số assertion, không phải số tính năng hoàn tất. 22 file runtime tích lũy được kiểm cú pháp riêng từng file.

Các phiên GUI dùng cùng Game.exe. Sau ba phiên shop, chỉ bốn overlay Lua/layout Thú hồn được đổi để sửa hàng chữ dài. Manifest trước/sau được giữ; công cụ publish kiểm mọi thành phần của shop không đổi. Hai phiên Thú hồn và hai phiên kho dùng manifest cuối. Không lấy nhật ký của binary cũ làm bằng chứng.

'''
for r in release['proof']:
 f=Path(r['folder']);text+=f"- `{r['case']}`: [{f.name}](<{(f/'run.json').as_posix()}>) — marker chức năng hoàn tất, không lỗi Lua/handler/server mới, thoát sạch và di chuyển sau đóng UI.\n"
if stopwatch:
 f=Path(stopwatch['gui'])
 text+=f"\nĐồng hồ dùng cùng dấu thời gian cho giờ/phút/giây; sửa hiện `4:60` khi giá trị thật là `4:59`. [Phiên GUI bổ sung](<{(f/'run.json').as_posix()}>) kiểm đồng hồ, gửi/rút kho, di chuyển và thoát. Ảnh được đọc trực tiếp, giây nằm trong 0–59. Phiên đầu `stopwatch/gui` đạt phía client nhưng kiểm log máy chủ kéo dài qua 23:00 gặp lỗi Tàng Kinh Các có trước; giữ nguyên kết quả server **không đạt**, không dùng phiên này làm điều kiện publish. Phiên nghiệm thu mới có biên log riêng và không lỗi máy chủ trong khoảng thử.\n"
 health=LOG/'stopwatch/health.json';boot=LOG/'stopwatch/boot-log-summary.json'
 if health.exists() and boot.exists():
  h=json.loads(health.read_text());b=json.loads(boot.read_text())
  assert all(s['running'] and not s['duplicate'] for s in h['services'])
  assert h['ports']['15733'] and h['ports']['15734'] and b['tracebacks']==0
  text+=f"\nKiểm cụm sau lần phục hồi cuối lúc `{b['at']}`: sáu dịch vụ chạy, không trùng tiến trình, hai cổng game/login sẵn sàng. [Trạng thái cuối](<{health.as_posix()}>), [log khởi động cuối](<{boot.as_posix()}>). Vẫn ghi nhận năm monster thiếu dữ liệu 49285–49289; không tính chúng là đã sửa.\n"
text+='''
Đã phục hồi toàn bộ BSON hai tài khoản test14/test15 và xóa đúng tiệm fixture, rồi khởi động lại cụm riêng và đối chiếu toàn bản ghi. Không chỉ đặt lại tiền hoặc túi. Bốn pet của ca kho giữ GUID duy nhất, đúng container, tư chất và linh tính sau đăng nhập lại. Cụm riêng có đủ sáu dịch vụ, không trùng tiến trình, cổng 15733/15734 sẵn sàng. Log khởi động không có traceback; còn năm lỗi dữ liệu monster 49285–49289 trong scene 9/13/15 đã có trước, được ghi riêng trong `boot-log-summary.json`.

Các lượt lỗi ban đầu vẫn còn trong thư mục log: nhầm collection shop, thiếu API tên pet, con trỏ output null khi giải mã, chỉ số tiệm chưa nối, khung Pet bị mở do trùng sự kiện và nhãn bị cắt. Chỉ các phiên trong hồ sơ phát hành được nghiệm thu. Cảnh báo tài nguyên/baseline có trước vẫn được giữ.

## Giới hạn còn lại

- Bày bán Stall (#123) khác PlayerShop: nhánh pet KNB đã cộng đúng KNB và lỗi nhật ký Võ Thạch đã sửa, nhưng client Stall chưa nối đầy đủ và chưa nghiệm thu GUI hai người. Đối tác/chuyển nhượng và toàn bộ tiệm vật phẩm chưa nghiệm thu. Giao dịch PlayerShop trong scene không nhường luồng ở đoạn đổi tài sản; chưa có cam kết nguyên tử qua nhiều collection khi tiến trình/máy mất điện giữa các lần lưu.
- Xây thành, nghiên cứu, tuyến thương nhân, nhiệm vụ thành và chiến trường Trác Lộc còn các luồng riêng chưa hoàn thiện.
- Mạn Đà và cây thiên phú CY/GL còn khác dữ liệu/schema. Chưa tự bật phái hoặc chép hệ số của HJ.
- Chưa kiểm mọi item/skill/boss không có ID, toàn bộ Q70/Sát Tinh/Thanh Khâu/Tào Vận, hoặc THDC4 một giờ.
- Particle `anim_pos1/2/3` (#119) vẫn cần chứng minh ảnh hưởng; không xóa cảnh báo để coi là đã sửa.
- Tàng Kinh Các: lịch 23:00 gọi ID 13565 không có, sau đó dùng object không hợp lệ. Đã mở rộng kiểm tra toàn họ 13565–13600: thiếu cả 36 ID trong server và client CY. Chín cấp NPC cùng tên có bản CY 549, nhưng ba họ quái tấn công không có bản trùng tên. Chỉ đổi NPC đầu vào chưa thể sửa phụ bản, nên chưa thay runtime và chưa đánh dấu hoạt động hoàn tất. Bằng chứng chỉ đọc ở `Build/Logs/2026-09-28-hj05-cangjingge/summary.json` và `ids.json`.

## Tái tạo

`Tools/server/hj05_remaining.py plan/apply` tích hợp từ baseline đã lưu, kiểm hash và backup trước ghi. Áp sau lớp HJ05 trước đó; không chạy generator cũ ghi đè nguồn hiện hành. `Tools/server/remaining_verify.py` đối chiếu manifest tích lũy và chạy hồi quy.

`Tools/server/hj05_stall_format.py` là lớp cuối sau `hj05_remaining.py`, yêu cầu dừng Game riêng khi apply. Bản phát hành client được kiểm với server trước lớp Stall; sau đó chỉ hàm ghi thông báo Stall thay đổi, giữ nguyên Game/overlay và các hàm shop/Thú hồn/kho. Hồi quy tích lũy sau khởi động xác nhận cả hai lớp. Manifest và backup Stall nằm trong `Build/Logs/2026-09-28-hj05-stall`.

Client dùng build wrapper, `Tools/game/stage_hj05_remaining.py`, `remaining_ui.py` và `remaining_shop_ui.py`. `publish_hj05_remaining.py` kiểm bản Play ban đầu chưa đổi, binary/PDB mới nhất, các phiên GUI và server, dữ liệu lưu–nạp và phục hồi fixture trước sao lưu/publish. Không thêm DLL hook/inject trong đợt này.

`Tools/game/deploy_stopwatch.py` là lớp client cuối, chỉ thay DLL/PDB CEGUIFalagard đã build từ `Src/Client/CEGUIFalagardEx/FalStopWatch.cpp`. Công cụ kiểm Game/overlay không đổi, manifest đúng phiên GUI, biên log server, ảnh đồng hồ và full BSON phục hồi trước publish. `Tools/audit/cangjingge_ids.py` chỉ đọc dữ liệu CY/GL và ghi báo cáo; không sửa bảng hay script runtime.

## Sổ theo dõi 143 mục

`SUA_GUI` xác nhận đúng phạm vi ghi trong hàng; `SUA_HAM` là kiểm hàm; `KIEM_MOT_PHAN` còn điều kiện gốc chưa nghiệm thu. Không đồng nhất các trạng thái này với game không còn lỗi.

'''
text+='Phân bố: '+', '.join(f'{k}={v}' for k,v in sorted(counts.items()))+'.\n\n'
text+=f'[Hồi quy runtime hiện tại](<{current_verify.as_posix()}>).\n\n'
text+='| Mục | Trạng thái | Bằng chứng / giới hạn |\n|---|---|---|\n'
for r in rows:text+=f"| {r['id']} | {r['status']} | {r['assessment'].replace('|','/')} |\n"
out=ROOT/'Docs/specs/hj05-remaining-20260928_vi.md';out.write_text(text,encoding='utf8')
print(out);print(dict(counts))
