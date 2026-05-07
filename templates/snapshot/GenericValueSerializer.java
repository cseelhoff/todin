package games.strategy.engine.data;

import com.fasterxml.jackson.annotation.JsonAutoDetect.Visibility;
import com.fasterxml.jackson.annotation.JsonIdentityInfo;
import com.fasterxml.jackson.annotation.JsonTypeInfo;
import com.fasterxml.jackson.annotation.ObjectIdGenerators;
import com.fasterxml.jackson.annotation.PropertyAccessor;
import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.JsonSerializer;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.ObjectMapper.DefaultTyping;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.jsontype.impl.LaissezFaireSubTypeValidator;
import com.fasterxml.jackson.databind.jsontype.TypeSerializer;
import com.fasterxml.jackson.databind.module.SimpleModule;

import java.io.IOException;
import java.util.Set;

/**
 * Generic, reflective JSON serializer for arbitrary method parameter and return
 * values captured by the snapshot agent. Goal: produce a structurally faithful
 * dump of any POJO graph WITHOUT per-type code, so newly-instrumented procs
 * "just work".
 *
 * Design:
 * - All non-public fields are visible (FIELD = ANY). Lombok getters are ignored
 *   to avoid double-emitting (we read state, not API).
 * - Concrete subtype information is preserved via DefaultTyping
 *   OBJECT_AND_NON_CONCRETE → Jackson emits an "@class" property whenever a
 *   declared field type is Object, an interface, or abstract. This is exactly
 *   what we need to distinguish e.g. which Battle_Step subtype filled a slot.
 * - Cycles are broken with @JsonIdentityInfo applied to every Object via mixin.
 *   First encounter dumps the full body with an "@id"; later refs collapse to
 *   {"@ref": N}. This is robust to arbitrary back-references.
 * - "Prune list" — types whose full state is already captured by the GameData
 *   side-channel (or whose graphs explode the dump) are emitted as compact
 *   identity hints: {"@class":"...","_name":"...","_id":"..."} so the Odin
 *   side can resolve the same object by looking it up in the loaded Game_Data.
 *
 * Loaded reflectively from the snapshot agent (no compile-time dependency).
 */
public class GenericValueSerializer {

    /**
     * Types that should NOT be dumped in full. They are emitted as identity
     * stubs because (a) their state is already serialized via
     * GameStateJsonSerializer in before/after-gamedata.json, and (b) their
     * graphs reach back into GameData and would explode without pruning.
     */
    private static final Set<String> PRUNE_TYPES = Set.of(
            "games.strategy.engine.data.GameData",
            "games.strategy.engine.data.GameMap",
            "games.strategy.engine.data.GameSequence",
            "games.strategy.engine.data.GameStep",
            "games.strategy.engine.data.Territory",
            "games.strategy.engine.data.Unit",
            "games.strategy.engine.data.GamePlayer",
            "games.strategy.engine.data.UnitType",
            "games.strategy.engine.data.Resource",
            "games.strategy.engine.data.RelationshipType",
            "games.strategy.engine.data.ProductionRule",
            "games.strategy.engine.data.ProductionFrontier",
            "games.strategy.engine.data.RepairRule",
            "games.strategy.engine.data.RepairFrontier",
            "games.strategy.engine.data.AllianceTracker",
            "games.strategy.engine.data.RelationshipTracker",
            "games.strategy.engine.data.PlayerList",
            "games.strategy.engine.data.UnitTypeList",
            "games.strategy.engine.data.ResourceList",
            "games.strategy.engine.data.ProductionRuleList",
            "games.strategy.engine.data.ProductionFrontierList",
            "games.strategy.engine.data.RepairRuleList",
            "games.strategy.engine.data.RepairFrontierList",
            "games.strategy.engine.data.RelationshipTypeList",
            "games.strategy.engine.data.TechnologyFrontier",
            "games.strategy.engine.data.TechnologyFrontierList",
            "games.strategy.engine.data.UnitCollection",
            "games.strategy.engine.data.ResourceCollection",
            "games.strategy.engine.data.properties.GameProperties",
            "games.strategy.triplea.attachments.TerritoryAttachment",
            "games.strategy.triplea.attachments.UnitAttachment",
            "games.strategy.triplea.attachments.UnitSupportAttachment",
            "games.strategy.triplea.attachments.TechAttachment",
            "games.strategy.triplea.attachments.TechAbilityAttachment",
            "games.strategy.triplea.attachments.CanalAttachment",
            "games.strategy.triplea.attachments.RulesAttachment",
            "games.strategy.triplea.attachments.RelationshipTypeAttachment",
            "games.strategy.triplea.attachments.PlayerAttachment",
            "games.strategy.triplea.delegate.TechAdvance",
            // BattleState / BattleActions are snapshot-method params; their
            // identity is unique within a tick (one active battle).
            "games.strategy.triplea.delegate.battle.BattleState",
            "games.strategy.triplea.delegate.battle.BattleActions",
            "games.strategy.triplea.delegate.battle.MustFightBattle",
            "games.strategy.triplea.delegate.battle.IBattle"
    );

