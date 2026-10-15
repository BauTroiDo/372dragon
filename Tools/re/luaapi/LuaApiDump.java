// LuaApiDump.java - READ-ONLY extraction of the LuaPlus host API registered by a TLBB binary
// (CY-Source G3 preparation). Run with analyzeHeadless -readOnly -noanalysis (see run_luaapi.cmd).
//
// Usage:
//   -postScript LuaApiDump.java reg    <iat_map.tsv> <out.jsonl>
//   -postScript LuaApiDump.java decomp <addrs.txt>   <outDir>
//
// "reg" mode writes JSON lines:
//   info / iatcheck / importsites      program identity + import usage
//   helper                             registration helpers (RegisterObjectFunctor instantiations, wrappers)
//   reg                                one per registration site: name, implementing function, receiver key
//   ev                                 LuaPlus table plumbing (CreateTable/operator=/SetObject/SetMetaTable/BoxPointer/...)
//   fn                                 identity (bytes sha1 + RVA ranges) of functions containing registrations
//   vft                                RTTI vftables of SCRIPT_SANDBOX::* / LUA_CONTROL::* classes (slot targets;
//                                      "=g:X" marks a slot returning the static LuaObject* at X, i.e. GetMetaTable)
//   boxcls                             classes whose vftable is referenced by code touching a boxed static object
//   vslot                              resolution of a vcall thunk offset in every dumped class vftable
//   impl                               per implementing function: Lua stack reads, pushes, return constants,
//                                      packets (RTTI Packets::* vftables, depth 0..2), strings, RTTI classes
// Register values at call sites come from a conservative backward scan (volatile registers stop at calls;
// non-volatile registers are chased across calls; MOV/LEA copies are followed).
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.*;
import ghidra.program.model.lang.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.mem.*;
import ghidra.program.model.scalar.Scalar;
import ghidra.program.model.symbol.*;
import java.io.*;
import java.nio.charset.*;
import java.nio.file.*;
import java.security.MessageDigest;
import java.util.*;

public class LuaApiDump extends GhidraScript {

    static final String REG_CF = "?Register@LuaObject@LuaPlus@@QEAAXPEBDP6AHPEAUlua_State@@@ZH@Z";
    static final String REG_LS = "?Register@LuaObject@LuaPlus@@QEAAXPEBDP6AHPEAVLuaState@2@@ZH@Z";
    static final String NEWUD = "lua_newuserdata";
    static final String CREATETABLE = "?CreateTable@LuaObject@LuaPlus@@QEAA?AV12@PEBDHH@Z";
    static final String ASSIGN = "??4LuaObject@LuaPlus@@QEAAAEAV01@AEBV01@@Z";
    static final String SETOBJECT = "?SetObject@LuaObject@LuaPlus@@QEAAAEAV12@PEBDAEAV12@@Z";
    static final String SETMETA = "?SetMetaTable@LuaObject@LuaPlus@@QEAAXAEBV12@@Z";
    static final String BOXPTR = "?BoxPointer@LuaState@LuaPlus@@QEAA?AVLuaStackObject@2@PEAX@Z";
    static final String CTOR_STK = "??0LuaObject@LuaPlus@@QEAA@AEBVLuaStackObject@1@@Z";
    static final String GETGLOBALS = "?GetGlobals@LuaState@LuaPlus@@QEAA?AVLuaObject@2@XZ";
    static final String GETBYNAME = "?GetByName@LuaObject@LuaPlus@@QEAA?AV12@PEBD@Z";
    static final String SETSTRING = "?SetString@LuaObject@LuaPlus@@QEAAAEAV12@PEBD0@Z";
    static final String STKOBJ_CTOR = "??0LuaStackObject@LuaPlus@@QEAA@PEAVLuaState@1@H@Z";

    static final Set<String> VOLATILE = new HashSet<>(Arrays.asList("RAX", "RCX", "RDX", "R8", "R9", "R10", "R11"));
    static final Set<String> READERS_EDX = new HashSet<>(Arrays.asList(
        "lua_type", "lua_tonumber", "lua_tostring", "lua_isstring", "lua_isnumber", "lua_touserdata",
        "lua_isuserdata", "lua_toboolean", "lua_strlen", "lua_iscfunction", "lua_topointer", "lua_rawequal"));
    static final List<String> EVENT_IMPORTS = Arrays.asList(
        CREATETABLE, ASSIGN, SETOBJECT, SETMETA, BOXPTR, CTOR_STK, GETGLOBALS, GETBYNAME, SETSTRING);
    static final String[] VFT_NS = {"SCRIPT_SANDBOX::", "LUA_CONTROL::"};

    Map<Long, String> iat = new HashMap<>();
    Listing lst;
    Memory mem;
    ReferenceManager rm;
    PrintWriter out;
    Map<String, List<Address>> importSites = new HashMap<>();
    Register RAX, RCX, RDX, R8, R9;
    // boundary for resolve() inside code that has no Ghidra function (flood-filled pseudo bodies)
    Address curEntry;
    AddressSetView curBody;

    // ------------------------------------------------------------------ small JSON writer
    static String js(String s) {
        if (s == null) return "null";
        StringBuilder b = new StringBuilder("\"");
        for (char c : s.toCharArray()) {
            switch (c) {
                case '"': b.append("\\\""); break;
                case '\\': b.append("\\\\"); break;
                case '\n': b.append("\\n"); break;
                case '\r': b.append("\\r"); break;
                case '\t': b.append("\\t"); break;
                default:
                    if (c < 0x20) b.append(String.format("\\u%04x", (int) c));
                    else b.append(c);
            }
        }
        return b.append('"').toString();
    }

    static class J {
        StringBuilder b = new StringBuilder("{");
        boolean first = true;
        J k(String key) { if (!first) b.append(','); first = false; b.append(js(key)).append(':'); return this; }
        J s(String key, String v) { return k(key).raw(js(v)); }
        J n(String key, long v) { k(key); b.append(v); return this; }
        J h(String key, Address a) { return s(key, a == null ? null : Long.toHexString(a.getOffset())); }
        J raw(String v) { b.append(v); return this; }
        J r(String key, String rawv) { return k(key).raw(rawv); }
        String end() { return b.append('}').toString(); }
    }

    static String jarr(Collection<String> items) {
        StringBuilder b = new StringBuilder("[");
        boolean f = true;
        for (String s : items) { if (!f) b.append(','); f = false; b.append(js(s)); }
        return b.append(']').toString();
    }

    static String jarrRaw(Collection<String> items) {
        StringBuilder b = new StringBuilder("[");
        boolean f = true;
        for (String s : items) { if (!f) b.append(','); f = false; b.append(s); }
        return b.append(']').toString();
    }

