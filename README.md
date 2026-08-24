# Companion Leash

Follow-behaviour and presence fixes for **Night City Allies** (NCA) on Cyberpunk 2077 2.31.

Version **0.1** — see CHANGELOG.md.

---

## What it fixes

| Problem | Cause | Fix |
|---|---|---|
| Allies trail ~10m behind and react slowly | `OnAttach` assigns a vanilla `AIFollowerRole` and nothing else. The role has no distance parameter. | A leash: issue an `AIFollowTargetCommand` once they drift past `EngageDistance`. |
| They shuffle backwards when you step into them | `AIFollowTargetCommand` maintains `desiredDistance` in **both** directions. | Cancel the command inside `ReleaseDistance`; the still-assigned role takes over. |
| After sidestepping they keep their back to you | Look-at only bends eyes/head/chest. Root facing is owned by the movement system. | `AIRotateToCommand` rotates in place when they are >90° off-axis. |
| They look past you rather than at you | Vanilla `ActivateReactionLookAt` targets the torso-height `pla_default_tgt` slot and weights `Head` at only 0.1. | Build the `LookAtAddEvent` by hand: target the `Head` slot, `Head` weight 1.0. |
| You outrun them when sprinting | A persistent follow command uses exactly the gait it was issued with. `matchSpeed` does **not** damp it. | Escalate gait to Sprint past `SprintUpDistance`, drop back to Run under `SprintDownDistance`. |

## Design

`NCAFollowPlayerBehavior.Update()` ships **empty**. All logic lives there. `OnAttach` and
`OnDetach` are left intact apart from one added cleanup call, so the vanilla
`AIFollowerRole` still drives combat, navigation and unstuck handling.

Two modes:

- **IDLE** — no command of ours. Vanilla role governs. Drift past `EngageDistance` -> LEASHED.
- **LEASHED** — a follow command holds them at `DesiredDistance`. Walk inside
  `ReleaseDistance` -> cancel -> IDLE.

The gap between `ReleaseDistance` and `EngageDistance` is deliberate hysteresis. Without
it the command is cancelled and re-issued every frame.

## Tuning

All constants are `private static func` at the top of the patched block.
Edit, then restart — redscript only compiles at launch.

| Constant | v0.1 | Effect |
|---|---|---|
| `DesiredDistance` | 1.1 | Where they settle. Below ~1.0 they clip into you. |
| `FollowTolerance` | 0.3 | Arrival slack. Small = attentive, large = coasts in. |
| `EngageDistance` | 1.5 | Drift before a follow command is issued. |
| `ReleaseDistance` | 0.9 | How close *you* may get before they stop repositioning. |
| `LookAtDistance` | 6.0 | Range at which head tracking engages. |
| `FaceAwayDot` | 0.0 | Dot product, not degrees. 0.0 = "more than 90 degrees off". |
| `FaceAngleTolerance` | 15.0 | Rotate command angle tolerance. |
| `FaceCooldown` | 1.0 | Seconds between rotate attempts. |
| `SprintUpDistance` | 6.0 | Gap at which gait escalates to Sprint. |
| `SprintDownDistance` | 3.0 | Gap at which gait drops back to Run. |
| `head.weight` | 1.0 | Look-at head involvement. Vanilla uses 0.1. |
| `chest.weight` | 1.5 | Torso swing. Vanilla uses 2.0. Drives the visible "turn toward you". |

## Architecture

    r6/scripts/CompanionLeash/          <- policy layer, ours, nothing else touches it
      CompanionLeashPolicy.reds           distances, hysteresis, facing maths, decisions
      CompanionLeashCommands.reds         look-at event + rotate command construction

    NCA FollowPlayerBehavior.reds       <- bridge, 77 added lines
      Update()   gathers inputs -> Evaluate() -> applies the decision
      OnDetach() drops the persistent look-at

**Command ownership is the whole design.** The policy layer never issues or cancels a
command; it returns a decision. The bridge is the only code that reads or writes protected
command state, so NCA's behaviour remains the single writer to the AI controller.

The bridge cannot be eliminated. `FollowTarget`, `SendCommand`, `CancelCommand` and
`HasCommand` are `protected` on `NCABehavior`; passing `this` to an external helper does
not confer access, because protected is hierarchy-scoped. Annotations cannot bridge it
either - `@replaceMethod` / `@addField` resolve only against base-game classes:

- `@addField(NCAFollowPlayerBehavior)` -> `constant pool error: definition not found: 203383`
- `@replaceMethod(NCAFollowPlayerBehavior)` -> `unresolved reference 'NCAFollowPlayerBehavior'`
- unchanged after declaring `module NightCityAllies.Npc.Behavior`

Ordinary code *can* reference NCA types across modules - that is exactly how the bridge
calls into `CompanionLeash`. Only annotation targets are restricted.

## Cadence

Behaviour updates run at about **1 Hz**, not per frame:

    TimeListeners (ScriptableSystem)
      Start()                          <- explicit, from EventBus session start
        DelayCallback(TickDelay()=1.0, self-rescheduling, m_isStarted guards duplicates)
          OnTick(measured interval)    <- NCA compensates ~1.3% scheduler drift
            NpcManager.Tick -> NpcHandle.Tick -> behavior.Tick -> Update()

Every timer here is quantised to whole ticks. Prefer angle/distance hysteresis over
sub-second cooldowns - the latter cannot express anything finer than one tick.

## Upstream

The clean end state is an NCA extension point, so this stops being a patch entirely.
A narrow decision hook is enough - NCA keeps attach/detach, `m_command` and all
arbitration; the addon only supplies target and distance policy:

    public func ResolveFollowRequest(handle: ref<NpcHandle>, defaultTarget: ref<GameObject>,
                                     defaultDistance: Float, defaultTolerance: Float)
        -> ref<NCAFollowRequest>

Prefer this over a per-tick callback, which would bind NCA's public API to its scheduling
implementation.

## Install / revert / update

    python apply.py     # stock -> patched  (refuses if NCA changed)
    python revert.py    # patched -> stock

Both are hash-verified and idempotent. `apply.py` refuses rather than guessing if
`FollowPlayerBehavior.reds` matches neither recorded file.

**After an NCA update** the patch is overwritten and `apply.py` will refuse. Re-merge:

1. Copy the new stock file over `FollowPlayerBehavior.ORIGINAL.reds`
2. Re-apply the changes in `companion-leash.patch`
3. Save as `FollowPlayerBehavior.PATCHED.reds`, re-run `apply.py`

**Vortex note:** the target is a Vortex-deployed hardlink, so editing it also touches the
staging copy, and a purge/redeploy restores the stock file.

## Known limitations

- The small sidestep when you walk into a companion is vanilla `AIFollowerRole` /
  personal-space behaviour, not ours. Removing it means removing the role, which breaks
  combat and navigation — exactly the failure mode of the mod this replaces.
- `AIRotateToCommand.speed` is left unset. No vanilla script constructs one, so there is
  no reference value to copy.
- Untested on multi-companion squads; each behaviour instance holds its own state, so it
  should be fine, but it has not been verified.
