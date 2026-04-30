// Reference-vector generator for the Odin port of MersenneTwister.
// Produces the deterministic output of:
//   new org.apache.commons.math3.random.MersenneTwister(42L)
// captured as:
//   1) raw next(32) words (uint32) — to validate the core PRNG
//   2) nextInt(6)                  — to validate Apache's rejection-sampling on the
//                                    most common dice cap used by TripleA
//   3) nextInt(12)                 — non-power-of-two harder case
//
// Output is written to /home/caleb/todin/scripts/mt_reference_vector.txt as plain text:
//   raw32: <comma-separated 1024 unsigned ints>
//   nextInt6: <comma-separated 1024 ints in [0,6)>
//   nextInt12: <comma-separated 1024 ints in [0,12)>
//
// Run:   java -cp <commons-math3-jar> MtReferenceVector
import org.apache.commons.math3.random.MersenneTwister;
import java.io.PrintWriter;

public class MtReferenceVector {
    public static void main(String[] args) throws Exception {
        try (PrintWriter pw = new PrintWriter(args[0])) {
            // 1) raw 32-bit output (we read via nextInt() which calls next(32))
            MersenneTwister r1 = new MersenneTwister(42L);
            StringBuilder sb1 = new StringBuilder();
            for (int i = 0; i < 1024; i++) {
                if (i > 0) sb1.append(',');
                sb1.append(Integer.toUnsignedString(r1.nextInt()));
            }
            pw.println("raw32: " + sb1);

            // 2) nextInt(6) — power-of-two-style? 6 = 110b, NOT a power of 2 → rejection path
            MersenneTwister r2 = new MersenneTwister(42L);
            StringBuilder sb2 = new StringBuilder();
            for (int i = 0; i < 1024; i++) {
                if (i > 0) sb2.append(',');
                sb2.append(r2.nextInt(6));
            }
            pw.println("nextInt6: " + sb2);

            // 3) nextInt(12)
            MersenneTwister r3 = new MersenneTwister(42L);
            StringBuilder sb3 = new StringBuilder();
            for (int i = 0; i < 1024; i++) {
                if (i > 0) sb3.append(',');
                sb3.append(r3.nextInt(12));
            }
            pw.println("nextInt12: " + sb3);

            // 4) nextInt(8) — power-of-two path (8 & -8 == 8)
            MersenneTwister r4 = new MersenneTwister(42L);
            StringBuilder sb4 = new StringBuilder();
            for (int i = 0; i < 1024; i++) {
                if (i > 0) sb4.append(',');
                sb4.append(r4.nextInt(8));
            }
            pw.println("nextInt8: " + sb4);
        }
        System.out.println("OK wrote " + args[0]);
    }
}
