package games.strategy.engine.data;

import games.strategy.engine.framework.ServerGame;

import java.io.*;
import java.nio.file.*;

/**
 * Wrapper harness for characterization testing. Captures full GameData as JSON
 * before/after each game step (layer 22: runNextStep).
 *
 * Lower layers are captured by the Byte Buddy snapshot agent configured via
 * snapshot.config and jfr-layer* files.
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
            }

            System.out.println("[SnapshotHarness] Saved " + label
                    + " step=" + stepName + " round=" + round);

        } catch (Exception e) {
            System.err.println("[SnapshotHarness] Error saving " + label + " at step "
                    + stepCounter + ": " + e);
            e.printStackTrace();
        }
    }
}
