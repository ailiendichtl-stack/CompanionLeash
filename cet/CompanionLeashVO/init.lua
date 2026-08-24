--  CompanionLeash - Bark-Panel
--
--  Judys Barks stehen in base/quest/secondary_characters/vsets/vset_judy.scene und werden
--  ueber einen Quest-Voiceset-Knoten gespielt, NICHT ueber GameObject.PlayVoiceOver. Das
--  ist der entscheidende Unterschied: PlayVoiceOver hat eine harte Sperre von ~8.2s pro
--  NPC (gemessen: 656 Schuesse ergaben 28 Zeilen), der Quest-Knoten hat keine.
--
--  Der Stil "invisible" unterdrueckt den Untertitel pro Aufruf, also ohne an globalen
--  Spieleinstellungen zu drehen, die danach zurueckgesetzt werden muessten.
--
--  Entfernt, weil ueberholt: die Einstiegspunkte PlayVoiceOver und ChatterHelper, die
--  Kontext-Auswahl (alle fuenf Kontexte lieferten identische Ergebnisse) und die
--  VoIsPerceptible-Anzeige (misst Hoerbarkeit, ist beim Stummschalten also immer falsch).
--  Die Messungen dazu stehen in VOICE.md.

local MOD = "[CompanionLeashVO]"

--  print() erreicht nur CETs Konsolen-Overlay; spdlog schreibt die Mod-Logdatei.
local function log(msg)
  print(MOD .. " " .. msg)
  pcall(function() spdlog.info(MOD .. " " .. msg) end)
end

