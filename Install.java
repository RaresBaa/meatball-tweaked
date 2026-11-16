/*
 * Build the MeatballCraft Tweaked Prism instance.
 *
 * Downloads MeatballCraft prerelease-0.18.6.4 from CurseForge and SK-Tweaks from GitHub,
 * applies this repo's changes (overlay/, pack.json), downloads and patches the mods
 * (downloads.json, patchers/) and writes a Prism instance folder. Every download is
 * checked against its sha1. Downloads are kept in .cache/, so running it again is fast.
 *
 * Needs a JDK 25 (not just a JRE): run it from this folder with
 *   java Install.java [--out <folder>] [--zip]
 *
 *   --out <folder>  where to create the instance (default: MeatballCraft-Tweaked)
 *   --zip           also write <folder>.zip, which Prism's "Import" accepts
 */
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.DirectoryNotEmptyException;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.StandardCopyOption;
import java.nio.file.attribute.BasicFileAttributes;
import java.security.MessageDigest;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Stream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;
import java.util.zip.ZipOutputStream;

public class Install {
    static final int THREADS = 8;
    static final String USER_AGENT = "meatball-tweaked-installer";
    static final HttpClient HTTP = HttpClient.newBuilder()
            .followRedirects(HttpClient.Redirect.NORMAL)
            .connectTimeout(Duration.ofSeconds(30))
            .build();

    static Path repo, cache;

