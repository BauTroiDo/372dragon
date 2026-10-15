# Bộ sửa bố cục UI trong game (`CYS-UIEDIT`)

Tự vào game, mở khung lên, kéo cho vừa ý, bấm lưu. Lần sau mở lại vẫn y như vậy.

Hướng này **ngược** với cách cũ của mảng `ui-fit`: cách cũ **rút ngắn bản dịch** cho vừa khung
(5.700 → 262 chỗ, và một lần rút ẩu đã xoá nhầm thẻ `#{_INFOMAP…}`). Ở đây **giữ nguyên bản dịch,
sửa khung**.

---

## 1. Bật lên

Bộ sửa **mặc định TẮT**.

**Tắt thì nó làm gì — đã ĐO, không còn là suy luận** (`ui-editor-2`, 20/09, ba lượt live trên cùng
một binary, `Build\Logs\2026-09-20-ui-editor-2\`):

| | lượt TẮT (không đặt biến nào) | lượt BẬT |
|---|---:|---:|
| dòng `CYS-UIEDIT: BAT` | **0** | 1 |
| dòng `che do sua BAT` | **0** | 1 |
| đọc danh sách khung hỏng | **0** | 1 (56 mục) |
| `SetMode(1)` (bật chế độ sửa) | **bị từ chối, `rc=0`** | `rc=1` |
| bộ kiểm live | **20/20 PASS** | 20/20 PASS |
| minidump | **0** | 0 |

**Một khoản KHÔNG bằng không, nói thẳng:** lượt tắt vẫn có **đúng một** dòng
`CYS-UIEDIT: doc 0 dong de tu file`. `ApplyTo` **cố ý** chạy kể cả khi chưa bật — vì kết quả kéo tay
là **SẢN PHẨM**, còn bộ sửa mới là **CÔNG CỤ**. Nhờ vậy bạn kéo xong, lưu, rồi chơi bình thường
**không cần bật gì**: đã đo ở lượt thứ ba — công tắc TẮT, `SetMode(1)` bị **từ chối** (`rc=0`), kéo và
lưu đều trơ, nhưng ô vẫn rộng **189,0 px** đúng như đã kéo.

Bật bằng biến môi trường trước khi chạy `Game.exe`:

```powershell
$env:CYS_UIEDIT = '1'
& 'C:\TLBB\085\CY-Source\Build\world-gui\stage-uiedit\Bin64\Run-CY-Server.cmd'
```

`stage-uiedit` là bản **đã nghiệm thu**: ba lượt live 20/20 PASS trong ngày 20/09, 0 minidump, và
chính là binary mà bảng số ở trên đo được (`game_sha256 7faa7b48…`).

**Một cảnh báo cho bản này:** nó **chưa có** bản vá NULL ở mục 5, nên `PgDn` tới khung `Synthesize`
(mục số 7 trong danh sách) sẽ làm **văng game**. Cứ bấm `PgDn` tiếp để đi qua, hoặc dùng một stage
dựng sau khi bản vá vào `main` — bản đó có cả bản vá lẫn móc `@UIEDIT:` cho NPC.

Biến được đọc **một lần rồi nhớ luôn** (giống `CysSmokePhysicalMouseAllowed`), nên **đặt sau khi
game đã chạy là vô tác dụng**. Muốn biết nó có bật thật không thì tìm dòng này trong
`Bin64\UISystem.log`:

```
CYS-UIEDIT: BAT (CYS_UIEDIT=1), file de = ...\Data\InterfaceFolder\CysUiEdit\ui_layout_overrides.tsv
```

## 2. Dùng

| Phím / thao tác | Việc |
|---|---|
| `F11` | bật/tắt chế độ sửa (chỉ có tác dụng khi đã bật ở mục 1) |
| `Ctrl` + bấm trái | chọn widget ngay dưới con trỏ |
| kéo trong widget đang chọn | di chuyển |
| `Shift` + kéo | co giãn (góc phải–dưới) |
| mũi tên | dịch 1 px · `Shift`+mũi tên: 10 px |
| `Ctrl` + mũi tên | co giãn 1 px · thêm `Shift`: 10 px |
| `Delete` | trả widget đang chọn về kích thước gốc của layout |
| `PgDn` / `PgUp` | mở **khung kế tiếp / trước đó** trong danh sách 56 khung và chọn sẵn widget tràn |
| `Ctrl` + `S` | **LƯU** |

Dòng trạng thái trên cùng màn hình cho biết đang chọn widget nào, ô bao nhiêu px, và bao nhiêu dòng
đang chờ lưu.

`PgDn`/`PgUp` là phần trả lời yêu cầu *"cần một NPC để mở các khung còn lỗi"*: nó mở được cả những
khung **không có đường mở bình thường**. Xem mục 5 để biết vì sao và NPC thật đang ở đâu.

---

## 2b. ĐỪNG DÒ 348 KHUNG — đây là chỗ đáng kéo

Ba nhánh đo 19–20/09 đã **thu hẹp** bức tranh tràn khung. Hai điều cần biết trước khi kéo:

- **62 khung "hỏng chắc chắn"** mà `ui-frames` đếm được **KHÔNG có khung nào là tràn bố cục** —
  100 % là *giá trị chưa bao giờ được điền*, tức **mã chết**. Công cụ này **không cứu được khung
  nào trong số đó** (`Timeline/handoff/ui-frames.md:352-356, 426-427`). Đừng phí công vào chúng.
- **293 nhãn** đã hiện đủ chữ nhờ `i18n-scope` ghi đè theo cặp (khoá, khung), **0 chỗ tràn mới**,
  và **không đổi một byte hình học nào**. Việc đó sửa bằng DỊCH, không phải bằng kéo.

Còn lại mới là việc của công cụ này. `PgDn` đi theo thứ tự ưu tiên sau:

| thứ tự | nhóm | vì sao đáng |
|---|---|---|
| 1–9 | **9 widget lớp DBC** | chín ô này gánh **toàn bộ** 9.996 giá trị tràn của lớp DBC; riêng ba ô đầu (`ActionSkill_Name`, `CommonSkill_Target_Skill_Name`, `ActionSkillsStudy_SkillName`) là **8.939 = 89,4 %**. Kéo ba ô sửa gần chín nghìn dòng |
| 10–12 | **hàng 17 thẻ của `SelfEquip`** | **mọi ô rộng đúng 35 px**; 15/17 thẻ không đủ chỗ nên đang phải hiện chữ viết tắt `CN`/`TL`/`BK`. Nặng nhất: "Chân Nguyên" cần **72,7 px** trong ô 35. Widget mẫu này được chép sang **46 khung** |
| 13–16 | **4 ô ở `SeventhFestivalTopList` / `ValentineRoseTopList`** | năm dòng dịch cuối của `i18n-scope`; cần **+24…+51 px**. Không nới thì không có cách nào khác |
| 17–56 | 40 khung lớp layout | xếp theo số widget tràn |

Nhóm 10–16 nằm trong `data/ui_edit_targets_pinned.tsv` và được `make_edit_targets.py --pin` chèn lại
**mỗi lần sinh danh sách**. Không ghim thì lần sinh lại sau sẽ làm mất chúng, im lặng — cùng lớp mất
dữ liệu đã phải trả giá bằng 242 dòng DBC.

### Đừng nhắm "vừa khít"

Tên kỹ năng dài nhất cần thêm **641 px** cho `ActionSkill_Name` (ô hiện 154,8) — rộng hơn cả khung cha.
Nới hết cũng chỉ xuống 1.057 chỗ tràn. Bảng đổi chác:

| nới thêm (cả ba ô) | còn tràn | giảm |
|---:|---:|---:|
| +60 px | 6.227 | 37,7 % |
| +100 px | 4.143 | 58,6 % |
| **+150 px** | **2.270** | **77,3 %** |
| **+200 px** | **1.551** | **84,5 %** |
| +300 px | 1.191 | 88,1 % |

**+150…+200 px là chỗ đáng tiền nhất.**

### Nhân bản delta — bốn ô nhóm 13–16 mỗi ô lặp 16 bản sao

`SeventhFestivalTopList_ExchangeFrame_BK1_Text2` … `_BK16_Text2` là **16 widget khác tên nhau**, và
bảng đè khoá theo **tên window**. Kéo một ô chỉ sửa **một** bản sao. Cách đúng: kéo `_BK1_` cho vừa ý,
lưu, rồi nhân dòng đó ra 15 bản còn lại bằng tay hoặc bằng một vòng lặp thay `BK1` → `BK2..BK16`
trong `data/ui_layout_overrides.tsv`. Cùng cách cho `ValentineRoseTopList`.
Hàng 17 thẻ cũng vậy nếu muốn áp sang 45 khung còn lại.

## 3. Kết quả được lưu ở đâu — và vì sao không phải trong `*.layout.xml`

```
Tools/reapply/ui-editor/data/ui_layout_overrides.tsv      <- bản THẬT, git theo dõi
Assets/CanonicalCY/Data/InterfaceFolder/CysUiEdit/        <- DIRECTORY JUNCTION trỏ sang thư mục trên
```

Client đọc và ghi qua đường `Data/…`, nhưng byte thật rơi vào thư mục **được git theo dõi**. Vì vậy
bấm "lưu" trong game là xong, không phải chạy thêm lệnh nào.

**Hệ quả phải biết: MỌI stage dùng chung MỘT bảng đè.** Mỗi `<stage>\Data` là junction tới
`Assets\CanonicalCY\Data`, bên trong lại có junction tới `Tools\reapply\ui-editor\data`. Nên kéo ở
stage nào cũng ghi vào cùng một tệp, và mọi stage khác thấy ngay. Đó là điều mình muốn (kết quả kéo
đi theo bạn), nhưng nó cũng có nghĩa: **một lượt đo tự động có thể ghi đè bảng của bạn**.
Kiểm bất cứ lúc nào bằng `85-ui-overrides.py status` — xem `master_dong` và `master_sha256`.

**Không bao giờ sửa thẳng `*.layout.xml`.** `Tools/pipeline/build_canonical_cy.py` dựng lại **cả cây**
`InterfaceFolder` từ `.axp` của CY (hàm `xform_layout`), nên mọi chữ sửa trong layout sẽ biến mất ở
lần dựng lại sau — đúng lớp mất dữ liệu đã phải trả giá bằng 242 dòng `SceneDefineEx`.

Ngược lại, `build_canonical_cy.py` **không thể** đụng tới thư mục này: nó không có `rmtree`/`os.remove`
nào, chỉ `os.replace` những tệp **có trong manifest của lớp GUI trước**; tệp lạ thì không bao giờ bị dọn.

Định dạng mỗi dòng (TSV, UTF-8):

```
layout<TAB>window<TAB>UnifiedAreaRect<TAB>giá trị mới<TAB>giá trị gốc
```

Cột "giá trị gốc" để biết delta và để `Delete` trả về được.

## 4. Lệnh quản lý

```powershell
cd C:\TLBB\085\CY-Source
python -X utf8 Tools\reapply\ui-editor\85-ui-overrides.py link     # tạo junction, chạy MỘT lần
python -X utf8 Tools\reapply\ui-editor\85-ui-overrides.py status   # đang ở chế độ nào, bao nhiêu dòng
python -X utf8 Tools\reapply\ui-editor\85-ui-overrides.py verify   # kiểm định dạng + đối chiếu hai bên
```

Nếu `mklink /J` không chạy được thì script tự chuyển sang **chế độ CHÉP**; khi đó phải chạy
`save` (runtime → master) sau mỗi buổi kéo, và `apply` (master → runtime) sau khi dựng lại `Assets`.

Sinh lại danh sách khung hỏng sau mỗi đợt dịch:

```powershell
python -X utf8 Tools\ui-fit\measure_ui_text.py --out <thư mục đo> --cy-dict ... --dbc --dbc-baseline ...
python -X utf8 Tools\ui-fit\make_edit_targets.py --measure <thư mục đo> `
       --out Tools\reapply\ui-editor\data\ui_edit_targets.tsv --top 40
```

## 5. Còn thiếu gì

- **NPC: ĐÃ CÀI 20/09.** Vào Đại Lý, nói chuyện với **bất kỳ NPC trồng trọt nào** (36 con) — menu
  11 khung nằm ngay dưới câu chào. Không cần restart server. Chi tiết, cách tắt và cách gỡ:
  `Tools/reapply/ui-editor/server/README_vi.md`.
  Cần một `Game.exe` dựng **sau** commit `cfde805c`; stage cũ hơn thì menu vẫn hiện nhưng bấm vào
  không mở khung. Danh sách đầy đủ **56** khung vẫn phải dùng `PgDn`/`PgUp` (NPC chỉ chứa được 11).

- *(nền, giữ để đối chiếu)* **Cơ chế NPC:**
  Một mục menu NPC có chứa `@UIEDIT:<TênKhung>` được client **nuốt tại chỗ** và mở thẳng khung, không
  ra server (`GMUIDataPool.cpp`, `CUIDataPool::SendSelectEvent`). Không có dấu hiệu đó thì đường NPC
  bình thường **không đổi một byte**. Nhờ vậy server **không cần một dòng logic nào** — nó chỉ cung
  cấp nhãn.
  Vật chủ là script `714057` (`odali_zhongzhipai1`, NPC trồng trọt) — chọn vì nó **hiện không làm gì
  cả** trên server này, nên hỏng nó không mất gì; và vì làm vậy thì **không đụng `cy4_npc.lua`**
  (84 NPC CY4, trong đó có cửa duy nhất vào bốn bản đồ môn phái).
  **Không có cổng GM** — quyết định **có điều kiện**: server riêng một người. Có người chơi khác thì
  phải thêm cổng, hoặc đặt `M.enabled = false`.
- **`PgDn` có thể làm văng game — và đó là lỗi CÓ SẴN của khung, không phải của bộ sửa.**
  Mỗi khung trong danh sách là một đoạn Lua **chưa từng chạy**. Ca đầu tiên đã gặp và đã vá:
  mở `Synthesize` giết tiến trình vì `GetAbilityInfo` deref con trỏ NULL
  (`GMGameInterface_Script_PlayerMySelf.cpp:664`, bảy nhánh không một phép kiểm). Bất kỳ người chơi
  nào mở khung chế tạo khi chưa có kỹ năng sinh hoạt tương ứng cũng văng y như vậy.
  Gặp văng: đọc `Bin64\WXC_SML.TXT`, lấy `Fault: Game.exe+0x...`, rồi
  `llvm-symbolizer --obj=Game.exe --relative-address 0x<RVA>`. Mỗi lần như vậy là **một lỗi có sẵn
  được lôi ra**, không phải một lỗi mới sinh ra.

- Bộ sửa ghi đè hình học **ngay sau khi nạp layout**. Khung nào tự tính lại vị trí trong `*_OnLoad`
  hoặc khi nhận `ADJEST_UI_POS` / `VIEW_RESOLUTION_CHANGED` thì có thể đè ngược lại; gặp thì ghi lại
  tên khung.
- Bản v1 chỉ hiểu thuộc tính `UnifiedAreaRect`. Muốn đổi phông hay kiểu canh chữ thì phải mở rộng.