--  Im Spiel vermessen. Jede Variante ist eine BESTIMMTE Zeile, kein Zufallsgriff.
local BARKS = {
  { fam = "battlecry_curse", lines = {
    { n = "battlecry_curse_var_3", d = 2.89, t = "Hey, V! Mach was, verdammte Scheisse!" },
    { n = "battlecry_curse",       d = 1.65, t = "Was zur Hoelle?" },
    { n = "battlecry_curse_var_1", d = 1.18, t = "Fuuuck!" } } },
  { fam = "battlecry_morale", lines = {
    { n = "battlecry_morale_var_1", d = 2.55, t = "Jetzt bin ich richtig sauer!" },
    { n = "battlecry_morale_var_3", d = 2.10, t = "Jetzt mach ich ernst!" },
    { n = "battlecry_morale",       d = 1.75, t = "Hast es so gewollt!" } } },
  { fam = "body_warning", lines = {
    { n = "body_warning_var_1", d = 3.15, t = "Lass uns hier klar Schiff machen, sonst fliegen wir auf." },
    { n = "body_warning_var_2", d = 2.22, t = "Versteck den Koerper, okay?" } } },
  { fam = "bump", lines = {
    { n = "bump_var_2", d = 2.01, t = "Komm schon, ernsthaft?" },
    { n = "bump_var_1", d = 1.71, t = "Hey, pass auf ..." } } },
  { fam = "camera_warning", lines = {
    { n = "camera_warning_var_1", d = 2.13, t = "Pass auf die Kameras auf, okay?" },
    { n = "camera_warning_var_2", d = 2.07, t = "Die haben hier alles im Blick." } } },
  { fam = "combat_aggro_bark", lines = {
    { n = "combat_aggro_bark_var_1", d = 1.42, t = "Echt jetzt?!" },
    { n = "combat_aggro_bark_var_2", d = 1.34, t = "Aaah!" } } },
  { fam = "combat_ended", lines = {
    { n = "combat_ended_var_1", d = 2.84, t = "Oh, das wars. Wir habens geschafft." },
    { n = "combat_ended_var_2", d = 2.83, t = "Sieh uns an. Nicht totzukriegen." } } },
  { fam = "danger", lines = {
    { n = "danger_var_1", d = 1.88, t = "Oh, Scheisse!" },
    { n = "danger_var_3", d = 1.38, t = "Bin bei dir." },
    { n = "danger",       d = 1.22, t = "Achtung!" } } },
  { fam = "detection_warning", lines = {
    { n = "detection_warning_var_1", d = 2.86, t = "Verschwinde da, sonst sehen sie uns!" },
    { n = "detection_warning_var_2", d = 2.38, t = "Vorsicht, die haben was gehoert!" } } },
  { fam = "elite_warning", lines = {
    { n = "elite_warning_var_1", d = 2.72, t = "Wo haben die nur diese Ausruestung her?" },
    { n = "elite_warning_var_2", d = 2.32, t = "Ordentlich ausgestattet, die Typen!" } } },
  { fam = "enemy_warning", lines = {
    { n = "enemy_warning_var_2", d = 2.06, t = "Sie sind hier. Bleib wachsam." },
    { n = "enemy_warning_var_1", d = 1.41, t = "Da kommen sie!" } } },
  { fam = "follow_me", lines = {
    { n = "follow_me_1", d = 2.70, t = "Was ist los? Hoer auf zu troedeln." },
    { n = "follow_me",   d = 2.26, t = "Komm schon, V, bleib bei mir." } } },
  { fam = "grapple", lines = {
    { n = "grapple", d = 3.94, t = "Ungh ... Aaargh ... Lass ... los!" } } },
  { fam = "greeting", lines = {
    { n = "greeting",       d = 1.35, t = "Oh, hey!" },
    { n = "greeting_var_2", d = 1.11, t = "Hey, V." } } },
  { fam = "grenade_enemy", lines = {
    { n = "grenade_enemy_var_3", d = 2.23, t = "In Deckung! Granate!" },
    { n = "grenade_enemy_var_2", d = 1.92, t = "Achtung, Granate!" },
    { n = "grenade_enemy_var_1", d = 1.45, t = "Granate!" } } },
  { fam = "grenade_throw", lines = {
    { n = "grenade_throw", d = 2.28, t = "Na, wie schmeckt dir das?!" } } },
  { fam = "hurry_up", lines = {
    { n = "hurry_up_var_2", d = 2.53, t = "Wir haben was vor, schon vergessen?" },
    { n = "hurry_up_var_3", d = 2.11, t = "Konzentration, V." },
    { n = "hurry_up_var_1", d = 1.90, t = "Na? Los jetzt!" } } },
  { fam = "interrupt", lines = {
    { n = "interrupt_var_1", d = 2.54, t = "Okay, wir setzen das spaeter fort." },
    { n = "interrupt",       d = 1.85, t = "Hab ich dich gelangweilt?" } } },
  { fam = "phone_urge", lines = {
    { n = "phone_urge_var_2", d = 2.68, t = "Bist du da? Kannst du mich hoeren?" },
    { n = "phone_urge_var_1", d = 1.76, t = "Aeh ... V?" } } },
  { fam = "player_fallback", lines = {
    { n = "player_fallback_var_2", d = 3.46, t = "V, pass besser auf! Tot nuetzt du niemandem!" },
    { n = "player_fallback_var_1", d = 2.84, t = "Pass auf, verdammt! Schalt dein Hirn ein." },
    { n = "player_fallback_var_3", d = 2.76, t = "Alles okay? Schnauf mal kurz durch." } } },
  { fam = "reloading", lines = {
    { n = "reloading_var_3", d = 2.07, t = "Warte kurz, muss nachladen." },
    { n = "reloading_var_2", d = 2.01, t = "Deck mich, ich lade nach!" },
    { n = "reloading_var_1", d = 1.70, t = "Ich muss nachladen." } } },
  { fam = "return_answer", lines = {
    { n = "return_answer_var_1", d = 2.00, t = "Worueber hatten wir geredet?" },
    { n = "return_answer",       d = 1.40, t = "Du bist zurueck." } } },
  { fam = "stealth_restored", lines = {
    { n = "stealth_restored_var_1", d = 2.25, t = "Perfekt, die sehen uns nicht mehr." },
    { n = "stealth_restored_var_2", d = 1.79, t = "Die haben wir abgeschuettelt." } } },
  { fam = "stealth_warning_bark", lines = {
    { n = "stealth_warning_bark_var_2", d = 1.33, t = "Vorsicht!" },
    { n = "stealth_warning_bark_var_1", d = 1.25, t = "Sei still!" } } },
  { fam = "urge", lines = {
    { n = "urge_var_1", d = 1.78, t = "Was ist mit dir los?" },
    { n = "urge",       d = 1.64, t = "Komm schon, V." } } },
}

--  Die laengsten Zeilen. Die Kette laeuft darauf, damit der Mund durchgehend bewegt wird,
--  statt eine Ein-Sekunden-Begruessung zu wiederholen.
local LONG = { "grapple", "player_fallback_var_2", "body_warning_var_1", "battlecry_curse_var_3",
               "detection_warning_var_1", "combat_ended_var_1", "player_fallback_var_1",
               "combat_ended_var_2", "player_fallback_var_3", "elite_warning_var_1",
               "follow_me_1", "phone_urge_var_2", "battlecry_morale_var_1" }

