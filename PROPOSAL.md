# CompanionLeash 0.3 — proposal: presence feature set

**Dev scope: Judy, female V.** Every feature gates on `NpcHandle.recordID` vs
`Character.Judy` until proven, then widens. This is not just caution — the research below
shows Judy's content is *specifically* authored for female V, so the pairing matters.

---

## 0. Research findings

All numbers come from AMM's `db.sqlite3` (44,075 workspot animations) and NCA's source.

| Finding | Number |
|---|---|
| Synced (two-actor) animations in the game | **4,664** |
| Bases pairable as **female companion + female V** | **154** |
| Judy-specific synced pairs | **24** |
| Judy-specific animations overall | 203 |
| Crouch animations, Woman Average rig | 41 |
| Crouch animations, Player Woman rig | 28 |

**The Judy dual poses are natively female-V.** Every half resolves as
`Woman Average` (Judy) + `Player Woman` (V):

```
synced__v_hug_judy__01__judy               Woman Average
synced__v_hug_judy__01__player             Player Woman
synced__v_holds_judy__01__judy             Woman Average
synced__v_holds_judy__01__player           Player Woman
```

Because Judy's romance is female-V-only, these were authored for exactly this pairing.
**NCA's own shipped synced routines use the man player rig** (`player_man_skeleton.rig`),
so this entire female-V set is currently unused by NCA.

**They form complete pose systems, not one-shots:**

```
synced__transition_to_v_hug_judy__01..04     entry transitions (4 variants)
synced__v_hug_judy__01                       the held pose
synced__v_hug_judy__talk__01..04             in-pose variation
synced__v_hug_judy__shrug__01..02
synced__v_hug_judy__shuffle__01
synced__v_judy_transition_out__01            exit
synced__Judy_kisses_V_goodbye__01            standalone beat
```

That maps **exactly** onto NCA's routine model: entry effects, a `group` of clips sharing a
pose, `GetRandomClip` for in-pose variation, and a linear playback option for transitions.

**Judy's moveset is as broad as you said.** Confirmed dive/swim set on her rig:
`dive_idle__01`, `dive_swim_0__idle__01`, plus turn transitions
(`dive_idle__01__to__dive_idle__01__turn180l__01`) and `swim__tube_sexy_dance__01`.

**Crouch animations exist** — `action_crouch` and `action___crouch_and_shoot` on
Woman Average, among 41. My earlier "crouch is the risky one" was wrong about *content*.
The remaining question is narrower and stated in §3.

---

## 1. The constraint that shapes the code

The behaviour tick is **~1 Hz** (`TimeListeners` → self-rescheduling `DelayCallback`,
`TickDelay() = 1.0`). Fine for a leash, wrong for stealth. So 0.3 uses two paths:

| Path | Cadence | Used for |
|---|---|---|
| Polled (existing bridge) | ~1 Hz | distance, gait, facing, idle timers |
| Event-driven (new) | immediate | stance sync, voice triggers |

Nothing that must feel responsive goes in the slow path.

---

## 2. Feature A — dual poses (**content-only, do this first**)

**This is the biggest finding: it needs no redscript at all.**

`NCABehavior` already exposes, under a literal `// Menu options` header:

```
public func GetSyncedRoutines() -> array<ref<NCARoutine>>
    -> NCA.Animation().GetSyncedRoutines(StandingType(), this.m_npcHandle.rig,
                                         NCA.Util().GetPlayerRig())
public func PlaySyncedRoutine(routine: ref<NCARoutine>) -> Bool
```

`GetPlayerRig()` resolves V's *actual* rig at runtime. So a routine registered with
`partnerRig` = the female player rig is matched automatically, appears in Judy's
interaction menu labelled by `routine.label`, and plays on selection.

**Deliverable:** one CET Lua module in `NightCityAllies/Modules/`, auto-loaded by
`LoadModules()`. No NCA edit, no bridge growth, zero re-merge cost.

Structure per pose, copying `nca_animation_synced_standing.lua`:

```lua
NCA:RegisterRoutine("standing", {
  tag = "hug_judy_f", rig = <woman_base>, partnerRig = <player_woman>,
  label = "Hug", icon = "ChoiceCaptionParts.None",
  playback = "random",
  animations = {
    { animation = "synced__v_hug_judy__01",          partnerAnimation = "...__player", duration = ?, group = "hug" },
    { animation = "synced__v_hug_judy__talk__01",    partnerAnimation = "...__player", duration = ?, group = "hug" },
    ...
  },
})
```