    /**
     * How deep the structured-identity walk recurses through pruned-type
     * references. 2 = root expanded, one level of pruned references expanded
     * (so e.g. MustFightBattle.battleSite → Territory.name is reachable),
     * and pruned-type grandchildren collapse to {"@class":...}. Anything
     * deeper would re-walk the same back-reference cycles.
     */
    private static final int IDENTITY_MAX_DEPTH = 2;

    private final ObjectMapper mapper;

    public GenericValueSerializer() {
        ObjectMapper m = new ObjectMapper()
                .setVisibility(PropertyAccessor.ALL,    Visibility.NONE)
                .setVisibility(PropertyAccessor.FIELD,  Visibility.ANY)
                .activateDefaultTyping(
                        LaissezFaireSubTypeValidator.instance,
                        DefaultTyping.OBJECT_AND_NON_CONCRETE,
                        JsonTypeInfo.As.PROPERTY)
                .enable(SerializationFeature.INDENT_OUTPUT)
                .disable(SerializationFeature.FAIL_ON_EMPTY_BEANS)
                .disable(SerializationFeature.FAIL_ON_SELF_REFERENCES)
                .addMixIn(Object.class, IdentityMixin.class);

        SimpleModule prune = new SimpleModule("PruneTypes");
        for (String fqcn : PRUNE_TYPES) {
            try {
                Class<?> c = Class.forName(fqcn);
                prune.addSerializer(c, new IdentityHintSerializer(c));
            } catch (ClassNotFoundException ignored) {
                // Class may not be on the classpath in this build flavour.
            }
        }
        m.registerModule(prune);

        this.mapper = m;
    }

    /** Convenience for the agent's reflection path. Returns "null" for null. */
    public String serialize(Object value) throws Exception {
        if (value == null) return "null";
        return mapper.writeValueAsString(value);
    }

    /** @JsonIdentityInfo applied to every Object (cycle breaker). */
    @JsonIdentityInfo(generator = ObjectIdGenerators.IntSequenceGenerator.class,
                      property = "@id")
    abstract static class IdentityMixin {}

    /**
     * Pruned-type emitter. Walks the value's instance fields (including
     * inherited) and emits a structural identity stub:
     *   { "@class": "<fqcn>", "<field>": <value>, ... }
     * where each emitted field is one of: scalar (String / number / boolean /
     * char / enum.name() / UUID.toString()), nested pruned-type stub (recursive,
     * depth-capped at {@link #IDENTITY_MAX_DEPTH}), Collection / Map of those,
     * or Optional of those. Non-pruned object fields are silently skipped —
     * we only want identity, not arbitrary state. The Odin loader uses these
     * fields to locate the matching object inside the loaded Game_Data graph.
     */
    static final class IdentityHintSerializer<T> extends JsonSerializer<T> {
        private final Class<T> declaredType;

        IdentityHintSerializer(Class<T> declaredType) {
            this.declaredType = declaredType;
        }

        @Override
        public Class<T> handledType() { return declaredType; }

        @Override
        public void serialize(T value, JsonGenerator gen, SerializerProvider provider)
                throws IOException {
            writeIdentityStub(value, gen, 0);
        }

        // When default-typing engages, Jackson invokes serializeWithType
        // instead of serialize. We already write "@class" into the body, so
        // there is no separate type-id wrapper to emit — just delegate.
        @Override
        public void serializeWithType(T value, JsonGenerator gen,
                                      SerializerProvider provider,
                                      TypeSerializer typeSer) throws IOException {
            serialize(value, gen, provider);
        }

