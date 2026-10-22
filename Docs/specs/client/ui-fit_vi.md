# ui-fit — đo chữ tràn khung / đè nhau trong giao diện CY, và sửa bằng cách rút ngắn bản dịch (17/09/2026)

> **ĐỌC MỤC 8 TRƯỚC NẾU BẠN CẦN SỐ.** Lượt `ui-fit-2` (18/09) đã **sửa một lỗi của chính bộ đo** (`#g`/`#e`
> là mã màu 8 ký tự, không phải 2) và **đã áp 3.426 bản rút ngắn**. Mốc trong mục 0 dưới đây là số **cũ và
> hơi sai**; số đúng, cùng kết quả sau khi sửa, nằm ở **mục 8**.

Agent `ui-fit`. Phạm vi: `Assets/CanonicalCY/Data/InterfaceFolder/**` (`*.layout.xml`, `*.lua`, `*.font`,
`*.imageset.xml`). **Không** đụng `StrDictionary.txt` / `ConfigFolder/*.txt` (của `i18n-cy`), **không** đụng `Src/`.

Quy ước: **[DK]** dữ kiện đo được (có đường dẫn/offset/số). **[SL]** suy luận.

Bằng chứng: `Build/Logs/2026-09-17-ui-fit/` (không vào git). Công cụ: `Tools/ui-fit/`. Công thức áp lại:
`Tools/reapply/ui-fit/`.

---

## 0. Trả lời ngắn

Người dùng báo *"một số khung vẫn chưa vừa, chưa hợp lý, mất chữ"*. Việc khó không phải là sửa mà là **tìm**:
~900 thư mục giao diện, 2.032 layout, 24.310 widget có chữ. Lượt này dựng **phép đo tĩnh chạy được lặp lại**,
đo bằng **đúng font và đúng cỡ chữ client nạp**, rồi đối chiếu với **bản chữ Trung gốc của CY 3.71** để tách
ra phần **hỏng do bản dịch** khỏi phần vốn đã như thế ở CY.

| Số đo (17/09, 1024×768, CodePage 65001) | Kết quả |
|---|---|
| Layout đọc được / tổng | **2.032 / 2.032**, 0 lỗi cú pháp |
| Widget có chữ được đo | **24.310** (26.203 lượt đo, tính cả chuỗi Lua) |
| **Chỗ chữ rộng hơn khung** | **10.235** |
| — trong đó **chắc chắn** (tràn ngay cả khi phần số bằng rỗng) và widget không bị ẩn | **9.395** |
| — trong đó **CY vừa, bản Việt tràn ⇒ do bản dịch** | **5.693** ← danh sách phải sửa |
| — trong đó **CY cũng tràn** ⇒ hành vi sẵn có của CY | **2.353** |
| **Cặp chữ đè sang ô bên phải** | **487** cặp, **190 khung** |
| Khoá `StrDictionary` cần rút ngắn | **3.209** khoá |
| Khung có ít nhất một lỗi chắc chắn | **1.121** |
| Ký tự thiếu glyph trong font | **2** (U+0323, U+0303 — dấu tổ hợp), **45 dòng** `StrDictionary` |

Đã sửa trong lượt này: **1 khung** (`ActionSkillsStudy`) — 2 chỗ tràn, có ảnh trước/sau trên client thật.
Đây là mốc dừng có chủ ý: mảng này cần **danh sách đúng** trước khi sửa hàng loạt, vì luật số một cấm nới khung.

---

## 1. Đo bằng gì — từng bước đều đọc thẳng từ mã nguồn, không ước lượng

Đây là phần quan trọng nhất của lượt này: **không đếm ký tự**. Chuỗi Việt có dấu, chữ Trung vuông, chữ Latin
hẹp — đếm ký tự cho kết quả sai hàng chục phần trăm. Toàn bộ chuỗi đo bằng FreeType trên **chính file font
client nạp**, với **chính cỡ chữ** và **chính phép làm tròn** của engine.

### 1.1 Font nào đang thật sự được dùng [DK]

`Bin64/WXSystem.cfg` của mọi stage: `System_CodePage=65001`.
`Src/Client/CEGUISystem/UISystem.cpp:374-376` đẩy số đó vào `FontManager::setCodePage`.
`CysFontDefinition::select(codePage)` (`Src/ThirdParty/CEGUI-0.4.1/CEGUI/include/CysFontDefinition.h`) chọn
**đúng một** dòng `<Font>` trong file `.font` theo `CodePage`.

Kiểm chứng bằng log thật (`Build/world-gui/stage-fps-daiviet/Bin64/UISystem.log`):

```
CYS font selected: SongTiBmp12  CodePage=65001 Type=FreeType Filename=Schema/NotoSansSC-Regular.ttf
CYS font selected: YouYuan9.75  ... NotoSansSC-Regular.ttf      (8 font, tất cả cùng một file .ttf)
```

⇒ **Cả 8 font của giao diện đều là `Schema/NotoSansSC-Regular.ttf`.** Chỉ khác cỡ chữ:

