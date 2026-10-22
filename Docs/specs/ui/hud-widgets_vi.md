# HUD widgets — các kiểu Falagard GL còn thiếu cho HUD, minimap, menu hệ thống và 129 cửa sổ

Agent `hud-widgets`, 14/09/2026. Worktree `Build\wt-hud-widgets` (nhánh `hud-widgets`). Bằng chứng: `Build\Logs\2026-09-14-hud-widgets\`.

## 1. Vấn đề

`Tools\game\stage_game.py` lọc khỏi `InterfaceEx.txt` mọi cửa sổ mà layout dùng một kiểu Falagard chưa đăng ký trong `CEGUIFalagard.dll` (nếu không lọc, `Cloud_SelectServer` ném ngoại lệ và Game.exe thoát). Với DLL 13/09 danh sách này là **129 cửa sổ**:

- 118 cửa sổ dùng 9 kiểu chưa có: `Falagard/NotSuperList` (96 cửa sổ; 116 chỗ dùng trong 100 layout), `Falagard/NotSuperListItem` (104 cửa sổ; 159 chỗ dùng), `Falagard/PS` (5), `Falagard/ListBoxEx` (4), `Falagard/AchievementWindow` (2), `Falagard/ScrollInfo`, `Falagard/ScrollInfoFixed`, `Falagard/DragContainer`, `Falagard/DragDropTarget` (UnionFrame, 30 chỗ dùng mỗi kiểu).
- 11 cửa sổ tooltip dùng `Falagard/SuperTooltip/ResizeText`: kiểu **đã có** nhưng regex của `registered_window_types` (`Falagard/[A-Za-z0-9_]+`) không nhận tên có hai dấu `/` nên bị lọc oan. Đã sửa regex (`(?:/[A-Za-z0-9_]+)?`).
- Hai kiểu nữa được scheme ánh xạ nhưng chưa layout nào dùng trực tiếp (chỉ tạo lúc chạy qua `ChildItem` của AchievementWindow / tooltip): `Falagard/SuperBarButton` (TLBB_SweepButton), `Falagard/TripperTooltip` (TLBB_TripperTooltip). Cũng đã cài.

Census CysUiViewer trước khi sửa (`census-before`, 1.214 layout Canonical): 1.062 vẽ được, **30 crash** (19 `ComplexWindow::ActionButtonSize` → `requestRedraw` trên parent null; 11 `ResizeText` → `Rect::offset` vì ảnh khung null), **122 không nạp được**, 1.338 dòng `(Error)`, 38 thuộc tính thiếu.

## 2. Bảng kê 129 cửa sổ ↔ kiểu thiếu

| # | ID | Cửa sổ (InterfaceEx) | Layout | Kiểu thiếu (WindowType → base) |
|---|---|---|---|---|
| 1 | 2 | Agname | Agname/Agname.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon5 -> Falagard/NotSuperListItem |
| 2 | 23 | Pet | Pet/Pet.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 3 | 60 | Friend | Friend/friend.layout.xml | TLBB_IMListBoxCommon -> Falagard/ListBoxEx |
| 4 | 82 | ScrollInfo | ScrollInfo/ScrollInfo.layout.xml | TLBB_ScrollInfo -> Falagard/ScrollInfo |
| 5 | 116 | SelectHairstyle | SelectHairstyle/SelectHairstyle.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 6 | 128 | TargetPet | TargetPet/TargetPet.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 7 | 140 | OtherPet | OtherPet\OtherPet.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 8 | 152 | SelectFacestyle | SelectFacestyle\SelectFacestyle.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 9 | 165 | SelRecycleItem | SelectRecycleItem\SelectRecycleItem.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 10 | 182 | SelectHeadstyle | SelectHeadstyle\SelectHeadstyle.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 11 | 215 | PlayerList | PlayerList/PlayerList.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon5 -> Falagard/NotSuperListItem |
| 12 | 222 | YuanbaoShop | YuanbaoShop\YuanbaoShop.layout.xml | TLBB_ScrollInfoFixed -> Falagard/ScrollInfoFixed |
| 13 | 236 | TargetPet2 | TargetPet2/TargetPet2.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 14 | 240 | CampaignTrack | CampaignTrack\CampaignTrack.layout.xml | TLBB_ListBoxTransparent -> Falagard/ListBoxEx |
| 15 | 241 | MissionTrack | MissionTrack\MissionTrack.layout.xml | TLBB_ListBoxTransparent -> Falagard/ListBoxEx |
| 16 | 342 | HerosReturns_Mission | HerosReturns_Mission/HerosReturns_Mission.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon -> Falagard/NotSuperListItem |
| 17 | 343 | HerosReturns_Shop | HerosReturns_Shop/HerosReturns_Shop.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon2 -> Falagard/NotSuperListItem |
| 18 | 350 | SweepAll | SweepAll/SweepAll.layout.xml | TLBB_AchievementWindow -> Falagard/AchievementWindow |
| 19 | 364 | RongYuTitle | RongYuTitle/RongYuTitle.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 20 | 368 | SongliaoWarOver | SongliaoWarOver/SongliaoWarOver.layout.xml | TLBB_AchievementWindow -> Falagard/AchievementWindow |
| 21 | 379 | WuhunTupuActive | WuhunTupuActive/WuhunTupuActive.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 22 | 381 | WuhunTupuStudy | WuhunTupuStudy/WuhunTupuStudy.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 23 | 382 | WuhunTupuJinjie | WuhunTupuJinjie/WuhunTupuJinjie.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 24 | 383 | WuhunJian | WuhunJian/WuhunJian.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 25 | 388 | ZLHeroMeeting_Join | ZLHeroMeeting_Join/ZLHeroMeeting_Join.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 26 | 391 | ZhouHuoYue | ZhouHuoYue/ZhouHuoYue.layout.xml | TLBB_NotSuperList1 -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 27 | 415 | QinChiDao | QinChiDao/QinChiDao.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 28 | 425 | Kaiyanxi | Kaiyanxi/Kaiyanxi.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon -> Falagard/NotSuperListItem |
| 29 | 457 | HuaShanLunJian_TopList | HuaShanLunJian_TopList/HuaShanLunJian_TopList.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon1 -> Falagard/NotSuperListItem |
| 30 | 459 | FriendChat | FriendChat/FriendChat.layout.xml | TLBB_IMListBoxCommon -> Falagard/ListBoxEx |
| 31 | 481 | NewExterior_Facestyle | NewExterior_Facestyle\NewExterior_Facestyle.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 32 | 482 | NewExterior_HairStyle | NewExterior_HairStyle\NewExterior_HairStyle.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 33 | 483 | NewExterior_PlayerFrame | NewExterior_PlayerFrame\NewExterior_PlayerFrame.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 34 | 484 | NewExterior_Ride | NewExterior_Ride\NewExterior_Ride.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 35 | 485 | NewExterior_DressBox | NewExterior_DressBox\NewExterior_DressBox.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 36 | 492 | PetSoul | PetSoul\PetSoul.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem; TLBB_NotSuperListItemCommon4 -> Falagard/NotSuperListItem |
| 37 | 497 | PetSoul_Handbook | PetSoul_Handbook\PetSoul_Handbook.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 38 | 529 | MenPaiFirstOne_Vote | MenPaiFirstOne_Vote/MenPaiFirstOne_Vote.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 39 | 537 | PetSoul_JiHuo | PetSoul_JiHuo\PetSoul_JiHuo.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 40 | 538 | NewExterior_PetSoul | NewExterior_PetSoul\NewExterior_PetSoul.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 41 | 541 | NewExterior_Weapon | NewExterior_Weapon\NewExterior_Weapon.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 42 | 542 | NewExterior_Weapon_Levelup | NewExterior_Weapon_Levelup\NewExterior_Weapon_Levelup.layout.xml | TLBB_NotSuperList1 -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 43 | 547 | HerosReturns_Horizons | HerosReturns_Horizons/HerosReturns_Horizons.layout.xml | TLBB_NotSuperList1 -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon8 -> Falagard/NotSuperListItem |
| 44 | 554 | MenPaiFirstOne_BattleBet | MenPaiFirstOne_BattleBet/MenPaiFirstOne_BattleBet.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 45 | 560 | MenPaiWar_TopList | MenPaiWar_TopList/MenPaiWar_TopList.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 46 | 562 | ShaXing_BossChoice | ShaXing_BossChoice/ShaXing_BossChoice.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 47 | 575 | ShaXing_TopList | ShaXing_TopList/ShaXing_TopList.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 48 | 584 | NoDiffMatch_TeamInfo | NoDiffMatch_TeamInfo/NoDiffMatch_TeamInfo.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon5 -> Falagard/NotSuperListItem |
| 49 | 604 | Examination_TopList | Examination_TopList/Examination_TopList.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon1 -> Falagard/NotSuperListItem |
| 50 | 610 | FujiatianxiaTopList | FujiatianxiaTopList/FujiatianxiaTopList.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 51 | 623 | Redenvelope | Redenvelope/Redenvelope.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 52 | 627 | Redenvelope_HistoryList | Redenvelope_HistoryList/Redenvelope_HistoryList.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 53 | 630 | Lingyu | Lingyu/Lingyu.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 54 | 634 | Profile_TagChoose | Profile_TagChoose/Profile_TagChoose.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 55 | 635 | Profile_RideChoose | Profile_RideChoose/Profile_RideChoose.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 56 | 636 | Profile_WeaponChoose | Profile_WeaponChoose/Profile_WeaponChoose.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 57 | 638 | ShengWang_Pass | ShengWang_Pass/ShengWang_Pass.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperList1 -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon10 -> Falagard/NotSuperListItem; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 58 | 640 | ShengWangAll | ShengWangAll/ShengWangAll.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon10 -> Falagard/NotSuperListItem |
| 59 | 643 | TargetLingyu | TargetLingyu/TargetLingyu.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 60 | 646 | Profile_DressChoose | Profile_DressChoose/Profile_DressChoose.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 61 | 659 | Cloud_SelectServer | Cloud_SelectServer/Cloud_SelectServer.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 62 | 672 | Biwuzhaoqin_Vote | Biwuzhaoqin_Vote/Biwuzhaoqin_Vote.layout.xml | TLBB_Affection_NotSuperList -> Falagard/NotSuperList; TLBB_Affection_NotSuperListItemCommon_Small -> Falagard/NotSuperListItem |
| 63 | 674 | CoupleZone | CoupleZone/CoupleZone.layout.xml | TLBB_NotSuperListItemCommon5 -> Falagard/NotSuperListItem |
| 64 | 717 | DoublePK_TopList | DoublePK_TopList/DoublePK_TopList.layout.xml | TLBB_Affection_NotSuperList -> Falagard/NotSuperList; TLBB_Affection_NotSuperListItemCommon_Large -> Falagard/NotSuperListItem |
| 65 | 718 | DoublePK_TopListAward | DoublePK_TopListAward/DoublePK_TopListAward.layout.xml | TLBB_Affection_NotSuperListItemCommon_Large -> Falagard/NotSuperListItem |
| 66 | 719 | DoublePlay_TopList | DoublePlay_TopList/DoublePlay_TopList.layout.xml | TLBB_Affection_NotSuperList -> Falagard/NotSuperList; TLBB_Affection_NotSuperListItemCommon_Large -> Falagard/NotSuperListItem |
| 67 | 720 | DoublePlay_TopListAward | DoublePlay_TopListAward/DoublePlay_TopListAward.layout.xml | TLBB_Affection_NotSuperListItemCommon_Large -> Falagard/NotSuperListItem |
| 68 | 728 | Couples_Vault | Couples_Vault/Couples_Vault.layout.xml | TLBB_Affection_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 69 | 740 | Makefriends_Activity_Watch2 | Makefriends_Activity_Watch2/Makefriends_Activity_Watch2.layout.xml | TLBB_Affection_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 70 | 751 | UnionFrame | UnionFrame/UnionFrame.layout.xml | TLBB_UnionDragItem -> Falagard/DragContainer; TLBB_UnionDragTarget -> Falagard/DragDropTarget |
| 71 | 765 | HuaShanLunJian_TeamInfo | HuaShanLunJian_TeamInfo/HuaShanLunJian_TeamInfo.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon5 -> Falagard/NotSuperListItem |
| 72 | 772 | PetSoul_RanSe | PetSoul_RanSe/PetSoul_RanSe.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 73 | 785 | PetExterior_Change | PetExterior_Change/PetExterior_Change.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon -> Falagard/NotSuperListItem |
| 74 | 787 | YanMenMeng_MengYan | YanMenMeng_MengYan/YanMenMeng_MengYan.layout.xml | Falagard/PS -> Falagard/PS |
| 75 | 807 | ShenBingFuBen | ShenBingFuBen/ShenBingFuBen.layout.xml | Falagard/PS -> Falagard/PS |
| 76 | 812 | Fashion_Auction | Fashion_Auction\Fashion_Auction.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 77 | 872 | Phoenix_Enter | Phoenix_Enter/Phoenix_Enter.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon5 -> Falagard/NotSuperListItem |
| 78 | 889 | ShaXing_KF_TopList | ShaXing_KF_TopList/ShaXing_KF_TopList.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 79 | 892 | DWJinJie_Change | DWJinJie_Change/DWJinJie_Change.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon -> Falagard/NotSuperListItem |
| 80 | 893 | SelfDWJinJie | SelfDWJinJie/SelfDWJinJie.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 81 | 895 | DWJinJie_TeXingShengJi | DWJinJie_TeXingShengJi/DWJinJie_TeXingShengJi.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 82 | 897 | TargetDWJinJie | TargetDWJinJie/TargetDWJinJie.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 83 | 902 | JiangHuZhi_PaidChoices | JiangHuZhi_PaidChoices\JiangHuZhi_PaidChoices.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 84 | 904 | SelfDWJinJie_Packet | SelfDWJinJie_Packet/SelfDWJinJie_Packet.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon -> Falagard/NotSuperListItem |
| 85 | 908 | NewExterior_Widget | NewExterior_Widget/NewExterior_Widget.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 86 | 910 | HuaShanLunJian_TopList2 | HuaShanLunJian_TopList2/HuaShanLunJian_TopList2.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon1 -> Falagard/NotSuperListItem |
| 87 | 934 | DaHua_PKWarning | DaHua_PKWarning\DaHua_PKWarning.layout.xml | Falagard/PS -> Falagard/PS |
| 88 | 946 | HuaShanLunJian_TeamInfo2 | HuaShanLunJian_TeamInfo2/HuaShanLunJian_TeamInfo2.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon5 -> Falagard/NotSuperListItem |
| 89 | 965 | CangBao_GuoTu | CangBao_GuoTu/CangBao_GuoTu.layout.xml | Falagard/PS -> Falagard/PS |
| 90 | 972 | Levelup_TopList | Levelup_TopList/Levelup_TopList.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon9 -> Falagard/NotSuperListItem |
| 91 | 979 | Frozen_Answer_List | Frozen_Answer_List/Frozen_Answer_List.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon1 -> Falagard/NotSuperListItem |
| 92 | 981 | NewExterior_Headdress | NewExterior_Headdress/NewExterior_Headdress.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 93 | 987 | Frozen_GeCao_ZhanKuang | Frozen_GeCao_ZhanKuang/Frozen_GeCao_ZhanKuang.layout.xml | TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 94 | 989 | Frozen_GeCao_PersonalTopList | Frozen_GeCao_PersonalTopList/Frozen_GeCao_PersonalTopList.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon5 -> Falagard/NotSuperListItem |
| 95 | 1004 | Frozen_PVPResult | Frozen_PVPResult/Frozen_PVPResult.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 96 | 1005 | Frozen_PVPScore | Frozen_PVPScore/Frozen_PVPScore.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 97 | 1029 | Frozen_ActivityRaiders | Frozen_ActivityRaiders/Frozen_ActivityRaiders.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon1 -> Falagard/NotSuperListItem |
| 98 | 1036 | YearEndBonus_Preview | YearEndBonus_Preview/YearEndBonus_Preview.layout.xml | TLBB_NotSuperList1 -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon2 -> Falagard/NotSuperListItem |
| 99 | 1037 | YearEndBonus_Select | YearEndBonus_Select/YearEndBonus_Select.layout.xml | TLBB_NotSuperList1 -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon1 -> Falagard/NotSuperListItem |
| 100 | 1055 | Kunwu_PVPScore | Kunwu_PVPScore/Kunwu_PVPScore.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 101 | 1059 | KunWu_Expedition_Main | KunWu_Expedition_Main/KunWu_Expedition_Main.layout.xml | TLBB_NotSuperList1 -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon4 -> Falagard/NotSuperListItem; TLBB_NotSuperListItemCommon5 -> Falagard/NotSuperListItem |
| 102 | 1060 | KunWu_Expedition_Change | KunWu_Expedition_Change/KunWu_Expedition_Change.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon5 -> Falagard/NotSuperListItem |
| 103 | 1061 | KunWu_Expedition_Result | KunWu_Expedition_Result/KunWu_Expedition_Result.layout.xml | TLBB_NotSuperList1 -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon4 -> Falagard/NotSuperListItem |
| 104 | 1062 | KunWu_Expedition_AllQueue | KunWu_Expedition_AllQueue/KunWu_Expedition_AllQueue.layout.xml | TLBB_NotSuperList1 -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon4 -> Falagard/NotSuperListItem |
| 105 | 1106 | Kunwu_GiftBox | Kunwu_GiftBox/Kunwu_GiftBox.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 106 | 1130 | Self_Auction | Self_Auction/Self_Auction.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon1 -> Falagard/NotSuperListItem |
| 107 | 1137 | XinfuFanli_Shop | XinfuFanli_Shop/XinfuFanli_Shop.layout.xml | TLBB_NotSuperList1 -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 108 | 1138 | XiariZhanling | XiariZhanling/XiariZhanling.layout.xml | TLBB_NotSuperList1 -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 109 | 1169 | Peak_WarmUp_Warning | Peak_WarmUp_Warning/Peak_WarmUp_Warning.layout.xml | Falagard/PS -> Falagard/PS |
| 110 | 1178 | Confraternity_FightGroupTopList | Confraternity_FightGroupTopList/Confraternity_FightGroupTopList.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon1 -> Falagard/NotSuperListItem |
| 111 | 1179 | Thanksgiving_FeedBack | Thanksgiving_FeedBack/Thanksgiving_FeedBack.layout.xml | TLBB_NotSuperListItemCommon1 -> Falagard/NotSuperListItem |
| 112 | 1186 | Frozen_Dance_ZhanKuang | Frozen_Dance_ZhanKuang/Frozen_Dance_ZhanKuang.layout.xml | TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 113 | 1196 | PetTuJian | PetTuJian/PetTuJian.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 114 | 1230 | Stall_SelectRecycleItem | Stall_SelectRecycleItem\Stall_SelectRecycleItem.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 115 | 1237 | MonthPVE_TopList | MonthPVE_TopList/MonthPVE_TopList.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 116 | 1244 | KuafuPK_Info | KuafuPK_Info/KuafuPK_Info.layout.xml | TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 117 | 1246 | KuafuPK_Result | KuafuPK_Result/KuafuPK_Result.layout.xml | TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |
| 118 | 1254 | ZhengTaoPVP_TopList | ZhengTaoPVP_TopList/ZhengTaoPVP_TopList.layout.xml | TLBB_NotSuperList -> Falagard/NotSuperList; TLBB_NotSuperListItemCommon3 -> Falagard/NotSuperListItem |

Tổng: 118 cửa sổ (DLL 13/09 chưa có 9 kiểu). Thêm 11 cửa sổ tooltip dùng `Falagard/SuperTooltip/ResizeText` mà regex cũ của stage_game.py không nhận (tên có hai dấu `/`) = 129 cửa sổ bị lọc.


Thuộc tính mà các layout GL đặt lên từng kiểu thiếu (đếm từ 1.214 layout Canonical, `missing-types-before.json`):

| Kiểu | Thuộc tính (số lần) |
|---|---|
| `Falagard/NotSuperList` | UnifiedSize (116), UnifiedPosition (116), AlwaysOnTop (94), MultiColumn (67), MouseRButtonHollow (62), SelectMode (60), VScrollMode (30), Font (3), Visible (2) |
| `Falagard/NotSuperListItem` | UnifiedSize (159), UnifiedPosition (159), RiseOnClick (27), AlwaysOnTop (1) |
| `Falagard/DragDropTarget` | UnifiedPosition (30), UnifiedSize (30) |
| `Falagard/DragContainer` | UnifiedPosition (30), UnifiedSize (30) |
| `Falagard/PS` | UnifiedSize (5), UnifiedPosition (5), Effect (5), MouseRButtonHollow (5), MouseMoveHollow (5), MouseLButtonHollow (5), MouseHollow (5), EffectAuto (5), Visible (2) |
| `Falagard/ListBoxEx` | UnifiedPosition (5), UnifiedSize (5), ForceHorzScrollbar (2), MouseLButtonHollow (2), MouseRButtonHollow (2) |
| `Falagard/ScrollInfoFixed` | CoolDown (1), MouseHollow (1), MouseMoveHollow (1), MoveSpeed (1), ScrollTime (1), UnifiedPosition (1), UnifiedSize (1), Font (1) |
| `Falagard/ScrollInfo` | UnifiedPosition (1), UnifiedSize (1), CoolDown (1), MoveSpeed (1), ScrollTime (1), MouseHollow (1), MouseMoveHollow (1) |
| `Falagard/AchievementWindow` | UnifiedPosition (2), UnifiedSize (2), MouseRButtonHollow (1), AlwaysOnTop (1) |

## 3. Ngữ nghĩa từng kiểu theo B (client_GL)


| Kiểu | Ngữ nghĩa theo B | Bằng chứng | Cài đặt (file) |
|---|---|---|---|
| `Falagard/NotSuperList` | Danh sách các cửa sổ con. Item khai báo trong layout là **mẫu** (không vẽ); Lua `list:AddChild("Mẫu")` nhân bản mẫu (thuộc tính, `<Event>`, cây con) với hậu tố `__auto_%d__`, xếp theo `MultiColumn` cột trong `__auto_parent__`, cuộn bằng `__auto_vscrollbar__` (NamedArea `ClientRect`/`ClientRectVScroll`). `SelectMode` None/Single/Multi, `VScrollMode` Hide/Show/Auto (layout GL còn ghi ""/"True"), `ChildrenHoverSection` (mặc định `DefaultHoverSection`). Sự kiện layout dùng: `ElementLClick` (9), `Clicked` (5). | Export `FalagardNotSuperList::{AddChild, EraseChild, Clear, GetListSize, GetListItem, SetSelected, GetSelected, RefreshLayout, layoutChildItems, configureScrollbars, pushVirtualChildWindow, popVirtualChildWindow, pushVirtualChildProperty, createWindowR, isVirtualChild, handleItemLClickEvent, Get/SetVertScrollbarPosition, onMouseWheel}`; chuỗi mô tả "child items select mode, include None/Single/Multi", "vertical scrollbar show mode, include Hide/Show/Auto", `MultiColumn`, `__auto_%d__`; Lua `MetaTable_Control_NotSuperList` (AddChild, Clear, GetListItemAt, GetListItemCount, GetSelected, Set/GetScrollPosition, RefreshLayout, SetScrollPosition4Index); 143 lần `:AddChild(` trong Lua GL. | `FalagardNotSuperList.h/.cpp` |
| `Falagard/NotSuperListItem` | Một dòng của NotSuperList: vẽ `EnabledBackground`, khi hover/được chọn vẽ thêm ImagerySection hover; `MapChildName(tên gốc)` → tên con đã nhân bản (Lua `GetSubItem`, 1.696 lần); `SetChildItemEvent` (Lua `SetSubItemEvent`). | Export `FalagardNotSuperListItem::{MapChildName, SetChildItemEvent, setSelected, getSelected, setHoverSection, updateHoverState}`; look `TLBB_NotSuperListItemCommon*` (section `background`, `DefaultHoverSection`). | cùng file |
| `Falagard/SuperTooltip/ResizeText` | Phần chữ tự co giãn của SuperTooltip; GL thêm `MaxWidth`/`MinWidth` (pixel; 20 layout ghi cả hai, thường bằng nhau = 202). Không có ảnh khung Top/Middle/Bottom thì vẽ StateImagery `Enabled` của look (`TLBB_Look_ResizeTextFrame`). | Chuỗi `MaxWidth`/`MinWidth` cạnh SelfFitWindow; crash 0.85 tại `Rect::offset` khi ảnh null (11 layout). | `FalSuperTooltip.h/.cpp` (sửa) |
| `Falagard/PS` | Cửa sổ chứa hiệu ứng hạt của game: `Effect` (tên trong EffectFolder), `EffectAuto` (tự tạo/chạy khi hiện). Bản thân không vẽ; phát sự kiện `EffectShown`/`EffectHidden`/`EffectPlay` để lớp game vẽ hiệu ứng lên khung (cùng cách tách như MeshWindow). Lua `MetaTable_Control_Effect`: `playEffect`, `replayEffect`. | Export `FalagardParticleSystem::{setEffectName, getEffect, createEffect, autoCreateEffect, play, rePlay, setAuto, d_EffectAuto, onShown/onHidden/onParentShown/onParentHidden}`, chuỗi `Falagard/PS`, `EffectAuto`. | `FalagardParticleSystem.h/.cpp` |
| `Falagard/ListBoxEx` | Listbox có nút theo dòng (mắt/đóng/thiết lập, ảnh chân dung bạn bè). Lua: `AddItemEx(WithoutLayout)(text, id, type, màu, căn)`, `AddFriendItemExWithoutLayout(..., face)`, `DelItemEx`, `ClearListBoxEx`, `RequestLayout`, `GetClickedButtonItem`, `SetVScrollbarAlpha`, `GetItemNumByMissionId`; sự kiện `ButtonClickedForEye/Close/Set/Sns/Sjsl`, `ItemSelectionByRButton`. Ánh xạ type→nút không có trong chuỗi; suy luận: type 3 = dòng tiêu đề (mắt + đóng), type 4 = bạn bè (nút thiết lập), có face → chân dung. | Export `FalagardListBoxEx::{AddItemEx, AddItemExWithOutLayout, RemoveItemEx, ResetListEx, RequestLayOut, updateLayout, GetClickedButtonItem, SetVScrollbarAlpha, ShowButton, hideAllButtons, Tick}`, chuỗi `__button__eye__%02d`+`TLBB_Look_SingleTrackOpen`, `__button__close__%02d`+`TLBB_Look_SingleTrackClose`, `__button__set__%02d`+`TLBB_Look_FriendSet`, `__image__portrait__%02d`. | `FalagardListBoxEx.h/.cpp` |
| `Falagard/ScrollInfo` / `ScrollInfoFixed` | Băng thông báo chạy chữ đầu màn hình: `CoolDown` (giây giữa hai thông báo), `MoveSpeed` (px/giây), `ScrollTime`, font = `Font` của cửa sổ. ScrollInfo chạy chữ từ phải sang trái; ScrollInfoFixed giữ chữ giữa khung `ScrollTime` giây (0 → 3 giây). Lua `SetScrollInfo(text)`, `SetScrollInfoFixed(text)`, `ClearInfo`. | Export `FalagardScrollInfo::{setWaitingInfo, setWaitingInfoFirst, ResetIt, hideAll, showAll, setLife, setInfoFont, setCoolDown, setMoveSpeed, setScrollTime, isUpdateRequire}`; look `TLBB_Look_ScrollInfo` (`ChildItem key:Child name:TLBB_ChatBoard`). | `FalagardScrollInfo.h/.cpp` |
| `Falagard/AchievementWindow` | Danh sách cuộn các phần tử kiểu (ChildItem `key:K name:WindowType`, kích thước = NamedArea `K`), `__auto_parent__` + `__auto_vscrollbar__`; sự kiện `ElementLClick/RClick/Click/MouseEnter/MouseLeave`, `EventElementCheckButton1Click`, `EventElementButton1..6Click` (SweepAll). Lua: `CleanAllElement`, `Get/SetVertScrollbarPosition`, `SetVertScrollbarHide`, `SetElementsInView`. | Export `FalagardAchievementWindow::{AddChildElement, ClearAllElement, GetWindowSizeByType, SetElementsInView, PageEnd, ...}`; look `TLBB_Look_AchievementWindow`. | `FalagardAchievementWindow.h/.cpp` |
| `Falagard/DragDropTarget` | Ô nhận kéo-thả (thành viên bang hội): `HoverState`; look Normal/Hover/Disabled; nhận `DragDropItemEnters/Leaves/Dropped`; phát `DragDropTargetChanged`. | Chuỗi "Property to get/set the hover state of FalDragDropTarget Window.", `HoverState`, `DragDropTargetChanged`; look `TLBB_Look_UnionDragTarget`. | `FalagardDragDropTarget.h/.cpp` |
| `Falagard/DragContainer` | DragContainer của CEGUI vẽ được look (TLBB_UnionDragItem = look `TLBB_Look_StaticImage`, rỗng; nội dung là cửa sổ con). | Chuỗi `Falagard/DragContainer`, `LoseCapture`; layout UnionFrame (`DragStarted`, `MouseLClick`). | cùng file |
| `Falagard/SuperBarButton` | Dòng "càn quét" của AchievementWindow: 3 ảnh + ảnh Te, 6 ô chữ, 1 check + 7 nút con (`__auto_SuperBarButton%d__`); click nút con → chuyển lên AchievementWindow thành `EventElementButton%dClick`/`EventElementCheckButton1Click`; hover vẽ `SuperBarHoverSection`. | Export `FalagardSuperBarButton::{SetButtonActive, SetButtonSelected, SetImageTe(Show/Hide), GetChildItem, SetChildItemEvent, setHoverSection}`, chuỗi `SuperBarButtonHover`, `%s__auto_SuperBarButton%d__`; look `TLBB_Look_SweepButton`. | `FalagardSuperBarButton.h/.cpp` |
| `Falagard/TripperTooltip` | Tooltip GL với nhiều dòng theo id yêu cầu: `setTripperText(id, text)`, `clearTripperText(id)`; vẽ như FalagardTooltip (look `TLBB_GL_Tooltip`). | Export `FalagardTripperTooltip::{setTripperText, clearTripperText, doActive/FadeIn/FadeOut/InactiveState}`, chuỗi "setTripperText Incoming:%u". | cùng file |

Thuộc tính GL chỉ có tác dụng ở lớp game (hoặc chưa vẽ) nay được **lưu theo cửa sổ** thay vì ném ngoại lệ (`CysStoredProperties.cpp`, bảng có ghi ý nghĩa từng thuộc tính): ComplexWindow `QuestButtonImage`/`ChildItem`; SceneMap `IconImage`/`AnimateImage`/`FlashAnimateImage`/`BlueCircleImage`/`ChildItem`/`AutoReset`/`RoundEnabled`; ActionButton `BackImage`/`Image`; Money `AlignFix`/`MoneyMaxColour`/`MoneyColor`/`VertFormatting`; BoundWindow/StaticImage `AttachEnabled`; StaticImage/CheckBox/ChatBoard `TextColor`; AnimateImage `UseImageSize`; AnimateButton `WarningAnimation`; SimpleText `ColorTrans`/`VertScrollbar`; SuperProgress `EffectColorType`/`FlashPoint`/`FlashSetting`/`UseUninterruptedEffectColor`; IMEEditBox `SoftKeyOnly`; MultiColumnList `LineDrawOffset`; MultiIMEEditBox `DisableCopyPaste`/`HorzFormatting`/`VertScrollbar`; SelfFitWindow `MinWidth`; WorldMap/ScrollInfo `ChildItem`. Lớp game đọc lại bằng `Window::getProperty` (giá trị lặp nối bằng `\n`). Việc vẽ thật của `SceneMap.IconImage` (cờ minimap), `ActionButton.BackImage`, `ComplexWindow.QuestButtonImage` là NEXT của mảng world/HUD logic.

Sửa lỗi kèm theo: `ComplexWindow` không còn `requestRedraw` trên parent null khi thuộc tính được đặt trước `initialise()` (19 layout crash); `FalStaticImage` bỏ qua state không có trong look thay vì ném (`TLBB_Look_WorldMap`, SceneMap, MiniMap: 12 lỗi); viewer chọn tooltip `TLBB_Tooltip` như UISystem (1 lỗi scheme). Hook nhỏ trong CEGUIBase: `Window::cysRecordScriptedEvent` (layout loader ghi lại `<Event>` để NotSuperList nhân bản được), `ScriptFunctor` xuất khỏi DLL.

Lớp Lua (UI_CEGUI, `UILuaControl.*`, `UIWindowMng.*`): thêm `MetaTable_Control_NotSuperList`, `_NotSuperListItem`, `_ListBoxEx`, `_ScrollInfo`, `_AchievementWindow`, `_Effect` với đúng tên hàm của B; `Window:SetEvent(sự kiện, "hàm()")`; `CUIWindowItem::GetControlObject` tạo/giữ đối tượng Lua cho cửa sổ sinh lúc chạy (bản sao NotSuperList, phần tử AchievementWindow), giải phóng khi `Clear`. UI_CEGUI nay import CEGUIFalagard.dll (B đi qua interface; đây là khác biệt có chủ ý).

## 4. Kết quả

| Census CysUiViewer (`--all`, 1.214 layout Canonical, 1920×1080) | trước (`census-before`) | sau (`census-final`) |
|---|---|---|
| Vẽ được | 1.062 | **1.214 / 1.214** |
| Không có lỗi CEGUI | 926 | **1.206** |
| Crash | 30 | **0** |
| Không nạp được | 122 | **0** |
| Dòng `(Error)` | 1.338 | **33** |
| Thuộc tính thiếu (khác nhau) | 38 | 3 (DefaultWindow.HorzFormatting/Image/MoveSpeed — lỗi dữ liệu layout, **B ghi cùng lỗi** trong `client_GL\Bin64\CEGUI.log`) |
| Kiểu chưa đăng ký | 9 (+2 chỉ trong scheme) | **0** |
| Font | 15/15 engine | 15/15 engine |

33 dòng còn lại đều do dữ liệu, không phải widget: 20 `ChildImage` của MapImage trỏ ảnh không có trong imageset nào (`CharStyleFrame1/TragetCamp1_*`, SelectHeadFrame/TargetFrameDIY); 4 ảnh `Button7/Friend_ChangeAgname_*` không được định nghĩa (Friend_IMGroupInvite); 4 thuộc tính đặt lên `DefaultWindow` (B cũng lỗi); 3 `ChannelBkg` với `dir:CommonFrame` sai cú pháp (ChatFrame); 1 regex `[0-9]*` của Verification (pcre báo lỗi trên chuỗi mẫu); 1 `Agname18/ysqcdf_L8` (scheme; stage đã có alias). Không còn ngoại lệ nạp layout, không còn kiểu chưa đăng ký.

Widget tests (`Tests\ui\widget_tests.cpp`, DLL cây `hud-uiviewer-x64`, chạy với `Assets\Canonical` của cây chính): **139/139 PASS** — 126 ca cũ (font 59 đã nằm trong bộ này và các ca native) + 13 ca mới cho NotSuperList (mẫu ẩn, nhân bản thuộc tính/con/sự kiện, xếp cột, cuộn, chọn, Clear), ListBoxEx, ScrollInfo, PS, DragDropTarget, AchievementWindow, TripperTooltip, ResizeText Min/MaxWidth, thuộc tính lưu. Log: `widget-tests-final.log`.

`Tools\game\stage_game.py`: `ui_compat` tính lại từ DLL đã dựng — với DLL mới (`hud-x64\bin`: 85 kiểu) **0 cửa sổ bị lọc** (`missing-types-fullbin.json`); `Tools\game\test_stage_game.py` 20/20.

Build sạch toàn bộ thành phần (`build-full-3.log`, rc=0, cây `Build\wt-hud-widgets\Build\cmake\hud-x64`: Game.exe, UI_CEGUI.dll, CEGUIFalagard.dll, CysUiViewer.exe...). LuaPlus giữ `/EHc-` (build.ninja).

Ảnh (bằng chứng chính, `Build\Logs\2026-09-14-hud-widgets\shots\`): `HUD-composite.png` (PlayerFrame + TargetFrame + TargetBuff + MiniMap + ChatFrame + Action + MainMenuBar + MainMenuBar_2 + ScrollInfo ghép một khung), và từng cửa sổ: PlayerFrame, MiniMap, Action, MainMenuBar, ChatFrame, TargetFrame, ScrollInfo, GameSetup (menu hệ thống), SuperTooltip / SuperToolTip2_AttrCompare / CampaignItemTip (tooltip mẫu), Cloud_SelectServer (NotSuperList), friend (ListBoxEx), CampaignTrack, UnionFrame (DragDrop), SweepAll (AchievementWindow), DaHua_PKWarning (PS), Agname.

## 5. Lệnh

```
rem build (cay viewer hoac full) - ASCII, log ra file
cmd /c Build\Logs\2026-09-14-hud-widgets\build_hud.cmd viewer <log> cys_ui_viewer
cmd /c Build\Logs\2026-09-14-hud-widgets\build_hud.cmd full <log>
rem census toan bo Canonical
Build\wt-hud-widgets\Build\cmake\hud-uiviewer-x64\bin\CysUiViewer.exe --ui Assets\Canonical\Data\InterfaceFolder --all --no-shots --out <dir>
rem widget tests (bien dich + chay; chay lai exe voi Assets\Canonical cua cay chinh vi worktree khong co Assets)
powershell -File Build\wt-hud-widgets\Tests\ui\run_widget_tests.ps1 -OutDir <worktree>\Build\Logs\... -NativeTree <worktree>\Build\cmake\hud-uiviewer-x64
<OutDir>\widget_tests.exe C:\TLBB\085\CY-Source\Assets\Canonical\Data\InterfaceFolder
rem bang kieu thieu theo DLL (cung logic ui_compat cua stage_game.py)
python Build\Logs\2026-09-14-hud-widgets\missing_types.py <bin dir> <out.json>
```

## 6. Bẫy

1. `Window` của CEGUI fork này giữ thuộc tính **trong WindowFactory** (tĩnh theo kiểu) và trong PropertyDefinition của look, không trong cửa sổ: muốn liệt kê thuộc tính để nhân bản phải duyệt `getFactory(getWidgetType())` và look ánh xạ của `getType()`. `Window` kế thừa `PropertyReceiver` + `EventSet`, cả hai đều có `getIterator()`.
2. Lớp lồng (`FalagardSuperTooltip::ResizeText`) không được dllexport theo lớp ngoài: test phải tạo qua `registerFactory` của DLL, không `new` factory.
3. `ScriptFunctor` của CEGUIBase không export → widget trong CEGUIFalagard không link được; đã thêm `CEGUIEXPORT`.
4. Look có thể được gán **sau** `initialise()` (test, `setLookNFeel` tay): widget có `__auto_*__` phải nhận con trong `onChildAdded` nữa. Listbox gốc thì không (cần Falagard mapping để look gán trước `initialise`).
5. `Falagard/[A-Za-z0-9_]+` trong stage_game.py bỏ sót tên kiểu hai dấu `/` → 11 cửa sổ tooltip bị lọc oan.
6. Thứ tự nạp layout: cửa sổ được tạo, gắn vào cha, **rồi** mới đặt thuộc tính; `ComplexWindow` gọi `d_ParentWindow->requestRedraw()` trong setter → crash nếu look chưa gắn.
7. B ghi cùng lỗi cho `DefaultWindow.Image/HorzFormatting`, `ActionButton.Image`, `Money.VertFormatting`, `MultiIMEEditBox.VertScrollbar` (xem `client_GL\Bin64\CEGUI.log`): đây là lỗi dữ liệu, không phải widget thiếu.
8. `PropertyHelper::floatToString` in `%f` ("202.000000"): thuộc tính số của GL trả về dạng gọn (`intToString`, `%g`) để Lua/so sánh chuỗi không lệch.
9. UI_CEGUI của 0.85 không link CEGUIFalagard.dll (chỉ qua interface); lớp Lua GL gọi thẳng lớp widget nên `cys_uisystem` nay link `cys_ceguifalagard`.
10. `run_widget_tests.ps1` lấy `Assets\Canonical` theo gốc script (worktree không có Assets) → ca font Noto FAIL giả; chạy lại exe với đường dẫn Canonical của cây chính.

## 7. Kiểm lại 17/09/2026 (agent `ui-layouts`)

Mục này nối thêm, không sửa mục 1–6. Bằng chứng: `Build\Logs\2026-09-17-ui-layouts\` (xem `README_vi.md`).
Binary kiểm: cây riêng `Build\cmake\ui-layouts-x64` dựng từ HEAD `c2ca6001` (`build-1.log` rc 0, 638 bước);
mã chốt ở `build-3.log`. Số trong mục này lấy từ `census-*-final*` và `regression-181-final`.

### 7.1 Số liệu census (CysUiViewer, 1024×768, `--all --no-shots`)

| Bộ dữ liệu | Mốc | Vẽ được | Không nạp được | Crash | `(Error)` | Layout có lỗi |
|---|---|---|---|---|---|---|
| `Assets\Canonical` (GL, 1.214) | 12/09 `all-1024x768` (số trong nhiệm vụ) | **1.033** | **156** | **25** | 20.383 | 992 |
| `Assets\Canonical` (GL, 1.214) | 17/09 HEAD, trước lượt này | 1.214 | 0 | 0 | 32 | 7 |
| `Assets\Canonical` (GL, 1.214) | 17/09 sau lượt này | **1.214** | **0** | **0** | **28** | **5** |
| `Assets\CanonicalCY` (CY, 2.032) | 14/09 `census-all-3` (cy-gui) | 2.032 | 0 | 0 | 27 | 8 |
| `Assets\CanonicalCY` (CY, 2.032) | 17/09 HEAD, trước lượt này | 2.032 | 0 | 0 | 27 | 8 |
| `Assets\CanonicalCY` (CY, 2.032) | 17/09 sau lượt này | **2.032** | **0** | **0** | **24** | **5** |

- 156 layout không nạp được và 25 crash của mốc 12/09 đã được đóng từ 14/09 bởi `hud-widgets` (11 kiểu GL) và
  `cy-gui` (18 kiểu CY). Lượt 17/09 chỉ **đo lại và chứng minh không hồi quy**, rồi gỡ hai nguồn lỗi còn do engine.
- Hồi quy có chủ đích: chạy đúng **181 layout** từng hỏng ngày 12/09 (`regression-181.lst` = 156 load-failed + 25
  crash, trích từ `Build\Logs\2026-09-12-uiviewer\all-1920x1080\failures.txt`) ở **1920×1080** trên dữ liệu GL →
  **181/181 vẽ được, 0 không nạp, 0 crash** (`regression-181-after\summary.txt`).
- Đường thật của engine: `--scheme-mode game --strict-fonts` trên CanonicalCY (đúng `SchemeManager::loadScheme` của
  `UI_CEGUI`, không cho viewer thích ứng font) → **2.032/2.032, 0 crash, 24 `(Error)`, 8/8 font nạp bằng engine**,
  giống hệt chế độ `robust` (`census-cy-gamemode\summary.txt`). Lớp GUI CY **không** phụ thuộc chế độ nạp scheme.

### 7.2 Hai crash cũ — nguyên nhân gốc (đã ghi lại để khỏi tái phát)

| Crash | Số layout 12/09 | Nguyên nhân gốc | Chỗ sửa |
|---|---|---|---|
| `CEGUI::Window::requestRedraw` (CEGUIWindow.cpp:1383) trong `loadWindowLayout` | 19 | Không phải con trỏ treo mà là **con trỏ null**: loader tạo cửa sổ → gắn cha → *rồi mới* đặt thuộc tính, nên setter của `ComplexWindow` (`ActionButtonSize`…) gọi `d_ParentWindow->requestRedraw()` khi look/`initialise()` chưa gắn `d_ParentWindow`. `requestRedraw()` ghi `d_needsRedraw` ⇒ AV 0xC0000005 ngay byte đầu. | `FalagardComplexWindow.cpp` (14/09, `hud-widgets`) — kiểm null trước khi gọi, không try/catch |
| `CEGUI::Rect::offset` (CEGUIRect.cpp:83) trong `renderGUI` | 6 | `SuperTooltip/ResizeText` lấy `getImage()` của khung Top/Middle/Bottom mà look không có ⇒ `Image*` null, rồi `image->getSize()`/`Rect::offset` chạy trên `this` null. Không phải kích thước âm. | `FalSuperTooltip.cpp` (14/09) — thiếu ảnh khung thì vẽ `StateImagery Enabled` của look |

### 7.3 Hai lỗi engine gỡ trong lượt 17/09

1. **`ChannelBkg direction must be left, middle or right.`** (ChatFrame — 1 lần trên CY, 3 lần trên GL).
   Ngữ pháp `dir:` là **thật**: `client_GL\Bin64\CEGUIFalagard.dll` chứa đúng các literal ` dir:%15s`, `left`,
   `middle`, `right` ngay cạnh `ItemBkgLeftSize/ItemBkgMiddleSize/ItemBkgRightSize` (xem
   `Build\Logs\2026-09-14-hud-widgets\gl-CEGUIFalagard-strings.txt` dòng 11504–11511). Thứ B **không** làm là ném.
   Dữ liệu thật của **cả** CY lẫn GL chỉ có đúng một giá trị: `dir:CommonFrame set:Chat image:CommonEditBoxBK`
   (CY 1 dòng, GL 3 dòng giống nhau) — hướng `CommonFrame` không khớp cả ba, và imageset `Chat` không tồn tại
   (`CommonEditBoxBK` nằm trong imageset `CommonFrame`). Vậy hướng lạ **bị bỏ qua**: không phần nào được ghi, không
   vẽ, không log — cùng lối engine xử lý ảnh không giải được (`PropertyHelper::stringToImage()` trả 0 im lặng).
   Sửa (`FalChatChannel.cpp/.h`): hướng lạ ⇒ bỏ qua, chỉ nhớ descriptor cho getter; hướng đúng ⇒ đặt phần tương ứng,
   ảnh không giải được thì để null. Không còn bất kỳ nhánh nào ném. Ảnh không đổi
   (`ChatFrame` GL coverage 0,15209 → 0,15209).
2. **`Editbox::isStringValid - An internal error occurred while attempting to match the invalid RegEx '.*'`**
   (CY: `Anniversary`, `BW_CreateTeam`; GL: `Verification`). Regex **không** sai. TLBB nhét markup ngay trong chuỗi
   bằng **mã điểm utf32 ngoài dải Unicode** (màu `0xFB......`, gradient `0xFC......`, nháy `0xE0......`, icon
   `0xFA......` — xem `UIString.cpp`, `UiViewerText.cpp`). `String::c_str()` mã hoá mọi mã điểm bằng bộ ghi 4 byte
   thẳng, nên chuỗi có markup **không phải utf8 hợp lệ**; `pcre_exec()` (biên dịch với `PCRE_UTF8`) trả
   `PCRE_ERROR_BADUTF8` (-10), rơi vào nhánh "anything else" và ném. Câu chữ cũ đổ lỗi cho regex nên che mất nguyên
   nhân. Sửa (`CEGUIEditbox.cpp`): dựng chuỗi subject chỉ từ **mã điểm Unicode thật** (bỏ marker markup và surrogate
   lẻ) rồi mới `pcre_exec`; thông báo lỗi còn lại in đúng mã `pcre_exec` trả về.
   Không đổi ảnh: ngoại lệ cũ xảy ra **sau** khi `setMaxTextLength`/`setValidationString` đã cắt chuỗi và bắn sự kiện,
   nên chỉ thiếu `onTextInvalidatedEvent` (`BW_CreateTeam` coverage 0,21292 → 0,21292).

So từng dòng `layouts.csv` trước/sau: **chỉ 5 layout đổi số lỗi** (CY `Anniversary`, `BW_CreateTeam`, `ChatFrame`;
GL `ChatFrame`, `Verification`), tất cả về 0. Không layout nào đổi `status`/số cửa sổ.

**Widget tests trên DLL mới: 137/139** (`Build\Logs\2026-09-17-ui-layouts\widget-tests-2`). Hai ca đỏ, cả hai là
**hợp đồng cũ đã sai**, không phải hồi quy chức năng:

| Ca | Tình trạng |
|---|---|
| `ChildImage malformed resource cannot corrupt an existing mapping` (dòng 645) | **Đỏ từ 14/09**, không liên quan lượt này: ca đòi `setChildImage` ném 2 lần, nhưng `572e9755` (cy-gui, 14/09 18:41) đã đổi `FalagardMapImage::setChildImage` sang log-and-skip; `widget_tests.cpp` cập nhật lần cuối ở `973bef30` (14/09 13:06), tức **trước** đó. |
| `ChannelBkg rejects malformed direction atomically` (dòng 548) | Nửa "không làm hỏng trạng thái" vẫn đúng (ca `HoverColor keeps all eight digits` ngay sau đó vẫn PASS với đủ 9 quad ⇒ cả ba phần nền còn nguyên); chỉ nửa `threw` không còn đúng sau mục 7.3.1. Ca dùng đúng giá trị dữ liệu thật `dir:CommonFrame …`, nên phải sửa ca thành "bỏ qua, không ném, không đổi nền". |

Sửa hai ca này nằm ngoài phạm vi ghi của agent `ui-layouts` (`Tests\**`), nên để lại cho người điều phối.

### 7.4 24 `(Error)` còn lại trên CanonicalCY — đều là dữ liệu của chính CY

| Số | Thông báo | Nguồn |
|---|---|---|
| 12 | `Imageset::getImage … 'QiXi_StoryLetter_QZ_2/4/5' … 'QiXi_StoryLetter_2'` (pha scheme) | `Schema\wowanimate.xml` ghi sai tên imageset ở 12 khung; ảnh thật nằm trong `QiXi_StoryLetter_3` |
| 5 | `Aniamtemanager::getAniamte- No Animate named 'XinShouNew_SheJiaoDaRen_RewardFrame_Flash'` | `XinShouNew.layout.xml` gọi animate không có trong `wowanimate.xml` |
| 7 | `Imageset::getImage` (Anniversary2, Pretty01, XSYNew02) | layout gọi ảnh không có trong imageset |

Ngoài ra scheme CY ánh xạ 4 kiểu **không có looknfeel** (`TLBB_Look_NewExteriorCheckBK1/BK2`,
`TLBB_Look_ScrollbarThumb_Track`, `TLBB_Look_SelectServerWindow`) — đã kiểm: **0 layout** dùng bốn kiểu này, nên vô hại.
Kiểm tĩnh toàn bộ 2.032 layout: **479 kiểu cửa sổ dùng thật, 0 kiểu thiếu ánh xạ** (chỉ `DefaultWindow` dựng sẵn và
`Falagard/PS` gọi thẳng kiểu cơ sở); 79 kiểu cơ sở trong scheme đều có factory trong `CEGUIFalagard.dll` (97 factory).

### 7.5 28 ảnh trắng của CanonicalCY không phải lỗi

Toàn bộ là khung rỗng theo thiết kế: menu ngữ cảnh/`MessageBall`/`TargetBuff`/`PlayerImpactFrame` được Lua đổ nội
dung lúc chạy, các `*_NULL` (`TLBB_ActionButtonNULL`, `TLBB_StaticImageNULL`) vốn không có art, `TeamMessageBox1` có
`Root="false"`. Danh sách đầy đủ trong `census-cy-after\layouts.csv` (cột `coverage`).

### 7.6 Bẫy thêm

11. `Assets\CanonicalCY\Data\ConfigFolder\InterfaceEx.txt` là **DBC nhị phân** (`00CCBBDD`), còn bản GL là bảng text.
    Game đọc đúng (`GMDataBase.cpp`, `DBC_UI_LAYOUTDEFINE`, 10 cột `ISSSISIIIS`), nhưng **CysUiViewer chỉ có reader
    text** nên trên CanonicalCY nó chỉ lấy được **14** tên cửa sổ (GL: 1.181). Census không bị ảnh hưởng (viewer liệt
    kê theo file `*.layout.xml`), nhưng `--layout <TênCửaSổ>` và cột `window` trong báo cáo sai trên dữ liệu CY.
    Việc này thuộc phạm vi agent `ui-viewer`.
12. `MapImage: ChildImage '…' ignored (image not found in the imageset)` log ở mức `Errors` (20 dòng, chỉ dữ liệu GL)
    trong khi engine gốc im lặng khi `stringToImage` trả 0. Cố ý giữ để không giấu dữ liệu thiếu, nhưng phải nhớ khi
    so số `(Error)` với client thật.
