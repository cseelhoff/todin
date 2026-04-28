package games.strategy.engine.data;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonNull;
import com.google.gson.JsonObject;
import com.google.gson.JsonPrimitive;
import games.strategy.engine.data.properties.GameProperties;
import games.strategy.triplea.attachments.TerritoryAttachment;
import games.strategy.triplea.attachments.UnitAttachment;
import games.strategy.triplea.attachments.UnitSupportAttachment;
import games.strategy.triplea.attachments.TechAttachment;
import games.strategy.triplea.attachments.TechAbilityAttachment;
import games.strategy.triplea.attachments.CanalAttachment;
import games.strategy.triplea.attachments.RulesAttachment;
import games.strategy.triplea.attachments.RelationshipTypeAttachment;
import games.strategy.triplea.delegate.TechAdvance;
import java.io.Serializable;
import java.lang.reflect.Field;
import java.math.BigDecimal;
import java.util.*;

/**
 * Serializes the entire GameData object to JSON, covering all fields from state-audit.md.
 * The JSON is structured to be deserialized on the Odin side into the Game_Data struct.
 * All references are by name/id strings (flat, not nested object graphs).
 */
public class GameStateJsonSerializer {

    private final Gson gson = new GsonBuilder().setPrettyPrinting().create();

    public String serialize(GameData data) {
        JsonObject root = new JsonObject();
        root.addProperty("gameName", data.getGameName());
        root.addProperty("diceSides", data.getDiceSides());
        root.add("sequence", serializeSequence(data.getSequence()));
        root.add("players", serializePlayers(data.getPlayerList(), data));
        root.add("territories", serializeTerritories(data.getMap(), data));
        root.add("unitTypes", serializeUnitTypes(data.getUnitTypeList(), data));
        root.add("alliances", serializeAlliances(data.getAllianceTracker(), data));
        root.add("relationships", serializeRelationships(data.getRelationshipTracker(), data));
        root.add("properties", serializeProperties(data.getProperties()));
        root.add("resources", serializeResourceList(data.getResourceList()));
        root.add("productionRules", serializeProductionRules(data.getProductionRuleList()));
        root.add("productionFrontiers", serializeProductionFrontiers(data.getProductionFrontierList()));
        root.add("technologyFrontier", serializeTechFrontier(data.getTechnologyFrontier()));
        root.add("units", serializeAllUnits(data));
        root.add("relationshipTypes", serializeRelationshipTypes(data.getRelationshipTypeList()));
        return gson.toJson(root);
    }

    // ========================================================================
    // Sequence
    // ========================================================================

    private JsonObject serializeSequence(GameSequence seq) {
        JsonObject obj = new JsonObject();
        obj.addProperty("round", seq.getRound());
        obj.addProperty("stepIndex", seq.getStepIndex());
        JsonArray steps = new JsonArray();
        for (GameStep step : seq) {
            JsonObject s = new JsonObject();
            s.addProperty("name", step.getName());
            s.addProperty("displayName", step.getDisplayName());
            s.addProperty("delegateName", step.getDelegateName());
            s.addProperty("player", step.getPlayerId() != null ? step.getPlayerId().getName() : null);
            s.addProperty("maxRunCount", step.getMaxRunCount());
            steps.add(s);
        }
        obj.add("steps", steps);
        return obj;
    }

    // ========================================================================
    // Players
    // ========================================================================

    private JsonArray serializePlayers(PlayerList playerList, GameData data) {
        JsonArray arr = new JsonArray();
        for (GamePlayer p : playerList.getPlayers()) {
            if (p == null) continue;
            JsonObject obj = new JsonObject();
            obj.addProperty("name", p.getName());
            obj.addProperty("optional", p.getOptional());
            obj.addProperty("canBeDisabled", p.getCanBeDisabled());
            obj.addProperty("isDisabled", p.getIsDisabled());
            obj.addProperty("whoAmI", p.getWhoAmI());
            obj.add("resources", serializeResourceCollection(p.getResources()));
            obj.addProperty("productionFrontier",
                    p.getProductionFrontier() != null ? p.getProductionFrontier().getName() : null);
            try { obj.add("techAttachment", serializeTechAttachment(p.getTechAttachment())); } catch (Exception e) { obj.add("techAttachment", com.google.gson.JsonNull.INSTANCE); }
            arr.add(obj);
        }
        return arr;
    }

