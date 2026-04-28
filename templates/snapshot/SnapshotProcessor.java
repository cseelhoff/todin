package games.strategy.engine.data;

import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.stream.*;

/**
 * Processes snapshot directories from SnapshotHarness and organizes them into
 * per-proc test directories for Odin unit testing.
 *
 * Input:  build/snapshots/{method_name}/step-NNNN-round-RRR-stepName/
 *         Each step dir has: step-before-gamedata.json, step-after-gamedata.json, metadata
 *
 * Output: conversion/odin_tests/{method_name}/snapshots/{NNNN}/before.json, after.json
 *         Plus auto-generated Odin test file if missing.
 *
 * Run via: java -cp ... games.strategy.engine.data.SnapshotProcessor [inputDir] [outputDir]
 */
public class SnapshotProcessor {

    private final Path snapshotInputDir;
    private final Path odinTestOutputDir;

    public SnapshotProcessor(Path snapshotInputDir, Path odinTestOutputDir) {
        this.snapshotInputDir = snapshotInputDir;
        this.odinTestOutputDir = odinTestOutputDir;
    }

    /**
     * Process all method-level snapshot directories.
     * The harness creates: {inputDir}/{methodName}/step-NNNN-round-RRR-stepName/
     * We produce:          {outputDir}/{methodName}/snapshots/{NNNN}/before.json + after.json
     */
    public int process() throws IOException {
        if (!Files.isDirectory(snapshotInputDir)) {
            System.err.println("[SnapshotProcessor] Input dir does not exist: " + snapshotInputDir);
            return 0;
        }

        int totalCount = 0;

        // Iterate over method-level subdirectories (e.g. server_game_run_next_step/)
        try (var methodDirs = Files.list(snapshotInputDir)) {
            for (Path methodDir : methodDirs.sorted().collect(Collectors.toList())) {
                if (!Files.isDirectory(methodDir)) continue;
                String methodName = methodDir.getFileName().toString();
                int count = processMethodDir(methodDir, methodName);
                totalCount += count;
            }
        }

        return totalCount;
    }

    private int processMethodDir(Path methodDir, String methodName) throws IOException {
        Map<Integer, Path> stepDirs = new TreeMap<>();
        try (var stream = Files.list(methodDir)) {
            for (Path dir : stream.sorted().collect(Collectors.toList())) {
                String name = dir.getFileName().toString();
                if (name.startsWith("step-") && Files.isDirectory(dir)) {
                    try {
                        int stepNum = Integer.parseInt(name.substring(5, 9));
                        stepDirs.put(stepNum, dir);
                    } catch (NumberFormatException e) {
                        // skip
                    }
                }
            }
        }

        Path procDir = odinTestOutputDir.resolve(methodName);
        Path procSnapshotsDir = procDir.resolve("snapshots");
        Files.createDirectories(procSnapshotsDir);

        int count = 0;
        for (var entry : stepDirs.entrySet()) {
            int stepNum = entry.getKey();
            Path stepDir = entry.getValue();

            Path beforeJson = stepDir.resolve("step-before-gamedata.json");
            Path afterJson = stepDir.resolve("step-after-gamedata.json");

            if (!Files.exists(beforeJson) || !Files.exists(afterJson)) continue;

            String snapshotId = String.format("%04d", stepNum);
            Path snapshotDir = procSnapshotsDir.resolve(snapshotId);
            Files.createDirectories(snapshotDir);

            Files.copy(beforeJson, snapshotDir.resolve("before.json"), StandardCopyOption.REPLACE_EXISTING);
            Files.copy(afterJson, snapshotDir.resolve("after.json"), StandardCopyOption.REPLACE_EXISTING);

            for (String metaName : List.of("step-before-meta.txt", "step-after-meta.txt")) {
                Path meta = stepDir.resolve(metaName);
                String outName = metaName.replace("step-before-", "before-").replace("step-after-", "after-");
                if (Files.exists(meta)) {
                    Files.copy(meta, snapshotDir.resolve(outName), StandardCopyOption.REPLACE_EXISTING);
                }
            }

            count++;
        }

        System.out.println("[SnapshotProcessor] " + methodName + ": " + count + " snapshot pairs");

        // Generate Odin test file if it doesn't exist
        Path odinTestFile = procDir.resolve("test_" + methodName + ".odin");
        if (!Files.exists(odinTestFile)) {
            generateOdinTestFile(odinTestFile, methodName);
        }

        return count;
    }

    private void generateOdinTestFile(Path outputFile, String procName) throws IOException {
        String snapshotPath = "conversion/odin_tests/" + procName + "/snapshots";

        String content = """
                package test_%s

                import "core:testing"
                import game "../../odin_flat"
                import tc "../test_common"

                @(test)
                test_all_snapshots :: proc(t: ^testing.T) {
                    tc.run_snapshot_tests(t,
                        "%s",
                        game.%s)
                }
                """.formatted(procName, snapshotPath, procName);

        Files.writeString(outputFile, content);
        System.out.println("[SnapshotProcessor] Generated Odin test: " + outputFile);
    }

    public static void main(String[] args) throws IOException {
        Path input = args.length > 0 ? Path.of(args[0]) : Path.of("game-app/smoke-testing/build/snapshots");
        Path output = args.length > 1 ? Path.of(args[1]) : Path.of("conversion/odin_tests");
        new SnapshotProcessor(input, output).process();
    }
}
