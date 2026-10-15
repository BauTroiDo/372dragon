#include "falagardscenemap.h"
#include "ceguiPropertyHelper.h"
#include "ceguiimagesetmanager.h"
#include "ceguiimageset.h"
#include "ceguianimatemanager.h"
#include "ceguiwindowmanager.h"
#include "CEGUISystem.h"
#include "CEGUIResourceProvider.h"
#include "CEGUIDataContainer.h"
#include "CEGUILogger.h" // CYS-CRASHCEGUI
#include "CysStoredProperties.h" // CYS-SCENEMAP 20/09: doc thuoc tinh RoundEnabled cua layout
#include <string>        // CYS-CRASHCEGUI
#include <set>           // CYS-SCENEMAP 20/09
#include "FalagardLoginWidgets.h"
#include <vector>
#include <math.h>
#include <map>           // CYS-MAPDOTS 20/09
#include <stdio.h>       // CYS-MAPDOTS 20/09: sscanf / _snprintf
#include <string.h>      // CYS-MAPDOTS 20/09: strcmp
#include <stdlib.h>      // CYS-CRASHCEGUI: getenv
#include "windows.h"
namespace CEGUI
{

	FalagardSceneMapProperties::PlayerImage			FalagardSceneMap::d_PlayerImageProperty;		// 队友用得图标
	FalagardSceneMapProperties::MySelfImage			FalagardSceneMap::d_MyselfImageProperty;		// 自己所需要得图片动画

	const String FalagardSceneMap::EventNamespace("Falagard/SceneMap");
	const String FalagardSceneMap::MouseRButtonDownCtrl("MouseRButtonDownCtrl");
	const utf8 FalagardSceneMap::WidgetTypeName[] = "Falagard/SceneMap";
	const int SCENE_MAP_PER_PIC = 64; // 每一块地图片对应多大的地图区域
	const int SCENE_MAP_ZOOMSCALE = 4;

	// CYS-CRASHCEGUI: 1 = tên ô đánh dấu theo thể hiện (bản vá). 0 = tên TOÀN CỤC cũ.
	// Công tắc A/B nằm ở ĐÚNG MỘT dòng này, nên nhánh chứng dương chỉ khác nhánh vá một biến số.
	#define CYS_CRASHCEGUI_NAME_PER_INSTANCE 1

	// Một chỗ duy nhất đặt tên năm ô đánh dấu đồng đội.
	static void CysMarkerName( char* szOut, const String& strOwner, int i )
	{
#if CYS_CRASHCEGUI_NAME_PER_INSTANCE
		sprintf( szOut, "%s_Scenemap_Player_%d", strOwner.c_str(), i );
#else
		(void)strOwner;
		sprintf( szOut, "Scenemap_Player_%d", i );
#endif
	}

	// CYS-SCENEMAP 20/09: CONG TAC A/B, mot binary duy nhat.
	//   CYS_SCENEMAP_ROUND_LEGACY=1 => ngu nghia CU: hinh dang lay tu DOI SO THU 4 cua Lua.
	//   khong dat (mac dinh)        => ngu nghia MOI: hinh dang lay tu thuoc tinh RoundEnabled
	//                                  cua CHINH CUA SO (dung nhu client song 0.85/CY 3.71 lam).
	// Bang chung cho ngu nghia moi (Build/Logs/2026-09-20-scenemap-round/evidence-live-clients.txt):
	//   - client\Bin\CEGUIFalagard.dll xuat `?setRoundEnabled@FalagardSceneMap@CEGUI@@QAEX_N@Z`
	//     va `?d_RoundProperty@FalagardSceneMap@...RoundEnabled@FalagardSceneMapProperties@...`
	//     => TRON la mot THUOC TINH CUA CUA SO, khong phai tham so cua lenh ve ban do.
	//   - cung DLL do xuat `?setShowMyself@FalagardSceneMap@CEGUI@@UAEXH@Z` va
	//     `?setSceneFileName@...@@UAEXABV?$StringBaseT@D@2@@Z` (MOT doi so)
	//     => doi so thu 4 cua Lua di vao setShowMyself, tuc "co hien mui ten nhan vat khong".
	//   - MiniMap.layout.xml cua CA BA client song dat RoundEnabled="True" tren MiniMap_MapArea
	//     va KHONG dat gi tren SceneMap_Board.
	//   - Ca `UserSharps`/`LookLikeRound` lan hang so chia vong tron (sin22.5/cos22.5/sin45)
	//     KHONG ton tai trong CEGUIBase.dll / CEGUIOgreRenderer.dll cua bat ky client song nao.
	static bool CysRoundLegacy()
	{
		static int s_legacy = -1;
		if( s_legacy < 0 )
		{
			const char* p = ::getenv( "CYS_SCENEMAP_ROUND_LEGACY" );
			s_legacy = ( p && p[ 0 ] == '1' ) ? 1 : 0;
		}
		return s_legacy != 0;
	}

	// Cua so nay co duoc ve TRON khong? (minimap: co - ban do lon: khong)
	// Nhanh LEGACY tra ve false: o do hinh tron duoc lam bang `LookLikeRound` tren tung o nen
	// (dung cach CU, de tai hien trieu chung), KHONG bang mat na. Neu de legacy cung bat mat na
	// thi nhanh AM khong con la nhanh AM - do la loi CUA CHINH TOI o luot do dau, luot
	// `legacy-111508` dat mat na len ca SceneMap_Board.
	static bool CysWantRound( const Window* pWin, const int /*nUserSharp*/ )
	{
		if( CysRoundLegacy() ) return false;
		return PropertyHelper::stringToBool( cysStoredProperty( pWin, "RoundEnabled" ) );
	}

	// CYS-SCENEMAP 20/09: MAT NA TRON cho minimap - HOC THANG TU CLIENT SONG, khong tu nghi ra.
	// Bo chuoi cua `FalagardSceneMap` trong client/Bin/CEGUIFalagard.dll (offset 0xda59c) xep lien nhau:
	//   "%s_map_%d_%d" | "Scenemap_view" | "jpg_%s.dds" | "Scene" | "%s.jpg"
	//   | "Falagard/SceneMap/ParentWindow" | "RoundRegion" | "%s_%d_%d" | ... | "CJ_RoundRegion" | ...
	// Tuc la client song VUA lat o "jpg_<canh>_<x>_<y>.dds" giong ta, VUA co hai anh vung tron.
	// Do anh that: Common/tga_CJ_RoundRegion.dds (128x128) DEN va DUC ben NGOAI duong tron noi tiep,
	// TRONG SUOT ben trong => day la MAT NA. Ca hai anh + imageset da co san trong CanonicalCY va
	// da duoc dang ky trong WoWLookSkin.scheme.xml (dong 5282), khong phai them tep du lieu nao.
	//
	// PHAN BIEN (vi sao KHONG chep nguyen cach cu): duong goc 0.85 ep m_nXCount=m_nYCount=1 nen no
	// chi co MOT o, va `LookLikeRound` tren o do = mot elip lon hon khung nhin => khong ai thay.
	// Cay ta lat 5x5 o 256 px, nen `LookLikeRound` tren TUNG o cho ra 25 elip. Tien de da doi,
	// cho nen chep hanh vi cu sang la van hong. Cach dung: dat vong tron o CAP KHUNG NHIN
	// (chinh cua so ban do), vi khung nhin chi co MOT - bao nhieu o nen cung chi ra MOT duong tron.
	static void CysApplyRoundMask( Window* pMap, const bool bRound )
	{
		char szWindowName[ 160 ];
		_snprintf( szWindowName, sizeof( szWindowName ), "%s_Auto_RoundMask", pMap->getName().c_str() );
		szWindowName[ sizeof( szWindowName ) - 1 ] = 0;
		WindowManager& wm = WindowManager::getSingleton();
		const bool bExists = wm.isWindowPresent( szWindowName );
		if( !bRound )
		{
			if( bExists ) wm.getWindow( szWindowName )->hide();
			return;
		}
		const Image* pMask = 0;
		try
		{
			const String setName( (utf8*)"CJ_RoundRegion" );
			if( ImagesetManager::getSingleton().isImagesetPresent( setName ) )
			{
				Imageset* pSet = ImagesetManager::getSingleton().getImageset( setName );
				if( pSet->isImageDefined( setName ) ) pMask = &pSet->getImage( setName );
			}
		}
		catch( ... ) { pMask = 0; } // CYS: thieu anh thi bo qua, KHONG nem (bay 19/09: 0.85 nem cho CY chay tiep)
		if( !pMask )
		{
			Logger::getSingleton().logEvent( "CYS-SCENEMAP: win='" + pMap->getName() +
				"' KHONG CO anh CJ_RoundRegion => khong dat duoc mat na tron", Errors );
			return;
		}
		if( !bExists )
			pMap->addChildWindow( wm.createWindow( "WoWLook/StaticImage", szWindowName ) );
		Window* pMaskWin = wm.getWindow( szWindowName );
		( (StaticImage*)pMaskWin )->setImage( pMask );
		// Do anh that: tga_CJ_RoundRegion.dds la mau TRANG o phan duc (alpha 255 ben ngoai duong
		// tron, 0 ben trong). De nguyen thi bon goc ban do hien ra TRANG - da chup thay o luot
		// `legacy-111508`. Nhan mau cho no thanh DEN de doc ra nhu bong vien, khong phai mot
		// mang trang. (Client song ve ban do qua mot RENDER TEXTURE - chuoi
		// "set:MapLight_RenderTexture image:View" trong DLL cua ho - nen ho khong gap viec nay.)
		( (StaticImage*)pMaskWin )->setImageColours( colour( 0xFF000000 ) );
		pMaskWin->setRect( Relative, Rect( 0, 0, 1, 1 ) );
		pMaskWin->setSize( Relative, Size( 1, 1 ) );
		pMaskWin->setMaximumSize( Size( 100, 100 ) );
		pMaskWin->setAlwaysOnTop( true );
		pMaskWin->setRiseOnClickEnabled( false );
		pMaskWin->setMouseHollow( true );
		pMaskWin->setMouseMoveHollow( true );
		pMaskWin->setMouseLButtonHollow( true );
		pMaskWin->setMouseRButtonHollow( true );
		pMaskWin->show();
		Logger::getSingleton().logEvent( "CYS-SCENEMAP: win='" + pMap->getName() +
			"' mat na tron CJ_RoundRegion DA DAT ('" + String( (utf8*)szWindowName ) + "')", Errors );
	}

	// CYS-SCENEMAP 20/09: mat na nam TREN ban do nen no cung de len vanh khung vang cua cua so CHA
	// (`MiniMap_Background_Map`, anh `set:MiniMap image:Minimap_Area`), vi CEGUI ve CHA truoc CON.
	// Ve LAI dung anh do mot lan nua o tren cung thi vanh khung tro lai nguyen ven.
	// Doc anh qua THUOC TINH (chuoi), khong ep kieu con tro: neu cha khong phai loai co thuoc tinh
	// "Image" thi CEGUI nem UnknownObjectException, ta bat va bo qua - khong lam chet tien trinh.
	static void CysRedrawParentFrame( Window* pMap, const bool bRound )
	{
		Window* pParent = pMap->getParent();
		if( !pParent ) return;
		char sz[ 160 ];
		_snprintf( sz, sizeof( sz ), "%s_Auto_RoundFrame", pMap->getName().c_str() );
		sz[ sizeof( sz ) - 1 ] = 0;
		WindowManager& wm = WindowManager::getSingleton();
		const bool bExists = wm.isWindowPresent( sz );
		String strImage;
		if( bRound )
		{
			try { strImage = pParent->getProperty( "Image" ); }
			catch( ... ) { strImage.clear(); }
		}
		if( !bRound || strImage.empty() )
		{
			if( bExists ) wm.getWindow( sz )->hide();
			return;
		}
		if( !bExists )
			pParent->addChildWindow( wm.createWindow( "WoWLook/StaticImage", sz ) );
		Window* pWin = wm.getWindow( sz );
		try { pWin->setProperty( "Image", strImage ); }
		catch( ... )
		{
			pWin->hide();
			Logger::getSingleton().logEvent( "CYS-SCENEMAP: win='" + pMap->getName() +
				"' KHONG dat duoc anh vanh khung ve lai", Errors );
			return;
		}
		pWin->setRect( Relative, Rect( 0, 0, 1, 1 ) );
		pWin->setSize( Relative, Size( 1, 1 ) );
		pWin->setMaximumSize( Size( 100, 100 ) );
		pWin->setAlwaysOnTop( true );
		pWin->setRiseOnClickEnabled( false );
		pWin->setMouseHollow( true );
		pWin->setMouseMoveHollow( true );
		pWin->setMouseLButtonHollow( true );
		pWin->setMouseRButtonHollow( true );
		pWin->show();
		Logger::getSingleton().logEvent( "CYS-SCENEMAP: win='" + pMap->getName() +
			"' ve lai vanh khung cua cha ('" + String( (utf8*)sz ) + "' = " + strImage + ")", Errors );
	}