    // ------------------------------------------------------------------ values
    static class Val {
        String k;   // const addr gload sload stack ret param expr unk
        long v;
        String s;
        Address at;
        Val(String k, long v, String s, Address at) { this.k = k; this.v = v; this.s = s; this.at = at; }
        public String toString() {
            switch (k) {
                case "const": return "const:" + v;
                case "addr": return "addr:" + Long.toHexString(v);
                case "gload": return "gload:" + Long.toHexString(v);
                case "sload": return "sload:" + s + (v >= 0 ? "+" : "-") + Long.toHexString(Math.abs(v));
                case "stack": return "stack:" + s + (v >= 0 ? "+" : "-") + Long.toHexString(Math.abs(v));
                case "ret": return "ret:" + (at == null ? "?" : Long.toHexString(at.getOffset())) + (s == null ? "" : "(" + s + ")");
                case "param": return "param:" + s + (v != 0 ? "+" + v : "");
                default: return k + ":" + s;
            }
        }
    }

    Val unk(String why) { return new Val("unk", 0, why, null); }

    // ------------------------------------------------------------------ instruction helpers
    long iatSlot(Instruction ins) {
        byte[] b;
        try { b = ins.getBytes(); } catch (Exception e) { return -1; }
        int i = 0;
        if (b.length > 0 && (b[0] & 0xF0) == 0x40) i++;
        if (b.length >= i + 6 && (b[i] & 0xFF) == 0xFF && ((b[i + 1] & 0xFF) == 0x15 || (b[i + 1] & 0xFF) == 0x25)) {
            int disp = (b[i + 2] & 0xFF) | ((b[i + 3] & 0xFF) << 8) | ((b[i + 4] & 0xFF) << 16) | ((b[i + 5] & 0xFF) << 24);
            return ins.getAddress().getOffset() + ins.getLength() + disp;
        }
        return -1;
    }

    String importAt(Instruction ins) {
        long s = iatSlot(ins);
        return s < 0 ? null : iat.get(s);
    }

    Address directTarget(Instruction ins) {
        Address[] fl = ins.getFlows();
        if (fl != null && fl.length == 1) return fl[0];
        return null;
    }

    String shortImp(String n) {
        if (n == null) return null;
        if (n.startsWith("?")) {
            int at = n.indexOf('@');
            String meth = n.substring(n.startsWith("??0") || n.startsWith("??1") || n.startsWith("??4") ? 3 : 1, at < 0 ? n.length() : at);
            String cls = "";
            int at2 = at < 0 ? -1 : n.indexOf('@', at + 1);
            if (at2 > at) cls = n.substring(at + 1, at2);
            if (n.startsWith("??0")) return (meth.isEmpty() ? cls : meth) + "::ctor";
            if (n.startsWith("??1")) return (meth.isEmpty() ? cls : meth) + "::dtor";
            if (n.startsWith("??4")) return (meth.isEmpty() ? cls : meth) + "::operator=";
            return cls + "::" + meth;
        }
        return n;
    }

    boolean writes(Instruction p, Register base) {
        Object[] ro = p.getResultObjects();
        if (ro == null) return false;
        for (Object o : ro) {
            if (o instanceof Register) {
                Register r = (Register) o;
                if (r.getBaseRegister().equals(base)) return true;
            }
        }
        return false;
    }

    String callDesc(Instruction p) {
        String imp = importAt(p);
        if (imp != null) return shortImp(imp);
        Address t = directTarget(p);
        return t == null ? "indirect" : Long.toHexString(t.getOffset());
    }

    Map<Address, Boolean> cookieCache = new HashMap<>();

    // __security_check_cookie(rcx) leaves RAX untouched: treat such calls as transparent for RAX
    boolean raxTransparent(Instruction call) {
        Address t = directTarget(call);
        if (t == null) return false;
        Boolean c = cookieCache.get(t);
        if (c != null) return c;
        boolean r = false;
        try {
            byte[] b = new byte[3];
            mem.getBytes(t, b);
            r = (b[0] & 0xFF) == 0x48 && (b[1] & 0xFF) == 0x3B && (b[2] & 0xFF) == 0x0D;   // cmp rcx, [rip+X]
        } catch (Exception e) { r = false; }
        cookieCache.put(t, r);
        return r;
    }

    Val resolve(Instruction at, Register r, int depth) {
        if (depth > 10) return unk("depth");
        Function f = getFunctionContaining(at.getAddress());
        Address entry = f != null ? f.getEntryPoint() : null;
        AddressSetView body = f != null ? f.getBody() : null;
        if (f == null && curBody != null && curBody.contains(at.getAddress())) { entry = curEntry; body = curBody; }
        Register base = r.getBaseRegister();
        boolean vol = VOLATILE.contains(base.getName());
        int limit = vol ? 1500 : 60000;
        Instruction p = at;
        int steps = 0;
        while (steps++ < limit) {
            if (entry != null && p.getAddress().equals(entry)) return new Val("param", 0, base.getName(), null);
            Instruction q = p.getPrevious();
            if (q == null) return unk("start");
            if (body != null && !body.contains(q.getAddress())) return unk("left-body@" + q.getAddress());
            p = q;
            FlowType ft = p.getFlowType();
            if (ft.isCall()) {
                if (base.getName().equals("RAX")) {
                    if (raxTransparent(p)) continue;
                    return new Val("ret", 0, callDesc(p), p.getAddress());
                }
                if (vol) return unk("clobbered@" + p.getAddress());
                continue;
            }
            if (writes(p, base)) return evalDef(p, base, depth);
        }
        return unk("steps");
    }

    Val memOperand(Instruction p, int op, int depth) {
        for (Reference r : p.getOperandReferences(op)) {
            if (r.isStackReference()) return new Val("stack", ((StackReference) r).getStackOffset(), "SP", null);
            Address t = r.getToAddress();
            if (t != null && t.isMemoryAddress() && !r.getReferenceType().isFlow()) return new Val("addr", t.getOffset(), null, null);
        }
        Object[] objs = p.getOpObjects(op);
        Register reg = null;
        long disp = 0;
        int nreg = 0;
        Address abs = null;
        for (Object o : objs) {
            if (o instanceof Register) { reg = (Register) o; nreg++; }
            else if (o instanceof Scalar) disp += ((Scalar) o).getSignedValue();
            else if (o instanceof Address) abs = (Address) o;
        }
        if (abs != null && nreg == 0) return new Val("addr", abs.getOffset(), null, null);
        if (nreg == 0 && disp != 0) return new Val("addr", disp, null, null);
        if (nreg == 1) {
            String bn = reg.getBaseRegister().getName();
            if (bn.equals("RSP") || bn.equals("RBP")) return new Val("stack", disp, bn, null);
            Val b = resolve(p, reg, depth + 1);
            if (b.k.equals("const") || b.k.equals("addr")) return new Val("addr", b.v + disp, null, null);
            if (b.k.equals("param")) return new Val("param", b.v + disp, b.s, null);
            if (b.k.equals("stack")) return new Val("stack", b.v + disp, b.s, null);
            return new Val("expr", disp, b.toString() + "+" + disp, null);
        }
        return null;
    }

