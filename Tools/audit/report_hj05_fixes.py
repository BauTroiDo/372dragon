"""Keep the original 143-item audit intact; emit an evidence-scoped update."""
from pathlib import Path
import csv,json,collections
ROOT=Path(__file__).resolve().parents[2]
LOG=ROOT/'Build/Logs/2026-09-28-hj05-fixes'
OUT=ROOT/'Docs/specs/hj05-fixes-20260928_vi.md'
rows=list(csv.DictReader((ROOT/'Tools/audit/hj05_assessments.tsv').open(encoding='utf8'),delimiter='\t'))
release=json.loads((LOG/'release-report.json').read_text(encoding='utf8'))
verify_path=next(p for p in sorted(LOG.glob('verify-*/report.json'),reverse=True)
    if json.loads(p.read_text(encoding='utf8')).get('server_manifest_sha256')==release['server_manifest_sha256'])
verify=json.loads(verify_path.read_text(encoding='utf8'))
assert len(rows)==143 and verify['syntax_pass'] and all(x['exit']==0 for x in verify['tests'])
updates={
 '23':('KIEM_MOT_PHAN','GUI kho + đăng nhập lại giữ nguyên linh tính và tư chất. Đã sửa hiển thị thế hệ 100–110 thành linh tính 0–10 theo CY gốc. Chưa thử nâng linh tính sau rút kho.'),
 '24':('SUA_GUI','Đã nối giao thức 228/757/1706, số lượng và vị trí kho thực, chọn ô thưa 2/7. GUI gửi/rút/đổi chỗ, túi rỗng rồi rút lại, đăng nhập lại đạt; bốn GUID không trùng/mất.'),
 '25':('SUA_HAM','Hai calculator đã cộng tư chất trang bị pet theo PetEquipItemAptRate CY; bonus chỉ tính trên base, không nhân thêm dòng thuộc tính. Ma trận 256 × 6 và làm tròn đạt. Chưa đo mọi vật phẩm trực tiếp trong GUI.'),
 '26':('SUA_HAM','Lưu/nạp sáu byte tư chất vốn đạt; đã sửa thiếu hệ số khi tính chỉ số ở mục 25. Không kết luận tái hiện lỗi hook 2% của HJ.'),
 '73':('KIEM_MOT_PHAN','Sửa lỗi riêng của thọ VẬT PHẨM Thú hồn: loader và hai dạng packet giữ thọ thật, kể cả 0. GCItemInfo hết lỗi nil khi Thú hồn có dưới sáu dòng thuộc tính. GUI Hồi thọ 100→200 tiêu đúng một nguyên liệu, đăng nhập lại vẫn 200. Tốc độ tụt thọ pet phụ thể trong mục gốc chưa nghiệm thu.'),
 '87':('SUA_HAM','Một lần ra chiêu tính một đao, không tăng theo số mục tiêu; giữ token trước fork và theo dõi miss/hit riêng. Công thức cộng 1,5 × tổng 1..số đao trúng theo native CY, áp một lần trên sát thương tổng. Ma trận cô lập đạt, chưa có GUI chiến đấu AoE.'),
 '100':('SUA_HAM','Thêm guard self/nil/môi trường/pet mất chủ cho các nhánh sát khí và chết; kiểm hàm thật đạt. Chưa thử chết và tăng sát khí qua hai client.'),
 '101':('SUA_HAM','Chặn đồng đội hợp lệ trước PERSONAL PK ở instance thường/type1 và liên server/type4; giữ luật world. Kiểm cùng đội/khác đội/solo và 83 ca PvP đạt; chưa trận party PvP live.'),
 '112':('SUA_HAM','Callback lỗi 1/2/3/4 trả về trước khi trừ thẻ; thành công trừ đúng một, tên có * giữ ngoại lệ miễn phí của nguồn. Chưa nghiệm thu toàn bộ giao dịch đổi tên hoặc khả năng tranh chấp giữa các RPC.'),
 '119':('DONOR_BASELINE','Hiệu chỉnh kết luận audit: 9 cảnh báo anim_pos1/2/3 có thật, nhưng source/evidence CY/GL gốc cũng không đăng ký các tham số này. Không tự xóa cảnh báo hay đoán cách áp animation. Chưa chứng minh sai hình/FPS của CY.'),
 '121b':('SUA_GUI','Khung kho nhận dữ liệu pet thật, năm tư chất tách biệt; khung xem bổ sung ngộ tính, linh tính, hội công/hội thủ, cấp mang, tăng trưởng và sửa cột thuộc tính và tư chất bị tráo. GUI kiểm giá trị trong widget + GUID, sau relogin vẫn đúng. Nới khung/tên/nút, sửa mã màu và tên UTF-8.'),
}
for row in rows:
 row['prior_status']=row['status']
 if row['id'] in updates:row['status'],row['assessment']=updates[row['id']]