    public static void main(String[] args) throws Exception {
        String outName = "MeatballCraft-Tweaked";
        boolean zip = false;
        for (int i = 0; i < args.length; i++) {
            switch (args[i]) {
                case "--out" -> outName = args[++i];
                case "--zip" -> zip = true;
                default -> fail("usage: java Install.java [--out <folder>] [--zip]");
            }
        }
        repo = findRepo();
        cache = repo.resolve(".cache");
        Path out = Path.of(outName).toAbsolutePath().normalize();
        if (Files.exists(out))
            fail(out + " already exists. Choose another folder with --out, or delete it first. "
                    + "To update an instance you play in, build a new one and copy your saves over.");

        Map<String, Object> pack = obj(Json.parse(Files.readString(repo.resolve("pack.json"))));
        List<Object> downloads = list(Json.parse(Files.readString(repo.resolve("downloads.json"))));
        Map<String, Object> base = obj(pack.get("base")), sk = obj(pack.get("skTweaks")), asm = obj(pack.get("asm"));

        // 1. Download everything
        List<Download> jobs = new ArrayList<>();
        jobs.add(new Download("MeatballCraft", List.of(str(base.get("url"))), str(base.get("sha1"))));
        jobs.add(new Download("SK-Tweaks", List.of(str(sk.get("url"))), null));
        jobs.add(new Download("ASM", List.of(str(asm.get("url"))), str(asm.get("sha1"))));
        for (Object d : downloads) {
            Map<String, Object> m = obj(d);
            jobs.add(new Download(str(m.get("path")), list(m.get("urls")).stream().map(Install::str).toList(),
                    str(m.get("sha1"))));
        }
        Map<String, Path> files = downloadAll(jobs);

        // 2. Build the instance in a temporary folder, then move it into place
        Path work = out.resolveSibling(out.getFileName() + ".incomplete");
        deleteTree(work);
        Path mc = Files.createDirectories(work.resolve("minecraft"));

        System.out.println("Extracting MeatballCraft");
        try (ZipFile z = new ZipFile(files.get("MeatballCraft").toFile())) {
            for (ZipEntry e : z.stream().toList()) {
                String name = e.getName().replace('\\', '/');
                if (e.isDirectory() || !name.startsWith("overrides/")) continue;
                write(safe(mc, name.substring("overrides/".length())), z.getInputStream(e));
            }
        }

        System.out.println("Adding SK-Tweaks");
        try (ZipFile z = new ZipFile(files.get("SK-Tweaks").toFile())) {
            String top = z.entries().nextElement().getName().split("/")[0] + "/";
            for (Object o : list(sk.get("files"))) {
                Map<String, Object> f = obj(o);
                ZipEntry e = z.getEntry(top + str(f.get("from")));
                if (e == null) fail("SK-Tweaks is missing " + f.get("from"));
                byte[] data = z.getInputStream(e).readAllBytes();
                if (!hex(sha1(data)).equals(str(f.get("sha1")))) fail("SK-Tweaks file changed: " + f.get("from"));
                Path dest = safe(mc, str(f.get("to")));
                Files.createDirectories(dest.getParent());
                Files.write(dest, data);
            }
        }

        System.out.println("Applying changes");
        for (Object o : list(pack.get("delete"))) {
            Path p = safe(mc, str(o));
            Files.deleteIfExists(p);
            for (Path dir = p.getParent(); !dir.equals(mc) && isEmptyDir(dir); dir = dir.getParent())
                Files.delete(dir);
        }
        // Configs that mods rewrote with Linux line endings
        for (Object o : list(pack.get("lf"))) {
            Path p = safe(mc, str(o));
            byte[] data = Files.readAllBytes(p);
            Files.write(p, new String(data, StandardCharsets.ISO_8859_1).replace("\r\n", "\n")
                    .getBytes(StandardCharsets.ISO_8859_1));
        }
        Path diffs = repo.resolve("overlay/diffs");
        int[] count = {0, 0};
        if (Files.isDirectory(diffs)) {
            try (Stream<Path> walk = Files.walk(diffs)) {
                for (Path diff : walk.filter(Files::isRegularFile).toList()) {
                    String rel = diffs.relativize(diff).toString().replace('\\', '/');
                    rel = rel.substring(0, rel.length() - ".diff".length());
                    Path target = safe(mc, rel);
                    if (!Files.isRegularFile(target)) fail("can't patch " + rel + ": the pack doesn't have it");
                    Files.write(target, Patch.apply(Files.readAllBytes(target), Files.readAllBytes(diff), rel));
                    count[0]++;
                }
            }
        }
        Path overlay = repo.resolve("overlay/files");
        if (Files.isDirectory(overlay)) {
            try (Stream<Path> walk = Files.walk(overlay)) {
                for (Path f : walk.filter(Files::isRegularFile).toList()) {
                    Path dest = mc.resolve(overlay.relativize(f).toString());
                    Files.createDirectories(dest.getParent());
                    Files.copy(f, dest, StandardCopyOption.REPLACE_EXISTING);
                    count[1]++;
                }
            }
        }
        System.out.println("  " + count[0] + " files changed, " + count[1] + " added or replaced, "
                + list(pack.get("delete")).size() + " removed");

        System.out.println("Adding mods and shader packs");
        Path asmJar = files.get("ASM");
        for (Object d : downloads) {
            Map<String, Object> m = obj(d);
            String path = str(m.get("path"));
            Path dest = safe(mc, path);
            Files.createDirectories(dest.getParent());
            if (m.get("patch") == null) {
                Files.copy(files.get(path), dest, StandardCopyOption.REPLACE_EXISTING);
                continue;
            }
            Path current = files.get(path);
            List<Object> tools = list(m.get("patch"));
            for (int i = 0; i < tools.size(); i++) {
                Path next = i == tools.size() - 1 ? dest : work.resolve("patch-" + i + ".jar");
                runPatcher(asmJar, str(tools.get(i)), current, next);
                if (i > 0) Files.delete(current);
                current = next;
            }
            if (!contentSha1(dest).equals(str(m.get("contentSha1"))))
                fail("patching " + path + " gave an unexpected result");
        }

        System.out.println("Writing the Prism instance");
        Path instance = repo.resolve("instance");
        try (Stream<Path> walk = Files.walk(instance)) {
            for (Path f : walk.filter(Files::isRegularFile).toList()) {
                Path dest = work.resolve(instance.relativize(f).toString());
                Files.createDirectories(dest.getParent());
                Files.copy(f, dest);
            }
        }
        Files.move(work, out);

        if (zip) {
            Path zipPath = out.resolveSibling(out.getFileName() + ".zip");
            System.out.println("Writing " + zipPath);
            zipFolder(out, zipPath);
        }
        System.out.println();
        System.out.println("Done: " + out);
        System.out.println("Move that folder into Prism's instances folder (Prism: Folders > Instances), or import "
                + (zip ? "the zip" : "a zip made with --zip") + " with Add Instance > Import.");
        System.out.println("Then choose Java 25 in the instance's Settings > Java.");
    }

    // --- Downloads -------------------------------------------------------------------------

    record Download(String key, List<String> urls, String sha1) {}

