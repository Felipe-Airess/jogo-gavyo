"""Recalcula os quadros de contato de assets/miguel3d.json pelos marcadores
(ponta do punho/pe mais a frente), so entre 15% e 85% do golpe (sem contato
no 1o nem no ultimo quadro). Rodar depois de miguel_sprites.py --mixamo."""
import json
import os
import runpy
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.argv = [sys.argv[0]]


def picos(v, n, lo, hi):
    cand = [i for i in range(lo, hi + 1)
            if (i == lo or v[i] >= v[i - 1]) and (i == hi or v[i] >= v[i + 1])]
    cand.sort(key=lambda i: -v[i])
    esc = []
    for i in cand:
        if all(abs(i - j) >= 3 for j in esc):
            esc.append(i)
        if len(esc) == n:
            break
    return sorted(esc)


def main():
    caminho = os.path.join(RAIZ, "assets", "miguel3d.json")
    atlas = json.load(open(caminho))
    marc = json.load(open(os.path.join(RAIZ, "assets", "miguel3d-markers.json")))["clips"]
    for c in atlas["clips"]:
        n = len(c.get("contactFrames") or [])
        if not n:
            continue
        pe = "Kick" in c["id"] or "knee" in c["id"].lower() or "stomp" in c["id"] or "Knee" in c["id"]
        v = []
        for m in marc[c["id"]]:
            p = (m.get("frontFoot") if pe else m.get("frontFist")) or {}
            v.append(p.get("tipX", -99) - (0.5 * p.get("tipY", 0) if pe else 0))
        k = len(v)
        lo, hi = max(1, int(k * 0.15)), min(k - 2, int(k * 0.85))
        novos = picos(v, n, lo, hi) or [k // 2]
        c["contactFrames"] = novos
        for i, f in enumerate(c["frames"]):
            f["phase"] = "preparação" if i < novos[0] else "contato" if i in novos else "recuperação"
        print("%-22s contatos %s" % (c["id"], novos))
    json.dump(atlas, open(caminho, "w"), ensure_ascii=False, indent=1)


main()
