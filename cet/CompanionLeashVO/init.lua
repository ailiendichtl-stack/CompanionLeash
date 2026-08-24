-- =====================================================================================
--  CompanionLeash - test panel  (VO + animation)
-- =====================================================================================
--  Manual counterpart to the timed redscript spikes. Clicking removes the ambiguity a
--  scheduled test cannot: which slot a result belonged to, and whether nothing happening
--  meant "no data" or just "this variant was empty".
--
--  Lua rather than redscript on purpose: a mistake here is reported by CET and costs
--  nothing, whereas the redscript stack fails as a whole.
--
--  Usage: open the CET overlay, look at Judy, press "Ziel sperren", then click.
-- =====================================================================================

local MOD = "[CompanionLeashVO]"

--  print() goes to CET's console overlay ONLY; the mod log file stays empty, so nothing
--  can be handed over after a session. spdlog.info writes to
--  bin/x64/plugins/cyber_engine_tweaks/mods/CompanionLeashVO/CompanionLeashVO.log
local function log(msg)
  print(MOD .. " " .. msg)
  pcall(function() spdlog.info(MOD .. " " .. msg) end)
end

--  Workspot entity and component come from AMM, which is installed. Confirmed against
--  AMM's own database for these animations.
local WORKSPOT_ENT = "base\\amm_workspots\\entity\\workspot_anim.ent"
local WORKSPOT_COMP = "amm_workspot_base"

local WORKING = {
  { "greeting",                    "Hey V / Oh hey" },
  { "stealth_restored",            "Die haben wir abgeschuettelt" },
  { "stealth_ended",               "Da kommen sie / Achtung!" },
  { "combat_ended",                "Oh das wars, wir habens geschafft" },
  { "coop_irritation",             "Aaah!" },
  { "coop_reports_kill",           "Echt jetzt!?" },
  { "elite_warning",               "Wo haben die nur diese Ausruestung her?" },
  { "camera_warning",              "mehrere eigene Zeilen" },
  { "attack_fragile_player_order", "Hey V! Mach was, verdammte Scheisse!" },
  { "battlecry_curse",             "Fuuuuck!" },
  { "bump",                        "Was zur Hoelle?" },
  { "combat_target_hit",           "Na, wie schmeckt dir das?" },
  { "start_combat",                "funktioniert" },
  { "enemy_warning",               "funktioniert" },
  { "hit_reaction_light",          "funktioniert" },
  { "grenade_throw",               "funktioniert" },
  { "vehicle_bump",                "das kurze ...?" },
}

--  THE QUESTION THIS SECTION ANSWERS
--
--  An NCA routine is a workspot, not a scene, so it does not drive lipsync - the routine
--  schema has no lipsync or facial field at all. But several of Judy's synced animations
--  are "talk" variants, recorded as part of scenes in which she is speaking. If the mouth
--  movement is baked into the animation itself, playing it moves her mouth with no scene
--  system involved.
--
--  The controls matter as much as the talk variants: if the mouth moves on BOTH, it is
--  something else (idle chatter), and the result means nothing.
local ANIMS = {
  { "synced__v_hug_judy__talk__01__judy",   "TALK - Umarmung, sprechend" },
  { "synced__v_hug_judy__talk__03__judy",   "TALK - Umarmung, sprechend" },
  { "synced__v_holds_judy__talk__02__judy", "TALK - Halten, sprechend" },
  { "synced__v_hug_judy__01__judy",         "KONTROLLE - dieselbe Pose, nicht sprechend" },
  { "synced__v_holds_judy__01__judy",       "KONTROLLE - Halten, nicht sprechend" },
  { "stand__dance__02",                     "KONTROLLE - Tanz, sicher ohne Mimik" },
  { "alt__stand__2h_on_sides__01",          "KONTROLLE - Standard-Idle" },
}

--  Facial expressions. AnimFeature_FacialReaction takes two ints, category and idle.
--  These pairs are AMM's mapping, not guesses - see AMM init.lua GetPersonalityOptions.
--  This is expression, NOT lipsync: it moves brows, eyes and mouth shape, but does not
--  form visemes for speech.
local FACES = {
  { "Neutral",       2, 2 }, { "Joy",           3, 5 },
  { "Smile",         3, 6 }, { "Sad",           3, 3 },
  { "Surprise",      3, 8 }, { "Aggressive",    3, 2 },
  { "Anger",         3, 1 }, { "Disgust",       3, 7 },
  { "Disappointed",  3, 4 }, { "Interested",    1, 3 },
  { "Disinterested", 1, 6 }, { "Exertion",      1, 1 },
}