    static Map<String, Path> downloadAll(List<Download> jobs) throws Exception {
        Files.createDirectories(cache.resolve("files"));
        Map<String, Path> result = new LinkedHashMap<>();
        Map<String, Future<Path>> futures = new LinkedHashMap<>();
        AtomicInteger done = new AtomicInteger();
        int total = jobs.size();
        System.out.println("Downloading " + total + " files into " + cache);
        ExecutorService pool = Executors.newFixedThreadPool(THREADS);
        try {
            for (Download job : jobs) {
                futures.put(job.key(), pool.submit(() -> {
                    Path p = download(job);
                    int n = done.incrementAndGet();
                    if (n % 50 == 0 || n == total) System.out.println("  " + n + " of " + total);
                    return p;
                }));
            }
            List<String> failed = new ArrayList<>();
            for (var e : futures.entrySet()) {
                try {
                    result.put(e.getKey(), e.getValue().get());
                } catch (Exception ex) {
                    Throwable cause = ex.getCause() != null ? ex.getCause() : ex;
                    failed.add(e.getKey() + ": " + cause.getMessage());
                }
            }
            if (!failed.isEmpty()) {
                failed.forEach(f -> System.out.println("FAILED " + f));
                fail(failed.size() + " downloads failed. Run the installer again to retry them.");
            }
        } finally {
            pool.shutdown();
        }
        return result;
    }

    static Path download(Download job) throws Exception {
        String name = job.sha1() != null ? job.sha1() : "url-" + hex(sha1(job.urls().get(0).getBytes(StandardCharsets.UTF_8)));
        Path dest = cache.resolve("files").resolve(name);
        if (Files.exists(dest) && (job.sha1() == null || hex(fileSha1(dest)).equals(job.sha1()))) return dest;
        Path part = dest.resolveSibling(name + ".part");
        String error = "no url";
        for (String url : job.urls()) {
            for (int attempt = 1; attempt <= 3; attempt++) {
                try {
                    HttpRequest req = HttpRequest.newBuilder(URI.create(url)).header("User-Agent", USER_AGENT).build();
                    HttpResponse<Path> resp = HTTP.send(req, HttpResponse.BodyHandlers.ofFile(part));
                    if (resp.statusCode() != 200) {
                        error = "HTTP " + resp.statusCode() + " from " + url;
                        if (resp.statusCode() == 404) break;
                        continue;
                    }
                    if (job.sha1() != null && !hex(fileSha1(part)).equals(job.sha1())) {
                        error = "hash mismatch from " + url;
                        continue;
                    }
                    Files.move(part, dest, StandardCopyOption.REPLACE_EXISTING);
                    return dest;
                } catch (IOException e) {
                    error = e + " from " + url;
                }
            }
        }
        Files.deleteIfExists(part);
        throw new IOException(error);
    }

    // --- Patching ----------------------------------------------------------------------------

    static void runPatcher(Path asmJar, String tool, Path in, Path out) throws Exception {
        String java = ProcessHandle.current().info().command().orElse("java");
        Path source = repo.resolve("patchers").resolve(tool + ".java");
        Process p = new ProcessBuilder(java, "-cp", asmJar.toString(), source.toString(), in.toString(), out.toString())
                .inheritIO().start();
        if (p.waitFor() != 0) fail(tool + " failed");
    }

    /** sha1 over the sorted entry names and the sha1 of each entry, ignoring zip metadata. */
    static String contentSha1(Path jar) throws Exception {
        MessageDigest md = MessageDigest.getInstance("SHA-1");
        try (ZipFile z = new ZipFile(jar.toFile())) {
            List<ZipEntry> entries = new ArrayList<>(z.stream().filter(e -> !e.isDirectory()).toList());
            entries.sort((a, b) -> Arrays.compareUnsigned(a.getName().getBytes(StandardCharsets.UTF_8),
                    b.getName().getBytes(StandardCharsets.UTF_8)));
            for (ZipEntry e : entries) {
                md.update(e.getName().getBytes(StandardCharsets.UTF_8));
                md.update((byte) 0);
                try (InputStream in = z.getInputStream(e)) {
                    md.update(sha1(in.readAllBytes()));
                }
            }
        }
        return hex(md.digest());
    }

    // --- Files -------------------------------------------------------------------------------

    static Path findRepo() {
        try {
            Path src = Path.of(Install.class.getProtectionDomain().getCodeSource().getLocation().toURI());
            Path dir = Files.isDirectory(src) ? src : src.getParent();
            if (Files.exists(dir.resolve("pack.json"))) return dir;
        } catch (Exception ignored) {
        }
        Path cwd = Path.of("").toAbsolutePath();
        if (!Files.exists(cwd.resolve("pack.json"))) fail("run this from the meatball-tweaked folder");
        return cwd;
    }

