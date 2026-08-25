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

local Speaker, LINES, log, holeZiel, letzteZeile

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

--  Eine Abfrage, die still nichts liefert, kostet mehr Zeit als jeder laute Fehler -
--  genau daran ist der Kampf-Ausloeser einen ganzen Abend lang gescheitert. Jede Sonde
--  meldet darum ihren ersten Fehlschlag, danach schweigt sie.
--  `nilIstOk`, weil nil oft die richtige Antwort ist: wer nicht im Wagen sitzt, hat kein
--  Fahrzeug. Ohne die Unterscheidung meldet die Sonde einen Fehlschlag, wo nur nichts war -
--  und eine Warnung, die faelschlich kommt, macht die echten wertlos.
local function sonde(name, fn, nilIstOk)
  local wert
  local ok = pcall(function() wert = fn() end)
  if not ok or (wert == nil and not nilIstOk) then
    if not sondeTot[name] then
      sondeTot[name] = true
      log("SONDE " .. name .. (ok and " liefert nichts" or " nicht aufrufbar"))
    end
  end
  return wert
end

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

--  ---------------------------------------------------------------- Wo ist Judy

--  Eine Referenz auf sie, die sich selbst instand haelt.
--
--  Zwei Quellen liefern sie beilaeufig: der Blick, sobald V sie ansieht, und der
--  Untertitel, sobald sie etwas sagt - dort steht das Sprecherobjekt, nicht nur ein Name.
--  Beides passiert oft genug, dass eine verlorene Referenz von selbst zurueckkommt.
--
--  Gehalten wird sie nur, solange `IsAttached` das bestaetigt. NCA despawnt Begleiter bei
--  Entfernung und in gesperrten Zonen; eine Referenz auf eine abgeraeumte Entity waere
--  genau die Art Nullzeiger, die dieses Projekt schon zweimal abgestuerzt hat.
local judy = { obj = nil, dist = nil }

local function judyMerken(o)
  if o then judy.obj = o end
end

local function judyHolen()
  if not judy.obj then return nil end
  local da = false
  pcall(function() da = judy.obj:IsAttached() end)
  if not da then
    judy.obj, judy.dist = nil, nil
    return nil
  end
  return judy.obj
end

--  Abstand V zu Judy, oder nil wenn sie gerade nicht greifbar ist.
local function abstand(p)
  local o = judyHolen()
  if not o or not p then judy.dist = nil; return nil end
  local w
  pcall(function() w = Vector4.Distance(p:GetWorldPosition(), o:GetWorldPosition()) end)
  judy.dist = w
  return w
end

--  ---------------------------------------------------------------- Judys eigene Stimme

--  Die Spiel-KI laesst Judy im Gefecht selbst reden - dieselbe Voiceset-Infrastruktur, die
--  wir benutzen. Wer da dazwischenspricht, ersetzt ihre Zeile statt sie zu ergaenzen.
--
--  Eine direkte Abfrage "spricht sie gerade" gibt es nicht. Was es gibt, ist der
--  Untertitel: `UIGameData.ShowDialogLine` fuehrt die zuletzt gezeigte Zeile samt Sprecher
--  und Dauer. Erscheint dort eine Zeile von ihr, waehrend WIR nichts gestartet haben, war
--  es die KI.
--
--  Nebenbei loest das ein zweites Problem: laeuft eine unserer Zeilen, ist der Sprecher im
--  Untertitel zwangslaeufig sie - so lernen wir ihre Entity-Id, ohne sie ansehen zu muessen.
local stimme = { judyId = nil, letzter = "", zuletztFremd = "-" }

