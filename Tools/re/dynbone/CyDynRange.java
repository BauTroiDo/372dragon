// CY-Source dynbone RE helper (read-only; run with analyzeHeadless -readOnly -noanalysis).
// Usage: -postScript CyDynRange.java <mode> <outFile> <arg>
//   range  <s1-e1+s2-e2...>   decompile every function whose entry lies in [s,e) (hex, no 0x), with callers/callees
//   funcs  <a1+a2+...>        decompile the functions containing the given addresses, with callers/callees
//   refs   <a1+a2+...>        list every reference to the given addresses (from address, type, containing function)
//   byname <sub1+sub2+...>    decompile every non-thunk function whose qualified name contains a substring (max 80)
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.*;
import java.io.*;
import java.util.*;

public class CyDynRange extends GhidraScript {
    PrintWriter out;
    DecompInterface dec;

    String decompile(Function f) {
        DecompileResults r = dec.decompileFunction(f, 240, monitor);
        if (r != null && r.decompileCompleted()) return r.getDecompiledFunction().getC();
        return "DECOMPILE FAILED: " + (r == null ? "null" : r.getErrorMessage());
    }

    void dumpFunction(Function f) {
        StringBuilder callers = new StringBuilder();
        for (Function c : f.getCallingFunctions(monitor)) callers.append(' ').append(c.getName(true)).append('@').append(c.getEntryPoint());
        StringBuilder callees = new StringBuilder();
        for (Function c : f.getCalledFunctions(monitor)) callees.append(' ').append(c.getName(true)).append('@').append(c.getEntryPoint());
        out.println("==== FUNCTION " + f.getName(true) + " @ " + f.getEntryPoint() + " size=" + f.getBody().getNumAddresses());
        out.println("// callers:" + callers);
        out.println("// callees:" + callees);
        out.println(decompile(f));
    }

    @Override
    public void run() throws Exception {
        String[] a = getScriptArgs();
        String mode = a[0];
        out = new PrintWriter(new OutputStreamWriter(new FileOutputStream(a[1]), "UTF-8"));
        dec = new DecompInterface();
        dec.setOptions(new DecompileOptions());
        dec.openProgram(currentProgram);
        FunctionManager fm = currentProgram.getFunctionManager();
        if (mode.equals("range")) {
            for (String r : a[2].split("[+,]")) {
                String[] se = r.trim().split("-");
                Address s = toAddr(se[0]);
                Address e = toAddr(se[1]);
                out.println("################ RANGE " + s + " - " + e);
                for (Function f : fm.getFunctions(new AddressSet(s, e.subtract(1)), true)) {
                    if (monitor.isCancelled()) break;
                    if (f.isThunk()) continue;
                    dumpFunction(f);
                }
            }
        } else if (mode.equals("funcs")) {
            for (String s : a[2].split("[+,]")) {
                Address ad = toAddr(s.trim());
                Function f = getFunctionAt(ad);
                if (f == null) f = getFunctionContaining(ad);
                if (f == null) { out.println("==== " + s + " NOT FOUND"); continue; }
                dumpFunction(f);
            }
        } else if (mode.equals("refs")) {
            ReferenceManager rm = currentProgram.getReferenceManager();
            for (String s : a[2].split("[+,]")) {
                Address ad = toAddr(s.trim());
                out.println("################ REFS TO " + ad);
                for (Reference r : rm.getReferencesTo(ad)) {
                    Function f = getFunctionContaining(r.getFromAddress());
                    out.println("  " + r.getFromAddress() + " " + r.getReferenceType() + " in " + (f == null ? "-" : f.getName(true) + "@" + f.getEntryPoint()));
                }
            }
        } else if (mode.equals("byname")) {
            String[] subs = a[2].split("[+,]");
            int n = 0;
            for (Function f : fm.getFunctions(true)) {
                String q = f.getName(true);
                boolean m = false;
                for (String s : subs) if (q.contains(s.trim())) { m = true; break; }
                if (!m || f.isThunk()) continue;
                dumpFunction(f);
                if (++n >= 80) break;
            }
        }
        out.close();
        println("CyDynRange DONE " + mode + " -> " + a[1]);
    }
}