    private JsonObject serializeResourceCollection(ResourceCollection rc) {
        JsonObject obj = new JsonObject();
        if (rc != null) {
            for (Resource r : rc.getResourcesCopy().keySet()) {
                obj.addProperty(r.getName(), rc.getQuantity(r));
            }
        }
        return obj;
    }

    private JsonObject serializeTechAttachment(TechAttachment ta) {
        if (ta == null) return null;
        JsonObject obj = new JsonObject();
        obj.addProperty("techCost", ta.getTechCost());
        obj.addProperty("heavyBomber", ta.getHeavyBomber());
        obj.addProperty("longRangeAir", ta.getLongRangeAir());
        obj.addProperty("jetPower", ta.getJetPower());
        obj.addProperty("rocket", ta.getRocket());
        obj.addProperty("industrialTechnology", ta.getIndustrialTechnology());
        obj.addProperty("superSub", ta.getSuperSub());
        obj.addProperty("destroyerBombard", ta.getDestroyerBombard());
        obj.addProperty("improvedArtillerySupport", ta.getImprovedArtillerySupport());
        obj.addProperty("paratroopers", ta.getParatroopers());
        obj.addProperty("increasedFactoryProduction", ta.getIncreasedFactoryProduction());
        obj.addProperty("warBonds", ta.getWarBonds());
        obj.addProperty("mechanizedInfantry", ta.getMechanizedInfantry());
        obj.addProperty("aaRadar", ta.getAaRadar());
        obj.addProperty("shipyards", ta.getShipyards());
        JsonObject genericTech = new JsonObject();
        for (var entry : ta.getGenericTech().entrySet()) {
            genericTech.addProperty(entry.getKey(), entry.getValue());
        }
        obj.add("genericTech", genericTech);
        return obj;
    }

    // ========================================================================
    // Territories
    // ========================================================================

    private JsonArray serializeTerritories(GameMap map, GameData data) {
        JsonArray arr = new JsonArray();
        for (Territory t : map.getTerritories()) {
            JsonObject obj = new JsonObject();
            obj.addProperty("name", t.getName());
            obj.addProperty("water", t.isWater());
            obj.addProperty("owner", t.getOwner() != null ? t.getOwner().getName() : null);

            // Units in territory — list of unit IDs
            JsonArray unitIds = new JsonArray();
            for (Unit u : t.getUnitCollection().getUnits()) {
                unitIds.add(u.getId().toString());
            }
            obj.add("units", unitIds);

            // Neighbors
            JsonArray neighbors = new JsonArray();
            for (Territory n : map.getNeighbors(t)) {
                neighbors.add(n.getName());
            }
            obj.add("neighbors", neighbors);

            // Territory attachment
            TerritoryAttachment.get(t).ifPresent(ta -> {
                JsonObject taObj = new JsonObject();
                taObj.addProperty("production", ta.getProduction());
                taObj.addProperty("unitProduction", ta.getUnitProduction());
                taObj.addProperty("victoryCity", ta.getVictoryCity());
                ta.getCapital().ifPresent(cap -> taObj.addProperty("capital", cap));
                taObj.addProperty("isImpassable", ta.getIsImpassable());
                taObj.addProperty("convoyRoute", ta.getConvoyRoute());
                taObj.addProperty("navalBase", ta.getNavalBase());
                taObj.addProperty("airBase", ta.getAirBase());
                taObj.addProperty("kamikazeZone", ta.getKamikazeZone());
                ta.getOriginalOwner().ifPresent(oo ->
                    taObj.addProperty("originalOwner", oo.getName()));
                obj.add("territoryAttachment", taObj);
            });

            arr.add(obj);
        }
        return arr;
    }

    // ========================================================================
    // Units — every unit with all 25 mutable fields
    // ========================================================================

