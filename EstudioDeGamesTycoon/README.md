# Estúdio de Games Tycoon

Tycoon em que o jogador monta um estúdio de games: contrata funcionários que produzem cartuchos,
que viram dinheiro na Publicadora. Termina com o Troféu Game of the Year, que libera o Rebirth.

## Arquivos
- `EstudioDeGamesTycoon.rbxlx` — lugar completo; abra no Roblox Studio e publique.
- `src/` — scripts (Config em ReplicatedStorage, servidor em ServerScriptService, HUD em StarterPlayerScripts).
- `build.py` — gera o `.rbxlx` a partir dos scripts (`python build.py`).

## Antes de publicar
1. Game Settings → Security → ative **Enable Studio Access to API Services** (salvamento).
2. Crie os gamepasses "Dinheiro 2x" e "Coleta Automática" e cole os IDs no topo de `TycoonConfig`.
