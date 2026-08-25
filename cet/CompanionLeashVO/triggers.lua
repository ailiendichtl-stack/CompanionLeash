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

--  Steht das Spiel? Im Pausenmenue, im Inventar und auf der Karte laeuft `onUpdate`
--  weiter, das Spiel aber nicht. Ohne diese Sperre zaehlen alle Uhren durch: die
--  Standuhr der Leiter (im Menue bewegt sich niemand), der Zufallstimer, die Blickdauer.
--  Nach dem Schliessen waeren mehrere Sprossen gleichzeitig faellig und wuerden sich
--  aufeinander stapeln.
local function pausiert()
  local p = false
  pcall(function() p = Game.GetSystemRequestsHandler():IsGamePaused() end)
  if p == true then return true end
  pcall(function()
    local defs = Game.GetAllBlackboardDefs()
    local bb = Game.GetBlackboardSystem():Get(defs.UI_System)
    if bb then p = bb:GetBool(defs.UI_System.IsInMenu) end
  end)
  return p == true
end

function T.Pausiert() return pausiert() end

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

--  ---------------------------------------------------------------- Beziehungsstand

--  Flirt braucht keine Ausloesung, sondern eine SPERRE. Wer die Romanze nie gespielt hat,
--  soll nicht angeflirtet werden - das faellt sofort auf und ist keine Geschmacksfrage,
--  sondern schlicht falsch.
--
--  Der erste Versuch nahm NCAs `love`. Das war der falsche Wert: er zaehlt NCAs eigenen
--  Fortschritt aus Posen und Gespraechen. Im Spiel stand "Liebe 6 / Freundschaft 70" bei
--  abgeschlossener Romanze und fester Partnerin - als Sperre haette er alles zugehalten.
--
--  Der richtige Wert ist ein Quest-Fakt. Das Spiel fuehrt sie je Figur nach demselben
--  Muster - `sq027_panam_lover`, `sq029_river_lover`, `sq028_kerry_relationship` -, und
--  Judys heisst `sq030_judy_lover`. Beide hier benutzten Fakten werden von installierten
--  Romanzen-Mods abgefragt, sind also nicht geraten.
local FAKTEN = { "sq030_judy_lover", "mq055_judy" }

local NCA_PS = nil
local bez = { liebe = nil, freund = nil, fakt = nil, welcher = nil }

local function beziehungLesen()
  if NCA_PS == nil then
    pcall(function()
      local c = Game.GetScriptableSystemsContainer()
      NCA_PS = c:Get("NightCityAllies.Persistence.PersistenceSystem")
      if not NCA_PS then NCA_PS = c:Get("PersistenceSystem") end
    end)
    if not NCA_PS then
      NCA_PS = false
      log("SONDE NCAs PersistenceSystem nicht erreichbar - Flirt bleibt gesperrt")
    end
  end
  if NCA_PS and JUDY then
    pcall(function()
      bez.liebe  = NCA_PS:GetLove(JUDY)
      bez.freund = NCA_PS:GetFriendship(JUDY)
    end)
  end

  --  Der Fakt entscheidet. NCAs Werte stehen nur zur Anschauung daneben.
  bez.fakt, bez.welcher = nil, nil
  for _, name in ipairs(FAKTEN) do
    local v
    pcall(function() v = Game.GetQuestsSystem():GetFact(CName.new(name)) end)
    if v and v > 0 then
      bez.fakt, bez.welcher = v, name
      return
    end
    if v ~= nil and bez.fakt == nil then bez.fakt = 0 end
  end
end

--  Unbekannt heisst gesperrt - aber sichtbar gesperrt. Im Panel steht, welcher Fakt
--  gegriffen hat; ein stiller Riegel waere nach dieser Woche genau das falsche Verhalten.
local function verliebtGenug()
  return bez.fakt ~= nil and bez.fakt > 0
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

--  ---------------------------------------------------------------- Haltung