    private JsonArray serializeAllUnits(GameData data) {
        JsonArray arr = new JsonArray();
        for (Unit u : data.getUnits().getUnits()) {
            arr.add(serializeUnit(u));
        }
        return arr;
    }

    private JsonObject serializeUnit(Unit u) {
        JsonObject obj = new JsonObject();
        obj.addProperty("id", u.getId().toString());
        obj.addProperty("type", u.getType().getName());
        obj.addProperty("owner", u.getOwner() != null ? u.getOwner().getName() : null);
        obj.addProperty("hits", u.getHits());
        obj.addProperty("transportedBy", u.getTransportedBy() != null ? u.getTransportedBy().getId().toString() : null);
        JsonArray unloaded = new JsonArray();
        for (Unit ul : u.getUnloaded()) {
            unloaded.add(ul.getId().toString());
        }
        obj.add("unloaded", unloaded);
        obj.addProperty("wasLoadedThisTurn", u.getWasLoadedThisTurn());
        obj.addProperty("unloadedTo", u.getUnloadedTo() != null ? u.getUnloadedTo().getName() : null);
        obj.addProperty("wasUnloadedInCombatPhase", u.getWasUnloadedInCombatPhase());
        obj.addProperty("alreadyMoved", u.getAlreadyMoved().doubleValue());
        obj.addProperty("bonusMovement", u.getBonusMovement());
        obj.addProperty("unitDamage", u.getUnitDamage());
        obj.addProperty("submerged", u.getSubmerged());
        obj.addProperty("originalOwner", u.getOriginalOwner() != null ? u.getOriginalOwner().getName() : null);
        obj.addProperty("wasInCombat", u.getWasInCombat());
        obj.addProperty("wasLoadedAfterCombat", u.getWasLoadedAfterCombat());
        obj.addProperty("wasAmphibious", u.getWasAmphibious());
        obj.addProperty("originatedFrom", u.getOriginatedFrom() != null ? u.getOriginatedFrom().getName() : null);
        obj.addProperty("wasScrambled", u.getWasScrambled());
        obj.addProperty("maxScrambleCount", u.getMaxScrambleCount());
        obj.addProperty("wasInAirBattle", u.getWasInAirBattle());
        obj.addProperty("disabled", u.getDisabled());
        obj.addProperty("launched", u.getLaunched());
        obj.addProperty("airborne", u.getAirborne());
        obj.addProperty("chargedFlatFuelCost", u.getChargedFlatFuelCost());
        return obj;
    }

    // ========================================================================
    // Unit Types with full UnitAttachment
    // ========================================================================

    private JsonArray serializeUnitTypes(UnitTypeList utl, GameData data) {
        // Get first player for tech-dependent getters (fallback: null catches handled)
        GamePlayer anyPlayer = data.getPlayerList().getPlayers().isEmpty()
                ? null : data.getPlayerList().getPlayers().get(0);
        JsonArray arr = new JsonArray();
        for (UnitType ut : utl.getAllUnitTypes()) {
            JsonObject obj = new JsonObject();
            obj.addProperty("name", ut.getName());
            UnitAttachment ua = ut.getUnitAttachment();
            if (ua != null) {
                obj.add("unitAttachment", serializeUnitAttachment(ua, anyPlayer));
            }
            arr.add(obj);
        }
        return arr;
    }