Only unknown is per-clip `duration`, and that is a lookup, not a guess: NCA already
carries 559 animations with durations, and the community DB (RED Modding wiki animation
list) publishes duration + rig + `.anims` path per entry.

**Scope:** 24 Judy pairs first. 154 female-V pairs exist for later widening.

---

## 3. Feature B — stealth stance sync

**Behaviour.** Player crouches → Judy crouches, and *keeps following*. Player stands →
she stands. Immediate, not next tick.

**Detection** (confirmed, with in-repo precedent): blackboard listener on
`PlayerStateMachine.Locomotion`, values `gamePSMLocomotionStates.Crouch` /
`CrouchSprint` / `CrouchDodge`. NCA registers listeners exactly this way in
`BlackboardListeners.reds`.

**The real open question is not whether Judy can crouch — it is whether she can crouch
*while walking under AI locomotion*.** Two paths:

1. `AnimFeature_Stance.SetStanceState(animStanceState.Crouch)` via
   `AnimationControllerComponent.ApplyFeature(n"Stance", feat)` — same mechanism NCA's
   `Talk()` uses for `AnimFeature_FacialReaction`. Would preserve movement. **No vanilla
   script sets this**, so there is no reference usage — hence a spike.
2. Play `action_crouch` as a routine — a proven path, but routines anchor the NPC to a
   workspot, so she would crouch *in place* and stop following.

Path 1 is what the feature actually wants. Path 2 is the fallback and is strictly worse
for stealth, since a stationary companion in a stealth approach is close to useless.

---

## 4. Feature C — idle animations

Free-standing routines, exactly like the 18 shipping `dance` routines: `tag` + `rig` +
clips, no workspot, no offsets, no prop. Content is another drop-in Lua module.

Trigger lives in the 1 Hz path — an idle timer at this cadence is fine.

**Coordination:** `StartRoutine` internally calls `CancelCommand()`, so it drops our follow
command. The policy must treat "routine running" as an explicit state and not re-issue a
follow while active, or the two fight once per second. Same single-writer discipline as the
leash, extended to animation.

Judy's dive set is a natural special case: idle animations that fit *where she is* rather
than one generic pool.

---

## 5. Feature D — voice lines and dialogue-triggered poses

**Base capability confirmed:** `NpcHandle.Talk(vo, category, idle, upperBody)` is public
and drives VO + facial reaction + look-at together, so a line lands as a performance.

**Open question:** vanilla VO names are generic NPC events (`greeting`,
`stlh_curious_grunt`, `stealth_restored`, `enemy_warning`). Whether **Judy has recordings
bound to them** is unknown — unique characters have their own banks. A missing VO fails
quietly rather than erroring, so this is an audibility spike, not a code review.

**"Judy asks you"** — the ambitious half. Base flow: an `EventBus` trigger (location
entered, combat ended, idle together) → cooldown check → `Talk()` a prompt line → offer the
pose as an interaction. The pose half is free once Feature A lands; the *asking* needs a
prompt surface and a consent/decline path, and should be designed only after A and D's
audibility are settled.

---

## 6. Architecture

```
NightCityAllies/Modules/                    <- pure content, zero re-merge cost
  nca_animation_judy_dualposes.lua            Feature A  (no code at all)
  nca_animation_companion_idle.lua            Feature C content

r6/scripts/CompanionLeash/                  <- pure policy, no NCA types, issues nothing
  CompanionLeashPolicy.reds       existing
  CompanionLeashCommands.reds     existing
  CompanionLeashStance.reds       new — locomotion -> stance mapping
  CompanionLeashIdle.reds         new — idle timing + routine selection
  CompanionLeashVoice.reds        new — trigger -> VO mapping + cooldowns
  CompanionLeashEvents.reds       new — ScriptableSystem: blackboard + EventBus owner

NCA FollowPlayerBehavior.reds               <- bridge, grows only where protected access is required
```

**Single-writer rule holds.** Policy stays pure. The bridge remains the only caller of
protected command methods. The event system may apply anim features and call public
`NpcHandle` methods but must **never** issue or cancel AI commands.

**Bias the work toward the top of that tree.** Content in Lua costs nothing at NCA update
time; bridge lines cost the most.

---

## 7. Risks

1. **Mobile crouch** — whether `AnimFeature_Stance` survives AI locomotion. Only genuine
   unknown left in the animation stack.
