# `Tools/ui-fit` — tìm chỗ chữ tràn khung / bị cắt / đè nhau trong giao diện CY

Đo **tĩnh**, chạy lại được, không cần mở `Game.exe`. Đo bằng **đúng font và đúng cỡ chữ client nạp**
(FreeType trên `Schema/NotoSansSC-Regular.ttf`), không ước lượng bằng "số ký tự".

Giải thích đầy đủ + bằng chứng từng bước: `Docs/specs/client/ui-fit_vi.md`.

## Cần gì

```powershell
python -m pip install freetype-py      # 2.5.1, dùng cho FT_Set_Char_Size / advance.x >> 6
```

## Chạy một lượt đầy đủ

```powershell
cd C:\TLBB\085\CY-Source
$OUT = 'Build\Logs\2026-09-17-ui-fit\measure-lan-moi'

# 1. rút bảng chữ Trung gốc của CY 3.71 (chỉ cần làm lại khi đổi bản CY)
python Tools\ui-fit\extract_cy_dict.py --out $OUT\cy_strdict.tsv

# 2. quét toàn bộ 2.032 layout  (~90 giây)
python Tools\ui-fit\measure_ui_text.py --out $OUT --cy-dict $OUT\cy_strdict.tsv --dyn-digits 7

# 3. biến CSV thành danh sách dùng được
python Tools\ui-fit\report_ui_fit.py --in $OUT
```

Kết quả trong `$OUT`:

| File | Nội dung |
|---|---|
| `overflow.csv` | mọi widget có chữ rộng hơn khung |
| `overlap.csv` | mọi cặp chữ chồm sang ô bên phải |
| `summary.json` | số tổng, bảng font đang dùng, ký tự thiếu glyph |
| `for_i18n.tsv` | **danh sách khoá `StrDictionary` cần rút ngắn**, kèm ngân sách px và chuỗi CY gốc |
| `by_frame.tsv` | khung nào hỏng nhiều nhất |
| `overlap_by_frame.tsv` | khung nào có chữ đè nhau |
| `worst.tsv` | 200 widget nặng nhất, có đường dẫn file |

## Đọc kết quả

- **Dùng `over_px_min`, không dùng `over_px`.** `over_px_min` là mức tràn khi phần giá trị chạy
  (`.. tostring(n)`) **bằng rỗng** ⇒ chắc chắn tràn bất kể giá trị. `over_px` giả định `--dyn-digits`
  chữ số nên bi quan.
- **Cột `cy`**: `cy-fit` = chuỗi Trung gốc của CY vừa khung mà bản Việt tràn ⇒ **lỗi do bản dịch, phải
  sửa**. `cy-over` = CY cũng tràn ⇒ hành vi sẵn có của CY, để sau. `no-cy` = không có chuỗi CY để so
  (hằng trong `.lua`).
- **Cột `visible`** = 0 nghĩa là layout đặt `Visible="False"`; vẫn có thể hiện lúc chạy nhưng ưu tiên thấp.

## Chọn bản dịch ngắn hơn

```powershell
python Tools\ui-fit\fit_text.py --font SongTiBmp12 --box 132 --digits 7 `
       "Kinh nghiem hien tai:" "KN co:" "Hien co:"
