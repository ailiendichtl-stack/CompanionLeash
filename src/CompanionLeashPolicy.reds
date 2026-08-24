// =====================================================================================
//  CompanionLeash - policy layer
// =====================================================================================
//  Pure decision-making. This file holds NO references to Night City Allies types and
//  issues NO commands. It takes positions, orientation and elapsed time, and returns a
//  decision. The bridge inside NCA is the ONLY thing that touches protected command
//  state - that boundary is deliberate, so this layer can never become a second
//  ownership path over the AI controller.
//
//  CADENCE, IMPORTANT: NCA drives behaviour updates from TimeListeners, a self-
//  rescheduling DelayCallback with TickDelay() = 1.0. Evaluate() therefore runs about
//  ONCE PER SECOND, not per frame, and deltaTime is NCA's measured interval (~1.013s).
//  Measured from logged decisions: the minimum gap between ticks is exactly 1.0s.
//  Any timer here is quantised to whole ticks - which is why facing uses ANGLE
//  hysteresis rather than a sub-second cooldown.
//
//  NOTE: no `module` declaration on purpose. Global scope means these classes are
//  visible from NCA's module exactly like game classes (AIRotateToCommand,
//  LookAtAddEvent, Vector4) already are, with no import needed on their side.
//
//  Logging uses FTLog, not LogChannel. LogChannel is NOT declared anywhere in the
//  game scripts - every apparent use of it in installed mods is commented out.
//  FTLog is `import function FTLog(const value: ref<String>)` in the script dump
//  and is used live by Audioware, AldecaldosHighStakes and Hangout Romances.
// =====================================================================================

public class CompanionLeashTuning {
    // Distance policy
    public static func DesiredDistance()    -> Float = 1.1;
    public static func FollowTolerance()    -> Float = 0.3;
    public static func EngageDistance()     -> Float = 1.5;
    public static func ReleaseDistance()    -> Float = 0.9;

    //  GAIT POLICY: REMOVED IN 0.3 - see CHANGELOG.
    //  A custom gait layer cannot work at this cadence. Measured, sprinting at 5.4 m/s
    //  with a 1 Hz tick:
    //      8.29 m -> 3.12 m -> 1.16 m      i.e. ~5 m covered per tick
    //  The 6.0/3.0 window is 3 m wide, so the downshift threshold was never observable -
    //  it always fired at 1.1-1.6 m, right at arrival. Worse, nspD was already -1.56 the
    //  tick before, meaning the native follow logic had ALREADY begun a correct
    //  deceleration. Replacing the command there cut a working locomotion blend and
    //  produced the visible arms-cross pose pop.
    //
    //  Widening the window does not fix it: at ~5 m/tick the decision still lands
    //  wherever the single sample happens to fall.
    //
    //  The engine already handles this natively. AIMoveFollowTargetCommandHandler:
    //      if movementType == Sprint -> always sprint
    //      else -> sprint above TDB "IdleActions.MoveOnSplineWithCompanionParams
    //                                .catchUpSprintSpeedDistance" (default 12.0)
    //  So we always command Run and let the AI sprint on its own, with no command
    //  replacement at all. The catch-up threshold is tuned as DATA in
    //  r6/tweaks/CompanionLeash.yaml instead of as a script command swap.

    // Look-at
    public static func LookAtDistance()     -> Float = 6.0;
    //  The chest part of the look-at pulls on the same bone chain the locomotion
    //  animation drives, so at the weight that makes standing still look good it is the
    //  prime suspect for the jerky arm/walk motion. The weight therefore follows her
    //  speed, with a hysteresis band so it cannot flap while she accelerates.
    public static func LookAtChestStill()   -> Float = 1.5;
    public static func LookAtChestMoving()  -> Float = 0.3;
    public static func LookAtMoveSpeed()    -> Float = 1.5;
    public static func LookAtStillSpeed()   -> Float = 0.5;

    // Facing. Dot products, not degrees. 0.0 = more than 90 deg off axis.
    public static func FaceAwayDot()        -> Float = 0.0;
    // Considered settled again above this, so a rotate is not re-issued while turning.
    public static func FaceSettledDot()     -> Float = 0.7;
    // Seconds before a rotate that never took effect is retried. Quantised to ticks.
    public static func FaceRetry()          -> Float = 3.0;
    // Extra debounce on top of the angle hysteresis. 0.0 = none (see CHANGELOG 0.2).
    public static func FaceCooldown()       -> Float = 0.0;

