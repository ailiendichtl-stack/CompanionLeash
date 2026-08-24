"""Ersetzt den Durchstich-Abschnitt durch eine Testmatrix.

Die bisherigen Einzelknoepfe haben Name und Ziel vermischt: ein VVF-Name mit Judy als Ziel
waere kein aussagekraeftiger Fehlschlag, weil der Dispatcher das Voiceset am Puppet
auswaehlt und VVFs Eintraege in vset_v.scene liegen. Name und Ziel werden hier deshalb
getrennt uebergeben und beide vor dem Aufruf protokolliert.

Enthalten sind ausdruecklich auch die beiden Negativkontrollen - VVF-Name auf Judy,
unser Name auf V. Beide sollten NICHT spielen; tun sie es doch, loest der Dispatcher
Namen global statt am Puppet auf, und das aendert die Deutung aller anderen Zeilen.
"""
import hashlib
import io
import json
import os
import shutil
import sys

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PANEL = os.path.join(HERE, "cet", "CompanionLeashVO", "init.lua")

s = io.open(PANEL, encoding="utf-8").read()

start = s.index('  if ImGui.CollapsingHeader("Durchstich')
end = s.index('  if ImGui.CollapsingHeader("Barks - 55 Zeilen") then')

block = '''  if ImGui.CollapsingHeader("Testmatrix", ImGuiTreeNodeFlags.DefaultOpen) then
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

'''
s = s[:start] + block + s[end:]

#  Die Matrix als Datentabelle, damit Beschriftung, Name und Ziel nicht auseinanderlaufen
#  koennen - genau der Fehler, den das Protokoll ausschliessen soll.
matrix = '''--  name/ziel getrennt; hint sagt, was zu erwarten ist.
local MATRIX = {
  { label = "1 VVF auf V",      name = "vfv_better_run",      player = true,
    hint = "erwartet: V spricht - beweist, dass neue Eintraege tragen" },
  { label = "2 VVF auf V (2)",  name = "vfv_talk_later",      player = true,
    hint = "erwartet: V spricht" },
  { label = "3 Judy bekannt",   name = "follow_me",           player = false,
    hint = "erwartet: Judy spricht - Gegenprobe, dass der Pfad lebt" },
  { label = "4 Judy neu",       name = "cl_test_froh",        player = false,
    hint = "erwartet: Ich bin froh, dass du da bist." },
  { label = "5 Unsinn",         name = "cl_gibt_es_nicht_xyz", player = false,
    hint = "zeigt den echten Rueckfall bei unbekanntem Namen" },
  { label = "6 VVF auf Judy",   name = "vfv_better_run",      player = false,
    hint = "Negativkontrolle - sollte NICHT spielen" },
  { label = "7 Judy-Name auf V", name = "cl_test_froh",       player = true,
    hint = "Negativkontrolle - sollte NICHT spielen" },
}

'''
anchor = "local STYLES, styleIdx = {}, -1"
if anchor not in s:
    print("!! Anker fuer MATRIX fehlt")
    sys.exit(1)
s = s.replace(anchor, matrix + anchor, 1)

io.open(PANEL, "w", encoding="utf-8", newline="\n").write(s)

GAME = open(os.path.join(HERE, "game-root.txt"), encoding="utf-8").read().strip()
dst = os.path.join(GAME, "bin", "x64", "plugins", "cyber_engine_tweaks", "mods",
                   "CompanionLeashVO", "init.lua")
shutil.copyfile(PANEL, dst)
h = hashlib.md5(open(PANEL, "rb").read()).hexdigest()
m = json.load(open(os.path.join(HERE, "manifest.json"), encoding="utf-8"))
m["cet_files"] = {"CompanionLeashVO/init.lua": h}
json.dump(m, open(os.path.join(HERE, "manifest.json"), "w", encoding="utf-8"), indent=2)
print("[ok] Matrix eingebaut, deployed:",
      hashlib.md5(open(dst, "rb").read()).hexdigest() == h)