```

In bề rộng từng chuỗi và nói rõ **VỪA (còn N px)** hay **TRÀN N px**.

## Giới hạn — phải biết trước khi tin con số

1. Chỉ đo **chiều ngang**. Chữ bị cắt trên/dưới không có trong báo cáo.
2. **Bỏ qua** widget `HorzFormatting = WordWrap*` (chúng tự xuống dòng); chúng vẫn có thể tràn **dọc**.
3. Chỉ đo chữ có trong `*.layout.xml` hoặc **hằng** trong `*.lua`. **Tên vật phẩm, tên NPC, mô tả kỹ
   năng… đến từ bảng `ConfigFolder` hoặc từ server lúc chạy ⇒ KHÔNG được đo.** Đây là lỗ hổng lớn nhất.
4. Widget do Lua tạo lúc chạy (dòng danh sách, ô menu) không có trong layout ⇒ không đo.
5. Nhãn (`Falagard/SimpleText`) đo chính xác; **nút đo kém chính xác hơn** vì vùng chữ lấy từ
   `<TextComponent><Area>` của looknfeel. Nút không có `TextComponent` được bỏ qua đúng.
6. `cy_w` đo bằng **NotoSansSC**, không phải font 936 thật của CY ⇒ là **ý đồ thiết kế**, không phải
   bề rộng thật CY vẽ ra.
7. Mặc định màn hình **1024×768** (`--screen 1920x1080` để đổi). Khung dùng `scale` sẽ khác theo độ phân giải.
8. `MultiColumnList` / `Listbox`: bề rộng cột do Lua đặt lúc chạy ⇒ không đo.

## Sửa rồi thì áp lại thế nào

Sửa dữ liệu phải đi qua `Tools/reapply/ui-fit/` (xem `Tools/reapply/README_vi.md`), vì chạy lại
`build_canonical_cy.py` sẽ xoá mọi thay đổi trong `Assets/CanonicalCY`.


---

## Vòng rút ngắn hàng loạt (ui-fit-2, 18/09) — bốn công cụ thêm

```powershell
$OUT='Build\Logs\2026-09-17-ui-fit-2\measure-moi'
python Tools\ui-fit\measure_ui_text.py --out $OUT --cy-dict <cy.tsv> --dyn-digits 7 --all-rows
python Tools\ui-fit\shorten_plan.py    --measure $OUT --cy-dict <cy.tsv> --out plan      --scope fit
python Tools\ui-fit\shorten_plan.py    --measure $OUT --cy-dict <cy.tsv> --out plan-over --scope over
python Tools\ui-fit\apply_overrides.py --rows plan\override_rows.tsv --rows plan-over\override_rows.tsv --nfd
python -B Tools\pipeline\cy_i18n_apply.py apply
```

| File | Việc |
|---|---|
| `shorten_plan.py` | với mỗi khoá `StrDictionary`, tính **ngân sách px của khung hẹp nhất** dùng khoá đó rồi rút ngắn: bản viết tay (`data/short_vi.tsv`) trước, sau đó luật chuẩn hoá / bỏ loại từ / bỏ đệm / 79 luật viết tắt (`data/abbr_vi.tsv`). Ra `plan.tsv`, `override_rows.tsv`, `manual_queue.tsv` |
| `apply_overrides.py` | gộp `override_rows.tsv` vào `Registry/i18n/cy_vi_override.tsv` (thay **tại chỗ** nếu khoá đã có — vì `cy_gui_dict.load_tsv_dict` dùng `setdefault`, dòng ĐẦU TIÊN thắng); `--nfd` chuẩn hoá mọi dòng NFD → NFC. Tự `.bak` |
| `add_batch.py` | nối một lô viết tay `khoá\|chuỗi\|ghi chú` vào `data/short_vi.tsv` (lô sau sửa lô trước) |
| `diff_shots.py` | so hai lô ảnh `CysUiViewer` và ghép ảnh **trước\|sau** cạnh nhau; ra `diff.tsv` (số pixel đổi của từng khung). Không cần thư viện ngoài |

**Ảnh trước/sau cho mọi khung, không cần `Game.exe`:**

```powershell
Build\Client\Bin64\CysUiViewer.exe --ui <...\Data\InterfaceFolder> --data <...\Data> `
    --dict <...\ConfigFolder\StrDictionary.txt> --all --size 1024x768 --out <thu muc>
```

2.032 ảnh / ~12 phút, dùng chính CEGUI + 8 font + looknfeel của client. Chạy song song với mọi nhánh khác.
Lưu ý: viewer hiện **mọi** widget cùng lúc (kể cả dòng Lua thường ẩn) nên chữ chồng trong ảnh viewer
**không** đồng nghĩa lỗi bố cục — đối chiếu `overlap.csv` trước khi kết luận.

### Hai bẫy mới của chính bộ đo (đã sửa)

1. **`#g` / `#e` là mã màu 8 ký tự** (`CysTextColour.h::tokenLength`), không phải 2. Bản cũ đo 6 chữ hex như
   chữ thật, cộng dư 45–70 px. Mốc đúng sau khi sửa: **10.091** chỗ tràn, không phải 10.235.
2. **`shorten_plan.py` từng bỏ im lặng bản vá viết tay** khi không dựng được ngân sách, hoặc khi bản viết tay
   vẫn tràn vài px (`manual-OVER`). Nay bản viết tay **luôn** được áp.

---

## Đo chữ đến từ bảng DBC `ConfigFolder` (ui-fit-3, 19/09) — vá giới hạn #3

Giới hạn #3 ở trên ("tên vật phẩm, mô tả kỹ năng… KHÔNG được đo") đã được vá **một phần**: bộ đo nay
lần được đường `bảng DBC → hàm Lua của C++ → Widget:SetText(...)` và đo **mọi giá trị thật của cột**
thay vì chỉ đo chuỗi giữ chỗ trong layout.

```powershell
$OUT='Build\Logs\2026-09-19-ui-fit-3\do-cuoi'
python Tools\ui-fit\measure_ui_text.py --out $OUT --cy-dict <cy.tsv> --dyn-digits 7 --all-rows `
       --dbc --dbc-baseline Build\Logs\2026-09-19-ui-fit-3\cy-baseline