	// CYS-SCENEMAP 20/09: cua so nao dang dung duong LAT O. Ghi theo TEN cua so (duy nhat,
	// on dinh) chu khong theo con tro, de khong phu thuoc vong doi Window va khong doi
	// layout cua lop (cung luat voi ValidateFriendWindows).
	static std::set< std::string >& CysTiledSet()
	{
		static std::set< std::string > s;
		return s;
	}
	static bool CysIsTiled( const Window* pWin )
	{
		return CysTiledSet().count( std::string( pWin->getName().c_str() ) ) != 0;
	}

	// ====================================================================================
	// CYS-MAPDOTS 20/09 - LOP DAU tren minimap va ban do lon ("toi", quai, NPC, dong doi...).
	//
	// HOC TU CAY SONG (Build/Logs/2026-09-20-map-dots/01-cay-song-lam-the-nao.md), bang vi sai o
	// 02-bang-vi-sai.md. Tom tat nhung gi cay song lam, doc tu client_GL\Bin64\CEGUIFalagard.dll
	// (sha256 82b61321...ff527f, dinh vi bang ky hieu xuat):
	//   - `IconImage type:Icon%d set:%s image:%s` / `AnimateImage type:Animate%d animate:%s` la THUOC
	//     TINH THAT cua Falagard/SceneMap; moi `type` so duoc ghi vao mot map va danh dau "da dang ky".
	//   - `setMinimapData` BO QUA moi type chua dang ky; type da dang ky thi lay mot cua so tu POOL
	//     ("%s_Window_Pool%d_%d", con cua <win>_auto_background, HookMode=Hook_Center, ZoomMode=Relative),
	//     dat anh + HookPosition = toa do canh / d_SceneSize + kich thuoc tuyet doi = kich thuoc anh nguon.
	//   - "minh" la type 10 (hang so trong UpdateFlag cua UI_CEGUI.dll song) = `Animate10` = Minimap_arrow.
	//     KHONG cay song nao dat thuoc tinh `MySelfImage` tren Falagard/SceneMap.
	//   - `setShowMyself(0)` (doi so thu 4 cua SetSceneFileName = 0: dang xem ban do canh KHAC) tat CA
	//     mui ten LAN moi cham.
	//   - `updateSelf`: chuot o ngoai cua so => d_MouseScenePos = vi tri nguoi choi (=> tieu de toa do).
	// O cay ta ba thuoc tinh tren da duoc CAT dang chuoi (CysStoredProperties.cpp:66-68) nhung KHONG noi
	// nao doc lai, va `setMinimapData` la than rong => du lieu di tron duong game -> host -> widget roi
	// roi vao hu khong, KHONG co ngoai le nao (V-6: 0 dong "There is no Property named" tren hai cua so).
	//
	// PHAN BIEN - cho KHONG chep nguyen (02-bang-vi-sai.md P-1): cay song day MOT danh sach hop nhat, moi
	// phan tu tu mang (mode,type). Ben game cua ta van la 9 danh sach theo LOP cua ma nguon 0.85
	// (CWorldManager::GetObjectListByClass) va chu ky `setMinimapData(lop,x,z,ten)`. Doi giao dien sang 5
	// doi so buoc viet lai UpdateMinimapData + CActivePosManager trong Game.exe; thu nguoi dung thieu nam
	// TRON trong widget. => giu chu ky cua ta, dat bang dich LOP -> type-cua-layout o DUNG MOT cho duoi day.
	//
	// KHONG doi layout lop / vtable (cung luat voi ValidateFriendWindows): trang thai nam trong bang phu
	// tra theo TEN cua so. Pool KHONG giu Window* qua cac lan dung nen (createBackground huy nen cung moi
	// con cua no) - moi lan dung deu tra lai theo TEN qua WindowManager, dung nhu cay song lam.
	//
	// CONG TAC (getenv doc MOT lan roi nho):
	//   CYS_MAPDOTS_LEGACY=1  => hanh vi CU nguyen ven (nhanh AM cua phep A/B, cung mot binary).
	//   CYS_MAPDOTS_LOG=1     => log chan doan DUONG NONG. MAC DINH TAT (luat chung muc 2: chot do khong
	//                            duoc lot vao ban choi). Chi in khi noi dung DOI so voi dong truoc.
	// ====================================================================================
	static bool CysDotsEnv( const char* szName, int& nCache )
	{
		if( nCache < 0 )
		{
			const char* p = ::getenv( szName );
			nCache = ( p && p[ 0 ] == '1' ) ? 1 : 0;
		}
		return nCache != 0;
	}
	static bool CysDotsLegacy()	{ static int s = -1; return CysDotsEnv( "CYS_MAPDOTS_LEGACY", s ); }
	static bool CysDotsLog()	{ static int s = -1; return CysDotsEnv( "CYS_MAPDOTS_LOG", s ); }

	enum { CYS_DOTS_CLASS_NUM = 9, CYS_DOTS_TYPE_MYSELF = 10 };

	// Bang dich LOP cua ta (chi so cua CWorldManager::GetObjectListByClass) -> `type` cua layout.
	// 0..4 trung nhau giua hai the he. 5/6/7/8 cua ta la enum 0.85 CU (active/scenepos/flash/pet), con
	// layout la so cua cay song: 6 = Map_Pet, 8 = Map_NPC (diem nhiem vu), 16 = Map_Trip (cong dich chuyen).
	// Co so tung dong: 02-bang-vi-sai.md muc 2.2.
	static int CysClassToLayoutType( const int nClass )
	{
		// Active=5 is Animate9 (direction), never Icon8 (NPC). Its separate
		// edge renderer selects a frame by angle; Icon9 remains intentionally absent.
		static const int kMap[ CYS_DOTS_CLASS_NUM ] = { 0, 1, 2, 3, 4, 9, 16, 8, 6 };
		return ( nClass >= 0 && nClass < CYS_DOTS_CLASS_NUM ) ? kMap[ nClass ] : -1;
	}

	struct CysMapDirection
	{
		int index, type;
		Point target;
		String name;
	};
	struct CysDotsState
	{
		bool							bParsed;
		std::map< int, const Image* >	mapIcon;		// IconN        -> anh
		std::map< int, std::string >	mapAnimate;		// AnimateN     -> ten animate
		std::map<int, std::string> mapFlash;
		std::vector<CysMapDirection> directions;
		std::string strChildAnimate;
		std::string						strChildImage;	// ChildItem key:Image
		int		nShow;			// doi so thu 4 cua SetSceneFileName (setShowMyself cua cay song)
		int		nPoolUsed;		// so cua so pool dang dung trong chu ky nay
		int		nPoolMade;		// moc cao nhat da tung dung (de an phan du)
		bool	bMouseIn;
		// chan doan (chi dung khi CYS_MAPDOTS_LOG=1)
		int		aFed[ CYS_DOTS_CLASS_NUM ];
		std::map< int, int >			mapDrawn;		// type layout -> so cham da ve trong chu ky
		int		nDroppedUnreg;
		std::string						strLastCycle;
		std::string						strLastArrow;
		CysDotsState() : bParsed( false ), nShow( 1 ), nPoolUsed( 0 ), nPoolMade( 0 ), bMouseIn( false ), nDroppedUnreg( 0 )
		{
			for( int i = 0; i < CYS_DOTS_CLASS_NUM; ++i ) aFed[ i ] = 0;
		}
	};
	static CysDotsState& CysDotsOf( const Window* pWin )
	{
		static std::map< std::string, CysDotsState > s;
		return s[ std::string( pWin->getName().c_str() ) ];
	}

	// Doc lai ba thuoc tinh da cat. Dinh dang chep NGUYEN tu chuoi sscanf trong DLL song:
	//   "type:Icon%d set:%127s image:%127s"  |  "type:Animate%d animate:%127s"
	// Thieu imageset / thieu anh thi BO QUA dong do, KHONG nem (bay 19/09: 0.85 nem o cho CY chay tiep).
	static void CysDotsParse( const Window* pWin, CysDotsState& st )
	{
		st.mapIcon.clear();
		st.mapAnimate.clear();
		st.mapFlash.clear();
		st.strChildAnimate.clear();
		st.strChildImage.clear();
		const std::string strIcon( cysStoredProperty( pWin, "IconImage" ).c_str() );
		const std::string strFlash( cysStoredProperty( pWin, "FlashAnimateImage" ).c_str() );
		const std::string strAnim( cysStoredProperty( pWin, "AnimateImage" ).c_str() );
		const std::string strChild( cysStoredProperty( pWin, "ChildItem" ).c_str() );
		size_t nPos = 0;
		while( nPos <= strIcon.size() )
		{
			size_t nEnd = strIcon.find( '\n', nPos );
			if( nEnd == std::string::npos ) nEnd = strIcon.size();
			const std::string strLine = strIcon.substr( nPos, nEnd - nPos );
			nPos = nEnd + 1;
			int nType = -1; char szSet[ 128 ] = { 0 }; char szImage[ 128 ] = { 0 };
			if( sscanf( strLine.c_str(), "type:Icon%d set:%127s image:%127s", &nType, szSet, szImage ) != 3 ) continue;
			try
			{
				const String strSet( (utf8*)szSet ), strImg( (utf8*)szImage );
				if( !ImagesetManager::getSingleton().isImagesetPresent( strSet ) ) continue;
				Imageset* pSet = ImagesetManager::getSingleton().getImageset( strSet );
				if( pSet && pSet->isImageDefined( strImg ) )
					st.mapIcon[ nType ] = &pSet->getImage( strImg );
			}
			catch( ... ) {}
		}
		nPos = 0;
		while( nPos <= strAnim.size() )
		{
			size_t nEnd = strAnim.find( '\n', nPos );
			if( nEnd == std::string::npos ) nEnd = strAnim.size();
			const std::string strLine = strAnim.substr( nPos, nEnd - nPos );
			nPos = nEnd + 1;
			int nType = -1; char szAnimate[ 128 ] = { 0 };
			if( sscanf( strLine.c_str(), "type:Animate%d animate:%127s", &nType, szAnimate ) != 2 ) continue;
			st.mapAnimate[ nType ] = szAnimate;
		}
		nPos = 0;
        while(nPos <= strFlash.size())
        {
            size_t end = strFlash.find('\n', nPos);
            if(end == std::string::npos) end = strFlash.size();
            const std::string line = strFlash.substr(nPos, end - nPos);
            nPos = end + 1;
            int type = -1; char animate[128] = {0};
            if(sscanf(line.c_str(), "type:FlashAnimateImage%d animate:%127s", &type, animate) == 2)
                st.mapFlash[type] = animate;
        }
		nPos = 0;
		while( nPos <= strChild.size() )
		{
			size_t nEnd = strChild.find( '\n', nPos );
			if( nEnd == std::string::npos ) nEnd = strChild.size();
			const std::string strLine = strChild.substr( nPos, nEnd - nPos );
			nPos = nEnd + 1;
			char szKey[ 128 ] = { 0 }; char szType[ 128 ] = { 0 };
			if( sscanf( strLine.c_str(), "key:%127s name:%127s", szKey, szType ) != 2 ) continue;
			if( strcmp( szKey, "Image" ) == 0 ) st.strChildImage = szType;
			if( strcmp( szKey, "Animate" ) == 0 ) st.strChildAnimate = szType;
		}
		st.bParsed = true;
	}

