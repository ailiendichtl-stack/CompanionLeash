# -*- coding: utf-8 -*-
"""Prueft eine gebaute Voiceset-Szene auf Strukturfehler.

Nach dem Sprung von 6 auf 181 Eintraege stuerzte das Spiel beim Laden eines Spielstands
ab. Der Bau selbst meldete nichts - er zaehlt nur, ob Einstiege und startNodes gleich viele
sind. Das reicht offensichtlich nicht.

Geprueft wird hier, was eine Szene in sich stimmig macht:

* jeder Einstieg zeigt auf einen Knoten, den es gibt
* jeder Ausgang eines Knotens zeigt auf einen Knoten, den es gibt
* keine doppelten Knoten-Ids, Einstiegsnamen, itemIds oder Ereignis-Ids
* jedes Dialogereignis verweist auf eine Zeile, die es gibt
* Zahlenbereiche - was ueber 16 Bit hinauslaeuft, faellt auf

    python tools/check_scene.py <szene.json>
"""
import collections
import json
import os
import sys


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    d = json.load(open(sys.argv[1], encoding="utf-8"))["Data"]["RootChunk"]
    graph = d["sceneGraph"]["Data"]["graph"]
    lines = d["screenplayStore"]["lines"]
    starts = d["sceneGraph"]["Data"]["startNodes"]
    eps = d["entryPoints"]

    fehler = []

    def melde(was, beispiele):
        fehler.append((was, beispiele))

    #  Knoten-Ids
    nid = [n.get("Data", n)["nodeId"]["id"] for n in graph]
    dopp = [k for k, v in collections.Counter(nid).items() if v > 1]
    if dopp:
        melde("doppelte Knoten-Ids: %d" % len(dopp), dopp[:6])
    bekannt = set(nid)

    #  Einstiege
    namen = [e["name"]["$value"] for e in eps]
    dopp = [k for k, v in collections.Counter(namen).items() if v > 1]
    if dopp:
        melde("doppelte Einstiegsnamen: %d" % len(dopp), dopp[:6])
    fehl = [e["name"]["$value"] for e in eps if e["nodeId"]["id"] not in bekannt]
    if fehl:
        melde("Einstiege ohne Knoten: %d" % len(fehl), fehl[:6])
    if len(eps) != len(starts):
        melde("Einstiege %d != startNodes %d" % (len(eps), len(starts)), [])
    fehl = [s["id"] for s in starts if s["id"] not in bekannt]
    if fehl:
        melde("startNodes ohne Knoten: %d" % len(fehl), fehl[:6])

    #  Ausgaenge
    offen = []
    for n in graph:
        nd = n.get("Data", n)
        for sock in nd.get("outputSockets", []):
            for dest in sock.get("destinations", []):
                if dest["nodeId"]["id"] not in bekannt:
                    offen.append((nd["nodeId"]["id"], dest["nodeId"]["id"]))
    if offen:
        melde("Ausgaenge ins Leere: %d" % len(offen), offen[:6])

    #  Zeilen
    items = [l["itemId"]["id"] for l in lines]
    dopp = [k for k, v in collections.Counter(items).items() if v > 1]
    if dopp:
        melde("doppelte itemIds: %d" % len(dopp), dopp[:6])
    bekannte_items = set(items)
    #  (n << 8) | 1 - jede Vanilla-Id hat diese Form, und ein Verstoss loest still
    #  eine FREMDE Zeile auf, statt zu scheitern.
    schief = [i for i in items if (i & 0xFF) != 1]
    if schief:
        melde("itemIds ohne (n<<8)|1: %d" % len(schief), schief[:6])
    zu_gross = [i for i in items if i > 0xFFFF]
    if zu_gross:
        melde("itemIds ueber 16 Bit: %d" % len(zu_gross), zu_gross[:6])

    #  Ereignisse
    evids, ohne_zeile, nicht4 = [], [], []
    for n in graph:
        nd = n.get("Data", n)
        for e in nd.get("events", []):
            ed = e.get("Data", e)
            if ed.get("$type") != "scnDialogLineEvent":
                continue
            evids.append(str(ed["id"]["id"]))
            if int(ed["id"]["id"]) % 4 != 0:
                nicht4.append(ed["id"]["id"])
            if ed["screenplayLineId"]["id"] not in bekannte_items:
                ohne_zeile.append(ed["screenplayLineId"]["id"])
    dopp = [k for k, v in collections.Counter(evids).items() if v > 1]
    if dopp:
        melde("doppelte Ereignis-Ids: %d" % len(dopp), dopp[:6])
    if ohne_zeile:
        melde("Ereignisse ohne Zeile: %d" % len(ohne_zeile), ohne_zeile[:6])
    if nicht4:
        melde("Ereignis-Ids nicht auf 4 ausgerichtet: %d" % len(nicht4), nicht4[:6])

    #  Debug-Symbole
    ds = d.get("debugSymbols", {})
    ns = ds.get("sceneNodesDebugSymbols", [])
    if len(ns) != len(graph):
        melde("Knotensymbole %d != Knoten %d" % (len(ns), len(graph)), [])

    #  Lipsync-Namen
    ohne = [l["itemId"]["id"] for l in lines
            if not (l.get("femaleLipsyncAnimationName", {}).get("$value") or "").strip()]
    if ohne:
        melde("Zeilen ohne Lipsync-Namen: %d" % len(ohne), ohne[:6])

    print("Knoten %d | Einstiege %d | Zeilen %d | Dialogereignisse %d"
          % (len(graph), len(eps), len(lines), len(evids)))
    print("itemId    %d .. %d" % (min(items), max(items)))
    print("nodeId    %d .. %d" % (min(nid), max(nid)))
    print()
    if not fehler:
        print("Keine Strukturfehler gefunden.")
        return
    for was, bsp in fehler:
        print("!! %s" % was)
        for b in bsp:
            print("     %s" % (b,))
    raise SystemExit(1)


main()
