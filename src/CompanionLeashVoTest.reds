// =====================================================================================
//  CompanionLeash - VO spike  (TEMPORARY, delete after the experiment)
// =====================================================================================
//  Question: does Judy actually answer to the generic NPC voice-over events, or is her
//  bank empty for them? A missing VO fails SILENTLY - no error, no log - so this cannot
//  be settled from data. It has to be listened to.
//
//  What this does: every Interval() seconds it plays the next event in the list and
//  writes the name to the log first. Listen, note which numbers make a sound, and the
//  log gives you the name for each.
//
//  Uses GameObject.PlayVoiceOver directly rather than NpcHandle.Talk() on purpose:
//  Talk() also drives a facial reaction and a look-at, which would muddy whether the
//  AUDIO exists. This isolates the voice bank.
//
//  No NCA types are referenced here, so the file stays in global scope like the rest of
//  the policy layer.
// =====================================================================================

public class CompanionLeashVoTest {
    //  OFF: the CET panel (cet/CompanionLeashVO) has taken over manual testing.
    //  Set to true to run the timed sweep again.
    public static func Enabled()  -> Bool = false;
    // Seconds between attempts. Long enough to tell one line from the next by ear.
    public static func Interval() -> Float = 4.0;
    public static func Count()    -> Int32 = 20;

    //  Generic NPC voice-over events taken from vanilla script usage. These are the
    //  names PlayVoiceOver is actually called with elsewhere in the game, so they are
    //  real events - the open question is only whether Judy has recordings bound to them.
    //  ROUND 3 - the remainder of the vanilla catalogue, so the generic VO surface is
    //  mapped completely and no usable Judy line stays undiscovered.
    //
    //  CONFIRMED WORKING so far (heard, cross-checked against the log):
    //      greeting           "Hey V" / "Oh hey"
    //      stealth_restored   "Die haben wir abgeschuettelt"
    //      stealth_ended      "Da kommen sie" / "Achtung!"
    //      combat_ended       "Oh das wars, wir habens geschafft"
    //      coop_irritation    "Aaah!"
    //      coop_reports_kill  "Echt jetzt!?"
    //      sniper_warning     "Wo haben die nur diese Ausruestung her?"
    //
    //  CONFIRMED SILENT: danger, stlh_curious_grunt, stlh_call, enemy_warning,
    //      start_combat, crowd_combat, shove, fear_beg, hit_reaction_heavy,
    //      vo_any_damage_hit, turret/camera/drones/netrunner/mech/elite/heavy_warning
    //
    //  Note: "Sieh uns an, nicht tot zu kriegen" surfaced under BOTH stealth_restored
    //  and combat_ended, so events appear to share a line pool.
    //
    //  cpo_* is the family to watch here - after coop_* paid off, these look like the
    //  other half of the cooperative-NPC set.
    public static func NameAt(i: Int32) -> CName {
        if i == 0  { return n"attack_fragile_player_order"; }
        if i == 1  { return n"battlecry_curse"; }
        if i == 2  { return n"bump"; }
        if i == 3  { return n"combat_target_hit"; }
        if i == 4  { return n"cpo_armor_broken"; }
        if i == 5  { return n"cpo_got_data"; }
        if i == 6  { return n"cpo_nearly_dead"; }
        if i == 7  { return n"fear_run"; }
        if i == 8  { return n"grenade_throw"; }
        if i == 9  { return n"heavy_reloading"; }
        if i == 10 { return n"hit_grapple"; }
        if i == 11 { return n"hit_reaction_light"; }
        if i == 12 { return n"hmg_charge"; }
        if i == 13 { return n"octant_warning"; }
        if i == 14 { return n"pedestrian_hit"; }
        if i == 15 { return n"start_dead"; }
        if i == 16 { return n"stlh_death"; }
        if i == 17 { return n"vehicle_bump"; }
        if i == 18 { return n"following"; }
        if i == 19 { return n"waiting"; }
        return n"greeting";
    }

    public static func Tick(npc: wref<ScriptedPuppet>, who: String, deltaTime: Float,
                            state: ref<CompanionLeashState>) -> Void {
        if !CompanionLeashVoTest.Enabled() || !IsDefined(npc) {
            return;
        }

        state.voTimer -= deltaTime;
        if state.voTimer > 0.0 {
            return;
        }
        state.voTimer = CompanionLeashVoTest.Interval();

        let name: CName = CompanionLeashVoTest.NameAt(state.voIndex);

        // Logged BEFORE playing, so the log line and the sound line up in time.
        FTLog("[CompanionLeash] VO  " + who
            + " try #" + IntToString(state.voIndex)
            + " event=" + NameToString(name));

        GameObject.PlayVoiceOver(npc, name, n"CompanionLeashVoTest", 0.0, npc.GetEntityID(), true);

        state.voIndex += 1;
        if state.voIndex >= CompanionLeashVoTest.Count() {
            state.voIndex = 0;
        }
    }
}