	// MOT dong moi lan dung ban do (hiem: doi canh / mo Alt+M) - bang chung ban va co mat va doc duoc gi.
	static void CysDotsLogCfg( const Window* pWin, const CysDotsState& st )
	{
		std::string s = "CYS-MAPDOTS: cfg win='" + std::string( pWin->getName().c_str() ) + "'";
		char sz[ 64 ];
		_snprintf( sz, sizeof( sz ), " legacy=%d show=%d icon_types=[", CysDotsLegacy() ? 1 : 0, st.nShow ); sz[ sizeof( sz ) - 1 ] = 0;
		s += sz;
		for( std::map< int, const Image* >::const_iterator it = st.mapIcon.begin(); it != st.mapIcon.end(); ++it )
		{
			_snprintf( sz, sizeof( sz ), "%s%d", it == st.mapIcon.begin() ? "" : ",", it->first ); sz[ sizeof( sz ) - 1 ] = 0;
			s += sz;
		}
		s += "] animate_types=[";
		for( std::map< int, std::string >::const_iterator it = st.mapAnimate.begin(); it != st.mapAnimate.end(); ++it )
		{
			_snprintf( sz, sizeof( sz ), "%s%d", it == st.mapAnimate.begin() ? "" : ",", it->first ); sz[ sizeof( sz ) - 1 ] = 0;
			s += sz;
		}
		s += "] child_image='" + st.strChildImage + "'";
		Logger::getSingleton().logEvent( String( (utf8*)s.c_str() ), Errors );
	}

	// Cua so pool thu nIndex, tra theo TEN (khong giu con tro). Kieu cua so lay tu `ChildItem key:Image`
	// cua layout (TLBB_StaticImageNULL) nhu cay song; thieu thi dung kieu ma chinh tep nay van dung cho o nen.
	static Window* CysDotsPoolWindow( const Window* pOwner, Window* pBackground, const CysDotsState& st, const int nIndex, const int nKind = 0 )
	{
		char szName[ 192 ];
		_snprintf( szName, sizeof( szName ), "%s_Window_Pool%d_%d", pOwner->getName().c_str(), nKind, nIndex );
		szName[ sizeof( szName ) - 1 ] = 0;
		WindowManager& wm = WindowManager::getSingleton();
		Window* pWin = NULL;
		try
		{
			if( wm.isWindowPresent( szName ) )
				pWin = wm.getWindow( szName );
			else
			{
				try
				{
					const std::string& childType = nKind == 1 ? st.strChildAnimate : st.strChildImage;
					if( !childType.empty() )
						pWin = wm.createWindow( String( (utf8*)childType.c_str() ), szName );
				}
				catch( ... ) { pWin = NULL; }
				if( !pWin ) pWin = wm.createWindow( nKind == 1 ? "Falagard/AnimateImage" : "WoWLook/StaticImage", szName );
				pWin->setMaximumSize( Size( 100, 100 ) );
				pWin->setHookMode( Hook_Center );
				pWin->setZoomMode( Relative );
				pWin->setAlwaysOnTop( false );
				pWin->setRiseOnClickEnabled( false );
				// Cham KHONG duoc nuot chuot: bam len ban do la di chuyen toi do.
				pWin->setMouseHollow( true );
				pWin->setMouseMoveHollow( true );
				pWin->setMouseLButtonHollow( true );
				pWin->setMouseRButtonHollow( true );
			}
			if( pWin->getParent() != pBackground )
				pBackground->addChildWindow( pWin );
		}
		catch( ... ) { return NULL; }
		return pWin;
	}

	static void CysDotsHidePool( const Window* pOwner, const int nFrom, const int nTo )
	{
		char szName[ 192 ];
		WindowManager& wm = WindowManager::getSingleton();
		for( int i = nFrom; i < nTo; ++i )
		{
            for(int kind = 0; kind < 3; ++kind)
            {
                _snprintf(szName, sizeof(szName), "%s_Window_Pool%d_%d", pOwner->getName().c_str(), kind, i);
                szName[sizeof(szName) - 1] = 0;
                if(wm.isWindowPresent(szName)) wm.getWindow(szName)->hide();
            }
		}
	}

    // Live GL/CY: a directional frame is a compass lookup, not a timed animation.
    // The source uses background coordinates; compute the ray in viewport pixels and
    // convert its intersection back to HookPosition so the viewport mask and markers agree.
    static bool CysDotsDirection(Window* owner, Window* background, CysDotsState& st, const CysMapDirection& direction)
    {
        const std::map<int, std::string>::const_iterator found = st.mapAnimate.find(direction.type);
        if(found == st.mapAnimate.end()) return false;
        const String animation((utf8*)found->second.c_str());
        if(!AnimateManager::getSingleton().isAnimatePresent(animation)) return false;
        Animate* frames = (Animate*)AnimateManager::getSingleton().getAnimate(animation);
        if(!frames || frames->getFrameNumber() <= 0) return false;
        Window* marker = CysDotsPoolWindow(owner, background, st, direction.index, 2);
        StaticImage* image = marker ? dynamic_cast<StaticImage*>(marker) : NULL;
        if(!image) return false;
        const Rect map = owner->getPixelRect(), bg = background->getPixelRect();
        const float bw = bg.getWidth(), bh = bg.getHeight();
        if(bw <= 0 || bh <= 0) { marker->hide(); return false; }
        const Point target(bg.d_left + direction.target.d_x * bw, bg.d_top + direction.target.d_y * bh);
        if(st.nShow == 0 || map.isPointInRect(target)) { marker->hide(); return false; }
        const float cx = (map.d_left + map.d_right) * .5f, cy = (map.d_top + map.d_bottom) * .5f;
        const float dx = target.d_x - cx, dy = target.d_y - cy;
        float degrees = atan2f(-dy, dx) / .01745329238474369f;
        if(degrees < 0) degrees += 360;
        const int frame = int(degrees * frames->getFrameNumber() / 360) % frames->getFrameNumber();
        const Image* icon = frames->getFrame(frame);
        if(!icon) { marker->hide(); return false; }
        const Size size = icon->getSourceTextureArea().getSize();
        const float halfW = map.getWidth() * .5f - size.d_width * .5f;
        const float halfH = map.getHeight() * .5f - size.d_height * .5f;
        if(halfW <= 0 || halfH <= 0) { marker->hide(); return false; }
        float scale;
        if(CysWantRound(owner, 1))
        {
            const float radius = halfW < halfH ? halfW : halfH;
            const float length = sqrtf(dx * dx + dy * dy);
            if(length <= 0) { marker->hide(); return false; }
            scale = radius / length;
        }
        else
        {
            const float sx = fabsf(dx) > .00001f ? halfW / fabsf(dx) : 1.0e20f;
            const float sy = fabsf(dy) > .00001f ? halfH / fabsf(dy) : 1.0e20f;
            scale = sx < sy ? sx : sy;
        }
        if(image->getImage() != icon) image->setImage(icon);
        const float edgeX = cx + dx * scale, edgeY = cy + dy * scale;
        const Rect old = marker->getPixelRect();
        if(marker->getAbsoluteSize() != size || fabsf((old.d_left+old.d_right)*.5f-edgeX) > .01f ||
           fabsf((old.d_top+old.d_bottom)*.5f-edgeY) > .01f)
        {
            marker->setHookPosition(Point((edgeX-bg.d_left)/bw, (edgeY-bg.d_top)/bh));
            marker->setSize(Absolute, size);
        }
        if(marker->getText() != direction.name) marker->setText(direction.name);
        marker->show();
        if(CysDotsLog())
        {
            char line[256];
            _snprintf(line, sizeof(line), "CYS-MAPDOTS: direction win='%s' type=%d frame=%d/%d target=(%.3f,%.3f) edge=(%.3f,%.3f)",
                owner->getName().c_str(), direction.type, frame, frames->getFrameNumber(), target.d_x, target.d_y, cx+dx*scale, cy+dy*scale);
            line[sizeof(line)-1]=0;
            Logger::getSingleton().logEvent(String((utf8*)line), Errors);
        }
        return true;
    }

	// Ghi lại tệp bản đồ của lần CreateSceneMap gần nhất, để phép đo ép được đúng kịch bản.
	static std::string	g_strLastSceneFile;
	static int			g_nLastSceneSharp = 0;
	static bool			g_bProbeDone = false;
	static int			g_nProbeTick = 0;

	FalagardSceneMap::FalagardSceneMap(const String& type, const String& name) :
		FalagardStaticImage(type, name)
	{
		CEGUI_START_ADD_STATICPROPERTY( FalagardSceneMap )
		   CEGUI_ADD_STATICPROPERTY( &d_PlayerImageProperty );
		   CEGUI_ADD_STATICPROPERTY( &d_MyselfImageProperty );
		CEGUI_END_ADD_STATICPROPERTY
		
		d_fresh = false;
		d_PlayerDirect = 0;
		d_MyselfAnimate.clear();// = "";
		m_pMySelfWindow = NULL;
		m_pLTWindow		= NULL;
		m_pRBWindow		= NULL;
		m_nXCount		= 0;
		m_nYCount		= 0;
		d_MouseScenePos = Point( 0, 0 );
		// CYS-MAPDOTS 20/09: Vector2() cua CEGUI KHONG khoi tao thanh vien. Tu nay updateSelf() chep
		// m_PlayerPos sang d_MouseScenePos moi khung (nhu cay song) nen gia tri rac se len thang tieu de
		// toa do cua minimap cho toi lan UpdateFlag dau tien.
		m_PlayerPos		= Point( 0, 0 );
		d_MyseflPos		= Point( 0, 0 );
		CysDotsOf( this ) = CysDotsState(); // a recreated window may reuse its old name
		d_SceneSize		= Size( 128, 128 );
		d_PlayerImage	= NULL;
		for( int i = 0; i < 5; i ++ )
			m_pFriendWindow[ i ] = NULL;
		m_pBackground = NULL;
		m_WindowZero = Point( 0, 0 );
		m_aPlayerPos.clear();
		m_fZoomValueX = 1; // 默认为一乒全都显示
		m_fZoomValueY = 1; // 默认为一乒全都显示
		m_bDraping = false;
		m_nDisplayMode = SCENEMAP_DISPLAY_MODE_ABSOLTE;
		setMouseHollow( true );
	}

