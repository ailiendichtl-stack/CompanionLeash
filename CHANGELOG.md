# Changelog

## Unreleased

### Added: Judy hockt mit  (`gamedataNPCHighLevelState`)
V geht in die Hocke, Judy geht mit - und folgt dabei weiter. Aufstehen bringt sie zurueck.

Der Schalter ist die **Lage**, nicht die Haltung:
`NPCPuppet.ChangeHighLevelState(judy, Stealth)` gibt die tiefe Hocke,
`Relaxed` den Rueckweg. `Alerted` und `Combat` geben ein gebeugtes, wachsames Laufen.

Gemessen und dadurch geklaert, warum die Haltung allein nie reichen konnte: der gesetzte
Wert kommt an und bleibt fuenfzehn Sekunden unangetastet liegen - in `Relaxed` hat ihr Graph
keine Hocke, in die er wechseln koennte. Umgekehrt faellt der Haltungswert nach `Stealth`
binnen zwei Sekunden von selbst auf `Stand` zurueck, und sie hockt weiter. Die Pose haengt
an der Lage. Darum ist `Stand` in der Stealth-Lage auch kein Rueckweg.

**Korrektur zu 0.3:** der dort notierte Befund, die Replikation lehne das Setzen ab, war
falsch. Vier Wege setzen den Zustand sauber, zwei geben `true` zurueck. Der Fehler lag in
der Ebene, nicht im Weg. Der ganze Vorgang steht in `PRESENCE_PLAN.md` Abschnitt 3.

Im Kampf wird die Lage nicht angefasst - sie setzt dort selbst `Combat` und sucht Deckung.
Wir geben beim Kampfbeginn ab und uebernehmen beim Kampfende wieder. Aufgefrischt wird nur
die Hocke, alle 3 s.

`moveMovementType` kennt nur Walk/Run/Sprint/Strafe/Stand - eine Schleich-Gangart fuers
Folge-Kommando gibt es nicht, der Weg ist geschlossen.

### Changed: erstes Hallo haengt am Blick statt an der Uhr
Statt einer festen Wartezeit nach dem Laden kommt die Begruessung 200 ms nachdem der Blick
sie zum ersten Mal erkannt hat. Eine Uhr trifft den Moment nie - mal steht sie schon da, mal
kommt sie um die Ecke.

---

## 0.3 - 2026-08-24

Two data-driven fixes. Both were found by logging rather than by guessing, and both
removed our own interference rather than adding compensation for it.

### Fixed: arrival pose pop
Judy snapped into the arms-crossed idle when arriving, skipping the transition.

Cause, measured: at sprint speed with a 1 Hz tick she covers ~5 m per tick.

    8.29 m -> 3.12 m -> 1.16 m

The 6.0/3.0 gait window is 3 m wide, so `SprintDownDistance` was **never observable** -
the downshift always landed at 1.1-1.6 m, i.e. at arrival. And `nspD` was already -1.56
the tick before, meaning the native follow logic had already begun a correct
deceleration. Our command replacement cut a working locomotion blend.

- **Removed the custom gait layer entirely.** We always command Run; the engine escalates
  to a sprint by itself. Command replacements during approach went from 4 to **0**.
- Widening the window would not have helped: at ~5 m/tick the decision still lands
  wherever the single sample falls.
- Replaced by data: `r6/tweaks/CompanionLeash.yaml` sets
  `IdleActions.MoveOnSplineWithCompanionParams.catchUpSprintSpeedDistance` 12.0 -> 6.0,
  so the *native* threshold is tuned instead of the running movement being dismantled.
  Verified accepted by TweakXL, with sprinting observed at 5 m.

### Fixed: rotation almost never triggered
The `SetEntity` bug (0.2) was real but masked a second problem: facing correction only
ran in the IDLE branch, so after a crowding cancel she was immediately leashed again and
stayed turned away. Measured: 1 rotation per 5-minute session.

- Facing is now evaluated in LEASH too, gated on `FaceLeashDistance` (2.25 m) and
  `FaceMaxSpeed` (1.1 m/s) so it can only fire once she has effectively arrived.
  Mid-navigation her orientation stays the native locomotion's job.
- **Pending lock**: a rotation needs at least one scheduler cycle (measured ~1.0 s), so
  while one is executing only the retry path may re-issue. Without this, each tick would
  replace a rotate still in flight - the same interference the gait layer caused.
- IDLE and LEASH share one `ConsiderRotate` so the two paths cannot drift apart.
- Result: 9 rotations, 3 of them in LEASH, **9/9 resolved in ~1 tick, 0 suppressed**.
  `nsp` at rotation ranged 0.08-0.81 against a 1.1 gate - correctly calibrated, with
  headroom, and never firing at navigation speed.

### Fixed: jerky arm / walk animation
The walk and arm animation stuttered intermittently. Suspected to be an animation problem
and slated for the animation rework - it was ours.

The look-at was applied with a **fixed** `Chest` weight of 1.5 and gated on distance only,
so it stayed at full strength **while she was walking and sprinting**. That part pulls on
the same bone chain the locomotion animation drives.

- Chest weight now follows her speed: **1.5 when still, 0.3 while moving**, switching at
  `nsp > 1.5` and back below `nsp < 0.5` so it cannot flap during acceleration.
- Head weight is unchanged at 1.0 - she still aims at your face, which was the part worth
  keeping. Only the torso contribution is reduced.
- Switching removes and re-adds an *animation event*, not an AI command, so unlike a
  command replacement it does not touch the locomotion blend.
