/*
 * Stop NTM CE: Space from crashing when another mod creates an entity during preInit.
 *
 * com.hbmspace.main.ModEventHandler is an @EventBusSubscriber, so its static
 * attachRadCap(AttachCapabilitiesEvent<Entity>) listens from mod construction on,
 * but HbmLivingCapabilitySpace$EntityHbmPropsProvider.ENT_HBM_PROPS_CAP is only
 * injected during Space's own preInit. Hatchery's client preInit builds a chicken
 * for its egg machine renderer first, and the provider constructor NPEs on the null
 * capability. This inserts "if (ENT_HBM_PROPS_CAP == null) return;" at the top of
 * attachRadCap; entities built that early are render dummies that never enter a world.
 *
 * Usage: java -cp asm.jar tools/PatchNtmSpaceCapability.java <NTM-Space.jar in> <patched.jar out>
 */
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Enumeration;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;
import java.util.zip.ZipOutputStream;

import org.objectweb.asm.ClassReader;
import org.objectweb.asm.ClassVisitor;
import org.objectweb.asm.ClassWriter;
import org.objectweb.asm.Label;
import org.objectweb.asm.MethodVisitor;
import org.objectweb.asm.Opcodes;

public class PatchNtmSpaceCapability {
    static final String CLASS = "com/hbmspace/main/ModEventHandler.class";
    static final String PROVIDER = "com/hbmspace/capability/HbmLivingCapabilitySpace$EntityHbmPropsProvider";
    static final String CAP_DESC = "Lnet/minecraftforge/common/capabilities/Capability;";

    public static void main(String[] args) throws Exception {
        int patched = 0;
        try (ZipFile in = new ZipFile(args[0]);
             ZipOutputStream out = new ZipOutputStream(Files.newOutputStream(Path.of(args[1])))) {
            for (Enumeration<? extends ZipEntry> e = in.entries(); e.hasMoreElements(); ) {
                ZipEntry entry = e.nextElement();
                byte[] data;
                try (InputStream is = in.getInputStream(entry)) {
                    data = is.readAllBytes();
                }
                if (entry.getName().equals(CLASS)) {
                    int[] count = {0};
                    data = patch(data, count);
                    patched = count[0];
                }
                out.putNextEntry(new ZipEntry(entry.getName()));
                out.write(data);
                out.closeEntry();
            }
        }
        if (patched != 1) {
            Files.delete(Path.of(args[1]));
            System.err.println("expected exactly one attachRadCap in " + CLASS + ", found " + patched);
            System.exit(1);
        }
        System.out.println("patched " + CLASS + " -> " + args[1]);
    }

    static byte[] patch(byte[] data, int[] count) {
        ClassReader reader = new ClassReader(data);
        // Frames are recomputed; the method only branches between Object-typed locals.
        ClassWriter writer = new ClassWriter(reader, ClassWriter.COMPUTE_FRAMES) {
            @Override
            protected String getCommonSuperClass(String a, String b) {
                return "java/lang/Object";
            }
        };
        reader.accept(new ClassVisitor(Opcodes.ASM9, writer) {
            @Override
            public MethodVisitor visitMethod(int access, String name, String desc, String sig, String[] exc) {
                MethodVisitor mv = super.visitMethod(access, name, desc, sig, exc);
                if (!name.equals("attachRadCap")) return mv;
                count[0]++;
                return new MethodVisitor(Opcodes.ASM9, mv) {
                    @Override
                    public void visitCode() {
                        super.visitCode();
                        Label ready = new Label();
                        super.visitFieldInsn(Opcodes.GETSTATIC, PROVIDER, "ENT_HBM_PROPS_CAP", CAP_DESC);
                        super.visitJumpInsn(Opcodes.IFNONNULL, ready);
                        super.visitInsn(Opcodes.RETURN);
                        super.visitLabel(ready);
                    }
                };
            }
        }, ClassReader.EXPAND_FRAMES);
        return writer.toByteArray();
    }
}