	FalagardSceneMap::~FalagardSceneMap()
	{
	}
	void FalagardSceneMap::Close()
	{
		Clear();

		uint child_count = getChildCount();
		for (uint i = 0; i < child_count; ++i)
		{
			d_children[i]->hide();

		}
		//WindowManager::getSingleton().destroyWindow( "SceneMapWindow_background" );
		if( m_pMySelfWindow )
		{
			m_pMySelfWindow = NULL;
		}
		for( int i = 0; i < 5; i ++ )
		{
			m_pFriendWindow[ i ] = NULL;
		}

		m_pLTWindow = NULL;
		m_pRBWindow = NULL;
		

	}
	void FalagardSceneMap::addPlayerPos( const Point& pos, const String& name )
	{
		SCENEMAP_FLAG_DATA  data;
		data.pos = pos;
		data.name = name;
		m_aPlayerPos.push_back( data );
		d_fresh = true;
	}
	void FalagardSceneMap::onMouseButtonDown( MouseEventArgs &e )
	{
		
		// 计算和原点之间的位置
		// 得到当前鼠标点在了相对于左上角的那个位置
		m_ptDrapOffset = ScreenPosToScenePosRelative( e.position );
		if( e.button == RightButton )
		{
			if( e.sysKeys & Control )
				return;
			m_bDraping = true;
			e.handled = true;
			captureInput();
		}
		Window::onMouseButtonDown( e );
	}
	void FalagardSceneMap::onMouseEnters(MouseEventArgs& e)
	{
		CysDotsOf( this ).bMouseIn = true; // CYS-MAPDOTS 20/09 (V-11)
		d_MouseScenePos = ScreenPosToScenePos( e.position );
		d_MouseScenePos.d_x /= m_fZoomValueX;
		d_MouseScenePos.d_y /= m_fZoomValueY;
		if( d_MouseScenePos.d_x < 0 || d_MouseScenePos.d_x > d_SceneSize.d_width ||
			d_MouseScenePos.d_y < 0 || d_MouseScenePos.d_y > d_SceneSize.d_height )
		{
			d_MouseScenePos.d_x = 0;
			d_MouseScenePos.d_y = 0;
		}
		Window::onMouseEnters( e );
	}
	void FalagardSceneMap::onMouseButtonUp( MouseEventArgs &e )
	{
		if( e.button == RightButton && ( e.sysKeys & Control ) )
		{
			WindowEventArgs args(this);
			fireEvent(MouseRButtonDownCtrl, args, EventNamespace);
			return;
		}
		m_bDraping = false;
		releaseInput();
		Window::onMouseButtonUp( e );
	}
    void FalagardSceneMap::onMouseClicked(MouseEventArgs& e)
    {
        d_MouseScenePos = ScreenPosToScenePos(e.position);
        d_MouseScenePos.d_x /= m_fZoomValueX;
        d_MouseScenePos.d_y /= m_fZoomValueY;
        Window::onMouseClicked(e);
        // CY SceneMap.layout.xml subscribes to this native map event. The
        // old Window only emits MouseLClick, leaving the callback unreachable.
        if (e.button == LeftButton)
            fireEvent("MouseLButtonClick", e, EventNamespace);
    }
	void    FalagardSceneMap::onMouseLeaves( MouseEventArgs& e )
	{
		CysDotsOf( this ).bMouseIn = false; // CYS-MAPDOTS 20/09 (V-11)
		m_bDraping = false;
		d_MouseScenePos = m_PlayerPos;
		Window::onMouseLeaves( e );
	}

	void FalagardSceneMap::onMouseMove( MouseEventArgs &e )
	{
		
		if( m_bDraping ) // 正在托动
		{
			Point tmp = ScreenPosToWindowPosRelative( e.position );
			m_WindowZero.d_x = tmp.d_x - m_ptDrapOffset.d_x;
			m_WindowZero.d_y = tmp.d_y - m_ptDrapOffset.d_y;
			
			UpdateAllWindow();
		}
		else
		{
			d_MouseScenePos = ScreenPosToScenePos( e.position );
			d_MouseScenePos.d_x /= m_fZoomValueX;
			d_MouseScenePos.d_y /= m_fZoomValueY;
			if( d_MouseScenePos.d_x < 0 || d_MouseScenePos.d_x > d_SceneSize.d_width ||
				d_MouseScenePos.d_y < 0 || d_MouseScenePos.d_y > d_SceneSize.d_height )
				return;
		}
		FalagardStaticImage::onMouseMove( e );
	}
	// CYS-CRASHCEGUI: phép đo ÉP ĐÚNG KỊCH BẢN, bật bằng CYS_CRASHCEGUI_LIVE=1.
	// Người chơi mở bản đồ lớn => SceneMap.lua:426 `SceneMap_Show` => SceneMap_Board:SetSceneFileName.
	// Mở HAI lần là đủ: lần đầu Board nhận con nuôi năm ô đánh dấu, lần sau createBackground()
	// huỷ chúng cùng cửa sổ nền của Board, còn MiniMap_MapArea giữ nguyên con trỏ đã chết.
	// Ở đây ta gọi đúng hàm đó hai lần rồi ĐẾM xem MiniMap còn trỏ vào cửa sổ đã bị huỷ hay không.
	// An toàn khi gọi trong lúc cập nhật cây: destroyWindow() chỉ đưa vào deathrow, việc delete
	// thật nằm ở cleanDeadPool() sau vòng update.
	void FalagardSceneMap::RunCrashCeguiProbe()
	{
		if( g_bProbeDone || g_strLastSceneFile.empty() ) return;
		const char* pEnv = getenv( "CYS_CRASHCEGUI_LIVE" );
		if( !pEnv || pEnv[ 0 ] != '1' ) return;
		// Chờ vài khung hình cho `SceneMap_Board` có mặt, nhưng KHÔNG chờ lâu: lượt live
		// 19/09 chết ở một cú văng khác (đường trang bị, `GCDetailEquipList`) ngay đúng giây
		// vào thế giới, nên chờ ~5 s là phép đo không bao giờ kịp chạy. Chỉnh được bằng
		// CYS_CRASHCEGUI_DELAY nếu cần dời muộn hơn.
		int nDelay = 2;
		if( const char* pDelay = getenv( "CYS_CRASHCEGUI_DELAY" ) ) nDelay = atoi( pDelay );
		if( ++g_nProbeTick < nDelay ) return;
		g_bProbeDone = true;

		WindowManager& wm = WindowManager::getSingleton();
		Logger& log = Logger::getSingleton();
		const String strBoard( (utf8*)"SceneMap_Board" );
		const String strMini( (utf8*)"MiniMap_MapArea" );
		if( !wm.isWindowPresent( strBoard ) || !wm.isWindowPresent( strMini ) )
		{
			log.logEvent( "CYS-CRASHCEGUI PROBE: thieu SceneMap_Board hoac MiniMap_MapArea => KHONG DO DUOC", Errors );
			return;
		}
		FalagardSceneMap* pBoard = (FalagardSceneMap*)wm.getWindow( strBoard );
		FalagardSceneMap* pMini  = (FalagardSceneMap*)wm.getWindow( strMini );
		const String strFile( (utf8*)g_strLastSceneFile.c_str() );

		log.logEvent( "CYS-CRASHCEGUI PROBE: gia lap MO BAN DO LON lan 1", Errors );
		pBoard->SetSceneFileName( strFile, g_nLastSceneSharp );
		log.logEvent( "CYS-CRASHCEGUI PROBE: gia lap MO BAN DO LON lan 2", Errors );
		pBoard->SetSceneFileName( strFile, g_nLastSceneSharp );

		int nStale = 0, nNull = 0;
		char szName[ 128 ];
		for( int i = 0; i < 5; i ++ )
		{
			CysMarkerName( szName, pMini->getName(), i );
			Window* pLive = wm.isWindowPresent( szName ) ? wm.getWindow( szName ) : NULL;
			if( !pMini->m_pFriendWindow[ i ] ) nNull ++;
			else if( pMini->m_pFriendWindow[ i ] != pLive ) nStale ++;
		}
		char szMsg[ 256 ];
		_snprintf( szMsg, sizeof( szMsg ) - 1,
			"CYS-CRASHCEGUI PROBE KET QUA: sau 2 lan SceneMap_Show, MiniMap_MapArea stale=%d/5 null=%d/5",
			nStale, nNull );
		log.logEvent( (utf8*)szMsg, Errors );
	}

	// CYS-CRASHCEGUI: keep m_pFriendWindow[] honest before anything dereferences it.
	// Close() nulls the array while updateSelf() never checked, and a marker window can
	// still be destroyed by its parent behind our back. Five registry lookups, only on a
	// frame that has already decided it needs to redraw.
	void FalagardSceneMap::ValidateFriendWindows()
	{
		char szWindowName[ 128 ];
		WindowManager& wm = WindowManager::getSingleton();
		for( int i = 0; i < 5; i ++ )
		{
			CysMarkerName( szWindowName, getName(), i );
			Window* pLive = wm.isWindowPresent( szWindowName ) ? wm.getWindow( szWindowName ) : NULL;
			if( m_pFriendWindow[ i ] != pLive )
			{
				// Loud on purpose. If this ever fires again the marker changed owner
				// behind us, and we want that in UISystem.log instead of a #GP minutes later.
				Logger::getSingleton().logEvent( "CYS-CRASHCEGUI: SceneMap '" + getName() +
					"' dropped a stale teammate marker '" + String( (utf8*)szWindowName ) + "'.", Errors );
				m_pFriendWindow[ i ] = pLive;
			}
		}
	}
	void FalagardSceneMap::updateSelf(float elapsed)
	{
		RunCrashCeguiProbe(); // CYS-CRASHCEGUI: chi lam gi khi CYS_CRASHCEGUI_LIVE=1
		// CYS-MAPDOTS 20/09 (V-11): cay song - FalagardSceneMap::updateSelf cua client_GL\Bin64\CEGUIFalagard.dll:
		//   `if (!m_bMouseInWindow) d_MouseScenePos = m_PlayerPos;`
		// MiniMap.lua lay tieu de toa do tu MiniMap_MapArea:GetMouseScenePos() (Minimap_CoordinateUpdate).
		// Dong nay truoc gio chi co o FalagardRadar::updateSelf - lop khong scheme nao anh xa toi - nen
		// tieu de minimap luon la "0 0" cho toi khi chuot di vao roi di ra khoi minimap.
		if( !CysDotsLegacy() && !CysDotsOf( this ).bMouseIn )
			d_MouseScenePos = m_PlayerPos;
        if(!CysDotsLegacy() && m_pBackground && isVisible())
        {
            CysDotsState& state = CysDotsOf(this);
            for(size_t i=0; i<state.directions.size(); ++i)
                CysDotsDirection(this, m_pBackground, state, state.directions[i]);
        }
		if( d_fresh && isVisible() )
		{
			int i = 0;
			// 更新自己得图片
			ResetMyself();
			// 更新队友得位置和信息
			ValidateFriendWindows(); // CYS-CRASHCEGUI

			for( i = 0; i < 5; i ++ )
				if( m_pFriendWindow[ i ] ) // CYS-CRASHCEGUI
					m_pFriendWindow[ i ]->hide();
			RENDER_POS::iterator   it;
			String strTooltip[ 5 ]; //5个人得tooltip
			// CYS-CRASHCEGUI: m_aPlayerPos can hold more entries than there are marker
			// windows (a full TLBB team is six) and ResetPlayerWindow indexes
			// m_pFriendWindow[ nIndex ] directly, so past five it walks into
			// m_pMySelfWindow and the pointers declared after it. Stop at the bound.
			for( i = 0, it = m_aPlayerPos.begin(); it != m_aPlayerPos.end() && i < 5; it ++, i ++ )
			{
				ResetPlayerWindow( i, ( *it ) );

			}
			// 更新tooltip 
			
			for( int i = 0; i < 5; i ++ )
			{
				
				if( !m_pFriendWindow[ i ] || !m_pFriendWindow[ i ]->isVisible() ) // CYS-CRASHCEGUI // 如果可见才计算
					break;
				strTooltip[ i ] = m_pFriendWindow[ i ]->getTooltipText();
				for( int j = 0; j < 5; j ++ )
				{
					if( j == i )
						continue;
					if( !m_pFriendWindow[ j ] || !m_pFriendWindow[ j ]->isVisible() ) // CYS-CRASHCEGUI
						break;
					if( Rect( 0, 0, 0, 0 ) != m_pFriendWindow[ i ]->getRect().getIntersection( m_pFriendWindow[ j ]->getRect() ) )
					{
						if( strTooltip[ i ].size() )
							strTooltip[ i ] += "\r\n";
						strTooltip[ i ] += m_pFriendWindow[ j ]->getTooltipText();
					}

				}
			}
			for( int i = 0; i < 5; i ++ )
			{
				if( !m_pFriendWindow[ i ] || !m_pFriendWindow[ i ]->isVisible() ) // CYS-CRASHCEGUI // 如果可见才计算
					break;
				m_pFriendWindow[ i ]->setTooltipText( strTooltip[ i ] );

			}
			d_fresh = false;
			requestRedraw();
		}
	}
	void FalagardSceneMap::setPlayerImage( const Image* pImage )
	{
		
		d_PlayerImage = ( Image* )pImage;
	}

