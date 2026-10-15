// CY-Source helper: decompile by symbol name / list callers of imported functions (read-only).
// Usage: -postScript CyReByName.java <mode> <outFile> <sub1,sub2,...>
//   byname        decompile every function whose qualified name contains one of the substrings (max 60)
//   importcallers for each symbol (incl. externals/thunks) whose name contains a substring, decompile
//                 up to 8 functions that reference it
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.*;
import java.io.*;
import java.util.*;

public class CyReByName extends GhidraScript {
    @Override
    public void run() throws Exception {
        String[] a = getScriptArgs();
        PrintWriter out = new PrintWriter(new OutputStreamWriter(new FileOutputStream(a[1]), "UTF-8"));
        DecompInterface dec = new DecompInterface();
        dec.setOptions(new DecompileOptions());
        dec.openProgram(currentProgram);
        String[] subs = a[2].split("[,+]");
        Set<Address> done = new HashSet<>();
        FunctionManager fm = currentProgram.getFunctionManager();
        if (a[0].equals("byname")) {
            int n = 0;
            for (Function f : fm.getFunctions(true)) {
                String q = f.getName(true);
                boolean m = false;
                for (String s : subs) if (q.contains(s.trim())) { m = true; break; }
                if (!m || f.isThunk()) continue;
                out.println("==== FUNCTION " + q + " @ " + f.getEntryPoint());
                DecompileResults r = dec.decompileFunction(f, 180, monitor);
                out.println(r != null && r.decompileCompleted() ? r.getDecompiledFunction().getC() : "DECOMPILE FAILED");
                if (++n >= 60) break;
            }
        } else if (a[0].equals("importcallers")) {
            ReferenceManager rm = currentProgram.getReferenceManager();
            SymbolIterator it = currentProgram.getSymbolTable().getAllSymbols(true);
            while (it.hasNext()) {
                Symbol s = it.next();
                String q = s.getName(true);
                boolean m = false;
                for (String x : subs) if (q.contains(x.trim())) { m = true; break; }
                if (!m) continue;
                List<Address> targets = new ArrayList<>();
                targets.add(s.getAddress());
                // thunks that forward to this symbol
                for (Function f : fm.getFunctions(true)) {
                    if (f.isThunk()) {
                        Function t = f.getThunkedFunction(true);
                        if (t != null && t.getEntryPoint().equals(s.getAddress())) targets.add(f.getEntryPoint());
                    }
                }
                out.println("################ SYMBOL " + q + " @ " + s.getAddress() + " targets=" + targets);
                int n = 0;
                for (Address t : targets) {
                    for (Reference r : rm.getReferencesTo(t)) {
                        Function f = getFunctionContaining(r.getFromAddress());
                        if (f == null) continue;
                        out.println("  ref from " + f.getName(true) + " @ " + f.getEntryPoint() + " (" + r.getFromAddress() + ")");
                        if (done.contains(f.getEntryPoint()) || n >= 8) continue;
                        done.add(f.getEntryPoint());
                        n++;
                        out.println("==== FUNCTION " + f.getName(true) + " @ " + f.getEntryPoint() + " (calls " + q + ")");
                        DecompileResults d = dec.decompileFunction(f, 180, monitor);
                        out.println(d != null && d.decompileCompleted() ? d.getDecompiledFunction().getC() : "DECOMPILE FAILED");
                    }
                }
            }
        }
        out.close();
        println("CyReByName DONE " + a[0]);
    }
}
