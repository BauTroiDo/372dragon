// cy-oracle agent (from CySwitchRE): read-only batch dumper (run with analyzeHeadless -readOnly -noanalysis on a COPY of a project).
// Usage: -postScript CyActionSetRE.java <jobsFile>
// jobs file (UTF-8), one job per line, '#' comments:
//   funcs   <outFile> <a1,a2,...>          decompile functions containing the addresses
//   range   <outFile> <start,end>          decompile every function whose entry lies in [start,end]
//   refs    <outFile> <a1,a2,...>          every reference to each address (from, function) + decompile referencing functions
//   callers <outFile> <a1,a2,...>          call sites of each function (from, function) + decompile the callers
//   vtable  <outFile> <base,count>         dump count 8-byte slots with function names (+ label at base / base-8)
//   strings <outFile> <regex>              defined strings matching regex + referencing functions
//   scalar  <outFile> <hexvalue,start,end> instructions in [start,end] with an operand scalar == value
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.mem.*;
import ghidra.program.model.scalar.Scalar;
import ghidra.program.model.symbol.*;
import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.regex.*;

public class CyOracleRE extends GhidraScript {
    DecompInterface dec;

    String decompile(Function f) {
        DecompileResults r = dec.decompileFunction(f, 240, monitor);
        if (r != null && r.decompileCompleted()) return r.getDecompiledFunction().getC();
        return "DECOMPILE FAILED: " + (r == null ? "null" : r.getErrorMessage());
    }

    String label(Address a) {
        Symbol s = currentProgram.getSymbolTable().getPrimarySymbol(a);
        return s == null ? "" : s.getName(true);
    }

    void dumpFunc(PrintWriter out, Function f, Set<Address> done) {
        if (f == null || done.contains(f.getEntryPoint())) return;
        done.add(f.getEntryPoint());
        out.println("==== FUNCTION " + f.getName() + " @ " + f.getEntryPoint() + " size=" + f.getBody().getNumAddresses());
        out.println(decompile(f));
    }

    void dumpCallees(PrintWriter out, Function f, int depth, Set<Address> done) {
        if (depth <= 0) return;
        for (Function c : f.getCalledFunctions(monitor)) {
            if (c.isThunk()) c = c.getThunkedFunction(true);
            if (c == null || c.isExternal() || done.contains(c.getEntryPoint())) continue;
            if (c.getBody().getNumAddresses() > 20000) { out.println("==== (skip big) " + c.getName()); continue; }
            dumpFunc(out, c, done);
            dumpCallees(out, c, depth - 1, done);
        }
    }