	void FalagardSceneMap::setMyselfImage( const String& name )
	{
		d_MyselfAnimate = name;
	}
	void FalagardSceneMap::Clear()
	{
		m_aPlayerPos.clear();
		// CYS-MAPDOTS 20/09: Minimap::UpdateFlag goi Clear() NGAY TRUOC khi day lai toan bo dau
		// (UILuaControl.cpp, nhanh `m_pWindow->isVisible()`), nen day la moc BAT DAU mot chu ky.
		// Cay song lam dung the: freeAllWindow() -> ClearPool() roi moi setMinimapData().
		CysDotsState& st = CysDotsOf( this );
		if( CysDotsLog() )
		{
			// In chu ky VUA XONG (khong co moc "het chu ky" nao khac). Chi in khi noi dung DOI.
			std::string s;
			char sz[ 160 ];
			_snprintf( sz, sizeof( sz ), "show=%d pool=%d fed=[%d,%d,%d,%d,%d,%d,%d,%d,%d] drawn={", st.nShow, st.nPoolUsed,
				st.aFed[ 0 ], st.aFed[ 1 ], st.aFed[ 2 ], st.aFed[ 3 ], st.aFed[ 4 ], st.aFed[ 5 ], st.aFed[ 6 ], st.aFed[ 7 ], st.aFed[ 8 ] );
			sz[ sizeof( sz ) - 1 ] = 0;
			s = sz;
			for( std::map< int, int >::const_iterator it = st.mapDrawn.begin(); it != st.mapDrawn.end(); ++it )
			{
				_snprintf( sz, sizeof( sz ), "%s%d:%d", it == st.mapDrawn.begin() ? "" : ",", it->first, it->second ); sz[ sizeof( sz ) - 1 ] = 0;
				s += sz;
			}
			_snprintf( sz, sizeof( sz ), "} dropped_unreg=%d mouse=(%d,%d) pos=(%d,%d)", st.nDroppedUnreg,
				int( d_MouseScenePos.d_x ), int( d_MouseScenePos.d_y ), int( m_PlayerPos.d_x ), int( m_PlayerPos.d_y ) );
			sz[ sizeof( sz ) - 1 ] = 0;
			s += sz;
			if( s != st.strLastCycle )
			{
				st.strLastCycle = s;
				Logger::getSingleton().logEvent( String( (utf8*)( "CYS-MAPDOTS: cycle win='" + std::string( getName().c_str() ) + "' " + s ).c_str() ), Errors );
			}
		}
		if( CysDotsLegacy() ) return; // keep negative-arm telemetry, then preserve its empty implementation
		CysDotsHidePool( this, 0, st.nPoolMade );
		st.nPoolUsed = 0;
		st.directions.clear();
		for( int i = 0; i < CYS_DOTS_CLASS_NUM; ++i ) st.aFed[ i ] = 0;
		st.mapDrawn.clear();
		st.nDroppedUnreg = 0;
	}

	// CYS-MAPDOTS 20/09 (V-9): than that cua ham truoc day la `{}` trong header.
	void FalagardSceneMap::setMinimapData( int nType, float fX, float fY, String& szName )
	{
		if( CysDotsLegacy() ) return;				// nhanh AM cua phep A/B: giu nguyen than rong cu
		if( !m_pBackground ) return;				// chua SetSceneFileName lan nao
		CysDotsState& st = CysDotsOf( this );
		if( !st.bParsed ) CysDotsParse( this, st );
		if( nType >= 0 && nType < CYS_DOTS_CLASS_NUM ) st.aFed[ nType ] ++;
		// Cay song: setWindowByImage chi ve khi m_nShowMyself == 1. Dang xem ban do cua canh KHAC
		// (SceneMap.lua:818 truyen 0) thi vat the cua canh DANG DUNG khong co nghia tren do.
		if( st.nShow == 0 ) return;
		const int nLayoutType = CysClassToLayoutType( nType );
        const std::map<int, const Image*>::const_iterator icon = st.mapIcon.find(nLayoutType);
        const bool direction = (nType == 5 || nType == 7) && st.mapAnimate.find(nLayoutType) != st.mapAnimate.end();
        const std::map<int, std::string>::const_iterator flash = st.mapFlash.find(nLayoutType);
        const bool flashing = nType == 7 && flash != st.mapFlash.end();
        if(icon == st.mapIcon.end() && !direction && !flashing) { ++st.nDroppedUnreg; return; }
        if(d_SceneSize.d_width <= 0 || d_SceneSize.d_height <= 0 || st.nPoolUsed >= 256) return;
        const int index = st.nPoolUsed++;
        if(st.nPoolUsed > st.nPoolMade) st.nPoolMade = st.nPoolUsed;
        const Point position = ScenePosToWindowPos(Point(fX, fY));
        bool drawn = false;
        if(icon != st.mapIcon.end() && icon->second)
        {
            Window* dot = CysDotsPoolWindow(this, m_pBackground, st, index);
            StaticImage* image = dot ? dynamic_cast<StaticImage*>(dot) : NULL;
            if(image)
            {
                image->setImage(icon->second);
                dot->setHookPosition(position);
                dot->setSize(Absolute, icon->second->getSourceTextureArea().getSize());
                dot->setText(szName);
                dot->show();
                drawn = true;
            }
        }
        if(flashing)
        {
            const String animation((utf8*)flash->second.c_str());
            if(AnimateManager::getSingleton().isAnimatePresent(animation))
            {
                Animate* frames = (Animate*)AnimateManager::getSingleton().getAnimate(animation);
                Window* window = CysDotsPoolWindow(this, m_pBackground, st, index, 1);
                FalagardAnimateImage* effect = window ? dynamic_cast<FalagardAnimateImage*>(window) : NULL;
                const Image* first = frames ? frames->getFrame(0) : NULL;
                if(effect && first)
                {
                    if(effect->getAnimate() != animation) effect->setAnimate(animation);
                    effect->setHookPosition(position);
                    effect->setSize(Absolute, first->getSourceTextureArea().getSize());
                    effect->setText("");
                    effect->show();
                    drawn = true;
                }
            }
        }
        if(direction)
        {
            CysMapDirection d;
            d.index=index; d.type=nLayoutType; d.target=position; d.name=szName;
            st.directions.push_back(d);
            if(CysDotsDirection(this,m_pBackground,st,d)) drawn=true;
        }
        if(drawn) ++st.mapDrawn[nLayoutType];
	}
	void    FalagardSceneMap::SetViewByCenter( const Point& pos )
	{
		if( m_pBackground )
		{
			float fWidthWindowPerBackground = getAbsoluteWidth() / m_pBackground->getAbsoluteWidth();
			float fHeightWindowPerBackground = getAbsoluteHeight() / m_pBackground->getAbsoluteHeight();
			m_WindowZero.d_x = -( pos.d_x - fWidthWindowPerBackground / 2 ) / fWidthWindowPerBackground;
			m_WindowZero.d_y = -( pos.d_y - fHeightWindowPerBackground / 2 ) / fHeightWindowPerBackground;
			UpdateAllWindow();
		}
	}
	void FalagardSceneMap::setMyselfDir( const int nDirect )
	{
		d_PlayerDirect = ( nDirect ) % 360; 
		if( d_PlayerDirect < 0 )
			d_PlayerDirect += 360;
		d_fresh = true;
	}
	void FalagardSceneMap::setMyselfPos( const Point& pos )
	{
		m_PlayerPos = pos;
		d_MyseflPos = ScenePosToWindowPos( pos );	
		// UpdateFlag is followed by GetMouseScenePos in the same Lua event.
		// Publish this sample immediately, without waiting for the next UI frame.
		if( !CysDotsLegacy() && !CysDotsOf( this ).bMouseIn )
			d_MouseScenePos = pos;
		d_fresh = true;
	}
	void FalagardSceneMap::SetSceneFileName( const String& str, const int nUserSharp )
	{
		CreateSceneMap( str.c_str(), nUserSharp );
	}
	void FalagardSceneMap::onParentSized( WindowEventArgs &e )
	{
		FalagardStaticImage::onParentSized( e );
		UpdateAllWindow();
	}
	// 得到当前视口中心在背景上的位置
	Point	FalagardSceneMap::GetCurrentCenter()
	{
		Point pos;
		float fWidthWindowPerBackground = getAbsoluteWidth() / m_pBackground->getAbsoluteWidth();
		float fHeightWindowPerBackground = getAbsoluteHeight() / m_pBackground->getAbsoluteHeight();
		pos.d_x = -m_WindowZero.d_x * fWidthWindowPerBackground + fWidthWindowPerBackground / 2;
		pos.d_y = -m_WindowZero.d_y * fHeightWindowPerBackground + fHeightWindowPerBackground / 2 ;
		return pos;
	}
	// 得到当前视口在背景上的可见范围
	Rect FalagardSceneMap::GetCurrentViewRect() 
	{
		Rect rect;
		float fWidthWindowPerBackground = getAbsoluteWidth() / m_pBackground->getAbsoluteWidth();
		float fHeightWindowPerBackground = getAbsoluteHeight() / m_pBackground->getAbsoluteHeight();
		rect.d_left		= -m_WindowZero.d_x * fWidthWindowPerBackground;
		rect.d_top		= -m_WindowZero.d_y * fHeightWindowPerBackground;
		rect.d_right	= rect.d_left + fWidthWindowPerBackground;
		rect.d_bottom	= rect.d_top + fHeightWindowPerBackground;
		return rect;
	}
	void  FalagardSceneMap::UpdateAllWindow()
	{
		if( m_pBackground == NULL )
			return;
		// 根据缩放比例放置地图
		// 如果是1:1比例，正好全屏
		float fMax = ( d_SceneSize.d_width > d_SceneSize.d_height ) ? d_SceneSize.d_width : d_SceneSize.d_height;
		if( m_nDisplayMode == SCENEMAP_DISPLAY_MODE_FULLSCREEN ) 
		{
			float fScale = getAbsoluteHeight() / getAbsoluteWidth();
			m_fZoomValueX = fScale * d_SceneSize.d_width / fMax ;
			m_fZoomValueY = d_SceneSize.d_height / fMax;
		}
		else 
		{
			m_fZoomValueX = d_SceneSize.d_width * SCENE_MAP_ZOOMSCALE / getAbsoluteWidth(); 
			m_fZoomValueY = d_SceneSize.d_height * SCENE_MAP_ZOOMSCALE / getAbsoluteHeight(); 
		}
		
		Rect winRect;
		winRect = Rect( 0, 0, m_fZoomValueX, m_fZoomValueY );
		if( m_fZoomValueX < 1 ) // 说明宽度不够,就得居中显示了									
		{
			winRect.d_left = ( 1 - m_fZoomValueX ) / 2;
			winRect.d_right = winRect.d_left + m_fZoomValueX;
			m_WindowZero.d_x = winRect.d_left;
		}
		else
		{
			if( m_WindowZero.d_x < 1 - m_fZoomValueX  )
				m_WindowZero.d_x = 1 - m_fZoomValueX;
			if( m_WindowZero.d_x > 0 )
				m_WindowZero.d_x = 0;
		}
		if( m_fZoomValueY < 1 )
		{
			winRect.d_top = ( 1 - m_fZoomValueY ) / 2;
			winRect.d_bottom = winRect.d_top + m_fZoomValueY;
			m_WindowZero.d_y = winRect.d_top;
		}
		else
		{
			if( m_WindowZero.d_y < 1 - m_fZoomValueY )
				m_WindowZero.d_y = 1 - m_fZoomValueY;
			if( m_WindowZero.d_y > 0 )
				m_WindowZero.d_y = 0;
		}
		m_pBackground->setRect( Relative, winRect );
		m_pBackground->setSize( Relative, winRect.getSize() );
		
		m_pBackground->setPosition( Relative, m_WindowZero );
		m_pBackground->show();
		UpdateBackgroundItem();
		requestRedraw();
		d_fresh = true;
	}
	void FalagardSceneMap::UpdateBackgroundItem()
	{
		// CYS-SCENEMAP 20/09: ham nay la bo cuc "MOT tam anh 1280x1280" cua 0.85. Duoi day no ep
		// m_nXCount = m_nYCount = 1 roi dat LAI kich thuoc TUYET DOI cho DUY NHAT o <win>_map_0_0.
		// Khi ta lat o, 63 o kia giu rect tuong doi dung con o (0,0) bi keo len 1280 px => o dau
		// tien hien ra goc tren-trai cua tep .dds phong 5x. Voi jpg_luoyang_new_0_0.dds goc do la
		// den tuyet doi (do duoc: trung binh RGB cua 52x52 px dau = 0,0,0) nen ra mot HINH CHU NHAT
		// DEN o goc tren-trai ban do lon; con canh chi co MOT o (Dia Phu, jpg_siwangscene_0_0.dds)
		// thi CA minimap bi phong 5x. Duong lat o da dat rect TUONG DOI (i/nx, j/ny) nen no tu theo
		// kich thuoc nen - khong can buoc nay. Nhanh LEGACY giu nguyen hanh vi cu de phep A/B chi
		// khac DUNG MOT bien so.
		if( !CysRoundLegacy() && CysIsTiled( this ) )
			return;
		int i = 0;
		char szWindowName[ 128 ];
		float fOffsetX, fOffsetY; // 这是个比例值
	
		fOffsetX = float( ( int( d_SceneSize.d_width ) % SCENE_MAP_PER_PIC ) / float( SCENE_MAP_PER_PIC ) );  
		fOffsetY = float( ( int( d_SceneSize.d_height ) % SCENE_MAP_PER_PIC ) / float( SCENE_MAP_PER_PIC ) );
		m_nXCount =  int( d_SceneSize.d_width ) / SCENE_MAP_PER_PIC;
		m_nYCount =  int( d_SceneSize.d_height ) / SCENE_MAP_PER_PIC;
		if( fOffsetX ) // 如果有多余就多加一块
			m_nXCount += 1;
		else 
			fOffsetX = 1;
		if( fOffsetY )
			m_nYCount += 1;
		else 
			fOffsetY = 1;
		Size size;
		float fPicSizeX = 1280, fPicSizeY = 1280;
		if( m_nDisplayMode == SCENEMAP_DISPLAY_MODE_FULLSCREEN )
		{
			float fMax = ( d_SceneSize.d_width > d_SceneSize.d_height ) ? d_SceneSize.d_width : d_SceneSize.d_height;
			float fScale = getAbsoluteHeight() / getAbsoluteWidth();
			fPicSizeX *= fScale * getAbsoluteWidth() / ( fMax * SCENE_MAP_ZOOMSCALE ); 
			fPicSizeY *= getAbsoluteHeight() / ( fMax * SCENE_MAP_ZOOMSCALE );
		}
		Point pos( 0, 0);
		m_nXCount = 1;
		m_nYCount = 1;
		for( i = 0; i < m_nXCount; i ++ )
		{
			if( i == m_nXCount - 1 && fOffsetX != 1 ) // 如果是x最后一个,并且图有多余得
				size.d_width = float( fOffsetX * fPicSizeX );
			else
				size.d_width = fPicSizeX;
			
			for( int j = 0; j < m_nYCount; j ++ ) // 创建所有得图片，创建响应得窗口
			{
				
				if( j == m_nYCount - 1 && fOffsetY != 1 )
					size.d_height = float( fOffsetY * fPicSizeY);
				else
					size.d_height = fPicSizeY;

				sprintf( szWindowName, "%s_map_%d_%d", getName().c_str(),i, j ); 
				Window* pWindow = (StaticImage*)WindowManager::getSingleton().getWindow( szWindowName );
				if( pWindow )
				{
					pWindow->setPosition( Absolute, pos );
					pWindow->setSize( Absolute, size );
				}
				pos.d_y += size.d_height;

			}
			pos.d_x += size.d_width; 
			pos.d_y = 0;
		}
	}
	void FalagardSceneMap::SetZoomMode( int nMode )
	{ 
		m_nDisplayMode = nMode; 
		UpdateAllWindow();
	};
	const Image* FalagardSceneMap::getImageByName( const String& str, Rect rect, const char * Type) // 根据名字得到image
	{
		const String imagename = "Scenemap_view"; // 所有的地图都有这个名字，
		Imageset* pSet;
		char szFullFileName[ 128 ];
		sprintf( szFullFileName, "%s.%s", str.c_str() ,Type);
		Point offset( 0, 0 );
		if( !ImagesetManager::getSingleton().isImagesetPresent( str ) )
		{
			// CYS: client_GL scenes ship tiled minimap textures, not the single 0.85 "<scene>.jpg": a missing file
			// CYS: leaves the map background empty instead of ending the process (CEGUI already logged the error).
			try
			{
				pSet = ImagesetManager::getSingleton().createImagesetFromImageFile( str.c_str(), szFullFileName, "General" );
			}
			catch( const std::exception& )
			{
				return NULL;
			}
		}
		pSet = ImagesetManager::getSingleton().getImageset( str );
		if( pSet ) 
		{
			if( !pSet->isImageDefined( imagename ) )
				pSet->defineImage( imagename, rect, offset );
			return &pSet->getImage( imagename );
		}
		return NULL;
		
	}
	// CYS-CYGUI2: CY 3.71 (and client_GL) minimaps are tiles in Scene2Folder: "jpg_<map>_<x>_<y>.dds", 256x256, x = column
	// (scene X), y = row (scene Z); the new city maps ship only skinned sets "<map>_SJ" / "<map>_QX" that MiniMap.lua
	// selects by server flavour (g_JDTS_SceneMapFile / g_2606S_SceneMapFile). The 0.85 code loaded one "<map>.jpg",
	// absent in CY data, so the round minimap stayed empty. Order: plain tiles, _SJ (classic skin, as IsClassic=1),
	// _QX. Returns false when no tile set exists (the 0.85 single image path then runs).
	bool	FalagardSceneMap::probeImage( const String& setName, const String& file, float w, float h, const Image*& out )
	{
		out = 0;
		try
		{
			if( !ImagesetManager::getSingleton().isImagesetPresent( setName ) )
			{
				// the Ogre renderer creates an empty texture for a missing file instead of throwing: prove the file
				// exists through the resource provider first (replay-11 drew a black minimap from absent tiles)
				ResourceProvider* provider = System::getSingleton().getResourceProvider();
				RawDataContainer data;
				provider->loadRawDataContainer( file, data, "General" );
				const bool present = data.getSize() > 0;
				provider->unloadRawDataContainer( data );
				if( !present )
					return false;
			}
			if( !ImagesetManager::getSingleton().isImagesetPresent( setName ) )
				ImagesetManager::getSingleton().createImagesetFromImageFile( setName, file, "General" );
			Imageset* pSet = ImagesetManager::getSingleton().getImageset( setName );
			const String imagename = "Scenemap_view";
			if( !pSet->isImageDefined( imagename ) )
				pSet->defineImage( imagename, Rect( 0, 0, w, h ), Point( 0, 0 ) );
			out = &pSet->getImage( imagename );
			return true;
		}
		catch( ... )   // CEGUI and Ogre exceptions (the resource provider may throw either)
		{
			return false;
		}
	}

