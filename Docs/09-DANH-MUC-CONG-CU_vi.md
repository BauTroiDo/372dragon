# 09 — Danh mục công cụ và kế hoạch tái dùng

Ngày lập: 2026-09-12. Danh mục này liệt kê những gì đã có trong `C:\TLBB\085\Tools`, `C:\TLBB\085\analysis` và `Tools\DATA NEW\DIY`, sắp theo khâu của pipeline. Nó cũng ghi rõ những công cụ còn phải viết mới trong `CY-Source\Tools`.

**Loại công cụ:**
- **G** — tái dùng chung (đọc, chuyển, kiểm).
- **O** — trình cài một lần; chỉ dùng làm khuôn.
- **T** — công cụ bên thứ ba hoặc dữ liệu.

**Môi trường chạy:**
- **Win-Py** — `C:\Program Files\Python313\python.exe`, đặt `PYTHONUTF8=1`.
- **WSL-Py** — `wsl -d TLBB python3`.
- **PS** — PowerShell 5.1.
- **C#**, **Java/Ghidra**.

## 1. Theo khâu của pipeline

### Khâu 1 — Đọc và giải nén nguồn

| Công cụ | Loại | Chạy | Việc | Ghi chú |
|---|---|---|---|---|
| `Tools\AXPDecryptor` (`AxpDecryptor.cs`) | G | C# | Đọc, giải mã và đóng lại AXP v1.1 với lớp bọc kiểu 19–25 | **Không** đọc được kiểu 1–18. CY 3.71 có 7.368 mục model (6.101 mesh, 1.267 skeleton) thuộc loại này; lấy chúng từ bản đã giải của DataCY |
| `Docs\evidence\assetinv\axp_index.py` | G | Win-Py | Đọc chỉ mục và danh sách `(list)` của 23 file `.axp` (108.726 mục) mà không giải nén | Viết ngày 12/09, port từ `AxpDecryptor.cs` |
| `Tools\AXPManager-LLT` | T | .NET GUI | "Axp Tool", không có mã và README | Không dùng trong pipeline |
| `Tools\DATA NEW\DIY` (`run_pipeline.cmd`, `jpak.py`, `extract_all.py`, `tlhash.py`, `uiml_export.py`, `luac_convert.py` + unluac, `btab_decode.py`, `jmt2png.py`, `c\tlbrute`) | G | Win-Py + Java | Giải toàn bộ client GL: JPAK, JSTR, UIML, BTAB, JMT1, Lua 5.3 | Dùng bản DIY thay cho `analysis\jpak` (bản gốc có đường dẫn cứng) |
| `analysis\utf8-baseline\manifest\loginserver_crypt.py` | G | Win-Py | Giải mã và mã hoá `LoginServer.txt` | — |
| `Tools\model-convert\dbc.py`, `analysis\utf8-baseline\manifest\dbc_convert2.py`, `column_convert2.py`, `Tools\add-phai\compare-cy-20260909\compare_tables.py` (`read_table`) | G | WSL-Py / Win-Py | Đọc và ghi bảng DBC `00CCBBDD` và bảng text | — |
| `analysis\utf8-baseline\manifest\scan_enc.py`, `Tools\rasoat-4phai\fix_cp1252_names.py` | G | Win-Py | Quét mã hoá; chữa tên file cp1252/GBK | — |

### Khâu 2 — Chỉ mục, so sánh, kiểm toàn vẹn

