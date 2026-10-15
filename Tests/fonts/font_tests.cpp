// CYS: real Expat/FontManager/FreeType, with a memory-only renderer for lifecycle checks.
// Visible output is verified separately by CysUiViewer on D3D9.
#include "CEGUISystem.h"
#include "CEGUIRenderer.h"
#include "CEGUITexture.h"
#include "CEGUIDefaultResourceProvider.h"
#include "CEGUIFontManager.h"
#include "CEGUIFontBase.h"
#include "CEGUIImage.h"
#include "CEGUIImageset.h"
#include "CEGUIExceptions.h"
#include "CysFontDefinition.h"
#include "CysUnicodeText.h"
#include "CysTextColour.h"
#include "CEGUIWindow.h"
#include "elements/CEGUIEditbox.h"
#include "elements/CEGUIListboxTextItem.h"
#include <windows.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include <cstdio>
#include <fstream>
#include <functional>
#include <stdexcept>
#include <string>
#include <vector>
#include <algorithm>

using namespace CEGUI;
static int passed = 0, failed = 0;
static void require(bool ok, const char* message) { if (!ok) throw std::runtime_error(message); }
static void test(const char* name, const std::function<void()>& body)
{
    try { body(); ++passed; std::printf("PASS %s\n", name); }
    catch (const Exception& e) { ++failed; std::printf("FAIL %s: %s\n", name, e.getMessage().c_str()); }
    catch (const std::exception& e) { ++failed; std::printf("FAIL %s: %s\n", name, e.what()); }
}
struct MemoryTexture : Texture
{
    MemoryTexture(Renderer* owner, ushort size) : Texture(owner), w(size), h(size) {}
    ushort getWidth() const override { return w; }
    ushort getHeight() const override { return h; }
    void loadFromFile(const String&, const String&) override { throw std::runtime_error("unexpected image load"); }
    void loadFromMemory(const void* data, uint width, uint height) override
    {
        w = static_cast<ushort>(width); h = static_cast<ushort>(height);
        pixels.assign(static_cast<const unsigned*>(data), static_cast<const unsigned*>(data) + width * height);
    }
    ushort w, h;
    std::vector<unsigned> pixels;
};
struct MemoryRenderer : Renderer
{
    std::vector<ColourRect> quads, adjusted;
    unsigned long addQuad(const Rect&, float, const Texture*, const Rect&, const ColourRect& colours, QuadSplitMode, UserSharps) override
    { quads.push_back(colours); return static_cast<unsigned long>(quads.size()); }
    void adjustQuad(unsigned long, const Texture*, const Rect&, const ColourRect& colours) override { adjusted.push_back(colours); }
    void doRender() override {}
    void clearRenderList() override {}
    void setQueueingEnabled(bool) override {}
    Texture* createTexture() override { return new MemoryTexture(this,256); }
    Texture* createTexture(const String&, const String&) override { throw std::runtime_error("unexpected image load"); }
    Texture* createTexture(float size) override { return new MemoryTexture(this, static_cast<ushort>(size)); }
    void destroyTexture(Texture* texture) override { delete texture; }
    void destroyAllTextures() override {}
    bool isQueueingEnabled() const override { return true; }
    float getWidth() const override { return 1024; }
    float getHeight() const override { return 768; }
    Size getSize() const override { return Size(1024,768); }
    Rect getRect() const override { return Rect(0,0,1024,768); }
    uint getMaxTextureSize() const override { return 2048; }
    uint getHorzScreenDPI() const override { return 96; }
    uint getVertScreenDPI() const override { return 96; }
};
struct TestProvider : DefaultResourceProvider
{
    explicit TestProvider(const char* root) : root(root) {}
    void loadRawDataContainer(const String& name, RawDataContainer& data, const String& group) override
    {
        const std::string path = name.c_str();
        const bool schema = path.compare(0,7,"Schema/") == 0 || path.compare(0,7,"Schema\\") == 0;
        const std::string resolved = schema ? root + "/" + path : path;
        DefaultResourceProvider::loadRawDataContainer(resolved.c_str(), data, group);
    }
    std::string root;
};
static void writeXml(const std::string& xml)
{
    std::ofstream file("case.font", std::ios::binary | std::ios::trunc);
    file << "<?xml version=\"1.0\"?>\n" << xml;
    require(file.good(), "cannot write test fixture");
}
static std::string entry(const char* name, const char* cp, const char* file = "Schema/NotoSansSC-Regular.ttf", const char* type = "FreeType")
{
    return std::string("<Font Name=\"") + name + "\" Filename=\"" + file + "\" Size=\"12\" Type=\"" + type + "\" CodePage=\"" + cp + "\"/>";
}
// The same colour-token parser is called by UIString RuntimeNew; text stays UTF-8.
static String colourMarkup(const std::string& source)
{
    CysTextColourParser parser;
    String result;
    size_t begin = 0;
    while (begin < source.size())
    {
        const size_t mark = source.find('#', begin);
        if (mark == std::string::npos) { result += (const utf8*)source.substr(begin).c_str(); break; }
        result += (const utf8*)source.substr(begin, mark - begin).c_str();
        unsigned word = 0; size_t end = 0;
        if (parser.parse(source, mark + 1, word, end)) { result += static_cast<utf32>(word); begin = end; }
        else { result += static_cast<utf32>('#'); begin = mark + 1; }
    }
    return result;
}
static void checkColours(const ColourRect& colours, unsigned top, unsigned bottom)
{
    require(colours.d_top_left.getARGB() == top, "top-left glyph colour differs");
    require(colours.d_top_right.getARGB() == top, "top-right glyph colour differs");
    require(colours.d_bottom_left.getARGB() == bottom, "bottom-left glyph colour differs");
    require(colours.d_bottom_right.getARGB() == bottom, "bottom-right glyph colour differs");
}
// Access protected members through base-class member pointers; no object is downcast
// to a fixture type. Real FontManager/FreeType still allocates and paints the glyph.
struct AtlasProbe : FontBase
{
    static uint height(const FontBase& font) { return font.*(&AtlasProbe::d_maxGlyphHeight); }
    static void position(FontBase& font,uint x,uint y)
    { font.*(&AtlasProbe::d_ptNext_X)=x; font.*(&AtlasProbe::d_ptNext_Y)=y; }
    static argb_t* guardCurrent(FontBase& font)
    {
        auto* atlas=font.*(&AtlasProbe::d_currentGlyphImageset);
        argb_t* guarded=new argb_t[256*320];
        std::copy(atlas->d_memory,atlas->d_memory+256*256,guarded);
        std::fill(guarded+256*256,guarded+256*320,0xA1B2C3D4u);
        delete[] atlas->d_memory; atlas->d_memory=guarded;
        return guarded;
    }
    static const Image* image(const FontBase& font,utf32 code)
    { const auto& map=font.*(&AtlasProbe::d_cp_map);auto i=map.find(code);return i==map.end()?0:i->second.d_image; }
    static void upload(FontBase& font) { (font.*(&AtlasProbe::prepareFontTexture))(); }
};
int main(int argc, char** argv)
{
    if (argc != 2) return 2;
    MemoryRenderer renderer;
    TestProvider provider(argv[1]);
    System system(&renderer, &provider);
    FontManager& manager = FontManager::getSingleton();
    manager.setCodePage(65001);
    auto reject = [&](const std::string& xml) {
        writeXml(xml); bool rejected = false;
        try { manager.createFont(Bitmap,"case.font"); } catch (const Exception&) { rejected = true; }
        require(rejected, "invalid definition accepted");
        require(!manager.isFontPresent("Bad"), "failed font published");
    };
    test("legacy single font", [&] {
        writeXml("<Font Name=\"Legacy\" Filename=\"Schema/NotoSansSC-Regular.ttf\" Size=\"12\"/>");
        require(manager.createFont(FreeType,"case.font")->getType() == FreeType, "legacy type changed");
    });
    test("UTF-8 selection overrides bitmap scheme", [&] {
        writeXml("<Fonts>" + entry("Selected","936","missing.bin","Bitmap") + entry("Selected","65001") + "</Fonts>");
        require(manager.createFont(Bitmap,"case.font")->getType() == FreeType, "wrong variant or backend");
    });
    test("explicit codepage 1258 selects only its variant", [&] {
        manager.setCodePage(1258);
        writeXml("<Fonts>" + entry("VietnameseBranch","65001","missing.ttf") + entry("VietnameseBranch","1258") + "</Fonts>");
        auto font = manager.createFont(Bitmap,"case.font");
        manager.setCodePage(65001);
        require(font->getType() == FreeType, "wrong code page");
    });
    test("missing requested code page rejects", [&] { reject("<Fonts>"+entry("Bad","936")+"</Fonts>"); });
    test("duplicate requested code page rejects", [&] { reject("<Fonts>"+entry("Bad","65001")+entry("Bad","65001")+"</Fonts>"); });
    test("inconsistent names reject", [&] { reject("<Fonts>"+entry("Other","936")+entry("Bad","65001")+"</Fonts>"); });
    test("empty collection rejects", [&] { reject("<Fonts/>"); });
    test("unknown root rejects", [&] { reject("<Unknown/>"); });
    test("nested collection rejects", [&] { reject("<Fonts><Fonts>"+entry("Bad","65001")+"</Fonts></Fonts>"); });
    test("nested font rejects", [&] { reject("<Font Name=\"Bad\" Filename=\"x\">"+entry("Bad","65001")+"</Font>"); });
    test("truncated XML rejects", [&] { reject("<Fonts>"+entry("Bad","65001")); });
    test("missing codepage rejects", [&] { reject("<Fonts><Font Name=\"Bad\" Filename=\"x\"/></Fonts>"); });
    test("nondecimal codepage rejects", [&] { reject("<Fonts>"+entry("Bad","65001x")+"</Fonts>"); });
    test("overflow codepage rejects", [&] { reject("<Fonts>"+entry("Bad","429496729665001")+"</Fonts>"); });
    test("empty name rejects", [&] { reject("<Fonts>"+entry("","65001")+"</Fonts>"); });
    test("empty filename rejects", [&] { reject("<Fonts>"+entry("Bad","65001","")+"</Fonts>"); });
    test("unknown backend rejects", [&] { reject("<Fonts>"+entry("Bad","65001","missing","Unknown")+"</Fonts>"); });
    test("failed FreeType load cleans up repeatedly", [&] {
        std::ofstream("invalid.ttf",std::ios::binary) << "not a font";
        for(int i=0;i<20;++i) reject("<Fonts>"+entry("Bad","65001","invalid.ttf")+"</Fonts>");
    });
    test("recovery after failed load", [&] {
        writeXml("<Fonts>"+entry("Recovered","65001")+"</Fonts>");
        require(manager.createFont(Bitmap,"case.font")->getType()==FreeType,"recovery failed");
    });
    test("duplicate name retains existing font", [&] {
        FontBase* before = manager.getFont("Recovered"); bool rejected=false;
        try { manager.createFont(Bitmap,"case.font"); } catch (const AlreadyExistsException&) { rejected=true; }
        require(rejected && before==manager.getFont("Recovered"), "existing font changed");
    });
    const char* fonts[]={"SongTiBmp12","YouYuan9.75","YouYuan11.25","YouYuanMono","YouYuan13","YouYuan18","VDA_N","VDA_M","TLNA__","Title","TitleMini","GLFit10","GLFit11","GLFit12","GLFit13"};
    for (const char* name : fonts) test(name,[&] {
        const std::string filename=std::string("Schema/")+name+".font";
        FontBase* font=manager.createFont(Bitmap,filename.c_str());
        require(font->getType()==FreeType,"UTF-8 canonical font is not FreeType");
        require(font->getName()==name,"canonical name changed");
        font->prepareString((const utf8*)u8"天龙八部 Tiếng Việt Ắ ằ ẳ ẵ ặ ơ ư đ");
    });
    test("Noto Unicode charmap and Vietnamese/Chinese glyph coverage", [&] {
        FT_Library library=0; FT_Face face=0;
        require(FT_Init_FreeType(&library)==0,"FreeType init failed");
        const std::string filename=std::string(argv[1])+"/Schema/NotoSansSC-Regular.ttf";
        const int loaded=FT_New_Face(library,filename.c_str(),0,&face);
        if(loaded) { FT_Done_FreeType(library); throw std::runtime_error("Noto load failed"); }
        bool ok=FT_Select_Charmap(face,FT_ENCODING_UNICODE)==0;
        // Probe renderable Vietnamese letters. Decomposed sequences are tested through NFC below.
        std::vector<unsigned> codes;
        for(unsigned c=0x1EA0;c<=0x1EF9;++c) codes.push_back(c);
        const unsigned bases[]={0xC0,0xC1,0xC2,0xC3,0xC8,0xC9,0xCA,0xCC,0xCD,0xD2,0xD3,0xD4,0xD5,0xD9,0xDA,0xDD,0x102,0x103,0x110,0x111,0x128,0x129,0x168,0x169,0x1A0,0x1A1,0x1AF,0x1B0};
        codes.insert(codes.end(),std::begin(bases),std::end(bases));
        String mixed((const utf8*)u8"天龙八部中文与越南语江湖英雄你好角色装备武林");
        for(String::size_type i=0;i<mixed.length();++i) codes.push_back(mixed[i]);
        for(unsigned c:codes) if(!FT_Get_Char_Index(face,c)) { ok=false; std::printf("missing U+%04X\n",c); }
        std::printf("glyph probes=%zu font=%s\n",codes.size(),face->family_name);
        FT_Done_Face(face); FT_Done_FreeType(library);
        require(ok,"Unicode glyph missing");
    });
    test("all Vietnamese tone letters compose from decomposed Unicode", [&] {
        for(unsigned c=0x1EA0;c<=0x1EF9;++c)
        {
            wchar_t ch=static_cast<wchar_t>(c), decomposed[8]={};
            const int count=NormalizeString(NormalizationD,&ch,1,decomposed,8);
            require(count>1,"NFD fixture was not decomposed");
            String nfd; for(int i=0;i<count;++i) nfd+=static_cast<utf32>(decomposed[i]);
            String expected; expected+=static_cast<utf32>(c);
            require(CysComposeDisplayText(nfd)==expected,"NFD tone not composed to font glyph");
        }
    });
    test("display window composes Vietnamese while name stays exact", [&] {
        const String nfd((const utf8*)u8"Tie\u0302\u0301ng Vie\u0323\u0302t");
        Window label("DefaultWindow",nfd); label.setText(nfd);
        require(label.getText()==String((const utf8*)u8"Tiếng Việt"),"display did not compose");
        require(label.getName()==nfd,"resource/identity changed");
    });
    test("editable text retains exact value", [&] {
        const String nfd((const utf8*)u8"a\u0306\u0301");
        struct TestEditbox : Editbox {
            TestEditbox() : Editbox("DefaultWindow","Input") {} // No Falagard plugin in this memory-renderer test.
            size_t getTextIndexFromPosition(const Point&) const override { return 0; }
        } edit;
        edit.setText(nfd);
        require(edit.getText()==nfd,"editable value normalized");
    });
    test("list item constructor and setter compose display text", [&] {
        const String nfd((const utf8*)u8"a\u0306\u0301");
        ListboxTextItem item(nfd);
        require(item.getText()==String((const utf8*)u8"ắ"),"list ctor did not compose");
        item.setText((const utf8*)u8"o\u031B\u0323");
        require(item.getText()==String((const utf8*)u8"ợ"),"list setter did not compose");
    });
    test("TLBB control words and astral characters survive display composition", [&] {
        String text; text+=static_cast<utf32>(0xFF123456); text+=(const utf8*)u8"a\u0306\u0301";
        text+=static_cast<utf32>(0x1F600); text+=static_cast<utf32>(0xFF654321);
        String expected; expected+=static_cast<utf32>(0xFF123456); expected+=(const utf8*)u8"ắ";
        expected+=static_cast<utf32>(0x1F600); expected+=static_cast<utf32>(0xFF654321);
        require(CysComposeDisplayText(text)==expected,"control or astral value changed");
    });
    manager.prepareFontTexture();
    test("colour parser g is D0 and consumes six hexadecimal digits", [&] {
        String text = colourMarkup(u8"#gFF0FA0Tiếng Việt 中文");
        require(text[0] == 0xD0FF0FA0u, "g token is not D0");
        require(text.substr(1) == String((const utf8*)u8"Tiếng Việt 中文"), "UTF-8 tail changed");
    });
    test("colour parser restores previous flat colour without swapping", [&] {
        String text = colourMarkup("#c112233#gFF0FA0#l#l");
        require(text.size()==4 && text[2]==0xFB112233u && text[3]==0xFB112233u, "restore changed history");
    });
    test("colour parser restores gradient and initializes white", [&] {
        String text = colourMarkup("#l#gFF0FA0#R#l");
        require(text.size()==4 && text[0]==0xFBFFFFFFu && text[3]==0xD0FF0FA0u, "gradient restore/default wrong");
    });
    test("border colour does not replace prior text colour", [&] {
        String text = colourMarkup("#R#G#e123456#l");
        require(text.size()==4 && text[2]==0xFC123456u && text[3]==0xFBFF0000u, "border changed restore");
    });
    test("colour parser retains legacy partial-hex and truncated semantics", [&] {
        require(colourMarkup("#gFF")[0]==0xD00000FFu, "partial hex changed");
        require(colourMarkup("#gxyz")[0]==0xD0000000u, "invalid hex default changed");
        require(colourMarkup("#g")[0]==0xD0000000u, "empty hex default changed");
        require(colourMarkup("#")=="#", "trailing mark changed");
        require(colourMarkup("#z")=="#z", "unknown colour swallowed");
    });
    test("NoColor token lengths recognize g/l without changing G", [&] {
        require(CysTextColourParser::tokenLength('g')==8 && CysTextColourParser::tokenLength('c')==8 &&
                CysTextColourParser::tokenLength('e')==8 && CysTextColourParser::tokenLength('l')==2 &&
                CysTextColourParser::tokenLength('G')==2 && CysTextColourParser::tokenLength('z')==0,
                "NoColor consumption wrong");
    });
    FontBase* gradientFont = manager.getFont("SongTiBmp12");
    auto drawColours = [&](const std::string& markup, float alpha=1.0f, TextFormatting format=LeftAligned, float width=900.0f, bool blink=false) {
        String text; text+=static_cast<utf32>(0xFB112233u); text+=static_cast<utf32>(0xFC000000u);
        text+=static_cast<utf32>(blink ? 0xE0000000u : 0xE1000000u); text+=colourMarkup(markup);
        gradientFont->prepareString(text);
        renderer.quads.clear(); renderer.adjusted.clear(); manager.clearRuntimeBlinkList();
        const colour base(0.1f,0.2f,0.3f,alpha);
        gradientFont->drawText(0,text,Rect(0,0,width,700),0,Rect(0,0,1024,768),format,ColourRect(base));
    };
    test("real Noto glyph quad carries vertical RGB444 gradient", [&] {
        drawColours("#gFF0FA0A");
        require(renderer.quads.size()==1, "expected one glyph quad");
        checkColours(renderer.quads[0],0xFFFFFF00u,0xFFFFAA00u);
    });
    test("gradient channels expand all RGB444 nibbles", [&] {
        drawColours("#g123ABCA");
        require(renderer.quads.size()==1, "expected one glyph quad");
        checkColours(renderer.quads[0],0xFF112233u,0xFFAABBCCu);
    });
    test("gradient inherits supplied alpha at both endpoints", [&] {
        drawColours("#gFF0FA0A",0.5f);
        require(renderer.quads.size()==1, "expected one glyph quad");
        checkColours(renderer.quads[0],0x7FFFFF00u,0x7FFFAA00u);
    });
    test("equal gradient endpoints use B flat-colour fallback", [&] {
        drawColours("#c345678#gF00F00A");
        require(renderer.quads.size()==1, "expected one glyph quad");
        checkColours(renderer.quads[0],0xFF345678u,0xFF345678u);
    });
    test("flat colour retains gradient until border control clears it", [&] {
        drawColours("#gFF0FA0#c123456A#e000000A");
        require(renderer.quads.size()==2, "expected two glyph quads");
        checkColours(renderer.quads[0],0xFFFFFF00u,0xFFFFAA00u);
        checkColours(renderer.quads[1],0xFF123456u,0xFF123456u);
    });
    test("gradient cannot leak into next top-level draw", [&] {
        drawColours("#gFF0FA0A"); renderer.quads.clear();
        String text; text+=static_cast<utf32>(0xFB2468ACu); text+="A";
        gradientFont->drawText(0,text,Rect(0,0,900,700),0,Rect(0,0,1024,768),LeftAligned,ColourRect(colour(1,1,1,1)));
        require(renderer.quads.size()==1, "expected one glyph quad");
        checkColours(renderer.quads[0],0xFF2468ACu,0xFF2468ACu);
    });
    test("gradient survives newline and wrapped draw recursion", [&] {
        drawColours("#gFF0FA0A\nA");
        require(renderer.quads.size()==2, "newline glyph count changed");
        for(const auto& quad:renderer.quads) checkColours(quad,0xFFFFFF00u,0xFFFFAA00u);
        const float width=gradientFont->getTextExtent("AA")+0.5f;
        drawColours("#gFF0FA0AAAA",1.0f,WordWrapLeftAligned,width);
        require(renderer.quads.size()==4, "wrapped glyph count changed");
        for(const auto& quad:renderer.quads) checkColours(quad,0xFFFFFF00u,0xFFFFAA00u);
    });
    test("blink renderer and runtime update preserve gradient RGB", [&] {
        drawColours("#gFF0FA0A",1.0f,LeftAligned,900,true);
        require(renderer.quads.size()==1, "expected one blink glyph quad");
        checkColours(renderer.quads[0],0xFFFFFF00u,0xFFFFAA00u);
        manager.updateRuntimeBlinkList();
        require(renderer.adjusted.size()==1, "blink update not delivered to renderer");
        checkColours(renderer.adjusted[0],0xFFFFFF00u,0xFFFFAA00u);
        manager.clearRuntimeBlinkList();
    });
    test("taller Noto glyph on the last atlas row cannot overwrite its allocation", [&] {
        writeXml(entry("AtlasBoundary","65001"));FontBase* font=manager.createFont(FreeType,"case.font");
        const uint oldHeight=AtlasProbe::height(*font);
        struct Face {
            FT_Library library=0;FT_Face face=0;
            ~Face(){if(face)FT_Done_Face(face);if(library)FT_Done_FreeType(library);}
        } ft;
        require(FT_Init_FreeType(&ft.library)==0,"fixture FreeType init failed");
        const std::string path=std::string(argv[1])+"/Schema/NotoSansSC-Regular.ttf";
        require(FT_New_Face(ft.library,path.c_str(),0,&ft.face)==0,"fixture Noto load failed");
        require(FT_Set_Char_Size(ft.face,0,12*64,96,96)==0,"fixture point size failed");
        utf32 code=0;
        for(utf32 candidate=0x1EA0;candidate<=0x1EF9;++candidate)
            if(!FT_Load_Char(ft.face,candidate,FT_LOAD_RENDER|FT_LOAD_NO_AUTOHINT|FT_LOAD_TARGET_NORMAL) &&
               ft.face->glyph->bitmap.rows>static_cast<int>(oldHeight)){code=candidate;break;}
        require(code!=0,"Noto fixture has no taller Vietnamese glyph");
        const uint rows=ft.face->glyph->bitmap.rows,width=ft.face->glyph->bitmap.width;
        require(oldHeight<rows && rows<64 && width<200,"fixture does not cross only vertical atlas boundary");
        std::printf("atlas boundary U+%04X oldHeight=%u rows=%u x=32 y=%u\n",code,oldHeight,rows,256-oldHeight);
        argb_t* guarded=AtlasProbe::guardCurrent(*font);
        AtlasProbe::position(*font,32,256-oldHeight);
        String text;text+=code;font->prepareString(text);
        const size_t changed=static_cast<size_t>(std::count_if(guarded+256*256,guarded+256*320,[](argb_t pixel){return pixel!=0xA1B2C3D4u;}));
        std::printf("atlas guard overwritten pixels=%zu\n",changed);
        require(changed==0,"glyph write crossed 256x256 atlas into guard pixels");
        const Image* glyph=AtlasProbe::image(*font,code);require(glyph!=0,"taller glyph was dropped");
        const Rect area=glyph->getSourceTextureArea();
        require(area.d_bottom<=256 && area.d_right<=256,"glyph source rectangle escaped atlas");
        AtlasProbe::upload(*font);
        const auto* texture=static_cast<const MemoryTexture*>(glyph->getImageset()->getTexture());
        bool hasInk=false;
        for(uint y=0;y<rows;++y)for(uint x=0;x<width;++x)
        {
            const unsigned got=texture->pixels[(static_cast<uint>(area.d_top)+y)*256+static_cast<uint>(area.d_left)+x];
            const unsigned expected=ft.face->glyph->bitmap.buffer[y*ft.face->glyph->bitmap.pitch+x];
            require((got>>24)==expected,"glyph bitmap was clipped or changed while moving atlas");hasInk=hasInk || expected!=0;
        }
        require(hasInk,"glyph fixture has no ink");
        renderer.quads.clear();font->drawText(0,text,Rect(0,0,200,100),0,Rect(0,0,200,100),LeftAligned,ColourRect(colour(1,1,1,1)));
        require(!renderer.quads.empty(),"moved glyph did not render");
    });
    test("a glyph at the right edge moves to a complete new row", [&] {
        writeXml(entry("AtlasRight","65001"));FontBase* font=manager.createFont(FreeType,"case.font");
        argb_t* guarded=AtlasProbe::guardCurrent(*font);const uint rowHeight=AtlasProbe::height(*font);
        AtlasProbe::position(*font,255,0);font->prepareString("A");
        const Image* glyph=AtlasProbe::image(*font,'A');require(glyph!=0,"right-edge glyph was dropped");
        const Rect area=glyph->getSourceTextureArea();
        require(area.d_left==0 && area.d_top==rowHeight && area.d_right<256 && area.d_bottom<=256,"right-edge glyph crossed atlas row");
        require(std::all_of(guarded+256*256,guarded+256*320,[](argb_t p){return p==0xA1B2C3D4u;}),"right-edge write changed allocation guard");
    });
    test("sequential Chinese and Vietnamese glyphs retain bounded images across atlases", [&] {
        writeXml(entry("AtlasMany","65001"));FontBase* font=manager.createFont(FreeType,"case.font");
        String text;for(utf32 c=0x4E00;c<0x5200;++c)text+=c;for(utf32 c=0x1EA0;c<=0x1EF9;++c)text+=c;
        font->prepareString(text);const Imageset* firstSet=0;bool moved=false;
        for(String::size_type i=0;i<text.length();++i)
        {
            const Image* glyph=AtlasProbe::image(*font,text[i]);require(glyph!=0,"sequential glyph was dropped");
            const Rect area=glyph->getSourceTextureArea();
            require(area.d_left>=0 && area.d_top>=0 && area.d_right<=256 && area.d_bottom<=256,"sequential glyph escaped atlas");
            if(!firstSet)firstSet=glyph->getImageset();else moved=moved || firstSet!=glyph->getImageset();
        }
        AtlasProbe::upload(*font);require(moved,"fixture did not exercise multiple atlas pages");
    });
    test("an oversized font fails explicitly before any out-of-atlas write", [&] {
        writeXml("<Font Name=\"AtlasOversize\" Filename=\"Schema/NotoSansSC-Regular.ttf\" Size=\"512\" Type=\"FreeType\" CodePage=\"65001\"/>");
        bool rejected=false;try{manager.createFont(FreeType,"case.font");}catch(const InvalidRequestException&){rejected=true;}
        require(rejected && !manager.isFontPresent("AtlasOversize"),"oversized glyph was accepted or partially published");
    });
    std::printf("RESULT %d/%d passed\n",passed,passed+failed);
    return failed ? 1 : 0;
}