	bool	FalagardSceneMap::createTiledBackground( const String& strFileName, const int nUserSharp )
	{
		static const char* const kSuffix[] = { "", "_SJ", "_QX" };
		char szName[ 256 ];
		const Image* first = 0;
		String base;
		for( int s = 0; s < 3 && !first; ++s )
		{
			base = String( "jpg_" ) + strFileName + kSuffix[ s ];
			_snprintf( szName, sizeof( szName ), "%s_0_0", base.c_str() );
			probeImage( szName, String( szName ) + ".dds", 256, 256, first );
		}
		if( !first )
		{
			// CYS-SCENEMAP 20/09: in ca khi TRUOT. Mot luot im lang khong phan biet duoc
			// "chua ai mo ban do" voi "mo roi ma ten rong" - dung dang bug cua hai stub
			// GetSceneMapByID/GetSceneSizeByID. Ten rong in ra la "" nen nhin thay ngay.
			Logger::getSingleton().logEvent( "CYS-SCENEMAP: win='" + getName() +
				"' file='" + strFileName + "' KHONG CO BO O (thu ca _SJ/_QX)", Errors );
			CysTiledSet().erase( std::string( getName().c_str() ) ); // CYS-SCENEMAP 20/09
			return false;
		}
		// tile counts from the files themselves (no table names them)
		int nx = 1, ny = 1;
		const Image* probe = 0;
		while( nx < 64 )
		{
			_snprintf( szName, sizeof( szName ), "%s_%d_0", base.c_str(), nx );
			if( !probeImage( szName, String( szName ) + ".dds", 256, 256, probe ) ) break;
			++nx;
		}
		while( ny < 64 )
		{
			_snprintf( szName, sizeof( szName ), "%s_0_%d", base.c_str(), ny );
			if( !probeImage( szName, String( szName ) + ".dds", 256, 256, probe ) ) break;
			++ny;
		}
		m_nXCount = nx;
		m_nYCount = ny;
		CysTiledSet().insert( std::string( getName().c_str() ) ); // CYS-SCENEMAP 20/09
		// CYS-SCENEMAP 20/09: TRUOC ban va, dong nay la `nUserSharp == LookLikeRound` va no dung cho
		// TUNG O => 25 o = 25 hinh elip noi tiep, giua chung la nen den (dung trieu chung nguoi dung bao).
		// Duong GOC khong lo ra vi no ep m_nXCount=m_nYCount=1 (mot cua so duy nhat, elip lon hon khung nhin).
		// Chi nhanh LEGACY (nhanh chung duong, tai hien trieu chung) con dat `LookLikeRound` len TUNG o.
		// Nhanh da va KHONG BAO GIO lam the: vong tron di len mat na o cap khung nhin (CysApplyRoundMask).
		const bool bRound = CysRoundLegacy() && ( nUserSharp == LookLikeRound );
		int nTilesWithImage = 0;
		char szWindowName[ 256 ];
		for( int i = 0; i < nx; ++i )
		{
			for( int j = 0; j < ny; ++j )
			{
				_snprintf( szName, sizeof( szName ), "%s_%d_%d", base.c_str(), i, j );
				const Image* image = 0;
				probeImage( szName, String( szName ) + ".dds", 256, 256, image );
				if( image ) ++nTilesWithImage;
				_snprintf( szWindowName, sizeof( szWindowName ), "%s_map_%d_%d", getName().c_str(), i, j );
				if( !WindowManager::getSingleton().isWindowPresent( szWindowName ) )
					m_pBackground->addChildWindow( WindowManager::getSingleton().createWindow( "WoWLook/StaticImage", szWindowName ) );
				Window* pWindow = WindowManager::getSingleton().getWindow( szWindowName );
				if( image ) ((StaticImage*)pWindow)->setImage( image );
				if( bRound )
					pWindow->setUserSharp( LookLikeRound );
				// V-17: each texture covers 64 scene units, including a partial last
				// tile. Use the same scene denominator as every marker (live GL/CY).
				// The background clips the unused tail of the final texture.
				const float tileX = !CysDotsLegacy() && d_SceneSize.d_width > 0
					? float( SCENE_MAP_PER_PIC ) / d_SceneSize.d_width : 1.0f / nx;
				const float tileY = !CysDotsLegacy() && d_SceneSize.d_height > 0
					? float( SCENE_MAP_PER_PIC ) / d_SceneSize.d_height : 1.0f / ny;
				Rect winRect( i * tileX, j * tileY, ( i + 1 ) * tileX, ( j + 1 ) * tileY );
				pWindow->setRect( Relative, winRect );
				pWindow->setSize( Relative, winRect.getSize() );
				pWindow->show();
				pWindow->setRiseOnClickEnabled( false );
				pWindow->setMouseHollow( true );
				pWindow->setMouseMoveHollow( true );
				pWindow->setMaximumSize( Size( 100, 100 ) );
				if( i == 0 && j == 0 ) m_pLTWindow = pWindow;
				if( i == nx - 1 && j == ny - 1 ) m_pRBWindow = pWindow;
			}
		}
		// CYS-SCENEMAP 20/09: mot dong moi lan mo ban do (hiem, khong lam ngap log). In CA dau vao
		// (base, d_SceneSize - do chinh la hai gia tri hai ham host tra ve, qua
		// UILuaControl.cpp:2615-2616) LAN dau ra (luoi o, so o co anh that). Do la bang chung truc
		// tiep cho cau hoi cua nguoi dung: "ban do co dung anh .dds trong thu muc scene khong".
		{
			char szLine[ 320 ];
			_snprintf( szLine, sizeof( szLine ),
				"CYS-SCENEMAP: win='%s' base='%s' scene_size=%dx%d grid=%dx%d o_co_anh=%d/%d"
				" round=%d legacy=%d RoundEnabled='%s' arg4=%d o_tron=%d",
				getName().c_str(), base.c_str(),
				int( d_SceneSize.d_width ), int( d_SceneSize.d_height ),
				nx, ny, nTilesWithImage, nx * ny,
				CysWantRound( this, nUserSharp ) ? 1 : 0, CysRoundLegacy() ? 1 : 0,
				cysStoredProperty( this, "RoundEnabled" ).c_str(), nUserSharp, bRound ? 1 : 0 );
			szLine[ sizeof( szLine ) - 1 ] = 0;
			Logger::getSingleton().logEvent( String( (utf8*)szLine ), Errors );
		}
		return true;
	}

