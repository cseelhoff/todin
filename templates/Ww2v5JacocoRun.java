package org.triplea.portbootstrap;

import games.strategy.engine.data.GameTestUtils;
import games.strategy.engine.data.SnapshotHarness;
import games.strategy.engine.framework.ServerGame;
import games.strategy.engine.random.PlainRandomSource;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.io.IOException;

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

  /** Round cap for the snapshot run. Snapshots blow up quadratically; keep small. */
  private static final int SNAPSHOT_ROUNDS = 1;

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

      while (!game.isGameOver()) {
        if (game.getData().getSequence().getRound() > SNAPSHOT_ROUNDS) {
          break;
        }
        harness.wrapStep(() -> game.runNextStep());
      }
    } finally {
      // Don't leak the seed into other tests in the same JVM.
      PlainRandomSource.fixedSeed = null;
    }
  }
}
