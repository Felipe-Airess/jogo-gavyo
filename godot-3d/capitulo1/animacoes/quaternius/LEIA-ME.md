# Animações Quaternius (Universal Animation Library 1 e 2, Standard, CC0)

Baixadas por Felipe em 02/11/2026. Licença CC0 (`LICENSE-CC0.txt`). Arquivos sem root
motion (`UAL1.glb`, `UAL2.glb`). O esqueleto vem no padrão Unreal (`pelvis`, `thigh_l`…);
`mapa_ossos_quaternius.tres` mapeia para o perfil humanoide do Godot (`Hips`,
`LeftUpperArm`…), o mesmo do Miguel. O retarget está configurado nos `.import`.

## O que cobre da lista (`docs/ANIMACOES-MIXAMO.md`)

| Precisa | Quaternius |
|---|---|
| parado | Idle_Loop; Idle_FoldArms_Loop, Idle_No_Loop (variações) |
| andar | Walk_Loop |
| correr | Jog_Fwd_Loop; Sprint_Loop |
| agachado parado / andando | Crouch_Idle_Loop / Crouch_Fwd_Loop |
| acordar | Sitting_Idle_Loop + Sitting_Exit |
| abrir porta / usar | Interact; Chest_Open (armário) |
| pegar a bolsa | PickUp_Table |
| celular / gravar | Idle_TalkingPhone_Loop |
| lanterna | Idle_Lantern_Loop |
| pular obstáculo / escalar portão | ClimbUp_1m; Jump_Start/Loop/Land |
| empurrar | Push_Loop (adaptar trecho) ; Melee_Hook |
| ser empurrado | Hit_Knockback |
| levantar do chão | LayToIdle |
| dano | Hit_Chest, Hit_Head |
| morrer | Death01 |
| cultista andar / procurar | Walk_Formal_Loop, Zombie_Walk_Fwd_Loop / Idle_No_Loop |
| agarrão (aproximação) | Zombie_Idle_Loop, Zombie_Scratch |
| ritual | Fixing_Kneeling (ajoelhado) |
| perseguidor com faca | Sword_Attack, Sword_Regular_A (adaptar) |

## Ainda faltam (baixar no Mixamo, Y Bot, Without Skin, 30 fps)

- andar de costas ("walking backwards", In Place)
- agachar / levantar ("standing to crouch", "crouch to stand")
- espiar ("peek" / "look around corner")
- subir / descer escada ("climbing stairs", "descending stairs", In Place)
- agarrar alguém ("grab")
- ser agarrado / se debater ("struggle")
- se soltar ("break free")
- olhar em volta procurando ("look around" / "searching")
- facada ("stabbing")
- rezando ("praying"), opcional — Fixing_Kneeling já serve
