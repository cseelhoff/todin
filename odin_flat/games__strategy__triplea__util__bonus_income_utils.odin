package game

import "core:fmt"
import "core:math"
import "core:strings"

// Java owners covered by this file:
//   - games.strategy.triplea.util.BonusIncomeUtils

Bonus_Income_Utils :: struct {}

// Java: BonusIncomeUtils#addBonusIncome(IntegerMap<Resource>, IDelegateBridge, GamePlayer).
// Adds bonus income to the player based on the configured income-percentage
// game property (and a PU-specific bonus property for the "PUs" resource),
// emits a history event for each resource that changes, queues the resource
// change with the bridge, and returns an HTML-fragment summary of every
// per-resource line. Constants.PUS resolves to the literal "PUs".
bonus_income_utils_add_bonus_income :: proc(
	income: ^Integer_Map,
	bridge: ^I_Delegate_Bridge,
	player: ^Game_Player,
) -> string {
	sb := strings.builder_make()
	keys := integer_map_key_set(income)
	defer delete(keys)
	for raw_key in keys {
		resource := cast(^Resource)raw_key
		amount := integer_map_get_int(income, raw_key)
		data := i_delegate_bridge_get_data(bridge)
		props := game_data_get_properties(data)
		income_percent := properties_get_income_percentage(player, props)
		pu_income_bonus: i32 = 0
		if resource.named.base.name == "PUs" {
			pu_income_bonus = properties_get_pu_income_bonus(player, props)
		}
		// Java: (int) Math.round(((double) amount * (double) (incomePercent - 100) / 100)) + puIncomeBonus
		// Math.round(double) == (long) Math.floor(d + 0.5) — use floor(x + 0.5)
		// to match Java's half-up rounding rather than Odin's half-away-from-zero.
		ratio := f64(amount) * f64(income_percent - 100) / 100.0
		bonus_income := i32(math.floor(ratio + 0.5)) + pu_income_bonus
		if bonus_income == 0 {
			continue
		}
		total := resource_collection_get_quantity(
			game_player_get_resources(player),
			resource,
		) + bonus_income

		// Build the message exactly as Java does, including the "&" placeholder
		// trick used to drop the PU-bonus segment when income% == 100.
		mb := strings.builder_make()
		defer strings.builder_destroy(&mb)
		strings.write_string(&mb, "Giving ")
		strings.write_string(&mb, player.named.base.name)
		if pu_income_bonus > 0 {
			pu_str := fmt.aprintf(" %d PUs &", pu_income_bonus)
			strings.write_string(&mb, pu_str)
			delete(pu_str)
		}
		if income_percent != 100 {
			pct_str := fmt.aprintf(" %d%% income for %d ", income_percent, bonus_income)
			strings.write_string(&mb, pct_str)
			delete(pct_str)
		}
		message: string
		if income_percent == 100 {
			cleaned, was_alloc := strings.replace_all(strings.to_string(mb), "&", "")
			if was_alloc {
				message = cleaned
			} else {
				message = strings.clone(cleaned)
			}
		} else {
			message = strings.clone(strings.to_string(mb))
		}
		tail := fmt.aprintf(
			"%s; end with %d %s",
			resource.named.base.name,
			total,
			resource.named.base.name,
		)
		full := strings.concatenate({message, tail})
		delete(message)
		delete(tail)

		i_delegate_history_writer_start_event(
			i_delegate_bridge_get_history_writer(bridge),
			full,
		)
		i_delegate_bridge_add_change(
			bridge,
			change_factory_change_resources_change(player, resource, bonus_income),
		)
		strings.write_string(&sb, full)
		strings.write_string(&sb, "<br />")
		delete(full)
	}
	return strings.to_string(sb)
}

