--  Die Ausloeser. Jeder beobachtet einen Zustand und stellt Antraege beim Sprecher.
--
--  Keiner spielt selbst ab, keiner kennt Voiceset-Namen, keiner fuehrt eine eigene
--  Belegt-Fahne. Sie kennen nur ihren Pool und ihre Bedingungen; wann tatsaechlich geredet
--  wird, entscheidet `speaker.lua` allein.
--
--  Einen neuen Ausloeser anzulegen heisst: eine Beobachtung schreiben und
--  `Speaker.Request` aufrufen. Die Zeilen kommen aus `lines.lua`, das die Matrix erzeugt -
--  hier steht kein einziger Zeilentext.

local T = {}

local Speaker, LINES, log, holeZiel

--  ---------------------------------------------------------------- gemeinsame Hilfen

--  Laeuft eine Spielsitzung? Im Hauptmenue und waehrend des Ladens gibt es keinen Spieler,
--  und ein nil an eine native Funktion zu reichen faengt kein pcall ab - das nimmt den
--  Prozess mit. Genau daran ist der erste Anlauf gestorben.
local function spieler()
  local vor = true
  local ok = pcall(function() vor = Game.GetSystemRequestsHandler():IsPreGame() end)
  if not ok or vor then return nil end
  local p
  pcall(function() p = Game.GetPlayer() end)
  return p
end

local function imSpiel()
  return spieler() ~= nil
end

--  Ein Wert aus der Spieler-Zustandsmaschine.
--
--  `Game.GetPlayer():IsInCombat()` sah naheliegend aus und lieferte nie etwas - der Aufruf
--  scheiterte, das pcall schluckte es, und der Kampf-Ausloeser blieb still. Nichts im
--  Protokoll, weil ich nur Zustandswechsel schreibe, und Wechsel gab es nie.
--
--  Darum zwei Dinge: das Blackboard statt der Skriptfunktion, und eine Sonde, die ihren
--  ERSTEN Fehlschlag meldet. Eine Abfrage, die stumm nichts liefert, kostet mehr Zeit als
--  jeder laute Fehler.
local sondeTot = {}

local function psm(feld)
  local p = spieler()
  if not p then return nil end
  local wert, ok = nil, false
  pcall(function()
    local defs = Game.GetAllBlackboardDefs()
    local bb = Game.GetBlackboardSystem():GetLocalInstanced(
                 p:GetEntityID(), defs.PlayerStateMachine)
    if bb then
      wert = bb:GetInt(defs.PlayerStateMachine[feld])
      ok = wert ~= nil
    end
  end)
  if not ok and not sondeTot[feld] then
    sondeTot[feld] = true
    log("SONDE PlayerStateMachine." .. feld .. " nicht lesbar")
  end
  return wert
end