| Công cụ | Loại | Việc |
|---|---|---|
| `analysis\datacy-compare-2026-09-10\scripts\index_models.py` (có hàm `moji_to_gbk`), `compare_cyhj.py`, `compare_cyhj2.py` | G | Lập chỉ mục model; so sánh các nhánh **theo tên obj/mesh** |
| `analysis\full-audit-2026-09-10\`: `model_integrity.py`, `obj_integrity.py`, `table_xref_all.py`, `sortcheck.py`, `lua50check.py`, `scene_inventory3.py`, `packet_handler_audit.py`, `console.py` | G | Bộ kiểm toàn vẹn. Làm nền cho `Tests\validators` |
| `Tools\rasoat-4phai\`: `plan_resources.py`, `check_icons.py`, `fix_server_utf8_rows.py` (chế độ `check`), `npc_harness.lua` | G | Kiểm tài nguyên, icon, dòng UTF-8 lọt vào bảng server |
| `Docs\evidence\assetinv\fullscan.py`, `formats.py`, `fxkeys.py`, `inv_walk.py` | G | Kiểm kê nguồn: phiên bản mesh/skeleton, fourCC của DDS, template/keyword của effect (12/09) |
| `Docs\evidence\binlineage\inventory.py`, `expcmp.py`, `strscan.py`, `ziplist.py`, `patchdiff.py` | G | So sánh các bộ binary (PE, export, chuỗi, RTTI, zip template, diff bản vá) |

### Khâu 3 — Model, xương, animation

| Công cụ | Loại | Chạy | Việc |
|---|---|---|---|
| `Tools\model-convert\`: `lib\ogre_io.py`, `lib\dds.py`, `tlbb2gltf.py`, `gltf2tlbb.py` | G | WSL-Py | Chuyển hai chiều `.mesh`/`.skeleton` ⇄ glTF; khứ hồi khớp từng byte trên 5.450 skeleton |
| `check_model.py`, `expand_mesh_bounds.py`, `bake_bone_scale.py`, `retarget_skel.py`, `retarget_verify.py`, `ground_fix_skel.py`, `merge_tlbb_models.py`, `pose_check.py`, `scan_poses.py`, `bind_compare.py` | G | WSL-Py | Kiểm, sửa và mượn animation |
| `fxdump.py`, `fxcheck.py`, `fx_stats.py` | G | WSL-Py | In và kiểm effect/hệ hạt |
| `Tools\model-convert\jx3\jx3mount2tlbb.py` | G | WSL-Py | Chuyển model JX3/KSword3D |
| `Tools\model-convert\blender\*` (gk_prep, gk_bake_ao, gk_export…) | G | Blender 5.2 | Nướng pose, AO; xuất glb |
| `Tools\gl-skin\scene3d\glmesh.py`, `glskel.py`, `glpet2tlbb.py`, `gl2tlbb.py` | G | Win-Py | Đọc mesh/xương/animation của GL; chuyển pet và cảnh GL |
| `Tools\model-extract\extract_model.py` (có UI web) | G | Win-Py | Trích trọn một model gốc kèm 8 mục tự kiểm |
| `Tools\costume-add\costume_bake.py`, `mesh_reuv.py` | G | Win-Py | Vẽ texture theo 3D, tách UV |
| `install_goku.py`, `install_ironman*.py`, `install_glpet*.py` | O | WSL-Py | Khuôn cài đặt (check/apply/revert). Lưu ý: một số vẫn trỏ `client` gốc |

### Khâu 4 — Texture

| Công cụ | Loại | Việc | Quy tắc |
|---|---|---|---|
| `Tools\texture-upscale` (`realesrgan-ncnn-vulkan` 20220424, `texconv`, `upscale_tex.py`, `tex_index_from_log.py`, `Upscale-Tu-Log.cmd`, `Hoan-Tac-Upscale.cmd`) | G | Upscale ×2 có kiểm | Gọi từng file, tách alpha, loại texture UI (tài liệu 08, mục 3.5) |
| `Tools\model-convert\lib\dds.py` | G | Giải mã và nén DXT1 kèm mipmap | — |
| `tone_match.py`, `boost_tex.py`, `apply_ao.py` | G | Đo tông màu của game; chỉnh texture; nhân AO | — |

### Khâu 5 — Bản đồ

| Công cụ | Loại | Việc |
|---|---|---|
| `Tools\map-convert\`: `lib\mapfmt.py`, `obj2map.py`, `make_navmesh.py`, `paint_terrain.py`, `make_minimap.py`, `map_install.py`, `map_verify.py`, `add_water_grass.py`, `probe\*` (có `path_dllinv.py`) | G | Toàn bộ đường ống map (WSL-Py); khớp byte trên 499 map |
| `lol_*` | O | Riêng cho Summoner's Rift |
| `Tools\gl-skin\scene3d\gl2tlbb.py`, `preview_scene.py` | G | Cao độ `.Block` và instance của GL; render thử cảnh đã cài |
| `Tools\map-editor` | — | Mới có kế hoạch; chưa có mã |

### Khâu 6 — Giao diện

| Công cụ | Loại | Việc |
|---|---|---|
| `Tools\gl-skin\build_gl_skin.py` | O/G | Sinh atlas, imageset và looknfeel GL (68 look). Sửa bằng Edit/Write, không qua heredoc |
| `Tools\gl-skin\relayout\preview_ui.py`, `layout_tool`, `apply_gl_layout` | G | Xem trước layout ngoại tuyến (đúng font/ảnh/Lua state); sửa layout có `--dry`/`--revert` |
| `Tools\ui-relayout\` (`scan_static.py`, `relayout.py` chế độ an toàn, `apply_shortlist.py`) | G | Kẻ lại khung an toàn |
| `Tools\fonts`, `Tools\Noto_Sans_SC`, `Tools\Schema` | T | Font và lược đồ |

### Khâu 7 — Bảng, nội dung, dịch thuật

| Công cụ | Loại | Việc |
|---|---|---|
| Các trình cài 2026: `costume-add(-2026)`, `cyhj-add-2026`, `decoweapon-add-2026`, `hair-add-2026`, `mount-add-2026`, `ornament-add`, `pet-add-2026`, `title-add`, `add-phai` (CY4) | O | Mỗi trình cài có check/apply/verify/revert và backup. Là khuôn cho trình cài hợp nhất `Tools\pipeline\install.py`. `make_pack.py` dùng chung được |
| `Tools\costume-add\add_costume.py`, `shop_front.py`, `_hot_reload_sharetable.lua` | G | Thêm thời trang, bày shop, nạp nóng |
| `Tools\gmtool\` (`gen_gm_index.py`, `gen_scene_index_server.py`, `gen_equip_rules.lua`) | G | Chỉ mục GM Tool. **Chỉ mục cảnh phải sinh theo ID cảnh của server** |
| `Tools\add-phai\sort_tables_by_id.py`, `widen_actionsetline.py` | G | Sắp bảng tăng dần; nới ActionSetLine |
| `analysis\translation\` (`run_all.py`, `dbc_translate.py`, `gen_wire_names.py`, `_scan\audit.py`, `translate_long.py`, `translation.db`), `Tools\TLBBTranslationStudioPro\tlbb_tm.db` | G | Dịch Trung→Việt. Đo tiến độ bằng `_scan\audit.py`, **không tin `run_all.py status`** |

### Khâu 8 — Giao thức và server

| Công cụ | Loại | Việc |
|---|---|---|
| `Tools\stress-test\tlbb_sim\` (7.726 dòng Python: codec, gói tin, A* trên navmesh, seeder, perception, goals, arena, fleet) | G | Client headless nói giao thức skynet; khung cho test tích hợp |
| `Tools\stress-test\_capture\sniffer.py`, `decode.py`, `PROTOCOL_SPEC_vi.md` | G | Bắt và giải gói; đặc tả khung gói |
| `Tools\stress-test\TLBB-Launcher.ps1` | G | Launcher 3 tab (Máy chủ / Simulator / Cấu hình) |
| `analysis\server-check\skynet_stat.py` | G | Thống kê server |
| `CY-Source\Tools\protocol\specgen.py` (+ `validate_capture.py`, `match085.py`, `crosscheck_sim.py`, `codegen_cpp.py`) | G | **Đã có (12/09).** Sinh đặc tả `Registry\protocol\packets.yaml` từ codec Lua sống của server. `split_packet.py` mà chú thích server nhắc tới không còn tồn tại |
| `wsl\Start-TLBB.cmd`, `Stop-TLBB.cmd`, `Status-TLBB.cmd` | G | Vận hành server |

### Khâu 9 — Dịch ngược và kiểm binary

| Công cụ | Loại | Việc |
|---|---|---|
| Ghidra 12.1.3 (`Tools\ghidra`), project: `analysis\ghidra\game-exe-proj\game_exe.gpr`, `headless-projects\{cegui, pathlib, tlgl, tlgl32, tlgl_upd, utf8_client}.gpr`, `analysis\graphics-overhaul\ghidra\proj\gfx.gpr` | G | Nguồn đặc tả cho pha E2/G1. `game_exe.gpr` phân tích Game.exe **trước** khi vá ActionSetLine |
| Script Java: `DumpPacketById`, `FindStrRefs`, `FindScalarUsers`, `DumpVtableAround`, `ResolveVtable.java`, `DumpFuncs.java`, `DumpCallers.java`, `DumpStringXrefs.java`, `DumpFnsTo.java` | G | Chạy headless nhanh bằng `-process X -noanalysis` |
| Skill `headless-ghidra*`, `binary-triage`, `deep-analysis`; `Tools\ghidra-agent-cli` 1.8.0; ReVa MCP | G | ReVa **không kết nối được** trong phiên 12/09 (CONNECT_TIMEOUT). Cần khởi động lại hoặc kiểm tra trước khi dùng |
| `analysis\ghidra\pathlib-out\all.c` | G | Bản dịch ngược PathLib; làm đặc tả khi viết lại PathLib |
| Các script vá `patch_*.py` (utf8-baseline, graphics-overhaul, add-phai) | G | Tài liệu tham chiếu: mỗi bản vá là một tính năng phải làm lại trong mã (tài liệu 08, mục 10) |
| LLVM 22 (`llvm-readobj`, `llvm-objdump`, `llvm-strings`, `clang-cl`) | T | Đọc PE, import/export, chuỗi |
| CodeGraph 0.20.1 + `Tools\Sync-CodeGraphSources.ps1` | G | Đồ thị mã nguồn. Phải thêm `CY-Source\Src` vào gương index (tài liệu 04, mục 2.4) |
| `Tools\zig-0.16.0`, `Tools\unluac` | T | Biên dịch C chéo nền; dịch ngược Lua 5.x |

### Khâu 10 — Kiểm thử và vận hành client

| Công cụ | Loại | Việc |
|---|---|---|
| `Tools\gl-skin\Chup-ManHinh-Game.ps1` (PrintWindow, không cần cửa sổ nổi), `Game-Input.ps1` | G | Chụp màn hình và gửi phím cho client. Là nền của bộ đối chứng ảnh |
| `analysis\graphics-overhaul\presets\Doc-Log-Do-Hoa.cmd`, `hdr_tune.py`, `Doi-Do-Hoa.cmd` | G | Đọc log đồ hoạ; chỉnh `.newhdrbloom` |
| `Tools\diag-ride-pk` | O | Chẩn đoán lỗi cưỡi thú + PK (log `DIAG_RIDE_PK` đang bật) |

## 2. Công cụ phải viết mới trong `CY-Source\Tools`

| Đường dẫn (dự kiến) | Việc | Dựa trên |
|---|---|---|
| `Tools\pipeline\ingest.py` | Đọc từng nguồn (thư mục rời, AXP, JPAK), chuẩn hoá tên (GBK ⇄ mojibake), cắt đệm 0 ở cuối file (DataCY/CYHJ) theo kích thước trong `(list)` của CY Game, sinh manifest (đường dẫn, kích thước, SHA-256, nguồn) | `axp_index.py`, `inv_walk.py`, `index_models.py` |
| `Tools\pipeline\registry.py` | Sổ ID: cấp ID mới theo dải, kiểm va chạm với cả bảng client lẫn server, mọi Type | Quy tắc tài liệu 05, mục 4 |
| `Tools\pipeline\merge.py` | Chọn bản chuẩn theo luật; báo xung đột; ghi nguồn gốc từng tài sản | Tài liệu 05, mục 3 |
| `Tools\pipeline\tables.py` | Ánh xạ cột CY/JD → HJ; ghi bảng client (UTF-8 thân, GBK khoá, CRLF, sắp tăng) và bảng server (GBK); kiểm cặp client–server | `compare_tables.py`, `column_convert2.py` |
| `Tools\pipeline\install.py` | Cài nội dung đã chọn vào `client_GL` (bản chơi hiện tại) và server WSL, có check/apply/verify/revert | Khuôn các trình cài 2026 |
| `Tools\pipeline\package_axp.py` | Đóng gói AXP v1.1 cho `Build\Packs` | `AxpDecryptor.cs` |
| `Tests\validators\*` | Gộp bộ kiểm full-audit và thêm: parser effect nghiêm ngặt, tham chiếu template/texture-slot, DDS và sRGB, xương/submesh, bất biến `.path`, đăng ký scene, cặp bảng client–server | Tài liệu 07, mục 3 |
| `Tools\protocol\specgen.py`, `codegen_cpp.py`, `codegen_py.py` | Sinh đặc tả giao thức (YAML) từ `packet_ids.lua` + `packet_types` + `packet_domains`; từ đó sinh codec C++ cho client mới và Python cho `tlbb_sim` | Tài liệu 06 |
| `Tools\re\` | Script Ghidra lấy đặc tả: dump vtable có tên slot; dump bảng đăng ký API Lua của Game.exe B (tên → địa chỉ hàm); dump danh sách lớp gói | `DumpVtableAround`, `ResolveVtable.java` |
| `Tests\oracle\` | Chụp và so ảnh (SSIM) giữa B và client mới trên cùng cảnh/camera; so log | `Chup-ManHinh-Game.ps1`, `preview_scene.py` |

## 3. Quy tắc dùng công cụ

1. **Không sửa công cụ gốc** trong `C:\TLBB\085\Tools` chỉ vì CY-Source cần. Muốn đổi thì chép sang `CY-Source\Tools` (ghi nguồn gốc trong commit) hoặc gọi đường dẫn gốc ở chế độ chỉ đọc.
2. Mọi công cụ **có ghi dữ liệu** phải có đủ bốn chế độ `check`, `apply`, `verify`, `revert`, và phải sao lưu trước khi ghi.
3. Công cụ xử lý file GBK phải làm **ở mức byte**, không đi qua `errors='replace'` (tài liệu 08, mục 1.2).
4. Kết quả của công cụ AI hay decompile chỉ là đầu mối cho tới khi có xref/offset làm bằng chứng (`CLAUDE.md`).
