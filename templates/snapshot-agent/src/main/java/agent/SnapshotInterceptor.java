package agent;

import net.bytebuddy.asm.Advice;
import net.bytebuddy.implementation.bytecode.assign.Assigner;

import java.io.*;
import java.lang.reflect.Method;
import java.nio.file.*;
import java.util.*;

/**
 * Byte Buddy advice that:
 * 1. Increments GameData.snapshotTickCounter on every instrumented method entry
 * 2. If the tick is within [rangeStart, rangeEnd], snapshots GameData + params (before)
 *    and GameData + return value (after)
 *
 * This class uses static fields because Byte Buddy advice is inlined into the target
 * method bytecode — it cannot hold instance state.
 */
public class SnapshotInterceptor {

    // Configured by the agent at startup
    public static volatile long rangeStart = 0;
    public static volatile long rangeEnd = 20;
    public static volatile String outputDir = "snapshots";
    public static volatile Map<String, Set<String>> targetMethods = Map.of();

    // Filters — loaded from snapshot.config
    public static volatile Set<String> includeMethodSubstrings = Set.of();
    public static volatile Set<String> excludeMethodSubstrings = Set.of();
    public static volatile Set<String> includeClassSubstrings = Set.of();
    public static volatile Set<String> excludeClassSubstrings = Set.of();
    public static volatile Set<Integer> includeLayers = Set.of();
    public static volatile Set<Integer> excludeLayers = Set.of();
    public static volatile boolean saveGameData = false;
    public static volatile boolean saveParams = true;
    public static volatile boolean saveReturn = true;

    // Layer lookup: method signature -> layer number (loaded from layer files)
    public static volatile Map<String, Integer> methodToLayer = Map.of();

    // Safety caps — once exceeded, shouldSnapshot() returns false so no further
    // tick-* dirs are produced. Default caps are intentionally tight; raise
    // them via snapshot.config or -Dsnapshot.maxBytes / -Dsnapshot.maxMillis
    // when capturing big methods.
    public static volatile long maxBytes = 10L * 1024 * 1024;   // 10 MiB total
    public static volatile long maxMillis = 10L * 60 * 1000;    // 10 minutes wall clock
    public static volatile int  maxSnapshots = 100;             // hard count limit
    public static final java.util.concurrent.atomic.AtomicLong bytesWritten =
            new java.util.concurrent.atomic.AtomicLong(0);
    public static final java.util.concurrent.atomic.AtomicInteger snapshotsTaken =
            new java.util.concurrent.atomic.AtomicInteger(0);
    public static volatile long startMillis = 0;
    public static final java.util.concurrent.atomic.AtomicBoolean capExceeded =
            new java.util.concurrent.atomic.AtomicBoolean(false);

    /** Returns true once any cap has been hit. Logs once. */
    public static boolean capsExceeded() {
        if (capExceeded.get()) return true;
        if (startMillis == 0) startMillis = System.currentTimeMillis();
        long bytes = bytesWritten.get();
        long elapsed = System.currentTimeMillis() - startMillis;
        int taken = snapshotsTaken.get();
        String reason = null;
        if (bytes >= maxBytes) reason = "maxBytes=" + maxBytes + " (wrote " + bytes + ")";
        else if (elapsed >= maxMillis) reason = "maxMillis=" + maxMillis + " (elapsed " + elapsed + ")";
        else if (taken >= maxSnapshots) reason = "maxSnapshots=" + maxSnapshots + " (took " + taken + ")";
        if (reason != null && capExceeded.compareAndSet(false, true)) {
            System.err.println("[SnapshotAgent] CAP EXCEEDED: " + reason
                    + " — further snapshots will be skipped. Override via snapshot.maxBytes / snapshot.maxMillis / snapshot.maxSnapshots.");
            try {
                java.nio.file.Files.writeString(
                        java.nio.file.Path.of(outputDir, "CAP_EXCEEDED.txt"),
                        reason + "\n");
            } catch (Exception ignored) {}
        }
        return capExceeded.get();
    }

    /**
     * Called on method entry. Increments tick, and if in range, saves the "before" snapshot.
     * Returns the tick value so @Advice.Exit can use it.
     */
    // Cached counter reference (lazily initialized to avoid reflection on every call)
    public static final java.util.concurrent.atomic.AtomicLong COUNTER =
            new java.util.concurrent.atomic.AtomicLong(0);
    public static volatile Class<?> cachedGameDataClass = null;