--  AMMs Zuordnung. Das Feature RASTET EIN: eine zweite Mimik auf eine laufende anzuwenden
--  bewirkt nichts, deshalb erst ResetFacial und dann verzoegert anwenden.
local FACES = {
  { "neutral", 0, 0 }, { "freundlich", 1, 1 }, { "froehlich", 2, 2 },
  { "erfreut", 3, 5 }, { "besorgt", 3, 6 }, { "traurig", 4, 3 },
  { "wuetend", 5, 4 }, { "angeekelt", 6, 7 }, { "ueberrascht", 7, 8 },
  { "veraechtlich", 8, 9 }, { "misstrauisch", 9, 10 }, { "erschoepft", 10, 11 },
}

--  Aus vset_v.scene gelesen: 266 Eintraege, hier ohne Textfragmente und
--  fremdsprachige Reste. V ist Player-POV - bei ihr zaehlen nur Text und Dauer,
--  Mundbewegung spielt keine Rolle.
local VSET_V = {
  "battlecry_curse", "battlecry_curse_var_1", "battlecry_curse_var_10",
  "battlecry_curse_var_2", "battlecry_curse_var_3", "battlecry_curse_var_4",
  "battlecry_curse_var_5", "battlecry_curse_var_6", "battlecry_curse_var_7",
  "battlecry_curse_var_8", "battlecry_curse_var_9", "character_creation",
  "combat_ally_check", "combat_ally_check_var_1", "combat_ally_check_var_2",
  "combat_ally_check_var_3", "combat_ally_cover", "combat_ally_cover_var_1",
  "combat_ally_cover_var_2", "combat_ally_cover_var_3", "combat_ally_stealth",
  "combat_ally_stealth_var_1", "combat_ally_stealth_var_2", "combat_ally_stealth_var_3",
  "combat_ally_warning", "combat_ally_warning_var_1", "combat_ally_warning_var_2",
  "combat_ally_warning_var_3", "follower_end", "follower_end_var_1", "follower_end_var_2",
  "follower_end_var_3", "generic_1", "generic_10", "generic_11", "generic_12", "generic_13",
  "generic_14", "generic_15", "generic_16", "generic_17", "generic_18", "generic_19",
  "generic_2", "generic_20", "generic_21", "generic_22", "generic_23", "generic_24",
  "generic_25", "generic_26", "generic_27", "generic_28", "generic_29", "generic_3",
  "generic_30", "generic_4", "generic_5", "generic_6", "generic_7", "generic_8", "generic_9",
  "generic_sickness", "generic_sickness_1", "generic_sickness_2", "generic_sickness_3",
  "generic_sickness_4", "gp_vehicle_destroyed", "gp_vehicle_destroyed_var_1",
  "gp_vehicle_destroyed_var_2", "gp_vehicle_reckless", "gp_vehicle_reckless_var_1",
  "gp_vehicle_reckless_var_2", "gp_vehicle_reckless_var_3", "gp_vehicle_steal",
  "gp_vehicle_steal_var_1", "gp_vehicle_steal_var_2", "gp_vehicle_steal_var_3",
  "gp_vehicle_v_hit", "gp_vehicle_v_hit_var_1", "gp_vehicle_v_hit_var_2",
  "gp_vehicle_v_hit_var_3", "hint_check", "hint_check_var_1", "hint_check_var_2",
  "hint_check_var_3", "hint_check_var_4", "interrupt_phone", "interrupt_phone_done2",
  "interrupt_phone_var_1", "interrupt_phone_var_2", "interrupt_phone_var_3",
  "interrupt_phone_var_4", "interrupt_phone_var_5", "interrupt_phone_var_6",
  "interrupt_phone_var_7", "interrupt_var_1", "interrupt_var_10", "interrupt_var_2",
  "interrupt_var_3", "interrupt_var_4", "interrupt_var_5", "interrupt_var_6",
  "interrupt_var_7", "interrupt_var_8", "interrupt_var_9", "primary_characters", "prosz",
  "reaction", "reaction_curse", "reaction_curse_var_1", "reaction_curse_var_2",
  "reaction_curse_var_3", "reaction_curse_var_4", "reaction_curse_var_5", "reaction_happy",
  "reaction_happy_var_1", "reaction_happy_var_2", "reaction_happy_var_3",
  "reaction_hostiles", "reaction_hostiles_var_1", "reaction_hostiles_var_2",
  "reaction_hostiles_var_3", "reaction_hostiles_var_4", "reaction_hostiles_var_5",
  "reaction_inspect", "reaction_inspect_var_1", "reaction_inspect_var_2",
  "reaction_inspect_var_3", "reaction_inspect_var_4", "reaction_inspect_var_5",
  "reaction_shocked", "reaction_shocked_var_1", "reaction_shocked_var_2",
  "reaction_shocked_var_3", "reaction_sickness", "reaction_sickness_01",
  "reaction_sickness_01_var_1", "reaction_sickness_01_var_2", "reaction_sickness_02",
  "reaction_sickness_02_var_1", "reaction_sickness_02_var_2", "reaction_sickness_03",
  "reaction_sickness_03_var_1", "reaction_sickness_03_var_2", "reaction_sickness_04",
  "reaction_sickness_04_var_1", "reaction_sickness_04_var_2", "reaction_sickness_05",
  "reaction_sickness_05_var_1", "reaction_sickness_05_var_2", "reaction_surprise",
  "reaction_surprise_var_1", "reaction_surprise_var_2", "reaction_surprise_var_3",
  "reaction_wtf", "reaction_wtf_var_1", "reaction_wtf_var_2", "reaction_wtf_var_3",
  "return_var_1", "return_var_10", "return_var_2", "return_var_3", "return_var_4",
  "return_var_5", "return_var_6", "return_var_7", "return_var_8", "return_var_9", "right",
  "scene_crowd", "scene_crowd_var_1", "scene_crowd_var_2", "scene_holocall_end",
  "scene_holocall_end_var_1", "scene_holocall_end_var_2", "scene_holocall_start",
  "scene_holocall_start_var_1", "scene_holocall_start_var_2", "scene_insult",
  "scene_insult_var_1", "scene_insult_var_2", "scene_insult_var_3", "scene_insult_var_4",
  "scene_insult_var_5", "scene_johnny_move", "scene_johnny_move_var_1",
  "scene_johnny_move_var_2", "scene_johnny_move_var_3", "scene_johnny_shoot",
  "scene_johnny_shoot_var_1", "scene_johnny_shoot_var_2", "scene_johnny_shoot_var_3",
  "scene_thanks", "scene_thanks_var_1", "scene_thanks_var_2", "scene_thanks_var_3", "shit",
  "spokojnie", "sts_wat_kab_04_distract_01", "take", "talk", "tego", "the", "this",
  "timelapse_output", "timelapse_var_1", "timelapse_var_2", "timelapse_var_3",
  "timelapse_var_4", "timelapse_var_5", "tylko", "ugh", "v_vs_generic_1_done",
  "v_vs_generic_6_done", "v_vs_scene_thanks_var_1_done2", "vset_v", "well", "what", "who",
  "will", "yelling_happy", "yelling_happy_var_1", "yelling_happy_var_2",
  "yelling_happy_var_3"
}