local showUI = false
local locked = nil
local lastPlayed = "-"
local lastAnim = "-"
local heard = {}
local pending = nil     -- waiting for the spawned workspot entity to exist
local facePending = nil -- waiting out the ResetFacial cooldown before applying
local lipDuration = 6.0    -- panel sliders; tuned by eye, not derived from anything
local lipInterval = 1.0
local lipMode = 0          -- 0 = single shot (default), 1 = duration-driven (experimental)
local lipRotIdx = 0
--  Measured: a line is reported 0.13-0.24s after the shot, and Judy's barks run 1.1-1.5s.
--  0.35s is past the report latency but still inside a line that landed, so a retry only
--  ever fires when nothing came back.
local lipRetry = 0.35
local LIP_MAX_RETRY = 1    -- a dud gets one more chance, never an open-ended barrage
--  Each suppression is switchable on its own. Changing mute and subtitle handling at the
--  same time is how you end up unable to say which one produced a result.
local optMute = true       -- DialogueVolume -> 0
local optHideOver = true   -- Overheads -> false
local optEntry = 0         -- 0 = GameObject.PlayVoiceOver, 1 = ChatterHelper.PlayVoiceOver
local lipDiag = { perceptible = false, lastLine = "-", changes = 0, readable = false,
                  lastText = "", lastDur = 0.0, lastName = "", fresh = false, kind = "-" }
local lip = nil            -- active lipsync session, see LIPSYNC ENGINE
local savedVolume = nil    -- non-nil means dialogue is currently muted BY US
local savedOverheads = nil -- non-nil means overhead subtitles are suppressed BY US
local active = nil    -- {handle, target}

local function targetName(handle)
  if not handle then return "kein Ziel" end
  local ok, name = pcall(function() return handle:GetDisplayName() end)
  if ok and name and name ~= "" then return tostring(name) end
  return "NPC"
end

local function currentTarget()
  if locked then return locked end
  local player = Game.GetPlayer()
  if not player then return nil end
  local ok, obj = pcall(function()
    return Game.GetTargetingSystem():GetLookAtObject(player, false, false)
  end)
  if ok then return obj end
  return nil
end

--  Signature taken verbatim from AMM's util.lua, which is known to work.
local function playVO(handle, vo)
  if not handle then
    log(" kein Ziel - schau eine NPC an und sperre sie")
    return
  end
  local ok, err = pcall(function()
    Game["gameObject::PlayVoiceOver;GameObjectCNameCNameFloatEntityIDBool"](
      handle, CName.new(vo), CName.new("CompanionLeashVOPanel"),
      0.0, handle:GetEntityID(), true)
  end)
  if ok then
    lastPlayed = vo
    log(" VO: " .. vo)
  else
    log(" FEHLER bei " .. vo .. ": " .. tostring(err))
  end
end

--  Mirrors AMM's Util:NPCTalk - the full combination NCA's Talk() also uses:
--  look-at, voice-over and facial reaction together. This is the closest thing to
--  "she says a line", and the test for whether any mouth movement appears at all.
local function talk(handle, vo, cat, idle)
  if not handle then
    log(" kein Ziel")
    return
  end
  local ok, err = pcall(function()
    local stim = handle:GetStimReactionComponent()
    local anim = handle:GetAnimationControllerComponent()
    if not stim or not anim then error("Komponenten fehlen") end
    stim:ResetFacial(0)
    stim:ActivateReactionLookAt(Game.GetPlayer(), false, 1, true, true)
    if vo then
      Game["gameObject::PlayVoiceOver;GameObjectCNameCNameFloatEntityIDBool"](
        handle, CName.new(vo), CName.new("CompanionLeashPanel"),
        0.0, handle:GetEntityID(), true)
    end
    -- deferred like face(), so a previous expression cannot block this one
    facePending = { target = handle, cat = cat or 3, idle = idle or 5,
                    name = tostring(vo), t = 0 }
  end)
  if ok then
    lastPlayed = (vo or "-") .. " / face " .. tostring(cat) .. "," .. tostring(idle)
    log(" TALK: " .. tostring(vo) .. "  face=" .. tostring(cat) .. "," .. tostring(idle))
  else
    log(" TALK fehlgeschlagen: " .. tostring(err))
  end
end

--  A facial feature LATCHES: applying a second one on top of a live one does nothing,
--  which is why only the first click appeared to work. AMM's sequence is the fix -
--  ResetFacial first, wait out the cooldown, then apply. Confirmed against vanilla,
--  which calls ResetFacial(0.0) itself in reactionComponent.
local function face(handle, cat, idle, name)
  if not handle then
    log(" kein Ziel")
    return
  end
  local ok, err = pcall(function()
    local stim = handle:GetStimReactionComponent()
    if stim then stim:ResetFacial(0) end
  end)
  if not ok then
    log(" ResetFacial fehlgeschlagen: " .. tostring(err))
    return
  end
  facePending = { target = handle, cat = cat, idle = idle, name = name, t = 0 }