    Val evalDef(Instruction p, Register base, int depth) {
        String m = p.getMnemonicString();
        int n = p.getNumOperands();
        if ((m.equals("XOR") || m.equals("SUB")) && n == 2) {
            Register a = p.getRegister(0), b = p.getRegister(1);
            if (a != null && b != null && a.getBaseRegister().equals(b.getBaseRegister())) return new Val("const", 0, null, null);
            return unk(m);
        }
        if (m.equals("OR") && n == 2) {
            Scalar sc = p.getScalar(1);
            if (sc != null && (sc.getSignedValue() == -1 || sc.getUnsignedValue() == 0xffffffffL)) return new Val("const", -1, null, null);
            return unk(m);
        }
        if ((m.equals("MOV") || m.equals("MOVZX") || m.equals("MOVSXD") || m.equals("MOVSX")) && n == 2) {
            Register src = p.getRegister(1);
            if (src != null) return resolve(p, src, depth + 1);
            int t = p.getOperandType(1);
            Scalar sc = p.getScalar(1);
            if (sc != null && !OperandType.isDynamic(t) && !OperandType.isAddress(t)) return new Val("const", sc.getValue(), null, null);
            Val mv = memOperand(p, 1, depth);
            if (mv != null) {
                if (mv.k.equals("addr")) return new Val("gload", mv.v, null, null);
                if (mv.k.equals("stack")) return new Val("sload", mv.v, mv.s, null);
                return new Val("expr", 0, "load(" + mv + ")", null);
            }
            return unk(m + " " + p);
        }
        if (m.equals("LEA") && n == 2) {
            Val mv = memOperand(p, 1, depth);
            if (mv != null) return mv;
            return unk("lea " + p);
        }
        return unk(m + " " + p);
    }

    String cstr(long va) {
        try {
            byte[] buf = new byte[256];
            int got = mem.getBytes(toAddr(va), buf);
            int len = 0;
            while (len < got && buf[len] != 0) len++;
            if (len == got) return null;
            boolean hi = false;
            for (int i = 0; i < len; i++) if ((buf[i] & 0x80) != 0) hi = true;
            return new String(buf, 0, len, hi ? Charset.forName("GBK") : StandardCharsets.US_ASCII);
        } catch (Exception e) {
            return null;
        }
    }

    String keyOf(Val v, Function f) {
        String fe = f == null ? "?" : Long.toHexString(f.getEntryPoint().getOffset());
        switch (v.k) {
            case "gload": return "g:" + Long.toHexString(v.v);
            case "addr": return "a:" + Long.toHexString(v.v);
            case "stack": return "s:" + fe + ":" + v.s + ":" + v.v;
            case "ret": return "r:" + Long.toHexString(v.at.getOffset());
            default: return "?:" + fe + ":" + v;
        }
    }