| Tên font | `Size` trong `.font` | `d_ptSize` (uint) | em ở 96 DPI |
|---|---|---|---|
| SongTiBmp12 (**mặc định**) | 12 | 12 | 16,0 px |
| YouYuan13 | 13 | 13 | 17,3 px |
| TLNA__ / YouYuan9.75 | 14.1 | **14** | 18,7 px |
| YouYuan11.25 | 15 | 15 | 20,0 px |
| VDA_M / VDA_N | 16 | 16 | 21,3 px |
| YouYuan18 | 18 | 18 | 24,0 px |

**Bẫy [DK]:** `Size="14.1"` bị **cắt thành 14**, không làm tròn thành 14,1 — `Font_xmlHandler` gọi
`getValueAsInteger` (`CEGUIFont_xmlHandler.cpp:87`) và `istringstream >> int` đọc `14` rồi dừng
(`CEGUIXMLAttributes.cpp:130-148`), không báo lỗi. Ai đọc file `.font` mà tưởng cỡ chữ là 14,1 sẽ tính sai.

**Font mặc định là `SongTiBmp12`** vì nó là `<Font>` đầu tiên trong `Schema/WoWLookSkin.scheme.xml:25`, và
`FontManager::createFont` gọi `setDefaultFont` cho font đầu tiên được tạo. Widget không có thuộc tính `Font`
dùng font này — **đó là đa số nhãn trong game** (chỉ 2.944 / 24.310 widget đặt `Font`).

### 1.2 Bề rộng một chuỗi [DK]

`FontBase::getTextExtent` (`CEGUIFontBase.cpp:390-460`) cộng `d_horz_advance` của từng **mã điểm**; mã điểm
markup (0xFB màu, 0xFC gradient, 0xFD/0xFE hyperlink) **không cộng bề rộng**.
`Font_FreeType::createFontGlyph` (`CEGUIFont_FreeType.cpp:163-217`) đặt
`d_horz_advance = glyph->advance.x >> 6` — **số nguyên pixel** — sau khi nạp bằng
`FT_LOAD_RENDER|FT_LOAD_NO_AUTOHINT|FT_LOAD_TARGET_NORMAL`, với cỡ đặt bằng
`FT_Set_Char_Size(face, 0, ptSize*64, 96, 96)` (DPI 96 là hằng số `OgreCEGUIRenderer::getHorzScreenDPI`).

`Tools/ui-fit/ceguitext.py` lặp lại **y hệt** chuỗi lệnh đó bằng `freetype-py` (đã cài, 2.5.1).

### 1.3 Vùng vẽ chữ của nhãn = TOÀN BỘ rect, và chữ BỊ CẮT theo rect đó [DK]

`FalagardSimpleText::getTextRenderArea()` = `Rect(Point(0,0), getAbsoluteSize())`
(`Src/Client/CEGUIFalagardEx/FalSimpleText.h:115`) — **không** dùng `NamedArea "TextArea"` của looknfeel.
`populateRenderCache` (`FalSimpleText.cpp:66-106`) truyền chính rect đó làm `clipper`, chỉ nới **theo chiều
dọc** 4 px mỗi phía (sửa của `item-live` 15/09) — **không bao giờ nới ngang**.

⇒ Chữ rộng hơn widget **bị cắt cụt**. Đó chính là *"mất chữ"* của người dùng. Và khi hai nhãn nằm cạnh nhau,
cái bên trái bị cắt đúng ở mép cái bên phải nên **trông như hai chữ dính vào nhau** — đó là *"đè nhau"*.

Ba họ widget này chiếm gần hết số nhãn: `TLBB_SimpleText` (19.787 lần dùng), `TLBB_SimpleMulitiTextFrame`
(3.035), `TLBB_SimpleTextFrame` (573) — tất cả đều ánh xạ `Falagard/SimpleText`.

### 1.4 Hình học widget [DK]

`UnifiedSize`/`UnifiedPosition` = `{{scale,offset},{scale,offset}}`, tính theo rect của **cha**.
`Position`/`Size` (không có tiền tố) là **tương đối**, vì `Window::d_metricsMode = Relative`
(`CEGUIWindow.cpp:213`). Gốc toạ độ con = rect đầy đủ của cha, vì trong nhánh này
`Window::getUnclippedInnerRect()` trả thẳng `getUnclippedPixelRect()` (`CEGUIWindow.cpp:638-641`) và không
lớp Falagard nào của dự án ghi đè nó.

**Không có layout nào dùng `MetricsMode`** (đếm trên cả 2.032 file) ⇒ không có ngoại lệ.

**Bẫy đã tránh [DK]:** `UnifiedPosition` thiếu dấu `}` cuối là **định dạng gốc** của dữ liệu, 11.276 giá trị
trên toàn client; CEGUI chấp nhận. Bộ đọc của `measure_ui_text.py` lấy 4 số bằng regex nên **không quan tâm
dấu ngoặc** — và **không sửa** file nào vì việc đó.