	void	FalagardSceneMap::createBackground( const String& strFileName, const int nUserSharp )
	{
		// 场景被分为128 X 128得小块，对应图片得256X256
		int i = 0;
		char szImagesetName[ 128 ];
		char szWindowName[ 128 ];
		sprintf( szWindowName, "%s_auto_background", getName().c_str() ); 
		if( WindowManager::getSingleton().isWindowPresent( szWindowName ) ) //如果窗口存在，就删掉
		{
			WindowManager::getSingleton().destroyWindow( szWindowName );
		}
		WindowManager::getSingleton().createWindow( "DefaultWindow", szWindowName );
		m_pBackground = WindowManager::getSingleton().getWindow( szWindowName );
		addChildWindow( m_pBackground );
		m_pBackground->setMaximumSize( Size( 100, 100 ) );
		m_pBackground->setRiseOnClickEnabled( false );
		m_pBackground->setMouseMoveHollow( true );
		// CYS-SCENEMAP 20/09: TRON hay khong la thuoc tinh cua CUA SO (RoundEnabled), va no duoc
		// thuc hien bang MAT NA o cap khung nhin - KHONG phai bang `LookLikeRound` tren tung o nen.
		const bool bRoundLook = CysWantRound( this, nUserSharp );
		if( createTiledBackground( strFileName, nUserSharp ) )
		{
			CysApplyRoundMask( this, bRoundLook );
			CysRedrawParentFrame( this, bRoundLook );
			return;
		}
		
		float fOffsetX, fOffsetY; // 这是个比例值
		float fPicSizeX = 1024, fPicSizeY = 1024;
		fOffsetX = float( ( int( d_SceneSize.d_width ) % SCENE_MAP_PER_PIC ) / float( SCENE_MAP_PER_PIC ) );  
		fOffsetY = float( ( int( d_SceneSize.d_height ) % SCENE_MAP_PER_PIC ) / float( SCENE_MAP_PER_PIC ) );
		m_nXCount =  int( d_SceneSize.d_width ) / SCENE_MAP_PER_PIC;
		m_nYCount =  int( d_SceneSize.d_height ) / SCENE_MAP_PER_PIC;
		if( fOffsetX ) // 如果有多余就多加一块
			m_nXCount += 1;
		else 
			fOffsetX = 1;
		if( fOffsetY )
			m_nYCount += 1;
		else 
			fOffsetY = 1;
			

		float fWidthPerItem = 1 / d_SceneSize.d_width;
		float fHeightPerItem = 1 / d_SceneSize.d_height;
		m_nXCount = 1;
		m_nYCount = 1;
		for( i = 0; i < m_nXCount; i ++ )
		{
			for( int j = 0; j < m_nYCount; j ++ ) // 创建所有得图片，创建响应得窗口
			{
				sprintf( szImagesetName, "%s", strFileName.c_str() );
				
				Rect rect( 0, 0, float( fPicSizeX ), float( fPicSizeY ) );
				Point offset( 0, 0 );
				if( i == m_nXCount - 1 && fOffsetX != 1 ) // 如果是x最后一个,并且图有多余得
					rect.d_right = float( fOffsetX * fPicSizeX );
				if( j == m_nYCount - 1 && fOffsetY != 1 )
					rect.d_bottom = float( fOffsetY * fPicSizeY);
				// 创建这个图片所附属得窗口
				sprintf( szWindowName, "%s_map_%d_%d", getName().c_str(),i, j ); 
				Window* pWindow = NULL;
				if( !WindowManager::getSingleton().isWindowPresent( szWindowName ) ) //如果窗口不存在，就创建一个
				{
					pWindow = WindowManager::getSingleton().createWindow( "WoWLook/StaticImage", szWindowName );
					m_pBackground->addChildWindow( pWindow );
				}
				pWindow = WindowManager::getSingleton().getWindow( szWindowName );
				if( pWindow ) 
				{
					((StaticImage*)pWindow)->setImage( getImageByName( szImagesetName, rect ,"jpg") ); 
					pWindow->setRiseOnClickEnabled( false );
					pWindow->setMouseHollow( true );
				}
				if( i == 0 && j == 0 ) //左上角窗口
					m_pLTWindow = pWindow;
				if( i == m_nXCount - 1 && j == m_nYCount - 1 ) // 右下窗口
					m_pRBWindow = pWindow;

				if( CysRoundLegacy() && ( nUserSharp == LookLikeRound ) ) // CYS-SCENEMAP 20/09
					pWindow->setUserSharp(LookLikeRound);
				// 如果地图不是正方形的，
				CEGUI::Rect winRect;
				winRect.d_left= i * SCENE_MAP_PER_PIC / d_SceneSize.d_width;
				winRect.d_top = j * SCENE_MAP_PER_PIC / d_SceneSize.d_height;
				winRect.d_right = winRect.d_left + ( fOffsetX * SCENE_MAP_PER_PIC) / d_SceneSize.d_width;
				winRect.d_bottom = winRect.d_top + ( fOffsetY * SCENE_MAP_PER_PIC) / d_SceneSize.d_height;
				pWindow->setRect( Relative, winRect );
				pWindow->setSize( Relative, winRect.getSize() );
				pWindow->show();
				pWindow->setMouseHollow( true ); 
				pWindow->setMouseMoveHollow( true ); 
				pWindow->setMaximumSize( Size( 100, 100 ) );
				pWindow->setRiseOnClickEnabled( false );
			}
		}
		CysApplyRoundMask( this, bRoundLook ); // CYS-SCENEMAP 20/09
		CysRedrawParentFrame( this, bRoundLook );
	}
	void FalagardSceneMap::CreateSceneMap( const String& strFileName, const int nUserSharp )
	{
		char szWindowName[ 128 ];
		int i;
		g_strLastSceneFile = strFileName.c_str(); // CYS-CRASHCEGUI: cho phép đo ép lại đúng kịch bản
		g_nLastSceneSharp = nUserSharp;
		createBackground( strFileName, nUserSharp );
		for( i = 0; i < 5; i ++ )
		{
			// CYS-CRASHCEGUI: this used to be the process-global name "Scenemap_Player_%d",
			// so every TLBB_SceneMap instance (MiniMap_MapArea and SceneMap_Board) shared
			// one set of five markers. Whichever instance ran CreateSceneMap last
			// re-parented them under its own "<name>_auto_background"; the next
			// createBackground() on that owner destroyed them together with that parent,
			// leaving the other instance holding freed Window* in m_pFriendWindow[].
			// Every sibling window in this file is already per-instance ("%s_auto_background",
			// "%s_map_%d_%d", "%s_Auto_MyselfWindow"); these are now too.
			CysMarkerName( szWindowName, getName(), i );
			// CYS-CRASHCEGUI: phép đo quyền sở hữu. `reused=1` kèm `prev_parent` thuộc về một
			// FalagardSceneMap KHÁC chính là lúc hai thể hiện dùng chung ô đánh dấu — tiền đề
			// của cú văng. Ghi cả khi lành, để một lượt im lặng phân biệt được "kịch bản chưa
			// bao giờ chạy" với "mô hình sai". Mỗi lần đổi cảnh chỉ 5 dòng.
			const bool bReused = WindowManager::getSingleton().isWindowPresent( szWindowName );
			if( !bReused ) //如果窗口不存在，就创建一个
				WindowManager::getSingleton().createWindow( "WoWLook/StaticImage", szWindowName );
			m_pFriendWindow[ i ] = (StaticImage*)WindowManager::getSingleton().getWindow( szWindowName );
			{
				Window* pOldParent = m_pFriendWindow[ i ]->getParent();
				String strParent = pOldParent ? pOldParent->getName() : String( (utf8*)"(none)" );
				String strMsg = "CYS-CRASHCEGUI: CreateSceneMap owner='" + getName() +
					"' marker='" + String( (utf8*)szWindowName ) + "' reused=";
				strMsg += bReused ? "1" : "0";
				strMsg += " prev_parent='" + strParent + "'";
				Logger::getSingleton().logEvent( strMsg, Errors );
			}
			m_pBackground->addChildWindow( m_pFriendWindow[ i ] );
			m_pFriendWindow[ i ]->hide();
			//m_pFriendWindow[ i ]->setAlwaysOnTop( true );
			((StaticImage*)m_pFriendWindow[ i ])->setImage( d_PlayerImage );
			

		}
		sprintf( szWindowName, "%s_Auto_MyselfWindow", getName().c_str() );  
		if( !WindowManager::getSingleton().isWindowPresent( szWindowName ) ) //如果窗口不存在，就创建一个
			WindowManager::getSingleton().createWindow( "WoWLook/StaticImage", szWindowName );
		m_pMySelfWindow = (StaticImage*)WindowManager::getSingleton().getWindow( szWindowName );
		m_pBackground->addChildWindow( m_pMySelfWindow );
		m_pMySelfWindow->setAlwaysOnTop( true );
		// CYS-SCENEMAP 20/09: NGHIA THAT cua doi so thu 4 - CY chu thich thang tai
		// MiniMap.lua:902 `--跨场景寻路修改，是否显示人物箭头` (co hien mui ten nhan vat khong),
		// va client song dua no vao FalagardSceneMap::setShowMyself(int). SceneMap.lua:816/818
		// truyen 1 cho ban do cua CHINH canh dang dung, 0 cho ban do cua canh khac.
		// Nhanh legacy giu y nguyen hanh vi cu (luon hien) de phep A/B chi khac DUNG MOT bien so.
		if( CysRoundLegacy() || nUserSharp != 0 )
			m_pMySelfWindow->show();
		else
			m_pMySelfWindow->hide();
		// CYS-MAPDOTS 20/09: moi lan dung nen la mot lan doc lai thuoc tinh dau cua layout (con tro Image
		// duoc lam moi, pool bat dau lai tu 0 - nen cu da bi destroyWindow cung moi cua so pool con cua no).
		{
			CysDotsState& st = CysDotsOf( this );
			st.nShow = ( CysRoundLegacy() || nUserSharp != 0 ) ? 1 : 0;	// = setShowMyself(int) cua cay song
			CysDotsParse( this, st );
			st.nPoolUsed = 0;
			st.nPoolMade = 0;
			st.directions.clear();
			st.mapDrawn.clear();
			st.nDroppedUnreg = 0;
			st.strLastCycle.clear();
			st.strLastArrow.clear();
			if( !CysDotsLegacy() )
			{
				// Cay song dat du bon co hollow len "%s_MySelf". Truoc ban va cua so nay khong bao gio co
				// anh nen khong ai de y; gio no la mot o 32 px NGAY TAI nhan vat - khong hollow thi no nuot
				// cu bam "di toi day" va su kien MouseMove (toa do chuot) cua ban do.
				m_pMySelfWindow->setRiseOnClickEnabled( false );
				m_pMySelfWindow->setMouseHollow( true );
				m_pMySelfWindow->setMouseMoveHollow( true );
				m_pMySelfWindow->setMouseLButtonHollow( true );
				m_pMySelfWindow->setMouseRButtonHollow( true );
			}
			CysDotsLogCfg( this, st );
		}
		m_pBackground->setMouseHollow( true );
		m_pBackground->setMouseMoveHollow( true );

		UpdateAllWindow();
		//SetViewByCenter( d_MyseflPos );
			// 创建5个队友得窗口
		
	}
	void	FalagardSceneMap::setSceneMapCenter()
	{
		SetViewByCenter( d_MyseflPos );
	}
	void FalagardSceneMap::ResetMyself()
	{
		// CYS-MAPDOTS 20/09 (V-8 + V-10): d_MyselfAnimate chi duoc gan qua thuoc tinh `MySelfImage` - thuoc tinh
		// ma KHONG layout nao cua ba cay song hay cua CanonicalCY dat (no chi con o FalagardWorldMap). Cay song
		// lay mui ten "minh" tu `AnimateImage type:Animate10` (UpdateFlag cua UI_CEGUI.dll song goi
		// setMyselfPos(10, pos, dir); updateMyselfDir tra getTypeAnimate(10)). Truoc ban va: ten rong =>
		// pAnimate == 0 => khong bao gio setImage => KHONG CO MUI TEN, tren ca minimap lan ban do lon.
		String strAnimate = d_MyselfAnimate;
		if( !CysDotsLegacy() && strAnimate.empty() )
		{
			CysDotsState& st = CysDotsOf( this );
			if( !st.bParsed ) CysDotsParse( this, st );
			std::map< int, std::string >::const_iterator it = st.mapAnimate.find( CYS_DOTS_TYPE_MYSELF );
			if( it != st.mapAnimate.end() ) strAnimate = String( (utf8*)it->second.c_str() );
		}
		Animate* pAnimate = ( AnimateManager::getSingleton().isAnimatePresent( strAnimate ) ? ( Animate*)AnimateManager::getSingleton().getAnimate( strAnimate ) : 0 ); // CYS: property may be absent in client_GL looks
		int nCurFrame = -1, nFrames = 0;
		bool bImageSet = false;
		if( pAnimate && m_pBackground && m_pMySelfWindow )
		{
			nFrames = pAnimate->getFrameNumber();
			nCurFrame = ( d_PlayerDirect * nFrames ) / 360;
			Image* pPlayerImage = (Image*)( pAnimate->getFrame( nCurFrame ) );
			if( pPlayerImage ) // CYS-MAPDOTS: khung ngoai pham vi tra NULL - truoc day la mot cu giai tham chieu NULL
			{
				Point curPos = d_MyseflPos;
				Rect rect;
				float fWidth = ( pPlayerImage->getWidth() / m_pBackground->getAbsoluteWidth() ) / 2;
				float fHeight = ( pPlayerImage->getHeight() / m_pBackground->getAbsoluteHeight() ) / 2;
				rect.d_left   = curPos.d_x -  fWidth;
				rect.d_right  = curPos.d_x + fWidth;
				rect.d_top    = curPos.d_y - fHeight;
				rect.d_bottom = curPos.d_y + fHeight;
				(( StaticImage* )m_pMySelfWindow)->setImage( pPlayerImage ) ;
				m_pMySelfWindow->setRect( Relative, rect );
				m_pMySelfWindow->setSize( Relative, rect.getSize() );
				bImageSet = true;
			}
		}
		if( CysDotsLog() && m_pMySelfWindow )
		{
			// Nguon su that cua phep do = TRANG THAI CUA SO CEGUI THAT (visible + hinh chu nhat pixel tren man hinh),
			// khong phai "da goi ham". In ca o nhanh legacy (vis=0) de mot luot im lang phan biet duoc "chua chay"
			// voi "chay ma khong ve". Chi in khi noi dung DOI.
			CysDotsState& st = CysDotsOf( this );
			const Rect rcArrow = m_pMySelfWindow->getPixelRect();
			const Rect rcMap = getPixelRect();
			char sz[ 384 ];
			_snprintf( sz, sizeof( sz ),
				"vis=%d show=%d legacy=%d pos=(%.1f,%.1f) scene=%dx%d hook=(%.4f,%.4f) dir=%d frame=%d/%d"
				" rect=(%d,%d,%d,%d) map_rect=(%d,%d,%d,%d)",
				( bImageSet && m_pMySelfWindow->isVisible() ) ? 1 : 0, st.nShow, CysDotsLegacy() ? 1 : 0,
				m_PlayerPos.d_x, m_PlayerPos.d_y, int( d_SceneSize.d_width ), int( d_SceneSize.d_height ),
				d_MyseflPos.d_x, d_MyseflPos.d_y, d_PlayerDirect, nCurFrame, nFrames,
				int( rcArrow.d_left ), int( rcArrow.d_top ), int( rcArrow.d_right ), int( rcArrow.d_bottom ),
				int( rcMap.d_left ), int( rcMap.d_top ), int( rcMap.d_right ), int( rcMap.d_bottom ) );
			sz[ sizeof( sz ) - 1 ] = 0;
			if( st.strLastArrow != sz )
			{
				st.strLastArrow = sz;
				Logger::getSingleton().logEvent( String( (utf8*)( "CYS-MAPDOTS: arrow win='" + std::string( getName().c_str() ) + "' " + sz ).c_str() ), Errors );
			}
		}
	}
	// 重新计算玩家窗口得位置
	void FalagardSceneMap::ResetPlayerWindow( int nIndex, SCENEMAP_FLAG_DATA& data )
	{
		// CYS-CRASHCEGUI: callers index this straight from a list length, and the marker
		// may have been dropped by ValidateFriendWindows.
		if( nIndex < 0 || nIndex >= 5 || !m_pFriendWindow[ nIndex ] || !m_pBackground || !d_PlayerImage )
			return;
		Point curPos = ScenePosToWindowPos( data.pos );
		Rect rect;
		float fWidth = ( d_PlayerImage->getSourceTextureArea().getWidth() / m_pBackground->getAbsoluteWidth() ) / 2;
		float fHeight = ( d_PlayerImage->getSourceTextureArea().getHeight() / m_pBackground->getAbsoluteHeight() ) / 2;
		rect.d_left   = curPos.d_x - fWidth / 2;
		rect.d_right  = curPos.d_x + fWidth / 2;
		rect.d_top    = curPos.d_y - fHeight / 2;
		rect.d_bottom = curPos.d_y + fHeight / 2;
	
		m_pFriendWindow[ nIndex ]->show();
		m_pFriendWindow[ nIndex ]->setRect( Relative, rect );
		m_pFriendWindow[ nIndex ]->setSize( Relative, rect.getSize() );

		m_pFriendWindow[ nIndex ]->setTooltipText( data.name );
	}

