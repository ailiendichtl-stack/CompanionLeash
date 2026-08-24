"""Macht den Sweep-Fortschritt sichtbar.

Die Anzeige steckte im zugeklappten Abschnitt - bei geschlossenem Overlay also gar nicht
sichtbar, und genau so soll der Lauf ja stattfinden. Jetzt:

* eine Statuszeile ganz oben im Panel, unabhaengig von aufgeklappten Abschnitten
* alle 20 Eintraege eine Zeile ins Log, mit Restzeit
* eine Startzeile mit der geschaetzten Gesamtdauer
"""
import io
import os
import sys

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PANEL = os.path.join(HERE, "cet", "CompanionLeashVO", "init.lua")

s = io.open(PANEL, encoding="utf-8").read()
fails = []


def sub(old, new, label):
    global s
    if old not in s:
        fails.append(label)
        return
    s = s.replace(old, new, 1)


#  Fortschritt ins Log, damit ein Lauf ohne Overlay nachvollziehbar bleibt.
sub(
    "      else\n"
    "        local dl = lastLine()\n"
    '        sweep.before = dl and dl.text or ""\n'
    "        sweep.t, sweep.got, sweep.pending = 0, false, true\n"
    "        playBark(sweep.list[sweep.i])\n"
    "      end",
    "      else\n"
    "        local dl = lastLine()\n"
    '        sweep.before = dl and dl.text or ""\n'
    "        sweep.t, sweep.got, sweep.pending = 0, false, true\n"
    "        if sweep.i % 20 == 1 then\n"
    "          --  grob 1.5s je Eintrag; nur zur Orientierung waehrend des Laufs\n"
    '          log(string.format("  ... %d/%d, %d Treffer, noch etwa %d min",\n'
    "              sweep.i, #sweep.list, sweep.hits,\n"
    "              math.ceil((#sweep.list - sweep.i) * 1.5 / 60)))\n"
    "        end\n"
    "        playBark(sweep.list[sweep.i])\n"
    "      end",
    "Log-Fortschritt")

#  Statuszeile ganz oben, sichtbar ohne aufgeklappten Abschnitt.
sub(
    '  ImGui.Text("Sprecher:")',
    "  if sweep then\n"
    "    ImGui.TextColored(0.4, 1.0, 0.4, 1.0, string.format(\n"
    '      "SWEEP %d/%d  -  %d Treffer  -  noch etwa %d min",\n'
    "      sweep.i, #sweep.list, sweep.hits,\n"
    "      math.ceil((#sweep.list - sweep.i) * 1.5 / 60)))\n"
    "    ImGui.ProgressBar(sweep.i / #sweep.list, -1, 0)\n"
    '    ImGui.TextDisabled("laeuft auch bei geschlossenem Overlay weiter")\n'
    "    ImGui.Separator()\n"
    "  end\n\n"
    '  ImGui.Text("Sprecher:")',
    "Statuszeile")

sub(
    '        log(string.format("=== SWEEP ueber %d V-Eintraege", #VSET_V))',
    '        log(string.format("=== SWEEP ueber %d V-Eintraege, etwa %d min",\n'
    "            #VSET_V, math.ceil(#VSET_V * 1.5 / 60)))",
    "Startzeile")

if fails:
    print("!! NICHT ERSETZT: %s" % fails)
    sys.exit(1)

io.open(PANEL, "w", encoding="utf-8", newline="\n").write(s)
print("[ok] alle 3 Ersetzungen bestaetigt")