    @Override
    public void run() throws Exception {
        String[] a = getScriptArgs();
        dec = new DecompInterface();
        DecompileOptions o = new DecompileOptions();
        dec.setOptions(o);
        dec.openProgram(currentProgram);
        List<String> jobs = Files.readAllLines(Paths.get(a[0]), java.nio.charset.StandardCharsets.UTF_8);
        for (String line : jobs) {
            line = line.trim();
            if (line.isEmpty() || line.startsWith("#")) continue;
            String[] p = line.split("\\s+", 3);
            String mode = p[0], outFile = p[1], arg = p.length > 2 ? p[2] : "";
            PrintWriter out = new PrintWriter(new OutputStreamWriter(new FileOutputStream(outFile), "UTF-8"));
            out.println("# program " + currentProgram.getName() + " sha256=" + currentProgram.getExecutableSHA256());
            out.println("# job " + line);
            Set<Address> done = new HashSet<>();
            ReferenceManager rm = currentProgram.getReferenceManager();
            Listing lst = currentProgram.getListing();
            if (mode.equals("funcs")) {
                for (String s : arg.split("[,+]")) {
                    Address ad = toAddr(s.trim());
                    Function f = getFunctionAt(ad);
                    if (f == null) f = getFunctionContaining(ad);
                    if (f == null) { out.println("==== " + s + " NOT FOUND"); continue; }
                    dumpFunc(out, f, done);
                }
            } else if (mode.equals("pkt") || mode.equals("tree")) {
                // pkt  <outFile> <Name=vtableVA,...> : decompile slots 1 Read, 2 Write, 3 Execute (+callees), 5 GetPacketSize
                // tree <outFile> <depth,a1,a2,...>   : decompile functions and their callees up to depth (skip > 20000 bytes)
                Memory mem = currentProgram.getMemory();
                String[] items = arg.split(",");
                int depth = 1;
                int start = 0;
                if (mode.equals("tree")) { depth = Integer.parseInt(items[0].trim()); start = 1; }
                for (int ii = start; ii < items.length; ii++) {
                    String it0 = items[ii].trim();
                    if (mode.equals("pkt")) {
                        String[] nv = it0.split("=");
                        Address vt = toAddr(nv[1]);
                        out.println("################ PACKET " + nv[0] + " vtable " + vt);
                        String[] slotName = {"dtor", "Read", "Write", "Execute", "GetPacketID", "GetPacketSize"};
                        for (int k : new int[]{1, 2, 3, 5}) {
                            long t = mem.getLong(vt.add(8L * k));
                            Function f = getFunctionAt(toAddr(t));
                            out.println("######## " + nv[0] + "::" + slotName[k] + " slot " + k + " -> " + Long.toHexString(t));
                            if (f == null) { out.println("(no function)"); continue; }
                            dumpFunc(out, f, done);
                            if (k == 3) dumpCallees(out, f, 2, done);
                        }
                    } else {
                        Function f = getFunctionContaining(toAddr(it0));
                        if (f == null) { out.println("==== " + it0 + " NOT FOUND"); continue; }
                        dumpFunc(out, f, done);
                        dumpCallees(out, f, depth, done);
                    }
                }
            } else if (mode.equals("range")) {
                String[] r = arg.split("[,+]");
                Address s0 = toAddr(r[0]), s1 = toAddr(r[1]);
                FunctionIterator it = currentProgram.getFunctionManager().getFunctions(s0, true);
                while (it.hasNext()) {
                    Function f = it.next();
                    if (f.getEntryPoint().compareTo(s1) > 0) break;
                    dumpFunc(out, f, done);
                }
            } else if (mode.equals("refs") || mode.equals("callers")) {
                for (String s : arg.split("[,+]")) {
                    Address ad = toAddr(s.trim());
                    out.println("################ TARGET " + s + " " + label(ad));
                    List<Function> fs = new ArrayList<>();
                    for (Reference r : rm.getReferencesTo(ad)) {
                        Function f = getFunctionContaining(r.getFromAddress());
                        out.println("  ref " + r.getReferenceType() + " from " + r.getFromAddress() + " in " + (f == null ? "?" : f.getName() + "@" + f.getEntryPoint()));
                        if (f != null && !fs.contains(f)) fs.add(f);
                    }
                    for (Function f : fs) dumpFunc(out, f, done);
                }
            } else if (mode.equals("vtable")) {
                String[] r = arg.split("[,+]");
                Address base = toAddr(r[0]);
                int n = Integer.parseInt(r[1]);
                Memory mem = currentProgram.getMemory();
                out.println("label@base " + label(base) + " ; label@base-8 " + label(base.subtract(8)) + " ; qword@base-8 " + Long.toHexString(mem.getLong(base.subtract(8))));
                for (int i = 0; i < n; i++) {
                    long t = mem.getLong(base.add(8L * i));
                    Function f = getFunctionAt(toAddr(t));
                    out.println(String.format("slot +0x%x -> %x %s", 8 * i, t, f == null ? "(no func)" : f.getName()));
                }
            } else if (mode.equals("strings")) {
                Pattern pat = Pattern.compile(arg);
                DataIterator it = lst.getDefinedData(true);
                while (it.hasNext() && !monitor.isCancelled()) {
                    Data d = it.next();
                    if (!d.hasStringValue()) continue;
                    String v = String.valueOf(d.getValue());
                    if (!pat.matcher(v).find()) continue;
                    StringBuilder sb = new StringBuilder();
                    for (Reference r : rm.getReferencesTo(d.getAddress())) {
                        Function f = getFunctionContaining(r.getFromAddress());
                        sb.append(" ").append(r.getFromAddress()).append("/").append(f == null ? "?" : f.getName());
                    }
                    out.println(d.getAddress() + "\t" + v.replace("\n", "\\n") + "\t|" + sb);
                }
            } else if (mode.equals("floats")) {
                // floats <outFile> <start,count>  : 4-byte slots as float / int / hex + refs
                String[] r = arg.split("[,+]");
                Address base = toAddr(r[0]);
                int n = Integer.parseInt(r[1]);
                Memory mem = currentProgram.getMemory();
                for (int i = 0; i < n; i++) {
                    Address ad = base.add(4L * i);
                    int v = mem.getInt(ad);
                    StringBuilder sb = new StringBuilder();
                    for (Reference rf : rm.getReferencesTo(ad)) {
                        Function f = getFunctionContaining(rf.getFromAddress());
                        sb.append(" ").append(rf.getFromAddress()).append("/").append(f == null ? "?" : f.getName());
                    }
                    out.println(String.format("%s  f=%g  i=%d  hex=%08x  %s |%s", ad, Float.intBitsToFloat(v), v, v, label(ad), sb));
                }
            } else if (mode.equals("strdec")) {
                Pattern pat = Pattern.compile(arg);
                DataIterator it = lst.getDefinedData(true);
                List<Function> fs = new ArrayList<>();
                while (it.hasNext() && !monitor.isCancelled()) {
                    Data d = it.next();
                    if (!d.hasStringValue()) continue;
                    String v = String.valueOf(d.getValue());
                    if (!pat.matcher(v).find()) continue;
                    out.println("STR " + d.getAddress() + "\t" + v.replace("\n", "\\n"));
                    for (Reference r : rm.getReferencesTo(d.getAddress())) {
                        Function f = getFunctionContaining(r.getFromAddress());
                        out.println("   ref " + r.getFromAddress() + " in " + (f == null ? "?" : f.getName() + "@" + f.getEntryPoint()));
                        if (f != null && !fs.contains(f)) fs.add(f);
                    }
                }
                for (Function f : fs) dumpFunc(out, f, done);
            } else if (mode.equals("scalar")) {
                String[] r = arg.split("[,+]");
                long val = Long.parseLong(r[0], 16);
                Address s0 = toAddr(r[1]), s1 = toAddr(r[2]);
                InstructionIterator it = lst.getInstructions(new AddressSet(s0, s1), true);
                while (it.hasNext() && !monitor.isCancelled()) {
                    Instruction ins = it.next();
                    for (int i = 0; i < ins.getNumOperands(); i++) {
                        boolean hit = false;
                        for (Object obj : ins.getOpObjects(i)) {
                            if (obj instanceof Scalar && ((Scalar) obj).getUnsignedValue() == val) hit = true;
                        }
                        if (hit) {
                            Function f = getFunctionContaining(ins.getAddress());
                            out.println(ins.getAddress() + "\t" + ins + "\t" + (f == null ? "?" : f.getName()));
                            break;
                        }
                    }
                }
            } else {
                out.println("unknown mode " + mode);
            }
            out.close();
            println("Cam3dRE job done: " + line);
        }
        println("Cam3dRE ALL DONE");
    }
}
