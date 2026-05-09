package games.strategy.engine.data;

import games.strategy.engine.framework.ServerGame;
import games.strategy.engine.random.PlainRandomSource;

import java.io.*;
import java.lang.reflect.Field;
import java.nio.file.*;
import java.util.Random;
import java.util.concurrent.atomic.AtomicLong;

import org.apache.commons.math3.random.MersenneTwister;

/**
 * Wrapper harness for characterization testing. Captures full GameData as JSON
 * before/after each game step (layer 22: runNextStep).
 *
 * Lower layers are captured by the Byte Buddy snapshot agent configured via
 * snapshot.config and jfr-layer* files.
 *
 * <p>RNG state capture (added 2026-05-09): the Odin port replays each snap
 * in isolation, so without state capture its MT and Math.random sequences
 * start fresh per snap (position 0) while Java's are accumulated from steps
 * 1..N-1. The before-meta.txt now records both:
 * <ul>
 *   <li>{@code mt_state: hex of mti(int) || mt[0..624] (u32 LE)} — the full
 *       MersenneTwister state used by PlainRandomSource for dice rolls.</li>
 *   <li>{@code math_random_seed: hex of java.util.Random.seed (long)} — the
 *       LCG state used by Math.random for AI weighted picks.</li>
 * </ul>
 * The Odin harness reads both at snap-load time and seeds its own RNGs to
 * match Java's accumulated state, so step-N dice match byte-for-byte.</p>
 */
public class SnapshotHarness {

    private final ServerGame game;
    private final Path outputDir;
    private int stepCounter = 0;
    private final GameStateJsonSerializer serializer = new GameStateJsonSerializer();

    public SnapshotHarness(ServerGame game, String outputDir, long rangeStart, long rangeEnd) {
        this.game = game;
        this.outputDir = Path.of(outputDir);
        try {
            Files.createDirectories(this.outputDir);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    /**
     * Wraps a runNextStep() call. Captures before/after JSON game state.
     */
    public void wrapStep(Runnable stepRunner) {
        stepCounter++;
        String stepName = game.getData().getSequence().getStep().getName();
        String delegateName = game.getData().getSequence().getStep().getDelegateName();
        int round = game.getData().getSequence().getRound();
        GamePlayer player = game.getData().getSequence().getStep().getPlayerId();
        String playerName = player != null ? player.getName() : "none";

        String stepDirName = String.format("step-%04d-round-%03d-%s", stepCounter, round, stepName);
        Path dir = outputDir.resolve("server_game_run_next_step").resolve(stepDirName);

        saveSnapshot("step-before", dir, stepName, delegateName, playerName, round);
        stepRunner.run();
        saveSnapshot("step-after", dir, stepName, delegateName, playerName, round);
    }

    private void saveSnapshot(String label, Path dir, String stepName, String delegateName,
                               String playerName, int round) {
        try {
            Files.createDirectories(dir);

            Path jsonFile = dir.resolve(label + "-gamedata.json");
            Files.writeString(jsonFile, serializer.serialize(game.getData()));

            Path metaFile = dir.resolve(label + "-meta.txt");
            try (var pw = new PrintWriter(Files.newBufferedWriter(metaFile))) {
                pw.println("step: " + stepCounter);
                pw.println("round: " + round);
                pw.println("stepName: " + stepName);
                pw.println("delegateName: " + delegateName);
                pw.println("player: " + playerName);
                pw.println("label: " + label);
                pw.println("timestamp: " + System.currentTimeMillis());
                pw.println("mt_state: " + dumpMersenneTwisterState());
                pw.println("math_random_seed: " + dumpMathRandomSeed());
            }

            System.out.println("[SnapshotHarness] Saved " + label
                    + " step=" + stepName + " round=" + round);

        } catch (Exception e) {
            System.err.println("[SnapshotHarness] Error saving " + label + " at step "
                    + stepCounter + ": " + e);
            e.printStackTrace();
        }
    }

    /**
     * Reflectively reads the MersenneTwister inside the game's PlainRandomSource
     * and returns a hex dump of {@code mti (4 bytes LE) || mt[0..624] (4 bytes LE each)}.
     * Total payload = 4 + 4*624 = 2500 bytes → 5000 hex chars.
     *
     * <p>If the game uses a non-PlainRandomSource (e.g. dummy random source in
     * tests) or the MT state cannot be read, returns "unknown" so the Odin
     * harness can fall back to a fresh seed (and snap will diverge but still
     * load).</p>
     */
    private String dumpMersenneTwisterState() {
        try {
            Object randomSource = game.getRandomSource();
            if (!(randomSource instanceof PlainRandomSource)) {
                return "unknown";
            }
            Field randomField = PlainRandomSource.class.getDeclaredField("random");
            randomField.setAccessible(true);
            Object generator = randomField.get(randomSource);
            if (!(generator instanceof MersenneTwister)) {
                return "unknown";
            }
            Field mtField = MersenneTwister.class.getDeclaredField("mt");
            Field mtiField = MersenneTwister.class.getDeclaredField("mti");
            mtField.setAccessible(true);
            mtiField.setAccessible(true);
            int[] mt = (int[]) mtField.get(generator);
            int mti = (int) mtiField.get(generator);
            StringBuilder sb = new StringBuilder(5000);
            // mti first (4 bytes LE)
            appendHexLE(sb, mti);
            for (int i = 0; i < mt.length; i++) {
                appendHexLE(sb, mt[i]);
            }
            return sb.toString();
        } catch (ReflectiveOperationException e) {
            return "error:" + e.getClass().getSimpleName();
        }
    }

    /**
     * Reflectively reads the seed of {@code java.lang.Math$RandomNumberGeneratorHolder.randomNumberGenerator}.
     * Requires {@code --add-opens java.base/java.lang=ALL-UNNAMED} on the JVM
     * (already set by smoke-testing/build.gradle.kts).
     *
     * <p>Returns the 16-char hex of the long seed. If reflection fails, returns
     * "unknown".</p>
     */
    private String dumpMathRandomSeed() {
        try {
            Class<?> holderClass = Class.forName("java.lang.Math$RandomNumberGeneratorHolder");
            Field genField = holderClass.getDeclaredField("randomNumberGenerator");
            genField.setAccessible(true);
            Random random = (Random) genField.get(null);
            Field seedField = Random.class.getDeclaredField("seed");
            seedField.setAccessible(true);
            AtomicLong seed = (AtomicLong) seedField.get(random);
            return String.format("%016x", seed.get());
        } catch (ReflectiveOperationException e) {
            return "error:" + e.getClass().getSimpleName();
        }
    }

    private static void appendHexLE(StringBuilder sb, int v) {
        sb.append(String.format("%02x", v & 0xff));
        sb.append(String.format("%02x", (v >> 8) & 0xff));
        sb.append(String.format("%02x", (v >> 16) & 0xff));
        sb.append(String.format("%02x", (v >> 24) & 0xff));
    }
}