    @Advice.OnMethodEnter
    public static long onEnter(
            @Advice.Origin String methodSignature,
            @Advice.AllArguments Object[] args,
            @Advice.This(optional = true, typing = Assigner.Typing.DYNAMIC) Object self) {
        try {
            long tick = COUNTER.incrementAndGet();

            if (tick >= rangeStart && tick <= rangeEnd
                    && !capsExceeded()
                    && shouldSnapshot(methodSignature)) {
                if (cachedGameDataClass == null) {
                    try {
                        cachedGameDataClass = Class.forName("games.strategy.engine.data.GameData");
                    } catch (Throwable ignored) {}
                }
                Object gameData = extractGameData(self);
                saveBeforeSnapshot(tick, methodSignature, args, cachedGameDataClass, gameData);
                snapshotsTaken.incrementAndGet();
            }

            return tick;
        } catch (Exception e) {
            // Silently ignore — don't break the game
            return -1;
        }
    }

    /**
     * Called on method exit. If the tick was in range, saves the "after" snapshot.
     */
    @Advice.OnMethodExit(onThrowable = Throwable.class)
    public static void onExit(
            @Advice.Enter long tick,
            @Advice.Origin String methodSignature,
              @Advice.Return(readOnly = true, typing = Assigner.Typing.DYNAMIC) Object returnValue,
            @Advice.Thrown Throwable thrown,
            @Advice.This(optional = true, typing = Assigner.Typing.DYNAMIC) Object self) {
        try {
            if (tick >= rangeStart && tick <= rangeEnd
                    && !capExceeded.get()
                    && shouldSnapshot(methodSignature)) {
                Object gameData = extractGameData(self);
                saveAfterSnapshot(tick, methodSignature, returnValue, thrown, cachedGameDataClass, gameData);
            }
        } catch (Exception e) {
            // Silently ignore
        }
    }

