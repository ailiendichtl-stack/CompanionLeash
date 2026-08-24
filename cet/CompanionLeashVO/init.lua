-- =====================================================================================
--  CompanionLeash - VO test panel
-- =====================================================================================
--  Manual counterpart to the redscript spike. The automated test cycled through events
--  on a timer, which left two ambiguities: which slot a sound belonged to, and whether a
--  silent slot meant "no recording" or just "this variant happened to be empty".
--
--  Clicking a button removes both. You hear it or you do not, immediately, and you can
--  press the same one repeatedly to shake out variants.
--
--  Lua rather than redscript on purpose: no compile risk to the redscript stack at all.
--  If this file has a syntax error, CET reports it and everything else keeps working.
--
--  Usage: open the CET overlay, look at Judy, press "Ziel sperren", then click events.
-- =====================================================================================

local MOD = "[CompanionLeashVO]"

--  Confirmed by ear across three automated rounds. Listed so the panel doubles as a
--  reference, and so re-testing them is one click if a mapping ever looks wrong.
local WORKING = {
  { "greeting",                    "Hey V / Oh hey" },
  { "stealth_restored",            "Die haben wir abgeschuettelt" },
  { "stealth_ended",               "Da kommen sie / Achtung!" },
  { "combat_ended",                "Oh das wars, wir habens geschafft" },
  { "coop_irritation",             "Aaah!" },
  { "coop_reports_kill",           "Echt jetzt!?" },
  { "sniper_warning",              "Wo haben die nur diese Ausruestung her?" },
  { "attack_fragile_player_order", "Hey V! Mach was, verdammte Scheisse!" },
  { "battlecry_curse",             "Fuuuuck!" },
  { "bump",                        "Was zur Hoelle?" },
  { "combat_target_hit",           "Na, wie schmeckt dir das?" },
}

--  Silent in the automated rounds. This is the list worth re-checking by hand: a timed
--  test can miss an event whose variants were empty on that pass.
local SILENT = {
  "danger", "stlh_curious_grunt", "stlh_call", "stlh_death",
  "enemy_warning", "start_combat", "start_dead", "crowd_combat",
  "shove", "fear_beg", "fear_run", "hit_reaction_heavy",
  "hit_reaction_light", "hit_grapple", "vo_any_damage_hit", "grenade_throw",
  "heavy_reloading", "hmg_charge", "pedestrian_hit", "vehicle_bump",
  "octant_warning", "turret_warning", "camera_warning", "drones_warning",
  "netrunner_warning", "mech_warning", "elite_warning", "heavy_warning",
  "cpo_armor_broken", "cpo_got_data", "cpo_nearly_dead",
  "following", "waiting",
}

local showUI = false
local locked = nil
local lastPlayed = "-"
local heard = {}

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

--  Signature taken verbatim from AMM's util.lua, which is known to work:
--  Game["gameObject::PlayVoiceOver;GameObjectCNameCNameFloatEntityIDBool"]
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
    print(MOD .. " played: " .. vo)
  else
    print(MOD .. " FEHLER bei " .. vo .. ": " .. tostring(err))
  end
end

registerForEvent("onOverlayOpen",  function() showUI = true end)
registerForEvent("onOverlayClose", function() showUI = false end)

registerForEvent("onDraw", function()
  if not showUI then return end

  ImGui.SetNextWindowSize(560, 620, ImGuiCond.FirstUseEver)
  if not ImGui.Begin("CompanionLeash - VO Test") then
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
  ImGui.Text("zuletzt: " .. lastPlayed)

  ImGui.Separator()
  ImGui.TextWrapped("Sperre Judy als Ziel, dann klicke Events. Haken setzen bei allem, " ..
                    "was klingt - die Liste unten wird beim Beenden ins Log geschrieben.")
  ImGui.Separator()

  if ImGui.CollapsingHeader("Bestaetigt funktionierend (" .. #WORKING .. ")") then
    for _, e in ipairs(WORKING) do
      if ImGui.Button(e[1] .. "##w") then playVO(target, e[1]) end
      ImGui.SameLine()
      ImGui.TextDisabled(e[2])
    end
  end

  if ImGui.CollapsingHeader("Bisher still - bitte pruefen (" .. #SILENT .. ")") then
    ImGui.TextWrapped("Mehrfach klicken lohnt sich: einzelne Varianten koennen leer sein.")
    ImGui.Separator()
    for i, name in ipairs(SILENT) do
      if ImGui.Button(name .. "##s") then playVO(target, name) end
      ImGui.SameLine()
      local was = heard[name] and true or false
      local newv, changed = ImGui.Checkbox("gehoert##" .. name, was)
      if changed then
        heard[name] = newv or nil
        print(MOD .. " markiert: " .. name .. " = " .. tostring(newv))
      end
      if i % 2 == 1 then ImGui.SameLine() end
    end
  end

  ImGui.Separator()
  if ImGui.Button("Markierte ins Log schreiben") then
    local any = false
    for name, _ in pairs(heard) do
      print(MOD .. " HEARD " .. name)
      any = true
    end
    if not any then print(MOD .. " nichts markiert") end
  end

  ImGui.End()
end)

registerForEvent("onInit", function()
  print(MOD .. " bereit - CET-Overlay oeffnen, Judy anschauen, Ziel sperren")
end)
