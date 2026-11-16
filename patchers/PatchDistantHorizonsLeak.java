/*
 * Stop Distant Horizons keeping every unloaded dimension in memory.
 *
 * WorldGeneratorInjector.worldGeneratorByLevelWrapper and
 * LocalSaveStructure.levelWrapperToFileMap are keyed by the level wrapper, which holds
 * the World, and neither is cleaned up. This adds a forget method to each and calls
 * both at the end of DhClientServerWorld.unloadLevel. Both maps fill again on demand:
 * ServerLevelModule binds a new generator and getSaveFolder recomputes the folder if
 * the level loads again.
 *
 * Usage: java -cp asm.jar tools/PatchDistantHorizonsLeak.java <DH.jar in> <patched.jar out>
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
import org.objectweb.asm.MethodVisitor;
import org.objectweb.asm.Opcodes;

public class PatchDistantHorizonsLeak {
    static final String INJECTOR = "com/seibel/distanthorizons/coreapi/DependencyInjection/WorldGeneratorInjector";
    static final String SAVES = "com/seibel/distanthorizons/core/file/structure/LocalSaveStructure";
    static final String WORLD = "com/seibel/distanthorizons/core/world/DhClientServerWorld";
    static final String SERVER_WORLD = "com/seibel/distanthorizons/core/world/AbstractDhServerWorld";
    static final String WRAPPER_DESC = "Lcom/seibel/distanthorizons/core/wrapperInterfaces/world/ILevelWrapper;";
    static final String API_WRAPPER_DESC = "Lcom/seibel/distanthorizons/api/interfaces/world/IDhApiLevelWrapper;";

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
                if (entry.getName().equals(INJECTOR + ".class")) {
                    data = addForget(data, INJECTOR, "worldGeneratorByLevelWrapper", "java/util/HashMap", API_WRAPPER_DESC);
                    patched++;
                } else if (entry.getName().equals(SAVES + ".class")) {
                    data = addForget(data, SAVES, "levelWrapperToFileMap", "java/util/concurrent/ConcurrentHashMap", WRAPPER_DESC);
                    patched++;
                } else if (entry.getName().equals(WORLD + ".class")) {
                    int[] count = {0};
                    data = patchUnload(data, count);
                    if (count[0] == 1) patched++;
                }
                out.putNextEntry(new ZipEntry(entry.getName()));
                out.write(data);
                out.closeEntry();
            }
        }
        if (patched != 3) {
            Files.delete(Path.of(args[1]));
            System.err.println("expected to patch 3 classes with one 'return true' in unloadLevel, patched " + patched);
            System.exit(1);
        }
        System.out.println("patched WorldGeneratorInjector, LocalSaveStructure and DhClientServerWorld -> " + args[1]);
    }

    // public void forget(wrapper) { map.remove(wrapper); }
    static byte[] addForget(byte[] data, String owner, String field, String mapType, String wrapperDesc) {
        ClassReader reader = new ClassReader(data);
        ClassWriter writer = new ClassWriter(reader, ClassWriter.COMPUTE_MAXS);
        reader.accept(new ClassVisitor(Opcodes.ASM9, writer) {
            @Override
            public void visitEnd() {
                MethodVisitor mv = visitMethod(Opcodes.ACC_PUBLIC, "forget", "(" + wrapperDesc + ")V", null, null);
                mv.visitCode();
                mv.visitVarInsn(Opcodes.ALOAD, 0);
                mv.visitFieldInsn(Opcodes.GETFIELD, owner, field, "L" + mapType + ";");
                mv.visitVarInsn(Opcodes.ALOAD, 1);
                mv.visitMethodInsn(Opcodes.INVOKEVIRTUAL, mapType, "remove", "(Ljava/lang/Object;)Ljava/lang/Object;", false);
                mv.visitInsn(Opcodes.POP);
                mv.visitInsn(Opcodes.RETURN);
                mv.visitMaxs(0, 0);
                mv.visitEnd();
                super.visitEnd();
            }
        }, 0);
        return writer.toByteArray();
    }

    // Inserted before the only "return true" of unloadLevel, after the level has closed.
    static byte[] patchUnload(byte[] data, int[] count) {
        ClassReader reader = new ClassReader(data);
        ClassWriter writer = new ClassWriter(reader, ClassWriter.COMPUTE_MAXS);
        reader.accept(new ClassVisitor(Opcodes.ASM9, writer) {
            @Override
            public MethodVisitor visitMethod(int access, String name, String desc, String sig, String[] exc) {
                MethodVisitor mv = super.visitMethod(access, name, desc, sig, exc);
                if (!name.equals("unloadLevel")) return mv;
                return new MethodVisitor(Opcodes.ASM9, mv) {
                    @Override
                    public void visitInsn(int opcode) {
                        if (opcode == Opcodes.ICONST_1) {
                            count[0]++;
                            super.visitVarInsn(Opcodes.ALOAD, 0);
                            super.visitFieldInsn(Opcodes.GETFIELD, SERVER_WORLD, "saveStructure", "L" + SAVES + ";");
                            super.visitVarInsn(Opcodes.ALOAD, 1);
                            super.visitMethodInsn(Opcodes.INVOKEVIRTUAL, SAVES, "forget", "(" + WRAPPER_DESC + ")V", false);
                            super.visitFieldInsn(Opcodes.GETSTATIC, INJECTOR, "INSTANCE", "L" + INJECTOR + ";");
                            super.visitVarInsn(Opcodes.ALOAD, 1);
                            super.visitMethodInsn(Opcodes.INVOKEVIRTUAL, INJECTOR, "forget", "(" + API_WRAPPER_DESC + ")V", false);
                        }
                        super.visitInsn(opcode);
                    }
                };
            }
        }, 0);
        return writer.toByteArray();
    }
}