    private JsonObject serializeUnitAttachment(UnitAttachment ua, GamePlayer player) {
        // Use reflection for ALL fields to get raw base values without tech bonuses / NPE risk
        JsonObject obj = new JsonObject();
        obj.addProperty("isAir", getBoolField(ua, "isAir"));
        obj.addProperty("isSea", getBoolField(ua, "isSea"));
        obj.addProperty("movement", getIntField(ua, "movement"));
        obj.addProperty("canBlitz", getBoolField(ua, "canBlitz"));
        obj.addProperty("isKamikaze", getBoolField(ua, "isKamikaze"));
        obj.addProperty("canNotMoveDuringCombatMove", getBoolField(ua, "canNotMoveDuringCombatMove"));
        obj.addProperty("attack", getIntField(ua, "attack"));
        obj.addProperty("defense", getIntField(ua, "defense"));
        obj.addProperty("attackRolls", getIntField(ua, "attackRolls"));
        obj.addProperty("defenseRolls", getIntField(ua, "defenseRolls"));
        obj.addProperty("hitPoints", getIntField(ua, "hitPoints"));
        obj.addProperty("isInfrastructure", getBoolField(ua, "isInfrastructure"));
        obj.addProperty("canBombard", getBoolField(ua, "canBombard"));
        obj.addProperty("bombard", getIntField(ua, "bombard"));
        obj.addProperty("artillery", getBoolField(ua, "artillery"));
        obj.addProperty("artillerySupportable", getBoolField(ua, "artillerySupportable"));
        obj.addProperty("isMarine", getIntField(ua, "isMarine"));
        obj.addProperty("isSuicideOnAttack", getBoolField(ua, "isSuicideOnAttack"));
        obj.addProperty("isSuicideOnDefense", getBoolField(ua, "isSuicideOnDefense"));
        obj.addProperty("isSuicideOnHit", getBoolField(ua, "isSuicideOnHit"));
        obj.addProperty("chooseBestRoll", getBoolField(ua, "chooseBestRoll"));
        obj.addProperty("canEvade", getBoolField(ua, "canEvade"));
        obj.addProperty("isFirstStrike", getBoolField(ua, "isFirstStrike"));
        obj.addProperty("canMoveThroughEnemies", getBoolField(ua, "canMoveThroughEnemies"));
        obj.addProperty("canBeMovedThroughByEnemies", getBoolField(ua, "canBeMovedThroughByEnemies"));
        obj.addProperty("isDestroyer", getBoolField(ua, "isDestroyer"));
        obj.addProperty("isSub", getBoolField(ua, "isSub"));
        obj.addProperty("isCombatTransport", getBoolField(ua, "isCombatTransport"));
        obj.addProperty("transportCapacity", getIntField(ua, "transportCapacity"));
        obj.addProperty("transportCost", getIntField(ua, "transportCost"));
        obj.addProperty("carrierCapacity", getIntField(ua, "carrierCapacity"));
        obj.addProperty("carrierCost", getIntField(ua, "carrierCost"));
        obj.addProperty("isAirTransport", getBoolField(ua, "isAirTransport"));
        obj.addProperty("isAirTransportable", getBoolField(ua, "isAirTransportable"));
        obj.addProperty("isLandTransport", getBoolField(ua, "isLandTransport"));
        obj.addProperty("isLandTransportable", getBoolField(ua, "isLandTransportable"));
        obj.addProperty("isAaForCombatOnly", getBoolField(ua, "isAaForCombatOnly"));
        obj.addProperty("isAaForBombingThisUnitOnly", getBoolField(ua, "isAaForBombingThisUnitOnly"));
        obj.addProperty("isAaForFlyOverOnly", getBoolField(ua, "isAaForFlyOverOnly"));
        obj.addProperty("isRocket", getBoolField(ua, "isRocket"));
        obj.addProperty("attackAa", getIntField(ua, "attackAa"));
        obj.addProperty("offensiveAttackAa", getIntField(ua, "offensiveAttackAa"));
        obj.addProperty("attackAaMaxDieSides", getIntField(ua, "attackAaMaxDieSides"));
        obj.addProperty("offensiveAttackAaMaxDieSides", getIntField(ua, "offensiveAttackAaMaxDieSides"));
        obj.addProperty("maxAaAttacks", getIntField(ua, "maxAaAttacks"));
        obj.addProperty("maxRoundsAa", getIntField(ua, "maxRoundsAa"));
        obj.addProperty("typeAa", getStringField(ua, "typeAa"));
        obj.addProperty("mayOverStackAa", getBoolField(ua, "mayOverStackAa"));
        obj.addProperty("damageableAa", getBoolField(ua, "damageableAa"));
        obj.addProperty("isStrategicBomber", getBoolField(ua, "isStrategicBomber"));
        obj.addProperty("bombingMaxDieSides", getIntField(ua, "bombingMaxDieSides"));
        obj.addProperty("bombingBonus", getIntField(ua, "bombingBonus"));
        obj.addProperty("canIntercept", getBoolField(ua, "canIntercept"));
        obj.addProperty("canEscort", getBoolField(ua, "canEscort"));
        obj.addProperty("canAirBattle", getBoolField(ua, "canAirBattle"));
        obj.addProperty("airDefense", getIntField(ua, "airDefense"));
        obj.addProperty("airAttack", getIntField(ua, "airAttack"));
        obj.addProperty("canProduceUnits", getBoolField(ua, "canProduceUnits"));
        obj.addProperty("canProduceXUnits", getIntField(ua, "canProduceXUnits"));
        obj.addProperty("canBeDamaged", getBoolField(ua, "canBeDamaged"));
        obj.addProperty("maxDamage", getIntField(ua, "maxDamage"));
        obj.addProperty("maxOperationalDamage", getIntField(ua, "maxOperationalDamage"));
        obj.addProperty("canDieFromReachingMaxDamage", getBoolField(ua, "canDieFromReachingMaxDamage"));
        obj.addProperty("isConstruction", getBoolField(ua, "isConstruction"));
        obj.addProperty("constructionType", getStringField(ua, "constructionType"));
        obj.addProperty("constructionsPerTerrPerTypePerTurn", getIntField(ua, "constructionsPerTerrPerTypePerTurn"));
        obj.addProperty("maxConstructionsPerTypePerTerr", getIntField(ua, "maxConstructionsPerTypePerTerr"));
        obj.addProperty("tuv", getIntField(ua, "tuv"));
        obj.addProperty("whenCapturedSustainsDamage", getIntField(ua, "whenCapturedSustainsDamage"));
        return obj;
    }

