package org.triplea.portbootstrap;

import games.strategy.engine.data.GameData;
import games.strategy.engine.data.GamePlayer;
import games.strategy.engine.data.GameStateJsonSerializer;
import games.strategy.engine.data.GameStep;
import games.strategy.engine.data.GameTestUtils;
import games.strategy.engine.data.SnapshotHarness;
import games.strategy.engine.data.Territory;
import games.strategy.engine.data.Unit;
import games.strategy.engine.framework.ServerGame;
import games.strategy.engine.random.PlainRandomSource;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.lang.reflect.Field;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.TreeMap;

/**
 * triplea-port-bootstrap test driver.
 *
 * <p>Two modes, selected at runtime by Gradle test selectors:
 *
 * <ul>
 *   <li>{@link #run()} &mdash; 8-round AI-vs-AI game on
 *       {@code WW2v5_1942_2nd.xml}, default RNG. Used as the JaCoCo
 *       coverage trace by the bootstrap pipeline.
 *   <li>{@link #runWithSnapshots()} &mdash; 1-round AI-vs-AI game on the
 *       same map with {@code PlainRandomSource.fixedSeed = 42L}, wrapped
 *       in {@link SnapshotHarness} which dumps full {@code GameData} JSON
 *       before and after each delegate step. Used as the
 *       Java-side reference oracle for Odin port validation.
 * </ul>
 *
 * <p>This file is dropped into the smoke-testing module by
 * {@code scripts/patch_triplea.py}. It depends only on classes that
 * exist in upstream TripleA plus the snapshot harness sources that
 * the same script copies in alongside it.
 */
public class Ww2v5JacocoRun {

  /** Round cap for the JaCoCo run. Replaced at patch time. */
  private static final int MAX_ROUNDS = __ROUND_CAP__;

  /** Default round cap for the snapshot run. Override with -Dsnapshot.rounds=N. */
  private static final int SNAPSHOT_ROUNDS_DEFAULT = 2;

  /** Deterministic seed for the snapshot run. */
  private static final long SNAPSHOT_SEED = 42L;

  @BeforeAll
  public static void setUp() throws IOException {
    GameTestUtils.setUp();
  }

  @Test
  void run() {
    ServerGame game =
        GameTestUtils.setUpGameWithAis("WW2v5_1942_2nd.xml");
    game.setStopGameOnDelegateExecutionStop(true);
    while (!game.isGameOver()) {
      if (game.getData().getSequence().getRound() > MAX_ROUNDS) {
        break;
      }
      game.runNextStep();
    }
  }

  @Test
  void runWithSnapshots() {
    // Must be set BEFORE setUpGameWithAis so the game's PlainRandomSource picks
    // up the seed at construction.
    PlainRandomSource.fixedSeed = SNAPSHOT_SEED;
    // Seed Math.random() too. The Pro AI uses Math.random() for weighted
    // purchase picks, casualty selection, and political-action choice
    // (see ProPurchaseUtils.randomizePurchaseOption + AbstractAi). Without
    // this, snapshots are statistically unreproducible across JVM runs and
    // the Odin port can never byte-match. Requires the
    // --add-opens java.base/java.lang=ALL-UNNAMED JVM arg, set by
    // smoke-testing/build.gradle.kts.
    seedMathRandom(SNAPSHOT_SEED);
    try {
      ServerGame game =
          GameTestUtils.setUpGameWithAis("WW2v5_1942_2nd.xml");
      game.setStopGameOnDelegateExecutionStop(true);

      String outDir =
          System.getProperty("snapshot.outDir", "build/snapshots");
      long rangeStart = Long.getLong("snapshot.rangeStart", 1);
      long rangeEnd = Long.getLong("snapshot.rangeEnd", Long.MAX_VALUE);

      SnapshotHarness harness =
          new SnapshotHarness(game, outDir, rangeStart, rangeEnd);

      int rounds = Integer.getInteger("snapshot.rounds", SNAPSHOT_ROUNDS_DEFAULT);
      while (!game.isGameOver()) {
        if (game.getData().getSequence().getRound() > rounds) {
          break;
        }
        harness.wrapStep(() -> game.runNextStep());
      }
    } finally {
      // Don't leak the seed into other tests in the same JVM.
      PlainRandomSource.fixedSeed = null;
    }
  }