- Root cause was historical: the 1.5 chest weight dates from before the rotate fix, when
  the torso swing was the only thing making "turning back" visible. `AIRotateToCommand`
  has done that job since 0.2, so the high weight had simply become redundant.

Verified in the log: `laChest` switches between 1.500000 and 0.300000, with `act=L+L-`
marking the swap ticks.

### Facing gates in real play
First `SUPPRESS` observed, and it was the intended marginal case:

    reason=TooFar dist=2.285813 nsp=1.245584 dot=-0.153019

3.6 cm past `FaceLeashDistance`, still moving, barely past 90 degrees - correctly rejected
rather than rotating mid-navigation. Session totals: 7 ISSUE, 7 RESOLVED, 1 SUPPRESS.

### Observability
- `EVT` carries transition context: `reason`, `oldGait->newGait`, `commandReplaced`,
  `commandAge`, and `nspD`. `act=F` alone was ambiguous between engage and downshift.
- `ROT` logs `decision=ISSUE|SUPPRESS` with gate flags, and `RESOLVED after=` / `RETRY`.
  A SUPPRESS line only appears when she really is turned away, so the gates are directly
  countable rather than inferred.
- `RAW` captures full kinematics for both actors - position, facing and velocity - as
  replay input for `Evaluate()`. **Off by default**; enable to record a tuning trace.
- Heartbeat 15s in normal play, 3s when investigating.

### Note on measurement limits
At 1 Hz the log cannot resolve a sub-second animation blend. What it can prove is that
`replaced=0` removed our interference; that the pop is gone is the player's observation,
and at this cadence that is the more reliable signal.

## 0.2 - 2026-08-24

Architecture pass. No behavioural retuning except the facing debounce.

### Architecture
- **Policy extracted** to `r6/scripts/CompanionLeash/` as its own module. It holds no NCA
  types, issues no commands, and only takes positions/orientation/elapsed time and returns
  a `CompanionLeashDecision`. Pure enough to reason about without launching the game.
- **Bridge narrowed** to the single place that may touch protected state
  (`HasCommand` / `FollowTarget` / `SendCommand` / `CancelCommand`) and queue events.
  Command ownership stays entirely inside NCA's behaviour - there is never a second writer
  to the AI controller.
- Patch footprint: **266 diff lines -> 77 added lines**, mostly comments. Re-merging after
  an NCA update is now "restore a short bridge", not "reconcile a rewrite".
- Note: the bridge cannot be moved out. `FollowTarget`/`SendCommand`/`CancelCommand`/
  `HasCommand` are `protected` on `NCABehavior`, and passing `this` to an external helper
  does not grant access - protected is hierarchy-scoped, not instance-scoped.

### Discovered
- **The behaviour tick is ~1 Hz, not per frame.** Chain:
  `TimeListeners` (ScriptableSystem) -> `Start()` from EventBus session start ->
  self-rescheduling `DelayCallback(TickDelay() = 1.0)` -> `OnTick(measured)` ->
  `NpcManager.Tick` -> `NpcHandle.Tick` -> `behavior.Tick` -> our `Update`.
  Every timer in this mod is quantised to whole ticks. Earlier reasoning that assumed
  per-frame execution was wrong.
- ScriptableSystems *are* instantiated automatically by the container, but they are **not**
  ticked automatically. Scheduling needs an explicit owner - NCA uses `m_isStarted` to make
  duplicate scheduling impossible.

### Changed
- `FaceCooldown` 1.0 -> **0.0**. At 1 Hz a 1.0s cooldown cost a full extra tick before a
  turn-back could even be considered. Replaced with **angle hysteresis**, which is the
  meaningful control at this cadence: rotate below `FaceAwayDot` (90 deg), considered
  settled above `FaceSettledDot` (~45 deg), and `FaceRetry` (3s) re-issues a rotate that
  never took effect so a blocked turn cannot become permanent.

### Added
- Decision logging via `LogChannel(n"DEBUG", ...)`, emitted only on ticks where something
  was issued. Surfaces in CET's `gamelog.log`. Toggle with `LogEnabled()`.
- `manifest.json` - version, game/NCA build, both patch hashes, policy file hashes.
- Tooling is manifest-driven, discovers the game root instead of hardcoding it, verifies
  the post-install hash, and refuses to touch a file matching neither recorded hash.

## 0.1 — 2026-08-24

First working version. Patches `NCAFollowPlayerBehavior` in Night City Allies.

- **Leash** — two-mode IDLE/LEASHED state machine keeps companions at ~1.1m instead of
  the vanilla follower role's ~10m, without removing the role.
- **Anti-crowding** — cancels the follow command when the player steps inside
  `ReleaseDistance`, so they hold ground rather than shuffling backwards.
- **Turn back around** — `AIRotateToCommand` rotates the body when they end up more than
  90 degrees off-axis, instead of waiting for the player to move.
- **Direct look-at** — hand-built `LookAtAddEvent` targeting the `Head` slot with head
  weight 1.0, replacing vanilla's torso-anchored `pla_default_tgt` at weight 0.1.
- **Gait switching** — Sprint past 6m, Run under 3m, with hysteresis.
- Tooling: hash-verified `apply.py` / `revert.py`, round-trip tested.

### Fixed during development
- `chest.weight` regression: dropping it to 0.5 alongside the look-at rework removed the
  torso swing that made "turning back" readable. Restored to 1.5.
- Sprint-everywhere: `matchSpeed` does not damp `movementType`; a single persistent
  command used one gait at all distances.