    // ========================================================================
    // Alliances
    // ========================================================================

    private JsonObject serializeAlliances(AllianceTracker tracker, GameData data) {
        JsonObject obj = new JsonObject();
        for (String alliance : tracker.getAlliances()) {
            JsonArray players = new JsonArray();
            for (GamePlayer p : tracker.getPlayersInAlliance(alliance)) {
                players.add(p.getName());
            }
            obj.add(alliance, players);
        }
        return obj;
    }

    // ========================================================================
    // Relationships
    // ========================================================================

    private JsonArray serializeRelationships(RelationshipTracker tracker, GameData data) {
        JsonArray arr = new JsonArray();
        List<GamePlayer> players = data.getPlayerList().getPlayers();
        for (int i = 0; i < players.size(); i++) {
            for (int j = i + 1; j < players.size(); j++) {
                GamePlayer p1 = players.get(i);
                GamePlayer p2 = players.get(j);
                RelationshipTracker.Relationship rel = tracker.getRelationship(p1, p2);
                if (rel != null) {
                    JsonObject obj = new JsonObject();
                    obj.addProperty("player1", p1.getName());
                    obj.addProperty("player2", p2.getName());
                    obj.addProperty("type", rel.getRelationshipType().getName());
                    obj.addProperty("roundCreated", rel.getRoundCreated());
                    arr.add(obj);
                }
            }
        }
        return arr;
    }

    // ========================================================================
    // Relationship Types
    // ========================================================================

    private JsonArray serializeRelationshipTypes(RelationshipTypeList rtl) {
        JsonArray arr = new JsonArray();
        for (RelationshipType rt : rtl.getAllRelationshipTypes()) {
            JsonObject obj = new JsonObject();
            obj.addProperty("name", rt.getName());
            arr.add(obj);
        }
        return arr;
    }

    // ========================================================================
    // Properties
    // ========================================================================