  /**
   * Determinism probe: run a full WW2v5 game (capped at -Dgame.rounds, default 100)
   * with seeded RNG, then write the final GameData JSON to -Dgame.outFile (default
   * /tmp/ww2v5-final.json). Run this twice and diff the two output files; if Java
   * is fully deterministic the diff should be empty.
   *
   * <p>Invocation:
   * <pre>
   *   ./gradlew :game-app:smoke-testing:test \
   *     --tests 'org.triplea.portbootstrap.Ww2v5JacocoRun.runFullGameDeterminismProbe' \
   *     --rerun -Dgame.rounds=100 -Dgame.outFile=/tmp/ww2v5-A.json
   * </pre>
   */
  @Test
  void runFullGameDeterminismProbe() {
    PlainRandomSource.fixedSeed = SNAPSHOT_SEED;
    seedMathRandom(SNAPSHOT_SEED);
    try {
      ServerGame game =
          GameTestUtils.setUpGameWithAis("WW2v5_1942_2nd.xml");
      game.setStopGameOnDelegateExecutionStop(true);

      int maxRounds = Integer.getInteger("game.rounds", 100);
      boolean digest = Boolean.getBoolean("digest");
      while (!game.isGameOver()) {
        if (game.getData().getSequence().getRound() > maxRounds) {
          break;
        }
        if (digest) emitDigest(game.getData());
        game.runNextStep();
      }

      String outFile = System.getProperty("game.outFile", "/tmp/ww2v5-final.json");
      String json = new GameStateJsonSerializer().serialize(game.getData());
      try {
        Files.writeString(Path.of(outFile), json);
      } catch (IOException e) {
        throw new RuntimeException("Failed to write " + outFile, e);
      }
      System.err.println("[Ww2v5JacocoRun] Final state written to " + outFile
          + " (round=" + game.getData().getSequence().getRound()
          + ", isGameOver=" + game.isGameOver() + ")");
    } finally {
      PlainRandomSource.fixedSeed = null;
    }
  }

