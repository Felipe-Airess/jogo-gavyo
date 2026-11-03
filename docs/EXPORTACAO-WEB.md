# Exportação Web sem o Mac

O workflow **Godot Web** usa Ubuntu, Godot **4.5.1 oficial** e os templates
`web_nothreads` da mesma versão. Importa `godot-3d/`, exporta o preset `Web`
de `godot-3d/export_presets.cfg`, verifica os arquivos e executa os testes de toque.
Não copia modelos de outra pasta nem altera os controles existentes.

## Execução

- Push/merge em `main`: exporta e publica. Commits que só alteram `capitulo1/`
  não disparam a exportação (essa pasta contém o resultado gerado).
- PR para `main`: exporta, testa e guarda `capitulo1-web` em Artifacts por 7 dias;
  não publica nem escreve na `main`.
- Actions → Godot Web → Run workflow → **main**: exporta e publica manualmente.
  Outra branch só gera o artefato. O botão manual aparece após o merge do workflow.

## Publicação e proteção dos outros arquivos

Mantém o Pages existente: **Deploy from a branch → main → / (root)**.
O job verifica essa configuração pela API antes de escrever. É necessário que
Actions possa usar `contents: write` e `pages: write`; não exige secret/PAT próprio.
Se regras de proteção impedirem o bot de atualizar `main`, o job falha sem forçar
push ou contornar a proteção. Nesse caso a política do repositório precisa ser
revista antes de habilitar a publicação automática.

Somente `capitulo1/` é sincronizada, preservando seu `LEIA-ME.txt` e todos os
arquivos fora dela. Assets antigos gerados nessa pasta são removidos para não
misturar versões. A revisão-fonte fica em `capitulo1/build.json`.

Há uma fila por branch e nenhum force-push. Se `main` mudar durante a exportação,
o job falha antes de publicar: rode novamente na `main` mais recente. Uma corrida
posterior é rejeitada pelo push normal do Git. O commit usa `GITHUB_TOKEN`,
`[skip ci]` e um filtro de caminhos: não gera um ciclo de exportações.
Como commits do `GITHUB_TOKEN` não iniciam automaticamente o Pages, o workflow
solicita o build do Pages explicitamente, acompanha o resultado e verifica a
revisão publicada em `build.json`. Falha de publicação fica visível no job;
uma execução manual permite tentar novamente.

URL: https://felipe-airess.github.io/jogo-gavyo/capitulo1/

## Android

Preservados: Compatibility/WebGL 2, exportação sem threads (sem exigir
SharedArrayBuffer/COOP/COEP), compressão de texturas para mobile, canvas adaptável,
viewport e CSS de toque. Os controles existentes continuam detectando Android e
tratando múltiplos dedos. Isso não garante desempenho em todo aparelho: testar
Chrome/Android físico continua necessário. PWA/service worker fica desligado
para não manter uma versão antiga em cache.

## Reprodução local em Linux

Instale Godot 4.5.1 e `web_nothreads_debug.zip`/`web_nothreads_release.zip` em
`~/.local/share/godot/export_templates/4.5.1.stable/`, então:

```bash
GODOT=/caminho/Godot_v4.5.1-stable_linux.x86_64 bash scripts/exportar-web.sh
python3 scripts/validar-web.py godot-3d/web
python3 -m http.server 8000 --directory godot-3d/web
```

O workflow não faz merge de PR. A primeira publicação dessa automação ocorre
somente depois de o workflow entrar na `main` por um merge aprovado.