--  Alle Eintraege einer Situation, wahlweise nur einer Stufe.
local function pool(situation, stufe)
  local p = {}
  for _, l in ipairs(LINES) do
    if l.s == situation and (not stufe or l.st == stufe) then p[#p + 1] = l end
  end
  return p
end

--  Ist das Judy?
--
--  Zwei naheliegende Wege sind im Spiel durchgefallen, und beide schweigend:
--
--    `TDBID.ToStringDBID` braucht aufgeloeste TweakDB-Namen. Fehlen sie, kommt gar nichts
--    zurueck - im Panel stand `record=?`.
--
--    `GetDisplayName` liefert bei ihr `LocKey#47008`, nicht "Judy". Der Name steht in der
--    Lokalisierung und muss erst nachgeschlagen werden.
--
--  Darum wird die Record-Id jetzt als ZAHL verglichen, gegen `Character.Judy` - das ist
--  die Id, unter der NCA sie fuehrt. Keine Namensaufloesung, keine Sprache, kein Debugname.
--  Der aufgeloeste LocKey und das gesperrte Panel-Ziel bleiben als Rueckfallebenen.
local JUDY = nil
pcall(function() JUDY = TweakDBID.new("Character.Judy") end)

local function idGleich(a, b)
  if not a or not b then return false end
  local x, y
  pcall(function() x = string.format("%s:%s", tostring(a.hash), tostring(a.length)) end)
  pcall(function() y = string.format("%s:%s", tostring(b.hash), tostring(b.length)) end)
  return x ~= nil and x == y
end

--  Anzeigename, notfalls ueber die Lokalisierung aufgeloest.
local function klarname(o)
  local n = "?"
  pcall(function() n = tostring(o:GetDisplayName()) end)
  if n:find("LocKey", 1, true) then
    local k = n
    pcall(function()
      local t = Game.GetLocalizedText(k)
      if t and t ~= "" then n = tostring(t) end
    end)
  end
  return n
end

local function beschreibe(o)
  local rec = "?"
  pcall(function()
    local r = o:GetRecordID()
    if r then rec = string.format("%s:%s", tostring(r.hash), tostring(r.length)) end
  end)
  return rec, klarname(o)
end

local function istJudy(o)
  if not o then return false end

  local ziel = holeZiel and holeZiel() or nil
  if ziel then
    local a, b
    pcall(function() a = tostring(ziel:GetEntityID().hash) end)
    pcall(function() b = tostring(o:GetEntityID().hash) end)
    if a and a == b then return true end
  end

  local r
  pcall(function() r = o:GetRecordID() end)
  if idGleich(r, JUDY) then return true end

  if klarname(o):lower():find("judy", 1, true) then return true end

  --  Frueher stand hier ein Eintrag je unbekanntem Objekt. Das hat die Erkennung
  --  aufgeklaert, aber Night City hat Tausende Entitaeten, und 75 von 160 Zeilen waren
  --  Autos und Passanten. Was jetzt zaehlt, steht im Panel unter "anvisiert" - live und
  --  ohne Protokoll.
  return false
end

--  ---------------------------------------------------------------- Der lange Blick

local GAZE = {
  stufe1  =    5.0,   -- ab hier merkt sie es
  stufe2  =   14.0,   -- ab hier nimmt sie es auf
  cd1     =  180.0,   -- Abklingzeit der beilaeufigen Reaktion
  cd2     = 1800.0,   -- die zweite Ebene hoechstens halbstuendlich
  distanz =    8.0,   -- ueber die Strasse hinweg ist kein Anschauen
}
--  s1/s2 gehoeren dem Blick: sie verhindern, dass er innerhalb EINES Blicks nachlegt.
--  Belegt-Sein und Abklingzeiten fuehrt der Sprecher.
local gaze = { t = 0.0, id = nil, s1 = false, s2 = false, an = true, zuletzt = "-" }

local function gazeFeuern(obj)
  local stufe
  if not gaze.s2 and gaze.t >= GAZE.stufe2 then
    stufe = 2
  elseif not gaze.s1 and gaze.t >= GAZE.stufe1 then
    stufe = 1
  end
  if not stufe then return end

  --  Ob angenommen oder nicht: innerhalb dieses Blicks nicht noch einmal anfragen. Ohne
  --  das stellt der Ausloeser in jedem Frame denselben Antrag, solange V hinsieht.
  if stufe == 2 then gaze.s1, gaze.s2 = true, true else gaze.s1 = true end

  local k = pool("blick", stufe)
  if #k == 0 then
    log(string.format("BLICK Stufe %d - kein Eintrag mit st=%d in lines.lua", stufe, stufe))
    return
  end
  log(string.format("BLICK Stufe %d nach %.1fs, %d Kandidaten", stufe, gaze.t, #k))
  Speaker.Request({
    situation  = "blick",
    pool       = "blick" .. stufe,
    kandidaten = k,
    cd         = (stufe == 2) and GAZE.cd2 or GAZE.cd1,
    ziel       = obj,
  })
  gaze.zuletzt = string.format("Stufe %d, %d Kandidaten", stufe, #k)
end

local function gazeTick(d, p)
  if not gaze.an then return end
  local ts
  pcall(function() ts = Game.GetTargetingSystem() end)
  if not ts then return end
  local o
  pcall(function() o = ts:GetLookAtObject(p, false, false) end)

  local passt = istJudy(o)
  if passt then
    if psm("Combat") == 1 then passt = false end
  end
  if passt then
    local dist = 999.0
    pcall(function()
      dist = Vector4.Distance(p:GetWorldPosition(), o:GetWorldPosition())
    end)
    if dist > GAZE.distanz then passt = false end
  end

  if passt then
    local id = tostring(o:GetEntityID().hash)
    if id ~= gaze.id then
      gaze.id, gaze.t, gaze.s1, gaze.s2 = id, 0.0, false, false
    end
    gaze.t = gaze.t + d
    gazeFeuern(o)
  elseif gaze.id then
    --  Wegsehen setzt die Uhr zurueck. Sonst liesse sich die Schwelle aus lauter kurzen
    --  Blicken zusammensammeln, und das ist nicht dasselbe wie jemanden anzusehen.
    gaze.id, gaze.t, gaze.s1, gaze.s2 = nil, 0.0, false, false
  end
end

--  ---------------------------------------------------------------- Kampf

local KAMPF = {
  anlauf   =  2.0,    -- erst ein Moment Gefecht, dann redet sie
  waehrend = 30.0,    -- Abstand zwischen Zeilen im laufenden Kampf
  nachlauf =  2.5,    -- nach dem letzten Schuss, bevor sie es kommentiert
  cd_ende  = 45.0,    -- damit ein zweiter Schwung nicht sofort wieder quittiert wird
}
local kampf = { drin = false, seit = 0.0, seitEnde = nil, an = true }

local function kampfTick(d)
  if not kampf.an then return end
  --  gamePSMCombat: 0 Default, 1 InCombat, 2 OutOfCombat, 3 Stealth
  local drin = psm("Combat") == 1

  if drin and not kampf.drin then
    kampf.drin, kampf.seit, kampf.seitEnde = true, 0.0, nil
    log("KAMPF beginnt")
  elseif not drin and kampf.drin then
    kampf.drin, kampf.seitEnde = false, 0.0
    --  Was noch fuer den Kampf anstand, ist keine Kampfzeile mehr.
    Speaker.Verwerfen("kampf")
    log("KAMPF vorbei")
  end

  if kampf.drin then
    kampf.seit = kampf.seit + d
    --  Erst fragen, wenn es auch etwas werden kann. Sonst prallt alle zwei Sekunden ein
    --  Antrag an der Abklingzeit ab und begraebt die echten Ablehnungen im Protokoll.
    if kampf.seit >= KAMPF.anlauf and Speaker.Frei("kampf") then
      local k = pool("kampf")
      if #k > 0 then
        Speaker.Request({ situation = "kampf", pool = "kampf",
                          kandidaten = k, cd = KAMPF.waehrend })
      end
      kampf.seit = 0.0
    end
    return
  end

  if kampf.seitEnde then
    kampf.seitEnde = kampf.seitEnde + d
    if kampf.seitEnde >= KAMPF.nachlauf then
      kampf.seitEnde = nil
      local k = pool("kampf_ende")
      if #k > 0 then
        Speaker.Request({ situation = "kampf_ende", pool = "kampf_ende",
                          kandidaten = k, cd = KAMPF.cd_ende })
      end
    end
  end
end

--  ---------------------------------------------------------------- aussen

function T.Init(opts)
  Speaker  = opts.speaker
  LINES    = opts.lines or {}
  log      = opts.log or function() end
  holeZiel = opts.ziel
end

--  Fuer das Panel: was sieht V gerade an?
function T.Anvisiert()
  local p = spieler()
  if not p then return nil end
  local o
  pcall(function()
    o = Game.GetTargetingSystem():GetLookAtObject(p, false, false)
  end)
  if not o then return nil end
  local rec, name = beschreibe(o)
  return { name = name, record = rec, judy = istJudy(o),
           judyRecord = JUDY and string.format("%s:%s", tostring(JUDY.hash),
                                               tostring(JUDY.length)) or nil }
end

function T.Tick(d)
  if not Speaker then return end
  local p = spieler()
  if not p then return end
  gazeTick(d, p)
  kampfTick(d)
end

function T.Status()
  return {
    gaze  = { an = gaze.an, t = gaze.t, aktiv = gaze.id ~= nil, zuletzt = gaze.zuletzt,
              stufe1 = GAZE.stufe1, stufe2 = GAZE.stufe2,
              n1 = #pool("blick", 1), n2 = #pool("blick", 2) },
    kampf = { an = kampf.an, drin = kampf.drin, seit = kampf.seit,
              n = #pool("kampf"), nEnde = #pool("kampf_ende") },
  }
end

function T.Setzen(was, an)
  if was == "blick" then gaze.an = an end
  if was == "kampf" then kampf.an = an end
end

function T.Zuruecksetzen()
  gaze.s1, gaze.s2, gaze.t, gaze.id = false, false, 0.0, nil
  kampf.seit = 0.0
end

return T