2. **Judy VO coverage for generic events** — silent failure mode, ear-testable only.
3. **Dual-pose durations** — a lookup, but a wrong value desyncs the two halves visibly.
4. **Routine vs leash contention** at 1 Hz — mitigated by explicit routine state.
5. **Pose alignment** — synced routines position both actors; `partnerOffsetForward` /
   `partnerOffsetYaw` exist in NCA's schema and will need tuning per pose.
6. **NCA updates** — content and policy carry zero cost; bridge lines carry all of it.

---

## 8. Phasing

| Phase | Deliverable | Why here |
|---|---|---|
| 1 | **Judy dual poses** (24 pairs, Lua only) | Zero code, zero re-merge cost, immediately visible. Proves the content pipeline end to end. |
| 2 | **Idle animations** | Same pipeline, adds only a 1 Hz trigger + routine state |
| 3 | **Crouch spike**, then stance sync if it holds | Isolated unknown; fallback path known |
| 4 | **Voice audibility spike**, then reactions | Cheap to falsify, gates D |
| 5 | Judy asks / dialogue-triggered poses | Needs 1 and 4 settled first |
| 6 | Widen from Judy to the 154-pair female-V library, then other companions | Per-character coverage confirmed |

Phase 1 replaces what I previously called Phase 0. The dual poses need no spike because
every mechanism they use is already running in NCA today — only the content is missing.

---

# Scope ab 0.4

Gestuft, in dieser Reihenfolge. Szenen kommen zuletzt, wenn der Rest solide laeuft.

## 1. Barks

Erledigt, was die Bestandsaufnahme angeht: 55 Zeilen aus `vset_judy.scene`, benannt,
vermessen, ueber den Quest-Voiceset-Knoten ohne Cooldown abrufbar. Offen ist nur die
Verdrahtung an die vorhandenen CompanionLeash-Ausloeser.

Naheliegende Zuordnungen aus der gemessenen Liste:

| Ausloeser | Zeile |
|---|---|
| Spieler haengt zurueck | `follow_me_1` "Was ist los? Hoer auf zu troedeln." |
| Ankunft beim Spieler | `return_answer` "Du bist zurueck." |
| Anrempeln (Crowding-Abbruch) | `bump_var_1` "Hey, pass auf ..." |
| Stealth wiederhergestellt | `stealth_restored_var_1` "Perfekt, die sehen uns nicht mehr." |
| Kampf vorbei | `combat_ended_var_1` "Oh, das war's. Wir haben's geschafft." |
| Spieler bei wenig HP | `player_fallback_var_3` "Alles okay? Schnauf mal kurz durch." |

## 2. Fake-Lipsync fuer Quest-Zeilen

Die 1104 Quest-Zeilen sind ueber Voicesets nicht erreichbar, ihr **Audio** aber sehr wohl -
per Audioware auf dem SFX-Bus. Was fehlt, ist die Mundbewegung, und die liefern die Barks:

* Quest-Zeile ueber Audioware abspielen (SFX-Bus, hoerbar)
* parallel stumme Barks ueber den Quest-Knoten (Dialog-Bus auf 0) fuer den Mund
* Untertitel der Quest-Zeile per `PropagateSubtitle`

**Die gemessenen Dauern machen das erst praktikabel.** Fuer eine Quest-Zeile der Laenge L
lassen sich Barks so kombinieren, dass ihre Summe L trifft - ein Rucksackproblem mit 54
Bausteinen zwischen 1.11 s und 3.46 s, Schnitt 2.06 s.

Und weil die Dauern **offline** bekannt sind, braucht es zur Laufzeit keine Erkennung mehr.
Das loest den Zielkonflikt, der uns lange aufgehalten hat: die Untertitel der Barks duerfen
vollstaendig unterdrueckt werden, sichtbar ist nur die Quest-Zeile.

Grenze, die zu pruefen ist: Mundbewegung und Silben passen nicht zueinander. Bei einer
Zwei-Sekunden-Reaktion faellt das kaum auf, bei einem langen Satz vermutlich schon.

## 3. Hocken und einfache Idle-Animationen

Erst ein **weitgehend zufaelliger Pool** mit wenigen Indikatoren, spaeter Umgebungsfaktoren.
Bewusst nicht andersherum: ein Pool laesst sich sofort testen, die Faktoren kommen dazu,
wenn er steht.

## 4. Spaeter: Szenen

Eigene Szenen mit aufwendigeren Animationen und den komplexen Quest-Zeilen. `vset_judy.scene`
zeigt die Struktur - Lipsync haengt an `lipsyncAnimSet` mit `femaleLipsyncAnimationName`.
Kein Raetsel mehr, aber Szenen-Authoring in WolvenKit und ein eigenes Projekt.

