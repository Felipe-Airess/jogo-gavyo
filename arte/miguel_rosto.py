"""Aplica o encaixe por pontos do Felipe às fotos do Miguel.

As fotos laterais atuais são 3/4 e têm pessoas/móveis no fundo: não são
silhuetas ortográficas. O ajuste automático de profundidade fica desativado
até haver perfil isolado; não se usa o contorno da sala como se fosse rosto.
"""
import os
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import felipe_rosto as ajuste
import miguel_referencia as modelo


def main():
    if "--sem-perfil" not in sys.argv:
        sys.argv.append("--sem-perfil")
    ajuste.fh = modelo
    ajuste.FOTOS = os.path.join(AQUI, "referencias", "miguel")
    ajuste.FOTO_FRENTE = "rosto_frente4.jpg"
    ajuste.ALVO = modelo.ALVO_ROSTO
    ajuste.PINTURA = modelo.PINTURA
    ajuste.ALINHAMENTO = os.path.join(AQUI, "miguel_fotos_alinhamento.json")
    ajuste.PERSONAGEM = "Miguel"
    ajuste.main()


if __name__ == "__main__":
    main()
