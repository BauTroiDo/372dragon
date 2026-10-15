// CY-Source render spec helper (read-only analysis; run with analyzeHeadless -readOnly).
// Usage: -postScript CyReDump.java <mode> <outFile> [arg]
//   info                      program identity (path, MD5, SHA-256, image base, blocks)
//   strings  <regexFile>      every defined string matching any regex (one per line) + referencing functions
//   xref     <keysFile>       for each key (substring; prefix '=' for exact), decompile referencing functions
//   funcs    <a1,a2,...>      decompile functions at the given addresses (hex, no 0x)
//   callers  <a1,a2,...>      callers (2 levels) of the given functions + decompile level-1 callers
//   vtable   <addr,count>     dump <count> 8-byte slots of a vtable at addr with function names
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.mem.*;
import ghidra.program.model.symbol.*;
import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.regex.*;

public class CyReDump extends GhidraScript {
    PrintWriter out;
    DecompInterface dec;
    Set<String> done = new HashSet<>();

    String decompile(Function f) {
        DecompileResults r = dec.decompileFunction(f, 180, monitor);
        if (r != null && r.decompileCompleted()) return r.getDecompiledFunction().getC();
        return "DECOMPILE FAILED: " + (r == null ? "null" : r.getErrorMessage());
    }

    List<Function> refFuncs(Address a) {
        List<Function> fs = new ArrayList<>();
        ReferenceManager rm = currentProgram.getReferenceManager();
        for (Reference r : rm.getReferencesTo(a)) {
            Function f = getFunctionContaining(r.getFromAddress());
            if (f != null && !fs.contains(f)) fs.add(f);
        }
        return fs;
    }

    List<String> lines(String p) throws IOException {
        List<String> l = new ArrayList<>();
        for (String s : Files.readAllLines(Paths.get(p), java.nio.charset.StandardCharsets.UTF_8)) {
            if (!s.trim().isEmpty() && !s.startsWith("#")) l.add(s.trim());
        }
        return l;
    }

    List<Data> definedStrings() {
        List<Data> l = new ArrayList<>();
        DataIterator it = currentProgram.getListing().getDefinedData(true);
        while (it.hasNext() && !monitor.isCancelled()) {
            Data d = it.next();
            if (d.hasStringValue()) l.add(d);
        }
        return l;
    }

    @Override
    public void run() throws Exception {
        String[] a = getScriptArgs();
        String mode = a[0];
        out = new PrintWriter(new OutputStreamWriter(new FileOutputStream(a[1]), "UTF-8"));
        dec = new DecompInterface();
        dec.setOptions(new DecompileOptions());
        dec.openProgram(currentProgram);
        if (mode.equals("info")) {
            out.println("name=" + currentProgram.getName());
            out.println("exe_path=" + currentProgram.getExecutablePath());
            out.println("exe_md5=" + currentProgram.getExecutableMD5());
            out.println("exe_sha256=" + currentProgram.getExecutableSHA256());
            out.println("image_base=" + currentProgram.getImageBase());
            for (MemoryBlock b : currentProgram.getMemory().getBlocks())
                out.println("block " + b.getName() + " " + b.getStart() + "-" + b.getEnd() + " init=" + b.isInitialized());
            out.println("functions=" + currentProgram.getFunctionManager().getFunctionCount());
        } else if (mode.equals("strings")) {
            List<Pattern> pats = new ArrayList<>();
            for (String s : lines(a[2])) pats.add(Pattern.compile(s));
            for (Data d : definedStrings()) {
                String v = String.valueOf(d.getValue());
                boolean m = false;
                for (Pattern p : pats) if (p.matcher(v).find()) { m = true; break; }
                if (!m) continue;
                StringBuilder sb = new StringBuilder();
                for (Function f : refFuncs(d.getAddress())) sb.append(" ").append(f.getName()).append("@").append(f.getEntryPoint());
                out.println(d.getAddress() + "\t" + v.replace("\n", "\\n") + "\t|" + sb);
            }
        } else if (mode.equals("xref")) {
            List<Data> strs = definedStrings();
            for (String key : lines(a[2])) {
                boolean exact = key.startsWith("=");
                String k = exact ? key.substring(1) : key;
                out.println("################ KEY: " + key);
                int nfun = 0;
                for (Data d : strs) {
                    String v = String.valueOf(d.getValue());
                    if (exact ? !v.equals(k) : !v.contains(k)) continue;
                    List<Function> fs = refFuncs(d.getAddress());
                    out.println("  @" + d.getAddress() + " \"" + v.replace("\n", "\\n") + "\" refs=" + fs.size());
                    for (Function f : fs) {
                        out.println("    -> " + f.getName() + " @ " + f.getEntryPoint());
                        if (done.contains(f.getEntryPoint().toString()) || nfun >= 8) continue;
                        done.add(f.getEntryPoint().toString());
                        nfun++;
                        out.println("==== FUNCTION " + f.getName() + " @ " + f.getEntryPoint() + " (key " + key + ")");
                        out.println(decompile(f));
                    }
                }
            }
        } else if (mode.equals("funcs")) {
            for (String s : a[2].split("[,+]")) {
                Address ad = toAddr(s.trim());
                Function f = getFunctionAt(ad);
                if (f == null) f = getFunctionContaining(ad);
                out.println("==== FUNCTION " + s + " " + (f == null ? "NOT FOUND" : f.getName() + " @ " + f.getEntryPoint()));
                if (f != null) out.println(decompile(f));
            }
        } else if (mode.equals("callers")) {
            ReferenceManager rm = currentProgram.getReferenceManager();
            for (String s : a[2].split("[,+]")) {
                Address ad = toAddr(s.trim());
                out.println("################ TARGET " + s);
                List<Function> l1 = refFuncs(ad);
                for (Function f : l1) {
                    out.println("  L1 " + f.getName() + " @ " + f.getEntryPoint());
                    for (Function g : refFuncs(f.getEntryPoint())) out.println("     L2 " + g.getName() + " @ " + g.getEntryPoint());
                }
                for (Function f : l1) {
                    if (done.contains(f.getEntryPoint().toString())) continue;
                    done.add(f.getEntryPoint().toString());
                    out.println("==== FUNCTION " + f.getName() + " @ " + f.getEntryPoint());
                    out.println(decompile(f));
                }
            }
        } else if (mode.equals("vtable")) {
            String[] p = a[2].split("[,+]");
            Address base = toAddr(p[0]);
            int n = Integer.parseInt(p[1]);
            Memory mem = currentProgram.getMemory();
            for (int i = 0; i < n; i++) {
                long t = mem.getLong(base.add(8L * i));
                Function f = getFunctionAt(toAddr(t));
                out.println(String.format("slot +0x%x -> %x %s", 8 * i, t, f == null ? "(no func)" : f.getName()));
            }
        }
        out.close();
        println("CyReDump DONE " + mode + " -> " + a[1]);
    }
}
