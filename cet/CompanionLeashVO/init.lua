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
    print(MOD .. " kein Ziel - schau eine NPC an und sperre sie")
    return
  end
  local ok, err = pcall(function()
    Game["gameObject::PlayVoiceOver;GameObjectCNameCNameFloatEntityIDBool"](
      handle, CName.new(vo), CName.new("CompanionLeashVOPanel"),
      0.0, handle:GetEntityID(), true)
  end)
  if ok then
    lastPlayed = vo
    print(MOD .. " VO: " .. vo)
  else
    print(MOD .. " FEHLER bei " .. vo .. ": " .. tostring(err))
  end
end

--  Mirrors AMM's Util:NPCTalk - the full combination NCA's Talk() also uses:
--  look-at, voice-over and facial reaction together. This is the closest thing to
--  "she says a line", and the test for whether any mouth movement appears at all.
local function talk(handle, vo, cat, idle)
  if not handle then
    print(MOD .. " kein Ziel")
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
    print(MOD .. " TALK: " .. tostring(vo) .. "  face=" .. tostring(cat) .. "," .. tostring(idle))
  else
    print(MOD .. " TALK fehlgeschlagen: " .. tostring(err))
  end
end

--  A facial feature LATCHES: applying a second one on top of a live one does nothing,
--  which is why only the first click appeared to work. AMM's sequence is the fix -
--  ResetFacial first, wait out the cooldown, then apply. Confirmed against vanilla,
--  which calls ResetFacial(0.0) itself in reactionComponent.
local function face(handle, cat, idle, name)
  if not handle then
    print(MOD .. " kein Ziel")
    return
  end
  local ok, err = pcall(function()
    local stim = handle:GetStimReactionComponent()
    if stim then stim:ResetFacial(0) end
  end)
  if not ok then
    print(MOD .. " ResetFacial fehlgeschlagen: " .. tostring(err))
    return
  end
  facePending = { target = handle, cat = cat, idle = idle, name = name, t = 0 }
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
    print(MOD .. " kein Ziel")
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
    print(MOD .. " Spawn fehlgeschlagen: " .. tostring(err))
  end
end

registerForEvent("onUpdate", function(dt)
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
        print(MOD .. " FACE: " .. fp.name .. " (" .. fp.cat .. "," .. fp.idle .. ")")
      else
        print(MOD .. " FACE fehlgeschlagen: " .. tostring(err))
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
      print(MOD .. " ANIM: " .. pending.anim)
    else
      print(MOD .. " Animation fehlgeschlagen: " .. tostring(err))
    end
    pending = nil
  elseif pending.ticks > 120 then
    print(MOD .. " Workspot-Entitaet erschien nicht")
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
      print(MOD .. " Ziel freigegeben")
    else
      locked = currentTarget()
      print(MOD .. " Ziel gesperrt: " .. targetName(locked))
    end
  end
  ImGui.SameLine()
  ImGui.Text("VO: " .. lastPlayed .. "  |  Anim: " .. lastAnim)

  ImGui.Separator()

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
      print(MOD .. " Animation gestoppt")
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
end)

registerForEvent("onInit", function()
  print(MOD .. " bereit - Overlay oeffnen, Judy anschauen, Ziel sperren")
end)
