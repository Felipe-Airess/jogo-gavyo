# Perfil leve do protótipo

Ajuste urgente após Felipe relatar travamentos em 01/11/2026. A abertura pelo
lançador normal foi confirmada pelo usuário como melhor.

- Execução normal sem a ponte/captura QA: sem render extra, leitura de GPU e
  compressão de PNG durante a partida.
- Render fixo em 960×540 com filtragem linear, sem voltar a 426×240.
- MSAA e sombras dinâmicas desligados no perfil leve, preservando luzes e cores.
- Limite de 60 FPS para evitar renderização desnecessária.
- Medição de baixo custo em `work/prototipo-desempenho.json`; não captura imagens.

Amostra registrada durante exploração ativa, sem pausa e sem QA, na execução
42397: 39,24 FPS médios; percentil 95 de quadro 30,61 ms; máximo 52,65 ms;
198 draw calls; processo 35,65 ms e física 4,41 ms na leitura daquele instante.
Valores de CPU de uma leitura pontual não são médias da janela. Não há medição
comparável anterior; portanto não foi calculado ganho percentual nem prometido
60 FPS. A confirmação de melhora é do usuário; estes números descrevem a nova
execução.

O modo `--qualidade` pode restaurar as opções anteriores para futura comparação
controlada. `work/prototipo-qa/sem-captura` suspende imagens em execuções QA até
ser removido explicitamente. O lançador normal não ativa a ponte.