end

--  LIPSYNC ENGINE
--
--  Confirmed by testing: muting the dialogue bus does NOT stop the lipsync. The mouth
--  still moves. So a silent VO event can drive the face while a custom line plays from
--  the SFX bus - Audioware registers its files under "sfx:", a separate bus.
--
--  Two problems that first pass had, and the one trick that fixes both:
--
--  1. Reliability. A VO event picks a random variant from a pool and some of Judy's are
--     empty, so a single fire sometimes produces nothing at all.
--  2. Duration. The mouth moves for as long as the EVENT lasts, not our line - a short
--     bark under a long sentence looks like bad dubbing.
--
--  Because the event is muted, re-firing it costs nothing audibly. So we fire on an
--  interval for as long as our line runs: a dud variant is covered by the next shot, and
--  the mouth keeps moving to the end. Overlap is free when nobody can hear it.
--
--  Two settings get changed for the window and both are restored on a timer, on shutdown
--  and by hand - the panel shows their live values:
--    /audio/volume DialogueVolume  -> 0      (global; every other line is silent too)
--    /accessibility/subtitles Overheads -> false
--  Overheads is the one that printed the muted text above her head. It only covers
--  overhead barks; Cinematic subtitles are a separate var and stay untouched.
local function settingVar(path, name)
  local ok, var = pcall(function()
    return Game.GetSettingsSystem():GetVar(path, name)
  end)
  if ok then return var end
  return nil
end

local function dialogueVar() return settingVar("/audio/volume", "DialogueVolume") end
local function overheadVar() return settingVar("/accessibility/subtitles", "Overheads") end

local LIP_MAX = 20.0 -- hard ceiling; a stuck session must not mute the game forever

--  Judy answers to these; each was heard in game and cross-checked against the log. Her
--  whole bark vocabulary is 57 files / 55 distinct lines in the voice set
--  judy_vs_vset_judy, so this is a decent slice of it, not a lucky handful.
local LIP_ROTATION = {
  "greeting", "combat_ended", "elite_warning", "stealth_ended", "stealth_restored",
  "coop_reports_kill", "coop_irritation", "camera_warning", "start_combat",
  "enemy_warning", "hit_reaction_light", "grenade_throw",
}

local function lipRestore(why)
  if savedVolume ~= nil then
    local var = dialogueVar()
    if var then pcall(function() var:SetValue(savedVolume) end) end
    savedVolume = nil
  end
  if savedOverheads ~= nil then
    local var = overheadVar()
    if var then pcall(function() var:SetValue(savedOverheads) end) end
    savedOverheads = nil
  end
  if lip then
    if lip.confirmed then
      log(string.format("  ENDE (%s) - Zeile erkannt, dauer %.2fs", why or "", lip.lineDur or 0))
    elseif optHideOver then
      log("  ENDE (" .. (why or "") .. ") - KEINE Zeile. AUSSAGELOS: Untertitel waren "
          .. "unterdrueckt, es kann nichts gemeldet werden.")
    else
      log("  ENDE (" .. (why or "") .. ") - KEINE Zeile gemeldet.")
    end
    lip = nil
  end
end

--  Two native entry points exist. ChatterHelper is the game's own chatter/bark helper
--  (cyberpunk/helpers/chatterHelper.script) and takes only instigator and event name, so
--  it may route differently from the GameObject call we have been using.
local function fireVo(handle, vo)
  if optEntry == 1 then
    local ok = pcall(function()
      Game["ChatterHelper::PlayVoiceOver;GameObjectCName"](handle, CName.new(vo))
    end)
    if not ok then log("  ChatterHelper-Aufruf fehlgeschlagen - Signatur stimmt nicht") end
    return
  end
  pcall(function()
    Game["gameObject::PlayVoiceOver;GameObjectCNameCNameFloatEntityIDBool"](
      handle, CName.new(vo), CName.new("CompanionLeashLip"),
      0.0, handle:GetEntityID(), true)
  end)
end

--  Always the same event. An earlier version rotated on retry, which changed two things
--  at once - whether a second shot helps, and whether the event matters.
local function nextVo(session)
  return session.vo
end