### 1.5 Chuỗi lấy ở đâu

- Thuộc tính `Text` trong layout (27.008 chỗ), giải `#{KHOÁ}` qua `StrDictionary.txt` (đệ quy tối đa 4 lớp).
- Lời gọi `Widget:SetText(...)` trong `.lua` cùng thư mục — chỉ lấy **chuỗi hằng ở mức ngoài cùng**.
  **Bẫy đã sập rồi sửa:** lấy cả chuỗi trong lời gọi lồng nhau thì `Player:GetData("HUILIUEXP")` biến
  `"HUILIUEXP"` thành chữ hiển thị và đẻ ra 225 báo động giả.
- Phần giá trị chạy (`.. tostring(n)`) được thay bằng `--dyn-digits` chữ số (mặc định 7).
  **Cột `over_px_min` là số an toàn**: nó là mức tràn khi phần giá trị chạy **bằng rỗng**. Chỉ dùng
  `over_px_min > 0` mới gọi là "chắc chắn".

### 1.6 Đối chiếu CY thật — cách tách "lỗi do dịch" khỏi "CY vốn thế" [DK]

Bảng chữ gốc của CY 3.71 nằm trong `CY Game\Data\Config.axp → StrDictionary.txt`, payload mã hoá (alg 24),
giải ra là **DBC nhị phân `00CCBBDD` hai cột STRING, 154.822 dòng**. `Tools/ui-fit/extract_cy_dict.py` rút nó
ra TSV, dùng lại `Docs/evidence/assetinv/axp_index.py` để giải mã.

**Bẫy [DK]:** `Tools/game/dbc_inventory.py::decode()` thử **UTF-8 trước** rồi mới GBK. Chuỗi GBK ngắn như
`学习` (D1 A7 CF B0) **lại là UTF-8 hợp lệ** và ra `ѧϰ` (chữ Kirin) — sai cả nghĩa lẫn bề rộng. Bộ rút của
`ui-fit` **ép GBK** cho mọi ô STRING.

Với mỗi widget dùng `#{KHOÁ}`, đo **cùng font, cùng khung** cho cả chuỗi Việt và chuỗi Trung gốc:

- `cy = cy-fit` — CY vừa, bản Việt tràn ⇒ **hỏng do bản dịch**, sửa bằng cách rút ngắn. **5.693 chỗ.**
- `cy = cy-over` — CY cũng tràn ⇒ hành vi sẵn có của CY, **để sau**. **2.353 chỗ.**
- `cy = no-cy` — chuỗi không đến từ bảng (hằng trong `.lua`, hoặc khoá chỉ có ở bản Việt). **1.582 chỗ.**

**Giới hạn phải nói rõ:** `cy_w` đo bằng **NotoSansSC**, không phải font 936 thật của CY
(`Schema/0_FIREFOX_2.bin`). Với chữ Trung (ô vuông, gần bằng em) sai số nhỏ, nhưng con số đó là **ý đồ thiết
kế của khung**, không phải bề rộng thật CY vẽ ra.

---

### 2.1 Ba lỗi được chỉ đích danh — phép đo tìm lại được cả ba, độc lập [DK]

`host-xinfa` báo ở `ActionSkillsStudy`. Chạy `measure_ui_text.py --filter ActionSkillsStudy` cho ra:

| Widget | Khung | Chữ | Kết luận |
|---|---|---|---|
| `ActionSkillsStudy_CurrentlyExp_Character_Text` | **132 px** | `"Kinh nghiệm hiện tại:"` = **159 px** | tràn **27 px** ngay cả khi chưa có số |
| `ActionSkillsStudy_DemandExp_Character_Text` | **132 px** | `"Kinh nghiệm yêu cầu:"` = **161 px** | tràn **29 px** |
| `ActionSkillsStudy_Currently_Money_Text` | — | `"Sở hữu tiền bạc"` = 118 px, ô tiền bắt đầu ở **67 px** | **đè 53 px** |
| `ActionSkillsStudy_Demand_Jiaozi_Text` | — | `"Cần tiêu hao"` = 95 px | đè 30 px |
| `ActionSkillsStudy_Currently_Jiaozi_Text` | — | `"Có giao tử"` = 76 px | đè 11 px |
| `ActionSkillsStudy_UpLevel_Frame` | 53,6 px | `#{INTERFACE_XML_804}` = `"Học tập"` = 59 px | tràn 5 px (CY `学习` = 32 px ⇒ `cy-fit`) |

So với ảnh thật `Build/Logs/2026-09-17-host-xinfa/gui-live-2/cys-live-159173500-xinfa-after.png`: đúng từng
chỗ — *"Kinh nghiệm hiệnKinh nghiệm yêu"*, *"Sở hữu tiền bạ"*, nút *"Học tậ"*. **Phép đo tĩnh khớp ảnh động.**