--  0 = Judy ueber ihren Tag, 1 = V ueber #player.
local speaker = 0
local sweep = nil

--  name/ziel getrennt; hint sagt, was zu erwarten ist.
local MATRIX = {
  { label = "1 danger_var_1",    name = "danger_var_1",        player = false,
    hint = "EINZIGE Frage: bewegt sich der Mund? Ton passt absichtlich nicht" },
  { label = "2 greeting_var_2",  name = "greeting_var_2",      player = false,
    hint = "Gegenprobe: unveraenderte Bark, muss Lippen bewegen" },
},
}

local STYLES, styleIdx = {}, -1
local target, targetName = nil, "-"
local facePending = nil
local chain = nil
local chainDur, chainLead = 8.0, 0.15
local muteDialogue = false
local savedVolume = nil
local lastPlayed = "-"

local function durOf(name)
  for _, g in ipairs(BARKS) do
    for _, l in ipairs(g.lines) do
      if l.n == name then return l.d end
    end
  end
  return 2.5
end

--  Originalgetreuer Nachbau des V-Voice-Framework-Aufrufs. Drei Details tragen die Sache
--  und wurden jeweils muehsam gefunden: useVoicesetSystem/playOnlyGrunt duerfen NICHT
--  gesetzt werden, die beiden override-Flags MUESSEN gesetzt werden, und die Params gehen
--  NACH der Zuweisung in node.type.
local function playBark(name)
  if speaker == 0 and not target then log("kein Ziel"); return end
  local ok, err = pcall(function()
    local node = NewObject("questVoicesetManagerNodeDefinition")
    node.type  = NewObject("questPlayVoiceset_NodeType")

    local prm = NewObject("questPlayVoiceset_NodeTypeParams")
    --  NUR die Felder setzen, die VVF setzt. useVoicesetSystem und playOnlyGrunt bleiben
    --  auf der Voreinstellung des Structs: sie ausdruecklich zu setzen war schon beim
    --  ersten Anlauf einer der Gruende, warum der Knoten gar nichts tat - und
    --  useVoicesetSystem = false beim Test eines Voicesets ist ohnehin verkehrt herum.
    prm.overrideVoiceoverExpression = true
    prm.voicesetName                = CName.new(name)
    if styleIdx >= 0 then
      prm.overrideVisualStyle = true
      pcall(function()
        prm.overridingVisualStyle = Enum.new("scnDialogLineVisualStyle", STYLES[styleIdx + 1])
      end)
    else
      prm.overrideVisualStyle = false
    end

    --  Ihre Entity traegt den Tag NCA_Companion, und Tag ist einer der vier Referenztypen -
    --  eine dynamisch gespawnte Begleiterin braucht damit keinen NodeRef.
    local ref = NewObject("gameEntityReference")
    if speaker == 1 then
      prm.isPlayer  = true
      ref.reference = CreateNodeRef("#player")
    else
      --  Ihre Entity traegt den Tag NCA_Companion, und Tag ist einer der vier
      --  Referenztypen - eine gespawnte Begleiterin braucht damit keinen NodeRef.
      prm.isPlayer = false
      ref.type  = Enum.new("gameEntityReferenceType", "Tag")
      ref.names = { CName.new("NCA_Companion") }
    end
    prm.puppetRef = ref

    node.type.params = { prm }
    log(string.format("  EXEC name=%-22s isPlayer=%-5s stil=%s",
        name, tostring(prm.isPlayer),
        (styleIdx >= 0) and STYLES[styleIdx + 1] or "kein Override"))
    Game.GetQuestsSystem():ExecuteNode(node)
    log("  EXEC zurueck: " .. name)
  end)
  lastPlayed = name
  if not ok then log("BARK " .. name .. " FEHLER: " .. tostring(err)) end