    public static void saveBeforeSnapshot(long tick, String methodSignature,
                                            Object[] args, Class<?> gameDataClass, Object gameData) {
        try {
            Path dir = Path.of(outputDir, "tick-" + String.format("%010d", tick));
            Files.createDirectories(dir);

            // Save metadata
            try (var out = new PrintWriter(Files.newBufferedWriter(dir.resolve("before-meta.txt")))) {
                out.println("tick: " + tick);
                out.println("method: " + methodSignature);
                out.println("timestamp: " + System.currentTimeMillis());
                out.println("params: " + (args != null ? args.length : 0));
                if (args != null) {
                    for (int i = 0; i < args.length; i++) {
                        Object arg = args[i];
                        out.println("  param[" + i + "]: "
                                + (arg != null ? arg.getClass().getSimpleName() : "null")
                                + " = " + summarize(arg));
                    }
                }
            }

            // Save GameData as JSON
            saveGameDataJson(dir.resolve("before-gamedata.json"), gameData);

            // Save params via Java serialization (best effort)
            if (saveParams && args != null) {
                for (int i = 0; i < args.length; i++) {
                    if (args[i] instanceof Serializable s) {
                        try (var oos = new ObjectOutputStream(
                                Files.newOutputStream(dir.resolve("before-param-" + i + ".bin")))) {
                            oos.writeObject(s);
                        } catch (Exception e) {
                            // Some params aren't serializable — skip
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.err.println("[SnapshotAgent] Error saving before snapshot at tick " + tick + ": " + e);
        }
    }

    public static void saveAfterSnapshot(long tick, String methodSignature,
                                           Object returnValue, Throwable thrown,
                                           Class<?> gameDataClass, Object gameData) {
        try {
            Path dir = Path.of(outputDir, "tick-" + String.format("%010d", tick));
            Files.createDirectories(dir);

            // Save metadata
            try (var out = new PrintWriter(Files.newBufferedWriter(dir.resolve("after-meta.txt")))) {
                out.println("tick: " + tick);
                out.println("tickAfter: " + COUNTER.get());
                out.println("method: " + methodSignature);
                out.println("timestamp: " + System.currentTimeMillis());
                if (thrown != null) {
                    out.println("thrown: " + thrown.getClass().getName() + ": " + thrown.getMessage());
                } else {
                    out.println("return: "
                            + (returnValue != null ? returnValue.getClass().getSimpleName() : "void")
                            + " = " + summarize(returnValue));
                }
            }

            // Save GameData as JSON
            saveGameDataJson(dir.resolve("after-gamedata.json"), gameData);

            // Save return value
            if (saveReturn && returnValue instanceof Serializable s) {
                try (var oos = new ObjectOutputStream(
                        Files.newOutputStream(dir.resolve("after-return.bin")))) {
                    oos.writeObject(s);
                } catch (Exception e) {
                    // skip
                }
            }
        } catch (Exception e) {
            System.err.println("[SnapshotAgent] Error saving after snapshot at tick " + tick + ": " + e);
        }
    }

    /**
     * Extracts the GameData from an object instance via reflection.
     * Works for ServerGame (has getData()), delegates (have bridge.getData()),
     * or any object with getData()/getGameData().
     * Returns null if extraction fails.
     */
    public static Object extractGameData(Object instance) {
        if (instance == null) return null;
        // Try getData() directly (ServerGame, AbstractGame)
        try {
            Method m = instance.getClass().getMethod("getData");
            return m.invoke(instance);
        } catch (Exception ignored) {}
        // Try getGameData()
        try {
            Method m = instance.getClass().getMethod("getGameData");
            return m.invoke(instance);
        } catch (Exception ignored) {}
        // Try bridge.getData() (delegates have a bridge field set by setDelegateBridgeAndPlayer)
        try {
            java.lang.reflect.Field bridgeField = findFieldInHierarchy(instance.getClass(), "bridge");
            if (bridgeField != null) {
                bridgeField.setAccessible(true);
                Object bridge = bridgeField.get(instance);
                if (bridge != null) {
                    Method m = bridge.getClass().getMethod("getData");
                    return m.invoke(bridge);
                }
            }
        } catch (Exception ignored) {}
        return null;
    }

    private static java.lang.reflect.Field findFieldInHierarchy(Class<?> clazz, String name) {
        while (clazz != null) {
            try {
                return clazz.getDeclaredField(name);
            } catch (NoSuchFieldException e) {
                clazz = clazz.getSuperclass();
            }
        }
        return null;
    }

    /**
     * Serializes GameData to JSON using GameStateJsonSerializer (loaded via reflection
     * since it's in the test classpath, not the agent's compile classpath).
     */
    public static void saveGameDataJson(Path file, Object gameData) {
        if (gameData == null) {
            try {
                Files.writeString(file, "{\"error\": \"GameData not available\"}");
            } catch (IOException ignored) {}
            return;
        }
        try {
            // Load GameStateJsonSerializer via reflection (it's in the test classpath)
            if (cachedSerializer == null) {
                Class<?> serializerClass = Class.forName(
                        "games.strategy.engine.data.GameStateJsonSerializer");
                cachedSerializer = serializerClass.getConstructor().newInstance();
                cachedSerializeMethod = serializerClass.getMethod("serialize",
                        Class.forName("games.strategy.engine.data.GameData"));
            }
            String json = (String) cachedSerializeMethod.invoke(cachedSerializer, gameData);
            Files.writeString(file, json);
            bytesWritten.addAndGet(json.length());
        } catch (Exception e) {
            try {
                Files.writeString(file, "{\"error\": \"" + e.getMessage().replace("\"", "'") + "\"}");
            } catch (IOException ignored) {}
        }
    }

    private static volatile Object cachedSerializer = null;
    private static volatile Method cachedSerializeMethod = null;

    public static String summarize(Object obj) {
        if (obj == null) return "null";
        try {
            String s = obj.toString();
            if (s.length() > 200) return s.substring(0, 200) + "...";
            return s;
        } catch (Exception e) {
            return obj.getClass().getSimpleName() + "@" + System.identityHashCode(obj);
        }
    }

    /**
     * Check if this method signature passes the include/exclude filters.
     * Returns true if the method should be snapshotted.
     */
    public static boolean shouldSnapshot(String methodSignature) {
        // Extract simple class name from signature like "public void games.strategy...ClassName.methodName(...)"
        String className = "";
        String methodName = "";
        try {
            // Parse "access type package.ClassName.methodName(params)"
            int lastDot = methodSignature.lastIndexOf('.');
            int parenStart = methodSignature.indexOf('(');
            if (lastDot >= 0 && parenStart > lastDot) {
                methodName = methodSignature.substring(lastDot + 1, parenStart);
            }
            // Class name is between last space before lastDot and lastDot
            String beforeMethod = methodSignature.substring(0, lastDot);
            int prevDot = beforeMethod.lastIndexOf('.');
            if (prevDot >= 0) {
                className = beforeMethod.substring(prevDot + 1);
            }
        } catch (Exception e) {
            // Can't parse — allow it
            return true;
        }

        // Exclude filters always win
        if (!excludeMethodSubstrings.isEmpty()) {
            for (String ex : excludeMethodSubstrings) {
                if (methodName.contains(ex) || methodSignature.contains(ex)) return false;
            }
        }
        if (!excludeClassSubstrings.isEmpty()) {
            for (String ex : excludeClassSubstrings) {
                if (className.contains(ex) || methodSignature.contains(ex)) return false;
            }
        }
        if (!excludeLayers.isEmpty()) {
            Integer layer = methodToLayer.get(normalizeSignatureForLayerLookup(methodSignature));
            if (layer != null && excludeLayers.contains(layer)) return false;
        }

        // Include filters: each non-empty filter must match (AND across filter
        // categories, OR within a category). Empty categories are skipped.
        if (!includeMethodSubstrings.isEmpty()) {
            boolean any = false;
            for (String inc : includeMethodSubstrings) {
                if (methodName.contains(inc)) { any = true; break; }
            }
            if (!any) return false;
        }
        if (!includeClassSubstrings.isEmpty()) {
            boolean any = false;
            for (String inc : includeClassSubstrings) {
                if (className.contains(inc)) { any = true; break; }
            }
            if (!any) return false;
        }
        if (!includeLayers.isEmpty()) {
            String normalizedKey = normalizeSignatureForLayerLookup(methodSignature);
            Integer layer = methodToLayer.get(normalizedKey);
            if (layer == null || !includeLayers.contains(layer)) return false;
        }
        return true;
    }

    /**
     * Normalize a Byte Buddy @Advice.Origin signature to match the layer file key format.
     * Input:  "public void games.strategy.engine.framework.ServerGame.runStep(boolean)"
     * Output: "games.strategy.engine.framework.ServerGame:runStep(boolean)"
     */
    public static String normalizeSignatureForLayerLookup(String sig) {
        try {
            int parenStart = sig.indexOf('(');
            int parenEnd = sig.lastIndexOf(')');
            if (parenStart < 0 || parenEnd < 0) return sig;

            String params = sig.substring(parenStart, parenEnd + 1);
            String beforeParen = sig.substring(0, parenStart);
            int lastDot = beforeParen.lastIndexOf('.');
            if (lastDot < 0) return sig;

            String methodName = beforeParen.substring(lastDot + 1);
            String fqcnWithPrefix = beforeParen.substring(0, lastDot);

            // Strip access modifiers and return type (everything before the last space)
            int lastSpace = fqcnWithPrefix.lastIndexOf(' ');
            String fqcn = lastSpace >= 0 ? fqcnWithPrefix.substring(lastSpace + 1) : fqcnWithPrefix;

            // Strip package prefixes from param types so "java.lang.String" matches "String"
            // and "games.strategy.engine.data.GamePlayer" matches "GamePlayer".
            String simplifiedParams = simplifyParamTypes(params);

            return fqcn + ":" + methodName + simplifiedParams;
        } catch (Exception e) {
            return sig;
        }
    }

    /**
     * Given a parenthesized parameter list like "(java.lang.String, games.strategy.engine.data.GamePlayer)",
     * return "(String, GamePlayer)". Preserves array brackets and nested-type '$'.
     */
    public static String simplifyParamTypes(String parens) {
        if (parens == null || parens.length() < 2) return parens;
        String inner = parens.substring(1, parens.length() - 1);
        if (inner.isEmpty()) return "()";
        String[] parts = inner.split(",");
        StringBuilder sb = new StringBuilder("(");
        for (int i = 0; i < parts.length; i++) {
            String p = parts[i].trim();
            // Preserve array suffix
            String suffix = "";
            while (p.endsWith("[]")) {
                suffix = "[]" + suffix;
                p = p.substring(0, p.length() - 2);
            }
            int dot = p.lastIndexOf('.');
            if (dot >= 0) p = p.substring(dot + 1);
            if (i > 0) sb.append(", ");
            sb.append(p).append(suffix);
        }
        sb.append(')');
        return sb.toString();
    }

    /**
     * Load configuration from a .config properties file.
     */
    public static void loadConfig(String configPath) {
        try {
            var props = new java.util.Properties();
            try (var in = java.nio.file.Files.newInputStream(java.nio.file.Path.of(configPath))) {
                props.load(in);
            }

            rangeStart = Long.parseLong(props.getProperty("snapshot.rangeStart", "0"));
            rangeEnd = Long.parseLong(props.getProperty("snapshot.rangeEnd", "20"));
            outputDir = props.getProperty("snapshot.outDir", "snapshots");
            saveGameData = Boolean.parseBoolean(props.getProperty("snapshot.saveGameData", "false"));
            saveParams = Boolean.parseBoolean(props.getProperty("snapshot.saveParams", "true"));
            saveReturn = Boolean.parseBoolean(props.getProperty("snapshot.saveReturn", "true"));

            includeMethodSubstrings = parseSet(props.getProperty("snapshot.include.methods", ""));
            excludeMethodSubstrings = parseSet(props.getProperty("snapshot.exclude.methods", ""));
            includeClassSubstrings = parseSet(props.getProperty("snapshot.include.classes", ""));
            excludeClassSubstrings = parseSet(props.getProperty("snapshot.exclude.classes", ""));
            includeLayers = parseIntSet(props.getProperty("snapshot.include.layers", ""));
            excludeLayers = parseIntSet(props.getProperty("snapshot.exclude.layers", ""));

            // Safety caps. -D system properties take precedence over the config file.
            maxBytes = Long.parseLong(System.getProperty("snapshot.maxBytes",
                    props.getProperty("snapshot.maxBytes", String.valueOf(maxBytes))));
            maxMillis = Long.parseLong(System.getProperty("snapshot.maxMillis",
                    props.getProperty("snapshot.maxMillis", String.valueOf(maxMillis))));
            maxSnapshots = Integer.parseInt(System.getProperty("snapshot.maxSnapshots",
                    props.getProperty("snapshot.maxSnapshots", String.valueOf(maxSnapshots))));
            startMillis = System.currentTimeMillis();

            System.out.println("[SnapshotInterceptor] Config loaded from " + configPath);
            System.out.println("[SnapshotInterceptor] Range: " + rangeStart + "-" + rangeEnd);
            if (!includeMethodSubstrings.isEmpty())
                System.out.println("[SnapshotInterceptor] Include methods: " + includeMethodSubstrings);
            if (!excludeMethodSubstrings.isEmpty())
                System.out.println("[SnapshotInterceptor] Exclude methods: " + excludeMethodSubstrings);
            if (!includeClassSubstrings.isEmpty())
                System.out.println("[SnapshotInterceptor] Include classes: " + includeClassSubstrings);
            if (!includeLayers.isEmpty())
                System.out.println("[SnapshotInterceptor] Include layers: " + includeLayers);
        } catch (Exception e) {
            System.err.println("[SnapshotInterceptor] Failed to load config: " + e);
        }
    }

    /**
     * Load layer assignments from the jfr-layer files.
     */
    public static void loadLayers(String layerDir) {
        Map<String, Integer> map = new HashMap<>();
        try {
            // Layer 00 = leaf
            java.nio.file.Path dir = java.nio.file.Path.of(layerDir);
            for (int layer = 0; layer <= 30; layer++) {
                String filename = String.format("jfr-layer%02d-methods.txt", layer);
                java.nio.file.Path file = dir.resolve(filename);
                if (java.nio.file.Files.exists(file)) {
                    for (String line : java.nio.file.Files.readAllLines(file)) {
                        line = line.trim();
                        if (!line.isEmpty()) {
                            // Normalize: "games/strategy/.../Class.java:method(params)"
                            // → "games.strategy...Class:method(params)"
                            String normalized = line.replace(".java:", ":").replace('/', '.');
                            map.put(normalized, layer);
                        }
                    }
                }
            }
            methodToLayer = map;
            System.out.println("[SnapshotInterceptor] Loaded " + map.size() + " method->layer mappings");
        } catch (Exception e) {
            System.err.println("[SnapshotInterceptor] Failed to load layers: " + e);
        }
    }

    private static Set<String> parseSet(String value) {
        if (value == null || value.isBlank()) return Set.of();
        Set<String> set = new HashSet<>();
        for (String s : value.split(",")) {
            s = s.trim();
            if (!s.isEmpty()) set.add(s);
        }
        return set;
    }

    private static Set<Integer> parseIntSet(String value) {
        if (value == null || value.isBlank()) return Set.of();
        Set<Integer> set = new HashSet<>();
        for (String s : value.split(",")) {
            s = s.trim();
            if (s.contains("-")) {
                String[] range = s.split("-");
                int from = Integer.parseInt(range[0].trim());
                int to = Integer.parseInt(range[1].trim());
                for (int i = from; i <= to; i++) set.add(i);
            } else if (!s.isEmpty()) {
                set.add(Integer.parseInt(s));
            }
        }
        return set;
    }
}
