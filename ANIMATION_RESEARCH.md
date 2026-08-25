# CompanionLeash — content research & opportunity map

Source data: AMM `db.sqlite3` (44,075 workspot animations), NCA source + its 31 CET content
modules, and the game's redscript dump. All numbers measured, not estimated.

---

## 1. The headline

```
Animations available on Judy's rig (Woman Average)   13,754
Animations NCA registers, all rigs combined             559
   ... of those, usable on her rig                       479
UNUSED and available for her                         13,275
```

NCA is a well-built framework using **3.5%** of the animation content its own system can
already drive. The gap is not a missing feature — it is unwritten content, and content is
the cheapest thing in this architecture (Lua module, auto-loaded, zero NCA edits, zero
re-merge cost).

---

## 2. Two-actor (synced) content

**4,664 synced animations. 154 bases pair as female companion + female V.**

Per-character libraries, all NCA-supported companions:

| Character | Anims | Distinct poses |
|---|---|---|
| Alt | 484 | 166 |
| River | 240 | 101 |
| SoMi | 138 | 101 |
| Johnny | 191 | 88 |
| Panam | 108 | 73 |
| **Judy** | **106** | **71** |
| Kerry | 94 | 61 |
| Songbird | 71 | 44 |
| Takemura | 64 | 31 |
| Jackie | 68 | 29 |
| Misty | 26 | 9 |
| Rogue | 24 | 15 |

**Judy's set is natively female-V** (`Woman Average` + `Player Woman`), and several halves
are explicitly named `_player_female`. NCA's own shipped synced routines use the *man*
player rig, so none of this is currently reachable in-game.

### Judy's 71 poses, by usable category

**Affection** — full pose systems with entry, in-pose variation, and exit:
```
transition_to_v_hug_judy__01..04   ->  v_hug_judy__01
                                        + talk__01..04, shrug__01..02,
                                          shrug__narrow__01, shuffle__01
                                   ->  v_judy_transition_out__01
transition_to_v_holds_judy__01     ->  v_holds_judy__01
                                        + hug__01, shuffle__01..02, talk__02, yes__01
out_hug_judy__01 (+ __player_female)
Judy_kisses_V_goodbye__01
judy_lies_on_v_lap__01             (male-V half only)
v_judy_final_goodbye_hug__01 / _no_hug__01
sq030_09_pier__V_hugs_Judy__01
```

**Greeting / arrival** — explicit female-player halves:
```
judy_greeting_apartment_judy / _player_female
judy_greeting_apartment_slow_turn__01_judy / _player_female
V_approach__01
```

**Emotional beats:**
```
Judy_comforts_V__01        judy_angry_getting_up__01
Judy_talks_about_chip__01..02
v_wakes_judy__01           q004__wake_up_after_yori_bd__01
```

**Ambient / vibing** — context-specific idles:
```
judy_vibes_on_pool_table__01     judy_vibes_to_music__01
judy_and_v_in_shower__01 (+ __long__01)
```

**Item exchange** — pairs with the gift mods already installed:
```
player_gives_judy_cigarette_case__01
player_takes_judy_cigarette_case__01
sq030_03_dam_equipment__judy_inserts_shard__01
```

**Rescue / physical assistance:**
```
sq030_09_pier__Judy_pulls_player_up__01
sq030_09_pier__Judy_CPRs_player__01
```

**Companion-to-companion** — proof that two *NPCs* can be synced, not just NPC+player:
```
judy_and_carol_conversation__01..04 (+ __carol halves)
judy_and_carol_notice_v__01 (+ __carol)
Judy__Maiko_Judy_interaction__01 / Maiko__Maiko_Judy_interaction__01
```

---

## 3. Solo content

| Family | Count | Use |
|---|---|---|
| `stand` | 11,114 | idles, leaning, waiting |
| `sit` | 8,576 | seated behaviour |
| `walk` | 1,027 | locomotion variation |
| `lie` | 750 | resting |
| `idle` | 695 | dedicated idle loops |
| `kneel` | 429 | stealth / crouch adjacent |
| `melee`, `aim` | 483 / 241 | combat presence |