Một chỗ **không** phải lỗi: `ActionSkillsStudy_SkillLevel` (`"Cấp bậc hiện tại:"`, khung 160,8 px) chỉ tràn khi
giả định 7 chữ số. Cấp tâm pháp tối đa **119** (`CysHost_Skill.cpp` `MaxLevel` = 119) ⇒ 3 chữ số ⇒ **151 px,
vừa**. `over_px_min = -36,8` nói đúng điều đó. Đây là lý do phải đọc `over_px_min`, không đọc `over_px`.

### 2.2 `最高等级%d` in thô — KHÔNG phải lỗi của lớp giao diện [DK]

`ActionSkillsStudy.lua:352` chỉ làm `ActionSkillsStudy_SkillInfo:SetText(strInfo)` với
`strInfo = Player:GetXinfaInfo(nXinfaId,"explain")`.
`Src/Client/LuaApiGen/CysHost_Skill.cpp:31-42` (`PlayerGetXinfaInfo`) đẩy **nguyên văn** chuỗi của bảng
(`g_services.xinfaText(id, 1)`), không thay tham số. Client CY thật có thay `%d` (ảnh CY hiện `最高等级` kèm
số). ⇒ **Việc của nhánh host** (`Src/Client/LuaApiGen` + lớp game), không sửa được từ `.lua`/`.layout.xml`.
Phần mô tả còn tiếng Trung là cột `explain` của `XinFa_V1` ⇒ **`i18n-cy`**.

### 2.3 "Ô vuông" ở khung Tu luyện — phân biệt hai nguyên nhân, đã tách bạch [DK]

Câu hỏi: thiếu glyph trong font, hay dữ liệu chưa dịch?

**Kiểm 1 — font có đủ chữ Trung không:** nạp `NotoSansSC-Regular.ttf` và hỏi `FT_Get_Char_Index` cho
`修 炼 真 元 经 验 等 级 门 派 最 高 学 习` ⇒ **có đủ, không thiếu ký tự nào**.

**Kiểm 2 — dữ liệu:** bảy bảng `XiuLian*.txt` / `XiuChangNotice.txt` trong
`Assets/CanonicalCY/Data/ConfigFolder` đều là **DBC nhị phân còn nguyên GBK** (`raw.decode('utf-8')` ném
`invalid continuation byte`; `XiuLianDetail.txt` chứa **6.608** chữ Trung khác nhau).

⇒ **Nguyên nhân là dữ liệu GBK chưa dịch bị đọc như UTF-8**, không phải font. Chủ sở hữu: **`i18n-cy`**.
Không sửa được bằng cách đổi font, và **đừng** thay font vì lý do này.

**Nhưng có một lớp ô vuông THẬT do font [DK]:** **45 dòng** `StrDictionary.txt` viết dấu tiếng Việt ở dạng
**tổ hợp (NFD)** — `U+0323` (dấu nặng) và `U+0303` (dấu ngã) rời — mà `NotoSansSC` **không có glyph** cho hai
dấu tổ hợp đó ⇒ chữ mất dấu / hiện ô trống. Danh sách: `Build/Logs/2026-09-17-ui-fit/measure-after/nfd_keys.tsv`
(có sẵn cột `chuoi_sau_NFC` để thay thẳng). Sửa = chuẩn hoá NFC. Chủ sở hữu: **`i18n-cy`**.

### 2.4 Hai mươi lăm khung hỏng nặng nhất (xếp theo số lỗi chắc chắn)

`Build/Logs/2026-09-17-ui-fit/measure-after/by_frame.tsv` — 1.121 khung. Đầu bảng:

| Khung | Số lỗi | Nặng nhất | Người chơi thấy thường xuyên? |
|---|---|---|---|
| `AcceSetup` (phím tắt) | **146** | 159 px | **có** — bảng thiết lập |
| `SeventhFestivalTopList` | 81 | 133 px | theo sự kiện |
| `ValentineRoseTopList` | 64 | 302 px | theo sự kiện |
| `XinShouNew` (tân thủ) | 54 | 377 px | **có** — người mới |
| `ViewSetup` (thiết lập hiển thị) | 39 | 118 px | **có** |
| `Pet` (trân thú) | 36 | 66 px | **có** |
| `YuanbaoShop` (shop NB) | 31 | 134 px | **có** |
| `GameSetup` | 24 | 163 px | **có** |
| `Banghui_Bank` | 30 | 163 px | có |
| `WLBook` (võ lâm) | 25 | 63 px | có |
| `CangPin_ShuXing` | 27 | 103 px | có |

### 2.5 Chữ đè sang ô bên phải — 487 cặp / 190 khung

`measure-after/overlap.csv`, `overlap_by_frame.tsv`. Phép đo: lấy **vệt chữ thật** (đã tính theo
`HorzFormatting`: trái / phải / giữa, và đã cắt theo rect của chính widget) rồi xem nó có chồm sang rect của
một widget **cũng vẽ chữ** nằm **bên phải** hay không. Bỏ qua các cặp cùng chỗ (Show/Hide luân phiên, ô menu
nhân bản lúc chạy) vì đó không phải lỗi bố cục — nếu không lọc, con số phồng lên 6.001 với ~90 % báo động giả.