	Point FalagardSceneMap::ScreenPosToScenePos( const Point& pos ) // 屏幕坐标转换到场景坐标
	{

		Point tmp;
		float fMapScreenWidth = getPixelRect().getWidth();
		float fMapScreenHeight = getPixelRect().getHeight();
		// 显得到相对于左上角得屏幕偏移量,比例值
		tmp.d_x = ( pos.d_x - getPixelRect().d_left ) / fMapScreenWidth - m_WindowZero.d_x;
		tmp.d_y = ( pos.d_y - getPixelRect().d_top ) / fMapScreenHeight - m_WindowZero.d_y;

		tmp.d_x *= d_SceneSize.d_width;
		tmp.d_y *= d_SceneSize.d_height;
		return tmp;
	}

	Point FalagardSceneMap::ScreenPosToWindowPosRelative( const Point& pos ) // 屏幕坐标转换到场景坐标f
	{
		Point tmp;
		float fMapScreenWidth = getPixelRect().getWidth();
		float fMapScreenHeight = getPixelRect().getHeight();
		// 显得到相对于左上角得屏幕偏移量,比例值
		tmp.d_x = ( pos.d_x - getPixelRect().d_left ) / fMapScreenWidth;
		tmp.d_y = ( pos.d_y - getPixelRect().d_top ) / fMapScreenHeight;
		return tmp;
	}
	Point FalagardSceneMap::ScreenPosToScenePosRelative( const Point& pos ) // 屏幕坐标转换到场景坐标
	{
		Point tmp;
		float fMapScreenWidth = getPixelRect().getWidth();
		float fMapScreenHeight = getPixelRect().getHeight();
		// 显得到相对于左上角得屏幕偏移量,比例值
		tmp.d_x = ( pos.d_x - getPixelRect().d_left ) / fMapScreenWidth - m_WindowZero.d_x;
		tmp.d_y = ( pos.d_y - getPixelRect().d_top ) / fMapScreenHeight - m_WindowZero.d_y;
		return tmp;
	}
	Point FalagardSceneMap::ScenePosToWindowPos( const Point& pos )
	{
		Point tmp;
		tmp.d_x = pos.d_x / d_SceneSize.d_width;
		tmp.d_y = pos.d_y / d_SceneSize.d_height;
		return tmp;
	}

	namespace FalagardSceneMapProperties
	{
		//////////////////////////////////////////////////////////////////////////
		String PlayerImage::get(const PropertyReceiver* receiver) const
		{
			return "";//PropertyHelper::imageToString(static_cast<const FalagardSceneMap*>(receiver)->getObjImage());
		}

		void PlayerImage::set(PropertyReceiver* receiver, const String& value)
		{
			static_cast<FalagardSceneMap*>(receiver)->setPlayerImage(PropertyHelper::stringToImage(value));
		}
		//////////////////////////////////////////////////////////////////////////
		String MySelfImage::get(const PropertyReceiver* receiver) const
		{
			return "";
		}

		void MySelfImage::set(PropertyReceiver* receiver, const String& value)
		{
			static_cast<FalagardSceneMap*>(receiver)->setMyselfImage( value ) ;
		}

	};
 //////////////////////////////////////////////////////////////////////////
    Window* FalagardScenemapFactory::createWindow(const String& name)
    {
        return new FalagardSceneMap(d_type, name);
    }

    void FalagardScenemapFactory::destroyWindow(Window* window)
    {
//        if (window->getType() == d_type)
            delete window;
    }
};
