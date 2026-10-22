# 🎮 Estúdio de Games Tycoon

Tycoon em que o jogador monta o próprio estúdio de games: contrata funcionários que produzem
cartuchos de jogos, que viram dinheiro na Publicadora. Termina com o **Troféu Game of the Year**,
que libera o **Rebirth** (+50% de renda para sempre a cada rebirth).

## O que tem no jogo

- 4 estúdios por servidor (o jogador toca na porta azul para ser o dono)
- 10 funcionários em 2 linhas de produção, do Estagiário até a Lenda dos Games
- Melhorias: paredes, letreiro com o nome do jogador, café e sala de descanso (produção mais rápida),
  outdoor, servidores e contrato com publicadora (multiplicadores de renda), troféu
- **Rebirth** com bônus permanente
- **Recompensa diária** com sequência (dia 1 a 7, cresce a cada dia seguido)
- **Lucro offline**: o estúdio rende 50% enquanto o jogador está fora (até 8 horas)
- Barra de **próxima meta** no topo da tela, renda por segundo e multiplicador
- Progresso salvo (DataStore) e placar de Dinheiro e Rebirths
- 2 gamepasses e 3 pacotes de dinheiro, já programados

## Arquivos

| Arquivo | Para que serve |
|---|---|
| `EstudioDeGamesTycoon.rbxlx` | O jogo completo. Abra no Roblox Studio |
| `src/` | Os scripts separados (o mesmo código que está dentro do .rbxlx) |
| `imagens/` | Ícone, thumbnails e ícones dos passes e produtos |
| `build.py` | Gera o .rbxlx de novo a partir de `src/` (`python build.py`) |

---

## Passo a passo para publicar

### 1. Abrir e testar no Studio
1. Abra `EstudioDeGamesTycoon.rbxlx` com dois cliques (ou Roblox Studio → File → Open).
2. Aperte **Play** e confira: tocar na porta, comprar itens, coletar dinheiro no tapete verde.

### 2. Publicar o jogo
1. No Studio: **File → Publish to Roblox** → crie uma experiência nova.
2. Nome sugerido: **Estúdio de Games Tycoon**. Gênero: **Tycoon**.
3. Descrição sugerida:
   > 🎮 Monte o seu próprio estúdio de games! Contrate estagiários, programadores, artistas e lendas
   > dos games, produza jogos na esteira e venda na Publicadora. Melhore seu escritório, ganhe o
   > troféu Game of the Year e faça REBIRTH para ganhar ainda mais!
   > 🎁 Recompensa diária • 🌙 Lucro offline • 🔄 Rebirth
4. Depois de publicar, no Studio vá em **Home → Game Settings → Security** e ative
   **Enable Studio Access to API Services** (sem isso o progresso não salva nos testes do Studio).
5. Em **Game Settings → Permissions**, deixe o jogo **Public** quando quiser liberar para todos.

### 3. Ícone e thumbnails
Acesse **create.roblox.com/dashboard/creations** e clique no jogo.

**Ícone:** Configurations → Places → abra o lugar principal (marcado com ⭐) → **Icon** →
tipo **Image** → envie `imagens/icone_jogo.png` → salvar.

**Thumbnails:** Configurations → Places → lugar principal → **Thumbnails** → envie, nesta ordem:
1. `imagens/thumbnails/thumbnail_1_visao_geral.png`
2. `imagens/thumbnails/thumbnail_2_producao.png`
3. `imagens/thumbnails/thumbnail_3_trofeu.png`

> As imagens passam pela moderação do Roblox antes de aparecer para os outros.

### 4. Criar os Gamepasses (compra única)
No painel do jogo: **Monetization → Passes → Create pass**. Para cada passe: envie a imagem,
coloque nome e descrição e clique em **Create pass**. Depois abra o passe e coloque **à venda**
com o preço sugerido.

| Passe | Imagem | Nome | Descrição | Preço sugerido |
|---|---|---|---|---|
| Dinheiro em dobro | `imagens/passes/passe_dinheiro_2x.png` | Dinheiro 2x | Todo o dinheiro que seu estúdio ganha vale o DOBRO, para sempre! | 199 Robux |
| Coleta automática | `imagens/passes/passe_coleta_auto.png` | Coleta Automática | O dinheiro vai direto para você, sem precisar pisar no tapete de coleta! | 99 Robux |

**Pegar o ID:** em Monetization → Passes, passe o mouse no passe → **⋯** → **Copy Asset ID**.

### 5. Criar os Produtos (pacotes de dinheiro, podem ser comprados várias vezes)
No painel do jogo: **Monetization → Developer Products → Create developer product**.
Envie a imagem, coloque nome, descrição e preço, e clique em **Save Changes**.

| Produto | Imagem | Nome | Descrição | Preço sugerido |
|---|---|---|---|---|
| 1º | `imagens/produtos/produto_pacote_pequeno.png` | Pacote Pequeno | Ganhe dinheiro na hora para acelerar seu estúdio! | 25 Robux |
| 2º | `imagens/produtos/produto_pacote_medio.png` | Pacote Médio | Um bom empurrão de dinheiro para seu estúdio! | 99 Robux |
| 3º | `imagens/produtos/produto_pacote_grande.png` | Pacote Grande | Um baú cheio de dinheiro para seu estúdio! | 399 Robux |

O valor de cada pacote ($5K, $50K e $500K) é multiplicado por (1 + rebirths), então continua
valendo a pena no fim do jogo.

**Pegar o ID:** em Monetization → Developer Products, passe o mouse no produto → **⋯** → **Copy Asset ID**.

### 6. Colar os IDs no jogo
No Studio, abra **ReplicatedStorage → TycoonConfig** e troque os `0` pelos IDs:

```lua
Config.GAMEPASS_2X_ID = 0          -- ID do passe "Dinheiro 2x"
Config.GAMEPASS_AUTOCOLLECT_ID = 0 -- ID do passe "Coleta Automática"

Config.PRODUCTS = {
	{ Id = 0, Name = "Pacote Pequeno", Amount = 5000 },   -- ID do Pacote Pequeno
	{ Id = 0, Name = "Pacote Médio",   Amount = 50000 },  -- ID do Pacote Médio
	{ Id = 0, Name = "Pacote Grande",  Amount = 500000 }, -- ID do Pacote Grande
}
```

Depois **File → Publish to Roblox** de novo. Os botões **💸 Dinheiro 2x**, **⚡ Coleta Auto** e
**🛒 Loja** aparecem sozinhos no jogo quando o ID estiver preenchido.

> Dica: atualize também o `src/TycoonConfig.lua` aqui no repositório com os mesmos IDs,
> para não perder se gerar o .rbxlx de novo.

---

## Ajustes rápidos (tudo no `TycoonConfig`)

- Preços e valores de cada item: lista `Config.Items`
- Bônus do rebirth: `Config.REBIRTH_BONUS`
- Recompensa diária: `Config.DAILY_BASE`
- Lucro offline: `Config.OFFLINE_MAX_HOURS` e `Config.OFFLINE_RATE`
- Velocidade de produção e da esteira: `Config.DROP_INTERVAL` e `Config.CONVEYOR_SPEED`