(LOG/'resolution-ledger.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
counts=collections.Counter(r['status'] for r in rows)
text='''# Sửa lỗi HJ05 trên CY — 28/09/2026

Đã sửa và phát hành các lỗi đã xác định dưới đây. **Chưa đóng toàn bộ 143 mục; đây không phải chứng nhận game không còn lỗi.** Bảng theo dõi cuối tài liệu giữ cả phần thiếu tính năng và phần chưa đủ kiểm chứng. Báo cáo audit ban đầu được giữ nguyên làm lịch sử.

## Bản phát hành

'''
text+=f"- Launcher: `Build/world-gui/stage-play-21/Play.cmd`.\n- Game.exe SHA-256: `{release['game_sha256']}`.\n- Server: WSL TLBB `/home/ubuntu/cys-test-20260913`; 15 file runtime khớp manifest. Không sửa server GL chính hoặc tài nguyên tham chiếu.\n- Sao lưu client: `{release['backup']}`. Sao lưu server và lịch sử apply trong `Build/backups/hj05-server` và thư mục log đợt sửa.\n\n"
text+='''## Những thay đổi đã có bằng chứng

- **Nộ Hỏa Liên Trảm (#87):** đếm theo lần thi triển, phân biệt đao thử/đao trúng, không nhân đao theo số mục tiêu AoE. Token được chụp trước tác vụ bất đồng bộ; mục tiêu nhận sát thương chậm giữ hệ số của lần thi triển tương ứng. Công thức và làm tròn đối chiếu native CY. Kiểm hàm thật đạt; chưa chứng nhận trận AoE trực tiếp trong GUI.
- **Tư chất trang bị trân thú (#25–26):** bảng CY có 255 dòng, cộng theo đúng sáu cột và chỉ trên chỉ số cơ bản. Kiểm cả calculator chiến đấu và calculator dùng dữ liệu lưu.
- **Thọ vật phẩm Thú hồn:** nạp/lưu và packet không đặt cứng 300 nữa. Thọ 0 không bị coi là thiếu dữ liệu. Hồi thọ thực tế 100→200, tiêu một nguyên liệu; qua đăng nhập lại vẫn giữ 200. Đây là lỗi riêng, không đồng nhất với tốc độ tụt thọ phụ thể của #73.
- **Thông tin chi tiết Thú hồn:** `GCItemInfo` trước đây phát sinh lỗi nil khi danh sách thuộc tính chưa đủ sáu dòng, dù gói định danh túi và giao diện hồi thọ vẫn chạy. Đã mã hóa dòng chưa có thành loại -1/giá trị 0 giống `get_transfer`, không sửa dữ liệu vật phẩm hoặc sinh thêm thuộc tính. Kiểm payload thật cho danh sách rỗng, thiếu và thưa; GUI cuối không có lỗi mới trong khoảng log máy chủ.
- **Kho trân thú (#24, #121b):** nối danh sách/gửi/rút/đổi chỗ với container máy chủ, giữ vị trí thưa, chuyển cùng object/GUID và kiểm trạng thái khóa/xuất chiến/dung hồn/trao đổi/kho đầy/phiên NPC. Khung chi tiết đọc dữ liệu thật; sửa lựa chọn ô đã trống, tên UTF-8, màu chữ, cột thuộc tính và độ rộng nhãn. Nối `Bank:GetNpcId`: mở từ xa hiện đồng hồ 5 phút, NPC giữ điều kiện khoảng cách và đúng đối tượng; không áp nhầm thời hạn từ xa cho NPC.
- **Linh tính:** native client ở `0x1402bc699` và `0x1402ea02d` xác nhận mã thế hệ 100–110 phải hiện linh tính 0–10. Đã sửa cả Pet và TargetPet, vẫn giữ giá trị thế hệ riêng.
- **Sát khí/đồng đội (#100–101):** guard trường hợp tự chết, môi trường, không còn người gây sát thương, pet mất chủ; đồng đội không trở thành địch vì PERSONAL PK trong instance thường/liên server. Phạm vi đã kiểm là hàm thật và fixture cô lập.
- **Đổi tên (#112):** callback thất bại không tiêu thẻ. Lỗi từng nằm ở callback; chưa có bằng chứng người dùng đã gặp mất thẻ từ UI và chưa coi toàn bộ đổi tên là giao dịch nguyên tử.

## Nguồn và kiểm tra

Nguồn đối chiếu: source server, bảng dữ liệu và Lua/layout được sử dụng trong phiên kiểm thử.

11 bộ kiểm máy chủ đã qua; gồm 9.461 assertion hồi quy HJ05, 68 assertion kho, 113 ca pet, 83 ca PvP, 19 ca impact, 21 ca passive, 978 ca gameplay/chế tác, 47 ca power, 54 ca equipcraft, 174 callback quest và 37 ca trade/phúc lợi. Số assertion không phải số tính năng đã hoàn thiện. 15 file được kiểm cú pháp riêng từng file.

GUI trên cùng binary phát hành:

'''
for r in release['proof']:
 folder=Path(r['folder'])
 text+=f"- Mode {r['mode']}: [{folder.name}](<{(folder/'run.json').as_posix()}>) — marker chức năng kết thúc, không có Lua/packet/crash liên quan, thoát sạch và di chuyển sau đóng khung.\n"
text+=f"\n[Báo cáo 11 bộ kiểm máy chủ](<{verify_path.as_posix()}>).\n"
bank_folder=Path(next(r['folder'] for r in release['proof'] if r['mode']==5))
for suffix,label in [('hj05-bank-main','Ảnh kho và đồng hồ từ xa'),('hj05-bank-inspect','Ảnh khung chi tiết và tư chất')]:
 shot=next(bank_folder.glob('*'+suffix+'.png'))
 text+=f"\n[{label}](<{shot.as_posix()}>).\n"
text+='''
Sau vòng kho, bốn GUID duy nhất nằm đúng hai container, tư chất và linh tính giữ nguyên. Toàn bộ bản ghi BSON gốc của test15 đã được phục hồi và đối chiếu bằng nhau. Nhật ký xác nhận: `fixture-verify.json`, `bank-after.json`.

Các lượt thất bại được giữ nguyên: fixture Thú hồn ban đầu thiếu trường cấp/máu, crash client kho do truyền con trỏ output null, phiên online còn sót sau crash, lỗi chọn ô danh sách đã trống và lượt chạy chỉ world smoke vì cấu hình probe sai. Các lượt `ship-soul` dù GUI đạt vẫn có lỗi GCItemInfo trong server, nên bị loại khỏi nghiệm thu. Chỉ các lượt trong release-report, kèm `server-check.json` không có lỗi mới, được dùng nghiệm thu binary phát hành.

Lưu ý công cụ: máy này có `luac -p` nhiều file bị abort khi ghép chunk; bộ kiểm hiện tại parse từng file và tất cả đạt. `git diff --check` toàn file ActionSystem còn whitespace trong thay đổi tích lũy có trước; không sửa hàng loạt phần ngoài phạm vi để làm xanh kiểm tra.

## Phần còn mở

- Player shop/Cửu Châu mua/rút trân thú chưa có giao dịch hoàn chỉnh.
- Xây thành, nghiên cứu, tuyến thương nhân, tiến độ quest thành và chiến trường Trác Lộc còn thiếu các luồng riêng.
- Mạn Đà và cây thiên phú CY/GL còn cần thống nhất dữ liệu/schema; chưa tự bật phái hoặc chép các hệ số 40/75 từ HJ.
- Chưa có nghiệm thu mọi item/skill/boss mà log không nêu ID; chưa chơi toàn bộ Q70, Sát Tinh, Thanh Khâu và Tào Vận; chưa chạy THDC4 một giờ.
- #119: CY/GL donor cũng từ chối `anim_pos1/2/3`; cần chứng minh tác động hình ảnh trước khi thay semantics. Giữ cảnh báo, không che log để tính là đã sửa.
- Khi nạp cảnh vẫn còn lỗi dữ liệu `MONSTER_CFG_FAIL` có trước đợt sửa, ví dụ type 49288 ở scene 13 đã xuất hiện trong log 06:24:39 cùng ngày. Kết quả log không có lỗi mới ở bốn khoảng thử GUI không có nghĩa toàn bộ log khởi động đã sạch.

## Tái tạo và chống ghi đè

`Tools/server/hj05_fixes.py` tạo lớp tích hợp từ baseline và kiểm hash trước apply, backup trước ghi; **áp sau các generator server cũ** vì chúng có thể sinh lại logic 101/item/AI từ baseline cũ. Không chạy generator cũ đè trực tiếp lên bản đã sửa. `Tools/server/hj05_verify.py` phát hiện lệch hash và chạy hồi quy.

Client build bằng wrapper hiện tại, stage qua `Tools/game/stage_hj05.py`; overlay sinh từ `Tools/game/hj05_ui.py` với nguồn UI baseline được giữ riêng, không nhân kích thước lại khi chạy lần hai. `Tools/game/publish_hj05.py` yêu cầu bốn lượt GUI đúng binary/manifest, kiểm runtime, kiểm phục hồi BSON và backup trước publish. Không dùng Play như thư mục thử nghiệm.

## Theo dõi đủ 143 mục

Trạng thái `SUA_HAM` chỉ xác nhận phạm vi kiểm hàm; `SUA_GUI` có luồng GUI và lưu/nạp đã nêu; `KIEM_MOT_PHAN` còn điều kiện gốc chưa thử. `CO_XU_LY` là bằng chứng đã có trong audit ban đầu, không phải vừa kiểm toàn bộ lại. `CAN_THU`, `THIEU`, `KHAC`, `DONOR_BASELINE` giữ giới hạn rõ ràng.

'''
text+='Phân bố hiện tại: '+', '.join(f'{k}={v}' for k,v in sorted(counts.items()))+'.\n\n'
text+='| Mục HJ | Trạng thái | Kết quả / giới hạn |\n|---|---|---|\n'
for r in rows:text+=f"| {r['id']} | {r['status']} | {r['assessment'].replace('|','/')} |\n"
OUT.write_text(text,encoding='utf8');print(OUT);print(dict(counts))
