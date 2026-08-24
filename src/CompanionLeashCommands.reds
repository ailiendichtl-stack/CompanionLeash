// =====================================================================================
//  CompanionLeash - command and event construction
// =====================================================================================
//  Builds the game-owned objects. Deliberately does NOT send them: sending requires
//  NCABehavior.SendCommand, which is protected, so the bridge inside NCA stays the sole
//  issuer. Construction is pure and needs only public accessors, so it lives out here.
//  NOTE: no `module` declaration on purpose - global scope, so NCA's module sees
//  these classes exactly like it sees game classes, with no import needed.
// =====================================================================================

public class CompanionLeashLookAt {

    //  Built by hand rather than via ReactionManagerComponent.ActivateReactionLookAt,
    //  which hard-codes two things that make companions look THROUGH you:
    //    * it targets the 'pla_default_tgt' slot, a torso-height anchor, not your face
    //    * it gives the 'Head' part a weight of 0.1, so the eyes swivel but the head
    //      barely turns - which reads as glancing past rather than looking at you
    //  Everything else mirrors the vanilla construction, including the limit values.
    //  end/duration are not used: with no EndLookatEvent scheduled the look-at is
    //  persistent, so its lifetime is ours to manage via Remove().
    public static func Build(player: wref<GameObject>, chestWeight: Float) -> ref<LookAtAddEvent> {
        let evt: ref<LookAtAddEvent> = new LookAtAddEvent();

        evt.SetEntityTarget(player, n"Head", Vector4.EmptyVector());
        evt.SetStyle(animLookAtStyle.Normal);
        evt.bodyPart = n"Eyes";

        evt.request.limits.softLimitDegrees = 360.0;
        evt.request.limits.hardLimitDegrees = 270.0;
        evt.request.limits.backLimitDegrees = 210.0;
        evt.request.limits.hardLimitDistance = GetLookAtLimitDistanceValue(animLookAtLimitDistanceType.None);
        evt.request.calculatePositionInParentSpace = true;

        let parts: array<LookAtPartRequest>;

        let head: LookAtPartRequest;
        head.partName = n"Head";
        head.weight = 1.0;
        head.suppress = 0.0;
        head.mode = 0;
        ArrayPush(parts, head);

        //  Vanilla uses 2.0 here with Head at 0.1: the torso does the turning and the
        //  head barely moves. We keep Head high so they aim at your face, but the chest
        //  weight still matters - it is what visibly swings the upper body round toward
        //  you after a sidestep. Dropping it to 0.5 made them look correct but stop
        //  turning; 1.5 restores the swing without going back to torso-led aiming.
        //  Chest weight now comes from the policy instead of being fixed. It pulls on the
        //  same bone chain the locomotion animation drives, which is the suspected cause
        //  of the jerky arm/walk motion, so it is high when still and reduced while
        //  moving. Body rotation no longer depends on it - AIRotateToCommand does that.
        let chest: LookAtPartRequest;
        chest.partName = n"Chest";
        chest.weight = chestWeight;
        chest.suppress = 0.0;
        chest.mode = 0;
        ArrayPush(parts, chest);

        evt.SetAdditionalPartsArray(parts);
        return evt;
    }

    public static func Remove(npc: wref<GameObject>, evt: ref<LookAtAddEvent>) -> Void {
        if IsDefined(npc) && IsDefined(evt) {
            LookAtRemoveEvent.QueueRemoveLookatEvent(npc, evt);
        }
    }
}

public class CompanionLeashCommands {

    //  Look-at only bends eyes/head/chest. Root facing is owned by the movement system,
    //  so once they end up back-to-you nothing rotates the body. AIRotateToCommand
    //  rotates in place without moving, which is exactly that.
    //
    //  MUST be sent with once=true. NCABehavior.SendCommand only stores m_command when
    //  once is false, and NCA never clears m_command on completion - only CancelCommand
    //  does. Storing a one-shot rotate would leave HasCommand() true forever and the
    //  leash could never re-engage.
    //
    //  speed is left at its default: no vanilla script constructs one of these, so there
    //  is no reference value to copy.
    public static func BuildRotate(player: wref<GameObject>) -> ref<AIRotateToCommand> {
        let command: ref<AIRotateToCommand> = new AIRotateToCommand();

        //  MUST be a world position, not an entity. AIMoveRotateToCommandHandler reads the
        //  target with AIPositionSpec.GetWorldPosition() and never calls GetEntity(), so a
        //  spec built with SetEntity() hands the behaviour tree an unset position and the
        //  NPC rotates toward nothing. Measured: dot moved -0.763 -> -0.667 over 3s before
        //  this fix, i.e. effectively no rotation. Same pattern NCA uses in its MoveTo.
        let spec = new AIPositionSpec();
        let wp: WorldPosition;
        WorldPosition.SetVector4(wp, player.GetWorldPosition());
        AIPositionSpec.SetWorldPosition(spec, wp);

        command.target = spec;
        command.angleTolerance = 15.0;
        return command;
    }
}