### 2.6 Danh sách gửi `i18n-cy` — 3.209 khoá

`Build/Logs/2026-09-17-ui-fit/measure-after/for_i18n.tsv`, cột:
`khoa | so_widget | khung_hep_nhat_px | be_rong_hien_tai_px | vuot_px | be_rong_CY_px | font | chuoi_hien_tai |
khung_vi_du | widget_vi_du`.

Sắp theo **số widget bị ảnh hưởng** trước, vì một khoá có thể vỡ 49 khung cùng lúc. Đầu bảng:

| Khoá | Số widget | Khung hẹp nhất | Hiện tại | CY | Chuỗi |
|---|---|---|---|---|---|
| `INTERFACE_XML_1055` | 49 | 85 px | 110 px | 80 px | `Tắt trò chuyện` |
| `INTERFACE_XML_1056` | 49 | 85 px | 90 px | 64 px | `Chế độ chat` |
| `ZYXT_120528_154` | 45 | 35 px | 101 px | 32 px | `Chân Nguyên` |
| `MPJJ_XT_XML_01` | 45 | 35 px | 78 px | 32 px | `Kinh Mạch` |
| `INTERFACE_XML_804` | — | 53,6 px | 59 px | 32 px | `Học tập` → đề nghị `Học` (30 px) |
| `INTERFACE_XML_833` | — | (đè ô tiền ở 67 px) | 118 px | 64 px | `Sở hữu tiền bạc` → `Tiền:` |

**Một nhóm KHÔNG rút ngắn được [DK]:** khung 32–40 px vốn dành cho **hai chữ Hán** (`真元`, `经脉`). Không có
cách viết tiếng Việt nào của "Chân Nguyên" vừa 35 px ở cỡ 12pt. Nhóm này phải để người dùng quyết
(xem mục 5).

---

## 3. Đã sửa gì trong lượt này

**Một khung: `ActionSkillsStudy`.** Chỉ rút ngắn chữ, **không đụng một con số hình học nào**.

| File | Thay đổi | Vì sao |
|---|---|---|
| `ActionSkillsStudy/ActionSkillsStudy.lua` | `"Kinh nghiệm hiện tại:"` → `"KN có:"` (2 chỗ) | 159 px → 48 px; khung 132 px, còn 84 px cho số (7 chữ số = 63 px). CY dùng `当前经验:` = 68 px |
| `ActionSkillsStudy/ActionSkillsStudy.lua` | `"Kinh nghiệm yêu cầu:"` → `"KN cần:"` | 161 px → 57 px. CY dùng `需要经验:` = 68 px |
| `ActionSkillsStudy/ActionSkillsStudy.layout.xml` | thêm `Tooltip` cho hai nhãn đó | trả lại nghĩa đầy đủ khi rê chuột; `Tooltip` **không** chạm hình học |

Đo lại sau khi sửa: khung này còn **2** chỗ tràn (đều thuộc `i18n-cy`) và **3** cặp đè (đều thuộc `i18n-cy`).

### Ảnh trước / sau — client thật, server riêng

| | |
|---|---|
| TRƯỚC | `Build/Logs/2026-09-17-ui-fit/frames/ActionSkillsStudy-TRUOC.png` (lượt `host-xinfa` 21:43, test05) |
| SAU | `Build/Logs/2026-09-17-ui-fit/frames/ActionSkillsStudy-SAU.png` (lượt `gui-after-1` 22:59, test05) |

Dòng chữ đổi từ **`Kinh nghiệm hiệnKinh nghiệm yêu`** (hai nhãn bị cắt, dính vào nhau) thành
**`KN có:23279    KN cần:79`** — hai nhãn tách bạch, đọc được cả chữ lẫn số.

Lượt `gui-after-1`: `run_world_gui_live.ps1` trên `Build/world-gui/stage-host-xinfa-4`, **20/20 cổng kiểm
PASS**, `CYS_XINFA_LIVE=1` bơm chuột thật vào CEGUI (không gọi Lua tay), server riêng
`/home/ubuntu/cys-test-20260913`, test05 / CYTest05 / GUID 200006.

---

## 4. Công cụ — chạy lại được, và giới hạn của nó

`Tools/ui-fit/` (xem `Tools/ui-fit/README_vi.md`):

| File | Việc |
|---|---|
| `ceguitext.py` | nạp font theo CodePage, đo bề rộng y hệt `FontBase::getTextExtent`; đọc `StrDictionary`; giải markup `#{} #r #c.. #aB` |
| `measure_ui_text.py` | quét toàn bộ layout, dựng lại hình học CEGUI, xuất `overflow.csv` + `overlap.csv` + `summary.json` |
| `extract_cy_dict.py` | rút bảng chữ Trung gốc của CY 3.71 từ `Config.axp` ra TSV (ép GBK) |
| `report_ui_fit.py` | biến CSV thành `for_i18n.tsv`, `by_frame.tsv`, `worst.tsv`, `overlap_by_frame.tsv` |
| `fit_text.py` | đo vài chuỗi ứng viên trong một khung cho trước — dùng khi chọn bản dịch ngắn hơn |