**Crouch:** 41 on Judy's rig (`action_crouch`, `action___crouch_and_shoot`), 28 on
Player Woman.

**Judy's dive/swim moveset** confirmed: `dive_idle__01`, `dive_swim_0__idle__01`,
turn transitions (`dive_idle__01__to__dive_idle__01__turn180l__01`),
`swim__tube_sexy_dance__01`, `action___swim_01/02`.

---

## 4. Supporting systems

| System | Mechanism | Status |
|---|---|---|
| Routine registration | `NCA:RegisterRoutine(type, {...})`, CET Lua, auto-loaded | working, 21 types / ~60 routines today |
| Dual-pose surfacing | `NCABehavior.GetSyncedRoutines()` under `// Menu options`, resolves `NCA.Util().GetPlayerRig()` | **already wired — content-only to extend** |
| Solo routines | free-standing `dance` pattern: `tag` + `rig` + clips, no prop | working, 18 shipping |
| Pose alignment | `partnerOffsetForward` / `Right` / `Up` / `Yaw` in NCA's schema | available, needs per-pose tuning |
| Entry/exit effects | `effects = { exit = { {"love++"} } }` | working — poses can move relationship stats |
| Facial expression | `AnimFeature_FacialReaction{category: Int32, idle: Int32}` | **unexplored numeric axis**; NCA hardcodes 3 / 5 |
| Voice | `NpcHandle.Talk(vo, category, idle, upperBody)` — VO + face + look-at | public; Judy's bank coverage unverified |
| Locations | NCA location modules; Lizzie's already 261 lines | framework present, Judy's turf partly built |
| Player state | `PlayerStateMachine.Locomotion` blackboard listener | confirmed, NCA precedent |
| Event triggers | `EventBus.OnCombatStart/End`, `OnEnterLocation`, `OnCompanionTakeDamage`, … | 20+ hooks available |

NCA's Judy character module is **99 lines**, almost entirely dialogue keys
(`ask`, `join`, `yes`, `no`, `cool`, `nice`, `commute`). Her per-character content is
essentially a stub.

---

## 5. Opportunity tiers

### Tier 1 — pure content, zero code, zero re-merge cost
1. **Judy dual poses.** 71 poses; the hug/hold systems alone give a complete interaction
   with entry, variation and exit. Appears in her menu automatically.
2. **Solo idle library.** 13,275 unused animations on her rig.
3. **Location-aware idles.** NCA's location system exists; Lizzie's is her home turf.

### Tier 2 — content plus small policy in the existing 1 Hz path
4. **Contextual idle selection** — dive set near water, `judy_vibes_on_pool_table` at
   Lizzie's, `judy_vibes_to_music` where music plays.
5. **Item exchange poses** — cigarette-case animations pair with the gift mods installed.

### Tier 3 — event-driven code
6. **Stealth stance sync** (immediate, blackboard-driven).
7. **Voice reactions** on EventBus triggers.
8. **Facial expression modulation** — `category`/`idle` are raw ints nobody has mapped.

### Tier 4 — ambitious, built on the above
9. **Judy asks you** — she initiates a pose; needs prompt surface + decline path.
10. **Companion-to-companion interactions** — `judy_and_carol` proves two-NPC sync works.
11. **Emotional state model** — relationship/context drives which idles, poses, faces and
    lines are eligible. NCA already tracks `love`/`friendship` and routines can move them
    via exit effects, so the feedback loop is closed.

### Tier 5 — widening
12. Other companions: Panam 73, River 101, Kerry 61, SoMi 101, Johnny 88, Alt 166 poses.
13. The full 154-base female-V library beyond Judy.

---

## 6. What this changes about sequencing

Everything in Tier 1 is **content**, and content cannot break the compile, cannot conflict
with NCA's command ownership, and costs nothing when NCA updates. It is strictly safer than
anything we have shipped so far, and it is where the visible payoff is largest.

The riskiest item (mobile crouch) is the *only* one that needs a spike, and it is
independent of everything else. It should not gate the content work.
