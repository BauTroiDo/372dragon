// PuSemantics.java - Ghidra headless post-script (CY-Source data track D3, 2026-09-12)
// Decompiles the virtual methods (and optionally their direct callees) plus the vftable-referencing
// functions (constructors / destructors) of selected Particle-Universe classes of tlbbgl_x64.exe, so the
// GL-specific semantics of .pu properties (units, multipliers, defaults) can be read.
// args: outDir  "Class[:depth],Class[:depth],..."  maxSlots
// Run only on a COPY of the project, e.g.
//   set GHIDRA_HEADLESS_MAXMEM=3G
//   analyzeHeadless.bat C:\TLBB\085\CY-Source\Build\re\tlgl tlgl -process tlbbgl_x64.exe -noanalysis -readOnly
//      -scriptPath C:\TLBB\085\CY-Source\Tools\gl\pu\ghidra -postScript PuSemantics.java OUT "ScaleAffector:1,..." 48
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.*;
import ghidra.app.decompiler.*;
import java.io.*;
import java.util.*;

public class PuSemantics extends GhidraScript {
    private DecompInterface di;
    private final Set<Long> done = new HashSet<>();

    private String decomp(Function f) {
        DecompileResults r = di.decompileFunction(f, 90, monitor);
        if (r != null && r.decompileCompleted()) return r.getDecompiledFunction().getC();
        return "// decompile failed: " + f.getName() + "\n";
    }

    @Override
    public void run() throws Exception {
        String[] a = getScriptArgs();
        File out = new File(a[0]);
        out.mkdirs();
        // cmd.exe splits batch arguments on ',' ';' '=' and blanks, so every argument between outDir and the
        // trailing slot count is a class spec (each may itself hold several specs separated by ',' or '+')
        int maxSlots = Integer.parseInt(a[a.length - 1]);
        List<String> specList = new ArrayList<>();
        for (int i = 1; i < a.length - 1; i++)
            for (String s : a[i].split("[,+;]")) if (!s.trim().isEmpty()) specList.add(s.trim());
        String[] specs = specList.toArray(new String[0]);
        di = new DecompInterface();
        di.openProgram(currentProgram);
        Map<String, Integer> depth = new LinkedHashMap<>();
        Map<String, List<Address>> explicit = new HashMap<>();   // "Class@0xVTABLE:depth" (from find_vtables.py)
        for (String s : specs) {
            String[] p = s.trim().split(":");
            String cls = p[0];
            if (cls.contains("@")) {
                String[] q = cls.split("@");
                cls = q[0];
                explicit.computeIfAbsent(cls, x -> new ArrayList<>()).add(toAddr(Long.decode(q[1])));
            }
            depth.put(cls, p.length > 1 ? Integer.parseInt(p[1]) : 0);
        }
        if (!explicit.isEmpty()) {
            PrintWriter index = new PrintWriter(new FileWriter(new File(out, "_index.txt")));
            for (Map.Entry<String, Integer> e : depth.entrySet()) {
                String cls = e.getKey();
                List<Address> list = explicit.get(cls);
                if (list == null) { index.println("== " + cls + " : no address"); continue; }
                PrintWriter pw = new PrintWriter(new FileWriter(new File(out, cls + ".c")));
                for (Address va : list) dumpVtable(cls, va, e.getValue(), maxSlots, pw, index);
                pw.close();
                index.flush();
            }
            index.close();
            return;
        }
        // one pass over the symbol table: class simple name -> vftable symbols
        Map<String, List<Symbol>> vts = new HashMap<>();
        SymbolIterator it = currentProgram.getSymbolTable().getAllSymbols(true);
        while (it.hasNext() && !monitor.isCancelled()) {
            Symbol s = it.next();
            if (!s.getName().contains("vftable")) continue;
            String full = s.getName(true);
            int k = full.lastIndexOf("::");
            if (k <= 0) continue;
            String owner = full.substring(0, k);
            int j = owner.lastIndexOf("::");
            String simple = j >= 0 ? owner.substring(j + 2) : owner;
            if (depth.containsKey(simple)) vts.computeIfAbsent(simple, x -> new ArrayList<>()).add(s);
        }
        PrintWriter index = new PrintWriter(new FileWriter(new File(out, "_index.txt")));
        for (Map.Entry<String, Integer> e : depth.entrySet()) {
            String cls = e.getKey();
            List<Symbol> list = vts.get(cls);
            if (list == null) {
                index.println("== " + cls + " : no vftable symbol");
                continue;
            }
            PrintWriter pw = new PrintWriter(new FileWriter(new File(out, cls + ".c")));
            for (Symbol vt : list) {
                Address va = vt.getAddress();
                index.println("== " + vt.getName(true) + " @ " + va);
                pw.println("//==================== " + vt.getName(true) + " @ " + va);
                // constructors / destructors: functions referencing the vftable
                for (Reference ref : getReferencesTo(va)) {
                    Function f = getFunctionContaining(ref.getFromAddress());
                    if (f == null || !done.add(f.getEntryPoint().getOffset())) continue;
                    index.println("  xref-fn " + f.getEntryPoint() + " " + f.getName());
                    pw.println("//---- vftable xref (ctor/dtor?) " + f.getEntryPoint() + " " + f.getName());
                    pw.println(decomp(f));
                }
                List<Function> slotFns = new ArrayList<>();
                for (int i = 0; i < maxSlots; i++) {
                    Address slot = va.add(i * 8L);
                    long fp;
                    try { fp = currentProgram.getMemory().getLong(slot); } catch (Exception ex) { break; }
                    Function f = getFunctionAt(toAddr(fp));
                    if (f == null) {
                        index.println("  slot " + i + " -> " + Long.toHexString(fp) + " (not a function, stop)");
                        break;
                    }
                    index.println("  slot " + i + " -> " + f.getEntryPoint() + " " + f.getName()
                            + " size=" + f.getBody().getNumAddresses());
                    if (!done.add(fp)) continue;
                    pw.println("//---- slot " + i + " " + f.getEntryPoint() + " " + f.getName());
                    pw.println(decomp(f));
                    slotFns.add(f);
                }
                if (e.getValue() > 0) {
                    for (Function f : slotFns) {
                        for (Function c : f.getCalledFunctions(monitor)) {
                            if (c.isThunk() || c.isExternal()) continue;
                            if (c.getBody().getNumAddresses() > 6000) continue;
                            if (!done.add(c.getEntryPoint().getOffset())) continue;
                            pw.println("//---- callee of " + f.getName() + ": " + c.getEntryPoint() + " " + c.getName());
                            pw.println(decomp(c));
                        }
                    }
                }
            }
            pw.close();
            index.flush();
        }
        index.close();
    }