--  Geht V in die Hocke, soll Judy es auch tun - und dabei weiterlaufen.
--
--  Der Weg fuehrt durch dieselbe Tuer, die die Kampf-KI benutzt. Die Haltung wird nicht
--  ueber ein Anim-Feature gesetzt, sondern ueber ein Signal an ihre Zustandskomponente:
--
--      puppet:GetStatesComponent():OnNPCStateChangeSignalReceived(signal)
--
--  `OnNPCStateChangeSignalReceived` ist oeffentlich, und `ChangeStanceState` dahinter macht
--  genau das Richtige: Anim-Feature anwenden, Anim-Wrapper-Gewichte umsetzen, Blackboard
--  schreiben. Selbst am Anim-Feature zu drehen haette den halben Weg nachgebaut.
--
--  OFFEN und der eigentliche Grund fuer die Rueckmessung: ob die KI die Haltung beim
--  naechsten Verhaltensschritt wieder ueberschreibt. Darum wird nicht blind gesetzt,
--  sondern der Ist-Wert aus ihrem Blackboard gelesen und nachgezogen.
local STANCE = { Crouch = "Crouch", Stand = "Stand" }
local HALTUNG = { takt = 0.4 }     -- so oft wird nachgesehen und noetigenfalls nachgesetzt
local haltung = { an = true, ziel = nil, ist = nil, seit = 0.0,
                  gesetzt = 0, korrekturen = 0, gemeldet = false,
                  gemeldetOk = false }

--  Der ECHTE Zustand, nicht der gespiegelte.
--
--  `GetCurrentStanceState` liest `GetReplicatedStanceState` - das ist der Wert, den die
--  Zustandsmaschine wirklich fuehrt. Das Blackboard daneben ist nur eine Kopie, die
--  `UpdateStanceState` mitschreibt; wer sie selbst setzt, prueft sich gegen sich selbst.
local function haltungLesen(o)
  local v
  pcall(function()
    local comp = o:GetStatesComponent()
    if comp then v = comp:GetCurrentStanceState() end
  end)
  if v ~= nil then
    local n
    pcall(function() n = EnumInt(v) end)
    if n ~= nil then return n end
  end
  return v
end

--  Das Signal allein reichte nicht: es kam an, tat aber nichts. `ChangeStanceState` ruft
--  `SetCurrentStanceState`, das an `SetReplicatedStanceState` weiterreicht - eine native
--  Replikation, die einen Bool zurueckgibt. Schlaegt die fehl, wird `UpdateStanceState`
--  gar nicht erst aufgerufen, und von aussen sieht man davon nichts.
--
--  Also die drei Schritte, die `UpdateStanceState` macht, direkt nachgebaut. Alle drei
--  sind oeffentlich, und der zweite ist der, den man vergisst: der Anim-Wrapper schaltet
--  das Bewegungsset um. Ohne ihn haette sie hoechstens die Pose gewechselt und waere
--  weiter im Stehen gelaufen.
local ZUSTAND = { Crouch = 2, Stand = 3 }

local function haltungSetzen(o, name)
  local wert = ZUSTAND[name] or ZUSTAND.Stand
  local schritte = { feature = false, wrapper = false, blackboard = false }

  --  Der Klassenname traegt ein Praefix, das im Skript-Dump nicht steht: dort heisst sie
  --  `AnimFeature_NPCState`, in der RTTI `animAnimFeature_NPCState`. Reflection kennt den
  --  Dump-Namen gar nicht - sechs Schreibweisen durchzuprobieren war der einzige Weg, das
  --  herauszufinden, und ohne die Trennung von Bau und Feldzugriff haette die Sonde nur
  --  wieder "geht nicht" gesagt.
  local feat
  pcall(function()
    feat = NewObject("animAnimFeature_NPCState")
    feat.state = wert
  end)
  if feat then
    pcall(function()
      AnimationControllerComponent.ApplyFeature(o, CName.new("stanceState"), feat)
      schritte.feature = true
    end)
  end

  pcall(function()
    AnimationControllerComponent.SetAnimWrapperWeightOnOwnerAndItems(
      o, CName.new("inCrouch"), (name == "Crouch") and 1.0 or 0.0)
    schritte.wrapper = true
  end)

  --  Frueher wurde hier auch das Blackboard geschrieben. Zwei Gruende, es zu lassen:
  --
  --  Es machte die Rueckmessung wertlos - wir lasen zurueck, was wir selbst gesetzt hatten,
  --  der Korrekturzaehler konnte gar nicht anschlagen und stand auf 0, waehrend sichtbar
  --  nichts geschah.
  --
  --  Und es luegt. `UpdateStanceState` schreibt den Wert als SPIEGEL des echten Zustands.
  --  Ihn ohne den echten Zustand zu setzen erzaehlt jeder KI-Bedingung und jedem Prereq,
  --  sie hocke - und die entscheiden danach.

  if not haltung.gemeldet then
    haltung.gemeldet = true
    log(string.format("HALTUNG Feature=%s Wrapper=%s Blackboard=%s",
        tostring(schritte.feature), tostring(schritte.wrapper),
        tostring(schritte.blackboard)))
  end
  return schritte.feature or schritte.wrapper