### Giới hạn — đọc trước khi tin con số

1. **Chỉ đo chiều ngang.** Chữ bị cắt trên/dưới không nằm trong báo cáo này.
2. **Bỏ qua widget có `HorzFormatting` kiểu `WordWrap*`.** Chúng tự xuống dòng nên không tràn ngang, nhưng
   **có thể tràn dọc** — chưa đo.
3. **Chỉ đo chữ có trong layout hoặc hằng trong `.lua`.** Tên vật phẩm, tên NPC, mô tả kỹ năng… đến từ bảng
   `ConfigFolder` hoặc từ server lúc chạy ⇒ **không nằm trong 24.310 widget này**. Đây là lỗ hổng lớn nhất.
4. **Widget do Lua tạo lúc chạy** (dòng danh sách, ô menu, tooltip ghép động) không có trong layout ⇒ không đo.
5. **Ho nút đo kém chính xác hơn nhãn.** Vùng chữ của nút lấy từ `<TextComponent><Area>` của looknfeel (đa số
   là toàn rect) và `HorzFormatProperty`; nút không có `TextComponent` được **bỏ qua đúng** (ví dụ
   `TLBB_ButtonClose` có `Text="TLBB_ButtonClose"` nhưng không vẽ chữ). 3.087 / 5.693 dòng "do dịch" là nút.
6. **`cy_w` không phải bề rộng thật của CY** — xem mục 1.6.
7. **Màn hình 1024×768.** Khung gốc phần lớn có kích thước tuyệt đối nên không đổi theo độ phân giải, nhưng
   khung dùng `scale` thì có. Đổi bằng `--screen 1920x1080`.
8. **`MultiColumnList` / `Listbox`**: bề rộng cột do Lua đặt lúc chạy ⇒ không đo.

---

## 5. Cần người dùng quyết

**Nhóm khung 32–40 px vốn dành cho hai chữ Hán** (`真元` `经脉` `神鼎` `宝鉴` — khoảng 45 widget mỗi khoá,
xuất hiện ở `CangPin_ShuXing` và các khung thuộc tính). Ba lựa chọn, đều có giá:

1. **Viết tắt** (`CN`, `KM`, `TĐ`, `BG`) + tooltip đầy đủ. Giữ nguyên lưới CY. Mất tính đọc-ngay.
2. **Dùng font nhỏ hơn cho riêng nhóm nhãn đó** (đặt `Font="SongTiBmp12"` → không đổi; phải thêm một font
   mới cỡ 9–10). Lệch với CY về diện mạo.
3. **Nới riêng những ô đó** — **trái luật số một**, chỉ làm nếu người dùng chấp nhận rủi ro vỡ lưới.

Đề xuất của tôi: **(1)**, vì chuẩn so sánh là CY và CY để hai chữ ở đó.

---

## 6. Bẫy phát hiện trong lượt này

1. **`Size="14.1"` trong `.font` bị cắt thành 14.** Tính theo 14,1 là sai cỡ chữ ngay từ đầu.
2. **Font mặc định là `SongTiBmp12` (12pt)**, không phải `YouYuan11.25`. Nó là `<Font>` đầu tiên trong scheme.
3. **`TLBB_SimpleMulitiTextFrame` KHÔNG dùng `NamedArea "TextArea"`** của looknfeel dù looknfeel có khai báo
   (lề 7 px). `FalagardSimpleText` trả thẳng toàn rect. Trừ 7 px là sai.
4. **`dbc_inventory.py::decode()` thử UTF-8 trước GBK** ⇒ chuỗi GBK ngắn ra chữ Kirin (`学习` → `ѧϰ`). Rút dữ
   liệu CY phải **ép GBK**.
5. **Regex `SetText\((.+?)\)` với `re.S` ăn xuyên nhiều dòng** và gom cả chuỗi của lời gọi lồng nhau —
   `Player:GetData("HUILIUEXP")` biến `"HUILIUEXP"` thành chữ hiển thị. Phải đếm ngoặc cân bằng và **chỉ lấy
   chuỗi ở mức ngoài cùng**.
6. **Đếm "đè nhau" mà không lọc thì 90 % là báo động giả**: hai widget cùng một chỗ (Show/Hide luân phiên) và
   ô `TLBB_MenuItem` nhân bản lúc chạy. Bắt buộc yêu cầu widget kia nằm **bên phải**.
7. **Ô vuông có hai nguyên nhân khác hẳn nhau** — dữ liệu GBK chưa dịch (đa số) và dấu tiếng Việt dạng tổ hợp
   NFD mà NotoSansSC không có glyph (45 dòng). Đừng gộp làm một.