    //  Leash-state facing gates (0.3). While she is actively navigating, her orientation
    //  is the native locomotion's job - injecting a rotate there would be exactly the kind
    //  of mid-movement interference we removed with the gait layer. So in LEASH we only
    //  correct once she has practically arrived and is standing still anyway.
    public static func FaceLeashDistance()  -> Float = 2.25;
    public static func FaceMaxSpeed()       -> Float = 1.1;

    // Observability.
    public static func LogEnabled()         -> Bool = true;
    // Seconds between heartbeat samples. Events are always logged regardless.
    // At ~1 tick/second, 3.0 gives ~1200 samples/hour - enough to build a distribution
    // without drowning the shared gamelog.
    public static func LogHeartbeat()       -> Float = 5.0;
    //  Raw kinematic capture: the full input to Evaluate(), so a recorded session can be
    //  replayed against changed constants without launching the game.
    public static func LogRawEnabled()      -> Bool = true;
    //  Seconds between RAW samples. 1.0 = every tick (~0.9 MB/hour in the shared gamelog).
    //  Raise for long play sessions: 3.0 still resolves arrival deceleration, 5.0 is
    //  enough for distance/angle distributions but too coarse to replay a single approach.
    public static func LogRawInterval()     -> Float = 1.0;
}

public class CompanionLeashState {
    public let lookAtActive: Bool;
    public let rotating: Bool;
    public let rotateAge: Float;
    public let cooldown: Float;
    public let hbTimer: Float;
    public let rawTimer: Float;
    // Which look-at variant is currently applied.
    public let lookAtMoving: Bool;
    // VO spike only - remove with CompanionLeashVoTest.reds.
    public let voTimer: Float;
    public let voIndex: Int32;
    // Observability: how long the live follow command has existed, the previous tick's
    // npc speed, and which gait is currently commanded (0 none, 1 Run, 2 Sprint).
    public let commandAge: Float;
    public let lastNsp: Float;
    public let gait: Int32;
}

public class CompanionLeashDecision {
    public let cancelFollow: Bool;
    public let issueFollow: Bool;
    public let sprint: Bool;
    public let desiredDistance: Float;
    public let desiredTolerance: Float;
    public let issueRotate: Bool;
    public let applyLookAt: Bool;
    public let removeLookAt: Bool;

    // Observability only - never read by the bridge.
    public let distance: Float;
    public let facingDot: Float;
    // Captured BEFORE any reset - logging it afterwards always read 0.
    public let rotateAge: Float;
    public let leashed: Bool;
    public let heartbeat: Bool;
    // True on the tick a rotation reached FaceSettledDot. rotateAge is then how long it took.
    public let rotateResolved: Bool;
    // True when a rotate was re-issued because the previous one never resolved.
    public let rotateRetried: Bool;

    // Transition context. "F" alone is ambiguous - it can be a fresh engage OR a gait
    // downshift - so the reason and the gait pair are logged separately.
    public let reason: String;
    public let oldGait: Int32;
    public let newGait: Int32;
    public let commandReplaced: Bool;
    // Age of the command being replaced, i.e. how long it had been running.
    public let commandAge: Float;

    // Facing gates, so a wrong threshold shows up in the log instead of being inferred.
    public let gateDot: Bool;
    public let gateDist: Bool;
    public let gateSpeed: Bool;
    public let gatePending: Bool;
    public let rotSuppressed: Bool;
    public let rotSuppressReason: String;
    // Chest weight the bridge should build the look-at with.
    public let lookAtChest: Float;
}

public class CompanionLeashPolicy {

    // 1.0 (facing) on degenerate input, so we never rotate on noise.
    public static func FacingDot(playerPos: Vector4, npcPos: Vector4, npcForward: Vector4) -> Float {
        let toPlayer = playerPos - npcPos;
        toPlayer.Z = 0.0;
        if Vector4.Length(toPlayer) < 0.05 {
            return 1.0;
        }

        let fwd = npcForward;
        fwd.Z = 0.0;
        if Vector4.Length(fwd) < 0.05 {
            return 1.0;
        }

        return Vector4.Dot(Vector4.Normalize(fwd), Vector4.Normalize(toPlayer));
    }


