# -*- coding: utf-8 -*-
"""Wertet das Sprecher-Protokoll aus: wie oft redet sie, was, und was faellt weg.

Die Abklingzeiten sind allesamt geraten. Ob Judy zu viel redet, entscheidet sich nicht am
Schreibtisch, sondern nach mehreren Sitzungen - und dann nicht am Gefuehl, sondern hieran.

Ausgewertet wird, was der Sprecher schreibt:

    SPEAKER REQUEST situation=... prio=... pool=... line=...
    SPEAKER ACCEPT  situation=... prio=... line=... dauer=... bis=...
    SPEAKER REJECT  situation=... prio=... grund=...
    SPEAKER FINISH  line=...

Eine Ablehnung ist kein Fehler. Interessant ist ihr Verhaeltnis: viele `cooldown` heissen,
dass ein Ausloeser oefter will als er darf - viele `busy`, dass sich zwei ins Wort faellen
wollten.

    python tools/log_report.py               # neueste Sitzung
    python tools/log_report.py --alle        # alle Sitzungen zusammen
"""
import collections
import io
import os
import re
import sys

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

ZEIT = re.compile(r"^\[(\d{4}-\d\d-\d\d) (\d\d):(\d\d):(\d\d)")
ACC = re.compile(r"SPEAKER ACCEPT situation=(\S+) prio=(\d+) line=(\S+) dauer=([\d.]+)")
REJ = re.compile(r"SPEAKER REJECT situation=(\S+) prio=(\d+) grund=(\S+)")
REQ = re.compile(r"SPEAKER REQUEST situation=(\S+)")
START = re.compile(r"bereit - ")


def sekunden(zeile):
    m = ZEIT.match(zeile)
    if not m:
        return None
    return int(m.group(2)) * 3600 + int(m.group(3)) * 60 + int(m.group(4))


def sitzungen(pfad):
    """Zerlegt das Protokoll an den Startmarken."""
    out, akt = [], None
    for z in io.open(pfad, encoding="utf-8", errors="replace"):
        if START.search(z):
            akt = []
            out.append(akt)
        elif akt is not None:
            akt.append(z.rstrip("\n"))
    return [s for s in out if s]


def lesen(zeilen):
    """Eine Sitzung zu Zahlen. Getrennt vom Zusammenfassen, damit sich mehrere Sitzungen
    addieren lassen, ohne dass Dauern und Redepausen ueber die Pausen dazwischen
    hinweggerechnet werden - 1935 Sekunden Abstand waren die Nacht, nicht ihr Schweigen."""
    acc = collections.Counter()          # Situation -> Anzahl
    zeilenzahl = collections.Counter()   # Eintrag -> Anzahl
    rej = collections.Counter()          # Grund -> Anzahl
    req = collections.Counter()
    redezeit = collections.defaultdict(float)
    zeitpunkte = []
    t0 = t1 = None

    for z in zeilen:
        t = sekunden(z)
        if t is not None:
            if t0 is None:
                t0 = t
            t1 = t
        m = ACC.search(z)
        if m:
            acc[m.group(1)] += 1
            zeilenzahl[m.group(3)] += 1
            redezeit[m.group(1)] += float(m.group(4))
            if t is not None:
                zeitpunkte.append(t)
            continue
        m = REJ.search(z)
        if m:
            rej[m.group(3)] += 1
            continue
        m = REQ.search(z)
        if m:
            req[m.group(1)] += 1

    dauer = (t1 - t0) if (t0 is not None and t1 is not None and t1 >= t0) else 0
    luecken = [b - a for a, b in zip(zeitpunkte, zeitpunkte[1:])]
    return dict(acc=acc, zeilenzahl=zeilenzahl, rej=rej, req=req, redezeit=redezeit,
                dauer=dauer, luecken=luecken, protokoll=len(zeilen))


def zusammen(teile):
    g = dict(acc=collections.Counter(), zeilenzahl=collections.Counter(),
             rej=collections.Counter(), req=collections.Counter(),
             redezeit=collections.defaultdict(float), dauer=0, luecken=[], protokoll=0)
    for t in teile:
        for k in ("acc", "zeilenzahl", "rej", "req"):
            g[k].update(t[k])
        for sit, v in t["redezeit"].items():
            g["redezeit"][sit] += v
        g["dauer"] += t["dauer"]
        g["luecken"] += t["luecken"]
        g["protokoll"] += t["protokoll"]
    return g


def zeigen(g, titel):
    acc, zeilenzahl = g["acc"], g["zeilenzahl"]
    rej, req, redezeit = g["rej"], g["req"], g["redezeit"]
    dauer, luecken = g["dauer"], sorted(g["luecken"])

    print("=" * 72)
    print("%s   %s Spielzeit, %d Zeilen Protokoll"
          % (titel, _mmss(dauer), g["protokoll"]))
    print("=" * 72)

    gesamt = sum(acc.values())
    if not gesamt:
        print("Nichts gesprochen.")
        return
    gesprochen = sum(redezeit.values())
    print("gesprochen: %d Zeilen, %s reine Sprechzeit%s"
          % (gesamt, _mmss(int(gesprochen)),
             ("  (%.1f %% der Sitzung)" % (100.0 * gesprochen / dauer)) if dauer else ""))
    if luecken:
        print("Abstand zwischen Zeilen: kuerzester %ds, Mitte %ds, laengster %ds"
              % (luecken[0], luecken[len(luecken) // 2], luecken[-1]))
        eng = sum(1 for x in luecken if x < 10)
        if eng:
            print("   davon %d unter 10s - dort ueberlappt sie sich fast" % eng)
    print()

    print("%-14s %6s %8s %9s" % ("Situation", "Zeilen", "Antraege", "Sprechzeit"))
    print("-" * 42)
    for sit, n in acc.most_common():
        print("%-14s %6d %8d %8ds" % (sit, n, req.get(sit, 0), int(redezeit[sit])))
    fehlend = [s for s in req if s not in acc]
    for sit in fehlend:
        print("%-14s %6d %8d %8s   nie durchgekommen" % (sit, 0, req[sit], "-"))
    print()

    if rej:
        print("Abgelehnt: %d" % sum(rej.values()))
        for grund, n in rej.most_common():
            print("   %-16s %4d" % (grund, n))
        print()

    print("Meistgehoert:")
    for name, n in zeilenzahl.most_common(12):
        marke = "  <-- oft" if n >= 4 else ""
        print("   %3dx  %s%s" % (n, name, marke))
    einmal = sum(1 for v in zeilenzahl.values() if v == 1)
    print("   (%d verschiedene Eintraege, %d davon genau einmal)"
          % (len(zeilenzahl), einmal))


def _mmss(s):
    return "%d:%02d" % (s // 60, s % 60)


def main():
    cfg = os.path.join(HERE, "game-root.txt")
    root = io.open(cfg, encoding="utf-8").read().strip()
    pfad = os.path.join(root, "bin", "x64", "plugins", "cyber_engine_tweaks", "mods",
                        "CompanionLeashVO", "CompanionLeashVO.log")
    if not os.path.exists(pfad):
        raise SystemExit("kein Protokoll unter %s" % pfad)

    alle = sitzungen(pfad)
    if not alle:
        raise SystemExit("keine Sitzung im Protokoll")

    if "--alle" in sys.argv:
        zeigen(zusammen([lesen(s) for s in alle]), "Alle %d Sitzungen" % len(alle))
    else:
        zeigen(lesen(alle[-1]), "Letzte Sitzung (von %d)" % len(alle))
        if len(alle) > 1:
            print()
            print("Fuer alle zusammen: python tools/log_report.py --alle")


main()
