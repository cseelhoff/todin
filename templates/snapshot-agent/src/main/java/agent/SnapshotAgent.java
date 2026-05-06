package agent;

import net.bytebuddy.agent.builder.AgentBuilder;
import net.bytebuddy.asm.Advice;
import net.bytebuddy.matcher.ElementMatchers;

import java.io.IOException;
import java.lang.instrument.Instrumentation;
import java.nio.file.*;
import java.util.*;

/**
 * Java agent that instruments methods listed in jfr-methods.txt with a global
 * tick counter and conditional before/after GameData snapshots.
 *
 * Usage: -javaagent:snapshot-agent.jar=methods=path/to/jfr-methods.txt,rangeStart=100,rangeEnd=120,outDir=snapshots
 */
public class SnapshotAgent {

    public static void premain(String args, Instrumentation inst) {
        Map<String, String> config = parseArgs(args);

        String methodsFile = config.getOrDefault("methods", "jfr-methods.txt");
        long rangeStart = Long.parseLong(config.getOrDefault("rangeStart", "0"));
        long rangeEnd = Long.parseLong(config.getOrDefault("rangeEnd", "20"));
        String outDir = config.getOrDefault("outDir", "snapshots");

        // Store config in SnapshotInterceptor statics so the advice can read them
        SnapshotInterceptor.rangeStart = rangeStart;
        SnapshotInterceptor.rangeEnd = rangeEnd;
        SnapshotInterceptor.outputDir = outDir;

        // Load config file if provided (for filters, saveGameData, etc.)
        String configFile = config.getOrDefault("config", "");
        if (!configFile.isEmpty() && java.nio.file.Files.exists(java.nio.file.Path.of(configFile))) {
            SnapshotInterceptor.loadConfig(configFile);
        }

        // Command-line args override config file for outDir
        if (config.containsKey("outDir")) {
            SnapshotInterceptor.outputDir = outDir;
        }
        outDir = SnapshotInterceptor.outputDir;
        rangeStart = SnapshotInterceptor.rangeStart;
        rangeEnd = SnapshotInterceptor.rangeEnd;

        // Load layer assignments
        String layerDir = config.getOrDefault("layerDir", "");
        if (!layerDir.isEmpty()) {
            SnapshotInterceptor.loadLayers(layerDir);
        }

        try {
            Files.createDirectories(Path.of(outDir));
        } catch (IOException e) {
            System.err.println("[SnapshotAgent] Failed to create output dir: " + outDir);
        }

        // Load the methods list and build class/method matchers
        Set<String> targetClasses = new HashSet<>();
        Map<String, Set<String>> classToMethods = new HashMap<>();

        try {
            List<String> lines = Files.readAllLines(Path.of(methodsFile));
            for (String line : lines) {
                line = line.trim();
                if (line.isEmpty()) continue;
                int colon = line.lastIndexOf(':');
                String filePath = line.substring(0, colon);
                String methodSig = line.substring(colon + 1);
                String methodName = methodSig.substring(0, methodSig.indexOf('('));

                // Convert file path to class name: games/strategy/.../GameData.java -> games.strategy...GameData
                String className = filePath.replace(".java", "").replace('/', '.');

                targetClasses.add(className);
                classToMethods.computeIfAbsent(className, k -> new HashSet<>()).add(methodName);
            }
        } catch (IOException e) {
            System.err.println("[SnapshotAgent] Failed to load methods file: " + methodsFile);
            return;
        }

        // Store the method map for the advice to check
        SnapshotInterceptor.targetMethods = classToMethods;

        System.out.println("[SnapshotAgent] Loaded " + targetClasses.size() + " target classes");
        System.out.println("[SnapshotAgent] Tick range: " + rangeStart + " - " + rangeEnd);
        System.out.println("[SnapshotAgent] Output dir: " + outDir);

        // Install the agent using Byte Buddy
        // For each class, only instrument the specific methods from jfr-methods.txt
        for (var entry : classToMethods.entrySet()) {
            String className = entry.getKey();
            String[] methodNames = entry.getValue().toArray(new String[0]);
            new AgentBuilder.Default()
                    .disableClassFormatChanges()
                    .with(AgentBuilder.RedefinitionStrategy.RETRANSFORMATION)
                    .type(ElementMatchers.named(className))
                    .transform((builder, typeDescription, classLoader, module, protectionDomain) ->
                            builder.visit(
                                    Advice.to(SnapshotInterceptor.class)
                                            .on(ElementMatchers.isMethod()
                                                    .and(ElementMatchers.namedOneOf(methodNames)))
                            ))
                    .installOn(inst);
        }

        System.out.println("[SnapshotAgent] Instrumentation installed");
    }

    private static Map<String, String> parseArgs(String args) {
        Map<String, String> config = new HashMap<>();
        if (args == null || args.isEmpty()) return config;
        for (String pair : args.split(",")) {
            String[] kv = pair.split("=", 2);
            if (kv.length == 2) {
                config.put(kv[0].trim(), kv[1].trim());
            }
        }
        return config;
    }
}