    //  Facing decision, shared by both states.
    //
    //  IDLE  : original window - close to the player and turned away.
    //  LEASH : additionally gated on distance AND speed, so a correction only happens
    //          once she has effectively arrived. Mid-navigation her orientation belongs
    //          to the native locomotion.
    //
    //  PENDING LOCK: a rotation needs at least one full scheduler cycle to resolve
    //  (measured: RESOLVED after ~1.0s). Re-issuing every tick would replace a rotate
    //  that is still executing - the same class of interference the gait layer caused.
    //  While one is pending, only the retry path may re-issue.
    public static func ConsiderRotate(d: ref<CompanionLeashDecision>, state: ref<CompanionLeashState>,
                                      npcSpeed: Float, isLeashed: Bool) -> Void {
        let gateDist: Bool = true;
        let gateSpeed: Bool = true;
        if isLeashed {
            gateDist = d.distance <= CompanionLeashTuning.FaceLeashDistance();
            gateSpeed = npcSpeed <= CompanionLeashTuning.FaceMaxSpeed();
        }

        d.gateDot = d.facingDot < CompanionLeashTuning.FaceAwayDot();
        d.gateDist = gateDist;
        d.gateSpeed = gateSpeed;
        d.gatePending = !state.rotating;

        // Facing is fine - nothing to decide, and nothing worth logging.
        if !d.gateDot {
            return;
        }

        if state.cooldown > 0.0 {
            d.rotSuppressed = true;
            d.rotSuppressReason = "Cooldown";
            return;
        }

        if !gateDist {
            d.rotSuppressed = true;
            d.rotSuppressReason = "TooFar";
            return;
        }

        if !gateSpeed {
            d.rotSuppressed = true;
            d.rotSuppressReason = "Moving";
            return;
        }

        if state.rotating {
            if state.rotateAge > CompanionLeashTuning.FaceRetry() {
                d.issueRotate = true;
                d.rotateRetried = true;
                d.reason = "FaceRetry";
                state.rotateAge = 0.0;
                state.cooldown = CompanionLeashTuning.FaceCooldown();
            } else {
                d.rotSuppressed = true;
                d.rotSuppressReason = "Pending";
            }
            return;
        }

        d.issueRotate = true;
        d.reason = "FaceAway";
        state.rotating = true;
        state.rotateAge = 0.0;
        state.cooldown = CompanionLeashTuning.FaceCooldown();
    }

    public static func Evaluate(playerPos: Vector4, npcPos: Vector4, npcForward: Vector4,
                                npcSpeed: Float, hasCommand: Bool, deltaTime: Float,
                                state: ref<CompanionLeashState>) -> ref<CompanionLeashDecision> {
        let d = new CompanionLeashDecision();
        d.desiredDistance = CompanionLeashTuning.DesiredDistance();
        d.desiredTolerance = CompanionLeashTuning.FollowTolerance();
        d.distance = Vector4.Distance(playerPos, npcPos);
        d.facingDot = CompanionLeashPolicy.FacingDot(playerPos, npcPos, npcForward);
        d.leashed = hasCommand;

        if state.cooldown > 0.0 {
            state.cooldown -= deltaTime;
        }
        if state.rotating {
            state.rotateAge += deltaTime;
        }
        d.rotateAge = state.rotateAge;

        if hasCommand {
            state.commandAge += deltaTime;
        } else {
            state.commandAge = 0.0;
        }
        d.commandAge = state.commandAge;
        d.oldGait = state.gait;
        d.newGait = state.gait;

        state.hbTimer -= deltaTime;
        if state.hbTimer <= 0.0 {
            d.heartbeat = true;
            state.hbTimer = CompanionLeashTuning.LogHeartbeat();
        }

        // A rotation that reached the settled angle. Recorded before the IDLE early-outs
        // below, so resolution is still observed while leashed.
        if state.rotating && d.facingDot > CompanionLeashTuning.FaceSettledDot() {
            d.rotateResolved = true;
            state.rotating = false;
            state.rotateAge = 0.0;
        }

        // Look-at is independent of the follow state machine.
        //
        //  Two variants selected by her own speed, with a hysteresis band: full chest
        //  weight when standing, reduced while moving. Switching removes and re-adds the
        //  event, which the bridge does in that order within one tick. This is an
        //  animation event, not an AI command, so unlike a command replacement it does
        //  not touch the locomotion blend.
        let wantMoving: Bool = state.lookAtMoving;
        if npcSpeed > CompanionLeashTuning.LookAtMoveSpeed() {
            wantMoving = true;
        }
        if npcSpeed < CompanionLeashTuning.LookAtStillSpeed() {
            wantMoving = false;
        }

        if d.distance <= CompanionLeashTuning.LookAtDistance() {
            if !state.lookAtActive {
                d.applyLookAt = true;
                state.lookAtActive = true;
                state.lookAtMoving = wantMoving;
            } else {
                if !Equals(state.lookAtMoving, wantMoving) {
                    d.removeLookAt = true;
                    d.applyLookAt = true;
                    state.lookAtMoving = wantMoving;
                }
            }
        } else {
            if state.lookAtActive {
                d.removeLookAt = true;
                state.lookAtActive = false;
            }
        }

        d.lookAtChest = CompanionLeashTuning.LookAtChestStill();
        if state.lookAtMoving {
            d.lookAtChest = CompanionLeashTuning.LookAtChestMoving();
        }

        // LEASHED - a follow command of ours is live.
        //
        //  Nothing is re-issued here. The native follow command runs to completion, so
        //  its own sprint / decelerate / arrive / idle transition stays intact. The only
        //  thing that ends it early is you walking into her.
        if hasCommand {
            if d.distance < CompanionLeashTuning.ReleaseDistance() {
                d.cancelFollow = true;
                d.reason = "Crowding";
                d.newGait = 0;
                state.gait = 0;
                state.commandAge = 0.0;
                return d;
            }

            CompanionLeashPolicy.ConsiderRotate(d, state, npcSpeed, true);
            return d;
        }

        // IDLE - vanilla AIFollowerRole has them.
        if d.distance > CompanionLeashTuning.EngageDistance() {
            d.issueFollow = true;
            // Always Run. The AI escalates to a sprint by itself when the gap warrants it.
            d.sprint = false;
            d.reason = "Engage";
            d.newGait = 1;
            state.gait = 1;
            state.commandAge = 0.0;
            return d;
        }

        // Close and unleashed: turn the body back if she ended up facing away.
        CompanionLeashPolicy.ConsiderRotate(d, state, npcSpeed, false);

        return d;
    }