local function stimmeTick()
  if not letzteZeile then return end
  local dl = letzteZeile()
  if not dl or dl.text == "" or dl.text == stimme.letzter then return end
  stimme.letzter = dl.text

  --  Frueher wurde hier ihr Entity-Hash gelernt, sobald eine unserer Zeilen lief. Das
  --  ging schief: erscheint in diesem Moment ein fremder Untertitel - eine Werbetafel
  --  reicht -, wird dessen Sprecher als Judy gemerkt, und danach sperrt uns jede Reklame.
  --  Im Protokoll stand dann "Judy spricht selbst: Kumquat fuer die Seele."
  --
  --  Es gibt eine sichere Pruefung, und die stand schon da: die Record-Id.
  if not istJudy(dl.obj) then return end
  judyMerken(dl.obj)
  pcall(function() stimme.judyId = tostring(dl.obj:GetEntityID().hash) end)
  if Speaker.Spricht() then return end

  Speaker.Fremd(dl.dur)
  stimme.zuletztFremd = dl.text
  log(string.format("FREMD Judy spricht selbst (%.1fs): %s", dl.dur or 0, dl.text))
end

--  ---------------------------------------------------------------- Der lange Blick

local GAZE = {
  stufe1  =   10.0,   -- ab hier merkt sie es
  stufe2  =   30.0,   -- ab hier nimmt sie es auf
  cd1     =  300.0,   -- Abklingzeit der beilaeufigen Reaktion
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
    stimme.judyId = id
    judyMerken(o)
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

--  ---------------------------------------------------------------- Die Leiter

--  Wenn V stehen bleibt, faengt sie irgendwann von selbst an.
--
--  Der erste Entwurf mass Ruhe - wie lange nichts gesagt wurde. Das war das falsche Mass.
--  Bewegung ist Aktivitaet: wer gerade durch die Stadt gelaufen ist, steht nicht seit acht
--  Minuten herum, auch wenn niemand geredet hat. Gemessen wird darum STILLSTAND, und jede
--  Bewegung setzt die Leiter auf die erste Sprosse zurueck.
--
--  Ruhe bleibt trotzdem eine Sperre, nur eben nicht die Uhr: sie soll sich nicht selbst
--  hinterherreden, wenn eben erst etwas anderes lief.
--
--  Die Sprossen wachsen. Gleiche Abstaende erzeugen ein Ticken, und ein Ticken merkt man
--  beim dritten Mal. Ist die letzte gespielt, bleibt sie still, bis V sich bewegt.
--  `cd` je Sprosse, nicht global. Sprosse eins ist die billigste und wuerde sich sonst
--  bei "ein Schritt, warten, ein Schritt, warten" alle halbe Minute wiederholen.
local LEITER = {
  { steht =  25.0, pool = "reibung",    cd = 120.0 },   -- V steht rum: Ungeduld
  { steht =  75.0, pool = "alltag",     cd =  60.0 },   -- laenger: Smalltalk
  { steht = 180.0, pool = "initiative", cd =  60.0 },   -- sehr lange: sie faengt etwas an
}
--  In Metern JE SEKUNDE. Der erste Anlauf verglich die Strecke EINES BILDES mit einem
--  festen Wert; bei 60 Bildern waren das knapp ein Meter pro Bild, und damit haette
--  Sprinten noch als Stehen gezaehlt. 0,5 m/s ist langsamer als Schleichen.
local STILL_TEMPO = 0.5
local RUHE_MIN    = 15.0   -- so lange muss sie mindestens geschwiegen haben
--  Karenz: erst ANHALTENDE Bewegung setzt die Leiter zurueck. Sich umzudrehen oder einen
--  Schritt zur Seite zu machen ist kein Weitergehen - ohne die Karenz reichte eine
--  Sekunde, um von vorn zu beginnen, und dann faengt sie alle 25 s wieder an.
local KARENZ      = 4.0
local leiter = { stufe = 1, an = true, stehtSeit = 0.0, bewegtSeit = 0.0, letztePos = nil }

local function leiterTick(d, p)
  if not leiter.an then return end

  --  Im Gefecht und im Wagen hat sie anderes zu tun, und "stehen" heisst dort nichts.
  local imWagen = sonde("GetMountedVehicle", function() return Game.GetMountedVehicle(p) end,
                        true)
  if psm("Combat") == 1 or imWagen ~= nil then
    leiter.stufe, leiter.stehtSeit, leiter.bewegtSeit = 1, 0.0, 0.0
    return
  end

  local pos
  pcall(function() pos = p:GetWorldPosition() end)
  if pos and leiter.letztePos then
    local w = 0.0
    pcall(function() w = Vector4.Distance(pos, leiter.letztePos) end)
    local tempo = (d > 0.0) and (w / d) or 0.0
    if tempo > STILL_TEMPO then
      --  Waehrend der Karenz laeuft die Standuhr weder weiter noch zurueck: ein Schritt
      --  ist kein Stehen, aber auch kein Weitergehen.
      leiter.bewegtSeit = leiter.bewegtSeit + d
      if leiter.bewegtSeit >= KARENZ then
        leiter.stufe, leiter.stehtSeit = 1, 0.0
      end
    else
      leiter.bewegtSeit = 0.0
      leiter.stehtSeit = leiter.stehtSeit + d
    end
  end
  leiter.letztePos = pos

  local st = LEITER[leiter.stufe]
  if not st then return end
  if leiter.stehtSeit < st.steht then return end
  if Speaker.StillSeit() < RUHE_MIN then return end

  local k = pool(st.pool)
  if #k == 0 or not Speaker.Frei(st.pool) then return end
  log(string.format("LEITER Sprosse %d nach %.0fs Stillstand, Pool %s (%d)",
      leiter.stufe, leiter.stehtSeit, st.pool, #k))
  Speaker.Request({ situation = "leiter", prio = Speaker.PRIO.alltag,
                    pool = st.pool, kandidaten = k, cd = st.cd or 60.0 })
  leiter.stufe = leiter.stufe + 1
end

--  ---------------------------------------------------------------- Warten und Troedeln

--  Zwei Schwellen statt einer. Eine einzelne wuerde flattern, sobald V an der Grenze
--  entlanglaeuft: ein Schritt hin, ein Schritt zurueck, und sie faengt jedes Mal neu an.
--  Ausgeloest wird ueber `weit`, zurueckgesetzt erst unter `nah`.
--
--  Und es muss ANHALTEN. Kurz durch eine Tuer zu gehen ist kein Zuruecklassen; sechs
--  Sekunden Abstand sind eins.
local REIBUNG = {
  nah    =  6.0,
  weit   = 10.0,
  geduld =  6.0,
  cd     = 90.0,
}
local reibung = { seit = 0.0, an = true }

local function reibungTick(d, p)
  if not reibung.an then return end

  --  Im Wagen ist Abstand normal, im Gefecht redet sie ueber anderes.
  local imWagen = sonde("GetMountedVehicle", function() return Game.GetMountedVehicle(p) end,
                    true)
  if imWagen ~= nil or psm("Combat") == 1 then
    reibung.seit = 0.0
    return
  end

  local w = judy.dist
  if not w then reibung.seit = 0.0; return end

  if w < REIBUNG.nah then
    reibung.seit = 0.0
    return
  end
  if w < REIBUNG.weit then
    --  Zwischen nah und weit passiert nichts, aber die Uhr laeuft auch nicht zurueck.
    return
  end

  reibung.seit = reibung.seit + d
  if reibung.seit < REIBUNG.geduld then return end
  reibung.seit = 0.0

  local k = pool("reibung")
  if #k > 0 and Speaker.Frei("reibung") then
    log(string.format("WARTEN %.0f m seit %.0fs", w, REIBUNG.geduld))
    Speaker.Request({ situation = "reibung", pool = "reibung",
                      kandidaten = k, cd = REIBUNG.cd })
  end
end

--  ---------------------------------------------------------------- Sorge

--  Ausgeloest wird am UEBERGANG unter die Schwelle, nicht solange V darunter ist. Sonst
--  redet sie durch, waehrend es eng wird, und das ist das Gegenteil von Anteilnahme.
local SORGE = {
  schwelle = 40.0,    -- Prozent
  cd       = 120.0,
}
local sorge = { war = 100.0, an = true }

local function sorgeTick()
  if not sorge.an then return end
  local p = spieler()
  if not p then return end
  local hp = sonde("StatPool.Health", function()
    return Game.GetStatPoolsSystem():GetStatPoolValue(p:GetEntityID(),
                                                      gamedataStatPoolType.Health, false)
  end)
  if hp == nil then return end

  if hp <= SORGE.schwelle and sorge.war > SORGE.schwelle then
    local k = pool("sorge")
    if #k > 0 and Speaker.Frei("sorge") then
      log(string.format("SORGE Gesundheit %.0f%% -> unter %.0f%%", hp, SORGE.schwelle))
      Speaker.Request({ situation = "sorge", pool = "sorge",
                        kandidaten = k, cd = SORGE.cd })
    end
  end
  sorge.war = hp
end

--  ---------------------------------------------------------------- Wiedersehen

--  "V kommt zurueck" laesst sich ohne Judys Position nicht messen. Zwei ehrliche
--  Naeherungen: der Beginn einer Sitzung, und ein Ortssprung - Schnellreise, Aufzug ins
--  Penthouse, jede Teleportation. Ein Sprung ist schlicht eine Strecke, fuer die in einem
--  Bild keine Zeit war; das braucht kein Blackboard und faellt auch nicht mit ihm aus.
local WIEDER = {
  nachStart =  3.0,    -- 25 s las sich als Vergessen, 1 s als zu fix - dazwischen
  sprung    = 150.0,   -- Meter in EINEM Bild = teleportiert
  nachSprung = 8.0,
  cd        = 300.0,
}
local wieder = { seitStart = 0.0, startOffen = true, letztePos = nil,
                 seitSprung = nil, an = true }

local function wiederTick(d, p)
  if not wieder.an then return end

  --  Ortssprung erkennen.
  local pos
  pcall(function() pos = p:GetWorldPosition() end)
  if pos and wieder.letztePos then
    local weit = 0.0
    pcall(function() weit = Vector4.Distance(pos, wieder.letztePos) end)
    if weit > WIEDER.sprung then
      wieder.seitSprung = 0.0
      log(string.format("WIEDERSEHEN Ortssprung %.0f m", weit))
    end
  end
  wieder.letztePos = pos

  local faellig = false
  if wieder.startOffen then
    wieder.seitStart = wieder.seitStart + d
    if wieder.seitStart >= WIEDER.nachStart then
      wieder.startOffen, faellig = false, true
    end
  end
  if wieder.seitSprung then
    wieder.seitSprung = wieder.seitSprung + d
    if wieder.seitSprung >= WIEDER.nachSprung then
      wieder.seitSprung, faellig = nil, true
    end
  end
  if not faellig then return end

  local k = pool("wiedersehen")
  if #k > 0 then
    Speaker.Request({ situation = "wiedersehen", pool = "wiedersehen",
                      kandidaten = k, cd = WIEDER.cd })
  end
end

--  ---------------------------------------------------------------- Fahrzeug

local FAHRZEUG = {
  anlauf = 2.5,     -- erst sitzen, dann reden
  cd     = 150.0,
}
local fahrt = { drin = false, seit = nil, an = true }

local function fahrtTick(d, p)
  if not fahrt.an then return end
  local v = sonde("GetMountedVehicle", function() return Game.GetMountedVehicle(p) end,
                    true)
  local drin = v ~= nil

  if drin and not fahrt.drin then
    fahrt.drin, fahrt.seit = true, 0.0
    log("FAHRZEUG aufgesessen")
  elseif not drin and fahrt.drin then
    fahrt.drin, fahrt.seit = false, nil
    --  Was noch fuers Einsteigen anstand, passt nach dem Aussteigen nicht mehr.
    Speaker.Verwerfen("fahrzeug")
  end

  if fahrt.seit then
    fahrt.seit = fahrt.seit + d
    if fahrt.seit >= FAHRZEUG.anlauf then
      fahrt.seit = nil
      local k = pool("fahrzeug")
      if #k > 0 then
        Speaker.Request({ situation = "fahrzeug", pool = "fahrzeug",
                          kandidaten = k, cd = FAHRZEUG.cd })
      end
    end
  end
end

--  ---------------------------------------------------------------- aussen

function T.Init(opts)
  Speaker     = opts.speaker
  LINES       = opts.lines or {}
  log         = opts.log or function() end
  holeZiel    = opts.ziel
  letzteZeile = opts.letzteZeile
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
  --  Unabhaengig von jedem Ausloeser: der Abstand wird auch angezeigt und spaeter vom
  --  Teleport-Fix gebraucht. Frueher rechnete ihn nur reibungTick, und der steigt im
  --  Wagen und im Gefecht sofort aus - dann stand im Panel ein alter Wert.
  abstand(p)
  stimmeTick()
  gazeTick(d, p)
  kampfTick(d)
  sorgeTick()
  reibungTick(d, p)
  leiterTick(d, p)
  wiederTick(d, p)
  fahrtTick(d, p)
end

function T.Status()
  return {
    gaze  = { an = gaze.an, t = gaze.t, aktiv = gaze.id ~= nil, zuletzt = gaze.zuletzt,
              stufe1 = GAZE.stufe1, stufe2 = GAZE.stufe2,
              n1 = #pool("blick", 1), n2 = #pool("blick", 2) },
    kampf = { an = kampf.an, drin = kampf.drin, seit = kampf.seit,
              n = #pool("kampf"), nEnde = #pool("kampf_ende") },
    sorge = { an = sorge.an, hp = sorge.war, schwelle = SORGE.schwelle,
              n = #pool("sorge") },
    wieder = { an = wieder.an, offen = wieder.startOffen,
               seit = wieder.seitStart, nach = WIEDER.nachStart,
               n = #pool("wiedersehen") },
    fahrt = { an = fahrt.an, drin = fahrt.drin, n = #pool("fahrzeug") },
    stimme = { kennt = stimme.judyId ~= nil, zuletzt = stimme.zuletztFremd,
               greifbar = judy.obj ~= nil },
    leiter = { an = leiter.an, stufe = leiter.stufe, stufen = #LEITER,
               steht = leiter.stehtSeit,
               ruhe = Speaker and Speaker.StillSeit() or 0.0, ruheMin = RUHE_MIN,
               bewegt = leiter.bewegtSeit, karenz = KARENZ,
               naechste = LEITER[leiter.stufe] and LEITER[leiter.stufe].steht or nil },
    reibung = { an = reibung.an, dist = judy.dist, seit = reibung.seit,
                nah = REIBUNG.nah, weit = REIBUNG.weit, geduld = REIBUNG.geduld,
                n = #pool("reibung") },
  }
end

function T.Setzen(was, an)
  if was == "blick"    then gaze.an  = an end
  if was == "kampf"    then kampf.an = an end
  if was == "sorge"    then sorge.an = an end
  if was == "wieder"   then wieder.an = an end
  if was == "fahrzeug" then fahrt.an = an end
  if was == "reibung"  then reibung.an = an end
  if was == "leiter"   then leiter.an = an end
end

function T.Zuruecksetzen()
  gaze.s1, gaze.s2, gaze.t, gaze.id = false, false, 0.0, nil
  kampf.seit = 0.0
  sorge.war = 100.0
  wieder.startOffen, wieder.seitStart, wieder.seitSprung = true, 0.0, nil
  fahrt.seit = nil
  reibung.seit = 0.0
  leiter.stufe, leiter.stehtSeit, leiter.bewegtSeit = 1, 0.0, 0.0
end

return T
