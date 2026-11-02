# Fontes dos recursos

- `felipe.glb`: cópia sem alteração de `arte/felipe_boneco.glb`, modelo existente
  do projeto. Fontes, referências e técnica permanecem em `arte/` e
  `docs/TECNICA-PERSONAGEM-3D.md`. Não é um modelo novo aprovado nesta rodada.
- Miguel/clipes: recursos existentes `godot-3d/miguel_animado.glb` e
  `arte/mixamo`. Nenhum novo download de modelos/animações. Usos Mixamo:
  https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html
- Cultistas/perseguidor: derivação em memória da malha/rig existente, com
  remoção dos índices da cabeça original e novas peças/materiais, em `ator.gd`.
  Não altera os arquivos de Miguel. Modelo de Bola é provisório.
- Cenário/ave/objetos/rede: geometria e materiais gerados pelos scripts desta pasta.
- `acoes.gd`: chaves FK novas para pegada, pressão e derrubada. Recebimento do alvo
  e deslocamentos contextuais são adaptações do protótipo, não captura pareada pronta.
- `culto.wav`: síntese local pelo macOS, voz Luciana, ritmo 105, convertida para
  WAV mono 22.050 Hz. Texto: “Aclamamos o ser antigo. O fim dos tempos chegou.”
  É voz provisória; os termos de redistribuição dessa síntese não foram auditados
  para publicação. Não houve gravação de microfone ou clonagem de voz.
- Outros WAV desta pasta: ruído/ondas sintéticos gerados localmente, não sons
  captados de terceiros. São sons provisórios, sem aprovação auditiva do usuário.
- Fonte Work Sans e sons antigos: preservados em `prototipo/`, com licença da
  fonte em `prototipo/FONT-LICENSE.txt`.

Skills pesquisadas com `find-skills`: Godot/ambiente/animação. Mantidas as skills
locais já presentes; não se instalou pacote só pela posição em busca ou popularidade.
