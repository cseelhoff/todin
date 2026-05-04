package game

Casualty_Util :: struct {}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.casualty.CasualtyUtil

// Java: static int CasualtyUtil.getTotalHitpointsLeft(Collection<Unit>)
casualty_util_get_total_hitpoints_left :: proc(units: [dynamic]^Unit) -> i32 {
    if units == nil || len(units) == 0 {
        return 0
    }
    total_hit_points: i32 = 0
    for u in units {
        ua := unit_get_unit_attachment(u)
        if !unit_attachment_is_infrastructure(ua) {
            total_hit_points += unit_attachment_get_hit_points(ua)
            total_hit_points -= unit_get_hits(u)
        }
    }
    return total_hit_points
}

