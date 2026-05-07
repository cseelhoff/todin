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
import com.fasterxml.jackson.databind.module.SimpleModule;

import java.io.IOException;
import java.lang.reflect.Method;
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

    /** Identity hint method names tried in order; first non-null wins. */
    private static final String[] IDENTITY_HINT_METHODS = {
            "getName", "getId", "getKey", "getDisplayName"
    };

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
     * Pruned-type emitter. Always emits a compact stub:
     *   { "@class": "<fqcn>", "_name": "...", "_id": "..." }
     * Probe order: getName, getId, getKey, getDisplayName. All are optional;
     * absent ones are simply omitted. The Odin loader uses these hints to
     * locate the matching object inside the loaded Game_Data graph.
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
            gen.writeStartObject();
            gen.writeStringField("@class", value.getClass().getName());
            for (String probe : IDENTITY_HINT_METHODS) {
                Object hint = invokeNoArg(value, probe);
                if (hint != null) {
                    String key = "_" + probe.substring(3, 4).toLowerCase() + probe.substring(4);
                    gen.writeStringField(key, String.valueOf(hint));
                }
            }
            gen.writeEndObject();
        }

        private static Object invokeNoArg(Object target, String name) {
            try {
                Method m = target.getClass().getMethod(name);
                return m.invoke(target);
            } catch (Exception e) {
                return null;
            }
        }
    }
}