    private void dumpVtable(String cls, Address va, int depth, int maxSlots, PrintWriter pw, PrintWriter index)
            throws Exception {
        index.println("== " + cls + " vftable @ " + va);
        pw.println("//==================== " + cls + " vftable @ " + va);
        for (Reference ref : getReferencesTo(va)) {
            Function f = getFunctionContaining(ref.getFromAddress());
            if (f == null || !done.add(f.getEntryPoint().getOffset())) continue;
            index.println("  xref-fn " + f.getEntryPoint() + " " + f.getName());
            pw.println("//---- vftable xref (ctor/dtor?) " + f.getEntryPoint() + " " + f.getName());
            pw.println(decomp(f));
        }
        List<Function> slotFns = new ArrayList<>();
        for (int i = 0; i < maxSlots; i++) {
            long fp;
            try { fp = currentProgram.getMemory().getLong(va.add(i * 8L)); } catch (Exception ex) { break; }
            Address fa = toAddr(fp);
            Function f = getFunctionAt(fa);
            if (f == null) {
                try { f = createFunction(fa, null); } catch (Exception ex) { f = null; }
            }
            if (f == null) { index.println("  slot " + i + " -> " + fa + " (no function, stop)"); break; }
            index.println("  slot " + i + " -> " + f.getEntryPoint() + " " + f.getName() + " size=" + f.getBody().getNumAddresses());
            if (!done.add(fp)) continue;
            pw.println("//---- slot " + i + " " + f.getEntryPoint() + " " + f.getName());
            pw.println(decomp(f));
            slotFns.add(f);
        }
        if (depth > 0) {
            for (Function f : slotFns) {
                for (Function c : f.getCalledFunctions(monitor)) {
                    if (c.isThunk() || c.isExternal()) continue;
                    if (c.getBody().getNumAddresses() > 6000) continue;
                    if (!done.add(c.getEntryPoint().getOffset())) continue;
                    pw.println("//---- callee of " + f.getName() + ": " + c.getEntryPoint() + " " + c.getName());
                    pw.println(decomp(c));
                }
            }
        }
    }
}
