/*
 * Stop the Advanced Machine Builder crashing on machines with free-standing modifier blocks.
 *
 * BaseItemAdvancedMachineBuilder.onControllerRightClick looks up each modifier position
 * in the machine's pattern and calls addMatchingStates on the result. A modifier may sit
 * where the pattern has no block, so the lookup returns null and the click throws an NPE.
 * This skips those positions: the builder can't place an optional block that isn't in
 * the pattern, and everything else still gets assembled.
 *
 * Usage: java -cp asm.jar tools/PatchMmceAddonsBuilder.java <Addons.jar in> <patched.jar out>
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

public class PatchMmceAddonsBuilder {
    static final String BUILDER = "github/alecsio/mmceaddons/common/item/BaseItemAdvancedMachineBuilder";
    static final String INFO = "hellfirepvp/modularmachinery/common/util/BlockArray$BlockInformation";

    public static void main(String[] args) throws Exception {
        int[] count = {0};
        try (ZipFile in = new ZipFile(args[0]);
             ZipOutputStream out = new ZipOutputStream(Files.newOutputStream(Path.of(args[1])))) {
            for (Enumeration<? extends ZipEntry> e = in.entries(); e.hasMoreElements(); ) {
                ZipEntry entry = e.nextElement();
                byte[] data;
                try (InputStream is = in.getInputStream(entry)) {
                    data = is.readAllBytes();
                }
                if (entry.getName().equals(BUILDER + ".class")) {
                    data = patch(data, count);
                }
                out.putNextEntry(new ZipEntry(entry.getName()));
                out.write(data);
                out.closeEntry();
            }
        }
        if (count[0] != 1) {
            Files.delete(Path.of(args[1]));
            System.err.println("expected one modifier lookup in onControllerRightClick, patched " + count[0]);
            System.exit(1);
        }
        System.out.println("patched " + BUILDER + " -> " + args[1]);
    }

    // After "info = pattern.get(pos.rotate(...))": if (info == null) continue;
    static byte[] patch(byte[] data, int[] count) {
        ClassReader reader = new ClassReader(data);
        ClassWriter writer = new ClassWriter(reader, ClassWriter.COMPUTE_MAXS);
        reader.accept(new ClassVisitor(Opcodes.ASM9, writer) {
            @Override
            public MethodVisitor visitMethod(int access, String name, String desc, String sig, String[] exc) {
                MethodVisitor mv = super.visitMethod(access, name, desc, sig, exc);
                if (!name.equals("onControllerRightClick")) return mv;
                return new MethodVisitor(Opcodes.ASM9, mv) {
                    Label lastLabel, framed, loop;
                    int state = 0;

                    @Override
                    public void visitLabel(Label label) {
                        lastLabel = label;
                        super.visitLabel(label);
                    }

                    @Override
                    public void visitFrame(int type, int numLocal, Object[] local, int numStack, Object[] stack) {
                        framed = lastLabel;
                        super.visitFrame(type, numLocal, local, numStack, stack);
                    }

                    @Override
                    public void visitMethodInsn(int opcode, String owner, String method, String d, boolean itf) {
                        if (method.equals("hasNext")) loop = framed;
                        if (method.equals("func_190942_a")) state = 1;
                        super.visitMethodInsn(opcode, owner, method, d, itf);
                    }

                    @Override
                    public void visitTypeInsn(int opcode, String type) {
                        if (state == 1 && opcode == Opcodes.CHECKCAST && type.equals(INFO)) state = 2;
                        super.visitTypeInsn(opcode, type);
                    }

                    @Override
                    public void visitVarInsn(int opcode, int index) {
                        super.visitVarInsn(opcode, index);
                        if (state == 2 && opcode == Opcodes.ASTORE) {
                            state = 0;
                            count[0]++;
                            super.visitVarInsn(Opcodes.ALOAD, index);
                            super.visitJumpInsn(Opcodes.IFNULL, loop);
                        }
                    }
                };
            }
        }, 0);
        return writer.toByteArray();
    }
}