python Tools\ui-fit\report_dbc_fit.py  --measure $OUT --dot 2     # 8 bảng i18n-2 dịch 18/09
python Tools\ui-fit\report_dbc_fit.py  --measure $OUT --dot 1     # các bảng dịch đợt trước
```

| File | Nội dung |
|---|---|
| `dbc_overflow.csv` | mỗi dòng = **một giá trị thật của cột** rộng hơn khung; có `cy_w` (bản Hán gốc), `cy`, `dot`, `tin_cay`, `lua_line` |
| `dbc_unmatched.csv` | cặp widget–cột **không đo được** và **lý do** (bên nhận là phần tử bảng, widget tự giãn, widget không vẽ chữ…) |
| `dbc_summary.json` | `stats`, `mau_so_tung_cap` (mẫu số: đã đo bao nhiêu giá trị mỗi khung), `khong_cat_duoc` |
| `dbc_rank.txt` | xếp hạng theo khung |
| `for_i18n_dbc.tsv` | **danh sách chuỗi cần rút ngắn** (chỉ `cy-fit` = CY vừa khung mà bản Việt tràn) |

**Bản đồ xuất xứ nằm ở `Tools/ui-fit/dbc_sources.py`.** Mỗi dòng `PROV` bắt buộc có `evidence_api` =
`file:dòng` của chỗ C++ **thật sự đọc field đó** — theo đúng luật của `i18n-2` mục 5: *grep chỗ truy cập
field thật trong `Src`, KHÔNG suy từ tên cột*. `NON_CLIPPING` liệt kê những cột đã dịch mà đường ra màn
hình **không thể cắt chữ** (widget tự giãn, khung chat, tooltip) — đừng đi tìm "chỗ tràn" ở đó nữa.

`--dbc-baseline` trỏ tới thư mục chứa bảng DBC **bản CY gốc** (GBK). Có hai nguồn độc lập và chúng
**trùng byte**: bản sao lưu của `i18n-2` (`Build/Logs/2026-09-17-i18n-cy/backup/20260917-235553`) và bản
rút thẳng từ `Config.axp` của CY 3.71 bằng `Docs/evidence/assetinv/axp_index.py`.

**Phép đối chứng (bộ đo phải biết trượt):** chạy lại với `--dbc-baseline <chính ConfigFolder đang đo>
--dbc-baseline-encoding utf-8` ⇒ số chỗ tràn **không đổi** nhưng `cy-fit` phải về **0** và tất cả rơi vào
`cy-over`. Nếu không ra như vậy thì cột `cy` đang được quyết định bởi thứ khác chứ không phải dữ liệu nền.

### Thẻ `#{_INFO…}` — bản gương THỨ BA của bộ phân tích (ui-fit-3, lượt 2)

Từ 19/09 (nhánh `info-links`), 12 họ thẻ toạ độ của CY **nở thành chữ thật**: phần nhìn thấy là `[x,y]`.
Trước đó chúng phát ra 0 ký tự. Bộ phân tích chuỗi nay có **ba** bản:

| bản | file | dùng cho |
|---|---|---|
| game | `Src/Client/CEGUISystem/UIString.cpp` (`CysInfoLink.h`) | client thật |
| viewer | `Src/Tools/CysUiViewer/UiViewerText.cpp` (`CysInfoLink.h`) | 2.032 ảnh khung offline |
| **bộ đo** | `Tools/ui-fit/ceguitext.py::info_link_expand` | **mọi con số bề rộng trong `Tools/ui-fit`** |

Hai bản đầu dùng chung một header C++; bản thứ ba là Python nên **chép tay** ⇒ mỗi lần `CysInfoLink.h` đổi
phải chạy lại phép đối chiếu trên dữ liệu thật. Ba con số phải trùng với `Tests/luaapi/info_link_tests.cpp`:

```
rows=154778   expanded=11802   visible chars added=100753
types: 0->11188  1->127  2->68  3->14  4->1  5->115  6->288  7->1
```

Lệch một con số nghĩa là bản gương đã trôi — **không có lỗi, không có cảnh báo, chỉ là số sai**.

`--no-infolink` tái hiện cách đo trước 19/09. Dùng nó làm **tay đối chứng** khi cần tách riêng ảnh hưởng
của thẻ (và làm ô kiểm hồi quy: phải ra đúng `4.269` / `441` của `ui-fit-2`). **Cặp A/B phải chạy liền nhau
trong một lệnh** — với 10 nhánh song song, bảng dữ liệu có thể bị nhánh khác ghi đè giữa hai lượt.