  /**
   * Seeds the JVM-global {@code java.lang.Math$RandomNumberGeneratorHolder.randomNumberGenerator}
   * to the given value. Throws {@link RuntimeException} if reflective access is denied
   * (run with {@code --add-opens java.base/java.lang=ALL-UNNAMED}).
   */
  /**
   * Per-step state digest. Mirrors `test_full_game_digest_emit` in
   * `odin_flat/test_full_game_digest.odin`. Emit ONE line BEFORE each
   * runNextStep so a unified diff of Java vs Odin digest streams
   * pinpoints the first divergent step.
   */
  private static void emitDigest(GameData data) {
    int round = data.getSequence().getRound();
    int idx = data.getSequence().getStepIndex();
    GameStep step;
    try { step = data.getSequence().getStep(idx); } catch (RuntimeException e) { step = null; }
    String stepName = step == null ? "" : step.getName();
    GamePlayer stepPlayer = step == null ? null : step.getPlayerId();
    String playerName = stepPlayer == null ? "-" : stepPlayer.getName();

    // Sorted player list.
    List<GamePlayer> players = new ArrayList<>(data.getPlayerList().getPlayers());
    players.sort((a, b) -> a.getName().compareTo(b.getName()));

    StringBuilder pus = new StringBuilder();
    boolean first = true;
    for (GamePlayer gp : players) {
      if (!first) pus.append(',');
      first = false;
      pus.append(gp.getName()).append(':').append(gp.getResources().getQuantity("PUs"));
    }

    // Sorted territories.
    List<Territory> terrs = new ArrayList<>(data.getMap().getTerritories());
    terrs.sort((a, b) -> a.getName().compareTo(b.getName()));

    StringBuilder ownerPairs = new StringBuilder();
    StringBuilder ucPairs = new StringBuilder();
    StringBuilder compPairs = new StringBuilder();
    Map<String, Integer> ownerCount = new TreeMap<>();
    int totalUnits = 0;
    for (Territory t : terrs) {
      String owner = t.getOwner() == null ? "-" : t.getOwner().getName();
      int uc = t.getUnitCollection().size();
      totalUnits += uc;
      ownerCount.merge(owner, 1, Integer::sum);
      ownerPairs.append(t.getName()).append('=').append(owner).append('|');
      ucPairs.append(t.getName()).append('=').append(uc).append('|');
      Map<String, Integer> compCounts = new TreeMap<>();
      for (Unit u : t.getUnitCollection().getUnits()) {
        String oo = u.getOwner() == null ? "-" : u.getOwner().getName();
        String tn = u.getType() == null ? "?" : u.getType().getName();
        compCounts.merge(oo + "_" + tn, 1, Integer::sum);
      }
      compPairs.append(t.getName()).append('=');
      for (Map.Entry<String, Integer> ce : compCounts.entrySet()) {
        compPairs.append(ce.getKey()).append(':').append(ce.getValue()).append(',');
      }
      compPairs.append('|');
    }
    long ownerH = fnv1a64(ownerPairs.toString());
    long ucH = fnv1a64(ucPairs.toString());
    long compH = fnv1a64(compPairs.toString());

    StringBuilder terr = new StringBuilder();
    first = true;
    for (Map.Entry<String, Integer> e : ownerCount.entrySet()) {
      if (!first) terr.append(',');
      first = false;
      terr.append(e.getKey()).append(':').append(e.getValue());
    }

    System.out.printf(
        "DIGEST r=%d i=%d step=%s player=%s PUs=[%s] terr=[%s] units=%d owner_h=%016x uc_h=%016x comp_h=%016x%n",
        round, idx, stepName, playerName, pus, terr, totalUnits, ownerH, ucH, compH);

    // Detailed per-territory dump for one specific (round, step), keyed
    // by -Ddigest.detail.r=R -Ddigest.detail.i=I.
    int dr = Integer.getInteger("digest.detail.r", -1);
    int di = Integer.getInteger("digest.detail.i", -1);
    if (round == dr && idx == di) {
      for (Territory t : terrs) {
        String owner = t.getOwner() == null ? "-" : t.getOwner().getName();
        Map<String, Integer> typeCount = new TreeMap<>();
        for (Unit u : t.getUnitCollection().getUnits()) {
          String oo = u.getOwner() == null ? "-" : u.getOwner().getName();
          String tn = u.getType() == null ? "?" : u.getType().getName();
          typeCount.merge(oo + "_" + tn, 1, Integer::sum);
        }
        StringBuilder tb = new StringBuilder();
        boolean f = true;
        for (Map.Entry<String,Integer> e : typeCount.entrySet()) {
          if (!f) tb.append(',');
          f = false;
          tb.append(e.getKey()).append(':').append(e.getValue());
        }
        System.out.printf("DETAIL r=%d i=%d terr=%s owner=%s units=%d types=[%s]%n",
            round, idx, t.getName(), owner, t.getUnitCollection().size(), tb);
      }
    }
  }

  private static long fnv1a64(String s) {
    long h = 0xcbf29ce484222325L;
    for (int i = 0; i < s.length(); i++) {
      h ^= (s.charAt(i) & 0xff);
      h *= 0x100000001b3L;
    }
    return h;
  }

  private static void seedMathRandom(long seed) {
    try {
      Class<?> holder = Class.forName("java.lang.Math$RandomNumberGeneratorHolder");
      Field f = holder.getDeclaredField("randomNumberGenerator");
      f.setAccessible(true);
      ((Random) f.get(null)).setSeed(seed);
    } catch (ReflectiveOperationException e) {
      throw new RuntimeException(
          "Cannot seed Math.random(); add `--add-opens java.base/java.lang=ALL-UNNAMED`", e);
    }
  }
}
