// LuaApiProbe.java - exploratory, READ-ONLY. Program identity + LuaPlus import usage +
// raw instruction context around Register call sites + RTTI packet vftable labels.
// Usage (via run_luaapi.cmd): -postScript LuaApiProbe.java <outFile>
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.*;
import java.io.*;
import java.util.*;

public class LuaApiProbe extends GhidraScript {
    PrintWriter out;

    void ctx(Address call, int before, int after) {
        Listing lst = currentProgram.getListing();
        Instruction ins = lst.getInstructionAt(call);
        List<Instruction> pre = new ArrayList<>();
        Instruction p = ins;
        for (int i = 0; i < before && p != null; i++) {
            p = p.getPrevious();
            if (p != null) pre.add(0, p);
        }
        for (Instruction x : pre) out.println("    " + x.getAddress() + "  " + x + refs(x));
        out.println(" >> " + ins.getAddress() + "  " + ins + refs(ins));
        Instruction n = ins;
        for (int i = 0; i < after && n != null; i++) {
            n = n.getNext();
            if (n != null) out.println("    " + n.getAddress() + "  " + n + refs(n));
        }
    }

    String refs(Instruction x) {
        StringBuilder sb = new StringBuilder();
        for (Reference r : x.getReferencesFrom()) {
            Address t = r.getToAddress();
            Symbol s = getSymbolAt(t);
            Data d = getDataAt(t);
            sb.append("  ;").append(r.getReferenceType()).append("->").append(t);
            if (s != null) sb.append(" ").append(s.getName(true));
            if (d != null && d.hasStringValue()) sb.append(" \"").append(String.valueOf(d.getValue())).append("\"");
            Function f = getFunctionAt(t);
            if (f != null) sb.append(" FN:").append(f.getName(true));
        }
        return sb.toString();
    }

    @Override
    public void run() throws Exception {
        String[] a = getScriptArgs();
        out = new PrintWriter(new OutputStreamWriter(new FileOutputStream(a[0]), "UTF-8"));
        out.println("name=" + currentProgram.getName());
        out.println("exe_path=" + currentProgram.getExecutablePath());
        out.println("exe_md5=" + currentProgram.getExecutableMD5());
        out.println("exe_sha256=" + currentProgram.getExecutableSHA256());
        out.println("image_base=" + currentProgram.getImageBase());
        out.println("functions=" + currentProgram.getFunctionManager().getFunctionCount());
        ExternalManager em = currentProgram.getExternalManager();
        ReferenceManager rm = currentProgram.getReferenceManager();
        List<Address> registerSites = new ArrayList<>();
        for (String lib : em.getExternalLibraryNames()) {
            out.println("LIB " + lib);
            if (!lib.toUpperCase().contains("LUAPLUS")) continue;
            ExternalLocationIterator it = em.getExternalLocations(lib);
            while (it.hasNext()) {
                ExternalLocation loc = it.next();
                Address ea = loc.getExternalSpaceAddress();
                List<Address> iat = new ArrayList<>();
                int ncalls = 0;
                Map<Address, Integer> byFunc = new TreeMap<>();
                List<Address> sites = new ArrayList<>();
                for (Reference r : rm.getReferencesTo(ea)) {
                    Address from = r.getFromAddress();
                    iat.add(from);
                    Function thunk = getFunctionAt(from);
                    List<Address> targets = new ArrayList<>();
                    targets.add(from);
                    if (thunk != null) targets.add(thunk.getEntryPoint());
                    for (Address t : targets) {
                        for (Reference r2 : rm.getReferencesTo(t)) {
                            ncalls++;
                            sites.add(r2.getFromAddress());
                            Function f = getFunctionContaining(r2.getFromAddress());
                            if (f != null) byFunc.merge(f.getEntryPoint(), 1, Integer::sum);
                        }
                    }
                }
                String orig = loc.getOriginalImportedName();
                out.println("EXT label=" + loc.getLabel() + " orig=" + orig + " sym=" + loc.getSymbol().getName(true)
                    + " iat=" + iat + " sites=" + ncalls + " funcs=" + byFunc.size());
                String key = (orig != null ? orig : "") + " " + loc.getLabel();
                if (key.contains("?Register@LuaObject")) {
                    List<Map.Entry<Address, Integer>> es = new ArrayList<>(byFunc.entrySet());
                    es.sort((x, y) -> y.getValue() - x.getValue());
                    for (Map.Entry<Address, Integer> e : es) {
                        Function f = getFunctionAt(e.getKey());
                        out.println("   REGFUNC " + e.getKey() + " " + (f == null ? "?" : f.getName(true)) + " calls=" + e.getValue()
                            + " size=" + (f == null ? 0 : f.getBody().getNumAddresses()));
                    }
                    registerSites.addAll(sites);
                }
            }
        }
        Collections.sort(registerSites);
        out.println("REGISTER_SITES total=" + registerSites.size());
        int shown = 0;
        Set<Address> seenFn = new HashSet<>();
        for (Address s : registerSites) {
            Function f = getFunctionContaining(s);
            Address fe = f == null ? null : f.getEntryPoint();
            // show 2 sites for up to 8 distinct functions
            if (fe != null && seenFn.contains(fe) && shown % 2 == 0) continue;
            if (shown >= 16) break;
            if (fe != null) seenFn.add(fe);
            out.println("---- SITE " + s + " in " + (f == null ? "?" : f.getName(true) + "@" + fe));
            ctx(s, 18, 2);
            shown++;
        }
        // RTTI vftable labels
        SymbolIterator si = currentProgram.getSymbolTable().getSymbols("vftable");
        int nv = 0, np = 0;
        List<String> ex = new ArrayList<>();
        while (si.hasNext()) {
            Symbol s = si.next();
            nv++;
            String full = s.getName(true);
            if (full.contains("Packets::")) {
                np++;
                if (ex.size() < 12) ex.add(full + "@" + s.getAddress());
            }
        }
        out.println("VFTABLES total=" + nv + " packets=" + np + " e.g. " + ex);
        // sample strings
        for (String k : new String[] {"DataPoolMetaTable", "LuaFnGetCurrentExteriorSetInfo", "GetSubItem", "Exterior", "SetPetLocation"}) {
            DataIterator di = currentProgram.getListing().getDefinedData(true);
            int found = 0;
            while (di.hasNext() && found < 4) {
                Data d = di.next();
                if (!d.hasStringValue()) continue;
                if (!String.valueOf(d.getValue()).equals(k)) continue;
                found++;
                StringBuilder sb = new StringBuilder();
                for (Reference r : rm.getReferencesTo(d.getAddress())) {
                    Function f = getFunctionContaining(r.getFromAddress());
                    sb.append(" ").append(r.getFromAddress()).append("(").append(f == null ? "?" : f.getName(true)).append(")");
                }
                out.println("STR \"" + k + "\" @" + d.getAddress() + " refs:" + sb);
            }
            if (found == 0) out.println("STR \"" + k + "\" not defined");
        }
        out.close();
        println("LuaApiProbe DONE -> " + a[0]);
    }
}