end

local function haltungTick(d)
  if not haltung.an then return end
  haltung.seit = haltung.seit + d
  if haltung.seit < HALTUNG.takt then return end
  haltung.seit = 0.0

  local o = judyHolen()
  if not o then haltung.ziel, haltung.ist = nil, nil; return end

  --  gamePSMLocomotionStates: 1 Crouch, 11 CrouchSprint, 12 CrouchDodge
  local lok = psm("Locomotion")
  local hockt = lok == 1 or lok == 11 or lok == 12
  local ziel = hockt and STANCE.Crouch or STANCE.Stand
  local istWert = haltungLesen(o)
  haltung.ist = istWert

  --  gamedataNPCStanceState: 1 Cover, 2 Crouch, 3 Stand
  local istName = (istWert == 2) and STANCE.Crouch or (istWert == 3) and STANCE.Stand or nil

  if ziel == haltung.ziel and istName == ziel then return end

  if istName ~= ziel then
    if haltungSetzen(o, ziel) then
      if haltung.ziel == ziel then
        --  Sie stand schon auf diesem Ziel und ist zurueckgefallen: das ist die KI.
        haltung.korrekturen = haltung.korrekturen + 1
        --  Die wichtigste Zahl gehoert ins Protokoll, nicht nur ins Panel: ob jemand
        --  zurueckdreht, entscheidet ueber den ganzen Ansatz.
        if haltung.korrekturen == 1 or haltung.korrekturen == 25
           or haltung.korrekturen == 200 then
          log(string.format("HALTUNG %d Korrektur(en) - etwas setzt die Haltung zurueck",
              haltung.korrekturen))
        end
      else
        haltung.gesetzt = haltung.gesetzt + 1
        log(string.format("HALTUNG %s gesetzt - echter Zustand vorher: %s",
            ziel, tostring(istWert)))
      end
    elseif haltung.ziel ~= ziel then
      log("HALTUNG konnte nicht gesetzt werden - GetStatesComponent oder Signal fehlt")
    end
  end
  haltung.ziel = ziel
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
  stufe3  =   75.0,   -- so lange sieht man niemanden aus Versehen an
  cd1     =  300.0,   -- Abklingzeit der beilaeufigen Reaktion
  cd2     = 1800.0,   -- die zweite Ebene hoechstens halbstuendlich
  cd3     = 3600.0,   -- die dritte einmal pro Stunde
  distanz =    8.0,   -- ueber die Strasse hinweg ist kein Anschauen
}
--  s1/s2 gehoeren dem Blick: sie verhindern, dass er innerhalb EINES Blicks nachlegt.
--  Belegt-Sein und Abklingzeiten fuehrt der Sprecher.
local gaze = { t = 0.0, id = nil, s1 = false, s2 = false, s3 = false,
               an = true, zuletzt = "-" }