end

local function dialogueVar()
  local ok, v = pcall(function()
    return Game.GetSettingsSystem():GetVar("/audio/volume", "DialogueVolume")
  end)
  if ok then return v end
  return nil
end

local function restoreVolume(why)
  if savedVolume == nil then return end
  local v = dialogueVar()
  if v then pcall(function() v:SetValue(savedVolume) end) end
  log("DialogueVolume zurueckgesetzt (" .. tostring(savedVolume) .. ") - " .. (why or ""))
  savedVolume = nil
end

local function chainStop(why)
  restoreVolume(why or "Ende")
  if chain then
    log(string.format("KETTE Ende (%s): %d Zeilen ueber %.1fs", why or "", chain.shots, chain.clock))
    chain = nil
  end
end

local function chainStart()
  if not target then log("kein Ziel"); return end
  chainStop("Neustart")
  if muteDialogue then
    local v = dialogueVar()
    if v then
      savedVolume = v:GetValue()
      pcall(function() v:SetValue(0) end)
    end
  end
  chain = { i = 0, clock = 0, next = 0, shots = 0, remaining = chainDur }
  log(string.format("KETTE start: %.1fs, stumm=%s", chainDur, tostring(muteDialogue)))
end

local function setFace(cat, idle, label)
  if not target then log("kein Ziel"); return end
  local stim = target:GetStimReactionComponent()
  if not stim then log("keine StimReactionComponent"); return end
  pcall(function() stim:ResetFacial(0) end)
  facePending = { cat = cat, idle = idle, label = label, t = 0 }
end