        private static void writeIdentityStub(Object value, JsonGenerator gen, int depth)
                throws IOException {
            gen.writeStartObject();
            gen.writeStringField("@class", value.getClass().getName());
            if (depth >= IDENTITY_MAX_DEPTH) {
                gen.writeEndObject();
                return;
            }
            Class<?> c = value.getClass();
            java.util.Set<String> seen = new java.util.HashSet<>();
            while (c != null && c != Object.class) {
                for (java.lang.reflect.Field f : c.getDeclaredFields()) {
                    int mods = f.getModifiers();
                    if (java.lang.reflect.Modifier.isStatic(mods)) continue;
                    if (f.isSynthetic()) continue;
                    // Always-skip fields: back-references that produce noise
                    // and add no identity value. `gameData` is the universal
                    // root back-pointer on every domain object.
                    if ("gameData".equals(f.getName())) continue;
                    if (!seen.add(f.getName())) continue;
                    try {
                        f.setAccessible(true);
                        Object fv = f.get(value);
                        if (fv == null) continue;
                        if (isEmptyContainer(fv)) continue;
                        writeFieldValue(f.getName(), fv, gen, depth + 1);
                    } catch (Exception ignored) {}
                }
                c = c.getSuperclass();
            }
            gen.writeEndObject();
        }

        private static boolean isEmptyContainer(Object v) {
            if (v instanceof java.util.Collection<?> col) return col.isEmpty();
            if (v instanceof java.util.Map<?, ?> map) return map.isEmpty();
            if (v.getClass().isArray()) return java.lang.reflect.Array.getLength(v) == 0;
            if (v instanceof java.util.Optional<?> opt) return opt.isEmpty();
            return false;
        }

        private static void writeFieldValue(String name, Object fv, JsonGenerator gen, int depth)
                throws IOException {
            if (isScalar(fv)) {
                gen.writeFieldName(name);
                writeScalar(fv, gen);
                return;
            }
            String cls = fv.getClass().getName();
            if (PRUNE_TYPES.contains(cls)) {
                gen.writeFieldName(name);
                writeIdentityStub(fv, gen, depth);
                return;
            }
            if (fv instanceof java.util.Optional<?> opt) {
                if (opt.isPresent()) writeFieldValue(name, opt.get(), gen, depth);
                return;
            }
            if (fv instanceof java.util.Collection<?> col) {
                gen.writeArrayFieldStart(name);
                for (Object e : col) writeArrayElement(e, gen, depth);
                gen.writeEndArray();
                return;
            }
            if (fv instanceof java.util.Map<?, ?> map) {
                gen.writeObjectFieldStart(name);
                for (java.util.Map.Entry<?, ?> entry : map.entrySet()) {
                    Object ek = entry.getKey();
                    Object ev = entry.getValue();
                    if (ev == null) continue;
                    String key = ek == null ? "null" : String.valueOf(ek);
                    writeFieldValue(key, ev, gen, depth);
                }
                gen.writeEndObject();
                return;
            }
            // Non-pruned object types: silently skip. We only want identity,
            // not arbitrary state.
        }

        private static void writeArrayElement(Object e, JsonGenerator gen, int depth)
                throws IOException {
            if (e == null) { gen.writeNull(); return; }
            if (isScalar(e)) { writeScalar(e, gen); return; }
            if (PRUNE_TYPES.contains(e.getClass().getName())) {
                writeIdentityStub(e, gen, depth);
                return;
            }
            // Skip non-pruned collection elements.
        }

        private static boolean isScalar(Object v) {
            return v instanceof String || v instanceof Number || v instanceof Boolean
                    || v instanceof Character || v instanceof Enum<?>
                    || v instanceof java.util.UUID;
        }

        private static void writeScalar(Object v, JsonGenerator gen) throws IOException {
            if (v instanceof String s)         gen.writeString(s);
            else if (v instanceof Boolean b)   gen.writeBoolean(b);
            else if (v instanceof Integer i)   gen.writeNumber(i);
            else if (v instanceof Long l)      gen.writeNumber(l);
            else if (v instanceof Double d)    gen.writeNumber(d);
            else if (v instanceof Float f)     gen.writeNumber(f);
            else if (v instanceof Short s)     gen.writeNumber(s);
            else if (v instanceof Byte b)      gen.writeNumber(b);
            else if (v instanceof java.math.BigDecimal bd) gen.writeNumber(bd);
            else if (v instanceof java.math.BigInteger bi) gen.writeNumber(bi);
            else if (v instanceof Number n)    gen.writeNumber(n.doubleValue());
            else if (v instanceof Character c) gen.writeString(String.valueOf(c));
            else if (v instanceof Enum<?> e)   gen.writeString(((Enum<?>) e).name());
            else if (v instanceof java.util.UUID u) gen.writeString(u.toString());
            else gen.writeNull();
        }
    }
}