8. **`over_px` với `--dyn-digits` là số bi quan.** Dùng `over_px_min` để quyết định; ví dụ
   `ActionSkillsStudy_SkillLevel` "tràn" 26 px theo `over_px` nhưng thực tế thừa 10 px vì cấp tối đa là 119.
9. **`.layout.xml` dùng CRLF, `.lua` dùng LF.** Script áp lại phải đổi ký tự xuống dòng của bản vá theo file,
   không thì không khớp chuỗi nào.
10. **`UnifiedPosition` thiếu `}` là định dạng gốc** (11.276 giá trị). Bộ đọc phải chịu được, và **tuyệt đối
    không "sửa"** hàng loạt.

---

## 7. Áp lại sau khi chạy `build_canonical_cy.py`

`Tools/pipeline/build_canonical_cy.py` dựng lại `Assets/CanonicalCY` từ `.axp` ⇒ **xoá mọi sửa đổi ở trên**.
Công thức nằm trong git tại `Tools/reapply/ui-fit/`:

```powershell
cd C:\TLBB\085\CY-Source
python -X utf8 Tools\reapply\ui-fit\80-ui-fit-strings.py plan
python -X utf8 Tools\reapply\ui-fit\80-ui-fit-strings.py apply --bak Build\reapply-bak
python -X utf8 Tools\reapply\ui-fit\80-ui-fit-strings.py verify     # phải ra hong=0
```

`apply` idempotent (chạy lần hai báo `da-co`, không ghi). Sao lưu bản gốc vào
`Build\reapply-bak\ui-fit\<đường dẫn tương đối>` trước khi ghi lần đầu.
Thêm bản vá mới = thêm một mục vào `Tools\reapply\ui-fit\data\ui-fit-patches.json`
(`file` / `old` / `new` / `count` / `why`) — **chỉ được rút ngắn chữ hoặc thêm thuộc tính không chạm hình học.**

---

## 8. Lượt `ui-fit-2` (17–18/09/2026) — đã sửa thật, có số đo và ảnh trước/sau

Agent `ui-fit-2`. Phạm vi mở rộng: **`Registry/i18n/cy_vi_override.tsv`** (chuỗi `StrDictionary`) + `Tools/ui-fit/`
+ `Tools/reapply/ui-fit/`. Bàn giao: `Timeline/handoff/ui-fit-2.md`. Bằng chứng: `Build/Logs/2026-09-17-ui-fit-2/`.

### 8.1. Một lỗi của bộ đo phải sửa trước khi tin bất kỳ con số nào [DK]

`CysTextColourParser::tokenLength` (`Src/ThirdParty/CEGUI-0.4.1/CEGUI/include/CysTextColour.h:19-22`) cho
`#c`, **`#g`**, **`#e`** độ dài **8** ký tự (`#gFF0FA0`), và cả ba đều sinh mã điểm 0 bề rộng
(`0xFB` màu, `0xD0` gradient, `0xFC` viền — `FontBase::getTextExtent` bỏ qua cả ba, `CEGUIFontBase.cpp:438-462`).
`ceguitext.expand_markup` cũ chỉ nuốt **2** ký tự cho `#g`/`#e` ⇒ 6 chữ hex còn lại **được đo như chữ thật**,
cộng dư 45–70 px cho mọi chuỗi có `#gFF0FA0` (tiêu đề khung) hoặc `#e010101` (viền chữ).

Hệ quả: mốc trong mục 0 phải đọc lại là

| | mục 0 (sai) | đúng |
|---|---:|---:|
| Chỗ chữ rộng hơn khung | 10.235 | **10.091** |
| — chắc chắn + không ẩn | 9.395 | **9.249** |
| — do bản dịch (`cy-fit`) | 5.693 | **5.700** |
| — CY cũng tràn (`cy-over`) | 2.353 | **2.233** |
| Cặp chữ đè nhau | 487 | **486** |
| Khung có lỗi | 1.121 | **1.116** |

### 8.2. Đã sửa gì và kết quả đo

Cách sửa: **chỉ rút ngắn chuỗi hiển thị**, ghi vào `Registry/i18n/cy_vi_override.tsv` dạng `#KHOÁ`, rồi
`Tools/pipeline/cy_i18n_apply.py apply` dựng lại `StrDictionary.txt`. **Không** đụng một giá trị hình học nào.
**3.426 khoá** đã đổi (2.811 viết tay có ghi chú px, phần còn lại do 79 luật viết tắt trong
`Tools/ui-fit/data/abbr_vi.tsv`, cộng **49 dòng NFD → NFC**).

| | TRƯỚC | SAU | giảm |
|---|---:|---:|---:|
| Chỗ chữ rộng hơn khung | 10.091 | **4.269** | −58 % |
| — chắc chắn và không bị ẩn | 9.249 | **3.488** | −62 % |
| — **do bản dịch** | **5.700** | **262** | **−95 %** |
| — CY cũng tràn | 2.233 | 1.899 | −15 % |
| Cặp chữ đè nhau | 486 | 441 | −9 % |
| **Ký tự thiếu glyph** | 2 | **0** | −100 % |
| **Khung có lỗi do bản dịch** | 1.116 | **146** | −87 % |