registerForEvent("onInit", function()
  pcall(function()
    local e = Reflection.GetEnum("scnDialogLineVisualStyle")
    if not e then return end
    for _, c in pairs(e:GetConstants()) do
      local nm
      pcall(function() nm = tostring(c:GetName().value) end)
      if not nm then pcall(function() nm = tostring(c:GetName()) end) end
      if nm then STYLES[#STYLES + 1] = nm end
    end
  end)
  for i, nm in ipairs(STYLES) do
    if nm:lower() == "invisible" then styleIdx = i - 1 end
  end
  log(string.format("bereit - %d Stile gelesen, invisible=%s", #STYLES, tostring(styleIdx >= 0)))
  local dv = dialogueVar()
  if dv and dv:GetValue() == 0 then
    log("ACHTUNG: DialogueVolume steht auf 0 - im Panel steht ein Knopf zum Zuruecksetzen")
  end
end)

--  Liest die zuletzt angezeigte Dialogzeile. ShowDialogLine haelt ein ARRAY von
--  scnDialogLineData - als Struct gelesen ist jedes Feld nil.
local function lastLine()
  local ok, res = pcall(function()
    local defs = Game.GetAllBlackboardDefs()
    local bb   = Game.GetBlackboardSystem():Get(defs.UIGameData)
    local arr  = FromVariant(bb:GetVariant(defs.UIGameData.ShowDialogLine))
    if type(arr) ~= "table" then return nil end
    local el = arr[#arr]
    if el == nil then return nil end
    local hash = ""
    pcall(function() hash = tostring(el.speaker:GetEntityID().hash) end)
    return { text = tostring(el.text or ""), dur = tonumber(el.duration) or 0,
             name = tostring(el.speakerName or ""), hash = hash }
  end)
  if ok then return res end
  return nil
end

--  Bei V ist der Sprecher der Spieler, nicht das gesperrte Ziel.
local function expectedHash()
  local ok, h = pcall(function()
    if speaker == 1 then return tostring(Game.GetPlayer():GetEntityID().hash) end
    return tostring(target:GetEntityID().hash)
  end)
  if ok then return h end
  return nil
end

registerForEvent("onUpdate", function(dt)
  local d = dt or 0.016

  --  Sweep: jeden Namen feuern, kurz auf die Zeile warten, Ergebnis mitschreiben.
  --  Ein Treffer steht nach ~0.25s fest, ein Blindgaenger kostet nur den Timeout.
  if sweep then
    sweep.t = sweep.t + d
    if sweep.pending then
      local dl = lastLine()
      if dl and not sweep.got and dl.text ~= "" and dl.text ~= sweep.before
         and dl.hash == expectedHash() then
        sweep.got = true
        sweep.hits = sweep.hits + 1
        sweep.wait = math.max(0.4, dl.dur * 0.6)
        log(string.format("  TREFFER  %-30s %.2fs  \"%s\"",
            sweep.list[sweep.i], dl.dur, dl.text))
      end
      if sweep.t >= (sweep.got and sweep.wait or 1.3) then sweep.pending = false end
    end
    if not sweep.pending then
      sweep.i = sweep.i + 1
      if sweep.i > #sweep.list then
        styleIdx = sweep.savedStyle
        log(string.format("=== SWEEP FERTIG: %d von %d", sweep.hits, #sweep.list))
        sweep = nil
      else
        local dl = lastLine()
        sweep.before = dl and dl.text or ""
        sweep.t, sweep.got, sweep.pending = 0, false, true
        if sweep.i % 20 == 1 then
          --  grob 1.5s je Eintrag; nur zur Orientierung waehrend des Laufs
          log(string.format("  ... %d/%d, %d Treffer, noch etwa %d min",
              sweep.i, #sweep.list, sweep.hits,
              math.ceil((#sweep.list - sweep.i) * 1.5 / 60)))
        end
        playBark(sweep.list[sweep.i])
      end
    end
  end

  if facePending then
    facePending.t = facePending.t + d
    if facePending.t >= 0.5 then
      if target then
        local ok = pcall(function()
          local f = NewObject("handle:AnimFeature_FacialReaction")
          f.category = facePending.cat
          f.idle     = facePending.idle
          target:GetAnimationControllerComponent():ApplyFeature(CName.new("FacialReaction"), f)
        end)
        log("MIMIK " .. facePending.label .. (ok and "" or " FEHLER"))
      end
      facePending = nil
    end
  end

  if chain then
    chain.clock = chain.clock + d
    chain.remaining = chain.remaining - d
    if chain.remaining <= 0 then
      chainStop("Zeitablauf")
    elseif chain.clock >= chain.next then
      chain.i = (chain.i % #LONG) + 1
      local name = LONG[chain.i]
      --  kurz vor dem Ende uebergeben; mitten in der Zeile zu feuern schneidet sie ab
      chain.next = chain.clock + durOf(name) - chainLead
      chain.shots = chain.shots + 1
      playBark(name)
    end
  end
end)

registerForEvent("onShutdown", function() chainStop("Shutdown") end)

registerForEvent("onDraw", function()
  ImGui.SetNextWindowSize(620, 720, ImGuiCond.FirstUseEver)
  if not ImGui.Begin("CompanionLeash - Barks") then ImGui.End(); return end

  --  Endet eine Sitzung im Stumm-Fenster, bleibt die Lautstaerke auf 0 und landet so
  --  in den UserSettings. Timer und Shutdown-Hook helfen dann nicht mehr - das hier
  --  haengt an nichts ausser dem gelesenen Wert.
  local dv = dialogueVar()
  if dv and dv:GetValue() == 0 then
    ImGui.TextColored(1.0, 0.3, 0.3, 1.0, "DIALOGLAUTSTAERKE STEHT AUF 0")
    ImGui.TextWrapped("Vermutlich von einem Stumm-Fenster, das nicht zurueckgesetzt " ..
                      "wurde. Solange das so steht, hoerst du keinen Dialog im Spiel.")
    if ImGui.Button("auf 100 zuruecksetzen##volfix") then
      pcall(function() dv:SetValue(100) end)
      log("DialogueVolume von Hand auf 100 gesetzt")
    end
    ImGui.Separator()
  end

  ImGui.Text("Ziel: " .. targetName)
  ImGui.SameLine()
  if target then
    ImGui.TextColored(0.4, 1.0, 0.4, 1.0, "[gesperrt]")
    ImGui.SameLine()
    if ImGui.Button("freigeben") then target, targetName = nil, "-" end
  else
    if ImGui.Button("Ziel sperren (anschauen)") then
      local o = Game.GetTargetingSystem():GetLookAtObject(Game.GetPlayer(), false, false)
      if o then
        target = o
        targetName = tostring(o:GetDisplayName())
        log("Ziel gesperrt: " .. targetName)
      end
    end
  end
  ImGui.SameLine()
  ImGui.TextDisabled("zuletzt: " .. lastPlayed)
  ImGui.Separator()

  if sweep then
    ImGui.TextColored(0.4, 1.0, 0.4, 1.0, string.format(
      "SWEEP %d/%d  -  %d Treffer  -  noch etwa %d min",
      sweep.i, #sweep.list, sweep.hits,
      math.ceil((#sweep.list - sweep.i) * 1.5 / 60)))
    ImGui.ProgressBar(sweep.i / #sweep.list, 320, 18,
      string.format("%d%%", math.floor(100 * sweep.i / #sweep.list)))
    ImGui.TextDisabled("laeuft auch bei geschlossenem Overlay weiter")
    ImGui.Separator()
  end

  ImGui.Text("Sprecher:")
  ImGui.SameLine()
  if ImGui.RadioButton("Judy", speaker == 0) then speaker = 0 end
  ImGui.SameLine()
  if ImGui.RadioButton("V (Player-POV)", speaker == 1) then speaker = 1 end
  if speaker == 1 then
    ImGui.TextDisabled("V braucht kein Ziel und kein Lipsync - nur Text und Dauer.")
  end
  ImGui.Separator()

  if ImGui.CollapsingHeader("Vs Voiceset durchmessen") then
    ImGui.TextWrapped("Feuert alle " .. #VSET_V .. " Eintraege aus vset_v.scene und " ..
                      "schreibt Text und Dauer ins Log. Erzwingt dafuer einen " ..
                      "sichtbaren Untertitel-Stil - die Erkennung liest die " ..
                      "Untertiteldaten.")
    if sweep then
      ImGui.Text(string.format("laeuft: %d/%d, %d Treffer",
                 sweep.i, #sweep.list, sweep.hits))
      if ImGui.Button("abbrechen##vsweep") then
        styleIdx = sweep.savedStyle
        sweep = nil
      end
    else
      if ImGui.Button("Messung starten##vsweep") then
        speaker = 1
        sweep = { list = VSET_V, i = 0, t = 99, hits = 0, pending = false,
                  got = false, before = "", savedStyle = styleIdx }
        styleIdx = -1  -- sichtbar, sonst wird nichts gemeldet
        log(string.format("=== SWEEP ueber %d V-Eintraege, etwa %d min",
            #VSET_V, math.ceil(#VSET_V * 1.5 / 60)))
      end
      ImGui.TextDisabled("Rund 5 Minuten, unbeaufsichtigt.")
    end
  end

  if ImGui.CollapsingHeader("Testmatrix", ImGuiTreeNodeFlags.DefaultOpen) then
    ImGui.TextWrapped("Name und Ziel werden getrennt uebergeben. Ein VVF-Name auf Judy " ..
                      "waere kein aussagekraeftiger Fehlschlag - der Dispatcher waehlt " ..
                      "das Voiceset am Puppet, und VVFs Eintraege liegen in vset_v.scene.")
    ImGui.Separator()

    for _, t in ipairs(MATRIX) do
      if ImGui.Button(t.label .. "##mx") then
        speaker = t.player and 1 or 0
        for i, nm in ipairs(STYLES) do
          if nm:lower() == "regular" then styleIdx = i - 1 end
        end
        --  Vor dem Aufruf protokollieren, damit ausgeschlossen ist, dass der Knopf trotz
        --  Beschriftung einen alten Namen oder das falsche Ziel uebergibt.
        local eid = "-"
        pcall(function()
          if t.player then
            eid = tostring(Game.GetPlayer():GetEntityID().hash)
          elseif target then
            eid = tostring(target:GetEntityID().hash)
          end
        end)
        log(string.format("MATRIX  name=%-22s ziel=%-5s isPlayer=%-5s entity=%s",
            t.name, t.player and "V" or "Judy", tostring(t.player), eid))
        if not t.player and not target then
          log("        !! kein Ziel gesperrt - Aufruf uebersprungen")
        else
          playBark(t.name)
        end
      end
      ImGui.SameLine()
      ImGui.TextDisabled(t.hint)
    end
  end

  if ImGui.CollapsingHeader("Barks - 55 Zeilen") then
    for _, g in ipairs(BARKS) do
      if ImGui.TreeNode(g.fam) then
        for _, l in ipairs(g.lines) do
          if ImGui.Button(string.format("%.2fs##%s", l.d, l.n)) then playBark(l.n) end
          ImGui.SameLine()
          ImGui.Text(l.t)
        end
        ImGui.TreePop()
      end
    end
  end

  if ImGui.CollapsingHeader("Kette - durchgehende Mundbewegung") then
    ImGui.TextWrapped("Haengt die laengsten Zeilen aneinander. Grundlage fuer " ..
                      "Fake-Lipsync: stumme Barks bewegen den Mund, die eigene Zeile " ..
                      "laeuft ueber den SFX-Bus.")
    chainDur  = ImGui.SliderFloat("Dauer (s)", chainDur, 2.0, 30.0, "%.1f")
    chainLead = ImGui.SliderFloat("Vorlauf (s)", chainLead, 0.0, 0.6, "%.2f")
    muteDialogue = ImGui.Checkbox("Dialog stummschalten", muteDialogue)
    if chain then
      if ImGui.Button("STOPP") then chainStop("manuell") end
      ImGui.SameLine()
      ImGui.Text(string.format("noch %.1fs | %d Zeilen", chain.remaining, chain.shots))
    else
      if ImGui.Button("Kette starten") then chainStart() end
    end
    if savedVolume ~= nil then
      ImGui.TextColored(1.0, 0.5, 0.3, 1.0, "Dialog ist stumm - STOPP setzt zurueck.")
    end
  end

  if ImGui.CollapsingHeader("Mimik") then
    for i, f in ipairs(FACES) do
      if i % 4 ~= 1 then ImGui.SameLine() end
      if ImGui.Button(f[1]) then setFace(f[2], f[3], f[1]) end
    end
  end

  if ImGui.CollapsingHeader("Untertitel-Stil") then
    ImGui.TextWrapped("invisible unterdrueckt den Untertitel pro Aufruf, ohne an globalen " ..
                      "Spieleinstellungen zu drehen, die zurueckgesetzt werden muessten.")
    if ImGui.RadioButton("kein Override", styleIdx == -1) then styleIdx = -1 end
    for i, nm in ipairs(STYLES) do
      if i % 4 ~= 1 then ImGui.SameLine() end
      if ImGui.RadioButton(nm, styleIdx == i - 1) then styleIdx = i - 1 end
    end
  end

  ImGui.End()
end)