    // Raw input capture for offline replay. Records everything Evaluate() consumes, plus
    // the player's facing for relative-bearing analysis. With this the entire decision
    // stream can be re-derived outside the game, so tuning constants can be swept against
    // a real recorded session instead of guessed and re-launched.
    //
    // Deliberately NOT folded into Evaluate(): that function stays pure and free of
    // observability parameters. The bridge calls this separately.
    public static func LogRaw(who: String, deltaTime: Float,
                              playerPos: Vector4, playerForward: Vector4, playerVel: Vector4,
                              npcPos: Vector4, npcForward: Vector4, npcVel: Vector4,
                              hasCommand: Bool, state: ref<CompanionLeashState>) -> Void {
        if !CompanionLeashTuning.LogEnabled() || !CompanionLeashTuning.LogRawEnabled() {
            return;
        }

        state.rawTimer -= deltaTime;
        if state.rawTimer > 0.0 {
            return;
        }
        state.rawTimer = CompanionLeashTuning.LogRawInterval();

        let cmd: String = "0";
        if hasCommand {
            cmd = "1";
        }

        //  Full kinematic state for both actors: position, facing and velocity. Position
        //  and facing alone cannot answer the questions that matter for tuning - whether
        //  she is actually moving, whether her speed matches yours, or whether a gait
        //  change produced any real change in velocity. Speed is emitted alongside the
        //  vector purely so the log is readable without post-processing.
        FTLog("[CompanionLeash] RAW " + who
            + " dt=" + FloatToString(deltaTime)
            + " cmd=" + cmd
            + " | px=" + FloatToString(playerPos.X)
            + " py=" + FloatToString(playerPos.Y)
            + " pz=" + FloatToString(playerPos.Z)
            + " pfx=" + FloatToString(playerForward.X)
            + " pfy=" + FloatToString(playerForward.Y)
            + " pvx=" + FloatToString(playerVel.X)
            + " pvy=" + FloatToString(playerVel.Y)
            + " pvz=" + FloatToString(playerVel.Z)
            + " psp=" + FloatToString(Vector4.Length(playerVel))
            + " | nx=" + FloatToString(npcPos.X)
            + " ny=" + FloatToString(npcPos.Y)
            + " nz=" + FloatToString(npcPos.Z)
            + " nfx=" + FloatToString(npcForward.X)
            + " nfy=" + FloatToString(npcForward.Y)
            + " nvx=" + FloatToString(npcVel.X)
            + " nvy=" + FloatToString(npcVel.Y)
            + " nvz=" + FloatToString(npcVel.Z)
            + " nsp=" + FloatToString(Vector4.Length(npcVel)));
    }

    public static func Flag(b: Bool) -> String {
        if b {
            return "1";
        }
        return "0";
    }

    public static func GaitName(g: Int32) -> String {
        if g == 2 {
            return "Sprint";
        }
        if g == 1 {
            return "Run";
        }
        return "-";
    }

