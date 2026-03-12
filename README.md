# Jukebox 🎧

[![CI](https://github.com/josevilanir/jukebox/actions/workflows/ci.yml/badge.svg)](https://github.com/josevilanir/jukebox/actions/workflows/ci.yml)

Sala de música colaborativa em tempo real. Crie uma sala, convide amigos e
deixem a galera votar na próxima música — nada de DJ ditador.

---

## Funcionalidades

### 🎵 Player sincronizado
Todos os usuários na sala ouvem a mesma música no mesmo momento. Ao entrar
numa sala com música tocando, o player faz seek automático para a posição
correta usando o `started_at` persistido no banco.

### 🔍 Busca integrada do YouTube
Busca com debounce sem API key — scraping do `ytInitialData` com validação
de embeddability via oEmbed antes de adicionar à fila.

### 🗳 Upvotes na fila
Músicas com mais votos sobem na fila em tempo real. Ordenação por score + timestamp
de adição como tiebreaker — sem page reload.

### ⏭ Votação de skip democrática
Qualquer usuário pode votar para pular a música atual. Ao atingir 50% dos
presentes (mínimo 2 votos), a música é pulada automaticamente para todos.

### 🎛 Modo DJ
Host pode ativar o Modo DJ para permitir que qualquer usuário avance a fila.
Ativa automaticamente quando o host sai da sala (detectado via presença).

### 👥 Presença em tempo real
Contador de "N pessoas ouvindo" atualizado via ActionCable. Usa um hash de
timestamps no `solid_cache` com heartbeat a cada 30s — sem Redis, sem tabela extra.

### 💬 Chat em tempo real com comandos de barra
Mensagens via Turbo Streams. Suporta slash commands:

| Comando    | Descrição                                |
|------------|------------------------------------------|
| `/skip`    | Vota para pular a música atual           |
| `/help`    | Lista os comandos disponíveis            |
| `/<outro>` | Retorna mensagem de erro amigável        |

Mensagens de sistema (estilizadas de forma diferente das mensagens de usuário):
- `⏭ {user} votou para pular.` — ao usar `/skip`
- `🎵 Tocando agora: {title}` — ao avançar de música automaticamente

### 📜 Histórico paginado
Histórico da sala com paginação via Pagy + Turbo Frames. Botão "Carregar mais"
sem uma linha de JS adicional.

### 👤 Nome de convidado
Modal de seleção de nome na primeira visita, persistido em cookie de sessão
criptografado.

### 🛡 Rate limiting
Proteção via rack-attack: máximo de 10 buscas no YouTube/min por IP e 5
criações de sala/10min por IP.

### 🧹 Limpeza automática
`CleanupRoomsJob` roda diariamente às 3h UTC via Solid Queue, purgando itens
de fila reproduzidos há mais de 30 dias.

---

## Tech Stack

| Camada           | Tecnologia                                   |
|------------------|----------------------------------------------|
| Framework        | Ruby 3.3.4 + Rails 8                         |
| Frontend         | Hotwire (Turbo + Stimulus) — zero React      |
| WebSockets       | ActionCable + Solid Cable (Postgres)         |
| Cache / Locks    | Solid Cache (Postgres)                       |
| Background Jobs  | Solid Queue (Postgres) + cron via `recurring.yml` |
| Banco de dados   | PostgreSQL (Neon em produção)                |
| CSS              | Tailwind CSS                                 |
| Deploy           | Fly.io (região São Paulo — `gru`)            |
| Load testing     | K6                                           |
| CI/CD            | GitHub Actions (Brakeman, RuboCop, Minitest) |

---

## Arquitetura

### Zero Redis, Zero React
Todo o stack em tempo real roda sobre Postgres usando os adaptadores Solid*
do Rails 8 — Solid Cable para WebSockets, Solid Cache para presença e locks,
Solid Queue para jobs. Sem processo Redis separado, sem infraestrutura adicional.

### Presença via cache com heartbeat
```ruby
# presence:rock-room => { "42" => { name: "João", at: 1234567890 }, ... }
Rails.cache.write("presence:#{slug}", set, expires_in: 1.hour)
```
Cada conexão WebSocket renova seu timestamp a cada 30s. Entradas com mais de
40s sem heartbeat são consideradas offline. `PresenceChannel.user_count` é
chamado pelo `SkipVote` para calcular o threshold — presença como dado de
negócio, não só UI.

Lock leve por sala usa `unless_exist: true` com TTL de 2s e 3 tentativas com
backoff aleatório para reduzir race conditions no read-modify-write.

### Seek sync via started_at
Ao avançar para uma música, `Room#advance!` persiste `started_at` no `QueueItem`.
O player calcula `elapsed = now - started_at` e chama `seekTo(elapsed)`. O host
pode ajustar a posição via controles ±15s, que fazem broadcast do novo `started_at`
para todos via Turbo Stream.

### Fila ordenada por score sem N+1
```ruby
def queue_open
  queue_items.where(played_at: nil)
             .left_joins(:votes)
             .select("queue_items.*, COALESCE(SUM(votes.value),0) AS score")
             .group("queue_items.id")
             .order("score DESC, queue_items.created_at ASC")
end
```
Uma query só — sem `counter_cache`, sem callbacks de reordenação.

### Modo DJ com memoização
`can_advance?` chama `dj_mode_active?` que chama `host_online?`, que lê o cache.
Como a view chama isso múltiplas vezes por render, `host_online?` usa
`defined?(@host_online)` para memoizar corretamente (inclusive quando o valor é `false`).

---

## Setup local

```bash
git clone https://github.com/josevilanir/jukebox
cd jukebox
bundle install
bin/rails db:setup
bin/dev
```

Acesse `http://localhost:3000`.

---

## Testes

```bash
bin/rails test          # model + controller + channel tests
bin/rails test:system   # system tests com headless Chrome
```

Cobertura: `Room`, `QueueItem`, `SkipVote`, `Message`, `CleanupRoomsJob`,
`PresenceChannel` (subscribe, unsubscribe, heartbeat, user_count) e fluxos
principais via Capybara.

---

## Load Testing

O endpoint ActionCable (`PresenceChannel` + Solid Cable sobre Postgres) foi
benchmarked com [K6](https://k6.io/) simulando até 100 conexões WebSocket
simultâneas com heartbeat a cada 30s.

Veja [`load_test/README.md`](load_test/README.md) para a tabela de resultados.

```bash
# contra servidor local
k6 run load_test/websocket_test.js

# contra produção
k6 run -e BASE_URL=wss://your-app.fly.dev load_test/websocket_test.js
```

---

## Deploy

```bash
fly deploy
```