    /** Resolve a relative path from a download or the pack, refusing anything that leaves root. */
    static Path safe(Path root, String rel) {
        Path p = root.resolve(rel).normalize();
        if (!p.startsWith(root) || p.equals(root)) fail("unsafe path: " + rel);
        return p;
    }

    static void write(Path dest, InputStream in) throws IOException {
        Files.createDirectories(dest.getParent());
        try (in) {
            Files.copy(in, dest, StandardCopyOption.REPLACE_EXISTING);
        }
    }

    static boolean isEmptyDir(Path dir) throws IOException {
        if (!Files.isDirectory(dir)) return false;
        try (Stream<Path> s = Files.list(dir)) {
            return s.findAny().isEmpty();
        }
    }

    static void deleteTree(Path root) throws IOException {
        if (!Files.exists(root)) return;
        Files.walkFileTree(root, new SimpleFileVisitor<>() {
            @Override
            public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
                Files.delete(file);
                return FileVisitResult.CONTINUE;
            }

            @Override
            public FileVisitResult postVisitDirectory(Path dir, IOException e) throws IOException {
                try {
                    Files.delete(dir);
                } catch (DirectoryNotEmptyException ignored) {
                }
                return FileVisitResult.CONTINUE;
            }
        });
    }

    static void zipFolder(Path folder, Path zipPath) throws IOException {
        String top = folder.getFileName().toString() + "/";
        try (ZipOutputStream zos = new ZipOutputStream(Files.newOutputStream(zipPath));
             Stream<Path> walk = Files.walk(folder)) {
            for (Path f : walk.filter(Files::isRegularFile).toList()) {
                zos.putNextEntry(new ZipEntry(top + folder.relativize(f).toString().replace('\\', '/')));
                Files.copy(f, zos);
                zos.closeEntry();
            }
        }
    }

    static byte[] sha1(byte[] data) throws Exception {
        return MessageDigest.getInstance("SHA-1").digest(data);
    }

    static byte[] fileSha1(Path p) throws Exception {
        MessageDigest md = MessageDigest.getInstance("SHA-1");
        try (InputStream in = Files.newInputStream(p)) {
            byte[] buf = new byte[1 << 16];
            for (int n; (n = in.read(buf)) > 0; ) md.update(buf, 0, n);
        }
        return md.digest();
    }

    static String hex(byte[] b) {
        return HexFormat.of().formatHex(b);
    }

    static void fail(String message) {
        System.err.println("Error: " + message);
        System.exit(1);
    }

    @SuppressWarnings("unchecked")
    static Map<String, Object> obj(Object o) {
        return (Map<String, Object>) o;
    }

    @SuppressWarnings("unchecked")
    static List<Object> list(Object o) {
        return (List<Object>) o;
    }

    static String str(Object o) {
        return (String) o;
    }
}

/** Applies a unified diff made by tools/export_tweaked.py. Lines keep their own endings. */
class Patch {
    static byte[] apply(byte[] original, byte[] diff, String name) {
        List<byte[]> src = lines(original), d = lines(diff), result = new ArrayList<>();
        int pos = 0, i = 0;
        while (i < d.size() && !startsWith(d.get(i), "@@")) i++;
        while (i < d.size()) {
            String header = new String(d.get(i++), StandardCharsets.ISO_8859_1).trim();
            String[] parts = header.split(" ");
            int[] old = range(parts[1].substring(1)), neu = range(parts[2].substring(1));
            int start = old[1] == 0 ? old[0] : old[0] - 1;
            if (start < pos || start > src.size()) throw bad(name, header);
            while (pos < start) result.add(src.get(pos++));

            // Read the hunk as (kind, line) pairs; "\ No newline" drops the previous line's ending
            List<byte[]> hunk = new ArrayList<>();
            List<Character> kinds = new ArrayList<>();
            int oldLeft = old[1], newLeft = neu[1];
            while (oldLeft > 0 || newLeft > 0) {
                if (i >= d.size()) throw bad(name, header);
                byte[] line = d.get(i++);
                char kind = (char) line[0];
                if (kind == '\\') {
                    stripNewline(hunk);
                    continue;
                }
                if (kind == ' ') { oldLeft--; newLeft--; }
                else if (kind == '-') oldLeft--;
                else if (kind == '+') newLeft--;
                else throw bad(name, header);
                kinds.add(kind);
                hunk.add(Arrays.copyOfRange(line, 1, line.length));
            }
            if (i < d.size() && d.get(i).length > 0 && d.get(i)[0] == '\\') {
                stripNewline(hunk);
                i++;
            }
            for (int k = 0; k < hunk.size(); k++) {
                char kind = kinds.get(k);
                if (kind != '+') {
                    if (pos >= src.size() || !Arrays.equals(src.get(pos), hunk.get(k))) throw bad(name, header);
                    pos++;
                }
                if (kind != '-') result.add(hunk.get(k));
            }
        }
        while (pos < src.size()) result.add(src.get(pos++));
        int size = 0;
        for (byte[] line : result) size += line.length;
        byte[] out = new byte[size];
        int at = 0;
        for (byte[] line : result) {
            System.arraycopy(line, 0, out, at, line.length);
            at += line.length;
        }
        return out;
    }

