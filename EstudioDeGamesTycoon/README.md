# 🎮 Estúdio de Games Tycoon

Tycoon em que o jogador monta o próprio estúdio de games num **prédio de 3 andares**: contrata
funcionários que produzem cartuchos de jogos, que viram dinheiro na Publicadora. Começa numa garagem
e termina na cobertura, com piscina, helicóptero e o **Troféu Game of the Year**, que libera o
**Rebirth** (+50% de renda para sempre a cada rebirth). A primeira partida até o troféu leva cerca
de 1 hora; com rebirths fica cada vez mais rápida.

## O que tem no jogo

**🏠 Térreo — a garagem que vira escritório**
- 10 funcionários em 2 linhas de produção, do Estagiário até a Lenda dos Games
- Paredes com pôsteres, letreiro com o nome do jogador, outdoor na fachada, café, sala de
  descanso com TV e videogame, servidores e contrato com publicadora global
- **Construir 2º Andar**: o prédio sobe, com escada no fundo à direita

**🏢 2º andar — Estúdio Pro**
- 3ª linha de produção com 5 funcionários novos (Dev de VR, Especialista em IA, Roteirista,
  Produtor Executivo, Gênio dos Games)
- Sala de Testes (QA) com testadores jogando, Estúdio de Streaming (tela verde, ring light,
  câmera, placa "AO VIVO"), Fliperamas Retrô e **Arena de eSports** com palco, dois times e telão
- **Construir Cobertura**: escada na frente, à esquerda

**🌆 Cobertura — o topo**
- 4ª linha de produção com Diretor Criativo, Vice-Presidente e CEO Visionário
- Sala do CEO (mesa de mármore, estante, aquário), Terraço com piscina, espreguiçadeiras, guarda-sóis
  e bar, **Heliponto com helicóptero** no telhado e o **Troféu Game of the Year** num palco iluminado

**🔁 Motivos para voltar e continuar jogando**
- **38 melhorias** no total, com 18 funcionários
- **Rebirth** com +50% de renda permanente, e o estúdio muda de visual a cada rebirth
  (Garagem → Bronze → Prata → Ouro → Diamante → Lendário)
- **24 missões** em sequência (construir andares, ganhar dinheiro, vender dourados, chocar ovos, rebirths)
- **Cartucho dourado**: 4% de chance de sair um jogo de sucesso que vale 10x, com brilho
- **Evento HYPE** a cada 4 minutos para o servidor todo: tudo vale 2x por 30 segundos
- **Recompensa diária** com sequência (dia 1 a 7) e **lucro offline** (até 8 horas)
- Prêmios de missão, recompensa diária e pacotes de dinheiro acompanham a renda do jogador,
  então continuam valendo a pena no fim do jogo

**🐾 Pets**
- Incubadora em cada estúdio (térreo, ao lado do tapete de coleta): o jogador choca ovos com
  **dinheiro do jogo** (o preço acompanha a renda) e ganha pets que seguem ele e dão bônus de renda
- 10 pets em 4 raridades: Comum 60%, Raro 28%, Épico 10%, Lendário 2% (chances mostradas na incubadora)
- Até 3 pets equipados (4 para VIP), bônus somados (+10% a +120% cada); menu 🐾 Pets com
  "Equipar melhores" e opção de liberar pets
- O servidor todo é avisado quando alguém choca um Lendário

**🎨 Skins do prédio** (só visual)
- Clássico, Tijolinho (1 rebirth), Chalé de Madeira (2), Torre de Vidro (3), Mármore Real (5)
- Exclusivas VIP: Neon Noturno, Ouro Puro e Diamante

**👑 Passe VIP**
- Acesso à **Área VIP** no fim da rua ao sul (sala dourada com sofás, trono e tapete vermelho)
- **Baú VIP** a cada 10 minutos (5 minutos de renda)
- Pet exclusivo **Dragão Dourado VIP**, +1 espaço de pet, 3 skins exclusivas e a tag 👑 VIP na cabeça

**🏆 Ranking global**
- Dois telões na praça (sobre a rua, dá para passar por baixo): **Top Rebirths** e **Mais Ricos**
  (total ganho na vida), com os 10 melhores de todos os servidores, atualizados a cada 90 segundos

**✨ Acabamento**
- Seta guia que leva o jogador novo até a porta livre e depois até cada compra disponível
- Itens e andares caem do céu com animação quando são comprados, com explosão de partículas
- Funcionários sentados digitando, "+$" flutuando sobre a Publicadora a cada jogo vendido
- Luzes de teto em cada andar, plantas, luminárias, praça central com placa, árvores e postes
- Painéis de dinheiro, renda por segundo, próxima meta e missão; interface adaptada para celular
- Progresso salvo (DataStore) e placar de Dinheiro e Rebirths
- 3 gamepasses (VIP, Dinheiro 2x, Coleta Automática) e 3 pacotes de dinheiro, já programados

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
3. Para testar os andares sem esperar, no Studio abra **ReplicatedStorage → TycoonConfig** e mude
   `Config.START_CASH = 0` para um valor alto (ex.: `1e12`). **Volte para 0 antes de publicar.**