    // Three line kinds, so tuning can be judged from data rather than impressions:
    //
    //   EVT  something was issued. Carries the full transition context: WHY it fired,
    //        which gait replaced which, how old the replaced command was, and how the
    //        npc's speed moved across the tick. "F" alone is ambiguous - a fresh engage
    //        and a sprint downshift both log F - which is why reason is separate.
    //   HB   periodic sample. Shows WHERE she sits between thresholds: the distance,
    //        angle and speed distributions that say whether the numbers are too
    //        aggressive or too slack.
    //   ROT  a rotation resolved or was retried. after= is the direct measure of
    //        whether rotation is fast enough.
    //
    //  nspDelta is the key column for the locomotion-pop investigation: a command
    //  replacement that collapses npc speed within a single tick is the signature of a
    //  cut locomotion blend, as opposed to a normal multi-tick deceleration.
    public static func Log(who: String, d: ref<CompanionLeashDecision>, state: ref<CompanionLeashState>,
                           npcSpeed: Float, playerSpeed: Float) -> Void {
        if !CompanionLeashTuning.LogEnabled() {
            return;
        }

        let mode: String = "IDLE";
        if d.leashed {
            mode = "LEASH";
        }

        let flags: String = "";
        if state.lookAtActive { flags = flags + "l"; }
        if state.rotating { flags = flags + "r"; }
        if Equals(flags, "") { flags = "-"; }

        let nspDelta: Float = npcSpeed - state.lastNsp;

        let common: String = who
            + " " + mode
            + " dist=" + FloatToString(d.distance)
            + " dot=" + FloatToString(d.facingDot)
            + " nsp=" + FloatToString(npcSpeed)
            + " psp=" + FloatToString(playerSpeed)
            + " nspD=" + FloatToString(nspDelta)
            + " laChest=" + FloatToString(d.lookAtChest)
            + " st=" + flags;

        //  Facing decisions are logged even when nothing was issued - a SUPPRESS line
        //  only appears when she IS turned away, so the gates show directly whether the
        //  speed/distance thresholds are too strict or too loose.
        if d.issueRotate {
            FTLog("[CompanionLeash] ROT " + who + " decision=ISSUE state=" + mode
                + " dist=" + FloatToString(d.distance)
                + " nsp=" + FloatToString(npcSpeed)
                + " dot=" + FloatToString(d.facingDot)
                + " gateDist=" + CompanionLeashPolicy.Flag(d.gateDist)
                + " gateSpeed=" + CompanionLeashPolicy.Flag(d.gateSpeed)
                + " gateDot=" + CompanionLeashPolicy.Flag(d.gateDot)
                + " pending=" + CompanionLeashPolicy.Flag(!d.gatePending));
        }

        if d.rotSuppressed {
            FTLog("[CompanionLeash] ROT " + who + " decision=SUPPRESS reason=" + d.rotSuppressReason
                + " state=" + mode
                + " dist=" + FloatToString(d.distance)
                + " nsp=" + FloatToString(npcSpeed)
                + " dot=" + FloatToString(d.facingDot));
        }

        if d.rotateResolved {
            FTLog("[CompanionLeash] ROT " + common + " RESOLVED after=" + FloatToString(d.rotateAge) + "s");
        }

        if d.rotateRetried {
            FTLog("[CompanionLeash] ROT " + common + " RETRY unresolved_for=" + FloatToString(CompanionLeashTuning.FaceRetry()) + "s");
        }

        let acted: Bool = d.issueFollow || d.cancelFollow || d.issueRotate || d.applyLookAt || d.removeLookAt;
        if acted {
            let act: String = "";
            if d.issueFollow { act = act + "F"; }
            if d.sprint { act = act + "S"; }
            if d.cancelFollow { act = act + "C"; }
            if d.issueRotate { act = act + "R"; }
            if d.applyLookAt { act = act + "L+"; }
            if d.removeLookAt { act = act + "L-"; }

            let repl: String = "0";
            if d.commandReplaced {
                repl = "1";
            }

            FTLog("[CompanionLeash] EVT " + common
                + " act=" + act
                + " reason=" + d.reason
                + " gait=" + CompanionLeashPolicy.GaitName(d.oldGait) + "->" + CompanionLeashPolicy.GaitName(d.newGait)
                + " replaced=" + repl
                + " cmdAge=" + FloatToString(d.commandAge)
                + " rotAge=" + FloatToString(d.rotateAge));
            state.lastNsp = npcSpeed;
            return;
        }

        if d.heartbeat {
            FTLog("[CompanionLeash] HB  " + common
                + " gait=" + CompanionLeashPolicy.GaitName(state.gait)
                + " cmdAge=" + FloatToString(d.commandAge)
                + " rotAge=" + FloatToString(d.rotateAge));
        }

        state.lastNsp = npcSpeed;
    }
}