local function gazeFeuern(obj)
  --  Dritte Stufe: so lange sieht man niemanden aus Versehen an. Sie zieht aus dem
  --  Flirt-Pool und nur, wenn die Beziehung das traegt.
  local stufe
  if not gaze.s3 and gaze.t >= GAZE.stufe3 and verliebtGenug() then
    stufe = 3
  elseif not gaze.s2 and gaze.t >= GAZE.stufe2 then
    stufe = 2
  elseif not gaze.s1 and gaze.t >= GAZE.stufe1 then
    stufe = 1
  end
  if not stufe then return end

  --  Ob angenommen oder nicht: innerhalb dieses Blicks nicht noch einmal anfragen. Ohne
  --  das stellt der Ausloeser in jedem Frame denselben Antrag, solange V hinsieht.
  gaze.s1 = true
  if stufe >= 2 then gaze.s2 = true end
  if stufe >= 3 then gaze.s3 = true end

  local k = (stufe == 3) and pool("flirt") or pool("blick", stufe)
  if #k == 0 then
    log(string.format("BLICK Stufe %d - Pool leer", stufe))
    return
  end
  log(string.format("BLICK Stufe %d nach %.1fs, %d Kandidaten", stufe, gaze.t, #k))
  Speaker.Request({
    situation  = (stufe == 3) and "flirt" or "blick",
    --  Stufe 3 zieht aus dem Flirt-Pool und teilt sich dessen Abklingzeit mit der
    --  Leitersprosse und dem Zufallstimer: Flirt soll selten sein, egal woher er kommt.
    pool       = (stufe == 3) and "flirt" or ("blick" .. stufe),
    kandidaten = k,
    cd         = (stufe == 3) and GAZE.cd3 or (stufe == 2) and GAZE.cd2 or GAZE.cd1,
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
      gaze.id, gaze.t, gaze.s1, gaze.s2, gaze.s3 = id, 0.0, false, false, false
    end
    gaze.t = gaze.t + d
    gazeFeuern(o)
  elseif gaze.id then
    --  Wegsehen setzt die Uhr zurueck. Sonst liesse sich die Schwelle aus lauter kurzen
    --  Blicken zusammensammeln, und das ist nicht dasselbe wie jemanden anzusehen.
    gaze.id, gaze.t, gaze.s1, gaze.s2, gaze.s3 = nil, 0.0, false, false, false
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
  { steht = 420.0, pool = "flirt",      cd = 900.0, liebe = true },   -- sieben Minuten
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
  if st.liebe and not verliebtGenug() then return end

  local k = pool(st.pool)
  if #k == 0 or not Speaker.Frei(st.pool) then return end
  log(string.format("LEITER Sprosse %d nach %.0fs Stillstand, Pool %s (%d)",
      leiter.stufe, leiter.stehtSeit, st.pool, #k))
  Speaker.Request({ situation = "leiter", prio = Speaker.PRIO.alltag,
                    pool = st.pool, kandidaten = k, cd = st.cd or 60.0 })
  leiter.stufe = leiter.stufe + 1
end

--  ---------------------------------------------------------------- Abschied

--  Sie verabschiedet sich, wenn sie geht.
--
--  Ein Ereignis dafuer gibt es nicht, das wir ohne NCA-Haken lesen koennten. Was wir haben,
--  ist ihre Referenz: faellt sie weg, ist Judy nicht mehr da. Das passiert aber auch beim
--  Despawn auf Entfernung und in gesperrten Zonen, und das ist kein Abschied.
--
--  Der Unterschied ist die letzte bekannte Entfernung. Wer weggeschickt wird, steht vorher
--  neben einem; wer wegen Entfernung verschwindet, war weit weg. Protokolliert wird beides,
--  damit sich nach ein paar Sitzungen sagen laesst, ob die Trennung taugt.
local ABSCHIED = { nah = 20.0, cd = 120.0 }
local abschied = { warDa = false, letzteDist = nil, an = true }

local function abschiedTick()
  if not abschied.an then return end
  local daJetzt = judy.obj ~= nil
  if judy.dist then abschied.letzteDist = judy.dist end

  if abschied.warDa and not daJetzt then
    local w = abschied.letzteDist
    if w and w <= ABSCHIED.nah then
      local k = pool("abschied")
      if #k > 0 then
        log(string.format("ABSCHIED sie war %.0f m entfernt und ist weg", w))
        Speaker.Request({ situation = "abschied", pool = "abschied",
                          kandidaten = k, cd = ABSCHIED.cd })
      end
    else
      log(string.format("ABSCHIED verworfen - sie war %s entfernt, das war ein Despawn",
          w and string.format("%.0f m", w) or "unbekannt weit"))
    end
    abschied.letzteDist = nil
  end
  abschied.warDa = daJetzt
end

--  ---------------------------------------------------------------- Zufallsflirt

--  Ein seltener Timer, der auch beim Laufen zuschlaegt.
--
--  Blick und Leiter setzen beide Stillstand voraus - wer durch die Stadt laeuft, erreicht
--  keine der beiden. Genau dort fehlt aber etwas: sie geht neben V her, und irgendwann
--  sagt sie einfach etwas. Der Abstand ist absichtlich weit und zufaellig, damit sich kein
--  Takt einstellt.
local ZUFALL = { min = 600.0, max = 1200.0 }
local zufall = { rest = nil, an = true }

local function zufallNeu()
  zufall.rest = ZUFALL.min + math.random() * (ZUFALL.max - ZUFALL.min)
end

local function zufallTick(d, p)
  if not zufall.an then return end
  if zufall.rest == nil then zufallNeu() end

  --  Im Gefecht laeuft die Uhr nicht weiter - sonst haette sie nach einem langen Kampf
  --  sofort etwas offen, und ein Flirt direkt nach dem letzten Schuss sitzt falsch.
  if psm("Combat") == 1 then return end

  zufall.rest = zufall.rest - d
  if zufall.rest > 0.0 then return end

  if not verliebtGenug() then return end
  local k = pool("flirt")
  if #k == 0 or not Speaker.Frei("flirt") then return end

  zufallNeu()
  log(string.format("ZUFALLSFLIRT faellig, %d Kandidaten, naechster in %.0f min",
      #k, zufall.rest / 60.0))
  Speaker.Request({ situation = "flirt", pool = "flirt", kandidaten = k, cd = 300.0 })
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
    --  Der dritte Parameter heisst `perc`. Mit `false` kommen Absolutpunkte zurueck -
    --  im Panel standen 343, und eine Schwelle von 40 war damit nie zu unterschreiten.
    return Game.GetStatPoolsSystem():GetStatPoolValue(p:GetEntityID(),
                                                      gamedataStatPoolType.Health, true)
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

--  ---------------------------------------------------------------- Testknoepfe

--  Jeden Ausloeser sofort ausloesen, ohne seine Bedingung herzustellen. Sonst dauert eine
--  Runde durch alle Situationen Minuten: drei Minuten stillstehen fuer Sprosse drei, eine
--  halbe Stunde fuer die zweite Blickstufe.
--
--  Die Pools sind dieselben wie im echten Betrieb, und der Weg geht durch den Sprecher -
--  ein Test zeigt also auch, ob Auswahl, Wiederholungsschutz und Ausgabe stimmen. Nur die
--  Wartezeiten entfallen.
local TESTS = {
  { name = "Blick 1",     sit = "blick",       pool = "blick1",      q = "blick", st = 1 },
  { name = "Blick 2",     sit = "blick",       pool = "blick2",      q = "blick", st = 2 },
  { name = "Kampf",       sit = "kampf",       pool = "kampf",       q = "kampf" },
  { name = "Kampfende",   sit = "kampf_ende",  pool = "kampf_ende",  q = "kampf_ende" },
  { name = "Sorge",       sit = "sorge",       pool = "sorge",       q = "sorge" },
  { name = "Wiedersehen", sit = "wiedersehen", pool = "wiedersehen", q = "wiedersehen" },
  { name = "Fahrzeug",    sit = "fahrzeug",    pool = "fahrzeug",    q = "fahrzeug" },
  { name = "Warten",      sit = "reibung",     pool = "reibung",     q = "reibung" },
  { name = "Leiter 1",    sit = "leiter",      pool = "reibung",     q = "reibung" },
  { name = "Leiter 2",    sit = "leiter",      pool = "alltag",      q = "alltag" },
  { name = "Leiter 3",    sit = "leiter",      pool = "initiative",  q = "initiative" },
  { name = "Blick 3",     sit = "flirt",       pool = "blick3",      q = "flirt" },
  { name = "Leiter 4",    sit = "leiter",      pool = "flirt",       q = "flirt" },
  { name = "Zufallsflirt", sit = "flirt",      pool = "flirt",       q = "flirt" },
  { name = "Abschied",    sit = "abschied",    pool = "abschied",    q = "abschied" },
}

function T.Tests()
  local out = {}
  for i, t in ipairs(TESTS) do
    out[i] = { name = t.name, n = #pool(t.q, t.st) }
  end
  return out
end

function T.Test(i)
  local t = TESTS[i]
  if not t then return end
  local k = pool(t.q, t.st)
  if #k == 0 then
    log("TEST " .. t.name .. " - Pool leer")
    return
  end
  log(string.format("TEST %s, %d Kandidaten", t.name, #k))
  --  cd = 0: ein Test soll die echte Abklingzeit nicht setzen und damit den naechsten
  --  Versuch blockieren.
  Speaker.Request({ situation = t.sit, pool = t.pool, kandidaten = k,
                    cd = 0.0, erzwingen = true })
end

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
  --  Im Menue steht die Zeit fuer den Spieler still, also auch fuer sie.
  if pausiert() then return end
  --  Unabhaengig von jedem Ausloeser: der Abstand wird auch angezeigt und spaeter vom
  --  Teleport-Fix gebraucht. Frueher rechnete ihn nur reibungTick, und der steigt im
  --  Wagen und im Gefecht sofort aus - dann stand im Panel ein alter Wert.
  abstand(p)
  beziehungLesen()
  stimmeTick()
  gazeTick(d, p)
  kampfTick(d)
  sorgeTick()
  reibungTick(d, p)
  leiterTick(d, p)
  zufallTick(d, p)
  abschiedTick()
  haltungTick(d)
  wiederTick(d, p)
  fahrtTick(d, p)
end

function T.Status()
  return {
    gaze  = { an = gaze.an, t = gaze.t, aktiv = gaze.id ~= nil, zuletzt = gaze.zuletzt,
              stufe1 = GAZE.stufe1, stufe2 = GAZE.stufe2, stufe3 = GAZE.stufe3,
              n1 = #pool("blick", 1), n2 = #pool("blick", 2), n3 = #pool("flirt") },
    bez = { liebe = bez.liebe, freund = bez.freund,
            fakt = bez.fakt, welcher = bez.welcher, offen = verliebtGenug() },
    zufall = { an = zufall.an, rest = zufall.rest,
               min = ZUFALL.min, max = ZUFALL.max, n = #pool("flirt") },
    kampf = { an = kampf.an, drin = kampf.drin, seit = kampf.seit,
              n = #pool("kampf"), nEnde = #pool("kampf_ende") },
    sorge = { an = sorge.an, hp = sorge.war, schwelle = SORGE.schwelle,
              n = #pool("sorge") },
    wieder = { an = wieder.an, offen = wieder.startOffen,
               seit = wieder.seitStart, nach = WIEDER.nachStart,
               n = #pool("wiedersehen") },
    fahrt = { an = fahrt.an, drin = fahrt.drin, n = #pool("fahrzeug") },
    abschied = { an = abschied.an, da = abschied.warDa, n = #pool("abschied") },
    haltung = { an = haltung.an, ziel = haltung.ziel, ist = haltung.ist,
                gesetzt = haltung.gesetzt, korrekturen = haltung.korrekturen },
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
  if was == "zufall"   then zufall.an = an end
  if was == "abschied" then abschied.an = an end
  if was == "haltung"  then haltung.an = an end
end

function T.Zuruecksetzen()
  gaze.s1, gaze.s2, gaze.s3, gaze.t, gaze.id = false, false, false, 0.0, nil
  kampf.seit = 0.0
  sorge.war = 100.0
  wieder.startOffen, wieder.seitStart, wieder.seitSprung = true, 0.0, nil
  fahrt.seit = nil
  reibung.seit = 0.0
  leiter.stufe, leiter.stehtSeit, leiter.bewegtSeit = 1, 0.0, 0.0
  zufall.rest = nil
end

return T
