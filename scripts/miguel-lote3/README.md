# Miguel — lote 3 (folhas do ChatGPT → quadros do jogo)

Fontes: `arte/personagens/miguel/lote3/fontes/` (3 folhas de apresentação).

```bash
python scripts/miguel-lote3/recortar.py arte/personagens/miguel/lote3/fontes/guarda_andar.png /tmp/cut/guarda_andar 6,8
python scripts/miguel-lote3/recortar.py arte/personagens/miguel/lote3/fontes/chutes.png /tmp/cut/chutes 12,12,10,8
python scripts/miguel-lote3/recortar.py arte/personagens/miguel/lote3/fontes/socos.png /tmp/cut/socos 8,9,9,9,12
python scripts/miguel-lote3/padronizar.py /tmp/cut arte/personagens/miguel/lote3
python scripts/add-miguel-lote3.py
```

O recorte separa cada célula (quantidade conhecida por linha), tira fundo,
números, realce rosa do contato, linha do chão e o fundo preso entre as
pernas. A padronização põe a guarda (quadro 1 de cada animação) com 66 px
(andar em pé: 70 px), pivô (64,88), posição de cada figura igual à da célula
na folha, paleta comum de 48 cores e alfa binário. Nada é redesenhado.
