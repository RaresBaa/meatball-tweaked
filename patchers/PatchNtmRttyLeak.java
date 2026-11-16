/*
 * Stop NTM: Community Edition keeping every unloaded dimension in memory.
 *
 * RTTYSystem.broadcast and newMessages are static maps keyed by Pair<World, String>,
 * and nothing removes a world from them. updateBroadcastQueue adds a test channel for
 * every loaded world, so each dimension that is loaded even briefly stays on the heap.
 * This adds RTTYSystem.forgetWorld(World) and calls it first in the existing
 * ModEventHandler.worldUnload, so a world's channels go away when it unloads.
 *
 * Usage: java -cp asm.jar tools/PatchNtmRttyLeak.java <NTM-CE.jar in> <patched.jar out>
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

public class PatchNtmRttyLeak {
    static final String RTTY = "com/hbm/tileentity/network/RTTYSystem";
    static final String HANDLER = "com/hbm/main/ModEventHandler";
    static final String PAIR = "com/hbm/util/Tuple$Pair";
    static final String UNLOAD = "net/minecraftforge/event/world/WorldEvent$Unload";
    static final String WORLD_DESC = "Lnet/minecraft/world/World;";
    static final String MAP_DESC = "Ljava/util/Map;";

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
                if (entry.getName().equals(RTTY + ".class")) {
                    data = patchRtty(data);
                    patched++;
                } else if (entry.getName().equals(HANDLER + ".class")) {
                    int[] count = {0};
                    data = patchHandler(data, count);
                    patched += count[0];
                }
                out.putNextEntry(new ZipEntry(entry.getName()));
                out.write(data);
                out.closeEntry();
            }
        }
        if (patched != 2) {
            Files.delete(Path.of(args[1]));
            System.err.println("expected RTTYSystem and one ModEventHandler.worldUnload, patched " + patched);
            System.exit(1);
        }
        System.out.println("patched " + RTTY + " and " + HANDLER + " -> " + args[1]);
    }

    static byte[] patchRtty(byte[] data) {
        ClassReader reader = new ClassReader(data);
        ClassWriter writer = new ClassWriter(reader, ClassWriter.COMPUTE_MAXS);
        reader.accept(new ClassVisitor(Opcodes.ASM9, writer) {
            @Override
            public void visitEnd() {
                addForgetWorld(this);
                addForget(this);
                super.visitEnd();
            }
        }, 0);
        return writer.toByteArray();
    }

    // public static void forgetWorld(World world) { forget(broadcast, world); forget(newMessages, world); }
    static void addForgetWorld(ClassVisitor cv) {
        MethodVisitor mv = cv.visitMethod(Opcodes.ACC_PUBLIC | Opcodes.ACC_STATIC, "forgetWorld",
                "(" + WORLD_DESC + ")V", null, null);
        mv.visitCode();
        for (String field : new String[] {"broadcast", "newMessages"}) {
            mv.visitFieldInsn(Opcodes.GETSTATIC, RTTY, field, MAP_DESC);
            mv.visitVarInsn(Opcodes.ALOAD, 0);
            mv.visitMethodInsn(Opcodes.INVOKESTATIC, RTTY, "forget", "(" + MAP_DESC + WORLD_DESC + ")V", false);
        }
        mv.visitInsn(Opcodes.RETURN);
        mv.visitMaxs(0, 0);
        mv.visitEnd();
    }

    // private static void forget(Map map, World world) {
    //     Iterator it = map.keySet().iterator();
    //     while (it.hasNext()) if (((Pair) it.next()).getKey() == world) it.remove();
    // }
    static void addForget(ClassVisitor cv) {
        MethodVisitor mv = cv.visitMethod(Opcodes.ACC_PRIVATE | Opcodes.ACC_STATIC, "forget",
                "(" + MAP_DESC + WORLD_DESC + ")V", null, null);
        Label loop = new Label();
        Label done = new Label();
        mv.visitCode();
        mv.visitVarInsn(Opcodes.ALOAD, 0);
        mv.visitMethodInsn(Opcodes.INVOKEINTERFACE, "java/util/Map", "keySet", "()Ljava/util/Set;", true);
        mv.visitMethodInsn(Opcodes.INVOKEINTERFACE, "java/util/Set", "iterator", "()Ljava/util/Iterator;", true);
        mv.visitVarInsn(Opcodes.ASTORE, 2);
        mv.visitLabel(loop);
        mv.visitFrame(Opcodes.F_APPEND, 1, new Object[] {"java/util/Iterator"}, 0, null);
        mv.visitVarInsn(Opcodes.ALOAD, 2);
        mv.visitMethodInsn(Opcodes.INVOKEINTERFACE, "java/util/Iterator", "hasNext", "()Z", true);
        mv.visitJumpInsn(Opcodes.IFEQ, done);
        mv.visitVarInsn(Opcodes.ALOAD, 2);
        mv.visitMethodInsn(Opcodes.INVOKEINTERFACE, "java/util/Iterator", "next", "()Ljava/lang/Object;", true);
        mv.visitTypeInsn(Opcodes.CHECKCAST, PAIR);
        mv.visitMethodInsn(Opcodes.INVOKEVIRTUAL, PAIR, "getKey", "()Ljava/lang/Object;", false);
        mv.visitVarInsn(Opcodes.ALOAD, 1);
        mv.visitJumpInsn(Opcodes.IF_ACMPNE, loop);
        mv.visitVarInsn(Opcodes.ALOAD, 2);
        mv.visitMethodInsn(Opcodes.INVOKEINTERFACE, "java/util/Iterator", "remove", "()V", true);
        mv.visitJumpInsn(Opcodes.GOTO, loop);
        mv.visitLabel(done);
        mv.visitFrame(Opcodes.F_SAME, 0, null, 0, null);
        mv.visitInsn(Opcodes.RETURN);
        mv.visitMaxs(0, 0);
        mv.visitEnd();
    }

    static byte[] patchHandler(byte[] data, int[] count) {
        ClassReader reader = new ClassReader(data);
        ClassWriter writer = new ClassWriter(reader, ClassWriter.COMPUTE_MAXS);
        reader.accept(new ClassVisitor(Opcodes.ASM9, writer) {
            @Override
            public MethodVisitor visitMethod(int access, String name, String desc, String sig, String[] exc) {
                MethodVisitor mv = super.visitMethod(access, name, desc, sig, exc);
                if (!name.equals("worldUnload")) return mv;
                count[0]++;
                return new MethodVisitor(Opcodes.ASM9, mv) {
                    @Override
                    public void visitCode() {
                        super.visitCode();
                        super.visitVarInsn(Opcodes.ALOAD, 1);
                        super.visitMethodInsn(Opcodes.INVOKEVIRTUAL, UNLOAD, "getWorld", "()" + WORLD_DESC, false);
                        super.visitMethodInsn(Opcodes.INVOKESTATIC, RTTY, "forgetWorld", "(" + WORLD_DESC + ")V", false);
                    }
                };
            }
        }, 0);
        return writer.toByteArray();
    }
}
