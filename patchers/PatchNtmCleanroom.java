/*
 * Make NTM: Community Edition's mixins load on Cleanroom.
 *
 * HbmCorePlugin declares @TransformerExclusions({"com.hbm.core", "com.hbm.mixin"}).
 * Cleanroom's mixin loader (cleanmix) refuses to load mixin classes from an excluded
 * package ("Classloader restrictions [PACKAGE_TRANSFORMER_EXCLUSION]"), so every NTM
 * mixin is silently skipped. This renames the excluded package to "com.hbm.mixiN"
 * (same byte length, matches nothing) inside that one class.
 *
 * Usage: java tools/PatchNtmCleanroom.java <NTM-CE.jar in> <patched.jar out>
 */
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Enumeration;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;
import java.util.zip.ZipOutputStream;

public class PatchNtmCleanroom {
    static final String CLASS = "com/hbm/core/HbmCorePlugin.class";

    public static void main(String[] args) throws Exception {
        byte[] oldConst = constant("com.hbm.mixin"), newConst = constant("com.hbm.mixiN");
        try (ZipFile in = new ZipFile(args[0]);
             ZipOutputStream out = new ZipOutputStream(Files.newOutputStream(Path.of(args[1])))) {
            for (Enumeration<? extends ZipEntry> e = in.entries(); e.hasMoreElements(); ) {
                ZipEntry entry = e.nextElement();
                byte[] data = in.getInputStream(entry).readAllBytes();
                if (entry.getName().equals(CLASS)) {
                    int at = indexOf(data, oldConst, 0);
                    if (at < 0 || indexOf(data, oldConst, at + 1) >= 0)
                        throw new IllegalStateException("expected exactly one 'com.hbm.mixin' constant in " + CLASS);
                    System.arraycopy(newConst, 0, data, at, newConst.length);
                }
                ZipEntry copy = new ZipEntry(entry.getName());
                copy.setTime(entry.getTime());
                out.putNextEntry(copy);
                out.write(data);
                out.closeEntry();
            }
        }
        System.out.println("patched " + CLASS + " -> " + args[1]);
    }

    // A CONSTANT_Utf8 body: 2-byte length, then the bytes
    static byte[] constant(String s) {
        byte[] text = s.getBytes(StandardCharsets.UTF_8), out = new byte[text.length + 2];
        out[0] = (byte) (text.length >> 8);
        out[1] = (byte) text.length;
        System.arraycopy(text, 0, out, 2, text.length);
        return out;
    }

    static int indexOf(byte[] data, byte[] needle, int from) {
        outer:
        for (int i = from; i <= data.length - needle.length; i++) {
            for (int j = 0; j < needle.length; j++) if (data[i + j] != needle[j]) continue outer;
            return i;
        }
        return -1;
    }
}
