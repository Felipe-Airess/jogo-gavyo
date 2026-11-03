# Resultado parcial — Bola

03/11/2026. **Modelo não criado. QA não executado nem aprovado.**

## Feito

- Lidas as instruções, técnica padrão, contexto do Felipe e quatro skills pedidas.
- Blender portátil 3.6.23 local iniciado com `--version`; nenhum modelo foi alterado.
- Extraídas e preservadas as 45 fotos do 7z em `originais/`, com os nomes originais.
- Manifesto com resolução, tamanho e SHA-256 por foto em `originais-manifesto.json`;
  os 45 hashes foram conferidos contra o conteúdo do 7z, todos idênticos.
- Três folhas de contato geradas e abertas em `arte/revisoes/bola/`.
- Triagem **visual preliminar** por arquivo em `TRIAGEM.md`; dados em `LEIA-ME.txt`.
- Altura interpretada como 1,75 m; o pedido escreveu 1,75 cm. Peso aproximado 67 kg,
  físico esguio, farda das fotos, cabelo castanho escuro. Sem característica extra inventada.

## Falha que interrompeu o trabalho

A preparação local usou o Python 3.10 do Blender portátil e o ambiente existente
`work/venv-modelo`. Comando tentado:

```bash
work/venv-modelo/bin/python -m pip install --only-binary=:all: \
  'numpy<1.27' 'scipy==1.10.1' 'scikit-image==0.21.0' \
  'mediapipe==0.10.9' 'opencv-contrib-python==4.5.5.64'
```

A transação não concluiu. O download de OpenCV terminou com:

```text
error: incomplete-download
Download failed after 6 attempts because not enough bytes were received (28.0 MB/55.9 MB)
```

O log integral está em `DEPENDENCIAS-FALHA.txt`. O MediaPipe nativo que já estava
presente também falhou no teste de importação, antes da modelagem:

```text
ImportError: dlopen(.../_framework_bindings.cpython-310-darwin.so, 2):
Symbol not found: __ZNKSt3__115basic_stringbufIcNS_11char_traitsIcEENS_9allocatorIcEEE3strEv
Referenced from: .../_framework_bindings.cpython-310-darwin.so (which was built for Mac OS X 13.0)
Expected in: /usr/lib/libc++.1.dylib
```

Este Mac usa macOS 11.7.11 Intel. A ordem de Felipe foi parar se algo não
instalasse. Não houve nova tentativa após o erro final, substituição de técnica,
uso de detector alternativo ou modelo genérico apresentado como resultado.

## Não executado

MediaPipe nas 45 fotos; seleção final em `escolhidas/`; cópias/adaptação dos quatro
scripts `bola_*.py`; corpo MakeHuman; três passadas frontais e uma de perfil;
cabelo por fatias; pele/farda; rig e prévias; exportação GLB/FBX; comparações
foto/modelo/sobreposição; medições em milímetros e canais de pele; QA de malha/pesos.

Sem modelo, não há diferenças foto/modelo ou números de fidelidade para reportar.
As folhas existentes mostram **apenas as fotos**, não validação de um personagem 3D.
Os arquivos do Miguel, do Felipe e do capítulo 1 permanecem intactos.

## Ponto de retomada

Concluir as dependências locais e comprovar a importação/execução do MediaPipe.
Depois executar o detector nas 45 fotos e finalizar a triagem/seleção antes de
iniciar o encaixe do rosto. Seguir `docs/TECNICA-PERSONAGEM-3D.md`; não pular para
modelagem por descrição. As lacunas visuais estão em `TRIAGEM.md`.