    // ------------------------------------------------------------------ identity of a body's bytes
    String bodyIdentity(AddressSetView body) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-1");
            List<String> rs = new ArrayList<>();
            long base = currentProgram.getImageBase().getOffset();
            for (AddressRange r : body) {
                long len = r.getLength();
                byte[] b = new byte[(int) len];
                mem.getBytes(r.getMinAddress(), b);
                md.update(b);
                rs.add("[" + (r.getMinAddress().getOffset() - base) + "," + len + "]");
            }
            StringBuilder hx = new StringBuilder();
            for (byte x : md.digest()) hx.append(String.format("%02x", x));
            return "\"sha1\":" + js(hx.toString()) + ",\"ranges\":" + jarrRaw(rs);
        } catch (Exception e) {
            return "\"sha1\":null,\"ranges\":[]";
        }
    }

    String fnIdentity(Function f) { return bodyIdentity(f.getBody()); }

    // flood-fill a body for code that Ghidra never turned into a function
    AddressSet floodBody(Address start) {
        AddressSet set = new AddressSet();
        Deque<Address> work = new ArrayDeque<>();
        work.add(start);
        int n = 0;
        while (!work.isEmpty() && n < 4000) {
            Address a = work.poll();
            Instruction ins = lst.getInstructionAt(a);
            while (ins != null && !set.contains(ins.getAddress()) && n < 4000) {
                set.add(ins.getAddress(), ins.getMaxAddress());
                n++;
                FlowType ft = ins.getFlowType();
                if (ft.isJump() && !ft.isComputed()) {
                    Address t = directTarget(ins);
                    if (t != null && Math.abs(t.subtract(start)) < 0x4000 && getFunctionAt(t) == null) work.add(t);
                    if (ft.isUnConditional()) break;
                }
                if (ft.isTerminal() || (ft.isJump() && ft.isUnConditional())) break;
                Address fa = ins.getFallThrough();
                ins = fa == null ? null : lst.getInstructionAt(fa);
            }
        }
        return set;
    }

    // ------------------------------------------------------------------ scans
    void scanImportSites() {
        InstructionIterator it = lst.getInstructions(true);
        int n = 0;
        while (it.hasNext() && !monitor.isCancelled()) {
            Instruction ins = it.next();
            FlowType ft = ins.getFlowType();
            if (!ft.isCall() && !ft.isJump()) continue;
            String imp = importAt(ins);
            if (imp == null) continue;
            importSites.computeIfAbsent(imp, k -> new ArrayList<>()).add(ins.getAddress());
            n++;
        }
        println("import call sites: " + n);
    }

    static class Helper {
        Address entry;
        String kind;       // functor | wrapper
        String nameReg;    // register carrying the name at the helper's call sites
        String fnReg;      // register carrying the implementing function
        String metaReg;    // register carrying the receiver object (null if fixed)
        Val metaFixed;
        Val nup;
        Val dispatcher;
        int level;
    }

    Map<Address, Helper> helpers = new LinkedHashMap<>();
    Set<Address> regFuncs = new TreeSet<>();
    Map<Address, List<String>> implNames = new TreeMap<>();
    int nreg = 0;

    // store of the member-function pointer into the lua_newuserdata buffer, between the userdata call and 'site'
    Val storedFn(Instruction site) {
        Function f = getFunctionContaining(site.getAddress());
        Instruction p = site;
        List<Instruction> window = new ArrayList<>();
        for (int i = 0; i < 40; i++) {
            p = p.getPrevious();
            if (p == null || (f != null && !f.getBody().contains(p.getAddress()))) return null;
            if (p.getFlowType().isCall()) {
                String imp = importAt(p);
                if (NEWUD.equals(imp)) {
                    for (Instruction w : window) {
                        if (!w.getMnemonicString().equals("MOV") || w.getNumOperands() != 2) continue;
                        Register src = w.getRegister(1);
                        if (src == null) continue;
                        Object[] o0 = w.getOpObjects(0);
                        boolean memRax = false;
                        int nr = 0;
                        for (Object o : o0) if (o instanceof Register) { nr++; if (((Register) o).getBaseRegister().equals(RAX)) memRax = true; }
                        if (!OperandType.isDynamic(w.getOperandType(0)) || nr != 1 || !memRax) continue;
                        return resolve(w, src, 0);
                    }
                    return new Val("unk", 0, "no-store", null);
                }
                return null;   // another call in between: not an inline functor
            }
            window.add(0, p);
        }
        return null;
    }

    void emitReg(Address site, Function f, String kind, Helper h, Val name, Val fn, Val meta, Val nup, Val disp) {
        String nm = (name != null && name.k.equals("addr")) ? cstr(name.v) : null;
        Address implA = (fn != null && fn.k.equals("addr")) ? toAddr(fn.v) : null;
        J j = new J().s("t", "reg").h("site", site).h("func", f == null ? null : f.getEntryPoint()).s("kind", kind)
            .h("helper", h == null ? null : h.entry).s("name", nm).s("name_val", String.valueOf(name))
            .h("impl", implA).s("impl_val", String.valueOf(fn)).s("meta_key", meta == null ? null : keyOf(meta, f))
            .s("meta_val", String.valueOf(meta)).s("nup", String.valueOf(nup)).s("dispatcher", String.valueOf(disp));
        out.println(j.end());
        nreg++;
        if (f != null) regFuncs.add(f.getEntryPoint());
        if (implA != null) implNames.computeIfAbsent(implA, k -> new ArrayList<>()).add(nm);
    }

    void handleRegisterSite(Address site, String imp) {
        Instruction ins = lst.getInstructionAt(site);
        if (ins == null) return;
        Function f = getFunctionContaining(site);
        Val rcx = resolve(ins, RCX, 0), rdx = resolve(ins, RDX, 0), r8 = resolve(ins, R8, 0), r9 = resolve(ins, R9, 0);
        Val st = storedFn(ins);
        boolean small = f != null && f.getBody().getNumAddresses() < 0x400;
        boolean paramName = rdx.k.equals("param");
        boolean paramFn = (st != null && st.k.equals("param")) || (st == null && r8.k.equals("param"));
        if (small && (paramName || paramFn)) {
            Helper h = new Helper();
            h.entry = f.getEntryPoint();
            h.level = 1;
            h.kind = st != null ? "functor" : "wrapper";
            h.nameReg = paramName ? rdx.s : null;
            h.fnReg = st != null ? (st.k.equals("param") ? st.s : null) : (r8.k.equals("param") ? r8.s : null);
            if (rcx.k.equals("param")) h.metaReg = rcx.s; else h.metaFixed = rcx;
            h.nup = r9;
            h.dispatcher = st != null ? r8 : null;
            helpers.put(h.entry, h);
            out.println(new J().s("t", "helper").h("entry", h.entry).h("site", site).s("imp", shortImp(imp)).s("kind", h.kind)
                .s("nameReg", h.nameReg).s("fnReg", h.fnReg).s("metaReg", h.metaReg).s("metaFixed", String.valueOf(h.metaFixed))
                .s("nup", String.valueOf(r9)).s("dispatcher", String.valueOf(h.dispatcher)).s("stored", String.valueOf(st))
                .r("id", "{" + fnIdentity(f) + "}").end());
            return;
        }
        String kind = st != null ? "functor_inline" : (imp.equals(REG_CF) ? "direct_cfunction" : "direct_luastate");
        emitReg(site, f, kind, null, rdx, st != null ? st : r8, rcx, r9, st != null ? r8 : null);
    }

    void handleHelperSites(Helper h, int level) {
        for (Reference ref : rm.getReferencesTo(h.entry)) {
            RefType rt = ref.getReferenceType();
            if (!rt.isCall() && !rt.isJump()) continue;
            Address site = ref.getFromAddress();
            Instruction ins = lst.getInstructionAt(site);
            if (ins == null) continue;
            Function f = getFunctionContaining(site);
            Val name = h.nameReg == null ? null : resolve(ins, currentProgram.getRegister(h.nameReg), 0);
            Val fn = h.fnReg == null ? null : resolve(ins, currentProgram.getRegister(h.fnReg), 0);
            Val meta = h.metaReg == null ? h.metaFixed : resolve(ins, currentProgram.getRegister(h.metaReg), 0);
            if (name != null && name.k.equals("param") && level < 3 && f != null && f.getBody().getNumAddresses() < 0x400) {
                Helper h2 = new Helper();
                h2.entry = f.getEntryPoint();
                h2.kind = h.kind;
                h2.level = level + 1;
                h2.nameReg = name.s;
                h2.fnReg = fn != null && fn.k.equals("param") ? fn.s : null;
                if (meta != null && meta.k.equals("param")) h2.metaReg = meta.s; else h2.metaFixed = meta;
                h2.nup = h.nup;
                h2.dispatcher = h.dispatcher;
                if (!helpers.containsKey(h2.entry)) {
                    helpers.put(h2.entry, h2);
                    out.println(new J().s("t", "helper").h("entry", h2.entry).h("site", site).s("imp", "helper:" + h.entry).s("kind", h2.kind)
                        .s("nameReg", h2.nameReg).s("fnReg", h2.fnReg).s("metaReg", h2.metaReg).s("metaFixed", String.valueOf(h2.metaFixed))
                        .s("nup", String.valueOf(h2.nup)).s("dispatcher", String.valueOf(h2.dispatcher)).s("stored", "")
                        .r("id", "{" + fnIdentity(f) + "}").end());
                    handleHelperSites(h2, level + 1);
                }
                continue;
            }
            emitReg(site, f, h.kind + (h.level > 1 ? "_l" + h.level : ""), h, name, fn, meta, h.nup, h.dispatcher);
        }
    }

    Set<Long> boxedObjs = new TreeSet<>();

    void emitEvents() {
        for (String imp : EVENT_IMPORTS) {
            List<Address> sites = importSites.get(imp);
            if (sites == null) continue;
            for (Address site : sites) {
                Instruction ins = lst.getInstructionAt(site);
                Function f = getFunctionContaining(site);
                if (f == null) continue;
                // emitted for every function: metatables are sometimes created/published outside the
                // functions that register into them (e.g. Game.exe 0x14045afb0 / 0x14045b1a0)
                boolean inReg = regFuncs.contains(f.getEntryPoint());
                Val rcx = resolve(ins, RCX, 0), rdx = resolve(ins, RDX, 0), r8 = resolve(ins, R8, 0);
                J j = new J().s("t", "ev").s("op", shortImp(imp)).h("site", site).h("func", f.getEntryPoint()).n("inreg", inReg ? 1 : 0)
                    .s("rcx", keyOf(rcx, f)).s("rdx", keyOf(rdx, f)).s("r8", keyOf(r8, f))
                    .s("rcx_val", rcx.toString()).s("rdx_val", rdx.toString()).s("r8_val", r8.toString());
                if (imp.equals(CREATETABLE) || imp.equals(GETBYNAME)) j.s("str", r8.k.equals("addr") ? cstr(r8.v) : null);
                if (imp.equals(SETOBJECT) || imp.equals(SETSTRING)) j.s("str", rdx.k.equals("addr") ? cstr(rdx.v) : null);
                if (imp.equals(SETSTRING)) j.s("str2", r8.k.equals("addr") ? cstr(r8.v) : null);
                if (imp.equals(BOXPTR) && r8.k.equals("addr")) boxedObjs.add(r8.v);
                out.println(j.end());
            }
        }
    }

    // ------------------------------------------------------------------ RTTI vftables / classes
    String classOfSym(Address t) {
        Symbol s = getSymbolAt(t);
        if (s == null) return null;
        String n = s.getName();
        if (n.equals("vftable") || n.equals("RTTI_Type_Descriptor") || n.startsWith("RTTI_Complete_Object_Locator")) {
            return s.getParentNamespace().getName(true) + (n.equals("vftable") ? "" : "#rtti");
        }
        return null;
    }

    // slot target of the form  mov rax,[rip+X] ; ret   (g:X)   or   lea rax,[rip+X] ; ret   (a:X)
    String tinyRet(Address pa) {
        try {
            byte[] b = new byte[8];
            mem.getBytes(pa, b);
            if ((b[0] & 0xFF) == 0x48 && ((b[1] & 0xFF) == 0x8B || (b[1] & 0xFF) == 0x8D) && (b[2] & 0xFF) == 0x05 && (b[7] & 0xFF) == 0xC3) {
                int disp = (b[3] & 0xFF) | ((b[4] & 0xFF) << 8) | ((b[5] & 0xFF) << 16) | ((b[6] & 0xFF) << 24);
                long x = pa.getOffset() + 7 + disp;
                return ((b[1] & 0xFF) == 0x8B ? "g:" : "a:") + Long.toHexString(x);
            }
        } catch (Exception e) { }
        return null;
    }

    Map<String, List<Long>> vftSlots = new LinkedHashMap<>();

    void dumpVftables() {
        SymbolIterator si = currentProgram.getSymbolTable().getSymbols("vftable");
        while (si.hasNext()) {
            Symbol s = si.next();
            String cls = s.getParentNamespace().getName(true);
            boolean want = false;
            for (String p : VFT_NS) if (cls.startsWith(p)) want = true;
            if (!want) continue;
            Address va = s.getAddress();
            List<String> slots = new ArrayList<>();
            List<Long> raw = new ArrayList<>();
            for (int i = 0; i < 600; i++) {
                Address sa = va.add(8L * i);
                if (i > 0) {
                    Symbol o = getSymbolAt(sa);
                    if (o != null && (o.getName().equals("vftable") || o.getName().contains("RTTI"))) break;
                }
                long p;
                try { p = mem.getLong(sa); } catch (Exception e) { break; }
                Address pa;
                try { pa = toAddr(p); } catch (Exception e) { break; }
                MemoryBlock b = mem.getBlock(pa);
                if (b == null || !b.isExecute()) break;
                String tr = tinyRet(pa);
                slots.add(Long.toHexString(p) + (tr == null ? "" : "=" + tr));
                raw.add(p);
            }
            vftSlots.put(cls + "@" + Long.toHexString(va.getOffset()), raw);
            out.println(new J().s("t", "vft").s("cls", cls).h("addr", va).n("nslots", slots.size()).r("slots", jarr(slots)).end());
        }
    }

    void boxedClasses() {
        for (long b : boxedObjs) {
            Address ba = toAddr(b);
            List<String> cands = new ArrayList<>();
            Set<Address> fs = new LinkedHashSet<>();
            for (Reference r : rm.getReferencesTo(ba)) {
                Function g = getFunctionContaining(r.getFromAddress());
                if (g != null && g.getBody().getNumAddresses() < 0x800) fs.add(g.getEntryPoint());
            }
            for (Address fa : fs) {
                Function g = getFunctionAt(fa);
                List<Address> callees = new ArrayList<>();
                InstructionIterator it = lst.getInstructions(g.getBody(), true);
                while (it.hasNext()) {
                    Instruction ins = it.next();
                    if (ins.getFlowType().isCall()) { Address t = directTarget(ins); if (t != null) callees.add(t); }
                    for (Reference r : ins.getReferencesFrom()) {
                        String c = classOfSym(r.getToAddress());
                        if (c != null && !c.endsWith("#rtti")) cands.add(c + "@" + Long.toHexString(fa.getOffset()) + "@d0@" + Long.toHexString(ins.getAddress().getOffset()));
                    }
                }
                for (Address ca : callees) {
                    Function h = getFunctionAt(ca);
                    if (h == null || h.getBody().getNumAddresses() > 0x800) continue;
                    InstructionIterator it2 = lst.getInstructions(h.getBody(), true);
                    while (it2.hasNext()) {
                        Instruction ins = it2.next();
                        for (Reference r : ins.getReferencesFrom()) {
                            String c = classOfSym(r.getToAddress());
                            if (c != null && !c.endsWith("#rtti")) cands.add(c + "@" + Long.toHexString(ca.getOffset()) + "@d1@" + Long.toHexString(ins.getAddress().getOffset()));
                        }
                    }
                }
            }
            out.println(new J().s("t", "boxcls").s("obj", Long.toHexString(b)).r("cands", jarr(cands)).end());
        }
    }

    // ------------------------------------------------------------------ implementation analysis
    static class Sum {
        Set<String> packets = new TreeSet<>();
        Map<String, Integer> pushes = new TreeMap<>();
        List<String> strings = new ArrayList<>();
        Set<String> classes = new TreeSet<>();
        List<Address> callees = new ArrayList<>();
        long size;
    }

    Map<Address, Sum> sumCache = new HashMap<>();

    boolean isPush(String imp) {
        return imp.startsWith("lua_push") || imp.equals("lua_newtable") || imp.contains("?Push") || imp.equals(BOXPTR);
    }

    String strAt(Address t) {
        Data d = getDataAt(t);
        if (d != null && d.hasStringValue()) {
            Object v = d.getValue();
            return v == null ? null : v.toString();
        }
        MemoryBlock b = mem.getBlock(t);
        if (b == null || b.isExecute() || b.isWrite()) return null;
        String s = cstr(t.getOffset());
        if (s == null || s.length() < 3) return null;
        int good = 0;
        for (char c : s.toCharArray()) if (c >= 0x20 && c != 0xFFFD) good++;
        return good == s.length() ? s : null;
    }

    Sum summarize(Address entry, AddressSetView body) {
        Sum s = sumCache.get(entry);
        if (s != null) return s;
        s = new Sum();
        s.size = body.getNumAddresses();
        sumCache.put(entry, s);
        if (s.size > 0x8000) return s;
        InstructionIterator it = lst.getInstructions(body, true);
        while (it.hasNext()) {
            Instruction ins = it.next();
            FlowType ft = ins.getFlowType();
            if (ft.isCall() || ft.isJump()) {
                String imp = importAt(ins);
                if (imp != null) {
                    if (isPush(imp)) s.pushes.merge(shortImp(imp), 1, Integer::sum);
                    continue;
                }
                Address t = directTarget(ins);
                if (t != null && (ft.isCall() || (ft.isUnConditional() && !body.contains(t))) && !s.callees.contains(t)) s.callees.add(t);
            }
            for (Reference r : ins.getReferencesFrom()) {
                if (r.getReferenceType().isFlow()) continue;
                Address t = r.getToAddress();
                if (t == null || !t.isMemoryAddress()) continue;
                String c = classOfSym(t);
                if (c != null) {
                    if (c.startsWith("Packets::")) s.packets.add(c.replace("#rtti", ""));
                    else s.classes.add(c);
                    continue;
                }
                String str = strAt(t);
                if (str != null && s.strings.size() < 16 && !s.strings.contains(str)) s.strings.add(str.length() > 96 ? str.substring(0, 96) : str);
            }
        }
        return s;
    }

    Sum summarizeAt(Address a) {
        Function g = getFunctionAt(a);
        if (g != null) return summarize(g.getEntryPoint(), g.getBody());
        if (lst.getInstructionAt(a) == null) return null;
        AddressSet b = floodBody(a);
        return summarize(a, b);
    }

    String idxOf(Val v) {
        if (v == null) return "?";
        if (v.k.equals("const")) return String.valueOf(v.v);
        return v.toString();
    }

    // index stored inline into a LuaStackObject temp ([slot+8] = idx) when the ctor is not imported
    String inlineStackIdx(Instruction call, Val slot) {
        if (slot == null || !slot.k.equals("stack")) return null;
        Instruction p = call;
        for (int i = 0; i < 40; i++) {
            p = p.getPrevious();
            if (p == null) return null;
            if (!p.getMnemonicString().equals("MOV") || p.getNumOperands() != 2) continue;
            Scalar sc = p.getScalar(1);
            if (sc == null) continue;
            Val m = memOperand(p, 0, 5);
            if (m != null && m.k.equals("stack") && m.s.equals(slot.s) && m.v == slot.v + 8) return String.valueOf(sc.getValue());
        }
        return null;
    }

    Map<Long, Long> vcallThunks = new TreeMap<>();   // thunk addr -> vtable offset

    long vcallOffset(Address a) {
        try {
            byte[] b = new byte[9];
            mem.getBytes(a, b);
            if ((b[0] & 0xFF) != 0x48 || (b[1] & 0xFF) != 0x8B || (b[2] & 0xFF) != 0x01 || (b[3] & 0xFF) != 0xFF) return -1;
            int modrm = b[4] & 0xFF;
            if (modrm == 0x20) return 0;
            if (modrm == 0x60) return b[5];
            if (modrm == 0xA0) return (b[5] & 0xFF) | ((b[6] & 0xFF) << 8) | ((b[7] & 0xFF) << 16) | ((long) (b[8] & 0xFF) << 24);
        } catch (Exception e) { }
        return -1;
    }

    void analyzeImpl(Address a, List<String> names, String via) {
        J j = new J().s("t", "impl").h("addr", a).r("names", jarr(names == null ? new ArrayList<>() : names)).s("via", via);
        Function f = getFunctionAt(a);
        AddressSetView body;
        Address entry = a;
        boolean pseudo = false;
        if (f == null) {
            long vo = vcallOffset(a);
            if (vo >= 0) {
                vcallThunks.put(a.getOffset(), vo);
                out.println(j.n("vcall_off", vo).s("err", "vcall thunk").end());
                return;
            }
            if (lst.getInstructionAt(a) == null) {
                out.println(j.s("err", "no instructions at address").end());
                return;
            }
            body = floodBody(a);
            pseudo = true;
            j.s("gname", "(no function; flood-filled)");
        } else {
            body = f.getBody();
            j.s("gname", f.getName(true));
        }
        curEntry = entry;
        curBody = body;
        j.n("size", body.getNumAddresses()).n("pseudo", pseudo ? 1 : 0);
        j.r("id", "{" + bodyIdentity(body) + "}");
        List<String> reads = new ArrayList<>();
        List<String> pushes = new ArrayList<>();
        Map<String, Integer> impCount = new TreeMap<>();
        Map<String, String> slotIdx = new HashMap<>();
        Set<String> rets = new TreeSet<>();
        List<Address> callees = new ArrayList<>();
        List<String> tail = new ArrayList<>();
        int ninstr = 0;
        InstructionIterator it = lst.getInstructions(body, true);
        while (it.hasNext()) {
            Instruction ins = it.next();
            ninstr++;
            FlowType ft = ins.getFlowType();
            if (ft.isCall() || ft.isJump()) {
                String imp = importAt(ins);
                if (imp != null) {
                    String si = shortImp(imp);
                    impCount.merge(si, 1, Integer::sum);
                    if (READERS_EDX.contains(imp)) {
                        Val idx = resolve(ins, RDX, 0);
                        String extra = "";
                        Instruction nx = ins.getNext();
                        for (int k = 0; k < 4 && nx != null; k++, nx = nx.getNext()) {
                            String mn = nx.getMnemonicString();
                            if (imp.equals("lua_type") && mn.equals("CMP") && nx.getScalar(1) != null) { extra = "=" + nx.getScalar(1).getValue(); break; }
                            if (imp.equals("lua_tonumber") && (mn.startsWith("CVTTSD2SI") || mn.startsWith("CVTSD2SI"))) { extra = ":int"; break; }
                            if (imp.equals("lua_tonumber") && mn.startsWith("CVTSD2SS")) { extra = ":float"; break; }
                            if (nx.getFlowType().isCall()) break;
                        }
                        reads.add(js(si + "(" + idxOf(idx) + ")" + extra + "@" + Long.toHexString(ins.getAddress().getOffset())));
                    } else if (imp.equals(STKOBJ_CTOR)) {
                        Val idx = resolve(ins, R8, 0);
                        Val slot = resolve(ins, RCX, 0);
                        slotIdx.put(slot.toString(), idxOf(idx));
                        reads.add(js("LuaStackObject(" + idxOf(idx) + ")@" + Long.toHexString(ins.getAddress().getOffset())));
                    } else if (imp.contains("@LuaStackObject@") && (imp.startsWith("?Get") || imp.startsWith("?Is"))) {
                        Val slot = resolve(ins, RCX, 0);
                        String ix = slotIdx.get(slot.toString());
                        if (ix == null) ix = inlineStackIdx(ins, slot);
                        if (ix == null) ix = slot.toString();
                        reads.add(js(si + "(" + ix + ")@" + Long.toHexString(ins.getAddress().getOffset())));
                    } else if (isPush(imp)) {
                        pushes.add(js(si + "@" + Long.toHexString(ins.getAddress().getOffset())));
                    }
                    continue;
                }
                Address t = directTarget(ins);
                if (ft.isCall()) {
                    if (t != null && !callees.contains(t)) callees.add(t);
                } else if (ft.isUnConditional() && t != null && !body.contains(t)) {
                    tail.add(Long.toHexString(t.getOffset()));
                    if (!callees.contains(t)) callees.add(t);
                }
            }
            if (ft.isTerminal()) {
                Val v = resolve(ins, RAX, 0);
                rets.add(v.k.equals("const") ? String.valueOf(v.v) : v.toString());
            }
            String mn = ins.getMnemonicString();
            if ((mn.equals("MOV") || mn.equals("XOR") || mn.equals("OR")) && writes(ins, RAX)) {
                Val v = evalDef(ins, RAX, 5);
                if (v.k.equals("const")) {
                    Instruction nx = ins.getNext();
                    for (int k = 0; k < 6 && nx != null; k++, nx = nx.getNext()) {
                        FlowType f2 = nx.getFlowType();
                        if (f2.isCall() && !raxTransparent(nx)) break;
                        if (writes(nx, RAX)) break;
                        if (f2.isTerminal() || (f2.isJump() && f2.isUnConditional())) { rets.add(String.valueOf(v.v)); break; }
                        if (f2.isJump()) break;
                    }
                }
            }
        }
        Sum s0 = summarize(entry, body);
        Map<String, Integer> pk = new TreeMap<>();
        for (String p : s0.packets) pk.put(p, 0);
        List<String> helperPush = new ArrayList<>();
        Set<String> cls = new TreeSet<>(s0.classes);
        List<String> strs1 = new ArrayList<>();
        Set<Address> seen = new HashSet<>();
        seen.add(entry);
        List<Address> lvl = new ArrayList<>(callees);
        for (int d = 1; d <= 2; d++) {
            List<Address> next = new ArrayList<>();
            for (Address c : lvl) {
                if (seen.size() > 90) break;
                if (!seen.add(c)) continue;
                Sum s = summarizeAt(c);
                if (s == null) continue;
                for (String p : s.packets) pk.putIfAbsent(p, d);
                if (d == 1) {
                    if (!s.pushes.isEmpty()) helperPush.add(js(Long.toHexString(c.getOffset()) + ":" + s.pushes));
                    cls.addAll(s.classes);
                    for (String x : s.strings) if (strs1.size() < 10 && !strs1.contains(x)) strs1.add(x);
                }
                next.addAll(s.callees);
            }
            lvl = next;
        }
        curEntry = null;
        curBody = null;
        List<String> pks = new ArrayList<>();
        for (Map.Entry<String, Integer> e : pk.entrySet()) pks.add(js(e.getKey() + "@d" + e.getValue()));
        List<String> impc = new ArrayList<>();
        for (Map.Entry<String, Integer> e : impCount.entrySet()) impc.add(js(e.getKey() + "=" + e.getValue()));
        List<String> cal = new ArrayList<>();
        for (Address c : callees) cal.add(js(Long.toHexString(c.getOffset())));
        j.n("ninstr", ninstr).r("reads", jarrRaw(reads)).r("pushes", jarrRaw(pushes)).r("rets", jarr(rets))
         .r("imports", jarrRaw(impc)).r("helper_pushes", jarrRaw(helperPush)).r("packets", jarrRaw(pks))
         .r("classes", jarr(cls)).r("strings", jarr(s0.strings)).r("strings_d1", jarr(strs1))
         .r("callees", jarrRaw(cal.size() > 40 ? cal.subList(0, 40) : cal)).r("tail", jarr(tail));
        out.println(j.end());
    }

    // ------------------------------------------------------------------ modes
    void loadIat(String path) throws IOException {
        for (String line : Files.readAllLines(Paths.get(path), StandardCharsets.UTF_8)) {
            if (line.startsWith("#") || line.trim().isEmpty()) continue;
            String[] p = line.split("\t");
            iat.put(Long.parseUnsignedLong(p[0], 16), p[2]);
        }
    }

    void modeReg(String iatPath, String outPath) throws Exception {
        loadIat(iatPath);
        out = new PrintWriter(new OutputStreamWriter(new FileOutputStream(outPath), "UTF-8"));
        out.println(new J().s("t", "info").s("name", currentProgram.getName()).s("exe_path", currentProgram.getExecutablePath())
            .s("exe_sha256", currentProgram.getExecutableSHA256()).s("image_base", currentProgram.getImageBase().toString())
            .n("functions", currentProgram.getFunctionManager().getFunctionCount()).end());
        int ok = 0, bad = 0;
        for (Map.Entry<Long, String> e : iat.entrySet()) {
            if (!e.getValue().contains("LuaPlus") && !e.getValue().startsWith("lua")) continue;
            boolean m = false;
            for (Reference r : rm.getReferencesFrom(toAddr(e.getKey()))) {
                if (r.getToAddress().isExternalAddress()) {
                    ExternalLocation el = currentProgram.getExternalManager().getExternalLocation(getSymbolAt(r.getToAddress()));
                    String on = el == null ? null : el.getOriginalImportedName();
                    String lb = el == null ? null : el.getLabel();
                    if (e.getValue().equals(on) || e.getValue().equals(lb)) m = true;
                }
            }
            if (m) ok++; else bad++;
        }
        out.println(new J().s("t", "iatcheck").n("ok", ok).n("unverified", bad).end());
        scanImportSites();
        List<String> ic = new ArrayList<>();
        for (Map.Entry<String, List<Address>> e : importSites.entrySet())
            if (e.getKey().contains("LuaPlus") || e.getKey().startsWith("lua")) ic.add(js(e.getKey() + "=" + e.getValue().size()));
        out.println(new J().s("t", "importsites").r("counts", jarrRaw(ic)).end());
        for (String imp : new String[] {REG_CF, REG_LS}) {
            List<Address> sites = importSites.get(imp);
            if (sites == null) continue;
            for (Address s : sites) handleRegisterSite(s, imp);
        }
        for (Helper h : new ArrayList<>(helpers.values())) if (h.level == 1) handleHelperSites(h, 1);
        println("registrations: " + nreg + " helpers: " + helpers.size() + " impls: " + implNames.size());
        emitEvents();
        for (Address fa : regFuncs) {
            Function f = getFunctionAt(fa);
            out.println(new J().s("t", "fn").h("entry", fa).s("gname", f.getName(true)).n("size", f.getBody().getNumAddresses())
                .r("id", "{" + fnIdentity(f) + "}").end());
        }
        int n = 0;
        for (Address a : implNames.keySet()) {
            if (monitor.isCancelled()) break;
            analyzeImpl(a, implNames.get(a), "registered");
            if (++n % 500 == 0) println("impl " + n + "/" + implNames.size());
        }
        // virtual members registered through vcall thunks: resolve in every dumped class vftable
        dumpVftables();
        boxedClasses();
        Map<Address, List<String>> vtargets = new TreeMap<>();
        Map<Address, Set<String>> vvia = new TreeMap<>();
        for (Map.Entry<Long, Long> e : vcallThunks.entrySet()) {
            long off = e.getValue();
            if (off % 8 != 0) continue;
            int slot = (int) (off / 8);
            List<String> nm = implNames.get(toAddr(e.getKey()));
            for (Map.Entry<String, List<Long>> v : vftSlots.entrySet()) {
                if (slot >= v.getValue().size()) continue;
                Address t = toAddr(v.getValue().get(slot));
                out.println(new J().s("t", "vslot").s("thunk", Long.toHexString(e.getKey())).n("off", off).s("cls", v.getKey())
                    .h("target", t).end());
                vtargets.computeIfAbsent(t, k -> new ArrayList<>());
                if (nm != null) for (String x : nm) if (!vtargets.get(t).contains(x)) vtargets.get(t).add(x);
                vvia.computeIfAbsent(t, k -> new TreeSet<>()).add(v.getKey() + "+" + off);
            }
        }
        for (Map.Entry<Address, List<String>> e : vtargets.entrySet()) {
            if (implNames.containsKey(e.getKey())) continue;
            analyzeImpl(e.getKey(), e.getValue(), "vslot:" + String.join(",", vvia.get(e.getKey())));
        }
        out.close();
    }

    // arguments (RCX/RDX/R8/R9 + C strings) at every call site of the given functions ('+'-separated hex list)
    void modeCallArgs(String addrs, String outPath) throws Exception {
        out = new PrintWriter(new OutputStreamWriter(new FileOutputStream(outPath), "UTF-8"));
        for (String s : addrs.split("[,+]")) {
            Address fa = toAddr(s.trim());
            for (Reference ref : rm.getReferencesTo(fa)) {
                RefType rt = ref.getReferenceType();
                if (!rt.isCall() && !rt.isJump()) continue;
                Instruction ins = lst.getInstructionAt(ref.getFromAddress());
                if (ins == null) continue;
                Function f = getFunctionContaining(ins.getAddress());
                J j = new J().s("t", "callargs").h("callee", fa).h("site", ins.getAddress()).h("func", f == null ? null : f.getEntryPoint());
                for (Register r : new Register[] {RCX, RDX, R8, R9}) {
                    Val v = resolve(ins, r, 0);
                    j.s(r.getName().toLowerCase(), v.toString());
                    if (v.k.equals("addr")) j.s(r.getName().toLowerCase() + "_str", cstr(v.v));
                }
                out.println(j.end());
            }
        }
        out.close();
    }

    void modeDecomp(String listPath, String outDir) throws Exception {
        Files.createDirectories(Paths.get(outDir));
        DecompInterface dec = new DecompInterface();
        dec.setOptions(new DecompileOptions());
        dec.openProgram(currentProgram);
        PrintWriter log = new PrintWriter(new OutputStreamWriter(new FileOutputStream(Paths.get(outDir, "_decomp_log.txt").toString()), "UTF-8"));
        int n = 0;
        for (String line : Files.readAllLines(Paths.get(listPath), StandardCharsets.UTF_8)) {
            line = line.trim();
            if (line.isEmpty() || line.startsWith("#")) continue;
            String addr = line.split("\\s+")[0];
            Function f = getFunctionAt(toAddr(addr));
            if (f == null) { log.println(addr + "\tNOFUNC"); continue; }
            long t0 = System.currentTimeMillis();
            DecompileResults r = dec.decompileFunction(f, 90, monitor);
            String c = (r != null && r.decompileCompleted()) ? r.getDecompiledFunction().getC() : null;
            try (Writer w = new OutputStreamWriter(new FileOutputStream(Paths.get(outDir, addr + ".c").toString()), "UTF-8")) {
                w.write("// " + currentProgram.getName() + " " + f.getName(true) + " @ " + f.getEntryPoint() + " (READ-ONLY decompile, evidence for the spec; never paste into Src)\n");
                w.write(c == null ? "// DECOMPILE FAILED: " + (r == null ? "null" : r.getErrorMessage()) + "\n" : c);
            }
            log.println(addr + "\t" + (c == null ? "FAIL" : "OK") + "\t" + (System.currentTimeMillis() - t0) + "ms");
            if (++n % 50 == 0) println("decomp " + n);
        }
        log.close();
        dec.dispose();
    }

    @Override
    public void run() throws Exception {
        String[] a = getScriptArgs();
        lst = currentProgram.getListing();
        mem = currentProgram.getMemory();
        rm = currentProgram.getReferenceManager();
        RAX = currentProgram.getRegister("RAX");
        RCX = currentProgram.getRegister("RCX");
        RDX = currentProgram.getRegister("RDX");
        R8 = currentProgram.getRegister("R8");
        R9 = currentProgram.getRegister("R9");
        if (a[0].equals("reg")) modeReg(a[1], a[2]);
        else if (a[0].equals("decomp")) modeDecomp(a[1], a[2]);
        else if (a[0].equals("callargs")) modeCallArgs(a[1], a[2]);
        else throw new IllegalArgumentException("mode reg|decomp|callargs");
        println("LuaApiDump DONE " + a[0]);
    }
}