`AcceSetup` 146 → **0** · `SeventhFestivalTopList` 81 → **0** · `Banghui_Bank` 30 → **0** · `WLBook` 25 → **0** ·
`XinShouNew` 55 → 18 · `Pet` 36 → 5 · `YuanbaoShop` 30 → 2 · `CangPin_ShuXing` 27 → 1.

### 8.3. `CysUiViewer.exe` — cách lấy ảnh trước/sau cho **mọi** khung, không cần `Game.exe` [DK]

```powershell
Build\Client\Bin64\CysUiViewer.exe --ui <...\Data\InterfaceFolder> --data <...\Data> `
    --dict <...\ConfigFolder\StrDictionary.txt> --all --size 1024x768 --out <thu muc>
```

Dựng **2.032 ảnh trong ~12 phút** bằng **chính** CEGUI, **chính** 8 font và **chính** `StrDictionary.txt` mà
`Game.exe` nạp. Không cần server, không cần khe `Game.exe`, chạy song song với mọi nhánh. Ghép ảnh
trước|sau: `Tools/ui-fit/diff_shots.py` (đọc/ghi PNG bằng `zlib`, không cần thư viện ngoài).

**Cảnh báo khi đọc ảnh viewer:** viewer hiện **mọi** widget của layout cùng lúc, kể cả những dòng mà Lua
bình thường ẩn/phân trang (ví dụ 64 dòng phím tắt của `AcceSetup` chồng lên nhau). Chữ chồng trong ảnh
viewer **không** đồng nghĩa lỗi bố cục — đối chiếu với `overlap.csv` trước khi kết luận.

### 8.4. Không bơm được chuột/phím vào CEGUI từ ngoài tiến trình [DK]

Đo trong phiên `gui-after-1` (test06, stage `Build/world-gui/stage-ui-fit-2`):

* **Chuột `SendInput` toạ độ tuyệt đối**: con trỏ Windows tới đúng chỗ (`Cursor::Position` xác nhận
  `519,386` = client `511,355`) nhưng nút CEGUI **không sáng**, nhấp **không** mở khung.
* **Chuột delta DirectInput**: game **có** phản hồi (viền sáng xuất hiện) nhưng **lệch vị trí**; ghim về
  góc bằng nhiều delta âm **không** đưa được con trỏ của game về gốc.
* **Bàn phím scancode**: **tới được** game — `ESC` mở/đóng menu hệ thống. Nhưng mọi **phím chữ rơi vào ô
  chat** và `ESC` **không** nhả focus: gõ `c b p t u` ra đúng chuỗi `ccbbppttuc` trong ô chat.

⇒ Muốn chụp khung trong game **bắt buộc** dùng cầu nối trong tiến trình `CysUiSmokePointer` xuất từ
`UI_CEGUI.dll` (cách `CysSkillDriver`/`CysQuestDriver` làm), tức phải viết driver C++.

### 8.5. Ba phát hiện khác

1. **`cy-over` không phải "ô giữ chỗ".** Đo thật: chỉ **15 %** widget `cy-over` có `SetText` trong `.lua`
   cùng thư mục; 85 % là nhãn một dòng cao 16–22 px. Nhưng `cy_w` đo bằng NotoSansSC chứ không phải font
   936 thật của CY (giới hạn #6) ⇒ nhóm này có thể bị **phóng đại**, đừng dùng làm bằng chứng "CY cũng hỏng".
2. **Nút `WordWrap*` cao đúng 18 px** trên cả 656 chỗ, trong khi line spacing 12pt là **23 px** ⇒ không
   xuống dòng được, vẫn phải vừa một dòng.
3. **`shorten_plan.py` từng bỏ IM LẶNG các bản vá viết tay** không dựng được "ngân sách" hoặc vẫn tràn vài
   px (`manual-OVER`). 150 dòng của một lô biến mất trước khi phát hiện. Đã sửa: bản viết tay **luôn** được áp.

### 8.6. Bảng viết tắt dùng chung

Xem `Timeline/handoff/ui-fit-2.md` mục 5 (bảng đầy đủ) và `Tools/ui-fit/data/abbr_vi.tsv` (79 luật, có cột
mức 1/2/3 và ghi chú tiền lệ). Nhóm thẻ 35 px buộc dùng 2 chữ cái (`CN` Chân Nguyên, `KM` Kinh Mạch,
`TĐ` Thần Đỉnh, `BG` Bảo Giám, `TK` Thần Khí, `VH` Võ Hồn, `HA` Hiệp Ấn, `BK` Bí Kíp, `TB` Tinh Bàn,
`TV` Tài Vật, `TL` Tu Luyện) — **tooltip đầy đủ đã có sẵn** trong layout gốc của CY
(`CangPin_ShuXing_*_tips` + `SetToolTip`), nên rê chuột vẫn đọc được nghĩa.
