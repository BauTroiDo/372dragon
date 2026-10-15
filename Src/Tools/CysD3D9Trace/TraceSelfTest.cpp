// CY-Source Src/Tools/CysD3D9Trace/TraceSelfTest.cpp - minimal Direct3D 9 program exercising the d3d9 trace proxy:
// render-to-texture pass (HLSL shader with a constant table, managed texture), back-buffer pass sampling the RT,
// fixed-function DrawPrimitiveUP, StretchRect, Clear, Present. Run it next to the proxy d3d9.dll with
// CYS_D3DTRACE_FRAMES=5 and check <dir>\f000005_frame\events.jsonl. Exit code 0 = ran all frames.
//   CysD3D9TraceSelfTest.exe [frames=12]
#include <windows.h>
#include <d3d9.h>
#include <d3dx9.h>
#include <cstdio>
#include <cstdlib>

struct V { float x, y, z, u, v; };
struct VT { float x, y, z, rhw; D3DCOLOR c; };

int main(int argc, char** argv)
{
    int frames = argc > 1 ? atoi(argv[1]) : 12;
    WNDCLASSW wc = {};
    wc.lpfnWndProc = DefWindowProcW;
    wc.hInstance = GetModuleHandleW(nullptr);
    wc.lpszClassName = L"CysTraceSelfTest";
    RegisterClassW(&wc);
    HWND hwnd = CreateWindowW(wc.lpszClassName, L"CysTraceSelfTest", WS_OVERLAPPEDWINDOW, 0, 0, 336, 279, nullptr, nullptr, wc.hInstance, nullptr);
    ShowWindow(hwnd, SW_SHOWNOACTIVATE);
    IDirect3D9* d3d = Direct3DCreate9(D3D_SDK_VERSION);
    if (!d3d) return 2;
    D3DPRESENT_PARAMETERS pp = {};
    pp.Windowed = TRUE; pp.SwapEffect = D3DSWAPEFFECT_DISCARD; pp.BackBufferFormat = D3DFMT_X8R8G8B8;
    pp.BackBufferWidth = 320; pp.BackBufferHeight = 240; pp.EnableAutoDepthStencil = TRUE; pp.AutoDepthStencilFormat = D3DFMT_D24S8;
    pp.PresentationInterval = D3DPRESENT_INTERVAL_IMMEDIATE;
    IDirect3DDevice9* dev = nullptr;
    if (FAILED(d3d->CreateDevice(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, hwnd, D3DCREATE_HARDWARE_VERTEXPROCESSING, &pp, &dev))) return 3;
    HMODULE dx = LoadLibraryW(L"d3dx9_43.dll");
    auto compile = (HRESULT(WINAPI*)(LPCSTR, UINT, CONST D3DXMACRO*, LPD3DXINCLUDE, LPCSTR, LPCSTR, DWORD, LPD3DXBUFFER*, LPD3DXBUFFER*, LPD3DXCONSTANTTABLE*))
        (dx ? GetProcAddress(dx, "D3DXCompileShader") : nullptr);
    if (!compile) return 4;
    const char* hlsl =
        "float4x4 worldViewProj; float4 tint; sampler2D diffuseMap : register(s0);\n"
        "struct VO { float4 p : POSITION; float2 uv : TEXCOORD0; };\n"
        "VO vsMain(float3 p : POSITION, float2 uv : TEXCOORD0) { VO o; o.p = mul(worldViewProj, float4(p, 1)); o.uv = uv; return o; }\n"
        "float4 psMain(float2 uv : TEXCOORD0) : COLOR { return tex2D(diffuseMap, uv) * tint; }\n";
    LPD3DXBUFFER vsb = nullptr, psb = nullptr, err = nullptr;
    if (FAILED(compile(hlsl, (UINT)strlen(hlsl), nullptr, nullptr, "vsMain", "vs_2_0", 0, &vsb, &err, nullptr))) return 5;
    if (FAILED(compile(hlsl, (UINT)strlen(hlsl), nullptr, nullptr, "psMain", "ps_2_0", 0, &psb, &err, nullptr))) return 6;
    IDirect3DVertexShader9* vs = nullptr;
    IDirect3DPixelShader9* ps = nullptr;
    dev->CreateVertexShader((const DWORD*)vsb->GetBufferPointer(), &vs);
    dev->CreatePixelShader((const DWORD*)psb->GetBufferPointer(), &ps);
    D3DVERTEXELEMENT9 el[] = { { 0, 0, D3DDECLTYPE_FLOAT3, 0, D3DDECLUSAGE_POSITION, 0 }, { 0, 12, D3DDECLTYPE_FLOAT2, 0, D3DDECLUSAGE_TEXCOORD, 0 }, D3DDECL_END() };
    IDirect3DVertexDeclaration9* decl = nullptr;
    dev->CreateVertexDeclaration(el, &decl);
    IDirect3DVertexBuffer9* vb = nullptr;
    dev->CreateVertexBuffer(4 * sizeof(V), D3DUSAGE_WRITEONLY, 0, D3DPOOL_MANAGED, &vb, nullptr);
    V quad[] = { { -1, -1, 0, 0, 1 }, { -1, 1, 0, 0, 0 }, { 1, -1, 0, 1, 1 }, { 1, 1, 0, 1, 0 } };
    void* p = nullptr;
    vb->Lock(0, 0, &p, 0); memcpy(p, quad, sizeof quad); vb->Unlock();
    IDirect3DIndexBuffer9* ib = nullptr;
    dev->CreateIndexBuffer(6 * sizeof(WORD), D3DUSAGE_WRITEONLY, D3DFMT_INDEX16, D3DPOOL_MANAGED, &ib, nullptr);
    WORD idx[] = { 0, 1, 2, 2, 1, 3 };
    ib->Lock(0, 0, &p, 0); memcpy(p, idx, sizeof idx); ib->Unlock();
    IDirect3DTexture9* tex = nullptr;
    dev->CreateTexture(64, 64, 0, 0, D3DFMT_A8R8G8B8, D3DPOOL_MANAGED, &tex, nullptr);
    D3DLOCKED_RECT lr;
    tex->LockRect(0, &lr, nullptr, 0);
    for (int y = 0; y < 64; ++y)
        for (int x = 0; x < 64; ++x) ((DWORD*)lr.pBits)[y * 64 + x] = ((x / 8 + y / 8) & 1) ? 0xFFE08040 : 0xFF2040A0;
    tex->UnlockRect(0);
    IDirect3DTexture9* rt = nullptr;
    dev->CreateTexture(128, 128, 1, D3DUSAGE_RENDERTARGET, D3DFMT_A16B16G16R16F, D3DPOOL_DEFAULT, &rt, nullptr);
    IDirect3DSurface9* rts = nullptr;
    rt->GetSurfaceLevel(0, &rts);
    IDirect3DSurface9* bb = nullptr;
    dev->GetBackBuffer(0, 0, D3DBACKBUFFER_TYPE_MONO, &bb);
    IDirect3DSurface9* copy = nullptr;
    dev->CreateRenderTarget(320, 240, D3DFMT_X8R8G8B8, D3DMULTISAMPLE_NONE, 0, FALSE, &copy, nullptr);
    D3DMATRIX id = {};
    id._11 = id._22 = id._33 = id._44 = 1;
    for (int f = 0; f < frames; ++f) {
        MSG msg;
        while (PeekMessageW(&msg, nullptr, 0, 0, PM_REMOVE)) DispatchMessageW(&msg);
        dev->BeginScene();
        // pass 1: RT
        dev->SetRenderTarget(0, rts);
        dev->Clear(0, nullptr, D3DCLEAR_TARGET, 0xFF000000, 1, 0);
        dev->SetVertexShader(vs); dev->SetPixelShader(ps); dev->SetVertexDeclaration(decl);
        dev->SetStreamSource(0, vb, 0, sizeof(V)); dev->SetIndices(ib);
        dev->SetTexture(0, tex);
        dev->SetSamplerState(0, D3DSAMP_MINFILTER, D3DTEXF_LINEAR); dev->SetSamplerState(0, D3DSAMP_MAGFILTER, D3DTEXF_LINEAR);
        dev->SetSamplerState(0, D3DSAMP_MIPFILTER, D3DTEXF_LINEAR);
        dev->SetVertexShaderConstantF(0, (float*)&id, 4);
        float tint[4] = { 1, 0.5f + 0.5f * (f % 2), 1, 1 };
        dev->SetPixelShaderConstantF(0, tint, 1);
        dev->SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
        dev->SetRenderState(D3DRS_ZENABLE, FALSE);
        dev->DrawIndexedPrimitive(D3DPT_TRIANGLELIST, 0, 0, 4, 0, 2);
        // pass 2: back buffer sampling the RT, alpha blended
        dev->SetRenderTarget(0, bb);
        dev->Clear(0, nullptr, D3DCLEAR_TARGET | D3DCLEAR_ZBUFFER, 0xFF304050, 1, 0);
        dev->SetTexture(0, rt);
        dev->SetRenderState(D3DRS_ALPHABLENDENABLE, TRUE);
        dev->SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA); dev->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);
        float half[16] = { 0.5f, 0, 0, 0, 0, 0.5f, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 };
        dev->SetVertexShaderConstantF(0, half, 4);
        dev->DrawIndexedPrimitive(D3DPT_TRIANGLELIST, 0, 0, 4, 0, 2);
        dev->SetRenderState(D3DRS_ALPHABLENDENABLE, FALSE);
        // fixed-function UP triangle
        dev->SetVertexShader(nullptr); dev->SetPixelShader(nullptr); dev->SetTexture(0, nullptr);
        dev->SetFVF(D3DFVF_XYZRHW | D3DFVF_DIFFUSE);
        VT tri[] = { { 10, 230, 0.5f, 1, 0xFFFF0000 }, { 60, 150, 0.5f, 1, 0xFF00FF00 }, { 110, 230, 0.5f, 1, 0xFF0000FF } };
        dev->DrawPrimitiveUP(D3DPT_TRIANGLELIST, 1, tri, sizeof(VT));
        dev->EndScene();
        dev->StretchRect(bb, nullptr, copy, nullptr, D3DTEXF_LINEAR);
        dev->Present(nullptr, nullptr, nullptr, nullptr);
    }
    copy->Release(); bb->Release(); rts->Release(); rt->Release(); tex->Release(); ib->Release(); vb->Release(); decl->Release();
    ps->Release(); vs->Release(); dev->Release(); d3d->Release();
    printf("CysD3D9TraceSelfTest: %d frames OK\n", frames);
    return 0;
}