    private JsonObject serializeProperties(GameProperties props) {
        JsonObject obj = new JsonObject();
        JsonObject constants = new JsonObject();
        for (var entry : props.getConstantPropertiesByName().entrySet()) {
            constants.add(entry.getKey(), serializePropertyValue(entry.getValue()));
        }
        obj.add("constants", constants);
        JsonObject editables = new JsonObject();
        for (var entry : props.getEditablePropertiesByName().entrySet()) {
            var ep = entry.getValue();
            JsonObject epObj = new JsonObject();
            epObj.addProperty("name", ep.getName());
            epObj.add("value", serializePropertyValue(ep.getValue()));
            editables.add(entry.getKey(), epObj);
        }
        obj.add("editables", editables);
        return obj;
    }

    private JsonElement serializePropertyValue(Object value) {
        if (value == null) return JsonNull.INSTANCE;
        if (value instanceof Boolean b) return new JsonPrimitive(b);
        if (value instanceof Number n) return new JsonPrimitive(n);
        if (value instanceof String s) return new JsonPrimitive(s);
        return new JsonPrimitive(value.toString());
    }

    // ========================================================================
    // Resources
    // ========================================================================

    private JsonArray serializeResourceList(ResourceList rl) {
        JsonArray arr = new JsonArray();
        for (Resource r : rl.getResources()) {
            arr.add(r.getName());
        }
        return arr;
    }

    // ========================================================================
    // Production
    // ========================================================================

    private JsonArray serializeProductionRules(ProductionRuleList prl) {
        JsonArray arr = new JsonArray();
        for (ProductionRule rule : prl.getProductionRules()) {
            JsonObject obj = new JsonObject();
            obj.addProperty("name", rule.getName());
            JsonObject costs = new JsonObject();
            for (var entry : rule.getCosts().entrySet()) {
                costs.addProperty(entry.getKey().getName(), entry.getValue());
            }
            obj.add("costs", costs);
            JsonObject results = new JsonObject();
            for (var entry : rule.getResults().entrySet()) {
                results.addProperty(entry.getKey().getName(), entry.getValue());
            }
            obj.add("results", results);
            arr.add(obj);
        }
        return arr;
    }

    private JsonArray serializeProductionFrontiers(ProductionFrontierList pfl) {
        JsonArray arr = new JsonArray();
        for (String name : pfl.getProductionFrontierNames()) {
            ProductionFrontier pf = pfl.getProductionFrontier(name);
            JsonObject obj = new JsonObject();
            obj.addProperty("name", pf.getName());
            JsonArray rules = new JsonArray();
            for (ProductionRule r : pf.getRules()) {
                rules.add(r.getName());
            }
            obj.add("rules", rules);
            arr.add(obj);
        }
        return arr;
    }

    // ========================================================================
    // Technology
    // ========================================================================

    private JsonObject serializeTechFrontier(TechnologyFrontier tf) {
        if (tf == null) return null;
        JsonObject obj = new JsonObject();
        obj.addProperty("name", tf.getName());
        JsonArray techs = new JsonArray();
        for (TechAdvance ta : tf.getTechs()) {
            techs.add(ta.getName());
        }
        obj.add("techs", techs);
        return obj;
    }

    // ========================================================================
    // Reflection helpers for accessing private raw fields
    // ========================================================================

    private static int getIntField(Object obj, String fieldName) {
        try {
            Field f = findField(obj.getClass(), fieldName);
            f.setAccessible(true);
            return f.getInt(obj);
        } catch (Exception e) {
            return 0;
        }
    }

    private static boolean getBoolField(Object obj, String fieldName) {
        try {
            Field f = findField(obj.getClass(), fieldName);
            f.setAccessible(true);
            return f.getBoolean(obj);
        } catch (Exception e) {
            return false;
        }
    }

    private static String getStringField(Object obj, String fieldName) {
        try {
            Field f = findField(obj.getClass(), fieldName);
            f.setAccessible(true);
            Object val = f.get(obj);
            return val != null ? val.toString() : null;
        } catch (Exception e) {
            return null;
        }
    }

    private static Field findField(Class<?> clazz, String name) throws NoSuchFieldException {
        while (clazz != null) {
            try {
                return clazz.getDeclaredField(name);
            } catch (NoSuchFieldException e) {
                clazz = clazz.getSuperclass();
            }
        }
        throw new NoSuchFieldException(name);
    }
}