    static void stripNewline(List<byte[]> hunk) {
        byte[] last = hunk.get(hunk.size() - 1);
        if (last.length > 0 && last[last.length - 1] == '\n')
            hunk.set(hunk.size() - 1, Arrays.copyOf(last, last.length - 1));
    }

    static int[] range(String s) {
        String[] p = s.split(",");
        return new int[]{Integer.parseInt(p[0]), p.length > 1 ? Integer.parseInt(p[1]) : 1};
    }

    static List<byte[]> lines(byte[] data) {
        List<byte[]> out = new ArrayList<>();
        int start = 0;
        for (int i = 0; i < data.length; i++) {
            if (data[i] == '\n') {
                out.add(Arrays.copyOfRange(data, start, i + 1));
                start = i + 1;
            }
        }
        if (start < data.length) out.add(Arrays.copyOfRange(data, start, data.length));
        return out;
    }

    static boolean startsWith(byte[] line, String prefix) {
        return new String(line, 0, Math.min(line.length, prefix.length()), StandardCharsets.ISO_8859_1).equals(prefix);
    }

    static IllegalStateException bad(String name, String header) {
        return new IllegalStateException("the diff for " + name + " doesn't apply at " + header);
    }
}

/** Just enough JSON for pack.json and downloads.json. */
class Json {
    final String s;
    int i;

    Json(String s) {
        this.s = s;
    }

    static Object parse(String s) {
        Json j = new Json(s);
        Object v = j.value();
        j.ws();
        if (j.i != s.length()) throw new IllegalArgumentException("trailing data in JSON at " + j.i);
        return v;
    }

    void ws() {
        while (i < s.length() && Character.isWhitespace(s.charAt(i))) i++;
    }

    Object value() {
        ws();
        char c = s.charAt(i);
        if (c == '{') {
            Map<String, Object> m = new LinkedHashMap<>();
            i++;
            ws();
            if (s.charAt(i) == '}') { i++; return m; }
            while (true) {
                ws();
                String k = string();
                ws();
                expect(':');
                m.put(k, value());
                ws();
                if (s.charAt(i) == ',') { i++; continue; }
                expect('}');
                return m;
            }
        }
        if (c == '[') {
            List<Object> l = new ArrayList<>();
            i++;
            ws();
            if (s.charAt(i) == ']') { i++; return l; }
            while (true) {
                l.add(value());
                ws();
                if (s.charAt(i) == ',') { i++; continue; }
                expect(']');
                return l;
            }
        }
        if (c == '"') return string();
        if (s.startsWith("true", i)) { i += 4; return true; }
        if (s.startsWith("false", i)) { i += 5; return false; }
        if (s.startsWith("null", i)) { i += 4; return null; }
        int start = i;
        while (i < s.length() && "+-0123456789.eE".indexOf(s.charAt(i)) >= 0) i++;
        if (start == i) throw new IllegalArgumentException("bad JSON at " + i);
        return Double.parseDouble(s.substring(start, i));
    }

    String string() {
        expect('"');
        StringBuilder b = new StringBuilder();
        while (true) {
            char c = s.charAt(i++);
            if (c == '"') return b.toString();
            if (c != '\\') { b.append(c); continue; }
            char e = s.charAt(i++);
            switch (e) {
                case 'n' -> b.append('\n');
                case 't' -> b.append('\t');
                case 'r' -> b.append('\r');
                case 'b' -> b.append('\b');
                case 'f' -> b.append('\f');
                case 'u' -> { b.append((char) Integer.parseInt(s.substring(i, i + 4), 16)); i += 4; }
                default -> b.append(e);
            }
        }
    }

    void expect(char c) {
        if (s.charAt(i) != c) throw new IllegalArgumentException("expected '" + c + "' in JSON at " + i);
        i++;
    }
}