--  Is a voice-over from this entity audible right now? AudioSystem.VoIsPerceptible is what
--  the game's own bark-subtitle controller uses to decide whether to show a chatter line
--  (cyberpunk/UI/subtitles/chattersControllers.script), so it tracks a line actually
--  playing - which is exactly the signal we were missing.
--  questPlayVoiceset_NodeTypeParams is a native type and is not in the script dump, so
--  its fields cannot be read offline. Reflection lists them at runtime instead of me
--  guessing at them. Pattern taken from entSpawner/modules/utils/redConverter.lua.
local function inspect(typeName)
  local ok, err = pcall(function()
    local obj = NewObject(typeName)
    if not obj then log("INSPEKT " .. typeName .. ": NewObject = nil"); return end
    local cls = Reflection.GetClassOf(ToVariant(obj))
    if not cls then log("INSPEKT " .. typeName .. ": keine Klasse"); return end
    log("INSPEKT " .. typeName)
    for _, prop in pairs(cls:GetProperties()) do
      log(string.format("    %-34s %s",
          tostring(prop:GetName().value), tostring(prop:GetType():GetName().value)))
    end
  end)
  if not ok then log("INSPEKT " .. typeName .. " fehlgeschlagen: " .. tostring(err)) end
end

--  Enums cannot be built with NewObject; Reflection lists them separately. The two
--  expression/context enums are the built-in facial control on the quest voiceset node.
local function inspectEnum(name)
  local ok, err = pcall(function()
    local e = Reflection.GetEnum(name)
    if not e then log("ENUM " .. name .. ": nicht gefunden"); return end
    log("ENUM " .. name)
    --  constants come back as userdata; .value is not the accessor
    local out = {}
    for _, c in pairs(e:GetConstants()) do
      local nm
      pcall(function() nm = tostring(c:GetName().value) end)
      if not nm then pcall(function() nm = tostring(c:GetName()) end) end
      if not nm then pcall(function() nm = tostring(c.name) end) end
      out[#out + 1] = nm or tostring(c)
    end
    log("    " .. table.concat(out, ", "))
  end)
  if not ok then log("ENUM " .. name .. " fehlgeschlagen: " .. tostring(err)) end
end

--  FromVariant now yields a table but every field read nil, so either the table is empty
--  or its keys are named differently. Listing them settles which.
local function dumpDialogKeys()
  local ok, err = pcall(function()
    local defs = Game.GetAllBlackboardDefs()
    local bb = Game.GetBlackboardSystem():Get(defs.UIGameData)
    local raw = bb:GetVariant(defs.UIGameData.ShowDialogLine)
    log("BLACKBOARD ShowDialogLine: raw=" .. type(raw))
    if not raw then return end
    local v = FromVariant(raw)
    log("  entpackt=" .. type(v))
    if type(v) ~= "table" then return end
    local n = 0
    for k, val in pairs(v) do
      n = n + 1
      log(string.format("    [%s] %s", tostring(k), type(val)))
      --  array elements are the actual scnDialogLineData; list their fields via Reflection
      --  rather than probing names one at a time
      pcall(function()
        local cls = Reflection.GetClassOf(ToVariant(val))
        if not cls then return end
        log("      Klasse: " .. tostring(cls:GetName().value))
        for _, prop in pairs(cls:GetProperties()) do
          local nm = tostring(prop:GetName().value)
          local ok2, cur = pcall(function() return val[nm] end)
          log(string.format("        %-18s %-22s %s", nm,
              tostring(prop:GetType():GetName().value),
              ok2 and tostring(cur) or "<nicht lesbar>"))
        end
      end)
    end
    if n == 0 then log("    (leeres Array - es wurde nichts geschrieben)") end
  end)
  if not ok then log("BLACKBOARD-Dump fehlgeschlagen: " .. tostring(err)) end
end

local function voPerceptible(handle)
  if not handle then return false end
  local ok, res = pcall(function()
    return Game.GetAudioSystem():VoIsPerceptible(handle:GetEntityID())
  end)
  return ok and res == true
end

--  UIGameData.ShowDialogLine carries a scnDialogLineData for every displayed line,
--  overhead barks included, and is written upstream of the Overheads setting.
--
--  Reading it as tostring() was useless - that yields a fresh address every frame, which
--  is why the counter ran away. The struct itself carries what we actually need:
--
--      id : CRUID              stable per line, so a real change token
--      text : String           which line played
--      speaker : GameObject    whether it was our target
--      duration : Float        how long the mouth will move
--
--  duration is the prize: with it we do not have to poll at all, we know when the line
--  ends and can fire the next one exactly then.
local function dialogLine()
  local ok, res = pcall(function()
    local defs = Game.GetAllBlackboardDefs()
    local bb = Game.GetBlackboardSystem():Get(defs.UIGameData)
    --  GetVariant hands back a Variant (userdata). Reading .text off it gives nil - that
    --  was the bug, not the path. FromVariant unwraps it into the struct, the same way
    --  entSpawner and the fast-travel check do it.
    local raw = bb:GetVariant(defs.UIGameData.ShowDialogLine)
    if not raw then return nil end
    local arr = FromVariant(raw)
    if type(arr) ~= "table" then return nil end
    --  ShowDialogLine holds an ARRAY of scnDialogLineData, not a single struct. Reading it
    --  as a struct is why every field came back nil - the line was there the whole time.
    local el = arr[#arr]
    if el == nil then
      lipDiag.kind = "leeres Array"
      return nil
    end
    lipDiag.kind = string.format("array[%d] text=%s dur=%s",
                   #arr, type(el.text), type(el.duration))
    --  Overhead lines from passers-by land here too - one run caught a stranger's "...!"
    --  and scored it as ours. The speaker's entity id is the only reliable filter;
    --  speakerName is empty for plenty of NPCs.
    local hash = ""
    pcall(function() hash = tostring(el.speaker:GetEntityID().hash) end)
    return { text = tostring(el.text or ""),
             dur = tonumber(el.duration) or 0.0,
             name = tostring(el.speakerName or ""),
             hash = hash }
  end)
  if ok then return res end
  return nil -- struct not readable from Lua; the panel says so rather than guessing
end

local function lipStart(handle, vo, duration, interval, cat, idle)
  if not handle then
    log(" kein Ziel")
    return
  end
  local dv, ov = dialogueVar(), overheadVar()
  if not dv then
    log(" DialogueVolume nicht erreichbar")
    return
  end
  lipRestore("Neustart")

  local ok, err = pcall(function()
    if optMute then
      savedVolume = dv:GetValue()
      dv:SetValue(0)
    end
    if optHideOver and ov then
      savedOverheads = ov:GetValue()
      ov:SetValue(false)
    end
  end)
  if not ok then
    log(" Stummschalten fehlgeschlagen: " .. tostring(err))
    lipRestore("Fehler")
    return
  end

  if duration > LIP_MAX then duration = LIP_MAX end
  --  t starts at the interval so the first shot goes out on this very frame
  lip = { target = handle, vo = vo, interval = interval,
          remaining = duration, t = 0, shots = 1, retries = 0,
          confirmed = false, clock = 0, lastVo = vo, lineDur = 0 }
  lipDiag.fresh = false -- do not let a line from before the session count as ours
  fireVo(handle, vo)
  log(string.format("=== TEST  event=%s  mute=%s  untertitel_aus=%s  modus=%s  einstieg=%s",
      vo, tostring(optMute), tostring(optHideOver),
      (lipMode == 0) and "einzelschuss" or "1 neuversuch",
      (optEntry == 0) and "PlayVoiceOver" or "ChatterHelper"))
  log(string.format("  SCHUSS 1 t=0.000  %s", vo))

  if cat then
    local stim = handle:GetStimReactionComponent()
    if stim then pcall(function() stim:ResetFacial(0) end) end
    facePending = { target = handle, cat = cat, idle = idle, name = vo, t = 0 }
  end
  log(string.format("  fenster max %.1fs", duration))
end

local function stopAnim()
  if not active then return end
  pcall(function()
    Game.GetWorkspotSystem():StopInDevice(active.target)
    if active.handle then
      exEntitySpawner.Despawn(active.handle)
      active.handle:Dispose()
    end
  end)
  active = nil
end

--  Mirrors AMM's Poses:PlayAnimationOnTarget: spawn a workspot entity at the NPC,
--  yawed 180 degrees, then bind the NPC to it and jump to the animation.
local function playAnim(target, animName)
  if not target then
    log(" kein Ziel")
    return
  end
  stopAnim()

  local ok, err = pcall(function()
    local tr = target:GetWorldTransform()
    tr:SetPosition(target:GetWorldPosition())
    local angles = target:GetWorldOrientation():ToEulerAngles()
    tr:SetOrientationEuler(EulerAngles.new(0, 0, angles.yaw + 180))
    local id = exEntitySpawner.Spawn(WORKSPOT_ENT, tr, "")
    pending = { id = id, target = target, anim = animName, ticks = 0 }
  end)
  if not ok then
    log(" Spawn fehlgeschlagen: " .. tostring(err))
  end
end

registerForEvent("onUpdate", function(dt)
  --  Diagnostics run whether or not a session is active, so the two signals can be judged
  --  against what is actually happening on screen.
  local tgt = currentTarget()
  if tgt then lipDiag.perceptible = voPerceptible(tgt) end

  local dl = dialogLine()
  if dl == nil then
    lipDiag.readable = false
    lipDiag.kind = "GetVariant = nil"
  else
    lipDiag.readable = true
    --  text+duration identifies a line well enough; two identical lines back to back are
    --  indistinguishable, which costs us nothing here.
    local tok = dl.text .. "|" .. string.format("%.2f", dl.dur)
    if tok ~= lipDiag.lastLine then
      lipDiag.lastLine = tok
      lipDiag.lastText = dl.text
      lipDiag.lastDur = dl.dur
      lipDiag.lastName = dl.name
      lipDiag.lastHash = dl.hash
      lipDiag.changes = lipDiag.changes + 1
      lipDiag.fresh = true
    end
  end

  if lip then
    local d = dt or 0.016
    lip.remaining = lip.remaining - d
    if lip.remaining <= 0 then
      lipRestore("Zeitablauf")
    else
      lip.t = lip.t + d
      lip.t = lip.t + d
      lip.clock = (lip.clock or 0) + d

      --  A fresh dialog line is the only thing we treat as proof a shot landed. Its
      --  reported duration then tells us how long the mouth has work to do - no polling,
      --  and no audibility signal involved, since we muted that on purpose.
      if lipDiag.fresh then
        lipDiag.fresh = false
        local mine = true
        pcall(function()
          mine = lipDiag.lastHash == tostring(lip.target:GetEntityID().hash)
        end)
        if not mine then
          log(string.format("  (fremde Zeile ignoriert: \"%s\" [%s])",
              lipDiag.lastText, lipDiag.lastName))
        elseif not lip.confirmed then
          lip.confirmed = true
          lip.lineDur = lipDiag.lastDur
          log(string.format("  ZEILE t=%.3f  dauer=%.2f  \"%s\"  [%s]",
              lip.clock, lipDiag.lastDur, lipDiag.lastText, lipDiag.lastName))
          --  end the window when the line ends, instead of sitting on a blind timer.
          --  A muted VO request must not be strangled for 20s by our own cap.
          if lipDiag.lastDur > 0.05 then
            lip.remaining = math.min(lip.remaining, lipDiag.lastDur + 0.4)
          end
        end
      end

      --  ONE retry, and only while nothing has landed. Never re-fire after a confirmed
      --  line: that is what cut good shots off.
      if not lip.confirmed and lipMode ~= 0
         and lip.retries < LIP_MAX_RETRY and lip.t >= lipRetry then
        lip.t = 0
        lip.retries = lip.retries + 1
        lip.shots = lip.shots + 1
        local vo = nextVo(lip)
        lip.lastVo = vo
        fireVo(lip.target, vo)
        log(string.format("  SCHUSS %d t=%.3f  %s  (Neuversuch)",
            lip.shots, lip.clock, vo))
      end
    end
  end

  if facePending then
    facePending.t = facePending.t + (dt or 0.016)
    if facePending.t >= 0.5 then
      local fp = facePending
      facePending = nil
      local ok, err = pcall(function()
        local anim = fp.target:GetAnimationControllerComponent()
        if not anim then error("kein AnimationController") end
        local feat = NewObject("handle:AnimFeature_FacialReaction")
        feat.category = fp.cat
        feat.idle = fp.idle
        anim:ApplyFeature(CName.new("FacialReaction"), feat)
      end)
      if ok then
        lastPlayed = "face " .. fp.name .. " (" .. fp.cat .. "," .. fp.idle .. ")"
        log(" FACE: " .. fp.name .. " (" .. fp.cat .. "," .. fp.idle .. ")")
      else
        log(" FACE fehlgeschlagen: " .. tostring(err))
      end
    end
  end

  if not pending then return end
  pending.ticks = pending.ticks + 1
  local ent = Game.FindEntityByID(pending.id)
  if ent then
    local ok, err = pcall(function()
      Game.GetWorkspotSystem():PlayInDeviceSimple(
        ent, pending.target, false, CName.new(WORKSPOT_COMP),
        CName.new("CompanionLeashTest"), nil, 0, 1, nil)
      Game.GetWorkspotSystem():SendJumpToAnimEnt(pending.target, CName.new(pending.anim), true)
    end)
    if ok then
      active = { handle = ent, target = pending.target }
      lastAnim = pending.anim
      log(" ANIM: " .. pending.anim)
    else
      log(" Animation fehlgeschlagen: " .. tostring(err))
    end
    pending = nil
  elseif pending.ticks > 120 then
    log(" Workspot-Entitaet erschien nicht")
    pending = nil
  end
end)

registerForEvent("onOverlayOpen",  function() showUI = true end)
registerForEvent("onOverlayClose", function() showUI = false end)

registerForEvent("onDraw", function()
  if not showUI then return end

  ImGui.SetNextWindowSize(600, 660, ImGuiCond.FirstUseEver)
  if not ImGui.Begin("CompanionLeash - Test") then
    ImGui.End()
    return
  end

  local target = currentTarget()
  ImGui.Text("Ziel: " .. targetName(target))
  if locked then
    ImGui.SameLine()
    ImGui.TextColored(0.4, 1.0, 0.4, 1.0, "[gesperrt]")
  end

  if ImGui.Button(locked and "Ziel freigeben" or "Ziel sperren") then
    if locked then
      locked = nil
      log(" Ziel freigegeben")
    else
      locked = currentTarget()
      log(" Ziel gesperrt: " .. targetName(locked))
    end
  end
  ImGui.SameLine()
  ImGui.Text("VO: " .. lastPlayed .. "  |  Anim: " .. lastAnim)

  ImGui.Separator()

  if ImGui.CollapsingHeader("Lipsync-Motor") then
    local dv, ov = dialogueVar(), overheadVar()
    local dvv, ovv = "?", "?"
    if dv then dvv = tostring(dv:GetValue()) end
    if ov then ovv = tostring(ov:GetValue()) end -- NOT `ov and ... or "?"`: false would print "?"
    ImGui.Text("DialogueVolume: " .. dvv .. "   Overheads: " .. ovv)
    if savedVolume ~= nil or savedOverheads ~= nil then
      ImGui.TextColored(1.0, 0.5, 0.3, 1.0, "[von uns veraendert - laeuft]")
    end
    ImGui.TextWrapped("VoIsPerceptible misst Hoerbarkeit. Wir muten absichtlich, also ist " ..
                      "es zwangsläufig immer nein - es kann hier nichts steuern und steht " ..
                      "nur noch zur Beobachtung da.")
    ImGui.Separator()

    ImGui.Text("Dialogzeilen-Daten:")
    ImGui.SameLine()
    if lipDiag.readable then
      ImGui.TextColored(0.4, 1.0, 0.4, 1.0, "lesbar")
    else
      ImGui.TextColored(1.0, 0.5, 0.3, 1.0, "NICHT lesbar")
    end
    ImGui.SameLine()
    ImGui.TextDisabled(string.format("| %d Zeilen | VoIsPerceptible: %s",
                       lipDiag.changes, tostring(lipDiag.perceptible)))
    ImGui.TextDisabled("Variant: " .. tostring(lipDiag.kind or "-"))
    if lipDiag.readable then
      local mine = target and lipDiag.lastHash == tostring(target:GetEntityID().hash)
      ImGui.Text(string.format("zuletzt: \"%s\"", lipDiag.lastText))
      ImGui.SameLine()
      if mine then
        ImGui.TextColored(0.4, 1.0, 0.4, 1.0, "[unser Ziel]")
      else
        ImGui.TextDisabled("[fremd]")
      end
      ImGui.Text(string.format("  dauer %.2fs   sprecher: %s",
                 lipDiag.lastDur, lipDiag.lastName))
    end
    ImGui.TextDisabled("Zaehlt der Zaehler genau bei einem Schuss hoch und steht Judys " ..
                       "Text da, traegt der Weg. Laeuft er von allein hoch, nicht.")
    ImGui.Separator()

    if optHideOver then
      ImGui.TextColored(1.0, 0.5, 0.3, 1.0,
        "Erkennung unmoeglich: Untertitel sind unterdrueckt.")
    end
    if ImGui.Button("Struktur ausgeben (ins Log)") then
      inspect("questPlayVoiceset_NodeTypeParams")
      --  the params field is typed gameEntityReference, not EntityReference - that is
      --  why the previous run logged "Type 'EntityReference' not found"
      inspect("gameEntityReference")
      --  dynamicEntityUniqueName is the field that could address a spawned companion
      inspectEnum("gameEntityReferenceType")
      inspectEnum("locVoiceoverExpression")
      inspectEnum("locVoiceoverContext")
      dumpDialogKeys()
    end
    ImGui.TextDisabled("Listet die Felder des Quest-Voiceset-Knotens. Der Weg, den das " ..
                       "V Voice Framework nutzt - kein PlayVoiceOver, sondern ein " ..
                       "Quest-Knoten ueber das QuestsSystem.")
    ImGui.Separator()

    if ImGui.Button("Erkennungstest (hoerbar, mit Untertitel)") then
      optMute, optHideOver, lipMode = false, false, 0
      lipStart(target, "greeting", lipDuration, lipInterval, 3, 5)
    end
    ImGui.TextDisabled("Setzt beide Haken zurueck und feuert einmal. Beantwortet zuerst " ..
                       "die Grundfrage: wird ueberhaupt je eine Zeile gemeldet?")
    ImGui.Separator()

    ImGui.Text("Einstiegspunkt:")
    ImGui.SameLine()
    if ImGui.RadioButton("PlayVoiceOver", optEntry == 0) then optEntry = 0 end
    ImGui.SameLine()
    if ImGui.RadioButton("ChatterHelper", optEntry == 1) then optEntry = 1 end
    ImGui.Separator()

    optMute = ImGui.Checkbox("stummschalten", optMute)
    ImGui.SameLine()
    optHideOver = ImGui.Checkbox("Untertitel unterdruecken", optHideOver)
    ImGui.TextDisabled("Beide aus = normaler, hoerbarer Bark. Damit laesst sich pruefen, " ..
                       "ob ueberhaupt eine Zeile gemeldet wird - und danach einzeln, " ..
                       "welche der beiden sie verschluckt.")
    ImGui.Separator()

    if ImGui.RadioButton("Einzelschuss", lipMode == 0) then lipMode = 0 end
    ImGui.SameLine()
    if ImGui.RadioButton("1 Neuversuch (experimentell)", lipMode == 1) then lipMode = 1 end

    lipDuration = ImGui.SliderFloat("Fenster max (s)", lipDuration, 1.0, 20.0, "%.1f")
    if lipMode == 1 then
      lipRetry = ImGui.SliderFloat("Wartezeit vor Neuversuch (s)", lipRetry, 0.25, 2.5, "%.2f")
    end
    ImGui.TextDisabled("Das Fenster endet frueher, sobald eine Zeile ihre Dauer meldet.")

    if ImGui.Button("Start: greeting") then
      lipStart(target, "greeting", lipDuration, lipInterval, 3, 5)
    end
    ImGui.SameLine()
    if ImGui.Button("Start: elite_warning") then
      lipStart(target, "elite_warning", lipDuration, lipInterval, 3, 6)
    end
    ImGui.SameLine()
    if ImGui.Button("Start: combat_ended") then
      lipStart(target, "combat_ended", lipDuration, lipInterval, 3, 6)
    end

    if ImGui.Button("STOPP / Einstellungen zuruecksetzen") then
      lipRestore("manuell")
    end
    if lip then
      ImGui.SameLine()
      ImGui.Text(string.format("noch %.1fs | %d Schuss | %s",
                 lip.remaining, lip.shots, tostring(lip.lastVo or "-")))
    end
    ImGui.TextDisabled("Deckel bei " .. string.format("%.0f", LIP_MAX) .. "s")
  end

  if ImGui.CollapsingHeader("Mimik + Talk") then
    ImGui.TextWrapped("Talk = Blick + Stimme + Mimik zusammen, wie NCA es intern macht. " ..
                      "WICHTIG: dabei auf den MUND schauen. Bewegt er sich, liefern die " ..
                      "VO-Events Lipsync - das habe ich bisher nur behauptet, nie geprueft.")
    ImGui.Separator()
    if ImGui.Button("Talk: greeting + Joy") then talk(target, "greeting", 3, 5) end
    ImGui.SameLine()
    if ImGui.Button("Talk: combat_ended + Smile") then talk(target, "combat_ended", 3, 6) end
    ImGui.SameLine()
    if ImGui.Button("Talk: bump + Anger") then talk(target, "bump", 3, 1) end
    ImGui.Separator()
    ImGui.TextDisabled("nur Mimik, ohne Stimme:")
    for i, f in ipairs(FACES) do
      if ImGui.Button(f[1] .. "##f") then face(target, f[2], f[3], f[1]) end
      if i % 4 ~= 0 then ImGui.SameLine() end
    end
    ImGui.Text("")
  end

  if ImGui.CollapsingHeader("Animation - Lipsync-Test") then
    ImGui.TextWrapped("Frage: steckt die Mundbewegung in der Animation selbst? " ..
                      "TALK-Varianten mit den KONTROLLEN vergleichen. Bewegt sich der " ..
                      "Mund bei beiden, sagt das Ergebnis nichts aus.")
    ImGui.Separator()
    for _, a in ipairs(ANIMS) do
      if ImGui.Button(a[1] .. "##a") then playAnim(target, a[1]) end
      ImGui.SameLine()
      ImGui.TextDisabled(a[2])
    end
    ImGui.Separator()
    if ImGui.Button("Animation stoppen") then
      stopAnim()
      log(" Animation gestoppt")
    end
    ImGui.SameLine()
    ImGui.TextDisabled("immer stoppen, bevor die naechste startet")
  end

  if ImGui.CollapsingHeader("Voice - bestaetigt funktionierend (" .. #WORKING .. ")") then
    for _, e in ipairs(WORKING) do
      if ImGui.Button(e[1] .. "##w") then playVO(target, e[1]) end
      ImGui.SameLine()
      ImGui.TextDisabled(e[2])
    end
  end

  ImGui.End()
end)

registerForEvent("onShutdown", function()
  stopAnim()
  lipRestore("Shutdown")
end)

registerForEvent("onInit", function()
  log(" bereit - Overlay oeffnen, Judy anschauen, Ziel sperren")
end)