### 2. Publicar o jogo
1. No Studio: **File → Publish to Roblox** → crie uma experiência nova.
2. Nome sugerido: **Estúdio de Games Tycoon**. Gênero: **Tycoon**.
3. Descrição sugerida:
   > 🎮 Monte o seu próprio estúdio de games! Comece numa garagem, contrate estagiários,
   > programadores, artistas e lendas dos games, e construa um prédio de 3 andares com arena de
   > eSports, estúdio de streaming, cobertura com piscina e helicóptero. Ganhe o troféu Game of the
   > Year e faça REBIRTH para ganhar ainda mais!
   > 🏢 3 andares • 👨‍💻 18 funcionários • 🐾 Pets • 👑 Área VIP • 🏆 Ranking global • 📋 24 missões
   > • 🔥 Eventos HYPE • 🎁 Recompensa diária • 🔄 Rebirth
4. Depois de publicar, no Studio vá em **Home → Game Settings → Security** e ative
   **Enable Studio Access to API Services** (sem isso o progresso e o ranking não funcionam nos
   testes do Studio).
5. Em **Game Settings → Permissions**, deixe o jogo **Public** quando quiser liberar para todos.

### 3. Ícone e thumbnails
Acesse **create.roblox.com/dashboard/creations** e clique no jogo.

**Ícone:** Configurations → Places → abra o lugar principal (marcado com ⭐) → **Icon** →
tipo **Image** → envie `imagens/icone_jogo.png` → salvar.

**Thumbnails:** Configurations → Places → lugar principal → **Thumbnails** → envie, nesta ordem:
1. `imagens/thumbnails/thumbnail_1_predio.png`
2. `imagens/thumbnails/thumbnail_2_producao.png`
3. `imagens/thumbnails/thumbnail_3_segundo_andar.png`
4. `imagens/thumbnails/thumbnail_4_cobertura.png`
5. `imagens/thumbnails/thumbnail_5_pets_vip.png`

> As imagens passam pela moderação do Roblox antes de aparecer para os outros.

### 4. Criar os Gamepasses (compra única)
No painel do jogo: **Monetization → Passes → Create pass**. Para cada passe: envie a imagem,
coloque nome e descrição e clique em **Create pass**. Depois abra o passe e coloque **à venda**
com o preço sugerido.

| Passe | Imagem | Nome | Descrição | Preço sugerido |
|---|---|---|---|---|
| VIP | `imagens/passes/passe_vip.png` | VIP | Área VIP exclusiva, Baú VIP a cada 10 min, pet Dragão Dourado, +1 espaço de pet, 3 skins de prédio exclusivas e tag VIP! | 299 Robux |
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

Cada pacote dá 10 minutos, 1 hora ou 6 horas da renda atual do jogador (com um mínimo de $5K,
$50K e $500K), então vale a pena do começo ao fim do jogo.

**Pegar o ID:** em Monetization → Developer Products, passe o mouse no produto → **⋯** → **Copy Asset ID**.

### 6. Colar os IDs no jogo
No Studio, abra **ReplicatedStorage → TycoonConfig** e troque os `0` pelos IDs:

```lua
Config.GAMEPASS_2X_ID = 0          -- ID do passe "Dinheiro 2x"
Config.GAMEPASS_AUTOCOLLECT_ID = 0 -- ID do passe "Coleta Automática"
Config.GAMEPASS_VIP_ID = 0         -- ID do passe "VIP"

Config.PRODUCTS = {
	{ Id = 0, Name = "Pacote Pequeno", Minutes = 10,  Min = 5000 },   -- ID do Pacote Pequeno
	{ Id = 0, Name = "Pacote Médio",   Minutes = 60,  Min = 50000 },  -- ID do Pacote Médio
	{ Id = 0, Name = "Pacote Grande",  Minutes = 360, Min = 500000 }, -- ID do Pacote Grande
}
```

Depois **File → Publish to Roblox** de novo. Os botões **👑 VIP**, **💸 Dinheiro 2x**,
**⚡ Coleta Auto** e **🛒 Loja** aparecem sozinhos no jogo quando o ID estiver preenchido.
Quem encosta na porta da Área VIP sem ter o passe também recebe a oferta de compra.

> Dica: atualize também o `src/TycoonConfig.lua` aqui no repositório com os mesmos IDs,
> para não perder se gerar o .rbxlx de novo.

---

## Ajustes rápidos (tudo no `TycoonConfig`)

- Preços e valores de cada item: lista `Config.Items`
- Bônus do rebirth: `Config.REBIRTH_BONUS`
- Recompensa diária: `Config.DAILY_BASE`
- Lucro offline: `Config.OFFLINE_MAX_HOURS` e `Config.OFFLINE_RATE`
- Velocidade de produção e da esteira: `Config.DROP_INTERVAL` e `Config.CONVEYOR_SPEED`
- Cartucho dourado: `Config.GOLDEN_CHANCE` e `Config.GOLDEN_MULT`
- Evento HYPE: `Config.HYPE_INTERVAL`, `Config.HYPE_DURATION` e `Config.HYPE_MULT`
- Pets: lista `Config.PETS` (nome, raridade, bônus, cores), chances em `Config.RARITIES`,
  preço do ovo em `Config.EGG`, espaços em `Config.PET_SLOTS`
- Skins do prédio: lista `Config.SKINS`
- Baú VIP: `Config.VIP_CHEST_COOLDOWN`, `Config.VIP_CHEST_MINUTES` e `Config.VIP_CHEST_MIN`
- Ranking: `Config.LEADERBOARD_REFRESH`
- Missões: lista `Config.MISSIONS`
- Visual por rebirth: `Config.REBIRTH_THEMES`
- Nomes dos jogos nos pôsteres: `Config.POSTERS`
- Sons: `Config.SOUNDS`. Os sons padrão vêm do próprio Roblox; para sons melhores, pegue na
  Creator Store (aba Audio), copie o ID e troque por `"rbxassetid://NUMERO"`
